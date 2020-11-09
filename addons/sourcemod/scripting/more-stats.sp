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
	StatType_PerfStreaks
}

#define MAX_BHOP_TICKS 8
#define MAX_PERF_STREAK 24

Database gH_DB;
bool gB_Loaded[MAXPLAYERS + 1];
int gI_TickCount[MAXPLAYERS + 1];
int gI_CurrentPerfStreak[MAXPLAYERS + 1];
int gI_BhopTicks[MAXPLAYERS + 1][MAX_BHOP_TICKS];
int gI_PerfStreaks[MAXPLAYERS + 1][MAX_PERF_STREAK];



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
	gI_CurrentPerfStreak[client] = 0;
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
	gI_TickCount[client] = tickcount;
}

public void Movement_OnPlayerJump(int client, bool jumpbug)
{
	if (!gB_Loaded[client] || IsFakeClient(client))
	{
		return;
	}

	int landingTick = Movement_GetLandingTick(client);
	int groundTicks = gI_TickCount[client] - landingTick - 1;

	// Bhop stats
	if (groundTicks >= 0 && groundTicks < MAX_BHOP_TICKS)
	{
		gI_BhopTicks[client][groundTicks]++;
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

void EndPerfStreak(int client)
{
	int streak = gI_CurrentPerfStreak[client];
	if (streak > 0 && streak <= MAX_PERF_STREAK)
	{
		int index = streak - 1;
		gI_PerfStreaks[client][index]++;
	}
	gI_CurrentPerfStreak[client] = 0;
}



// ===== [ COMMANDS ] =====

void RegisterCommands()
{
	RegConsoleCmd("sm_bhopstats", CommandBhopStats);
	RegConsoleCmd("sm_perfstats", CommandBhopStats);
	RegConsoleCmd("sm_perfstreaks", CommandPerfStreaks);
}

Action CommandBhopStats(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintToConsole(client, "Bhop Stats:");
	for (int i = 0; i < MAX_BHOP_TICKS; i++)
	{
		int tick = i + 1;
		int count = gI_BhopTicks[client][i];
		PrintToConsole(client, "Tick %d: %6d", tick, count);
	}
	return Plugin_Handled;
}

Action CommandPerfStreaks(int client, int argc)
{
	if (!gB_Loaded[client])
	{
		return Plugin_Handled;
	}

	PrintToConsole(client, "Perf Streaks:");
	for (int i = 0; i < MAX_PERF_STREAK; i++)
	{
		int streak = i + 1;
		int count = gI_PerfStreaks[client][i];
		PrintToConsole(client, "Perfs %2d: %6d", streak, count);
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

	char query[1024];
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
	query[strlen(query) - 1] = 0; // Remove last comma...
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
		}
	}

	gB_Loaded[client] = true;
}
