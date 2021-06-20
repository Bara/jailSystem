static int g_iTimeT = 14400;
static Handle g_hCookie = null;
static g_bHide[MAXPLAYERS + 1] = { false , ...};

void NewBeacon_OnPluginStart()
{
    g_hCookie = RegClientCookie("newbeacon_hide", "Enable/Disable NoobGlow", CookieAccess_Private);
}

void NewBeacon_OnClientCookiesCached(int client)
{
	char sBuffer[4];
	GetClientCookie(client, g_hCookie, sBuffer, sizeof(sBuffer));
	g_bHide[client] = view_as<bool>(StringToInt(sBuffer));
}

void NewBeacon_PlayerSpawn(int client)
{
    CreateTimer(3.0, Timer_GlowAd, GetClientUserId(client));
}

public Action Timer_GlowAd(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (IsClientValid(client) && PlayerPlayTime_GetPlayerTimeT(client) <= g_iTimeT)
    {
        CPrintToChat(client, "%s Du kannst mit %s!Noob %sdein Glow de/aktivieren.", OUTBREAK, SPECIAL, TEXT);
    }
}

public Action Command_Noob(int client, int args)
{
    if(!IsClientValid(client))
    {
        return Plugin_Handled;
    }

    if (PlayerPlayTime_GetPlayerTimeT(client) > g_iTimeT)
    {
        CPrintToChat(client, "%s Das macht kein Sinn mehr...", OUTBREAK);
        return Plugin_Handled;
    }

    if (g_bHide[client])
    {
        g_bHide[client] = false;
        CPrintToChat(client, "%s Dein Glow sollte wieder sichtbar sein.", OUTBREAK);
    }
    else
    {
        g_bHide[client] = true;
        CPrintToChat(client, "%s Dein Glow sollte nicht mehr sichtbar sein.", OUTBREAK);
    }

    char sBuffer[4];
    IntToString(g_bHide[client], sBuffer, sizeof(sBuffer));
    SetClientCookie(client, g_hCookie, sBuffer);

    return Plugin_Handled;
}

void NewBeacon_OnClientDisconnect(int client)
{
	if(AreClientCookiesCached(client))
	{
		char sBuffer[4];
		IntToString(g_bHide[client], sBuffer, sizeof(sBuffer));
		SetClientCookie(client, g_hCookie, sBuffer);
	}
}

public Action OnGlowCheck(int client, int target, bool &seeTarget, bool &overrideColor, int &red, int &green, int &blue, int &alpha)
{
    if (GetClientTeam(target) == CS_TEAM_T && IsPlayerAlive(target) && !g_bHide[target] && PlayerPlayTime_GetPlayerTimeT(target) <= g_iTimeT)
    {
        overrideColor = true;

        red = 0;
        green = 255;
        blue = 255;
        alpha = 255;

        seeTarget = true;

        return Plugin_Changed;
    }

    return Plugin_Handled;
}
