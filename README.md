# More Stats

![Downloads](https://img.shields.io/github/downloads/zer0k-z/more-stats/total?style=flat-square) ![Last commit](https://img.shields.io/github/last-commit/zer0k-z/more-stats?style=flat-square) ![Open issues](https://img.shields.io/github/issues/zer0k-z/more-stats?style=flat-square) ![Closed issues](https://img.shields.io/github/issues-closed/zer0k-z/more-stats?style=flat-square) ![Size](https://img.shields.io/github/repo-size/zer0k-z/more-stats?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/zer0k-z/more-stats/Compile%20with%20SourceMod?style=flat-square)

Plugin to display statistics about various KZ actions. Read [this](https://github.com/Szwagi/more-stats/blob/main/README.md) if you are looking to migrate from Szwagi's plugins.

### Commands
- `!bhopstats` / `!perfstats <scope> <mode>` - Display bhop statistics

- `!perfstreaks <scope> <mode>` - Display perf streaks

- `!scrollstats <scope> <mode>` - Display scroll statistics

- `!airstats <scope> <mode>` - Display airstrafe statistics

- `!resetcount` / `!rcount <scope> <course> <mode>` - Display reset count

- `!completioncount` / `!ccount <scope> <course> <mode>` - Display reset and completion count

- `!procompletioncount` / `!pccount <scope> <course> <mode>` - Display reset and pro completion count

#

- `!chatbhopstats <scope> <mode>` - Display bhop statistics in chat, similar to GOKZ's `!bhopcheck`

- `!chatscrollstats` - Display scroll statistics in chat as they happen 

- `!chatairstats` - Display airstrafe statistics in chat as they happen

#
- `!pausesegment` / `!unpausesegment` / `!resumesegment` / `!togglesegment` - Toggle bhop recording of the segment

- `!resetsegment` - Reset all statistics of the segment

- `!postrunstats` - Display all statistics at the end of the run (GOKZ)
#
- Possible scopes: ``all`` (default) / ``session`` / ``run`` (not available for reset stats) / ``segment``.

- Possible modes: ``kzt`` / ``skz`` / ``vnl``. Default is player's current mode.

### Dependencies
- [MovementAPI](https://github.com/danzayau/MovementAPI)
- [GOKZ](https://bitbucket.org/kztimerglobalteam/gokz/)

### Notes
- Requires `more-stats` in databases config
- Not every perf would result in a speed gain. More precisely (KZT/VNL example):

| # ticks on ground       | 0 (considered as 1 tick in more-stats)       | 1                                        | 2+                                         |
|-------------------------|----------------------------------------------|------------------------------------------|--------------------------------------------|
| Jumpbug/Duckbug/Telehop | Speed preserved, considered as GOKZ perf     | Speed clamped, considered as GOKZ perf   | Speed clamped, not considered as GOKZ perf |
| Normal                  | N/A                                          | Speed preserved, considered as GOKZ perf | Speed clamped, not considered as GOKZ perf |

### Todo
- Add a way to check other players' statistics
