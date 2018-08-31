import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RLS_KernelTests.allTests),
    ]
}
#endif