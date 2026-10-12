#!/usr/bin/env bash
# Abre o ForgeProject de verdade numa tela virtual (OpenGL por software,
# llvmpipe) e captura as áreas de trabalho e um render real.
set -u
APP="$(readlink -f "$1")"
OUT="$(mkdir -p "$2" && readlink -f "$2")"
chmod +x "$APP" 2>/dev/null  # o artefato do Actions perde o bit de execução
export DISPLAY=:99 APPIMAGE_EXTRACT_AND_RUN=1 LIBGL_ALWAYS_SOFTWARE=1 MESA_GL_VERSION_OVERRIDE=4.5
Xvfb :99 -screen 0 1600x1000x24 -nolisten tcp >/dev/null 2>&1 &
sleep 2
(command -v openbox >/dev/null && DISPLAY=:99 openbox >/dev/null 2>&1 &)
sleep 2
n=0
shot() { n=$((n+1)); sleep "${2:-3}"; import -window root "$(printf '%s/%02d-%s.png' "$OUT" "$n" "$1")"; echo "captura $n: $1"; }
key() { timeout 10 xdotool key --clearmodifiers "$@"; }
# Cena de exemplo criada na abertura (macaco suavizado, chão, luz e material
# verde), para as capturas mostrarem o app trabalhando de verdade.
SCENE='import bpy
for o in list(bpy.data.objects): bpy.data.objects.remove(o)
bpy.ops.mesh.primitive_monkey_add(location=(0,0,1))
m=bpy.context.object
bpy.ops.object.shade_smooth()
m.modifiers.new("Subdiv","SUBSURF").levels=2
mat=bpy.data.materials.new("Verde"); mat.diffuse_color=(0.29,0.87,0.5,1); m.data.materials.append(mat)
bpy.ops.mesh.primitive_plane_add(size=8)
bpy.ops.object.light_add(type="SUN", location=(4,-4,6))
bpy.ops.object.camera_add(location=(5,-5,4), rotation=(1.1,0,0.785))
bpy.context.scene.camera=bpy.context.object
bpy.context.scene.render.engine="BLENDER_WORKBENCH"
bpy.context.view_layer.objects.active=m; m.select_set(True)'
"$APP" --factory-startup --python-expr "$SCENE" > "$OUT/app.log" 2>&1 &
APP_PID=$!
sleep 45
W=$(timeout 10 xdotool search --onlyvisible --name "ForgeProject" | head -1)
[ -n "$W" ] && timeout 10 xdotool windowfocus "$W" windowsize "$W" 1600 1000 windowmove "$W" 0 0
shot tela-inicial 4
xdotool mousemove 250 760 click 1; sleep 2   # fecha a tela inicial clicando fora dela
xdotool mousemove 700 600 click 1; sleep 1
shot cena-3d 3
key KP_Decimal; shot objeto-em-foco 3          # enquadra o objeto selecionado
key Tab; shot modo-edicao 3                    # modo de edição da malha
key Tab; sleep 1
key shift+a; shot menu-adicionar 3
key Escape; sleep 1
key z; shot modos-de-visualizacao 3
key Escape; sleep 1
for ws in 1 2 3 4 5 6 7; do
  key ctrl+Next; shot "area-de-trabalho-$ws" 4
done
key ctrl+Next; key ctrl+Next
xdotool mousemove 700 600
key F12; shot render 40
key Escape; sleep 2
key ctrl+comma; shot preferencias 5
kill $APP_PID 2>/dev/null; sleep 1
ls -la "$OUT"
# encerra a tela virtual e o gerenciador de janelas
pkill openbox 2>/dev/null; pkill -f "Xvfb :99" 2>/dev/null; true
