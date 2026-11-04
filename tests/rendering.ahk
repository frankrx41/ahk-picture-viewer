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
Gui, PV:Show, w500 h400
bitmap := Gdip_CreateBitmap(2, 2)
Gdip_SetPixel(bitmap, 0, 0, 0xFFFF0000)
Gdip_SetPixel(bitmap, 1, 0, 0xFF00FF00)
Gdip_SetPixel(bitmap, 0, 1, 0xFF0000FF)
Gdip_SetPixel(bitmap, 1, 1, 0xFFFFFFFF)
try {
    ShowImageToControl(pvpic, bitmap, 20, 20)
    GuiControlGet, hwnd, PV:hwnd, pvpic
    handle := DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x173, "Ptr", 0, "Ptr", 0, "Ptr")
    copy := Gdip_CreateBitmapFromHBITMAP(handle)
    Assert((Gdip_GetPixel(copy, 5, 5) & 0xFFFFFF) = 0xFF0000, "Top-left is red")
    Assert((Gdip_GetPixel(copy, 15, 5) & 0xFFFFFF) = 0x00FF00, "Top-right is green")
    Assert((Gdip_GetPixel(copy, 5, 15) & 0xFFFFFF) = 0x0000FF, "Bottom-left is blue")
    Assert((Gdip_GetPixel(copy, 15, 15) & 0xFFFFFF) = 0xFFFFFF, "Bottom-right is white")
    Gdip_DisposeImage(copy)
    before := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Loop, 100
        ShowImageToControl(pvpic, bitmap, 20, 20)
    after := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Assert(after = before, "Repeated renders do not leak GDI handles")
    Assert(Gdip_GetPixel(bitmap, 0, 0) = 0xFFFF0000, "Cached source remains intact")
    FileAppend, PASS: direct rendering pixels and resource ownership`n, *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
    SetTimer, GuiUpdateNavigation, Off
    ClearThumbnail()
    FilmstripClear()
    Gui, PV:Destroy
    Gdip_DisposeImage(bitmap)
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
