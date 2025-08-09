--- STEAMODDED HEADER
--- MOD_NAME: ravensSpeedEnforcer
--- MOD_ID: ravensSpeedEnforcer
--- MOD_AUTHOR: [raven]
--- MOD_DESCRIPTION: Enforces maximum 4x game speed
--- BADGE_COLOUR: D2AFFF
--- PREFIX: se
--- PRIORITY: 1000
--- VERSION: 1.0.0

-- Valid speeds only
local valid_speeds = {0.5, 1.0, 2.0, 3.0, 4.0}

-- Check if speed is valid
local function is_valid_speed(speed)
    for _, v in ipairs(valid_speeds) do
        if math.abs(speed - v) < 0.01 then return true end
    end
    return false
end

-- Clamp to nearest valid speed
local function clamp_speed(speed)
    local closest = valid_speeds[1]
    local min_diff = math.abs(speed - closest)
    
    for _, v in ipairs(valid_speeds) do
        local diff = math.abs(speed - v)
        if diff < min_diff then
            min_diff = diff
            closest = v
        end
    end
    return closest
end

-- Show message to player
local function show_message(text)
    if G and G.E_MANAGER and G.E_MANAGER.add_event then
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = function()
                attention_text({
                    text = text,
                    scale = 0.8, 
                    hold = 2,
                    backdrop_colour = G.C.SECONDARY_SET.Enhanced,
                    align = 'cm',
                    offset = {x = 0, y = -2.7},
                    major = G.play
                })
                return true
            end
        }))
    else
        print("[SE] " .. text)
    end
end

-- Main enforcement in update loop
local original_update = nil
local last_warning = 0

local function setup_enforcement()
    if G and G.update and not original_update then
        original_update = G.update
        G.update = function(self, dt)
            if G.SETTINGS and G.SETTINGS.GAMESPEED then
                local current = G.SETTINGS.GAMESPEED
                local now = love.timer.getTime()
                
                -- Cap at 4x maximum
                if current > 4.0 then
                    G.SETTINGS.GAMESPEED = 4.0
                    if now - last_warning > 2 then
                        show_message("Speed capped at 4.0x by SpeedEnforcer")
                        last_warning = now
                    end
                -- Force to valid speeds
                elseif not is_valid_speed(current) then
                    G.SETTINGS.GAMESPEED = clamp_speed(current)
                    if now - last_warning > 2 then
                        show_message("Speed enforced to " .. G.SETTINGS.GAMESPEED .. "x")
                        last_warning = now
                    end
                end
            end
            
            if original_update then
                return original_update(self, dt)
            end
        end
    end
end

-- Override set_speed if it exists
if G and G.set_speed then
    local original_set_speed = G.set_speed
    G.set_speed = function(speed)
        speed = math.min(speed, 4.0) -- Cap at 4x
        speed = clamp_speed(speed)   -- Force valid speeds
        return original_set_speed(speed)
    end
end

-- Setup after delay to ensure G is loaded
love.timer = love.timer or {}
if love.timer.getTime then
    local setup_time = love.timer.getTime() + 1
    love.update = love.update or function() end
    local original_love_update = love.update
    love.update = function(dt)
        if love.timer.getTime() > setup_time and not G._se_setup then
            setup_enforcement()
            G._se_setup = true
        end
        return original_love_update(dt)
    end
end

-- Console commands
if G and G.CONSOLE then
    G.CONSOLE.commands["se_toggle"] = function()
        return "SpeedEnforcer is always active"
    end
    
    G.CONSOLE.commands["se_status"] = function()
        local speed = G.SETTINGS and G.SETTINGS.GAMESPEED or "unknown"
        return "Current speed: " .. speed .. "x (max 4.0x enforced)"
    end
end

print("SpeedEnforcer loaded - Maximum 4x speed enforced!")
