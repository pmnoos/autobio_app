param(
  [Parameter(Mandatory=$true)][string]$PdfPath,
  [string]$OutPath = "bio.wav",
  [string]$Voice = "",
  [int]$Rate = 0,
  [int]$Volume = 100,
  [switch]$PickVoice
)

function Ensure-Ruby {
  $rubyVersion = & ruby -v 2>$null
  if (-not $rubyVersion) { throw "Ruby not found in PATH. Please install Ruby and retry." }
}

function Ensure-PdfReaderGem {
  $check = & ruby -e "begin; require 'pdf-reader'; puts 'ok'; rescue LoadError; puts 'missing'; end"
  if ($check -match 'missing') {
    Write-Host "Installing pdf-reader gem..." -ForegroundColor Yellow
    $install = & gem install pdf-reader --no-document 2>&1
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to install pdf-reader gem. Try: gem install --user-install pdf-reader"
    }
  }
}

function Split-ByLength([string]$s, [int]$len) {
  for ($i=0; $i -lt $s.Length; $i += $len) {
    $end = [Math]::Min($len, $s.Length - $i)
    $s.Substring($i, $end)
  }
}

# Validate input PDF
if (-not (Test-Path -Path $PdfPath)) { throw "Input PDF not found: $PdfPath" }

# Resolve script dir and helper
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rubyHelper = Join-Path $ScriptDir 'pdf_to_text.rb'
if (-not (Test-Path $rubyHelper)) { throw "Helper not found: $rubyHelper" }

# Ensure prerequisites
Ensure-Ruby
Ensure-PdfReaderGem

# Temp text path
$tmpName = [System.Guid]::NewGuid().ToString() + '.txt'
$tmpTxt = Join-Path ([System.IO.Path]::GetTempPath()) $tmpName

# Extract PDF → text
Write-Host "Extracting text from PDF..." -ForegroundColor Cyan
& ruby $rubyHelper $PdfPath $tmpTxt
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmpTxt)) { throw "Text extraction failed." }

# Read text
$text = Get-Content -Raw $tmpTxt

# Setup SpeechSynthesizer
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

function Get-InstalledVoicesInfo {
  $synth.GetInstalledVoices() | ForEach-Object {
    $_.VoiceInfo | Select-Object Name, Culture, Gender, Description
  }
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

# Speak in chunks (paragraphs, then 4000-char chunks)
$paragraphs = $text -split "(\r?\n){2,}"
foreach ($p in $paragraphs) {
  $p2 = $p.Trim()
  if ($p2.Length -gt 0) {
    if ($p2.Length -le 4000) { $synth.Speak($p2) }
    else { Split-ByLength $p2 4000 | ForEach-Object { $synth.Speak($_) } }
  }
}

$synth.Dispose()

# Cleanup
Remove-Item $tmpTxt -ErrorAction SilentlyContinue
Write-Host "Done. Wrote audio to: $OutPath" -ForegroundColor Green
