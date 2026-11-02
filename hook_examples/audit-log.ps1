# Windows version of audit-log.sh. Same behavior: write one JSON line per event, then allow it.
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$rawParts = @($input | ForEach-Object { "$_" })
$raw = $rawParts -join "`n"
if ([string]::IsNullOrWhiteSpace($raw) -and [Console]::IsInputRedirected) {
    $raw = [Console]::In.ReadToEnd()
}
if ($null -eq $raw) { $raw = "" }
$raw = $raw.TrimStart([char]0xFEFF).Trim()
if ($raw -eq "") { $raw = "{}" }

function Get-Prop($obj, [string]$name) {
    if ($null -eq $obj) { return $null }
    $prop = $obj.PSObject.Properties[$name]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}

function Get-Preview([string]$text, [int]$max) {
    if ([string]::IsNullOrEmpty($text)) { return $null }
    $normalized = ([regex]::Replace($text, "\s+", " ")).Trim()
    if ($normalized.Length -le $max) { return $normalized }
    return $normalized.Substring(0, $max) + "..."
}

function Test-Number($value) {
    return ($value -is [byte]) -or ($value -is [int]) -or ($value -is [long]) -or ($value -is [double]) -or ($value -is [decimal]) -or ($value -is [single])
}

function Get-ListCount($value) {
    if ($null -eq $value) { return $null }
    if ($value -is [System.Array]) { return @($value).Count }
    return 1
}

function Escape-Json([string]$text) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $text.ToCharArray()) {
        $code = [int]$ch
        if ($code -eq 34) { [void]$sb.Append('\"') }
        elseif ($code -eq 92) { [void]$sb.Append('\\') }
        elseif ($code -eq 8) { [void]$sb.Append('\b') }
        elseif ($code -eq 12) { [void]$sb.Append('\f') }
        elseif ($code -eq 10) { [void]$sb.Append('\n') }
        elseif ($code -eq 13) { [void]$sb.Append('\r') }
        elseif ($code -eq 9) { [void]$sb.Append('\t') }
        elseif ($code -lt 32) { [void]$sb.Append("\u" + ("{0:x4}" -f $code)) }
        else { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

function Add-JsonField($fields, [string]$name, $value, [string]$kind) {
    $encoded = switch ($kind) {
        "string" { '"' + (Escape-Json ([string]$value)) + '"' }
        "bool" { if ($value) { "true" } else { "false" } }
        "number" { [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0}", $value) }
    }
    $fields.Add('"' + $name + '":' + $encoded)
}

$maxPreview = 240
if ($env:CURSOR_HOOK_LOG_PREVIEW_CHARS -match '^[0-9]+$') {
    $maxPreview = [int]$env:CURSOR_HOOK_LOG_PREVIEW_CHARS
}
$logDir = ".cursor/hook-logs"
if ($env:CURSOR_HOOK_LOG_DIR) { $logDir = $env:CURSOR_HOOK_LOG_DIR }
$logFile = Join-Path ($logDir.TrimEnd('\', '/')) "audit.jsonl"
$verbose = ($env:CURSOR_HOOK_LOG_VERBOSE -eq "1")

try {
    $payload = $raw | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("audit-log.ps1 could not read the hook JSON")
    exit 1
}

$eventName = Get-Prop $payload "hook_event_name"
$prompt = Get-Prop $payload "prompt"
$command = Get-Prop $payload "command"
$output = Get-Prop $payload "output"
$filePath = Get-Prop $payload "file_path"
$edits = Get-Prop $payload "edits"

if ($eventName -is [string]) {
    $event = $eventName
} elseif ($prompt -is [string]) {
    $event = "beforeSubmitPrompt"
} elseif (($command -is [string]) -and ($output -is [string])) {
    $event = "afterShellExecution"
} elseif ($command -is [string]) {
    $event = "beforeShellExecution"
} elseif (($filePath -is [string]) -and ($null -ne $edits)) {
    $event = "afterFileEdit"
} else {
    $event = "unknown"
}

$fields = New-Object System.Collections.Generic.List[string]
Add-JsonField $fields "timestamp" ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.000Z")) "string"
Add-JsonField $fields "event" $event "string"

$cwd = Get-Prop $payload "cwd"
if ($cwd -is [string]) { Add-JsonField $fields "cwd" $cwd "string" }
if ($command -is [string]) { Add-JsonField $fields "command" $command "string" }
if ($prompt -is [string]) {
    Add-JsonField $fields "prompt_length" $prompt.Length "number"
    $preview = Get-Preview $prompt $maxPreview
    if ($null -ne $preview) { Add-JsonField $fields "prompt_preview" $preview "string" }
}

$attachments = Get-Prop $payload "attachments"
$attachmentsCount = Get-ListCount $attachments
if ($null -ne $attachmentsCount) { Add-JsonField $fields "attachments_count" $attachmentsCount "number" }
if ($filePath -is [string]) { Add-JsonField $fields "file_path" $filePath "string" }
$editsCount = Get-ListCount $edits
if ($null -ne $editsCount) { Add-JsonField $fields "edits_count" $editsCount "number" }

$duration = Get-Prop $payload "duration"
if (Test-Number $duration) { Add-JsonField $fields "duration_ms" $duration "number" }
if ($output -is [string]) {
    Add-JsonField $fields "output_length" $output.Length "number"
    if ($verbose) {
        $outputPreview = Get-Preview $output $maxPreview
        if ($null -ne $outputPreview) { Add-JsonField $fields "output_preview" $outputPreview "string" }
    }
}

$sandbox = Get-Prop $payload "sandbox"
if ($sandbox -is [bool]) { Add-JsonField $fields "sandbox" $sandbox "bool" }

$record = "{" + ($fields -join ",") + "}"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::AppendAllText($logFile, $record + "`n", $utf8)

switch ($event) {
    "beforeSubmitPrompt" { [Console]::Out.WriteLine('{"continue":true}') }
    "beforeShellExecution" { [Console]::Out.WriteLine('{"permission":"allow"}') }
    default { [Console]::Out.WriteLine("{}") }
}
exit 0
