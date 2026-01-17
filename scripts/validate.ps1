param(
  [Parameter(Mandatory = $true)]
  [string]$JsonlPath
)

$ErrorActionPreference = 'Stop'

function Read-Jsonl([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  $lines = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($line in $lines) {
    $trim = $line
    if ($null -eq $trim) { $trim = '' }
    $trim = ([string]$trim).Trim()
    if ($trim.Length -eq 0) { continue }
    $obj = $trim | ConvertFrom-Json -ErrorAction Stop
    $out.Add($obj)
  }
  return ,$out.ToArray()
}

function Assert-NoSecrets([string]$text) {
  $patterns = @(
    'ghp_[A-Za-z0-9]{20,}',                 # GitHub classic PAT
    'github_pat_[A-Za-z0-9_]{20,}',         # fine-grained PAT
    '-----BEGIN [A-Z ]*PRIVATE KEY-----',   # private keys
    '\bAKIA[0-9A-Z]{16}\b',                 # AWS access key id
    '\bsk-[A-Za-z0-9]{20,}\b'               # common API key prefix (OpenAI-style)
  )
  foreach ($p in $patterns) {
    if ($text -match $p) { throw "Potential secret detected (pattern: $p). Refusing to proceed." }
  }
}

if (-not (Test-Path -LiteralPath $JsonlPath)) { throw "Not found: $JsonlPath" }

$raw = Get-Content -LiteralPath $JsonlPath -Raw -ErrorAction Stop
Assert-NoSecrets $raw

$entries = Read-Jsonl $JsonlPath

$ids = @{}
foreach ($e in $entries) {
  if ($null -eq $e.id -or [string]::IsNullOrWhiteSpace([string]$e.id)) { throw 'Missing required field: id' }
  if ($null -eq $e.summary -or [string]::IsNullOrWhiteSpace([string]$e.summary)) {
    throw "Missing required field: summary (id=$($e.id))"
  }
  $id = [string]$e.id
  if ($ids.ContainsKey($id)) { throw "Duplicate id detected: $id" }
  $ids[$id] = $true
  if ($null -ne $e.priority) {
    $p = [int]$e.priority
    if ($p -lt 1 -or $p -gt 5) { throw "priority must be 1..5 (id=$id)" }
  }
}

Write-Host "OK: $($entries.Count) entries validated in $JsonlPath"
