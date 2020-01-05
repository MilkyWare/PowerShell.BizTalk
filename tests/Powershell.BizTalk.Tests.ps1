#Requires -RunAsAdministrator
#Requires -Modules Pester

Describe "Create and delete in-process host" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestInProcess" -HostType InProcess -GroupName "BizTalk Application Users" -Verbose
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestInProcess" -Verbose
    }
}

Describe "Create and delete isolated host" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestIsolated" -HostType Isolated -GroupName "BizTalk Isolated Host Users" -Verbose
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestIsolated" -Verbose
    }
}

Describe "Get hosts" {
    BeforeAll {
        Import-Module "$($PSScriptRoot)\..\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Get list of hosts" {
        Get-BTSHost -Verbose
    }
}