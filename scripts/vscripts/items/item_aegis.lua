--[[	Author: d2imba
		Date:	13.08.2015	]]

function AegisPickup( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_aegis = keys.modifier_aegis

	-- Display aegis pickup message for all players
	if not caster.has_aegis then
		local line_duration = 7
		Notifications:BottomToAll({hero = caster:GetName(), duration = line_duration})
		Notifications:BottomToAll({text = PlayerResource:GetPlayerName(caster:GetPlayerID()).." ", duration = line_duration, continue = true})
		Notifications:BottomToAll({text = "#imba_player_aegis_message", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
	end

	-- Flag caster as an aegis holder
	caster.has_aegis = true

	-- Nullify the owner's gold/experience bounty
	caster:SetDeathXP(0)
	caster:SetMaximumGoldBounty(0)
	caster:SetMinimumGoldBounty(0)

	-- Apply the Aegis holder modifier
	ability:ApplyDataDrivenModifier(caster, caster, modifier_aegis, {})
end

function AegisHeal( keys )
	local caster = keys.caster
	local sound_heal = keys.sound_heal

	-- Play sound
	caster:EmitSound(sound_heal)

	-- Heal
	caster:Heal(caster:GetMaxHealth(), caster)
	caster:GiveMana(caster:GetMaxMana())

	-- Remove this item
	caster:RemoveItem(ability)
end

function AegisActivate( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_wait = keys.particle_wait
	local particle_respawn = keys.particle_respawn
	local sound_aegis = keys.sound_aegis

	-- Parameters
	local respawn_delay = ability:GetLevelSpecialValueFor("reincarnate_time", ability_level)

	-- Play sound
	caster:EmitSound(sound_aegis)

	-- Play initial particle
	local wait_pfx = ParticleManager:CreateParticle(particle_wait, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(wait_pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(wait_pfx, 1, Vector(respawn_delay, 0, 0))

	-- After the respawn delay, play reincarnation particle
	local respawn_pfx = ParticleManager:CreateParticle(particle_respawn, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(respawn_pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(respawn_pfx, 1, Vector(respawn_delay, 0, 0))

	-- Destroy the Aegis
	caster:RemoveItem(ability)
end