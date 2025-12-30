param(
  [switch]$PickVoice,
  [ValidateSet("wav","mp3")][string]$OutFormat = "wav"
)

Add-Type -AssemblyName System.Windows.Forms

# Ensure Single-Threaded Apartment (STA) for dialogs; re-invoke self if needed
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  $argPick = if ($PickVoice) { '-PickVoice' } else { '' }
  $argFmt = "-OutFormat $OutFormat"
  Start-Process -FilePath "powershell" -ArgumentList "-STA -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $argPick $argFmt" -Wait
  exit $LASTEXITCODE
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title = "Select your autobiography PDF"
$dialog.Filter = "PDF files (*.pdf)|*.pdf|All files (*.*)|*.*"
$dialog.Multiselect = $false
$dialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")

$null = $dialog.ShowDialog()

if ([string]::IsNullOrWhiteSpace($dialog.FileName)) {
  Write-Warning "No file selected. Aborting."
  exit 1
}

$pdfPath = $dialog.FileName

# Determine output path next to the PDF
$targetExt = $OutFormat.ToLower()
if ($targetExt -notin @('wav','mp3')) { $targetExt = 'wav' }
$outPath = [System.IO.Path]::ChangeExtension($pdfPath, $targetExt)

# Resolve helper script path
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pdfHelper = Join-Path $ScriptDir 'pdf_to_audio.ps1'
if (-not (Test-Path $pdfHelper)) {
  Write-Error "Helper script not found: $pdfHelper"
  exit 1
}

# Always generate WAV first
$wavPath = [System.IO.Path]::ChangeExtension($pdfPath, 'wav')

Write-Host "Generating narration..." -ForegroundColor Cyan
& $pdfHelper -PdfPath $pdfPath -OutPath $wavPath -PickVoice:$PickVoice
if ($LASTEXITCODE -ne 0 -and -not (Test-Path $wavPath)) {
  Write-Error "Narration failed."
  exit 1
}

if ($targetExt -eq 'mp3') {
  $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
  if ($ffmpeg) {
    Write-Host "Converting WAV to MP3..." -ForegroundColor Cyan
    & ffmpeg -y -i "$wavPath" -codec:a libmp3lame -b:a 192k "$outPath"
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outPath)) {
      Write-Host "Done. Wrote: $outPath" -ForegroundColor Green
    } else {
      Write-Warning "MP3 conversion failed; WAV available at: $wavPath"
    }
  } else {
    Write-Warning "ffmpeg not found. Keeping WAV at: $wavPath"
  }
} else {
  Write-Host "Done. Wrote: $wavPath" -ForegroundColor Green
}
