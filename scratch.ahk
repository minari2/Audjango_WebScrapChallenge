
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