// ===== [ COMMANDS ] =====

void RegisterCommands()
{
	RegConsoleCmd("sm_bhopstats", CommandBhopStats);
	RegConsoleCmd("sm_perfstats", CommandBhopStats);
	RegConsoleCmd("sm_perfstreaks", CommandPerfStreaks);
	RegConsoleCmd("sm_scrollstats", CommandScrollStats);

	RegConsoleCmd("sm_chatscrollstats", CommandChatScrollStats);

	RegConsoleCmd("sm_chatbhopstats", CommandChatBhopStats);

	RegConsoleCmd("sm_postrunstats", CommandPostRunStats);
	RegConsoleCmd("sm_resetsegment", CommandSegmentReset);
	RegConsoleCmd("sm_pausesegment", CommandSegmentPause);
	RegConsoleCmd("sm_unpausesegment", CommandSegmentPause);
	RegConsoleCmd("sm_togglesegment", CommandSegmentPause);
	RegConsoleCmd("sm_resumesegment", CommandSegmentPause);

	RegConsoleCmd("sm_resetcount", CommandResetCount);
	RegConsoleCmd("sm_completioncount", CommandCompletionCount);
	RegConsoleCmd("sm_procompletioncount", CommandProCompletionCount);

	RegConsoleCmd("sm_rcount", CommandResetCount);
	RegConsoleCmd("sm_ccount", CommandCompletionCount);
	RegConsoleCmd("sm_pccount", CommandProCompletionCount);
	
	RegConsoleCmd("sm_chatairstats", CommandChatAirStats);
	RegConsoleCmd("sm_airstats", CommandAirStats);
}

Action CommandPostRunStats(int client, int argc)
{
	gB_PostRunStats[client] = !gB_PostRunStats[client];
	if (gB_PostRunStats[client])
	{
		PrintToChat(client, "%s\8Post-run stats enabled. Check console at the end of the run for more statistics.", PREFIX);
	}
	else
	{
		PrintToChat(client, "%s\8Post-run stats disabled.", PREFIX);
	}
	if (AreClientCookiesCached(client))
	{
		char buffer[2];
		IntToString(gB_PostRunStats[client], buffer, sizeof(buffer));	
		SetClientCookie(client, gH_MoreStatsCookie, buffer);
	}
	return Plugin_Handled;
}

Action CommandSegmentReset(int client, int argc)
{
	EndPerfStreak(client, Scope_Segment);
	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		FillArray(gI_BhopTicks[client][mode], sizeof(gI_BhopTicks[][]), Scope_Segment, 0);
		FillArray(gI_PerfStreaks[client][mode], sizeof(gI_PerfStreaks[][]), Scope_Segment, 0);	
		gI_SumRegisteredScrolls[client][mode][Scope_Segment] = 0;
		gI_SumFastScrolls[client][mode][Scope_Segment] = 0;
		gI_SumSlowScrolls[client][mode][Scope_Segment] = 0;
		gI_TimingTotal[client][mode][Scope_Segment] = 0;
		gI_TimingSamples[client][mode][Scope_Segment] = 0;		
		gI_GOKZPerfCount[client][mode][Scope_Segment] = 0;
	}

	for (int mode = 0; mode < MODE_COUNT; mode++)
	{
		for (int course = 0; course < GOKZ_MAX_COURSES; course++)
		{
			gI_ResetCount[client][course][mode][Scope_Segment] = 0;
			gI_CompletionCount[client][course][mode][Scope_Segment] = 0;
			gI_ProCompletionCount[client][course][mode][Scope_Segment] = 0;
		}
		gI_AirTime[client][mode][Scope_Segment] = 0;
		gI_Strafes[client][mode][Scope_Segment] = 0;
		gI_Overlap[client][mode][Scope_Segment] = 0;
		gI_DeadAir[client][mode][Scope_Segment] = 0;
		gI_AirAccelTime[client][mode][Scope_Segment] = 0;
		gI_AirVelChangeTime[client][mode][Scope_Segment] = 0;
	}
	PrintToChat(client, "%s\8Segment stats have been reset.", PREFIX);
}

Action CommandSegmentPause(int client, int argc)
{
	gB_SegmentPaused[client] = !gB_SegmentPaused[client];
	if (gB_SegmentPaused[client])
	{
		PrintToChat(client, "%s\8Segment stats paused.", PREFIX);
	}
	else
	{
		PrintToChat(client, "%s\8Segment stats resumed.", PREFIX);
	}
	return Plugin_Handled;
}

// ===== [ BhopStats ] =====
Action CommandBhopStats(int client, int argc)
{
	if (!gB_BhopStatsLoaded[client])
	{
		return Plugin_Handled;
	}

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;

	if (argc >= 1)
	{
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}
		else if (StrEqual(buffer, "run", false))
		{
			scope = Scope_Run;
		}
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	PrintBhopStats(client, gI_BhopTicks[client][mode], sizeof(gI_BhopTicks[][]), mode, scope);
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandChatBhopStats(int client, int argc)
{
	if (!gB_BhopStatsLoaded[client])
	{
		return Plugin_Handled;
	}

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;

	if (argc >= 1)
	{
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}
		else if (StrEqual(buffer, "run", false))
		{
			scope = Scope_Run;
		}
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}

	PrintShortBhopStats(client, gI_BhopTicks[client], sizeof(gI_BhopTicks[][]), mode, scope);
	
	return Plugin_Handled;
}

Action CommandPerfStreaks(int client, int argc)
{
	if (!gB_BhopStatsLoaded[client])
	{
		return Plugin_Handled;
	}

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;

	if (argc >= 1)
	{
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}
		else if (StrEqual(buffer, "run", false))
		{
			scope = Scope_Run;
		}
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	PrintPerfStreaks(client, gI_PerfStreaks[client][mode], sizeof(gI_PerfStreaks[][]), scope);
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandScrollStats(int client, int argc)
{
	if (!gB_BhopStatsLoaded[client])
	{
		return Plugin_Handled;
	}

	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;

	if (argc >= 1)
	{
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}
		else if (StrEqual(buffer, "run", false))
		{
			scope = Scope_Run;
		}
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	PrintScrollStats(client, gI_SumRegisteredScrolls[client][mode][scope], 
		gI_SumFastScrolls[client][mode][scope], 
		gI_SumSlowScrolls[client][mode][scope], 
		gI_TimingTotal[client][mode][scope], 
		gI_TimingSamples[client][mode][scope]);
	PrintCheckConsole(client);
	return Plugin_Handled;
}

Action CommandChatScrollStats(int client, int argc)
{
	gB_ChatScrollStats[client] = !gB_ChatScrollStats[client];
	if (gB_ChatScrollStats[client])
	{
		PrintToChat(client, "%s\8Chat scroll stats enabled. Check console for more information.", PREFIX);

		PrintToConsole(client, "*0 Scrolls (*1) | *2 / *3 Speed | *4 Time | *5 Ground");
		PrintToConsole(client, "=====================================================");
		PrintToConsole(client, "*0 = How many fresh +jump commands were registered during the scroll");
		PrintToConsole(client, "*1 = The effectiveness of the scroll speed (3 jump commands like so +-+-+- is 100%%)");
		PrintToConsole(client, "*2 = Ticks wasted on slow scrolling (-jump twice or more in a row)");
		PrintToConsole(client, "*3 = Ticks wasted on fast scrolling (+jump twice or more in a row)");
		PrintToConsole(client, "*4 = The timing in ticks of the bhop related to scroll 'middle' (negative means early, positive means late)");
		PrintToConsole(client, "*5 = Amount of ticks spent on the ground");
	}
	else
	{
		PrintToChat(client, "%s\8Chat scroll stats disabled.", PREFIX);
	}
	return Plugin_Handled;
}

// ===== [ ResetStats ] =====
Action CommandResetCount(int client, int argc)
{
	int course = GOKZ_GetCourse(client);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;


	if (argc >= 1)
	{
		// Run scope doesn't mean anything here!
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}		
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		course = StringToInt(buffer);		
	}
	if (argc >= 3)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}

	PrintToChat(client, "%sReset count: \6%i", PREFIX, GetResetCount(client, course, mode, scope))
	return Plugin_Handled;
}

Action CommandCompletionCount(int client, int argc)
{
	int course = GOKZ_GetCourse(client);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;	

	if (argc >= 1)
	{
		// Run scope doesn't mean anything here!
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}		
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		course = StringToInt(buffer);		
	}
	if (argc >= 3)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	int completions = GetCompletionCount(client, course, mode, scope);
	int resets = GetResetCount(client, course, mode, scope);
	float percent = resets == 0 ? 0.0 : float(completions) / resets * 100;
	PrintToChat(client, "%sCompletion count: \6%i \8/ \6%i \8| \6%.2f\8%%", PREFIX, completions, resets, percent);
	return Plugin_Handled;
}

Action CommandProCompletionCount(int client, int argc)
{
	int course = GOKZ_GetCourse(client);
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;	

	if (argc >= 1)
	{
		// Run scope doesn't mean anything here!
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}		
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[32];
		GetCmdArg(1, buffer, sizeof(buffer));
		course = StringToInt(buffer);		
	}
	if (argc >= 3)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	int completions = GetCompletionCount(client, course, mode, scope, true);
	int resets = GetResetCount(client, course, mode, scope);
	float percent = resets == 0 ? 0.0 : float(completions) / resets * 100;
	PrintToChat(client, "%sCompletion count: \4%i \8/ \4%i \8|\4%5.2f\8%%", PREFIX, completions, resets, percent);
	return Plugin_Handled;
}

// ===== [ AirStats ] =====
Action CommandAirStats(int client, int argc)
{
	int mode = GOKZ_GetCoreOption(client, Option_Mode);
	int scope = Scope_AllTime;

	if (argc >= 1)
	{
		// Run scope doesn't mean anything here!
		char buffer[10];
		GetCmdArg(1, buffer, sizeof(buffer));
		if (StrEqual(buffer, "session", false))
		{
			scope = Scope_Session;
		}
		else if (StrEqual(buffer, "run", false))
		{
			scope = Scope_Segment;
		}
		else if (StrEqual(buffer, "segment", false))
		{
			scope = Scope_Segment;
		}
	}
	if (argc >= 2)
	{
		char buffer[10];
		GetCmdArg(2, buffer, sizeof(buffer));
		if (StrEqual(buffer, "kzt", false))
		{
			mode = Mode_KZTimer;
		}
		else if (StrEqual(buffer, "skz", false))
		{
			mode = Mode_SimpleKZ;
		}
		else if (StrEqual(buffer, "vnl", false))
		{
			mode = Mode_Vanilla;
		}
	}
	
	PrintCheckConsole(client);
	PrintAirStats(client, mode, scope);
	return Plugin_Handled;
}

Action CommandChatAirStats(int client, int argc)
{
	gB_ChatAirStats[client] = !gB_ChatAirStats[client];
	if (gB_ChatAirStats[client])
	{
		PrintToChat(client, "%s\8Air scroll stats enabled. Check console for more information.", PREFIX);

		PrintToConsole(client, "*0 Strafes | Sync: *1%% / *2%% | Air: *3 | OL: *4 | DA: *5 | BA: *6");
		PrintToConsole(client, "=====================================================");
		PrintToConsole(client, "*0 = Strafe count in the air, determined by mouse movements");
		PrintToConsole(client, "*1 = Percentage of ticks gaining speed in the air");
		PrintToConsole(client, "*2 = Percentage of ticks air acceleration would have an impact on velocity");
		PrintToConsole(client, "*3 = Ticks spent in the air");
		PrintToConsole(client, "*4 = Ticks spent in the air where strafe keys are overlapped, resulting in no acceleration");
		PrintToConsole(client, "*5 = Ticks spent in the air where no strafe key is pressed");
		PrintToConsole(client, "*6 = Ticks spent in the air where air acceleration has no impact on velocity due to bad angles");
	}
	else
	{
		PrintToChat(client, "%s\8Chat air stats disabled.", PREFIX);
	}
	return Plugin_Handled;
}