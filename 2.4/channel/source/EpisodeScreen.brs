sub ShowEpisodeScreen(show, leftBread, rightBread)
	mp4$ = "mp4"
	mp3$ = "mp3"
	screen = CreateObject("roPosterScreen")
	screen.SetMessagePort(CreateObject("roMessagePort"))
  screen.SetListStyle("flat-episodic")
  screen.SetBreadcrumbText(leftBread, rightBread)
	screen.Show()
	
	mrss = NWM_MRSS(show.url)
	content = mrss.GetEpisodes()
	selectedEpisode = 0
	screen.SetContentList(content)
	screen.Show()

	while true
		msg = wait(0, screen.GetMessagePort())
		
		if msg <> invalid
			if msg.isScreenClosed()
				exit while
			else if msg.isListItemFocused()
				selectedEpisode = msg.GetIndex()
			else if msg.isListItemSelected() Then
				if content[selectedEpisode].sdpsterurl.Right(3) = "mp4"
				    ShowVideoScreen(content[selectedEpisode])
				    screen.SetFocusedListItem(selectedEpisode)
					'screen.Show()
					PrintAA("this is an MP4")
				else if content[selectedEpisode].sdpsterurl.Right(3) = "mp3"
					PrintAA("this is an MP3")
				end if
			else if msg.isRemoteKeyPressed()
        if msg.GetIndex() = 13
					if content[selectedEpisode].sdpsterurl.Right(3) = "mp4"
					    ShowVideoScreen(content[selectedEpisode])
						PrintAA("this is an MP4")
					else if content[selectedEpisode].sdpsterurl.Right(3) = "mp3"
						PrintAA("this is an MP3")
					end if
				end if
			end if
		end if
	end while
end sub

