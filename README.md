# ReallyLazySequences
Asynchronous Sequences for Swift

1. everything’s a struct
1. everything is asynchronous 
1. every swift.Sequence function is implemented _as is_, only with a possibly different return value
1. the structs have no methods other than init, functions _all_ occur in protocol extensions.
1. no 100 level deep stack traces are allowed
1. single-thread and thread-safe versions supported (for performance)
1. error handling is in line rather than passed to end
1. sequence is preserved
1. the order of evaluation for each sequence can be read from the nested type information
