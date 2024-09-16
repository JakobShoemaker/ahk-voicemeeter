---
title: Voicemeeter.Enum
icon: material/alpha-c-box
---
# Voicemeeter.Enum

A class containing helper methods for integral enumerations used by the Voicemeeter Remote SDK.

## Static Methods

### :material-alpha-m-box: IsDefined

Determines whether a given integral value, or its name as a string, exists in the enumeration.

#### Syntax

```autohotkey
IsDefined := SomeEnum.IsDefined(Value)
```

#### Parameters

`Value`: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)* | *[String](https://www.autohotkey.com/docs/v2/Concepts.htm#strings)*

:   The value or name of a constant in the enumeration.

#### Returns: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

1 (true) if `Value` is defined in the enumeration, otherwise 0 (false).

### :material-alpha-m-box: __Enum

Enumerates values of the enumeration. This method is typically not called directly. Instead, the enumeration is passed directly to a [for-loop](https://www.autohotkey.com/docs/v2/lib/For.htm).

#### Syntax

```autohotkey
for Value in SomeEnum
```

```autohotkey
for Name, Value in SomeEnum
```

#### Parameters

`NumberOfVars`: *[Integer](https://www.autohotkey.com/docs/v2/Concepts.htm#numbers)*

:   The number of variables passed to the calling for-loop.

#### Returns: *[Enumerator](https://www.autohotkey.com/docs/v2/lib/Enumerator.htm)*

A new [enumerator](https://www.autohotkey.com/docs/v2/lib/Enumerator.htm).
