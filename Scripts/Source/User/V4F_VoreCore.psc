Scriptname V4F_VoreCore extends Quest

; Properties populated through CK HELLO
V4F_Endurance Property EndurancePerk Auto Const Mandatory
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const

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
float timeWarp = 1.0
float sleepStart

float metabolicRate = -2.08
float digestHealthRestore = 0.001 ; 1 hp per 1000 calories 

float IntelligencePerkRate
float IntelligencePerkProgress
float IntelligencePerkDecay

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

CustomEvent EnduranceUpdate
CustomEvent SleepUpdate

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
    metabolicRate = -2.08 ; Calories burned per 1 second.
    digestHealthRestore = 0.001
    WarpSpeedMode(1.0)
    Self.RegisterForPlayerSleep()
    StartTimer(60.0 / timeWarp, 1)

    ; Prep other scripts
    IntelligencePerkSetup()
    EndurancePerk.Setup()
EndFunction

function WarpSpeedMode(float warp)
    foodWarp = warp
    calorieWarp = warp
    timeWarp = warp
endfunction

; ======
; EVENTS
; ======
Event Actor.OnPlayerLoadGame(Actor akSender)
	Setup()
EndEvent

Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    sleepStart = afSleepStartTime
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
    float timeDelta = (Utility.GetCurrentGameTime() - SleepStart) / (1.0 / 24.0) * 60 * 60
    Metabolize(metabolicRate * Player.GetValue(AgilityAV) * timeDelta * calorieWarp) ; Represents the base metabolic rate of the player. Burn calories.
    UpdateBody()
    IntelligencePerkDecay(timeDelta)
EndEvent

Event OnTimer(int timer)
    Debug.Trace("OnTimer" + timer)
    if timer == 1
        Metabolize(metabolicRate * 60 * Player.GetValue(AgilityAV) * calorieWarp) ; Represents the base metabolic rate of the player. Burn calories.
        UpdateBody()
        MorphBody()
        StartTimer(60.0 / timeWarp, 1)
    elseif timer == 30
        IntelligencePerkDecay(1.0)
        StartTimer(3600.0, 30)
    endif
endevent

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
        If foodeffect != NONE
            foodeffect.Dispel()
        EndIf
        Player.DamageValue(HealthAV, Math.Min(50, excess * 1000)) ; In case of warp, don't just die instantly.
        SendCustomEvent("EnduranceUpdate", new Var[0])
    EndIf
    UpdateBody()
    MorphBody()
endfunction

float Function BellyMaxByAV()
    ; An hockey-stick function targeting 6.0 at Endurance 10
    return 0.05 + (0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3))
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
endfunction
 
; =======
; Private
; =======
function UpdateBody()
    Debug.Trace("UpdateBody Vore:" + PlayerVore)
    PlayerBody.bbw = PlayerVore.fat
    PlayerBody.giantBellyUp = Math.Max(0, PlayerVore.prey + (PlayerVore.food / 2) - 14000) * 6 
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
endfunction

function MorphBody()
    BodyGen.SetMorph(Player, true, "Vore prey belly", NONE, PlayerBody.vorePreyBelly)
    BodyGen.SetMorph(Player, true, "SSBBW3 body", NONE, PlayerBody.bbw)
    BodyGen.SetMorph(Player, true, "Giant belly up", NONE, PlayerBody.giantBellyUp)
    BodyGen.SetMorph(Player, true, "BigBelly", NONE, PlayerBody.bigBelly)
    BodyGen.SetMorph(Player, true, "TummyTuck", NONE, PlayerBody.tummyTuck)
    BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, PlayerBody.pregnancyBelly)
    BodyGen.SetMorph(Player, true, "Giant belly (coldsteelj)", NONE, PlayerBody.giantBelly)
    BodyGen.SetMorph(Player, true, "Breasts", NONE, PlayerBody.breasts)
    BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, PlayerBody.breastsH)
    BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, PlayerBody.breastsT)
    BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, PlayerBody.breastsD)
    BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, PlayerBody.breastsF)
    BodyGen.SetMorph(Player, true, "Butt", NONE, PlayerBody.butt)
    BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, PlayerBody.buttChubby)
    BodyGen.SetMorph(Player, true, "Thighs", NONE, PlayerBody.buttThighs)
    BodyGen.SetMorph(Player, true, "Waist", NONE, PlayerBody.buttWaist)
    BodyGen.SetMorph(Player, true, "Back", NONE, PlayerBody.buttBack)
    BodyGen.SetMorph(Player, true, "BigButt", NONE, PlayerBody.buttBig)
    BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, PlayerBody.buttCLegs)
    BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, PlayerBody.buttCWaist)
    BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, PlayerBody.buttApple)
    BodyGen.SetMorph(Player, true, "RoundAss", NONE, PlayerBody.buttRound)
    BodyGen.UpdateMorphs(Player)
endfunction

; Metabolism
Function Metabolize(float calories)
    If calories > 0
        float topCalories = MetabolizeTop(calories / 2.0)
        calories = MetabolizeBottom((calories / 2.0) + topCalories)
        calories = MetabolizeRest(calories)
    Elseif PlayerVore.fat > 0.0 || PlayerVore.topFat > 0.0 || PlayerVore.bottomFat > 0.0
        Player.RestoreValue(HealthAV, -calories * digestHealthRestore) ; Heal slowly when burning fat
        calories = MetabolizeRest(calories)
        float bottomCalories = MetabolizeBottom(calories / 2.0)
        calories = MetabolizeTop((calories / 2.0) + bottomCalories)
    else
        PlayerVore.fat = 0.0
        PlayerVore.topFat = 0.0
        PlayerVore.bottomFat = 0.0
    EndIf
EndFunction

float Function MetabolizeRest(float calories)
    PlayerVore.fat += (calories / 3500.0) * 0.005 ; 1/2% per pound of calories

    If PlayerVore.fat < 0.0
        float excess = PlayerVore.fat
        PlayerVore.fat = 0.0
        return excess * 3500 * 200
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

;; Handling Intelligence Perk "Sweet Foods"
function IntelligencePerkSetup()
    IntelligencePerkProgress = 0
    IntelligencePerkRate = 0.025
    IntelligencePerkDecay = 0.125
    StartTimer(3600.0, 30)
endfunction

function SweetFood()
    IntelligencePerkProgress += IntelligencePerkRate
    ApplyIntelligencePerks()
endfunction

function ApplyIntelligencePerks()
    Player.RemovePerk(V4F_Intelligence1)
    Player.RemovePerk(V4F_Intelligence2)
    Player.RemovePerk(V4F_Intelligence3)
    Player.RemovePerk(V4F_Intelligence4)
    Player.RemovePerk(V4F_Intelligence5)
    if IntelligencePerkProgress >= 1.0
        Player.AddPerk(V4F_Intelligence1)
        Debug.Trace("Added Perk 1" + V4F_Intelligence1)
    endif
    if IntelligencePerkProgress >= 2.0
        Player.AddPerk(V4F_Intelligence2)
        Debug.Trace("Added Perk 2" + V4F_Intelligence2)
    endif
    if IntelligencePerkProgress >= 3.0
        Player.AddPerk(V4F_Intelligence3)
        Debug.Trace("Added Perk 3" + V4F_Intelligence3)
    endif
    if IntelligencePerkProgress >= 4.0
        Player.AddPerk(V4F_Intelligence4)
        Debug.Trace("Added Perk 4" + V4F_Intelligence4)
    endif
    if IntelligencePerkProgress >= 5.0
        Player.AddPerk(V4F_Intelligence5)
        Debug.Trace("Added Perk 5" + V4F_Intelligence5)
    endif
    StartTimer(3600.0, 30)
endfunction

function IntelligencePerkDecay(float time)
    IntelligencePerkProgress -= time * IntelligencePerkDecay
    ApplyIntelligencePerks()
endfunction