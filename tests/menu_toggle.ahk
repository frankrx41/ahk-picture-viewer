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
    Assert(!DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Menu initially hidden")
    GuiToggleMenuBar()
    Assert(pv_menu_visible && pv_menu_pinned && DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Toggle attaches menu bar")
    GuiMenuExit(0, 0, 0x212, pvhwnd)
    GuiMenuActivate(0, 0, 0x6, pvhwnd)
    Sleep, 50
    Assert(DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Pinned bar survives dismissal and deactivation")
    GuiToggleMenuBar()
    Assert(!pv_menu_visible && !pv_menu_pinned && !DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Toggle detaches menu bar")
    Loop, 5 {
        GuiToggleMenuBar()
        GuiToggleMenuBar()
    }
    Assert(!pv_menu_visible, "Repeated toggles remain consistent")
    FileAppend, % "PASS: menu bar toggle; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
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
