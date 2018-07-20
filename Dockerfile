FROM microsoft/windowsservercore-insider    

ENV exe "https://collectors.sumologic.com/rest/download/win64"

SHELL ["powershell", "-Command"]

WORKDIR /collector

RUN Invoke-WebRequest -Uri $env:exe -OutFile collector.exe
RUN Start-Process -Wait -FilePath "collector.exe" \
  -ArgumentList "'-q', '-dir', 'C:\collector', '-VskipRegistration=true', '-Vsumo.accessid=x', '-Vsumo.accesskey=y', '-Dinstall4j.detailStdout=true', '-Dinstall4j.logToStderr=true', '-Dinstall4j.debug=true'"
RUN Remove-Item -Force collector.exe

COPY run.ps1 .

COPY sumo-sources.json .

ENTRYPOINT ["powershell", "-f", "./run.ps1"]