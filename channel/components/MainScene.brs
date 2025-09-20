sub init()
    m.loadingScreen = m.top.findNode("loadingScreen")
    m.episodeList = m.top.findNode("episodeList")
    m.videoPlayer = m.top.findNode("videoPlayer")

    m.episodeList.observeField("itemSelected", "onItemSelected")
    m.videoPlayer.observeField("state", "onVideoStateChange")

    ' Create and run the background task to fetch content
    contentTask = createObject("roSGNode", "ContentTask")
    contentTask.observeField("feedData", "onContentReady")
    contentTask.control = "RUN"
end sub

' This function is called when the ContentTask finishes.
sub onContentReady(event as object)
    m.videoData = event.getData()
    if m.videoData = invalid or m.videoData.count() = 0
        m.loadingScreen.text = "Error loading feed."
    else
        displayEpisodes()
    end if
end sub

' Populates the RowList with episode data
sub displayEpisodes()
    content = createObject("roSGNode", "ContentNode")
    for each item in m.videoData
        episode = content.createChild("ContentNode")
        episode.title = item.title
        episode.description = item.description
        episode.hdPosterUrl = item.hdPosterUrl
        episode.streamUrl = item.streamUrl
    end for
    m.episodeList.content = content
    
    m.loadingScreen.visible = false
    m.episodeList.visible = true
    m.episodeList.setFocus(true)
end sub

' This function is called when the user presses OK on a list item.
sub onItemSelected()
    playVideo(m.episodeList.itemSelected)
end sub

' Plays the selected video
sub playVideo(index as integer)
    videoContentNode = m.episodeList.content.getChild(index)
    m.videoPlayer.content = videoContentNode
    m.videoPlayer.control = "play"
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
end sub

' Handles video state changes
sub onVideoStateChange()
    if m.videoPlayer.state = "finished"
        m.videoPlayer.visible = false
        m.episodeList.setFocus(true)
    end if
end sub
