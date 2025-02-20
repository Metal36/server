-----------------------------------
-- Ability: Steal
-- Steal items from enemy.
-- Obtained: Thief Level 5
-- Recast Time: 5:00
-- Duration: Instant
-----------------------------------
require("scripts/globals/jobpoints")
require("scripts/settings/main")
require("scripts/globals/items")
require("scripts/globals/msg")
require("scripts/globals/quests")
require("scripts/globals/status")
-----------------------------------
local ability_object = {}

-- these are the quadavs that the thf af1 item can be stolen from
-- bronze quadav groupid = 7949
-- garnet quadav groupid = 7960
-- silver quadav groupid = 7977
-- zircorn quadav groupid = 7985
local validThfQuestMobs =
{
    17379367, 17379368, 17379459, 17379470, 17379477, 17379489, 17379493, 17379495, 17379501, 17379505, 17379509,
    17379513, 17379517, 17379521, 17379525, 17379529, 17379533, 17379538, 17379543, 17379547, 17379552, 17379556,
    17379560, 17379565, 17379569, 17379573, 17379577, 17379581, 17379585, 17379597, 17379363, 17379364, 17379462,
    17379473, 17379480, 17379496, 17379498, 17379500, 17379504, 17379508, 17379512, 17379516, 17379520, 17379524,
    17379528, 17379532, 17379536, 17379541, 17379546, 17379550, 17379555, 17379559, 17379563, 17379568, 17379572,
    17379576, 17379580, 17379584, 17379588, 17379600, 17379361, 17379362, 17379460, 17379471, 17379478, 17379490,
    17379491, 17379497, 17379502, 17379506, 17379510, 17379514, 17379518, 17379522, 17379526, 17379530, 17379534,
    17379539, 17379544, 17379548, 17379553, 17379557, 17379561, 17379566, 17379570, 17379574, 17379578, 17379582,
    17379586, 17379598, 17379365, 17379366, 17379461, 17379472, 17379479, 17379492, 17379494, 17379499, 17379503,
    17379507, 17379511, 17379515, 17379519, 17379523, 17379527, 17379531, 17379535, 17379540, 17379545, 17379549,
    17379554, 17379558, 17379562, 17379567, 17379571, 17379575, 17379579, 17379583, 17379587, 17379599
}

local function checkThfAfQuest(player, target)
    local targid = target:getID()

    if player:getQuestStatus(xi.quest.log_id.WINDURST, xi.quest.id.windurst.THE_TENSHODO_SHOWDOWN) == QUEST_ACCEPTED then
        for key, value in pairs(validThfQuestMobs) do
            if value == targid then
                return true
            end
        end
    return false
    end
end

ability_object.onAbilityCheck = function(player, target, ability)
    if player:getFreeSlotsCount() == 0 then
        return xi.msg.basic.FULL_INVENTORY, 0
    else
        -- JP Recast Reduction
        local jpValue = player:getJobPointLevel(xi.jp.STEAL_RECAST)
        ability:setRecast(ability:getRecast() - 2 * jpValue)
        return 0, 0
    end
end

ability_object.onUseAbility = function(player, target, ability, action)
    local thfLevel
    local stolen = 0

    if player:getMainJob() == xi.job.THF then
        thfLevel = player:getMainLvl()
    else
        thfLevel = player:getSubLvl()
    end

    local stealMod = player:getMod(xi.mod.STEAL)

    local stealChance = 50 + stealMod * 2 + thfLevel - target:getMainLvl()

    stolen = target:getStealItem()
    if target:isMob() and math.random(100) < stealChance and stolen ~= 0 then
        -- This guarantees item if quest is flagged
        if checkThfAfQuest(player, target) == true then
            stolen = xi.items.BOWL_OF_QUADAV_STEW
        end

        player:addItem(stolen)
        target:itemStolen()
        ability:setMsg(xi.msg.basic.STEAL_SUCCESS) -- Item stolen successfully
        target:triggerListener("ITEM_STOLEN", target, player, stolen)
        -- Aura Steal does not trigger on successful item steal
        return stolen
    else
        ability:setMsg(xi.msg.basic.STEAL_FAIL) -- Failed to steal
        action:setAnimation(target:getID(), 182)
    end

    -- Attempt Aura steal
    -- local effect = xi.effect.NONE
    if stolen == 0 and player:hasTrait(75) then
        local resist = applyResistanceAbility(player, target, xi.magic.ele.NONE, 0, 0)
        -- local effectStealSuccess = false
        if resist > 0.0625 then
            local auraStealChance = math.min(player:getMerit(xi.merit.AURA_STEAL), 95)
            if math.random(100) < auraStealChance then
                stolen = player:stealStatusEffect(target)
                if stolen ~= 0 then
                    ability:setMsg(xi.msg.basic.STEAL_EFFECT)
                end
            -- else
            --     effect = target:dispelStatusEffect()
            end

            -- Try for a second effect if we have the augment
            --[[
            TODO: This implementation is currently broken and inaccurate.  20% chance of a second aura being
            stolen per merit.

            if ((effect ~= xi.effect.NONE or stolen ~= 0) and player:getMod(xi.mod.AUGMENTS_AURA_STEAL) > 0) then
                if (math.random(100) < auraStealChance) then
                    if (stolenEffect2 ~= nil and math.random(100) < auraStealChance) then
                        player:stealStatusEffect(target)
                    else
                        target:dispelStatusEffect()
                    end
                end
            end
            ]]--
        end
    end

    return stolen
end

return ability_object
