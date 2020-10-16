#NoEnv
setbatchlines,-1
CoordMode,Pixel,Screen ; change this to client only if exclusively testing in tf2 (faster)
SetMouseDelay,-1

sleep 3000
soundplay,*-1

switchState := 0
maxSecs := 5

totalDiffCounter := 0
totalLoopCounter := 0

secLoop := 0
totalPerSecondArr := []
totalPerSecondArr.Push(secLoop)

PixelGetColor,color1,(A_ScreenWidth // 2),(A_ScreenHeight // 2),RGB
settimer,inter,1000
loop {
	Critical,On
	if (switchState = 0) {
		PixelGetColor,color2,(A_ScreenWidth // 2),(A_ScreenHeight // 2),RGB
		switchState := 1
	} else {
		PixelGetColor,color1,(A_ScreenWidth // 2),(A_ScreenHeight // 2),RGB
		switchState := 0
	}
	if (color1 != color2) {
		++totalDiffCounter
		totalPerSecondArr[totalPerSecondArr.MaxIndex()] := ++secLoop
	}
	
	++totalLoopCounter

	if (totalPerSecondArr.MaxIndex() >= (maxSecs + 1))
		break
	Critical,Off
	sleep,-1
}

loop % maxSecs
	totalPerSecondArrConcat .= totalPerSecondArr[A_Index] "`n"


msgbox,% "total loops: " totalLoopCounter "`ntotal instances of one loop not matching the previous: " totalDiffCounter " in " maxSecs " seconds`navg mismatches/sec: " (totalDiffCounter // maxSecs) "`nmismatches each second:`n" totalPerSecondArrConcat

exitapp


inter:
	secLoop := 0
	totalPerSecondArr.Push(secLoop)
return

