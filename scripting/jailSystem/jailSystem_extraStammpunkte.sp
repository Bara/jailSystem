public Action STAMM_OnClientGetPoints_PRE(int client, int &points)
{
	if(!IsClientValid(client))
	{
		return Plugin_Continue;
	}
	
	bool changed = false;
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		points *= 2;
		CPrintToChat(client, "%sSie bekommen für das Spielen als CT's die %sdoppelte %sStammpunkte!", TEXT, SPECIAL, TEXT);
		changed = true;
	}
	
	char sName[64], sTag[32];
	GetClientName(client, sName, sizeof(sName));
	CS_GetClientClanTag(client, sTag, sizeof(sTag));
	
	if(
	(StrContains(sName, "outbreak-community.de", false) != -1) || (StrContains(sName, "outbreak.community", false) != -1) || // Name Check
	(StrEqual(sTag, ".#Outbreak", false))
	)
	{
		int iPoints = GetRandomInt(1, 3);
		
		points += iPoints;
		
		CPrintToChat(client, "%s Sie haben für das Tragen des Community Tags %s%d %szusätzliche Stammpunkte bekommen!", OUTBREAK, SPECIAL, iPoints, TEXT);
		
		changed = true;
	}
	
	if(!changed)
	{
		return Plugin_Continue;
	}
	else
	{
		return Plugin_Changed;
	}
}