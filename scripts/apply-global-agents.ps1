param(
  [Parameter(Mandatory=$true)][string]$WorkspacePath,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$template = Join-Path $PSScriptRoot '..\\AGENTS.template.md'
if (-not (Test-Path -LiteralPath $template)) {
  throw "Missing template: $template"
}

$dest = Join-Path $WorkspacePath 'AGENTS.md'
if ((Test-Path -LiteralPath $dest) -and (-not $Force)) {
  Write-Host "AGENTS.md already exists: $dest"
  Write-Host "Use -Force to overwrite, or manually merge." 
  exit 0
}

New-Item -ItemType Directory -Force -Path $WorkspacePath | Out-Null
Copy-Item -LiteralPath $template -Destination $dest -Force
Write-Host "Wrote: $dest"
