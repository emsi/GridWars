SuperStrict

Import "../gameinput.bmx"
Import BRL.StandardIO

' Real SDL virtual devices exercise mapping, hotplug and polling, without hardware.
Extern "C"
	Function SDL_JoystickAttachVirtual:Int(kind:Int, axes:Int, buttons:Int, hats:Int)
	Function SDL_JoystickDetachVirtual:Int(index:Int)
	Function SDL_JoystickSetVirtualAxis:Int(handle:Byte Ptr, axis:Int, value:Short)
	Function SDL_JoystickSetVirtualButton:Int(handle:Byte Ptr, button:Int, value:Byte)
End Extern

Type TTestPad
	Field index:Int
	Field joystick:Byte Ptr

	Method New()
		index = SDL_JoystickAttachVirtual(1, 6, 21, 0)
		Assert index >= 0, "Could not create SDL virtual controller"
		Assert SDL_IsGameController(index), "SDL virtual controller has no mapping"
		joystick = SDL_JoystickOpen(index)
		Assert joystick, "Could not open SDL virtual controller"
	End Method

	Method Axis(axis:Int, value:Int)
		Assert SDL_JoystickSetVirtualAxis(joystick, axis, Short(value)) = 0
	End Method

	Method Button(button:Int, down:Int)
		Assert SDL_JoystickSetVirtualButton(joystick, button, Byte(down)) = 0
	End Method

	Method Close()
		SDL_JoystickClose(joystick)
		Assert SDL_JoystickDetachVirtual(index) = 0
		joystick = Null
	End Method
End Type
