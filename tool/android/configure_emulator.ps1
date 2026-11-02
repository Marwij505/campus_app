# Menghindari pemulihan snapshot emulator yang dapat membuat layar tetap hitam.
# Jalankan sekali dengan emulator tertutup. Data aplikasi dan snapshot tidak dihapus.
[CmdletBinding()]
param(
    # Gunakan nama AVD dari Android Studio Device Manager, bukan ID emulator-5554.
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z0-9_.-]+$')]
    [string]$AvdName
)

$ErrorActionPreference = 'Stop'

# Emulator dapat menulis ulang config.ini ketika ditutup; ubah hanya saat berhenti.
if (Get-Process -Name 'emulator', 'qemu-system-x86_64', 'qemu-system-aarch64' -ErrorAction SilentlyContinue) {
    throw 'Tutup semua Android Emulator dahulu, lalu jalankan perintah ini kembali.'
}

# Hormati lokasi AVD khusus jika pengguna mengaturnya di lingkungan Android SDK.
$avdRoot = if ($env:ANDROID_AVD_HOME) {
    $env:ANDROID_AVD_HOME
} elseif ($env:ANDROID_USER_HOME) {
    Join-Path $env:ANDROID_USER_HOME 'avd'
} else {
    Join-Path $env:USERPROFILE '.android/avd'
}
$avdIndex = Join-Path $avdRoot "$AvdName.ini"
if (!(Test-Path -LiteralPath $avdIndex -PathType Leaf)) {
    throw "AVD '$AvdName' tidak ditemukan di $avdRoot. Periksa nama di Device Manager."
}

# File indeks menunjuk folder data AVD; folder tersebut bisa berada di drive lain.
$pathLine = Get-Content -LiteralPath $avdIndex | Where-Object { $_ -match '^path=' } | Select-Object -First 1
if (!$pathLine) { throw "Lokasi data AVD tidak tercantum pada $avdIndex." }
$configPath = Join-Path $pathLine.Substring(5).Trim() 'config.ini'
$original = [IO.File]::ReadAllText($configPath)
$updated = $original

# Cold boot memulai Android dari awal setiap kali emulator dibuka.
# Pengaturan GPU, RAM, akun, aplikasi terpasang, dan berkas pengguna tetap sama.
$settings = [ordered]@{
    'fastboot.forceChosenSnapshotBoot' = 'no'
    'fastboot.forceColdBoot' = 'yes'
    'fastboot.forceFastBoot' = 'no'
}
foreach ($name in $settings.Keys) {
    $pattern = '(?m)^' + [regex]::Escape($name) + '=[^\r\n]*'
    $line = "$name=$($settings[$name])"
    if ([regex]::IsMatch($updated, $pattern)) {
        $updated = [regex]::Replace($updated, $pattern, $line)
    } else {
        $updated = $updated.TrimEnd() + "`r`n$line`r`n"
    }
}

# Pemanggilan ulang tidak membuat cadangan baru jika konfigurasi sudah benar.
if ($updated -eq $original) {
    Write-Host "AVD '$AvdName' sudah memakai cold boot."
    return
}

# Simpan salinan asli agar pengaturan sebelumnya dapat dikembalikan secara manual.
$backup = "$configPath.campus-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
Copy-Item -LiteralPath $configPath -Destination $backup -ErrorAction Stop
[IO.File]::WriteAllText($configPath, $updated, [Text.UTF8Encoding]::new($false))
Write-Host "Cold boot aktif untuk '$AvdName'. Buka emulator, lalu jalankan flutter run."
Write-Host "Cadangan konfigurasi: $backup"
