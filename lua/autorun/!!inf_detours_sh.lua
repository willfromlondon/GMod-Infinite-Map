if game.GetMap() != "gm_infinite" then return end

AddCSLuaFile()

InfMap = InfMap or {chunk_size = 10000}

// metatable fuckery
local EntityMT = FindMetaTable("Entity")
local VehicleMT = FindMetaTable("Vehicle")
local PhysObjMT = FindMetaTable("PhysObj")
local PlayerMT = FindMetaTable("Player")
local NextBotMT = FindMetaTable("NextBot")
local CLuaLocomotionMT = FindMetaTable("CLuaLocomotion")
local CTakeDamageInfoMT = FindMetaTable("CTakeDamageInfo")

if CLIENT then
	InfMap.CreateClientside = InfMap.CreateClientside or ents.CreateClientside
	function ents.CreateClientside(str) 
		local ent = InfMap.CreateClientside(str)
		ent.Think = function(self)
			local parent = self:GetParent()
			if parent:IsValid() then
				local parent_offset = parent.CHUNK_OFFSET
				if parent_offset != self.CHUNK_OFFSET then
					self.CHUNK_OFFSET = parent_offset
					hook.Run("PropUpdateChunk", self, parent_offset)
					table.insert(InfMap.all_ents, self)
				end
			end
			//self:SetNextClientThink(CurTime() + 0.1)
			//return true
		end
		return ent
	end
	return
end

/*********** Entity Metatable *************/

EntityMT.InfMap_GetPos = EntityMT.InfMap_GetPos or EntityMT.GetPos
function EntityMT:GetPos()
	return InfMap.unlocalize_vector(self:InfMap_GetPos(), self.CHUNK_OFFSET)
end

EntityMT.InfMap_SetPos = EntityMT.InfMap_SetPos or EntityMT.SetPos
function EntityMT:SetPos(pos)
	local chunk_pos, chunk_offset = InfMap.localize_vector(pos)
	if chunk_offset != self.CHUNK_OFFSET then
		hook.Run("PropUpdateChunk", self, chunk_offset)
	end
	self:InfMap_SetPos(chunk_pos)
end

EntityMT.InfMap_LocalToWorld = EntityMT.InfMap_LocalToWorld or EntityMT.LocalToWorld
function EntityMT:LocalToWorld(pos)
	return InfMap.unlocalize_vector(self:InfMap_LocalToWorld(pos), self.CHUNK_OFFSET)
end

EntityMT.InfMap_WorldToLocal = EntityMT.InfMap_WorldToLocal or EntityMT.WorldToLocal
function EntityMT:WorldToLocal(pos)
	return self:InfMap_WorldToLocal(pos - InfMap.unlocalize_vector(Vector(), self.CHUNK_OFFSET))
end

EntityMT.InfMap_EyePos = EntityMT.InfMap_EyePos or EntityMT.EyePos
function EntityMT:EyePos()
	return InfMap.unlocalize_vector(self:InfMap_EyePos(), self.CHUNK_OFFSET)
end

EntityMT.InfMap_NearestPoint = EntityMT.InfMap_NearestPoint or EntityMT.NearestPoint
function EntityMT:NearestPoint(pos)
	// shouldnt really ever be outside the map
	local chunk_pos, chunk_offset = InfMap.localize_vector(pos)
	return InfMap.unlocalize_vector(self:InfMap_NearestPoint(chunk_pos), chunk_offset)
end

/************ Physics Object Metatable **************/

PhysObjMT.InfMap_GetPos = PhysObjMT.InfMap_GetPos or PhysObjMT.GetPos
function PhysObjMT:GetPos()
	return InfMap.unlocalize_vector(self:InfMap_GetPos(), self:GetEntity().CHUNK_OFFSET)
end

PhysObjMT.InfMap_SetPos = PhysObjMT.InfMap_SetPos or PhysObjMT.SetPos
function PhysObjMT:SetPos(pos, teleport)
	local chunk_pos, chunk_offset = InfMap.localize_vector(pos)
	local ent = self:GetEntity()
	if chunk_offset != ent.CHUNK_OFFSET then
		hook.Run("PropUpdateChunk", ent, chunk_offset)
	end
	self:InfMap_SetPos(chunk_pos, teleport)
end

/*************** Vehicle Metatable *****************/

VehicleMT.InfMap_GetPos = VehicleMT.InfMap_GetPos or VehicleMT.GetPos
function VehicleMT:GetPos()
	return InfMap.unlocalize_vector(self:InfMap_GetPos(), self.CHUNK_OFFSET)
end

VehicleMT.InfMap_SetPos = VehicleMT.InfMap_SetPos or VehicleMT.SetPos
function VehicleMT:SetPos(pos)
	local chunk_pos, chunk_offset = InfMap.localize_vector(pos)
	if chunk_offset != self.CHUNK_OFFSET then
		hook.Run("PropUpdateChunk", self, chunk_offset)
		if self:GetDriver():IsValid() then
			hook.Run("PropUpdateChunk", self:GetDriver(), chunk_offset)
		end
	end
	self:InfMap_SetPos(chunk_pos)
end

VehicleMT.InfMap_LocalToWorld = VehicleMT.InfMap_LocalToWorld or VehicleMT.LocalToWorld
function VehicleMT:LocalToWorld(pos)
	return InfMap.unlocalize_vector(self:InfMap_LocalToWorld(pos), self.CHUNK_OFFSET)
end

VehicleMT.InfMap_WorldToLocal = VehicleMT.InfMap_WorldToLocal or VehicleMT.WorldToLocal
function VehicleMT:WorldToLocal(pos)
	return self:InfMap_WorldToLocal(pos - InfMap.unlocalize_vector(Vector(), self.CHUNK_OFFSET))
end

/**************** CTakeDamageInfo Metatable *****************/

CTakeDamageInfoMT.InfMap_GetDamagePosition = CTakeDamageInfoMT.InfMap_GetDamagePosition or CTakeDamageInfoMT.GetDamagePosition
function CTakeDamageInfoMT:GetDamagePosition()
	local inflictor = self:GetInflictor()
	if !inflictor or !inflictor:IsValid() then 
		inflictor = game.GetWorld()
	end
	return InfMap.unlocalize_vector(self:InfMap_GetDamagePosition(), inflictor.CHUNK_OFFSET)
end

/**************** Player Metatable *****************/

PlayerMT.InfMap_GetShootPos = PlayerMT.InfMap_GetShootPos or PlayerMT.GetShootPos
function PlayerMT:GetShootPos()
	return InfMap.unlocalize_vector(self:InfMap_GetShootPos(), self.CHUNK_OFFSET)
end

/**************** NextBot Metatable *****************/

NextBotMT.InfMap_GetRangeSquaredTo = NextBotMT.InfMap_GetRangeSquaredTo or NextBotMT.GetRangeSquaredTo
function NextBotMT:GetRangeSquaredTo(to)
	if isentity(to) then to = to:GetPos() end
	return self:GetPos():DistToSqr(to)
end

NextBotMT.InfMap_GetRangeTo = NextBotMT.InfMap_GetRangeTo or NextBotMT.GetRangeTo
function NextBotMT:GetRangeTo(to)
	return math.sqrt(self:GetRangeSquaredTo(to))
end

/*************** CLuaLocomotion Metatable *****************/

CLuaLocomotionMT.InfMap_Approach = CLuaLocomotionMT.InfMap_Approach or CLuaLocomotionMT.Approach
function CLuaLocomotionMT:Approach(goal, goalweight)
	local nb = self:GetNextBot()
	local dir = (goal - nb:GetPos()):GetNormalized()
	local pos = InfMap.localize_vector(nb:GetPos() + dir)
	return CLuaLocomotionMT.InfMap_Approach(self, pos, goalweight)
end

CLuaLocomotionMT.InfMap_FaceTowards = CLuaLocomotionMT.InfMap_FaceTowards or CLuaLocomotionMT.FaceTowards
function CLuaLocomotionMT:FaceTowards(goal)
	local nb = self:GetNextBot()
	local dir = (goal - nb:GetPos()):GetNormalized()
	local pos = InfMap.localize_vector(nb:GetPos() + dir)
	return CLuaLocomotionMT.InfMap_FaceTowards(self, pos)
end

/**************** Other Functions ********************/

// infinite map.. nothing can be inside the world!
function util.IsInWorld(pos)
	return false 
end



// faster lookup
local istable = istable
local IsEntity = IsEntity
local function modify_trace_data(orig_data, trace_func, extra)
	local data = {}

	for k, v in pairs(orig_data) do
		data[k] = v
	end

	// #1 localize start and end position of trace
	local start_pos, start_offset = InfMap.localize_vector(data.start)

	data.start = start_pos
	data.endpos = data.endpos - InfMap.unlocalize_vector(Vector(), start_offset)

	// #2 create filter and only hit entities in your chunk
	local old_filter = data.filter
	if !old_filter then 
		data.filter = function(e) 
			return e.CHUNK_OFFSET == chunk_offset or (e:GetClass() == "infinite_chunk_terrain" and start_offset[3] == 0) 
		end
	elseif IsEntity(old_filter) then // rip efficiency
		data.filter = function(e)
			return (e.CHUNK_OFFSET == start_offset or (e:GetClass() == "infinite_chunk_terrain" and start_offset[3] == 0)) and e != old_filter
		end 
	elseif istable(old_filter) then	
		data.filter = function(e)
			for i = 1, #old_filter do 
				if e == old_filter[i] then 
					return false
				end 
			end
			return e.CHUNK_OFFSET == start_offset or (e:GetClass() == "infinite_chunk_terrain" and start_offset[3] == 0)
		end
	else // must be function
		data.filter = function(e)
			return old_filter(e) and (e.CHUNK_OFFSET == start_offset or (e:GetClass() == "infinite_chunk_terrain" and start_offset[3] == 0))
		end
	end

	// #3, unlocalize hit positions to designated chunks
	local hit_data = trace_func(data, extra)
	hit_data.HitPos = InfMap.unlocalize_vector(hit_data.HitPos, start_offset)
	hit_data.StartPos = InfMap.unlocalize_vector(hit_data.StartPos, start_offset)
	return hit_data
end

// traceline
InfMap.TraceLine = InfMap.TraceLine or util.TraceLine
function util.TraceLine(data)
	return modify_trace_data(data, InfMap.TraceLine)
end

// hull traceline
InfMap.TraceHull = InfMap.TraceHull or util.TraceHull
function util.TraceHull(data)
	return modify_trace_data(data, InfMap.TraceHull)
end

// entity traceline
InfMap.TraceEntity = InfMap.TraceEntity or util.TraceEntity
function util.TraceEntity(data, ent)
	return modify_trace_data(data, InfMap.TraceEntity, ent)
end

// no need to detour GetEyeTrace or util.GetPlayerTrace as it uses already detoured functions


// when entities are spawned, reset them
hook.Add("PlayerSpawn", "infinite_plyreset", function(ply, trans)
	timer.Simple(0, function()	// players weapons are invalid for first tick
		hook.Run("PropUpdateChunk", ply, Vector())	// still required because weapon entities are changed
		print("Resetting " .. ply:Nick() .." to chunk 0,0,0")
		ply:SetPos(Vector(math.Rand(-1, 1) * 200, math.Rand(-1, 1) * 200))
	end)
end)


// ^^
hook.Add("OnEntityCreated", "infinite_propreset", function(ent)
	timer.Simple(0.02, function()
		if ent:IsValid() and !ent:IsWeapon() then 
			if ent.CHUNK_OFFSET then return end
			if InfMap.filter_entities(ent) then return end
			
			hook.Run("PropUpdateChunk", ent, Vector())
		end
	end)
end)


/*
// lazy fix to put props spawned by players in their designated chunks
local function spawned_model(ply, model, ent)
	if ent and ent:IsValid() then
		local chunk_pos, chunk_offset = InfMap.localize_vector(ent:InfMap_GetPos())
		hook.Run("PropUpdateChunk", ent, ply.CHUNK_OFFSET + chunk_offset)
		if chunk_offset != Vector() then ent:Inf_SetPos(chunk_pos) end
	end
end
local function spawned(ply, ent)
	if ent and ent:IsValid() then
		local chunk_pos, chunk_offset = InfMap.localize_vector(ent:InfMap_GetPos())
		hook.Run("PropUpdateChunk", ent, ply.CHUNK_OFFSET + chunk_offset)
		if chunk_offset != Vector() then ent:Inf_SetPos(chunk_pos) end
	end
end

hook.Add("PlayerSpawnedProp", "infinite_entdetour", spawned_model)
hook.Add("PlayerSpawnedEffect", "infinite_entdetour", spawned_model)
hook.Add("PlayerSpawnedRagdoll", "infinite_entdetour", spawned_model)
hook.Add("PlayerSpawnedNPC", "infinite_entdetour", spawned)
hook.Add("PlayerSpawnedSENT", "infinite_entdetour", spawned)
hook.Add("PlayerSpawnedVehicle", "infinite_entdetour", spawned)
hook.Add("PlayerSpawnedSWEP", "infinite_entdetour", spawned)
hook.Add("WeaponEquip", "infinite_entdetour", function(weapon, ply)
	hook.Run("PropUpdateChunk", weapon, ply.CHUNK_OFFSET or Vector())
end)*/


// disable picking up weapons/items in other chunks
local function can_pickup(ply, ent)
	if !ply.CHUNK_OFFSET or !ent.CHUNK_OFFSET then return true end	// when spawning, player weapons will be nil for 1 tick
	return ply.CHUNK_OFFSET == ent.CHUNK_OFFSET
end

hook.Add("PlayerCanPickupWeapon", "infinite_entdetour", can_pickup)
hook.Add("PlayerCanPickuItem", "infinite_entdetour", can_pickup)
hook.Add("GravGunPickupAllowed", "infinite_entdetour", can_pickup)