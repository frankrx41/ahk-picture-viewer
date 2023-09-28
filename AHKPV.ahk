#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
cmd_line := ""
for k,v in A_Args
{
    cmd_line .= v
}
Run, % A_AhkPath " ahk_picture_viewer.ahk """ cmd_line """"
