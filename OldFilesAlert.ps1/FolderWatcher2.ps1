$limit = (Get-Date).AddDays(1)
$path = Get-ChildItem -Path c:\scripts\test;

$oldFiles = Get-ChildItem -Path c:\scripts\test -Recurse -Force | Where-Object { $_.CreationTime -lt $limit }  
if (!$oldFiles) { 
    exit
}
$password = Get-Content C:\scripts\cred.txt | ConvertTo-SecureString
$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist "wesleyroxmysoxoff@gmail.com",$password
$From = "wesleyroxmysoxoff@gmail.com"
$To = "wmcvicar@email.itt-tech.edu"
#$Cc = ""
#$Attachment = "C:\temp\Some random file.txt"
$Subject = "Test Email"
$Body = "There are files older than a day on this server."
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
-Credential $credentials
exit
