#Requires -Modules Pester

Describe "Create InProcess Host" {
    BeforeAll {
        Import-Module ".\src\PowerShell.BizTalk\PowerShell.BizTalk.psd1" -Force
    }
    Context "Create In-Process host" {
        New-BTSHost -Name "TestInProcess" -HostType InProcess -GroupName "BizTalk Application Users"
    }
    Context "Create Isolated host" {
        New-BTSHost -Name "TestIsolated" -HostType Isolated -GroupName "BizTalk Application Users"
    }
}