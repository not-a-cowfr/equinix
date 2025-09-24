#!/usr/bin/env nu

# yes this script is nushell i dont care if no one else uses nushell
# i am not making a script that only im going to run in bash

# rm -rf ./Equicord
# git clone https://github.com/Equicord/Equicord

def thing [] {
    cd Equicord/src/equicordplugins
    
    mut output = "{"

    for file in (ls -f ...(glob **/*.{ts,tsx}) | where name =~ "index" | get name) {
        if ($file | str contains "_") { continue }

        let dirname = ($file | path dirname | path basename)
        $output += $"\"($dirname)\": {"

        $output += (awk (cat ../../../scripts/ts2json.awk) $file | str join "\n")

        $output += "},"
    }

    $output += "}"
    $output
}

# remember to remove config options where the config type is component because that means like a button (im pretty sure its always like that, i havent seen anything besides that)
# and button is a one time thing not something configuarable
thing | str replace --all --regex "\",\n\\},\n +\\}," "\",\n},\n" | from json | to json --indent 4 # looks stupid but its to format the json
