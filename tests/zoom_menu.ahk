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
    Gui, PV:Show, w800 h600
    bitmap := Gdip_CreateBitmap(600, 400)
    image_cache.entries["menu-test"] := {bitmap: bitmap, bytes: 960000}
    img_path_list := ["menu-test"], img_list_index := 1
    GuiShowImage("menu-test", "100%", true)
    for index, percent in [25, 50, 75, 100, 150, 200, 300, 400, 500, 1000] {
        MenuSetZoom(percent "%")
        GuiControlGet, picture, PV:Pos, pvpic
        Assert(pictureW = 600 * percent / 100 && pictureH = 400 * percent / 100, "Menu scale " percent)
        Assert(GetZoomLevel("get_legacy") = percent "%", "Zoom method remembered")
    }
    for index, method in ["fit_width", "fit_height", "fit_image", "fit_window", "auto"] {
        MenuSetZoom(method)
        Assert(GetZoomLevel("get_legacy") = method, "Fit action " method)
        WinGetTitle, title, ahk_id %pvhwnd%
        Assert(InStr(title, method), "Title updated for " method)
    }
    GuiShowImage("")
    previous := GetZoomLevel("get_legacy")
    MenuSetZoom("200%")
    Assert(GetZoomLevel("get_legacy") = previous && !pv_has_image, "Closed image is not reopened")
    FileAppend, % "PASS: zoom menu; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
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
