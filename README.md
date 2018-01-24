# Bulk Rail Loaders

This mod adds dedicated train loaders and unloaders for granular bulk cargo,
as often used in reality at mines, power stations, etc.  A large hopper placed
directly over the track drops granular solids into the top of a hopper car,
and at the destination the bottom of the car is opened and the cargo pours out
through metal grates and onto conveyors.

Loaders benefit from inserter stack size bonus.  When fully researched they will
fill or empty a cargo wagon in about 5 seconds.

![Bulk Rail Loaders in action](https://github.com/mspielberg/factorio-railloader/raw/master/resources/snapshot.jpg)

This mod should be considered __ALPHA__ quality.  Expect bugs, and please report
any you find to the mod thread. Graphics are placeholder.
If you would like to make pretty graphics, or know someone who would like to, see
my [request thread](https://forums.factorio.com/viewtopic.php?f=15&t=56820).

## How to use

Place your rails and train stop first.  The Bulk Rail Loader and Unloader items
will show a preview of the (un)loader and an image of a cargo wagon, to help
position the loader correctly.

The loader locks in the first item it sees of a supported type.  If you want to
change what item a loader is handling, mine and rebuild it.  Loaders are
circuit-connectable chest entities, ready for use with Logistic Train Network.

## What items are supported?

Anything that would tolerate a long drop onto the hard metal floor of a cargo
wagon, then would fit through a metal grate, and would survive a trip up a
[screw conveyor](https://en.wikipedia.org/wiki/Screw_conveyor).

By default, this does not include plates, but a setting is available to enable
them if you wish to abandon realism. You can even enable Bulk Rail Loaders to
handle any item at all.

From vanilla:

* Coal, stone, copper ore, iron ore
* Landfill
* Sulfur

From Bob's mods:

* All ores, including quartz
* Solid chemical intermediates (salt, lithium chloride, etc.)

From Angel's mods:

* All 6 primary ores from Angel's Refining, including refined variants up to
  purified crystals
* Processed ores from Angel's Smelting
* Solid chemical intermediates from Angel's Petrochem

If you feel something that meets the above generic description is not included,
let me know.  You can also edit `bulk.lua` if you would like to change the set
of supported items for your own use.

## Known Issues

* Loaders cannot be selected with the pipette tool (`Q` by default), but they
  can be blueprinted.
* Loader configuration is not preserved when blueprinted.
* Loader circuit connections are not recreated when building from a blueprint.
* Loader ghosts can be placed in locations they cannot be built, either by
  blueprint or by shift-clicking.  Robots will make repeated trips attempting to
  build the loader until they are successful or the ghost is removed.  This
  allows robots to eventually complete blueprint construction even if they run
  out of rails or similar.

## Acknowledgements

* Arch666Angel for the loader graphics.

## Version History
* 0.1.0 (2018-01-20):
  * Initial preview release.
* 0.2.0 (2018-01-21):
  * Add improved graphics.
  * Fix some blueprinting crashes.
  * Improve robot handling when trying to build a loader before the rails are
    built.
  * Use flying-text instead of console notifications when inserters lock in an
    item.
* 0.2.1 (2018-01-21):
  * Fix bad migration.
* 0.2.2 (2018-01-23):
  * Enable walking and driving vehicles through loaders.
  * Enable using the pipette feature (Q) with loaders.
  * Fix misleading loader placement guide in vertical orientation.