#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>
#include <colorvariables>

#define PLUGIN_NAME "[ZR] Repeat Kill Detector"
#define PLUGIN_VERSION "1.0.3"

new Handle:g_hCvar_RepeatKillDetectThreshold = INVALID_HANDLE;
new Float:g_fRepeatKillDetectThreshold;

new Handle:g_hRespawnDelay = INVALID_HANDLE;
new Float:g_fDeathTime[MAXPLAYERS+1];
new bool:g_bBlockRespawn = false;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "GoD-Tony + BotoX",
	description = "Disables respawning on maps with repeat killers",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnAllPluginsLoaded()
{
	if((g_hRespawnDelay = FindConVar("zr_respawn_delay")) == INVALID_HANDLE)
		SetFailState("Failed to find zr_respawn_delay cvar.");

	g_hCvar_RepeatKillDetectThreshold = CreateConVar("zr_repeatkill_threshold", "1.0", "Zombie Reloaded Repeat Kill Detector Threshold", 0, true, 0.0, true, 10.0);
	g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	HookConVarChange(g_hCvar_RepeatKillDetectThreshold, OnConVarChanged);

	CreateConVar("zr_repeatkill_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);

	AutoExecConfig(true, "plugin.RepeatKillDetector");
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == g_hCvar_RepeatKillDetectThreshold)
	{
		g_fRepeatKillDetectThreshold = GetConVarFloat(g_hCvar_RepeatKillDetectThreshold);
	}
}

public OnClientDisconnect(client)
{
	g_fDeathTime[client] = 0.0;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bBlockRespawn = false;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bBlockRespawn)
		return;

	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(victim && !attacker && StrEqual(weapon, "trigger_hurt"))
	{
		new Float:fGameTime = GetGameTime();

		if(fGameTime - g_fDeathTime[victim] - GetConVarFloat(g_hRespawnDelay) < g_fRepeatKillDetectThreshold)
		{
			CPrintToChatAll("{green}[ZR]{lightred} Repeat killer detected. Disabling respawn for this round.");
			g_bBlockRespawn = true;
		}

		g_fDeathTime[victim] = fGameTime;
	}
}

public Action:ZR_OnClientRespawn(&client, &ZR_RespawnCondition:condition)
{
	if(g_bBlockRespawn)
		return Plugin_Handled;

	return Plugin_Continue;
}
