local uv = require("uv")
local wrapRead = require("coro-channel").wrapRead
local http = require("coro-http")

local script = "main.lua"
local webhookURL = "URL_HERE"
local lastTimeWebhookSent = 0
local logBuffer = {}
local maxLines = 30
local lastMemUsage = 0

local maxMemory = 3400

local ansiColors = {
	black = 30,
	red = 31,
	green = 32,
	yellow = 33,
	blue = 34,
	purple = 35,
	cyan = 36,
	white = 37
}

local function timestamp(ts)
    ts = ts or os.time()
    return os.date("%x @ %I:%M:%S%p", ts)
end

local function prettyLog(name, color, text)
	return print(timestamp() .. "   \27[" .. ansiColors[color] .. "m\27[1m" .. name .. "\27[0m" .. string.rep(" ", 8 - name:len()) .. " " .. text)
end

local function log(text)
    prettyLog("SPYDUCK", "white", text)
end

local function sendToDiscord(logLines)
    if os.time() - lastTimeWebhookSent < 10 then
        return log("Not sending webhook due to 10 second cooldown")
    end

    lastTimeWebhookSent = os.time()

    local logContent = table.concat(logLines, "")
    logContent = logContent .. "\n\n[WATCHDUCK] Last recorded memory usage: "
        .. tostring(lastMemUsage) .. "MB (limit " .. tostring(maxMemory) .. "MB)\n"

    local boundary = "----LuvitBoundary" .. os.time()
    local body = "--" .. boundary .. "\r\n" ..
        'Content-Disposition: form-data; name="file"; filename="crash_log.txt"\r\n' ..
        "Content-Type: text/plain\r\n\r\n" ..
        logContent .. "\r\n--" .. boundary .. "--\r\n"

    local headers = {
        {"Content-Type", "multipart/form-data; boundary=" .. boundary},
        {"Content-Length", tostring(#body)}
    }

    coroutine.wrap(function()
        local ok, res, _ = pcall(http.request, "POST", webhookURL, headers, body)
        if ok then
            log("Sent crash report to Discord. Response code: " .. res.code)
        else
            log("http.request to Discord returned not ok")
        end
    end)()
end

local function startProcess()
    print("[WATCHDUCK] Starting " .. script)

    local memTimer = uv.new_timer()
    local lastLog = os.time()

    local stdoutPipe = uv.new_pipe(false)
    local stderrPipe = uv.new_pipe(false)

    local handle, pid
    handle, pid = uv.spawn("./luvit", {
        args = {script},
        stdio = {nil, stdoutPipe, stderrPipe}
    }, function(code, signal)
        log("Process exited with code: " .. code .. " signal: " .. signal)

        sendToDiscord(logBuffer)
        logBuffer = {}

        memTimer:stop()
        memTimer:close()

        pcall(function() stdoutPipe:close() end)
        pcall(function() stderrPipe:close() end)
        pcall(function() handle:close() end)

        uv.sleep(100)
        startProcess()
    end)

    local function readStream(pipe)
        local reader = wrapRead(pipe)
        for chunk in reader do
            for line in chunk:gmatch("[^\r\n]+") do
                local lineWithNewline = line .. "\n"
                table.insert(logBuffer, lineWithNewline)
                if #logBuffer > maxLines then table.remove(logBuffer, 1) end
                io.write(lineWithNewline)
            end
        end
    end

    coroutine.wrap(readStream)(stdoutPipe)
    coroutine.wrap(readStream)(stderrPipe)

    memTimer:start(350, 350, function()
        local f = io.popen("ps -o rss= -p " .. pid)
        if not f then return end

        local rss
        local pcall_status, result = pcall(function()
            rss = f:read("*n") or 0
            f:close()
        end)

        if not pcall_status then
            f:close()
            return
        end

        local memMB = math.floor(rss / 1024)
        lastMemUsage = memMB

        if os.time() - lastLog > 10 then
            prettyLog("SPYDUCK", "yellow", "Current memory usage: " .. memMB .. "MB / " .. maxMemory .. "MB")
            lastLog = os.time()
        end

        if memMB > maxMemory then
            prettyLog("SPYDUCK", "red", "Memory limit exceeded: " .. memMB .. "MB > " .. maxMemory .. "MB, killing process...")
            handle:kill("sigterm")
        end
    end)

end

startProcess()
uv.run()
