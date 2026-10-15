#NoEnv
#SingleInstance Off
SetBatchLines, -1
CoordMode, Mouse, Client
SetWorkingDir, %A_ScriptDir%\..
#Include %A_ScriptDir%\..\lib\Gdip.ahk
token := Gdip_Startup()
image_cache := new BitmapCache()
min_width := 500
img_path_list := [A_ScriptDir "\..\assets\clip_20230928_084336.png", A_ScriptDir "\..\assets\clip_20230928_084524.png"]
img_list_index := 1
VarSetCapacity(original_mouse, 8, 0)
DllCall("GetCursorPos", "Ptr", &original_mouse)
exit_code := 0
GuiInitialize()
Gui, PV:Show, w800 h600, Navigation test
WinActivate, ahk_id %pvhwnd%
WinWaitActive, ahk_id %pvhwnd%, , 2
GuiShowImage(GetCurrentImagePath(), "fit_window", true)
try {
    Assert(!DllCall("IsWindowVisible", "Ptr", pv_thumbnail.hwnd), "Thumbnail hidden when image fits")
    GuiShowImage(GetCurrentImagePath(), "1000%", true)
    Assert(DllCall("IsWindowVisible", "Ptr", pv_thumbnail.hwnd), "Thumbnail visible for oversized image")
    GuiControlGet, thumb, PV:Pos, % pv_thumbnail.hwnd
    Assert(thumbX + thumbW = 788 && thumbY + thumbH = 476, "Thumbnail anchored bottom right")
    BeginThumbnailDrag(0, 0)
    PanFromThumbnail(-100, -100)
    EndThumbnailDrag()
    GuiControlGet, picture, PV:Pos, pvpic
    Assert(pictureX = 0 && pictureY = 0, "Drag to top-left clamps to image origin")
    BeginThumbnailDrag(pv_thumbnail.w, pv_thumbnail.h)
    PanFromThumbnail(pv_thumbnail.w + 100, pv_thumbnail.h + 100)
    EndThumbnailDrag()
    GuiControlGet, picture, PV:Pos, pvpic
    Assert(pictureX = 800 - pictureW && pictureY = 600 - pictureH, "Drag to bottom-right clamps to image edge")
    ControlClick, x1 y1, % "ahk_id " pv_thumbnail.hwnd, , Left, 1, NA
    Sleep, 50
    GuiControlGet, picture, PV:Pos, pvpic
    Assert(pictureX = 0 && pictureY = 0, "Thumbnail mouse click pans instead of dragging the main image")
    before := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Loop, 100
        PanFromThumbnail(Mod(A_Index, pv_thumbnail.w), Mod(A_Index, pv_thumbnail.h))
    after := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Assert(after = before, "Repeated thumbnail draws do not leak GDI handles")
    Gui, PV:Show, w640 h400
    Sleep, 100
    GuiControlGet, thumb, PV:Pos, % pv_thumbnail.hwnd
    Assert(thumbX + thumbW = 628 && thumbY + thumbH = 276, "Thumbnail follows resized window")
    GuiShowImage(GetCurrentImagePath(), "fit_window", true)
    Assert(!DllCall("IsWindowVisible", "Ptr", pv_thumbnail.hwnd), "Fit hides thumbnail")
    GuiShowImage(GetCurrentImagePath(), "1000%", true)
    GuiShowImage("")
    Assert(!DllCall("IsWindowVisible", "Ptr", pv_thumbnail.hwnd), "Close hides thumbnail")
    FileAppend, PASS: thumbnail navigation checks`n, *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
    SetTimer, GuiUpdateNavigation, Off
    ClearThumbnail()
    FilmstripClear()
    Gui, PV:Destroy
    image_cache.Clear()
    Gdip_Shutdown(token)
    DllCall("SetCursorPos", "Int", NumGet(original_mouse, 0, "Int"), "Int", NumGet(original_mouse, 4, "Int"))
}
ExitApp, % exit_code
Assert(condition, message) {
    if(!condition)
        throw Exception(message)
}
#Include %A_ScriptDir%\..\ahk_picture_viewer_gui.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_image.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_lib.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_file.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_menu.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_hotkey.ahk


#Include %A_ScriptDir%\..\ahk_picture_viewer_filmstrip.ahk
