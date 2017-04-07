; MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=None, Timeout=3 ss
;MsgBox(<win-type-yes-no>,"Win Title","Win Message", <timeout>)
;Sleep(500)

Func Get_On_Top()
    $hHandle = WinGetHandle(AutoItWinGetTitle())
    WinSetOnTop($hHandle, "", 1)
EndFunc

; Run program in CMD.exe window with changed title.
Func _RunCMD($sTitle, $sCommand) ; Returns PID of Run.
	Return Run(@ComSpec & " /K title " & $sTitle & "|" & $sCommand)
EndFunc   ;==>_RunCMD

; Max number of dest
Local $rows=5
; One column for Proc Name and Another for Path
Local $cols=2
; Array to list the dest. Whenever there is a new Ping, only append to bottom and update $rows
Local $dest[$rows][$cols] = [ ["Wifi Router", "192.168.1.1"], ["TTN Gateway", "10.50.68.1"], ["Google", "google.com"], ["Trivial Conversations", "trivialconversations.com"], ["Yahoo", "yahoo.com"] ]

Local $elem = UBound($dest, 1)
MsgBox(0, "PingAlert", "Ping run begin for " & $elem & " dest!")

; ===========================================================================================
$answer = MsgBox(4, "PingRunAlert", "Invoke pathping google.com? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "PingRunAlert", "Skip pathping google.com!")
Else
	; Run the Ping
    _RunCMD("PathPing", "pathping google.com")
	Get_On_Top()
EndIf

$answer = MsgBox(4, "PingRunAlert", "Invoke tracert google.com? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "PingRunAlert", "Skip tracert google.com!")
Else
	; Run the Ping
    _RunCMD("Tracert", "tracert google.com")
	Get_On_Top()
EndIf

For $i = 0 to $elem - 1
	; Prompt the user to run the Ping - a Yes/No prompt (4 - see help file)
	$answer = MsgBox(4, "PingRunAlert", "Invoke ping " & $dest[$i][0] & "? (3sec timeout)", 3)
	If $answer = 7 Then
	    MsgBox(0, "PingRunAlert", "Skip Ping " & $dest[$i][0])
	Else
		; Run the Ping
        _RunCMD("Ping " & $dest[$i][0], "ping " & $dest[$i][1])
	EndIf
	Get_On_Top()
Next
; ===========================================================================================

MsgBox(0, "PingRunAlert", "Ping run complete. Bye!")
Exit
