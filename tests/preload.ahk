#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include %A_ScriptDir%\..\lib\Gdip.ahk
token := Gdip_Startup()
image_cache := new SlowCache()
a := A_ScriptDir "\..\assets\clip_20230928_084336.png"
b := A_ScriptDir "\..\assets\clip_20230928_084524.png"
exit_code := 0
try {
    pv_has_image := true
    img_path_list := [], img_list_index := 0
    PreloadNextImage()
    Assert(image_cache.entries.Count() = 0, "Empty list")
    img_path_list := [a], img_list_index := 1
    PreloadNextImage()
    Assert(image_cache.entries.Count() = 0, "Single image")
    img_path_list := [a, b], pv_has_image := false
    PreloadNextImage()
    Assert(image_cache.entries.Count() = 0, "Closed image")
    pv_has_image := true
    PreloadNextImage()
    Assert(image_cache.entries.HasKey(b), "Next image cached")
    first := image_cache.Get(b), bytes := image_cache.bytes
    PreloadNextImage()
    Assert(image_cache.Get(b) = first && image_cache.bytes = bytes, "Repeated preload reuses bitmap")
    img_list_index := 2
    PreloadNextImage()
    Assert(image_cache.entries.HasKey(a), "Wraparound")
    img_path_list := [a, A_ScriptDir "\missing.png"], img_list_index := 1
    PreloadNextImage()
    Assert(image_cache.entries.Count() = 2, "Missing file skipped")
    image_cache.Clear()
    img_path_list := [a, b], img_list_index := 1
    navigation_ran := false, navigation_during_load := false
    image_cache.slow := true
    image_cache.loads := 0
    PreloadNextImage()
    Sleep, 100
    Assert(navigation_ran, "Pending navigation runs after preload")
    Assert(!navigation_during_load, "Navigation cannot interrupt loading")
    Assert(img_list_index = 2 && navigation_bitmap = image_cache.Get(b), "Navigation reuses completed bitmap")
    Assert(image_cache.loads = 1, "No duplicate decode")
    Assert(!A_IsCritical, "Critical state restored")
    Critical, 23
    PreloadNextImage()
    Assert(A_IsCritical = 23, "Existing critical state preserved")
    Critical, Off
    FileAppend, % "PASS: preload regression checks; Windows " A_OSVersion "; AHK " A_AhkVersion "`n", *
} catch error {
    exit_code := 1
    FileAppend, % "FAIL: " error.Message "`n", *
} finally {
    Critical, Off
    SetTimer, NavigateDuringLoad, Off
    image_cache.Clear()
    Gdip_Shutdown(token)
}
ExitApp, % exit_code
NavigateDuringLoad() {
    global
    navigation_during_load := image_cache.loading
    UpdateImageIndex(1)
    navigation_bitmap := image_cache.Get(GetCurrentImagePath())
    navigation_ran := true
}
class SlowCache extends BitmapCache {
    Load(path) {
        if(this.slow && !this.entries.HasKey(path)) {
            this.loads := this.loads + 1
            this.loading := true
            SetTimer, NavigateDuringLoad, -10
            Sleep, 100
            result := base.Load(path)
            this.loading := false
            return result
        }
        return base.Load(path)
    }
}
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

