﻿class VoicemeeterRemote {
	class VoicemeeterEnum {
		/**
		 * Returns an Integer indicating whether a given integral value, or its name as a String, exists in the enumeration.
		 * @param {Integer | String} value
		 * @returns {Integer} This function returns 1 (true) if `value` is defined in the enumeration, otherwise 0 (false).
		 */
		static IsDefined(value) {
			if (value is Integer) {
				for enumValue in this {
					if (value == enumValue) {
						return true
					}
				}
				return false
			}

			if (value is String) {
				for name, _ in this {
					if (value == name) {
						return true
					}
				}
				return false
			}

			return false
		}

		static __Enum(numberOfVars) {
			OwnProps := ObjOwnProps(this)

			EnumerateOwnProps(&value, &name?) {
				while (OwnProps(&name, &value)) {
					if (value is Integer) {
						return true
					}
				}
				return false
			}

			EnumerateValues(&value) {
				return EnumerateOwnProps(&value)
			}

			EnumerateNameValuePairs(&name, &value) {
				return EnumerateOwnProps(&value, &name)
			}

			return numberOfVars == 1 ? EnumerateValues : EnumerateNameValuePairs
		}
	}

	class VoicemeeterType extends VoicemeeterRemote.VoicemeeterEnum {
		static Voicemeeter => 1
		static VoicemeeterBanana => 2
		static VoicemeeterPotato => 3
	}

	class DeviceType extends VoicemeeterRemote.VoicemeeterEnum {
		static MME => 1
		static WDM => 3
		static KS => 4
		static ASIO => 5
	}

	class VoicemeeterRemoteInterface {
		__New(dllPath) {
			; Load the VoicemeeterRemote library.
			this._hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

			GetProcAddress := (procName) => DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", procName, "Ptr")

			; Login
			this.Login := GetProcAddress("VBVMR_Login")
			this.Logout := GetProcAddress("VBVMR_Logout")
			this.RunVoicemeeter := GetProcAddress("VBVMR_RunVoicemeeter")

			; General information
			this.GetVoicemeeterType := GetProcAddress("VBVMR_GetVoicemeeterType")
			this.GetVoicemeeterVersion := GetProcAddress("VBVMR_GetVoicemeeterVersion")

			; Get parameters
			this.IsParametersDirty := GetProcAddress("VBVMR_IsParametersDirty")
			this.GetParameterFloat := GetProcAddress("VBVMR_GetParameterFloat")
			this.GetParameterString := GetProcAddress("VBVMR_GetParameterStringW")

			; Get levels
			; this.GetLevel := GetProcAddress("VBVMR_GetLevel")
			; this.GetMidiMessage := GetProcAddress("VBVMR_GetMidiMessage")

			; Set parameters
			this.SetParameterFloat := GetProcAddress("VBVMR_SetParameterFloat")
			this.SetParameterString := GetProcAddress("VBVMR_SetParameterStringW")
			this.SetParameters := GetProcAddress("VBVMR_SetParametersW")

			; Devices enumerator
			; this.Output_GetDeviceNumber := GetProcAddress("VBVMR_Output_GetDeviceNumber")
			; this.Output_GetDeviceDesc := GetProcAddress("VBVMR_Output_GetDeviceDescW")
			; this.Input_GetDeviceNumber := GetProcAddress("VBVMR_Input_GetDeviceNumber")
			; this.Input_GetDeviceDesc := GetProcAddress("VBVMR_Input_GetDeviceDescW")
		}

		__Delete() {
			; Unload the VoicemeeterRemote library.
			DllCall("FreeLibrary", "Ptr", this._hModule)
		}
	}

	static WindowClass => "ahk_class VBCABLE0Voicemeeter0MainWindow0"

	_vmType := 0

	__New(vmType?) {
		if (IsSet(vmType)) {
			this.SetVoicemeeterType(vmType)
		}

		vmFolder := this._GetVoicemeeterInstallDir()
		dllName := A_Is64bitOS ? "VoicemeeterRemote64.dll" : "VoicemeeterRemote.dll"
		dllPath := vmFolder . "\" . dllName

		; Build an interface of function pointers.
		this._vmr := VoicemeeterRemote.VoicemeeterRemoteInterface(dllPath)

		this._Login()
	}

	__Delete() {
		this._Logout()
	}

	_GetVoicemeeterInstallDir() {
		; Cache the current RegView setting to be restored after reading the registry.
		regView := A_RegView

		; Force system to read from 32-bit registry.
		SetRegView 32

		; Get Voicemeeter install folder by reading the uninstall program path from the registry.
		uninstallString := RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\VB:Voicemeeter {17359A74-1236-5467}", "UninstallString", "")

		; Restore previous RegView setting.
		SetRegView regView

		if (uninstallString) {
			SplitPath uninstallString, , &installDir
			return installDir
		} else {
			; We were unable to get UninstallString from registry, so assume Voicemeeter is not installed.
			throw Error("Voicemeeter is not installed")
		}
	}

	; Login

	_Login() {
		result := DllCall(this._vmr.Login)
		switch result {
			; OK
			case 0:
				return

			; OK but Voicemeeter application not launched
			case 1:
				if (VoicemeeterRemote.VoicemeeterType.IsDefined(this._vmType)) {
					DllCall(this._vmr.RunVoicemeeter, "Int", this._vmType)
				} else {
					throw Error("Successfully logged into Voicemeeter Remote, but Voicemeeter is not running.")
				}

			; Cannot get client (unexpected)
			case -1:
				throw Error("Unexpected error while calling VBVMR_Login: Cannot get client")

			; Unexpected login (logout was expected before)
			case -2:
				this._Logout()
				this._Login()

			default:
				throw Error("Unexpected error while calling VBVMR_Login")
		}
	}

	_Logout() {
		result := DllCall(this._vmr.Logout)
		if (result != 0) {
			throw Error("Unexpected error while calling VBVMR_Logout")
		}
	}

	; General Information

	GetVoicemeeterType() {
		value := Buffer(4)
		switch DllCall(this._vmr.GetVoicemeeterType, "Ptr", &value) {
			case 0:
				return NumGet(value, "Int")
		}
	}

	GetVoicemeeterVersion() {
		value := Buffer(4)
		switch DllCall(this._vmr.GetVoicemeeterVersion, "Ptr", &value) {
			case 0:
				return NumGet(value, "Int")
		}
	}

	; Get parameters

	IsParametersDirty() {
		return DllCall(this._vmr.IsParametersDirty)
	}

	GetParameterFloat(paramName) {
		value := Buffer(4)
		switch DllCall(this._vmr.GetParameterFloat, "AStr", paramName, "Ptr", &value) {
			case 0:
				return NumGet(value, "Float")
		}
	}

	GetParameterString(paramName) {
		value := Buffer(1024)
		switch DllCall(this._vmr.GetParameterString, "AStr", paramName, "Ptr", &value) {
			case 0:
				return StrGet(value, "UTF-16")
		}
	}

	; Set parameters

	SetParameterFloat(paramName, value) {
		switch DllCall(this._vmr.SetParameterFloat, "AStr", paramName, "Float", value) {
			case 0:
				return
		}
	}

	SetParameterString(paramName, value) {
		switch DllCall(this._vmr.SetParameterString, "AStr", paramName, "Str", value) {
			case 0:
				return
		}
	}

	SetParameters(params) {
		switch DllCall(this._vmr.SetParameters, "Str", params) {
			case 0:
				return
		}
	}

	; Misc. functions

	SetVoicemeeterType(vmType) {
		if (!(vmType is Integer)) {
			throw TypeError("Expected value type Integer, but received " . Type(vmType) . ".", this.SetVoicemeeterType.Name, vmType)
		} else if (!VoicemeeterRemote.VoicemeeterType.IsDefined(vmType)) {
			throw ValueError("Value must be a defined property in VoicemeeterRemote.VoicemeeterType.", this.SetVoicemeeterType.Name, vmType)
		}

		this._vmType := vmType
	}

	BuildParamString(values*) {
		str := ""
		for index, value in values {
			str .= value . ";"
		}
		return SubStr(str, 1, -1)
	}

	ShowVoicemeeterWindow() {
		WinShow VoicemeeterRemote.WindowClass
		WinActivate VoicemeeterRemote.WindowClass
	}

	HideVoicemeeterWindow() {
		WinHide VoicemeeterRemote.WindowClass
	}

	ToggleVoicemeeterWindow() {
		if WinActive(VoicemeeterRemote.WindowClass) {
			this.HideVoicemeeterWindow()
		} else {
			this.ShowVoicemeeterWindow()
		}
	}
}
