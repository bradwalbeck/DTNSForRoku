sub init()
    m.videoList   = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.status      = m.top.findNode("status")

    m.bg    = m.top.findNode("episodeDescBg")
    m.dateL = m.top.findNode("episodeDateLabel")
    m.div   = m.top.findNode("episodeDivider")
    m.descL = m.top.findNode("episodeDescPanel")

    if m.videoList <> invalid then
        m.videoList.observeField("content", "onListContent")
        m.videoList.observeField("itemFocused", "onFocusChanged")
        m.videoList.observeField("itemSelected", "onItemSelected")
    end if
    if m.videoPlayer <> invalid then
        m.videoPlayer.observeField("state", "onVideoState")
        sizeVideo()
    end if

    startFeed()
end sub

sub startFeed()
    if m.status <> invalid then
        m.status.visible = true
        m.status.text = "Loading…"
    end if
    if m.videoList <> invalid then m.videoList.visible = false

    if m.feedTask = invalid then
        m.feedTask = createObject("roSGNode", "FeedTask")
        m.feedTask.observeField("result", "onFeedResult")
        ' optional: m.feedTask.url = "custom feed"
    end if
    m.feedTask.control = "run"
end sub

sub onFeedResult()
    eps = m.feedTask.result
    if eps = invalid or eps.count() = 0 then
        if m.status <> invalid then
            m.status.visible = true
            m.status.text = "No episodes (Press * to retry)"
        end if
        return
    end if

    root = createObject("roSGNode", "ContentNode")
    for i = 0 to eps.count() - 1
        ep = eps[i]
        n = createObject("roSGNode", "ContentNode")
        if ep.title <> invalid then n.title = ep.title
        if ep.url <> invalid then n.url = ep.url
        if ep.description <> invalid then
            n.description = ep.description
            n.shortDescriptionLine2 = ep.description
        end if
        if ep.pubDateFriendly <> invalid and ep.pubDateFriendly <> "" then
            n.releaseDate = ep.pubDateFriendly
        else if ep.pubDateShort <> invalid and ep.pubDateShort <> "" then
            n.releaseDate = ep.pubDateShort
        else if ep.pubDate <> invalid and ep.pubDate <> "" then
            n.releaseDate = ep.pubDate
        end if
        root.appendChild(n)
    end for

    m.episodes = eps
    m.videoList.content = root
    m.videoList.visible = true
    if m.status <> invalid then m.status.visible = false
    if m.videoList.itemFocused = invalid or m.videoList.itemFocused < 0 then
        m.videoList.itemFocused = 0
    end if
    m.videoList.setFocus(true)
    updateDetails()
end sub

sub onListContent()
    ' not heavily needed; placeholder if dynamic changes happen
end sub

sub onFocusChanged()
    updateDetails()
end sub

sub updateDetails()
    hide = true
    dt = "" : desc = ""

    if m.videoList <> invalid then
        root = m.videoList.content
        if root <> invalid then
            idx = m.videoList.itemFocused
            if idx <> invalid and idx >= 0 and idx < root.getChildCount() then
                node = root.getChild(idx)
                if node <> invalid then
                    if node.doesExist("releaseDate") and node.releaseDate <> invalid then
                        dt = node.releaseDate.tostr()
                    end if
                    if node.doesExist("description") and node.description <> invalid then desc = node.description.tostr()
                    if desc = "" and node.doesExist("shortDescriptionLine2") and node.shortDescriptionLine2 <> invalid then desc = node.shortDescriptionLine2.tostr()
                end if
            end if
        end if
    end if

    hide = (dt = "" and desc = "")

    if m.bg    <> invalid then m.bg.visible    = not hide
    if m.dateL <> invalid then
        m.dateL.visible = (dt <> "")
        if m.dateL.visible then m.dateL.text = dt else m.dateL.text = ""
    end if
    if m.div   <> invalid then m.div.visible   = (desc <> "" and (dt <> ""))
    if m.descL <> invalid then
        m.descL.visible = (desc <> "")
        if m.descL.visible then m.descL.text = desc else m.descL.text = ""
    end if
end sub

sub onItemSelected()
    idx = m.videoList.itemSelected
    if m.episodes = invalid or idx = invalid or idx < 0 or idx >= m.episodes.count() then return
    playEpisode(idx)
end sub

sub playEpisode(i as integer)
    ep = m.episodes[i]
    c = createObject("roSGNode", "ContentNode")
    c.title = ep.title
    c.url = ep.url
    u = lcase(ep.url)
    if right(u,4) = ".mp4" then
        c.streamFormat = "mp4"
    else if instr(1,u,".m3u8") > 0 then
        c.streamFormat = "hls"
    else
        c.streamFormat = "mp4"
    end if

    ' hide detail panel while playing
    if m.bg <> invalid then m.bg.visible = false
    if m.dateL <> invalid then m.dateL.visible = false
    if m.div <> invalid then m.div.visible = false
    if m.descL <> invalid then m.descL.visible = false

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
        m.videoPlayer.width = ui.width
        m.videoPlayer.height = ui.height
    else
        m.videoPlayer.width = 1920
        m.videoPlayer.height = 1080
    end if
end sub