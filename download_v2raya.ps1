# Define an array of objects, where each object contains the URL and the desired destination filename.
$outout_dir="./config"

if ( -not (Test-Path "$outout_dir")) {
    Write-Host "Create outout_dir: $outout_dir"
    mkdir $outout_dir
}else{
    Write-Host "Find existing outout_dir: $outout_dir"
}


$downloadItems = @(
    @{ Url = "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"; Destination = ".\$outout_dir\geoip.dat" }
    @{ Url = "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"; Destination = ".\$outout_dir\geosite.dat" }
    @{ Url = "https://github.com/v2rayA/v2rayA/releases/download/v2.2.6.7/v2raya_windows_x64_2.2.6.7.exe"; Destination = ".\v2raya.exe" }
    @{ Url = "https://github.com/v2fly/v2ray-core/releases/download/v5.38.0/v2ray-linux-64.zip"; Destination = ".\v2ray.zip" }
)

# Loop through each item and download it

foreach ($item in $downloadItems) {
    $sourceUrl = $item.Url
    $destinationPath = $item.Destination

    # Check if the file already exists. If it does, remove it before downloading the new one.
    if (Test-Path $destinationPath) {
        # Write-Host "Removing existing file: $destinationPath"
        # Remove-Item -Path $destinationPath -Force -ErrorAction SilentlyContinue

        Write-Host "Find existing file: $destinationPath"

    }else{
        Write-Host "Downloading '$($item.Destination)' from '$sourceUrl'..."
    try {
        Invoke-WebRequest -Uri $sourceUrl -OutFile $destinationPath -ErrorAction Stop
        Write-Host "Successfully downloaded '$($item.Destination)'."
    } catch {
        Write-Error "Failed to download '$($item.Destination)'. Error: $($_.Exception.Message)"
    }
    
    }


}

Write-Host "All downloads complete."
if ( -not (Test-Path ".\v2ray")) {
    Expand-Archive -Path ".\v2ray.zip" -DestinationPath ".\v2ray"
}else{
    Write-Host "Find existing file: v2ray"
}

Set-Content -Path "$PWD\run_v2ray.ps1" -Value "$PWD\v2raya.exe --lite --v2ray-bin $PWD\v2ray\v2ray.exe -c $PWD\config"
Write-Host "Run $PWD\run_v2ray.ps1 on powershell"
