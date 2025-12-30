param(
  [Parameter(Mandatory=$true)][string]$TextPath,
  [string]$OutPath = "output.wav",
  [string]$Voice = "",
  [int]$Rate = 0,
  [int]$Volume = 100,
  [switch]$PickVoice
)

if (-not (Test-Path -Path $TextPath)) { throw "Input text file not found: $TextPath" }

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

function Get-InstalledVoicesInfo {
  $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo | Select-Object Name, Culture, Gender, Description }
}

$installedVoices = Get-InstalledVoicesInfo

if ($PickVoice -and -not $Voice) {
  Write-Host "Installed voices:" -ForegroundColor Cyan
  for ($i = 0; $i -lt $installedVoices.Count; $i++) {
    $v = $installedVoices[$i]
    Write-Host ("[{0}] {1} ({2}, {3})" -f $i, $v.Name, $v.Culture, $v.Gender)
  }
  $choice = Read-Host "Enter voice number"
  if ($choice -match '^[0-9]+$' -and [int]$choice -ge 0 -and [int]$choice -lt $installedVoices.Count) {
    $Voice = $installedVoices[[int]$choice].Name
    Write-Host "Using voice: $Voice" -ForegroundColor Green
  } else {
    Write-Warning "Invalid selection; using default voice."
  }
}

if ($Voice) {
  $names = $installedVoices | Select-Object -ExpandProperty Name
  if ($names -contains $Voice) { $synth.SelectVoice($Voice) }
  else { Write-Warning "Requested voice '$Voice' not found. Using default." }
}

$synth.Rate = $Rate
$synth.Volume = $Volume
$synth.SetOutputToWaveFile($OutPath)

# Read text and split by paragraphs (blank lines)
$text = Get-Content -Raw $TextPath
$paragraphs = $text -split "(\r?\n){2,}"

function Split-ByLength([string]$s, [int]$len) { for ($i=0; $i -lt $s.Length; $i += $len) { $end = [Math]::Min($len, $s.Length - $i); $s.Substring($i, $end) } }

foreach ($p in $paragraphs) {
  $p2 = $p.Trim()
  if ($p2.Length -gt 0) {
    if ($p2.Length -le 4000) { $synth.Speak($p2) }
    else { Split-ByLength $p2 4000 | ForEach-Object { $synth.Speak($_) } }
  }
}

$synth.Dispose()
Write-Host "Done. Wrote audio to: $OutPath" -ForegroundColor Green
