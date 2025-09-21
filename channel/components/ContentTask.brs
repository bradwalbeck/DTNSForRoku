sub init()
    m.top.functionName = "fetchContent"
end sub

sub fetchContent()
    print "ContentTask: Starting fetch"
    
    feedUrl = "https://feeds.feedburner.com/daily_tech_news_show"
    
    http = createObject("roUrlTransfer")
    http.setURL(feedUrl)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    
    print "ContentTask: Fetching RSS feed"
    response = http.GetToString()
    
    if response <> invalid and response <> ""
        print "ContentTask: Got response length: " + response.len().toStr()
        contentNode = parseRSSFeed(response)
        print "ContentTask: Created content node with " + contentNode.getChildCount().toStr() + " children"
        m.top.content = contentNode
    else
        print "ContentTask: No response or empty response"
        m.top.content = createObject("roSGNode", "ContentNode")
    end if
end sub

function parseRSSFeed(xmlString as string) as object
    contentNode = createObject("roSGNode", "ContentNode")
    
    xml = createObject("roXMLElement")
    if not xml.parse(xmlString)
        print "Failed to parse XML"
        return contentNode
    end if
    
    print "XML parsed successfully"
    
    ' Navigate to channel
    channel = invalid
    if xml.channel <> invalid
        channel = xml.channel
    else if xml.rss <> invalid and xml.rss.channel <> invalid
        channel = xml.rss.channel
    end if
    
    if channel = invalid
        print "No channel found"
        return contentNode
    end if
    
    print "Channel found"
    
    ' Get items
    items = channel.item
    if items = invalid
        print "No items found"
        return contentNode
    end if
    
    ' Check if items is an array or single item
    itemCount = 0
    if getInterface(items, "ifArray") <> invalid
        itemCount = items.count()
        print "Found items array with " + itemCount.toStr() + " items"
    else
        itemCount = 1
        print "Found single item"
        items = [items]
    end if
    
    videoCount = 0
    for i = 0 to itemCount - 1
        item = items[i]
        videoNode = parseVideoItem(item)
        if videoNode <> invalid
            contentNode.appendChild(videoNode)
            videoCount = videoCount + 1
        end if
    end for
    
    print "Added " + videoCount.toStr() + " video items out of " + itemCount.toStr() + " total items"
    
    return contentNode
end function

function parseVideoItem(item as object) as dynamic
    if item = invalid then return invalid
    
    ' Extract title safely
    title = ""
    if item.title <> invalid
        titleText = item.title.getText()
        if titleText <> invalid then title = titleText
    end if
    if title = "" then return invalid
    
    print "Processing: " + title
    
    ' Extract description safely
    description = ""
    if item.description <> invalid
        descText = item.description.getText()
        if descText <> invalid then description = descText
    end if
    
    ' Look for media content
    streamUrl = invalid
    posterUrl = ""
    
    ' Try to get media:group using getNamedElements (safer approach)
    mediaGroups = item.getNamedElements("media:group")
    if mediaGroups <> invalid and mediaGroups.count() > 0
        print "  Found " + mediaGroups.count().toStr() + " media:group elements"
        mediaGroup = mediaGroups[0]
        
        ' Look for media:content
        mediaContents = mediaGroup.getNamedElements("media:content")
        if mediaContents <> invalid and mediaContents.count() > 0
            print "  Found " + mediaContents.count().toStr() + " media:content elements"
            
            for each mediaContent in mediaContents
                attrs = mediaContent.getAttributes()
                if attrs <> invalid and attrs.url <> invalid
                    url = attrs.url
                    medium = attrs.medium
                    contentType = attrs.type
                    
                    print "    URL: " + url
                    if medium <> invalid then print "    Medium: " + medium
                    if contentType <> invalid then print "    Type: " + contentType
                    
                    ' Check if it's video
                    isVideo = false
                    if medium <> invalid and lcase(medium) = "video"
                        isVideo = true
                        print "    -> Video (medium)"
                    else if contentType <> invalid and left(lcase(contentType), 6) = "video/"
                        isVideo = true
                        print "    -> Video (type)"
                    else if url <> invalid
                        lowerUrl = lcase(url)
                        if right(lowerUrl, 4) = ".mp4" or instr(lowerUrl, ".m3u8") > 0 or right(lowerUrl, 4) = ".m4v"
                            isVideo = true
                            print "    -> Video (extension)"
                        end if
                    end if
                    
                    if isVideo and streamUrl = invalid
                        streamUrl = url
                        print "    -> USING THIS VIDEO URL"
                    end if
                end if
            end for
        end if
        
        ' Look for media:thumbnail
        mediaThumbnails = mediaGroup.getNamedElements("media:thumbnail")
        if mediaThumbnails <> invalid and mediaThumbnails.count() > 0
            attrs = mediaThumbnails[0].getAttributes()
            if attrs <> invalid and attrs.url <> invalid
                posterUrl = attrs.url
                print "  Found thumbnail: " + posterUrl
            end if
        end if
    else
        print "  No media:group found"
    end if
    
    ' Try enclosure if no video found
    if streamUrl = invalid and item.enclosure <> invalid
        print "  Checking enclosures"
        enclosures = item.enclosure
        
        ' Handle single or array
        if getInterface(enclosures, "ifArray") <> invalid
            enclosureList = enclosures
        else
            enclosureList = [enclosures]
        end if
        
        for each enclosure in enclosureList
            attrs = enclosure.getAttributes()
            if attrs <> invalid and attrs.url <> invalid
                url = attrs.url
                contentType = attrs.type
                
                print "    Enclosure URL: " + url
                if contentType <> invalid then print "    Type: " + contentType
                
                ' Check for video in enclosure
                isVideo = false
                if contentType <> invalid and left(lcase(contentType), 6) = "video/"
                    isVideo = true
                    print "    -> Video enclosure (type)"
                else if url <> invalid
                    lowerUrl = lcase(url)
                    if right(lowerUrl, 4) = ".mp4" or instr(lowerUrl, ".m3u8") > 0 or right(lowerUrl, 4) = ".m4v"
                        isVideo = true
                        print "    -> Video enclosure (extension)"
                    end if
                end if
                
                if isVideo and streamUrl = invalid
                    streamUrl = url
                    print "    -> USING THIS ENCLOSURE VIDEO URL"
                end if
            end if
        end for
    end if
    
    ' Try itunes:image for poster if none found
    if posterUrl = "" and item.getNamedElements("itunes:image") <> invalid
        itunesImages = item.getNamedElements("itunes:image")
        if itunesImages.count() > 0
            attrs = itunesImages[0].getAttributes()
            if attrs <> invalid and attrs.href <> invalid
                posterUrl = attrs.href
                print "  Found iTunes image: " + posterUrl
            end if
        end if
    end if
    
    ' Only return video content
    if streamUrl = invalid
        print "  No video content found, skipping"
        return invalid
    end if
    
    print "  SUCCESS: Video item created for: " + title
    
    ' Create video node with correct field names
    videoNode = createObject("roSGNode", "ContentNode")
    videoNode.title = title
    videoNode.description = description
    videoNode.hdPosterUrl = posterUrl
    videoNode.url = streamUrl          ' Changed from streamUrl to url
    videoNode.streamFormat = "mp4"     ' Add stream format
    
    return videoNode
end function