#SingleInstance, force
#NoEnv

; Define the primary paths more efficiently
scriptDir := A_ScriptDir
saveDir := scriptDir . "\..\Accounts\Saved"

; Clean up path efficiently
saveDir := StrReplace(saveDir, "\\", "\")

; Quick directory existence check with fallback
if (!FileExist(saveDir)) {
    ; Try alternative path directly
    saveDir := scriptDir . "\Accounts\Saved"
    saveDir := StrReplace(saveDir, "\\", "\")
    
    ; Exit immediately if neither path exists
    if (!FileExist(saveDir)) {
        ExitApp
    }
}

; Use batch file deletion for maximum speed
; Create a temporary batch script for bulk deletion
tempBatchFile := A_Temp . "\reset_lists_" . A_TickCount . ".bat"

; Build the batch commands for ultra-fast deletion
batchContent := "@echo off`n"
batchContent .= "cd /d """ . saveDir . """`n"

; Add deletion commands for all possible list files in all subdirectories
; This processes all folders and files in a single batch operation
batchContent .= "for /d %%i in (*) do (`n"
batchContent .= "    if exist ""%%i\list.txt"" del /q ""%%i\list.txt"" 2>nul`n"
batchContent .= "    if exist ""%%i\list_current.txt"" del /q ""%%i\list_current.txt"" 2>nul`n"
batchContent .= "    if exist ""%%i\list_last_generated.txt"" del /q ""%%i\list_last_generated.txt"" 2>nul`n"
batchContent .= ")`n"

; Write the batch file
FileDelete, %tempBatchFile%
FileAppend, %batchContent%, %tempBatchFile%

; Execute the batch file and wait for completion
RunWait, "%tempBatchFile%",, Hide

; Clean up the temporary batch file
FileDelete, %tempBatchFile%

ExitApp