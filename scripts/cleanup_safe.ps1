
# cleanup_safe.ps1
Import-Module ActiveDirectory

# Base64 списков для надежности кодировки (UTF-16LE)
# Компании: Агроконсалтинг, АКФ ПромСтройФинанс, Конто-М, ПК НКС, ТД "НКС", Тестовая
$B64_Comp = "QQBnAHIAbwBrAG8AbgBzAGEAbAB0AGkAbgBnACwAQQBLAEYAIABQAHIAbwBtAFMAdAByAG8AecBGAGkAbgBhAG4AcwAsAEsAbwBuAHQAbwAtAE0ALABQAEsAIABOAEsAUwAsAFQARAAnACIATgBLAFMAIgAsAFQAZQBzAHQAbwB2AGEAeQBhAA=="
$ExcludeCompanies = ([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($B64_Comp))).Split(',')

# Департаменты: Аппарат президента, Президентство, Техническая запись, Техническая учетная запись, Тестировщиков, Внешние сотрудники
$B64_Dept = "QQBwAHAAYQByAGEAdAAgAHAAcgBlAHoAaQBkAGUAbgB0AGEALABQAHIAZQB6AGkAZABlAG4AdABzAHQAdgBvACwAVABlAGsAaABuAGkAYwBoAGUAcwBrAGEAeQBhACAAegBhAHAAaQBzACwAVABlAGsAaABuAGkAYwBoAGUAcwBrAGEAeQBhACAAdQBjAGgAZQB0AG4AYQB5AGEAIAB6AGEAcABpAHMALABUAGUAcwB0AGkAcgBvAHYAcwBoAGMAaABpAGsAbwB2ACwAVgBuAGUAcwBoAG4AaQBlACAAcwBvAHQAcgB1AGQAbgBpAGsAaQA="
$ExcludeDepts = ([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($B64_Dept))).Split(',')

$ExcludeLogins = @('krbtgt', 'Guest', 'Administrator', 'administrator', 'guest')
$ExcludeRegex = "^(svc_|admin_|test_|tmp_|demo_|mailbox_)"

$Users = Get-ADUser -Filter * -Properties Company, Department, DisplayName, Enabled

$ToDelete = @()

foreach ($u in $Users) {
    $shouldDelete = $false
    $login = $u.sAMAccountName.ToLower()
    $disp = if ($u.DisplayName) { $u.DisplayName } else { "" }
    $comp = if ($u.Company) { $u.Company } else { "" }
    $dept = if ($u.Department) { $u.Department } else { "" }

    if ($u.Enabled -eq $false) { $shouldDelete = $true }
    if ($login -match $ExcludeRegex) { $shouldDelete = $true }
    if ($ExcludeLogins -contains $login) { $shouldDelete = $true }
    if ($login -like "$*") { $shouldDelete = $true }

    foreach ($ex in $ExcludeCompanies) { if ($comp -like "*$ex*") { $shouldDelete = $true } }
    foreach ($ex in $ExcludeDepts) { if ($dept -like "*$ex*") { $shouldDelete = $true } }

    if ($disp -like "*Microsoft Exchange*") { $shouldDelete = $true }
    if ($disp -like "*SystemMailbox*") { $shouldDelete = $true }

    if ($shouldDelete) { $ToDelete += $u }
}

Write-Host "Found $($ToDelete.Count) users to remove." -ForegroundColor Yellow
foreach ($u in $ToDelete) {
    # Пытаемся удалить. Если не выходит (например, системный объект), просто пропускаем.
    try {
        Remove-ADUser -Identity $u.sAMAccountName -Confirm:$false -ErrorAction Stop
        Write-Host "Removed: $($u.sAMAccountName)"
    } catch {
        Write-Host "Skip (protected or error): $($u.sAMAccountName)" -ForegroundColor Gray
    }
}
Write-Host "Cleanup Complete." -ForegroundColor Green
