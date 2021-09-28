Scriptname V4F_VoreSurvival extends Quest

Hardcore:HC_ManagerScript Property HC_Manager Auto
V4F_VoreCore Property VoreCore Auto

event OnInit()
    Setup()
endevent

function Setup()
    RegisterForRemoteEvent(VoreCore, "OnDigest")
endfunction

Event V4F_VoreCore.OnDigest(V4F_VoreCore akSender, Var[] akArgs)
    HC_Manager.ModFoodPoolAndUpdateHungerEffects(9999, true)
EndEvent