#Requires -RunAsAdministrator
#Requires -Modules Pester

Describe "Create and delete in-process host" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestInProcess" -HostType InProcess -GroupName "LEEDS\SDL-SDE BT App Users"
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestInProcess"
    }
}

Describe "Create and delete isolated host" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestIsolated" -HostType Isolated -GroupName "LEEDS\SDL-SDE BT Isolated Host Users"
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestIsolated"
    }
}

Describe "Get hosts" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Get list of hosts" {
        Get-BTSHost
    }
}