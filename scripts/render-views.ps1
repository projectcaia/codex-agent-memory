param(
  [Parameter(Mandatory = $true)]
  [string]$RepoDir,
  [string]$JsonlRelPath = "ltm\\long_term_memory.jsonl",
  [string]$OutRelPath = "views\\ltm-summary.md"
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
    try { $out.Add(($trim | ConvertFrom-Json -ErrorAction Stop)) } catch { }
  }
  return ,$out.ToArray()
}

function Get-Ts($obj) {
  try {
    if ($null -eq $obj.ts) { return [DateTimeOffset]::MinValue }
    return [DateTimeOffset]::Parse([string]$obj.ts)
  } catch {
    return [DateTimeOffset]::MinValue
  }
}

$jsonlPath = Join-Path $RepoDir $JsonlRelPath
$outPath = Join-Path $RepoDir $OutRelPath
New-Item -ItemType Directory -Force -Path (Split-Path $outPath) | Out-Null

$entries = Read-Jsonl $jsonlPath
$latest = ($entries | Sort-Object { Get-Ts $_ } | Select-Object -Last 1)
$byPriority = $entries |
  Group-Object { if ($null -eq $_.priority) { 0 } else { [int]$_.priority } } |
  Sort-Object Name -Descending

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# LTM Summary')
$lines.Add('')
$lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
if ($latest) { $lines.Add("Latest ts: $([string]$latest.ts)") }
$lines.Add("Count: $($entries.Count)")
$lines.Add('')

foreach ($g in $byPriority) {
  $p = [int]$g.Name
  if ($p -le 0) { continue }
  $lines.Add("## Priority $p")
  foreach ($e in ($g.Group | Sort-Object { Get-Ts $_ } -Descending)) {
    $type = if ($e.type) { "[$($e.type)] " } else { '' }
    $id = [string]$e.id
    $summary = [string]$e.summary
    $lines.Add("- $type$summary (id: $id)")
  }
  $lines.Add('')
}

Set-Content -LiteralPath $outPath -Value ($lines -join "`n") -Encoding utf8
Write-Host "Wrote: $outPath"
