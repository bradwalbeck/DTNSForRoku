' filepath: c:\Repository\DTNSForRoku\channel\source\main.brs
sub Main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    ' Show loading screen
    loadingScene = screen.CreateScene("LoadingScreen")
    screen.Show()

    ' Load video feed in the background
    videoList = GetVideoFeed("https://feeds.feedburner.com/daily_tech_news_show")

    ' Show video selection screen
    ShowVideoSelection(screen, port, videoList)
end sub

sub ShowVideoSelection(screen as object, port as object, videoList as object)
    scene = screen.CreateScene("VideoSelectionScene")
    scene.content = videoList
    screen.Show()

    ' Event loop for video selection
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent"
            if msg.GetInt() = 2 ' roSGScreenEvent.EVT_KEYUP
                key = msg.GetString()
                if key = "back" or key = "home"
                    exit while
                end if
            end if
        elseif type(msg) = "roSGNodeEvent"
            if msg.GetField() = "selectedVideo"
                selectedVideo = msg.GetData()
                PlayVideo(screen, port, selectedVideo, videoList)
                screen.ClearScene()
                ShowVideoSelection(screen, port, videoList) ' Return to selection after playback
            end if
        end if
    end while
end sub

sub PlayVideo(screen as object, port as object, video as object, videoList as object)
    player = screen.CreateScene("VideoPlayer")
    player.video = video
    screen.Show()

    ' Event loop for video playback
    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent"
            if msg.GetInt() = 2 ' roSGScreenEvent.EVT_KEYUP
                key = msg.GetString()
                if key = "back" or key = "home"
                    exit while
                end if
            end if
        elseif type(msg) = "roVideoPlayerEvent"
            if msg.GetInt() = 1 ' roVideoPlayerEvent.Stopped
                ' Play next video or return to selection
                index = videoList.indexOf(video)
                if index < videoList.count() - 1
                    nextVideo = videoList[index + 1]
                    screen.ClearScene()
                    PlayVideo(screen, port, nextVideo, videoList)
                    exit while
                else
                    exit while ' Return to selection
                end if
            end if
        end if
    end while
end sub

' filepath: c:\Repository\DTNSForRoku\channel\source\utils.brs
function GetVideoFeed(feedUrl as string) as object
    url = CreateObject("roUrlTransfer")
    url.SetUrl(feedUrl)
    responseRaw = url.GetToString()
    responseXML = ParseXML(responseRaw)
    responseXML = responseXML.GetChildElements()
    responseArray = responseXML.GetChildElements()

    result = []
    for each xmlItem in responseArray
        if xmlItem.getName() = "item"
            itemAA = xmlItem.GetChildElements()

            if itemAA <> invalid
                item = {}
                for each xmlItem in itemAA
                    item[xmlItem.getName()] = xmlItem.getText()

                    if xmlItem.getName() = "media:content"
                        item.stream = {url : xmlItem.url}
                        item.url = xmlItem.getAttributes().url
                        if instr(0, LCase(item.url), ".mp4") > 0 
                            item.streamFormat = "mp4"
                        end if
                    end if

                    if xmlItem.getName() = "maxImgUrl" 
                        item.HDPosterUrl = xmlItem.GetText()
                    end if

                    if xmlItem.getName() = "pubDate" 
                        item.ReleaseDate = xmlItem.GetText()
                    end if

                    if xmlItem.getName() = "itunes:summary" 
                        item.Description = xmlItem.GetText()
                    end if
                end for
                if item.streamFormat = "mp4"
                    result.push(item)
                end if
            end if
        end if
    end for

    return result
end function

function ParseXML(str As String) As dynamic
    if str = invalid 
        return invalid
    end if
    xml = CreateObject("roXMLElement")
    if not xml.Parse(str) 
        return invalid
    end if
    return xml
End Function