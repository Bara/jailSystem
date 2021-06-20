#define FK_SOUND "buttons/weapon_cant_buy.wav"

bool g_bFreekill[MAXPLAYERS + 1] =  { false, ... };

ArrayList g_aClient = null;
ArrayList g_aAttacker = null;

bool g_bFKSQL[MAXPLAYERS + 1] =  { false, ... };
bool g_bFKBan[MAXPLAYERS + 1] =  { false, ... };

void Freekill_OnMapStart()
{
	PrecacheSoundAny(FK_SOUND, true);
}

public Action Command_freekill(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T && !IsPlayerAlive(client))
		{
			if(!g_bFKBan[client])
			{
				if(!g_bFreekill[client])
				{
					if(args < 1)
					{
						CPrintToChat(client, "%s Gib bitte deine Meinung an.", OUTBREAK);
						
						return Plugin_Handled;
					}
					
					char sMessage[MAX_MESSAGE_LENGTH];
					GetCmdArgString(sMessage, sizeof(sMessage));
					
					if (CheckCommandAccess(client, "sm_radmin", ADMFLAG_ROOT) && StrEqual(sMessage, "test"))
					{
						CPrintToChat(client, "%s %s%N %sist der Meinung, von %s<TEST> %sgefreekilled worden zu sein. Grund:", OUTBREAK, SPECIAL, client, TEXT, SPECIAL, TEXT);
						CPrintToChat(client, "%s %s%s", OUTBREAK, SPECIAL, sMessage);
						
						return Plugin_Continue;
					}
					
					char sName[MAX_NAME_LENGTH];
					GetClientName(client, sName, sizeof(sName));
					
					if(g_aClient.FindString(sName) == -1)
					{
						CPrintToChat(client, "%s Du hast dich selbst getötet..", OUTBREAK);
						
						return Plugin_Handled;
					}
					
					int iIndex = g_aClient.FindString(sName);
					
					char sAttacker[MAX_NAME_LENGTH];
					g_aAttacker.GetString(iIndex, sAttacker, sizeof(sAttacker));
					
					int iAttacker = FindClientByName(sAttacker, true);
					
					int iTick = SourceTV_GetRecordingTick();
					
					char sACom[32], sVCom[32], sMap[32];
					GetCurrentMap(sMap, sizeof(sMap));
					GetClientAuthId(client, AuthId_SteamID64, sVCom, sizeof(sVCom));
					
					if(iAttacker > 0)
					{
						GetClientAuthId(iAttacker, AuthId_SteamID64, sACom, sizeof(sACom));
					}
					else
						Format(sACom, sizeof(sACom), "-");
					
					/*
						sMap
						iTick
						sVCom
						client
						sACom
						sAttacker
						sMessage
					*/
					
					Menu menu = new Menu(Menu_FreekillConfirm);
					menu.SetTitle("Bitte bestätigen Sie diesen Report!\n \nSpieler: %s\nGrund: %s\n \nAbuse wird mit ein FK-Ban bestraft\noutbreak-community.de/freekill\n ", sAttacker, sMessage);
					menu.AddItem("yes", "Ja, es ist kein Abuse!\n \nSie haben 20 Sekunden Zeit.");
					menu.ExitButton = true;
					
					PushMenuCell(menu, "tick", iTick);
					PushMenuString(menu, "vcom", sVCom);
					PushMenuString(menu, "aname", sAttacker);
					PushMenuString(menu, "acom", sACom);
					PushMenuString(menu, "reason", sMessage);
					PushMenuString(menu, "map", sMap);
					
					menu.Display(client, 20);
				}
				else
				{
					CPrintToChat(client, "%s Du hast deine Meinung bereits geäußert.", OUTBREAK);
				}
			}
			else
			{
				CPrintToChat(client, "%s Du darfst kein !fk benutzen.", OUTBREAK);
			}
		}
		else
		{
			CPrintToChat(client, "%s Du bist nicht tot oder kein Terrorist.", OUTBREAK);
		}
	}
	
	return Plugin_Handled;
}

public int Menu_FreekillConfirm(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char sParam[32];
		menu.GetItem(param, sParam, sizeof(sParam));
		
		if(StrEqual(sParam, "yes", false))
		{
			int iTick = GetMenuCell(menu, "tick");
			
			char sACom[32], sVCom[32], sMap[32], sAttacker[MAX_NAME_LENGTH], sMessage[MAX_MESSAGE_LENGTH];
			GetMenuString(menu, "vcom", sVCom, sizeof(sVCom));
			GetMenuString(menu, "aname", sAttacker, sizeof(sAttacker));
			GetMenuString(menu, "acom", sACom, sizeof(sACom));
			GetMenuString(menu, "reason", sMessage, sizeof(sMessage));
			GetMenuString(menu, "map", sMap, sizeof(sMap));
			
			g_bFreekill[client] = true;
			
			CPrintToChatAll("%s %s%N %sist der Meinung, von %s%s %sgefreekilled worden zu sein. Grund:", OUTBREAK, SPECIAL, client, TEXT, SPECIAL, sAttacker, TEXT);
			CPrintToChatAll("%s %s%s", OUTBREAK, SPECIAL, sMessage);
			
			if (FindClientByName(sAttacker) > 0)
			{
				int clients[1];
				clients[0] = FindClientByName(sAttacker);
				EmitSoundAny(clients, 1, FK_SOUND);
			}
			
			char sQuery[512];
			g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `freekill_reports` (`date`, `map`, `tick`, `vCommunityid`, `vName`, `aCommunityid`, `aName`, `reason`) VALUES (UNIX_TIMESTAMP(), \"%s\", %d, \"%s\", \"%N\", \"%s\", \"%s\", \"%s\");", sMap, iTick, sVCom, client, sACom, sAttacker, sMessage);
			g_dDB.Query(Freekill_InsertQuery, sQuery);
		}
	}
	if (action == MenuAction_End)
		delete menu;
}

public Action Command_fkBan(int client, int args)
{
	if (args != 0)
	{
		ReplyToCommand(client, "sm_fkban");
		return Plugin_Handled;
	}
	
	if(client > 0)
	{
		Menu menu = new Menu(fkBanMenu);
		menu.SetTitle("FK-Ban Spieler:");
		
		char sName[MAX_NAME_LENGTH];
		char sBuffer[MAX_NAME_LENGTH];
		
		LoopClients(i)
		{
			if(!IsFakeClient(i) && !IsClientSourceTV(i) && CanTargetPlayer(client, i))
			{
				GetClientName(i, sName, sizeof(sName));
				
				if(g_bFKBan[i])
					Format(sBuffer, sizeof(sBuffer), "[X] %s", sName);
				else
					Format(sBuffer, sizeof(sBuffer), "[ ] %s", sName);
				
				menu.AddItem(sName, sBuffer);
			}
		}
		
		menu.Display(client, MTF);
	}
	
	return Plugin_Handled;
}

public int fkBanMenu(Menu menu, MenuAction action, int client, int param)
{
	if(action == MenuAction_Select)
	{
		char sName[MAX_NAME_LENGTH];
		menu.GetItem(param, sName, sizeof(sName));
		
		int iTarget = FindTarget(client, sName, true, false);
		
		if(iTarget == -1)
		{
			CPrintToChat(client, "%s Spieler nicht gefunden.", OUTBREAK);
		}
		else
		{
			int iTick = SourceTV_GetRecordingTick();
	
			char sACom[32], sVCom[32], sMap[32];
			GetCurrentMap(sMap, sizeof(sMap));
			GetClientAuthId(iTarget, AuthId_SteamID64, sVCom, sizeof(sVCom));
			GetClientAuthId(client, AuthId_SteamID64, sACom, sizeof(sACom));
			
			if(!g_bFKBan[iTarget])
			{
				g_bFKBan[iTarget] = true;
				
				CPrintToChatAll("%s %s%N %shat von %s%N %seinen !fk-Ban erhalten!", OUTBREAK, SPECIAL, iTarget, TEXT, SPECIAL, client, TEXT);
			}
			else
			{
				g_bFKBan[iTarget] = false;
				CPrintToChatAll("%s %s%N %shat von %s%N %sden !fk-Ban entfernt!", OUTBREAK, SPECIAL, client, TEXT, SPECIAL, iTarget, TEXT);
			}
			
			if(!g_bFKSQL[iTarget])
			{
				char sQuery[512];
				g_dDB.Format(sQuery, sizeof(sQuery), "INSERT INTO `freekill_bans` (`date`, `map`, `tick`, `vCommunityid`, `vName`, `aCommunityid`, `aName`, `banned`) VALUES (UNIX_TIMESTAMP(), \"%s\", %d, \"%s\", \"%N\", \"%s\", \"%N\", '1');", sMap, iTick, sVCom, iTarget, sACom, client);
				g_dDB.Query(Freekill_InsertQueryBans, sQuery);
				g_bFKSQL[iTarget] = true;
			}
			else
			{
				char sQuery[512];
				g_dDB.Format(sQuery, sizeof(sQuery), "UPDATE freekill_bans SET date = UNIX_TIMESTAMP(), map = \"%s\", tick = '%d', vName = \"%N\", aCommunityid = \"%s\", aName = \"%N\", banned = '%d' WHERE vCommunityid = \"%s\";", sMap, iTick, iTarget, sACom, client, g_bFKBan[iTarget], sVCom);
				g_dDB.Query(Freekill_UpdateQueryBans, sQuery);
			}
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

void Freekill_OnPluginStart()
{
	g_aClient = CreateArray(32); // Warum nicht MAX_NAME_LENGTH wenn schon Namen gespeichert werden? Was ist wenn einer sein Name aendert?
	g_aAttacker = CreateArray(32); // Warum nicht MAX_NAME_LENGTH wenn schon Namen gespeichert werden? Was ist wenn einer sein Name aendert?
}

void Freekill_OnClientCookiesCached(int client)
{
	OnClientPostAdminCheck(client);
}

void Freekill_PlayerDeath(int client, int attacker)
{
	char sClient[MAX_NAME_LENGTH];
	char sAttacker[MAX_NAME_LENGTH];
	
	GetClientName(client, sClient, sizeof(sClient));
	GetClientName(attacker, sAttacker, sizeof(sAttacker));
	
	if(GetClientTeam(client) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT)
	{
		g_aClient.PushString(sClient); // Waere es nicht sinnvoller die UserID (GetClientUserId) (nicht client Index(!)) zu speichern, bzgl. Namensaenderung?
		g_aAttacker.PushString(sAttacker); // Waere es nicht sinnvoller die UserID (GetClientUserId) (nicht client Index(!)) zu speichern, bzgl. Namensaenderung?
	}
}

void Freekill_RoundStart()
{
	g_aClient.Clear();
	g_aAttacker.Clear();
}

void ResetFreekill(int client)
{
	g_bFreekill[client] = false;
}

void Freekill_GetStatus(int client)
{
	char sQuery[512], sCom[32];
	GetClientAuthId(client, AuthId_SteamID64, sCom, sizeof(sCom));
	g_dDB.Format(sQuery, sizeof(sQuery), "SELECT banned FROM freekill_bans WHERE vCommunityid = \"%s\";", sCom);
	g_dDB.Query(Freekill_GetStatusQuery, sQuery, GetClientUserId(client));
}
