Import-Module ActiveDirectory
$log = @()
function Set-Hierarchy {
  param($UserFIO, $ManagerFIO, $Title)
  try {
    $u = Get-ADUser -Filter "DisplayName -eq '$UserFIO'" -ErrorAction SilentlyContinue
    if (-not $u) { return }
    if ($Title) { Set-ADUser -Identity $u -Title $Title }
    if ($ManagerFIO) {
      $mgr = Get-ADUser -Filter "DisplayName -eq '$ManagerFIO'" -ErrorAction SilentlyContinue
      if ($mgr) { Set-ADUser -Identity $u -Manager $mgr.DistinguishedName }
    }
    Write-Host "SUCCESS: $UserFIO configured." -ForegroundColor Green
  } catch { Write-Host "ERROR: $UserFIO failed." -ForegroundColor Red }
}

Set-Hierarchy -UserFIO 'Дышлюк Борис Александрович' -ManagerFIO '' -Title 'Генеральный директор / Куратор блока ЭиФ'
Set-Hierarchy -UserFIO 'Градинарова Маргарита Александровна' -ManagerFIO 'Дышлюк Борис Александрович' -Title 'Заместитель генерального директора по экономике и финансам'
Set-Hierarchy -UserFIO 'Воробьева Елена Александровна' -ManagerFIO 'Градинарова Маргарита Александровна' -Title 'Директор по казначейским операциям'
Set-Hierarchy -UserFIO 'Титов Сергей Александрович' -ManagerFIO 'Градинарова Маргарита Александровна' -Title 'Директор по корпоративным финансам'
Set-Hierarchy -UserFIO 'Гавриленко Татьяна Яковлевна' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Глухоедов Сергей Васильевич' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Тлакадугов Залим Заурбекович' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Гребенников Виталий Васильевич' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Чертова Оксана Федоровна' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Донова Мария Михайловна' -ManagerFIO 'Воробьева Елена Александровна' -Title 'Руководитель отдела казначейских операций (Юг)'
Set-Hierarchy -UserFIO 'Королева Юлия Александровна' -ManagerFIO 'Воробьева Елена Александровна' -Title ''
Set-Hierarchy -UserFIO 'Сизова В.В.' -ManagerFIO 'Воробьева Елена Александровна' -Title ''
Set-Hierarchy -UserFIO 'Гольденберг Марк Ильич' -ManagerFIO 'Титов Сергей Александрович' -Title ''
Set-Hierarchy -UserFIO 'Левченко Петр Иванович' -ManagerFIO 'Титов Сергей Александрович' -Title ''
Set-Hierarchy -UserFIO 'Репа Максим Евгеньевич' -ManagerFIO 'Титов Сергей Александрович' -Title ''
Set-Hierarchy -UserFIO 'Плетнева Наталья Викторовна' -ManagerFIO 'Градинарова Маргарита Александровна' -Title 'Руководитель группы бухгалтерского учета и отчетности'
Set-Hierarchy -UserFIO 'Долгоносова Людмила Сергеевна' -ManagerFIO 'Градинарова Маргарита Александровна' -Title 'Руководитель группы контроллинга'
Set-Hierarchy -UserFIO 'Зевакин Василий Владимирович' -ManagerFIO 'Градинарова Маргарита Александровна' -Title ''
Set-Hierarchy -UserFIO 'Бирюкова Алина Андреевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Дурнева Валерия Александровна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Зубкова Лариса Михайловна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Лесникова Юлия Сергеевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Морозова Екатерина Александровна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Рахманина Наталья Васильевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Секнина Валерия Александровна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Сорокина Анна Юрьевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Бахмацкая Светлана Анатольевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Мищенко Юлия Геннадьевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Трайзе Полина Сергеевна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Черникова Марина Викторовна' -ManagerFIO 'Донова Мария Михайловна' -Title ''
Set-Hierarchy -UserFIO 'Гейкина Ирина Ильинична' -ManagerFIO 'Левченко Петр Иванович' -Title ''
Set-Hierarchy -UserFIO 'Ильяшенко Светлана Александровна' -ManagerFIO 'Левченко Петр Иванович' -Title ''
Set-Hierarchy -UserFIO 'Одинокая Татьяна Анатольевна' -ManagerFIO 'Левченко Петр Иванович' -Title ''
Set-Hierarchy -UserFIO 'Бежанова Татьяна Ивановна' -ManagerFIO 'Плетнева Наталья Викторовна' -Title ''
Set-Hierarchy -UserFIO 'Шрамко Галина Николаевна' -ManagerFIO 'Плетнева Наталья Викторовна' -Title ''
Set-Hierarchy -UserFIO 'Григорян Софья Феликсовна' -ManagerFIO 'Плетнева Наталья Викторовна' -Title ''
Set-Hierarchy -UserFIO 'Алексеенко Сергей Игоревич' -ManagerFIO 'Долгоносова Людмила Сергеевна' -Title ''
Set-Hierarchy -UserFIO 'Мойсеенков Дмитрий Андреевич' -ManagerFIO 'Долгоносова Людмила Сергеевна' -Title ''
Set-Hierarchy -UserFIO 'Есипенко Вера Тихоновна' -ManagerFIO 'Зевакин Василий Владимирович' -Title ''
Set-Hierarchy -UserFIO 'Митина Анжела Анатольевна' -ManagerFIO 'Зевакин Василий Владимирович' -Title ''
Set-Hierarchy -UserFIO 'Ильяшенко Надежда Александровна' -ManagerFIO 'Зевакин Василий Владимирович' -Title ''
Set-Hierarchy -UserFIO 'Захарова Екатерина Евгеньевна' -ManagerFIO 'Зевакин Василий Владимирович' -Title ''
Set-Hierarchy -UserFIO 'Нехаева Зоя Владимировна' -ManagerFIO 'Тлакадугов Залим Заурбекович' -Title ''
Set-Hierarchy -UserFIO 'Костина Светлана Валерьевна' -ManagerFIO 'Тлакадугов Залим Заурбекович' -Title ''
Set-Hierarchy -UserFIO 'Брагина Светлана Федоровна' -ManagerFIO 'Тлакадугов Залим Заурбекович' -Title ''
Set-Hierarchy -UserFIO 'Христофорова Елизавета Юрьевна' -ManagerFIO 'Тлакадугов Залим Заурбекович' -Title ''
Set-Hierarchy -UserFIO 'Крячко Анна Леонидовна' -ManagerFIO 'Брагина Светлана Федоровна' -Title ''
Set-Hierarchy -UserFIO 'Вдовыдченко Наталья Александровна' -ManagerFIO 'Брагина Светлана Федоровна' -Title ''