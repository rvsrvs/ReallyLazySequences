/*
 Copyright 2019, Ronald V. Simmons
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import ReallyLazySequences

let consumedArray = [24, 4, 6]
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }

print (type(of: consumedArray))
print (consumedArray.description)

let unconsumedSequence = SimpleSequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }

print(type(of:unconsumedSequence))
print(unconsumedSequence.description)

let consumer = unconsumedSequence
    .consume { (value: Double?) -> ContinuationTermination in
        guard let value = value else { return .terminate }
        print(type(of:value), value)
        return .canContinue
}

print(type(of:consumer))
print(consumer.description)

do {
    try [24, 4, 6, nil, 14].forEach {_ = try consumer.process($0) }
} catch {
    print("Error in processing: \(error)")
}
