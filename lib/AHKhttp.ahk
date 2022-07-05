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
        ; OutputDebug, % "from handle sessioniD : " . request.session.sessionID
        response := new HttpResponse(request.session.sessionID)
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
        ; OutputDebug, % "StrLen:" . StrLen(text) . "`r`nbDataLength:" . bDataLength

        ; New request or old?
        if (socket.request) {
            ; Get data and append it to the existing request body
            ; socket.request.bytesLeft -= StrLen(text)
            socket.request.bytesLeft -= bDataLength
            socket.request.body := socket.request.body . text

            OutputDebug, % bDataLength . "<< bDataLength, current " . socket.request.size . " total: " . socket.request.headers["Content-Length"]

            p := socket.request.binaryData.getPointer()
            length := socket.request.size
            OutputDebug, % "p :" . p . "`nlength: " length
            
            ; with memory: failed.
            ; DllCall("RtlMoveMemory", "uint", p + length, "uint", &bData, "uint", bDataLength) ; ??

            ; data middleware file
            BinWrite("middleware", bData, , length + bDataLength)

            OutputDebug,% "4 " . data_buffer.length
            ; socket.request.binaryData.Done()
            OutputDebug, 5
            socket.request.size += bDataLength
            OutputDebug, 6
            
            request := socket.request

        } else {
            ; Parse new request
            ; OutputDebug, % bDataLength . " : left Bytes"
            request := new HttpRequest(text, bData, bDataLength)

            length := request.headers["Content-Length"]
            request.bytesLeft := length + 0
            request.size := bDataLength

            request.binaryData := new Buffer(bDataLength)
            request.binaryData.Write(&bData, bDataLength)
            OutputDebug,% "new bina2 " . request.binaryData.length
            ; request.binaryData.Done()

            BinWrite("middleware", bData)

            if (request.body) {
                ; request.bytesLeft -= StrLen(request.body)
                request.bytesLeft -= bDataLength
            }
        }

        if (request.bytesLeft <= 0) {
            request.done := true
        } else {
            socket.request := request
        }


        ; if serving file
        if (request.done || request.IsMultipart()) {
            response := server.Handle(request)
            ; OutputDebug, This is multipart
            if (response.status) {
                socket.SetData(response.Generate())
            }
        }

        if ((request.done && request.boundary) 
            && socket.request.headers["Content-Length"]*1 <= request.size )
        {
            ; all done
            OutputDebug, All request done.
            OutputDebug, % "last request: " . bDataLength . " request.size :" . request.size

            ; request.find_binary_data_from_body(request.binaryData, "--" . request.boundary, request.size)
            binFile := FileOpen("middleware", "r")
            binFile.RawRead(rawData, request.size)
            request.find_binary_data_from_body(rawData, "--" . request.boundary, request.size)

            response := server.Handle(request)
            if (response.status) {
                socket.SetData(response.Generate())
            }
            OutputDebug, tttt here??
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
    __New(data = "", bData = "", bDataLength="") {
        if (data)
            ; OutputDebug, % data
            this.bData := bData
            this.bDataLength := bDataLength
            this.isitmultipart := false
            this.Parse(data)
            this.cookie := this.cut_cookie(this.headers["cookie"])
            this.session := New SessionManager(this.cookie["__sessionID"])
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

        this.headers_raw := data[1]
        this.headers_length := StrLen(data[1])

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
            ; this.dataCollection := this.CollectData(this.body, this.boundary)
            ; this.find_binary_data_from_body(this.bdata, "--" . boundary1, this.bDataLength)

        }
    }

    cut_cookie(cookie_raw)
    {
        cutCookie := Array()
        Cookies := cookie_raw
        Cookie := StrSplit(Cookies, ";" . A_Space)
        for k, v in Cookie
        {
            ; key     value
            ; nadure=Tadure
            splited := StrSplit(v, "=")
            cutCookie[splited[1]] := splited[2]
        }
        return cutCookie
    }

    find_binary_data_from_body(raw_data, boundary, bDataLength)
    {
        OutputDebug, find_binary_data_from_body, length %bDataLength% Data text
        
        boundaries := []
        data := []

        Loop,% bDataLength - StrLen(boundary) + 4
        {
            tt := A_Index
            
            try
            {
                ; OutputDebug, % StrGet(&raw_data + A_Index, StrLen(boundary))
                if((StrGet(&raw_data + A_Index, StrLen(boundary), "UTF-8") = boundary))
                    ; or (StrGet(&raw_data + A_Index, StrLen(boundary) + 2, "UTF-8") = boundary . "--")
                {
                    ; OutputDebug, % StrGet(&raw_data + A_Index, StrLen(boundary), "UTF-8")
                    OutputDebug, % "boundaries: " . A_Index
                    boundaries.Push(A_Index)
                }
                ; else
            }
            Catch e
            {
                OutputDebug, % A_index . " error occurs"
            }
        }

        boundaries.Push(bDataLength - (StrLen(boundary) +2))
        OutputDebug, boudaries done %tt%

        data_collection := []
        for k, v in boundaries
        {
            OutputDebug, % k . " : boundary " . v
        }
        
        for k, v in boundaries
        {
            if(boundaries[k+1])
            {   
                data_array := Array()
                
                offset := &raw_data + v + 2 + StrLen(boundary) ; 2 = `r`n length
                data_end := boundaries[k+1] - boundaries[k] - StrLen(boundary) - 4
                
                find_str := "`r`n`r`n"
                Loop,% boundaries[k+1] - boundaries[k]
                {
                    ; found_position := offset + A_Index
                    if(StrGet(offset + A_Index, StrLen(find_str), "UTF-8") = find_str)
                    {
                        found_pos := A_Index
                        binary_data_start := offset + found_pos + 4
                        data_header := StrGet(offset, A_Index, "UTF-8")
                        ; OutputDebug, % data_header
                        aa := regexmatch(data_header
                            , "O)name=""(?<name>.*)""; filename=""(?<filename>.*)""", _)
                        
                        if(not _["name"])
                            aa := regexmatch(data_header
                            , "O)name=""(?<name>.*)""", _)

                        aa := regexmatch(data_header
                            , "O)Content-Type: (?<type>.*)", __)
                        break
                    }
                }

                OutputDebug, % _["name"] . "`n" . _["filename"]

                data_size := (boundaries[k+1] - boundaries[k] - StrLen(boundary) - 4) - found_pos - 4

                data_array["name"] := _["name"]
                data_array["filename"] := _["filename"]
                
                data_array["type"] := __["type"]


                if(not data_array["type"])
                {
                    OutputDebug, "this is str type"
                    data_array["data"] := StrGet(offset + found_pos + 4, data_size, "UTF-8")
                }
                else
                {
                    OutputDebug, "this is not str type"
                    VarSetCapacity(buff, data_size, 0)
                    OutputDebug, aaaa
                    DllCall("RtlMoveMemory", "Ptr", &buff, "Ptr", 
                    , "Ptr", data_size)
                    OutputDebug, bbbb
                    ; data_array["data"] := buff
                    
                    loop ; save file
                    {
                        OutputDebug, "save"
                        Random, random_seed, 1, 1000
                        if !fileExist(A_ScriptDir . "\temp\" . random_seed . "\" . data_array["filename"])
                        {
                            file_path := A_ScriptDir . "\temp\" . random_seed . "\" . data_array["filename"]
                            data_array["file_path"] := file_path
                            FileCreateDir, % A_ScriptDir . "\temp\" . random_seed
                            BinWrite(file_path, buff)
                            break
                        }
                    }

                }

                
                BinWrite(v . ".txt", buff)

                data.Push(data_array)
            }
            else
            {
                OutputDebug, % boundaries[k+1] . " why?`n " . k
            }
        }
        return data
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
    __New(sessionID="") {
        this.headers := {}
        this.status := 0
        this.protocol := "HTTP/1.1"
        this.sessionID := sessionID

        this.SetBodyText("")
    }

    Generate() {
        FormatTime, date,, ddd, d MMM yyyy HH:mm:ss
        this.headers["Date"] := date

        headers := this.protocol . " " . this.status . "`r`n"
        for key, value in this.headers {
            headers := headers . key . ": " . value . "`r`n"
        }

        headers .= "Set-Cookie: __sessionID=" . this.sessionID . "`r`n"

        ; cookie_accept_test := "Set-Cookie: nadure=Tadure`r`n" ; additional custom cookie for test
        ; headers .= cookie_accept_test

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

BinWrite(file, ByRef data, n=0, offset=0)
{
   ; Open file for WRITE (0x40..), OPEN_ALWAYS (4): creates only if it does not exists
   h := DllCall("CreateFile","str",file,"Uint",0x40000000,"Uint",0,"UInt",0,"UInt",4,"Uint",0,"UInt",0)
   IfEqual h,-1, SetEnv, ErrorLevel, -1
   IfNotEqual ErrorLevel,0,Return,0 ; couldn't create the file

   m = 0                            ; seek to offset
   IfLess offset,0, SetEnv,m,2
   r := DllCall("SetFilePointerEx","Uint",h,"Int64",offset,"UInt *",p,"Int",m)
   IfEqual r,0, SetEnv, ErrorLevel, -3
   IfNotEqual ErrorLevel,0, {
      t = %ErrorLevel%              ; save ErrorLevel to be returned
      DllCall("CloseHandle", "Uint", h)
      ErrorLevel = %t%              ; return seek error
      Return 0
   }

   m := VarSetCapacity(data)        ; get the capacity ( >= used length )
   If (n < 1 or n > m)
       n := m
   result := DllCall("WriteFile","UInt",h,"Str",data,"UInt",n,"UInt *",Written,"UInt",0)
   if (!result or Written < n)
       ErrorLevel = -3
   IfNotEqual ErrorLevel,0, SetEnv,t,%ErrorLevel%

   h := DllCall("CloseHandle", "Uint", h)
   IfEqual h,-1, SetEnv, ErrorLevel, -2
   IfNotEqual t,,SetEnv, ErrorLevel, %t%-%ErrorLevel%

   Return Written
}

class SessionManager
{
    ; value means sessionID
    __New(value="")
    {
        this.sessionDir := A_ScriptDir . "\session"
        IfNotExist,% this.sessionDir
            FileCreateDir,% this.sessionDir
        
        ; Check Session
        if(value)
        {
            ; check if exists session file
            this.sessionFilePath := this.sessionDir . "\" . value
            if(FileExist(this.sessionFilePath))
            {
                ; session exist
                FileRead, sessionText, % this.sessionFilePath
                this.sessionData := Json.Load(sessionText)
                this.sessionID := value
                return this
            }
        }
        else
        {
            this.SaveSession()
            return this
        }
    }

    SaveSession(data="")
    {
        ; make session
        ; this.sessionData := Array()

        if(!data)
            data := Array()
        this.sessionData := data
        sessionDatatxt := Json.Dump(data)
        ; OutputDebug, % "from SaveSession. " . sessionDatatxt
        ; this.sessionId := this.CreateUUID()
        this.sessionFilePath := this.sessionDir . "\" . this.sessionId
        FileDelete, % this.sessionfilePath
        FileAppend, %sessionDatatxt%, % this.sessionFilePath
        return this.sessionId
    }

    SaveSessionData(data="")
    {

    }

    ; sessionData {
    ;     get {
    ;         return this.sessionData
    ;     }
    ; }

    CreateUUID()
    {
        VarSetCapacity(puuid, 16, 0)
        if !(DllCall("rpcrt4.dll\UuidCreate", "ptr", &puuid))
            if !(DllCall("rpcrt4.dll\UuidToString", "ptr", &puuid, "uint*", suuid))
                return StrGet(suuid), DllCall("rpcrt4.dll\RpcStringFree", "uint*", suuid)
        return ""
    }
    
}
