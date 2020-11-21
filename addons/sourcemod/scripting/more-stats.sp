#include <sourcemod>
#include <movementapi>

#pragma newdecls required
#pragma semicolon 1



public Plugin myinfo = 
{
	name = "More Stats", 
	author = "Szwagi", 
	description = "Tracks various KZ related statistics", 
	version = "v1.0.0", 
	url = "https://github.com/Szwagi/more-stats"
};

enum
{
	StatType_BhopStats,
	StatType_PerfStreaks,
	StatType_ScrollEff
};

enum
{
	ScrollEff_RegisteredScrolls,
	ScrollEff_FastScrolls,
	ScrollEff_SlowScrolls
};

#define PREFIX " \4KZ \8| "
#define MAX_BHOP_TICKS 8
#define MAX_PERF_STREAK 24
#define MAX_SCROLL_TICKS 16

Database gH_DB;
bool gB_Loaded[MAXPLAYERS + 1];
int gI_TickCount[MAXPLAYERS + 1];
int gI_LastPlusJumpCmdNum[MAXPLAYERS + 1];
int gI_CurrentPerfStreak[MAXPLAYERS + 1];
int gI_BhopTicks[MAXPLAYERS + 1][MAX_BHOP_TICKS];
int gI_BhopTicksSession[MAXPLAYERS + 1][MAX_BHOP_TICKS];
int gI_PerfStreaks[MAXPLAYERS + 1][MAX_PERF_STREAK];
int gI_PerfStreaksSession[MAXPLAYERS + 1][MAX_PERF_STREAK];
bool gB_ChatScrollStats[MAXPLAYERS + 1];
bool gB_Scrolling[MAXPLAYERS + 1];
int gI_ScrollGroundTicks[MAXPLAYERS + 1];
int gI_ScrollStartCmdNum[MAXPLAYERS + 1];
int gI_RegisteredScrolls[MAXPLAYERS + 1];
int gI_FastScrolls[MAXPLAYERS + 1];
int gI_SlowScrolls[MAXPLAYERS + 1];
int gI_LastButtons[MAXPLAYERS + 1];
int gI_SumRegisteredScrolls[MAXPLAYERS + 1];
int gI_SumFastScrolls[MAXPLAYERS + 1];
int gI_SumSlowScrolls[MAXPLAYERS + 1];
int gI_SumRegisteredScrollsSession[MAXPLAYERS + 1];
int gI_SumFastScrollsSession[MAXPLAYERS + 1];
int gI_SumSlowScrollsSession[MAXPLAYERS + 1];


// ===== [ PLUGIN EVENTS ] =====

public void OnPluginStart()
{
	RegisterCommands();
	SetupDatabase();
}



// ===== [ CLIENT EVENTS ] =====

public void OnClientConnected(int client)
{
	gB_Loaded[client] = false;
	gI_TickCount[client] = 0;
	gI_LastPlusJumpCmdNum[client] = 0;
	gI_CurrentPerfStreak[client] = 0;
	FillArray(gI_BhopTicks[client], sizeof(gI_BhopTicks[]), 0);
	FillArray(gI_BhopTicksSession[client], sizeof(gI_BhopTicksSession[]), 0);
	FillArray(gI_PerfStreaks[client], sizeof(gI_PerfStreaks[]), 0);
	FillArray(gI_PerfStreaksSession[client], sizeof(gI_PerfStreaksSession[]), 0);
	gB_ChatScrollStats[client] = false;
	gB_Scrolling[client] = false;
	gI_ScrollGroundTicks[client] = -1;
	gI_ScrollStartCmdNum[client] = 0;
	gI_RegisteredScrolls[client] = 0;
	gI_FastScrolls[client] = 0;
	gI_SlowScrolls[client] = 0;
	gI_LastButtons[client] = 0;
	gI_SumRegisteredScrolls[client] = 0;
	gI_SumFastScrolls[client] = 0;
	gI_SumSlowScrolls[client] = 0;
	gI_SumRegisteredScrollsSession[client] = 0;
	gI_SumFastScrollsSession[client] = 0;
	gI_SumSlowScrollsSession[client] = 0;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
	{
		return;
	}

	LoadClientStats(client);
}

public void OnClientDisconnect(int client)
{	
	if (IsFakeClient(client))
	{
		return;
	}

	EndPerfStreak(client);
	SaveClientStats(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	gI_TickCount[client] = tickcount;

	if (!gB_Loaded[client])
	{
		return Plugin_Continue;
	}

	// Scroll stats, we eating spaghettios tonight
	int lastButtons = gI_LastButtons[client];

	bool inJump = (buttons & IN_JUMP) != 0;
	bool lastInJump = (lastButtons & IN_JUMP) != 0;

	if (gB_Scrolling[client])
	{
		if (inJump && !lastInJump)
		{
			gI_RegisteredScrolls[client]++;
		}
		else if (inJump && lastInJump)
		{
			gI_FastScrolls[client]++;
		}
		else if (!inJump && !lastInJump)
		{
			gI_SlowScrolls[client]++;
		}
	}

	if (inJump)
	{
		if (tickcount > gI_LastPlusJumpCmdNum[client] + MAX_SCROLL_TICKS)
		{
			// Started scrolling
			gB_Scrolling[client] = true;
			gI_ScrollGroundTicks[client] = -1;
			gI_ScrollStartCmdNum[client] = tickcount;
			gI_RegisteredScrolls[client] = 1;
			gI_FastScrolls[client] = 0;
			gI_SlowScrolls[client] = 0;
		}
		gI_LastPlusJumpCmdNum[client] = tickcount;
	}
	else if (gB_Scrolling[client])
	{
		if (tickcount > gI_LastPlusJumpCmdNum[client] + MAX_SCROLL_TICKS)
		{
			// Stopped scrolling
			gB_Scrolling[client] = false;

			bool scrollCausedBhop = (gI_ScrollGroundTicks[client] >= 0);
			int registeredScrolls = gI_RegisteredScrolls[client];
			if (registeredScrolls > 2 && scrollCausedBhop)
			{
				int fastScrolls = gI_FastScrolls[client];
				int slowScrolls = gI_SlowScrolls[client] - MAX_SCROLL_TICKS;

				if (gB_ChatScrollStats[client])
				{
					float effectivenessPercent = GetScrollEffectivenessPercent(registeredScrolls, fastScrolls, slowScrolls);
					int groundTicks = gI_ScrollGroundTicks[client];
					PrintToChat(client, "%s\6%d \8Scrolls (\6%0.0f%%\8) | \6%d \8/ \6%d \8Speed | \6%d \8Ground", 
						PREFIX, registeredScrolls, effectivenessPercent, slowScrolls, fastScrolls, groundTicks);
				}

				gI_SumRegisteredScrolls[client] += registeredScrolls;
				gI_SumFastScrolls[client] += fastScrolls;
				gI_SumSlowScrolls[client] += slowScrolls;
				gI_SumRegisteredScrollsSession[client] += registeredScrolls;
				gI_SumFastScrollsSession[client] += fastScrolls;
				gI_SumSlowScrollsSession[client] += slowScrolls;
			}
		}
	}

	gI_LastButtons[client] = buttons;

	return Plugin_Continue;
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!gB_Loaded[client] || IsFakeClient(client))
	{
		return;
	}

	int landingTick = Movement_GetLandingTick(client);
	int groundTicks = gI_TickCount[client] - landingTick - 1;

	// Scroll stats
	if (groundTicks >= 0 && groundTicks < MAX_BHOP_TICKS)
	{
		gI_ScrollGroundTicks[client] = groundTicks;
	}

	// Bhop stats
	if (groundTicks >= 0 && groundTicks < MAX_BHOP_TICKS)
	{
		gI_BhopTicks[client][groundTicks]++;
		gI_BhopTicksSession[client][groundTicks]++;
	}

	// Perf streaks
	if (groundTicks == 0)
	{
		int streak = gI_CurrentPerfStreak[client];
		if (streak < MAX_PERF_STREAK)
		{
			gI_CurrentPerfStreak[client]++;
		}
	}
	else
	{
		EndPerfStreak(client);
	}
}



// ===== [ HELPERS ] =====

void FillArray(any[] array, int length, any value)
{
	for (int i = 0; i < length; i++)
	{
		array[i] = value;
	}
}

float GetScrollEffectivenessPercent(int registeredScrolls, int fastScrolls, int slowScrolls)
{
	int badScrolls = fastScrolls + slowScrolls;
	if (registeredScrolls + badScrolls == 0)
	{
		return 0.0;
	}

	float effectiveness = registeredScrolls / (float(registeredScrolls) + (float(badScrolls) / 1.5));
	return effectiveness * 100.0;
}

void EndPerfStreak(int client)
{
	int streak = gI_CurrentPerfStreak[client];
	if (streak > 0 && streak <= MAX_PERF_STREAK)
	{
		int index = streak - 1;
		gI_PerfStreaks[client][index]++;
		gI_PerfStreaksSession[client][index]++;
	}
	gI_CurrentPerfStreak[client] = 0;
}

void PrintCheckConsole(int client)
{
	PrintToChat(client, "%sCheck console for results!", PREFIX);
}

void PrintBhopStats(int client, const int[] bhopTicks, int length)
{
	int sum = 0;
	for (int i = 0; i < length; i++)
	{
		sum += bhopTicks[i];
	}

	PrintToConsole(client, "Bhop Stats (%d bhops)", sum);
	PrintToConsole(client, "-----------------------");

	for (int i = 0; i < length; i++)
	{
		int tick = i + 1;
		int count = bhopTicks[i];
		float percent = (sum == 0) ? 0.0 : count / float(sum) * 100.0;
		PrintToConsole(client, "Tick %d: %6d | %5.2f%%", tick, count, percent);
	}
}

void PrintPerfStreaks(int client, const int[] perfStreaks, int length)
{
	int sum = 0;
	for (int i = 0; i < MAX_PERF_STREAK; i++)
	{
		sum += perfStreaks[i];
	}

	PrintToConsole(client, "Perf Streaks (%d streaks)", sum);
	PrintToConsole(client, "-------------------------");
	for (int i = 0; i < length; i++)
	{
		int streak = i + 1;
		int count = perfStreaks[i];
		float percent = (sum == 0) ? 0.0 : count / float(sum) * 100.0;
		PrintToConsole(client, "Perfs %2d: %6d | %5.2f%%", streak, count, percent);
	}
}

void PrintScrollStats(int client, int registeredScrolls, int fastScrolls, int slowScrolls)
{
	PrintToConsole(client, "Scroll Stats (%d scrolls)", registeredScrolls);
	PrintToConsole(client, "-------------------------");
	PrintToConsole(client, "Effectiveness: %0.2f%%", GetScrollEffectivenessPercent(registeredScrolls, fastScrolls, slowScrolls));
	PrintToConsole(client, "Fast: %d", fastScrolls);
	PrintToConsole(client, "Slow: %d", slowScrolls);
}



// ===== [ COMMANDS ] =====

void RegisterCommands()
{
	RegConsoleCmd("sm_bhopstats", CommandBhopStats);
	RegConsoleCmd("sm_perfstats", CommandBhopStats);
	RegConsoleCmd("sm_sessionbhopstats", CommandSessionBhopStats);
	RegConsoleCmd("sm_sessionperfstats", CommandSessionBhopStats);
	RegConsoleCmd("sm_perfstreaks", CommandPerfStreaks);
	RegConsoleCmd("sm_sessionperfstreaks", CommandSessionPerfStreaks);
	RegConsoleCmd("sm_scrollstats", CommandScrollStats);
	RegConsoleCmd("sm_sessionscrollstats", CommandSessionScrollStats);
	RegConsoleCmd("sm_chatscrollstats", CommandChatScrollStats);
}

Action CommandBhopStats(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintBhopStats(client, gI_BhopTicks[client], sizeof(gI_BhopTicks[]));
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandSessionBhopStats(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintBhopStats(client, gI_BhopTicksSession[client], sizeof(gI_BhopTicksSession[]));
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandPerfStreaks(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintPerfStreaks(client, gI_PerfStreaks[client], sizeof(gI_PerfStreaks[]));
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandSessionPerfStreaks(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintPerfStreaks(client, gI_PerfStreaksSession[client], sizeof(gI_PerfStreaksSession[]));
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandScrollStats(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintScrollStats(client, gI_SumRegisteredScrolls[client], gI_SumFastScrolls[client], gI_SumSlowScrolls[client]);
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandSessionScrollStats(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintScrollStats(client, gI_SumRegisteredScrollsSession[client], gI_SumFastScrollsSession[client], gI_SumSlowScrollsSession[client]);
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandChatScrollStats(int client, int argc)
{
	gB_ChatScrollStats[client] = !gB_ChatScrollStats[client];
	if (gB_ChatScrollStats[client])
	{
		PrintToChat(client, "%s\8Chat scroll stats enabled.", PREFIX);
	}
	else
	{
		PrintToChat(client, "%s\8Chat scroll stats disabled.", PREFIX);
	}
	return Plugin_Handled;
}



// ===== [ DATABASE ] =====

void SetupDatabase()
{
	char error[512];
	gH_DB = SQL_Connect("more-stats", true, error, sizeof(error));
	if (gH_DB == null)
	{
		SetFailState("Database connection failed. Error: \"%s\".", error);
	}

	Transaction txn = new Transaction();

	// Setup tables
	txn.AddQuery("CREATE TABLE IF NOT EXISTS MoreStats (" ...
    	"SteamID32 INTEGER NOT NULL, " ...
    	"StatType1 INTEGER NOT NULL, " ...
    	"StatType2 INTEGER NOT NULL, " ...
    	"StatCount INTEGER NOT NULL, " ...
    	"PRIMARY KEY(SteamID32, StatType1, StatType2))");

	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_High);
}

void LoadClientStats(int client)
{
	int userid = GetClientUserId(client);
	int steamid = GetSteamAccountID(client);
	if (steamid == 0)
	{
		return;
	}

	char query[256];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), 
		"SELECT StatType1, StatType2, StatCount " ...
		"FROM MoreStats " ...
		"WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	gH_DB.Execute(txn, SQLTxnSuccess_LoadClientStats, SQLTxnFailure_LogError, userid, DBPrio_Normal);
}

void SaveClientStats(int client)
{
	int steamid = GetSteamAccountID(client);
	if (steamid == 0 || !gB_Loaded[client])
	{
		return;
	}

	char query[2048];
	char buffer[128];
	Transaction txn = new Transaction();

	FormatEx(query, sizeof(query), "DELETE FROM MoreStats WHERE SteamID32 = %d", steamid);
	txn.AddQuery(query);

	FormatEx(query, sizeof(query), "INSERT INTO MoreStats (SteamID32, StatType1, StatType2, StatCount) VALUES ");

	for (int i = 0; i < MAX_BHOP_TICKS; i++)
	{
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, StatType_BhopStats, i, gI_BhopTicks[client][i]);
		StrCat(query, sizeof(query), buffer);
	}

	for (int i = 0; i < MAX_PERF_STREAK; i++)
	{
		FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, StatType_PerfStreaks, i, gI_PerfStreaks[client][i]);
		StrCat(query, sizeof(query), buffer);
	}

	FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, StatType_ScrollEff, ScrollEff_RegisteredScrolls, gI_SumRegisteredScrolls[client]);
	StrCat(query, sizeof(query), buffer);
	FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d),", steamid, StatType_ScrollEff, ScrollEff_FastScrolls, gI_SumFastScrolls[client]);
	StrCat(query, sizeof(query), buffer);
	// This format has no comma!!!
	FormatEx(buffer, sizeof(buffer), "(%d,%d,%d,%d)", steamid, StatType_ScrollEff, ScrollEff_SlowScrolls, gI_SumSlowScrolls[client]);
	StrCat(query, sizeof(query), buffer);

	//query[strlen(query) - 1] = 0; // Remove last comma...
	txn.AddQuery(query);

	gH_DB.Execute(txn, _, SQLTxnFailure_LogError, _, DBPrio_Normal);
}

void SQLTxnFailure_LogError(Database db, any unused, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError("[MoreStats] %s", error);
}

void SQLTxnSuccess_LoadClientStats(Database db, int userid, int numQueries, DBResultSet[] results, any[] queryData)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
	{
		return;
	}

	while (results[0].FetchRow())
	{
		int type1 = results[0].FetchInt(0);
		int type2 = results[0].FetchInt(1);
		int count = results[0].FetchInt(2);

		switch (type1)
		{
			case StatType_BhopStats:
			{
				if (type2 >= 0 && type2 < MAX_BHOP_TICKS)
				{
					gI_BhopTicks[client][type2] = count;
				}
			}
			case StatType_PerfStreaks:
			{
				if (type2 >= 0 && type2 < MAX_PERF_STREAK)
				{
					gI_PerfStreaks[client][type2] = count;
				}
			}
			case StatType_ScrollEff:
			{
				if (type2 == ScrollEff_RegisteredScrolls)
				{
					gI_SumRegisteredScrolls[client] = count;
				}
				else if (type2 == ScrollEff_FastScrolls)
				{
					gI_SumFastScrolls[client] = count;
				}
				else if (type2 == ScrollEff_SlowScrolls)
				{
					gI_SumSlowScrolls[client] = count;
				}
			}
		}
	}

	gB_Loaded[client] = true;
}
