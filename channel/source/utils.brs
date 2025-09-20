function ParseFeed(feedString as string) as object
    xml = createObject("roXMLElement")
    videos = []
    if xml.parse(feedString)
        ' This path is correct and verified against the live feed.
        channel = xml.rss.channel
        if channel <> invalid
            for each item in channel.item
                ' FIX: Get the list of <media:group> elements and access the first one.
                mediaGroupList = item["media:group"]
                if mediaGroupList <> invalid and mediaGroupList.count() > 0
                    mediaGroup = mediaGroupList[0] ' Get the actual element from the list

                    ' Now, get the lists of content and thumbnail elements from the group element
                    mediaContentList = mediaGroup["media:content"]
                    mediaThumbnailList = mediaGroup["media:thumbnail"]
                    
                    if mediaContentList <> invalid and mediaContentList.count() > 0 and mediaThumbnailList <> invalid and mediaThumbnailList.count() > 0
                        ' Get the actual elements from their respective lists
                        mediaContent = mediaContentList[0]
                        mediaThumbnail = mediaThumbnailList[0] ' Default to the first thumbnail

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
    return videos
end function