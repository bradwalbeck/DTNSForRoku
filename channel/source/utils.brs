' filepath: c:\Repository\DTNSForRoku\channel\source\utils.brs
function GetVideoFeed() as object
    url = CreateObject("roUrlTransfer")
    url.SetUrl("https://feeds.feedburner.com/daily_tech_news_show")
    
    response = url.GetToString()
    xml = ParseXML(response)
    
    if xml = invalid then return []
    
    episodes = []
    items = xml.GetChildElements()
    
    for each item in items
        if item.getName() = "item"
            episode = {
                title: item.title.getText(),
                description: item.description.getText(),
                pubDate: item.pubDate.getText(),
                url: item.enclosure.url
            }
            episodes.push(episode)
        end if
    next
    
    return episodes
end function

function ParseXML(str as string) as object
    if str = invalid return invalid
    
    xml = CreateObject("roXMLElement")
    if not xml.Parse(str) return invalid
    
    return xml
end function