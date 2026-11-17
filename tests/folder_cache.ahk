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
    ; Drive cache ticks explicitly; background preload must not affect counts.
    Critical, On
    CancelFolderCache()
    GuiUpdateTitle("")
    WinGetTitle, title, ahk_id %pvhwnd%
    Assert(InStr(title, "Cached 0/2 | Cache memory: 0.0 MiB"), "Empty cache count and size visible without folder job")
    image_cache.bytes := 4 * 1024 * 1024 * 1024
    Assert(InStr(FolderCacheStatus(), "4.00 GiB"), "Cache size supports more than 32-bit bytes")
    image_cache.bytes := 0
    image_cache.Get(img_path_list[1])
    GuiUpdateTitle(GetCurrentImagePath())
    WinGetTitle, title, ahk_id %pvhwnd%
    Assert(InStr(title, "Cached 1/2"), "Ordinary viewing counts without folder job")
    image_cache.Get(img_path_list[1])
    Assert(InStr(FolderCacheStatus(), "Cached 1/2"), "Revisiting does not double-count")
    LoadAllFolderFiles()
    SetTimer, CacheFolderTick, Off
    Assert(InStr(FolderCacheStatus(), "Caching 1/2"), "Initial progress")
    CacheFolderTick()
    SetTimer, CacheFolderTick, Off
    Assert(folder_cache.done = 1 && folder_cache.active, "One file per tick")
    CacheFolderTick()
    Assert(!folder_cache.active && image_cache.entries.Count() = 2, "All files cached")
    Assert(InStr(FolderCacheStatus(), "Cached 2/2"), "Cache counts all distinct decoded images")
    Assert(InStr(FolderCacheStatus(), "Cached 2/2"), "Completion status")
    WinGetTitle, title, ahk_id %pvhwnd%
    Assert(InStr(title, "Cached 2/2"), "Window title reports completion")
    Assert(InStr(title, FolderCacheStatus()), "Title includes memory size during folder caching")
    CancelFolderCache()
    GuiUpdateTitle(GetCurrentImagePath())
    WinGetTitle, title, ahk_id %pvhwnd%
    Assert(InStr(title, FolderCacheStatus()), "Cache size remains after clearing folder job")
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
    Assert(InStr(FolderCacheStatus(), "Cached 0/0"), "Folder change cancels stale work")
    LoadAllFolderFiles()
    Assert(InStr(FolderCacheStatus(), "Cached 0/0"), "Empty list is safe")
    FileAppend, % "PASS: folder caching; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
    SetTimer, PreloadNextImage, Off
    SetTimer, CacheFolderTick, Off
    SetTimer, GuiUpdateNavigation, Off
    ClearThumbnail()
    FilmstripClear()
    Gui, PV:Destroy
    image_cache.Clear()
    Gdip_Shutdown(token)
    Critical, Off
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
