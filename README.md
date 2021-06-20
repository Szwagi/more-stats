# More Stats

Plugin to display statistics about various KZ actions.

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

### Todo
- Add a way to check other players' statistics
