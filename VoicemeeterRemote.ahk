; Create a window group to ensure any version of Voicemeeter can be detected.
GroupAdd "Voicemeeter", "ahk_exe voicemeeter.exe"
GroupAdd "Voicemeeter", "ahk_exe voicemeeterpro.exe"
GroupAdd "Voicemeeter", "ahk_exe voicemeeter8.exe"

class VoicemeeterRemote {
	class VoicemeeterType {
		static Voicemeeter := 1
		static VoicemeeterBanana := 2
		static VoicemeeterPotato := 3
	}

	class DeviceType {
		static MME := 1
		static WDM := 3
		static KS := 4
		static ASIO := 5
	}

	class VoicemeeterRemoteInterface {
		__New(dllPath) {
			; Load the VoicemeeterRemote library.
			this._hModule := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

			; Get the correct string type to append to certain function names.
			strType := A_IsUnicode ? "W" : "A"

			; Login
			this.Login := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Login", "Ptr")
			this.Logout := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Logout", "Ptr")
			this.RunVoicemeeter := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_RunVoicemeeter", "Ptr")

			; General information
			this.GetVoicemeeterType := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetVoicemeeterType", "Ptr")
			this.GetVoicemeeterVersion := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetVoicemeeterVersion", "Ptr")

			; Get parameters
			this.IsParametersDirty := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_IsParametersDirty", "Ptr")
			this.GetParameterFloat := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetParameterFloat", "Ptr")
			this.GetParameterString := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetParameterString" . strType, "Ptr")

			; Get levels
			; this.GetLevel := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetLevel", "Ptr")
			; this.GetMidiMessage := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_GetMidiMessage", "Ptr")

			; Set parameters
			this.SetParameterFloat := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_SetParameterFloat", "Ptr")
			this.SetParameterString := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_SetParameterString" . strType, "Ptr")
			this.SetParameters := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", A_IsUnicode ? "VBVMR_SetParametersW" : "VBVMR_SetParameters", "Ptr")

			; Devices enumerator
			; this.Output_GetDeviceNumber := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Output_GetDeviceNumber", "Ptr")
			; this.Output_GetDeviceDesc := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Output_GetDeviceDesc" . strType, "Ptr")
			; this.Input_GetDeviceNumber := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Input_GetDeviceNumber", "Ptr")
			; this.Input_GetDeviceDesc := DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", "VBVMR_Input_GetDeviceDesc" . strType, "Ptr")
		}

		__Delete() {
			; Unload the VoicemeeterRemote library.
			DllCall("FreeLibrary", "Ptr", this._hModule)
		}
	}

	; Character size in bytes for string allocation.
	static CharWidth := A_IsUnicode ? 2 : 1

	static WindowClass := "ahk_class VBCABLE0Voicemeeter0MainWindow0"

	__New(vmType := 0) {
		this.vmType := vmType

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
		uninstallPath := ""
		try {
			; Save the current RegView setting to be restored later.
			regView := A_RegView
			; Nested try/finally block to ensure RegView is restored before exceptions are thrown.
			try {
				; Force system to read from 32-bit registry.
				SetRegView 32
				; Get Voicemeeter install folder by reading the uninstall program path from the registry.
				uninstallPath := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VB:Voicemeeter {17359A74-1236-5467}", "UninstallString")
			} finally {
				; Restore previous RegView setting.
				SetRegView regView
			}
		} catch {
			; RegRead throws an exception on a nonexistent key or value, so we assume Voicemeeter is not installed.
			throw Error("Voicemeeter is not installed")
		}
		SplitPath uninstallPath,, installDir
		return installDir
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
				if (this.vmType == VoicemeeterRemote.VoicemeeterType.Voicemeeter
					or this.vmType == VoicemeeterRemote.VoicemeeterType.VoicemeeterBanana
					or this.vmType == VoicemeeterRemote.VoicemeeterType.VoicemeeterPotato) {
					DllCall(this._vmr.RunVoicemeeter, "Int", this.vmType)
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
		value := Buffer(512 * VoicemeeterRemote.CharWidth)
		switch DllCall(this._vmr.GetParameterString, "AStr", paramName, "Ptr", &value) {
			case 0:
				return StrGet(value, A_IsUnicode ? "UTF-16" : "CP0")
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
