-- PiAhri - simple as f***

local version = "1.17"
local AUTOUPDATE = true
local silentUpdate = false

if myHero.charName ~= "Ahri" then return end

require 'VPrediction'
require 'SOW'

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

local VP   = nil
local menu = nil
local target = nil
local PiSetUp = false
local EnemyMinions, JungleMinions = nil, nil
local ignite, igniteReady = nil, false

local CHARM_NAME = "AhriSeduce"
local MAX_RANGE  = 920

local ToInterrupt = {}
local InterruptList = {
    { charName = "Caitlyn", spellName = "CaitlynAceintheHole"},
    { charName = "FiddleSticks", spellName = "Crowstorm"},
    { charName = "FiddleSticks", spellName = "DrainChannel"},
    { charName = "Galio", spellName = "GalioIdolOfDurand"},
    { charName = "Karthus", spellName = "FallenOne"},
    { charName = "Katarina", spellName = "KatarinaR"},
    { charName = "Lucian", spellName = "LucianR"},
    { charName = "Malzahar", spellName = "AlZaharNetherGrasp"},
    { charName = "MissFortune", spellName = "MissFortuneBulletTime"},
    { charName = "Nunu", spellName = "AbsoluteZero"},
    { charName = "Pantheon", spellName = "Pantheon_GrandSkyfall_Jump"},
    { charName = "Shen", spellName = "ShenStandUnited"},
    { charName = "Urgot", spellName = "UrgotSwap2"},
    { charName = "Varus", spellName = "VarusQ"},
    { charName = "Warwick", spellName = "InfiniteDuress"}
}

 
local SpellQ = {Speed = 1600, Range = 950, Delay = 0.250, Width = 100}
local SpellE = {Speed = 1500, Range = 975, Delay = 0.250, Width = 60}
local SpellW = {Speed = nil, Range = 800, Delay = 0.250, Width = nil}

function setupMenu()

	menu = scriptConfig("PiAhri", "PiAhri")

	menu:addSubMenu("Orbwalking", "orbwalking")
		OW:LoadToMenu(menu.orbwalking)
	
	menu:addSubMenu("Combo", "combo")
		menu.combo:addParam("active","Combo active",SCRIPT_PARAM_ONKEYDOWN, false, 32)
		menu.combo:addParam("sep",    "",              SCRIPT_PARAM_INFO,      "")
		menu.combo:addParam("useQ",   "Use Q",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useW",   "Use W",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useE",   "Use E",         SCRIPT_PARAM_ONOFF,     true)

	menu:addSubMenu("Harass", "harass")
		menu.harass:addParam("active",    "Harass active" ,           SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		menu.harass:addParam("sep",       "",                         SCRIPT_PARAM_INFO,      "")
		menu.harass:addParam("mana",      "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		menu.harass:addParam("useQ",      "Use Q",                    SCRIPT_PARAM_ONOFF,     true)
		menu.harass:addParam("useW",      "Use W",                    SCRIPT_PARAM_ONOFF,     true)
		menu.harass:addParam("useE",      "Use E",                    SCRIPT_PARAM_ONOFF,     false)

	menu:addSubMenu("Farm", "farm")
		menu.farm:addParam("active", "Farm",          				 	SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		menu.farm:addParam("sep",     "",                          		SCRIPT_PARAM_INFO,  "")
		menu.farm:addParam("useQ", "Q",           						SCRIPT_PARAM_ONOFF, true)
		
	menu:addSubMenu("Killsteal", "KS")
		menu.KS:addParam("active", "Turn KS on",          				 	SCRIPT_PARAM_ONOFF, true)
		menu.KS:addParam("sep",     "",                          			SCRIPT_PARAM_INFO,  "")
		menu.KS:addParam("useQ", "Use Q",           						SCRIPT_PARAM_ONOFF, true)
		menu.KS:addParam("useE", "Use E",           						SCRIPT_PARAM_ONOFF, true)
		
	menu:addSubMenu("Extra", "extra")
		menu.extra:addParam("charm",   "Try to Charm with E first",          				 SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("sep",     "",                          						 SCRIPT_PARAM_INFO,  "")
		menu.extra:addParam("chanceQ", "Hitchance for Q",           						 SCRIPT_PARAM_SLICE, 2, 1, 5, 0)
		menu.extra:addParam("chanceE", "Hitchance for E",           						 SCRIPT_PARAM_SLICE, 2, 1, 5, 0)

	menu:addSubMenu("Drawings", "Draw")
		menu.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawQ", "Draw Q", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawW", "Draw W", SCRIPT_PARAM_ONOFF, false)
		menu.Draw:addParam("DrawE", "Draw E", SCRIPT_PARAM_ONOFF, true)


	menu.combo:permaShow("active")
	menu.harass:permaShow("active")
	menu.KS:permaShow("active")
	
end

function OnLoad()
	
	VP = VPrediction()
	OW = SOW(VP)
	setupMenu()
	PiSet()

end

function PiSet()
		 for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
        for _, champ in pairs(InterruptList) do
        	if hero.charName == champ.charName then
        		table.insert(ToInterrupt, champ.spellName)
        	end
        end
	end
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 950, DAMAGE_MAGICAL)
	ts.name = "Ahri"
	menu:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 950, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, 950, myHero, MINION_SORT_MAXHEALTH_DEC)
    print('PiAhri ' .. tostring(version) .. ' loaded!')
    PiSetUp = true
end

function OnTick()
	OW:EnableAttacks()
	if PiSetUp then
			AddTickCallback(combo)
			AddTickCallback(harass)
			AddTickCallback(farm)
			AddTickCallback(KS)
			ts:update()
			KillSteal()
			target = ts.target
			OW:ForceTarget(target)
			EnemyMinions:update()
			Checks()
	end
	
end


function combo()

	if menu.combo.active then
	OW:DisableAttacks()
		-- E
		if target and menu.combo.useE and EReady and not isCharmed(target) then 
		CastE(target)
		end

		-- Q
		if target and menu.combo.useQ and QReady and (isCharmed(target) or not menu.extra.charm or not EReady) and (not menu.combo.useE) then 
		CastQ(target)
		end

		-- W
		if target and menu.combo.useW and WReady and (isCharmed(target) or not menu.extra.charm) and (EReady or not menu.combo.useE) and GetDistance(target) <= WRange then CastSpell(_W) end

		-- Combo
		if menu.combo.useE and target and menu.combo.useQ  and menu.combo.useW and EReady and QReady and WReady then
			CastE(target)
			CastQ(target)
			if GetDistance(target) <= SpellW.Range then
				CastSpell(_W)
			end
		end
		if not EReady and not QReady then
			OW:EnableAttacks()
		end
	end
end


function harass()
	if menu.harass.active then
		if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

		if target and QReady and menu.harass.useQ then
			CastQ(target)
		end

		if target and WReady and menu.harass.useW then
			CastE(target)
		end
	end
end

function Farm()
    EnemyMinion:update()
    if myHero.mana/myHero.maxMana * 100 > Menu.Farm.Mana and ValidTarget(EnemyMinion.objects[1],Spell.Q.range) then
        if QREADY and Menu.Farm.Q then
        local qDmg = getDmg("Q",EnemyMinion.objects[1],myHero)
        if qDmg > EnemyMinion.objects[1].health then
        Packets(_Q,EnemyMinion.objects[1])
			end
		end
    end
end
		   

function Packets(spellSlot,castPosition)
    Packet("S_CAST", {spellId = spellSlot, fromX = castPosition.x, fromY = castPosition.z, toX = castPosition.x, toY = castPosition.z}):send()
end

function KillSteal()
	if menu.KS.active then
		local Enemies = GetEnemyHeroes()
		for i, enemy in pairs(Enemies) do
			if ValidTarget(enemy, 1000) and not enemy.dead and GetDistance(enemy) < 1000 then
				if getDmg("Q", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellQ.Range and menu.KS.useQ then
					CastQ(enemy)
				end

			if getDmg("E", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellE.Range and menu.KS.useE then
				CastE(enemy)
			end
		end
	end
end
	IgniteKS()
end


function CastQ(Target)		  
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
		if HitChance >= menu.extra.chanceQ then
		CastSpell(_Q, CastPosition.x, CastPosition.z)
	end
end

function CastE(Target)	  
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellE.Delay, SpellE.Width, SpellE.Range, SpellE.Speed, myHero, true)
		if HitChance >= menu.extra.chanceE then
		CastSpell(_E, CastPosition.x, CastPosition.z)
		
	end
end

function IgniteKS()
	if igniteReady then
		local Enemies = GetEnemyHeroes()
		for idx,val in ipairs(Enemies) do
			if ValidTarget(val, 600) then
                if getDmg("IGNITE", val, myHero) > val.health and GetDistance(val) <= 600 then
                        CastSpell(ignite, val)
                end
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if #ToInterrupt > 0 and menu.extra.interrupt and EReady then
		for _, ability in pairs(ToInterrupt) do
			if spell.name == ability and unit.team ~= myHero.team and GetDistance(unit) < SpellE.Range then
				CastSpell(_E, unit.x, unit.z)
			end
		end
	end
end

function HasBuff(unit, buffname)
    for i = 1, unit.buffCount do
        local tBuff = unit:getBuff(i)
        if tBuff.valid and BuffIsValid(tBuff) and tBuff.name == buffname then
            return true
        end
    end
    return false
end


function isCharmed(target)
	return HasBuff(target, CHARM_NAME)
end

function Checks()
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
            ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
            ignite = SUMMONER_2
    end
    igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
end


function OnDraw()

	if menu.Draw.DrawTarget then
		if target ~= nil then
			DrawCircle3D(target.x, target.y, target.z, VP:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
		end
	end

	if menu.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if menu.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1,  ARGB(255, 0, 255, 255))
	end

	if menu.Draw.DrawE then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellE.Range, 1,  ARGB(255, 0, 255, 255))
	end

end