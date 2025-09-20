sub init()
    m.episodeList = m.top.findNode("episodeList")
    m.detailsView = m.top.findNode("detailsView")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.backgroundPoster = m.top.findNode("backgroundPoster")

    ' Observe events directly on the nodes within the scene
    m.episodeList.observeField("itemFocused", "onEpisodeFocusChanged")
    m.episodeList.observeField("itemSelected", "onItemSelected")
    m.videoPlayer.observeField("state", "onVideoStateChange")

    ' Create and run the background task to fetch content
    m.contentTask = createObject("roSGNode", "ContentTask")
    m.contentTask.observeField("feedData", "onContentReady")
    m.contentTask.control = "RUN"
end sub

' NEW: This function is called when the ContentTask finishes.
sub onContentReady()
    ' The blocking while loop is gone. This function is called asynchronously.
    m.videoData = m.contentTask.feedData
    if m.videoData = invalid
        m.top.findNode("loadingLabel").text = "Error loading feed."
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
        episode.hdPosterUrl = item.hdPosterUrl ' Thumbnail from the feed
        episode.streamUrl = item.streamUrl
    end for
    m.episodeList.content = content
    
    ' Set the initial background to the first episode's thumbnail
    if m.videoData.count() > 0
        m.backgroundPoster.uri = m.videoData[0].hdPosterUrl
    end if

    ' Hide loading label and show the UI
    m.top.findNode("loadingLabel").visible = false
    m.detailsView.visible = true
    m.episodeList.visible = true
    m.episodeList.setFocus(true)
end sub

' This function is called when the user presses OK on a list item.
sub onItemSelected()
    selectedIndex = m.episodeList.itemSelected
    playVideo({ index: selectedIndex })
end sub

' Updates the details view and background when a new episode is focused
sub onEpisodeFocusChanged()
    focusedIndex = m.episodeList.itemFocused
    if focusedIndex >= 0
        focusedItem = m.episodeList.content.getChild(focusedIndex)
        ' Update the details view
        m.detailsView.content = focusedItem
        ' Update the main background poster
        m.backgroundPoster.uri = focusedItem.hdPosterUrl
    end if
end sub

' Plays the selected video
function playVideo(args as object)
    m.currentIndex = args.index
    
    videoContentNode = m.episodeList.content.getChild(m.currentIndex)
    
    m.videoPlayer.content = videoContentNode
    m.videoPlayer.control = "play"
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
end function

' Handles video state changes for continuous play
sub onVideoStateChange()
    if m.videoPlayer.state = "finished"
        m.currentIndex = m.currentIndex + 1
        if m.currentIndex < m.videoData.count()
            ' Play the next video in the series
            playVideo({ index: m.currentIndex })
        else
            ' Last video finished, return to the episode list
            m.videoPlayer.visible = false
            m.episodeList.setFocus(true)
        end if
    end if
end sub
