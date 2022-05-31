
; string1 := "$100 blah blah HELLO blah WORLD" 
; string2 := "$100 blah blah HELLO blah SHOE" 
; string3 := "$100 blah blah FOO blah BAR" 

; regex := "^(?=.*HELLO)(?=.*WORLD)(\$\d+).*?|\b(\w+?)$"

; Loop, 3
; {
; 	RegExMatch(string%A_Index%, regex, match)
; 	extracted := match1 . match2
; 	MsgBox %extracted%
; }

example := "{% base ""testsetset"" %}"
example = 
(
{`% block ttt `%}
yeapssss!!jkljakldsf
dsfzsdfzsdzzz

zsdfz

{`% endblock ttt `%}

{`% block ttt1 `%}
yeapssss!!2222
zsdfzsdf

ddd

{`% endblock ttt1 `%}

)
; Msgbox,% example

block_list := []

loop, parse, example, `n, `r
{
    if RegExMatch(A_LoopField, "{% block (.*) %}", blocks)
        {
            block_list.Push(blocks1)
        }
}

for k, v in block_list
{
    tt := RegExMatch(example, "{% block " . v . " %}(.*){% endblock " . v . " %}", base)
    Msgbox,% base1
}

; find_include_file_path := RegExMatch(example, "{`% block ttt `%}(.*){`% endblock ttt `%}", base)
; Msgbox,% base1
; Msgbox,% base

; find_blocks := RegExMatch(example, "{% block (.*) `%}`r`n", blocks)
; Msgbox,% blocks1
; loop, %find_blocks%
; {
;     Msgbox,% blocks[A_Index]
; }
; find_include_file_path := RegExMatch(example, "{`% block ttt `%}(.*){`% endblock ttt `%}", base)
; ; Msgbox,% base1
; ; Msgbox,% base