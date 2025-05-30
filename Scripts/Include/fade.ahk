#SingleInstance Force

TargetWindowTitle := "PTCGPB Bot Setup [Non-Commercial 4.0 International License]"
WinGetPos, x, y, w, h, %TargetWindowTitle%

stopSignalFile := A_ScriptDir "\stop.signal"
goSignalFile := A_ScriptDir "\go.signal"
fadeFinish := A_ScriptDir "\finish.signal"

; Create GUI mask
Gui, Mask:New
Gui, Mask:+ToolWindow -Caption +AlwaysOnTop +E0x80000 +LastFound
Gui, Mask:Color, 2d2d2d
WinSet, Transparent, 0
WinSet, ExStyle, +0x20
Gui, Mask:Show, w380 h705 x%x% y%y% NoActivate

; Ensure clean initial state
FileDelete, %goSignalFile%
FileDelete, %fadeFinish%

; === Fade In ===
Loop 17 {
    if FileExist(stopSignalFile)
        goto CleanupAndExit
    WinSet, Transparent, % (A_Index * 15), ahk_class AutoHotkeyGUI
    Sleep, 1
}

; Create finish.signal to notify the main script
FileAppend,, %fadeFinish%

; === Wait for go.signal or timeout ===
WaitCount := 0
MaxWait := 30 ; Max wait: 30 * 10ms = 300ms

Loop {
    if FileExist(stopSignalFile)
        goto CleanupAndExit
    if FileExist(goSignalFile)
        break
    Sleep, 10
    WaitCount++
    if (WaitCount >= MaxWait)
        break
}

; Clean up signal files
FileDelete, %goSignalFile%
FileDelete, %fadeFinish%

; === Fade Out ===
Loop 17 {
    if FileExist(stopSignalFile)
        goto CleanupAndExit
    WinSet, Transparent, % (255 - A_Index * 15), ahk_class AutoHotkeyGUI
    Sleep, 2
}

Gui, Mask:Destroy
ExitApp

CleanupAndExit:
    Gui, Mask:Destroy
ExitApp
