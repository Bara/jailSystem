void CTBoost_PlayerSpawn(int client)
{
	if (g_cBoost.BoolValue && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		int iT = GetTeamClientCount(CS_TEAM_T);
		int iCT = GetTeamClientCount(CS_TEAM_CT);
		
		// Health
		int iHP = RoundToCeil(iT / iCT * g_cHPMulti.FloatValue);
		int iNewHP = GetClientHealth(client) + iHP;
		SetEntityHealth(client, iNewHP);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", iNewHP);
		
		
		// Armor
		SetEntProp(client, Prop_Send, "m_ArmorValue", GetEntProp(client, Prop_Send, "m_ArmorValue") + 110);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}
}