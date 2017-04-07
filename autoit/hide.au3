;MsgBox(0, "Warning", "Hide desktop icons")
_ShowHideIcons(@SW_HIDE)
Func _ShowHideIcons($sState)
     Local $hParent = WinGetHandle("Program Manager")
     Local $hListView = ControlGetHandle($hParent, "", "SysListView321")
     WinSetState($hListView, "", $sState)
EndFunc