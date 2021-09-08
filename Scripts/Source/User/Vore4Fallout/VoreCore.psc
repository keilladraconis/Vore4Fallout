Scriptname Vore4Fallout:VoreCore extends Quest
{Core functionality for Vore}

float TickRate
float SimRate
float ConsumeVolume
float CalorieDensity
float DigestionRate
float MetabolicRate
float SleepStart
float DigestHealthRestore

ActorValue StrengthAV
ActorValue PerceptionAV
ActorValue EnduranceAV
ActorValue CharismaAV
ActorValue IntelligenceAV
ActorValue AgilityAV
ActorValue LuckAV

float EndurancePerkInc

Actor Player
ActorValue HealthAV

Function Initialize()
    TickRate = 1.0 / 1.0 ; ticks per second. Increasting numerator lowers resolution. Increasing denominator increases resolution.
    SimRate = TickRate / 1.0 ; Sims per Tick. Increasing denominator beyond 1 accelerates simulation. Decreasing it below 1 decelerates simulation. 
    ; If the belly 100% volume is 60 gallons, and each food is about a gallon, then the volume expressed as a percent should be 1.6%.
    ConsumeVolume = 0.016 ; Volume of each food, in belly percentage.
    ; If the full belly is 1.25 feet in radius, 8 cubic feet, or 60 gallons, then at 2400 calories per gallon a full belly of milk would be 144000 calories.
    CalorieDensity = 144000.0 ; How many calories are in a full stomach? Increasing this increases the rate of weight gain. 
    ;  An adult human runs at 2500 calories per day, in 20 minute fallout days, that is 2.08 calories per second.
    MetabolicRate = 2.08 / SimRate ; calories burned per sim tick. Increase too much and you cannot get fat.
    ; Digesting at a rate of 1 full belly per 8 hours is 0.0025
    DigestionRate = 0.0034 / SimRate ; How much do you digest per sim tick? If DigestionRate * CalorieDensity < MetabolicRate, you never gain weight. 
    DigestHealthRestore = 1000
    StrengthAV = Game.GetStrengthAV()
    PerceptionAV = Game.GetPerceptionAV()
    EnduranceAV = Game.GetEnduranceAV()
    CharismaAV = Game.GetCharismaAV()
    IntelligenceAV = Game.GetIntelligenceAV()
    AgilityAV = Game.GetAgilityAV()
    LuckAV = Game.GetLuckAV()
    EndurancePerkInc = 10.0
    Player = Game.GetPlayer()
    HealthAV = Game.GetHealthAV()
EndFunction

Function DebugRates()
    ; Speed everything up for debugging/testing purposes.
    TickRate = 1.0 / 60.0
    SimRate = 1.0
    ConsumeVolume = 0.1
    CalorieDensity = 144000.0
    MetabolicRate = 5
    DigestionRate = 1
EndFunction

Struct VoreData
    float VoreBelly = 0.0
    float Giantbelly = 0.0
    float SSBBW = 0.0
    float Breasts = 0.0
    float Butt = 0.0
    float EndurancePerkProgress = 0.0
EndStruct

VoreData Data

Event OnInit()
    Setup()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Setup()
EndEvent

Function Setup()
    ; Debug.Trace("RestoreHealthFood: " + RestoreHealthFood)
    ; RegisterForCustomEvent(RestoreHealthFood, "FoodConsumed")
    ; Reset every time. Debugging only
    ; Data = new VoreData
    ; If(Data==NONE)
	; 	Data = new VoreData
	; EndIf
    ; Initialize()
    ; ; DebugRates()
    ; UpdateBody()
    ; Self.RegisterForPlayerSleep()
    ; StartTimer(1)
EndFunction

; Event Vore4Fallout:RestoreHealthFood.FoodConsumed(Vore4Fallout:RestoreHealthFood sender, Var[] akArgs)
;     Debug.Notification("Custom Event Worked")
; EndEvent

Event OnTimer(int timerID)
    UpdateBody()
    StartTimer(TickRate)
EndEvent

Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    SleepStart = afSleepStartTime
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal.
    Metabolize(Digest((Utility.GetCurrentGameTime() - SleepStart) / (1.0 / 24.0) * 60 * 60))
EndEvent

Function UpdateBody()
    Debug.Trace("VB: " + Data.VoreBelly + " GB: " + Data.GiantBelly + " B: " + Data.Breasts + " U: " + Data.Butt + " BBW: " + Data.SSBBW)
    Metabolize(Digest())
    
    BodyGen.SetMorph(Player, true, "Vore prey belly", NONE, Data.VoreBelly)
    BodyGen.SetMorph(Player, true, "SSBBW3 body", NONE, Data.SSBBW)
    BodyGen.SetMorph(Player, true, "Giant belly up", NONE, Math.Max(0.0, Math.Max(0.0, Data.VoreBelly) + (Math.Max(0.0, Data.GiantBelly) / 2) - 1.4 ) * 6)

    If Data.GiantBelly >= 0.0 && Data.GiantBelly <= 0.1
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, Data.GiantBelly * 10)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, Data.GiantBelly * 10)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, 0)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, 0)
    ElseIf Data.GiantBelly > 0.1 && Data.GiantBelly <= 0.15
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, 1 - (Data.GiantBelly - 0.1))
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, 1 - (Data.GiantBelly - 0.1))
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, ((Data.GiantBelly - 0.1) / 0.15) * 0.5)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, 0)
    ElseIf Data.GiantBelly > 0.15 && Data.GiantBelly <= 0.2
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, 0)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, 0)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, 0.5 - (Data.GiantBelly - 0.15) * 10)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, ((Data.GiantBelly - 0.15) / 0.05) * 0.2)
    ElseIf Data.GiantBelly >= 0.2
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, 0)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, 0)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, 0)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, Data.GiantBelly)
    EndIf
    
    If Data.Breasts >= 0.0 && Data.Breasts <= 0.25
        BodyGen.SetMorph(Player, true, "Breasts", NONE, Data.Breasts / 0.25)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, 0)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, 0)
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, 0)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.25 && Data.Breasts <= 0.5
        BodyGen.SetMorph(Player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, (Data.Breasts - 0.25) / 0.25)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, (Data.Breasts - 0.25) / 0.25)
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, 0)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.5 && Data.Breasts <= 0.75
        BodyGen.SetMorph(Player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, 1 - ((Data.Breasts - 0.5) * 4))
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, (Data.Breasts - 0.5) / 0.25)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, 0)
    ElseIf Data.Breasts > 0.75 ; && Data.Breasts <= 1
        BodyGen.SetMorph(Player, true, "Breasts", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, 0)
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, 1)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, (Data.Breasts - 0.75) / 0.25)
    Else
        Debug.Trace("[Error] Breasts OOB: " + Data.Breasts)
    EndIf

    If Data.Butt >= 0.0 && Data.Butt <= 0.1
        BodyGen.SetMorph(Player, true, "Butt", NONE, Data.Butt / 0.1)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, 0)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, 0)
        BodyGen.SetMorph(Player, true, "Waist", NONE, 0) 
        BodyGen.SetMorph(Player, true, "BigButt", NONE, 0)
        BodyGen.SetMorph(Player, true, "Back", NONE, 0)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, 0)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, 0)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, 0)
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, 0)
    ElseIf Data.Butt > 0.1 && Data.Butt <= 0.2
        BodyGen.SetMorph(Player, true, "Butt", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, (Data.Butt - 0.1) / 0.1)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, (Data.Butt - 0.1) / 0.1)
        BodyGen.SetMorph(Player, true, "Waist", NONE, (Data.Butt - 0.1) / 0.1) 
        BodyGen.SetMorph(Player, true, "BigButt", NONE, 0)
        BodyGen.SetMorph(Player, true, "Back", NONE, 0)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, 0)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, 0)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, 0)
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, 0)
    ElseIf Data.Butt > 0.2 && Data.Butt <= 0.6
        BodyGen.SetMorph(Player, true, "Butt", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, 1)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, 1)
        BodyGen.SetMorph(Player, true, "Waist", NONE, 1) 
        BodyGen.SetMorph(Player, true, "BigButt", NONE, (Data.Butt - 0.2) / 0.4)
        BodyGen.SetMorph(Player, true, "Back", NONE, (Data.Butt - 0.2) / 0.4)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, (Data.Butt - 0.2) / 0.4)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, (Data.Butt - 0.2) / 0.4)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, 0)
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, 0)
    ElseIf Data.Butt > 0.6 && Data.Butt <= 0.9
        BodyGen.SetMorph(Player, true, "Butt", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, 1)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, 1)
        BodyGen.SetMorph(Player, true, "Waist", NONE, 1) 
        BodyGen.SetMorph(Player, true, "BigButt", NONE, 1)
        BodyGen.SetMorph(Player, true, "Back", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, 1)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, 2 * ((Data.Butt - 0.6) / 0.3)) ; Double Butt :3
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, 0)
    ElseIf Data.Butt > 0.9
        BodyGen.SetMorph(Player, true, "Butt", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, 1)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, 1)
        BodyGen.SetMorph(Player, true, "Waist", NONE, 1) 
        BodyGen.SetMorph(Player, true, "BigButt", NONE, 1)
        BodyGen.SetMorph(Player, true, "Back", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, 1)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, 1)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, 2)
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, (Data.Butt - 0.9) / 0.1)
    Else
        Debug.Trace("[Error] Butt OOB: " + Data.Butt)
    EndIf

    BodyGen.UpdateMorphs(Player)
EndFunction

Function HandleFoodEvent(ActiveMagicEffect ActiveHealthFoodEffect)
    Data.Giantbelly += ConsumeVolume
    float maxBelly = BellyMaxByAV()
    If Data.GiantBelly > maxBelly
        float excess = Data.GiantBelly - maxBelly
        Data.GiantBelly = maxBelly
        Data.EndurancePerkProgress += excess * EndurancePerkInc
        Debug.Trace("Overeat: " + excess + " EndurancePerkProgress: " + Data.EndurancePerkProgress)
        If ActiveHealthFoodEffect != NONE
            ActiveHealthFoodEffect.Dispel()
        EndIf
        Player.DamageValue(HealthAV, excess * 1000)
    EndIf
        
    ; If Data.VoreBelly <= 0
    ;     Data.VoreBelly += 0.5
    ; Else
    ;     Data.VoreBelly += 0.1
    ; EndIf
EndFunction

float Function BellyMaxByAV()
    ; An hockey-stick function targeting 6.0 at Endurance 10
    ; y = Ax2 + Bx + C
    return 0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3)
EndFunction

float Function Digest(float time = 1.0)
    If Data.VoreBelly > 0.0
        Data.VoreBelly -= DigestionRate * 0.01 * time
        Data.GiantBelly += DigestionRate * 0.02 * time
        return 0.0
    ElseIf Data.GiantBelly > 0.0
        float digestAmount = DigestionRate * 0.01 * Player.GetValue(PerceptionAV) * time
        Debug.Trace("HealthDigest: " + digestAmount * DigestHealthRestore)
        Player.RestoreValue(HealthAV, digestAmount * DigestHealthRestore)
        If digestAmount > Data.GiantBelly
            float actual = Data.GiantBelly
            Data.GiantBelly = 0.0
            return actual * CalorieDensity
        Else
            Data.GiantBelly -= digestAmount
            return digestAmount * CalorieDensity
        EndIf
    Else
        Data.VoreBelly = 0.0
        Data.GiantBelly = 0.0
        return -MetabolicRate * Player.GetValue(AgilityAV) * time
    EndIf
EndFunction

Function Metabolize(float calories)
    If calories > 0
        calories = MetabolizeBreasts(calories / 2.0) + MetabolizeButt(calories / 2.0)
        calories = MetabolizeSSBBW(calories)
    Else
        calories = MetabolizeSSBBW(calories)
        calories = MetabolizeBreasts(calories / 2.0) + MetabolizeButt(calories / 2.0)
    EndIf
EndFunction

float Function MetabolizeSSBBW(float calories)
    Data.SSBBW += (calories / 3500.0) * 0.005 ; 1/2% per pound of calories

    If Data.SSBBW < 0
        float excess = Data.SSBBW
        Data.SSBBW = 0
        return excess
    Else
        return calories
    EndIf
EndFunction

float Function MetabolizeBreasts(float calories)
    Data.Breasts += (calories / 3500) * 0.025

    float breastsMax = BreastsMaxByAV()
    If Data.Breasts > breastsMax
        float excess = Data.Breasts - breastsMax
        Data.Breasts = breastsMax
        return excess * 20 * 3500
    ElseIf Data.Breasts < 0.0
        float excess = Data.Breasts
        Data.Breasts = 0.0
        return excess * 20 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function BreastsMaxByAV()
    return Player.GetValue(IntelligenceAV) / 10.0
EndFunction

float Function MetabolizeButt(float calories)
    Data.Butt += (calories / 3500) * 0.01

    float buttMax = ButtMaxByAV()
    If Data.Butt > buttMax
        float excess = Data.Butt - buttMax
        Data.Butt = buttMax
        return excess * 100 * 3500
    ElseIf Data.Butt < 0.0
        float excess = Data.Butt
        Data.Butt = 0.0
        return excess * 100 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function ButtMaxByAV()
    return Player.GetValue(CharismaAV) / 10.0
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
