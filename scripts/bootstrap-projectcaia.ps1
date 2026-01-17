param(
  [string]$BaseDir = "C:\\Users\\A\\Documents\\GitHub\\projectcaia",
  [switch]$UseSsh,
  [switch]$ForceAgents
)

$ErrorActionPreference = 'Stop'

$repos = @(
  'caia-memory',
  'FastAPI-Sentinel',
  'caia-genspark-bridge',
  'Caia-agent',
  'caia-evolve',
  'caia-agent-core',
  'connector-hub',
  'caia-core',
  'caia-mcp-gate-way'
)

function Get-RepoUrl([string]$name) {
  if ($UseSsh) {
    return "git@github.com:projectcaia/$name.git"
  }
  return "https://github.com/projectcaia/$name.git"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'git not found. Install Git for Windows first.'
}

New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null

$applyAgents = Join-Path $PSScriptRoot 'apply-global-agents.ps1'
if (-not (Test-Path -LiteralPath $applyAgents)) {
  throw "Missing: $applyAgents"
}

foreach ($name in $repos) {
  $dir = Join-Path $BaseDir $name
  $url = Get-RepoUrl $name

  if (Test-Path -LiteralPath (Join-Path $dir '.git')) {
    Write-Host "[pull] $name ($dir)"
    git -C $dir fetch --all --prune
    git -C $dir pull --ff-only
  } else {
    Write-Host "[clone] $name -> $dir"
    git clone $url $dir
  }

  if ($ForceAgents) {
    & $applyAgents -WorkspacePath $dir -Force
  } else {
    & $applyAgents -WorkspacePath $dir
  }
}

Write-Host "Done. BaseDir=$BaseDir"
