# Windows version of allow-models.sh. Same behavior.
# Allows a prompt only when the selected model matches a line in allowed-models.txt,
# which lives next to this script.

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$listFile = Join-Path $scriptDir "allowed-models.txt"
$listLabel = ".cursor/hooks/allowed-models.txt"

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
        elseif ($code -lt 32) { [void]$sb.AppendFormat('\u{0:x4}', $code) }
        else { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

function Write-Allow {
    [Console]::Out.WriteLine('{"continue":true}')
}

function Write-Deny([string]$message) {
    $escaped = Escape-Json $message
    [Console]::Out.WriteLine('{"continue":false,"user_message":"' + $escaped + '"}')
}

if (-not (Test-Path -LiteralPath $listFile)) {
    Write-Deny "The allow list is missing: $listLabel"
    exit 0
}

$allowed = New-Object System.Collections.Generic.List[string]
Get-Content -LiteralPath $listFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $allowed.Add($line.ToLowerInvariant())
}

if ($allowed.Count -eq 0) {
    Write-Deny "The allow list in $listLabel is empty. Add a model name, one per line."
    exit 0
}

try {
    $payload = $raw | ConvertFrom-Json
} catch {
    Write-Deny "This prompt did not include a model name, so it was refused."
    exit 0
}

$model = Get-Prop $payload "model"
if ($model -isnot [string] -or $model -eq "") {
    Write-Deny "This prompt did not include a model name, so it was refused."
    exit 0
}

$haystack = $model.ToLowerInvariant()
foreach ($piece in $allowed) {
    if ($haystack.Contains($piece)) {
        Write-Allow
        exit 0
    }
}

Write-Deny "$haystack is not on the allow list in $listLabel"
exit 0
