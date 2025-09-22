sub init()
    m.top.functionName = "run"
end sub

sub run()
    m.top.error = ""
    m.top.result = []

    ' Allow an optional url field; otherwise use default DTNS feed
    feedUrl = ""
    if m.top.lookup("url") <> invalid and m.top.url <> invalid then
        feedUrl = m.top.url.tostr()
    end if
    if feedUrl = "" then feedUrl = "https://feeds.feedburner.com/daily_tech_news_show"

    xfer = createObject("roUrlTransfer")
    xfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.addHeader("User-Agent", "DTNSForRoku/1.0")
    xfer.enableEncodings(true)
    xfer.setUrl(feedUrl)
    data = xfer.getToString()

    if data = invalid or data = "" then
        m.top.error = "empty feed"
        return
    end if

    xml = createObject("roXMLElement")
    ok = xml.parse(data)
    if not ok then
        m.top.error = "xml parse failed"
        return
    end if

    items = findAllItems(xml)
    episodes = []
    for each it in items
        title = getTextChild(it, "title")
        url   = extractPlayableUrl(it)
        descRaw = getTextChild(it, "description")
        if descRaw = "" then descRaw = getTextChild(it, "content:encoded")
        desc = stripHtmlTags(descRaw)

        if title <> "" and url <> "" then
            episodes.push({ title: title, url: url, description: desc })
        end if
    end for

    m.top.result = episodes
end sub

function findAllItems(root as object) as object
    list = []
    if root = invalid then return list
    for each c in root.getChildElements()
        n = lcase(c.getName())
        if n = "item" then
            list.push(c)
        else if n = "channel" then
            for each i in c.getChildElements()
                if lcase(i.getName()) = "item" then list.push(i)
            end for
        end if
    end for
    return list
end function

function getTextChild(node as object, name as string) as string
    if node = invalid then return ""
    lname = lcase(name)
    for each c in node.getChildElements()
        if lcase(c.getName()) = lname then
            b = c.getBody()
            if b <> invalid then return b.tostr()
        end if
    end for
    return ""
end function

function extractPlayableUrl(item as object) as string
    ' enclosure with video
    for each c in item.getChildElements()
        if lcase(c.getName()) = "enclosure" then
            a = c.getAttributes()
            if a <> invalid then
                u = "" : t = ""
                if a["url"]  <> invalid then u = a["url"].tostr()
                if a["type"] <> invalid then t = lcase(a["type"].tostr())
                if u <> "" and (instr(1, t, "video") > 0 or endsWith(u, ".mp4") or endsWith(u, ".m3u8")) then return u
            end if
        end if
    end for

    ' media:content with video
    for each c in item.getChildElements()
        n = lcase(c.getName())
        if n = "media:content" or n = "content" then
            a = c.getAttributes()
            if a <> invalid then
                u = "" : t = "" : m = ""
                if a["url"]    <> invalid then u = a["url"].tostr()
                if a["type"]   <> invalid then t = lcase(a["type"].tostr())
                if a["medium"] <> invalid then m = lcase(a["medium"].tostr())
                if u <> "" and ((t <> "" and instr(1, t, "video") > 0) or m = "video" or endsWith(u, ".mp4") or endsWith(u, ".m3u8")) then return u
            end if
        end if
    end for

    ' scan text for .m3u8/.mp4
    txt = getTextChild(item, "description")
    if txt = "" then txt = getTextChild(item, "content:encoded")
    if txt = "" then txt = getTextChild(item, "link")
    return scanTextForMediaUrl(txt)
end function

function scanTextForMediaUrl(txt as string) as string
    if txt = invalid then return ""
    s = txt
    i = instr(1, s, "http")
    while i > 0
        j = i
        while j <= len(s)
            ch = mid(s, j, 1)
            if ch = " " or ch = chr(10) or ch = chr(13) or ch = """" or ch = "'" or ch = ")" or ch = "(" or ch = "<" or ch = ">" then
                exit while
            end if
            j = j + 1
        end while
        u = mid(s, i, j - i)
        lu = lcase(u)
        if endsWith(lu, ".m3u8") or endsWith(lu, ".mp4") then return u
        i = instr(i + 1, s, "http")
    end while
    return ""
end function

function endsWith(s as string, suffix as string) as boolean
    if s = invalid or suffix = invalid then return false
    ls = len(s) : lf = len(suffix)
    if lf > ls then return false
    return mid(s, ls - lf + 1, lf) = suffix
end function

function stripHtmlTags(s as dynamic) as string
    if s = invalid then return ""
    txt = s.tostr()
    out = ""
    inTag = false
    for k = 1 to len(txt)
        ch = mid(txt, k, 1)
        if ch = "<" then
            inTag = true
        else if ch = ">" then
            inTag = false
        else if not inTag then
            out = out + ch
        end if
    end for

    ' convert CR/LF to spaces
    tmp = ""
    for k = 1 to len(out)
        ch = mid(out, k, 1)
        if ch = chr(10) or ch = chr(13) then
            tmp = tmp + " "
        else
            tmp = tmp + ch
        end if
    end for

    ' collapse spaces and trim both ends (no LTrim/RTrim)
    res = ""
    seenSpace = false
    for k = 1 to len(tmp)
        ch = mid(tmp, k, 1)
        isSp = (ch = " ")
        if isSp then
            if not seenSpace and len(res) > 0 then res = res + " "
        else
            res = res + ch
        end if
        seenSpace = isSp
    end for
    ' trim trailing space
    if len(res) > 0 and mid(res, len(res), 1) = " " then res = left(res, len(res) - 1)
    return res
end function