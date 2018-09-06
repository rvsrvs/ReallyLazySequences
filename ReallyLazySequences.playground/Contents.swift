import ReallyLazySequences

let consumed = [24, 4, 6]
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }

print (type(of: consumed))
print (consumed.description)

let consumer = SimpleSequence<Int>()
    .filter { $0 < 10 }
    .map { Double($0) * 2.0 }
    .consume { (value: Double?) -> ContinuationTermination in
        guard let value = value else { return .stop }
        print(type(of:value), value)
        return .canContinue
}

print(type(of:consumer))
print(consumer.description)

do {
    try [24, 4, 6, nil, 14].forEach {_ = try consumer.process($0) }
} catch {
    print(error)
}
