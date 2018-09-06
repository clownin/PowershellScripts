Dim shell,command
command = "powershell.exe -nologo -command ""dir C:\Users\Wes\Documents\PowershellScripts\OldFilesAlert.ps1\FolderWater2.ps1"""
Set shell = CreateObject("WScript.Shell")
shell.Run command,0