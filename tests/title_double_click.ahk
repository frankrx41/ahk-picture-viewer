#NoEnv
DetectHiddenWindows, On
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
exit_code := 0
GuiInitialize()
try {
    saved_clipboard := ClipboardAll
    Gui, PV:Show, w800 h600
    GuiShowImage(GetCurrentImagePath(), "fit_image", true)
    WinGet, before, MinMax, ahk_id %pvhwnd%
    Clipboard := "sentinel"
    SendMessage, 0xA3, 2, 0, , ahk_id %pvhwnd%
    Assert(Clipboard = GetCurrentImageName(), "Title double click copies filename")
    WinGet, after, MinMax, ahk_id %pvhwnd%
    Assert(before = after, "Title double click does not maximize")
    GuiToggleTitleDetails()
    Clipboard := "sentinel"
    SendMessage, 0xA3, 2, 0, , ahk_id %pvhwnd%
    Assert(Clipboard = GetCurrentImageName(), "Filename-only title copies same name")
    Clipboard := "sentinel"
    GuiTitleDoubleClick(3, 0, 0xA3, pvhwnd)
    GuiTitleDoubleClick(2, 0, 0xA3, pv_thumbnail.hwnd)
    Assert(Clipboard = "sentinel", "Other hit targets are ignored")
    GuiShowImage("")
    SendMessage, 0xA3, 2, 0, , ahk_id %pvhwnd%
    Assert(Clipboard = "sentinel", "Closed image does not copy stale filename")
    FileAppend, % "PASS: title double click; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
    Clipboard := saved_clipboard
    SetTimer, PreloadNextImage, Off
    SetTimer, GuiUpdateNavigation, Off
    ClearThumbnail()
    FilmstripClear()
    Gui, PV:Destroy
    image_cache.Clear()
    Gdip_Shutdown(token)
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
