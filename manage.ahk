#Persistent
#SingleInstance, force
SetBatchLines, -1
; #Include AHKhttp.ahk
#Include %A_SCriptDir%\MyFileInstallScript.ahk
#include <AHKhttp>
#include <AHKsock>
#include <helper>
#Include %A_ScriptDir%\config\settings.ahk

; 
; When Compile for release > 
; 1. Launch fileinstallhelper.ahk
; 2. Compile
; 

; paths := {}
; paths["/"] := Func("HelloWorld")
; paths["/logo"] := Func("Logo")


paths := {}
for k, v in AuDjangoApplication
{
    for i, j in v
    {
        for l,m in j
        {
            paths[l] := m
        }
    }
}
paths["404"] := Func("NotFound")

server := new HttpServer()
server.LoadMimes(A_ScriptDir . "/mime.types")
server.SetPaths(paths)
server.Serve(8000)
return

; Logo(ByRef req, ByRef res, ByRef server) {
;     server.ServeFile(res, A_ScriptDir . "/logo.png")
;     res.status := 200
; }

NotFound(ByRef req, ByRef res) {
    res.SetBodyText("Page not found")
}

; HelloWorld(ByRef req, ByRef res) {
;     res.SetBodyText("Hello World")
;     res.status := 200
; }


