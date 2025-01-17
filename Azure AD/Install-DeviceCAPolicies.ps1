﻿<##################################################################################################
#
.SYNOPSIS
    This script can create the following Device-based Conditional Access policies in your tenant:
    1. [Office 365 Mobile] GRANT: Require managed apps and browsers (MAM)
    2. [Office 365 Mobile] GRANT: Require compliant device for client app access (MDM)
    3. [Office 365 MacOS] GRANT: Require compliant device for client app access
    4. [Office 365 Windows] GRANT: Require compliant device or hybrid join for client app access
    5. [Office 365 Browsers] SESSION: Prevent web downloads on unmanaged devices
    6. [Office 365 Strict] GRANT: Require compliant device for all platforms

.NOTES
    1. You may need to disable the 'Security defaults' first. See https://aka.ms/securitydefaults
    2. None of the policies created by this script will be enabled by default.
    3. Before enabling policies, you should notify end users about the expected impacts
    4. Be sure to populate the 'Exclude from CA' security group with at least one admin account for emergency access

.HOW-TO
    1. To install the Azure AD Preview PowerShell module use: Install-Module AzureADPreview -AllowClobber
    2. To import the module run: Import-Module AzureADPreview 
    3. To connect to Azure AD via PowerShell run: Connect-AzureAD
    4. Run .\Install-BaselineConditionalAccessPolicies.ps1
    5. Reference: https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0#installing-the-azure-ad-module

.DETAILS
    FileName:    Install-DeviceCAPolicies.ps1
    Author:      Alex Fields, ITProMentor.com
    Created:     September 2020
	Updated:     February 2021

#>
###################################################################################################


## Check for the existence of the "Exclude from CA" security group, and create the group if it does not exist

$ExcludeCAGroupName = "sg-Exclude From CA"
$ExcludeCAGroup = Get-AzureADGroup -All $true | Where-Object DisplayName -eq $ExcludeCAGroupName

if ($ExcludeCAGroup -eq $null -or $ExcludeCAGroup -eq "") {
    New-AzureADGroup -DisplayName $ExcludeCAGroupName -SecurityEnabled $true -MailEnabled $false -MailNickName sg-ExcludeFromCA
    $ExcludeCAGroup = Get-AzureADGroup -All $true | Where-Object DisplayName -eq $ExcludeCAGroupName
}
else {
    Write-Host "Exclude from CA group already exists"
}

########################################################

## This policy enforces MAM for iOS and Android devices
## MAM NOTES: 
##     1. End-users will not be able to access company data from built-in browser or mail apps for iOS or Android; they must use approved apps (e.g. Outlook, Edge)
##     2. Android and iOS users must have the Authenticator app configured, and Android users must also download the Company Portal app

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = @('Android', 'IOS')
$conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = @('ApprovedApplication', 'CompliantApplication')

New-AzureADMSConditionalAccessPolicy -DisplayName "[Office 365 Mobile] GRANT: Require approved apps and browsers (MAM)" -State "Disabled" -Conditions $conditions -GrantControls $controls 

########################################################

## [OPTIONAL POLICY] Enforces MDM compliance for client app access on iOS and Android devices (i.e. Company-owned devices)
## MDM NOTES:
##     1. For iOS: Configure Apple enrollment certificate, and optionally connect Apple Business Manager (company-owned)
##     2. For Android: Link your Managed Google Play account, and optionally configure corporate-owned dedicated or fully managed devices
##     3. Personal devices: Both iOS and Android users should download the Authenticator app, and the Company Portal app to sign-in

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = @('Android', 'IOS')
$conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = @('CompliantDevice')

New-AzureADMSConditionalAccessPolicy -DisplayName "[Office 365 Mobile] GRANT: Require compliant device for client apps (MDM)" -State "Disabled" -Conditions $conditions -GrantControls $controls 

########################################################

## This policy enforces MDM compliance for client app access on macOS devices 
## MDM NOTES:
##     1. For macOS: Configure Apple enrollment certificate, and optionally connect Apple Business Manager (Company-owned)
##     2. Personal devices: Users need the Company Portal app to enroll

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = @('macOS')
$conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = @('CompliantDevice')

New-AzureADMSConditionalAccessPolicy -DisplayName "[Office 365 MacOS] GRANT: Require compliant device for client apps (MDM)" -State "Disabled" -Conditions $conditions -GrantControls $controls 

########################################################
## This policy requires compliant device or Hybrid Azure AD join for client app access on Windows devices 
## MDM NOTES:
##     1. For Windows: Configure Microsoft Store (Intune) or Hybrid Azure AD Join (On-premises/Azure AD Connect)
##     2. Personal devices: Users need the Company Portal app to enroll

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = @('Windows')
$conditions.ClientAppTypes = @('MobileAppsAndDesktopClients')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = @('DomainJoinedDevice', 'CompliantDevice')

New-AzureADMSConditionalAccessPolicy -DisplayName "[Office 365 Windows] GRANT: Require compliant device or Hybrid Azure AD Join" -State "Disabled" -Conditions $conditions -GrantControls $controls 

########################################################

## This policy prevents web downloads from unmanaged devices and unmanaged web browsers 
## Policy NOTES:
##     1. You must take additional action in Exchange Online and SharePoint Online to complete the set up for this policy to take effect
##     2. See my Conditional Access Best Practices guide for more details on those additional steps 
##     3. Unmanaged browsers (e.g. Firefox) will also be impacted by this policy, even on managed devices
##     4. End users should be advised to use Edge (Chromium version) with Office 365

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.ClientAppTypes = @('Browser')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
$controls.ApplicationEnforcedRestrictions = $true

New-AzureADMSConditionalAccessPolicy -DisplayName "[Office 365 Browsers] SESSION: Prevent web downloads from unmanaged devices" -State "Disabled" -Conditions $conditions -SessionControls $controls 

########################################################

## This policy enforces device compliance (or Hybrid Azure AD join) for all supported platforms: Windows, macOS, Android, and iOS
## NOTES: 
##    1. End-users must enroll their devices with Intune before enabling this policy
##    2. Azure AD joined or Hybrid Joined devices will be managed without taking additional action
##    3. Users with personal devices should use the Company Portal app to enroll
##    4. This policy blocks unmanaged device access from browsers (Edge, Firefox, etc.) and client apps (Outlook, OneDrive, etc.)

$conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
$conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
$conditions.Applications.IncludeApplications = "Office365"
$conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
$conditions.Users.IncludeUsers = "All"
$conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
$conditions.Users.ExcludeGroups = $ExcludeCAGroup.ObjectId
$conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
$conditions.Platforms.IncludePlatforms = @('Android', 'IOS', 'Windows', 'macOS')
$conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
$controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
$controls._Operator = "OR"
$controls.BuiltInControls = @('DomainJoinedDevice', 'CompliantDevice')

New-AzureADMSConditionalAccessPolicy -DisplayName "[Offie 365 Strict] Require compliant device for apps and browsers on all platforms" -State "Disabled" -Conditions $conditions -GrantControls $controls 

########################################################
