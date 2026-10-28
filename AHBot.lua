-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------
--
-- Welcome to mostlynick's Eluna AH Bot :)
--
-- Features: * Plug and Play *, * Extensive filters *, * Buyer *, * Seller *, * Both bids and buyouts *, * and more *
-- This module is compatible with all Eluna versions that support async DB queries.
-- Made for Yggdrasil WotLK / AzerothCore. 
-- You may freely use this file for emulation purposes. It is released under this repository's GPL v3 license: https://github.com/mostlynick3/azerothcore-lua-ah-bot
--
-------------------------------------------------------------------------------------------------------------------------
-- Multistate support
-------------------------------------------------------------------------------------------------------------------------

if GetStateMapId() ~= -1 then return end

-------------------------------------------------------------------------------------------------------------------------
-- AH Bot Configs
-------------------------------------------------------------------------------------------------------------------------

local EnableAHBot           = true           -- Default: True. If false, AH bot is disabled. 
local AHBots                = {1, 2, 3}      -- Default: 1, 2, 3. Chooses which player GUID lows will be used as AH bots. Must match extant characters. Not faction specific.
local EnabledAuctionHouses  = {2, 6, 7}      -- Default: 2, 6, 7. Possible values: 2 is ally, 6 is horde, 7 is cross faction (neutral). Multiple values accepted, like {2, 6, 7}. Only 7 is required on cross-faction servers.
local AHBotActionDebug      = true           -- Default: False. Enables various action debug prints. Critical prints will still be active even if false.
local AHBotItemDebug        = false          -- Default: False. Enables debug prints on item handling, cost per item entry, Quality, etc.
local ActionsPerCycle       = 150            -- Default: 500 (items). Batch size per auction house at peak hours (see HourlySellMultipliers). The higher the value, the faster the bots fill the AH up to the min auctions limit and the more items they buy, at the expense of performance.
local StartupDelay          = 1000           -- Default: 1000 (ms). Delay after startup/Eluna reload before the auction house initializes. Having this set to 0 will cause lag on initial world load. 
local EnableGMMessages      = true           -- Default: True. Messages all online GMs on command and initiation events.
local AnnounceOnLogin       = true           -- Default: True. Announces to all players on login that this server runs the Eluna AH Bot module.
local ClearBotMailbox       = true           -- Default: False. If enabled, periodically clears bots' mailbox, including the items in it. Ensures no overflow from bot mailbox filling up with expired/sold/bought auctions. Recommended when selling often.

-------------------------------------------------------------------------------------------------------------------------
-- Buyer Configs
-------------------------------------------------------------------------------------------------------------------------

local EnableBuyer           = true           -- Default: True.
local AHBuyTimer            = 1              -- Default: 0.5 (hours). How often the AH bot will try to purchase a few items.
local ItemLevelLimit        = 187            -- Default: 187. Prevents bots from buying items above this item level, to ensure players get access to those items instead.
local BotsBuyFromBots       = false          -- Default: True. Lets bots buy and bid on other bots' auctions (scaled down by BotToBotBuyFactor), so some bot auctions sell before they expire.
local BotToBotBuyFactor     = 0.2            -- Default: 0.2. Multiplies the buyout/bid chances on other bots' auctions.
local BuyerCostFormula      = 1              -- Default: 1. 1 = Quality based scaling, 2 = Entry ID influenced, 3 = Quality/Level focused, 4 = Balanced multi-factor, 5 = Progressive thresholds, 6 = Random (1000-1000000)
local BotsPriceTolerance    = 1.0            -- Default: 1.0. How much bots pay at most, relative to the price they would list the item at themselves (including market prices). 1.0 = only buy below the bots' own price.
local PlaceBidChance        = 5              -- Default: 10 (%). Setting to 0 disables bids. 
local PlaceBuyoutChance     = 3              -- Default: 5 (%). Settings to 0 disables buyouts.
local BuyOnStartup          = true           -- Default: True. Buyer bot will start buying auctions immediately on server start, instead of on AHBuyTimer. If false, will still activate on AHBuyTimer. 
local DisableBidFight       = true           -- Default: True. Don't place bids/buyouts on items that players have already placed bids on
local BotsOutbidBots        = true           -- Default: True. Bots may outbid other bots' bids, so bid prices move. Players' bids are only outbid if DisableBidFight is false.
local DealChanceMultiplier  = 3              -- Default: 3. The better the deal, the likelier a bot buys: buyout/bid chances are multiplied by (value / price), up to this factor. 1 disables.
local BuyDelayMin           = 30             -- Default: 30 (minutes). Bots only consider an auction once it has been listed for a random delay between BuyDelayMin and BuyDelayMax,
local BuyDelayMax           = 360            -- Default: 360 (minutes). so items don't sell the moment they're posted.
local MaxBuysPerCycle       = 3              -- Default: 3. Maximum buyouts/bids per buy cycle. Set to false for no limit.

-------------------------------------------------------------------------------------------------------------------------
-- Seller Configs
-------------------------------------------------------------------------------------------------------------------------

local EnableSeller          = true          -- Default: True.
local MaxAuctions           = 10000         -- Default: 5000. Max number of auctions posted by the AH bot.
local MinAuctions           = 2000          -- Default: 2000. Min number of auctions. If under this value, AH will repopulate sales. If over, but less than max, has 30% chance per check to populate AH.
local RepopulationChance    = 30            -- Default: 30. Percentage chance to partially restock AH if stock is between max and min during a periodical check. Can be overriden to force populate whenever with ".ahbot auctions add". 
local SellerCostFormula     = 1             -- Default: 1. 1 = Quality based scaling, 2 = Entry ID influenced, 3 = Quality/Level focused, 4 = Balanced multi-factor, 5 = Progressive thresholds, 6 = Random (1000-1000000)
local SellPriceVariance     = 20            -- Default: 20. How many % to randomize prices with. 
local AHSellTimer           = 1             -- Default: 5 (hours). How often the AH bot will check whether it needs to put up new auctions, in hours. Minimum 1.
local HourlySellMultipliers = {             -- Share of ActionsPerCycle posted per sell cycle by server hour (0-23), from 0 to 1. Busier evenings, quiet nights.
    [0] = 0.4, [1] = 0.3, [2] = 0.2, [3] = 0.2, [4] = 0.2, [5] = 0.2,       -- Only applies while an auction house has at least MinAuctions,
    [6] = 0.3, [7] = 0.4, [8] = 0.5, [9] = 0.5, [10] = 0.6, [11] = 0.6,     -- below that the full ActionsPerCycle is posted.
    [12] = 0.7, [13] = 0.7, [14] = 0.7, [15] = 0.7, [16] = 0.8, [17] = 0.9, -- Set to false to always post ActionsPerCycle.
    [18] = 1.0, [19] = 1.0, [20] = 1.0, [21] = 1.0, [22] = 0.8, [23] = 0.6,
}
local SellOnStartup         = true          -- Default: True. Used for debugging and instantly populating an empty auction house. If true, fires AH bot on Eluna load (startup / Eluna reloads). If false, activates on AHSellTimer. 
local ApplyRandomProperties = true          -- Default: True. Adds enchant/random stats and corresponding name to items (e.g., "of the Eagle"). This is DBC-based with Lua tables copied into this script. Disable if non-WotLK core.
local SetAsCraftedBy        = true          -- Default: True. Marks items created by player spells as created by the AH bot posting the item.

-- Seller Realism
local AuctionDurations      = {[12] = 20, [24] = 40, [48] = 40}   -- Default: 12h = 20, 24h = 40, 48h = 40. Relative chance of each auction duration (in hours), like players choose when posting.
local UndercutChance        = 80            -- Default: 80 (%). Chance to undercut the lowest listing of the same item in the same auction house, like players do.
local UndercutRange         = {1, 5}        -- Default: 1, 5 (%). How much below the lowest listing to post when undercutting.
local UndercutLimits        = {0.6, 1.5}    -- Default: 0.6, 1.5. Undercut prices are kept between 60% and 150% of the bot's own price, so it doesn't follow dumped or absurd listings.
local UndercutPlayers       = false         -- Default: False. If false, bots only undercut other bots, and list at or slightly above players' lowest price instead of below it (within UndercutLimits), so players' auctions stay competitive.
local VendorPriceMultiplier = {4, 8}        -- Default: 4, 8. Items the cost formula prices under 10s are priced at this many times their vendor sell price instead. Items are never priced below 1.25x vendor price.
local HumanizePrices        = true          -- Default: True. Rounds prices like players type them, e.g. 4g 95s or 24g 99s 99c instead of 4g 37s 12c.
local MarketPrices          = true          -- Default: True. Remembers a price factor per item and auction house: raised when the bot's listings sell, lowered when they expire unsold.
local MarketPriceLimits     = {0.5, 2.0}    -- Default: 0.5, 2.0. Lowest and highest market price factor.
local HousePriceModifiers   = {[2] = 1.0, [6] = 1.0, [7] = 1.15}  -- Default: 2 = 1.0, 6 = 1.0, 7 = 1.15. Price factor per auction house. The neutral AH takes a bigger cut, so prices there run higher.
local StackSizeWeights      = {[1] = 15, [5] = 20, [10] = 25, [20] = 30, full = 10}  -- Default: 1 = 15, 5 = 20, 10 = 25, 20 = 30, full = 10. Relative chance of each stack size for StackedItemClasses. Sizes above an item's max stack are skipped.
local CheapItemPrice        = 5000          -- Default: 5000 (50s). Items whose single unit costs less than this are mostly sold in full stacks.
local CheapFullStackWeight  = 60            -- Default: 60. Replaces the 'full' stack weight for cheap items.
local MultiListClasses      = {0, 7}        -- Default: 0, 7 (Consumables and Trade Goods). Item classes that may be posted as several listings at slightly increasing prices, like several sellers undercutting each other.
local MultiListChance       = 40            -- Default: 40 (%). Chance for an item of MultiListClasses to get extra listings.
local MaxExtraListings      = 3             -- Default: 3. Maximum number of extra listings per item.
local MatchPlayerLevels     = 0.5           -- Default: 0.5. From 0 to 1, how strongly gear and consumable listings follow the levels of recently active players. 0 or false disables.
local PlayerActivityDays    = 7             -- Default: 7. Characters who logged in within this many days count as active for MatchPlayerLevels.

-------------------------------------------------------------------------------------------------------------------------
-- Item Seller Filter Configs
-------------------------------------------------------------------------------------------------------------------------

-- General Item Filters
local Expansion              = 0                   -- Default: 0 (no expansion lock). Possible values: 0 (no expansion lock), 1 (Vanilla, patch 1.12), 2 (TBC, patch 2.4.3), 3 (WotLK, patch 3.3.5a). Any expansion filter makes bots includes all items in the item_template database table per expansion.
local EnableItemFilters      = true                -- Default: True. Disable only for debugging.
local SellAllAuctionableItems = true               -- Default: True. Sells every item a player could list on the AH: everything that isn't soulbound (BoP/quest bound), account bound, conjured or timed. Only unobtainable placeholder/test items, NeverSellIDs and the Expansion setting are still filtered. Overrides all filters below until the weights section. Set to false to use the curated filters below instead.
local AllowDeprecated        = false               -- Default: False. Items with flag 16 (Deprecated) or name like NPC, zzOLD, etc. will not be sold.
local AllowedBinds           = {0, 2, 3}           -- Default: 0, 2, 3. 0 = no bounds, 1 = Bind on Pickup, 2 = Bind on Equip, 3 = Bind on Use, 4-5 Quest Items (see also AllowQuestItems to control quest item sales).
local AllowBindOnAccount     = false               -- Default: False. Decides whether BoA items (e.g., hierlooms) can be sold by the AH bot.
local AllowedQualities       = {1, 2, 3, 4}        -- Default: 1, 2, 3, 4. 0 = Gray/Poor, 1 = White/Common, 2 = Green/Uncommon, 3 = Blue/Rare, 4 = Purple/Epic, 5 = Orange/Legendary, 6 = Red/Artifact, 7 = Gold/Heirloom.
local AllowQuestItems        = false               -- Default: False.
local AllowConsumables       = true                -- Default: True. Toggles selling consumables (potions, elixirs, etc.).
local MinContainerSize       = 16                  -- Default: 16. Don't allow selling containers (including quivers, bags, etc.) under specified size.
local MinLevelConsumables    = 50                  -- Default: 50. Prevents the AH bot from flooding the market with low level junk.
local MinLevelGear           = 10                  -- Default: 10. Prevents the AH bot from flooding the market with low level junk and unobtainable starter items.
local MaxLevel               = 80                  -- Default: 80. The AH bot will not sell any item with a level limit exceeding this value.
local StackedItemClasses     = {0, 5, 6, 7}        -- Default: 0, 5, 6, 7. Sells stacks using StackSizeWeights. Possible values: 0 (Consumable), 1 (Container), 2 (Weapon), 3 (Gem), 4 (Armor), 5 (Reagent), 6 (Projectile), 7 (Trade Goods), 9 (Recipe), 11 (Quiver), 12 (Quest), 13 (Key) 15 (Miscellaneous), 16 (Glyph).
local AlwaysMaxStackAmmo     = true                -- Default: True. If true, always sells ammo in stacks of 1000.
local AdjustedAmmoPrices     = true                -- Default: True. Ammo price variables are inconsistent. This adjusts ammunition prices to realistic in-game prices. For example, Iceblade Arrows are set to between 20g-35g per stack.
local AllowCommonAmmo        = false               -- Defualt: False. Common ammo is just dead weight.
local AllowReputationItems   = false               -- Default: False.
local AllowMounts            = false               -- Default: False. If true, the X-51 rocket has a tendency to show up.
local AllowCompanions        = true                -- Default: True. 

-- Character and Race Filters
local AllowedClassItems        = {-1}                                  -- Default: -1. Possible values: -1 (Items with no class restrictions), 1 (Warrior), 2 (Paladin), 3 (Hunter), 4 (Rogue), 5 (Priest), 6 (DK), 7 (Shaman), 9 (Warlock), 11 (Druid). Table accepts multiple values, such as {-1, 1, 2, 3}.
local AllowedAllyRaces         = {-1, 1, 4, 8, 64, 1024, 2147483647}   -- Default: -1, 1, 4, 8, 64, 1024, 2147483647 (All races and all raceless items). Possible values: 1 (Human), 2 (Orc), 4 (Dwarf), 8 (Night Elf), 16 (Undead), 32 (Tauren), 64 (Gnome), 128 (Troll), 512 (Blood Elf), 1024 (Draenei), -1 and 2147483647 (all races).
local AllowedHordeRaces        = {-1, 2, 16, 32, 128, 512, 2147483647} -- Default: -1, 2, 16, 32, 128, 512, 2147483647 (All races and all raceless items). Possible values: 1 (Human), 2 (Orc), 4 (Dwarf), 8 (Night Elf), 16 (Undead), 32 (Tauren), 64 (Gnome), 128 (Troll), 512 (Blood Elf), 1024 (Draenei), -1 and 2147483647 (all races).

-- Profession Filters
local AllowedProfessions    = {8, 16, 32, 64, 128, 512, 1024}  -- Default: 8, 16, 32, 64, 128, 512, 1024. Possible values: 8 (Leatherworking Supplies), 16 (Inscription Supplies), 32 (Herbs), 64 (Enchanting Supplies), 128 (Engineering Supplies), 512 (Gems), 1024 (Mining Supplies).
local AllowLockpicking      = true                             -- Default: True. Toggles lockboxes, etc.
local AllowGlyphs           = true                             -- Default: True. Toggles selling glyphs.
local AllowRecipes          = true                             -- Default: True. Toggles profession recipes.
local RecipePriceAdjustment = 10                               -- Default: 10. Factor to increase recipe prices by. These are usually low in price because their associated variables are low. Set to false to disable.
local GemPriceAdjustment    = 0.142                            -- Default: 1/7. Factor to decrease gem prices by. These are usually high in price because their associated variables are high. Set to false to disable.
local UndervaluedItemAdjust = 5                                -- Default: 5. Vellums, Titanium materials, VIII scrolls etc. are usually somewhat undervalued. Set to false to disable.
local LowPriceFloor         = 200000                           -- Default: 200000 (20g). Price floor for certain items where multipliers don't work well. Companions, glyphs, etc. Randomized +- 30% around this base cost. If nil, defaults to UndervaluedItemAdjust.

-- Misc Config
local AllowKeys                = false                           -- Default: False.
local AllowMisc                = false                           -- Default: False. If enabled, allows Soul Shards, Currency Tokens and "Misc Other" items (item_template class 15, subclass 4).
local AllowJunk                = true                            -- Default: True. Toggles junk, such as fishing boxes.
local AllowHolidayItems        = false                           -- Default: False. Toggles holiday/seasonal items.
local AllowConjured            = false                           -- Default: False. Toggles conjured items like mage strudels.

-- Seller Item Weights
-- Each category is picked with a chance relative to its weight, then an item is picked at random within it.
-- An item can be picked at most <weight> times per cycle (rounded down), so categories with a weight below 1 are skipped.
-- Defaults favour what players buy most on a live server: trade goods, consumables, gems, glyphs and BoE greens.
local ItemWeights = {
    Gear = {
        ["Gray/Poor"]            = 1,
        ["White/Common"]         = 1,
        ["Green/Uncommon"]       = 25,
        ["Blue/Rare"]            = 15,
        ["Purple/Epic"]          = 5,
        ["Orange/Legendary"]     = 1,
        ["Red/Artifact"]         = 1,
        ["Gold/Heirloom"]        = 0
    },
    Mats = {                                 -- Trade goods. Most herbs, ores, cloth and leather are White/Common.
        ["Gray/Poor"]            = 1,
        ["White/Common"]         = 30,
        ["Green/Uncommon"]       = 15,
        ["Blue/Rare"]            = 6,
        ["Purple/Epic"]          = 1,
        ["Orange/Legendary"]     = 1,
        ["Red/Artifact"]         = 1,
        ["Gold/Heirloom"]        = 0
    },
    Consumable = 15,                         -- Potions, elixirs, flasks, food, scrolls, etc.
    Gem = 8,
    Glyph = 10,
    Recipe = 5,
    Container = 4,                           -- Bags and quivers
    Companion = 3,                           -- Non-combat pets
    Projectile = 5,
    Other = 3,                               -- Everything else (keys, quest items, misc junk)
    SpecificItems = {
        -- Example items to include that the auction house bots will weigh as separate categories.
        -- Adding weights per item ID here can, for example, ensure that they are always sold by the AH in a desired (relative) quantity.
        -- Example below: Frostweave Bag
        -- [41599] = 2, -- Frostweave Bag
        -- Add more items with the following structure:
        -- [Item ID] = Weight,
    },
}

-- Customizable item ID exclusion filters
local NeverSellIDs            = {                               -- Default: Various items not intended for AH sale. Append list by adding new "<item_entry>," rows. 
                               52252, -- Lightbringer Tabard    -- Additions here append to the SQL "NAME NOT" list. 
                               44663, -- Adventurer's Satchel
                               54822, -- Sen'Jin's Overcloak
                               37201, -- Corpse Dust
                               17195, -- Fake Mistletoe
                               44432, -- China Glyph of Raise Dead??
                                4439, -- Wooden Stock, vendor trash
                               40533, -- Electrified blade, unobtainable item
                               30418, -- Unused polearm
                               -- Deprecated Classic mounts
                               1041, 1133, 1134, 2413, 2415, 5663, 5874, 5875, 
                               8583, 8589, 8590, 8627, 8628, 8630, 8633, 14062,
                               -- Add more item IDs if needed
                               }

-------------------------------------------------------------------------------------------------------------------------
-- Do not edit below this line unless you know what you're doing
-------------------------------------------------------------------------------------------------------------------------

if not EnableAHBot then return end

if AHSellTimer < 1 then AHSellTimer = 1 end -- Sell cycles must be at least 1 hour apart

-------------------------------------------------------------------------------------------------------------------------
-- Helper functions, tables, etc.
-------------------------------------------------------------------------------------------------------------------------

-- As the core iterates upwards through auction IDs from the highest extrant value on startup,
-- we must insert either far above or far below this value. The caveat of this is that, on 
-- reload eluna, we can't tell whether an insert was made on the same session as Eluna
-- can't access the core's AH counter. So, we're tracking server startup instead and assigning
-- a tag to all inserts to identify which we can safely go below and which we must be above.

local AddedByEluna = 1 -- 0 means created by the core, 1 means created by Eluna

local function TagElunaAuctions(event)
    CharDBQueryAsync("SHOW COLUMNS FROM auctionhouse LIKE 'AddedByEluna'", function(result) -- Checks if tracker exists directly from table structure
        if not result and not (event == 14) then -- Check if any row is returned, indicating the column exists. FetchRow attempts to get the first row, if it fails (returns nil), then no column exists.
            CharDBExecute("ALTER TABLE auctionhouse ADD COLUMN AddedByEluna INT NOT NULL DEFAULT 0") -- Adds the column if it doesn't exist
        elseif event == 14 then
            CharDBExecute("UPDATE auctionhouse SET AddedByEluna = 0 WHERE AddedByEluna > 0") -- Ensures all entries tracked by the core are reset on event 14
        end
    end)
    CharDBQueryAsync("SHOW COLUMNS FROM item_instance LIKE 'AddedByEluna'", function(result) -- Checks if tracker exists directly from table structure
        if not result and not (event == 14) then -- Check if any row is returned, indicating the column exists. FetchRow attempts to get the first row, if it fails (returns nil), then no column exists.
            CharDBExecute("ALTER TABLE item_instance ADD COLUMN AddedByEluna INT NOT NULL DEFAULT 0") -- Adds the column if it doesn't exist
        elseif event == 14 then
            CharDBExecute("UPDATE item_instance SET AddedByEluna = 0 WHERE AddedByEluna > 0") -- Ensures all entries tracked by the core are reset on event 14
        end
    end)
end

TagElunaAuctions()
RegisterServerEvent(14, TagElunaAuctions)

if MarketPrices then -- Bot listings and the market price factors learned from them
    CharDBExecute("CREATE TABLE IF NOT EXISTS ahbot_market (houseid INT UNSIGNED NOT NULL, entry INT UNSIGNED NOT NULL, factor FLOAT NOT NULL DEFAULT 1, PRIMARY KEY (houseid, entry))")
    CharDBExecute("CREATE TABLE IF NOT EXISTS ahbot_listings (id INT UNSIGNED NOT NULL, itemguid INT UNSIGNED NOT NULL, houseid INT UNSIGNED NOT NULL, entry INT UNSIGNED NOT NULL, expiretime INT UNSIGNED NOT NULL, hasbid TINYINT UNSIGNED NOT NULL DEFAULT 0, PRIMARY KEY (id, itemguid))")
end

local itemCache = {}                                          -- Stores all entries from the item_template for further processing
local NextAHBotSellCycle = os.time() + AHSellTimer * 60 * 60  -- Used in print and cmd feedback
local NextAHBotBuyCycle    = os.time() + AHBuyTimer * 60 * 60 -- Used in print and cmd feedback 
local AHBotSellEventId                                        -- Used to track if running, for cmd etc
local AHBotBuyEventId                                         -- Used to track if the indefinite Lua event for the AH bot is running, to not schedule another on top through the cmd system
local botList = table.concat(AHBots, ",")                     -- Converts table to a string for SQL and concat interaction
local houseList = table.concat(EnabledAuctionHouses, ",")     -- Converts table to a string for SQL and concat interaction
local postedAuctions = {}                                     -- Counts how many auctions have been posted by the auction bots last. Used in info cmd
local EnchantmentModule = require("EnchantmentModule")        -- For random item properties
require("AHBot_Helpers")

-- Early returns and MySQL error failsafes
if not EnabledAuctionHouses then error("[Eluna AH Bot]: Core - No valid auction houses found!") end
if not botList or botList == "" or botList:match("[^%d,]") then error("[Eluna AH Bot]: Core - Invalid auction house bots selection! Correct config value 'AHBots' to contain only digits and commas.") end 
if not houseList or houseList == "" or houseList:match("[^%d,]") then  print("[Eluna AH Bot]: Core - No valid house list given! Defaulting to 2, 6, 7 (ally, horde, and neutral).") houseList = "2,6,7" end
if not ActionsPerCycle or type(ActionsPerCycle) ~= "number" then print("[Eluna AH Bot]: Core - ActionsPerCycle must be a number! Defaulting to 500.") ActionsPerCycle = 500 end

function SendMessageToGMs(message)
    for _, player in pairs(GetPlayersInWorld()) do
        if player:GetGMRank() > 0 then
            if not EnableGMMessages then
                if tonumber(message) ~= nil then RemoveEventById(message) end -- If GM messages are off, remove any events in the GM message handler (identified by msg var being number)
                return
            end
            if tonumber(message) ~= nil then player:SendBroadcastMessage("|cFFFF0000 [Eluna AH Bot GM]: Fatal error - No valid bots configured! |r")
            else player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: "..message)
            end
        end
    end
end

local function queryBotCharacters() -- Verifies bots' existence
    local result = CharDBQuery("SELECT guid FROM characters WHERE guid IN (" .. botList .. ")")
    if not result then CreateLuaEvent(SendMessageToGMs, 15 * 60 * 1000, 0) error("[Eluna AH Bot]: Core - No valid bots found!") end -- Notify GMs every 15 minutes if enabled with erroneous AH bot setup

    local validGUIDs = {}

    repeat
        table.insert(validGUIDs, result:GetUInt32(0))
    until not result:NextRow()
    
    if #validGUIDs < #AHBots then
        print("[Eluna AH Bot]: Error in selected bot list "..botList..", bot(s) not found! Defaulting to "..table.concat(validGUIDs, ",")..".")
        SendMessageToGMs("Error in bot list "..botList.."! Defaulting to "..table.concat(validGUIDs, ",")..".")
        AHBots = validGUIDs
        botList = table.concat(AHBots, ",")
    end
    print("[Eluna AH Bot]: AH bot module loaded. Type '.ahbot' in game to manage, set cache settings, and display statistics.")
end

queryBotCharacters()

-- Static table of crafted items that can be assigned bot's name as crafter.
local craftedItems = require("craftedItems")

-- Expansion-specific item ID tables. These are inversions of the item_template tables per expansion (ie., all entries below the max entry which are *not* populated) to conserve space. Used as an initial filter for the "Expansion" config setting.
local ItemsVanilla = require("ItemsVanilla")
local ItemsTBC = require("ItemsTBC")
local ItemsWotLK = require("ItemsWotLK")

-- Static tables of ItemRandomPropeties.dbc and ItemRandomSuffix.dbc to assign enchant IDs to random property items
local ItemRandomSuffix = require("ItemRandomSuffix")
local ItemRandomProperties = require("ItemRandomProperties")
local ItemRandomProperty = {} -- For items with randomized names

-- Build filtered item_template query
local ItemTemplateQuery = [[
    SELECT entry, class, subclass, quality, BuyPrice, SellPrice, 
           InventoryType, AllowableClass, ItemLevel, RequiredLevel,
           RequiredSkill, RequiredSkillRank, stackable, startquest,
           bonding, BagFamily, flags, name, MaxDurability, ContainerSlots,
           RandomProperty, spellcharges_1, spellcharges_2, spellcharges_3,
           spellcharges_4, spellcharges_5, duration, AllowableRace,
           RandomSuffix
    FROM item_template
]]

if EnableItemFilters then
    local conditions = {} -- We must use a table to store conditions to ensure we're not overwriting "where" statements, in case any of the filter conditions are empty

    if Expansion then
        local expansionData = {
            [1] = {items = ItemsVanilla, maxEntry = 24284},
            [2] = {items = ItemsTBC, maxEntry = 39657},
            [3] = {items = ItemsWotLK, maxEntry = 56807}
        }
        local exp = expansionData[Expansion]
        if exp then
            table.insert(conditions, "entry NOT IN (" .. table.concat(exp.items, ',') .. ") AND entry < " .. exp.maxEntry)
        end
    end
    
    -- Simple exclusions
    if NeverSellIDs then
        table.insert(conditions, "NOT entry IN (" .. table.concat(NeverSellIDs, ',') .. ")")
    end
    
    if SellAllAuctionableItems then
        -- Mirror the core's auction house listing rules (AuctionHouseHandler): soulbound,
        -- account bound, conjured and limited duration items can't be auctioned.
        table.insert(conditions, "bonding NOT IN (1, 4, 5)")
        table.insert(conditions, "(flags & 134217728) = 0")
        table.insert(conditions, "(flags & 2) = 0")
        table.insert(conditions, "duration = 0")
        -- Items flagged deprecated or named as placeholders/tests/NPC gear exist in item_template but not in the game.
        table.insert(conditions, "(flags & 16) = 0")
        local placeholderNames = {
            "'%zzOLD%'", "'OLD%'", "'%[PH]%'", "'%(PH)%'", "'%NPC%'", "'%QA%'", "'%TEST%'", "'Test %'",
            "'%Deprecated%'", "'%DEPRECATED%'", "'%Deptecated%'", "'%Unused%'", "'%UNUSED%'",
            "'Monster -%'", "'%90 Epic%'", "'%90 Blue%'", "'%90 Green%'"
        }
        table.insert(conditions, "BINARY name NOT LIKE " .. table.concat(placeholderNames, " AND BINARY name NOT LIKE "))
    else
        -- Container size filter
        if MinContainerSize then
            table.insert(conditions, "NOT ((class = 1 OR class = 11) AND ContainerSlots < "..MinContainerSize..")")
        end
    
        -- Class restrictions
        if AllowedClassItems then
            local classFilter = AllowGlyphs and "(class = 16 OR AllowableClass IN (" or "(AllowableClass IN ("
            table.insert(conditions, classFilter .. table.concat(AllowedClassItems, ',') .. "))")
        end
    
        -- Race restrictions
        for _, raceGroup in ipairs({{AllowedHordeRaces}, {AllowedAllyRaces}}) do
            if raceGroup[1] then
                table.insert(conditions, "AllowableRace IN (" .. table.concat(raceGroup[1], ',') .. ")")
            end
        end
    
        -- Boolean filters with class/subclass/flag checks
        local booleanFilters = {
            {not AllowRecipes, "NOT (class = 9)"},
            {not AllowCompanions, "NOT (class = 15 and subclass = 2)"},
            {not AllowMounts, "NOT (class = 15 and subclass = 5)"},
            {not AllowReputationItems, "RequiredReputationFaction = 0"},
            {not AllowKeys, {"(BagFamily & 256) = 0", "NOT (class = 13 and subclass = 0)"}},
            {not AllowConjured, "(flags & 2) = 0"},
            {not AllowMisc, {"(BagFamily & 4) = 0", "(BagFamily & 2048) = 0", "NOT (class = 15 and subclass = 4)"}},
            {not AllowQuestItems, {"(BagFamily & 16384) = 0", "NOT class = 12"}},
            {not AllowLockpicking, "NOT (class = 13 and subclass = 1)"},
            {not AllowConsumables, "NOT (class = 0)"},
            {not AllowCommonAmmo, "NOT (class = 6 and quality < 2)"},
            {not AllowHolidayItems, {"NOT (class = 15 and subclass = 3)", "HolidayId = 0"}},
            {not AllowBindOnAccount, "(flags & 134217728) = 0"}
        }
    
        for _, filter in ipairs(booleanFilters) do
            if filter[1] then
                if type(filter[2]) == "table" then
                    for _, condition in ipairs(filter[2]) do
                        table.insert(conditions, condition)
                    end
                else
                    table.insert(conditions, filter[2])
                end
            end
        end
    
        -- Quality and binding filters
        if AllowedBinds then
            table.insert(conditions, "bonding IN (" .. table.concat(AllowedBinds, ',') .. ")")
        end
        if AllowedQualities then
            table.insert(conditions, "quality IN (" .. table.concat(AllowedQualities, ',') .. ")")
        end
    
        -- Level filters
        if MaxLevel then
            table.insert(conditions, "RequiredLevel <= ".. MaxLevel)
        end
        if MinLevelConsumables then
            table.insert(conditions, "NOT (class = 0 AND RequiredLevel < " .. MinLevelConsumables .. ")")
        end
        if MinLevelGear then
            table.insert(conditions, "NOT ((class = 4 OR class = 2) AND RequiredLevel < " .. MinLevelGear .. ")")
        end
    
        -- Deprecated items filter
        if not AllowDeprecated then
            table.insert(conditions, "(flags & 16) = 0")
            table.insert(conditions, "NOT (class = 8 and subclass = 0)")
            table.insert(conditions, "NOT (class = 10 and subclass = 0)")
            table.insert(conditions, "NOT ((class = 11 and subclass = 0) OR (class = 11 and subclass = 1))")
        
            -- Consolidated name exclusions
            local nameExclusions = {
                "'%OLD%'", "'%NPC%'", "'%QA%'", "'%enchant ring%'", "'%tablet%'", "'%throwing dagger%'",
                "'%shot pouch%'", "'%brimstone%'", "'%small pouch%'", "'%stormjewel%'", "'%dye%'",
                "'%feathers of azeroth%'", "'%broken%throwing%'", "'%northrend meat%'", "'%ironwood seed%'",
                "'%stranglethorn seed%'", "'%simple wood%'", "'%small sack of coins%'", "'%slimy bag%'",
                "'%bleach%'", "'%oozing bag%'", "'%Pale Skinner%'", "'%Pioneer Buckler%'", "'%locust wing%'",
                "'%community token%'", "'%thick citrine%'", "'%brilliant citrine%'", "'%nightbloom lilac%'",
                "'%flour%'", "'%brew%'", "'%[PH]%'", "'%(PH)%'", "'%fishing -%'", "'%Sandy Scorpid Claw%'",
                "'% caster %'", "'%Jeweler''s Kit%'", "'%nightmare berries%'", "'%parchment%'",
                "'%light quiver%'", "'%honey%'", "'%explosive shell%'", "'%envelope%'", "'%equipment kit%'",
                "'%/%'", "'%2.0%'", "'%creeping anguish%'", "'%felcloth bag%'", "'%elementium ore%'",
                "'%unused%'", "'%lava core%'", "'%fiery core%'", "'%sulfuron ingot%'", "'%sak%'",
                "'%gigantique%'", "'%portable hole%'", "'%deptecated%'", "'%durability%'", "'%big sack%'",
                "'%decoded%'", "'%knowledge:%'", "'%manual%'", "'%gnome head%'", "'%box of%'",
                "'%Light Feather%'", "'%Pet Stone%'", "'%Ogrela%'", "'%cache of%'", "'%summoning%'",
                "'%cut %'", "'%turtle egg%'", "'%jillian%'", "'%heavy crate%'", "'%plain letter%'",
                "'%sack of gems%'", "'%plans: darkspear%'", "'%beetle husk%'", "'%froststeel bar%'",
                "'%firefly dust%'", "'%of swords%'", "'%gnomish alarm%'", "'%tome%'", "'%ornate spyglass%'",
                "'%test%'", "'%darkmoon prize%'", "'%frostmourne%'", "'%codex%'", "'%the fall of ameth%'",
                "'%frostwolf artichoke%'", "'%symbol of kings%'", "'%symbol of divinity%'", "'%word of thawing%'",
                "'%grimoire%'", "'%deprecated%'", "'%cowardly flight%'", "'%book%'", "'%libram%'",
                "'%brazie''s%'", "'%guide%'", "'%glyphed breastplate%'", "'%weak flux%'", "'%leatherworking%'",
                "'%walnut stock%'", "'%virtuoso inking%'", "'%dictionary%'", "'%moonlit katana%'",
                "'%Omar%'", "'%depleted%'", "'%bottomless inscription bag%'", "'%90 Epic%'", "'%90 Blue%'",
                "'%90 Green%'", "'%blood shard%'", "'%dampscale basilisk eye%'", "'%evil bat eye%'",
                "'%package%'", "'%signet of beckoning%'", "'%silithid carapace%'", "'%smoke beacon%'",
                "'%shadoweave belt%'", "'%snickerfang jowl%'", "'%mojo%'", "'%singed%'"
            }
        
            table.insert(conditions, "UPPER(NAME) NOT LIKE " .. table.concat(nameExclusions, " AND UPPER(NAME) NOT LIKE "))
            table.insert(conditions, "NAME NOT LIKE '% Crate %' AND NAME NOT LIKE 'Crate %' AND NAME NOT LIKE '% Crate'")
            table.insert(conditions, "NOT (CLASS = 15 AND NAME LIKE '%throw%')")
            table.insert(conditions, "NOT (NAME LIKE '%broken%' AND NAME LIKE '%throwing%')")
        end
    end

    if #conditions > 0 then
        ItemTemplateQuery = ItemTemplateQuery .. " WHERE " .. table.concat(conditions, " AND ")
    end
end

local function CheckAuctions(houseId, callback)
    CharDBQueryAsync(string.format("SELECT COUNT(*) FROM auctionhouse WHERE itemowner IN (%s) and houseid = %d", botList, houseId),
    function(countResult)
        local count
        if countResult then
            count = tonumber(countResult:GetUInt64(0)) or 0
            postedAuctions[houseId] = count
        else
            count = 0
        end
        callback(count)
    end)
end

-- Weighted item pools, built once from itemCache on first use. Each pool lists every item once and
-- caps how many times an item may be picked per cycle, instead of storing an item once per weight point.
-- Gear and consumables are split into level brackets so listings can follow active players' levels.
local itemPools
local playerLevelShares -- Share of recently active players per level bracket, refreshed every sell cycle

local function GetLevelBracket(level)
    return math.min(8, math.floor(level / 10)) -- 0-9, 10-19, ... 70-79, 80
end

local function IsInList(list, value)
    if not list then return false end
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

local function BuildItemPools()
    local pools = {}
    local poolsByKey = {}

    local function addToPool(category, weight, item, maxPicks, bracket)
        maxPicks = math.floor(maxPicks or 0)
        if not weight or weight <= 0 or maxPicks < 1 then return end
        local key = bracket and (category .. "_" .. bracket) or category
        local pool = poolsByKey[key]
        if not pool then
            pool = {category = category, bracket = bracket, weight = weight, items = {}, maxPicks = {}, totalPicks = 0, usesCount = false}
            poolsByKey[key] = pool
            table.insert(pools, pool)
        end
        table.insert(pool.items, item)
        pool.maxPicks[item] = maxPicks
        pool.totalPicks = pool.totalPicks + maxPicks
    end

    for _, item in pairs(itemCache) do
        local bracket = GetLevelBracket(item.RequiredLevel)
        if ItemWeights.SpecificItems[item.entry] then
            local weight = ItemWeights.SpecificItems[item.entry]
            addToPool("SpecificItems", weight, item, weight)
        elseif item.class == 2 or item.class == 4 then
            local weight = ItemWeights.Gear[getQualityString(item.Quality)]
            addToPool("Gear" .. item.Quality, weight, item, weight, bracket)
        elseif item.class == 7 then
            local weight = ItemWeights.Mats[getQualityString(item.Quality)]
            addToPool("Mats" .. item.Quality, weight, item, weight)
        elseif item.class == 0 then
            addToPool("Consumable", ItemWeights.Consumable, item, ItemWeights.Consumable, bracket)
        elseif item.class == 3 then
            addToPool("Gem", ItemWeights.Gem, item, ItemWeights.Gem)
        elseif item.class == 9 then
            addToPool("Recipe", ItemWeights.Recipe, item, ItemWeights.Recipe)
        elseif item.class == 1 or item.class == 11 then
            addToPool("Container", ItemWeights.Container, item, ItemWeights.Container)
        elseif item.class == 15 and item.subclass == 2 then
            addToPool("Companion", ItemWeights.Companion, item, ItemWeights.Companion)
        elseif item.class == 6 then
            addToPool("Projectile", ItemWeights.Projectile, item, ItemWeights.Projectile)
        elseif item.class == 16 then
            addToPool("Glyph", ItemWeights.Glyph, item, ItemWeights.Glyph)
        else
            addToPool("Other", ItemWeights.Other, item, ItemWeights.Other)
        end
    end

    -- Specific items are weighted by how many picks they have left, as each item has its own weight
    if poolsByKey.SpecificItems then
        poolsByKey.SpecificItems.usesCount = true
    end

    -- Item count per category, to split a category's weight between its level brackets
    local categoryItems = {}
    for _, pool in ipairs(pools) do
        if pool.bracket then
            categoryItems[pool.category] = (categoryItems[pool.category] or 0) + #pool.items
        end
    end
    for _, pool in ipairs(pools) do
        if pool.bracket then
            pool.itemShare = #pool.items / categoryItems[pool.category]
        end
    end

    return pools
end

-- Weight of a level bracket pool: its category weight split by item count, shifted towards active players' levels
local function GetBracketPoolWeights()
    local weights = {}
    local playerShareTotals = {}
    local strength = (MatchPlayerLevels and playerLevelShares) and MatchPlayerLevels or 0

    if strength > 0 then
        for _, pool in ipairs(itemPools) do
            if pool.bracket then
                playerShareTotals[pool.category] = (playerShareTotals[pool.category] or 0) + (playerLevelShares[pool.bracket] or 0)
            end
        end
    end

    for i, pool in ipairs(itemPools) do
        if pool.bracket then
            local share = pool.itemShare
            local playerTotal = playerShareTotals[pool.category]
            if strength > 0 and playerTotal and playerTotal > 0 then
                share = (1 - strength) * share + strength * (playerLevelShares[pool.bracket] or 0) / playerTotal
            end
            weights[i] = pool.weight * share
        end
    end
    return weights
end

local function SelectRandomItems(batchSize)
    if not itemPools then itemPools = BuildItemPools() end

    -- Per-cycle state: items [1, available] of each pool can still be picked
    local available = {}
    local picksLeft = {}
    for i, pool in ipairs(itemPools) do
        available[i] = #pool.items
        picksLeft[i] = pool.totalPicks
    end
    local bracketWeights = GetBracketPoolWeights()
    local timesPicked = {}

    local selectedItems = {}
    while #selectedItems < batchSize do
        local totalWeight = 0
        local cumWeights = {}
        for i, pool in ipairs(itemPools) do
            if available[i] > 0 then
                totalWeight = totalWeight + (bracketWeights[i] or (pool.usesCount and picksLeft[i]) or pool.weight)
            end
            cumWeights[i] = totalWeight
        end

        if totalWeight <= 0 then break end

        -- Select weighted random pool, then a random item within it
        local rand = math.random() * totalWeight
        for i, pool in ipairs(itemPools) do
            if available[i] > 0 and rand <= cumWeights[i] then
                local items = pool.items
                local itemIndex = math.random(1, available[i])
                local item = items[itemIndex]
                table.insert(selectedItems, item)

                -- Popular items get a few extra listings, posted at slightly increasing prices
                if IsInList(MultiListClasses, item.class) and MaxExtraListings and MaxExtraListings > 0 and math.random(100) <= MultiListChance then
                    for _ = 1, math.random(1, MaxExtraListings) do
                        if #selectedItems >= batchSize then break end
                        table.insert(selectedItems, item)
                    end
                end

                timesPicked[item] = (timesPicked[item] or 0) + 1
                picksLeft[i] = picksLeft[i] - 1
                if timesPicked[item] >= pool.maxPicks[item] then
                    -- Swap the exhausted item out of the available range (pool order doesn't matter)
                    items[itemIndex], items[available[i]] = items[available[i]], items[itemIndex]
                    available[i] = available[i] - 1
                end
                break
            end
        end
    end

    return selectedItems
end

---------------------------------------------------------------------------------
-- Cost Formulas
---------------------------------------------------------------------------------

function ChooseCostFormula(formulaNum, item)
    -- Set up base modifiers
    local q if item.Quality == 0 then q = 1 elseif item.Quality == 3 then q = 2.2 else q = item.Quality end
    local p if item.BuyPrice == 0 then if item.ItemLevel > 150 then p = item.ItemLevel/30 else p = 1 end elseif item.class == 2 then p = item.BuyPrice * 0.4 else p = item.BuyPrice * 0.8 end
    local s if item.SellPrice == 0 then if item.ItemLevel > 150 then s = item.ItemLevel/30 else s = 1 end elseif item.class == 2 then s = item.SellPrice * 0.4 else s = item.SellPrice * 0.8 end
    local l if item.ItemLevel == 0 then l = 1 elseif item.ItemLevel > 226 then l = item.ItemLevel * 2.5 else l = item.ItemLevel end
                            
    if AHBotItemDebug then
        print("- Quality (q) type:", type(q), "Value:", q)
        print("- BuyPrice (p) type:", type(p), "Value:", p)
        print("- SellPrice (s) type:", type(s), "Value:", s)
        print("- ItemLevel (l) type:", type(l), "Value:", l)
        print("- Entry type:", type(item.entry), "Value:", item.entry)
    end
    
    -- Choose formula based on input
    if formulaNum == 1 then
        local price = (q / 3 * p / 10 * l * 1.2)
        
        -- Cap weapons at 2M ± 20%
        if item.class == 2 and price > 2000000 then
            local variance = 2000000 * 0.05
            price = 2000000 + math.random(-variance, variance)
        elseif item.entry == 50182 then -- Blood Queen's Choker should probably be more expensive than other BoEs
            price = price * 3
        end
        
        return price
    elseif formulaNum == 2 then
        return (q * p * s * l * item.entry) / 100000
    elseif formulaNum == 3 then
        return (q * q * l * item.RequiredLevel * 1.5) * 100
    elseif formulaNum == 4 then
        return ((q + l) * (item.RequiredLevel + 50) * (p + s) / 1000) * 
               (item.ItemLevel > 200 and 2 or 1)
    elseif formulaNum == 5 then
        local qualityMod = q * (item.Quality >= 3 and 1.5 or 1)
        local levelMod = (item.RequiredLevel / 10) * (item.ItemLevel / 50)
        local priceMod = ((p + s) / 1000) * (item.BuyPrice > 100000 and 1.3 or 1)
        return qualityMod * levelMod * priceMod * 10000
    else
        return math.random(1000, 1000000)
    end
end

-- Market price factors per auction house and item entry, persisted in ahbot_market
local marketFactors = {}

local function GetMarketFactor(houseId, entry)
    return (marketFactors[houseId] and marketFactors[houseId][entry]) or 1
end

-- Price a bot would list one unit of the item at, before market and auction house factors. Shared by seller and buyer.
local function CalculateItemCost(item, formula)
    local cost = ChooseCostFormula(formula, item)
    
    -- Item type price adjustments
    if RecipePriceAdjustment and item.class == 9 and not item.name:find("Design:") then 
        cost = cost * RecipePriceAdjustment 
    end
    
    if GemPriceAdjustment and item.class == 3 then 
        cost = cost * GemPriceAdjustment * (1 + (math.random() * 0.4 - 0.2)) 
    end
    
    if UndervaluedItemAdjust and cost < 50000 then 
        if ((item.class == 7 and item.entry > 40000) or (item.name:find("VIII"))) and not (item.Quality > 2 or item.entry == 41511) then 
            cost = cost * UndervaluedItemAdjust 
        end 
    end
    
    -- Failsafe for extremely low costs: base cheap items on their vendor price, like players do
    if not cost or cost < 1000 then 
        if item.SellPrice > 0 then
            cost = math.max(cost or 0, item.SellPrice * randomFloatBetween(VendorPriceMultiplier[1], VendorPriceMultiplier[2]))
        else
            cost = math.random(10000, 100000) 
        end
    end
    -- Nobody lists below what a vendor pays
    cost = math.max(cost, item.SellPrice * 1.25)
    
    -- Special handling for high-level bracers
    if item.class == 4 and item.ItemLevel > 200 and item.InventoryType == 9 and item.bonding == 2 then 
        if cost < 500000 then cost = cost * 100 end 
    end 
    
    -- Handle pets and glyphs
    if LowPriceFloor then
        if (((item.class == 15 and item.subclass == 2) or (item.class == 16)) and cost < 200000) then 
            cost = LowPriceFloor * (math.random() * 0.6 + 0.7) 
        end
    elseif UndervaluedItemAdjust then 
        if (((item.class == 15 and item.subclass == 2) or (item.class == 16)) and cost < 200000) then 
            cost = cost * UndervaluedItemAdjust 
        end 
    end
    
    -- Adjusted ammo prices
    if AdjustedAmmoPrices and item.class == 6 then
        local ammoPrices = {
            [1] = {150, 5000},
            [2] = {10000, 100000},
            [3] = {100000, 150000},
            [4] = {200000, 350000},
            [5] = {350000, 1000000}
        }
        local priceRange = ammoPrices[item.Quality]
        if priceRange then
            -- Ranges are per full stack, cost is per unit
            cost = math.random(priceRange[1], priceRange[2]) / math.max(1, item.stackable)
        end
    end
    
    return cost
end

---------------------------------------------------------------------------------
-- AH Bot Buyer Script
---------------------------------------------------------------------------------

local auctionReadyTimes = {} -- [auction id:item guid] = time from which bots will consider buying the auction

local function IsBot(guid)
    for _, bot in ipairs(AHBots) do
        if bot == guid then return true end
    end
    return false
end

-- Picks a bot to buy or bid on an auction, never the seller or the current highest bidder
local function PickBuyerBot(auction)
    local candidates = {}
    for _, bot in ipairs(AHBots) do
        if bot ~= auction.itemowner and bot ~= auction.buyguid then
            table.insert(candidates, bot)
        end
    end
    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

local function IsAuctionReadyToBuy(auction, now)
    local key = auction.id .. ":" .. auction.itemguid
    local readyAt = auctionReadyTimes[key]
    if not readyAt then
        readyAt = now + math.random(BuyDelayMin, math.max(BuyDelayMin, BuyDelayMax)) * 60
        auctionReadyTimes[key] = readyAt
    end
    return now >= readyAt
end

-- On startup the seller hands over to the buyer, which must load the new auctions even if it buys nothing
local function FinishBuyCycleWithoutTransactions()
    if BuyOnStartup and SellOnStartup then
        BuyOnStartup = false
        SendMessageToGMs("No eligible items to buy. Loading in new auctions...")
        RunCommand("reload auctions")
    end
    BuyOnStartup = false
end

local function AHBot_Buy_ProcessItemResults(itemResults, auctionResults)
    if not itemResults then return FinishBuyCycleWithoutTransactions() end
    
    local itemEntries = {}
    local stackSizes = {}
    repeat
        local guid = itemResults:GetUInt32(0)
        local itemEntry = itemResults:GetUInt32(1)
        local stackSize = itemResults:GetUInt32(2)
        itemEntries[guid] = itemEntry
        stackSizes[guid] = stackSize
    until not itemResults:NextRow()
    
    -- Group auctions by item entry, so only items that are actually listed get evaluated
    local auctionsByEntry = {}
    for _, auction in ipairs(auctionResults) do
        local entry = itemEntries[auction.itemguid]
        if entry and itemCache[entry] then
            auctionsByEntry[entry] = auctionsByEntry[entry] or {}
            table.insert(auctionsByEntry[entry], auction)
        end
    end

    local underpricedItems = {}
    for entry, auctions in pairs(auctionsByEntry) do
        local item = itemCache[entry]
        if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Evaluating item " .. item.entry .. " for price calculation") end
        
        local validItem = false
        if ItemLevelLimit then
            if item.ItemLevel < ItemLevelLimit then 
                validItem = true 
                if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Item " .. item.entry .. " meets level requirement of " .. ItemLevelLimit) end
            end
        end

        if validItem then
            if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Calculating price for valid item " .. item.entry) end
            -- Bots value items at what they would list them for themselves
            local baseCost = CalculateItemCost(item, BuyerCostFormula) * BotsPriceTolerance

            for _, auction in ipairs(auctions) do
                local cost = baseCost * (HousePriceModifiers[auction.houseid] or 1)
                if MarketPrices then
                    cost = cost * GetMarketFactor(auction.houseid, item.entry)
                end
                if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Final adjusted cost for item " .. item.entry .. " in house " .. auction.houseid .. ": " .. cost) end
                local count = stackSizes[auction.itemguid]
                local stackCost = cost * count
                -- Auctions without a buyout are judged by their current bid
                local askingPrice = auction.buyoutprice > 0 and auction.buyoutprice or math.max(auction.startbid, auction.lastbid)
                if askingPrice < stackCost then
                    if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Buyer - Found underpriced item " .. count .. "x " .. item.name .. " (" .. item.entry .. ") at " .. askingPrice .. " vs calculated " .. stackCost .. (count > 1 and " (" .. count .. "x " .. cost .. ")" or "")) end
                    table.insert(underpricedItems, {
                        entry = item.entry,
                        auctionId = auction.id,
                        value = stackCost,
                        dealRatio = stackCost / math.max(1, askingPrice)
                    })
                else
                    if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Buyer - Not buying " .. count .. "x " .. item.name .. " (" .. item.entry .. ") at " .. askingPrice .. " vs calculated " .. stackCost .. (count > 1 and " (" .. count .. "x " .. cost .. ")" or "")) end
                end
            end
        end
    end

    if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - Found " .. #underpricedItems .. " underpriced items to roll buyout/bid on.") end
    
    if #underpricedItems == 0 then return FinishBuyCycleWithoutTransactions() end

    AHBot_Buy_ProcessTransactions(underpricedItems, auctionResults)
end

function AHBot_Buy_ProcessTransactions(underpricedItems, auctionResults)
    local transactions = {}
    local auctionsById = {}
    for _, auction in ipairs(auctionResults) do
        auctionsById[auction.id] = auction
    end
    
    -- Random order, so a buy limit doesn't always favour the same auctions
    for i = #underpricedItems, 2, -1 do
        local j = math.random(1, i)
        underpricedItems[i], underpricedItems[j] = underpricedItems[j], underpricedItems[i]
    end

    for _, item in ipairs(underpricedItems) do
        if MaxBuysPerCycle and #transactions >= MaxBuysPerCycle then break end
        if AHBotItemDebug then print("[Eluna AH Bot Debug]: Processing transaction chances for item " .. item.entry) end
        
        local buyoutRoll = math.random(1, 100)
        local bidRoll = math.random(1, 100)
        
        -- Ensure rolls don't exceed 100% combined probability
        if buyoutRoll + bidRoll > 100 then
            bidRoll = 100 - buyoutRoll
            if AHBotItemDebug then print("[Eluna AH Bot Debug]: Adjusted bid roll for item " .. item.entry .. " to " .. bidRoll) end
        end

        local matchingAuction = auctionsById[item.auctionId]
        local buyerBot = matchingAuction and PickBuyerBot(matchingAuction)

        if buyerBot then
            -- Better deals are likelier to be bought, other bots' auctions less likely than players'
            local chanceFactor = math.max(1, math.min(DealChanceMultiplier or 1, item.dealRatio))
            if IsBot(matchingAuction.itemowner) then
                chanceFactor = chanceFactor * BotToBotBuyFactor
            end

            local transactionType = nil
            if matchingAuction.buyoutprice > 0 and buyoutRoll <= PlaceBuyoutChance * chanceFactor then
                transactionType = "buyout"
            elseif bidRoll <= PlaceBidChance * chanceFactor then
                transactionType = "bid"
            end

            if transactionType then
                local price
                
                if transactionType == "buyout" then
                    price = matchingAuction.buyoutprice
                else  -- bid, which must beat the current bid
                    local minBid = math.max(matchingAuction.startbid * 1.10, matchingAuction.lastbid * 1.05 + 1)
                    local maxBid
                    if matchingAuction.buyoutprice > 0 then
                        minBid = math.max(minBid, matchingAuction.buyoutprice * 0.60)
                        maxBid = matchingAuction.buyoutprice * 0.95
                    else
                        maxBid = item.value
                    end

                    if minBid < maxBid then
                        price = math.floor(randomFloatBetween(minBid, maxBid))
                    elseif matchingAuction.buyoutprice > 0 then -- If no valid bid range exists, default to buyout
                        transactionType = "buyout"
                        price = matchingAuction.buyoutprice
                    end
                end
                
                if price then
                    table.insert(transactions, {
                        transactionType = transactionType,
                        entry = item.entry,
                        itemGuid = matchingAuction.itemguid,
                        auctionId = matchingAuction.id,
                        itemOwner = matchingAuction.itemowner,
                        buyer = buyerBot,
                        price = price,
                        houseid = matchingAuction.houseid
                    })
                end
            end
        end
    end
    
    if #transactions > 0 then
        AHBot_Buy_ExecuteTransactions(transactions)
    else
        FinishBuyCycleWithoutTransactions()
    end
end

function AHBot_Buy_ExecuteTransactions(transactions)
    local ids = {}
    local buyguidCases = {}
    local lastbidCases = {}
    local timeCases = {}

    for _, transaction in ipairs(transactions) do
        table.insert(buyguidCases, "WHEN " .. transaction.auctionId .. " THEN " .. transaction.buyer)
        table.insert(lastbidCases, "WHEN " .. transaction.auctionId .. " THEN " .. transaction.price)
        table.insert(ids, transaction.auctionId)

        if transaction.transactionType == "buyout" then
            table.insert(timeCases, "WHEN " .. transaction.auctionId .. " THEN " .. os.time())
        else
            table.insert(timeCases, "WHEN " .. transaction.auctionId .. " THEN time")
        end
    end

    local query = "UPDATE auctionhouse SET " ..
                  "buyguid = CASE id " .. table.concat(buyguidCases, " ") .. " END, " ..
                  "lastbid = CASE id " .. table.concat(lastbidCases, " ") .. " END, " ..
                  "time = CASE id " .. table.concat(timeCases, " ") .. " END " ..
                  "WHERE id IN(" .. table.concat(ids, ",") .. ")"

    BuyOnStartup = false
    CharDBQueryAsync(query, function()
        SendMessageToGMs("Refreshing auctions cache to pick up new bot transactions...")
        RunCommand("reload auctions")
        if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - Finished placing " .. #transactions .. " buyouts/bids.") end
    end)
end

local function AHBot_Buy_ProcessAuctionResults(results)
    if not results then return FinishBuyCycleWithoutTransactions() end
    
    local now = os.time()
    local auctionResults = {}
    
    repeat
        local auction = {
            id = results:GetUInt32(0),
            itemguid = results:GetUInt32(1),
            houseid = results:GetUInt32(2),
            itemowner = results:GetUInt32(3),
            buyoutprice = results:GetUInt32(4),
            buyguid = results:GetUInt32(5),
            lastbid = results:GetUInt32(6),
            startbid = results:GetUInt32(7),
            bidtime = results:GetUInt32(8)
        }

        -- Skip auctions that were only just listed, and auctions with bids bots shouldn't fight over
        local bidAllowed = auction.buyguid == 0
            or not DisableBidFight
            or (BotsOutbidBots and IsBot(auction.buyguid))
        if bidAllowed and IsAuctionReadyToBuy(auction, now) then
            table.insert(auctionResults, auction)
        end
    until not results:NextRow()

    -- Forget auctions that are long gone (auctions last at most 48 hours)
    for key, readyAt in pairs(auctionReadyTimes) do
        if readyAt < now - 3 * 24 * 3600 then
            auctionReadyTimes[key] = nil
        end
    end
    
    if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - Found " .. #auctionResults .. " potential auctions to process") end

    if #auctionResults == 0 then return FinishBuyCycleWithoutTransactions() end

    -- Get item entries for all auction item GUIDs
    local itemGuids = {}
    for _, auction in ipairs(auctionResults) do
        table.insert(itemGuids, auction.itemguid)
    end

    local itemQuery = string.format("SELECT guid, itemEntry, count FROM item_instance WHERE guid IN (%s)", table.concat(itemGuids, ","))
    CharDBQueryAsync(itemQuery, function(itemResults)
        AHBot_Buy_ProcessItemResults(itemResults, auctionResults)
    end)
end

local function AHBot_BuyAuction()
    -- Random sample, so bots look at different auctions every cycle
    local query
    if BotsBuyFromBots then
        query = string.format("SELECT id, itemguid, houseid, itemowner, buyoutprice, buyguid, lastbid, startbid, time FROM auctionhouse WHERE houseid IN (%s) ORDER BY RAND() LIMIT %d", houseList, ActionsPerCycle)
        if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - Starting buy cycle including bot sellers") end
    else
        query = string.format("SELECT id, itemguid, houseid, itemowner, buyoutprice, buyguid, lastbid, startbid, time FROM auctionhouse WHERE itemowner NOT IN (%s) AND houseid IN (%s) ORDER BY RAND() LIMIT %d", botList, houseList, ActionsPerCycle)
        if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - Starting buy cycle excluding bot sellers") end
    end
    
    CharDBQueryAsync(query, AHBot_Buy_ProcessAuctionResults)
end

---------------------------------------------------------------------------------
-- AH Bot Seller Script
---------------------------------------------------------------------------------

local currentHouse = 0
local lastAuctionId


local function PickWeighted(weights)
    local total = 0
    for _, weight in pairs(weights) do total = total + weight end
    if total <= 0 then return nil end
    local rand = math.random() * total
    for value, weight in pairs(weights) do
        rand = rand - weight
        if rand <= 0 then return value end
    end
    return next(weights)
end

local function CalculateStackSize(item, unitCost)
    local stack = 1
    
    if item.class == 6 and AlwaysMaxStackAmmo then
        stack = item.stackable
    elseif item.stackable > 1 and IsInList(StackedItemClasses, item.class) then
        -- Players post a handful of common stack sizes, and cheap materials mostly in full stacks
        local weights = {}
        for size, weight in pairs(StackSizeWeights) do
            if size == "full" then
                weights[item.stackable] = (weights[item.stackable] or 0) + ((unitCost < CheapItemPrice) and CheapFullStackWeight or weight)
            elseif size < item.stackable then
                weights[size] = (weights[size] or 0) + weight
            end
        end
        stack = PickWeighted(weights) or 1
    end
    
    return stack
end

-- Rounds a price the way players type it, e.g. 4g 95s or 24g 99s 99c instead of 4g 37s 12c
local function HumanizePrice(price)
    price = math.floor(price)
    if not HumanizePrices or price < 1000 then return math.max(1, price) end

    local unit
    if price < 10000 then unit = 100            -- Under 1g: whole silver
    elseif price < 100000 then unit = 500       -- Under 10g: 5 silver steps
    elseif price < 1000000 then unit = 10000    -- Under 100g: whole gold
    elseif price < 10000000 then unit = 50000   -- Under 1000g: 5 gold steps
    else unit = 100000 end                      -- Above: 10 gold steps

    local rounded = math.max(unit, math.floor(price / unit + 0.5) * unit)
    local roll = math.random(100)
    if roll <= 25 then
        rounded = rounded - 1                   -- 24g 99s 99c
    elseif roll <= 50 then
        rounded = rounded - unit / 20           -- 24g 95s
    end
    return math.floor(rounded)
end

local function PickAuctionDuration()
    return (PickWeighted(AuctionDurations) or 24) * 3600
end

local lowestBotUnitPrices = {}    -- Lowest unit buyout per item entry from bots, in the house being stocked, refreshed per house each cycle
local lowestPlayerUnitPrices = {} -- Same, from players

local function ProcessItemCreation(selectedItems, houseId, availableGuids, availableIds)
    local itemQueryParts = {}
    local auctionQueryParts = {}
    local listingQueryParts = {}
    local batchListings = {} -- Listings posted this batch per item entry, for extra listings of the same item
    local auctionCount = 0
    
    for _, item in ipairs(selectedItems) do
        if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Processing item "..item.name) end
        
        local isAllowed = IsItemAllowedForHouse(item, houseId)
        
        if not isAllowed then
            if AHBotItemDebug then print("[Eluna AH Bot Item Debug]: Removing item " .. item.name .. " from queue due to belonging to another faction than auction house ID "..houseId) end
        else
            auctionCount = auctionCount + 1
            lastItemId = availableGuids[1]
            table.remove(availableGuids, 1)
            lastAuctionId = availableIds[1]
            table.remove(availableIds, 1)
            
            local randomBot = AHBots[math.random(1, #AHBots)]
            local creator = (item.craftedBy == 1) and randomBot or 0
            local expireTime = os.time() + PickAuctionDuration()
            local cost, stack, undercut

            local previous = batchListings[item.entry]
            if previous then
                -- Extra listing of the same item: same stack size, slightly above the previous listing
                stack = previous.stack
                cost = previous.cost * randomFloatBetween(1.01, 1.04)
            else
                local unitCost = CalculateItemCost(item, SellerCostFormula) * (HousePriceModifiers[houseId] or 1)
                if MarketPrices then
                    unitCost = unitCost * GetMarketFactor(houseId, item.entry)
                end
                stack = CalculateStackSize(item, unitCost)
                cost = unitCost * stack

                if SellPriceVariance then
                    cost = cost * randomFloatBetween(1 - (SellPriceVariance/100), 1 + (SellPriceVariance/100))
                end

                -- Undercut the lowest listing of this item, within limits of the bot's own price
                local ownCost = cost
                local lowestPlayerUnit = lowestPlayerUnitPrices[item.entry]
                local lowestUnit = lowestBotUnitPrices[item.entry]
                if UndercutPlayers and lowestPlayerUnit and (not lowestUnit or lowestPlayerUnit < lowestUnit) then
                    lowestUnit = lowestPlayerUnit
                end
                if lowestUnit and UndercutChance and math.random(100) <= UndercutChance then
                    local lowestTotal = lowestUnit * stack
                    local target = lowestTotal * (1 - randomFloatBetween(UndercutRange[1], UndercutRange[2]) / 100)
                    cost = math.max(cost * UndercutLimits[1], math.min(cost * UndercutLimits[2], target))
                    if cost < lowestTotal then
                        cost = HumanizePrice(cost)
                        if cost >= lowestTotal then cost = math.max(1, math.floor(lowestTotal) - 1) end
                        undercut = true
                    end
                end

                -- Don't list below players, unless their price is beyond what the bot would ask
                if not UndercutPlayers and lowestPlayerUnit then
                    local playerTotal = lowestPlayerUnit * stack
                    if cost < playerTotal and playerTotal <= ownCost * UndercutLimits[2] then
                        cost = math.max(math.ceil(playerTotal), HumanizePrice(playerTotal * randomFloatBetween(1.0, 1.05)))
                        undercut = true
                    end
                end
            end

            if not undercut then cost = HumanizePrice(cost) end
            batchListings[item.entry] = {stack = stack, cost = cost}
            local startBid = math.max(1, math.min(cost - 1, HumanizePrice(cost * (math.random(51, 90) / 100))))
            
            local randomStats, enchantString = EnchantmentModule.ApplyRandomEnchantments(item)
            
            -- Add item_instance entry
            table.insert(itemQueryParts, "(" .. lastItemId .. ", " .. item.entry .. ", " .. randomBot .. ", " .. creator .. ", 0, " .. stack .. ", 0, '" ..
                item.c1 .. " " .. item.c2 .. " " .. item.c3 .. " " .. item.c4 .. " " .. item.c5 .. "', 0, '"..enchantString.."', " ..
                randomStats .. ", " .. item.durability .. ", "..item.duration..", '')")

            -- Add auction entry
            table.insert(auctionQueryParts, string.format("(%d, %d, %d, %d, %d, %d, 0, 0, %d, 1, %d)",
                lastAuctionId, houseId, lastItemId, randomBot, cost, expireTime, startBid, AddedByEluna))

            -- Track the listing to learn from whether it sells
            table.insert(listingQueryParts, string.format("(%d, %d, %d, %d, %d)", lastAuctionId, lastItemId, houseId, item.entry, expireTime))
        end
    end
    
    if #itemQueryParts > 0 and #auctionQueryParts > 0 then
        local itemQuery = "INSERT INTO item_instance (guid, itemEntry, owner_guid, creatorGuid, giftCreatorGuid, count, duration, charges, flags, enchantments, randomPropertyId, durability, playedTime, text) VALUES " .. table.concat(itemQueryParts, ",")
        local auctionQuery = "INSERT INTO auctionhouse (id, houseid, itemguid, itemowner, buyoutprice, time, buyguid, lastbid, startbid, deposit, AddedByEluna) VALUES " .. table.concat(auctionQueryParts, ",")
        
        CharDBQueryAsync(itemQuery, function(results) -- Instantiate items in database
            CharDBQueryAsync(auctionQuery, function(results) -- Add auctions to database
                if MarketPrices then
                    CharDBExecute("REPLACE INTO ahbot_listings (id, itemguid, houseid, entry, expiretime) VALUES " .. table.concat(listingQueryParts, ","))
                end
                if AHBotActionDebug then 
                    print("[Eluna AH Bot Debug]: Seller - " .. auctionCount .. " auctions added to auction house no. " .. houseId .. ".") 
                end
                
                currentHouse = currentHouse - houseId
                
                if currentHouse == 0 then
                    if BuyOnStartup then
                        if AHBotActionDebug then 
                            print("[Eluna AH Bot Debug]: Seller - Done processing all included auction houses, proceeding to initiate buyers...") 
                        end
                        AHBot_BuyAuction()
                        SendMessageToGMs("AH bot sellers initiated. Starting buyers...")
                        return
                    end
                    
                    if AHBotActionDebug then 
                        print("[Eluna AH Bot Debug]: Seller - Done processing all included auction houses, instantiating auctions!") 
                    end
                    SendMessageToGMs("Refreshing auctions cache to pick up new bot auctions...")
                    RunCommand("reload auctions")
                    NextAHBotSellCycle = os.time() + AHSellTimer * 60 * 60
                    return
                end
                
                if AHBotActionDebug then 
                    print("[Eluna AH Bot Debug]: Seller - Scheduling processing of next house ID.") 
                end
                AddAuctions() -- Check if more auctions are scheduled in other auction houses
            end)
        end)
    end
end

local function ProcessAuctionIds(result, selectedItems, houseId, availableGuids)
    local availableIds = {}
    local maxId = 0
    local usedIds = {}
    local MaxIdNotAddedByEluna = 0
    local NotAddedByEluna
    local isEmpty = true
   
    if result then 
        repeat
            isEmpty = false
            local id = result:GetUInt32(0)
            local AddedByEluna = result:GetUInt32(1)
           
            usedIds[id] = true
            maxId = math.max(maxId, id)
           
            if AddedByEluna == 0 then
                MaxIdNotAddedByEluna = math.max(MaxIdNotAddedByEluna, id)
                NotAddedByEluna = true
            end
        until not result:NextRow() 
    end
    
    if MaxIdNotAddedByEluna == 0 then MaxIdNotAddedByEluna = maxId end
    
    if isEmpty then -- If table is empty, start from 10,000,000
        local nextId = 10000000
        while #availableIds < ActionsPerCycle do
            table.insert(availableIds, nextId)
            nextId = nextId + 1
        end
    else
        local upperBound = NotAddedByEluna and MaxIdNotAddedByEluna or maxId
        
        if NotAddedByEluna then -- Fill in gaps if there are non-Eluna auctions
            for i = 1, upperBound do
                if not usedIds[i] then
                    table.insert(availableIds, i)
                    if #availableIds >= ActionsPerCycle then
                        break
                    end
                end
            end
        else -- Continue from highest ID if only Eluna auctions exist
            local nextId = maxId + 1
            while #availableIds < ActionsPerCycle do
                table.insert(availableIds, nextId)
                nextId = nextId + 1
            end
        end
        
        -- Add more IDs if needed
        if #availableIds < ActionsPerCycle then
            local nextId = math.max(MaxIdNotAddedByEluna + 10000000, maxId + 1)
            while #availableIds < ActionsPerCycle do
                table.insert(availableIds, nextId)
                nextId = nextId + 1
            end
        end
    end
    
    ProcessItemCreation(selectedItems, houseId, availableGuids, availableIds)
end

-- Finds free item GUIDs in the database instead of loading every item_instance row into Lua.
-- Uses unused GUIDs below the current highest GUID first, then continues 10,000,000 above it.
local function ProcessItemGuids(selectedItems, houseId)
    CharDBQueryAsync("SELECT MIN(guid), MAX(guid), MAX(AddedByEluna) FROM item_instance", function(boundsResult)
        local minGuid, maxGuid, highestAddedByEluna = 0, 0, 0
        if boundsResult and not boundsResult:IsNull(0) then
            minGuid = boundsResult:GetUInt32(0)
            maxGuid = boundsResult:GetUInt32(1)
            highestAddedByEluna = boundsResult:GetUInt32(2)
        end

        local gapQuery = string.format([[
            SELECT guid, nextGuid FROM (
                SELECT guid, LEAD(guid) OVER (ORDER BY guid) AS nextGuid FROM item_instance
            ) g WHERE nextGuid > guid + 1 ORDER BY guid LIMIT %d]], ActionsPerCycle)

        CharDBQueryAsync(gapQuery, function(gapResult)
            local availableGuids = {}

            local function addRange(first, last)
                for guid = first, last do
                    if #availableGuids >= ActionsPerCycle then return end
                    table.insert(availableGuids, guid)
                end
            end

            if minGuid > 1 then addRange(1, minGuid - 1) end
            if gapResult then
                repeat
                    addRange(gapResult:GetUInt32(0) + 1, gapResult:GetUInt32(1) - 1)
                until #availableGuids >= ActionsPerCycle or not gapResult:NextRow()
            end

            -- Add more GUIDs if needed
            if #availableGuids < ActionsPerCycle then
                local nextGuid = (maxGuid > 0 and highestAddedByEluna > 0) and (maxGuid + 1) or (maxGuid + 10000000)
                addRange(nextGuid, nextGuid + ActionsPerCycle)
            end

            if AHBotActionDebug then 
                print("[Eluna AH Bot Debug]: Seller - Found " .. #availableGuids .. " available item GUIDs for next batch") 
            end

            CharDBQueryAsync("SELECT id, AddedByEluna FROM auctionhouse ORDER BY AddedByEluna DESC", function(result)
                ProcessAuctionIds(result, selectedItems, houseId, availableGuids)
            end)
        end)
    end)
end

local function ProcessAuctionCheck(auctionCount, houseId)
    if (auctionCount < MinAuctions) or (specificHouse or ((auctionCount < MaxAuctions) and (math.random(100) <= RepopulationChance))) then
        -- Post less at quiet hours, unless the auction house is running low
        local batchSize = ActionsPerCycle
        if HourlySellMultipliers and auctionCount >= MinAuctions then
            local multiplier = HourlySellMultipliers[tonumber(os.date("%H"))] or 1
            batchSize = math.max(1, math.floor(ActionsPerCycle * math.max(0, math.min(1, multiplier))))
        end
        local selectedItems = SelectRandomItems(batchSize)
        if AHBotActionDebug then print("[Eluna AH Bot Debug]: Seller - Item selection complete.") end

        lowestBotUnitPrices = {}
        lowestPlayerUnitPrices = {}
        local entries = {}
        local seen = {}
        for _, item in ipairs(selectedItems) do
            if not seen[item.entry] then
                seen[item.entry] = true
                table.insert(entries, item.entry)
            end
        end

        if #entries == 0 or not ((UndercutChance and UndercutChance > 0) or not UndercutPlayers) then
            return ProcessItemGuids(selectedItems, houseId)
        end

        -- Lowest unit buyout of each selected item in this house, from bots and from players
        CharDBQueryAsync(string.format("SELECT ii.itemEntry, a.buyoutprice, ii.count, a.itemowner FROM auctionhouse a JOIN item_instance ii ON ii.guid = a.itemguid WHERE a.houseid = %d AND a.buyoutprice > 0 AND ii.itemEntry IN (%s)", houseId, table.concat(entries, ",")), function(priceResult)
            if priceResult then
                repeat
                    local entry = priceResult:GetUInt32(0)
                    local unitPrice = priceResult:GetUInt32(1) / math.max(1, priceResult:GetUInt32(2))
                    local lowest = IsBot(priceResult:GetUInt32(3)) and lowestBotUnitPrices or lowestPlayerUnitPrices
                    if not lowest[entry] or unitPrice < lowest[entry] then
                        lowest[entry] = unitPrice
                    end
                until not priceResult:NextRow()
            end
            ProcessItemGuids(selectedItems, houseId)
        end)
    else
        if AHBotActionDebug then 
            print("[Eluna AH Bot Debug]: Seller - Action house at capacity (Min auctions: "..MinAuctions..". Current auctions: ".. tostring(auctionCount) .." / " .. MaxAuctions .. "). No action taken, awaiting next cycle on ".. os.date("%H:%M", NextAHBotSellCycle) .. " server time.") 
        end
        if BuyOnStartup then
            AHBot_BuyAuction()
        end
    end
end

function AddAuctions(specificHouse)
    local houseId = 0
    
    if specificHouse then currentHouse = specificHouse end
    
    if currentHouse == 15 or currentHouse == 13 or currentHouse == 9 or currentHouse == 7 then 
        houseId = 7
    elseif currentHouse == 8 or currentHouse == 6 then 
        houseId = 6
    elseif currentHouse == 2 then 
        houseId = 2 
    end
    
    if houseId == 0 then return end
    
    if AHBotActionDebug then 
        print("[Eluna AH Bot Debug]: Seller - Processing auctions for house ID: " .. houseId) 
    end
    
    CheckAuctions(houseId, function(auctionCount)
        ProcessAuctionCheck(auctionCount, houseId)
    end)
end

local marketFactorsLoaded = false

-- Raises the price factor of items whose bot listings sold and lowers it for those that expired unsold
local function UpdateMarketPrices(callback)
    if not MarketPrices then return callback() end

    if not marketFactorsLoaded then
        return CharDBQueryAsync("SELECT houseid, entry, factor FROM ahbot_market", function(result)
            if result then
                repeat
                    local houseId = result:GetUInt32(0)
                    marketFactors[houseId] = marketFactors[houseId] or {}
                    marketFactors[houseId][result:GetUInt32(1)] = result:GetFloat(2)
                until not result:NextRow()
            end
            marketFactorsLoaded = true
            UpdateMarketPrices(callback)
        end)
    end

    -- Remember listings that got a bid, as won bids only disappear when the auction ends
    CharDBQueryAsync("UPDATE ahbot_listings l JOIN auctionhouse a ON a.id = l.id AND a.itemguid = l.itemguid SET l.hasbid = 1 WHERE a.buyguid <> 0", function()
        CharDBQueryAsync("SELECT l.id, l.itemguid, l.houseid, l.entry, l.expiretime, l.hasbid FROM ahbot_listings l LEFT JOIN auctionhouse a ON a.id = l.id AND a.itemguid = l.itemguid WHERE a.id IS NULL", function(result)
            if not result then return callback() end

            local now = os.time()
            local finished = {}
            local changed = {}
            local sold, expired = 0, 0
            repeat
                local houseId = result:GetUInt32(2)
                local entry = result:GetUInt32(3)
                local wasSold = result:GetUInt32(5) == 1 or now < result:GetUInt32(4)

                marketFactors[houseId] = marketFactors[houseId] or {}
                local factor = marketFactors[houseId][entry] or 1
                if wasSold then
                    factor = factor * randomFloatBetween(1.03, 1.08)
                    sold = sold + 1
                else
                    factor = factor * randomFloatBetween(0.92, 0.97)
                    expired = expired + 1
                end
                marketFactors[houseId][entry] = math.max(MarketPriceLimits[1], math.min(MarketPriceLimits[2], factor))

                changed[houseId .. ":" .. entry] = {houseId, entry}
                table.insert(finished, "(" .. result:GetUInt32(0) .. ", " .. result:GetUInt32(1) .. ")")
            until not result:NextRow()

            local factorRows = {}
            for _, key in pairs(changed) do
                table.insert(factorRows, string.format("(%d, %d, %.4f)", key[1], key[2], marketFactors[key[1]][key[2]]))
            end
            CharDBExecute("REPLACE INTO ahbot_market (houseid, entry, factor) VALUES " .. table.concat(factorRows, ","))
            CharDBExecute("DELETE FROM ahbot_listings WHERE (id, itemguid) IN (" .. table.concat(finished, ",") .. ")")

            if AHBotActionDebug then print("[Eluna AH Bot Debug]: Seller - Market prices updated from " .. sold .. " sold and " .. expired .. " expired bot auctions.") end
            callback()
        end)
    end)
end

-- Counts recently active players per level bracket, so listings can follow their levels
local function RefreshPlayerLevels(callback)
    if not MatchPlayerLevels or MatchPlayerLevels <= 0 then return callback() end

    local since = os.time() - PlayerActivityDays * 24 * 3600
    CharDBQueryAsync(string.format("SELECT level FROM characters WHERE (online = 1 OR logout_time > %d) AND guid NOT IN (%s)", since, botList), function(result)
        local counts, total = {}, 0
        if result then
            repeat
                local bracket = GetLevelBracket(result:GetUInt32(0))
                counts[bracket] = (counts[bracket] or 0) + 1
                total = total + 1
            until not result:NextRow()
        end

        playerLevelShares = nil
        if total > 0 then
            playerLevelShares = {}
            for bracket, count in pairs(counts) do
                playerLevelShares[bracket] = count / total
            end
        end
        callback()
    end)
end

local function AHBot_SellItems(_, _, _, specificHouse)
    if not specificHouse then
        currentHouse = 0
        for _, houseId in ipairs(EnabledAuctionHouses) do
            currentHouse = currentHouse + houseId
        end
    else
        currentHouse = specificHouse
    end
    UpdateMarketPrices(function()
        RefreshPlayerLevels(function()
            AddAuctions(specificHouse)
        end)
    end)
end

---------------------------------------------------------------------------------
-- Clear bot mailboxes
---------------------------------------------------------------------------------

if ClearBotMailbox then
    CreateLuaEvent(function()
        for _, botGUIDLow in ipairs(AHBots) do
            local botOnline = false
            for _, player in pairs(GetPlayersInWorld()) do
                if player:GetGUIDLow() == botGUIDLow then
                    botOnline = true
                    break
                end
            end
            if not botOnline then
                -- One statement, so mail, attachments and the attached items are removed together
                CharDBExecute("DELETE m, mi, ii FROM mail m LEFT JOIN mail_items mi ON mi.mail_id = m.id LEFT JOIN item_instance ii ON ii.guid = mi.item_guid WHERE m.receiver = " .. botGUIDLow)
                CharDBExecute("DELETE mi, ii FROM mail_items mi LEFT JOIN item_instance ii ON ii.guid = mi.item_guid WHERE mi.receiver = " .. botGUIDLow)
            end
        end
    end, 60000, 0)

    -- Once per load, while no bot is logged in: remove bot items left behind by earlier mailbox clears, which only deleted the mail.
    -- Only items owned by a bot that are in no auction, mail, inventory or guild bank are removed.
    local anyBotOnline = false
    for _, player in pairs(GetPlayersInWorld()) do
        for _, botGUIDLow in ipairs(AHBots) do
            if player:GetGUIDLow() == botGUIDLow then anyBotOnline = true end
        end
    end
    if not anyBotOnline then
        CharDBExecute("DELETE ii FROM item_instance ii " ..
            "LEFT JOIN auctionhouse a ON a.itemguid = ii.guid " ..
            "LEFT JOIN mail_items mi ON mi.item_guid = ii.guid " ..
            "LEFT JOIN character_inventory ci ON ci.item = ii.guid " ..
            "LEFT JOIN guild_bank_item gbi ON gbi.item_guid = ii.guid " ..
            "WHERE ii.owner_guid IN (" .. botList .. ") AND a.itemguid IS NULL AND mi.item_guid IS NULL AND ci.item IS NULL AND gbi.item_guid IS NULL")
    end
end

---------------------------------------------------------------------------------
-- Initialize item_template cache and initial event scheduling
---------------------------------------------------------------------------------

local ItemTemplateSize = 0

CreateLuaEvent(function()
    WorldDBQueryAsync(ItemTemplateQuery, function(results)
        if AHBotActionDebug then print("[Eluna AH Bot]: Core - Caching item_template.") end
        if results then
            repeat
                local entry = results:GetUInt32(0)
                itemCache[entry] = {
                    entry = entry,
                    class = results:GetUInt32(1),
                    subclass = results:GetUInt32(2),
                    Quality = results:GetUInt32(3),
                    BuyPrice = results:GetUInt32(4),
                    SellPrice = results:GetUInt32(5),
                    InventoryType = results:GetUInt32(6),
                    AllowableClass = results:GetInt32(7),
                    ItemLevel = results:GetUInt32(8),
                    RequiredLevel = results:GetUInt32(9),
                    RequiredSkill = results:GetUInt32(10),
                    RequiredSkillRank = results:GetUInt32(11),
                    stackable = results:GetUInt32(12),
                    startquest = results:GetUInt32(13),
                    bonding = results:GetUInt32(14),
                    BagFamily = results:GetUInt32(15),
                    flags = results:GetUInt32(16),
                    name = results:GetString(17),
                    durability = results:GetUInt32(18),
                    ContainerSlots = results:GetUInt32(19),
                    RandomProperty = results:GetInt32(20),
                    c1 = results:GetInt32(21),
                    c2 = results:GetInt32(22),
                    c3 = results:GetInt32(23),
                    c4 = results:GetInt32(24),
                    c5 = results:GetInt32(25),
                    duration = results:GetUInt32(26),
                    race = results:GetInt32(27),
                    RandomSuffix = results:GetInt32(28),
                    craftedBy = 0
                }
                ItemTemplateSize = ItemTemplateSize + 1
            until not results:NextRow()
            if AHBotActionDebug then print("[Eluna AH Bot]: Core - Finished caching item_template. Valid items: "..ItemTemplateSize..".") end
            
            if SetAsCraftedBy then -- Split out of the query to not delay db ops
                for _, craftedItem in ipairs(craftedItems) do
                    if itemCache[craftedItem] then
                        itemCache[craftedItem].craftedBy = 1
                    end
                end
            end
            
            if EnableSeller then
                WorldDBQueryAsync("SELECT * FROM item_enchantment_template", function(results)
                    if results then
                        -- Initialize the ItemRandomProperty table if it doesn't exist
                        ItemRandomProperty = ItemRandomProperty or {}
                        
                        repeat
                            local entry = results:GetUInt32(0)
                            local ench = results:GetUInt32(1)
                            local chance = results:GetFloat(2)
                            -- Initialize the entry table only once
                            if not ItemRandomProperty[entry] then
                                ItemRandomProperty[entry] = {}
                            end
                            
                            -- Add the new enchantment data
                            table.insert(ItemRandomProperty[entry], {
                                ench = ench,
                                chance = chance
                            })
                        until not results:NextRow()
                        
                        if AHBotActionDebug then 
                            print("[Eluna AH Bot Debug]: Seller - Finished caching item_enchantment_template.") 
                        end
                        
                        if SellOnStartup then
                            AHBot_SellItems()
                        end
                    end
                end)
            end
        end
    end)
end, StartupDelay + 100) -- The core may crash if we get MySQL locked from other scripts querying database on load/reload Eluna. Adding slight delay in case StartupDelay is 0.

if EnableSeller then
    AHBotSellEventId = CreateLuaEvent(AHBot_SellItems, AHSellTimer * 60 * 60 * 1000, 0)
    NextAHBotSellCycle = os.time() + AHSellTimer * 60 * 60
    if AHBotActionDebug then print("[Eluna AH Bot Debug]: Seller - AH Bot seller system initialized. Actions scheduled on every " .. AHSellTimer .. " hour(s).") end
end

if EnableBuyer then
    AHBotBuyEventId = CreateLuaEvent(AHBot_BuyAuction, AHBuyTimer * 65 * 60 * 1000, 0) -- 5 minutes after seller bots to not cause overlapping lag
    if AHBotActionDebug then print("[Eluna AH Bot Debug]: Buyer - AH Bot buyer system initialized. Actions scheduled on every " .. AHBuyTimer .. " hour(s).") end
    if BuyOnStartup and not SellOnStartup then -- The seller will initiate buyers once done, if both are enabled, so here we must check is not SellOnStartup to not start overlapping buyers
        CreateLuaEvent(AHBot_BuyAuction, StartupDelay + 1000) -- Slight artificial delay in case StartupDelay is 0.
    end
end

---------------------------------------------------------------------------------
-- Management commands
---------------------------------------------------------------------------------

local blockCommands = os.time() + 15 -- Prevents expiring auctions while initially starting AH bot

local function CheckExpiry(houseId)
    blockCommands = os.time() + 300 -- Block expirations for 5 minutes. If the core hasn't expired auctions by now, something is wrong
    CreateLuaEvent(function(eventId)
        if blockCommands < os.time() then
            print("[Eluna AH Bot]: Error expiring auctions " .. (houseId and " in house ID " .. houseId or "") .. ".")
            SendMessageToGMs("Error expiring auctions" .. (houseId and " in house ID " .. houseId or "") .. "!")
            RemoveEventById(eventId)
            blockCommands = 0
        end
        
        local query = "SELECT 1 FROM auctionhouse WHERE itemowner IN (" .. botList .. ")"
        
        if houseId then
            query = query .. " AND houseid = " .. houseId
        end
        
        CharDBQueryAsync(query, function(result)
            if not result then
                print("[Eluna AH Bot]: All bot auctions" .. (houseId and " in house ID " .. houseId or "") .. " have expired.")
                SendMessageToGMs("All bot auctions" .. (houseId and " in house ID " .. houseId or "") .. " have been expired.")
                RemoveEventById(eventId)
                blockCommands = 0
            end
        end)
    end, 5000, 0)
end

local function AHBot_Cmd(event, player, command)
    if not player then return end
    if command:find("ah") then
        if player:GetGMRank() < 1 then
            player:SendBroadcastMessage("You don't have access to this command.")
            return false
        end
    end
    
    if blockCommands > os.time() then
        if command:find("ahbot auctions expire") or command:find("ahbot auctions add") or command:find("ahbot auctions buy") or command:find("ahbot start") then
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: This command cannot be used while auctions are being refreshed.")
            return false
        end
    end
    
    local name = player:GetName()
    if command:lower() == "ahbot" or command == "ahbot options" or command == "ahbot help" then
        player:SendBroadcastMessage(" ")
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Welcome to the Eluna AH bot menu. Possible subcommands:")
        player:SendBroadcastMessage("|- .ahbot info: Displays statistics about the auction house bot.")
        player:SendBroadcastMessage("|- .ahbot auctions expire <auction_house_ID/all>: Expires all auctions per house (2/6/7) or all houses.")
        player:SendBroadcastMessage("|- .ahbot auctions add: Force adds a batch of ".. ActionsPerCycle .." auctions to all auction houses.")
        player:SendBroadcastMessage("|- .ahbot auctions buy: Force buys a random batch of auctions from all auction houses.")
        player:SendBroadcastMessage("|- .ahbot stop: Removes the scheduled auction bot events.")
        player:SendBroadcastMessage("|- .ahbot start: Starts the auction bot, if stopped.")
        player:SendBroadcastMessage("|- .ahbot pause <hours>: Pauses the auction bot for the specified number of hours.")
        player:SendBroadcastMessage("|- .ahbot set batchsize <number>: Changes how many items the auction bots processes per cycle.")
        player:SendBroadcastMessage("|- .ahbot set buycycle <hours>: Changes how often the auction house bot checks the auction house to take action.")
        player:SendBroadcastMessage("|- .ahbot set sellcycle <hours>: Changes how often the auction house bot checks the auction house to take action.")
        return false
        
    elseif command:lower() == "ahbot info" then
        local auctionInfo = {}
        for houseId, count in pairs(postedAuctions) do
            if count and not (count == "0") then
                table.insert(auctionInfo, string.format("House ID: %d -> Auctions: %s", houseId, count))
            end
        end
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: ---------- INFO ----------")
        player:SendBroadcastMessage("|- Auction house IDs with active bots (2 = ally, 6 = horde, 7 = neutral): ".. houseList)
        player:SendBroadcastMessage("|- Active bot GUID lows: ".. botList)
        player:SendBroadcastMessage("|- Min bot auctions: "..MinAuctions..". Max bot auctions: "..MaxAuctions..".")
        player:SendBroadcastMessage("|- Number of possible items in auction house pool: ".. ItemTemplateSize)
        player:SendBroadcastMessage("|- Bot items on auction houses on last cycle: "..(table.concat(auctionInfo, ", ")))
        player:SendBroadcastMessage("|- Next auction house bot sell cycle (hours:minutes): ".. os.date("%H:%M", NextAHBotSellCycle))
        player:SendBroadcastMessage("|- Next auction house bot buy cycle: in " .. math.ceil((NextAHBotBuyCycle - os.time()) / 60) .. " minutes")
        local status
        if AHBotSellEventId then status = "Online" else status = "Offline" end
        player:SendBroadcastMessage("|- Status auction house bot seller service: "..status)
        if AHBotBuyEventId then status = "Online" else status = "Offline" end
        player:SendBroadcastMessage("|- Status auction house bot buyer service: "..status)
        return false
        
    elseif command:lower() == "ahbot auctions expire" or command == "ahbot auctions expire all" then
        if MarketPrices then CharDBExecute("DELETE FROM ahbot_listings") end -- GM expiries say nothing about demand
        CharDBQueryAsync("UPDATE auctionhouse SET time = 1 WHERE itemowner IN (" .. botList .. ")", function(query)
            local player = GetPlayerByName(name)
            SendMessageToGMs("GM "..name.." has set all bot auctions to expire on next auction update. Refreshing auctions cache...")
            RunCommand("reload auctions")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." expired all auction houses' bot auctions.")    
            CheckExpiry()
        end)
        return false
    elseif command:lower() == "ahbot auctions expire 2" then
        if MarketPrices then CharDBExecute("DELETE FROM ahbot_listings WHERE houseid = 2") end -- GM expiries say nothing about demand
        CharDBQueryAsync("UPDATE auctionhouse SET time = 1 WHERE itemowner IN (" .. botList .. ") AND houseid = 2", function(query)
            local player = GetPlayerByName(name)
            SendMessageToGMs("GM "..name.." has set bot auctions on house ID 2 to expire on next auction update. Refreshing auctions cache...")
            RunCommand("reload auctions")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." expired bot auctions on auction house 2.")    
            CheckExpiry(2)
        end)
        return false
    elseif command:lower() == "ahbot auctions expire 6" then
        if MarketPrices then CharDBExecute("DELETE FROM ahbot_listings WHERE houseid = 6") end -- GM expiries say nothing about demand
        CharDBQueryAsync("UPDATE auctionhouse SET time = 1 WHERE itemowner IN (" .. botList .. ") AND houseid = 6", function(query)
            local player = GetPlayerByName(name)
            SendMessageToGMs("GM "..name.." has set bot auctions on house ID 6 to expire on next auction update. Refreshing auctions cache...")
            RunCommand("reload auctions")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." expired bot auctions on auction house 6.")    
            CheckExpiry(6)
        end)
        return false
    elseif command:lower() == "ahbot auctions expire 7" then
        if MarketPrices then CharDBExecute("DELETE FROM ahbot_listings WHERE houseid = 7") end -- GM expiries say nothing about demand
        CharDBQueryAsync("UPDATE auctionhouse SET time = 1 WHERE itemowner IN (" .. botList .. ") AND houseid = 7", function(query)
            local player = GetPlayerByName(name)
            SendMessageToGMs("GM "..name.." has set bot auctions on house ID 7 to expire on next auction update. Refreshing auctions cache...")
            RunCommand("reload auctions") -- Instantiates auctions
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." expired bot auctions on auction house 7.")
            CheckExpiry(7)
        end)
        return false
    
    elseif command:lower() == "ahbot auctions buy" then
        AHBot_BuyAuction()
        SendMessageToGMs("GM "..name.." is force buying " .. ActionsPerCycle .. " auctions from all auction houses.")
        print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." force bought auctions on all auction houses.")
        return false
        
    elseif command:lower() == "ahbot auctions add" or command == "ahbot auctions add all" or command == "ahbot auction add all" or command == "auctions add all" or command == "auction add all" then
        local overrideHouse = 0
        for _, houseId in ipairs(EnabledAuctionHouses) do
            overrideHouse = overrideHouse + houseId
        end
        if overrideHouse > 1 then
            AHBot_SellItems(_, _, _, overrideHouse)
            SendMessageToGMs("GM "..name.." has force added " .. ActionsPerCycle .. " auctions to auction house(s) ".. houseList)
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." force added auctions on all auction houses: ".. houseList)
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Syntax error. No auction houses enabled in AH bot config.")
        end
        return false
    elseif command:lower():find("ahbot auctions add (%d+)") then
        local _, _, houseId = command:lower():find("ahbot auctions add (%d+)")
        if houseId then
            houseId = tonumber(houseId)
            if houseId == 2 or houseId == 6 or houseId == 7 then
                local houseEnabled = false
                for _, enabledId in ipairs(EnabledAuctionHouses) do
                    if enabledId == houseId then
                        houseEnabled = true
                        AHBot_SellItems(_, _, _, houseId)
                        SendMessageToGMs("GM "..player:GetName().." has force added " .. ActionsPerCycle .. " auctions to auction house ID "..houseId..".")
                        print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." force added auctions on auction house "..houseId..".")
                        break
                    end
                end
                if not houseEnabled then
                    player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Syntax error. Auction house not found or disabled in AH bot config.")
                end
            else
                player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Syntax error. Auction house not found or disabled in AH bot config.")
            end
        end
        return false
        
    elseif command:lower() == "ahbot stop" then
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Syntax error. Please use either '.ahbot stop sell' or '.ahbot stop buy'.")
        return false
    elseif command:lower() == "ahbot stop sell" then
        RemoveEventById(AHBotSellEventId)
        AHBotSellEventId = nil
        NextAHBotSellCycle = nil
        SendMessageToGMs("GM "..name.." has force stopped the auction house seller on all auction houses.")
        print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." just stopped the auction bot seller.")
        return false
    elseif command:lower() == "ahbot stop buy" then
        RemoveEventById(AHBotBuyEventId)
        AHBotBuyEventId = nil
        NextAHBotBuyCycle = nil
        SendMessageToGMs("GM "..name.." has force stopped the auction house buyer on all auction houses.")
        print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." just stopped the auction bot buyer.")
        return false
        
    elseif command:lower() == "ahbot pause" then
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Invalid pause time! Please specify a duration between 1 to 24 hours.")
        return false
    elseif command:find("ahbot pause ") then
        local _, _, pauseTime = command:find("ahbot pause (%d+)")
        if pauseTime and tonumber(pauseTime) >= 1 and tonumber(pauseTime) <= 24 then
            pauseTime = tonumber(pauseTime)
            RemoveEventById(AHBotSellEventId)
            RemoveEventById(AHBotBuyEventId)
            AHBotBuyEventId = CreateLuaEvent(AHBot_BuyAuction, AHBuyTimer * pauseTime * 65 * 60 * 1000, 0)
            AHBotSellEventId = CreateLuaEvent(AHBot_SellItems, AHSellTimer * pauseTime * 60 * 60 * 1000, 0)
            NextAHBotSellCycle = os.time() + pauseTime * 60 * 60
            SendMessageToGMs("GM "..name.." has paused all auction house bots for "..pauseTime.." hours.")
            print("[Eluna AH Bot]: Player "..player:GetGUIDLow().." just paused the auction bot for " .. pauseTime .. " hours.")
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Invalid pause time! Please specify a number between 1 and 24.")
        end
        return false
        
    elseif command:find("ahbot set batchsize ") then
        local batchsize = tonumber(command:match("ahbot%s+set%s+batchsize%s+(%d+)"))
        if batchsize and tonumber(batchsize) >= 1 and tonumber(batchsize) <= MaxAuctions then
            batchsize = tonumber(batchsize)
            ActionsPerCycle = batchsize
            SendMessageToGMs("GM "..name.." has set the auction house bots' batch size to "..batchsize..".")
            print("[Eluna AH Bot]: Player "..player:GetGUIDLow().." just changed the auction bot's batch size to "..batchsize..".")
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Invalid batch size! Please specify a number between 1 and "..MaxAuctions..".")
        end
        return false
        
    elseif command:find("ahbot set sellcycle ") then
        local hours = tonumber(command:match("ahbot%s+set%s+sellcycle%s+(%d+)"))
        if hours and tonumber(hours) >= 1 and tonumber(hours) <= 48 then
            hours = tonumber(hours)
            AHSellTimer = hours
            SendMessageToGMs("GM "..name.." has set the auction house bot's sell cycle time has been set to "..hours.." hours. Next cycle is in "..hours.." hour(s) from now.")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." just changed the auction bot's sell cycle time to "..hours.." hour(s).")
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Invalid sell cycle time! Please specify a number between 1 and 48.")
        end
        return false
    elseif command:find("ahbot set buycycle ") then
        local hours = tonumber(command:match("ahbot%s+set%s+buycycle%s+([%d%.]+)"))
        if hours and hours >= 0.1 and hours <= 48 then
            AHBuyTimer = hours
            SendMessageToGMs("GM "..name.." has set the auction house bot's buy cycle time has been set to %.1f minutes. Next cycle is in %.1f minutes from now.", 60 * hours, 60 * hours)
            print(string.format("[Eluna AH Bot]: GM %d just changed the auction bot's buy cycle time to %.1f minutes.", player:GetGUIDLow(), 60 * hours))
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Invalid buy cycle time! Please specify a number between 0.1 and 48.")
        end
        return false
            
    elseif command:lower() == "ahbot start" then
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Incorrect syntax. Use either '.ahbot start sell' or '.ahbot start buy'.")
        return false
    elseif command:lower() == "ahbot start buy" then
        if not AHBotBuyEventId then
            AHBotBuyEventId = CreateLuaEvent(AHBot_BuyAuction, AHBuyTimer * 65 * 60 * 1000, 0)
            NextAHBotBuyCycle = os.time() + AHBuyTimer * 60 * 60
            SendMessageToGMs("GM "..name.." has just started the auction house buyer bot.")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." just started the auction bot buyer.")
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Auction house buyer has already been started. No action taken.")
        end
        return false
    elseif command:lower() == "ahbot start sell" then
        if not AHBotSellEventId then
            AHBotSellEventId = CreateLuaEvent(AHBot_SellItems, AHSellTimer * 60 * 60 * 1000, 0)
            NextAHBotSellCycle = os.time() + AHSellTimer * 60 * 60
            SendMessageToGMs("GM "..name.." has just started the auction house seller bot.")
            print("[Eluna AH Bot]: GM "..player:GetGUIDLow().." just started the auction bot seller.")
        else
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Auction house seller has already been started. No action taken.")
        end
        return false
    
    elseif command:find("ahbot.+") then
        player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Syntax error. Type .ahbot to see available commands.")
        return false
    end
end

RegisterPlayerEvent(42, AHBot_Cmd)

---------------------------------------------------------------------------------
-- Announce login
---------------------------------------------------------------------------------

if AnnounceOnLogin then
    local function OnPlayerLogin(event, player)
        player:SendBroadcastMessage("This server runs the |cFFD8D8E6[Eluna AH Bot]|r module by mostlynick :)")
        if player:GetGMRank() > 0 then
            player:SendBroadcastMessage("|cFFD8D8E6[Eluna AH Bot GM]|r: Type '.ahbot' to manage, set cache settings, and display statistics.")
        end
    end
    RegisterPlayerEvent(3, OnPlayerLogin)
end

---------------------------------------------------------------------------------
-- End of script
---------------------------------------------------------------------------------
