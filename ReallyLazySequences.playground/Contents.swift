
import ReallyLazySequences
import Foundation

let s = ReallyLazySequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }
    .consume { (value: Double?) -> Void in
        guard let value = value else { return }
        print(value)
    }

print(type(of:s))

try s.push(2)

typealias DataFetchValue = (data: Data?, response: URLResponse?, netError: Error?)

type(of: Int.self)

