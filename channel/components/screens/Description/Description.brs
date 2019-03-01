
sub Init()
    'setting top interfaces
    m.top.Title = m.top.findNode("Title")
    m.top.ReleaseDate = m.top.findNode("ReleaseDate")
    m.top.Description = m.top.findNode("Description")
end sub

' Content change fields population
sub OnContentchanged()
    item = m.top.content

    title = item.title.toStr()
    if title <> invalid then
        if title.toStr() <> "" then
            m.top.Title.text = RemoveHTMLNumbers(title.toStr())
        else
            m.top.Title.text = "No title"
        end if  
    end if        

    value = item.description
    if value <> invalid then
        if value.toStr() <> "" then
            m.top.Description.text = DTNSDescriptionParse(value.toStr())
        else
            m.top.Description.text = "No description"
        end if  
    end if
    
    releaseDate = item.ReleaseDate
    if releaseDate <> invalid then
        if releaseDate.toStr() <> "" then
            m.top.ReleaseDate.text = releaseDate.toStr()
        else 
            m.top.ReleaseDate.text = "No release date"
        end if      
    end if
end sub


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
