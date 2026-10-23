# Uji pengait dengan server/SDK tiruan; tidak mengunduh model atau membuka browser.
# Jalankan memakai powershell.exe -NoProfile -File tool/local_ai/test_autostart.ps1.
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$fixture = Join-Path $projectRoot ('build/autostart-test-' + [Guid]::NewGuid().ToString('N'))
$scripts = Join-Path $fixture 'tool/local_ai'
$null = New-Item -ItemType Directory -Force -Path $scripts
$null = New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'lib')
Set-Content -LiteralPath (Join-Path $fixture 'pubspec.yaml') -Value 'name: campus_app'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'flutter_hook.ps1') -Destination $scripts

# Server palsu mencatat bahwa penyiapan terjadi sebelum panggilan SDK.
@'
param([switch]$RequireModel)
if (!$RequireModel) { throw 'Model harus diperiksa sebelum Flutter.' }
Add-Content -LiteralPath $env:CAMPUS_TEST_EVENTS -Value 'ai'
if ($env:CAMPUS_TEST_FAIL -eq '1') { exit 1 }
exit 0
'@ | Set-Content -LiteralPath (Join-Path $scripts 'start.ps1')
@'
Add-Content -LiteralPath $env:CAMPUS_TEST_EVENTS -Value 'flutter'
ConvertTo-Json -InputObject @($args) -Compress | Set-Content -LiteralPath $env:CAMPUS_TEST_ARGUMENTS
$global:LASTEXITCODE = 7
'@ | Set-Content -LiteralPath (Join-Path $fixture 'sdk.ps1')
$env:CAMPUS_TEST_EVENTS = Join-Path $fixture 'events.txt'
$env:CAMPUS_TEST_ARGUMENTS = Join-Path $fixture 'arguments.json'
$global:campusTestSdk = Join-Path $fixture 'sdk.ps1'

# Resolusi SDK saja yang diganti. Implementasi pengait tetap file asli yang disalin.
function global:Get-Command {
    param($Name, $CommandType, $ErrorAction)
    if ($Name -eq 'flutter.bat') { return [pscustomobject]@{ Source = $global:campusTestSdk } }
    Microsoft.PowerShell.Core\Get-Command $Name -ErrorAction SilentlyContinue
}
function Assert-True($Condition, [string]$Message) {
    if (!$Condition) { throw ('GAGAL: ' + $Message) }
}
function Reset-Calls {
    Set-Content -LiteralPath $env:CAMPUS_TEST_EVENTS -Value '' -NoNewline
    Set-Content -LiteralPath $env:CAMPUS_TEST_ARGUMENTS -Value '[]'
}
function Assert-Calls([string]$Expected) {
    $actual = (Get-Content -LiteralPath $env:CAMPUS_TEST_EVENTS) -join ','
    Assert-True ($actual -eq $Expected) ('urutan panggilan: ' + $actual)
}

Push-Location $fixture
try {
    . (Join-Path $scripts 'flutter_hook.ps1')
    foreach ($device in @('chrome', 'emulator-5554')) {
        Reset-Calls
        flutter run -d $device '--dart-define=LABEL=dua kata'
        Assert-True ($LASTEXITCODE -eq 7) 'exit code SDK diteruskan'
        Assert-Calls 'ai,flutter'
        $forwarded = Get-Content -LiteralPath $env:CAMPUS_TEST_ARGUMENTS -Raw | ConvertFrom-Json
        Assert-True ($forwarded.Count -eq 4 -and $forwarded[2] -eq $device -and $forwarded[3] -eq '--dart-define=LABEL=dua kata') 'argumen perangkat/spasi utuh'
    }
    Reset-Calls
    flutter run
    Assert-Calls 'ai,flutter'
    # Memuat profil dua kali tidak boleh membuat pemanggilan bertumpuk/rekursif.
    . (Join-Path $scripts 'flutter_hook.ps1')
    Reset-Calls
    flutter test
    Assert-Calls 'flutter'
    Reset-Calls
    flutter run --help
    Assert-Calls 'flutter'
    Push-Location (Join-Path $fixture 'lib')
    try { Reset-Calls; flutter run; Assert-Calls 'ai,flutter' }
    finally { Pop-Location }
    Push-Location $projectRoot
    try { Reset-Calls; flutter run -d chrome; Assert-Calls 'flutter' }
    finally { Pop-Location }
    # Gagal menyiapkan AI menghentikan alur, tanpa berpura-pura menjalankan Flutter.
    Reset-Calls
    $env:CAMPUS_TEST_FAIL = '1'
    flutter run -d chrome 2>$null
    Assert-True ($LASTEXITCODE -eq 1) 'exit code gagal penyiapan'
    Assert-Calls 'ai'
    Write-Output 'LULUS: Chrome, emulator, pilihan perangkat, subfolder, proyek lain, help/test, muat ulang, kegagalan, argumen, dan exit code.'
} finally {
    Pop-Location
    Remove-Item Env:CAMPUS_TEST_FAIL -ErrorAction SilentlyContinue
    Remove-Item Env:CAMPUS_TEST_EVENTS, Env:CAMPUS_TEST_ARGUMENTS
    Remove-Item Function:\global:Get-Command, Function:\global:flutter
    Remove-Variable campusTestSdk -Scope Global
}
