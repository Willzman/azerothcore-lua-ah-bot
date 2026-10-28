
<h1>Eluna AH Bot</h1>
<p>This is Willzman's version of the <strong>Eluna AH Bot</strong> module, a fork of <a href="https://github.com/mostlynick3/azerothcore-lua-ah-bot" target="_blank">mostlynick3's original</a>. This script is designed for automated auction house operations in AzerothCore emulation environments. It supports both buyer and seller functionalities, and is designed to be plug-and-play with extensive configuration options.</p>
<img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/icon.png" alt="Settings Image">

<h2>Features</h2>
<ul>
	<li>Plug and play: copy the Lua files to your server, no SQL scripts needed</li>
	<li>Sells every item a player could list on the auction house, or a curated selection</li>
	<li>Buyer and seller bots, with bids and buyouts</li>
	<li>Behaves like a live server's players: real auction durations, undercutting, rounded prices, normal stack sizes, market prices that follow demand, busier evenings, and listings that follow your players' levels</li>
	<li>Holiday items only during their holiday</li>
	<li>In-game commands to manage the bots, check prices and ban items</li>
	<li>Compatible with all Eluna versions supporting async DB queries (slight modifications needed otherwise)</li>
</ul>

<h2>Installation</h2>
<ol>
	<li>Copy <code>AHBot.lua</code> and the <code>AHBot</code> folder into your server's Lua scripts folder, keeping the same layout.</li>
	<li>Create the bot characters and put their GUIDs in <code>AHBots</code>.</li>
	<li>Back up your characters database, then start the server or run <code>.reload eluna</code>.</li>
</ol>
<p>Requirements: Eluna with async database queries, and MySQL 8.0+ or MariaDB 10.2+. The bot creates what it needs in the characters database on load: an <code>AddedByEluna</code> column on <code>auctionhouse</code> and <code>item_instance</code>, and the tables <code>ahbot_market</code> and <code>ahbot_listings</code> (market prices) and <code>ahbot_banned</code> (item bans). The server's database user needs permission to create and alter tables.</p>
<p>To fill an empty auction house quickly on the first start, temporarily raise <code>ActionsPerCycle</code> (for example to <code>5000</code>), then set it back and reload Eluna.</p>

<h2>Configuration</h2>
<p>All settings are at the top of <code>AHBot.lua</code>. The values below are this version's defaults, sized for a small server: two faction auction houses, about 10,000 auctions each, hourly selling and light buying.</p>

<h3>Bot Settings</h3>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>EnableAHBot</code></td><td><code>true</code></td><td>Enables or disables the auction house bot.</td></tr>
	<tr><td><code>AHBots</code></td><td><code>{1, 2, 3}</code></td><td>GUIDs of the characters used as bots. They must exist.</td></tr>
	<tr><td><code>EnabledAuctionHouses</code></td><td><code>{2, 6}</code></td><td>Auction houses to stock: 2 = Alliance, 6 = Horde, 7 = neutral. On cross-faction servers, only 7 is needed.</td></tr>
	<tr><td><code>ActionsPerCycle</code></td><td><code>500</code></td><td>Auctions posted per auction house per sell cycle at peak hours. Also how many auctions the buyer looks at per cycle.</td></tr>
	<tr><td><code>StartupDelay</code></td><td><code>1000</code></td><td>Milliseconds to wait after startup or an Eluna reload before starting.</td></tr>
	<tr><td><code>ClearBotMailbox</code></td><td><code>true</code></td><td>Regularly deletes the bots' mail and the items in it (expired and bought auctions), so mailboxes and the database don't fill up.</td></tr>
	<tr><td><code>EnableGMMessages</code></td><td><code>true</code></td><td>Messages online GMs about bot actions and errors.</td></tr>
	<tr><td><code>AnnounceOnLogin</code></td><td><code>true</code></td><td>Tells players on login that the server runs the AH bot.</td></tr>
	<tr><td><code>AHBotActionDebug / AHBotItemDebug</code></td><td><code>true / false</code></td><td>Debug output to the server console.</td></tr>
</table>

<h3>Buyer</h3>
<p>Bots value an item at the price they would list it for themselves. They only buy auctions priced below that, and the better the deal, the likelier they buy.</p>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>EnableBuyer</code></td><td><code>true</code></td><td>Enables the buyer bots.</td></tr>
	<tr><td><code>AHBuyTimer</code></td><td><code>1</code></td><td>Hours between buy cycles.</td></tr>
	<tr><td><code>PlaceBuyoutChance / PlaceBidChance</code></td><td><code>3 / 5</code></td><td>Base chance (%) to buy out or bid on an underpriced auction.</td></tr>
	<tr><td><code>MaxBuysPerCycle</code></td><td><code>3</code></td><td>Most buyouts and bids per buy cycle. <code>false</code> for no limit.</td></tr>
	<tr><td><code>BotsPriceTolerance</code></td><td><code>1.0</code></td><td>Most a bot pays, relative to its own listing price. 1.0 = only below the bots' own price.</td></tr>
	<tr><td><code>DealChanceMultiplier</code></td><td><code>3</code></td><td>Buy and bid chances are multiplied by how good the deal is (value / price), up to this factor.</td></tr>
	<tr><td><code>BuyDelayMin / BuyDelayMax</code></td><td><code>30 / 360</code></td><td>Minutes an auction must have been seen by the bots before they consider it, picked at random in this range. Resets on Eluna reload.</td></tr>
	<tr><td><code>ItemLevelLimit</code></td><td><code>187</code></td><td>Bots don't buy items at or above this item level, so players get them.</td></tr>
	<tr><td><code>BotsBuyFromBots</code></td><td><code>false</code></td><td>Lets bots buy other bots' auctions.</td></tr>
	<tr><td><code>BotToBotBuyFactor</code></td><td><code>0.2</code></td><td>Multiplies the chances when buying from another bot.</td></tr>
	<tr><td><code>BotsOutbidBots</code></td><td><code>true</code></td><td>Bots may outbid other bots' bids. They never bid on their own auctions, outbid themselves, or touch auctions players have bid on (players' bid gold isn't refunded when an auction is changed in the database).</td></tr>
	<tr><td><code>BuyerCostFormula</code></td><td><code>1</code></td><td>Price formula used to value items (see Price Formulas).</td></tr>
	<tr><td><code>BuyOnStartup</code></td><td><code>true</code></td><td>Run a buy cycle right after startup.</td></tr>
</table>

<h3>Seller</h3>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>EnableSeller</code></td><td><code>true</code></td><td>Enables the seller bots.</td></tr>
	<tr><td><code>AHSellTimer</code></td><td><code>1</code></td><td>Hours between sell cycles. Minimum 1.</td></tr>
	<tr><td><code>MinAuctions / MaxAuctions</code></td><td><code>10000 / 15000</code></td><td>Bot auctions per auction house. Below the minimum, every cycle posts a full batch; between the two, a cycle posts with <code>RepopulationChance</code>. The auction house settles just above the minimum.</td></tr>
	<tr><td><code>RepopulationChance</code></td><td><code>30</code></td><td>Chance (%) to post a batch while between the minimum and maximum.</td></tr>
	<tr><td><code>HourlySellMultipliers</code></td><td><code>0.2 at night to 1.0 at 18-21h</code></td><td>Share of <code>ActionsPerCycle</code> posted per cycle by server hour, while an auction house has at least <code>MinAuctions</code>. <code>false</code> to always post the full batch.</td></tr>
	<tr><td><code>SellerCostFormula</code></td><td><code>1</code></td><td>Price formula used to price listings (see Price Formulas).</td></tr>
	<tr><td><code>SellPriceVariance</code></td><td><code>20</code></td><td>Randomizes prices by up to this many %.</td></tr>
	<tr><td><code>SellOnStartup</code></td><td><code>true</code></td><td>Run a sell cycle right after startup.</td></tr>
	<tr><td><code>ApplyRandomProperties</code></td><td><code>true</code></td><td>Gives items their random enchantments and names, like &quot;of the Eagle&quot;. Disable on non-WotLK cores.</td></tr>
	<tr><td><code>SetAsCraftedBy</code></td><td><code>true</code></td><td>Crafted items show a bot as their crafter.</td></tr>
</table>

<h3>Seller Realism</h3>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>AuctionDurations</code></td><td><code>{[12] = 20, [24] = 40, [48] = 40}</code></td><td>Relative chance of each auction duration in hours, like players choose.</td></tr>
	<tr><td><code>UndercutChance</code></td><td><code>80</code></td><td>Chance (%) to undercut the cheapest listing of the same item.</td></tr>
	<tr><td><code>UndercutRange</code></td><td><code>{1, 5}</code></td><td>How many % below the cheapest listing to post.</td></tr>
	<tr><td><code>UndercutLimits</code></td><td><code>{0.6, 1.5}</code></td><td>Undercut prices stay between 60% and 150% of the bot's own price, so it doesn't follow dumped or absurd listings.</td></tr>
	<tr><td><code>UndercutPlayers</code></td><td><code>false</code></td><td>If false, bots only undercut other bots, and list at or up to 5% above players' cheapest price instead of below it, so players' auctions stay competitive.</td></tr>
	<tr><td><code>HumanizePrices</code></td><td><code>true</code></td><td>Rounds prices the way players type them, like 4g 95s or 24g 99s 99c.</td></tr>
	<tr><td><code>VendorPriceMultiplier</code></td><td><code>{4, 8}</code></td><td>Items the price formula values under 10 silver are priced at 4-8 times their vendor price. Nothing is listed below 1.25 times vendor price.</td></tr>
	<tr><td><code>MarketPrices</code></td><td><code>true</code></td><td>Remembers a price factor per item and auction house, in <code>ahbot_market</code>. Items selling better than the auction house's average get pricier, worse get cheaper, and prices hold steady even when most listings expire.</td></tr>
	<tr><td><code>MarketPriceStep</code></td><td><code>0.05</code></td><td>How far one sale moves an item's price factor.</td></tr>
	<tr><td><code>MarketPriceLimits</code></td><td><code>{0.5, 2.0}</code></td><td>Lowest and highest price factor.</td></tr>
	<tr><td><code>HousePriceModifiers</code></td><td><code>{[2] = 1.0, [6] = 1.0, [7] = 1.15}</code></td><td>Price factor per auction house. The neutral auction house takes a bigger cut, so prices there run higher.</td></tr>
	<tr><td><code>StackSizeWeights</code></td><td><code>{[1] = 15, [5] = 20, [10] = 25, [20] = 30, full = 10}</code></td><td>Relative chance of each stack size, for the item classes in <code>StackedItemClasses</code>.</td></tr>
	<tr><td><code>CheapItemPrice / CheapFullStackWeight</code></td><td><code>5000 / 60</code></td><td>Items under 50 silver each are mostly sold in full stacks.</td></tr>
	<tr><td><code>MultiListClasses</code></td><td><code>{0, 7}</code></td><td>Item classes (consumables, trade goods) that sometimes get several listings at slightly increasing prices, like several sellers.</td></tr>
	<tr><td><code>MultiListChance / MaxExtraListings</code></td><td><code>40 / 3</code></td><td>Chance (%) of extra listings, and how many at most.</td></tr>
	<tr><td><code>MatchPlayerLevels</code></td><td><code>0.5</code></td><td>From 0 to 1, how strongly gear and consumable listings follow the levels of recently active players. 0 disables.</td></tr>
	<tr><td><code>PlayerActivityDays</code></td><td><code>7</code></td><td>Characters who logged in within this many days count as active.</td></tr>
</table>

<h3>Item Filters</h3>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>SellAllAuctionableItems</code></td><td><code>true</code></td><td>Sells every item a player could list: anything not soulbound, account bound, conjured or timed. Only placeholder and test items, <code>NeverSellIDs</code>, banned items and the expansion lock still apply. Set to false to use the curated filters below.</td></tr>
	<tr><td><code>HolidayItemsInSeason</code></td><td><code>true</code></td><td>Holiday items (Winter Veil, Hallow's End, etc.) are only posted while their holiday's game event is active.</td></tr>
	<tr><td><code>Expansion</code></td><td><code>0</code></td><td>Limit items to an expansion: 0 = no limit, 1 = Vanilla, 2 = TBC, 3 = WotLK.</td></tr>
	<tr><td><code>NeverSellIDs</code></td><td><code>various</code></td><td>Item IDs the bots never sell. Items can also be banned in game with <code>.ahbot ban</code>.</td></tr>
	<tr><td><code>StackedItemClasses</code></td><td><code>{0, 5, 6, 7}</code></td><td>Item classes sold in stacks: consumables, reagents, projectiles and trade goods.</td></tr>
	<tr><td><code>AlwaysMaxStackAmmo / AdjustedAmmoPrices</code></td><td><code>true / true</code></td><td>Sell ammo in full stacks, at realistic prices per stack.</td></tr>
</table>
<p>Only used when <code>SellAllAuctionableItems = false</code>: <code>AllowDeprecated</code>, <code>AllowedBinds</code>, <code>AllowBindOnAccount</code>, <code>AllowedQualities</code>, <code>AllowQuestItems</code>, <code>AllowConsumables</code>, <code>MinContainerSize</code>, <code>MinLevelConsumables</code>, <code>MinLevelGear</code>, <code>MaxLevel</code>, <code>AllowCommonAmmo</code>, <code>AllowReputationItems</code>, <code>AllowMounts</code>, <code>AllowCompanions</code>, <code>AllowedClassItems</code>, <code>AllowedAllyRaces</code>, <code>AllowedHordeRaces</code>, <code>AllowedProfessions</code>, <code>AllowLockpicking</code>, <code>AllowGlyphs</code>, <code>AllowRecipes</code>, <code>AllowKeys</code>, <code>AllowMisc</code>, <code>AllowJunk</code>, <code>AllowHolidayItems</code> and <code>AllowConjured</code>. Each is described next to it in <code>AHBot.lua</code>.</p>

<h3>Item Weights</h3>
<p><code>ItemWeights</code> sets how often each kind of item is posted. Each category is picked with a chance relative to its weight, then an item at random within it. The defaults favour what players buy most on a live server:</p>
<ul>
	<li><strong>Gear</strong> by quality: Green 25, Blue 15, Epic 5, others 1, Heirloom 0</li>
	<li><strong>Mats</strong> (trade goods) by quality: White 30 (most herbs, ore, cloth and leather), Green 15, Blue 6, others 1, Heirloom 0</li>
	<li><strong>Consumable</strong> 15, <strong>Glyph</strong> 10, <strong>Gem</strong> 8, <strong>Recipe</strong> 5, <strong>Projectile</strong> 5, <strong>Container</strong> 4, <strong>Companion</strong> 3, <strong>Other</strong> 3</li>
	<li><strong>SpecificItems</strong>: give single items their own weight, like <code>[41599] = 2</code></li>
</ul>

<h3>Price Adjustments</h3>
<table>
	<tr><th>Setting</th><th>Value</th><th>What it does</th></tr>
	<tr><td><code>RecipePriceAdjustment</code></td><td><code>10</code></td><td>Multiplies recipe prices, which the formulas undervalue.</td></tr>
	<tr><td><code>GemPriceAdjustment</code></td><td><code>0.142</code></td><td>Multiplies gem prices, which the formulas overvalue.</td></tr>
	<tr><td><code>UndervaluedItemAdjust</code></td><td><code>5</code></td><td>Multiplies prices of vellums, Titanium materials, VIII scrolls, etc.</td></tr>
	<tr><td><code>LowPriceFloor</code></td><td><code>200000</code></td><td>Base price (20g, +/- 30%) for companions and glyphs priced under 20g.</td></tr>
</table>
<p><strong>Price Formulas</strong> (<code>SellerCostFormula</code>, <code>BuyerCostFormula</code>): 1 = quality based scaling, 2 = entry ID influenced, 3 = quality/level focused, 4 = balanced multi-factor, 5 = progressive thresholds, 6 = random.</p>

<h2>In-Game Commands</h2>
<p>For GMs. Type <code>.ahbot</code> in game to see them all.</p>
<ul>
	<li><code>.ahbot info</code> - Statistics about the bots.</li>
	<li><code>.ahbot auctions add [2/6/7]</code> / <code>.ahbot auctions buy</code> - Force a full batch of auctions on all or one auction house, or a buy cycle.</li>
	<li><code>.ahbot auctions expire &lt;2/6/7/all&gt;</code> - Expire the bots' auctions.</li>
	<li><code>.ahbot start sell|buy</code> / <code>.ahbot stop sell|buy</code> - Start or stop the seller or buyer.</li>
	<li><code>.ahbot pause &lt;hours&gt;</code> - Pause the bots, which then resume on their normal schedule.</li>
	<li><code>.ahbot set batchsize|sellcycle|buycycle &lt;value&gt;</code> - Change settings until the next reload. New cycle times take effect immediately.</li>
	<li><code>.ahbot price &lt;item ID&gt;</code> - What the bots list an item for and pay for it, per auction house, with its market factor.</li>
	<li><code>.ahbot ban &lt;item ID&gt;</code> / <code>.ahbot unban &lt;item ID&gt;</code> - Stop or resume the bots selling and buying an item. Banning removes the item's bot auctions, except those a player has bid on.</li>
</ul>
<img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/commands.png" alt="In-Game Commands">

<h2>Screenshots</h2>
<p>From the original module.</p>
<img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/sales.png" alt="AH Bot's Wide Variety of Sales">
<img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/bids.png" alt="AH Bot's Realistic Bids">

<h2>AzerothCore Module Details</h2>
<p>Maintainer: Willzman</p>
<p>Repository: <a href="https://github.com/Willzman/azerothcore-lua-ah-bot" target="_blank">https://github.com/Willzman/azerothcore-lua-ah-bot</a>.</p>
<p>Download ZIP: <a href="https://github.com/Willzman/azerothcore-lua-ah-bot/archive/refs/heads/main.zip" target="_blank">https://github.com/Willzman/azerothcore-lua-ah-bot/archive/refs/heads/main.zip</a>.</p>
<p>License: GPL-3.0</p>

<h2>Credits</h2>
<p>Based on the original Eluna AH Bot by <strong>mostlynick3</strong>: <a href="https://github.com/mostlynick3/azerothcore-lua-ah-bot" target="_blank">https://github.com/mostlynick3/azerothcore-lua-ah-bot</a>. Thanks to mostlynick3 and the original contributors.</p>
