param(
  [string]$Cd = "",
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

function New-SessionId() {
  try { return ([guid]::NewGuid().ToString()) } catch { return (Get-Random).ToString() }
}

function Get-SafetySwitch() {
  try {
    $s = Get-Content -LiteralPath "C:\Users\A\.caia-core\memory\STATE.json" -Raw | ConvertFrom-Json
    if ($null -eq $s.safety_switch) { return "on" }
    return [string]$s.safety_switch
  } catch {
    return "on"
  }
}

function Get-AutoUploadFlag() {
  $v = $env:CAIA_AUTO_UPLOAD
  if (-not $v) { return $false }
  $v = $v.Trim().ToLowerInvariant()
  return ($v -eq "1" -or $v -eq "true" -or $v -eq "on" -or $v -eq "yes")
}

function Get-Sha256Hex([string]$text) {
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
  } catch {
    return ""
  }
}

function Append-Trace([string]$tracePath, [hashtable]$row) {
  try {
    $dir = Split-Path -Parent $tracePath
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    ($row | ConvertTo-Json -Compress -Depth 10) | Add-Content -LiteralPath $tracePath -Encoding UTF8
  } catch {
  }
}

function Get-AssistantTextFromPayload($payload) {
  if ($null -eq $payload) { return "" }

  if ($payload.type -eq "message" -and $payload.role -eq "assistant") {
    if ($payload.content -is [string]) { return [string]$payload.content }
    if ($payload.content -is [System.Collections.IEnumerable]) {
      $parts = @()
      foreach ($item in $payload.content) {
        if ($null -eq $item) { continue }
        if ($item.type -eq "output_text" -and $item.text) { $parts += [string]$item.text }
        elseif ($item.text) { $parts += [string]$item.text }
      }
      return ($parts -join "")
    }
  }

  return ""
}

function Send-CaiaNotifyTurnComplete([string]$assistantText, [string]$inputPrompt, [string]$toolsDir) {
  if (-not $assistantText -or $assistantText.Trim().Length -eq 0) { return }

  $payload = @{
    type = "agent-turn-complete"
    input_messages = @(
      @{
        role = "user"
        content = $inputPrompt
      }
    )
    last_assistant_message = $assistantText
  }

  $json = ($payload | ConvertTo-Json -Compress -Depth 6)
  $scriptPath = Join-Path $toolsDir "caia_notify.py"

  if (Test-Path -LiteralPath $scriptPath) {
    try {
      & python $scriptPath $json | Out-Null
    } catch {
    }
  }
}

$toolsDir = "C:\Users\A\.caia-core\tools"
$tracePath = "C:\Users\A\.codex\log\session_trace.ndjson"
$sessionId = New-SessionId
$turn = 0
$safety = Get-SafetySwitch
$autoUpload = Get-AutoUploadFlag

$cmd = @('codex', 'exec', '--json')
if ($Cd -and $Cd.Trim().Length -gt 0) {
  $cmd += @('-C', $Cd)
}
if ($Args) { $cmd += $Args }

$inputPrompt = ""
if ($Args -and $Args.Count -gt 0) {
  $inputPrompt = $Args[0]
}

$userRow = @{
  ts = (Get-Date).ToUniversalTime().ToString("o")
  session_id = $sessionId
  turn = $turn
  role = "user"
  text = $inputPrompt
  cwd = $(if ($Cd -and $Cd.Trim().Length -gt 0) { $Cd } else { (Get-Location).Path })
  tags = @("codex","trace")
}
if ($safety -eq "off") {
  $userRow["text_len"] = $(if ($inputPrompt) { $inputPrompt.Length } else { 0 })
  $userRow["text_sha256"] = Get-Sha256Hex $inputPrompt
  $userRow["text"] = ""
  $userRow["tags"] = @("codex","trace","safety_off")
}
Append-Trace -tracePath $tracePath -row $userRow

& $cmd[0] $cmd[1..($cmd.Count - 1)] 2>&1 | ForEach-Object {
  $line = $_
  Write-Output $line

  $obj = $null
  try { $obj = $line | ConvertFrom-Json -ErrorAction Stop } catch { $obj = $null }
  if ($null -eq $obj) { return }

  $payload = $obj.payload
  $assistantText = Get-AssistantTextFromPayload $payload
  if ($assistantText -and $assistantText.Trim().Length -gt 0) {
    $turn++
    $asstRow = @{
      ts = (Get-Date).ToUniversalTime().ToString("o")
      session_id = $sessionId
      turn = $turn
      role = "assistant"
      text = $assistantText
      cwd = $(if ($Cd -and $Cd.Trim().Length -gt 0) { $Cd } else { (Get-Location).Path })
      tags = @("codex","trace","agent-turn-complete")
      promote_hint = "ersp"
    }
    if ($safety -eq "off") {
      $asstRow["text_len"] = $assistantText.Length
      $asstRow["text_sha256"] = Get-Sha256Hex $assistantText
      $asstRow["text"] = ""
      $asstRow["tags"] = @("codex","trace","agent-turn-complete","safety_off")
    }
    Append-Trace -tracePath $tracePath -row $asstRow

    if ($autoUpload -and $safety -ne "off") {
      Send-CaiaNotifyTurnComplete -assistantText $assistantText -inputPrompt $inputPrompt -toolsDir $toolsDir
    }
  }
}
