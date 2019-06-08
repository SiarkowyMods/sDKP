# sDKP

sDKP stands for Siarkowy's Dragon Kill Points manager for World of Warcraft
and is an entirely slash command driven DKP manager compatible with QDKPv2
on the level of officer note data storage. Despite sDKP being only usable by
means of slash commands, the syntax is quite easy, yet potent.

Let's begin with `/sdkp` command. You may also use the abbreviation `/dkp` — the choice is up to you!

## Quick introduction

You will be using these commands quite often. This is the basic awarding/charging syntax.

### Awarding

```
/sdkp award Player 50
```

Awards Player 50 DKP and stores data to officer note immediately.

### Charging

```
/sdkp charge Player 25
```

Charges Player 25 DKP and updates the officer note.

### Specifying reason

```
/sdkp award raid 30 Kael'thas
```

Awards the raid 30 DKP with reason, stored in the operation log.

> **Note:** `raid` stands for players in groups 1—5 only, whereas `all` matches groups 1—8.

### Public announce

```
/sdkp charge! Player 10 buffs
```

Charges Player 10 DKP with reason and public announce (enabled by exclamation mark).


> **Note:** The channel will be chosen automatically from raid warning, raid and guild channels.

### Combining it together

```
/sdkp award! all 15 iron man
```

Awards groups 1—8 15 DKP with reason and public announce.

Proceed to [Usage](USAGE.md) to see the complete list of slash commands.

## Installation

* Download sDKP using the `Download ZIP` button on the right (or by cloning the repository using `Git`).
* Open the ZIP file and copy contents of `sDKP-master` folder to your `Wow\Interface\AddOns` directory.
* Restart the game client, log into the game and ensure that sDKP is present on the addon list.
