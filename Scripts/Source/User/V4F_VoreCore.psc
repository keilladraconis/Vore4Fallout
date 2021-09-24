Scriptname V4F_VoreCore extends Quest

; Properties populated through CK
V4F_Endurance Property EndurancePerk Auto Const Mandatory
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const
Perk Property V4F_Charisma1 Auto Const
Perk Property V4F_Charisma2 Auto Const
Perk Property V4F_Charisma3 Auto Const
Perk Property V4F_Charisma4 Auto Const
Perk Property V4F_Charisma5 Auto Const
Perk Property V4F_Strength1 Auto Const
Perk Property V4F_Strength2 Auto Const
Perk Property V4F_Strength3 Auto Const
Perk Property V4F_Strength4 Auto Const
Perk Property V4F_Strength5 Auto Const
Perk Property V4F_Perception1 Auto Const
Perk Property V4F_Perception2 Auto Const
Perk Property V4F_Perception3 Auto Const
Perk Property V4F_Perception4 Auto Const
Perk Property V4F_Perception5 Auto Const
ObjectReference Property V4FStomach Auto Const
ObjectReference Property V4FStomachObs Auto Const
Weapon Property V4F_Swallow Auto Const

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
float calorieWarp = 10.0
float timeWarp = 1.0
float sleepStart

float digestionRate = 0.000017 ; Approximately 50% of the vore prey belly is digested per 8 hours. This is the per-second rate.
float metabolicRate = -0.0289 ; Assuming 2500 calories per day.
float digestHealthRestore = 0.001 ; 1 hp per 1000 calories 
float calorieDensity = 144000.0 ; If the full belly is 1.25 feet in radius, 8 cubic feet, or 60 gallons, then at 2400 calories per gallon a full belly of milk would be 144000 calories.

float IntelligencePerkProgress = 0.0
float IntelligencePerkRate
float IntelligencePerkDecay

float CharismaPerkProgress = 0.0
float CharismaPerkRate
float CharismaPerkDecay

float StrengthPerkProgress = 0.0
float StrengthPerkRate
float StrengthPerkDecay

float PerceptionPerkProgress = 0.0
float PerceptionPerkRate
float PerceptionPerkDecay

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

Actor[] BellyContent
bool isProcessingVore

; Called when the quest initializes
Event OnInit()
    Setup()
    Self.RegisterForPlayerSleep()
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
    metabolicRate = -0.0289 ; Calories burned per 1 second.
    digestHealthRestore = 0.001
    digestionRate = 0.000017
    calorieDensity = 144000.0
    WarpSpeedMode(1.0)
    ; Self.RegisterForPlayerWait()
    StartTimer(60.0 / timeWarp, 1)

    ; Give swallow weapon
    EnsureSwallowItem()

    ; Prep other scripts
    IntelligencePerkSetup()
    CharismaPerkSetup()
    EndurancePerk.Setup()
    StrengthPerkSetup()
    PerceptionPerkSetup()

    Player.MoveTo(V4FStomachObs) ; Debug.
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
    float timeDelta = (Utility.GetCurrentGameTime() - sleepStart) / (1.0 / 24.0) * 60 * 60
    float calories = Digest(timeDelta * Player.GetValue(StrengthAV) * timeWarp)
    if isProcessingVore
        ProcessVore(timeDelta / 10.0)
    endif
    Metabolize(calories + ComputeMetabolicRate(timeDelta)) ; Represents the base metabolic rate of the player. Burn calories.      
    UpdateBody()
    MorphBody()
    IntelligencePerkDecay(timeDelta)
    CharismaPerkDecay(timeDelta)
    StrengthPerkDecay(timeDelta)
    PerceptionPerkDecay(timeDelta)
EndEvent

Event OnTimer(int timer)
    if timer == 1
        if !isProcessingVore
            float calories = Digest(60.0 * Player.GetValue(StrengthAV) * timeWarp)
            
            Metabolize(calories + ComputeMetabolicRate(60.0)) ; Represents the base metabolic rate of the player. Burn calories.
            UpdateBody()
            MorphBody()
        endif
        StartTimer(60.0 / timeWarp, 1)
    elseif timer == 30
        IntelligencePerkDecay(1.0)
        StartTimer(3600.0, 30)
    elseif timer == 40
        CharismaPerkDecay(1.0)
        StartTimer(3600.0, 40)
    elseif timer == 50
        StrengthPerkDecay(1.0)
        StartTimer(3600.0, 50)
    elseif timer == 60
        PerceptionPerkDecay(1.0)
        StartTimer(3600.0, 60)
    elseif timer == 70
        ProcessVore(10.0)
    endif
endevent

float function ComputeMetabolicRate(float time)
    float agilityBonus = Player.GetValue(AgilityAV) / 4.0
    return metabolicRate * time * agilityBonus * calorieWarp
endfunction

; ======
; Public
; ======
Function TestHookup(ScriptObject caller)
    Debug.Notification("Called by " + caller)
EndFunction

function AddFood(float amount, activemagiceffect foodEffect)
    PlayerVore.food += amount * foodWarp
    float maxBelly = BellyMaxByAV()
    If BellyTotal() > maxBelly
        float excess = BellyTotal() - maxBelly
        If foodeffect != NONE
            foodeffect.Dispel()
        EndIf
        Player.DamageValue(HealthAV, Math.Min(50, excess * 1000)) ; In case of warp, don't just die instantly.
        SendCustomEvent("EnduranceUpdate", new Var[0])
    EndIf
    UpdateBody()
    MorphBody()
endfunction

bool function AddVore(float amount)
    if PlayerVore.prey < 0.5
        amount = amount / 2.0
    elseif PlayerVore.prey >= 0.5
        amount = amount / 10.0
    endif
    float maxBelly = BellyMaxByAV()
    float newPrey = PlayerVore.prey + amount
    if (BellyTotal() + amount) > maxBelly
        float excess = (BellyTotal() + amount) - maxBelly
        Player.DamageValue(HealthAV, Math.Min(50, excess * 1000))
        SendCustomEvent("EnduranceUpdate", new Var[0])
        return false
    else
        PlayerVore.prey += amount
        ProteinFood()
        UpdateBody()
        MorphBody()
        return true
    endif
endfunction

float Function BellyTotal()
    return PlayerVore.prey * 2 + PlayerVore.food
endfunction

float Function BellyMaxByAV()
    ; An hockey-stick function targeting 6.0 at Endurance 10
    return 0.05 + (0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3))
EndFunction

float function Digest(float digestAmount)
    float digestActual = digestAmount * digestionRate
    float digestToFood = 0.0
    float digestCalories = 0.0

    if PlayerVore.prey > 0.5
        float digestPlus = PlayerVore.prey - 0.5 - digestActual
        if digestPlus >= 0.0
            PlayerVore.prey -= digestActual
            digestToFood += digestActual * 10.0
            digestActual = 0.0
        else
            PlayerVore.prey -= digestActual + digestPlus
            digestToFood += (digestActual + digestPlus) * 10.0
            digestActual = Math.abs(digestPlus)
        endif
    endif

    if digestActual > 0.0 && PlayerVore.prey <= 0.5 && PlayerVore.prey > 0.0
        PlayerVore.prey -= digestActual
        if PlayerVore.prey > 0.0
            digestToFood += digestActual * 2.0
            digestActual = 0.0
        else
            digestToFood += (digestActual + PlayerVore.prey) * 2.0
            digestActual = Math.abs(PlayerVore.prey)
            PlayerVore.prey = 0.0
        endif
    endif

    if digestActual > 0.0 && PlayerVore.food > 0.0
        PlayerVore.food -= digestActual
        if PlayerVore.food > 0.0
            digestCalories += digestActual * calorieDensity
        else
            digestCalories += (digestActual + PlayerVore.food) * calorieDensity
            PlayerVore.food = 0.0
        endif
    endif

    PlayerVore.food += digestToFood
    return digestCalories
endfunction
 
; =======
; Private
; =======
function UpdateBody()
    PlayerBody.bbw = PlayerVore.fat
    PlayerBody.vorePreyBelly = PlayerVore.prey
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
;; TimerID = 30
function IntelligencePerkSetup()
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
    endif
    if IntelligencePerkProgress >= 2.0
        Player.AddPerk(V4F_Intelligence2)
    endif
    if IntelligencePerkProgress >= 3.0
        Player.AddPerk(V4F_Intelligence3)
    endif
    if IntelligencePerkProgress >= 4.0
        Player.AddPerk(V4F_Intelligence4)
    endif
    if IntelligencePerkProgress >= 5.0
        Player.AddPerk(V4F_Intelligence5)
    endif
    StartTimer(3600.0, 30)
endfunction

function IntelligencePerkDecay(float time)
    if IntelligencePerkProgress > 0.0
        IntelligencePerkProgress -= time * IntelligencePerkDecay
        if IntelligencePerkProgress < 0.0
            IntelligencePerkProgress = 0.0
        endif
        ApplyIntelligencePerks()
    endif
endfunction

;; Handling Charisma Perk "Fatty Foods"
;; TimerID = 40
function CharismaPerkSetup()
    CharismaPerkRate = 0.025
    CharismaPerkDecay = 0.125
    StartTimer(3600.0, 40)
endfunction

function FattyFood()
    CharismaPerkProgress += CharismaPerkRate
    ApplyCharismaPerks()
endfunction

function ApplyCharismaPerks()
    Player.RemovePerk(V4F_Charisma1)
    Player.RemovePerk(V4F_Charisma2)
    Player.RemovePerk(V4F_Charisma3)
    Player.RemovePerk(V4F_Charisma4)
    Player.RemovePerk(V4F_Charisma5)
    if CharismaPerkProgress >= 1.0
        Player.AddPerk(V4F_Charisma1)
    endif
    if CharismaPerkProgress >= 2.0
        Player.AddPerk(V4F_Charisma2)
    endif
    if CharismaPerkProgress >= 3.0
        Player.AddPerk(V4F_Charisma3)
    endif
    if CharismaPerkProgress >= 4.0
        Player.AddPerk(V4F_Charisma4)
    endif
    if CharismaPerkProgress >= 5.0
        Player.AddPerk(V4F_Charisma5)
    endif
    StartTimer(3600.0, 40)
endfunction

function CharismaPerkDecay(float time)
    CharismaPerkProgress -= time * CharismaPerkDecay
    ApplyCharismaPerks()
endfunction

;; Handling Strength Perk "Protein Foods"
;; TimerID = 50
function StrengthPerkSetup()
    StrengthPerkRate = 0.025
    StrengthPerkDecay = 0.125
    StartTimer(3600.0, 50)
endfunction

function ProteinFood()
    StrengthPerkProgress += StrengthPerkRate
    ApplyStrengthPerks()
endfunction

function ApplyStrengthPerks()
    Player.RemovePerk(V4F_Strength1)
    Player.RemovePerk(V4F_Strength2)
    Player.RemovePerk(V4F_Strength3)
    Player.RemovePerk(V4F_Strength4)
    Player.RemovePerk(V4F_Strength5)
    if StrengthPerkProgress >= 1.0
        Player.AddPerk(V4F_Strength1)
    endif
    if StrengthPerkProgress >= 2.0
        Player.AddPerk(V4F_Strength2)
    endif
    if StrengthPerkProgress >= 3.0
        Player.AddPerk(V4F_Strength3)
    endif
    if StrengthPerkProgress >= 4.0
        Player.AddPerk(V4F_Strength4)
    endif
    if StrengthPerkProgress >= 5.0
        Player.AddPerk(V4F_Strength5)
    endif
    StartTimer(3600.0, 50)
endfunction

function StrengthPerkDecay(float time)
    StrengthPerkProgress -= time * StrengthPerkDecay
    ApplyStrengthPerks()
endfunction

;; Handling Perception Perk "Health Foods"
;; TimerID = 60
function PerceptionPerkSetup()
    PerceptionPerkRate = 0.025
    PerceptionPerkDecay = 0.125
    StartTimer(3600.0, 60)
endfunction

function HealthFood()
    PerceptionPerkProgress += PerceptionPerkRate
    ApplyPerceptionPerks()
endfunction

function ApplyPerceptionPerks()
    Player.RemovePerk(V4F_Perception1)
    Player.RemovePerk(V4F_Perception2)
    Player.RemovePerk(V4F_Perception3)
    Player.RemovePerk(V4F_Perception4)
    Player.RemovePerk(V4F_Perception5)
    if PerceptionPerkProgress >= 1.0
        Player.AddPerk(V4F_Perception1)
    endif
    if PerceptionPerkProgress >= 2.0
        Player.AddPerk(V4F_Perception2)
    endif
    if PerceptionPerkProgress >= 3.0
        Player.AddPerk(V4F_Perception3)
    endif
    if PerceptionPerkProgress >= 4.0
        Player.AddPerk(V4F_Perception4)
    endif
    if PerceptionPerkProgress >= 5.0
        Player.AddPerk(V4F_Perception5)
    endif
    StartTimer(3600.0, 60)
endfunction

function PerceptionPerkDecay(float time)
    PerceptionPerkProgress -= time * PerceptionPerkDecay
    ApplyPerceptionPerks()
endfunction

function EnsureSwallowItem()
    float swallows = Player.GetItemCount(V4F_Swallow)
    if swallows == 1.0
        return
    elseif swallows >= 1.0
        while swallows > 1.0
            Player.RemoveItem(V4F_Swallow)
            swallows -= 1.0
        endwhile
    else
        Player.AddItem(V4F_Swallow)
    endif
endfunction

function HandleSwallow(Actor prey)
    if BellyContent == NONE
        BellyContent = new Actor[0]
    endif

    if AddVore(1.0)
        Player.SetRelationshipRank(prey, -4)
        prey.MoveTo(V4FStomach)
        BellyContent.Add(prey)
        if !isProcessingVore
            isProcessingVore = true
            StartTimer(10.0, 70)
        endif
    else
        Debug.Notification("You have no room in your stomach!")
    endif
endfunction

; TimerID 70
function ProcessVore(float time = 10.0)
    if BellyContent.length == 0
        isProcessingVore = false
        return
    endif
    int i = 0
    Actor[] deadList = new Actor[0]
    ; Acid damage is equal to player strength divided by the number of prey
    float stomachAcidDamage = (time / 10.0) * (Player.GetValue(StrengthAV) * 2.0) / BellyContent.Length
    while i < BellyContent.Length
        BellyContent[i].DamageValue(HealthAV, stomachAcidDamage)
        if BellyContent[i].IsDead()
            deadList.Add(BellyContent[i])
        endif
        i += 1
    endwhile

    i = 0
    while i < deadList.Length
        BellyContent.Remove(BellyContent.Find(deadList[i]))
        i += 1
    endwhile

    if BellyContent.Length > 0
        StartTimer(10.0, 70)
    else
        isProcessingVore = false
    endif
endfunction