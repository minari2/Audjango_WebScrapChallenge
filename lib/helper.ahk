HTMLBuilder(HTMLFilePath, variables)
{
    ; Msgbox,% WebScrapChallengePath
    page := ""
    FileRead, readHTML, HTMLFilePath
    
    ; find > {% base "" %}
    find_base_file_path := RegExMatch(readHTML, "{% base ""(.*)"" %}", base)
    ; Msgbox,% base1
    if base1
        if !FileExist(baseTemplateFolder . base1)
        {
            throw, "base is not exists"
        }
        else
        {
            FileRead, page, % baseTemplateFolder . base1
        }
    
    return 
}