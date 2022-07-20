# Timeline
- A simple way to manager the animation for game independently, especially for turn-based game. This library can be translated into any program language, and be embeded into any game engine.

- Here is a piece of code example that is a card game

```
function CardPlayer:Main()
    cardActions:AppendOther(self:PlayToGraveAction())  -- append other timeline
    cardActions:AppendOther(self:StartToDrawCards())
    cardActions:AppendOther(self:PlayMonstersAction())
    cardActions:AddAction(nil, 0, function() self.context.cardTable:LockTable(false) end)
    cardActions:SetOnComplete2(self, self.CheckGameEnd)
    cardActions:Play()
end

function CardPlayer:PlayToGraveAction()
    local toGraveCards = self.context.dataProxy:GetToGraveCards()
    local actions = self.context.timelineManager:CreateTimeline()

    for index, cardDataId in ipairs(toGraveCards) do
        local card = self.context.handCard:GetCardByDataId(cardDataId)
        local recyleAni = self.context.cardTomb:MoveHandCardToTomb(card)
        actions:AppendOther(recyleAni, (index - 1) * 0.3)
    end

    local newMonsterGroup1 = self.context.dataProxy:GetMonsterGroup1()
    if newMonsterGroup1 and not table.isEmpty(newMonsterGroup1) and newMonsterGroup1.monsterGroup then
        local groupAni = self:PlayNextMonsterGroup(newMonsterGroup1)
        actions:AppendOther(groupAni)
    end

    return actions
end


function CardPlayer:PlayNextMonsterGroup(newMonsterGroup)
    local actions = self.context.timelineManager:CreateTimeline()

    local delay = 2
    actions:AddAction(nil, delay, function()
        self.context.uiProxy:ShowNewMonsterGroup(newMonsterGroup.monsterGroup)
    end)

    for index, info in ipairs(newMonsterGroup.monsters or {}) do
        local monster = self.context.monsters:CreateMonster(info)
        local y = monster.displayObject.y
        monster.displayObject.y = y - 400

        actions:AddAction(delay + index * 0.2, 0.2, function()
            monster.tween:TweenMoveY(y, 0.2) -- can use any animation but not just 'tween'
        end)
    end

    return actions
end

```
