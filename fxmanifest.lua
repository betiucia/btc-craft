fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'btc-craft'
version '1.0.3'
author 'Betiucia'

shared_scripts {
    '@ox_lib/init.lua',
    'locales/*.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}
ui_page 'ui/index.html'

escrow_ignore {
    'shared/*.lua',
    'locales/*.lua'
}

dependencies {
    'btc-core',
}

files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/*',
    'ui/fonts/*',
    'ui/images/*',
}

lua54 'yes'
