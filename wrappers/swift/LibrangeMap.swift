import Foundation

struct IntegerRangeMapper {
    let inputMin: Int64
    let inputMax: Int64
    let outputMin: Double
    let outputMax: Double
    let clip: Bool

    init(inputMin: Int64, inputMax: Int64, outputMin: Double = -1.0, outputMax: Double = 1.0, clip: Bool = false) {
        precondition(inputMin < inputMax, "inputMin must be less than inputMax")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        self.inputMin = inputMin
        self.inputMax = inputMax
        self.outputMin = outputMin
        self.outputMax = outputMax
        self.clip = clip
    }

    func mapValue(_ value: Int64) -> Double {
        var v = value
        if clip {
            if v < inputMin { v = inputMin }
            if v > inputMax { v = inputMax }
        } else {
            precondition(v >= inputMin && v <= inputMax, "value out of range")
        }
        let inputSpan = Double(inputMax - inputMin)
        let outputSpan = outputMax - outputMin
        return outputMin + (Double(v - inputMin) / inputSpan) * outputSpan
    }
}

struct FloatRangeMapper {
    let inputMin: Double
    let inputMax: Double
    let outputMin: Double
    let outputMax: Double
    let clip: Bool
    let allowInteger: Bool

    init(inputMin: Double, inputMax: Double, outputMin: Double = -1.0, outputMax: Double = 1.0, clip: Bool = false, allowInteger: Bool = true) {
        precondition(inputMin.isFinite && inputMax.isFinite && outputMin.isFinite && outputMax.isFinite, "ranges must be finite")
        precondition(inputMin < inputMax, "inputMin must be less than inputMax")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        self.inputMin = inputMin
        self.inputMax = inputMax
        self.outputMin = outputMin
        self.outputMax = outputMax
        self.clip = clip
        self.allowInteger = allowInteger
    }

    func mapValue(_ value: Double) -> Double {
        precondition(value.isFinite, "value must be finite")
        var v = value
        if clip {
            if v < inputMin { v = inputMin }
            if v > inputMax { v = inputMax }
        } else {
            precondition(v >= inputMin && v <= inputMax, "value out of range")
        }
        let inputSpan = inputMax - inputMin
        let outputSpan = outputMax - outputMin
        return outputMin + ((v - inputMin) / inputSpan) * outputSpan
    }

    func mapIntegerValue(_ value: Int64) -> Double {
        precondition(allowInteger, "integer input is disabled by policy")
        return mapValue(Double(value))
    }
}

struct BooleanRangeMapper {
    let falseValue: Double
    let trueValue: Double

    init(falseValue: Double = -1.0, trueValue: Double = 1.0) {
        precondition(falseValue.isFinite && trueValue.isFinite, "boolean outputs must be finite")
        self.falseValue = falseValue
        self.trueValue = trueValue
    }

    func mapValue(_ value: Bool) -> Double {
        value ? trueValue : falseValue
    }
}

struct TextRangeMapper {
    enum Mode {
        case codepoint
        case byte
        case alphabet([Character])
    }

    let mode: Mode
    let outputMin: Double
    let outputMax: Double

    init(mode: Mode = .codepoint, outputMin: Double = -1.0, outputMax: Double = 1.0) {
        precondition(outputMin.isFinite && outputMax.isFinite, "text outputs must be finite")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        if case let .alphabet(alphabet) = mode {
            precondition(!alphabet.isEmpty, "alphabet must not be empty")
            precondition(Set(alphabet).count == alphabet.count, "alphabet must be unique")
        }
        self.mode = mode
        self.outputMin = outputMin
        self.outputMax = outputMax
    }

    func mapValue(_ value: String) -> [Double] {
        precondition(!value.isEmpty, "empty text input is invalid by default")

        switch mode {
        case .codepoint:
            return value.unicodeScalars.map { scalar in
                outputMin + ((Double(scalar.value) / 255.0) * (outputMax - outputMin))
            }
        case .byte:
            return Array(value.utf8).map { byte in
                outputMin + ((Double(byte) / 255.0) * (outputMax - outputMin))
            }
        case let .alphabet(alphabet):
            var indexByCharacter = [Character: Int]()
            for (position, character) in alphabet.enumerated() {
                indexByCharacter[character] = position
            }

            return value.map { character in
                guard let index = indexByCharacter[character] else {
                    preconditionFailure("unknown text token")
                }
                if alphabet.count == 1 {
                    return (outputMin + outputMax) / 2.0
                }
                let normalized = Double(index) / Double(alphabet.count - 1)
                return outputMin + normalized * (outputMax - outputMin)
            }
        }
    }
}

struct BytesRangeMapper {
    let outputMin: Double
    let outputMax: Double
    let clip: Bool
    let allowEmpty: Bool

    init(outputMin: Double = -1.0, outputMax: Double = 1.0, clip: Bool = false, allowEmpty: Bool = false) {
        precondition(outputMin.isFinite && outputMax.isFinite, "byte outputs must be finite")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        self.outputMin = outputMin
        self.outputMax = outputMax
        self.clip = clip
        self.allowEmpty = allowEmpty
    }

    func mapValue(_ value: [UInt8]) -> [Double] {
        precondition(allowEmpty || !value.isEmpty, "empty byte input is invalid by default")
        return value.map { byte in
            let bounded: UInt8
            if clip {
                bounded = min(max(byte, 0), 255)
            } else {
                precondition(byte <= 255, "byte value out of range")
                bounded = byte
            }
            return outputMin + ((Double(bounded) / 255.0) * (outputMax - outputMin))
        }
    }

    func mapValue(_ value: Data) -> [Double] {
        mapValue([UInt8](value))
    }
}

struct ImageMapperSpec {
    let specVersion: String
    let mapperType: String
    let outputMin: Double
    let outputMax: Double
    let clip: Bool
    let allowEmpty: Bool

    func toJson() -> String {
        return "{\"spec_version\":\"\(specVersion)\",\"mapper_type\":\"\(mapperType)\",\"output_range\":[\(outputMin),\(outputMax)],\"clip\":\(clip ? "true" : "false"),\"allow_empty\":\(allowEmpty ? "true" : "false")}"
    }
}

struct ImageRangeMapper {
    let bytesMapper: BytesRangeMapper

    init(outputMin: Double = -1.0, outputMax: Double = 1.0, clip: Bool = false, allowEmpty: Bool = false) {
        self.bytesMapper = BytesRangeMapper(outputMin: outputMin, outputMax: outputMax, clip: clip, allowEmpty: allowEmpty)
    }

    func mapValue(_ value: [UInt8]) -> [Double] {
        bytesMapper.mapValue(value)
    }

    func mapRows(_ values: [[UInt8]]) -> [[Double]] {
        precondition(bytesMapper.allowEmpty || !values.isEmpty, "empty image input is invalid by default")
        return values.map(bytesMapper.mapValue)
    }

    func spec() -> ImageMapperSpec {
        ImageMapperSpec(
            specVersion: "1.0-alpha",
            mapperType: "image_range",
            outputMin: bytesMapper.outputMin,
            outputMax: bytesMapper.outputMax,
            clip: bytesMapper.clip,
            allowEmpty: bytesMapper.allowEmpty
        )
    }

    func toJson() -> String {
        spec().toJson()
    }
}

struct CategoricalRangeMapper {
    let tokens: [String]
    private let tokenToIndex: [String: Int]
    let outputMin: Double
    let outputMax: Double

    init(tokens: [String], outputMin: Double = -1.0, outputMax: Double = 1.0) {
        precondition(outputMin.isFinite && outputMax.isFinite, "categorical outputs must be finite")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        precondition(!tokens.isEmpty, "tokens must not be empty")
        precondition(Set(tokens).count == tokens.count, "tokens must be unique")
        self.tokens = tokens
        self.outputMin = outputMin
        self.outputMax = outputMax

        var index = [String: Int]()
        for (position, token) in tokens.enumerated() {
            index[token] = position
        }
        self.tokenToIndex = index
    }

    func mapValue(_ value: String) -> Double {
        guard let index = tokenToIndex[value] else {
            preconditionFailure("unknown categorical token")
        }

        if tokens.count == 1 {
            return (outputMin + outputMax) / 2.0
        }

        let normalized = Double(index) / Double(tokens.count - 1)
        return outputMin + normalized * (outputMax - outputMin)
    }
}

struct SequenceMapperSpec {
    let specVersion: String
    let mapperType: String
    let allowEmpty: Bool

    func toJson() -> String {
        return "{\"spec_version\":\"\(specVersion)\",\"mapper_type\":\"\(mapperType)\",\"allow_empty\":\(allowEmpty ? "true" : "false")}"
    }
}

struct SequenceRangeMapper<Input, Output> {
    let elementMapper: (Input) -> Output
    let allowEmpty: Bool

    init(elementMapper: @escaping (Input) -> Output, allowEmpty: Bool = false) {
        self.elementMapper = elementMapper
        self.allowEmpty = allowEmpty
    }

    func mapValue(_ values: [Input]) -> [Output] {
        precondition(allowEmpty || !values.isEmpty, "empty sequence input is invalid by default")
        return values.map(elementMapper)
    }

    func map(_ values: [Input]) -> [Output] {
        mapValue(values)
    }

    func spec() -> SequenceMapperSpec {
        SequenceMapperSpec(specVersion: "1.0-alpha", mapperType: "sequence_range", allowEmpty: allowEmpty)
    }

    func toJson() -> String {
        spec().toJson()
    }
}

enum ObjectFieldFamily: Equatable {
    case integer
    case float
    case boolean
    case text
    case bytes
    case integerSequence
    case floatSequence
}

enum ObjectFieldValue {
    case integer(Int64)
    case float(Double)
    case boolean(Bool)
    case text(String)
    case bytes([UInt8])
    case integerSequence([Int64])
    case floatSequence([Double])

    var family: ObjectFieldFamily {
        switch self {
        case .integer:
            return .integer
        case .float:
            return .float
        case .boolean:
            return .boolean
        case .text:
            return .text
        case .bytes:
            return .bytes
        case .integerSequence:
            return .integerSequence
        case .floatSequence:
            return .floatSequence
        }
    }
}

struct ObjectFieldInput {
    let name: String
    let value: ObjectFieldValue?

    init(name: String, value: ObjectFieldValue?) {
        precondition(!name.isEmpty, "input field name must not be empty")
        self.name = name
        self.value = value
    }
}

struct ObjectFieldSpec {
    let name: String
    let family: ObjectFieldFamily
    let inputMin: Double
    let inputMax: Double
    let outputMin: Double
    let outputMax: Double
    let clip: Bool
    let allowInteger: Bool
    let falseValue: Double
    let trueValue: Double
    let textMode: TextRangeMapper.Mode
    let allowEmpty: Bool
    let allowMissing: Bool
    let missingValue: Double

    init(
        name: String,
        family: ObjectFieldFamily,
        inputMin: Double = 0.0,
        inputMax: Double = 1.0,
        outputMin: Double = -1.0,
        outputMax: Double = 1.0,
        clip: Bool = false,
        allowInteger: Bool = true,
        falseValue: Double = -1.0,
        trueValue: Double = 1.0,
        textMode: TextRangeMapper.Mode = .codepoint,
        allowEmpty: Bool = false,
        allowMissing: Bool = false,
        missingValue: Double = 0.0
    ) {
        precondition(!name.isEmpty, "schema field name must not be empty")
        precondition(inputMin.isFinite && inputMax.isFinite, "schema input bounds must be finite")
        precondition(outputMin.isFinite && outputMax.isFinite, "schema output bounds must be finite")
        precondition(falseValue.isFinite && trueValue.isFinite, "boolean outputs must be finite")
        precondition(missingValue.isFinite, "missing value must be finite")
        if family == .integer || family == .float || family == .integerSequence || family == .floatSequence {
            precondition(inputMin < inputMax, "inputMin must be less than inputMax")
        }
        if family == .integer || family == .integerSequence {
            precondition(inputMin.rounded() == inputMin && inputMax.rounded() == inputMax, "integer schema bounds must be integral")
        }
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        self.name = name
        self.family = family
        self.inputMin = inputMin
        self.inputMax = inputMax
        self.outputMin = outputMin
        self.outputMax = outputMax
        self.clip = clip
        self.allowInteger = allowInteger
        self.falseValue = falseValue
        self.trueValue = trueValue
        self.textMode = textMode
        self.allowEmpty = allowEmpty
        self.allowMissing = allowMissing
        self.missingValue = missingValue
    }
}

struct ObjectRangeMapper {
    let schema: [ObjectFieldSpec]
    let allowUnknown: Bool

    init(schema: [ObjectFieldSpec], allowUnknown: Bool = false) {
        precondition(!schema.isEmpty, "schema must not be empty")
        let names = schema.map { $0.name }
        precondition(Set(names).count == names.count, "schema field names must be unique")
        self.schema = schema.sorted { $0.name < $1.name }
        self.allowUnknown = allowUnknown
    }

    func mapValue(_ fields: [ObjectFieldInput]) -> [Double] {
        precondition(!fields.isEmpty, "object input must not be empty")
        let inputNames = fields.map { $0.name }
        precondition(Set(inputNames).count == inputNames.count, "input field names must be unique")

        let fieldsByName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0) })
        if !allowUnknown {
            let schemaNames = Set(schema.map { $0.name })
            for fieldName in inputNames {
                precondition(schemaNames.contains(fieldName), "unknown field in object input")
            }
        }

        return schema.map { spec in
            guard let field = fieldsByName[spec.name] else {
                precondition(spec.allowMissing, "missing required field")
                return spec.missingValue
            }
            guard let value = field.value else {
                precondition(spec.allowMissing, "missing required field value")
                return spec.missingValue
            }
            precondition(value.family == spec.family, "field type mismatch")
            return mapField(value, spec: spec)
        }
    }

    private func mapField(_ value: ObjectFieldValue, spec: ObjectFieldSpec) -> Double {
        switch value {
        case let .integer(raw):
            return IntegerRangeMapper(
                inputMin: integerBound(spec.inputMin),
                inputMax: integerBound(spec.inputMax),
                outputMin: spec.outputMin,
                outputMax: spec.outputMax,
                clip: spec.clip
            ).mapValue(raw)
        case let .float(raw):
            return FloatRangeMapper(
                inputMin: spec.inputMin,
                inputMax: spec.inputMax,
                outputMin: spec.outputMin,
                outputMax: spec.outputMax,
                clip: spec.clip,
                allowInteger: spec.allowInteger
            ).mapValue(raw)
        case let .boolean(raw):
            return BooleanRangeMapper(falseValue: spec.falseValue, trueValue: spec.trueValue).mapValue(raw)
        case let .text(raw):
            let mapped = TextRangeMapper(mode: spec.textMode, outputMin: spec.outputMin, outputMax: spec.outputMax).mapValue(raw)
            precondition(!mapped.isEmpty, "text field produced empty output")
            return mapped.reduce(0.0, +) / Double(mapped.count)
        case let .bytes(raw):
            let mapped = BytesRangeMapper(outputMin: spec.outputMin, outputMax: spec.outputMax, clip: spec.clip, allowEmpty: spec.allowEmpty).mapValue(raw)
            if mapped.isEmpty {
                precondition(spec.allowEmpty, "bytes field produced empty output")
                return 0.0
            }
            return mapped.reduce(0.0, +) / Double(mapped.count)
        case let .integerSequence(raw):
            let integerMapper = IntegerRangeMapper(
                inputMin: integerBound(spec.inputMin),
                inputMax: integerBound(spec.inputMax),
                outputMin: spec.outputMin,
                outputMax: spec.outputMax,
                clip: spec.clip
            )
            let mapped = SequenceRangeMapper<Int64, Double>(
                elementMapper: { integerMapper.mapValue($0) },
                allowEmpty: spec.allowEmpty
            ).mapValue(raw)
            precondition(!mapped.isEmpty, "sequence field produced empty output")
            return mapped.reduce(0.0, +) / Double(mapped.count)
        case let .floatSequence(raw):
            let floatMapper = FloatRangeMapper(
                inputMin: spec.inputMin,
                inputMax: spec.inputMax,
                outputMin: spec.outputMin,
                outputMax: spec.outputMax,
                clip: spec.clip,
                allowInteger: spec.allowInteger
            )
            let mapped = SequenceRangeMapper<Double, Double>(
                elementMapper: { floatMapper.mapValue($0) },
                allowEmpty: spec.allowEmpty
            ).mapValue(raw)
            precondition(!mapped.isEmpty, "sequence field produced empty output")
            return mapped.reduce(0.0, +) / Double(mapped.count)
        }
    }

    private func integerBound(_ value: Double) -> Int64 {
        precondition(value.isFinite && value.rounded() == value, "integer schema bounds must be integral")
        return Int64(value)
    }
}

struct TemporalRangeMapper {
    let inputMin: Int64
    let inputMax: Int64
    let outputMin: Double
    let outputMax: Double
    let clip: Bool

    init(inputMin: Int64, inputMax: Int64, outputMin: Double = -1.0, outputMax: Double = 1.0, clip: Bool = false) {
        precondition(inputMin < inputMax, "inputMin must be less than inputMax")
        precondition(outputMin < outputMax, "outputMin must be less than outputMax")
        self.inputMin = inputMin
        self.inputMax = inputMax
        self.outputMin = outputMin
        self.outputMax = outputMax
        self.clip = clip
    }

    func mapValue(_ value: Int64) -> Double {
        var v = value
        if clip {
            if v < inputMin { v = inputMin }
            if v > inputMax { v = inputMax }
        } else {
            precondition(v >= inputMin && v <= inputMax, "value out of range")
        }
        let inputSpan = Double(inputMax - inputMin)
        let outputSpan = outputMax - outputMin
        return outputMin + (Double(v - inputMin) / inputSpan) * outputSpan
    }

    func mapValue(_ value: Date) -> Double {
        let milliseconds = Int64((value.timeIntervalSince1970 * 1000.0).rounded())
        return mapValue(milliseconds)
    }
}

func runSelfCheck() {
    let mapper = IntegerRangeMapper(inputMin: 0, inputMax: 100)
    assert(mapper.mapValue(0) == -1.0)
    assert(mapper.mapValue(50) == 0.0)
    assert(mapper.mapValue(100) == 1.0)
    assert(mapper.mapValue(50) == mapper.mapValue(50))

    let floatMapper = FloatRangeMapper(inputMin: 0.0, inputMax: 10.0)
    assert(floatMapper.mapValue(0.0) == -1.0)
    assert(floatMapper.mapValue(5.0) == 0.0)
    assert(floatMapper.mapValue(10.0) == 1.0)

    let booleanMapper = BooleanRangeMapper()
    assert(booleanMapper.mapValue(false) == -1.0)
    assert(booleanMapper.mapValue(true) == 1.0)

    let textMapper = TextRangeMapper()
    assert(textMapper.mapValue("Ada").count == 3)
    let alphabetMapper = TextRangeMapper(mode: .alphabet(["a", "b", "c"]))
    assert(alphabetMapper.mapValue("abc").count == 3)
    assert(alphabetMapper.mapValue("b")[0] == 0.0)

    let categoricalMapper = CategoricalRangeMapper(tokens: ["alpha", "beta", "gamma"])
    assert(categoricalMapper.mapValue("alpha") == -1.0)
    assert(categoricalMapper.mapValue("beta") == 0.0)
    assert(categoricalMapper.mapValue("gamma") == 1.0)
    assert(categoricalMapper.mapValue("beta") == categoricalMapper.mapValue("beta"))

    let bytesMapper = BytesRangeMapper()
    assert(bytesMapper.mapValue([0, 127, 255]) == [-1.0, -0.0039215686274509665, 1.0])
    assert(bytesMapper.mapValue([0, 127, 255]) == bytesMapper.mapValue([0, 127, 255]))

    let imageMapper = ImageRangeMapper()
    assert(imageMapper.mapValue([0, 127, 255]) == [-1.0, -0.0039215686274509665, 1.0])
    assert(imageMapper.mapRows([[0, 127], [255]]) == [[-1.0, -0.0039215686274509665], [1.0]])
    assert(imageMapper.mapRows([[0, 127], [255]]) == imageMapper.mapRows([[0, 127], [255]]))

    let sequenceMapper = SequenceRangeMapper<Int64, Double>(elementMapper: { IntegerRangeMapper(inputMin: 0, inputMax: 100).mapValue($0) })
    assert(sequenceMapper.mapValue([0, 50, 100]) == [-1.0, 0.0, 1.0])
    assert(sequenceMapper.mapValue([0, 50, 100]) == sequenceMapper.mapValue([0, 50, 100]))
    let nestedSequenceMapper = SequenceRangeMapper<[Int64], [Double]>(elementMapper: { sequenceMapper.mapValue($0) })
    assert(nestedSequenceMapper.mapValue([[0, 50], [100]]) == [[-1.0, 0.0], [1.0]])

    let objectMapper = ObjectRangeMapper(schema: [
        ObjectFieldSpec(name: "age", family: .integer, inputMin: 0, inputMax: 100),
        ObjectFieldSpec(name: "active", family: .boolean)
    ])
    let objectMapped = objectMapper.mapValue([
        ObjectFieldInput(name: "age", value: .integer(0)),
        ObjectFieldInput(name: "active", value: .boolean(true))
    ])
    assert(objectMapped == [1.0, -1.0])
    assert(objectMapped == objectMapper.mapValue([
        ObjectFieldInput(name: "active", value: .boolean(true)),
        ObjectFieldInput(name: "age", value: .integer(0))
    ]))

    let missingObjectMapper = ObjectRangeMapper(schema: [
        ObjectFieldSpec(name: "optional", family: .float, inputMin: 0.0, inputMax: 1.0, allowMissing: true, missingValue: 0.25)
    ])
    assert(missingObjectMapper.mapValue([ObjectFieldInput(name: "optional", value: nil)]) == [0.25])

    let temporalMapper = TemporalRangeMapper(inputMin: 1_700_000_000_000, inputMax: 1_700_000_100_000)
    assert(temporalMapper.mapValue(1_700_000_000_000) == -1.0)
    assert(temporalMapper.mapValue(1_700_000_050_000) == 0.0)
    assert(temporalMapper.mapValue(1_700_000_050_000) == temporalMapper.mapValue(1_700_000_050_000))
    assert(temporalMapper.mapValue(Date(timeIntervalSince1970: 1_700_000_050_000.0 / 1000.0)) == 0.0)
}

runSelfCheck()
