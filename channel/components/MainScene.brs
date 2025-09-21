sub init()
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    
    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoStateChanged")
    
    ' Create and start task
    m.task = createObject("roSGNode", "FeedTask")
    m.task.observeField("result", "onFeedLoaded")
    m.task.control = "RUN"
end sub

sub onFeedLoaded()
    videos = m.task.result
    
    if videos <> invalid and videos.count() > 0
        contentNode = createObject("roSGNode", "ContentNode")
        
        for each video in videos
            itemNode = createObject("roSGNode", "ContentNode")
            itemNode.title = video.title
            itemNode.url = video.url
            contentNode.appendChild(itemNode)
        end for
        
        m.videoList.content = contentNode
        m.videos = videos
    end if
end sub

sub onVideoSelected()
    index = m.videoList.itemSelected
    if index >= 0 and m.videos <> invalid and index < m.videos.count()
        video = m.videos[index]
        
        videoContent = createObject("roSGNode", "ContentNode")
        videoContent.title = video.title
        videoContent.url = video.url
        videoContent.streamFormat = "mp4"
        
        m.videoList.visible = false
        m.videoPlayer.content = videoContent
        m.videoPlayer.visible = true
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)
    end if
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
    if press and key = "back" and m.videoPlayer.visible
        m.videoPlayer.control = "stop"
        return true
    end if
    return false
end function