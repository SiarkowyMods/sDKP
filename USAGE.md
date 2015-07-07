Usage
=====

This file serves as the complete usage manual for sDKP.

Awarding and charging
---------------------

Let's recall the quintessential syntax of modifying player's DKP.

* `/sdkp award Steven 50` — Awards Steven 50 DKP and stores data to officer note.
* `/sdkp charge Helen 25` — Charges Helen 25 DKP (same as above).
* `/sdkp award raid 30 Kael'thas` — Awards the raid (groups 1-5 only!) 30 DKP
  with reason (stored in the operation log).
* `/sdkp charge! Jeff 10 buffs` — Charges Jeff 10 DKP with reason and public
  announce to proper channel.
* `/sdkp award! all 15 iron man` — Awards the raid (group 1-8) 15 DKP
  with reason and announce.

These commands have the following usage:

* `/sdkp award <filter> <points>[ <reason>]`
  — Awards players specified amount of DKP with optional reason.
* `/sdkp award! <filter> <points>[ <reason>[ @<channel>]]`
  — Same as above but with public announce.
* `/sdkp charge <filter> <points>[ <reason>]`
  — Charges players specified amount of DKP with optional reason.
* `/sdkp charge! <filter> <points>[ <reason>[ @<channel>]]`
  — Analogously to `/sdkp award!`, with public announce.

Both above commands immediately store changes to officer notes. You may use item
links as reason. For explanation of `@channel` parameter, consult the Output
redirection paragraph below.

Filters
-------

The `<filter>` parameter is used in numerous commands. It describes the subject
of DKP operations.

List of available qualifiers (alternate form in braces):

* `<name>` — player of specified name only (case sensitive)
* `raid` — raid members **in groups 1-5 only**
* `all` — players **in raid groups 1-8** as well as **members of the standby
  list**
* `standby` — raid members **in groups 6-8** and players **on the standby list**
  remaining out of the raid
* `party1` up to `party8` (`pt1`—`pt8`) — members of specified raid subgroup
* `party` — your party members
* `ironman` — iron man eligible players
* `druids`, `hunters`, `mages`, `paladins`, `priests`, `rogues`, `shamans`,
  `warlocks`, `warriors` — class members
* `main` (`mains`) — mains only
* `alt` (`alts`) — alts only
* `zone` — characters in the same zone
* `otherzone` — characters in other zones
* `guild ` — all guild members
* `officer` (`officers`) — officers
* `online` — online characters only

> Filter matching does not distinguish between online/offline players and treats
> offline characters as matching specified conditions **unless the `online`
> qualifier** is used. This stands in contrast to QDKP default behaviour.

You may combine multiple qualifiers to obtain particular lists of characters.
This can be done by separating filters in such ways:

* by space — means logic `AND`
* by comma — means logic `OR`

You can even mix both. Look at the examples:

* `Steven, Helen, Jack` → `named Steven OR Helen OR Jack` → specified characters
* `party5 warlocks` → `being in party no 5 AND a warlock` →
  warlocks in subgroup no 5
* `raid main druids` → `being in raid AND a main AND a druid` →
  main druid characters in the raid
* `party2 mages, raid hunters, Jeff` → `being in raid group no 2 AND a mage
  OR in raid AND a hunter OR named Jeff` → raid mages in subgroup no 2, hunters
  in raid or character named Jeff

> Watch out! Take a look at this example, which illustrates the difference
> between space and comma:
>
> `Steven Helen Jack` → `named Steven AND Helen AND Jack` →
> player named simultaneously Steven, Helen and Jack
>
> Such filter always returns no characters because they can only have one name.

Example usage with DKP awarding:

```
/sdkp award! party2 mages, raid hunters, Jeff 25 nice job
```

Output redirection
------------------

Some commands accept the output redirecting sequence in form of `@channel`. This
enables you to send the results to different channels. Available channels are:

```
@guild      @officer    @party      @raid       @raid_warning
@say        @yell       @<player>   @<channel>
```

You have to join the channel before using `@<channel>`, for example `@mychannel`.
If the specified channel is not found, the string is interpreted as a player
name and whisper is sent, for example `@Jack`.

Other core commands
-------------------

You can also modify DKP values without immediately storing them to officer notes.
These changes stay in roster data until explicitly stored to notes or discarded.

* `/sdkp modify <player> <netDelta> [<totDelta> [<hrsDelta>]]`
  — Changes player's DKP amounts as relative values.
* `/sdkp store` — Stores pending DKP changes to officer notes.
* `/sdkp discard` — Discards all pending roster changes.

Remaining commands:

* `/sdkp set <player> <net> [<tot> [<hrs>]]` — Sets fixed player DKP amounts
  and stores them immediately to officer note.
* `/sdkp info <player>` — Prints DKP info for given player.
* `/sdkp usage` — Prints some help about usage strings.
* `/sdkp versions` — Prints out guild mates' addon versions.

Categorized commands
--------------------

### Alts `/sdkp alt ...`

Alt management functions can be accessed with `/sdkp alt`.

* `/sdkp alt set <alt> <main>` — Set alt status for specified character.
* `/sdkp alt clear <character>` — Clears character's alt status.
* `/sdkp alt swap <oldmain> <newmain>` — Swap player's main.

### Aliasing `/sdkp alias ...`

Aliases are a way of binding out of guild characters with their guild characters.
Aliasing functions are grouped uncer `/sdkp alias`.

* `/sdkp alias set <alias> <main>` — Sets alias as a main's character.
  This will affect only out of guild characters.
* `/sdkp alias list` — Lists saved aliases to chat frame.
* `/sdkp alias clear <alias>` — Clears alias status from character.

### Backups `/sdkp backup ...`

Backup module provides functionality dedicated to creating, restoring, comparing
and deleting of officer note backups.

* `/sdkp backup create` — Saves a new officer note backup.
* `/sdkp backup restore <timestamp>` — Loads specified backup to officer notes.
* `/sdkp backup list [<guild>]`
  — Lists all saved backups. Guild name parameter is optional.
* `/sdkp backup diff <timestamp>`
  — Shows differences from specified to current roster DKP data.
* `/sdkp backup delete <timestamp>`
  — Deletes backup specified by creation timestamp.

### Iron man `/sdkp ironman ...`

sDKP has built-in iron man support. These commands are used for flagging players
eligible for iron man bonus.

> **Keep in mind** that iron man flag is set for the main character
> (which applies later to alts).

* `/sdkp ironman start [<filter>]`
  — Saves entire raid (groups 1-8) or selected players (if specified) for iron
  man bonus. Clears previously stored iron man data.
* `/sdkp ironman clear` — Cancels entirely iron man bonus awarning no DKP.
* `/sdkp ironman add <filter>` — Adds selected players to the iron man list.
  Does not clear any iron man data.
* `/sdkp ironman remove <filter>` — Removes selected players from ironman list.
* `/sdkp ironman list` — Lists players eligible for iron man bonus.
* `/sdkp ironman reinvite`
  — Reinvites iron man eligible players who remain online out of raid.
* `/sdkp award! ironman 50`
  — Use this example to award players the iron man bonus.

> **Bear in mind** that iron man data won't be cleared unless
> `/sdkp ironman clear` or until `/sdkp ironman start` is issued!

### Logs management `/sdkp log ...`

All DKP operations are stored in the account-wide per-guild log. Same applies
to loot above specified threshold (epic by default). To manage the log, use
commands under `/sdkp log`.

* `/sdkp log recent [<timestamp>]` — Prints log entries from last 1 day or newer
    than specified timestamp.
    * The time stamp parameter has the form of `YYYYMMDD`.
      Examples of valid timestamps: `20140211`, `201302`, `2010`.

* `/sdkp log search <query>[|...] [[from<]time[<to]] [@<channel>]`
  — Shows all entries matching given string(s).
    * Search query in `/sdkp log search` can be a character name, part of reason
    or an item name. All log entries are matched against specified pattern and
    shown if positive. You can also provide multiple patterns by separating them
    with `|` character. The entry will be shown if any of the patterns matches.
    Example: `/sdkp log search Jeff|Helen|Jack`.
    * The `time` parameter allows specifying the searching period. It uses
    similar syntax as the `timestamp` parameter in `/sdkp log recent`. Use it
    like this:
    ```
    /sdkp log search time>20140707

    /sdkp log search Jeff time>201406

    /sdkp log search Helen|Jack time<2010

    /sdkp log search Badge of Justice 201206<time<201207
    ```
* `/sdkp log purge [<timestamp>]` — Deletes log entries for current guild older
  than specified or at least 4 weeks old if no parameter given.
* `/sdkp log dump` — Prints all entries from log into the chat frame.

### Standby `/sdkp standby ...`

Standby flagging is similar to the functionality of iron man bonus. Its main
goal is to keep standby players out of raid when they do not participate in it
actively.

> Contrary to iron man bonus, standby flags are kept per character!

* `/sdkp standby start [<filter>]` — Adds entire raid (groups 1-8) or selected
  players only to standby list. Clears previously stored standby data.
* `/sdkp standby clear` — Clears standby data from guild roster.
* `/sdkp standby add <filter>` — Adds selected players to standby list.
* `/sdkp standby remove <filter>` — Removes selected players from standby list.
* `/sdkp standby list` — Prints standby list to chat frame.
* `/sdkp standby uninvite` — Uninvites standby players (groups 6-8) from raid.
* `/sdkp stnadby reinvite` — Reinvites online standby players to raid.
  This sends invites to player's online character.

### Statistics `/sdkp stat ...`

Statictics commands require `sDKP_Stat` addon enabled. All ranges are evaluated
as weak inequalities (`parameter >= value` and `parameter <= value`).

* `/sdkp who params` — Who-like utility for guild. Params may include:
  * `n-Name` — name lookup
  * `c-Class` — class lookup
  * `z-Zone` — zone lookup
  * `N-PlayerNote` — player note match
  * `O-OfficerNote` — officer note match
  * `R-RankName` — rank name match
  * `lvl-L`, `lvl<M`, `lvl>m`, `m<lvl<M` — specified level or level range
  * `rank-R`, `rank<M`, `rank>m`, `m<rank<M` — specified rank ID or rank range
  * `net<M`, `net>m`, `m<net<M` — netto DKP range
  * `tot<M`, `tot>m`, `m<tot<M` — total DKP range
  * `hrs<M`, `hrs>m`, `m<hrs<M` — hour counter range
  * `online` — online players only
  * `raid` — raid members only
  * `main` or `alt` — character status filter

  > You may combine multiple search conditions
  > by listing them separated with spaces. Examples:
  >
  > Online players with more than 200 netto DKP
  > and total DKP between 800 and 1200:
  >
  > ```
  > /sdkp who online net>200 800<tot<1200
  > ```
  >
  > Raid healers (assuming H in player note means that player is a healer):
  >
  > ```
  > /sdkp who raid N-H
  > ```
  >
  > Warlocks with negative netto DKP values (greetings to Nevendar):
  >
  > ```
  > /sdkp who O-Net:%- c-warlock
  > ```

* `/sdkp stat class` — Displays class breakdown.
* `/sdkp stat guild` — Displays overall player, main and alt counts.
* `/sdkp stat level` — Displays level breakdown.
* `/sdkp stat rank` — Displays rank breakdown.
* `/sdkp stat spec` — Displays specialization breakdown. Specialization data is
  loaded from player note data and has to be stored between square braces `[spec]`.
  Recognized specialization symbols include:
  * `D` — melee DPS
  * `H` — healer
  * `L` — leveling
  * `RD` — ranged dps
  * `T` — tank
* `/sdkp stat spent` — Displays spent DKP ranking.
* `/sdkp stat top [<count>] [<filter>]` — Displays netto DKP ranking
  for selected players or all guild mains if not specified.
* `/sdkp stat total [<count>]` — Displays total DKP ranking.
* `/sdkp stat zone` — Displays zone breakdown.

### Options `/sdkp option ...`

A few settings of sDKP can be adjusted with option management commands.

* `/sdkp option dkpformat <format>` — Sets DKP format for officer notes.
  This decides what goes between curly braces in officer notes. By default,
  sDKP uses QDKP compatible format of `Net:%n Tot:%t Hrs:%h`. As you can see,
  there are some special placeholders for player data. These are:
  * `%n` for netto DKP,
  * `%t` for total DKP,
  * `%h` for hour counter,
  * `%d` for current day,
  * `%m` for current month,
  so that `%d.%m` produces a standard date.

* `/sdkp option ignoreginfo off|on`
  — Toggles ignoring of guild info DKP note format.

  > You may specify the DKP note format for sDKP in guild info message so that
  > all officers share the same format. Just use the following string:
  > `{dkp:FORMAT}` where `FORMAT` is the same as in `/sdkp option dkpformat`.
  >
  > This option comes handy if you want not to synchronize note format from
  > guild info.

* `/sdkp option verbosediff off|on`
  — Specifies whether to print chat notifications on DKP changes. On by default.
* `/sdkp option whispers off|on`
  — Toggles whisper announces of DKP changes made by you. On by default.
