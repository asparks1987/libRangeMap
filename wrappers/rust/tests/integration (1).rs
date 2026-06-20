use librangemap::{IntegerRangeMapper, MapperSpec, SPEC_VERSION};

#[test]
fn verify_public_api() {
    let mapper = IntegerRangeMapper::new_default(0, 100).unwrap();
    assert_eq!(mapper.map_value(0).unwrap(), -1.0);
    assert_eq!(mapper.map_value(50).unwrap(), 0.0);
    assert_eq!(mapper.map_value(100).unwrap(), 1.0);

    let spec = mapper.spec().unwrap();
    assert_eq!(spec.spec_version, SPEC_VERSION);

    let restored = IntegerRangeMapper::from_json(&mapper.to_json().unwrap()).unwrap();
    assert_eq!(restored.map_value(50).unwrap(), 0.0);

    let clipped = IntegerRangeMapper::from_spec(MapperSpec {
        spec_version: SPEC_VERSION.to_string(),
        mapper_type: "integer_range".to_string(),
        input_range: [0, 10],
        output_range: [-1.0, 1.0],
        clip: true,
        name: None,
    })
    .unwrap();
    assert_eq!(clipped.map_value(-5).unwrap(), -1.0);

    let unsupported = MapperSpec {
        spec_version: SPEC_VERSION.to_string(),
        mapper_type: "other".to_string(),
        input_range: [0, 10],
        output_range: [-1.0, 1.0],
        clip: false,
        name: None,
    };
    assert!(IntegerRangeMapper::from_spec(unsupported).is_err());
}
