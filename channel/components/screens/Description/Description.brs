
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
            m.top.Title.text = title.toStr()
        else
            m.top.Title.text = "No title"
        end if  
    end if        

    value = item.description
    if value <> invalid then
        if value.toStr() <> "" then
            m.top.Description.text = value.toStr()
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