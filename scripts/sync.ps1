# Merge local/global Codex memory with the GitHub-backed repo.
#
# Behavior:
# - Pulls latest main.
# - Merges JSONL by `id` (prefers the entry with the newer `ts` when both exist).
# - Writes merged output to BOTH:
#   - C:\Users\A\.codex\memory\long_term_memory.jsonl
#   - <repo>\ltm\long_term_memory.jsonl
# - Commits + pushes only if repo file changed.
#
param(
  [string]$RepoDir = "C:\\Users\\A\\.codex\\memory-repos\\codex-agent-memory",
  [string]$LocalJsonl = "C:\\Users\\A\\.codex\\memory\\long_term_memory.jsonl",
  [string]$Branch = "main"
)

$ErrorActionPreference = 'Stop'

function Read-Jsonl([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return @() }
  $lines = Get-Content -LiteralPath $path -ErrorAction SilentlyContinue
  $out = New-Object System.Collections.Generic.List[object]
  foreach ($line in $lines) {
    $trim = $(if ($null -ne $line) { [string]$line } else { "" }).Trim()
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

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'git not found' }
if (-not (Test-Path -LiteralPath (Join-Path $RepoDir '.git'))) { throw "Not a git repo: $RepoDir" }

# Pull latest
$headBranch = (git -C $RepoDir rev-parse --abbrev-ref HEAD).Trim()
if ($headBranch -ne $Branch) {
  git -C $RepoDir checkout -B $Branch
}

git -C $RepoDir fetch --all --prune
$hasRemoteBranch = $false
try {
  $probe = git -C $RepoDir ls-remote --heads origin $Branch
  if ($probe) { $hasRemoteBranch = $true }
} catch { }
if ($hasRemoteBranch) {
  try { git -C $RepoDir pull --ff-only origin $Branch } catch { }
}

$repoJsonl = Join-Path $RepoDir 'ltm\\long_term_memory.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path $repoJsonl) | Out-Null

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

$merged = $byId.Values | Sort-Object { Get-Ts $_ } | ForEach-Object { To-JsonLine $_ }
$mergedText = ($merged -join "`n") + "`n"

# Write both
$localDir = Split-Path $LocalJsonl
New-Item -ItemType Directory -Force -Path $localDir | Out-Null
Set-Content -LiteralPath $LocalJsonl -Value $mergedText -Encoding utf8
Set-Content -LiteralPath $repoJsonl -Value $mergedText -Encoding utf8

# Commit + push if changed
$changed = git -C $RepoDir status --porcelain
if ($changed) {
  git -C $RepoDir add -A
  $msg = "sync memory " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
  git -C $RepoDir commit -m $msg
  git -C $RepoDir push -u origin $Branch
  Write-Host "Pushed updates to origin/$Branch"
} else {
  Write-Host "No changes to push"
}

