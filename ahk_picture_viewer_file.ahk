ImageListInitialize(file_path)
{
    local
    global img_path_list, img_list_index
    global file_ext_list

    img_path_list := []

    SplitPath, file_path, file_name, file_dir, file_ext, file_name_no_ext

    tempList := ""  ; will hold lines: key|fullpath

    Loop, Files, %file_dir%\*
    {
        if (A_LoopFileExt in file_ext_list)
        {
            SplitPath, A_LoopFileLongPath, fn, , , fn_no_ext

            ; Match once here
            if RegExMatch(fn_no_ext, "i)^photo_(\d+)_([0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})$", m)
            {
                num  := Format("{:08}", m1)  ; zero‑pad for proper string sort
                date := m2
                key  := date . "_" . num
            }
            else
            {
                ; Non‑matching files go after, sorted by name
                key := "zzzzzzzz_" . fn_no_ext
            }

            tempList .= key . "|" . A_LoopFileLongPath . "`n"
        }
    }

    ; Sort by key (date+num) ascending
    Sort, tempList, D`n

    ; Build final array
    Loop, Parse, tempList, `n
    {
        if !A_LoopField
            continue
        StringSplit, parts, A_LoopField, |
        img_path_list.Push(parts2)
    }

    ; Find index of current file
    img_list_index := ""
    Loop % img_path_list.Length()
    {
        if (img_path_list[A_Index] = file_path) {
            img_list_index := A_Index
            break
        }
    }
}

GetCurrentImagePath() {
    global img_path_list, img_list_index
    return img_path_list[img_list_index]
}

GetFileIndexText() {
    global img_path_list, img_list_index
    return Format("{}/{}", img_list_index, img_path_list.Length())
}

;*******************************************************************************
; Functions
OpenImageInNewWindow(img_path, img_name)
{
    local
    full_path := img_path "\" img_name
    if( IsImageFile(full_path) ) {
        if( A_IsCompiled ) {
            Run, "%A_ScriptFullPath%" full_path
        }
        else {
            Run, %A_AhkPath% "%A_ScriptFullPath%" full_path
        }
    }
}

OpenFile()
{
    local
    global select_file_filter
    FileSelectFile, select_img, M3, %A_ScriptDir%, Select Images, % select_file_filter
    if( !select_img ) {
        return
    }
    loop, parse, select_img, `n
    {
        if( A_Index == 1 ) {
            selected_dir := A_LoopField
            continue
        }
        if( A_Index == 2 ) {
            img_path = %selected_dir%\%A_LoopField%
        }
        ; if select multiple files, run new instance
        else if( A_LoopField )
        {
            OpenImageInNewWindow(selected_dir, A_LoopField)
        }
    }
    if( img_path )
    {
        ImageListInitialize(img_path)
        GuiShowImage(img_path)
        GuiUpdateTitle(img_path)
    }
    return
}

; direction: -1 ~ +1
UpdateImageIndex(direction)
{
    local
    global img_path_list, img_list_index

    if( direction > 0 ) {
        img_list_index := (img_list_index >= img_path_list.Length()) ? 1 : img_list_index + 1
    }
    else {
        img_list_index := (img_list_index <= 1) ? img_path_list.Length() : img_list_index - 1
    }
}

;*******************************************************************************
;
NextPicture:
PrevPicture:
    if( WinActive("ahk_group AHKPV") )
    {
        UpdateImageIndex(A_ThisLabel == "NextPicture" ? +1 : -1)
        GuiShowImage(GetCurrentImagePath(), "last", true)
        GuiUpdateTitle(GetCurrentImagePath())
    }
return
