' ********** Copyright 2016 Roku Corp.  All Rights Reserved. ********** 
 
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
                    '    item.Description = PeriodAtTheEnd(CropMp3Down(xmlItem.GetText().Replace("&#8221;", "'").Replace("&#8211;", "'").Replace("&#8216;", "'").Replace("&#8217;", "'").Replace("&#8220;", "'").Replace("&#8221;", "'")))
                        item.Description = DTNSDescriptionParse(xmlItem.GetText())
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

Function DTNSDescriptionParse(rawString As String) As dynamic
    if rawString = invalid 
        return invalid
    end if

    stringInProcess = CropMp3Down(rawString)
    stringInProcess = RemoveHTMLNumbers(stringInProcess)
    stringInProcess = RemoveLeadingSpace(stringInProcess)
    stringInProcess = PeriodAtTheEnd(stringInProcess)
    
    return stringInProcess
End Function

Function CropMp3Down(rawString As String) As dynamic
    if rawString.Instr("MP3 Down") < 0 
        return rawString + "..."
    end if
    stringInProcess = rawString
    stringInProcess = stringInProcess.Left(stringInProcess.Instr("MP3 Down"))
    return stringInProcess
End Function

Function PeriodAtTheEnd(rawString As String) As dynamic
    stringInProcess = rawString.Trim() 
    if stringInProcess.Right(1) = "." 
        return stringInProcess
    end if
    return stringInProcess + "."
End Function

Function RemoveLeadingSpace(rawString As String) As dynamic
    if rawString.Instr(" ") <> 0
        return rawString
    end if
    return rawString.Right((rawString.len())-1)
End Function

Function RemoveHTMLNumbers(rawString As String) As dynamic
    'HTML Numbers known to display
    stringInProcess = rawString.Replace("&#8211;", "-")
    stringInProcess = stringInProcess.Replace("&#8211;", "'")
    stringInProcess = stringInProcess.Replace("&#8216;", "'")
    stringInProcess = stringInProcess.Replace("&#8217;", "'")
    stringInProcess = stringInProcess.Replace("&#8220;", "'")
    stringInProcess = stringInProcess.Replace("&#8221;", "'")
    
    'HTML Numbers that are predicted
    stringInProcess = stringInProcess.Replace("&#60;", "<")
    stringInProcess = stringInProcess.Replace("&#62;", ">")
    stringInProcess = stringInProcess.Replace("&#38;", "&")
    stringInProcess = stringInProcess.Replace("&#34;", "'")
    stringInProcess = stringInProcess.Replace("&#39;", "'")
    stringInProcess = stringInProcess.Replace("&#162;", "¢")
    stringInProcess = stringInProcess.Replace("&#163;", "£")
    stringInProcess = stringInProcess.Replace("&#165;", "¥")
    stringInProcess = stringInProcess.Replace("&#8364;", "€")
    stringInProcess = stringInProcess.Replace("&#169;", "©")
    stringInProcess = stringInProcess.Replace("&#174;", "®")

    return stringInProcess
End Function
