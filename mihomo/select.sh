#!/usr/bin/env bash
set -euo pipefail

api_url=${MIHOMO_API_URL:-http://127.0.0.1:9090}
dmenu_monitor=

if [[ ${1:-} == --monitor ]]; then
    if [[ ! ${2:-} =~ ^[0-9]+$ ]]; then
        echo "mihomo-select: --monitor requires a non-negative integer" >&2
        exit 2
    fi
    dmenu_monitor=$2
    shift 2
fi

for required_command in curl jq; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'mihomo-select: missing command: %s\n' "$required_command" >&2
        exit 1
    fi
done

choose_item() {
    prompt=$1
    if [[ -n ${DISPLAY:-} ]] && command -v dmenu >/dev/null 2>&1; then
        dmenu_args=(-i -p "$prompt")
        if [[ -n $dmenu_monitor ]]; then
            dmenu_args=(-m "$dmenu_monitor" "${dmenu_args[@]}")
        fi
        dmenu "${dmenu_args[@]}"
    elif command -v fzf >/dev/null 2>&1; then
        fzf --prompt="$prompt> "
    else
        echo "mihomo-select: neither dmenu nor fzf is available" >&2
        return 2
    fi
}

if ! proxies_json=$(curl -fsS "$api_url/proxies"); then
    printf 'mihomo-select: cannot reach %s\n' "$api_url" >&2
    exit 1
fi

selector_groups=$(jq -r '
    .proxies
    | to_entries[]
    | select(.value.type == "Selector")
    | .key
' <<<"$proxies_json")

if [[ -z $selector_groups ]]; then
    echo "mihomo-select: no Selector groups found" >&2
    exit 1
fi

group=${1:-}
if [[ -z $group ]]; then
    if group=$(choose_item "Mihomo group" <<<"$selector_groups"); then
        :
    else
        exit_code=$?
        ((exit_code == 2)) && exit "$exit_code"
        exit 0
    fi
    [[ -n $group ]] || exit 0
fi

if ! jq -e --arg group "$group" \
    '.proxies[$group].type == "Selector"' \
    >/dev/null <<<"$proxies_json"
then
    printf 'mihomo-select: unknown Selector group: %s\n' "$group" >&2
    exit 1
fi

nodes=$(jq -r --arg group "$group" '.proxies[$group].all[]' <<<"$proxies_json")
node=${2:-}
if [[ -z $node ]]; then
    if node=$(choose_item "Mihomo node" <<<"$nodes"); then
        :
    else
        exit_code=$?
        ((exit_code == 2)) && exit "$exit_code"
        exit 0
    fi
    [[ -n $node ]] || exit 0
fi

if ! jq -e --arg group "$group" --arg node "$node" \
    '.proxies[$group].all | index($node) != null' \
    >/dev/null <<<"$proxies_json"
then
    printf 'mihomo-select: node is not in %s: %s\n' "$group" "$node" >&2
    exit 1
fi

encoded_group=$(jq -rn --arg value "$group" '$value | @uri')
payload=$(jq -cn --arg name "$node" '{name: $name}')

curl -fsS \
    -X PUT \
    -H 'Content-Type: application/json' \
    --data "$payload" \
    "$api_url/proxies/$encoded_group" \
    >/dev/null

printf 'mihomo: %s -> %s\n' "$group" "$node"
