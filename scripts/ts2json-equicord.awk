# im dogshit at awk so if this sucks forgive me
/export const settings = definePluginSettings\(\{/ {flag=1; next}
/\}\);/ {flag=0; next}

flag {
    if (!skip && $0 ~ /^[[:space:]]*(component|onChange):/) {
		# fixes some parenthesis not being added for a reason i dont know so just manually add some
		# this also causes another issue where parenthesis are being put where they should but luckily its in only 2 places and is super easy to fix
        print "},"

        match($0, /^([[:space:]]*)/, m)
        baseIndent = length(m[1])

        depth = gsub(/\{/, "{") - gsub(/\}/, "}")
        parenDepth = gsub(/\(/, "(") - gsub(/\)/, ")")

        skip = 1
        next
    }

    if (skip) {
        depth += gsub(/\{/, "{")
        depth -= gsub(/\}/, "}")
        parenDepth += gsub(/\(/, "(")
        parenDepth -= gsub(/\)/, ")")

        match($0, /^([[:space:]]*)/, m)
        lineIndent = length(m[1])

        if (depth <= 0 && parenDepth <= 0 && lineIndent <= baseIndent && $0 ~ /,[[:space:]]*$/) {
            skip = 0
        }
        next
    }

    if ($0 ~ /^[[:space:]]*restartNeeded:/) next
    if ($0 ~ /^[[:space:]]*disabled:/) next

    $0 = gensub(/(:[[:space:]]*)([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)/, "\\1\"\\3\"", "g", $0)

    $0 = gensub(/^[[:space:]]*([A-Za-z0-9_]+):/, "\"\\1\":", 1, $0)

    $0 = gensub(/^([[:space:]]*)\{[[:space:]]*([A-Za-z0-9_]+):/, "\\1{\"\\2\":", "g", $0)
    $0 = gensub(/,[[:space:]]*([A-Za-z0-9_]+):/, ", \"\\1\":", "g", $0)

    print
}
