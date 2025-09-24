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
		"STRING"	=> "types.str",
		"NUMBER"	=> "types.int",
		"SLIDER"	=> "types.int",
		"SELECT"	=> $"types.enum ($options | to json | lines | str trim | str join ' ')",
		_				 => {
		error make { msg: $"Unhandled attempted type conversion ($in)" };
	}
	}
}

# if you dont think ts is beautiful you dont have eyes
./scripts/ts2json.nu
	| from json 
	| transpose key value 
	| sort-by key
	| par-each {|row|
		let key = if ($row.value | is-empty) { $"($row.key).enable" } else { $row.key };

		let settings = ($row.value
			| transpose key value
			| where ($it.value.type != "COMPONENT")
			| each {|child|
				if ($child.value | get -o hidden | is-empty) { 
					let key = if ($child.value.type == "BOOLEAN") { $"($child.key).enable"; } else { $child.key };
					let default = if ($child.value.type == "SELECT") { $child.value.options? | where default? == true | get value.0 } else { $child.value.default? } | default null | to json | default "null";
					let range = if ($child.value | get -o stickToMarkers | is-not-empty) { $child.value.markers | parse 'makeRange({min}, {max}, {step}),' }

					let type = $child.value.type | into nix-type ($child.value.options?.value?);
					let type = if ($child.value.type == "SLIDER" and ($range | is-not-empty)) {
						'types.addCheck ' + $type + ' (x: x >= ' + $range.min.0 + ' && x <= ' + $range.max.0 + ' && mod x ' + $range.step.0 + ' == 0)'
					} else {
						$type
					} 

					$"    ($key) = {
					      type = ($type);
					      description = \"($child.value.description? | default "")\";
					      default = ($default);
					    };" | str replace -a (char tab) ''
				}
			}
			| str join (char nl)
		)

		$"  ($key) = {
			($settings)
		  };" | str replace -a (char tab) ''
	}
	| str join (char nl)
	| $"{\n($in)\n}"

# need to add mod operator thingy for the `check`
# let
#	 mod = dividend: divisor: dividend - (divisor * (dividend / divisor));
# in

# todo: skip field if it has the `hidden` key and its true
