# DTNSForRoku

A minimal Roku SceneGraph video channel that lists and plays Daily Tech News Show video episodes.

## Features
- Fetches DTNS video feed (RSS) on a Task thread (FeedTask).
- Parses titles, publication dates, descriptions, and first playable video URL (enclosure or media:content).
- Friendly date formatting with optional relative age.
- Simple navigation: list -> select -> playback. Back returns to list. * (Options) reloads feed.
- Lightweight UI (LabelList + detail panel + Video) following Roku sample patterns.

## Architecture
```
channel/
  manifest
  source/
    main.brs            ' App entry: creates MainScene
  components/
    MainScene.xml/.brs  ' UI logic
    FeedTask.xml/.brs   ' Background feed retrieval & parsing
  images/
    icon_focus_hd.png
    icon_side_hd.png
    splash_hd.jpg
    splash_fhd.jpg
    splash_uhd.jpg
```

## Icons & Splash (Roku Guidelines)
- Focus HD icon (recommended 336x210 PNG): images/icon_focus_hd.png
- Side HD icon (recommended 108x69 PNG): images/icon_side_hd.png
- (Reused for SD)
- Splash images: supply HD (1280x720), FHD (1920x1080), UHD (3840x2160) for crisp display.
Verify dimensions; adjust if different.

## Manifest Versioning
Increment build_version for every side-load to ensure device refresh:
```
major_version.minor_version (feature / minor changes)
build_version              (every package)
```

## Networking
- roUrlTransfer in Task to keep UI responsive.
- Add simple timeout/stall protection.
- User-Agent set to differentiate channel.

## Error Handling
- Task sets error field on: empty feed / parse failure / no items.
- MainScene observes result + error and updates status label.

## Future Enhancements (Optional)
- Relative date toggle or show both friendly + relative in date label.
- ScrollingLabel for very long descriptions.
- Playback resume (remember last position).
- Basic search/filter (client-side substring on titles).
- Caching feed for a short TTL to reduce requests when user re-opens.

## Build & Deploy
(Existing section retained; ensure deploy script increments build_version or prompt developer.)

## License / Attribution
- DTNS name/logo belong to Daily Tech News Show / respective owners.
- Provide attribution for artwork if required.
- This repository code: (add your license choice, e.g., MIT).

## Testing Checklist
- Side-load: channel shows icons on Home screen.
- Load: status "Loading..." then list populates (>0 items).
- Navigate list: date + description update.
- Select: video plays; Back returns.
- Press *: feed reload occurs.
- Network fail (disconnect) yields error message "* to retry".

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



## Project Objectives

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
  "deviceIP": "192.168.1.168",
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
.\tools\build_and_deploy.ps1 -DeviceIP 192.168.1.168 -Password your_dev_password
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