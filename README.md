# ReallyLazySequences
Asynchronous Sequences for Swift.  

I wanted to call this LazySequence, but that was already taken, hence the name.

The idea is to create a new protocol which is a slightly larger superset of the Swift.Sequence protocol, but which allows values to be pushed into the sequence asynchronously rather than requiring them all to be present ab initio when calling things like map, flatMap, filter, et al. 

i.e. Instead of synchronously _returning_ the result of a map or reduce command to a caller, RLS's _deliver_ a stream of values to a downstream consumer _asynchronously_ as a result of values being pushed into the head of the sequence _asynchronously_.  This has important implications for implementation, but it should still allow an RLS to do ANY operation that can be performed on a Swift.Sequence plus many more.

This approach cannot be implemented using the regular Swift.Sequence because, for example, map in Swift.Sequence returns an array and in the asynchronous case we want it to return another asynchronous Sequence.  So we modify Swift.Sequence.map to return an object which implements ReallyLazySequenceProtocol instead.  Here are the declarations of SwiftSequence.map and flatMap for example:

_func map<T>(_ transform: (Self.Element) throws -> T) rethrows -> [T]_
_func flatMap<SegmentOfResult>(_ transform: (Self.Element) throws -> SegmentOfResult) rethrows -> [SegmentOfResult.Element] where SegmentOfResult : Sequence_

here's the equivalent RLS declaration:

_func map<T>(_ transform: @escaping (OutputType) -> T ) -> Map<Self, T>_
_func flatMap<T>(_ transform: @escaping (OutputType) -> Producer<T>) -> FlatMap<Self, T>_

Note how much simpler, flatMap in particular is, even though it accomplishes the same thing.  Also note that in both cases, the Swift.Sequence function acts on any object implementing the Sequence protocol, but returns an Array, i.e. a concrete implementation of the protocol

### Rules

1. Each Sequence when properly initialized accepts its values one at a time, asynchronously
1. Every swift.Sequence function is implemented _as is_, only with a possibly different return value and executed asynchronously on only one object at a time
1. All sequences are structs, not classes
1. All RLS structs have no methods other than init. Sequence functions _all_ occur in protocol extensions. Ideally, the sequence classes would not have _init_ either, but you can't place struct initializers in protocol extensions
1. Everything is asynchronous-capable and capable of thread-safety when specified rules are followed
1. You should never see a 100 level deep stack trace (implies use of Continuations), each step of the sequence chain is executed by the head independently not by having each step invoke its successor on its own.
1. The order of evaluation for each sequence can be read from the type name of the final sequence
1. Error handling is by throwing rather than passing the error up or down the sequence chain in-band
1. flatMap returns specific subtypes of our Sequence called Producers

### Notes

1. All Sequences have an InputType and a OutputType.  Values of type InputType are defined at the _head_ of the sequence and values of type OutputType are defined by the tail element of the sequence.
1. Putting a value in at the head does not necessarily cause a value to come out at the end (e.g. filter and reduce).  
1. Sending the nil value in at the head will cause all in-progress values to emerge at the end and mark the sequence as completed
1. You cannot put values into a Sequence object, you must first create a Consumer of the sequence by calling consume() on a Sequence and passing a closure which will consume the output values.  Values of InputType may be pushed into the resulting Consumer.  The rationale here is that pushing values in when there is no consumer will simply cause values emerging from the final step of the sequence to be discarded and hence would be pointless.
1. Once a Consumer is created all intermediate operations become opaque except that the type of the Consumer carries information about each of its predecessor elements in its name.  To see this do type(of:) on any Consumer or RLS.
1. The head of a sequence is always a Sequence, subsequent elements are always ChainedSequences.
1. To create a Producer (which is itself a Sequence) you must provide a closure which produces values of type Sequence.InputType.  
1. Producers must be consumed before they can be started.  Consuming a Producer returns a Task which must subsequently be started and which will call a completion handler when the TaskCompletes
1. Composition of a sequence consists of composing a new closure from the closures and values associated with the predecessor of the given sequence
1. Composition of a Consumer consists of composing the consumer's closure with that of its predecessor Sequence

### Questions

1. Is it worth preserving sequence at the expense of performance? - _No can be implemented by the user of the lib_
1. Is composability too hard a concept? Are Producer, Consumer, Task and Sequence the right abstractions?
1. Should error handling be in-line, at front or at end?
1. Are enormous stack frames really a problem if you can read where they come from?
1. Is it worth it to preserve the type names in long form? e.g. `Consumer<Reduce<Map<Sort<Map<Map<Filter<ReallyLazySequence<Int>, Int>, Double>, Double>, Double>, Int>, Int>>`
1. How can I get rid of boilerplate in the RLS extensions? _Probably requires HKTs_
1. Should sending nil into a consumer represent completion or just clear/reset?

### To Do

1. Implement several zip TLF's




