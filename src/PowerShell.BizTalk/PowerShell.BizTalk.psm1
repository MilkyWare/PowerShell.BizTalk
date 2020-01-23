#Requires -RunAsAdministrator

enum BtsAdapterDirection
{
    Receive
    Send
}

enum BtsConfigurationState
{
    Installed = 1
    InstallationFailed = 2
    UninstallationFailed = 3
    UpdateFailed = 4
    NotInstalled = 5 
}

enum BtsHostType
{
    InProcess = 1
    Isolated = 2
}

enum BtsServiceState
{
    Stopped = 1
    StartPending = 2
    StopPending = 3
    Started = 4
    ContinuePending = 5
    PausePending = 6
    Paused = 7
    NotApplicable = 8
}

class BtsAdapter
{
    [string]$Name
    [string]$Comment
}

class BtsAdapterHandler
{
    [string]$AdapterName
    [string]$HostName
    [BtsAdapterDirection]$Direction
}

class BtsHost
{
    [string]$Name
    [BtsHostType]$HostType
    [bool]$TrackingHost
    [bool]$AuthTrusted
    [bool]$Is32BitOnly
    [bool]$IsDefaultHost
    [string]$WindowsGroup
    [bool]$LegacyWhitespace
}

class BtsHostInstance
{
    [string]$Name
    [string]$HostName
    [BtsHostType]$HostType
    [string]$ComputerName
    [BtsConfigurationState]$ConfigurationState
    [BtsServiceState]$Status
    [string]$Logon
    [bool]$IsDisabled
}

#region Hosts
function Get-Host
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name
    )
    process
    {
        $instances = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").GetInstances()
        if ($PSBoundParameters.ContainsKey("Name"))
        {
            Write-Verbose "Filtering hosts by name"
            $instances = $instances | Where-Object { $Name -contains $_.Name }
        }
        Write-Verbose "Found $($instances.Count) host(s)"
        
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

function New-Host
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [BtsHostType]$HostType,
        [Parameter(Mandatory = $true)]
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
    process
    {
        Set-Host @PSBoundParameters -PutType ([System.Management.PutType]::CreateOnly)
    }
}

function Remove-Host
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    process
    {
        $instance = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_Host").CreateInstance()
        $instance.Name = $Name
        if ($PSCmdlet.ShouldProcess($instance, "Deleting BizTalk Host"))
        {
            $instance.Delete()   
        }
    }
}

function Set-Host
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [BtsHostType]$HostType,
        [Parameter(Mandatory = $true)]
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
        [Parameter(Mandatory = $true)]
        [System.Management.PutType]$PutType
    )
    process
    {
        Write-Verbose "Building host WMI instance"
        $instance = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_HostSetting").CreateInstance()
        $instance.Name = $Name
        $instance.HostType = $HostType
        $instance.NTGroupName = $GroupName
        if ($PSBoundParameters.ContainsKey("AuthTrusted"))
        {
            $instance.AuthTrusted = [bool]$AuthTrusted
        }
        if ($PSBoundParameters.ContainsKey("Is32BitOnly"))
        {
            $instance.AuthTrusted = [bool]$Is32BitOnly
        }
        if ($PSBoundParameters.ContainsKey("TrackingHost"))
        {
            $instance.AuthTrusted = [bool]$TrackingHost
        }
        if ($PSBoundParameters.ContainsKey("IsDefaultHost"))
        {
            $instance.AuthTrusted = [bool]$IsDefaultHost
        }
        if ($PSBoundParameters.ContainsKey("LegacyWhitespace"))
        {
            $instance.AuthTrusted = [bool]$LegacyWhitespace
        }
        if ($PSBoundParameters.ContainsKey("AllowMultipleResponses"))
        {
            $instance.AuthTrusted = [bool]$AllowMultipleResponses
        }
        Write-Debug ($instance | Out-String)

        $putOptions = [System.Management.PutOptions]::new()
        $putOptions.Type = $PutType
        if ($PSCmdlet.ShouldProcess($instance, "Modifying BizTalk Host"))
        {
            $instance.Put($PutOptions)
        }
    }
}
#endregion

#region Host Instances
function Get-HostInstance
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$HostName,
        [Parameter()]
        [string[]]$ComputerName
    )
    $instances = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_HostInstance").GetInstances()
    if ($HostName)
    {
        Write-Verbose "Filtering instances by name"
        $instances = $instances | Where-Object { $HostName -contains $_.HostName }
    }
    if ($ComputerName)
    {
        Write-Verbose "Filtering instances by server"
        $instances = $instances | Where-Object { $ComputerName -contains $_.RunningServer }
    }
    Write-Verbose "Found $($instances.Count) host instance(s)"

    $instances | ForEach-Object {
        $instance = [BtsHostInstance]::new()
        $instance.Name = $_.Name
        $instance.HostName = $_.HostName
        $instance.HostType = [BtsHostType]$_.HostType
        $instance.ComputerName = $_.RunningServer
        $instance.ConfigurationState = [BtsConfigurationState]$_.ConfigurationState
        $instance.Status = [BtsServiceState]$_.ServiceState
        $instance.Logon = $_.Logon
        $instance.IsDisabled = $_.IsDisabled

        return $instance
    }
}

function New-HostInstance
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $true)]
        [pscredential]$Credential,
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME,
        [Parameter()]
        [switch]$StartOnCreation
    )
    process
    {
        Write-Verbose "Checkng for existing server host"
        $serverHostFound = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ServerHost").GetInstances() | Where-Object {
            ($_.HostName -eq $HostName) -and ($_.ServerName = $ComputerName) -and $_.IsMapped
        }

        if (-not $serverHostFound)
        {
            try
            {
                Write-Verbose "Creating server host"
                [System.Management.ManagementObject]$serverHost = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ServerHost").CreateInstance()
                $serverHost.HostName = $HostName
                $serverHost.ServerName = $ComputerName
                Write-Debug ($serverHost | Out-String)
    
                if ($PSCmdlet.ShouldProcess($serverHost, "Installing host instance"))
                {
                    Write-Verbose "Mapping server host"
                    $serverHost.Map() | Out-Null
                }
            }
            catch
            {
                throw $_
            }
        }
        else
        {
            Write-Verbose "Existing server host found"
            Write-Debug ($serverHostFound | Out-String)
        }

        Write-Verbose "Checkng for existing host instance"
        $instanceFound = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_HostInstance").GetInstances() | Where-Object {
            ($_.HostName -eq $HostName) -and ($_.RunningServer -eq $ComputerName)
        }
        if (-not $instanceFound)
        {
            try
            {
                [System.Management.ManagementObject]$instance = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_HostInstance").CreateInstance()
                $hostInstanceName = "Microsoft BizTalk Server $Name $ComputerName"
                Write-Debug "HostInstanceName = $hostInstanceName"
    
                $instance.Name = $hostInstanceName
                $instance.HostName = $HostName
                $instance.RunningServer = $ComputerName
                Write-Debug ($instance | Out-String)
    
                if ($PSCmdlet.ShouldProcess($instance, "Installing host instance"))
                {
                    Write-Verbose "Installing host instance"
                    $instance.Install($Credential.UserName, $Credential.GetNetworkCredential().Password, $true) | Out-Null
                }
            }
            catch
            {
                throw $_
            }
        }
        else
        {
            Write-Error "Existing host instance found"
            Write-Debug ($instanceFound | Out-String)
        }
    }
}

function Remove-HostInstance
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME,
        [Parameter()]
        [switch]$Force
    )
    process
    {
        $instance = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_HostInstance").GetInstances() | Where-Object {
            $_.HostName -eq $HostName -and $_.RunningServer -eq $ComputerName
        }

        if ($instance)
        {
            Write-Verbose "Host instance found"

            if ($instance.ConfigurationState -eq [BtsConfigurationState]::Installed)
            {
                if ($PSCmdlet.ShouldProcess($instance, "Uninstalling host instance"))
                {
                    try
                    {
                        $instance.Uninstall() | Out-Null
                        Write-Verbose "Host instance uninstalled"
                    }
                    catch
                    {
                        Write-Error -Exception $Error[0].Exception
                    }
                }
            }

            $serverHost = ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ServerHost").GetInstances() | Where-Object {
                ($_.HostName -eq $HostName) -and ($_.ServerName -eq $ComputerName)
            }
    
            if ($serverHost)
            {
                Write-Verbose "Server host found"
                if ($PSCmdlet.ShouldProcess($serverHost), "Server host unmapped")
                {
                    if ($Force)
                    {
                        $serverHost.ForceUnmap() | Out-Null
                        Write-Verbose "Forcibly unmappws server host"
                    }
                    else
                    {
                        $serverHost.Unmap() | Out-Null
                        Write-Verbose "Unmapped server host"
                    }
                }
            }
        }
        else {
            Write-Warning "Host instance not found"
        }
    }
}
#endregion

#region Adapters
function Get-Adapter
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name
    )
    process
    {
        $instances = ([wmiclass]"root/MicrosoftBizTalkServer:MSBTS_AdapterSetting").GetInstances()
        if ($Name)
        {
            $instances = $instances | Where-Object { $Name.Contains($_.Name) }
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
function Get-AdapterHandlers
{
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]$Name,
        [Parameter()]
        [string[]]$HostName,
        [Parameter()]
        [BtsAdapterDirection]$Direction
    )
    process
    {
        $handlers = [System.Collections.Generic.List[BtsAdapterHandler]]::new()
        if (-not $PSBoundParameters.ContainsKey("Direction") -or $Direction -eq [BtsAdapterDirection]::Receive)
        {
            ([WmiClass]"root/MicrosoftBizTalkServer:MSBTS_ReceiveHandler").GetInstances() | ForEach-Object {
                $handler = [BtsAdapterHandler]::new()
                $handler.AdapterName = $_.AdapterName
                $handler.HostName = $_.HostName
                $handler.Direction = [BtsAdapterDirection]::Receive

                $handlers.Add($handler)
            }
        }
        if (-not $PSBoundParameters.ContainsKey("Direction") -or $Direction -eq [BtsAdapterDirection]::Send)
        {
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