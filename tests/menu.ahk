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
Gui, PV:Show, w800 h600
WinActivate, ahk_id %pvhwnd%
WinWaitActive, ahk_id %pvhwnd%, , 2
try {
    Assert(!DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Menu initially hidden")
    SendLevel, 1
    GuiMenuSystemCommand(0xF100, 0, 0x112, pvhwnd)
    PostMessage, 0x112, 0xF100, 0,, ahk_id %pvhwnd%
    Sleep, 150
    Assert(pv_menu_visible && DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Alt attaches menu")
    SendEvent, {Esc}
    Sleep, 150
    Assert(!pv_menu_visible && !DllCall("GetMenu", "Ptr", pvhwnd, "Ptr"), "Escape hides menu")
    Assert(DllCall("IsWindow", "Ptr", pvhwnd), "Escape does not close viewer")
    FileAppend, PASS: Alt menu activation and dismissal`n, *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
}
Gui, PV:Destroy
Gdip_Shutdown(token)
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
