fx_version 'cerulean'
game 'gta5'

name 'rtv_prison_doctor'
author 'RTV Scripts'
description 'Standalone prison doctor system with beds, ox_lib UI, ox_target support and tk_ambulancejob integration.'
version '1.0.0'

lua54 'yes'

dependencies {
    'ox_lib',
    'ox_target',      -- required if you enable ox_target in config
    --'tk_ambulancejob' -- revive export change to your own ambulance resource
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
