# PowerShell script to add extensionAttribute1-15 to AD Schema with unique OIDs
$RootDSE = Get-ADRootDSE
$SchemaDN = $RootDSE.schemaNamingContext
$UserClassDN = "CN=User,$SchemaDN"

# Use a safe OID range (private OIDs)
$oid_base = "1.2.840.113556.1.4.7000.102."

Write-Host "--- ATTRIBUTE CREATION ---"
for ($i=1; $i -le 15; $i++) {
    $attrName = "extensionAttribute$i"
    $oid = $oid_base + $i
    $exists = Get-ADObject -Filter "Name -eq '$attrName'" -SearchBase $SchemaDN -ErrorAction SilentlyContinue
    if (-not $exists) {
        Write-Host "Creating $attrName ($oid)..."
        try {
            New-ADObject -Type attributeSchema -Name $attrName -Path $SchemaDN -OtherAttributes @{
                attributeID     = $oid
                attributeSyntax = "2.5.5.12"
                isSingleValued  = $true
                lDAPDisplayName = $attrName
                oMSyntax        = 64
            }
        } catch {
            Write-Host "Error creating $($attrName) : $($_.Exception.Message)"
        }
    } else {
        Write-Host "$attrName already exists."
    }
}

# Reload Schema Cache
$rootDSE_obj = [ADSI]"LDAP://RootDSE"
$rootDSE_obj.Put("schemaUpdateNow", 1)
$rootDSE_obj.SetInfo()

# Add to User Class
$userClass = [ADSI]"LDAP://$UserClassDN"
for ($i=1; $i -le 15; $i++) {
    $attrName = "extensionAttribute$i"
    try {
        $userClass.PutEx(3, "mayContain", @($attrName))
        $userClass.SetInfo()
        Write-Host "Added $attrName to User class."
    } catch {
        Write-Host "$attrName already in User class or couldn't be added."
    }
}
Write-Host "--- SCHEMA EXTENSION COMPLETE ---"
