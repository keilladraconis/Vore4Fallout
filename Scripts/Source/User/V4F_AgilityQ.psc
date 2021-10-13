Scriptname V4F_AgilityQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Agility1 Auto Const
Perk Property V4F_Agility2 Auto Const
Perk Property V4F_Agility3 Auto Const
Perk Property V4F_Agility4 Auto Const
Perk Property V4F_Agility5 Auto Const
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
float previousTime

float metabolicRate = -0.0289 ; Assuming 2500 calories per day.
float PerkRate = 0.0
int version
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        metabolicRate = -0.0289
        PerkRate = 0.0
        RegisterForCustomEvent(VoreCore, "BodyMassEvent")
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(5)
EndEvent

Actor Player
ActorValue AgilityAV


; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    AgilityAV = Game.GetAgilityAV()
    RegisterForPlayerTeleport()
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
            Debug.Trace("AgilityQ Clock Sync @ " + currentGameTime + " # " + HackClockLowestTime)
        endif
    endif
EndEvent

Event OnTimerGameTime(int timer)
    if timer == TIMER_main
        ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
        float timeDelta = (Utility.GetCurrentGameTime() - GameTimeElapsed) / (1.0 / 24.0) * 60 * 60
        GameTimeElapsed = Utility.GetCurrentGameTime()

        Update(timeDelta / 3600.0)
        StartTimerGameTime(10.0/60.0, 1)
    elseif timer == TIMER_cooldown
        GotoState("")
    endif
endevent

Event OnPlayerTeleport()
    float timeDelta = (Utility.GetCurrentGameTime() - GameTimeElapsed) / (1.0 / 24.0) * 60 * 60
    Debug.Trace("AgilityQ: Teleport TimeDelta: " + timeDelta)
    if timeDelta > 3600.0
        GotoState("")
        Increment(timeDelta / 3600.0)
    endif
EndEvent

Event V4F_VoreCore.BodyMassEvent(V4F_VoreCore akSender, Var[] akArgs)
    GotoState("Cooldown")
    float bodyMass = akArgs[0] as float
    if bodyMass <= 1.0
        PerkRate -= 1.0 * difficultyScaling
        if PerkRate <= 1.0
            PerkRate = 0.0
        endif
        Debug.Trace("Bodymass low, reducing AgilityPerk rate:" + PerkRate)
    endif
EndEvent

; ========
; Public
; ========

float function ComputeMetabolicRate(float time)
    float agilityBonus = Player.GetValue(AgilityAV) / 4.0
    Debug.Trace("MBR: " + metabolicRate + " t: " + time + " ag: " + agilityBonus + " pp: " + PerkProgress + " ds: " + difficultyScaling)
    return metabolicRate * time * agilityBonus * (1 + PerkProgress * 10) * difficultyScaling
endfunction

function Increment(float amount = 1.0)
    GotoState("Cooldown")
    float burdenBonus = 1.0
    if Player.HasPerk(V4F_VoreBurden1)
        burdenBonus = 1.2
    ElseIf Player.HasPerk(V4F_VoreBurden2)
        burdenBonus = 1.4
    ElseIf Player.HasPerk(V4F_VoreBurden3)
        burdenBonus = 1.8
    ElseIf Player.HasPerk(V4F_VoreBurden4)
        burdenBonus = 2.0
    ElseIf Player.HasPerk(V4F_VoreBurden5)
        burdenBonus = 3.0
    endif
    PerkRate += amount * burdenBonus * difficultyScaling
    Debug.Trace("AgilityQ Perkrate:" + PerkRate)
    ApplyPerks()
    StartTimerGameTime(1.0, TIMER_cooldown)
endfunction

state Cooldown
    function Increment(float amount = 1.0)
    endfunction

    Event V4F_VoreCore.BodyMassEvent(V4F_VoreCore akSender, Var[] akArgs)
    EndEvent
endstate

; ========
; Private
; ========

function Update(float time)
    PerkProgress += time * PerkRate * difficultyScaling
    
    if PerkProgress < 0.0
        PerkProgress = 0.0
    endif
    ApplyPerks()
    Debug.Trace("AgilityQ:" + PerkProgress)
endfunction

function ApplyPerks()
    Player.RemovePerk(V4F_Agility1)
    Player.RemovePerk(V4F_Agility2)
    Player.RemovePerk(V4F_Agility3)
    Player.RemovePerk(V4F_Agility4)
    Player.RemovePerk(V4F_Agility5)
    if PerkProgress >= 1.0
        Player.AddPerk(V4F_Agility1)
    endif
    if PerkProgress >= 20.0
        Player.AddPerk(V4F_Agility2)
    endif
    if PerkProgress >= 30.0
        Player.AddPerk(V4F_Agility3)
    endif
    if PerkProgress >= 40.0
        Player.AddPerk(V4F_Agility4)
    endif
    if PerkProgress >= 50.0
        Player.AddPerk(V4F_Agility5)
    endif
endfunction