# DTNS Live Roku Channel

A Roku channel for streaming Daily Tech News Show video episodes.

## Features
- Fetches and displays DTNS video feed (RSS).
- Simple navigation: episode list, description panel, video playback.
- Responsive UI with error handling.

## Architecture
```
channel/
  manifest
  components/
    FeedTask.brs/.xml
    MainScene.brs/.xml
  images/
    icon_focus_hd.png
    icon_side_hd.png
    splash_fhd.jpg
    splash_hd.jpg
    splash_uhd.jpg
  source/
    main.brs
```

## Asset Specs
- Channel icon (focus): 336x210 PNG
- Channel icon (side): 108x69 PNG
- Splash images: 1280x720 (HD), 1920x1080 (FHD), 3840x2160 (UHD)

## Usage
- Arrow keys: navigate episodes
- OK: play selected episode
- Back: return to episode list
- * (Options): reload feed

## Troubleshooting
- If icons do not appear, verify manifest entries and PNG sizes.
- If feed fails, check network and RSS URL.
- For long descriptions, UI may truncate.

## License / Attribution
- DTNS logo and content, except where otherwise noted, is licensed under a Creative Commons Attribution 4.0 International License. © Daily Tech News Show.
- Channel code: Except where otherwise noted, this is licensed under a Creative Commons Attribution 4.0 International License.

## Versioning
- Increment `build_version` in manifest for each update.

---
