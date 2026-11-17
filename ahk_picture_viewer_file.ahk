ImageListInitialize(file_path)
{
    local
    global img_path_list, img_list_index
    global file_ext_list

    CancelFolderCache()
    img_path_list := []

    SplitPath, file_path, file_name, file_dir, file_ext, file_name_no_ext

    tempList := ""  ; will hold lines: key|fullpath

    Loop, Files, %file_dir%\*
    {
        if A_LoopFileExt in %file_ext_list%
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

CancelFolderCache()
{
    global folder_cache
    SetTimer, CacheFolderTick, Off
    folder_cache := ""
}

LoadAllFolderFiles()
{
    global folder_cache, img_path_list
    if( !IsObject(img_path_list) || !img_path_list.Length() )
        return
    CancelFolderCache()
    folder_cache := {list: img_path_list, done: 0, failed: 0, total: img_path_list.Length(), active: true}
    GuiUpdateTitle(GetCurrentImagePath())
    SetTimer, CacheFolderTick, -50
}

CacheFolderTick()
{
    global folder_cache, img_path_list, image_cache
    was_critical := A_IsCritical
    Critical, On
    try {
        if( !IsObject(folder_cache) || !folder_cache.active )
            return
        if( folder_cache.list != img_path_list ) {
            CancelFolderCache()
            return
        }
        path := folder_cache.list[folder_cache.done + 1]
        if( !image_cache.Get(path) )
            folder_cache.failed += 1
        folder_cache.done += 1
        folder_cache.active := folder_cache.done < folder_cache.total
        GuiUpdateTitle(GetCurrentImagePath())
        if( folder_cache.active )
            SetTimer, CacheFolderTick, -50
    } finally {
        Critical, % was_critical
    }
}

FolderCacheStatus()
{
    global folder_cache, img_path_list, image_cache
    count := 0
    total := IsObject(img_path_list) ? img_path_list.Length() : 0
    for index, path in img_path_list {
        if( IsObject(image_cache) && image_cache.entries.HasKey(path) )
            count += 1
    }
    current_job := IsObject(folder_cache) && folder_cache.list == img_path_list
    bytes := IsObject(image_cache) ? image_cache.bytes : 0
    size := bytes >= 1024 * 1024 * 1024
        ? Format("{:.2f} GiB", bytes / (1024 * 1024 * 1024))
        : Format("{:.1f} MiB", bytes / (1024 * 1024))
    return " | " (current_job && folder_cache.active ? "Caching " : "Cached ")
        . count "/" total " | Cache memory: " size
        . (current_job && folder_cache.failed ? " (" folder_cache.failed " failed)" : "")
}

PreloadNextImage()
{
    local
    global img_path_list, img_list_index, image_cache, pv_has_image

    ; AHK v1 timers share the GUI thread. Buffer navigation until the cache
    ; entry is complete; never wait in an interrupting hotkey for this timer.
    ; Protect target selection too, so navigation cannot change the list/index
    ; between choosing the next image and starting its decode.
    was_critical := A_IsCritical
    Critical, On
    try {
        if( !pv_has_image || !img_list_index || img_path_list.Length() < 2 )
            return
        next_index := img_list_index >= img_path_list.Length() ? 1 : img_list_index + 1
        next_path := img_path_list[next_index]
        if( next_path != "" && FileExist(next_path) )
            image_cache.Get(next_path)
    } finally {
        Critical, % was_critical
    }
}

GetCurrentImageName()
{
    filePath := GetCurrentImagePath()
    SplitPath, filePath, fileName
    return fileName
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
