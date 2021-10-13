Scriptname V4F_PerceptionQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Perception1 Auto Const
Perk Property V4F_Perception2 Auto Const
Perk Property V4F_Perception3 Auto Const
Perk Property V4F_Perception4 Auto Const
Perk Property V4F_Perception5 Auto Const
Perk Property V4F_VoreBurden1 Auto Const
Perk Property V4F_VoreBurden2 Auto Const
Perk Property V4F_VoreBurden3 Auto Const
Perk Property V4F_VoreBurden4 Auto Const
Perk Property V4F_VoreBurden5 Auto Const

; Timer hacks
bool timersInitialized
int RealTimerID_HackClockSyncer = 5 const
int TIMER_main = 1 const
int TIMER_cooldown = 2 const
float HackClockLowestTime
float GameTimeElapsed

float PerkProgress = 0.0

float healthRestore = 0.005 ; 5 hp per 1000 calories 
float digestionRate = 0.00011
float exerciseBoost = 0.0

float PerkDecay = 0.001
float PerkRate = 0.2
int version = 0
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        healthRestore = 0.005
        digestionRate = 0.00011
        PerkDecay = 0.001
        PerkRate = 0.2
        PerceptionAV = Game.GetPerceptionAV()
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(8)
EndEvent

Actor Player
ActorValue PerceptionAV

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    UpdateDifficultyScaling(Game.GetDifficulty())
    ; HACK! The game clock gets adjusted early game to set lighting and such.
    ; This will fix out clocks from getting out of alignment on new game start.
    timersInitialized = false
    StartTimer(1.0, RealTimerID_HackClockSyncer)
EndEvent

float difficultyScaling
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
; EVENTS
; ======
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
            Debug.Trace("PerceptionQ Clock Sync @ " + currentGameTime + " # " + HackClockLowestTime)
        endif
    endif
EndEvent

Event OnTimerGameTime(int timer)
    if timer == TIMER_main
        ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
        float timeDelta = (Utility.GetCurrentGameTime() - GameTimeElapsed) / (1.0 / 24.0) * 60 * 60
        GameTimeElapsed = Utility.GetCurrentGameTime()
        PerkDecay(timeDelta / 3600.0)
        StartTimerGameTime(10.0/60.0, 1)
    elseif timer == TIMER_cooldown
        GotoState("")
    endif
endevent
; ========
; Public
; ========
function Increment()
    GotoState("Cooldown")
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("PerceptionQ +:" + PerkProgress)
    if PerkProgress > 7.5
        PerkProgress = 7.5
    endif
    StartTimerGameTime(1.0, TIMER_cooldown)
endfunction

state Cooldown
    function Increment()
    endfunction
endstate

float function ComputeDigestion(float time)
    Debug.Trace("t: " + time + " dr: " + digestionRate + " pav: " + (1 + Player.GetValue(PerceptionAV) / 4.0) + " ds: " + difficultyScaling + " eb: " + (1 + exerciseBoost))
    float digestion =  time * digestionRate * (1 + Player.GetValue(PerceptionAV) / 4.0) * difficultyScaling * (1 + exerciseBoost)
    exerciseBoost = 0.0
    return digestion
endfunction

float function DigestHealthRestore()
    return healthRestore * difficultyScaling
endfunction

function SetExerciseBoost()
    float burdenBonus = 1.0
    if Player.HasPerk(V4F_VoreBurden1)
        burdenBonus = 0.2
    ElseIf Player.HasPerk(V4F_VoreBurden2)
        burdenBonus = 0.4
    ElseIf Player.HasPerk(V4F_VoreBurden3)
        burdenBonus = 0.8
    ElseIf Player.HasPerk(V4F_VoreBurden4)
        burdenBonus = 1.0
    ElseIf Player.HasPerk(V4F_VoreBurden5)
        burdenBonus = 3.0
    endif
    exerciseBoost = burdenBonus
endfunction

; ========
; Private
; ========

function PerkDecay(float time)
    if PerkProgress > 0.0
        PerkProgress -= time * PerkDecay * difficultyScaling
        if PerkProgress < 0.0
            PerkProgress = 0.0
        endif
        ApplyPerks()
        Debug.Trace("PerceptionQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    Player.RemovePerk(V4F_Perception1)
    Player.RemovePerk(V4F_Perception2)
    Player.RemovePerk(V4F_Perception3)
    Player.RemovePerk(V4F_Perception4)
    Player.RemovePerk(V4F_Perception5)
    if PerkProgress >= 1.0
        Player.AddPerk(V4F_Perception1)
    endif
    if PerkProgress >= 2.0
        Player.AddPerk(V4F_Perception2)
    endif
    if PerkProgress >= 3.0
        Player.AddPerk(V4F_Perception3)
    endif
    if PerkProgress >= 4.0
        Player.AddPerk(V4F_Perception4)
    endif
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Perception5)
    endif
endfunction