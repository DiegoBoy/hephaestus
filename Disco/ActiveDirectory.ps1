function Get-Domain {
    $domainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $domainName = $domainObj.Name
    return $domainName
}


function Get-DomainController {
    $domainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $dcName = $domainObj.PdcRoleOwner.Name
    return $dcName
}


function Get-SearchRoot {
    $domainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
    $dcName = $domainObj.PdcRoleOwner.Name
    $domainName = $domainObj.Name

    $dcDistinguishedName = "DC=$($domainName.Replace('.', ',DC='))"
    $searchRoot = "LDAP://$dcName/$dcDistinguishedName"
    return $searchRoot
}


function Search-AD {
    param (
        [Parameter(Mandatory=$true)]
        [String]$Filter,

        [Parameter(Mandatory=$false)]
        [String[]]$Properties
    )

    $searchRoot = Get-SearchRoot
    $objDomain = New-Object System.DirectoryServices.DirectoryEntry($searchRoot)
    
    $searcher = New-Object System.DirectoryServices.DirectorySearcher($searchRoot)
    $searcher.SearchRoot = $objDomain
    $searcher.filter = $Filter

    if ($Properties) {
        foreach ($prop in $Properties) {
            $searcher.PropertiesToLoad.Add($prop)
        }
    }

    $all = $searcher.FindAll()
    $result = @()
    foreach ($obj in $all)
    {
        $result += [PSCustomObject]($obj.Properties)
    }
    return $result
}


function Get-AndFilter {
    param (
        [Parameter(Mandatory=$false)]
        [String]$FilterA,
        
        [Parameter(Mandatory=$false)]
        [String]$FilterB
    )

    if ($FilterA -and $FilterB) {
        return "(&($FilterA)($FilterB))"
    }
    elseif ($FilterA) {
        return $FilterA
    }
    else {
        return $FilterB
    }
}


# samAccountType == 0x30000000 == 805306368 == domain user objects
$script:filter_users = "samAccountType=805306368"
function Get-Users {
    param (
        [Parameter(Mandatory=$false)]
        [String]$Filter
    )

    $andFilter = Get-AndFilter -FilterA $script:filter_users -FilterB $Filter
    $result = Search-AD -Filter $andFilter
    return $result
}


# samAccountType == 0x10000000 == 268435456 == domain group objects
$script:filter_groups = "samAccountType=268435456"
function Get-Groups {
    param (
        [Parameter(Mandatory=$false)]
        [String]$Filter
    )

    $andFilter = Get-AndFilter -FilterA $script:filter_groups -FilterB $Filter
    $result = Search-AD -Filter $andFilter
    return $result
}


# samAccountType == 0x30000001 == 805306369 == domain-joined computer objects
$script:filter_computers = "samAccountType=805306369"
function Get-Computers {
    param (
        [Parameter(Mandatory=$false)]
        [String]$Filter
    )

    $andFilter = Get-AndFilter -FilterA $script:filter_computers -FilterB $Filter
    $result = Search-AD -Filter $andFilter
    return $result
}


function Get-GroupMembers {
    param (
        [Parameter(Mandatory=$true)]
        [String]$Group
    )

    $distinguished = (Search-AD -Filter "(&($script:filter_groups)(name=$Group))" -Properties "distinguishedname").distinguishedname
    $result = Search-AD -Filter "(&($script:filter_users)(memberOf:1.2.840.113556.1.4.1941:=$distinguished))"
    return $result
}



# Get all users
# samAccountType == 0x30000000 == 805306368 == user objects
#$adSearcher.Filter  "samAccountType=805306368"

# Get domain admins
#$adSearcher.filter = "(&(samAccountType=805306368)(memberof=CN=Domain Admins,CN=Users,$dcDistinguishedName))"

# Get domain computers
$result = Search-AD -Filter "(&(objectCategory=computer)(!(logoncount=0)))"

foreach ($obj in $result)
{
    # Foreach ($prop in $obj.Properties)
    # {
    #     $prop | Out-String
    # }
    echo "------------------------" | Out-String

    $obj.Properties.samaccountname
}

Get-Users