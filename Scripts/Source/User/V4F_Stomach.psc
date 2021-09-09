Scriptname V4F_Stomach extends Quest
{Handles all digestion mechanics.}

V4F_VoreCore Property VoreCore Auto Const Mandatory

; Increment to update script properties.
int stomachVersion = 1
float stomachPrey = 0.0
float stomachFood = 0.0

; Digesting at a rate of 1 full belly per 8 hours is 0.025 per 10 seconds
float digestionRate = 0.034 
; How many calories in a full stomach, if for example it was 60 gallons of milk.
float calorieDensity = 144000.0

event OnInit()
    RegisterForCustomEvent(VoreCore, "VoreUpdate")
endevent

; Increment the version, then use this function to update properties.
function Update(int version)
    stomachVersion = version
endfunction

event V4F_VoreCore.VoreUpdate(V4F_VoreCore caller, Var[] args)
    GoToState("Digesting")

    if stomachVersion < 1
        Update(1)
    endif

    V4F_VoreCore:Vore vore = (args[0] as V4F_VoreCore:Vore)
    stomachPrey = vore.prey
    stomachFood = vore.food
    StartTimer(10.0, 1)
    Debug.Trace("prey:" + stomachPrey + " food:" + stomachFood)
endevent

state Digesting
    ; Skip vore updates if we're already digesting.
    event V4F_VoreCore.VoreUpdate(V4F_VoreCore caller, Var[] args)
        Debug.Trace("DigestTimer VoreUpdate")

        V4F_VoreCore:Vore vore = args[0] as V4F_VoreCore:Vore
        stomachPrey = vore.prey
        stomachFood = vore.food
        StartTimer(10.0, 1)
    endevent

    event OnTimer(int timer)
        Debug.Trace("DigestTimer")
        if stomachPrey > 0
            VoreCore.Digest(digestionRate * 2, digestionRate, 0)
        elseif stomachFood > 0  
            VoreCore.Digest(digestionRate * 10, 0, digestionRate * calorieDensity)
        endif
        GoToState("")
    endevent
endstate