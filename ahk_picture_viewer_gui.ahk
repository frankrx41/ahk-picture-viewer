PVGuiDropFiles:
    GuiDropFiles(A_GuiEvent)
return

GuiDropFiles(filename_list) {
    local
    loop, Parse, filename_list, `n
    {
        if( A_Index == 1 ) {
            image_path := IsImageFile(A_LoopField) ? A_LoopField : ""
        }
        else {
            OpenImageInNewWindow("", A_LoopField)
        }
    }
    if( image_path )
    {
        ImageListInitialize(image_path) ;create a imagelist
        GuiShowImage(image_path)
        GuiUpdateTitle(image_path)
    }
    return
}

PVGuiClose:
    Goto, Exit
return

;*******************************************************************************
;
GuiInitialize()
{
    local
    global pvhwnd, pvpic, pv_prev_button, pv_next_button

    ; Menu
    open_file_fn := Func("OpenFile").Bind()
    Menu, menu_file, Add, &Open File, % open_file_fn
    Menu, menu_file, Add, &Re-Open File, ReOpenFile
    Menu, menu_file, Add, &Close File, CloseFile
    Menu, menu_file, Add,
    Menu, menu_file, Add, &Exit, Exit
    Menu, file_menubar, Add, &File, :menu_file
    Menu, file_menubar, Add,
    Menu, file_menubar, Add, &Prev, PrevPicture
    Menu, file_menubar, Add, &Next, NextPicture

    Gui, PV:New, -DPIScale
    Gui, Menu, file_menubar
    Gui, PV:Color, 0x1e1e1e
    Gui, PV:Margin, 0, 0
    GUI, PV:+Resize -MaxSize -MinSize +LastFound +Hwndpvhwnd
    Gui, PV:Add, Text, 0x400000E vpvpic   ; SS_BITMAP | WS_CLIPSIBLINGS
    Gui, PV:Font, s24, Segoe UI
    Gui, PV:Add, Button, Hidden -TabStop x12 y12 w44 h64 hwndpv_prev_button gPrevPicture, <
    Gui, PV:Add, Button, Hidden -TabStop x68 y12 w44 h64 hwndpv_next_button gNextPicture, >
    Gui, PV:Font
    SetTimer, GuiUpdateNavigation, 50
    ; Gui, Add, StatusBar,, Bar's starting text (omit to start off empty).
    GroupAdd, AHKPV, ahk_id %pvhwnd%
    GuiControl, PV:Disable, pvpic           ; disable the beep
    OnMessage(0x0201, "WM_LBUTTONDOWN")
    OnMessage(0x204, "WM_RBUTTONDOWN")
    OnMessage(0x05, "WM_SIZE")
    OnMessage(0x020A, "WM_MOUSEWHEEL")
    OnMessage(0x0203, "WM_LBUTTONDBLCLK")

    ; Right Menu
    Menu, right_menu, Add, &Next Picture, NextPicture
    Menu, right_menu, Add, &Prev Picture, PrevPicture
    Menu, right_menu, Add,
    Menu, right_menu, Add, &Open, % open_file_fn
    Menu, right_menu, Add,
    Menu, right_menu, Add, Copy as &File, CopyAsFile
    Menu, right_menu, Add, Copy as &Image, CopyToClipboard
    Menu, right_menu, Add, Copy as &HTML, CopyAsHTML
    Menu, right_menu, Add, Copy as &Markdown, CopyAsMarkdown
    Menu, right_menu, Add, Copy as &Text, CopyAsText
    Menu, right_menu, Add, Copy as &Path, CopyAsPath
    Menu, right_menu, Add,
    Menu, right_menu, Add, P&roperties, ViewFileProperties
    ; Menu, right_menu, Icon, %A_ScriptDir%/AHKPV.ico, , 1 
}

GuiShow( mode := "" )
{
    if( mode == "max" ) {
        Gui, PV:Show, Center Maximize
    }
    else
    if( mode == "fit_size" ) {
        global pvhwnd, pvpic
        GuiControlGet, gui_picture, PV:Pos, pvpic
        w := gui_picturew
        h := gui_pictureh
        x := gui_picturex
        y := gui_picturey
        JEE_ClientToWindow(pvhwnd, x, y, offset_x, offset_y)
        offset_x -= x
        offset_y -= y
        JEE_ClientToScreen(pvhwnd, x, y, x2, y2)
        ; ToolTip, % x ", " y "`n" x2 ", " y2
        initial_width_height := " x" x2 - offset_x " y" y2 - offset_y " w" . w . " h" . h
        Gui, PV:Show, Center %initial_width_height%
    }
    else
    if( GetCurrentImagePath() ) {
        global image_cache
        image_cache.GetDimensions(GetCurrentImagePath(), w, h)
        if( !w || !h )
            return
        global min_width
        ; MsgBox, % "2 " w "," h
        if( w < min_width ) {
            image_scale := min_width / w
            w := min_width
            h := h * image_scale
        }
        ; MsgBox, % "3 " w "," h
        initial_width_height := "w" . w . " h" . h
        ; ToolTip, % initial_width_height
        Gui, PV:Show, Center %initial_width_height%
    }
    GuiUpdateTitle(GetCurrentImagePath())
}

;*******************************************************************************
;
GuiUpdateTitle(image_path:="")
{
    local
    global image_cache
    static img_name
    if( image_path != "" ) {
        SplitPath, image_path, img_name
        script_title := Format("[{2}] {1} {3}", img_name, GetFileIndexText(), GetZoomLevel("get"))
        ; GetImgDimension(image_path, img_w, img_h)
        image_cache.GetDimensions(image_path, img_w, img_h)
        script_title .= Format(" {:.0f}*{:.0f}", img_w, img_h)
    } else {
        script_title := "AHK Picture Viewer"
    }
    Gui, PV:Show,, % script_title
}

GuiShowImage(image_path, zoom_method:="100%", keep_center:=false)
{
    global pvpic, image_cache, pv_has_image
    static in_process := false

    if( in_process ) {
        return
    }
    in_process := true
    was_critical := A_IsCritical
    Critical, On

    ; Borrow the bitmap for this draw; only the cache disposes it.
    pbitmap := image_path ? image_cache.Get(image_path) : 0
    pv_has_image := !!pbitmap
    if( pbitmap ) {
        image_scale := GetZoomLevel(zoom_method, pbitmap)
        global min_width
        GuiGetImageSize(pbitmap, image_scale, keep_center, x, y, w, h)
        if( (zoom_method == "100%" || zoom_method == "last") && w < min_width ) {
            Gdip_GetImageDimension(pbitmap, img_w, img_h)
            image_scale := min_width / img_w
            GuiGetImageSize(pbitmap, image_scale, keep_center, x, y, w, h)
            ; MsgBox, % zoom_method ", " w "," image_scale "," keep_center "`n" x "," y
            ; MsgBox, % "1 " w "," h
        }
        ; GuiControl, PV:Move, pvpic, % "x" x " y" y " w" w " h" h
        ShowImageToControl(pvpic, pbitmap, w, h)
        GuiControl, PV:Move, pvpic, % "x" x " y" y
    } else {
        GuiControlGet, hwnd, PV:hwnd, pvpic
        ; SetImage does not accept a null bitmap, so clear the control directly.
        old_bitmap := DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x172, "Ptr", 0, "Ptr", 0, "Ptr")
        if( old_bitmap )
            DeleteObject(old_bitmap)
    }
    in_process := false
    Critical, % was_critical
}

; See `Gdip_SetPbitmapCtrl`
ShowImageToControl(pvpic, pbitmap, w, h)
{
    if( !pbitmap || w < 1 || h < 1 )
        return

    hDC := CreateCompatibleDC()
    hbm := CreateDIBSection(w, -h, hdc)
    obm := SelectObject(hDC, hbm)

    hdc2 := CreateCompatibleDC()
    hBitmap := Gdip_CreateARGBHBITMAPFromBitmap(pbitmap)
    obm2 := SelectObject(hdc2, hBitmap)

    Gdip_GetImageDimensions(pBitmap, Width, Height)
    ; https://github.com/github/VisualStudio/blob/master/tools/Debugging%20Tools%20for%20Windows/winext/manifest/gdi32.h
    SetStretchBltMode(hdc, 3)
    StretchBlt(hdc, 0, 0, w, h, hdc2, 0, 0, width, height, 0x00CC0020 )
    ; StretchDIBits(hDC, 0, 0, w, h, hdc2, 0, 0, width, height, 0x00CC0020 )
    ; If pBrush

    newBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
    ; A selected bitmap cannot be deleted. Restore both DCs first.
    SelectObject(hdc, obm)
    SelectObject(hdc2, obm2)
    DeleteObject(hbm)
    DeleteObject(hBitmap)
    DeleteDC(hdc)
    DeleteDC(hdc2)

    if( !newBitmap )
        return

    hBitmap := Gdip_CreateARGBHBITMAPFromBitmap(newBitmap)
    Gdip_DisposeImage(newBitmap)
    GuiControlGet, hwnd, PV:hwnd, pvpic
    E := SetImage(hwnd, hBitmap)
    ; The static control may retain our bitmap or make an alpha-channel copy.
    ; SetImage deletes the previous control bitmap on the next redraw.
    control_bitmap := DllCall("SendMessage", "Ptr", hwnd, "UInt", 0x173, "Ptr", 0, "Ptr", 0, "Ptr")
    if( hBitmap && control_bitmap != hBitmap )
        DeleteObject(hBitmap)
}

GuiGetImageSize(pbitmap, image_scale, keep_center, ByRef x, ByRef y, ByRef w, ByRef h)
{
    local
    global pvhwnd, pvpic
    static last_image_w, last_image_h

    if( !pbitmap ) {
        return
    }

    Gdip_GetImageDimension(pbitmap, img_w, img_h)

    MouseGetPos, mcX, mcY
    GuiControlGet, gui_picture, PV:Pos, pvpic
    if( !keep_center ) {
        keep_center := !(mcX > gui_picturex && mcX < gui_picturex + gui_picturew && mcY > gui_picturey && mcY < gui_picturey + gui_pictureh)
    }
    ; ToolTip, % keep_center "`n" mcX ", " mcY "`n" gui_picturex ", " gui_picturey ", " gui_picturew ", " gui_pictureh
    GetClientSize(pvhwnd, gui_w, gui_h)
    if( gui_w == 0 ) {
        return
    }

    if( keep_center ){
        gui_picturew := img_w * image_scale
        gui_pictureh := img_h * image_scale

        if( gui_w != 0 ) {
            gui_picturex := Round((gui_w - gui_picturew)/2)
            gui_picturey := Round((gui_h - gui_pictureh)/2)
            if( gui_pictureh > gui_picturew * 1.5 ) {
                gui_picturey := Max(0, gui_picturey)
            }
            ; MsgBox, % gui_picturex ", " gui_picturey
        }
        ; MsgBox, % gui_w "`n" image_scale "`n" gui_picturex ", " gui_picturey
    } else {
        image_scale2 := img_w / gui_picturew * image_scale
        gui_picturew := gui_picturew * image_scale2 ; New width
        gui_pictureh := gui_pictureh * image_scale2 ; New height
        gui_picturex := gui_picturex + (mcX - gui_picturex) * (1 - image_scale2)
        gui_picturey := gui_picturey + (mcY - gui_picturey) * (1 - image_scale2)
    }

    ; displayed inside the window
    if( gui_picturew <= gui_w ) {
        if( gui_picturex < 0 ) {
            gui_picturex := 0
        }
        if( gui_picturex + gui_picturew > gui_w ) {
            gui_picturex := gui_w - gui_picturew
        }
    }

    if( gui_pictureh <= gui_h ) {
        if( gui_picturey < 0 ) {
            gui_picturey := 0
        }
        if( gui_picturey + gui_pictureh > gui_h ) {
            gui_picturey := gui_h - gui_pictureh
        }
    }

    pos_str := "w" gui_picturew " h" gui_pictureh " x" gui_picturex " y" gui_picturey
    ; ; ToolTip, % pos_str
    Gui, PV:Default
    SB_SetText(pos_str)

    last_image_w := gui_picturew
    last_image_h := gui_pictureh

    x := gui_picturex
    y := gui_picturey
    w := gui_picturew
    h := gui_pictureh

    return
}

; https://www.autohotkey.com/boards/viewtopic.php?t=110944
WM_MOUSEWHEEL(wParam, lParam, msg, hwnd) {
    if (wParam > 0x7FFFFFFF)
        wParam := -(~wParam) - 1
    is_up := (wParam >> 16) / 120 == 1
    if( is_up ) {
        GuiShowImage(GetCurrentImagePath(),"+1")
    } else {
        GuiShowImage(GetCurrentImagePath(),"-1")
    }
    GuiUpdateTitle(GetCurrentImagePath())
}

; https://www.autohotkey.com/boards/viewtopic.php?t=20083
WM_LBUTTONDBLCLK()
{
    global pvhwnd
    MouseGetPos, , , , control_id
    ; ToolTip, % control_id
    if( control_id == "Static1" ) {
        WinGet, is_max, MinMax, ahk_id %pvhwnd%
        if( is_max ) {
            WinRestore, ahk_id %pvhwnd%
        } else {
            WinMaximize, ahk_id %pvhwnd%
        }
    }
}

; https://www.autohotkey.com/boards/viewtopic.php?t=103848
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    global g_mx, g_my, pvhwnd, pv_prev_button, pv_next_button
    ; Native buttons dispatch their own click labels; do not also navigate or drag.
    if( hwnd == pv_prev_button || hwnd == pv_next_button )
        return
    MouseGetPos, g_mx, g_my
    SetTimer, DragTimer, 16
}

GuiUpdateNavigation()
{
    local
    global pvhwnd, pv_prev_button, pv_next_button, pv_has_image
    static last_width := 0, last_height := 0
    if( !pv_prev_button || !pv_next_button )
        return
    GetClientSize(pvhwnd, width, height)
    if( width != last_width || height != last_height ) {
        y := Max(12, Floor((height - 64) / 2))
        GuiControl, PV:Move, % pv_prev_button, % "x12 y" y
        GuiControl, PV:Move, % pv_next_button, % "x" Max(12, width - 56) " y" y
        last_width := width, last_height := height
    }
    MouseGetPos, , , hovered_window
    VarSetCapacity(point, 8, 0)
    DllCall("GetCursorPos", "Ptr", &point)
    DllCall("ScreenToClient", "Ptr", pvhwnd, "Ptr", &point)
    x := NumGet(point, 0, "Int"), y := NumGet(point, 4, "Int")
    inside := pv_has_image && hovered_window == pvhwnd && width >= 112 && height >= 88
        && x >= 0 && x < width && y >= 0 && y < height
    edge_width := Min(150, Floor(width / 3))
    for index, button in [pv_prev_button, pv_next_button] {
        show := inside && (index = 1 ? x < edge_width : x >= width - edge_width)
        if( show != !!DllCall("IsWindowVisible", "Ptr", button) ) {
            if( show ) {
                ; Keep navigation above the image without taking keyboard focus.
                DllCall("SetWindowPos", "Ptr", button, "Ptr", 0, "Int", 0, "Int", 0
                    , "Int", 0, "Int", 0, "UInt", 0x53)
            } else {
                GuiControl, PV:Hide, % button
            }
        }
    }
}

; https://www.autohotkey.com/board/topic/44736-onmessage-for-minimize-maximize-restore/
WM_SIZE()
{
    if( GetCurrentImagePath() ) {
        GuiShowImage(GetCurrentImagePath(), "last")
    }
}

DragTimer:
    o_mx := g_mx
    o_my := g_my
    MouseGetPos, g_mx, g_my
    MoveImage(g_mx - o_mx, g_my - o_my)
return

MoveImage(offset_x, offset_y)
{
    local
    global pvpic
    if( offset_x != 0 || offset_y != 0 )
    {
        GuiControlGet, gui_picture, PV:Pos, pvpic
        gui_picturex += offset_x
        gui_picturey += offset_y
        pos_str := "w" gui_picturew " h" gui_pictureh " x" gui_picturex " y" gui_picturey
        ; GuiControl, PV:MoveDraw, pvpic, % pos_str
        GuiControl, PV:Move, pvpic, % pos_str
        ; DrawBox(posx, posy, posw, posh)
        ; GuiControl, PV:MoveDraw, transPic, % pos_str
        ; MsgBox, % offset_x "," offset_y "`n" g_my "," g_my "`n" o_mx "," o_my
    }
}

WM_RBUTTONDOWN()
{
    Menu, right_menu, Show
}
