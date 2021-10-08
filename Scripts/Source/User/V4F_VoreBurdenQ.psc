Scriptname V4F_VoreBurdenQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_VoreBurden1 Auto Const
Perk Property V4F_VoreBurden2 Auto Const
Perk Property V4F_VoreBurden3 Auto Const
Perk Property V4F_VoreBurden4 Auto Const
Perk Property V4F_VoreBurden5 Auto Const
Perk Property V4F_Agility1 Auto Const
Perk Property V4F_Agility2 Auto Const
Perk Property V4F_Agility3 Auto Const
Perk Property V4F_Agility4 Auto Const
Perk Property V4F_Agility5 Auto Const
ActorValue Property SpeedMult Auto

Actor Player

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "BodyMassEvent")
EndEvent

; ======
; EVENTS
; ======
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
    Player.SetValue(SpeedMult, 100)
    Player.RemovePerk(V4F_VoreBurden1)
    Player.RemovePerk(V4F_VoreBurden2)
    Player.RemovePerk(V4F_VoreBurden3)
    Player.RemovePerk(V4F_VoreBurden4)
    Player.RemovePerk(V4F_VoreBurden5)
    if burden >= 0.2
        if !Player.HasPerk(V4F_Agility1)
            Player.SetValue(SpeedMult, 80)
        endif
        Player.AddPerk(V4F_VoreBurden1)
    endif
    if burden >= 0.4
        if !Player.HasPerk(V4F_Agility2)
            Player.SetValue(SpeedMult, 60)
        endif
        
        Player.AddPerk(V4F_VoreBurden2)
    endif
    if burden >= 0.6
        if !Player.HasPerk(V4F_Agility3)
            Player.SetValue(SpeedMult, 30)
        endif
        
        Player.AddPerk(V4F_VoreBurden3)
    endif
    if burden >= 0.8
        if !Player.HasPerk(V4F_Agility4)
            Player.SetValue(SpeedMult, 10)
        endif
        
        Player.AddPerk(V4F_VoreBurden4)
    endif
    if burden >= 1.0
        if !Player.HasPerk(V4F_Agility5)
            Player.SetValue(SpeedMult, 5)
        endif
        Player.AddPerk(V4F_VoreBurden5)
    endif
endfunction