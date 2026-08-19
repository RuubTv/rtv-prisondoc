Config = {}

----------------------------------------------------------
-- Check-in configuration
----------------------------------------------------------
Config.CheckIn = {
    -- Location used for TextUI + E mode
    coords = vec3(1761.10, 2570.90, 45.70), -- EDIT ME
    radius = 1.5,
    label = '[E] Check in at prison doctor',

    -- Interaction type:
    -- false  = use ox_lib TextUI + E
    -- true   = use ox_target sphere zone
    useOxTarget = false,

    -- ox_target zone settings
    -- These can be the same as coords/radius above or different
    targetCoords = vec3(1761.10, 2570.90, 45.70), -- EDIT ME
    targetRadius = 1.5,
    targetLabel  = 'Check in at prison doctor',
    targetIcon   = 'fa-solid fa-user-doctor'
}

----------------------------------------------------------
-- Bed configuration
----------------------------------------------------------
Config.Beds = {
    { coords = vec3(1761.50, 2585.20, 45.70), heading = 90.0 }, -- EDIT ME
    { coords = vec3(1761.50, 2587.20, 45.70), heading = 90.0 }, -- EDIT ME
    { coords = vec3(1761.50, 2589.20, 45.70), heading = 90.0 }, -- EDIT ME
}

----------------------------------------------------------
-- Treatment settings
----------------------------------------------------------
-- How long the treatment lasts (in seconds)
-- After this time, the player is automatically revived and gets up from the bed.
Config.TreatmentTime = 20

----------------------------------------------------------
-- Screen fade settings
----------------------------------------------------------
Config.FadeScreen = true
Config.FadeOutMs  = 800
Config.FadeHoldMs = 200
Config.FadeInMs   = 800

----------------------------------------------------------
-- Check-in animation (clipboard / notepad style)
----------------------------------------------------------
Config.CheckInAnim = {
    dict = 'amb@world_human_clipboard@male@base',
    name = 'base',
    durationMs = 2000,
    flag = 49 -- upper body + loopish
}

----------------------------------------------------------
-- Bed animation (soft attempt, no forced loop)
-- If the player is alive, we try to lay them down.
-- If they are ragdoll/last stand/dead, we do nothing.
----------------------------------------------------------
Config.BedAnim = {
    enabled = true,
    dict = 'amb@world_human_sunbathe@male@back@base',
    name = 'base',
    flag = 1
}

----------------------------------------------------------
-- Get-up animation
----------------------------------------------------------
Config.GetUpAnim = {
    enabled = true,
    dict = 'get_up@directional@movement@from_knees@action',
    name = 'getup_r_0',
    durationMs = 1400,
    flag = 0
}

----------------------------------------------------------
-- Ambulance / EMS on-duty check
--
-- If enough EMS are on duty, players are forced to use
-- the normal medical system instead of the prison doctor.
----------------------------------------------------------
Config.AmbulanceCheck = {
    enabled = true,

    -- 'auto', 'esx', 'qb', 'export', 'none'
    -- auto  = try ESX -> QB -> export -> none
    -- esx   = always use ESX job list
    -- qb    = always use QB job list
    -- export = call a custom export returning count or boolean
    -- none  = do not check EMS online at all
    mode = 'auto',

    -- If on-duty EMS >= minOnDuty, block prison doctor usage
    minOnDuty = 1,
    blockIfOnDuty = true,

    -- Job names for ESX / QBCore
    jobNames = { 'ambulance', 'ems', 'doctor' },

    -- Custom export mode (only used if mode = 'export' or auto falls back to this)
    -- Export must return:
    --   - number  (on duty count)
    --   - boolean (true if EMS available, false if not)
    export = {
        resource = 'tk_ambulancejob',  -- CHANGE or keep if you implement this
        name = 'GetOnDutyCount'        -- CHANGE or remove if unused
    },

    denyTitle = 'Prison Doctor',
    denyMessage = 'There are EMS on duty (%s). Please use regular medical services instead of the prison doctor.'
}
