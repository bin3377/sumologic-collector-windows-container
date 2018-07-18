FROM microsoft/windowsservercore

RUN powershell -Command `
    (New-Object System.Net.WebClient).DownloadFile('https://collectors.sumologic.com/rest/download/win64', 'C:\collector.exe') ; `
    Start-Process -filepath C:\collector.exe -wait -argumentlist "-q,-dir,C:\collector,-VskipRegistration=true,-Dinstall4j.detailStdout=true,-Dinstall4j.logToStderr=true,-Dinstall4j.debug=true" ; `
    del C:\collector.exe

WORKDIR C:\collector

COPY run.ps1 C:\collector\run.ps1
COPY sumo-sources.json C:\collector\sumo-sources.json
ENTRYPOINT ["powershell", "c:\collector\run.ps1"]