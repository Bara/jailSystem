public Action Command_kill(int client, int args)
{
	if(IsClientValid(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
		{
			if(IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
				
				CPrintToChatAll("%s %s%N %shat sich selbst erschlagen!", OUTBREAK, SPECIAL, client, TEXT);
			}
			else
			{
				CPrintToChat(client, "%s Das ergibt keinen Sinn..?!", OUTBREAK);
			}
		}
		else
		{
			CPrintToChat(client, "%s Das ergibt keinen Sinn..?!", OUTBREAK);
		}
	}
	
	return Plugin_Handled;
}

public Action ConsoleKill(int client, const char[] command, int argc)
{
	if(IsClientValid(client) && IsPlayerAlive(client))
	{
		CPrintToChatAll("%s %s%N %shat sich selbst erschlagen!", OUTBREAK, SPECIAL, client, TEXT);
	}
}

void Kill_OnPluginStart()
{
	AddCommandListener(ConsoleKill, "kill");
}