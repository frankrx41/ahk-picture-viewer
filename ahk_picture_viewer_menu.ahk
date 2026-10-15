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
    SplitPath, % GetCurrentImagePath(), , , image_extension
    image_mime := image_extension = "webp" ? "image/webp" : "image/png"
    Clipboard := "<IMG src=""data:" image_mime ";base64," GetFileBase64(GetCurrentImagePath()) """>"
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
