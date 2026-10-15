SuperStrict

Import SDL.SDLGameController
Import BRL.PolledInput
Import BRL.LinkedList
Import BRL.Math

Extern "C"
	Function SDL_JoystickGetDeviceInstanceID:Int(index:Int)
	Function SDL_GameControllerUpdate()
End Extern

' SDL's mapped buttons are positions, independent of the printed face labels.
Const PAD_CONFIRM:Int = 0
Const PAD_BACK:Int = 1
Const PAD_CASE:Int = 2
Const PAD_START:Int = 6
Const PAD_RIGHT_BUMPER:Int = 10
Const PAD_UP:Int = 11
Const PAD_DOWN:Int = 12
Const PAD_LEFT:Int = 13
Const PAD_RIGHT:Int = 14
Const PAD_RIGHT_TRIGGER:Int = 21

Global padDeadzone:Float = .18
Global gameInput:TGameInput = New TGameInput

Type TMappedPad
	Field handle:Byte Ptr
	Field instance:Int
	Field buttons:Int, hits:Int
	Field moveX:Float, moveY:Float, aimX:Float, aimY:Float
	Field activityX:Float, activityY:Float, activityAimX:Float, activityAimY:Float
	Field changed:Int

	Method Sample()
		Local oldButtons:Int = buttons
		buttons = 0
		For Local i:Int = 0 To 20
			If SDL_GameControllerGetButton(handle, ESDLGameControllerButton(i)) Then buttons :| 1 Shl i
		Next
		If SDL_GameControllerGetAxis(handle, ESDLGameControllerAxis.TRIGGERRIGHT) > 16384 Then buttons :| 1 Shl PAD_RIGHT_TRIGGER
		hits = buttons & ~oldButtons
		moveX = SDL_GameControllerGetAxis(handle, ESDLGameControllerAxis.LEFTX) / 32767.0
		moveY = SDL_GameControllerGetAxis(handle, ESDLGameControllerAxis.LEFTY) / 32767.0
		aimX = SDL_GameControllerGetAxis(handle, ESDLGameControllerAxis.RIGHTX) / 32767.0
		aimY = SDL_GameControllerGetAxis(handle, ESDLGameControllerAxis.RIGHTY) / 32767.0
		RadialDeadzone(moveX, moveY, padDeadzone)
		RadialDeadzone(aimX, aimY, padDeadzone)
		' Accumulate slow movement too. A stationary held stick must not keep
		' stealing control back after the player switches to keyboard/mouse.
		changed = hits <> 0 Or ..
			((moveX <> 0 Or moveY <> 0) And (Abs(moveX-activityX) > .03 Or Abs(moveY-activityY) > .03)) Or ..
			((aimX <> 0 Or aimY <> 0) And (Abs(aimX-activityAimX) > .03 Or Abs(aimY-activityAimY) > .03))
		If changed Or (moveX = 0 And moveY = 0 And aimX = 0 And aimY = 0)
			activityX = moveX; activityY = moveY
			activityAimX = aimX; activityAimY = aimY
		EndIf
	End Method
End Type

Type TGameInput
	Field pads:TList = New TList
	Field active:TMappedPad
	Field usingPad:Int
	Field focused:Int = True
	Field quit:Int, pauseRequested:Int
	Field keyboardActivity:Int, mouseMoved:Int, mouseClicked:Int
	Field lastMouseX:Int, lastMouseY:Int
	Field navX:Int, navY:Int
	Field lastNavX:Int, lastNavY:Int, repeatX:Int, repeatY:Int
	Field blockNavigation:Int

	Method New()
		SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER)
		AddHook EmitEventHook, EventHook, Self
	End Method

	Function EventHook:Object(id:Int, data:Object, context:Object)
		Local input:TGameInput = TGameInput(context)
		Local event:TEvent = TEvent(data)
		If Not event Then Return data
		Select event.id
			Case EVENT_APPTERMINATE
				input.quit = True
			Case EVENT_APPSUSPEND
				input.focused = False
				input.pauseRequested = True
			Case EVENT_APPRESUME
				input.focused = True
			Case EVENT_KEYDOWN
				input.keyboardActivity = True
			Case EVENT_MOUSEDOWN
				input.keyboardActivity = True
				input.mouseClicked = True
		End Select
		Return data
	End Function

	Method Poll()
		PollSystem()
		SDL_GameControllerUpdate()
		Local x:Int = MouseX(), y:Int = MouseY()
		mouseMoved = mouseClicked Or x <> lastMouseX Or y <> lastMouseY
		mouseClicked = False
		lastMouseX = x
		lastMouseY = y
		For Local pad:TMappedPad = EachIn pads
			If Not SDL_GameControllerGetAttached(pad.handle)
				If active = pad
					If usingPad Then pauseRequested = True
					active = Null
					usingPad = False
				EndIf
				SDL_GameControllerClose(pad.handle)
				pads.Remove(pad)
			EndIf
		Next
		For Local index:Int = 0 Until SDL_NumJoysticks()
			If Not SDL_IsGameController(index) Then Continue
			Local instance:Int = SDL_JoystickGetDeviceInstanceID(index)
			Local found:Int = False
			For Local pad:TMappedPad = EachIn pads
				If pad.instance = instance Then found = True; Exit
			Next
			If found Then Continue
			Local handle:Byte Ptr = SDL_GameControllerOpen(index)
			If Not handle Then Continue
			Local pad:TMappedPad = New TMappedPad
			pad.handle = handle
			pad.instance = instance
			pad.Sample() ' A button held while connecting must be released first.
			pads.AddLast(pad)
			If Not active Then active = pad
		Next
		For Local pad:TMappedPad = EachIn pads
			pad.Sample()
			If pad.changed And focused Then active = pad; usingPad = True
		Next
		If (keyboardActivity Or mouseMoved) And focused Then usingPad = False
		keyboardActivity = False
		navX = 0
		navY = 0
		If active And focused And usingPad
			Local dx:Int = (active.moveX > .5) - (active.moveX < -.5)
			Local dy:Int = (active.moveY > .5) - (active.moveY < -.5)
			dx :+ ((active.buttons Shr PAD_RIGHT) & 1) - ((active.buttons Shr PAD_LEFT) & 1)
			dy :+ ((active.buttons Shr PAD_DOWN) & 1) - ((active.buttons Shr PAD_UP) & 1)
			dx = Sgn(dx)
			dy = Sgn(dy)
			If dx = 0 And dy = 0 Then blockNavigation = False
			If Not blockNavigation
				navX = RepeatDirection(dx, lastNavX, repeatX)
				navY = RepeatDirection(dy, lastNavY, repeatY)
			EndIf
		Else
			lastNavX = 0
			lastNavY = 0
		EndIf
		If Not focused Then ClearHits()
	End Method

	Method ClearHits()
		For Local pad:TMappedPad = EachIn pads
			pad.hits = 0
		Next
	End Method

	Method Close()
		For Local pad:TMappedPad = EachIn pads
			SDL_GameControllerClose(pad.handle)
		Next
		pads.Clear()
		active = Null
		RemoveHook EmitEventHook, EventHook, Self
		SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER)
	End Method
End Type

' Scale the circle outside the deadzone back to 0..1; diagonals never exceed 1.
Function RadialDeadzone(x:Float Var, y:Float Var, deadzone:Float)
	Local magnitude:Float = Sqr(x*x + y*y)
	If magnitude <= deadzone
		x = 0
		y = 0
	Else
		Local scale:Float = (Min(magnitude, 1.0)-deadzone) / (1.0-deadzone) / magnitude
		x :* scale
		y :* scale
	EndIf
End Function

Function RepeatDirection:Int(direction:Int, previous:Int Var, deadline:Int Var)
	Local now:Int = MilliSecs()
	Local result:Int
	If direction <> previous
		result = direction
		deadline = now + 350
	ElseIf direction <> 0 And now >= deadline
		result = direction
		deadline = now + 120
	EndIf
	previous = direction
	Return result
End Function

Function PollGameInput()
	gameInput.Poll()
End Function

Function BeginInputContext()
	gameInput.ClearHits()
	gameInput.blockNavigation = False
	If gameInput.active
		Local pad:TMappedPad = gameInput.active
		gameInput.blockNavigation = Abs(pad.moveX) > .5 Or Abs(pad.moveY) > .5 Or ..
			(pad.buttons & ((1 Shl PAD_UP) | (1 Shl PAD_DOWN) | (1 Shl PAD_LEFT) | (1 Shl PAD_RIGHT))) <> 0
	EndIf
	gameInput.lastNavX = 0
	gameInput.lastNavY = 0
	gameInput.navX = 0
	gameInput.navY = 0
	FlushKeys()
	FlushMouse()
End Function

Function PadHit:Int(button:Int)
	If Not gameInput.active Or Not gameInput.focused Or Not gameInput.usingPad Then Return False
	Local mask:Int = 1 Shl button
	Local hit:Int = gameInput.active.hits & mask
	gameInput.active.hits :& ~mask
	Return hit <> 0
End Function

Function PadBombHit:Int()
	Local a:Int = PadHit(PAD_CONFIRM)
	Local bumper:Int = PadHit(PAD_RIGHT_BUMPER)
	Local trigger:Int = PadHit(PAD_RIGHT_TRIGGER)
	Return a Or bumper Or trigger
End Function

Function MenuBack:Int()
	Return KeyHit(KEY_ESCAPE) Or PadHit(PAD_BACK) Or PadHit(PAD_START)
End Function

Function PauseHit:Int()
	Local requested:Int = gameInput.pauseRequested
	gameInput.pauseRequested = False
	Return requested Or KeyHit(KEY_ESCAPE) Or PadHit(PAD_START)
End Function

Function GameMoveMouse(x:Int, y:Int)
	MoveMouse(x, y)
	gameInput.lastMouseX = x
	gameInput.lastMouseY = y
End Function

Function PadName:String()
	If Not gameInput.active Then Return "No mapped gamepad connected"
	Return String.FromUTF8String(SDL_GameControllerName(gameInput.active.handle))
End Function
