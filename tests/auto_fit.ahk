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
    for index, size in [[4000, 2000], [1000, 6000], [100, 6000], [800, 600]] {
        path := "generated-" index
        bitmap := Gdip_CreateBitmap(size[1], size[2])
        image_cache.entries[path] := {bitmap: bitmap, bytes: size[1]*size[2]*4}
        img_path_list := [path], img_list_index := 1
        GuiShow()
        GuiShowImage(path, "auto", true)
        Sleep, 50
        GetClientSize(pvhwnd, cw, ch)
        GuiControlGet, picture, PV:Pos, pvpic
        Assert(pictureW <= cw && pictureH <= ch, "Image fits client: " path)
        Assert(pictureX >= 0 && pictureY >= 0, "Image starts inside client: " path)
        monitor := DllCall("MonitorFromWindow", "Ptr", pvhwnd, "UInt", 2, "Ptr")
        VarSetCapacity(info, 40, 0)
        NumPut(40, info, 0, "UInt")
        DllCall("GetMonitorInfo", "Ptr", monitor, "Ptr", &info)
        WinGetPos, x, y, w, h, ahk_id %pvhwnd%
        Assert(x >= NumGet(info, 20, "Int") && y >= NumGet(info, 24, "Int"), "Window origin fits")
        Assert(x+w <= NumGet(info, 28, "Int") && y+h <= NumGet(info, 32, "Int"), "Window bounds fit: " path " " x "," y " " w "x" h " work " NumGet(info, 28, "Int") "x" NumGet(info, 32, "Int"))
        GuiShowImage(path, "last", true)
        GuiControlGet, picture, PV:Pos, pvpic
        Assert(pictureW <= cw && pictureH <= ch, "Last zoom preserves fit")
    }
    FileAppend, % "PASS: automatic fit; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
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
