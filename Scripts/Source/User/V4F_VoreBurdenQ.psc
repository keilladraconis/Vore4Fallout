Scriptname V4F_VoreBurdenQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_VoreBurden1 Auto Const
Perk Property V4F_VoreBurden2 Auto Const
Perk Property V4F_VoreBurden3 Auto Const
Perk Property V4F_VoreBurden4 Auto Const
Perk Property V4F_VoreBurden5 Auto Const

Actor Player

; Called when the quest initializes
Event OnInit()
    Setup()
EndEvent

function Setup()
    Player = Game.GetPlayer()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    RegisterForCustomEvent(VoreCore, "BodyMassEvent")
endfunction

; ======
; EVENTS
; ======
Event Actor.OnPlayerLoadGame(Actor akSender)
	Setup()
EndEvent

Event V4F_VoreCore.BodyMassEvent(V4F_VoreCore sender, Var[] args)
    float burden = args[0] as float
    ApplyPerks(burden)
endevent

; ========
; Public
; ========

; ========
; Private
; ========

function ApplyPerks(float burden)
    Player.RemovePerk(V4F_VoreBurden1)
    Player.RemovePerk(V4F_VoreBurden2)
    Player.RemovePerk(V4F_VoreBurden3)
    Player.RemovePerk(V4F_VoreBurden4)
    Player.RemovePerk(V4F_VoreBurden5)
    if burden >= 0.2
        Player.AddPerk(V4F_VoreBurden1)
    endif
    if burden >= 0.4
        Player.AddPerk(V4F_VoreBurden2)
    endif
    if burden >= 0.6
        Player.AddPerk(V4F_VoreBurden3)
    endif
    if burden >= 0.8
        Player.AddPerk(V4F_VoreBurden4)
    endif
    if burden >= 1.0
        Player.AddPerk(V4F_VoreBurden5)
    endif
endfunction