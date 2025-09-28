sub init()
    m.top.functionName = "execute"  ' renamed from run
end sub

' renamed from run
sub execute()
    m.top.error = ""
    m.top.result = []

    url = ""
    if m.top.lookup("url") <> invalid and m.top.url <> invalid then
        url = m.top.url.tostr()
    end if
    if url = "" then url = "https://feeds.feedburner.com/daily_tech_news_show"

    x = createObject("roUrlTransfer")
    x.setCertificatesFile("common:/certs/ca-bundle.crt")
    x.addHeader("User-Agent", "DTNSForRoku/1.0")
    x.enableEncodings(true)
    x.setUrl(url)
    data = x.getToString()
    if data = invalid or data = "" then
        m.top.error = "empty feed"
        return
    end if

    xml = createObject("roXMLElement")
    if not xml.parse(data) then
        m.top.error = "xml parse failed"
        return
    end if

    items = findItems(xml)
    out = []
    for each it in items
        title = getText(it, "title")
        mediaUrl = firstPlayableUrl(it)
        if title = "" or mediaUrl = "" then
            continue for
        end if

        rawDesc = getText(it, "description")
        if rawDesc = "" then rawDesc = getText(it, "content:encoded")
        desc = htmlToText(rawDesc)

        rawPub = getText(it, "pubDate")
        shortPub = formatRfc822Date(rawPub)          ' existing short (YYYY-MM-DD)
        friendlyPub = formatRfc822DateFriendly(rawPub)

        ' FIX: commas between fields so keys are created
        out.push({
            title: title,
            url: mediaUrl,
            description: desc,
            pubDate: rawPub,
            pubDateShort: shortPub,
            pubDateFriendly: friendlyPub
        })
    end for

    m.top.result = out
    ? "DEBUG first ep:", out[0]
end sub

function findItems(root as object) as object
    r = []
    if root = invalid then return r
    for each c in root.getChildElements()
        n = lcase(c.getName())
        if n = "item" then
            r.push(c)
        else if n = "channel" then
            for each i in c.getChildElements()
                if lcase(i.getName()) = "item" then r.push(i)
            end for
        end if
    end for
    return r
end function

function getText(node as object, name as string) as string
    if node = invalid then return ""
    ln = lcase(name)
    for each c in node.getChildElements()
        if lcase(c.getName()) = ln then
            b = c.getBody()
            if b <> invalid then return b.tostr()
        end if
    end for
    return ""
end function

function firstPlayableUrl(item as object) as string
    ' enclosure first
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
    ' media:content fallback
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
    ' scan description/content/link text for .mp4 / .m3u8
    scan = getText(item, "description")
    if scan = "" then scan = getText(item, "content:encoded")
    if scan = "" then scan = getText(item, "link")
    return scanForMediaUrl(scan)
end function

function scanForMediaUrl(txt as string) as string
    if txt = invalid then return ""
    s = txt
    i = instr(1, s, "http")
    while i > 0
        j = i
        while j <= len(s)
            ch = mid(s, j, 1)
            if ch = " " or ch = chr(10) or ch = chr(13) or ch = """" or ch = "'" or ch = ")" or ch = "(" or ch = "<" or ch = ">" then exit while
            j = j + 1
        end while
        u = mid(s, i, j - i)
        lu = lcase(u)
        if endsWith(lu, ".m3u8") or endsWith(lu, ".mp4") then return u
        i = instr(i + 1, s, "http")
    end while
    return ""
end function

function endsWith(s as string, suf as string) as boolean
    if s = invalid or suf = invalid then return false
    ls = len(s) : lf = len(suf)
    if lf > ls then return false
    return mid(s, ls - lf + 1, lf) = suf
end function

function htmlToText(s as dynamic) as string
    if s = invalid then return ""
    txt = s.tostr()
    out = ""
    inTag = false
    for i = 1 to len(txt)
        ch = mid(txt, i, 1)
        if ch = "<" then
            inTag = true
        else if ch = ">" then
            inTag = false
        else if not inTag then
            out = out + ch
        end if
    end for
    ' normalize whitespace
    tmp = ""
    for i = 1 to len(out)
        ch = mid(out, i, 1)
        if ch = chr(10) or ch = chr(13) or ch = chr(9) then
            ch = " "
        end if
        tmp = tmp + ch
    end for
    res = ""
    spaceRun = false
    for i = 1 to len(tmp)
        ch = mid(tmp, i, 1)
        if ch = " " then
            if not spaceRun and len(res) > 0 then res = res + " "
            spaceRun = true
        else
            res = res + ch
            spaceRun = false
        end if
    end for
    ' trim trailing space
    if len(res) > 0 and mid(res, len(res), 1) = " " then res = left(res, len(res) - 1)
    return res
end function

function formatRfc822Date(raw as string) as string
    if raw = invalid or raw = "" then return ""
    ' Target YYYY-MM-DD; fallback raw
    parts = []
    token = ""
    for i = 1 to len(raw)
        ch = mid(raw, i, 1)
        if ch = " " then
            if token <> "" then parts.push(token) : token = ""
        else
            token = token + ch
        end if
    end for
    if token <> "" then parts.push(token)
    monthMap = { jan:"01", feb:"02", mar:"03", apr:"04", may:"05", jun:"06", jul:"07", aug:"08", sep:"09", oct:"10", nov:"11", dec:"12" }
    d = "" : m = "" : y = ""
    for i = 0 to parts.count() - 1
        tk = parts[i]
        if d = "" and isDigits(tk) and len(tk) <= 2 then
            d = tk
            if i + 1 < parts.count() then
                mm = lcase(parts[i + 1])
                if monthMap.doesExist(mm) then m = monthMap[mm]
            end if
            if i + 2 < parts.count() and isDigits(parts[i + 2]) and len(parts[i + 2]) = 4 then
                y = parts[i + 2]
            end if
            exit for
        end if
    end for
    if len(d) = 1 then d = "0" + d
    if d <> "" and m <> "" and y <> "" then return y + "-" + m + "-" + d
    return raw
end function

' NEW: Friendly date (e.g. "Sep 25, 2025")
function formatRfc822DateFriendly(raw as string) as string
    if raw = invalid or raw = "" then return ""
    ' Split tokens
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

    ' Find day / month / year
    mmMap = { jan:"Jan", feb:"Feb", mar:"Mar", apr:"Apr", may:"May", jun:"Jun", jul:"Jul", aug:"Aug", sep:"Sep", oct:"Oct", nov:"Nov", dec:"Dec" }
    day = "" : monTxt = "" : year = ""
    for i = 0 to parts.count() - 1
        tk = parts[i]
        ' Day is numeric (1–31)
        if day = "" and isDigits(tk) and len(tk) <= 2 then
            day = tk
            if i + 1 < parts.count() then
                m2 = lcase(parts[i + 1])
                if mmMap.doesExist(m2) then monTxt = mmMap[m2]
            end if
            if i + 2 < parts.count() and isDigits(parts[i + 2]) and len(parts[i + 2]) = 4 then
                year = parts[i + 2]
            end if
            exit for
        end if
    end for
    if day = "" or monTxt = "" or year = "" then return raw
    if len(day) = 1 then day = "0" + day
    ' Return e.g. "Sep 25, 2025"
    return monTxt + " " + day + ", " + year
end function

function isDigits(s as string) as boolean
    if s = invalid or s = "" then return false
    for i = 1 to len(s)
        ch = mid(s, i, 1)
        if ch < "0" or ch > "9" then return false
    end for
    return true
end function
