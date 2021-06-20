#define MSGCOUNT 10

void Freedayteams_RoundStart()
{
	int iCTCount = GetTeamClientCount(CS_TEAM_CT);
	int iTCount = GetTeamClientCount(CS_TEAM_T);
	
	if(iCTCount > 1 && iTCount > 1)
	{
		int iFreedayteams = iTCount / 2;
	
		if(iFreedayteams < iCTCount)
		{
			for(int i = 0; i < MSGCOUNT; i++)
			{
				CPrintToChatAll("%s %sFreeday! Grund: Freeday Teams (allg. Jail Regeln 6.2)", OUTBREAK, SPECIAL);
				CPrintToChatAll("%sEs gelten allgemeine Freeday Regeln!", SPECIAL);
			}
		}
		else
		{
			for(int i = 0; i < MSGCOUNT; i++)
			{
				// PrintToChatAll("%s \x09Diese Runde sind keine Freeday - Teams!!!", OB);
			}
		}
	}
}
