# Unduh versi portable resmi dan model ringan ke folder proyek, tanpa installer global.
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$aiRoot = Join-Path $projectRoot '.local-ai'
$runtime = Join-Path $aiRoot 'runtime'
$null = New-Item -ItemType Directory -Force -Path $runtime
$archive = Join-Path $aiRoot 'ollama-windows-amd64.zip'
$expected = '5134ce7e3bc8e94d0494721c799ec293b429450d0c52461b0ee3647dd3bb4bb7'
if (!(Test-Path (Join-Path $runtime 'ollama.exe'))) {
    Write-Output 'Mengunduh Ollama v0.40.5 portable (sekitar 1,5 GB)...'
    & curl.exe --fail --location --retry 3 --continue-at - --output $archive 'https://github.com/ollama/ollama/releases/download/v0.40.5/ollama-windows-amd64.zip'
    if ($LASTEXITCODE -ne 0) { throw 'Unduhan runtime gagal; jalankan ulang untuk melanjutkan.' }
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expected) { throw 'Checksum runtime tidak cocok; arsip tidak dijalankan.' }
    Expand-Archive -LiteralPath $archive -DestinationPath $runtime -Force
}
# Pakai shell yang sedang menjalankan setup, tanpa bergantung pada PATH.
# Windows PowerShell 5.1 memakai powershell.exe; PowerShell 7 memakai pwsh.exe.
# Bypass hanya berlaku pada proses anak ini, tidak mengubah kebijakan Windows.
$shellName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
$shellExe = Join-Path $PSHOME $shellName
& $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'start.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Server lokal gagal dimulai.' }
# Pemasangan ulang tidak perlu mengunduh model yang sudah tersedia.
$endpoint = (Get-Content -LiteralPath (Join-Path $aiRoot 'endpoint.txt') -Raw).Trim()
$installed = Invoke-RestMethod ($endpoint + '/api/tags') -TimeoutSec 10
if ($installed.models.name -contains 'qwen2.5:1.5b') {
    # Daftarkan pengait sekali agar terminal baru dapat memakai flutter run langsung.
    & $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'install_autostart.ps1')
    if ($LASTEXITCODE -ne 0) { throw 'Pemasangan pengait Flutter gagal.' }
    Write-Output 'Ollama dan model campus_app sudah terpasang. Smart Chatbot menyambung otomatis saat dibuka.'
    exit 0
}
Write-Output 'Mengunduh model qwen2.5:1.5b ke penyimpanan campus_app...'
$result = Invoke-RestMethod ($endpoint + '/api/pull') -Method Post -ContentType 'application/json' -Body '{"model":"qwen2.5:1.5b","stream":false}' -TimeoutSec 3600
if ($result.status -ne 'success') { throw 'Unduhan model belum berhasil.' }
# Profil hanya memuat pengait; AI tidak menyala saat Windows login atau terminal dibuka.
& $shellExe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'install_autostart.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Pemasangan pengait Flutter gagal.' }
Write-Output 'Selesai. Smart Chatbot menyambung otomatis saat dibuka.'
