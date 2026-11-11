fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Kakarot'
description 'Allows players to sell items for money, built on the kora_lib AppShell'
version '2.0.9'

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

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
