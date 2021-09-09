Scriptname V4F_BodyMorph extends Quest

V4F_VoreCore Property VoreCore Auto Const Mandatory

float PI = 3.14159 const

Actor Player

float morphFrame
int morphQueue = 0

float bigBellyA
float bigBellyB
float tummyTuckA
float tummyTuckB
float pregA
float pregB
float giantBellyA
float giantBellyB
float breastsA
float breastsB
float breastsHA
float breastsHB
float breastsTA
float breastsTB
float breastsDA
float breastsDB
float breastsFA
float breastsFB

event OnInit()
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "BodyUpdate")
endevent

function StartMorph()
    GotoState("Morphin")
    V4F_VoreCore:Body body = VoreCore.PlayerBody
    Debug.Trace("MorphBody:" + body)

    morphFrame = 0.0
    bigBellyA = BodyGen.GetMorph(Player, true, "BigBelly", NONE)
    bigBellyB = body.bigBelly - bigBellyA
    tummyTuckA = BodyGen.GetMorph(Player, true, "TummyTuck", NONE)
    tummyTuckB = body.tummyTuck - tummyTuckA
    pregA = BodyGen.GetMorph(Player, true, "PregnancyBelly", NONE)
    pregB = body.pregnancyBelly - pregA
    giantBellyA = BodyGen.GetMorph(Player, true, "Giant Belly (coldsteelj)", NONE)
    giantBellyB = body.giantBelly - giantBellyA
    breastsA = BodyGen.GetMorph(Player, true, "Breasts", NONE)
    breastsB = body.breasts - breastsA
    breastsHA = BodyGen.GetMorph(Player, true, "BreastsNewSH", NONE)
    breastsHB = body.breastsH - breastsHA
    breastsTA = BodyGen.GetMorph(Player, true, "BreastsTogether", NONE)
    breastsTB = body.breastsT - breastsTA
    breastsDA = BodyGen.GetMorph(Player, true, "DoubleMelon", NONE)
    breastsDB = body.breastsD - breastsDA
    breastsFA = BodyGen.GetMorph(Player, true, "BreastFantasy", NONE)
    breastsFB = body.breastsF - breastsFA
    
    StartTimer(0.016, 10) ; 60 fps :3
    Debug.Trace("Morphin")
endfunction

event OnTimer(int timer)
    if timer != 11
        return
    endif
    Debug.Trace("Deferred Morphin")
    GotoState("Morphin")
    StartMorph()
endevent

event V4F_VoreCore.BodyUpdate(V4F_VoreCore caller, Var[] args)
    Debug.Trace("Immediate Morphin")
    morphQueue = 0
    StartMorph()
endevent

state Morphin
    event V4F_VoreCore.BodyUpdate(V4F_VoreCore caller, Var[] args)
        morphQueue += 1
        Debug.Trace("Morphin Queued:" + morphQueue)
    endevent

    event OnTimer(int timer)
        float easing = easeInOutQuad(morphFrame)
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, bigBellyB * easing + bigBellyA)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, tummyTuckB * easing + tummyTuckA)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, pregB * easing + pregA)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, giantBellyB * easing + giantBellyA)
        BodyGen.SetMorph(Player, true, "Breasts", NONE, breastsB * easing + breastsA)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, breastsHB * easing + breastsHA)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, breastsTB * easing + breastsTA)
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, breastsDA * easing + breastsDB)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, breastsFA * easing + breastsFA)

        BodyGen.UpdateMorphs(Player)
        if easing < 1.0 && morphFrame < 1.0
            morphFrame += 0.04
            StartTimer(0.016, 10) ; 60 fps :3
        else
            if morphQueue > 0
                Debug.Trace("Starting queued morph:" + morphQueue)
                morphQueue -= 1
                StartMorph()
            else
                Debug.Trace("Done Morphin")
                GotoState("")
            endif
        endif
    endevent
endstate

; https://github.com/Michaelangel007/easing
float function easeLinear(float p)
    return p
endfunction

float function easeInOutSine(float p)
    return 0.5*(1 - Math.cos(p * PI))
endfunction

float function easeInOutQuad(float p)
    float m = p - 1
    return 1 - m * m
endfunction

; For some reason, F4 has bullshit trig functions that make no sense.
float function easeOutElastic(float p)
    return 1 + (Math.pow(2, 10 * -p) * Math.sin((-p * 40 - 3) * PI / 6))
endfunction