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
    LoadAllFolderFiles()
    SetTimer, CacheFolderTick, Off
    Assert(InStr(FolderCacheStatus(), "Caching 0/2"), "Initial progress")
    CacheFolderTick()
    SetTimer, CacheFolderTick, Off
    Assert(folder_cache.done = 1 && folder_cache.active, "One file per tick")
    CacheFolderTick()
    Assert(!folder_cache.active && image_cache.entries.Count() = 2, "All files cached")
    Assert(InStr(FolderCacheStatus(), "Cached 2/2"), "Completion status")
    WinGetTitle, title, ahk_id %pvhwnd%
    Assert(InStr(title, "Cached 2/2"), "Window title reports completion")
    img_path_list := [img_path_list[1], A_ScriptDir "\missing.png"]
    LoadAllFolderFiles()
    SetTimer, CacheFolderTick, Off
    CacheFolderTick()
    SetTimer, CacheFolderTick, Off
    CacheFolderTick()
    Assert(folder_cache.failed = 1 && !folder_cache.active, "Bad files do not stop completion")
    Assert(InStr(FolderCacheStatus(), "1 failed"), "Failure status")
    LoadAllFolderFiles()
    SetTimer, CacheFolderTick, Off
    img_path_list := []
    CacheFolderTick()
    Assert(FolderCacheStatus() = "", "Folder change cancels stale work")
    LoadAllFolderFiles()
    Assert(FolderCacheStatus() = "", "Empty list is safe")
    FileAppend, % "PASS: folder caching; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
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

