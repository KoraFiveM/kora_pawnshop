fx_version 'cerulean'
game 'gta5'
lua54 'yes'
-- Keep the legacy resource name resolvable for exports['qbpawnshop'] callers.
provide 'qbpawnshop'
author 'Kakarot'
description 'Allows players to sell items for money, built on the kora_lib AppShell'
version '2.0.4'

dependency 'kora_lib'
dependency 'kora_core'
dependency 'kora_sql'

shared_script {
    '@kora_lib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@kora_sql/init.lua',
    'server/**.lua',
}

client_script 'client/**.lua'

files {
    'locales/*.json',
}
