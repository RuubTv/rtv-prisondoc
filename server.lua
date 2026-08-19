local occupiedBeds = {} -- [bedIndex] = source
local playerBed    = {} -- [source] = bedIndex

----------------------------------------------------------
-- Ambulance / EMS on-duty detection
----------------------------------------------------------
local cachedESX = nil
local cachedQB  = nil

local function isAmbJob(name)
    local list = (Config.AmbulanceCheck and Config.AmbulanceCheck.jobNames) or {}
    for _, n in ipairs(list) do
        if name == n then return true end
    end
    return false
end

local function getESX()
    if cachedESX then return cachedESX end
    if GetResourceState('es_extended') ~= 'started' then return nil end

    local ok, obj = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if ok then
        cachedESX = obj
        return cachedESX
    end
    return nil
end

local function getQB()
    if cachedQB then return cachedQB end
    if GetResourceState('qb-core') ~= 'started' then return nil end

    local ok, obj = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if ok then
        cachedQB = obj
        return cachedQB
    end
    return nil
end

local function countESX()
    local ESX = getESX()
    if not ESX then return 0 end

    local count = 0

    if ESX.GetExtendedPlayers then
        local players = ESX.GetExtendedPlayers()
        for _, xPlayer in pairs(players) do
            local job = xPlayer and xPlayer.job
            if job and isAmbJob(job.name) then
                if job.onduty == nil or job.onduty == true then
                    count = count + 1
                end
            end
        end
        return count
    end

    if ESX.GetPlayers and ESX.GetPlayerFromId then
        local players = ESX.GetPlayers()
        for _, id in ipairs(players) do
            local xPlayer = ESX.GetPlayerFromId(id)
            local job = xPlayer and xPlayer.job
            if job and isAmbJob(job.name) then
                if job.onduty == nil or job.onduty == true then
                    count = count + 1
                end
            end
        end
    end

    return count
end

local function countQB()
    local QBCore = getQB()
    if not QBCore or not QBCore.Functions then return 0 end

    local count = 0
    local players = QBCore.Functions.GetPlayers()

    for _, id in ipairs(players) do
        local ply = QBCore.Functions.GetPlayer(id)
        local job = ply and ply.PlayerData and ply.PlayerData.job
        if job and isAmbJob(job.name) then
            if job.onduty == nil or job.onduty == true then
                count = count + 1
            end
        end
    end

    return count
end

local function countByExport()
    local ex = Config.AmbulanceCheck and Config.AmbulanceCheck.export
    if not ex or not ex.resource or not ex.name then return 0 end
    if GetResourceState(ex.resource) ~= 'started' then return 0 end

    local ok, val = pcall(function()
        return exports[ex.resource][ex.name]()
    end)

    if not ok then return 0 end

    if type(val) == 'number' then
        return val
    elseif type(val) == 'boolean' then
        return val and 1 or 0
    end

    return 0
end

local function getOnDutyAmbCount()
    local cfg = Config.AmbulanceCheck
    if not cfg or not cfg.enabled then return 0 end

    local mode = cfg.mode or 'auto'
    if mode == 'none' then return 0 end

    if mode == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            mode = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            mode = 'qb'
        elseif cfg.export and cfg.export.resource and cfg.export.name
            and GetResourceState(cfg.export.resource) == 'started' then
            mode = 'export'
        else
            mode = 'none'
        end
    end

    if mode == 'esx' then
        return countESX()
    elseif mode == 'qb' then
        return countQB()
    elseif mode == 'export' then
        return countByExport()
    end

    return 0
end

----------------------------------------------------------
-- Bed helpers
----------------------------------------------------------
local function findFreeBed()
    for i = 1, #Config.Beds do
        if not occupiedBeds[i] then
            return i
        end
    end
    return nil
end

local function releaseBed(src)
    local bedIndex = playerBed[src]
    if bedIndex then
        if occupiedBeds[bedIndex] == src then
            occupiedBeds[bedIndex] = nil
        end
        playerBed[src] = nil
    end
end

----------------------------------------------------------
-- Events
----------------------------------------------------------
RegisterNetEvent('rtv_prisonmed:checkIn', function()
    local src = source

    -- EMS on-duty check
    local ambCfg = Config.AmbulanceCheck
    if ambCfg and ambCfg.enabled and ambCfg.blockIfOnDuty ~= false then
        local onDuty = getOnDutyAmbCount()
        local min = ambCfg.minOnDuty or 1
        if onDuty >= min then
            TriggerClientEvent('rtv_prisonmed:ambulanceOnDuty', src, onDuty)
            return
        end
    end

    -- Already assigned a bed?
    if playerBed[src] then return end

    local bedIndex = findFreeBed()
    if not bedIndex then
        TriggerClientEvent('rtv_prisonmed:noBeds', src)
        return
    end

    occupiedBeds[bedIndex] = src
    playerBed[src] = bedIndex

    local bedData = Config.Beds[bedIndex]
    TriggerClientEvent('rtv_prisonmed:assignBed', src, bedIndex, bedData, Config.TreatmentTime)

    SetTimeout((Config.TreatmentTime or 20) * 1000, function()
        if playerBed[src] == bedIndex and occupiedBeds[bedIndex] == src then
            -- Auto finish: revive via tk_ambulancejob and let client stand up
            exports.tk_ambulancejob:revive(src) -- change this if you use a different ambulance resource or revive export
            releaseBed(src)
            TriggerClientEvent('rtv_prisonmed:finishAck', src)
        end
    end)
end)

RegisterNetEvent('rtv_prisonmed:forceRelease', function()
    local src = source
    releaseBed(src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    releaseBed(src)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    occupiedBeds = {}
    playerBed = {}
end)
