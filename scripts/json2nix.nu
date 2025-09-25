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

# maps the string representation types (after `OptionType.` part is removed) into nix types
def "into nix-type" [options?: any]: string -> string {
	match $in {
		"BOOLEAN" => "types.bool",
		"STRING" => "types.str",
		"NUMBER" => "types.int",
		"SLIDER" => "types.int",
		"SELECT" => $"types.enum ($options | to json | lines | str trim | str join ' ')",
		_ => {
			error make { msg: $"Unhandled attempted type conversion ($in)" };
		}
	}
}

# if you dont think ts is beautiful you dont have eyes
./scripts/ts2json.nu equicord
	| from json
	| transpose key value
	| sort-by key
	| par-each {|row|
		# if the key doesnt have any child config optiosn then it has no settings and is just enable/disable
		let key = if ($row.value | is-empty) { $"($row.key).enable" } else { $row.key };

		let settings = ($row.value
			| transpose key value
			| where ($it.value.type != "COMPONENT") # most of the time this means that its like a one time use button (eg. to reset something), except for when it isnt so idk i need to manually handle those
			| each {|child|
				if ($child.value | get -o hidden | is-empty) {
					# make boolean options just be .enable for nix semantics
					let key = if ($child.value.type == "BOOLEAN") { $"($child.key).enable"; } else { $child.key };
					# if the type is select then you have to find the default differently
					let default = if ($child.value.type == "SELECT") { $child.value.options? | where default? == true | get value.0 } else { $child.value.default? } | to json | default "null";
					# if stick to markers doesnt exist then the range isnt actually something you have to follow, but if it is there, then parse the range
					let range = if ($child.value | get -o stickToMarkers | is-not-empty) { $child.value.markers | parse 'makeRange({min}, {max}, {step}),' }

					# turn the string type representation into an actual nix type
					let type = $child.value.type | into nix-type ($child.value.options?.value?);
					# if the type is a slider (and the range exists) then you need to add a check to make sure its in the specified range
					let type = if ($child.value.type == "SLIDER" and ($range | is-not-empty)) {
						'types.addCheck ' + $type + ' (x: x >= ' + $range.min.0 + ' && x <= ' + $range.max.0 + ' && mod x ' + $range.step.0 + ' == 0)'
					} else {
						$type
					}

					$"    ($key) = mkOption {
					      type = ($type);
					      description = \"($child.value.description? | default "")\";
					      default = ($default);
					    };" | str replace -a (char tab) '' # removes tabs so it can be neatly formatted in the editor but still be outputted correctly
				}
			}
			| str join (char nl)
		)

		$"  ($key) =(if ($row.value | is-empty) { ' mkOption' }) {
			($settings)
		  };" | str replace -a (char tab) '' # removes tabs so it can be neatly formatted in the editor but still be outputted correctly
	}
	| str join (char nl)
	| $"{ lib, ... }:
		let
		  inherit \(lib\) types mkOption;

		  mod = dividend: divisor: dividend - \(divisor * \(dividend / divisor\)\);
		in
		{
			($in)
		}" | str replace -a (char tab) '' # removes tabs so it can be neatly formatted in the editor but still be outputted correctly

# need to add mod operator thingy for the `check`
# let
#	 mod = dividend: divisor: dividend - (divisor * (dividend / divisor));
# in
