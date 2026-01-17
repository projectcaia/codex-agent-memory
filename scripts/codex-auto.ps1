param(
  [string]$Cd = "",
  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

$ErrorActionPreference='Stop'

$cmd = @('codex','--full-auto')
if ($Cd -and $Cd.Trim().Length -gt 0) {
  $cmd += @('-C', $Cd)
}
if ($Args) { $cmd += $Args }

& $cmd[0] $cmd[1..($cmd.Count-1)]
