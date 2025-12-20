param(
  [Parameter(Mandatory = $true)][string]$Type,
  [Parameter(Mandatory = $true)][string]$Summary,
  [int]$Priority = 3,
  [string[]]$Topic = @(),
  [string[]]$Triggers = @(),
  [string]$JsonlPath = "C:\\Users\\A\\.codex\\memory\\long_term_memory.jsonl"
)

$ErrorActionPreference = 'Stop'

if ($Priority -lt 1 -or $Priority -gt 5) { throw "Priority must be 1..5" }

$ts = [DateTimeOffset]::Now.ToString("yyyy-MM-ddTHH:mm:sszzz")
$id = "LTM-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + ([Guid]::NewGuid().ToString("N").Substring(0, 6)).ToUpper()

$entry = [ordered]@{
  id = $id
  ts = $ts
  type = $Type
  topic = $Topic
  summary = $Summary
  triggers = $Triggers
  priority = $Priority
  status = "active"
}

$line = ($entry | ConvertTo-Json -Compress -Depth 20)

New-Item -ItemType Directory -Force -Path (Split-Path $JsonlPath) | Out-Null
Add-Content -LiteralPath $JsonlPath -Value $line -Encoding utf8

Write-Host "Appended: $id -> $JsonlPath"
