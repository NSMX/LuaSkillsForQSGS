--[[
	代码速查手册（L区）
	技能索引：
		狼顾、乐学、雷击、离魂、离间、离迁、礼让、疠火、连环、连理、连破、连营、烈斧、烈弓、烈刃、流离、龙胆、龙魂、龙魂、龙怒、龙吟、笼络、乱击、乱武、裸衣、裸衣、洛神、落英、
]]--
--[[
	技能名：狼顾
	相关武将：贴纸·司马昭
	描述：每当你受到1点伤害后，你可以进行一次判定，然后你可以打出一张手牌代替此判定牌：若如此做，你观看伤害来源的所有手牌，并弃置其中任意数量的与判定牌花色相同的牌。 
	引用：LuaXLanggu
	状态：验证通过
]]--
LuaXLanggu = sgs.CreateTriggerSkill{
	name = "LuaXLanggu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged, sgs.AskForRetrial},
	on_trigger = function(self, event, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.from or damage.from:isKongcheng() then
				return
			end
			local target = damage.from
			local num = damage.damage
			local n = 0
			while n < num do
				if player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local judge = sgs.JudgeStruct()
					judge.reason = self:objectName()
					judge.pattern = sgs.QRegExp("(.*):(.*):(.*)")
					judge.who = player
					room:judge(judge)
					local ids = target:handCards()
					room:fillAG(ids, player)
					local mark = judge.card:getSuitString()
					room:setPlayerFlag(player, mark)
					while not target:isKongcheng() do
						local card_id = room:askForAG(player, ids, true, "LuaXLanggu")
						if card_id == -1 then
							player:invoke("clearAG")
							break
						end
						local card = sgs.Sanguosha:getCard(card_id)
						if judge.card:getSuit() == card:getSuit() then
							room:throwCard(card_id, target)
						end
					end
					room:setPlayerFlag(player, "-" .. mark)
				else
					break
				end
				n = n + 1
			end
			return
		elseif event == sgs.AskForRetrial then
			local room = player:getRoom()
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				if judge.who:objectName() == player:objectName() then
					local card = room:askForCard(player, ".", "@LuaXLanggu", data, sgs.AskForRetrial)
					if card then
						room:retrial(card, player, judge, self:objectName(), false)
					end
				end
			end
			return false
		end
	end,
}
--[[
	技能名：乐学
	相关武将：倚天·姜伯约
	描述：出牌阶段，可令一名有手牌的其他角色展示一张手牌，若为基本牌或非延时锦囊，则你可将与该牌同花色的牌当作该牌使用或打出直到回合结束；若为其他牌，则立刻被你获得。每阶段限一次 
	引用：LuaXLexue
	状态：验证通过
]]--
LuaXLexueCard = sgs.CreateSkillCard{
	name = "LuaXLexueCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if to_select:objectName() ~= sgs.Self:objectName() then
				return not to_select:isKongcheng()
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		local target = effect.to
		local room = target:getRoom()
		local card = room:askForCardShow(target, source, "LuaXLexue")
		local card_id = card:getEffectiveId()
		room:showCard(target, card_id)
		local type_id = card:getTypeId()
		if type_id == sgs.Card_Basic or card:isNDTrick() then
			room:setPlayerMark(source, "lexue", card_id)
			room:setPlayerFlag(source, "lexue")
		else
			source:obtainCard(card)
			room:setPlayerFlag(source, "-lexue")
		end
	end
}
LuaXLexue = sgs.CreateViewAsSkill{
	name = "LuaXLexue", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasUsed("#LuaXLexueCard") then
			if #selected == 0 then
				if sgs.Self:hasFlag("lexue") then
					local card_id = sgs.Self:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					return to_select:getSuit() == card:getSuit()
				end
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if sgs.Self:hasUsed("#LuaXLexueCard") then
			if sgs.Self:hasFlag("lexue") then
				if #cards == 1 then
					local card_id = sgs.Self:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					local first = cards[1]
					local name = card:objectName()
					local suit = first:getSuit()
					local point = first:getNumber()
					local new_card = sgs.Sanguosha:cloneCard(name, suit, point)
					new_card:addSubcard(first)
					new_card:setSkillName(self:objectName())
					return new_card
				end
			end
		else
			return LuaXLexueCard:clone()
		end
	end, 
	enabled_at_play = function(self, player)
		if player:hasUsed("#LuaXLexueCard") then
			if player:hasFlag("lexue") then
				local card_id = player:getMark("lexue")
				local card = sgs.Sanguosha:getCard(card_id)
				return card:isAvailable(player)
			end
		end
		return true
	end, 
	enabled_at_response = function(self, player, pattern)
		if player:getPhase() ~= sgs.Player_NotActive then
			if player:hasFlag("lexue") then
				if player:hasUsed("#LuaXLexueCard") then
					local card_id = player:getMark("lexue")
					local card = sgs.Sanguosha:getCard(card_id)
					return string.find(pattern, card:objectName())
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		if player:hasFlag("lexue") then
			local card_id = player:getMark("lexue")
			local card = sgs.Sanguosha:getCard(card_id)
			if card:objectName() == "nullification" then
				local cards = player:getHandcards()
				for _,c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:getSuit() == card:getSuit() then
						return true
					end
				end
				cards = player:getEquips()
				for _,c in sgs.qlist(cards) do
					if c:objectName() == "nullification" or c:getSuit() == card:getSuit() then
						return true
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：雷击
	相关武将：风·张角
	描述：当你使用或打出一张【闪】（若为使用则在选择目标后），你可以令一名角色进行一次判定，若判定结果为黑桃，你对该角色造成2点雷电伤害。
	引用：LuaLeiji
	状态：验证通过
]]--
LuaLeijiCard = sgs.CreateSkillCard{
	name = "LuaLeijiCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		return #targets == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(spade):(.*)")
		judge.good = false
		judge.reason = self:objectName()
		judge.who = target
		judge.play_animation = true
		judge.negative = true
		room:judge(judge)
		if judge.isBad() then
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.damage = 2
			damage.from = source
			damage.to = target
			damage.nature = sgs.DamageStruct_Thunder
			room:damage(damage)
		else
			room:setEmotion(source, "bad")
		end
	end
}
LuaLeijiVS = sgs.CreateViewAsSkill{
	name = "LuaLeiji", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaLeijiCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaLeiji"
	end
}
LuaLeiji = sgs.CreateTriggerSkill{
	name = "LuaLeiji", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardResponsed}, 
	view_as_skill = LuaLeijiVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local card = data:toResponsed().m_card
		if card:isKindOf("Jink") then
			room:askForUseCard(player, "@@LuaLeiji", "@LuaLeiji")
		end
		return false
	end, 
	priority = 3
}
--[[
	技能名：离魂
	相关武将：☆SP·貂蝉
	描述：出牌阶段，你可以弃置一张牌并将你的武将牌翻面，若如此做，指定一名男性角色，获得其所有手牌。出牌阶段结束时，你须为该角色每一点体力分配给其一张牌。每回合限一次。
	引用：LuaLihun
	状态：验证通过
]]--
LuaLihunDummyCard = sgs.CreateSkillCard{
	name = "LuaLihunDummyCard",
}
LuaLihunCard = sgs.CreateSkillCard{
	name = "LuaLihunCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select)
		if to_select:isMale() then
			return #targets == 0
		end
		return false
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local room = source:getRoom()
		source:turnOver()
		local card = LuaLihunDummyCard:clone()
		local dest = effect.to
		local list = dest:getHandcards()
		for _,cd in sgs.qlist(list) do
			card:addSubcard(cd)
		end
		if not dest:isKongcheng() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(),			dest:objectName(), self:objectName(), "")
			room:moveCardTo(card, dest, source, sgs.Player_PlaceHand, reason, false)
		end
		dest:setFlags("LihunTarget")
	end
}
LuaLihunSelect = sgs.CreateViewAsSkill{
	name = "LuaLihunSelect",
	n = 1, 
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaLihunCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaLihunCard")
	end
}
LuaLihun = sgs.CreateTriggerSkill{
	name = "#LuaLihun", 
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd},
	view_as_skill = LuaLihunSelect, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local target = nil
			local list = room:getOtherPlayers(player)
			for _,other in sgs.qlist(list) do
				if other:hasFlag("LihunTarget") then
					other:setFlags("-LihunTarget")
					target = other
					break
				end
			end
			if target then
				local hp = target:getHp()
				if hp > 0 then
					if not player:isNude() then
						local to_goback
						local card_count = player:getCardCount(true)
						if card_count <= hp then
							if player:isKongcheng() then
								to_goback = sgs.DummyCard()
							else
								to_goback = player:wholeHandcards()
							end
							for i = 0, 3, 1 do
								local equip = player:getEquip(i)
								if equip then
									to_goback:addSubcard(equip:getEffectiveId())
								end
							end
						else
							to_goback = room:askForExchange(player, self:objectName(), hp, true, "LihunGoBack")
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), "")
						reason.m_playerId = target:objectName();
						room:moveCardTo(to_goback, player, target, sgs.Player_PlaceHand, reason)
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasUsed("#LuaLihunCard")
		end
	end
}
--[[
	技能名：离间
	相关武将：标准·貂蝉、SP·貂蝉
	描述：出牌阶段，你可以弃置一张牌并选择两名男性角色，视为其中一名男性角色对另一名男性角色使用一张【决斗】。此【决斗】不能被【无懈可击】响应。每阶段限一次。
	引用：LuaLijian
	状态：验证通过 
]]--
LuaLijianCard = sgs.CreateSkillCard{
	name = "LuaLijianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets ~= 2 then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			if to_select:isMale() then
				return not sgs.Self:isProhibited(to_select, duel)
			end
		elseif #targets == 2 then
			local tag = sgs.QVariant(targets[1]:objectName())
			sgs.Self:setTag("LualijianTarget", tag)
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local LijianTarget = sgs.Self:getTag("LualijianTarget"):toString()
		if LijianTarget ~= "" then
			local from = nil
			local to = nil
			if LijianTarget == targets[1]:objectName() then
				from = targets[2]
				to = targets[1]
			else
				from = targets[1]
				to = targets[2]
			end
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:toTrick():setCancelable(false)
			duel:setSkillName("LuaLijian")
			local use = sgs.CardUseStruct()
            		use.card = duel
            		use.from = from
           	 	use.to:append(to)
            		room:useCard(use)
			source:removeTag("LualijianTarget")
		end
	end	
}
LuaLijian = sgs.CreateViewAsSkill{
	name = "LuaLijian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = LuaLijianCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function()
		return not sgs.Self:hasUsed("#LuaLijianCard")
	end
}
--[[
	技能名：离迁（锁定技）
	相关武将：倚天·夏侯涓
	描述：当你处于连理状态时，势力与连理对象的势力相同；当你处于未连理状态时，势力为魏 
	状态：同连理状态
]]--
--[[
	技能名：礼让
	相关武将：国战·孔融
	描述：当你的牌因弃置而置入弃牌堆时，你可以将其中任意数量的牌以任意分配方式交给任意数量的其他角色。
	引用：LuaXLirang
	状态：0224验证通过
]]--
require ("bit")
LuaXLirang = sgs.CreateTriggerSkill{
	name = "LuaXLirang",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardsMoving},  
	on_trigger = function(self, event, player, data) 
		local move = data:toMoveOneTime()
		local source = move.from
		if not player:hasFlag("lirang_InTempMoving") then --防止不完全给出时二次触发
			if source and source:objectName() == player:objectName() then
				if move.to_place == sgs.Player_DiscardPile then
					local reason = move.reason
					local basic = bit:_and(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) 
					if basic == sgs.CardMoveReason_S_REASON_DISCARD then
						local room = player:getRoom()
						local i = 0
						local lirang_card = sgs.IntList()
						for _,card_id in sgs.qlist(move.card_ids) do
							if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
								local place = move.from_places:at(i)
								if place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip then
									lirang_card:append(card_id)
								end
							end
							i = i + 1
						end
						if not lirang_card:isEmpty() then
							if player:askForSkillInvoke(self:objectName(), data) then
								room:setPlayerFlag(player, "lirang_InTempMoving")
								local move2 = sgs.CardsMoveStruct()
								move2.card_ids = lirang_card
								move2.to_place = sgs.Player_PlaceHand
								move2.to = player
								room:moveCardsAtomic(move2, true)
								while room:askForYiji(player, lirang_card, false, true) do
								end
								local move3 = sgs.CardsMoveStruct()
								move3.card_ids = lirang_card
								move3.to_place = sgs.Player_DiscardPile
								move3.reason = reason
								room:moveCardsAtomic(move3, true)
								room:setPlayerFlag(player, "-lirang_InTempMoving")
							end
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：疠火
	相关武将：二将成名·程普
	描述：你可以将一张普通【杀】当火【杀】使用，若以此法使用的【杀】造成了伤害，在此【杀】结算后你失去1点体力；你使用火【杀】时，可以额外选择一个目标。
	引用：LuaLihuo、LuaLihuoTarget
	状态：验证通过
]]--
LuaLihuoVS = sgs.CreateViewAsSkill{
	name = "LuaLihuo", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "slash"
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local number = card:getNumber()
			local id = card:getId()
			local acard = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			acard:addSubcard(id)
			acard:setSkillName(self:objectName())
			return acard
		end
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}
LuaLihuo = sgs.CreateTriggerSkill{
	name = "LuaLihuo",
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageDone, sgs.CardFinished}, 
	view_as_skill = LuaLihuoVS, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageDone then
			local damage = data:toDamage()
			local card = damage.card
			if card then
				if card:isKindOf("Slash") then
					if card:getSkillName() == self:objectName() then
						room:setTag("Invokelihuo", sgs.QVariant(true))
					end
				end
			end
		elseif event == sgs.CardFinished then
			if player:hasSkill(self:objectName()) then
				local tag = room:getTag("Invokelihuo")
				if tag:toBool() then
					room:setTag("Invokelihuo", sgs.QVariant(false))
					room:loseHp(player, 1)
				end
			end
		end
		return false;
	end, 
	can_trigger = function(self, target)
		return target 
	end
}
LuaLihuoTarget = sgs.CreateTargetModSkill{
	name = "#LuaLihuoTarget",
	pattern = "FireSlash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
		return 0
	end,
}
--[[
	技能名：连环
	相关武将：火·庞统
	描述：你可以将一张梅花手牌当【铁索连环】使用或重铸。
	引用：LuaLianhuan
	状态：验证通过
]]--
LuaLianhuan = sgs.CreateViewAsSkill{
	name = "LuaLianhuan", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if to_select:isEquipped() then
			return false
		else
			return to_select:getSuit() == sgs.Card_Club
		end
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local id = card:getId()
			local chain = sgs.Sanguosha:cloneCard("iron_chain", suit, point)
			chain:addSubcard(id)
			chain:setSkillName(self:objectName())
			return chain
		end
	end
}
--[[
	技能名：连理
	相关武将：倚天·夏侯涓
	描述：回合开始阶段开始时，你可以选择一名男性角色，你和其进入连理状态直到你的下回合开始：该角色可以帮你出闪，你可以帮其出杀 
	状态：验证失败
]]--
--[[
	技能名：连破
	相关武将：神·司马懿
	描述：若你在一回合内杀死了至少一名角色，此回合结束后，你可以进行一个额外的回合。
	引用：LuaLianpoCount、LuaLianpo、LuaLianpoDo
	状态：验证通过
]]--
LuaLianpoCount = sgs.CreateTriggerSkill{
	name = "#LuaLianpoCount", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death}, 
	on_trigger = function(self, event, player, data)
		local damage = data:toDamageStar()
		if damage then
			local killer = damage.from
			if killer then
				if killer:hasSkill("LuaLianpo") then
					local room = killer:getRoom()
					if room:getCurrent():isAlive() then
						killer:addMark("lianpo")
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end
}
LuaLianpo = sgs.CreateTriggerSkill{
	name = "LuaLianpo", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName(self:objectName())
		if source then
			if source:getMark("lianpo") > 0 then
				source:setMark("lianpo", 0)
				if source:askForSkillInvoke("lianpo") then
					local p = sgs.QVariant()
					p:setValue(source)
					room:setTag("LianpoInvoke", p)
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end, 
	priority = -1
}
LuaLianpoDo = sgs.CreateTriggerSkill{
	name = "#LuaLianpoDo", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local tag = room:getTag("LianpoInvoke")
		if tag then
			local target = tag:toPlayer()
			room:removeTag("LianpoInvoke")
			if target then
				if target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getPhase() == sgs.Player_NotActive
		end
		return false
	end, 
	priority = -3
}
--[[
	技能名：连营
	相关武将：标准·陆逊、倚天·陆抗
	描述：当你失去最后的手牌时，你可以摸一张牌。
	引用：LuaLianYing
	状态：验证通过
]]--
LuaLianYing = sgs.CreateTriggerSkill{
	name = "LuaLianYing",
	events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:hasSkill(self:objectName()) then
			if move.from_places:contains(sgs.Player_PlaceHand) then
				if event == sgs.BeforeCardsMove then 
					local handcards = player:handCards()
					for _,id in sgs.qlist(handcards) do 
						if not move.card_ids:contains(id) then 
							return 
						end
					end
					player:addMark(self:objectName())
				else
					if player:getMark(self:objectName()) > 0 then
						player:removeMark(self:objectName())			 
						if room:askForSkillInvoke(player, self:objectName(), data) then
							player:drawCards(1)
						end
					end
				end
			end
		end
	end
} 
--[[
	技能名：烈斧
	相关武将：3D织梦·潘凤
	描述：当你使用的【杀】被目标角色的【闪】抵消时，你可以令此【杀】依然造成伤害，若如此做，你选择一项：弃置等同于目标角色已损失的体力值数量的牌，不足则全弃；令目标角色摸等同于其当前体力值数量的牌，最多为5张。 
]]--
--[[
	技能名：烈弓
	相关武将：风·黄忠
	描述：当你在出牌阶段内使用【杀】指定一名角色为目标后，以下两种情况，你可以令其不可以使用【闪】对此【杀】进行响应：1.目标角色的手牌数大于或等于你的体力值。2.目标角色的手牌数小于或等于你的攻击范围。
	引用：LuaLiegong
	状态：验证通过
]]--
LuaLiegong = sgs.CreateTriggerSkill{
	name = "LuaLiegong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirmed, sgs.SlashProceed}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local card = use.card
			local source = use.from
			local room = player:getRoom()
			if card:isKindOf("Slash") then
				if source:objectName() == player:objectName() then
					local phase = player:getPhase()
					if phase == sgs.Player_Play then
						local hp = player:getHp()
						local range = player:getAttackRange()
						local targets = use.to
						for _,target in sgs.qlist(targets) do
							local count = target:getHandcardNum()
							if count >= hp or count <= range then
								local ai_data = sgs.QVariant()
								ai_data:setValue(target)
								if player:askForSkillInvoke(self:objectName(), ai_data) then
									room:setPlayerFlag(target, "LiegongTarget")
								end
							end
						end
					end
				end
			end
		elseif event == sgs.SlashProceed then
			local effect = data:toSlashEffect()
			local dest = effect.to
			if dest:hasFlag("LiegongTarget") then
				room:setPlayerFlag(dest, "-LiegongTarget")
				room:slashResult(effect, nil)
				return true
			end
		end
		return false
	end
}
--[[
	技能名：烈刃
	相关武将：火·祝融
	描述：每当你使用【杀】对目标角色造成一次伤害后，你可以与其拼点，若你赢，你获得该角色的一张牌。
	引用：LuaLieren
	状态：验证通过
]]--
LuaLieren = sgs.CreateTriggerSkill{
	name = "LuaLieren", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.Damage},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local target = damage.to
		local slash = damage.card
		if slash then
			if slash:isKindOf("Slash") then
				if not player:isKongcheng() then
					if not target:isKongcheng() then
						if target:objectName() ~= player:objectName() then
							if not damage.chain then
								if not damage.transfer then
									local room = player:getRoom()
									if room:askForSkillInvoke(player, self:objectName(), data) then
										local success = player:pindian(target, self:objectName(), nil)
										if success then
											if not target:isNude() then
												local id = room:askForCardChosen(player, target, "he", self:objectName())
												room:obtainCard(player, id, false)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：流离
	相关武将：标准·大乔
	描述：当你成为【杀】的目标时，你可以弃置一张牌，将此【杀】转移给你攻击范围内的一名其他角色（此【杀】的使用者除外）。
	引用：LuaLiuli
	状态：验证通过
]]--
sgs.LiuliPattern = {0}
LuaLiuliCard = sgs.CreateSkillCard{
	name = "LuaLiuliCard", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:hasFlag("slash_source") then
				local slash = sgs.Sanguosha:getCard(sgs.LiuliPattern[1])
				if sgs.Self:canSlash(to_select, slash) then
					local cards = self:getSubcards()
					local card_id = cards:at(0)
					local weapon = sgs.Self:getWeapon()
					local horse = sgs.Self:getOffensiveHorse()
					if weapon and weapon:getId() == card_id then
						return sgs.Self:distanceTo(to_select) <= 1
					elseif horse and horse:getId() == card_id then
						local distance = 1
						if weapon then
							local wp = weapon:getRealCard()
							distance = wp:getRange()
						end
						return sgs.Self:distanceTo(to_select, 1) <= distance
					else
						return true
					end
				end
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room = target:getRoom()
		room:setPlayerFlag(target, "liuli_target")
	end
}
LuaLiuliVS = sgs.CreateViewAsSkill{
	name = "LuaLiuliVS",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards)
		if #cards == 1 then
			local liuli_card = LuaLiuliCard:clone()
			liuli_card:addSubcard(cards[1])
			return liuli_card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaLiuli"
	end
}
LuaLiuli = sgs.CreateTriggerSkill{
	name = "LuaLiuli", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.TargetConfirming},  
	view_as_skill = LuaLiuliVS, 
	on_trigger = function(self, event, player, data) 
		local use = data:toCardUse()
		local slash = use.card
		local source = use.from
		local targets = use.to
		if slash and slash:isKindOf("Slash") then
			if targets:contains(player) then
				if not player:isNude() then
					local room = player:getRoom()
					if room:alivePlayerCount() > 2 then
						local players = room:getOtherPlayers(player)
						players:removeOne(source)
						local can_invoke = false
						for _,p in sgs.qlist(players) do
							if player:canSlash(p, slash) then
								can_invoke = true
								break
							end
						end
						if can_invoke then
							local prompt = string.format("@liuli:%s", source:objectName())
							room:setPlayerFlag(source, "slash_source")
							sgs.LiuliPattern = {slash:getId()}
							if room:askForUseCard(player, "@@LuaLiuli", prompt) then
								room:removeTag("liuli-card")
								for _,p in sgs.qlist(players) do
									if p:hasFlag("liuli_target") then
										local new_targets = sgs.SPlayerList()
										for _,t in sgs.qlist(targets) do
											if t:objectName() == player:objectName() then
												new_targets:append(p)
											else
												new_targets:append(t)
											end
										end
										use.from = source
										use.to = new_targets
										use.card = slash
										data:setValue(use)
										room:setPlayerFlag(source, "-slash_source")
										room:setPlayerFlag(p, "-liuli_target")
										return true
									end
								end
							end
							room:removeTag("liuli-card")
						end
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：龙胆
	相关武将：标准·赵云、☆SP·赵云、翼·赵云
	描述：你可以将一张【杀】当【闪】，一张【闪】当【杀】使用或打出。
	引用：LuaLongdan
	状态：验证通过
]]--
sgs.LongdanPattern = {"pattern"}
LuaLongdan = sgs.CreateViewAsSkill{
	name = "LuaLongdan",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.LongdanPattern[1]
			if pattern == "slash" then
				return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
				return to_select:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			if card:isKindOf("Slash") then
				local jink = sgs.Sanguosha:cloneCard("jink", suit, point)
				jink:addSubcard(card)
				jink:setSkillName(self:objectName())
				return jink
			elseif card:isKindOf("Jink") then
				local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
				slash:addSubcard(card)
				slash:setSkillName(self:objectName())
				return slash
			end
		end
	end,
	enabled_at_play = function(self, player)
		if sgs.Slash_IsAvailable(player) then
			sgs.LongdanPattern = {"slash"}
			return true
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "jink" or pattern == "slash" then
			sgs.LongdanPattern = {pattern}
			return true
		end
		return false
	end
}
--[[
	技能名：龙魂
	相关武将：神·赵云
	描述：你可以将同花色的X张牌按下列规则使用或打出：红桃当【桃】，方块当具火焰伤害的【杀】，梅花当【闪】，黑桃当【无懈可击】（X为你当前的体力值且至少为1）。
	引用：LuaLonghun
	状态：验证通过
]]--
sgs.LonghunPattern = {"spade", "heart", "club", "diamond"}
LuaLonghun = sgs.CreateViewAsSkill{
	name = "LuaLonghun", 
	n = 999, 
	view_filter = function(self, selected, to_select)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #selected < n then
			if n > 1 then
				if #selected > 0 then
					local suit = selected[1]:getSuit()
					return to_select:getSuit() == suit
				end
			end
			local suit = to_select:getSuit()
			if sgs.LonghunPattern[1] == "true" and suit == sgs.Card_Spade then
				return true
			elseif sgs.LonghunPattern[2] == "true" and suit == sgs.Card_Heart then
				return true
			elseif sgs.LonghunPattern[3] == "true" and suit == sgs.Card_Club then
				return true
			elseif sgs.LonghunPattern[4] == "true" and suit == sgs.Card_Diamond then
				return true
			end
		end
		return false
	end, 
	view_as = function(self, cards)
		local hp = sgs.Self:getHp()
		local n = math.max(1, hp)
		if #cards == n then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = 0
			if #cards == 1 then
				number = card:getNumber()
			end
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("peach", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				for _,cd in pairs(cards) do
					new_card:addSubcard(cd)
				end
			end
			return new_card
		end
	end, 
	enabled_at_play = function(self, player)
		sgs.LonghunPattern = {"false", "false", "false", "false"}
		local flag = false
		if player:isWounded() then
			sgs.LonghunPattern[2] = "true"
			flag = true
		end
		if sgs.Slash_IsAvailable(player) then
			sgs.LonghunPattern[4] = "true"
			flag = true
		end
		return flag
	end, 
	enabled_at_response = function(self, player, pattern)
		sgs.LonghunPattern = {"false", "false", "false", "false"}
		if pattern == "slash" then
			sgs.LonghunPattern[4] = "true"
			return true
		elseif pattern == "jink" then
			sgs.LonghunPattern[3] = "true"
			return true
		elseif string.find(pattern, "peach") then
			sgs.LonghunPattern[2] = "true"
			return true
		elseif pattern == "nullification" then
			sgs.LonghunPattern[1] = "true"
			return true
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		sgs.LonghunPattern = {"true", "false", "false", "false"}
		local hp = player:getHp()
		local n = math.max(1, hp)
		local count = 0
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				count = count + 1
			end
		end
		return count >= n
	end
}
--[[
	技能名：龙魂
	相关武将：测试·高达一号
	描述：你可以将一张牌按以下规则使用或打出：♥当【桃】；♦当火【杀】；♠当【无懈可击】；♣当【闪】。回合开始阶段开始时，若其他角色的装备区内有【青釭剑】，你可以获得之。 
	引用：LuaXNosLonghun、LuaXDuojian
	状态：验证通过
]]--
sgs.NosLonghunPattern = {"spade", "heart", "club", "diamond"}
LuaXNosLonghun = sgs.CreateViewAsSkill{
	name = "LuaXNosLonghun", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if #selected < 1 then
			local suit = to_select:getSuit()
			if sgs.NosLonghunPattern[1] == "true" and suit == sgs.Card_Spade then
				return true
			elseif sgs.NosLonghunPattern[2] == "true" and suit == sgs.Card_Heart then
				return true
			elseif sgs.NosLonghunPattern[3] == "true" and suit == sgs.Card_Club then
				return true
			elseif sgs.NosLonghunPattern[4] == "true" and suit == sgs.Card_Diamond then
				return true
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local new_card = nil
			local suit = card:getSuit()
			local number = card:getNumber()
			if suit == sgs.Card_Spade then
				new_card = sgs.Sanguosha:cloneCard("nullification", suit, number)
			elseif suit == sgs.Card_Heart then
				new_card = sgs.Sanguosha:cloneCard("peach", suit, number)
			elseif suit == sgs.Card_Club then
				new_card = sgs.Sanguosha:cloneCard("jink", suit, number)
			elseif suit == sgs.Card_Diamond then
				new_card = sgs.Sanguosha:cloneCard("fire_slash", suit, number)
			end
			if new_card then
				new_card:setSkillName(self:objectName())
				new_card:addSubcard(card)
			end
			return new_card
		end
	end, 
	enabled_at_play = function(self, player)
		sgs.NosLonghunPattern = {"false", "false", "false", "false"}
		local flag = false
		if player:isWounded() then
			sgs.NosLonghunPattern[2] = "true"
			flag = true
		end
		if sgs.Slash_IsAvailable(player) then
			sgs.NosLonghunPattern[4] = "true"
			flag = true
		end
		return flag
	end, 
	enabled_at_response = function(self, player, pattern)
		sgs.NosLonghunPattern = {"false", "false", "false", "false"}
		if pattern == "slash" then
			sgs.NosLonghunPattern[4] = "true"
			return true
		elseif pattern == "jink" then
			sgs.NosLonghunPattern[3] = "true"
			return true
		elseif string.find(pattern, "peach") then
			sgs.NosLonghunPattern[2] = "true"
			return true
		elseif pattern == "nullification" then
			sgs.NosLonghunPattern[1] = "true"
			return true
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		sgs.NosLonghunPattern = {"true", "false", "false", "false"}
		local cards = player:getHandcards()
		for _,card in sgs.qlist(cards) do
			if card:objectName() == "nullification" then
				return true
			end
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		cards = player:getEquips()
		for _,card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Spade then
				return true
			end
		end
		return false
	end
}
LuaXDuojian = sgs.CreateTriggerSkill{
	name = "#LuaXDuojian",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local weapon = p:getWeapon()
				if weapon and weapon:objectName() == "QinggangSword" then
					if room:askForSkillInvoke(player, self:objectName()) then
						player:obtainCard(weapon)
					end
				end
			end
		end			
		return false	 
	end
}
--[[
	技能名：龙怒（聚气技）
	相关武将：长坂坡·神赵云
	描述：出牌阶段，你可以弃两张相同颜色的“怒”，若如此做，你使用的下一张【杀】不可被闪避。
]]--
--[[
	技能名：龙吟（特定技）
	相关武将：长坂坡·神赵云
	描述：聚气阶段，你可以从牌堆顶亮出三张牌，选择其中一张做为“怒”，其余收为手牌。
]]--
--[[
	技能名：笼络
	相关武将：智·张昭
	描述：回合结束阶段开始时，你可以选择一名其他角色摸取与你弃牌阶段弃牌数量相同的牌 
	引用：LuaXLongluo
	状态：验证通过
]]--
LuaXLongluo = sgs.CreateTriggerSkill{
	name = "LuaXLongluo",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local drawnum = player:getMark("longluo")
				if drawnum > 0 and player:askForSkillInvoke(self:objectName(), data) then
					local room = player:getRoom()
					local others = room:getOtherPlayers(player)
					local target = room:askForPlayerChosen(player, others, self:objectName())
					target:drawCards(drawnum)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				player:setMark("longluo", 0)
			end
			return false
		elseif player:getPhase() == sgs.Player_Discard then
			local move = data:toMoveOneTime()
			local source = move.from
			if source and source:objectName() == player:objectName() then
				if move.to_place == sgs.Player_DiscardPile then
					for _,id in sgs.qlist(move.card_ids) do
						player:addMark("longluo")
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：乱击
	相关武将：火·袁绍
	描述：你可以将两张花色相同的手牌当【万箭齐发】使用。
	引用：LuaLuanji
	状态：验证通过
]]--
LuaLuanji = sgs.CreateViewAsSkill{
	name = "LuaLuanji", 
	n = 2, 
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return not to_select:isEquipped()
		elseif #selected == 1 then
			local card = selected[1]
			if to_select:getSuit() == card:getSuit() then
				return not to_select:isEquipped()
			end
		else
			return false
		end
	end, 
	view_as = function(self, cards) 
		if #cards == 2 then
			local cardA = cards[1]
			local cardB = cards[2]
			local suit = cardA:getSuit()
			local aa = sgs.Sanguosha:cloneCard("archery_attack", suit, 0);
			aa:addSubcard(cardA)
			aa:addSubcard(cardB)
			aa:setSkillName(self:objectName())
			return aa
		end
	end
}
--[[
	技能名：乱武（限定技）
	相关武将：林·贾诩、SP·贾诩
	描述：出牌阶段，你可以令所有其他角色各选择一项：对距离最近的另一名角色使用一张【杀】，或失去1点体力。
	引用：LuaLuanwu、LuaLuanwuMark
	状态：验证通过
]]--
LuaLuanwuCard = sgs.CreateSkillCard{
	name = "LuaLuanwuCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets)
		source:loseMark("@chaos")
		local players = room:getOtherPlayers(source)
		for _,p in sgs.qlist(players) do
			if p:isAlive() then
				room:cardEffect(self, source, p)
			end
		end
	end,
	on_effect = function(self, effect)
		local dest = effect.to
		local room = dest:getRoom()
		local players = room:getOtherPlayers(dest)
		local nearest = 1000
		local distance_list = sgs.IntList()
		for _,player in sgs.qlist(players) do
			local dist = dest:distanceTo(player)
			distance_list:append(dist)
			if dist < nearest then
				nearest = dist
			end
		end
		local luanwu_targets = sgs.SPlayerList()
		local count = distance_list:length()
		for i=0, count, 1 do
			local dist = distance_list:at(i)
			if dist == nearest then
				local player = players:at(i)
				if dest:canSlash(player) then
					luanwu_targets:append(player)
				end
			end
		end
		if luanwu_targets:length() > 0 then
			if not room:askForUseSlashTo(dest, luanwu_targets, "@luanwu-slash") then
				room:loseHp(dest)
			end
		else
			room:loseHp(dest)
		end
	end
}
LuaLuanwu = sgs.CreateViewAsSkill{
	name = "LuaLuanwu", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaLuanwuCard:clone()
	end, 
	enabled_at_play = function(self, player)
		local count = player:getMark("@chaos")
		return count > 0
	end
}
LuaLuanwuMark = sgs.CreateTriggerSkill{
	name = "#LuaLuanwuMark",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@chaos", 1)
	end
}
--[[
	技能名：裸衣
	相关武将：标准·许褚
	描述：摸牌阶段，你可以少摸一张牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。
	引用：LuaLuoyiBuff、LuaLuoyi
	状态：验证通过
]]--
LuaLuoyiBuff = sgs.CreateTriggerSkill{
	name = "#LuaLuoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasFlag("LuaLuoyi") then
				return target:isAlive()
			end
		end
		return false
	end
}
LuaLuoyi = sgs.CreateTriggerSkill{
	name = "LuaLuoyi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local count = data:toInt()
		if count > 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				count = count - 1
				room:setPlayerFlag(player, "LuaLuoyi")
				data:setValue(count)
			end
		end
	end
}
--[[
	技能名：裸衣
	相关武将：翼·许褚
	描述：出牌阶段，你可以弃置一张装备牌，若如此做，你使用的【杀】或【决斗】（你为伤害来源时）造成的伤害+1，直到回合结束。每阶段限一次。 
	引用：LuaXNeoLuoyi、LuaXNeoLuoyiBuff
	状态：验证通过
]]--
LuaXNeoLuoyiCard = sgs.CreateSkillCard{
	name = "LuaXNeoLuoyiCard", 
	target_fixed = true, 
	will_throw = true, 
	on_use = function(self, room, source, targets) 
		source:setFlags("LuaXNeoLuoyi")
	end
}
LuaXNeoLuoyi = sgs.CreateViewAsSkill{
	name = "LuaXNeoLuoyi", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXNeoLuoyiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		if not player:hasUsed("#LuaXNeoLuoyiCard") then
			return not player:isNude()
		end
		return false
	end
}
LuaXNeoLuoyiBuff = sgs.CreateTriggerSkill{
	name = "#LuaXNeoLuoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasFlag("LuaXNeoLuoyi") then
				return target:isAlive()
			end
		end
		return false
	end
}
--[[
	技能名：洛神
	相关武将：标准·甄姬、SP·甄姬
	描述：回合开始阶段开始时，你可以进行一次判定，若判定结果为黑色，你获得此牌，你可以重复此流程，直到出现红色的判定结果为止。
	引用：LuaLuoshen
	状态：验证通过
]]--
LuaLuoshen = sgs.CreateTriggerSkill{
	name = "LuaLuoshen", 
	frequency = sgs.Skill_Frequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				while player:askForSkillInvoke(self:objectName()) do
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*):(spade|club):(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					judge.time_consuming = true
					room:judge(judge)
					if judge:isBad() then
						break
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				local card = judge.card
				if card:isBlack() then
					player:obtainCard(card)
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：落英
	相关武将：一将成名·曹植
	描述：当其他角色的梅花牌因弃置或判定而置入弃牌堆时，你可以获得之。
	引用：LuaLuoying
	状态：0224验证通过
]]--
require("bit")
LuaLuoying = sgs.CreateTriggerSkill{
	name = "LuaLuoying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source then
			if source:objectName() ~= player:objectName() then
				if move.to_place == sgs.Player_DiscardPile then
					local reason = move.reason.m_reason
					local flag = false
					if bit:_and(reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
						flag = true
					end
					if reason == sgs.CardMoveReason_S_REASON_JUDGEDONE then
						flag = true
					end
					if flag then
						local luoyingMove = sgs.CardsMoveStruct()
						luoyingMove.to = player
						luoyingMove.to_place = sgs.Player_PlaceHand
						local ids = sgs.QList2Table(move.card_ids)
						local places = move.from_places
						for i=1, #ids, 1 do
							local id = ids[i]
							local place = places[i]
							local suit = sgs.Sanguosha:getCard(id):getSuit()
							if suit == sgs.Card_Club then
								if place ~= sgs.Player_PlaceDelayedTrick then
									if place ~= sgs.Player_PlaceSpecial then
										if room:getCardPlace(id) == sgs.Player_DiscardPile then
											luoyingMove.card_ids:append(id)
										end
									end
								end
							end
						end
						if not luoyingMove.card_ids:isEmpty() then
							if player:askForSkillInvoke(self:objectName(), data) then
								if luoyingMove.card_ids:length() > 1 then
									while (not luoyingMove.card_ids:isEmpty()) do
										room:fillAG(luoyingMove.card_ids, player)
										local card_id = room:askForAG(player, luoyingMove.card_ids, true, self:objectName())
										player:invoke("clearAG")
										if card_id == -1 then
											break
										end
										luoyingMove.card_ids:removeOne(card_id)
									end
									if luoyingMove.card_ids:isEmpty() then
										return false
									end
								end
								room:moveCardsAtomic(luoyingMove, true)
							end
						end
					end
				end
			end
		end
		return false
	end,
	priority = 4
}
