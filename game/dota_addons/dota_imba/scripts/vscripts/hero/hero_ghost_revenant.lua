-----------------------------------------------------------------------------------------------------------
-- Wraith
-----------------------------------------------------------------------------------------------------------
ghost_revenant_wraith = class({})
LinkLuaModifier("modifier_ghost_revenant_wraith", "hero/hero_ghost_revenant.lua", LUA_MODIFIER_MOTION_NONE)

function ghost_revenant_wraith:GetAbilityTextureName()
   return "custom/ghost_revenant_wraith"
end

function ghost_revenant_wraith:IsHiddenWhenStolen()
	return false
end

function ghost_revenant_wraith:OnSpellStart()
local caster = self:GetCaster()
local ability = self
local sound_cast = "DOTA_Item.GhostScepter.Activate"
local modifier_decrep = "modifier_ghost_revenant_wraith"

local duration = ability:GetSpecialValueFor("duration")

	-- Play cast sound
	EmitSoundOn(sound_cast, caster)

	-- Apply decrepify modifier on target
	caster:AddNewModifier(caster, ability, modifier_decrep, {duration = duration})
end

-----------------------------------------------------------------------------------------------------------
-- Wraith modifier
-----------------------------------------------------------------------------------------------------------
modifier_ghost_revenant_wraith = class({})

function modifier_ghost_revenant_wraith:OnRefresh() 
	if IsServer() then
		self:OnDestroy()
	end  
end

function modifier_ghost_revenant_wraith:IsHidden() return false end
function modifier_ghost_revenant_wraith:IsPurgable() return true end
function modifier_ghost_revenant_wraith:IsDebuff() return false end

function modifier_ghost_revenant_wraith:CheckState()
	local state = {
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
	return state
end

function modifier_ghost_revenant_wraith:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}

	return decFuncs
end

function modifier_ghost_revenant_wraith:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("res_reduction_pct") * (-1)
end

function modifier_ghost_revenant_wraith:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_ms_pct")
end

function modifier_ghost_revenant_wraith:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_ghost_revenant_wraith:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_ghost_revenant_wraith:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

-----------------------------------------------------------------------------------------------------------
--	Blackjack
-----------------------------------------------------------------------------------------------------------

if ghost_revenant_blackjack == nil then ghost_revenant_blackjack = class({}) end
LinkLuaModifier( "modifier_ghost_revenant_blackjack_debuff", "hero/hero_ghost_revenant.lua", LUA_MODIFIER_MOTION_NONE )	-- Armor/vision debuff

function ghost_revenant_blackjack:GetAbilityTextureName()
   return "custom/ghost_revenant_blackjack"
end

function ghost_revenant_blackjack:OnSpellStart()	
local caster = self:GetCaster()
local caster_loc = caster:GetAbsOrigin()
local target_loc = self:GetCursorPosition()

local projectile_radius = self:GetSpecialValueFor("projectile_radius")
local projectile_length = self:GetSpecialValueFor("projectile_length")
local projectile_speed = self:GetSpecialValueFor("projectile_speed")
local projectile_cone = self:GetSpecialValueFor("projectile_cone")
local projectile_amount = self:GetSpecialValueFor("projectile_amount")
local projectile_vision = self:GetSpecialValueFor("projectile_vision")

-- Determine projectile geometry
local projectile_directions = {}
local main_direction = (target_loc - caster_loc):Normalized()
if target_loc == caster_loc then
	main_direction = caster:GetForwardVector()		
end
local angle_step = projectile_cone / (projectile_amount - 1)
for i = 1, projectile_amount do
	projectile_directions[i] = RotatePosition(caster_loc, QAngle(0, (i - 1) * angle_step - projectile_cone * 0.5, 0), caster_loc + main_direction * 50)
end

	local blackjack_projectile = {
		Ability				= self,
		EffectName			= "particles/hero/ghost_revenant/blackjack_projectile.vpcf",
		vSpawnOrigin		= caster_loc + main_direction * 50 + Vector(0, 0, 100),
		fDistance			= projectile_length,
		fStartRadius		= projectile_radius,
		fEndRadius			= projectile_radius,
		Source				= caster,
		bHasFrontalCone		= false,
		bReplaceExisting	= false,
		iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
--		iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	--	fExpireTime			= ,
		bDeleteOnHit		= true,
		vVelocity			= main_direction * projectile_speed,
		bProvidesVision		= true, 
		iVisionRadius		= projectile_vision,
		iVisionTeamNumber	= caster:GetTeamNumber(),
	}

	caster:EmitSound("Imba.DesolatorCast")

	local projectiles_launched = 0
	Timers:CreateTimer(function()
		blackjack_projectile.vSpawnOrigin = projectile_directions[projectiles_launched + 1] + Vector(0, 0, 100)
		blackjack_projectile.vVelocity = (projectile_directions[projectiles_launched + 1] - caster_loc):Normalized() * projectile_speed
		blackjack_projectile.vVelocity.z = 0
		ProjectileManager:CreateLinearProjectile(blackjack_projectile)

		projectiles_launched = projectiles_launched + 1
		if projectiles_launched < projectile_amount then
			return 0.0
		end
	end)	
end

function ghost_revenant_blackjack:OnProjectileHit(target, target_loc)
	if IsServer() and target then
		local caster = self:GetCaster()
		local damage_type = self:GetAbilityDamageType()
		local stun_duration = self:GetSpecialValueFor("stun_duration")
		local damage = self:GetSpecialValueFor("damage")
		if target then location = target:GetAbsOrigin() end

		target:EmitSound("Item_Desolator.Target")
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type,})
		target:AddNewModifier(caster, self, "modifier_ghost_revenant_blackjack_debuff", {duration = stun_duration})
		return true
	end
end

-----------------------------------------------------------------------------------------------------------
--	Blackjack Debuff
-----------------------------------------------------------------------------------------------------------

if modifier_ghost_revenant_blackjack_debuff == nil then modifier_ghost_revenant_blackjack_debuff = class({}) end

function modifier_ghost_revenant_blackjack_debuff:OnCreated()
	local ability = self:GetAbility()
	if ability then
		self.armor_reduction = (-1) * ability:GetSpecialValueFor("armor_reduction")
	end
end

function modifier_ghost_revenant_blackjack_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true
	}
	return state    
end

function modifier_ghost_revenant_blackjack_debuff:IsHidden() return false end
function modifier_ghost_revenant_blackjack_debuff:IsDebuff() return true end
function modifier_ghost_revenant_blackjack_debuff:IsPurgable() return true end
function modifier_ghost_revenant_blackjack_debuff:IsPurgable() return false end
function modifier_ghost_revenant_blackjack_debuff:IsStunDebuff() return true end
function modifier_ghost_revenant_blackjack_debuff:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_ghost_revenant_blackjack_debuff:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

-----------------------------------------------------------------------------------------------------------
--	Miasma
-----------------------------------------------------------------------------------------------------------
LinkLuaModifier( "modifier_ghost_revenant_miasma", "hero/hero_ghost_revenant.lua", LUA_MODIFIER_MOTION_NONE )
if ghost_revenant_miasma == nil then ghost_revenant_miasma = class({}) end

function ghost_revenant_miasma:GetAbilityTextureName()
   return "custom/ghost_revenant_miasma"
end

function ghost_revenant_miasma:OnAbilityPhaseStart()
	EmitSoundOn("Hero_Warlock.RainOfChaos_buildup", self:GetCaster())
	return true
end

function ghost_revenant_miasma:OnSpellStart()
local caster = self:GetCaster()
local target = self:GetCursorPosition()
local aoe = self:GetSpecialValueFor("area_of_effect")
local duration = self:GetSpecialValueFor("duration")

	caster:EmitSound("DOTA_Item.DustOfAppearance.Activate")
	local particle = ParticleManager:CreateParticle("particles/hero/ghost_revenant/miasma.vpcf", PATTACH_ABSORIGIN_FOLLOW, nil)
	ParticleManager:SetParticleControl(particle, 0, target)
--	ParticleManager:SetParticleControl(particle, 2, target)
--	ParticleManager:SetParticleControl(particle, 4, target)

	local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY , DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO , DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER , false)
	for _,unit in pairs(targets) do
		unit:AddNewModifier(caster, self, "modifier_ghost_revenant_miasma", {duration = duration})
	end
end

-----------------------------------------------------------------------------------------------------------
--	Reveal modifier
-----------------------------------------------------------------------------------------------------------

if modifier_ghost_revenant_miasma == nil then modifier_ghost_revenant_miasma = class({}) end
function modifier_ghost_revenant_miasma:IsDebuff() return true end
function modifier_ghost_revenant_miasma:IsHidden() return false end
function modifier_ghost_revenant_miasma:IsPurgable() return true end

function modifier_ghost_revenant_miasma:DeclareFunctions()	
	local decFuncs = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return decFuncs	
end



function modifier_ghost_revenant_miasma:OnCreated()
	if IsServer() then
		self.damage = self:GetAbility():GetSpecialValueFor("dmg_per_sec")
		self.tick = self:GetAbility():GetSpecialValueFor("tick")

		self:StartIntervalThink(self.tick)
	end
end

function modifier_ghost_revenant_miasma:GetEffectName()
	return "particles/items2_fx/true_sight_debuff.vpcf" end
	
function modifier_ghost_revenant_miasma:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW end

function modifier_ghost_revenant_miasma:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA end

function modifier_ghost_revenant_miasma:CheckState()
	if self:GetParent():HasModifier("modifier_slark_shadow_dance") then
		return nil
	end

	return {
		[MODIFIER_STATE_INVISIBLE] = false,
	}
end

function modifier_ghost_revenant_miasma:GetModifierProvidesFOWVision()
	local parent = self:GetParent()
	
	if not parent:IsHero() then return 0 end
	
	local invisModifiers = {
		"modifier_invisible",
		"modifier_mirana_moonlight_shadow",
		"modifier_item_imba_shadow_blade_invis",
		"modifier_item_shadow_amulet_fade",
		"modifier_imba_vendetta",
		"modifier_nyx_assassin_burrow",
		"modifier_item_imba_silver_edge_invis",
		"modifier_item_glimmer_cape_fade",
		"modifier_weaver_shukuchi",
		"modifier_treant_natures_guise_invis",
		"modifier_templar_assassin_meld",
		"modifier_imba_skeleton_walk_dummy",
		"modifier_invoker_ghost_walk_self"
	}
		
	for _,v in ipairs(invisModifiers) do
		if parent:HasModifier(v) then return 1 end
	end
	return 0
end

function modifier_ghost_revenant_miasma:GetModifierMoveSpeedBonus_Percentage()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	local slow = 0
	local invisModifiers = {
		"modifier_invisible",
		"modifier_mirana_moonlight_shadow",
		"modifier_item_imba_shadow_blade_invis",
		"modifier_item_shadow_amulet_fade",
		"modifier_imba_vendetta",
		"modifier_nyx_assassin_burrow",
		"modifier_item_imba_silver_edge_invis",
		"modifier_item_glimmer_cape_fade",
		"modifier_weaver_shukuchi",
		"modifier_treant_natures_guise_invis",
		"modifier_templar_assassin_meld",
		"modifier_imba_skeleton_walk_dummy",
		"modifier_invoker_ghost_walk_self"
	}
		
	for _,v in ipairs(invisModifiers) do
		if parent:HasModifier(v) then slow = ability:GetSpecialValueFor("invisible_slow") end
	end
	
	return slow
end

function modifier_ghost_revenant_miasma:OnIntervalThink()
	ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
end

-----------------------------------------------------------------------------------------------------------
-- Ghost Immolation
-----------------------------------------------------------------------------------------------------------
ghost_revenant_ghost_immolation = ghost_revenant_ghost_immolation or class({})
LinkLuaModifier("modifier_ghost_revenant_ambient", "hero/hero_ghost_revenant", LUA_MODIFIER_MOTION_NONE)

function ghost_revenant_ghost_immolation:GetAbilityTextureName()
   return "custom/ghost_revenant_ghost_immolation"
end

function ghost_revenant_ghost_immolation:GetIntrinsicModifierName()
	return "modifier_ghost_revenant_ambient"
end

function ghost_revenant_ghost_immolation:IsInnateAbility() return true end

-----------------------------------------------------------------------------------------------------------
-- Ghost Immolation modifier
-----------------------------------------------------------------------------------------------------------
modifier_ghost_revenant_ambient = modifier_ghost_revenant_ambient or class({})

function modifier_ghost_revenant_ambient:DeclareFunctions()	
	local decFuncs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
	return decFuncs	
end

function modifier_ghost_revenant_ambient:OnCreated()
	if IsServer() then
		self:GetParent():SetRenderColor(128, 255, 0)
		self:StartIntervalThink(1.0)
	end
end

function modifier_ghost_revenant_ambient:OnIntervalThink()
	if IsServer() then
		if self:GetCaster():PassivesDisabled() then return nil end
	end
end

function modifier_ghost_revenant_ambient:GetModifierAttackRangeBonus()
	return -300
end

function modifier_ghost_revenant_ambient:GetEffectName()
	return "particles/hero/ghost_revenant/ambient_effects.vpcf"
end

function modifier_ghost_revenant_ambient:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost_revenant.vpcf"
end

function modifier_ghost_revenant_ambient:StatusEffectPriority() return 15 end
function modifier_ghost_revenant_ambient:IsDebuff() return false end
function modifier_ghost_revenant_ambient:IsPurgable() return false end
function modifier_ghost_revenant_ambient:IsHidden() return false end
function modifier_ghost_revenant_ambient:RemoveOnDeath() return false end