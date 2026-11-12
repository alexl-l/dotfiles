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

## Zsh en macOS

Copia `macos/shell/.zshrc` a `~/.zshrc` o incorpora su contenido a tu archivo actual. Después, abre una nueva terminal o ejecuta `source ~/.zshrc`.

## Git Bash en Windows

Copia `windows/git-bash/.bash_profile` a tu carpeta de usuario de Windows como `.bash_profile` (por ejemplo, `C:\Users\TU_USUARIO\.bash_profile`). Reinicia Git Bash o ejecuta `source ~/.bash_profile`.

Los archivos de shell son esqueletos listos para que añadas tus alias y funciones.
