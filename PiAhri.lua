-- PiAhri - simple as f***

local version = 1.08
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
local OW   = nil
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

function PiSet()
        for _, champ in pairs(InterruptList) do
        	if hero.charName == champ.charName then
        		table.insert(ToInterrupt, champ.spellName)
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

function GetCustomTarget()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end

function OnLoad()
	PiSet()
	VP = VPrediction()
	OW = SOW(VP)
	Checks()
	setupMenu()

end

function setupMenu()

	menu = scriptConfig("Pi" .. player.charName, "Pi" .. player.charName)

	menu:addSubMenu("Orbwalking", "orbwalking")
		OW:LoadToMenu(menu.orbwalking)


	menu:addSubMenu("Combo", "combo")
		menu.combo:addParam("active", "Combo active" , SCRIPT_PARAM_ONKEYDOWN, false, 32)
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
		menu.extra:addParam("active", "Farm",          				 	SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("sep",     "",                          	SCRIPT_PARAM_INFO,  "")
		menu.extra:addParam("useQ", "Q",           						SCRIPT_PARAM_ONOFF, true)
		menu.extra:addParam("useW", "W",           						SCRIPT_PARAM_ONOFF, true)
		
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
end

function OnTick()

	if PiSetUp then
			AddTickCallback(combo)
			AddTickCallback(harass)
			ts:update()
			KillSteal()
			target = ts.target
			EnemyMinions:update()
	end
	OW:EnableAttacks()
	
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

		if not QReady and not WReady and not EReady then
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
	if menu.farm.active then
		if menu.farm.useQ then
			FarmQ()
		end
	end
end

function FarmQ()
	if QReady and #EnemyMinions.objects > 0 then
		local QPos = GetBestQPositionFarm()
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	end
end

function GetBestQPositionFarm()
	local MaxQ = 0 
	local MaxQPos 
	for i, minion in pairs(EnemyMinions.objects) do
		local hitQ = countminionshitQ(minion)
		if hitQ ~= nil and hitQ > MaxQ or MaxQPos == nil then
			MaxQPos = minion
			MaxQ = hitQ
		end
	end

	if MaxQPos then
		local CastPosition = MaxQPos
		return CastPosition
	else
		return nil
	end
end

function countminionshitQ(pos)
	local n = 0
	local ExtendedVector = Vector(myHero) + Vector(Vector(pos) - Vector(myHero)):normalized()*SpellQ.Range
	local EndPoint = Vector(myHero) + ExtendedVector
	for i, minion in ipairs(EnemyMinions.objects) do
		local MinionPointSegment, MinionPointLine, MinionIsOnSegment =  VectorPointProjectionOnLineSegment(Vector(myHero), Vector(EndPoint), Vector(minion)) 
		local MinionPointSegment3D = {x=MinionPointSegment.x, y=pos.y, z=MinionPointSegment.y}
		if MinionIsOnSegment and GetDistance(MinionPointSegment3D, pos) < SpellQ.Width then
			n = n +1
		end
	end
	return n
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