# 1. Check if the required environment variable is set.
# In PowerShell, environment variables should be accessed with the $env: prefix.
if ([string]::IsNullOrEmpty($JSONBINKEY)) {
    Write-Host "JSONBINKEY environment variable is not set."
    exit 1
}
Write-Host "JSONBINKEY environment variable is set to $JSONBINKEY"

# 2. Make a web request to get the URL from the JSON response.
# A try-catch block is used to handle potential errors during the request.
try {
    # Invoke-RestMethod automatically handles the request and parses the JSON.
    $response = Invoke-RestMethod -Uri "https://jsonbin.1248369.xyz/proxy/cf/?key=$JSONBINKEY"
    $url = $response.url
} catch {
    # If the web request fails, print the error and ensure $url is null.
    Write-Host "Failed to retrieve or parse URL. Error: $_"
    $url = $null
}


# 3. If the URL could not be retrieved, exit gracefully.
if ([string]::IsNullOrEmpty($url)) {
    Write-Host "URL variable is empty, exiting."
    exit 0
}

# 4. Find and forcefully terminate any existing 'gost' processes
# that are listening on the same port.
# We make the search pattern more specific to match the original script.
$existingProcesses = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*gost -L=:38083*' }

if ($existingProcesses) {
    $existingProcesses | ForEach-Object {
        Write-Host "Stopping existing gost process with PID: $($_.ProcessId)"
        Stop-Process -Id $_.ProcessId -Force
    }
}

# 5. Display the retrieved URL.
Write-Host "url: $url"

# The here-string will automatically replace $($url) with the variable's value
$yamlContent = @"
services:
- name: service-0
  addr: ":38083"
  handler:
    type: http
    chain: chain-0
  listener:
    type: tcp

chains:
  - name: chain-0
    hops:
      - name: hop-0
        nodes:
          - name: node-0
            addr: $($url):443
            connector:
              type: http
            dialer:
              type: mwss
        metadata:
          keepAlive: 1
          enableCompression: true
"@

# Write the dynamic content to the file
Set-Content -Path "$PWD\config.yml" -Value $yamlContent

# 6. Execute the gost command with the correctly formed argument.
# We now use the variable for the -F flag and match the original script's syntax (-L=:...).
# The '&' (call operator) is good practice for executing commands with paths/quotes.
& "$PWD\gost.exe" -C  "$PWD\config.yaml"
