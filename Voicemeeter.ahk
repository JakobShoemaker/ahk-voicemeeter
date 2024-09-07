/**
 * The Voicemeeter Remote interface.
 */
class Voicemeeter {
	/**
	 * A class containing helper methods for integral enumerations used by the Voicemeeter Remote SDK. This class exists to be extended by other classes, and is not intended to be referenced directly.
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
		 * Enumerates values of the enumeration. This method is typically not called directly. Instead, the enumeration is passed directly to a {@link https://www.autohotkey.com/docs/v2/lib/For.htm|for-loop}.
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
		static Voicemeeter64 => 4
		static VoicemeeterBanana64 => 5
		static VoicemeeterPotato64 => 6
		static VbDeviceCheck => 10
		static VoicemeeterMacroButtons => 11
		static VoicemeeterStreamerView => 12
		static VoicemeeterBusMatrix8 => 13
		static VoicemeeterBusGeq15 => 14
		static Vban2Midi => 15
		static VbCableControlPanel => 20
		static VbAuxControlPanel => 21
		static VbVaio3ControlPanel => 22
		static VbVaioControlPanel => 23
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

	/**
	 * The window class of the Voicemeeter main window. This is intended to be used with AutoHotkey [window functions](https://www.autohotkey.com/docs/v2/lib/Win.htm).
	 * @type {String}
	 */
	static WindowClass => "ahk_class VBCABLE0Voicemeeter0MainWindow0"

	/**
	 * @type {Voicemeeter.RemoteInterface}
	 * @private
	 */
	_vmr := 0

	/**
	 * Constructs a new Voicemeeter instance. This loads the Voicemeeter Remote DLL and logs in to the server.
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

	/**
	 * Open communication pipe with Voicemeeter.
	 * @private
	 */
	_Login() {
		response := DllCall(this._vmr.Login)
		switch (response) {
			case 0:
				return
			case 1:
				return
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this._Login.Name, response)
			case -2:
				this._Logout()
				this._Login()
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this._Login.Name, response)
		}
	}

	/**
	 * Close communication pipe with Voicemeeter.
	 * @private
	 */
	_Logout() {
		response := DllCall(this._vmr.Logout)
		switch (response) {
			case 0:
				return
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this._Logout.Name, response)
		}
	}

	/**
	 * Get the Voicemeeter type.
	 * @returns {Integer} An integer representing the type of Voicemeeter.
	 */
	GetVoicemeeterType() {
		value := Buffer(4)
		response := DllCall(this._vmr.GetVoicemeeterType, "Ptr", value)
		switch (response) {
			case 0:
				return NumGet(value, "Int")
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.GetVoicemeeterType.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.GetVoicemeeterType.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.GetVoicemeeterType.Name, response)
		}
	}

	/**
	 * Get the Voicemeeter version.
	 * @returns {Integer} An integer representing the Voicemeeter version.
	 */
	GetVoicemeeterVersion() {
		value := Buffer(4)
		response := DllCall(this._vmr.GetVoicemeeterVersion, "Ptr", value)
		switch (response) {
			case 0:
				return NumGet(value, "Int")
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.GetVoicemeeterVersion.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.GetVoicemeeterVersion.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.GetVoicemeeterVersion.Name, response)
		}
	}

	/**
	 * Check if parameters have changed. Call this function periodically (typically every 10 or 20ms).
	 * @returns {Integer} 1 (true) if parameters have changed, otherwise 0 (false).
	 */
	IsParametersDirty() {
		response := DllCall(this._vmr.IsParametersDirty)
		switch (response) {
			case 0, 1:
				return response
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.IsParametersDirty.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.IsParametersDirty.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.IsParametersDirty.Name, response)
		}
	}

	/**
	 * Get a parameter value as a floating point number.
	 * @param {String} ParamName The name of the parameter.
	 * @returns {Float} The value of the parameter.
	 */
	GetParameterFloat(ParamName) {
		value := Buffer(4)
		response := DllCall(this._vmr.GetParameterFloat, "AStr", ParamName, "Ptr", value)
		switch (response) {
			case 0:
				return NumGet(value, "Float")
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.GetParameterFloat.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.GetParameterFloat.Name, response)
			case -3:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN_PARAMETER, this.GetParameterFloat.Name, response)
			case -5:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_STRUCTURE_MISMATCH, this.GetParameterFloat.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.GetParameterFloat.Name, response)
		}
	}

	/**
	 * Get a parameter value as a string.
	 * @param {String} ParamName The name of the parameter.
	 * @returns {String} The value of the parameter.
	 */
	GetParameterString(ParamName) {
		value := Buffer(1024)
		response := DllCall(this._vmr.GetParameterString, "AStr", ParamName, "Ptr", value)
		switch (response) {
			case 0:
				return StrGet(value, "UTF-16")
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.GetParameterString.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.GetParameterString.Name, response)
			case -3:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN_PARAMETER, this.GetParameterString.Name, response)
			case -5:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_STRUCTURE_MISMATCH, this.GetParameterString.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.GetParameterString.Name, response)
		}
	}

	/**
	 * Set a floating point parameter value.
	 * @param {String} ParamName The name of the parameter.
	 * @param {Float} Value The value to assign to the parameter.
	 */
	SetParameterFloat(ParamName, Value) {
		response := DllCall(this._vmr.SetParameterFloat, "AStr", ParamName, "Float", Value)
		switch (response) {
			case 0:
				return
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.SetParameterFloat.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.SetParameterFloat.Name, response)
			case -3:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN_PARAMETER, this.SetParameterFloat.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.SetParameterFloat.Name, response)
		}
	}

	/**
	 * Set a string parameter value.
	 * @param {String} ParamName The name of the parameter.
	 * @param {String} Value The value to assign to the parameter.
	 */
	SetParameterString(ParamName, Value) {
		response := DllCall(this._vmr.SetParameterString, "AStr", ParamName, "Str", Value)
		switch (response) {
			case 0:
				return
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.SetParameterString.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.SetParameterString.Name, response)
			case -3:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN_PARAMETER, this.SetParameterString.Name, response)
			default:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.SetParameterString.Name, response)
		}
	}

	/**
	 * Set one or several parameters by a script.
	 * @param {String} Params A string containing the script.
	 */
	SetParameters(Params) {
		response := DllCall(this._vmr.SetParameters, "Str", Params)
		switch (response) {
			case 0:
				return
			case -1:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.SetParameters.Name, response)
			case -2:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_NO_SERVER, this.SetParameters.Name, response)
			case -3:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.SetParameters.Name, response)
			case -4:
				throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNEXPECTED, this.SetParameters.Name, response)
			default:
				if (response > 0) {
					throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_SCRIPT_ERROR, this.SetParameters.Name, response, Params)
				} else {
					throw Voicemeeter.RemoteError(Voicemeeter.RemoteError.ERR_UNKNOWN, this.SetParameters.Name, response)
				}
		}
	}

	/**
	 * Builds a string containing a script from a list of strings containing script statements for {@link Voicemeeter#SetParameters|SetParameters}.
	 * @param {...String} Value A string containing a script for {@link Voicemeeter#SetParameters|SetParameters}.
	 * @returns {String} A string containing each of the provided scripts.
	 */
	BuildParamString(Value*) {
		str := ""
		for i in Value {
			str .= Value[i] . ";"
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

	/**
	 * An error from the Voicemeeter Remote library.
	 */
	class RemoteError extends Error {
		static ERR_UNKNOWN => 0
		static ERR_NOT_INSTALLED => 1
		static ERR_UNKNOWN_VTYPE => 2
		static ERR_UNEXPECTED => 3
		static ERR_NO_SERVER => 4
		static ERR_UNKNOWN_PARAMETER => 5
		static ERR_STRUCTURE_MISMATCH => 6
		static ERR_NO_LEVEL_AVAILABLE => 7
		static ERR_OUT_OF_RANGE => 8
		static ERR_NO_MIDI_DATA => 9
		static ERR_CANNOT_SEND_MIDI_DATA => 10
		static ERR_SCRIPT_ERROR => 11
		static ERR_CALLBACK_ALREADY_REGISTERED => 12
		static ERR_NO_CALLBACK_REGISTERED => 13
		static ERR_CALLBACK_ALREADY_UNREGISTERED => 14

		/**
		 * The error response code provided by the Voicemeeter Remote library.
		 * @type {Integer}
		 */
		Code := 0

		/**
		 * Creates a new Voicemeeter.RemoteError object.
		 * @param {Integer} ErrorType The type of error being created, typically one of the ERR_ fields of this class, such as `Voicemeeter.RemoteError.ERR_NO_SERVER`. This is used to determine the message to assign to the error object.
		 * @param {String} What The source of the error. This is typically the name of a function.
		 * @param {Integer} [Code] The response code from the Voicemeeter Remote library.
		 * @param {Any} [Extra] A value relating to the error.
		 * @protected
		 */
		__New(ErrorType, What, Code?, Extra?) {
			prefix := IsSet(Code) ? "VBVMR (" . Code . "): " : "VBVMR: "
			message := ""

			switch (ErrorType) {
				case Voicemeeter.RemoteError.ERR_NOT_INSTALLED:
					message := "Voicemeeter is not installed."
				case Voicemeeter.RemoteError.ERR_UNKNOWN_VTYPE:
					message := "Unknown Voicemeeter type number."
				case Voicemeeter.RemoteError.ERR_UNEXPECTED:
					message := "An unexpected error occurred."
				case Voicemeeter.RemoteError.ERR_NO_SERVER:
					message := "Server not found."
				case Voicemeeter.RemoteError.ERR_UNKNOWN_PARAMETER:
					message := "Unknown parameter."
				case Voicemeeter.RemoteError.ERR_STRUCTURE_MISMATCH:
					message := "Structure mismatch."
				case Voicemeeter.RemoteError.ERR_NO_LEVEL_AVAILABLE:
					message := "No level available."
				case Voicemeeter.RemoteError.ERR_OUT_OF_RANGE:
					message := "Out of range."
				case Voicemeeter.RemoteError.ERR_NO_MIDI_DATA:
					message := "No MIDI data."
				case Voicemeeter.RemoteError.ERR_CANNOT_SEND_MIDI_DATA:
					message := "Cannot send MIDI data."
				case Voicemeeter.RemoteError.ERR_SCRIPT_ERROR:
					if (IsSet(Code)) {
						message := "Script contains an error on line " . Code . "."
					} else {
						message := "Script contains an error."
					}
				default:
					message := "An unknown error occurred."
			}

			super.__New(prefix . message, What, Extra?)

			if (IsSet(Code)) {
				this.Code := Code
			}
		}
	}
}
