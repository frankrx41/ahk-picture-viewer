#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include %A_ScriptDir%\..\lib\Gdip.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_image.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_lib.ahk

token := Gdip_Startup()
test_dir := A_Temp "\ahkpv-cache-" DllCall("GetCurrentProcessId")
FileCreateDir, % test_dir
cache := new BitmapCache()
exit_code := 0
try {
    for index, name in ["a", "b", "c"]
        WriteImage(test_dir "\" name ".png", 16)
    a := test_dir "\a.png"
    b := test_dir "\b.png"
    c := test_dir "\c.png"
    first := cache.Get(a)
    Assert(first > 0, "Image loads")
    Assert(Gdip_GetPixel(first, 5, 5) = 0xFF336699, "Decoded pixels preserved")
    cache.Get(b)
    Assert(cache.Get(a) = first, "Revisiting reuses decoded bitmap")
    cache.Get(c)
    Assert(cache.entries.Count() = 3 && cache.bytes = 3072, "All opened images retained")

    ; Cross both former limits: three images and 128 MiB of decoded pixels.
    Loop, 9 {
        path := test_dir "\large-" A_Index ".png"
        WriteImage(path, 2048)
        Assert(cache.Get(path) > 0, "Large image loads")
    }
    Assert(cache.bytes > 128 * 1024 * 1024, "Cache exceeds former size limit")
    Assert(cache.entries.Count() = 12, "Cache exceeds former image count limit")
    bytes_before := cache.bytes
    Loop, 100 {
        cache.Get(b)
        cache.Get(c)
        Assert(cache.Get(a) = first, "Repeated navigation preserves original bitmap")
    }
    Assert(cache.bytes = bytes_before, "Revisits allocate no additional cached pixels")

    ; Cached images remain usable even after their source is replaced or deleted.
    FileDelete, % a
    Assert(!ErrorLevel, "Cached source can be deleted")
    WriteImage(a, 32)
    Assert(cache.Get(a) = first, "Changed source retains original cached bitmap")
    FileDelete, % a
    Assert(cache.Get(a) = first, "Deleted source remains cached")
    missing := test_dir "\missing.png"
    Assert(cache.Get(missing) = 0, "Missing uncached image is rejected")
    FileAppend, not an image, % missing
    Assert(cache.Get(missing) = 0, "Invalid image is not cached")
    Assert(cache.entries.Count() = 12, "Failed loads do not alter cache")
    cache.Clear()
    cache.Clear()
    Assert(cache.bytes = 0 && cache.entries.Count() = 0, "Exit cleanup is repeatable")
    FileAppend, PASS: bitmap cache regression checks`n, *
} catch error {
    FileAppend, % "FAIL: " error.Message " (" error.What ", line " error.Line ")`n", *
    exit_code := 1
} finally {
    cache.Clear()
    Gdip_Shutdown(token)
    for index, name in ["a", "b", "c"] {
        path := test_dir "\" name ".png"
        FileDelete, % path
    }
    Loop, 9 {
        path := test_dir "\large-" A_Index ".png"
        FileDelete, % path
    }
    FileDelete, % test_dir "\missing.png"
    FileRemoveDir, % test_dir
}
ExitApp, % exit_code

Assert(condition, message)
{
    if( !condition )
        throw Exception(message)
}

WriteImage(path, size)
{
    bitmap := Gdip_CreateBitmap(size, size)
    Gdip_SetPixel(bitmap, 5, 5, 0xFF336699)
    status := Gdip_SaveBitmapToFile(bitmap, path)
    Gdip_DisposeImage(bitmap)
    Assert(status = 0, "Create test image")
}
