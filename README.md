# ahk-picture-viewer

This is a simple picture viewer tool written in AHK

Support bmp, jpg, png, ico

## How to start

Run "AHKPV.ahk" to start.

You can compile AHKPV.ahk to AHKPV.exe, and set image open with it.
And then goto `HKEY_CLASSES_ROOT\Applications\AHKPV.exe` and set

```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\Applications\AHKPV.exe\shell\open]
@="View (AHK)"
"Icon"="\"AHKPV.ico\""

[HKEY_CLASSES_ROOT\Applications\AHKPV.exe\shell\open\command]
@="\"AHKPV.exe\" \"%1\""
```

Then you will get this right menu:

![image](https://github.com/frankrx41/ahk-picture-viewer/assets/21332318/88a9806e-85ec-4ade-9900-67b670c1103a)

## Screenshot

![image](https://github.com/frankrx41/ahk-picture-viewer/assets/21332318/70b11ccf-e5aa-40ed-868d-fc0b68d59b4d)

![image](https://github.com/frankrx41/ahk-picture-viewer/assets/21332318/dc3cd5bd-375e-4f21-abaf-9172c675eaa5)

## Hotkeys

* <kbd>Left</kbd> / <kbd>Right</kbd> to change image
* <kbd>1</kbd> ~ <kbd>5</kbd> to set scale value
* <kbd>Space</kbd> to maximize window and set fit width
* <kbd>Enter</kbd> to maximize window and set fit image
* <kbd>Backspace</kbd> to set window fit to image

## Copy as text

This function need ddddocr support, see <https://github.com/sml2h3/ddddocr>

## Special Thanks

* "AHK Picture Viewer" write by sbc <https://www.autohotkey.com/board/topic/58226-ahk-picture-viewer/>
* "image-viewer" write by langheran <https://github.com/langheran/image-viewer>
