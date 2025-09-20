sub init()
    m.top.functionName = "fetchAndParseFeed"
end sub

' This function runs on a background thread
function fetchAndParseFeed()
    ' This is the same parsing function, now moved inside the task function
    ' to be accessible within the task's execution scope.
    function parseFeed(feedString as string) as object
        xml = createObject("roXMLElement")
        videos = []
        if xml.parse(feedString)
            for each item in xml.GetChildElements().GetChildElements()
                if item.getName() = "item"
                    video = {
                        title: item.title.getText(),
                        description: item.description.getText(),
                        hdPosterUrl: item["media:thumbnail"].getAttributes().url,
                        streamUrl: item["media:content"].get.getAttributes().url
                    }
                    videos.push(video)
                end if
            end for
        end if
        return videos
    end function

    fetcher = CreateObject("roUrlTransfer")
    fetcher.SetUrl("https://feeds.feedburner.com/daily_tech_news_show")
    
    responseString = fetcher.GetToString()
    responseCode = fetcher.GetResponseCode()

    if responseCode = 200
        ' Now the call to parseFeed() will succeed.
        m.top.feedData = parseFeed(responseString)
    else
        ' Signal an error by returning an invalid object
        m.top.feedData = invalid
    end if
end function