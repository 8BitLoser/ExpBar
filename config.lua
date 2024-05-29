local bs = require("BeefStranger.functions")
local log = bs.getLog("ExpBar")
local db = log.debug
local configPath = "ExpBar"

---@class bsExpBar<K, V>: { [K]: V }
local defaults = {
    allowed = {},
    enabled = true,
    enableThreshold = false,
    logLevel = "WARN",
    threshold = 25,
    slim = true,
    keycode = {
        keyCode = tes3.scanCode.z,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
    refreshRate = 1.2,
    opacity = 1
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
    event.trigger("bsExpBar:RefreshUI")

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
        label = "Progress threshold for skill to appear on HUD",
        min = 0,
        max = 99,
        step = 1,
        jump = 10,
    })

    settings:createSlider({
        variable = mwse.mcm.createTableVariable{id = "refreshRate", table = config},
        label = "Update Rate in seconds (Values under 1 tend to be slower, 1.2 seems to be the sweetspot)",
        min = 0.8,
        max = 20,
        step = 0.01,
        jump = 0.10,
        decimalPlaces = 2
    })

    local opacity = settings:createSlider({
        variable = mwse.mcm.createTableVariable{id = "opacity", table = config},
        label = "Opacity of Menu",
        min = 0,
        max = 1,
        step = 0.01,
        jump = 0.10,
        decimalPlaces = 2,
        callback = function ()
            bs.msg("Slider Moved")
            event.trigger("bsExpBar:RefreshUI")
        end
    })

    settings:createButton{
        buttonText = "Preview",
        callback = function ()
            event.trigger("bsExpBar:RefreshUI")
        end
    }

    settings:createButton({
        buttonText = "Clear Whitelist",
        callback = function()
            -- table.clear(config)
            -- config = defaults
            config.allowed = {}

            event.trigger("bsExpBar:RefreshUI")

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
            event.trigger("bsExpBar:RefreshUI")
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
            event.trigger("bsExpBar:RefreshUI")
        end,
        inGameOnly = true
    })

    settings:createKeyBinder({
        label = "Assign Keybind",
        description = "Assign a new keybind to perform awesome tasks.",
        variable = mwse.mcm.createTableVariable{ id = "keycode", table = config },
        allowCombinations = false,
    })

    -- settings:createButton({
    --     buttonText = "Config Check",
    --     callback = function()
    --         bs.inspect(config)
    --     end,
    -- })

    bs.config.createLogLevel(settings, config, log.log)

    template:createExclusionsPage({
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