param(
  [string]$RepoDir = "C:\\Users\\A\\.codex\\memory-repos\\codex-agent-memory"
)

$ErrorActionPreference = 'Stop'
$sync = Join-Path $RepoDir 'scripts\\sync.ps1'
if (-not (Test-Path -LiteralPath $sync)) { throw "Missing: $sync" }

powershell -ExecutionPolicy Bypass -File $sync -RepoDir $RepoDir
