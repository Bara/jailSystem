#define TIME_ERGEBEN 30.0

bool g_bErgeben[MAXPLAYERS + 1] =  { false, ... };

Handle g_hErgebenTimer[MAXPLAYERS+1] =  { null, ... };


public Action Command_ergeben(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client))
		{
			if(!g_bErgeben[client])
			{
				if (Outbreak_IsClientAssassine(client))
				{
					ForcePlayerSuicide(client);
					CPrintToChatAll("%s %s%N %swollte sich als Assassine ergeben!", OUTBREAK, SPECIAL, client, TEXT);
					return Plugin_Handled;
				}

				g_bErgeben[client] = true;
				CPrintToChatAll("%s %s%N %shat sich ergeben!", OUTBREAK, SPECIAL, client, TEXT);
				
				SetEntityRenderMode(client, RENDER_TRANSCOLOR);
				SetEntityRenderColor(client, 75, 255, 75, 255);
				
				g_hErgebenTimer[client] = CreateTimer(TIME_ERGEBEN, ErgebenTimer, client);
				
				SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUseErgeben);
				
				ChangeRebelStatus(client, false);
				
				for(int i = CS_SLOT_PRIMARY; i <= CS_SLOT_C4; i++)
				{
					int index = -1;
					while((index = GetPlayerWeaponSlot(client, i)) != -1)
					{
						SafeRemoveWeapon(client, index);
					}
				}
			}
			else
			{
				CPrintToChat(client, "%s Du bist bereits ergeben.", OUTBREAK);
			}
		}
		else
		{
			CPrintToChat(client, "%s Du bist tot oder kein Terrorist.", OUTBREAK);
		}
	}
	
	return Plugin_Handled;
}

public Action ErgebenTimer(Handle timer, any client)
{
	if(IsClientValid(client) && g_hErgebenTimer[client] != null)
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		
		SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUseErgeben);
		g_bErgeben[client] = false;
		
		if (!Outbreak_LoseAll(client))
		{
			int iKnife = GivePlayerItem(client, "weapon_knife");
			EquipPlayerWeapon(client, iKnife);
		}
	}
	
	g_hErgebenTimer[client] = null;
	return Plugin_Stop;
}

public Action OnWeaponCanUseErgeben(int client, int weapon)
{
	if(g_bErgeben[client])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void ResetErgeben(int client)
{
	g_bErgeben[client] = false;
	delete g_hErgebenTimer[client];
}