fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Allows players to sell items for money, built on the qblib AppShell'
version '2.0.0'

dependency 'qblib'

shared_script {
    '@qblib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**.lua',
}

client_script 'client/**.lua'
