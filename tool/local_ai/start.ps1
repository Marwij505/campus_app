# Jalankan Ollama hanya untuk campus_app; tidak mengubah PATH atau pengaturan Windows.
param([switch]$LocalOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$aiRoot = Join-Path $projectRoot '.local-ai'
$exe = Join-Path (Join-Path $aiRoot 'runtime') 'ollama.exe'
$pidFile = Join-Path $aiRoot 'server.pid'
if (!(Test-Path -LiteralPath $exe)) { throw 'Jalankan tool/local_ai/setup.ps1 terlebih dahulu.' }
# Pilih satu antarmuka LAN fisik. Jangan membuka AI pada semua antarmuka/VPN.
$lan = Get-NetIPConfiguration | Where-Object {
    $_.IPv4DefaultGateway -and $_.NetAdapter.HardwareInterface -and
    ($_.IPv4Address.IPAddress -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)')
} | Select-Object -First 1
$bindAddress = if (!$LocalOnly -and $lan) { [string]($lan.IPv4Address.IPAddress | Select-Object -First 1) } else { '127.0.0.1' }
$endpoint = 'http://' + $bindAddress + ':11435'
$assetDir = Join-Path $projectRoot 'assets/local_ai'
$null = New-Item -ItemType Directory -Force -Path $assetDir
# JSON tanpa BOM dapat dibaca Flutter; alamat dibuat sebelum flutter run/build.
$config = @{ addresses = @($endpoint) } | ConvertTo-Json -Compress
[IO.File]::WriteAllText((Join-Path $assetDir 'connection.json'), $config, (New-Object Text.UTF8Encoding($false)))
Set-Content -LiteralPath (Join-Path $aiRoot 'endpoint.txt') -Value $endpoint

# Aturan hanya untuk executable, IP, port, dan subnet lokal proyek ini.
# Gagal mendapat hak Administrator tidak mematikan firewall atau mengganti profil jaringan.
if ($bindAddress -ne '127.0.0.1') {
    try {
        & (Join-Path $PSScriptRoot 'firewall.ps1') -Address $bindAddress
    } catch {
        Write-Warning ('Aturan firewall belum diperbarui. Jalankan tool/local_ai/firewall.ps1 -Address ' + $bindAddress + ' sekali dari PowerShell Administrator bila HP belum tersambung.')
    }
}
Write-Output ('Alamat AI perangkat: ' + $endpoint + '. Jalankan flutter run setelah script ini selesai.')
# Jangan mengambil alih port aplikasi lain yang kebetulan sudah digunakan.
$listener = Get-NetTCPConnection -LocalPort 11435 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $knownPid = if (Test-Path $pidFile) { [int](Get-Content $pidFile) } else { 0 }
    $existing = Get-Process -Id $knownPid -ErrorAction SilentlyContinue
    if ($existing -and $existing.Path -eq $exe -and $listener.OwningProcess -contains $knownPid) {
        if ($listener.LocalAddress -contains $bindAddress) {
            Write-Output ('Ollama campus_app sudah aktif di ' + $endpoint)
            exit 0
        }
        # Hanya server proyek sendiri yang dimulai ulang saat IP/mode jaringan berubah.
        Stop-Process -Id $knownPid
        $existing.WaitForExit(5000) | Out-Null
    } else {
        throw 'Port 11435 sedang digunakan proses lain; tidak dihentikan otomatis.'
    }
}
# Variabel ini hanya diwariskan ke proses anak; setelah itu dipulihkan.
$settings = @{
    OLLAMA_HOST = ($bindAddress + ':11435')
    OLLAMA_MODELS = (Join-Path $aiRoot 'models')
    OLLAMA_NO_CLOUD = '1'
    OLLAMA_ORIGINS = ('http://localhost:*,http://127.0.0.1:*,http://' + $bindAddress + ':*,http://10.0.2.2:*')
    OLLAMA_MAX_LOADED_MODELS = '1'
    OLLAMA_NUM_PARALLEL = '1'
}
$previous = @{}
try {
    foreach ($name in $settings.Keys) {
        $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
        [Environment]::SetEnvironmentVariable($name, $settings[$name], 'Process')
    }
    $server = Start-Process -FilePath $exe -ArgumentList 'serve' -WorkingDirectory $aiRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $aiRoot 'server.out.log') -RedirectStandardError (Join-Path $aiRoot 'server.err.log')
    Set-Content -LiteralPath $pidFile -Value $server.Id
} finally {
    foreach ($name in $previous.Keys) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        $null = Invoke-RestMethod ($endpoint + '/api/version') -TimeoutSec 2
        Write-Output ('Ollama campus_app aktif di ' + $endpoint + '. HP harus berada pada Wi-Fi yang sama; izinkan akses jaringan lokal bila diminta.')
        exit 0
    } catch { Start-Sleep -Seconds 1 }
}
throw 'Ollama belum siap. Periksa .local-ai/server.err.log.'
