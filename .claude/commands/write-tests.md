# Structured Test Writing

Write comprehensive, well-structured tests that verify the essential functionality of implementations.

## Instructions

You are a test engineering assistant that writes meaningful, structural tests based on deep understanding of the implementation.

### Input
$ARGUMENTS

Expected format: `<target_path_or_module> [--coverage] [--unit-only] [--integration-only]`

### Workflow

Execute this workflow systematically:

#### Phase 1: Implementation Review
```
Step 1.1: Discover all source files
Step 1.2: Read and catalog each implementation
Step 1.3: Create implementation inventory
```

Output format:
```
═══════════════════════════════════════════════════════
Phase 1: Implementation Review
═══════════════════════════════════════════════════════

Files Discovered:
  1. CGImageSource.swift (634 lines)
  2. CGImageDestination.swift (665 lines)
  ...

Implementation Inventory:
┌─────────────────────────┬──────────┬─────────────────┐
│ Type                    │ Category │ Public APIs     │
├─────────────────────────┼──────────┼─────────────────┤
│ CGImageSource           │ class    │ 15 functions    │
│ CGImageDestination      │ class    │ 10 functions    │
└─────────────────────────┴──────────┴─────────────────┘
═══════════════════════════════════════════════════════
```

#### Phase 2: Understand Structure & Functionality

For each implementation:
1. Identify the **purpose** (what problem does it solve?)
2. Map **dependencies** (what does it depend on?)
3. Identify **public API surface** (what can users call?)
4. Understand **internal state** (what data does it manage?)
5. Identify **edge cases** (what could go wrong?)
6. Identify **invariants** (what must always be true?)

Output format:
```
═══════════════════════════════════════════════════════
Phase 2: Structure & Functionality Analysis
═══════════════════════════════════════════════════════

CGImageSource Analysis:
────────────────────────────────────────────────────────
Purpose: Read and decode image data from various sources

Dependencies:
  - CFData, CFURL, CGDataProvider (input types)
  - CGImage (output type)
  - CGImageSourceStatus (status tracking)

Public API Surface:
  Creation:
    - CGImageSourceCreateWithURL(_:_:)
    - CGImageSourceCreateWithData(_:_:)
    - CGImageSourceCreateWithDataProvider(_:_:)
    - CGImageSourceCreateIncremental(_:)

  Information:
    - CGImageSourceGetCount(_:)
    - CGImageSourceGetType(_:)
    - CGImageSourceGetStatus(_:)
    ...

Internal State:
  - imageData: [UInt8] - raw image bytes
  - imageCount: Int - number of images
  - status: CGImageSourceStatus - current parsing state

Edge Cases:
  - Empty data
  - Corrupted/invalid image data
  - Unsupported format
  - Index out of bounds
  - Partial/incremental data

Invariants:
  - imageCount >= 0
  - status reflects actual data state
  - properties dictionary contains valid keys
═══════════════════════════════════════════════════════
```

#### Phase 3: Overall Test Design

Design the test architecture:

```
═══════════════════════════════════════════════════════
Phase 3: Overall Test Design
═══════════════════════════════════════════════════════

Test Categories:
  1. Unit Tests - Test individual functions in isolation
  2. Integration Tests - Test component interactions
  3. Edge Case Tests - Test boundary conditions
  4. Performance Tests - Test efficiency (optional)

Test File Structure:
  Tests/
  └── OpenImageIOTests/
      ├── CGImageSourceTests.swift
      ├── CGImageDestinationTests.swift
      ├── CGImageMetadataTests.swift
      ├── ImageFormatTests.swift
      └── TestHelpers/
          └── TestDataGenerator.swift

Coverage Goals:
  - All public APIs tested
  - All error paths exercised
  - All supported formats verified
  - Edge cases covered
═══════════════════════════════════════════════════════
```

#### Phase 4: Feature-by-Feature Test Design

For each feature/module, design specific tests:

```
═══════════════════════════════════════════════════════
Phase 4: Feature Test Design - CGImageSource
═══════════════════════════════════════════════════════

Test Suite: CGImageSourceCreationTests
────────────────────────────────────────────────────────
  @Test testCreateWithValidPNGData()
    Purpose: Verify source creation from valid PNG
    Input: Valid PNG byte array
    Expected: Non-nil source, status = complete

  @Test testCreateWithInvalidData()
    Purpose: Verify graceful handling of invalid data
    Input: Random bytes
    Expected: Source with status = unknownType or invalidData

  @Test testCreateWithEmptyData()
    Purpose: Verify handling of empty input
    Input: Empty byte array
    Expected: Nil or status = invalidData

Test Suite: CGImageSourceImageExtractionTests
────────────────────────────────────────────────────────
  @Test testCreateImageAtValidIndex()
    Purpose: Verify image extraction works
    Input: Valid source, index 0
    Expected: Non-nil CGImage with correct dimensions

  @Test testCreateImageAtInvalidIndex()
    Purpose: Verify bounds checking
    Input: Valid source, index = count
    Expected: Nil result
═══════════════════════════════════════════════════════
```

#### Phase 5: Test Implementation

Write the actual test code following Swift Testing framework conventions:

```swift
import Testing
@testable import OpenImageIO

// MARK: - Test Helpers

struct TestData {
    /// Minimal valid PNG (1x1 transparent pixel)
    static let minimalPNG: [UInt8] = [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        // ... IHDR, IDAT, IEND chunks
    ]
}

// MARK: - CGImageSource Creation Tests

@Suite("CGImageSource Creation")
struct CGImageSourceCreationTests {

    @Test("Create source from valid PNG data")
    func createWithValidPNGData() {
        let data = CFData(bytes: TestData.minimalPNG)
        let source = CGImageSourceCreateWithData(data, nil)

        #expect(source != nil)
        #expect(CGImageSourceGetStatus(source!) == .statusComplete)
        #expect(CGImageSourceGetCount(source!) == 1)
    }

    @Test("Create source from empty data returns nil or invalid status")
    func createWithEmptyData() {
        let data = CFData(bytes: [])
        let source = CGImageSourceCreateWithData(data, nil)

        if let source = source {
            #expect(CGImageSourceGetStatus(source) != .statusComplete)
        }
    }
}
```

#### Phase 6: Iterate - Repeat Steps 4 & 5

Continue designing and implementing tests for each feature:

```
Iteration Progress:
────────────────────────────────────────────────────────
[x] CGImageSource Creation Tests (8 tests)
[x] CGImageSource Information Tests (6 tests)
[x] CGImageSource Image Extraction Tests (5 tests)
[ ] CGImageSource Incremental Tests (4 tests) <- Current
[ ] CGImageDestination Tests (12 tests)
[ ] CGImageMetadata Tests (10 tests)
────────────────────────────────────────────────────────
```

#### Phase 7: Final Verification

After all tests are written:

1. **Run all tests**: `swift test`
2. **Verify coverage**: Check all public APIs are tested
3. **Review test quality**:
   - Are tests meaningful (not just checking non-nil)?
   - Are edge cases covered?
   - Are error paths tested?
   - Are tests independent?
4. **Fix any failing tests or gaps**

Output format:
```
═══════════════════════════════════════════════════════
Phase 7: Final Verification
═══════════════════════════════════════════════════════

Test Execution Results:
  Total: 45 tests
  Passed: 43
  Failed: 2
  Skipped: 0

Coverage Analysis:
┌─────────────────────────┬──────────┬─────────────────┐
│ Module                  │ APIs     │ Coverage        │
├─────────────────────────┼──────────┼─────────────────┤
│ CGImageSource           │ 15       │ 100% (15/15)    │
│ CGImageDestination      │ 10       │ 100% (10/10)    │
│ CGImageMetadata         │ 12       │ 92% (11/12)     │
└─────────────────────────┴──────────┴─────────────────┘

Missing Coverage:
  - CGImageMetadataEnumerateTagsUsingBlock (complex callback)

Failed Tests:
  1. testCreateThumbnailWithMaxSize - Dimension mismatch
  2. testEncodeJPEGWithQuality - Output validation failed

Action Items:
  [ ] Fix thumbnail dimension calculation
  [ ] Fix JPEG quality encoding
  [ ] Add test for enumeration function
═══════════════════════════════════════════════════════
```

#### Phase 8: Completion

Present final summary:

```
═══════════════════════════════════════════════════════
Phase 8: Test Implementation Complete
═══════════════════════════════════════════════════════

Summary:
  Test Files Created: 5
  Total Test Cases: 47
  All Tests Passing: Yes

Files Modified/Created:
  + Tests/OpenImageIOTests/CGImageSourceTests.swift
  + Tests/OpenImageIOTests/CGImageDestinationTests.swift
  + Tests/OpenImageIOTests/CGImageMetadataTests.swift
  + Tests/OpenImageIOTests/CGImageMetadataTagTests.swift
  + Tests/OpenImageIOTests/TestHelpers.swift

Test Categories:
  - Unit Tests: 35
  - Integration Tests: 8
  - Edge Case Tests: 4

Run tests with: swift test
═══════════════════════════════════════════════════════
```

### Test Writing Principles

1. **Test Behavior, Not Implementation**
   - Test what the function does, not how it does it
   - Tests should survive refactoring

2. **One Assertion Per Concept**
   - Each test should verify one specific behavior
   - Multiple related assertions are OK if testing one concept

3. **Arrange-Act-Assert Pattern**
   ```swift
   @Test func example() {
       // Arrange
       let input = createTestData()

       // Act
       let result = functionUnderTest(input)

       // Assert
       #expect(result == expectedValue)
   }
   ```

4. **Meaningful Test Names**
   - Describe what is being tested and expected outcome
   - `testCreateImageFromValidPNGReturnsNonNil`
   - `testGetCountReturnsZeroForEmptySource`

5. **Independent Tests**
   - Tests should not depend on each other
   - Each test sets up its own state

6. **Test Edge Cases**
   - Empty inputs
   - Nil inputs (where applicable)
   - Boundary values (0, max, negative)
   - Invalid/corrupted data

### Important Rules

1. **Use Swift Testing Framework** (not XCTest)
   ```swift
   import Testing
   @Test func myTest() { }
   @Suite struct MyTests { }
   #expect(condition)
   #require(condition) // throws if false
   ```

2. **Create Reusable Test Helpers**
   - Test data generators
   - Common assertions
   - Mock/stub creators

3. **Document Test Purpose**
   - Why does this test exist?
   - What specification does it verify?

4. **Keep Tests Fast**
   - Avoid I/O where possible
   - Use in-memory test data

5. **Verify Before Committing**
   - All tests must pass before completion
   - Run `swift test` and confirm success

### Example Session

```
$ /write-tests Sources/OpenImageIO

Phase 1: Reviewing implementations...
Found 16 source files with 45 public APIs.

Phase 2: Analyzing structure...
Identified 6 main components with 23 edge cases.

Phase 3: Designing test architecture...
Planning 5 test files with ~50 test cases.

Phase 4: Designing CGImageSource tests...
Designed 15 test cases across 4 categories.

Phase 5: Implementing CGImageSource tests...
Created Tests/OpenImageIOTests/CGImageSourceTests.swift

[Continuing iteration...]

Phase 7: Running verification...
swift test
47 tests passed.

Phase 8: Complete!
All tests implemented and passing.
```
