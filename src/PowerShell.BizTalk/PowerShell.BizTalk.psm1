enum BtsHostType {
    InProcess = 1
    Isolated = 2
}

class BtsHost {
    [string]$Name
    [BtsHostType]$HostType
    [bool]$TrackingHost
    [bool]$AuthTrusted
    [bool]$Is32BitOnly
    [bool]$IsDefaultHost
    [string]$WindowsGroup
    [bool]$LegacyWhitespace
}

function Get-Host {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Name
    )
    process {
        $instances = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").GetInstances()
    
        $instances | ForEach-Object {
            $btsHost = [BtsHost]::new()
            $btsHost.Name = $_.Name
            $btsHost.HostType = $_.HostType
            $btsHost.TrackingHost = $_.HostTracking
            $btsHost.AuthTrusted = $_.AuthTrusted
            $btsHost.Is32BitOnly = $_.IsHost32BitOnly
            $btsHost.IsDefaultHost = $_.IsDefault
            $btsHost.WindowsGroup = $_.NTGroupName

            return $btsHost
}
    }
}

function Remove-Host {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    process {
        $instance = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_Host").CreateInstance()
        $instance.Name = $Name
        if ($PSCmdlet.ShouldProcess($instance, "Deleting BizTalk Host")) {
            $instance.Delete()   
        }
    }
}

function New-Host {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [BtsHostType]$HostType,
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        [Parameter()]
        [switch]$TrackingHost,
        [Parameter()]
        [switch]$AuthTrusted,
        [Parameter()]
        [switch]$32BitOnly,
        [Parameter()]
        [switch]$DefaultHost
    )
    process {
        Set-Host @PSBoundParameters -PutType ([System.Management.PutType]::CreateOnly)
    }
}

function Set-Host {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory=$true)]
        [BtsHostType]$HostType,
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        [Parameter()]
        [switch]$TrackingHost,
        [Parameter()]
        [switch]$AuthTrusted,
        [Parameter()]
        [switch]$32BitOnly,
        [Parameter()]
        [switch]$DefaultHost,
        [Parameter(Mandatory=$true)]
        [System.Management.PutType]$PutType
    )
    process {
        Write-Verbose "Building host WMI instance"
        $instance = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").CreateInstance()
        $instance.Name = $Name
        $instance.HostType = $HostType
        $instance.NTGroupName = $GroupName
        $instance.AuthTrusted = [bool]$AuthTrusted
        $instance.IsHost32BitOnly = [bool]$32BitOnly
        $instance.HostTracking = [bool]$TrackingHost
        $instance.IsDefault = [bool]$DefaultHost
        Write-Debug ($instance | Out-String)

        $putOptions = [System.Management.PutOptions]::new()
        $putOptions.Type = $PutType
        if ($PSCmdlet.ShouldProcess($instance, "Modifying BizTalk Host")) {
            $instance.Put($PutOptions)   
        }
    }
}

function Remove-AdapterHandler {
    [CmdletBinding()]
    param (
    )
    process {

    }
}