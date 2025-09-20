sub init()
    m.top.functionName = "fetchAndParseFeed"
end sub

sub fetchAndParseFeed()
    print "--- [ContentTask] Task started. ---"
    port = CreateObject("roMessagePort")
    fetcher = CreateObject("roUrlTransfer")
    fetcher.SetMessagePort(port)
    fetcher.SetCertificatesFile("common:/certs/ca-bundle.crt")
    fetcher.EnablePeerVerification(true)
    fetcher.SetUrl("https://feeds.feedburner.com/daily_tech_news_show")
    
    print "--- [ContentTask] Starting async download... ---"
    if not fetcher.AsyncGetToString()
        print "--- [ContentTask] ERROR: AsyncGetToString() failed to start. ---"
        m.top.feedData = invalid
        return
    end if

    msg = wait(0, port)
    print "--- [ContentTask] Received message from port. Type: "; type(msg); " ---"

    if type(msg) = "roUrlEvent"
        responseCode = msg.GetResponseCode()
        print "--- [ContentTask] Fetch complete. Response code: "; responseCode; " ---"
        if responseCode = 200
            responseString = msg.GetString()
            print "--- [ContentTask] Response is OK. Calling ParseFeed. ---"
            m.top.feedData = ParseFeed(responseString)
            if m.top.feedData <> invalid
                print "--- [ContentTask] ParseFeed finished. Data count: "; m.top.feedData.count(); " ---"
            else
                 print "--- [ContentTask] ParseFeed returned invalid. ---"
            end if
        else
            print "--- [ContentTask] HTTP Error. Setting data to invalid. ---"
            m.top.feedData = invalid
        end if
    else
        print "--- [ContentTask] ERROR: Did not receive a roUrlEvent. ---"
        m.top.feedData = invalid
    end if

    print "--- [ContentTask] Task finished. ---"
end sub