# LEGACY!!!
This repository will not get any feature updates (big bugs will still get fixed).

KZTimer servers can only use this legacy version.

If you are hosting a GOKZ server, use [this fork](https://github.com/zer0k-z/more-stats) by zer0.k!

If updating to zer0.k fork, you can run these SQL queries to port your database:
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

Plugin to display statistics about various KZ actions.

### Commands
- `!bhopstats` / `!perfstats` - Display bhop ground ticks
- `!sessionbhopstats` / `!sessionperfstats` - Display bhop ground ticks since connected
- `!perfstreaks` - Display perf streaks
- `!sessionperfstreaks` - Display perf streaks since connected
- `!scrollstats` - Display scroll statistics
- `!sessionscrollstats` - Display scroll statistics since connected
- `!chatscrollstats` - Display scroll statistics in chat as they happen 

### Dependencies
- [MovementAPI](https://github.com/danzayau/MovementAPI)

### Notes
- Requires `more-stats` in databases config

