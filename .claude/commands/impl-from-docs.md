# Implementation from Documentation

Fetch API documentation and implement/update code to match the official specification.

## Instructions

You are an implementation assistant that ensures code matches official API documentation exactly.

### Input
$ARGUMENTS

Expected format: `<documentation_url> [--dry-run] [--skip-build]`

### Workflow

Execute this workflow for each documentation page:

#### Step 1: Fetch Documentation
```bash
remark "<URL>"
```

Parse the returned content to extract:
- **Type name** (class, struct, enum, protocol)
- **Properties** with types and descriptions
- **Methods** with full signatures
- **Constants** with values
- **Inheritance/Conformances**

#### Step 2: Compare with Codebase

Search the codebase for the corresponding implementation:
1. Use Glob to find files that might contain the type
2. Read the relevant source files
3. Compare extracted specification against actual implementation

Generate a **Diff Report**:
```
═══════════════════════════════════════════════════════
Type: CGImageSource
Status: PARTIAL MATCH
═══════════════════════════════════════════════════════

✅ Matching:
   - CGImageSourceGetCount(_:) -> Int
   - CGImageSourceGetType(_:) -> CFString?

❌ Missing:
   - CGImageSourceGetPrimaryImageIndex(_:) -> Int
   - CGImageSourceCopyAuxiliaryDataInfoAtIndex(_:_:_:) -> CFDictionary?

⚠️ Signature Mismatch:
   - CGImageSourceCreateWithData
     Expected: (CFData, CFDictionary?) -> CGImageSource?
     Actual:   (CFData, CFDictionary) -> CGImageSource?
              ^ Missing optional

═══════════════════════════════════════════════════════
```

#### Step 3: User Confirmation

Present the diff report and ask:
```
Differences found. How would you like to proceed?

[1] Apply all changes (Recommended)
[2] Review each change individually
[3] Skip this type
[4] Exit implementation session
```

#### Step 4: Implement Changes

For each approved change:
1. Edit or create the necessary source files
2. Ensure proper imports and dependencies
3. Add placeholder implementations for method bodies if needed

#### Step 5: Validate

Run build verification:
```bash
swift build
```

If build fails:
- Show the error
- Attempt automatic fix if obvious
- Ask user for guidance if complex

#### Step 6: Progress Update & Next Page

Update progress display and ask:
```
═══════════════════════════════════════
Framework: ImageIO
Progress: 5/23 pages (21%)
═══════════════════════════════════════
✅ CGImageSourceStatus (enum)
✅ CGImageMetadataType (enum)
✅ CGImageSource (class) - just completed
🔄 CGImageDestination - up next
⏳ CGImageMetadata - queued
═══════════════════════════════════════

Continue to next page (CGImageDestination)?
[Y] Yes  [n] No  [s] Skip to specific type
```

### Processing Order

Process types in this order for proper dependency resolution:
1. **Enums** - No dependencies
2. **Structs** - May depend on enums
3. **Classes** - May depend on enums and structs
4. **Protocols** - May depend on any type
5. **Functions** - May depend on all types
6. **Constants** - Usually depend on types

### Implementation Templates

#### For Missing Enum:
```swift
public enum TypeName: RawType {
    case case1
    case case2
    // ... cases from documentation
}
```

#### For Missing Function:
```swift
public func FunctionName(
    _ param1: Type1,
    _ param2: Type2
) -> ReturnType? {
    // TODO: Implement - matches ImageIO API
    fatalError("Not implemented")
}
```

#### For Missing Property:
```swift
public var propertyName: Type {
    // TODO: Implement - matches ImageIO API
    fatalError("Not implemented")
}
```

### Session State Tracking

Maintain session state:
- `visited`: URLs already processed
- `pending`: URLs queued for processing
- `skipped`: URLs user chose to skip
- `failed`: URLs that encountered errors
- `implemented`: Types successfully implemented

### Important Rules

1. **Exact API Match**: Signatures must match ImageIO exactly
2. **No Deprecated APIs**: Skip anything marked as deprecated
3. **User Control**: Never make changes without user approval
4. **Build Validation**: Always verify changes compile
5. **Incremental Progress**: One type at a time, don't overwhelm
6. **Clear Reporting**: Show exactly what will change before changing

### Link Discovery

When fetching a documentation page, also extract links to related types:
- Child types referenced on the page
- Parameter types in method signatures
- Return types
- Protocol conformances

Add discovered links to the pending queue (unless already visited).

### Error Handling

- **Network Error**: Retry once, then ask user
- **Parse Error**: Show raw content, ask user to identify structure
- **Build Error**: Show error, offer to rollback changes
- **Type Conflict**: Show both versions, let user decide

### Example Session

```
$ /impl-from-docs https://developer.apple.com/documentation/imageio

Fetching: https://developer.apple.com/documentation/imageio
Found framework overview page with 15 type links.

Discovered types (sorted by dependency order):
  1. CGImageSourceStatus (enum)
  2. CGImagePropertyOrientation (enum)
  3. CGImageSource (class)
  4. CGImageDestination (class)
  5. CGImageMetadata (class)
  ...

Starting with: CGImageSourceStatus

Fetching: .../cgimagesourcestatus
Extracted enum with 6 cases.

Comparing with codebase...
File: Sources/OpenImageIO/CGImageSourceStatus.swift

Status: MISSING
This enum does not exist in the codebase.

Implement CGImageSourceStatus enum?
[Y] Yes  [n] No  [s] Skip

> Y

Creating CGImageSourceStatus.swift...
Running swift build...
Build succeeded!

✅ CGImageSourceStatus implemented

Continue to next type (CGImagePropertyOrientation)?
[Y] Yes  [n] No  [s] Skip to specific
```
