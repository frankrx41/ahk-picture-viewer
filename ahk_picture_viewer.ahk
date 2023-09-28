;*******************************************************************************
; Auto Execute Section
#noenv
#notrayicon
#singleinstance, off
SetTitleMatchMode, 2
DetectHiddenWindows On
CoordMode, Mouse, Client
OnExit, Exit
ToolTip,
; #Warn

; Download from
; https://github.com/marius-sucan/AHK-GDIp-Library-Compilation/blob/master/ahk-v1-1/Gdip_All.ahk
#Include  %A_ScriptDir%\Lib\Gdip.ahk

;program settings
file_ext_list       := "avci,avcs,avif,acifs,bmp,dib,gif,heic,heics,heif,heifs,hif,jfif,jpe,jpeg,jpg,png,tif,tiff,wdp,webp,tag,ico"
select_file_filter  := "Image (*.*)"

gdip_token := Gdip_Startup()
if( !gdip_token )
{
    MsgBox, 48, GDI Error Occurred.
    ExitApp
}

OnExit("ExitFunc")
ProcessArgs()
GuiInitialize()
if( GetCurrentImagePath() ) {
    GuiShow()
    GuiShowImage(GetCurrentImagePath(), "100%", true)
} else {
    GuiShow("max")
}
return

;*******************************************************************************
;
ProcessArgs()
{
    local
    global A_Args
    img_path := ""
    if( A_Args.Length() )
    {
        for k, path in A_Args
        {
            full_path := GetFileLongPath(path)
            ; MsgBox, % full_path
            if( IsImageFile(full_path) )
            {
                ; MsgBox, % full_path
                if (A_Index = 1) {
                    img_path := full_path
                }
                else
                {
                    OpenImageInNewWindow("", full_path)
                }
            }
        }
    }
    if( !img_path && !A_IsCompiled ) {
        ; Debug only
        img_path := ""
    }
    if( img_path ) {
        ImageListInitialize(img_path)
    }
}

;*******************************************************************************
; Labels
RemoveTooltip:
    tooltip
return

ExitFunc(exit_reason, exit_code)
{
    global gdip_token
    Gdip_Shutdown( gdip_token )
}

#Include, %A_ScriptDir%\ahk_picture_viewer_gui.ahk
#Include, %A_ScriptDir%\ahk_picture_viewer_lib.ahk
#Include, %A_ScriptDir%\ahk_picture_viewer_hotkey.ahk
#Include, %A_ScriptDir%\ahk_picture_viewer_image.ahk
#Include, %A_ScriptDir%\ahk_picture_viewer_file.ahk
#Include, %A_ScriptDir%\ahk_picture_viewer_menu.ahk

#if WinActive(A_ScriptName)
    ~^S::
        ToolTip, Reload %A_ScriptName%
        Sleep, 500
        Reload
    return
#if
