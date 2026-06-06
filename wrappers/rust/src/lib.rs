use std::fmt;
use std::fs;
use std::os::raw::c_int;
use std::path::Path;

pub const SPEC_VERSION: &str = "1.0-alpha";
pub const MAPPER_TYPE_INTEGER_RANGE: &str = "integer_range";

#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
struct NativeMapper {
    input_min: i64,
    input_max: i64,
    output_min: f64,
    output_max: f64,
    clip: c_int,
}

#[repr(C)]
#[derive(Clone, Copy, Debug, Default)]
struct NativeSpec {
    spec_version_major: c_int,
    spec_version_minor: c_int,
    input_min: i64,
    input_max: i64,
    output_min: f64,
    output_max: f64,
    clip: c_int,
}

#[derive(Debug)]
pub enum Error {
    InvalidRange,
    InvalidValue,
    OutOfRange,
    NullPointer,
    UnsupportedSpec(String),
    Json(String),
    Io(std::io::Error),
    Native(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::InvalidRange => write!(f, "invalid range"),
            Error::InvalidValue => write!(f, "invalid value"),
            Error::OutOfRange => write!(f, "value out of range"),
            Error::NullPointer => write!(f, "null pointer"),
            Error::UnsupportedSpec(text) => write!(f, "unsupported spec: {text}"),
            Error::Json(text) => write!(f, "json error: {text}"),
            Error::Io(err) => write!(f, "{err}"),
            Error::Native(text) => write!(f, "{text}"),
        }
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(value: std::io::Error) -> Self {
        Self::Io(value)
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct MapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub input_range: [i64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
    pub name: Option<String>,
}

impl MapperSpec {
    pub fn to_json(&self) -> String {
        let mut json = format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"input_range\":[{},{}],\"output_range\":[{},{}],\"clip\":{}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            self.input_range[0],
            self.input_range[1],
            self.output_range[0],
            self.output_range[1],
            if self.clip { "true" } else { "false" }
        );
        if let Some(name) = &self.name {
            json.push_str(&format!(",\"name\":\"{}\"", escape_json(name)));
        }
        json.push('}');
        json
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        let spec_version = extract_string(text, "spec_version")?;
        let mapper_type = extract_string(text, "mapper_type")?;
        let input_range = extract_i64_pair(text, "input_range")?;
        let output_range = extract_f64_pair(text, "output_range")?;
        let clip = extract_bool(text, "clip")?;
        let name = extract_optional_string(text, "name")?;
        Ok(Self {
            spec_version,
            mapper_type,
            input_range,
            output_range,
            clip,
            name,
        })
    }
}

pub struct IntegerRangeMapper {
    native: NativeMapper,
    pub input_range: [i64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
    pub name: Option<String>,
}

impl IntegerRangeMapper {
    pub fn new(
        input_range: [i64; 2],
        output_range: [f64; 2],
        clip: bool,
        name: Option<String>,
    ) -> Result<Self, Error> {
        let mut native = NativeMapper::default();
        let status = unsafe {
            lrm_integer_range_mapper_init(
                &mut native,
                input_range[0],
                input_range[1],
                output_range[0],
                output_range[1],
                if clip { 1 } else { 0 },
            )
        };
        if status != 0 {
            return Err(map_status("init", status));
        }

        Ok(Self {
            native,
            input_range,
            output_range,
            clip,
            name,
        })
    }

    pub fn new_default(input_min: i64, input_max: i64) -> Result<Self, Error> {
        Self::new([input_min, input_max], [-1.0, 1.0], false, None)
    }

    pub fn map_value(&self, value: i64) -> Result<f64, Error> {
        let mut mapped = 0.0;
        let status = unsafe { lrm_integer_range_mapper_map_value(&self.native, value, &mut mapped) };
        if status != 0 {
            return Err(map_status("map_value", status));
        }
        Ok(mapped)
    }

    pub fn map(&self, value: i64) -> Result<f64, Error> {
        self.map_value(value)
    }

    pub fn spec(&self) -> Result<MapperSpec, Error> {
        let mut native_spec = NativeSpec::default();
        let status = unsafe { lrm_integer_range_mapper_get_spec(&self.native, &mut native_spec) };
        if status != 0 {
            return Err(map_status("get_spec", status));
        }

        Ok(MapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_INTEGER_RANGE.to_string(),
            input_range: [native_spec.input_min, native_spec.input_max],
            output_range: [native_spec.output_min, native_spec.output_max],
            clip: native_spec.clip != 0,
            name: self.name.clone(),
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(MapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: MapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_INTEGER_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_INTEGER_RANGE
            )));
        }
        Self::new(spec.input_range, spec.output_range, spec.clip, spec.name)
    }

    pub fn save<P: AsRef<Path>>(&self, path: P) -> Result<(), Error> {
        fs::write(path, self.to_json()?)?;
        Ok(())
    }

    pub fn load<P: AsRef<Path>>(path: P) -> Result<Self, Error> {
        let text = fs::read_to_string(path)?;
        Self::from_json(&text)
    }
}

fn map_status(operation: &str, status: c_int) -> Error {
    match status {
        1 => Error::InvalidRange,
        2 => Error::InvalidValue,
        3 => Error::OutOfRange,
        4 => Error::NullPointer,
        _ => Error::Native(format!("{operation} failed with native status {status}")),
    }
}

fn extract_string(text: &str, key: &str) -> Result<String, Error> {
    let needle = format!("\"{key}\":\"");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    let end = rest.find('"').ok_or_else(|| Error::Json(format!("unterminated string for {key}")))?;
    Ok(rest[..end].replace("\\\"", "\"").replace("\\\\", "\\"))
}

fn extract_optional_string(text: &str, key: &str) -> Result<Option<String>, Error> {
    let needle = format!("\"{key}\":\"");
    if let Some(start) = text.find(&needle) {
        let start = start + needle.len();
        let rest = &text[start..];
        let end = rest.find('"').ok_or_else(|| Error::Json(format!("unterminated string for {key}")))?;
        return Ok(Some(rest[..end].replace("\\\"", "\"").replace("\\\\", "\\")));
    }
    Ok(None)
}

fn extract_i64_pair(text: &str, key: &str) -> Result<[i64; 2], Error> {
    let needle = format!("\"{key}\":[");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    let end = rest.find(']').ok_or_else(|| Error::Json(format!("unterminated array for {key}")))?;
    let parts: Vec<_> = rest[..end].split(',').map(|s| s.trim()).collect();
    if parts.len() != 2 {
        return Err(Error::Json(format!("{key} must contain two values")));
    }
    Ok([
        parts[0].parse().map_err(|_| Error::Json(format!("invalid integer in {key}")))?,
        parts[1].parse().map_err(|_| Error::Json(format!("invalid integer in {key}")))?,
    ])
}

fn extract_f64_pair(text: &str, key: &str) -> Result<[f64; 2], Error> {
    let needle = format!("\"{key}\":[");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    let end = rest.find(']').ok_or_else(|| Error::Json(format!("unterminated array for {key}")))?;
    let parts: Vec<_> = rest[..end].split(',').map(|s| s.trim()).collect();
    if parts.len() != 2 {
        return Err(Error::Json(format!("{key} must contain two values")));
    }
    Ok([
        parts[0].parse().map_err(|_| Error::Json(format!("invalid number in {key}")))?,
        parts[1].parse().map_err(|_| Error::Json(format!("invalid number in {key}")))?,
    ])
}

fn extract_bool(text: &str, key: &str) -> Result<bool, Error> {
    let needle = format!("\"{key}\":");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    if rest.starts_with("true") {
        Ok(true)
    } else if rest.starts_with("false") {
        Ok(false)
    } else {
        Err(Error::Json(format!("invalid boolean for {key}")))
    }
}

fn escape_json(text: &str) -> String {
    text.replace('\\', "\\\\").replace('"', "\\\"")
}

extern "C" {
    fn lrm_integer_range_mapper_init(
        mapper: *mut NativeMapper,
        input_min: i64,
        input_max: i64,
        output_min: f64,
        output_max: f64,
        clip: c_int,
    ) -> c_int;

    fn lrm_integer_range_mapper_map_value(
        mapper: *const NativeMapper,
        value: i64,
        out_value: *mut f64,
    ) -> c_int;

    fn lrm_integer_range_mapper_get_spec(
        mapper: *const NativeMapper,
        out_spec: *mut NativeSpec,
    ) -> c_int;
}

#[cfg(test)]
mod tests {
    use super::{IntegerRangeMapper, MapperSpec};
    use std::fs;

    #[test]
    fn maps_canonical_cases() {
        let mapper = IntegerRangeMapper::new_default(0, 100).unwrap();
        assert_eq!(mapper.map_value(0).unwrap(), -1.0);
        assert_eq!(mapper.map_value(50).unwrap(), 0.0);
        assert_eq!(mapper.map_value(100).unwrap(), 1.0);
    }

    #[test]
    fn supports_clipping() {
        let mapper = IntegerRangeMapper::new([0, 10], [-1.0, 1.0], true, None).unwrap();
        assert_eq!(mapper.map_value(-5).unwrap(), -1.0);
        assert_eq!(mapper.map_value(15).unwrap(), 1.0);
    }

    #[test]
    fn round_trips_json_specs() {
        let mapper = IntegerRangeMapper::new([0, 10], [-1.0, 1.0], true, Some("sample".to_string())).unwrap();
        let text = mapper.to_json().unwrap();
        let restored = IntegerRangeMapper::from_json(&text).unwrap();
        assert_eq!(restored.map_value(10).unwrap(), 1.0);
        assert_eq!(restored.name.as_deref(), Some("sample"));
    }

    #[test]
    fn save_and_load_spec_files() {
        let mapper = IntegerRangeMapper::new_default(0, 4).unwrap();
        let path = std::env::temp_dir().join("librangemap-rust-mapper.json");
        mapper.save(&path).unwrap();
        let restored = IntegerRangeMapper::load(&path).unwrap();
        assert_eq!(restored.map_value(2).unwrap(), 0.0);
        let _ = fs::remove_file(path);
    }

    #[test]
    fn spec_struct_round_trip() {
        let spec = MapperSpec {
            spec_version: super::SPEC_VERSION.to_string(),
            mapper_type: super::MAPPER_TYPE_INTEGER_RANGE.to_string(),
            input_range: [0, 10],
            output_range: [-1.0, 1.0],
            clip: false,
            name: None,
        };
        let json = spec.to_json();
        let restored = MapperSpec::from_json(&json).unwrap();
        assert_eq!(restored.input_range, [0, 10]);
    }
}
