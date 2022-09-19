# LEGACY!!!
This repository will not get any feature updates (big bugs will still get fixed).

KZTimer servers can only use this legacy version.

If you are hosting a GOKZ server, use [this fork](https://github.com/zer0k-z/more-stats) by zer0.k!

If you are updating to zer0.k fork, you can run these SQL queries to port your database:
```SQL
INSERT INTO BhopStats (SteamID32, Mode, StatType1, StatType2, StatCount)
  SELECT olddb.SteamID32, 2, olddb.StatType1, olddb.StatType2, olddb.StatCount 
    FROM MoreStats olddb
ON DUPLICATE KEY UPDATE Mode=2, StatCount=olddb.StatCount;

INSERT INTO BhopStats (SteamID32, Mode, StatType1, StatType2, StatCount)
  SELECT olddb.SteamID32, 2, 4, 0, olddb.StatCount
    FROM MoreStats olddb
    WHERE olddb.StatType1=0 AND olddb.StatType2=0
ON DUPLICATE KEY UPDATE StatCount=olddb.StatCount;
```

# More Stats

![Downloads](https://img.shields.io/github/downloads/zer0k-z/more-stats/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/zer0k-z/more-stats?style=flat-square) ![Open issues](https://img.shields.io/github/issues/zer0k-z/more-stats?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/zer0k-z/more-stats?style=flat-square) ![Size](https://img.shields.io/github/repo-size/zer0k-z/more-stats?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/zer0k-z/more-stats/Compile%20with%20SourceMod?style=flat-square)

Plugin to display statistics about various KZ actions. Read [this](https://github.com/Szwagi/more-stats/blob/main/README.md) if you are looking to migrate from Szwagi's plugins.

### Commands

#### Arguments
- Scope (s): `all` (`alltime` / `overall`) / `session` / `run` (not available for ResetStats) / `segment` / `jump` (exclusive to AirStats). Commands will show alltime statistics by default.
- Mode (m): `kzt` / `skz` / `vnl`. Commands will use the current mode by default.
- Course (c): 0 (main course), 1-100 (bonuses). Commands will use the current course by default.
- For ResetStats, map name can be used instead of scope to show reset statistics for the requested map instead.
#### General
- `!morestats` - Display command list in console

- `!pausesegment` / `!unpausesegment` / `!resumesegment` / `!togglesegment` - Toggle recording of the segment

- `!resetsegment` - Reset all statistics of the segment

- `!postrunstats` - Display all run statistics at the end of the run

#### BhopStats

- `!bhopstats` / `!perfstats` `<s> <m>` - Display bhop statistics

- `!perfstreaks <s> <m>` - Display perf streaks

- `!scrollstats <s> <m>` - Display scroll statistics

- `!chatscrollstats` - Display realtime scroll statistics in chat

- `!chatbhopstats <s> <m>` - Display bhop statistics in chat, similar to GOKZ's `!bhopcheck`

#### ResetStats

- `!resetcount` / `!rcount <s/map> <c> <m>` - Display reset count

- `!completioncount` / `!ccount <s/map> <c> <m>` - Display reset and completion count

- `!procompletioncount` / `!pccount <s/map> <c> <m>` - Display reset and pro completion count

#### AirStats

- `!chatairstats` - Display realtime airstrafe statistics in chat

- `!airstats <s> <m>` - Display airstrafe statistics

### Admin Commands

- `!morestatsdelete <UID> <all/bhop/reset/air>.` - Delete statistics of selected player. UID is the number found in player's SteamID3: `[U:1:XXXXXXXXX]`

### Dependencies
- [MovementAPI](https://github.com/danzayau/MovementAPI)
- [GOKZ](https://github.com/KZGlobalTeam/gokz/)
- [Updater](https://forums.alliedmods.net/showthread.php?t=169095) (Optional)

### Notes
- Requires `more-stats` in databases config.
- Not every perf would result in a speed gain. More precisely (KZT/VNL example):

| # ticks on ground       | 0 (considered as 1 tick in more-stats)       | 1                                        | 2+                                         |
|-------------------------|----------------------------------------------|------------------------------------------|--------------------------------------------|
| Jumpbug/Duckbug/Telehop | Speed preserved, considered as GOKZ perf     | Speed clamped, considered as GOKZ perf   | Speed clamped, not considered as GOKZ perf |
| Normal                  | N/A                                          | Speed preserved, considered as GOKZ perf | Speed clamped, not considered as GOKZ perf |

### Todo
- Add a way to check other players' statistics
