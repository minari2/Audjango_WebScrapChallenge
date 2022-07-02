#include %A_ScriptDir%\WebScrapChallenge\views.ahk
urls := {}

urls["/"] := Func("HomePage")
urls["/applicationURLTest"] := Func("HelloWorld")
urls["/test2"] := Func("TestPage")
urls["/sessionTest1"] := Func("SessionTestPage1")
urls["/sessionTest2"] := Func("SessionTestPage2")

; Step1.
urls["/step1/1"] := Func("Step1_Page_1")
urls["/step1/2"] := Func("Step1_Page_2")
