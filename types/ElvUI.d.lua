---@meta
--- Minimal ElvUI stubs for ElvUI_mhTags (no local ElvUI clone required).
--- WoW API globals are provided by the ketho.wow-api extension.

---@class ElvUIEngine
---@field version number|string
---@field AddTag fun(self: ElvUIEngine, name: string, events: string, func: fun(unit: string): string?)
---@field AddTagInfo fun(self: ElvUIEngine, name: string, category: string, description: string)
---@field GetFormattedText fun(self: ElvUIEngine, text: string, ...: any): string
---@field ShortValue fun(self: ElvUIEngine, value: number): string
---@field ShortenString fun(self: ElvUIEngine, text: string, length: number): string

---@type [ElvUIEngine, table<string, string>]
ElvUI = ElvUI
