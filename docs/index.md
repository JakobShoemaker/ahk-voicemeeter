# AHK Voicemeeter

AHK Voicemeeter is a library to enable controlling Voicemeeter through Autohotkey.

## Getting Started

Download the [latest release](https://github.com/JakobShoemaker/ahk-voicemeeter/releases/latest) from GitHub Releases.

Place `Voicemeeter.ahk` in the [local library folder](https://www.autohotkey.com/docs/v2/Scripts.htm#lib) of your AutoHotkey script.

In your script, add the line: `#!autohotkey #Include <Voicemeeter>`. Next create a new `Voicemeeter` instance by calling `#!autohotkey Voicemeeter()` to establish a connection to the program. All that's left is to write your script logic, hotkeys, macros, et cetera.

## Example Script

```title="Folder Structure"
MyAwesomeScript
├── Lib
│   └── Voicemeeter.ahk
├── MyAwesomeScript.ahk
└── MyOtherCoolScript.ahk
```

```autohotkey title="MyAwesomeScript.ahk"
#Requires AutoHotkey v2.0

; Set SingleInstance to make sure only one instance of the script can run at a time.
#SingleInstance Force

; Include the Voicemeeter library.
#Include <Voicemeeter>

; Create the Voicemeeter instance.
vmr := Voicemeeter()

; Increase or decrease the gain of Strip[2] by 1 when the volume up or down keys are pressed.
Volume_Up::vmr.SetParameters("Strip[2].Gain+=1.0")
Volume_Down::vmr.SetParameters("Strip[2].Gain-=1.0")

; When the volume mute key is pressed, get the current mute state of Strip[2] and set it to the opposite.
Volume_Mute::vmr.SetParameterFloat("Strip[2].Mute", !vmr.GetParameterFloat("Strip[2].Mute"))
```
