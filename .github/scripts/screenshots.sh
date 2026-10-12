#!/usr/bin/env bash
# Abre o ForgeProject de verdade numa tela virtual (OpenGL por software,
# llvmpipe) e captura as áreas de trabalho e um render real.
set -u
APP="$(readlink -f "$1")"; OUT="$(mkdir -p "$2" && readlink -f "$2")"
export DISPLAY=:99 APPIMAGE_EXTRACT_AND_RUN=1 LIBGL_ALWAYS_SOFTWARE=1 MESA_GL_VERSION_OVERRIDE=4.5
Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp &
sleep 2
n=0
shot() { n=$((n+1)); sleep "${2:-3}"; import -window root "$(printf '%s/%02d-%s.png' "$OUT" "$n" "$1")"; echo "captura $n: $1"; }
key() { xdotool key --clearmodifiers "$@"; }
"$APP" --factory-startup > "$OUT/app.log" 2>&1 &
APP_PID=$!
sleep 45
W=$(xdotool search --onlyvisible --name "ForgeProject" | head -1)
[ -n "$W" ] && xdotool windowactivate --sync "$W" windowsize "$W" 1600 1000 windowmove "$W" 0 0
shot tela-inicial 4
xdotool mousemove 800 520 click 1; sleep 2   # fecha a tela inicial
shot area-3d 3
# Adiciona objetos e modificadores pela busca de operadores (F3)
xdotool mousemove 800 520
key shift+a; shot menu-adicionar 3
key Escape
for ws in 1 2 3 4 5 6 7 8 9; do
  key ctrl+Next; shot "area-de-trabalho-$ws" 4
done
key ctrl+Next
xdotool mousemove 800 520
key F12; shot render 40
key Escape; sleep 2
key ctrl+comma; shot preferencias 5
kill $APP_PID 2>/dev/null; sleep 1
ls -la "$OUT"
