; A scrollable folder strip, separate from the current-image pan navigator.
FilmstripInitialize()
{
    global pv_filmstrip
    Gui, PV:Add, Text, Hidden 0x400010E x0 y0 w1 h1 hwndstrip_hwnd
    pv_filmstrip := {hwnd: strip_hwnd, previews: {}, first: 1, visible: false, dirty: true}
}

FilmstripUpdate(inside, x, y, width, height)
{
    global pv_filmstrip, pv_has_image, pv_thumbnail, img_path_list, img_list_index
    if( !IsObject(pv_filmstrip) )
        return
    show := inside && pv_has_image && !pv_thumbnail.dragging && width >= 160 && height >= 160
        && x >= 0 && x < width && y < height
        && y >= height - (pv_filmstrip.visible ? 108 : 32)
    if( pv_filmstrip.dragging && pv_has_image )
        show := true
    if( !show ) {
        GuiControl, PV:Hide, % pv_filmstrip.hwnd
        pv_filmstrip.visible := false
        return
    }
    was_critical := A_IsCritical
    Critical, On
    try {
        slots := Max(1, Floor((width - 56) / 96))
        if( pv_filmstrip.list != img_path_list || pv_filmstrip.selected != img_list_index
            || !pv_filmstrip.visible ) {
            pv_filmstrip.first := Max(1, img_list_index - Floor(slots / 2))
            pv_filmstrip.list := img_path_list
            pv_filmstrip.selected := img_list_index
            pv_filmstrip.dirty := true
        }
        if( pv_filmstrip.width != width || pv_filmstrip.height != height )
            pv_filmstrip.dirty := true
        pv_filmstrip.width := width, pv_filmstrip.height := height, pv_filmstrip.slots := slots
        pv_filmstrip.first := Min(pv_filmstrip.first, Max(1, img_path_list.Length() - slots + 1))
        ; Decode one visible preview per tick so large folders do not load at once.
        Loop, % slots {
            index := pv_filmstrip.first + A_Index - 1
            if( index > img_path_list.Length() )
                break
            path := img_path_list[index]
            if( !pv_filmstrip.previews.HasKey(path) ) {
                pv_filmstrip.previews[path] := FilmstripPreview(path)
                pv_filmstrip.dirty := true
                break
            }
        }
        if( pv_filmstrip.dirty )
            FilmstripRender()
        pv_filmstrip.visible := true
        GuiControl, PV:Move, % pv_filmstrip.hwnd, % "x0 y" height - 108 " w" width " h108"
        DllCall("SetWindowPos", "Ptr", pv_filmstrip.hwnd, "Ptr", 0, "Int", 0, "Int", 0
            , "Int", 0, "Int", 0, "UInt", 0x53)
    } finally {
        Critical, % was_critical
    }
}

FilmstripPreview(path)
{
    global image_cache
    borrowed := image_cache.entries.HasKey(path)
    SplitPath, path, , , extension
    source := borrowed ? image_cache.entries[path].bitmap
        : (extension = "webp" ? LoadWebPBitmap(path) : Gdip_CreateBitmapFromFile(path))
    if( source <= 0 )
        return 0
    Gdip_GetImageDimensions(source, w, h)
    bitmap := Gdip_CreateBitmap(88, 72)
    graphics := Gdip_GraphicsFromImage(bitmap)
    Gdip_GraphicsClear(graphics, 0xFF303030)
    scale := Min(88 / w, 72 / h)
    Gdip_SetInterpolationMode(graphics, 7)
    Gdip_DrawImage(graphics, source, (88 - w * scale) / 2, (72 - h * scale) / 2, w * scale, h * scale, 0, 0, w, h)
    Gdip_DeleteGraphics(graphics)
    if( !borrowed )
        Gdip_DisposeImage(source)
    return bitmap
}

FilmstripRender()
{
    global pv_filmstrip, img_path_list, img_list_index
    bitmap := Gdip_CreateBitmap(pv_filmstrip.width, 108)
    graphics := Gdip_GraphicsFromImage(bitmap)
    Gdip_GraphicsClear(graphics, 0xFF202020)
    Gdip_TextToGraphics(graphics, "<", "x4 y34 w24 h36 s24 cFFFFFFFF", "Segoe UI")
    Gdip_TextToGraphics(graphics, ">", "x" pv_filmstrip.width - 26 " y34 w24 h36 s24 cFFFFFFFF", "Segoe UI")
    Loop, % pv_filmstrip.slots {
        index := pv_filmstrip.first + A_Index - 1
        if( index > img_path_list.Length() )
            break
        path := img_path_list[index]
        x := 28 + (A_Index - 1) * 96
        preview := pv_filmstrip.previews[path]
        if( preview )
            Gdip_DrawImage(graphics, preview, x, 8, 88, 72)
        else
            Gdip_TextToGraphics(graphics, pv_filmstrip.previews.HasKey(path) ? "?" : "...", "x" x " y28 w88 h28 Center s18 cFFAAAAAA", "Segoe UI")
        if( index = img_list_index ) {
            pen := Gdip_CreatePen(0xFF43C6FF, 2)
            Gdip_DrawRectangle(graphics, pen, x - 2, 6, 92, 76)
            Gdip_DeletePen(pen)
        }
        SplitPath, path, name
        Gdip_TextToGraphics(graphics, name, "x" x " y86 w88 h18 s10 NoWrap cFFFFFFFF", "Segoe UI")
    }
    Gdip_DeleteGraphics(graphics)
    handle := Gdip_CreateHBITMAPFromBitmap(bitmap)
    Gdip_DisposeImage(bitmap)
    SetImage(pv_filmstrip.hwnd, handle)
    retained := DllCall("SendMessage", "Ptr", pv_filmstrip.hwnd, "UInt", 0x173, "Ptr", 0, "Ptr", 0, "Ptr")
    if( handle && retained != handle )
        DeleteObject(handle)
    pv_filmstrip.dirty := false
}

FilmstripScroll(direction)
{
    global pv_filmstrip, img_path_list
    pv_filmstrip.first := Max(1, Min(Max(1, img_path_list.Length() - pv_filmstrip.slots + 1)
        , pv_filmstrip.first + direction * Max(1, pv_filmstrip.slots - 1)))
    pv_filmstrip.dirty := true
}

FilmstripClick(x)
{
    global pv_filmstrip, img_path_list, img_list_index
    if( x < 28 || x >= pv_filmstrip.width - 28 ) {
        FilmstripScroll(x < 28 ? -1 : 1)
        return
    }
    slot := Floor((x - 28) / 96)
    index := pv_filmstrip.first + slot
    if( slot >= pv_filmstrip.slots || index > img_path_list.Length() )
        return
    img_list_index := index
    pv_filmstrip.selected := index
    pv_filmstrip.dirty := true
    GuiShowImage(GetCurrentImagePath(), "last", true)
    GuiUpdateTitle(GetCurrentImagePath())
}

FilmstripBeginDrag(x)
{
    global pv_filmstrip
    SetTimer, DragTimer, Off
    if( x < 28 || x >= pv_filmstrip.width - 28 ) {
        FilmstripClick(x)
        return
    }
    pv_filmstrip.dragging := true, pv_filmstrip.moved := false
    pv_filmstrip.click_x := x, pv_filmstrip.start_first := pv_filmstrip.first
    VarSetCapacity(point, 8, 0)
    DllCall("GetCursorPos", "Ptr", &point)
    pv_filmstrip.mouse_x := NumGet(point, 0, "Int")
    DllCall("SetCapture", "Ptr", pv_filmstrip.hwnd)
    SetTimer, FilmstripDragTimer, 16
}

FilmstripDragBy(delta)
{
    global pv_filmstrip, img_path_list
    if( Abs(delta) < 6 && !pv_filmstrip.moved )
        return
    pv_filmstrip.moved := true
    pv_filmstrip.first := Max(1, Min(Max(1, img_path_list.Length() - pv_filmstrip.slots + 1)
        , pv_filmstrip.start_first - Round(delta / 96)))
    pv_filmstrip.dirty := true
}

FilmstripDragTimer()
{
    global pv_filmstrip
    if( !pv_filmstrip.dragging || !GetKeyState("LButton", "P") ) {
        FilmstripEndDrag()
        return
    }
    VarSetCapacity(point, 8, 0)
    DllCall("GetCursorPos", "Ptr", &point)
    FilmstripDragBy(NumGet(point, 0, "Int") - pv_filmstrip.mouse_x)
}

FilmstripEndDrag()
{
    global pv_filmstrip
    SetTimer, FilmstripDragTimer, Off
    if( !IsObject(pv_filmstrip) || !pv_filmstrip.dragging )
        return
    pv_filmstrip.dragging := false
    DllCall("ReleaseCapture")
    if( !pv_filmstrip.moved )
        FilmstripClick(pv_filmstrip.click_x)
}

FilmstripClear()
{
    global pv_filmstrip
    if( !IsObject(pv_filmstrip) )
        return
    pv_filmstrip.moved := true
    FilmstripEndDrag()
    for path, bitmap in pv_filmstrip.previews {
        if( bitmap )
            Gdip_DisposeImage(bitmap)
    }
    old_bitmap := DllCall("SendMessage", "Ptr", pv_filmstrip.hwnd, "UInt", 0x172, "Ptr", 0, "Ptr", 0, "Ptr")
    if( old_bitmap )
        DeleteObject(old_bitmap)
    pv_filmstrip.previews := {}
}
