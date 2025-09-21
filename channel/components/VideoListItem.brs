function init()
    m.poster = m.top.findNode("poster")
    m.title = m.top.findNode("title")
    m.focusRect = m.top.findNode("focusRect")
end function

function itemContentChanged()
    content = m.top.itemContent
    if content <> invalid
        m.poster.uri = content.hdPosterUrl
        m.title.text = content.title
    end if
end function

function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function

function onGainedFocus(event as object)
    m.focusRect.color = "0xFFFFFFFF"
    m.focusRect.opacity = 0.3
end function

function onLostFocus(event as object)
    m.focusRect.color = "0x00000000"
    m.focusRect.opacity = 0
end function