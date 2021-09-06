Scriptname Vore4Fallout:VoreCore extends Quest
{Core functionality for Vore}

MagicEffect Property HealthFoodME Auto Const
{References Food item healing effect}

float TickRate
float SimRate
float CalorieDensity
float DigestionRate
float MetabolicRate

Function Initialize()
    TickRate = 1.0 / 1.0 ; ticks per second. Increasting numerator lowers resolution. Increasing denominator increases resolution.
    SimRate = TickRate / 1.0 ; Sims per Tick. Increasing denominator beyond 1 accelerates simulation. Decreasing it below 1 decelerates simulation. 
    CalorieDensity = 2000.0 ; How many calories are in each percentage 'point' of digestion?
    MetabolicRate = 100.0 / SimRate ; calories per sim tick
    DigestionRate = 0.1 / SimRate ; points per sim tick. If CalorieDensity * DigestionRate < MetabolicRate you cannot get fat.
EndFunction

Struct VoreData
    float VoreBelly = 0.0
    float Giantbelly = 0.0
    float SSBBW = 0.0
    float Breasts = 0.0
EndStruct

VoreData Data

Event OnInit()
    Main()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Main()
EndEvent

Function Main()
    ; Reset every time. Debugging only
    Data = new VoreData
    ; If(Data==NONE)
	; 	Data = new VoreData
	; EndIf
    Initialize()
    
    UpdateBody()
    Actor player = Game.GetPlayer()
    Self.RegisterForMagicEffectApplyEvent(player, player, HealthFoodME, True)
    StartTimer(1)
EndFunction

Event OnMagicEffectApply(ObjectReference akTarget, ObjectReference akCaster, MagicEffect akEffect)
    HandleFoodEvent(akTarget as Actor)
    
	Actor player = Game.GetPlayer()
    Self.RegisterForMagicEffectApplyEvent(player, player, HealthFoodME, True)
EndEvent

Event OnTimer(int timerID)
    UpdateBody()
    StartTimer(0.1)
EndEvent

Function UpdateBody()
    Debug.Trace("VB: " + Data.VoreBelly + " GB: " + Data.GiantBelly + " B: " + Data.Breasts + " BBW: " + Data.SSBBW)
    Actor player = Game.GetPlayer()
    Metabolize(Digest())
    
    BodyGen.SetMorph(player, true, "Vore prey belly", NONE, Data.VoreBelly)
    BodyGen.SetMorph(player, true, "Giant Belly (coldsteelj)", NONE, Data.GiantBelly)
    BodyGen.SetMorph(player, true, "SSBBW3 body", NONE, Data.SSBBW)
    BodyGen.SetMorph(player, true, "Giant belly up", NONE, Math.Max(0.0, Math.Max(0.0, Data.VoreBelly) + (Math.Max(0.0, Data.GiantBelly) / 2) - 1.4 ) * 6)
    BodyGen.SetMorph(player, true, "SSBBW2 body", NONE, 0)
    If Data.Breasts >= 0.0 && Data.Breasts <= 0.25
        BodyGen.SetMorph(player, true, "Breasts", NONE, Data.Breasts / 0.25)
        BodyGen.SetMorph(player, true, "BreastsNewSH", NONE, 0)
        BodyGen.SetMorph(player, true, "BreastsTogether", NONE, 0)
        BodyGen.SetMorph(player, true, "DoubleMelon", NONE, 0)
        BodyGen.SetMorph(player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.25 && Data.Breasts <= 0.5
        BodyGen.SetMorph(player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastsNewSH", NONE, (Data.Breasts - 0.25) / 0.25)
        BodyGen.SetMorph(player, true, "BreastsTogether", NONE, (Data.Breasts - 0.25) / 0.25)
        BodyGen.SetMorph(player, true, "DoubleMelon", NONE, 0)
        BodyGen.SetMorph(player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.5 && Data.Breasts <= 0.75
        BodyGen.SetMorph(player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastsNewSH", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastsTogether", NONE, 1 - ((Data.Breasts - 0.5) * 4))
        BodyGen.SetMorph(player, true, "DoubleMelon", NONE, (Data.Breasts - 0.5) / 0.25)
        BodyGen.SetMorph(player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.75 ; && Data.Breasts <= 1
        BodyGen.SetMorph(player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastsNewSH", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastsTogether", NONE, 0)
        BodyGen.SetMorph(player, true, "DoubleMelon", NONE, 1)
        BodyGen.SetMorph(player, true, "BreastFantasy", NONE, (Data.Breasts - 0.75) / 0.25)
    Else
        Debug.Trace("[Error] Breasts OOB: " + Data.Breasts)
    EndIf

    BodyGen.UpdateMorphs(player)
EndFunction

Function HandleFoodEvent(Actor actor)
    Data.Giantbelly += 0.1
    ; If Data.VoreBelly <= 0
    ;     Data.VoreBelly += 0.5
    ; Else
    ;     Data.VoreBelly += 0.1
    ; EndIf
EndFunction

float Function Digest()
    If Data.VoreBelly > 0
        Data.VoreBelly -= DigestionRate * 0.01
        Data.GiantBelly += DigestionRate * 0.02
        return 0.0
    ElseIf Data.GiantBelly > 0
        Data.GiantBelly -= DigestionRate * 0.01 
        return DigestionRate * CalorieDensity
    Else
        return 0.0
    EndIf

EndFunction

Function Metabolize(float calories)
    calories -= MetabolicRate

    If calories > 0
        calories = MetabolizeBreasts(calories)
        calories = MetabolizeSSBBW(calories)
    Else
        calories = MetabolizeSSBBW(calories)
        calories = MetabolizeBreasts(calories)
    EndIf
EndFunction

float Function MetabolizeSSBBW(float calories)
    If calories > 0 || Data.SSBBW > 0.0
        Data.SSBBW += (calories / 3500.0) * 0.005 ; 1/2% per pound of calories
        return 0.0
    Else
        Data.SSBBW = Math.Max(0.0, Data.SSBBW)
        return calories
    EndIf
EndFunction

float Function MetabolizeBreasts(float calories)
    If (calories > 0 || Data.Breasts > 0.0) && Data.Breasts < 1.0
        calories /= 2
        Data.Breasts += (calories / 3500) * 0.01
        return calories
    Else
        Data.Breasts = Clamp(0.0, 1.0, Data.Breasts)
        return calories
    EndIf
EndFunction

float Function Clamp(float min, float max, float x)
    If x < min
        return min
    ElseIf x > max
        return max
    Else
        return x
    EndIf
EndFunction