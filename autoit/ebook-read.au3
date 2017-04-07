;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win9x/NT
; Author:         Ravikiran K.S. (ravikiran.ks@ccpu.com)
;
; Script Function:
;   Opens startup applications, initializes apps.
;

; Prompt the user to run the script - use a Yes/No prompt (4 - see help file)
$answer = MsgBox(4, "AutoStart Assistant", "Good Day Ravi, shall I startup routine applications for you?")

; Check the user's answer to the prompt (see the help file for MsgBox return values)
; If "No" was clicked (7) then exit the script
If $answer = 7 Then
    MsgBox(0, "AutoStart Assistant", "Alright Ravi.  Bye!")
    Exit
EndIf

;-----------------------------------------------------------------------------------------
; Run FindAndRunRobot
Func FindAndRunRobot()
	Run("C:\Users\rkks\Documents\Most Basic\Search Tools\FindAndRunRobot\FindAndRunRobot.exe")
	Sleep(500)
EndFunc 

;-----------------------------------------------------------------------------------------
; Run Outlook
Func Outlook()
Run("C:\Program Files\Microsoft Office\Office12\outlook.exe")

; Wait for the Outlook become active - it is titled "Inbox - Microsoft Outlook" on English systems
WinWaitActive("[Inbox - Microsoft Outlook]")

Sleep(500)
EndFunc 

Func ReadDir()
; Shows the filenames of all files in the current directory.
$search = FileFindFirstFile("*.*")  

; Check if the search was successful
If $search = -1 Then
    MsgBox(0, "Error", "No files/directories matched the search pattern")
    Exit
EndIf

While 1
    $file = FileFindNextFile($search) 
    If @error Then ExitLoop
    
    MsgBox(4096, "File:", $file)
WEnd

; Close the search handle
FileClose($search)
EndFunc

;-----------------------------------------------------------------------------------------
Func PlayMusic()
; plays back a beep noise, at the frequency 500 for 1 second
;Beep(500, 1000)
SoundPlay(@WindowsDir & "\media\flourish.mid",1)
EndFunc 

ReadDir()
;WinActivate("[CLASS:Notepad]", "")


; Now quit by pressing Alt-f and then x (File menu -> Exit)
;Send("!f")
;Send("x")

; Finished!
