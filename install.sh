#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_VERSION="v0.1.0-alpha"
PRIVATE_REPO="daisukevn16/MagicalStoryTime"
PRIVATE_BOOTSTRAP_API="https://api.github.com/repos/${PRIVATE_REPO}/contents/Bootstrap.sh"
CONFIG_DIR="${MST_CONFIG_DIR:-/etc/magical-story-time}"
TOKEN_FILE="${MST_GITHUB_TOKEN_FILE:-${CONFIG_DIR}/github-token}"
BRANCH="${1:-${MST_BRANCH:-main}}"
EXPECTED_VERSION="${2:-${MST_EXPECTED_VERSION:-}}"

fail() {
    printf 'FEHLER: %s\n' "$1" >&2
    exit 1
}

info() {
    printf '%s\n' "$1"
}

require_root() {
    [ "$(id -u)" -eq 0 ] || fail "Der Installer muss als root ausgeführt werden, z. B. mit sudo."
}

load_os() {
    [ -r /etc/os-release ] || fail "Die Linux-Distribution kann nicht erkannt werden, weil /etc/os-release fehlt."
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        debian|ubuntu) ;;
        *) fail "Die automatische Erstinstallation unterstützt aktuell Debian und Ubuntu. Erkannt: ${ID:-unbekannt}." ;;
    esac
}

package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -Fq 'install ok installed'
}

apt_install() {
    DEBIAN_FRONTEND=noninteractive apt-get update -qq \
        || fail "Der apt-Paketindex konnte nicht aktualisiert werden."
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" \
        || fail "Benötigte Pakete konnten nicht installiert werden: $*"
}

ensure_entry_tools() {
    local missing=()

    command -v curl >/dev/null 2>&1 || missing+=(curl)
    package_installed ca-certificates || missing+=(ca-certificates)

    if [ "${#missing[@]}" -gt 0 ]; then
        info "Benötigte Basispakete werden installiert: ${missing[*]}"
        apt_install "${missing[@]}"
    fi

    command -v curl >/dev/null 2>&1 || fail "curl ist nach der Installation weiterhin nicht verfügbar."
}

secure_config_dir() {
    install -d -m 700 "$CONFIG_DIR" \
        || fail "Das Konfigurationsverzeichnis kann nicht angelegt werden: $CONFIG_DIR"

    if [ -L "$TOKEN_FILE" ]; then
        fail "Die GitHub-Token-Datei darf kein symbolischer Link sein: $TOKEN_FILE"
    fi
    if [ -e "$TOKEN_FILE" ] && [ ! -f "$TOKEN_FILE" ]; then
        fail "Die GitHub-Token-Datei muss eine reguläre Datei sein: $TOKEN_FILE"
    fi
    if [ -f "$TOKEN_FILE" ]; then
        chmod 600 "$TOKEN_FILE" \
            || fail "Die Dateirechte des vorhandenen GitHub Tokens konnten nicht gehärtet werden."
        chown root:root "$TOKEN_FILE" 2>/dev/null || true
    fi
}

read_secret_from_tty() {
    local label="$1"
    local value=""

    [ -r /dev/tty ] && [ -w /dev/tty ] \
        || fail "$label benötigt ein interaktives Terminal."

    printf '%s: ' "$label" >/dev/tty
    IFS= read -r -s value </dev/tty
    printf '\n' >/dev/tty

    [ -n "$value" ] || fail "$label darf nicht leer sein."
    printf '%s' "$value"
}

persist_token() {
    local token="$1"

    umask 077
    printf '%s' "$token" >"$TOKEN_FILE" \
        || fail "Der GitHub Token kann nicht gespeichert werden: $TOKEN_FILE"
    chmod 600 "$TOKEN_FILE" \
        || fail "Die Dateirechte des GitHub Tokens konnten nicht gesetzt werden."
    chown root:root "$TOKEN_FILE" 2>/dev/null || true
}

build_curl_config() {
    local config_file="$1"
    local token="$2"

    umask 077
    {
        printf 'silent\n'
        printf 'show-error\n'
        printf 'fail\n'
        printf 'header = "Authorization: Bearer %s"\n' "$token"
        printf 'header = "Accept: application/vnd.github.raw+json"\n'
        printf 'header = "X-GitHub-Api-Version: 2022-11-28"\n'
    } >"$config_file"
    chmod 600 "$config_file"
}

validate_private_bootstrap() {
    local file="$1"
    local first_line=""

    [ -s "$file" ] || fail "Die private Bootstrap.sh wurde leer heruntergeladen."
    first_line="$(head -n 1 "$file" 2>/dev/null || true)"
    [ "$first_line" = '#!/usr/bin/env bash' ] \
        || fail "Die heruntergeladene private Bootstrap.sh hat kein erwartetes Bash-Format."
    grep -Fq 'MagicalStoryTime' "$file" \
        || fail "Die heruntergeladene private Bootstrap.sh konnte nicht eindeutig MagicalStoryTime zugeordnet werden."
    chmod 700 "$file"
}

main() {
    local token=""
    local token_is_new=0
    local curl_config=""
    local private_bootstrap=""
    local rc=0

    require_root
    load_os
    ensure_entry_tools
    secure_config_dir

    [ -n "$BRANCH" ] || fail "Der Branch darf nicht leer sein."

    if [ -s "$TOKEN_FILE" ]; then
        [ -r "$TOKEN_FILE" ] || fail "Die vorhandene GitHub-Token-Datei ist nicht lesbar: $TOKEN_FILE"
        token="$(cat "$TOKEN_FILE")"
        [ -n "$token" ] || fail "Die vorhandene GitHub-Token-Datei ist leer: $TOKEN_FILE"
        info "Vorhandener GitHub Fine-grained Token wird sicher wiederverwendet."
    else
        token="$(read_secret_from_tty 'GitHub Fine-grained Token mit Leserechten auf MagicalStoryTime')"
        token_is_new=1
    fi

    curl_config="$(mktemp /tmp/mst-bootstrap-curl.XXXXXX.conf)" \
        || fail "Temporäre curl-Konfiguration konnte nicht erstellt werden."
    private_bootstrap="$(mktemp /tmp/mst-private-bootstrap.XXXXXX.sh)" \
        || { rm -f "$curl_config"; fail "Temporäre Bootstrap-Datei konnte nicht erstellt werden."; }

    cleanup() {
        rm -f "$curl_config" "$private_bootstrap"
    }
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM HUP

    build_curl_config "$curl_config" "$token"

    info "Private MagicalStoryTime-Bootstrap-Datei für Branch '$BRANCH' wird authentifiziert geladen."
    if ! curl --config "$curl_config" \
        --get \
        --data-urlencode "ref=$BRANCH" \
        --output "$private_bootstrap" \
        "$PRIVATE_BOOTSTRAP_API"; then
        unset token
        if [ "$token_is_new" -eq 1 ]; then
            fail "Der eingegebene Token kann die private Bootstrap.sh im Branch '$BRANCH' nicht lesen. Es wurde kein Token dauerhaft gespeichert."
        fi
        fail "Der gespeicherte GitHub Token kann die private Bootstrap.sh im Branch '$BRANCH' nicht lesen. Die bestehende Token-Datei wurde nicht verändert."
    fi

    validate_private_bootstrap "$private_bootstrap"

    if [ "$token_is_new" -eq 1 ]; then
        persist_token "$token"
    fi
    unset token

    info "Öffentlicher Bootstrap ${BOOTSTRAP_VERSION} abgeschlossen. Übergabe an die private MagicalStoryTime-Installation."

    set +e
    bash "$private_bootstrap" "$BRANCH" "$EXPECTED_VERSION"
    rc=$?
    set -e

    cleanup
    trap - EXIT INT TERM HUP
    exit "$rc"
}

main "$@"
