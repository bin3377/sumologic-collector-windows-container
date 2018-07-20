param([string]$AccessID, [string]$AccessKey)
if ($env:SUMO_ACCESS_ID_FILE -and (Test-Path $env:SUMO_ACCESS_ID_FILE -PathType Leaf)) {
  $env:SUMO_ACCESS_ID = Get-Content $env:SUMO_ACCESS_ID_FILE
}

if ($env:SUMO_ACCESS_KEY_FILE -and (Test-Path $env:SUMO_ACCESS_KEY_FILE -PathType Leaf)) {
  $env:SUMO_ACCESS_KEY = Get-Content $env:SUMO_ACCESS_KEY_FILE
}

if (-not $env:SUMO_GENERATE_USER_PROPERTIES) { $env:SUMO_GENERATE_USER_PROPERTIES = 'true' }
if (-not $env:SUMO_ACCESS_ID) { $env:SUMO_ACCESS_ID = $AccessID }
if (-not $env:SUMO_ACCESS_KEY) { $env:SUMO_ACCESS_KEY = $AccessKey }
if (-not $env:SUMO_RECEIVER_URL) { $env:SUMO_RECEIVER_URL = 'https://collectors.sumologic.com' }
if (-not $env:SUMO_COLLECTOR_NAME_PREFIX) { $env:SUMO_COLLECTOR_NAME_PREFIX = 'collector_container-' }
if (-not $env:SUMO_COLLECTOR_NAME) { $env:SUMO_COLLECTOR_NAME = hostname }
$env:SUMO_COLLECTOR_NAME = $env:SUMO_COLLECTOR_NAME_PREFIX + $env:SUMO_COLLECTOR_NAME
if (-not $env:SUMO_SOURCES_JSON) { $env:SUMO_SOURCES_JSON = 'sumo-sources.json' }
if (-not $env:SUMO_SYNC_SOURCES) { $env:SUMO_SYNC_SOURCES = 'false' }
if (-not $env:SUMO_COLLECTOR_EPHEMERAL) { $env:SUMO_COLLECTOR_EPHEMERAL = 'true' }

function New-UserProperties() {
  if (-not $env:SUMO_ACCESS_ID -or -not $env:SUMO_ACCESS_KEY) {
    Write-Error "FATAL: Please provide credentials, either via the SUMO_ACCESS_ID and SUMO_ACCESS_KEY environment variables,"
    Write-Error "       as the first two command line arguments,"
    Write-Error "       or in files references by SUMO_ACCESS_ID_FILE and SUMO_ACCESS_KEY_FILE!"
    exit 1
  }
  $TEMPLATE_FILES = @()
  if (Test-Path "$env:SUMO_SOURCES_JSON.tmpl" -PathType Leaf) {
    $TEMPLATE_FILES += "${env:SUMO_SOURCES_JSON}.tmpl"
  }
  if (Test-Path $env:SUMO_SOURCES_JSON -PathType Container) {
    Get-ChildItem $env:SUMO_SOURCES_JSON | ForEach-Object { $TEMPLATE_FILES += $_.FullName }
  }
  foreach ($from in $TEMPLATE_FILES) {
    $to = $from.SubString(0, $from.Length - 5)
    Convert-Template $from $to
  }

  if (-not (Test-Path $env:SUMO_SOURCES_JSON)) {
    Write-Error "FATAL: Unable to find $env:SUMO_SOURCES_JSON - please make sure you include it in your image!"
    exit 1
  }

  if ($env:SUMO_SYNC_SOURCES -eq 'true') {
    $env:SUMO_SYNC_SOURCES = $env:SUMO_SOURCES_JSON
    $env:SUMO_SOURCES_JSON = $null
  } else {
    $env:SUMO_SYNC_SOURCES = $null
  }

  # Supported user.properties configuration parameters
  # More information https://help.sumologic.com/Send_Data/Installed_Collectors/stu_user.properties
  $SUPPORTED_OPTIONS = @{
    "SUMO_ACCESS_ID"="accessid"
    "SUMO_ACCESS_KEY"="accesskey"
    "SUMO_RECEIVER_URL"="url"
    "SUMO_COLLECTOR_NAME"="name"
    "SUMO_SOURCES_JSON"="sources"
    "SUMO_SYNC_SOURCES"="syncSources"
    "SUMO_COLLECTOR_EPHEMERAL"="ephemeral"
    "SUMO_PROXY_HOST"="proxyHost"
    "SUMO_PROXY_PORT"="proxyPort"
    "SUMO_PROXY_USER"="proxyUser"
    "SUMO_PROXY_PASSWORD"="proxyPassword"
    "SUMO_PROXY_NTLM_DOMAIN" ="proxyNtlmDomain"
    "SUMO_CLOBBER"="clobber"
    "SUMO_DISABLE_SCRIPTS"="disableScriptSource"
    "SUMO_JAVA_MEMORY_INIT"="wrapper.java.initmemory"
    "SUMO_JAVA_MEMORY_MAX"="wrapper.java.maxmemory"
  }

  $target= "c:\collector\config\user.properties"
  Write-Output "INFO: Generating options in $target"
  if (Test-Path $target) {
    Remove-Item $target -Force
  }

  foreach ($key in $SUPPORTED_OPTIONS.Keys) {
    $val = Invoke-Expression ('Write-Output $env:' + $key)
    Invoke-Expression ('$env:' + $key + '=$null')
    if ($val) {
      $line = $SUPPORTED_OPTIONS[$key] + " = " + $val
      Write-Output "    $line"
      Add-Content -Force -Value $line -Path $target
    }
  }
  Add-Content -Force -Value "wrapper.debug=TRUE" -Path $target
}

function Convert-Template([string]$FromPath, [string]$ToPath) {
  Write-Output "INFO: Replacing environment variables from $FromPath into $ToPath"
  if (Test-Path $ToPath) {
    Remove-Item $ToPath -Force
  }
  $pattern = '\$\{(?<Name>.+)\}'
  foreach ($line in (Get-Content $FromPath)) {
    $out = $line
    if ($line -match $pattern) {
      $valName = $Matches.Name
      $valValue = Invoke-Expression ('Write-Output $env:' + $valName)
      $out = $line.Replace($Matches[0], $valValue)
      Write-Output "    FROM[$line]"
      Write-Output "      TO[$out]"
    }
    Add-Content -Force -Value $out -Path $ToPath
  }
}

if ($env:SUMO_GENERATE_USER_PROPERTIES) {
  New-UserProperties
}

Add-Content -Force -Value "docker.apiVersion=1.24" -Path "c:\collector\config\collector.properties"

& c:\collector\wrapper.exe -c c:\collector\config\wrapper.conf 
Get-Content -Wait c:\collector\logs\collector.log
