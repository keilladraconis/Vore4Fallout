# Vore4Fallout
 Vore mod for Fallout 4

Inspired by:
[ColdSteelJ's Weight Gain mod](https://www.deviantart.com/coldsteelj/art/Fallout-4-WeightGain-mod-ssbbw-730902010)
[Carreau & Gat's Fallout Vore](https://aryion.com/forum/viewtopic.php?f=79&t=58266)

## Reasoning
Fallout Vore 3.0 is very hard to install, buggy, and hasn't been updated in some time. Its features are extensive, complicated, and difficult to comprehend in the code. It also conflicts with Coldsteel's weight gain mod, since both mods fight over the same sliders. This is a reimplementation with the goal of being simple, easy to install, and easy to maintain.

## Goal
Make consumption more interesting, with real gameplay impact and fun features. You now have limits on how much food you can eat, and eating lots of food (as you are force to do early game) will make you fat, and being fat has upsides and downsides. Consumption has RPG elements, benefitting from your S.P.E.C.I.A.L. stats, and offering temporary boosts as well. Your stats will affect how your body shapes up.

Limits spice up gameplay, making stimpaks and other non-fattening health items more precious. Pushing beyond your limits is a fun way to earn boons.

Time is fun. Beds and sleeping have an actual purpose other than advancing the clock; you metabolize 2x faster while sleeping or resting. Otherwise, you cannot simply pound 10 molerat kebabs while ducking and covering, then pound 10 more 2 minutes later. If you eat yourself into immobility, you'll have to suffer the consequences, or find a clever way out of them.

## Not Included
Frankly, I think most of this stuff should be scoped to companion mods. A great deal of the excessive complexity of both of the inspiration mods is their everything-but-the-kitchen-sink approach. 

* Quests, Books, Items, Weapons
* Male vore
* Atomic Beauty support
* UI widgets
* Configurability
* Companion stuff
* Sound Effects
* Non-lethal swallow
* Player Vore

## Sweet Features
* Realistic metabolism
* Complex morphing

## Feature Map
- [x] Belly bloating from food.
- [x] Digestion to calories - Calories are distributed over the weight gain simulation.
- [x] Accelerate metabolism while sleeping
- [ ] Accelerate metabolism after running
- [x] Belly limit. Overeating damages you, levels up capacity
- [ ] Fatness grants damage reduction
- [ ] Fatness makes you slower
- [x] Metabolizing fat grants temporary health regeneration
- [x] Weight Gain: Distribute calories to breasts
- [x] Weight Gain: Distribute calories to butt
- [ ] Strength: More damage from stomach acid. More muscle growth.
- [ ] Perception: Digest faster and have higher regeneration
- [x] Endurance: More belly capacity
- [x] Charisma: Bigger butt
- [x] Intelligence: Bigger breasts
- [ ] Agility: Move faster when fat. Higher metabolism burns fat faster.
- [ ] Luck: Find more food in containers
- [x] Strength Perk: Eating meat (and voring) grants a boon to strength
- [ ] Perception Perk: Healthy eating grants a boon to perception.
- [x] Endurance Perk: Overeating grants a boon to Endurance.
- [x] Charisma Perk: Eating fatty food grants a boon to Charisma.
- [x] Intelligence Perk: Eating sugary food grants a boon to Intelligence.
- [ ] Agility Perk: Running while fat grants a boon to Agility.
- [ ] Luck Perk: Eating a variety of foods grants a boon to Luck.
- [ ] Vore: A 'devour' weapon allows voring NPCs.
- [ ] Vore: NPCs go to a 'belly' room where they can damage you, and take damage from your stomach acid.
- [ ] Vore: Digesting vore prey transitions smoothly from the lumpy belly to the round belly.
- [ ] Belly Inventory: System keeps track of what you're digesting, dropped items.
- [ ] Vomit belly inventory: Use a consumable to vomit up a container with all the enemies' loot.

## Vore notes

A 'Swallow' unarmed weapon is given to the player. Base it off some player unarmed weapon so it has the right stuff to work and animate.
It applies an enchantment.

The swallow enchantment is type enchantment, with a magic effect 'lethal swallow'. Its duration is 5 seconds.

The swallow magic effect is a FoF 'Script' archetype, with contact delivery. It has an attached script
It's got some conditions. Target doesn't have the ActorTypeChild keyword, AND not the 'isVertibird' keyword. AND Also, that target isBlocking NONE

OnEffectStart The attached script rolls some dice. Interestingly, it is supposed to block some races that cause crashes, but the formlist is empty.

The script uses `akTarget.MoveTo(FV_StomachCellMarker)`, which is a marker in the stomach cell, which is a room that acts as the player's stomach. That room has a chest in it which acts as a repository for items from digested prey. 

There are a lot of checks in the script, such as ensuring the player's stomach isn't full and so on. Only when all the checks pass does it move the prey, then it calls the consumptionregistry to inform it of the vore event.

Now, the consumption registry is a very complicated thing that handles the digestion damage of live prey, disposal of dead prey, vomiting of live prey who struggle their way out, and so forth. It also collects the inventory of digested prey.

Interestingly, it puts the prey in a buffer.

It ends up using CallFunctionNoWait to async the rest of the consumption registry stuff.

So the buffer is used because of how magiceffects work, and how you could be swallowing a bunch of things and triggering scripts concurrently. So the point of the async function is to lock and serialize these async swallows.

So each swallowed prey takes a turn going through the globally locked ProcessSingleSwallow function. It even checks to deduplicate the prey, because I suppose repeated attempts to ingest the same prey would put them into the buffer multiple times.

Even after all the previous checks, there can still be rejections at this stage.

A custom event is even fired, "OnSwallow". 

Then it hands off to "PerformVoreEventAccept", which adds the prey to the prey array with `InsertIntoBuffer`. 

If the prey was already dead, it just starts digestion.
Finally a timer is started to do prey digestion damage. The timer ID is the vore index of the prey.

As soon as the timer is entered, the `OnTimerState` is activated, acting as a lock so that when multiple timers fire the other ones just delay themselves by a quarter second. (Apparently this is annoying with the sounds)

So once the other timers are dealt with the `GetPreyAndPredFromIndex` is called with the timer id (prey index), and if we got a hit, it goes through this extensive process of playing sounds and updating timer states and fullness levels and on and on and on.

The actual work happens whiel the timerstate is 100, and `OnTimerDecreaseTicks` is called. Deep inside there, `DamageDealt` is calculated. It either kills the prey if the damage exceeds their remaining health, or damages their health AV by that amount. If the prey is dead then, it calls `OnTimerPerformDigestion`, otherwise it restarts the timer for another round.

Now, with `OnTimerPerformDigestion`, another custom event is used, `OnDigest`, and passed the pred, prey, and belly container. Some cleanup happens. Vore XP is handed out. `currentPrey.RemoveAllItems(FV_BellyContainer)` is used to empty out the prey's inventory, that's cool. There's also some reason where the prey is moved back to its spawn for cell reset... `currentPrey.MoveToMyEditorLocation()` but after setting critical stage 4, who knows what that is. Possibly the ash/goo vaporized state.