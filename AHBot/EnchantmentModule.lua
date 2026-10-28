-- enchantments.lua
local EnchantmentModule = {}

local unpack = table.unpack or unpack -- table.unpack doesn't exist in Lua 5.1 / LuaJIT

-- Item enchantment slots are stored as 12 slots of "id duration charges". Random properties use
-- PROP_ENCHANTMENT_SLOT_2-4 (slots 9-11) and random suffixes PROP_ENCHANTMENT_SLOT_0-4 (slots 7-11), like the core.
local ENCHANTMENT_SLOTS = 12
local RANDOM_PROPERTY_FIRST_SLOT = 9
local RANDOM_SUFFIX_FIRST_SLOT = 7

local function BuildEnchantString(firstSlot, enchantments)
    local values = {}
    for slot = 0, ENCHANTMENT_SLOTS - 1 do
        local enchantment = enchantments[slot - firstSlot + 1] or 0
        table.insert(values, enchantment .. " 0 0")
    end
    return table.concat(values, " ")
end

local DEFAULT_ENCHANT_STRING = BuildEnchantString(0, {})

-- Picks an entry of item_enchantment_template by its chance, among those the given table has data for
local function PickByChance(options, known)
    local total = 0
    for _, option in ipairs(options) do
        if known[option.ench] then total = total + option.chance end
    end
    if total <= 0 then return nil end

    local rand = math.random() * total
    for _, option in ipairs(options) do
        if known[option.ench] then
            rand = rand - option.chance
            if rand <= 0 then return option.ench end
        end
    end
    return nil
end

-- Fallback for random suffix items without item_enchantment_template data
local function GetRandomSuffix(item)
    local suffixOptions = {}

    -- Determine suffix options based on item type
    if item.InventoryType == 23 or item.InventoryType == 20
    or (item.class == 2 and (item.subclass == 10 or item.subclass == 19))
    or (item.class == 4 and item.subclass == 1) then
        suffixOptions = {36, 37, 38, 39, 9, 15, 19, 26, 81, 84, 85, 31, 32, 33, 34, 35}
    elseif (item.class == 4 and item.subclass == 2)
    or (item.class == 2 and (item.subclass == 2 or item.subclass == 3 or item.subclass == 6 or
        item.subclass == 13 or item.subclass == 15 or item.subclass == 16 or
        item.subclass == 17 or item.subclass == 18)) then
        suffixOptions = {56, 63, 68, 69, 71, 74, 84, 89, 91, 31, 32, 33, 34, 35}
    elseif (item.class == 4 and item.subclass == 3) then
        suffixOptions = {91, 89, 86, 71, 69, 63, 67, 50, 31, 32, 33, 34, 35}
    elseif item.class == 2 or (item.class == 4 and (item.subclass == 4 or item.subclass == 6)) then
        suffixOptions = {92, 89, 86, 84, 68, 71, 72, 66, 62, 63, 43, 41, 31, 32, 33, 34, 35}
    else
        return math.random(49, 75)
    end

    return suffixOptions[math.random(1, #suffixOptions)]
end

-- Returns the item's randomPropertyId and enchantments string for item_instance.
-- config holds ApplyRandomProperties, AHBotItemDebug, ItemRandomProperty (item_enchantment_template),
-- ItemRandomProperties and ItemRandomSuffix, as those are local to AHBot.lua.
function EnchantmentModule.ApplyRandomEnchantments(item, config)
    config = config or {}
    if not config.ApplyRandomProperties then
        return 0, DEFAULT_ENCHANT_STRING
    end

    local templates = config.ItemRandomProperty or {}
    local properties = config.ItemRandomProperties or {}
    local suffixes = config.ItemRandomSuffix or {}

    if item.RandomProperty > 0 then -- Handle random properties, like "of the Eagle"
        local propertyId = PickByChance(templates[item.RandomProperty] or {}, properties)
        if not propertyId then return 0, DEFAULT_ENCHANT_STRING end

        local e1, e2, e3 = unpack(properties[propertyId])
        if config.AHBotItemDebug then
            print("[Eluna AH Bot Item Debug]: Item "..item.entry.." - Enchants for "..propertyId..": "..e1..", "..e2..", "..e3)
        end
        return propertyId, BuildEnchantString(RANDOM_PROPERTY_FIRST_SLOT, {e1, e2, e3})

    elseif item.RandomSuffix > 0 then -- Handle random suffixes, stored as negative IDs
        local suffixId = PickByChance(templates[item.RandomSuffix] or {}, suffixes)
        if not suffixId then
            suffixId = GetRandomSuffix(item)
            if not suffixes[suffixId] then return 0, DEFAULT_ENCHANT_STRING end
        end

        local e1, e2, e3, e4, e5 = unpack(suffixes[suffixId].Enchantment)
        if config.AHBotItemDebug then
            print("[Eluna AH Bot Item Debug]: Item "..item.entry.." - Enchants found for "..suffixId..": "..e1..", "..e2..", "..e3..", "..e4..", "..e5)
        end
        return -suffixId, BuildEnchantString(RANDOM_SUFFIX_FIRST_SLOT, {e1, e2, e3, e4, e5})
    end

    return 0, DEFAULT_ENCHANT_STRING
end

return EnchantmentModule
