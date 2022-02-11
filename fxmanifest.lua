fx_version 'cerulean'
game 'gta5'

description 'QB-Weed'
version '1.0.0'

shared_scripts {
	'config.lua'
}

client_scripts {
	'client/main.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua'
}

lua54 'yes'