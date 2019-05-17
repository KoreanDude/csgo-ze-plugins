#include <sourcemod>
#include <zombiereloaded>
#include <colorvariables>

public Plugin:myinfo = 
{
	name = "[ZR] No Alone Infection & No Armor",
	author = "DSASDFGH, REZOR, Modified by. Someone",
	description = "",
	version = "1.1",
	url = ""
}

ConVar g_InfectionEnabled;
ConVar g_InfectionMinPlayer;

public OnPluginStart()
{
	g_InfectionEnabled = CreateConVar("zr_infectenabled", "1", "1 - Yes, 0 - No", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_InfectionMinPlayer = CreateConVar("zr_infectmin", "3", "MinPlayer", FCVAR_NOTIFY, true, 0.0, true, 64.0);

	HookEvent("player_spawn", OnSpawn);
	
	AutoExecConfig();
}

public Action:ZR_OnClientInfect(&client, &attacker, &bool:motherInfect, &bool:respawnOverride, &bool:respawn)
{
	new players = GetClientCount(true);
	
	if (!g_InfectionEnabled.BoolValue)
	{
		CPrintToChatAll("{green}[ZR]{lightred} infect is disabled.");
		return Plugin_Handled;
	}
	
	if (players <= g_InfectionMinPlayer.IntValue)
	{
		CPrintToChatAll("{green}[ZR]{lightred} There aren't enough players to create a zombie.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	
	if (IsPlayerAlive(client))
		SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
}

public Action OnSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	
	if (IsPlayerAlive(client))
		if (ZR_IsClientHuman(client))
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
}