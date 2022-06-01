HTMLBuilder(HTMLFilePath, variables)
{
    page := ""
    FileRead, readHTML, *t %HTMLFilePath%
    RegExMatch(readHTML, "{% base ""(.*)"" %}", base)
    ; build page
    if base1
        if !FileExist(baseTemplateFolder . base1)
        {
            throw, "base is not exists"
        }
        else
        {
            FileRead, page, % "*t " . baseTemplateFolder . base1
            page_backup := page
            loop, parse, page_backup, `n, `r
            {
                if RegExMatch(A_LoopField, "{% block (.*) %}", blocks)
                {
                    tt := RegExMatch(readHTML, "{% block " . blocks1 . " %}(.*){% endblock " . blocks1 . " %}", found)
                    if found1
                    {
                        page := Regexreplace(page, "{% block " . blocks1 . " %}(.*){% endblock " . blocks1 . " %}", found1)    
                    }
                    else
                    {
                        page := Regexreplace(page, "{% block " . blocks1 . " %}(.*){% endblock " . blocks1 . " %}", "")    
                    }
                }
                
            }
        }
    else
    {
        page := readHTML
    }

    ; Msgbox, % page
  
    loop, parse, page, `n, `r
    {
        if RegExMatch(A_LoopField, "{{ (.*?) }}", var)
        {
            if(var1)
            {   
                if variables[var1]
                {    
                    page := Regexreplace(page, "{{ " . var1 . " }}", variables[var1])
                }
                else
                {
                    page := Regexreplace(page, "{{ " . var1 . " }}", "")
                }
            }
        }
    }
    
    
    return page
}