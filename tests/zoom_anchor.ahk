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
    WinActivate, ahk_id %pvhwnd%
    WinWaitActive, ahk_id %pvhwnd%, , 2
    bitmap := Gdip_CreateBitmap(1000, 1000)
    image_cache.entries["zoom-test"] := {bitmap: bitmap, bytes: 4000000}
    MouseMove, 300, 250, 0
    MouseGetPos, mx, my
    ; Cross both fit thresholds in both directions, including exact fit.
    for index, scale in [0.9, 0.8, 0.7, 0.6, 0.5, 0.6, 0.8, 1.0] {
        GuiControl, PV:Move, pvpic, x-200 y-150 w1000 h1000
        GuiGetImageSize(bitmap, scale, false, x, y, w, h)
        Assert(Abs((mx-x)/w - (mx+200)/1000) < 0.000001, "Horizontal mouse anchor at " scale)
        Assert(Abs((my-y)/h - (my+150)/1000) < 0.000001, "Vertical mouse anchor at " scale)
    }
    GuiGetImageSize(bitmap, 0.5, true, x, y, w, h)
    GetClientSize(pvhwnd, cw, ch)
    Assert(x = Round((cw-w)/2) && y = Round((ch-h)/2), "Explicit centered zoom stays centered")
    FileAppend, % "PASS: mouse anchored zoom; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
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

