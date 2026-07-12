---@meta
--- Minimal ElvUI stubs for ElvUI_mhTags (no local ElvUI clone required).
--- WoW API globals are provided by the ketho.wow-api extension.

---@alias ElvUITagFunction fun(unit: string, event?: string, args?: string): string|number|nil

---@class ElvUIEngine
---@field version number|string
---@field AddTag fun(self: ElvUIEngine, name: string, events: string, func: ElvUITagFunction)
---@field AddTagInfo fun(self: ElvUIEngine, name: string, category: string, description: string)
---@field ShortenString fun(self: ElvUIEngine, text: string, length: number): string

---@type [ElvUIEngine, table<string, string>]
ElvUI = ElvUI
