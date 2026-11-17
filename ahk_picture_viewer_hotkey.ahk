
;*******************************************************************************
; Hotkeys
#If WinActive("ahk_id " PVhwnd) && (!pv_menu_visible || pv_menu_pinned)

; ~LAlt up::
;     if( A_PriorKey == "LAlt" ) {
;         GuiMenuSystemCommand(0xF100, 0, 0x112, PVhwnd)
;         PostMessage, 0x112, 0xF100, 0,, ahk_id %PVhwnd%
;     }
; return

,::
Right::
    Gosub, NextPicture
return

.::
Left::
    Gosub, PrevPicture
return

^O::
    OpenFile()
return

^L::
    LoadAllFolderFiles()
return

^B::
    GuiToggleTitleDetails()
return

^T::
    GuiToggleMenuBar()
return

Esc::
    if( IsObject(folder_cache) && folder_cache.active ) {
        CancelFolderCache()
    } else {
        Gosub, Exit
    }
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
    GuiEndPointerDrag()
return

Space::
    if( GetZoomLevel("get_legacy") != "fit_width" ) {
        GuiShowImage(GetCurrentImagePath(), "fit_width", true)
    } else {
        GuiShowImage(GetCurrentImagePath(), "fit_window", true)
    }
    GuiUpdateTitle(GetCurrentImagePath())
return

Enter::
    WinMaximize, ahk_id %pvhwnd%
    GuiShowImage(GetCurrentImagePath(), "fit_image", true)
    GuiUpdateTitle(GetCurrentImagePath())
return

'::
    GuiShowImage(GetCurrentImagePath(), "fit_height", true)
    GuiUpdateTitle(GetCurrentImagePath())
return

`::
    GuiShowImage(GetCurrentImagePath(), "50%")
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
    GuiShowImage(GetCurrentImagePath(), "width_100px")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad7::
7::
    GuiShowImage(GetCurrentImagePath(), "width_200px")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad8::
8::
    GuiShowImage(GetCurrentImagePath(), "width_500px")
    GuiUpdateTitle(GetCurrentImagePath())
return

Numpad9::
9::
    GuiShowImage(GetCurrentImagePath(), "width_1000px")
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
    GuiShowImage(GetCurrentImagePath(), "", true)
return

Delete::
    path := GetCurrentImagePath()
    Gosub, NextPicture
    FileRecycle, %path%
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

; #If WinActive("ahk_id " PVhwnd) && pv_menu_visible
; Esc::
;     DllCall("EndMenu")
;     GuiHideMenu()
; return
#If
