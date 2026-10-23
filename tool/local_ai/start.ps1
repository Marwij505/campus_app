# Nyalakan Ollama khusus campus_app, lalu tunggu layanan benar-benar siap.
# RequireModel dipakai pengait flutter run; setup boleh mulai sebelum model diunduh.
param([switch]$LocalOnly, [switch]$RequireModel)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$aiRoot = Join-Path $projectRoot '.local-ai'
$exe = Join-Path $aiRoot 'runtime/ollama.exe'
$pidFile = Join-Path $aiRoot 'server.pid'
if (!(Test-Path -LiteralPath $exe)) { throw 'Jalankan tool/local_ai/setup.ps1 sekali untuk memasang runtime dan model.' }

# Dua terminal yang menjalankan Flutter bersamaan harus bergiliran menyiapkan server.
$hash = [Security.Cryptography.SHA256]::Create()
try {
    $key = [BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($projectRoot.ToLowerInvariant()))).Replace('-', '')
} finally { $hash.Dispose() }
$mutex = New-Object Threading.Mutex($false, ('Local\CampusAppAI-' + $key))
$locked = $false
try {
    try { $locked = $mutex.WaitOne(120000) }
    catch [Threading.AbandonedMutexException] { $locked = $true }
    if (!$locked) { throw 'Penyiapan AI oleh terminal lain belum selesai. Coba lagi sebentar.' }

    # Pilih satu jaringan fisik. Tanpa LAN, Chrome dan emulator memakai loopback.
    $lan = Get-NetIPConfiguration | Where-Object {
        $_.IPv4DefaultGateway -and $_.NetAdapter.HardwareInterface -and
        ($_.IPv4Address.IPAddress -match '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)')
    } | Select-Object -First 1
    $bindAddress = if (!$LocalOnly -and $lan) { [string]($lan.IPv4Address.IPAddress | Select-Object -First 1) } else { '127.0.0.1' }
    $endpoint = 'http://' + $bindAddress + ':11435'

    # Pertahankan pembatasan executable, IP, port, dan subnet proyek yang sudah ada.
    if ($bindAddress -ne '127.0.0.1') {
        try { & (Join-Path $PSScriptRoot 'firewall.ps1') -Address $bindAddress }
        catch {
            Write-Warning ('Izin LAN belum diperbarui. Jika emulator/HP tidak tersambung, jalankan tool/local_ai/firewall.ps1 -Address ' + $bindAddress + ' dari PowerShell Administrator.')
        }
    }

    # Port milik proses lain tidak boleh diambil alih; hanya server proyek sendiri dikenali.
    $reuse = $false
    $listener = Get-NetTCPConnection -LocalPort 11435 -State Listen -ErrorAction SilentlyContinue
    if ($listener) {
        $knownPid = if (Test-Path -LiteralPath $pidFile) { [int](Get-Content -LiteralPath $pidFile) } else { 0 }
        $existing = Get-Process -Id $knownPid -ErrorAction SilentlyContinue
        if (!$existing -or $existing.Path -ne $exe -or $listener.OwningProcess -notcontains $knownPid) {
            throw 'Port 11435 sedang digunakan proses lain; tidak dihentikan otomatis.'
        }
        if ($listener.LocalAddress -contains $bindAddress) { $reuse = $true }
        else {
            # Saat jaringan berubah, mulai ulang hanya server proyek agar alamatnya sesuai.
            Stop-Process -Id $knownPid
            $existing.WaitForExit(5000) | Out-Null
        }
    }
    if (!$reuse) {
        # Variabel hanya diwariskan ke server ini, lalu lingkungan terminal dipulihkan.
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
    }

    # Server yang sudah aktif tetap diperiksa, bukan dianggap siap hanya dari nomor PID.
    $ready = $false
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $null = Invoke-RestMethod ($endpoint + '/api/version') -TimeoutSec 2
            $ready = $true
            break
        } catch { Start-Sleep -Seconds 1 }
    }
    if (!$ready) { throw 'Ollama belum siap. Periksa .local-ai/server.err.log.' }
    if ($RequireModel) {
        $installed = Invoke-RestMethod ($endpoint + '/api/tags') -TimeoutSec 10
        if ($installed.models.name -notcontains 'qwen2.5:1.5b') {
            throw 'Model qwen2.5:1.5b belum ada. Jalankan tool/local_ai/setup.ps1 sekali sebelum flutter run.'
        }
    }

    # Perbarui alamat sebelum Flutter membundel aset; IP baru setelah cold boot ikut terbaca.
    $assetDir = Join-Path $projectRoot 'assets/local_ai'
    $null = New-Item -ItemType Directory -Force -Path $assetDir
    $config = @{ addresses = @($endpoint) } | ConvertTo-Json -Compress
    [IO.File]::WriteAllText((Join-Path $assetDir 'connection.json'), $config, (New-Object Text.UTF8Encoding($false)))
    Set-Content -LiteralPath (Join-Path $aiRoot 'endpoint.txt') -Value $endpoint
    Write-Output ('Ollama campus_app siap di ' + $endpoint + $(if ($reuse) { ' (memakai server yang sudah aktif).' } else { ' (server baru).' }))
} finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
