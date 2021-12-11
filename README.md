# AHK Voicemeeter

AHK Voicemeeter is a library to enable controlling Voicemeeter through Autohotkey.

## Getting Started

Save `VoicemeeterRemote.ahk` to the directory containing your AutoHotkey script. Alternatively, you can copy the contents of `VoicemeeterRemote.ahk` into your AutoHotkey script. If you chose to save `VoicemeeterRemote.ahk` to your AHK script directory, be sure to `#include VoicemeeterRemote.ahk` in your script. Create a new `VoicemeeterRemote` instance to establish connection.

## Example Script

```autohotkey
#NoEnv
SendMode, Input
SetWorkingDir, %A_ScriptDir%
#SingleInstance Force
#MaxHotkeysPerInterval 200

; Include the VoicemeeterRemote library
#include VoicemeeterRemote.ahk

; Wait until Voicemeeter is running before continuing
DetectHiddenWindows, On
WinWait, % VoicemeeterRemote.WindowClass
DetectHiddenWindows, Off

; Voicemeeter waits a few seconds before starting the audio engine, so we wait
Sleep, 4000

vm := new VoicemeeterRemote()

muted := vm.GetParameterFloat("Strip[2].Mute")

Volume_Up::vm.SetParameters("Strip[2].Gain+=1.0")
Volume_Down::vm.SetParameters("Strip[2].Gain-=1.0")
Volume_Mute::vm.SetParameterFloat("Strip[5].Mute", (muted := !muted))
```

## API

### `VoicemeeterRemote`

This class wraps the whole library.

- **Static properties**
	- VoicemeeterType
	- WindowClass
- **Instance methods**
	- IsParametersDirty
	- GetParameterFloat
	- GetParameterString
	- SetParameterFloat
	- SetParameterString
	- SetParameters
	- ShowVoicemeeterWindow
	- HideVoicemeeterWindow
	- ToggleVoicemeeterWindow

### `VoicemeeterRemote.VoicemeeterType`

Abstraction to more easily identify `VoicemeeterType` numbers as utilized by the VMR API.

| Property Name       | Value |
| ------------------- | ----- |
| `Voicemeeter`       | `1`   |
| `VoicemeeterBanana` | `2`   |
| `VoicemeeterPotato` | `3`   |

### `VoicemeeterRemote.WindowClass`

A string to more easily identify the Voicemeeter window.

#### Example

```autohotkey
; Wait until the Voicemeeter window is detected to ensure it is running
WinWait, % VoicemeeterRemote.WindowClass
```

### `VoicemeeterRemote#IsParametersDirty()`

Check if parameters have changed. It is recommended to call this function periodically if you are tracking parameter states.

### `VoicemeeterRemote#GetParameterFloat()`

Get a floating point parameter value.

#### Example

```autohotkey
; Get the current state of Strip 0's Mute parameter
muted := vm.GetParameterFloat("Strip[0].Mute")
```

### `VoicemeeterRemote#GetParameterString()`

Get a string parameter value.

#### Example

```autohotkey
; Get Strip 0's label
label := vm.GetParameterString("Strip[0].Label")
```

### `VoicemeeterRemote#SetParameterFloat()`

Set a floating point parameter value.

#### Example

```autohotkey
; Set the gain of Strip 0 to -3.0
vm.SetParameterFloat("Strip[0].Gain", -3.0)
```

### `VoicemeeterRemote#SetParameterString()`

Set a string parameter value.

#### Example

```autohotkey
; Set the label of Strip 0 to "My Microphone"
vm.SetParameterString("Strip[0].Label", "My Microphone")
```

### `VoicemeeterRemote#SetParameters()`

Set one or several parameters by a script. See the official [Voicemeeter Remote API Documentation](https://download.vb-audio.com/Download_CABLE/VoicemeeterRemoteAPI.pdf) for more information.

#### Example

```autohotkey
; Set the gain of Strip 0 to -3.0
vm.SetParameters("Strip[0].Gain = -3.0")

; Supports addition/subtraction assignment
; Set the gain of Strip 0 to [current value] - 3.0
vm.SetParameters("Strip[0].Gain -= -3.0")

; Also supports changing multiple parameters in a single expression
; Supported instruction delimiters: "," ";" or "`n" (new line)
; The below example unmutes Strip 0 and increases the gain by 1.0
vm.SetParameters("Strip[0].Mute = 0; Strip[0].Gain += 1.0")
```

### `VoicemeeterRemote#ShowVoicemeeterWindow()`

Show and activate the Voicemeeter window.

#### Example

```autohotkey
; Show the Voicemeeter window on keypress
#F7::vm.ShowVoicemeeterWindow()
```

### `VoicemeeterRemote#HideVoicemeeterWindow()`

Hide the Voicemeeter window.

#### Example

```autohotkey
; Hide the Voicemeeter window on keypress
#F7::vm.HideVoicemeeterWindow()
```

### `VoicemeeterRemote#ToggleVoicemeeterWindow()`

Toggles showing or hiding the Voicemeeter window. Hides the window if it is active. Shows and activates the window if it is hidden or inactive.

#### Example

```autohotkey
; Show or hide the Voicemeeter window, depending on whether it is currently active or not
#F7::vm.ToggleVoicemeeterWindow()
```
