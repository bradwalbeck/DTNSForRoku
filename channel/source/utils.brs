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