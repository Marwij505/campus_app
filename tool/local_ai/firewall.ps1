# Izin masuk dibatasi ke AI proyek ini dan perangkat di subnet lokal yang sama.
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)')]
    [string]$Address
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$exe = Join-Path $projectRoot '.local-ai/runtime/ollama.exe'
if (!(Test-Path -LiteralPath $exe)) { throw 'Runtime AI proyek belum tersedia.' }
$ruleName = 'CampusApp-LocalAI-11435'
$rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($rule) {
    $addressFilter = $rule | Get-NetFirewallAddressFilter
    $applicationFilter = $rule | Get-NetFirewallApplicationFilter
    $portFilter = $rule | Get-NetFirewallPortFilter
    if ($rule.Enabled -eq 'True' -and $rule.Direction -eq 'Inbound' -and $rule.Action -eq 'Allow' -and
        $addressFilter.LocalAddress -eq $Address -and $addressFilter.RemoteAddress -eq 'LocalSubnet' -and
        $applicationFilter.Program -eq $exe -and $portFilter.LocalPort -eq '11435' -and $portFilter.Protocol -eq 'TCP') {
        Write-Output 'Izin firewall subnet lokal sudah sesuai.'
        return
    }
    $null = $rule | Set-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Any -Program $exe -Protocol TCP -LocalPort 11435 -LocalAddress $Address -RemoteAddress LocalSubnet
} else {
    $null = New-NetFirewallRule -Name $ruleName -DisplayName 'Campus App AI - subnet lokal' -Direction Inbound -Action Allow -Profile Any -Program $exe -Protocol TCP -LocalPort 11435 -LocalAddress $Address -RemoteAddress LocalSubnet
}
Write-Output 'Izin firewall subnet lokal berhasil disiapkan.'
