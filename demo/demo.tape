# Renders the README demo GIF. Run from the repository root:
#   vhs demo/demo.tape && gifsicle -O3 --lossy=80 demo.gif -o demo.gif
Output demo.gif

Set Shell bash
Set FontFamily "JetBrains Mono"
Set WindowBar Colorful
Set WindowBarSize 80
Set FontSize 30
Set Width 2400
Set Height 1120
Set Padding 48
Set Theme "Catppuccin Mocha"
Set TypingSpeed 75ms

Hide
Type "source demo/env.sh"
Enter
# Staging makes ~100 commits and colocates jj repos; let it finish.
Sleep 8s
Type "clear"
Enter
Sleep 1s
Show

Sleep 500ms
Type "zp"
Sleep 500ms
Enter
Sleep 2.5s

Type "picker"
Sleep 2.5s

Backspace 6
Sleep 1s

Type "whatch"
Sleep 1.5s
Down
Sleep 2s
Enter
Sleep 1.5s

Type "jj st"
Sleep 500ms
Enter
Sleep 3s

# Reopen the picker from inside the session: whatchord.2 carries
# the arrow marker and a "you are here" preview.
Type "zp"
Sleep 500ms
Enter
Sleep 2.5s
Down
Sleep 4s
