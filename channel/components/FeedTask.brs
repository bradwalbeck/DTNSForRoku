sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    result = []

    ut = createObject("roUrlTransfer")
    ut.setCertificatesFile("common:/certs/ca-bundle.crt")
    ut.setUrl("https://feeds.feedburner.com/daily_tech_news_show")
    res = ut.GetToString()
    if res = invalid or res = "" then m.top.result = result : return

    xml = createObject("roXMLElement")
    if not xml.parse(res) then m.top.result = result : return

    rss = xml
    if lcase(xml.getName()) <> "rss" and xml.rss <> invalid then rss = xml.rss
    if rss = invalid or rss.channel = invalid then m.top.result = result : return

    kids = rss.channel.GetChildElements()
    if kids = invalid or kids.count() = 0 then m.top.result = result : return

    for i = 0 to kids.count() - 1
        node = kids[i]
        if lcase(node.getName()) = "item"
            title = ""
            if node.title <> invalid
                t = node.title.getText()
                if t <> invalid then title = t
            end if
            if title = "" then goto nextItem

            url = firstVideoUrl(node)
            if url <> invalid and url <> ""
                result.push({ title: title, url: url })
            end if
        end if
        nextItem:
    end for

    m.top.result = result
end sub

function firstVideoUrl(item)
    if item = invalid then return invalid
    kids = item.GetChildElements()
    if kids = invalid then return invalid

    for i = 0 to kids.count() - 1
        c = kids[i]
        n = lcase(c.getName())
        if n = "enclosure" or n = "media:content"
            a = c.getAttributes()
            if a <> invalid and a.url <> invalid
                u = a.url
                mt = invalid
                if a.type <> invalid then mt = lcase(a.type)
                if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4"
                    return u
                end if
            end if
        end if
    end for

    ' Optional: media:group/media:content
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