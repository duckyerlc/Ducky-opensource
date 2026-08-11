local netConnect = require('coro-net').connect
local coroWrapper = require('coro-wrapper')
local codec = require('postgres-codec')
local md5 = require('md5').sumhexa
local mutexWrapper = require('mutex-wrapper')
local bit = require('bit')

local concat = table.concat
local sbyte = string.byte

local originalDecode = codec.decode
local encoders = codec.encoders

local char = string.char
local band = bit.band
local rshift = bit.rshift

local function writeUint16(int)
  return char(band(rshift(int, 8), 0xff), band(int, 0xff))
end

local function writeUint32(int)
  return char(
    band(rshift(int, 24), 0xff),
    band(rshift(int, 16), 0xff),
    band(rshift(int, 8), 0xff),
    band(int, 0xff)
  )
end

local function writeUint32List(list)
  local parts = {}
  for i = 1, #list do
    parts[i] = writeUint32(list[i])
  end
  return concat(parts)
end

local function writeCstring(s)
  return s .. "\0"
end

local function frame(header, body)
  return header .. writeUint32(#body + 4) .. body
end

function encoders.Parse(name, query, var_types)
  assert(type(name) == "string")
  assert(type(query) == "string")
  assert(type(var_types) == "table")
  return frame('P',
    writeCstring(name) ..
    writeCstring(query) ..
    writeUint16(#var_types) ..
    writeUint32List(var_types)
  )
end

local function readUint32(s, i)
  return bit.bor(
    bit.lshift(sbyte(s, i), 24),
    bit.lshift(sbyte(s, i + 1), 16),
    bit.lshift(sbyte(s, i + 2), 8),
    sbyte(s, i + 3)
  ), i + 4
end

local extraMessageTypes = {
  [sbyte('1')] = 'ParseComplete',
  [sbyte('n')] = 'NoData',
  [sbyte('3')] = 'CloseComplete',
}

local function decode(buffer, index)
  local length = #buffer
  if length - index < 4 then return end

  local len = readUint32(buffer, index + 1)
  if length < index + len then return end

  local msgByte = sbyte(buffer, index)
  local extraType = extraMessageTypes[msgByte]

  if extraType then
    return {extraType}, index + 1 + len
  end

  return originalDecode(buffer, index)
end

local function formatError(msg)
  return string.format(
    "%s: %s %s:%s (%s) - %s",
    msg.S or "?", msg.F or "?", msg.L or "?",
    msg.C or "?", msg.R or "?", msg.M or "?"
  )
end

local function wrap(options, read, write, socket)
  assert(options.username, "options.username is required")
  assert(options.database, "options.database is required")

  write = mutexWrapper()(write)
  socket:nodelay(true)

  read  = coroWrapper.decoder(read, decode)
  write = coroWrapper.encoder(write, codec.encode)

  write {'StartupMessage', {
    user     = options.username,
    database = options.database,
  }}

  while true do
    local message = read()
    if not message then
      error("pg: connection closed during authentication")
    end
    if message[1] == 'AuthenticationOk' then
      break
    elseif message[1] == 'AuthenticationMD5Password' then
      assert(options.password, "pg: password required for MD5 auth")
      local salt  = message[2]
      local inner = md5(options.password .. options.username)
      write {'PasswordMessage', 'md5' .. md5(inner .. salt)}
    elseif message[1] == 'AuthenticationCleartextPassword' then
      assert(options.password, "pg: password required")
      write {'PasswordMessage', options.password}
    elseif message[1] == 'ErrorResponse' then
      error("pg auth: " .. formatError(message[2]))
    else
      error("pg: unexpected auth message: " .. message[1])
    end
  end

  local params = {}
  while true do
    local message = read()
    if not message then
      error("pg: connection closed during startup")
    end
    if message[1] == 'ReadyForQuery' then
      break
    elseif message[1] == 'ParameterStatus' then
      params[message[2][1]] = message[2][2]
    elseif message[1] == 'BackendKeyData' then
      params.backend_key_data = { pid = message[2], secret = message[3] }
    elseif message[1] == 'ErrorResponse' then
      error("pg startup: " .. formatError(message[2]))
    end
  end

  local waiting

  coroutine.wrap(function()
    local description, rows, summary

    for message in read do
      local tag = message[1]

      if tag == "ErrorResponse" then
        if waiting then
          local t
          t, waiting = waiting, nil
          assert(coroutine.resume(t, nil, formatError(message[2]), message[2]))
        else
          print("[pg] unhandled ErrorResponse: " .. formatError(message[2]))
        end

      elseif tag == "RowDescription" then
        description = message[2]
        rows = {}

      elseif tag == 'BindCompletion'
          or tag == 'ParseComplete'
          or tag == 'CloseComplete' then

      elseif tag == 'NoData' then
        description = nil
        rows = nil

      elseif tag == "NoticeResponse" then

      elseif tag == "DataRow" then
        if rows and description then
          local row = {}
          rows[#rows + 1] = row
          for i = 1, #description do
            local col   = description[i]
            local value = message[2][i]
            if value ~= nil then
              local tid = col.typeId
              if tid == 16 then
                value = value == "t"
              elseif tid == 20 or tid == 21 or tid == 23
                  or tid == 26
                  or tid == 700 or tid == 701 then
                value = tonumber(value)
              end
            end
            row[col.field] = value
          end
        end

      elseif tag == "CommandComplete" then
        summary = message[2]

      elseif tag == "ReadyForQuery" and waiting then
        local t, r, d, s
        t, waiting       = waiting, nil
        r, rows          = rows, nil
        d, description   = description, nil
        s, summary       = summary, nil
        assert(coroutine.resume(t, {
          rows        = r or {},
          description = d,
          summary     = s,
        }))
      end
    end

    if waiting then
      local t
      t, waiting = waiting, nil
      coroutine.resume(t, nil, "pg: connection closed")
    end
  end)()

  local function query(sql)
    write {'Query', sql}
    waiting = coroutine.running()
    return coroutine.yield()
  end

  local function queryParams(sql, params)
    params = params or {}

    local bindMsg = {'Bind', '', ''}
    for i = 1, #params do
      local v = params[i]
      if v ~= nil then
        bindMsg[i + 3] = tostring(v)
      end
    end

    write {
      {'Parse', '', sql, {}},
      bindMsg,
      {'Describe', 'P', ''},
      {'Execute', '', 0},
      {'Sync'},
    }
    waiting = coroutine.running()
    return coroutine.yield()
  end

  local function close()
    write {'Terminate'}
    return write()
  end

  return {
    close       = close,
    params      = params,
    query       = query,
    queryParams = queryParams,
    socket      = socket,
  }
end

local function connect(options)
  local connOpts
  if options.path then
    connOpts = { path = options.path }
  else
    connOpts = {
      host = options.host or "localhost",
      port = options.port or 5432,
    }
  end

  local psqlOpts = {
    username = options.username or os.getenv("USER") or "postgres",
    database = options.database or options.username or "postgres",
    password = options.password,
  }

  local read, write, socket = netConnect(connOpts)
  if not read then
    return nil, write
  end

  local ok, result = pcall(wrap, psqlOpts, read, write, socket)
  if not ok then
    pcall(function() socket:close() end)
    return nil, result
  end

  return result
end

return {
  connect = connect,
  wrap    = wrap,
}
