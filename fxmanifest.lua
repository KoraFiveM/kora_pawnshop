fx_version 'cerulean'
game 'gta5'
lua54 'yes'
-- Keep the legacy resource name resolvable for exports['qbpawnshop'] callers.
provide 'qbpawnshop'
author 'Kakarot'
description 'Allows players to sell items for money, built on the qblib AppShell'
version '2.0.0'

dependency 'kora_lib'
dependency 'kora_core'

shared_script {
    '@kora_lib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**.lua',
}

client_script 'client/**.lua'
