# ReallyLazySequences
Asynchronous Sequences for Swift

### Rules

1. Each Sequence when properly initialized accepts is values one at a time, asynchronously
1. Every swift.Sequence function is implemented _as is_, only with a possibly different return value and executed asynchronously on only one object at a time
1. All sequences are structs, not classes
1. All RLS structs have no methods other than init. Sequence functions _all_ occur in protocol extensions. ideally, they would not have _init_ either, but you can't place struct initializers in protocol extensions
1. Everything is asynchronous-capable and capable of thread-safety when specified rules are followed
1. You should never see a 100 level deep stack trace (implies use of Continuations), each step of the sequence chain is executed by the head independently
1. The order of evaluation for each sequence can be read from the type name of the final sequence
1. Error handling is by throwing rather than passing the error up or down the sequence chain in-band
1. flatMap returns specific subtypes of our Sequence called Producers

### Notes

1. All Sequences have an InputType and a OutputType.  Values of type InputType are defined at the _head_ of the sequence and values of type OutputType are defined by the tail element of the sequence.
1. Putting a value in at the head does not necessarily cause a value to come out at the end (e.g. filter and reduce).  
1. Sending the nil value in at the head will cause all in-progress values to emerge at the end and mark the sequence as completed
1. You cannot put values into a Sequence object, you must first create a Consumer of the sequence by calling consume() on a Sequence and passing a closure which will consume the output values.  Values of InputType may be pushed into the resulting Consumer.
1. Once a Consumer is created all intermediate operations become opaque except that the type of the Consumer carries information of each of its predecessor elements in its name.
1. The head of a sequence is always a Sequence, subsequent elements are always ChainedSequences.
1. You may create a Producer from a Sequence by specifying a closure which produces values of type Sequence.InputType.  
1. Producers must be consumed before they can be started.  Consuming a Producer returns a Task which may be started and which will call a completion handler when the TaskCompletes
1. Composition of a sequence consists of creating a single closure from the closures and values associated with the predecessor of the given sequence. 
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




