#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include %A_ScriptDir%\..\lib\Gdip.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_image.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_lib.ahk

token := Gdip_Startup()
cache := new BitmapCache()
exit_code := 0
test_path := A_Temp "\ahkpv webp " Chr(0x56FE) DllCall("GetCurrentProcessId") ".WEBP"
try {
    for index, name in ["opaque", "alpha", "lossy", "animated"] {
        bitmap := cache.Get(A_ScriptDir "\fixtures\" name ".webp")
        Assert(bitmap > 0, "Decode " name " WebP (requires Microsoft WebP Image Extensions)")
        Gdip_GetImageDimensions(bitmap, width, height)
        Assert(width = 16 && height = 12, "Dimensions of " name)
        color := Gdip_GetPixel(bitmap, 5, 5)
        if( name = "opaque" )
            Assert(color = 0xFF336699, "Lossless colors preserved")
        if( name = "alpha" )
            Assert(Abs((color >> 24) - 128) <= 1, "Transparency preserved")
        if( name = "animated" )
            Assert(((color >> 16) & 255) > 240 && (color & 255) < 10, "First animation frame displayed")
    }
    source := A_ScriptDir "\fixtures\alpha.webp"
    FileCopy, % source, % test_path, 1
    bitmap := cache.Get(test_path)
    Assert(bitmap > 0, "Unicode/spaces and uppercase extension")
    FileDelete, % test_path
    Assert(!ErrorLevel, "WebP source is not locked")
    bytes := cache.bytes
    Loop, 100 {
        Assert(cache.Get(test_path) = bitmap, "Cache reuses decoded WebP after source deletion")
        cache.Get(A_ScriptDir "\fixtures\opaque.webp")
    }
    Assert(cache.bytes = bytes, "Navigation does not duplicate cached images")
    FileAppend, invalid webp data, % test_path
    Loop, 50
        Assert(LoadWebPBitmap(test_path) = 0, "Invalid WebP rejected")
    FileDelete, % test_path
    Assert(!ErrorLevel, "Failed decoder releases source")
    Assert(LoadWebPBitmap(test_path) = 0, "Missing WebP rejected")
    FileAppend, PASS: WebP regression checks`n, *
} catch error {
    FileAppend, % "FAIL: " error.Message " (line " error.Line ")`n", *
    exit_code := 1
} finally {
    cache.Clear()
    Gdip_Shutdown(token)
    FileDelete, % test_path
}
ExitApp, % exit_code

Assert(condition, message)
{
    if( !condition )
        throw Exception(message)
}
