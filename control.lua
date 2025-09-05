quality_levels = {"normal", "uncommon", "rare", "epic", "legendary"}
inventory_type_table = {
    ["furnace"] = defines.inventory.crafter_modules,
    ["assembling-machine"] = defines.inventory.crafter_modules,
    ["lab"] = defines.inventory.lab_modules,
    ["mining-drill"] = defines.inventory.mining_drill_modules,
    ["rocket-silo"] = defines.inventory.crafter_modules,
    ["beacon"] = defines.inventory.beacon_modules,
}
quality_table = {
    ["normal"] = 1,
    ["uncommon"] = 2,
    ["rare"] = 3,
    ["epic"] = 4,
    ["legendary"] = 5
}
module_table = {
    ["speed-module"] = 1,
    ["speed-module-2"] = 2,
    ["speed-module-3"] = 3,
    ["efficiency-module"] = 1,
    ["efficiency-module-2"] = 2,
    ["efficiency-module-3"] = 3,
    ["quality-module"] = 1,
    ["quality-module-2"] = 2,
    ["quality-module-3"] = 3,
    ["productivity-module"] = 1,
    ["productivity-module-2"] = 2,
    ["productivity-module-3"] = 3
}
entities_table = {
    ["speed-module"] = {
        ["entity_max_name"] = "speed_module_max_quality"
    },
    ["speed-module-2"] = {
        ["entity_max_name"] = "speed_module_max_quality",
        ["to_nil"] = {"speed-module"}
    },
    ["speed-module-3"] = {
        ["entity_max_name"] = "speed_module_max_quality",
        ["to_nil"] = {"speed-module", "speed-module-2"}
    },
    ["productivity-module"] = {
        ["entity_max_name"] = "productivity_module_max_quality"
    },
    ["productivity-module-2"] = {
        ["entity_max_name"] = "productivity_module_max_quality",
        ["to_nil"] = {"productivity-module"}
    },
    ["productivity-module-3"] = {
        ["entity_max_name"] = "productivity_module_max_quality",
        ["to_nil"] = {"productivity-module", "productivity-module-2"}
    },
    ["efficiency-module"] = {
        ["entity_max_name"] = "efficiency_module_max_quality"
    },
    ["efficiency-module-2"] = {
        ["entity_max_name"] = "efficiency_module_max_quality",
        ["to_nil"] = {"efficiency-module"}
    },
    ["efficiency-module-3"] = {
        ["entity_max_name"] = "efficiency_module_max_quality",
        ["to_nil"] = {"efficiency-module", "efficiency-module-2"}
    },
    ["quality-module"] = {
        ["entity_max_name"] = "quality_module_max_quality"
    },
    ["quality-module-2"] = {
        ["entity_max_name"] = "quality_module_max_quality",
        ["to_nil"] = {"quality-module"}
    },
    ["quality-module-3"] = {
        ["entity_max_name"] = "quality_module_max_quality",
        ["to_nil"] = {"quality-module", "quality-module-2"}
    },
}
upgrade_table = upgrade_table or {
            ["speed_module_max_quality"] = {
                ["speed-module"] = "normal"
            },
            ["efficiency_module_max_quality"] = {
                ["efficiency-module"] = "normal"
            },
            ["quality_module_max_quality"] = {
                ["quality-module"] = "normal"
            },
            ["productivity_module_max_quality"] = {
                ["productivity-module"] = "normal"
            }
        }
upgrade_entities = {"big-mining-drill", "electric-mining-drill", "assembling-machine-1", "assembling-machine-2", "assembling-machine-3", "lab", "beacon", "centrifuge", "oil-refinery", "chemical-plant", "electromagnetic-plant", "cryogenic-plant", "rocket-silo"}
index = 1
script.on_event(defines.events.on_tick, function(event)
    local surfaces = game.surfaces
    for _, surface in pairs(surfaces) do
        local param_name = upgrade_entities[index]
        local entities = surface.find_entities_filtered{name = param_name}
        for _, entity in ipairs(entities) do
            local module_inventory = entity.get_module_inventory()
            local inventory_define = inventory_type_table[entity.type]
            local insert_plan = {}
            local removal_plan = {}

            if not entity.item_request_proxy then
                local update_needed = {}
                for i = 1, #module_inventory do
                    local stack = module_inventory[i]
                    if stack.valid_for_read then
                        local current_name = stack.name
                        local current_quality = stack.quality.name
                        local entiry_max_name = entities_table[current_name]["entity_max_name"]
                        local entity_name, entity_quality = next(upgrade_table[entiry_max_name])
                        local new_name_value = module_table[entity_name] or 1
                        local new_quality_value = quality_table[entity_quality] or 1
                        local old_name_value = module_table[current_name] or 1
                        local old_quality_value = quality_table[current_quality] or 1


                        if new_name_value == old_name_value and old_quality_value == new_quality_value then
                            update_needed[i] = false
                        end
                        if new_name_value == old_name_value and old_quality_value < new_quality_value then
                            update_needed[i] = true
                            removal_plan[i] = createBlueprintInsertPlan({ name = current_name, quality = current_quality }, i, inventory_define)
                            insert_plan[i] = createBlueprintInsertPlan({ name = current_name, quality = entity_quality }, i, inventory_define)
                        end
                        if new_name_value > old_name_value and old_quality_value < new_quality_value then
                            update_needed[i] = true
                            removal_plan[i] = createBlueprintInsertPlan({ name = entity_name, quality = entity_quality }, i, inventory_define)
                            insert_plan[i] = createBlueprintInsertPlan({ name = entity_name, quality = entity_quality }, i, inventory_define)
                        end
                        if new_name_value > old_name_value and old_quality_value == new_quality_value then
                            update_needed[i] = true
                            removal_plan[i] = createBlueprintInsertPlan({ name = entity_name, quality = entity_quality }, i, inventory_define)
                            insert_plan[i] = createBlueprintInsertPlan({ name = entity_name, quality = entity_quality }, i, inventory_define)
                        end
                        if new_name_value > old_name_value and old_quality_value > new_quality_value then
                            update_needed[i] = true
                            removal_plan[i] = createBlueprintInsertPlan({ name = current_name, quality = current_quality }, i, inventory_define)
                            insert_plan[i] = createBlueprintInsertPlan({ name = entity_name, quality = entity_quality }, i, inventory_define)
                        end
                    end

                end
                local create_info = {
                    name = "item-request-proxy",
                    position = entity.position,
                    force = entity.force,
                    target = entity,
                    modules = insert_plan,
                    removal_plan = removal_plan,
                    raise_built = true
                }
                if array_contains_word(update_needed, true) then
                    entity.surface.create_entity(create_info)
                end
            end
        end



        index = index + 1
        if index > #upgrade_entities then index = 1 end
        if event.tick % 300 == 0 then
            local logistic_containers = surface.find_entities_filtered{type = "logistic-container"}
            for _, storage in ipairs(logistic_containers) do
                local inv = storage.get_inventory(defines.inventory.chest)
                if inv and inv.valid then
                    local contents = inv.get_contents()
                    for _, v in pairs(contents) do
                        if entities_table[v.name] then
                            set_upgrade_table(v, entities_table[v.name].entity_max_name, entities_table[v.name].to_nil)
                        end
                    end
                end
            end
        end
    end
end)

function set_upgrade_table(v, entity_max_name, to_nil)
    upgrade_table[entity_max_name][v.name] = upgrade_table[entity_max_name][v.name] or v.quality
    if to_nil then
        for _, nilled in pairs(to_nil) do
            upgrade_table[entity_max_name][nilled] = nil
        end
    end
    change_upgrade_table(v, entity_max_name)
end

function change_upgrade_table(v, entity_max_name)
    if v.quality == "uncommon" and not array_contains_word({"rare", "epic", "legendary"}, upgrade_table[entity_max_name][v.name]) then
        upgrade_table[entity_max_name][v.name] = v.quality
    end
    if v.quality == "rare" and not array_contains_word({ "epic", "legendary"}, upgrade_table[entity_max_name][v.name]) then
        upgrade_table[entity_max_name][v.name] = v.quality
    end
    if v.quality == "epic" and not array_contains_word({"legendary"}, upgrade_table[entity_max_name][v.name]) then
        upgrade_table[entity_max_name][v.name] = v.quality
    end
    if v.quality == "legendary" then
        upgrade_table[entity_max_name][v.name] = v.quality
    end
end

function array_contains_word(array, word)
    for i = 1, #array do
        if array[i] == word then
            return true
        end
    end
    return false
end

function createBlueprintInsertPlan(module, stack_index, inventory_define)
    return {
        id = module,
        items = {
            in_inventory = {{
                                inventory = inventory_define,
                                stack = stack_index - 1,
                                count = 1,
                            }}
        }
    }
end