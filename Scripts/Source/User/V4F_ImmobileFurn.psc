Scriptname V4F_ImmobileFurn extends ObjectReference

bool playerPrefersFirst

Event OnInit()
	Actor Player = Game.GetPlayer()
	; Player.SetGhost()	
	playerPrefersFirst = Player.GetAnimationVariableBool("IsFirstPerson")
	Utility.wait(0.5)
	Game.ForceThirdPerson()
	Self.Activate(Game.GetPlayer() as ObjectReference, True)	
	Utility.SetINIBool("bForceAutoVanityMode:Camera", true)
EndEvent

Event OnExitFurniture(ObjectReference akActionRef)
	Actor Player = Game.GetPlayer()
	If (akActionRef == Player as ObjectReference)
		Utility.SetINIBool("bForceAutoVanityMode:Camera", false)
		; Player.SetGhost(false)	
		if playerPrefersFirst
			Game.ForceFirstPerson()	
		else
			Game.ForceThirdPerson()
		endif														

		Utility.wait(10)
		Self.Delete()
	EndIf
EndEvent