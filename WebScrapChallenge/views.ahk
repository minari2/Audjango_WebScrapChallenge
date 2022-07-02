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

SessionTestPage1(ByRef req, byRef res)
{
    ; this page is test page for the writing session data.

    Random, rand, 1, 4
    strings := ["Nadure", "Tadure", "Yadure", "Yodure"]
    vars := {"testdata": strings[rand]}

    OutputDebug, % req.session.SaveSession(vars)
    
    template_path := A_ScriptDir . "\WebScrapChallenge\views\"
    body := HTMLBuilder(template_path . "session_test_page_write.html",vars)
    res.SetBodyText(body)
    res.status := 200
}

SessionTestPage2(ByRef req, byRef res)
{
    ; this page is test page for the load session data from request.
    ; OutputDebug, % "get from session data(testdata): " . req.session.sessionData["testdata"]
    vars := {"testdata":req.session.sessionData["testdata"]}
    template_path := A_ScriptDir . "\WebScrapChallenge\views\"
    body := HTMLBuilder(template_path . "session_test_page_load.html",vars)
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

Step1_Page_2(ByRef req, ByRef res) {
    Random, rand, 1, 4
    strings := ["Nadure", "Tadure", "Yadure", "Yodure"]
    
    vars := {"Answer": strings[rand]}
    template_path := A_ScriptDir . "\WebScrapChallenge\views\Step1\"
    body := HTMLBuilder(template_path . "page2.html", vars)
    res.SetBodyText(body)
    res.status := 200
}