
# cleanup_ad_250.ps1
Import-Module ActiveDirectory

$ExcludeCompanies = @('Агроконсалтинг', 'АКФ ПромСтройФинанс', 'Конто-М', 'ПК НКС', 'ТД "НКС"', 'Тестовая')
$ExcludeDepts = @('Аппарат президента', 'Президентство', 'Техническая запись', 'Техническая учетная запись', 'Тестировщиков', 'Внешние сотрудники')
$ExcludeLogins = @('krbtgt', 'Guest', 'Administrator', 'Администратор', 'Гость')
$ExcludeRegex = "^(svc_|admin_|test_|tmp_|demo_|mailbox_)"

$Users = Get-ADUser -Filter * -Properties Company, Department, DisplayName, Enabled

$ToDelete = @()

foreach ($u in $Users) {
    $shouldDelete = $false
    $login = $u.sAMAccountName.ToLower()
    $disp = if ($u.DisplayName) { $u.DisplayName } else { "" }
    $comp = if ($u.Company) { $u.Company } else { "" }
    $dept = if ($u.Department) { $u.Department } else { "" }

    # 1. Отключенные
    if ($u.Enabled -eq $false) { $shouldDelete = $true }

    # 2. Логины
    if ($login -match $ExcludeRegex) { $shouldDelete = $true }
    if ($ExcludeLogins -contains $login) { $shouldDelete = $true }
    if ($login -like "$*") { $shouldDelete = $true }

    # 3. Компании
    foreach ($ex in $ExcludeCompanies) {
        if ($comp -like "*$ex*") { $shouldDelete = $true }
    }

    # 4. Департаменты
    foreach ($ex in $ExcludeDepts) {
        if ($dept -like "*$ex*") { $shouldDelete = $true }
    }

    # 5. Системные по DisplayName
    if ($disp -like "*Microsoft Exchange*") { $shouldDelete = $true }
    if ($disp -like "*SystemMailbox*") { $shouldDelete = $true }

    if ($shouldDelete) {
        $ToDelete += $u
    }
}

Write-Host "Found $($ToDelete.Count) users to remove from AD 250." -ForegroundColor Yellow

foreach ($u in $ToDelete) {
    Write-Host "Removing: $($u.sAMAccountName) ($($u.DisplayName))"
    Remove-ADUser -Identity $u.sAMAccountName -Confirm:$false
}

Write-Host "Cleanup Complete." -ForegroundColor Green
