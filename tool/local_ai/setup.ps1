# Pasang/pulihkan AI memakai alur yang sama dengan flutter run agar tidak berbeda perilaku.
$ErrorActionPreference = 'Stop'
# Gunakan shell saat ini, tanpa bergantung pada perintah pwsh di PATH komputer.
$shellName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
$shellExe = Join-Path $PSHOME $shellName
& $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'start.ps1') -RequireModel -Repair
if ($LASTEXITCODE -ne 0) { throw 'Penyiapan AI belum selesai; jalankan setup.ps1 lagi untuk melanjutkan.' }
# Profil hanya memasang pengait perintah Flutter; AI tidak dimulai saat Windows login.
& $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'install_autostart.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Pemasangan pengait Flutter gagal.' }
Write-Output 'Ollama siap. Buka terminal PowerShell baru, lalu gunakan flutter run seperti biasa.'
