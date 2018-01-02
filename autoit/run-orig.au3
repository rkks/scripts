#Region --- CodeWizard generated code Start ---
; MsgBox features: Title=Yes, Text=Yes, Buttons=Yes and No, Icon=None, Timeout=3 ss
;MsgBox(<win-type-yes-no>,"Win Title","Win Message", <timeout>)
;Sleep(500)

; 2 = Write mode (erase previous contents)
$file = FileOpen("C:\Users\raviks\pid-autoit.txt", 1)
; Check if file opened for reading OK
If $file = -1 Then
    MsgBox(0, "AppRunAlert", "Unable to open C:\pid-autoit.txt")
    Exit
EndIf

Func Get_On_Top()
    $hHandle = WinGetHandle(AutoItWinGetTitle())
    WinSetOnTop($hHandle, "", 1)
EndFunc

MsgBox(0, "AppRunAlert", "App run begin for " & $elem & " apps!")

; ===========================================================================================
; Prompt the user to run the app - a Yes/No prompt (4 - see help file)
$answer = MsgBox(4, "AppRunAlert", "Invoke app FindAndRunRobot. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app FindAndRunRobot!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\SearchTools\FindAndRunRobot\FindAndRunRobot.exe")
	; Wait for the App to become active
	;ProcessWait("FindAndRunRobot.exe")
	ProcessWait($pid)
	FileWriteLine($file, $pid)
EndIf
Get_On_Top()

; ===========================================================================================
$answer = MsgBox(4, "AppRunAlert", "Invoke app RBTray. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app RBTray!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\ProductivityTools\RBTray\64bit\RBTray.exe")
	; Wait for the App to become active
	ProcessWait($pid);
	FileWriteLine($file, $pid)
EndIf
Get_On_Top()

; ===========================================================================================
$answer = MsgBox(4, "AppRunAlert", "Invoke app Phrase Express. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app Phrase Express!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\ProductivityTools\PhraseExpress\PhraseExpress.exe")
	; Wait for the App to become active
	ProcessWait($pid);
	FileWriteLine($file, $pid)
EndIf
Get_On_Top()

; ===========================================================================================
$answer = MsgBox(4, "AppRunAlert", "Invoke app EyeRelax. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app EyeRelax!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\ProductivityTools\EyesRelax\EyesRelax.exe")
	; Wait for the App to become active
	ProcessWait($pid);
	FileWriteLine($file, $pid)
EndIf
Get_On_Top()

; ===========================================================================================
;$answer = MsgBox(4, "AppRunAlert", "Map network drive \\bng-sam\homes? (3sec timeout)", 3)
;$drivemap = "P:"
; Map $drivemap drive to \\bng-sam\homes\ using current user
;DriveMapAdd($drivemap, "\\bng-sam\homes")
; Get details of the mapping
;MsgBox(0, "Drive $drivemap is mapped to", DriveMapGet($drivemap))

; ===========================================================================================
$answer = MsgBox(4, "AppRunAlert", "Invoke app Putty. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app Putty!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\ConnectivityTools\Putty\putty.exe")
	; Wait for the App to become active
	ProcessWait($pid)
	FileWriteLine($file, $pid)
	WinWait("PuTTY Configuration","Cate&gory:")
	;ControlCommand("PuTTY Configuration","Cate&gory:","ListBox1","SelectString","bng-lnx-shell3.juniper.net")
	ControlCommand("PuTTY Configuration","Cate&gory:","ListBox1","SelectString","AAA")
	ControlClick("PuTTY Configuration","Cate&gory:","Button1")
EndIf
Get_On_Top()

; ===========================================================================================
$answer = MsgBox(4, "AppRunAlert", "Invoke app FireFox. Run? (3sec timeout)", 3)
If $answer = 7 Then
    MsgBox(0, "AppRunAlert", "Skip app FireFox!")
Else
	; Run the App
	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\Browsers\Firefox\FirefoxPortable.exe")
	; Wait for the App to become active
	ProcessWait($pid);
	FileWriteLine($file, $pid)
EndIf
Get_On_Top()

; ===========================================================================================
;$answer = MsgBox(4, "AppRunAlert", "Invoke app WordWeb. Run? (3sec timeout)", 3)
;    MsgBox(0, "AppRunAlert", "Skip app WordWeb!")
;	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\DocumentViewers\WordWeb\wweb32.exe")

; ===========================================================================================
;$answer = MsgBox(4, "AppRunAlert", "Invoke app TinyResMeter. Run? (3sec timeout)", 3)
;    MsgBox(0, "AppRunAlert", "Skip app TinyResMeter!")
;	$pid = Run("C:\Users\raviks\Desktop\Important\Tools\ProductivityTools\Tinyresmeter\tinyresmeter.exe")

FileClose($file)

MsgBox(0, "AppRunAlert", "App run complete. Bye!")
Exit
#EndRegion --- CodeWizard generated code End ---
