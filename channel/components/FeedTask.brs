sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    url = m.top.url
    if url = invalid or url = "" then url = "https://feeds.feedburner.com/daily_tech_news_show"

    x = createObject("roUrlTransfer")
    x.setCertificatesFile("common:/certs/ca-bundle.crt")
    x.enableEncodings(true)
    x.setUrl(url)
    data = x.getToString()
    if data = invalid or data = "" then return

    xml = createObject("roXMLElement")
    if not xml.parse(data) then return

    items = gatherItems(xml)
    episodes = []
    for each it in items
        title = txt(it, "title")
        media = playableUrl(it)
        if title = "" or media = "" then continue for

        rawDesc = txt(it, "description")
        if rawDesc = "" then rawDesc = txt(it, "content:encoded")
        desc = stripHtml(rawDesc)

        rawPub = txt(it, "pubDate")
        friendly = friendlyDate(rawPub)

        episodes.push({
            title: title,
            url: media,
            description: desc,
            dateDisplay: friendly
        })
    end for

    m.top.result = episodes
end sub

function gatherItems(root as object) as object
    r = []
    if root = invalid then return r
    for each c in root.getChildElements()
        n = lcase(c.getName())
        if n = "channel" then
            for each i in c.getChildElements()
                if lcase(i.getName()) = "item" then r.push(i)
            end for
        else if n = "item" then
            r.push(c)
        end if
    end for
    return r
end function

function txt(node as object, name as string) as string
    if node = invalid then return ""
    want = lcase(name)
    for each c in node.getChildElements()
        if lcase(c.getName()) = want then
            b = c.getBody()
            if b <> invalid then return b.tostr()
        end if
    end for
    return ""
end function

function playableUrl(item as object) as string
    ' enclosure first
    for each c in item.getChildElements()
        if lcase(c.getName()) = "enclosure" then
            a = c.getAttributes()
            if a <> invalid and a["url"] <> invalid then
                u = a["url"].tostr()
                if u <> "" then return u
            end if
        end if
    end for
    ' media:content fallback
    for each c in item.getChildElements()
        if lcase(c.getName()) = "media:content" then
            a = c.getAttributes()
            if a <> invalid and a["url"] <> invalid then
                u = a["url"].tostr()
                if u <> "" then return u
            end if
        end if
    end for
    return ""
end function

function stripHtml(s as dynamic) as string
    if s = invalid then return ""
    t = s.tostr()
    out = ""
    inTag = false
    for i = 1 to len(t)
        ch = mid(t, i, 1)
        if ch = "<" then
            inTag = true
        else if ch = ">" then
            inTag = false
        else if not inTag then
            out = out + ch
        end if
    end for
    ' collapse whitespace
    res = ""
    spaceRun = false
    for i = 1 to len(out)
        ch = mid(out, i, 1)
        if ch <= " " then
            if not spaceRun and len(res) > 0 then res = res + " "
            spaceRun = true
        else
            res = res + ch
            spaceRun = false
        end if
    end for
    if len(res) > 0 and right(res,1) = " " then res = left(res, len(res)-1)
    return res
end function

function friendlyDate(raw as string) as string
    if raw = invalid or raw = "" then return ""
    parts = splitSpaces(raw)
    mmMap = { jan:"Jan", feb:"Feb", mar:"Mar", apr:"Apr", may:"May", jun:"Jun", jul:"Jul", aug:"Aug", sep:"Sep", oct:"Oct", nov:"Nov", dec:"Dec" }
    day = "" : mon = "" : yr = ""
    for i = 0 to parts.count()-1
        p = parts[i]
        if day = "" and isDigits(p) and len(p) <= 2 then
            day = p
            if i + 1 < parts.count() then
                m2 = lcase(parts[i+1])
                if mmMap.doesExist(m2) then mon = mmMap[m2]
            end if
            if i + 2 < parts.count() and isDigits(parts[i+2]) and len(parts[i+2]) = 4 then
                yr = parts[i+2]
            end if
            exit for
        end if
    end for
    if day = "" or mon = "" or yr = "" then return raw
    if len(day) = 1 then day = "0" + day
    return mon + " " + day + ", " + yr
end function

function splitSpaces(raw as string) as object
    arr = [] : tok = ""
    for i = 1 to len(raw)
        ch = mid(raw, i, 1)
        if ch = " " then
            if tok <> "" then arr.push(tok) : tok = ""
        else
            tok = tok + ch
        end if
    end for
    if tok <> "" then arr.push(tok)
    return arr
end function

function isDigits(s as string) as boolean
    if s = invalid or s = "" then return false
    for i = 1 to len(s)
        ch = mid(s, i, 1)
        if ch < "0" or ch > "9" then return false
    end for
    return true
end function
