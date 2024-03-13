#################################################################################################################################
#  Name        : Configure-WinRM.ps1                                                                                            #
#                                                                                                                               #
#  Description : Configures the WinRM on a local machine                                                                        #
#                                                                                                                               #
#  Arguments   : HostName, specifies the ipaddress or FQDN of machine                                                           #
#################################################################################################################################

#################################################################################################################################
#                                             Helper Functions                                                                  #
#################################################################################################################################

$ErrorActionPreference="Stop"
$winrmHttpPort=5985
$winrmHttpsPort=5986

$helpMsg = "Usage:
            To configure WinRM:
                ./ConfigureWinRM.ps1"

function Delete-WinRMListener
{
    $config = winrm enumerate winrm/config/listener
    foreach($conf in $config)
    {
        if($conf.Contains("HTTPS"))
        {
            Write-Verbose -Verbose "HTTPS is already configured. Deleting the exisiting configuration."

            winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
            break
        }
    }
}

function Add-FirewallException
{
    $port = $winrmHttpPort

    # Delete an exisitng rule
    Write-Verbose -Verbose "Deleting the existing firewall exception for port $port"
    netsh advfirewall firewall delete rule name="Windows Remote Management (HTTP-In)" dir=in protocol=TCP localport=$port | Out-Null

    # Add a new firewall rule
    Write-Verbose -Verbose "Adding the firewall exception for port $port"
    netsh advfirewall firewall add rule name="Windows Remote Management (HTTP-In)" dir=in action=allow protocol=TCP localport=$port | Out-Null
}


#################################################################################################################################
#                                              Configure WinRM                                                                  #
#################################################################################################################################

winrm quickconfig -q

# The default MaxEnvelopeSizekb on Windows Server is 500 Kb which is very less. It needs to be at 8192 Kb. The small envelop size if not changed
# results in WS-Management service responding with error that the request size exceeded the configured MaxEnvelopeSize quota.
winrm set winrm/config '@{MaxEnvelopeSizekb = "8192"}'
winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="512"}'
winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
winrm set "winrm/config/service/auth" '@{Basic="true"}'
winrm set "winrm/config/client/auth" '@{Basic="true"}'

# Add firewall exception
Add-FirewallException

net stop winrm
sc config winrm start= auto
net start winrm

# Shut down the machine
Stop-Computer -Force

#################################################################################################################################
#################################################################################################################################

