<#
    #####################################
    Cisco SSH Toolkit
    V2.0 - 4.1.18
    #####################################
    .Synopsis
       Perform Common SSH Commands on Cisco 3750x Switches
    .EXAMPLE
       Example of how to use this cmdlet
    .EXAMPLE
       Another example of how to use this cmdlet
#>

########################################
#region Variables ######################
########################################

## Import SSH Module - http://www.carbon60.com/it-advice/powershell-ssh-module-nonstandard-devices-like-cisco-asa
Import-Module SshShell
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference ="Inquire"
$time ="$(get-date -f yyyy-MM-dd)"

## SSH Login Info
$TargetSSHDevice = '10.100.1.2'

## SSH Device Prompts
$elevatedPrompt = "#"
$configPrompt = '\(config\)#$'
$vlanPrompt = '\(config-vlan\)#$'
$intPrompt = '\(config-if\)#$'
$passwordPrompt = 'Password:'

########################################
#endregion #############################
########################################

########################################
#region Start ##########################
########################################
    
    ## Display Intro Text
    Write-Host '  _   _   _   _   _   _   _   _   _'
    Write-Host ' / \ / \ / \ / \ / \ / \ / \ / \ / \'
    Write-Host '( C ) i ) s ) c ) o ) - ) S ) S ) H )'
    Write-Host ' \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/'


    ## Prompt user for cred and store in secure file
    Write-Host 'Getting Credentials....'
    $Cred = Get-Credential -Message 'Please enter your credentials to connect.'
    $elevatedPassword = $cred.GetNetworkCredential().Password

    ## Login to SSH device and navigate to enable prompt
    Write-Host "Logging into Device... $TargetSSHDevice"
    $s = New-SshSession -SshHost $TargetSSHDevice -Credential $Cred
    Send-SshCommand $s "en" -Expect $passwordPrompt
    Send-SshCommand $s "$elevatedPassword" -Expect $elevatedPrompt

    ## Backup Running Config
    #Send-SshCommand $s "show run" -Expect $elevatedPrompt -WaitMillisecondsForOutput '2000'| Out-File 'C:\TEMP\test.txt'

#endregion


########################################
#region Script #########################
########################################
do
    {

    $x = '1'

    ########################################
    #region Configure Vlan for Access port #
    ########################################

        function ConfigSwitchPortVlan ()
        {

            Write-Host 'Entering Switchport Vlan change Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Get info on port,vlan,desc,switchstack,etc..
            Read-Host 'What should the description be? EX:WAP' -OutVariable SwitchPortDisc
            Read-Host 'What Switch in the stack EX:1|2|3|4?' -OutVariable SwitchNum
            Read-Host 'What Switch Port? EX:48' -OutVariable SwitchPortNum
            Read-Host 'What VLAN? EX:200' -OutVariable SwitchPortVlan
            Read-Host 'Enable Switch Port? EX:Yes|No' -OutVariable SwitchPortEnabled

            # Send SSH commands
            Send-SshCommand $s "conf t" -Expect $configPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "int gi$SwitchNum/0/$SwitchPortNum" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "description $SwitchPortDisc" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "switchport mode access" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "spanning-tree portfast" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "switchport access vlan $SwitchPortVlan" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            If($SwitchPortEnabled -like 'yes'){
                Write-Host 'Done.. Bringing Up Switchport' -ForegroundColor Yellow -BackgroundColor Black
                Send-SshCommand $s "no shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            }

            Write-Host 'Complete.... Exiting SwitchPort Vlan change Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Clear Switch Number and Switchport
            $SwitchPortNum = "$null"
            $SwitchNum = "$null"

        }

    ########################################
    #endregion #############################
    ########################################

    ########################################
    #region Configure port security ########
    ########################################

        function ConfigSwitchPortSecurity ()
        {
            Write-Host 'Entering Port Security Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Get info on port,vlan,desc,switchstack,etc..
            Read-Host 'What Switch in the stack EX:1|2|3|4?' -OutVariable SwitchNum
            Read-Host 'What Switch Port? EX:48' -OutVariable SwitchPortNum
            Read-Host 'Enable MAC Address Sticky?' -OutVariable SwitchPortSecMacSticky
            Read-Host 'How do you want to handle violations? EX:shutdown|restrict|protect' -OutVariable SwitchPortSecVioType
            Read-Host 'How many devices do you want to allow on this Port? EX:1|5|7' -OutVariable SwitchPortSecMax
            Read-Host 'Enable Switch Port? EX:Yes|No' -OutVariable SwitchPortEnabled

            # Send SSH commands
            ## Error handle if values are not correct?
            Send-SshCommand $s "conf t" -Expect $configPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "int gi$SwitchNum/0/$SwitchPortNum" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "switchport port-security" -Expect $intPrompt -WaitMillisecondsForOutput '750'

            switch ($SwitchPortSecMacSticky)
            {
                "yes" {Send-SshCommand $s "switchport port-security mac-address sticky" -Expect $intPrompt -WaitMillisecondsForOutput '750'}
                "no" {Send-SshCommand $s "shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'}
                default {Write-Host 'PortSecMacSticky: Please type "Yes" or "No".. starting over...' -ForegroundColor Yellow -BackgroundColor Black}

            }

            switch ($SwitchPortSecVioType)
            {
                "shutdown" {Send-SshCommand $s "switchport port-security violation shutdown" -Expect $intPrompt -WaitMillisecondsForOutput '750'}
                "restrict" {Send-SshCommand $s "switchport port-security violation restrict" -Expect $intPrompt -WaitMillisecondsForOutput '750'}
                "protect" {Send-SshCommand $s "switchport port-security violation protect" -Expect $intPrompt -WaitMillisecondsForOutput '750'}
                default {Write-Host 'PortSecSecVio: Please pick a valid option' -ForegroundColor Yellow -BackgroundColor Black}

            }


            if ($SwitchPortSecMax)
            {
                Send-SshCommand $s "switchport port-security maximum $SwitchPortSecMax" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            }

            Write-Host 'Done.. Resetting Switchport' -ForegroundColor Yellow -BackgroundColor Black
            Send-SshCommand $s "shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "no shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            Write-Host 'Complete.... Exiting Port Security Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Clear Switch Number and Switchport
            $SwitchPortNum = "$null"
            $SwitchNum = "$null"

        }


    ########################################
    #endregion #############################
    ########################################

    ########################################
    #region Configure port 802.1x ########
    ########################################

        function ConfigSwitchPort802 ()
        {

            Write-Host 'Entering 802.1x Mode' -ForegroundColor Yellow -BackgroundColor Black
            Write-Host 'Done.. Resetting Switchport' -ForegroundColor Yellow -BackgroundColor Black
            Write-Host 'Complete.... Exiting 802.1x Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Clear Switch Number and Switchport
            $SwitchPortNum = "$null"
            $SwitchNum = "$null"
        }


    ########################################
    #endregion #############################
    ########################################

    ########################################
    #region Configure Vlan for Access port #
    ########################################

        function ConfigSwitchPort ()
        {

            Write-Host 'Entering Switchport Enable/Disable Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Get info on port,vlan,desc,switchstack,etc..
            Read-Host 'What Switch in the stack EX:1|2|3|4?' -OutVariable SwitchNum
            Read-Host 'What Switch Port? EX:48' -OutVariable SwitchPortNum
            Read-Host 'Enable/Disable Switch Port? EX:Disable|Enable' -OutVariable SwitchPortEnabled

            # Send SSH commands
            Send-SshCommand $s "conf t" -Expect $configPrompt -WaitMillisecondsForOutput '750'
            Send-SshCommand $s "int gi$SwitchNum/0/$SwitchPortNum" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            If($SwitchPortEnabled -like 'enable'){
                Send-SshCommand $s "no shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            }

            elseif($SwitchPortEnabled -like 'disable'){
                Send-SshCommand $s "shut" -Expect $intPrompt -WaitMillisecondsForOutput '750'
            }

            else{
                Write-Host 'Please type "Enable" or "Disable".. starting over...' -ForegroundColor Yellow -BackgroundColor Black
                ConfigSwitchPort
            }

            Write-Host 'Done.. Resetting Switchport' -ForegroundColor Yellow -BackgroundColor Black
            Write-Host 'Complete.... Exiting Enable/Disable Mode' -ForegroundColor Yellow -BackgroundColor Black

            # Clear Switch Number and Switchport
            $SwitchPortNum = "$null"
            $SwitchNum = "$null"

        }

    ########################################
    #endregion #############################
    ########################################

    ########################################
    #region Select Action ##################
    ########################################
        
        Write-Host "Current Target Device: $TargetSSHDevice"
        Write-Host 'Please pick a number....' -ForegroundColor Green
        Write-Host '1. Configure Switch Port Vlan' -ForegroundColor Red
        Write-Host '2. Configure Port Security'-ForegroundColor Red
        Write-Host '3. Configure 802.1X Switch Port'-ForegroundColor Red
        Write-Host '4. Enable/Disable Switch Port'-ForegroundColor Red
        Write-Host '5. Backup Running Configuration'-ForegroundColor Red
        Read-Host 'Please pick a number...' -OutVariable MenuSelect

        switch ($MenuSelect)
            {
                1 {ConfigSwitchPortVlan}
                2 {ConfigSwitchPortSecurity}
                3 {ConfigSwitchPort802}
                4 {ConfigSwitchPort}
                5 {BackupRunningConfig}
                6 {}
                7 {}
                8 {}
                default {"Please pick a number.."}

            }
    ########################################
    #endregion #############################
    ########################################


    }

while ($x -gt 0)

########################################
#endregion #############################
########################################


Send-SshCommand $s "end"
Close-SshSession $s


<#if ($s.LastResult -match "does not exist") {
    Send-SshCommand $s "conf t" -Expect $configPrompt
    #Send-SshCommand $s "object network $objectId" -Expect $vlanPrompt
    Send-SshCommand $s "end" -Expect $elevatedPrompt
    Send-SshCommand $s "write mem" -Expect "[OK]" -WaitUnlimitedOn "configuration...|Cryptochecksum|copied"
}#>