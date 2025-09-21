# DTNSForRoku
DTNSForRoku is a streaming video channel for the [Roku® streaming players as well as Roku TVs™](https://www.roku.com/) that provides the [Daily Tech News Show](http://www.dailytechnewsshow.com/). 


[Get DTNS for Roku, NOW!](https://my.roku.com/add/DTNS)

[Read about DTNS For Roku](https://channelstore.roku.com/details/86190/dtns)


## Daily Tech News Show
Daily Tech News Show is hosted by Tom Merritt and Sarah Lane and does what it says in the name. Each show delivers the top stories in tech combined with analysis from regular contributors and guest perspectives from the top names in technology.


## Support Daily Tech News Show

Please [SUBSCRIBE HERE](http://feeds.feedburner.com/DailyTechNewsShow)

[DTNS official subreddit](http://feeds.feedburner.com/DailyTechNewsShow) 

[IRC chatroom for DTNS](http://irc.chatrealm.net/)

[Daily Tech News Show on DCTVpedia](http://dctvpedia.com/Daily_Tech_News_Show)

[Buy cool DTNS merch!](http://dtns.bigcartel.com/)


## Feedback about DTNS For Roku? 
[Send a message](mailto:feedback+github@welloiledapps.com)


project objectives:

Build a minimal Roku SceneGraph video channel that compiles and runs without errors.
Use only the DTNS RSS feed: https://feeds.feedburner.com/daily_tech_news_show.
Fetch the feed on a Task thread (roUrlTransfer in a Task component) per Roku docs.
Parse the RSS XML robustly and extract only video URLs (mp4/HLS) from:
    enclosure elements with video types or .mp4
    media:content (and media:group/media:content) if present
Display the episodes as a simple list (LabelList) showing titles.
Allow the user to select an episode and play it in a Video node.
Support basic navigation: back exits playback and returns to the list.
Handle empty/error cases gracefully (status label/logging), with minimal logging noise.
Keep the code aligned with Roku sample channel patterns and best practices.
Acceptance: channel installs, loads episode list (>0 items), selects, and plays a DTNS video successfully.

## Build & Deploy (Windows)

Prerequisites
- Roku device in Developer Mode (Development Application Installer enabled)
- Device IP, username (rokudev), and password
- PowerShell 5+ (Windows 10/11 includes curl.exe)

Config (create at project root)
- File: deploy.config.json
```json
{
  "deviceIP": "10.210.1.254",
  "username": "rokudev",
  "password": "your_dev_password"
}
```

Build and deploy
- From the repo root:
```powershell
.\tools\build_and_deploy.ps1
```
- Override config values if needed:
```powershell
.\tools\build_and_deploy.ps1 -DeviceIP 10.210.1.254 -Password your_dev_password
```

Execution policy
- If scripts are blocked:
```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\tools\build_and_deploy.ps1
```

Troubleshooting
- Verify the installer is reachable: http://<deviceIP>/plugin_install
- Ensure deploy.config.json is at the project root
- If authentication fails, re-enter the device password on the Roku (Developer Settings)
- The script uses curl with Digest auth; it will fall back to PowerShell if needed