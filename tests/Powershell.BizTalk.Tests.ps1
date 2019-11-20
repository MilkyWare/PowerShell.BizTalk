#Requires -Modules Pester

Describe "Create and delete in-process host" {
    BeforeAll {
        Import-Module ".\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestInProcess" -HostType InProcess -GroupName "BizTalk Application Users"
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestInProcess"
    }
}

Describe "Create and delete isolated host" {
    BeforeAll {
        Import-Module ".\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    It "Create Host" {
        New-BTSHost -Name "TestIsolated" -HostType Isolated -GroupName "BizTalk Isolated Host Users"
    }
    Context "Cleanup" {
        Remove-BTSHost -Name "TestIsolated"
    }
}

Describe "Get hosts" {
    It "Get list of hosts" {
        Get-BTSHost
    }
}