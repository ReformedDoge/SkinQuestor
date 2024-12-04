
# SkinQuestor - League of Legends Unowned Skins PowerShell Script


## Initial goal
The initial goal was to create a script that lists unowned skins available in the reroll pool. However, it became clear that this approach wasn’t feasible without messing with the client in a way that Riot likely prohibits.

Instead, this script provides a filtered list of unowned skins, categorizes them by price, and saves the results to a text file for easy reference (Will include some unobtainable skins)


## Features
- **Identifies unowned skins:** Finds skins that the player does not own
- **Categorizes by price:** Sorts skins into groups based on price (e.g., regular prices, skins available in the current Mythic Shop, BE Special items such as "150000 BE Urfwick," and unpurchasable skins).
- **Saves to a text file:** Allows the user to save the filtered list for easy viewing.


## How to Use
1. Ensure **League of Legends** is running.
2. Run the **PowerShell** script. (Right click and choose run with PowerShell)
3. The script will prompt you to select a save location for the output file.
4. Once the script finishes, your unowned skins, categorized by price, will be saved to the chosen text file.


## Requirements
- Windows OS with PowerShell and Curl (comes pre-installed with Windows).
- League of Legends client running since the script pulls data directly from the local League client’s LCU API.


## Why PowerShell?
PowerShell is the ideal choice for this script because it’s natively available on all modern Windows installations, meaning there’s no need for users to install external dependencies (like Python or Node.js).


## How it Works
The script operates entirely on your local network, ensuring that no data is exposed to the outside internet. Here's a high-level overview of how the script functions:

- **Check for League Process:** The script first checks if the League of Legends client is running.
- **Retrieve Process Information:** It fetches the command-line arguments of the League client to extract two critical values: `remoting-auth-token` and `app-port`, used for authenticating with the LCU API.
- **Connect to the LCU API:** With these values, the script connects to three key endpoints in the League of Legends client’s LCU API:
    - `/lol-summoner/v1/current-summoner`: This endpoint retrieves the current summoner’s data (used to fetch the summoner ID).
    - `/lol-champions/v1/inventories/{summonerId}/skins-minimal`: This endpoint provides a list of all skins that are owned and unowned by the player.
    - `/lol-catalog/v1/items/CHAMPION_SKIN`: This endpoint provides pricing information for all skins, which allows the script to categorize skins by price (e.g., regular skins, BE Special, Mythic Shop).

- **Data Filtering:** The script then filters the unowned skins and categorizes them based on their price and availability.
- **Output:** Finally, the script generates a categorized list and saves it to a text file chosen by the user.


## Output file Preview
```
Cost: 390
  Skin Name: SKIN_NAME

Cost: 520
  Skin Name: SKIN_NAME

Cost: 750
  Skin Name: SKIN_NAME

Cost: 975
  Skin Name: SKIN_NAME

Cost: 1350
  Skin Name: SKIN_NAME

Cost: 1820
  Skin Name: SKIN_NAME

Cost: 2775
  Skin Name: SKIN_NAME

Cost: 3250
  Skin Name: SKIN_NAME

Cost: 150000_BE
  Skin Name: SKIN_NAME

Cost: Mythic_Shop
  Skin Name: SKIN_NAME

Cost: Unpurchasable
  Skin Name: SKIN_NAME
```


## License

This project is licensed under the [CC BY-NC-ND 4.0 License](LICENSE). You are free to use and distribute the script for non-commercial purposes, with attribution to the original creator. Redistributions or modifications for commercial purposes are not permitted.

For more details, please refer to the [LICENSE](LICENSE) file.