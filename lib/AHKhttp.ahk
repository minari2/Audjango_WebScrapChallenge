class Uri
{
    Decode(str) {
        Loop
            If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
                StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
            Else Break
        Return, str
    }

    Encode(str) {
        f = %A_FormatInteger%
        SetFormat, Integer, Hex
        If RegExMatch(str, "^\w+:/{0,2}", pr)
            StringTrimLeft, str, str, StrLen(pr)
        StringReplace, str, str, `%, `%25, All
        Loop
            If RegExMatch(str, "i)[^\w\.~%]", char)
                StringReplace, str, str, %char%, % "%" . Asc(char), All
            Else Break
        SetFormat, Integer, %f%
        Return, pr . str
    }
}

class HttpServer
{
    static servers := {}

    LoadMimes(file) {
        if (!FileExist(file))
            return false

        FileRead, data, % file
        types := StrSplit(data, "`n")
        this.mimes := {}
        for i, data in types {
            info := StrSplit(data, " ")
            type := info.Remove(1)
            ; Seperates type of content and file types
            info := StrSplit(LTrim(SubStr(data, StrLen(type) + 1)), " ")

            for i, ext in info {
                this.mimes[ext] := type
            }
        }
        return true
    }

    GetMimeType(file) {
        default := "text/plain"
        if (!this.mimes)
            return default

        SplitPath, file,,, ext
        type := this.mimes[ext]
        if (!type)
            return default
        return type
    }

    ServeFile(ByRef response, file) {
        f := FileOpen(file, "r")
        length := f.RawRead(data, f.Length)
        f.Close()

        response.SetBody(data, length)
        res.headers["Content-Type"] := this.GetMimeType(file)
    }

    SetPaths(paths) {
        this.paths := paths
    }

    Handle(ByRef request) {
        response := new HttpResponse()
        if (!this.paths[request.path]) {
            func := this.paths["404"]
            response.status := 404
            if (func)
                func.(request, response, this)
            return response
        } else {
            this.paths[request.path].(request, response, this)
        }
        return response
    }

    Serve(port) {
        this.port := port
        HttpServer.servers[port] := this

        AHKsock_Listen(port, "HttpHandler")
    }
}

HttpHandler(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
    static sockets := {}

    if (!sockets[iSocket]) {
        sockets[iSocket] := new Socket(iSocket)
        AHKsock_SockOpt(iSocket, "SO_KEEPALIVE", true)
    }
    socket := sockets[iSocket]

    if (sEvent == "DISCONNECTED") {
        socket.request := false
        sockets[iSocket] := false
    } else if (sEvent == "SEND") {
        if (socket.TrySend()) {
            socket.Close()
        }

    } else if (sEvent == "RECEIVED") {
        server := HttpServer.servers[sPort]

        text := StrGet(&bData, "UTF-8")

        ; New request or old?
        if (socket.request) {
            ; Get data and append it to the existing request body
            socket.request.bytesLeft -= StrLen(text)
            socket.request.body := socket.request.body . text
            request := socket.request
        } else {
            ; Parse new request
            request := new HttpRequest(text)

            length := request.headers["Content-Length"]
            request.bytesLeft := length + 0

            if (request.body) {
                request.bytesLeft -= StrLen(request.body)
            }
        }

        if (request.bytesLeft <= 0) {
            request.done := true
        } else {
            socket.request := request
        }

        if (request.done || request.IsMultipart()) {
            response := server.Handle(request)
            if (response.status) {
                socket.SetData(response.Generate())
            }
        }

        if (request.done || request.boundary)
        {
            response := server.Handle(request)
            if (response.status) {

                ; info := {"name" : _["name"]
                ; , "filename" : _["filename"]
                ; , "Content-Type" : Content_Type_line[2]
                ; , "data" : data}
                ; OutputDebug, % this.dataCollection.MaxIndex()
                ; OutputDebug, % request.boundary
                for k, fileData in this.dataCollection
                {
                    OutputDebug, % k . "asdfa"
                    if(not fileData["Content-Type"])
                        continue
                    ; OutputDebug,% "asdfasdfasd" . fileData["filename"]

                    data := NumGet(ComObjValue(fileData["data"]) + 8 + A_PtrSize, "UInt")
                    size := fileData["data"].MaxIndex() + 1
                    f := FileOpen(fileData["filename"], "w")
                    f.RawWrite(data + 0, size)
                    f.Close()
                }
                socket.SetData(response.Generate())
            }
        }

        if (socket.TrySend()) {
            if (!request.IsMultipart() || request.done) {
                socket.Close()
            }
        }    

    }
}

class HttpRequest
{
    __New(data = "") {
        if (data)
            this.Parse(data)
            this.isitmultipart := false
    }

    GetPathInfo(top) {
        results := []
        while (pos := InStr(top, " ")) {
            results.Insert(SubStr(top, 1, pos - 1))
            top := SubStr(top, pos + 1)
        }
        this.method := results[1]
        this.path := Uri.Decode(results[2])
        this.protocol := top
    }

    GetQuery() {
        pos := InStr(this.path, "?")
        query := StrSplit(SubStr(this.path, pos + 1), "&")
        if (pos)
            this.path := SubStr(this.path, 1, pos - 1)

        this.queries := {}
        for i, value in query {
            pos := InStr(value, "=")
            key := SubStr(value, 1, pos - 1)
            val := SubStr(value, pos + 1)
            this.queries[key] := val
        }
    }

    Parse(data) {
        this.raw := data
        ; OutputDebug, % this.raw
        data := StrSplit(data, "`n`r")
        headers := StrSplit(data[1], "`n")
        this.body := LTrim(data[2], "`n")

        if (this.body != "" and data.MaxIndex() > 2)
        {
            this.body := ""
            for k, v in data
            {
                if(k=1)
                    continue
                ; OutputDebug,% v
                this.body .= v
            }
        }

        this.GetPathInfo(headers.Remove(1))
        this.GetQuery()
        this.headers := {}

        for i, line in headers {
            pos := InStr(line, ":")
            key := SubStr(line, 1, pos - 1)
            val := Trim(SubStr(line, pos + 1), "`n`r ")

            this.headers[key] := val
        }

        regexmatch(this.headers["Content-Type"], "boundary=(.*)", boundary)
        ; OutputDebug, % boundary1

        if(boundary)
        {
            this.boundary := boundary1
            this.dataCollection := this.CollectData(this.body, this.boundary)
            ; OutputDebug, % this.boundary
            ; OutputDebug, % this.body

        }
    }

    CollectData(body, boundary) {
        t := StrSplit(body, "--" . boundary, "`n")

        data_collection := []

        for k, content in t
        {
            content := StrReplace(content, "`n", "", , 1)
            ; OutputDebug, % content

            content_data := StrSplit(content, "`n")
            if(StrLen(content_data[1]) < 4)
            {
                continue
            }

            Content_disposition_length := StrLen(content_data[1])
            aa := regexmatch(content_data[1]
                , "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)
            
            if(not _["name"])
                aa := regexmatch(content_data[1]
                , "O)name=""(?<name>.*)""", _)

            Content_Type_length := StrLen(content_data[2])
            c_length := Content_disposition_length + Content_Type_length + 3
            data := SubStr(content, c_length, StrLen(content) - c_length)

            Disposition := StrSplit(content_data[1], ":")
            Content_Type_line := StrSplit(content_data[2], ": ")

            ; OutputDebug, % _["filename"] . ":`n" . _["name"] . "`nk:" . k . "()" . StrLen(content_data[1])
            ; OutputDebug,% data
            info := {"name" : _["name"]
                , "filename" : _["filename"]
                , "Content-Type" : Content_Type_line[2]
                , "data" : data}
            data_collection.push(info)
        }
        ; OutputDebug, % data_collection.MaxIndex() . "max_index"

        ; not works when binary file.
        for k, fileData in data_collection
        {
            if(not fileData["Content-Type"])
                continue
            data := fileData["data"]

            loop
            {
                Random, random_seed, 1, 1000
                if !fileExist(A_ScriptDir . "\temp\" . random_seed . "\" . fileData["filename"])
                {
                    file_path := A_ScriptDir . "\temp\" . random_seed . "\" . fileData["filename"]
                    data_collection[k]["file_path"] := file_path
                    FileCreateDir, % A_ScriptDir . "\temp\" . random_seed
                    break
                }
            }
            
            f := FileOpen(file_path, "w")
            f.Write(data)
            f.Close()
        }

        return data_collection
    }

    IsMultipart() {
        length := this.headers["Content-Length"]
        expect := this.headers["Expect"]


        if (expect = "100-continue" && length > 0)
            return true
        ; OutputDebug,% "Expect:" . expect
        return false
    }
}

class HttpResponse
{
    __New() {
        this.headers := {}
        this.status := 0
        this.protocol := "HTTP/1.1"

        this.SetBodyText("")
    }

    Generate() {
        FormatTime, date,, ddd, d MMM yyyy HH:mm:ss
        this.headers["Date"] := date

        headers := this.protocol . " " . this.status . "`r`n"
        for key, value in this.headers {
            headers := headers . key . ": " . value . "`r`n"
        }
        headers := headers . "`r`n"
        length := this.headers["Content-Length"]

        buffer := new Buffer((StrLen(headers) * 2) + length)
        buffer.WriteStr(headers)

        buffer.Append(this.body)
        buffer.Done()

        return buffer
    }

    SetBody(ByRef body, length) {
        this.body := new Buffer(length)
        this.body.Write(&body, length)
        this.headers["Content-Length"] := length
    }

    SetBodyText(text) {
        this.body := Buffer.FromString(text)
        this.headers["Content-Length"] := this.body.length
    }


}

class Socket
{
    __New(socket) {
        this.socket := socket
    }

    Close(timeout = 5000) {
        AHKsock_Close(this.socket, timeout)
    }

    SetData(data) {
        this.data := data
    }

    TrySend() {
        if (!this.data || this.data == "")
            return false

        p := this.data.GetPointer()
        length := this.data.length

        this.dataSent := 0
        loop {
            if ((i := AHKsock_Send(this.socket, p, length - this.dataSent)) < 0) {
                if (i == -2) {
                    return
                } else {
                    ; Failed to send
                    return
                }
            }

            if (i < length - this.dataSent) {
                this.dataSent += i
            } else {
                break
            }
        }
        this.dataSent := 0
        this.data := ""

        return true
    }
}

class Buffer
{
    __New(len) {
        this.SetCapacity("buffer", len)
        this.length := 0
    }

    FromString(str, encoding = "UTF-8") {
        length := Buffer.GetStrSize(str, encoding)
        buffer := new Buffer(length)
        buffer.WriteStr(str)
        return buffer
    }

    GetStrSize(str, encoding = "UTF-8") {
        encodingSize := ((encoding="utf-16" || encoding="cp1200") ? 2 : 1)
        ; length of string, minus null char
        return StrPut(str, encoding) * encodingSize - encodingSize
    }

    WriteStr(str, encoding = "UTF-8") {
        length := this.GetStrSize(str, encoding)
        VarSetCapacity(text, length)
        StrPut(str, &text, encoding)

        this.Write(&text, length)
        return length
    }

    ; data is a pointer to the data
    Write(data, length) {
        p := this.GetPointer()
        DllCall("RtlMoveMemory", "uint", p + this.length, "uint", data, "uint", length)
        this.length += length
    }

    Append(ByRef buffer) {
        destP := this.GetPointer()
        sourceP := buffer.GetPointer()

        DllCall("RtlMoveMemory", "uint", destP + this.length, "uint", sourceP, "uint", buffer.length)
        this.length += buffer.length
    }

    GetPointer() {
        return this.GetAddress("buffer")
    }

    Done() {
        this.SetCapacity("buffer", this.length)
    }
}
