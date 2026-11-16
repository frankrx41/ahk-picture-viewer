#NoEnv
#SingleInstance Off
SetBatchLines, -1
#Include %A_ScriptDir%\..\lib\Gdip.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_image.ahk
#Include %A_ScriptDir%\..\ahk_picture_viewer_lib.ahk
token := Gdip_Startup()
path := A_Args[1]
if(!FileExist(path)) {
    FileAppend, Supply a large WebP file as the first argument.`n, *
    ExitApp, 1
}
cache := new BitmapCache()
old_ms := 0, new_ms := 0, exit_code := 0
try {
    Loop, 5 {
        started := A_TickCount
        source := LoadWebPBitmap(path)
        if(!source)
            throw Exception("Decode failed")
        Gdip_GetImageDimensions(source, w, h)
        copied := Gdip_CreateBitmap(w, h)
        graphics := Gdip_GraphicsFromImage(copied)
        Gdip_SetCompositingMode(graphics, 1)
        status := Gdip_DrawImage(graphics, source, 0, 0, w, h, 0, 0, w, h)
        Gdip_DeleteGraphics(graphics)
        Gdip_DisposeImage(source)
        old_ms += A_TickCount - started
        if(status)
            throw Exception("Baseline copy failed")
        expected := Gdip_GetPixel(copied, w//2, h//2)
        Gdip_DisposeImage(copied)
        started := A_TickCount
        bitmap := cache.Get(path)
        new_ms += A_TickCount - started
        actual := Gdip_GetPixel(bitmap, w//2, h//2)
        ; GDI+ drawing rounds premultiplied alpha; allow one level per channel.
        if(!bitmap || Abs((actual>>24)-(expected>>24)) > 1
            || Abs(((actual>>16)&255)-((expected>>16)&255)) > 1
            || Abs(((actual>>8)&255)-((expected>>8)&255)) > 1
            || Abs((actual&255)-(expected&255)) > 1)
            throw Exception("Pixel mismatch")
        if(cache.bytes != w*h*4 || cache.Get(path) != bitmap)
            throw Exception("Cache accounting/reuse failed")
        cache.Clear()
    }
    FileAppend, % "PASS: " w "x" h " WebP; five loads: old=" old_ms " ms, new=" new_ms " ms`n", *
} catch error {
    FileAppend, % "FAIL: " error.Message "`n", *
    exit_code := 1
} finally {
    cache.Clear()
    Gdip_Shutdown(token)
}
ExitApp, % exit_code

