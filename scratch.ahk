; ; Content-Disposition: form-data; name="ttt"; filename="testdatatext.txt"
; tt := "Content-Disposition: form-data; name=""ttt""; filename=""testdatatext.txt"""
; aa := regexmatch(tt, "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)
; OutputDebug, % _["filename"] . "`n" . _["name"]
; return

vtext = 
(
-----------------------------6432351878510131532453799569
Content-Disposition: form-data; name="ttt"; filename="testdatatext.txt"
Content-Type: text/plain
test_data_text
asdfasdf

adfs
-----------------------------6432351878510131532453799569
Content-Disposition: form-data; name="ttt"; filename="testdatatext.txt"
Content-Type: text/plain
test_data_text
-----------------------------6432351878510131532453799569
Content-Disposition: form-data; name="zzz"
테스트
-----------------------------6432351878510131532453799569--
)
boundary := "-----------------------------6432351878510131532453799569"
t := StrSplit(vtext, boundary, "`n")

data_collection := []

for k, content in t
{
    content_data := StrSplit(content, "`n")

    if(StrLen(content_data[1]) < 3)
        continue

    Content_disposition_length := StrLen(content_data[1])
    Content_Type_length := StrLen(content_data[2])
    c_length := Content_disposition_length + Content_Type_length+3
    data := SubStr(content, c_length, StrLen(content) - c_length+1)

    Disposition := StrSplit(content_data[1], ":")
    Content_Type_line := StrSplit(content_data[2], ": ")

    aa := regexmatch(tt, "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)
    ; OutputDebug, % _["filename"] . "`n" . _["name"]
    info := {"name":_["name"], "filename":_["filename"], "Content-Type":Content_Type_line[2]}
    data_collection.push(info)
}

return


text := "multipart/form-data; boundary=---------------------------319170419021049609841763391870"
tt := regexmatch(text, "(boundary=)(.*)", results)
; Msgbox,% results
Msgbox,% results2
; Msgbox,% tt

return


TestString := "me  This is a test apple."

; regexmatch(teststring, "(me)(.*?)(?=apple)", results)
; msgbox, % results2

return

file := Fileopen("version", "w")
file.Write("0.0.0.0.1")
file.close()
return

Version1 := "0.0.0.3"
Version2 := "0.0.0.3"
tt := []
tt.push(Version1, Version2)
Latest := VersionCompare(tt[1], tt[2])
if not Latest
    Msgbox,111
Msgbox,% tt[Latest]
; MsgBox, % (Latest ? "Version" . Latest . " is the latest" : "Both versions are the same") . " at " . (Latest ? Version%Latest% : Version1)

return

; Demo the function:
Version1 := "9.1.3.2"
Version2 := "10.1.3.5"
Latest := VersionCompare(Version1, Version2)
MsgBox, % (Latest ? "Version" . Latest . " is the latest" : "Both versions are the same") . " at " . (Latest ? Version%Latest% : Version1)
return

VersionCompare(version1, version2)
{
	StringSplit, verA, version1, .
	StringSplit, verB, version2, .
	Loop, % (verA0> verB0 ? verA0 : verB0)
	{
		if (verA0 < A_Index)
			verA%A_Index% := "0"
		if (verB0 < A_Index)
			verB%A_Index% := "0"
		if (verA%A_Index% > verB%A_Index%)
			return 1
		if (verB%A_Index% > verA%A_Index%)
			return 2
	}
	return 0
}

Return

; FileAppend, %response%, ttt
; test := "/goglgo/Audjango_WebScrapChallenge/releases/download/0.0.1.1/manage.exe"
needle := "/goglgo/Audjango_WebScrapChallenge/releases/download/(.*)/manage.exe"
; needle := "<span class=""px-1 text-bold"">(.*)</span>"
FileRead, response, ttt
; FileRead, response, % "*t ttt"
ttt:= RegExMatch(response, needle, result)
Msgbox,% result1
; Msgbox,% ttt


Return

FileRead, main, % "*t " . A_Scriptdir . "\templates\base.html"

FileRead, example, % "*t " . A_ScriptDir . "\WebScrapChallenge\views\test_page.html"

tt := RegExMatch(main, "{% block (.*) %}", base)
Msgbox,% base1
; Msgbox,% A_Scriptdir . "\templates\base.html"

return
block_list := []

loop, parse, example, `n, `r
{
    if RegExMatch(A_LoopField, "{% block (.*) %}", blocks)
        {
            block_list.Push(blocks1)
        }
}
; "{% block ttt %}(.*){% endblock ttt %}"
for k, v in block_list
{
    ; main
    tt := RegExMatch(example, "{% block ttt %}(.*){% endblock ttt %}", base)
    MSgbox,% base1
    if base1
    {
        main := RegExReplace(main, "{% block " . v . " %}(.*){% endblock " . v . " %}", base1)    
    }
    ; tt := RegExReplace(example, "{% block " . v . " %}(.*){% endblock " . v . " %}", Replacement = "")
    ; Msgbox,% base1
}
Msgbox,% main