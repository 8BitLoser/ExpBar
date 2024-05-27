local bs = require("BeefStranger.functions")
local config = require("BeefStranger.ExpBar.config")
local log = bs.getLog("ExpBar")
local db = log.debug

event.register("initialized", function ()
        print("[MWSE:ExpBar] initialized")
        bs.sound.register()
end)

local lastUpdate = 0 --Gets changed to current time
local cooldown = 1 --The cooldown for exerciseSkill
local activeSkillBar = {} --Stores a list of active expBars
local skillProgressDebug = {} --Debug table to inspect everything in player.skillProgress
local skillUpdates = {} --Table to mark a skill as needing an update
local lastProgress = {}

---@return table skillOutput Table with a list of all allowed skills and their name/level/progress
local function getPlayerSkills()
    db("getPlayerSkills triggered")

    local player = tes3.mobilePlayer
    local class = player.object.class

    ---Get all skill bonuses from gmst
    local majorBonus = tes3.findGMST("fMajorSkillBonus").value
    local minorBonus = tes3.findGMST("fMinorSkillBonus").value
    local miscBonus = tes3.findGMST("fMiscSkillBonus").value
    local specialBonus = tes3.findGMST("fSpecialSkillBonus").value
    

    ---@class SkillInfo
    ---@field skillName string?  -- The name of the skill
    ---@field skillLevel number?  -- The level of the skill
    ---@field normalizedProgress number?  -- The normalized progress of the skill

    ---@type SkillInfo
    local skillOutput = {}

    for skillIndex, progress in ipairs(player.skillProgress) do
        local skillId = skillIndex - 1  -- Adjust for 0-based skill indices
        local skillName = tes3.skillName[skillId]
        local skillLevel = player.skills[skillId + 1].base  -- Getting current skill level
        local skillObj = tes3.getSkill(skillId)

        -----------------------------------
        skillProgressDebug[skillIndex] = {
            skillIndex = skillIndex,
            progress = progress,
            skillName = skillName,
            skillLevel = skillLevel,
            skillId = skillId
        }
        -----------------------------------
        ---Get skills specialization
        local special = skillObj.specialization
        ---Get skillTypes
        local skillType = tes3.mobilePlayer:getSkillStatistic(skillId).type

        if config.allowed[skillId] then
            local progressRequirement = 1 + skillLevel
            -- Adjust progress requirement based on skill type and bonuses
            if skillType == tes3.skillType.major then
                progressRequirement = progressRequirement * majorBonus
            elseif skillType == tes3.skillType.minor then
                progressRequirement = progressRequirement * minorBonus
            elseif skillType == tes3.skillType.misc then
                progressRequirement = progressRequirement * miscBonus
            end

            if special == class.specialization then
                progressRequirement = progressRequirement * specialBonus
            end

            local normalizedProgress = (progress / progressRequirement) * 100
            
            skillOutput[skillId] = {
                skillName = skillName,
                skillLevel = skillLevel,
                normalizedProgress = normalizedProgress,
            }
        end
    end
    return skillOutput
end

local function saveMenuPosition(menu)
    if not tes3.player.data.expMenuPos then
        tes3.player.data.expMenuPos = {}
    end
    tes3.player.data.expMenuPos.x = menu.positionX
    tes3.player.data.expMenuPos.y = menu.positionY
end

local function restoreMenuPosition(menu)
    if tes3.player.data.expMenuPos then
        menu.positionX = tes3.player.data.expMenuPos.x
        menu.positionY = tes3.player.data.expMenuPos.y
    end
end


local function expBarUI()
    local skillInfo = getPlayerSkills()
    local expBarID = tes3ui.registerID("bsExpBar")

    local expMenu = tes3ui.createMenu{ id = expBarID, fixedFrame = false, dragFrame = true}
        expMenu.text = "Experience"
        expMenu.positionX = -912
        expMenu.positionY = 512
        expMenu.minWidth = 200
        expMenu.minHeight = 100
        expMenu.width = 300
        expMenu.height = 400
        expMenu.autoWidth = false
        expMenu.autoHeight = false
        expMenu.flowDirection = tes3.flowDirection.topToBottom

        local scroller = expMenu:createVerticalScrollPane{id = "scroller"}

        restoreMenuPosition(expMenu)
    ---------------------------------------------------------------------------------------
    for skillID, info in ipairs(skillInfo) do
        local name = info.skillName
        local level = info.skillLevel
        local progress = info.normalizedProgress

        if progress > config.threshold or config.enableThreshold == false then
            local skillLabel = scroller:createLabel { id = name .. " Label", text = name .. " - " .. level }
            skillLabel.borderBottom = 4
            --------------------------------------------------------------------------------
            local bar = scroller:createFillBar{id = name.." FillBar", current = progress, max = 100}
                bar.borderBottom = 3
                bar.widthProportional = 1
                activeSkillBar[name] = bar
        end
    end
    expMenu:updateLayout()
end


local function updateFillBar(skillName, newProgress)
    local menu = tes3ui.findMenu("bsExpBar")
    local bar = activeSkillBar[skillName]

    if bar then
        if menu then
            local fillBar = menu:findChild(skillName.." FillBar")
            if fillBar then
                fillBar.widget.current = newProgress
                menu:updateLayout()
            else
                db("No fillbar destroying menu")
                menu:destroy()
                expBarUI()
            end
        end
    end
end

local function skillUpdate()
    if next(skillUpdates) == nil then return end --Bail if table is empty

    local skillOutput = getPlayerSkills()
    for skillID, _ in pairs(skillOutput) do --Get all skillID's in skillOutput
        local info = skillOutput[skillID]
        if info then
            local progress = info.normalizedProgress
            local last = lastProgress[skillID] or 0
            if (progress > config.threshold or config.threshold == false) or
            progress - last >= 1 then
                updateFillBar(info.skillName, progress)
            end
            lastProgress[skillID] = progress
        end
    end
    skillUpdates = {} --Clear skillUpdates table
end

---@param e exerciseSkillEventData
event.register("exerciseSkill", function (e)
    skillUpdates[e.skill] = true
    local currentTime = os.clock()
    if currentTime - lastUpdate >= cooldown then
        lastUpdate = currentTime
        skillUpdate()
    end
end)

event.register("skillRaised", function (e)
    local menu = tes3ui.findMenu(tes3ui.registerID("bsExpBar"))
    if menu then
        menu:destroy() -- Destroy then remake expBar on skill level gain
    end
    expBarUI()
end)


bs.keyUp("z", function ()
    local menu = tes3ui.findMenu("bsExpBar")
    if menu then
        saveMenuPosition(menu)
        menu:destroy()
    else
        expBarUI()
    end
end)