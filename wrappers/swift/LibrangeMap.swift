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

func runSelfCheck() {
    let mapper = IntegerRangeMapper(inputMin: 0, inputMax: 100)
    assert(mapper.mapValue(0) == -1.0)
    assert(mapper.mapValue(50) == 0.0)
    assert(mapper.mapValue(100) == 1.0)
}

runSelfCheck()
