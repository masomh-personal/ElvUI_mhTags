# WoW Lua Best Practices - Quick Reference

## Performance Rules

### ✅ DO: Localize Everything

```lua
-- GOOD: Localize at file/function top
local format = string.format
local floor = math.floor
local UnitHealth = UnitHealth
local E = unpack(ElvUI)

-- BAD: Global lookups in hot paths
local percent = (UnitHealth(unit) / UnitHealthMax(unit)) * 100
```

### ✅ DO: Pre-Compute Constants

```lua
-- GOOD: Compute once at load time
local PERCENT_FORMAT = "%.1f%%"
local COLOR_END = "|r"

-- BAD: Compute every call
local result = format("%." .. decimals .. "f%%", value)
```

### ✅ DO: Use Table Lookups Over Conditionals

```lua
-- GOOD: O(1) lookup
local FORMATS = {[0] = "%.0f", [1] = "%.1f", [2] = "%.2f"}
local fmt = FORMATS[decimals] or format("%%.%df", decimals)

-- BAD: O(n) conditional chain
local fmt
if decimals == 0 then
    fmt = "%.0f"
elseif decimals == 1 then
    fmt = "%.1f"
-- ... etc
```

### ✅ DO: Early Returns

```lua
-- GOOD: Exit fast for common cases
function getHealthPercent(unit)
    if not unit then return "" end
    local maxHp = UnitHealthMax(unit)
    if maxHp == 0 then return "" end
    return (UnitHealth(unit) / maxHp) * 100
end

-- BAD: Nested conditionals
function getHealthPercent(unit)
    if unit then
        local maxHp = UnitHealthMax(unit)
        if maxHp > 0 then
            return (UnitHealth(unit) / maxHp) * 100
        end
    end
    return ""
end
```

### ⚠️ AVOID: String Concatenation in Loops

```lua
-- GOOD: Use table.concat
local parts = {}
for i = 1, n do
    parts[i] = getValue(i)
end
return table.concat(parts, " ")

-- BAD: Creates n temporary strings
local result = ""
for i = 1, n do
    result = result .. getValue(i) .. " "
end
return result
```

### ⚠️ AVOID: Unnecessary format() Calls

```lua
-- GOOD: Direct concatenation for 2-3 strings
return str1 .. str2 .. str3

-- BAD: format() overhead
return string.format("%s%s%s", str1, str2, str3)

-- EXCEPTION: Use format when you need formatting
return string.format("%.2f%%", percent)  -- OK
```

---

## Memory Management

### ✅ DO: Avoid Persistent Caching

```lua
-- GOOD: Calculate on demand
function getHealthColor(unit)
    local percent = getHealthPercent(unit)
    return GRADIENT_TABLE[floor(percent)]
end

-- BAD: Cache grows unbounded
local healthColorCache = {}
function getHealthColor(unit)
    if not healthColorCache[unit] then
        healthColorCache[unit] = GRADIENT_TABLE[floor(getHealthPercent(unit))]
    end
    return healthColorCache[unit]
end
```

### ✅ DO: Reuse Tables

```lua
-- GOOD: Reuse table for multiple operations
local tempTable = {}
function processData()
    wipe(tempTable)
    -- use tempTable
end

-- BAD: Create new table every call
function processData()
    local t = {}  -- GC pressure
    -- use t
end
```

### ✅ DO: Clear References

```lua
-- GOOD: Help garbage collector
frame:SetScript("OnUpdate", nil)
frame.data = nil

-- BAD: Leave dangling references
-- (frame still has OnUpdate handler)
```

---

## Error Handling

### ✅ DO: Validate Inputs

```lua
-- GOOD: Check all assumptions
function formatHealth(unit, decimals)
    if not unit or type(decimals) ~= "number" then
        return ""
    end
    -- ...
end

-- BAD: Assume inputs are valid
function formatHealth(unit, decimals)
    return string.format("%." .. decimals .. "f", getPercent(unit))
end
```

### ✅ DO: Use pcall for Unsafe Operations

```lua
-- GOOD: Catch errors
local success, result = pcall(function()
    return E:GetFormattedText(...)
end)
if success then
    return result
else
    print("Error:", result)
    return ""
end

-- BAD: Let errors propagate
return E:GetFormattedText(...)  -- Crashes if E is nil
```

### ✅ DO: Provide Fallbacks

```lua
-- GOOD: Always return valid value
function getColor(index)
    return COLOR_TABLE[index] or DEFAULT_COLOR
end

-- BAD: Return nil
function getColor(index)
    return COLOR_TABLE[index]
end
```

---

## Event Handling

### ✅ DO: Register Only Needed Events

```lua
-- GOOD: Minimal event set
"UNIT_HEALTH UNIT_MAXHEALTH"

-- BAD: Register everything "just in case"
"UNIT_HEALTH UNIT_MAXHEALTH UNIT_POWER_UPDATE UNIT_AURA PLAYER_ENTERING_WORLD"
```

### ✅ DO: Unregister When Done

```lua
-- GOOD: Clean up
frame:UnregisterEvent("PLAYER_LOGIN")

-- BAD: Leave registered forever
-- (wastes CPU on every event fire)
```

### ⚠️ AVOID: Heavy Processing in Event Handlers

```lua
-- GOOD: Defer heavy work
frame:SetScript("OnEvent", function()
    C_Timer.After(0.1, function()
        -- Heavy calculation here
    end)
end)

-- BAD: Block event processing
frame:SetScript("OnEvent", function()
    -- Heavy calculation here
end)
```

---

## Namespace Management

### ✅ DO: Use Private Namespace

```lua
-- GOOD: Addon-specific namespace
local _, ns = ...
ns.MyAddon = {}
local MyAddon = ns.MyAddon

MyAddon.VERSION = "1.0.0"
MyAddon.doSomething = function() end

-- BAD: Pollute global namespace
MyAddonVersion = "1.0.0"
function MyAddon_DoSomething() end
```

### ✅ DO: Export Only Public API

```lua
-- GOOD: Internal functions are local
local function internalHelper()
    -- Not visible outside file
end

MyAddon.publicFunction = function()
    internalHelper()
end

-- BAD: Everything is exposed
function MyAddon_InternalHelper()  -- Global!
end
```

---

## WoW-Specific Patterns

### ✅ DO: Check for Game State

```lua
-- GOOD: Validate state
if not InCombatLockdown() then
    -- Safe to modify UI
end

if UnitExists(unit) then
    -- Safe to query unit
end

-- BAD: Assume state
-- Modify UI (might be in combat)
```

### ✅ DO: Use C\_\* APIs When Available

```lua
-- GOOD: Modern API
local info = C_UnitAuras.GetAuraDataByIndex(unit, 1)

-- OLD: Legacy API (still works but may be deprecated)
local name, icon = UnitAura(unit, 1)
```

### ✅ DO: Handle Disconnected Units

```lua
-- GOOD: Check connection
if UnitIsConnected(unit) then
    -- Unit is online
else
    return "Offline"
end

-- BAD: Assume connected
local health = UnitHealth(unit)  -- Returns 0 if disconnected!
```

---

## ElvUI-Specific Patterns

### ✅ DO: Use ElvUI Helpers

```lua
-- GOOD: Use ElvUI formatting
E:GetFormattedText("CURRENT", hp, maxHp, nil, true)
E:ShortValue(1234567)  -- "1.2m"
E:ShortenString("Long Name", 10)  -- "Long Na..."

-- BAD: Reimplement
function shortenNumber(n)
    if n >= 1000000 then
        return string.format("%.1fm", n / 1000000)
    -- ... etc
end
```

### ✅ DO: Register Tags Properly

```lua
-- GOOD: Use E:AddTag
E:AddTag("mytag", "UNIT_HEALTH", function(unit)
    return UnitHealth(unit)
end)

-- BAD: Direct table manipulation
E.Tags.Methods["mytag"] = function() end
```

### ✅ DO: Follow ElvUI Naming

```lua
-- GOOD: Consistent with ElvUI style
"mh-health-current-percent"
"mh-power-percent"

-- BAD: Inconsistent naming
"mhHealthCurrentPercent"
"MH_POWER_PCT"
```

---

## Code Organization

### ✅ DO: Group Related Code

```lua
-- GOOD: Clear sections
-- ====================
-- CONSTANTS
-- ====================
local MAX_LEVEL = 70
local COLOR_RED = "|cffFF0000"

-- ====================
-- HELPER FUNCTIONS
-- ====================
local function formatValue(v)
    -- ...
end

-- ====================
-- PUBLIC API
-- ====================
MyAddon.doSomething = function()
    -- ...
end
```

### ✅ DO: Keep Functions Focused

```lua
-- GOOD: Single responsibility
local function getHealthData(unit)
    return UnitHealth(unit), UnitHealthMax(unit)
end

local function formatHealthPercent(hp, maxHp, decimals)
    return string.format("%." .. decimals .. "f%%", (hp / maxHp) * 100)
end

-- BAD: Does too much
local function getAndFormatHealth(unit, decimals, includeStatus, ...)
    -- 50 lines of mixed concerns
end
```

### ✅ DO: Comment Why, Not What

```lua
-- GOOD: Explains reasoning
-- Check connection first because it's the most common case in raids
if not UnitIsConnected(unit) then
    return "Offline"
end

-- BAD: States the obvious
-- Check if unit is connected
if not UnitIsConnected(unit) then
    return "Offline"
end
```

---

## Testing Patterns

### ✅ DO: Test Edge Cases

```lua
-- Test these scenarios:
- nil input
- invalid unit ("invalidunit123")
- dead unit
- disconnected unit
- zero values (maxHp = 0)
- extreme values (maxHp = 999999999)
- malformed args ("abc", "{invalid}")
```

### ✅ DO: Profile in Realistic Scenarios

```lua
-- Test addon in:
- 40-person raid (heavy load)
- Battleground (network latency)
- Boss fight (CPU spike)
- After 2+ hours (memory leak check)
```

### ✅ DO: Monitor Resource Usage

```lua
-- Commands to run:
/run UpdateAddOnMemoryUsage(); print("Memory:", GetAddOnMemoryUsage("YourAddon"), "KB")
/run UpdateAddOnCPUUsage(); print("CPU:", GetAddOnCPUUsage("YourAddon"), "ms")
/run collectgarbage("collect"); print("GC done")
```

---

## Common Pitfalls to Avoid

### ❌ DON'T: Use `pairs()` When `ipairs()` Works

```lua
-- GOOD: ipairs for arrays
for i, value in ipairs(orderedTable) do
end

-- BAD: pairs is slower
for i, value in pairs(orderedTable) do
end
```

### ❌ DON'T: Create Functions Inside Loops

```lua
-- GOOD: Define once, reuse
local function processItem(item)
    -- ...
end

for i = 1, n do
    processItem(items[i])
end

-- BAD: Creates n functions
for i = 1, n do
    local fn = function()
        process(items[i])
    end
    fn()
end
```

### ❌ DON'T: Assume tonumber() Behavior

```lua
-- GOOD: Explicit nil check
local n = tonumber(input)
if n ~= nil then
    -- Use n
end

-- BAD: Uses 'or' for default
local n = tonumber(input) or 1
-- Problem: tonumber("0") is 0, which is falsy!
-- So tonumber("0") or 1 returns 1, not 0
```

### ❌ DON'T: Modify Tables During Iteration

```lua
-- GOOD: Iterate over copy
for k, v in pairs(tableC

opy) do
    if shouldRemove(v) then
        originalTable[k] = nil
    end
end

-- BAD: Undefined behavior
for k, v in pairs(table) do
    if shouldRemove(v) then
        table[k] = nil  -- Breaks iteration!
    end
end
```

---

## Version Control Best Practices

### ✅ DO: Track Interface Version

```lua
-- In .toc file:
## Interface: 110200
## Version: 6.0.1

-- Match to WoW patch version
```

### ✅ DO: Maintain CHANGELOG

```lua
-- Document:
- Breaking changes
- New features
- Bug fixes
- Performance improvements
- Migration paths
```

### ✅ DO: Semantic Versioning

```lua
-- MAJOR.MINOR.PATCH
-- 6.0.0 - Breaking changes
-- 6.1.0 - New features (backwards compatible)
-- 6.1.1 - Bug fixes only
```

---

## Quick Checklist for New Code

Before committing code, verify:

- [ ] All globals localized
- [ ] Nil checks on function entry
- [ ] Error handling for API calls
- [ ] No memory leaks (no growing tables)
- [ ] Events properly registered/unregistered
- [ ] Functions are single-responsibility
- [ ] Comments explain "why", not "what"
- [ ] Tested in 40-person raid
- [ ] Memory usage checked after 30+ minutes
- [ ] No Lua errors in /console scriptErrors 1

---

**Remember**: In WoW, performance isn't just nice-to-have—it's critical. Even "small" inefficiencies become massive when multiplied by 40 raid frames updating every 0.5 seconds.
