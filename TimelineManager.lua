
local Timeline = require("Fight.Core.Timeline.Timeline")

---@class timelineManager
local TimelineManager = class("TimelineManager")

---@generic T
---@param context T
function TimelineManager:ctor(context)
    self.context = context
    ---@type table<number, Timeline>
    self.timelines = {}
end

function TimelineManager:CreateTimeline()
    local timeline = Timeline.new(self.context, self)
    return timeline
end

function TimelineManager:Add(timeline)
    assert(not timeline.hasAdd, "Add Twice?")

    timeline.hasAdd = true
    table.insert(self.timelines, timeline)
end

function TimelineManager:Update(curTime)
    for i = #self.timelines, 1, -1 do
        local timeline = self.timelines[i]
        timeline:Update(curTime)
        if timeline:IsComplete() then
            table.remove(self.timelines, i)
            timeline:Dispose()
        end
    end
end

function TimelineManager:Dispose()
    for index, value in ipairs(self.timelines) do
        value:Dispose()
    end
    self.timelines = {}
end


return TimelineManager