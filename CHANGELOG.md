# Changelog

## 1.0.0 (2024-09-17)


### ⚠ BREAKING CHANGES

* rename VoicemeeterRemote.ahk to Voicemeeter.ahk
* merge class Voicemeeter.Remote with Voicemeeter
* remove redundant class names
* remove the vmType constructor param and related startup logic
* move logic into class contained within the top-level class

### Features

* _GetVoicemeeterInstallDir no longer throws ([4432420](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/4432420a4850955cd8ecbcd12579117dc7b9ddd0))
* add custom error class to provide consistent error messages ([d0e280a](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/d0e280aa1568f181d91991c30ad76cd00300da10))
* add doc comments ([78f8559](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/78f8559b73d2be487e0ed7867569f50d13af28a4))
* add error conditions to IsParametersDirty ([d43734a](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/d43734aa3fea1fcc144d3d4b918932b2e6eda895))
* add error detection ([fb6bc20](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/fb6bc20462fa7d5ff61066a112f690421f16e3d0))
* add SetVoicemeeterType method ([85d04f2](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/85d04f2a78f5542b48037831da580f51e43bb813))
* add unknown error type to Voicemeeter.RemoteError ([dbfd0b2](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/dbfd0b2eec9233a076542b9ac7a3ebad1921f14d))
* add values to Voicemeeter.Type ([049b008](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/049b008cd3c7e2d3b4651afcaf19728ee9afc545))
* add VoicemeeterEnum class to expand functionality of VoicemeeterType and DeviceType enums ([55de824](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/55de824913a7e0a1677cacbcd81a30265333dd49))


### Bug Fixes

* correct DllCalls that passed parameters as VarRef instead of plain Buffer objects ([2e76fdd](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/2e76fdd760312a81654c5c4866520da6841b3fb9))


### Code Refactoring

* merge class Voicemeeter.Remote with Voicemeeter ([d628768](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/d6287685c6307487a6ede58642b88bd4d7048e90))
* move logic into class contained within the top-level class ([2a70b77](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/2a70b7715bfc4bb6934467c91718627d2314f105))
* remove redundant class names ([afeef6b](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/afeef6bf9de5fbe2b82274b75c8a6ca236b88996))
* remove the vmType constructor param and related startup logic ([6bddf65](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/6bddf6592ccb2ac1a79f5891fb764b046ff86495))
* rename VoicemeeterRemote.ahk to Voicemeeter.ahk ([b69b869](https://github.com/JakobShoemaker/ahk-voicemeeter/commit/b69b869fde31ee27d40e27e26ea313d2bc47f300))
