Scriptname Hardcore:HC_ManagerScript extends Quest conditional

;**************************************************************************************************
;**************************************   INITIALIZATION    ***************************************
;**************************************************************************************************

Event OnInit()
	trace(self, "OnInit()")

	; We may need this later...
	PlayerRef = Game.GetPlayer()
	RegisterForRemoteEvent(PlayerRef, "OnDifficultyChanged") ;for turning it all off...
	
	; If we're playing Hardcore lets get everything turned on... Otherwise lets remove all effects.
	if (Game.GetDifficulty() == 6)
		trace(self, "OnInit() - Difficulty is set to Survival. Starting up...")
		StartupHardcore()
	else
		trace(self, "OnInit() - Difficulty is not set to Survival. Sleeping for now...")
	endif

EndEvent

;**************************************************************************************************
;***********************************     STARTUP & SHUTDOWN     ***********************************
;**************************************************************************************************

; It rubs the lotion on its skin...
Function StartupHardcore()
	trace(self, "StartupHardcore()")

	if !bHardcoreIsRunning

		FoodItems = new form[0]

		; Set our max adrenaline as defined by these other two values...
		MaxAdrenaline = KillsForAdrenalinePerkLevel * MaxAdrenalinePerkLevel

		HC_HoursToRespawnCellMult.SetValue(HoursToRespawnCellMult)
		HC_HoursToRespawnCellClearedMult.SetValue(HoursToRespawnCellClearedMult)

		RegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame") ;for not disabling the sleep message.

		RegisterForRemoteEvent(PlayerRef, "OnKill") ;for awarding Adrenaline

		RegisterForPlayerSleep() ; for resetting adrenaline
		RegisterForPlayerWait()

		RegisterForRemoteEvent(PlayerRef, "OnCombatStateChanged") ;for hunger effects
		RegisterForRemoteEvent(PlayerRef, "OnItemEquipped") ;for hunger effects

		RegisterForHitEvent(PlayerRef, DiseaseRiskCombatantFactions) ; for getting diseased when hit by these combatants
		RegisterForRemoteEvent(PlayerRef, "OnPlayerSwimming") ;for disease

		RegisterForCustomEvent(Followers, "CompanionChange") ;DONT UNREGISTER - for toggling companion no bleedout recovery
		RegisterForRemoteEvent(Companion, "OnEnterBleedout") ;for dismissing if player gets too far away while bleeding out
		RegisterForRemoteEvent(DogmeatCompanion, "OnEnterBleedout") ;for dismissing if player gets too far away while bleeding out
		RegisterForRemoteEvent(PlayerRef, "OnPlayerHealTeammate") ;DONT UNREGISTER - for toggling off variable that means player should heal companion
	
		RegisterForMenuOpenCloseEvent("PipboyMenu") ;for toggling off the fast travel tutorial

		RegisterForRemoteEvent(PlayerRef, "OnLocationChange") ;for toggling map marker fast travel allowances while in the institute		

		playerRef.addPerk(HC_SustenanceEffectsTurnOffFood)
		playerRef.addPerk(HC_FillWaterBottlePerk)

		;we don't need to remove these because the condition itself is conditioned, and we don't know how to find them again if they aren't currently a companion
		AddReduceCarryWeightAbility(Companion.GetActorReference())
		AddReduceCarryWeightAbility(DogmeatCompanion.GetActorReference())
		AddReduceCarryWeightAbility(PlayerRef)

		HC_Vendor_Antiboitic_ChanceNone.setvalue(0) ;turns on vendors selling antiboitics
		HC_Medkit_Antiboitic_ChanceNone.setvalue(0) ;turns on finding antiboitics

		; HACK! The game clock gets adjusted early game to set lighting and such.
		; This will fix out clocks from getting out of alignment on new game start.
		bTimersInitialized = false
		StartTimer(1.0, RealTimerID_HackClockSyncer)

		trace(self, "  StartupHardcore(): Hardcore is now running.")
	else
		trace(self, "  StartupHardcore(): Hardcore was already running.")
	endif

	bHardcoreIsRunning = true

	CompanionSetNoBleedoutRecovery(Companion.GetActorReference(), true)
	CompanionSetNoBleedoutRecovery(DogmeatCompanion.GetActorReference(), true)

EndFunction

; I WANT IT SHUT DOWN... ALL OF IT!
Function ShutdownHardcore()
	trace(self, "ShutdownHardcore()")

	Tutorial.RegisterForTutorialEvent("OnEnterPipBoyMapPage")

	FoodItems = none

	HC_HoursToRespawnCellMult.SetValue(1.0)
	HC_HoursToRespawnCellClearedMult.SetValue(1.0)

	UnRegisterForRemoteEvent(PlayerRef, "OnPlayerLoadGame") ;for not disabling the sleep message.

	UnRegisterForRemoteEvent(PlayerRef, "OnKill") ;for awarding Adrenaline

	UnRegisterForPlayerSleep() ; for resetting adrenaline
	UnRegisterForPlayerWait()

	UnRegisterForRemoteEvent(PlayerRef, "OnCombatStateChanged") ;for hunger effects
	UnRegisterForRemoteEvent(PlayerRef, "OnItemEquipped") ;for hunger effects

	UnRegisterForHitEvent(PlayerRef, DiseaseRiskCombatantFactions) ; for getting diseased when hit by these combatants
	UnRegisterForRemoteEvent(PlayerRef, "OnPlayerSwimming") ;for disease

	UnRegisterForRemoteEvent(Companion, "OnEnterBleedout") ;for dismissing if player gets too far away while bleeding out
	UnRegisterForRemoteEvent(DogmeatCompanion, "OnEnterBleedout") ;for dismissing if player gets too far away while bleeding out

	CancelTimer(RealTimerID_HackClockSyncer)
	CancelTimerGameTime(GameTimerID_SleepDeprivation)
	CancelTimerGameTime(GameTimerID_Sustenance)
	CancelTimerGameTime(GameTimerID_Disease)
	CancelTimerGameTime(GameTimerID_Encumbrance) 
	
	; remove diseases
	ClearDisease()
	HC_Vendor_Antiboitic_ChanceNone.setvalue(100) ;turns off vendors selling antiboitics
	HC_Medkit_Antiboitic_ChanceNone.setvalue(100) ;turns off finding antiboitics

	; remove sleep and sustenance effects
	FoodPool = 0
	PlayerRef.SetValue(HC_HungerEffect, HC_HE_Fed.GetValue())
	ApplyEffect(HC_Rule_SustenanceEffects, HungerEffects, HC_HungerEffect, bBypassGlobalCheck = true)

	playerRef.removePerk(HC_SustenanceEffectsTurnOffFood)
	
	;turn off cannibal effect ravenous hunger
	CureRavenousHunger()

	DrinkPool = 0
	PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Hydrated.GetValue())
	ApplyEffect(HC_Rule_SustenanceEffects, ThirstEffects, HC_ThirstEffect, bBypassGlobalCheck = true)
	
	PlayerRef.SetValue(HC_SleepEffect,  HC_SE_Rested.GetValue())
	ApplyEffect(HC_Rule_SleepEffects,      SleepEffects,  HC_SleepEffect,  bBypassGlobalCheck = true)
	playerRef.removePerk(HC_AdrenalinePerk)
	
	playerRef.removePerk(HC_WellRestedPerk)
	playerRef.removePerk(HC_LoversEmbracePerk)

	ClearFatigue()

	; remove encumbrance effect
	PlayerRef.UnEquipItem(HC_EncumbranceEffect_OverEncumbered, abSilent = true)
	
	CompanionSetNoBleedoutRecovery(Companion.GetActorReference(), false)
	CompanionSetNoBleedoutRecovery(DogmeatCompanion.GetActorReference(), false)

	bHardcoreIsRunning = false
	trace(self, "  ShutdownHardcore(): Hardcore is no longer running.")
	
EndFunction

Event Actor.OnDifficultyChanged(actor aSender, int aOldDifficulty, int aNewDifficulty)
	trace(self, "OnDifficultyChanged() aOldDifficulty, aNewDifficulty: " + aOldDifficulty + ", " + aNewDifficulty)

	if (aOldDifficulty != 6) && (aNewDifficulty == 6)
		trace(self, "  Player wants hardcore mode...")
		StartupHardcore()
	elseif (aOldDifficulty == 6) && (aNewDifficulty != 6)
		trace(self, "  Player no longer wants hardcore mode...")
		ShutdownHardcore()
	endif

EndEvent

;FOR DEBUG PRIOR TO CODE SWITCH (can come out later)
Function SetHardcoreMode(bool HardcoreModeOn = true)
	
	RegisterForRemoteEvent(Game.GetPlayer(), "OnDifficultyChanged") ;for turning it all off...

	int i = 0
	while (i < HC_Rules.GetSize())
		SetGlobal(HC_Rules.GetAt(i) as GlobalVariable, HardcoreModeOn)
		i += 1
	endwhile
	
	if HardcoreModeOn
		trace(self, "  Player wants hardcore mode...")
		StartupHardcore()
	elseif !HardcoreModeOn
		trace(self, "  Player no longer wants hardcore mode...")
		ShutdownHardcore()
	endif

EndFunction

;**************************************************************************************************
;**************************************       COMMON        ***************************************
;**************************************************************************************************

Group CommonProperties
	Formlist Property HC_Rules const auto mandatory
	ActorValue property Fatigue auto const mandatory; FatigueAV

	FollowersScript Property Followers const auto mandatory
	{Autofill; needed for reimplementing lover's embrace and turning off bleedout recovery}

	keyword[] Property NonFoodKeywords auto const mandatory

	; Globals for altering the world reset times.
	float Property HoursToRespawnCellMult = 5.0 const auto
	float Property HoursToRespawnCellClearedMult = 4.0 const auto
	globalvariable Property HC_HoursToRespawnCellMult const auto
	globalvariable Property HC_HoursToRespawnCellClearedMult const auto

EndGroup

; TUTORIALS
;;;;;;;;;;;;;;;;;;
Struct HC_Tutorial
	message MessageToDisplay
	int     TimesToDisplay = 1
	int     TimesDisplayed hidden
	float   GameDaysBetweenDisplays = 0.01
	float   LastTimeDisplayed hidden
EndStruct

; Checks to see if we should display the current tutorial and displays it.
bool Function TryTutorial(HC_Tutorial t, string EventName)
	float DaysUntilNextDisplay = 0
	trace(self, "TryTutorial()   - Tutorial: " + EventName + ",       TimesDisplayed: " + t.TimesDisplayed)
	trace(self, "  TryTutorial() - Tutorial: " + EventName + ",       TimesToDisplay: " + t.TimesToDisplay)
	if t.TimesDisplayed < t.TimesToDisplay
		float currentGameTime = Utility.GetCurrentGameTime()
		float nextDisplayTime = t.LastTimeDisplayed + t.GameDaysBetweenDisplays
		if currentGameTime > nextDisplayTime
			t.MessageToDisplay.ShowAsHelpMessage(EventName, 8, 0, 1, "")
			t.TimesDisplayed += 1
			t.LastTimeDisplayed = currentGameTime
			trace(self, "  TryTutorial() - Show Tutorial: " + EventName + ", TimesDisplayed: " + t.TimesDisplayed)
			return true
		endif
		DaysUntilNextDisplay = nextDisplayTime - currentGameTime
		trace(self, "  TryTutorial() - Tutorial: " + EventName + ", DaysUntilNextDisplay: " + DaysUntilNextDisplay)
	endif
	trace(self, "  TryTutorial() - Hide Tutorial: " + EventName + ", TimesDisplayed: " + t.TimesDisplayed + ", DaysUntilNextDisplay: " + DaysUntilNextDisplay)
	return false
EndFunction
;;;;;;;;;;;;;;;;;;

Group Tutorials
	HC_Tutorial Property ImmunodeficiencyTutorial Auto
	HC_Tutorial Property TirednessTutorial        Auto
	HC_Tutorial Property HungerTutorial           Auto
	HC_Tutorial Property ThirstTutorial           Auto
	HC_Tutorial Property HighRiskEventTutorial    Auto
	HC_Tutorial Property DiseasedTutorial         Auto
	HC_Tutorial Property AdrenalineTutorial       Auto
	HC_Tutorial Property NonBedSleepTutorial      Auto
	HC_Tutorial Property CompanionDownedTutorial  Auto
	HC_Tutorial Property SleepToSaveTutorial      Auto
EndGroup

Actor PlayerRef ;pointwe to player, set in OnInit()

; Keep track of whether we are or are not playing Hardcore
bool bHardcoreIsRunning = false

;Global "enum" values, used by IsGlobalTrue, SetGlobal
int iGlobalTrue = 1 const
int iGlobalFalse = 0 const

; This is the absolute cap on fatigue...
float fMaxFatigue = 1000.00 const
; This is the selfimposed cap on fatigue...
float fCapFatigue =  950.00 const
; This is the lowest value Fatigue can be if not 0. This helps visually with the hud.
float fLowestNonZeroFatigue = 20.0 const

; Our epsilon value for safe floating...
float fEpsilon = 0.0001 const

;************************************     TIMERS    *********************************************
int GameTimerID_SleepDeprivation = 1 const
int GameTimerID_Encumbrance = 2 const
int GameTimerID_Sustenance = 3 const
int GameTimerID_Disease = 4 const
int RealTimerID_HackClockSyncer = 5 const
int GameTimerID_DisplaySleepMessage = 6 const
int GameTimerID_IgnoreNonWeaponHits = 7 const

Group Timers

	float Property GameTimerInterval_SleepDeprivation = 14.0 auto const ;hours

	float Property GameTimerInterval_Encumbrance = 24.0 auto const ;hours

	float Property GameTimerInterval_Sustenance = 0.1 auto const ;hours -- THIS NEEDS TO BE LESS THAN TickHoursCostPerCombat
{THIS NEEDS TO BE LESS THAN TickHoursCostPerCombat }

	float Property GameTimerInterval_Disease              = 0.333333 auto const ;hours
	float Property GameTimerInterval_DiseasePostRiskEvent = 0.033 auto const ;hours - Used as alternate to the standard disease interval.

	float Property GameTimerInterval_DisplaySleepMessage = 0.033 auto const ; hours

	float Property GameTimerInterval_IgnoreNonWeaponHits = 0.16666667 auto const  ; 30 real seconds.

EndGroup
; (seconds) Setup our Clock Resync Timer values.
float RealTimerInterval_HackClockSyncer = 30.0 const
; The game is setup so that on game start the time moves around. Need to track that to properly start our timers.
float LowestGameTimeResetTime; 
; Flag to track clock initialization. False in StartupHardcore; True on first initialization.
bool bTimersInitialized = false


Event Actor.OnPlayerLoadGame(actor aSender)
	
	;<NEW STUFF> - SUPPORTING EXISTING SAVES DURING DEVELOPMENT - can come out before shipping
	if false == PlayerRef.HasPerk(HC_FillWaterBottlePerk)
		PlayerRef.AddPerk(HC_FillWaterBottlePerk)
	endif

	if HC_Medkit_Antiboitic_ChanceNone.GetValue() == 100
		HC_Medkit_Antiboitic_ChanceNone.setvalue(0) ;turns on finding antiboitics
	endif

	; Fixup New Food Values
	if  FoodReqs < 0
		FoodReqs = FoodPool
	endif
	if  DrinkReqs < 0
		DrinkReqs = DrinkPool
	endif

	RegisterForRemoteEvent(PlayerRef, "OnPlayerHealTeammate") ;for toggling off variable that means player should heal companion
	
	;</NEW STUFF>


	float currentGameTime = Utility.GetCurrentGameTime()
	trace(self, "OnPlayerLoadGame() @ " + currentGameTime)
	
	CancelTimerGameTime(GameTimerID_DisplaySleepMessage)

	; Use the current game time to possibly update our "LastSleepUpdateDay". This is primarily an old save fix. Delete for ship?
	if currentGameTime - LastSleepUpdateDay > 1.0 || LastSleepUpdateDay > currentGameTime
		trace(self, "  OnPlayerLoadGame() Old LastSleepUpdateDay: " + LastSleepUpdateDay + ", New LastSleepUpdateDay: " + currentGameTime)
		LastSleepUpdateDay = currentGameTime
	else
		trace(self, "  OnPlayerLoadGame() LastSleepUpdateDay: " + LastSleepUpdateDay)
	endif

	; If NextSleepUpdateDay is out of whack, correct it and restart our clock to finalize the correction. This is primarily an old save fix. Delete for ship?
	if NextSleepUpdateDay < (currentGameTime - 0.05)
		float temp = NextSleepUpdateDay
		NextSleepUpdateDay = currentGameTime + (currentGameTime - LastSleepUpdateDay)
		; This just takes the time we think we should have left and adjusts it based on disease.
		StartSleepDeprivationTimer(GetHoursUntilCurrentSleepCycleEnds())
		trace(self, "  OnPlayerLoadGame() Old NextSleepUpdateDay: " + temp + ", New NextSleepUpdateDay: " + NextSleepUpdateDay)
	else
		trace(self, "  OnPlayerLoadGame() NextSleepUpdateDay: " + NextSleepUpdateDay)
	endif

	; Make sure carry weight can be updated as needed.
	RemoveReduceCarryWeightAbility(Companion.GetActorReference())
	RemoveReduceCarryWeightAbility(DogmeatCompanion.GetActorReference())
	RemoveReduceCarryWeightAbility(PlayerRef)
	AddReduceCarryWeightAbility(Companion.GetActorReference())
	AddReduceCarryWeightAbility(DogmeatCompanion.GetActorReference())
	AddReduceCarryWeightAbility(PlayerRef)

EndEvent


Event OnTimer(int aiTimerID)

	float currentGameTime = Utility.GetCurrentGameTime()
	
	; HACK! The game clock gets adjusted early game to set lighting and such.
	; This will fix out clocks from getting out of alignment on new game start.
	if aiTimerID == RealTimerID_HackClockSyncer
		
		; Initial Timer setup.  This should work regardless of how you start a new game.
		if !bTimersInitialized
			; Start our timers...
			InitializeHardcoreTimers(currentGameTime)
			trace(self, "HackClockSyncer: Setup @ " + currentGameTime + " - CLOCKS ARE SET!")
			bTimersInitialized = true

		; If we have traveled back in time, someone get Hewy Lewis on the phone and lets resync our clocks!
		elseif bHardcoreIsRunning && currentGameTime < LowestGameTimeResetTime
			; Restart our timers...
			InitializeHardcoreTimers(currentGameTime)					
			trace(self, "  HackClockSyncer: Resyncing Survival Clocks To The Game Clock! LowestGameTimeResetTime: " + currentGameTime)
		endif
			
		; Let's keep verifying we dont need travel back any further until we are out of the woods, er... Vault.
		if bHardcoreIsRunning && currentGameTime <= LowestGameTimeResetTime + 0.05
			StartTimer(RealTimerInterval_HackClockSyncer, RealTimerID_HackClockSyncer)
			trace(self, "  HackClockSyncer: Restarting Clock Sync Timer @ " + currentGameTime)
		elseif bHardcoreIsRunning
			; Hey look, we're out of the vault now...
			; Tutorial Call - Sleep To Save.
			TryTutorial(SleepToSaveTutorial, "SleepToSaveTutorial")
		endif

	endif

EndEvent

Function InitializeHardcoreTimers(float CurrentGameTime)
	
	CancelTimerGameTime(GameTimerID_SleepDeprivation)
	CancelTimerGameTime(GameTimerID_Sustenance)
	CancelTimerGameTime(GameTimerID_Disease)
	CancelTimerGameTime(GameTimerID_Encumbrance) 

	StartSleepDeprivationTimer(2.0, true)
	bFirstSleep = true
	StartTimerGameTime(GameTimerInterval_Sustenance, GameTimerID_Sustenance)
	StartTimerGameTime(GameTimerInterval_Disease,    GameTimerID_Disease)
	StartTimerGameTime(0.033,                        GameTimerID_Encumbrance)

	; The Sustenance Timer is short enough to trip mid vault.  Reseting the tick day when we reset the clock.
	NextSustenanceTickDay= 0

	; Store this update time for handling no effect clearing sleeps.
	LastSleepUpdateDay= CurrentGameTime

	; Store this update time for handling pushing off diseases for the first 24 hours.
	LastDiseasedDay= CurrentGameTime

	; Store our new low!
	LowestGameTimeResetTime= CurrentGameTime

EndFunction

Event OnTimerGameTime(int aiTimerID)
	
	float currentGameTime = Utility.GetCurrentGameTime()

	if aiTimerID == GameTimerID_SleepDeprivation
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_SleepDeprivation @ " + currentGameTime)
	
		if IsGlobalTrue(HC_Rule_SleepEffects) && ProcessingSleep == false
			HandleSleepDeprivationTimer()
		endif
		;this needs to live outside the if check, in case we allow turning on option during play
		if iCaffeinated > 0
			StartSleepDeprivationTimer(fCaffeinatedTimeTracker)
		else
			StartSleepDeprivationTimer()
		endif
		
		; The Caffeine has worn off. 
		; When we get Caffeinated we set ourselfs on a short clock and this thing clears when the time is up.
		HC_CaffeinatedEffect.Dispel()
		HC_CaffeinatedEffect  = none
		iCaffeinated          = 0
		CaffeinatedCount      = 0
		ExtraCaffeinatedCount = 0

	elseif aiTimerID == GameTimerID_Encumbrance
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_Encumbrance @ " + currentGameTime)
		if IsGlobalTrue(HC_Rule_DamageWhenEncumbered) && ProcessingSleep == false
			HandleEncumbranceTimer()
		endif
		;this needs to live outside the if check, in case we allow turning on option during play
		StartTimerGameTime(GameTimerInterval_Encumbrance, GameTimerID_Encumbrance)

	elseif aiTimerID == GameTimerID_Sustenance
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_Sustenance @ " + currentGameTime)
		if IsGlobalTrue(HC_Rule_SustenanceEffects) && ProcessingSleep == false
			HandleSustenanceTimer()
		endif
		;this needs to live outside the if check, in case we allow turning on option during play
		StartTimerGameTime(GameTimerInterval_Sustenance, GameTimerID_Sustenance)

	elseif aiTimerID == GameTimerID_Disease
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_Disease @ " + currentGameTime)
		if IsGlobalTrue(HC_Rule_DiseaseEffects) && ProcessingSleep == false
			HandleDiseaseTimer()
		endif
		;this needs to live outside the if check, in case we allow turning on option during play
		StartTimerGameTime(GameTimerInterval_Disease, GameTimerID_Disease)
	
	elseif aiTimerID == GameTimerID_DisplaySleepMessage
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_DisplaySleepMessage @ " + currentGameTime)
		; explain why he woke up early... If you didnt get what you asked for, that is.
		if EarlyWakeMessageToShow
			EarlyWakeMessageToShow.show()
			EarlyWakeMessageToShow = none
		endif

	elseif aiTimerID == GameTimerID_IgnoreNonWeaponHits
		trace(self, "OnTimerGameTime() aiTimerID: = GameTimerID_IgnoreNonWeaponHits @ " + currentGameTime)
		bIgnoreNonWeaponHits = false

	else
		trace(self, "OnTimerGameTime() NO MATCH! - aiTimerID: " + aiTimerID )
	
	endif

EndEvent

bool Function Trace(ScriptObject CallingObject, string asTextToPrint, int aiSeverity = 0) debugOnly
	;we are sending callingObject so we can in the future route traces to different logs based on who is calling the function
	string logName = "Hardcore"
	debug.OpenUserLog(logName) 
	RETURN debug.TraceUser(logName, CallingObject + ": " + asTextToPrint, aiSeverity)
	
EndFunction

;convenience function, also helps enforce the values
bool function IsGlobalTrue(globalvariable GlobalToCheck)
	
	bool val = GlobalToCheck.GetValue() 

	if val == iGlobalTrue
		RETURN true
	elseif  val == iGlobalFalse
		RETURN false
	else
		;ERROR
		Game.Warning(self + "IsGlobalTrue() found unrecognized value in " + GlobalToCheck + ": " + GlobalToCheck.GetValue())
		RETURN false
	endif

EndFunction

;convenience function, also helps enforce the values
Function SetGlobal(globalvariable GlobalToSet, bool ValueToSet)
	if ValueToSet
		GlobalToSet.SetValue(iGlobalTrue)
	else 
		GlobalToSet.SetValue(iGlobalFalse)
	endif
EndFunction


;**************************************************************************************************
;**************************************    	FAST TRAVEL       *************************************
;**************************************************************************************************

Group FastTravel

	GlobalVariable Property HC_Rule_NoFastTravel const auto Mandatory
{autofill}

	TutorialScript Property Tutorial const auto Mandatory
{autofill; used to toggle on/off tutorial message for pipboy map}

	Location Property InstituteLocation Auto Const Mandatory
{Autofill}

	formlist Property HC_FastTravelAllowedList Auto Const Mandatory
{autofill}

	ObjectReference[] Property FastTravelAllowedWhileInInstituteMapMarkers Auto Const Mandatory
{CITRuinsMapMarker, others?}

	message Property HC_TutorialFastTravelInstitute Auto Const Mandatory
{Autofill}

	message Property HC_FastTravelInstitute_Out Auto Const Mandatory
{Autofill}

	message Property HC_FastTravelInstitute_To Auto Const Mandatory
{Autofill}

	Quest Property MQ207 Auto Const Mandatory
{autofill}

EndGroup

Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    if asMenuName == "PipboyMenu" && IsGlobalTrue(HC_Rule_NoFastTravel)
		Tutorial.UnregisterForTutorialEvent("OnEnterPipBoyMapPage")
    endif
EndEvent


bool MsgInsideInstitute = false
Event Actor.OnLocationChange(Actor akSender, Location akOldLoc, Location akNewLoc)
    ;akSender ASSUMED to be player, as that's the only thing we've registered for

    if IsGlobalTrue(HC_Rule_NoFastTravel) 
	  
    	int i = 0
    	While (i < FastTravelAllowedWhileInInstituteMapMarkers.length)
    		ObjectReference currentRef = FastTravelAllowedWhileInInstituteMapMarkers[i]
    		
    		 if PlayerRef.IsInLocation(InstituteLocation)
    		 	trace(self, "Actor.OnLocationChange ADDING ref to HC_FastTravelAllowedList: " + currentRef)
    			HC_FastTravelAllowedList.addform(currentRef)

				if false == MsgInsideInstitute
					MsgInsideInstitute = true

					if Game.IsFastTravelEnabled()
						utility.wait(3)
						HC_FastTravelInstitute_Out.show()
					endif
				endif

    		else
    			trace(self, "Actor.OnLocationChange REMOVING ref from HC_FastTravelAllowedList: " + currentRef)
    			HC_FastTravelAllowedList.RemoveAddedForm(currentRef)

    			if MsgInsideInstitute
					MsgInsideInstitute = false

					if Game.IsFastTravelEnabled()
						utility.wait(3)
						HC_FastTravelInstitute_To.show()
					endif
				endif

    		endif

    		i += 1
    	EndWhile

    endif

EndEvent

Function ShowInstituteFastTravelTutorial(string asEvent, float afDuration, float afInterval, int aiMaxTimes, string asContext="", int aiPriority=0)
	HC_TutorialFastTravelInstitute.ShowAsHelpMessage(asEvent, afDuration, afInterval, aiMaxTimes, asContext, aiPriority)
EndFunction


;**************************************************************************************************
;**************************************    BALANCE CHANGES    *************************************
;**************************************************************************************************

Group Balance
	globalvariable Property HC_Rule_ScaleDamage const auto mandatory  ;used by perk on Player scale damage based on actor valies
EndGroup

;**************************************************************************************************
;**************************************      ADRENALINE     ***************************************
;**************************************************************************************************

Group Adrenaline
globalvariable Property HC_Rule_AdrenalineOn const auto mandatory
ActorValue Property HC_Adrenaline const auto mandatory
perk Property HC_AdrenalinePerk const auto mandatory
int Property KillsForAdrenalinePerkLevel = 5 const auto ;how many kills before you gain an adrenaline perk level
{***IMPORTANT*** if we ever change KillsForAdrenalinePerkLevel, we must change the conditions in HC_AdrenalineEffect potion}
int Property MaxAdrenalinePerkLevel = 10 const auto
potion Property HC_AdrenalineEffect Auto Const Mandatory
{autofill; potion with effects to show player has adrenaline}
EndGroup

int MaxAdrenaline ;This will never change once we are all setup, so why should we recompute it every time?

int AdrenalineKills  ;Keeps track of the number of kills we have gotten recently (to better compute your adrenaline with).
bool bProcessingAdrenalineKills = false  ;Flag used to keep us from processing more than once at the same time.


;Registered for in OnInit()
Event Actor.OnKill(Actor akSender, Actor akVictim)
	if akSender == PlayerRef ;registered only for player, but doesn't hurt to check
		AdrenalineKills += 1
		trace(self, "Actor.OnKill() player killed: " + akVictim + ". Adding Kill! Now at " + AdrenalineKills + " Total Kills...")
		CallFunctionNoWait("ProcessAdrenalineKills", new var[0])
	endif

EndEvent

; NO RENAMING! THIS FUNCTION IS CALLED BY "CallFunctionNoWait" FROM Actor.OnKill() WHICH RELIES ON THE NAME. NO RENAMING!
Function ProcessAdrenalineKills()
	
	; Check to see if we're already running this.
	if bProcessingAdrenalineKills
		return
	endif
	trace(self, "  ProcessAdrenalineKills() Processing " + AdrenalineKills + " Adrenaline Kills...")

	; Set our flag and start processing these kills. Feel the Adrenaline flow through you...
	bProcessingAdrenalineKills = true
	
	; Grab our current value and then immediately reset it.
	int currentAdrenalineKillTotal = AdrenalineKills
	AdrenalineKills = 0
	
	; Update our Adrenaline totals with this new information.
	ModAdrenaline(currentAdrenalineKillTotal)
	
	; We out. Peace!
	bProcessingAdrenalineKills = false
	trace(self, "  ProcessAdrenalineKills() Processing complete.")

EndFunction

Function ModAdrenaline(int amountToMod)

	; Get our current values and compute an updated one.
	int currentAdrenaline = playerRef.GetValue(HC_Adrenaline) as int
	int updatedAdrenaline = currentAdrenaline + amountToMod
	trace(self, "    ModAdrenaline() currentAdrenaline: " + currentAdrenaline + " + amountToMod: " + amountToMod + " = updatedAdrenaline: " + updatedAdrenaline)

	; Jethro Clamp-It.
	if updatedAdrenaline < 0
		trace(self, "      ModAdrenaline() clamping updatedAdrenaline to 0")
		updatedAdrenaline = 0
	elseif updatedAdrenaline > MaxAdrenaline
		trace(self, "      ModAdrenaline() clamping updatedAdrenaline to maxAdrenaline: " + MaxAdrenaline)
		updatedAdrenaline = MaxAdrenaline
	endif
	
	; Store our value for the future. Think of the children!
	playerRef.SetValue(HC_Adrenaline, updatedAdrenaline)

	; Check to see if we need to make updates to our perk rank, and then make them if need be...
	int perkLevelHasBeen  = currentAdrenaline / KillsForAdrenalinePerkLevel
	int perkLevelShouldBe = updatedAdrenaline / KillsForAdrenalinePerkLevel

	if perkLevelShouldBe == perkLevelHasBeen
	
		; No reason to continue...
		trace(self, "      ModAdrenaline() Adrenaline Rank remains the same at: " + perkLevelShouldBe)
		return
	
	else

		;equip the effect potion in case it's duration has expired
		playerRef.EquipItem(HC_AdrenalineEffect, abSilent = true)

		; Setup
		int i = 0
		
		if perkLevelShouldBe > perkLevelHasBeen
		
			; Clamp our perk level since we will be increasing it.
			if perkLevelShouldBe > MaxAdrenalinePerkLevel
				perkLevelShouldBe = MaxAdrenalinePerkLevel
			endif

			; Setup the number of ranks we will be due...
			i = perkLevelShouldBe - perkLevelHasBeen
			trace(self, "      ModAdrenaline() Adrenaline Rank increases from " + perkLevelHasBeen + " to " + perkLevelShouldBe)

			; Tutorial Call - Adrenaline.
			TryTutorial(AdrenalineTutorial, "AdrenalineTutorial")
			
		elseif perkLevelShouldBe < perkLevelHasBeen
			
			; Remove all ranks (because we have too?) and setup the number of ranks we will be due...
			playerRef.removePerk(HC_AdrenalinePerk)
			i = perkLevelShouldBe
			trace(self, "      ModAdrenaline() Adrenaline Rank decreases from " + perkLevelHasBeen + " to " + perkLevelShouldBe)
			
		endif

		; Now we add what we are due...
		while (i > 0)
			playerRef.AddPerk(HC_AdrenalinePerk)	
			i -= 1
		endwhile
		
	endif

EndFunction


;**************************************************************************************************
;**************************************        COMMON EFFECTS       ********************************
;**************************************************************************************************

Struct Effect
	
	Potion EffectPotion
{What potion to apply when gaining this effect - for all negative effects so they show up in stats effects list in pipboy}
	MagicEffect MagicEffectToApply
{The Magic Effect this effect applies, if any. This lets us to test whether or not it's active (Disease Symptoms).}
	GlobalVariable GlobalEnum 
{this global's value is the enum for this effect}
	Message MessageToDisplay
{What message do we display when gaining this effect}
	Message MessageToRedisplay
{What message do we display when regaining this effect while it's already active}
	Message MessageToDisplayAfterAwaking
{What message do we display when awaking with this effect}
	float DiseaseChanceFloor = 0.05
{The lowest chance of getting diseased the player has with this effect}
	float DiseaseChanceCeiling = 0.9
{The highest chance of getting diseased the player has with this effect}
	float DiseaseChanceDrainMult = 1.0
{The multiplier on that rate at which the disease chance drains to the floor value}
	float FatigueMult = 0.01
{The percentage of fatigue that this effect adds}
	MagicEffect HerbalRemedyEffect
{This Herbal Remedy, if applied, can counter disease if RNGesus shows grace.}
	float HerbalRemedyBoostedImmunityThreshold = 0.20	
{The disease  die roll needs to be <= Risk Pool && >= BoostedImmunityThreshold to get this disease.
This number acts as both a minimum Risk Pool threshold to even get this disease and
once the Risk Pool is high enough, adds some randomness to whether you would get this disease with each risky action.
IMPORTANT: to prevent total imminuty this value should be below 1.}

EndStruct

message EffectMessageToShow

; IncrementEffectBy is assumed to be a positive value as negative values will be discarded like the trash they are.
Function ApplyEffect(GlobalVariable RuleGlobal, Effect[] EffectsArray, ActorValue EffectActorValue, bool DispellRestedSpells = false, int IncrementEffectBy = 0, bool DisplayAfterAwakingMessage = false, bool bDisplayMessage = true, bool bDamageFatigue = true, bool bAnnounceFatigue = false, bool bBypassGlobalCheck = false)
	trace(self, "  ApplyEffect()")
	if IsGlobalTrue(RuleGlobal) == false && bBypassGlobalCheck == false
		;** This ASSUMES we don't toggle off and on in the same play through... if so, this could cause you to permamently be in the effected state)
		;BAIL OUT, not in hardcore mode
		RETURN
	endif

	;just incase there's base game spells running:
	if DispellRestedSpells
		playerRef.dispelSpell(WellRested)
		playerRef.dispelSpell(LoversEmbracePerkSpell)
	endif

	;give the player all the effects
	;they are potions he needs to equip, which will restart their duration
	;the effects on each potion are conditioned on the EffectActorValue actorvalue
	;I tried having each one dispel the effects on the other, similar to MS19MoleRatPoison and Cure... but that didn't work for some reason. Perhaps it'd only work on checking in?

	;restart all the  effects by equipping their potions on the player.
	int i = 0
	int EffectsLength = EffectsArray.length
	while (i < EffectsLength)
		potion potionToApply = EffectsArray[i].EffectPotion
	
		if potionToApply ;detrimental effects are potions
			PlayerRef.EquipItem(potionToApply, abSilent = true)
		endif

		i += 1
	endwhile


	; Increment the  effect actor value
	int newVal = PlayerRef.GetValue(EffectActorValue) as int
	int oldVal = newVal
	trace(self, "    ApplyEffect() Current Value: " + newVal)
	if IncrementEffectBy > 0
		newVal += IncrementEffectBy
		trace(self, "    ApplyEffect() Updated Value: " + newVal)
		
		;don't exceed the array of effects
		if newVal < EffectsLength
			PlayerRef.SetValue(EffectActorValue, newVal)
		endif
	endif

	; Display appropriate message
	message PreviousEffectMessageToShow = EffectMessageToShow
	if DisplayAfterAwakingMessage
		PreviousEffectMessageToShow = None ;always show messages upon waking
		EffectMessageToShow = EffectsArray[newVal].MessageToDisplayAfterAwaking
	else
		EffectMessageToShow = EffectsArray[newVal].MessageToDisplay
	endif

	; There has been no change... nothing to see here.
	if IncrementEffectBy > 0 && newVal == oldVal
		EffectMessageToShow = none
	endif

	if bDisplayMessage && EffectMessageToShow != PreviousEffectMessageToShow
		EffectMessageToShow.show()
	endif

	; Update Fatigue.
	if bDamageFatigue
		DamageFatigue(bAnnounceFatigue)
	endif

EndFunction

Function DamageFatigue(bool bAnnounceFatigue = false)
	trace(self, "    DamageFatigue() bAnnounceFatigue: " + bAnnounceFatigue)
	
	; Grab our current values
	float HungerFatigueMult = HungerEffects[PlayerRef.GetValue(HC_HungerEffect) as int].FatigueMult
	float ThirstFatigueMult = ThirstEffects[PlayerRef.GetValue(HC_ThirstEffect) as int].FatigueMult
	float SleepFatigueMult  = SleepEffects[PlayerRef.GetValue( HC_SleepEffect ) as int].FatigueMult
	trace(self, "      DamageFatigue()     HungerFatigueMult (2x): " + HungerFatigueMult)
	trace(self, "      DamageFatigue()     ThirstFatigueMult (2x): " + ThirstFatigueMult)
	trace(self, "      DamageFatigue()      SleepFatigueMult (3x): " + SleepFatigueMult)
	
	; Average them up...
	float AverageFatigueMult = ((HungerFatigueMult * 2.0) + (ThirstFatigueMult * 2.0) + (SleepFatigueMult * 3.0)) / 7.0
	trace(self, "      DamageFatigue()         AverageFatigueMult: " + AverageFatigueMult)
	
	; Let's store our average fatigue.
	float currentFatigue = AverageFatigueMult * fMaxFatigue

	; Captastic.
	if currentFatigue > fCapFatigue
		currentFatigue = fCapFatigue
	elseif currentFatigue > 0 && currentFatigue < fLowestNonZeroFatigue
		currentFatigue = fLowestNonZeroFatigue
	elseif currentFatigue < 0
		currentFatigue = 0
	endif
	
	; Only worry about touching this AV if the value is actually changing...
	float previousFatigue = PlayerRef.GetValue(Fatigue)
	if previousFatigue != currentFatigue
		; First, we set it back to 0...
		ClearFatigue()

		; Then, we set it to the desired value.
		PlayerRef.DamageValue(Fatigue, currentFatigue)
		trace(self, "      DamageFatigue()     Updated currentFatigue: " + currentFatigue)

		; Display the Fatigue Warning?
		if bAnnounceFatigue && currentFatigue > previousFatigue 
			Game.ShowFatigueWarningOnHUD()
			trace(self, "      DamageFatigue() - Announcing Fatigue!")
		endif
		
	endif

Endfunction

Function ClearFatigue()
	PlayerRef.RestoreValue(Fatigue, fMaxFatigue)
EndFunction

;**************************************************************************************************
;**************************************    SUSTENANCE EFFECTS  *******************************
;**************************************************************************************************

Group SustenanceEffects
	globalvariable Property HC_Rule_SustenanceEffects const auto mandatory

	ActorValue Property HC_HungerEffect const auto mandatory

	Effect[] Property HungerEffects const auto mandatory
{The order in this array, is the order they devolution after time passes since eating.}

	keyword[] Property IncreasesHungerKeywords const auto mandatory
{keywords in here, removes points from Food pool, making the player more hungry}

	float Property IncreasesHungerCostMult = 0.65 const auto
{Multiplier on things that increase hunger's caps value}
	
	keyword Property ObjectTypeFood const auto mandatory
{autofill}

	ActorValue Property HC_ThirstEffect const auto mandatory

	Effect[] Property ThirstEffects const auto mandatory
{The order in this array, is the order they devolution after time passes since eating.}

	keyword[] Property IncreasesThirstKeywords const auto mandatory
{keywords in here, removes points from Drink pool, making the player more thirsty}

	float Property IncreasesThirstCostMult = 0.5 const auto
{Default: 0.5; Multiplier on things that increase thirst's caps value}

	keyword[] Property QuenchesThirstKeywords const auto mandatory
{keywords in here, removes points from Drink pool, making the player more thirsty}

	keyword Property ObjectTypeNukaCola const auto mandatory
{autofill}

	float Property NukaThirstCostMult = 0.4 const auto
{Cost * this = Thirst Value}

	float Property NukaFoodCostMult = 0.2 const auto
{-Cost * this = Food Value}

	keyword Property ObjectTypeCaffeinated const auto mandatory
{autofill}
	keyword Property ObjectTypeExtraCaffeinated const auto mandatory
{autofill}

	MagicEffect Property HC_Disease_NeedMoreFood_Effect const auto mandatory
{Autofill, if player has this effect, he requires more food -- eating restores less food}

	float Property DiseaseNeedMoreFoodMult = 0.5 const auto
{multiplyer on the value of food when player have the need more food disease effect}

	perk Property HC_SustenanceEffectsTurnOffFood const auto mandatory

	
	int Property CannibalTicksToGoRavenous = 12 const auto
{How many sustenance ticks as a cannibal it takes to go Ravenous}

	ActorValue Property HC_CannibalEffect const auto mandatory
{Autofill; 0 = normal, 1 = has ravenous hunger (recently ate a corpse)}

	Potion Property HC_Cannibal_RavenousHunger const auto mandatory
{Autofill; potion that has the Ravenous Hunger effect - conditioned on AV HC_CannibalRavenousHunger being 1}

	Message Property HC_Cannibal_Msg_RavenousHunger_EatFood const auto mandatory
{autofill; message to display when eating normal food while suffering from Cannibal Effect Ravenous Hunger}

	Message Property HC_Cannibal_Msg_RavenousHunger_EatCorpse const auto mandatory
{autofill; message to display when eating a corpse and gaiing the Ravenous Hunger}

	Message Property HC_Cannibal_Msg_RavenousHunger_DropToRavenousLevel const auto mandatory
{autofill; message to display when dropping to ravenous hunger level while suffering from Cannibal Effect Ravenous Hunger}

	potion Property HC_SippableWater const auto mandatory
{autofill; Water we force you to drink when you drink from a fountain or pool to run it through the correct processes}
	
	potion Property HC_SippableDirtyWater const auto mandatory
{autofill; Dirty water we force you to drink when you drink from a dirty fountain or pool to run it through the correct processes}

	perk Property HC_FillWaterBottlePerk Auto Const Mandatory
{autofill; this perk let's you fill empty bottles at water sources}

EndGroup

Group SustenanceTiers
	float Property GamesHoursPerTick = 1.0 const auto
{How many game hours for a standard hunger/thirst check tick}
	float Property BonusDigestionHours = 1.0 Auto Const
{How many hours you get after clearing a hunger or thirst tier before the next sustenance tick}
	float Property SustenanceTickWhileSleepingMult = 0.25 const auto
{This is a cut on the amount of time being passed as percieved by sustenance, to prevent massive changes while sleeping.}
	float Property TickHoursCostPerCombat = 0.25 const auto 
{in terms of game hours, how much does each combat shave off the next tick time}
	
	; Food
	int Property FoodCostPerTick = 4 const auto
{in terms of caps value, how much food per tick is required to remain normal}
	int Property iFoodPoolPeckishAmount   =  -24 const auto  ;  6 hours
	int Property iFoodPoolHungryAmount    =  -48 const auto  ; 12 hours
	int Property iFoodPoolFamishedAmount  =  -96 const auto  ; 24 hours
	int Property iFoodPoolRavenousAmount  = -144 const auto  ; 36 hours
	int Property iFoodPoolStarvingAmount  = -256 const auto  ; 64 hours
	int Property MinFoodValueFed          =   12 const auto
	int Property MinFoodValuePeckish      =   12 const auto  ; Maximum of  2 Food to Fed
	int Property MinFoodValueHungry       =   12 const auto  ; Maximum of  4 Food to Fed
	int Property MinFoodValueFamished     =   24 const auto  ; Maximum of  6 Food to Fed
	int Property MinFoodValueRavenous     =   24 const auto  ; Maximum of  8 Food to Fed
	int Property MinFoodValueStarving     =   56 const auto  ; Maximum of 10 Food to Fed
	int Property MaxFoodValue             =  231 const auto  ; The most food points we will ever take.

	; Drink
	int Property DrinkCostPerTick = 4 const auto
{in terms of caps value, how much drink per tick is required to remain normal}
	int Property iDrinkPoolParchedAmount            =  -16 const auto  ;  4 hours
	int Property iDrinkPoolThirstyAmount            =  -36 const auto  ;  9 hours
	int Property iDrinkPoolMildlyDehydratedAmount   =  -72 const auto  ; 18 hours
	int Property iDrinkPoolDehydratedAmount         = -120 const auto  ; 30 hours
	int Property iDrinkPoolSeverelyDehydratedAmount = -180 const auto  ; 45 hours
	int Property MinDrinkValueHydrated              =    8 const auto
	int Property MinDrinkValueParched               =    8 const auto  ; Maximum of  2 Drink to Hydrated
	int Property MinDrinkValueThirsty               =   10 const auto  ; Maximum of  4 Drink to Hydrated
	int Property MinDrinkValueMildlyDehydrated      =   18 const auto  ; Maximum of  6 Drink to Hydrated
	int Property MinDrinkValueDehydrated            =   24 const auto  ; Maximum of  8 Drink to Hydrated
	int Property MinDrinkValueSeverelyDehydrated    =   30 const auto  ; Maximum of 10 Drink to Hydrated
	int Property MaxDrinkValue                      =  167 const auto  ; The most drink points we will ever take.

EndGroup

Group SustenanceEffectsGlobalEnums
	globalvariable Property HC_HE_Fed const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_HE_Peckish const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_HE_Hungry const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_HE_Famished const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_HE_Ravenous const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_HE_Starving const auto
{autofill; global whose value represents this level}


	globalvariable Property HC_TE_Hydrated const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_TE_Parched const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_TE_Thirsty const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_TE_MildlyDehydrated const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_TE_Dehydrated const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_TE_SeverelyDehyrdated const auto
{autofill; global whose value represents this level}


	globalvariable Property HC_SE_WellRestedORLoversEmbrace const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Rested const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Tired const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Weary const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Fatigued const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Exhausted const auto
{autofill; global whose value represents this level}

	globalvariable Property HC_SE_Incapacitated const auto
{autofill; global whose value represents this level}

EndGroup

int   iCaffeinated = 0              ; 0 = None, 1 = Caffeinated, 2 = Well Rested + Caffeinated
int   CaffeinatedCount = 0          ; Track the number of times we've been extra caffeinated.
int   ExtraCaffeinatedCount = 0     ; Track the number of times we've been caffeinated.
float fCaffeinatedTimeTracker       ; Store off the time remaining when we got caffeinated.
float DEBUGCaffeinatedTimeRemaining ; (DEBUG) Store off the time we will be caffeinated if it's allowed to expire.

int CannibalTicks = 0 ; How many sustenance ticks have passed while you've been a cannibal?

int FoodPool  =  0 ; negative means a debt that needs to be paid or suffer effect
int FoodReqs  = -1 ; This is how much you actually have to eat in order to remove the effects.
int DrinkPool =  0 ; negative means a debt that needs to be paid or suffer effect
int DrinkReqs = -1 ; This is how much you actually have to drink in order to remove the effects.
;int DeadPool ; negative needs to be paid for effects suffered...



float LastCombatDay                 ;store the last combat time in terms of game days passed
float MinDaysPerCombat = 0.1        ;how many gamedayspassed need to occur before we count a new combat

float NextSustenanceTickDay     ;expressed in GameDaysPassed, when is the next game day that a tick occurs - player getting in combats can shorten this.

form[] FoodItems ; Holds our food for later processing.
bool bProcessingFood = false ; Flag used to keep us from processing more than once at the same time.

Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
	trace(self, "OnCombatStateChanged()")

	float GameDaysPassed = Utility.GetCurrentGameTime() 

	if aeCombatState == 1 &&  GameDaysPassed < (LastCombatDay + MinDaysPerCombat)

		trace(self, "  OnCombatStateChanged() shaving time off NextSustenanceTickDay. Was: " + NextSustenanceTickDay)

		;shave off time from tick day because player is exerting himself in combat
		NextSustenanceTickDay -=  (TickHoursCostPerCombat/24)

		trace(self, "  OnCombatStateChanged() shaving time off NextSustenanceTickDay. Now: " + NextSustenanceTickDay)
		
		LastCombatDay = GameDaysPassed
	endif
EndEvent

Event Actor.OnItemEquipped(Actor akSender, Form akBaseObject, ObjectReference akReference)
	; As long as your actually food and not one of our many tasty potions, lets add you to the food array.
	if akBaseObject == HC_Antibiotics || (akReference == none || false == akReference.IsQuestItem()) && false == CommonArrayFunctions.CheckFormAgainstKeywordArray(akBaseObject, NonFoodKeywords)
		AddFoodItem(akBaseObject)
	endif

EndEvent

Function AddFoodItem(Form akBaseObject)
	FoodItems.add(akBaseObject)
	trace(self, "Adding Food Item " + akBaseObject + " To Array With " + FoodItems.length + " Total Food Items...")
	CallFunctionNoWait("ProcessFoodItems", new var[0])
EndFunction


; NO RENAMING! THIS FUNCTION IS CALLED BY "CallFunctionNoWait" FROM Actor.OnItemEquipped() WHICH RELIES ON THE NAME. NO RENAMING!
Function ProcessFoodItems()
	trace(self, "Processing " + FoodItems.length + " Food Items...")
	
	; Check to see if we're already running this.  Additional items will just be added to the array.
	if bProcessingFood
		return
	endif

	; Set our flag and start eating all this delicous food product.
	bProcessingFood = true
	while FoodItems.length > 0
		ProcessSingleFoodItem(FoodItems[0])
		FoodItems.remove(0)
		trace(self, "  Food Item Processed! " + FoodItems.length + " remaining...")
		utility.WaitMenuMode(0.1)
	endwhile
	
	; We out. Peace.
	bProcessingFood = false

EndFunction

; Process each item one at a time.
Function ProcessSingleFoodItem(Form akBaseObject)
	int baseCost = akBaseObject.GetGoldValue()
	trace(self, "  ProcessSingleFoodItem(): " + akBaseObject + ", Base Cost: " + baseCost)

	if akBaseObject == HC_Antibiotics
		bPlayerTookAntibiotics = true
		HandleDiseaseRiskEvent(0)
	endif

	; Caffeine makes me feel alright... for a time.
	if akBaseObject.HasKeyword(ObjectTypeCaffeinated)
		; Time until sleep cycle ends / length of Caffeination.
		float timeToCaffeinate = 0 

		if iCaffeinated > 0
			timeToCaffeinate = GetHoursUntilCurrentSleepCycleEnds()
		endif

		; To prevent staving off sleep forever by caffeinating, we increase it by the standard value scaled by the number of times caffeinated (typed).
		if akBaseObject.HasKeyword(ObjectTypeExtraCaffeinated)
			ExtraCaffeinatedCount += 1
			timeToCaffeinate += ExtraCaffeineInducedSleepDelay / ExtraCaffeinatedCount
		else
			CaffeinatedCount += 1
			timeToCaffeinate += CaffeineInducedSleepDelay / CaffeinatedCount
		endif

		; Get Caffeinated
		PlayerRef.EquipItem(HC_Effect_Caffeinated, abSilent = true)

		; Get our current value - 1.
		int newVal = (PlayerRef.GetValue(HC_SleepEffect) as int) - 1

		if iCaffeinated == 0 && newVal >= 0
			iCaffeinated = 1
			PlayerRef.SetValue(HC_SleepEffect, newVal)
			fCaffeinatedTimeTracker = GetHoursUntilCurrentSleepCycleEnds()
		elseif iCaffeinated == 0
			iCaffeinated = 2
		endif
		trace(self, "    ProcessSingleFoodItem(): CAFFEINATED!!! iCaffeinated: " + iCaffeinated + ", SleepEffect[" + newVal + "]")

		; Show our message (Using Redisplay exlusively for this.)
		HC_SE_Msg_Caffeinated.show()

		; Restart the sleep timer with the Caffeine delay.
		StartSleepDeprivationTimer(timeToCaffeinate)

		; For logging.
		DEBUGCaffeinatedTimeRemaining = timeToCaffeinate

	endif

	; FOOD!
	if akBaseObject.HasKeyword(ObjectTypeFood)
		trace(self, "    ProcessSingleFoodItem() player eating food: " + akBaseObject  + ", Base Cost: " + baseCost)
		;based on food pool deficit, set hunger effect
		ModFoodPoolAndUpdateHungerEffects(basecost)
		; Increase the chance for the disease without immediately forcing a roll.
		FillDiseaseRiskPool(DiseaseRiskIncreaser_Food)
	elseif IsHungerIncreasing(akBaseObject)
		trace(self, "    ProcessSingleFoodItem() player increasing hunger: " + akBaseObject  + ", cost: -" + basecost)
		ModFoodPoolAndUpdateHungerEffects(math.floor(-basecost * IncreasesHungerCostMult))
	endif
	
	;DRINK - This is not ifelse'd, because some food also cures thirst.
	if IsThirstQuenching(akBaseObject)
		trace(self, "    ProcessSingleFoodItem() player quenching thirst: " + akBaseObject  + ", cost: " + basecost)
		ModDrinkPoolAndUpdateThirstEffects(basecost)
		; Increase the chance for the disease without immediately forcing a roll.
		FillDiseaseRiskPool(DiseaseRiskIncreaser_Drink)
	elseif IsThirstIncreasing(akBaseObject)
		trace(self, "    ProcessSingleFoodItem() player increasing thirst: " + akBaseObject  + ", cost: -" + basecost)
		ModDrinkPoolAndUpdateThirstEffects(math.floor(-basecost * IncreasesThirstCostMult))
	endif

	; NUKA COLA, GET YOURSELF REFRESHED!!!
	if akBaseObject.HasKeyword(ObjectTypeNukaCola)
		trace(self, "    ProcessSingleFoodItem() Player is drinking cola (" + akBaseObject + "): Thirst +" + (basecost * NukaThirstCostMult) + ", Hunger -" + (basecost * NukaFoodCostMult))
		ModFoodPoolAndUpdateHungerEffects( math.floor(-basecost * NukaFoodCostMult))
		ModDrinkPoolAndUpdateThirstEffects(math.floor( basecost * NukaThirstCostMult))
		; Increase the chance for the disease without immediately forcing a roll.
		FillDiseaseRiskPool(DiseaseRiskIncreaser_Cola)
	endif

	; Handle Disease Risks (with rolls!)
	if CommonArrayFunctions.CheckFormAgainstKeywordArray(akBaseObject, DiseaseRiskFoodStandardKeywords)
		trace(self, "    ProcessSingleFoodItem() player eating food with standard disease risk: " + akBaseObject )
		HandleDiseaseRiskEvent(DiseaseRiskFoodStandardAmount)

	elseif CommonArrayFunctions.CheckFormAgainstKeywordArray(akBaseObject, DiseaseRiskFoodHighKeywords)
		trace(self, "    ProcessSingleFoodItem() player eating food with high disease risk: " + akBaseObject )
		HandleDiseaseRiskEvent(DiseaseRiskFoodHighAmount)

	elseif CommonArrayFunctions.CheckFormAgainstKeywordArray(akBaseObject, DiseaseRiskChemsKeywords)
		trace(self, "    ProcessSingleFoodItem() player taking chem with disease risk: " + akBaseObject )
		HandleDiseaseRiskEvent(DiseaseRiskChemsAmount)

	endif

	; Handle Radaway and other similar Rad treatments.
	if IsGlobalTrue(HC_Rule_DiseaseEffects) && akBaseObject.HasKeyword(HC_CausesImmunodeficiency)
		trace(self, "    ProcessSingleFoodItem() player is using Rad Treatment and must be punished!")
		PlayerRef.EquipItem(HC_Effect_Immunodeficiency, abSilent = true)
		; Increase the chance for the disease without immediately forcing a roll.
		FillDiseaseRiskPool(DiseaseRiskIncreaser_Immunodeficiency)
	endif

Endfunction

bool Function IsThirstQuenching(form akBaseObject)
	bool returnVal = false
	if akBaseObject
		int i = 0
		while (returnVal == false && i < QuenchesThirstKeywords.length)
			returnVal = akBaseObject.HasKeyword(QuenchesThirstKeywords[i])
			i += 1
		endwhile
	endif
	return returnVal
EndFunction

bool Function IsThirstIncreasing(form akBaseObject)
	bool returnVal = false
	if akBaseObject
		int i = 0
		while (returnVal == false && i < IncreasesThirstKeywords.length)
			returnVal = akBaseObject.HasKeyword(IncreasesThirstKeywords[i])
			i += 1
		endwhile
	endif
	return returnVal	
EndFunction

bool Function IsHungerIncreasing(form akBaseObject)
	bool returnVal = false
	if akBaseObject
		int i = 0
		while (returnVal == false && i < IncreasesHungerKeywords.length)
			returnVal = akBaseObject.HasKeyword(IncreasesHungerKeywords[i])
			i += 1
		endwhile
	endif
	return returnVal	
EndFunction

function HandleSustenanceTimer(bool bWasSleeping = false, bool bCanceledSleepPreHour = false)
	trace(self, "  HandleSustenanceTimer()")
	
	float GameDaysPassed = Utility.GetCurrentGameTime()
	trace(self, "    HandleSustenanceTimer()                                GameDaysPassed: " + GameDaysPassed)
	trace(self, "    HandleSustenanceTimer()                         NextSustenanceTickDay: " + NextSustenanceTickDay)

	; Store this off and use it a couple of times...
	float GameDaysPerTick = GamesHoursPerTick / 24.0
	
	; If we've been sleeping we are conserving energy.
	if bWasSleeping
		trace(self, "    HandleSustenanceTimer() Look at this sleepyhead! You just woke up! I'll take that into account!")
		GameDaysPerTick *= 1/SustenanceTickWhileSleepingMult
		if bCanceledSleepPreHour
			NextSustenanceTickDay -= 1.0 / 24.0
			trace(self, "    HandleSustenanceTimer() Sleep Canceled! Updated NextSustenanceTickDay: " + NextSustenanceTickDay)
		endif
	EndIf
	
	; "If this is your first time..., you have to fight." -  Tyler Durden
	; Translation: If this is 0, then it has never been run before, so we correctly increment it from out incoming starting time.
	if false == NextSustenanceTickDay
		NextSustenanceTickDay = GameDaysPassed + GameDaysPerTick
		trace(self, "    HandleSustenanceTimer() FIRST CALL - GameDaysPassed: " + GameDaysPassed + ", NextSustenanceTickDay: " + NextSustenanceTickDay)
		return
	endif
	
	trace(self, "    HandleSustenanceTimer()                             GamesHoursPerTick: " + GamesHoursPerTick)
	trace(self, "    HandleSustenanceTimer()                               GameDaysPerTick: " + GameDaysPerTick)
	
	; Is this a tick threshold?
	if GameDaysPassed >= NextSustenanceTickDay

		trace(self, "      HandleSustenanceTimer() GameDaysPassed >= NextSustenanceTickDay >>> PROCESSING HUNGER >>>")
		trace(self, "      HandleSustenanceTimer()   (NextSustenanceTickDay - GameDaysPerTick): " + (NextSustenanceTickDay - GameDaysPerTick))
		trace(self, "      HandleSustenanceTimer()                      GameDaysPassed - ABOVE: " + (GameDaysPassed - (NextSustenanceTickDay - GameDaysPerTick)))
		trace(self, "      HandleSustenanceTimer()                    ABOVE / GameDaysPerTick): " + ((GameDaysPassed - (NextSustenanceTickDay - GameDaysPerTick)) / GameDaysPerTick))
		trace(self, "      HandleSustenanceTimer()                           math.floor(ABOVE): " + math.floor( ((GameDaysPassed - (NextSustenanceTickDay - GameDaysPerTick)) / GameDaysPerTick) ))

		;get # of ticks since last time we handled the timer (in case player waits for a long time for example)
		int ticks =  math.floor( ((GameDaysPassed - (NextSustenanceTickDay - GameDaysPerTick)) / GameDaysPerTick) ) 
		
		int ModFoodPool = 0

		;IF SUFFERING RAVENOUS HUNGER Cannibal Effect
		;set the hunger ticks to trigger ravenous hunger effect
		if PlayerRef.GetValue(HC_CannibalEffect) <= 0
			trace(self, "    HandleSustenanceTimer() You're not a cannibal!                  TICKS: " + ticks)
			;normal amount
			ModFoodPool = -FoodCostPerTick * ticks
		else
			CannibalTicks += 1 * ticks
			trace(self, "    HandleSustenanceTimer() You're a cannibal! WHY!?       CANNABIL TICKS: " + CannibalTicks)
			; Every X ticks we are going to go ravenous until we eat a corpse.
			if CannibalTicks >= CannibalTicksToGoRavenous
				;specific amount because player is suffering from ravenous hunger
				ModFoodPool = iFoodPoolRavenousAmount
				;pop a message explaining what happened
				HC_Cannibal_Msg_RavenousHunger_DropToRavenousLevel.show()
				; reset our counter and be prepaird to do this again.
				CannibalTicks = 0
			endif
		endif

		ModFoodPoolAndUpdateHungerEffects(ModFoodPool)
		ModDrinkPoolAndUpdateThirstEffects(-DrinkCostPerTick * ticks)
	   
		;set up for the next tick
		NextSustenanceTickDay = GameDaysPassed + GameDaysPerTick

	else
		trace(self, "    HandleSustenanceTimer() GameDaysPassed < NextSustenanceTickDay. Try again later.")
	endif

endfunction

float Function CapFoodAndDrinkPoolMinValue(float afModPoolAmount, int aiMinTierValue)
	if afModPoolAmount < aiMinTierValue
		return aiMinTierValue
	endif
	; Otherwise return what we had.
	return afModPoolAmount
EndFunction

int Function SetOrCapReqsToTiersSustenanceValueOnDeterioration(int aiReqs, int aiCurrentEffectTier, int aiNewEffectTier, int aiFoodPoolValueForTier)
	; We've gotten worse.  Bump up the Food Requirements needed to clear states.
	if (aiCurrentEffectTier != aiNewEffectTier)
		trace(self, "          SetOrCapReqsToTiersSustenanceValueOnDeterioration():                    Updated Reqs: " + aiFoodPoolValueForTier)
		return aiFoodPoolValueForTier
	; Make sure Food Requirements remains atleast as high as the current cap.
	elseif aiReqs < aiFoodPoolValueForTier
		trace(self, "          SetOrCapReqsToTiersSustenanceValueOnDeterioration():                     Capped Reqs: " + aiFoodPoolValueForTier)
		return aiFoodPoolValueForTier
	endif
	; Otherwise return what we had.
	trace(self, "          SetOrCapReqsToTiersSustenanceValueOnDeterioration():                  Unchanged Reqs: " + aiReqs)
	return aiReqs
EndFunction

int Function SetPoolToTiersSustenanceValueOnRecovery(int aiPool, int aiCurrentEffectTier, int aiNewEffectTier, int aiFoodPoolValueForTier)
	; We've gotten better.  Roll back out food pool to the new value.
	if (aiCurrentEffectTier != aiNewEffectTier)
		if  aiPool < aiFoodPoolValueForTier
			trace(self, "        SetPoolToTiersSustenanceValueOnRecovery():                        Updated Pool: " + aiFoodPoolValueForTier)
			return aiFoodPoolValueForTier
		endif
	endif
	; Otherwise return what we had.
	trace(self, "        SetPoolToTiersSustenanceValueOnRecovery():                      Unchanged Pool: " + aiPool)
	return aiPool
EndFunction

bool Function ShowSustenance(bool abStateChanged)
	; Is this a state change?  If so, let's add some fatigue and show our message.
	if  abStateChanged
		return true
	endif
	return false
EndFunction

bool Function AnnounceFatigue(bool abStateChanged, int aiModPoolAmount)
	; We're transitioning to a worse effect.
	if  abStateChanged && aiModPoolAmount < 0
		; Tutorial Call - Thirst.
		TryTutorial(ThirstTutorial, "ThirstTutorial")
		return true
	endif
	return false
EndFunction

Function UpdateNextSustenanceTickDay(bool abStateChanged, int aiModPoolAmount)
	; We're transitioning to a better effect
	if  abStateChanged && aiModPoolAmount > 0
		; Reset out time.
		NextSustenanceTickDay = Utility.GetCurrentGameTime() + (BonusDigestionHours / 24.0)
	endif
EndFunction		

Function ModFoodPoolAndUpdateHungerEffects(float ModPoolAmount, bool IsEatingCorpse = false)
	trace(self, "      ModFoodPoolAndUpdateHungerEffects()                                ModPoolAmount: " + ModPoolAmount)
	
	; Store our current effect to test for a change...
	int currentHE = PlayerRef.GetValue(HC_HungerEffect) as int

	if ModPoolAmount >= 0
		; FIND OUR CORRECT MOD VALUE BASED ON YOU CURRENT TIER AND/OR EFFECTS
	  	;if player has Cannibal effect Ravenous Hunger, he gets no value from normal food.
	  	if (false == IsEatingCorpse) && PlayerRef.GetValue(HC_CannibalEffect) > 0
			;suffering Ravenous Hunger
			ModPoolAmount = 0 ;gains no benefit from food.
			HC_Cannibal_Msg_RavenousHunger_EatFood.Show()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is suffering Cannibal's Hunger! Food is worthless!")

		; Check our max value first
	  	elseif ModPoolAmount > MaxFoodValue && (false == IsEatingCorpse) ;no cap for corpses!
	  		ModPoolAmount = MaxFoodValue
	  		trace(self, "        ModFoodPoolAndUpdateHungerEffects():                     Capped @ MaxFoodValue: " + ModPoolAmount)

	  	; Adjust our ModPoolAmount for current hunger state:
		elseif HC_HE_Fed.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValueFed)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects():      Player is Fed! Updated ModPoolAmount: " + ModPoolAmount)
	
		elseif HC_HE_Peckish.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValuePeckish)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects():  Player is Peckish! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_HE_Hungry.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValueHungry)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects():   Player is Hungry! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_HE_Famished.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValueFamished)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Famished! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_HE_Ravenous.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValueRavenous)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Ravenous! Updated ModPoolAmount: " + ModPoolAmount)

		elseif HC_HE_Starving.GetValue() == currentHE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount, MinFoodValueStarving)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Starving! Updated ModPoolAmount: " + ModPoolAmount)
			
		endif

		;reduce it if it's positive change and the player is suffering disease effect that requires more food
		if PlayerRef.HasMagicEffect(HC_Disease_NeedMoreFood_Effect)
			ModPoolAmount *= DiseaseNeedMoreFoodMult
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player has Disease Effect requiring more food, scaling ModPoolAmount to: " + ModPoolAmount)
		endif

	EndIf

	; Uupdate our new pool and required food values.
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                               Old FoodPool: " + FoodPool)
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                               Old FoodReqs: " + FoodReqs)
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                            + ModPoolAmount: " + ModPoolAmount)
	FoodPool += ModPoolAmount as int
	FoodReqs += ModPoolAmount as int
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                               New FoodPool: " + FoodPool)
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                               New FoodReqs: " + FoodReqs)

	; Based on Food pool deficit, set effect...
	; We're transitioning to a worse effect:
	if ModPoolAmount < 0
		if FoodPool <= iFoodPoolStarvingAmount && currentHE <= HC_HE_Starving.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Starving")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Starving.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			FoodReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(FoodReqs, currentHE, HC_HE_Starving.GetValue() as int, iFoodPoolStarvingAmount)

			;cap it
			FoodPool = iFoodPoolStarvingAmount

		elseif FoodPool <= iFoodPoolRavenousAmount && currentHE <= HC_HE_Ravenous.GetValue()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Ravenous")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Ravenous.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			FoodReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(FoodReqs, currentHE, HC_HE_Ravenous.GetValue() as int, iFoodPoolRavenousAmount)

		elseif FoodPool <= iFoodPoolFamishedAmount && currentHE <= HC_HE_Famished.GetValue()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Famished")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Famished.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			FoodReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(FoodReqs, currentHE, HC_HE_Famished.GetValue() as int, iFoodPoolFamishedAmount)

		elseif FoodPool <= iFoodPoolHungryAmount && currentHE <= HC_HE_Hungry.GetValue()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Hungry")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Hungry.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			FoodReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(FoodReqs, currentHE, HC_HE_Hungry.GetValue() as int, iFoodPoolHungryAmount)

		elseif FoodPool <= iFoodPoolPeckishAmount && currentHE <= HC_HE_Peckish.GetValue()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Peckish")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Peckish.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			FoodReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(FoodReqs, currentHE, HC_HE_Peckish.GetValue() as int, iFoodPoolPeckishAmount)

		elseif currentHE <= HC_HE_Fed.GetValue()
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Fed")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Fed.GetValue())

			; Make sure Food Requirements remains atleast as high as the current cap.
			if  FoodReqs < 0
				FoodReqs = 0
			endif

			;cap it, if we are over the limit.
			if FoodPool > 0
				FoodPool = 0
			endif
			
		else
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): GETTING WORSE - NO MATCH!")
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is: " + PlayerRef.GetValue(HC_HungerEffect))
			trace(self, "        ModFoodPoolAndUpdateHungerEffects():  Foodpool: " + FoodPool)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects():  FoodReqs: " + FoodReqs)
		endif
	
	; We're transitioning to a better effect:
	elseif ModPoolAmount > 0
	
		if FoodReqs >= 0 && currentHE >= HC_HE_Fed.GetValue() 
			;fed
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Fed")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Fed.GetValue())
			
			; We've gotten better.  Roll back out food pool to the new value.
			FoodPool = SetPoolToTiersSustenanceValueOnRecovery(FoodPool, currentHE, HC_HE_Fed.GetValue() as int, 0)
	
			;cap it, if we are over the limit.
			FoodReqs = 0
			if FoodPool > 0
				FoodPool = 0
			endif

		elseif FoodReqs >= iFoodPoolPeckishAmount && currentHE >= HC_HE_Peckish.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Peckish")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Peckish.GetValue())
			
			; We've gotten better.  Roll back out food pool to the new value.
			FoodPool = SetPoolToTiersSustenanceValueOnRecovery(FoodPool, currentHE, HC_HE_Peckish.GetValue() as int, iFoodPoolPeckishAmount)

		elseif FoodReqs >= iFoodPoolHungryAmount && currentHE >= HC_HE_Hungry.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Hungry")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Hungry.GetValue())
			
			; We've gotten better.  Roll back out food pool to the new value.
			FoodPool = SetPoolToTiersSustenanceValueOnRecovery(FoodPool, currentHE, HC_HE_Hungry.GetValue() as int, iFoodPoolHungryAmount)

		elseif FoodReqs >= iFoodPoolFamishedAmount && currentHE >= HC_HE_Famished.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Famished")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Famished.GetValue())
			
			; We've gotten better.  Roll back out food pool to the new value.
			FoodPool = SetPoolToTiersSustenanceValueOnRecovery(FoodPool, currentHE, HC_HE_Famished.GetValue() as int, iFoodPoolFamishedAmount)

		elseif FoodReqs >= iFoodPoolRavenousAmount && currentHE >= HC_HE_Ravenous.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Ravenous")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Ravenous.GetValue())

			; We've gotten better.  Roll back out food pool to the new value.
			FoodPool = SetPoolToTiersSustenanceValueOnRecovery(FoodPool, currentHE, HC_HE_Ravenous.GetValue() as int, iFoodPoolRavenousAmount)

		elseif currentHE >= HC_HE_Starving.GetValue() 
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is Starving")
			PlayerRef.SetValue(HC_HungerEffect, HC_HE_Starving.GetValue())

			;cap it
			if foodPool < iFoodPoolStarvingAmount
				foodPool = iFoodPoolStarvingAmount
			endif
			if FoodReqs < iFoodPoolStarvingAmount
				FoodReqs = iFoodPoolStarvingAmount
			endif

		else
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): GETTING BETTER - NO MATCH!")
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Player is " + PlayerRef.GetValue(HC_HungerEffect))
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): Foodpool: " + FoodPool)
			trace(self, "        ModFoodPoolAndUpdateHungerEffects(): FoodReqs: " + FoodReqs)
		
		endif
	endif

	; If we've changed tiers, let's add some fatigue and show our message.
	bool bstateChanged = currentHE != PlayerRef.GetValue(HC_HungerEffect) as int
	bool showSustenanceMessage = ShowSustenance(bstateChanged)
	bool announceFatigue = AnnounceFatigue(bstateChanged, ModPoolAmount as int)
	UpdateNextSustenanceTickDay(bstateChanged, ModPoolAmount as int)
		
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                             Final FoodPool: " + FoodPool)
	trace(self, "        ModFoodPoolAndUpdateHungerEffects()                             Final FoodReqs: " + FoodReqs)
	ApplyEffect(HC_Rule_SustenanceEffects, HungerEffects, HC_HungerEffect, DispellRestedSpells = false, DisplayAfterAwakingMessage= !announceFatigue, bDisplayMessage = showSustenanceMessage, bAnnounceFatigue = announceFatigue)

EndFunction

Function ModDrinkPoolAndUpdateThirstEffects(int ModPoolAmount)
	trace(self, "      ModDrinkPoolAndUpdateThirstEffects():                                          ModPoolAmount: " + ModPoolAmount)

	; Store our current effect to test for a change...
	int currentTE = PlayerRef.GetValue(HC_ThirstEffect) as int

	if ModPoolAmount >= 0
		; FIND OUR CORRECT MOD VALUE BASED ON YOU CURRENT TIER AND/OR EFFECTS
		; We cap this value because our high value beverages are really high value...
	  	if ModPoolAmount > MaxDrinkValue
	  		ModPoolAmount = MaxDrinkValue
	  		trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                               Capped @ MaxDrinkValue: " + ModPoolAmount)

	  	; Adjust our ModPoolAmount for current thirst state:
		elseif HC_TE_Hydrated.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueHydrated) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():            Player is Hydrated! Updated ModPoolAmount: " + ModPoolAmount)

		elseif HC_TE_Parched.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueParched) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():             Player is Parched! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_TE_Thirsty.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueThirsty) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():             Player is Thirsty! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_TE_MildlyDehydrated.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueMildlyDehydrated) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():   Player is Mildly Dehydrated! Updated ModPoolAmount: " + ModPoolAmount)
			
		elseif HC_TE_Dehydrated.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueDehydrated) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():          Player is Dehydrated! Updated ModPoolAmount: " + ModPoolAmount)

		elseif HC_TE_SeverelyDehyrdated.GetValue() == currentTE
			ModPoolAmount = CapFoodAndDrinkPoolMinValue(ModPoolAmount as float, MinDrinkValueSeverelyDehydrated) as int
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Severely Dehydrated! Updated ModPoolAmount: " + ModPoolAmount)
			
		endif

	endif

	; Update our new pool and required food values.
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                        Old DrinkPool: " + DrinkPool)
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                        Old DrinkReqs: " + DrinkReqs)
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                      + ModPoolAmount: " + ModPoolAmount)
	DrinkPool += ModPoolAmount
	DrinkReqs += ModPoolAmount
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                        New DrinkPool: " + DrinkPool)
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                        New DrinkReqs: " + DrinkReqs)

	; Based on Drink pool deficit, set effect...
	; We're transitioning to a worse effect:
	if ModPoolAmount < 0
		if DrinkPool <= iDrinkPoolSeverelyDehydratedAmount && currentTE <= HC_TE_SeverelyDehyrdated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Severely Dehydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_SeverelyDehyrdated.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			DrinkReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(DrinkReqs, currentTE, HC_TE_SeverelyDehyrdated.GetValue() as int, iDrinkPoolSeverelyDehydratedAmount)

			;cap it
			DrinkPool = iDrinkPoolSeverelyDehydratedAmount

		elseif DrinkPool <= iDrinkPoolDehydratedAmount && currentTE <= HC_TE_Dehydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Dehydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Dehydrated.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			DrinkReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(DrinkReqs, currentTE, HC_TE_Dehydrated.GetValue() as int, iDrinkPoolDehydratedAmount)

		elseif DrinkPool <= iDrinkPoolMildlyDehydratedAmount && currentTE <= HC_TE_MildlyDehydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Mildly Dehyrdated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_MildlyDehydrated.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			DrinkReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(DrinkReqs, currentTE, HC_TE_MildlyDehydrated.GetValue() as int, iDrinkPoolMildlyDehydratedAmount)

		elseif DrinkPool <= iDrinkPoolThirstyAmount && currentTE <= HC_TE_Thirsty.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Thirsty")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Thirsty.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			DrinkReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(DrinkReqs, currentTE, HC_TE_Thirsty.GetValue() as int, iDrinkPoolThirstyAmount)

		elseif DrinkPool <= iDrinkPoolParchedAmount && currentTE <= HC_TE_Parched.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Parched")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Parched.GetValue())

			; We've gotten worse.  Bump up the Food Requirements needed to clear states.
			DrinkReqs = SetOrCapReqsToTiersSustenanceValueOnDeterioration(DrinkReqs, currentTE, HC_TE_Parched.GetValue() as int, iDrinkPoolParchedAmount)

		elseif currentTE <= HC_TE_Hydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Hydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Hydrated.GetValue())

			; Make sure Drink Requirements remains atleast as high as the current cap.
			if  DrinkReqs < 0
				DrinkReqs = 0
			endif

			;cap it, if we are over the limit.
			if DrinkPool > 0
				DrinkPool = 0
			endif

		else
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): GETTING WORSE - NO MATCH!")
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is: " + PlayerRef.GetValue(HC_ThirstEffect))
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Drinkpool: " + Drinkpool)
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): DrinkReqs: " + DrinkReqs)
		endif

	; We're transitioning to a better effect:
	elseif ModPoolAmount > 0
		if DrinkReqs >= 0 && currentTE >= HC_TE_Hydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Hydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Hydrated.GetValue())
			
			; We've gotten better.  Roll back out drink pool to the new value.
			DrinkPool = SetPoolToTiersSustenanceValueOnRecovery(DrinkPool, currentTE, HC_TE_Hydrated.GetValue() as int, 0)

			;cap it, if we are over the limit.
			DrinkReqs = 0
			if DrinkPool > 0
				DrinkPool = 0
			endif

		elseif DrinkReqs >= iDrinkPoolParchedAmount && currentTE >= HC_TE_Parched.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Parched")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Parched.GetValue())

			; We've gotten better.  Roll back out drink pool to the new value.
			DrinkPool = SetPoolToTiersSustenanceValueOnRecovery(DrinkPool, currentTE, HC_TE_Parched.GetValue() as int, iDrinkPoolParchedAmount)

		elseif DrinkReqs >= iDrinkPoolThirstyAmount && currentTE >= HC_TE_Thirsty.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Thirsty")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Thirsty.GetValue())

			; We've gotten better.  Roll back out drink pool to the new value.
			DrinkPool = SetPoolToTiersSustenanceValueOnRecovery(DrinkPool, currentTE, HC_TE_Thirsty.GetValue() as int, iDrinkPoolThirstyAmount)

		elseif DrinkReqs >= iDrinkPoolMildlyDehydratedAmount && currentTE >= HC_TE_MildlyDehydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Mildly Dehyrdated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_MildlyDehydrated.GetValue())

			; We've gotten better.  Roll back out drink pool to the new value.
			DrinkPool = SetPoolToTiersSustenanceValueOnRecovery(DrinkPool, currentTE, HC_TE_MildlyDehydrated.GetValue() as int, iDrinkPoolMildlyDehydratedAmount)

		elseif DrinkReqs >= iDrinkPoolDehydratedAmount && currentTE >= HC_TE_Dehydrated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Dehydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_Dehydrated.GetValue())

			; We've gotten better.  Roll back out drink pool to the new value.
			DrinkPool = SetPoolToTiersSustenanceValueOnRecovery(DrinkPool, currentTE, HC_TE_Dehydrated.GetValue() as int, iDrinkPoolDehydratedAmount)

		elseif currentTE >= HC_TE_SeverelyDehyrdated.GetValue() 
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Player is Severely Dehydrated")
			PlayerRef.SetValue(HC_ThirstEffect, HC_TE_SeverelyDehyrdated.GetValue())

			;cap it
			if DrinkPool < iDrinkPoolSeverelyDehydratedAmount
				DrinkPool = iDrinkPoolSeverelyDehydratedAmount
			endif
			if DrinkReqs < iDrinkPoolSeverelyDehydratedAmount
				DrinkReqs = iDrinkPoolSeverelyDehydratedAmount
			endif
		
		else
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): GETTING BETTER - NO MATCH!")
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects():  Player is " + PlayerRef.GetValue(HC_ThirstEffect))
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): Drinkpool: " + Drinkpool)
			trace(self, "        ModDrinkPoolAndUpdateThirstEffects(): DrinkReqs: " + DrinkReqs)
		endif
	endif

	; Is this a state change?  If so, let's add some fatigue and show our message.
	bool bstateChanged = currentTE != PlayerRef.GetValue(HC_ThirstEffect) as int
	bool showSustenanceMessage = ShowSustenance(bstateChanged)
	bool announceFatigue = AnnounceFatigue(bstateChanged, ModPoolAmount)
	UpdateNextSustenanceTickDay(bstateChanged, ModPoolAmount)
	
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                      Final DrinkPool: " + DrinkPool)
	trace(self, "        ModDrinkPoolAndUpdateThirstEffects():                                      Final DrinkReqs: " + DrinkReqs)
	ApplyEffect(HC_Rule_SustenanceEffects, ThirstEffects, HC_ThirstEffect, DispellRestedSpells = false, DisplayAfterAwakingMessage= !announceFatigue, bDisplayMessage = showSustenanceMessage, bAnnounceFatigue = announceFatigue)

EndFunction

Function DrinkSippableWater(bool bDirtyWater)
	if bDirtyWater
		PlayerRef.EquipItem(HC_SippableDirtyWater, abSilent = true)
	else
		PlayerRef.EquipItem(HC_SippableWater, abSilent = true)
	endif
EndFunction

Function FillWaterBottle(ObjectReference TargetRef)
	((self as quest) as HC_WaterBottleScript).FillWaterBottle(TargetRef)
EndFunction

; Called from ShutdownHardcore() and from HC_CureRavenousHunger.
Function CureRavenousHunger()
	; Turn off our value.
	trace(self, "CureRavenouseHunger(): Setting HC_CannibalEffect actor value to 0")
	playerRef.SetValue(HC_CannibalEffect, 0)
	; Reset our cannibal ticks count.
	CannibalTicks = 0
EndFunction



;**************************************************************************************************
;***********************************  		  DISEASE EFFECTS 		  *****************************
;**************************************************************************************************

Group Disease
	float Property DiseaseRiskRollThreshold = 0.25 const auto
{When we have this much disease chance built up, as scaled by the currect wellness rating, we need to roll for disease}

	float Property DiseaseRiskDrainPerCycle= -0.01 const auto
{Each disease update we drain this much out of the DiseaseRiskPool}

	float Property CurrentDiseasePoolValueMult = 1.75 const auto
{If NOT 0, scales the current Disease Risk Pool to multiply against the current Disease Pool Drain Rate}

	float Property DiseaseGracePeriod = 1.0 const auto
{You're not allowed to roll a disease unless you have been playing for longer than this many game days after getting diseased.}

	globalvariable Property HC_Rule_DiseaseEffects const auto mandatory

	Effect[] Property DiseaseEffects const auto mandatory
{Array of the various Disease Effects.}
;IMPORTANT NOTE: disease effects work a different than the others. They are simply effects we give the player that eventually time out.

	keyword[] Property DiseaseRiskFoodStandardKeywords const auto mandatory
{keywords in here represent things that are disease risks for the player}
	
	float Property DiseaseRiskFoodStandardAmount = 0.07 const auto
{how much % chance does this event add tot he DiseaseRiskPool}

	keyword[] Property DiseaseRiskFoodHighKeywords const auto mandatory
{keywords in here represent things that are disease risks for the player}

	float Property DiseaseRiskFoodHighAmount = 0.12 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	keyword[] Property DiseaseRiskChemsKeywords const auto mandatory
{keywords in here represent things that are disease risks for the player}

	float Property DiseaseRiskChemsAmount = 0.07 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	formlist Property DiseaseRiskCombatantFactions const auto mandatory
{if hit by these factions, player might get a disease. It's a formlist so we can use it as a filter for the onhit event as well}

	float Property DiseaseRiskCombatantAmount = 0.05 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	float Property DiseaseRiskCannibalAmount = 0.05 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	float Property GameDaysPerSwimmingEvent = 0.1 const auto
{in terms of game dayspassed, how long until we allow subsequent swimming events}

	float Property DiseaseRiskSwimmingAmount = 0.03 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	float Property GameDaysPerRainEvent = 0.5 const auto
{in terms of game dayspassed, how long until we allow subsequent swimming events}

	float Property DiseaseRiskRainAmount = 0.03 const auto
{how much % chance does this event add to the DiseaseRiskPool}

	Potion Property HC_Antibiotics const auto mandatory
{Antibiotics for catching it to process as food.}

	Potion Property HC_Antibiotics_SILENT_SCRIPT_ONLY const auto mandatory
{doesn't have audio effect. Used only for clearing on doctors healing and lowering diffiuclt}

	GlobalVariable Property HC_Vendor_Antiboitic_ChanceNone const auto mandatory
{autofill}

	GlobalVariable Property HC_Medkit_Antiboitic_ChanceNone const auto mandatory
{autofill}

	keyword Property HC_CausesImmunodeficiency const auto mandatory
{autofill; Checked to see if an item causes Immunodeficiency}

	Potion Property HC_Effect_Immunodeficiency const auto mandatory
{Drink this potion when you drink something that causes Immunodeficiency. This will weaken your immunity for some time, raising the chance for disease}

	float Property ImmunodeficiencyDiseaseChanceMult = 1.2 const auto
{Immunodeficiency increases your chance for disease by this much.}

	float Property DiseaseRiskIncreaser_Food  = 0.01 const auto
{Food increases your disease chance this much every time you eat. DOES NOT FORCE A ROLL!}

	float Property DiseaseRiskIncreaser_Drink = 0.00 const auto
{Drink increases your disease chance this much every time you drink. DOES NOT FORCE A ROLL!}

	float Property DiseaseRiskIncreaser_Cola  = 0.02 const auto
{Cola increases your disease chance this much every time you drink. DOES NOT FORCE A ROLL!}

	float Property DiseaseRiskIncreaser_Immunodeficiency = 0.05 const auto
{Immunodeficiency increases your disease chance this much every time you get it. DOES NOT FORCE A ROLL!}

EndGroup

ActiveMagicEffect HC_CaffeinatedEffect  ; This is the active magic effect for Caffeinated.

float DiseaseRiskPool  ;The value of our "bucket".  This is the chance of the player getting sick.

int lastDiseaseDieRoll = -1

float NextSwimEventAllowed   ;in terms of gamedayspassed, when do we next want to send a disease risk event for swimming

float NextRainEventAllowed conditional  ;in terms of gamedayspassed, when do we next want to send a disease risk event for Rain event

float LastDiseaseCycle = 0.0 ; Store off the last time we started the disease timer.

bool bIgnoreNonWeaponHits = false

bool bHandleDiseaseRiskEvent = false

float ImmunodeficiencyMult = 1.0 ; Used in the disease roll. Get's set in ImmunodeficiencyEffectToggle()

bool bPlayerTookAntibiotics = false; Used to keep track of a player taken antibiotics so we can consume with HandleDiseaseRiskEvent()

float LastDiseasedDay ; Used to give a grace period between diseases.

;called here and from GenericDoctorScript
Function ClearDisease()
	DiseaseRiskPool = 0
	PlayerRef.EquipItem(HC_Antibiotics_SILENT_SCRIPT_ONLY, abSilent = true)
EndFunction


Function PlayerEatsCorpse()
	trace(self, "PlayerEatsCorpse()")

	if IsGlobalTrue(HC_Rule_SustenanceEffects) == false
		;BAIL OUT, not in hardcore mode
		RETURN
	endif

	;Remove all food debt, eating corpses should always sate you fully (for a time)
	ModFoodPoolAndUpdateHungerEffects(9999, IsEatingCorpse = true)

	;Give you "Ravenous Hunger" potion effect which scales all food points that aren’t from bodies down to 0 for the next 24 game hours.
	playerRef.EquipItem(HC_Cannibal_RavenousHunger, abSilent = true) ;re-up this, it's effects last fo 9999 days but conditioned on actor value

	;set actor value to 1
	PlayerRef.SetValue(HC_CannibalEffect, 1)
	
	;subtract 1 from our ticks to remove an hour per body once we've started Craving.
	CannibalTicks    -= 1
	if  CannibalTicks < 0
		CannibalTicks = 0
	endif

	;Reset the Sustenenance Tick clock - to prevent you from getting hungry again right away - note this also resets the drink timer... lucky you.
	StartTimerGameTime(GameTimerInterval_Sustenance,  GameTimerID_Sustenance)

	;Future sustenance ticks will drop you down to Ravenous
	;handled in HandleSustenanceTimer

	;show message
	HC_Cannibal_Msg_RavenousHunger_EatCorpse.show()

	;start risk event
	HandleDiseaseRiskEvent(DiseaseRiskCannibalAmount)
EndFunction


Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
	
	bool bhandleDisease = true

	; If this is something other than a weapon, we need to see if we're allowed to handle it at this time.
	; ...Looking at you GLOWING ONES RADIATION CLOAK!
	if !(akSource as Weapon) && bIgnoreNonWeaponHits
		trace(self, " OnHit() BAILING OUT! NON Weapon Hit from DiseaseRiskCombatantFactions. Currently ignored.")
		bhandleDisease = false
	elseif !(akSource as Weapon) && !bIgnoreNonWeaponHits
		trace(self, "  OnHit() HANDLING DISEASE! NON Weapon Hit from DiseaseRiskCombatantFactions. Currently allowed.")
		StartTimerGameTime(GameTimerInterval_IgnoreNonWeaponHits, GameTimerID_IgnoreNonWeaponHits)
		bIgnoreNonWeaponHits = true
	else
		trace(self, "  OnHit() HANDLING DISEASE! Weapon Hit from DiseaseRiskCombatantFactions.")
	endif

	; Each hit is a chance for getting disease:
	if bhandleDisease
		HandleDiseaseRiskEvent(DiseaseRiskCombatantAmount)
	endif

	;filtered by DiseaseRiskCombatantFactions
	RegisterForHitEvent(PlayerRef, DiseaseRiskCombatantFactions) 

EndEvent


Event Perk.OnEntryRun(Perk akSender, int auiEntryID, ObjectReference akTarget, Actor akOwner)
	trace(self, "Perk.OnEntryRun() for Cannibal perks. Will call HandleDiseaseRiskEvent()")

	;only Cannibal perks are registered so we can assume it was one of those

	HandleDiseaseRiskEvent(DiseaseRiskCannibalAmount)

EndEvent


Event Actor.OnPlayerSwimming(Actor akSender)
	float GameDaysPassed = Utility.GetCurrentGameTime() 

	if NextSwimEventAllowed <= GameDaysPassed
		trace(self, "Actor.OnPlayerSwimming() and NextSwimEventAllowed <= GameDaysPassed. Will call HandleDiseaseRiskEvent()")
		HandleDiseaseRiskEvent(DiseaseRiskSwimmingAmount)
		NextSwimEventAllowed = GameDaysPassed + GameDaysPerSwimmingEvent
	endif

EndEvent


Function SetNextRainEventAllowed()
	float GameDaysPassed = Utility.GetCurrentGameTime() 
	NextRainEventAllowed = GameDaysPassed + GameDaysPerRainEvent
EndFunction

; ALL HAIL THE DANGER TACO!!!
Function HandleDiseaseRiskEvent(float RiskyEventPoints)
	trace(self, "HandleDiseaseRiskEvent() RiskyEventPoints: " + RiskyEventPoints)
	
	if IsGlobalTrue(HC_Rule_DiseaseEffects) == false
		;BAIL OUT, not in hardcore mode
		RETURN
	endif

	; Tutorial Call - High Risk Event.
	TryTutorial(HighRiskEventTutorial, "HighRiskEventTutorial")

	; If our risk pool is greater than the Wellness ceiling it's not allowed to go higher,
	; but it must drain out from there. Otherwise, we add the risk and cap it out to the ceiling.
	float wellnessCeiling= GetWellnessCeiling()
	trace(self, "  HandleDiseaseRiskEvent() Old DiseaseRiskPool " + DiseaseRiskPool)
	if  DiseaseRiskPool  < wellnessCeiling
		DiseaseRiskPool += RiskyEventPoints
		if  DiseaseRiskPool > wellnessCeiling
			DiseaseRiskPool = wellnessCeiling
		endif
	endif
	trace(self, "  HandleDiseaseRiskEvent() Updated DiseaseRiskPool " + DiseaseRiskPool)

	; Set our flag.
	bHandleDiseaseRiskEvent = true

	; Restart the timer... You're buying youself time but it's gonna catch up with you.
	StartTimerGameTime(GameTimerInterval_DiseasePostRiskEvent, GameTimerID_Disease)
	
EndFunction


Function HandleDiseaseTimer()
	trace(self, "  HandleDiseaseTimer() bHandleDiseaseRiskEvent: " + bHandleDiseaseRiskEvent + ", DiseaseRiskPool: " + DiseaseRiskPool + ", DiseaseRiskRollThreshold" + DiseaseRiskRollThreshold)
	
	; If the risk pool is greater than the roll threshold, let's roll for disease!  NO WHAMMY!
	if bHandleDiseaseRiskEvent && DiseaseRiskPool > DiseaseRiskRollThreshold
		; Check for disease. If you get one (true), we empty the pool entirely. If not (false), we should drain some out.
		if !CheckAndPossiblyApplyDisease(bShouldClearDiseaseRiskPoolOnDisease = true, bShouldClearDiseaseRiskPool = false)
			DrainDiseaseRiskPool()
		endif
	else
		; We still need to drain this every tick.
		DrainDiseaseRiskPool()
	endif

	; Events handled.  Unflagging.
	bHandleDiseaseRiskEvent = false

EndFunction


Function CheckForDiseaseAndRestart()
	trace(self, "  CheckForDiseaseAndRestart()")
	DrainDiseaseRiskPool()
	CheckAndPossiblyApplyDisease(bShouldClearDiseaseRiskPoolOnDisease = true, bShouldClearDiseaseRiskPool = true)
	StartTimerGameTime(GameTimerInterval_Disease, GameTimerID_Disease)
EndFunction

Function FillDiseaseRiskPool(float PoolIncrease = 0.01)
	
	trace(self, "    FillDiseaseRiskPool() - Old DiseaseRiskPool: " + DiseaseRiskPool)
	float wellnessCeiling= GetWellnessCeiling()
	if  DiseaseRiskPool  < wellnessCeiling
		DiseaseRiskPool += PoolIncrease
		if  DiseaseRiskPool > wellnessCeiling
			DiseaseRiskPool = wellnessCeiling
		endif
	endif
	trace(self, "    FillDiseaseRiskPool() - New DiseaseRiskPool: " + DiseaseRiskPool)

EndFunction

Function DrainDiseaseRiskPool()               
	; Grab out current time in hours...
	float currentGameTime= Utility.GetCurrentGameTime() * 24.0

	; How long have we been unresponsive?
	float cyclesPassed= (currentGameTime - LastDiseaseCycle) / GameTimerInterval_Disease

	; Show me...
	trace(self, "    DrainDiseaseRiskPool()           currentGameTime: " + currentGameTime)
	trace(self, "      DrainDiseaseRiskPool()        LastDiseaseCycle: " + LastDiseaseCycle)
	trace(self, "      DrainDiseaseRiskPool()            cyclesPassed: " + cyclesPassed)

	; Grab our needed values.
	float wellnessCeiling = GetWellnessCeiling()
	float wellnessFloor   = GetWellnessFloor()
	float diseaseToDrain  = 0.0

	; Drain it, but only down to your current tiers ceiling.  
	; Yes, the ceiling, this is intended to get you back down to...
	; your current tier not drain what's in your current tier.
	if DiseaseRiskPool > wellnessCeiling
		; Calculate how much we need to drain from the pool.
		diseaseToDrain= DiseaseRiskDrainPerCycle * cyclesPassed * GetWellnessDrainMult() * GetWellnessPoolDrainMult(wellnessFloor)
		trace(self, "      DrainDiseaseRiskPool()     OLD DiseaseRiskPool: " + DiseaseRiskPool)
		trace(self, "      DrainDiseaseRiskPool()          diseaseToDrain: " + diseaseToDrain)
		DiseaseRiskPool += diseaseToDrain
		trace(self, "      DrainDiseaseRiskPool() UPDATED DiseaseRiskPool: " + DiseaseRiskPool)
		if  DiseaseRiskPool < wellnessCeiling
			DiseaseRiskPool = wellnessCeiling
			trace(self, "      DrainDiseaseRiskPool() CAPPING DiseaseRiskPool: " + DiseaseRiskPool)
		endif
	elseif DiseaseRiskPool < wellnessFloor
		DiseaseRiskPool = wellnessFloor
		trace(self, "      DrainDiseaseRiskPool()     Old DiseaseRiskPool: " + DiseaseRiskPool)
		trace(self, "      DrainDiseaseRiskPool()          diseaseToDrain: " + diseaseToDrain)
		trace(self, "      DrainDiseaseRiskPool() FLOORED DiseaseRiskPool: " + DiseaseRiskPool)
	else
		trace(self, "      DrainDiseaseRiskPool()  HELD DiseaseRiskPool @: " + DiseaseRiskPool)
	endif

	; Note our current time.
	LastDiseaseCycle = currentGameTime

EndFunction


; returns true if diseased.
bool Function CheckAndPossiblyApplyDisease(bool bShouldClearDiseaseRiskPoolOnDisease = true, bool bShouldClearDiseaseRiskPool = false)
	trace(self, "    CheckAndPossiblyApplyDisease() bShouldClearDiseaseRiskPoolOnDisease, bShouldClearDiseaseRiskPool: " + bShouldClearDiseaseRiskPoolOnDisease + ", " + bShouldClearDiseaseRiskPool )

	if IsGlobalTrue(HC_Rule_DiseaseEffects) == false
		;BAIL OUT, not in hardcore mode
		RETURN false
	endif

	float diseaseDieRoll = RollForDisease() ;returns positive if disease roll was successful, negative if not diseased
	bool  diseased = diseaseDieRoll > 0

	trace(self, "      CheckAndPossiblyApplyDisease() bPlayerTookAntibiotics: " + bPlayerTookAntibiotics)
	if bPlayerTookAntibiotics
		diseased = false
		bPlayerTookAntibiotics = false
		trace(self, "      CheckAndPossiblyApplyDisease()  PLAYER TOOK ANTIBIOTICS RECENTLY!  NO DISEASES WILL BE APPLIED!!")
	endif

	if diseased
		trace(self, "      CheckAndPossiblyApplyDisease()  Player will be diseased if he doesnt have a remedy...")
		
		;Randomly pick a disease and apply it
		int arrayLen = DiseaseEffects.length
		int dieRoll = utility.RandomInt(0, arrayLen - 1)

		;if same as last time, pick the higher one (they are arranged in array so that this increased chance these come in pairs will maybe make some thematic sense)
		if dieRoll == lastDiseaseDieRoll
			dieRoll += 1
		endif

		if dieRoll > arrayLen - 1
			dieRoll = 0
		endif

		lastDiseaseDieRoll = dieRoll
		effect effectToApply = DiseaseEffects[dieRoll]

		;*** CHECK FOR HERBAL MEDICATION PROTECTION
		if PlayerRef.HasMagicEffect(effectToApply.HerbalRemedyEffect) 			
			trace(self, "      CheckAndPossiblyApplyDisease()  Player has Remedy (" + effectToApply.HerbalRemedyEffect + ") for " + effectToApply.EffectPotion)
			trace(self, "      CheckAndPossiblyApplyDisease()     diseaseDieRoll: " + diseaseDieRoll)
			trace(self, "      CheckAndPossiblyApplyDisease()  ImmunityThreshold: " + effectToApply.HerbalRemedyBoostedImmunityThreshold)
			; diseaseDieRoll needs to be <= Risk Pool (check!) && >= BoostedImmunityThreshold to get this disease.
			diseased = diseaseDieRoll >= effectToApply.HerbalRemedyBoostedImmunityThreshold
			trace(self, "      CheckAndPossiblyApplyDisease()  PROTECTED AGAINST DISEASE: " + !diseased)
		endif
		

		if diseased

			LastDiseasedDay = Utility.GetCurrentGameTime()
			trace(self, "      CheckAndPossiblyApplyDisease()  **DISEASED** - INFECTED @: " + LastDiseasedDay)

			message diseaseMessageToDisplay
			; If you already have this effect lets tweak our announce.
			if PlayerRef.HasMagicEffect(effectToApply.MagicEffectToApply)
				diseaseMessageToDisplay = effectToApply.MessageToRedisplay
			else
				diseaseMessageToDisplay = effectToApply.MessageToDisplay
			endif

			; Apply the effect and show our chosen message.
			playerRef.EquipItem(effectToApply.EffectPotion, abSilent = true)
			diseaseMessageToDisplay.Show()
			; Tutorial Call - Diseased.
			TryTutorial(DiseasedTutorial, "DiseasedTutorial")

			; Did you request to clear the pool if diseased?
			if bShouldClearDiseaseRiskPoolOnDisease
				DiseaseRiskPool = GetWellnessFloor()
			endif

		endif
	endif
	
	; Did you request to clear the pool after the roll?
	if bShouldClearDiseaseRiskPool
		DiseaseRiskPool = GetWellnessFloor()
	endif
	trace(self, "      CheckAndPossiblyApplyDisease() Updated DiseaseRiskPool " + DiseaseRiskPool)

	return diseased

EndFunction

;returns > dieroll amount if roll was successful (ie should gain a disease)
;return < 0 if roll was unsuccessful
float Function RollForDisease()
	trace(self, "        RollForDisease()")

	float currentGameTime = utility.GetCurrentGameTime()

	if currentGameTime < LastDiseasedDay + DiseaseGracePeriod
		trace(self, "        Too Soon! Failing roll due to being within the Grace Period!")
		return -1.0
	endif

	float dieRoll = utility.Randomfloat(0.01, 1.0)

	trace(self, "          RollForDisease() DiseaseRiskPool: " + DiseaseRiskPool)
	trace(self, "          RollForDisease()         dieRoll: " + dieRoll)

	float diseaseChance = DiseaseRiskPool * ImmunodeficiencyMult

	if dieRoll <= diseaseChance
		trace(self, "          RollForDisease() dieRoll: " + dieRoll + " <= chance: " + diseaseChance + ", returning: true")
		return dieRoll
	else
		trace(self, "          RollForDisease() dieRoll: " + dieRoll + " > chance: " + diseaseChance + ", returning: false")
		return -1.0
	endif

EndFunction

; Returns this Wellness tiers Disease Chance ceiling
float Function GetWellnessCeiling()
	trace(self, "        GetWellnessCeiling()")
	
	; Figure out which effects by consulting player's current actor values
	effect HungerEffect = GetCurrentEffect(HC_HungerEffect, HungerEffects)
	effect ThirstEffect = GetCurrentEffect(HC_ThirstEffect, ThirstEffects)
	effect SleepEffect  = GetCurrentEffect(HC_SleepEffect,  SleepEffects )

	; Average the Wellness based Ceiling
	float HungerCeiling   = HungerEffect.DiseaseChanceCeiling
	float ThirstCeiling   = ThirstEffect.DiseaseChanceCeiling 
	float SleepCeiling    = SleepEffect.DiseaseChanceCeiling 
	float WellnessCeiling = ((HungerCeiling + ThirstCeiling + SleepCeiling) * 0.3333333)

	; Debuggerific
	trace(self, "          GetWellnessCeiling() HungerCeiling: " + HungerCeiling  )
	trace(self, "          GetWellnessCeiling() ThirstCeiling: " + ThirstCeiling  )
	trace(self, "          GetWellnessCeiling()  SleepCeiling: " + SleepCeiling   )
	trace(self, "          GetWellnessCeiling()     returning: " + WellnessCeiling)

	; Return the averaged Ceiling
	return WellnessCeiling

EndFunction

; Returns this Wellness tiers Disease Chance floor
float Function GetWellnessFloor()
	trace(self, "        GetWellnessFloor()")
	
	; Figure out which effects by consulting player's current actor values
	effect HungerEffect = GetCurrentEffect(HC_HungerEffect, HungerEffects)
	effect ThirstEffect = GetCurrentEffect(HC_ThirstEffect, ThirstEffects)
	effect SleepEffect  = GetCurrentEffect(HC_SleepEffect,  SleepEffects )

	; Average the Wellness based Floor
	float HungerFloor   = HungerEffect.DiseaseChanceFloor
	float ThirstFloor   = ThirstEffect.DiseaseChanceFloor 
	float SleepFloor    = SleepEffect.DiseaseChanceFloor 
	float WellnessFloor = ((HungerFloor + ThirstFloor + SleepFloor) * 0.3333333)

	; Debuggerific
	trace(self, "          GetWellnessFloor() HungerFloor: " + HungerFloor  )
	trace(self, "          GetWellnessFloor() ThirstFloor: " + ThirstFloor  )
	trace(self, "          GetWellnessFloor()  SleepFloor: " + SleepFloor   )
	trace(self, "          GetWellnessFloor()   returning: " + WellnessFloor)

	; Return the averaged Floor
	return WellnessFloor

EndFunction

; Returns this Wellness tiers Disease Chance Drain Multiplier
float Function GetWellnessDrainMult()
	trace(self, "        GetWellnessDrainMult()")
	
	; Figure out which effects by consulting player's current actor values
	effect HungerEffect = GetCurrentEffect(HC_HungerEffect, HungerEffects)
	effect ThirstEffect = GetCurrentEffect(HC_ThirstEffect, ThirstEffects)
	effect SleepEffect  = GetCurrentEffect(HC_SleepEffect,  SleepEffects )

	; Average the Wellness based Drain Mult
	float HungerDrainMult   = HungerEffect.DiseaseChanceDrainMult
	float ThirstDrainMult   = ThirstEffect.DiseaseChanceDrainMult 
	float SleepDrainMult    = SleepEffect.DiseaseChanceDrainMult 
	float WellnessDrainMult = ((HungerDrainMult + ThirstDrainMult + SleepDrainMult) * 0.3333333)

	; Debuggerific
	trace(self, "        GetWellnessDrainMult() HungerDrainMult: " + HungerDrainMult  )
	trace(self, "        GetWellnessDrainMult() ThirstDrainMult: " + ThirstDrainMult  )
	trace(self, "        GetWellnessDrainMult()  SleepDrainMult: " + SleepDrainMult   )
	trace(self, "        GetWellnessDrainMult()       returning: " + WellnessDrainMult)

	; Return the averaged DrainMult
	return WellnessDrainMult

EndFunction

; Returns this Wellness tiers Disease Chance Pool Drain Multiplier
float Function GetWellnessPoolDrainMult(float WellnessFloor)
	
	; CAP IT
	if  DiseaseRiskPool < WellnessFloor
		DiseaseRiskPool = WellnessFloor
	endif

	if CurrentDiseasePoolValueMult != 0
		trace(self, "        GetWellnessPoolDrainMult() - CurrentDiseasePoolValueMult: " + CurrentDiseasePoolValueMult + ", DiseaseRiskPool: " + DiseaseRiskPool + ", RETURNING: " + DiseaseRiskPool * CurrentDiseasePoolValueMult)
		return DiseaseRiskPool * CurrentDiseasePoolValueMult
	endif
	trace(self, "        GetWellnessPoolDrainMult() - CurrentDiseasePoolValueMult: " + CurrentDiseasePoolValueMult + ", DiseaseRiskPool: " + DiseaseRiskPool + ", RETURNING: 1.0")
	return 1.0

EndFunction


effect Function GetCurrentEffect(ActorValue EffectActorValue, Effect[] EffectsArray)
	float val = PlayerRef.GetValue(EffectActorValue)

	;loop through the arrays, and find the struct who's globalenum value matches what is store in the player actor value
	int i = 0
	int max = EffectsArray.length
	while (i < max)
		effect currentEffect = EffectsArray[i]

		if currentEffect.GlobalEnum.GetValue() == val
			trace(self, "            GetCurrentEffect() EffectActorValue: " + EffectActorValue + "; Returning " + currentEffect)
			return currentEffect
		endif
		i += 1
	endwhile

	trace(self, "            GetCurrentEffect() didn't find an effect", 2)
	return None

EndFunction

;called by HC_DiseaseSleepinessEffectScript
Function SleepinessEffectToggle(bool IsPlayerSleepy)
	trace(self, "SleepinessEffectToggle(): " + IsPlayerSleepy)
	StartSleepDeprivationTimer(GetHoursUntilCurrentSleepCycleEnds())
EndFunction

;called by HC_ImmunodeficiencyEffectScript
Function ImmunodeficiencyEffectToggle(bool IsPlayerImmunodeficient)

	if IsPlayerImmunodeficient
		; Scale our wellness value
		ImmunodeficiencyMult = ImmunodeficiencyDiseaseChanceMult
		HandleSleepDeprivationTimer()
		trace(self, "ImmunodeficiencyEffectToggle(): Scaling Disease Chance By: " + ImmunodeficiencyDiseaseChanceMult)
		; Tutorial Call - Immunodeficiency.
		TryTutorial(ImmunodeficiencyTutorial, "ImmunodeficiencyTutorial")
	else
		; Restore our wellness value
		ImmunodeficiencyMult = 1.0
		trace(self, "ImmunodeficiencyEffectToggle(): Player is back to normal!")
	endif

EndFunction

;called by HC_CaffeinatedEffectScript
Function CaffeinatedEffectToggle(ActiveMagicEffect CaffeinatedEffect)
	HC_CaffeinatedEffect = CaffeinatedEffect
EndFunction

;**************************************************************************************************
;**************************************        SLEEP EFFECTS       ********************************
;**************************************************************************************************

;bedtype "enums"
int iBedType_NotApplicable = -1 const
int iBedType_SleepingBag = 0 const
int iBedType_Mattress = 1 const
int iBedType_Bed = 2 const

Group SleepEffects
	globalvariable Property HC_Rule_SleepEffects const auto mandatory

	ActorValue Property HC_SleepEffect const auto mandatory

	int Property MinHoursForCuringSleepEffects = 2 const auto
	{Need to at least sleep this long for sleep effects to be cured}

	keyword[] Property SleepingBagKeywords const auto mandatory
	{a bed with any of these keywords will be treated as a sleeping bag, wins over Mattress and Bed keywords}

	keyword[] Property MattressKeywords const auto mandatory
	{a bed with any of these keywords will be treated as a matress, wins over Bed keywords}

	keyword[] Property BedKeywords const auto mandatory
	{a bed with any of these keywords will be treated as a bed}

	Effect[] Property SleepEffects const auto mandatory
{The order in this array, is the order they devolution after time passes since sleeping.
***IMPORTANT REMINDER***
The first entry in this is a place hold for the Well Rested / Lover's Embrace effects, which are handled by pre-existing spells from base game not potions
}

	int Property IndexOfSleepEffectsForWellRestedORLoversEmbrace = 0 const auto
	{what index in SleepEffects represents WellRested}

	int Property HighestIndexOfSleepEffectsCuredBySleepingBag = 4 const auto
	{starting with this index in SleepEffects, you can cure this and higher effect while sleeping here}

	int Property HighestIndexOfSleepEffectsCuredByMattress = 2 const auto
	{starting with this index in SleepEffects, you can cure this and higher effect while sleeping here}

	int Property HighestIndexOfSleepEffectsCuredByBed = 0 const auto
	{starting with this index in SleepEffects, you can cure this and higher effect while sleeping here}

	message Property HC_SleepInterruptedMsg_Mattress const auto mandatory
	{autofill, message you get when you try to sleep longer than allowed}

	message Property HC_SleepInterruptedMsg_SleepingBag const auto mandatory
	{autofill, message you get when you try to sleep longer than allowed}

	perk Property HC_WellRestedPerk const auto mandatory
	Message Property WellRestedMessage const Auto
	String Property WellRestedSWFname const Auto
	Sound Property UIPerkWellRested Const Auto Mandatory

	perk Property HC_LoversEmbracePerk const auto mandatory
	Message Property LoversEmbraceMessage const Auto
	String Property LoversEmbraceSWFname Const Auto 
	Sound Property UIPerkLoversEmbrace Const Auto Mandatory


	spell Property WellRested const auto mandatory
	{autofill, base game spell we'll need to dispell}

	spell Property LoversEmbracePerkSpell const auto mandatory
	{autofill, base game spell we'll need to dispell}

	MagicEffect Property HC_Disease_Insomnia_Effect const auto mandatory
	{autofill, comes from disease, will cause player to wake up early}

	float Property InsomniaSleepMult = 0.5 Auto Const
	{How much to scale our sleep since we are currently suffering from Insomnia}

	MagicEffect Property HC_Disease_Sleepiness_Effect const auto mandatory
	{autofill, comes from disease, will cause player to need sleep more often}

	float Property DisaseSleepinessSleepDeprivationTimerMult = 0.5 const auto
	{when player has Sleepiness disease effect, the Sleep Deprivation Timer Duration should be scaled by this amount}

	Potion Property HC_Effect_Caffeinated const auto mandatory
{Drink this potion when you become Caffeinated to show the player the status.}

	message Property HC_SE_Msg_Caffeinated const auto mandatory
{Autofilled message to display when Caffeinated}

	float Property CaffeineInducedSleepDelay = 2.333 const auto
{How much time a caffeinated beverage (Nuka Cola / Cherry ) buys us.}

	float Property ExtraCaffeineInducedSleepDelay = 7.0 const auto
{How much time a caffeinated beverage (Quantum ) buys us.}


EndGroup

float NextSleepUpdateDay ; Keep track of the game days passed we should next increment the sleep tiers.
float LastSleepUpdateDay ; Keep track of the game days passed between real sleeping (>= 3 hours)
float SleepStartDay      ; Comes in as game days passed
float SleepStopDay       ; Comes in as game days passed
float WaitStartDay       ; Comes in as game days passed
float WaitStopDay        ; Comes in as game days passed

message EarlyWakeMessageToShow 	; The message we will show to the player to explain why we've woken them up.

bool ProcessingSleep = false
bool bFirstSleep = false
bool bSleepInterrupted = false

bool Function IsProcessingSleep()
	;for external access -- initial case is for preventing nerd rage from being triggered by us damaging you after sleeping
	return ProcessingSleep
EndFunction

Event OnPlayerWaitStart(float afWaitStartTime, float afDesiredWaitEndTime)
	WaitStartDay = afWaitStartTime
	trace(self, "OnPlayerWaitStart()           WaitStartDay: " + WaitStartDay)
EndEvent


Event OnPlayerWaitStop(bool abInterrupted)
	WaitStopDay = Utility.GetCurrentGameTime()
	trace(self, "OnPlayerWaitStop()             WaitStopDay: " + WaitStopDay)
	
	float GameHoursSpentWaiting = (WaitStopDay - WaitStartDay) * 24.0
	trace(self, "  OnPlayerWaitStop() GameHoursSpentWaiting: " + GameHoursSpentWaiting)
EndEvent


Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
	ProcessingSleep = true
	bSleepInterrupted = false
	trace(self, "OnPlayerSleepStart() ProcessingSleep: " + ProcessingSleep + ", bSleepInterrupted: " + bSleepInterrupted)

	SleepStartDay = afSleepStartTime
	trace(self, "  OnPlayerSleepStart()         SleepStartDay: " + SleepStartDay)

	; Poll for disease...
	CheckForDiseaseAndRestart()

	; Then cancel all our timers...  We'll restart when we wake.
	CancelTimerGameTime(GameTimerID_SleepDeprivation)
	CancelTimerGameTime(GameTimerID_Sustenance)
	CancelTimerGameTime(GameTimerID_Disease)
	CancelTimerGameTime(GameTimerID_Encumbrance) 

	;store existing health and condition values
	CacheValuesBeforeSleep()

	WakeUpPlayerBasedOnBedType(akBed, afSleepStartTime, afDesiredSleepEndTime)

EndEvent


Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
	trace(self, "OnPlayerSleepStop()")
	
	SleepStopDay = Utility.GetCurrentGameTime()
	float oneHour = 1.0 / 24.0
	float DaysSpentSleeping = SleepStopDay - SleepStartDay
	bool  bCanceledPreHour = false ; This is only used in the event that the player cancels sleep before an hour passes.
	if DaysSpentSleeping < oneHour
		trace(self, "  OnPlayerSleepStop()           < 1 hour DaysSpentSleeping: " + DaysSpentSleeping)
		DaysSpentSleeping = oneHour
		trace(self, "  OnPlayerSleepStop()            Updated DaysSpentSleeping: " + DaysSpentSleeping)
		bCanceledPreHour = true
	endif
	int GameHoursSpentSleeping = ((DaysSpentSleeping * 24) + fEpsilon) as int

	; Making sure we don't show the error message if you cancel in time.
	if abInterrupted
		bSleepInterrupted = abInterrupted
		trace(self, "  OnPlayerSleepStop() SLEEP INTERRUPTED!")
		if IsSleepingBag(akBed)
			if GameHoursSpentSleeping < 3
				CancelTimerGameTime(GameTimerID_DisplaySleepMessage)
				EarlyWakeMessageToShow = none
				trace(self, "  OnPlayerSleepStop() Canceled < 3 hour in Sleeping Bag!")
			endif
		elseif !IsBed(akBed)
			if GameHoursSpentSleeping < 5
				CancelTimerGameTime(GameTimerID_DisplaySleepMessage)
				EarlyWakeMessageToShow = none
				trace(self, "  OnPlayerSleepStop() Canceled < 5 hour in Dirty Mattress!")
			endif
		endif
	endif

	trace(self, "  OnPlayerSleepStop()                         SleepStopDay: " + SleepStopDay)   
	trace(self, "  OnPlayerSleepStop()                    DaysSpentSleeping: " + DaysSpentSleeping)
	trace(self, "  OnPlayerSleepStop()               GameHoursSpentSleeping: " + GameHoursSpentSleeping)

	;remove adrenaline based on number of hours
	int AdrenalineRanksToRemove

	if GameHoursSpentSleeping == 1
		AdrenalineRanksToRemove = 2
	elseif GameHoursSpentSleeping == 2
		AdrenalineRanksToRemove = 3
	elseif GameHoursSpentSleeping == 3
		AdrenalineRanksToRemove = 4
	elseif GameHoursSpentSleeping == 4
		AdrenalineRanksToRemove = 5
	elseif GameHoursSpentSleeping == 5
		AdrenalineRanksToRemove = 6
	elseif GameHoursSpentSleeping == 6
		AdrenalineRanksToRemove = 8
	else
		AdrenalineRanksToRemove = 10
	endif

	;REMOVE RANKS WORTH OF ADRENALINE
	int AdrelanineToRemove = AdrenalineRanksToRemove * killsForAdrenalinePerkLevel
	trace(self, "  OnPlayerSleepStop()                   AdrelanineToRemove: " + AdrelanineToRemove )
	ModAdrenaline(-AdrelanineToRemove)

	; Do we have Insomnia?  If we do, that sucks... We won't get much sleep like that.
	if PlayerRef.HasMagicEffect(HC_Disease_Insomnia_Effect)
		
		GameHoursSpentSleeping = (GameHoursSpentSleeping as float * InsomniaSleepMult) as int
		
		; Don't let you sleep less than 1 hour.
		if GameHoursSpentSleeping < 1
			GameHoursSpentSleeping = 1
		; No one with Insomnia is Well Rested.
		elseif GameHoursSpentSleeping > 6
			GameHoursSpentSleeping = 6
		endif
		trace(self, "  OnPlayerSleepStop() - INSOMNIA! - GameHoursSpentSleeping: " + GameHoursSpentSleeping)

	endif

	;Heal player's health and condition values based on how long he sleeped
	UpdateHealingAfterSleep(GameHoursSpentSleeping)

	; Handle Encumbrance and then restarting the timer since we just woke up...
	HandleEncumbranceTimer()
	StartTimerGameTime(GameTimerInterval_Encumbrance, GameTimerID_Encumbrance)

	; Handle Sustenance and then restarting the timer since we just woke up...
	HandleSustenanceTimer(bWasSleeping = true, bCanceledSleepPreHour = bCanceledPreHour)
	StartTimerGameTime(GameTimerInterval_Sustenance,  GameTimerID_Sustenance)

	; Handled disease OnPlayerSleepStart(). Restarting the timer since we just woke up...
	StartTimerGameTime(GameTimerInterval_Disease,     GameTimerID_Disease)

	float ftimeUntilNextSleepUpdate = GetHoursUntilCurrentSleepCycleEnds()
	
	; The first sleep timer is a super short tutorial time. 
	; We won't punish the player for sleeping before it expires.
	if bFirstSleep
		ftimeUntilNextSleepUpdate = GameTimerInterval_SleepDeprivation
		bFirstSleep = false
	endif

	; Update sleep effects based on bed and hours slept...
	UpdateSleepEffectsAfterSleeping(GameHoursSpentSleeping, akBed, ftimeUntilNextSleepUpdate)
	
	ProcessingSleep = false

EndEvent

Function StartSleepDeprivationTimer(float RestartTimerForThisManyGameHours = -1.0, bool ForceThisExactValue = false)
	trace(self, "    StartSleepDeprivationTimer() RestartTimerForThisManyGameHours: " + RestartTimerForThisManyGameHours)

	float sleepInterval = RestartTimerForThisManyGameHours

	if false == ForceThisExactValue

		float intervalMult = 1

		if PlayerRef.HasMagicEffect(HC_Disease_Sleepiness_Effect)
			intervalMult = DisaseSleepinessSleepDeprivationTimerMult
		endif

		sleepInterval = GameTimerInterval_SleepDeprivation * intervalMult
		if RestartTimerForThisManyGameHours > 0
			sleepInterval = RestartTimerForThisManyGameHours * intervalMult
		endif

		StartTimerGameTime(sleepInterval, GameTimerID_SleepDeprivation) 
		
		trace(self, "      StartSleepDeprivationTimer()  starting timer with an interval of: " + sleepInterval)

	else
		StartTimerGameTime(sleepInterval, GameTimerID_SleepDeprivation)
	endif

	; Store our value away.
	NextSleepUpdateDay = utility.GetCurrentGameTime() + (sleepInterval / 24.0)

EndFunction

float Function GetHoursUntilCurrentSleepCycleEnds(bool abReturnGameDaysInstead= false)
	
	float hoursUntilCurrentSleepCycleEnds = NextSleepUpdateDay - utility.GetCurrentGameTime()
	
	if !abReturnGameDaysInstead
		hoursUntilCurrentSleepCycleEnds *= 24
	endif
	
	if hoursUntilCurrentSleepCycleEnds < 0
		return 0
	endif
	return hoursUntilCurrentSleepCycleEnds

EndFunction


;*** WE NEED A "wakeup after X hours" FUNCTION, THIS ISN'T THE BEST WAY TO HANDLE THIS
;***Ideally we could get code to prevent you from dialing in more than you can sleep
Function WakeUpPlayerBasedOnBedType(ObjectReference BedRef, float SleepStartTime, float DesiredTime)
	trace(self, "WakeUpPlayerBasedOnBedType() - SleepStartTime: "+SleepStartTime+", DesiredTime: "+DesiredTime)
	
	; I've heard they give out rewards for lowering the number of divides...
	float oneOverTwentyFour = 1.0/24.0

	float WakeDay = DesiredTime
	
	float MaxWakeDay

	if IsBed(BedRef)
		MaxWakeDay = SleepStartTime + 24.0 * oneOverTwentyFour
	elseif IsSleepingBag(BedRef)
		MaxWakeDay = SleepStartTime +  3.0 * oneOverTwentyFour
		EarlyWakeMessageToShow = HC_SleepInterruptedMsg_SleepingBag
	else ;treat everything else as mattress
		MaxWakeDay = SleepStartTime +  5.0 * oneOverTwentyFour
		EarlyWakeMessageToShow = HC_SleepInterruptedMsg_Mattress
	endif
	trace(self, "  WakeUpPlayerBasedOnBedType()                       MaxWakeDay: " + MaxWakeDay)

	if MaxWakeDay >= WakeDay
		;no need to force you to wake up
		trace(self, "  WakeUpPlayerBasedOnBedType() Letting them rest... MaxWakeDay: " + MaxWakeDay + " >= WakeDay: " + WakeDay)
		RETURN
	else
		trace(self, "  WakeUpPlayerBasedOnBedType() Setting WakeDay: " + WakeDay + " to MaxWakeDay: " + MaxWakeDay)
		WakeDay = MaxWakeDay
	endif

	float currentGameTime
	while (currentGameTime < WakeDay) && !bSleepInterrupted
		utility.WaitMenuMode(0.5) ;sleeping happens pretty fast, need to catch it so we don't get more than an hour before we check again
		currentGameTime = utility.GetCurrentGameTime()
		trace(self, "  WakeUpPlayerBasedOnBedType() WakeDay: " + WakeDay + ", currentGameTime: " + currentGameTime)
	endwhile

	; Bail out on sleep interruption.
	if  bSleepInterrupted
		trace(self, "  WakeUpPlayerBasedOnBedType() CANCELED! bSleepInterrupted: " + bSleepInterrupted)
		return
	endif

	;"wake up" the player
	PlayerRef.Moveto(PlayerRef) ;I worry a little bit about what this would do if the player was in a trigger, but in theory triggers should be able to handle this

	; Tutorial Call - Non Bed Wakeup.
	TryTutorial(NonBedSleepTutorial, "NonBedSleepTutorial")

	; Start the timer to display our wake up message.  Doing it like this prevents a broken save thumbnail.
	StartTimerGameTime(GameTimerInterval_DisplaySleepMessage, GameTimerID_DisplaySleepMessage)

EndFunction

Function HandleSleepDeprivationTimer()
	trace(self, "  HandleSleepDeprivationTimer() LastSleepUpdateDay: " + LastSleepUpdateDay)

	; This is no longer the short first sleep timer.
	bFirstSleep = false

	float currentGameTime = Utility.GetCurrentGameTime()

	;either of these perks only last 24 hours, so when the timer expires, just remove them
	playerRef.removePerk(HC_WellRestedPerk)
	playerRef.removePerk(HC_LoversEmbracePerk)

	; Handle cycles that are longer than our current interval due to disease.
	int IncrementEffectBy = 1
	if PlayerRef.HasMagicEffect(HC_Disease_Sleepiness_Effect)
		IncrementEffectBy = (((currentGameTime - LastSleepUpdateDay) * 24) / (GameTimerInterval_SleepDeprivation * DisaseSleepinessSleepDeprivationTimerMult)) as int
		if IncrementEffectBy < 1
			IncrementEffectBy = 1
		endif
	elseif iCaffeinated == 2
		IncrementEffectBy = 0
	endif

	
	ApplyEffect(HC_Rule_SleepEffects, SleepEffects, HC_SleepEffect, DispellRestedSpells = true, IncrementEffectBy = IncrementEffectBy, bAnnounceFatigue = true)

	if IncrementEffectBy
		; Tutorial Call - Tiredness.
		TryTutorial(TirednessTutorial, "TirednessTutorial")
	endif

	; Store this update time for handling no effect clearing sleeps.
	LastSleepUpdateDay = currentGameTime
	trace(self, "  HandleSleepDeprivationTimer() and setting LastSleepUpdateDay: " + LastSleepUpdateDay)

EndFunction



Function UpdateSleepEffectsAfterSleeping(int GameHoursSpentSleeping, ObjectReference BedSleptIn, float TimeUntilNextSleepUpdate)
	trace(self, "  UpdateSleepEffectsAfterSleeping() GameHoursSpentSleeping: " + GameHoursSpentSleeping + ", TimeUntilNextSleepUpdate: " + TimeUntilNextSleepUpdate)

	int CurrentSleepEffect = PlayerRef.GetValue(HC_SleepEffect) as int

	; Do you have Caffeine to sleep off?
	if iCaffeinated
		; Put us back to our previous state, and turn off Caffeinated.
		if iCaffeinated == 1
			CurrentSleepEffect += 1
		endif
		HC_CaffeinatedEffect.Dispel()
		HC_CaffeinatedEffect  = none
		iCaffeinated          = 0
		CaffeinatedCount      = 0
		ExtraCaffeinatedCount = 0
	endif

	int NewSleepEffect = 999

	bool SleepingInBed = IsBed(BedSleptIn)

	;first make sure we sleep long enough
	if GameHoursSpentSleeping >= MinHoursForCuringSleepEffects
	
		; Figure out where we could be at if we were allowed to take all of this sleep into account.
		NewSleepEffect = CurrentSleepEffect - GameHoursSpentSleeping + 1
		trace(self, "  UpdateSleepEffectsAfterSleeping() GameHoursSpentSleeping: " + GameHoursSpentSleeping + ", CurrentSleepEffect: " + CurrentSleepEffect + ", NewSleepEffect: " + NewSleepEffect)

		;roll back SleepEffects based on bed type
		if IsSleepingBag(BedSleptIn) 
			if  NewSleepEffect < HighestIndexOfSleepEffectsCuredBySleepingBag
				NewSleepEffect = HighestIndexOfSleepEffectsCuredBySleepingBag
				trace(self, "  UpdateSleepEffectsAfterSleeping() Sleeping Bag - HighestIndexOfSleepEffectsCuredBySleepingBag: " + HighestIndexOfSleepEffectsCuredBySleepingBag + ", Updated NewSleepEffect: " + NewSleepEffect)
			endif
		
		elseif IsMattress(BedSleptIn)
			if  NewSleepEffect < HighestIndexOfSleepEffectsCuredByMattress
				NewSleepEffect = HighestIndexOfSleepEffectsCuredByMattress
				trace(self, "  UpdateSleepEffectsAfterSleeping() Mattress - HighestIndexOfSleepEffectsCuredByMattress: " + HighestIndexOfSleepEffectsCuredByMattress + ", Updated NewSleepEffect: " + NewSleepEffect)
			endif
		
		elseif SleepingInBed
			if  NewSleepEffect < HighestIndexOfSleepEffectsCuredByBed
				NewSleepEffect = HighestIndexOfSleepEffectsCuredByBed
				trace(self, "  UpdateSleepEffectsAfterSleeping() Bed - HighestIndexOfSleepEffectsCuredByBed: " + HighestIndexOfSleepEffectsCuredByBed + ", Updated NewSleepEffect: " + NewSleepEffect)
			endif
		
		elseif NewSleepEffect < HighestIndexOfSleepEffectsCuredByMattress
			;unexpected, consider it mattress
			NewSleepEffect = HighestIndexOfSleepEffectsCuredByMattress 
			trace(self, "  UpdateSleepEffectsAfterSleeping() Other - HighestIndexOfSleepEffectsCuredByMattress: " + HighestIndexOfSleepEffectsCuredByMattress + ", Updated NewSleepEffect: " + NewSleepEffect)
		endif

		; NewSleepEffect -= 1 ;because you cure down to the previous SleepEffectslee
		trace(self, "  UpdateSleepEffectsAfterSleeping() Final NewSleepEffect: " + NewSleepEffect)
	
	endif

	;throw away well rested and lovers embrace, so you can't "top it off" by sleeping before it expires
	if CurrentSleepEffect == IndexOfSleepEffectsForWellRestedORLoversEmbrace
		CurrentSleepEffect += 1

		playerRef.removePerk(HC_WellRestedPerk)
		playerRef.removePerk(HC_LoversEmbracePerk)

	endif

	;if you sleep for 7 hours in a bed, you get well rested.
	if GameHoursSpentSleeping >= 7 && SleepingInBed
		trace(self, "    UpdateSleepEffectsAfterSleeping() GameHoursSpentSleeping >= 8 && SleepingInBed, will give well rested or lovers embrace.")

		NewSleepEffect = IndexOfSleepEffectsForWellRestedORLoversEmbrace

		;apply the appropriate perk:
		if Followers.GetNearbyInfatuatedRomanticCompanion()
			playerRef.AddPerk(HC_LoversEmbracePerk)
			LoversEmbraceMessage.Show()
			Game.ShowPerkVaultBoyOnHUD(LoversEmbraceSwfName, UIPerkLoversEmbrace)

		else
			playerRef.AddPerk(HC_WellRestedPerk)
			WellRestedMessage.Show()
			Game.ShowPerkVaultBoyOnHUD(WellRestedSWFname, UIPerkWellRested)

		endif

	endif

	;only set it if it's better than the current effect
	if NewSleepEffect < CurrentSleepEffect
		trace(self, "    UpdateSleepEffectsAfterSleeping() setting HC_SleepEffect to: " + NewSleepEffect)
		PlayerRef.SetValue(HC_SleepEffect, NewSleepEffect)
		CurrentSleepEffect = NewSleepEffect
	else
		trace(self, "    UpdateSleepEffectsAfterSleeping() setting HC_SleepEffect to: " + CurrentSleepEffect)
		PlayerRef.SetValue(HC_SleepEffect, CurrentSleepEffect)
	endif

	if GameHoursSpentSleeping < MinHoursForCuringSleepEffects

		; This means our clock is getting ready to expire	
		if TimeUntilNextSleepUpdate < 1

			; Apply effect to move us down in the tier since our time has expired.
			ApplyEffect(HC_Rule_SleepEffects, SleepEffects, HC_SleepEffect, DispellRestedSpells = true, IncrementEffectBy = 1)
			
			; Store this out to correctly tweak that clock.
			TimeUntilNextSleepUpdate = GameTimerInterval_SleepDeprivation + TimeUntilNextSleepUpdate

		else

			; Don't show the wake message if your in a good state. It hides the fact you're getting worse.
			bool displaySleepMessages = false
			if CurrentSleepEffect > 1
				displaySleepMessages = true
			endif

			; This is a standard post sleep update.  Apply it!
			ApplyEffect(HC_Rule_SleepEffects, SleepEffects, HC_SleepEffect, DispellRestedSpells = true, bDisplayMessage = displaySleepMessages)

		endif

		; Restart our timer taking into account our reduced time since we slept too short of a time.
		StartSleepDeprivationTimer(RestartTimerForThisManyGameHours = TimeUntilNextSleepUpdate, ForceThisExactValue = false)
	
	else

		; This is a standard post sleep update.  Apply it!
		ApplyEffect(HC_Rule_SleepEffects, SleepEffects, HC_SleepEffect, DispellRestedSpells = true, DisplayAfterAwakingMessage = true)
		; Store this update time for handling no effect clearing sleeps.
		LastSleepUpdateDay = utility.GetCurrentGameTime()
		; And restart our timer for the full cycle.
		StartSleepDeprivationTimer()

	endif

EndFunction


bool Function IsSleepingBag(ObjectReference RefToCheck)
	return CommonArrayFunctions.CheckObjectAgainstKeywordArray(RefToCheck, SleepingBagKeywords)
EndFunction

bool Function IsMattress(ObjectReference RefToCheck)
	return CommonArrayFunctions.CheckObjectAgainstKeywordArray(RefToCheck, MattressKeywords)
EndFunction

bool Function IsBed(ObjectReference RefToCheck)
	return CommonArrayFunctions.CheckObjectAgainstKeywordArray(RefToCheck, BedKeywords)
EndFunction

;--------------------------------------------------------------------------------------------------
;------------------------------------    SLEEP EFFECTS -- HEALING    ------------------------------
;--------------------------------------------------------------------------------------------------
;Change how the auto heal works when sleeping. Also see OnPlayerSleepXXX events above.

Group SleepEffectsHealing
ActorValue Property Health const auto mandatory     ;Health
ActorValue Property EnduranceCondition const auto mandatory     ;TORSO
ActorValue Property LeftAttackCondition const auto mandatory    ;LEFT ARM   
ActorValue Property LeftMobilityCondition const auto mandatory  ;LEFT LEG
ActorValue Property PerceptionCondition const auto mandatory    ;HEAD
ActorValue Property RightAttackCondition const auto mandatory   ;RIGHT ARM
ActorValue Property RightMobilityCondition const auto mandatory ;RIGHT ARM
EndGroup


;Pre-sleep cached values
float HealthCache
float EnduranceConditionCache
float LeftAttackConditionCache
float LeftMobilityConditionCache
float PerceptionConditionCache
float RightAttackConditionCache
float RightMobilityConditionCache

Function CacheValuesBeforeSleep()
	HealthCache = PlayerRef.GetValue(Health)
	EnduranceConditionCache = PlayerRef.GetValue(EnduranceCondition)
	LeftAttackConditionCache = PlayerRef.GetValue(LeftAttackCondition)
	LeftMobilityConditionCache = PlayerRef.GetValue(LeftMobilityCondition)
	PerceptionConditionCache = PlayerRef.GetValue(PerceptionCondition)
	RightAttackConditionCache = PlayerRef.GetValue(RightAttackCondition)
	RightMobilityConditionCache = PlayerRef.GetValue(RightMobilityCondition)
EndFunction

Function UpdateHealingAfterSleep(int GameHoursSpentSleeping)

	; GetBaseValue() doesnt get that value with the permenant additions (Life Giver!).
	; But... Sleeping us has healed us to that true max... So let's use that!
	float healthTrueMax        = PlayerRef.GetValue(Health)
	float enduranceTrueMax     = PlayerRef.GetValue(EnduranceCondition)
	float leftAttackTrueMax    = PlayerRef.GetValue(LeftAttackCondition)
	float leftMobilityTrueMax  = PlayerRef.GetValue(LeftMobilityCondition)
	float perceptionTrueMax    = PlayerRef.GetValue(PerceptionCondition)
	float rightAttackTrueMax   = PlayerRef.GetValue(RightAttackCondition)
	float rightMobilityTrueMax = PlayerRef.GetValue(RightMobilityCondition)

	;damage actorvalues back to cached values
	DamageValuesBackToCachedValues() ;*** BETTER HANDLED BY CODE?

	RestoreValueBasedOnHours(Health,                 GameHoursSpentSleeping, healthTrueMax       )
	RestoreValueBasedOnHours(EnduranceCondition,     GameHoursSpentSleeping, enduranceTrueMax    )
	RestoreValueBasedOnHours(LeftAttackCondition,    GameHoursSpentSleeping, leftAttackTrueMax   )
	RestoreValueBasedOnHours(LeftMobilityCondition,  GameHoursSpentSleeping, leftMobilityTrueMax )
	RestoreValueBasedOnHours(PerceptionCondition,    GameHoursSpentSleeping, perceptionTrueMax   )
	RestoreValueBasedOnHours(RightAttackCondition,   GameHoursSpentSleeping, rightAttackTrueMax  )
	RestoreValueBasedOnHours(RightMobilityCondition, GameHoursSpentSleeping, rightMobilityTrueMax)

EndFunction

;***THIS MIGHT BE BETTER HANDLED BY CODE SIMPLY NOT AUTOHEALING IN HARDCORE MODE
Function DamageValuesBackToCachedValues()
	DamageValueBackToCachedValue(Health, HealthCache)
	DamageValueBackToCachedValue(EnduranceCondition, EnduranceConditionCache)
	DamageValueBackToCachedValue(LeftAttackCondition, LeftAttackConditionCache)
	DamageValueBackToCachedValue(LeftMobilityCondition, LeftMobilityConditionCache)
	DamageValueBackToCachedValue(PerceptionCondition, PerceptionConditionCache)
	DamageValueBackToCachedValue(RightAttackCondition, RightAttackConditionCache)
	DamageValueBackToCachedValue(RightMobilityCondition, RightMobilityConditionCache)
EndFunction


Function DamageValueBackToCachedValue(ActorValue ActorValueToDamage, float CachedValue)
	float currentVal = PlayerRef.GetValue(ActorValueToDamage)
	float difference = currentVal - CachedValue
	
	;this shouldn't happen, but just in case, bail out if current value is less than cached value (suggesting some kind of on going effect that's not healed by sleeping)
	if difference <= 0 
		trace(self, "    DamageValueBackToCachedValue() [NO DIFFERENCE - BAILING OUT]: ActorValueToDamage: " + ActorValueToDamage + " - Difference: " + difference + ". currentVal:" + currentVal +  " vs CachedValue: " + CachedValue) 
		RETURN
	endif

	trace(self, "    DamageValueBackToCachedValue() [DIFFERENCE >0 - DAMAGING AV]: ActorValueToDamage: " + ActorValueToDamage + " - Difference: " + difference + ". currentVal:" + currentVal +  " vs CachedValue: " + CachedValue) 
	PlayerRef.DamageValue(ActorValueToDamage, difference)
EndFunction

Function RestoreValueBasedOnHours(ActorValue ActorValueToRestore, int GameHoursSpentSleeping, float TrueMaxValue)
	float valueToRestore   = TrueMaxValue
	int   percentToRestore = 0
	
	;restore a % of max total based on hours slept
	if GameHoursSpentSleeping <= 1
		valueToRestore *= 0.00
		percentToRestore = 0
	elseif GameHoursSpentSleeping == 2
		valueToRestore *= 0.15
		percentToRestore = 15
	elseif GameHoursSpentSleeping == 3
		valueToRestore *= 0.25
		percentToRestore = 25
	elseif GameHoursSpentSleeping == 4
		valueToRestore *= 0.45
		percentToRestore = 45
	elseif GameHoursSpentSleeping == 5
		valueToRestore *= 0.75
		percentToRestore = 75
	else 
		valueToRestore *= 1.00 
		percentToRestore = 100 
	endif

	trace(self, "    RestoreValueBasedOnHours() For " + GameHoursSpentSleeping + " hours slept, restore " + percentToRestore + "% of TrueMaxValue: " + TrueMaxValue + " (valueToRestore: " + valueToRestore + ") to ActorValueToRestore: " + ActorValueToRestore)
	PlayerRef.RestoreValue(ActorValueToRestore, valueToRestore)

EndFunction

;**************************************************************************************************
;***********************************  ENCUMBRANCE AND LIMB CONDITION  *****************************
;**************************************************************************************************

Group EncumbranceAndLimbCondition
	
	globalvariable Property HC_Rule_NoLimbConditionHeal const auto mandatory
	globalvariable Property HC_Rule_DamageWhenEncumbered const auto mandatory

	potion Property HC_EncumbranceEffect_OverEncumbered const auto mandatory

	spell Property HC_ReduceCarryWeightAbility Auto Const Mandatory

EndGroup

Function HandleEncumbranceTimer()
	trace(self, "  HandleEncumbranceTimer()")
	;make the player drink the potion that turns on the encumberance effect (similar to how sleep effects work)
	;spell effects in potion are conditioned on player being encumbered 
	PlayerRef.EquipItem(HC_EncumbranceEffect_OverEncumbered, abSilent = true)
	StartTimerGameTime(GameTimerInterval_Encumbrance, GameTimerID_Encumbrance)
EndFunction 

Function RemoveReduceCarryWeightAbility(actor ActorToRemoveSpellFrom)
	;Remove the ability that reduces carrying capacity (effect in ability is conditioned on HC_Rule_DamageWhenEncumbered)
	if ActorToRemoveSpellFrom && true == ActorToRemoveSpellFrom.HasSpell(HC_ReduceCarryWeightAbility)
		ActorToRemoveSpellFrom.removeSpell(HC_ReduceCarryWeightAbility)
	endif
EndFunction

Function AddReduceCarryWeightAbility(actor ActorToAddSpellTo)
	;Add the ability that reduces carrying capacity (effect in ability is conditioned on HC_Rule_DamageWhenEncumbered)
	if ActorToAddSpellTo && false == ActorToAddSpellTo.HasSpell(HC_ReduceCarryWeightAbility)
		ActorToAddSpellTo.addSpell(HC_ReduceCarryWeightAbility, false)
	endif
EndFunction


;**************************************************************************************************
;***********************************  		 COMPANION HEALING 	  	  *****************************
;**************************************************************************************************

Group CompanionHealing
	GlobalVariable Property HC_Rule_CompanionNoHeal const auto mandatory
	{autofill}

	ReferenceAlias Property Companion const auto mandatory
	{Companion alias on the Followers quest}

	ReferenceAlias Property DogmeatCompanion const auto mandatory
	{DogmeatCompanion alias on the Followers quest}

	float Property DismissIfBleedingOutDistance = 10000.0 const auto
	{this needs to be less than the unload distance
because unloading causes actors to stop bleeing out, even if you SetNoBleedoutRecovery()}

	keyword Property playerCanStimpak auto const mandatory
	{autofill}

	ActorValue Property HC_IsCompanionInNeedOfHealing Auto Const Mandatory
	{autofill; used to manage player leaving companion behind when bleeding out, because going into low clears bleedout state, we need to manage it ourselves}

EndGroup


Event FollowersScript.CompanionChange(FollowersScript akSender, Var[] akArgs)
	Actor ActorThatChanged = akArgs[0] as actor
	bool IsNowCompanion = akArgs[1] as bool

	trace(self, "FollowersScript.CompanionChange() ActorThatChanged: " + ActorThatChanged + ", IsNowCompanion: " + IsNowCompanion)

	CompanionSetNoBleedoutRecovery(ActorThatChanged, IsNowCompanion)
	
	AddReduceCarryWeightAbility(ActorThatChanged)

	;if we are no longer a companion, clear our need for healing
	if false == IsNowCompanion
		SetIsInNeedOfHealing(ActorThatChanged, false)
	endif

EndEvent

bool Function PlayerCanHeal(Actor ActorToHeal)
	trace(self, "PlayerCanHeal() ActorToHeal: " + ActorToHeal)

	trace(self, "PlayerCanHeal() playerCanStimpak: " + playerCanStimpak)

	if ActorToHeal.HasKeyword(playerCanStimpak)
		trace(self, "PlayerCanHeal() TRUE -- ActorToHeal: " + ActorToHeal)
		return true
	endif
	
	trace(self, "PlayerCanHeal() FALSE -- ActorToHeal: " + ActorToHeal)
	return false
EndFunction

bool Function PlayerCanRepair(Actor ActorToHeal)
	;DLC01 keyword used to repair robots
	keyword DLC01PlayerCanRepairKit = Game.GetFormFromFile(0x01004F13, "DLCRobot.esm") as keyword

	if DLC01PlayerCanRepairKit && ActorToHeal.HasKeyword(DLC01PlayerCanRepairKit)
		trace(self, "PlayerCanRepair() TRUE -- ActorToHeal: " + ActorToHeal)
		return true
	endif

	trace(self, "PlayerCanRepair() FALSE -- ActorToHeal: " + ActorToHeal)
	return false

EndFunction

bool Function PlayerCanHealOrRepair(Actor ActorToHeal)

	return PlayerCanHeal(ActorToHeal) || PlayerCanRepair(ActorToHeal)
	
EndFunction

Function CompanionSetNoBleedoutRecovery(Actor CompanionActor, bool ShouldSetNoBleedoutRecovery)
	trace(self, "CompanionSetNoBleedoutRecovery CompanionActor: " + CompanionActor + ", ShouldSetNoBleedoutRecovery: " + ShouldSetNoBleedoutRecovery)

	if ShouldSetNoBleedoutRecovery && IsGlobalTrue(HC_Rule_CompanionNoHeal) 
		if PlayerCanHealOrRepair(CompanionActor)
			trace(self, "  CompanionSetNoBleedoutRecovery calling setNoBleedoutRecovery(true)")
			CompanionActor.SetNoBleedoutRecovery(true)
		else
			trace(self, "  PlayerCanHealOrRepair == false. CompanionSetNoBleedoutRecovery IS NOT calling setNoBleedoutRecovery(true)")
		endif
	else
		trace(self, "  CompanionSetNoBleedoutRecovery calling setNoBleedoutRecovery(false)")
		CompanionActor.SetNoBleedoutRecovery(false)
	endif
EndFunction

Function SetIsInNeedOfHealing(actor ActorToSet, bool IsInNeedOfHealing)
	if IsInNeedOfHealing
		ActorToSet.SetValue(HC_IsCompanionInNeedOfHealing, 1)
	else
		ActorToSet.SetValue(HC_IsCompanionInNeedOfHealing, 0)
	endif
EndFunction

bool Function IsInNeedOfHealing(actor ActorToCheck)
	return ActorToCheck.GetValue(HC_IsCompanionInNeedOfHealing) == 1
EndFunction

Event ReferenceAlias.OnEnterBleedout(ReferenceAlias akSender)
	if IsGlobalTrue(HC_Rule_CompanionNoHeal) == false
		;BAIL OUT, not in hardcore mode
		RETURN
	endif
	trace(self, "ReferenceAlias.OnEnterBleedout() akSender: " + akSender)

	;make sure it's someone the player can heal:
	actor actorRef = akSender.GetActorReference()
	if PlayerCanHealOrRepair(actorRef)
		SetIsInNeedOfHealing(actorRef, true)
		RegisterForDistanceGreaterThanEvent(PlayerRef, akSender, DismissIfBleedingOutDistance) ;for dismissing companion if player gets too far while they are bleeding out
		; Tutorial Call - Downed Companion.
		TryTutorial(CompanionDownedTutorial, "CompanionDownedTutorial")
	endif

EndEvent

Event Actor.OnPlayerHealTeammate(Actor akSender, Actor akTeammate)
	trace(self, "Actor.OnPlayerHealTeammate() akTeammate: " + akTeammate)
    SetIsInNeedOfHealing(akTeammate, false)
EndEvent


Event OnDistanceGreaterThan(ObjectReference akObj1, ObjectReference akObj2, float afDistance)
	trace(self, "OnDistanceGreaterThan() will check for bleedingout and dismiss companion")
	
	;assume this is the companion and player event since that is the only one we registered for
	actor ActorLeftBehind = akObj2 as Actor

	if ActorLeftBehind.isBleedingOut() || IsInNeedOfHealing(ActorLeftBehind) 
		trace(self, "  OnDistanceGreaterThan() bleedingout or IsInNeedOfHealing, will dismiss companion")
		
		if ActorLeftBehind.GetRace() == Game.GetCommonProperties().DogmeatRace
			Followers.DismissDogmeatCompanion(ShowLocationAssignmentListIfAvailable = false)
		else
			Followers.DismissCompanion(ActorLeftBehind, ShowLocationAssignmentListIfAvailable = false)
		endif

		SetIsInNeedOfHealing(ActorLeftBehind, false)
		ActorLeftBehind.EvaluatePackage()
		ActorLeftBehind.MoveToPackageLocation()
	endif

EndEvent

