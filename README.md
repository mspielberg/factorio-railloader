# Bulk Rail Loaders

This mod adds dedicated train loaders and unloaders for granular bulk cargo,
as often used in reality at mines, power stations, etc.  A large hopper placed
directly over the track drops granular solids into the top of a hopper car,
and at the destination the bottom of the car is opened and the cargo pours out
through metal grates and onto conveyors.

![Bulk Rail Loaders in action](https://github.com/mspielberg/factorio-railloader/raw/master/demo.mp4)

Graphics are placeholder.  If you would like to make pretty graphics, or know
someone who would like to, see my
[request thread](https://forums.factorio.com/viewtopic.php?f=15&t=56820).

This mod should be considered __ALPHA__ quality.  Expect bugs, and please report
any you find to the mod thread.

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
them if you wish, or even to enable Bulk Rail Loaders to handle any item at all.

From vanilla:

* Mined coal, stone, copper ore, iron ore
* Landfill
* Sulfur

From Bob's mods:

* All ores, including quartz

From Angel's mods:

* All 6 primary ores from Angel's Refining, including processed variants up to
  purified crystals
* A variety of solid chemical intermediates from Angel's Petrochem.

If you feel something that meets the above generic description is not included,
let me know.  You can also edit `bulk.lua` if you would like to change the set
of supported items for your own use.

## Known Issues

* Loader configuration is not preserved when blueprinted.
* Loader circuit connections are not recreated when building from a blueprint.

## Version History
* 0.1.0 (2018-01-20):
    * Initial preview release.