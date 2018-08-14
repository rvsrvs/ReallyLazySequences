
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

do {
    try c.process(24)
    try c.process(4)
    try c.process(6)
    try c.process(nil)
    try c.process(14)
} catch {
    print(error)
}
