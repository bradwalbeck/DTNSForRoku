sub init()
    m.top.functionName = "loadDTNSFeed"
end sub

sub loadDTNSFeed()
    http = createObject("roUrlTransfer")
    http.setURL("https://feeds.feedburner.com/daily_tech_news_show")
    http.setCertificatesFile("common:/certs/ca-bundle.crt")

    result = []
    res = http.GetToString()
    if res = invalid or res = "" then
        m.top.result = result : return
    end if

    xml = createObject("roXMLElement")
    if not xml.parse(res) then
        m.top.result = result : return
    end if

    ' Normalize root to <rss>
    root = xml
    if lcase(xml.getName()) <> "rss" and xml.rss <> invalid
        root = xml.rss
    end if

    if root = invalid or root.channel = invalid
        m.top.result = result : return
    end if

    ' Collect <item> nodes
    chChildren = root.channel.GetChildElements()
    if chChildren = invalid or chChildren.count() = 0
        m.top.result = result : return
    end if

    for i = 0 to chChildren.count() - 1
        node = chChildren[i]
        if lcase(node.getName()) = "item"
            item = parseItem(node)
            if item <> invalid then result.push(item)
        end if
    end for

    m.top.result = result
end sub

function parseItem(item as object) as object
    if item = invalid then return invalid

    title = ""
    if item.title <> invalid
        t = item.title.getText()
        if t <> invalid then title = t
    end if
    if title = "" then return invalid

    url = findVideoUrl(item)
    if url = invalid or url = "" then return invalid

    return { title: title, url: url }
end function

function findVideoUrl(item as object) as dynamic
    ' 1) Check <enclosure> elements for video/mp4 or .mp4
    encs = getNodes(item, "enclosure")
    for each enc in encs
        attrs = enc.getAttributes()
        if attrs <> invalid and attrs.url <> invalid
            u = attrs.url : mt = invalid
            if attrs.type <> invalid then mt = lcase(attrs.type)
            if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4"
                return u
            end if
        end if
    end for

    ' 2) Check <media:content> (namespaced) for video/mp4 or .mp4
    medias = getNodes(item, "media:content")
    for each m in medias
        attrs = m.getAttributes()
        if attrs <> invalid and attrs.url <> invalid
            u = attrs.url : mt = invalid
            if attrs.type <> invalid then mt = lcase(attrs.type)
            if (mt <> invalid and left(mt, 5) = "video") or right(lcase(u), 4) = ".mp4"
                return u
            end if
        end if
    end for

    ' 3) Fallback: scan description for an .mp4 URL (best-effort)
    if item.description <> invalid
        d = item.description.getText()
        if d <> invalid
            mp4pos = instr(1, lcase(d), ".mp4")
            if mp4pos > 0
                ' Walk back to start of URL (http/https)
                startHttp = instrrev(lcase(left(d, mp4pos)), "http")
                if startHttp > 0
                    u = mid(d, startHttp, mp4pos - startHttp + 4)
                    return u
                end if
            end if
        end if
    end if

    return invalid
end function

function getNodes(parent as object, tagName as string) as object
    nodes = []
    ' Property access (may yield single or array)
    child = invalid
    ' Try direct property if it exists (e.g., parent.enclosure)
    ' Use eval-like access via GetChildElements when in doubt
    kids = parent.GetChildElements()
    if kids <> invalid
        for each k in kids
            if lcase(k.getName()) = lcase(tagName)
                nodes.push(k)
            end if
        end for
    end if
    return nodes
end function