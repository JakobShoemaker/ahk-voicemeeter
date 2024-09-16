---
title: Voicemeeter
icon: material/alpha-c-box
---
# Voicemeeter

The Voicemeeter Remote interface.

## Fields

### :material-alpha-f-box: WindowClass

The window class of the Voicemeeter main window. This is intended to be used with AutoHotkey [window functions](https://www.autohotkey.com/docs/v2/lib/Win.htm).

#### Type: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

## Static Methods

### :material-alpha-m-box: Call

Constructs a new Voicemeeter instance. This loads the Voicemeeter Remote DLL and logs in to the server.

#### Syntax

```autohotkey
Vmr := Voicemeeter()
```

```autohotkey
Vmr := Voicemeeter.Call()
```

## Methods

### :material-alpha-m-box: BuildParamString

Builds a string containing a script from a list of strings containing script statements for [SetParameters](#setparameters).

#### Syntax

```autohotkey
ParamString := Vmr.BuildParamString(Value1 [, Value2, ..., ValueN])
```

#### Parameters

`Value`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   A string containing a script for [SetParameters](#setparameters).

#### Returns: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

A string containing each of the provided scripts.

### :material-alpha-m-box: GetParameterFloat

Get a parameter value as a floating point number.

#### Syntax

```autohotkey
Value := Vmr.GetParameterFloat(ParamName)
```

#### Parameters

`ParamName`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The name of the parameter.

#### Returns: *[Float](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

The value of the parameter.

### :material-alpha-m-box: GetParameterString

Get a parameter value as a string.

#### Syntax

```autohotkey
Value := Vmr.GetParameterString(ParamName)
```

#### Parameters

`ParamName`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The name of the parameter.

#### Returns: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

The value of the parameter.

### :material-alpha-m-box: GetVoicemeeterType

Get the Voicemeeter type.

#### Syntax

```autohotkey
VoicemeeterType := Vmr.GetVoicemeeterType()
```

#### Returns: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

An integer representing the type of Voicemeeter.

### :material-alpha-m-box: GetVoicemeeterVersion

Get the Voicemeeter version.

#### Syntax

```autohotkey
Version := Vmr.GetVoicemeeterVersion()
```

#### Returns: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

An integer representing the Voicemeeter version.

### :material-alpha-m-box: HideVoicemeeterWindow

Hide the Voicemeeter window.

#### Syntax

```autohotkey
Vmr.HideVoicemeeterWindow()
```

### :material-alpha-m-box: IsParametersDirty

Check if parameters have changed. Call this function periodically (typically every 10 or 20ms).

#### Syntax

```autohotkey
ParametersChanged := Vmr.IsParametersDirty()
```

#### Returns: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

1 (true) if parameters have changed, otherwise 0 (false).

### :material-alpha-m-box: SetParameterFloat

Set a floating point parameter value.

#### Syntax

```autohotkey
Vmr.SetParameterFloat(ParamName, Value)
```

#### Parameters

`ParamName`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The name of the parameter.

`Value`: *[Float](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

:   The value to assign to the parameter.

### :material-alpha-m-box: SetParameterString

Set a string parameter value.

#### Syntax

```autohotkey
Vmr.SetParameterString()
```

#### Parameters

`ParamName`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The name of the parameter.

`Value`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The value to assign to the parameter.

### :material-alpha-m-box: SetParameters

Set one or several parameters by a script.

#### Syntax

```autohotkey
Vmr.SetParameters()
```

#### Parameters

`Params`: *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   A string containing the script.

### :material-alpha-m-box: ShowVoicemeeterWindow

Show and activate the Voicemeeter window.

#### Syntax

```autohotkey
Vmr.ShowVoicemeeterWindow()
```

### :material-alpha-m-box: ToggleVoicemeeterWindow

Toggles the Voicemeeter window between shown and hidden. If the window is hidden or inactive, shows and activates the window, otherwise hides the window.

#### Syntax

```autohotkey
Vmr.ToggleVoicemeeterWindow()
```
