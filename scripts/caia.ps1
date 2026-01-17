param(
  [Parameter(Position=0)]
  [ValidateSet("today","end","promote","state")]
  [string]$Cmd = "today",

  [Parameter(ValueFromRemainingArguments=$true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'

& "C:\Users\A\.caia-core\work\caia.ps1" -Cmd $Cmd -Args $Args

