; Owns decoded bitmaps until process exit. Callers must not dispose borrowed handles.
class BitmapCache
{
    __New()
    {
        this.entries := {}
        this.bytes := 0
    }

    Get(path)
    {
        was_critical := A_IsCritical
        Critical, On
        try {
            return this.Load(path)
        } finally {
            Critical, % was_critical
        }
    }

    GetDimensions(path, ByRef width, ByRef height)
    {
        was_critical := A_IsCritical
        Critical, On
        try {
            bitmap := this.Get(path)
            width := 0, height := 0
            if( bitmap )
                Gdip_GetImageDimensions(bitmap, width, height)
        } finally {
            Critical, % was_critical
        }
    }

    Load(path)
    {
        if( this.entries.HasKey(path) )
            return this.entries[path].bitmap

        SplitPath, path, , , extension
        source := extension = "webp" ? LoadWebPBitmap(path) : Gdip_CreateBitmapFromFile(path)
        if( source <= 0 )
            return 0
        Gdip_GetImageDimensions(source, width, height)
        bytes := width * height * 4
        ; Copy into independent pixels so cached images do not lock source files.
        bitmap := Gdip_CreateBitmap(width, height)
        graphics := bitmap ? Gdip_GraphicsFromImage(bitmap) : 0
        status := 1
        if( graphics ) {
            Gdip_SetCompositingMode(graphics, 1)
            status := Gdip_DrawImage(graphics, source, 0, 0, width, height, 0, 0, width, height)
            Gdip_DeleteGraphics(graphics)
        }
        Gdip_DisposeImage(source)
        if( status != 0 ) {
            if( bitmap )
                Gdip_DisposeImage(bitmap)
            return 0
        }
        this.entries[path] := {bitmap: bitmap, bytes: bytes}
        this.bytes += bytes
        return bitmap
    }

    Clear()
    {
        was_critical := A_IsCritical
        Critical, On
        try {
            for index, entry in this.entries
                Gdip_DisposeImage(entry.bitmap)
            this.entries := {}
            this.bytes := 0
        } finally {
            Critical, % was_critical
        }
    }
}

; Decode the first WebP frame through the installed Windows WIC codec.
; Returns an owned GDI+ bitmap; releases the decoder and source file immediately.
LoadWebPBitmap(path)
{
    factory := 0, decoder := 0, frame := 0, converted := 0, bitmap := 0
    locked := false, success := false
    try {
        factory := ComObjCreate("{cacaf262-9370-4615-a13b-9f5539da4c0a}"
            , "{ec5ec8a9-c395-4314-9c77-54d7a935ff70}")
        ; IWICImagingFactory::CreateDecoderFromFilename, GENERIC_READ.
        if( DllCall(NumGet(NumGet(factory+0) + 3*A_PtrSize), "Ptr", factory
            , "WStr", path, "Ptr", 0, "UInt", 0x80000000, "UInt", 0, "PtrP", decoder, "Int") < 0 )
            return 0
        ; IWICBitmapDecoder::GetFrame(0).
        if( DllCall(NumGet(NumGet(decoder+0) + 13*A_PtrSize), "Ptr", decoder
            , "UInt", 0, "PtrP", frame, "Int") < 0 )
            return 0
        if( DllCall(NumGet(NumGet(frame+0) + 3*A_PtrSize), "Ptr", frame
            , "UIntP", width, "UIntP", height, "Int") < 0 || !width || !height )
            return 0
        ; GUID_WICPixelFormat32bppBGRA matches GDI+ PixelFormat32bppARGB.
        VarSetCapacity(format, 16, 0)
        DllCall("ole32\CLSIDFromString", "WStr", "{6fddc324-4e03-4bfe-b185-3d77768dc90f}", "Ptr", &format)
        if( DllCall("windowscodecs\WICConvertBitmapSource", "Ptr", &format
            , "Ptr", frame, "PtrP", converted, "Int") < 0 )
            return 0
        bitmap := Gdip_CreateBitmap(width, height)
        if( !bitmap || Gdip_LockBits(bitmap, 0, 0, width, height, stride, pixels, data, 2) )
            return 0
        locked := true
        if( stride <= 0 || stride * height > 0xFFFFFFFF )
            return 0
        ; IWICBitmapSource::CopyPixels into GDI+-owned memory, including alpha.
        if( DllCall(NumGet(NumGet(converted+0) + 7*A_PtrSize), "Ptr", converted
            , "Ptr", 0, "UInt", stride, "UInt", stride * height, "Ptr", pixels, "Int") < 0 )
            return 0
        success := true
        return bitmap
    } catch error {
        return 0
    } finally {
        if( locked )
            Gdip_UnlockBits(bitmap, data)
        if( bitmap && !success )
            Gdip_DisposeImage(bitmap)
        for index, pointer in [converted, frame, decoder, factory] {
            if( pointer )
                ObjRelease(pointer)
        }
    }
}

; method:
;   * get
;   * get_legacy
;   * last
;   * fit_width / fit_image / fit_window
;   * 100% / 200%
;   * +1 / -1
GetZoomLevel(method:="", bitmap:="")
{
    static last_zoom
    static last_zoom_param := ""
    global PVhwnd
    ; switch method:
    ; case "
    if( method == "auto" ) {
        last_zoom_param := method
        last_zoom := 1
    }
    else
    if( method == "get" ) {
        return Format("{:.1f}% ({})", last_zoom*100, last_zoom_param)
    }
    else
    if( method == "get_legacy" ) {
        return last_zoom_param
    }
    else
    if( method == "last" ) {
        if( last_zoom_param != "last" ) {
            last_zoom := GetZoomLevel(last_zoom_param, bitmap)
        } else {
            last_zoom := 1
        }
    }
    else
    if( method == "fit_width" ) {
        Gdip_GetImageDimension(bitmap, img_w, img_h)
        GetClientSize(PVhwnd, gui_w, gui_h)
        last_zoom := gui_w/img_w
        if( last_zoom > 1 ) {
            ; last_zoom := 1
        }
        last_zoom_param := method
    }
    else
    if( method == "fit_height" ) {
        Gdip_GetImageDimension(bitmap, img_w, img_h)
        GetClientSize(PVhwnd, gui_w, gui_h)
        last_zoom := gui_h/img_h
        last_zoom_param := method
    }
    else
    if( method == "fit_image" ) {
        Gdip_GetImageDimension(bitmap, img_w, img_h)
        GetClientSize(PVhwnd, gui_w, gui_h)
        last_zoom := Min(gui_w/img_w, gui_h/img_h)
        if( last_zoom > 1 ) {
            last_zoom := 1
        }
        last_zoom_param := method
    }
    else
    if( method == "fit_window" ) {
        Gdip_GetImageDimension(bitmap, img_w, img_h)
        GetClientSize(PVhwnd, gui_w, gui_h)
        last_zoom := Min(gui_w/img_w, gui_h/img_h)
        last_zoom_param := method
    }
    else
    if( SubStr(method, 0, 1) == "%" ) {
        last_zoom_param := method
        last_zoom := RTrim(method, "%") / 100
    }
    else
    if( method == "" || method == 0 ) {
    }
    else
    if( method < 0 ) {
        if( last_zoom < 1 ) {
            last_zoom += method / 10
            last_zoom := Max(0.1, last_zoom)
        } else {
            last_zoom += method * .25
            last_zoom := Max(.9, last_zoom)
        }
    } else {
        ; Fix float error
        if( last_zoom < 0.9999 ) {
            last_zoom += method / 10
        } else {
            last_zoom += method * .25
        }
    }
    return last_zoom
}
