import Types "../types/capabilities";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Array "mo:core/Array";
import List "mo:core/List";
import Iter "mo:core/Iter";
import Nat "mo:core/Nat";
import Nat64 "mo:core/Nat64";
import Int "mo:core/Int";
import Float "mo:core/Float";
import Set "mo:core/Set";
import Char "mo:core/Char";
import Blob "mo:core/Blob";
import Time "mo:core/Time";

module {

  // ── exported HTTP types (used in main.mo for transform function) ───────────

  public type HttpHeader = { name : Text; value : Text };

  public type HttpRequestResult = {
    status : Nat;
    headers : [HttpHeader];
    body : Blob;
  };

  public type TransformArgs = {
    response : HttpRequestResult;
    context : Blob;
  };

  // ── cache types ────────────────────────────────────────────────────────────

  public type CacheEntry = {
    response : Text;        // full JSON response string
    fetchedAt : Int;        // nanoseconds timestamp when fetched
    lastAccessedAt : Int;   // nanoseconds timestamp of last access
  };

  // ── helpers for registry ──────────────────────────────────────────────────

  func inp(key : Text, t : Text, req : Bool, desc : Text) : Types.CapabilityInput =
    { key; inputType = t; required = req; description = desc };

  func out(key : Text, t : Text, desc : Text) : Types.CapabilityOutput =
    { key; outputType = t; description = desc };

  // ── static capability list ─────────────────────────────────────────────────

  func allCapabilities() : [Types.CapabilityInfo] = [
    // ── Web ──────────────────────────────────────────────────────────────────
    {
      name = "fetch_url"; description = "Fetch the content of a URL via HTTP outcalls with caching and optimization.";
      category = "Web";
      inputs = [
        inp("url", "string", true, "URL to fetch"),
        inp("method", "string", false, "HTTP method: get|post|head (default get)"),
        inp("headers", "object", false, "Request headers as JSON object"),
        inp("body", "string", false, "Request body (for POST)"),
        inp("ttl_seconds", "number", false, "Cache TTL in seconds (default 60)"),
        inp("eviction_window_seconds", "number", false, "Last-accessed eviction window in seconds (default 600)"),
        inp("max_response_bytes", "number", false, "Max response size in bytes (default 50000, max 200000)"),
        inp("bypass_cache", "boolean", false, "Skip cache and always make a fresh call (default false)"),
      ];
      outputs = [
        out("status", "number", "HTTP status code"),
        out("body", "string", "Response body"),
        out("headers", "object", "Response headers"),
        out("cache_hit", "boolean", "True if response came from cache"),
        out("cache_key", "string", "Cache key used for this request"),
        out("cache_ttl_remaining_seconds", "number", "Seconds until cached entry expires (0 on cache miss)"),
      ];
      constraints = ["Supported methods: get, post, head", "Max response: 200KB (configurable, default 50KB)", "Cache TTL and eviction window are per-request configurable"];
      exampleInput = "{\"url\": \"https://example.com\"}";
      exampleOutput = "{\"status\": 200, \"body\": \"<!DOCTYPE html>...\", \"headers\": {}, \"cache_hit\": false, \"cache_key\": \"https://example.com:get\"}";
    },
    // ── Documents / Text ────────────────────────────────────────────────────
    {
      name = "read_document";
      description = "Read and normalize a raw text document, returning its content with character, word, and line counts. Supports BOM stripping, line-ending normalization, whitespace trimming, and length-based truncation. Ideal as the entry point for any document processing pipeline.";
      category = "Documents";
      inputs = [
        inp("content", "string", true, "Raw document text to read and process. Pass the full content of the document as a string."),
        inp("encoding_hint", "string", false, "Encoding label for the content. Accepted values: utf-8, latin-1, ascii. Used for output annotation only. Default: utf-8."),
        inp("strip_bom", "boolean", false, "When true, removes the UTF-8 byte-order mark (\\uFEFF) from the start of the content. Useful for files exported from Windows tools. Default: true."),
        inp("detect_line_endings", "boolean", false, "When true, normalizes all line endings (CRLF and bare CR) to LF for consistent line counting. Default: false."),
        inp("trim_whitespace", "boolean", false, "When true, removes leading and trailing whitespace from the full document content before returning. Default: false."),
        inp("max_length", "number", false, "Maximum number of characters to return. Content exceeding this is truncated and was_truncated is true. 0 means no limit. Default: 0."),
      ];
      outputs = [
        out("content", "string", "The processed document content after all enabled transformations."),
        out("char_count", "number", "Total characters in the returned content."),
        out("line_count", "number", "Number of lines (split by \\n) in the returned content."),
        out("word_count", "number", "Approximate word count based on whitespace-delimited tokens."),
        out("encoding_hint", "string", "The encoding_hint value passed in, or the default utf-8."),
        out("was_truncated", "boolean", "True if content was truncated due to max_length; false otherwise."),
      ];
      constraints = [
        "content must be non-empty",
        "max_length must be 0 or a positive integer; 0 means no limit",
        "encoding_hint accepted values: utf-8, latin-1, ascii",
        "strip_bom only removes the leading \\uFEFF character",
      ];
      exampleInput = "{\"content\": \"Hello World!\\r\\nSecond line.\", \"encoding_hint\": \"utf-8\", \"strip_bom\": true, \"detect_line_endings\": true, \"trim_whitespace\": false, \"max_length\": 0}";
      exampleOutput = "{\"content\": \"Hello World!\\nSecond line.\", \"char_count\": 25, \"line_count\": 2, \"word_count\": 4, \"encoding_hint\": \"utf-8\", \"was_truncated\": false}";
    },
    {
      name = "extract_text";
      description = "Extract clean, readable plain text from raw content by stripping non-printable control characters, decoding HTML entities, collapsing whitespace, and removing custom unwanted characters. Use this before parsing, searching, or feeding content into downstream capabilities.";
      category = "Documents";
      inputs = [
        inp("content", "string", true, "The raw input content from which to extract clean text. May include control characters, HTML entities, extra whitespace, or noise characters."),
        inp("preserve_formatting", "boolean", false, "When true, preserves paragraph breaks (double newlines) and indentation. When false, whitespace is treated uniformly. Default: false."),
        inp("decode_html_entities", "boolean", false, "When true, converts common HTML entities to plain text: &amp; to &, &lt; to <, &gt; to >, &quot; to \", &#39; to '. Default: true."),
        inp("custom_strip_chars", "string", false, "A string of individual characters to remove from the output. Each character is stripped independently. Example: \"|#@\" removes pipe, hash, and at-sign. Default: null."),
        inp("collapse_whitespace", "boolean", false, "When true, collapses consecutive spaces and tabs into a single space. Default: true."),
        inp("min_length", "number", false, "Minimum character count for the extracted text. If the result is shorter, an empty string is returned. Set to 0 to disable. Default: 0."),
      ];
      outputs = [
        out("text", "string", "The extracted and cleaned plain text."),
        out("char_count", "number", "Character count of the extracted text."),
        out("stripped_char_count", "number", "Characters removed during extraction (original length minus output length)."),
      ];
      constraints = [
        "Strips all control characters except \\n and \\t",
        "min_length must be 0 or a positive integer",
        "custom_strip_chars is treated as a set of individual characters, not a substring pattern",
        "HTML entity decoding covers: &amp; &lt; &gt; &quot; &#39;",
      ];
      exampleInput = "{\"content\": \"  Hello &amp; World!\\n\\nParagraph two.  \", \"preserve_formatting\": false, \"decode_html_entities\": true, \"custom_strip_chars\": \"!\", \"collapse_whitespace\": true, \"min_length\": 1}";
      exampleOutput = "{\"text\": \"Hello & World Paragraph two.\", \"char_count\": 28, \"stripped_char_count\": 12}";
    },
    {
      name = "clean_text";
      description = "Clean and normalize text through a configurable pipeline: zero-width character removal, Unicode normalization, whitespace collapsing, tab replacement, newline stripping, and boundary trimming. Each transformation is independently controlled and applied in a fixed, deterministic order.";
      category = "Documents";
      inputs = [
        inp("content", "string", true, "The text content to clean. All enabled transformations are applied in a fixed order."),
        inp("collapse_whitespace", "boolean", false, "When true, collapses consecutive space and tab characters into a single space. Default: true."),
        inp("trim_mode", "string", false, "Where to trim leading/trailing whitespace. Accepted values: both, start, end, none. Default: both."),
        inp("strip_tabs", "boolean", false, "When true, replaces tab characters with the string in replace_tabs_with. Default: false."),
        inp("strip_newlines", "boolean", false, "When true, removes all newline characters (\\n and \\r) to produce single-line output. Default: false."),
        inp("normalize_unicode", "boolean", false, "When true, replaces common accented Latin characters with ASCII equivalents. Default: false."),
        inp("remove_zero_width", "boolean", false, "When true, removes zero-width space, zero-width non-joiner, zero-width joiner, and BOM characters. Default: true."),
        inp("replace_tabs_with", "string", false, "The replacement string for each tab when strip_tabs is true. Default: \" \" (single space)."),
      ];
      outputs = [
        out("text", "string", "The cleaned text after all enabled transformations."),
        out("original_length", "number", "Character count of the input content before cleaning."),
        out("cleaned_length", "number", "Character count of the output text after cleaning."),
        out("chars_removed", "number", "Characters removed (original_length minus cleaned_length)."),
      ];
      constraints = [
        "Transformations are applied in this fixed order: remove_zero_width, normalize_unicode, collapse_whitespace, strip_tabs, strip_newlines, trim_mode",
        "trim_mode must be one of: both, start, end, none",
        "replace_tabs_with is only used when strip_tabs is true",
        "strip_newlines removes both \\n and \\r characters",
        "content field is used (not text) for consistency with other document capabilities",
      ];
      exampleInput = "{\"content\": \"  Hello\\t\\t World!\\n\", \"collapse_whitespace\": true, \"trim_mode\": \"both\", \"strip_tabs\": true, \"strip_newlines\": false, \"normalize_unicode\": false, \"remove_zero_width\": true, \"replace_tabs_with\": \" \"}";
      exampleOutput = "{\"text\": \"Hello World!\", \"original_length\": 17, \"cleaned_length\": 12, \"chars_removed\": 5}";
    },
    {
      name = "chunk_text";
      description = "Split text into smaller chunks using fixed character, word-boundary, or sentence-boundary strategies. Supports overlap for context continuity, minimum size filtering, per-chunk whitespace stripping, and optional index prefixes. Essential for preparing documents for LLM context windows, embedding pipelines, and search indexes.";
      category = "Documents";
      inputs = [
        inp("content", "string", true, "The text to split into chunks."),
        inp("chunk_size", "number", true, "Target size per chunk in characters. For fixed: exact count. For word_boundary and sentence: max characters before splitting at the nearest boundary."),
        inp("strategy", "string", false, "Chunking strategy. fixed: splits at exactly chunk_size characters. word_boundary: splits at the last space before chunk_size. sentence: splits at the last sentence-ending punctuation (. ! ?) before chunk_size. Default: fixed."),
        inp("overlap", "number", false, "Characters from the end of each chunk to repeat at the start of the next for context continuity. Must be less than chunk_size. Default: 0."),
        inp("min_chunk_size", "number", false, "Minimum characters a chunk must contain to be included. Smaller trailing chunks are discarded. 0 keeps all chunks. Default: 0."),
        inp("preserve_sentences", "boolean", false, "When true with fixed strategy, looks back from the chunk boundary for sentence-ending punctuation to avoid mid-sentence splits. Default: false."),
        inp("strip_chunk_whitespace", "boolean", false, "When true, trims leading and trailing whitespace from each individual chunk. Default: true."),
        inp("include_chunk_index", "boolean", false, "When true, prefixes each chunk with [chunk N] where N is the 1-based chunk number. Default: false."),
      ];
      outputs = [
        out("chunks", "array<string>", "Array of text chunks produced by the selected strategy."),
        out("chunk_count", "number", "Total number of chunks in the output."),
        out("avg_chunk_size", "number", "Average character count across all returned chunks."),
        out("total_chars", "number", "Total characters summed across all output chunks."),
      ];
      constraints = [
        "chunk_size must be >= 1",
        "overlap must be >= 0 and < chunk_size",
        "min_chunk_size must be >= 0",
        "strategy must be one of: fixed, word_boundary, sentence",
        "content field is used (not text) for consistency with other document capabilities",
      ];
      exampleInput = "{\"content\": \"The quick brown fox jumps over the lazy dog. A second sentence follows.\", \"chunk_size\": 30, \"strategy\": \"word_boundary\", \"overlap\": 5, \"min_chunk_size\": 5, \"preserve_sentences\": false, \"strip_chunk_whitespace\": true, \"include_chunk_index\": true}";
      exampleOutput = "{\"chunks\": [\"[chunk 1] The quick brown fox jumps\", \"[chunk 2] umps over the lazy dog. A\", \"[chunk 3] g. A second sentence follows.\"], \"chunk_count\": 3, \"avg_chunk_size\": 26, \"total_chars\": 79}";
    },
    {
      name = "remove_html";
      description = "Strip HTML tags from content to produce clean plain text. Optionally removes entire script/style blocks, decodes HTML entities, inserts newlines at block elements, and preserves an allowlist of specific tags. Returns the plain text with tag removal and character length statistics.";
      category = "Documents";
      inputs = [
        inp("content", "string", true, "The HTML content to process. Can be a full HTML document, a fragment, or any string containing HTML markup."),
        inp("decode_entities", "boolean", false, "When true, converts HTML entities after tag removal: &amp; to &, &lt; to <, &gt; to >, &quot; to \", &#39; to '. Default: true."),
        inp("preserve_line_breaks", "boolean", false, "When true, inserts newline characters at block-level elements (p, div, br, h1-h6, li, tr) to preserve structural layout. Default: true."),
        inp("skip_script_style", "boolean", false, "When true, removes the entire content of script and style blocks including inner text, preventing JavaScript/CSS from appearing in output. Default: true."),
        inp("allowed_tags", "string", false, "Comma-separated list of tag names to preserve — all others are stripped. Example: b,i,em,strong,code. Empty or null strips all tags. Default: null."),
        inp("collapse_whitespace", "boolean", false, "When true, collapses consecutive whitespace characters in the output into a single space. Default: true."),
      ];
      outputs = [
        out("text", "string", "The plain text extracted from the HTML content after all processing."),
        out("tags_removed", "number", "Approximate count of HTML tags stripped from the content."),
        out("original_length", "number", "Character count of the original HTML input."),
        out("output_length", "number", "Character count of the plain text output."),
      ];
      constraints = [
        "allowed_tags must be comma-separated lowercase tag names with no spaces: b,i,strong",
        "skip_script_style removes all content between opening and closing script/style tags",
        "Block elements for preserve_line_breaks: p, div, br, h1, h2, h3, h4, h5, h6, li, tr",
        "HTML entity decoding covers: &amp; &lt; &gt; &quot; &#39;",
        "Tag count is approximate for malformed or deeply nested HTML",
        "content field is used (not html) for consistency with other document capabilities",
      ];
      exampleInput = "{\"content\": \"<h1>Title</h1><p>Hello &amp; World</p><script>alert(1)</script>\", \"decode_entities\": true, \"preserve_line_breaks\": true, \"skip_script_style\": true, \"allowed_tags\": null, \"collapse_whitespace\": true}";
      exampleOutput = "{\"text\": \"Title\\n\\nHello & World\", \"tags_removed\": 6, \"original_length\": 63, \"output_length\": 20}";
    },
    {
      name = "normalize_text";
      description = "Apply a configurable normalization pipeline to text: Unicode normalization, diacritic removal, case folding, punctuation/number/symbol stripping, and whitespace normalization. Each transformation is independently controlled and applied in a fixed sequence. Returns normalized text with a list of operations that actively changed the content.";
      category = "Documents";
      inputs = [
        inp("text", "string", true, "The input text to normalize. All enabled transformations are applied in a deterministic sequence."),
        inp("lowercase", "boolean", false, "When true, converts all characters to lowercase. Applied after diacritic removal. Default: false."),
        inp("remove_punctuation", "boolean", false, "When true, strips punctuation marks (non-alphanumeric, non-whitespace punctuation). Default: false."),
        inp("normalize_unicode", "string", false, "Unicode normalization form. Accepted values: none, NFC (canonical composition — recommended), NFD, NFKC, NFKD. Default: none."),
        inp("remove_diacritics", "boolean", false, "When true, replaces common accented Latin characters with ASCII base forms: e.g. e for e-acute, n for n-tilde, u for u-umlaut, c for c-cedilla. Default: false."),
        inp("whitespace_mode", "string", false, "Whitespace handling. preserve: unchanged. collapse: multiple spaces/tabs to one. strip: trim leading/trailing. normalize: both collapse and strip. Default: preserve."),
        inp("remove_numbers", "boolean", false, "When true, removes all digit characters [0-9] from the text. Default: false."),
        inp("remove_symbols", "boolean", false, "When true, removes non-alphanumeric, non-whitespace symbols such as @, #, $, %, ^, *, =, +. Default: false."),
        inp("locale", "string", false, "Locale hint for case folding. Accepted values: en (standard ASCII), tr (Turkish dotless-i rules). Default: en."),
      ];
      outputs = [
        out("text", "string", "The normalized text after all enabled transformations."),
        out("original_length", "number", "Character count of the input text before normalization."),
        out("normalized_length", "number", "Character count of the output text after normalization."),
        out("operations_applied", "array<string>", "Names of transformations that actively modified the text (excludes no-ops)."),
      ];
      constraints = [
        "Transformations are applied in this fixed order: normalize_unicode, remove_diacritics, lowercase, remove_punctuation, remove_numbers, remove_symbols, whitespace_mode",
        "normalize_unicode must be one of: none, NFC, NFD, NFKC, NFKD",
        "whitespace_mode must be one of: preserve, collapse, strip, normalize",
        "locale must be one of: en, tr",
        "remove_diacritics covers common Latin extended characters; non-Latin script coverage is limited",
      ];
      exampleInput = "{\"text\": \"  Hello, World! 123 cafe  \", \"lowercase\": true, \"remove_punctuation\": true, \"normalize_unicode\": \"NFC\", \"remove_diacritics\": true, \"whitespace_mode\": \"normalize\", \"remove_numbers\": false, \"remove_symbols\": false, \"locale\": \"en\"}";
      exampleOutput = "{\"text\": \"hello world 123 cafe\", \"original_length\": 26, \"normalized_length\": 20, \"operations_applied\": [\"normalize_unicode\", \"lowercase\", \"remove_punctuation\", \"whitespace_mode\"]}";
    },
    // ── Data / Parsing ───────────────────────────────────────────────────────
    {
      name = "parse_json";
      description = "Parse and analyze a JSON string, returning structured metadata including top-level keys, depth, array detection, and byte size. Supports field inclusion/exclusion filtering and optional pretty-printing for downstream consumption.";
      category = "Data";
      inputs = [
        inp("content", "string", true, "Raw JSON string to parse and analyze"),
        inp("strict_mode", "boolean", false, "When true (default), enforces strict JSON spec; when false, tolerates trailing commas and single-quoted strings"),
        inp("max_depth", "number", false, "Maximum nesting depth to analyze (default 50); structures deeper than this are marked with __depth_exceeded"),
        inp("include_keys", "array<string>", false, "If provided, only these top-level keys are included in the parsed output"),
        inp("exclude_keys", "array<string>", false, "Top-level keys to remove from the parsed output"),
        inp("pretty_print", "boolean", false, "Format the output JSON with indentation (default false)"),
        inp("indent_size", "number", false, "Number of spaces per indentation level when pretty_print is true (default 2)"),
      ];
      outputs = [
        out("parsed", "object", "The parsed JSON value after applying include_keys/exclude_keys filters"),
        out("key_count", "number", "Number of top-level keys in the parsed object"),
        out("is_array", "boolean", "True if the root JSON value is an array"),
        out("depth", "number", "Estimated nesting depth of the JSON structure"),
        out("size_bytes", "number", "Byte size of the input JSON string"),
        out("keys", "array<string>", "Top-level keys of the parsed object (empty if root is array or primitive)"),
      ];
      constraints = [
        "Input must be a non-empty JSON string",
        "include_keys and exclude_keys are mutually exclusive; include_keys takes priority if both are provided",
        "max_depth only affects depth reporting, not parsing",
      ];
      exampleInput = "{\"content\": \"{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30, \\\"address\\\": {\\\"city\\\": \\\"London\\\"}}\", \"strict_mode\": true, \"max_depth\": 50, \"include_keys\": [\"name\", \"age\"], \"pretty_print\": true, \"indent_size\": 2}";
      exampleOutput = "{\"parsed\": \"{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30}\", \"key_count\": 2, \"is_array\": false, \"depth\": 2, \"size_bytes\": 67, \"keys\": [\"name\", \"age\"]}";
    },
    {
      name = "validate_json";
      description = "Validate a JSON string for syntactic correctness and optionally validate its structure against a provided JSON Schema. Returns detailed per-field errors including path, expected type, and actual value for easy debugging in agent workflows.";
      category = "Data";
      inputs = [
        inp("content", "string", true, "JSON string to validate"),
        inp("schema", "string", false, "JSON Schema object (as a JSON string) defining required fields and their expected types; supports: type, required, properties, enum, minimum, maximum, minLength, maxLength"),
        inp("allow_null_values", "boolean", false, "Whether null values are considered valid for any field (default true)"),
        inp("strict_types", "boolean", false, "When true, reject numeric strings like \"30\" for fields that expect number type (default false)"),
        inp("detailed_errors", "boolean", false, "Return detailed error objects with path, expected, and actual fields (default true)"),
        inp("max_errors", "number", false, "Maximum number of validation errors to collect before stopping (default 10)"),
      ];
      outputs = [
        out("is_valid", "boolean", "True if the JSON is syntactically valid and passes all schema constraints"),
        out("errors", "array<object>", "Array of validation error objects, each with: path (string), message (string), expected (string), actual (string)"),
        out("error_count", "number", "Total number of validation errors found"),
        out("warnings", "array<string>", "Non-fatal warnings such as unrecognized fields when strict_mode is active"),
      ];
      constraints = [
        "Schema validation supports: required fields, type checking (string, number, boolean, object, array), enum values, min/max for numbers, minLength/maxLength for strings",
        "If no schema is provided, only syntactic JSON validity is checked",
        "max_errors caps error collection; does not indicate total errors in the document",
      ];
      exampleInput = "{\"content\": \"{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30, \\\"role\\\": \\\"admin\\\"}\", \"schema\": \"{\\\"required\\\": [\\\"name\\\", \\\"age\\\"], \\\"properties\\\": {\\\"name\\\": {\\\"type\\\": \\\"string\\\"}, \\\"age\\\": {\\\"type\\\": \\\"number\\\", \\\"minimum\\\": 0}, \\\"role\\\": {\\\"type\\\": \\\"string\\\", \\\"enum\\\": [\\\"admin\\\", \\\"user\\\"]}}}\", \"allow_null_values\": true, \"strict_types\": false, \"detailed_errors\": true, \"max_errors\": 10}";
      exampleOutput = "{\"is_valid\": true, \"errors\": [], \"error_count\": 0, \"warnings\": []}";
    },
    {
      name = "extract_fields";
      description = "Extract one or more fields from a JSON object or array of objects, with support for dot-notation nested paths, field renaming, default values for missing fields, type coercion, and null filtering. Designed for reliable structured data extraction in agent pipelines.";
      category = "Data";
      inputs = [
        inp("content", "string", true, "JSON object or array of objects to extract fields from"),
        inp("fields", "array<string>", true, "List of field names or dot-notation paths (e.g. \"user.address.city\") to extract"),
        inp("rename_map", "object", false, "JSON object mapping original field names to new output names: {\"original\": \"renamed\"}"),
        inp("default_values", "object", false, "JSON object providing fallback values for fields that are missing or null: {\"field_name\": \"default_value\"}"),
        inp("type_coerce", "boolean", false, "Attempt to coerce extracted string values to their inferred types: \"42\" becomes 42, \"true\" becomes true (default false)"),
        inp("include_nulls", "boolean", false, "Whether to include fields whose value is null in the output (default true)"),
        inp("flatten_nested", "boolean", false, "Enable dot-notation path resolution to navigate nested objects: \"user.name\" extracts obj.user.name (default false)"),
      ];
      outputs = [
        out("extracted", "object", "Object containing only the requested fields, with renaming and defaults applied"),
        out("found_count", "number", "Number of requested fields that were successfully found"),
        out("missing_fields", "array<string>", "Fields that were not found in the source object and had no default value"),
        out("total_fields_requested", "number", "Total number of fields requested for extraction"),
      ];
      constraints = [
        "Dot-notation paths require flatten_nested to be true",
        "rename_map keys must match the original field names (before renaming)",
        "type_coerce applies only to string values that look like numbers or booleans",
        "When content is an array, extraction applies to the first object only",
      ];
      exampleInput = "{\"content\": \"{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": \\\"30\\\", \\\"role\\\": null, \\\"address\\\": {\\\"city\\\": \\\"London\\\"}}\", \"fields\": [\"name\", \"age\", \"role\", \"address.city\", \"missing_field\"], \"rename_map\": {\"name\": \"full_name\"}, \"default_values\": {\"missing_field\": \"N/A\"}, \"type_coerce\": true, \"include_nulls\": true, \"flatten_nested\": true}";
      exampleOutput = "{\"extracted\": {\"full_name\": \"Alice\", \"age\": 30, \"role\": null, \"address.city\": \"London\", \"missing_field\": \"N/A\"}, \"found_count\": 5, \"missing_fields\": [], \"total_fields_requested\": 5}";
    },
    {
      name = "extract_table";
      description = "Parse CSV or delimited tabular text into a structured table of rows and columns. Supports custom delimiters, header detection, column filtering and reordering, type inference, and row limits for efficient downstream processing.";
      category = "Data";
      inputs = [
        inp("content", "string", true, "CSV or delimited tabular text to parse into a structured table"),
        inp("columns", "array<string>", false, "Override column names; if not provided, the first row is used as headers (requires has_header true)"),
        inp("delimiter", "string", false, "Field delimiter character (default \",\"); use \"\\t\" for TSV"),
        inp("has_header", "boolean", false, "Whether the first row contains column names (default true)"),
        inp("filter_empty_columns", "boolean", false, "Remove columns where all values are empty or whitespace-only (default false)"),
        inp("column_order", "array<string>", false, "Reorder output columns to this specified list; columns not in this list are dropped"),
        inp("infer_types", "boolean", false, "Parse numeric strings as numbers and \"true\"/\"false\" strings as booleans (default false)"),
        inp("skip_empty_rows", "boolean", false, "Ignore rows where all cell values are empty (default true)"),
        inp("max_rows", "number", false, "Limit output to this many data rows, excluding the header row"),
      ];
      outputs = [
        out("table", "array<object>", "Array of row objects keyed by column name"),
        out("row_count", "number", "Number of data rows in the output (after filtering and max_rows)"),
        out("column_count", "number", "Number of columns in the output"),
        out("columns", "array<string>", "Final ordered list of column names used in the output"),
        out("has_header", "boolean", "Whether a header row was detected or provided"),
      ];
      constraints = [
        "delimiter must be a single character or escape sequence (\\t)",
        "column_order filters the output to only listed columns",
        "max_rows applies after skip_empty_rows filtering",
        "infer_types applies to cell values only, not column names",
      ];
      exampleInput = "{\"content\": \"name,age,city\\nAlice,30,London\\nBob,25,Paris\\n,, \", \"delimiter\": \",\", \"has_header\": true, \"filter_empty_columns\": false, \"column_order\": [\"name\", \"age\", \"city\"], \"infer_types\": true, \"skip_empty_rows\": true, \"max_rows\": 100}";
      exampleOutput = "{\"table\": [{\"name\": \"Alice\", \"age\": 30, \"city\": \"London\"}, {\"name\": \"Bob\", \"age\": 25, \"city\": \"Paris\"}], \"row_count\": 2, \"column_count\": 3, \"columns\": [\"name\", \"age\", \"city\"], \"has_header\": true}";
    },
    {
      name = "text_to_key_value";
      description = "Parse plain text lines of key-value pairs into a structured JSON object. Supports configurable separators, whitespace trimming, type inference, duplicate key handling, comment line skipping, and key transformation for clean, normalized output.";
      category = "Data";
      inputs = [
        inp("content", "string", true, "Plain text with one key-value pair per line, e.g. \"name: Alice\\nage: 30\""),
        inp("separator", "string", false, "Character(s) separating key from value on each line (default \":\")"),
        inp("trim_keys", "boolean", false, "Strip leading and trailing whitespace from key names (default true)"),
        inp("trim_values", "boolean", false, "Strip leading and trailing whitespace from values (default true)"),
        inp("allow_duplicate_keys", "boolean", false, "When true, duplicate keys accumulate into arrays; when false, the last value wins (default false)"),
        inp("infer_types", "boolean", false, "Parse \"true\"/\"false\" as booleans and numeric strings as numbers in output values (default false)"),
        inp("skip_empty_lines", "boolean", false, "Ignore lines that are blank or contain only whitespace (default true)"),
        inp("skip_comment_lines", "boolean", false, "Ignore lines whose first non-whitespace character is # (default false)"),
        inp("key_transform", "string", false, "Transformation applied to all key names: \"none\" (default), \"lowercase\", \"uppercase\", \"snake_case\""),
      ];
      outputs = [
        out("data", "object", "Parsed key-value pairs as a JSON object; duplicate keys produce array values when allow_duplicate_keys is true"),
        out("pair_count", "number", "Number of key-value pairs successfully parsed"),
        out("skipped_lines", "number", "Number of lines skipped due to being empty, comment, or unparseable"),
        out("duplicate_keys", "array<string>", "List of keys that appeared more than once in the input"),
      ];
      constraints = [
        "Lines without the separator character are silently skipped and counted in skipped_lines",
        "key_transform snake_case converts spaces and hyphens to underscores and lowercases",
        "separator is treated as a plain string, not a regex; first occurrence splits key from value",
        "infer_types only affects output values, not key names",
      ];
      exampleInput = "{\"content\": \"# User record\\nname: Alice Smith\\nAge: 30\\nactive: true\\nscore: 98.5\\nname: Alice Updated\", \"separator\": \":\", \"trim_keys\": true, \"trim_values\": true, \"allow_duplicate_keys\": true, \"infer_types\": true, \"skip_empty_lines\": true, \"skip_comment_lines\": true, \"key_transform\": \"lowercase\"}";
      exampleOutput = "{\"data\": {\"name\": [\"Alice Smith\", \"Alice Updated\"], \"age\": 30, \"active\": true, \"score\": 98.5}, \"pair_count\": 5, \"skipped_lines\": 1, \"duplicate_keys\": [\"name\"]}";
    },
    // ── Data Transformation ──────────────────────────────────────────────────
    {
      name = "transform_data"; description = "Apply a sequence of field-level transformation operations to a JSON object or array of objects. Supports rename, add, remove, compute (expression with field references), and value map operations applied in order.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "JSON array of objects or a single JSON object to transform"),
        inp("transformations", "array", true, "Ordered list of transform ops. Each: {\"op\": \"rename|add|remove|compute|map\", \"field\": string, \"source_field\"?: string, \"value\"?: any, \"expression\"?: string, \"value_map\"?: object}. rename: moves source_field to field. add: sets field=value. remove: deletes field. compute: evaluates expression with {field_name} references. map: replaces field values via value_map lookup."),
        inp("include_unmapped", "boolean", false, "Keep fields not referenced by any transformation (default true)"),
        inp("apply_to_all", "boolean", false, "Apply transformations to every object in array; false applies only to the first (default true)"),
        inp("error_on_missing", "boolean", false, "Return error if a referenced source field is missing from an object (default false)"),
      ];
      outputs = [
        out("result", "array|object", "Transformed object or array of objects"),
        out("transformed_count", "number", "Number of objects processed"),
        out("operations_applied", "number", "Total transformation operations applied across all objects"),
        out("errors", "array<string>", "Non-fatal per-object errors when fields were missing and error_on_missing is false"),
      ];
      constraints = ["compute expressions support +, -, *, / operators and {field_name} references", "operations are applied in declaration order", "map op requires value_map object; unmatched values are left unchanged"];
      exampleInput = "{\"content\": \"[{\\\"first_name\\\": \\\"Alice\\\", \\\"price\\\": 10, \\\"qty\\\": 3}]\", \"transformations\": [{\"op\": \"rename\", \"source_field\": \"first_name\", \"field\": \"name\"}, {\"op\": \"compute\", \"field\": \"total\", \"expression\": \"{price}*{qty}\"}, {\"op\": \"remove\", \"field\": \"qty\"}, {\"op\": \"add\", \"field\": \"currency\", \"value\": \"USD\"}]}";
      exampleOutput = "{\"result\": [{\"price\": 10, \"name\": \"Alice\", \"total\": 30, \"currency\": \"USD\"}], \"transformed_count\": 1, \"operations_applied\": 4, \"errors\": []}";
    },
    {
      name = "filter_data"; description = "Filter a JSON array of objects using one or more field-level conditions. Supports 13 operators, logical AND/OR combination, inversion, offset/limit pagination, and per-filter case sensitivity overrides.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "JSON array of objects to filter"),
        inp("filters", "array", true, "List of filter conditions. Each: {\"field\": string, \"operator\": string, \"value\": any, \"case_sensitive\"?: boolean}. Operators: eq, neq, gt, gte, lt, lte, contains, not_contains, starts_with, ends_with, in, not_in, is_null, is_not_null"),
        inp("logical_operator", "string", false, "How to combine multiple filters: AND (all must match) or OR (any must match) — default AND"),
        inp("case_sensitive", "boolean", false, "Global case sensitivity for string comparisons; overridden per-filter (default false)"),
        inp("invert", "boolean", false, "Return items that do NOT match the combined filter (default false)"),
        inp("limit", "number", false, "Max items to return after filtering (default unlimited)"),
        inp("offset", "number", false, "Skip this many matching items before returning results (default 0)"),
      ];
      outputs = [
        out("result", "array", "Filtered and paginated array of objects"),
        out("matched_count", "number", "Items matching the filter before offset/limit"),
        out("total_count", "number", "Total items in the input array"),
        out("filtered_out", "number", "Items excluded by the filter"),
      ];
      constraints = ["in and not_in operators expect value to be a JSON array string", "is_null and is_not_null ignore the value field", "numeric operators gt, gte, lt, lte parse values as floats when possible"];
      exampleInput = "{\"content\": \"[{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30}, {\\\"name\\\": \\\"Bob\\\", \\\"age\\\": 17}, {\\\"name\\\": \\\"Carol\\\", \\\"age\\\": 25}]\", \"filters\": [{\"field\": \"age\", \"operator\": \"gte\", \"value\": \"18\"}], \"logical_operator\": \"AND\", \"limit\": 10, \"offset\": 0}";
      exampleOutput = "{\"result\": [{\"name\": \"Alice\", \"age\": 30}, {\"name\": \"Carol\", \"age\": 25}], \"matched_count\": 2, \"total_count\": 3, \"filtered_out\": 1}";
    },
    {
      name = "sort_data"; description = "Sort a JSON array by one or more fields with per-field ordering, null placement control, and natural sort support for strings containing embedded numbers.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "JSON array of objects or primitives to sort"),
        inp("sort_fields", "array", true, "Ordered list of sort specs. Each: {\"field\": string, \"order\": \"asc\"|\"desc\", \"nulls\": \"first\"|\"last\", \"case_sensitive\"?: boolean}. Use \"_value\" as field name for primitive arrays."),
        inp("natural_sort", "boolean", false, "Use natural sort for strings with embedded numbers (item2 before item10) — default false"),
        inp("stable", "boolean", false, "Preserve relative order of equal elements (default true)"),
      ];
      outputs = [
        out("result", "array", "Sorted array"),
        out("original_count", "number", "Total items sorted"),
        out("sort_fields_used", "array<string>", "Field names applied during sort"),
      ];
      constraints = ["Multi-field sort applies fields in declaration order as tiebreakers", "Numeric strings are compared as numbers when both values parse as float", "natural_sort only affects string fields"];
      exampleInput = "{\"content\": \"[{\\\"dept\\\": \\\"eng\\\", \\\"salary\\\": 90000}, {\\\"dept\\\": \\\"mkt\\\", \\\"salary\\\": 75000}, {\\\"dept\\\": \\\"eng\\\", \\\"salary\\\": 85000}]\", \"sort_fields\": [{\"field\": \"dept\", \"order\": \"asc\", \"nulls\": \"last\"}, {\"field\": \"salary\", \"order\": \"desc\", \"nulls\": \"last\"}]}";
      exampleOutput = "{\"result\": [{\"dept\": \"eng\", \"salary\": 90000}, {\"dept\": \"eng\", \"salary\": 85000}, {\"dept\": \"mkt\", \"salary\": 75000}], \"original_count\": 3, \"sort_fields_used\": [\"dept\", \"salary\"]}";
    },
    {
      name = "deduplicate_data"; description = "Remove duplicate entries from a JSON array using a composite key with configurable comparison mode, keep strategy, and optional duplicate count annotation.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "JSON array of objects to deduplicate"),
        inp("by_fields", "array<string>", false, "Fields to use as composite deduplication key. If omitted, the full serialized object is compared."),
        inp("case_sensitive", "boolean", false, "Case sensitivity for string field comparisons (default true)"),
        inp("compare_mode", "string", false, "Comparison mode: exact (strict equality), normalized (trim+lowercase before compare), type_coerced (compare after numeric/boolean coercion) — default exact"),
        inp("keep", "string", false, "Which duplicate to keep: first or last (default first)"),
        inp("count_duplicates", "boolean", false, "Add a _duplicate_count field to each kept record showing total copies including the kept one (default false)"),
      ];
      outputs = [
        out("result", "array", "Deduplicated array"),
        out("original_count", "number", "Items in input"),
        out("deduplicated_count", "number", "Items in output after deduplication"),
        out("duplicates_removed", "number", "Items removed as duplicates"),
      ];
      constraints = ["by_fields: only listed fields form the composite key; other fields are ignored for comparison", "keep=last reverses, deduplicates, then re-reverses to maintain stable relative order", "count_duplicates minimum value is 1 for every kept record"];
      exampleInput = "{\"content\": \"[{\\\"id\\\": 1, \\\"name\\\": \\\"Alice\\\"}, {\\\"id\\\": 2, \\\"name\\\": \\\"Bob\\\"}, {\\\"id\\\": 1, \\\"name\\\": \\\"Alice Duplicate\\\"}]\", \"by_fields\": [\"id\"], \"keep\": \"first\", \"count_duplicates\": true}";
      exampleOutput = "{\"result\": [{\"id\": 1, \"name\": \"Alice\", \"_duplicate_count\": 2}, {\"id\": 2, \"name\": \"Bob\", \"_duplicate_count\": 1}], \"original_count\": 3, \"deduplicated_count\": 2, \"duplicates_removed\": 1}";
    },
    {
      name = "merge_objects"; description = "Merge two or more JSON objects with configurable conflict resolution, shallow or deep merging, array merge strategies, null value exclusion, and diff output mode.";
      category = "Transform";
      inputs = [
        inp("objects", "array", false, "JSON array of 2 or more object strings to merge in order. Takes priority over object1/object2 if provided."),
        inp("object1", "string", false, "Base object — used when objects array is not provided"),
        inp("object2", "string", false, "Override object — used when objects array is not provided"),
        inp("deep_merge", "boolean", false, "Recursively merge nested objects (default false — shallow, later keys overwrite)"),
        inp("conflict_strategy", "string", false, "How to handle key conflicts: overwrite (later wins), keep_first (earlier wins), error (fail on first conflict), array (combine into array) — default overwrite"),
        inp("array_merge_mode", "string", false, "For array values at the same key: replace (later overwrites), concat (combine arrays), unique (concat+deduplicate) — default replace"),
        inp("exclude_null_values", "boolean", false, "Do not merge keys whose value is null (default false)"),
        inp("output_format", "string", false, "object (merged result) or diff (only conflicting keys with before/after values) — default object"),
      ];
      outputs = [
        out("result", "object", "Merged object, or diff map when output_format=diff"),
        out("key_count", "number", "Number of keys in the result"),
        out("conflicts_resolved", "number", "Keys that had conflicting values across sources"),
        out("source_count", "number", "Number of source objects merged"),
      ];
      constraints = ["objects array takes priority over object1/object2 when both are provided", "deep_merge only recurses into nested object values not array elements", "conflict_strategy=error returns error on the first detected key conflict"];
      exampleInput = "{\"objects\": [\"{\\\"name\\\": \\\"Alice\\\", \\\"role\\\": \\\"user\\\"}\", \"{\\\"role\\\": \\\"admin\\\", \\\"level\\\": 5}\", \"{\\\"level\\\": 10, \\\"dept\\\": \\\"eng\\\"}\"], \"conflict_strategy\": \"overwrite\"}";
      exampleOutput = "{\"result\": {\"dept\": \"eng\", \"level\": 10, \"name\": \"Alice\", \"role\": \"admin\"}, \"key_count\": 4, \"conflicts_resolved\": 2, \"source_count\": 3}";
    },
    {
      name = "flatten_object"; description = "Flatten a nested JSON object into a single-level object with configurable path separators, depth limits, array index styles, key prefixing, and null/empty-array filtering.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "Nested JSON object to flatten"),
        inp("separator", "string", false, "Character(s) to join path segments (default '.')"),
        inp("max_depth", "number", false, "Flatten only up to this nesting depth; deeper objects remain as-is (default unlimited)"),
        inp("prefix", "string", false, "String to prepend to all output keys (default empty)"),
        inp("array_index_style", "string", false, "How to represent array indices: bracket (items[0]), dot (items.0), underscore (items_0) — default bracket"),
        inp("skip_null_values", "boolean", false, "Omit keys whose value is null from output (default false)"),
        inp("skip_empty_arrays", "boolean", false, "Omit keys for empty arrays from output (default false)"),
      ];
      outputs = [
        out("result", "object", "Flattened single-level object with path-based keys"),
        out("original_depth", "number", "Maximum nesting depth detected in the input"),
        out("key_count", "number", "Number of keys in the flattened output"),
        out("array_keys_flattened", "number", "Number of array elements expanded into individual keys"),
      ];
      constraints = ["Arrays are expanded into individual keys by default; use max_depth to preserve nested arrays as values", "prefix is applied before the separator when a path has multiple segments"];
      exampleInput = "{\"content\": \"{\\\"user\\\": {\\\"name\\\": \\\"Alice\\\", \\\"address\\\": {\\\"city\\\": \\\"London\\\", \\\"zip\\\": \\\"EC1\\\"}, \\\"tags\\\": [\\\"admin\\\", \\\"user\\\"]}}\", \"separator\": \".\", \"array_index_style\": \"bracket\"}";
      exampleOutput = "{\"result\": {\"user.name\": \"Alice\", \"user.address.city\": \"London\", \"user.address.zip\": \"EC1\", \"user.tags[0]\": \"admin\", \"user.tags[1]\": \"user\"}, \"original_depth\": 3, \"key_count\": 5, \"array_keys_flattened\": 2}";
    },
    {
      name = "expand_object"; description = "Expand a flat object with path-based keys into a fully nested JSON structure. Supports array index detection, type preservation, and conflict resolution when paths overlap.";
      category = "Transform";
      inputs = [
        inp("content", "string", true, "Flat JSON object with path-based keys (e.g. {\"user.name\": \"Alice\"})"),
        inp("separator", "string", false, "Path separator used in the flat keys (default '.')"),
        inp("max_depth", "number", false, "Stop expanding at this depth; deeper path segments remain as flat keys (default unlimited)"),
        inp("array_indices", "boolean", false, "Convert integer path segments to array indices: user.0.name becomes nested array (default true)"),
        inp("preserve_types", "boolean", false, "Infer and preserve original types: numeric strings become numbers, true/false become booleans, null becomes null (default true)"),
        inp("conflict_strategy", "string", false, "When a path conflicts with an existing key: overwrite or skip (default overwrite)"),
      ];
      outputs = [
        out("result", "object", "Expanded nested JSON object"),
        out("expanded_key_count", "number", "Number of flat keys processed"),
        out("depth", "number", "Maximum nesting depth of the output"),
        out("array_keys_created", "number", "Number of array structures created from integer path segments"),
      ];
      constraints = ["Integer path segments are converted to array indices when array_indices=true", "preserve_types applies to leaf values only", "conflict_strategy applies when a path prefix is already set to a scalar value"];
      exampleInput = "{\"content\": \"{\\\"user.name\\\": \\\"Alice\\\", \\\"user.address.city\\\": \\\"London\\\", \\\"user.address.zip\\\": \\\"EC1\\\", \\\"user.scores.0\\\": \\\"95\\\", \\\"user.scores.1\\\": \\\"87\\\"}\", \"array_indices\": true, \"preserve_types\": true}";
      exampleOutput = "{\"result\": {\"user\": {\"name\": \"Alice\", \"address\": {\"city\": \"London\", \"zip\": \"EC1\"}, \"scores\": [95, 87]}}, \"expanded_key_count\": 5, \"depth\": 3, \"array_keys_created\": 1}";
    },
    // ── Search ───────────────────────────────────────────────────────────────
    {
      name = "keyword_search";
      description = "Search text for a keyword or phrase, returning match count, positions, and optional surrounding context. Supports whole-word matching, case sensitivity, match limits, and count-only mode for large documents.";
      category = "Search";
      inputs = [
        inp("content", "string", true, "The text to search within"),
        inp("query", "string", true, "The keyword or phrase to search for"),
        inp("case_sensitive", "boolean", false, "Whether matching is case-sensitive (default false)"),
        inp("match_whole_words", "boolean", false, "Only match complete words, not substrings within larger words (default false)"),
        inp("return_positions", "boolean", false, "Include character position of each match in the output (default false)"),
        inp("max_matches", "number", false, "Stop after finding this many matches; omit for unlimited"),
        inp("context_chars", "number", false, "Number of characters of surrounding context to include with each match (default 0)"),
        inp("count_only", "boolean", false, "Return only match count without match details, faster for large texts (default false)"),
      ];
      outputs = [
        out("found", "boolean", "True if at least one match was found"),
        out("match_count", "number", "Total number of matches found"),
        out("matches", "array<object>", "Array of match objects: match (string), position (number), context (string)"),
        out("query", "string", "The query that was searched"),
      ];
      constraints = [
        "query must be non-empty",
        "match_whole_words checks boundaries using non-alphanumeric-underscore characters",
        "max_matches caps collection after that many results",
        "count_only returns match_count but matches array will be empty",
      ];
      exampleInput = "{\"content\": \"The quick brown fox jumps over the lazy fox\", \"query\": \"fox\", \"case_sensitive\": false, \"match_whole_words\": true, \"return_positions\": true, \"context_chars\": 10, \"count_only\": false}";
      exampleOutput = "{\"found\": true, \"match_count\": 2, \"matches\": [{\"match\": \"fox\", \"position\": 16, \"context\": \"ick brown fox jumps ove\"}, {\"match\": \"fox\", \"position\": 40, \"context\": \" the lazy fox\"}], \"query\": \"fox\"}";
    },
    {
      name = "regex_search";
      description = "Search text using a regular expression pattern. Supports literals, wildcards, character classes, quantifiers, anchors, and escape sequences. Full regex matching, not a literal substring search.";
      category = "Search";
      inputs = [
        inp("content", "string", true, "The text to search"),
        inp("pattern", "string", true, "Regular expression pattern. Supported: literals, . (any char), * (0+), + (1+), ? (0 or 1), [abc] (class), [a-z] (range), [^abc] (negated), ^ (start anchor), $ (end anchor), backslash escaping"),
        inp("flags", "string", false, "Regex flags: i (case insensitive), g (find all, not just first), m (multiline anchors). Combine as gi etc. Default empty string"),
        inp("return_all_matches", "boolean", false, "Return all matches (true) or only the first (false). Default true"),
        inp("capture_groups", "boolean", false, "Extract parenthetical capture group content if present in pattern (default false)"),
        inp("match_limit", "number", false, "Maximum number of matches to return (default 100)"),
        inp("include_positions", "boolean", false, "Include start character position for each match (default false)"),
        inp("context_chars", "number", false, "Characters of surrounding context to include with each match (default 0)"),
      ];
      outputs = [
        out("found", "boolean", "True if at least one match was found"),
        out("match_count", "number", "Number of matches found"),
        out("matches", "array<object>", "Array of match objects: match (string), position (number), context (string)"),
        out("pattern", "string", "The pattern that was used"),
      ];
      constraints = [
        "Supported syntax: literals, . * + ? [] [^] [a-z] ^ $ backslash escaping",
        "Alternation (|) and nested groups not supported",
        "match_limit caps matches at 100 by default",
        "i flag = case insensitive, g flag = find all matches, m flag = multiline anchors",
        "^ and $ match start/end of string; with m flag they match line boundaries",
      ];
      exampleInput = "{\"content\": \"Contact hello@example.com or support@test.org\", \"pattern\": \"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]+\", \"flags\": \"g\", \"return_all_matches\": true, \"include_positions\": true, \"context_chars\": 8, \"match_limit\": 100}";
      exampleOutput = "{\"found\": true, \"match_count\": 2, \"matches\": [{\"match\": \"hello@example.com\", \"position\": 8, \"context\": \"Contact hello@example.com or su\"}, {\"match\": \"support@test.org\", \"position\": 29, \"context\": \".com or support@test.org\"}], \"pattern\": \"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\\\.[a-zA-Z]+\"}";
    },
    {
      name = "substring_search";
      description = "Find all occurrences of an exact substring within text, returning positions, match count, and optional context. Supports overlapping matches, case sensitivity, and result limiting.";
      category = "Search";
      inputs = [
        inp("content", "string", true, "The text to search within"),
        inp("substring", "string", true, "The exact string to find"),
        inp("case_sensitive", "boolean", false, "Case-sensitive matching (default false)"),
        inp("return_all_indices", "boolean", false, "Return positions of all occurrences, not just the first (default true)"),
        inp("context_chars", "number", false, "Number of characters of surrounding context to include with each match (default 0)"),
        inp("max_matches", "number", false, "Limit number of matches returned; omit for unlimited"),
        inp("overlap", "boolean", false, "Allow overlapping matches, e.g. aa in aaa yields 2 instead of 1 (default false)"),
      ];
      outputs = [
        out("found", "boolean", "True if at least one match was found"),
        out("match_count", "number", "Number of occurrences found"),
        out("positions", "array<number>", "Character positions of each match"),
        out("matches", "array<object>", "Array of match objects: match (string), position (number), context (string)"),
        out("substring", "string", "The substring that was searched"),
      ];
      constraints = [
        "substring must be non-empty",
        "overlap=false advances past the end of each match before searching again",
        "overlap=true advances by 1 character each step for overlapping results",
        "max_matches caps collection after that many results",
      ];
      exampleInput = "{\"content\": \"banana\", \"substring\": \"an\", \"case_sensitive\": false, \"return_all_indices\": true, \"context_chars\": 2, \"overlap\": false}";
      exampleOutput = "{\"found\": true, \"match_count\": 2, \"positions\": [1, 3], \"matches\": [{\"match\": \"an\", \"position\": 1, \"context\": \"banan\"}, {\"match\": \"an\", \"position\": 3, \"context\": \"anana\"}], \"substring\": \"an\"}";
    },
    // ── Storage ──────────────────────────────────────────────────────────────
    {
      name = "store_object";
      description = "Store any JSON value under a key with optional TTL expiration, metadata, tags, and conditional write semantics. Values are persisted in canister state and wrapped in a storage envelope tracking creation time and expiry. Expired entries are lazily evicted on read. Use overwrite=false to implement safe insert-only semantics.";
      category = "Storage";
      inputs = [
        inp("key", "string", true, "Storage key — must be non-empty. Use structured prefixes like user:123 or session:abc for namespace organization."),
        inp("value", "string", true, "Value to store — any valid string, including JSON objects, arrays, or plain text."),
        inp("ttl_seconds", "number", false, "Time-to-live in seconds. After this duration from creation, the entry is considered expired and will be evicted on next read. Null or 0 means no expiration."),
        inp("metadata", "object", false, "Arbitrary JSON metadata object stored alongside the value. Useful for tagging, audit fields, or custom properties. Must be a valid JSON object string."),
        inp("tags", "array", false, "Array of string tags for categorization and filtering. Used by list_objects to filter by tag. Default: []."),
        inp("overwrite", "boolean", false, "When true (default), overwrites any existing value at this key. When false, returns stored=false if the key already exists and has not expired."),
        inp("return_stored", "boolean", false, "When true, returns the stored value in the response for confirmation. Default: false."),
      ];
      outputs = [
        out("key", "string", "The storage key used."),
        out("stored", "boolean", "True if the value was successfully stored; false if overwrite=false and key already existed."),
        out("created_at", "number", "Unix timestamp (seconds) when the entry was created."),
        out("expires_at", "number|null", "Unix timestamp (seconds) when the entry expires, or null if no TTL was set."),
        out("size_bytes", "number", "Approximate byte size of the stored value string."),
        out("value", "string", "The stored value, only present when return_stored=true."),
      ];
      constraints = [
        "key must be non-empty",
        "ttl_seconds must be a positive integer or null/0 for no expiry",
        "metadata must be a valid JSON object string if provided",
        "overwrite=false prevents any update to an existing non-expired key",
      ];
      exampleInput = "{\"key\": \"user:123\", \"value\": \"{\\\"name\\\": \\\"Alice\\\", \\\"role\\\": \\\"admin\\\"}\", \"ttl_seconds\": 3600, \"metadata\": \"{\\\"created_by\\\": \\\"system\\\"}\", \"tags\": [\"user\", \"admin\"], \"overwrite\": true, \"return_stored\": false}";
      exampleOutput = "{\"key\": \"user:123\", \"stored\": true, \"created_at\": 1712000000, \"expires_at\": 1712003600, \"size_bytes\": 38}";
    },
    {
      name = "retrieve_object";
      description = "Retrieve a stored value by key with optional metadata, JSON decoding, and fallback. Lazily checks TTL on read — expired entries are treated as missing. Returns the raw or decoded value along with envelope metadata when requested.";
      category = "Storage";
      inputs = [
        inp("key", "string", true, "Storage key to retrieve."),
        inp("fallback_value", "string", false, "Value to return when the key is not found or has expired. If not provided and key is missing, value will be null."),
        inp("include_metadata", "boolean", false, "When true, includes metadata, tags, created_at, and expires_at fields in the response. Default: false."),
        inp("decode_json", "boolean", false, "When true, attempts to parse the stored value as JSON. If parsing fails, the raw string is returned. Default: false."),
      ];
      outputs = [
        out("key", "string", "The storage key requested."),
        out("value", "string", "The stored value or fallback_value if not found. Null if not found and no fallback provided."),
        out("found", "boolean", "True if the key existed and had not expired at the time of retrieval."),
        out("metadata", "object", "The stored metadata object, only present when include_metadata=true and entry was found."),
        out("tags", "array<string>", "The stored tags array, only present when include_metadata=true and entry was found."),
        out("created_at", "number", "Unix timestamp (seconds) when the entry was created, only present when include_metadata=true."),
        out("expires_at", "number|null", "Unix timestamp (seconds) when the entry expires, or null. Only present when include_metadata=true."),
      ];
      constraints = [
        "Expired entries (current time >= expires_at) are treated as missing — found=false is returned",
        "fallback_value is returned only when found=false",
        "include_metadata returns null for metadata/tags if they were not set on store",
      ];
      exampleInput = "{\"key\": \"user:123\", \"fallback_value\": null, \"include_metadata\": true, \"decode_json\": false}";
      exampleOutput = "{\"key\": \"user:123\", \"value\": \"{\\\"name\\\": \\\"Alice\\\", \\\"role\\\": \\\"admin\\\"}\", \"found\": true, \"metadata\": \"{\\\"created_by\\\": \\\"system\\\"}\", \"tags\": [\"user\", \"admin\"], \"created_at\": 1712000000, \"expires_at\": 1712003600}";
    },
    {
      name = "update_object";
      description = "Update the value stored at a key with configurable merge strategies (replace, shallow merge, or deep merge). Supports conditional update, metadata preservation, TTL refresh, and optional return of the previous value for auditing.";
      category = "Storage";
      inputs = [
        inp("key", "string", true, "Storage key to update."),
        inp("value", "string", true, "New value to write. Interpretation depends on merge_strategy."),
        inp("merge_strategy", "string", false, "How to combine new value with existing. replace: overwrites entirely (default). merge_shallow: merges top-level JSON object keys (new wins). merge_deep: recursively merges nested objects."),
        inp("only_if_exists", "boolean", false, "When true, the update only proceeds if the key exists and has not expired. Returns updated=false otherwise. Default: false."),
        inp("preserve_metadata", "boolean", false, "When true (default), retains the original metadata and tags. When false, clears them on update."),
        inp("ttl_seconds", "number", false, "If provided, resets the TTL from now. Null preserves the existing TTL. Set to 0 to remove TTL."),
        inp("return_previous", "boolean", false, "When true, includes the previous_value in the response before the update. Default: false."),
      ];
      outputs = [
        out("key", "string", "The storage key updated."),
        out("updated", "boolean", "True if the update was applied; false if only_if_exists=true and key was missing or expired."),
        out("merge_strategy", "string", "The merge strategy used."),
        out("previous_value", "string", "The value before the update, only present when return_previous=true."),
        out("updated_at", "number", "Unix timestamp (seconds) of the update."),
      ];
      constraints = [
        "merge_shallow and merge_deep require both existing and new values to be valid JSON objects; falls back to replace if not",
        "only_if_exists treats expired entries as missing",
        "ttl_seconds=0 removes the TTL (entry becomes persistent)",
      ];
      exampleInput = "{\"key\": \"user:123\", \"value\": \"{\\\"role\\\": \\\"superadmin\\\"}\", \"merge_strategy\": \"merge_shallow\", \"only_if_exists\": true, \"preserve_metadata\": true, \"ttl_seconds\": null, \"return_previous\": true}";
      exampleOutput = "{\"key\": \"user:123\", \"updated\": true, \"merge_strategy\": \"merge_shallow\", \"previous_value\": \"{\\\"name\\\": \\\"Alice\\\", \\\"role\\\": \\\"admin\\\"}\", \"updated_at\": 1712001500}";
    },
    {
      name = "delete_object";
      description = "Delete one or more stored objects by key. Supports single key deletion, batch deletion, optional soft delete (marks as deleted without removing), return of deleted values for auditing, and configurable error behavior for missing keys.";
      category = "Storage";
      inputs = [
        inp("key", "string", false, "Single key to delete. Use batch_keys for bulk deletion. One of key or batch_keys is required."),
        inp("batch_keys", "array", false, "Array of key strings to delete in a single call."),
        inp("soft_delete", "boolean", false, "When true, marks entries as soft-deleted (adds _deleted: true to metadata) rather than removing them. Default: false."),
        inp("return_deleted", "boolean", false, "When true, includes the values of deleted entries in the response. Default: false."),
        inp("error_on_missing", "boolean", false, "When true, returns an error if any key does not exist or has expired. When false (default), missing keys are reported in not_found_keys."),
      ];
      outputs = [
        out("deleted_keys", "array<string>", "Keys that were successfully deleted or soft-deleted."),
        out("not_found_keys", "array<string>", "Keys that were not found or had already expired."),
        out("delete_count", "number", "Number of keys successfully deleted."),
        out("soft_deleted", "boolean", "True if soft_delete mode was used."),
        out("deleted_values", "array<object>", "Array of {key, value} objects for deleted entries, only present when return_deleted=true."),
      ];
      constraints = [
        "At least one of key or batch_keys must be provided",
        "Expired entries are treated as not-found and reported in not_found_keys",
        "error_on_missing triggers if any key in the request is missing",
      ];
      exampleInput = "{\"batch_keys\": [\"user:123\", \"user:456\", \"user:999\"], \"soft_delete\": false, \"return_deleted\": false, \"error_on_missing\": false}";
      exampleOutput = "{\"deleted_keys\": [\"user:123\", \"user:456\"], \"not_found_keys\": [\"user:999\"], \"delete_count\": 2, \"soft_deleted\": false}";
    },
    {
      name = "list_objects";
      description = "List keys in the object store with rich filtering, sorting, pagination, and optional metadata inclusion. Supports prefix and suffix matching, tag filtering, regex pattern matching, and TTL-aware filtering. Designed for large-scale key enumeration in agent workflows.";
      category = "Storage";
      inputs = [
        inp("prefix", "string", false, "Filter keys that start with this prefix. Empty string matches all keys. Default: \"\"."),
        inp("suffix", "string", false, "Filter keys that end with this suffix. Applied after prefix filter. Default: \"\"."),
        inp("regex_pattern", "string", false, "Filter keys matching this regex pattern. Supports literals, . * + ? [] [^] ^ $."),
        inp("tags", "array", false, "Filter entries containing ALL of the specified tags. Requires reading envelope metadata. Null or empty disables tag filtering."),
        inp("limit", "number", false, "Maximum number of keys to return. Default: 100. Set to 0 for unlimited."),
        inp("offset", "number", false, "Number of matching keys to skip before returning results. Default: 0."),
        inp("sort_by", "string", false, "Sort field: key (lexicographic, default), created_at (chronological), size (by value byte size)."),
        inp("sort_order", "string", false, "Sort direction: asc (default) or desc."),
        inp("include_metadata", "boolean", false, "When true, returns items array with per-entry metadata: key, size_bytes, created_at, expires_at, tags. Default: false."),
        inp("include_expired", "boolean", false, "When true, includes entries that have passed their TTL. Default: false."),
      ];
      outputs = [
        out("keys", "array<string>", "Array of matching key strings after all filters, sort, and pagination."),
        out("items", "array<object>", "Array of {key, size_bytes, created_at, expires_at, tags} objects when include_metadata=true; empty otherwise."),
        out("total_count", "number", "Total number of matching keys before offset/limit pagination."),
        out("returned_count", "number", "Number of keys returned in this response."),
        out("has_more", "boolean", "True if there are more matching keys beyond offset+limit."),
      ];
      constraints = [
        "prefix and suffix filters are case-sensitive exact string matches",
        "tags filtering reads each entry envelope — slower for large key sets",
        "sort_by created_at and size require reading envelope data for all matching keys",
        "limit=0 returns all matching keys",
        "include_expired=false (default) excludes expired entries",
      ];
      exampleInput = "{\"prefix\": \"user:\", \"suffix\": \"\", \"tags\": [\"admin\"], \"limit\": 10, \"offset\": 0, \"sort_by\": \"created_at\", \"sort_order\": \"desc\", \"include_metadata\": true, \"include_expired\": false}";
      exampleOutput = "{\"keys\": [\"user:123\"], \"items\": [{\"key\": \"user:123\", \"size_bytes\": 38, \"created_at\": 1712000000, \"expires_at\": 1712003600, \"tags\": [\"user\", \"admin\"]}], \"total_count\": 1, \"returned_count\": 1, \"has_more\": false}";
    },
    // ── Compute ──────────────────────────────────────────────────────────────
    {
      name = "compute_math";
      description = "Evaluate a mathematical expression with full operator precedence, variable substitution, and configurable precision and rounding. Supports +, -, *, /, %, ^ (power), unary minus, and parentheses grouping.";
      category = "Compute";
      inputs = [
        inp("expression", "string", true, "Mathematical expression to evaluate. Supports: numbers, +, -, *, /, %, ^ (power), parentheses. Example: \"((150 * 0.2) + 50) / 2\""),
        inp("variables", "object", false, "Variable substitution map as JSON object. Example: {\"price\": 99.99, \"qty\": 3}"),
        inp("precision", "number", false, "Number of decimal places to round result to (0-15, default 10)"),
        inp("rounding_mode", "string", false, "Rounding strategy: \"half_up\" (default), \"half_down\", \"floor\", \"ceiling\", \"truncate\""),
        inp("output_format", "string", false, "Output format: \"number\" (default) or \"string\""),
      ];
      outputs = [
        out("result", "number", "The evaluated numeric result after applying precision and rounding"),
        out("expression_evaluated", "string", "The expression string after variable substitution"),
        out("precision", "number", "The precision used for rounding"),
        out("rounded", "boolean", "True if rounding was applied"),
      ];
      constraints = [
        "Division by zero returns an error",
        "Expression parser supports operator precedence: parentheses > unary minus > ^ > * / % > + -",
        "^ is right-associative",
        "Variables are substituted as numeric values before parsing",
        "precision must be 0-15",
      ];
      exampleInput = "{\"expression\": \"((150 * 0.2) + 50) / 2\", \"variables\": {}, \"precision\": 4, \"rounding_mode\": \"half_up\", \"output_format\": \"number\"}";
      exampleOutput = "{\"result\": 40.0000, \"expression_evaluated\": \"((150 * 0.2) + 50) / 2\", \"precision\": 4, \"rounded\": false}";
    },
    {
      name = "aggregate_data";
      description = "Compute comprehensive statistical aggregations over a numeric array or array of objects. Supports median, mode, standard deviation, variance, percentiles, and grouped aggregations.";
      category = "Compute";
      inputs = [
        inp("content", "string", true, "JSON array of numbers or JSON array of objects"),
        inp("field", "string", false, "If content is an array of objects, extract this numeric field"),
        inp("operations", "array<string>", false, "Which aggregations to compute (default: all). Options: sum, min, max, mean, count, median, mode, stddev, variance, range, percentile_25, percentile_75, percentile_90, percentile_95, percentile_99"),
        inp("grouping_field", "string", false, "If set, group objects by this field and compute aggregations per group"),
        inp("precision", "number", false, "Decimal places for floating point results (default 4)"),
        inp("exclude_nulls", "boolean", false, "Skip null or non-numeric values (default true)"),
        inp("exclude_outliers", "boolean", false, "Exclude values beyond 3 standard deviations from the mean (default false)"),
      ];
      outputs = [
        out("results", "object", "Object mapping each requested operation name to its computed value"),
        out("count", "number", "Number of values included in the aggregation"),
        out("grouped_results", "object", "Per-group aggregation results when grouping_field is provided; null otherwise"),
        out("field", "string", "The field name used for extraction, or null if content was a flat array"),
      ];
      constraints = [
        "content must be a valid JSON array",
        "field is required when content is an array of objects",
        "mode returns the most frequent value; if all values are unique, returns the first value",
        "stddev and variance use population formulas (N denominator)",
      ];
      exampleInput = "{\"content\": \"[{\\\"score\\\": 85}, {\\\"score\\\": 92}, {\\\"score\\\": 78}, {\\\"score\\\": 95}, {\\\"score\\\": 88}]\", \"field\": \"score\", \"operations\": [\"mean\", \"median\", \"stddev\", \"percentile_90\"], \"precision\": 2}";
      exampleOutput = "{\"results\": {\"mean\": 87.60, \"median\": 88.00, \"stddev\": 5.89, \"percentile_90\": 93.80}, \"count\": 5, \"grouped_results\": null, \"field\": \"score\"}";
    },
    {
      name = "compare_values";
      description = "Compare two values using a rich set of operators with type coercion, case control, float tolerance, null handling, and result negation. Supports string, numeric, and boolean comparisons.";
      category = "Compute";
      inputs = [
        inp("value1", "string", true, "First value to compare (type is inferred or specified via the type parameter)"),
        inp("value2", "string", true, "Second value to compare"),
        inp("operator", "string", true, "Comparison operator: eq, neq, gt, gte, lt, lte, contains, starts_with, ends_with"),
        inp("type", "string", false, "How to interpret values: auto (default), string, number, boolean"),
        inp("case_sensitive", "boolean", false, "For string comparisons, whether to respect case (default false)"),
        inp("float_tolerance", "number", false, "Tolerance for floating-point equality (default 0, exact match)"),
        inp("null_handling", "string", false, "How to handle null/empty values: error (default), false, null_first, null_last"),
        inp("negate", "boolean", false, "Invert the final result (default false)"),
      ];
      outputs = [
        out("result", "boolean", "The comparison result (after applying negate if set)"),
        out("value1_coerced", "string", "value1 after type coercion"),
        out("value2_coerced", "string", "value2 after type coercion"),
        out("operator", "string", "The operator used for comparison"),
        out("type_used", "string", "The type interpretation that was applied"),
      ];
      constraints = [
        "contains, starts_with, ends_with are string-only operators",
        "gt, gte, lt, lte on non-numeric values fall back to lexicographic comparison",
        "float_tolerance only applies to eq and neq operators on numeric values",
        "null_handling applies when either value1 or value2 is empty/null",
      ];
      exampleInput = "{\"value1\": \"42\", \"value2\": \"100\", \"operator\": \"lt\", \"type\": \"number\", \"case_sensitive\": false, \"float_tolerance\": 0, \"null_handling\": \"error\", \"negate\": false}";
      exampleOutput = "{\"result\": true, \"value1_coerced\": \"42\", \"value2_coerced\": \"100\", \"operator\": \"lt\", \"type_used\": \"number\"}";
    },
    {
      name = "normalize_values";
      description = "Normalize a numeric array using one of seven methods: min-max scaling, z-score standardization, percentile rank, log/log10 transformation, robust scaling (IQR-based), or decimal scaling. Supports object arrays, precision control, outlier handling, and optional original value inclusion.";
      category = "Compute";
      inputs = [
        inp("content", "string", true, "JSON array of numbers or JSON array of objects"),
        inp("field", "string", false, "If content is an array of objects, extract this numeric field for normalization"),
        inp("method", "string", false, "Normalization method: minmax (default), zscore, percentile, log, log10, robust, decimal_scaling"),
        inp("target_min", "number", false, "Minimum output value for minmax scaling (default 0)"),
        inp("target_max", "number", false, "Maximum output value for minmax scaling (default 1)"),
        inp("precision", "number", false, "Decimal places for normalized output values (default 6)"),
        inp("handle_outliers", "string", false, "Outlier treatment: include (default), clip, remove"),
        inp("output_with_original", "boolean", false, "Include original values alongside normalized values (default false)"),
      ];
      outputs = [
        out("normalized", "array<number>", "Array of normalized values (or {original, normalized} objects when output_with_original is true)"),
        out("method", "string", "The normalization method applied"),
        out("stats", "object", "Descriptive statistics of the input: {min, max, mean, stddev, median}"),
        out("count", "number", "Number of values in the normalized output"),
      ];
      constraints = [
        "log and log10 require all values to be strictly > 0",
        "zscore and robust require at least 2 values",
        "robust method uses median and IQR instead of mean and stddev",
        "decimal_scaling divides each value by 10^k where k = ceil(log10(max|x|))",
        "percentile output is in range [0, 100]",
      ];
      exampleInput = "{\"content\": \"[10, 20, 30, 40, 50]\", \"method\": \"minmax\", \"target_min\": 0, \"target_max\": 1, \"precision\": 4, \"handle_outliers\": \"include\", \"output_with_original\": false}";
      exampleOutput = "{\"normalized\": [0.0000, 0.2500, 0.5000, 0.7500, 1.0000], \"method\": \"minmax\", \"stats\": {\"min\": 10.0000, \"max\": 50.0000, \"mean\": 30.0000, \"stddev\": 14.1421, \"median\": 30.0000}, \"count\": 5}";
    },
    // ── File Operations ──────────────────────────────────────────────────────
    {
      name = "convert_file_format";
      description = "Convert content between structured formats: JSON, CSV, TSV, key-value pairs, and markdown/HTML tables. Supports delimiter configuration, header control, JSON indentation, and null value representation.";
      category = "Files";
      inputs = [
        inp("content", "string", true, "Raw content in the source format"),
        inp("from_format", "string", true, "Source format: json | csv | tsv | key_value"),
        inp("to_format", "string", true, "Target format: json | csv | tsv | markdown_table | html_table | key_value"),
        inp("delimiter", "string", false, "Field delimiter for CSV/TSV input/output (default comma)"),
        inp("include_header", "boolean", false, "Include column headers in CSV/TSV output (default true)"),
        inp("indent_size", "number", false, "Indentation spaces for JSON output (default 2)"),
        inp("pretty_print", "boolean", false, "Format JSON output with indentation (default true)"),
        inp("null_representation", "string", false, "Representation for null/missing values in CSV/TSV output (default empty string)"),
      ];
      outputs = [
        out("content", "string", "Converted output in the target format"),
        out("from_format", "string", "Source format used"),
        out("to_format", "string", "Target format produced"),
        out("row_count", "number", "Number of data rows in the output"),
        out("char_count", "number", "Character count of the output"),
      ];
      constraints = [
        "JSON source must be an array of flat objects for tabular targets",
        "CSV/TSV source must have a header row",
        "key_value source expects one key=value pair per line",
      ];
      exampleInput = "{\"content\": \"name,age,city\\nAlice,30,London\\nBob,25,Paris\", \"from_format\": \"csv\", \"to_format\": \"json\", \"delimiter\": \",\"}";
      exampleOutput = "{\"content\": \"[{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": \\\"30\\\", \\\"city\\\": \\\"London\\\"}, {\\\"name\\\": \\\"Bob\\\", \\\"age\\\": \\\"25\\\", \\\"city\\\": \\\"Paris\\\"}]\", \"from_format\": \"csv\", \"to_format\": \"json\", \"row_count\": 2, \"char_count\": 97}";
    },
    {
      name = "generate_json_file";
      description = "Format, validate, and optionally transform a JSON value into a clean output string. Supports key sorting, array sorting, null pruning, minification, and ASCII escaping for downstream consumption.";
      category = "Files";
      inputs = [
        inp("content", "string", true, "JSON value to format (object, array, or primitive)"),
        inp("indent_size", "number", false, "Spaces per indentation level (default 2)"),
        inp("sort_keys", "boolean", false, "Sort object keys alphabetically at every level (default false)"),
        inp("sort_arrays", "boolean", false, "Sort array values lexicographically for strings, numerically for numbers (default false)"),
        inp("include_null_values", "boolean", false, "Include keys whose value is null; false omits them (default true)"),
        inp("compress", "boolean", false, "Output minified JSON with no whitespace; overrides indent_size (default false)"),
        inp("ensure_ascii", "boolean", false, "Escape all non-ASCII characters as \\uXXXX sequences (default false)"),
      ];
      outputs = [
        out("content", "string", "Formatted JSON string"),
        out("char_count", "number", "Character count of the output"),
        out("key_count", "number", "Number of top-level keys (0 for arrays and primitives)"),
        out("is_valid", "boolean", "Whether the input was valid JSON"),
      ];
      constraints = [
        "Input must be a valid JSON string",
        "compress overrides indent_size when true",
        "sort_arrays sorts only string and number elements; mixed-type arrays left in original order",
      ];
      exampleInput = "{\"content\": \"{\\\"z\\\": null, \\\"a\\\": 1, \\\"m\\\": \\\"hello\\\"}\", \"sort_keys\": true, \"include_null_values\": false}";
      exampleOutput = "{\"content\": \"{\\\"a\\\": 1, \\\"m\\\": \\\"hello\\\"}\", \"char_count\": 22, \"key_count\": 2, \"is_valid\": true}";
    },
    {
      name = "generate_csv";
      description = "Convert a JSON array of objects (or array of arrays) to CSV with full control over delimiters, quoting, column ordering, null handling, line endings, and header inclusion.";
      category = "Files";
      inputs = [
        inp("content", "string", true, "JSON array of objects or array of arrays to convert to CSV"),
        inp("delimiter", "string", false, "Field separator character (default comma)"),
        inp("include_header", "boolean", false, "Include column names as first row (default true)"),
        inp("quote_mode", "string", false, "When to quote fields: minimal (only when needed), all (always), non_numeric (quote strings only), none (never) — default minimal"),
        inp("line_ending", "string", false, "Line ending style: lf (default) or crlf"),
        inp("null_value", "string", false, "Representation for null or missing field values (default empty string)"),
        inp("column_order", "array<string>", false, "Explicit column ordering; unspecified columns appended at end"),
        inp("escape_char", "string", false, "Character for escaping quotes within quoted fields (default double-quote)"),
      ];
      outputs = [
        out("content", "string", "CSV output string"),
        out("row_count", "number", "Number of data rows excluding header"),
        out("column_count", "number", "Number of columns in output"),
        out("char_count", "number", "Character count of the output"),
      ];
      constraints = [
        "Input must be a JSON array; objects in array must be flat",
        "column_order accepts only existing column names; unknown names are ignored",
        "quote_mode none may produce invalid CSV if values contain the delimiter",
      ];
      exampleInput = "{\"content\": \"[{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30}, {\\\"name\\\": \\\"Bob\\\", \\\"age\\\": 25}]\", \"delimiter\": \",\", \"include_header\": true, \"null_value\": \"N/A\"}";
      exampleOutput = "{\"content\": \"name,age\\nAlice,30\\nBob,25\", \"row_count\": 2, \"column_count\": 2, \"char_count\": 24}";
    },
    {
      name = "merge_files";
      description = "Merge multiple text content pieces into a single output with full control over separators, deduplication, sorting, trimming, and optional per-part index prefixes.";
      category = "Files";
      inputs = [
        inp("contents", "array<string>", true, "List of string content pieces to merge (also accepts files key for backward compatibility)"),
        inp("separator", "string", false, "String inserted between each content piece (default newline)"),
        inp("deduplicate_lines", "boolean", false, "Remove duplicate lines from the merged output (default false)"),
        inp("sort_output", "boolean", false, "Sort output lines alphabetically after merging (default false)"),
        inp("trim_each", "boolean", false, "Trim leading/trailing whitespace from each content piece before merging (default false)"),
        inp("filter_empty", "boolean", false, "Skip content pieces that are empty or whitespace-only (default false)"),
        inp("prefix_with_index", "boolean", false, "Prepend each content piece with --- Part N --- before merging (default false)"),
      ];
      outputs = [
        out("content", "string", "Merged output string"),
        out("source_count", "number", "Number of input content pieces processed"),
        out("line_count", "number", "Number of lines in the merged output"),
        out("char_count", "number", "Character count of the output"),
        out("duplicates_removed", "number", "Number of duplicate lines removed (0 when deduplicate_lines is false)"),
      ];
      constraints = [
        "contents array must have at least one item",
        "sort_output applies after deduplicate_lines",
      ];
      exampleInput = "{\"contents\": [\"Hello World\", \"Foo Bar\", \"Hello World\"], \"separator\": \"\\n\", \"deduplicate_lines\": true, \"filter_empty\": true}";
      exampleOutput = "{\"content\": \"Hello World\\nFoo Bar\", \"source_count\": 3, \"line_count\": 2, \"char_count\": 19, \"duplicates_removed\": 1}";
    },
    {
      name = "split_file";
      description = "Split text content into parts using one of several strategies: by line count, character count, custom delimiter, paragraph breaks, or word count. Supports filtering, trimming, and max parts limit.";
      category = "Files";
      inputs = [
        inp("content", "string", true, "The text content to split"),
        inp("strategy", "string", false, "Split strategy: lines (by line count), chars (by character count), delimiter (by custom string), paragraphs (by blank lines), words (by word count) — default lines"),
        inp("chunk_size", "number", false, "Size of each chunk in the unit of the chosen strategy (default 100)"),
        inp("delimiter", "string", false, "Custom split string used when strategy is delimiter (default newline)"),
        inp("filter_empty", "boolean", false, "Remove empty or whitespace-only chunks from output (default true)"),
        inp("trim_parts", "boolean", false, "Trim leading/trailing whitespace from each part (default false)"),
        inp("max_parts", "number", false, "Maximum number of parts to produce; remaining content appended to last part (default 0 meaning no limit)"),
        inp("keep_separator", "boolean", false, "Include the separator string at the end of each chunk when strategy is delimiter (default false)"),
      ];
      outputs = [
        out("parts", "array<string>", "Array of split content parts"),
        out("part_count", "number", "Number of parts produced"),
        out("strategy", "string", "Strategy used for splitting"),
        out("avg_part_size", "number", "Average character length of the parts"),
        out("total_chars", "number", "Total character count of input content"),
      ];
      constraints = [
        "chunk_size must be >= 1 when strategy is lines, chars, or words",
        "delimiter strategy splits on exact string match, not regex",
        "max_parts 0 means no limit; applies after filter_empty",
      ];
      exampleInput = "{\"content\": \"Line 1\\nLine 2\\nLine 3\\nLine 4\\nLine 5\\nLine 6\", \"strategy\": \"lines\", \"chunk_size\": 2, \"filter_empty\": true}";
      exampleOutput = "{\"parts\": [\"Line 1\\nLine 2\", \"Line 3\\nLine 4\", \"Line 5\\nLine 6\"], \"part_count\": 3, \"strategy\": \"lines\", \"avg_part_size\": 13, \"total_chars\": 41}";
    },
    // ── Validation / Safety ──────────────────────────────────────────────────
    {
      name = "validate_input";
      description = "Validate a string value against an expected type and optional constraints. Supports 18 type formats including email, URL, UUID, date, IP, hex, and base64. Applies length, range, pattern, and allowed-values checks. Returns structured errors with normalized value for downstream use.";
      category = "Validation";
      inputs = [
        inp("content", "string", true, "The value to validate. Pass as a string regardless of the semantic type being checked (e.g. \"42\" for a number check, \"alice@example.com\" for an email check). Also accepts legacy key 'value'."),
        inp("type", "string", true, "Expected type/format. Accepted values: string, number, integer, boolean, email, url, uuid, date, datetime, json, ip, ipv4, ipv6, alphanumeric, hex, base64. Also accepts legacy key 'expected_type'."),
        inp("min_length", "number", false, "Minimum character length for the value. Applied after type check. Null or absent disables this check."),
        inp("max_length", "number", false, "Maximum character length for the value. Applied after type check. Null or absent disables this check."),
        inp("min_value", "number", false, "Minimum numeric value. Only applied when type is number or integer. Null or absent disables this check."),
        inp("max_value", "number", false, "Maximum numeric value. Only applied when type is number or integer. Null or absent disables this check."),
        inp("pattern", "string", false, "Substring or simple pattern the value must contain. Applied as a literal substring check. Null or absent disables this check."),
        inp("allowed_values", "array<string>", false, "Whitelist of permitted values. If provided and non-empty, the value must exactly match one of the listed strings. Null or absent disables this check."),
        inp("required", "boolean", false, "When true (default), empty or whitespace-only values produce a required-field error. When false, empty values skip all type and constraint checks."),
        inp("error_message", "string", false, "Custom error message to use for all validation failures instead of the generated messages. Useful for user-facing validation flows."),
      ];
      outputs = [
        out("is_valid", "boolean", "True if the value passed all enabled checks; false if any check failed."),
        out("type", "string", "The type/format that was checked against."),
        out("errors", "array<string>", "Array of error message strings describing each failed check."),
        out("value", "string", "The original input value as provided."),
        out("normalized_value", "string", "The value after leading/trailing whitespace trimming — the form used for all checks."),
      ];
      constraints = [
        "type must be one of: string, number, integer, boolean, email, url, uuid, date, datetime, json, ip, ipv4, ipv6, alphanumeric, hex, base64",
        "min_value and max_value are only enforced when type is number or integer",
        "pattern is a literal substring check, not a regex",
        "allowed_values check requires exact match against normalized_value",
        "required defaults to true; empty values bypass all other checks when required=false",
        "Also accepts legacy input key 'value' instead of 'content', and 'expected_type' instead of 'type'",
      ];
      exampleInput = "{\"content\": \"alice@example.com\", \"type\": \"email\", \"min_length\": 5, \"max_length\": 100, \"required\": true}";
      exampleOutput = "{\"is_valid\": true, \"type\": \"email\", \"errors\": [], \"value\": \"alice@example.com\", \"normalized_value\": \"alice@example.com\"}";
    },
    {
      name = "validate_schema";
      description = "Validate a JSON object or array against a JSON Schema definition. Supports required fields, type checking, property constraints (minimum, maximum, minLength, maxLength, pattern), enum validation, strict mode (no additional properties), type coercion hints, and detailed per-field error reporting with path and expected/actual values.";
      category = "Validation";
      inputs = [
        inp("content", "string", true, "The JSON string to validate. Must be a valid JSON object or array. Also accepts legacy key 'json'."),
        inp("schema", "string", true, "JSON Schema definition as a JSON string. Supported keywords: type, required (array), properties (with per-property: type, enum, minimum, maximum, minLength, maxLength, pattern, nullable), additionalProperties."),
        inp("strict_mode", "boolean", false, "When true, no additional properties beyond those defined in 'properties' are allowed. Equivalent to setting additionalProperties to false in the schema. Default: false."),
        inp("allow_extra_fields", "boolean", false, "When false, fields present in content but not in schema properties produce errors. Overridden by strict_mode. Default: true."),
        inp("coerce_types", "boolean", false, "When true, numeric strings like '42' are accepted for number-type fields without error. Default: false."),
        inp("detailed_errors", "boolean", false, "When true (default), errors include path, message, expected, and actual fields. When false, only the message is provided."),
        inp("max_errors", "number", false, "Maximum number of validation errors to collect before stopping. Prevents excessive output for large objects. Default: 20."),
      ];
      outputs = [
        out("is_valid", "boolean", "True if the JSON satisfies all schema constraints; false if any validation error was found."),
        out("errors", "array<object>", "Array of error objects, each with: path (dot-notation field path, e.g. '$.name'), message (description), expected (what was required), actual (what was found)."),
        out("error_count", "number", "Total number of validation errors collected (capped at max_errors)."),
        out("schema_fields_checked", "number", "Number of properties defined in the schema's 'properties' block that were checked."),
      ];
      constraints = [
        "schema must be a valid JSON object string",
        "Supported schema keywords: type, required, properties, enum, minimum, maximum, minLength, maxLength, pattern, nullable",
        "strict_mode overrides allow_extra_fields",
        "error_count is capped at max_errors; actual errors may be higher",
        "Pattern check in schema properties uses literal substring matching",
        "Also accepts legacy input key 'json' instead of 'content'",
      ];
      exampleInput = "{\"content\": \"{\\\"name\\\": \\\"Alice\\\", \\\"age\\\": 30, \\\"role\\\": \\\"admin\\\"}\", \"schema\": \"{\\\"required\\\": [\\\"name\\\", \\\"age\\\"], \\\"properties\\\": {\\\"name\\\": {\\\"type\\\": \\\"string\\\", \\\"minLength\\\": 1}, \\\"age\\\": {\\\"type\\\": \\\"number\\\", \\\"minimum\\\": 0, \\\"maximum\\\": 150}, \\\"role\\\": {\\\"type\\\": \\\"string\\\", \\\"enum\\\": [\\\"admin\\\", \\\"user\\\", \\\"guest\\\"]}}}\", \"strict_mode\": false, \"allow_extra_fields\": true, \"detailed_errors\": true, \"max_errors\": 20}";
      exampleOutput = "{\"is_valid\": true, \"errors\": [], \"error_count\": 0, \"schema_fields_checked\": 3}";
    },
    {
      name = "sanitize_input";
      description = "Remove or neutralize dangerous content from text using one or more sanitization modes. Supports XSS (strips script tags and HTML), SQL injection escaping, path traversal removal, HTML entity encoding, and Markdown special-character escaping. Preserves or collapses whitespace, strips null bytes, normalizes Unicode diacritics, and truncates to a maximum length.";
      category = "Validation";
      inputs = [
        inp("content", "string", true, "The raw text content to sanitize. Can be user input, scraped text, form data, or any untrusted string. Also accepts legacy key 'text'."),
        inp("mode", "string", false, "Sanitization strategy: xss (strip script blocks and HTML tags), sql (escape single quotes, backslashes, semicolons), path (remove ../  traversal sequences), html (encode &<>\\\"' as HTML entities), markdown (escape * _ ` # [ ] special chars), all (apply all modes in sequence). Default: xss."),
        inp("allowed_tags", "string", false, "Comma-separated HTML tag names to preserve when mode is xss or html (e.g. 'b,i,strong,em'). All other tags are stripped. Null or empty removes all tags. Default: null."),
        inp("preserve_formatting", "boolean", false, "When false (default), consecutive whitespace is collapsed to a single space and leading/trailing whitespace is trimmed after sanitization. When true, original whitespace structure is preserved."),
        inp("max_length", "number", false, "Truncate sanitized output to this many characters. 0 or null disables truncation. Applied after all other operations. Default: 0."),
        inp("strip_nullbytes", "boolean", false, "When true (default), removes null byte characters (\\u0000) which can bypass security filters. Default: true."),
        inp("normalize_unicode", "boolean", false, "When true, replaces common accented Latin characters with ASCII base forms (e.g. é→e, ñ→n, ü→u). Useful for normalized comparison or storage. Default: false."),
      ];
      outputs = [
        out("content", "string", "The sanitized output text after all enabled operations."),
        out("original_length", "number", "Character count of the input text before sanitization."),
        out("sanitized_length", "number", "Character count of the sanitized output."),
        out("chars_removed", "number", "Difference between original_length and sanitized_length (characters removed or neutralized)."),
        out("operations_applied", "array<string>", "List of sanitization operation names that were applied, in order."),
      ];
      constraints = [
        "mode must be one of: xss, sql, path, html, markdown, all",
        "allowed_tags is only respected when mode is xss or html; strip entire tags without inner text when not in allowed list",
        "mode=all applies all modes in this order: xss, sql, path, html, markdown",
        "strip_nullbytes is applied before other operations",
        "max_length truncation is applied last, after all other transformations",
        "Also accepts legacy input key 'text' instead of 'content'",
      ];
      exampleInput = "{\"content\": \"<script>alert('xss')</script> Hello <b>World</b>! ../../../etc/passwd\", \"mode\": \"xss\", \"allowed_tags\": \"b\", \"preserve_formatting\": false, \"strip_nullbytes\": true, \"normalize_unicode\": false, \"max_length\": 0}";
      exampleOutput = "{\"content\": \"Hello <b>World</b>!\", \"original_length\": 70, \"sanitized_length\": 19, \"chars_removed\": 51, \"operations_applied\": [\"xss\", \"strip_nullbytes\"]}";
    },
    {
      name = "enforce_constraints";
      description = "Enforce one or more value constraints on a string, number, or any serialized value. Checks not-empty, not-null, numeric min/max, string min/max length, enum membership, and regex pattern containment. Returns all violations with per-constraint detail. Supports fail-on-first or collect-all error modes for flexible workflow integration.";
      category = "Validation";
      inputs = [
        inp("content", "string", true, "The value to check constraints against. Pass as a string; numeric checks are applied if the value parses as a number. Also accepts legacy keys 'value' or 'constraints'."),
        inp("min_value", "number", false, "Minimum numeric value (inclusive). Only enforced when content parses as a float. Null disables this check."),
        inp("max_value", "number", false, "Maximum numeric value (inclusive). Only enforced when content parses as a float. Null disables this check."),
        inp("min_length", "number", false, "Minimum string character length (inclusive). Applied to the raw content string. Null disables this check."),
        inp("max_length", "number", false, "Maximum string character length (inclusive). Applied to the raw content string. Null disables this check."),
        inp("enum_values", "array<string>", false, "Whitelist of allowed values. Content must exactly match one of the listed strings. Null or empty disables this check."),
        inp("regex_pattern", "string", false, "Substring or pattern the value must contain. Applied as a literal substring match. Null or empty disables this check."),
        inp("not_empty", "boolean", false, "When true, content that is empty or whitespace-only produces a violation. Default: false."),
        inp("not_null", "boolean", false, "When true, content that is empty or the literal string 'null' produces a violation. Default: false."),
        inp("error_mode", "string", false, "How to handle multiple constraint failures: fail_first (return after the first violation, default) or collect_all (check all constraints and return all violations)."),
        inp("custom_message", "string", false, "Custom violation message used for all constraint failures instead of the auto-generated messages. Useful for user-facing error displays."),
      ];
      outputs = [
        out("is_valid", "boolean", "True if all enabled constraints passed; false if any violation was found."),
        out("value", "string", "The original content value as provided."),
        out("violations", "array<object>", "Array of violation objects, each with: constraint (the constraint name that failed) and message (description of the violation)."),
        out("violation_count", "number", "Number of violations found (1 when error_mode is fail_first and a violation occurred)."),
      ];
      constraints = [
        "min_value and max_value only apply when content parses as a float",
        "not_null checks for empty string or literal 'null'",
        "regex_pattern is a literal substring check, not a full regex",
        "fail_first mode stops after the first violation — violation_count will be at most 1",
        "collect_all mode checks every constraint — violation_count reflects the total",
        "Also accepts legacy input key 'value' instead of 'content'",
        "Legacy: if a 'constraints' JSON object is provided in input and no direct constraint params are found, it is parsed for minLength/maxLength/min/max/pattern keys",
      ];
      exampleInput = "{\"content\": \"25\", \"min_value\": 18, \"max_value\": 65, \"min_length\": 1, \"max_length\": 10, \"not_empty\": true, \"not_null\": true, \"error_mode\": \"collect_all\"}";
      exampleOutput = "{\"is_valid\": true, \"value\": \"25\", \"violations\": [], \"violation_count\": 0}";
    },
    // ── Formatting ───────────────────────────────────────────────────────────
    {
      name = "format_json";
       description = "Pretty-print, minify, or sort a JSON string. Supports key filtering, depth limiting, configurable indent style and size, and structured output metrics. Designed as the standard JSON formatting step before returning or storing JSON data in an agent pipeline.";
       category = "Formatting";
       inputs = [
         inp("content", "string", true, "JSON string to format. Must be a valid JSON value (object, array, string, number, or boolean). Also accepts legacy key 'json'."),
         inp("mode", "string", false, "Output format mode. One of: pretty (human-readable with indentation), compact (minified, no whitespace), sorted (pretty-printed with keys alphabetically sorted). Default: pretty."),
         inp("indent_size", "number", false, "Number of indent units per nesting level when mode is pretty or sorted. Default: 2."),
         inp("indent_style", "string", false, "Indent character to use. One of: space, tab. Default: space."),
         inp("sort_keys", "boolean", false, "When true, all object keys are sorted alphabetically before formatting. Also triggered when mode is sorted. Default: false."),
         inp("filter_keys", "array", false, "Array of top-level key names to include. All other keys are removed. Example: [\"name\", \"age\"]. Default: null (include all)."),
         inp("max_depth", "number", false, "Maximum nesting depth to include. Objects/arrays beyond this depth are replaced with a placeholder. 0 means no limit. Default: 0."),
         inp("colorize", "boolean", false, "When true, ANSI color escape codes are applied to the output for terminal rendering. Default: false."),
       ];
       outputs = [
         out("content", "string", "The formatted JSON string after all transformations."),
         out("original_length", "number", "Character count of the input content before formatting."),
         out("formatted_length", "number", "Character count of the output content after formatting."),
         out("is_valid", "boolean", "True if the input was valid JSON; false if it was malformed (output is best-effort)."),
         out("key_count", "number", "Number of top-level keys if the root is an object; 0 for arrays or primitives."),
       ];
       constraints = [
         "content must be non-empty",
         "mode must be one of: pretty, compact, sorted",
         "indent_style must be one of: space, tab",
         "filter_keys applies only to top-level keys of the root object",
         "colorize output is not valid JSON — use only for display, not downstream parsing",
         "Also accepts legacy input key 'json' instead of 'content'",
       ];
       exampleInput = "{\"content\": \"{\\\"name\\\":\\\"Alice\\\",\\\"age\\\":30,\\\"city\\\":\\\"London\\\"}\", \"mode\": \"sorted\", \"indent_size\": 2}";
       exampleOutput = "{\"content\": \"{\\\"age\\\": 30, \\\"city\\\": \\\"London\\\", \\\"name\\\": \\\"Alice\\\"}\", \"original_length\": 41, \"formatted_length\": 46, \"is_valid\": true, \"key_count\": 3}";
     },
     {
       name = "format_table";
       description = "Render a JSON array of objects as a formatted table. Supports multiple border styles (simple, ASCII, Markdown, CSV, none), per-column alignment, column width limits with truncation, optional row numbers, custom null display, and configurable header separators.";
       category = "Formatting";
       inputs = [
         inp("content", "string", true, "JSON array of objects to render as a table. Each object becomes a row; keys become column headers. Also accepts legacy key 'json'."),
         inp("columns", "array", false, "Ordered list of column names to include. Columns not listed are excluded. Default: all keys from the first row."),
         inp("border_style", "string", false, "Table border/formatting style. One of: simple (pipe-padded), ascii (box-drawing), markdown (GitHub pipe table), csv (comma-separated, no borders), none (space-separated). Default: simple."),
         inp("alignment", "object", false, "Per-column text alignment. Map of column name to: left, right, or center. Example: {\"score\": \"right\", \"name\": \"left\"}."),
         inp("max_column_width", "number", false, "Maximum character width of any single cell. Longer values are truncated and truncate_suffix is appended. 0 means no limit. Default: 50."),
         inp("truncate_suffix", "string", false, "String appended to cells truncated by max_column_width. Default: ..."),
         inp("show_row_numbers", "boolean", false, "When true, a leading # column is added with 1-based row numbers. Default: false."),
         inp("null_display", "string", false, "String to display for null or missing cell values. Default: empty string."),
         inp("header_separator", "boolean", false, "When true, a separator row is rendered between the header and data rows. Default: true."),
       ];
       outputs = [
         out("table", "string", "The formatted table as a multi-line string."),
         out("row_count", "number", "Number of data rows in the table (excluding header)."),
         out("column_count", "number", "Number of columns rendered."),
         out("columns_used", "array", "Ordered array of column names that were rendered."),
       ];
       constraints = [
         "content must be a JSON array of objects",
         "border_style must be one of: simple, ascii, markdown, csv, none",
         "alignment values must be one of: left, right, center",
         "max_column_width of 0 disables truncation",
         "Also accepts legacy input key 'json' instead of 'content'",
       ];
       exampleInput = "{\"content\": \"[{\\\"name\\\":\\\"Alice\\\",\\\"score\\\":95},{\\\"name\\\":\\\"Bob\\\",\\\"score\\\":87}]\", \"border_style\": \"markdown\", \"show_row_numbers\": true}";
       exampleOutput = "{\"table\": \"| # | name  | score |\\n|---|-------|-------|\\n| 1 | Alice | 95    |\\n| 2 | Bob   | 87    |\", \"row_count\": 2, \"column_count\": 3, \"columns_used\": [\"#\", \"name\", \"score\"]}";
     },
     {
       name = "format_markdown";
       description = "Convert a JSON object, array, or string into well-structured Markdown. Supports multiple rendering modes (auto-detected or explicit): definition list, table, heading, code block, or unordered/ordered/task list. Supports heading levels, linked fields, and item limits.";
       category = "Formatting";
       inputs = [
         inp("content", "string", true, "Input content to convert. Can be a JSON object (for definition or table mode), a JSON array (for list or table mode), or a plain string. Also accepts legacy key 'json'."),
         inp("mode", "string", false, "Rendering mode. One of: auto (inferred from content shape), list (array items as bullet points), table (array of objects as Markdown table), heading (wrap content in a heading), code (wrap in fenced code block), definition (object key-value pairs as bold-key list). Default: auto."),
         inp("heading_level", "number", false, "Heading level for heading mode and section headings. Range 1-6. Default: 2."),
         inp("include_toc", "boolean", false, "When true, a Table of Contents is prepended based on detected headings. Default: false."),
         inp("link_fields", "object", false, "Map of display field to URL field for generating Markdown links. Example: {\"title\": \"url\"} renders [title value](url value). Default: null."),
         inp("code_language", "string", false, "Language identifier for fenced code blocks in code mode. Example: json, python. Default: empty."),
         inp("list_style", "string", false, "List item style for list mode. One of: unordered (- prefix), ordered (1. 2. prefix), task (- [ ] checkbox). Default: unordered."),
         inp("max_items", "number", false, "Maximum items to render in list or table mode. 0 means no limit. Default: 0."),
       ];
       outputs = [
         out("content", "string", "The rendered Markdown string."),
         out("char_count", "number", "Character count of the rendered Markdown output."),
         out("mode_used", "string", "The rendering mode that was applied (useful when mode was auto)."),
       ];
       constraints = [
         "mode must be one of: auto, list, table, heading, code, definition",
         "heading_level must be between 1 and 6",
         "list_style must be one of: unordered, ordered, task",
         "link_fields applies only in list and table modes",
         "Also accepts legacy input key 'json' instead of 'content'",
       ];
       exampleInput = "{\"content\": \"[{\\\"title\\\":\\\"API Guide\\\",\\\"url\\\":\\\"https://docs.example.com\\\"},{\\\"title\\\":\\\"SDK Reference\\\",\\\"url\\\":\\\"https://sdk.example.com\\\"}]\", \"mode\": \"list\", \"list_style\": \"ordered\", \"link_fields\": {\"title\": \"url\"}}";
        exampleOutput = "{\"content\": \"1. [API Guide](https://docs.example.com)\\n2. [SDK Reference](https://sdk.example.com)\", \"char_count\": 84, \"mode_used\": \"list\"}";
     },
     {
       name = "format_text";
       description = "Apply case transformations, word-wrapping, line indentation, and alignment to plain text. Supports 9 case styles (including camelCase, snake_case, PascalCase), configurable wrap width with word or character break strategy, justification modes, paragraph break preservation, and extra whitespace stripping.";
       category = "Formatting";
       inputs = [
         inp("content", "string", true, "Plain text to format. Multi-line input is supported. Also accepts legacy key 'text'."),
         inp("case_style", "string", false, "Case transformation to apply. One of: none, lowercase, uppercase, title_case, sentence_case, camel_case, snake_case, kebab_case, pascal_case. Default: none."),
         inp("width", "number", false, "Maximum line width in characters for word-wrapping. 0 means no wrapping. Default: 0."),
         inp("indent", "number", false, "Number of spaces to prepend to each line. Applied after wrapping. Default: 0."),
         inp("alignment", "string", false, "Text alignment within the specified width. One of: left, right, center, justify. Only applies when width > 0. Default: left."),
         inp("preserve_paragraph_breaks", "boolean", false, "When true, double newlines (paragraph breaks) are preserved during wrapping. Default: true."),
         inp("break_strategy", "string", false, "Line-breaking strategy when wrapping. One of: word (break at word boundaries), char (break at exact character limit). Default: word."),
         inp("strip_extra_whitespace", "boolean", false, "When true, collapses multiple consecutive whitespace characters into a single space before other transformations. Default: false."),
       ];
       outputs = [
         out("content", "string", "The formatted text after all transformations."),
         out("char_count", "number", "Character count of the formatted output."),
         out("line_count", "number", "Number of lines in the formatted output."),
         out("case_style_applied", "string", "The case_style value that was applied."),
       ];
       constraints = [
         "case_style must be one of: none, lowercase, uppercase, title_case, sentence_case, camel_case, snake_case, kebab_case, pascal_case",
         "alignment must be one of: left, right, center, justify",
         "alignment requires width > 0 to take effect",
         "break_strategy must be one of: word, char",
         "Also accepts legacy input key 'text' instead of 'content'",
       ];
       exampleInput = "{\"content\": \"hello world this is agent layer\", \"case_style\": \"title_case\", \"width\": 20, \"alignment\": \"left\"}";
       exampleOutput = "{\"content\": \"Hello World This Is\\nAgent Layer\", \"char_count\": 31, \"line_count\": 2, \"case_style_applied\": \"title_case\"}";
     },
     // ── Decision ─────────────────────────────────────────────────────────────
     {
       name = "evaluate_condition";
       description = "Evaluate one or more conditions using comparison operators with support for multi-condition arrays and logical combinators (AND/OR/NOT). Returns a boolean result, per-condition detail trace, and pass/fail counts. Use for branching logic, data validation gates, and conditional routing in agent pipelines.";
       category = "Decision";
       inputs = [
         inp("value", "string", false, "Value for single-condition mode. Compared against threshold using operator. Required if conditions is not provided."),
         inp("operator", "string", false, "Comparison operator for single-condition mode. One of: eq, neq, gt, gte, lt, lte, contains, starts_with, ends_with, is_null, is_not_null, is_empty, matches_regex. Default: eq."),
         inp("threshold", "string", false, "Comparison target for single-condition mode. Required if conditions is not provided."),
         inp("conditions", "array", false, "Array of condition objects for multi-condition mode. Each: {value: string, operator: string, threshold: string}. Overrides single-condition fields when provided."),
         inp("logical_operator", "string", false, "How multiple conditions are combined. One of: AND (all must pass), OR (any must pass), NOT (negates the first condition result). Default: AND."),
         inp("type", "string", false, "Value type hint for comparison coercion. One of: auto (infer from value), string, number, boolean. Default: auto."),
         inp("case_sensitive", "boolean", false, "When false, string comparisons are case-insensitive. Default: false."),
       ];
       outputs = [
         out("result", "boolean", "Final evaluated result after applying logical_operator across all conditions."),
         out("conditions_evaluated", "number", "Total number of individual conditions that were evaluated."),
         out("conditions_passed", "number", "Number of individual conditions that evaluated to true."),
         out("logical_operator", "string", "The logical operator used to combine results."),
         out("details", "array", "Per-condition trace: [{value, operator, threshold, result}]."),
       ];
       constraints = [
         "Either (value + operator + threshold) or conditions must be provided",
         "operator must be one of: eq, neq, gt, gte, lt, lte, contains, starts_with, ends_with, is_null, is_not_null, is_empty, matches_regex",
         "logical_operator must be one of: AND, OR, NOT",
         "NOT applies only to the first condition result",
         "Numeric operators auto-parse both values as floats when possible",
       ];
       exampleInput = "{\"conditions\": [{\"value\": \"95\", \"operator\": \"gte\", \"threshold\": \"90\"}, {\"value\": \"active\", \"operator\": \"eq\", \"threshold\": \"active\"}], \"logical_operator\": \"AND\"}";
       exampleOutput = "{\"result\": true, \"conditions_evaluated\": 2, \"conditions_passed\": 2, \"logical_operator\": \"AND\", \"details\": [{\"value\": \"95\", \"operator\": \"gte\", \"threshold\": \"90\", \"result\": true}, {\"value\": \"active\", \"operator\": \"eq\", \"threshold\": \"active\", \"result\": true}]}";
     },
     {
       name = "select_value";
       description = "Select and return a value based on a boolean condition or a multi-case switch. Supports variable substitution in conditions, type coercion of the output, null handling strategies, and an ordered case array for complex branching. Designed as the core value-selection primitive in conditional agent logic.";
       category = "Decision";
       inputs = [
         inp("condition", "string", true, "Boolean condition string to evaluate. Accepts 'true'/'false' literals or any string that resolves to truthy/falsy after variable substitution."),
         inp("value_if_true", "string", true, "Value to return when condition evaluates to true. Ignored when a matching case is found."),
         inp("value_if_false", "string", true, "Value to return when condition evaluates to false and no case matches. Acts as the default fallback."),
         inp("variables", "object", false, "Map of variable names to values for text substitution in the condition string. Example: {\"score\": \"95\"} replaces 'score' in condition before evaluation."),
         inp("cases", "array", false, "Ordered list of condition-value pairs for multi-branch selection. Each entry: {condition: string, value: string}. First matching case wins. Falls back to value_if_false if no case matches."),
         inp("return_type", "string", false, "Type coercion to apply to the selected value. One of: string, number, boolean, json. Default: string."),
         inp("null_handling", "string", false, "Behavior when the selected value is empty. One of: empty_string (return empty), null (return JSON null), error (return EXECUTION_ERROR). Default: empty_string."),
       ];
       outputs = [
         out("selected_value", "string", "The value that was selected and returned after type coercion."),
         out("condition_result", "boolean", "Whether the primary condition evaluated to true."),
         out("branch_taken", "string", "Which branch was taken: 'true', 'false', or the 0-based case index as a string."),
         out("return_type", "string", "The return_type that was applied to the output value."),
       ];
       constraints = [
         "condition, value_if_true, and value_if_false are all required",
         "return_type must be one of: string, number, boolean, json",
         "null_handling must be one of: empty_string, null, error",
         "cases array is evaluated in order; first match wins",
         "variables substitution is a simple text replacement, not expression evaluation",
       ];
       exampleInput = "{\"condition\": \"score\", \"variables\": {\"score\": \"true\"}, \"value_if_true\": \"Premium\", \"value_if_false\": \"Free\", \"return_type\": \"string\"}";
       exampleOutput = "{\"selected_value\": \"Premium\", \"condition_result\": true, \"branch_taken\": \"true\", \"return_type\": \"string\"}";
     },
     {
       name = "rank_by_field";
       description = "Sort and rank a JSON array by one or more fields with configurable ordering, tie-breaking, dense rank support, percentile annotation, and result limiting. Each item is annotated with a _rank and optionally a _percentile value. Use for leaderboards, priority queues, scoring systems, and ordered output in agent workflows.";
       category = "Decision";
       inputs = [
         inp("content", "string", true, "JSON array of objects to rank. Also accepts legacy key 'json'."),
         inp("rank_fields", "array", false, "Ordered array of sort field specs. Each entry: {field: string, order: 'asc'|'desc'}. First field is the primary sort key; subsequent fields are secondary. Example: [{\"field\": \"score\", \"order\": \"desc\"}, {\"field\": \"name\", \"order\": \"asc\"}]."),
         inp("field", "string", false, "Primary rank field name (simple mode, used when rank_fields is not provided)."),
         inp("order", "string", false, "Sort order for simple mode. One of: asc (lowest first), desc (highest first). Default: desc."),
         inp("tie_break_by", "string", false, "Secondary field name for tie-breaking when two items have equal primary field values. Compared lexicographically. Default: null."),
         inp("include_rank", "boolean", false, "When true, a _rank field (1-based integer) is added to each output item. Default: true."),
         inp("include_percentile", "boolean", false, "When true, a _percentile field (0-100 integer) is added showing relative rank position. Default: false."),
         inp("dense_rank", "boolean", false, "When true, items with equal values receive the same rank and the next rank increments by 1 (not by count of tied items). Default: false."),
         inp("top_n", "number", false, "If set, only the top N items are returned after sorting. 0 means return all. Default: 0."),
         inp("normalize_scores", "boolean", false, "When true, numeric rank field values are min-max normalized to 0-1 range and stored in _normalized_score. Default: false."),
       ];
       outputs = [
         out("result", "array", "Ranked array of objects, each annotated with _rank and optionally _percentile."),
         out("ranked_count", "number", "Number of items in the result."),
         out("rank_fields_used", "array", "Array of field names that were used for ranking, in priority order."),
       ];
       constraints = [
         "content must be a JSON array of objects",
         "Either rank_fields or field must be provided",
         "order must be one of: asc, desc",
         "dense_rank only affects the _rank annotation, not the sort order",
         "Also accepts legacy input key 'json' instead of 'content'",
       ];
       exampleInput = "{\"content\": \"[{\\\"name\\\":\\\"Alice\\\",\\\"score\\\":92},{\\\"name\\\":\\\"Bob\\\",\\\"score\\\":78},{\\\"name\\\":\\\"Charlie\\\",\\\"score\\\":92}]\", \"rank_fields\": [{\"field\": \"score\", \"order\": \"desc\"}, {\"field\": \"name\", \"order\": \"asc\"}], \"include_percentile\": true, \"dense_rank\": true}";
        exampleOutput = "{\"result\": [{\"name\": \"Alice\", \"score\": 92, \"_rank\": 1, \"_percentile\": 100}, {\"name\": \"Charlie\", \"score\": 92, \"_rank\": 1, \"_percentile\": 66}, {\"name\": \"Bob\", \"score\": 78, \"_rank\": 3, \"_percentile\": 33}], \"ranked_count\": 3, \"rank_fields_used\": [\"score\", \"name\"]}";
     },
     // ── Meta ─────────────────────────────────────────────────────────────────
     {
       name = "list_capabilities";
       description = "Return the full registry of available capabilities with optional filtering by category or search term, configurable sorting, and optional inline schema inclusion. Designed as the discovery endpoint for agents that need to self-direct capability selection before executing a workflow.";
       category = "Meta";
       inputs = [
         inp("category", "string", false, "Filter results to capabilities in this category only. Case-sensitive. Example: Formatting, Decision, Web, Documents, Compute. Default: null (all categories)."),
         inp("search", "string", false, "Search string matched case-insensitively against capability name and description. Combined with category filter using AND logic. Default: null (no search filter)."),
         inp("include_schemas", "boolean", false, "When true, each capability in the result includes its full inputs and outputs schema arrays. Increases response size significantly. Default: false."),
         inp("sort_by", "string", false, "Sort order for the result list. One of: category (group by category then alphabetical), name (global alphabetical), alphabetical (same as name). Default: category."),
       ];
       outputs = [
         out("capabilities", "array", "Array of capability records. When include_schemas is false, each record contains name, description, and category. When true, inputs and outputs are also included."),
         out("total_count", "number", "Total number of capabilities in the registry before any filtering."),
         out("filtered_count", "number", "Number of capabilities returned after applying category and search filters."),
         out("categories", "array", "Distinct list of all category names present in the registry, sorted alphabetically."),
       ];
       constraints = [
         "sort_by must be one of: category, name, alphabetical",
         "search is a case-insensitive substring match against name and description",
         "include_schemas: true significantly increases response payload size",
       ];
       exampleInput = "{\"category\": \"Compute\", \"include_schemas\": false, \"sort_by\": \"name\"}";
        exampleOutput = "{\"capabilities\": [{\"name\": \"aggregate_data\", \"description\": \"...\", \"category\": \"Compute\"}, {\"name\": \"compare_values\", \"description\": \"...\", \"category\": \"Compute\"}], \"total_count\": 42, \"filtered_count\": 4, \"categories\": [\"Compute\", \"Data\", \"Decision\", \"Documents\", \"Files\", \"Formatting\", \"Meta\", \"Search\", \"Storage\", \"Transform\", \"Validation\", \"Web\"]}";
     },
     {
       name = "describe_capability";
       description = "Return full metadata for a single capability by name, including its complete input/output schema, constraints, and usage examples. Optionally includes related capability suggestions. Designed as the introspection endpoint for agents that need to understand a capability's full contract before calling it.";
       category = "Meta";
       inputs = [
         inp("name", "string", true, "Exact name of the capability to describe. Case-sensitive. Example: fetch_url, parse_json, rank_by_field."),
         inp("include_examples", "boolean", false, "When true, the response includes exampleInput and exampleOutput fields. Default: true."),
         inp("include_constraints", "boolean", false, "When true, the response includes the constraints array listing edge cases and validation rules. Default: true."),
         inp("include_related", "boolean", false, "When true, the response includes a related_capabilities array of up to 3 capability names in the same category. Default: false."),
       ];
       outputs = [
         out("capability", "object", "Full capability metadata: name, description, category, inputs (array), outputs (array), constraints (array), exampleInput, exampleOutput."),
         out("related_capabilities", "array", "Up to 3 capability names from the same category (only present when include_related is true)."),
         out("found", "boolean", "True if a capability with the given name exists; false if not found."),
       ];
       constraints = [
         "name must exactly match a registered capability name (case-sensitive)",
         "found: false is returned instead of an error when the name is not recognized",
         "related_capabilities excludes the queried capability itself",
       ];
       exampleInput = "{\"name\": \"rank_by_field\", \"include_examples\": true, \"include_constraints\": true, \"include_related\": true}";
       exampleOutput = "{\"capability\": {\"name\": \"rank_by_field\", \"description\": \"...\", \"category\": \"Decision\", \"inputs\": [...], \"outputs\": [...], \"constraints\": [...], \"exampleInput\": \"...\", \"exampleOutput\": \"...\"}, \"related_capabilities\": [\"evaluate_condition\", \"select_value\"], \"found\": true}";
     },
  ];

  // ── public registry API ────────────────────────────────────────────────────
  // These functions operate directly on the static allCapabilities() array.
  // This avoids any EOP-cached Map state that could be stale after upgrades.

  public func list(categoryFilter : ?Text) : [Types.CapabilityInfo] {
    let caps = allCapabilities();
    switch (categoryFilter) {
      case null { caps };
      case (?cat) {
        caps.filter(func(c : Types.CapabilityInfo) : Bool = Text.equal(c.category, cat));
      };
    };
  };

  public func describe(name : Text) : ?Types.CapabilityInfo {
    allCapabilities().find(func(c : Types.CapabilityInfo) : Bool = Text.equal(c.name, name));
  };

  public func validateInput(
    info : Types.CapabilityInfo,
    inputJson : Text,
  ) : ?Text {
    let trimmed = inputJson.trimStart(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
    if (trimmed.size() == 0) return ?"Input JSON is empty";
    if (not trimmed.startsWith(#text "{")) return ?"Input must be a JSON object";
    for (field in info.inputs.values()) {
      if (field.required) {
        let needle = "\"" # field.key # "\"";
        if (not inputJson.contains(#text needle)) {
          return ?("Missing required field: " # field.key);
        };
      };
    };
    null;
  };

  // ── JSON text helpers ──────────────────────────────────────────────────────

  // Extract a top-level key value from a JSON object text.
  // Returns the raw value token (string value has quotes stripped).
  func jsonGetStr(json : Text, key : Text) : ?Text {
    let needle = "\"" # key # "\"";
    let parts = json.split(#text needle).toArray();
    if (parts.size() < 2) return null;
    let after = parts[1].trimStart(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
    if (not after.startsWith(#text ":")) return null;
    let afterColon = after.trimStart(#text ":").trimStart(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
    if (afterColon.startsWith(#text "\"")) {
      let inner = afterColon.trimStart(#text "\"");
      let innerParts = inner.split(#text "\"").toArray();
      if (innerParts.size() == 0) return null;
      ?innerParts[0];
    } else {
      var result = "";
      var done = false;
      for (c in afterColon.toIter()) {
        if (not done) {
          if (c == ',' or c == '}' or c == ']' or c == '\n') {
            done := true;
          } else {
            result := result # c.toText();
          };
        };
      };
      ?(result.trimEnd(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\r' })));
    };
  };

  func jsonGetStrDefault(json : Text, key : Text, default : Text) : Text {
    switch (jsonGetStr(json, key)) { case (?v) v; case null default };
  };

  func looksLikeArray(s : Text) : Bool {
    s.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "[");
  };

  // Balanced split of a JSON array "[a, b, ...]" into individual item strings
  func splitJsonArray(json : Text) : [Text] {
    let trimmed = json.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
    if (not trimmed.startsWith(#text "[")) return [];
    let inner = trimmed.trimStart(#text "[").trimEnd(#text "]").trim(#predicate(func(c : Char) { c == ' ' }));
    if (inner.size() == 0) return [];
    let items = List.empty<Text>();
    var depth = 0;
    var inStr = false;
    var prevBackslash = false;
    var current = "";
    for (c in inner.toIter()) {
      if (inStr) {
        current := current # c.toText();
        if (prevBackslash) { prevBackslash := false }
        else if (c == '\u{5C}') { prevBackslash := true }
        else if (c == '\u{22}') { inStr := false };
      } else if (c == '\u{22}') {
        inStr := true;
        current := current # c.toText();
      } else if (c == '{' or c == '[') {
        depth += 1;
        current := current # c.toText();
      } else if (c == '}' or c == ']') {
        depth -= 1;
        current := current # c.toText();
      } else if (c == ',' and depth == 0) {
        items.add(current.trim(#predicate(func(c2 : Char) { c2 == ' ' or c2 == '\t' or c2 == '\n' })));
        current := "";
      } else {
        current := current # c.toText();
      };
    };
    let last = current.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' }));
    if (last.size() > 0) items.add(last);
    items.toArray();
  };

  // Get top-level keys from a flat JSON object text
  func jsonKeys(json : Text) : [Text] {
    let keys = List.empty<Text>();
    let trimmed = json.trim(#predicate(func(c : Char) { c == ' ' }));
    if (not trimmed.startsWith(#text "{")) return [];
    let inner = trimmed.trimStart(#text "{").trimEnd(#text "}");
    var inKey = false;
    var inValue = false;
    var inStr = false;
    var depth = 0;
    var prevBackslash = false;
    var current = "";
    var afterColon = false;
    for (c in inner.toIter()) {
      if (inStr) {
        if (prevBackslash) {
          if (not afterColon) current := current # c.toText();
          prevBackslash := false;
        } else if (c == '\u{5C}') {
          prevBackslash := true;
          if (not afterColon) current := current # c.toText();
        } else if (c == '\u{22}') {
          inStr := false;
          if (inKey) {
            keys.add(current);
            current := "";
            inKey := false;
            afterColon := false;
          };
        } else {
          if (not afterColon) current := current # c.toText();
        };
      } else if (c == '\u{22}' and depth == 0 and not afterColon) {
        inStr := true;
        inKey := true;
        current := "";
      } else if (c == ':' and not inStr and depth == 0) {
        afterColon := true;
        inValue := true;
        depth := 0;
      } else if (c == '{' or c == '[') {
        depth += 1;
      } else if (c == '}' or c == ']') {
        if (depth > 0) depth -= 1;
      } else if (c == ',' and depth == 0) {
        afterColon := false;
        inValue := false;
      };
    };
    keys.toArray();
  };

  // Parse a simple integer or float from text
  func parseFloat(s : Text) : ?Float {
    let t = s.trim(#predicate(func(c : Char) { c == ' ' }));
    if (t.size() == 0) return null;
    var neg = false;
    var rest = t;
    if (rest.startsWith(#text "-")) {
      neg := true;
      rest := rest.trimStart(#text "-");
    };
    let dotParts = rest.split(#text ".").toArray();
    if (dotParts.size() == 0) return null;
    switch (Nat.fromText(dotParts[0])) {
      case null return null;
      case (?intPart) {
        let intF = intPart.toFloat();
        let frac = if (dotParts.size() >= 2) {
          let fracStr = dotParts[1];
          switch (Nat.fromText(fracStr)) {
            case null 0.0;
            case (?f) f.toFloat() / Float.pow(10.0, fracStr.size().toFloat());
          };
        } else 0.0;
        let result = intF + frac;
        if (neg) ?(-result) else ?result;
      };
    };
  };

  func floatToText(f : Float) : Text {
    let i = Float.floor(f);
    let frac = Float.abs(f - i);
    let iInt = i.toInt();
    if (frac < 0.0001) {
      iInt.toText();
    } else {
      let fracScaled = (frac * 10000.0).toInt();
      iInt.toText() # "." # fracScaled.toText();
    };
  };

  func detectType(s : Text) : Text {
    let t = s.trim(#predicate(func(c : Char) { c == ' ' }));
    if (t.startsWith(#text "\"")) "string"
    else if (t.startsWith(#text "{")) "object"
    else if (t.startsWith(#text "[")) "array"
    else if (t == "true" or t == "false") "boolean"
    else if (t == "null") "null"
    else switch (parseFloat(t)) { case (?_) "number"; case null "unknown" };
  };

  func escapeJson(s : Text) : Text {
    s.replace(#text "\\", "\\\\")
     .replace(#text "\"", "\\\"")
     .replace(#text "\n", "\\n")
     .replace(#text "\r", "\\r")
     .replace(#text "\t", "\\t");
  };

  // Returns the first byte-index of needle in haystack, or -1 if not found
  func textFindIndex(haystack : Text, needle : Text) : Int {
    if (needle.size() == 0) return 0;
    let hChars = haystack.toArray();
    let nChars = needle.toArray();
    let hLen = hChars.size();
    let nLen = nChars.size();
    if (nLen > hLen) return -1;
    var i = 0;
    while (i + nLen <= hLen) {
      var match = true;
      var j = 0;
      while (j < nLen and match) {
        if (hChars[i + j] != nChars[j]) match := false;
        j += 1;
      };
      if (match) return i;
      i += 1;
    };
    -1;
  };

  // ── ExecResult type ────────────────────────────────────────────────────────

  public type ExecResult = {
    success : Bool;
    output : ?Text;
    errorCode : ?Text;
    errorMessage : ?Text;
  };

  func ok(output : Text) : ExecResult =
    { success = true; output = ?output; errorCode = null; errorMessage = null };
  func err(code : Text, msg : Text) : ExecResult =
    { success = false; output = null; errorCode = ?code; errorMessage = ?msg };

  // ── IC management canister type for HTTP outcalls ─────────────────────────

  type HttpMethod = { #get; #post; #head };
  public type TransformFn = shared query TransformArgs -> async HttpRequestResult;
  type HttpRequestArgs = {
    url : Text;
    max_response_bytes : ?Nat64;
    method : HttpMethod;
    headers : [HttpHeader];
    body : ?Blob;
    transform : ?{ function : TransformFn; context : Blob };
    is_replicated : ?Bool;
  };

  // IC management canister actor reference
  let IC = actor "aaaaa-aa" : actor {
    http_request : HttpRequestArgs -> async HttpRequestResult;
  };

  // ── capability handlers ────────────────────────────────────────────────────

  func handle_fetch_url(
    inputJson : Text,
    httpCacheMap : Map.Map<Text, CacheEntry>,
    transformFn : TransformFn,
  ) : async* ExecResult {
    let url = jsonGetStrDefault(inputJson, "url", "");
    if (url.size() == 0) return err("INVALID_INPUT", "url is required");

    let methodStr = jsonGetStrDefault(inputJson, "method", "get");
    let method : HttpMethod = switch (methodStr.toLower()) {
      case "post" #post;
      case "head" #head;
      case _ #get;
    };

    // Optional parameters — parse with explicit trim and fallback
    let ttlSecsStr = jsonGetStrDefault(inputJson, "ttl_seconds", "60");
    let ttlSecs : Int = switch (Int.fromText(ttlSecsStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) if (n > 0) n else 60; case null 60 };
    let ttlNs : Int = ttlSecs * 1_000_000_000;

    let evictionSecsStr = jsonGetStrDefault(inputJson, "eviction_window_seconds", "600");
    let evictionSecs : Int = switch (Int.fromText(evictionSecsStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) if (n > 0) n else 600; case null 600 };
    let evictionWindowNs : Int = evictionSecs * 1_000_000_000;

    let maxRespBytesStr = jsonGetStrDefault(inputJson, "max_response_bytes", "50000");
    let maxRespBytesRaw : Nat = switch (Nat.fromText(maxRespBytesStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 50_000 };
    // Treat 0 as "use default" — passing 0 to IC causes "Header size exceeds specified response size limit 0"
    let maxRespBytesClamped : Nat = if (maxRespBytesRaw == 0) 50_000 else maxRespBytesRaw;
    let maxResponseBytes : Nat64 = Nat.min(maxRespBytesClamped, 200_000).toNat64();

    let bypassCacheStr = jsonGetStrDefault(inputJson, "bypass_cache", "false");
    let bypassCache = bypassCacheStr == "true";

    // Build body for POST
    let bodyStr = jsonGetStrDefault(inputJson, "body", "");
    let bodyBlob : ?Blob = switch (method) {
      case (#post) { if (bodyStr.size() > 0) ?bodyStr.encodeUtf8() else null };
      case _ null;
    };

    // Build cache key — explicit format to ensure consistency
    let cacheKey : Text = switch (method) {
      case (#post) url # ":post:" # bodyStr;
      case (#head) url # ":head";
      case (#get) url # ":get";
    };

    let now = Time.now();

    // Cache lookup FIRST (skip if bypass_cache = true), before eviction
    if (not bypassCache) {
      switch (httpCacheMap.get(cacheKey)) {
        case (?entry) {
          let age = now - entry.fetchedAt;
          if (age >= 0 and age < ttlNs) {
            // Cache hit — update lastAccessedAt and return immediately
            httpCacheMap.add(cacheKey, { entry with lastAccessedAt = now });
            let ttlRemainingNs = ttlNs - age;
            let ttlRemainingSeconds = ttlRemainingNs / 1_000_000_000;
            let withMeta = injectCacheMeta(entry.response, cacheKey, true, ttlRemainingSeconds);
            return ok(withMeta);
          } else {
            // Stale entry — remove it before making a fresh call
            httpCacheMap.remove(cacheKey);
          };
        };
        case null {};
      };
    };

    // Run last-accessed eviction as background cleanup (after lookup, not before)
    evictStale(httpCacheMap, now, evictionWindowNs);

    // Build request headers
    let reqHeaders = List.empty<HttpHeader>();
    reqHeaders.add({ name = "User-Agent"; value = "AgentLayer/1.0" });

    // Right-size cycles: base + per-request-byte + per-response-byte + 10% margin
    let baseCycles : Nat = 21_000_000_000;
    let perRequestByte : Nat = 1_600;
    let perResponseByte : Nat = 800;
    let requestBodySize : Nat = bodyStr.size();
    let expectedResponseSize : Nat = Nat.fromNat64(maxResponseBytes);
    let rawCycles : Nat = baseCycles + (requestBodySize * perRequestByte) + (expectedResponseSize * perResponseByte);
    let cyclesWithMargin : Nat = rawCycles + (rawCycles / 10);

    let reqArgs : HttpRequestArgs = {
      url;
      max_response_bytes = ?maxResponseBytes;
      method;
      headers = reqHeaders.toArray();
      body = bodyBlob;
      transform = ?{ function = transformFn; context = Blob.fromArray([]) };
      is_replicated = ?false;
    };

    try {
      let response = await (with cycles = cyclesWithMargin) IC.http_request(reqArgs);
      let bodyText = switch (response.body.decodeUtf8()) {
        case (?t) t;
        case null "<binary response>";
      };
      // Build response headers JSON
      let headerPairs = List.empty<Text>();
      for (h in response.headers.values()) {
        headerPairs.add("\"" # escapeJson(h.name) # "\": \"" # escapeJson(h.value) # "\"");
      };
      let headersJson = "{" # headerPairs.values().join(", ") # "}";
      // Store the base response (without cache meta) so cache hits can inject fresh TTL values
      let responseJson = "{\"status\": " # response.status.toText() # ", \"body\": \"" # escapeJson(bodyText) # "\", \"headers\": " # headersJson # "}";

      // Write to cache with explicit Text.compare to ensure correct key lookup on next call
      let freshNow = Time.now();
      httpCacheMap.add(cacheKey, { response = responseJson; fetchedAt = freshNow; lastAccessedAt = freshNow });

      ok(injectCacheMeta(responseJson, cacheKey, false, ttlSecs));
    } catch (e) {
      err("HTTP_ERROR", "HTTP outcall failed: " # e.message());
    };
  };

  // Evict entries where lastAccessedAt is older than evictionWindowNs
  func evictStale(cache : Map.Map<Text, CacheEntry>, now : Int, windowNs : Int) {
    // Collect stale keys first to avoid mutating the map during iteration
    let toRemove = List.empty<Text>();
    for ((k, entry) in cache.entries()) {
      let idleTime = now - entry.lastAccessedAt;
      if (idleTime > windowNs) {
        toRemove.add(k);
      };
    };
    for (k in toRemove.values()) {
      cache.remove(k);
    };
  };

  // Inject cache_hit, cache_key, and cache_ttl_remaining_seconds into a JSON response string
  func injectCacheMeta(responseJson : Text, cacheKey : Text, hit : Bool, ttlRemainingSeconds : Int) : Text {
    let hitStr = if (hit) "true" else "false";
    // Strip trailing "}" and append the new fields
    let trimmed = responseJson.trimEnd(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' }));
    let base = switch (trimmed.stripEnd(#text "}")) {
      case (?s) s;
      case null trimmed;
    };
    base # ", \"cache_hit\": " # hitStr # ", \"cache_key\": \"" # escapeJson(cacheKey) # "\", \"cache_ttl_remaining_seconds\": " # ttlRemainingSeconds.toText() # "}";
  };

  func handle_read_document(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content must be non-empty");
    let encodingHint = jsonGetStrDefault(inputJson, "encoding_hint", "utf-8");
    let doStripBom = jsonGetStrDefault(inputJson, "strip_bom", "true") != "false";
    let doDetectLineEndings = jsonGetStrDefault(inputJson, "detect_line_endings", "false") == "true";
    let doTrimWhitespace = jsonGetStrDefault(inputJson, "trim_whitespace", "false") == "true";
    let maxLength = switch (Nat.fromText(jsonGetStrDefault(inputJson, "max_length", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    // Unconditionally normalize line endings before any other processing
    var result = content.replace(#text "\r\n", "\n").replace(#text "\r", "\n");
    if (doStripBom and result.startsWith(#text "\u{FEFF}")) {
      result := switch (result.stripStart(#text "\u{FEFF}")) { case (?s) s; case null result };
    };
    // doDetectLineEndings kept for API compatibility but normalization already applied above
    ignore doDetectLineEndings;
    if (doTrimWhitespace) {
      result := result.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
    };
    let wasTruncated = maxLength > 0 and result.size() > maxLength;
    if (wasTruncated) {
      let chars = result.toArray();
      result := Text.fromIter(chars.sliceToArray(0, maxLength.toInt()).values());
    };
    let charCount = result.size();
    let lineCount = result.split(#text "\n").toArray().size();
    var wordCount = 0;
    var inWord = false;
    for (c in result.toIter()) {
      let isSpace = c == ' ' or c == '\t' or c == '\n' or c == '\r';
      if (isSpace) { inWord := false }
      else if (not inWord) { inWord := true; wordCount += 1 };
    };
    ok("{\"content\": \"" # escapeJson(result) # "\", \"char_count\": " # charCount.toText() # ", \"line_count\": " # lineCount.toText() # ", \"word_count\": " # wordCount.toText() # ", \"encoding_hint\": \"" # escapeJson(encodingHint) # "\", \"was_truncated\": " # (if wasTruncated "true" else "false") # "}");
  };

  func handle_extract_text(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let originalLen = content.size();
    let doPreserve = jsonGetStrDefault(inputJson, "preserve_formatting", "false") == "true";
    let doDecodeEntities = jsonGetStrDefault(inputJson, "decode_html_entities", "true") != "false";
    let customStripOpt = jsonGetStr(inputJson, "custom_strip_chars");
    let doCollapse = jsonGetStrDefault(inputJson, "collapse_whitespace", "true") != "false";
    let minLength = switch (Nat.fromText(jsonGetStrDefault(inputJson, "min_length", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    var result = content.flatMap(func(c : Char) : Text {
      if (c >= ' ' or c == '\n' or c == '\t') c.toText() else "";
    });
    if (doDecodeEntities) {
      result := result
        .replace(#text "&amp;", "&")
        .replace(#text "&lt;", "<")
        .replace(#text "&gt;", ">")
        .replace(#text "&quot;", "\"")
        .replace(#text "&#39;", "'");
    };
    switch (customStripOpt) {
      case (?stripChars) {
        result := result.flatMap(func(c : Char) : Text {
          if (stripChars.contains(#char c)) "" else c.toText()
        });
      };
      case null {};
    };
    if (doCollapse) {
      let chars = List.empty<Char>();
      var prevSpace = false;
      for (c in result.toIter()) {
        let isSpace = if (doPreserve) c == ' ' or c == '\t' else c == ' ' or c == '\t' or c == '\n';
        if (isSpace) {
          if (not prevSpace) { chars.add(' '); prevSpace := true };
        } else {
          chars.add(c);
          prevSpace := false;
        };
      };
      result := Text.fromIter(chars.values());
    };
    result := result.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
    let charCount = result.size();
    if (minLength > 0 and charCount < minLength) result := "";
    let stripped : Int = originalLen.toInt() - charCount.toInt();
    let strippedCount = if (stripped < 0) 0 else stripped.toNat();
    ok("{\"text\": \"" # escapeJson(result) # "\", \"char_count\": " # charCount.toText() # ", \"stripped_char_count\": " # strippedCount.toText() # "}");
  };

  func normalizeDiacritics(s : Text) : Text {
    s
      .replace(#text "à", "a").replace(#text "á", "a").replace(#text "â", "a").replace(#text "ã", "a").replace(#text "ä", "a").replace(#text "å", "a")
      .replace(#text "è", "e").replace(#text "é", "e").replace(#text "ê", "e").replace(#text "ë", "e")
      .replace(#text "ì", "i").replace(#text "í", "i").replace(#text "î", "i").replace(#text "ï", "i")
      .replace(#text "ò", "o").replace(#text "ó", "o").replace(#text "ô", "o").replace(#text "õ", "o").replace(#text "ö", "o").replace(#text "ø", "o")
      .replace(#text "ù", "u").replace(#text "ú", "u").replace(#text "û", "u").replace(#text "ü", "u")
      .replace(#text "ý", "y").replace(#text "ÿ", "y")
      .replace(#text "ñ", "n").replace(#text "ç", "c").replace(#text "ß", "ss").replace(#text "œ", "oe")
      .replace(#text "À", "A").replace(#text "Á", "A").replace(#text "Â", "A").replace(#text "Ã", "A").replace(#text "Ä", "A").replace(#text "Å", "A")
      .replace(#text "È", "E").replace(#text "É", "E").replace(#text "Ê", "E").replace(#text "Ë", "E")
      .replace(#text "Ì", "I").replace(#text "Í", "I").replace(#text "Î", "I").replace(#text "Ï", "I")
      .replace(#text "Ò", "O").replace(#text "Ó", "O").replace(#text "Ô", "O").replace(#text "Õ", "O").replace(#text "Ö", "O").replace(#text "Ø", "O")
      .replace(#text "Ù", "U").replace(#text "Ú", "U").replace(#text "Û", "U").replace(#text "Ü", "U")
      .replace(#text "Ñ", "N").replace(#text "Ç", "C");
  };

  func handle_clean_text(inputJson : Text) : ExecResult {
    let input = switch (jsonGetStr(inputJson, "content")) {
      case (?v) v;
      case null jsonGetStrDefault(inputJson, "text", "");
    };
    let originalLen = input.size();
    let doRemoveZW = jsonGetStrDefault(inputJson, "remove_zero_width", "true") != "false";
    let doNormalizeUnicode = jsonGetStrDefault(inputJson, "normalize_unicode", "false") == "true";
    let doCollapse = jsonGetStrDefault(inputJson, "collapse_whitespace", "true") != "false";
    let doStripTabs = jsonGetStrDefault(inputJson, "strip_tabs", "false") == "true";
    let doStripNewlines = jsonGetStrDefault(inputJson, "strip_newlines", "false") == "true";
    let trimMode = jsonGetStrDefault(inputJson, "trim_mode", "both");
    let replaceTabsWith = jsonGetStrDefault(inputJson, "replace_tabs_with", " ");
    var result = input;
    if (doRemoveZW) {
      result := result
        .replace(#text "\u{200B}", "")
        .replace(#text "\u{200C}", "")
        .replace(#text "\u{200D}", "")
        .replace(#text "\u{FEFF}", "");
    };
    if (doNormalizeUnicode) { result := normalizeDiacritics(result) };
    if (doCollapse) {
      let chars = List.empty<Char>();
      var prevSpace = false;
      for (c in result.toIter()) {
        let isSpace = c == ' ' or c == '\t';
        if (isSpace) {
          if (not prevSpace) { chars.add(' '); prevSpace := true };
        } else {
          chars.add(c);
          prevSpace := false;
        };
      };
      result := Text.fromIter(chars.values());
    };
    if (doStripTabs) { result := result.replace(#text "\t", replaceTabsWith) };
    if (doStripNewlines) { result := result.replace(#text "\n", "").replace(#text "\r", "") };
    result := switch (trimMode) {
      case "both"  result.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
      case "start" result.trimStart(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
      case "end"   result.trimEnd(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
      case _       result;
    };
    let cleanedLen = result.size();
    let removed : Int = originalLen.toInt() - cleanedLen.toInt();
    let charsRemoved = if (removed < 0) 0 else removed.toNat();
    ok("{\"text\": \"" # escapeJson(result) # "\", \"original_length\": " # originalLen.toText() # ", \"cleaned_length\": " # cleanedLen.toText() # ", \"chars_removed\": " # charsRemoved.toText() # "}");
  };

  func handle_chunk_text(inputJson : Text) : ExecResult {
    let input = switch (jsonGetStr(inputJson, "content")) {
      case (?v) v;
      case null jsonGetStrDefault(inputJson, "text", "");
    };
    let chunkSize = switch (Nat.fromText(jsonGetStrDefault(inputJson, "chunk_size", "500").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 500 };
    let overlap = switch (Nat.fromText(jsonGetStrDefault(inputJson, "overlap", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let strategy = jsonGetStrDefault(inputJson, "strategy", "fixed");
    let minChunkSize = switch (Nat.fromText(jsonGetStrDefault(inputJson, "min_chunk_size", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let doPreserveSentences = jsonGetStrDefault(inputJson, "preserve_sentences", "false") == "true";
    let doStripWs = jsonGetStrDefault(inputJson, "strip_chunk_whitespace", "true") != "false";
    let doIncludeIndex = jsonGetStrDefault(inputJson, "include_chunk_index", "false") == "true";
    if (chunkSize == 0) return err("INVALID_INPUT", "chunk_size must be >= 1");
    if (overlap >= chunkSize) return err("INVALID_INPUT", "overlap must be < chunk_size");
    let chars = input.toArray();
    let total = chars.size();
    let chunks = List.empty<Text>();
    var pos = 0;
    while (pos < total) {
      let end : Nat = switch (strategy) {
        case "word_boundary" {
          let e = Nat.min(pos + chunkSize, total);
          if (e >= total) e
          else {
            var i = e;
            while (i > pos and chars[i - 1] != ' ') { i -= 1 };
            if (i == pos) e else i;
          };
        };
        case "sentence" {
          let e = Nat.min(pos + chunkSize, total);
          if (e >= total) e
          else {
            var i = e;
            var found = false;
            while (i > pos + 1 and not found) {
              let c = chars[i - 1];
              if ((c == '.' or c == '!' or c == '?') and i < total and chars[i] == ' ') { found := true }
              else i -= 1;
            };
            if (not found) {
              // fallback to word boundary
              var j = e;
              while (j > pos and chars[j - 1] != ' ') { j -= 1 };
              if (j == pos) e else j;
            } else i + 1;
          };
        };
        case _ {
          let hardEnd = Nat.min(pos + chunkSize, total);
          if (doPreserveSentences and hardEnd < total) {
            var i = hardEnd;
            var found = false;
            while (i > pos + 1 and not found) {
              let c = chars[i - 1];
              if ((c == '.' or c == '!' or c == '?') and i < total and chars[i] == ' ') { found := true }
              else i -= 1;
            };
            if (not found) hardEnd else i + 1;
          } else hardEnd;
        };
      };
      let slice = chars.sliceToArray(pos.toInt(), end.toInt());
      var chunk = Text.fromIter(slice.values());
      if (doStripWs) {
        chunk := chunk.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
      };
      if (chunk.size() >= minChunkSize) chunks.add(chunk);
      if (end >= total) { pos := total }
      else {
        let step = if (end > pos + overlap) end - overlap else end;
        pos := if (step <= pos) pos + 1 else step;
      };
    };
    let arr = chunks.toArray();
    let finalChunks = if (doIncludeIndex) {
      arr.mapEntries(func(chunk, i) { "[chunk " # (i + 1).toText() # "] " # chunk })
    } else arr;
    var totalChars = 0;
    for (c in arr.values()) { totalChars += c.size() };
    let avgSize = if (arr.size() == 0) 0 else totalChars / arr.size();
    let arrayStr = "[" # finalChunks.values().map(func(c : Text) : Text { "\"" # escapeJson(c) # "\"" }).join(", ") # "]";
    ok("{\"chunks\": " # arrayStr # ", \"chunk_count\": " # finalChunks.size().toText() # ", \"avg_chunk_size\": " # avgSize.toText() # ", \"total_chars\": " # totalChars.toText() # "}");
  };

  func stripScriptStyleBlocks(html : Text) : (Text, Nat) {
    var result = "";
    var remaining = html;
    var tagsRemoved = 0;
    var keepGoing = true;
    while (keepGoing) {
      let lowerRemaining = remaining.toLower();
      let scriptIdx = textFindIndex(lowerRemaining, "<script");
      let styleIdx = textFindIndex(lowerRemaining, "<style");
      if (scriptIdx == -1 and styleIdx == -1) {
        keepGoing := false;
      } else {
        let tagStart : Int = if (scriptIdx == -1) styleIdx
          else if (styleIdx == -1) scriptIdx
          else if (scriptIdx <= styleIdx) scriptIdx else styleIdx;
        let tagName = if (tagStart == scriptIdx) "script" else "style";
        result := result # Text.fromIter(remaining.toIter().take(tagStart.toNat()));
        let afterTag = Text.fromIter(remaining.toIter().drop(tagStart.toNat()));
        let closeTag = "</" # tagName # ">";
        let closeIdx = textFindIndex(afterTag.toLower(), closeTag);
        if (closeIdx == -1) {
          remaining := "";
          keepGoing := false;
        } else {
          remaining := Text.fromIter(afterTag.toIter().drop(closeIdx.toNat() + closeTag.size()));
          tagsRemoved += 2;
        };
      };
    };
    (result # remaining, tagsRemoved);
  };

  func handle_remove_html(inputJson : Text) : ExecResult {
    let html = switch (jsonGetStr(inputJson, "content")) {
      case (?v) v;
      case null jsonGetStrDefault(inputJson, "html", "");
    };
    let originalLen = html.size();
    let doDecodeEntities = jsonGetStrDefault(inputJson, "decode_entities", "true") != "false";
    let doPreserveLineBreaks = jsonGetStrDefault(inputJson, "preserve_line_breaks", "true") != "false";
    let doSkipScriptStyle = jsonGetStrDefault(inputJson, "skip_script_style", "true") != "false";
    let allowedTagsOpt = jsonGetStr(inputJson, "allowed_tags");
    let doCollapse = jsonGetStrDefault(inputJson, "collapse_whitespace", "true") != "false";
    var working = html;
    var tagsRemoved = 0;
    if (doSkipScriptStyle) {
      let (stripped, count) = stripScriptStyleBlocks(working);
      working := stripped;
      tagsRemoved += count;
    };
    let allowedArr = switch (allowedTagsOpt) {
      case (?tags) tags.split(#text ",").toArray().map(func(t) {
        t.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })).toLower()
      });
      case null [];
    };
    let hasAllowList = allowedArr.size() > 0;
    let blockTags = ["p", "div", "br", "h1", "h2", "h3", "h4", "h5", "h6", "li", "tr"];
    let resultList = List.empty<Char>();
    var inTag = false;
    var tagBuf = "";
    var prevWasSpace = false;
    for (c in working.toIter()) {
      if (c == '<') {
        inTag := true;
        tagBuf := "";
      } else if (c == '>') {
        inTag := false;
        let tagContent = tagBuf.trim(#predicate(func(x : Char) { x == ' ' or x == '/' })).toLower();
        let tagNameOnly = Text.fromIter(tagContent.toIter().takeWhile(func(x : Char) : Bool { x != ' ' and x != '/' }));
        let isBlock = blockTags.find<Text>(func(t) { Text.equal(t, tagNameOnly) }) != null;
        if (hasAllowList and allowedArr.values().find(func(t : Text) : Bool { Text.equal(t, tagNameOnly) }) != null) {
          for (tc in ("<" # tagBuf # ">").toIter()) resultList.add(tc);
        } else {
          tagsRemoved += 1;
          if (doPreserveLineBreaks and isBlock) {
            resultList.add('\n');
            prevWasSpace := false;
          } else if (not prevWasSpace) {
            resultList.add(' ');
            prevWasSpace := true;
          };
        };
      } else if (inTag) {
        tagBuf := tagBuf # c.toText();
      } else {
        if (c == ' ' or c == '\t') {
          if (not prevWasSpace) { resultList.add(' '); prevWasSpace := true };
        } else if (c == '\n' or c == '\r') {
          if (doPreserveLineBreaks) {
            resultList.add('\n');
            prevWasSpace := false;
          } else if (not prevWasSpace) {
            resultList.add(' ');
            prevWasSpace := true;
          };
        } else {
          resultList.add(c);
          prevWasSpace := false;
        };
      };
    };
    var text = Text.fromIter(resultList.values()).trim(#predicate(func(c : Char) { c == ' ' or c == '\n' }));
    if (doDecodeEntities) {
      text := text
        .replace(#text "&amp;", "&")
        .replace(#text "&lt;", "<")
        .replace(#text "&gt;", ">")
        .replace(#text "&quot;", "\"")
        .replace(#text "&#39;", "'");
    };
    if (doCollapse) {
      let chars2 = List.empty<Char>();
      var prevS = false;
      for (c in text.toIter()) {
        let isS = c == ' ' or c == '\t';
        if (isS) {
          if (not prevS) { chars2.add(' '); prevS := true };
        } else {
          chars2.add(c);
          prevS := false;
        };
      };
      text := Text.fromIter(chars2.values()).trim(#predicate(func(c : Char) { c == ' ' }));
    };
    let outputLen = text.size();
    ok("{\"text\": \"" # escapeJson(text) # "\", \"tags_removed\": " # tagsRemoved.toText() # ", \"original_length\": " # originalLen.toText() # ", \"output_length\": " # outputLen.toText() # "}");
  };

  func handle_normalize_text(inputJson : Text) : ExecResult {
    let text = jsonGetStrDefault(inputJson, "text", "");
    let originalLen = text.size();
    let normalizeUnicodeForm = jsonGetStrDefault(inputJson, "normalize_unicode", "none");
    let doRemoveDiacritics = jsonGetStrDefault(inputJson, "remove_diacritics", "false") == "true";
    let doLower = jsonGetStrDefault(inputJson, "lowercase", "false") == "true";
    let doRemovePunct = jsonGetStrDefault(inputJson, "remove_punctuation", "false") == "true";
    let doRemoveNumbers = jsonGetStrDefault(inputJson, "remove_numbers", "false") == "true";
    let doRemoveSymbols = jsonGetStrDefault(inputJson, "remove_symbols", "false") == "true";
    let whitespaceMode = jsonGetStrDefault(inputJson, "whitespace_mode", "preserve");
    let locale = jsonGetStrDefault(inputJson, "locale", "en");
    var result = text;
    let ops = List.empty<Text>();
    if (normalizeUnicodeForm != "none") {
      result := normalizeDiacritics(result);
      ops.add("normalize_unicode");
    };
    if (doRemoveDiacritics) {
      let before = result;
      result := normalizeDiacritics(result);
      if (result != before) ops.add("remove_diacritics");
    };
    if (doLower) {
      let before = result;
      result := if (locale == "tr") {
        result.replace(#text "I", "\u{0131}").replace(#text "\u{0130}", "i").toLower();
      } else result.toLower();
      if (result != before) ops.add("lowercase");
    };
    if (doRemovePunct) {
      let before = result;
      result := result.flatMap(func(c : Char) : Text {
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == ' ' or c == '\t' or c == '\n') c.toText()
        else "";
      });
      if (result != before) ops.add("remove_punctuation");
    };
    if (doRemoveNumbers) {
      let before = result;
      result := result.flatMap(func(c : Char) : Text {
        if (c >= '0' and c <= '9') "" else c.toText()
      });
      if (result != before) ops.add("remove_numbers");
    };
    if (doRemoveSymbols) {
      let before = result;
      result := result.flatMap(func(c : Char) : Text {
        if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == ' ' or c == '\t' or c == '\n' or c == '\r') c.toText()
        else "";
      });
      if (result != before) ops.add("remove_symbols");
    };
    let beforeWs = result;
    result := switch (whitespaceMode) {
      case "collapse" {
        let chars = List.empty<Char>();
        var prevSpace = false;
        for (c in result.toIter()) {
          let isSpace = c == ' ' or c == '\t';
          if (isSpace) {
            if (not prevSpace) { chars.add(' '); prevSpace := true };
          } else {
            chars.add(c);
            prevSpace := false;
          };
        };
        Text.fromIter(chars.values());
      };
      case "strip" result.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' }));
      case "normalize" {
        let chars = List.empty<Char>();
        var prevSpace = false;
        for (c in result.toIter()) {
          let isSpace = c == ' ' or c == '\t';
          if (isSpace) {
            if (not prevSpace) { chars.add(' '); prevSpace := true };
          } else {
            chars.add(c);
            prevSpace := false;
          };
        };
        Text.fromIter(chars.values()).trim(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
      };
      case _ result;
    };
    if (result != beforeWs) ops.add("whitespace_mode");
    let normalizedLen = result.size();
    let opsArr = ops.toArray();
    let opsJson = "[" # opsArr.values().map(func(o : Text) : Text { "\"" # escapeJson(o) # "\"" }).join(", ") # "]";
    ok("{\"text\": \"" # escapeJson(result) # "\", \"original_length\": " # originalLen.toText() # ", \"normalized_length\": " # normalizedLen.toText() # ", \"operations_applied\": " # opsJson # "}");
  };

  func isValidJsonStart(s : Text) : Bool {
    let t = s.trim(#predicate(func(c : Char) { c == ' ' }));
    t.startsWith(#text "{") or t.startsWith(#text "[") or t.startsWith(#text "\"") or
    t == "true" or t == "false" or t == "null" or
    (switch (parseFloat(t)) { case (?_) true; case null false });
  };

  // Compute nesting depth of a JSON value string (simple bracket counter)
  func jsonDepth(s : Text) : Nat {
    var depth = 0;
    var maxDepth = 0;
    var inStr = false;
    var prevBackslash = false;
    for (c in s.toIter()) {
      if (inStr) {
        if (prevBackslash) prevBackslash := false
        else if (c == '\u{5C}') prevBackslash := true
        else if (c == '\u{22}') inStr := false;
      } else if (c == '\u{22}') {
        inStr := true;
      } else if (c == '{' or c == '[') {
        depth += 1;
        if (depth > maxDepth) maxDepth := depth;
      } else if (c == '}' or c == ']') {
        if (depth > 0) depth -= 1;
      };
    };
    maxDepth;
  };

  // Build a filtered JSON object keeping only include_keys (or dropping exclude_keys)
  func filterJsonKeys(json : Text, includeKeys : [Text], excludeKeys : [Text]) : Text {
    let allKeys = jsonKeys(json);
    let pairs = List.empty<Text>();
    for (k in allKeys.values()) {
      let keep = if (includeKeys.size() > 0) {
        // include_keys provided: only keep listed keys
        includeKeys.find(func(ik : Text) : Bool { ik == k }) != null
      } else if (excludeKeys.size() > 0) {
        // exclude_keys provided: drop listed keys
        excludeKeys.find(func(ek : Text) : Bool { ek == k }) == null
      } else true;
      if (keep) {
        switch (jsonGetStr(json, k)) {
          case (?v) {
            let vType = detectType(v);
            let vQuoted = if (vType == "string") "\"" # escapeJson(v) # "\"" else v;
            pairs.add("\"" # escapeJson(k) # "\": " # vQuoted);
          };
          case null {};
        };
      };
    };
    "{" # pairs.values().join(", ") # "}"
  };

  func handle_parse_json(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content must be non-empty");
    let isArray_ = looksLikeArray(content);
    let valid = isValidJsonStart(content);
    if (not valid) return err("INVALID_INPUT", "content is not valid JSON");

    // Parse include_keys and exclude_keys arrays
    let includeKeysRaw = jsonGetStrDefault(inputJson, "include_keys", "[]");
    let excludeKeysRaw = jsonGetStrDefault(inputJson, "exclude_keys", "[]");
    let includeKeyTokens = splitJsonArray(includeKeysRaw);
    let excludeKeyTokens = splitJsonArray(excludeKeysRaw);
    let includeKeys = includeKeyTokens.map(func(f) {
      f.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }))
    });
    let excludeKeys = excludeKeyTokens.map(func(f) {
      f.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }))
    });

    // Apply key filtering (only for objects, not arrays)
    let filtered = if (not isArray_ and (includeKeys.size() > 0 or excludeKeys.size() > 0)) {
      filterJsonKeys(content, includeKeys, excludeKeys)
    } else content;

    let keys = if (not isArray_) jsonKeys(filtered) else ([] : [Text]);
    let depth = jsonDepth(content);
    let sizeBytes = content.size();

    let keysJson = "[" # keys.values().map(func(k : Text) : Text { "\"" # escapeJson(k) # "\"" }).join(", ") # "]";
    ok("{\"parsed\": \"" # escapeJson(filtered) # "\", \"key_count\": " # keys.size().toText() # ", \"is_array\": " # (if isArray_ "true" else "false") # ", \"depth\": " # depth.toText() # ", \"size_bytes\": " # sizeBytes.toText() # ", \"keys\": " # keysJson # "}");
  };

  func handle_validate_json(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) {
      return ok("{\"is_valid\": false, \"errors\": [{\"path\": \"$\", \"message\": \"Input is empty\", \"expected\": \"non-empty JSON string\", \"actual\": \"empty\"}], \"error_count\": 1, \"warnings\": []}");
    };

    // Syntactic check first
    if (not isValidJsonStart(content)) {
      return ok("{\"is_valid\": false, \"errors\": [{\"path\": \"$\", \"message\": \"Invalid JSON syntax\", \"expected\": \"valid JSON\", \"actual\": \"unparseable\"}], \"error_count\": 1, \"warnings\": []}");
    };

    let detailedRaw = jsonGetStrDefault(inputJson, "detailed_errors", "true");
    let allowNullRaw = jsonGetStrDefault(inputJson, "allow_null_values", "true");
    let strictTypesRaw = jsonGetStrDefault(inputJson, "strict_types", "false");
    let maxErrorsStr = jsonGetStrDefault(inputJson, "max_errors", "10");
    let maxErrors = switch (Nat.fromText(maxErrorsStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 10 };
    let _detailed = detailedRaw != "false";
    let allowNull = allowNullRaw != "false";
    let strictTypes = strictTypesRaw == "true";

    let errors = List.empty<Text>();
    let warnings = List.empty<Text>();

    // Schema validation if provided
    switch (jsonGetStr(inputJson, "schema")) {
      case null {};
      case (?schemaRaw) {
        let schemaStr = schemaRaw.trim(#predicate(func(c : Char) { c == ' ' }));
        // Check required fields
        switch (jsonGetStr(schemaStr, "required")) {
          case (?reqRaw) {
            let reqTokens = splitJsonArray(reqRaw);
            for (req in reqTokens.values()) {
              if (errors.size() >= maxErrors) {}
              else {
                let fieldName = req.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }));
                switch (jsonGetStr(content, fieldName)) {
                  case null {
                    errors.add("{\"path\": \"$." # escapeJson(fieldName) # "\", \"message\": \"Required field missing\", \"expected\": \"present\", \"actual\": \"missing\"}");
                  };
                  case (?v) {
                    if (not allowNull and v.trim(#predicate(func(c : Char) { c == ' ' })) == "null") {
                      errors.add("{\"path\": \"$." # escapeJson(fieldName) # "\", \"message\": \"Field is null but null values are not allowed\", \"expected\": \"non-null\", \"actual\": \"null\"}");
                    };
                  };
                };
              };
            };
          };
          case null {};
        };
        // Check properties types
        switch (jsonGetStr(schemaStr, "properties")) {
          case null {};
          case (?propsRaw) {
            for (propKey in jsonKeys(propsRaw).values()) {
              if (errors.size() >= maxErrors) {}
              else {
                switch (jsonGetStr(content, propKey)) {
                  case null {}; // missing fields handled by required check
                  case (?v) {
                    let vTrimmed = v.trim(#predicate(func(c : Char) { c == ' ' }));
                    switch (jsonGetStr(propsRaw, propKey)) {
                      case null {};
                      case (?propSchemaRaw) {
                        // Check type
                        switch (jsonGetStr(propSchemaRaw, "type")) {
                          case null {};
                          case (?expectedType) {
                            let actualType = detectType(vTrimmed);
                            let typeMatch = if (strictTypes) actualType == expectedType
                              else actualType == expectedType or (expectedType == "number" and actualType == "string" and parseFloat(vTrimmed) != null);
                            if (not typeMatch and (allowNull or vTrimmed != "null")) {
                              errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"Type mismatch\", \"expected\": \"" # escapeJson(expectedType) # "\", \"actual\": \"" # escapeJson(actualType) # "\"}");
                            };
                          };
                        };
                        // Check enum
                        switch (jsonGetStr(propSchemaRaw, "enum")) {
                          case null {};
                          case (?enumRaw) {
                            if (errors.size() < maxErrors) {
                              let enumVals = splitJsonArray(enumRaw);
                              let vStripped = vTrimmed.trim(#predicate(func(c : Char) { c == '\u{22}' }));
                              let inEnum = enumVals.find(func(e : Text) : Bool {
                                e.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' })) == vStripped
                              }) != null;
                              if (not inEnum) {
                                errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"Value not in allowed enum\", \"expected\": \"" # escapeJson(enumRaw) # "\", \"actual\": \"" # escapeJson(vStripped) # "\"}");
                              };
                            };
                          };
                        };
                        // Check minimum/maximum for numbers
                        switch (parseFloat(vTrimmed)) {
                          case (?numVal) {
                            switch (jsonGetStr(propSchemaRaw, "minimum")) {
                              case (?minStr) {
                                if (errors.size() < maxErrors) {
                                  switch (parseFloat(minStr.trim(#predicate(func(c : Char) { c == ' ' })))) {
                                    case (?minVal) {
                                      if (numVal < minVal) {
                                        errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"Value below minimum\", \"expected\": \">= " # floatToText(minVal) # "\", \"actual\": \"" # floatToText(numVal) # "\"}");
                                      };
                                    };
                                    case null {};
                                  };
                                };
                              };
                              case null {};
                            };
                            switch (jsonGetStr(propSchemaRaw, "maximum")) {
                              case (?maxStr) {
                                if (errors.size() < maxErrors) {
                                  switch (parseFloat(maxStr.trim(#predicate(func(c : Char) { c == ' ' })))) {
                                    case (?maxVal) {
                                      if (numVal > maxVal) {
                                        errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"Value above maximum\", \"expected\": \"<= " # floatToText(maxVal) # "\", \"actual\": \"" # floatToText(numVal) # "\"}");
                                      };
                                    };
                                    case null {};
                                  };
                                };
                              };
                              case null {};
                            };
                          };
                          case null {};
                        };
                        // Check minLength/maxLength for strings
                        if (vTrimmed.startsWith(#text "\"")) {
                          let strVal = vTrimmed.trim(#predicate(func(c : Char) { c == '\u{22}' }));
                          switch (jsonGetStr(propSchemaRaw, "minLength")) {
                            case (?mlStr) {
                              if (errors.size() < maxErrors) {
                                switch (Nat.fromText(mlStr.trim(#predicate(func(c : Char) { c == ' ' })))) {
                                  case (?ml) {
                                    if (strVal.size() < ml) {
                                      errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"String too short\", \"expected\": \"minLength " # ml.toText() # "\", \"actual\": \"" # strVal.size().toText() # "\"}");
                                    };
                                  };
                                  case null {};
                                };
                              };
                            };
                            case null {};
                          };
                          switch (jsonGetStr(propSchemaRaw, "maxLength")) {
                            case (?mlStr) {
                              if (errors.size() < maxErrors) {
                                switch (Nat.fromText(mlStr.trim(#predicate(func(c : Char) { c == ' ' })))) {
                                  case (?ml) {
                                    if (strVal.size() > ml) {
                                      errors.add("{\"path\": \"$." # escapeJson(propKey) # "\", \"message\": \"String too long\", \"expected\": \"maxLength " # ml.toText() # "\", \"actual\": \"" # strVal.size().toText() # "\"}");
                                    };
                                  };
                                  case null {};
                                };
                              };
                            };
                            case null {};
                          };
                        };
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    let errArr = errors.toArray();
    let warnArr = warnings.toArray();
    let isValid = errArr.size() == 0;
    ok("{\"is_valid\": " # (if isValid "true" else "false") # ", \"errors\": [" # errArr.values().join(", ") # "], \"error_count\": " # errArr.size().toText() # ", \"warnings\": [" # warnArr.values().map(func(w : Text) : Text { "\"" # escapeJson(w) # "\"" }).join(", ") # "]}");
  };

  // Navigate nested path segments in a JSON object
  func jsonGetNested(json : Text, pathParts : [Text]) : ?Text {
    if (pathParts.size() == 0) return ?json;
    var current = json;
    for (part in pathParts.values()) {
      switch (jsonGetStr(current, part)) {
        case (?v) current := v;
        case null return null;
      };
    };
    ?current
  };

  func handle_extract_fields(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let fieldsRaw = jsonGetStrDefault(inputJson, "fields", "[]");
    let renameMapRaw = jsonGetStrDefault(inputJson, "rename_map", "{}");
    let defaultValuesRaw = jsonGetStrDefault(inputJson, "default_values", "{}");
    let typeCoerceRaw = jsonGetStrDefault(inputJson, "type_coerce", "false");
    let includeNullsRaw = jsonGetStrDefault(inputJson, "include_nulls", "true");
    let flattenNestedRaw = jsonGetStrDefault(inputJson, "flatten_nested", "false");
    let typeCoerce = typeCoerceRaw == "true";
    let includeNulls = includeNullsRaw != "false";
    let flattenNested = flattenNestedRaw == "true";

    let fieldTokens = splitJsonArray(fieldsRaw);
    let fields = fieldTokens.map(func(f) {
      f.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }))
    });

    let resultPairs = List.empty<Text>();
    let missingFields = List.empty<Text>();
    var foundCount = 0;

    for (field in fields.values()) {
      // Resolve rename
      let outputKey = switch (jsonGetStr(renameMapRaw, field)) {
        case (?renamed) renamed;
        case null field;
      };

      // Try to get value — support dot-notation if flattenNested
      let maybeVal : ?Text = if (flattenNested and field.contains(#text ".")) {
        let parts = field.split(#text ".").toArray();
        jsonGetNested(content, parts);
      } else {
        jsonGetStr(content, field);
      };

      // Apply default if missing
      let resolvedVal : ?Text = switch (maybeVal) {
        case (?v) {
          let vTrimmed = v.trim(#predicate(func(c : Char) { c == ' ' }));
          if (vTrimmed == "null") {
            // Field exists but is null — check default
            switch (jsonGetStr(defaultValuesRaw, field)) {
              case (?def) ?def;
              case null ?vTrimmed;
            };
          } else ?vTrimmed;
        };
        case null {
          switch (jsonGetStr(defaultValuesRaw, field)) {
            case (?def) ?def;
            case null null;
          };
        };
      };

      switch (resolvedVal) {
        case null {
          missingFields.add("\"" # escapeJson(field) # "\"");
        };
        case (?v) {
          foundCount += 1;
          let vType = detectType(v);
          // Skip null values if includeNulls is false
          if (not includeNulls and v == "null") {
            // don't add
          } else {
            let vFinal = if (typeCoerce) {
              // Coerce string-wrapped numbers and booleans
              if (vType == "string") {
                let inner = v.trim(#predicate(func(c : Char) { c == '\u{22}' }));
                if (inner == "true" or inner == "false") inner
                else switch (parseFloat(inner)) {
                  case (?_) inner; // output as bare number
                  case null "\"" # escapeJson(inner) # "\"";
                };
              } else v; // number, boolean, null, object, array — use as-is
            } else {
              if (vType == "string") "\"" # escapeJson(v) # "\"" else v
            };
            resultPairs.add("\"" # escapeJson(outputKey) # "\": " # vFinal);
          };
        };
      };
    };

    let missingArr = missingFields.toArray();
    ok("{\"extracted\": {" # resultPairs.values().join(", ") # "}, \"found_count\": " # foundCount.toText() # ", \"missing_fields\": [" # missingArr.values().join(", ") # "], \"total_fields_requested\": " # fields.size().toText() # "}");
  };

  // Coerce a cell string value to its inferred type for JSON output
  func coerceCellValue(v : Text) : Text {
    let trimmed = v.trim(#predicate(func(c : Char) { c == ' ' }));
    if (trimmed == "true" or trimmed == "false") trimmed
    else switch (parseFloat(trimmed)) {
      case (?_) trimmed;
      case null "\"" # escapeJson(trimmed) # "\"";
    };
  };

  func handle_extract_table(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content must be non-empty");

    let delimiterRaw = jsonGetStrDefault(inputJson, "delimiter", ",");
    let delimiter = if (delimiterRaw == "\\t") "\t" else if (delimiterRaw.size() == 0) "," else delimiterRaw;
    let hasHeaderRaw = jsonGetStrDefault(inputJson, "has_header", "true");
    let hasHeader = hasHeaderRaw != "false";
    let filterEmptyColsRaw = jsonGetStrDefault(inputJson, "filter_empty_columns", "false");
    let filterEmptyCols = filterEmptyColsRaw == "true";
    let inferTypesRaw = jsonGetStrDefault(inputJson, "infer_types", "false");
    let inferTypes = inferTypesRaw == "true";
    let skipEmptyRowsRaw = jsonGetStrDefault(inputJson, "skip_empty_rows", "true");
    let skipEmptyRows = skipEmptyRowsRaw != "false";
    let maxRowsStr = jsonGetStrDefault(inputJson, "max_rows", "0");
    let maxRows = switch (Nat.fromText(maxRowsStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };

    // Split all lines
    let rawLines = content.split(#text "\n").toArray();
    if (rawLines.size() == 0) return ok("{\"table\": [], \"row_count\": 0, \"column_count\": 0, \"columns\": [], \"has_header\": false}");

    // Determine headers
    let colsOverrideRaw = jsonGetStrDefault(inputJson, "columns", "[]");
    let colOverrideTokens = splitJsonArray(colsOverrideRaw);
    let colsOverride = colOverrideTokens.map(func(c) {
      c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == ' ' }))
    });

    let headerLine = rawLines[0].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' }));
    let rawHeaders = if (colsOverride.size() > 0) {
      colsOverride
    } else if (hasHeader) {
      headerLine.split(#text delimiter).toArray().map(func(h) {
        h.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' or c == '\r' }))
      })
    } else {
      // Generate positional headers col0, col1, ...
      let firstCells = headerLine.split(#text delimiter).toArray();
      firstCells.mapEntries(func(_, i) { "col" # i.toText() })
    };

    // Determine which lines are data (skip header if hasHeader and no override)
    let dataStartIdx = if (hasHeader and colsOverride.size() == 0) 1 else 0;

    // Parse all data rows
    let allDataRows = List.empty<[Text]>();
    for (i in Nat.range(dataStartIdx, rawLines.size())) {
      let line = rawLines[i].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' }));
      let cells = line.split(#text delimiter).toArray().map(func(c) {
        c.trim(#predicate(func(x : Char) { x == ' ' or x == '\u{22}' or x == '\r' }))
      });
      // Skip empty rows
      let allEmpty = cells.find(func(c : Text) : Bool { c.size() > 0 }) == null;
      if (not (skipEmptyRows and allEmpty)) {
        allDataRows.add(cells);
      };
    };

    // Apply column order filtering
    let columnOrderRaw = jsonGetStrDefault(inputJson, "column_order", "[]");
    let columnOrderTokens = splitJsonArray(columnOrderRaw);
    let columnOrder = columnOrderTokens.map(func(c) {
      c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == ' ' }))
    });

    // Effective headers after column_order (or use rawHeaders)
    let effectiveHeaders = if (columnOrder.size() > 0) columnOrder else rawHeaders;

    // Build map from header name to index in rawHeaders for fast lookup
    let headerIndexMap = Map.empty<Text, Nat>();
    for (i in Nat.range(0, rawHeaders.size())) {
      headerIndexMap.add(rawHeaders[i], i);
    };

    // Filter empty columns if needed (check across all data rows)
    let finalHeaders = if (filterEmptyCols) {
      effectiveHeaders.filter(func(h : Text) : Bool {
        let hIdx = switch (headerIndexMap.get(h)) { case (?i) i; case null 999 };
        let allDataRowsArr = allDataRows.toArray();
        allDataRowsArr.find(func(row : [Text]) : Bool {
          hIdx < row.size() and row[hIdx].size() > 0
        }) != null
      })
    } else effectiveHeaders;

    // Apply max_rows
    let allDataRowsArr = allDataRows.toArray();
    let limitedRows = if (maxRows > 0 and allDataRowsArr.size() > maxRows) {
      allDataRowsArr.sliceToArray(0, maxRows.toInt())
    } else allDataRowsArr;

    // Build output JSON array of objects
    let rowObjects = List.empty<Text>();
    for (row in limitedRows.values()) {
      let pairs = List.empty<Text>();
      for (h in finalHeaders.values()) {
        let hIdx = switch (headerIndexMap.get(h)) { case (?i) i; case null 999 };
        let cellVal = if (hIdx < row.size()) row[hIdx] else "";
        let jsonVal = if (inferTypes) coerceCellValue(cellVal) else "\"" # escapeJson(cellVal) # "\"";
        pairs.add("\"" # escapeJson(h) # "\": " # jsonVal);
      };
      rowObjects.add("{" # pairs.values().join(", ") # "}");
    };

    let colsJson = "[" # finalHeaders.values().map(func(h : Text) : Text { "\"" # escapeJson(h) # "\"" }).join(", ") # "]";
    let rowsJson = "[" # rowObjects.toArray().values().join(", ") # "]";
    ok("{\"table\": " # rowsJson # ", \"row_count\": " # limitedRows.size().toText() # ", \"column_count\": " # finalHeaders.size().toText() # ", \"columns\": " # colsJson # ", \"has_header\": " # (if hasHeader "true" else "false") # "}");
  };

  func parseKVLine(line : Text, sep : Text) : ?(Text, Text) {
    let parts = line.split(#text sep).toArray();
    if (parts.size() < 2) return null;
    let k = parts[0].trim(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
    var val = "";
    var first = true;
    for (i in Nat.range(1, parts.size())) {
      if (not first) val := val # sep;
      val := val # parts[i];
      first := false;
    };
    val := val.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\r' }));
    if (k.size() == 0) null else ?(k, val);
  };

  // Transform a key string according to key_transform setting
  func applyKeyTransform(k : Text, transform : Text) : Text {
    switch (transform) {
      case "lowercase" k.toLower();
      case "uppercase" k.toUpper();
      case "snake_case" {
        k.toLower().flatMap(func(c : Char) : Text {
          if (c == ' ' or c == '-') "_" else c.toText()
        });
      };
      case _ k; // "none" or unknown
    };
  };

  func handle_text_to_key_value(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let sep = jsonGetStrDefault(inputJson, "separator", ":");
    let trimKeysRaw = jsonGetStrDefault(inputJson, "trim_keys", "true");
    let trimValsRaw = jsonGetStrDefault(inputJson, "trim_values", "true");
    let allowDupsRaw = jsonGetStrDefault(inputJson, "allow_duplicate_keys", "false");
    let inferTypesRaw = jsonGetStrDefault(inputJson, "infer_types", "false");
    let skipEmptyRaw = jsonGetStrDefault(inputJson, "skip_empty_lines", "true");
    let skipCommentsRaw = jsonGetStrDefault(inputJson, "skip_comment_lines", "false");
    let keyTransform = jsonGetStrDefault(inputJson, "key_transform", "none");

    let doTrimKeys = trimKeysRaw != "false";
    let doTrimVals = trimValsRaw != "false";
    let allowDups = allowDupsRaw == "true";
    let inferTypes = inferTypesRaw == "true";
    let skipEmpty = skipEmptyRaw != "false";
    let skipComments = skipCommentsRaw == "true";

    let lines = content.split(#text "\n").toArray();

    // Track insertion order for key output
    let keyOrder = List.empty<Text>();
    // For allow_duplicate_keys=true: key -> list of values
    let dupValuesMap = Map.empty<Text, List.List<Text>>();
    // For allow_duplicate_keys=false: key -> last value
    let singleValueMap = Map.empty<Text, Text>();
    let duplicateKeys = Set.empty<Text>();
    var skippedLines = 0;
    var pairCount = 0;

    for (rawLine in lines.values()) {
      let line = rawLine.trim(#predicate(func(c : Char) { c == '\r' }));

      // Skip empty lines
      if (skipEmpty and line.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })).size() == 0) {
        skippedLines += 1;
      }
      // Skip comment lines
      else if (skipComments and line.trimStart(#predicate(func(c : Char) { c == ' ' or c == '\t' })).startsWith(#text "#")) {
        skippedLines += 1;
      }
      else {
        switch (parseKVLine(line, sep)) {
          case null { skippedLines += 1 };
          case (?(rawK, rawV)) {
            let k0 = if (doTrimKeys) rawK.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })) else rawK;
            let v0 = if (doTrimVals) rawV.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })) else rawV;
            let k = applyKeyTransform(k0, keyTransform);
            pairCount += 1;

            if (allowDups) {
              switch (dupValuesMap.get(k)) {
                case null {
                  let vList = List.empty<Text>();
                  vList.add(v0);
                  dupValuesMap.add(k, vList);
                  keyOrder.add(k);
                };
                case (?existing) {
                  duplicateKeys.add(k);
                  existing.add(v0);
                };
              };
            } else {
              // last value wins
              if (singleValueMap.containsKey(k)) {
                duplicateKeys.add(k);
              } else {
                keyOrder.add(k);
              };
              singleValueMap.add(k, v0);
            };
          };
        };
      };
    };

    // Build output object
    let pairs = List.empty<Text>();
    // Deduplicate keyOrder (may have dups from allowDups=false multiple writes)
    let seenKeys = Set.empty<Text>();
    for (k in keyOrder.values()) {
      if (not seenKeys.contains(k)) {
        seenKeys.add(k);
        if (allowDups) {
          switch (dupValuesMap.get(k)) {
            case null {};
            case (?vList) {
              let vArr = vList.toArray();
              if (vArr.size() > 1) {
                let arrItems = vArr.map(func(v : Text) : Text {
                  if (inferTypes) coerceCellValue(v) else "\"" # escapeJson(v) # "\""
                });
                pairs.add("\"" # escapeJson(k) # "\": [" # arrItems.values().join(", ") # "]");
              } else {
                let v = if (vArr.size() > 0) vArr[0] else "";
                let jsonVal = if (inferTypes) coerceCellValue(v) else "\"" # escapeJson(v) # "\"";
                pairs.add("\"" # escapeJson(k) # "\": " # jsonVal);
              };
            };
          };
        } else {
          switch (singleValueMap.get(k)) {
            case null {};
            case (?v) {
              let jsonVal = if (inferTypes) coerceCellValue(v) else "\"" # escapeJson(v) # "\"";
              pairs.add("\"" # escapeJson(k) # "\": " # jsonVal);
            };
          };
        };
      };
    };

    let dupArr = duplicateKeys.toArray();
    let dupJson = "[" # dupArr.values().map(func(d : Text) : Text { "\"" # escapeJson(d) # "\"" }).join(", ") # "]";

    ok("{\"data\": {" # pairs.values().join(", ") # "}, \"pair_count\": " # pairCount.toText() # ", \"skipped_lines\": " # skippedLines.toText() # ", \"duplicate_keys\": " # dupJson # "}");
  };


  // ── Production transform/filter/sort/dedup/merge/flatten/expand handlers ───

  func applyTransformOp_(
    op : Text, field : Text, srcField : Text, value : Text,
    expr : Text, valueMapRaw : Text,
    pairs : List.List<Text>, srcJson : Text,
    errOnMissing : Bool, errs : List.List<Text>,
  ) {
    switch (op) {
      case "rename" {
        switch (jsonGetStr(srcJson, srcField)) {
          case (?v) {
            let vT = detectType(v);
            let vQ = if (vT == "string") "\"" # escapeJson(v) # "\"" else v;
            let f2 = pairs.filter(func(p : Text) : Bool { not p.startsWith(#text ("\"" # escapeJson(srcField) # "\"")) });
            pairs.clear(); for (p in f2.values()) pairs.add(p);
            pairs.add("\"" # escapeJson(field) # "\": " # vQ);
          };
          case null { if (errOnMissing) errs.add("\"rename: field '" # escapeJson(srcField) # "' not found\"") };
        };
      };
      case "add" {
        let vT = detectType(value);
        pairs.add("\"" # escapeJson(field) # "\": " # (if (vT == "string" and not value.startsWith(#text "\"")) "\"" # escapeJson(value) # "\"" else value));
      };
      case "remove" {
        let f2 = pairs.filter(func(p : Text) : Bool { not p.startsWith(#text ("\"" # escapeJson(field) # "\"")) });
        pairs.clear(); for (p in f2.values()) pairs.add(p);
      };
      case "compute" {
        var e = expr;
        for (k in jsonKeys(srcJson).values()) {
          switch (jsonGetStr(srcJson, k)) { case (?v) e := e.replace(#text ("{" # k # "}"), v); case null {} };
        };
        let res = switch (parseFloat(e.trim(#predicate(func(c : Char) { c == ' ' })))) {
          case (?n) floatToText(n);
          case null {
            var comp = "0";
            label fo loop {
              let ec = e.toArray(); var d = 0; var op2 = -1; var oc = '+';
              var j = ec.size();
              label sa while (j > 0) { j -= 1; let c = ec[j]; if (c == ')') d += 1 else if (c == '(') { if (d > 0) d -= 1 } else if (d == 0 and j > 0 and (c == '+' or c == '-')) { op2 := j; oc := c; break sa } };
              if (op2 == -1) { d := 0; j := ec.size(); label sm while (j > 0) { j -= 1; let c = ec[j]; if (c == ')') d += 1 else if (c == '(') { if (d > 0) d -= 1 } else if (d == 0 and (c == '*' or c == '/')) { op2 := j; oc := c; break sm } } };
              if (op2 <= 0) break fo;
              let lhs = Text.fromIter(ec.sliceToArray(0, op2).values()).trim(#predicate(func(c : Char) { c == ' ' }));
              let rhs = Text.fromIter(ec.sliceToArray(op2 + 1, ec.size()).values()).trim(#predicate(func(c : Char) { c == ' ' }));
              switch (parseFloat(lhs), parseFloat(rhs)) {
                case (?a, ?b) { comp := floatToText(switch (oc) { case '+' a+b; case '-' a-b; case '*' a*b; case '/' if (b==0.0) 0.0 else a/b; case _ 0.0 }) };
                case _ {};
              };
              break fo;
            };
            comp
          };
        };
        pairs.add("\"" # escapeJson(field) # "\": " # res);
      };
      case "map" {
        switch (jsonGetStr(srcJson, field)) {
          case (?ov) {
            let vs = ov.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' }));
            let m2 = switch (jsonGetStr(valueMapRaw, vs)) { case (?m) m; case null ov };
            let mT = detectType(m2);
            let mQ = if (mT == "string") "\"" # escapeJson(m2) # "\"" else m2;
            let f2 = pairs.filter(func(p : Text) : Bool { not p.startsWith(#text ("\"" # escapeJson(field) # "\"")) });
            pairs.clear(); for (p in f2.values()) pairs.add(p);
            pairs.add("\"" # escapeJson(field) # "\": " # mQ);
          };
          case null { if (errOnMissing) errs.add("\"map: field '" # escapeJson(field) # "' not found\"") };
        };
      };
      case _ {};
    };
  };

  func transformObj_(obj : Text, ops : [Text], inclUnmapped : Bool, errOnMissing : Bool, errs : List.List<Text>) : Text {
    let pairs = List.empty<Text>();
    if (inclUnmapped) {
      for (k in jsonKeys(obj).values()) {
        switch (jsonGetStr(obj, k)) {
          case (?v) { let vT = detectType(v); pairs.add("\"" # escapeJson(k) # "\": " # (if (vT == "string") "\"" # escapeJson(v) # "\"" else v)) };
          case null {};
        };
      };
    };
    for (op in ops.values()) {
      let f = jsonGetStrDefault(op, "field", "");
      applyTransformOp_(jsonGetStrDefault(op, "op", ""), f,
        jsonGetStrDefault(op, "source_field", f), jsonGetStrDefault(op, "value", ""),
        jsonGetStrDefault(op, "expression", ""), jsonGetStrDefault(op, "value_map", "{}"),
        pairs, obj, errOnMissing, errs);
    };
    "{" # pairs.values().join(", ") # "}"
  };

  func handle_transform_data(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let ops = splitJsonArray(jsonGetStrDefault(inputJson, "transformations", "[]"));
    let inclUnmapped = jsonGetStrDefault(inputJson, "include_unmapped", "true") != "false";
    let applyAll = jsonGetStrDefault(inputJson, "apply_to_all", "true") != "false";
    let errOnMissing = jsonGetStrDefault(inputJson, "error_on_missing", "false") == "true";
    let errs = List.empty<Text>();
    var tc = 0; var oa = 0;
    let result : Text = if (looksLikeArray(content)) {
      let items = splitJsonArray(content);
      let out = List.empty<Text>();
      for (i in Nat.range(0, items.size())) {
        if (applyAll or i == 0) { out.add(transformObj_(items[i], ops, inclUnmapped, errOnMissing, errs)); tc += 1; oa += ops.size() }
        else out.add(items[i]);
      };
      "[" # out.toArray().values().join(", ") # "]"
    } else { tc := 1; oa := ops.size(); transformObj_(content, ops, inclUnmapped, errOnMissing, errs) };
    ok("{\"result\": " # result # ", \"transformed_count\": " # tc.toText() # ", \"operations_applied\": " # oa.toText() # ", \"errors\": [" # errs.toArray().values().join(", ") # "]}");
  };

  func evalFC_(item : Text, field : Text, op : Text, value : Text, cs : Bool) : Bool {
    let raw = jsonGetStrDefault(item, field, "");
    let iv = if (cs) raw else raw.toLower();
    let cv = if (cs) value else value.toLower();
    switch (op) {
      case "eq"           iv == cv;
      case "neq"          iv != cv;
      case "gt"           switch (parseFloat(raw), parseFloat(value)) { case (?a, ?b) a > b; case _ iv > cv };
      case "gte"          switch (parseFloat(raw), parseFloat(value)) { case (?a, ?b) a >= b; case _ iv >= cv };
      case "lt"           switch (parseFloat(raw), parseFloat(value)) { case (?a, ?b) a < b; case _ iv < cv };
      case "lte"          switch (parseFloat(raw), parseFloat(value)) { case (?a, ?b) a <= b; case _ iv <= cv };
      case "contains"     iv.contains(#text cv);
      case "not_contains" not iv.contains(#text cv);
      case "starts_with"  iv.startsWith(#text cv);
      case "ends_with"    iv.endsWith(#text cv);
      case "in"           splitJsonArray(value).find(func(a : Text) : Bool { (if (cs) a else a.toLower()).trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) == iv }) != null;
      case "not_in"       splitJsonArray(value).find(func(a : Text) : Bool { (if (cs) a else a.toLower()).trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) == iv }) == null;
      case "is_null"      raw == "" or raw == "null";
      case "is_not_null"  raw != "" and raw != "null";
      case "regex"        raw.contains(#text value);
      case _              iv == cv;
    };
  };

  func handle_filter_data(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let fts = splitJsonArray(jsonGetStrDefault(inputJson, "filters", "[]"));
    let logOp = jsonGetStrDefault(inputJson, "logical_operator", "AND").toUpper();
    let gCS = jsonGetStrDefault(inputJson, "case_sensitive", "false") == "true";
    let invert = jsonGetStrDefault(inputJson, "invert", "false") == "true";
    let limitOpt : ?Nat = switch (jsonGetStr(inputJson, "limit")) { case null null; case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' }))) };
    let offset = switch (Nat.fromText(jsonGetStrDefault(inputJson, "offset", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let items = splitJsonArray(content);
    let total = items.size();
    let matched = List.empty<Text>();
    for (item in items.values()) {
      let pass = if (fts.size() == 0) true else {
        let results = fts.map(func(ft : Text) : Bool {
          let pCS = if (ft.contains(#text "\"case_sensitive\"")) jsonGetStrDefault(ft, "case_sensitive", if (gCS) "true" else "false") == "true" else gCS;
          evalFC_(item, jsonGetStrDefault(ft, "field", ""), jsonGetStrDefault(ft, "operator", "eq"), jsonGetStrDefault(ft, "value", ""), pCS)
        });
        switch (logOp) { case "OR" results.any(func(r : Bool) : Bool { r }); case _ results.all(func(r : Bool) : Bool { r }) }
      };
      if (if (invert) not pass else pass) matched.add(item);
    };
    let ma = matched.toArray();
    let mc = ma.size();
    let sliced = if (offset >= ma.size()) ([] : [Text]) else ma.sliceToArray(offset.toInt(), ma.size().toInt());
    let limited = switch (limitOpt) { case null sliced; case (?n) if (n >= sliced.size()) sliced else sliced.sliceToArray(0, n.toInt()) };
    ok("{\"result\": [" # limited.values().join(", ") # "], \"matched_count\": " # mc.toText() # ", \"total_count\": " # total.toText() # ", \"filtered_out\": " # (total - mc).toText() # "}");
  };

  func handle_sort_data(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let sts = splitJsonArray(jsonGetStrDefault(inputJson, "sort_fields", "[]"));
    let natSort = jsonGetStrDefault(inputJson, "natural_sort", "false") == "true";
    let specs : [(Text, Text, Text, Bool)] = if (sts.size() > 0) {
      sts.map<Text, (Text, Text, Text, Bool)>(func(ft) {
        (jsonGetStrDefault(ft, "field", "_value"), jsonGetStrDefault(ft, "order", "asc"),
         jsonGetStrDefault(ft, "nulls", "last"), jsonGetStrDefault(ft, "case_sensitive", "false") == "true")
      })
    } else [(jsonGetStrDefault(inputJson, "field", "_value"), jsonGetStrDefault(inputJson, "order", "asc"), "last", false)];
    let items = splitJsonArray(content);
    let origCount = items.size();
    let sorted = items.sort(func(a, b) {
      var res : {#less; #equal; #greater} = #equal;
      label sl for ((f, ord, np, csf) in specs.values()) {
        if (res != #equal) break sl;
        let va = jsonGetStrDefault(a, f, ""); let vb = jsonGetStrDefault(b, f, "");
        let aN = va == "" or va == "null"; let bN = vb == "" or vb == "null";
        let cmp : {#less; #equal; #greater} = if (aN and bN) #equal
          else if (aN) (if (np == "first") #less else #greater)
          else if (bN) (if (np == "first") #greater else #less)
          else switch (parseFloat(va), parseFloat(vb)) {
            case (?fa, ?fb) if (fa < fb) #less else if (fa > fb) #greater else #equal;
            case _ {
              let ca = if (csf) va else va.toLower(); let cb = if (csf) vb else vb.toLower();
              if (natSort) { switch (Nat.fromText(ca), Nat.fromText(cb)) { case (?na, ?nb) if (na < nb) #less else if (na > nb) #greater else #equal; case _ Text.compare(ca, cb) } }
              else Text.compare(ca, cb)
            };
          };
        res := if (ord == "desc") switch (cmp) { case (#less) #greater; case (#greater) #less; case (#equal) #equal } else cmp;
      };
      res
    });
    let fu = specs.map(func((f, _, _, _) : (Text, Text, Text, Bool)) : Text { "\"" # escapeJson(f) # "\"" });
    ok("{\"result\": [" # sorted.values().join(", ") # "], \"original_count\": " # origCount.toText() # ", \"sort_fields_used\": [" # fu.values().join(", ") # "]}");
  };

  func handle_deduplicate_data(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let byFs = splitJsonArray(jsonGetStrDefault(inputJson, "by_fields", "[]")).map(func(f) { f.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) });
    let csf = jsonGetStrDefault(inputJson, "case_sensitive", "true") != "false";
    let cmode = jsonGetStrDefault(inputJson, "compare_mode", "exact");
    let keep = jsonGetStrDefault(inputJson, "keep", "first");
    let cntDups = jsonGetStrDefault(inputJson, "count_duplicates", "false") == "true";
    let items = splitJsonArray(content);
    let origCount = items.size();
    let mkKey = func(item : Text) : Text {
      let raw = if (byFs.size() > 0) byFs.map(func(f : Text) : Text { jsonGetStrDefault(item, f, "") }).values().join("|") else item;
      let k = switch (cmode) {
        case "normalized" raw.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })).toLower();
        case "type_coerced" switch (parseFloat(raw.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?f) floatToText(f); case null if (raw == "true" or raw == "1") "true" else if (raw == "false" or raw == "0") "false" else raw };
        case _ raw;
      };
      if (csf) k else k.toLower()
    };
    let work = if (keep == "last") items.reverse() else items;
    let cntMap = Map.empty<Text, Nat>();
    for (item in items.values()) { let k = mkKey(item); cntMap.add(k, switch (cntMap.get(k)) { case (?c) c + 1; case null 1 }) };
    let seen = Set.empty<Text>(); let result = List.empty<Text>(); var dr = 0;
    for (item in work.values()) {
      let k = mkKey(item);
      if (not seen.contains(k)) {
        seen.add(k);
        if (cntDups) {
          let dc = switch (cntMap.get(k)) { case (?c) c; case null 1 };
          result.add(item.trimEnd(#predicate(func(c : Char) { c == ' ' })).trimEnd(#text "}") # ", \"_duplicate_count\": " # dc.toText() # "}");
        } else result.add(item);
      } else dr += 1;
    };
    let fa = if (keep == "last") result.toArray().reverse() else result.toArray();
    ok("{\"result\": [" # fa.values().join(", ") # "], \"original_count\": " # origCount.toText() # ", \"deduplicated_count\": " # fa.size().toText() # ", \"duplicates_removed\": " # dr.toText() # "}");
  };

  func handle_merge_objects(inputJson : Text) : ExecResult {
    let otks = splitJsonArray(jsonGetStrDefault(inputJson, "objects", "[]"));
    let srcs : [Text] = if (otks.size() > 0) otks.map(func(s) { s.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) })
      else [jsonGetStrDefault(inputJson, "object1", "{}"), jsonGetStrDefault(inputJson, "object2", "{}")];
    let deep = jsonGetStrDefault(inputJson, "deep_merge", "false") == "true";
    let cs = jsonGetStrDefault(inputJson, "conflict_strategy", "overwrite");
    let amm = jsonGetStrDefault(inputJson, "array_merge_mode", "replace");
    let exNull = jsonGetStrDefault(inputJson, "exclude_null_values", "false") == "true";
    let merged = Map.empty<Text, Text>(); var cr = 0;
    for (src in srcs.values()) {
      let t = src.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
      if (t.startsWith(#text "{")) {
        for (k in jsonKeys(t).values()) {
          switch (jsonGetStr(t, k)) {
            case (?v) {
              let vT = v.trim(#predicate(func(c : Char) { c == ' ' }));
              if (not (exNull and vT == "null")) {
                switch (merged.get(k)) {
                  case null merged.add(k, vT);
                  case (?ex) {
                    cr += 1;
                    switch (cs) {
                      case "keep_first" {};
                      case "error" { return err("CONFLICT", "Key conflict: " # k) };
                      case "array" { merged.add(k, if (ex.trim(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "[")) ex.trimEnd(#text "]") # ", " # vT # "]" else "[" # ex # ", " # vT # "]") };
                      case _ {
                        if (deep and ex.trim(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{") and vT.startsWith(#text "{")) {
                          let nm = Map.empty<Text, Text>();
                          for (nk in jsonKeys(ex).values()) { switch (jsonGetStr(ex, nk)) { case (?nv) nm.add(nk, nv); case null {} } };
                          for (nk in jsonKeys(vT).values()) { switch (jsonGetStr(vT, nk)) { case (?nv) nm.add(nk, nv); case null {} } };
                          let np = List.empty<Text>();
                          for ((nk, nv) in nm.entries()) { let nvT = detectType(nv); np.add("\"" # escapeJson(nk) # "\": " # (if (nvT == "string") "\"" # escapeJson(nv) # "\"" else nv)) };
                          merged.add(k, "{" # np.values().join(", ") # "}");
                        } else if (amm == "concat" and ex.trim(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "[") and vT.startsWith(#text "[")) {
                          merged.add(k, "[" # ex.trimEnd(#text "]").trimStart(#text "[") # ", " # vT.trimEnd(#text "]").trimStart(#text "[") # "]");
                        } else merged.add(k, vT);
                      };
                    };
                  };
                };
              };
            };
            case null {};
          };
        };
      };
    };
    let pairs = List.empty<Text>();
    for ((k, v) in merged.entries()) { let vT = detectType(v); pairs.add("\"" # escapeJson(k) # "\": " # (if (vT == "string") "\"" # escapeJson(v) # "\"" else v)) };
    ok("{\"result\": {" # pairs.values().join(", ") # "}, \"key_count\": " # pairs.size().toText() # ", \"conflicts_resolved\": " # cr.toText() # ", \"source_count\": " # srcs.size().toText() # "}");
  };

  func flattenRec_(
    json : Text, pfx : Text, sep : Text, pairs : List.List<Text>,
    arrStyle : Text, maxD : ?Nat, d : Nat,
    skipNull : Bool, skipEA : Bool, aC : List.List<Nat>,
  ) {
    let atMax = switch (maxD) { case (?md) d >= md; case null false };
    for (k in jsonKeys(json).values()) {
      let fk = if (pfx.size() == 0) k else pfx # sep # k;
      switch (jsonGetStr(json, k)) {
        case (?v) {
          let vT = v.trim(#predicate(func(c : Char) { c == ' ' }));
          if (skipNull and vT == "null") {}
          else if (vT.startsWith(#text "{") and not atMax) flattenRec_(vT, fk, sep, pairs, arrStyle, maxD, d + 1, skipNull, skipEA, aC)
          else if (vT.startsWith(#text "[") and not atMax) {
            if (skipEA and vT == "[]") {}
            else {
              let ai = splitJsonArray(vT);
              if (ai.size() == 0 and skipEA) {}
              else {
                for (i in Nat.range(0, ai.size())) {
                  let idx = switch (arrStyle) { case "dot" sep # i.toText(); case "underscore" "_" # i.toText(); case _ "[" # i.toText() # "]" };
                  let av = ai[i].trim(#predicate(func(c : Char) { c == ' ' }));
                  if (av.startsWith(#text "{")) flattenRec_(av, fk # idx, sep, pairs, arrStyle, maxD, d + 1, skipNull, skipEA, aC)
                  else { let avT = detectType(av); pairs.add("\"" # escapeJson(fk # idx) # "\": " # (if (avT == "string") "\"" # escapeJson(av) # "\"" else av)) };
                };
                if (aC.size() > 0) aC.put(0, aC.at(0) + ai.size());
              };
            };
          } else {
            let vvT = detectType(vT);
            pairs.add("\"" # escapeJson(fk) # "\": " # (if (vvT == "string") "\"" # escapeJson(vT) # "\"" else vT));
          };
        };
        case null {};
      };
    };
  };

  func jDepth_(json : Text) : Nat {
    var d = 0; var m = 0; var inS = false; var pb = false;
    for (c in json.toIter()) {
      if (inS) { if (pb) pb := false else if (c == '\u{5C}') pb := true else if (c == '\u{22}') inS := false }
      else if (c == '\u{22}') inS := true
      else if (c == '{' or c == '[') { d += 1; if (d > m) m := d }
      else if ((c == '}' or c == ']') and d > 0) d -= 1;
    };
    m
  };

  func handle_flatten_object(inputJson : Text) : ExecResult {
    let content = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "{}") };
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let sep = jsonGetStrDefault(inputJson, "separator", ".");
    let maxD : ?Nat = switch (jsonGetStr(inputJson, "max_depth")) { case null null; case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' }))) };
    let pfx = jsonGetStrDefault(inputJson, "prefix", "");
    let arrStyle = jsonGetStrDefault(inputJson, "array_index_style", "bracket");
    let skipNull = jsonGetStrDefault(inputJson, "skip_null_values", "false") == "true";
    let skipEA = jsonGetStrDefault(inputJson, "skip_empty_arrays", "false") == "true";
    let pairs = List.empty<Text>();
    let aC = List.fromArray<Nat>([0]);
    flattenRec_(content, pfx, sep, pairs, arrStyle, maxD, 0, skipNull, skipEA, aC);
     ok("{\"result\": {" # pairs.values().join(", ") # "}, \"original_depth\": " # jDepth_(content).toText() # ", \"key_count\": " # pairs.size().toText() # ", \"array_keys_flattened\": " # (if (aC.size() > 0) aC.at(0) else 0).toText() # "}");
  };

  // Coerce a flat-key leaf value to its JSON representation when preserve_types=true
  func coerceLeaf_(raw : Text) : Text {
    let t = raw.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }));
    if (t == "null") "null"
    else if (t == "true" or t == "false") t
    else switch (parseFloat(t)) { case (?_) t; case null "\"" # escapeJson(raw.trim(#predicate(func(c : Char) { c == ' ' }))) # "\"" }
  };

  // Recursively build nested JSON from (path_segments, json_value) pairs.
  // Returns (json_string, max_depth, array_keys_created).
  func buildNested_(entries : [([Text], Text)], arrIdx : Bool) : (Text, Nat, Nat) {
    if (entries.size() == 1 and entries[0].0.size() == 0) return (entries[0].1, 0, 0);
    let groupMap = Map.empty<Text, List.List<([Text], Text)>>();
    let groupOrder = List.empty<Text>();
    for ((segs, v) in entries.values()) {
      let head = if (segs.size() == 0) "_value" else segs[0];
      let tail : [Text] = if (segs.size() > 1) segs.sliceToArray(1, segs.size().toInt()) else [];
      switch (groupMap.get(head)) {
        case null { let l = List.empty<([Text], Text)>(); l.add((tail, v)); groupMap.add(head, l); groupOrder.add(head) };
        case (?l) l.add((tail, v));
      };
    };
    let seenOrd = Set.empty<Text>(); let uniqueOrder = List.empty<Text>();
    for (gk in groupOrder.values()) {
      if (not seenOrd.contains(gk)) { seenOrd.add(gk); uniqueOrder.add(gk) };
    };
    let uniqueKeys = uniqueOrder.toArray();
    let allIntsSeq : Bool = if (arrIdx and uniqueKeys.size() > 0) {
      var isSeq = true;
      for (i in Nat.range(0, uniqueKeys.size())) {
        if (not seenOrd.contains(i.toText())) isSeq := false;
      };
      if (isSeq) { for (gk2 in uniqueKeys.values()) { switch (Nat.fromText(gk2)) { case null isSeq := false; case (?_) {} } } };
      isSeq
    } else false;
    var totalMaxDepth = 0; var totalArrKeys = 0;
    if (allIntsSeq) {
      let sortedNums = uniqueKeys.sort(func(a2, b2) { switch (Nat.fromText(a2), Nat.fromText(b2)) { case (?na, ?nb) if (na < nb) #less else if (na > nb) #greater else #equal; case _ Text.compare(a2, b2) } });
      let arrItems = List.empty<Text>();
      for (gk in sortedNums.values()) {
        switch (groupMap.get(gk)) {
          case null {};
          case (?subList) {
            let (childJson, childDepth, childArrKeys) = buildNested_(subList.toArray(), arrIdx);
            arrItems.add(childJson);
            if (childDepth + 1 > totalMaxDepth) totalMaxDepth := childDepth + 1;
            totalArrKeys += childArrKeys;
          };
        };
      };
      totalArrKeys += 1;
      ("[" # arrItems.values().join(", ") # "]", totalMaxDepth, totalArrKeys)
    } else {
      let pairsN = List.empty<Text>();
      for (gk in uniqueKeys.values()) {
        switch (groupMap.get(gk)) {
          case null {};
          case (?subList) {
            let (childJson, childDepth, childArrKeys) = buildNested_(subList.toArray(), arrIdx);
            pairsN.add("\"" # escapeJson(gk) # "\": " # childJson);
            if (childDepth + 1 > totalMaxDepth) totalMaxDepth := childDepth + 1;
            totalArrKeys += childArrKeys;
          };
        };
      };
      ("{" # pairsN.values().join(", ") # "}", totalMaxDepth, totalArrKeys)
    }
  };

  func handle_expand_object(inputJson : Text) : ExecResult {
    let content = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "{}") };
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let sep = jsonGetStrDefault(inputJson, "separator", ".");
    let maxD : ?Nat = switch (jsonGetStr(inputJson, "max_depth")) { case null null; case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' }))) };
    let arrIdx = jsonGetStrDefault(inputJson, "array_indices", "true") != "false";
    let presTypes = jsonGetStrDefault(inputJson, "preserve_types", "true") != "false";
    let flatKeys = jsonKeys(content);
    var ec = 0;
    let allEntries = List.empty<([Text], Text)>();
    for (fk in flatKeys.values()) {
      switch (jsonGetStr(content, fk)) {
        case (?rawVal) {
          ec += 1;
          let parts = fk.split(#text sep).toArray();
          let effectiveParts : [Text] = switch (maxD) {
            case null parts;
            case (?md) if (parts.size() <= md) parts else parts.sliceToArray(0, md.toInt())
          };
          let leafVal = if (presTypes) coerceLeaf_(rawVal) else "\"" # escapeJson(rawVal.trim(#predicate(func(c : Char) { c == ' ' }))) # "\"";
          allEntries.add((effectiveParts, leafVal));
        };
        case null {};
      };
    };
    if (ec == 0) return ok("{\"result\": {}, \"expanded_key_count\": 0, \"depth\": 0, \"array_keys_created\": 0}");
    let (resultJson, maxDepth, arrKeysCreated) = buildNested_(allEntries.toArray(), arrIdx);
    ok("{\"result\": " # resultJson # ", \"expanded_key_count\": " # ec.toText() # ", \"depth\": " # maxDepth.toText() # ", \"array_keys_created\": " # arrKeysCreated.toText() # "}");
  };

  func countOccurrences(haystack : Text, needle : Text) : Nat {
    if (needle.size() == 0) return 0;
    var count = 0;
    var remaining = haystack;
    label lp loop {
      if (remaining.size() < needle.size()) break lp;
      if (remaining.startsWith(#text needle)) {
        count += 1;
        remaining := Text.fromIter(remaining.toIter().drop(needle.size()));
      } else {
        remaining := Text.fromIter(remaining.toIter().drop(1));
      };
    };
    count;
  };

  func handle_keyword_search(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let kw = jsonGetStrDefault(inputJson, "query", "");
    if (kw.size() == 0) return err("INVALID_INPUT", "query must be non-empty");
    let caseSensRaw = jsonGetStrDefault(inputJson, "case_sensitive", "false");
    let caseSens = caseSensRaw == "true";
    let wholeWordsRaw = jsonGetStrDefault(inputJson, "match_whole_words", "false");
    let wholeWords = wholeWordsRaw == "true";
    let returnPosRaw = jsonGetStrDefault(inputJson, "return_positions", "false");
    let returnPos = returnPosRaw == "true";
    let countOnlyRaw = jsonGetStrDefault(inputJson, "count_only", "false");
    let countOnly = countOnlyRaw == "true";
    let maxMatchesRaw = jsonGetStr(inputJson, "max_matches");
    let maxMatches : ?Nat = switch (maxMatchesRaw) {
      case null null;
      case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' })));
    };
    let ctxCharsRaw = jsonGetStrDefault(inputJson, "context_chars", "0");
    let ctxChars = switch (Nat.fromText(ctxCharsRaw.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };

    let haystack = if (caseSens) content else content.toLower();
    let needle = if (caseSens) kw else kw.toLower();
    let chars = haystack.toArray();
    let origChars = content.toArray();
    let needleChars = needle.toArray();
    let needleSize = needleChars.size();
    let total = chars.size();

    func isWordBoundaryKw(pos : Nat) : Bool {
      let before = if (pos == 0) true else {
        let c = chars[pos - 1];
        not ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_');
      };
      let after = if (pos + needleSize >= total) true else {
        let c = chars[pos + needleSize];
        not ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_');
      };
      before and after;
    };

    let matchObjs = List.empty<Text>();
    var matchCount = 0;
    var pos = 0;
    label searchLoop while (pos + needleSize <= total) {
      switch (maxMatches) { case (?m) { if (matchCount >= m) break searchLoop }; case null {} };
      let slice = Text.fromIter(chars.sliceToArray(pos.toInt(), (pos + needleSize).toInt()).values());
      if (Text.equal(slice, needle)) {
        if (not wholeWords or isWordBoundaryKw(pos)) {
          matchCount += 1;
          if (not countOnly) {
            let matchStr = Text.fromIter(origChars.sliceToArray(pos.toInt(), (pos + needleSize).toInt()).values());
            var obj = "{\"match\": \"" # escapeJson(matchStr) # "\"";
            if (returnPos) obj := obj # ", \"position\": " # pos.toText();
            if (ctxChars > 0) {
              let ctxStart = if (pos >= ctxChars) pos - ctxChars else 0;
              let ctxEnd = Nat.min(pos + needleSize + ctxChars, total);
              let ctx = Text.fromIter(origChars.sliceToArray(ctxStart.toInt(), ctxEnd.toInt()).values());
              obj := obj # ", \"context\": \"" # escapeJson(ctx) # "\"";
            };
            matchObjs.add(obj # "}");
          };
        };
      };
      pos += 1;
    };
    let found = matchCount > 0;
    let matchesArr = if (countOnly) "[]" else "[" # matchObjs.toArray().values().join(", ") # "]";
    ok("{\"found\": " # (if found "true" else "false") # ", \"match_count\": " # matchCount.toText() # ", \"matches\": " # matchesArr # ", \"query\": \"" # escapeJson(kw) # "\"}");
  };

  // ── Regex engine ─────────────────────────────────────────────────────────
  // Supports: literals, . * + ? [class] [^class] [a-z] ^ $ \ escaping

  func parseCharClass(pat : [Char], start : Nat) : (Char -> Bool, Nat) {
    var i = start;
    let patLen = pat.size();
    let negated = (i < patLen and pat[i] == '^');
    if (negated) i += 1;
    let startIdx = i;
    let matchers = List.empty<Char -> Bool>();
    label classLoop while (i < patLen) {
      if (pat[i] == ']' and i != startIdx) break classLoop;
      if (i + 2 < patLen and pat[i + 1] == '-' and pat[i + 2] != ']') {
        let lo = pat[i];
        let hi = pat[i + 2];
        matchers.add(func(c : Char) : Bool { c >= lo and c <= hi });
        i += 3;
      } else if (pat[i] == '\\' and i + 1 < patLen) {
        let escaped = pat[i + 1];
        matchers.add(func(c : Char) : Bool { c == escaped });
        i += 2;
      } else {
        let ch = pat[i];
        matchers.add(func(c : Char) : Bool { c == ch });
        i += 1;
      };
    };
    if (i < patLen and pat[i] == ']') i += 1;
    let matcherArr = matchers.toArray();
    let matchFn : Char -> Bool = if (negated) {
      func(c : Char) : Bool { not matcherArr.any(func(m : Char -> Bool) : Bool { m(c) }) };
    } else {
      func(c : Char) : Bool { matcherArr.any(func(m : Char -> Bool) : Bool { m(c) }) };
    };
    (matchFn, i);
  };

  func regexMatch(pat : [Char], patLen : Nat, txt : [Char], txtLen : Nat, txtPos : Nat, patPos : Nat, ci : Bool) : ?Nat {
    if (patPos >= patLen) return ?txtPos;

    let normChar : Char -> Char = if (ci) {
      func(c : Char) : Char {
        if (c >= 'A' and c <= 'Z') Char.fromNat32(c.toNat32() + 32) else c;
      };
    } else { func(c : Char) : Char { c } };

    if (pat[patPos] == '^') {
      return if (txtPos == 0) regexMatch(pat, patLen, txt, txtLen, txtPos, patPos + 1, ci) else null;
    };
    if (pat[patPos] == '$') {
      return if (txtPos == txtLen) regexMatch(pat, patLen, txt, txtLen, txtPos, patPos + 1, ci) else null;
    };

    let (atomFn, nextPat) : (Char -> Bool, Nat) = if (pat[patPos] == '\\' and patPos + 1 < patLen) {
      let esc = pat[patPos + 1];
      (func(c : Char) : Bool { normChar(c) == normChar(esc) }, patPos + 2);
    } else if (pat[patPos] == '[') {
      let (fn, np) = parseCharClass(pat, patPos + 1);
      (if (ci) { func(c : Char) : Bool { fn(normChar(c)) } } else fn, np);
    } else if (pat[patPos] == '.') {
      (func(_ : Char) : Bool { true }, patPos + 1);
    } else {
      let ch = pat[patPos];
      (func(c : Char) : Bool { normChar(c) == normChar(ch) }, patPos + 1);
    };

    let quant : ?Char = if (nextPat < patLen) {
      let q = pat[nextPat];
      if (q == '*' or q == '+' or q == '?') ?q else null;
    } else null;
    let restPat = switch (quant) { case (?_) nextPat + 1; case null nextPat };

    switch (quant) {
      case (?'?') {
        if (txtPos < txtLen and atomFn(txt[txtPos])) {
          switch (regexMatch(pat, patLen, txt, txtLen, txtPos + 1, restPat, ci)) {
            case (?r) return ?r; case null {};
          };
        };
        regexMatch(pat, patLen, txt, txtLen, txtPos, restPat, ci);
      };
      case (?'*') {
        var maxE = txtPos;
        label sc while (maxE < txtLen and atomFn(txt[maxE])) { maxE += 1 };
        var tp = maxE;
        label sb loop {
          switch (regexMatch(pat, patLen, txt, txtLen, tp, restPat, ci)) {
            case (?r) return ?r;
            case null { if (tp == txtPos) break sb; tp -= 1 };
          };
        };
        null;
      };
      case (?'+') {
        if (txtPos >= txtLen or not atomFn(txt[txtPos])) return null;
        var maxE = txtPos + 1;
        label pc while (maxE < txtLen and atomFn(txt[maxE])) { maxE += 1 };
        var tp = maxE;
        label pb loop {
          switch (regexMatch(pat, patLen, txt, txtLen, tp, restPat, ci)) {
            case (?r) return ?r;
            case null { if (tp == txtPos + 1) break pb; tp -= 1 };
          };
        };
        null;
      };
      case _ {
        if (txtPos < txtLen and atomFn(txt[txtPos])) regexMatch(pat, patLen, txt, txtLen, txtPos + 1, restPat, ci)
        else null;
      };
    };
  };

  func handle_regex_search(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let pattern = jsonGetStrDefault(inputJson, "pattern", "");
    if (pattern.size() == 0) return err("INVALID_INPUT", "pattern must be non-empty");
    let flags = jsonGetStrDefault(inputJson, "flags", "");
    let ci = flags.contains(#text "i");
    let globalFlag = flags.contains(#text "g");
    let returnAllRaw = jsonGetStrDefault(inputJson, "return_all_matches", "true");
    let returnAll = returnAllRaw != "false" or globalFlag;
    let includePosRaw = jsonGetStrDefault(inputJson, "include_positions", "false");
    let includePos = includePosRaw == "true";
    let ctxCharsRaw = jsonGetStrDefault(inputJson, "context_chars", "0");
    let ctxChars = switch (Nat.fromText(ctxCharsRaw.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let matchLimitRaw = jsonGetStrDefault(inputJson, "match_limit", "100");
    let matchLimit = switch (Nat.fromText(matchLimitRaw.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 100 };

    let patChars = pattern.toArray();
    let patLen = patChars.size();
    let txtChars = content.toArray();
    let txtLen = txtChars.size();
    let matchObjs = List.empty<Text>();
    var matchCount = 0;
    var searchPos = 0;

    label matchLoop while (searchPos <= txtLen and matchCount < matchLimit) {
      switch (regexMatch(patChars, patLen, txtChars, txtLen, searchPos, 0, ci)) {
        case (?endPos) {
          matchCount += 1;
          let matchStr = Text.fromIter(txtChars.sliceToArray(searchPos.toInt(), endPos.toInt()).values());
          var obj = "{\"match\": \"" # escapeJson(matchStr) # "\"";
          if (includePos) obj := obj # ", \"position\": " # searchPos.toText();
          if (ctxChars > 0) {
            let ctxStart = if (searchPos >= ctxChars) searchPos - ctxChars else 0;
            let ctxEnd = Nat.min(endPos + ctxChars, txtLen);
            let ctx = Text.fromIter(txtChars.sliceToArray(ctxStart.toInt(), ctxEnd.toInt()).values());
            obj := obj # ", \"context\": \"" # escapeJson(ctx) # "\"";
          };
          matchObjs.add(obj # "}");
          if (not returnAll) break matchLoop;
          searchPos := if (endPos > searchPos) endPos else searchPos + 1;
        };
        case null {
          searchPos += 1;
          // If pattern starts with ^, it can only match at position 0
          if (patLen > 0 and patChars[0] == '^') break matchLoop;
        };
      };
    };

    let found = matchCount > 0;
    ok("{\"found\": " # (if found "true" else "false") # ", \"match_count\": " # matchCount.toText() # ", \"matches\": [" # matchObjs.toArray().values().join(", ") # "], \"pattern\": \"" # escapeJson(pattern) # "\"}");
  };

  func handle_substring_search(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let sub = jsonGetStrDefault(inputJson, "substring", "");
    if (sub.size() == 0) return err("INVALID_INPUT", "substring must be non-empty");
    let caseSensRaw = jsonGetStrDefault(inputJson, "case_sensitive", "false");
    let caseSens = caseSensRaw == "true";
    let returnAllRaw = jsonGetStrDefault(inputJson, "return_all_indices", "true");
    let returnAllIndices = returnAllRaw != "false";
    let overlapRaw = jsonGetStrDefault(inputJson, "overlap", "false");
    let overlap = overlapRaw == "true";
    let ctxCharsRaw = jsonGetStrDefault(inputJson, "context_chars", "0");
    let ctxChars = switch (Nat.fromText(ctxCharsRaw.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let maxMatchesRaw = jsonGetStr(inputJson, "max_matches");
    let maxMatches : ?Nat = switch (maxMatchesRaw) {
      case null null;
      case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' })));
    };

    let haystack = if (caseSens) content else content.toLower();
    let needle = if (caseSens) sub else sub.toLower();
    let haystackChars = haystack.toArray();
    let origChars = content.toArray();
    let needleSize = needle.size();
    let total = haystackChars.size();
    let positions = List.empty<Nat>();
    let matchObjs = List.empty<Text>();
    var pos = 0;
    var matchCount = 0;

    label subLoop while (pos + needleSize <= total) {
      switch (maxMatches) { case (?m) { if (matchCount >= m) break subLoop }; case null {} };
      let slice = Text.fromIter(haystackChars.sliceToArray(pos.toInt(), (pos + needleSize).toInt()).values());
      if (Text.equal(slice, needle)) {
        matchCount += 1;
        positions.add(pos);
        if (returnAllIndices) {
          let matchStr = Text.fromIter(origChars.sliceToArray(pos.toInt(), (pos + needleSize).toInt()).values());
          var obj = "{\"match\": \"" # escapeJson(matchStr) # "\", \"position\": " # pos.toText();
          if (ctxChars > 0) {
            let ctxStart = if (pos >= ctxChars) pos - ctxChars else 0;
            let ctxEnd = Nat.min(pos + needleSize + ctxChars, total);
            let ctx = Text.fromIter(origChars.sliceToArray(ctxStart.toInt(), ctxEnd.toInt()).values());
            obj := obj # ", \"context\": \"" # escapeJson(ctx) # "\"";
          };
          matchObjs.add(obj # "}");
        };
        pos := if (overlap) pos + 1 else pos + needleSize;
      } else {
        pos += 1;
      };
    };

    let posArr = positions.toArray();
    let posJson = "[" # posArr.values().map(func(p : Nat) : Text { p.toText() }).join(", ") # "]";
    let found = matchCount > 0;
    ok("{\"found\": " # (if found "true" else "false") # ", \"match_count\": " # matchCount.toText() # ", \"positions\": " # posJson # ", \"matches\": [" # matchObjs.toArray().values().join(", ") # "], \"substring\": \"" # escapeJson(sub) # "\"}");
  };

  // Storage: canister-state in-memory map (injected from actor state)
  // Envelope format stored as JSON: {"value":"...","metadata":"...","tags":[...],"created_at":N,"expires_at":N_or_null}
  // TTL is lazily checked on read — expired entries are treated as missing.

  func nowSeconds() : Int {
    Time.now() / 1_000_000_000
  };

  // Build a storage envelope JSON string
  func makeEnvelope(value : Text, metadataRaw : Text, tagsRaw : Text, createdAt : Int, expiresAt : ?Int) : Text {
    let expiresStr = switch (expiresAt) { case null "null"; case (?t) t.toText() };
    "{\"value\":\"" # escapeJson(value) # "\",\"metadata\":" # metadataRaw # ",\"tags\":" # tagsRaw # ",\"created_at\":" # createdAt.toText() # ",\"expires_at\":" # expiresStr # "}"
  };

  // Extract the "value" field from an envelope
  func envelopeValue(envelope : Text) : Text {
    jsonGetStrDefault(envelope, "value", "")
  };

  // Check if an envelope is expired (returns true if expired, false if live or no TTL)
  func isExpired(envelope : Text) : Bool {
    switch (jsonGetStr(envelope, "expires_at")) {
      case null false;
      case (?raw) {
        let t = raw.trim(#predicate(func(c : Char) { c == ' ' }));
        if (t == "null") false
        else switch (Int.fromText(t)) {
          case null false;
          case (?exp) nowSeconds() >= exp;
        };
      };
    };
  };

  // Get envelope from store, return null if not found or expired
  func getLiveEnvelope(key : Text, objectStore : Map.Map<Text, Text>) : ?Text {
    switch (objectStore.get(key)) {
      case null null;
      case (?env) {
        if (isExpired(env)) { objectStore.remove(key); null }
        else ?env;
      };
    };
  };

  // Parse tags from envelope into a JSON array string for output
  func envelopeTags(envelope : Text) : Text {
    switch (jsonGetStr(envelope, "tags")) {
      case null "[]";
      case (?t) {
        let trimmed = t.trim(#predicate(func(c : Char) { c == ' ' }));
        if (trimmed.startsWith(#text "[")) trimmed else "[]"
      };
    };
  };

  // Parse tags raw array and check if all filter tags are present
  func tagsContainAll(envelope : Text, filterTags : [Text]) : Bool {
    if (filterTags.size() == 0) return true;
    let tagsRaw = envelopeTags(envelope);
    let storedTags = splitJsonArray(tagsRaw);
    let normalizedStored = storedTags.map(func(t) {
      t.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }))
    });
    filterTags.all(func(ft : Text) : Bool {
      normalizedStored.find(func(st : Text) : Bool { st == ft }) != null
    });
  };

  func handle_store_object(inputJson : Text, objectStore : Map.Map<Text, Text>) : ExecResult {
    let key = jsonGetStrDefault(inputJson, "key", "");
    let value = jsonGetStrDefault(inputJson, "value", "");
    if (key.size() == 0) return err("INVALID_INPUT", "key must be non-empty");

    let overwrite = jsonGetStrDefault(inputJson, "overwrite", "true") != "false";
    let returnStored = jsonGetStrDefault(inputJson, "return_stored", "false") == "true";

    // Check overwrite=false: fail if key exists and not expired
    if (not overwrite) {
      switch (getLiveEnvelope(key, objectStore)) {
        case (?_) {
          return ok("{\"key\": \"" # escapeJson(key) # "\", \"stored\": false, \"created_at\": null, \"expires_at\": null, \"size_bytes\": " # value.size().toText() # "}");
        };
        case null {};
      };
    };

    let now = nowSeconds();

    // Parse TTL
    let ttlRaw = jsonGetStr(inputJson, "ttl_seconds");
    let expiresAt : ?Int = switch (ttlRaw) {
      case null null;
      case (?t) {
        let trimmed = t.trim(#predicate(func(c : Char) { c == ' ' }));
        if (trimmed == "null" or trimmed == "0") null
        else switch (Int.fromText(trimmed)) {
          case null null;
          case (?secs) if (secs > 0) ?(now + secs) else null;
        };
      };
    };

    // Parse metadata (store as-is JSON string, default "{}")
    let metadataRaw = switch (jsonGetStr(inputJson, "metadata")) {
      case null "null";
      case (?m) {
        let mt = m.trim(#predicate(func(c : Char) { c == ' ' }));
        if (mt.startsWith(#text "{")) mt
        else if (mt == "null") "null"
        else "null"
      };
    };

    // Parse tags (store as-is JSON array string, default "[]")
    let tagsRaw = switch (jsonGetStr(inputJson, "tags")) {
      case null "[]";
      case (?t) {
        let tt = t.trim(#predicate(func(c : Char) { c == ' ' }));
        if (tt.startsWith(#text "[")) tt else "[]"
      };
    };

    let envelope = makeEnvelope(value, metadataRaw, tagsRaw, now, expiresAt);
    objectStore.add(key, envelope);

    let expiresStr = switch (expiresAt) { case null "null"; case (?e) e.toText() };
    var resp = "{\"key\": \"" # escapeJson(key) # "\", \"stored\": true, \"created_at\": " # now.toText() # ", \"expires_at\": " # expiresStr # ", \"size_bytes\": " # value.size().toText();
    if (returnStored) { resp := resp # ", \"value\": \"" # escapeJson(value) # "\"" };
    ok(resp # "}");
  };

  func handle_retrieve_object(inputJson : Text, objectStore : Map.Map<Text, Text>) : ExecResult {
    let key = jsonGetStrDefault(inputJson, "key", "");
    let includeMeta = jsonGetStrDefault(inputJson, "include_metadata", "false") == "true";
    let fallbackOpt = jsonGetStr(inputJson, "fallback_value");

    let fallbackStr = switch (fallbackOpt) {
      case null "null";
      case (?fb) {
        let t = fb.trim(#predicate(func(c : Char) { c == ' ' }));
        if (t == "null") "null" else "\"" # escapeJson(fb) # "\"";
      };
    };

    switch (getLiveEnvelope(key, objectStore)) {
      case null {
        var resp = "{\"key\": \"" # escapeJson(key) # "\", \"value\": " # fallbackStr # ", \"found\": false";
        if (includeMeta) resp := resp # ", \"metadata\": null, \"tags\": [], \"created_at\": null, \"expires_at\": null";
        ok(resp # "}");
      };
      case (?envelope) {
        let rawValue = envelopeValue(envelope);
        var resp = "{\"key\": \"" # escapeJson(key) # "\", \"value\": \"" # escapeJson(rawValue) # "\", \"found\": true";
        if (includeMeta) {
          let metaRaw = switch (jsonGetStr(envelope, "metadata")) { case null "null"; case (?m) m };
          let tagsRaw = envelopeTags(envelope);
          let createdRaw = switch (jsonGetStr(envelope, "created_at")) { case null "null"; case (?c) c };
          let expiresRaw = switch (jsonGetStr(envelope, "expires_at")) { case null "null"; case (?e) e };
          resp := resp # ", \"metadata\": " # metaRaw # ", \"tags\": " # tagsRaw # ", \"created_at\": " # createdRaw # ", \"expires_at\": " # expiresRaw;
        };
        ok(resp # "}");
      };
    };
  };

  // Shallow merge two JSON object strings — later keys win
  func shallowMergeJson(base : Text, override_ : Text) : Text {
    let merged = Map.empty<Text, Text>();
    for (k in jsonKeys(base).values()) {
      switch (jsonGetStr(base, k)) { case (?v) merged.add(k, v); case null {} };
    };
    for (k in jsonKeys(override_).values()) {
      switch (jsonGetStr(override_, k)) { case (?v) merged.add(k, v); case null {} };
    };
    let pairs = List.empty<Text>();
    for ((k, v) in merged.entries()) {
      let vType = detectType(v);
      let vQuoted = if (vType == "string") "\"" # escapeJson(v) # "\"" else v;
      pairs.add("\"" # escapeJson(k) # "\": " # vQuoted);
    };
    "{" # pairs.values().join(", ") # "}"
  };

  func handle_update_object(inputJson : Text, objectStore : Map.Map<Text, Text>) : ExecResult {
    let key = jsonGetStrDefault(inputJson, "key", "");
    let newValue = jsonGetStrDefault(inputJson, "value", "");
    let mergeStrategy = jsonGetStrDefault(inputJson, "merge_strategy", "replace");
    let onlyIfExists = jsonGetStrDefault(inputJson, "only_if_exists", "false") == "true";
    let preserveMeta = jsonGetStrDefault(inputJson, "preserve_metadata", "true") != "false";
    let returnPrev = jsonGetStrDefault(inputJson, "return_previous", "false") == "true";
    let now = nowSeconds();

    // Parse new TTL
    let newTtlOpt = jsonGetStr(inputJson, "ttl_seconds");

    let existingEnvelope = getLiveEnvelope(key, objectStore);

    switch (existingEnvelope) {
      case null {
        if (onlyIfExists) {
          var resp = "{\"key\": \"" # escapeJson(key) # "\", \"updated\": false, \"merge_strategy\": \"" # escapeJson(mergeStrategy) # "\", \"updated_at\": " # now.toText();
          if (returnPrev) resp := resp # ", \"previous_value\": null";
          return ok(resp # "}");
        };
        // Key doesn't exist — create new entry
        let expiresAt : ?Int = switch (newTtlOpt) {
          case null null;
          case (?t) {
            let trimmed = t.trim(#predicate(func(c : Char) { c == ' ' }));
            if (trimmed == "null" or trimmed == "0") null
            else switch (Int.fromText(trimmed)) { case null null; case (?s) if (s > 0) ?(now + s) else null };
          };
        };
        let envelope = makeEnvelope(newValue, "null", "[]", now, expiresAt);
        objectStore.add(key, envelope);
        let expiresStr = switch (expiresAt) { case null "null"; case (?e) e.toText() };
        var resp = "{\"key\": \"" # escapeJson(key) # "\", \"updated\": true, \"merge_strategy\": \"" # escapeJson(mergeStrategy) # "\", \"updated_at\": " # now.toText();
        if (returnPrev) resp := resp # ", \"previous_value\": null";
        return ok(resp # "}");
      };
      case (?existing) {
        let prevValue = envelopeValue(existing);

        // Compute merged value
        let finalValue = switch (mergeStrategy) {
          case "merge_shallow" {
            let et = prevValue.trim(#predicate(func(c : Char) { c == ' ' }));
            let nt = newValue.trim(#predicate(func(c : Char) { c == ' ' }));
            if (et.startsWith(#text "{") and nt.startsWith(#text "{")) shallowMergeJson(prevValue, newValue)
            else newValue;
          };
          case "merge_deep" {
            // Same as shallow merge for our implementation (no recursive JSON traversal without full parser)
            let et = prevValue.trim(#predicate(func(c : Char) { c == ' ' }));
            let nt = newValue.trim(#predicate(func(c : Char) { c == ' ' }));
            if (et.startsWith(#text "{") and nt.startsWith(#text "{")) shallowMergeJson(prevValue, newValue)
            else newValue;
          };
          case _ newValue; // replace
        };

        // Resolve metadata and tags
        let metaRaw = if (preserveMeta) {
          switch (jsonGetStr(existing, "metadata")) { case null "null"; case (?m) m }
        } else "null";
        let tagsRaw = if (preserveMeta) envelopeTags(existing) else "[]";

        // Resolve created_at (preserve original)
        let createdAt : Int = switch (jsonGetStr(existing, "created_at")) {
          case null now;
          case (?c) switch (Int.fromText(c.trim(#predicate(func(x : Char) { x == ' ' })))) { case null now; case (?t) t };
        };

        // Resolve expires_at
        let expiresAt : ?Int = switch (newTtlOpt) {
          case null {
            // Preserve existing
            switch (jsonGetStr(existing, "expires_at")) {
              case null null;
              case (?e) {
                let et = e.trim(#predicate(func(c : Char) { c == ' ' }));
                if (et == "null") null
                else switch (Int.fromText(et)) { case null null; case (?t) ?t };
              };
            };
          };
          case (?t) {
            let trimmed = t.trim(#predicate(func(c : Char) { c == ' ' }));
            if (trimmed == "null") null
            else if (trimmed == "0") null
            else switch (Int.fromText(trimmed)) { case null null; case (?s) if (s > 0) ?(now + s) else null };
          };
        };

        let newEnvelope = makeEnvelope(finalValue, metaRaw, tagsRaw, createdAt, expiresAt);
        objectStore.add(key, newEnvelope);

        var resp = "{\"key\": \"" # escapeJson(key) # "\", \"updated\": true, \"merge_strategy\": \"" # escapeJson(mergeStrategy) # "\", \"updated_at\": " # now.toText();
        if (returnPrev) resp := resp # ", \"previous_value\": \"" # escapeJson(prevValue) # "\"";
        ok(resp # "}");
      };
    };
  };

  func handle_delete_object(inputJson : Text, objectStore : Map.Map<Text, Text>) : ExecResult {
    let softDelete = jsonGetStrDefault(inputJson, "soft_delete", "false") == "true";
    let returnDeleted = jsonGetStrDefault(inputJson, "return_deleted", "false") == "true";
    let errorOnMissing = jsonGetStrDefault(inputJson, "error_on_missing", "false") == "true";

    // Collect keys to delete from key or batch_keys
    let keysToDelete = List.empty<Text>();
    switch (jsonGetStr(inputJson, "batch_keys")) {
      case (?batchRaw) {
        let tokens = splitJsonArray(batchRaw);
        for (t in tokens.values()) {
          let k = t.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }));
          if (k.size() > 0) keysToDelete.add(k);
        };
      };
      case null {
        let k = jsonGetStrDefault(inputJson, "key", "");
        if (k.size() > 0) keysToDelete.add(k);
      };
    };

    if (keysToDelete.isEmpty()) {
      return err("INVALID_INPUT", "At least one of key or batch_keys must be provided");
    };

    let deletedKeys = List.empty<Text>();
    let notFoundKeys = List.empty<Text>();
    let deletedValues = List.empty<Text>();
    let now = nowSeconds();

    for (k in keysToDelete.values()) {
      switch (objectStore.get(k)) {
        case null { notFoundKeys.add(k) };
        case (?envelope) {
          if (isExpired(envelope)) {
            objectStore.remove(k);
            notFoundKeys.add(k);
          } else {
            if (returnDeleted) {
              let val = envelopeValue(envelope);
              deletedValues.add("{\"key\": \"" # escapeJson(k) # "\", \"value\": \"" # escapeJson(val) # "\"}");
            };
            if (softDelete) {
              // Mark as soft-deleted by updating metadata
              let metaBase = switch (jsonGetStr(envelope, "metadata")) {
                case null "{}"; case (?m) if (m.trim(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) m else "{}"
              };
              let softMeta = shallowMergeJson(metaBase, "{\"_deleted\": true, \"_deleted_at\": " # now.toText() # "}");
              let tagsRaw = envelopeTags(envelope);
              let createdAt : Int = switch (jsonGetStr(envelope, "created_at")) {
                case null now;
                case (?c) switch (Int.fromText(c.trim(#predicate(func(x : Char) { x == ' ' })))) { case null now; case (?t) t };
              };
              let expiresAt : ?Int = switch (jsonGetStr(envelope, "expires_at")) {
                case null null;
                case (?e) {
                  let et = e.trim(#predicate(func(c : Char) { c == ' ' }));
                  if (et == "null") null else switch (Int.fromText(et)) { case null null; case (?t) ?t };
                };
              };
              objectStore.add(k, makeEnvelope(envelopeValue(envelope), softMeta, tagsRaw, createdAt, expiresAt));
            } else {
              objectStore.remove(k);
            };
            deletedKeys.add(k);
          };
        };
      };
    };

    if (errorOnMissing and not notFoundKeys.isEmpty()) {
      return err("NOT_FOUND", "Keys not found: " # notFoundKeys.values().join(", "));
    };

    let deletedArr = deletedKeys.toArray();
    let notFoundArr = notFoundKeys.toArray();
    let dkJson = "[" # deletedArr.values().map(func(k : Text) : Text { "\"" # escapeJson(k) # "\"" }).join(", ") # "]";
    let nfJson = "[" # notFoundArr.values().map(func(k : Text) : Text { "\"" # escapeJson(k) # "\"" }).join(", ") # "]";
    var resp = "{\"deleted_keys\": " # dkJson # ", \"not_found_keys\": " # nfJson # ", \"delete_count\": " # deletedArr.size().toText() # ", \"soft_deleted\": " # (if softDelete "true" else "false");
    if (returnDeleted) {
      resp := resp # ", \"deleted_values\": [" # deletedValues.toArray().values().join(", ") # "]";
    };
    ok(resp # "}");
  };

  func handle_list_objects(inputJson : Text, objectStore : Map.Map<Text, Text>) : ExecResult {
    let prefix = jsonGetStrDefault(inputJson, "prefix", "");
    let suffix = jsonGetStrDefault(inputJson, "suffix", "");
    let regexPatternOpt = jsonGetStr(inputJson, "regex_pattern");
    let includeExpired = jsonGetStrDefault(inputJson, "include_expired", "false") == "true";
    let includeMeta = jsonGetStrDefault(inputJson, "include_metadata", "false") == "true";
    let sortBy = jsonGetStrDefault(inputJson, "sort_by", "key");
    let sortOrder = jsonGetStrDefault(inputJson, "sort_order", "asc");
    let limit = switch (Nat.fromText(jsonGetStrDefault(inputJson, "limit", "100").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 100 };
    let offset = switch (Nat.fromText(jsonGetStrDefault(inputJson, "offset", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };

    // Parse tag filter
    let tagsFilterRaw = jsonGetStr(inputJson, "tags");
    let tagFilters : [Text] = switch (tagsFilterRaw) {
      case null [];
      case (?t) {
        let tt = t.trim(#predicate(func(c : Char) { c == ' ' }));
        if (tt.startsWith(#text "[")) {
          splitJsonArray(tt).map(func(tag) { tag.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' })) })
        } else [];
      };
    };

    // Build matched entries list: (key, envelope)
    // Collect expired keys separately to evict after iteration (avoid mutating map during iteration)
    let expiredToEvict = List.empty<Text>();
    let matched = List.empty<(Text, Text)>();
    for ((k, envelope) in objectStore.entries()) {
      // TTL check
      if (not includeExpired and isExpired(envelope)) {
        expiredToEvict.add(k);
      } else {
        // prefix filter
        if (prefix.size() == 0 or k.startsWith(#text prefix)) {
          // suffix filter
          if (suffix.size() == 0 or k.endsWith(#text suffix)) {
            // regex filter
            let passesRegex = switch (regexPatternOpt) {
              case null true;
              case (?pat) {
                let patChars = pat.toArray();
                let keyChars = k.toArray();
                let keyLen = keyChars.size();
                let patLen = patChars.size();
                var found = false;
                var sp = 0;
                label rl while (sp <= keyLen and not found) {
                  switch (regexMatch(patChars, patLen, keyChars, keyLen, sp, 0, false)) {
                    case (?_) found := true;
                    case null {
                      sp += 1;
                      if (patLen > 0 and patChars[0] == '^') break rl;
                    };
                  };
                };
                found;
              };
            };
            if (passesRegex) {
              // tag filter
              let passesTags = if (tagFilters.size() == 0) true
                else tagsContainAll(envelope, tagFilters);
              if (passesTags) {
                // skip soft-deleted entries unless include_expired is true
                let isSoftDeleted = switch (jsonGetStr(envelope, "metadata")) {
                  case null false;
                  case (?m) {
                    let delRaw = jsonGetStrDefault(m, "_deleted", "false");
                    delRaw == "true"
                  };
                };
                if (not isSoftDeleted or includeExpired) {
                  matched.add((k, envelope));
                };
              };
            };
          };
        };
      };
    };
    // Evict expired keys after iteration
    for (k in expiredToEvict.values()) { objectStore.remove(k) };

    // Sort
    let sortedList = matched.sort(func(entryA, entryB) {
      let (ka, envA) = entryA;
      let (kb, envB) = entryB;
      let cmp = switch (sortBy) {
        case "created_at" {
          let ca : Int = switch (jsonGetStr(envA, "created_at")) { case null 0; case (?c) switch (Int.fromText(c.trim(#predicate(func(x : Char) { x == ' ' })))) { case null 0; case (?t) t } };
          let cb : Int = switch (jsonGetStr(envB, "created_at")) { case null 0; case (?c) switch (Int.fromText(c.trim(#predicate(func(x : Char) { x == ' ' })))) { case null 0; case (?t) t } };
          Int.compare(ca, cb)
        };
        case "size" {
          let sa = envelopeValue(envA).size();
          let sb = envelopeValue(envB).size();
          Nat.compare(sa, sb)
        };
        case _ Text.compare(ka, kb);
      };
      if (sortOrder == "desc") switch (cmp) { case (#less) #greater; case (#greater) #less; case (#equal) #equal }
      else cmp
    });

    let allArr = sortedList.toArray();
    let totalCount = allArr.size();

    // Pagination
    let pagedArr = if (offset >= totalCount) []
      else if (limit == 0) allArr.sliceToArray(offset.toInt(), totalCount.toInt())
      else {
        let end = Nat.min(offset + limit, totalCount);
        allArr.sliceToArray(offset.toInt(), end.toInt())
      };

    let returnedCount = pagedArr.size();
    let hasMore = (offset + returnedCount) < totalCount;

    let keysList = List.empty<Text>();
    for ((k, _env) in pagedArr.values()) { keysList.add("\"" # escapeJson(k) # "\"") };
    let keysJson = "[" # keysList.toArray().values().join(", ") # "]";

    let itemsJson = if (not includeMeta) "[]"
    else {
      let items = List.empty<Text>();
      for ((k, env) in pagedArr.values()) {
        let sizeBytes = envelopeValue(env).size();
        let createdRaw = switch (jsonGetStr(env, "created_at")) { case null "null"; case (?c) c };
        let expiresRaw = switch (jsonGetStr(env, "expires_at")) { case null "null"; case (?e) e };
        let tagsRaw = envelopeTags(env);
        items.add("{\"key\": \"" # escapeJson(k) # "\", \"size_bytes\": " # sizeBytes.toText() # ", \"created_at\": " # createdRaw # ", \"expires_at\": " # expiresRaw # ", \"tags\": " # tagsRaw # "}");
      };
      "[" # items.toArray().values().join(", ") # "]"
    };

    ok("{\"keys\": " # keysJson # ", \"items\": " # itemsJson # ", \"total_count\": " # totalCount.toText() # ", \"returned_count\": " # returnedCount.toText() # ", \"has_more\": " # (if hasMore "true" else "false") # "}")
  };

  // ── Math expression evaluator ─────────────────────────────────────────────
  // Recursive-descent parser: +- < */% < ^ < unary- < parens

  type MathToken = { #num : Float; #plus; #minus; #mul; #div; #mod; #pow; #lparen; #rparen; #end_token };
  type ParseState = { var pos : Nat; tokens : [MathToken] };

  func tokenizeMath(expr : Text) : [MathToken] {
    let toks = List.empty<MathToken>();
    let chars = expr.toArray();
    let n = chars.size();
    var i = 0;
    while (i < n) {
      let c = chars[i];
      if (c == ' ' or c == '\t') { i += 1 }
      else if (c == '+') { toks.add(#plus);   i += 1 }
      else if (c == '-') { toks.add(#minus);  i += 1 }
      else if (c == '*') { toks.add(#mul);    i += 1 }
      else if (c == '/') { toks.add(#div);    i += 1 }
      else if (c == '%') { toks.add(#mod);    i += 1 }
      else if (c == '^') { toks.add(#pow);    i += 1 }
      else if (c == '(') { toks.add(#lparen); i += 1 }
      else if (c == ')') { toks.add(#rparen); i += 1 }
      else if ((c >= '0' and c <= '9') or c == '.') {
        var numStr = "";
        while (i < n and ((chars[i] >= '0' and chars[i] <= '9') or chars[i] == '.')) {
          numStr := numStr # chars[i].toText(); i += 1;
        };
        switch (parseFloat(numStr)) { case (?f) toks.add(#num(f)); case null toks.add(#num(0.0)) };
      } else { i += 1 };
    };
    toks.add(#end_token);
    toks.toArray()
  };

  func mathParseExpr(ps : ParseState) : ?Float { mathParseAddSub(ps) };

  func mathParseAddSub(ps : ParseState) : ?Float {
    switch (mathParseMulDiv(ps)) {
      case null null;
      case (?left) {
        var result = left; var go = true;
        while (go) {
          if (ps.pos >= ps.tokens.size()) { go := false }
          else switch (ps.tokens[ps.pos]) {
            case (#plus)  { ps.pos += 1; switch (mathParseMulDiv(ps)) { case (?r) result += r; case null go := false } };
            case (#minus) { ps.pos += 1; switch (mathParseMulDiv(ps)) { case (?r) result -= r; case null go := false } };
            case _ go := false;
          };
        };
        ?result
      };
    }
  };

  func mathParseMulDiv(ps : ParseState) : ?Float {
    switch (mathParsePow(ps)) {
      case null null;
      case (?left) {
        var result = left; var go = true;
        while (go) {
          if (ps.pos >= ps.tokens.size()) { go := false }
          else switch (ps.tokens[ps.pos]) {
            case (#mul) { ps.pos += 1; switch (mathParsePow(ps)) { case (?r) result *= r; case null go := false } };
            case (#div) { ps.pos += 1; switch (mathParsePow(ps)) { case (?r) { if (r == 0.0) go := false else result /= r }; case null go := false } };
            case (#mod) { ps.pos += 1; switch (mathParsePow(ps)) { case (?r) { if (r == 0.0) go := false else result := result - Float.floor(result / r) * r }; case null go := false } };
            case _ go := false;
          };
        };
        ?result
      };
    }
  };

  func mathParsePow(ps : ParseState) : ?Float {
    switch (mathParseUnary(ps)) {
      case null null;
      case (?base) {
        if (ps.pos < ps.tokens.size()) {
          switch (ps.tokens[ps.pos]) {
            case (#pow) { ps.pos += 1; switch (mathParsePow(ps)) { case (?e) ?Float.pow(base, e); case null ?base } };
            case _ ?base;
          }
        } else ?base
      };
    }
  };

  func mathParseUnary(ps : ParseState) : ?Float {
    if (ps.pos >= ps.tokens.size()) return null;
    switch (ps.tokens[ps.pos]) {
      case (#minus) { ps.pos += 1; switch (mathParseAtom(ps)) { case (?v) ?(-v); case null null } };
      case (#plus)  { ps.pos += 1; mathParseAtom(ps) };
      case _ mathParseAtom(ps);
    }
  };

  func mathParseAtom(ps : ParseState) : ?Float {
    if (ps.pos >= ps.tokens.size()) return null;
    switch (ps.tokens[ps.pos]) {
      case (#num(v)) { ps.pos += 1; ?v };
      case (#lparen) {
        ps.pos += 1;
        switch (mathParseExpr(ps)) {
          case (?v) {
            if (ps.pos < ps.tokens.size()) { switch (ps.tokens[ps.pos]) { case (#rparen) ps.pos += 1; case _ {} } };
            ?v
          };
          case null null;
        }
      };
      case _ null;
    }
  };

  func substituteVars(expr : Text, varJson : Text) : Text {
    var result = expr;
    for (k in jsonKeys(varJson).values()) {
      switch (jsonGetStr(varJson, k)) {
        case (?v) result := result.replace(#text k, v.trim(#predicate(func(c : Char) { c == ' ' })));
        case null {};
      };
    };
    result
  };

  func roundFloat_(f : Float, precision : Nat, mode : Text) : Float {
    let factor = Float.pow(10.0, precision.toFloat());
    let shifted = f * factor;
    let floored = Float.floor(shifted);
    let frac = shifted - floored;
    let rounded = switch (mode) {
      case "floor"     floored;
      case "ceiling"   Float.ceil(shifted);
      case "truncate"  if (f >= 0.0) floored else Float.ceil(shifted);
      case "half_down" if (frac > 0.5) floored + 1.0 else floored;
      case _           if (frac >= 0.5) floored + 1.0 else floored;
    };
    rounded / factor
  };

  func floatPrec(f : Float, precision : Nat) : Text {
    if (precision == 0) {
      Float.floor(if (f >= 0.0) f + 0.5 else f - 0.5).toInt().toText()
    } else {
      let factor = Float.pow(10.0, precision.toFloat());
      let absF = Float.abs(f);
      let rounded = Float.floor(absF * factor + 0.5);
      let intPart = Float.floor(rounded / factor).toInt();
      let fracPart = (rounded - Float.floor(rounded / factor) * factor).toInt();
      let sign = if (f < 0.0 and (intPart != 0 or fracPart != 0)) "-" else "";
      let fracStr = fracPart.toText();
      let padded = if (fracStr.size() < precision) Text.fromIter(Iter.repeat('0', precision - fracStr.size())) # fracStr else fracStr;
      sign # intPart.toText() # "." # padded
    }
  };

  func handle_compute_math(inputJson : Text) : ExecResult {
    let exprRaw = switch (jsonGetStr(inputJson, "expression")) {
      case (?v) v; case null jsonGetStrDefault(inputJson, "expr", "")
    };
    if (exprRaw.trim(#predicate(func(c : Char) { c == ' ' })).size() == 0) return err("INVALID_INPUT", "expression is required");
    let precision = switch (Nat.fromText(jsonGetStrDefault(inputJson, "precision", "10").trim(#predicate(func(c : Char) { c == ' ' })))) {
      case (?pn) if (pn > 15) 15 else pn; case null 10
    };
    let roundingMode = jsonGetStrDefault(inputJson, "rounding_mode", "half_up");
    let outputFormat = jsonGetStrDefault(inputJson, "output_format", "number");
    let varJsonRaw = switch (jsonGetStr(inputJson, "variables")) { case (?v) v; case null "{}" };
    let substituted = substituteVars(exprRaw, varJsonRaw);
    let tokens = tokenizeMath(substituted);
    let ps : ParseState = { var pos = 0; tokens };
    switch (mathParseExpr(ps)) {
      case null err("EVAL_ERROR", "Could not evaluate expression: " # substituted);
      case (?rawResult) {
        let rounded = roundFloat_(rawResult, precision, roundingMode);
        let wasRounded = Float.abs(rawResult - rounded) > 1e-12;
        let resultStr = if (outputFormat == "string") "\"" # floatPrec(rounded, precision) # "\"" else floatPrec(rounded, precision);
        ok("{\"result\": " # resultStr # ", \"expression_evaluated\": \"" # escapeJson(substituted) # "\", \"precision\": " # precision.toText() # ", \"rounded\": " # (if wasRounded "true" else "false") # "}");
      };
    };
  };

  // ── Statistical helpers ────────────────────────────────────────────────────

  func computeMedian_(sorted : [Float]) : Float {
    let n = sorted.size();
    if (n == 0) return 0.0;
    if (n % 2 == 1) sorted[n / 2]
    else (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0
  };

  func computeMode_(arr : [Float]) : Float {
    if (arr.size() == 0) return 0.0;
    let freqMap = Map.empty<Text, Nat>();
    for (fv in arr.values()) {
      let key = floatToText(fv);
      let cur = switch (freqMap.get(key)) { case (?cn) cn; case null 0 };
      freqMap.add(key, cur + 1);
    };
    var bestKey = floatToText(arr[0]);
    var bestCount = 0;
    for ((k, cnt) in freqMap.entries()) {
      if (cnt > bestCount) { bestCount := cnt; bestKey := k };
    };
    switch (parseFloat(bestKey)) { case (?f) f; case null arr[0] }
  };

  func computePercentile_(sorted : [Float], pct : Float) : Float {
    let n = sorted.size();
    if (n == 0) return 0.0;
    if (n == 1) return sorted[0];
    let pos = pct / 100.0 * (n.toFloat() - 1.0);
    let lo = Float.floor(pos).toInt().toNat();
    let hi = if (lo + 1 >= n) n - 1 else lo + 1;
    let frac = pos - lo.toFloat();
    sorted[lo] * (1.0 - frac) + sorted[hi] * frac
  };

  func sortFloats_(arr : [Float]) : [Float] {
    arr.sort(func(a, b) { if (a < b) #less else if (a > b) #greater else #equal })
  };

  func statsBlock_(arr : [Float]) : (Float, Float, Float, Float, Float) {
    // (sum, min, max, mean, stddev)
    if (arr.size() == 0) return (0.0, 0.0, 0.0, 0.0, 0.0);
    var s = 0.0; var lo = arr[0]; var hi = arr[0];
    for (v in arr.values()) { s += v; if (v < lo) lo := v; if (v > hi) hi := v };
    let m = s / arr.size().toFloat();
    var vr = 0.0;
    for (v in arr.values()) { let d = v - m; vr += d * d };
    vr /= arr.size().toFloat();
    (s, lo, hi, m, Float.sqrt(vr))
  };

  func extractNums_(contentRaw : Text, fieldOpt : ?Text, excludeNulls : Bool) : [Float] {
    let nums = List.empty<Float>();
    let items = splitJsonArray(contentRaw);
    if (items.size() == 0) return [];
    let isObjects = items[0].trim(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{");
    for (item in items.values()) {
      let raw : ?Text = if (isObjects) {
        switch (fieldOpt) { case (?f) jsonGetStr(item, f); case null jsonGetStr(item, "value") }
      } else {
        ?item.trim(#predicate(func(c : Char) { c == ' ' }))
      };
      switch (raw) {
        case null { if (not excludeNulls) nums.add(0.0) };
        case (?v) {
          let vt = v.trim(#predicate(func(c : Char) { c == ' ' }));
          if (vt == "null" or vt == "") {
            if (not excludeNulls) nums.add(0.0);
          } else {
            switch (parseFloat(vt)) {
              case (?fn) nums.add(fn);
              case null { if (not excludeNulls) nums.add(0.0) };
            };
          };
        };
      };
    };
    nums.toArray()
  };

  func statsJson_(arr : [Float], prec : Nat) : Text {
    let sorted = sortFloats_(arr);
    if (arr.size() == 0) return "{\"min\": 0, \"max\": 0, \"mean\": 0, \"stddev\": 0, \"median\": 0}";
    let (_, minS, maxS, meanS, stddevS) = statsBlock_(arr);
    let medianS = computeMedian_(sorted);
    "{\"min\": " # floatPrec(minS, prec) # ", \"max\": " # floatPrec(maxS, prec) # ", \"mean\": " # floatPrec(meanS, prec) # ", \"stddev\": " # floatPrec(stddevS, prec) # ", \"median\": " # floatPrec(medianS, prec) # "}"
  };

  func handle_aggregate_data(inputJson : Text) : ExecResult {
    let contentRaw = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "values", "[]") };
    if (contentRaw.trim(#predicate(func(c : Char) { c == ' ' })).size() == 0) return err("INVALID_INPUT", "content is required");
    let fieldOpt = jsonGetStr(inputJson, "field");
    let opsRaw = jsonGetStrDefault(inputJson, "operations", "[]");
    let groupingFieldOpt = jsonGetStr(inputJson, "grouping_field");
    let prec = switch (Nat.fromText(jsonGetStrDefault(inputJson, "precision", "4").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?pn) pn; case null 4 };
    let excludeNulls = jsonGetStrDefault(inputJson, "exclude_nulls", "true") != "false";
    let excludeOutliers = jsonGetStrDefault(inputJson, "exclude_outliers", "false") == "true";

    let opTokens = splitJsonArray(opsRaw);
    let reqOps : [Text] = if (opTokens.size() == 0) {
      ["sum","min","max","mean","count","median","mode","stddev","variance","range","percentile_25","percentile_75","percentile_90","percentile_95","percentile_99"]
    } else {
      opTokens.map(func(t) { t.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' })) })
    };

    func computeOps(arr : [Float]) : Text {
      if (arr.size() == 0) {
        return "{" # reqOps.values().map(func(o : Text) : Text { "\"" # escapeJson(o) # "\": 0" }).join(", ") # "}";
      };
      var work = arr;
      if (excludeOutliers and arr.size() >= 3) {
        let (_, _, _, mOE, sdOE) = statsBlock_(arr);
        if (sdOE > 0.0) work := arr.filter(func(v : Float) : Bool { Float.abs(v - mOE) <= 3.0 * sdOE });
      };
      let sorted = sortFloats_(work);
      let cnt = work.size();
      let (sumA, minA, maxA, meanA, sdA) = statsBlock_(work);
      let varA = sdA * sdA;
      let medA = computeMedian_(sorted);
      let modA = computeMode_(work);
      let pairs = List.empty<Text>();
      for (op in reqOps.values()) {
        let v = switch (op) {
          case "sum"           floatPrec(sumA, prec);
          case "min"           floatPrec(minA, prec);
          case "max"           floatPrec(maxA, prec);
          case "mean"          floatPrec(meanA, prec);
          case "count"         cnt.toText();
          case "median"        floatPrec(medA, prec);
          case "mode"          floatPrec(modA, prec);
          case "stddev"        floatPrec(sdA, prec);
          case "variance"      floatPrec(varA, prec);
          case "range"         floatPrec(maxA - minA, prec);
          case "percentile_25" floatPrec(computePercentile_(sorted, 25.0), prec);
          case "percentile_75" floatPrec(computePercentile_(sorted, 75.0), prec);
          case "percentile_90" floatPrec(computePercentile_(sorted, 90.0), prec);
          case "percentile_95" floatPrec(computePercentile_(sorted, 95.0), prec);
          case "percentile_99" floatPrec(computePercentile_(sorted, 99.0), prec);
          case _ "null";
        };
        pairs.add("\"" # escapeJson(op) # "\": " # v);
      };
      "{" # pairs.values().join(", ") # "}"
    };

    let fieldStr = switch (fieldOpt) { case (?f) "\"" # escapeJson(f) # "\""; case null "null" };

    switch (groupingFieldOpt) {
      case (?gf) {
        let items = splitJsonArray(contentRaw);
        let groupMap = Map.empty<Text, List.List<Float>>();
        let groupOrder = List.empty<Text>();
        for (item in items.values()) {
          let gk = jsonGetStrDefault(item, gf, "__missing__");
          let valOpt : ?Float = switch (fieldOpt) {
            case (?f) { switch (jsonGetStr(item, f)) { case (?v) parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' }))); case null null } };
            case null null;
          };
          switch (valOpt) {
            case null {};
            case (?fv) {
              switch (groupMap.get(gk)) {
                case null { let lst = List.empty<Float>(); lst.add(fv); groupMap.add(gk, lst); groupOrder.add(gk) };
                case (?lst) lst.add(fv);
              };
            };
          };
        };
        let groupPairs = List.empty<Text>();
        let seenGrps = Set.empty<Text>();
        for (gk2 in groupOrder.values()) {
          if (not seenGrps.contains(gk2)) {
            seenGrps.add(gk2);
            switch (groupMap.get(gk2)) {
              case null {};
              case (?lst) groupPairs.add("\"" # escapeJson(gk2) # "\": " # computeOps(lst.toArray()));
            };
          };
        };
        let allNums = extractNums_(contentRaw, fieldOpt, excludeNulls);
        ok("{\"results\": " # computeOps(allNums) # ", \"count\": " # allNums.size().toText() # ", \"grouped_results\": {" # groupPairs.values().join(", ") # "}, \"field\": " # fieldStr # "}");
      };
      case null {
        let allNums = extractNums_(contentRaw, fieldOpt, excludeNulls);
        ok("{\"results\": " # computeOps(allNums) # ", \"count\": " # allNums.size().toText() # ", \"grouped_results\": null, \"field\": " # fieldStr # "}");
      };
    };
  };

  func handle_compare_values(inputJson : Text) : ExecResult {
    let v1Raw = switch (jsonGetStr(inputJson, "value1")) { case (?v) v; case null jsonGetStrDefault(inputJson, "a", "") };
    let v2Raw = switch (jsonGetStr(inputJson, "value2")) { case (?v) v; case null jsonGetStrDefault(inputJson, "b", "") };
    let operator = switch (jsonGetStr(inputJson, "operator")) { case (?v) v; case null jsonGetStrDefault(inputJson, "op", "eq") };
    let typePref = jsonGetStrDefault(inputJson, "type", "auto");
    let caseSensitive = jsonGetStrDefault(inputJson, "case_sensitive", "false") == "true";
    let floatTol = switch (parseFloat(jsonGetStrDefault(inputJson, "float_tolerance", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?f) f; case null 0.0 };
    let nullHandling = jsonGetStrDefault(inputJson, "null_handling", "error");
    let negate = jsonGetStrDefault(inputJson, "negate", "false") == "true";

    let v1t = v1Raw.trim(#predicate(func(c : Char) { c == ' ' }));
    let v2t = v2Raw.trim(#predicate(func(c : Char) { c == ' ' }));
    let v1Empty = v1t.size() == 0 or v1t == "null";
    let v2Empty = v2t.size() == 0 or v2t == "null";
    if (v1Empty or v2Empty) {
      switch (nullHandling) {
        case "error" return err("NULL_VALUE", "null/empty value; set null_handling to handle gracefully");
        case "false" {
          let r = if (negate) "true" else "false";
          return ok("{\"result\": " # r # ", \"value1_coerced\": \"" # escapeJson(v1Raw) # "\", \"value2_coerced\": \"" # escapeJson(v2Raw) # "\", \"operator\": \"" # escapeJson(operator) # "\", \"type_used\": \"null\"}");
        };
        case _ {};
      };
    };

    let v1Num = parseFloat(v1t);
    let v2Num = parseFloat(v2t);
    let typeUsed = switch (typePref) {
      case "number" "number";
      case "string" "string";
      case "boolean" "boolean";
      case _ if (v1Num != null and v2Num != null) "number" else "string";
    };

    let v1c = if (caseSensitive or typeUsed == "number") v1t else v1Raw.toLower().trim(#predicate(func(c : Char) { c == ' ' }));
    let v2c = if (caseSensitive or typeUsed == "number") v2t else v2Raw.toLower().trim(#predicate(func(c : Char) { c == ' ' }));

    let baseResult : Bool = switch (operator) {
      case "eq" {
        if (typeUsed == "number") { switch (v1Num, v2Num) { case (?a, ?b) Float.abs(a - b) <= floatTol; case _ v1c == v2c } }
        else v1c == v2c;
      };
      case "neq" {
        if (typeUsed == "number") { switch (v1Num, v2Num) { case (?a, ?b) Float.abs(a - b) > floatTol; case _ v1c != v2c } }
        else v1c != v2c;
      };
      case "gt"  { switch (v1Num, v2Num) { case (?a, ?b) a > b; case _ v1c > v2c } };
      case "gte" { switch (v1Num, v2Num) { case (?a, ?b) a >= b; case _ v1c >= v2c } };
      case "lt"  { switch (v1Num, v2Num) { case (?a, ?b) a < b; case _ v1c < v2c } };
      case "lte" { switch (v1Num, v2Num) { case (?a, ?b) a <= b; case _ v1c <= v2c } };
      case "contains"      { v1c.contains(#text v2c) };
      case "starts_with"   { v1c.startsWith(#text v2c) };
      case "ends_with"     { v1c.endsWith(#text v2c) };
      case "matches_regex" { v1c.contains(#text v2c) };
      case _ false;
    };

    let result = if (negate) not baseResult else baseResult;
    ok("{\"result\": " # (if result "true" else "false") # ", \"value1_coerced\": \"" # escapeJson(v1c) # "\", \"value2_coerced\": \"" # escapeJson(v2c) # "\", \"operator\": \"" # escapeJson(operator) # "\", \"type_used\": \"" # escapeJson(typeUsed) # "\"}");
  };

  func handle_normalize_values(inputJson : Text) : ExecResult {
    let contentRaw = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "values", "[]") };
    if (contentRaw.trim(#predicate(func(c : Char) { c == ' ' })).size() == 0) return err("INVALID_INPUT", "content is required");
    let fieldOpt = jsonGetStr(inputJson, "field");
    let method = jsonGetStrDefault(inputJson, "method", "minmax");
    let targetMin = switch (parseFloat(jsonGetStrDefault(inputJson, "target_min", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?f) f; case null 0.0 };
    let targetMax = switch (parseFloat(jsonGetStrDefault(inputJson, "target_max", "1").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?f) f; case null 1.0 };
    let prec = switch (Nat.fromText(jsonGetStrDefault(inputJson, "precision", "6").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?pn) pn; case null 6 };
    let handleOutliers = jsonGetStrDefault(inputJson, "handle_outliers", "include");
    let outputWithOriginal = jsonGetStrDefault(inputJson, "output_with_original", "false") == "true";

    let rawArr = extractNums_(contentRaw, fieldOpt, true);
    if (rawArr.size() == 0) return ok("{\"normalized\": [], \"method\": \"" # escapeJson(method) # "\", \"stats\": {}, \"count\": 0}");

    var workArr = rawArr;
    if (handleOutliers == "clip" or handleOutliers == "remove") {
      let (_, _, _, mH, sdH) = statsBlock_(rawArr);
      if (sdH > 0.0) {
        let lo3 = mH - 3.0 * sdH; let hi3 = mH + 3.0 * sdH;
        workArr := if (handleOutliers == "remove") {
          rawArr.filter(func(v : Float) : Bool { v >= lo3 and v <= hi3 })
        } else {
          rawArr.map(func(v : Float) : Float { if (v < lo3) lo3 else if (v > hi3) hi3 else v })
        };
      };
    };

    let sortedN = sortFloats_(workArr);
    let nN = workArr.size();
    let (_, minN, maxN, meanN, sdN) = statsBlock_(workArr);
    let medN = computeMedian_(sortedN);
    let q1N = computePercentile_(sortedN, 25.0);
    let q3N = computePercentile_(sortedN, 75.0);
    let iqrN = q3N - q1N;

    func normOne(v : Float) : Float {
      switch (method) {
        case "minmax" {
          let r = maxN - minN;
          if (r == 0.0) targetMin else (v - minN) / r * (targetMax - targetMin) + targetMin
        };
        case "zscore" { if (sdN == 0.0) 0.0 else (v - meanN) / sdN };
        case "percentile" {
          var rank = 0;
          for (sv in sortedN.values()) { if (sv <= v) rank += 1 };
          (rank.toFloat() / nN.toFloat()) * 100.0
        };
        case "log"   { if (v <= 0.0) 0.0 else Float.log(v) };
        case "log10" { if (v <= 0.0) 0.0 else Float.log(v) / Float.log(10.0) };
        case "robust" { if (iqrN == 0.0) 0.0 else (v - medN) / iqrN };
        case "decimal_scaling" {
          let maxAbs = if (Float.abs(maxN) >= Float.abs(minN)) Float.abs(maxN) else Float.abs(minN);
          if (maxAbs == 0.0) 0.0 else {
            let k = Float.ceil(Float.log(maxAbs) / Float.log(10.0));
            v / Float.pow(10.0, k)
          }
        };
        case _ { let r = maxN - minN; if (r == 0.0) 0.0 else (v - minN) / r };
      }
    };

    let normItems = List.empty<Text>();
    for (idx in Nat.range(0, nN)) {
      let origV = workArr[idx];
      let normV = normOne(origV);
      if (outputWithOriginal) {
        normItems.add("{\"original\": " # floatPrec(origV, prec) # ", \"normalized\": " # floatPrec(normV, prec) # "}");
      } else {
        normItems.add(floatPrec(normV, prec));
      };
    };

    ok("{\"normalized\": [" # normItems.values().join(", ") # "], \"method\": \"" # escapeJson(method) # "\", \"stats\": " # statsJson_(workArr, prec) # ", \"count\": " # nN.toText() # "}");
  };

  func csvToJson(csv : Text) : Text {
    let lines = csv.split(#text "\n").toArray();
    if (lines.size() == 0) return "[]";
    let headers = lines[0].split(#text ",").toArray();
    let rows = List.empty<Text>();
    var i = 1;
    while (i < lines.size()) {
      let line = lines[i].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' }));
      if (line.size() > 0) {
        let cells = line.split(#text ",").toArray();
        let pairs = List.empty<Text>();
        for (j in Nat.range(0, headers.size())) {
          let h = headers[j].trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' or c == '\r' }));
          let v = if (j < cells.size()) cells[j].trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' or c == '\r' })) else "";
          pairs.add("\"" # escapeJson(h) # "\": \"" # escapeJson(v) # "\"");
        };
        rows.add("{" # pairs.values().join(", ") # "}");
      };
      i += 1;
    };
    "[" # rows.values().join(", ") # "]";
  };

  func jsonToCsv(json : Text, delimiter : Text) : (Text, Nat) {
    let items = splitJsonArray(json);
    if (items.size() == 0) return ("", 0);
    let headers = jsonKeys(items[0]);
    let headerRow = headers.values().join(delimiter);
    let rows = List.empty<Text>();
    for (item in items.values()) {
      rows.add(headers.map<Text, Text>(func(h) { jsonGetStrDefault(item, h, "") }).values().join(delimiter));
    };
    (headerRow # "\n" # rows.values().join("\n"), items.size());
  };

  func handle_convert_file_format(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    if (content.size() == 0) return err("INVALID_INPUT", "content is required");
    let fromFmt = switch (jsonGetStr(inputJson, "from_format")) { case (?v) v; case null jsonGetStrDefault(inputJson, "from", "") };
    let toFmt = switch (jsonGetStr(inputJson, "to_format")) { case (?v) v; case null jsonGetStrDefault(inputJson, "to", "") };
    let delimiter = jsonGetStrDefault(inputJson, "delimiter", ",");
    let includeHeader = jsonGetStrDefault(inputJson, "include_header", "true") != "false";
    let nullRepr = jsonGetStrDefault(inputJson, "null_representation", "");
    let effectiveDelim : Text = if (delimiter == ",") { if (fromFmt == "tsv" or toFmt == "tsv") "\t" else "," } else delimiter;

    let parseResult : ?([Text], [[Text]]) = switch (fromFmt) {
      case "csv" {
        let lines = content.split(#text "\n").toArray();
        if (lines.size() == 0) return err("INVALID_INPUT", "CSV/TSV content has no lines");
        let hdrs = lines[0].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' })).split(#text effectiveDelim).toArray().map(func(h) { h.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' or c == '\r' })) });
        let dRows = List.empty<[Text]>();
        var i = 1;
        while (i < lines.size()) {
          let line = lines[i].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' }));
          if (line.size() > 0) dRows.add(line.split(#text effectiveDelim).toArray().map(func(c) { c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == '\r' })) }));
          i += 1;
        };
        ?(hdrs, dRows.toArray())
      };
      case "tsv" {
        let lines = content.split(#text "\n").toArray();
        if (lines.size() == 0) return err("INVALID_INPUT", "CSV/TSV content has no lines");
        let hdrs = lines[0].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' })).split(#text effectiveDelim).toArray().map(func(h) { h.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' or c == '\r' })) });
        let dRows = List.empty<[Text]>();
        var i = 1;
        while (i < lines.size()) {
          let line = lines[i].trim(#predicate(func(c : Char) { c == '\r' or c == ' ' }));
          if (line.size() > 0) dRows.add(line.split(#text effectiveDelim).toArray().map(func(c) { c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == '\r' })) }));
          i += 1;
        };
        ?(hdrs, dRows.toArray())
      };
      case "json" {
        let items = splitJsonArray(content);
        if (items.size() == 0) {
          let hdrs = jsonKeys(content);
          ?(hdrs, [hdrs.map(func(h) { jsonGetStrDefault(content, h, nullRepr) })])
        } else {
          let hdrs = jsonKeys(items[0]);
          ?(hdrs, items.map(func(item) { hdrs.map(func(h) { jsonGetStrDefault(item, h, nullRepr) }) }))
        }
      };
      case "key_value" {
        let lines = content.split(#text "\n").toArray();
        let keys = List.empty<Text>(); let vals = List.empty<Text>();
        for (line in lines.values()) {
          let t = line.trim(#predicate(func(c : Char) { c == ' ' or c == '\r' }));
          if (t.size() > 0) {
            let pts = t.split(#text "=").toArray();
            if (pts.size() >= 2) {
              keys.add(pts[0].trim(#predicate(func(c : Char) { c == ' ' })));
              var v = ""; var first = true;
              for (pi in Nat.range(1, pts.size())) { if (not first) v := v # "="; v := v # pts[pi]; first := false };
              vals.add(v.trim(#predicate(func(c : Char) { c == ' ' })));
            };
          };
        };
        ?(keys.toArray(), [vals.toArray()])
      };
      case _ null;
    };

    switch (parseResult) {
      case null { err("INVALID_INPUT", "Unsupported from_format: " # fromFmt) };
      case (?(headers, rows)) {
        let rowCount = rows.size();
        let converted : Text = switch (toFmt) {
          case "json" {
            let items = rows.map(func(rv) { "{" # headers.mapEntries(func(h, i) { "\"" # escapeJson(h) # "\": \"" # escapeJson(if (i < rv.size()) rv[i] else nullRepr) # "\"" }).values().join(", ") # "}" });
            "[" # items.values().join(", ") # "]"
          };
          case "csv" {
            let sep = if (toFmt == "tsv") "\t" else effectiveDelim;
            let rLines = List.empty<Text>();
            if (includeHeader) rLines.add(headers.values().join(sep));
            for (rv in rows.values()) rLines.add(headers.mapEntries(func(_, i) { if (i < rv.size()) rv[i] else nullRepr }).values().join(sep));
            rLines.values().join("\n")
          };
          case "tsv" {
            let sep = "\t";
            let rLines = List.empty<Text>();
            if (includeHeader) rLines.add(headers.values().join(sep));
            for (rv in rows.values()) rLines.add(headers.mapEntries(func(_, i) { if (i < rv.size()) rv[i] else nullRepr }).values().join(sep));
            rLines.values().join("\n")
          };
          case "markdown_table" {
            let hRow = "| " # headers.values().join(" | ") # " |";
            let sep2 = "|" # headers.map(func(_) { "---" }).values().join("|") # "|";
            hRow # "\n" # sep2 # "\n" # rows.map(func(rv) { "| " # headers.mapEntries(func(_, i) { if (i < rv.size()) rv[i] else nullRepr }).values().join(" | ") # " |" }).values().join("\n")
          };
          case "html_table" {
            "<table><thead><tr>" # headers.map(func(h) { "<th>" # h # "</th>" }).values().join("") # "</tr></thead><tbody>" # rows.map(func(rv) { "<tr>" # headers.mapEntries(func(_, i) { "<td>" # (if (i < rv.size()) rv[i] else nullRepr) # "</td>" }).values().join("") # "</tr>" }).values().join("") # "</tbody></table>"
          };
          case "key_value" { if (rows.size() > 0) headers.mapEntries(func(h, i) { h # "=" # (if (i < rows[0].size()) rows[0][i] else nullRepr) }).values().join("\n") else "" };
          case _ { return err("INVALID_INPUT", "Unsupported to_format: " # toFmt) };
        };
        ok("{\"content\": \"" # escapeJson(converted) # "\", \"from_format\": \"" # escapeJson(fromFmt) # "\", \"to_format\": \"" # escapeJson(toFmt) # "\", \"row_count\": " # rowCount.toText() # ", \"char_count\": " # converted.size().toText() # "}")
      };
    };
  };

  func handle_generate_json_file(inputJson : Text) : ExecResult {
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "") };
    if (rawContent.size() == 0) return err("INVALID_INPUT", "content is required");
    let isValid = isValidJsonStart(rawContent);
    let doSortKeys = jsonGetStrDefault(inputJson, "sort_keys", "false") == "true";
    let doSortArrays = jsonGetStrDefault(inputJson, "sort_arrays", "false") == "true";
    let includeNulls = jsonGetStrDefault(inputJson, "include_null_values", "true") != "false";
    let compress = jsonGetStrDefault(inputJson, "compress", "false") == "true";
    var result = rawContent;

    // Sort keys and/or strip nulls for object types
    if (isValid and result.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) {
      let ks = if (doSortKeys) jsonKeys(result).sort() else jsonKeys(result);
      let pairs = List.empty<Text>();
      for (k in ks.values()) {
        switch (jsonGetStr(result, k)) {
          case null {};
          case (?v) {
            let vt = v.trim(#predicate(func(c : Char) { c == ' ' }));
            if (includeNulls or vt != "null") {
              let vType = detectType(vt);
              pairs.add("\"" # escapeJson(k) # "\": " # (if (vType == "string") "\"" # escapeJson(vt) # "\"" else vt));
            };
          };
        };
      };
      result := "{" # pairs.values().join(", ") # "}";
    };

    // Sort array values
    if (isValid and doSortArrays and result.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "[")) {
      let items = splitJsonArray(result);
      let sorted = items.sort(func(a, b) {
        switch (parseFloat(a.trim(#predicate(func(c : Char) { c == ' ' }))), parseFloat(b.trim(#predicate(func(c : Char) { c == ' ' })))) {
          case (?fa, ?fb) if (fa < fb) #less else if (fa > fb) #greater else #equal;
          case _ Text.compare(a, b);
        };
      });
      result := "[" # sorted.values().join(", ") # "]";
    };

    // Minify if compress=true
    if (compress and isValid) {
      let minified = List.empty<Char>();
      var inStr = false; var prevBs = false;
      for (c in result.toIter()) {
        if (inStr) {
          minified.add(c);
          if (prevBs) prevBs := false else if (c == '\u{5C}') prevBs := true else if (c == '\u{22}') inStr := false;
        } else {
          if (c == '\u{22}') { inStr := true; minified.add(c) }
          else if (c != ' ' and c != '\n' and c != '\r' and c != '\t') minified.add(c);
        };
      };
      result := Text.fromIter(minified.values());
    };

    let keyCount = if (result.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) jsonKeys(result).size() else 0;
    ok("{\"content\": \"" # escapeJson(result) # "\", \"char_count\": " # result.size().toText() # ", \"key_count\": " # keyCount.toText() # ", \"is_valid\": " # (if isValid "true" else "false") # "}")
  };

  func handle_generate_csv(inputJson : Text) : ExecResult {
    let jsonContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "[]") };
    let delimiter = jsonGetStrDefault(inputJson, "delimiter", ",");
    let includeHeader = jsonGetStrDefault(inputJson, "include_header", "true") != "false";
    let quoteMode = jsonGetStrDefault(inputJson, "quote_mode", "minimal");
    let lineEnding = if (jsonGetStrDefault(inputJson, "line_ending", "lf") == "crlf") "\r\n" else "\n";
    let nullValue = jsonGetStrDefault(inputJson, "null_value", "");
    let columnOrderRaw = jsonGetStrDefault(inputJson, "column_order", "[]");
    let items = splitJsonArray(jsonContent);
    if (items.size() == 0) return ok("{\"content\": \"\", \"row_count\": 0, \"column_count\": 0, \"char_count\": 0}");
    let allHeaders = jsonKeys(items[0]);
    let colOrderTokens = splitJsonArray(columnOrderRaw);
    let orderedCols = if (colOrderTokens.size() > 0) {
      let specified = colOrderTokens.map(func(c) { c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == ' ' })) });
      specified.concat(allHeaders.filter(func(h) { specified.find(func(s) { s == h }) == null }))
    } else allHeaders;
    let quoteCell = func(v : Text) : Text {
      let needs = quoteMode == "all"
        or (quoteMode == "non_numeric" and parseFloat(v) == null and v != "true" and v != "false")
        or (quoteMode == "minimal" and (v.contains(#text delimiter) or v.contains(#text "\"") or v.contains(#text "\n")));
      if (quoteMode == "none" or not needs) v else "\"" # v.replace(#text "\"", "\\\"") # "\"";
    };
    let rLines = List.empty<Text>();
    if (includeHeader) rLines.add(orderedCols.map(quoteCell).values().join(delimiter));
    for (item in items.values()) {
      rLines.add(orderedCols.map(func(h) {
        let raw = jsonGetStrDefault(item, h, "");
        quoteCell(if (raw == "null" or raw.size() == 0) nullValue else raw)
      }).values().join(delimiter));
    };
    let csvContent = rLines.values().join(lineEnding);
    ok("{\"content\": \"" # escapeJson(csvContent) # "\", \"row_count\": " # items.size().toText() # ", \"column_count\": " # orderedCols.size().toText() # ", \"char_count\": " # csvContent.size().toText() # "}")
  };

  func handle_merge_files(inputJson : Text) : ExecResult {
    let rawContents : [Text] = switch (jsonGetStr(inputJson, "contents")) {
      case (?v) splitJsonArray(v).map(func(s) { s.trim(#predicate(func(c : Char) { c == '\u{22}' })) });
      case null switch (jsonGetStr(inputJson, "files")) {
        case (?v) splitJsonArray(v).map(func(s) { s.trim(#predicate(func(c : Char) { c == '\u{22}' })) });
        case null [jsonGetStrDefault(inputJson, "content_a", ""), jsonGetStrDefault(inputJson, "content_b", "")];
      };
    };
    if (rawContents.size() == 0) return err("INVALID_INPUT", "contents must have at least one item");
    let sep = jsonGetStrDefault(inputJson, "separator", "\n");
    let doDedupe = jsonGetStrDefault(inputJson, "deduplicate_lines", "false") == "true";
    let doSort = jsonGetStrDefault(inputJson, "sort_output", "false") == "true";
    let doTrim = jsonGetStrDefault(inputJson, "trim_each", "false") == "true";
    let doFilter = jsonGetStrDefault(inputJson, "filter_empty", "false") == "true";
    let doPrefix = jsonGetStrDefault(inputJson, "prefix_with_index", "false") == "true";
    let pieces = List.empty<Text>();
    var idx = 0;
    for (piece in rawContents.values()) {
      idx += 1;
      var p = if (doTrim) piece.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' })) else piece;
      if (doFilter and p.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' })).size() == 0) {}
      else { if (doPrefix) p := "--- Part " # idx.toText() # " ---\n" # p; pieces.add(p) };
    };
    var merged = pieces.values().join(sep);
    var dupesRemoved = 0;
    if (doDedupe) {
      let lines = merged.split(#text "\n").toArray();
      let seen = Set.empty<Text>(); let deduped = List.empty<Text>();
      for (line in lines.values()) {
        if (not seen.contains(line)) { seen.add(line); deduped.add(line) } else { dupesRemoved += 1 };
      };
      merged := deduped.values().join("\n");
    };
    if (doSort) merged := merged.split(#text "\n").toArray().sort().values().join("\n");
    let lineCount = merged.split(#text "\n").toArray().size();
    ok("{\"content\": \"" # escapeJson(merged) # "\", \"source_count\": " # rawContents.size().toText() # ", \"line_count\": " # lineCount.toText() # ", \"char_count\": " # merged.size().toText() # ", \"duplicates_removed\": " # dupesRemoved.toText() # "}")
  };

  func handle_split_file(inputJson : Text) : ExecResult {
    let content = jsonGetStrDefault(inputJson, "content", "");
    let strategy = jsonGetStrDefault(inputJson, "strategy", "lines");
    let chunkSize = switch (Nat.fromText(jsonGetStrDefault(inputJson, "chunk_size", "100").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 100 };
    let delimiter = jsonGetStrDefault(inputJson, "delimiter", "\n");
    let doFilter = jsonGetStrDefault(inputJson, "filter_empty", "true") != "false";
    let doTrim = jsonGetStrDefault(inputJson, "trim_parts", "false") == "true";
    let maxParts = switch (Nat.fromText(jsonGetStrDefault(inputJson, "max_parts", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let keepSep = jsonGetStrDefault(inputJson, "keep_separator", "false") == "true";
    let totalChars = content.size();
    let rawParts = List.empty<Text>();
    switch (strategy) {
      case "chars" {
        if (chunkSize == 0) return err("INVALID_INPUT", "chunk_size must be >= 1 for chars strategy");
        let chars = content.toArray(); var pos = 0;
        while (pos < chars.size()) {
          let endPos = Nat.min(pos + chunkSize, chars.size());
          rawParts.add(Text.fromIter(chars.sliceToArray(pos.toInt(), endPos.toInt()).values()));
          pos := endPos;
        };
      };
      case "words" {
        if (chunkSize == 0) return err("INVALID_INPUT", "chunk_size must be >= 1 for words strategy");
        let words = content.split(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' })).toArray().filter(func(w) { w.size() > 0 });
        var i = 0;
        while (i < words.size()) {
          let endIdx = Nat.min(i + chunkSize, words.size());
          rawParts.add(words.sliceToArray(i, endIdx).values().join(" "));
          i := endIdx;
        };
      };
      case "paragraphs" {
        for (p in content.split(#text "\n\n").toArray().values()) { rawParts.add(p) };
      };
      case "delimiter" {
        for (p in content.split(#text delimiter).toArray().values()) {
          rawParts.add(if (keepSep and p.size() > 0) p # delimiter else p);
        };
      };
      case _ {
        // lines strategy
        if (chunkSize == 0) return err("INVALID_INPUT", "chunk_size must be >= 1 for lines strategy");
        let lines = content.split(#text "\n").toArray(); var i = 0;
        while (i < lines.size()) {
          let endIdx = Nat.min(i + chunkSize, lines.size());
          rawParts.add(lines.sliceToArray(i, endIdx).values().join("\n"));
          i := endIdx;
        };
      };
    };
    let processed = List.empty<Text>();
    for (p in rawParts.values()) {
      let part = if (doTrim) p.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' })) else p;
      if (not (doFilter and part.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' })).size() == 0)) {
        processed.add(part);
      };
    };
    var finalParts = processed.toArray();
    if (maxParts > 0 and finalParts.size() > maxParts) {
      let remainder = finalParts.sliceToArray(maxParts - 1, finalParts.size());
      finalParts := finalParts.sliceToArray(0, maxParts - 1).concat([remainder.values().join("\n")]);
    };
    let partCount = finalParts.size();
    let totalOut = finalParts.foldLeft(0, func(acc, p) { acc + p.size() });
    let avg = if (partCount > 0) totalOut / partCount else 0;
    ok("{\"parts\": [" # finalParts.values().map(func(p : Text) : Text { "\"" # escapeJson(p) # "\"" }).join(", ") # "], \"part_count\": " # partCount.toText() # ", \"strategy\": \"" # escapeJson(strategy) # "\", \"avg_part_size\": " # avg.toText() # ", \"total_chars\": " # totalChars.toText() # "}")
  };

  // ── Type format checkers ──────────────────────────────────────────────────
  func isValidEmail_(s : Text) : Bool { s.contains(#text "@") and s.contains(#text ".") and s.size() >= 5 };
  func isValidUrl_(s : Text) : Bool { s.startsWith(#text "http://") or s.startsWith(#text "https://") or s.startsWith(#text "ftp://") };
  func isValidUuid_(s : Text) : Bool {
    let pts = s.split(#text "-").toArray();
    if (pts.size() != 5) return false;
    let lens = [8, 4, 4, 4, 12];
    for (i in Nat.range(0, pts.size())) { if (pts[i].size() != lens[i]) return false };
    true
  };
  func isValidDate_(s : Text) : Bool {
    let pts = s.split(#text "-").toArray();
    pts.size() == 3 and pts[0].size() == 4 and pts[1].size() == 2 and pts[2].size() == 2
  };
  func checkTypeFormat_(v : Text, t : Text) : Bool {
    switch (t) {
      case "string" true;
      case "number" { parseFloat(v) != null };
      case "integer" { switch (Int.fromText(v)) { case (?_) true; case null false } };
      case "boolean" { v == "true" or v == "false" };
      case "email" { isValidEmail_(v) };
      case "url" { isValidUrl_(v) };
      case "uuid" { isValidUuid_(v) };
      case "date" { isValidDate_(v) };
      case "datetime" { v.contains(#text "T") };
      case "json" { isValidJsonStart(v) };
      case "ip" { v.split(#text ".").toArray().size() == 4 };
      case "ipv4" { v.split(#text ".").toArray().size() == 4 };
      case "ipv6" { v.contains(#text ":") };
      case "phone" { v.size() >= 7 and v.size() <= 15 };
      case "alphanumeric" { v.toArray().all(func(c : Char) : Bool { (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') }) };
      case "hex" { v.toArray().all(func(c : Char) : Bool { (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F') }) };
      case "base64" { v.size() > 0 };
      case _ true;
    };
  };

  func handle_validate_input(inputJson : Text) : ExecResult {
    let rawValue = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "value", "") };
    let typeName = switch (jsonGetStr(inputJson, "type")) { case (?v) v; case null jsonGetStrDefault(inputJson, "expected_type", "string") };
    let isRequired = jsonGetStrDefault(inputJson, "required", "true") != "false";
    let normalized = rawValue.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' }));
    let customMsg = jsonGetStr(inputJson, "error_message");
    let errors = List.empty<Text>();
    let addErr = func(msg : Text) {
      errors.add("\"" # escapeJson(switch (customMsg) { case (?cm) cm; case null msg }) # "\"");
    };
    if (isRequired and normalized.size() == 0) { addErr("Value is required") }
    else if (normalized.size() > 0) {
      if (not checkTypeFormat_(normalized, typeName)) addErr("Value does not match expected type: " # typeName);
      switch (jsonGetStr(inputJson, "min_length")) {
        case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (normalized.size() < n) addErr("Value too short (min_length " # n.toText() # ")") }; case null {} } };
        case null {};
      };
      switch (jsonGetStr(inputJson, "max_length")) {
        case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (normalized.size() > n) addErr("Value too long (max_length " # n.toText() # ")") }; case null {} } };
        case null {};
      };
      if (typeName == "number" or typeName == "integer") {
        switch (parseFloat(normalized)) {
          case (?num) {
            switch (jsonGetStr(inputJson, "min_value")) {
              case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mn) { if (num < mn) addErr("Value " # floatToText(num) # " < min_value " # floatToText(mn)) }; case null {} } };
              case null {};
            };
            switch (jsonGetStr(inputJson, "max_value")) {
              case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mx) { if (num > mx) addErr("Value " # floatToText(num) # " > max_value " # floatToText(mx)) }; case null {} } };
              case null {};
            };
          };
          case null {};
        };
      };
      switch (jsonGetStr(inputJson, "pattern")) {
        case (?pat) { if (pat.size() > 0 and not normalized.contains(#text pat)) addErr("Value does not contain pattern: " # pat) };
        case null {};
      };
      switch (jsonGetStr(inputJson, "allowed_values")) {
        case (?av) {
          let allowed = splitJsonArray(av).map(func(s) { s.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) });
          if (allowed.size() > 0 and allowed.find(func(a) { a == normalized }) == null) addErr("Value not in allowed values list");
        };
        case null {};
      };
    };
    let errArr = errors.toArray();
    ok("{\"is_valid\": " # (if (errArr.size() == 0) "true" else "false") # ", \"type\": \"" # escapeJson(typeName) # "\", \"errors\": [" # errArr.values().join(", ") # "], \"value\": \"" # escapeJson(rawValue) # "\", \"normalized_value\": \"" # escapeJson(normalized) # "\"}")
  };

  func handle_validate_schema(inputJson : Text) : ExecResult {
    let json = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "{}") };
    let schema = jsonGetStrDefault(inputJson, "schema", "{}");
    let strictMode = jsonGetStrDefault(inputJson, "strict_mode", "false") == "true";
    let allowExtra = if (strictMode) false else jsonGetStrDefault(inputJson, "allow_extra_fields", "true") != "false";
    let maxErrors = switch (Nat.fromText(jsonGetStrDefault(inputJson, "max_errors", "20").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 20 };
    if (not isValidJsonStart(json)) {
      return ok("{\"is_valid\": false, \"errors\": [{\"path\": \"$\", \"message\": \"Invalid JSON syntax\", \"expected\": \"valid JSON\", \"actual\": \"unparseable\"}], \"error_count\": 1, \"schema_fields_checked\": 0}");
    };
    let errors = List.empty<Text>();
    var sfc = 0;
    switch (jsonGetStr(schema, "required")) {
      case (?rr) {
        for (req in splitJsonArray(rr).values()) {
          if (errors.size() < maxErrors) {
             let fn = req.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' }));
            if (jsonGetStr(json, fn) == null) errors.add("{\"path\": \"$." # escapeJson(fn) # "\", \"message\": \"Required field missing\", \"expected\": \"present\", \"actual\": \"missing\"}");
          };
        };
      };
      case null {};
    };
    switch (jsonGetStr(schema, "properties")) {
      case null {};
      case (?pr) {
        let pks = jsonKeys(pr); sfc := pks.size();
        for (pk in pks.values()) {
          if (errors.size() < maxErrors) {
            switch (jsonGetStr(json, pk)) {
              case null {};
              case (?v) {
                let vt = v.trim(#predicate(func(c : Char) { c == ' ' }));
                switch (jsonGetStr(pr, pk)) {
                  case null {};
                  case (?ps) {
                    switch (jsonGetStr(ps, "type")) {
                      case null {};
                      case (?et) { let at = detectType(vt); if (at != et and vt != "null") errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"Type mismatch\", \"expected\": \"" # escapeJson(et) # "\", \"actual\": \"" # escapeJson(at) # "\"}") };
                    };
                    switch (jsonGetStr(ps, "enum")) {
                      case null {};
                      case (?er) {
                        if (errors.size() < maxErrors) {
                           let vs = vt.trim(#predicate(func(c : Char) { c == '\u{22}' }));
                           if (splitJsonArray(er).find(func(e : Text) : Bool { e.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' })) == vs }) == null) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"Value not in enum\", \"expected\": \"one of " # escapeJson(er) # "\", \"actual\": \"" # escapeJson(vs) # "\"}");
                        };
                      };
                    };
                    switch (parseFloat(vt)) {
                      case (?num) {
                        switch (jsonGetStr(ps, "minimum")) { case (?ms) { if (errors.size() < maxErrors) switch (parseFloat(ms.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mn) { if (num < mn) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"Value below minimum\", \"expected\": \">= " # floatToText(mn) # "\", \"actual\": \"" # floatToText(num) # "\"}") }; case null {} } }; case null {} };
                        switch (jsonGetStr(ps, "maximum")) { case (?ms) { if (errors.size() < maxErrors) switch (parseFloat(ms.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mx) { if (num > mx) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"Value above maximum\", \"expected\": \"<= " # floatToText(mx) # "\", \"actual\": \"" # floatToText(num) # "\"}") }; case null {} } }; case null {} };
                      };
                      case null {};
                    };
                    if (vt.startsWith(#text "\"")) {
                       let sv = vt.trim(#predicate(func(c : Char) { c == '\u{22}' }));
                      switch (jsonGetStr(ps, "minLength")) { case (?ml) { if (errors.size() < maxErrors) switch (Nat.fromText(ml.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (sv.size() < n) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"String too short\", \"expected\": \"minLength " # n.toText() # "\", \"actual\": \"" # sv.size().toText() # "\"}") }; case null {} } }; case null {} };
                      switch (jsonGetStr(ps, "maxLength")) { case (?ml) { if (errors.size() < maxErrors) switch (Nat.fromText(ml.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (sv.size() > n) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"String too long\", \"expected\": \"maxLength " # n.toText() # "\", \"actual\": \"" # sv.size().toText() # "\"}") }; case null {} } }; case null {} };
                      switch (jsonGetStr(ps, "pattern")) { case (?pat) { if (errors.size() < maxErrors and not sv.contains(#text pat)) errors.add("{\"path\": \"$." # escapeJson(pk) # "\", \"message\": \"Pattern mismatch\", \"expected\": \"contains '" # escapeJson(pat) # "'\", \"actual\": \"" # escapeJson(sv) # "\"}") }; case null {} };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
    if (not allowExtra) {
      let dks = switch (jsonGetStr(schema, "properties")) { case (?pr2) jsonKeys(pr2); case null [] };
      for (ak in jsonKeys(json).values()) {
        if (errors.size() < maxErrors and dks.find(func(dk) { dk == ak }) == null) errors.add("{\"path\": \"$." # escapeJson(ak) # "\", \"message\": \"Additional property not allowed\", \"expected\": \"absent\", \"actual\": \"present\"}");
      };
    };
    let errArr = errors.toArray();
    ok("{\"is_valid\": " # (if (errArr.size() == 0) "true" else "false") # ", \"errors\": [" # errArr.values().join(", ") # "], \"error_count\": " # errArr.size().toText() # ", \"schema_fields_checked\": " # sfc.toText() # "}")
  };

  func handle_sanitize_input(inputJson : Text) : ExecResult {
    let rawText = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "text", "") };
    let mode = jsonGetStrDefault(inputJson, "mode", "xss");
    let doPreserve = jsonGetStrDefault(inputJson, "preserve_formatting", "false") == "true";
    let maxLength = switch (Nat.fromText(jsonGetStrDefault(inputJson, "max_length", "0").trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let doStripNull = jsonGetStrDefault(inputJson, "strip_nullbytes", "true") != "false";
    let doNormUni = jsonGetStrDefault(inputJson, "normalize_unicode", "false") == "true";
    let originalLength = rawText.size();
    let ops = List.empty<Text>();
    var result = rawText;
    let allowedTagsStr = switch (jsonGetStr(inputJson, "allowed_tags")) { case (?v) v; case null "" };
    let allowedTagArr = if (allowedTagsStr.size() > 0) {
      allowedTagsStr.split(#text ",").toArray().map(func(t) {
        t.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' })).toLower()
      })
    } else ([] : [Text]);
    let hasAllowedTags = allowedTagArr.size() > 0;
    if (mode == "xss" or mode == "all") {
      // Step 1: strip <script>...</script> blocks (case-insensitive via toLower trick)
      label sl loop {
        let lowerResult = result.toLower();
        if (not lowerResult.contains(#text "<script")) break sl;
        let pts = result.split(#text "<script").toArray();
        let lpts = lowerResult.split(#text "<script").toArray();
        if (pts.size() < 2) break sl;
         let afterScript = lpts[1];
        if (afterScript.contains(#text "</script>")) {
          // find close tag in the original result
          let afterScriptOrig = pts[1];
          let pts2 = afterScriptOrig.split(#text "</script>").toArray();
          if (pts2.size() < 2) {
            // try case-insensitive close — just drop from <script onward
            result := pts[0];
          } else {
            result := pts[0] # pts2[1];
          };
        } else {
          // No closing tag found — drop from <script onward
          result := pts[0];
          break sl;
        };
      };
      // Step 2: strip HTML tags, preserving allowed_tags
      if (hasAllowedTags) {
        // Preserve tags in allowedTagArr, strip all others
        let outChars = List.empty<Char>();
        var inTag = false;
        var tagBuf = "";
        for (c in result.toIter()) {
          if (c == '<') {
            inTag := true;
            tagBuf := "";
          } else if (c == '>') {
            inTag := false;
            // Determine tag name (strip leading / for closing tags)
            let rawTag = tagBuf.trim(#predicate(func(x : Char) { x == ' ' }));
            let tagNameOnly = Text.fromIter(rawTag.toIter().takeWhile(func(x : Char) : Bool { x != ' ' and x != '/' })).toLower();
            let isClosing = rawTag.startsWith(#text "/");
            let realTagName = if (isClosing) Text.fromIter(rawTag.trimStart(#text "/").toIter().takeWhile(func(x : Char) : Bool { x != ' ' })).toLower() else tagNameOnly;
            let isAllowed = allowedTagArr.find(func(t : Text) : Bool { Text.equal(t, realTagName) }) != null;
            if (isAllowed) {
              // Re-emit the full tag
              for (tc in ("<" # tagBuf # ">").toIter()) outChars.add(tc);
            };
            // else: discard the tag
          } else if (inTag) {
            tagBuf := tagBuf # c.toText();
          } else {
            outChars.add(c);
          };
        };
        result := Text.fromIter(outChars.values());
      } else {
        // No allowed tags — strip all tags
        let chars = List.empty<Char>(); var inT = false;
        for (c in result.toIter()) { if (c == '<') { inT := true } else if (c == '>') { inT := false } else if (not inT) chars.add(c) };
        result := Text.fromIter(chars.values());
      };
      ops.add("\"xss\"");
    };
    if (mode == "sql" or mode == "all") { result := result.replace(#text "'", "''").replace(#text "\\", "\\\\").replace(#text ";", "\\;"); ops.add("\"sql\"") };
    if (mode == "path" or mode == "all") { result := result.replace(#text "../", "").replace(#text "..\\", "").replace(#text "//", "/"); ops.add("\"path\"") };
    if (mode == "html" or mode == "all") { result := result.replace(#text "&", "&amp;").replace(#text "<", "&lt;").replace(#text ">", "&gt;").replace(#text "\"", "&quot;").replace(#text "'", "&#39;"); ops.add("\"html\"") };
    if (mode == "markdown" or mode == "all") { result := result.replace(#text "*", "\\*").replace(#text "_", "\\_").replace(#text "`", "\\`").replace(#text "#", "\\#").replace(#text "[", "\\[").replace(#text "]", "\\]"); ops.add("\"markdown\"") };
    if (doStripNull) { result := result.replace(#text "\u{00}", ""); ops.add("\"strip_nullbytes\"") };
    if (doNormUni) {
      result := result.flatMap(func(c : Char) : Text {
        switch (c) {
          case 'à' "a"; case 'á' "a"; case 'â' "a"; case 'ä' "a"; case 'è' "e"; case 'é' "e"; case 'ê' "e"; case 'ë' "e";
          case 'ì' "i"; case 'í' "i"; case 'î' "i"; case 'ï' "i"; case 'ò' "o"; case 'ó' "o"; case 'ô' "o"; case 'ö' "o";
          case 'ù' "u"; case 'ú' "u"; case 'û' "u"; case 'ü' "u"; case 'ý' "y"; case 'ñ' "n"; case 'ç' "c";
          case _ c.toText();
        };
      });
      ops.add("\"normalize_unicode\"");
    };
    if (not doPreserve) {
      let chars = List.empty<Char>(); var prevSp = false;
      for (c in result.toIter()) {
        if (c == ' ' or c == '\t') { if (not prevSp) { chars.add(' '); prevSp := true } } else { chars.add(c); prevSp := false };
      };
      result := Text.fromIter(chars.values()).trim(#predicate(func(c : Char) { c == ' ' }));
    };
    if (maxLength > 0 and result.size() > maxLength) result := Text.fromIter(result.toIter().take(maxLength));
    let sl2 = result.size(); let cr = if (originalLength >= sl2) originalLength - sl2 else 0;
    ok("{\"content\": \"" # escapeJson(result) # "\", \"original_length\": " # originalLength.toText() # ", \"sanitized_length\": " # sl2.toText() # ", \"chars_removed\": " # cr.toText() # ", \"operations_applied\": [" # ops.values().join(", ") # "]}")
  };

  func handle_enforce_constraints(inputJson : Text) : ExecResult {
    let value = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "value", "") };
    let collectAll = jsonGetStrDefault(inputJson, "error_mode", "fail_first") == "collect_all";
    let customMsg = jsonGetStr(inputJson, "custom_message");
    let violations = List.empty<Text>();
    let addV = func(c : Text, dm : Text) {
      violations.add("{\"constraint\": \"" # escapeJson(c) # "\", \"message\": \"" # escapeJson(switch (customMsg) { case (?m) m; case null dm }) # "\"}");
    };
    let stop = func() : Bool = not collectAll and violations.size() > 0;
    if (not stop() and jsonGetStrDefault(inputJson, "not_empty", "false") == "true") {
      if (value.trim(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' or c == '\r' })).size() == 0) addV("not_empty", "Value must not be empty");
    };
    if (not stop() and jsonGetStrDefault(inputJson, "not_null", "false") == "true") {
      let t = value.trim(#predicate(func(c : Char) { c == ' ' }));
      if (t.size() == 0 or t == "null") addV("not_null", "Value must not be null");
    };
    if (not stop()) { switch (jsonGetStr(inputJson, "min_length")) { case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (value.size() < n) addV("min_length", "Length " # value.size().toText() # " < min_length " # n.toText()) }; case null {} } }; case null {} } };
    if (not stop()) { switch (jsonGetStr(inputJson, "max_length")) { case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (value.size() > n) addV("max_length", "Length " # value.size().toText() # " > max_length " # n.toText()) }; case null {} } }; case null {} } };
    if (not stop()) {
      switch (parseFloat(value.trim(#predicate(func(c : Char) { c == ' ' })))) {
        case (?num) {
          if (not stop()) { switch (jsonGetStr(inputJson, "min_value")) { case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mn) { if (num < mn) addV("min_value", "Value " # floatToText(num) # " < min_value " # floatToText(mn)) }; case null {} } }; case null {} } };
          if (not stop()) { switch (jsonGetStr(inputJson, "max_value")) { case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?mx) { if (num > mx) addV("max_value", "Value " # floatToText(num) # " > max_value " # floatToText(mx)) }; case null {} } }; case null {} } };
        };
        case null {};
      };
    };
    if (not stop()) {
      switch (jsonGetStr(inputJson, "enum_values")) {
        case (?ev) {
          let allowed = splitJsonArray(ev).map(func(s) { s.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) });
          if (allowed.size() > 0 and allowed.find(func(a) { a == value }) == null) addV("enum_values", "Value not in enum_values list");
        };
        case null {};
      };
    };
    if (not stop()) { switch (jsonGetStr(inputJson, "regex_pattern")) { case (?pat) { if (pat.size() > 0 and not value.contains(#text pat)) addV("regex_pattern", "Value does not contain required pattern") }; case null {} } };
    // Legacy constraints object support
    if (violations.size() == 0) {
      switch (jsonGetStr(inputJson, "constraints")) {
        case (?cj) {
          switch (jsonGetStr(cj, "minLength")) { case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (value.size() < n) addV("minLength", "Length " # value.size().toText() # " < minLength " # n.toText()) }; case null {} } }; case null {} };
          switch (jsonGetStr(cj, "maxLength")) { case (?v) { switch (Nat.fromText(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (value.size() > n) addV("maxLength", "Length " # value.size().toText() # " > maxLength " # n.toText()) }; case null {} } }; case null {} };
          switch (parseFloat(value)) {
            case (?num) {
              switch (jsonGetStr(cj, "min")) { case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (num < n) addV("min", "Value " # floatToText(num) # " < min " # floatToText(n)) }; case null {} } }; case null {} };
              switch (jsonGetStr(cj, "max")) { case (?v) { switch (parseFloat(v.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) { if (num > n) addV("max", "Value " # floatToText(num) # " > max " # floatToText(n)) }; case null {} } }; case null {} };
            };
            case null {};
          };
          switch (jsonGetStr(cj, "pattern")) { case (?pat) { if (not value.contains(#text pat)) addV("pattern", "Value does not match pattern: " # pat) }; case null {} };
        };
        case null {};
      };
    };
    let arr = violations.toArray();
    ok("{\"is_valid\": " # (if (arr.size() == 0) "true" else "false") # ", \"value\": \"" # escapeJson(value) # "\", \"violations\": [" # arr.values().join(", ") # "], \"violation_count\": " # arr.size().toText() # "}")
  };

  func handle_format_json(inputJson : Text) : ExecResult {
    // Support both new "content" and legacy "json" input keys
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "") };
    if (rawContent.size() == 0) return err("INVALID_INPUT", "content is required");
    let mode = jsonGetStrDefault(inputJson, "mode", "pretty");
    let filterKeysRaw = jsonGetStrDefault(inputJson, "filter_keys", "[]");
    let filterKeyTokens = splitJsonArray(filterKeysRaw);
    let filterKeys = filterKeyTokens.map(func(f) { f.trim(#predicate(func(c : Char) { c == ' ' or c == '\u{22}' })) });
    let sortKeys = jsonGetStrDefault(inputJson, "sort_keys", "false") == "true" or mode == "sorted";
    let isValid = isValidJsonStart(rawContent);
    let originalLength = rawContent.size();

    var working = if (filterKeys.size() > 0 and rawContent.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) {
      filterJsonKeys(rawContent, filterKeys, [] : [Text])
    } else rawContent;

    if (sortKeys and working.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) {
      let ks = jsonKeys(working).sort();
      let pairs = List.empty<Text>();
      for (k in ks.values()) {
        switch (jsonGetStr(working, k)) {
          case null {};
          case (?v) {
            let vt = v.trim(#predicate(func(c : Char) { c == ' ' }));
            let vType = detectType(vt);
            pairs.add("\"" # escapeJson(k) # "\": " # (if (vType == "string") "\"" # escapeJson(vt) # "\"" else vt));
          };
        };
      };
      working := "{" # pairs.values().join(", ") # "}";
    };

    let formatted = if (mode == "compact") {
      let minified = List.empty<Char>();
      var inStr = false;
      var prevBs = false;
      for (c in working.toIter()) {
        if (inStr) {
          minified.add(c);
          if (prevBs) prevBs := false else if (c == '\u{5C}') prevBs := true else if (c == '\u{22}') inStr := false;
        } else {
          if (c == '\u{22}') { inStr := true; minified.add(c) }
          else if (c != ' ' and c != '\n' and c != '\r' and c != '\t') minified.add(c);
        };
      };
      Text.fromIter(minified.values())
    } else working;

    let keyCount = if (formatted.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) jsonKeys(formatted).size() else 0;
    ok("{\"content\": \"" # escapeJson(formatted) # "\", \"original_length\": " # originalLength.toText() # ", \"formatted_length\": " # formatted.size().toText() # ", \"is_valid\": " # (if isValid "true" else "false") # ", \"key_count\": " # keyCount.toText() # "}");
  };

  func handle_format_table(inputJson : Text) : ExecResult {
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "[]") };
    let items = splitJsonArray(rawContent);
    if (items.size() == 0) return ok("{\"table\": \"\", \"row_count\": 0, \"column_count\": 0, \"columns_used\": []}");
    let colsRaw = jsonGetStrDefault(inputJson, "columns", "[]");
    let colTokens = splitJsonArray(colsRaw);
    let borderStyle = jsonGetStrDefault(inputJson, "border_style", "simple");
    let maxColWidthStr = jsonGetStrDefault(inputJson, "max_column_width", "50");
    let maxColWidth = switch (Nat.fromText(maxColWidthStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 50 };
    let truncSuffix = jsonGetStrDefault(inputJson, "truncate_suffix", "...");
    let showRowNums = jsonGetStrDefault(inputJson, "show_row_numbers", "false") == "true";
    let nullDisplay = jsonGetStrDefault(inputJson, "null_display", "");
    let headerSep = jsonGetStrDefault(inputJson, "header_separator", "true") != "false";

    let baseHeaders = if (colTokens.size() > 0) {
      colTokens.map(func(c) { c.trim(#predicate(func(x : Char) { x == '\u{22}' or x == ' ' })) });
    } else jsonKeys(items[0]);

    let headers = if (showRowNums) {
      let withNum = List.empty<Text>();
      withNum.add("#");
      for (h in baseHeaders.values()) withNum.add(h);
      withNum.toArray()
    } else baseHeaders;

    let truncCell = func(s : Text) : Text {
      if (maxColWidth > 0 and s.size() > maxColWidth) {
        Text.fromIter(s.toArray().sliceToArray(0, maxColWidth.toInt()).values()) # truncSuffix
      } else s
    };

    let widths = List.fromArray<Nat>(headers.map<Text, Nat>(func(h) { h.size() }));
    for (ri in Nat.range(0, items.size())) {
      let item = items[ri];
      for (ci in Nat.range(0, headers.size())) {
        let h = headers[ci];
        let cellVal = if (showRowNums and ci == 0) (ri + 1).toText()
          else { let v = jsonGetStrDefault(item, if (showRowNums) headers[ci] else h, ""); if (v == "" or v == "null") nullDisplay else v };
        let truncated = truncCell(cellVal);
        let cur = widths.at(ci);
        if (truncated.size() > cur) widths.put(ci, truncated.size());
      };
    };
    let finalWidths = widths.toArray();

    let padRight = func(s : Text, n : Nat) : Text {
      if (n > s.size()) s # Text.fromIter(Iter.repeat(' ', n - s.size())) else s
    };

    if (borderStyle == "csv") {
      let rows = List.empty<Text>();
      rows.add(headers.values().join(","));
      for (ri in Nat.range(0, items.size())) {
        let item = items[ri];
        rows.add(headers.mapEntries(func(h, ci) : Text {
          if (showRowNums and ci == 0) (ri + 1).toText()
          else { let v = jsonGetStrDefault(item, h, ""); if (v == "" or v == "null") nullDisplay else v }
        }).values().join(","));
      };
      let colsJson = "[" # headers.values().map(func(h : Text) : Text { "\"" # escapeJson(h) # "\"" }).join(", ") # "]";
      ok("{\"table\": \"" # escapeJson(rows.values().join("\n")) # "\", \"row_count\": " # items.size().toText() # ", \"column_count\": " # headers.size().toText() # ", \"columns_used\": " # colsJson # "}");
    } else {
      let headerCells = headers.mapEntries(func(h, i) { padRight(h, finalWidths[i]) });
      let headerRow = "| " # headerCells.values().join(" | ") # " |";
      let sepRow = if (headerSep) {
        "|" # finalWidths.mapEntries(func(w, _) { Text.fromIter(Iter.repeat('-', w + 2)) }).values().join("|") # "|"
      } else "";
      let dataRows = List.empty<Text>();
      for (ri in Nat.range(0, items.size())) {
        let item = items[ri];
        let cells = headers.mapEntries(func(h, ci) : Text {
          let raw = if (showRowNums and ci == 0) (ri + 1).toText()
            else { let v = jsonGetStrDefault(item, h, ""); if (v == "" or v == "null") nullDisplay else v };
          padRight(truncCell(raw), finalWidths[ci])
        });
        dataRows.add("| " # cells.values().join(" | ") # " |");
      };
      let tableLines = List.empty<Text>();
      tableLines.add(headerRow);
      if (headerSep and sepRow.size() > 0) tableLines.add(sepRow);
      for (row in dataRows.values()) tableLines.add(row);
      let colsJson = "[" # headers.values().map(func(h : Text) : Text { "\"" # escapeJson(h) # "\"" }).join(", ") # "]";
      ok("{\"table\": \"" # escapeJson(tableLines.values().join("\n")) # "\", \"row_count\": " # items.size().toText() # ", \"column_count\": " # headers.size().toText() # ", \"columns_used\": " # colsJson # "}");
    };
  };

  func handle_format_markdown(inputJson : Text) : ExecResult {
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "{}") };
    let modeInput = jsonGetStrDefault(inputJson, "mode", "auto");
    let headingLevelStr = jsonGetStrDefault(inputJson, "heading_level", "2");
    let headingLevel = switch (Nat.fromText(headingLevelStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) if (n >= 1 and n <= 6) n else 2; case null 2 };
    let listStyleInput = jsonGetStrDefault(inputJson, "list_style", "unordered");
    let codeLanguage = jsonGetStrDefault(inputJson, "code_language", "");
    let maxItemsStr = jsonGetStr(inputJson, "max_items");
    let maxItems : ?Nat = switch (maxItemsStr) { case null null; case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' }))) };
    let linkFieldsRaw = switch (jsonGetStr(inputJson, "link_fields")) { case (?v) v; case null "{}" };

    let mode = if (modeInput == "auto") {
      if (looksLikeArray(rawContent)) "list"
      else if (rawContent.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{")) "definition"
      else "code"
    } else modeInput;

    let hPrefix = Text.fromIter(Iter.repeat('#', headingLevel)) # " ";

    let resultText = switch (mode) {
      case "table" {
        let items = splitJsonArray(rawContent);
        if (items.size() == 0) ""
        else {
          let displayItems = switch (maxItems) { case null items; case (?n) if (items.size() <= n) items else items.sliceToArray(0, n.toInt()) };
          let hdrs = jsonKeys(displayItems[0]);
          let headerRow = "| " # hdrs.values().join(" | ") # " |";
          let sepRow = "|" # hdrs.map(func(_) { "---" }).values().join("|") # "|";
          let rows = List.empty<Text>();
          for (item in displayItems.values()) {
            rows.add("| " # hdrs.map<Text, Text>(func(h) { jsonGetStrDefault(item, h, "") }).values().join(" | ") # " |");
          };
          headerRow # "\n" # sepRow # "\n" # rows.values().join("\n")
        }
      };
      case "list" {
        let items = splitJsonArray(rawContent);
        let displayItems = switch (maxItems) { case null items; case (?n) if (items.size() <= n) items else items.sliceToArray(0, n.toInt()) };
        let lines = List.empty<Text>();
        for (item in displayItems.values()) {
          let isObj = item.trimStart(#predicate(func(c : Char) { c == ' ' })).startsWith(#text "{");
          let displayText = if (isObj) {
            let ks = jsonKeys(item);
            if (ks.size() == 0) item
            else {
              let firstKey = ks[0];
              let displayVal = jsonGetStrDefault(item, firstKey, item);
              switch (jsonGetStr(linkFieldsRaw, firstKey)) {
                case null displayVal;
                case (?urlField) "[" # displayVal # "](" # jsonGetStrDefault(item, urlField, displayVal) # ")";
              }
            }
          } else item.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' }));
          let prefix = switch (listStyleInput) {
            case "ordered" { (lines.size() + 1).toText() # ". " };
            case "task" "- [ ] ";
            case _ "- ";
          };
          lines.add(prefix # displayText);
        };
        lines.values().join("\n")
      };
      case "heading" { hPrefix # rawContent.trim(#predicate(func(c : Char) { c == '\u{22}' or c == ' ' })) };
      case "code" { "```" # codeLanguage # "\n" # rawContent # "\n```" };
      case _ {
        let ks = jsonKeys(rawContent);
        let lines = List.empty<Text>();
        let displayKs = switch (maxItems) { case null ks; case (?n) if (ks.size() <= n) ks else ks.sliceToArray(0, n.toInt()) };
        for (k in displayKs.values()) {
          lines.add("**" # k # "**: " # jsonGetStrDefault(rawContent, k, ""));
        };
        lines.values().join("\n")
      };
    };

    ok("{\"content\": \"" # escapeJson(resultText) # "\", \"char_count\": " # resultText.size().toText() # ", \"mode_used\": \"" # escapeJson(mode) # "\"}");
  };

  func applyCaseStyle(text : Text, style : Text) : Text {
    switch (style) {
      case "lowercase" text.toLower();
      case "uppercase" text.toUpper();
      case "title_case" {
        let words = text.split(#predicate(func(c : Char) { c == ' ' or c == '\t' or c == '\n' })).toArray();
        words.map(func(w : Text) : Text {
          if (w.size() == 0) w
          else {
            let chars = w.toArray();
            let first = Text.fromIter([Char.fromNat32(chars[0].toNat32() - (if (chars[0] >= 'a' and chars[0] <= 'z') 32 else 0))].values());
            first # Text.fromIter(chars.sliceToArray(1, chars.size().toInt()).values()).toLower()
          }
        }).values().join(" ")
      };
      case "sentence_case" {
        let t = text.trim(#predicate(func(c : Char) { c == ' ' }));
        if (t.size() == 0) t
        else {
          let chars = t.toArray();
          let first = Text.fromIter([Char.fromNat32(chars[0].toNat32() - (if (chars[0] >= 'a' and chars[0] <= 'z') 32 else 0))].values());
          first # Text.fromIter(chars.sliceToArray(1, chars.size().toInt()).values()).toLower()
        }
      };
      case "snake_case" {
        text.trim(#predicate(func(c : Char) { c == ' ' })).toLower().replace(#text " ", "_").replace(#text "-", "_")
      };
      case "kebab_case" {
        text.trim(#predicate(func(c : Char) { c == ' ' })).toLower().replace(#text " ", "-").replace(#text "_", "-")
      };
      case "camel_case" {
        let words = text.split(#predicate(func(c : Char) { c == ' ' or c == '_' or c == '-' })).toArray();
        if (words.size() == 0) text
        else {
          let capWord = func(w : Text) : Text {
            if (w.size() == 0) w
            else {
              let chars = w.toArray();
              Text.fromIter([Char.fromNat32(chars[0].toNat32() - (if (chars[0] >= 'a' and chars[0] <= 'z') 32 else 0))].values()) # Text.fromIter(chars.sliceToArray(1, chars.size().toInt()).values()).toLower()
            }
          };
          let result2 = List.empty<Text>();
          result2.add(words[0].toLower());
          for (i in Nat.range(1, words.size())) { result2.add(capWord(words[i])) };
          result2.values().join("")
        }
      };
      case "pascal_case" {
        let words = text.split(#predicate(func(c : Char) { c == ' ' or c == '_' or c == '-' })).toArray();
        words.map(func(w : Text) : Text {
          if (w.size() == 0) w
          else {
            let chars = w.toArray();
            Text.fromIter([Char.fromNat32(chars[0].toNat32() - (if (chars[0] >= 'a' and chars[0] <= 'z') 32 else 0))].values()) # Text.fromIter(chars.sliceToArray(1, chars.size().toInt()).values()).toLower()
          }
        }).values().join("")
      };
      case _ text;
    };
  };

  func handle_format_text(inputJson : Text) : ExecResult {
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "text", "") };
    let caseStyle = jsonGetStrDefault(inputJson, "case_style", "none");
    let widthStr = jsonGetStrDefault(inputJson, "width", "0");
    let width = switch (Nat.fromText(widthStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let indentCountStr = jsonGetStrDefault(inputJson, "indent", "0");
    let indentCount = switch (Nat.fromText(indentCountStr.trim(#predicate(func(c : Char) { c == ' ' })))) { case (?n) n; case null 0 };
    let alignment = jsonGetStrDefault(inputJson, "alignment", "left");
    let preserveParaBreaks = jsonGetStrDefault(inputJson, "preserve_paragraph_breaks", "true") != "false";
    let stripExtraWs = jsonGetStrDefault(inputJson, "strip_extra_whitespace", "false") == "true";
    let indentStr = Text.fromIter(Iter.repeat(' ', indentCount));

    var result = applyCaseStyle(rawContent, caseStyle);

    if (stripExtraWs) {
      let chars = List.empty<Char>();
      var prevSpace = false;
      for (c in result.toIter()) {
        let isSpace = c == ' ' or c == '\t';
        if (isSpace) {
          if (not prevSpace) { chars.add(' '); prevSpace := true };
        } else { chars.add(c); prevSpace := false };
      };
      result := Text.fromIter(chars.values());
    };

    if (width > 0) {
      let paragraphs = if (preserveParaBreaks) result.split(#text "\n\n").toArray() else [result];
      let wrappedParas = List.empty<Text>();
      for (para in paragraphs.values()) {
        let words = para.split(#predicate(func(c : Char) { c == ' ' or c == '\n' or c == '\t' })).toArray();
        let lines = List.empty<Text>();
        var current = "";
        for (word in words.values()) {
          if (word.size() == 0) {}
          else if (current.size() == 0) current := word
          else if (current.size() + 1 + word.size() <= width - indentCount) current := current # " " # word
          else { lines.add(current); current := word };
        };
        if (current.size() > 0 or lines.size() == 0) lines.add(current);
        let alignedLines = lines.toArray().map(func(line : Text) : Text {
          indentStr # (switch (alignment) {
            case "right" {
              let spaces = if (width > line.size() + indentCount) width - line.size() - indentCount else 0;
              Text.fromIter(Iter.repeat(' ', spaces)) # line
            };
            case "center" {
              let spaces = if (width > line.size() + indentCount) (width - line.size() - indentCount) / 2 else 0;
              Text.fromIter(Iter.repeat(' ', spaces)) # line
            };
            case _ line;
          })
        });
        wrappedParas.add(alignedLines.values().join("\n"));
      };
      result := wrappedParas.values().join("\n\n");
    } else if (indentCount > 0) {
      result := result.split(#text "\n").toArray().map(func(line : Text) : Text { indentStr # line }).values().join("\n");
    };

    let lineCount = result.split(#text "\n").toArray().size();
    ok("{\"content\": \"" # escapeJson(result) # "\", \"char_count\": " # result.size().toText() # ", \"line_count\": " # lineCount.toText() # ", \"case_style_applied\": \"" # escapeJson(caseStyle) # "\"}");
  };

  func evalSingleCond(value : Text, op : Text, threshold : Text, caseSensitive : Bool) : Bool {
    let v = if (caseSensitive) value else value.toLower();
    let t = if (caseSensitive) threshold else threshold.toLower();
    switch (op) {
      case "eq" { v == t };
      case "neq" { v != t };
      case "gt" { switch (parseFloat(value), parseFloat(threshold)) { case (?a, ?b) a > b; case _ v > t } };
      case "gte" { switch (parseFloat(value), parseFloat(threshold)) { case (?a, ?b) a >= b; case _ v >= t } };
      case "lt" { switch (parseFloat(value), parseFloat(threshold)) { case (?a, ?b) a < b; case _ v < t } };
      case "lte" { switch (parseFloat(value), parseFloat(threshold)) { case (?a, ?b) a <= b; case _ v <= t } };
      case "contains" { v.contains(#text t) };
      case "starts_with" { v.startsWith(#text t) };
      case "ends_with" { v.endsWith(#text t) };
      case "is_null" { value == "null" or value == "" };
      case "is_not_null" { value != "null" and value.size() > 0 };
      case "is_empty" { value.size() == 0 };
      case "matches_regex" { value.contains(#text threshold) };
      case _ false;
    };
  };

  func handle_evaluate_condition(inputJson : Text) : ExecResult {
    let logicalOp = jsonGetStrDefault(inputJson, "logical_operator", "AND").toUpper();
    let condType = jsonGetStrDefault(inputJson, "type", "auto");
    let caseSensitive = jsonGetStrDefault(inputJson, "case_sensitive", "false") == "true";
    let conditionsRaw = jsonGetStrDefault(inputJson, "conditions", "[]");
    let condTokens = splitJsonArray(conditionsRaw);

    let details = List.empty<Text>();
    var condsPassed = 0;
    var condsEvaluated = 0;

    let evalAndRecord = func(value : Text, op : Text, threshold : Text) : Bool {
      condsEvaluated += 1;
      let r = evalSingleCond(value, op, threshold, caseSensitive);
      if (r) condsPassed += 1;
      details.add("{\"value\": \"" # escapeJson(value) # "\", \"operator\": \"" # escapeJson(op) # "\", \"threshold\": \"" # escapeJson(threshold) # "\", \"result\": " # (if r "true" else "false") # "}");
      r
    };

    let combinedResult : Bool = if (condTokens.size() > 0) {
      let results = List.empty<Bool>();
      for (condItem in condTokens.values()) {
        let v = jsonGetStrDefault(condItem, "value", "");
        let o = jsonGetStrDefault(condItem, "operator", "eq");
        let thr = jsonGetStrDefault(condItem, "threshold", "");
        results.add(evalAndRecord(v, o, thr));
      };
      let resArr = results.toArray();
      switch (logicalOp) {
        case "OR" { resArr.any(func(r : Bool) : Bool { r }) };
        case "NOT" { if (resArr.size() > 0) not resArr[0] else false };
        case _ { resArr.all(func(r : Bool) : Bool { r }) };
      }
    } else {
      // Single condition — also support legacy "field op value" in "condition" field
      switch (jsonGetStr(inputJson, "value")) {
        case (?value) {
          let op = jsonGetStrDefault(inputJson, "operator", "eq");
          let threshold = jsonGetStrDefault(inputJson, "threshold", "");
          evalAndRecord(value, op, threshold)
        };
        case null {
          let condition = jsonGetStrDefault(inputJson, "condition", "");
          let parts = condition.split(#predicate(func(c : Char) { c == ' ' })).toArray();
          if (parts.size() >= 3) {
            let context = jsonGetStrDefault(inputJson, "context", "{}");
            let actual = jsonGetStrDefault(context, parts[0], "");
            evalAndRecord(actual, parts[1], parts[2])
          } else false
        };
      }
    };

    ok("{\"result\": " # (if combinedResult "true" else "false") # ", \"conditions_evaluated\": " # condsEvaluated.toText() # ", \"conditions_passed\": " # condsPassed.toText() # ", \"logical_operator\": \"" # escapeJson(logicalOp) # "\", \"details\": [" # details.values().join(", ") # "]}");
  };

  func castReturnType(value : Text, returnType : Text) : Text {
    switch (returnType) {
      case "number" { switch (parseFloat(value)) { case (?_) value; case null "0" } };
      case "boolean" { if (value == "true" or value == "1") "true" else "false" };
      case "json" { if (isValidJsonStart(value)) value else "\"" # escapeJson(value) # "\"" };
      case _ value;
    };
  };

  func handle_select_value(inputJson : Text) : ExecResult {
    let condition = jsonGetStrDefault(inputJson, "condition", "");
    let valueIfTrue = jsonGetStrDefault(inputJson, "value_if_true", "");
    let valueIfFalse = jsonGetStrDefault(inputJson, "value_if_false", "");
    let returnType = jsonGetStrDefault(inputJson, "return_type", "string");
    let nullHandling = jsonGetStrDefault(inputJson, "null_handling", "empty_string");
    let variablesRaw = switch (jsonGetStr(inputJson, "variables")) { case (?v) v; case null "{}" };
    var evaluableCondition = condition;
    for (k in jsonKeys(variablesRaw).values()) {
      switch (jsonGetStr(variablesRaw, k)) {
        case (?v) evaluableCondition := evaluableCondition.replace(#text k, v);
        case null {};
      };
    };
    let casesRaw = jsonGetStrDefault(inputJson, "cases", "[]");
    let caseTokens = splitJsonArray(casesRaw);
    if (caseTokens.size() > 0) {
      var matchedIdx : ?Nat = null;
      var matchedVal = valueIfFalse;
      for (ci in Nat.range(0, caseTokens.size())) {
        if (matchedIdx == null) {
          let caseItem = caseTokens[ci];
          let caseCond = jsonGetStrDefault(caseItem, "condition", "false");
          let caseVal = jsonGetStrDefault(caseItem, "value", "");
          if (caseCond == "true" or caseCond == "1") { matchedIdx := ?ci; matchedVal := caseVal };
        };
      };
      let branch = switch (matchedIdx) { case null "false"; case (?i) i.toText() };
      ok("{\"selected_value\": \"" # escapeJson(castReturnType(matchedVal, returnType)) # "\", \"condition_result\": " # (if (matchedIdx != null) "true" else "false") # ", \"branch_taken\": \"" # escapeJson(branch) # "\", \"return_type\": \"" # escapeJson(returnType) # "\"}");
    } else {
      let condIsTrue = evaluableCondition.trim(#predicate(func(c : Char) { c == ' ' })) == "true"
        or evaluableCondition.trim(#predicate(func(c : Char) { c == ' ' })) == "1";
      let selected = if (condIsTrue) valueIfTrue else valueIfFalse;
      let finalVal = if (selected.size() == 0) {
        switch (nullHandling) { case "null" "null"; case "error" { return err("NO_MATCH", "No match") }; case _ "" }
      } else castReturnType(selected, returnType);
      ok("{\"selected_value\": \"" # escapeJson(finalVal) # "\", \"condition_result\": " # (if condIsTrue "true" else "false") # ", \"branch_taken\": \"" # (if condIsTrue "true" else "false") # "\", \"return_type\": \"" # escapeJson(returnType) # "\"}");
    };
  };

  func handle_rank_by_field(inputJson : Text) : ExecResult {
    let rawContent = switch (jsonGetStr(inputJson, "content")) { case (?v) v; case null jsonGetStrDefault(inputJson, "json", "[]") };
    let field = jsonGetStrDefault(inputJson, "field", "");
    let order = jsonGetStrDefault(inputJson, "order", "desc");
    let tieBreakBy = switch (jsonGetStr(inputJson, "tie_break_by")) { case (?v) v; case null "" };
    let includeRank = jsonGetStrDefault(inputJson, "include_rank", "true") != "false";
    let includePercentile = jsonGetStrDefault(inputJson, "include_percentile", "false") == "true";
    let denseRank = jsonGetStrDefault(inputJson, "dense_rank", "false") == "true";
    let topNStr = jsonGetStr(inputJson, "top_n");
    let topN : ?Nat = switch (topNStr) { case null null; case (?s) Nat.fromText(s.trim(#predicate(func(c : Char) { c == ' ' }))) };
     let rankFieldsRaw = jsonGetStrDefault(inputJson, "rank_fields", "[]");
    let rankFieldTokens = splitJsonArray(rankFieldsRaw);
    let primaryField = if (rankFieldTokens.size() > 0) jsonGetStrDefault(rankFieldTokens[0], "field", field) else field;
    let primaryOrder = if (rankFieldTokens.size() > 0) jsonGetStrDefault(rankFieldTokens[0], "order", order) else order;
    // Build multi-key sort specs from rank_fields, or fall back to simple field+order+tieBreakBy
    let sortSpecs : [(Text, Text)] = if (rankFieldTokens.size() > 0) {
      rankFieldTokens.map(func(rf) { (jsonGetStrDefault(rf, "field", field), jsonGetStrDefault(rf, "order", "asc")) })
    } else if (tieBreakBy.size() > 0) {
      [(primaryField, primaryOrder), (tieBreakBy, "asc")]
    } else {
      [(primaryField, primaryOrder)]
    };
    let items = splitJsonArray(rawContent);
    let sorted = items.sort(func(a, b) {
      var result2 : {#less; #equal; #greater} = #equal;
      label specLoop for ((sf, sord) in sortSpecs.values()) {
        if (result2 != #equal) break specLoop;
        let va = jsonGetStrDefault(a, sf, "");
        let vb = jsonGetStrDefault(b, sf, "");
        let cmp = switch (parseFloat(va), parseFloat(vb)) {
          case (?fa, ?fb) if (fa < fb) #less else if (fa > fb) #greater else #equal;
          case (?_, null) #less; case (null, ?_) #greater;
          case _ Text.compare(va, vb);
        };
        result2 := if (sord == "asc") cmp
          else switch (cmp) { case (#less) #greater; case (#greater) #less; case (#equal) #equal };
      };
      result2
    });
    let limitedSorted = switch (topN) { case null sorted; case (?n) if (sorted.size() <= n) sorted else sorted.sliceToArray(0, n.toInt()) };
    let ranked = List.empty<Text>();
    var lastVal = "";
    var lastRank = 0;
    var denseCounter = 0;
    let total = limitedSorted.size();
    for (i in Nat.range(0, total)) {
      let item = limitedSorted[i];
      let val = jsonGetStrDefault(item, primaryField, "");
      denseCounter += 1;
      let rankNum = if (denseRank) {
        if (val == lastVal and i > 0) lastRank
        else { lastVal := val; lastRank := denseCounter; denseCounter }
      } else { lastRank := i + 1; i + 1 };
      let stripped = item.trimEnd(#predicate(func(c : Char) { c == ' ' })).trimEnd(#text "}");
      var entry = stripped;
       if (includeRank) entry := entry # ", \"_rank\": " # rankNum.toText();
       if (includePercentile and total > 0) {
        let pct = if (total == 1) 100
          else Float.nearest(((total - i) * 100).toFloat() / total.toFloat()).toInt();
        entry := entry # ", \"_percentile\": " # pct.toText();
      };
      ranked.add(entry # "}");
    };
    let fieldsUsed = if (rankFieldTokens.size() > 0) {
      "[" # rankFieldTokens.map(func(rf) { "\"" # escapeJson(jsonGetStrDefault(rf, "field", primaryField)) # "\"" }).values().join(", ") # "]"
    } else "[\"" # escapeJson(primaryField) # "\"]";
    ok("{\"result\": [" # ranked.toArray().values().join(", ") # "], \"ranked_count\": " # limitedSorted.size().toText() # ", \"rank_fields_used\": " # fieldsUsed # "}");
  };

  func handle_list_capabilities_meta(inputJson : Text) : ExecResult {
    let allCaps = allCapabilities();
    let totalCount = allCaps.size();
    let cat = jsonGetStr(inputJson, "category");
    let searchRaw = jsonGetStr(inputJson, "search");
    let includeSchemas = jsonGetStrDefault(inputJson, "include_schemas", "false") == "true";
    let sortBy = jsonGetStrDefault(inputJson, "sort_by", "category");

    // filter by category and/or search
    var filtered = allCaps.filter(func(c : Types.CapabilityInfo) : Bool {
      let catMatch = switch (cat) { case null true; case (?ct) Text.equal(c.category, ct) };
      let searchMatch = switch (searchRaw) {
        case null true;
        case (?s) {
          let sl = s.toLower();
          c.name.toLower().contains(#text sl) or c.description.toLower().contains(#text sl)
        };
      };
      catMatch and searchMatch
    });

    // sort
    if (sortBy == "name" or sortBy == "alphabetical") {
      filtered := filtered.sort(func(a : Types.CapabilityInfo, b : Types.CapabilityInfo) : { #less; #equal; #greater } {
        Text.compare(a.name, b.name)
      });
    } else {
      // default: sort by category then name
      filtered := filtered.sort(func(a : Types.CapabilityInfo, b : Types.CapabilityInfo) : { #less; #equal; #greater } {
        let catCmp = Text.compare(a.category, b.category);
        if (catCmp == #equal) Text.compare(a.name, b.name) else catCmp
      });
    };

    let filteredCount = filtered.size();

    // build capabilities JSON
    let capItems = filtered.map(func(c) {
      if (includeSchemas) {
        let inputsJson = "[" # c.inputs.map(func(i) {
          "{\"key\": \"" # escapeJson(i.key) # "\", \"inputType\": \"" # escapeJson(i.inputType) # "\", \"required\": " # (if (i.required) "true" else "false") # ", \"description\": \"" # escapeJson(i.description) # "\"}"
        }).values().join(", ") # "]";
        let outputsJson = "[" # c.outputs.map(func(o) {
          "{\"key\": \"" # escapeJson(o.key) # "\", \"outputType\": \"" # escapeJson(o.outputType) # "\", \"description\": \"" # escapeJson(o.description) # "\"}"
        }).values().join(", ") # "]";
        "{\"name\": \"" # escapeJson(c.name) # "\", \"description\": \"" # escapeJson(c.description) # "\", \"category\": \"" # escapeJson(c.category) # "\", \"inputs\": " # inputsJson # ", \"outputs\": " # outputsJson # "}"
      } else {
        "{\"name\": \"" # escapeJson(c.name) # "\", \"description\": \"" # escapeJson(c.description) # "\", \"category\": \"" # escapeJson(c.category) # "\"}"
      }
    });

    // collect unique categories sorted
    let catSet = Set.empty<Text>();
    for (c in allCaps.values()) catSet.add(c.category);
    let catArr = catSet.toArray().sort();
    let categoriesJson = "[" # catArr.map(func(ct : Text) : Text { "\"" # escapeJson(ct) # "\"" }).values().join(", ") # "]";

    ok("{\"capabilities\": [" # capItems.values().join(", ") # "], \"total_count\": " # totalCount.toText() # ", \"filtered_count\": " # filteredCount.toText() # ", \"categories\": " # categoriesJson # "}");
  };

  func serializeCapabilityInfo(info : Types.CapabilityInfo, includeExamples : Bool, includeConstraints : Bool) : Text {
    let inputsJson = "[" # info.inputs.map(func(i) {
      "{\"key\": \"" # escapeJson(i.key) # "\", \"inputType\": \"" # escapeJson(i.inputType) # "\", \"required\": " # (if (i.required) "true" else "false") # ", \"description\": \"" # escapeJson(i.description) # "\"}"
    }).values().join(", ") # "]";
    let outputsJson = "[" # info.outputs.map(func(o) {
      "{\"key\": \"" # escapeJson(o.key) # "\", \"outputType\": \"" # escapeJson(o.outputType) # "\", \"description\": \"" # escapeJson(o.description) # "\"}"
    }).values().join(", ") # "]";
    let constraintsJson = if (includeConstraints) {
      "[" # info.constraints.map(func(c : Text) : Text { "\"" # escapeJson(c) # "\"" }).values().join(", ") # "]"
    } else "[]";
    var result = "{\"name\": \"" # escapeJson(info.name) # "\", \"description\": \"" # escapeJson(info.description) # "\", \"category\": \"" # escapeJson(info.category) # "\", \"inputs\": " # inputsJson # ", \"outputs\": " # outputsJson # ", \"constraints\": " # constraintsJson;
    if (includeExamples) {
      result := result # ", \"exampleInput\": \"" # escapeJson(info.exampleInput) # "\", \"exampleOutput\": \"" # escapeJson(info.exampleOutput) # "\"";
    };
    result # "}";
  };

  func handle_describe_capability_meta(inputJson : Text) : ExecResult {
    let name = jsonGetStrDefault(inputJson, "name", "");
    let includeExamples = jsonGetStrDefault(inputJson, "include_examples", "true") != "false";
    let includeConstraints = jsonGetStrDefault(inputJson, "include_constraints", "true") != "false";
    let includeRelated = jsonGetStrDefault(inputJson, "include_related", "false") == "true";
    switch (describe(name)) {
      case null ok("{\"capability\": null, \"found\": false}");
      case (?info) {
        let capJson = serializeCapabilityInfo(info, includeExamples, includeConstraints);
        let relatedJson = if (includeRelated) {
          let same = allCapabilities().filter(func(c : Types.CapabilityInfo) : Bool {
            Text.equal(c.category, info.category) and not Text.equal(c.name, info.name)
          });
          let top3 = if (same.size() <= 3) same else same.sliceToArray(0, 3);
          ", \"related_capabilities\": [" # top3.map(func(c : Types.CapabilityInfo) : Text { "\"" # escapeJson(c.name) # "\"" }).values().join(", ") # "]"
        } else "";
        ok("{\"capability\": " # capJson # ", \"found\": true" # relatedJson # "}");
      };
    };
  };

  // ── public dispatch ────────────────────────────────────────────────────────

  public func dispatch(
    name : Text,
    inputJson : Text,
    objectStore : Map.Map<Text, Text>,
    httpCacheMap : Map.Map<Text, CacheEntry>,
    transformFn : TransformFn,
  ) : async* ExecResult {
    switch (name) {
      case "fetch_url"           await* handle_fetch_url(inputJson, httpCacheMap, transformFn);
      case "read_document"       handle_read_document(inputJson);
      case "extract_text"        handle_extract_text(inputJson);
      case "clean_text"          handle_clean_text(inputJson);
      case "chunk_text"          handle_chunk_text(inputJson);
      case "remove_html"         handle_remove_html(inputJson);
      case "normalize_text"      handle_normalize_text(inputJson);
      case "parse_json"          handle_parse_json(inputJson);
      case "validate_json"       handle_validate_json(inputJson);
      case "extract_fields"      handle_extract_fields(inputJson);
      case "extract_table"       handle_extract_table(inputJson);
      case "text_to_key_value"   handle_text_to_key_value(inputJson);
      case "transform_data"      handle_transform_data(inputJson);
      case "filter_data"         handle_filter_data(inputJson);
      case "sort_data"           handle_sort_data(inputJson);
      case "deduplicate_data"    handle_deduplicate_data(inputJson);
      case "merge_objects"       handle_merge_objects(inputJson);
      case "flatten_object"      handle_flatten_object(inputJson);
      case "expand_object"       handle_expand_object(inputJson);
      case "keyword_search"      handle_keyword_search(inputJson);
      case "regex_search"        handle_regex_search(inputJson);
      case "substring_search"    handle_substring_search(inputJson);
      case "store_object"        handle_store_object(inputJson, objectStore);
      case "retrieve_object"     handle_retrieve_object(inputJson, objectStore);
      case "update_object"       handle_update_object(inputJson, objectStore);
      case "delete_object"       handle_delete_object(inputJson, objectStore);
      case "list_objects"        handle_list_objects(inputJson, objectStore);
      case "compute_math"        handle_compute_math(inputJson);
      case "aggregate_data"      handle_aggregate_data(inputJson);
      case "compare_values"      handle_compare_values(inputJson);
      case "normalize_values"    handle_normalize_values(inputJson);
      case "convert_file_format" handle_convert_file_format(inputJson);
      case "generate_json_file"  handle_generate_json_file(inputJson);
      case "generate_csv"        handle_generate_csv(inputJson);
      case "merge_files"         handle_merge_files(inputJson);
      case "split_file"          handle_split_file(inputJson);
      case "validate_input"      handle_validate_input(inputJson);
      case "validate_schema"     handle_validate_schema(inputJson);
      case "sanitize_input"      handle_sanitize_input(inputJson);
      case "enforce_constraints" handle_enforce_constraints(inputJson);
      case "format_json"         handle_format_json(inputJson);
      case "format_table"        handle_format_table(inputJson);
      case "format_markdown"     handle_format_markdown(inputJson);
      case "format_text"         handle_format_text(inputJson);
      case "evaluate_condition"  handle_evaluate_condition(inputJson);
      case "select_value"        handle_select_value(inputJson);
      case "rank_by_field"       handle_rank_by_field(inputJson);
      case "list_capabilities"   handle_list_capabilities_meta(inputJson);
      case "describe_capability" handle_describe_capability_meta(inputJson);
      case _ err("UNKNOWN_CAPABILITY", "No capability named: " # name);
    };
  };
};
