
<h1>Eluna AH Bot - Project is WIP but functional</h1>
<p>This is Willzman's version of the <strong>Eluna AH Bot</strong> module, a fork of <a href="https://github.com/mostlynick3/azerothcore-lua-ah-bot" target="_blank">mostlynick3's original</a>. This script is designed for automated auction house operations in AzerothCore emulation environments. It supports both buyer and seller functionalities, and is designed to be plug-and-play with extensive configuration options.</p>
<img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/icon.png" alt="Settings Image">

<h2>Features</h2>
<ul>
	<li>Plug and Play</li>
	<li>Extensive Filters</li>
	<li>Buyer and Seller Capabilities</li>
	<li>Supports both Bids and Buyouts</li>
	<li>Compatible with all Eluna versions supporting async DB queries (slight modifications needed otherwise)</li>
</ul>

<h2>Key Configuration Options</h2>
<h3>Bot Settings</h3>
<ul>
	<li><strong>Enable AH Bot</strong> - Enables or disables the auction house bot. Default is <code>true</code>.</li>
	<li><strong>AH Bots</strong> - List of player GUIDs used as bots. Can be customized.</li>
	<li><strong>Enabled Auction Houses</strong> - Specifies which auction houses the bot operates in (e.g., alliance, horde, neutral).</li>
	<li><strong>Enable Debugging</strong> - Configurable debugging options for both bot actions and item handling.</li>
	<li><strong>Startup Delay</strong> - Sets a delay after bot initialization to avoid server lag.</li>
  <li><strong>Some settings include:</strong> </li>
  <br><img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/settings.png" alt="Settings Image">
</ul>

<h3>Buyer Features</h3>
<ul>
	<li><strong>Enable Buyer</strong> - Controls whether the bot will buy items. Default is <code>true</code>.</li>
	<li><strong>AH Buy Timer</strong> - Specifies how frequently the bot purchases items (in hours).</li>
	<li><strong>Place Bid/Buyout Chance</strong> - Configures the chances of the bot placing a bid or buyout on items.</li>
	<li><strong>Realistic Bidding</strong> - The buyer bot is configured to bid within acceptable ranges of prices, and can be configured to bid over players or not.</li>
  <br><img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/bids.png" alt="AH Bot's Realistic Bids">
</ul>

<h3>Seller Features</h3>
<ul>
	<li><strong>Enable Seller</strong> - Controls whether the bot will post items for sale. Default is <code>true</code>.</li>
	<li><strong>Max Auctions</strong> - Maximum number of auctions the bot can post.</li>
	<li><strong>Repopulation Chance</strong> - Percentage chance the bot will repopulate the auction house when the number of items falls below a threshold.</li>
	<li><strong>Apply Random Properties</strong> - The AH bot is able to instantiate all items, including those with random properties and suffixes.</li>
  <br><img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/sales.png" alt="AH Bot's Wide Variety of Sales">
</ul>

<h3>Live Server Realism</h3>
<ul>
	<li><strong>Real Auction Durations</strong> - Auctions run for 12, 24 or 48 hours, like players choose (<code>AuctionDurations</code>).</li>
	<li><strong>Undercutting</strong> - Sellers post just below the cheapest listing of the same item, within limits of their own price (<code>UndercutChance</code>, <code>UndercutRange</code>, <code>UndercutLimits</code>). By default bots only undercut each other and list at or above players' prices, so players' auctions stay competitive (<code>UndercutPlayers</code>).</li>
	<li><strong>Vendor-Based Prices for Cheap Items</strong> - Items the price formula can't value sensibly are priced at a multiple of their vendor price, and nothing is listed below vendor price (<code>VendorPriceMultiplier</code>).</li>
	<li><strong>Busier Evenings</strong> - Each sell cycle posts a share of <code>ActionsPerCycle</code> depending on the server hour, more in the evening and less at night (<code>HourlySellMultipliers</code>).</li>
	<li><strong>Human-Looking Prices</strong> - Prices are rounded the way players type them, like 4g 95s or 24g 99s 99c (<code>HumanizePrices</code>).</li>
	<li><strong>Market Memory</strong> - Each auction house remembers a price factor per item: raised when it sells better than the auction house average, lowered when it sells worse, so prices hold steady even when most listings expire. Stored in the <code>ahbot_market</code> table (<code>MarketPrices</code>, <code>MarketPriceStep</code>, <code>MarketPriceLimits</code>). The neutral auction house runs higher prices (<code>HousePriceModifiers</code>).</li>
	<li><strong>Normal Stack Sizes</strong> - Stacks of 1, 5, 10, 20 or full stacks, with cheap materials mostly in full stacks. Popular materials and consumables get several listings at slightly increasing prices (<code>StackSizeWeights</code>, <code>MultiListClasses</code>).</li>
	<li><strong>Demand-Based Weights</strong> - Trade goods, consumables, gems, glyphs and BoE greens make up most listings (<code>ItemWeights</code>).</li>
	<li><strong>Holiday Items in Season</strong> - Winter Veil, Hallow's End and other holiday items are only posted while their holiday is active (<code>HolidayItemsInSeason</code>).</li>
	<li><strong>Follows Player Levels</strong> - Gear and consumable listings lean towards the levels of recently active players (<code>MatchPlayerLevels</code>, <code>PlayerActivityDays</code>).</li>
	<li><strong>Human-Like Buyers</strong> - Better deals are likelier to be bought, auctions aren't bought the moment they're listed, bots occasionally buy from and outbid each other, and never buy or bid on their own auctions. Bots value items at the price they would list them for themselves, and buy at most a few auctions per cycle (<code>BotsPriceTolerance</code>, <code>MaxBuysPerCycle</code>, <code>DealChanceMultiplier</code>, <code>BuyDelayMin</code>/<code>BuyDelayMax</code>, <code>BotsBuyFromBots</code>, <code>BotToBotBuyFactor</code>, <code>BotsOutbidBots</code>).</li>
</ul>

<h3>Item Filters</h3>
<ul>
	<li><strong>Sell All Auctionable Items</strong> - When enabled (default), the bot can sell every item a player could list on the auction house (anything not soulbound, account bound, conjured or timed). Only unobtainable placeholder/test items, <code>NeverSellIDs</code> and the expansion lock still apply. Disable it to use the curated filters below.</li>
	<li><strong>Allowed Qualities</strong> - Configures the allowed item qualities for sale (e.g., Common, Rare, Epic).</li>
	<li><strong>Allowed Classes</strong> - Specifies which class items can be sold.</li>
	<li><strong>Allowed Races</strong> - Configures which races' items can be sold.</li>
	<li><strong>Item Weighting</strong> - Customizes how different item types are prioritized in the selling process.</li>
</ul>

<h2>Additional Features</h2>
<ul>
	<li><strong>GM Messaging</strong> - Sends messages to online GMs to notify them of bot actions or critical errors.</li>
	<li><strong>Price Check and Item Bans</strong> - <code>.ahbot price &lt;item ID&gt;</code> shows what the bots list an item for and pay for it per auction house. <code>.ahbot ban &lt;item ID&gt;</code> stops the bots selling and buying an item and removes its bot auctions; <code>.ahbot unban &lt;item ID&gt;</code> undoes it. Bans are stored in the <code>ahbot_banned</code> table.</li>
	<li><strong>In-Game Management Comamnds</strong> - Type 'ahbot' to manage your AH bots.<br>
  <br><img src="https://raw.githubusercontent.com/mostlynick3/azerothcore-lua-ah-bot/master/images/commands.png" alt="In-Game Commands">
</li>
</ul>

<h2>AzerothCore Module Details</h2>
<p>Maintainer: Willzman</p>
<p>Repository: <a href="https://github.com/Willzman/azerothcore-lua-ah-bot" target="_blank">https://github.com/Willzman/azerothcore-lua-ah-bot</a>.</p>
<p>Download ZIP: <a href="https://github.com/Willzman/azerothcore-lua-ah-bot/archive/refs/heads/main.zip" target="_blank">https://github.com/Willzman/azerothcore-lua-ah-bot/archive/refs/heads/main.zip</a>.</p>
<p>License: GPL-3.0</p>

<h2>Credits</h2>
<p>Based on the original Eluna AH Bot by <strong>mostlynick3</strong>: <a href="https://github.com/mostlynick3/azerothcore-lua-ah-bot" target="_blank">https://github.com/mostlynick3/azerothcore-lua-ah-bot</a>. Thanks to mostlynick3 and the original contributors.</p>
