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
        slots := Max(1, Floor((width - 8) / 96))
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
    Loop, % pv_filmstrip.slots {
        index := pv_filmstrip.first + A_Index - 1
        if( index > img_path_list.Length() )
            break
        path := img_path_list[index]
        x := 4 + (A_Index - 1) * 96
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
        Gdip_TextToGraphics(graphics, name, "x" x " y82 w88 h14 s9 NoWrap cFFFFFFFF", "Segoe UI")
    }
    FilmstripScrollbarSize(track_w, thumb_w, thumb_x, last_first)
    brush := Gdip_BrushCreateSolid(0xFF383838)
    Gdip_FillRectangle(graphics, brush, 4, 99, track_w, 7)
    Gdip_DeleteBrush(brush)
    brush := Gdip_BrushCreateSolid(last_first > 1 ? 0xFFAAAAAA : 0xFF606060)
    Gdip_FillRectangle(graphics, brush, thumb_x, 99, thumb_w, 7)
    Gdip_DeleteBrush(brush)
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
    slot := Floor((x - 4) / 96)
    index := pv_filmstrip.first + slot
    if( slot < 0 || slot >= pv_filmstrip.slots || index > img_path_list.Length() )
        return
    img_list_index := index
    pv_filmstrip.selected := index
    pv_filmstrip.dirty := true
    GuiShowImage(GetCurrentImagePath(), "last", true)
    GuiUpdateTitle(GetCurrentImagePath())
}

FilmstripScrollbarSize(ByRef track_w, ByRef thumb_w, ByRef thumb_x, ByRef last_first)
{
    global pv_filmstrip, img_path_list
    track_w := Max(1, pv_filmstrip.width - 8)
    count := Max(1, img_path_list.Length())
    last_first := Max(1, count - pv_filmstrip.slots + 1)
    thumb_w := Min(track_w, Max(24, track_w * Min(1, pv_filmstrip.slots / count)))
    thumb_x := 4 + (last_first > 1 ? (track_w - thumb_w) * (pv_filmstrip.first - 1) / (last_first - 1) : 0)
}

FilmstripScrollbarTo(x)
{
    global pv_filmstrip
    FilmstripScrollbarSize(track_w, thumb_w, thumb_x, last_first)
    fraction := track_w > thumb_w ? (x - 4 - pv_filmstrip.grab_offset) / (track_w - thumb_w) : 0
    pv_filmstrip.first := 1 + Round(Max(0, Min(1, fraction)) * (last_first - 1))
    pv_filmstrip.dirty := true
}

FilmstripBeginDrag(x, y:=0)
{
    global pv_filmstrip
    SetTimer, DragTimer, Off
    pv_filmstrip.dragging := true, pv_filmstrip.moved := false
    pv_filmstrip.scrollbar_drag := y >= 96
    if( pv_filmstrip.scrollbar_drag ) {
        FilmstripScrollbarSize(track_w, thumb_w, thumb_x, last_first)
        pv_filmstrip.grab_offset := x >= thumb_x && x <= thumb_x + thumb_w ? x - thumb_x : thumb_w / 2
        pv_filmstrip.moved := true
        FilmstripScrollbarTo(x)
    }
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
    if( pv_filmstrip.scrollbar_drag ) {
        FilmstripScrollbarTo(pv_filmstrip.click_x + delta)
        return
    }
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
