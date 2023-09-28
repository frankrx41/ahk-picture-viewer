CopyAsFile:
    ClipboardSetFiles(GetCurrentImagePath())
return

ReOpenFile:
    GuiShowImage(GetCurrentImagePath())
    GuiUpdateTitle(GetCurrentImagePath())
return

CloseFile:
    GuiShowImage("")
    GuiUpdateTitle("")
return

CopyToClipboard:
    CopyImageToClipboard(GetCurrentImagePath())
return

CopyAsHTML:
    Clipboard := "<IMG src=""data:image/png;base64," GetFileBase64(GetCurrentImagePath()) """>"
return

CopyAsMarkdown:
    ; TODO: Check it
    Clipboard := "![img](" . GetCurrentImagePath() . ")"
return

CopyAsText:
    Clipboard := GetDdddOcr(GetCurrentImagePath())
    MsgBox, 64, image.exe, Text copied:`n`n%Clipboard%
return

CopyAsPath:
    Clipboard := GetCurrentImagePath()
return

ViewFileProperties:
    Run, % "Properties """ GetCurrentImagePath() """"
return

Exit:
ExitApp
