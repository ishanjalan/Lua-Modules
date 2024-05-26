-- @Liquipedia
-- wiki=dota2
-- page=Module:Infobox/Item/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DotaIcon = require('Module:DotaIcon')
local ItemIcon = require('Module:ItemIcon')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Namespace = require('Module:Namespace')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Injector = Lua.import('Module:Infobox/Widget/Injector')
local Item = Lua.import('Module:Infobox/Item')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center
local Breakdown = Widgets.Breakdown

---@class Dota2ItemInfobox: ItemInfobox
local CustomItem = Class.new(Item)
local CustomInjector = Class.new(Injector)

local CATEGORY_DISPLAY = {
	['basic'] = 'Basic [[Category:Basic Items]]',
	['consumable'] = 'Consumable [[Category:Consumable Items]]',
	['attribute'] = 'Attribute [[Category:Attribute Items]]',
	['arcane'] = 'Arcane [[Category:Arcane Items]]',
	['common'] = 'Common [[Category:Common Items]]',
	['support'] = 'Support [[Category:Support Items]]',
	['caster'] = 'Caster [[Category:Caster Items]]',
	['weapons'] = 'Weapons [[Category:Weapons]]',
	['armor'] = 'Armor [[Category:Armor]]',
	['artifact'] = 'Artifact [[Category:Artifact Items]]',
	['neutral'] = 'Neutral [[Category:Neutral Items]]',
}

local DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION = '_positiveConcatedArgsForBase'

---@param frame Frame
---@return Html
function CustomItem.run(frame)
	local item = CustomItem(frame)
	item:setWidgetInjector(CustomInjector(item))

	return item:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'header' then
		if String.isNotEmpty(args.itemcost) then
			table.insert(widgets, Breakdown{
				content = caller:_getCostDisplay(),
				classes = {
					'infobox-header',
					'wiki-backgroundcolor-light',
					'infobox-header-2',
					'infobox-gold'
				}
			})
		end
		if String.isNotEmpty(args.itemname) then
			local iconImage = ItemIcon.display({}, args.itemname)
			if String.isNotEmpty(args.itemtext) then
				iconImage = iconImage .. '<br><i>' .. args.itemtext .. '</i>'
			end
			table.insert(widgets, Center{content = {iconImage}})
		end
		return widgets
	elseif id == 'attributes' then
		local attributeCells = {
			{name = 'Bonus Strength', parameter = 'bonus_strength'},
			{name = 'Bonus Agility', parameter = 'bonus_agility'},
			{name = 'Bonus Intelligence', parameter = 'bonus_intelligence'},
			{name = 'Bonus Health', parameter = 'bonus_health'},
			{name = 'Bonus Health Regen', parameter = 'bonus_health_regen'},
			{name = 'Bonus Mana', parameter = 'bonus_mana'},
			{name = 'Bonus Mana Regen', parameter = 'bonus_mana_regen'},
			{name = 'Bonus Armor', parameter = 'bonus_armor'},
			{name = 'Bonus Evasion', parameter = 'bonus_evasion', funct = '_positivePercentDisplay'},
			{name = 'Bonus Magic Resistance', parameter = 'bonus_magic_resistance'},
			{name = 'Bonus Status Resistance', parameter = 'bonus_status_resistance', funct = '_positivePercentDisplay'},
			{name = 'Bonus Movement Speed (Flat)', parameter = 'bonus_movement_speed_flat'},
			{name = 'Bonus Movement Speed (Percent)', parameter = 'bonus_movement_speed_percent', funct = '_positivePercentDisplay'},
			{name = 'Bonus Cooldown Reduction', parameter = 'bonus_cooldown_reduction', funct = '_positivePercentDisplay'},
			{name = 'Bonus Attack Damage', parameter = 'bonus_attack_damage'},
			{name = 'Bonus Attack Speed', parameter = 'bonus_attack_speed'},
			{name = 'Bonus Lifesteal', parameter = 'bonus_lifesteal', funct = '_positivePercentDisplay'},
		}
		widgets = caller:_getAttributeCells(attributeCells)
		if not Table.isEmpty(widgets) then
			table.insert(widgets, 1, Title{name = 'Attributes'})
		end
		return widgets
	elseif id == 'ability' then
		if String.isEmpty(args.active) and String.isEmpty(args.passive) and String.isEmpty(args.passive2) then
			return {}
		end
		Array.appendWith(widgets,
			Cell{name = 'Active', content = {args.active}},
			Cell{name = 'Passive', content = {args.passive, args.passive2}}
		)
	elseif id == 'availability' then
		if String.isEmpty(args.category) and String.isEmpty(args.drop) then return {} end
		return {
			Title{name = 'Item Tier'},
			Cell{name = 'Category', content = {caller:_categoryDisplay()}},
			Cell{name = 'Dropped From', content = {args.drop}},
		}
	elseif id == 'maps' then
		if String.isEmpty(args.neutral) then
			return {}
		end
		Array.appendWith(widgets,
			Cell{name = 'Neutral', content = {args.neutral}}
		)
	elseif id == 'recipe' then
		if String.isEmpty(args.recipe) then return {} end
		table.insert(widgets, Center{content = {args.recipe}})
	elseif id == 'info' then return {}
	end

	return widgets
end

---@param args table
---@return string[]
function CustomItem:getWikiCategories(args)
	if not Namespace.isMain() then return {} end

	local categories = {}
	if String.isNotEmpty(args.bonus_strength) or String.isNotEmpty(args.bonus_agility) or String.isNotEmpty(args.bonus_intelligence) then
		table.insert(categories, 'Attribute Items')
	end

	if String.isNotEmpty(args.bonus_movement_speed_flat) or String.isNotEmpty(args.bonus_movement_speed_percent) then
		table.insert(categories, 'Movement Speed Items')
	end

	local possibleCategories = {
		['Strength Items'] = 'bonus_strength',
		['Agility Items'] = 'bonus_agility',
		['Intelligence Items'] = 'bonus_intelligence',
		['Health Items'] = 'bonus_health',
		['Mana Pool Items'] = 'bonus_mana',
		['Health Regeneration Items'] = 'bonus_health_regen',
		['Mana Regeneration Items'] = 'bonus_mana_regen',
		['Armor Bonus Items'] = 'bonus_armor',
		['Evasion Items'] = 'bonus_evasion',
		['Magic Resistance Items'] = 'bonus_magic_resistance',
		['Damage Items'] = 'bonus_attack_damage',
		['Items with Active Abilities'] = 'active',
		['Items with Passive Abilities'] = 'passive',
	}
	for category, requiredArg in pairs(possibleCategories) do
		if String.isNotEmpty(args[requiredArg]) then
			table.insert(categories, category)
		end
	end

	if not self:_categoryDisplay() then
		table.insert(categories, 'Unknown Type')
	end

	return categories
end

---@param args table
---@return string?
function CustomItem.nameDisplay(args)
	return args.itemname
end

---@return string[]
function CustomItem:_getCostDisplay()
	local costs = self:getAllArgsForBase(self.args, 'itemcost')

	local innerDiv = CustomItem._costInnerDiv(table.concat(costs, '&nbsp;/&nbsp;'))
	local outerDiv = mw.html.create('div')
		:wikitext(DotaIcon.display({}, 'gold', '21') .. ' ' .. tostring(innerDiv))
	local display = tostring(outerDiv)

	if String.isNotEmpty(self.args.recipecost) then
		innerDiv = CustomItem._costInnerDiv('(' .. self.args.recipecost .. ')')
		outerDiv = mw.html.create('div')
			:css('padding-top', '3px')
			:wikitext(DotaIcon.display({}, 'recipe', '21') .. ' ' .. tostring(innerDiv))
		display = display .. tostring(outerDiv)
	end

	return {display}
end

---@param text string|number|nil
---@return Html
function CustomItem._costInnerDiv(text)
	return mw.html.create('div')
		:css('display', 'inline-block')
		:css('padding', '0px 3px')
		:css('border-radius', '4px')
		:addClass('placement-darkgrey')
		:wikitext(text)
end

---@param caller Dota2ItemInfobox
---@param base string?
---@return string?
function CustomItem._positiveConcatedArgsForBase(caller, base)
	if String.isEmpty(caller.args[base]) then return end
	---@cast base -nil
	local foundArgs = caller:getAllArgsForBase(caller.args, base)
	return '+ ' .. table.concat(foundArgs, '&nbsp;/&nbsp;')
end

---@param caller Dota2ItemInfobox
---@param base string?
---@return string?
function CustomItem._positivePercentDisplay(caller, base)
	if String.isEmpty(caller.args[base]) then
		return
	elseif not Logic.isNumeric(caller.args[base]) then
		error('"' .. base .. '" has to be numerical')
	end
	---@cast base -nil
	return '+ ' .. (tonumber(caller.args[base]) * 100) .. '%'
end

---@param caller Dota2ItemInfobox
---@param base string?
---@return string?
function CustomItem._movementSpeedDisplay(caller, base)
	local display = Array.append({},
		String.nilIfEmpty(caller.args.bonus_movement_speed_flat),
		Logic.isNumeric(caller.args.bonus_movement_speed_percent) and ((tonumber(caller.args.bonus_movement_speed_percent) + 100) .. '%') or nil
	)
	if Table.isEmpty(display) then return end
	return '+ ' .. table.concat(display)
end

---@return string?
function CustomItem:_categoryDisplay()
	return CATEGORY_DISPLAY[string.lower(self.args.category or '')]
end

---@param attributeCells {name: string, parameter: string?, funct: string?}[]
---@return table
function CustomItem:_getAttributeCells(attributeCells)
	return Array.map(attributeCells, function(attribute)
		local funct = attribute.funct or DEFAULT_ATTRIBUTE_DISPLAY_FUNCTION
		local content = CustomItem[funct](self, attribute.parameter)
		if String.isEmpty(content) then return nil end
		return Cell{name = attribute.name, content = {content}}
	end)
end

return CustomItem
