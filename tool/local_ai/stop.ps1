# Hentikan hanya server milik proyek ini, tanpa menyentuh Ollama aplikasi lain.
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$aiRoot = Join-Path $projectRoot '.local-ai'
$pidFile = Join-Path $aiRoot 'server.pid'
if (!(Test-Path $pidFile)) { Write-Output 'Tidak ada server proyek yang tercatat.'; exit 0 }
$server = Get-Process -Id ([int](Get-Content $pidFile)) -ErrorAction SilentlyContinue
if ($server) {
    $exe = Join-Path (Join-Path $aiRoot 'runtime') 'ollama.exe'
    if ($server.Path -ne $exe) { throw 'PID sudah dipakai proses lain; tidak dihentikan.' }
    Stop-Process -Id $server.Id
}
Remove-Item -LiteralPath $pidFile
Write-Output 'Server Ollama campus_app dihentikan. Model tetap tersimpan.'
