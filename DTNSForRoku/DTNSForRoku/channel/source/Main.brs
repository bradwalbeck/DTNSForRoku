sub Main()
	categories = LoadConfig()
	
	if categories.Count() > 1
		ShowPosterScreen(categories, "MRSS", "Template")
	else
		ShowEpisodeScreen(categories[0], categories[0].shortDescriptionLine1, "")
	end if
end sub

function LoadConfig()
	result = []

	app = CreateObject("roAppManager")
	theme = CreateObject("roAssociativeArray")
	theme.OverhangSliceSD = "pkg:/images/overhang_slice_sd.png"
	theme.OverhangSliceHD = "pkg:/images/overhang_slice_hd.png"
	theme.OverhanglogoHD = "pkg:/images/overhang_logo_hd.png"
	theme.OverhanglogoSD = "pkg:/images/overhang_logo_sd.png"

	theme.OverhangPrimaryLogoOffsetHD_X = "100"
	theme.OverhangPrimaryLogoOffsetHD_Y = "60"

	theme.OverhangPrimaryLogoOffsetSD_X = "60"
	theme.OverhangPrimaryLogoOffsetSD_Y = "40"

	raw = ReadASCIIFile("pkg:/config.opml")
	opml = CreateObject("roXMLElement")
	if opml.Parse(raw)
		theme.backgroundColor = ValidStr(opml.body@backgroundColor)
		theme.breadcrumbTextLeft = ValidStr(opml.body@leftBreadcrumbColor)
		theme.breadcrumbDelimiter = ValidStr(opml.body@rightBreadcrumbColor)
		theme.breadcrumbTextRight = ValidStr(opml.body@rightBreadcrumbColor)
		
		theme.posterScreenLine1Text = ValidStr(opml.body@posterScreenTitleColor)
		theme.posterScreenLine2Text = ValidStr(opml.body@posterScreenSubtitleColor)
		theme.episodeSynopsisText = ValidStr(opml.body@posterScreenSynopsisColor)

		for each category in opml.body.outline
			result.Push(BuildCategory(category))
		next
	end if

	app.SetTheme(theme)
	
	return result
end function

function BuildCategory(category)
	result = {
		shortDescriptionLine1:	ValidStr(category@title)
		shortDescriptionLine2:	ValidStr(category@subtitle)
		sdPosterURL:						ValidStr(category@img)
		hdPosterURL:						ValidStr(category@img)
		url:										ValidStr(category@url)
		categories:							[]
	}
	
	if category.outline.Count() > 0
		for each subCategory in category.outline
			result.categories.Push(BuildCategory(subCategory))
		next
	end if
	
	return result
end function
