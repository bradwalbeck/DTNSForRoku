sub init()
    m.top.functionName = "exacute"
end sub

sub exacute()
    result = []
    FEED_URL = "https://feeds.feedburner.com/daily_tech_news_show"
    MAX_ITEMS = 50

    ut = createObject("roUrlTransfer")
    ut.setCertificatesFile("common:/certs/ca-bundle.crt")
    ut.setUrl(FEED_URL)
    ' ut.EnableEncodings(true) ' optional; remove if this causes errors on your device
    ut.AddHeader("User-Agent", "DTNSForRoku/1.0")

    ' Manual retry (3 attempts, 2s wait)
    res = invalid
    for attempt = 1 to 3
        res = ut.GetToString()
        if res <> invalid and res <> "" then exit for
        sleep(2000)
    end for
    if res = invalid or res = "" then m.top.result = result : return

    xml = createObject("roXMLElement")
    if not xml.parse(res) then m.top.result = result : return

    rss = xml
    if lcase(xml.getName()) <> "rss" and xml.rss <> invalid then rss = xml.rss
    if rss = invalid or rss.channel = invalid then m.top.result = result : return

    kids = rss.channel.GetChildElements()
    if kids = invalid or kids.count() = 0 then m.top.result = result : return

    count = 0
    for i = 0 to kids.count() - 1
        if count >= MAX_ITEMS then exit for
        node = kids[i]
        if lcase(node.getName()) = "item"
            itm = parseItem(node)
            if itm <> invalid then
                result.push(itm)
                count = count + 1
            end if
        end if
    end for

    m.top.result = result
end sub

function parseItem(n as object) as dynamic
    if n = invalid then return invalid

    t = ""
    if n.title <> invalid
        tt = n.title.getText()
        if tt <> invalid then t = tt
    end if
    if t = "" then return invalid

    u = firstVideoUrl(n)
    if u = invalid or u = "" then
        ' Fallbacks: feedburner:origEnclosureLink, content:encoded, description, link
        fb = firstTextOf(n, "feedburner:origEnclosureLink")
        if fb <> invalid and fb <> "" then u = scanTextForMediaUrl(fb)
    end if
    if (u = invalid or u = "") then
        ce = firstTextOf(n, "content:encoded")
        if ce <> invalid and ce <> "" then u = scanTextForMediaUrl(ce)
    end if
    if (u = invalid or u = "") and n.description <> invalid
        d = n.description.getText()
        if d <> invalid then u = scanTextForMediaUrl(d)
    end if
    if (u = invalid or u = "") and n.link <> invalid
        lk = n.link.getText()
        if lk <> invalid then u = scanTextForMediaUrl(lk)
    end if

    if u = invalid or u = "" then return invalid

    return { title: t, url: u }
end function

function firstVideoUrl(item as object) as dynamic
    if item = invalid then return invalid
    kids = item.GetChildElements()
    if kids = invalid then return invalid

    ' 1) enclosure, media:content
    for i = 0 to kids.count() - 1
        c = kids[i]
        n = lcase(c.getName())
        if n = "enclosure" or n = "media:content"
            a = c.getAttributes()
            if a <> invalid and a.url <> invalid
                u = a.url
                mt = invalid
                if a.type <> invalid then mt = lcase(a.type)
                if (mt <> invalid and left(mt, 5) = "video") or hasMediaExt(u) then return u
            end if
        end if
    end for

    ' 2) media:group -> media:content
    for i = 0 to kids.count() - 1
        if lcase(kids[i].getName()) = "media:group"
            inner = kids[i].GetChildElements()
            if inner <> invalid
                for j = 0 to inner.count() - 1
                    if lcase(inner[j].getName()) = "media:content"
                        a = inner[j].getAttributes()
                        if a <> invalid and a.url <> invalid
                            u = a.url
                            mt = invalid
                            if a.type <> invalid then mt = lcase(a.type)
                            if (mt <> invalid and left(mt, 5) = "video") or hasMediaExt(u) then return u
                        end if
                    end if
                end for
            end if
        end if
    end for

    return invalid
end function

' Get first child text by element name (case-insensitive, supports namespaced like "content:encoded")
function firstTextOf(parent as object, tagName as string) as dynamic
    if parent = invalid then return invalid
    kids = parent.GetChildElements()
    if kids = invalid then return invalid
    tgt = lcase(tagName)
    for i = 0 to kids.count() - 1
        if lcase(kids[i].getName()) = tgt
            txt = kids[i].getText()
            if txt <> invalid then return txt
        end if
    end for
    return invalid
end function

' Return true if URL string looks like mp4 or m3u8
function hasMediaExt(u as dynamic) as boolean
    if u = invalid then return false
    ul = lcase(u)
    if right(ul, 4) = ".mp4" then return true
    if instr(1, ul, ".m3u8") > 0 then return true
    return false
end function

' Scan arbitrary text for the first http/https URL containing .mp4 or .m3u8
function scanTextForMediaUrl(s as dynamic) as dynamic
    if s = invalid then return invalid
    txt = s
    tl  = lcase(s)
    start = instr(1, tl, "http")
    while start > 0
        ' find end at first whitespace or common delimiter
        e1 = findFirstOf(tl, start, " ")
        e2 = findFirstOf(tl, start, "`t")  ' tab
        e3 = findFirstOf(tl, start, "`r")
        e4 = findFirstOf(tl, start, "`n")
        e5 = findFirstOf(tl, start, """")  ' quote
        e6 = findFirstOf(tl, start, "'")
        e7 = findFirstOf(tl, start, "<")
        e8 = findFirstOf(tl, start, ")")
        e9 = findFirstOf(tl, start, "]")
        e10 = findFirstOf(tl, start, "(")
        e11 = findFirstOf(tl, start, ">")
        ' choose smallest positive end
        ending = 0
        endings = [e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11]
        for i = 0 to endings.count()-1
            v = endings[i]
            if v > 0 and (ending = 0 or v < ending) then ending = v
        end for
        if ending = 0 then ending = len(tl) + 1

        cand = mid(txt, start, ending - start)
        if hasMediaExt(cand) then return cand

        start = instr(start + 1, tl, "http")
    end while
    return invalid
end function

' Find index (1-based) of the first occurrence of any character in "chars" at or after "fromPos"
function findFirstOf(s as string, fromPos as integer, chars as string) as integer
    if s = invalid or chars = invalid then return 0
    best = 0
    for i = 1 to len(chars)
        ch = mid(chars, i, 1)
        p = instr(fromPos, s, ch)
        if p > 0 and (best = 0 or p < best) then best = p
    end for
    return best
end function