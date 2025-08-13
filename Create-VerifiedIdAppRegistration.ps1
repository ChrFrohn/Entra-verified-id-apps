# Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

<#
.SYNOPSIS
    Creates app registration and grants permissions for Microsoft Entra Verified ID deployment

.DESCRIPTION
    Part of the Entra Verified ID project: https://github.com/ChrFrohn/Entra-Verified-ID
    Author: Christian Frohn
    LinkedIn: https://www.linkedin.com/in/frohn/

.PARAMETER AppName
    App registration name (default: "APR-Entra-VerifiedID-Apps")

.EXAMPLE
    .\setup-verified-id.ps1
    Creates app registration with default name "APR-Entra-VerifiedID-Apps"

.EXAMPLE
    .\setup-verified-id.ps1 -AppName "APR-MyCompany-VerifiedID"
    Creates app registration with custom name "APR-MyCompany-VerifiedID"
#>

param([string]$AppName = "APR-Entra-VerifiedID-Apps")

# Connect to Graph
Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -NoWelcome

$TenantId = (Get-MgContext).TenantId

# Create or get existing app
$App = Get-MgApplication -Filter "displayName eq '$AppName'" -ErrorAction SilentlyContinue
if (-not $App) {
    $App = New-MgApplication -DisplayName $AppName -RequiredResourceAccess @(
        @{
            ResourceAppId = "3db474b9-6a0c-4840-96ac-1fceb342124f"  # Verified ID
            ResourceAccess = @(@{ Id = "949ebb93-18f8-41b4-b677-c2bfea940027"; Type = "Role" })
        },
        @{
            ResourceAppId = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
            ResourceAccess = @(@{ Id = "df021288-bdef-4463-88db-98f22de89214"; Type = "Role" })
        }
    ) -Web @{ RedirectUris = @("https://localhost") }
}

# Create client secret
$Secret = Add-MgApplicationPassword -ApplicationId $App.Id -PasswordCredential @{
    DisplayName = "VerifiedID-Secret-$(Get-Date -Format 'yyyyMMdd')"
    EndDateTime = (Get-Date).AddYears(2)
}

# Create service principal and grant permissions
$ServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '$($App.AppId)'" -ErrorAction SilentlyContinue
if (-not $ServicePrincipal) {
    $ServicePrincipal = New-MgServicePrincipal -AppId $App.AppId
}

# Grant Verified ID permissions
$VerifiedIdSP = Get-MgServicePrincipal -Filter "appId eq '3db474b9-6a0c-4840-96ac-1fceb342124f'" -ErrorAction SilentlyContinue
if ($VerifiedIdSP) {
    $VerifiedIdRole = $VerifiedIdSP.AppRoles | Where-Object { $_.Id -eq "949ebb93-18f8-41b4-b677-c2bfea940027" }
    if ($VerifiedIdRole -and -not (Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id | 
        Where-Object { $_.ResourceId -eq $VerifiedIdSP.Id -and $_.AppRoleId -eq $VerifiedIdRole.Id })) {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -PrincipalId $ServicePrincipal.Id -ResourceId $VerifiedIdSP.Id -AppRoleId $VerifiedIdRole.Id | Out-Null
    }
}

# Grant User.Read.All permissions
$GraphSP = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction SilentlyContinue
if ($GraphSP) {
    $UserReadRole = $GraphSP.AppRoles | Where-Object { $_.Id -eq "df021288-bdef-4463-88db-98f22de89214" }
    if ($UserReadRole -and -not (Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id | 
        Where-Object { $_.ResourceId -eq $GraphSP.Id -and $_.AppRoleId -eq $UserReadRole.Id })) {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ServicePrincipal.Id -PrincipalId $ServicePrincipal.Id -ResourceId $GraphSP.Id -AppRoleId $UserReadRole.Id | Out-Null
    }
}

Disconnect-MgGraph | Out-Null

# Output values
Write-Host ""
Write-Host "Deployment Values:" -ForegroundColor Green
Write-Host "-----------------" -ForegroundColor Green
Write-Host "1. CLIENT_ID:     $($App.AppId)" -ForegroundColor White
Write-Host ""
Write-Host "2. CLIENT_SECRET: $($Secret.SecretText)" -ForegroundColor White
Write-Host ""
Write-Host "3. TENANT_ID:     $TenantId" -ForegroundColor White

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "4. Get your credential manifest URL from:" -ForegroundColor White
Write-Host "   https://entra.microsoft.com/#view/Microsoft_AAD_DecentralizedIdentity/CardsListBlade" -ForegroundColor Cyan
Write-Host "   (Select credential with type 'Verified Employee')" -ForegroundColor Gray
Write-Host ""
Write-Host "5. Get your credential type from the same location (e.g., 'VerifiedEmployee')" -ForegroundColor White
Write-Host ""
Write-Host "6. Get your DID Authority URL from:" -ForegroundColor White
Write-Host "   https://entra.microsoft.com/#view/Microsoft_AAD_DecentralizedIdentity/IssuerSettingsBlade" -ForegroundColor Cyan
Write-Host ""
Write-Host "7. Deploy to Azure using these numbered values with the 'Deploy to Azure' button on the GitHub repo" -ForegroundColor White