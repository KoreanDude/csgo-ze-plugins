#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define LINES 32
#pragma newdecls required

char Buffer[LINES][64];
int Hits[MAXPLAYERS+1];
bool roundend;

bool BossEntityDestroyed;

public Plugin myinfo = {
	name = "[ZR] Boss Hit Rank",
	author = "null, Modified by. Someone",
	description = "Boss Hit Rank",
}

public void OnPluginStart()
{
	HookEntityOutput("math_counter", "OutValue", DamageCounter);
	
    HookEvent("round_start", RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", RoundEnd, EventHookMode_PostNoCopy);
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
		ServerCommand("sm_cvar zr_roundend_overlay 0");
		
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
		LogMessage("[BHR] This map does not have a config.");
		ServerCommand("sm_cvar zr_roundend_overlay 1");
	}
}

public void RoundStart(Event event, char[] name, bool dontBroadcast)
{
	roundend = false;
	
    for (int i = 1; i <= MaxClients; i++)
	{	
        Hits[i] = 0;
    }
}

public void RoundEnd(Event event, char[] name, bool dontBroadcast)
{
	if(BossEntityDestroyed)
	{
		PrintBossHitRanks();
	}
	
	BossEntityDestroyed = false;
	roundend = true;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_physbox", false) || StrEqual(classname, "func_physbox_multiplayer", false) || StrEqual(classname, "func_breakable", false))
	{
		if (IsValidEntity(entity))
		{
            if(!IsBossEntity(entity))
                return;
			
		    SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	    }
    }
}

public Action OnTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{	
    if(!IsBossEntity(entity))
        return;
		
	char cname[32];
	
	GetEntPropString(entity, Prop_Data, "m_iName", cname, sizeof(cname));

	if(strlen(cname) == 0)
		return;
    
	if (IsValidEntity(entity) && IsValidClient(attacker))
	{
		Hits[attacker] += 1;
	}
} 

public void OnEntityDestroyed(int entity)
{
	char classname2[32];
	char cname3[32];
	
	if (IsValidEntity(entity))
	{
		GetEntityClassname(entity, classname2, sizeof(classname2));
		GetEntPropString(entity, Prop_Data, "m_iName", cname3, sizeof(cname3));
	
	    if(strlen(cname3) == 0)
	        return;
	        
    	if(StrEqual(classname2, "func_physbox", false) || StrEqual(classname2, "func_physbox_multiplayer", false) || StrEqual(classname2, "func_breakable", false))
		{
        	if (!IsBossEntity(entity))
            	return;
				
			if(!BossEntityDestroyed) BossEntityDestroyed = true;
    	}
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
	    
        if((activator > 0 && activator <= MaxClients && IsClientInGame(activator)))
		{
            Hits[activator] += 1;
        }
		
		static int offset = -1;
        if (offset == -1) 
            offset = FindDataMapInfo(caller, "m_OutValue");
            float value = GetEntDataFloat(caller, offset);
            int hpcount = RoundToFloor(value);
        
		if(hpcount == 0)
		{
			if(!BossEntityDestroyed) BossEntityDestroyed = true;
		}
	}
}

public Action PrintBossHitRanks()
{
	if(roundend) return;

    int TopOne, TopTwo, TopThree, TopFour, TopFive;
    
    for (int i = 1; i <= MaxClients; i++)
	{
        if (IsClientInGame(i) && Hits[i] >= Hits[TopOne])
		{
            TopOne = i;
        }
    }
    for (int i = 1; i <= MaxClients; i++)
	{
        if (i != TopOne && IsClientInGame(i) && Hits[i] >= Hits[TopTwo])
		{           
            TopTwo = i;
        }
    }      
    for (int i = 1; i <= MaxClients; i++)
	{
        if (i != TopOne && i != TopTwo && IsClientInGame(i) && Hits[i] >= Hits[TopThree])
		{
            TopThree = i;
        }
    }
	for (int i = 1; i <= MaxClients; i++)
	{
        if (i != TopOne && i != TopTwo && i != TopThree && IsClientInGame(i) && Hits[i] >= Hits[TopFour])
		{
            TopFour = i;
        }
    }
	for (int i = 1; i <= MaxClients; i++)
	{
        if (i != TopOne && i != TopTwo && i != TopThree && i != TopFour && IsClientInGame(i) && Hits[i] >= Hits[TopFive])
		{
            TopFive = i;
        }
    }
    
    char top1[512];
	Format(top1,sizeof(top1), "- Top1 Boss Hitter -\n1. %N - %i Hits", TopOne, Hits[TopOne]);
	
	char top2[512];
	Format(top2,sizeof(top2), "- Top2 Boss Hitters -\n1. %N - %i Hits\n2. %N - %i Hits", TopOne, Hits[TopOne], TopTwo, Hits[TopTwo]);
	
	char top3[512];
	Format(top3,sizeof(top3), "- Top3 Boss Hitters -\n1. %N - %i Hits\n2. %N - %i Hits\n3. %N - %i Hits", TopOne, Hits[TopOne], TopTwo, Hits[TopTwo], TopThree, Hits[TopThree]);
	
	char top4[512];
	Format(top3,sizeof(top4), "- Top4 Boss Hitters -\n1. %N - %i Hits\n2. %N - %i Hits\n3. %N - %i Hits\n4. %N - %i Hits", TopOne, Hits[TopOne], TopTwo, Hits[TopTwo], TopThree, Hits[TopThree], TopFour, Hits[TopFour]);
	
	char top5[512];
	Format(top3,sizeof(top5), "- Top5 Boss Hitters -\n1. %N - %i Hits\n2. %N - %i Hits\n3. %N - %i Hits\n4. %N - %i Hits\n5. %N - %i Hits", TopOne, Hits[TopOne], TopTwo, Hits[TopTwo], TopThree, Hits[TopThree], TopFour, Hits[TopFour], TopFive, Hits[TopFive]);
    
	if(Hits[TopFive]>=5)
	{ 
        for (int client = 1; client <= MaxClients; client++)
		{
            if (client == 0)
                return;

            if(IsClientInGame(client) && !IsFakeClient(client))
			{
                SetHudTextParams(-1.0, 0.3, 5.0, 255, 228, 0, 255, 0, 5.0, 0.1, 0.2);
                ShowHudText(client, 5, top5); 
            }
        }
    } 
	else if(Hits[TopFour]>=5)
	{ 
        for (int client = 1; client <= MaxClients; client++)
		{
            if (client == 0)
                return;

            if(IsClientInGame(client) && !IsFakeClient(client))
			{
                SetHudTextParams(-1.0, 0.3, 5.0, 255, 228, 0, 255, 0, 5.0, 0.1, 0.2);
                ShowHudText(client, 5, top4); 
            }
        }
    } 
    else if(Hits[TopThree]>=5)
	{ 
        for (int client = 1; client <= MaxClients; client++)
		{
            if (client == 0)
                return;

            if(IsClientInGame(client) && !IsFakeClient(client))
			{
                SetHudTextParams(-1.0, 0.3, 5.0, 255, 228, 0, 255, 0, 5.0, 0.1, 0.2);
                ShowHudText(client, 5, top3); 
            }
        }
    } 
    else if(Hits[TopTwo]>=5)
	{ 
        for (int client = 1; client <= MaxClients; client++)
		{
            if (client == 0)
                return;

            if(IsClientInGame(client) && !IsFakeClient(client))
			{
                SetHudTextParams(-1.0, 0.3, 5.0, 255, 228, 0, 255, 0, 5.0, 0.1, 0.2);
                ShowHudText(client, 5, top2); 
            }
        }
    } 
    else if(Hits[TopOne]>=5)
	{ 
        for (int client = 1; client <= MaxClients; client++)
		{
            if (client == 0)
                return;

            if(IsClientInGame(client) && !IsFakeClient(client))
			{
                SetHudTextParams(-1.0, 0.3, 5.0, 255, 228, 0, 255, 0, 5.0, 0.1, 0.2);
                ShowHudText(client, 5, top1); 
            }
        }
    }      
    for (int i = 1; i <= MaxClients; i++)
	{	
        Hits[i] = 0;
    }
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