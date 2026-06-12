use std::fmt;
use std::fs;
use std::os::raw::c_int;
use std::path::Path;

pub const SPEC_VERSION: &str = "1.0-alpha";
pub const MAPPER_TYPE_INTEGER_RANGE: &str = "integer_range";
pub const MAPPER_TYPE_FLOAT_RANGE: &str = "float_range";
pub const MAPPER_TYPE_BOOLEAN_RANGE: &str = "boolean_range";
pub const MAPPER_TYPE_TEXT_RANGE: &str = "text_range";
pub const MAPPER_TYPE_SEQUENCE_RANGE: &str = "sequence_range";
pub const MAPPER_TYPE_CATEGORICAL_RANGE: &str = "categorical_range";
pub const MAPPER_TYPE_TEMPORAL_RANGE: &str = "temporal_range";
pub const MAPPER_TYPE_IMAGE_RANGE: &str = "image_range";
pub const MAPPER_TYPE_OBJECT_RANGE: &str = "object_range";

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
    UnsupportedType(String),
    UnknownToken(String),
    Json(String),
    Io(std::io::Error),
    Native(String),
}

#[derive(Clone, Debug, PartialEq)]
pub struct SequenceMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub allow_empty: bool,
}

impl SequenceMapperSpec {
    pub fn to_json(&self) -> String {
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"allow_empty\":{}}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            if self.allow_empty { "true" } else { "false" }
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            allow_empty: extract_bool(text, "allow_empty")?,
        })
    }
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::InvalidRange => write!(f, "invalid range"),
            Error::InvalidValue => write!(f, "invalid value"),
            Error::OutOfRange => write!(f, "value out of range"),
            Error::NullPointer => write!(f, "null pointer"),
            Error::UnsupportedSpec(text) => write!(f, "unsupported spec: {text}"),
            Error::UnsupportedType(text) => write!(f, "unsupported type: {text}"),
            Error::UnknownToken(text) => write!(f, "unknown token: {text}"),
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

pub struct SequenceRangeMapper<F, T, R>
where
    F: Fn(&T) -> Result<R, Error>,
{
    element_mapper: F,
    allow_empty: bool,
    _input: std::marker::PhantomData<T>,
    _output: std::marker::PhantomData<R>,
}

impl<F, T, R> SequenceRangeMapper<F, T, R>
where
    F: Fn(&T) -> Result<R, Error>,
{
    pub fn new(element_mapper: F, allow_empty: bool) -> Result<Self, Error> {
        Ok(Self {
            element_mapper,
            allow_empty,
            _input: std::marker::PhantomData,
            _output: std::marker::PhantomData,
        })
    }

    pub fn map_value(&self, values: &[T]) -> Result<Vec<R>, Error> {
        if values.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }

        let mut output = Vec::with_capacity(values.len());
        for value in values {
            output.push((self.element_mapper)(value)?);
        }
        Ok(output)
    }

    pub fn map(&self, values: &[T]) -> Result<Vec<R>, Error> {
        self.map_value(values)
    }

    pub fn spec(&self) -> SequenceMapperSpec {
        SequenceMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_SEQUENCE_RANGE.to_string(),
            allow_empty: self.allow_empty,
        }
    }

    pub fn to_json(&self) -> String {
        self.spec().to_json()
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

#[derive(Clone, Debug, PartialEq)]
pub struct FloatMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub input_range: [f64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
    pub allow_integer: bool,
}

impl FloatMapperSpec {
    pub fn to_json(&self) -> String {
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"input_range\":[{},{}],\"output_range\":[{},{}],\"clip\":{},\"allow_integer\":{}}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            self.input_range[0],
            self.input_range[1],
            self.output_range[0],
            self.output_range[1],
            if self.clip { "true" } else { "false" },
            if self.allow_integer { "true" } else { "false" }
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            input_range: extract_f64_pair(text, "input_range")?,
            output_range: extract_f64_pair(text, "output_range")?,
            clip: extract_bool(text, "clip")?,
            allow_integer: extract_bool(text, "allow_integer")?,
        })
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct BooleanMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub false_value: f64,
    pub true_value: f64,
}

#[derive(Clone, Debug, PartialEq)]
pub struct CategoricalMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub tokens: Vec<String>,
    pub output_range: [f64; 2],
}

#[derive(Clone, Debug, PartialEq)]
pub struct TextMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub mode: String,
    pub alphabet: Option<String>,
    pub input_range: [i64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
    pub allow_empty: bool,
    pub name: Option<String>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct TextRangeMapper {
    mode: String,
    alphabet: Option<String>,
    output_range: [f64; 2],
    clip: bool,
    allow_empty: bool,
    pub name: Option<String>,
}

impl TextMapperSpec {
    pub fn to_json(&self) -> String {
        let mut json = format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"mode\":\"{}\"",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            escape_json(&self.mode)
        );
        if let Some(alphabet) = &self.alphabet {
            json.push_str(&format!(",\"alphabet\":\"{}\"", escape_json(alphabet)));
        }
        json.push_str(&format!(
            ",\"input_range\":[{},{}],\"output_range\":[{},{}],\"clip\":{},\"allow_empty\":{}",
            self.input_range[0],
            self.input_range[1],
            self.output_range[0],
            self.output_range[1],
            if self.clip { "true" } else { "false" },
            if self.allow_empty { "true" } else { "false" }
        ));
        if let Some(name) = &self.name {
            json.push_str(&format!(",\"name\":\"{}\"", escape_json(name)));
        }
        json.push('}');
        json
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            mode: extract_string(text, "mode")?,
            alphabet: extract_optional_string(text, "alphabet")?,
            input_range: extract_i64_pair(text, "input_range")?,
            output_range: extract_f64_pair(text, "output_range")?,
            clip: extract_bool(text, "clip")?,
            allow_empty: extract_bool(text, "allow_empty")?,
            name: extract_optional_string(text, "name")?,
        })
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct ImageMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub output_range: [f64; 2],
    pub allow_empty: bool,
}

impl ImageMapperSpec {
    pub fn to_json(&self) -> String {
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"output_range\":[{},{}],\"allow_empty\":{}}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            self.output_range[0],
            self.output_range[1],
            if self.allow_empty { "true" } else { "false" }
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            output_range: extract_f64_pair(text, "output_range")?,
            allow_empty: extract_bool(text, "allow_empty")?,
        })
    }
}

impl TextRangeMapper {
    pub fn new_codepoint(
        output_range: [f64; 2],
        clip: bool,
        allow_empty: bool,
        name: Option<String>,
    ) -> Result<Self, Error> {
        Self::new_with_mode("codepoint", None, output_range, clip, allow_empty, name)
    }

    pub fn new_alphabet(
        alphabet: String,
        output_range: [f64; 2],
        clip: bool,
        allow_empty: bool,
        name: Option<String>,
    ) -> Result<Self, Error> {
        Self::new_with_mode("alphabet", Some(alphabet), output_range, clip, allow_empty, name)
    }

    pub fn new_bytes(
        output_range: [f64; 2],
        clip: bool,
        allow_empty: bool,
        name: Option<String>,
    ) -> Result<Self, Error> {
        Self::new_with_mode("byte", None, output_range, clip, allow_empty, name)
    }

    pub fn new_default() -> Result<Self, Error> {
        Self::new_codepoint([-1.0, 1.0], false, false, None)
    }

    pub fn map_value(&self, value: &str) -> Result<Vec<f64>, Error> {
        match self.mode.as_str() {
            "codepoint" => self.map_codepoints(value),
            "alphabet" => self.map_alphabet(value),
            "byte" => Err(Error::UnsupportedType(
                "use map_bytes_value for byte mode".to_string(),
            )),
            _ => Err(Error::UnsupportedSpec(format!(
                "unsupported mode {:?}",
                self.mode
            ))),
        }
    }

    pub fn map_bytes_value(&self, value: &[u8]) -> Result<Vec<f64>, Error> {
        if self.mode != "byte" {
            return Err(Error::UnsupportedType(
                "map_bytes_value is only available in byte mode".to_string(),
            ));
        }
        if value.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }
        Ok(value.iter().map(|byte| self.map_byte(*byte)).collect())
    }

    pub fn map(&self, value: &str) -> Result<Vec<f64>, Error> {
        self.map_value(value)
    }

    pub fn spec(&self) -> Result<TextMapperSpec, Error> {
        Ok(TextMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_TEXT_RANGE.to_string(),
            mode: self.mode.clone(),
            alphabet: self.alphabet.clone(),
            input_range: self.input_range(),
            output_range: self.output_range,
            clip: self.clip,
            allow_empty: self.allow_empty,
            name: self.name.clone(),
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(TextMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: TextMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_TEXT_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_TEXT_RANGE
            )));
        }
        let expected_input_range = match spec.mode.as_str() {
            "codepoint" => [0, 0x10FFFF],
            "alphabet" => {
                let alphabet = spec.alphabet.as_ref().ok_or(Error::InvalidValue)?;
                validate_alphabet(alphabet)?;
                [0, alphabet.chars().count() as i64 - 1]
            }
            "byte" => {
                if spec.alphabet.is_some() {
                    return Err(Error::InvalidValue);
                }
                [0, 255]
            }
            _ => return Err(Error::UnsupportedSpec(format!("unsupported mode {:?}", spec.mode))),
        };
        if spec.input_range != expected_input_range {
            return Err(Error::InvalidRange);
        }
        Self::new_with_mode(
            &spec.mode,
            spec.alphabet,
            spec.output_range,
            spec.clip,
            spec.allow_empty,
            spec.name,
        )
    }

    fn new_with_mode(
        mode: &str,
        alphabet: Option<String>,
        output_range: [f64; 2],
        clip: bool,
        allow_empty: bool,
        name: Option<String>,
    ) -> Result<Self, Error> {
        validate_float_range(output_range)?;
        let mode = mode.to_string();
        let alphabet = match mode.as_str() {
            "codepoint" => {
                if alphabet.is_some() {
                    return Err(Error::InvalidValue);
                }
                None
            }
            "alphabet" => {
                let alphabet = alphabet.ok_or(Error::InvalidValue)?;
                validate_alphabet(&alphabet)?;
                Some(alphabet)
            }
            "byte" => {
                if alphabet.is_some() {
                    return Err(Error::InvalidValue);
                }
                None
            }
            _ => return Err(Error::UnsupportedSpec(format!("unsupported mode {:?}", mode))),
        };

        Ok(Self {
            mode,
            alphabet,
            output_range,
            clip,
            allow_empty,
            name,
        })
    }

    fn input_range(&self) -> [i64; 2] {
        match self.mode.as_str() {
            "codepoint" => [0, 0x10FFFF],
            "alphabet" => [0, self.alphabet.as_ref().unwrap().chars().count() as i64 - 1],
            "byte" => [0, 255],
            _ => [0, 0],
        }
    }

    fn map_codepoints(&self, value: &str) -> Result<Vec<f64>, Error> {
        if value.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }
        let input_range = self.input_range();
        let input_min = input_range[0] as f64;
        let input_max = input_range[1] as f64;
        let input_span = input_max - input_min;
        let output_span = self.output_range[1] - self.output_range[0];
        value
            .chars()
            .map(|ch| {
                let codepoint = ch as u32 as f64;
                self.map_scalar(codepoint, input_min, input_max, input_span, output_span)
            })
            .collect::<Result<Vec<_>, Error>>()
    }

    fn map_alphabet(&self, value: &str) -> Result<Vec<f64>, Error> {
        if value.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }
        let alphabet = self.alphabet.as_ref().ok_or(Error::InvalidValue)?;
        let alphabet_len = alphabet.chars().count();
        if alphabet_len < 2 {
            return Err(Error::InvalidValue);
        }
        let input_min = 0.0;
        let input_max = alphabet_len as f64 - 1.0;
        let input_span = input_max - input_min;
        let output_span = self.output_range[1] - self.output_range[0];
        value
            .chars()
            .map(|ch| {
                let index = alphabet
                    .chars()
                    .position(|token| token == ch)
                    .ok_or_else(|| Error::UnknownToken(ch.to_string()))? as f64;
                self.map_scalar(index, input_min, input_max, input_span, output_span)
            })
            .collect::<Result<Vec<_>, Error>>()
    }

    fn map_byte(&self, byte: u8) -> f64 {
        let input_min = 0.0;
        let input_max = 255.0;
        let input_span = input_max - input_min;
        let output_span = self.output_range[1] - self.output_range[0];
        self.output_range[0] + ((byte as f64 - input_min) / input_span) * output_span
    }

    fn map_scalar(
        &self,
        value: f64,
        input_min: f64,
        input_max: f64,
        input_span: f64,
        output_span: f64,
    ) -> Result<f64, Error> {
        let mut bounded = value;
        if value < input_min || value > input_max {
            if !self.clip {
                return Err(Error::OutOfRange);
            }
            if value < input_min {
                bounded = input_min;
            }
            if value > input_max {
                bounded = input_max;
            }
        }
        Ok(self.output_range[0] + ((bounded - input_min) / input_span) * output_span)
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct TemporalMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub input_range: [f64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
}

#[derive(Clone, Debug, PartialEq)]
pub struct CategoricalRangeMapper {
    tokens: Vec<String>,
    output_range: [f64; 2],
}

impl CategoricalRangeMapper {
    pub fn new(tokens: Vec<String>, output_range: [f64; 2]) -> Result<Self, Error> {
        if tokens.is_empty() {
            return Err(Error::InvalidValue);
        }
        validate_float_range(output_range)?;
        for i in 0..tokens.len() {
            for j in (i + 1)..tokens.len() {
                if tokens[i] == tokens[j] {
                    return Err(Error::InvalidValue);
                }
            }
        }
        Ok(Self { tokens, output_range })
    }

    pub fn new_default(tokens: Vec<String>) -> Result<Self, Error> {
        Self::new(tokens, [-1.0, 1.0])
    }

    pub fn map_value(&self, value: &str) -> Result<f64, Error> {
        let index = self
            .tokens
            .iter()
            .position(|token| token == value)
            .ok_or(Error::InvalidValue)?;
        if self.tokens.len() == 1 {
            return Ok((self.output_range[0] + self.output_range[1]) / 2.0);
        }
        let normalized = index as f64 / (self.tokens.len() as f64 - 1.0);
        Ok(self.output_range[0] + normalized * (self.output_range[1] - self.output_range[0]))
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(CategoricalMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_CATEGORICAL_RANGE.to_string(),
            tokens: self.tokens.clone(),
            output_range: self.output_range,
        }
        .to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(CategoricalMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: CategoricalMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_CATEGORICAL_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_CATEGORICAL_RANGE
            )));
        }
        Self::new(spec.tokens, spec.output_range)
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct ImageRangeMapper {
    output_range: [f64; 2],
    clip: bool,
    allow_empty: bool,
}

impl ImageRangeMapper {
    pub fn new(output_range: [f64; 2], clip: bool, allow_empty: bool) -> Result<Self, Error> {
        validate_float_range(output_range)?;
        Ok(Self {
            output_range,
            clip,
            allow_empty,
        })
    }

    pub fn new_default() -> Result<Self, Error> {
        Self::new([-1.0, 1.0], false, false)
    }

    pub fn map_value(&self, value: &[u8]) -> Result<Vec<f64>, Error> {
        if value.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }
        Ok(value.iter().map(|byte| self.map_byte(*byte)).collect())
    }

    pub fn map_bytes_value(&self, value: &[u8]) -> Result<Vec<f64>, Error> {
        self.map_value(value)
    }

    pub fn map_nested_value(&self, value: &[Vec<u8>]) -> Result<Vec<Vec<f64>>, Error> {
        if value.is_empty() && !self.allow_empty {
            return Err(Error::InvalidValue);
        }
        let mut mapped = Vec::with_capacity(value.len());
        for row in value {
            mapped.push(self.map_value(row.as_slice())?);
        }
        Ok(mapped)
    }

    pub fn spec(&self) -> Result<ImageMapperSpec, Error> {
        Ok(ImageMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_IMAGE_RANGE.to_string(),
            output_range: self.output_range,
            allow_empty: self.allow_empty,
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(ImageMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: ImageMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_IMAGE_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_IMAGE_RANGE
            )));
        }
        Self::new(spec.output_range, false, spec.allow_empty)
    }

    fn map_byte(&self, byte: u8) -> f64 {
        let span = self.output_range[1] - self.output_range[0];
        self.output_range[0] + ((byte as f64) / 255.0) * span
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum ObjectValue {
    Integer(i64),
    Float(f64),
    Boolean(bool),
    Text(String),
    Bytes(Vec<u8>),
    Sequence(Vec<ObjectValue>),
    Object(Vec<ObjectFieldValue>),
}

#[derive(Clone, Debug, PartialEq)]
pub struct ObjectFieldValue {
    pub name: String,
    pub value: ObjectValue,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ObjectFieldSpec {
    pub name: String,
    pub allow_missing: bool,
    pub missing_value: Option<f64>,
    pub mapper: ObjectValueMapper,
}

#[derive(Clone, Debug)]
struct ObjectSequenceMapperSpec {
    allow_empty: bool,
    mapper_json: String,
}

impl ObjectSequenceMapperSpec {
    fn to_json(&self) -> String {
        format!(
            "{{\"allow_empty\":{},\"mapper_json\":\"{}\"}}",
            if self.allow_empty { "true" } else { "false" },
            escape_json(&self.mapper_json)
        )
    }

    fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            allow_empty: extract_bool(text, "allow_empty")?,
            mapper_json: extract_string(text, "mapper_json")?,
        })
    }
}

#[derive(Clone, Debug)]
pub enum ObjectValueMapper {
    Integer(IntegerRangeMapper),
    Float(FloatRangeMapper),
    Boolean(BooleanRangeMapper),
    Text(TextRangeMapper),
    Categorical(CategoricalRangeMapper),
    Temporal(TemporalRangeMapper),
    Image(ImageRangeMapper),
    Sequence(Box<ObjectValueMapper>, bool),
    Object(Box<ObjectRangeMapper>),
}

#[derive(Clone, Debug)]
pub struct ObjectRangeMapper {
    pub fields: Vec<ObjectFieldSpec>,
    pub allow_unknown: bool,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ObjectMapperSpec {
    pub spec_version: String,
    pub mapper_type: String,
    pub allow_unknown: bool,
    pub fields: Vec<ObjectFieldSpecJson>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct ObjectFieldSpecJson {
    pub name: String,
    pub allow_missing: bool,
    pub missing_value: Option<f64>,
    pub family: String,
    pub mapper_json: String,
}

impl ObjectMapperSpec {
    pub fn from_json(text: &str) -> Result<Self, Error> {
        let fields_text = extract_json_array(text, "fields")?;
        let fields = split_top_level_json_objects(&fields_text)
            .into_iter()
            .map(|field| ObjectFieldSpecJson::from_json(&field))
            .collect::<Result<Vec<_>, Error>>()?;
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            allow_unknown: extract_bool(text, "allow_unknown")?,
            fields,
        })
    }

    pub fn to_json(&self) -> String {
        let mut fields = self.fields.clone();
        fields.sort_by(|a, b| a.name.cmp(&b.name));
        let fields_json = fields
            .iter()
            .map(|field| field.to_json())
            .collect::<Vec<_>>()
            .join(",");
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"allow_unknown\":{},\"fields\":[{}]}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            if self.allow_unknown { "true" } else { "false" },
            fields_json
        )
    }
}

impl ObjectFieldSpecJson {
    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            name: extract_string(text, "name")?,
            allow_missing: extract_bool(text, "allow_missing")?,
            missing_value: extract_optional_f64(text, "missing_value")?,
            family: extract_string(text, "family")?,
            mapper_json: extract_string(text, "mapper_json")?,
        })
    }

    pub fn to_json(&self) -> String {
        let missing = match self.missing_value {
            Some(value) => format!(",\"missing_value\":{}", value),
            None => String::new(),
        };
        format!(
            "{{\"name\":\"{}\",\"allow_missing\":{},\"family\":\"{}\",\"mapper_json\":\"{}\"{}}}",
            escape_json(&self.name),
            if self.allow_missing { "true" } else { "false" },
            escape_json(&self.family),
            escape_json(&self.mapper_json),
            missing
        )
    }
}

impl ObjectRangeMapper {
    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(ObjectMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: ObjectMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_OBJECT_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_OBJECT_RANGE
            )));
        }
        let fields = spec
            .fields
            .into_iter()
            .map(ObjectFieldSpec::from_spec_json)
            .collect::<Result<Vec<_>, Error>>()?;
        Self::new(fields, spec.allow_unknown)
    }

    pub fn new(fields: Vec<ObjectFieldSpec>, allow_unknown: bool) -> Result<Self, Error> {
        let mut seen = Vec::new();
        for field in &fields {
            if field.name.trim().is_empty() {
                return Err(Error::InvalidValue);
            }
            if let Some(value) = field.missing_value {
                if !value.is_finite() {
                    return Err(Error::InvalidValue);
                }
            }
            if seen.iter().any(|item| item == &field.name) {
                return Err(Error::InvalidValue);
            }
            seen.push(field.name.clone());
        }
        Ok(Self { fields, allow_unknown })
    }

    pub fn map(&self, value: &[ObjectFieldValue]) -> Result<Vec<f64>, Error> {
        self.map_value(value)
    }

    pub fn map_value(&self, value: &[ObjectFieldValue]) -> Result<Vec<f64>, Error> {
        let mut sorted_fields = self.fields.clone();
        sorted_fields.sort_by(|a, b| a.name.cmp(&b.name));
        if duplicate_object_field_names(value.iter().map(|item| item.name.as_str()).collect::<Vec<_>>().as_slice()) {
            return Err(Error::InvalidValue);
        }

        let mut output = Vec::with_capacity(sorted_fields.len());
        for field_schema in &sorted_fields {
            let matches: Vec<&ObjectFieldValue> = value.iter().filter(|item| item.name == field_schema.name).collect();
            if matches.is_empty() {
                if field_schema.allow_missing {
                    if let Some(value) = field_schema.missing_value {
                        output.push(value);
                    } else {
                        return Err(Error::InvalidValue);
                    }
                } else {
                    return Err(Error::InvalidValue);
                }
            } else {
                if matches.len() > 1 {
                    return Err(Error::InvalidValue);
                }
                output.push(field_schema.mapper.map(&matches[0].value)?);
            }
        }

        if !self.allow_unknown {
            for item in value {
                if !self.fields.iter().any(|field| field.name == item.name) {
                    return Err(Error::UnsupportedType(item.name.clone()));
                }
                if item.name.trim().is_empty() {
                    return Err(Error::InvalidValue);
                }
            }
        }
        Ok(output)
    }

    pub fn spec(&self) -> Result<ObjectMapperSpec, Error> {
        let mut fields = self.fields.clone();
        fields.sort_by(|a, b| a.name.cmp(&b.name));
        let fields = fields
            .iter()
            .map(|field| field.to_spec_json())
            .collect::<Result<Vec<_>, Error>>()?;
        Ok(ObjectMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_OBJECT_RANGE.to_string(),
            allow_unknown: self.allow_unknown,
            fields,
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }
}

impl ObjectFieldSpec {
    fn from_spec_json(spec: ObjectFieldSpecJson) -> Result<Self, Error> {
        let ObjectFieldSpecJson {
            name,
            allow_missing,
            missing_value,
            family,
            mapper_json,
        } = spec;
        let mapper = ObjectValueMapper::from_spec_json(&family, &mapper_json)?;
        Ok(Self {
            name,
            allow_missing,
            missing_value,
            mapper,
        })
    }

    fn to_spec_json(&self) -> Result<ObjectFieldSpecJson, Error> {
        Ok(ObjectFieldSpecJson {
            name: self.name.clone(),
            allow_missing: self.allow_missing,
            missing_value: self.missing_value,
            family: self.mapper.family(),
            mapper_json: self.mapper.to_json()?,
        })
    }
}

impl ObjectValueMapper {
    fn from_spec_json(family: &str, mapper_json: &str) -> Result<Self, Error> {
        match family {
            MAPPER_TYPE_INTEGER_RANGE => Ok(Self::Integer(IntegerRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_FLOAT_RANGE => Ok(Self::Float(FloatRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_BOOLEAN_RANGE => Ok(Self::Boolean(BooleanRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_TEXT_RANGE => Ok(Self::Text(TextRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_CATEGORICAL_RANGE => Ok(Self::Categorical(CategoricalRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_TEMPORAL_RANGE => Ok(Self::Temporal(TemporalRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_IMAGE_RANGE => Ok(Self::Image(ImageRangeMapper::from_json(mapper_json)?)),
            MAPPER_TYPE_SEQUENCE_RANGE => {
                let spec = ObjectSequenceMapperSpec::from_json(mapper_json)?;
                let mapper = Box::new(Self::from_json(&spec.mapper_json)?);
                Ok(Self::Sequence(mapper, spec.allow_empty))
            }
            MAPPER_TYPE_OBJECT_RANGE => Ok(Self::Object(Box::new(ObjectRangeMapper::from_json(mapper_json)?))),
            _ => Err(Error::UnsupportedSpec(format!("unsupported family {:?}", family))),
        }
    }

    fn family(&self) -> String {
        match self {
            Self::Integer(_) => MAPPER_TYPE_INTEGER_RANGE.to_string(),
            Self::Float(_) => MAPPER_TYPE_FLOAT_RANGE.to_string(),
            Self::Boolean(_) => MAPPER_TYPE_BOOLEAN_RANGE.to_string(),
            Self::Text(_) => MAPPER_TYPE_TEXT_RANGE.to_string(),
            Self::Categorical(_) => MAPPER_TYPE_CATEGORICAL_RANGE.to_string(),
            Self::Temporal(_) => MAPPER_TYPE_TEMPORAL_RANGE.to_string(),
            Self::Image(_) => MAPPER_TYPE_IMAGE_RANGE.to_string(),
            Self::Sequence(_, _) => MAPPER_TYPE_SEQUENCE_RANGE.to_string(),
            Self::Object(_) => MAPPER_TYPE_OBJECT_RANGE.to_string(),
        }
    }

    fn to_json(&self) -> Result<String, Error> {
        match self {
            Self::Integer(mapper) => mapper.spec().map(|spec| spec.to_json()),
            Self::Float(mapper) => mapper.to_json(),
            Self::Boolean(mapper) => mapper.to_json(),
            Self::Text(mapper) => mapper.to_json(),
            Self::Categorical(mapper) => mapper.to_json(),
            Self::Temporal(mapper) => mapper.to_json(),
            Self::Image(mapper) => mapper.to_json(),
            Self::Sequence(mapper, allow_empty) => {
                let nested = mapper.to_json()?;
                let spec = ObjectSequenceMapperSpec {
                    allow_empty: *allow_empty,
                    mapper_json: nested,
                };
                Ok(spec.to_json())
            }
            Self::Object(mapper) => mapper.to_json(),
        }
    }

    fn map(&self, value: &ObjectValue) -> Result<f64, Error> {
        match self {
            Self::Integer(mapper) => match value {
                ObjectValue::Integer(v) => mapper.map_value(*v),
                _ => Err(Error::UnsupportedType("integer field expects integer".to_string())),
            },
            Self::Float(mapper) => match value {
                ObjectValue::Float(v) => mapper.map_value(*v),
                _ => Err(Error::UnsupportedType("float field expects float".to_string())),
            },
            Self::Boolean(mapper) => match value {
                ObjectValue::Boolean(v) => Ok(mapper.map_value(*v)),
                _ => Err(Error::UnsupportedType("boolean field expects bool".to_string())),
            },
            Self::Text(mapper) => match value {
                ObjectValue::Text(v) => {
                    let mapped = mapper.map_value(v)?;
                    Ok(mean(mapped))
                }
                _ => Err(Error::UnsupportedType("text field expects text".to_string())),
            },
            Self::Categorical(mapper) => match value {
                ObjectValue::Text(v) => mapper.map_value(v),
                _ => Err(Error::UnsupportedType("categorical field expects text token".to_string())),
            },
            Self::Temporal(mapper) => match value {
                ObjectValue::Float(v) => mapper.map_value(*v),
                _ => Err(Error::UnsupportedType("temporal field expects float".to_string())),
            },
            Self::Image(mapper) => match value {
                ObjectValue::Bytes(v) => Ok(mean(mapper.map_value(v)?)),
                ObjectValue::Sequence(row) => {
                    let nested = row
                        .iter()
                        .map(|child| match child {
                            ObjectValue::Bytes(bytes) => mapper.map_value(bytes),
                            _ => Err(Error::UnsupportedType(
                                "image sequence expects only byte values".to_string(),
                            )),
                        })
                        .collect::<Result<Vec<_>, _>>()?;
                    if nested.is_empty() {
                        if mapper.allow_empty {
                            Ok(mean(vec![0.0]))
                        } else {
                            Err(Error::InvalidValue)
                        }
                    } else {
                        Ok(mean(
                            nested.into_iter().flatten().collect::<Vec<f64>>(),
                        ))
                    }
                }
                _ => Err(Error::UnsupportedType("image field expects byte data".to_string())),
            },
            Self::Sequence(mapper, allow_empty) => match value {
                ObjectValue::Sequence(values) => {
                    if values.is_empty() && !*allow_empty {
                        return Err(Error::InvalidValue);
                    }
                    if values.is_empty() {
                        return Ok(0.0);
                    }
                    let mapped = values.iter().map(|entry| mapper.map(entry)).collect::<Result<Vec<_>, _>>()?;
                    Ok(mean(mapped))
                }
                _ => Err(Error::UnsupportedType("sequence field expects sequence".to_string())),
            },
            Self::Object(mapper) => match value {
                ObjectValue::Object(fields) => {
                    let mapped = mapper.map(fields)?;
                    Ok(mean(mapped))
                }
                _ => Err(Error::UnsupportedType("object field expects object".to_string())),
            },
        }
    }
}

fn mean(values: Vec<f64>) -> f64 {
    if values.is_empty() {
        return 0.0;
    }
    let total: f64 = values.iter().sum();
    let count = values.len() as f64;
    let value = total / count;
    if value < -1.0 {
        -1.0
    } else if value > 1.0 {
        1.0
    } else {
        value
    }
}

fn duplicate_object_field_names(names: &[&str]) -> bool {
    for i in 0..names.len() {
        for j in (i + 1)..names.len() {
            if names[i] == names[j] {
                return true;
            }
        }
    }
    false
}

impl TemporalMapperSpec {
    pub fn to_json(&self) -> String {
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"input_range\":[{},{}],\"output_range\":[{},{}],\"clip\":{}}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            self.input_range[0],
            self.input_range[1],
            self.output_range[0],
            self.output_range[1],
            if self.clip { "true" } else { "false" }
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            input_range: extract_f64_pair(text, "input_range")?,
            output_range: extract_f64_pair(text, "output_range")?,
            clip: extract_bool(text, "clip")?,
        })
    }
}

impl BooleanMapperSpec {
    pub fn to_json(&self) -> String {
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"false_value\":{},\"true_value\":{}}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            self.false_value,
            self.true_value
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            false_value: extract_f64(text, "false_value")?,
            true_value: extract_f64(text, "true_value")?,
        })
    }
}

impl CategoricalMapperSpec {
    pub fn to_json(&self) -> String {
        let tokens = self
            .tokens
            .iter()
            .map(|token| format!("\"{}\"", escape_json(token)))
            .collect::<Vec<_>>()
            .join(",");
        format!(
            "{{\"spec_version\":\"{}\",\"mapper_type\":\"{}\",\"tokens\":[{}],\"output_range\":[{},{}]}}",
            escape_json(&self.spec_version),
            escape_json(&self.mapper_type),
            tokens,
            self.output_range[0],
            self.output_range[1]
        )
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Ok(Self {
            spec_version: extract_string(text, "spec_version")?,
            mapper_type: extract_string(text, "mapper_type")?,
            tokens: extract_string_vec(text, "tokens")?,
            output_range: extract_f64_pair(text, "output_range")?,
        })
    }
}

pub struct FloatRangeMapper {
    pub input_range: [f64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
    pub allow_integer: bool,
}

impl FloatRangeMapper {
    pub fn new(
        input_range: [f64; 2],
        output_range: [f64; 2],
        clip: bool,
        allow_integer: bool,
    ) -> Result<Self, Error> {
        validate_float_range(input_range)?;
        validate_float_range(output_range)?;
        Ok(Self {
            input_range,
            output_range,
            clip,
            allow_integer,
        })
    }

    pub fn new_default(input_min: f64, input_max: f64) -> Result<Self, Error> {
        Self::new([input_min, input_max], [-1.0, 1.0], false, true)
    }

    pub fn map_value(&self, value: f64) -> Result<f64, Error> {
        if !value.is_finite() {
            return Err(Error::InvalidValue);
        }
        self.map_scalar(value)
    }

    pub fn map_int_value(&self, value: i64) -> Result<f64, Error> {
        if !self.allow_integer {
            return Err(Error::InvalidValue);
        }
        self.map_scalar(value as f64)
    }

    pub fn map(&self, value: f64) -> Result<f64, Error> {
        self.map_value(value)
    }

    pub fn spec(&self) -> Result<FloatMapperSpec, Error> {
        Ok(FloatMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_FLOAT_RANGE.to_string(),
            input_range: self.input_range,
            output_range: self.output_range,
            clip: self.clip,
            allow_integer: self.allow_integer,
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(FloatMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: FloatMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_FLOAT_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_FLOAT_RANGE
            )));
        }
        Self::new(spec.input_range, spec.output_range, spec.clip, spec.allow_integer)
    }

    fn map_scalar(&self, value: f64) -> Result<f64, Error> {
        let mut bounded = value;
        if value < self.input_range[0] || value > self.input_range[1] {
            if !self.clip {
                return Err(Error::OutOfRange);
            }
            if value < self.input_range[0] {
                bounded = self.input_range[0];
            }
            if value > self.input_range[1] {
                bounded = self.input_range[1];
            }
        }
        let input_span = self.input_range[1] - self.input_range[0];
        let output_span = self.output_range[1] - self.output_range[0];
        Ok(self.output_range[0] + ((bounded - self.input_range[0]) / input_span) * output_span)
    }
}

pub struct BooleanRangeMapper {
    pub false_value: f64,
    pub true_value: f64,
}

pub struct TemporalRangeMapper {
    pub input_range: [f64; 2],
    pub output_range: [f64; 2],
    pub clip: bool,
}

impl TemporalRangeMapper {
    pub fn new(
        input_range: [f64; 2],
        output_range: [f64; 2],
        clip: bool,
    ) -> Result<Self, Error> {
        validate_float_range(input_range)?;
        validate_float_range(output_range)?;
        Ok(Self { input_range, output_range, clip })
    }

    pub fn new_default(input_min: f64, input_max: f64) -> Result<Self, Error> {
        Self::new([input_min, input_max], [-1.0, 1.0], false)
    }

    pub fn map_value(&self, value: f64) -> Result<f64, Error> {
        if !value.is_finite() {
            return Err(Error::InvalidValue);
        }
        self.map_scalar(value)
    }

    pub fn map(&self, value: f64) -> Result<f64, Error> {
        self.map_value(value)
    }

    pub fn spec(&self) -> Result<TemporalMapperSpec, Error> {
        Ok(TemporalMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_TEMPORAL_RANGE.to_string(),
            input_range: self.input_range,
            output_range: self.output_range,
            clip: self.clip,
        })
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec()?.to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(TemporalMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: TemporalMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_TEMPORAL_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_TEMPORAL_RANGE
            )));
        }
        Self::new(spec.input_range, spec.output_range, spec.clip)
    }

    fn map_scalar(&self, value: f64) -> Result<f64, Error> {
        let mut bounded = value;
        if value < self.input_range[0] || value > self.input_range[1] {
            if !self.clip {
                return Err(Error::OutOfRange);
            }
            if value < self.input_range[0] {
                bounded = self.input_range[0];
            }
            if value > self.input_range[1] {
                bounded = self.input_range[1];
            }
        }
        let input_span = self.input_range[1] - self.input_range[0];
        let output_span = self.output_range[1] - self.output_range[0];
        Ok(self.output_range[0] + ((bounded - self.input_range[0]) / input_span) * output_span)
    }
}

impl BooleanRangeMapper {
    pub fn new(false_value: f64, true_value: f64) -> Result<Self, Error> {
        if !false_value.is_finite() || !true_value.is_finite() {
            return Err(Error::InvalidValue);
        }
        Ok(Self { false_value, true_value })
    }

    pub fn new_default() -> Result<Self, Error> {
        Self::new(-1.0, 1.0)
    }

    pub fn map_value(&self, value: bool) -> f64 {
        if value {
            self.true_value
        } else {
            self.false_value
        }
    }

    pub fn map(&self, value: bool) -> f64 {
        self.map_value(value)
    }

    pub fn spec(&self) -> BooleanMapperSpec {
        BooleanMapperSpec {
            spec_version: SPEC_VERSION.to_string(),
            mapper_type: MAPPER_TYPE_BOOLEAN_RANGE.to_string(),
            false_value: self.false_value,
            true_value: self.true_value,
        }
    }

    pub fn to_json(&self) -> Result<String, Error> {
        Ok(self.spec().to_json())
    }

    pub fn from_json(text: &str) -> Result<Self, Error> {
        Self::from_spec(BooleanMapperSpec::from_json(text)?)
    }

    pub fn from_spec(spec: BooleanMapperSpec) -> Result<Self, Error> {
        if spec.spec_version != SPEC_VERSION {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported spec_version {:?}; expected {:?}",
                spec.spec_version, SPEC_VERSION
            )));
        }
        if spec.mapper_type != MAPPER_TYPE_BOOLEAN_RANGE {
            return Err(Error::UnsupportedSpec(format!(
                "unsupported mapper_type {:?}; expected {:?}",
                spec.mapper_type, MAPPER_TYPE_BOOLEAN_RANGE
            )));
        }
        Self::new(spec.false_value, spec.true_value)
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

fn extract_optional_f64(text: &str, key: &str) -> Result<Option<f64>, Error> {
    let needle = format!("\"{key}\":");
    let Some(start) = text.find(&needle) else {
        return Ok(None);
    };
    let rest = &text[start + needle.len()..];
    let end = rest.find([',', '}']).unwrap_or(rest.len());
    let value = rest[..end].trim();
    if value.is_empty() {
        return Ok(None);
    }
    let parsed = value
        .parse()
        .map_err(|_| Error::Json(format!("invalid number in {key}")))?;
    Ok(Some(parsed))
}

fn extract_json_array(text: &str, key: &str) -> Result<String, Error> {
    let needle = format!("\"{key}\":");
    let start = text
        .find(&needle)
        .ok_or_else(|| Error::Json(format!("missing key {key}")))? 
        + needle.len();
    let mut rest = &text[start..];
    rest = rest.trim_start();
    if !rest.starts_with('[') {
        return Err(Error::Json(format!("invalid array for {key}")));
    }

    let mut in_string = false;
    let mut escape = false;
    let mut depth = 0i32;
    let mut end_index = None;
    for (offset, ch) in rest.char_indices() {
        if in_string {
            if escape {
                escape = false;
                continue;
            }
            if ch == '\\' {
                escape = true;
                continue;
            }
            if ch == '"' {
                in_string = false;
            }
            continue;
        }
        if ch == '"' {
            in_string = true;
            continue;
        }
        if ch == '[' {
            depth += 1;
        } else if ch == ']' {
            depth -= 1;
            if depth == 0 {
                end_index = Some(offset + 1);
                break;
            }
            if depth < 0 {
                return Err(Error::Json(format!("invalid array for {key}")));
            }
        }
    }
    let end_index = end_index.ok_or_else(|| Error::Json(format!("unterminated array for {key}")))?;
    Ok(rest[..end_index].to_string())
}

fn split_top_level_json_objects(text: &str) -> Result<Vec<String>, Error> {
    if !text.starts_with('[') || !text.ends_with(']') {
        return Err(Error::Json("invalid array".to_string()));
    }
    let body = &text[1..text.len() - 1];
    let mut objects = Vec::new();
    let mut in_string = false;
    let mut escape = false;
    let mut brace_depth = 0i32;
    let mut start = None;

    let trimmed = body.trim();
    if trimmed.is_empty() {
        return Ok(objects);
    }

    for (offset, ch) in trimmed.char_indices() {
        if in_string {
            if escape {
                escape = false;
                continue;
            }
            if ch == '\\' {
                escape = true;
                continue;
            }
            if ch == '"' {
                in_string = false;
            }
            continue;
        }
        match ch {
            '"' => {
                in_string = true;
            }
            '{' => {
                if brace_depth == 0 {
                    start = Some(offset);
                }
                brace_depth += 1;
            }
            '}' => {
                brace_depth -= 1;
                if brace_depth < 0 {
                    return Err(Error::Json("invalid object array".to_string()));
                }
                if brace_depth == 0 {
                    if let Some(s) = start {
                        let end = offset + ch.len_utf8();
                        objects.push(trimmed[s..end].to_string());
                        start = None;
                    } else {
                        return Err(Error::Json("invalid object array".to_string()));
                    }
                }
            }
            _ => {}
        }
    }
    if brace_depth != 0 {
        return Err(Error::Json("unterminated object array".to_string()));
    }
    Ok(objects)
}

fn extract_string_vec(text: &str, key: &str) -> Result<Vec<String>, Error> {
    let needle = format!("\"{key}\":[");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    let end = rest.find(']').ok_or_else(|| Error::Json(format!("unterminated array for {key}")))?;
    let mut tokens = Vec::new();
    let mut slice = rest[..end].trim();
    if slice.is_empty() {
        return Ok(tokens);
    }
    while !slice.is_empty() {
        if !slice.starts_with('"') {
            return Err(Error::Json(format!("{key} must contain strings")));
        }
        slice = &slice[1..];
        let token_end = slice.find('"').ok_or_else(|| Error::Json(format!("unterminated string in {key}")))?;
        let token = slice[..token_end].replace("\\\"", "\"").replace("\\\\", "\\");
        tokens.push(token);
        slice = slice[token_end + 1..].trim_start();
        if slice.starts_with(',') {
            slice = slice[1..].trim_start();
            continue;
        }
        if slice.is_empty() {
            break;
        }
        return Err(Error::Json(format!("{key} must contain comma-separated strings")));
    }
    Ok(tokens)
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

fn extract_f64(text: &str, key: &str) -> Result<f64, Error> {
    let needle = format!("\"{key}\":");
    let start = text.find(&needle).ok_or_else(|| Error::Json(format!("missing key {key}")))? + needle.len();
    let rest = &text[start..];
    let end = rest.find([',', '}']).unwrap_or(rest.len());
    rest[..end]
        .trim()
        .parse()
        .map_err(|_| Error::Json(format!("invalid number in {key}")))
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

fn validate_float_range(range: [f64; 2]) -> Result<(), Error> {
    if !range[0].is_finite() || !range[1].is_finite() {
        return Err(Error::InvalidValue);
    }
    if !(range[1] > range[0]) {
        return Err(Error::InvalidRange);
    }
    Ok(())
}

fn validate_alphabet(alphabet: &str) -> Result<(), Error> {
    if alphabet.is_empty() {
        return Err(Error::InvalidValue);
    }
    let mut count = 0;
    for (i, ch) in alphabet.chars().enumerate() {
        count += 1;
        for other in alphabet.chars().take(i) {
            if other == ch {
                return Err(Error::InvalidValue);
            }
        }
    }
    if count < 2 {
        return Err(Error::InvalidValue);
    }
    Ok(())
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
    use super::{BooleanRangeMapper, CategoricalMapperSpec, CategoricalRangeMapper, FloatRangeMapper, IntegerRangeMapper, MapperSpec, TemporalRangeMapper};
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

    #[test]
    fn float_mapper_round_trip() {
        let mapper = FloatRangeMapper::new_default(0.0, 10.0).unwrap();
        assert_eq!(mapper.map_value(5.0).unwrap(), 0.0);
        assert_eq!(mapper.map_int_value(5).unwrap(), 0.0);

        let text = mapper.to_json().unwrap();
        let restored = FloatRangeMapper::from_json(&text).unwrap();
        assert_eq!(restored.map_value(10.0).unwrap(), 1.0);

        let clipped = FloatRangeMapper::new([0.0, 1.0], [-1.0, 1.0], true, true).unwrap();
        assert_eq!(clipped.map_value(2.0).unwrap(), 1.0);
    }

    #[test]
    fn boolean_mapper_round_trip() {
        let mapper = BooleanRangeMapper::new_default().unwrap();
        assert_eq!(mapper.map_value(false), -1.0);
        assert_eq!(mapper.map_value(true), 1.0);

        let text = mapper.to_json().unwrap();
        let restored = BooleanRangeMapper::from_json(&text).unwrap();
        assert_eq!(restored.map_value(true), 1.0);
    }

    #[test]
    fn categorical_mapper_round_trip() {
        let mapper = CategoricalRangeMapper::new(
            vec!["red".to_string(), "green".to_string(), "blue".to_string()],
            [-1.0, 1.0],
        ).unwrap();
        assert_eq!(mapper.map_value("red").unwrap(), -1.0);
        assert_eq!(mapper.map_value("green").unwrap(), 0.0);
        assert_eq!(mapper.map_value("blue").unwrap(), 1.0);
        assert_eq!(mapper.map_value("green").unwrap(), mapper.map_value("green").unwrap());

        let text = mapper.to_json().unwrap();
        let restored = CategoricalRangeMapper::from_json(&text).unwrap();
        assert_eq!(restored.map_value("blue").unwrap(), 1.0);

        let spec = CategoricalMapperSpec {
            spec_version: super::SPEC_VERSION.to_string(),
            mapper_type: super::MAPPER_TYPE_CATEGORICAL_RANGE.to_string(),
            tokens: vec!["a".to_string(), "b".to_string()],
            output_range: [-1.0, 1.0],
        };
        let json = spec.to_json();
        let parsed = CategoricalMapperSpec::from_json(&json).unwrap();
        assert_eq!(parsed.tokens, vec!["a".to_string(), "b".to_string()]);
    }

    #[test]
    fn temporal_mapper_round_trip() {
        let mapper = TemporalRangeMapper::new_default(-10.0, 10.0).unwrap();
        assert_eq!(mapper.map_value(0.0).unwrap(), 0.0);

        let text = mapper.to_json().unwrap();
        let restored = TemporalRangeMapper::from_json(&text).unwrap();
        assert_eq!(restored.map_value(0.0).unwrap(), 0.0);
    }
}
