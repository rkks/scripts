;#Include <WinAPI.au3>

;Func _ShowDesktopIcons ( $_Show )
;	_WinAPI_PostMessage ( ControlGetHandle ( WinGetHandle ( '[CLASS:Progman]' ), '', '[CLASSNN:SHELLDLL_DefView1]' ), 0x00111, 0x7402, $_Show )
;EndFunc

;_ShowDesktopIcons ( 0 ) ;Hide
;Sleep ( 3000 )
;_ShowDesktopIcons ( 1 ) ;Show

Local $iMax=10
;NOTE: By keeping arr[0] to store number of elements in array, we eliminate running through complete array size.
Local $arr[$iMax] = [3, "Element 1", "Element 2", "Element 3"]
;NOTE: We use the count in $arr[0] to indicate the last item and we start from index=1
Local $count = UBound($arr)
;For $i = 1 to $arr[0]
For $i = 1 to $count - 1
    ;ConsoleWrite($arr[$i][$i] & @LF)
    MsgBox(0, "Array Element", $arr[$i] & @LF)
Next

Local  $arr[3][3] = [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
For $i = 0 to UBound($arr, 1) - 1
	For $j = 0 to UBound($arr, 2) - 1
		;ConsoleWrite("$arr[" & $i & "][" & $j & "]:=" & $arr[$i][$j] & @LF)
		MsgBox(0, "Array Element", "$arr[" & $i & "][" & $j & "]:=" & $arr[$i][$j] & @LF)
	Next 
;ConsoleWrite(@LF)
Next
