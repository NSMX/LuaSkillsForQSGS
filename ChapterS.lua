--[[
	代码速查手册（S区）
	技能索引：
		伤逝、伤逝、烧营、涉猎、神愤、神戟、神君、神力、神速、神威、神智、师恩、识破、识破、恃才、恃勇、弑神、誓仇、授业、淑德、淑慎、双刃、双雄、水箭、水泳、死谏、死节、死战、颂词、颂威、随势
]]--
--[[
	技能名：伤逝（锁定技）
	相关武将：一将成名·张春华
	描述：弃牌阶段外，当你的手牌数小于X时，你将手牌补至X张（X为你已损失的体力值且最多为2）。
	引用：LuaShangshi
	状态：验证通过
]]--
LuaShangshi = sgs.CreateTriggerSkill{
	name = "LuaShangshi",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.MaxHpChanged, sgs.HpChanged},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local num = player:getHandcardNum()
		local lost = player:getLostHp()
		if lost > 2 then lost = 2 end
		if num >= lost then return end
		if player:getPhase() ~= sgs.Player_Discard then
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.from:objectName() == player:objectName() then
					if not room:askForSkillInvoke(player,self:objectName()) then return end
					player:drawCards(lost-num)
				end
			end	
			if event == sgs.MaxHpChanged or event == sgs.HpChanged then
				if not room:askForSkillInvoke(player,self:objectName()) then return end
				player:drawCards(lost-num)
			end	
		end
	end	
}
--[[
	技能名：伤逝
	相关武将：怀旧·张春华
	描述：弃牌阶段外，当你的手牌数小于X时，你可以将手牌补至X张（X为你已损失的体力值） 
	引用：LuaNosShangshi
	状态：验证通过
]]--
LuaNosShangshi = sgs.CreateTriggerSkill {
	name = "LuaNosShangshi",
	events={sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local CAN = nil
			if move.from:objectName() == player:objectName() then 
				CAN = move.from_places:contains(sgs.Player_PlaceHand)
			elseif move.to:objectName() == player:objectName() then 
				CAN = move.to_place==sgs.Player_PlaceHand 
			end
			if not CAN then 
				return 
			end
		end
		if event == sgs.EventPhaseChanging then 
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Finish then 
				return 
			end
		end
		if event == sgs.EventAcquireSkill then 
			local string = data:toString()
			if string ~= self:objectName() then 
				return 
			end
		end
		local Num = player:getHandcardNum()
		local Mhp = player:getMaxHp()
		local Lhp = player:getLostHp()
		local x = math.min(Lhp, Mhp) - Num
		if x > 0 and player:getHp() > 0 then 
			if player:getPhase() ~= sgs.Player_Discard then 
				if player:askForSkillInvoke(self:objectName()) then 
					player:drawCards(x)
				end
			end	
		end 
	end
}
--[[
	技能名：烧营
	相关武将：倚天·陆伯言
	描述：当你对一名不处于连环状态的角色造成一次火焰伤害时，你可选择一名其距离为1的另外一名角色并进行一次判定：若判定结果为红色，则你对选择的角色造成一点火焰伤害 
	引用：LuaXShaoying
	状态：验证通过
]]--
LuaXShaoying = sgs.CreateTriggerSkill{
	name = "LuaXShaoying",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.DamageComplete},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local source = damage.from
		local target = damage.to
		if player and source then
			if source:hasSkill(self:objectName()) then
				if not target:isChained() then
					if damage.nature == sgs.DamageStruct_Fire then 
						local room = player:getRoom()
						local targets = sgs.SPlayerList()
						local tag = sgs.QVariant(target:objectName())
						room:setTag("Shaoying", tag)
						local allplayers = room:getAlivePlayers()
						for _,p in sgs.qlist(allplayers) do
							if target:distanceTo(p) == 1 then
								targets:append(p)
							end
						end
						if not targets:isEmpty() then
							if source:askForSkillInvoke(self:objectName(), data) then
								local victim = room:askForPlayerChosen(source, targets, self:objectName())
								room:setTag("Shaoying", sgs.QVariant())
								local judge = sgs.JudgeStruct()
								judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
								judge.good = true
								judge.reason = self:objectName()
								judge.who = source
								room:judge(judge)
								if judge:isGood() then
									local shaoying_damage = sgs.DamageStruct()
									shaoying_damage.nature = sgs.DamageStruct_Fire
									shaoying_damage.from = source				
									shaoying_damage.to = victim
									room:damage(shaoying_damage)
								end
							end
						end
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
--[[
	技能名：涉猎
	相关武将：神·吕蒙
	描述：摸牌阶段开始时，你可以放弃摸牌，改为从牌堆顶亮出五张牌，你获得不同花色的牌各一张，将其余的牌置入弃牌堆。 
	引用：LuaShelie
	状态：验证通过
]]--
LuaShelie = sgs.CreateTriggerSkill{
	name = "LuaShelie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() ~= sgs.Player_Draw then
			return false
		end
		local room = player:getRoom()
		if not player:askForSkillInvoke(self:objectName()) then
			return false
		end
		local card_ids = room:getNCards(5)
		room:fillAG(card_ids)
		while (not card_ids:isEmpty()) do
			local card_id = room:askForAG(player, card_ids, false, self:objectName())
			card_ids:removeOne(card_id)
			local card = sgs.Sanguosha:getCard(card_id)
			local suit = card:getSuit()
			room:takeAG(player, card_id)
			local removelist = {}
			for _,id in sgs.qlist(card_ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit() == suit then
					room:takeAG(nil, c:getId())
					table.insert(removelist, id)
				end
			end
			if #removelist > 0 then
				for _,id in ipairs(removelist) do
					if card_ids:contains(id) then
						card_ids:removeOne(id)
					end
				end
			end
		end
		room:broadcastInvoke("clearAG")
		return true
	end
}
--[[
	技能名：神愤
	相关武将：神·吕布
	描述：出牌阶段，你可以弃6枚“暴怒”标记，对所有其他角色各造成1点伤害，所有其他角色先弃置各自装备区里的牌，再弃置四张手牌，然后将你的武将牌翻面。每阶段限一次。
	引用：LuaShenfen
	状态：验证通过
]]--
LuaShenfenCard = sgs.CreateSkillCard{
	name = "LuaShenfenCard", 
	target_fixed = true,
	will_throw = true, 
	on_use = function(self, room, source, targets)
		source:loseMark("@wrath", 6)
		local players = room:getOtherPlayers(source)
		for _,player in sgs.qlist(players) do
			local damage = sgs.DamageStruct()
			damage.card = self
			damage.from = source
			damage.to = player
			room:damage(damage)
		end
		for _,player in sgs.qlist(players) do
			player:throwAllEquips()
		end
		for _,player in sgs.qlist(players) do
			local count = player:getHandcardNum()
			if count <= 4 then
				player:throwAllHandCards()
			else
				room:askForDiscard(player, self:objectName(), 4, 4)
			end
		end
		source:turnOver()
	end
}
LuaShenfen = sgs.CreateViewAsSkill{
	name = "LuaShenfen", 
	n = 0,
	view_as = function(self, cards)
		return LuaShenfenCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@wrath") >= 6 then
			return not player:hasUsed("#LuaShenfenCard")
		end
		return false
	end
}
--[[
	技能名：神戟
	相关武将：SP·暴怒战神
	描述：若你的装备区没有武器牌，当你使用【杀】时，你可以额外选择至多两个目标。
	状态：尚未验证	
	附注：由于TargetModSkill为锁定技，与描述有出入，所以创建一个仅提供按键图标的空壳视为技，功能由TargetModSkill实现。
]]--
LuaShenji = sgs.CreateViewAsSkill{
	name = "LuaShenji",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return false
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
LuaShenjiHid = sgs.CreateTargetModSkill{
	name = "#LuaShenjiHid",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			if player:getWeapon() == nil then
				return 2
			end
		end
	end,
}
--[[
	技能名：神君（锁定技）
	相关武将：倚天·陆伯言
	描述：游戏开始时，你必须选择自己的性别。回合开始阶段开始时，你必须倒转性别，异性角色对你造成的非雷电属性伤害无效 
	引用：LuaXShenjun
	状态：验证通过
]]--
LuaXShenjun = sgs.CreateTriggerSkill{
	name = "LuaXShenjun",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart then
			local gender = room:askForChoice(player, self:objectName(), "male+female")
			local is_male = player:isMale()
			if gender == "female" then
				if is_male then
					player:setGender(sgs.General_Female)
				end
			elseif gender == "male" then
				if not is_male then
					player:setGender(sgs.General_Male)
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if player:isMale() then
					player:setGender(sgs.General_Female)
				else
					player:setGender(sgs.General_Male)
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Thunder then
				local source = damage.from
				if source and source:isMale() ~= player:isMale() then
					return true
				end
			end
		end
		return false
	end
}
--[[
	技能名：神力（锁定技）
	相关武将：倚天·古之恶来
	描述：出牌阶段，你使用【杀】造成的第一次伤害+X，X为当前死战标记数且最大为3 
	引用：LuaXShenli
	状态：验证通过
]]--
LuaXShenli = sgs.CreateTriggerSkill{
	name = "LuaXShenli",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.ConfirmDamage},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash and slash:isKindOf("Slash") then
			if player:getPhase() == sgs.Player_Play then
				if not player:hasFlag("shenli") then
					player:setFlags("shenli")
					local x = player:getMark("@struggle")
					if x > 0 then
						x = math.min(3, x)
						damage.damage = damage.damage + x
						data:setValue(damage)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：神速
	相关武将：风·夏侯渊
	描述：你可以选择一至两项：
		1.跳过你的判定阶段和摸牌阶段。
		2.跳过你的出牌阶段并弃置一张装备牌。
		你每选择一项，视为对一名其他角色使用一张【杀】（无距离限制）。
	引用：LuaShensu
	状态：验证通过
]]--
LuaShensu_Pattern = nil
LuaShensuCard = sgs.CreateSkillCard{
	name = "LuaShensuCard",
	mute = true,
	filter = function(self, targets, to_select)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("LuaShensu") 
		local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, slash) + 1
		return sgs.Self:canSlash(to_select, slash, false) and #targets < extra
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local change = sgs.SPlayerList()
		slash:setSkillName("LuaShensu")
		for _, play in ipairs (targets) do
			change:append(play) 
		end
		local use = sgs.CardUseStruct()
		use.card = slash
		use.to = change
		use.from = source
		room:useCard(use)
	end,
}
LuaShensuVS = sgs.CreateViewAsSkill{
	name = "LuaShensu",
	n = 1,
	view_filter = function(self, selected, to_select)
		if string.sub(LuaShensu_Pattern, -1) == "1" then
			return false
		else
			return #selected == 0 and to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self, cards)					
		if string.sub(LuaShensu_Pattern, -1) == "1" then
			if #cards == 0 then
				return LuaShensuCard:clone()
			else
				return nil
			end
		else
			if #cards == 1 then
				local card = LuaShensuCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		LuaShensu_Pattern = pattern 
		return string.sub(LuaShensu_Pattern, 1, -2) == "@@LuaShensu" and sgs.Slash_IsAvailable(player)
	end,
}
LuaShensu = sgs.CreateTriggerSkill{
	name = "LuaShensu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	view_as_skill = LuaShensuVS,
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		local room = player:getRoom()
		if change.to == sgs.Player_Judge then
			if not player:isSkipped(sgs.Player_Judge) then
				if not player:isSkipped(sgs.Player_Draw) then
					if room:askForUseCard(player, "@@LuaShensu1", "@LuaShensu1", 1) then
						player:skip(sgs.Player_Judge)
						player:skip(sgs.Player_Draw)
					end
				end
			end
		elseif change.to == sgs.Player_Play then
			if not player:isSkipped(sgs.Player_Play) then
				if room:askForUseCard(player, "@@LuaShensu2", "@LuaShensu2", 2, sgs.Card_MethodDiscard) then
					player:skip(sgs.Player_Play)
				end
			end
		end
		return false
	end,
}
--[[
	技能名：神威（锁定技）
	相关武将：SP·暴怒战神
	描述：摸牌阶段，你额外摸两张牌；你的手牌上限+2。
	引用：LuaShenwei、LuaShenweiKeep
	状态：验证通过
]]--
LuaShenwei = sgs.CreateTriggerSkill{
	name = "LuaShenwei", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DrawNCards}, 
	on_trigger = function(self, event, player, data) 
		local count = data:toInt() + 2
		data:setValue(count)
	end
}
LuaShenweiKeep = sgs.CreateMaxCardsSkill{
	name = "#LuaShenwei", 
	extra_func = function(self, target) 
		if target:hasSkill(self:objectName()) then
			return 2
		end
	end
}
--[[
	技能名：神智
	相关武将：国战·甘夫人
	描述：回合开始阶段开始时，你可以弃置所有手牌：若你以此法弃置的牌不少于X张，你回复1点体力。（X为你当前的体力值） 
	引用：LuaXShenzhi
	状态：0224验证通过
]]--
LuaXShenzhi = sgs.CreateTriggerSkill{
	name = "LuaXShenzhi",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if not player:isKongcheng() then
				local handcards = player:getHandcards()
				for _,card in sgs.qlist(handcards) do
					if player:isJilei(card) then
						return false
					end
				end
				if room:askForSkillInvoke(player, self:objectName()) then
					local handcard_num = player:getHandcardNum()
					player:throwAllHandCards()
					if handcard_num >= player:getHp() then
						local recover = sgs.RecoverStruct()
						recover.who = player
						room:recover(player, recover)
					end
				end
			end
		end
		return false
	end
}
--[[
	技能名：师恩
	相关武将：智·司马徽
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
	引用：LuaXShien
	状态：验证通过
]]--
LuaXShien = sgs.CreateTriggerSkill{
	name = "LuaXShien",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.CardUsed, sgs.CardResponsed},  
	on_trigger = function(self, event, player, data) 
		if player and player:getMark("forbid_shien") == 0 then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			elseif event == sgs.CardResponsed then
				card = data:toResponsed().m_card
			end
			if card:isNDTrick() then
				local room = player:getRoom()
				local teacher = room:findPlayerBySkillName(self:objectName())
				if teacher:isAlive() then
					local ai_data = sgs.QVariant()
					ai_data:setValue(teacher)
					if room:askForSkillInvoke(player, self:objectName(), ai_data) then
						teacher:drawCards(1)
					else
						local dontaskmeneither = room:askForChoice(player, "forbid_shien", "yes+no")
						if dontaskmeneither == "yes" then
							player:setMark("forbid_shien", 1)
						end
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return not target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：识破
	相关武将：智·田丰
	描述：任意角色判定阶段判定前，你可以弃置两张牌，获得该角色判定区里的所有牌 
	引用：LuaXShipo
	状态：验证通过
]]--
LuaXShipo = sgs.CreateTriggerSkill{
	name = "LuaXShipo",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Judge then
			local judges = player:getJudgingArea()
			if judges:length() > 0 then
				local room = player:getRoom()
				local list = room:getAlivePlayers()
				for _,source in sgs.qlist(list) do
					if source:hasSkill(self:objectName()) then
						if source:getCardCount(true) >= 2 then
							local ai_data = sgs.QVariant()
							ai_data:setValue(player)
							if room:askForSkillInvoke(source, self:objectName(), ai_data) then
								if room:askForDiscard(source, self:objectName(), 2, 2, false, true) then
									for _,jcd in sgs.qlist(judges) do
										source:obtainCard(jcd)
									end
									break
								end
							end
						end
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
--[[
	技能名：识破（锁定技）
	相关武将：3D织梦·李儒
	描述：你不能成为黑桃【杀】或黑桃锦囊的目标。 
]]--
--[[
	技能名：恃才（锁定技）
	相关武将：智·许攸
	描述：当你拼点成功时，摸一张牌 
	引用：LuaXShicai
	状态：验证通过
]]--
LuaXShicai = sgs.CreateTriggerSkill{
	name = "LuaXShicai",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Pindian},  
	on_trigger = function(self, event, player, data) 
		if player then
			local room = player:getRoom()
			local xuyou = room:findPlayerBySkillName(self:objectName())
			if xuyou then
				local pindian = data:toPindian()
				local source = pindian.from
				local target = pindian.to
				if source:objectName() == xuyou:objectName() or target:objectName() == xuyou:objectName() then
					local winner
					if pindian.from_card:getNumber() > pindian.to_card:getNumber() then
						winner = source 
					else
						winner = target
					end
					if winner:objectName() == xuyou:objectName() then
						xuyou:drawCards(1)
					end
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		return target
	end, 
	priority = -1
}
--[[
	技能名：恃勇（锁定技）
	相关武将：二将成名·华雄
	描述：每当你受到一次红色的【杀】或因【酒】生效而伤害+1的【杀】造成的伤害后，你减1点体力上限。
	引用：LuaShiyong
	状态：验证通过
]]--
LuaShiyong = sgs.CreateTriggerSkill{
	name = "LuaShiyong",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.Damaged},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		local slash = damage.card
		if slash then
			if slash:isKindOf("Slash") then
				if slash:isRed() or slash:hasFlag("drank") then
					local room = player:getRoom()
					room:loseMaxHp(player)
				end
			end
		end
		return false
	end
}
--[[
	技能名：弑神（聚气技）
	相关武将：长坂坡·神张飞
	描述：出牌阶段，你可以弃两张相同颜色的“怒”，令任一角色流失1点体力。
]]--
--[[
	技能名：誓仇（主公技、限定技）
	相关武将：☆SP·刘备
	描述：你的回合开始时，你可指定一名蜀国角色并交给其两张牌。本盘游戏中，每当你受到伤害时，改为该角色替你受到等量的伤害，然后摸等量的牌，直至该角色第一次进入濒死状态。
	引用：LuaShichou
	状态：验证通过
]]--
LuaShichou = sgs.CreateTriggerSkill{
	name = "LuaShichou$", 
	frequency = sgs.Skill_Limited, 
	events = {sgs.GameStart, sgs.EventPhaseStart, sgs.DamageInflicted, sgs.Dying, sgs.DamageComplete},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasLordSkill(self:objectName()) then
				room:setPlayerMark(player, "@hate", 1)
			end
		elseif event == sgs.EventPhaseStart then
			if player:hasLordSkill(self:objectName()) then
				if player:getPhase() == sgs.Player_Start then
					if player:getMark("shichouInvoke") == 0 then
						if player:getCards("he"):length() > 1 then
							local targets = room:getOtherPlayers(player)
							local victims = sgs.SPlayerList()
							for _,target in sgs.qlist(targets) do
								if target:getKingdom() == "shu" then
									victims:append(target)
								end
							end
							if victims:length() > 0 then
								if player:askForSkillInvoke(self:objectName()) then
									player:loseMark("@hate", 1)
									room:setPlayerMark(player, "shichouInvoke", 1)
									local victim = room:askForPlayerChosen(player, victims, self:objectName())
									room:setPlayerMark(victim, "@chou", 1)
									local tagvalue = sgs.QVariant()
									tagvalue:setValue(victim)
									room:setTag("ShichouTarget", tagvalue)
									local card = room:askForExchange(player, self:objectName(), 2, true, "ShichouGive")
									room:obtainCard(victim, card, false)
								end
							end
						end
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			if player:hasLordSkill(self:objectName(), true) then
				local tag = room:getTag("ShichouTarget")
				if tag then
					local target = tag:toPlayer()
					if target then
						room:setPlayerFlag(target, "Shichou")
						if player:objectName() ~= target:objectName() then
							local damage = data:toDamage()
							damage.to = target
							damage.transfer = true
							room:damage(damage)
							return true
						end
					end
				end
			end
		elseif event == sgs.DamageComplete then
			if player:hasFlag("Shichou") then
				local damage = data:toDamage()
				local count = damage.damage
				player:drawCards(count)
				room:setPlayerFlag(player, "-Shichou")
			end
		elseif event == sgs.Dying then
			if player:getMark("@chou") > 0 then
				player:loseMark("@chou")
				local list = room:getAlivePlayers()
				for _,lord in sgs.qlist(list) do
					if lord:hasLordSkill(self:objectName(), true) then
						local tag = room:getTag("ShichouTarget") 
						local target = tag:toPlayer()
						if target:objectName() == player:objectName() then
							room:removeTag("ShichouTarget")
						end
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
--[[
	技能名：授业
	相关武将：智·司马徽
	描述：出牌阶段，你可以弃置一张红色手牌，指定最多两名其他角色各摸一张牌 
	引用：LuaXShouye
	状态：验证通过
]]--
LuaXShouyeCard = sgs.CreateSkillCard{
	name = "LuaXShouyeCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets < 2 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		local source = effect.from
		effect.to:drawCards(1)
		if source:getMark("jiehuo") == 0 then
			source:gainMark("@shouye")
		end
	end
}
LuaXShouye = sgs.CreateViewAsSkill{
	name = "LuaXShouye", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			return to_select:isRed()
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards > 0 then
			local shouye_card = LuaXShouyeCard:clone()
			shouye_card:addSubcard(cards[1]:getId())
			return shouye_card
		end
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("shouyeonce") > 0 then
			return not player:hasUsed("#LuaXShouyeCard")
		end
		return true
	end
}
--[[
	技能名：淑德
	相关武将：贴纸·王元姬
	描述：回合结束阶段开始时，你可以将手牌数补至等同于体力上限的张数。 
	引用：LuaXShude
	状态：验证通过
]]--
LuaXShude = sgs.CreateTriggerSkill{
	name = "LuaXShude",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getMaxHp() - player:getHandcardNum()
		if player:getPhase() == sgs.Player_Finish then
			if x > 0 then 
				if room:askForSkillInvoke(player, self:objectName()) then
					player:drawCards(x)
				end
			end
		end
	end
}
--[[
	技能名：淑慎
	相关武将：国战·甘夫人
	描述：每当你回复1点体力后，你可以令一名其他角色摸一张牌。
	引用：LuaXShushen
	状态：0224验证通过
]]--
LuaXShushenCard = sgs.CreateSkillCard{
	name = "LuaXShushenCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_effect = function(self, effect) 
		effect.to:drawCards(1)
	end
}
LuaXShushenVS = sgs.CreateViewAsSkill{
	name = "LuaXShushen", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaXShushenCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXShushen"
	end
}
LuaXShushen = sgs.CreateTriggerSkill{
	name = "LuaXShushen",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.HpRecover},  
	view_as_skill = LuaXShushenVS, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local recover_struct = data:toRecover()
		local recover = recover_struct.recover
		for i=1, recover, 1 do
			if not room:askForUseCard(player, "@@LuaXShushen", "@shushen-draw") then
				break
			end
		end
		return false
	end
}
--[[
	技能名：双刃
	相关武将：国战·纪灵
	描述：出牌阶段开始时，你可以与一名其他角色拼点：若你赢，视为你一名其他角色使用一张无距离限制的普通【杀】（此【杀】不计入出牌阶段使用次数的限制）；若你没赢，你结束出牌阶段。 
	引用：LuaXShuangren
	状态：0224验证通过
]]--
LuaXShuangrenCard = sgs.CreateSkillCard{
	name = "LuaXShuangrenCard", 
	target_fixed = false, 
	will_throw = false, 
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select) 
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect) 
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "LuaXShuangren", self)
		if success then
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(effect.from)
			for _,target in sgs.qlist(others) do
				if effect.from:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(effect.from, targets, "shuangren-slash")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("LuaXShuangren")
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = effect.from
				card_use.to:append(target)
				room:useCard(card_use, false)
			end
		else
			room:setPlayerFlag(effect.from, "SkipPlay")
		end
	end
}
LuaXShuangrenVS = sgs.CreateViewAsSkill{
	name = "LuaXShuangren", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = LuaXShuangrenCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@LuaXShuangren"
	end
}
LuaXShuangren = sgs.CreateTriggerSkill{
	name = "LuaXShuangren",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart},  
	view_as_skill = LuaXShuangrenVS, 
	on_trigger = function(self, event, player, data) 
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				room:askForUseCard(player, "@@LuaXShuangren", "@shuangren-card", -1, sgs.Card_MethodPindian)
			end
			if player:hasFlag("SkipPlay") then
				return true
			end
		end
		return false
	end
}
--[[
	技能名：双雄
	相关武将：火·颜良文丑
	描述：摸牌阶段开始时，你可以放弃摸牌，改为进行一次判定，你获得生效后的判定牌，然后你可以将一张与此判定牌颜色不同的手牌当【决斗】使用，直到回合结束。 
	引用：LuaShuangxiong
	状态：验证通过
]]--
LuaShuangxiongVS = sgs.CreateViewAsSkill{
	name = "LuaShuangxiong", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		if not to_select:isEquipped() then
			local value = sgs.Self:getMark("shuangxiong")
			if value == 1 then
				return to_select:isBlack()
			elseif value == 2 then
				return card:isRed()
			end
		end
		return false
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then
			local card = cards[1]
			local suit = card:getSuit()
			local point = card:getNumber()
			local duel = sgs.Sanguosha:cloneCard("duel", suit, point)
			duel:addSubcard(card)
			duel:setSkillName(self:objectName())
			return duel
		end
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("shuangxiong") > 0
	end
}
LuaShuangxiong = sgs.CreateTriggerSkill{
	name = "LuaShuangxiong",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart, sgs.FinishJudge}, 
	view_as_skill = LuaShuangxiongVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "shuangxiong", 0)
			elseif player:getPhase() == sgs.Player_Draw then
				if player:askForSkillInvoke(self:objectName()) then
					local judge = sgs.JudgeStruct()
					judge.pattern = sgs.QRegExp("(.*)")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge.card:isRed() then
						room:setPlayerMark(player, "shuangxiong", 1)
					else
						room:setPlayerMark(player, "shuangxiong", 2)
					end
					return true
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason == self:objectName() then
				player:obtainCard(judge.card)
				return true
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:isAlive() then
				return target:hasSkill(self:objectName())
			end
		end
		return false
	end
}
--[[
	技能名：水箭
	相关武将：奥运·孙扬
	描述：摸牌阶段摸牌时，你可以额外摸X+1张牌，X为你装备区的牌数量的一半（向下取整）。 
	引用：LuaXShuijian
	状态：验证通过
]]--
LuaXShuijian = sgs.CreateTriggerSkill{
	name = "LuaXShuijian",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
		if player:askForSkillInvoke(self:objectName(), data) then
			local equips = player:getEquips()
			local length = equips:length()
			local extra = (length / 2) + 1
			local count = data:toInt() + extra
			data:setValue(count)
			return false
		end
	end
}
--[[
	技能名：水泳（锁定技）
	相关武将：奥运·叶诗文
	描述：防止你受到的火焰伤害。 
	引用：LuaXShuiyong
	状态：验证通过
]]--
LuaXShuiyong = sgs.CreateTriggerSkill{
	name = "LuaXShuiyong",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.sgs.DamageInflicted},  
	on_trigger = function(self, event, player, data) 
		local damage = data:toDamage()
		return damage.nature == sgs.DamageStruct_Fire 
	end
}
--[[
	技能：死谏
	相关武将：国战·田丰
	描述：每当你失去最后的手牌后，你可以弃置一名其他角色的一张牌。 
	状态：尚未验证
]]--
--[[
	技能名：死节
	相关武将：3D织梦·沮授
	描述：每当你受到1点伤害后，可弃置一名角色的X张牌（X为该角色已损失的体力值，且至少为1）。 
]]--
--[[
	技能名：死战（锁定技）
	相关武将：倚天·古之恶来
	描述：当你受到伤害时，防止该伤害并获得与伤害点数等量的死战标记；你的回合结束阶段开始时，你须弃掉所有的X个死战标记并流失X点体力 
	引用：LuaXSizhan
	状态：验证通过
]]--
LuaXSizhan = sgs.CreateTriggerSkill{
	name = "LuaXSizhan",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.DamageInflicted, sgs.EventPhaseStart},  
	on_trigger = function(self, event, player, data) 
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			player:gainMark("@struggle", damage.damage)
			return true
		elseif event == sgs.EventPhaseStart then	
			if player:getPhase() == sgs.Player_Finish then
				local x = player:getMark("@struggle")
				if x > 0 then
					local room = player:getRoom()
					player:loseMark("@struggle", x)
					room:loseHp(player, x)
				end
				player:setFlags("-shenli")
			end
		end
		return false
	end
}
--[[
	技能名：颂词
	相关武将：SP·陈琳
	描述：出牌阶段，你可以选择一项：1、令一名手牌数小于其当前的体力值的角色摸两张牌。2、令一名手牌数大于其当前的体力值的角色弃置两张牌。每名角色每局游戏限一次。
	引用：LuaSongci、LuaSongciClear
	状态：验证通过
]]--
LuaSongciCard = sgs.CreateSkillCard{
	name = "LuaSongciCard", 
	target_fixed = false, 
	will_throw = true, 
	filter = function(self, targets, to_select) 
		if to_select:getMark("@songci") == 0 then
			local num = to_select:getHandcardNum()
			local hp = to_select:getHp()
			return num ~= hp
		end
		return false
	end,
	on_effect = function(self, effect) 
		local target = effect.to
		local handcard_num = target:getHandcardNum()
		local hp = target:getHp()
		local room = target:getRoom()
		if handcard_num ~= hp then
			target:gainMark("@songci")
			if handcard_num > hp then
				room:askForDiscard(target, "LuaSongci", 2, 2, false, true)
			elseif handcard_num < hp then
				room:drawCards(target, 2, "LuaSongci")
			end
		end
	end
}
LuaSongci = sgs.CreateViewAsSkill{
	name = "LuaSongci", 
	n = 0, 
	view_as = function(self, cards) 
		return LuaSongciCard:clone()
	end, 
	enabled_at_play = function(self, player)
		if player:getMark("@songci") == 0 then
			if player:getHandcardNum() ~= player:getHp() then
				return true
			end
		end
		local siblings = player:getSiblings()
		for _,sib in sgs.qlist(siblings) do
			if sib:getMark("@songci") == 0 then
				if sib:getHandcardNum() ~= sib:getHp() then
					return true
				end
			end
		end
		return false
	end
}
LuaSongciClear = sgs.CreateTriggerSkill{
	name = "#LuaSongciClear",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.Death},   
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local list = room:getAllPlayers()
		for _,p in sgs.qlist(list) do
			if p:getMark("@songci") > 0 then
				room:setPlayerMark(p, "@songci", 0)
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:hasSkill(self:objectName())
		end
		return false
	end
}
--[[
	技能名：颂威（主公技）
	相关武将：林·曹丕、铜雀台·曹丕
	描述：其他魏势力角色的判定牌为黑色且生效后，该角色可以令你摸一张牌。
	引用：LuaSongwei
	状态：验证通过
]]--
LuaSongwei = sgs.CreateTriggerSkill{
	name = "LuaSongwei$", 
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.FinishJudge},  
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		if card:isBlack() then
			local targets = room:getOtherPlayers(player)
			for _,p in sgs.qlist(targets) do
				if p:hasLordSkill(self:objectName()) then
					if player:askForSkillInvoke(self:objectName()) then
						p:drawCards(1)
						p:setFlags("songweiused")
					end
				end
			end
			targets = room:getAllPlayers()
			for _,p in sgs.qlist(targets) do
				if p:hasFlag("songweiused") then
					p:setFlags("-songweiused")
				end
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			return target:getKingdom() == "wei"
		end
		return false
	end
}
--[[
	技能：随势
	相关武将：国战·田丰
	描述：每当其他角色进入濒死状态时，伤害来源可以令你摸一张牌；每当其他角色死亡时，伤害来源可以令你失去1点体力。
	引用：LuaXSuishi
	状态：0224验证通过
]]--
LuaXSuishi = sgs.CreateTriggerSkill{
	name = "LuaXSuishi",  
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying, sgs.Death},  
	on_trigger = function(self, event, player, data) 
		local target = nil
		local room = player:getRoom()
		if event == sgs.Dying then
			local dying = data:toDying()
			local damage = dying.damage
			if damage and damage.from then
				target = damage.from
			end
			local victim = dying.who
			if not victim or victim:objectName() ~= player:objectName() then
				if target then
					if room:askForChoice(target, "suishi1", "draw+no") == "draw" then
						player:drawCards(1)
					end
				end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local damage = death.damage
			if damage and damage.from then
				target = damage.from
			end
			if target then
				if room:askForChoice(target, "suishi2", "loseHp+no") == "loseHp" then
					room:loseHp(player)
				end
			end
		end
		return false
	end
}
