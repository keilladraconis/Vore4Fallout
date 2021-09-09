Scriptname V4F_BodyMorph extends Quest

V4F_VoreCore Property VoreCore Auto Const Mandatory

float PI = 3.14159 const

Actor Player

float morphFrame

float bigBellyA
float bigBellyB
float tummyTuckA
float tummyTuckB
float pregA
float pregB
float giantBellyA
float giantBellyB

event OnInit()
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "BodyUpdate")
endevent

function ReadBodyUpdateArgs(Var[] args)
    V4F_VoreCore:Body body = (args[0] as V4F_VoreCore:Body)

    morphFrame = 0.0
    bigBellyA = BodyGen.GetMorph(Player, true, "BigBelly", NONE)
    bigBellyB = body.bigBelly - bigBellyA
    tummyTuckA = BodyGen.GetMorph(Player, true, "TummyTuck", NONE)
    tummyTuckB = body.tummyTuck - tummyTuckA
    pregA = BodyGen.GetMorph(Player, true, "PregnancyBelly", NONE)
    pregB = body.pregnancyBelly - pregA
    giantBellyA = BodyGen.GetMorph(Player, true, "Giant Belly (coldsteelj)", NONE)
    giantBellyB = body.giantBelly - giantBellyA
endfunction

event V4F_VoreCore.BodyUpdate(V4F_VoreCore caller, Var[] args)
    GotoState("Morphin")
    ReadBodyUpdateArgs(args)
    
    StartTimer(0.016) ; 60 fps :3
    Debug.Trace("Morphin")
endevent

state Morphin
    event V4F_VoreCore.BodyUpdate(V4F_VoreCore caller, Var[] args)
        Debug.Trace("Morphin BodyUpdate")
        ReadBodyUpdateArgs(args)        
    endevent

    event OnTimer(int timer)
        float easing = easeInOutQuad(morphFrame)
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, bigBellyB * easing + bigBellyA)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, tummyTuckB * easing + tummyTuckA)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, pregB * easing + pregA)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, giantBellyB * easing + giantBellyA)

        BodyGen.UpdateMorphs(Player)
        if easing < 1
            morphFrame += 0.01
            StartTimer(0.016) ; 60 fps :3
        else
            Debug.Trace("Done Morphin")
            GotoState("")
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