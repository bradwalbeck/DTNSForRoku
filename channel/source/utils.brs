function ParseFeed(feedString as string) as object
    videos = []
    
    ' Regex to find each <item>...</item> block
    itemRegex = createObject("roRegex", "<item>(.*?)</item>", "si")
    itemMatches = itemRegex.Match(feedString)

    ' Regex for the data inside each item block
    titleRegex = createObject("roRegex", "<title><!\[CDATA\[(.*?)\]\]></title>", "i")
    streamRegex = createObject("roRegex", "<media:content.*?url=""(.*?)"".*?>", "i")
    posterRegex = createObject("roRegex", "<media:thumbnail.*?url=""(.*?)"".*?>", "i")
    descRegex = createObject("roRegex", "<description><!\[CDATA\[(.*?)\]\]></description>", "si")

    for each itemBlock in itemMatches
        ' itemBlock[0] is the full match, itemBlock[1] is the content inside the tags
        itemContent = itemBlock[1]

        titleMatch = titleRegex.Match(itemContent)
        streamMatch = streamRegex.Match(itemContent)
        posterMatch = posterRegex.Match(itemContent)
        descMatch = descRegex.Match(itemContent)

        ' Ensure all required data was found before adding the item
        if titleMatch.count() > 0 and streamMatch.count() > 0 and posterMatch.count() > 0 and descMatch.count() > 0
            video = {
                title: titleMatch[0][1],
                description: descMatch[0][1],
                hdPosterUrl: posterMatch[0][1],
                streamUrl: streamMatch[0][1]
            }
            videos.push(video)
        end if
    end for

    return videos
end function