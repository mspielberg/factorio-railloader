# Bulk Rail Loaders

This mod adds dedicated train loaders and unloaders for granular bulk cargo,
as often used in reality at mines, power stations, etc.  A large hopper placed
directly over the track drops granular solids into the top of a hopper car,
and at the destination the bottom of the car is opened and the cargo pours out
through metal grates and onto conveyors.

Loaders benefit from inserter stack size bonus.  When fully researched they will
fill or empty a cargo wagon in about 5 seconds.

![Bulk Rail Loaders in action](https://github.com/mspielberg/factorio-railloader/raw/master/resources/snapshot.jpg)

The Bulk Rail Loader and Unloader items will show a preview of the loader and
an image of a cargo wagon, to help position the loader correctly. The
concrete pad of the Bulk Rail Unloader serves a similar purpose.

Note that rails are placed every other tile, but cargo wagons in stations
stop every 7 tiles. Depending on the exact loader placement, it may appear
with two or three rail segments underneath. You cannot place a BRL if it
could not align with other rails.

BRLs are circuit-connectable chest entities that output their content. You
can connect them to Logistic Train Network stops to manage automatic creation
of transport orders. Sending a BRL the special "Disable rail loader" signal
will stop the BRL from loading/unloading a cargo wagon. Due to their speed,
you are likely to load or unload a few more items than expected.

This mod should be considered __ALPHA__ quality.  Expect bugs, and please report
any you find to the mod thread.

## Boosting Throughput with Interface Chests

Rail loaders and unloaders can fit 4 inserters or loaders on each side, for
an inherent 8 belts of throughput. If this is insufficient, you can add up to
4 chests to the corners of the loaders, and they will automatically push or
pull items into these chests. I recommend limiting these chests to just a few
stacks to prevent them from getting too out of balance.

With vanilla 1x1 chests, this system allows up to 12 belts of throughput, 6
per side. However, chests can be of any size. Interface chests can also be
logistics chests, if you wish to directly connect your bulk rail loaders to
your logistics network.

![Interface Chest Demo](https://github.com/mspielberg/factorio-railloader/raw/master/resources/interfacechests.jpg)

## What items are supported?

Anything that would tolerate a long drop onto the hard metal floor of a cargo
wagon, then would fit through a metal grate, and would survive a trip up a
[screw conveyor](https://en.wikipedia.org/wiki/Screw_conveyor).

By default, this does not include plates, but a setting is available to enable
them if you wish to abandon realism. You can even enable Bulk Rail Loaders to
handle any item at all.

From base:

* Coal, stone, copper ore, iron ore, uranium ore
* Landfill
* Plastic (realistically these are likely pellets, not shaped bars)
* Sulfur

From Bob's mods:

* All ores, including quartz
* Solid chemical intermediates (salt, lithium chloride, etc.)

From Angel's mods:

* All 6 primary ores from Angel's Refining, including refined variants up to
  purified crystals
* Geodes, crushed stone and slag waste products from Angel's Refining
* Processed ores from Angel's Smelting
* Solid chemical intermediates from Angel's Petrochem

From MadClown's Extended AngelBob Minerals:

* Additional ores and refined variants

From Omnimatter:

* Omnite ore

From Pynandon's mods:

* A huge variety of organics, stone, and chemical intermediates from Pyanodons
  Coal Processing

If you feel something that meets the above generic description is not included,
let me know.  You can also edit `bulk.lua` if you would like to change the set
of supported items for your own use.

## Known Issues

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
* 0.3.3 (2018-02-19):
    * Fix crash when build conditions are not met (colliding entities, rail not present).
    * Add support for Pyanodons Coal Processing.
* 0.3.4 (2018-02-23):
    * Fix configuration on train arrival.
* 0.3.5 (2018-02-23):
    * Prevent loaders from being built when there is only one rail underneath, which could block connecting rails from being built, particularly when building a blueprint.
    * Prevent loaders from being built over curved rails, which leads to odd "train driving through a wall" appearance.
    * Give better messages when a loader can't be built.
    * Prevent rails blocked by loaders from being damaged, destroyed, or mined, since they cannot be replaced without removing the loader.
* 0.3.6 (2018-03-16):
    * Change how graphics are rendered.
    * Fix crash on mining BRLs in Factorio 0.16.29.
* 0.3.7 (2018-03-19):
    * Revise unloader graphics.
    * Improve handling of blueprint circuit connections.
    * Improve Bluebuild compatibility.
    * Marking a BRL for deconstruction also marks the underlying rails.
    * Add support for interface chests of any size.
* 0.3.8 (2018-03-31):
    * Add support for plastic bars, Angel's geodes, and MadClown's Extended Minerals.
    * Fix a rare migration bug from early BRL versions.
* 0.4.0 (2018-04-04):
    * Major change: BRLs are now placed independently, instead of on top of existing rails.
    * A best-effort is made to update blueprints in characters inventories, chests, blueprint books, etc.  You will have to re-create any blueprints exported to your library.
    * Fix use of logistics chests as interface chests.
* 0.4.1 (2018-04-09):
    * Fix crash when marking BRLs for deconstruction.
* 0.4.2 (2018-04-12):
    * Fix rare crash related to on_nth_tick() processing.
* 0.4.3 (2018-04-30):
    * Update bulk materials list for PyIndustry mods.
    * Add workaround for Creative Mode's Instant Deconstruction.
* 0.5.0 (2018-08-06):
    * Add circuit control via virtual signal.
    * Replace technology icon.
* 0.5.1 (2018-08-26):
    * Fix crash experienced with PickerTweaks.
    * Add compatibility recipe for xander-mod.
* 0.5.2 (2018-10-14):
    * Interface chest transfer is now stopped when the "Disable rail loader" signal is sent.
* 0.5.3 (2018-10-15):
    * Fix crash bug on building BRL.
* 0.5.4 (2018-10-17):
    * Fix crash bug on changing permitted items setting on an existing map.