Func Get_On_Top()
    $hHandle = WinGetHandle(AutoItWinGetTitle())
    WinSetOnTop($hHandle, "", 1)
EndFunc

Func Open_File(ByRef $file, $filePath)
    $file = FileOpen($filePath, 2)   ; 2 = Write mode (truncate)
    If $file = -1 Then
        MsgBox(0, "AppRunAlert", "Unable to open " & $filePath)
        Exit
    EndIf
EndFunc

Func Start_Putty($puttyPath)
;    Local Const $puttyPath = "C:\Users\raviks\Desktop\Important\Tools\BasicTools\Putty\putty.exe"
    If FileExists($puttyPath) = 0 Then Return MsgBox(0, "Path Error", $puttyPath & " doesn't exist")
	$pid = Run($puttyPath)
	ProcessWait($pid)   	; Wait for the App to become active
	WinWait("PuTTY Configuration","Cate&gory:")
	ControlCommand("PuTTY Configuration","Cate&gory:","ListBox1","SelectString","AAA")
	ControlClick("PuTTY Configuration","Cate&gory:","Button1")
EndFunc

; ===========================================================================================
Local $cols=2   ; One column for Proc Name, Another for Path
; $rows auto-computed
Local $apps[][$cols] = [ ["FindAndRunRobot", "C:\Users\raviks\Desktop\Important\Tools\BasicTools\FindAndRunRobot\FindAndRunRobot.exe"], ["RBTray", "C:\Users\raviks\Desktop\Important\Tools\BasicTools\RBTray\RBTray.exe"], ["GrindStone", "C:\Users\raviks\Desktop\Important\Tools\BasicTools\GrindStone\Grindstone 2.exe"], ["Networx", "C:\Users\raviks\Desktop\Important\Tools\BasicTools\Networx\networx.exe"] ]
;, ["Firefox", "C:\Users\raviks\Desktop\Important\Tools\BasicTools\FireFox\FirefoxPortable.exe"]
; ===========================================================================================
;Local $pidFile
;Open_File($pidFile, "C:\Users\raviks\pid-autoit.txt")
    ;	FileWriteLine($file, $pid)
;FileClose($pidFile)

Local $elem = UBound($apps, 1)
; MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=None, Timeout=3s
MsgBox(0, "AppRunAlert", "App run begin for " & $elem & " apps!")

$answer = MsgBox(4, "AppRunAlert", "Invoke app Putty. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app Putty!")
Else
    Start_Putty("C:\Users\raviks\Desktop\Important\Tools\BasicTools\Putty\putty.exe")
EndIf

For $i = 0 to $elem - 1
    If FileExists($apps[$i][1]) = 0 Then
        MsgBox(0, "Path Error", $apps[$i][1] & " doesn't exist")
        ContinueLoop
    EndIf
;    Get_On_Top()
;    $answer = MsgBox(4, "AppRunAlert", "Run: " & $apps[$i][0] & "? (3s timeout)", 3)
;    If $answer = 7 Then
;        MsgBox(0, "AppRunAlert", "Skip app " & $apps[$i][0])
;        ContinueLoop
;    Else
    	$pid = Run($apps[$i][1])
    	ProcessWait($pid)   		; Wait for the App to become active
;    Endif
Next

MsgBox(0, "AppRunAlert", "App run complete. Bye!")
Exit
