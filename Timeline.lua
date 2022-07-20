---@class TimeFrame
---@field time number
---@field action function

---@class Timeline
local Timeline = class("Timeline")

local FRAME_RATE = 1/30

---@generic T
---@param context T
---@param timelineMgr timelineManager
function Timeline:ctor(context, timelineMgr, frameRate)
    self.frameRate = frameRate or FRAME_RATE
    self.context = context
    self.timelineMgr = timelineMgr
    self.isRunning = false
    self.isComplete = false
    self.totleTime = 0

    ---@type table<number, TimeFrame>
    self.frames = {}
end

function Timeline:Play()
    self.isRunning = true
    self.isComplete = false
    self.costTime = 0
    self.lastTime = 0
    self.index = 1

    self.timelineMgr:Add(self)
    return self
end

function Timeline:SetOnComplete2(obj, callback)
    return self:SetOnComplete(handler2(obj, callback))
end

function Timeline:SetOnComplete(callback)
    self.onCompleteCbk = callback
    return self
end

function Timeline:Pause()
    self.isRunning = false
end

function Timeline:Resume()
    self.isRunning = true
end

function Timeline:IsRunning()
    return self.isRunning
end

function Timeline:IsComplete()
    return self.isComplete
end

function Timeline:AppendFinishTime(delay)
    return self:AddAction(self.totleTime, delay, nil)
end

function Timeline:InsertHeadTime(delay)
    return self:InsertAction(0, delay, nil)
end

function Timeline:CombineOther(timeline)
    for index, frame in ipairs(timeline.frames) do
        self:Add(frame)
    end
    return self
end

--- 插入时间轴的所有动画，默认在最后插入
---@param timeline Timeline
---@param insertTime number|nil @nil在最后插入；<0 totleTime+time位置插入；>0 绝对位置插入
function Timeline:AppendOther(timeline, insertTime)
    local time = insertTime
    if time == nil then
        time = self.totleTime
    elseif time < 0 then
        time = math.max(0, self.totleTime + time)
    end

    for index, frame in ipairs(timeline.frames) do
        self:Add({time = frame.time + time, duration = frame.duration, action = frame.action})
    end
    return self
end

---@param time number|nil @nil在最后插入；<0 totleTime+time位置插入；>0 绝对位置插入
function Timeline:AddAction(time, duration, action)
    return self:Add({time = time, duration = duration, action = action})
end

function Timeline:InsertAction(time, duration, action)
    return self:Insert({time = time, duration = duration, action = action})
end

--- 插入帧
---@param frame TimeFrame
function Timeline:Add(frame)
    if frame.time == nil then
        frame.time = self.totleTime
    elseif frame.time < 0 then
        frame.time = math.max(0, self.totleTime + frame.time)
    end

    table.insert(self.frames, frame)
    self:SortFrames()
    self.totleTime = self:GetTotleTime()
    return self
end

--- 插入帧，并将原有的帧推后
---@param frame TimeFrame
function Timeline:Insert(frame)
    for _, value in ipairs(self.frames) do
        if value.time > frame.time then
            value.time = frame.time + frame.duration
        end
    end
    table.insert(self.frames, frame)
    self:SortFrames()
    self.totleTime = self:GetTotleTime()
    return self
end

function Timeline:SortFrames()
    table.sort(self.frames, function(a, b)
        return a.time < b.time
    end)
end

function Timeline:GetTotleTime()
    local max = 0
    for _, value in ipairs(self.frames) do
        max = math.max(value.time + value.duration, max)
    end
    return max
end

function Timeline:Update(curTime)
    if not self.isRunning then
        return
    end

    if self.lastTime == 0 then
        self.lastTime = curTime
    end
    
    local delta = curTime - self.lastTime
    if delta > self.frameRate then
        self.lastTime = curTime
        self:UpdateDelta(delta)
    end
end

function Timeline:UpdateDelta(delta)
    if not self.isRunning then
        return
    end

    self.costTime = self.costTime + delta

    local count = #self.frames
    for i = self.index, count do
        local frame = self.frames[i]
        if frame.time < self.costTime then
            if frame.action then
                frame.action(self.context)
            end
            self.index = self.index + 1
        end
    end
    if self.index > count and self.costTime >= self.totleTime then
        self.isRunning = false
        self.isComplete = true
        if self.onCompleteCbk then
            self.onCompleteCbk(self.context)
        end
    end
end

function Timeline:Dispose()
    self.frames = {}
    self.isRunning = false
    self.isComplete = true
end

return Timeline