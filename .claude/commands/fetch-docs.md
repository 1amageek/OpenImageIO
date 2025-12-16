# Recursive Documentation Fetcher

Fetch documentation from a URL and recursively gather related pages using the `remark` CLI tool.

## Instructions

You are a documentation fetcher that uses the `remark` CLI tool to retrieve web documentation and recursively follow relevant links.

### Input
The user will provide:
- A base URL (e.g., `https://developer.apple.com/documentation/imageio`)
- Optionally: maximum depth for recursion (default: 2)
- Optionally: URL patterns to include/exclude

### Process

1. **Initial Fetch**: Use `remark --include-front-matter "<URL>"` to fetch the base URL
2. **Parse Links**: Extract all relevant documentation links from the fetched content
3. **Filter Links**: Only follow links that:
   - Are on the same domain
   - Match the documentation path pattern
   - Haven't been fetched yet
   - Are not external resources (images, downloads, etc.)
4. **Recursive Fetch**: For each relevant link, recursively fetch up to the specified depth
5. **Compile Results**: Organize all fetched documentation into a structured summary

### Output Format

Provide the results in this format:

```
## Documentation Summary

### [Page Title 1](URL)
- Key types/classes discovered
- Key functions/methods
- Related links found

### [Page Title 2](URL)
...
```

### Important Rules

1. **One URL per remark call**: The `remark` command only accepts ONE URL at a time
2. **Rate limiting**: Add a small delay between requests to be respectful to the server
3. **Deduplication**: Track visited URLs to avoid fetching the same page twice
4. **Depth control**: Respect the maximum recursion depth
5. **Domain restriction**: Only follow links within the same documentation domain
6. **Error handling**: If a fetch fails, log the error and continue with other URLs

### Example Usage

For Apple Developer documentation:
```
Base URL: https://developer.apple.com/documentation/imageio
Depth: 2
Include pattern: /documentation/imageio/
```

This will:
1. Fetch the main ImageIO page
2. Extract links to CGImageSource, CGImageDestination, etc.
3. Fetch each of those pages
4. Extract and fetch sub-pages (up to depth 2)

### Bash Command Template

```bash
remark --include-front-matter "URL"
```

## Arguments
$ARGUMENTS
