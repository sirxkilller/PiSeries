-- PiNidalee - simple as f***

local version = "1.01"
local AUTOUPDATE = true

if myHero.charName ~= "Nidalee" then return end

require 'VPrediction'
require 'Prodiction'
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

local scriptName = "PiNidalee"
local VP   = nil
local menu = nil
local target = nil
local SpellQ = {}
local SpellW = {}
local SpellE = {}
local PiSetUp = false
local EnemyMinions, JungleMinions = nil, nil
local ignite, igniteReady = nil, false

function setupMenu()

	menu = scriptConfig("PiNidalee", "PiNidalee")

	menu:addSubMenu("Orbwalking", "orbwalking")
		OW:LoadToMenu(menu.orbwalking)
	
	menu:addSubMenu("Prediction","pred")
		menu.pred:addParam("Prodiction","PROdiction",SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Combo and Keybindings", "combo")
		menu.combo:addParam("active","Combo active",SCRIPT_PARAM_ONKEYDOWN, false, 32)
		menu.combo:addParam("jump","Use W to MousePos (Cougar)",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
		menu.combo:addParam("Heal","Heal",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
		menu.combo:addParam("sep",    "",              SCRIPT_PARAM_INFO,      "")
		menu.combo:addParam("useQ",   "Use Q - Normal Form",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useQ2",   "Use Q - Cougar Form",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useW",   "Use W - Cougar Form",         SCRIPT_PARAM_ONOFF,     true)
		menu.combo:addParam("useE",   "Use E - Cougar Form",         SCRIPT_PARAM_ONOFF,     true)

	menu:addSubMenu("Harass", "harass")
		menu.harass:addParam("active",    "Harass active" ,           SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		menu.harass:addParam("sep",       "",                         SCRIPT_PARAM_INFO,      "")
		menu.harass:addParam("useQ",      "Use Q",                    SCRIPT_PARAM_ONOFF,     true)
		menu.harass:addParam("mana",      "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

	
	menu:addSubMenu("Heal","Heal")
		menu.Heal:addParam("sep",       "Mode Settings",SCRIPT_PARAM_INFO,"")
		menu.Heal:addParam("HealA","Heal Mode",7,3,{ "HP MODE", "NEAR MOUSE", "PRIOTIZED MODE"})
		menu.Heal:addParam("sep",       "Priority Settings",SCRIPT_PARAM_INFO,"")
		menu.Heal:addSubMenu("Ally Priority","Priority")
		menu.Heal:addParam("Auto","Auto Heal",SCRIPT_PARAM_ONOFF,false)
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
		menu.extra:addParam("smart", "Smart changing of R",           						 SCRIPT_PARAM_ONOFF, true)

	menu:addSubMenu("Drawings", "Draw")
		menu.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawQ", "Draw Q", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawW", "Draw W if Cougar", SCRIPT_PARAM_ONOFF, true)
		menu.Draw:addParam("DrawE", "Draw E if Cougar", SCRIPT_PARAM_ONOFF, true)


	menu.combo:permaShow("active")
	menu.combo:permaShow("jump")
	menu.combo:permaShow("Heal")
	menu.combo:permaShow("useQ")
	menu.combo:permaShow("useQ2")
	menu.combo:permaShow("useW")
	menu.combo:permaShow("useE")
	menu.harass:permaShow("active")
	menu.KS:permaShow("active")
	menu.extra:permaShow("smart")
	menu.Draw:permaShow("DrawTarget")
	menu.Draw:permaShow("DrawQ")
	menu.Draw:permaShow("DrawW")
	menu.Draw:permaShow("DrawE")
	
end

function OnLoad()

	printMessage = function(message) print("<font color=\"#00A300\"><b>"..scriptName.."</b></font> <font color=\"#FFFFFF\">"..message.."</font>") end
	VP = VPrediction()
	OW = SOW(VP)
	setupMenu()
	PiSet()
	notisCougar()

end

function notisCougar()
	local couRange = myHero.range + 50

	if myHero:GetSpellData(_Q).name == "JavelinToss" then
		SpellQ = {Speed = 1600, Range = 1250, Delay = 0.1, Width = 30}
		SpellW = {Range = 900, Delay = 0.90}
		SpellE = {Range = 600}
		return true
	elseif myHero:GetSpellData(_Q).name == "Takedown" then
		SpellQ = {Range = couRange}
		SpellW = {Range = 450, Speed = math.huge, Delay = 0.275, Width = 200}
		SpellE = {range = couRange, Speed = math.huge, Delay = 0.25, Width = 250}
		return false
	end
end

function PiSet()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1250, DAMAGE_MAGICAL)
	ts.name = "Nidalee Reworked"
	menu:addTS(ts)
	EnemyMinions = minionManager(MINION_ENEMY, 950, myHero, MINION_SORT_MAXHEALTH_DEC)
    printMessage('PiNidalee ' .. tostring(version) .. ' loaded!')
    PiSetUp = true
end

function OnTick()
	OW:EnableAttacks()
	if PiSetUp then
		if menu.harass.active then harass() end
		if menu.combo.active then combo() end
		AddTickCallback(KS)
		ts:update()
		KillSteal()
		target = ts.target
		friend = GrabAlly(SpellE.Range)
		OW:ForceTarget(target)
		EnemyMinions:update()
		notisCougar()
		Checks()	
		if menu.combo.jump and not notisCougar() then 
			CastSpell(_W,mousePos.x,mousePos.z) 
		end
		if notisCougar() and Ally ~= nil then
			if menu.Heal.Auto then
				if (myHero.mana/myHero.maxMana * 100 > menu.Heal.AMana) and (Ally.health/Ally.maxHealth * 100 < menu.Heal.AHealth) then
					CastSpell(_E,Ally)
				end
			end
		elseif menu.combo.Heal then
			CastSpell(_E,myHero)
		end
	end
end		


function combo()
	OW:DisableAttacks()
	local m = myHero
	if not notisCougar() then OW:EnableAttacks() end
	
	if notisCougar() and target and QReady and menu.combo.useQ then
		CastQ(target)
	end
	if notisCougar() and not QReady and target and menu.extra.smart and GetDistance(target) <= 200 then CastSpell(_R) end
	if not notisCougar() and target then
		if menu.combo.useW then
			CastW(target)
		end
		if menu.combo.useE and target then
			CastE(target)
		end
		if menu.combo.useQ2 and target then
			CastQ(target)
		end
		if not notisCougar() and not EReady and not QReady and not WReady and GetDistance(target) < 1250 and menu.extra.smart then
			CastSpell(_R)
		end
	end
	if not QReady and notisCougar() then OW:EnableAttacks() end
end

function harass()

	if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

	if notisCougar() and target and QReady and menu.harass.useQ then
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
		if heroTarget == nil then return end
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
			if heroTarget == nil then return end
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
	if menu.pred.Prodiction and ValidTarget(Target,SpellQ.Range) then
		 local pos, info = Prodiction.GetPrediction(Target, SpellQ.Range, SpellQ.Speed, SpellQ.Delay, SpellQ.Width)
		 if pos then
			CastSpell(_Q, pos.x, pos.z)
		end
	end
end

function CastW(Target)	
	if menu.pred.Prodiction and ValidTarget(Target,SpellW.Range) then
		 local pos, info = Prodiction.GetPrediction(Target, SpellW.Range, SpellW.Speed, SpellW.Delay, SpellW.Width)
		 if pos then
			CastSpell(_W, pos.x, pos.z)
		end
	end
end

function CastE(Target)	
	if menu.pred.Prodiction and ValidTarget(Target,SpellE.Range) then
		 local pos, info = Prodiction.GetPrediction(Target, SpellE.Range, SpellE.Speed, SpellE.Delay, SpellE.Width)
		 if pos then
			CastSpell(_E, pos.x, pos.z)
		end
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
	
	if menu.Draw.DrawW and not notisCougar() then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
	end
	
	if menu.Draw.DrawW and not notisCougar() then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1,  ARGB(255, 0, 255, 255))
	end

end