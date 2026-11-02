# Windows version of sensitive-prompt-guard.sh. Same behavior: refuse a prompt that looks like a secret.
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

try {
    $payload = $raw | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("sensitive-prompt-guard.ps1 could not read the hook JSON")
    exit 1
}

$prompt = Get-Prop $payload "prompt"
if ($prompt -isnot [string]) { $prompt = "" }
$promptLower = $prompt.ToLowerInvariant()
$found = New-Object System.Collections.Generic.List[string]

# -cmatch is case-sensitive, same as the bash script. -match would ignore case.
if ($promptLower -cmatch '-----begin (rsa |dsa |ec |openssh |pgp )?private key-----') {
    $found.Add("private key")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_-])crsr_[A-Za-z0-9_-]{20,}([^A-Za-z0-9_-]|$)') {
    $found.Add("Cursor API key")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_])(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9_]{30,}([^A-Za-z0-9_]|$)') {
    $found.Add("GitHub token")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_-])xox[baprs]-[A-Za-z0-9-]{20,}([^A-Za-z0-9_-]|$)') {
    $found.Add("Slack token")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_-])sk-[A-Za-z0-9_-]{32,}([^A-Za-z0-9_-]|$)') {
    $found.Add("OpenAI API key")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_])(AKIA|ASIA)[A-Z0-9]{16}([^A-Za-z0-9_]|$)') {
    $found.Add("AWS access key ID")
}
if ($prompt -cmatch '(^|[^A-Za-z0-9_-])eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}([^A-Za-z0-9_-]|$)') {
    $found.Add("JWT-like token")
}
if ($prompt -cmatch '(^|[^0-9])([0-9][ \-]*){13,19}([^0-9]|$)') {
    $found.Add("credit card-like number")
}

if ($found.Count -gt 0) {
    $matchList = $found -join ", "
    $message = "This prompt appears to contain sensitive data ($matchList). Remove or replace the sensitive value before resubmitting."
    [Console]::Out.WriteLine('{"continue":false,"user_message":"' + (Escape-Json $message) + '"}')
} else {
    [Console]::Out.WriteLine('{"continue":true}')
}
exit 0
