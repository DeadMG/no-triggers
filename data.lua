function filter(list, predicate)
    local result = {}
    for _, value in ipairs(list) do
        if predicate(value) then table.insert(result, value) end
    end
    return result
end

function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
    return false
end

function update_trigger(trigger, name, new)
    if not trigger then return false end
    if trigger and trigger.type == "research" and trigger.technology == name then
        if new then
            trigger.technology = new
        else
            return true
        end
    end
    
    if trigger and (trigger.type == "and" or trigger.type == "sequence") then
        for _, condition in ipairs(trigger.triggers) do
            if (update_trigger(condition, name, new)) then return true end
        end
    end
    
    if trigger and trigger.type == "or" then
        local result = true
        for _, condition in ipairs(trigger.triggers) do
            if (not update_trigger(condition, name, new)) then result = false end
        end
        return result
    end
    
    return false
end

function remove_technology(name, new)
    for _, effect in ipairs(data.raw.technology[name].effects or {}) do
        if not new and effect.type == 'unlock-recipe' then
            data.raw.recipe[effect.recipe].enabled = true
        else
            table.insert(data.raw.technology[new].effects, effect)
        end
    end
    
    for _, shortcut in pairs(data.raw.shortcut) do
        if shortcut.technology_to_unlock == name then
            if new then
                shortcut.technology_to_unlock = new
            else
                shortcut.technology_to_unlock = nil
                shortcut.unavailable_until_unlocked = false
            end
        end
    end
    
    for _, tech in pairs(data.raw.technology) do
        if tech.prerequisites then
            local add = contains(tech.prerequisites, name)
            tech.prerequisites = filter(tech.prerequisites, function(pre) return pre ~= name end)
            if add and new then
                table.insert(tech.prerequisites, new)
            end
        end
    end
    
    local remove_achievements = {}
    for key, achievement in pairs(data.raw["research-achievement"]) do
        if achievement.technology == name then
            if new then
                achievement.technology = new
            else
                table.insert(remove_achievements, key)
            end
        end
    end
    
    for _, name in ipairs(remove_achievements) do
        data.raw["research-achievement"][name] = nil
    end
    
    local remove_tips = {}
    for key, tip in pairs(data.raw["tips-and-tricks-item"]) do
        if (update_trigger(tip.trigger, name, new)) then
            table.insert(remove_tips, key)
        end
        update_trigger(tip.skip_trigger, name, new)
    end
    for _, name in ipairs(remove_tips) do
        data.raw["tips-and-tricks-item"][name] = nil
    end

    data.raw["technology"][name] = nil
end

function replace_trigger_with_cost(name, cost)
    data.raw.technology[name].research_trigger = nil
    data.raw.technology[name].unit = cost
end

-- Nauvis
remove_technology("steam-power")
remove_technology("automation-science-pack")
remove_technology("electronics")

replace_trigger_with_cost("steel-axe", {
    count = 50,
    time = 20,
    ingredients = {
        { "automation-science-pack", 1 }
    }
})

remove_technology("oil-processing", "oil-gathering")
remove_technology("uranium-processing", "uranium-mining")

if mods["space-age"] then
    -- Space
    remove_technology("space-platform", "rocket-silo")
    remove_technology("space-science-pack", "rocket-silo")
    
    -- Gleba
    remove_technology("agriculture", "planet-discovery-gleba")
    remove_technology("yumako", "planet-discovery-gleba")
    remove_technology("jellynut", "planet-discovery-gleba")
    remove_technology("heating-tower", "planet-discovery-gleba")
    remove_technology("biochamber", "planet-discovery-gleba")
    remove_technology("artificial-soil", "planet-discovery-gleba")
    remove_technology("bioflux", "planet-discovery-gleba")
    remove_technology("bioflux-processing", "planet-discovery-gleba")
    remove_technology("bacteria-cultivation", "planet-discovery-gleba")
    remove_technology("agricultural-science-pack", "planet-discovery-gleba")
    remove_technology("biter-egg-handling", "captivity")
    
    -- Vulcanus
    remove_technology("calcite-processing", "planet-discovery-vulcanus")
    remove_technology("tungsten-carbide", "planet-discovery-vulcanus")
    remove_technology("foundry", "planet-discovery-vulcanus")
    remove_technology("big-mining-drill", "planet-discovery-vulcanus")
    remove_technology("tungsten-steel", "planet-discovery-vulcanus")
    remove_technology("metallurgic-science-pack", "planet-discovery-vulcanus")
    
    -- Fulgora
    remove_technology("recycling", "planet-discovery-fulgora")
    remove_technology("holmium-processing", "planet-discovery-fulgora")
    remove_technology("electromagnetic-plant", "planet-discovery-fulgora")
    remove_technology("electromagnetic-science-pack", "planet-discovery-fulgora")
    
    -- Aquilo
    remove_technology("lithium-processing", "planet-discovery-aquilo")
    remove_technology("cryogenic-plant", "planet-discovery-aquilo")
    remove_technology("cryogenic-science-pack", "planet-discovery-aquilo")    
else
    remove_technology("space-science-pack", "rocket-silo")
end