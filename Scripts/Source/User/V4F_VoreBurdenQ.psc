Scriptname V4F_VoreBurdenQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell PRoperty V4F_VoreBurden Auto Const
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
Furniture Property Immobile Auto

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
    
    if Player.HasPerk(V4F_Agility5)
        burden -= 2.0
    elseif Player.HasPerk(V4F_Agility4)
        burden -= 1.0
    elseif Player.HasPerk(V4F_Agility3)
        burden -= 0.8
    elseif Player.HasPerk(V4F_Agility2)
        burden -= 0.5
    elseif Player.HasPerk(V4F_Agility1)
        burden -= 0.3
    endif

    if burden >= 5.0
        Debug.Notification("You're immobilized.")
        DoPlayerLieDown()
        Player.SetValue(SpeedMult, 10)
        Player.AddPerk(V4F_VoreBurden5)
        Player.AddPerk(V4F_VoreBurden4)
        Player.AddPerk(V4F_VoreBurden3)
        Player.AddPerk(V4F_VoreBurden2)
        Player.AddPerk(V4F_VoreBurden1)
        Player.AddSpell(V4F_VoreBurden, false)
    elseif burden >= 2.0
        Debug.Notification("You're barely able to move.")
        Player.SetValue(SpeedMult, 15)
        Player.RemovePerk(V4F_VoreBurden5)
        Player.AddPerk(V4F_VoreBurden4)
        Player.AddPerk(V4F_VoreBurden3)
        Player.AddPerk(V4F_VoreBurden2)
        Player.AddPerk(V4F_VoreBurden1)
        Player.AddSpell(V4F_VoreBurden, false)
    elseif burden >= 1.0
        Player.SetValue(SpeedMult, 30)
        Player.RemovePerk(V4F_VoreBurden5)
        Player.RemovePerk(V4F_VoreBurden4)
        Player.AddPerk(V4F_VoreBurden3)
        Player.AddPerk(V4F_VoreBurden2)
        Player.AddPerk(V4F_VoreBurden1)
        Player.AddSpell(V4F_VoreBurden, false)
    elseif burden > 0.6
        Player.SetValue(SpeedMult, 60)
        Player.RemovePerk(V4F_VoreBurden5)
        Player.RemovePerk(V4F_VoreBurden4)
        Player.RemovePerk(V4F_VoreBurden3)
        Player.AddPerk(V4F_VoreBurden2)
        Player.AddPerk(V4F_VoreBurden1)
        Player.AddSpell(V4F_VoreBurden, false)
    elseif burden >= 0.4
        Player.SetValue(SpeedMult, 80)
        Player.RemovePerk(V4F_VoreBurden5)
        Player.RemovePerk(V4F_VoreBurden4)
        Player.RemovePerk(V4F_VoreBurden3)
        Player.RemovePerk(V4F_VoreBurden2)
        Player.AddPerk(V4F_VoreBurden1)
        Player.AddSpell(V4F_VoreBurden, false)
    else
        Player.RemovePerk(V4F_VoreBurden1)
        Player.RemovePerk(V4F_VoreBurden2)
        Player.RemovePerk(V4F_VoreBurden3)
        Player.RemovePerk(V4F_VoreBurden4)
        Player.RemovePerk(V4F_VoreBurden5)
        Player.RemoveSpell(V4F_VoreBurden)
    endif
endfunction

function DoPlayerLieDown()
    Debug.Trace("Lying Down: " + Player.GetSitState())
    If (Player.Getsitstate() == 0)
		Player.PlaceAtMe(Immobile as Form, 1, False, False, True)
	EndIf
endfunction