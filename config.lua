local bs = require("BeefStranger.functions")
local log = bs.getLog("ExpBar")
local db = log.debug
local configPath = "ExpBar"

local allowedSkills = {
    [tes3.skill.acrobatics] = true,
    [tes3.skill.alchemy] = true,
    [tes3.skill.alteration] = true,
    [tes3.skill.armorer] = true,
    [tes3.skill.athletics] = true,
    [tes3.skill.axe] = true,
    [tes3.skill.block] = true,
    [tes3.skill.bluntWeapon] = true,
    [tes3.skill.conjuration] = true,
    [tes3.skill.destruction] = true,
    [tes3.skill.enchant] = true,
    [tes3.skill.handToHand] = true,
    [tes3.skill.heavyArmor] = true,
    [tes3.skill.illusion] = true,
    [tes3.skill.lightArmor] = true,
    [tes3.skill.longBlade] = true,
    [tes3.skill.marksman] = true,
    [tes3.skill.mediumArmor] = true,
    [tes3.skill.mercantile] = true,
    [tes3.skill.mysticism] = true,
    [tes3.skill.restoration] = true,
    [tes3.skill.security] = true,
    [tes3.skill.shortBlade] = true,
    [tes3.skill.sneak] = true,
    [tes3.skill.spear] = true,
    [tes3.skill.speechcraft] = true,
    [tes3.skill.unarmored] = true,
}
---@class bsExpBar<K, V>: { [K]: V }
local defaults = {
    allowed = allowedSkills,
    enableThreshold = false,
    threshold = 25,
    logLevel = "NONE",
    toggleKey = "v"
}
---@type bsExpBar
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = bs.config.template(configPath)
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })
    bs.config.yesNo(settings, "Enable skill threshold", "enableThreshold", config)

    settings:createSlider({
        variable = mwse.mcm.createTableVariable{id = "threshold", table = config},
        label = "Threshold to for skill to appear on HUD.",
        min = 0,
        max = 99,
        step = 1,
        jump = 10,
    })

    bs.config.createLogLevel(settings, config, log.log)

    template:register()
    
end
event.register(tes3.event.modConfigReady, registerModConfig)

return config