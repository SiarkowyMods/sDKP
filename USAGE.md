# Usage

This file serves as the complete usage manual for sDKP.

## Awarding and charging

Let's recall the quintessential syntax of modifying player's DKP.

### Award

```
/sdkp award Player 50
```

Awards Player 50 DKP and stores data to officer note immediately.

### Charge

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

Awards all raid members 15 DKP with reason and public announce.

> **Note:** `all` matches players in groups 1—8.

### General syntax

These commands have the following usage:

```
/sdkp award|charge[!] <character filter> <points>[ <reason>[ @<channel>]]
```

> **Note:** `<...>` stands for a parameter. `[...]` means an optional part which may be freely omitted. Vertical bar `|` separaters alternatives, so only one option should be used at a time.

* You may use item links as the reason.
* Both of the above commands immediately store changes to officer notes.
* For explanation of `@channel` parameter, consult the *Output redirection* paragraph below.

---

## Character filters

The `<character filter>` parameter is used in numerous commands. It describes the subject
of DKP operations. This is the complete list of available filters with alternate forms in braces.

| Filter | Meaning |
| --- | --- |
| `<name>` | filter by character name (case sensitive) |
| `raid` | raid members **in groups 1—5** |
| `all` | raid members **in groups 1—8** and **standby players** |
| `standby` | raid members **in groups 6—8** and players **on the standby list** out of the raid |
| `party1` through `party8` (`pt1` through `pt8`) | members of specified raid subgroup |
| `party` | your party members |
| `ironman` | iron man eligible players |
| `druids`, `hunters`, `mages`, ... | class members |
| `main` (`mains`) | mains |
| `alt` (`alts`) | alts |
| `zone` | characters in your current zone |
| `otherzone` | characters outside your zone |
| `guild ` | all guild members |
| `officer` (`officers`) | officers |
| `online` | online characters |

> **Note:** In contrast to QDKP's behaviour, sDKP does not distinguish between online/offline players by default.
> You have to use the `online` filter explicitly if only online characters should be matched.

You may combine multiple qualifiers to obtain particular lists of characters.
This can be done by separating filters in two ways:

* by comma — means logic `OR`, so *any* condition can match a character
* by space — means logic `AND`, so *each* condition should match a character

You can even mix both. Look at the examples:

| Filter | Meaning |
| --- | --- |
| `Steven, Helen, Jack` | any character with specified name |
| `party5 warlocks` | warlocks in subgroup no 5 |
| `raid main druids` |  main druids in the raid |
| `party2 mages, raid hunters, Jeff` | raid mages in subgroup no 2, hunters in the raid or character named Jeff |

> **Note:** Take a look at the following filter, which illustrates the difference
> between space and comma:
> ```
> Steven Helen Jack
> ```
> Such filter returns no characters because a character can only have one name at a time.

Example usage with DKP awarding:

```
/sdkp award! party2 mages, raid hunters, Jeff 25 nice job
```

---

## Output redirection

Some commands allow channel redirection by appending `@channel` sequence.

```
 /sdkp info Tom @officer
```

Available channels are:

```
@guild      @officer    @party      @raid       @raid_warning
@say        @yell       @<player>   @<channel>
```

You have to join the channel before using `@<channel>`, for example `@mychannel`.
If the specified channel is not found, the string is interpreted as a player
name and whisper is sent, for example `@Jack`.

---

## Modification without saving to notes

You can modify DKP without immediately storing it to officer notes.
Such local changes stay in the roster data until explicitly stored to notes or discarded.

```
/sdkp modify <filter> <net change> [<total change> [<hours change>]]

/sdkp modify Kate 5         # increase Kate's net by 5
/sdkp modify party2 0 -10   # decrease party 2 members' total by 10
```
Changes DKP of selected player(s) as relative values.

```
/sdkp pending
```
Displays pending (unsaved) changes to officer notes.

```
/sdkp store
```
Stores pending changes to officer notes.

```
/sdkp discard
```
Discards all unsaved roster changes.

---

## Other core commands

```
/sdkp set <player> <net> [<total> [<hrs>]]
```
Sets fixed player DKP amounts and stores them immediately to officer note.

```
/sdkp info <player>
```
Prints DKP info for given player.

```
/sdkp invite [<filter>]
```
Invites selected players into the raid group. By default matches any online characters.

```
/sdkp usage
```
Prints some help about usage strings.

```
/sdkp versions
```
Prints out guild mates' addon versions.

---

## Alts management

Alternate character related functions can be accessed with `/sdkp alt`.

```
/sdkp alt set <alt> <main>
```
Sets alt status for specified character.

```
/sdkp alt clear <character>
```
Clears character's alt status.

```
/sdkp alt swap <oldmain> <newmain>
```
Swaps player's main, updating alternative characters' officer notes.

---

## Aliases

Aliases are a way of binding out of guild characters with their guild characters.
Aliasing functions are grouped under `/sdkp alias`.

```
/sdkp alias set <alias> <main>
```
Sets alias character for specified main. This will affect only out of guild characters.

```
/sdkp alias clear <alias>
```
Clears alias status from character.

```
/sdkp alias list
```
Lists saved aliases to chat frame.

```
/sdkp alias unbound
```
Displays raid members not bound to any guild character.

---

## Backups

Backup module provides functionality dedicated for creating, restoring, comparing
and deleting officer note backups. It requires the sDKP Backups addon to be enabled.

```
/sdkp backup create
```
Saves a new officer note backup.

```
/sdkp backup restore <timestamp>
```
Loads specified backup to officer notes.

> **Note:** `<timestamp>` parameters is in the form of `YYYYmmddHHMMSS`, eg. `20100815141533`.

```
/sdkp backup revert <player> <timestamp>
```
Reverts player's DKP from specified backup.

```
/sdkp backup list [<guild>]
```
Lists all saved backups. Guild name parameter is optional.

```
/sdkp backup diff <timestamp>
```
Shows differences between backup's and current roster DKP.

```
/sdkp backup delete <timestamp>
```
Deletes backup specified by timestamp.

---

## Iron man

sDKP has built-in iron man support. These commands are used for flagging players
eligible for iron man bonus.

> **Note:** Iron man flag is set for the main character
> (which applies later to alts) and won't be cleared unless
> `/sdkp ironman clear` or `/sdkp ironman start` is issued.

```
/sdkp ironman start [<filter>]
```
Saves entire raid (groups 1-8) or selected players (if specified) for iron man
bonus. Clears previously stored iron man data.

```
/sdkp ironman clear
```
Cancels entirely iron man bonus awarding no DKP.

```
/sdkp ironman add <filter>
```
Adds selected players to the iron man list. Does not clear any iron man data.

```
/sdkp ironman remove <filter>
```
Removes selected players from iron man list.

```
/sdkp ironman list
```
Lists players eligible for iron man bonus.

```
/sdkp ironman reinvite
```
Reinvites iron man eligible players who remain online out of raid.

```
/sdkp award! ironman 50
```
Use this example to award players the iron man bonus.

---

## Logs management `/sdkp log ...`

All DKP operations are stored in the account-wide per-guild log. Same applies
to loot above specified threshold (epic by default). To manage the log, use
commands under `/sdkp log`.

> The guild for logging purposes is your character's current guild,
> not the player being logged.

```
/sdkp log search <query>[, ...] [[from<]time[<to]] [#<guild>] [@<channel>]
```
Shows all entries matching given string(s). You may optionally provide a guild
name to use instead of the current one or when your character is out of guild.
You may also look in all guilds' logs with `#all` or in out-of-guild logs with
`#_`.

```
/sdkp log search! [...]
```
A shorthand for `/sdkp log search [...] #all` to search in any guild.

```
/sdkp log search time>8h (changes newer than 8 hours ago)

/sdkp log search Jeff time>201406

/sdkp log search Helen, Jack time<2010

/sdkp log search Badge of Justice 201206<time<201207
```
Search query in `/sdkp log search` can be a character name, part of reason
or an item name. All log entries are matched against specified pattern and
shown if positive. You can also provide multiple patterns by separating them
with comma character. The entry will be shown if any of the patterns matches.
Example: `/sdkp log search Jeff, Helen, Jack`.

The `time` parameter allows specifying the searching period. Its
argument has the form of `YYYYMMDD` (absolute) or `3d20h` (relative,
3d20h ago). Examples of valid timestamps:
`20140211`, `201302`, `2010`, `3M` (months), `7d`, `8h30m`.

```
/sdkp log purge [<timestamp>]
```
Deletes log entries for current guild older  than specified or at least 4 weeks 
old if no parameter given.

```
/sdkp log dump [#<guild>]
```
Prints all entries from log into the chat frame.

---

## Standby `/sdkp standby ...`

Standby flagging is similar to the functionality of iron man bonus. Its main
goal is to keep standby players out of raid when they do not participate in it
actively.

> Contrary to iron man bonus, standby flags are kept per character!

```
/sdkp standby start [<filter>]
```
Adds entire raid (groups 1-8) or selected players only to standby list.
Clears previously stored standby data.

```
/sdkp standby clear
```
Clears standby data from guild roster.

```
/sdkp standby add <filter>
```
Adds selected players to standby list.

```
/sdkp standby remove <filter>
```
Removes selected players from standby list.

```
/sdkp standby list
```
Prints standby list to chat frame.

```
/sdkp standby uninvite
```
Uninvites standby players (groups 6-8) from raid.

```
/sdkp standby reinvite
```
Reinvites online standby players to raid. This sends invites to player's
online character.

---

## Statistics `/sdkp stat ...`

Statistics commands require sDKP Stat addon enabled. All ranges are evaluated
as weak inequalities (`parameter >= value` and `parameter <= value`).

```
/sdkp who params
```
Who-like utility for guild.

| Param | Meaning |
| --- | --- |
| `n-Name` | name lookup |
| `c-Class` | class lookup |
| `z-Zone` | zone lookup |
| `N-PlayerNote` | player note match |
| `O-OfficerNote` | officer note match |
| `R-RankName` | rank name match |
| `lvl-L lvl<M lvl>m m<lvl<M` | specified level or level range |
| `rank-R rank<M rank>m m<rank<M` | specified rank ID or rank range |
| `net<M net>m m<net<M` | net DKP range |
| `tot<M tot>m m<tot<M` | total DKP range |
| `hrs<M hrs>m m<hrs<M` | hour counter range |
| `online` | online players only |
| `raid` | raid members only |
| `main alt` | character status filter |

You may combine multiple search conditions
by listing them separated with spaces.

```
/sdkp who online net>200 800<tot<1200
```
Online players with more than 200 net DKP
and total DKP between 800 and 1200.

```
/sdkp who raid N-H
```
Raid healers (assuming H in player note means that player is a healer).

```
/sdkp who O-Net:%- c-warlock
```
Warlocks with negative net DKP values (greetings to Nevendar).
Note you need to escape the second minus sign with `%`.

```
/sdkp stat class
```
Displays class breakdown.

```
/sdkp stat guild
```
Displays overall player, main and alt counts.

```
/sdkp stat level
```
Displays level breakdown.

```
/sdkp stat rank
```
Displays rank breakdown.

```
/sdkp stat spec
```
Displays specialization breakdown. Specialization data is loaded from player
note data and has to be stored between square braces `[spec]`. Recognized
specialization symbols include:

| Symbol | Meaning |
| --- | --- |
| `[D]` | melee DPS |
| `[H]` | healer |
| `[L]` | leveling |
| `[RD]` | ranged dps |
| `[T]` | tank |

```
/sdkp stat spent
```
Displays spent DKP ranking.

```
/sdkp stat top [<count>] [<filter>]
```
Displays net DKP ranking for selected players or all guild mains if not
specified.

```
/sdkp stat total [<count>]
```
Displays total DKP ranking.

```
/sdkp stat zone
```
Displays zone breakdown.

---

## Options `/sdkp option ...`

A few settings of sDKP can be adjusted with option management commands.

```
/sdkp option binding off|on
```
Toggles creating character aliases through `?bind` command. On by default.

> If the option is enabled, out of guild characters that are with you
> in the raid group can bind themselves to their main character to get DKP.
> By sending the `?bind <main> <net_dkp>` whisper, the sender will be marked
> as an alt of his main if the net DKP amount matches the actual value.

```
/sdkp option dkpformat <format>
```
Sets DKP format for officer notes. This decides what goes between curly
braces in officer notes. By default, sDKP uses QDKP compatible format of
`Net:%n Tot:%t Hrs:%h`. As you can see, there are some special placeholders
for player data. These are:

| Symbol | Meaning |
| --- | --- |
| `%n` | net DKP |
| `%t` | total DKP |
| `%h` | hour counter |
| `%d` | current day |
| `%m` | current month |
| `%d.%m`| standard date |

You may consider using `Net:%n Tot:%t %d.%m` format instead of the default
one so you know when the player last attended a raid. The `Hrs:%h` part is
not required to maintain QDKP compatibility.

```
/sdkp option ignoreginfo off|on
```
Toggles ignoring of guild info DKP note format. Off by default.

> You may specify the DKP note format for sDKP in guild info message so that
> all officers share the same format. Just use the following string:
> `{dkp:FORMAT}` where `FORMAT` is the same as in `/sdkp option dkpformat`,
> e.g. `{dkp:Net:%n Tot:%t %d.%m}`.
> This option comes handy if you don't want to synchronize note format from
guild info.

```
/sdkp option verbosediff off|on
```
Specifies whether to print chat notifications on DKP changes. On by default.

```
/sdkp option whispers off|on
```
Toggles whisper announces of DKP changes made by you. On by default.
