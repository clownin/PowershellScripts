$password = Get-Content C:\scripts\cred.txt | ConvertTo-SecureString
$credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist "wesleyroxmysoxoff@gmail.com",$password
$From = "wesleyroxmysoxoff@gmail.com"
$To = "wmcvicar@email.itt-tech.edu"
#$Cc = ""
#$Attachment = "C:\temp\Some random file.txt"
$Subject = "Test Email"
$Body = "This is a test. Please ignore."
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
Send-MailMessage -From $From -to $To -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
-Credential $credentials