# Fungsi pemulihan runtime portable. Hanya dipanggil saat instalasi lokal tidak lengkap.
# Versi dan checksum dikunci agar berkas unduhan tidak langsung dipercaya/dijalankan.
function Test-CampusRuntime([string]$Root) {
    $runtime = Join-Path $Root 'runtime'
    return (Test-Path -LiteralPath (Join-Path $runtime 'ollama.exe')) -and
        (Test-Path -LiteralPath (Join-Path $runtime '.campus-runtime-complete'))
}

# Model diperiksa melalui server proyek, supaya model Ollama global tidak ikut dipakai.
function Confirm-CampusModel([string]$Executable, [string]$Endpoint, [switch]$Repair) {
    $installed = Invoke-RestMethod ($Endpoint + '/api/tags') -TimeoutSec 10
    if ($installed.models.name -contains 'qwen2.5:1.5b') { return }
    if (!$Repair) { throw 'Model qwen2.5:1.5b belum ada. Jalankan setup.ps1 untuk memulihkannya.' }
    # CLI menampilkan progres dan melanjutkan bagian model yang sudah diunduh.
    Write-Output '[campus_app] Model belum tersedia. Memulihkan qwen2.5:1.5b (~1 GB); perlu internet.'
    $oldHost = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Process')
    try {
        $env:OLLAMA_HOST = $Endpoint
        & $Executable pull 'qwen2.5:1.5b'
        if ($LASTEXITCODE -ne 0) { throw 'Pemulihan model belum selesai. Jalankan flutter run lagi saat jaringan tersedia.' }
    } finally { [Environment]::SetEnvironmentVariable('OLLAMA_HOST', $oldHost, 'Process') }
    # Jangan melanjutkan Flutter jika CLI selesai tetapi model belum terdaftar.
    $installed = Invoke-RestMethod ($Endpoint + '/api/tags') -TimeoutSec 10
    if ($installed.models.name -notcontains 'qwen2.5:1.5b') { throw 'Model belum terdaftar sesudah pemulihan.' }
}

function Restore-CampusRuntime([string]$Root) {
    if (Test-CampusRuntime $Root) { return }
    $null = New-Item -ItemType Directory -Force -Path $Root
    $runtime = Join-Path $Root 'runtime'
    $archive = Join-Path $Root 'ollama-windows-amd64.zip'
    $expected = '5134ce7e3bc8e94d0494721c799ec293b429450d0c52461b0ee3647dd3bb4bb7'
    $url = 'https://github.com/ollama/ollama/releases/download/v0.40.5/ollama-windows-amd64.zip'
    $verified = $false
    # ZIP valid yang masih tersimpan bisa dipakai tanpa mengunduh ulang.
    if (Test-Path -LiteralPath $archive) {
        $verified = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expected
    }
    for ($attempt = 0; !$verified -and $attempt -lt 2; $attempt++) {
        Write-Output '[campus_app] Runtime belum lengkap. Mengunduh/melanjutkan Ollama portable (~1,5 GB); perlu internet.'
        & curl.exe --fail --location --retry 3 --connect-timeout 30 --speed-limit 1024 --speed-time 120 --continue-at - --output $archive $url
        if ($LASTEXITCODE -ne 0) {
            # 416 dapat terjadi jika ZIP lengkap/rusak tidak bisa dilanjutkan; cek hash dahulu.
            if ($LASTEXITCODE -ne 22 -and $LASTEXITCODE -ne 33) {
                throw 'Unduhan runtime terputus. File parsial disimpan; jalankan flutter run lagi saat internet tersedia.'
            }
        }
        $verified = (Test-Path -LiteralPath $archive) -and
            (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $expected
        if (!$verified -and (Test-Path -LiteralPath $archive)) {
            # Karantina hanya ZIP proyek ini; jangan mengekstrak arsip dengan hash berbeda.
            Move-Item -LiteralPath $archive -Destination ($archive + '.invalid-' + [Guid]::NewGuid().ToString('N'))
        }
    }
    if (!$verified) { throw 'Checksum runtime tidak cocok. Unduhan tidak dijalankan; periksa jaringan lalu coba kembali.' }

    # Ekstraksi yang terputus tidak diberi penanda selesai, sehingga dipulihkan lagi.
    Write-Output '[campus_app] Memeriksa dan mengekstrak runtime Ollama...'
    Expand-Archive -LiteralPath $archive -DestinationPath $runtime -Force
    if (!(Test-Path -LiteralPath (Join-Path $runtime 'ollama.exe'))) {
        throw 'Ekstraksi selesai tanpa ollama.exe. Runtime belum dapat digunakan.'
    }
    Set-Content -LiteralPath (Join-Path $runtime '.campus-runtime-complete') -Value $expected
}
