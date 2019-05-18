#include <sourcemod>
#include <zombiereloaded>
#include <clientprefs>
#include <colorvariables>

bool g_ToggleShowDamage[MAXPLAYERS+1];
Handle g_hClientCookie = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[ZR] Show Damage",
	author = "Franc1sco, Modified by. Someone",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	g_hClientCookie = RegClientCookie("ShowDamage", "Toggle show damage", CookieAccess_Private);
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (!AreClientCookiesCached(i))
		{
			continue;
		}
		OnClientCookiesCached(i);
	}
	HookEvent("player_hurt", Event_PlayerHurt);
	
	RegConsoleCmd("sm_sd", Command_sd);
}

public OnClientCookiesCached(client)
{
	char sValue[8];
	GetClientCookie(client, g_hClientCookie, sValue, sizeof(sValue));
	
	g_ToggleShowDamage[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public OnClientPutInServer(client)
{
	if (!AreClientCookiesCached(client))
	{
		g_ToggleShowDamage[client] = false;
	}
}

public Action Command_sd(client, args)
{
	if (!IsClientInGame(client) || !client)
		return Plugin_Handled;
		
	if (!g_ToggleShowDamage[client])
	{
		g_ToggleShowDamage[client] = true;
		char sCookieValue[12];
		IntToString(1, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hClientCookie, sCookieValue);
		CPrintToChat(client, "{green}[ToggleShowDMG]{default} Enabled.");
	}
	else
	{
		g_ToggleShowDamage[client] = false;
		char sCookieValue[12];
		IntToString(0, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hClientCookie, sCookieValue);
		CPrintToChat(client, "{green}[ToggleShowDMG]{default} Disabled.");
	}
	return Plugin_Handled;
}

public OnClientDisconnect_Post(client)
{
	g_ToggleShowDamage[client] = false;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!g_ToggleShowDamage[attacker])
		return;
	
	if(!attacker)
		return;

	if(GetClientTeam(attacker) == 2 || ZR_IsClientZombie(attacker))
		return;
		
	if(attacker == client)
		return;
	
	new restante = GetClientHealth(client);
	decl String:input[512];
	
	if(restante > 0)
	{
		new damage = GetEventInt(event, "dmg_health");
		Format(input, 512, "<font class='fontSize-l'>You did <font color='#FF0000'>%i <font color='#FFFFFF'>Damage to <font color='#0066FF'>%N\n<font color='#FFFFFF'>Health Remaining: <font color='#00CC00'>%i", damage, client, restante);
	}
	PrintHintText(attacker, input);
}