bool g_bLrStamm = false;

Handle g_hLrTimer = null;

bool g_bInRound[MAXPLAYERS + 1] =  { false, ... };


void LrStammpunkte_RoundStart()
{
	ResetLrStammpunkte();
	
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			g_bInRound[i] = true;
		}
	}
	
	g_hLrTimer = CreateTimer(240.0, LrTimer);
}

void LrStammpunkte_RoundEnd()
{
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			g_bInRound[i] = false;
		}
	}
}

void ResetClientLrStammpunkte(int client)
{
	g_bInRound[client] = false;
}

public Action LrTimer(Handle timer)
{
	g_bLrStamm = true;
	
	g_hLrTimer = null;
	return Plugin_Stop;
}

void LrStammpunkte_PlayerDeath()
{
	int iPlayerCount = 0;
	
	LoopClients(i)
	{
		if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
		{
			if(g_bInRound[i])
			{
				iPlayerCount++;
			}
		}
	}

	int iMinPlayers = 5;
	ConVar cvar = FindConVar("stamm_min_player");

	if (cvar != null)
	{
		iMinPlayers = cvar.IntValue;
	}
	
	if(iPlayerCount >= iMinPlayers && GetAlivePlayers() == 1)
	{
		if(g_bLrStamm)
		{
			CPrintToChatAll("%s %s%N %serhält %s10 Bonus Stammpunkte%s, da er der letzte Überlebende ist.", OUTBREAK, SPECIAL, GetLastAlivePlayer(), TEXT, SPECIAL, TEXT);
			STAMM_AddClientPoints(GetLastAlivePlayer(), 10);	
		}
		else
		{
			CPrintToChatAll("%s Die Runde muss eine bestimmte Zeit lang sein und es müssen mind. 5 Spieler auf dem Server spielen, um 10 Stammpunkte zu bekommen.", OUTBREAK);
		}
	}
}

void ResetLrStammpunkte()
{
	g_bLrStamm = false;

	delete g_hLrTimer;
}