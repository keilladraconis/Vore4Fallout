Scriptname V4F_BodyMorph extends Quest

V4F_VoreCore Property VoreCore Auto Const Mandatory

float PI = 3.14159 const

Actor Player

float morphFrame

float bigBellyA
float bigBellyB
float giantBellyA
float giantBellyB

event OnInit()
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "BodyUpdate")
endevent

event V4F_VoreCore.BodyUpdate(V4F_VoreCore caller, Var[] args)
    V4F_VoreCore:Body body = (args[0] as V4F_VoreCore:Body)

    morphFrame = 0.0
    bigBellyA = BodyGen.GetMorph(Player, true, "BigBelly", NONE)
    bigBellyB = body.bigBelly - bigBellyA
    giantBellyA = BodyGen.GetMorph(Player, true, "Giant Belly (coldsteelj)", NONE)
    giantBellyB = 1.0
    
    StartTimer(0.016) ; 60 fps :3
endevent

event OnTimer(int timer)
    float easing = easeNone(morphFrame)
    float bbVal = bigBellyB * easing + bigBellyA
    Debug.Trace("MF: " + morphFrame + " Easing: " + easing + " BB: " + bbVal)
    BodyGen.SetMorph(Player, true, "BigBelly", NONE, bbVal)
    BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, giantBellyB * easing + giantBellyA)

    BodyGen.UpdateMorphs(Player)
    if easing < 1
        morphFrame += 0.005
        StartTimer(0.016) ; 60 fps :3
    else
        Debug.Trace("Done!")
    endif
endevent

; https://github.com/Michaelangel007/easing
float function easeNone(float time)
    return time
endfunction

float function easeInOutSine(float time)
    return -(Math.cos(Math.DegreesToRadians(PI * time)) - 1.0)
endfunction
