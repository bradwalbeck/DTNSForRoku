function init()
    m.loadingIndicator = m.top.findNode("loadingIndicator")
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    
    ' Set up event handlers
    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoPlayerStateChanged")
    
    ' Start loading content
    loadVideoContent()
end function

function loadVideoContent()
    ' Create content task to fetch RSS feed
    m.contentTask = createObject("roSGNode", "ContentTask")
    m.contentTask.observeField("content", "onContentLoaded")
    m.contentTask.control = "RUN"
end function

function onContentLoaded()
    content = m.contentTask.content
    if content <> invalid and content.count() > 0
        ' Hide loading, show video list
        m.loadingIndicator.visible = false
        m.videoList.visible = true
        m.videoList.content = createContentNode(content)
        m.videoList.setFocus(true)
    else
        ' Show error message or empty state
        showErrorMessage("No video content available")
    end if
end function

function onVideoSelected()
    selectedIndex = m.videoList.rowItemSelected[1]
    videoContent = m.videoList.content.getChild(selectedIndex)
    
    if videoContent <> invalid
        ' Hide video list, show video player
        m.videoList.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.content = videoContent
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)
    end if
end function

function onVideoPlayerStateChanged()
    state = m.videoPlayer.state
    if state = "finished" or state = "error" or state = "stopped"
        ' Return to video list
        m.videoPlayer.visible = false
        m.videoPlayer.control = "stop"
        m.videoList.visible = true
        m.videoList.setFocus(true)
    end if
end function

function createContentNode(videos as object) as object
    contentNode = createObject("roSGNode", "ContentNode")
    
    for each video in videos
        videoNode = createObject("roSGNode", "ContentNode")
        videoNode.title = video.title
        videoNode.description = video.description
        videoNode.hdPosterUrl = video.hdPosterUrl
        videoNode.streamUrl = video.streamUrl
        videoNode.streamFormat = "mp4"
        contentNode.appendChild(videoNode)
    end for
    
    return contentNode
end function

function showErrorMessage(message as string)
    m.loadingIndicator.visible = false
    ' Could implement error display here
    print "Error: " + message
end function

' Handle remote control input
function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "back"
            if m.videoPlayer.visible
                ' Stop video and return to list
                m.videoPlayer.control = "stop"
                return true
            end if
        end if
    end if
    return false
end function