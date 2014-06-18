-- PiNidalee - simple as f***

local version = "1.02"
local AUTOUPDATE = true

if myHero.charName ~= "Nidalee" then return end

require 'VPrediction'
require 'Prodiction'
require "Collision"
require 'SOW'

local UPDATE_NAME = "PiNidalee"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/RankedFire/PiSeries/master/PiNidalee.lua".."?rand="..math.random(1,10000)
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
local Prodict = ProdictManager.GetInstance()
local ProdictQ
local ProdictQCol
local PiSetUp = false
local EnemyMinions, JungleMinions = nil, nil
local ignite, igniteReady = nil, false

function setupMenu()

	menu = scriptConfig("PiAhri", "PiAhri")

	menu:addSubMenu("Orbwalking", "orbwalking")
		OW:LoadToMenu(menu.orbwalking)
	
	menu:addSubMenu("Prediction","pred")
		menu.combo:addParam("VPrediction","VPrediction",SCRIPT_PARAM_ONOFF, true)
		menu.combo:addParam("Prodiction","PROdiction",SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Combo and Keybindings", "combo")
		menu.combo:addParam("active","Combo active",SCRIPT_PARAM_ONKEYDOWN, false, 32)
		menu.combo:addParam("Heal","Heal",2,false,string.byte("A"))
		menu.combo:addParam("sep",    "",              SCRIPT_PARAM_INFO,      "")
		menu.combo:addParam("useQ",   "Use Q - Normal Form",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useQ2",   "Use Q - Cougar Form",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useE",   "Use E - Cougar Form",         SCRIPT_PARAM_ONOFF,     true)

	menu:addSubMenu("Harass", "harass")
		menu.harass:addParam("active",    "Harass active" ,           SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		menu.harass:addParam("sep",       "",                         SCRIPT_PARAM_INFO,      "")
		menu.harass:addParam("mana",      "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		menu.harass:addParam("useQ",      "Use Q",                    SCRIPT_PARAM_ONOFF,     true)

	
	Menu:addSubMenu("Heal","Heal")
		menu.Heal:addParam("sep",       "Mode Settings",SCRIPT_PARAM_INFO,"")
		menu.Heal:addParam("HealA","Heal Mode",7,3,{ "HP MODE", "NEAR MOUSE", "PRIOTIZED MODE"})
		menu.Heal:addParam("sep",       "Priority Settings",SCRIPT_PARAM_INFO,"")
		menu.Heal:addSubMenu("Ally Priority","Priority")
		menu.Heal:addParam("sep","Other Options",SCRIPT_PARAM_INFO,"")
		menu.Heal:addParam("Auto","Auto Heal",1,false)
		menu.Heal:addParam("sep","Health & Mana Settings",SCRIPT_PARAM_INFO,"")
		menu.Heal:addParam("AHealth","Minimum Health Percentage to Heal",4,60,0,100,0)
		menu.Heal:addParam("AMana","Minimum Mana Percentage to Heal",4,60,0,100,0)
	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if hero.team == myHero.team then
			if hero == myHero then
				menu.Heal.Priority:addParam(hero.charName,hero.charName,4,1,1,5,0)
			else
				menu.Heal.Priority:addParam(hero.charName,hero.charName,4,2,1,5,0)
		end
	end
end
		
	menu:addSubMenu("Killsteal", "KS")
		menu.KS:addParam("active", "Turn KS on",          				 	SCRIPT_PARAM_ONOFF, true)
		menu.KS:addParam("sep",     "",                          			SCRIPT_PARAM_INFO,  "")
		menu.KS:addParam("useQ", "Use Q",           						SCRIPT_PARAM_ONOFF, true)
		menu.KS:addParam("useIG", "Use IGNITE",           					SCRIPT_PARAM_ONOFF, true)
		
	menu:addSubMenu("Extra", "extra")
		menu.extra:addParam("chanceQ", "Hitchance for Q",           						 SCRIPT_PARAM_SLICE, 2, 1, 5, 0)

	menu:addSubMenu("Drawings", "Draw")
		menu.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawQ", "Draw Q", SCRIPT_PARAM_ONOFF, true)


	menu.combo:permaShow("active")
	menu.harass:permaShow("active")
	menu.KS:permaShow("active")
	
end

function OnLoad()
	
	VP = VPrediction()
	OW = SOW(VP)
	setupMenu()
	PiSet()
	isCougar()

end

function isCougar()
	local couRange = myHero.range + 50
	
	if myHero:GetSpellData(_Q).name == "JavelinToss" then
		local SpellQ = {Speed = 1600, Range = 1250, Delay = 0.250, Width = 30},
		local SpellW = {Range = 900, Delay = 0.90}
		return false
	else
		local SpellQ = {range = couRange},
		local SpellW = {range = 450, speed = math.huge, delay = 0.275, width = 200},
		local SpellE = {range = 400, speed = math.huge, delay = 0.25, width = 250}
		return true
	end
end

function PiSet()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1250, DAMAGE_MAGICAL)
	ts.name = "Nidalee Reworked"
	menu:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 950, myHero, MINION_SORT_MAXHEALTH_DEC)
	ProdictQ = Prodict:AddProdictionObject(_Q, 1500, 1250, 0.250, 30, myHero, CastQ)
	ProdictQCol = Collision(1500, 1300, 0.125, 30)
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			ProdictQ:CanNotMissMode(true, hero)
		end
	end
end
    print('PiNidalee ' .. tostring(version) .. ' loaded!')
    PiSetUp = true
end

function OnTick()
	OW:EnableAttacks()
	if PiSetUp then
			if menu.harass.active then harass() end
			if menu.combo.active then combo() end
			if menu.farm.active then Farm() end
			AddTickCallback(KS)
			ts:update()
			KillSteal()
			target = ts.target
			if target ~= nil then ProdictQ:EnableTarget(target, true) end
			friend = GrabAlly(SpellE.Range)
			OW:ForceTarget(target)
			EnemyMinions:update()
			Checks()
			if not isCougar and Ally ~= nil then
				if menu.Heal.Auto then
					if (myHero.mana/myHero.maxMana * 100 > menu.Heal.AMana) and (Ally.health/Ally.maxHealth * 100 < menu.Heal.AHealth) then
						CastSpell(_E,Ally)
					end
				end
				if menu.General.Heal then
					if (myHero.mana/myHero.maxMana * 100 > menu.Heal.MMana) and (Ally.health/Ally.maxHealth * 100 < menu.Heal.MHealth) then
						CastSpell(_E,Ally)
					end
				end
			end
		end		
	end
end

function combo()

	OW:DisableAttacks()
	local m = myHero
	if isCougar then OW:EnableAttacks() end
	
	if not isCougar and target and QReady and menu.combo.useQ then
		CastQ(target)
	elseif isCougar and target and QReady then
		if Facing(m,target,200) then
			CastW(target)
		if menu.combo.useE and menu.combo.useQ2 then
			CastE(target)
			CastQ(target)
		elseif menu.combo useE then
			CastE(target)
		elseif menu.combo.useQ2 then
			CastQ(target)
		end
	end
	if not QReady and not isCougar then OW:EnableAttacks() end
end

function harass()

	if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

	if not isCougar and target and QReady and menu.harass.useQ then
		CastQ(target)
	end
end

function Farm()
		EnemyMinions:update()
		if QReady and menu.farm.useQ then
		local qDmg = getDmg("Q",EnemyMinions.objects[1],myHero)
		if qDmg > EnemyMinions.objects[1].health then
		Packets(_Q,EnemyMinions.objects[1])	
		end	
	end
 end

function Facing(source, target, lineLength)
	local sourceVector = Vector(source.visionPos.x, source.visionPos.z)
	local sourcePos = Vector(source.x, source.z)
	sourceVector = (sourceVector-sourcePos):normalized()
	sourceVector = sourcePos + (sourceVector*(GetDistance(target, source)))
	return GetDistanceSqr(target, {x = sourceVector.x, z = sourceVector.y}) <= (lineLength and lineLength^2 or 90000)
end 

	function GrabAlly(range)
		if menu.Heal.HealA == 1 then
			return LowestAlly(range)
		elseif menu.Heal.HealA == 2 then
			return NearMouseAlly(range)
		elseif menu.Heal.HealA == 3 then
			return PrioritizedAlly(range)
		end
	end
	function LowestAlly(range)
		for i = 1, heroManager.iCount do
			hero = heroManager:GetHero(i)
			if hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
				if heroTarget == nil then
					heroTarget = hero
				elseif hero.health/hero.maxHealth < heroTarget.health/heroTarget.maxHealth then
					heroTarget = hero
				end
			end
		end
		return heroTarget
	end
	
	function NearMouseAlly(range)
		for i = 1, heroManager.iCount do
			hero = heroManager:GetHero(i)
			if hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
				if heroTarget == nil then
					heroTarget = hero
				elseif GetDistance(myHero,hero) < GetDistance(myHero,heroTarget) then
					heroTarget = hero
				end
			end
		end
		return heroTarget
	end
	
	function PrioritizedAlly(range)
		for i = 1, heroManager.iCount do
			hero = heroManager:GetHero(i)
			if hero.team == myHero.team and not hero.dead and GetDistance(myHero,hero) <= range then
				if heroTarget == nil then
					heroTarget = hero
				elseif menu.Heal.Priority[hero.charName] < menu.Heal.Priority[heroTarget] then
					heroTarget = hero
				end
			end
		end
		return heroTarget
	end

function Packets(spellSlot,castPosition)
    Packet("S_CAST", {spellId = spellSlot, fromX = castPosition.x, fromY = castPosition.z, toX = castPosition.x, toY = castPosition.z}):send()
end

function KillSteal()
	if menu.KS.active then
		local Enemies = GetEnemyHeroes()
		for i, enemy in pairs(Enemies) do
			if ValidTarget(enemy, 900) and not enemy.dead and GetDistance(enemy) < 900 and QReady or EReady then
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

local function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)
end

function CastQ(Target)	
		if menu.pred.VPrediction then
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellQ.Delay, SpellQ.Width, SpellQ.Range, SpellQ.Speed, myHero, false)
			if HitChance >= menu.extra.chanceQ then
			CastSpell(_Q, CastPosition.x, CastPosition.z)
		end
		elseif menu.pred.Prodiction then
			if GetDistance(pos) - getHitBoxRadius(unit)/2 < 1500 and myHero:GetSpellData(_Q).name == "JavelinToss" then
			local willCollide = ProdictQCol:GetMinionCollision(pos, myHero)
			if not willCollide then CastSpell(_Q, pos.x, pos.z) end
		end
	end
end

function CastE(Target)	  
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(Target, SpellE.Delay, SpellE.Width, SpellE.Range, SpellE.Speed, myHero, true)
		if HitChance >= menu.extra.chanceE then
		CastSpell(_E, CastPosition.x, CastPosition.z)
		
	end
end

function IgniteKS()
	if menu.KS.useIG then
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

function isCharmed(target)
    for i = 1, target.buffCount do
        local tBuff = target:getBuff(i)
        if tBuff.valid and BuffIsValid(tBuff) and tBuff.name == CHARM_NAME then
            return true
        end
    end
    return false
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

end