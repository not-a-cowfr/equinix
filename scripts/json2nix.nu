#!/usr/bin/env nu

def "into nix-type" []: string -> string {
  match $in {
    "BOOLEAN" => "types.bool",
    "STRING"  => "types.str",
    "NUMBER"  => "types.int",
    "SLIDER"  => "types.int",
    "SELECT"  => "types.enum", # todo: add enum data in this too, maybe pass as optional param?
    _         => {
		error make { msg: $"Unhandled attempted type conversion ($in)" };
	}
  }
}

./scripts/ts2json.nu 
| from json 
| transpose key value 
| each {|row|
	let key = if ($row.value | is-empty) { $"($row.key).enable" } else { $row.key };
	
    let settings = (
        $row.value
        | transpose key value
        | where ($it.value.type != "COMPONENT")
        | each {|child|
            let key = $"($child.key).enable";

            $"    ($key) = {
      type = ($child.value.type? | into nix-type);
      description = \"($child.value.description? | default "")\";
      default = ($child.value | get default? | default null | to json);
    };"
        }
        | str join (char nl)
    )

    $"  ($key) = {
($settings)
  };"
}
| str join (char nl)
| $"{
($in)
}"

# todo: sliders, use markers thing to get the range limit then make soemthing like this fpor nix
# check = x: x >= 1 && x <= 12;