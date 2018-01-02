;MsgBox(0, "Warning", "Show desktop icons")
_ShowHideIcons(@SW_SHOW)
Func _ShowHideIcons($sState)
     Local $hParent = WinGetHandle("Program Manager")
     Local $hListView = ControlGetHandle($hParent, "", "SysListView321")
     WinSetState($hListView, "", $sState)
EndFunc