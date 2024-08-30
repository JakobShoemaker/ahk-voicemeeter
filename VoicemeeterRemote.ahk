class Voicemeeter {
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

	/**
	 * An enum representing a Voicemeeter application type.
	 * @enum {Integer}
	 */
	class VoicemeeterType extends Voicemeeter.VoicemeeterEnum {
		static Voicemeeter => 1
		static VoicemeeterBanana => 2
		static VoicemeeterPotato => 3
	}

	/**
	 * An enum representing an audio device type.
	 * @enum {Integer}
	 */
	class DeviceType extends Voicemeeter.VoicemeeterEnum {
		static MME => 1
		static WDM => 3
		static KS => 4
		static ASIO => 5
	}

	/**
	 * The Voicemeeter Remote DLL interface.
	 * @private
	 */
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

	/**
	 * The Voicemeeter Remote interface.
	 */
	class VoicemeeterRemote {
		/**
		 * @type {Voicemeeter.VoicemeeterRemoteInterface}
		 * @private
		 */
		_vmr := 0

		__New() {
			vmFolder := this._GetVoicemeeterInstallDir()
			dllName := A_Is64bitOS ? "VoicemeeterRemote64.dll" : "VoicemeeterRemote.dll"
			dllPath := vmFolder . "\" . dllName

			; Build an interface of function pointers.
			this._vmr := Voicemeeter.VoicemeeterRemoteInterface(dllPath)

			this._Login()
		}

		__Delete() {
			this._Logout()
		}

		/**
		 * Get the directory that contains the Voicemeeter installation from the registry.
		 * @returns {String} A string containing the path to the install directory, or an empty string if nothing was found.
		 * @private
		 */
		_GetVoicemeeterInstallDir() {
			; Cache the current RegView setting to be restored after reading the registry.
			regView := A_RegView

			; Force system to read from 32-bit registry.
			SetRegView 32

			; Get Voicemeeter install folder by reading the uninstall program path from the registry.
			uninstallString := RegRead("HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\VB:Voicemeeter {17359A74-1236-5467}", "UninstallString", "")

			; Restore previous RegView setting.
			SetRegView regView

			SplitPath uninstallString, , &installDir
			return installDir
		}

		; Login

		/**
		 * Open communication pipe with Voicemeeter.
		 * @private
		 */
		_Login() {
			result := DllCall(this._vmr.Login)
			switch result {
				case 0: ; OK
					return

				case 1: ; OK but Voicemeeter application not launched
					return

				case -1: ; Cannot get client (unexpected)
					throw Error("Unexpected error while calling VBVMR_Login: Cannot get client")

				case -2: ; Unexpected login (logout was expected before)
					this._Logout()
					this._Login()

				default:
					throw Error("Unexpected error while calling VBVMR_Login")
			}
		}

		/**
		 * Close communication pipe with Voicemeeter.
		 * @private
		 */
		_Logout() {
			result := DllCall(this._vmr.Logout)
			if (result != 0) {
				throw Error("Unexpected error while calling VBVMR_Logout")
			}
		}

		; General Information

		/**
		 * Get the Voicemeeter type.
		 * @returns {Integer}
		 */
		GetVoicemeeterType() {
			value := Buffer(4)
			switch DllCall(this._vmr.GetVoicemeeterType, "Ptr", value) {
				case 0:
					return NumGet(value, "Int")
			}
		}

		/**
		 * Get the Voicemeeter version
		 * @returns {Integer}
		 */
		GetVoicemeeterVersion() {
			value := Buffer(4)
			switch DllCall(this._vmr.GetVoicemeeterVersion, "Ptr", value) {
				case 0:
					return NumGet(value, "Int")
			}
		}

		; Get parameters

		/**
		 * Check if parameters have changed. Call this function periodically (typically every 10 or 20ms).
		 * @returns {Integer}
		 */
		IsParametersDirty() {
			return DllCall(this._vmr.IsParametersDirty)
		}

		/**
		 * Get a parameter value as a floating point number.
		 * @param {String} paramName The name of the parameter.
		 * @returns {Float}
		 */
		GetParameterFloat(paramName) {
			value := Buffer(4)
			switch DllCall(this._vmr.GetParameterFloat, "AStr", paramName, "Ptr", value) {
				case 0:
					return NumGet(value, "Float")
			}
		}

		/**
		 * Get a parameter value as a string.
		 * @param {String} paramName The name of the parameter.
		 * @returns {String}
		 */
		GetParameterString(paramName) {
			value := Buffer(1024)
			switch DllCall(this._vmr.GetParameterString, "AStr", paramName, "Ptr", value) {
				case 0:
					return StrGet(value, "UTF-16")
			}
		}

		; Set parameters

		/**
		 * Set a floating point parameter value.
		 * @param {String} paramName The name of the parameter.
		 * @param {Float} value The value to assign to the parameter.
		 */
		SetParameterFloat(paramName, value) {
			switch DllCall(this._vmr.SetParameterFloat, "AStr", paramName, "Float", value) {
				case 0:
					return
			}
		}

		/**
		 * Set a string parameter value.
		 * @param {String} paramName The name of the parameter.
		 * @param {String} value The value to assign to the parameter.
		 */
		SetParameterString(paramName, value) {
			switch DllCall(this._vmr.SetParameterString, "AStr", paramName, "Str", value) {
				case 0:
					return
			}
		}

		/**
		 * Set one or several parameters by a script.
		 * @param {String} params A string containing the script.
		 */
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

		/**
		 * Show and activate the Voicemeeter window.
		 */
		ShowVoicemeeterWindow() {
			WinShow Voicemeeter.WindowClass
			WinActivate Voicemeeter.WindowClass
		}

		/**
		 * Hide the Voicemeeter window.
		 */
		HideVoicemeeterWindow() {
			WinHide Voicemeeter.WindowClass
		}

		/**
		 * Toggles the Voicemeeter window between shown and hidden. If the window is hidden or inactive, shows and activates the window, otherwise hides the window.
		 */
		ToggleVoicemeeterWindow() {
			if WinActive(Voicemeeter.WindowClass) {
				this.HideVoicemeeterWindow()
			} else {
				this.ShowVoicemeeterWindow()
			}
		}
	}
}
