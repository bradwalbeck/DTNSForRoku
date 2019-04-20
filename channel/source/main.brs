
 sub RunUserInterface()
    screen = CreateObject("roSGScreen")
    scene = screen.CreateScene("HomeScene")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.Show()
    
    oneRow = GetApiArray()
    list = [
        {
            ContentList : oneRow
        }
    ]
    scene.gridContent = ParseXMLContent(list)

    while true
        msg = wait(0, port)
        print "------------------"
        print "msg = "; msg
    end while
    
    if screen <> invalid then
        screen.Close()
        screen = invalid
    end if
end sub


Function ParseXMLContent(list As Object)
    RowItems = createObject("RoSGNode","ContentNode")
    
    for each rowAA in list
        row = createObject("RoSGNode","ContentNode")
        row.Title = rowAA.Title

        for each itemAA in rowAA.ContentList
            item = createObject("RoSGNode","ContentNode")
            ' We don't use item.setFields(itemAA) as doesn't cast streamFormat to proper value
            for each key in itemAA
                item[key] = itemAA[key]
            end for
            row.appendChild(item)
        end for
        RowItems.appendChild(row)
    end for

    return RowItems
End Function


Function GetApiArray()
    url = CreateObject("roUrlTransfer")
    url.SetUrl("http://feeds.feedburner.com/daily_tech_news_show")
    responseRaw = url.GetToString()

    responseXML = ParseXML(responseRaw)
    responseXML = responseXML.GetChildElements()
    responseArray = responseXML.GetChildElements()

    result = []
    'parse needs to get the string between href=" and 



    for each xmlItem in responseArray
        if xmlItem.getName() = "item"
            itemAA = xmlItem.GetChildElements()

            mediaContentText = itemAA.Lookup("media:content").getText()
            'if file doenst end in .mp4 then set itemAA to invalid
            if Instr( Len(mediaContentText) - 4, LCase(mediaContentText, ".mp4") <> 1
                itemAA = invalid
            end if

            if itemAA <> invalid
                item = {}
                for each xmlItem in itemAA
                    item[xmlItem.getName()] = xmlItem.getText()

                    'xml <media:content> is addressed and populates 
                    if xmlItem.getName() = "media:content"
                        item.stream = {url : xmlItem.url}
                        item.url = xmlItem.getAttributes().url
                        item.streamFormat = "mp4"
                    end if
                    
                    'DTNS thumbnail is at <maxImgUrl> ex: <maxImgUrl>http://i.ytimg.com/vi/VGViMR6k0g4/0.jpg</maxImgUrl>
                    if xmlItem.getName() = "maxImgUrl" 
                        item.HDPosterUrl = xmlItem.GetText()
                        item.hdBackgroundImageUrl = xmlItem.GetText()
                    end if

                    'DTNS episode date is at <pubDate> ex: <pubDate>Fri, 22 Feb 2019 22:19:34 GMT</pubDate>
                    if xmlItem.getName() = "pubDate" 
                        item.ReleaseDate = xmlItem.GetText()
                    end if

                    'DTNS episode description is at <itunes:summary> ex: <itunes:summary> Microsoft is rumored to ... Reader? Clic</itunes:summary>
                    if xmlItem.getName() = "itunes:summary" 
                        item.Description = xmlItem.GetText()
                    end if

                end for
                result.push(item)
            end if
        end if
    end for

    return result
End Function


Function ParseXML(str As String) As dynamic
    if str = invalid 
        return invalid
    end if
    xml = CreateObject("roXMLElement")
    if not xml.Parse(str) 
        return invalid
    end if
    return xml
End Function