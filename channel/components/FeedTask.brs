sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    m.top.error = ""
    url = m.top.url
    if url = invalid or url = "" then url = "https://feeds.feedburner.com/daily_tech_news_show"

    x = createObject("roUrlTransfer")
    x.setCertificatesFile("common:/certs/ca-bundle.crt")
    x.enableEncodings(true)
    x.setRequest("GET")
    x.setUrl(url)
    x.addHeader("User-Agent", "DTNSForRoku/1.0")
    x.setPort(createObject("roMessagePort"))
    x.setCertificatesDepth(3)
    x.setMinimumTransferRate(1024, 10) ' basic stall protection
    data = x.getToString()
    if data = invalid or data = "" then
        m.top.error = "empty feed"
        return
    end if

    xml = createObject("roXMLElement")
    if not xml.parse(data) then
        m.top.error = "xml parse"
        return
    end if

    episodes = []
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

    if episodes.count() = 0 then
        m.top.error = "no items"
    end if
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
    rel = relativeAge(rawPub)
    if friendly <> "" and rel <> "" then
        friendly = friendly + " • " + rel
    end if

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

function relativeAge(raw as string) as string
    if raw = invalid or raw = "" then return ""
    ' Attempt to find YYYY or numeric tokens; simplified parse via friendlyDate again
    friendly = friendlyDate(raw)
    if friendly = "" then return ""
    ' friendly = Mon DD, YYYY
    y = val(right(friendly,4))
    monStr = left(friendly,3)
    dayStr = mid(friendly,5,2)
    monthMap = { Jan:1, Feb:2, Mar:3, Apr:4, May:5, Jun:6, Jul:7, Aug:8, Sep:9, Oct:10, Nov:11, Dec:12 }
    if not monthMap.doesExist(monStr) then return ""
    m = monthMap[monStr]
    d = val(dayStr)
    today = createObject("roDateTime") : today.toLocalTime()
    diff = dayNumber(today.getYear(), today.getMonth(), today.getDayOfMonth()) - dayNumber(y,m,d)
    if diff < 0 then return ""
    if diff = 0 then return "Today"
    if diff = 1 then return "Yesterday"
    if diff < 30 then return diff.tostr() + "d ago"
    if diff < 60 then return "1mo ago"
    if diff < 365 then return int(diff/30).tostr() + "mo ago"
    yrs = int(diff / 365)
    if yrs = 1 then return "1y ago"
    return yrs.tostr() + "y ago"
end function

function dayNumber(y as integer, m as integer, d as integer) as integer
    if m < 3 then y = y - 1 : m = m + 12
    return 365 * y + y / 4 - y / 100 + y / 400 + ((153 * (m - 3) + 2) / 5) + d - 1
end function
