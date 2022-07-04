tt := new Buffer(4)
buff := tt.FromString("abcd")
; buff := Buffer.FromString("abcd")
; tt.Done()
; OutputDebug, % Buffer.GetStrSize("abcd")
OutputDebug, % tt.GetPointer()
OutputDebug,% "1 " . StrGet(buff.GetPointer(), 4, "UTF-8")

dd := new Buffer(4)
edf := dd.FromString("efgh")

edf.append(buff)
OutputDebug,% "2 " . StrGet(edf.GetPointer(), 8, "UTF-8")
; edf.done()
; OutputDebug,% "3 " . StrGet(edf.GetPointer(), 10, "UTF-8")
; Msgbox,% StrGet(tt, 8)

Return

cutCookie := Array()
Cookies := "NNB=YJ2S4HQXSJTF2; NFS=2; _ga=GA1.2.1205915527.1571410902; ASID=7c38b4970000017030e2d4b20000004d"
Cookie := StrSplit(Cookies, ";" . A_Space)
for k, v in Cookie
{
    splited := StrSplit(v, "=")
    cutCookie[splited[1]] := splited[2]
    OutputDebug, % splited[1]
}

return

/*
tt = 
(
Content-Disposition: form-data; name="ttt"; filename="testdatatext.txt"
Content-Type: text/plain

test_data_text
)

aa := regexmatch(tt
    , "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)

if(not _["name"])
    aa := regexmatch(tt
    , "O)name=""(?<name>.*)""", _)

aa := regexmatch(tt
    , "O)Content-Type: (?<type>.*)`r`n`r`n", __)

; Msgbox,% _["filename"]
MSgbox,% __["type"]

return
*/

FileRead, form_raw, *c form_raw_data.txt
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

; headers := find_string_from_binary(form_raw, "`r`n`r`n", found_pos)
data := find_binary_data_from_body(form_raw, "--" . boundary)
; Msgbox,% body
return

find_string_from_binary(raw_data, find_str, ByRef found_position=0, offset=0)
{
    Loop,% VarSetCapacity(raw_data) - StrLen(find_str) + 1
    {
        found_position := A_Index
        if(StrGet(&raw_data + A_Index, StrLen(find_str), "UTF-8") = find_str)
        {
            ; MSgbox,% StrGet(&raw_data + A_Index, StrLen(find_str), "UTF-8")
            OutputDebug, % StrGet(&raw_data , A_Index, "UTF-8")
            data := StrGet(&raw_data + offset, A_Index, "UTF-8")
            break
        }
    }
    return data
}

; VarSetCapacity(buff, size, 0)
; ; copy var to buff
; DllCall("RtlMoveMemory", "Ptr", &buff, "Ptr", &var, "Ptr", size)
; ; copy buff to var
; DllCall("RtlMoveMemory", "Ptr", &var, "Ptr", &buff, "Ptr", size)

find_binary_data_from_body(raw_data, boundary)
{
    boundaries := []
    data := []
    Loop,% VarSetCapacity(raw_data) - StrLen(boundary)
    {
        if((StrGet(&raw_data + A_Index, StrLen(boundary), "UTF-8") = boundary)
            or (StrGet(&raw_data + A_Index, StrLen(boundary) + 2, "UTF-8") = boundary . "--"))
        {
            boundaries.Push(A_Index)
        }
    }

    data_collection := []
    
    for k, v in boundaries
    {
        if(boundaries[k+1])
        {   
            data_array := Array()

            ; Msgbox, % boundaries[k+1] - boundaries[k]
            ; content_data := StrGet(
            ;     &raw_data + v + 2 + StrLen(boundary)
            ;     , boundaries[k+1] - boundaries[k] - StrLen(boundary) - 4
            ;     , "UTF-8")
            
            offset := &raw_data + v + 2 + StrLen(boundary)
            data_end := boundaries[k+1] - boundaries[k] - StrLen(boundary) - 4
            ; offset_data := 
            
            find_str := "`r`n`r`n"
            Loop,% boundaries[k+1] - boundaries[k]
            {
                ; found_position := offset + A_Index
                if(StrGet(offset + A_Index, StrLen(find_str), "UTF-8") = find_str)
                {
                    ; MSgbox,% StrGet(&raw_data + A_Index, StrLen(find_str), "UTF-8")
                    found_pos := A_Index
                    binary_data_start := offset + found_pos + 4
                    data_header := StrGet(offset, A_Index, "UTF-8")
                    ; MSgbox,% v + 2 + StrLen(boundary) + found_pos + 4
                    ; MSgbox,% data_header
                    aa := regexmatch(data_header
                        , "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)
                    
                    if(not _["name"])
                        aa := regexmatch(data_header
                        , "O)name=""(?<name>.*)""", _)

                    aa := regexmatch(data_header
                        , "O)Content-Type: (?<type>.*)", __)
                    break
                }
            }

            data_size := (boundaries[k+1] - boundaries[k] - StrLen(boundary) - 4) - found_pos - 4

            data_array["name"] := _["name"]
            data_array["filename"] := _["filename"]
            data_array["type"] := __["type"]
            if(not data_array["type"])
            {
                data_array["data"] := StrGet(offset + found_pos + 4, data_size, "UTF-8")
            }
            else
            {
                VarSetCapacity(buff, data_size, 0)
                DllCall("RtlMoveMemory", "Ptr", &buff, "Ptr", binary_data_start, "Ptr", data_size)
                data_array["data"] := buff
            }
            ; Msgbox,% StrGet(binary_data_start, data_size, "UTF-8")

            ; copy var to buff
            ; copy buff to var
            ; DllCall("RtlMoveMemory", "Ptr", &var, "Ptr", &buff, "Ptr", size)
            
            ; BinWrite(v . ".txt", buff)

            data.Push(data_array)
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

return

; Bin2Hex(h,data,res)
; MsgBox Data = "%h%"
Bin2Hex(ByRef h, ByRef b, n=0)      ; n bytes binary data -> stream of 2-digit hex
{                                   ; n = 0: all (SetCapacity can be larger than used!)
   format = %A_FormatInteger%       ; save original integer format
   SetFormat Integer, Hex           ; for converting bytes to hex

   m := VarSetCapacity(b)
   If (n < 1 or n > m)
       n := m
   Address := &b
   h =
   Loop %n%
   {
      x := *Address                 ; get byte in hex
      StringTrimLeft x, x, 2        ; remove 0x
      x = 0%x%                      ; pad left
      StringRight x, x, 2           ; 2 hex digits
      h = %h%%x%
      Address++
   }
   SetFormat Integer, %format%      ; restore original format
}

Hex2Bin(ByRef b, h, n=0)            ; n hex digit-pairs -> binary data
{                                   ; n = 0: all. (Only ByRef can handle binaries)
   m := Ceil(StrLen(h)/2)
   If (n < 1 or n > m)
       n := m
   Granted := VarSetCapacity(b, n, 0)
   IfLess Granted,%n%, {
      ErrorLevel = Mem=%Granted%
      Return
   }
   Address := &b
   Loop %n%
   {
      StringLeft  x, h, 2
      StringTrimLeft h, h, 2
      x = 0x%x%
      DllCall("RtlFillMemory", "UInt", Address, "UInt", 1, "UChar", x)
      Address++
   }
}

BinWrite(file, ByRef data, n=0, offset=0)
{
   ; Open file for WRITE (0x40..), OPEN_ALWAYS (4): creates only if it does not exists
   h := DllCall("CreateFile","str",file,"Uint",0x40000000,"Uint",0,"UInt",0,"UInt",4,"Uint",0,"UInt",0)
   IfEqual h,-1, SetEnv, ErrorLevel, -1
   IfNotEqual ErrorLevel,0,Return,0 ; couldn't create the file

   m = 0                            ; seek to offset
   IfLess offset,0, SetEnv,m,2
   r := DllCall("SetFilePointerEx","Uint",h,"Int64",offset,"UInt *",p,"Int",m)
   IfEqual r,0, SetEnv, ErrorLevel, -3
   IfNotEqual ErrorLevel,0, {
      t = %ErrorLevel%              ; save ErrorLevel to be returned
      DllCall("CloseHandle", "Uint", h)
      ErrorLevel = %t%              ; return seek error
      Return 0
   }

   m := VarSetCapacity(data)        ; get the capacity ( >= used length )
   If (n < 1 or n > m)
       n := m
   result := DllCall("WriteFile","UInt",h,"Str",data,"UInt",n,"UInt *",Written,"UInt",0)
   if (!result or Written < n)
       ErrorLevel = -3
   IfNotEqual ErrorLevel,0, SetEnv,t,%ErrorLevel%

   h := DllCall("CloseHandle", "Uint", h)
   IfEqual h,-1, SetEnv, ErrorLevel, -2
   IfNotEqual t,,SetEnv, ErrorLevel, %t%-%ErrorLevel%

   Return Written
}

/* ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; BinRead ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
|  - Open binary file
|  - Read n bytes (n = 0: file size)
|  - From offset (offset < 0: counted from end)
|  - Close file
|  (Binary)data (replaced) <- file[offset + 0..n-1]
|  Return #bytes actually read
*/ ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BinRead(file, ByRef data, n=0, offset=0)
{
   h := DllCall("CreateFile","Str",file,"Uint",0x80000000,"Uint",3,"UInt",0,"UInt",3,"Uint",0,"UInt",0)
   IfEqual h,-1, SetEnv, ErrorLevel, -1
   IfNotEqual ErrorLevel,0,Return,0 ; couldn't open the file

   m = 0                            ; seek to offset
   IfLess offset,0, SetEnv,m,2
   r := DllCall("SetFilePointerEx","Uint",h,"Int64",offset,"UInt *",p,"Int",m)
   IfEqual r,0, SetEnv, ErrorLevel, -3
   IfNotEqual ErrorLevel,0, {
      t = %ErrorLevel%              ; save ErrorLevel to be returned
      DllCall("CloseHandle", "Uint", h)
      ErrorLevel = %t%              ; return seek error
      Return 0
   }

   m := DllCall("GetFileSize","UInt",h,"Int64 *",r)
   If (n < 1 or n > m)
       n := m
   Granted := VarSetCapacity(data, n, 0)
   IfLess Granted,%n%, {
      ErrorLevel = Mem=%Granted%
      Return 0
   }

   result := DllCall("ReadFile","UInt",h,"Str",data,"UInt",n,"UInt *",Read,"UInt",0)

   if (!result or Read < n)
       t = -3
   IfNotEqual ErrorLevel,0, SetEnv,t,%ErrorLevel%

   h := DllCall("CloseHandle", "Uint", h)
   IfEqual h,-1, SetEnv, ErrorLevel, -2
   IfNotEqual t,,SetEnv, ErrorLevel, %t%-%ErrorLevel%

   Return Read
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