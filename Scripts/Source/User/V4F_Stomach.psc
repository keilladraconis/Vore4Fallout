Scriptname V4F_Stomach extends Quest
{Handles all digestion mechanics.}

V4F_VoreCore Property VoreCore Auto Const Mandatory

; Increment to update script properties.
int stomachVersion = 3
float stomachPrey = 0.0
float stomachFood = 0.0

; Digesting at a rate of 1 full belly per 8 hours is 0.0025 per 1 seconds
float digestionRate = 0.00034 
; How many calories in a full stomach, if for example it was 60 gallons of milk.
float calorieDensity = 144000.0

event OnInit()
    RegisterForCustomEvent(VoreCore, "VoreUpdate")
    RegisterForCustomEvent(VoreCore, "SleepUpdate")
endevent

; Increment the version, then use this function to update properties.
function Update(int version)
    stomachVersion = version
    digestionRate = 0.00034
endfunction

function FetchPlayerVore()
    V4F_VoreCore:Vore vore = VoreCore.PlayerVore
    stomachPrey = vore.prey
    stomachFood = vore.food
endfunction

function StomachDigest(float time = 10.0)
    float timeDigest = time * digestionRate
    if stomachPrey > 0
        VoreCore.Digest(timeDigest * 2, timeDigest, 0)
    elseif stomachFood > 0  
        VoreCore.Digest(timeDigest, 0, timeDigest * calorieDensity)
    endif
endfunction

event V4F_VoreCore.VoreUpdate(V4F_VoreCore caller, Var[] args)
    GoToState("Digesting")

    if stomachVersion < 3
        Update(3)
    endif

    FetchPlayerVore()
    StartTimer(10.0, 1)
endevent

event V4F_VoreCore.SleepUpdate(V4F_VoreCore caller, Var[] args)
    Debug.Trace("Digest SleepUpdate:" + args)
    float time = args[0] as float
    FetchPlayerVore()
    StomachDigest(time)
endevent

state Digesting
    ; Skip vore updates if we're already digesting.
    event V4F_VoreCore.VoreUpdate(V4F_VoreCore caller, Var[] args)
        Debug.Trace("DigestTimer VoreUpdate")

        FetchPlayerVore()
        StartTimer(10.0, 1)
    endevent

    event OnTimer(int timer)
        Debug.Trace("DigestTimer - prey:" + stomachPrey + " food:" + stomachFood)
        StomachDigest()
        GoToState("")
    endevent
endstate