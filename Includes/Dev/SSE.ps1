
$Body = @{ 
    title = "foo"
    body = "bar"
    userId = 1
}

# The ContentType will automatically be set to application/x-www-form-urlencoded for
# all POST requests, unless specified otherwise.
$Params = @{ 
    Method = "Put"
    Uri = "http://localhost:3999/"
    Body = $JsonBody
    ContentType = "text/event-stream"
    Headers = @{ 
        "Connection" = "keep-alive"
        "Cache-Control" = "no-cache"
    }
}

$Result = Invoke-RestMethod @Params

Start-Sleep -Seconds 0