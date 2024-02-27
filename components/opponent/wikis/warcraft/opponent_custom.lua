---
-- @Liquipedia
-- wiki=warcraft
-- page=Module:Opponent/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Faction = require('Module:Faction')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

local Opponent = Lua.import('Module:Opponent')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')

local CustomOpponent = Table.deepCopy(Opponent)

CustomOpponent.types.Player = TypeUtil.extendStruct(Opponent.types.Player, {
	race = 'string?',
})

CustomOpponent.types.PartyOpponent = TypeUtil.struct{
	players = TypeUtil.array(CustomOpponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes)),
}

CustomOpponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	CustomOpponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

---@class WarcraftStandardPlayer:standardPlayer
---@field race string?

---@class WarcraftStandardOpponent:standardOpponent
---@field players WarcraftStandardPlayer[]
---@field isArchon boolean
---@field isSpecialArchon boolean?
---@field extradata table

---@param args table
---@return WarcraftStandardOpponent?
function CustomOpponent.readOpponentArgs(args)
	local opponent = Opponent.readOpponentArgs(args) --[[@as WarcraftStandardOpponent?]]
	local partySize = Opponent.partySize((opponent or {}).type)

	if not opponent then
		return nil
	end

	if partySize == 1 then
		opponent.players[1].race = Faction.read(args.race)
	elseif partySize then
		for playerIx, player in ipairs(opponent.players) do
			player.race = Faction.read(args['p' .. playerIx .. 'race'])
		end
	end

	return opponent
end

---@param record table
---@return WarcraftStandardOpponent?
function CustomOpponent.fromMatch2Record(record)
	local opponent = Opponent.fromMatch2Record(record) --[[@as WarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.typeIsParty(opponent.type) then
		for playerIx, player in ipairs(opponent.players) do
			local playerRecord = record.match2players[playerIx]
			player.race = Faction.read(playerRecord.extradata.faction) or Faction.defaultFaction
		end
	end

	return opponent
end

---@param opponent WarcraftStandardOpponent
---@return table?
function CustomOpponent.toLpdbStruct(opponent)
	local storageStruct = Opponent.toLpdbStruct(opponent)

	if Opponent.typeIsParty(opponent.type) then
		for playerIndex, player in pairs(opponent.players) do
			storageStruct.opponentplayers['p' .. playerIndex .. 'faction'] = player.race
		end
	end

	return storageStruct
end

---@param storageStruct table
---@return WarcraftStandardOpponent?
function CustomOpponent.fromLpdbStruct(storageStruct)
	local opponent = Opponent.fromLpdbStruct(storageStruct) --[[@as WarcraftStandardOpponent?]]

	if not opponent then
		return nil
	end

	if Opponent.partySize(storageStruct.opponenttype) then
		for playerIndex, player in pairs(opponent.players) do
			player.race = storageStruct.opponentplayers['p' .. playerIndex .. 'faction']
		end
	end

	return opponent
end

---@param opponent WarcraftStandardOpponent
---@param date string|number|nil
---@param options {syncPlayer: boolean?}
---@return WarcraftStandardOpponent
function CustomOpponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		return Opponent.resolve(opponent --[[@as standardOpponent]], date, options) --[[@as WarcraftStandardOpponent]]
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local hasRace = String.isNotEmpty(player.race)
				local savePageVar = not Opponent.playerIsTbd(player)
				PlayerExt.syncPlayer(player, {savePageVar = savePageVar, date = date})
				player.team = PlayerExt.syncTeam(
					player.pageName:gsub(' ', '_'),
					player.team,
					{date = date, savePageVar = savePageVar}
				)
				player.race = (hasRace or player.race ~= Faction.defaultFaction) and player.race or nil
			else
				PlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end
	end
	return opponent
end

return CustomOpponent
