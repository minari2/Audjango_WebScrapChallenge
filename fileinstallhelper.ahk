; when deploy,
; first run this script
; and it can compile to binary file with needed files.

subfolder := Array()
loop, Files, %A_SCriptDir%\*.*, FR ; R = recurse into folders
{
    SplitPath, A_LoopFileFullPath, oFileName, oDirName, oEXT, oNameNoExt
    if (oEXT = "ahk")
        continue

    if(instr(oDirName, "lib") or instr(oDirName, "AHKhttp") or instr(oDirName, ".git"))
        Continue

    sub_dir_path := StrReplace(A_LoopFileFullPath, A_ScriptDir, "")
    sub_dir_path := StrReplace(sub_dir_path, oFileName, "")
    ; MSgbox,% sub_dir_path
    if(!HasVal(subfolder, sub_dir_path))
    {
        subfolder.Push(sub_dir_path)
        FileAppend, % "FileCreateDir, `%A_ScriptDir`%" . sub_dir_path . "`n", MyFileInstallScript.ahk
    }
    FileAppend, % "FileInstall, " A_LoopFileFullPath ", `%A_ScriptDir`%" . sub_dir_path . A_LoopFileName "`n", MyFileInstallScript.ahk
}
Return

HasVal(haystack, needle) {
	if !(IsObject(haystack)) || (haystack.Length() = 0)
		return 0
	for index, value in haystack
		if (value = needle)
			return index
	return 0
}