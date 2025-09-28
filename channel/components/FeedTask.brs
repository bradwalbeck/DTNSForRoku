sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    m.top.error = ""
    feedUrl = m.top.url
    if feedUrl = invalid or feedUrl = "" then feedUrl = "https://feeds.feedburner.com/daily_tech_news_show"

    urlTransfer = createObject("roUrlTransfer")
    urlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
    urlTransfer.enableEncodings(true)
    urlTransfer.setRequest("GET")
    urlTransfer.setUrl(feedUrl)
    urlTransfer.addHeader("User-Agent", "DTNSForRoku/1.0")
    urlTransfer.setPort(createObject("roMessagePort"))
    urlTransfer.setCertificatesDepth(3)
    urlTransfer.setMinimumTransferRate(1024, 10)
    feedData = urlTransfer.getToString()
    if feedData = invalid or feedData = "" then
        m.top.error = "empty feed"
        return
    end if

    xmlRoot = createObject("roXMLElement")
    if not xmlRoot.parse(feedData) then
        m.top.error = "xml parse"
        return
    end if

    episodeList = []
    for each xmlChild in xmlRoot.getChildElements()
        nodeName = lcase(xmlChild.getName())
        if nodeName = "channel" then
            for each channelChild in xmlChild.getChildElements()
                if lcase(channelChild.getName()) = "item" then processItem(channelChild, episodeList)
            end for
        else if nodeName = "item" then
            processItem(xmlChild, episodeList)
        end if
    end for

    if episodeList.count() = 0 then
        m.top.error = "no items"
    end if
    m.top.result = episodeList
end sub

sub processItem(itemNode as object, episodeList as object)
    if itemNode = invalid then return
    episodeTitle = nodeText(itemNode, "title")
    episodeMediaUrl = firstMedia(itemNode)
    if episodeTitle = "" or episodeMediaUrl = "" then return

    rawDescription = nodeText(itemNode, "description")
    if rawDescription = "" then rawDescription = nodeText(itemNode, "content:encoded")
    episodeDescription = stripHtml(rawDescription)

    rawPubDate = nodeText(itemNode, "pubDate")
    friendlyDateStr = friendlyDate(rawPubDate)
    relativeDateStr = relativeAge(rawPubDate)
    if friendlyDateStr <> "" and relativeDateStr <> "" then
        friendlyDateStr = friendlyDateStr + " • " + relativeDateStr
    end if

    episodeList.push({
        title: episodeTitle,
        url: episodeMediaUrl,
        description: episodeDescription,
        pubDate: rawPubDate,
        dateFriendly: friendlyDateStr
    })
end sub

function nodeText(xmlNode as object, tagName as string) as string
    if xmlNode = invalid then return ""
    desiredTag = lcase(tagName)
    for each childNode in xmlNode.getChildElements()
        if lcase(childNode.getName()) = desiredTag then
            body = childNode.getBody()
            if body <> invalid then return body.tostr()
        end if
    end for
    return ""
end function

function firstMedia(itemNode as object) as string
    if itemNode = invalid then return ""
    for each childNode in itemNode.getChildElements()
        if lcase(childNode.getName()) = "enclosure" then
            attributes = childNode.getAttributes()
            if attributes <> invalid and attributes["url"] <> invalid then
                mediaUrl = attributes["url"].tostr()
                if mediaUrl <> "" then return mediaUrl
            end if
        end if
    end for
    for each childNode in itemNode.getChildElements()
        if lcase(childNode.getName()) = "media:content" then
            attributes = childNode.getAttributes()
            if attributes <> invalid and attributes["url"] <> invalid then
                mediaUrl = attributes["url"].tostr()
                if mediaUrl <> "" then return mediaUrl
            end if
        end if
    end for
    return ""
end function

function stripHtml(input as dynamic) as string
    if input = invalid then return ""
    inputStr = input.tostr()
    if instr(1, inputStr, "<") = 0 then return collapseSpace(inputStr)
    outputStr = ""
    inTag = false
    for i = 1 to len(inputStr)
        char = mid(inputStr, i, 1)
        if char = "<" then
            inTag = true
        else if char = ">" then
            inTag = false
        else if not inTag then
            outputStr = outputStr + char
        end if
    end for
    return collapseSpace(outputStr)
end function

function collapseSpace(inputStr as string) as string
    result = ""
    spaceRun = false
    for i = 1 to len(inputStr)
        char = mid(inputStr, i, 1)
        if char <= " " then
            if not spaceRun and len(result) > 0 then result = result + " "
            spaceRun = true
        else
            result = result + char
            spaceRun = false
        end if
    end for
    if len(result) > 0 and right(result,1) = " " then result = left(result, len(result)-1)
    return result
end function

function friendlyDate(rawDate as string) as string
    if rawDate = invalid or rawDate = "" then return ""
    parts = []
    token = ""
    for i = 1 to len(rawDate)
        char = mid(rawDate, i, 1)
        if char = " " then
            if token <> "" then parts.push(token) : token = ""
        else
            token = token + char
        end if
    end for
    if token <> "" then parts.push(token)

    monthMap = { jan:"Jan", feb:"Feb", mar:"Mar", apr:"Apr", may:"May", jun:"Jun", jul:"Jul", aug:"Aug", sep:"Sep", oct:"Oct", nov:"Nov", dec:"Dec" }
    day = "" : month = "" : year = ""
    for i = 0 to parts.count() - 1
        part = parts[i]
        if isNumToken(part) then
            day = part
            if i + 1 < parts.count() then
                monthKey = lcase(parts[i + 1])
                if monthMap.doesExist(monthKey) then month = monthMap[monthKey]
            end if
            if i + 2 < parts.count() then
                yearToken = parts[i + 2]
                if len(yearToken) = 4 and isNumToken(yearToken) then year = yearToken
            end if
            exit for
        end if
    end for
    if day = "" or month = "" or year = "" then return ""
    if len(day) = 1 then day = "0" + day
    return month + " " + day + ", " + year
end function

function isNumToken(str as string) as boolean
    if str = invalid or str = "" then return false
    for i = 1 to len(str)
        char = mid(str, i, 1)
        if char < "0" or char > "9" then return false
    end for
    return true
end function

function relativeAge(rawDate as string) as string
    if rawDate = invalid or rawDate = "" then return ""
    friendly = friendlyDate(rawDate)
    if friendly = "" then return ""
    year = val(right(friendly,4))
    monthStr = left(friendly,3)
    dayStr = mid(friendly,5,2)
    monthMap = { Jan:1, Feb:2, Mar:3, Apr:4, May:5, Jun:6, Jul:7, Aug:8, Sep:9, Oct:10, Nov:11, Dec:12 }
    if not monthMap.doesExist(monthStr) then return ""
    month = monthMap[monthStr]
    day = val(dayStr)
    today = createObject("roDateTime") : today.toLocalTime()
    diff = dayNumber(today.getYear(), today.getMonth(), today.getDayOfMonth()) - dayNumber(year,month,day)
    if diff < 0 then return ""
    if diff = 0 then return "Today"
    if diff = 1 then return "Yesterday"
    if diff < 30 then return diff.tostr() + "d ago"
    if diff < 60 then return "1mo ago"
    if diff < 365 then return int(diff/30).tostr() + "mo ago"
    years = int(diff / 365)
    if years = 1 then return "1y ago"
    return years.tostr() + "y ago"
end function

function dayNumber(year as integer, month as integer, day as integer) as integer
    if month < 3 then year = year - 1 : month = month + 12
    return 365 * year + year / 4 - year / 100 + year / 400 + ((153 * (month - 3) + 2) / 5) + day - 1
end function
