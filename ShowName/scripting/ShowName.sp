#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <colorvariables>
#include <zombiereloaded>

Handle hShowNameCookie;
bool iClientShowHUD[MAXPLAYERS+1];

bool bLateLoad = false;

public Plugin myinfo = {
	name = "[ZR] Simple Show Name",
	description = "Show name of aimed target HintText",
	author = "SHUFEN from POSSESSION.tokyo, Modified by. Someone",
	version = "1.2",
	url = "https://possession.tokyo"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("ShowName");

	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("ShowName.phrases");

	RegConsoleCmd("sm_sn", Command_ShowHud);
	hShowNameCookie = RegClientCookie("ShowName", "ShowName Cookie", CookieAccess_Protected);

	SetCookieMenuItem(PrefMenu, 0, "");
	
	if(bLateLoad) {
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(AreClientCookiesCached(i))
					OnClientCookiesCached(i);
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, hShowNameCookie, sValue, sizeof(sValue));
	
	iClientShowHUD[client] = (sValue[0] != '\0' && StringToInt(sValue));
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen)
{
	if (actions == CookieMenuAction_DisplayOption)
	{
		switch(iClientShowHUD[client])
		{
			case false: FormatEx(buffer, maxlen, "%T: %T", "ShowName", client, "Disabled", client);
			case true: FormatEx(buffer, maxlen, "%T: %T", "ShowName", client, "Enabled", client);
		}
	}

	if (actions == CookieMenuAction_SelectOption)
	{
		ToggleShowHud(client);
		ShowCookieMenu(client);
	}
}

public Action Command_ShowHud(int client, int args)
{
	if(client < 1 || client > MaxClients) return Plugin_Handled;

	ToggleShowHud(client);
	return Plugin_Handled;
}

void ToggleShowHud(int client)
{
	char sCookieValue[12];

	switch(iClientShowHUD[client])
	{
		case false:
		{
			iClientShowHUD[client] = true;
			IntToString(1, sCookieValue, sizeof(sCookieValue));
			SetClientCookie(client, hShowNameCookie, sCookieValue);
			CReplyToCommand(client, "\x04[ShowName]\x05 %t", "EnabledMsg");
		}
		case true:
		{
			iClientShowHUD[client] = false;
			IntToString(0, sCookieValue, sizeof(sCookieValue));
			SetClientCookie(client, hShowNameCookie, sCookieValue);
			CReplyToCommand(client, "\x04[ShowName]\x05 %t", "DisabledMsg");
		}
	}
}

public void OnPostThinkPost(int client)
{
	if (iClientShowHUD[client] && IsClientInGame(client))
	{
		int iClientTeam = GetClientTeam(client);
		int target = GetClientAimTarget2(client);
		
		if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target))
		{
			if(ZR_IsClientHuman(target))
			{
				if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
				{
					PrintHintText(client, "<font class='fontSize-l' color='#489CFF'>Human:</font> <font class='fontSize-l'>%N</font>\n<font class='fontSize-l' color='#1DDB16'>Health:</font> <font class='fontSize-l'>%i</font>", target, GetClientHealth(target));
				}
				else
				{
					char client_specmode[10];
					GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
					
					if(StringToInt(client_specmode) == 6)
						PrintHintText(client, "<font class='fontSize-l' color='#489CFF'>Human:</font> <font class='fontSize-l'>%N</font>\n<font class='fontSize-l' color='#1DDB16'>Health:</font> <font class='fontSize-l'>%i</font>", target, GetClientHealth(target));
				}
			}
			else
			{
				if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
				{
					PrintHintText(client, "<font class='fontSize-l' color='#FF0000'>Zombie:</font> <font class='fontSize-l'>%N</font>\n<font class='fontSize-l' color='#1DDB16'>Health:</font> <font class='fontSize-l'>%i</font>", target, GetClientHealth(target));
				}
				else
				{
					char client_specmode[10];
					GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
					
					if(StringToInt(client_specmode) == 6)
						PrintHintText(client, "<font class='fontSize-l' color='#FF0000'>Zombie:</font> <font class='fontSize-l'>%n</font>\n<font class='fontSize-l' color='#1DDB16'>Health:</font> <font class='fontSize-l'>%d</font>", target, GetClientHealth(target));
				}
			}
		}
	}
}

stock int GetClientAimTarget2(int client)
{
	float fPosition[3];
	float fAngles[3];
	GetClientEyePosition(client, fPosition);
	GetClientEyeAngles(client, fAngles);

	Handle hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

	if(TR_DidHit(hTrace))
	{
		int entity = TR_GetEntityIndex(hTrace);
		delete hTrace;
		return entity;
	}

	delete hTrace;
	return -1;
}

public bool TraceRayFilter(int entity, int mask, any client)
{
	if(entity == client)
		return false;

	return true;
}