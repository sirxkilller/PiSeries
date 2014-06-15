-- PiAhri - simple as f***

local AUTOUPDATE = true
local silentUpdate = false

local version = 1.03

if myHero.charName ~= "Ahri" then return end

local scriptName = player.charName


local sourceLibFound = true
if FileExist(LIB_PATH .. "SourceLib.lua") then
	require "SourceLib"
else
	sourceLibFound = false
	DownloadFile("https://raw.githubusercontent.com/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", function() print("<font color=\"#DF7401\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SourceLib downloaded! Please reload!</font>") end)
end

if not sourceLibFound then return end



local UPDATE_NAME = "PiAhri"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/RankedFire/PiSeries/master/PiAhri.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..UPDATE_NAME..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH, "", 5)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end
    --SourceUpdater(scriptName, version, "raw.githubusercontent.com", "/RankedFire/PiSeries/master/PiAhri.lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME):SetSilent(silentUpdate):CheckUpdate()



local libDownloader = Require(scriptName)
libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
libDownloader:Check()

if libDownloader.downloadNeeded then return end

local VP   = nil
local OW   = nil
local STS  = nil
local DLib = nil
local drawManager = nil

local menu = nil

local spells  = {}
local circles = {}

local MainCombo = {ItemManager:GetItem("DFG"):GetId(), _AA, _E, _W, _Q}
local QCombo = {_Q}
local WCombo = {_W}
local ECombo = {_E}

local Q, W, E, R = _Q, _W, _E, _R

local CHARM_NAME = "AhriSeduce"
local MAX_RANGE  = 920

local SPELL_DATA = { [_Q] = { skillshotType = SKILLSHOT_LINEAR, range = 950, delay = 0.25, width = 100, speed = 1600, collision = false }, -- used for sourcelib - only some minor details
					 [_W] = { skillshotType = nil,              range = 800, collision = false },
					 [_E] = { skillshotType = SKILLSHOT_LINEAR, range = 975, delay = 0.25, width = 60, speed = 1500, collision = true },
					 [_R] = { skillshotType = nil,              range = 450, collision = false } }
					 
local SpellQ = {Speed = 1600, Range = 950, Delay = 0.250, Width = 100}
local SpellE = {Speed = 1500, Range = 975, Delay = 0.250, Width = 60}

function OnLoad()

	VP   = VPrediction()
	OW   = SOW(VP)
	STS  = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	drawManager = DrawManager()


	for spell, data in pairs(SPELL_DATA) do

		local rawSpell = Spell(spell, data.range)

		if data.skillshotType then
			rawSpell:SetSkillshot(VP, data.skillshotType, data.delay, data.width, data.speed, data.collision)
		end
		table.insert(spells, spell, rawSpell)
		print(rawSpell.collision)

		local rawCircle = drawManager:CreateCircle(player, data.range)

		rawCircle:LinkWithSpell(rawSpell)
		rawCircle:SetDrawCondition(function() return rawSpell:GetLevel() > 0 end)
		table.insert(circles, spell, rawCircle)

	end

	DLib:RegisterDamageSource(Q, _MAGIC, 20, 22.5, _MAGIC, _AP, 0.33, function() return spells[Q]:IsReady() end)
	DLib:RegisterDamageSource(W, _MAGIC, 20, 22.5, _MAGIC, _AP, 0.13, function() return spells[W]:IsReady() end)
	DLib:RegisterDamageSource(E, _MAGIC, 30, 30, _MAGIC, _AP, 0.35, function() return spells[E]:IsReady() end)

	setupMenu()

	AddTickCallback(combo)
	AddTickCallback(harass)

end

function setupMenu()

	menu = scriptConfig("Pi" .. player.charName, "Pi" .. player.charName)

	menu:addSubMenu("Orbwalking", "orbwalking")
		OW:LoadToMenu(menu.orbwalking)


	menu:addSubMenu("Target Selector", "ts")
		STS:AddToMenu(menu.ts)


	menu:addSubMenu("Combo", "combo")
		menu.combo:addParam("active", "Combo active" , SCRIPT_PARAM_ONKEYDOWN, false, 32)
		menu.combo:addParam("sep",    "",              SCRIPT_PARAM_INFO,      "")
		menu.combo:addParam("useQ",   "Use Q",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useW",   "Use W",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useE",   "Use E",         SCRIPT_PARAM_ONOFF,     true)

	-- Harass
	menu:addSubMenu("Harass", "harass")
		menu.harass:addParam("active",    "Harass active" ,           SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		menu.harass:addParam("sep",       "",                         SCRIPT_PARAM_INFO,      "")
		menu.harass:addParam("mana",      "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		menu.harass:addParam("useQ",      "Use Q",                    SCRIPT_PARAM_ONOFF,     true)
		menu.harass:addParam("useW",      "Use W",                    SCRIPT_PARAM_ONOFF,     true)
		menu.harass:addParam("useE",      "Use E",                    SCRIPT_PARAM_ONOFF,     false)

	-- Extra
	menu:addSubMenu("Extra", "extra")
		menu.extra:addParam("charm",   "Try to Charm with E first",          				 SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("autoQ",   "Automatically Cast Q if Dashing",                    SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("autoQ2",  "Automatically Cast Q if Immobile",                   SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("autoE",   "Automatically Cast E if Dashing",                    SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("autoE2",  "Automatically Cast E if Immobile",                   SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("packet",  "Cast spells using packets", 						 SCRIPT_PARAM_ONOFF, false)
		menu.extra:addParam("sep",     "",                          						 SCRIPT_PARAM_INFO,  "")
		menu.extra:addParam("chanceQ", "Hitchance for Q",           						 SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
		menu.extra:addParam("chanceE", "Hitchance for E",           						 SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
	
	-- Drawings
	menu:addSubMenu("Drawings", "drawing")
		for spell, circle in pairs(circles) do
			circle:AddToMenu(menu.drawing, "Draw " .. SpellToString(spell) .. " range", true, true, true)
		end
		DLib:AddToMenu(menu.drawing, MainCombo)

	-- Permashow
	menu.combo:permaShow("active")
	menu.harass:permaShow("active")
end

function OnTick()

	OW:EnableAttacks()

	for i, enemy in ipairs(GetEnemyHeroes()) do
			if menu.extra.autoE and ValidTarget(enemy) then
				spells[E]:CastIfDashing(enemy)
		end	

			if menu.extra.autoQ then
				spells[Q]:CastIfDashing(enemy)
		end	

			if menu.extra.autoE2 then
				spells[E]:CastIfImmobile(enemy)
		end
			if menu.extra.autoQ2 then
				spells[Q]:CastIfImmobile(enemy)
		end
	end
end


function combo()

	if menu.combo.active then
		OW:DisableAttacks()

		local targets = { [Q] = STS:GetTarget(spells[Q].range),
						  [W] = STS:GetTarget(spells[W].range),
						  [E] = STS:GetTarget(spells[E].range) }

	
		-- Item
		 if targets[E] and DLib:IsKillable(targets[E], MainCombo) then ItemManager:CastOffensiveItems(targets[E]) end

		-- E
		if targets[E] and menu.combo.useE and spells[E]:IsReady() and not isCharmed(targets[E]) then 
		CastE(targets[E])
		end

		-- Q
		if targets[Q] and menu.combo.useQ and spells[Q]:IsReady() and (isCharmed(targets[Q]) or not menu.extra.charm or not spells[E]:IsReady()) and (not targets[E] or not spells[E]:IsReady() or not menu.combo.useE) then 
		CastQ(targets[Q])
		end

		-- W
		if targets[W] and menu.combo.useW and spells[W]:IsReady() and (isCharmed(targets[W]) or DLib:IsKillable(targets[W], WCombo) or not menu.extra.charm) and (not targets[E] or not spells[E]:IsReady() or not menu.combo.useE) then spells[W]:Cast() end

		-- Combo
		if menu.combo.useE and targets[E] and menu.combo.useQ and targets[Q] and menu.combo.useW and targets[W] and spells[E]:IsReady() and spells[Q]:IsReady() and spells[W]:IsReady() then
			spells[E]:Cast(targets[E])
			spells[Q]:Cast(targets[Q])
			spells[W]:Cast(targets[W])
		end

		if not spells[Q]:IsReady() and not spells[W]:IsReady() and not spells[E]:IsReady() then
			OW:EnableAttacks()
		end
	end
end


function harass()
	if menu.harass.active then

	if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

	local targets = {[Q] = STS:GetTarget(spells[Q].range),
					 [W] = STS:GetTarget(spells[W].range),
					 [E] = STS:GetTarget(spells[E].range) }


	if targets[Q] and spells[Q]:IsReady() and menu.harass.useQ then
		spells[Q]:Cast(targets[Q])
	end

	if targets[W] and spells[W]:IsReady() and menu.harass.useW then
		spells[W]:Cast(targets[W])
	end

	if targets[E] and spells[E]:IsReady() and menu.harass.useE then
		spells[E]:Cast(targets[E])
	end
end
end

function CastQ(Target)
		local targets = {[E] = STS:GetTarget(spells[E].range) }				  
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
		if HitChance >= menu.extra.chanceQ then
		CastSpell(_Q, CastPosition.x, CastPosition.z)
	end
end

function CastE(Target)
		local targets = { [Q] = STS:GetTarget(spells[Q].range) }		  
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellE.Delay, SpellE.Width, SpellE.Range, SpellE.Speed, myHero, true)
		if HitChance >= menu.extra.chanceE then
		CastSpell(_E, CastPosition.x, CastPosition.z)
		
	end
end


function isCharmed(target)
	return HasBuff(target, CHARM_NAME)
end
