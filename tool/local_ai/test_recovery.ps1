# Uji pemulihan tanpa internet. Unduhan, checksum, dan ekstraksi diganti tiruan.
# Semua berkas uji berada di build; instalasi AI pengguna tidak disentuh.
$ErrorActionPreference = 'Stop'
# Muat modul sebelum membuat tiruan, supaya autoload tidak menimpa fungsi uji.
Import-Module Microsoft.PowerShell.Utility, Microsoft.PowerShell.Archive
. (Join-Path $PSScriptRoot 'runtime.ps1')
$root = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path ('build/recovery-test-' + [Guid]::NewGuid().ToString('N'))
$script:downloads = 0
$script:extracts = 0
$script:badHash = $false
$script:failDownload = $false
$script:failExtract = $false
function Assert-True($Condition, [string]$Message) {
    if (!$Condition) { throw ('GAGAL: ' + $Message) }
}
# Tiruan tetap menulis ZIP agar pemeriksaan keberadaan berkas memakai filesystem nyata.
function curl.exe {
    $script:downloads++
    $output = $args[[Array]::IndexOf($args, '--output') + 1]
    Set-Content -LiteralPath $output -Value 'arsip uji'
    $global:LASTEXITCODE = if ($script:failDownload) { 28 } else { 0 }
}
function Get-FileHash {
    param($LiteralPath, $Algorithm)
    $value = if ($script:badHash) { 'invalid' } else { '5134ce7e3bc8e94d0494721c799ec293b429450d0c52461b0ee3647dd3bb4bb7' }
    return [pscustomobject]@{ Hash = $value }
}
function Expand-Archive {
    param($LiteralPath, $DestinationPath, [switch]$Force)
    $script:extracts++
    $null = New-Item -ItemType Directory -Force -Path $DestinationPath
    Set-Content -LiteralPath (Join-Path $DestinationPath 'ollama.exe') -Value 'runtime uji, bukan executable'
    if ($script:failExtract) { throw 'Ekstraksi uji terputus' }
}
# Server tiruan mencatat model yang tersedia; CLI tiruan hanya menerima model proyek.
$script:modelPresent = $false
$script:modelFailure = $false
$script:modelPulls = 0
function Invoke-RestMethod {
    param($Uri, $TimeoutSec)
    Assert-True ($Uri -eq 'http://127.0.0.1:11435/api/tags') 'alamat server proyek digunakan'
    $models = if ($script:modelPresent) { @([pscustomobject]@{ name = 'qwen2.5:1.5b' }) } else { @() }
    return [pscustomobject]@{ models = $models }
}
function Invoke-TestModel {
    Assert-True ($args[0] -eq 'pull' -and $args[1] -eq 'qwen2.5:1.5b') 'perintah model sesuai'
    Assert-True ($env:OLLAMA_HOST -eq 'http://127.0.0.1:11435') 'CLI hanya menghubungi server proyek'
    $script:modelPulls++
    $script:modelPresent = !$script:modelFailure
    $global:LASTEXITCODE = if ($script:modelFailure) { 1 } else { 0 }
}
$savedHost = [Environment]::GetEnvironmentVariable('OLLAMA_HOST', 'Process')
try {
    $missing = Join-Path $root 'missing'
    Restore-CampusRuntime $missing
    Assert-True ((Test-CampusRuntime $missing) -and $script:downloads -eq 1 -and $script:extracts -eq 1) 'instalasi hilang dipulihkan'
    Restore-CampusRuntime $missing
    Assert-True ($script:downloads -eq 1 -and $script:extracts -eq 1) 'instalasi lengkap tidak diunduh/diekstrak ulang'

    # Runtime hilang tetapi ZIP masih ada: gunakan cache yang lolos checksum.
    $cached = Join-Path $root 'cached'
    $null = New-Item -ItemType Directory -Force -Path $cached
    Set-Content -LiteralPath (Join-Path $cached 'ollama-windows-amd64.zip') -Value 'cache uji'
    Restore-CampusRuntime $cached
    Assert-True ((Test-CampusRuntime $cached) -and $script:downloads -eq 1) 'cache valid dapat memulihkan tanpa internet'

    $broken = Join-Path $root 'broken'
    $script:badHash = $true
    $before = $script:extracts
    $rejected = $false
    try { Restore-CampusRuntime $broken } catch { $rejected = $true }
    Assert-True ($rejected -and $script:extracts -eq $before -and !(Test-CampusRuntime $broken)) 'checksum salah tidak diekstrak atau ditandai siap'
    $script:badHash = $false

    $partial = Join-Path $root 'partial'
    $script:failDownload = $true
    $rejected = $false
    try { Restore-CampusRuntime $partial } catch { $rejected = $true }
    Assert-True ($rejected -and (Test-Path (Join-Path $partial 'ollama-windows-amd64.zip')) -and !(Test-CampusRuntime $partial)) 'unduhan terputus disimpan, tetapi tidak dianggap siap'
    $script:failDownload = $false

    $interrupted = Join-Path $root 'interrupted'
    $script:failExtract = $true
    $rejected = $false
    try { Restore-CampusRuntime $interrupted } catch { $rejected = $true }
    Assert-True ($rejected -and !(Test-CampusRuntime $interrupted)) 'ekstraksi parsial belum dianggap lengkap meskipun exe sudah ada'
    $script:failExtract = $false
    $before = $script:downloads
    Restore-CampusRuntime $interrupted
    Assert-True ((Test-CampusRuntime $interrupted) -and $script:downloads -eq $before) 'ekstraksi terputus dapat diulang dari cache'
    $env:OLLAMA_HOST = 'alamat-asli-uji'
    Confirm-CampusModel -Executable Invoke-TestModel -Endpoint 'http://127.0.0.1:11435' -Repair
    Assert-True ($script:modelPresent -and $script:modelPulls -eq 1 -and $env:OLLAMA_HOST -eq 'alamat-asli-uji') 'model hilang dipulihkan dan lingkungan dikembalikan'
    Confirm-CampusModel -Executable Invoke-TestModel -Endpoint 'http://127.0.0.1:11435' -Repair
    Assert-True ($script:modelPulls -eq 1) 'model tersedia tidak diunduh ulang'
    $script:modelPresent = $false
    $script:modelFailure = $true
    $rejected = $false
    try { Confirm-CampusModel -Executable Invoke-TestModel -Endpoint 'http://127.0.0.1:11435' -Repair } catch { $rejected = $true }
    Assert-True ($rejected -and $env:OLLAMA_HOST -eq 'alamat-asli-uji') 'kegagalan model dilaporkan dan lingkungan tetap dikembalikan'
    Write-Output 'LULUS: runtime/model hilang, penggunaan ulang, cache, checksum, unduhan/ekstraksi terputus, dan lingkungan CLI.'
} finally {
    # Hanya hapus fungsi tiruan dari proses pengujian, bukan berkas instalasi.
    Remove-Item Function:\curl.exe, Function:\Get-FileHash, Function:\Expand-Archive
    Remove-Item Function:\Invoke-RestMethod, Function:\Invoke-TestModel
    [Environment]::SetEnvironmentVariable('OLLAMA_HOST', $savedHost, 'Process')
}
