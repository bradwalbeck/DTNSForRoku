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
    if u = invalid or u = "" then return invalid

    d = ""
    if n.pubDate <> invalid
        pd = n.pubDate.getText()
        if pd <> invalid then d = left(pd, 16) ' trim e.g., "Mon, 01 Jan 20"
    end if

    thumb = firstImageUrl(n)

    return { title: t, url: u, date: d, thumb: thumb }
end function

function firstVideoUrl(item as object) as dynamic
    if item = invalid then return invalid
    kids = item.GetChildElements()
    if kids = invalid then return invalid

    ' enclosure or media:content
    for i = 0 to kids.count() - 1
        c = kids[i]
        n = lcase(c.getName())
        if n = "enclosure" or n = "media:content"
            a = c.getAttributes()
            if a <> invalid and a.url <> invalid
                u = a.url : mt = invalid
                if a.type <> invalid then mt = lcase(a.type)
                if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4"
                    return u
                end if
            end if
        end if
    end for

    ' media:group -> media:content
    for i = 0 to kids.count() - 1
        if lcase(kids[i].getName()) = "media:group"
            inner = kids[i].GetChildElements()
            if inner <> invalid
                for j = 0 to inner.count() - 1
                    if lcase(inner[j].getName()) = "media:content"
                        a = inner[j].getAttributes()
                        if a <> invalid and a.url <> invalid
                            u = a.url : mt = invalid
                            if a.type <> invalid then mt = lcase(a.type)
                            if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4"
                                return u
                            end if
                        end if
                    end if
                end for
            end if
        end if
    end for

    return invalid
end function

function firstImageUrl(item as object) as dynamic
    if item = invalid then return invalid
    kids = item.GetChildElements()
    if kids = invalid then return invalid

    ' media:thumbnail url=...
    for i = 0 to kids.count() - 1
        if lcase(kids[i].getName()) = "media:thumbnail"
            a = kids[i].getAttributes()
            if a <> invalid and a.url <> invalid then return a.url
        end if
    end for

    ' itunes:image href=...
    for i = 0 to kids.count() - 1
        if lcase(kids[i].getName()) = "itunes:image"
            a = kids[i].getAttributes()
            if a <> invalid and a.href <> invalid then return a.href
        end if
    end for

    return invalid
end function