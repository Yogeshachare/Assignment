import-module servermanager
add-windowsfeature web-server -includeallsubfeature
add-windowsfeature web-Asp-Net45
add-windowsfeature NET-Framework-Features
Set-Content -Path "C:\inetpub\wwwroot\Default.html" -Value "This is the server $($env:computername)"