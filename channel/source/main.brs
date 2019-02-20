
' 1st function called when channel application starts.
sub Main(input as Dynamic)
  print "################"
  print "Start of Channel"
  print "################"
  
  showHeroScreen(input)

end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen(input as object)
  print "main.brs - [showHeroScreen]"
  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  scene = screen.CreateScene("VideoScene")
  m.global = screen.getGlobalNode()
  'Deep link params
  m.global.addFields({ input: input })
  screen.show()

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    end if
  end while
end sub
