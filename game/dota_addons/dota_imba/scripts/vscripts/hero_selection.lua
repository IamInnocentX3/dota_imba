--[[
 Hero selection module for D2E.
 This file basically just separates the functions related to hero selection from
 the other functions present in D2E.
]]

--Class definition
if HeroSelection == nil then
	HeroSelection = {}
	HeroSelection.__index = HeroSelection
end

function HeroSelection:HeroListPreLoad()
	-- Retrieve heroes info
	NPC_HEROES_CUSTOM = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	HeroSelection.strength_heroes = {}
	HeroSelection.agility_heroes = {}
	HeroSelection.intellect_heroes = {}

	HeroSelection.strength_heroes_custom = {}
	HeroSelection.agility_heroes_custom = {}
	HeroSelection.intellect_heroes_custom = {}

	HeroSelection.vanilla_heroes = {}
	HeroSelection.imba_heroes = {}
	HeroSelection.random_heroes = {}
	HeroSelection.disabled_10v10_heroes = {}
	HeroSelection.disabled_heroes = {}
	HeroSelection.heroes_custom = {}

	-- New function that retrieves kv infos
	for hero, attributes in pairs(NPC_HEROES_CUSTOM) do
		hero = string.gsub(hero, "imba", "dota")

		if GetKeyValueByHeroName(hero, "IsImba") == 1 then
			if GetKeyValueByHeroName(hero, "IsDisabled") == 1 then
				table.insert(HeroSelection.disabled_10v10_heroes, hero)
			elseif GetKeyValueByHeroName(hero, "IsDisabled") == 2 then
				table.insert(HeroSelection.disabled_heroes, hero)
			else
				table.insert(HeroSelection.imba_heroes, hero)
			end
		else
			if GetKeyValueByHeroName(hero, "IsDisabled") == 1 then
				table.insert(HeroSelection.disabled_10v10_heroes, hero)
			elseif GetKeyValueByHeroName(hero, "IsDisabled") == 2 then
				table.insert(HeroSelection.disabled_heroes, hero)
			else
				table.insert(HeroSelection.vanilla_heroes, hero)
			end
		end

		if GetKeyValueByHeroName(hero, "IsCustom") == 1 then
			HeroSelection:AddCustomHeroToList(hero)
		elseif GetKeyValueByHeroName(hero, "IsCustom") == 0 then
			HeroSelection:AddVanillaHeroToList(hero)
		end

		if GetKeyValueByHeroName(hero, "IsDisabled") == 1 then
		elseif GetKeyValueByHeroName(hero, "IsDisabled") == 2 then
		end
	end

	HeroSelection:HeroList(0.1)
end

function HeroSelection:AddCustomHeroToList(hero_name)
	if GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_STRENGTH" then
		table.insert(HeroSelection.strength_heroes_custom, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_AGILITY" then
		table.insert(HeroSelection.agility_heroes_custom, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_INTELLECT" then
		table.insert(HeroSelection.intellect_heroes_custom, hero_name)
	end

	a = {}
	for k, n in pairs(HeroSelection.strength_heroes_custom) do
		table.insert(a, n)
		HeroSelection.strength_heroes_custom = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.strength_heroes_custom, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.agility_heroes_custom) do
		table.insert(a, n)
		HeroSelection.agility_heroes_custom = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.agility_heroes_custom, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.intellect_heroes_custom) do
		table.insert(a, n)
		HeroSelection.intellect_heroes_custom = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.intellect_heroes_custom, n)
	end
end

function HeroSelection:AddVanillaHeroToList(hero_name)
	if GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_STRENGTH" then
		table.insert(HeroSelection.strength_heroes, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_AGILITY" then
		table.insert(HeroSelection.agility_heroes, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "AttributePrimary") == "DOTA_ATTRIBUTE_INTELLECT" then
		table.insert(HeroSelection.intellect_heroes, hero_name)
	end

	a = {}
	for k, n in pairs(HeroSelection.strength_heroes) do
		table.insert(a, n)
		HeroSelection.strength_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.strength_heroes, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.agility_heroes) do
		table.insert(a, n)
		HeroSelection.agility_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.agility_heroes, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.intellect_heroes) do
		table.insert(a, n)
		HeroSelection.intellect_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.intellect_heroes, n)
	end
end

function HeroSelection:HeroList(delay)
	Timers:CreateTimer(delay, function()
		CustomNetTables:SetTableValue("game_options", "hero_list", {
			Strength = HeroSelection.strength_heroes,
			Agility = HeroSelection.agility_heroes,
			Intellect = HeroSelection.intellect_heroes,
			StrengthCustom = HeroSelection.strength_heroes_custom,
			AgilityCustom = HeroSelection.agility_heroes_custom,
			IntellectCustom = HeroSelection.intellect_heroes_custom,
			Imba = HeroSelection.imba_heroes,
			Disabled10v10 = HeroSelection.disabled_10v10_heroes,
			Disabled = HeroSelection.disabled_heroes
		})

		table.deepmerge(HeroSelection.random_heroes, HeroSelection.vanilla_heroes)
		table.deepmerge(HeroSelection.random_heroes, HeroSelection.imba_heroes)

--		print("Custom Heroes:")
--		PrintTable(HeroSelection.heroes_custom)
	end)

	HeroSelection:Start(0.1)
end

--[[
	Start
	Call this function from your gamemode once the gamestate changes
	to pre-game to start the hero selection.
]]
function HeroSelection:Start(delay)
	Timers:CreateTimer(delay, function()
		-- Figure out which players have to pick
		HeroSelection.HorriblyImplementedReconnectDetection = {}
		HeroSelection.radiantPicks = {}
		HeroSelection.direPicks = {}
		HeroSelection.playerPicks = {}
		HeroSelection.playerPickState = {}
		HeroSelection.numPickers = 0
--		print(DOTA_MAX_PLAYERS)
		for pID = 0, DOTA_MAX_PLAYERS -1 do
			if PlayerResource:IsValidPlayer( pID ) then
				HeroSelection.numPickers = self.numPickers + 1
				HeroSelection.playerPickState[pID] = {}
				HeroSelection.playerPickState[pID].pick_state = "selecting_hero"
				HeroSelection.playerPickState[pID].repick_state = false
				HeroSelection.HorriblyImplementedReconnectDetection[pID] = true			
			end
		end

		-- Start the pick timer
		HeroSelection.TimeLeft = HERO_SELECTION_TIME
		Timers:CreateTimer( 0.04, HeroSelection.Tick )

		-- Keep track of the number of players that have picked
		HeroSelection.playersPicked = 0

		-- Listen for pick and repick events
		HeroSelection.listener_select = CustomGameEventManager:RegisterListener("hero_selected", HeroSelection.HeroSelect )
		HeroSelection.listener_random = CustomGameEventManager:RegisterListener("hero_randomed", HeroSelection.RandomHero )
		HeroSelection.listener_imba_random = CustomGameEventManager:RegisterListener("hero_imba_randomed", HeroSelection.RandomImbaHero )
		HeroSelection.listener_repick = CustomGameEventManager:RegisterListener("hero_repicked", HeroSelection.HeroRepicked )
		HeroSelection.listener_ui_initialize = CustomGameEventManager:RegisterListener("ui_initialized", HeroSelection.UiInitialized )
		HeroSelection.listener_abilities_requested = CustomGameEventManager:RegisterListener("pick_abilities_requested", HeroSelection.PickAbilitiesRequested )

		-- Play relevant pick lines
		if IMBA_PICK_MODE_ALL_RANDOM or IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO then
			EmitGlobalSound("announcer_announcer_type_all_random")	
		elseif IMBA_PICK_MODE_ARENA_MODE then
			EmitGlobalSound("announcer_announcer_type_death_match")
		else
			EmitGlobalSound("announcer_announcer_type_all_pick")
		end
	end)
end

-- Horribly implemented reconnection detection
function HeroSelection:UiInitialized(event)
	Timers:CreateTimer(0.04, function()
		HeroSelection.HorriblyImplementedReconnectDetection[event.PlayerID] = true
	end)
end 

--[[
	Tick
	A tick of the pick timer.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:Tick() 
	-- Send a time update to all clients
	if HeroSelection.TimeLeft >= 0 then
		CustomGameEventManager:Send_ServerToAllClients( "picking_time_update", {time = HeroSelection.TimeLeft} )
	end

	-- Tick away a second of time
	HeroSelection.TimeLeft = HeroSelection.TimeLeft - 1
	if HeroSelection.TimeLeft < 0 then
		-- End picking phase
		HeroSelection:EndPicking()
		return nil
	elseif HeroSelection.TimeLeft >= 0 then
		return 1
	end
end

function HeroSelection:RandomHero(event)
local id = event.PlayerID
if PlayerResource:GetConnectionState(id) == 1 then
	print("Bot, ignoring..")
else
	if HeroSelection.playerPickState[id].pick_state ~= "selecting_hero" then
		return nil
	end
end

	-- Roll a random hero
	local random_hero = HeroSelection.random_heroes[RandomInt(1, #HeroSelection.random_heroes)]

	-- Check if this random hero hasn't already been picked
	if PlayerResource:GetTeam(id) == DOTA_TEAM_GOODGUYS then
		for _, picked_hero in pairs(HeroSelection.radiantPicks) do
			if random_hero == picked_hero then
				HeroSelection:RandomHero({PlayerID = id})
				break
			end
		end
	else
		for _, picked_hero in pairs(HeroSelection.direPicks) do
			if random_hero == picked_hero then
				HeroSelection:RandomHero({PlayerID = id})
				break
			end
		end
	end

	-- Flag the player as having randomed
	PlayerResource:SetHasRandomed(id)

	-- If it's a valid hero, allow the player to select it
	HeroSelection:HeroSelect({PlayerID = id, HeroName = random_hero, HasRandomed = true})

	-- The person has randomed (separate from Set/HasRandomed, because those cannot be unset)
	HeroSelection.playerPickState[id].random_state = true

	-- Send a Custom Message in PreGame Chat to tell other players this player has randomed
	Chat:PlayerRandomed(id, PlayerResource:GetPlayer(id), PlayerResource:GetTeam(id), random_hero)
end

function HeroSelection:RandomImbaHero(event)
local id = event.PlayerID

	if HeroSelection.playerPickState[id].pick_state ~= "selecting_hero" then return nil end

	local random_hero = HeroSelection.imba_heroes[RandomInt(1, #HeroSelection.imba_heroes)]

	if PlayerResource:GetTeam(id) == DOTA_TEAM_GOODGUYS then
		for _, picked_hero in pairs(HeroSelection.radiantPicks) do
			if random_hero == picked_hero then
				HeroSelection:RandomHero({PlayerID = id})
				break
			end
		end
	else
		for _, picked_hero in pairs(HeroSelection.direPicks) do
			if random_hero == picked_hero then
				HeroSelection:RandomHero({PlayerID = id})
				break
			end
		end
	end

	PlayerResource:SetHasRandomed(id)
	HeroSelection:HeroSelect({PlayerID = id, HeroName = random_hero, HasRandomed = true})
	HeroSelection.playerPickState[id].random_state = true
	Chat:PlayerRandomed(id, PlayerResource:GetPlayer(id), PlayerResource:GetTeam(id), random_hero)
end

global_chat_randomed = 0
function HeroSelection:RandomSameHero(event)
local id = event.PlayerID
--	if id ~= -1 and HeroSelection.playerPickState[id].pick_state ~= "selecting_hero" then return end

	-- Roll a random hero, and keep it stored
	if not random_hero then random_hero = normal_heroes[RandomInt(1, #normal_heroes)] end
--	print(random_hero)

	PlayerResource:SetHasRandomed(id)
	HeroSelection:HeroSelect({PlayerID = id, HeroName = random_hero, HasRandomed = true})
	HeroSelection.playerPickState[id].random_state = true
	if global_chat_randomed == 0 then
		global_chat_randomed = 1
		Chat:PlayerRandomed(id, PlayerResource:GetPlayer(id), PlayerResource:GetTeam(id), random_hero)
	end
end

--[[
	HeroSelect
	A player has selected a hero. This function is caled by the CustomGameEventManager
	once a 'hero_selected' event was seen.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:HeroSelect(event)

	-- If this player has not picked yet give him the hero
	if PlayerResource:GetConnectionState(event.PlayerID) == 1 then
		HeroSelection:AssignHero( event.PlayerID, event.HeroName )
	else
		if not HeroSelection.playerPicks[ event.PlayerID ] then
			HeroSelection.playersPicked = HeroSelection.playersPicked + 1
			HeroSelection.playerPicks[ event.PlayerID ] = event.HeroName

			-- Add the picked hero to the list of picks of the relevant team
			if PlayerResource:GetTeam(event.PlayerID) == DOTA_TEAM_GOODGUYS then
				HeroSelection.radiantPicks[#HeroSelection.radiantPicks + 1] = event.HeroName
			else
				HeroSelection.direPicks[#HeroSelection.direPicks + 1] = event.HeroName
			end

			-- Send a pick event to all clients
			local has_randomed = false
			if event.HasRandomed then has_randomed = true end
			CustomGameEventManager:Send_ServerToAllClients("hero_picked", {PlayerID = event.PlayerID, HeroName = event.HeroName, Team = PlayerResource:GetTeam(event.PlayerID), HasRandomed = has_randomed})
			if PlayerResource:GetConnectionState(event.PlayerID) ~= 1 then
				HeroSelection.playerPickState[event.PlayerID].pick_state = "selected_hero"
			end

			-- Assign the hero if picking is over
			if HeroSelection.TimeLeft <= 0 and HeroSelection.playerPickState[event.PlayerID].pick_state ~= "in_game" then
				HeroSelection:AssignHero( event.PlayerID, event.HeroName )
				HeroSelection.playerPickState[event.PlayerID].pick_state = "in_game"
				CustomGameEventManager:Send_ServerToAllClients("hero_loading_done", {} )
			end

			-- Play pick sound to the player
			EmitSoundOnClient("HeroPicker.Selected", PlayerResource:GetPlayer(event.PlayerID))
		end
	end

	-- If this is All Random and the player picked a hero manually, refuse it
	if IMBA_PICK_MODE_ALL_RANDOM or IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO and (not event.HasRandomed) then
		return nil
	end

    if IMBA_HERO_PICK_RULE == 0 then
        -- All Unique heroes
        for _, picked_hero in pairs(HeroSelection.radiantPicks) do
            if event.HeroName == picked_hero then
                return nil
            end
        end
        for _, picked_hero in pairs(HeroSelection.direPicks) do
            if event.HeroName == picked_hero then
                return nil
            end
        end
    elseif IMBA_HERO_PICK_RULE == 1 then
        -- Allow Team pick same hero
        -- Check if this hero hasn't already been picked
        if PlayerResource:GetTeam(event.PlayerID) == DOTA_TEAM_GOODGUYS then
            for _, picked_hero in pairs(HeroSelection.radiantPicks) do
                if event.HeroName == picked_hero then
                    return nil
                end
            end
        else
            for _, picked_hero in pairs(HeroSelection.direPicks) do
                if event.HeroName == picked_hero then
                    return nil
                end
            end
        end
    end

	--Check if all heroes have been picked
--	if HeroSelection.playersPicked >= HeroSelection.numPickers then

		--End picking
--		HeroSelection.TimeLeft = 0
--	end
end

-- Handles player repick
function HeroSelection:HeroRepicked( event )
	local player_id = event.PlayerID
	local hero_name = HeroSelection.playerPicks[player_id]

	-- Fire repick event to all players
	CustomGameEventManager:Send_ServerToAllClients("hero_unpicked", {PlayerID = player_id, HeroName = hero_name, Team = PlayerResource:GetTeam(player_id)})

	-- Remove the player's currently picked hero
	HeroSelection.playerPicks[ player_id ] = nil

	-- Remove the picked hero to the list of picks of the relevant team
	if PlayerResource:GetTeam(player_id) == DOTA_TEAM_GOODGUYS then
		for pick_index, team_pick in pairs(HeroSelection.radiantPicks) do
			if team_pick == hero_name then
				table.remove(HeroSelection.radiantPicks, pick_index)
			end
		end
	else
		for pick_index, team_pick in pairs(HeroSelection.direPicks) do
			if team_pick == hero_name then
				table.remove(HeroSelection.direPicks, pick_index)
			end
		end
	end

	-- Decrement player pick count
	HeroSelection.playersPicked = HeroSelection.playersPicked - 1

	-- Flag the player as having repicked
	PlayerResource:CustomSetHasRepicked(player_id, true)
	HeroSelection.playerPickState[player_id].pick_state = "selecting_hero"
	HeroSelection.playerPickState[player_id].repick_state = true
	HeroSelection.playerPickState[player_id].random_state = false

	-- Play pick sound to the player
	EmitSoundOnClient("ui.pick_repick", PlayerResource:GetPlayer(player_id))
end

--[[
	EndPicking
	The final function of hero selection which is called once the selection is done.
	This function spawns the heroes for the players and signals the picking screen
	to disappear.
]]
function HeroSelection:EndPicking()
local time = 0.0

	--Stop listening to events (except picks)
	CustomGameEventManager:UnregisterListener( self.listener_repick )

	-- Let all clients know the picking phase has ended
	CustomGameEventManager:Send_ServerToAllClients("picking_done", {} )

	-- Assign the picked heroes to all players that have picked
	for player_id = 0, HeroSelection.numPickers do
		if HeroSelection.playerPicks[player_id] and HeroSelection.playerPickState[player_id].pick_state ~= "in_game" then
			HeroSelection:AssignHero(player_id, HeroSelection.playerPicks[player_id])
			HeroSelection.playerPickState[player_id].pick_state = "in_game"
		end
	end

	-- Let all clients know hero loading has ended
	CustomGameEventManager:Send_ServerToAllClients("hero_loading_done", {} )

	-- Stop picking phase music
	StopSoundOn("Imba.PickPhaseDrums", HeroSelection.pick_sound_dummy_good)
	StopSoundOn("Imba.PickPhaseDrums", HeroSelection.pick_sound_dummy_bad)

	-- Destroy dummy!
	UTIL_Remove(HeroSelection.pick_sound_dummy_good) 
	UTIL_Remove(HeroSelection.pick_sound_dummy_bad) 
end

--[[
	AssignHero
	Assign a hero to the player. Replaces the current hero of the player
	with the selected hero, after it has finished precaching.
	Params:
		- player_id {integer} - The playerID of the player to assign to.
		- hero_name {string} - The unit name of the hero to assign (e.g. 'npc_dota_hero_rubick')
]]
function HeroSelection:AssignHero(player_id, hero_name)
	PrecacheUnitByNameAsync(hero_name, function()
		-- Dummy invisible wisp
		local wisp = PlayerResource:GetPlayer(player_id):GetAssignedHero()
		local hero = PlayerResource:ReplaceHeroWith(player_id, hero_name, 0, 0 )
		hero.pID = player_id
--		print(hero.pID)
--		print(hero_name)

		-- If this is a "real" wisp, tag it
		if hero:GetUnitName() == "npc_dota_hero_wisp" then
			hero.is_real_wisp = true
		end

		-------------------------------------------------------------------------------------------------
		-- IMBA: First hero spawn initialization
		-------------------------------------------------------------------------------------------------
		
		hero:RespawnHero(false, false, false)
		PlayerResource:SetCameraTarget(player_id, hero)
		Timers:CreateTimer(FrameTime(), function()
			PlayerResource:SetCameraTarget(player_id, nil)
		end)

		-- Set the picked hero for this player
		PlayerResource:SetPickedHero(player_id, hero)

		-- Initializes player data if this is a bot
		if PlayerResource:GetConnectionState(player_id) == 1 then
			PlayerResource:InitPlayerData(player_id)
		end

		-- Make heroes briefly visible on spawn (to prevent bad fog interactions)
		Timers:CreateTimer(0.5, function()
			hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
			hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)
		end)

		-- Set up initial level 1 experience bounty
		hero:SetCustomDeathXP(HERO_XP_BOUNTY_PER_LEVEL[1])

		-- Set up initial level
		if HERO_STARTING_LEVEL > 1 then
			hero:AddExperience(XP_PER_LEVEL_TABLE[HERO_STARTING_LEVEL], DOTA_ModifyXP_CreepKill, false, true)
		end

		-- Set up initial gold
		-- local has_randomed = PlayerResource:HasRandomed(player_id)
		-- This randomed variable gets reset when the player chooses to Repick, so you can detect a rerandom
		local has_randomed = HeroSelection.playerPickState[player_id].random_state
		local has_repicked = PlayerResource:CustomGetHasRepicked(player_id)

		if has_repicked and has_randomed then
			PlayerResource:SetGold(player_id, HERO_RERANDOM_GOLD, false)
		elseif has_repicked then
			PlayerResource:SetGold(player_id, HERO_REPICK_GOLD, false)
		elseif has_randomed or IMBA_PICK_MODE_ALL_RANDOM or IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO then
			PlayerResource:SetGold(player_id, HERO_RANDOM_GOLD, false)
		else
			PlayerResource:SetGold(player_id, HERO_INITIAL_GOLD, false)
		end

		-- Apply generic talents handler
		hero:AddNewModifier(hero, nil, "modifier_imba_generic_talents_handler", {})

		-- Initialize innate hero abilities
		InitializeInnateAbilities(hero)

		-- Initialize Invoker's innate invoke buff
		-- TODO: This should be removed when another solution is found, like giving Invoker a hidden passive ability to apply the modifier
		if hero:HasAbility("invoker_invoke") then
			hero:AddNewModifier(hero, hero:FindAbilityByName("invoker_invoke"), "modifier_imba_invoke_buff", {})
		end

		-- If a custom hero has been choosed
		for int, unit in pairs(HeroSelection.heroes_custom) do
			if unit == hero_name then
				CustomHeroAttachments(hero, false)
			end
		end

		-- Set up player color
		PlayerResource:SetCustomPlayerColor(player_id, PLAYER_COLORS[player_id][1], PLAYER_COLORS[player_id][2], PLAYER_COLORS[player_id][3])

		Timers:CreateTimer(3.0, function()
			if not hero:HasModifier("modifier_command_restricted") then
				PlayerResource:SetCameraTarget(player_id, nil)
			end
			UTIL_Remove(wisp)
		end)

		-- Set initial spawn setup as having been done
		PlayerResource:IncrementTeamPlayerCount(player_id)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "picking_done", {})

		-- This is from imba_talent_events.lua
		PopulateHeroImbaTalents(hero);
	end, player_id)
end

-- Sends this hero's nonhidden abilities to the client
function HeroSelection:PickAbilitiesRequested(event)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(event.PlayerID), "pick_abilities", { heroAbilities = HeroSelection:GetPickScreenAbilities(event.HeroName) })
end

-- Returns an array with the hero's non-hidden abilities
function HeroSelection:GetPickScreenAbilities(hero_name)
local hero_abilities = {}

	for i = 1, 8 do
		if GetKeyValueByHeroName(hero_name, "Ability"..i) ~= nil then
			hero_abilities[i] = GetKeyValueByHeroName(hero_name, "Ability"..i)
		end
	end
	return hero_abilities
end