# Скрипт 2: Импорт структуры и пользователей из Excel в AD
Import-Module ActiveDirectory
$BaseDN = 'DC=sync,DC=rusagroeco,DC=ru'
$RootOU = 'OU=B24_Structure,' + $BaseDN
try { New-ADOrganizationalUnit -Name 'B24_Structure' -Path $BaseDN -ErrorAction Stop } catch {}

try { New-ADOrganizationalUnit -Name 'ОСП "Ростовское"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Управление по экономике и финансам' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'margarita.gradinarova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Градинарова Маргарита Александровна' -DisplayName 'Градинарова Маргарита Александровна' -GivenName 'Маргарита' -Surname 'Градинарова' -sAMAccountName 'margarita.gradinarova' -UserPrincipalName 'margarita.gradinarova@sync.rusagroeco.ru' -Path 'OU=Управление по экономике и финансам,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель генерального директора по экономике и финансам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'marina.karasova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Карасова Марина Юрьевна' -DisplayName 'Карасова Марина Юрьевна' -GivenName 'Марина' -Surname 'Карасова' -sAMAccountName 'marina.karasova' -UserPrincipalName 'marina.karasova@sync.rusagroeco.ru' -Path 'OU=Управление по экономике и финансам,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный бухгалтер малых предприятий' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по контроллингу' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'viktoriya.goncharenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гончаренко Виктория Николаевна' -DisplayName 'Гончаренко Виктория Николаевна' -GivenName 'Виктория' -Surname 'Гончаренко' -sAMAccountName 'viktoriya.goncharenko' -UserPrincipalName 'viktoriya.goncharenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по контроллингу,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный экономист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.shtykh'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Штых Александр Николаевич' -DisplayName 'Штых Александр Николаевич' -GivenName 'Александр' -Surname 'Штых' -sAMAccountName 'aleksandr.shtykh' -UserPrincipalName 'aleksandr.shtykh@sync.rusagroeco.ru' -Path 'OU=Дирекция по контроллингу,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный экономист по управленческому учёту' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikolay.samarin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Самарин Николай Алексеевич' -DisplayName 'Самарин Николай Алексеевич' -GivenName 'Николай' -Surname 'Самарин' -sAMAccountName 'nikolay.samarin' -UserPrincipalName 'nikolay.samarin@sync.rusagroeco.ru' -Path 'OU=Дирекция по контроллингу,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист по инвестициям' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция бухгалтерского учета и отчетности' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.pletneva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Плетнева Наталья Викторовна' -DisplayName 'Плетнева Наталья Викторовна' -GivenName 'Наталья' -Surname 'Плетнева' -sAMAccountName 'natalya.pletneva' -UserPrincipalName 'natalya.pletneva@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела бухгалтерского учета и отчетности Ростовского и Краснодарского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция бухгалтерского учета и отчетности' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.bezhanova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бежанова Татьяна Ивановна' -DisplayName 'Бежанова Татьяна Ивановна' -GivenName 'Татьяна' -Surname 'Бежанова' -sAMAccountName 'tatyana.bezhanova' -UserPrincipalName 'tatyana.bezhanova@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления бухгалтерского учета и отчетности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'galina.shramko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Шрамко Галина Николаевна' -DisplayName 'Шрамко Галина Николаевна' -GivenName 'Галина' -Surname 'Шрамко' -sAMAccountName 'galina.shramko' -UserPrincipalName 'galina.shramko@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель расчетной группы Ростовского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.falaleeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Фалалеева Наталья Алексеевна' -DisplayName 'Фалалеева Наталья Алексеевна' -GivenName 'Наталья' -Surname 'Фалалеева' -sAMAccountName 'natalya.falaleeva' -UserPrincipalName 'natalya.falaleeva@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист расчетной группы' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sofya.grigoryan'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Григорян Софья Феликсовна' -DisplayName 'Григорян Софья Феликсовна' -GivenName 'Софья' -Surname 'Григорян' -sAMAccountName 'sofya.grigoryan' -UserPrincipalName 'sofya.grigoryan@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления по налоговому учету Ростовского и Краснодарского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел контроллинга' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.alekseenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Алексеенко Сергей Игоревич' -DisplayName 'Алексеенко Сергей Игоревич' -GivenName 'Сергей' -Surname 'Алексеенко' -sAMAccountName 'sergey.alekseenko' -UserPrincipalName 'sergey.alekseenko@sync.rusagroeco.ru' -Path 'OU=Отдел контроллинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный экономист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.moyseenkov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Мойсеенков Дмитрий Андреевич' -DisplayName 'Мойсеенков Дмитрий Андреевич' -GivenName 'Дмитрий' -Surname 'Мойсеенков' -sAMAccountName 'dmitriy.moyseenkov' -UserPrincipalName 'dmitriy.moyseenkov@sync.rusagroeco.ru' -Path 'OU=Отдел контроллинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий экономист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'lyudmila.dolgonosova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Долгоносова Людмила Сергеевна' -DisplayName 'Долгоносова Людмила Сергеевна' -GivenName 'Людмила' -Surname 'Долгоносова' -sAMAccountName 'lyudmila.dolgonosova' -UserPrincipalName 'lyudmila.dolgonosova@sync.rusagroeco.ru' -Path 'OU=Отдел контроллинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела контроллинга Ростовского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел казначейских операций' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mariya.donova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Донова Мария Михайловна' -DisplayName 'Донова Мария Михайловна' -GivenName 'Мария' -Surname 'Донова' -sAMAccountName 'mariya.donova' -UserPrincipalName 'mariya.donova@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела казначейских операций' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alina.biryukova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бирюкова Алина Андреевна' -DisplayName 'Бирюкова Алина Андреевна' -GivenName 'Алина' -Surname 'Бирюкова' -sAMAccountName 'alina.biryukova' -UserPrincipalName 'alina.biryukova@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления казначейских операций' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valeriya.durneva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дурнева Валерия Александровна' -DisplayName 'Дурнева Валерия Александровна' -GivenName 'Валерия' -Surname 'Дурнева' -sAMAccountName 'valeriya.durneva' -UserPrincipalName 'valeriya.durneva@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.bakhmatskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бахмацкая Светлана Анатольевна' -DisplayName 'Бахмацкая Светлана Анатольевна' -GivenName 'Светлана' -Surname 'Бахмацкая' -sAMAccountName 'svetlana.bakhmatskaya' -UserPrincipalName 'svetlana.bakhmatskaya@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел кредитования' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'petr.levchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Левченко Петр Иванович' -DisplayName 'Левченко Петр Иванович' -GivenName 'Петр' -Surname 'Левченко' -sAMAccountName 'petr.levchenko' -UserPrincipalName 'petr.levchenko@sync.rusagroeco.ru' -Path 'OU=Отдел кредитования,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела кредитования' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.geykina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гейкина Ирина Ильинична' -DisplayName 'Гейкина Ирина Ильинична' -GivenName 'Ирина' -Surname 'Гейкина' -sAMAccountName 'irina.geykina' -UserPrincipalName 'irina.geykina@sync.rusagroeco.ru' -Path 'OU=Отдел кредитования,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.ilyashenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ильяшенко Светлана Александровна' -DisplayName 'Ильяшенко Светлана Александровна' -GivenName 'Светлана' -Surname 'Ильяшенко' -sAMAccountName 'svetlana.ilyashenko' -UserPrincipalName 'svetlana.ilyashenko@sync.rusagroeco.ru' -Path 'OU=Отдел кредитования,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел государственной поддержки' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vera.esipenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Есипенко Вера Тихоновна' -DisplayName 'Есипенко Вера Тихоновна' -GivenName 'Вера' -Surname 'Есипенко' -sAMAccountName 'vera.esipenko' -UserPrincipalName 'vera.esipenko@sync.rusagroeco.ru' -Path 'OU=Отдел государственной поддержки,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист по страхованию' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anzhela.mitina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Митина Анжела Анатольевна' -DisplayName 'Митина Анжела Анатольевна' -GivenName 'Анжела' -Surname 'Митина' -sAMAccountName 'anzhela.mitina' -UserPrincipalName 'anzhela.mitina@sync.rusagroeco.ru' -Path 'OU=Отдел государственной поддержки,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист по субсидиям' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nadezhda.ilyashenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ильяшенко Надежда Александровна' -DisplayName 'Ильяшенко Надежда Александровна' -GivenName 'Надежда' -Surname 'Ильяшенко' -sAMAccountName 'nadezhda.ilyashenko' -UserPrincipalName 'nadezhda.ilyashenko@sync.rusagroeco.ru' -Path 'OU=Отдел государственной поддержки,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vasiliy.zevakin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Зевакин Василий Владимирович' -DisplayName 'Зевакин Василий Владимирович' -GivenName 'Василий' -Surname 'Зевакин' -sAMAccountName 'vasiliy.zevakin' -UserPrincipalName 'vasiliy.zevakin@sync.rusagroeco.ru' -Path 'OU=Отдел государственной поддержки,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела государственной поддержки' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по казначейским операциям' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.vorobeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Воробьева Елена Александровна' -DisplayName 'Воробьева Елена Александровна' -GivenName 'Елена' -Surname 'Воробьева' -sAMAccountName 'elena.vorobeva' -UserPrincipalName 'elena.vorobeva@sync.rusagroeco.ru' -Path 'OU=Дирекция по казначейским операциям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по казначейским операциям' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление по корпоративной работе' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mikhail.chernyshev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Чернышев Михаил Александрович' -DisplayName 'Чернышев Михаил Александрович' -GivenName 'Михаил' -Surname 'Чернышев' -sAMAccountName 'mikhail.chernyshev' -UserPrincipalName 'mikhail.chernyshev@sync.rusagroeco.ru' -Path 'OU=Управление по корпоративной работе,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель генерального директора по корпоративной работе' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по управлению недвижимым имуществом Ростовской области и Республики Калмыкия' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'liliya.petrova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Петрова Лилия Александровна' -DisplayName 'Петрова Лилия Александровна' -GivenName 'Лилия' -Surname 'Петрова' -sAMAccountName 'liliya.petrova' -UserPrincipalName 'liliya.petrova@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.valueva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Валуева Ирина Евгеньевна' -DisplayName 'Валуева Ирина Евгеньевна' -GivenName 'Ирина' -Surname 'Валуева' -sAMAccountName 'irina.valueva' -UserPrincipalName 'irina.valueva@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'marina.agarkova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Агаркова Марина Николаевна' -DisplayName 'Агаркова Марина Николаевна' -GivenName 'Марина' -Surname 'Агаркова' -sAMAccountName 'marina.agarkova' -UserPrincipalName 'marina.agarkova@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по правовым и корпоративным вопросам Ростовской области и Республики Калмыкия' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ester.arabachyan'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Арабачян Эстер Самвеловна' -DisplayName 'Арабачян Эстер Самвеловна' -GivenName 'Эстер' -Surname 'Арабачян' -sAMAccountName 'ester.arabachyan' -UserPrincipalName 'ester.arabachyan@sync.rusagroeco.ru' -Path 'OU=Отдел по правовым и корпоративным вопросам Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'marina.prikhodko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Приходько Марина Владимировна' -DisplayName 'Приходько Марина Владимировна' -GivenName 'Марина' -Surname 'Приходько' -sAMAccountName 'marina.prikhodko' -UserPrincipalName 'marina.prikhodko@sync.rusagroeco.ru' -Path 'OU=Отдел по правовым и корпоративным вопросам Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alevtina.stryzhakova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Стрыжакова Алевтина Викторовна' -DisplayName 'Стрыжакова Алевтина Викторовна' -GivenName 'Алевтина' -Surname 'Стрыжакова' -sAMAccountName 'alevtina.stryzhakova' -UserPrincipalName 'alevtina.stryzhakova@sync.rusagroeco.ru' -Path 'OU=Отдел по правовым и корпоративным вопросам Ростовской области и Республики Калмыкия,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела по правовым и корпоративным вопросам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по развитию земельного банка' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.vasilev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Васильев Алексей Николаевич' -DisplayName 'Васильев Алексей Николаевич' -GivenName 'Алексей' -Surname 'Васильев' -sAMAccountName 'aleksey.vasilev' -UserPrincipalName 'aleksey.vasilev@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vadim.kovalev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ковалев Вадим Эдуардович' -DisplayName 'Ковалев Вадим Эдуардович' -GivenName 'Вадим' -Surname 'Ковалев' -sAMAccountName 'vadim.kovalev' -UserPrincipalName 'vadim.kovalev@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по развитию земельного банка' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.pashchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пащенко Дмитрий Анатольевич' -DisplayName 'Пащенко Дмитрий Анатольевич' -GivenName 'Дмитрий' -Surname 'Пащенко' -sAMAccountName 'dmitriy.pashchenko' -UserPrincipalName 'dmitriy.pashchenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель директора по развитию земельного банка' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'eduard.besedin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Беседин Эдуард Юрьевич' -DisplayName 'Беседин Эдуард Юрьевич' -GivenName 'Эдуард' -Surname 'Беседин' -sAMAccountName 'eduard.besedin' -UserPrincipalName 'eduard.besedin@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция правовой и корпоративной работы' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ismoil.makhmudov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Махмудов Исмоил Искандар Оглы' -DisplayName 'Махмудов Исмоил Искандар Оглы' -GivenName 'Исмоил' -Surname 'Махмудов' -sAMAccountName 'ismoil.makhmudov' -UserPrincipalName 'ismoil.makhmudov@sync.rusagroeco.ru' -Path 'OU=Дирекция правовой и корпоративной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель цифровых проектов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.guziev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гузиев Владимир Владимирович' -DisplayName 'Гузиев Владимир Владимирович' -GivenName 'Владимир' -Surname 'Гузиев' -sAMAccountName 'vladimir.guziev' -UserPrincipalName 'vladimir.guziev@sync.rusagroeco.ru' -Path 'OU=Дирекция правовой и корпоративной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по правовым и корпоративным вопросам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел корпоративной работы' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandra.lavreshina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лаврешина Александра Анатольевна' -DisplayName 'Лаврешина Александра Анатольевна' -GivenName 'Александра' -Surname 'Лаврешина' -sAMAccountName 'aleksandra.lavreshina' -UserPrincipalName 'aleksandra.lavreshina@sync.rusagroeco.ru' -Path 'OU=Отдел корпоративной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела корпоративной работы' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.arkusha'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Аркуша Наталья Захаровна' -DisplayName 'Аркуша Наталья Захаровна' -GivenName 'Наталья' -Surname 'Аркуша' -sAMAccountName 'natalya.arkusha' -UserPrincipalName 'natalya.arkusha@sync.rusagroeco.ru' -Path 'OU=Отдел корпоративной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'polina.kalinina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Калинина Полина Сергеевна' -DisplayName 'Калинина Полина Сергеевна' -GivenName 'Полина' -Surname 'Калинина' -sAMAccountName 'polina.kalinina' -UserPrincipalName 'polina.kalinina@sync.rusagroeco.ru' -Path 'OU=Отдел корпоративной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по управлению недвижимым имуществом' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tamara.razinkova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Разинкова Тамара Ильинична' -DisplayName 'Разинкова Тамара Ильинична' -GivenName 'Тамара' -Surname 'Разинкова' -sAMAccountName 'tamara.razinkova' -UserPrincipalName 'tamara.razinkova@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению недвижимым имуществом,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по управлению недвижимым имуществом' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба аналитической и архивной работы' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.uryupina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Урюпина Дарья Владимировна' -DisplayName 'Урюпина Дарья Владимировна' -GivenName 'Дарья' -Surname 'Урюпина' -sAMAccountName 'darya.uryupina' -UserPrincipalName 'darya.uryupina@sync.rusagroeco.ru' -Path 'OU=Служба аналитической и архивной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по документообороту' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.minkina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Минкина Ирина Александровна' -DisplayName 'Минкина Ирина Александровна' -GivenName 'Ирина' -Surname 'Минкина' -sAMAccountName 'irina.minkina' -UserPrincipalName 'irina.minkina@sync.rusagroeco.ru' -Path 'OU=Служба аналитической и архивной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ekaterina.kotsyuk'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Коцюк Екатерина Ервантовна' -DisplayName 'Коцюк Екатерина Ервантовна' -GivenName 'Екатерина' -Surname 'Коцюк' -sAMAccountName 'ekaterina.kotsyuk' -UserPrincipalName 'ekaterina.kotsyuk@sync.rusagroeco.ru' -Path 'OU=Служба аналитической и архивной работы,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный менеджер по недвижимости' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление по персоналу и организационному развитию' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuliya.denisenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Денисенко Юлия Анатольевна' -DisplayName 'Денисенко Юлия Анатольевна' -GivenName 'Юлия' -Surname 'Денисенко' -sAMAccountName 'yuliya.denisenko' -UserPrincipalName 'yuliya.denisenko@sync.rusagroeco.ru' -Path 'OU=Управление по персоналу и организационному развитию,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель генерального директора по персоналу и организационному развитию' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел административно-хозяйственного обеспечения' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'roman.zakharov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Захаров Роман Александрович' -DisplayName 'Захаров Роман Александрович' -GivenName 'Роман' -Surname 'Захаров' -sAMAccountName 'roman.zakharov' -UserPrincipalName 'roman.zakharov@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.plaksin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Плаксин Иван Витальевич' -DisplayName 'Плаксин Иван Витальевич' -GivenName 'Иван' -Surname 'Плаксин' -sAMAccountName 'ivan.plaksin' -UserPrincipalName 'ivan.plaksin@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.klimenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Клименко Алексей Николаевич' -DisplayName 'Клименко Алексей Николаевич' -GivenName 'Алексей' -Surname 'Клименко' -sAMAccountName 'aleksey.klimenko' -UserPrincipalName 'aleksey.klimenko@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел административно-хозяйственного обеспечения' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikita.ognev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Огнев Никита Алексеевич' -DisplayName 'Огнев Никита Алексеевич' -GivenName 'Никита' -Surname 'Огнев' -sAMAccountName 'nikita.ognev' -UserPrincipalName 'nikita.ognev@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'pavel.antonenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Антоненко Павел Олегович' -DisplayName 'Антоненко Павел Олегович' -GivenName 'Павел' -Surname 'Антоненко' -sAMAccountName 'pavel.antonenko' -UserPrincipalName 'pavel.antonenko@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель административно-хозяйственного отдела' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.salova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Салова Дарья Михайловна' -DisplayName 'Салова Дарья Михайловна' -GivenName 'Дарья' -Surname 'Салова' -sAMAccountName 'darya.salova' -UserPrincipalName 'darya.salova@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по документообороту' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anastasiya.doroganova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дороганова Анастасия Сергеевна' -DisplayName 'Дороганова Анастасия Сергеевна' -GivenName 'Анастасия' -Surname 'Дороганова' -sAMAccountName 'anastasiya.doroganova' -UserPrincipalName 'anastasiya.doroganova@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Офис-менеджер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'denis.ikanin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Иканин Денис Владимирович' -DisplayName 'Иканин Денис Владимирович' -GivenName 'Денис' -Surname 'Иканин' -sAMAccountName 'denis.ikanin' -UserPrincipalName 'denis.ikanin@sync.rusagroeco.ru' -Path 'OU=Отдел административно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель группы сервисного обслуживания и эксплуатации транспорта' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба управления персоналом' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yaroslava.levchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Левченко Ярослава Олеговна' -DisplayName 'Левченко Ярослава Олеговна' -GivenName 'Ярослава' -Surname 'Левченко' -sAMAccountName 'yaroslava.levchenko' -UserPrincipalName 'yaroslava.levchenko@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы управления персоналом' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.sirota'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Сирота Наталья Викторовна' -DisplayName 'Сирота Наталья Викторовна' -GivenName 'Наталья' -Surname 'Сирота' -sAMAccountName 'natalya.sirota' -UserPrincipalName 'natalya.sirota@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления оплаты труда и мотивации персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по подбору персонала' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.merkulova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Меркулова Светлана Викторовна' -DisplayName 'Меркулова Светлана Викторовна' -GivenName 'Светлана' -Surname 'Меркулова' -sAMAccountName 'svetlana.merkulova' -UserPrincipalName 'svetlana.merkulova@sync.rusagroeco.ru' -Path 'OU=Дирекция по подбору персонала,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по подбору персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел стратегического подбора' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anna.polokhova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Полохова Анна Сергеевна' -DisplayName 'Полохова Анна Сергеевна' -GivenName 'Анна' -Surname 'Полохова' -sAMAccountName 'anna.polokhova' -UserPrincipalName 'anna.polokhova@sync.rusagroeco.ru' -Path 'OU=Отдел стратегического подбора,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела стратегического подбора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elina.kalieva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Калиева Элина Галимовна' -DisplayName 'Калиева Элина Галимовна' -GivenName 'Элина' -Surname 'Калиева' -sAMAccountName 'elina.kalieva' -UserPrincipalName 'elina.kalieva@sync.rusagroeco.ru' -Path 'OU=Отдел стратегического подбора,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Менеджер по подбору персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по кадровому администрированию' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olga.grechenkova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Греченкова Ольга Михайловна' -DisplayName 'Греченкова Ольга Михайловна' -GivenName 'Ольга' -Surname 'Греченкова' -sAMAccountName 'olga.grechenkova' -UserPrincipalName 'olga.grechenkova@sync.rusagroeco.ru' -Path 'OU=Дирекция по кадровому администрированию,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления методологии кадрового делопроизводства' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.babakova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бабакова Светлана Евгеньевна' -DisplayName 'Бабакова Светлана Евгеньевна' -GivenName 'Светлана' -Surname 'Бабакова' -sAMAccountName 'svetlana.babakova' -UserPrincipalName 'svetlana.babakova@sync.rusagroeco.ru' -Path 'OU=Дирекция по кадровому администрированию,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по кадровому администрированию и воинскому учету' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'viktor.streltsov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Стрельцов Виктор Вячеславович' -DisplayName 'Стрельцов Виктор Вячеславович' -GivenName 'Виктор' -Surname 'Стрельцов' -sAMAccountName 'viktor.streltsov' -UserPrincipalName 'viktor.streltsov@sync.rusagroeco.ru' -Path 'OU=Дирекция по кадровому администрированию,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по персональным данным' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'kseniya.kino'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кино Ксения Валентиновна' -DisplayName 'Кино Ксения Валентиновна' -GivenName 'Ксения' -Surname 'Кино' -sAMAccountName 'kseniya.kino' -UserPrincipalName 'kseniya.kino@sync.rusagroeco.ru' -Path 'OU=Дирекция по кадровому администрированию,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по аудиту кадрового администрирования' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по эффективности труда и вознаграждениям' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.gromak'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Громак Светлана Генадьевна' -DisplayName 'Громак Светлана Генадьевна' -GivenName 'Светлана' -Surname 'Громак' -sAMAccountName 'svetlana.gromak' -UserPrincipalName 'svetlana.gromak@sync.rusagroeco.ru' -Path 'OU=Дирекция по эффективности труда и вознаграждениям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по эффективности труда и вознаграждению персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anastasiya.aksinina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Аксинина Анастасия Александровна' -DisplayName 'Аксинина Анастасия Александровна' -GivenName 'Анастасия' -Surname 'Аксинина' -sAMAccountName 'anastasiya.aksinina' -UserPrincipalName 'anastasiya.aksinina@sync.rusagroeco.ru' -Path 'OU=Дирекция по эффективности труда и вознаграждениям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления организационного развития' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuliya.sukhanova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Суханова Юлия Владимировна' -DisplayName 'Суханова Юлия Владимировна' -GivenName 'Юлия' -Surname 'Суханова' -sAMAccountName 'yuliya.sukhanova' -UserPrincipalName 'yuliya.sukhanova@sync.rusagroeco.ru' -Path 'OU=Дирекция по эффективности труда и вознаграждениям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела оплаты труда и мотивации персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandra.martyshchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Мартыщенко Александра Викторовна' -DisplayName 'Мартыщенко Александра Викторовна' -GivenName 'Александра' -Surname 'Мартыщенко' -sAMAccountName 'aleksandra.martyshchenko' -UserPrincipalName 'aleksandra.martyshchenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по эффективности труда и вознаграждениям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по оплате труда и мотивации персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'lyubov.bogatikova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Богатикова Любовь Николаевна' -DisplayName 'Богатикова Любовь Николаевна' -GivenName 'Любовь' -Surname 'Богатикова' -sAMAccountName 'lyubov.bogatikova' -UserPrincipalName 'lyubov.bogatikova@sync.rusagroeco.ru' -Path 'OU=Дирекция по эффективности труда и вознаграждениям,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист методологии и анализа оплаты труда' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел внутренних коммуникаций и корпоративной культуры' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olesya.gavrilova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гаврилова Олеся Валерьевна' -DisplayName 'Гаврилова Олеся Валерьевна' -GivenName 'Олеся' -Surname 'Гаврилова' -sAMAccountName 'olesya.gavrilova' -UserPrincipalName 'olesya.gavrilova@sync.rusagroeco.ru' -Path 'OU=Отдел внутренних коммуникаций и корпоративной культуры,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела внутренних коммуникаций и корпоративной культуры' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'diana.zakharova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Захарова Диана Олеговна' -DisplayName 'Захарова Диана Олеговна' -GivenName 'Диана' -Surname 'Захарова' -sAMAccountName 'diana.zakharova' -UserPrincipalName 'diana.zakharova@sync.rusagroeco.ru' -Path 'OU=Отдел внутренних коммуникаций и корпоративной культуры,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Менеджер по внутренним коммуникациям и корпоративной культуре' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по работе с молодежью' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mariya.nesterova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Нестерова Мария Петровна' -DisplayName 'Нестерова Мария Петровна' -GivenName 'Мария' -Surname 'Нестерова' -sAMAccountName 'mariya.nesterova' -UserPrincipalName 'mariya.nesterova@sync.rusagroeco.ru' -Path 'OU=Отдел по работе с молодежью,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по работе с молодежью' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел обучения и развития персонала' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'lidiya.evsegneeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Евсегнеева Лидия Юрьевна' -DisplayName 'Евсегнеева Лидия Юрьевна' -GivenName 'Лидия' -Surname 'Евсегнеева' -sAMAccountName 'lidiya.evsegneeva' -UserPrincipalName 'lidiya.evsegneeva@sync.rusagroeco.ru' -Path 'OU=Отдел обучения и развития персонала,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела производственного обучения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.penshina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пеньшина Наталья Сергеевна' -DisplayName 'Пеньшина Наталья Сергеевна' -GivenName 'Наталья' -Surname 'Пеньшина' -sAMAccountName 'natalya.penshina' -UserPrincipalName 'natalya.penshina@sync.rusagroeco.ru' -Path 'OU=Отдел обучения и развития персонала,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по производственному обучению' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел информационных технологий' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'binali.bachatov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бачатов Бинали Казымович' -DisplayName 'Бачатов Бинали Казымович' -GivenName 'Бинали' -Surname 'Бачатов' -sAMAccountName 'binali.bachatov' -UserPrincipalName 'binali.bachatov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел информационных технологий' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'grigoriy.obryashchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Обрященко Григорий Павлович' -DisplayName 'Обрященко Григорий Павлович' -GivenName 'Григорий' -Surname 'Обрященко' -sAMAccountName 'grigoriy.obryashchenko' -UserPrincipalName 'grigoriy.obryashchenko@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.gumen'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гумен Светлана Петровна' -DisplayName 'Гумен Светлана Петровна' -GivenName 'Светлана' -Surname 'Гумен' -sAMAccountName 'svetlana.gumen' -UserPrincipalName 'svetlana.gumen@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Программист 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valeriy.tsekhovskoy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Цеховской Валерий Александрович' -DisplayName 'Цеховской Валерий Александрович' -GivenName 'Валерий' -Surname 'Цеховской' -sAMAccountName 'valeriy.tsekhovskoy' -UserPrincipalName 'valeriy.tsekhovskoy@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель цифровых проектов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.motorin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Моторин Дмитрий Алексеевич' -DisplayName 'Моторин Дмитрий Алексеевич' -GivenName 'Дмитрий' -Surname 'Моторин' -sAMAccountName 'dmitriy.motorin' -UserPrincipalName 'dmitriy.motorin@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.strekozov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Стрекозов Иван Владимирович' -DisplayName 'Стрекозов Иван Владимирович' -GivenName 'Иван' -Surname 'Стрекозов' -sAMAccountName 'ivan.strekozov' -UserPrincipalName 'ivan.strekozov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления технического обеспечения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел развития семеноводства и агротехнологий' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'oksana.ermolina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ермолина Оксана Владимировна' -DisplayName 'Ермолина Оксана Владимировна' -GivenName 'Оксана' -Surname 'Ермолина' -sAMAccountName 'oksana.ermolina' -UserPrincipalName 'oksana.ermolina@sync.rusagroeco.ru' -Path 'OU=Отдел развития семеноводства и агротехнологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела развития семеноводства и агротехнологий' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.balin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Балин Александр Александрович' -DisplayName 'Балин Александр Александрович' -GivenName 'Александр' -Surname 'Балин' -sAMAccountName 'aleksandr.balin' -UserPrincipalName 'aleksandr.balin@sync.rusagroeco.ru' -Path 'OU=Отдел развития семеноводства и агротехнологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anton.gudym'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гудым Антон Сергеевич' -DisplayName 'Гудым Антон Сергеевич' -GivenName 'Антон' -Surname 'Гудым' -sAMAccountName 'anton.gudym' -UserPrincipalName 'anton.gudym@sync.rusagroeco.ru' -Path 'OU=Отдел развития семеноводства и агротехнологий,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном-селекционер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел научных разработок' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vasiliy.tsyganov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Цыганов Василий Васильевич' -DisplayName 'Цыганов Василий Васильевич' -GivenName 'Василий' -Surname 'Цыганов' -sAMAccountName 'vasiliy.tsyganov' -UserPrincipalName 'vasiliy.tsyganov@sync.rusagroeco.ru' -Path 'OU=Отдел научных разработок,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.ryabushchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Рябущенко Александр Николаевич' -DisplayName 'Рябущенко Александр Николаевич' -GivenName 'Александр' -Surname 'Рябущенко' -sAMAccountName 'aleksandr.ryabushchenko' -UserPrincipalName 'aleksandr.ryabushchenko@sync.rusagroeco.ru' -Path 'OU=Отдел научных разработок,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по автоматизации животноводства' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел производственного мониторинга' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.drango'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дранго Татьяна Витальевна' -DisplayName 'Дранго Татьяна Витальевна' -GivenName 'Татьяна' -Surname 'Дранго' -sAMAccountName 'tatyana.drango' -UserPrincipalName 'tatyana.drango@sync.rusagroeco.ru' -Path 'OU=Отдел производственного мониторинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по производственному мониторингу' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikita.pestich'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пестич Никита Витальевич' -DisplayName 'Пестич Никита Витальевич' -GivenName 'Никита' -Surname 'Пестич' -sAMAccountName 'nikita.pestich' -UserPrincipalName 'nikita.pestich@sync.rusagroeco.ru' -Path 'OU=Отдел производственного мониторинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по производственному мониторингу' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuliya.skidan'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Скидан Юлия Александровна' -DisplayName 'Скидан Юлия Александровна' -GivenName 'Юлия' -Surname 'Скидан' -sAMAccountName 'yuliya.skidan' -UserPrincipalName 'yuliya.skidan@sync.rusagroeco.ru' -Path 'OU=Отдел производственного мониторинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по геоинформационным системам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.marchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Марченко Иван Николаевич' -DisplayName 'Марченко Иван Николаевич' -GivenName 'Иван' -Surname 'Марченко' -sAMAccountName 'ivan.marchenko' -UserPrincipalName 'ivan.marchenko@sync.rusagroeco.ru' -Path 'OU=Отдел производственного мониторинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Оператор беспилотных летательных аппаратов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.ryabushchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Рябущенко Наталья Григорьевна' -DisplayName 'Рябущенко Наталья Григорьевна' -GivenName 'Наталья' -Surname 'Рябущенко' -sAMAccountName 'natalya.ryabushchenko' -UserPrincipalName 'natalya.ryabushchenko@sync.rusagroeco.ru' -Path 'OU=Отдел производственного мониторинга,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления производственного мониторинга' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Операционная дирекция' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.tretyakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Третьяков Евгений Валерьевич' -DisplayName 'Третьяков Евгений Валерьевич' -GivenName 'Евгений' -Surname 'Третьяков' -sAMAccountName 'evgeniy.tretyakov' -UserPrincipalName 'evgeniy.tretyakov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Операционный директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.miroshnichenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Мирошниченко Александр Викторович' -DisplayName 'Мирошниченко Александр Викторович' -GivenName 'Александр' -Surname 'Мирошниченко' -sAMAccountName 'aleksandr.miroshnichenko' -UserPrincipalName 'aleksandr.miroshnichenko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'petr.kufaev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Куфаев Петр Леонидович' -DisplayName 'Куфаев Петр Леонидович' -GivenName 'Петр' -Surname 'Куфаев' -sAMAccountName 'petr.kufaev' -UserPrincipalName 'petr.kufaev@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном-семеновод' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'raisa.makshantseva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Макшанцева Раиса Юрьевна' -DisplayName 'Макшанцева Раиса Юрьевна' -GivenName 'Раиса' -Surname 'Макшанцева' -sAMAccountName 'raisa.makshantseva' -UserPrincipalName 'raisa.makshantseva@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном-аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuriy.lebedenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лебеденко Юрий Николаевич' -DisplayName 'Лебеденко Юрий Николаевич' -GivenName 'Юрий' -Surname 'Лебеденко' -sAMAccountName 'yuriy.lebedenko' -UserPrincipalName 'yuriy.lebedenko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель по животноводству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vitaliy.zakharov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Захаров Виталий Викторович' -DisplayName 'Захаров Виталий Викторович' -GivenName 'Виталий' -Surname 'Захаров' -sAMAccountName 'vitaliy.zakharov' -UserPrincipalName 'vitaliy.zakharov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инженер по эксплуатации' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikolay.teslenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Тесленко Николай Фиодосиевич' -DisplayName 'Тесленко Николай Фиодосиевич' -GivenName 'Николай' -Surname 'Тесленко' -sAMAccountName 'nikolay.teslenko' -UserPrincipalName 'nikolay.teslenko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Зоотехник' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuriy.turov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Туров Юрий Петрович' -DisplayName 'Туров Юрий Петрович' -GivenName 'Юрий' -Surname 'Туров' -sAMAccountName 'yuriy.turov' -UserPrincipalName 'yuriy.turov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления по развитию рыбоводства' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.dyakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дьяков Сергей Александрович' -DisplayName 'Дьяков Сергей Александрович' -GivenName 'Сергей' -Surname 'Дьяков' -sAMAccountName 'sergey.dyakov' -UserPrincipalName 'sergey.dyakov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном-рисовод' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'matvey.nekrasov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Некрасов Матвей Андреевич' -DisplayName 'Некрасов Матвей Андреевич' -GivenName 'Матвей' -Surname 'Некрасов' -sAMAccountName 'matvey.nekrasov' -UserPrincipalName 'matvey.nekrasov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном по аналитике' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.kosakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Косаков Сергей Анатольевич' -DisplayName 'Косаков Сергей Анатольевич' -GivenName 'Сергей' -Surname 'Косаков' -sAMAccountName 'sergey.kosakov' -UserPrincipalName 'sergey.kosakov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель операционного директора по производству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба безопасности объектов и персонала' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuriy.kononov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кононов Юрий Петрович' -DisplayName 'Кононов Юрий Петрович' -GivenName 'Юрий' -Surname 'Кононов' -sAMAccountName 'yuriy.kononov' -UserPrincipalName 'yuriy.kononov@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы безопасности объектов и персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olesya.chaychenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Чайченко Олеся Анатольевна' -DisplayName 'Чайченко Олеся Анатольевна' -GivenName 'Олеся' -Surname 'Чайченко' -sAMAccountName 'olesya.chaychenko' -UserPrincipalName 'olesya.chaychenko@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел экономической безопасности и противодействия коррупции' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'andrey.chertok'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Черток Андрей Иванович' -DisplayName 'Черток Андрей Иванович' -GivenName 'Андрей' -Surname 'Черток' -sAMAccountName 'andrey.chertok' -UserPrincipalName 'andrey.chertok@sync.rusagroeco.ru' -Path 'OU=Отдел экономической безопасности и противодействия коррупции,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Ростовс' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Отдел экономической безопасности и противодействия коррупции' -Path 'OU=ОСП \"Ростовс,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anton.shelikhov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Шелихов Антон Эдуардович' -DisplayName 'Шелихов Антон Эдуардович' -GivenName 'Антон' -Surname 'Шелихов' -sAMAccountName 'anton.shelikhov' -UserPrincipalName 'anton.shelikhov@sync.rusagroeco.ru' -Path 'OU=Отдел экономической безопасности и противодействия коррупции,OU=ОСП \"Ростовс,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела экономической безопасности и противодействия коррупции' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел экономической безопасности и противодействия коррупции' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladislav.gorobets'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Горобец Владислав Валерьевич' -DisplayName 'Горобец Владислав Валерьевич' -GivenName 'Владислав' -Surname 'Горобец' -sAMAccountName 'vladislav.gorobets' -UserPrincipalName 'vladislav.gorobets@sync.rusagroeco.ru' -Path 'OU=Отдел экономической безопасности и противодействия коррупции,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя отдела экономической безопасности и противодействия коррупции' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Организационно-аналитический отдел' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elina.damaskin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дамаскин Элина Георгиевна' -DisplayName 'Дамаскин Элина Георгиевна' -GivenName 'Элина' -Surname 'Дамаскин' -sAMAccountName 'elina.damaskin' -UserPrincipalName 'elina.damaskin@sync.rusagroeco.ru' -Path 'OU=Организационно-аналитический отдел,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladislav.bashmanov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Башманов Владислав Владимирович' -DisplayName 'Башманов Владислав Владимирович' -GivenName 'Владислав' -Surname 'Башманов' -sAMAccountName 'vladislav.bashmanov' -UserPrincipalName 'vladislav.bashmanov@sync.rusagroeco.ru' -Path 'OU=Организационно-аналитический отдел,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель организационно-аналитического отдела' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikolay.babchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бабченко Николай Васильевич' -DisplayName 'Бабченко Николай Васильевич' -GivenName 'Николай' -Surname 'Бабченко' -sAMAccountName 'nikolay.babchenko' -UserPrincipalName 'nikolay.babchenko@sync.rusagroeco.ru' -Path 'OU=Организационно-аналитический отдел,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя организационного-аналитического отдела' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел пожарной безопасности и предупреждения чрезвычайных ситуаций' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.koval'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Коваль Александр Александрович' -DisplayName 'Коваль Александр Александрович' -GivenName 'Александр' -Surname 'Коваль' -sAMAccountName 'aleksandr.koval' -UserPrincipalName 'aleksandr.koval@sync.rusagroeco.ru' -Path 'OU=Отдел пожарной безопасности и предупреждения чрезвычайных ситуаций,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела пожарной безопасности и предупреждения чрезвычайных ситуаций' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по экологической безопасности' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.galkina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Галкина Светлана Николаевна' -DisplayName 'Галкина Светлана Николаевна' -GivenName 'Светлана' -Surname 'Галкина' -sAMAccountName 'svetlana.galkina' -UserPrincipalName 'svetlana.galkina@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.pushkarskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пушкарская Татьяна Ивановна' -DisplayName 'Пушкарская Татьяна Ивановна' -GivenName 'Татьяна' -Surname 'Пушкарская' -sAMAccountName 'tatyana.pushkarskaya' -UserPrincipalName 'tatyana.pushkarskaya@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mikhail.talalay'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Талалай Михаил Владимирович' -DisplayName 'Талалай Михаил Владимирович' -GivenName 'Михаил' -Surname 'Талалай' -sAMAccountName 'mikhail.talalay' -UserPrincipalName 'mikhail.talalay@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.kigim'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кигим Елена Григорьевна' -DisplayName 'Кигим Елена Григорьевна' -GivenName 'Елена' -Surname 'Кигим' -sAMAccountName 'elena.kigim' -UserPrincipalName 'elena.kigim@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по техническому развитию и инфраструктуре' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.denisenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Денисенко Сергей Анатольевич' -DisplayName 'Денисенко Сергей Анатольевич' -GivenName 'Сергей' -Surname 'Денисенко' -sAMAccountName 'sergey.denisenko' -UserPrincipalName 'sergey.denisenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по техническому развитию и инфраструктуре,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по техническому развитию и инфраструктуре' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.kolodyazhnyy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Колодяжный Евгений Васильевич' -DisplayName 'Колодяжный Евгений Васильевич' -GivenName 'Евгений' -Surname 'Колодяжный' -sAMAccountName 'evgeniy.kolodyazhnyy' -UserPrincipalName 'evgeniy.kolodyazhnyy@sync.rusagroeco.ru' -Path 'OU=Дирекция по техническому развитию и инфраструктуре,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель проекта по созданию южного сервисного центра' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Ро' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Дирекция по техническому развитию и инфраструктуре' -Path 'OU=ОСП \"Ро,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.bliznyuk'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Близнюк Алексей Игоревич' -DisplayName 'Близнюк Алексей Игоревич' -GivenName 'Алексей' -Surname 'Близнюк' -sAMAccountName 'aleksey.bliznyuk' -UserPrincipalName 'aleksey.bliznyuk@sync.rusagroeco.ru' -Path 'OU=Дирекция по техническому развитию и инфраструктуре,OU=ОСП \"Ро,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель директора по техническому развитию и инфраструктуре по автоматизации процессов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по техническому развитию и инфр' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.pukhtiy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пухтий Александр Владимирович' -DisplayName 'Пухтий Александр Владимирович' -GivenName 'Александр' -Surname 'Пухтий' -sAMAccountName 'aleksandr.pukhtiy' -UserPrincipalName 'aleksandr.pukhtiy@sync.rusagroeco.ru' -Path 'OU=Дирекция по техническому развитию и инфр,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель директора по техническому развитию и инфраструктуре по ремонту и эксплуатации подвижного состава' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел автоматизации процессов' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.tarasova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Тарасова Татьяна Вячеславовна' -DisplayName 'Тарасова Татьяна Вячеславовна' -GivenName 'Татьяна' -Surname 'Тарасова' -sAMAccountName 'tatyana.tarasova' -UserPrincipalName 'tatyana.tarasova@sync.rusagroeco.ru' -Path 'OU=Отдел автоматизации процессов,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Методолог по техническому обслуживанию и ремонту' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба производственного контроля' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.erzakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ерзаков Александр Евгеньевич' -DisplayName 'Ерзаков Александр Евгеньевич' -GivenName 'Александр' -Surname 'Ерзаков' -sAMAccountName 'aleksandr.erzakov' -UserPrincipalName 'aleksandr.erzakov@sync.rusagroeco.ru' -Path 'OU=Служба производственного контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы производственного контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба акционерно-инспекторского контроля' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniya.krivolapova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Криволапова Евгения Юрьевна' -DisplayName 'Криволапова Евгения Юрьевна' -GivenName 'Евгения' -Surname 'Криволапова' -sAMAccountName 'evgeniya.krivolapova' -UserPrincipalName 'evgeniya.krivolapova@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'shamil.khachirov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Хачиров Шамиль Борисович' -DisplayName 'Хачиров Шамиль Борисович' -GivenName 'Шамиль' -Surname 'Хачиров' -sAMAccountName 'shamil.khachirov' -UserPrincipalName 'shamil.khachirov@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инспектор службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'abomuslim.dugachiev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дугачиев Абомуслим Батырсултанович' -DisplayName 'Дугачиев Абомуслим Батырсултанович' -GivenName 'Абомуслим' -Surname 'Дугачиев' -sAMAccountName 'abomuslim.dugachiev' -UserPrincipalName 'abomuslim.dugachiev@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инспектор службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.derzhaev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Держаев Сергей Анатольевич' -DisplayName 'Держаев Сергей Анатольевич' -GivenName 'Сергей' -Surname 'Держаев' -sAMAccountName 'sergey.derzhaev' -UserPrincipalName 'sergey.derzhaev@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'andrey.sherepa'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Шерепа Андрей Яковлевич' -DisplayName 'Шерепа Андрей Яковлевич' -GivenName 'Андрей' -Surname 'Шерепа' -sAMAccountName 'andrey.sherepa' -UserPrincipalName 'andrey.sherepa@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Старший инспектор службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Аппарат генерального директора' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alina.semerenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Семеренко Алина Сергеевна' -DisplayName 'Семеренко Алина Сергеевна' -GivenName 'Алина' -Surname 'Семеренко' -sAMAccountName 'alina.semerenko' -UserPrincipalName 'alina.semerenko@sync.rusagroeco.ru' -Path 'OU=Аппарат генерального директора,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Помощник генерального директора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по внутреннему контролю' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alena.prikhodko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Приходько Алена Владимировна' -DisplayName 'Приходько Алена Владимировна' -GivenName 'Алена' -Surname 'Приходько' -sAMAccountName 'alena.prikhodko' -UserPrincipalName 'alena.prikhodko@sync.rusagroeco.ru' -Path 'OU=Дирекция по внутреннему контролю,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по внутреннему контролю' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'zhanna.afanaseva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Афанасьева Жанна Александровна' -DisplayName 'Афанасьева Жанна Александровна' -GivenName 'Жанна' -Surname 'Афанасьева' -sAMAccountName 'zhanna.afanaseva' -UserPrincipalName 'zhanna.afanaseva@sync.rusagroeco.ru' -Path 'OU=Дирекция по внутреннему контролю,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист внутреннего контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.stepanenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Степаненко Александр Анатольевич' -DisplayName 'Степаненко Александр Анатольевич' -GivenName 'Александр' -Surname 'Степаненко' -sAMAccountName 'aleksandr.stepanenko' -UserPrincipalName 'aleksandr.stepanenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по внутреннему контролю,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист внутреннего контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба заказчика' -Path 'OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.bolotov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Болотов Дмитрий Вячеславович' -DisplayName 'Болотов Дмитрий Вячеславович' -GivenName 'Дмитрий' -Surname 'Болотов' -sAMAccountName 'dmitriy.bolotov' -UserPrincipalName 'dmitriy.bolotov@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель по строительству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.gornich'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Горнич Александр Валерьевич' -DisplayName 'Горнич Александр Валерьевич' -GivenName 'Александр' -Surname 'Горнич' -sAMAccountName 'aleksandr.gornich' -UserPrincipalName 'aleksandr.gornich@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Ростовское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий инженер по надзору за строительством' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'zoya.nekhaeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Нехаева Зоя Владимировна' -DisplayName 'Нехаева Зоя Владимировна' -GivenName 'Зоя' -Surname 'Нехаева' -sAMAccountName 'zoya.nekhaeva' -UserPrincipalName 'zoya.nekhaeva@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела бухгалтерского учета и отчетности Ставропольского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.kostina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Костина Светлана Валерьевна' -DisplayName 'Костина Светлана Валерьевна' -GivenName 'Светлана' -Surname 'Костина' -sAMAccountName 'svetlana.kostina' -UserPrincipalName 'svetlana.kostina@sync.rusagroeco.ru' -Path 'OU=Дирекция бухгалтерского учета и отчетности,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель расчетной группы Ставропольского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Ставропольское"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Отдел контроллинга' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.bragina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Брагина Светлана Федоровна' -DisplayName 'Брагина Светлана Федоровна' -GivenName 'Светлана' -Surname 'Брагина' -sAMAccountName 'svetlana.bragina' -UserPrincipalName 'svetlana.bragina@sync.rusagroeco.ru' -Path 'OU=Отдел контроллинга,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный экономист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.vdovydchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Вдовыдченко Наталья Александровна' -DisplayName 'Вдовыдченко Наталья Александровна' -GivenName 'Наталья' -Surname 'Вдовыдченко' -sAMAccountName 'natalya.vdovydchenko' -UserPrincipalName 'natalya.vdovydchenko@sync.rusagroeco.ru' -Path 'OU=Отдел контроллинга,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий экономист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по контроллингу' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'seda.bagdasaryan'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Багдасарян Седа Пайлаковна' -DisplayName 'Багдасарян Седа Пайлаковна' -GivenName 'Седа' -Surname 'Багдасарян' -sAMAccountName 'seda.bagdasaryan' -UserPrincipalName 'seda.bagdasaryan@sync.rusagroeco.ru' -Path 'OU=Дирекция по контроллингу,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления анализа отрасли животноводства' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба контроллинга' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'zalim.tlakadugov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Тлакадугов Залим Заурбекович' -DisplayName 'Тлакадугов Залим Заурбекович' -GivenName 'Залим' -Surname 'Тлакадугов' -sAMAccountName 'zalim.tlakadugov' -UserPrincipalName 'zalim.tlakadugov@sync.rusagroeco.ru' -Path 'OU=Служба контроллинга,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы контроллинга' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел подбора, адаптации и обучения персонала' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ekaterina.kraeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Краева Екатерина Александровна' -DisplayName 'Краева Екатерина Александровна' -GivenName 'Екатерина' -Surname 'Краева' -sAMAccountName 'ekaterina.kraeva' -UserPrincipalName 'ekaterina.kraeva@sync.rusagroeco.ru' -Path 'OU=Отдел подбора\, адаптации и обучения персонала,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Менеджер по подбору, адаптации и обучению персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел администратавно-хозяйственного обеспечения' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.cherkova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Черкова Светлана Ивановна' -DisplayName 'Черкова Светлана Ивановна' -GivenName 'Светлана' -Surname 'Черкова' -sAMAccountName 'svetlana.cherkova' -UserPrincipalName 'svetlana.cherkova@sync.rusagroeco.ru' -Path 'OU=Отдел администратавно-хозяйственного обеспечения,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Уборщик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел персонала и кадрового администрирования' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ekaterina.krasulina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Красулина Екатерина Сергеевна' -DisplayName 'Красулина Екатерина Сергеевна' -GivenName 'Екатерина' -Surname 'Красулина' -sAMAccountName 'ekaterina.krasulina' -UserPrincipalName 'ekaterina.krasulina@sync.rusagroeco.ru' -Path 'OU=Отдел персонала и кадрового администрирования,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Менеджер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба управления персоналом' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'polina.makarova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Макарова Полина Сергеевна' -DisplayName 'Макарова Полина Сергеевна' -GivenName 'Полина' -Surname 'Макарова' -sAMAccountName 'polina.makarova' -UserPrincipalName 'polina.makarova@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы управления персоналом' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valentina.sokolets'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Соколец Валентина Юрьевна' -DisplayName 'Соколец Валентина Юрьевна' -GivenName 'Валентина' -Surname 'Соколец' -sAMAccountName 'valentina.sokolets' -UserPrincipalName 'valentina.sokolets@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления оплаты труда и мотивации персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Операционная дирекция' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'timur.oshkhunov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ошхунов Тимур Хусенович' -DisplayName 'Ошхунов Тимур Хусенович' -GivenName 'Тимур' -Surname 'Ошхунов' -sAMAccountName 'timur.oshkhunov' -UserPrincipalName 'timur.oshkhunov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Операционный директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'pavel.ezhov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ежов Павел Викторович' -DisplayName 'Ежов Павел Викторович' -GivenName 'Павел' -Surname 'Ежов' -sAMAccountName 'pavel.ezhov' -UserPrincipalName 'pavel.ezhov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.pogoretskiy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Погорецкий Алексей Иванович' -DisplayName 'Погорецкий Алексей Иванович' -GivenName 'Алексей' -Surname 'Погорецкий' -sAMAccountName 'aleksey.pogoretskiy' -UserPrincipalName 'aleksey.pogoretskiy@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Технический директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.sviridov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Свиридов Иван Алексеевич' -DisplayName 'Свиридов Иван Алексеевич' -GivenName 'Иван' -Surname 'Свиридов' -sAMAccountName 'ivan.sviridov' -UserPrincipalName 'ivan.sviridov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном-аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'roman.proshlyakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Прошляков Роман Игоревич' -DisplayName 'Прошляков Роман Игоревич' -GivenName 'Роман' -Surname 'Прошляков' -sAMAccountName 'roman.proshlyakov' -UserPrincipalName 'roman.proshlyakov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель по животноводству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.grishin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гришин Евгений Игоревич' -DisplayName 'Гришин Евгений Игоревич' -GivenName 'Евгений' -Surname 'Гришин' -sAMAccountName 'evgeniy.grishin' -UserPrincipalName 'evgeniy.grishin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инженер по эксплуатации' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'danil.grechkin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гречкин Данил Андреевич' -DisplayName 'Гречкин Данил Андреевич' -GivenName 'Данил' -Surname 'Гречкин' -sAMAccountName 'danil.grechkin' -UserPrincipalName 'danil.grechkin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инженер по эксплуатации' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.malikova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Маликова Ирина Федоровна' -DisplayName 'Маликова Ирина Федоровна' -GivenName 'Ирина' -Surname 'Маликова' -sAMAccountName 'irina.malikova' -UserPrincipalName 'irina.malikova@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по охране труда' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.vasilkova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Василькова Татьяна Александровна' -DisplayName 'Василькова Татьяна Александровна' -GivenName 'Татьяна' -Surname 'Василькова' -sAMAccountName 'tatyana.vasilkova' -UserPrincipalName 'tatyana.vasilkova@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном-семеновод' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.grishin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гришин Евгений Игоревич' -DisplayName 'Гришин Евгений Игоревич' -GivenName 'Евгений' -Surname 'Гришин' -sAMAccountName 'evgeniy.grishin' -UserPrincipalName 'evgeniy.grishin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инженер-энергетик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'daniil.naumenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Науменко Даниил Владимирович' -DisplayName 'Науменко Даниил Владимирович' -GivenName 'Даниил' -Surname 'Науменко' -sAMAccountName 'daniil.naumenko' -UserPrincipalName 'daniil.naumenko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Помощник операционного директора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'polina.porubleva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Порублева Полина Константиновна' -DisplayName 'Порублева Полина Константиновна' -GivenName 'Полина' -Surname 'Порублева' -sAMAccountName 'polina.porubleva' -UserPrincipalName 'polina.porubleva@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя по животноводству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'akhmat.khasanov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Хасанов Ахмат Исламович' -DisplayName 'Хасанов Ахмат Исламович' -GivenName 'Ахмат' -Surname 'Хасанов' -sAMAccountName 'akhmat.khasanov' -UserPrincipalName 'akhmat.khasanov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель технического директора по строительству и ремонту' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по внутреннему контролю' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.akopov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Акопов Александр Рафикович' -DisplayName 'Акопов Александр Рафикович' -GivenName 'Александр' -Surname 'Акопов' -sAMAccountName 'aleksandr.akopov' -UserPrincipalName 'aleksandr.akopov@sync.rusagroeco.ru' -Path 'OU=Дирекция по внутреннему контролю,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист внутреннего контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alina.makhmudova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Махмудова Алина Магомедовна' -DisplayName 'Махмудова Алина Магомедовна' -GivenName 'Алина' -Surname 'Махмудова' -sAMAccountName 'alina.makhmudova' -UserPrincipalName 'alina.makhmudova@sync.rusagroeco.ru' -Path 'OU=Дирекция по внутреннему контролю,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления по внутреннему контролю в области земельных отношений' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба безопасности объектов и персонала' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuriy.syvachenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Сываченко Юрий Сергеевич' -DisplayName 'Сываченко Юрий Сергеевич' -GivenName 'Юрий' -Surname 'Сываченко' -sAMAccountName 'yuriy.syvachenko' -UserPrincipalName 'yuriy.syvachenko@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'akhat.bayramkulov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Байрамкулов Ахат Сапар-Алиевич' -DisplayName 'Байрамкулов Ахат Сапар-Алиевич' -GivenName 'Ахат' -Surname 'Байрамкулов' -sAMAccountName 'akhat.bayramkulov' -UserPrincipalName 'akhat.bayramkulov@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя службы безопасности объектов и персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.rudakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Рудаков Александр Владимирович' -DisplayName 'Рудаков Александр Владимирович' -GivenName 'Александр' -Surname 'Рудаков' -sAMAccountName 'aleksandr.rudakov' -UserPrincipalName 'aleksandr.rudakov@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы безопасности Ставропольского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба информационной безопасности' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.burlakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бурлаков Дмитрий Николаевич' -DisplayName 'Бурлаков Дмитрий Николаевич' -GivenName 'Дмитрий' -Surname 'Бурлаков' -sAMAccountName 'dmitriy.burlakov' -UserPrincipalName 'dmitriy.burlakov@sync.rusagroeco.ru' -Path 'OU=Служба информационной безопасности,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель ситуационного центра' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел научных разработок' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.malochkin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Малочкин Владимир Юрьевич' -DisplayName 'Малочкин Владимир Юрьевич' -GivenName 'Владимир' -Surname 'Малочкин' -sAMAccountName 'vladimir.malochkin' -UserPrincipalName 'vladimir.malochkin@sync.rusagroeco.ru' -Path 'OU=Отдел научных разработок,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по точному земледелию' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел информационных технологий' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vadim.yurchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Юрченко Вадим Алексеевич' -DisplayName 'Юрченко Вадим Алексеевич' -GivenName 'Вадим' -Surname 'Юрченко' -sAMAccountName 'vadim.yurchenko' -UserPrincipalName 'vadim.yurchenko@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.kirievskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кириевская Елена Сергеевна' -DisplayName 'Кириевская Елена Сергеевна' -GivenName 'Елена' -Surname 'Кириевская' -sAMAccountName 'elena.kirievskaya' -UserPrincipalName 'elena.kirievskaya@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления технического обеспечения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по правовым и корпоративным вопросам Ставропольского края' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'margarita.avedova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Аведова Маргарита Владимировна' -DisplayName 'Аведова Маргарита Владимировна' -GivenName 'Маргарита' -Surname 'Аведова' -sAMAccountName 'margarita.avedova' -UserPrincipalName 'margarita.avedova@sync.rusagroeco.ru' -Path 'OU=Отдел по правовым и корпоративным вопросам Ставропольского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valeriya.yugina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Югина Валерия Владимировна' -DisplayName 'Югина Валерия Владимировна' -GivenName 'Валерия' -Surname 'Югина' -sAMAccountName 'valeriya.yugina' -UserPrincipalName 'valeriya.yugina@sync.rusagroeco.ru' -Path 'OU=Отдел по правовым и корпоративным вопросам Ставропольского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела по правовым и корпоративным вопросам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по управлению недвижимым имуществом Ставропольского края' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nadezhda.popova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Попова Надежда Николаевна' -DisplayName 'Попова Надежда Николаевна' -GivenName 'Надежда' -Surname 'Попова' -sAMAccountName 'nadezhda.popova' -UserPrincipalName 'nadezhda.popova@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ставропольского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olga.akhtyrskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ахтырская Ольга Юрьевна' -DisplayName 'Ахтырская Ольга Юрьевна' -GivenName 'Ольга' -Surname 'Ахтырская' -sAMAccountName 'olga.akhtyrskaya' -UserPrincipalName 'olga.akhtyrskaya@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ставропольского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'regina.murtazalieva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Муртазалиева Регина Шафиуллаевна' -DisplayName 'Муртазалиева Регина Шафиуллаевна' -GivenName 'Регина' -Surname 'Муртазалиева' -sAMAccountName 'regina.murtazalieva' -UserPrincipalName 'regina.murtazalieva@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Ставропольского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела по управлению недвижимым имуществом Ставропольского края' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по экологической безопасности' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'bella.kagova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кагова Бэлла Мухамедовна' -DisplayName 'Кагова Бэлла Мухамедовна' -GivenName 'Бэлла' -Surname 'Кагова' -sAMAccountName 'bella.kagova' -UserPrincipalName 'bella.kagova@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба заказчика' -Path 'OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.gornich'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Горнич Александр Валерьевич' -DisplayName 'Горнич Александр Валерьевич' -GivenName 'Александр' -Surname 'Горнич' -sAMAccountName 'aleksandr.gornich' -UserPrincipalName 'aleksandr.gornich@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Ставропольское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий инженер по надзору за строительством' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по экономике и финансам' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.glukhoedov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Глухоедов Сергей Васильевич' -DisplayName 'Глухоедов Сергей Васильевич' -GivenName 'Сергей' -Surname 'Глухоедов' -sAMAccountName 'sergey.glukhoedov' -UserPrincipalName 'sergey.glukhoedov@sync.rusagroeco.ru' -Path 'OU=Дирекция по экономике и финансам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Финансовый директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.germanova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Германова Наталья Сергеевна' -DisplayName 'Германова Наталья Сергеевна' -GivenName 'Наталья' -Surname 'Германова' -sAMAccountName 'natalya.germanova' -UserPrincipalName 'natalya.germanova@sync.rusagroeco.ru' -Path 'OU=Дирекция по экономике и финансам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист казначейства' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел казначейских операций' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ekaterina.sidorova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Сидорова Екатерина Владимировна' -DisplayName 'Сидорова Екатерина Владимировна' -GivenName 'Екатерина' -Surname 'Сидорова' -sAMAccountName 'ekaterina.sidorova' -UserPrincipalName 'ekaterina.sidorova@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Старший казначей' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Краснодарское"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Служба контроллинга' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vitaliy.grebennikov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гребенников Виталий Васильевич' -DisplayName 'Гребенников Виталий Васильевич' -GivenName 'Виталий' -Surname 'Гребенников' -sAMAccountName 'vitaliy.grebennikov' -UserPrincipalName 'vitaliy.grebennikov@sync.rusagroeco.ru' -Path 'OU=Служба контроллинга,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы контроллинга' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'viktor.beloborodov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Белобородов Виктор Владимирович' -DisplayName 'Белобородов Виктор Владимирович' -GivenName 'Виктор' -Surname 'Белобородов' -sAMAccountName 'viktor.beloborodov' -UserPrincipalName 'viktor.beloborodov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vitaliy.krivonosov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кривоносов Виталий Иванович' -DisplayName 'Кривоносов Виталий Иванович' -GivenName 'Виталий' -Surname 'Кривоносов' -sAMAccountName 'vitaliy.krivonosov' -UserPrincipalName 'vitaliy.krivonosov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по проектам 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел информационных технологий' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.presnov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Преснов Алексей Владимирович' -DisplayName 'Преснов Алексей Владимирович' -GivenName 'Алексей' -Surname 'Преснов' -sAMAccountName 'aleksey.presnov' -UserPrincipalName 'aleksey.presnov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления технического обеспечения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел договорной и судебно-претензионной работы' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anna.fadeeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Фадеева Анна Владимировна' -DisplayName 'Фадеева Анна Владимировна' -GivenName 'Анна' -Surname 'Фадеева' -sAMAccountName 'anna.fadeeva' -UserPrincipalName 'anna.fadeeva@sync.rusagroeco.ru' -Path 'OU=Отдел договорной и судебно-претензионной работы,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Начальник юридической службы' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'oksana.trunina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Трунина Оксана Олеговна' -DisplayName 'Трунина Оксана Олеговна' -GivenName 'Оксана' -Surname 'Трунина' -sAMAccountName 'oksana.trunina' -UserPrincipalName 'oksana.trunina@sync.rusagroeco.ru' -Path 'OU=Отдел договорной и судебно-претензионной работы,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Юрисконсульт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел по управлению недвижимым имуществом Краснодарского края' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'oksana.obertas'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Обертас Оксана Сергеевна' -DisplayName 'Обертас Оксана Сергеевна' -GivenName 'Оксана' -Surname 'Обертас' -sAMAccountName 'oksana.obertas' -UserPrincipalName 'oksana.obertas@sync.rusagroeco.ru' -Path 'OU=Отдел по управлению недвижимым имуществом Краснодарского края,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела по управлению недвижимым имуществом Краснодарского края' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по развитию земельного банка' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nikolay.savchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Савченко Николай Павлович' -DisplayName 'Савченко Николай Павлович' -GivenName 'Николай' -Surname 'Савченко' -sAMAccountName 'nikolay.savchenko' -UserPrincipalName 'nikolay.savchenko@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Операционная дирекция' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.panchikhin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Панчихин Сергей Викторович' -DisplayName 'Панчихин Сергей Викторович' -GivenName 'Сергей' -Surname 'Панчихин' -sAMAccountName 'sergey.panchikhin' -UserPrincipalName 'sergey.panchikhin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Операционный директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.vorona'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ворона Владимир Борисович' -DisplayName 'Ворона Владимир Борисович' -GivenName 'Владимир' -Surname 'Ворона' -sAMAccountName 'vladimir.vorona' -UserPrincipalName 'vladimir.vorona@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Операционная дирекция' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.ostroverkhov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Островерхов Александр Александрович' -DisplayName 'Островерхов Александр Александрович' -GivenName 'Александр' -Surname 'Островерхов' -sAMAccountName 'aleksandr.ostroverkhov' -UserPrincipalName 'aleksandr.ostroverkhov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по производству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.leshko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лешко Александр Николаевич' -DisplayName 'Лешко Александр Николаевич' -GivenName 'Александр' -Surname 'Лешко' -sAMAccountName 'aleksandr.leshko' -UserPrincipalName 'aleksandr.leshko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный агроном-семеновод' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'artem.popov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Попов Артем Сергеевич' -DisplayName 'Попов Артем Сергеевич' -GivenName 'Артем' -Surname 'Попов' -sAMAccountName 'artem.popov' -UserPrincipalName 'artem.popov@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Технический директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'oksana.orlova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Орлова Оксана Григорьевна' -DisplayName 'Орлова Оксана Григорьевна' -GivenName 'Оксана' -Surname 'Орлова' -sAMAccountName 'oksana.orlova' -UserPrincipalName 'oksana.orlova@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Офис-менеджер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.didenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Диденко Владимир Андреевич' -DisplayName 'Диденко Владимир Андреевич' -GivenName 'Владимир' -Surname 'Диденко' -sAMAccountName 'vladimir.didenko' -UserPrincipalName 'vladimir.didenko@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Агроном-аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'semen.anikin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Аникин Семён Алексеевич' -DisplayName 'Аникин Семён Алексеевич' -GivenName 'Семён' -Surname 'Аникин' -sAMAccountName 'semen.anikin' -UserPrincipalName 'semen.anikin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный инженер растениеводческого направления' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба управления персоналом' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.tsegelskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Цегельская Ирина Анатольевна' -DisplayName 'Цегельская Ирина Анатольевна' -GivenName 'Ирина' -Surname 'Цегельская' -sAMAccountName 'irina.tsegelskaya' -UserPrincipalName 'irina.tsegelskaya@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы управления персоналом' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.tereshchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Терещенко Елена Владимировна' -DisplayName 'Терещенко Елена Владимировна' -GivenName 'Елена' -Surname 'Терещенко' -sAMAccountName 'elena.tereshchenko' -UserPrincipalName 'elena.tereshchenko@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления оплаты труда и мотивации персонала' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'svetlana.alivantseva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Аливанцева Светлана Павловна' -DisplayName 'Аливанцева Светлана Павловна' -GivenName 'Светлана' -Surname 'Аливанцева' -sAMAccountName 'svetlana.alivantseva' -UserPrincipalName 'svetlana.alivantseva@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления кадрового администрирования' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба безопасности объектов и персонала' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vitaliy.kravchenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кравченко Виталий Львович' -DisplayName 'Кравченко Виталий Львович' -GivenName 'Виталий' -Surname 'Кравченко' -sAMAccountName 'vitaliy.kravchenko' -UserPrincipalName 'vitaliy.kravchenko@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vadim.sayapin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Саяпин Вадим Викторович' -DisplayName 'Саяпин Вадим Викторович' -GivenName 'Вадим' -Surname 'Саяпин' -sAMAccountName 'vadim.sayapin' -UserPrincipalName 'vadim.sayapin@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы безопасности Краснодарского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по экологической безопасности' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'irina.shvaleva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Швалева Ирина Васильевна' -DisplayName 'Швалева Ирина Васильевна' -GivenName 'Ирина' -Surname 'Швалева' -sAMAccountName 'irina.shvaleva' -UserPrincipalName 'irina.shvaleva@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба заказчика' -Path 'OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.timofeev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Тимофеев Иван Михайлович' -DisplayName 'Тимофеев Иван Михайлович' -GivenName 'Иван' -Surname 'Тимофеев' -sAMAccountName 'ivan.timofeev' -UserPrincipalName 'ivan.timofeev@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Краснодарское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий инженер по надзору за строительством' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел мониторинга' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alina.koryagina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Корягина Алина Александровна' -DisplayName 'Корягина Алина Александровна' -GivenName 'Алина' -Surname 'Корягина' -sAMAccountName 'alina.koryagina' -UserPrincipalName 'alina.koryagina@sync.rusagroeco.ru' -Path 'OU=Отдел мониторинга,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Диспетчер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'inna.repina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Репина Инна Игоревна' -DisplayName 'Репина Инна Игоревна' -GivenName 'Инна' -Surname 'Репина' -sAMAccountName 'inna.repina' -UserPrincipalName 'inna.repina@sync.rusagroeco.ru' -Path 'OU=Отдел мониторинга,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Диспетчер' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.korotkikh'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Коротких Александр Николаевич' -DisplayName 'Коротких Александр Николаевич' -GivenName 'Александр' -Surname 'Коротких' -sAMAccountName 'aleksandr.korotkikh' -UserPrincipalName 'aleksandr.korotkikh@sync.rusagroeco.ru' -Path 'OU=Отдел мониторинга,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела мониторинга' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Нижегородское"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Отдел мониторинга' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'kristina.ryabinina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Рябинина Кристина Алексеевна' -DisplayName 'Рябинина Кристина Алексеевна' -GivenName 'Кристина' -Surname 'Рябинина' -sAMAccountName 'kristina.ryabinina' -UserPrincipalName 'kristina.ryabinina@sync.rusagroeco.ru' -Path 'OU=Отдел мониторинга,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по мониторигу' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел информационных технологий' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mikhail.chadin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Чадин Михаил Алексеевич' -DisplayName 'Чадин Михаил Алексеевич' -GivenName 'Михаил' -Surname 'Чадин' -sAMAccountName 'mikhail.chadin' -UserPrincipalName 'mikhail.chadin@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ilya.zaykov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Зайков Илья Михайлович' -DisplayName 'Зайков Илья Михайлович' -GivenName 'Илья' -Surname 'Зайков' -sAMAccountName 'ilya.zaykov' -UserPrincipalName 'ilya.zaykov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий программист 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'kirill.vetrov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ветров Кирилл Владимирович' -DisplayName 'Ветров Кирилл Владимирович' -GivenName 'Кирилл' -Surname 'Ветров' -sAMAccountName 'kirill.vetrov' -UserPrincipalName 'kirill.vetrov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Программист 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.chulichkov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Чуличков Владимир Михайлович' -DisplayName 'Чуличков Владимир Михайлович' -GivenName 'Владимир' -Surname 'Чуличков' -sAMAccountName 'vladimir.chulichkov' -UserPrincipalName 'vladimir.chulichkov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anton.dulepov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дулепов Антон Вадимович' -DisplayName 'Дулепов Антон Вадимович' -GivenName 'Антон' -Surname 'Дулепов' -sAMAccountName 'anton.dulepov' -UserPrincipalName 'anton.dulepov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления технического обеспечения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.panin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Панин Александр Владимирович' -DisplayName 'Панин Александр Владимирович' -GivenName 'Александр' -Surname 'Панин' -sAMAccountName 'aleksandr.panin' -UserPrincipalName 'aleksandr.panin@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Операционный директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Операционная дирекция' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.khomutetskiy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Хомутецкий Дмитрий Николаевич' -DisplayName 'Хомутецкий Дмитрий Николаевич' -GivenName 'Дмитрий' -Surname 'Хомутецкий' -sAMAccountName 'dmitriy.khomutetskiy' -UserPrincipalName 'dmitriy.khomutetskiy@sync.rusagroeco.ru' -Path 'OU=Операционная дирекция,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Технический директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба безопасности объектов и персонала' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'andrey.butenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бутенко Андрей Юрьевич' -DisplayName 'Бутенко Андрей Юрьевич' -GivenName 'Андрей' -Surname 'Бутенко' -sAMAccountName 'andrey.butenko' -UserPrincipalName 'andrey.butenko@sync.rusagroeco.ru' -Path 'OU=Служба безопасности объектов и персонала,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель руководителя службы безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по экологической безопасности' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'natalya.rodina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Родина Наталья Сергеевна' -DisplayName 'Родина Наталья Сергеевна' -GivenName 'Наталья' -Surname 'Родина' -sAMAccountName 'natalya.rodina' -UserPrincipalName 'natalya.rodina@sync.rusagroeco.ru' -Path 'OU=Дирекция по экологической безопасности,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по экологической безопасности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба управления персоналом' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olga.cherenovskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Череновская Ольга Сергеевна' -DisplayName 'Череновская Ольга Сергеевна' -GivenName 'Ольга' -Surname 'Череновская' -sAMAccountName 'olga.cherenovskaya' -UserPrincipalName 'olga.cherenovskaya@sync.rusagroeco.ru' -Path 'OU=Служба управления персоналом,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель службы управления персоналом' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба акционерно-инспекторского контроля' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'azret.uzdenov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Узденов Азрет Алиевич' -DisplayName 'Узденов Азрет Алиевич' -GivenName 'Азрет' -Surname 'Узденов' -sAMAccountName 'azret.uzdenov' -UserPrincipalName 'azret.uzdenov@sync.rusagroeco.ru' -Path 'OU=Служба акционерно-инспекторского контроля,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Старший инспектор службы акционерно-инспекторского контроля' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба заказчика' -Path 'OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.polyakov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Поляков Александр Викторович' -DisplayName 'Поляков Александр Викторович' -GivenName 'Александр' -Surname 'Поляков' -sAMAccountName 'aleksandr.polyakov' -UserPrincipalName 'aleksandr.polyakov@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Нижегородское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий инженер по надзору за строительством' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'ОСП "Воронежское"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
try { New-ADOrganizationalUnit -Name 'Отдел казначейских операций' -Path 'OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olga.lazareva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лазарева Ольга Ивановна' -DisplayName 'Лазарева Ольга Ивановна' -GivenName 'Ольга' -Surname 'Лазарева' -sAMAccountName 'olga.lazareva' -UserPrincipalName 'olga.lazareva@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'yuliya.koroleva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Королева Юлия Александровна' -DisplayName 'Королева Юлия Александровна' -GivenName 'Юлия' -Surname 'Королева' -sAMAccountName 'yuliya.koroleva' -UserPrincipalName 'yuliya.koroleva@sync.rusagroeco.ru' -Path 'OU=Отдел казначейских операций,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления казначейский операция Воронежского кластера' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел кредитования и государственной поддержки' -Path 'OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'galina.dobrovolskaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Добровольская Галина Сергеевна' -DisplayName 'Добровольская Галина Сергеевна' -GivenName 'Галина' -Surname 'Добровольская' -sAMAccountName 'galina.dobrovolskaya' -UserPrincipalName 'galina.dobrovolskaya@sync.rusagroeco.ru' -Path 'OU=Отдел кредитования и государственной поддержки,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.odinokaya'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Одинокая Татьяна Анатольевна' -DisplayName 'Одинокая Татьяна Анатольевна' -GivenName 'Татьяна' -Surname 'Одинокая' -sAMAccountName 'tatyana.odinokaya' -UserPrincipalName 'tatyana.odinokaya@sync.rusagroeco.ru' -Path 'OU=Отдел кредитования и государственной поддержки,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по развитию земельного банка' -Path 'OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mikhail.makashov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Макашов Михаил Николаевич' -DisplayName 'Макашов Михаил Николаевич' -GivenName 'Михаил' -Surname 'Макашов' -sAMAccountName 'mikhail.makashov' -UserPrincipalName 'mikhail.makashov@sync.rusagroeco.ru' -Path 'OU=Дирекция по развитию земельного банка,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Служба заказчика' -Path 'OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.afanasenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Афанасенко Евгений Владимирович' -DisplayName 'Афанасенко Евгений Владимирович' -GivenName 'Евгений' -Surname 'Афанасенко' -sAMAccountName 'evgeniy.afanasenko' -UserPrincipalName 'evgeniy.afanasenko@sync.rusagroeco.ru' -Path 'OU=Служба заказчика,OU=ОСП \"Воронежское\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий инженер по надзору за строительством' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Акционерное общество "Агрохолдинг"Просторы"' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'boris.dyshlyuk'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дышлюк Борис Александрович' -DisplayName 'Дышлюк Борис Александрович' -GivenName 'Борис' -Surname 'Дышлюк' -sAMAccountName 'boris.dyshlyuk' -UserPrincipalName 'boris.dyshlyuk@sync.rusagroeco.ru' -Path 'OU=Акционерное общество \"Агрохолдинг\"Просторы\",OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Генеральный Директор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление по экономике и финансам' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'tatyana.gavrilenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гавриленко Татьяна Яковлевна' -DisplayName 'Гавриленко Татьяна Яковлевна' -GivenName 'Татьяна' -Surname 'Гавриленко' -sAMAccountName 'tatyana.gavrilenko' -UserPrincipalName 'tatyana.gavrilenko@sync.rusagroeco.ru' -Path 'OU=Управление по экономике и финансам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный бухгалтер агрохолдинга' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по корпоративным финансам' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.titov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Титов Сергей Александрович' -DisplayName 'Титов Сергей Александрович' -GivenName 'Сергей' -Surname 'Титов' -sAMAccountName 'sergey.titov' -UserPrincipalName 'sergey.titov@sync.rusagroeco.ru' -Path 'OU=Дирекция по корпоративным финансам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по корпоративным финансам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Отдел финансового моделирования' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mark.goldenberg'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Гольденберг Марк Ильич' -DisplayName 'Гольденберг Марк Ильич' -GivenName 'Марк' -Surname 'Гольденберг' -sAMAccountName 'mark.goldenberg' -UserPrincipalName 'mark.goldenberg@sync.rusagroeco.ru' -Path 'OU=Отдел финансового моделирования,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель отдела финансового моделирования' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление по информационным технологиям и научным разработкам' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'olga.borisenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Борисенко Ольга Николаевна' -DisplayName 'Борисенко Ольга Николаевна' -GivenName 'Ольга' -Surname 'Борисенко' -sAMAccountName 'olga.borisenko' -UserPrincipalName 'olga.borisenko@sync.rusagroeco.ru' -Path 'OU=Управление по информационным технологиям и научным разработкам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vladimir.borisov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Борисов Владимир Борисович' -DisplayName 'Борисов Владимир Борисович' -GivenName 'Владимир' -Surname 'Борисов' -sAMAccountName 'vladimir.borisov' -UserPrincipalName 'vladimir.borisov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Системный администратор' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.ermolaev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ермолаев Александр Григорьевич' -DisplayName 'Ермолаев Александр Григорьевич' -GivenName 'Александр' -Surname 'Ермолаев' -sAMAccountName 'aleksandr.ermolaev' -UserPrincipalName 'aleksandr.ermolaev@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий программист 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.burkov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бурков Алексей Борисович' -DisplayName 'Бурков Алексей Борисович' -GivenName 'Алексей' -Surname 'Бурков' -sAMAccountName 'aleksey.burkov' -UserPrincipalName 'aleksey.burkov@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель направления 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.kovalenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Коваленко Елена Раифовна' -DisplayName 'Коваленко Елена Раифовна' -GivenName 'Елена' -Surname 'Коваленко' -sAMAccountName 'elena.kovalenko' -UserPrincipalName 'elena.kovalenko@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Методолог 1C' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'larisa.pozdnyakova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Позднякова Лариса Рафаиловна' -DisplayName 'Позднякова Лариса Рафаиловна' -GivenName 'Лариса' -Surname 'Позднякова' -sAMAccountName 'larisa.pozdnyakova' -UserPrincipalName 'larisa.pozdnyakova@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Консультант 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ekaterina.zaykova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Зайкова Екатерина Александровна' -DisplayName 'Зайкова Екатерина Александровна' -GivenName 'Екатерина' -Surname 'Зайкова' -sAMAccountName 'ekaterina.zaykova' -UserPrincipalName 'ekaterina.zaykova@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Консультант 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nataliya.ryl'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Рыль Наталия Владимировна' -DisplayName 'Рыль Наталия Владимировна' -GivenName 'Наталия' -Surname 'Рыль' -sAMAccountName 'nataliya.ryl' -UserPrincipalName 'nataliya.ryl@sync.rusagroeco.ru' -Path 'OU=Отдел информационных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Программист 1С' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по стратегии' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.vinnikova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Винникова Дарья Дмитриевна' -DisplayName 'Винникова Дарья Дмитриевна' -GivenName 'Дарья' -Surname 'Винникова' -sAMAccountName 'darya.vinnikova' -UserPrincipalName 'darya.vinnikova@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель генерального директора по стратегии' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valeriy.kong'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Конг Валерий Чивинович' -DisplayName 'Конг Валерий Чивинович' -GivenName 'Валерий' -Surname 'Конг' -sAMAccountName 'valeriy.kong' -UserPrincipalName 'valeriy.kong@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Финансовый аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.darmina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Дармина Дарья Ивановна' -DisplayName 'Дармина Дарья Ивановна' -GivenName 'Дарья' -Surname 'Дармина' -sAMAccountName 'darya.darmina' -UserPrincipalName 'darya.darmina@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'regina.bashirova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Баширова Регина Венеровна' -DisplayName 'Баширова Регина Венеровна' -GivenName 'Регина' -Surname 'Баширова' -sAMAccountName 'regina.bashirova' -UserPrincipalName 'regina.bashirova@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Инвестиционный аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'kirill.kondrashov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кондрашов Кирилл Евгеньевич' -DisplayName 'Кондрашов Кирилл Евгеньевич' -GivenName 'Кирилл' -Surname 'Кондрашов' -sAMAccountName 'kirill.kondrashov' -UserPrincipalName 'kirill.kondrashov@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий специалист по работе с государственными органами' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'valeriya.alekseeva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Алексеева Валерия Александровна' -DisplayName 'Алексеева Валерия Александровна' -GivenName 'Валерия' -Surname 'Алексеева' -sAMAccountName 'valeriya.alekseeva' -UserPrincipalName 'valeriya.alekseeva@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий финансовый аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.vinnikova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Винникова Дарья Дмитриевна' -DisplayName 'Винникова Дарья Дмитриевна' -GivenName 'Дарья' -Surname 'Винникова' -sAMAccountName 'darya.vinnikova' -UserPrincipalName 'darya.vinnikova@sync.rusagroeco.ru' -Path 'OU=Дирекция по стратегии,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Стажер-аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по капитальному строительству' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksandr.shpilev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Шпилев Александр Петрович' -DisplayName 'Шпилев Александр Петрович' -GivenName 'Александр' -Surname 'Шпилев' -sAMAccountName 'aleksandr.shpilev' -UserPrincipalName 'aleksandr.shpilev@sync.rusagroeco.ru' -Path 'OU=Дирекция по капитальному строительству,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по капитальному строительству' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'evgeniy.sukhorukov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Сухоруков Евгений Александрович' -DisplayName 'Сухоруков Евгений Александрович' -GivenName 'Евгений' -Surname 'Сухоруков' -sAMAccountName 'evgeniy.sukhorukov' -UserPrincipalName 'evgeniy.sukhorukov@sync.rusagroeco.ru' -Path 'OU=Дирекция по капитальному строительству,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист технического надзора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aynur.khusnutdinov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Хуснутдинов Айнур Амирович' -DisplayName 'Хуснутдинов Айнур Амирович' -GivenName 'Айнур' -Surname 'Хуснутдинов' -sAMAccountName 'aynur.khusnutdinov' -UserPrincipalName 'aynur.khusnutdinov@sync.rusagroeco.ru' -Path 'OU=Дирекция по капитальному строительству,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист технического надзора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'andrey.alekhin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Алехин Андрей Валерьянович' -DisplayName 'Алехин Андрей Валерьянович' -GivenName 'Андрей' -Surname 'Алехин' -sAMAccountName 'andrey.alekhin' -UserPrincipalName 'andrey.alekhin@sync.rusagroeco.ru' -Path 'OU=Дирекция по капитальному строительству,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Сметчик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'margarita.brezhneva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Брежнева Маргарита Сергеевна' -DisplayName 'Брежнева Маргарита Сергеевна' -GivenName 'Маргарита' -Surname 'Брежнева' -sAMAccountName 'margarita.brezhneva' -UserPrincipalName 'margarita.brezhneva@sync.rusagroeco.ru' -Path 'OU=Дирекция по капитальному строительству,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий сметчик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по агроскаутингу' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vasiliy.luchkov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лучков Василий Александрович' -DisplayName 'Лучков Василий Александрович' -GivenName 'Василий' -Surname 'Лучков' -sAMAccountName 'vasiliy.luchkov' -UserPrincipalName 'vasiliy.luchkov@sync.rusagroeco.ru' -Path 'OU=Дирекция по агроскаутингу,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по агроскаутингу' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по маркетингу' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nataliya.malkiel'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Малкиель Наталия Яковлевна' -DisplayName 'Малкиель Наталия Яковлевна' -GivenName 'Наталия' -Surname 'Малкиель' -sAMAccountName 'nataliya.malkiel' -UserPrincipalName 'nataliya.malkiel@sync.rusagroeco.ru' -Path 'OU=Дирекция по маркетингу,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по маркетингу' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nadezhda.bulatova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Булатова Надежда Юрьевна' -DisplayName 'Булатова Надежда Юрьевна' -GivenName 'Надежда' -Surname 'Булатова' -sAMAccountName 'nadezhda.bulatova' -UserPrincipalName 'nadezhda.bulatova@sync.rusagroeco.ru' -Path 'OU=Дирекция по маркетингу,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по внешним коммуникациям' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по управлению проектами и бизнес-процессами' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.ignatov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Игнатов Дмитрий Александрович' -DisplayName 'Игнатов Дмитрий Александрович' -GivenName 'Дмитрий' -Surname 'Игнатов' -sAMAccountName 'dmitriy.ignatov' -UserPrincipalName 'dmitriy.ignatov@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению проектами и бизнес-процессами,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель проектов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anton.mantorov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Манторов Антон Сергеевич' -DisplayName 'Манторов Антон Сергеевич' -GivenName 'Антон' -Surname 'Манторов' -sAMAccountName 'anton.mantorov' -UserPrincipalName 'anton.mantorov@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению проектами и бизнес-процессами,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный менеджер по оптимизации бизнес-процессов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anzor.dzhabrailov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Джабраилов Анзор Аюбович' -DisplayName 'Джабраилов Анзор Аюбович' -GivenName 'Анзор' -Surname 'Джабраилов' -sAMAccountName 'anzor.dzhabrailov' -UserPrincipalName 'anzor.dzhabrailov@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению проектами и бизнес-процессами,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по управлению проектами и бизнес-процессами' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ilyas.tsakaev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Цакаев Ильяс Русланович' -DisplayName 'Цакаев Ильяс Русланович' -GivenName 'Ильяс' -Surname 'Цакаев' -sAMAccountName 'ilyas.tsakaev' -UserPrincipalName 'ilyas.tsakaev@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению проектами и бизнес-процессами,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный менеджер по управлению проектами и бизнес-процессами' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'alena.tolmacheva'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Толмачева Алёна Ивановна' -DisplayName 'Толмачева Алёна Ивановна' -GivenName 'Алёна' -Surname 'Толмачева' -sAMAccountName 'alena.tolmacheva' -UserPrincipalName 'alena.tolmacheva@sync.rusagroeco.ru' -Path 'OU=Дирекция по управлению проектами и бизнес-процессами,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный аналитик проектов' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Аппарат генерального директора' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.samigullina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Самигуллина Елена Рафаиловна' -DisplayName 'Самигуллина Елена Рафаиловна' -GivenName 'Елена' -Surname 'Самигуллина' -sAMAccountName 'elena.samigullina' -UserPrincipalName 'elena.samigullina@sync.rusagroeco.ru' -Path 'OU=Аппарат генерального директора,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель аппарата' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nadezhda.zobnina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Зобнина Надежда Александровна' -DisplayName 'Зобнина Надежда Александровна' -GivenName 'Надежда' -Surname 'Зобнина' -sAMAccountName 'nadezhda.zobnina' -UserPrincipalName 'nadezhda.zobnina@sync.rusagroeco.ru' -Path 'OU=Аппарат генерального директора,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Делопроизводитель' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.zobnin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Зобнин Алексей Анатольевич' -DisplayName 'Зобнин Алексей Анатольевич' -GivenName 'Алексей' -Surname 'Зобнин' -sAMAccountName 'aleksey.zobnin' -UserPrincipalName 'aleksey.zobnin@sync.rusagroeco.ru' -Path 'OU=Аппарат генерального директора,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mariya.mikhaylova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Михайлова Мария Львовна' -DisplayName 'Михайлова Мария Львовна' -GivenName 'Мария' -Surname 'Михайлова' -sAMAccountName 'mariya.mikhaylova' -UserPrincipalName 'mariya.mikhaylova@sync.rusagroeco.ru' -Path 'OU=Аппарат генерального директора,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Референт' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'aleksey.plaskov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Пласков Алексей Александрович' -DisplayName 'Пласков Алексей Александрович' -GivenName 'Алексей' -Surname 'Пласков' -sAMAccountName 'aleksey.plaskov' -UserPrincipalName 'aleksey.plaskov@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Первый заместитель генерального директора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'konstantin.kushnarev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Кушнарев Константин Федорович' -DisplayName 'Кушнарев Константин Федорович' -GivenName 'Константин' -Surname 'Кушнарев' -sAMAccountName 'konstantin.kushnarev' -UserPrincipalName 'konstantin.kushnarev@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Советник' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'rustam.uzdenov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Узденов Рустам Альбертович' -DisplayName 'Узденов Рустам Альбертович' -GivenName 'Рустам' -Surname 'Узденов' -sAMAccountName 'rustam.uzdenov' -UserPrincipalName 'rustam.uzdenov@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Советник' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'mikhail.samarin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Самарин Михаил Ильич' -DisplayName 'Самарин Михаил Ильич' -GivenName 'Михаил' -Surname 'Самарин' -sAMAccountName 'mikhail.samarin' -UserPrincipalName 'mikhail.samarin@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Советник' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'andrey.lutchin'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Лутчин Андрей Михайлович' -DisplayName 'Лутчин Андрей Михайлович' -GivenName 'Андрей' -Surname 'Лутчин' -sAMAccountName 'andrey.lutchin' -UserPrincipalName 'andrey.lutchin@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по экономической эффективности' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'ivan.yuzefovich'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Юзефович Иван Михайлович' -DisplayName 'Юзефович Иван Михайлович' -GivenName 'Иван' -Surname 'Юзефович' -sAMAccountName 'ivan.yuzefovich' -UserPrincipalName 'ivan.yuzefovich@sync.rusagroeco.ru' -Path 'OU=Управление,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Советник генерального директора' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Центр прикладных генетических и репродуктивных технологий' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'elena.korochkina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Корочкина Елена Александровна' -DisplayName 'Корочкина Елена Александровна' -GivenName 'Елена' -Surname 'Корочкина' -sAMAccountName 'elena.korochkina' -UserPrincipalName 'elena.korochkina@sync.rusagroeco.ru' -Path 'OU=Центр прикладных генетических и репродуктивных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Руководитель подразделения' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'vadim.olontsev'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Олонцев Вадим Акимович' -DisplayName 'Олонцев Вадим Акимович' -GivenName 'Вадим' -Surname 'Олонцев' -sAMAccountName 'vadim.olontsev' -UserPrincipalName 'vadim.olontsev@sync.rusagroeco.ru' -Path 'OU=Центр прикладных генетических и репродуктивных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по селекционно-племенной работе' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'angelina.belikova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Беликова Ангелина Олеговна' -DisplayName 'Беликова Ангелина Олеговна' -GivenName 'Ангелина' -Surname 'Беликова' -sAMAccountName 'angelina.belikova' -UserPrincipalName 'angelina.belikova@sync.rusagroeco.ru' -Path 'OU=Центр прикладных генетических и репродуктивных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Биоинформатик-аналитик' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
$user = Get-ADUser -Filter "sAMAccountName -eq 'darya.krylova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Крылова Дарья Дмитриевна' -DisplayName 'Крылова Дарья Дмитриевна' -GivenName 'Дарья' -Surname 'Крылова' -sAMAccountName 'darya.krylova' -UserPrincipalName 'darya.krylova@sync.rusagroeco.ru' -Path 'OU=Центр прикладных генетических и репродуктивных технологий,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Специалист по генотипированию' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Управление научных разработок и цифровизации' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'sergey.tkachenko'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Ткаченко Сергей Петрович' -DisplayName 'Ткаченко Сергей Петрович' -GivenName 'Сергей' -Surname 'Ткаченко' -sAMAccountName 'sergey.tkachenko' -UserPrincipalName 'sergey.tkachenko@sync.rusagroeco.ru' -Path 'OU=Управление научных разработок и цифровизации,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Заместитель генерального директора по научным разработкам и цифровизации' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по информационным технологиям' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.zemskov'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Земсков Дмитрий Анатольевич' -DisplayName 'Земсков Дмитрий Анатольевич' -GivenName 'Дмитрий' -Surname 'Земсков' -sAMAccountName 'dmitriy.zemskov' -UserPrincipalName 'dmitriy.zemskov@sync.rusagroeco.ru' -Path 'OU=Дирекция по информационным технологиям,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по информационным технологиям' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по специальным проектам' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'dmitriy.borodovskiy'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Бородовский Дмитрий' -DisplayName 'Бородовский Дмитрий' -GivenName 'Дмитрий' -Surname 'Бородовский' -sAMAccountName 'dmitriy.borodovskiy' -UserPrincipalName 'dmitriy.borodovskiy@sync.rusagroeco.ru' -Path 'OU=Дирекция по специальным проектам,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Директор по специальным проектам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция по кадровому администрированию' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'nataliya.kharina'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Харина Наталия Владимировна' -DisplayName 'Харина Наталия Владимировна' -GivenName 'Наталия' -Surname 'Харина' -sAMAccountName 'nataliya.kharina' -UserPrincipalName 'nataliya.kharina@sync.rusagroeco.ru' -Path 'OU=Дирекция по кадровому администрированию,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Ведущий менеджер по кадровому администрированию и воинскому учету' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}
try { New-ADOrganizationalUnit -Name 'Дирекция правовой и корпоративной работы' -Path 'OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -ErrorAction Stop } catch {}
$user = Get-ADUser -Filter "sAMAccountName -eq 'anastasiya.shiyanova'" -ErrorAction SilentlyContinue
if (-not $user) {
    New-ADUser -Name 'Шиянова Анастасия Сергеевна' -DisplayName 'Шиянова Анастасия Сергеевна' -GivenName 'Анастасия' -Surname 'Шиянова' -sAMAccountName 'anastasiya.shiyanova' -UserPrincipalName 'anastasiya.shiyanova@sync.rusagroeco.ru' -Path 'OU=Дирекция правовой и корпоративной работы,OU=B24_Structure,DC=sync,DC=rusagroeco,DC=ru' -Title 'Главный юрисконсульт дирекции по правовым и корпоративным вопросам' -AccountPassword (ConvertTo-SecureString 'ChangeMe2026!' -AsPlainText -Force) -Enabled $true
}