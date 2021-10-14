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
    Debug.Trace("Burden:" + burden)
    Player.SetValue(SpeedMult, 100)
    Player.RemovePerk(V4F_VoreBurden1)
    Player.RemovePerk(V4F_VoreBurden2)
    Player.RemovePerk(V4F_VoreBurden3)
    Player.RemovePerk(V4F_VoreBurden4)
    Player.RemovePerk(V4F_VoreBurden5)
    if burden >= 0.4
        Player.SetValue(SpeedMult, 80)
        Player.AddPerk(V4F_VoreBurden1)
    endif
    if burden >= 0.6
        Player.SetValue(SpeedMult, 60)
        
        Player.AddPerk(V4F_VoreBurden2)
    endif
    if burden >= 1.0
        Player.SetValue(SpeedMult, 30)
        
        Player.AddPerk(V4F_VoreBurden3)
    endif
    if burden >= 2.0
        Player.SetValue(SpeedMult, 15)
        
        Player.AddPerk(V4F_VoreBurden4)
    endif
    if burden >= 5.0
        Player.SetValue(SpeedMult, 10)
        Player.AddPerk(V4F_VoreBurden5)
    endif
endfunction