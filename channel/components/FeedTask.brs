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
        friendly = ""
        if rawPub <> "" then
            ' Inline friendly date: look for numeric day then month abbrev then year
            parts = []
            token = ""
            for i = 1 to len(rawPub)
                ch = mid(rawPub, i, 1)
                if ch = " " then
                    if token <> "" then parts.push(token) : token = ""
                else
                    token = token + ch
                end if
            end for
            if token <> "" then parts.push(token)

            mmMap = { jan:"Jan", feb:"Feb", mar:"Mar", apr:"Apr", may:"May", jun:"Jun", jul:"Jul", aug:"Aug", sep:"Sep", oct:"Oct", nov:"Nov", dec:"Dec" }
            for i = 0 to parts.count()-3
                dpart = parts[i]
                if isDayNumber(dpart) then
                    mkey = lcase(parts[i+1])
                    ypart = parts[i+2]
                    if mmMap.doesExist(mkey) and len(ypart) = 4 and isYearNumber(ypart) then
                        day = dpart
                        if len(day)=1 then day = "0"+day
                        friendly = mmMap[mkey] + " " + day + ", " + ypart
                        exit for
                    end if
                end if
            end for
            if friendly = "" then friendly = rawPub
        end if

        prefix = friendly
        if prefix <> "" then
            descOut = prefix + chr(10) + desc
        else
            descOut = desc
        end if

        episodes.push({
            title: title,
            url: media,
            description: descOut
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
    for each c in item.getChildElements()
        if lcase(c.getName()) = "enclosure" then
            a = c.getAttributes()
            if a <> invalid and a["url"] <> invalid then
                u = a["url"].tostr()
                if u <> "" then return u
            end if
        end if
    end for
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
    if instr(1, t, "<") = 0 then
        return trimWhitespace(t)
    end if
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
    return trimWhitespace(out)
end function

function trimWhitespace(src as string) as string
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

function isDayNumber(s as string) as boolean
    if s = invalid or s = "" then return false
    for i = 1 to len(s)
        ch = mid(s,i,1)
        if ch < "0" or ch > "9" then return false
    end for
    return true
end function

function isYearNumber(s as string) as boolean
    if len(s) <> 4 then return false
    return isDayNumber(s)
end function
