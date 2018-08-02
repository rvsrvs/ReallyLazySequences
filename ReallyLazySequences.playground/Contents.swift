
import ReallyLazySequences

let s = ReallyLazySequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }
    .consume { (value: Double?) -> Void in
        guard let value = value else { return }
        print(value)
    }

print(type(of:s))

try s.push(2)

