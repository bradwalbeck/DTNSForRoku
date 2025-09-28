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

    episodes = []

    ' Collect item nodes (direct or within channel)
    for each c in xml.getChildElements()
        nm = lcase(c.getName())
        if nm = "channel" then
            for each i in c.getChildElements()
                if lcase(i.getName()) = "item" then processItem(i, episodes)
            end for
        else if nm = "item" then
            processItem(c, episodes)
        end if
    end for

    m.top.result = episodes
end sub

sub processItem(it as object, episodes as object)
    if it = invalid then return
    title = nodeText(it, "title")
    media = firstMedia(it)
    if title = "" or media = "" then return

    rawDesc = nodeText(it, "description")
    if rawDesc = "" then rawDesc = nodeText(it, "content:encoded")
    desc = stripHtml(rawDesc)

    rawPub = nodeText(it, "pubDate")
    friendly = friendlyDate(rawPub)

    episodes.push({
        title: title,
        url: media,
        description: desc,
        pubDate: rawPub,
        dateFriendly: friendly
    })
end sub

function nodeText(node as object, tag as string) as string
    if node = invalid then return ""
    want = lcase(tag)
    for each c in node.getChildElements()
        if lcase(c.getName()) = want then
            b = c.getBody()
            if b <> invalid then return b.tostr()
        end if
    end for
    return ""
end function

function firstMedia(item as object) as string
    if item = invalid then return ""
    ' enclosure
    for each c in item.getChildElements()
        if lcase(c.getName()) = "enclosure" then
            a = c.getAttributes()
            if a <> invalid and a["url"] <> invalid then
                u = a["url"].tostr()
                if u <> "" then return u
            end if
        end if
    end for
    ' media:content
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
    if instr(1, t, "<") = 0 then return collapseSpace(t)
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
    return collapseSpace(out)
end function

function collapseSpace(src as string) as string
    res = ""
    spaceRun = false
    for i = 1 to len(src)
        ch = mid(src, i, 1)
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

' Simple friendly date: "Sep 25, 2025"
function friendlyDate(raw as string) as string
    if raw = invalid or raw = "" then return ""
    ' Tokenize on spaces
    parts = []
    tok = ""
    for i = 1 to len(raw)
        ch = mid(raw, i, 1)
        if ch = " " then
            if tok <> "" then parts.push(tok) : tok = ""
        else
            tok = tok + ch
        end if
    end for
    if tok <> "" then parts.push(tok)

    mmMap = { jan:"Jan", feb:"Feb", mar:"Mar", apr:"Apr", may:"May", jun:"Jun", jul:"Jul", aug:"Aug", sep:"Sep", oct:"Oct", nov:"Nov", dec:"Dec" }
    day = "" : mon = "" : yr = ""
    for i = 0 to parts.count() - 1
        p = parts[i]
        ' Identify numeric day token (1-31)
        if isNumToken(p) then
            day = p
            if i + 1 < parts.count() then
                mkey = lcase(parts[i + 1])
                if mmMap.doesExist(mkey) then mon = mmMap[mkey]
            end if
            if i + 2 < parts.count() then
                ytok = parts[i + 2]
                if len(ytok) = 4 and isNumToken(ytok) then yr = ytok
            end if
            exit for
        end if
    end for
    if day = "" or mon = "" or yr = "" then return ""
    if len(day) = 1 then day = "0" + day
    return mon + " " + day + ", " + yr
end function

function isNumToken(s as string) as boolean
    if s = invalid or s = "" then return false
    for i = 1 to len(s)
        ch = mid(s, i, 1)
        if ch < "0" or ch > "9" then return false
    end for
    return true
end function
