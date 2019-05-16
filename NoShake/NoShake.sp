#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdkhooks>
#include <clientprefs>

#pragma newdecls required

Handle g_hNoShakeCookie;
ConVar g_Cvar_NoShakeGlobal;

bool g_bNoShake[MAXPLAYERS + 1] = {false, ...};
bool g_bNoShakeGlobal = false;

public Plugin myinfo =
{
	name 			= "NoShake",
	author 			= "BotoX",
	description 	= "Disable env_shake",
	version 		= "1.0.1",
	url 			= ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_shake", Command_Shake, "[NoShake] Disables or enables screen shakes.");
	RegConsoleCmd("sm_noshake", Command_Shake, "[NoShake] Disables or enables screen shakes.");

	g_hNoShakeCookie = RegClientCookie("noshake_cookie", "NoShake", CookieAccess_Protected);

	g_Cvar_NoShakeGlobal = CreateConVar("sm_noshake_global", "0", "Disable screenshake globally.", 0, true, 0.0, true, 1.0);
	g_bNoShakeGlobal = g_Cvar_NoShakeGlobal.BoolValue;
	g_Cvar_NoShakeGlobal.AddChangeHook(OnConVarChanged);

	HookUserMessage(GetUserMessageId("Shake"), MsgHook, true);
}

public void OnClientCookiesCached(int client)
{
	static char sCookieValue[2];
	GetClientCookie(client, g_hNoShakeCookie, sCookieValue, sizeof(sCookieValue));
	g_bNoShake[client] = StringToInt(sCookieValue) != 0;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(StringToInt(newValue) > StringToInt(oldValue))
		PrintToChatAll("\x03[NoShake]\x01 Enabled NoShake globally!");
	else if(StringToInt(newValue) < StringToInt(oldValue))
		PrintToChatAll("\x03[NoShake]\x01 Disabled NoShake globally!");

	g_bNoShakeGlobal = StringToInt(newValue) != 0;
}

public Action MsgHook(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	char map[128];
    GetCurrentMap(map, 128);
	if(StrContains(map, "zm_", false) != -1)
		return Plugin_Continue;

	if(playersNum == 1 && (g_bNoShakeGlobal || g_bNoShake[players[0]]))
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public Action Command_Shake(int client, int args)
{
	if(g_bNoShakeGlobal)
		return Plugin_Handled;

	if(!AreClientCookiesCached(client))
	{
		ReplyToCommand(client, "\x03[NoShake]\x01 Please wait. Your settings are still loading.");
		return Plugin_Handled;
	}

	if(g_bNoShake[client])
	{
		g_bNoShake[client] = false;
		ReplyToCommand(client, "\x03[NoShake]\x01 has been disabled!");
	}
	else
	{
		g_bNoShake[client] = true;
		ReplyToCommand(client, "\x03[NoShake]\x01 has been enabled!");
	}

	static char sCookieValue[2];
	IntToString(g_bNoShake[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, g_hNoShakeCookie, sCookieValue);

	return Plugin_Handled;
}

