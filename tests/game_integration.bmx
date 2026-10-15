' Appended to a temporary copy of gridwars.bmx by run.py. The shipped game has
' no test hooks or virtual devices. These tests exercise the actual game screens.

Type TPadSequence
	Field pad:TTestPad
	Field frame:Int, endFrame:Int
	Field buttons:Int[500]
	Field states:Int[500]

	Method New(controller:TTestPad)
		pad = controller
		For Local i:Int = 0 Until buttons.Length
			buttons[i] = -1
		Next
		AddHook FlipHook, Tick, Self
	End Method

	Method Press(button:Int)
		endFrame :+ 8
		buttons[endFrame] = button
		states[endFrame] = True
		buttons[endFrame+2] = button
		states[endFrame+2] = False
	End Method

	Function Tick:Object(id:Int, data:Object, context:Object)
		Local sequence:TPadSequence = TPadSequence(context)
		sequence.frame :+ 1
		Assert sequence.frame < sequence.endFrame+60, "Game screen did not respond to controller sequence"
		If sequence.buttons[sequence.frame] >= 0
			sequence.pad.Button(sequence.buttons[sequence.frame], sequence.states[sequence.frame])
		EndIf
		Return data
	End Function

	Method Finish()
		Assert frame >= endFrame, "Game screen exited at frame " + frame + " before intended action " + endFrame
		RemoveHook FlipHook, Tick, Self
		For Local i:Int = 0 To 20
			pad.Button(i, False)
		Next
		PollGameInput()
		BeginInputContext()
	End Method
End Type

Function RunGameInputTests()
	part.CreateAll()
	PollGameInput()
	Assert controltype = 4, "Legacy joystick mode did not migrate"
	Assert k_move_left = KEY_Q, "Migration lost a custom keyboard binding"
	Local pad:TTestPad = New TTestPad
	PollGameInput()
	ResetGame()
	CenterPlayer()
	Local x:Float = px
	pad.Axis(0, 32767)
	pad.Axis(2, 32767)
	PollGameInput()
	UpdatePlayer()
	Assert px > x And shot_list.Count() > 0, "Mapped sticks did not move and fire in gameplay"
	pad.Axis(0, 0); pad.Axis(2, 0)
	PollGameInput()
	UpdatePlayer()
	Assert jdmx = 0 And jdmy = 0 And jdfx = 0 And jdfy = 0, "Stick release did not stop movement/fire"
	numbombs = 3; bombtime = 0
	pad.Button(PAD_CONFIRM, True)
	PollGameInput()
	UpdatePlayer()
	Assert numbombs = 2, "Bomb button did not deploy one bomb"
	bombtime = 0
	PollGameInput()
	UpdatePlayer()
	Assert numbombs = 2, "Held button deployed a second bomb"
	pad.Button(PAD_CONFIRM, False)
	PollGameInput()
	controltype = 2
	EmitEvent CreateEvent(EVENT_KEYDOWN, Null, k_move_right)
	x = px
	PollGameInput()
	UpdatePlayer()
	Assert px > x And Not gameInput.usingPad, "Keyboard movement did not take over"
	EmitEvent CreateEvent(EVENT_KEYUP, Null, k_move_right)
	PollGameInput()
	controltype = 4

	' Options -> Settings -> Controls -> deadzone, then keyboard binding cancel.
	Local before:Float = padDeadzone
	Local binding:Int = k_bomb
	Local sequence:TPadSequence = New TPadSequence(pad)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_CONFIRM)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_CONFIRM)
	sequence.Press(PAD_DOWN)
	sequence.Press(PAD_RIGHT)
	sequence.Press(PAD_DOWN)
	sequence.Press(PAD_CONFIRM)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_CONFIRM)
	sequence.Press(PAD_BACK)
	sequence.Press(PAD_BACK)
	sequence.Press(PAD_BACK)
	sequence.Press(PAD_BACK)
	sequence.Press(PAD_BACK)
	Assert Options(False) = 0, "Back accidentally exited the game"
	sequence.Finish()
	Assert Abs(padDeadzone-before-.01) < .001, "Controller could not reach/change the deadzone setting"
	Assert k_bomb = binding, "Cancel changed the keyboard binding"

	' Highlighting Yes and pressing Back must still cancel.
	sequence = New TPadSequence(pad)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_BACK)
	Assert Not conf(False, "Controller cancel test"), "Back accepted a destructive confirmation"
	sequence.Finish()

	' Audio/video/game settings are reachable with dpad, and leave with Back.
	sequence = New TPadSequence(pad)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_RIGHT)
	sequence.Press(PAD_BACK)
	AudioSettings(False)
	sequence.Finish()
	sequence = New TPadSequence(pad)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_BACK)
	VideoSettings(False)
	sequence.Finish()
	sequence = New TPadSequence(pad)
	sequence.Press(PAD_UP)
	sequence.Press(PAD_BACK)
	GameSettings(False)
	sequence.Finish()

	' High-score name entry needs no keyboard or OS text-entry dialog.
	pscore = 99999999
	valid = True
	Local oldLetter:Int = letter[0]
	sequence = New TPadSequence(pad)
	sequence.Press(PAD_DOWN)
	sequence.Press(PAD_RIGHT)
	sequence.Press(PAD_CASE)
	sequence.Press(PAD_CONFIRM)
	Assert score.GetHighScore() = 0, "Controller could not save a high score"
	sequence.Finish()
	Assert letter[0] <> oldLetter, "Controller did not edit high-score letters"

	' Exercise the real Main loop: start, disconnect -> pause -> reconnect/back,
	' then a window-manager close must leave through the normal save path.
	RemoveAll(True)
	playgame = False
	Local lifecycle:TGameLifecycle = New TGameLifecycle
	lifecycle.pad = pad
	AddHook FlipHook, TGameLifecycle.Tick, lifecycle
	Main()
	RemoveHook FlipHook, TGameLifecycle.Tick, lifecycle
	Assert lifecycle.stage = 5 And gameInput.quit, "Main did not pause/reconnect/quit cleanly"
	Print "PASS: gameplay, bomb edge, keyboard takeover, nested settings, cancel, high-score entry, Main disconnect pause and quit"
End Function

Type TGameLifecycle
	Field pad:TTestPad
	Field frame:Int, stage:Int, pausedCount:Int, stageFrame:Int

	Function Tick:Object(id:Int, data:Object, context:Object)
		Local test:TGameLifecycle = TGameLifecycle(context)
		test.frame :+ 1
		Assert test.frame < 600, "Main integration test timed out"
		Select test.stage
			Case 0
				If test.frame = 5 Then test.pad.Button(PAD_CONFIRM, True)
				If test.frame = 7 Then test.pad.Button(PAD_CONFIRM, False)
				If playgame And Not dying And gcount > 5
					test.pad.Close()
					test.stage = 1
					test.stageFrame = test.frame
					test.pausedCount = gcount
				EndIf
			Case 1
				If test.frame > test.stageFrame+10
					Assert gcount <= test.pausedCount+1, "Gameplay continued after controller disconnect"
					test.pad = New TTestPad
					test.stage = 2
					test.stageFrame = test.frame
				EndIf
			Case 2
				If test.frame = test.stageFrame+5 Then test.pad.Button(PAD_BACK, True)
				If test.frame = test.stageFrame+7 Then test.pad.Button(PAD_BACK, False)
				If gcount > test.pausedCount+3
					EmitEvent CreateEvent(EVENT_APPSUSPEND)
					test.stage = 3
					test.stageFrame = test.frame
					test.pausedCount = gcount
				EndIf
			Case 3
				If test.frame > test.stageFrame+10
					Assert gcount <= test.pausedCount+1, "Gameplay continued after focus loss"
					EmitEvent CreateEvent(EVENT_APPRESUME)
					test.stage = 4
					test.stageFrame = test.frame
				EndIf
			Case 4
				If test.frame = test.stageFrame+5 Then test.pad.Button(PAD_BACK, True)
				If test.frame = test.stageFrame+7 Then test.pad.Button(PAD_BACK, False)
				If gcount > test.pausedCount+3
					EmitEvent CreateEvent(EVENT_APPTERMINATE)
					test.stage = 5
					test.pad.Close()
				EndIf
		End Select
		Return data
	End Function
End Type
