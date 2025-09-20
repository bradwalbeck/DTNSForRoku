sub init()
    m.top.observeField("focusedChild", "onFocusChanged")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.videoPlayer.observeField("state", "onVideoStateChange")

    ' Fetch the video feed
    fetcher = CreateObject("roUrlTransfer")
    fetcher.SetUrl("https://feeds.feedburner.com/daily_tech_news_show")
    port = CreateObject("roMessagePort")
    fetcher.SetMessagePort(port)
    fetcher.AsyncGetToString()

    while true
        msg = wait(0, port)
        if type(msg) = "roUrlEvent"
            if msg.GetResponseCode() = 200
                m.videoData = parseFeed(msg.GetString())
                displayEpisodes()
            else
                m.top.findNode("loadingLabel").text = "Error loading feed."
            end if
            exit while
        end if
    end while
end sub

' Populates the RowList with episode data
sub displayEpisodes()
    list = m.top.findNode("episodeList")
    content = createObject("roSGNode", "ContentNode")
    for each item in m.videoData
        episode = content.createChild("ContentNode")
        episode.title = item.title
        episode.hdPosterUrl = item.hdPosterUrl
        episode.description = item.description
        episode.streamUrl = item.streamUrl
    end for
    list.content = content
    m.top.findNode("loadingLabel").visible = false
    list.visible = true
    list.setFocus(true)
end sub

' Plays the selected video
function playVideo(args as object)
    m.currentIndex = args.index
    videoContent = m.videoData[m.currentIndex]
    
    content = createObject("roSGNode", "ContentNode")
    content.url = videoContent.streamUrl
    content.title = videoContent.title
    
    m.videoPlayer.content = content
    m.videoPlayer.control = "play"
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
end function

' Handles video state changes for continuous play
sub onVideoStateChange()
    if m.videoPlayer.state = "finished"
        m.currentIndex = m.currentIndex + 1
        if m.currentIndex < m.videoData.count()
            ' Play the next video
            playVideo({ index: m.currentIndex })
        else
            ' Last video finished, return to list
            m.videoPlayer.visible = false
            m.top.findNode("episodeList").setFocus(true)
        end if
    end if
end sub

' Parses the XML feed into an array of video data
function parseFeed(feedString as string) as object
    xml = createObject("roXMLElement")
    videos = []
    if xml.parse(feedString)
        for each item in xml.GetChildElements().GetChildElements()
            if item.getName() = "item"
                video = {
                    title: item.title.getText(),
                    description: item.description.getText(),
                    hdPosterUrl: item["media:thumbnail"][0].getAttributes().url,
                    streamUrl: item["media:content"][0].getAttributes().url
                }
                videos.push(video)
            end if
        end for
    end if
    return videos
end function