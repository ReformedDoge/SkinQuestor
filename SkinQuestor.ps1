# Add required assembly for Forms (for save file popup)
Add-Type -AssemblyName "System.Windows.Forms"

# Get the width of the PowerShell window
$width = $host.UI.RawUI.WindowSize.Width

# Function to center text with color
function Center-Text {
    param (
        [string]$text,
        [ValidateSet("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")]
        [string]$color = "White"
    )
    $padding = [math]::Floor(($width - $text.Length) / 2)
    Write-Host (' ' * $padding + $text) -ForegroundColor $color
}

# Display introductory message in PowerShell window
Center-Text ("=" * $width) White
Center-Text "Welcome to the SkinQuestor Script!" Cyan
Center-Text ("=" * $width) White
Center-Text "Script created by github.com/ReformedDoge" Green
Center-Text "Up-to-date repository at: [https://github.com/ReformedDoge/SkinQuestor]" Yellow
Center-Text ("=" * $width) White

# Informational text
Write-Host "League of Legends Unowned Skins PowerShell filter script."
Write-Host "It will categorize unowned skins by their prices and save the list for you."
Write-Host "Please ensure League of Legends is running before proceeding."

# Prompt user for action
$input = Read-Host "Press '1' to start or '0' to exit"

# Get League client process
$leagueProcess = Get-Process -Name "LeagueClientUx" -ErrorAction SilentlyContinue

if ($input -eq '1') {
    if ($null -ne $leagueProcess) {
        Write-Host "Found League client process: $($leagueProcess.Name), PID: $($leagueProcess.Id)"
        
        # Get command line arguments of the League client process using WMI
        $process = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($leagueProcess.Id)"
        
        if ($null -ne $process) {
            Write-Host "Successfully retrieved process information."
            
            # Extract the command line arguments from retrieved process information
            $arguments = $process.CommandLine
            
            # regex "remoting-auth-token" and "app-port"
            $remotingAuthTokenMatch = [regex]::Match($arguments, '--remoting-auth-token=([^\s]+)')
            $appPortMatch = [regex]::Match($arguments, '--app-port=(\d+)')
            
            if ($remotingAuthTokenMatch.Success) {
                $remotingAuthToken = $remotingAuthTokenMatch.Groups[1].Value.Trim('"') # Trim any surrounding quotes
                } else {
                Write-Host "Failed to find remoting-auth-token in the process arguments."
            }
            
            if ($appPortMatch.Success) {
                $appPort = $appPortMatch.Groups[1].Value
                } else {
                Write-Host "Failed to find app-port in the process arguments."
            }
            
            if ($remotingAuthToken -and $appPort) {
                Write-Host "Successfully found the necessary arguments."
                
                # authorization string creation
                $authString = "riot:$remotingAuthToken"
                
                # Base64 encode the authorization token string
                $encodedAuthString = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($authString))
                
                # Get Summoner ID using curl because Invoke-RestMethod and other native powershell commands fail tls for some odd reason
                $uriSummoner = "https://127.0.0.1:$appPort/lol-summoner/v1/current-summoner"
                $curlCommandSummoner = 'curl.exe -X GET "' + $uriSummoner + '" -H "Authorization: Basic ' + $encodedAuthString + '" --insecure -s'
                $responseSummoner = Invoke-Expression $curlCommandSummoner
                $summonerData = $responseSummoner | ConvertFrom-Json
                $summonerId = $summonerData.summonerId
                
                # Get skins data using curl because Invoke-RestMethod and other native powershell commands fail tls for some odd reason
                $uriSkinsMinimal = "https://127.0.0.1:$appPort/lol-champions/v1/inventories/$summonerId/skins-minimal"
                $curlCommandSkinsMinimal = 'curl.exe -X GET "' + $uriSkinsMinimal + '" -H "Authorization: Basic ' + $encodedAuthString + '" --insecure -s'
                $responseSkinsMinimal = Invoke-Expression $curlCommandSkinsMinimal
                $skinsMinimalData = $responseSkinsMinimal | ConvertFrom-Json
                
                # Get the Champion Skins pricing data using curl because Invoke-RestMethod and other native powershell commands fail tls for some odd reason
                $uriChampionSkin = "https://127.0.0.1:$appPort/lol-catalog/v1/items/CHAMPION_SKIN"
                $curlCommandChampionSkin = 'curl.exe -X GET "' + $uriChampionSkin + '" -H "Authorization: Basic ' + $encodedAuthString + '" --insecure -s'
                $responseChampionSkin = Invoke-Expression $curlCommandChampionSkin
                $championSkinsData = $responseChampionSkin | ConvertFrom-Json
                
                # Create a hashtable to map skin IDs to prices
                $skinPriceMapping = @{ }
                foreach ($skin in $championSkinsData) {
                    if ($skin.prices.Count -gt 0) {
                        if ($skin.prices[0].cost -eq 150000) {
                            $skinPriceMapping[$skin.itemId] = "150000_BE"
                            } elseif ($skin.prices[0].cost -ne 150000) {
                            $skinPriceMapping[$skin.itemId] = $skin.prices[0].cost
                        }
                        } else {
                        $skinPriceMapping[$skin.itemId] = "Mythic_Shop"
                    }
                }
                
                # Filter skins from skins-minimal data where they are not in Champion Skins (aka unpurchasable skins)
                $filteredSkinsMinimal = $skinsMinimalData | Where-Object { $_.isBase -eq $false -and $_.ownership.owned -eq $false }
                $unpurchasableSkins = $filteredSkinsMinimal | Where-Object { -not $skinPriceMapping.ContainsKey($_.id) }
                
                # Separate out purchasable skins
                $purchasableSkins = $filteredSkinsMinimal | Where-Object { $skinPriceMapping.ContainsKey($_.id) }
                
                # Sort the skins by their price, using price mapping
                $sortedSkins = $purchasableSkins | Sort-Object {
                    if ($skinPriceMapping[$_.id] -eq "Mythic_Shop") {
                        [int]::MaxValue
                        } elseif ($skinPriceMapping[$_.id] -eq "150000_BE") {
                        150000
                        } else {
                        $skinPriceMapping[$_.id]
                    }
                }
                
                Write-Host "Total Missing Purchasable Skins Count: $($sortedSkins.Count)"
                Write-Host "Total Missing Skins Count: $($unpurchasableSkins.Count + $sortedSkins.Count)"
                
                # Group the skins by their cost
                $groupedSkins = $sortedSkins | Group-Object -Property {
                    if ($skinPriceMapping[$_.id] -eq "Mythic_Shop") {
                        "Mythic_Shop"
                        } elseif ($skinPriceMapping[$_.id] -eq "150000_BE") {
                        "150000_BE"
                        } else {
                        $skinPriceMapping[$_.id]
                    }
                }
                
                # Prompt user to choose save file location
                $fileDialog = New-Object Windows.Forms.SaveFileDialog
                $fileDialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
                $fileDialog.Title = "Save Filtered Skins List"
                Write-Host "Please pick a save file location!"
                # Show the save file popup dialog form
                $dialogResult = $fileDialog.ShowDialog()
                
                if ($dialogResult -eq [Windows.Forms.DialogResult]::OK) {
                    # file path from the dialog popup save file dialog form
                    $filePath = $fileDialog.FileName
                    
                    $output = ""
                    
                    # Output grouped skins by cost first
                    foreach ($group in $groupedSkins) {
                        $output += "Cost: $($group.Name)`r`n"
                        $group.Group | ForEach-Object {
                            #$output += " Skin ID: $($_.id), Skin Name: $($_.name), Price: $($skinPriceMapping[$_.id])`r`n"
                            $output += " Skin Name: $($_.name)`r`n"
                        }
                        $output += "`r`n" # blank line between each price category
                    }
                    
                    # Add the unpurchasable skins last
                    $output += "Cost: Unpurchasable`r`n"
                    $unpurchasableSkins | ForEach-Object {
                        #$output += " Skin ID: $($_.id), Skin Name: $($_.name), Price: Unpurchasable`r`n"
                        $output += " Skin Name: $($_.name)`r`n"
                    }
                    
                    # Remove the trailing blank line <will figure a better formating later/ can't be bothered rn>
                    $output = $output.TrimEnd("`r`n")
                    # Save the data to the selected file
                    try {
                        Set-Content -Path $filePath -Value $output
                        Write-Host "Filtered skins saved to: $filePath"
                        } catch {
                        Write-Host "Failed to save file: $_"
                    }
                    } else {
                    Write-Host "No file selected. Skins not saved."
                }
                
                } else {
                Write-Host "Failed to find remoting-auth-token or app-port in the process arguments."
            }
            } else {
            Write-Host "Failed to retrieve process information using WMI."
        }
        } else {
        Write-Host "League of Legends client is not running."
    }
}

else {
    Write-Host "Exiting script."
    Exit
}