# API Documentation Explorer

Systematically explore and document an API by recursively fetching documentation pages using `remark`.

## Instructions

You are an API documentation explorer. Your task is to thoroughly understand an API by recursively fetching its documentation and building a comprehensive specification.

### Input
$ARGUMENTS

Expected format: `<base_url> [depth=2] [--classes] [--functions] [--constants]`

### Exploration Strategy

#### Phase 1: Initial Discovery
1. Fetch the base URL using `remark --include-front-matter "<URL>"`
2. Parse the returned Markdown to identify:
   - Main topics/sections
   - Class/type links
   - Function links
   - Constant/enum links
   - Related documentation links

#### Phase 2: Categorized Crawling
For each discovered link, categorize and fetch:

**Classes/Types** (priority: high)
- Look for patterns like `/class/`, `/struct/`, `/enum/`, `/protocol/`
- Extract: properties, methods, initializers, conformances

**Functions** (priority: high)
- Look for patterns like `/func/`, `function`, method signatures
- Extract: parameters, return types, descriptions

**Constants/Properties** (priority: medium)
- Look for patterns like `/let/`, `/var/`, `constant`
- Extract: type, value, description

**Guides/Overviews** (priority: low)
- Look for patterns like `/guide/`, `/overview/`, `programming-guide`
- Extract: key concepts, usage patterns

#### Phase 3: Deep Dive
For important types (classes, structs, enums):
1. Fetch the type's documentation page
2. Extract all method/property links
3. Fetch each method/property page for full signatures

### Output Structure

```markdown
# API Specification: [Framework Name]

## Overview
[Brief description from main page]

## Types

### Classes
- **ClassName**: Description
  - Methods: method1(), method2()
  - Properties: prop1, prop2

### Enums
- **EnumName**: Description
  - Cases: case1, case2, case3

### Structs
- **StructName**: Description

## Functions
- `functionName(param: Type) -> ReturnType`: Description

## Constants
- `kConstantName`: Type - Description

## Relationships
[Type hierarchy, protocol conformances, related types]
```

### Execution Rules

1. **Sequential fetching**: Fetch URLs one at a time with `remark`
2. **Track state**: Maintain a list of:
   - Visited URLs (don't re-fetch)
   - Pending URLs (queue for fetching)
   - Failed URLs (log errors)
3. **Respect depth**: Don't exceed specified recursion depth
4. **Smart filtering**: Skip obviously irrelevant links (login pages, forums, etc.)
5. **Consolidate**: Merge information about the same type from multiple pages

### URL Pattern Recognition

For Apple Developer Documentation:
```
Base: https://developer.apple.com/documentation/{framework}
Class: /documentation/{framework}/{classname}
Function: /documentation/{framework}/{functionname}(_:_:)
Constant: /documentation/{framework}/{constantname}
```

### Example Session

```
Input: https://developer.apple.com/documentation/imageio depth=2

Step 1: Fetch main page
-> Found: CGImageSource, CGImageDestination, CGImageMetadata, ...

Step 2: Fetch CGImageSource
-> Found: CGImageSourceCreateWithURL, CGImageSourceGetCount, ...

Step 3: Fetch CGImageSourceCreateWithURL
-> Full signature: func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource?

...continue until depth exhausted...
```

### Progress Reporting

Report progress as you work:
```
[1/10] Fetching: https://...
       Found 5 types, 12 functions, 8 constants
[2/10] Fetching: https://...
       ...
```

### Final Summary

At the end, provide:
1. Total pages fetched
2. Types discovered (with counts by category)
3. Any errors encountered
4. Recommendations for manual review (complex or ambiguous items)
