sub init()
    m.videoList   = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.status      = m.top.findNode("status")

    m.bg    = m.top.findNode("episodeDescBg")
    m.dateL = m.top.findNode("episodeDateLabel")
    m.div   = m.top.findNode("episodeDivider")
    m.descL = m.top.findNode("episodeDescPanel")

    m.lastIndex = -1

    m.videoList.observeField("content", "onFeedReady")
    m.videoList.observeField("itemFocused", "onFocusChanged")
    m.videoList.observeField("itemSelected", "onItemSelected")
    m.videoPlayer.observeField("state", "onVideoState")

    startFeed()
end sub

sub startFeed()
    m.status.visible = true
    m.status.text = "Loading..."
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
        n.description = ep.description    ' description only (date separate)
        if ep.dateFriendly <> invalid and ep.dateFriendly <> "" then
            n.releaseDate = ep.dateFriendly ' reuse built-in for date label
        end if
        root.appendChild(n)
    end for

    m.episodes = eps
    m.videoList.content = root
    m.videoList.visible = true
    m.status.visible = false
    if m.videoList.itemFocused = invalid then m.videoList.itemFocused = 0
    m.videoList.setFocus(true)
    m.lastIndex = -1
    updateDetails()
end sub

sub onFeedReady()
    ' no-op placeholder
end sub

sub onFocusChanged()
    updateDetails()
end sub

sub updateDetails()
    idx = m.videoList.itemFocused
    if idx = invalid or idx = m.lastIndex then return
    m.lastIndex = idx

    dateStr = ""
    desc = ""
    root = m.videoList.content
    if root <> invalid and idx >= 0 and idx < root.getChildCount() then
        node = root.getChild(idx)
        if node.doesExist("releaseDate") and node.releaseDate <> invalid then
            dateStr = node.releaseDate.tostr()
        end if
        if node.doesExist("description") and node.description <> invalid then
            desc = node.description.tostr()
        end if
    end if

    showPanel = (dateStr <> "" or desc <> "")
    m.bg.visible   = showPanel
    m.dateL.visible = (dateStr <> "")
    if m.dateL.visible then m.dateL.text = dateStr else m.dateL.text = ""
    m.div.visible  = (desc <> "" and dateStr <> "")
    m.descL.visible = (desc <> "")
    if m.descL.visible then m.descL.text = desc else m.descL.text = ""
end sub

sub onItemSelected()
    idx = m.videoList.itemSelected
    if idx = invalid or idx < 0 or idx >= m.episodes.count() then return
    playEpisode(idx)
end sub

sub playEpisode(i as integer)
    ep = m.episodes[i]
    c = createObject("roSGNode", "ContentNode")
    c.title = ep.title
    c.url   = ep.url
    lu = lcase(ep.url)
    if right(lu,5) = ".m3u8" then
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
        m.lastIndex = -1
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