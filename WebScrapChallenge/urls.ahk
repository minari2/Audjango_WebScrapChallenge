#include %A_ScriptDir%\WebScrapChallenge\views.ahk
urls := {}

urls["/applicationURLTest"] := Func("HelloWorld")
urls["/test2"] := Func("TestPage")
urls["/"] := Func("HomePage")

; Step1.
urls["/step1/1"] := Func("Step1_Page_1")
