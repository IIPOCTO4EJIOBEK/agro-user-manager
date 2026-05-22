# Скрипт 1: Первичная настройка сервера и поднятие Active Directory
# Скопируйте и выполните этот код в PowerShell от имени Администратора после установки Windows Server 2022

Write-Host "Настройка сети..." -ForegroundColor Cyan
$NetAdapter = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
New-NetIPAddress -InterfaceAlias $NetAdapter.Name -IPAddress 10.0.1.250 -PrefixLength 24 -DefaultGateway 10.0.1.1 -ErrorAction SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias $NetAdapter.Name -ServerAddresses ("127.0.0.1", "8.8.8.8")

Write-Host "Переименование компьютера..." -ForegroundColor Cyan
Rename-Computer -NewName "B24-AD-SYNC" -Force -ErrorAction SilentlyContinue

Write-Host "Установка роли AD DS..." -ForegroundColor Cyan
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host "Повышение до контроллера домена (лес sync.rusagroeco.ru)..." -ForegroundColor Cyan
$password = ConvertTo-SecureString "Admin@2026Prostory!" -AsPlainText -Force
Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DomainMode "WinThreshold" `
    -DomainName "sync.rusagroeco.ru" `
    -DomainNetbiosName "SYNC" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $password `
    -Force

Write-Host "Сервер будет перезагружен. После перезагрузки зайдите под учетной записью SYNC\Administrator" -ForegroundColor Yellow
