sub init()
    m.top.functionName = "loadDTNSFeed"
end sub

sub loadDTNSFeed()
    http = createObject("roUrlTransfer")
    http.setURL("https://feeds.feedburner.com/daily_tech_news_show")
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    response = http.GetToString()
    videos = []
    
    if response <> invalid and response <> ""
        xml = createObject("roXMLElement")
        if xml.parse(response)
            if xml.rss <> invalid and xml.rss.channel <> invalid
                ' Get items directly - fix the invalid items issue
                if xml.rss.channel.item <> invalid
                    items = xml.rss.channel.item
                    
                    ' Handle single item vs array
                    if getInterface(items, "ifArray") <> invalid
                        ' Multiple items
                        for each item in items
                            video = parseItem(item)
                            if video <> invalid then videos.push(video)
                        end for
                    else
                        ' Single item
                        video = parseItem(items)
                        if video <> invalid then videos.push(video)
                    end if
                end if
            end if
        end if
    end if
    
    m.top.result = videos
end sub

function parseItem(item as object) as object
    if item = invalid then return invalid
    
    title = ""
    url = ""
    
    if item.title <> invalid
        titleText = item.title.getText()
        if titleText <> invalid then title = titleText
    end if
    
    if item.enclosure <> invalid
        attrs = item.enclosure.getAttributes()
        if attrs <> invalid and attrs.url <> invalid and attrs.type <> invalid
            if left(lcase(attrs.type), 5) = "video" or right(lcase(attrs.url), 4) = ".mp4"
                url = attrs.url
            end if
        end if
    end if
    
    if title <> "" and url <> ""
        return {title: title, url: url}
    end if
    
    return invalid
end function