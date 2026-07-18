#!/usr/bin/env bash

set -euo pipefail

readonly REPO_DIR="$(dirname "$(readlink -m "$0")")"
readonly USER_THEME_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"
readonly BLUR_THEME_UUID="blur-my-shell@aunetx"
readonly THEME_NAME="WhiteSur-Dark-solid"
readonly BLUR_KEY="/org/gnome/shell/extensions/blur-my-shell/panel/blur"
readonly BLUR_OVERRIDE_KEY="/org/gnome/shell/extensions/blur-my-shell/panel/override-background"

restore_dconf_value() {
  local key="$1"
  local value="$2"

  if [[ -n ${value} ]]; then
    dconf write "${key}" "${value}"
  else
    dconf reset "${key}"
  fi
}

restore_blur_my_shell() {
  restore_dconf_value "${BLUR_KEY}" "${blur_before}"
  restore_dconf_value "${BLUR_OVERRIDE_KEY}" "${blur_override_before}"
}

if [[ ${EUID} -eq 0 ]]; then
  echo "Run this script as your desktop user, not with sudo." >&2
  exit 1
fi

"${REPO_DIR}/install.sh" -c dark -o solid --darker
"${REPO_DIR}/install.sh" -l -c dark -o solid --darker -f

if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme "${THEME_NAME}"
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
fi

if command -v dconf >/dev/null; then
  dconf write /org/gnome/shell/extensions/user-theme/name "'${THEME_NAME}'"

  if command -v gnome-extensions >/dev/null && gnome-extensions info "${BLUR_THEME_UUID}" >/dev/null 2>&1; then
    blur_before="$(dconf read "${BLUR_KEY}")"
    blur_override_before="$(dconf read "${BLUR_OVERRIDE_KEY}")"
    trap restore_blur_my_shell EXIT

    dconf write "${BLUR_KEY}" false
    dconf write "${BLUR_OVERRIDE_KEY}" false
  fi
fi

if command -v gnome-extensions >/dev/null && \
   gnome-extensions list --enabled | grep -Fxq "${USER_THEME_UUID}"; then
  gnome-extensions disable "${USER_THEME_UUID}"
  gnome-extensions enable "${USER_THEME_UUID}"
fi

if [[ -v blur_before ]]; then
  restore_blur_my_shell
  trap - EXIT
fi

echo "Installed and activated ${THEME_NAME} with OLED-black surfaces."
