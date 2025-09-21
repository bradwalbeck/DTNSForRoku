sub init()
    m.top.functionName = "loadDTNSFeed"
end sub

sub loadDTNSFeed()
    result = []

    ut = createObject("roUrlTransfer")
    ut.setURL("https://feeds.feedburner.com/daily_tech_news_show")
    ut.setCertificatesFile("common:/certs/ca-bundle.crt")
    res = ut.GetToString()
    if res = invalid or res = "" then m.top.result = result : return

    xml = createObject("roXMLElement")
    if not xml.parse(res) then m.top.result = result : return

    root = xml
    if lcase(xml.getName()) <> "rss" and xml.rss <> invalid then root = xml.rss
    if root = invalid or root.channel = invalid then m.top.result = result : return

    kids = root.channel.GetChildElements()
    if kids = invalid or kids.count() = 0 then m.top.result = result : return

    for i = 0 to kids.count() - 1
        n = kids[i]
        if lcase(n.getName()) = "item"
            itm = parseItem(n)
            if itm <> invalid then result.push(itm)
        end if
    end for

    m.top.result = result
end sub

function parseItem(n)
    if n = invalid then return invalid

    t = ""
    if n.title <> invalid
        tt = n.title.getText()
        if tt <> invalid then t = tt
    end if
    if t = "" then return invalid

    u = findVideoUrl(n)
    if u = invalid or u = "" then return invalid

    return { title: t, url: u }
end function

function findVideoUrl(n)
    encs = findChildren(n, "enclosure")
    for j = 0 to encs.count() - 1
        e = encs[j]
        a = e.getAttributes()
        if a <> invalid and a.url <> invalid
            u = a.url
            mt = invalid
            if a.type <> invalid then mt = lcase(a.type)
            if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4" then return u
        end if
    end for

    medias = findChildren(n, "media:content")
    for j = 0 to medias.count() - 1
        m = medias[j]
        a = m.getAttributes()
        if a <> invalid and a.url <> invalid
            u = a.url
            mt = invalid
            if a.type <> invalid then mt = lcase(a.type)
            if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4" then return u
        end if
    end for

    groups = findChildren(n, "media:group")
    for g = 0 to groups.count() - 1
        inner = findChildren(groups[g], "media:content")
        for j = 0 to inner.count() - 1
            m = inner[j]
            a = m.getAttributes()
            if a <> invalid and a.url <> invalid
                u = a.url
                mt = invalid
                if a.type <> invalid then mt = lcase(a.type)
                if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4" then return u
            end if
        end for
    end for

    if n.description <> invalid
        d = n.description.getText()
        if d <> invalid
            dl = lcase(d)
            p = instr(1, dl, ".mp4")
            if p > 0
                s = instrRev(left(dl, p), "http")  ' replace instrrev(...) with instrRev(...)
                if s > 0 then return mid(d, s, p - s + 4)
            end if
        end if
    end if

    return invalid
end function

function findChildren(parent, name)
    out = []
    if parent = invalid then return out
    kids = parent.GetChildElements()
    if kids = invalid then return out
    tgt = lcase(name)
    for i = 0 to kids.count() - 1
        c = kids[i]
        if lcase(c.getName()) = tgt then out.push(c)
    end for
    return out
end function

' Helper: last occurrence of substring (returns 0 if not found)
function instrRev(haystack as string, needle as string) as integer
    if haystack = invalid or needle = invalid then return 0
    last = 0
    idx = instr(1, haystack, needle)
    while idx > 0
        last = idx
        idx = instr(last + 1, haystack, needle)
    end while
    return last
end function