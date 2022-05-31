HelloWorld(ByRef req, ByRef res) {
    res.SetBodyText("Hello World")
    res.status := 200
}

HomePage(ByRef req, ByRef res) {
    vars := {"test":"ttttttttttttt"}
    HTMLBuilder("test_page.html",vars)
    res.SetBodyText("Hello Home")
    res.status := 200
}