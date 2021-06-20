#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <outbreak>
#include <clientprefs>
#pragma newdecls optional
#include <stamm>
#include <emitsoundany>
#include <menu-stocks>
#include <multicolors>
#include <lastrequest>
#include <jailDice>
#include <playerplaytime>

#undef REQUIRE_EXTENSIONS
#include <sourcetvmanager>

#pragma newdecls required

#define PL_NAME "jailSystem"

Handle g_hOnMySQLConnect = null;
Database g_dDB = null;

// CT Boost
ConVar g_cBoost = null;
ConVar g_cHPMulti = null;

#include "jailSystem/jailSystem_ergeben.sp"
#include "jailSystem/jailSystem_verweigern.sp"
#include "jailSystem/jailSystem_freedayteams.sp"
#include "jailSystem/jailSystem_teamdamage.sp"
#include "jailSystem/jailSystem_freeday.sp"
#include "jailSystem/jailSystem_newBeacon.sp"
#include "jailSystem/jailSystem_freekill.sp"
#include "jailSystem/jailSystem_spawnweapons.sp"
#include "jailSystem/jailSystem_kill.sp"
// #include "jailSystem/jailSystem_showdamage.sp"
#include "jailSystem/jailSystem_lrStammpunkte.sp"
#include "jailSystem/jailSystem_extraStammpunkte.sp"
#include "jailSystem/jailSystem_mysql.sp"
#include "jailSystem/jailSystem_ctboost.sp"
#include "jailSystem/jailSystem_voicemenu.sp"

static int g_iRed = 0;
static int g_iGreen = 0;
static int g_iBlue = 0;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hOnMySQLConnect = CreateGlobalForward("jailSystem_OnMySQLCOnnect", ET_Ignore, Param_Cell);
	
	CreateNative("jailSystem_GetDatabase", Native_GetDatabase);
	
	RegPluginLibrary("jailSystem");
	
	return APLRes_Success;
}
public Plugin myinfo =
{
	name = "[Outbreak] JailSystem", 
	author = "Bara (Based of the version by Dive)", 
	description = "", 
	version = "1.0", 
	url = "outbreak-community.de"
};

public void OnPluginStart()
{
	MySQL_OnPluginStart();
	Teamdamage_OnPluginStart();
	Freekill_OnPluginStart();
	Kill_OnPluginStart();
	VoiceMenu_OnPluginStart();
	Spawnweapons_OnPluginStart();

	LoadTranslations("common.phrases");

	RegConsoleCmd("sm_e", Command_ergeben);
	RegConsoleCmd("sm_v", Command_verweigern);
	RegConsoleCmd("sm_vreset", Command_vreset);
	RegConsoleCmd("sm_teamdamage", Command_teamdamage);
	RegConsoleCmd("sm_td", Command_teamdamage);
	RegConsoleCmd("sm_fd", Command_freeday);
	RegConsoleCmd("sm_kill", Command_kill);
	RegConsoleCmd("sm_fk", Command_freekill);
	RegConsoleCmd("sm_noob", Command_Noob);
	
	Handle hCvar = FindConVar("mp_teammates_are_enemies");
	int flags = GetConVarFlags(hCvar);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(hCvar, flags);
	delete hCvar;
	
	RegAdminCmd("sm_fkban", Command_fkBan, ADMFLAG_GENERIC);
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	// HookEvent("player_hurt", PlayerHurt);
	
	g_cHPMulti = CreateConVar("jailsystem_hp_multi", "10.2842");
	g_cBoost = CreateConVar("jailsystem_ctboost", "1");

	NewBeacon_OnPluginStart();

	LoopClients(client)
	{
		OnClientCookiesCached(client);
	}
}

public void OnMapStart()
{
	Freeday_OnMapStart();
	Freekill_OnMapStart();
}

public void OnClientCookiesCached(int client)
{
	Freekill_OnClientCookiesCached(client);
	NewBeacon_OnClientCookiesCached(client);
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Freedayteams_RoundStart();
	Freekill_RoundStart();
	LrStammpunkte_RoundStart();
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Teamdamage_RoundEnd();
	LrStammpunkte_RoundEnd();
	
	LoopClients(client)
	{
		ResetErgeben(client);
		ResetVerweigern(client);
		ResetFreeday(client);
		ResetFreekill(client);
		ResetSpawnweapons(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsClientValid(client) && g_dDB != null)
		Freekill_GetStatus(client);
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		ResetErgeben(client);
		ResetVerweigern(client);
		ResetFreeday(client);
		ResetFreekill(client);
		
		Spawnweapons_PlayerSpawn(client);
		NewBeacon_PlayerSpawn(client);
		CTBoost_PlayerSpawn(client);
		VoiceMenu_ResetSettings(client);
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	LrStammpunkte_PlayerDeath();

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(IsClientValid(client))
	{
		CPrintToChat(client, "%s Zu früh gestorben? Es gibt auch Minispiele wie %s!tetris, !snake %sund %s!pong", OUTBREAK, SPECIAL, TEXT, SPECIAL);
		if(IsClientValid(attacker))
		{
			Freekill_PlayerDeath(client, attacker);
		}
	}
}

/* public Action PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if(IsClientValid(attacker))
	{
		int damage = event.GetInt("dmg_health");
		
		Showdamage_PlayerHurt(attacker, damage);
	}
} */

public void OnClientDisconnect(int client)
{
	ResetErgeben(client);
	ResetVerweigern(client);
	ResetFreeday(client);
	ResetFreekill(client);
	ResetSpawnweapons(client);
	ResetClientLrStammpunkte(client);
	NewBeacon_OnClientDisconnect(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (!IsClientValid(client))
	{
		return Plugin_Continue;
	}

	if(IsPlayerAlive(client))
	{
		CS_SetClientContributionScore(client, 1);
	}
	else
	{
		CS_SetClientContributionScore(client, 0);
	}
	
	if(IsPlayerAlive(client) && g_bFreeday[client])
	{
		if(buttons & IN_JUMP)
		{
			if(!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
				
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					buttons &= ~IN_JUMP;
				}
			}
		}
	}

	return Plugin_Continue;
}
