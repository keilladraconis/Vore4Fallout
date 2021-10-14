Scriptname V4F_VoreCore extends Quest

; Properties populated through CK
ObjectReference Property V4FStomach Auto Const
ObjectReference Property V4FStomachObs Auto Const
Weapon Property V4F_Swallow Auto Const
V4F_AgilityQ Property AgilityQ Auto Const
V4F_EnduranceQ Property EnduranceQ Auto Const
V4F_StrengthQ Property StrengthQ Auto Const
V4F_PerceptionQ Property PerceptionQ Auto Const
Hardcore:HC_ManagerScript Property HC_Manager Auto
FormList Property V4F_EdibleSmall Auto Const
FormList Property V4F_EdibleMedium Auto Const
FormList Property V4F_EdibleHuge Auto Const
FormList Property V4F_EdibleMassive Auto Const

struct Vore
    float food = 0.0
    float prey = 0.0
    float topFat = 0.0
    float bottomFat = 0.0
    float fat = 0.0
    float muscle = 0.0
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
    float UKTop = 0.0
    float UKBottom = 0.0
    float muscle = 0.0
endstruct

; Timer hacks
bool timersInitialized
int RealTimerID_HackClockSyncer = 5 const
int TIMER_main = 1 const
float HackClockLowestTime
float GameTimeElapsed

float calorieDensity = 144000.0 ; If the full belly is 1.25 feet in radius, 8 cubic feet, or 60 gallons, then at 2400 calories per gallon a full belly of milk would be 144000 calories.
float metabolicRate = -0.0289 ; Assuming 2500 calories per day.
bool hasExercised

; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
int version = 1
function Updateversion(int v)
    if v < version
        calorieDensity = 144000.0
        metabolicRate = -0.0289
        Body oldBody = PlayerBody
        pPlayerBody = new Body
        pPlayerBody.vorePreyBelly = oldBody.vorePreyBelly
        pPlayerBody.bbw = oldBody.bbw
        pPlayerBody.giantBellyUp = oldBody.giantBellyUp
        pPlayerBody.bigBelly = oldBody.bigBelly
        pPlayerBody.tummyTuck = oldBody.tummyTuck
        pPlayerBody.pregnancyBelly = oldBody.pregnancyBelly
        pPlayerBody.giantBelly = oldBody.giantBelly
        pPlayerBody.breasts = oldBody.breasts
        pPlayerBody.breastsH = oldBody.breastsH
        pPlayerBody.breastsT = oldBody.breastsT
        pPlayerBody.breastsD = oldBody.breastsD
        pPlayerBody.breastsF = oldBody.breastsF
        pPlayerBody.butt = oldBody.butt
        pPlayerBody.buttChubby = oldBody.buttChubby
        pPlayerBody.buttThighs = oldBody.buttThighs
        pPlayerBody.buttWaist = oldBody.buttWaist
        pPlayerBody.buttBack = oldBody.buttBack
        pPlayerBody.buttBig = oldBody.buttBig
        pPlayerBody.buttCLegs = oldBody.buttCLegs
        pPlayerBody.buttCWaist = oldBody.buttCWaist
        pPlayerBody.buttApple = oldBody.buttApple
        pPlayerBody.buttRound = oldBody.buttRound
        pPlayerBody.UKBottom = oldBody.UKBottom
        pPlayerBody.UKTop = oldBody.UKTop

        Vore oldVore = PlayerVore
        pPlayerVore = new Vore
        pPlayerVore.food = oldVore.food
        pPlayerVore.prey = oldVore.prey
        pPlayerVore.topFat = oldVore.topFat
        pPlayerVore.bottomFat = oldVore.bottomFat
        pPlayerVore.fat = oldVore.fat
        pPlayerVore.muscle = oldVore.muscle

        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
    EnsureSwallowItem()
    Updateversion(3)
EndEvent

float property BreastMax = 0.0 Auto
float property ButtMax = 0.0 Auto
float property MuscleMax = 0.0 Auto

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
ActorValue HealthAV
ActorValue StrengthAV

CustomEvent StomachStrainEvent
CustomEvent VoreEvent
CustomEvent BodyMassEvent
CustomEvent BodyShapeEvent
CustomEvent OnDigest

Actor[] BellyContent
bool isProcessingVore
float difficultyScaling

; Called when the quest initializes
Event OnInit()
    pPlayerBody = new Body
    pPlayerVore = new Vore
    Player = Game.GetPlayer()
    StrengthAV = Game.GetStrengthAV()
    HealthAV = Game.GetHealthAV()
    RegisterForPlayerTeleport()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    UpdateDifficultyScaling(Game.GetDifficulty())

    EnsureSwallowItem()    
    ; HACK! The game clock gets adjusted early game to set lighting and such.
    ; This will fix out clocks from getting out of alignment on new game start.
    timersInitialized = false
    StartTimer(1.0, RealTimerID_HackClockSyncer)
EndEvent

; ======
; EVENTS
; ======
Event OnPlayerTeleport()
    EnsureSwallowItem()
EndEvent

Event OnTimer(int timer)
    if timer == RealTimerID_HackClockSyncer
        float currentGameTime = Utility.GetCurrentGameTime()
        if !timersInitialized || currentGameTime < HackClockLowestTime
            GameTimeElapsed = currentGameTime
            HackClockLowestTime = currentGameTime
            StartTimerGameTime(10.0/60.0, 1)
            timersInitialized = true
        endif
        
        if currentGameTime <= HackClockLowestTime + 0.05
            StartTimer(30.0, RealTimerID_HackClockSyncer)
            Debug.Trace("VoreCore Clock Sync @ " + currentGameTime + " # " + HackClockLowestTime)
        endif
    endif
EndEvent

Event OnTimerGameTime(int timer)
    if timer == TIMER_main
        ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
        float timeDelta = (Utility.GetCurrentGameTime() - GameTimeElapsed) / (1.0 / 24.0) * 60 * 60
        GameTimeElapsed = Utility.GetCurrentGameTime()
        Update(timeDelta)
        ProcessVore(timeDelta)
        StartTimerGameTime(10.0/60.0, 1)
    endif
endevent

Event Actor.OnDifficultyChanged(Actor akSender, int aOldDifficulty, int aNewDifficulty)
    UpdateDifficultyScaling(aNewDifficulty)
EndEvent

function UpdateDifficultyScaling(int difficulty)
    difficulty += 1
    if difficulty > 5
        difficulty = 5
    endif
    difficultyScaling = 5.0 / difficulty
endfunction

; ======
; Public
; ======
function AddFood(float amount, activemagiceffect foodEffect)
    PlayerVore.food += amount * difficultyScaling
    float maxBelly = EnduranceQ.BellyMax()
    If BellyTotal() > maxBelly
        float excess = BellyTotal() - maxBelly
        If foodeffect != NONE
            foodeffect.Dispel()
        EndIf
        Debug.Trace("OverEat: " + Math.Min(25, excess * 100) + " max: " + maxBelly + " total " + BellyTotal())
        Player.DamageValue(HealthAV, Math.Min(25, excess * 100)) ; In case of warp, don't just die instantly.
        EnduranceQ.StomachStrain(BellyTotal())
        Debug.Notification("You have no room in your stomach!")
    EndIf
    Update(0.0, false)
endfunction

bool function AddVore(float amount)
    if PlayerVore.prey < 0.5
        amount = amount / 2.0
    elseif PlayerVore.prey >= 0.5
        amount = amount / 5.0
    endif
    float maxBelly = EnduranceQ.BellyMax()
    float newPrey = PlayerVore.prey + amount
    if (BellyTotal() + amount) > maxBelly
        Debug.Trace("T:" + BellyTotal() + " A:" + amount + " M:" + maxBelly)
        return false
    else
        PlayerVore.prey += amount
        Var[] args = new Var[0]
        SendCustomEvent("VoreEvent", args)
        EnduranceQ.StomachStrain(BellyTotal())
        Update(0.0, false)
        return true
    endif
endfunction

function HandleSwallow(Actor prey)
    if BellyContent == NONE
        BellyContent = new Actor[0]
    endif

    if prey.GetValuePercentage(HealthAV) > StrengthQ.HealthPctLimit()
        return
    endif

    float preyVolume
    Race preyRace = Prey.GetRace()
    if V4F_EdibleSmall.HasForm(preyRace)
        preyVolume = 0.25
    elseif V4F_EdibleMedium.HasForm(preyRace)
        preyVolume = 0.5
    elseif V4F_EdibleHuge.HasForm(preyRace)
        preyVolume = 2.0
    elseif V4F_EdibleMassive.HasForm(preyRace)
        preyVolume = 10.0
    else
        preyVolume = 1.0
    endif

    if AddVore(preyVolume)
        if prey.IsDead()
            Cleanup(prey)
        endif
        Player.SetRelationshipRank(prey, -4)
        prey.MoveTo(V4FStomach)
        BellyContent.Add(prey)
        if !isProcessingVore
            isProcessingVore = true
        endif
    else
        Debug.Notification("You have no room in your stomach!")
    endif
endfunction

function SetExerciseBoost()
    hasExercised = true
endfunction

; =======
; Private
; =======

function Update(float time, bool doDigest = true)
    if doDigest
        float calories = Digest(time)
        float meta = ComputeMetabolicRate(time)
        Debug.Trace("Metabolic Rate:" + meta + " per:" + time)
        Metabolize(calories + meta)
    endif
    if isProcessingVore
        ProcessVore(time / 10.0)
    endif
    UpdateBody()
    MorphBody()
    SendBodyMassEvent()
    SendBodyShapeEvent()
    Debug.Trace("PlayerVore: " + PlayerVore)
    Debug.Trace("BrM: " + BreastMax + " BtM: " + ButtMax)
endfunction

float function ComputeMetabolicRate(float time)
    if hasExercised
        hasExercised = false
        return metabolicRate * time * (1 + Math.pow(PlayerVore.fat - 1.0, 2)) * difficultyScaling
    else
        return metabolicRate * time * difficultyScaling
    endif
endfunction

function SendBodyMassEvent()
    Var[] args = new Var[1]
    args[0] = PlayerVore.prey + (PlayerVore.food / 1.0) + (PlayerVore.fat)
    SendCustomEvent("BodyMassEvent", args)
endfunction

function SendBodyShapeEvent()
    Var[] args = new Var[3]
    args[0] = PlayerVore.topFat
    args[1] = PlayerVore.bottomFat
    args[2] = PlayerVore.muscle
    SendCustomEvent("BodyShapeEvent", args)
endfunction

float Function BellyTotal()
    return PlayerVore.prey * 2 + PlayerVore.food
endfunction

float function Digest(float time)
    float digestActual = PerceptionQ.ComputeDigestion(time)
    float digestToFood = 0.0
    float digestCalories = 0.0
    float digestStep = 0.0

    Debug.Trace("Digest:" + digestActual)
    ; Loop digestActual so that we do some incremental digestion steps rather than one single step.
    ; This helps with digesting prey, so that you don't spend a whole 8 hours simply digesting only prey, but 
    ; each loop you digest prey, then prey + food, etc.
    while digestActual > 0.0 && (PlayerVore.prey > 0.0 || PlayerVore.food > 0.0)
        digestActual -= 0.01
        if digestActual < 0.0
            digestStep = Math.abs(digestActual)
        else
            digestStep = 0.01
        endif
        
        if PlayerVore.prey > 0.5
            float digestPlus = PlayerVore.prey - 0.5 - digestStep
            if digestPlus >= 0.0
                PlayerVore.prey -= digestStep
                digestToFood += digestStep * 2.5
                digestStep = 0.0
            else
                PlayerVore.prey -= digestStep + digestPlus
                digestToFood += (digestStep + digestPlus) * 2.5
                digestStep = Math.abs(digestPlus)
            endif
        endif
    
        if digestStep > 0.0 && PlayerVore.prey <= 0.5 && PlayerVore.prey > 0.0
            PlayerVore.prey -= digestStep
            if PlayerVore.prey > 0.0
                digestToFood += digestStep * 2.0
                digestStep = 0.0
            else
                digestToFood += (digestStep + PlayerVore.prey) * 2.0
                digestStep = Math.abs(PlayerVore.prey)
                PlayerVore.prey = 0.0
            endif
        endif
    
        if digestStep > 0.0 && PlayerVore.food > 0.0
            PlayerVore.food -= digestStep
            if PlayerVore.food > 0.0
                digestCalories += digestStep * calorieDensity
            else
                digestCalories += (digestStep + PlayerVore.food) * calorieDensity
                PlayerVore.food = 0.0
            endif
        endif
    endwhile 

    PlayerVore.food += digestToFood
    return digestCalories
endfunction

function UpdateBody()
    PlayerBody.bbw = PlayerVore.fat
    PlayerBody.vorePreyBelly = PlayerVore.prey
    PlayerBody.giantBellyUp = (Math.max(0.0, PlayerVore.prey - (1.2 - PlayerVore.fat * 0.5)) + Math.max(0.0, PlayerVore.food - (2.5 - PlayerVore.fat * 0.4))) * 2
    Debug.Trace("PB:" + PlayerBody)
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
        PlayerBody.UKTop      = 0.0
    elseif PlayerVore.topFat > 0.25 && PlayerVore.topFat <= 0.5
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = (PlayerVore.topFat - 0.25) / 0.25
        PlayerBody.breastsT   = (PlayerVore.topFat - 0.25) / 0.25
        PlayerBody.breastsD   = 0.0
        PlayerBody.breastsF   = 0.0
        PlayerBody.UKTop      = 0.0
    elseif PlayerVore.topFat > 0.5 && PlayerVore.topFat <= 0.75
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = 1.0
        PlayerBody.breastsT   = 1 - ((PlayerVore.topFat - 0.5) * 4)
        PlayerBody.breastsD   = (PlayerVore.topFat - 0.5) / 0.25
        PlayerBody.breastsF   = 0.0
        PlayerBody.UKTop      = 0.0
    elseif PlayerVore.topFat > 0.75 && PlayerVore.topFat <= 1.0
        PlayerBody.breasts    = 1.0
        PlayerBody.breastsH   = 1.0
        PlayerBody.breastsT   = 0.0
        PlayerBody.breastsD   = 1.0
        PlayerBody.breastsF   = (PlayerVore.topFat - 0.75) / 0.25
        PlayerBody.UKTop      = 0.0
    elseif PlayerVore.topFat > 1.0
        PlayerBody.breasts    = 1.0 - (PlayerVore.topFat - 1.0)
        PlayerBody.breastsH   = 1.0 - (PlayerVore.topFat - 1.0)
        PlayerBody.breastsT   = 0.0
        PlayerBody.breastsD   = 1.0 - (PlayerVore.topFat - 1.0)
        PlayerBody.breastsF   = 1.0 - (PlayerVore.topFat - 1.0)
        PlayerBody.UKTop = (PlayerVore.topFat - 1.0) / 4.0
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
        PlayerBody.UKBottom   = 0.0
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
        PlayerBody.UKBottom   = 0.0
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
        PlayerBody.UKBottom   = 0.0
    elseif PlayerVore.bottomfat > 0.6 && PlayerVore.bottomFat <= 0.9
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = 1.0
        PlayerBody.buttThighs = 1.0
        PlayerBody.buttWaist  = 1.0
        PlayerBody.buttBig    = 1.0
        PlayerBody.buttBack   = 1.0
        PlayerBody.buttCLegs  = 1.0
        PlayerBody.buttCWaist = 1.0
        PlayerBody.buttApple  = ((PlayerVore.bottomfat - 0.2) / 0.4) 
        PlayerBody.buttRound  = 0.0
        PlayerBody.UKBottom   = 0.0
    elseif PlayerVore.bottomfat > 0.9 && PlayerVore.bottomFat <= 1.0
        PlayerBody.butt       = 1.0
        PlayerBody.buttChubby = 1.0
        PlayerBody.buttThighs = 1.0
        PlayerBody.buttWaist  = 1.0
        PlayerBody.buttBig    = 1.0
        PlayerBody.buttBack   = 1.0
        PlayerBody.buttCLegs  = 1.0
        PlayerBody.buttCWaist = 1.0
        PlayerBody.buttApple  = 1.0
        PlayerBody.buttRound  = (PlayerVore.bottomfat - 0.9) / 0.1
        PlayerBody.UKBottom   = 0.0
    else
        PlayerBody.butt       = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttChubby = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttThighs = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttWaist  = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttBig    = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttBack   = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttCLegs  = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttCWaist = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttApple  = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.buttRound  = 1.0 - (PlayerVore.bottomFat - 1.0)
        PlayerBody.UKBottom   = (PlayerVore.bottomFat - 1.0) / 4.0
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
    BodyGen.SetMorph(Player, true, "SSBBW UltKir Body", NONE, PlayerBody.UKBottom + PlayerBody.UKTop)
    BodyGen.UpdateMorphs(Player)
endfunction

; Metabolism
Function Metabolize(float calories)
    Debug.Trace("Metabolize: " + calories)
    If calories > 0
        Debug.Trace("Gaining...")
        float muscleCalories = MetabolizeMuscle(calories / 3.0)
        float topCalories = MetabolizeTop(calories / 3.0)
        float bottomCalories = MetabolizeBottom(calories / 3.0)
        calories = MetabolizeRest(muscleCalories + topCalories + bottomCalories)
    Elseif PlayerVore.fat > 0.0 || PlayerVore.topFat > 0.0 || PlayerVore.bottomFat > 0.0 || PlayerVore.muscle > 0.0
        Debug.Trace("Losing...")
        Player.RestoreValue(HealthAV, -calories * PerceptionQ.DigestHealthRestore()) ; Heal slowly when burning fat
        calories = MetabolizeRest(calories)
        if calories == 0.0
            return ; Stop processing if we have burned all calories as fat.
        endif
        MetabolizeBottom(calories / 3.0)
        MetabolizeTop(calories / 3.0)
        MetabolizeMuscle(calories / 3.0)
    else
        PlayerVore.fat = 0.0
        PlayerVore.topFat = 0.0
        PlayerVore.bottomFat = 0.0
        PlayerVore.muscle = 0.0
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

    If calories > 0 && PlayerVore.topFat > BreastMax
        float excess = PlayerVore.topFat - BreastMax
        PlayerVore.topFat = BreastMax
        return excess * 40 * 3500
    ElseIf PlayerVore.topFat < 0.0
        float excess = PlayerVore.topFat
        PlayerVore.topFat = 0.0
        return excess * 40 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function MetabolizeBottom(float calories)
    PlayerVore.bottomFat += (calories / 3500) * 0.025

    If calories > 0 && PlayerVore.bottomFat > ButtMax
        float excess = PlayerVore.bottomFat - ButtMax
        PlayerVore.bottomFat = ButtMax
        return excess * 100 * 3500
    ElseIf PlayerVore.bottomFat < 0.0
        float excess = PlayerVore.bottomFat
        PlayerVore.bottomFat = 0.0
        return excess * 100 * 3500
    Else
        return 0.0
    EndIf
EndFunction

float Function MetabolizeMuscle(float calories)
    PlayerVore.muscle += (calories / 3500) * 0.01

    If calories > 0 && PlayerVore.muscle > MuscleMax
        float excess = PlayerVore.muscle - MuscleMax
        PlayerVore.muscle = MuscleMax
        return excess * 100 * 3500
    ElseIf PlayerVore.muscle < 0.0
        float excess = PlayerVore.muscle
        PlayerVore.muscle = 0.0
        return excess * 100 * 3500
    Else
        return 0.0
    EndIf
EndFunction

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
        Player.EquipItem(V4F_Swallow, false, true)
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
        int deadPreyIndex = BellyContent.Find(deadList[i])
        Actor deadPrey = BellyContent[deadPreyIndex]
        Cleanup(deadPrey)

        BellyContent.Remove(deadPreyIndex)
        i += 1
    endwhile

    if BellyContent.Length > 0
        StartTimer(10.0, 70)
    else
        isProcessingVore = false
    endif
endfunction

function Cleanup(Actor prey)
    prey.RemoveAllItems(Player)
    prey.SetCriticalStage(4)
    HC_Manager.ModFoodPoolAndUpdateHungerEffects(9999, true) ; Vore is hardcore food
    prey.MoveToMyEditorLocation()
endfunction
