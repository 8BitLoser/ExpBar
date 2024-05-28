local bs = require("BeefStranger.functions")
local log = bs.getLog("ExpBar")
local db = log.debug
local configPath = "ExpBar"

---@class bsExpBar<K, V>: { [K]: V }
local defaults = {
    allowed = {},
    enabled = true,
    enableThreshold = false,
    logLevel = "NONE",
    threshold = 25,
    slim = true,
    keycode = {
        keyCode = tes3.scanCode.z,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    }
}


---@class bsExpBar
local config = mwse.loadConfig(configPath, defaults)


local function getSkillList()
    local skillList = {}
    local skillMajor = {}
    local skillMinor = {}
    for name, id in pairs(tes3.skill) do
        table.insert(skillList, tes3.skillName[id])

        if tes3.mobilePlayer then
            local skillType = tes3.mobilePlayer:getSkillStatistic(id).type

            if skillType == tes3.skillType.major then
                table.insert(skillMajor, tes3.skillName[id])
            elseif skillType == tes3.skillType.minor then
                table.insert(skillMinor, tes3.skillName[id])
            end
        end

    end
    bs.inspect(skillList)

    table.sort(skillList)
    return skillList, skillMajor, skillMinor
end


local function registerModConfig()
    local template = bs.config.template(configPath)
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    bs.config.yesNo(settings, "Enable skill threshold", "enableThreshold", config)

    bs.config.yesNo(settings, "Enable Mod", "enabled", config)

    bs.config.yesNo(settings, "Slim UI mode", "slim", config)

    settings:createSlider({
        variable = mwse.mcm.createTableVariable{id = "threshold", table = config},
        label = "Progress threshold for skill to appear on HUD.",
        min = 0,
        max = 99,
        step = 1,
        jump = 10,
    })

    settings:createButton({
        buttonText = "Clear Whitelist",
        callback = function()
            -- table.clear(config)
            -- config = defaults
            config.allowed = {}
            -- -- config = {}
            -- config.keybind = nil
        end,
    })

    settings:createButton({
        buttonText = "Select Major Skills",
        callback = function()
            local _, major = getSkillList()
            bs.inspect(major)
            for _, skill in ipairs(major) do
                config.allowed[skill] = true
            end
        end,
        inGameOnly = true
    })

    settings:createButton({
        buttonText = "Select Minor Skills",
        callback = function()
            local _, _, minor = getSkillList()
            bs.inspect(minor)
            for _, skill in ipairs(minor) do
                config.allowed[skill] = true
            end
        end,
        inGameOnly = true
    })

    settings:createKeyBinder({
        label = "Assign Keybind",
        description = "Assign a new keybind to perform awesome tasks.",
        variable = mwse.mcm.createTableVariable{ id = "keycode", table = config },
        allowCombinations = false,
        
    })

    settings:createButton({
        buttonText = "Config Check",
        callback = function()
            bs.inspect(config)
        end,
    })

    bs.config.createLogLevel(settings, config, log.log)

    local exclude = template:createExclusionsPage({
        label = "Allowed Skills",
        description = "Manage the list of allowed skills.",
        leftListLabel = "Allowed Skills",
        rightListLabel = "Excluded Skills",
        variable = mwse.mcm.createTableVariable{ id = "allowed", table = config},
        filters = { { label = "Skills", callback = getSkillList }, },
    })

    template:register()

end
event.register(tes3.event.modConfigReady, registerModConfig)

return config