
;*******************************************************************************
; Hotkeys
#If WinActive("ahk_id " PVhwnd)

Right::
    Gosub, NextPicture
return

Left::
    Gosub, PrevPicture
return

^O::
    OpenFile()
return

Esc::
    Gosub, Exit
return

Up::
    GuiShowImage(GetCurrentImagePath(), "+1", true)
    GuiUpdateTitle(GetCurrentImagePath())
return

Down::
    GuiShowImage(GetCurrentImagePath(), "-1", true)
    GuiUpdateTitle(GetCurrentImagePath())
return

~LButton up::
    SetTimer, DragTimer, Off
return

Space::
    if( GetZoomLevel("get_legacy") != "fit_width" ) {
        GuiShowImage(GetCurrentImagePath(), "fit_width")
    } else {
        GuiShowImage(GetCurrentImagePath(), "fit_window", true)
    }
    GuiUpdateTitle(GetCurrentImagePath())
return

Enter::
    WinMaximize, ahk_id %pvhwnd%
    GuiShowImage(GetCurrentImagePath(), "fit_image")
    GuiUpdateTitle(GetCurrentImagePath())
return

'::
    GuiShowImage(GetCurrentImagePath(), "fit_height")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad1::
1::
    GuiShowImage(GetCurrentImagePath(), "100%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad2::
2::
    GuiShowImage(GetCurrentImagePath(), "200%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad3::
3::
    GuiShowImage(GetCurrentImagePath(), "300%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad4::
4::
    GuiShowImage(GetCurrentImagePath(), "400%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad5::
5::
    GuiShowImage(GetCurrentImagePath(), "500%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad6::
6::
    GuiShowImage(GetCurrentImagePath(), "1000%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad7::
7::
    GuiShowImage(GetCurrentImagePath(), "2000%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad8::
8::
    GuiShowImage(GetCurrentImagePath(), "4000%")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad9::
9::
    GuiShowImage(GetCurrentImagePath(), "8000%")
    GuiUpdateTitle(GetCurrentImagePath())
return

\::
    WinMaximize, ahk_id %pvhwnd%

/::
    if( GetZoomLevel("get_legacy") != "fit_window" ) {
        GuiShowImage(GetCurrentImagePath(), "fit_window", true)
    } else {
        GuiShowImage(GetCurrentImagePath(), "100%", true)
    }
    GuiUpdateTitle(GetCurrentImagePath())
return

; Fit window to image size
BackSpace::
    GuiShow("fit_size")
    GuiShowImage(GetCurrentImagePath(), "")
return

Delete::
    FileRecycle, % GetCurrentImagePath()
    Gosub, NextPicture
    ImageListInitialize(GetCurrentImagePath())
    GuiUpdateTitle(GetCurrentImagePath())
return

^C::
    Gosub, CopyToClipboard
return

^+C::
    GoSub, CopyAsPath
return

!Enter::
    Gosub, ViewFileProperties
return

#If
