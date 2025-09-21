sub init()
    m.status = m.top.findNode("status")
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")

    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoStateChanged")

    m.task = createObject("roSGNode", "FeedTask")
    m.task.observeField("result", "onFeedLoaded")
    m.task.control = "RUN"
end sub

sub onFeedLoaded()
    eps = m.task.result
    if eps = invalid or eps.count() = 0
        if m.status <> invalid then m.status.text = "No videos found"
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
    return false
end function