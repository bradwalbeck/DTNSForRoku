function ParseFeed(feedString as string) as object
    xml = createObject("roXMLElement")
    videos = []
    if xml.parse(feedString)
        ' The diagnostic logs showed the parser can be inconsistent.
        ' The most direct and reliable method is to use dot notation for standard tags
        ' and bracket notation for namespaced tags. This avoids the buggy traversal methods.
        
        ' Use dot notation to get to the list of items.
        itemList = xml.rss.channel.item
        if itemList = invalid
            ' Fallback if the primary method fails, based on diagnostic log evidence
            ' that sometimes <channel> is seen as the root.
            itemList = xml.channel.item
        end if
        
        if itemList <> invalid
            for each item in itemList
                ' Use bracket notation for tags with a colon in the name.
                mediaGroup = item["media:group"]
                
                ' Check that the mediaGroup and its children exist before trying to access them.
                if mediaGroup <> invalid and mediaGroup.count() > 0
                    mediaContent = mediaGroup[0]["media:content"]
                    mediaThumbnail = mediaGroup[0]["media:thumbnail"]

                    if mediaContent <> invalid and mediaContent.count() > 0 and mediaThumbnail <> invalid and mediaThumbnail.count() > 0
                        video = {
                            title: item.title.getText(),
                            description: item.description.getText(),
                            hdPosterUrl: mediaThumbnail[0].getAttributes().url,
                            streamUrl: mediaContent[0].getAttributes().url
                        }
                        videos.push(video)
                    end if
                end if
            end for
        end if
    end if
    return videos
end function