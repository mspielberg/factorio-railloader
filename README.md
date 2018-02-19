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

Place your rails and train stop first.  The Bulk Rail Loader item
will show a preview of the loader and an image of a cargo wagon, to help
position the loader correctly.  The concrete pad of the Bulk Rail Unloader
serves a similar purpose.

Loaders are circuit-connectable chest entities that output their content.
You can connect them to Logistic Train Network stops to manage automatic
creation of transport orders.  Loaders are not circuit controllable, and
will always load or unload as many items as possible while a cargo wagon
is stopped.

## Boosting Throughput

Rail loaders and unloaders can fit 4 inserters or loaders on each side, for an
inherent 8 belts of throughput.  If this is insufficient, you can add any kind
of 1x1 chests to the corners of the loaders, and they will automatically push or
pull items into these chests.  You can then connect inserters or loaders to the
chests for up to 12 belts of throughput, 6 per side.

![Interface Chest Demo](https://github.com/mspielberg/factorio-railloader/raw/master/resources/interfacechests.jpg)

## What items are supported?

Anything that would tolerate a long drop onto the hard metal floor of a cargo
wagon, then would fit through a metal grate, and would survive a trip up a
[screw conveyor](https://en.wikipedia.org/wiki/Screw_conveyor).

By default, this does not include plates, but a setting is available to enable
them if you wish to abandon realism. You can even enable Bulk Rail Loaders to
handle any item at all.

From vanilla:

* Coal, stone, copper ore, iron ore, uranium ore
* Landfill
* Sulfur

From Bob's mods:

* All ores, including quartz
* Solid chemical intermediates (salt, lithium chloride, etc.)

From Angel's mods:

* All 6 primary ores from Angel's Refining, including refined variants up to
  purified crystals
* Crushed stone and slag waste products from Angel's Refining
* Processed ores from Angel's Smelting
* Solid chemical intermediates from Angel's Petrochem

If you feel something that meets the above generic description is not included,
let me know.  You can also edit `bulk.lua` if you would like to change the set
of supported items for your own use.

## Known Issues

* Loader configuration is not preserved when blueprinted.
* Loader circuit connections are not recreated when building from a blueprint.
* Loader ghosts can be placed in locations they cannot be built, either by
  blueprint or by shift-clicking.  Robots will make repeated trips attempting to
  build the loader until they are successful or the ghost is removed.  This
  allows robots to eventually complete blueprint construction even if they run
  out of rails or similar.  An alert will be added to the map to warn that
  player intervention may be needed to complete construction.

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
    * Fix crash when clicking a single point to create a blueprint.
    * Fix misleading loader placement guide.
    * Shrink placement collision box.
* 0.2.3 (2018-02-02):
    * You must now actually research the technology to unlock rail loaders and unloaders.
    * Fix crash when creating a blueprint with a GUI open in Factorio versions before 0.16.21.
    * Fix crash after mining a loader under certain circumstances.
    * Loaders do not lock in an item if set to accept all items.
* 0.2.4 (2018-02-04):
    * Fix bug building new non-locking loaders.
    * Add partial support for preserving circuit connections in blueprints.
    * Add alert to map when robots cannot build a loader due to missing rails or an obstruction.
* 0.2.5 (2018-02-09):
    * Fix failure to join multiplayer maps with unconfigured loaders present.
    * Fix crash when placing loaders set to "any" item type.
* 0.3.0 (2018-02-13):
    * New feature for increasing throughput: interface chests.
    * Loaders no longer lock onto a single item.  Instead they handle up to 5 item types per cargo wagon.
    * Since this leads to increased message frequency when loaders reconfigure themselves, you can now turn these notifications off.
    * Add support for Omnimatter's omnite ore.
* 0.3.1 (2018-02-14):
    * Fix crash when migrating from a save with unconfigured loaders.
* 0.3.2 (2018-02-14):
    * Fix crash when building on top of modded rails.