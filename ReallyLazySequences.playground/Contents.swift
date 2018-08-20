
import ReallyLazySequences

let c = SimpleSequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }
    .consume { (value: Double?) -> Void in
        guard let value = value else { return }
        print(value)
    }

print(type(of:c))

do {
    try [24, 4, 6, nil, 14].forEach {_ = try c.process($0) }
} catch {
    print(error)
}
