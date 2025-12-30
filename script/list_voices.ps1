Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voices = $synth.GetInstalledVoices() | ForEach-Object { $_.VoiceInfo }

if (-not $voices -or $voices.Count -eq 0) {
  Write-Warning "No installed voices found. Install Windows speech voices and retry."
  exit 1
}

Write-Host "Installed voices:" -ForegroundColor Cyan
for ($i = 0; $i -lt $voices.Count; $i++) {
  $v = $voices[$i]
  Write-Host ("[{0}] {1} | Culture: {2} | Gender: {3}" -f $i, $v.Name, $v.Culture, $v.Gender)
}

Write-Host "\nTo use a specific voice, run pdf_to_audio.ps1 with -Voice '<Name>' or -PickVoice to choose interactively."