HelloWorld(ByRef req, ByRef res) {
    res.SetBodyText("Hello World")
    res.status := 200
}

TestPage(ByRef req, ByRef res) {
    vars := {"title":"tttttttttitle"}
    template_path := A_ScriptDir . "\WebScrapChallenge\views\"
    body := HTMLBuilder(template_path . "test_page.html",vars)
    ; Msgbox,% body
    res.SetBodyText(body)
    res.status := 200
}

HomePage(ByRef req, ByRef res) {
    vars := {"title":"tttttttttitle"}
    template_path := A_ScriptDir . "\WebScrapChallenge\views\"
    body := HTMLBuilder(template_path . "index.html",vars)
    ; Msgbox,% body
    res.SetBodyText(body)
    res.status := 200
}


Step1_Page_1(ByRef req, ByRef res) {
    template_path := A_ScriptDir . "\WebScrapChallenge\views\Step1\"
    body := HTMLBuilder(template_path . "page1.html", vars)
    res.SetBodyText(body)
    res.status := 200
}