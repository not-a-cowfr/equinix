#!/usr/bin/env nu

# for visualization of the table
# ./scripts/ts2json.nu 
# 	| from json 
# 	| transpose key value 
# 	| each {|row|
# 		{
# 			name: $row.key,
# 			settings: ($row.value | transpose key value | where ($it.value.type != "COMPONENT"))
# 		}
# 	}

def "into nix-type" [options?: any]: string -> string {
  match $in {
    "BOOLEAN" => "types.bool",
    "STRING"  => "types.str",
    "NUMBER"  => "types.int",
    "SLIDER"  => "types.int",
    "SELECT"  => $"types.enum ($options | to json | lines | str trim | str join ' ')",
    _         => {
		error make { msg: $"Unhandled attempted type conversion ($in)" };
	}
  }
}

# if you dont think ts is beautiful you dont have eyes
./scripts/ts2json.nu 
| from json 
| transpose key value 
| par-each {|row|
	let key = if ($row.value | is-empty) { $"($row.key).enable" } else { $row.key };
	
    let settings = (
        $row.value
        	| transpose key value
        	| where ($it.value.type != "COMPONENT")
        	| each {|child|
        	    let key = if ($child.value.type == "BOOLEAN") { $"($child.key).enable"; } else { $child.key };
				let default = if ($child.value.type == "SELECT") { $child.value.options? | where default? == true | get value.0 } else { $child.value.default? } | default null;

        	    $"    ($key) = {
      type = ($child.value.type? | into nix-type ($child.value.options?.value?));
      description = \"($child.value.description? | default "")\";(if ($default != null) { $'(char nl)      default = ($default | to json);' } else { '' })
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
