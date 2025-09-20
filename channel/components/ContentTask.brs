sub init()
    m.top.functionName = "fetchAndParseFeed"
end sub

' This function runs on a background thread
function parseFeed(feedString as string) as object
    xml = createObject("roXMLElement")
    videos = []
    if xml.parse(feedString)
        rssNode = xml.getChildElements()
        if rssNode.count() > 0
            channelNode = rssNode[0].getChildElements()
            if channelNode.count() > 0
                for each item in channelNode[0].getChildElements()
                    if item.getName() = "item"
                        mediaContent = item["media:content"]
                        mediaThumbnail = item["media:thumbnail"]
                        if mediaContent <> invalid and mediaThumbnail <> invalid
                            video = {
                                title: item.title.getText(),
                                description: item.description.getText(),
                                hdPosterUrl: mediaThumbnail.getAttributes().url,
                                streamUrl: mediaContent.getAttributes().url
                            }
                            videos.push(video)
                        end if
                    end if
                end for
            end if
        end if
    end if
    return videos
end function

function fetchAndParseFeed()
    fetcher = CreateObject("roUrlTransfer")
    fetcher.SetUrl("https://feeds.feedburner.com/daily_tech_news_show")
    
    responseString = fetcher.GetToString()
    responseCode = fetcher.GetResponseCode()

    if responseCode = 200
        m.top.feedData = parseFeed(responseString)
    else
        m.top.feedData = invalid
    end if
end function