#
#
#
#﻿
### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = "Y:\CONSUMER\PRODUCTION\Manual Work\Faxes"
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

### DEFINE ACTIONS AFTER A EVENT IS DETECTED
    $action = { $path = $Event.SourceEventArgs.FullPath
                $changeType = $Event.SourceEventArgs.ChangeType
                $logline = "$(Get-Date), $changeType, $path"
                Add-content "C:\log.txt" -value $logline
              }
### DECIDE WHICH EVENTS SHOULD BE WATCHED + SET CHECK FREQUENCY  
    $created = Register-ObjectEvent $watcher "Created" -Action $prompt
    $changed = Register-ObjectEvent $watcher "Changed" -Action $action
    $deleted = Register-ObjectEvent $watcher "Deleted" -Action $action
    $renamed = Register-ObjectEvent $watcher "Renamed" -Action $action
    while ($true) {Start-sleep 900}