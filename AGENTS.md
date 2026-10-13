# Repository Guidelines

## Project Structure & Module Organization

This Windows picture viewer uses AutoHotkey v1.1 syntax. `AHKPV.ahk` is the launcher; `ahk_picture_viewer.ahk` initializes GDI+, processes arguments, and includes the feature modules. Keep GUI work in `_gui.ahk`, image rendering in `_image.ahk`, file navigation in `_file.ahk`, keyboard bindings in `_hotkey.ahk`, menu actions in `_menu.ahk`, and shared helpers in `_lib.ahk` (all use the `ahk_picture_viewer` prefix).

`lib/Gdip.ahk` contains the bundled GDI+ library. `assets/` holds README screenshots. `AHKPV.ico` and `AHKPV.reg` support Windows integration. `py_dddd_clip_ocr.py` provides optional OCR. There is no dedicated test directory or build configuration.

## Build, Test, and Development Commands

Run these commands from the repository root in PowerShell, with the relevant executables on `PATH`:

- `AutoHotkey.exe .\AHKPV.ahk` — launch with AutoHotkey v1.1; v2 syntax is incompatible.
- `AutoHotkey.exe .\AHKPV.ahk ".\assets\clip_20230928_084524.png"` — open a sample image.
- `Ahk2Exe.exe /in AHKPV.ahk /out AHKPV.exe /icon AHKPV.ico` — compile the launcher using the v1 toolchain. The launcher invokes `ahk_picture_viewer.ahk`; verify packaging separately before distribution.
- `py -m pip install ddddocr Pillow` — install optional OCR dependencies.
- `py .\py_dddd_clip_ocr.py "path\to\image.png"` — check OCR output directly.

## Coding Style & Naming Conventions

Use four-space indentation for new code and preserve surrounding brace style. Follow existing PascalCase function names, such as `GuiShowImage`, and snake_case variables, such as `img_path_list`. Keep explicit `local`/`global` declarations where used. Preserve v1 command syntax, labels, and hotkey scoping. No formatter or linter is configured; avoid unrelated reformatting or edits to the bundled GDI+ library.

## Testing Guidelines

No automated framework or coverage threshold is configured. Manually check opening files, drag-and-drop, previous/next navigation, zoom, fit modes, resizing, clipboard actions, and exit. Test deletion only with disposable images. For sorting changes, include ordinary filenames and `photo_<number>_YYYY-MM-DD_HH-MM-SS` filenames. Verify OCR separately when changed, and record the Windows and AutoHotkey versions used.

## Commit & Pull Request Guidelines

History uses short imperative subjects such as `Fix scale` and `Update sort`; no mandatory prefix convention is evident. Prefer specific subjects and focused commits. PRs should explain behavior changes, link relevant issues, and list manual checks. Include screenshots for visual changes and update README hotkeys when bindings change.
