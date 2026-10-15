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
Gui, PV:Show, w800 h600, Folder strip test
WinActivate, ahk_id %pvhwnd%
WinWaitActive, ahk_id %pvhwnd%, , 2
GuiShowImage(GetCurrentImagePath(), "fit_window", true)
try {
    SetTimer, GuiUpdateNavigation, Off
    FilmstripUpdate(true, 400, 590, 800, 600)
    Assert(pv_filmstrip.visible, "Bottom hover shows strip")
    Loop, 3
        FilmstripUpdate(true, 400, 550, 800, 600)
    Assert(pv_filmstrip.previews.Count() = 2, "Folder thumbnails loaded")
    Assert(image_cache.entries.Count() = 1, "Previewing does not populate full-size cache")
    ControlClick, x150 y40, % "ahk_id " pv_filmstrip.hwnd, , Left, 1, NA
    Sleep, 50
    Assert(img_list_index = 2, "Click opens the selected file")
    FilmstripUpdate(true, 400, 300, 800, 600)
    Assert(!pv_filmstrip.visible, "Leaving bottom hides strip")
    ; Repeat entries to exercise scrolling in a long folder list.
    img_path_list := []
    Loop, 25
        img_path_list.Push(A_ScriptDir "\..\assets\clip_20230928_084336.png")
    img_list_index := 1
    FilmstripUpdate(true, 400, 590, 800, 600)
    FilmstripScroll(1)
    FilmstripUpdate(true, 400, 550, 800, 600)
    Assert(pv_filmstrip.first > 1, "Scroll reaches later thumbnails")
    Loop, 10
        FilmstripScroll(1)
    FilmstripUpdate(true, 400, 550, 800, 600)
    Assert(pv_filmstrip.first + pv_filmstrip.slots - 1 = 25, "Last folder item is reachable")
    FilmstripClick(28 + (pv_filmstrip.slots - 1) * 96 + 20)
    Assert(img_list_index = 25, "Click last item")
    before := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Loop, 100
        FilmstripRender()
    after := DllCall("GetGuiResources", "Ptr", DllCall("GetCurrentProcess", "Ptr"), "UInt", 0)
    Assert(after = before, "Strip redraws do not leak GDI handles")
    FilmstripUpdate(true, 300, 390, 640, 400)
    GuiControlGet, strip, PV:Pos, % pv_filmstrip.hwnd
    Assert(stripY = 292 && stripW = 640, "Strip follows window size")
    GuiShowImage("")
    FilmstripUpdate(true, 300, 390, 640, 400)
    Assert(!pv_filmstrip.visible, "Close hides strip")
    FileAppend, PASS: folder strip checks`n, *
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
