#
# Sync Codex long-term memory between:
# - Local file: C:\Users\A\.codex\memory\long_term_memory.jsonl
# - Git repo:   <repo>\ltm\long_term_memory.jsonl
#
# Notes:
# - Offline-safe: fetch/pull/push are best-effort.
# - Merge strategy: unique `id`, newer `ts` wins when both exist.
# - Safety: refuses to proceed if obvious secret patterns are detected.
#
param(
  [string]$RepoDir = "C:\\Users\\A\\.codex\\memory-repos\\codex-agent-memory",
  [string]$LocalJsonl = "C:\\Users\\A\\.codex\\memory\\long_term_memory.jsonl",
  [string]$Branch = "main",
  [switch]$GenerateViews = $true
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
    try {
      $obj = $trim | ConvertFrom-Json -ErrorAction Stop
      if ($null -eq $obj.id -or [string]::IsNullOrWhiteSpace([string]$obj.id)) { continue }
      $out.Add($obj)
    } catch {
      continue
    }
  }
  return ,$out.ToArray()
}

function To-JsonLine($obj) {
  return ($obj | ConvertTo-Json -Compress -Depth 20)
}

function Get-Ts($obj) {
  try {
    if ($null -eq $obj.ts) { return [DateTimeOffset]::MinValue }
    return [DateTimeOffset]::Parse([string]$obj.ts)
  } catch {
    return [DateTimeOffset]::MinValue
  }
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
    if ($text -match $p) { throw "Potential secret detected (pattern: $p). Refusing to sync/push." }
  }
}

function Assert-EntriesBasic($entries) {
  $seen = @{}
  foreach ($e in $entries) {
    if ($null -eq $e.id -or [string]::IsNullOrWhiteSpace([string]$e.id)) { throw "Invalid entry: missing id" }
    $id = [string]$e.id
    if ($seen.ContainsKey($id)) { throw "Duplicate id detected: $id" }
    $seen[$id] = $true
  }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git not found' }
if (-not (Test-Path -LiteralPath (Join-Path $RepoDir '.git'))) { throw "Not a git repo: $RepoDir" }

# Best-effort fetch/pull (offline-safe)
$headBranch = ''
try { $headBranch = (git -C $RepoDir rev-parse --abbrev-ref HEAD).Trim() } catch { $headBranch = '' }
if ($headBranch -ne $Branch) { try { git -C $RepoDir checkout -B $Branch | Out-Null } catch { } }

$networkOk = $true
try { git -C $RepoDir fetch --all --prune | Out-Null } catch { $networkOk = $false }
if ($networkOk) {
  $hasRemoteBranch = $false
  try {
    $probe = git -C $RepoDir ls-remote --heads origin $Branch
    if ($probe) { $hasRemoteBranch = $true }
  } catch { }
  if ($hasRemoteBranch) {
    try { git -C $RepoDir pull --ff-only origin $Branch | Out-Null } catch { }
  }
}

$repoJsonl = Join-Path $RepoDir 'ltm\\long_term_memory.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $repoJsonl) | Out-Null

if (Test-Path -LiteralPath $LocalJsonl) {
  $localRaw = Get-Content -LiteralPath $LocalJsonl -Raw -ErrorAction SilentlyContinue
  if ($null -eq $localRaw) { $localRaw = '' }
  Assert-NoSecrets $localRaw
}

$local = Read-Jsonl $LocalJsonl
$remote = Read-Jsonl $repoJsonl

$byId = @{}
foreach ($e in $remote) { $byId[[string]$e.id] = $e }
foreach ($e in $local) {
  $id = [string]$e.id
  if (-not $byId.ContainsKey($id)) { $byId[$id] = $e; continue }
  $a = $byId[$id]
  if ((Get-Ts $e) -gt (Get-Ts $a)) { $byId[$id] = $e }
}

Assert-EntriesBasic ($byId.Values)

$merged = $byId.Values | Sort-Object { Get-Ts $_ } | ForEach-Object { To-JsonLine $_ }
$mergedText = ($merged -join "`n") + "`n"
Assert-NoSecrets $mergedText

# Write both
$localDir = Split-Path $LocalJsonl
New-Item -ItemType Directory -Force -Path $localDir | Out-Null
Set-Content -LiteralPath $LocalJsonl -Value $mergedText -Encoding utf8
Set-Content -LiteralPath $repoJsonl -Value $mergedText -Encoding utf8

# Render views (optional)
if ($GenerateViews) {
  $render = Join-Path $RepoDir 'scripts\\render-views.ps1'
  if (Test-Path -LiteralPath $render) {
    try { powershell -ExecutionPolicy Bypass -File $render -RepoDir $RepoDir | Out-Null } catch { }
  }
}

# Validate (optional)
$validate = Join-Path $RepoDir 'scripts\\validate.ps1'
if (Test-Path -LiteralPath $validate) {
  powershell -ExecutionPolicy Bypass -File $validate -JsonlPath $repoJsonl | Out-Null
}

# Commit + push if changed
$changed = git -C $RepoDir status --porcelain
if ($changed) {
  git -C $RepoDir add -A
  $msg = "sync memory " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " (" + $byId.Count + " entries)"
  git -C $RepoDir commit -m $msg

  if ($networkOk) {
    try {
      git -C $RepoDir push -u origin $Branch
      Write-Host "Pushed updates to origin/$Branch"
    } catch {
      Write-Host "Commit created but push failed (offline?)."
    }
  } else {
    Write-Host "Commit created but network unavailable; push skipped."
  }
} else {
  Write-Host "No changes to push"
}
