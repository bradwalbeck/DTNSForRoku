sub init()
    m.episodeList      = m.top.findNode("videoList")
    m.videoPlayer      = m.top.findNode("videoPlayer")
    m.statusLabel      = m.top.findNode("status")
    m.descriptionPanel = m.top.findNode("episodeDescBg")
    m.dateLabel        = m.top.findNode("episodeDateLabel")
    m.divider          = m.top.findNode("episodeDivider")
    m.descriptionLabel = m.top.findNode("episodeDescPanel")
    ' m.borderRectangle = m.top.findNode("episodeDescBorder") ' (not present in XML)

    m.lastFocusedIndex     = -1
    m.currentEpisodeIndex  = -1

    m.episodeList.observeField("content", "onFeedReady")
    m.episodeList.observeField("itemFocused", "onFocusChanged")
    m.episodeList.observeField("itemSelected", "onItemSelected")
    m.videoPlayer.observeField("state", "onVideoState")

    startFeed()
end sub

sub startFeed()
    m.statusLabel.visible = true
    m.statusLabel.text = "Loading..."
    m.episodeList.visible = false
    if m.feedTask = invalid then
        m.feedTask = createObject("roSGNode", "FeedTask")
        m.feedTask.observeField("result", "onFeedResult")
        m.feedTask.observeField("error", "onFeedError")
    end if
    m.feedTask.control = "run"
end sub

sub onFeedError()
    if m.feedTask = invalid then return
    errorMessage = m.feedTask.error
    if errorMessage <> invalid and errorMessage <> "" then
        if m.episodeList.visible = false then
            m.statusLabel.visible = true
            m.statusLabel.text = "Feed error: " + errorMessage + " (* to retry)"
        end if
    end if
end sub

sub onFeedResult()
    episodeArray = m.feedTask.result

    if (episodeArray = invalid or episodeArray.count() = 0) then
        if m.feedTask.error <> "" then return
        m.statusLabel.visible = true
        m.statusLabel.text = "No episodes (* to retry)"
        return
    end if

    contentRoot = createObject("roSGNode", "ContentNode")
    for each episode in episodeArray
        episodeNode = createObject("roSGNode", "ContentNode")
        episodeNode.title = episode.title
        episodeNode.url   = episode.url
        episodeNode.description = episode.description
        if episode.dateFriendly <> invalid and episode.dateFriendly <> "" then
            episodeNode.releaseDate = episode.dateFriendly
        end if
        contentRoot.appendChild(episodeNode)
    end for

    m.episodes = episodeArray
    m.episodeList.content = contentRoot
    m.episodeList.visible = true
    m.statusLabel.visible = false
    if m.episodeList.itemFocused = invalid then m.episodeList.itemFocused = 0
    m.episodeList.setFocus(true)
    m.lastFocusedIndex = -1
    updateDetails()
end sub

sub onFeedReady()
    ' no-op placeholder
end sub

sub onFocusChanged()
    updateDetails()
end sub

sub updateDetails()
    focusedIndex = m.episodeList.itemFocused
    if focusedIndex = invalid or focusedIndex = m.lastFocusedIndex then return
    m.lastFocusedIndex = focusedIndex

    episodeDate = ""
    episodeDescription = ""
    episodeContent = m.episodeList.content
    if episodeContent <> invalid and focusedIndex >= 0 and focusedIndex < episodeContent.getChildCount() then
        episodeNode = episodeContent.getChild(focusedIndex)
        if episodeNode.doesExist("releaseDate") and episodeNode.releaseDate <> invalid then
            episodeDate = episodeNode.releaseDate.tostr()
        end if
        if episodeNode.doesExist("description") and episodeNode.description <> invalid then
            episodeDescription = episodeNode.description.tostr()
        end if
    end if

    maxDescriptionLength = 4000
    if episodeDescription.len() > maxDescriptionLength then
        episodeDescription = left(episodeDescription, maxDescriptionLength) + "... [truncated]"
    end if

    showPanel = (episodeDate <> "" or episodeDescription <> "")
    m.descriptionPanel.visible   = showPanel
    m.dateLabel.visible = (episodeDate <> "")
    if m.dateLabel.visible then m.dateLabel.text = episodeDate else m.dateLabel.text = ""
    m.divider.visible  = (episodeDescription <> "" and episodeDate <> "")
    m.descriptionLabel.visible = (episodeDescription <> "")
    if m.descriptionLabel.visible then m.descriptionLabel.text = episodeDescription else m.descriptionLabel.text = ""
end sub

sub onItemSelected()
    selectedIndex = m.episodeList.itemSelected
    if selectedIndex = invalid or selectedIndex < 0 or selectedIndex >= m.episodes.count() then return
    playEpisode(selectedIndex)
end sub

sub playEpisode(episodeIndex as integer)
    episode = m.episodes[episodeIndex]
    m.currentEpisodeIndex = episodeIndex

    episodeNode = createObject("roSGNode", "ContentNode")
    episodeNode.title = episode.title
    episodeNode.url   = episode.url
    episodeUrlLower = lcase(episode.url)
    if right(episodeUrlLower,5) = ".m3u8" then
        episodeNode.streamFormat = "hls"
    else
        episodeNode.streamFormat = "mp4"
    end if

    m.descriptionPanel.visible = false
    if m.dateLabel <> invalid then m.dateLabel.visible = false
    if m.divider <> invalid then m.divider.visible = false
    m.descriptionLabel.visible = false
    m.episodeList.visible = false

    m.videoPlayer.content = episodeNode
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)
end sub

sub onVideoState()
    playerState = m.videoPlayer.state
    if playerState = "finished" then
        if m.currentEpisodeIndex <> invalid and m.currentEpisodeIndex >= 0 and m.currentEpisodeIndex + 1 < m.episodes.count() then
            playEpisode(m.currentEpisodeIndex + 1)
            return
        end if
    end if

    if playerState = "finished" or playerState = "stopped" or playerState = "error" then
        m.videoPlayer.visible = false
        m.episodeList.visible = true
        m.episodeList.setFocus(true)
        m.lastFocusedIndex = -1
        m.currentEpisodeIndex = -1
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