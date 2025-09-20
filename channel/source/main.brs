sub Main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.setMessagePort(port)
    
    scene = screen.createScene("MainScene")
    screen.show()
    
    ' The main event loop is now only responsible for detecting when the channel exits.
    ' All other event handling is done within the MainScene component.
    while(true)
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent" and msg.isScreenClosed()
            return
        end if
    end while
end sub