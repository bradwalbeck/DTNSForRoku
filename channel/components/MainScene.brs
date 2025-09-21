sub init()
    print "MainScene init() called"
    
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.videoList = m.top.findNode("videoList")
    m.videoPlayer = m.top.findNode("videoPlayer")
    
    print "Nodes found successfully"
    
    ' Set up event handlers
    m.videoList.observeField("itemSelected", "onVideoSelected")
    m.videoPlayer.observeField("state", "onVideoPlayerStateChanged")
    
    print "Starting content load"
    loadVideoContent()
end sub

sub loadVideoContent()
    print "Creating ContentTask"
    m.contentTask = createObject("roSGNode", "ContentTask")
    m.contentTask.observeField("content", "onContentLoaded")
    m.contentTask.control = "RUN"
    print "ContentTask started"
end sub

sub onContentLoaded()
    print "Content loaded callback"
    contentNode = m.contentTask.content
    
    if contentNode <> invalid and contentNode.getChildCount() > 0
        print "Found " + contentNode.getChildCount().toStr() + " videos"
        
        ' Show video list
        m.loadingLabel.visible = false
        m.videoList.visible = true
        m.videoList.content = contentNode
        m.videoList.setFocus(true)
    else
        print "No content found"
        m.loadingLabel.text = "No videos available"
    end if
end sub

sub onVideoSelected()
    print "Video selected"
    selectedIndex = m.videoList.rowItemSelected[1]
    videoContent = m.videoList.content.getChild(selectedIndex)
    
    if videoContent <> invalid
        print "Playing: " + videoContent.title
        m.videoList.visible = false
        m.videoPlayer.visible = true
        m.videoPlayer.content = videoContent
        m.videoPlayer.control = "play"
        m.videoPlayer.setFocus(true)
    end if
end sub

sub onVideoPlayerStateChanged()
    state = m.videoPlayer.state
    print "Video player state: " + state
    
    if state = "finished" or state = "error" or state = "stopped"
        m.videoPlayer.visible = false
        m.videoPlayer.control = "stop"
        m.videoList.visible = true
        m.videoList.setFocus(true)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if press
        if key = "back"
            if m.videoPlayer.visible
                print "Back pressed, stopping video"
                m.videoPlayer.control = "stop"
                return true
            end if
        end if
    end if
    return false
end function