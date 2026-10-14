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

        source := Gdip_CreateBitmapFromFile(path)
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
