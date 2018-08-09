
import ReallyLazySequences
import Foundation

let c = ReallyLazySequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }
    .consume { (value: Double?) -> Void in
        guard let value = value else { return }
        print(value)
    }

print(type(of:c))

try c.push(2)
try c.push(4)
try c.push(6)
try c.push(nil)
try c.push(7)


