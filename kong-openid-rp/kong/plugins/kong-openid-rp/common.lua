local json = require "JSON"
local stringy = require "stringy"
local constants = require "kong.constants"
local _M = {}

function _M.isempty(s)
    return s == nil or s == ''
end

function _M.split(str, sep)
    local output = {}
    for match in str:gmatch("([^".. sep .."%s]+)") do
        table.insert(output, match)
    end
    return output
end

function _M.isHttps(url)
    if _M.isempty(url) then
        ngx.log(ngx.ERR, url .. ". It is blank.")
        return false
    end

    if not stringy.startswith(url, "https://") then
        ngx.log(ngx.ERR, "Invalid ".. url ..". It does not start from 'https://', value: " .. url)
        return false
    end

    return true
end

function _M.print_table(node)
    -- to make output beautiful
    local function tab(amt)
        local str = ""
        for i=1,amt do
            str = str .. "\t"
        end
        return str
    end

    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. tab(depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. tab(depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. tab(depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. tab(depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end

function _M.set_header(consumer, oxd, user_info)
    ngx.header[constants.HEADERS.CONSUMER_ID] = consumer.id
    ngx.header[constants.HEADERS.CONSUMER_CUSTOM_ID] = consumer.custom_id
    ngx.header[constants.HEADERS.CONSUMER_USERNAME] = consumer.username
    ngx.header["X-OXD"] = json:encode(oxd)
    ngx.header["X-USER-INFO"] = json:encode(user_info)
end

return _M