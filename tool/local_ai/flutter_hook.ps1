# Dimuat oleh terminal proyek VS Code atau profil PowerShell yang sudah dipasang.
# VS Code memakai -File dan -NoExit: fungsi tetap ada saat pengguna mulai mengetik.
# File ini hanya memasang fungsi di terminal itu, belum mengunduh/menyalakan AI.
# Pengait berlaku untuk flutter run di proyek ini; perintah lain langsung ke SDK.
& {
    $campusProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    $existing = Get-Command flutter -ErrorAction SilentlyContinue
    # Jangan menimpa alias/fungsi pribadi yang tidak dibuat oleh pengait ini.
    if ($existing -and $existing.CommandType -in @('Function', 'Alias') -and
        $existing.Definition -notlike '*campus_app-local-ai-hook*') {
        Write-Warning 'Pengait AI tidak dimuat: sudah ada alias/fungsi flutter pribadi.'
        return
    }

    $wrapper = {
        # campus_app-local-ai-hook: penanda agar pemuatan ulang tidak bertumpuk.
        # Tidak memakai param() agar semua argumen Flutter diteruskan apa adanya.
        $flutterArguments = @($args)
        $sdk = Get-Command flutter.bat -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (!$sdk) {
            Write-Error 'Flutter SDK belum ditemukan di PATH.' -ErrorAction Continue
            $global:LASTEXITCODE = 1
            return
        }

        # Cari pubspec terdekat: subfolder proyek boleh, proyek lain tidak ikut.
        $project = $null
        if ($PWD.Provider.Name -eq 'FileSystem') {
            $directory = Get-Item -LiteralPath $PWD.Path
            while ($directory) {
                if (Test-Path -LiteralPath (Join-Path $directory.FullName 'pubspec.yaml')) {
                    $project = $directory.FullName
                    break
                }
                $directory = $directory.Parent
            }
        }
        $isRun = $flutterArguments.Count -gt 0 -and $flutterArguments[0] -eq 'run'
        $isHelp = $flutterArguments -contains '--help' -or $flutterArguments -contains '-h'
        if ($project -eq $campusProjectRoot -and $isRun -and !$isHelp) {
            Write-Host '[campus_app] Menyiapkan Ollama sebelum Flutter berjalan...'
            # Proses anak membuat exit pada start.ps1 tidak menutup terminal pengguna.
            $shell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
            & $shell -NoProfile -ExecutionPolicy Bypass -File (
                Join-Path $campusProjectRoot 'tool/local_ai/start.ps1'
            ) -RequireModel -Repair
            if ($LASTEXITCODE -ne 0) {
                Write-Error 'AI belum siap; Flutter belum dijalankan. Periksa pesan di atas lalu coba lagi.' -ErrorAction Continue
                $global:LASTEXITCODE = 1
                return
            }
        }
        # Pemanggilan native tetap interaktif: r/R/q dan pemilihan perangkat tetap bekerja.
        & $sdk.Source @flutterArguments
        $global:LASTEXITCODE = $LASTEXITCODE
    }.GetNewClosure()
    Set-Item -Path Function:\global:flutter -Value $wrapper
}
