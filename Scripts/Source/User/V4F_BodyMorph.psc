Scriptname V4F_BodyMorph extends Quest

V4F_VoreCore Property VoreCore Auto Const Mandatory

float PI = 3.14159 const

Actor Player

float morphFrame
int morphQueue = 0

float voreBellyA
float voreBellyB
float bbwA
float bbwB
float giantBellyUpA
float giantBellyUpB
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
float buttA
float buttB
float buttChubbyA
float buttChubbyB
float buttThighsA
float buttThighsB
float buttWaistA
float buttWaistB
float buttBackA
float buttBackB
float buttBigA
float buttBigB
float buttCLegsA
float buttCLegsB
float buttCWaistA
float buttCWaistB
float buttAppleA
float buttAppleB
float buttRoundA
float buttRoundB

event OnInit()
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "BodyUpdate")
endevent

function StartMorph()
    GotoState("Morphin")
    V4F_VoreCore:Body body = VoreCore.PlayerBody
    Debug.Trace("MorphBody:" + body)

    morphFrame = 0.0

    voreBellyA = BodyGen.GetMorph(Player, true, "Vore prey belly", NONE)
    voreBellyB = body.vorePreyBelly - voreBellyA
    bbwA = BodyGen.GetMorph(Player, true, "SSBBW3 body", NONE)
    bbwB = body.bbw - bbwA
    giantBellyUpA = BodyGen.GetMorph(Player, true, "Giant belly up", NONE)
    giantBellyUpB = body.giantBellyUp - giantBellyUpA
    bigBellyA   = BodyGen.GetMorph(Player, true, "BigBelly", NONE)
    bigBellyB   = body.bigBelly - bigBellyA
    tummyTuckA  = BodyGen.GetMorph(Player, true, "TummyTuck", NONE)
    tummyTuckB  = body.tummyTuck - tummyTuckA
    pregA       = BodyGen.GetMorph(Player, true, "PregnancyBelly", NONE)
    pregB       = body.pregnancyBelly - pregA
    giantBellyA = BodyGen.GetMorph(Player, true, "Giant Belly (coldsteelj)", NONE)
    giantBellyB = body.giantBelly - giantBellyA
    breastsA    = BodyGen.GetMorph(Player, true, "Breasts", NONE)
    breastsB    = body.breasts - breastsA
    breastsHA   = BodyGen.GetMorph(Player, true, "BreastsNewSH", NONE)
    breastsHB   = body.breastsH - breastsHA
    breastsTA   = BodyGen.GetMorph(Player, true, "BreastsTogether", NONE)
    breastsTB   = body.breastsT - breastsTA
    breastsDA   = BodyGen.GetMorph(Player, true, "DoubleMelon", NONE)
    breastsDB   = body.breastsD - breastsDA
    breastsFA   = BodyGen.GetMorph(Player, true, "BreastFantasy", NONE)
    breastsFB   = body.breastsF - breastsFA
    buttA       = BodyGen.GetMorph(Player, true, "Butt", NONE)
    buttB       = body.butt - buttA
    buttChubbyA = BodyGen.GetMorph(Player, true, "ChubbyButt", NONE)
    buttChubbyB = body.buttChubby - buttChubbyA
    buttThighsA = BodyGen.GetMorph(Player, true, "Thighs", NONE)
    buttThighsB = body.buttThighs - buttThighsA
    buttWaistA  = BodyGen.GetMorph(Player, true, "Waist", NONE)
    buttWaistB  = body.buttWaist - buttWaistA
    buttBackA   = BodyGen.GetMorph(Player, true, "Back", NONE)
    buttBackB   = body.buttBack - buttBackA
    buttBigA    = BodyGen.GetMorph(Player, true, "BigButt", NONE)
    buttBigB    = body.buttBig - buttBigA
    buttCLegsA  = BodyGen.GetMorph(Player, true, "ChubbyLegs", NONE)
    buttCLegsB  = body.buttCLegs - buttCLegsA
    buttCWaistA = BodyGen.GetMorph(Player, true, "ChubbyWaist", NONE)
    buttCWaistB = body.buttCWaist - buttCWaistA
    buttAppleA  = BodyGen.GetMorph(Player, true, "AppleCheeks", NONE)
    buttAppleB  = body.buttApple - buttAppleA
    buttRoundA  = BodyGen.GetMorph(Player, true, "RoundAss", NONE)
    buttRoundB  = body.buttRound - buttRoundA
    
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
        BodyGen.SetMorph(Player, true, "Vore prey belly", NONE, voreBellyB * easing + voreBellyA)
        BodyGen.SetMorph(Player, true, "SSBBW3 body", NONE, bbwB * easing + bbwA)
        BodyGen.SetMorph(Player, true, "Giant belly up", NONE, giantBellyUpB * easing + giantBellyUpA)
        BodyGen.SetMorph(Player, true, "BigBelly", NONE, bigBellyB * easing + bigBellyA)
        BodyGen.SetMorph(Player, true, "TummyTuck", NONE, tummyTuckB * easing + tummyTuckA)
        BodyGen.SetMorph(Player, true, "PregnancyBelly", NONE, pregB * easing + pregA)
        BodyGen.SetMorph(Player, true, "Giant Belly (coldsteelj)", NONE, giantBellyB * easing + giantBellyA)
        BodyGen.SetMorph(Player, true, "Breasts", NONE, breastsB * easing + breastsA)
        BodyGen.SetMorph(Player, true, "BreastsNewSH", NONE, breastsHB * easing + breastsHA)
        BodyGen.SetMorph(Player, true, "BreastsTogether", NONE, breastsTB * easing + breastsTA)
        BodyGen.SetMorph(Player, true, "DoubleMelon", NONE, breastsDB * easing + breastsDA)
        BodyGen.SetMorph(Player, true, "BreastFantasy", NONE, breastsFB * easing + breastsFA)
        BodyGen.SetMorph(Player, true, "Butt", NONE, buttB * easing + buttA)
        BodyGen.SetMorph(Player, true, "ChubbyButt", NONE, buttChubbyB * easing + buttChubbyA)
        BodyGen.SetMorph(Player, true, "Thighs", NONE, buttThighsB * easing + buttThighsA)
        BodyGen.SetMorph(Player, true, "Waist", NONE, buttWaistB * easing + buttWaistA)
        BodyGen.SetMorph(Player, true, "Back", NONE, buttBackB * easing + buttBackA)
        BodyGen.SetMorph(Player, true, "BigButt", NONE, buttBigB * easing + buttBigA)
        BodyGen.SetMorph(Player, true, "ChubbyLegs", NONE, buttCLegsB * easing + buttCLegsA)
        BodyGen.SetMorph(Player, true, "ChubbyWaist", NONE, buttCWaistB * easing + buttCWaistA)
        BodyGen.SetMorph(Player, true, "AppleCheeks", NONE, buttAppleB * easing + buttAppleA)
        BodyGen.SetMorph(Player, true, "RoundAss", NONE, buttRoundB * easing + buttRoundA)

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