sub init()
    m.status = m.top.findNode("status")
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")

    fitVideoToUI()  ' ensure perfect fit on HD/FHD/UHD

    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoStateChanged")

    startFeedLoad()
end sub

' Size the Video node to the active UI coordinate space
sub fitVideoToUI()
    di = createObject("roDeviceInfo")
    ui = di.GetUIResolution()  ' { name: "hd" | "fhd" | "uhd", width: int, height: int }
    m.videoPlayer.translation = [0, 0]
    if ui <> invalid
        m.videoPlayer.width = ui.width
        m.videoPlayer.height = ui.height
    else
        ' Fallback
        m.videoPlayer.width = 1920
        m.videoPlayer.height = 1080
    end if
end sub

sub startFeedLoad()
    if m.status <> invalid then
        m.status.visible = true
        m.status.text = "Loading DTNS… (Press * to refresh)"
    end if
    m.videoList.visible = false

    if m.task <> invalid then m.task.control = "stop"
    m.task = createObject("roSGNode", "FeedTask")
    m.task.observeField("result", "onFeedLoaded")
    m.task.control = "RUN"
end sub

sub onFeedLoaded()
    eps = m.task.result
    if eps = invalid or eps.count() = 0
        if m.status <> invalid then
            m.status.visible = true
            m.status.text = "No videos found (Press * to refresh)"
        end if
        return
    end if

    listContent = createObject("roSGNode", "ContentNode")
    for i = 0 to eps.count() - 1
        ep = eps[i]
        item = createObject("roSGNode", "ContentNode")
        item.title = ep.title
        item.url = ep.url
        listContent.appendChild(item)
    end for

    m.episodes = eps
    if m.status <> invalid then m.status.visible = false
    m.videoList.content = listContent
    m.videoList.visible = true
    m.videoList.setFocus(true)
end sub

sub onVideoSelected()
    idx = m.videoList.itemSelected
    if m.episodes = invalid or idx < 0 or idx >= m.episodes.count() then return

    ep = m.episodes[idx]
    content = createObject("roSGNode", "ContentNode")
    content.title = ep.title
    content.url = ep.url

    u = lcase(ep.url)
    if right(u, 4) = ".mp4"
        content.streamFormat = "mp4"
    else if instr(1, u, ".m3u8") > 0
        content.streamFormat = "hls"
    else
        content.streamFormat = "mp4"
    end if

    m.videoList.visible = false
    m.videoPlayer.content = content
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)
end sub

sub onVideoStateChanged()
    st = m.videoPlayer.state
    if st = "finished" or st = "error" or st = "stopped"
        m.videoPlayer.visible = false
        m.videoList.visible = true
        m.videoList.setFocus(true)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if key = "back" and m.videoPlayer.visible
        m.videoPlayer.control = "stop"
        return true
    end if

    ' Options (*) to refresh when not playing
    if key = "options" and not m.videoPlayer.visible
        startFeedLoad()
        return true
    end if

    return false
end function