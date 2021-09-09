Scriptname V4F_VoreCore extends Quest

struct Vore
    float food = 0.0
    float prey = 0.0
    float calories = 0.0
    float topFat = 0.0
    float bottomFat = 0.0
    float bbw = 0.0
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
EndFunction

; ======
; EVENTS
; ======
Event Actor.OnPlayerLoadGame(Actor akSender)
	Setup()
EndEvent

; ======
; Public
; ======
Function TestHookup(ScriptObject caller)
    Debug.Notification("Called by " + caller)
EndFunction

function AddFood(float amount, activemagiceffect foodEffect)
    PlayerVore.food += amount
    UpdateBody()
    SendVoreUpdate()
endfunction

function Digest(float food, float prey, float calories)
    Debug.Trace("Digest food:" + food + " prey:" + prey + "cal:" + calories)
    PlayerVore.food -= food
    if PlayerVore.food < 0.0
        PlayerVore.food = 0.0
    endif
    PlayerVore.prey -= prey
    if PlayerVore.prey < 0.0
        PlayerVore.prey = 0.0
    endif
    PlayerVore.calories += calories
    UpdateBody()
    SendVoreUpdate()
endfunction
 
; =======
; Private
; =======
function SendVoreUpdate()
    Var[] args = new Var[1]
    args[0] = PlayerVore
    SendCustomEvent("VoreUpdate", args)
endfunction

function UpdateBody()
    ; PlayerBody.giantBellyUp = Math.Max(0, PlayerVore.prey + (PlayerVore.food / 2) - 14000) * 6 
    if PlayerVore.food >= 0.0 && PlayerVore.food <= 0.1
        PlayerBody.bigBelly = PlayerVore.food * 10.0
        PlayerBody.tummyTuck = PlayerVore.food * 10.0
        PlayerBody.pregnancyBelly = 0.0
        PlayerBody.giantBelly = 0.0
    elseif PlayerVore.food > 0.1 && PlayerVore.food <= 0.15
        PlayerBody.bigBelly = 1 - PlayerVore.food - 0.1
        PlayerBody.tummyTuck = 1 - PlayerVore.food - 0.1
        PlayerBody.pregnancyBelly = (PlayerVore.food - 0.1) / 0.15 * 0.5
        PlayerBody.giantBelly = 0.0
    elseif PlayerVore.food > 0.15 && PlayerVore.food <= 0.2
        PlayerBody.bigBelly = 0.0
        PlayerBody.tummyTuck = 0.0
        PlayerBody.pregnancyBelly = 0.5 - ((PlayerVore.food - 0.15) * 10)
        PlayerBody.giantBelly = (PlayerVore.food - 0.15) / 0.05 * 0.2
    elseif PlayerVore.food > 0.2
        PlayerBody.bigBelly = 0.0
        PlayerBody.tummyTuck = 0.0
        PlayerBody.pregnancyBelly = 0.0
        PlayerBody.giantBelly = PlayerVore.food
    endif

    Var[] args = new Var[1]
    args[0] = PlayerBody
    SendCustomEvent("BodyUpdate", args)
endfunction