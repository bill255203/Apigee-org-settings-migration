#!/usr/bin/env bash

# cd results/get/sharedflow/revision

for z in *.zip; do
    dir="${z%.*}"
    mkdir "$dir" && unzip "$z" -d "$dir"
done

# ... [License and Copyright]

sfdir="$1"
target=$2

# Validate input directory
if [ -z "$sfdir" ] || [ ! -d "$sfdir" ]; then
    echo "ERROR: Missing or invalid directory with shared flows"
    exit 1
fi

# Validate target type
if [ -z "$target" ] || { [ "$target" != "dot" ] && [ "$target" != "tsort" ]; }; then
    echo "ERROR: Invalid target type: $target. Use 'dot' or 'tsort'"
    exit 1
fi

# Initialize variables
declare -a all_shared_flows
declare -a independent_shared_flows
declare -A dependencies

# Process shared flows
for sf in "$sfdir"/*/; do
    if [ -d "$sf" ]; then
        sflow="$(basename "$sf")"
        all_shared_flows+=("$sflow")

        if [ -d "${sf}sharedflowbundle/policies" ]; then
            pushd "${sf}sharedflowbundle/policies" >/dev/null || exit

            # Collect dependencies
            for fc in $(grep -Ril "<FlowCallout " *); do
                to="$(grep '<SharedFlowBundle' "$fc" | awk -F "[><]" '{print $3}')"
                if [ -n "$to" ]; then
                    dependencies["$sflow"]+="$to "
                fi
            done

            popd >/dev/null || exit
        else
            independent_shared_flows+=("$sflow")
        fi
    fi
done

# Output in 'dot' format
if [ "$target" = "dot" ]; then
    echo "digraph G {"
    echo "  rankdir=LR"
    echo "  node [shape=box,fixedsize=true,width=3]"

    for sf in "${all_shared_flows[@]}"; do
        if [ -n "${dependencies[$sf]}" ]; then
            for dep in ${dependencies[$sf]}; do
                echo "  \"$sf\" -> \"$dep\";"
            done
        else
            echo "  \"$sf\";"
        fi
    done

    echo "}"
fi

# Output in 'tsort' format
if [ "$target" = "tsort" ]; then
    for sf in "${all_shared_flows[@]}"; do
        if [ -n "${dependencies[$sf]}" ]; then
            for dep in ${dependencies[$sf]}; do
                echo "$sf $dep"
            done
        else
            echo "$sf"
        fi
    done | tsort | tail -r
fi
