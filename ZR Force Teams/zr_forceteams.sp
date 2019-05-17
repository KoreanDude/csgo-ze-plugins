#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <colorvariables>
#include <cstrike>

bool started;
int ctscore;
int trscore;

ConVar g_HE_Amount;
ConVar g_HE_Enable;
ConVar g_Elite_Enable;

public Plugin myinfo =
{
	name = "[ZR] Force Teams",
	author = "Franc1sco franug, simpson0141, Modified by. Someone",
	description = "",
	version = "2.3",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart() 
{
	g_Elite_Enable = CreateConVar("Elite_Enable", "1");
	g_HE_Enable = CreateConVar("HE_Enable", "1");
	g_HE_Amount = CreateConVar("HE_Amount", "3");

	HookEvent("player_spawn", OnSpawn, EventHookMode_Post);
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
	
	AutoExecConfig();
}

public Action OnSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!started)
		if(GetClientTeam(client) == CS_TEAM_T) CS_SwitchTeam(client, CS_TEAM_CT);
	
	CreateTimer(1.0, GiveWeapons, client);
}

public Action GiveWeapons(Handle timer, any client)
{
	if(!IsClientInGame(client)) return;
	if(!IsPlayerAlive(client)) return;

	new pistol = GetPlayerWeaponSlot(client, 1);
	new knife = GetPlayerWeaponSlot(client, 2);
	
	if(!IsValidEdict(knife))
		FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_knife"));
		
	if(ZR_IsClientHuman(client))
	{
		if(g_HE_Enable.BoolValue) Grenade(client, g_HE_Amount.IntValue);
		
		if(!IsValidEdict(pistol))
			if(g_Elite_Enable.BoolValue) FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_elite"));
	}
	else return;
}

public Action EventRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	ctscore = GetTeamScore(3);
	trscore = GetTeamScore(2);
	
	started = false;
}

public Action EventRoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{
	CreateTimer(1.0, Check);
}

public Action Check(Handle timer)
{
	started = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(!started) started = true;
	
	CreateTimer(1.0, GiveWeapons2, client);
}

public Action GiveWeapons2(Handle timer, any client)
{
	if(!IsClientInGame(client)) return;
	if(!IsPlayerAlive(client)) return;
	
	new knife = GetPlayerWeaponSlot(client, 2);
	
	if(!IsValidEdict(knife))
		FakeClientCommand(client, "use %d", GivePlayerItem(client, "weapon_knife"));
	else return;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(reason == CSRoundEnd_GameStart)
		CreateTimer(1.0, Check);
	
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	else
		CreateTimer(1.0, Check);
	
	if(!started)
	{
		int count;
	
		for (int i = 1; i <= MaxClients; i++) 
			if (IsClientInGame(i) && IsPlayerAlive(i))
				count++;
	
		if(count > 0)
		{
			SetTeamScore(3, ctscore);
			SetTeamScore(2, trscore);
			return Plugin_Handled;
		}
	}
	else return Plugin_Continue;
	
	return Plugin_Continue;
}

public Grenade(client, amount)
{
	new offset2 = FindDataMapInfo(client, "m_iAmmo")+(4*14);
	new current2 = GetEntData(client, offset2,4);
	if (current2 == 0) GivePlayerItem(client, "weapon_hegrenade");
	SetEntData(client, offset2, amount);
}