# Dotfiles

Configuraciones personales para macOS y Windows (Git Bash).

## Hammerspoon en macOS

1. Instala [Hammerspoon](https://www.hammerspoon.org/).
2. Copia `macos/hammerspoon/init.lua` a `~/.hammerspoon/init.lua` (crea la carpeta si hace falta).
3. Abre Hammerspoon y selecciona **Reload Config** desde su menú.
4. Concede a Hammerspoon los permisos de Accesibilidad y Automatización que macOS solicite. La configuración usa eventos de teclado/ratón, el micrófono y AppleScript para controlar Chrome y Microsoft Teams.

Atajos incluidos:

- `Fn` + `F12`: activa o desactiva el movimiento periódico del ratón.
- `F5`: alterna el estado del micrófono y sincroniza Teams/Google Meet cuando están disponibles.
- `Fn` + `F10`: desactiva el movimiento del ratón y bloquea el Mac tras dos segundos.
- `Fn` + `F6`: bloquea el Mac.
- `Fn` + `F1`: envía `Control` + `Command` + `9`.

El comportamiento de `F5` depende de la distribución del teclado y de la interfaz de Meet; verifica el estado del micrófono al usarlo.

## Touch Bar con MTMR

1. Instala MTMR ejecutando `macos/mtmr/build-mtmr.sh` (requiere Xcode). Usa el clon de `~/Repositories/MTMR` (si no existe, clona MTMR 0.28 y aplica `mtmr-keyboard-brightness.patch`). El parche añade el tipo de ítem `keyboardBrightness`, sliders con el estilo de la Control Strip (perilla redonda y color por función), íconos en los botones de grupo y hace que MTMR se aparte mientras haya un diálogo abierto, para que la Touch Bar muestre los botones de la app (Save, Delete, Allow...). Los diálogos los detecta Hammerspoon, que tiene el permiso de Accesibilidad, y se lo avisa a MTMR con la notificación `com.toxblh.mtmr.dialog`. Desactiva las actualizaciones de MTMR: una actualización reemplazaría esta versión.
2. Compila el lector de temperatura del CPU (lee del SMC el núcleo más caliente, como las apps de ventiladores; `mactemp -v` lista los sensores):
   `mkdir -p ~/.local/bin && clang -O2 -framework IOKit -framework CoreFoundation macos/mtmr/mactemp.c -o ~/.local/bin/mactemp`
3. Copia `macos/mtmr/items.json` a `~/Library/Application Support/MTMR/items.json` y reinicia MTMR.

Los botones de ratón, micrófono, captura y luna llaman a las acciones de Hammerspoon mediante URLs (`hammerspoon://toggle-jiggler`, `toggle-mic`, `screenshot`, `lock-eod`), así que Hammerspoon debe estar abierto.

Brillo, luz del teclado y volumen se convierten en un slider al tocarlos, como en la Control Strip nativa; se cierran solos al soltar el slider o tras 4 segundos sin tocarlos, y la ✕ junto al slider los cierra antes. El botón verde de play abre Spotify si está cerrado; si está abierto, un toque alterna play/pausa, dos pasan a la siguiente canción y tres vuelven a la anterior (lo gestiona Hammerspoon con `hammerspoon://spotify-tap`). Tocar la batería rota entre íconos de colores, todos blancos y arcoíris (de izquierda a derecha); tocar la hora muestra la fecha unos segundos. El clima viene de [wttr.in](https://wttr.in).

## Zsh en macOS

Copia `macos/shell/.zshrc` a `~/.zshrc` o incorpora su contenido a tu archivo actual. Después, abre una nueva terminal o ejecuta `source ~/.zshrc`.

## Git Bash en Windows

Copia `windows/git-bash/.bash_profile` a tu carpeta de usuario de Windows como `.bash_profile` (por ejemplo, `C:\Users\TU_USUARIO\.bash_profile`). Reinicia Git Bash o ejecuta `source ~/.bash_profile`.

Los archivos de shell son esqueletos listos para que añadas tus alias y funciones.
