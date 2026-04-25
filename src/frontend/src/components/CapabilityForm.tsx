import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import { cn } from "@/lib/utils";
import { AlertCircle, CheckCircle2, Loader2, Paperclip, X } from "lucide-react";
import mammoth from "mammoth";
import * as pdfjsLib from "pdfjs-dist";
import { useEffect, useRef, useState } from "react";
import type { CapabilityInfo, CapabilityInput } from "../types";

// Use CDN worker to avoid bundling the heavy worker script
pdfjsLib.GlobalWorkerOptions.workerSrc =
  "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";

interface Props {
  capability: CapabilityInfo;
  mode: "form" | "json";
  jsonValue: string;
  onJsonChange: (v: string) => void;
  onModeChange: (m: "form" | "json") => void;
  validationErrors: string[];
}

const DOCUMENT_CAPABILITIES = new Set([
  "read_document",
  "extract_text",
  "clean_text",
  "chunk_text",
  "remove_html",
  "normalize_text",
]);

const FILE_PRIMARY_KEYS = new Set(["content", "text", "html"]);
const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

function getFileExtension(filename: string): string {
  const idx = filename.lastIndexOf(".");
  return idx >= 0 ? filename.slice(idx).toLowerCase() : "";
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

interface FileAttachState {
  name: string;
  size: number;
}

async function extractDocxText(arrayBuffer: ArrayBuffer): Promise<string> {
  const result = await mammoth.extractRawText({ arrayBuffer });
  return result.value;
}

async function extractPdfText(arrayBuffer: ArrayBuffer): Promise<string> {
  const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
  const pages: string[] = [];
  for (let i = 1; i <= pdf.numPages; i++) {
    const page = await pdf.getPage(i);
    const content = await page.getTextContent();
    const pageText = content.items
      .map((item) => ("str" in item ? item.str : ""))
      .join(" ");
    pages.push(pageText);
  }
  return pages.join("\n\n");
}

function FileAttachButton({
  fieldKey,
  onContent,
}: {
  fieldKey: string;
  onContent: (content: string) => void;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [attached, setAttached] = useState<FileAttachState | null>(null);
  const [parsing, setParsing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleFile = async (file: File) => {
    setError(null);
    setAttached(null);

    if (file.size > MAX_FILE_SIZE) {
      setError("File too large — maximum size is 10MB.");
      if (inputRef.current) inputRef.current.value = "";
      return;
    }

    const ext = getFileExtension(file.name);

    // Old .doc (binary compound document) — not supported
    if (ext === ".doc") {
      setError(
        "Old .doc format is not supported. Please save the file as .docx and try again.",
      );
      if (inputRef.current) inputRef.current.value = "";
      return;
    }

    // Plain text formats — read directly
    if (ext === ".txt" || ext === ".md" || ext === ".json") {
      const reader = new FileReader();
      reader.onload = (e) => {
        const text = (e.target?.result as string) ?? "";
        onContent(text);
        setAttached({ name: file.name, size: file.size });
        if (inputRef.current) inputRef.current.value = "";
      };
      reader.onerror = () => {
        setError("Could not read file. Try saving as .txt or .docx.");
        if (inputRef.current) inputRef.current.value = "";
      };
      reader.readAsText(file);
      return;
    }

    // Binary formats — read as ArrayBuffer then parse
    if (ext === ".docx" || ext === ".pdf") {
      setParsing(true);
      const reader = new FileReader();
      reader.onload = async (e) => {
        const buffer = e.target?.result as ArrayBuffer;
        try {
          const text =
            ext === ".docx"
              ? await extractDocxText(buffer)
              : await extractPdfText(buffer);
          onContent(text);
          setAttached({ name: file.name, size: file.size });
        } catch {
          setError("Could not read file. Try saving as .txt or .docx.");
        } finally {
          setParsing(false);
          if (inputRef.current) inputRef.current.value = "";
        }
      };
      reader.onerror = () => {
        setError("Could not read file. Try saving as .txt or .docx.");
        setParsing(false);
        if (inputRef.current) inputRef.current.value = "";
      };
      reader.readAsArrayBuffer(file);
      return;
    }

    // Unknown extension — fallback to text
    const reader = new FileReader();
    reader.onload = (e) => {
      onContent((e.target?.result as string) ?? "");
      setAttached({ name: file.name, size: file.size });
      if (inputRef.current) inputRef.current.value = "";
    };
    reader.onerror = () => {
      setError("Could not read file. Try saving as .txt or .docx.");
      if (inputRef.current) inputRef.current.value = "";
    };
    reader.readAsText(file);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) void handleFile(file);
  };

  const clearAttachment = () => {
    setAttached(null);
    setError(null);
    if (inputRef.current) inputRef.current.value = "";
  };

  return (
    <div className="flex flex-col gap-1.5">
      <input
        ref={inputRef}
        type="file"
        accept=".txt,.pdf,.docx,.md,.json"
        onChange={handleChange}
        className="sr-only"
        id={`file-input-${fieldKey}`}
        data-ocid={`file-input-${fieldKey}`}
        aria-label={`Attach file for ${fieldKey}`}
      />

      {parsing ? (
        <div
          className={cn(
            "flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-mono",
            "bg-accent/5 border-accent/30 text-muted-foreground",
          )}
        >
          <Loader2 size={13} className="text-accent shrink-0 animate-spin" />
          <span>Parsing document…</span>
        </div>
      ) : attached ? (
        <div
          className={cn(
            "flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-mono",
            "bg-accent/5 border-accent/30 text-foreground",
          )}
        >
          <Paperclip size={13} className="text-accent shrink-0" />
          <span className="truncate min-w-0 flex-1">{attached.name}</span>
          <span className="text-muted-foreground/60 shrink-0 text-xs">
            {formatFileSize(attached.size)}
          </span>
          <button
            type="button"
            onClick={clearAttachment}
            aria-label="Remove attached file"
            className="shrink-0 text-muted-foreground hover:text-foreground transition-colors p-0.5 rounded"
          >
            <X size={13} />
          </button>
        </div>
      ) : (
        <label
          htmlFor={`file-input-${fieldKey}`}
          className={cn(
            "inline-flex items-center gap-2 px-3 py-2 rounded-lg border text-sm font-mono cursor-pointer",
            "border-border bg-secondary/30 text-muted-foreground",
            "hover:border-accent/40 hover:text-foreground hover:bg-accent/5 transition-smooth",
            "w-fit min-h-[36px]",
          )}
        >
          <Paperclip size={13} />
          Attach file
          <span className="text-muted-foreground/50 text-xs">
            .txt .md .json .pdf .docx
          </span>
        </label>
      )}

      {error && (
        <p className="text-xs font-mono text-destructive flex items-center gap-1.5">
          <AlertCircle size={11} className="shrink-0" />
          {error}
        </p>
      )}
    </div>
  );
}

function getDefaultValue(type: string): string | boolean | number {
  if (type === "boolean") return false;
  if (type === "number" || type === "integer") return 0;
  return "";
}

function buildJsonFromFields(
  fields: Record<string, string | boolean | number>,
): string {
  const obj: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(fields)) {
    if (v === "") continue;
    obj[k] = v;
  }
  return JSON.stringify(obj, null, 2);
}

// Type badge colors
const TYPE_BADGE_CLASSES: Record<string, string> = {
  string: "bg-secondary/60 text-chart-2 border-chart-2/20",
  number: "bg-secondary/60 text-chart-5 border-chart-5/20",
  integer: "bg-secondary/60 text-chart-5 border-chart-5/20",
  boolean: "bg-secondary/60 text-chart-1 border-chart-1/20",
  array: "bg-secondary/60 text-chart-3 border-chart-3/20",
  object: "bg-secondary/60 text-chart-4 border-chart-4/20",
};

function TypeBadge({ type }: { type: string }) {
  const classes =
    TYPE_BADGE_CLASSES[type] ??
    "bg-secondary/60 text-muted-foreground border-border";
  return (
    <span
      className={cn(
        "inline-flex items-center text-[10px] font-mono px-1.5 py-0 h-4 rounded border",
        classes,
      )}
    >
      {type}
    </span>
  );
}

function FieldRow({
  input,
  value,
  onChange,
  isDocumentCapability,
}: {
  input: CapabilityInput;
  value: string | boolean | number;
  onChange: (v: string | boolean | number) => void;
  isDocumentCapability: boolean;
}) {
  const fieldId = `field-${input.key}`;
  const isLong =
    input.inputType === "string" &&
    (input.key.includes("text") ||
      input.key.includes("content") ||
      input.key.includes("body") ||
      input.key.includes("data"));

  const showFileAttach =
    isDocumentCapability &&
    input.inputType === "string" &&
    FILE_PRIMARY_KEYS.has(input.key);

  return (
    <div className="flex flex-col gap-2" data-ocid={`field-row-${input.key}`}>
      {/* Label row */}
      <div className="flex items-center gap-2 flex-wrap">
        <label
          htmlFor={fieldId}
          className="text-sm font-mono text-foreground font-medium"
        >
          {input.key}
        </label>
        <TypeBadge type={input.inputType} />
        {input.required ? (
          <Badge
            variant="outline"
            className="h-4 text-[10px] px-1.5 py-0 font-mono border-destructive/30 text-destructive/80 bg-destructive/5"
          >
            required
          </Badge>
        ) : (
          <Badge
            variant="outline"
            className="h-4 text-[10px] px-1.5 py-0 font-mono border-border text-muted-foreground/50"
          >
            optional
          </Badge>
        )}
      </div>

      {/* Description helper text */}
      {input.description && (
        <p className="text-xs text-muted-foreground/70 font-body leading-relaxed -mt-1">
          {input.description}
        </p>
      )}

      {/* File attach for document capabilities */}
      {showFileAttach && (
        <FileAttachButton
          fieldKey={input.key}
          onContent={(text) => onChange(text)}
        />
      )}

      {/* Input control */}
      {input.inputType === "boolean" ? (
        <div className="flex items-center gap-3 min-h-[44px]">
          <Switch
            id={fieldId}
            checked={value as boolean}
            onCheckedChange={(checked) => onChange(checked)}
            data-ocid={`field-${input.key}`}
          />
          <span className="text-xs font-mono text-muted-foreground">
            {(value as boolean) ? "true" : "false"}
          </span>
        </div>
      ) : isLong ? (
        <textarea
          id={fieldId}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
          data-ocid={`field-${input.key}`}
          rows={5}
          className="w-full px-3 py-3 rounded-lg border border-input bg-background font-mono text-sm text-foreground resize-y focus:outline-none focus:ring-2 focus:ring-ring placeholder:text-muted-foreground/40 leading-relaxed"
          placeholder={
            showFileAttach
              ? `Attach a file above or paste ${input.key} here…`
              : `Enter ${input.key}…`
          }
        />
      ) : input.inputType === "number" || input.inputType === "integer" ? (
        <input
          id={fieldId}
          type="number"
          value={value as number}
          onChange={(e) => onChange(Number(e.target.value))}
          data-ocid={`field-${input.key}`}
          className="w-full px-3 py-3 rounded-lg border border-input bg-background font-mono text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring min-h-[44px]"
        />
      ) : (
        <input
          id={fieldId}
          type="text"
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
          data-ocid={`field-${input.key}`}
          className="w-full px-3 py-3 rounded-lg border border-input bg-background font-mono text-sm text-foreground focus:outline-none focus:ring-2 focus:ring-ring placeholder:text-muted-foreground/40 min-h-[44px]"
          placeholder={`Enter ${input.key}…`}
        />
      )}
    </div>
  );
}

export function CapabilityForm({
  capability,
  mode,
  jsonValue,
  onJsonChange,
  onModeChange,
  validationErrors,
}: Props) {
  const isDocumentCapability = DOCUMENT_CAPABILITIES.has(capability.name);

  const [fields, setFields] = useState<
    Record<string, string | boolean | number>
  >(() => {
    const defaults: Record<string, string | boolean | number> = {};
    for (const inp of capability.inputs) {
      defaults[inp.key] = getDefaultValue(inp.inputType);
    }
    try {
      const parsed = JSON.parse(jsonValue) as Record<
        string,
        string | boolean | number
      >;
      for (const inp of capability.inputs) {
        if (inp.key in parsed) defaults[inp.key] = parsed[inp.key];
      }
    } catch {
      // ignore
    }
    return defaults;
  });

  const handleFieldChange = (key: string, val: string | boolean | number) => {
    const next = { ...fields, [key]: val };
    setFields(next);
    onJsonChange(buildJsonFromFields(next));
  };

  const onJsonChangeRef = useRef(onJsonChange);
  onJsonChangeRef.current = onJsonChange;

  // Sync fields when jsonValue changes externally (e.g. "Load Example" button)
  const prevJsonRef = useRef(jsonValue);
  useEffect(() => {
    if (prevJsonRef.current === jsonValue) return;
    prevJsonRef.current = jsonValue;
    try {
      const parsed = JSON.parse(jsonValue) as Record<
        string,
        string | boolean | number
      >;
      const next: Record<string, string | boolean | number> = {};
      for (const inp of capability.inputs) {
        next[inp.key] =
          inp.key in parsed ? parsed[inp.key] : getDefaultValue(inp.inputType);
      }
      setFields(next);
    } catch {
      // keep fields as-is if JSON is invalid
    }
  }, [jsonValue, capability.inputs]);

  useEffect(() => {
    const defaults: Record<string, string | boolean | number> = {};
    for (const inp of capability.inputs) {
      defaults[inp.key] = getDefaultValue(inp.inputType);
    }
    setFields(defaults);
    onJsonChangeRef.current(buildJsonFromFields(defaults));
  }, [capability]);

  // Partition required vs optional
  const requiredInputs = capability.inputs.filter((i) => i.required);
  const optionalInputs = capability.inputs.filter((i) => !i.required);

  return (
    <div className="flex flex-col lg:h-full lg:overflow-hidden">
      {/* Mode toggle + header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-border bg-secondary/20 shrink-0">
        <span className="text-sm font-mono text-muted-foreground">Input</span>
        <fieldset
          className="flex items-center border border-border rounded-lg overflow-hidden"
          aria-label="Input mode"
        >
          {(["form", "json"] as const).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => onModeChange(m)}
              data-ocid={`mode-${m}`}
              className={cn(
                "px-4 py-2 text-sm font-mono transition-smooth min-h-[40px]",
                mode === m
                  ? "bg-secondary text-foreground"
                  : "text-muted-foreground hover:text-foreground",
              )}
            >
              {m}
            </button>
          ))}
        </fieldset>
      </div>

      {/* Validation errors */}
      {validationErrors.length > 0 && (
        <div className="px-4 py-3 bg-destructive/10 border-b border-destructive/20 shrink-0 space-y-1">
          {validationErrors.map((err) => (
            <div
              key={err}
              className="flex items-start gap-2 text-sm font-mono text-destructive"
            >
              <AlertCircle size={14} className="mt-0.5 shrink-0" />
              {err}
            </div>
          ))}
        </div>
      )}

      {/* Body */}
      <div className="lg:flex-1 lg:overflow-y-auto">
        {mode === "json" ? (
          <textarea
            value={jsonValue}
            onChange={(e) => onJsonChange(e.target.value)}
            data-ocid="input-json"
            spellCheck={false}
            className="w-full lg:h-full p-4 bg-background font-mono text-sm text-foreground resize-none focus:outline-none placeholder:text-muted-foreground/40 min-h-[240px] lg:min-h-0 leading-relaxed"
            placeholder={'{\n  "key": "value"\n}'}
          />
        ) : capability.inputs.length === 0 ? (
          <div className="flex items-center justify-center py-12 lg:h-full">
            <div className="flex items-center gap-2 text-sm text-muted-foreground font-mono">
              <CheckCircle2 size={16} className="text-chart-2" />
              No input parameters required
            </div>
          </div>
        ) : (
          <div className="p-4 space-y-6">
            {/* Required fields */}
            {requiredInputs.map((inp) => (
              <FieldRow
                key={inp.key}
                input={inp}
                value={fields[inp.key] ?? getDefaultValue(inp.inputType)}
                onChange={(v) => handleFieldChange(inp.key, v)}
                isDocumentCapability={isDocumentCapability}
              />
            ))}

            {/* Optional divider + fields */}
            {optionalInputs.length > 0 && (
              <>
                {requiredInputs.length > 0 && (
                  <div className="flex items-center gap-3 pt-2">
                    <div className="flex-1 border-t border-border" />
                    <span className="text-[11px] font-mono text-muted-foreground/50 uppercase tracking-wider shrink-0">
                      Optional Parameters
                    </span>
                    <div className="flex-1 border-t border-border" />
                  </div>
                )}
                {optionalInputs.map((inp) => (
                  <FieldRow
                    key={inp.key}
                    input={inp}
                    value={fields[inp.key] ?? getDefaultValue(inp.inputType)}
                    onChange={(v) => handleFieldChange(inp.key, v)}
                    isDocumentCapability={isDocumentCapability}
                  />
                ))}
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
