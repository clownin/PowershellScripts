
function Show-Menu
{
     param (
           [string]$Title = 'Best Tool Ever'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "1: Display System Information"
     Write-Host "2: Clean PC (Remove Bloatware, Un-Needed System Files & Scan/Remove Malware)"
     Write-Host "3: Quick Printer Setup (Needs Tested)"
     Write-Host "4: Export Troubleshooting Answer Files (Not Implemented)"
     Write-Host "5: Online DISM Image Checker"
     Write-Host "6: System File Checker"
     Write-Host "q: Press 'q' to quit."
}

function Show-Info
{
    Write-Host -NoNewLine "OS Version: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  Caption | ForEach{ $_.Caption }
    Write-Host -NoNewLine "Install Date: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  InstallDate | ForEach{ $_.InstallDate }
    Write-Host -NoNewLine "Service Pack Version: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  ServicePackMajorVersion | ForEach{ $_.ServicePackMajorVersion }
    Write-Host -NoNewLine "OS Architecture: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  OSArchitecture | ForEach{ $_.OSArchitecture }
    Write-Host -NoNewLine "Boot Device: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  BootDevice | ForEach{ $_.BootDevice }
    Write-Host -NoNewLine "Build Number: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  BuildNumber | ForEach{ $_.BuildNumber }
    Write-Host -NoNewLine "Host Name: "
      Get-CimInstance Win32_OperatingSystem | Select-Object  CSName | ForEach{ $_.CSName }
    Write-Host -NoNewLine "IP Address: "
      Get-WmiObject -Class Win32_NetworkAdapterConfiguration | select ipaddress | ForEach{ $_.ipaddress } 
    Write-Host -NoNewLine "Gateway: "
        Get-WmiObject -Class Win32_NetworkAdapterConfiguration | select defaultipgateway | ForEach{ $_.defaultipgateway }
    Get-WmiObject -Class win32_logicaldisk  | ft DeviceID, @{Name="Free Disk Space (GB)";e={$_.FreeSpace /1GB}}, @{Name="Total Disk Size (GB)";e={$_.Size /1GB}} -AutoSize
    Get-WmiObject -Class win32_computersystem  | ft @{Name="Physical Processors";e={$_.NumberofProcessors}} ,@{Name="Logical Processors";e={$_.NumberOfLogicalProcessors}} , @{Name="TotalPhysicalMemory (GB)";e={[math]::truncate($_.TotalPhysicalMemory /1GB)}}, Model -AutoSize
    Get-WmiObject -Class win32_operatingsystem | ft @{Name="Total Visible Memory Size (GB)";e={[math]::truncate($_.TotalVisibleMemorySize /1MB)}}, @{Name="Free Physical Memory (GB)";e={[math]::truncate($_.FreePhysicalMemory /1MB)}} -AutoSize
    Get-WmiObject -Class win32_bios | ft @{Name="ServiceTag";e={$_.SerialNumber}}  
}

#This function finds any AppX/AppXProvisioned package and uninstalls it, except for Freshpaint, Windows Calculator, Windows Store, and Windows Photos.
#Also, to note - This does NOT remove essential system services/software/etc such as .NET framework installations, Cortana, Edge, etc.

#This is the switch parameter for running this script as a 'silent' script, for use in MDT images or any type of mass deployment without user interaction.
param (
    [switch]$Debloat, [switch]$SysPrep, [switch]$StopEdgePDF, [Switch]$Privacy
)
$ErrorActionPreference = 'SilentlyContinue'
Function Remove-AppxPackagesForSysprep {
    $AppXApps = @(

        #Unnecessary Windows 10 AppX Apps
        "*Microsoft.BingNews*"
        "*Microsoft.GetHelp*"
        "*Microsoft.Getstarted*"
        "*Microsoft.Messaging*"
        "*Microsoft.Microsoft3DViewer*"
        "*Microsoft.MicrosoftOfficeHub*"
        "*Microsoft.MicrosoftSolitaireCollection*"
        "*Microsoft.NetworkSpeedTest*"
        "*Microsoft.Office.OneNote*"
        "*Microsoft.Office.Sway*"
        "*Microsoft.OneConnect*"
        "*Microsoft.People*"
        "*Microsoft.Print3D*"
        "*Microsoft.SkypeApp*"
        "*Microsoft.StorePurchaseApp*"
        "*Microsoft.WindowsAlarms*"
        "*Microsoft.WindowsCamera*"
        "*microsoft.windowscommunicationsapps*"
        "*Microsoft.WindowsFeedbackHub*"
        "*Microsoft.WindowsMaps*"
        "*Microsoft.WindowsSoundRecorder*"
        "*Microsoft.Xbox.TCUI*"
        "*Microsoft.XboxApp*"
        "*Microsoft.XboxGameOverlay*"
        "*Microsoft.XboxIdentityProvider*"
        "*Microsoft.XboxSpeechToTextOverlay*"
        "*Microsoft.ZuneMusic*"
        "*Microsoft.ZuneVideo*"

        #Sponsored Windows 10 AppX Apps
        #Add sponsored/featured apps to remove in the "*AppName*" format
        "*EclipseManager*"
        "*ActiproSoftwareLLC*"
        "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
        "*Duolingo-LearnLanguagesforFree*"
        "*PandoraMediaInc*"
        "*CandyCrush*"
        "*Wunderlist*"
        "*Flipboard*"
        "*Twitter*"
        "*Facebook*"
        "*Spotify*"

        #Optional: Typically not removed but you can if you need to for some reason
        #"*Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe*"
        #"*Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe*"
        #"*Microsoft.BingWeather*"
        #"*Microsoft.MSPaint*"
        #"*Microsoft.MicrosoftStickyNotes*"
        #"*Microsoft.Windows.Photos*"
        #"*Microsoft.WindowsCalculator*"
        #"*Microsoft.WindowsStore*"
    )
    foreach ($App in $AppXApps) {
        Write-Verbose -Message ('Removing Package {0}' -f $App)
        Get-AppxPackage -Name $App | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $App | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

}

#This will run get-appxpackage | remove-appxpackage which is required for sysprep to provision the apps.
Function Begin-SysPrep {

    param([switch]$SysPrep)
    IF ($SysPrep) {
        Write-Verbose -Message ('Starting Sysprep Fixes')
        Write-Verbose -Message ('Removing AppXPackages for current user')
        get-appxpackage | remove-appxpackage -ErrorAction SilentlyContinue
        Remove-AppxPackagesForSysprep -ErrorAction SilentlyContinue
        # Disable Windows Store Automatic Updates
        Write-Verbose -Message "Adding Registry key to Disable Windows Store Automatic Updates"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        If (!(Test-Path $registryPath)) {
            Mkdir $registryPath -ErrorAction SilentlyContinue
            New-ItemProperty $registryPath -Name AutoDownload -Value 2 -ErrorAction SilentlyContinue
        }
        Else {
            Set-ItemProperty $registryPath -Name AutoDownload -Value 2 -ErrorAction SilentlyContinue
        }
        # Disable Microsoft Consumer Experience
        Write-Verbose -Message "Adding Registry key to prevent bloatware apps from returning"
        #Prevents bloatware applications from returning
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        If (!(Test-Path $registryPath)) {
            Mkdir $registryPath -ErrorAction SilentlyContinue
            New-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -ErrorAction SilentlyContinue
        }
        Else {
            Set-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -ErrorAction SilentlyContinue
        }
        #Stop WindowsStore Installer Service and set to Disabled
        Write-Verbose -Message ('Stopping InstallService')
        Stop-Service InstallService
        Write-Verbose -Message ('Setting InstallService Startup to Disabled')
        & sc config InstallService start=disabled
    }
}


Function Start-Debloat {

    param([switch]$Debloat)
    IF ($Debloat) {
        #Removes AppxPackages
        #Credit to Reddit user /u/GavinEke for a modified version of my whitelist code
        Write-Verbose -Message ('Starting Debloat')
        [regex]$WhitelistedApps = 'Microsoft.Paint3D|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.Windows.Photos|CanonicalGroupLimited.UbuntuonWindows'
        Get-AppxPackage -AllUsers | Where-Object {$_.Name -NotMatch $WhitelistedApps} | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -NotMatch $WhitelistedApps} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
}

Function Remove-Keys {

    Param([switch]$Debloat)
    if ($Debloat) {
        #Creates a PSDrive to be able to access the 'HKCR' tree
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
        #These are the registry keys that it will delete.

        $Keys = @(

            #Remove Background Tasks
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

            #Windows File
            "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"

            #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

            #Scheduled Tasks to delete
            "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"

            #Windows Protocol Keys
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

            #Windows Share Target
            "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        )

        #This writes the output of each key it is removing and also removes the keys listed above.
        ForEach ($Key in $Keys) {
            Write-Output "Removing $Key from registry"
            Remove-Item $Key -Recurse -ErrorAction SilentlyContinue
        }
    }
}

Function Protect-Privacy {

    Param([switch]$Privacy)
    if ($Privacy) {
        Write-Verbose -Message ('Starting Protect Privacy')
        #Creates a PSDrive to be able to access the 'HKCR' tree
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

        #Disables Windows Feedback Experience
        Write-Output "Disabling Windows Feedback Experience program"
        $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
        If (Test-Path $Advertising) {
            Set-ItemProperty $Advertising -Name Enabled -Value 0 -Verbose
        }

        #Stops Cortana from being used as part of your Windows Search Function
        Write-Output "Stopping Cortana from being used as part of your Windows Search Function"
        $Search = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
        If (Test-Path $Search) {
            Set-ItemProperty $Search -Name AllowCortana -Value 0 -Verbose
        }

        #Stops the Windows Feedback Experience from sending anonymous data
        Write-Output "Stopping the Windows Feedback Experience program"
        $Period1 = 'HKCU:\Software\Microsoft\Siuf'
        $Period2 = 'HKCU:\Software\Microsoft\Siuf\Rules'
        $Period3 = 'HKCU:\Software\Microsoft\Siuf\Rules\PeriodInNanoSeconds'
        If (!(Test-Path $Period3)) {
            mkdir $Period1 -ErrorAction SilentlyContinue
            mkdir $Period2 -ErrorAction SilentlyContinue
            mkdir $Period3 -ErrorAction SilentlyContinue
            New-ItemProperty $Period3 -Name PeriodInNanoSeconds -Value 0 -Verbose -ErrorAction SilentlyContinue
        }

        Write-Output "Adding Registry key to prevent bloatware apps from returning"
        #Prevents bloatware applications from returning
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        If (!(Test-Path $registryPath)) {
            Mkdir $registryPath -ErrorAction SilentlyContinue
            New-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -Verbose -ErrorAction SilentlyContinue
        }

        Write-Output "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
        $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'
        If (Test-Path $Holo) {
            Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 0 -Verbose
        }

        #Disables live tiles
        Write-Output "Disabling live tiles"
        $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
        If (!(Test-Path $Live)) {
            mkdir $Live -ErrorAction SilentlyContinue
            New-ItemProperty $Live -Name NoTileApplicationNotification -Value 1 -Verbose
        }

        #Turns off Data Collection via the AllowTelemtry key by changing it to 0
        Write-Output "Turning off Data Collection"
        $DataCollection = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
        If (Test-Path $DataCollection) {
            Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 0 -Verbose
        }

        #Disables People icon on Taskbar
        Write-Output "Disabling People icon on Taskbar"
        $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
        If (!(Test-Path $People)) {
            mkdir $People -ErrorAction SilentlyContinue
            New-ItemProperty $People -Name PeopleBand -Value 0 -Verbose
        }

        #Disables suggestions on start menu
        Write-Output "Disabling suggestions on the Start Menu"
        $Suggestions = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
        If (Test-Path $Suggestions) {
            Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 0 -Verbose
        }

        #Loads the registry keys/values below into the NTUSER.DAT file which prevents the apps from redownloading. Credit to a60wattfish
        reg load HKU\Default_User C:\Users\Default\NTUSER.DAT
        Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
        Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
        Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0
        reg unload HKU\Default_User

        #Disables scheduled tasks that are considered unnecessary
        Write-Output "Disabling scheduled tasks"
        Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask -ErrorAction SilentlyContinue
    }
}

Function Stop-EdgePDF {

    param([switch]$StopEdgePDF)
    IF ($StopEdgePDF) {
        Write-Verbose -Message ('Starting StopEdge PDF')
        #Stops edge from taking over as the default .PDF viewer
        Write-Output "Stopping Edge from taking over as the default .PDF viewer"
        $NoOpen = 'HKCR:\.pdf'
        If (!(Get-ItemProperty $NoOpen -Name NoOpenWith)) {
            New-ItemProperty $NoOpen -Name NoOpenWith -Verbose -ErrorAction SilentlyContinue
        }

        $NoStatic = 'HKCR:\.pdf'
        If (!(Get-ItemProperty $NoStatic -Name NoStaticDefaultVerb)) {
            New-ItemProperty $NoStatic -Name NoStaticDefaultVerb -Verbose -ErrorAction SilentlyContinue
        }

        $NoOpen = 'HKCR:\.pdf\OpenWithProgids'
        If (!(Get-ItemProperty $NoOpen -Name NoOpenWith)) {
            New-ItemProperty $NoOpen -Name NoOpenWith -Verbose -ErrorAction SilentlyContinue
        }

        $NoStatic = 'HKCR:\.pdf\OpenWithProgids'
        If (!(Get-ItemProperty $NoStatic -Name NoStaticDefaultVerb)) {
            New-ItemProperty $NoStatic -Name NoStaticDefaultVerb -Verbose -ErrorAction SilentlyContinue
        }

        $NoOpen = 'HKCR:\.pdf\OpenWithList'
        If (!(Get-ItemProperty $NoOpen -Name NoOpenWith)) {
            New-ItemProperty $NoOpen -Name NoOpenWith -Verbose -ErrorAction SilentlyContinue
        }

        $NoStatic = 'HKCR:\.pdf\OpenWithList'
        If (!(Get-ItemProperty $NoStatic -Name NoStaticDefaultVerb)) {
            New-ItemProperty $NoStatic -Name NoStaticDefaultVerb -Verbose -ErrorAction SilentlyContinue
        }

        #Appends an underscore '_' to the Registry key for Edge
        $Edge = 'HKCR:\AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723'
        If (Test-Path $Edge) {
            Set-Item $Edge AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723_ -Verbose
        }
    }
}

Function FixWhitelistedApps {

    Param([switch]$Debloat, [switch]$SysPrep)
    IF ($Debloat -or $SysPrep) {
        Write-Verbose -Message ('Starting Fix Whitelisted Apps')
        If (!(Get-AppxPackage -AllUsers | Select Microsoft.Paint3D, Microsoft.WindowsCalculator, Microsoft.WindowsStore, Microsoft.Windows.Photos)) {

            #Credit to abulgatz for the 4 lines of code
            Get-AppxPackage -allusers Microsoft.Paint3D | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
            Get-AppxPackage -allusers Microsoft.WindowsCalculator | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
            Get-AppxPackage -allusers Microsoft.WindowsStore | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
            Get-AppxPackage -allusers Microsoft.Windows.Photos | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
        }
    }
}

function clean-systemfiles{
function Delete-ComputerRestorePoints{
	[CmdletBinding(SupportsShouldProcess=$True)]param(  
	    [Parameter(
	        Position=0, 
	        Mandatory=$true, 
	        ValueFromPipeline=$true
		)]
	    $restorePoints
	)
	begin{
		$fullName="SystemRestore.DeleteRestorePoint"
		#check if the type is already loaded
		$isLoaded=([AppDomain]::CurrentDomain.GetAssemblies() | foreach {$_.GetTypes()} | where {$_.FullName -eq $fullName}) -ne $null
		if (!$isLoaded){
			$SRClient= Add-Type   -memberDefinition  @"
		    	[DllImport ("Srclient.dll")]
		        public static extern int SRRemoveRestorePoint (int index);
"@  -Name DeleteRestorePoint -NameSpace SystemRestore -PassThru
		}
	}
	process{
		foreach ($restorePoint in $restorePoints){
			if($PSCmdlet.ShouldProcess("$($restorePoint.Description)","Deleting Restorepoint")) {
		 		[SystemRestore.DeleteRestorePoint]::SRRemoveRestorePoint($restorePoint.SequenceNumber)
			}
		}
	}
}

Write-Host "Deleting System Restore Points"
	Get-ComputerRestorePoint | Delete-ComputerRestorePoints # -WhatIf

	Write-host "Checking to make sure you have Local Admin rights" -foreground yellow
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        Write-Warning "Please run this script as an Administrator!"
        If (!($psISE)){"Press any key to continue�";[void][System.Console]::ReadKey($true)}
        Exit 1
    }

Write-Host "Capture current free disk space on Drive C" -foreground yellow
    $FreespaceBefore = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB

Write-host "Deleting Rouge folders" -foreground yellow
    if (test-path C:\Config.Msi) {remove-item -Path C:\Config.Msi -force -recurse}
	if (test-path c:\Intel) {remove-item -Path c:\Intel -force -recurse}
	if (test-path c:\PerfLogs) {remove-item -Path c:\PerfLogs -force -recurse}
	# if (test-path c:\swsetup) {remove-item -Path c:\swsetup -force -recurse} # HP Software and Driver Repositry
    if (test-path $env:windir\memory.dmp) {remove-item $env:windir\memory.dmp -force}

Write-host "Deleting Windows Error Reporting files" -foreground yellow
    if (test-path C:\ProgramData\Microsoft\Windows\WER) {Get-ChildItem -Path C:\ProgramData\Microsoft\Windows\WER -Recurse | Remove-Item -force -recurse}

Write-host "Removing System and User Temp Files" -foreground yellow
    Remove-Item -Path "$env:windir\Temp\*" -Force -Recurse
    Remove-Item -Path "$env:windir\minidump\*" -Force -Recurse
    Remove-Item -Path "$env:windir\Prefetch\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Temp\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\WER\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatCache\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IECompatUaCache\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\IEDownloadHistory\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCache\*" -Force -Recurse
    Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Windows\INetCookies\*" -Force -Recurse
	Remove-Item -Path "C:\Users\*\AppData\Local\Microsoft\Terminal Server Client\Cache\*" -Force -Recurse

Write-host "Removing Windows Updates Downloads" -foreground yellow
    Stop-Service wuauserv -Force -Verbose
	Stop-Service TrustedInstaller -Force -Verbose
    Remove-Item -Path "$env:windir\SoftwareDistribution\*" -Force -Recurse
    Remove-Item $env:windir\Logs\CBS\* -force -recurse
    Start-Service wuauserv -Verbose
	Start-Service TrustedInstaller -Verbose

Write-host "Checkif Windows Cleanup exists" -foreground yellow
#Mainly for 2008 servers
	if (!(Test-Path c:\windows\System32\cleanmgr.exe)) {
	Write-host "Windows Cleanup NOT installed now installing" -foreground yellow
	copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr_31bf3856ad364e35_6.1.7600.16385_none_c9392808773cd7da\cleanmgr.exe $env:windir\System32
	copy-item $env:windir\winsxs\amd64_microsoft-windows-cleanmgr.resources_31bf3856ad364e35_6.1.7600.16385_en-us_b9cb6194b257cc63\cleanmgr.exe.mui $env:windir\System32\en-US
	}


Write-host "Running Windows System Cleanup" -foreground yellow
#Set StateFlags setting for each item in Windows disk cleanup utility
$StateFlags = 'StateFlags0013'
$StateRun = $StateFlags.Substring($StateFlags.get_Length()-2)
$StateRun = '/sagerun:' + $StateRun 
    if  (-not (get-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name $StateFlags)) {
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Temp Files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files' -name $StateFlags -type DWORD -Value 2
		set-itemproperty -path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -name $StateFlags -type DWORD -Value 2
    }

Write-host "Starting CleanMgr.exe.." -foreground yellow
    Start-Process -FilePath CleanMgr.exe -ArgumentList $StateRun  -WindowStyle Hidden -Wait

Write-host "Clearing All Event Logs" -foreground yellow
    wevtutil el | Foreach-Object {Write-Host "Clearing $_"; wevtutil cl "$_"}

Write-host "Disk Usage before and after cleanup" -foreground yellow
    $FreespaceAfter = (Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'" | select Freespace).FreeSpace/1GB
    "Free Space Before: {0}" -f $FreespaceBefore
    "Free Space After: {0}" -f $FreespaceAfter
}

function quick-printer{
    # This script works on Windows 8 or newer since the add-printer cmdlets are't available on Windows 7.
    
    # To find\extract the .inf file, run 7-zip on the print driver .exe and go to the folder in Powershell and run this command: get-childitem *.inf* |copy-item -destination "C:\examplefolder" Otherwise it's hard to find the .inf files.   
    $driver = Read-Host "Input the name of the driver here: "
    $address = Read-Host "Enter the IP or Port of the Printer here: "
    $name = Read-Host "Input the name of the Printer here: "
    $sleep = "3"
    $driverpath = Read-Host "Enter the path of the driver here: " 
    
    # The invoke command can be added to specify a remote computer by adding -computername. You would need to copy the .inf file to the remote computer first though. 
    # This script has it configured to run on the local computer that needs the printer.
    # The pnputil command imports the .inf file into the Windows driverstore. 
    # The .inf driver file has to be physically on the local or remote computer that the printer is being installed on.
    Invoke-Command {pnputil.exe -a $driverpath } -ErrorAction SilentlyContinue
    Add-PrinterDriver -Name $driver -ErrorAction SilentlyContinue
    start-sleep $sleep -ErrorAction SilentlyContinue
    
    # This creates the TCP\IP printer port. It also will not use the annoying WSD port type that can cause problems. 
    # WSD can be used by using a different command syntax though if needed.
    Add-PrinterPort -Name $address -PrinterHostAddress $address -ErrorAction SilentlyContinue
    start-sleep $sleep -ErrorAction SilentlyContinue
    Add-Printer -DriverName $driver -Name $name -PortName $address -ErrorAction SilentlyContinue
    start-sleep $sleep -ErrorAction SilentlyContinue
    
    # This prints a list of installed printers on the local computer. This proves the newly added printer works.
    get-printer |Out-Printer -Name $name 
}

function troublehsooter-menu
{
     param (
           [string]$Title = 'Troubleshooting Menu'
     )
     cls
     Write-Host "================ $Title ================"
     
     Write-Host "1: Power"
     Write-Host "2: Networking"
     Write-Host "3: Printers"
     Write-Host "4: Video"
     Write-Host "5: Performance"
     Write-Host "b: Press 'b' to go back."
     power-troubleshooter
}

function power-troubleshooter{
    do{
        Import-Module TroubleshootingPack
        $input = Read-Host "Which system would you like to troubleshoot: "
        switch ($input)
        {
            '1' {
                cls
                Get-TroubleshootingPack c:\windows\diagnostics\system\power | Invoke-TroubleshootingPack
            }
            '2' {
                cls
                Get-TroubleshootingPack c:\windows\diagnostics\system\networking | Invoke-TroubleshootingPack
            }
            '3' {
                cls
                Get-TroubleshootingPack c:\windows\diagnostics\system\printer | Invoke-TroubleshootingPack
            }
            '4' {
                cls
                Get-TroubleshootingPack c:\windows\diagnostics\system\video | Invoke-TroubleshootingPack
            }
            '5' {
                cls
                Get-TroubleshootingPack c:\windows\diagnostics\system\performance | Invoke-TroubleshootingPack
            }
            'b' {
                Show-Menu
            }
        }
    }
    until (input -eq 'p')
}

do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
             '1' {
                cls
                Show-Info
           } '2' {
                cls
                #Write-Output "Initiating Sysprep..."
                #Begin-SysPrep 
                Write-Output "Removing bloatware apps..."
                Start-Debloat 
                Write-Output "Removing leftover bloatware registry keys..."
                Remove-Keys 
                Write-Output "Checking to see if any Whitelisted Apps were removed, and if so re-adding them..."
                FixWhitelistedApps 
                Write-Output "Stopping telemetry, disabling unneccessary scheduled tasks, and preventing bloatware from returning..."
                Protect-Privacy 
                Write-Output "Stopping Edge from taking over as the default PDF Viewer..."
                Stop-EdgePDF 
                Write-Output "Cleaning up system files..."
                clean-systemfiles
                Write-Output "Scanning your PC for Malware..."
                Update-MpSignature
                Start-MpScan -ScanType QuickScan
                Remove-MpThreat
                Write-Output "Finished all tasks..."
                
           } '3' {
                cls
                quick-printer
           } '4' {
                cls
                troublehsooter-menu
           } '5' {
                cls
                DISM /Online /Cleanup-Image /RestoreHealth
           } '6' {
                cls
                sfc /scannow
           } 'b' {
                return
           }
     }
     pause
}
until ($input -eq 'q')

