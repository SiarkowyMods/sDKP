sDKP
====

sDKP stands for Siarkowy's Dragon Kill Points manager for World of Warcraft
and is an entirely slash command driven DKP manager compatible with QDKPv2
on the level of officer note data storage. Despite sDKP being only usable by
means of slash commands, the syntax is quite easy, yet potent.

Let's begin with `/sdkp` command. You may also use the abbreviation `/dkp` — the choice is up to you!

Quintessential syntax
---------------------

You will be using these commands quite often. This is the basic awarding/charging syntax.

* `/sdkp aawrd Steven 50` — awards Steven 50 DKP and stores data to officer note.
* `/sdkp charge Helen 25` — charges Helen 25 DKP (same as above).
* `/sdkp award raid 30 Kael'thas` — awards the raid (groups 1-5 only!) 30 DKP with reason (stored in the operation log).
* `/sdkp charge! Jeff 10 buffs` — charges Jeff 10 DKP with reason and public announce to proper channel.
* `/sdkp award! all 15 iron man` — awards the raid (group 1-8) 15 DKP with reason and announce.

Let's proceed to [Usage](USAGE.md) to see the complete list of slash commands.

Installation
------------

* Download sDKP using the `Download ZIP` button on the right (or by cloning the repository using `Git`).
* Open the ZIP file and copy contents of `sDKP-master` folder to your `Wow\Interface\AddOns` directory.
* Restart the game client, log into the game and ensure that sDKP is present on the addon list.
