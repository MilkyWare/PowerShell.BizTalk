enum BtsAdapterDirection {
    Receive
    Send
}

enum BtsHostType {
    InProcess = 1
    Isolated = 2
}

class BtsAdapter {
    [string]$Name
    [string]$Comment
}

class BtsAdapterHandler {
    [string]$AdapterName
    [string]$HostName
    [BtsAdapterDirection]$Direction
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

#region Hosts
function Get-Host {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name
    )
    process {
        $instances = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").GetInstances()
        if ($PSBoundParameters.ContainsKey("Name")) {
            $instances = $instances | Where-Object {$Name.Contains($_.Name)}
        }
        
        $instances | ForEach-Object {
            $btsHost = [BtsHost]::new()
            $btsHost.Name = $_.Name
            $btsHost.HostType = $_.HostType
            $btsHost.TrackingHost = $_.HostTracking
            $btsHost.AuthTrusted = $_.AuthTrusted
            $btsHost.Is32BitOnly = $_.IsHost32BitOnly
            $btsHost.IsDefaultHost = $_.IsDefault
            $btsHost.LegacyWhitespace = $_.LegacyWhitespace
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
        [switch]$Is32BitOnly,
        [Parameter()]
        [switch]$IsDefaultHost,
        [Parameter()]
        [switch]$LegacyWhitespace,
        [Parameter()]
        [switch]$AllowMulitpleResponses
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
        [switch]$Is32BitOnly,
        [Parameter()]
        [switch]$IsDefaultHost,
        [Parameter()]
        [switch]$LegacyWhitespace,
        [Parameter()]
        [switch]$AllowMulitpleResponses,
        [Parameter(Mandatory=$true)]
        [System.Management.PutType]$PutType
    )
    process {
        Write-Verbose "Building host WMI instance"
        $instance = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").CreateInstance()
        $instance.Name = $Name
        $instance.HostType = $HostType
        $instance.NTGroupName = $GroupName
        if ($PSBoundParameters.ContainsKey("AuthTrusted")) {
            $instance.AuthTrusted = [bool]$AuthTrusted
        }
        if ($PSBoundParameters.ContainsKey("Is32BitOnly")) {
            $instance.AuthTrusted = [bool]$Is32BitOnly
        }
        if ($PSBoundParameters.ContainsKey("TrackingHost")) {
            $instance.AuthTrusted = [bool]$TrackingHost
        }
        if ($PSBoundParameters.ContainsKey("IsDefaultHost")) {
            $instance.AuthTrusted = [bool]$IsDefaultHost
        }
        if ($PSBoundParameters.ContainsKey("LegacyWhitespace")) {
            $instance.AuthTrusted = [bool]$LegacyWhitespace
        }
        if ($PSBoundParameters.ContainsKey("AllowMultipleResponses")) {
            $instance.AuthTrusted = [bool]$AllowMultipleResponses
        }
        Write-Debug ($instance | Out-String)

        $putOptions = [System.Management.PutOptions]::new()
        $putOptions.Type = $PutType
        if ($PSCmdlet.ShouldProcess($instance, "Modifying BizTalk Host")) {
            $instance.Put($PutOptions)
        }
    }
}
#endregion

#region Adapters
function Get-Adapter {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name
    )
    process {
        $instances = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_AdapterSetting").GetInstances()
        if ($PSBoundParameters.ContainsKey("Name")) {
            $instances = $instances | Where-Object {$Name.Contains($_.Name)}
        }
        $instances | ForEach-Object {
            $adapter = [BtsAdapter]::new()
            $adapter.Name = $_.Name
            $adapter.Comment = $_.Comment

            return $adapter
        }
    }
}
#endregion

#region Adapter Handlers
function Get-AdapterHandlers {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name,
        [Parameter()]
        [string[]]$HostName,
        [Parameter()]
        [BtsAdapterDirection]$Direction
    )
    process {
        $handlers = [System.Collections.Generic.List[BtsAdapterHandler]]::new()
        if (-not $PSBoundParameters.ContainsKey("Direction") -or $Direction -eq [BtsAdapterDirection]::Receive) {
            ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ReceiveHandler").GetInstances() | ForEach-Object {
                $handler = [BtsAdapterHandler]::new()
                $handler.AdapterName = $_.AdapterName
                $handler.HostName = $_.HostName
                $handler.Direction = [BtsAdapterDirection]::Receive

                $handlers.Add($handler)
            }
        }
        if (-not $PSBoundParameters.ContainsKey("Direction") -or $Direction -eq [BtsAdapterDirection]::Send) {
            ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_SendHandler2").GetInstances() | ForEach-Object {
                $handler = [BtsAdapterHandler]::new()
                $handler.AdapterName = $_.AdapterName
                $handler.HostName = $_.HostName
                $handler.Direction = [BtsAdapterDirection]::Send

                $handlers.Add($handler)
            }
        }
        return $handlers
    }
}
#endregion