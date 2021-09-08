Scriptname V4F_VoreCore extends Quest

float consumeVolume

struct Vore
    float food = 0.0
    float prey = 0.0
endstruct

struct Body
    float vorePreyBelly = 0.0
    float ssbbw = 0.0
    float giantBellyUp = 0.0
    float bigBelly = 0.0
    float tummyTuck = 0.0
    float pregnancyBelly = 0.0
    float giantBelly = 0.0
endstruct

Body PlayerBody
Vore PlayerVore

CustomEvent VoreUpdate
CustomEvent BodyUpdate

; Called when the quest initializes
Event OnInit()
    Setup()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Function Setup()
    PlayerBody = new Body
    PlayerVore = new Vore
    ; If the belly 100% volume is 60 gallons, and each food is about a gallon, then the volume expressed as a percent should be 1.6%. In integer 10,000ths, it's 160 10,000ths.
    consumeVolume = 0.016

    RegisterForCustomEvent(self, "VoreUpdate")
EndFunction

; ======
; EVENTS
; ======
Event Actor.OnPlayerLoadGame(Actor akSender)
	Setup()
EndEvent

Event V4F_VoreCore.VoreUpdate(V4F_VoreCore sender, Var[] args)
    UpdateBody()
endevent

; ======
; Public
; ======
Function TestHookup(ScriptObject caller)
    Debug.Notification("Called by " + caller)
EndFunction

function AddFood(int amount, activemagiceffect foodEffect)
    PlayerVore.food += amount * consumeVolume
    SendCustomEvent("VoreUpdate")
endfunction

; =======
; Private
; =======
function UpdateBody()
    ; PlayerBody.giantBellyUp = Math.Max(0, PlayerVore.prey + (PlayerVore.food / 2) - 14000) * 6 
    if PlayerVore.food >= 0.0 && PlayerVore.food <= 0.1
        PlayerBody.bigBelly = PlayerVore.food * 10.0
    endif

    Var[] args = new Var[1]
    args[0] = PlayerBody
    SendCustomEvent("BodyUpdate", args)
endfunction