;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win9x/NT
; Author:         Ravikiran K.S. (ravikiran.ks@ccpu.com)
;
; Script Function:
;   Close routine applications, allows saving work and then quits.
;

; Prompt the user to run the script - use a Yes/No prompt (4 - see help file)
$answer = MsgBox(4, "AutoClose Assistant", "Shall I close routine applications for you?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $answer = 7 Then
    MsgBox(0, "AutoClose Assistant", "Sorry Ravi.  Bye!")
    Exit
EndIf

;-----------------------------------------------------------------------------------------
; Close FindAndRunRobot
Func CloseFindAndRunRobot()
$FARR = ProcessExists("FindAndRunRobot.exe") ; Will return the PID or 0 if the process isn't found.
If $FARR Then ProcessClose($FARR)
EndFunc 

;-----------------------------------------------------------------------------------------
; Close Notepad
Func CloseTaskTable()
; Get the handle of a notepad window
$handle = WinGetHandle("Untitled - Notepad", "")
If @error Then
    MsgBox(4096, "Error", "Could not find the correct window")
Else
    ; Send some text directly to this window's edit control
	Sleep(500)
	WinClose($handle)
EndIf
EndFunc 

;-----------------------------------------------------------------------------------------
; Close Outlook
Func CloseOutlook()
$handle = WinGetHandle("Inbox - Microsoft Outlook", "")
If @error Then
    MsgBox(4096, "Error", "Could not find the correct window")
Else
    ; Send some text directly to this window's edit control
	WinClose($handle)
EndIf
EndFunc 

;-----------------------------------------------------------------------------------------
; Close Putty
Func ClosePutty()
$PUTTY = ProcessExists("Putty.exe") ; Will return the PID or 0 if the process isn't found.
If $PUTTY Then ProcessClose($PUTTY)
EndFunc 

Func PlayMusic()
; plays back a beep noise, at the frequency 500 for 1 second
;Beep(500, 1000)
SoundPlay(@WindowsDir & "\media\flourish.mid",1)
EndFunc 

Func CloseApps()
CloseTaskTable()
ClosePutty()
CloseOutlook()
CloseFindAndRunRobot()
EndFunc 

CloseApps()

; Now quit by pressing Alt-f and then x (File menu -> Exit)
;Send("!f")
;Send("x")

; Finished!
