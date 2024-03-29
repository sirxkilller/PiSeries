-- PiSkarner - simple as f***

local version = "1.00"
local AUTOUPDATE = true

if myHero.charName ~= "Skarner" then return end

require 'VPrediction'
require "Collision"
require 'Prodiction'
require 'SOW'

local UPDATE_NAME = "PiSkarner"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/RankedFire/PiSeries/master/PiSkarner.lua".."?rand="..math.random(1,10000)
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


local SpellQ = {Range = 350}
local SpellW = {Range = 175}
local SpellE = {Range = 980, Speed = 1200, Delay = 0.25, Width = 60}
local SpellR = {Range = 450}
local JungleMobs = {}
local JungleFocusMobs = {}
local VP = nil
local Prodict = nil
local menu = nil
local target = nil
local PiSetUp = false
local Mob = nil
local QReady,WReady,EReady,RReady = nil,nil,nil,nil
local ignite, igniteReady = nil, false

function setupMenu()
	
	menu = scriptConfig("PiSkarner", "PiSkarner")
	
	menu:addSubMenu("Orbwalking", "orbwalking")
	OW:LoadToMenu(menu.orbwalking)
	
	menu:addSubMenu("Prediction","pred")
	menu.pred:addParam("Prodiction","PROdiction",SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Combo and Keybindings", "combo")
	menu.combo:addParam("active","Combo active",SCRIPT_PARAM_ONKEYDOWN, false, 32)
	menu.combo:addParam("castR","Cast R to current Target",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
	menu.combo:addParam("sep", "", SCRIPT_PARAM_INFO, "")
	menu.combo:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
	menu.combo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
	menu.combo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Lane Clear", "lane")
	menu.lane:addParam("active", "Clear lane", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	menu.lane:addParam("useQ", "use Q", SCRIPT_PARAM_ONOFF, true)
	menu.lane:addParam("useW", "use W", SCRIPT_PARAM_ONOFF, true)
	menu.lane:addParam("useE", "use E", SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Jungle Clear", "jungle")
	menu.jungle:addParam("active", "Clear Jungle", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	menu.jungle:addParam("useQ", "use Q", SCRIPT_PARAM_ONOFF, true)
	menu.jungle:addParam("useW", "use W", SCRIPT_PARAM_ONOFF, true)
	menu.jungle:addParam("useE", "use E", SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Killsteal", "KS")
	menu.KS:addParam("active", "Turn KS on", 				 	SCRIPT_PARAM_ONOFF, true)
	menu.KS:addParam("sep", "", 			SCRIPT_PARAM_INFO, "")
	menu.KS:addParam("useE", "Use E", 						SCRIPT_PARAM_ONOFF, true)
	menu.KS:addParam("useR", "Use R", 						SCRIPT_PARAM_ONOFF, true)
	menu.KS:addParam("useIG", "Use IGNITE", 					SCRIPT_PARAM_ONOFF, true)
	
	menu:addSubMenu("Drawings", "Draw")
	menu.Draw:addParam("DrawTarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
	menu.Draw:addParam("DrawCollision", "Draw Collision", SCRIPT_PARAM_ONOFF, true)
	menu.Draw:addParam("DrawQ", "Draw Q", SCRIPT_PARAM_ONOFF, true)
	menu.Draw:addParam("DrawW", "Draw W", SCRIPT_PARAM_ONOFF, true)
	menu.Draw:addParam("DrawE", "Draw E", SCRIPT_PARAM_ONOFF, true)
	menu.Draw:addParam("DrawR", "Draw R", SCRIPT_PARAM_ONOFF, true)
	
	
	menu.combo:permaShow("active")
	menu.combo:permaShow("castR")
	menu.jungle:permaShow("active")
	menu.lane:permaShow("active")
	menu.combo:permaShow("useQ")
	menu.combo:permaShow("useW")
	menu.combo:permaShow("useE")
	menu.KS:permaShow("active")
	menu.Draw:permaShow("DrawTarget")
	menu.Draw:permaShow("DrawQ")
	menu.Draw:permaShow("DrawW")
	menu.Draw:permaShow("DrawE")
	
end

function OnLoad()
	PiSet()
end

function PiSet()
	-- intializing Libs
	VP = VPrediction()
	OW = SOW(VP)
	Prodict = ProdictManager.GetInstance()
	-- Menu
	setupMenu()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGICAL)
	ts.name = "Skarner"
	menu:addTS(ts)
	-- selfwritten functions
	ProFunc()
	-- jungle clear
	enemyMinions = minionManager(MINION_ENEMY, SpellE.Range, myHero, MINION_SORT_HEALTH_ASC)
	-- Prediction
	PreE = Collision(SpellE.Range, SpellE.Speed, SpellE.Delay, SpellE.Width)
	-- after loading everything fine, printing out that Script did load successfully.
	print("<b><font color=\"#00A300\">PiSkarner ".. tostring(version)..":</font></b> <font color=\"#FFFFFF\">loaded!</font>")
	-- end the set-up
	PiSetUp = true
end

function OnTick()
	OW:EnableAttacks()
	if PiSetUp then
		target = ts.target
		KillSteal()
		OW:ForceTarget(target)
		Checks()	
		
		if menu.combo.active then combo() end
		if menu.combo.castR and GetDistance(target) <= SpellR.Range then 
			CastSpell(_R,target)
		end
		
		if menu.jungle.active then jungle() end
		if menu.jungle.active then lane() end
		
	end
end		


function combo()
	
	OW:DisableAttacks()
	
	if menu.combo.useE and target then CastE(target) end
	if menu.combo.useW and target then
		if GetDistance(target) < SpellW.Range + 75 then
			CastSpell(_W)
		end
		if GetDistance(target) < SpellQ.Range then
			CastSpell(_Q)
		end
	end
	
	if not EReady then OW:EnableAttacks() end
	
end

function jungle()
	if GetJungleMob() ~= nil then
		if menu.jungle.useQ and GetDistance(GetJungleMob()) <= SpellQ.Range then
			CastSpell(_Q)
		end
		if menu.jungle.useW and GetDistance(GetJungleMob()) <= SpellW.Range then
			CastSpell(_W)
		end
		if menu.jungle.useE and GetDistance(GetJungleMob()) <= SpellE.Range then
			CastSpell(_E,GetJungleMob().x,GetJungleMob().z)
		end
	end
end

function lane()
	if not GetJungleMob() then
		for i, minion in pairs(enemyMinions.objects) do
			if ValidTarget(minion) and minion ~= nil then
				if menu.lane.useQ and GetDistance(minion) < SpellQ.Range then CastSpell(_Q) end
				if menu.lane.useW and GetDistance(minion) < SpellW.Range then CastSpell(_W) end
				if menu.lane.useE and GetDistance(minion) < SpellE.Range then CastE(minion) end
			end		 
		end
	end
end
--JungleMob
function GetJungleMob()
	for _, Mob in pairs(JungleFocusMobs) do
		if ValidTarget(Mob, SpellE.Range) then return Mob end
	end
	for _, Mob in pairs(JungleMobs) do
		if ValidTarget(Mob, SpellE.Range) then return Mob end
	end
end

function OnCreateObj(obj)
	if obj.valid then
		if FocusJungleNames[obj.name] then
			JungleFocusMobs[#JungleFocusMobs+1] = obj
		elseif JungleMobNames[obj.name] then
			JungleMobs[#JungleMobs+1] = obj
		end
	end
end

function OnDeleteObj(obj)
	for i, Mob in pairs(JungleMobs) do
		if obj.name == Mob.name then
			table.remove(JungleMobs, i)
		end
	end
	for i, Mob in pairs(JungleFocusMobs) do
		if obj.name == Mob.name then
			table.remove(JungleFocusMobs, i)
		end
	end
end


function ProFunc()
	for I = 1, heroManager.iCount do
		local hero = heroManager:GetHero(I)
		if hero.team ~= myHero.team then
			Prodict:AddProdictionObject(_Q, SpellQ.Range, SpellQ.Speed, SpellQ.Delay, SpellQ.Width, myHero, CastQ):CanNotMissMode(true, hero)
		end
	end
end

function KillSteal()
	if menu.KS.active then
		local Enemies = GetEnemyHeroes()
		for i, enemy in pairs(Enemies) do
			if ValidTarget(enemy, SpellE.Range) and not enemy.dead and GetDistance(enemy) < SpellE.Range and EReady then
				if getDmg("E", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellE.Range and menu.KS.useE then
					CastE(enemy)
				end
				
				if getDmg("R", enemy, myHero) > enemy.health and GetDistance(enemy) < SpellR.Range and menu.KS.useR then
					Packet("S_CAST", {spellId = id, toX = enemy.x, toY = enemy.z, fromX = myHero.x, fromY = myHero.z, targetNetworkId = enemy.networkID}):send()
				end
			end
		end
	end
	IgniteKS()
end

function CastE(Target)	
	if menu.pred.Prodiction and ValidTarget(Target,SpellE.Range) then
		local pos, info = Prodiction.GetPrediction(Target, SpellE.Range, SpellE.Speed, SpellE.Delay, SpellE.Width)
		local Collide = PreE:GetMinionCollision(pos, myHero)
		if pos and not Collide then
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

function Checks()
	
	QReady = (myHero:CanUseSpell(_Q) == READY)
	WReady = (myHero:CanUseSpell(_W) == READY)
	EReady = (myHero:CanUseSpell(_E) == READY)
	RReady = (myHero:CanUseSpell(_R) == READY)
	
	-- thanks to dieno
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		ignite = SUMMONER_2
	end
	igniteReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	JungleMobNames = { 
		["Wolf8.1.2"]			= true,
		["Wolf8.1.3"]			= true,
		["YoungLizard7.1.2"]	= true,
		["YoungLizard7.1.3"]	= true,
		["LesserWraith9.1.3"]	= true,
		["LesserWraith9.1.2"]	= true,
		["LesserWraith9.1.4"]	= true,
		["YoungLizard10.1.2"]	= true,
		["YoungLizard10.1.3"]	= true,
		["SmallGolem11.1.1"]	= true,
		["Wolf2.1.2"]			= true,
		["Wolf2.1.3"]			= true,
		["YoungLizard1.1.2"]	= true,
		["YoungLizard1.1.3"]	= true,
		["LesserWraith3.1.3"]	= true,
		["LesserWraith3.1.2"]	= true,
		["LesserWraith3.1.4"]	= true,
		["YoungLizard4.1.2"]	= true,
		["YoungLizard4.1.3"]	= true,
		["SmallGolem5.1.1"]		= true
	}
	
	FocusJungleNames = {
		["Dragon6.1.1"]			= true,
		["Worm12.1.1"]			= true,
		["GiantWolf8.1.1"]		= true,
		["AncientGolem7.1.1"]	= true,
		["Wraith9.1.1"]			= true,
		["LizardElder10.1.1"]	= true,
		["Golem11.1.2"]			= true,
		["GiantWolf2.1.1"]		= true,
		["AncientGolem1.1.1"]	= true,
		["Wraith3.1.1"]			= true,
		["LizardElder4.1.1"]	= true,
		["Golem5.1.2"]			= true,
		["GreatWraith13.1.1"]	= true,
		["GreatWraith14.1.1"]	= true
	}
		
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.valid and not object.dead then
			if FocusJungleNames[object.name] then
				JungleFocusMobs[#JungleFocusMobs+1] = object
			elseif JungleMobNames[object.name] then
				JungleMobs[#JungleMobs+1] = object
			end
		end
	end
	
end


function OnDraw()
	
	if menu.Draw.DrawTarget then
		if target ~= nil then
			DrawCircle3D(target.x, target.y, target.z, VP:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
		end
	end
	
	if menu.Draw.DrawQ then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellQ.Range, 1, ARGB(255, 0, 255, 255))
	end
	
	if menu.Draw.DrawW then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellW.Range, 1, ARGB(255, 0, 255, 255))
	end
	
	if menu.Draw.DrawE then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, SpellE.Range, 1, ARGB(255, 0, 255, 255))
	end
	
	if menu.Draw.DrawCollision then
		PreE:DrawCollision(myHero, mousePos)
	end
	
end