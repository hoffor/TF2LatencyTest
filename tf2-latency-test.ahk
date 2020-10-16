/*
------------------------------------------------------------------------------------------------------------------

,--------.,------. ,---.     ,--.             ,--.                                    ,--------.              ,--.
'--.  .--'|  .---''.-.  \    |  |    ,--,--.,-'  '-. ,---. ,--,--,  ,---.,--. ,--.    '--.  .--',---.  ,---.,-'  '-.
   |  |   |  `--,  .-' .'    |  |   ' ,-.  |'-.  .-'| .-. :|      \| .--' \  '  /        |  |  | .-. :(  .-''-.  .-'
   |  |   |  |`   /   '-.    |  '--.\ '-'  |  |  |  \   --.|  ||  |\ `--.  \   '         |  |  \   --..-'  `) |  |
   `--'   `--'    '-----'    `-----' `--`--'  `--'   `----'`--''--' `---'.-'  /          `--'   `----'`----'  `--'
                                                                         `---'
------------------------------------------------------------------------------------------------------------------
Get software 'input-to-frame' latency values for Team Fortress 2 
https://github.com/hoffersrc/tf2-latency-test
big fonts by http://patorjk.com/software/taag/    :)
*/

#NoTrayIcon ; if debugging, comment out this and all instances of Menu,Tray,NoIcon
#SingleInstance,force
#Persistent
#NoEnv

SetBatchLines,% batchInit := "20ms"
OnExit,ExitSub

scriptPID := DllCall("GetCurrentProcessId")
Process,Priority,scriptPID,A
SetWorkingDir,% A_ScriptDir


; --------------
; get environment info, issue warnings


version := "1.0.0"
if ("WIN_7" != OSVersion := A_OSVersion) {
	OSVersion := "Windows " . OSVersion
	win10note := "NOTE: System is not running Windows 7, so visual styles and desktop composition cannot be disabled. This means results can be up to 40% (avg ~28%) higher than the values you'd get in Win7. Regardless of how bad that sounds, they should still be good 'ballpark' estimates of your game's performance.`n`n"
	msgbox,1,% "TF2 Latency Test",% win10note "For more info, view the README."
	ifmsgbox,Cancel
	{
		msgbox,,% "TF2 Latency Test",% "Exiting script...",2
		gosub,ExitSub
	}
} else {
	OSVersion := "Windows 7"
	if (DllCall("Dwmapi\DwmIsCompositionEnabled", "Int*", dcState) = 0) {
		if (dcState > 0) {
			msgbox,1,% "TF2 Latency Test",% "Warning: On Windows 7, desktop composition must be disabled for script stability. Please view the README. For a genuinely terrible and inaccurate experience, press OK"
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
		} else {
			SysGet,titleButtonX,30
			SysGet,titleButtonY,31
			if (titleButtonX != titleButtonY) { ; if not windows 98 mode (square buttons)
				msgbox,1,% "TF2 Latency Test",% "Note: On Windows 7, visual styles, effects and animations will somewhat affect consistency of the results. Please view the README."
				ifmsgbox,Cancel
				{
					msgbox,,% "TF2 Latency Test",% "Exiting script...",2
					gosub,ExitSub
				}
			}
		}
	} else {
		msgbox,1,% "TF2 Latency Test",% "Can't get the current state of desktop composition... regardless, just be sure you've read the README and that desktop composition AND visual styles are disabled for good results."
		ifmsgbox,Cancel
		{
			msgbox,,% "TF2 Latency Test",% "Exiting script...",2
			gosub,ExitSub
		}
	}
}

DllCall("Sleep","UInt",750) ; try to lower cpu clocks if possible using process suspension-based sleep

; get cpu/gpu info to include in report
objWMIService := ComObjGet("winmgmts:\\.\root\cimv2")
for gpu in objWMIService.ExecQuery("SELECT * FROM Win32_VideoController")
	gpuName := gpu.Name

currentClockArr := []
for cpu in objWMIService.ExecQuery("SELECT * FROM Win32_Processor") {
	cpuNameNoTrim := cpu.Name
    cpuName = %cpuNameNoTrim% ; autotrim needs traditional assignment
	maxClock := cpu.MaxClockSpeed
	currentClockArr[1] := cpu.CurrentClockSpeed
}
DllCall("Sleep","UInt",500)
loop 10 { ; many samples so we can be sure
	for cpu in objWMIService.ExecQuery("SELECT CurrentClockSpeed FROM Win32_Processor")
		currentClockArr[A_Index + 1] := cpu.CurrentClockSpeed
	DllCall("Sleep","UInt",50)
}
currentClock := Min(currentClockArr*)

if (currentClock != "" && maxClock != "") {
	if (currentClock <= maxClock * 0.98) {
		msgbox,1,% "TF2 Latency Test", % "Warning: CPU clock speed appears to be much lower than its max. For best performance set your Windows power plan to High Performance or equivalent."
		ifmsgbox,Cancel
		{
			msgbox,,% "TF2 Latency Test",% "Exiting script...",2
			gosub,ExitSub
		}
	}
}

; -----------


msgbox,1,% "TF2 Latency Test",% "TF2 Latency Test v" . version . " (github.com/hoffersrc/tf2-latency-test)`n`nBe sure to have read the README's instructions prior to running the test. Once TF2 is running and fully loaded in, press OK and then click into the game window to start and connect to the test map.`n`nTime estimate: 10 iterations = ~25sec"
ifmsgbox,Cancel
{
	msgbox,,% "TF2 Latency Test",% "Exiting script...",2
	gosub,ExitSub
}
Menu,Tray,Icon
gosub,LatencyTest
return


PlzExit:
	Critical,On
	gosub,ExitSub
return



LatencyTest:
	Critical,Off
	setbatchlines,-1
	CoordMode,Mouse,Client
	CoordMode,Pixel,Client
	SetMouseDelay,-1
	
	
	; ----------------------------------
	; Environment prep:
	
	appDetectTs := TS()
	detectmsg := 1
	while (windowName != "Team Fortress 2" || gamePath = "") {
		if (detectmsg = 1 && (TS() - appDetectTs >= 8000)) {
			detectmsg := 0
			msgbox,1,% "TF2 Latency Test",% "Problem finding game window or process. Be sure to click into the window. Waiting..."
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
		}
		; using active window pid before getting its path allows to distinguish btwn any concurrent/sandboxed instances
		WinGet,processID,PID,A
		WinGetTitle,windowName,% "ahk_pid " . processID
		if (windowName = "Team Fortress 2") {
			WinGet,gamePath,ProcessPath,% "ahk_pid " . processID
		}
		sleep,500
	}
	StringTrimRight,gamePath,gamePath,8
	
	
	; make sure window and therefore dot is centered with screen regardless of game resolution
	scrnW_half := A_ScreenWidth // 2 ; faster than using built-in vars during test
	scrnH_half := A_ScreenHeight // 2
	WinGetPos,,,tf2W,tf2H,% "ahk_pid " . processID
	WinMove,% "ahk_pid " . processID,,(A_ScreenWidth / 2)-(tf2W / 2),(A_ScreenHeight / 2)-(tf2H / 2)
	tf2W_Half := tf2W // 2
	tf2H_Half := tf2H // 2
	
	; some cvars can't be set while connected
	runwait,% "hl2.exe -hijack +disconnect",% gamePath . "\",Hide
	sleep,1000
	
	; record initial cvar values
	gosub,CvarReversionSetup
	
	; apply test cvars
	cvarsChanged := 1
	runwait,% "hl2.exe -hijack +exec latencytest",% gamePath . "\",Hide
	sleep,250 ; hl2.exe buffer
	
	
	
	; ----------------------------------
	; final user prompt / map load / prep:
	
	runwait,% "hl2.exe -hijack +map latency_test",% gamePath . "\",Hide
	
	Menu,Tray,NoIcon
	; we COULD monitor conlog for team join / status info, but...
	msgbox,1,% "TF2 Latency Test",% "Please be patient while the script is connecting you to the single player test map (it may appear stuck on main menu or frozen up but it'll get there)`n`nDuring the test strafing will be locked, mouse-look camera will routinely toggle on/off and the game scoreboard will flash.`n`nKeep your mouse in constant motion at a moderately fast pace (eg. circle, up and down, etc)`n`nPress CTRL+SHIFT+P if you want to prematurely stop the test. You may need to spam the hotkey for it to work.`n`nNow, press OK and join RED team with any class, and once you're able to control your character's mouse-look camera the test will start."
	ifmsgbox,Cancel
	{
		msgbox,,% "TF2 Latency Test",% "Exiting script...",2
		gosub,ExitSub
	}
	Menu,Tray,Icon
	
	Hotkey,^+p,PlzExit,On
	while (A_Cursor != "Unknown") {
		sleep,1000
	}
	
	; load latency cfg again in case user has combative class cfg / per slot cfg
	runwait,% "hl2.exe -hijack +exec latencytest",% gamePath . "\",Hide
	sleep,250
	
	while ((0 != WinActive(ahk_pid processID)) && (A_Cursor != "Unknown")) {
		if (A_Index = 1) {
			msgbox,1,% "TF2 Latency Test",% "Player is not controllable. Be sure to click into the window. Waiting..."
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
		}
		sleep 500
	}
	
	sendinput,i ; tf_bot_kick all in case user had tf_bots earlier
	sleep,50
	sendinput,i ; sometimes they come back...
	sleep,50
	sendinput,i ; dang bots
	sleep,300
	sendinput,j ; -showscores
	
	
	
	; ----------------------------------
	; Test loop:
	
	resupCounter := 0
	loopMax := 10 ; number of results to get
	loop % loopMax {
		
		LoopStart:
		
		while ((0 != WinActive(ahk_pid processID)) && (A_Cursor != "Unknown")) {
			if (A_Index = 1) {
				msgbox,1,% "TF2 Latency Test",% "Player is not controllable. Be sure to click into the window. Waiting..."
				ifmsgbox,Cancel
				{
					msgbox,,% "TF2 Latency Test",% "Exiting script...",2
					gosub,ExitSub
				}
			}
			sleep 500
		}
		
		gotmouse := 0
		sendinput,x ; sens 0
		sleep,50
		sendinput,b ; bot_kick all
		sleep,50
		sendinput,t ; bot_mimic 0
		sleep,200
		sendinput,u ; spawn 31 bots
		botspawns := TS()
		
		if (resupped = "") {
			sendinput,m ; resup soldier
			lastClass := "soldier"
			resupped := TS() ; record time between resups
		}
		while (TS() - resupped <= 750) ; resup has very odd cooldown, 750 seems safe
			sleep,50
		if (lastClass = "soldier") {
			; using hl2.exe for the loop in case user has combative class cfg
			runwait,% "hl2.exe -hijack +join_class demoman",% gamePath . "\",Hide
			lastClass := "demoman"
		} else {
			runwait,% "hl2.exe -hijack +join_class soldier",% gamePath . "\",Hide
			lastClass := "soldier"
		}
		resupped := TS()
		
		; additional buffer for newly spawned bot weapon draw (~1.2s total being extra safe tho)
		while (TS() - botspawns <= 1700)
			sleep,100
		
		sendinput,q ; slot3 so we don't shoot ourselves
		
		runwait,% "hl2.exe -hijack +exec latencytest",% gamePath . "\",Hide

		sleep,50
		sendinput,y ; bot_mimic 1 (was disabled cuz we want bots to have slot1, not slot3)
		
		; ensure the dot is centered in frame
		loop {
			PixelGetColor,color,% tf2W_Half,% tf2H_Half,RGB
			if (color = "0x000000")
				break
			else
				goto,LoopStart
		}

		; get scouts in bottom left corner of their baby jails
		sendinput,{a down}{s down}
		sleep,200
		sendinput,{a up}{s up}

		; make scouts double jump forward
		sendinput,{Space}
		sleep,200
		sendinput,{w down}
		sendinput,{Space}
		sleep,60 ; minimum to reliably allow forward movement
		sendinput,{w up}
		sendinput,h ; +attack
		
		
		;------------
		; sample get:
		
		; we want our sample just AFTER bot command cpu spike so that we mostly record 'normal' render/event performance
		sleep,50
		
		sendinput,c ; wait 1;sens 50
		sendinput,k ; "exec showscores". contains "+showscores", allows us to run it without -showscores. had trouble holding keys during the test for some reason, might fix
		
		sleep,50
		PixelGetColor,scoreboardDotColor,% tf2W_Half,% tf2H_Half,RGB
		sleep,50
		sendinput,j ; -showscores
		
		
		; WAIT FOR MOUSE MOVEMENT & TIME PIXEL COLOR CHANGE
		
		; ultimately i'm going with mouse-on-scoreboard/A_Cursor as the method of detecting mouse movement.
		; when cursor is locked in 'mouselook' mode, it uses state "Unknown". when in game menus, "1". windows: "Arrow/etc".
		;
		; this method turns on mouse-on-scoreboard mode, brings up and dismisses scoreboard, and waits for mouse state to
		; change from "1" to "Unknown".
		;
		; this method reports identical values to suddenly moving mouse while waiting for cursor pos change. in addition,
		; there is no reason for me to believe that once cursor changes modes there'd be an extra waiting period before
		; character view is allowed to move. even though when dismissing, scoreboard can last for a single frame after
		; cursor state changes, that doesn't mean it isn't processing mouselook during that frame
		
		; here's a list of methods that do not reliably detect the game's registration of mouselook:
		; - solely detecting mouse movement: game cursor does not move like traditional cursor. if cursor is moving,
		;   position must be off-center. with the 'move mouse in circles' method as required when using bots with specific
		;   sample timings, mouse will always be off-center including when scoreboard is shown
		;
		; - winapi mouse_event -!! TEST THIS WITH A_CURSOR PLZ !!- even when running on separate thread seems to have delay
		
		; on my system in tf2, in a loop pixelgetcolor can run at 45KHz. with desktop composition on: 30Hz. yikes
		; mousegetpos in tf2 while mouse moves: 675Khz
		sampleTs := TS()
		loop {
			ts1 := TS()
			if (A_Cursor = "Unknown") ; on the instant that cursor mode indicates that character view is movable
				break
			; NOTE: we're discarding potential 150ms+ samples by doing this, but those are very unlikely
			if (ts1 - sampleTs > 150)
				goto,LoopStart
		}
		loop 300 { ; if mouse is in fact moving
			; 1/2 samples will likely take 100-300 loops to catch mouse
			; lower loop counts mean more 'failures' and much longer overall test time (wrist pain)
			mouseIndex := A_Index
			MouseGetPos,OutputVarX,OutputVarY
			if (OutputVarX != tf2W_Half || OutputVarY != tf2H_Half)
				gotmouse := 1
			if (A_Index = 300) {
				if (gotmouse = 0)
					goto,LoopStart
				else
					break ; enforce 300 loops always for consistent per-user data at the expense of minus ~0.2 - 0.4ms
			}
		}
		loop {
			PixelGetColor,color,% tf2W_Half,% tf2H_Half,RGB
			if (150 < (td := (TS() - ts1)))
				goto,LoopStart
			if (color != "0x000000" && color != scoreboardDotColor) {
				colorIndex := A_Index
				break ; success
			}
		}

		
		loopMetrics .= td . "ms  Mouse loops: " mouseIndex . "  Color loops: " . colorIndex . "`n"
		
		; compile data to csv
		if (td = 0)
			td := "<1"
		if (tsAll != "")
			if (A_Index = loopMax)
				tsAll := tsAll . td
			else
				tsAll := tsAll . td . ", "
		else
			tsAll := td . ", "
		
		; i've determined through trial and error that this prevents stms values in the next loop from possibly being higher
		sleep,15 ; no idea why
		
	}
	
	
	
	; ----------------------------------
	; Revert cvars and create spreadsheet:
	
	gosub,RevertCvars
	
	; construct csv
	firstRow := "Results (ms),CPU,GPU,OS,CPU max clock,Game version,Game graphics,Date/time"
	
	timedate := A_YYYY . "-" . A_MM . "-" . A_DD . "_" . A_Hour . "h" . A_Min . "m" . A_Sec . "s"
	dateSlashes := A_YYYY . "/" . A_MM . "/" . A_DD
	
	fileConstruction1 := firstRow . "`n" . """" . tsAll . """" . "," . """" . cpuName . """" . "," . """"
	fileConstruction2 :=  fileConstruction1 . gpuName . """" . "," . """" . OSVersion . """" . "," . """"
	fileConstruction3 :=  fileConstruction2 . maxClock . """" . "," . """" . gameVersion . """" . "," . """"
	fileConstruction4 :=  fileConstruction3 . gfx . """" . "," . """" . dateSlashes . """"
	
	FileAppend,% fileConstruction4,% A_WorkingDir . "\tf2-latency_" . timedate . ".csv"
	
	;msgbox,% loopMetrics
		
	Menu,Tray,NoIcon
	msgbox,1,% "TF2 Latency Test",% "Spreadsheet created:`n" A_WorkingDir . "\tf2-latency_" . timedate . ".csv`n`nYour latencies (in ms) were: " . tsAll . "`n`n" . win10note . "Would you like to submit these results?`n(Opens docs.google.com in browser & .csv in Notepad so you can copy/paste its contents)"
	ifmsgbox,OK
	{
		run,% "notepad.exe " . A_WorkingDir . "\tf2-latency_" . timedate . ".csv"
		sleep 150
		run,% "https://docs.google.com/forms/d/e/1FAIpQLSenFVEHYT3jpUcolGElqH0bZ4LISdqP2JtA8cM-ynkH1zmdmQ/viewform"
	}
	
	setbatchlines,% batchInit
	exitapp,0
	
return



CvarReversionSetup:
	; Set up cvar logging to revert later
	; Useful in case we alter archived cvars, &
	; useful so the user doesn't have to restart TF2 to reset non-archived cvars


	/*
	this section took way too long to make so here's a logo:
	   _____   ___   ___   ___                    _          
	  / __\ \ / /_\ | _ \ | _ \_____ _____ _ _ __(_)___ _ _  
	 | (__ \ V / _ \|   / |   / -_) V / -_) '_(_-< / _ \ ' \ 
	  \___| \_/_/ \_\_|_\ |_|_\___|\_/\___|_| /__/_\___/_||_|

	*/
	
	; ------------------
	; construct cvar values query

	; grab all cvar names used in latencytest.cfg
	cvarInitTotalLen := 0
	cvarInit := []
	cvarInitLen := []
	loop,read,% gamePath . "\tf\custom\latency-test\cfg\latencytest.cfg"
	{ ; loop,parse/read braces can't be on same line >:(
		if (A_LoopReadLine != "`n") {  ; skip empty lines
			loop,parse,% A_LoopReadLine,% A_Space
			{
				; unwanted keywords
				if (InStr(A_LoopReadLine,"bind") != 1
				&& InStr(A_LoopReadLine,"//") != 1
				&& InStr(A_LoopReadLine,"alias") != 1) {
					; put each cvar name in its own element, record individual/total cvar name lengths
					cvarInitElem := cvarInit.Push(A_Loopfield)
					cvarInitLen.Push(StrLen(cvarInit[cvarInitElem]))
					cvarInitTotalLen += cvarInitLen[cvarInitElem]
					break
				}
			}
		}
	}


	; make sure cvars aren't empty/wrong
	loop % cvarInit.MaxIndex() {
		if (A_Index = 1) {
			if (cvarInit[A_Index] = "" || cvarInit[A_Index] != "version") { ; version will always be first line in cfg
				msgbox,1,% "TF2 Latency Test",% "Cannot set up CVAR reversion system, proceed to alter cvars?`nError: our cfg cvar name values are not as expected"
				ifmsgbox,Cancel
				{
					msgbox,,% "TF2 Latency Test",% "Exiting script...",2
					gosub,ExitSub
				}
				return
			}
		}
		if (cvarInit[A_Index] = "") {
			msgbox,1,% "TF2 Latency Test",% "Cannot set up CVAR reversion system, proceed to alter cvars?`nError: our cfg cvar name values are not as expected"
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
			return
		}
	}

	; compile cvar names into a long semicolon separated cvar string so we can query their values
	; cvars have char limit of 255, so split our long string without cutting off individual cvar names
	lenCounter := 0
	varIndex := 0
	totalStrings := 1
	numElemsToAddToString := []
	timesToLoop := cvarInit.MaxIndex()
	; create string splits
	loop {
		++varIndex
		if (255 < (lenCounter += cvarInitLen[A_Index] + 1)) {
			numElemsToAddToString.Push(varIndex - 1) ; -1 cuz we want the previous element to be the last accepted
			varIndex := 0
			lenCounter := 0
			++timesToLoop ; make up since we skipped this one
			++totalStrings
		}
		if (--timesToLoop = 0) {
			numElemsToAddToString.Push(varIndex) ; since it's the last, we want THIS elem to be accepted
			break
		}
	}
	; this is a total fckin disaster ^ at least it works :)

	; compile em
	varIndex := 1
	cvarInitFullCmd := []
	loop % totalStrings {
		splitIndex := A_Index
		loop % numElemsToAddToString[splitIndex] {
			cvarInitFullCmd[splitIndex] := cvarInitFullCmd[splitIndex] . cvarInit[varIndex] . ";"
			++varIndex
		}
	}


	; ensure conlog file is writable
	; file must not exist, since conlog never overwrites, only appends
	if (FileExist(conlogFullPath) != "") {
		ErrorLevel := 0
		FileRecycle,% conlogFullPath
		if (ErrorLevel != 0) {
			runwait,% "hl2.exe -hijack +exec clearconlog",% gamePath . "\",Hide
			sleep,300
			FileRecycle,% conlogFullPath
			sleep 150
		}
		if (ErrorLevel != 0) {
			msgbox,1,% "TF2 Latency Test",% "Cannot set up CVAR reversion system, proceed to alter cvars?`nError: console log file is locked. To fix, set cvar ""con_logfile"" to """", then delete:`n" conlogFullPath "`nand reload the script."
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
			return
		}
	}

	; write to conlog file all cvars we'll mess with and their initial values
	conlogRelativePath := "latencytest_conlog.txt"
	conlogFullPath := gamePath . "\tf\" . conlogRelativePath
	runwait,% "hl2.exe -hijack +con_filter_enable 0 +con_logfile " . conlogRelativePath,% gamePath . "\",Hide
	sleep 200
	loop % totalStrings {  ; query relevant cvar initial states
		runwait,% "hl2.exe -hijack +" . cvarInitFullCmd[A_Index],% gamePath . "\",Hide
		sleep 250
	}

	; disable logging. literal quotes within cvar hl2.exe params do not work. must exec .cfg
	runwait,% "hl2.exe -hijack +exec clearconlog",% gamePath . "\",Hide
	sleep,200



	; -----------
	; parse conlog to get cvar names (again) and values

	cvarInitValue := []
	cvarInitValueName := []
	delimArr1 := ["Current "," value is ","."]
	delimArr2 := ["Build Label:","#"]
	arrIndex := 0
	loop,read,% conlogFullPath
	{
		if (InStr(A_LoopReadLine,""" is """) != 0 ; for "maxplayers"
		|| InStr(A_LoopReadLine,""" = """) != 0) { ; for nearly everything else
			line := StrSplit(A_LoopReadLine,"""")
			cvarInitValue.Push(line[4]) ; cvar value
			cvarInitValueName.Push(line[2]) ; cvar name (so we can verify)
			++arrIndex
		}
		if (InStr(A_LoopReadLine,"Current sv_pure value is ") != 0) { ; special treatment for a special cvar :l
			line := StrSplit(A_LoopReadLine,delimArr1)
			cvarInitValue.Push(line[3])
			cvarInitValueName.Push(line[2])
			++arrIndex
		}
		if (InStr(A_LoopReadLine,"Build Label:") != 0) {
			line := StrSplit(A_LoopReadLine,delimArr2,A_Space)
			cvarInitValue.Push(line[2])
			cvarInitValueName.Push("version")
			++arrIndex
		}

	}


	; recycle log file
	if (FileExist(conlogFullPath) != "") {
		ErrorLevel := 0
		FileRecycle,% conlogFullPath
		if (ErrorLevel != 0) {
			sleep,1000
			ErrorLevel := 0
			FileRecycle,% conlogFullPath
		}
		if (ErrorLevel != 0) {
			msgbox,1,% "TF2 Latency Test",% "Cannot set up CVAR reversion system, proceed to alter cvars?`nError: conlog file cannot be recycled. ErrorLevel: " ErrorLevel "`n" conlogFullPath
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
		}
	} else { ; yes i actually need this message
		msgbox,1,% "TF2 Latency Test",% "CVAR Reversion Warning: conlog has been utilized and now should be deleted, but does not appear to exist."
		ifmsgbox,Cancel
		{
			msgbox,,% "TF2 Latency Test",% "Exiting script...",2
			gosub,ExitSub
		}
	}

	; verify data
	if (cvarInitValueName.MaxIndex() != cvarInit.MaxIndex()) {
		if (cvarInitValueName.MaxIndex() - cvarInit.MaxIndex() > 0)
			maxval := cvarInitValueName.MaxIndex()
		else
			maxval := cvarInit.MaxIndex()
	}
	; if one array > the other, that's likely bad but we should compare elems anyway
	loop % maxval
		if (cvarInitValueName[A_Index] != cvarInit[A_Index])
			msgbox,1,% "TF2 Latency Test",% "Cannot set up CVAR reversion system, proceed to alter cvars?`nError: CVAR: """ cvarInitValueName[A_Index] """ does not match """ cvarInit[A_Index] """`nArrays have " cvarInitValueName.MaxIndex() " & " cvarInit.MaxIndex() " elements"
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}


	; writeconfig reliably records binds, less work for us
	runwait,% "hl2.exe -hijack ""+host_writeconfig latencytest_revert full""",% gamePath . "\",Hide
	sleep 250 ; hl2.exe buffer

	; add initial cvars+values to reversion file
	loop % cvarInit.MaxIndex()
		FileAppend,% "`n" . cvarInit[A_Index] . " """ . cvarInitValue[A_Index] . """",% gamePath . "\tf\cfg\latencytest_revert.cfg"



	; get game version via "version" cvar
	if (FileExist(gamePath . "\tf\tc2\") || FileExist(gamePath . "\tf\custom\tc2\"))
		versionType := "TC2 (Mastercoms)"
	else
		versionType := "TF2 (Valve)"

	loop % cvarInit.MaxIndex() {	
		if (cvarInit[A_Index] = "version") {
			versionBuild := cvarInitValue[A_Index]
			break
		} else
			msgbox,1,% "TF2 Latency Test",% "failed to get game build label from cvar: ""version"". continuing anyway..."
			ifmsgbox,Cancel
			{
				msgbox,,% "TF2 Latency Test",% "Exiting script...",2
				gosub,ExitSub
			}
	}
	gameVersion := versionType . " - " . versionBuild

return



ExitSub:
	gosub,RevertCvars
	exitapp,0
return



RevertCvars:
	if (cvarsChanged = 1) {
		; disconnect to allow for reversion of all cvars
		; also prevent user from possibly deafening themselves by triggering 31 scout shots lol
		runwait,% "hl2.exe -hijack +disconnect",% gamePath . "\",Hide
		sleep,1000
		sleep 250 ; hl2.exe buffer
		runwait,% "hl2.exe -hijack +exec latencytest_revert",% gamePath . "\",Hide
		cvarsChanged := 0
	}
return



TS() {
	DllCall("GetSystemTimeAsFileTime","Int64P",T1601)
	Return (T1601 // 10000)
}
