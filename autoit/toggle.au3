_ToggleDesktopIcons()
Func _ToggleDesktopIcons()
	Local $hwnd = WinGetHandle("Program Manager")
	Local $sClass = "[CLASS:SysListView32; INSTANCE:1]"
	$iVis = ControlCommand($hwnd, "", $sClass, "IsVisible", "")
	If Not $iVis Then
		ControlShow($hwnd, "", $sClass)
	Else
	    ControlHide($hwnd, "", $sClass)
	EndIf
EndFunc   ;==>_ToggleDesktopIcons