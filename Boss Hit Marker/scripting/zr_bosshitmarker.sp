#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define LINES 32
#pragma newdecls required

char Buffer[LINES][64];
Handle BossName = INVALID_HANDLE;

public Plugin myinfo = {
	name = "[ZR] Boss Hit Marker",
	author = "null, Modified by. Someone",
	description = "[ZR] Boss Hit Marker",
}

public void OnPluginStart()
{
	HookEntityOutput("math_counter", "OutValue", DamageCounter);
}

public void OnMapStart()
{
	for (int i = 0; i <= (LINES - 1); i++)
		Buffer[i] = "";

	char path[PLATFORM_MAX_PATH];
	char Line[64];

	char CurrentMap[128];
	GetCurrentMap(CurrentMap, 128);

    BuildPath(Path_SM, path, sizeof(path), "configs/bossname/%s.cfg", CurrentMap); //path of cfg

	Handle hFile = OpenFile(path, "r");

	if(hFile != INVALID_HANDLE)
	{
		int iLine = 0;
		while (!IsEndOfFile(hFile))
		{
			if (!ReadFileLine(hFile, Line, sizeof(Line)))
				break;
				
            int comment;
		    comment = StrContains(Line, "//");
		    if (comment != -1)
			{
			    Line[comment] = 0;
		    }
		    
			TrimString(Line);
			Buffer[iLine] = Line;
			iLine++;
		}
	    CloseHandle(hFile);
	}
	else
	{
		LogMessage("[BHM] This map does not have a config.");
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_physbox", false) || StrEqual(classname, "func_physbox_multiplayer", false) || StrEqual(classname, "func_breakable", false))
	{
		if (IsValidEntity(entity)) SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void DamageCounter(const char[] output, int caller, int activator, float delay)
{	
	if(!IsBossEntity(caller))
        return; 
    
    if(IsValidEntity(caller))
	{  
        char cname4[32];
        GetEntPropString(caller, Prop_Data, "m_iName", cname4, sizeof(cname4));
        if(strlen(cname4) == 0)
	       return;
		
		BossName = CreateDataPack();
		WritePackCell(BossName, caller);
	}
}

public Action OnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(BossName == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}
	ResetPack(BossName);
	int caller = ReadPackCell(BossName);
	CloseHandle(BossName);
	BossName = INVALID_HANDLE;
	
	if (IsBossEntity(caller) && IsValidEntity(entity) && IsValidClient(attacker) ||
	    IsBossEntity(entity) && IsValidEntity(entity) && IsValidClient(attacker))
	{
		SetHudTextParams(-1.0, -1.0, 0.1, 255, 0, 0, 0, 0, 6.0, 0.0, 0.0);
	    ShowHudText(attacker, GetDynamicChannel(5), "X");
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

stock bool IsBossEntity(int entity)
{
	char cname[64];
	GetEntPropString(entity, Prop_Data, "m_iName", cname, sizeof(cname));
	for (int i = 0; i <= (LINES - 1); i++)
	{
        if (StrEqual(cname, Buffer[i], false))
		{
            return true;
        }
    }    
	return false;
}
