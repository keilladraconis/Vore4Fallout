Scriptname V4F_VoreCore extends Quest

struct Vore
    float food = 0.0
    float prey = 0.0
    float topFat = 0.0
    float bottomFat = 0.0
    float fat = 0.0
endstruct

struct Body
    float vorePreyBelly = 0.0
    float bbw = 0.0
    float giantBellyUp = 0.0
    float bigBelly = 0.0
    float tummyTuck = 0.0
    float pregnancyBelly = 0.0
    float giantBelly = 0.0
    float breasts = 0.0
    float breastsH = 0.0
    float breastsT = 0.0
    float breastsD = 0.0
    float breastsF = 0.0
    float butt = 0.0
    float buttChubby = 0.0
    float buttThighs = 0.0
    float buttWaist = 0.0
    float buttBack = 0.0
    float buttBig = 0.0
    float buttCLegs = 0.0
    float buttCWaist = 0.0
    float buttApple = 0.0
    float buttRound = 0.0
endstruct

float foodWarp = 1.0
float calorieWarp = 1.0

Body pPlayerBody
Body Property PlayerBody
    Body function get()
        return pPlayerBody
    endfunction
endproperty

Vore pPlayerVore
Vore Property PlayerVore
    Vore function get()
        return pPlayerVore
    endfunction
endproperty

Actor Player
ActorValue StrengthAV
ActorValue PerceptionAV
ActorValue EnduranceAV
ActorValue CharismaAV
ActorValue IntelligenceAV
ActorValue AgilityAV
ActorValue LuckAV
ActorValue HealthAV

CustomEvent VoreUpdate
CustomEvent BodyUpdate
CustomEvent CalorieUpdate

; Called when the quest initializes
Event OnInit()
    Setup()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Function Setup()
    pPlayerBody = new Body
    pPlayerVore = new Vore
    Player = Game.GetPlayer()
    StrengthAV = Game.GetStrengthAV()
    PerceptionAV = Game.GetPerceptionAV()
    EnduranceAV = Game.GetEnduranceAV()
    CharismaAV = Game.GetCharismaAV()
    IntelligenceAV = Game.GetIntelligenceAV()
    AgilityAV = Game.GetAgilityAV()
    LuckAV = Game.GetLuckAV()
    HealthAV = Game.GetHealthAV()
    WarpSpeedMode(10.0)
EndFunction

function WarpSpeedMode(float warp)
    foodWarp = warp
    calorieWarp = warp
endfunction

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
    PlayerVore.food += amount * foodWarp
    float maxBelly = BellyMaxByAV()
    If PlayerVore.food > maxBelly
        float excess = PlayerVore.food - maxBelly
        PlayerVore.food = maxBelly
        ; EndurancePerkProgress += excess * EndurancePerkInc
        ; Debug.Trace("Overeat: " + excess + " EndurancePerkProgress: " + Data.EndurancePerkProgress)
        If foodeffect != NONE
            foodeffect.Dispel()
        EndIf
        Player.DamageValue(HealthAV, Math.Min(50, excess * 1000)) ; In case of warp, don't just die instantly.
    EndIf

    UpdateBody()
    SendVoreUpdate()
endfunction

float Function BellyMaxByAV()
    ; An hockey-stick function targeting 6.0 at Endurance 10
    return 0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3)
EndFunction

function Digest(float food, float prey, float calories)
    Debug.Trace("Digest food:" + food + " prey:" + prey + "cal:" + calories)
    PlayerVore.food -= food * foodWarp
    if PlayerVore.food < 0.0
        PlayerVore.food = 0.0
    endif
    PlayerVore.prey -= prey
    if PlayerVore.prey < 0.0
        PlayerVore.prey = 0.0
    endif
    Metabolize(calories * calorieWarp)
    UpdateBody()
    SendVoreUpdate()
endfunction
 
; =======
; Private
; =======
function SendVoreUpdate()
    SendCustomEvent("VoreUpdate")
endfunction

function UpdateBody()
    Debug.Trace("UpdateBody Vore:" + PlayerVore)
    PlayerBody.giantBellyUp = Math.Max(0, PlayerVore.prey + (PlayerVore.food / 2) - 14000) * 6 
    PlayerBody.bbw = PlayerVore.fat
    if PlayerVore.food >= 0.0 && PlayerVore.food <= 0.1
        PlayerBody.bigBelly         = PlayerVore.food * 10.0
        PlayerBody.tummyTuck        = PlayerVore.food * 10.0
        PlayerBody.pregnancyBelly   = 0.0
        PlayerBody.giantBelly       = 0.0
    elseif PlayerVore.food > 0.1 && PlayerVore.food <= 0.15
        PlayerBody.bigBelly         = 1 - PlayerVore.food - 0.1
        PlayerBody.tummyTuck        = 1 - PlayerVore.food - 0.1
        PlayerBody.pregnancyBelly   = (PlayerVore.food - 0.1) / 0.15 * 0.5
        PlayerBody.giantBelly       = 0.0
    elseif PlayerVore.food > 0.15 && PlayerVore.food <= 0.2
        PlayerBody.bigBelly         = 0.0
        PlayerBody.tummyTuck        = 0.0
        PlayerBody.pregnancyBelly   = 0.5 - ((PlayerVore.food - 0.15) * 10)
        PlayerBody.giantBelly       = (PlayerVore.food - 0.15) / 0.05 * 0.2
    elseif PlayerVore.food > 0.2
        PlayerBody.bigBelly         = 0.0
        PlayerBody.tummyTuck        = 0.0
        PlayerBody.pregnancyBelly   = 0.0
        PlayerBody.giantBelly       = PlayerVore.food
    endif

    if PlayerVore.topFat >= 0.0 && PlayerVore.topFat <= 0.25
        PlayerBody.breasts    = PlayerVore.topFat / 0.25
        PlayerBody.breastsH   = 0.0
        PlayerBody.breastsT   = 0.0
        PlayerBody.breastsD   = 0.0
        PlayerBody.breastsF   = 0.0
    elseif PlayerVore.topFat > 0.25 && PlayerVore.topFat <= 0.5
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = (PlayerVore.topFat - 0.25) / 0.25
        PlayerBody.breastsT   = (PlayerVore.topFat - 0.25) / 0.25
        PlayerBody.breastsD   = 0.0
        PlayerBody.breastsF   = 0.0
    elseif PlayerVore.topFat > 0.5 && PlayerVore.topFat <= 0.75
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = 1.0
        PlayerBody.breastsT   = 1 - ((PlayerVore.topFat - 0.5) * 4)
        PlayerBody.breastsD   = (PlayerVore.topFat - 0.5) / 0.25
        PlayerBody.breastsF   = 0.0
    elseif PlayerVore.topFat > 0.75
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = 1.0
        PlayerBody.breastsT   = 0.0
        PlayerBody.breastsD   = 1.0
        PlayerBody.breastsF   = (PlayerVore.topFat - 0.75) / 0.25
    endif

    if PlayerVore.bottomFat >= 0.0 && PlayerVore.bottomFat <= 0.1
        PlayerBody.butt       = PlayerVore.bottomFat / 0.1
        PlayerBody.buttChubby = 0.0
        PlayerBody.buttThighs = 0.0
        PlayerBody.buttWaist  = 0.0
        PlayerBody.buttBig    = 0.0
        PlayerBody.buttBack   = 0.0
        PlayerBody.buttCLegs  = 0.0
        PlayerBody.buttCWaist = 0.0
        PlayerBody.buttApple  = 0.0
        PlayerBody.buttRound  = 0.0
    elseif PlayerVore.bottomfat > 0.1 && PlayerVore.bottomFat <= 0.2
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = (PlayerVore.bottomfat - 0.1) / 0.1
        PlayerBody.buttThighs = (PlayerVore.bottomfat - 0.1) / 0.1
        PlayerBody.buttWaist  = (PlayerVore.bottomfat - 0.1) / 0.1
        PlayerBody.buttBig    = 0.0
        PlayerBody.buttBack   = 0.0
        PlayerBody.buttCLegs  = 0.0
        PlayerBody.buttCWaist = 0.0
        PlayerBody.buttApple  = 0.0
        PlayerBody.buttRound  = 0.0
    elseif PlayerVore.bottomfat > 0.2 && PlayerVore.bottomFat <= 0.6
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = 1.0
        PlayerBody.buttThighs = 1.0
        PlayerBody.buttWaist  = 1.0
        PlayerBody.buttBig    = (PlayerVore.bottomfat - 0.2) / 0.4
        PlayerBody.buttBack   = (PlayerVore.bottomfat - 0.2) / 0.4
        PlayerBody.buttCLegs  = (PlayerVore.bottomfat - 0.2) / 0.4
        PlayerBody.buttCWaist = (PlayerVore.bottomfat - 0.2) / 0.4
        PlayerBody.buttApple  = 0.0
        PlayerBody.buttRound  = 0.0
    elseif PlayerVore.bottomfat > 0.6 && PlayerVore.bottomFat <= 0.9
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = 1.0
        PlayerBody.buttThighs = 1.0
        PlayerBody.buttWaist  = 1.0
        PlayerBody.buttBig    = 1.0
        PlayerBody.buttBack   = 1.0
        PlayerBody.buttCLegs  = 1.0
        PlayerBody.buttCWaist = 1.0
        PlayerBody.buttApple  = 2 * ((PlayerVore.bottomfat - 0.2) / 0.4) 
        PlayerBody.buttRound  = 0.0
    elseif PlayerVore.bottomfat > 0.9
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = 1.0
        PlayerBody.buttThighs = 1.0
        PlayerBody.buttWaist  = 1.0
        PlayerBody.buttBig    = 1.0
        PlayerBody.buttBack   = 1.0
        PlayerBody.buttCLegs  = 1.0
        PlayerBody.buttCWaist = 1.0
        PlayerBody.buttApple  = 2.0
        PlayerBody.buttRound  = (PlayerVore.bottomfat - 0.9) / 0.1
    endif
        
    Debug.Trace("UpdateBody Body:" + PlayerBody)

    SendCustomEvent("BodyUpdate")
endfunction

; Metabolism
Function Metabolize(float calories)
    Debug.Trace("Metabolizing: " + calories)
    If calories > 0
        float topCalories = MetabolizeTop(calories / 2.0)
        calories = MetabolizeBottom((calories / 2.0) + topCalories)
        calories = MetabolizeRest(calories)
    Else
        calories = MetabolizeRest(calories)
        float bottomCalories = MetabolizeBottom(calories / 2.0)
        calories = MetabolizeTop((calories / 2.0) + bottomCalories)
    EndIf
EndFunction

float Function MetabolizeRest(float calories)
    PlayerVore.fat += (calories / 3500.0) * 0.005 ; 1/2% per pound of calories

    If PlayerVore.fat < 0.0
        float excess = PlayerVore.fat
        PlayerVore.fat = 0.0
        return excess
    Else
        return 0.0
    EndIf
EndFunction

float Function MetabolizeTop(float calories)
    PlayerVore.topFat += (calories / 3500) * 0.025

    float breastsMax = BreastsMaxByAV()
    If PlayerVore.topFat > breastsMax
        float excess = PlayerVore.topFat - breastsMax
        PlayerVore.topFat = breastsMax
        return excess * 40 * 3500
    ElseIf PlayerVore.topFat < 0.0
        float excess = PlayerVore.topFat
        PlayerVore.topFat = 0.0
        return excess * 40 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function BreastsMaxByAV()
    return Player.GetValue(IntelligenceAV) / 10.0
EndFunction

float Function MetabolizeBottom(float calories)
    PlayerVore.bottomFat += (calories / 3500) * 0.01

    float buttMax = ButtMaxByAV()
    If PlayerVore.bottomFat > buttMax
        float excess = PlayerVore.bottomFat - buttMax
        PlayerVore.bottomFat = buttMax
        return excess * 100 * 3500
    ElseIf PlayerVore.bottomFat < 0.0
        float excess = PlayerVore.bottomFat
        PlayerVore.bottomFat = 0.0
        return excess * 100 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function ButtMaxByAV()
    return Player.GetValue(CharismaAV) / 10.0
EndFunction