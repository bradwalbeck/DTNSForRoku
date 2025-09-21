function init()
    m.top.functionName = "fetchContent"
end function

function fetchContent()
    feedUrl = "https://feeds.feedburner.com/daily_tech_news_show"
    
    ' Create HTTP request
    http = createObject("roUrlTransfer")
    http.setURL(feedUrl)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    ' Fetch the RSS feed
    response = http.GetToString()
    
    if response <> invalid and response <> ""
        ' Parse the RSS feed
        videos = parseRSSFeed(response)
        m.top.content = videos
    else
        m.top.content = []
    end if
end function

function parseRSSFeed(xmlString as string) as object
    videos = []
    
    ' Parse XML
    xml = createObject("roXMLElement")
    if not xml.parse(xmlString) then return videos
    
    ' Navigate to channel
    channel = invalid
    if xml.rss <> invalid and xml.rss.channel <> invalid
        channel = xml.rss.channel
    else if xml.channel <> invalid
        channel = xml.channel
    end if
    
    if channel = invalid then return videos
    
    ' Get channel-level image as fallback
    channelImage = invalid
    if channel.image <> invalid and channel.image.url <> invalid
        channelImage = channel.image.url.getText()
    end if
    
    ' Process items
    items = channel.item
    if items <> invalid
        ' Handle both single item and array of items
        if getInterface(items, "ifArray") = invalid
            items = [items]
        end if
        
        for each item in items
            video = parseVideoItem(item, channelImage)
            if video <> invalid
                videos.push(video)
            end if
        end for
    end if
    
    return videos
end function

function parseVideoItem(item as object, fallbackImage as dynamic) as dynamic
    if item = invalid then return invalid
    
    ' Extract title
    title = invalid
    if item.title <> invalid
        title = item.title.getText()
    end if
    if title = invalid or title = "" then return invalid
    
    ' Extract description
    description = ""
    if item.description <> invalid
        description = item.description.getText()
    end if
    
    ' Look for video content in media:group or enclosure
    streamUrl = invalid
    posterUrl = fallbackImage
    
    ' Try media:group first (preferred for video content)
    mediaGroup = item["media:group"]
    if mediaGroup <> invalid
        if getInterface(mediaGroup, "ifArray") <> invalid and mediaGroup.count() > 0
            mediaGroup = mediaGroup[0]
        end if
        
        ' Look for video content
        mediaContent = mediaGroup["media:content"]
        if mediaContent <> invalid
            if getInterface(mediaContent, "ifArray") <> invalid
                ' Multiple media:content elements, find video
                for each content in mediaContent
                    attrs = content.getAttributes()
                    if attrs <> invalid and attrs.url <> invalid
                        url = attrs.url
                        contentType = attrs.type
                        medium = attrs.medium
                        
                        ' Check if this is video content
                        if isVideoContent(url, contentType, medium)
                            streamUrl = url
                            exit for
                        end if
                    end if
                end for
            else
                ' Single media:content
                attrs = mediaContent.getAttributes()
                if attrs <> invalid and attrs.url <> invalid
                    url = attrs.url
                    contentType = attrs.type
                    medium = attrs.medium
                    
                    if isVideoContent(url, contentType, medium)
                        streamUrl = url
                    end if
                end if
            end if
        end if
        
        ' Look for thumbnail
        mediaThumbnail = mediaGroup["media:thumbnail"]
        if mediaThumbnail <> invalid
            if getInterface(mediaThumbnail, "ifArray") <> invalid and mediaThumbnail.count() > 0
                mediaThumbnail = mediaThumbnail[0]
            end if
            
            attrs = mediaThumbnail.getAttributes()
            if attrs <> invalid and attrs.url <> invalid
                posterUrl = attrs.url
            end if
        end if
    end if
    
    ' Try enclosure if no media:group video found
    if streamUrl = invalid and item.enclosure <> invalid
        enclosures = item.enclosure
        if getInterface(enclosures, "ifArray") = invalid
            enclosures = [enclosures]
        end if
        
        for each enclosure in enclosures
            attrs = enclosure.getAttributes()
            if attrs <> invalid and attrs.url <> invalid
                url = attrs.url
                contentType = attrs.type
                
                if isVideoContent(url, contentType, invalid)
                    streamUrl = url
                    exit for
                end if
            end if
        end for
    end if
    
    ' Only return video content
    if streamUrl = invalid then return invalid
    
    return {
        title: title
        description: description
        streamUrl: streamUrl
        hdPosterUrl: posterUrl
    }
end function

function isVideoContent(url as string, contentType as dynamic, medium as dynamic) as boolean
    ' Check medium attribute
    if medium <> invalid and lcase(medium) = "video"
        return true
    end if
    
    ' Check content type
    if contentType <> invalid
        lowerType = lcase(contentType)
        if left(lowerType, 6) = "video/"
            return true
        end if
        ' Reject audio types
        if left(lowerType, 6) = "audio/"
            return false
        end if
    end if
    
    ' Check URL for video file extensions
    if url <> invalid
        lowerUrl = lcase(url)
        if right(lowerUrl, 4) = ".mp4" or right(lowerUrl, 4) = ".m4v" or right(lowerUrl, 4) = ".mov"
            return true
        end if
        if instr(lowerUrl, ".m3u8") > 0 ' HLS streams
            return true
        end if
        ' Reject audio extensions
        if right(lowerUrl, 4) = ".mp3" or right(lowerUrl, 4) = ".m4a"
            return false
        end if
    end if
    
    return false
end function