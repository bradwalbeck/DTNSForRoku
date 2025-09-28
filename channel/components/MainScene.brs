sub init()
    m.videoList   = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.status      = m.top.findNode("status")

    m.bg    = m.top.findNode("episodeDescBg")
    m.dateL = m.top.findNode("episodeDateLabel")
    m.div   = m.top.findNode("episodeDivider")
    m.descL = m.top.findNode("episodeDescPanel")

    m.videoList.observeField("content", "onFeedContentSet")
    m.videoList.observeField("itemFocused", "onFocusChanged")
    m.videoList.observeField("itemSelected", "onItemSelected")
    m.videoPlayer.observeField("state", "onVideoState")

    sizeVideo()
    startFeed()
end sub

sub startFeed()
    m.status.visible = true
    m.status.text = "Loading…"
    m.videoList.visible = false
    if m.feedTask = invalid then
        m.feedTask = createObject("roSGNode", "FeedTask")
        m.feedTask.observeField("result", "onFeedResult")
    end if
    m.feedTask.control = "run"
end sub

sub onFeedResult()
    eps = m.feedTask.result
    if eps = invalid or eps.count() = 0 then
        m.status.visible = true
        m.status.text = "No episodes (* to retry)"
        return
    end if

    root = createObject("roSGNode", "ContentNode")
    for each ep in eps
        n = createObject("roSGNode", "ContentNode")
        n.title = ep.title
        n.url   = ep.url
        n.description = ep.description
        if ep.dateDisplay <> invalid and ep.dateDisplay <> "" then
            n.releaseDate = ep.dateDisplay
        end if
        root.appendChild(n)
    end for

    m.episodes = eps
    m.videoList.content = root
    m.videoList.visible = true
    m.status.visible = false
    if m.videoList.itemFocused = invalid or m.videoList.itemFocused < 0 then m.videoList.itemFocused = 0
    m.videoList.setFocus(true)
    updateDetails()
end sub

sub onFeedContentSet()
    ' kept empty intentionally (simplified)
end sub

sub onFocusChanged()
    updateDetails()
end sub

sub updateDetails()
    dt = "" : desc = ""
    root = m.videoList.content
    if root <> invalid then
        idx = m.videoList.itemFocused
        if idx <> invalid and idx >= 0 and idx < root.getChildCount() then
            node = root.getChild(idx)
            if node.doesExist("releaseDate") and node.releaseDate <> invalid then dt = node.releaseDate.tostr()
            if node.doesExist("description") and node.description <> invalid then desc = node.description.tostr()
        end if
    end if

    showPanel = (dt <> "" or desc <> "")
    m.bg.visible = showPanel
    m.dateL.visible = (dt <> "")
    if m.dateL.visible then m.dateL.text = dt else m.dateL.text = ""
    m.div.visible = (desc <> "" and dt <> "")
    m.descL.visible = (desc <> "")
    if m.descL.visible then m.descL.text = desc else m.descL.text = ""
end sub

sub onItemSelected()
    idx = m.videoList.itemSelected
    if idx = invalid then return
    if idx < 0 then return
    if idx >= m.episodes.count() then return
    playEpisode(idx)
end sub

sub playEpisode(i as integer)
    ep = m.episodes[i]
    c = createObject("roSGNode", "ContentNode")
    c.title = ep.title
    c.url   = ep.url
    u = lcase(ep.url)
    if right(u,4) = ".mp4" then
        c.streamFormat = "mp4"
    else if instr(1,u,".m3u8") > 0 then
        c.streamFormat = "hls"
    else
        c.streamFormat = "mp4"
    end if

    m.bg.visible = false
    m.dateL.visible = false
    m.div.visible = false
    m.descL.visible = false
    m.videoList.visible = false

    m.videoPlayer.content = c
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)
end sub

sub onVideoState()
    st = m.videoPlayer.state
    if st = "finished" or st = "stopped" or st = "error" then
        m.videoPlayer.visible = false
        m.videoList.visible = true
        m.videoList.setFocus(true)
        updateDetails()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back" and m.videoPlayer.visible then
        m.videoPlayer.control = "stop"
        return true
    else if key = "options" and (not m.videoPlayer.visible) then
        startFeed()
        return true
    end if
    return false
end function

sub sizeVideo()
    di = createObject("roDeviceInfo")
    ui = di.getUIResolution()
    if ui <> invalid then
        m.videoPlayer.translation = [0,0]
        m.videoPlayer.width  = ui.width
        m.videoPlayer.height = ui.height
    else
        m.videoPlayer.width = 1920
        m.videoPlayer.height = 1080
    end if
end sub