$drivemap = "P:"
; Map $drivemap drive to \\bng-sam\homes\ using current user
DriveMapAdd($drivemap, "\\bng-sam\homes")
; Get details of the mapping
MsgBox(0, "Drive P: is mapped to", DriveMapGet($drivemap))
