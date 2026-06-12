use librangemap::{
    BooleanRangeMapper,
    CategoricalRangeMapper,
    ImageMapperSpec,
    ImageRangeMapper,
    IntegerRangeMapper,
    MapperSpec,
    ObjectFieldSpec,
    ObjectFieldValue,
    ObjectRangeMapper,
    ObjectValue,
    ObjectValueMapper,
    SequenceMapperSpec,
    SequenceRangeMapper,
    SPEC_VERSION,
    TextRangeMapper,
};

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

    let repeated_first = mapper.map_value(50).unwrap();
    let repeated_second = mapper.map_value(50).unwrap();
    assert_eq!(repeated_first, repeated_second);

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

#[test]
fn text_mapper_round_trip() {
    let mapper = TextRangeMapper::new_alphabet("ABC".to_string(), [-1.0, 1.0], false, false, None).unwrap();
    assert_eq!(mapper.map_value("CA").unwrap(), vec![1.0, -1.0]);
    assert_eq!(mapper.map_value("CA").unwrap(), vec![1.0, -1.0]);

    let text = mapper.to_json().unwrap();
    let restored = TextRangeMapper::from_json(&text).unwrap();
    assert_eq!(restored.map_value("B").unwrap(), vec![0.0]);

    let bytes = TextRangeMapper::new_bytes([-1.0, 1.0], false, false, None).unwrap();
    assert_eq!(
        bytes.map_bytes_value(&[0, 127, 255]).unwrap(),
        vec![-1.0, -0.0039215686274509665, 1.0]
    );

    let duplicate = TextRangeMapper::new_alphabet("AAB".to_string(), [-1.0, 1.0], false, false, None);
    assert!(duplicate.is_err());

    let unknown = mapper.map_value("Z");
    assert!(unknown.is_err());
}

#[test]
fn sequence_mapper_round_trip() {
    let integer_mapper = IntegerRangeMapper::new_default(0, 100).unwrap();
    let sequence_mapper = SequenceRangeMapper::new(|value: &i64| integer_mapper.map_value(*value), false).unwrap();

    let mapped = sequence_mapper.map_value(&[0, 50, 100]).unwrap();
    assert_eq!(mapped, vec![-1.0, 0.0, 1.0]);
    assert_eq!(sequence_mapper.map_value(&[0, 50, 100]).unwrap(), mapped);

    let nested_mapper = SequenceRangeMapper::new(
        |row: &Vec<i64>| sequence_mapper.map_value(row.as_slice()),
        false,
    )
    .unwrap();
    let nested = nested_mapper
        .map_value(&[vec![0, 50], vec![100]])
        .unwrap();
    assert_eq!(nested, vec![vec![-1.0, 0.0], vec![1.0]]);

    let empty = sequence_mapper.map_value(&[]);
    assert!(empty.is_err());

    let spec = sequence_mapper.spec();
    assert_eq!(spec.spec_version, SPEC_VERSION);
    assert_eq!(spec.mapper_type, "sequence_range");
    assert!(!spec.allow_empty);
    assert_eq!(
        SequenceMapperSpec::from_json(&sequence_mapper.to_json()),
        Ok(spec)
    );
}

#[test]
fn image_mapper_round_trip() {
    let mapper = ImageRangeMapper::new_default().unwrap();
    assert_eq!(mapper.map_value(&[0, 127, 255]).unwrap(), vec![-1.0, -0.0039215686274509665, 1.0]);
    assert_eq!(mapper.map_value(&[0, 127, 255]).unwrap(), mapper.map_value(&[0, 127, 255]).unwrap());

    let nested = mapper.map_nested_value(&[vec![0, 127], vec![255]]).unwrap();
    assert_eq!(nested, vec![vec![-1.0, -0.0039215686274509665], vec![1.0]]);

    let spec = mapper.spec().unwrap();
    assert_eq!(spec.spec_version, SPEC_VERSION);
    assert_eq!(spec.mapper_type, "image_range");
    assert!(!spec.allow_empty);
    assert_eq!(ImageMapperSpec::from_json(&mapper.to_json().unwrap()), Ok(spec));

    let empty = mapper.map_value(&[]);
    assert!(empty.is_err());
}

#[test]
fn object_mapper_round_trip_and_failures() {
    let status_mapper = ObjectFieldSpec {
        name: "status".to_string(),
        allow_missing: false,
        missing_value: None,
        mapper: ObjectValueMapper::Categorical(CategoricalRangeMapper::new_default(vec![
            "pending".to_string(),
            "active".to_string(),
            "complete".to_string(),
        ]).unwrap()),
    };
    let active_mapper = ObjectFieldSpec {
        name: "active".to_string(),
        allow_missing: false,
        missing_value: None,
        mapper: ObjectValueMapper::Boolean(BooleanRangeMapper::new_default().unwrap()),
    };
    let score_mapper = ObjectFieldSpec {
        name: "score".to_string(),
        allow_missing: false,
        missing_value: None,
        mapper: ObjectValueMapper::Sequence(
            Box::new(ObjectValueMapper::Integer(
                IntegerRangeMapper::new_default(0, 100).unwrap(),
            )),
            false,
        ),
    };
    let object_mapper = ObjectRangeMapper::new(vec![status_mapper, active_mapper, score_mapper], false).unwrap();

    let input = vec![
        ObjectFieldValue {
            name: "active".to_string(),
            value: ObjectValue::Boolean(true),
        },
        ObjectFieldValue {
            name: "status".to_string(),
            value: ObjectValue::Text("complete".to_string()),
        },
        ObjectFieldValue {
            name: "score".to_string(),
            value: ObjectValue::Sequence(vec![
                ObjectValue::Integer(0),
                ObjectValue::Integer(50),
                ObjectValue::Integer(100),
            ]),
        },
    ];

    let mapped = object_mapper.map(&input).unwrap();
    assert_eq!(mapped.len(), 3);
    assert_eq!(mapped[2], 0.0);
    assert_eq!(mapped, object_mapper.map(&input).unwrap());
    let spec = object_mapper.to_json().unwrap();
    let restored = ObjectRangeMapper::from_json(&spec).unwrap();
    assert_eq!(restored.map(&input).unwrap(), mapped);

    let unknown_field = vec![
        ObjectFieldValue {
            name: "active".to_string(),
            value: ObjectValue::Boolean(true),
        },
        ObjectFieldValue {
            name: "status".to_string(),
            value: ObjectValue::Text("complete".to_string()),
        },
        ObjectFieldValue {
            name: "extra".to_string(),
            value: ObjectValue::Integer(1),
        },
        ObjectFieldValue {
            name: "score".to_string(),
            value: ObjectValue::Sequence(vec![
                ObjectValue::Integer(10),
            ]),
        },
    ];
    assert!(object_mapper.map(&unknown_field).is_err());

    let missing_field = vec![
        ObjectFieldValue {
            name: "active".to_string(),
            value: ObjectValue::Boolean(true),
        },
        ObjectFieldValue {
            name: "status".to_string(),
            value: ObjectValue::Text("complete".to_string()),
        },
    ];
    assert!(object_mapper.map(&missing_field).is_err());
}
