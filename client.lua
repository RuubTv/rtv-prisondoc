local inTreatment = false

local assignedBed = nil
local currentBedData = nil

local showingText = false
local lastInteract = 0
local isCheckingIn = false

local checkinPoint = nil
local targetZoneId = nil

----------------------------------------------------------
-- Helpers
----------------------------------------------------------
local function notify(title, description, ntype)
    lib.notify({
        title = title or 'Prison Doctor',
        description = description or '',
        type = ntype or 'inform'
    })
end

local function loadAnimDict(dict)
    if not dict then return false end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 200 do
        Wait(10)
        timeout = timeout + 1
    end
    return HasAnimDictLoaded(dict)
end

local function playOnceAnim(cfg)
    if not cfg or not cfg.dict or not cfg.name then return end

    local ped = PlayerPedId()

    if loadAnimDict(cfg.dict) then
        TaskPlayAnim(
            ped,
            cfg.dict,
            cfg.name,
            8.0, -8.0,
            -1,
            cfg.flag or 0,
            0,
            false, false, false
        )
        Wait(cfg.durationMs or 1000)
        StopAnimTask(ped, cfg.dict, cfg.name, 2.0)
    end
end

local function playBedAnim()
    local cfg = Config.BedAnim
    if not cfg or not cfg.enabled then return end

    local ped = PlayerPedId()
    if loadAnimDict(cfg.dict) then
        TaskPlayAnim(
            ped,
            cfg.dict,
            cfg.name,
            8.0, -8.0,
            -1,
            cfg.flag or 1,
            0,
            false, false, false
        )
    end
end

-- Soft attempt to lay the player down only if they are alive
local function gentleLayDownIfAlive()
    local ped = PlayerPedId()

    -- Do not touch player if they are in a down / ragdoll / dying state
    if IsPedDeadOrDying(ped, true) or IsPedRagdoll(ped) then
        return
    end

    if not Config.BedAnim or not Config.BedAnim.enabled then
        return
    end

    -- A few attempts to start the bed animation, then stop trying
    for _ = 1, 6 do
        playBedAnim()
        Wait(250)

        if IsEntityPlayingAnim(ped, Config.BedAnim.dict, Config.BedAnim.name, 3) then
            break
        end
    end
end

local function stopBedAnim()
    local ped = PlayerPedId()

    if Config.BedAnim and Config.BedAnim.dict and Config.BedAnim.name then
        StopAnimTask(ped, Config.BedAnim.dict, Config.BedAnim.name, 2.0)
    end

    ClearPedTasks(ped)
end

local function playGetUp()
    local cfg = Config.GetUpAnim
    if not cfg or not cfg.enabled then return end
    playOnceAnim(cfg)
end

----------------------------------------------------------
-- Control lock while in treatment
----------------------------------------------------------
CreateThread(function()
    while true do
        if inTreatment then
            -- movement
            DisableControlAction(0, 30, true) -- left/right
            DisableControlAction(0, 31, true) -- fwd/back
            DisableControlAction(0, 21, true) -- sprint
            DisableControlAction(0, 22, true) -- jump

            -- interaction / combat / vehicle
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 38, true) -- E

            Wait(0)
        else
            Wait(500)
        end
    end
end)

----------------------------------------------------------
-- Shared check-in logic
----------------------------------------------------------
local function doCheckIn()
    if isCheckingIn or inTreatment then return end
    isCheckingIn = true

    -- Notepad / clipboard style animation on check-in
    playOnceAnim(Config.CheckInAnim)
    ClearPedTasks(PlayerPedId())

    TriggerServerEvent('rtv_prisonmed:checkIn')

    Wait(300)
    isCheckingIn = false
end

----------------------------------------------------------
-- TextUI mode using ox_lib points
----------------------------------------------------------
local function setupTextUIMode()
    checkinPoint = lib.points.new({
        coords = Config.CheckIn.coords,
        distance = (Config.CheckIn.radius or 1.5) + 5.0
    })

    function checkinPoint:nearby()
        if inTreatment then
            if showingText then
                showingText = false
                lib.hideTextUI()
            end
            return
        end

        local ped = PlayerPedId()
        local dist = #(GetEntityCoords(ped) - Config.CheckIn.coords)

        if dist <= (Config.CheckIn.radius or 1.5) then
            if not showingText then
                showingText = true
                lib.showTextUI(Config.CheckIn.label or '[E] Check in')
            end

            if IsControlJustReleased(0, 38) then
                local now = GetGameTimer()
                if now - lastInteract > 1000 then
                    lastInteract = now
                    doCheckIn()
                end
            end
        else
            if showingText then
                showingText = false
                lib.hideTextUI()
            end
        end
    end

    function checkinPoint:onExit()
        if showingText then
            showingText = false
            lib.hideTextUI()
        end
    end
end

----------------------------------------------------------
-- ox_target mode
----------------------------------------------------------
local function setupTargetMode()
    local pos = Config.CheckIn.targetCoords or Config.CheckIn.coords
    local rad = Config.CheckIn.targetRadius or Config.CheckIn.radius or 1.5

    targetZoneId = exports.ox_target:addSphereZone({
        coords = pos,
        radius = rad,
        debug = false,
        options = {
            {
                name = 'rtv_prisonmed_checkin',
                icon = Config.CheckIn.targetIcon or 'fa-solid fa-user-doctor',
                label = Config.CheckIn.targetLabel or 'Check in at prison doctor',
                onSelect = function(data)
                    doCheckIn()
                end
            }
        }
    })
end

----------------------------------------------------------
-- Init: pick interaction mode from config
----------------------------------------------------------
CreateThread(function()
    if Config.CheckIn.useOxTarget then
        setupTargetMode()
    else
        setupTextUIMode()
    end
end)

----------------------------------------------------------
-- Server events
----------------------------------------------------------
RegisterNetEvent('rtv_prisonmed:noBeds', function()
    notify('No beds available', 'Please try again in a moment.', 'error')
end)

RegisterNetEvent('rtv_prisonmed:ambulanceOnDuty', function(count)
    local cfg = Config.AmbulanceCheck or {}
    local msg = cfg.denyMessage or 'There are EMS on duty. Please use regular medical services.'

    if msg:find("%%s") then
        msg = msg:format(count or 0)
    end

    notify(cfg.denyTitle or 'Prison Doctor', msg, 'error')
end)

RegisterNetEvent('rtv_prisonmed:assignBed', function(bedIndex, bedData, treatmentTime)
    if inTreatment then return end

    assignedBed = bedIndex
    currentBedData = bedData
    inTreatment = true

    local ped = PlayerPedId()

    if Config.FadeScreen then
        DoScreenFadeOut(Config.FadeOutMs or 300)
        while not IsScreenFadedOut() do Wait(10) end
        Wait(Config.FadeHoldMs or 0)
    end

    SetEntityCoords(ped, bedData.coords.x, bedData.coords.y, bedData.coords.z, false, false, false, true)
    SetEntityHeading(ped, bedData.heading or 0.0)

    -- If the player is still alive, gently lay them onto the bed
    gentleLayDownIfAlive()

    if Config.FadeScreen then
        DoScreenFadeIn(Config.FadeInMs or 300)
    end

    notify('Checked in', ('You are being treated. Duration: %s seconds.'):format(treatmentTime or 0), 'inform')
end)

-- Treatment finished server-side (revived & bed freed)
RegisterNetEvent('rtv_prisonmed:finishAck', function()
    if not inTreatment then return end

    local ped = PlayerPedId()

    lib.hideTextUI()

    stopBedAnim()
    playGetUp()
    ClearPedTasks(ped)

    inTreatment = false
    assignedBed = nil
    currentBedData = nil
end)

----------------------------------------------------------
-- Safety cleanup
----------------------------------------------------------
AddEventHandler('onClientResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end

    if inTreatment then
        TriggerServerEvent('rtv_prisonmed:forceRelease')
        lib.hideTextUI()
        stopBedAnim()
    end

    if targetZoneId then
        pcall(function()
            exports.ox_target:removeZone(targetZoneId)
        end)
    end
end)
