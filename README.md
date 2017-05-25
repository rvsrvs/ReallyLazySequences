# ReallyLazySequences
Asynchronous Sequences for Swift

### Rules

1. Everything is a struct
1. Everything is asynchronous
1. Every swift.Sequence function is implemented _as is_, only with a possibly different return value
1. the structs have no methods other than init. Sequence functions _all_ occur in protocol extensions.
1. We should never see a 100 level deep stack trace (implies use of Continuations)
1. Single-thread and thread-safe versions are supported. Single-thread is for performance reasons. (Also implies use of Continuations)
1. Sequence is preserved, i.e. in a multi-threaded environment, the consumer of a ReallyLazySequence should see things in the same order they would appear in the single-threaded environment
1. The order of evaluation for each sequence can be read from the nested type information
1. Error handling is in line rather than passed up or down the chain

### Notes

1. Sequences have a HeadType and a ConsumableType.  Values of type HeadType enter at the head of the sequence and values of type ConsumableType come out at the end.
1. Putting a value in does not necessarily cause a value to come out.  Sending the nil value in will cause all values to emerge at the end.
1. You cannot put values into a sequence, you must create a Consumer of the sequence by calling consume() on a sequence and passing a closure which will consume the values.  Values of HeadType may be pushed into the resulting Consumer.
1. You may create a Producer from a sequence by specifying a closure which produces values of type HeadType.  
1. Producers must be consumed before they can be started.  Consuming a Producer returns a Task which may be started and which will call a ccompletion handler when the TaskCompletes
1. Composition of a sequence consists of creating a single closure from the closures and values associated with each predecessor of the given sequence


### Questions
1. Is it worth it to preserve the type names in long form? e.g.
```
Consumer<Reduce<Map<Sort<Map<Map<Filter<ReallyLazySequence<Int>, Int>, Double>, Double>, Double>, Int>, Int>>
```

2. How to get rid of boilerplate in the RLS extensions?
1. Should sending nil in be complete or clear/reset?




