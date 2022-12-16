local files   = require 'files'
local guide   = require 'parser.guide'
local lang    = require 'language'
local define  = require 'proto.define'
local log     = require 'log'
local luacheck = require "luacheck.check"
local lcstages = require "luacheck.stages"
local lcformat = require "luacheck.format"
local lcfilter = require "luacheck.filter"
local lcconfig = require "luacheck.config"
local workspace = require "workspace"
local fs = require "luacheck.fs"

local function pprint(t)
    if type(t) ~= "table" then
        log.info(t)
        return
    end
    for k,v in pairs(t) do
        log.info("t k:", k, "v:", v)
    end
end

local config = nil

return function (uri, callback)
    if not config then
        local rootUri = (workspace.rootUri or ""):gsub("file://", "")
        local path = fs.join(rootUri, ".luacheckrc")
        local global_path = nil
        config = lcconfig.load_config(path, global_path)
    end
    local text = files.getText(uri)
    local report = luacheck(text)
    lcfilter.filter({report})
    for i,warning in ipairs(report.filtered_warnings) do
        local message = lcformat.get_message(warning)
        local start = ((warning.line - 1) * 10000) + warning.column - 1
        local finish = ((warning.line - 1) * 10000) + warning.end_column
        callback({
            start   = start,
            finish  = finish,
            tags    = { define.DiagnosticTag.Unnecessary },
            message = message,
        })
    end
end
