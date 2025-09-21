function ParseFeed(feedString as string) as object
    xml = createObject("roXMLElement")
    videos = []
    if xml.parse(feedString)
        ' The log shows the root element is <channel>.
        ' Its children are a mix of info tags and <item> tags.
        for each itemNode in xml.GetChildElements()
            if itemNode.getName() = "item"
                ' Found an <item>. Now find <media:group> inside it.
                mediaGroupNode = invalid
                for each childOfItem in itemNode.GetChildElements()
                    if childOfItem.getName() = "media:group"
                        mediaGroupNode = childOfItem
                        exit for
                    end if
                end for

                if mediaGroupNode <> invalid
                    ' Found <media:group>. Now find content and thumbnail inside it.
                    mediaContentNode = invalid
                    mediaThumbnailNode = invalid
                    for each childOfMediaGroup in mediaGroupNode.GetChildElements()
                        if childOfMediaGroup.getName() = "media:content"
                            mediaContentNode = childOfMediaGroup
                        else if childOfMediaGroup.getName() = "media:thumbnail"
                            mediaThumbnailNode = childOfMediaGroup
                        end if
                    end for

                    if mediaContentNode <> invalid and mediaThumbnailNode <> invalid
                        video = {
                            title: itemNode.title.getText(),
                            description: itemNode.description.getText(),
                            hdPosterUrl: mediaThumbnailNode.getAttributes().url,
                            streamUrl: mediaContentNode.getAttributes().url
                        }
                        videos.push(video)
                    end if
                end if
            end if
        end for
    end if
    return videos
end function