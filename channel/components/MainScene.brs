sub init()
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")

    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoStateChanged")

    m.task = createObject("roSGNode", "FeedTask")
    m.task.observeField("result", "onFeedLoaded")
    m.task.control = "RUN"
end sub

sub onFeedLoaded()
    episodes = m.task.result
    if episodes = invalid or episodes.count() = 0 then return

    content = createObject("roSGNode", "ContentNode")
    for each ep in episodes
        item = createObject("roSGNode", "ContentNode")
        item.title = ep.title
        item.url = ep.url
        content.appendChild(item)
    end for

    m.episodes = episodes
    m.videoList.content = content
    m.videoList.setFocus(true)
end sub

sub onVideoSelected()
    idx = m.videoList.itemSelected
    if m.episodes = invalid or idx < 0 or idx >= m.episodes.count() then return

    ep = m.episodes[idx]
    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.title = ep.title
    videoContent.url = ep.url

    ' Infer stream format
    urlLower = lcase(ep.url)
    if right(urlLower, 4) = ".mp4"
        videoContent.streamFormat = "mp4"
    else if instr(1, urlLower, ".m3u8") > 0
        videoContent.streamFormat = "hls"
    else
        videoContent.streamFormat = "mp4" ' default
    end if

    m.videoList.visible = false
    m.videoPlayer.content = videoContent
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)
end sub

sub onVideoStateChanged()
    state = m.videoPlayer.state
    if state = "finished" or state = "error" or state = "stopped"
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