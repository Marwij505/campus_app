# Pasang sekali untuk pengguna Windows ini, bukan pada SDK atau startup Windows.
# Setelah terminal baru dibuka, flutter run di campus_app menyiapkan Ollama dulu.
param([switch]$Uninstall)
$ErrorActionPreference = 'Stop'
$hook = Join-Path $PSScriptRoot 'flutter_hook.ps1'
if (!(Test-Path -LiteralPath $hook)) { throw 'File flutter_hook.ps1 tidak ditemukan.' }
$documents = [Environment]::GetFolderPath('MyDocuments')
if (!$documents) { throw 'Folder Documents pengguna tidak ditemukan.' }
$begin = '# BEGIN campus_app local AI'
$end = '# END campus_app local AI'
$pattern = '(?ms)^' + [regex]::Escape($begin) + '\r?\n.*?^' + [regex]::Escape($end) + '(?:\r?\n)?'
# Tanda petik dalam path di-escape sebagai literal PowerShell, bukan kode tambahan.
$quotedHook = $hook.Replace("'", "''")
$block = @"
$begin
# Muat pengait hanya jika checkout proyek ini masih tersedia.
if (Test-Path -LiteralPath '$quotedHook') { . '$quotedHook' }
$end
"@

foreach ($edition in @('WindowsPowerShell', 'PowerShell')) {
    # CurrentUserAllHosts dipakai terminal biasa dan terminal PowerShell VS Code.
    $profilePath = Join-Path (Join-Path $documents $edition) 'profile.ps1'
    $exists = Test-Path -LiteralPath $profilePath
    $content = if ($exists) { [IO.File]::ReadAllText($profilePath) } else { '' }
    # Jika penanda tidak lengkap, jangan menebak bagian profil yang boleh diganti.
    if (($content.Contains($begin) -or $content.Contains($end)) -and
        ![regex]::IsMatch($content, $pattern)) {
        throw ('Penanda pengait tidak lengkap dalam ' + $profilePath)
    }
    $clean = [regex]::Replace($content, $pattern, '')
    $updated = $clean
    if (!$Uninstall) {
        if ($updated.Length -gt 0 -and !$updated.EndsWith("`n")) { $updated += "`r`n" }
        $updated += $block + "`r`n"
    }
    if ($updated -eq $content) { continue }
    # Simpan salinan profil sebelum perubahan agar penyesuaian pribadi bisa dipulihkan.
    if ($exists) {
        $backup = $profilePath + '.campus-backup-' + [Guid]::NewGuid().ToString('N')
        Copy-Item -LiteralPath $profilePath -Destination $backup
        Write-Output ('Cadangan profil: ' + $backup)
    }
    $null = New-Item -ItemType Directory -Force -Path (Split-Path $profilePath)
    # UTF-8 dengan BOM kompatibel dengan Windows PowerShell 5.1 dan PowerShell 7.
    [IO.File]::WriteAllText($profilePath, $updated, (New-Object Text.UTF8Encoding($true)))
    Write-Output ('Profil diperbarui: ' + $profilePath)
}
if ($Uninstall) {
    Write-Output 'Pengait dihapus. Buka terminal baru; runtime/model AI tetap tersimpan.'
} else {
    Write-Output 'Pengait terpasang. Buka terminal PowerShell baru, lalu gunakan flutter run seperti biasa.'
    Write-Output 'Terminal -NoProfile, Command Prompt, dan tombol F5 IDE tidak memakai pengait ini.'
}
