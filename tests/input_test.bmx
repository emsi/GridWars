SuperStrict
Framework SDL.GLSDLMax2D
Import "virtualpad.bmx"

Graphics 320, 240, 0
Delay 50
PollGameInput()
gameInput.pauseRequested = False

Local pad:TTestPad = New TTestPad
PollGameInput()
Assert gameInput.pads.Count() = 1, "Hotplug was not discovered"
pad.Axis(0, 2000)
pad.Axis(1, -2000)
PollGameInput()
Assert gameInput.active.moveX = 0 And gameInput.active.moveY = 0, "Stick drift escaped deadzone"
Assert Not gameInput.usingPad, "Stick drift stole keyboard/mouse input"
For Local value:Int = 2000 To 12000 Step 100
	pad.Axis(0, value)
	PollGameInput()
Next
Assert gameInput.usingPad, "Slow intentional stick movement did not activate gamepad"
pad.Axis(0, 32767)
pad.Axis(1, -32768)
pad.Axis(2, -32768)
PollGameInput()
Assert gameInput.usingPad, "Stick activity did not activate gamepad"
Assert Abs(Sqr(gameInput.active.moveX^2 + gameInput.active.moveY^2)-1) < .0001, "Diagonal speed is not normalized"
Assert gameInput.active.moveY < 0 And gameInput.active.aimX = -1, "Mapped axes have wrong direction"

pad.Button(PAD_CONFIRM, True)
PollGameInput()
Assert PadHit(PAD_CONFIRM), "Confirm press missing"
Assert Not PadHit(PAD_CONFIRM), "Button press delivered twice"
For Local i:Int = 0 Until 5
	PollGameInput()
	Assert Not PadHit(PAD_CONFIRM), "Held confirm repeated"
Next
BeginInputContext()
PollGameInput()
Assert gameInput.navY = 0 And Not PadHit(PAD_CONFIRM), "Held input leaked into a new menu"
pad.Axis(0, 0); pad.Axis(1, 0); pad.Axis(2, 0)
pad.Button(PAD_CONFIRM, False)
PollGameInput()
pad.Button(PAD_DOWN, True)
PollGameInput()
Assert gameInput.navY = 1, "Dpad navigation missing"
PollGameInput()
Assert gameInput.navY = 0, "Dpad repeated without delay"
Delay 370
PollGameInput()
Assert gameInput.navY = 1, "Held dpad did not repeat"
pad.Button(PAD_DOWN, False)
PollGameInput()

pad.Axis(5, 32767)
PollGameInput()
Assert PadBombHit(), "Right trigger bomb missing"
PollGameInput()
Assert Not PadBombHit(), "Held trigger repeated bombs"
pad.Axis(5, -32768)
PollGameInput()

EmitEvent CreateEvent(EVENT_KEYDOWN, Null, KEY_W)
PollGameInput()
Assert Not gameInput.usingPad, "Keyboard did not take over"
EmitEvent CreateEvent(EVENT_KEYUP, Null, KEY_W)
BeginInputContext()
pad.Button(PAD_DOWN, True)
PollGameInput()
Assert gameInput.navY = 1, "First navigation press after keyboard input was lost"
pad.Button(PAD_DOWN, False)
PollGameInput()
pad.Button(PAD_START, True)
PollGameInput()
Assert gameInput.usingPad And PauseHit(), "Start did not switch to gamepad/pause"
pad.Button(PAD_START, False)
PollGameInput()
EmitEvent CreateEvent(EVENT_APPSUSPEND)
pad.Button(PAD_CONFIRM, True)
PollGameInput()
Assert PauseHit() And Not PadHit(PAD_CONFIRM), "Background input or missing focus pause"
EmitEvent CreateEvent(EVENT_APPRESUME)
PollGameInput()
Assert Not PadHit(PAD_CONFIRM), "Background confirm leaked on focus return"

' A second controller can take over; disconnecting the inactive one is harmless.
Local second:TTestPad = New TTestPad
PollGameInput()
second.Axis(2, 32767)
PollGameInput()
Assert gameInput.active.instance = SDL_JoystickGetDeviceInstanceID(second.index)
pad.Close()
PollGameInput()
Assert Not PauseHit(), "Disconnecting an inactive controller paused gameplay"
second.index = 0 ' SDL device indices change after removal; instance IDs do not.
second.Close()
PollGameInput()
Assert PauseHit() And Not gameInput.active, "Active controller removal did not pause"
Local reconnected:TTestPad = New TTestPad
PollGameInput()
reconnected.Button(PAD_BACK, True)
PollGameInput()
Assert MenuBack(), "Reconnected pad cannot cancel"
reconnected.Close()
PollGameInput()
EmitEvent CreateEvent(EVENT_APPTERMINATE)
PollGameInput()
Assert gameInput.quit, "Window close was not retained"
gameInput.Close()
EndGraphics()
Print "PASS: mapped axes, deadzone, hotplug, multiple pads, input switching, edges, repeats, focus and quit"
