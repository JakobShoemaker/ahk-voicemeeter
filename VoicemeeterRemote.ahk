class Voicemeeter {
	/**
	 * A class containing helper methods for integral enumerations used by the Voicemeeter Remote SDK.
	 */
	class Enum {
		/**
		 * Determines whether a given integral value, or its name as a string, exists in the enumeration.
		 * @param {Integer | String} Value The value or name of a constant in the enumeration.
		 * @returns {Integer} 1 (true) if `Value` is defined in the enumeration, otherwise 0 (false).
		 */
		static IsDefined(Value) {
			if (Value is Integer) {
				for enumValue in this {
					if (Value == enumValue) {
						return true
					}
				}
				return false
			}

			if (Value is String) {
				for name, _ in this {
					if (Value == name) {
						return true
					}
				}
				return false
			}

			return false
		}

		/**
		 * Enumerates values of the enumeration. This method is typically not called directly. Instead, the map object is passed directly to a {@link https://www.autohotkey.com/docs/v2/lib/For.htm|for-loop}.
		 * @param {Integer} NumberOfVars The number of variables passed to the calling for-loop.
		 * @returns {Enumerator} A new {@link https://www.autohotkey.com/docs/v2/lib/Enumerator.htm|enumerator}.
		 */
		static __Enum(NumberOfVars) {
			OwnProps := ObjOwnProps(this)

			EnumerateOwnProps(&Value, &Name?) {
				while (OwnProps(&Name, &Value)) {
					if (Value is Integer) {
						return true
					}
				}
				return false
			}

			EnumerateValues(&Value) {
				return EnumerateOwnProps(&Value)
			}

			EnumerateNameValuePairs(&Name, &Value) {
				return EnumerateOwnProps(&Value, &Name)
			}

			return NumberOfVars == 1 ? EnumerateValues : EnumerateNameValuePairs
		}
	}

	/**
	 * An enum representing a Voicemeeter application type.
	 * @enum {Integer}
	 */
	class Type extends Voicemeeter.Enum {
		static Voicemeeter => 1
		static VoicemeeterBanana => 2
		static VoicemeeterPotato => 3
	}

	/**
	 * An enum representing an audio device type.
	 * @enum {Integer}
	 */
	class DeviceType extends Voicemeeter.Enum {
		static MME => 1
		static WDM => 3
		static KS => 4
		static ASIO => 5
	}

	/**
	 * A collection of function pointers for the Voicemeeter Remote DLL interface.
	 * @private
	 */
	class RemoteInterface {
		/**
		 * Loads the VoicemeeterRemote DLL and gets function pointers.
		 */
		__New(DllPath) {
			; Load the VoicemeeterRemote library.
			this._hModule := DllCall("LoadLibrary", "Str", DllPath, "Ptr")

			GetProcAddress := (ProcName) => DllCall("GetProcAddress", "Ptr", this._hModule, "AStr", ProcName, "Ptr")

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

		/**
		 * Frees the VoicemeeterRemote DLL.
		 * @private
		 */
		__Delete() {
			; Unload the VoicemeeterRemote library.
			DllCall("FreeLibrary", "Ptr", this._hModule)
		}
	}

	static WindowClass => "ahk_class VBCABLE0Voicemeeter0MainWindow0"

	/**
	 * The Voicemeeter Remote interface.
	 */
	class Remote {
		/**
		 * @type {Voicemeeter.RemoteInterface}
		 * @private
		 */
		_vmr := 0

		/**
		 * Constructs a new Voicemeeter.Remote instance. This loads the Voicemeeter Remote DLL and logs in to the server.
		 */
		__New() {
			vmFolder := this._GetVoicemeeterInstallDir()
			dllName := A_Is64bitOS ? "VoicemeeterRemote64.dll" : "VoicemeeterRemote.dll"
			dllPath := vmFolder . "\" . dllName

			; Build an interface of function pointers.
			this._vmr := Voicemeeter.RemoteInterface(dllPath)

			this._Login()
		}

		/**
		 * Logs out of the Voicemeeter server.
		 * @private
		 */
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
		 * @returns {Integer} An integer representing the type of Voicemeeter.
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
		 * @returns {Integer} An integer representing the Voicemeeter version.
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
		 * @returns {Integer} 1 (true) if parameters have changed, otherwise 0 (false).
		 */
		IsParametersDirty() {
			response := DllCall(this._vmr.IsParametersDirty)
			switch response {
				case 0, 1:
					return response
				case -1:
					throw Error("An unexpected error occurred.", this.IsParametersDirty.Name, response)
				case -2:
					throw Error("Voicemeeter is not running.", this.IsParametersDirty.Name, response)
				default:
					throw Error("An unknown error occurred.", this.IsParametersDirty.Name, response)
			}
		}

		/**
		 * Get a parameter value as a floating point number.
		 * @param {String} ParamName The name of the parameter.
		 * @returns {Float} The value of the parameter.
		 */
		GetParameterFloat(ParamName) {
			value := Buffer(4)
			switch DllCall(this._vmr.GetParameterFloat, "AStr", ParamName, "Ptr", value) {
				case 0:
					return NumGet(value, "Float")
			}
		}

		/**
		 * Get a parameter value as a string.
		 * @param {String} ParamName The name of the parameter.
		 * @returns {String} The value of the parameter.
		 */
		GetParameterString(ParamName) {
			value := Buffer(1024)
			switch DllCall(this._vmr.GetParameterString, "AStr", ParamName, "Ptr", value) {
				case 0:
					return StrGet(value, "UTF-16")
			}
		}

		; Set parameters

		/**
		 * Set a floating point parameter value.
		 * @param {String} ParamName The name of the parameter.
		 * @param {Float} Value The value to assign to the parameter.
		 */
		SetParameterFloat(ParamName, Value) {
			switch DllCall(this._vmr.SetParameterFloat, "AStr", ParamName, "Float", Value) {
				case 0:
					return
			}
		}

		/**
		 * Set a string parameter value.
		 * @param {String} ParamName The name of the parameter.
		 * @param {String} Value The value to assign to the parameter.
		 */
		SetParameterString(ParamName, Value) {
			switch DllCall(this._vmr.SetParameterString, "AStr", ParamName, "Str", Value) {
				case 0:
					return
			}
		}

		/**
		 * Set one or several parameters by a script.
		 * @param {String} Params A string containing the script.
		 */
		SetParameters(Params) {
			switch DllCall(this._vmr.SetParameters, "Str", Params) {
				case 0:
					return
			}
		}

		; Misc. functions

		/**
		 * Builds a string containing a script from a list of strings containing script statements for {@link Voicemeeter.Remote#SetParameters|SetParameters}.
		 * @param {...String} Values A string containing a script for {@link Voicemeeter.Remote#SetParameters|SetParameters}.
		 * @returns {String} A string containing each of the provided scripts.
		 */
		BuildParamString(Values*) {
			str := ""
			for index, value in Values {
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
