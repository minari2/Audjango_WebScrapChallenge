#include %A_ScriptDir%\WebScrapChallenge\views.ahk
urls := {}

urls["/applicationURLTest"] := Func("HelloWorld")
urls["/test2"] := Func("TestPage")
urls["/"] := Func("HomePage")