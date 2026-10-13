#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include %A_ScriptDir%\..\lib\Gdip.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_image.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_lib.ahk

token := Gdip_Startup()
test_dir := A_Temp "\ahkpv-cache-" DllCall("GetCurrentProcessId")
FileCreateDir, % test_dir
cache := new BitmapCache(2048, 3)
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
    Assert(cache.entries.Length() = 2 && cache.bytes = 2048, "Pixel budget enforced")
    Assert(cache.entries[1].path = a && cache.entries[2].path = c, "Least recently used image evicted")

    cache.Clear()
    cache.max_bytes := 1024 * 1024
    cache.max_images := 2
    cache.Get(a)
    cache.Get(b)
    cache.Get(c)
    Assert(cache.entries.Length() = 2 && cache.entries[1].path = b, "Entry limit enforced")

    ; Saving over a cached source also verifies that the source file is unlocked.
    FileDelete, % c
    Assert(!ErrorLevel, "Cached source can be deleted")
    WriteImage(c, 32)
    updated := cache.Get(c)
    Gdip_GetImageDimensions(updated, width, height)
    Assert(width = 32 && height = 32, "Changed source is refreshed")

    cache.max_bytes := 1024
    cache.Remove(c)
    Assert(cache.Get(c) > 0 && cache.entries.Length() = 1, "Oversized image retained alone")
    cache.Get(a)
    Assert(cache.bytes = 1024 && cache.entries.Length() = 1, "Oversized image evicted on navigation")
    FileDelete, % a
    Assert(cache.Get(a) = 0 && cache.bytes = 0, "Deleted source invalidates cache")
    FileAppend, not an image, % a
    Assert(cache.Get(a) = 0 && cache.entries.Length() = 0, "Invalid image is not cached")
    cache.Get(b)
    cache.Clear()
    cache.Clear()
    Assert(cache.bytes = 0 && cache.entries.Length() = 0, "Cleanup is repeatable")
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
