; Define a function to get the device context of a gui control
GuiControlGetDC(ByRef hdc, Control) {
    ; Get the hwnd of the gui control
    GuiControlGet, hwnd, Hwnd, % Control

    ; Get the device context of the hwnd using GetDC
    hdc := DllCall("user32\GetDC", "UInt", hwnd)

    ; return true if successful, false otherwise
    return hdc ? true : false
}

;by Lexikos http://www.autohotkey.com/forum/post-170475.html
GetClientSize(hwnd, ByRef w, ByRef h)
{
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
    w := NumGet(rc, 8, "int")
    h := NumGet(rc, 12, "int")
}

IsImageFile(filepath)
{
    global file_ext_list
    loop, %filepath%
    {
        if A_LoopFileExt in %file_ext_list%
        {
            return true
        }
    }
}

GetFileLongPath(shortpath)
{
    loop, %shortpath%
    {
        return A_LoopFileLongPath
    }
}

Gdip_ShowImgonGui(GuiVariable, imgfile, Width, Height)
{
    return
}

GetFileBase64(file_path) {
    FileGetSize, n_bytes, % file_path
    FileRead, Bin, % "*c " file_path
    base64_data := Base64Enc( Bin, n_bytes, 100, 0 )
    return base64_data
}

; By SKAN / 18-Aug-2017
Base64Enc( ByRef Bin, nBytes, LineLength := 64, LeadingSpaces := 0 ) {
    Local Rqd := 0, B64, B := "", N := 0 - LineLength + 1  ; CRYPT_STRING_BASE64 := 0x1
    DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin ,"UInt",nBytes, "UInt",0x1, "Ptr",0,   "UIntP",Rqd )
    VarSetCapacity( B64, Rqd * ( A_Isunicode ? 2 : 1 ), 0 )
    DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin, "UInt",nBytes, "UInt",0x1, "Str",B64, "UIntP",Rqd )
    If ( LineLength = 64 and ! LeadingSpaces )
        Return B64
    B64 := StrReplace( B64, "`r`n" )
    Loop % Ceil( StrLen(B64) / LineLength )
        B .= Format("{1:" LeadingSpaces "s}","" ) . SubStr( B64, N += LineLength, LineLength ) . "`n" 
    Return RTrim( B,"`n" )
}

; By SKAN / 18-Aug-2017
Base64Dec( ByRef B64, ByRef Bin ) {
    Local Rqd := 0, BLen := StrLen(B64)                 ; CRYPT_STRING_BASE64 := 0x1
    DllCall( "Crypt32.dll\CryptStringToBinary", "Str",B64, "UInt",BLen, "UInt",0x1
            , "UInt",0, "UIntP",Rqd, "Int",0, "Int",0 )
    VarSetCapacity( Bin, 128 ), VarSetCapacity( Bin, 0 ),  VarSetCapacity( Bin, Rqd, 0 )
    DllCall( "Crypt32.dll\CryptStringToBinary", "Str",B64, "UInt",BLen, "UInt",0x1
            , "Ptr",&Bin, "UIntP",Rqd, "Int",0, "Int",0 )
    Return Rqd
}

CopyImageToClipboard(file_path) {
    local
    pBitmap := Gdip_CreateBitmapFromFile(file_path)
    Gdip_SetBitmapToClipboard(pBitmap)
    Gdip_DisposeImage(pBitmap)

    DllCall("OpenClipboard", "UPtr", 0)
    DllCall("CloseClipboard")
    return
}

ClipboardSetFiles(FilesToSet, DropEffect := "Copy") {
    ; FilesToSet - list of fully qualified file pathes separated by "`n" or "`r`n"
    ; DropEffect - preferred drop effect, either "Copy", "Move" or "" (empty string)
    Static TCS := A_IsUnicode ? 2 : 1 ; size of a TCHAR
    Static PreferredDropEffect := DllCall("RegisterClipboardFormat", "Str", "Preferred DropEffect")
    Static DropEffects := {1: 1, 2: 2, Copy: 1, Move: 2}
    ; -------------------------------------------------------------------------------------------------------------------
    ; Count files and total string length
    TotalLength := 0
    FileArray := []
    Loop, Parse, FilesToSet, `n, `r
    {
        If (Length := StrLen(A_LoopField))
            FileArray.Push({Path: A_LoopField, Len: Length + 1})
        TotalLength += Length
    }
    FileCount := FileArray.Length()
    If !(FileCount && TotalLength)
       Return False
    ; -------------------------------------------------------------------------------------------------------------------
    ; Add files to the clipboard
    If DllCall("OpenClipboard", "Ptr", A_ScriptHwnd) && DllCall("EmptyClipboard") {
        ; HDROP format ---------------------------------------------------------------------------------------------------
        ; 0x42 = GMEM_MOVEABLE (0x02) | GMEM_ZEROINIT (0x40)
        hDrop := DllCall("GlobalAlloc", "UInt", 0x42, "UInt", 20 + (TotalLength + FileCount + 1) * TCS, "UPtr")
        pDrop := DllCall("GlobalLock", "Ptr" , hDrop)
        Offset := 20
        NumPut(Offset, pDrop + 0, "UInt")         ; DROPFILES.pFiles = offset of file list
        NumPut(!!A_IsUnicode, pDrop + 16, "UInt") ; DROPFILES.fWide = 0 --> ANSI, fWide = 1 --> Unicode
        For Each, File In FileArray
            Offset += StrPut(File.Path, pDrop + Offset, File.Len) * TCS
        DllCall("GlobalUnlock", "Ptr", hDrop)
        DllCall("SetClipboardData","UInt", 0x0F, "UPtr", hDrop) ; 0x0F = CF_HDROP
        ; Preferred DropEffect format ------------------------------------------------------------------------------------
        If (DropEffect := DropEffects[DropEffect]) {
            ; Write Preferred DropEffect structure to clipboard to switch between copy/cut operations
            ; 0x42 = GMEM_MOVEABLE (0x02) | GMEM_ZEROINIT (0x40)
            hMem := DllCall("GlobalAlloc", "UInt", 0x42, "UInt", 4, "UPtr")
            pMem := DllCall("GlobalLock", "Ptr", hMem)
            NumPut(DropEffect, pMem + 0, "UChar")
            DllCall("GlobalUnlock", "Ptr", hMem)
            DllCall("SetClipboardData", "UInt", PreferredDropEffect, "Ptr", hMem)
        }
        DllCall("CloseClipboard")
        ; DllCall("GlobalFree", "Ptr", hMem)
        Return True
    }
    Return False
}

GetDdddOcr(file_path)
{
    local
    cmdline :=  "py py_dddd_clip_ocr.py """ file_path """"
    try {
        return CmdRet(cmdline)
    }
}

; https://www.autohotkey.com/boards/viewtopic.php?t=86355
CmdRet(sCmd, callBackFuncObj := "", encoding := "CP0")
{
    ; MsgBox, %sCmd%
    static HANDLE_FLAG_INHERIT := 0x00000001, flags := HANDLE_FLAG_INHERIT
        , STARTF_USESTDHANDLES := 0x100, CREATE_NO_WINDOW := 0x08000000
    hPipeRead:=""
    hPipeWrite:=""
    sOutput:=""
    DllCall("CreatePipe", "PtrP", hPipeRead, "PtrP", hPipeWrite, "Ptr", 0, "UInt", 0)
    DllCall("SetHandleInformation", "Ptr", hPipeWrite, "UInt", flags, "UInt", HANDLE_FLAG_INHERIT)

    VarSetCapacity(STARTUPINFO , siSize := A_PtrSize*4 + 4*8 + A_PtrSize*5, 0)
    NumPut(siSize , STARTUPINFO)
    NumPut(STARTF_USESTDHANDLES, STARTUPINFO, A_PtrSize*4 + 4*7)
    NumPut(hPipeWrite , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*3)
    NumPut(hPipeWrite , STARTUPINFO, A_PtrSize*4 + 4*8 + A_PtrSize*4)

    VarSetCapacity(PROCESS_INFORMATION, A_PtrSize*2 + 4*2, 0)
    if !DllCall("CreateProcess", "Ptr", 0, "Str", sCmd, "Ptr", 0, "Ptr", 0, "UInt", true, "UInt", CREATE_NO_WINDOW
        , "Ptr", 0, "Ptr", 0, "Ptr", &STARTUPINFO, "Ptr", &PROCESS_INFORMATION)
    {
        DllCall("CloseHandle", "Ptr", hPipeRead)
        DllCall("CloseHandle", "Ptr", hPipeWrite)
        throw Exception("CreateProcess is failed")
    }
    DllCall("CloseHandle", "Ptr", hPipeWrite)
    VarSetCapacity(sTemp, 4096), nSize := 0
    while DllCall("ReadFile", "Ptr", hPipeRead, "Ptr", &sTemp, "UInt", 4096, "UIntP", nSize, "UInt", 0) {
        sOutput .= stdOut := StrGet(&sTemp, nSize, encoding)
        ;sOutput .= stdOut := StrGet(&sTemp, nSize)
        ;sOutput .= stdOut := StrGet(&sTemp, nSize, CPX)
        ( callBackFuncObj && callBackFuncObj.Call(stdOut) )
    }
    DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION))
    DllCall("CloseHandle", "Ptr", NumGet(PROCESS_INFORMATION, A_PtrSize))
    DllCall("CloseHandle", "Ptr", hPipeRead)
    Return sOutput
}

JEE_WinGetPosClient(hWnd, ByRef vWinX, ByRef vWinY, ByRef vWinW, ByRef vWinH)
{
	VarSetCapacity(RECT, 16, 0)
	DllCall("user32\GetClientRect", Ptr,hWnd, Ptr,&RECT)
	DllCall("user32\ClientToScreen", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int"), vWinY := NumGet(&RECT, 4, "Int")
	vWinW := NumGet(&RECT, 8, "Int"), vWinH := NumGet(&RECT, 12, "Int")
}


JEE_ClientToScreen(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ClientToScreen", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}

;==================================================

JEE_ScreenToClient(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ScreenToClient", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}

;==================================================

JEE_ScreenToWindow(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 := vPosX - vWinX
	vPosY2 := vPosY - vWinY
}

;==================================================

JEE_WindowToScreen(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16, 0)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 := vPosX + vWinX
	vPosY2 := vPosY + vWinY
}

;==================================================

JEE_ClientToWindow(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(POINT, 8)
	NumPut(vPosX, &POINT, 0, "Int")
	NumPut(vPosY, &POINT, 4, "Int")
	DllCall("user32\ClientToScreen", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")

	VarSetCapacity(RECT, 16)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")
	vPosX2 -= vWinX
	vPosY2 -= vWinY
}

;==================================================

JEE_WindowToClient(hWnd, vPosX, vPosY, ByRef vPosX2, ByRef vPosY2)
{
	VarSetCapacity(RECT, 16, 0)
	DllCall("user32\GetWindowRect", Ptr,hWnd, Ptr,&RECT)
	vWinX := NumGet(&RECT, 0, "Int")
	vWinY := NumGet(&RECT, 4, "Int")

	VarSetCapacity(POINT, 8)
	NumPut(vPosX+vWinX, &POINT, 0, "Int")
	NumPut(vPosY+vWinY, &POINT, 4, "Int")
	DllCall("user32\ScreenToClient", Ptr,hWnd, Ptr,&POINT)
	vPosX2 := NumGet(&POINT, 0, "Int")
	vPosY2 := NumGet(&POINT, 4, "Int")
}
