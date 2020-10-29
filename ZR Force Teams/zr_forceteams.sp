#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <cstrike>

bool started;

ConVar g_HE_Amount;
ConVar g_HE_Enable;

public Plugin myinfo =
{
	name = "[ZR] Force Teams",
	author = "Franc1sco franug, simpson0141, Modified by. Someone",
	description = "",
	version = "2.5",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart() 
{
	g_HE_Enable = CreateConVar("HE_Enable", "1");
	g_HE_Amount = CreateConVar("HE_Amount", "3");

	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
	
	AutoExecConfig();
}

public Action EventPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(1.0, GiveWeapons, client);
	
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if(!started)
		if(GetClientTeam(client) == CS_TEAM_T)
			CS_SwitchTeam(client, CS_TEAM_CT);
	
	return Plugin_Continue;
}

public Action GiveWeapons(Handle timer, any client)
{
	if(!IsClientInGame(client)) return;
	if(!IsPlayerAlive(client)) return;

	int knife = GetPlayerWeaponSlot(client, 2);
	int pistol = GetPlayerWeaponSlot(client, 1);
	int rifle = GetPlayerWeaponSlot(client, 0);
	
	if(!IsValidEdict(knife))
		FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_knife"));
		
	if(ZR_IsClientHuman(client))
	{
		if(g_HE_Enable.BoolValue)
			GiveGrenade(client, g_HE_Amount.IntValue);
				
		if(!IsValidEdict(pistol))
			FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_elite"));
			
		if(!IsValidEdict(rifle))
			FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_bizon"));
	}
	else return;
}

public Action EventRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	started = false;

	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if(GetClientCount() > 1)
		ServerCommand("mp_ignore_round_win_conditions 1");
	
	return Plugin_Continue;
}

public Action EventRoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{
	started = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(!started)
	{
		ServerCommand("mp_ignore_round_win_conditions 0");
		
		started = true;
	}
	CreateTimer(1.0, GiveKnife, client);
}

public Action GiveKnife(Handle timer, any client)
{
	if(!IsClientInGame(client)) return;
	if(!IsPlayerAlive(client)) return;
	
	int knife = GetPlayerWeaponSlot(client, 2);
	
	if(!IsValidEdict(knife))
		FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_knife"));
	else return;
}

public void GiveGrenade(client, amount)
{
	int offset2 = FindDataMapInfo(client, "m_iAmmo")+(4*14);
	int current2 = GetEntData(client, offset2,4);
	
	if (current2 == 0)
		GivePlayerItem(client, "weapon_hegrenade");
	
	SetEntData(client, offset2, amount);
}