sub Main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
    
    scene = screen.createScene("MainScene")
    screen.show()
    
    while(true)
        msg = wait(0, port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        else if msgType = "roSGNodeEvent"
            if msg.GetField() = "itemSelected"
                ' An item was selected from the list, show the video player
                selectedIndex = msg.GetData()
                scene.callFunc("playVideo", { index: selectedIndex })
            end if
        end if
    end while
end sub