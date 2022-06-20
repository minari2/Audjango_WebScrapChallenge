FileRead, form_raw, *c form_raw_data.txt

; buffer := new Buffer((StrLen(form_raw) * 2))
; buffer.WriteStr(form_raw)

; buffer.Done() ; raw_data

; offset := 0x10
; text := StrGet(&form_raw + offset, "UTF-8")
; Msgbox,% text
; Msgbox,% StrLen(form_raw)



; Loop, % VarSetCapacity(form_raw) { ; parse through each character
; 	chr := Chr(*(&form_raw + A_Index)) ; check if character is in ASCII range
; 	If chr ; if it is...
; 		asc = %asc%%chr% ; then build another var
; }
; VarSetCapacity(bin, 0) ; empty binary variable to free memory
; MsgBox, %asc%

; find `r`n

find_char := "`r`n`r`n"
; find_char_length := StrLen(find_char)


; Msgbox,% 5//2

text := ""
boundary := "---------------------------17038290032358951008704054732"

; Loop,% VarSetCapacity(form_raw)-StrLen(find_char) +1
; {
;     if(StrGet(&form_raw + A_Index, find_char_length, "UTF-8") = find_char)
;     {
;         text := StrGet(&form_raw, A_Index, "UTF-8")
;         break
;     }

; }
; Msgbox,% text

headers := find_string_from_binary(form_raw, "`r`n`r`n", found_pos)
body := find_string_from_binary(form_raw, "--" . boundary . "`r`n", tt, found_pos)
Msgbox,% tt
return

find_string_from_binary(raw_data, find_str, ByRef found_position=0, offset=0)
{
    Loop,% VarSetCapacity(raw_data) - StrLen(find_str) + 1
    {
        found_position := A_Index
        if(StrGet(&raw_data + A_Index, StrLen(find_str), "UTF-8") = find_str)
        {
            MSgbox,% StrGet(&raw_data + A_Index, StrLen(find_str), "UTF-8")
            data := StrGet(&raw_data + offset, A_Index, "UTF-8")
            break
        }
    }
    return data
}

find_binary_data_from_body(raw_data, boundary)
{
    Loop,% VarSetCapacity(raw_data) - StrLen(boundary) + 1
    {
        found_position := A_Index
        if(StrGet(&raw_data + A_Index, StrLen(boundary), "UTF-8") = boundary)
        {
            ; MSgbox,% StrGet(&raw_data + A_Index, StrLen(boundary), "UTF-8")
            ; data := StrGet(&raw_data + offset, A_Index, "UTF-8")


            break
        }
    }
    return data
}




/*

import email
import pprint
from io import StringIO

request_string = 'GET / HTTP/1.1\r\nHost: localhost\r\nConnection: keep-alive\r\nCache-Control: max-age=0\r\nUpgrade-Insecure-Requests: 1\r\nUser-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Safari/537.36\r\nAccept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8\r\nAccept-Encoding: gzip, deflate, sdch\r\nAccept-Language: en-US,en;q=0.8'

# pop the first line so we only process headers
_, headers = request_string.split('\r\n', 1)

# construct a message from the request string
message = email.message_from_file(StringIO(headers))

# construct a dictionary containing the headers
headers = dict(message.items())

# pretty-print the dictionary of headers
pprint.pprint(headers, width=160)

*/

class RequestParser
{
    __New(data)
    {
        this.data := data
        
    }
    _find_rn()
    {

    }
    _set_prcess_header()
    {

    }
}

class Buffer
{
    __New(len) {
        this.SetCapacity("buffer", len)
        this.length := 0
    }

    FromString(str, encoding = "UTF-8") {
        length := Buffer.GetStrSize(str, encoding)
        buffer := new Buffer(length)
        buffer.WriteStr(str)
        return buffer
    }

    GetStrSize(str, encoding = "UTF-8") {
        encodingSize := ((encoding="utf-16" || encoding="cp1200") ? 2 : 1)
        ; length of string, minus null char
        return StrPut(str, encoding) * encodingSize - encodingSize
    }

    WriteStr(str, encoding = "UTF-8") {
        length := this.GetStrSize(str, encoding)
        VarSetCapacity(text, length)
        StrPut(str, &text, encoding)

        this.Write(&text, length)
        return length
    }

    ; data is a pointer to the data
    Write(data, length) {
        p := this.GetPointer()
        DllCall("RtlMoveMemory", "uint", p + this.length, "uint", data, "uint", length)
        this.length += length
    }

    Append(ByRef buffer) {
        destP := this.GetPointer()
        sourceP := buffer.GetPointer()

        DllCall("RtlMoveMemory", "uint", destP + this.length, "uint", sourceP, "uint", buffer.length)
        this.length += buffer.length
    }

    GetPointer() {
        return this.GetAddress("buffer")
    }

    Done() {
        this.SetCapacity("buffer", this.length)
    }
}


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