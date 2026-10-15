SuperStrict

Import "gameinput.bmx"
Import BRL.Volumes
Import BRL.FileSystem
Import Pub.StdC

Import "sound.bmx"
Import "gridparttrail.bmx"
Import "vectorfont.bmx"


Global g_style:Int = 0
Global info$ = " "
Global infotimer:Int
Global mx:Int,my:Int
Global ax:Int
Global bombtime:Int = 30
Global jdmx# = 0
Global jdmy# = 0
Global jdfx# = 0
Global jdfy# = 0
Global playgame:Int = False
Global startingdifficulty:Int = 1
Global laststartingdifficulty:Int = 1
Global numplayers:Int = 3
Global numbombs:Int = 3
Global EXTRALIFE:Int = 100000
Global POWERUP:Int = 2500
Global EXTRABOMB:Int = 150000
Global mbut$[] = ["None", "Left", "Right", "Middle"]
Global onoff$[] = ["Off","On"]
Global difficulty$[] = ["Easy","Medium","Hard"]
Global NUMGFXSETS:Int = 5-1
Global lowmedhigh$[] = ["Solid","Low","Med","High","User"]
Global soundsets$[] = ["Original", "User"]

Global exbomb:Int[] = [100000,150000,250000]
Global exlife:Int[] = [75000,100000,200000]


' Slots 0 and 3 are retained only to recognize legacy configuration files.
Global control_method$[5]
control_method[0] = "Dual Analog"
control_method[1] = "Mouse"
control_method[2] = "Keyboard"
control_method[3] = "Joypad"
control_method[4] = "Keyboard + mouse"


'defaults
Global controltype:Int = 4
Global autofire:Int = 0
Global h_config:Int = 0

Global k_bomb:Int = KEY_SPACE
Global k_move_left:Int = KEY_A
Global k_move_right:Int = KEY_D
Global k_move_up:Int = KEY_W
Global k_move_down:Int = KEY_S
Global k_fire_left:Int = KEY_LEFT
Global k_fire_right:Int = KEY_RIGHT
Global k_fire_up:Int = KEY_UP
Global k_fire_down:Int = KEY_DOWN

Global m_sensitivity# = .5
Global m_bomb:Int = 2
Global m_fire:Int = 1
Global inertia# = 0.0




Function DrawTarget(x%,y%,cnt%,sz%=7)

	If cnt Mod 30 > 14
		SetColor 255,255,32
	Else
		SetColor 255,32,32
	EndIf
'	DrawLine x-12,y,x+12,y
'	DrawLine x,y-12,x,y+12

	For Local a%=0 Until 359 Step 45
		SetRotation ((cnt*8) Mod 360)+a
		DrawLine x-sz,y-sz,x+sz,y+sz
	Next
	SetRotation 0

End Function


Function ConfigDirectory:String()
	Local profileDirectory:String = getenv_("GRIDWARS_CONFIG_DIR")
	If profileDirectory <> "" Then Return profileDirectory
	Return GetUserHomeDir()+"/.config/gridwars"
End Function

Function CheckConfDir:Int()
	Local ft:Int, confdir$

	confdir$=ConfigDirectory()
	ft = FileType(confdir)
	if ft = 2
		Return True
	Else
		Local success:Int = CreateDir(confdir, True)
		If Not success Then
			info$ = "Config directory creation failed."
			infotimer = 30*4
			Return False
		EndIf
	EndIf

End Function

Function LoadConfig:Int()

	Local fh:TStream, fn$, hdir$
	Local pv$, pm$

	hdir$=GetUserHomeDir()
	fn$ = ConfigDirectory()+"/Config.txt"
	fh = OpenFile(fn$)
	If fh <> Null
		While Not Eof(fh)
			' read each line
			pm$ = ReadLine(fh)
			pv$ = ReadLine(fh)
			Select pm$
				Case "[Windowed]"
					If Pv.toupper() = "TRUE"
						windowed = True
					Else
						windowed = False
					EndIf
				Case "[Control Type]"
					If Pv.toupper() = control_method[0].toupper()
						controltype = 0 'dual analog
					ElseIf Pv.toupper() = control_method[1].toupper()
						controltype = 1 'mouse
					ElseIf Pv.toupper() = control_method[2].toupper()
						controltype = 2 'keys
					ElseIf Pv.toupper() = control_method[3].toupper()
						controltype = 3	'joypad
					ElseIf Pv.toupper() = control_method[4].toupper() Or Pv.toupper() = "HYBRID"
						controltype = 4	'hybrid
					EndIf
				Case "[Autofire]"
					autofire = Int(pv$)

				Case "[Hybrid Config]"
					h_config = Int(pv$)

				Case "[Key Bomb]"
					k_bomb = Int(pv$)
				Case "[Key Move Left]"
					k_move_left = Int(pv$)
				Case "[Key Move Right]"
					k_move_right = Int(pv$)
				Case "[Key Move Up]"
					k_move_up = Int(pv$)
				Case "[Key Move Down]"
					k_move_down = Int(pv$)
				Case "[Key Fire Left]"
					k_fire_left = Int(pv$)
				Case "[Key Fire Right]"
					k_fire_right = Int(pv$)
				Case "[Key Fire Up]"
					k_fire_up = Int(pv$)
				Case "[Key Fire Down]"
					k_fire_down = Int(pv$)

				Case "[SFX Volume]" '0-100
					sfxvol# = Float(pv$)/100.0
				Case "[Music Volume]" '0-100
					musicvol# = Float(pv$)/100.0
				Case "[Sound Set]"
					soundset = Int(pv$)
					If soundset < 0 Or soundset > 1 Then soundset = 0

				Case "[Grid Style]"
					g_style = Int(pv$)

				Case "[Grid Red]"
					g_red = Int(pv$)
				Case "[Grid Green]"
					g_green = Int(pv$)
				Case "[Grid Blue]"
					g_blue = Int(pv$)
				Case "[Grid Opacity]" '0-100
					g_opacity# = Float(pv$)/100.0
				Case "[Grid Spacing]"
					gridsize = Int(pv$)
				Case "[Full Grid]"
					fullgrid = Int(pv$)
					If fullgrid < 0 Or fullgrid > 1 Then fullgrid = 0
				Case "[Gfx Set]"
					gfxset = Int(pv$)
					If gfxset < 0 Or gfxset > NUMGFXSETS Then gfxset = 0

				Case "[Mouse Sensitivity]"
					m_sensitivity = Float(pv$)/100.0
				Case "[Mouse Fire]"
					m_fire = Int(pv$)
				Case "[Mouse Bomb]"
					m_bomb = Int(pv$)

				Case "[Show Stars]"
					showstars = Int(pv$)
				Case "[Scroll]"
					scroll = Int(pv$)
				Case "[Playfield Width]"
					playsizew = Int(pv$)
				Case "[Playfield Height]"
					playsizeh = Int(pv$)
				Case "[Screen Width]"
					screensizew = Int(pv$)
				Case "[Screen Height]"
					screensizeh = Int(pv$)

				Case "[Particle Count]"
					numparticles = Int(pv$)
					If numparticles > MAXPARTICLES Then numparticles = MAXPARTICLES
				Case "[Particle Life]"
					particlelife = Int(pv$)
					If particlelife > 500 Then particlelife = 500
				Case "[Particle Gravity]"
					gravityparticles = Int(pv$)
				Case "[Particle Decay]"
					particledecay# = Float(pv$)
					If particledecay < .01 Then particledecay = .01
					If particledecay > .9999 Then particledecay = .9999
				Case "[Particle Style]"
					particlestyle = Int(pv$)

				Case "[Difficulty]"
					startingdifficulty = Int(pv$)

				Case "[Inertia]"
					inertia# = Float(pv$)/100.0

				Case "[Gamepad Deadzone]"
					padDeadzone = Max(.05, Min(.4, Float(pv$)/100.0))

			End Select
		Wend
		' Legacy joystick modes migrate to keyboard/mouse with automatic gamepad input.
		If controltype = 0 Or controltype = 3 Then controltype = 4
		h_config = Max(0, Min(2, h_config))
		info$ = "Config file loaded."
		infotimer = 30*4
		CloseFile fh
		Return True
	Else
		info$ = "Config load failed."
		infotimer = 30*4
		Return False
	EndIf

End Function




Function SaveConfig:Int()

	Local fh:TStream, fn$, hdir$

	hdir$=GetUserHomeDir()
	fn$ = ConfigDirectory()+"/Config.txt"
	fh = WriteFile(fn$)
	If fh <> Null
		WriteLine (fh,"[Windowed]")
		If windowed
			WriteLine(fh,"True")
		Else
			WriteLine(fh,"False")
		EndIf
		WriteLine(fh,"[Control Type]")
		' Keep the on-disk name readable by the Linux branch as well.
		If controltype = 4
			WriteLine(fh,"Hybrid")
		Else
			WriteLine(fh,control_method[controltype])
		EndIf

		WriteLine(fh,"[Hybrid Config]")
		WriteLine(fh,h_config)

		WriteLine(fh,"[Autofire]")
		WriteLine(fh,autofire)

		WriteLine(fh,"[Key Bomb]")
		WriteLine(fh,k_bomb)
		WriteLine(fh,"[Key Move Left]")
		WriteLine(fh,k_move_left)
		WriteLine(fh,"[Key Move Right]")
		WriteLine(fh,k_move_right)
		WriteLine(fh,"[Key Move Up]")
		WriteLine(fh,k_move_up)
		WriteLine(fh,"[Key Move Down]")
		WriteLine(fh,k_move_down)
		WriteLine(fh,"[Key Fire Left]")
		WriteLine(fh,k_fire_left)
		WriteLine(fh,"[Key Fire Right]")
		WriteLine(fh,k_fire_right)
		WriteLine(fh,"[Key Fire Up]")
		WriteLine(fh,k_fire_up)
		WriteLine(fh,"[Key Fire Down]")
		WriteLine(fh,k_fire_down)

		WriteLine(fh,"[SFX Volume]")
		WriteLine(fh,Int(sfxvol#*100))
		WriteLine(fh,"[Music Volume]")
		WriteLine(fh,Int(musicvol#*100))
		WriteLine(fh,"[Sound Set]")
		WriteLine(fh,soundset)

		WriteLine(fh,"[Grid Style]")
		WriteLine(fh,g_style)

		WriteLine(fh,"[Grid Red]")
		WriteLine(fh,g_red)
		WriteLine(fh,"[Grid Green]")
		WriteLine(fh,g_green)
		WriteLine(fh,"[Grid Blue]")
		WriteLine(fh,g_blue)
		WriteLine(fh,"[Grid Opacity]")
		WriteLine(fh,Int(g_opacity#*100))
		WriteLine(fh,"[Grid Spacing]")
		WriteLine(fh,gridsize)
		WriteLine(fh,"[Full Grid]")
		WriteLine(fh,fullgrid)
		WriteLine(fh,"[Gfx Set]")
		WriteLine(fh,gfxset)

		WriteLine(fh,"[Show Stars]")
		WriteLine(fh,showstars)
		WriteLine(fh,"[Scroll]")
		WriteLine(fh,scroll)

		WriteLine(fh,"[Playfield Width]")
		WriteLine(fh,playsizew)
		WriteLine(fh,"[Playfield Height]")
		WriteLine(fh,playsizeh)
		WriteLine(fh,"[Screen Width]")
		WriteLine(fh,screensizew)
		WriteLine(fh,"[Screen Height]")
		WriteLine(fh,screensizeh)

		WriteLine(fh,"[Particle Count]")
		WriteLine(fh,numparticles)
		WriteLine(fh,"[Particle Life]")
		WriteLine(fh,particlelife)
		WriteLine(fh,"[Particle Gravity]")
		WriteLine(fh,gravityparticles)
		WriteLine(fh,"[Particle Decay]")
		WriteLine(fh,particledecay)
		WriteLine(fh,"[Particle Style]")
		WriteLine(fh,particlestyle)

		WriteLine(fh,"[Mouse Sensitivity]")
		WriteLine(fh,Int(m_sensitivity#*100))
		WriteLine(fh,"[Mouse Fire]")
		WriteLine(fh,m_fire)
		WriteLine(fh,"[Mouse Bomb]")
		WriteLine(fh,m_bomb)

		WriteLine(fh,"[Difficulty]")
		WriteLine(fh,startingdifficulty)

		WriteLine(fh,"[Inertia]")
		WriteLine(fh,Int(inertia#*100))

		WriteLine(fh,"[Gamepad Deadzone]")
		WriteLine(fh,Int(padDeadzone*100+.5))
		info$ = "Config file saved."
		infotimer = 30*4
		CloseFile fh
		Return True
	Else
		Return False
	EndIf
End Function




Function SaveColours:Int()

	Local fh:TStream, fn$, hdir$

	hdir$=GetUserHomeDir()
	fn$ = ConfigDirectory()+"/Colours.txt"
	fh = WriteFile(fn$)
	If fh <> Null
		WriteLine(fh,"squares")
		WriteLine(fh,COL_SQUARE_R)
		WriteLine(fh,COL_SQUARE_G)
		WriteLine(fh,COL_SQUARE_B)
		WriteLine(fh,"pinwheels")
		WriteLine(fh,COL_PIN_R)
		WriteLine(fh,COL_PIN_G)
		WriteLine(fh,COL_PIN_B)
		WriteLine(fh,"diamonds")
		WriteLine(fh,COL_DIAMOND_R)
		WriteLine(fh,COL_DIAMOND_G)
		WriteLine(fh,COL_DIAMOND_B)
		WriteLine(fh,"cubes")
		WriteLine(fh,COL_CUBE_R)
		WriteLine(fh,COL_CUBE_G)
		WriteLine(fh,COL_CUBE_B)
		WriteLine(fh,"circles")
		WriteLine(fh,COL_SEEKER_R)
		WriteLine(fh,COL_SEEKER_G)
		WriteLine(fh,COL_SEEKER_B)
		WriteLine(fh,"butterflies")
		WriteLine(fh,COL_BUTTER_R)
		WriteLine(fh,COL_BUTTER_G)
		WriteLine(fh,COL_BUTTER_B)
		WriteLine(fh,"blackholes")
		WriteLine(fh,COL_SUN_R)
		WriteLine(fh,COL_SUN_G)
		WriteLine(fh,COL_SUN_B)
		WriteLine(fh,"clone")
		WriteLine(fh,COL_CLONE_R)
		WriteLine(fh,COL_CLONE_G)
		WriteLine(fh,COL_CLONE_B)
		WriteLine(fh,"snake head")
		WriteLine(fh,COL_SNAKE_R)
		WriteLine(fh,COL_SNAKE_G)
		WriteLine(fh,COL_SNAKE_B)
		WriteLine(fh,"snake tail")
		WriteLine(fh,COL_TAIL_R)
		WriteLine(fh,COL_TAIL_G)
		WriteLine(fh,COL_TAIL_B)
		WriteLine(fh,"triangles")
		WriteLine(fh,COL_TRIANGLE_R)
		WriteLine(fh,COL_TRIANGLE_G)
		WriteLine(fh,COL_TRIANGLE_B)
		WriteLine(fh,"player")
		WriteLine(fh,COL_PLAYER_R)
		WriteLine(fh,COL_PLAYER_G)
		WriteLine(fh,COL_PLAYER_B)
		WriteLine(fh,"shots")
		WriteLine(fh,COL_SHOT_R)
		WriteLine(fh,COL_SHOT_G)
		WriteLine(fh , COL_SHOT_B)
		WriteLine(fh,"super shots")
		WriteLine(fh,COL_SHOT1_R)
		WriteLine(fh,COL_SHOT1_G)
		WriteLine(fh,COL_SHOT1_B)
		WriteLine(fh,"bouncy shots")
		WriteLine(fh,COL_SHOT2_R)
		WriteLine(fh,COL_SHOT2_G)
		WriteLine(fh , COL_SHOT2_B)
		WriteLine(fh,"bomb")
		WriteLine(fh,COL_BOMB_R)
		WriteLine(fh,COL_BOMB_G)
		WriteLine(fh,COL_BOMB_B)
		WriteLine(fh,"scores")
		WriteLine(fh,COL_SCORE_R)
		WriteLine(fh,COL_SCORE_G)
		WriteLine(fh,COL_SCORE_B)
		WriteLine(fh,"powerups")
		WriteLine(fh,COL_POWERUP_R)
		WriteLine(fh,COL_POWERUP_G)
		WriteLine(fh,COL_POWERUP_B)
		WriteLine(fh,"trail")
		WriteLine(fh,COL_TRAIL_R)
		WriteLine(fh,COL_TRAIL_G)
		WriteLine(fh,COL_TRAIL_B)

		info$ = "Colour file saved."
		infotimer = 30*4
		CloseFile fh
		Return True
	Else
		Return False
	EndIf

End Function



Function LoadColours:Int()

	Local fh:TStream, fn$, hdir$
	Local com$

	hdir$=GetUserHomeDir()
	fn$ = ConfigDirectory()+"/Colours.txt"
	fh = OpenFile(fn$)
	If fh <> Null
		com$ = ReadLine(fh)
		COL_SQUARE_R = Int(ReadLine(fh))
		COL_SQUARE_G = Int(ReadLine(fh))
		COL_SQUARE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_PIN_R = Int(ReadLine(fh))
		COL_PIN_G = Int(ReadLine(fh))
		COL_PIN_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_DIAMOND_R = Int(ReadLine(fh))
		COL_DIAMOND_G = Int(ReadLine(fh))
		COL_DIAMOND_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_CUBE_R = Int(ReadLine(fh))
		COL_CUBE_G = Int(ReadLine(fh))
		COL_CUBE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SEEKER_R = Int(ReadLine(fh))
		COL_SEEKER_G = Int(ReadLine(fh))
		COL_SEEKER_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_BUTTER_R = Int(ReadLine(fh))
		COL_BUTTER_G = Int(ReadLine(fh))
		COL_BUTTER_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SUN_R = Int(ReadLine(fh))
		COL_SUN_G = Int(ReadLine(fh))
		COL_SUN_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_CLONE_R = Int(ReadLine(fh))
		COL_CLONE_G = Int(ReadLine(fh))
		COL_CLONE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SNAKE_R = Int(ReadLine(fh))
		COL_SNAKE_G = Int(ReadLine(fh))
		COL_SNAKE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_TAIL_R = Int(ReadLine(fh))
		COL_TAIL_G = Int(ReadLine(fh))
		COL_TAIL_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_TRIANGLE_R = Int(ReadLine(fh))
		COL_TRIANGLE_G = Int(ReadLine(fh))
		COL_TRIANGLE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_PLAYER_R = Int(ReadLine(fh))
		COL_PLAYER_G = Int(ReadLine(fh))
		COL_PLAYER_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SHOT_R = Int(ReadLine(fh))
		COL_SHOT_G = Int(ReadLine(fh))
		COL_SHOT_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SHOT1_R = Int(ReadLine(fh))
		COL_SHOT1_G = Int(ReadLine(fh))
		COL_SHOT1_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SHOT2_R = Int(ReadLine(fh))
		COL_SHOT2_G = Int(ReadLine(fh))
		COL_SHOT2_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_BOMB_R = Int(ReadLine(fh))
		COL_BOMB_G = Int(ReadLine(fh))
		COL_BOMB_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_SCORE_R = Int(ReadLine(fh))
		COL_SCORE_G = Int(ReadLine(fh))
		COL_SCORE_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_POWERUP_R = Int(ReadLine(fh))
		COL_POWERUP_G = Int(ReadLine(fh))
		COL_POWERUP_B = Int(ReadLine(fh) )

		com$ = ReadLine(fh)
		COL_TRAIL_R = Int(ReadLine(fh))
		COL_TRAIL_G = Int(ReadLine(fh))
		COL_TRAIL_B = Int(ReadLine(fh) )

		info$ = "Colour file loaded."
		infotimer = 30*4
		CloseFile fh
		Return True
	Else
		info$ = "Colour file load failed."
		infotimer = 30*4
		Return False
	EndIf

End Function







Function CaptureScreen()

	GrabImage(capturedimg,0,0)

End Function

Function DrawAllStatic(sz#=1)

	SetColor 64,64,128
	SetBlend SOLIDBLEND
	If capturedimg <> Null
		SetScale sz,sz
		DrawImage capturedimg,SCREENW/2,SCREENH/2
	EndIf
	SetScale 1,1
End Function



Function Options:Int(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local ret:Int = 0
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 2+showgame
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40

	If showgame Then CaptureScreen()
	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		gameInput.pauseRequested = False
		Cls
		xx = MouseX()
		yy = MouseY()
		SetLineWidth 2
		tim = MilliSecs()
		If showgame Then DrawAllStatic(.9)
		SetColor 255,0,0
		DrawString("Options",SCREENW/2-280,SCREENH/2-lsp*3,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0, SCREENH/2-lsp,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Exit Program",SCREENW/2-280,SCREENH/2-lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Settings",SCREENW/2-280,SCREENH/2,4)
		If showgame
			If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 2
			If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
			DrawString("End Game",SCREENW/2-280,SCREENH/2+lsp,4)

			If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 3
			If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
			DrawString("Continue",SCREENW/2-280,SCREENH/2+lsp*2,4)
		Else
			If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 2
			If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
			DrawString("Continue",SCREENW/2-280,SCREENH/2+lsp,4)
		EndIf
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		Flip 1
		cnt:+1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 2+showgame

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 2+showgame Then sel = 0

		EndIf

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Or MouseHit(1) Then done = True
		If MenuBack() Or KeyHit(KEY_LEFT) Then sel = 2+showgame;done = True;bombtime = 20
		If KeyHit(KEY_RIGHT) Then done = True
		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If sel = 1 And done = True
			ret = Settings(showgame)

			done = False
			looper = 0
			bombtime = 20
			If ret = 2 And showgame
				FlushKeys()
				FlushMouse()
				Return 2
			EndIf
		EndIf
		If showgame
			If sel = 2 And done = True
				If conf(showgame,"End Game?")
					bombtime = 20
					FlushKeys()
					FlushMouse()
					Return 2
				Else
					done = False
					bombtime = 20
				EndIf
			EndIf
		EndIf
		If sel = 0 And done = True
			If conf(showgame,"Sure?")
				bombtime = 20
				FlushKeys()
				FlushMouse()
				Return 1
			Else
				done = False
				bombtime = 20
			EndIf
		EndIf
		looper :+8
	Wend
	FlushKeys()
	FlushMouse()
	If gameInput.quit Then Return 1
	Return False

End Function



Function conf:Int(showgame:Int, st$="")
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 1
	Local tim:Int
	Local lsp:Int = 40

	If st$ = "" Then st$ = "Confirm"

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		If MenuBack() Then Return False
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.8)

		SetColor 255,0,0
		DrawString(st$,SCREENW/2-280,SCREENH/2-lsp*2,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Yes",SCREENW/2-280,SCREENH/2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("No",SCREENW/2-280,SCREENH/2+lsp,4)
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		Flip 1
		cnt:+1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 1

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 1 Then sel = 0

		EndIf

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Or MouseHit(1) Then done = True
		If KeyHit(KEY_RIGHT) Then done = True
		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		looper :+8
	Wend
	If sel = 0 Then Return True Else Return False

End Function



Function Settings:Int(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local ret:Int = 0
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 4
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.8)
		SetColor 255,0,0
		DrawString("Settings",SCREENW/2-280,SCREENH/2-lsp*3,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Audio",SCREENW/2-280,SCREENH/2-lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Video",SCREENW/2-280,SCREENH/2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Controls",SCREENW/2-280,SCREENH/2+lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Game",SCREENW/2-280,SCREENH/2+lsp*2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 4
		If sel = 4 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*3,4)
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		Flip 1
		cnt:+1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 4

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 4 Then sel = 0

		EndIf

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Or MouseHit(1) Then done = True
		If MenuBack()  Or KeyHit(KEY_LEFT) Then done = True;sel = 4;bombtime = 20
		If KeyHit(KEY_RIGHT) Then done = True

		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If done = True
			Select sel
				Case 0 'audio
					AudioSettings(showgame)

					done = False
					looper = 0
					bombtime = 20
				Case 1 'video
					ret = VideoSettings(showgame)

					done = False
					looper = 0
					bombtime = 20
				Case 2 'controller
					ret = ControllerSettings(showgame)

					done = False
					looper = 0
					bombtime = 20
				Case 3 'game settings
					ret = GameSettings(showgame)

					done = False
					looper = 0
					bombtime = 20
				Case 4 ' done
					bombtime = 20
			End Select
			FlushKeys()
			FlushMouse()
		EndIf
		looper :+8
	Wend
	Return ret

End Function





Function VideoSettings:Int(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 10 ' done
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40
	If SCREENH =< 480 Then lsp = 32

	Local old_scroll:Int = scroll
	Local old_screensize:Int = screensize
	Local old_playsize:Int = playsize
	Local old_gfxset:Int = gfxset
	Local old_windowed:Int = windowed
	Local bright# = g_opacity*120
	Local col_pick:Int = 0

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()
		SetLineWidth 2
		tim = MilliSecs()
		If showgame Then DrawAllStatic(.7)
		SetColor 255,0,0
		DrawString("Video Settings",SCREENW/2-280,SCREENH/2-lsp*6,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*4,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Scroll: "+onoff$[scroll],SCREENW/2-280,SCREENH/2-lsp*4,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*3,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Screen Size: "+(screensize+1)+"/"+numgfxmodes+" "+gfxmodearr[screensize].desc$+" ("+gfxmodearr[screensize].s$+")",SCREENW/2-280,SCREENH/2-lsp*3,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*2,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Playfield Size: "+(playsize+1)+"/"+numplayfieldsizes+" "+playfieldsizes[playsize*2]+"X"+playfieldsizes[playsize*2+1],SCREENW/2-280,SCREENH/2-lsp*2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Gfx Set: "+lowmedhigh$[gfxset],SCREENW/2-280,SCREENH/2-lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*0,SCREENW,5*4) Then sel = 4
		If sel = 4 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Windowed: "+onoff$[windowed],SCREENW/2-280,SCREENH/2+lsp*0,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*1,SCREENW,5*4) Then sel = 5
		If sel = 5 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Grid Style: "+g_style,SCREENW/2-280,SCREENH/2+lsp*1,4)
		If sel = 5 Or sel = 7 Or sel = 8 Or sel = 9
			If (cnt Mod 60 = 0) Then gridpoint.Pull(Rand(0,20)*GRIDWIDTH,Rand(0,20)*GRIDHEIGHT,8,24)
		EndIf
		CycleColours()
		gridpoint.UpdateGrid()
		gridpoint.DrawGrid(g_style, True)
		gxoff = 0
		gyoff = 0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 6
		If sel = 6 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Number of Stars: "+showstars,SCREENW/2-280,SCREENH/2+lsp*2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 7
		If sel = 7 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Particle Style: "+particlestyle,SCREENW/2-280,SCREENH/2+lsp*3,4)
		If sel = 7
			If Rand(0,100) > 94 Then part.CreateFireworks(2)
		EndIf
		part.UpdateParticles(1)
		part.DrawParticles()

		SetColor 255,255,255
		SetScale 2,2
		DrawImage colourpick,SCREENW/2+74,SCREENH/2+lsp*4+14,1
		DrawImage colourpick,SCREENW/2+74,SCREENH/2+lsp*5+14,0
		SetScale 1,1
		SetColor 100,255,100
		DrawRect SCREENW/2+74+2-122+col_pick*2,SCREENH/2+lsp*4+20,2,8
		DrawRect SCREENW/2+74+2-122+bright*2,SCREENH/2+lsp*5+20,2,8
		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*4,SCREENW,5*4) Then sel = 8
		If sel = 8 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Grid Colour:",SCREENW/2-280,SCREENH/2+lsp*4,4)
		If sel = 8
			SetScale 2,2
			DrawImage colourpick,SCREENW/2+74,SCREENH/2+lsp*4+14,2
			SetScale 1,1
		EndIf

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*5,SCREENW,5*4) Then sel = 9
		If sel = 9 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Grid Bright:",SCREENW/2-280,SCREENH/2+lsp*5,4)
		If sel = 9
			SetScale 2,2
			DrawImage colourpick,SCREENW/2+74,SCREENH/2+lsp*5+14,2
			SetScale 1,1
		EndIf

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*6,SCREENW,5*4) Then sel = 10
		If sel = 10 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*6,4)


		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		cnt:+1
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		jdmx = gameInput.navX
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 10

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 10 Then sel = 0

		EndIf

		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Then done = True
		If MenuBack() Then done = True;sel = 10;bombtime = 20
		If (KeyDown(KEY_LEFT) Or MouseDown(1)) And bombtime = 0 Then jdmx = -1;bombtime = 20
		If (KeyDown(KEY_RIGHT) Or MouseDown(2)) And bombtime = 0 Then jdmx = 1;bombtime = 20
		Select sel
			Case 0
				If jdmx <> 0
					scroll = 1-scroll
				EndIf
				done = False
			Case 1
				If jdmx < 0
					screensize:-1
					If screensize < 0 Then screensize = numgfxmodes
					bombtime = 8
				EndIf
				If jdmx > 0
					screensize:+1
					If screensize > numgfxmodes Then screensize = 0
					bombtime = 8
				EndIf
				done = False
			Case 2
				If jdmx < 0
					playsize:-1
					If playsize < 0 Then playsize = numplayfieldsizes
					bombtime = 8
				EndIf
				If jdmx > 0
					playsize:+1
					If playsize > numplayfieldsizes Then playsize = 0
					bombtime = 8
				EndIf
				done = False
			Case 3
				If jdmx < 0
					gfxset:-1
					If gfxset < 0 Then gfxset = NUMGFXSETS
				EndIf
				If jdmx > 0
					gfxset:+1
					If gfxset > NUMGFXSETS Then gfxset = 0
				EndIf
				done = False
			Case 4
				If jdmx <> 0
					windowed = 1-windowed
				EndIf
				done = False
			Case 5
				If jdmx > 0
					g_style:+1
					If g_style > numgridstyles Then g_style = 0
				EndIf
				If jdmx < 0
					g_style:-1
					If g_style < 0 Then g_style = numgridstyles
				EndIf
			Case 6
				If jdmx > 0
					showstars:+100
					If showstars > MAXSTARS Then showstars = 0
					bombtime = 8
				EndIf
				If jdmx < 0
					showstars:-100
					If showstars < 0 Then showstars = MAXSTARS
					bombtime = 8
				EndIf
			Case 7
				If jdmx > 0
					particlestyle:+1
					If particlestyle > numparticlestyles Then particlestyle = 0
				EndIf
				If jdmx < 0
					particlestyle:-1
					If particlestyle < 0 Then particlestyle = numparticlestyles
				EndIf
			Case 8 ' colour
				If jdmx < 0
					col_pick:-1
					If col_pick < 0 Then col_pick = 0
					SetGridColours(col_pick)
					bombtime = 2
				EndIf
				If jdmx > 0
					col_pick:+1
					If col_pick > 119 Then col_pick = 119
					SetGridColours(col_pick)
					bombtime = 2
				EndIf
				done = False
			Case 9 ' brightness
				If jdmx < 0
					bright:-1
					If bright < 0 Then bright= 0
					g_opacity = bright/119
					bombtime = 2
				EndIf
				If jdmx > 0
					bright:+1
					If bright> 119 Then bright= 119
					g_opacity = bright/119
					bombtime = 2
				EndIf
				done = False
			Case 10
				If jdmx <> 0 Then done=True
				'exit this menu
		End Select
		looper :+8
	Wend
	If 	(old_scroll <> scroll Or ..
		old_screensize <> screensize Or ..
		old_playsize <> playsize or..
		old_gfxset <> gfxset or..
		old_windowed <> windowed)
		If conf(showgame,"Keep Changes?")
			' reload gfx, resize grid
			If setup()
				Return 2
			Else
				' can't set mode - reset to old
				scroll  = old_scroll
				screensize  = old_screensize
				playsize  = old_playsize
				gfxset = old_gfxset
				windowed = old_windowed
				SetDimensions()
				Cls
				SetColor 0,255,255
				DrawString("Unable to set Gfx Mode",20,64,3)
				DrawString("Reverting to old settings: "+gfxmodearr[screensize].s$,20,64+30,3)
				Flip 1
				Delay 2000
			EndIf
		Else
			scroll  = old_scroll
			screensize  = old_screensize
			playsize  = old_playsize
			gfxset = old_gfxset
			windowed = old_windowed
		EndIf
	EndIf
	Return False
End Function




Function SetGridColours(ind:Int)
	Local rgb:Int
	Local pm:TPixmap = LockImage:TPixmap(colourpick,1)
	rgb = ReadPixel(pm,1+ind,2)
	UnlockImage(colourpick,1)

	g_red = (rgb Shr 16) & $FF
	g_green = (rgb Shr 8) & $FF
	g_blue = rgb & $FF

End Function




Function GameSettings:Int(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 5 ' done
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40

	Local old_startingdifficulty:Int = startingdifficulty
	Local old_exlife:Int = exlife[startingdifficulty]
	Local old_exbomb:Int = exbomb[startingdifficulty]
	Local old_autofire:Int = autofire
	Local old_inertia# = inertia
	Local old_scroll:Int = scroll

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.7)
		SetColor 255,0,0
		DrawString("Game Settings",SCREENW/2-280,SCREENH/2-lsp*4,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*2,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Starting Level: "+difficulty$[startingdifficulty],SCREENW/2-280,SCREENH/2-lsp*2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Free Player: "+exlife[startingdifficulty],SCREENW/2-280,SCREENH/2-lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Free Bomb: "+exbomb[startingdifficulty],SCREENW/2-280,SCREENH/2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("AutoFire: "+onoff$[autofire],SCREENW/2-280,SCREENH/2+lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 4
		If sel = 4 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Inertia:",SCREENW/2-280,SCREENH/2+lsp*2,4)
		DrawGameRect SCREENW/2-360+240+1,SCREENH/2+lsp*2+1,inertia*300,24-2,1
		SetColor 255,255,0
		DrawGameRect SCREENW/2-360+240,SCREENH/2+lsp*2,302,24,0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 5
		If sel = 5 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*3,4)
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		cnt:+1
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		jdmx = gameInput.navX
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 5

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 5 Then sel = 0

		EndIf

		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Then done = True
		If MenuBack() Then done = True;sel = 5;bombtime = 20
		If (KeyDown(KEY_LEFT) Or MouseDown(1)) And bombtime = 0 Then jdmx = -1;bombtime = 20
		If (KeyDown(KEY_RIGHT) Or MouseDown(2)) And bombtime = 0 Then jdmx = 1;bombtime = 20
		Select sel
			Case 0
				If jdmx < 0
					startingdifficulty:-1
					If startingdifficulty < 0 Then startingdifficulty = 0
				EndIf
				If jdmx > 0
					startingdifficulty:+1
					If startingdifficulty > 2 Then startingdifficulty = 2
				EndIf
				done = False
			Case 1
				If jdmx < 0
					exlife[startingdifficulty]:-25000
					If exlife[startingdifficulty]< 25000 Then exlife[startingdifficulty]= 25000
				EndIf
				If jdmx > 0
					exlife[startingdifficulty]:+25000
					If exlife[startingdifficulty]> 300000 Then exlife[startingdifficulty]= 300000
				EndIf
				done = False
			Case 2
				If jdmx < 0
					exbomb[startingdifficulty]:-25000
					If exbomb[startingdifficulty] < 25000 Then exbomb[startingdifficulty]= 25000
				EndIf
				If jdmx > 0
					exbomb[startingdifficulty]:+25000
					If exbomb[startingdifficulty]> 300000 Then exbomb[startingdifficulty]= 300000
				EndIf
				done = False
			Case 3
				If jdmx <> 0
					autofire = 1-autofire
				EndIf
				done = False
			Case 4
				'inertia
				If jdmx < 0
					inertia:- 0.05
					If inertia< 0 Then inertia = 0
				EndIf
				If jdmx > 0
					inertia:+ 0.05
					If inertia > 1 Then inertia = 1
				EndIf
				done = False
			Case 5
				If jdmx <> 0 Then done=True
				'exit this menu
		End Select
		looper :+8
	Wend
	If 	(old_startingdifficulty <> startingdifficulty Or ..
		old_exlife <> exlife[startingdifficulty] Or ..
		old_exbomb <> exbomb[startingdifficulty] Or ..
		old_autofire <> autofire Or ..
		old_inertia <> inertia)
		If conf(showgame,"Keep Changes?")
			Return 2
		Else
			startingdifficulty = old_startingdifficulty
			exlife[startingdifficulty] = old_exlife
			exbomb[startingdifficulty] = old_exbomb
			autofire  = old_autofire
			inertia  = old_inertia
		EndIf
	EndIf
	Return False
End Function





Function AudioSettings(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 3
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40
	Local oldsoundset:Int = soundset

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.7)
		SetColor 255,0,0
		DrawString("Audio Settings",SCREENW/2-280,SCREENH/2-lsp*2,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 0
		If sel = 0
			SetColor 0,200,0
			DrawGameRect SCREENW/2+2,SCREENH/2+2,sfxvol*200,24-2,1
			SetColor 255,255,(cnt*8) Mod 255
		Else
			SetColor 0,100,0
			DrawGameRect SCREENW/2+1,SCREENH/2+1,sfxvol*200,24-2,1
			SetColor 0,200,0
		EndIf
		DrawString("SFX Volume:",SCREENW/2-280,SCREENH/2,4)
		DrawGameRect SCREENW/2,SCREENH/2,202,24,0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 1
		If sel = 1
			SetColor 0,200,0
			DrawGameRect SCREENW/2+1,SCREENH/2+lsp+1,musicvol*200,24-2,1
			SetColor 255,255,(cnt*8) Mod 255
		Else
			SetColor 0,100,0
			DrawGameRect SCREENW/2+1,SCREENH/2+lsp+1,musicvol*200,24-2,1
			SetColor 0,200,0
		EndIf
		DrawString("Music Volume:",SCREENW/2-280,SCREENH/2+lsp,4)
		DrawGameRect SCREENW/2,SCREENH/2+lsp,202,24,0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Sound Set: "+soundsets$[soundset],SCREENW/2-280,SCREENH/2+lsp*2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 3
		If sel = 3 Then SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*3,4)
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		cnt:+1
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf

		jdmy = gameInput.navY
		jdmx = gameInput.navX
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 3

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 3 Then sel = 0

		EndIf
		If (KeyDown(KEY_LEFT) Or MouseDown(1)) And bombtime = 0 Then jdmx = -1;bombtime = 20
		If (KeyDown(KEY_RIGHT) Or MouseDown(2)) And bombtime = 0 Then jdmx = 1;bombtime = 20
		Select sel
			Case 0 ' sfxvol
				If jdmx < 0
					sfxvol:- 0.05
					If sfxvol < 0 Then sfxvol = 0
					AdjustVolume()
				EndIf
				If jdmx > 0
					sfxvol:+ 0.05
					If sfxvol > 1 Then sfxvol = 1
					AdjustVolume()
				EndIf
			Case 1 ' musicvol
				If jdmx < 0
					musicvol:- 0.05
					If musicvol < 0 Then musicvol = 0
					SetMusicVolume()
				EndIf
				If jdmx > 0
					musicvol:+ 0.05
					If musicvol > 1 Then musicvol = 1
					SetMusicVolume()
				EndIf
			Case 2
				If jdmx < 0
					soundset:-1
					If soundset < 0 Then soundset = 1
				EndIf
				If jdmx > 0
					soundset:+1
					If soundset > 1 Then soundset = 0
				EndIf
				done = False
			Case 3 ' done
				If jdmx <> 0 Then done=True

		End Select

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Then done = True
		If MenuBack() Then done = True;sel = 2;bombtime = 20
		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0


		looper :+8
	Wend
	If soundset <> oldsoundset
		LoadSounds()
	EndIf

End Function





Function ControllerSettings:Int(showgame:Int)
	Local sel:Int = 0, cnt:Int, xx:Int, yy:Int
	Local labels:String[6]
	Local modes:Int[] = [4, 2, 1]
	BeginInputContext()
	While Not gameInput.quit
		PollGameInput()
		If MenuBack() Then Exit
		xx = MouseX(); yy = MouseY()
		For Local i:Int = 0 Until labels.Length
			Local row:Int = SCREENH/2-40+i*40
			If gameInput.mouseMoved And RectsOverlap(xx,yy,1,1,SCREENW/2-280,row,600,28) Then sel = i
		Next
		If KeyHit(KEY_UP) Or gameInput.navY < 0 Then sel = (sel+5) Mod 6
		If KeyHit(KEY_DOWN) Or gameInput.navY > 0 Then sel = (sel+1) Mod 6
		Local change:Int = gameInput.navX + KeyHit(KEY_RIGHT) - KeyHit(KEY_LEFT)
		Local accept:Int = KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM) Or MouseHit(1)
		If accept And sel = 5 Then Exit
		If sel = 0 And (change <> 0 Or accept)
			Local mode:Int
			For Local i:Int = 0 Until modes.Length
				If modes[i] = controltype Then mode = i
			Next
			If change < 0 Then mode = (mode+2) Mod 3 Else mode = (mode+1) Mod 3
			controltype = modes[mode]
		EndIf
		If sel = 1 And (change <> 0 Or accept)
			If accept Then change = 1
			padDeadzone = Max(.05, Min(.4, padDeadzone + Sgn(change)*.01))
		EndIf
		If accept And sel >= 2 And sel <= 4
			Select sel
				Case 2
					KeyboardControllerSettings(showgame)
				Case 3
					HybridControllerSettings(showgame)
				Case 4
					MouseControllerSettings(showgame)
			End Select
			BeginInputContext()
		EndIf
		Cls
		If showgame Then DrawAllStatic(.7)
		SetColor 255,80,80
		DrawString("Controls",SCREENW/2-280,SCREENH/2-260,5)
		SetColor 180,220,255
		DrawString(PadName()[..Min(48,PadName().Length)],SCREENW/2-280,SCREENH/2-210,2)
		DrawString("Left stick: move  Right stick: aim/fire",SCREENW/2-280,SCREENH/2-180,2)
		DrawString("Bomb: south / right bumper / right trigger",SCREENW/2-280,SCREENH/2-150,2)
		DrawString("Start: pause  South: confirm  East: back",SCREENW/2-280,SCREENH/2-120,2)
		DrawString("Gamepad and keyboard/mouse switch automatically",SCREENW/2-280,SCREENH/2-90,2)
		labels[0] = "Keyboard/mouse: " + control_method[controltype]
		labels[1] = "Stick deadzone: " + Int(padDeadzone*100+.5) + "%"
		labels[2] = "Keyboard bindings"
		labels[3] = "Keyboard + mouse settings"
		labels[4] = "Mouse settings"
		labels[5] = "Done"
		For Local i:Int = 0 Until labels.Length
			Local row:Int = SCREENH/2-40+i*40
			If sel = i Then SetColor 255,255,64 Else SetColor 0,200,0
			DrawString(labels[i],SCREENW/2-280,row,3)
		Next
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		Flip 1
		Delay 10
		cnt :+ 1
	Wend
	BeginInputContext()
End Function


Function HybridControllerSettings(showgame:Int)
	BeginInputContext()

	Local xx:Int, yy:Int, cnt:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 4
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.6)
		SetColor 255,0,0
		DrawString("Hybrid Control",SCREENW/2-280,SCREENH/2-lsp*3,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		Select h_config
			Case 0
				DrawString("Move: Keys* - Aim: Mouse Relative",SCREENW/2-280,SCREENH/2-lsp,4)
			Case 1
				DrawString("Move: Mouse - Fire: Keys*",SCREENW/2-280,SCREENH/2-lsp,4)
			Case 2
				DrawString("Move: Keys* - Aim: Mouse Centered",SCREENW/2-280,SCREENH/2-lsp,4)
		End Select

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Fire: "+mbut$[m_fire]+" Mouse Button",SCREENW/2-280,SCREENH/2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Bomb: "+mbut$[m_bomb]+" Mouse Button",SCREENW/2-280,SCREENH/2+lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawGameRect SCREENW/2+100+1,SCREENH/2+lsp*2+1,m_sensitivity*200,24-2,1
		DrawString("Mouse Sensitivity:",SCREENW/2-280,SCREENH/2+lsp*2,4)
		SetColor 255,255,0
		DrawGameRect SCREENW/2+100,SCREENH/2+lsp*2,202,24,0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 4
		If sel = 4 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*3,4)

		SetColor 0,200,0
		DrawString("* see Keyboard bindings",SCREENW/2-280,SCREENH/2+lsp*4,4)

		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		cnt:+1
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		jdmx = gameInput.navX
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 4

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 4 Then sel = 0

		EndIf

		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If (KeyDown(KEY_LEFT) Or MouseDown(1)) And bombtime = 0 Then jdmx = -1;bombtime = 20
		If (KeyDown(KEY_RIGHT) Or MouseDown(2)) And bombtime = 0 Then jdmx = 1;bombtime = 20

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Then done = True
		If MenuBack() Then done = True;sel = 4;bombtime = 20
		Select sel
			Case 0
				If jdmx <> 0
					h_config:+1
					If h_config > 2 Then h_config = 0
				EndIf
				done = False
			Case 1
				If jdmx <> 0
					m_fire:+1
					If m_fire > 3 Then m_fire = 1
				EndIf
				done = False
			Case 2
				If jdmx <> 0
					m_bomb:+1
					If m_bomb > 3 Then m_bomb = 1
				EndIf
				done = False
			Case 3
				If jdmx < 0
					m_sensitivity:- 0.05
					If m_sensitivity< 0 Then m_sensitivity= 0
				EndIf
				If jdmx > 0
					m_sensitivity:+ 0.05
					If m_sensitivity> 1 Then m_sensitivity= 1
				EndIf
				done = False
			Case 4
				If jdmx <> 0 Then done = True
		End Select
		looper :+8
	Wend

End Function




Function MouseControllerSettings(showgame:Int)
	BeginInputContext()

	Local cnt:Int, xx:Int, yy:Int
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 3
	Local s#,x:Int
	Local tim:Int
	Local lsp:Int = 40

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		Cls
		xx = MouseX()
		yy = MouseY()

		tim = MilliSecs()
		If showgame Then DrawAllStatic(.6)
		SetColor 255,0,0
		DrawString("Mouse Control",SCREENW/2-280,SCREENH/2-lsp*3,6)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Fire: "+mbut$[m_fire]+" Mouse Button",SCREENW/2-280,SCREENH/2-lsp,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Bomb: "+mbut$[m_bomb]+" Mouse Button",SCREENW/2-280,SCREENH/2,4)

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawGameRect SCREENW/2+100+1,SCREENH/2+lsp+1,m_sensitivity*200,24-2,1
		DrawString("Mouse Sensitivity:",SCREENW/2-280,SCREENH/2+lsp,4)
		SetColor 255,255,0
		DrawGameRect SCREENW/2+100,SCREENH/2+lsp,202,24,0

		If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*2,4)
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		cnt:+1
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		jdmy = gameInput.navY
		jdmx = gameInput.navX
		If KeyHit(KEY_UP) Or jdmy < 0
			sel:-1
			If sel < 0 Then sel = 3

		EndIf
		If KeyHit(KEY_DOWN) Or jdmy > 0
			sel:+1
			If sel > 3 Then sel = 0

		EndIf

		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

		If (KeyDown(KEY_LEFT) Or MouseDown(1)) And bombtime = 0 Then jdmx = -1;bombtime = 20
		If (KeyDown(KEY_RIGHT) Or MouseDown(2)) And bombtime = 0 Then jdmx = 1;bombtime = 20

		If KeyHit(k_bomb) Or (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Then done = True
		If MenuBack() Then done = True;sel = 4;bombtime = 20
		Select sel
			Case 0
				If jdmx <> 0
					m_fire:+1
					If m_fire > 3 Then m_fire = 1
				EndIf
				done = False
			Case 1
				If jdmx <> 0
					m_bomb:+1
					If m_bomb > 3 Then m_bomb = 1
				EndIf
				done = False
			Case 2
				If jdmx < 0
					m_sensitivity:- 0.05
					If m_sensitivity< 0 Then m_sensitivity= 0
				EndIf
				If jdmx > 0
					m_sensitivity:+ 0.05
					If m_sensitivity> 1 Then m_sensitivity= 1
				EndIf
				done = False
			Case 3
				If jdmx <> 0 Then done=True
		End Select
		looper :+8
	Wend

End Function




Function KeyboardControllerSettings(showgame:Int)
	BeginInputContext()
	Local done:Int = False
	Local jb:Int,i:Int
	Local looper:Int = 0
	Local sel:Int = 9
	Local s#,x:Int
	Local key:Int = -10
	Local flash$
	Local tim:Int
	Local cnt:Int
	Local lsp:Int = 40
	Local xx:Int
	Local yy:Int
	If (SCREENH<600) Then lsp = 32

	bombtime = 20
	FlushKeys()
	FlushMouse()

	While Not done And Not gameInput.quit
		PollGameInput()
		If MenuBack()
			If key = -1 Then key = -10 Else Exit
		EndIf
		Cls
		xx = MouseX()
		yy = MouseY()
		tim = MilliSecs()
		If showgame Then DrawAllStatic(.6)
		SetColor 255,0,0
		DrawString("Keyboard Control",SCREENW/2-280,SCREENH/2-lsp*6,6)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*4,SCREENW,5*4) Then sel = 0
		If sel = 0 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_move_left];If key = -1 And sel = 0 And looper Mod 30 < 15 Then flash = ""
		DrawString("Move Left : "+flash$,SCREENW/2-280,SCREENH/2-lsp*4,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*3,SCREENW,5*4) Then sel = 1
		If sel = 1 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_move_right];If key = -1 And sel = 1 And looper Mod 30 < 15 Then flash = ""
		DrawString("Move Right: "+flash$,SCREENW/2-280,SCREENH/2-lsp*3,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*2,SCREENW,5*4) Then sel = 2
		If sel = 2 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_move_up];If key = -1 And sel = 2 And looper Mod 30 < 15 Then flash = ""
		DrawString("Move Up   : "+flash$,SCREENW/2-280,SCREENH/2-lsp*2,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*1,SCREENW,5*4) Then sel = 3
		If sel = 3 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_move_down];If key = -1 And sel = 3 And looper Mod 30 < 15 Then flash = ""
		DrawString("Move Down : "+flash$,SCREENW/2-280,SCREENH/2-lsp*1,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2-lsp*0,SCREENW,5*4) Then sel = 4
		If sel = 4 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_fire_left];If key = -1 And sel = 4 And looper Mod 30 < 15 Then flash = ""
		DrawString("Fire Left : "+flash$,SCREENW/2-280,SCREENH/2-lsp*0,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*1,SCREENW,5*4) Then sel = 5
		If sel = 5 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_fire_right];If key = -1 And sel = 5 And looper Mod 30 < 15 Then flash = ""
		DrawString("Fire Right: "+flash$,SCREENW/2-280,SCREENH/2+lsp*1,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*2,SCREENW,5*4) Then sel = 6
		If sel = 6 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_fire_up];If key = -1 And sel = 6 And looper Mod 30 < 15 Then flash = ""
		DrawString("Fire Up   : "+flash$,SCREENW/2-280,SCREENH/2+lsp*2,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*3,SCREENW,5*4) Then sel = 7
		If sel = 7 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_fire_down];If key = -1 And sel = 7 And looper Mod 30 < 15 Then flash = ""
		DrawString("Fire Down : "+flash$,SCREENW/2-280,SCREENH/2+lsp*3,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*4,SCREENW,5*4) Then sel = 8
		If sel = 8 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		flash$ = keystring[k_bomb];If key = -1 And sel = 8 And looper Mod 30 < 15 Then flash = ""
		DrawString("Bomb : "+flash$,SCREENW/2-280,SCREENH/2+lsp*4,4)

		If key = -10 Then If gameInput.mouseMoved And RectsOverlap(xx-8,yy-8,16,16,0,SCREENH/2+lsp*5,SCREENW,5*4) Then sel = 9
		If sel = 9 SetColor 255,255,(cnt*8) Mod 255 Else SetColor 0,200,0
		DrawString("Done",SCREENW/2-280,SCREENH/2+lsp*5,4)

		cnt:+1
		If Not gameInput.usingPad Then DrawTarget(xx,yy,cnt,4)
		Flip 1
		tim = MilliSecs() - tim
		If tim < 20 And tim > 0
			Delay 20-tim
		EndIf
		If key = -10
			jdmy = gameInput.navY
			If KeyHit(KEY_UP) Or jdmy < 0
				sel:-1
				If sel < 0 Then sel = 9

			EndIf
			If KeyHit(KEY_DOWN) Or jdmy > 0
				sel:+1
				If sel > 9 Then sel = 0

			EndIf

			If (KeyHit(KEY_ENTER) Or PadHit(PAD_CONFIRM)) Or KeyHit(KEY_RIGHT) Or KeyHit(KEY_LEFT) Or MouseHit(1)
				If sel < 9
					key = -1
					FlushKeys()
				Else
					done = True
				EndIf
			EndIf
		EndIf
		If key = -1 ' waiting for key press
			For Local kk:Int = 8 To 255
				If KeyHit(kk) Then FlushKeys();key=kk;Exit
			Next
		EndIf
		' key was entered
		If key > -1
			Select sel
				Case 0
					k_move_left = key
				Case 1
					k_move_right = key
				Case 2
					k_move_up = key
				Case 3
					k_move_down = key
				Case 4
					k_fire_left = key
				Case 5
					k_fire_right = key
				Case 6
					k_fire_up = key
				Case 7
					k_fire_down = key
				Case 8
					k_bomb = key
			End Select
			key = -10
		EndIf
		looper :+8
		jb = 0
		bombtime = bombtime - 1
		If bombtime < 0 Then bombtime = 0

	Wend

End Function




