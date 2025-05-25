fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'snake charmer'
version '1.0.0'
author 'phil mcracken'
shared_scripts {
    '@rsg-core/shared/locale.lua',
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
   
    'client.lua'
}

server_scripts {
    
    'server.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'ox_target',
	'xsound',
	'rNotify'
}

lua54 'yes'