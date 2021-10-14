# Vore4Fallout
 Vore and weight gain mod for Fallout 4

Inspired by:
[ColdSteelJ's Weight Gain mod](https://www.deviantart.com/coldsteelj/art/Fallout-4-WeightGain-mod-ssbbw-730902010)
[Carreau & Gat's Fallout Vore](https://aryion.com/forum/viewtopic.php?f=79&t=58266)

## Reasoning
Fallout Vore 3.0 is very hard to install, buggy, and hasn't been updated in some time. Its features are extensive, complicated, and difficult to comprehend in the code. It also conflicts with Coldsteel's weight gain mod, since both mods fight over the same sliders. This is a reimplementation with the goal of being simple, easy to install, and easy to maintain.

## Goal
A simple mod in which your relationship with food is a key element of the gameplay. 

To eat is to exist. In this harsh and radioactive environment your body has undergone a change, and your appetite grown. You find that when you eat, you grow stronger, and larger. Your power waxes and wanes in seasons, sometimes you are slower and hardier, sometimes faster and leaner. You learn to ride these waves and survive.

This mod attempts to make consumption more interesting, with real gameplay impact and fun features. You now have limits on how much food you can eat, and eating lots of food (as you are forced to do early game) will make you fat, and being fat has upsides and downsides. Consumption has RPG elements, benefitting from your S.P.E.C.I.A.L. stats, and offering temporary boosts as well. Your stats will affect how your body shapes up.

Limits spice up gameplay, making stimpaks and other non-fattening health items more precious. Pushing beyond your limits is a fun way to earn boons.

Time is fun. Too fat to walk? Digest while you sleep. Otherwise, you cannot simply pound 10 molerat kebabs while ducking and covering, then pound 10 more 2 minutes later. If you eat yourself into immobility, you'll have to suffer the consequences, or find a clever way out of them.

## Not Included
Frankly, I think most of this stuff should be scoped to companion mods. A great deal of the excessive complexity of both of the inspiration mods is their everything-but-the-kitchen-sink approach. 

* Quests, Books, Items, Weapons
* Male vore
* Atomic Beauty support
* UI widgets
* Configurability
* Companion stuff
* Sound Effects (maybe)
* Non-lethal swallow
* Being a victim of NPC vore

## Sweet Features
* Realistic metabolism
* Complex morphing

## Feature Map
- [x] Belly bloating from food.
- [x] Digestion to calories - Calories are distributed over the weight gain simulation.
- [x] Accelerate metabolism while sleeping
- [x] Belly limit. Overeating damages you, levels up capacity
- [x] Fatness grants damage reduction
- [x] Fatness makes you slower
- [x] Metabolizing fat grants temporary health regeneration
- [x] Weight Gain: Distribute calories to breasts
- [x] Weight Gain: Distribute calories to butt
- [ ] Strength: More damage from stomach acid. Able to swallow prey at higher health percentage
- [ ] Perception: Digest faster and have higher regeneration
- [x] Endurance: More belly capacity
- [x] Charisma: Bigger butt
- [x] Intelligence: Bigger breasts
- [x] Agility: Move faster when fat. Higher metabolism burns fat faster.
- [ ] Luck: Find more food in containers
- [x] Strength Perk: Eating meat (and voring) grants a boon to strength
- [x] Perception Perk: Healthy eating grants a boon to perception.
- [x] Endurance Perk: Overeating grants a boon to Endurance.
- [x] Charisma Perk: Eating fatty food grants a boon to Charisma.
- [x] Intelligence Perk: Eating sugary food grants a boon to Intelligence.
- [x] Agility Perk: Running while fat grants a boon to Agility.
- [ ] Luck Perk: Eating a variety of foods grants a boon to Luck.
- [x] Vore: A 'devour' weapon allows voring NPCs.
- [x] Vore: NPCs go to a 'belly' room where they can damage you, and take damage from your stomach acid.
- [x] Vore: Digesting vore prey transitions smoothly from the lumpy belly to the round belly.
- [x] Belly Inventory: System keeps track of what you're digesting, dropped items.
- [ ] Fast Travel elapsed time is taken into account for digestion/metabolism.

## Camera Fix
As you inevitably become YUGE, you may find you need your camerawoman to stand back a bit. Here's what you can put in `Fallout4.ini`
```ini
[Camera]
f3rdPersonAimFOV=50.0000
fVanityModeMaxDist=700.0000
fVanityModeMinDist=50.0000
fPitchZoomOutMaxDist=200.0000
fMinCurrentZoom=0.0000
fMouseWheelZoomSpeed=2.0000
fMouseWheelZoomIncrement=0.2000
f3rdPersonPowerArmorCameraAdjust=0.0000
fOverShoulderMeleeCombatAddY=0.0000
fOverShoulderMeleeCombatPosZ=30.0000 
fOverShoulderMeleeCombatPosX=0.0000
fOverShoulderCombatAddY=0.0000
fOverShoulderCombatPosZ=30.0000
fOverShoulderCombatPosX=0.0000
fOverShoulderPosZ=20.0000
```

## Vore notes

It seems like the fat loss is happening wrong, where the breasts/butt get preferentially diminished. Need to test more.
Also, perhaps the perk degradation is also way too fast. And most perks should let you over-stack so that you don't immediately fall off of 5* on the first tick down.

Finally, need to ensure that if I run back and forth between two locations, I experience proper perk adjustment, such as earning a lot of agility perk for fast travel.