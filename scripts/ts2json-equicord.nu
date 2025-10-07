#!/usr/bin/env nu

# yes this script is nushell i dont care if no one else uses nushell
# i am not making a script that only im going to run in bash

# rm -rf ./Equicord
# git clone https://github.com/Equicord/Equicord

def thing [] {
    let awk = cat ./scripts/ts2json-equicord.awk

    cd $"Equicord/src/equicordplugins"
    
    mut output = "{"

    for file in (ls -f ...(glob **/*.{ts,tsx}) | where name =~ "index" | get name) {
        if ($file | str contains "_") { continue }

        let dirname = ($file | path dirname | path basename)
        $output += $"\"($dirname)\": {"

        $output += (awk $awk $file | str join "\n")

        $output += "},"
    }

    $output += "}"
    $output
}

# remember to remove config options where the config type is component because that means like a button
# and button is a one time thing not something configuarable
# update: nevermind, `commandPalette` for example the component is to set a keybind which is 100% configuarble so idk might have to make a manual override for those

# todo: get description for the actual plugin itself to i can add the enable option for everything
# todo: fix parsing when its parsing for vencord since the format is different

def main [
    --format, # format the json output
] {
    thing | str replace --all --regex "\",\n\\},\n +\\}," "\",\n},\n" | if ($format) {
        $in | from json | sort | to json --indent 4 # looks stupid but its to format and sort the json in case you ever need the raw json
    } else {
        $in
    }
}
