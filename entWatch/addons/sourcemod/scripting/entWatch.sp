//====================================================================================================
//
// Name: entWatch
// Author: Prometheum & zaCade
// Description: Monitor entity interactions.
//
//====================================================================================================
#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>
#include <colors_csgo>
#include <protobuf>
#include <zombiereloaded>
#tryinclude <colors_csgo>
#tryinclude <entWatch>

#define PLUGIN_VERSION "1.0"
//#define LAST_TAG_SIZE 32
Handle buttons;

//ConVar G_hCvar_HudPosition;

//----------------------------------------------------------------------------------------------------
// Purpose: Entity Data
//----------------------------------------------------------------------------------------------------
enum entities
{
	String:ent_name[32],
	String:ent_shortname[32],
	String:ent_color[32],
	String:ent_buttonclass[32],
	String:ent_filtername[32],
	bool:ent_hasfiltername,
	bool:ent_blockpickup,
	bool:ent_allowtransfer,
	bool:ent_forcedrop,
	bool:ent_chat,
	bool:ent_hud,
	ent_hammerid,
	ent_weaponid,
	ent_buttonid,
	ent_ownerid,
	ent_mode, // 0 = No button, 1 = Spam protection only, 2 = Cooldowns, 3 = Limited uses, 4 = Limited uses with cooldowns, 5 = Cooldowns after multiple uses.
	ent_uses,
	ent_maxuses,
	ent_cooldown,
	ent_cooldowntime,
	ent_glow,
};

new ItemIdx=1;
new String:ShowCools[64][512];
new String:ShowCoolsPlayerName[64][512];

new entArray[512][entities];
new entArraySize = 512;
int triggerArray[512];
int triggerSize = 512;

new Handle:GetTagTimer[MAXPLAYERS+1];
new String:g_LastTag[MAXPLAYERS+1][MAX_NAME_LENGTH];
//new String:g_LastTag[32];
new g_Taged[MAXPLAYERS] = {false, ...};

//----------------------------------------------------------------------------------------------------
// Purpose: Color Settings
//----------------------------------------------------------------------------------------------------
new String:color_tag[16]         = "{olive}";
new String:color_name[16]        = "{green}";
new String:color_steamid[16]     = "{default}";
new String:color_use[16]         = "{red}";
new String:color_pickup[16]      = "{red}";
new String:color_drop[16]        = "{red}";
new String:color_disconnect[16]  = "{red}";
new String:color_death[16]       = "{red}";
new String:color_warning[16]     = "{red}";

//----------------------------------------------------------------------------------------------------
// Purpose: Client Settings
//----------------------------------------------------------------------------------------------------
new Handle:G_hCookie_Display     = INVALID_HANDLE;
new Handle:G_hCookie_Restricted  = INVALID_HANDLE;

new bool:G_bDisplay[MAXPLAYERS + 1]     = false;
new bool:G_bDisplay2[MAXPLAYERS + 1]     = false;
new bool:G_bRestricted[MAXPLAYERS + 1]  = false;
//new bool:G_bHasPosData[MAXPLAYERS + 1]  = false;

#define DefaultStringData "0.0"

static Handle:Vault;
static String:StringPath[33];
new Float:HudPosition[MAXPLAYERS+1][2];

//----------------------------------------------------------------------------------------------------
// Purpose: Plugin Settings
//----------------------------------------------------------------------------------------------------
new Handle:G_hCvar_DisplayEnabled    = INVALID_HANDLE;
new Handle:G_hCvar_DisplayCooldowns  = INVALID_HANDLE;
new Handle:G_hCvar_ModeTeamOnly      = INVALID_HANDLE;
new Handle:G_hCvar_ConfigColor       = INVALID_HANDLE;
ConVar     G_hCvar_DefaultHudPos;

new bool:G_bRoundTransition  = false;
new bool:G_bConfigLoaded     = false;
//new Handle:EntHud;
float DefaultHudPos[2];

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin:myinfo =
{
	name         = "entWatch CS:GO ScoreBoard HUD Edition",
	author       = "Prometheum & zaCade, Modified by. Someone",
	description  = "Notify players about entity interactions.",
	version      = PLUGIN_VERSION,
	url          = "https://github.com/zaCade/entWatch"
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnPluginStart()
{
	CreateConVar("entwatch_version", PLUGIN_VERSION, "Current version of entWatch", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	buttons = CreateTrie();
	G_hCvar_DisplayEnabled    = CreateConVar("entwatch_display_enable", "1", "Enable/Disable the display.", 0, true, 0.0, true, 1.0);
	G_hCvar_DisplayCooldowns  = CreateConVar("entwatch_display_cooldowns", "1", "Show/Hide the cooldowns on the display.", 0, true, 0.0, true, 1.0);
	G_hCvar_ModeTeamOnly      = CreateConVar("entwatch_mode_teamonly", "1", "Enable/Disable team only mode.", 0, true, 0.0, true, 1.0);
	G_hCvar_ConfigColor       = CreateConVar("entwatch_config_color", "color_classic", "The name of the color config.", 0);
	G_hCvar_DefaultHudPos	  = CreateConVar("entwatch_default_hudpos", "0.0 0.4", "default hudpos.");
	
	G_hCookie_Display     = RegClientCookie("entwatch_display", "", CookieAccess_Private);
	G_hCookie_Restricted  = RegClientCookie("entwatch_restricted", "", CookieAccess_Private);
	
	//EntHud = CreateHudSynchronizer();
	
	RegConsoleCmd("sm_hud", Command_ToggleHUD);
	RegConsoleCmd("sm_status", Command_Status);
	
	RegAdminCmd("sm_eban", Command_Restrict, ADMFLAG_BAN);
	RegAdminCmd("sm_clear", Command_clear, ADMFLAG_BAN);
	RegAdminCmd("sm_eunban", Command_Unrestrict, ADMFLAG_BAN);
	RegAdminCmd("sm_etransfer", Command_Transfer, ADMFLAG_BAN);
	
	//player can change showhudtext position, ex) !hudpos 0.6 0.3
	RegConsoleCmd("sm_hudpos", Command_Hudpos);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	
	CreateTimer(1.0, Timer_DisplayHUD, _, TIMER_REPEAT);
	CreateTimer(1.0, Timer_Cooldowns, _, TIMER_REPEAT);
	
	LoadTranslations("entWatch.phrases");
	LoadTranslations("common.phrases");
	
	//G_hCvar_HudPosition.AddChangeHook(ConVarChange);
	
	AutoExecConfig(true, "plugin.entWatch");
	
	//GetConVars();
	
	AddCommandListener(Command_JoinTeam, "jointeam");
}

public Action:Command_JoinTeam(client, const String:command[], argc)  
{
	decl String:sTeamName[8];
	GetCmdArg(1, sTeamName, sizeof(sTeamName)) ;
	new iTeam = StringToInt(sTeamName);
	
	g_Taged[client] = true;
	
	if (iTeam == 1)
	{
		CreateTimer(0.1, ResetScore, client);
	}
}
//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnMapStart()
{
	for (new index = 0; index < entArraySize; index++)
	{
		Format(entArray[index][ent_name],         32, "");
		Format(entArray[index][ent_shortname],    32, "");
		Format(entArray[index][ent_color],        32, "");
		Format(entArray[index][ent_buttonclass],  32, "");
		Format(entArray[index][ent_filtername],   32, "");
		entArray[index][ent_hasfiltername]  = false;
		entArray[index][ent_blockpickup]    = false;
		entArray[index][ent_allowtransfer]  = false;
		entArray[index][ent_forcedrop]      = false;
		entArray[index][ent_chat]           = false;
		entArray[index][ent_hud]            = false;
		entArray[index][ent_hammerid]       = -1;
		entArray[index][ent_weaponid]       = -1;
		entArray[index][ent_buttonid]       = -1;
		entArray[index][ent_ownerid]        = -1;
		entArray[index][ent_mode]           = 0;
		entArray[index][ent_uses]           = 0;
		entArray[index][ent_maxuses]        = 0;
		entArray[index][ent_cooldown]       = 0;
		entArray[index][ent_cooldowntime]   = -1;
	}
	PrecacheModel("models/strado/coke.mdl");
	LoadColors();
	LoadConfig();
	
	BuildPath(Path_SM, StringPath, 64, "data/hudpos.txt");
	Vault = CreateKeyValues("Vault");
	FileToKeyValues(Vault, StringPath);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;

	ClearTrie(buttons);
	if (G_bConfigLoaded && G_bRoundTransition)
	{
		CPrintToChatAll("\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "welcome");
	}
	
	for (new client = 1; client < MaxClients; client++)
		if(IsClientInGame(client))
		{
			CreateTimer(0.5, ResetScore, client);
		}
	
	G_bRoundTransition = false;
	
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (G_bConfigLoaded && !G_bRoundTransition)
	{
	
		new tmpidx[entArraySize];
		
		for (new index = 0; index < entArraySize; index++)
		{
			SDKUnhook(entArray[index][ent_buttonid], SDKHook_Use, OnButtonUse);
			tmpidx[index] = entArray[index][ent_weaponid];
			entArray[index][ent_weaponid]       = -1;
			entArray[index][ent_buttonid]       = -1;
			entArray[index][ent_ownerid]        = -1;
			entArray[index][ent_cooldowntime]   = -1;
			entArray[index][ent_uses]           = 0;
			entArray[index][ent_glow] = -1;
			
		}
		
		for (new index2 = 0; index2 < entArraySize; index2++)
		{				
				char buffer1[256];
				int theglow;
				if(tmpidx[index2] == -1 ) continue;
				Format(buffer1, 256, "%i", EntIndexToEntRef(tmpidx[index2]));				
				if (!GetTrieValue(buttons, buffer1, theglow)) continue; 
				theglow = EntRefToEntIndex(theglow);
				if (theglow == INVALID_ENT_REFERENCE) continue; 
				AcceptEntityInput(theglow, "Kill");
		}
	}
	G_bRoundTransition = true;
	
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnClientCookiesCached(client)
{
	new String:buffer_cookie[32];
	GetClientCookie(client, G_hCookie_Display, buffer_cookie, sizeof(buffer_cookie));
	G_bDisplay[client] = bool:StringToInt(buffer_cookie);
	
	GetClientCookie(client, G_hCookie_Restricted, buffer_cookie, sizeof(buffer_cookie));
	G_bRestricted[client] = bool:StringToInt(buffer_cookie);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_Use, OnButtonUse);
	G_bDisplay2[client] = true;
	if (!AreClientCookiesCached(client))
	{
		G_bDisplay2[client] = true;
		G_bDisplay[client] = false;
	}
	
	decl String:SteamID[32];
	decl String:Explode_HudPosition[2][32];
	decl String:Last_HudPosition[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	KvJumpToKey(Vault, "HudPosition", false);
	KvGetString(Vault, SteamID, Last_HudPosition, sizeof(Last_HudPosition));
	ExplodeString(Last_HudPosition, "/", Explode_HudPosition, 2, 32);
	HudPosition[client][0] = StringToFloat(Explode_HudPosition[0]);
	HudPosition[client][1] = StringToFloat(Explode_HudPosition[1]);
	KvRewind(Vault);
}

public Action:GetTag(Handle:timer, any:client)
{
	static numCount = 0;
	
	if (numCount >= 12.0)
	{
		numCount = 0;
		GetTagTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	numCount++;
	
	return Plugin_Continue;
}

public Action:ResetScore(Handle:timer, any:client)
{
	if(!IsClientInGame(client)) {
		return Plugin_Continue;
	}
	new death = GetEntProp(client, Prop_Data, "m_iDeaths");
	new frags = GetEntProp(client, Prop_Data, "m_iFrags");
	new scores = frags - death;
	CS_SetClientContributionScore(client, scores);
	
	decl String:buffer_tag[MAX_NAME_LENGTH];
	Format(buffer_tag, sizeof(buffer_tag), g_LastTag[client]);
	
	return Plugin_Continue;
}

public Action:ResetScoreT(Handle:timer, any:target)
{
	if(!IsClientInGame(target)) {
		return Plugin_Continue;
	}
	new death = GetEntProp(target, Prop_Data, "m_iDeaths");
	new frags = GetEntProp(target, Prop_Data, "m_iFrags");
	new scores = frags - death;
	CS_SetClientContributionScore(target, scores);
	
	decl String:buffer_tag[MAX_NAME_LENGTH];
	Format(buffer_tag, sizeof(buffer_tag), g_LastTag[target]);
	
	return Plugin_Continue;
}

public Action:Set9999Score(Handle:timer, any:client)
{
	CS_SetClientContributionScore(client, 9999);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	//CreateTimer(0.5, ResetScore, client);
	if (GetTagTimer[client] != INVALID_HANDLE)
	{
		KillTimer(GetTagTimer[client]);
		GetTagTimer[client] = INVALID_HANDLE;
	}
	
	if (G_bConfigLoaded && !G_bRoundTransition)
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_ownerid] != -1 && entArray[index][ent_ownerid] == client)
			{
				entArray[index][ent_ownerid] = -1;
				
				if (entArray[index][ent_forcedrop] && IsValidEdict(entArray[index][ent_weaponid]))
					SDKHooks_DropWeapon(client, entArray[index][ent_weaponid]);
				
				if (entArray[index][ent_chat])
				{
					new String:buffer_steamid[32];
					
					GetClientAuthId(client, AuthId_Steam2, buffer_steamid, sizeof(buffer_steamid));
					ReplaceString(buffer_steamid, sizeof(buffer_steamid), "STEAM_", "", true);
					
					char buffer1[256];
					float origin[3];
					int Ent;
					GetEntPropVector(entArray[index][ent_weaponid], Prop_Send, "m_vecOrigin", origin);
					Format(buffer1, 256, "%i", EntIndexToEntRef(entArray[index][ent_weaponid]));
					
					Ent = CreateEntityByName("prop_dynamic_glow");
					if (Ent == -1)return;
					DispatchKeyValue(Ent, "model", "models/strado/coke.mdl");
					DispatchKeyValue(Ent, "disablereceiveshadows", "1");
					DispatchKeyValue(Ent, "disableshadows", "1");
					DispatchKeyValue(Ent, "solid", "0");
					DispatchKeyValue(Ent, "spawnflags", "256");
					SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 11);
					DispatchSpawn(Ent);
					TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
					SetEntProp(Ent, Prop_Send, "m_bShouldGlow", true, true);
					SetEntPropFloat(Ent, Prop_Send, "m_flGlowMaxDist", 10000000.0);
					SetGlowColor(Ent, "0 0 255");
					SetEntPropFloat(Ent, Prop_Send, "m_flModelScale", 1.0);
					SetVariantString("!activator");
					AcceptEntityInput(Ent, "SetParent", entArray[index][ent_weaponid]);
					SetTrieValue(buttons, buffer1, EntIndexToEntRef(Ent	));
					entArray[index][ent_glow] = 1;
					
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(client) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, client, color_disconnect, color_steamid, buffer_steamid, color_disconnect, color_disconnect, "disconnect", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
				}
			}
		}
	}
	
	SDKUnhook(client, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
	SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	G_bDisplay[client] = false;
	G_bDisplay2[client] = true;
	G_bRestricted[client] = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(0.5, ResetScore, client);
	
	if (G_bConfigLoaded && !G_bRoundTransition)
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_ownerid] != -1 && entArray[index][ent_ownerid] == client)
			{
				entArray[index][ent_ownerid] = -1;
				
				if (entArray[index][ent_forcedrop] && IsValidEdict(entArray[index][ent_weaponid]))
					SDKHooks_DropWeapon(client, entArray[index][ent_weaponid]);
				
				if (entArray[index][ent_chat])
				{
					new String:buffer_steamid[32];
					GetClientAuthId(client, AuthId_Steam2, buffer_steamid, sizeof(buffer_steamid));
					//GetClientAuthString(client, buffer_steamid, sizeof(buffer_steamid));
					ReplaceString(buffer_steamid, sizeof(buffer_steamid), "STEAM_", "", true);
					char buffer1[256];
					float origin[3];
					int Ent;
					GetEntPropVector(entArray[index][ent_weaponid], Prop_Send, "m_vecOrigin", origin);
					Format(buffer1, 256, "%i", EntIndexToEntRef(entArray[index][ent_weaponid]));
					
					Ent = CreateEntityByName("prop_dynamic_glow");
					if (Ent == -1)return;
					DispatchKeyValue(Ent, "model", "models/strado/coke.mdl");
					DispatchKeyValue(Ent, "disablereceiveshadows", "1");
					DispatchKeyValue(Ent, "disableshadows", "1");
					DispatchKeyValue(Ent, "solid", "0");
					DispatchKeyValue(Ent, "spawnflags", "256");
					SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 11);
					DispatchSpawn(Ent);
					TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
					SetEntProp(Ent, Prop_Send, "m_bShouldGlow", true, true);
					SetEntPropFloat(Ent, Prop_Send, "m_flGlowMaxDist", 10000000.0);
					SetGlowColor(Ent, "0 0 255");
					SetEntPropFloat(Ent, Prop_Send, "m_flModelScale", 1.0);
					SetVariantString("!activator");
					AcceptEntityInput(Ent, "SetParent", entArray[index][ent_weaponid]);
					SetTrieValue(buttons, buffer1, EntIndexToEntRef(Ent	));					
					entArray[index][ent_glow] = 1;
					
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(client) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, client, color_death, color_steamid, buffer_steamid, color_death, color_death, "death", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:OnWeaponEquip(client, weapon)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return;
	
	if (G_bConfigLoaded && !G_bRoundTransition && IsValidEdict(weapon))
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(weapon))
			{
				if (entArray[index][ent_weaponid] != -1 && entArray[index][ent_weaponid] == weapon)
				{
					entArray[index][ent_ownerid] = client;
					
					if (entArray[index][ent_chat])
					{
						new String:buffer_steamid[32];
						GetClientAuthId(client, AuthId_Steam2, buffer_steamid, sizeof(buffer_steamid));
						ReplaceString(buffer_steamid, sizeof(buffer_steamid), "STEAM_", "", true);
						
						CreateTimer(0.2, Set9999Score, client);
						
						for (new ply = 1; ply <= MaxClients; ply++)
						{
							if (IsClientConnected(ply) && IsClientInGame(ply))
							{
								if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(client) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
								{
									CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, client, color_pickup, color_steamid, buffer_steamid, color_pickup, color_pickup, "pickup", entArray[index][ent_color], entArray[index][ent_name]);
								}
							}
						}
						char buffer1[256];
						int theglow;

						Format(buffer1, 256, "%i", EntIndexToEntRef(weapon));
						if (!GetTrieValue(buttons, buffer1, theglow)) return; 
						theglow = EntRefToEntIndex(theglow);
						
						if (theglow == INVALID_ENT_REFERENCE) return;
						
						AcceptEntityInput(theglow, "Kill");
						entArray[index][ent_glow] = -1;
					}
					break;
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:OnWeaponDrop(client, weapon)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return;
	
	if (G_bConfigLoaded && !G_bRoundTransition && IsValidEdict(weapon))
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(weapon))
			{
				if (entArray[index][ent_weaponid] != -1 && entArray[index][ent_weaponid] == weapon)
				{
					entArray[index][ent_ownerid] = -1;
					
					if (entArray[index][ent_chat])
					{
						char buffer1[256];
						float origin[3];
						int Ent;
						GetEntPropVector(weapon, Prop_Send, "m_vecOrigin", origin);
						Format(buffer1, 256, "%i", EntIndexToEntRef(weapon));
						
						new String:buffer_steamid[32];
						GetClientAuthId(client, AuthId_Steam2, buffer_steamid, sizeof(buffer_steamid));
						ReplaceString(buffer_steamid, sizeof(buffer_steamid), "STEAM_", "", true);
						
						Ent = CreateEntityByName("prop_dynamic_glow");
						if (Ent == -1)return;
						DispatchKeyValue(Ent, "model", "models/strado/coke.mdl");
						DispatchKeyValue(Ent, "disablereceiveshadows", "1");
						DispatchKeyValue(Ent, "disableshadows", "1");
						DispatchKeyValue(Ent, "solid", "0");
						DispatchKeyValue(Ent, "spawnflags", "256");
						SetEntProp(Ent, Prop_Send, "m_CollisionGroup", 11);
						DispatchSpawn(Ent);
						TeleportEntity(Ent, origin, NULL_VECTOR, NULL_VECTOR);
						SetEntProp(Ent, Prop_Send, "m_bShouldGlow", true, true);
						SetEntPropFloat(Ent, Prop_Send, "m_flGlowMaxDist", 10000000.0);
						SetGlowColor(Ent, "0 0 255");
						SetEntPropFloat(Ent, Prop_Send, "m_flModelScale", 1.0);
						SetVariantString("!activator");
						AcceptEntityInput(Ent, "SetParent", weapon);
						SetTrieValue(buttons, buffer1, EntIndexToEntRef(Ent));
						entArray[index][ent_glow] = 1;
						
						CreateTimer(0.0, ResetScore, client);
						
						for (new ply = 1; ply <= MaxClients; ply++)
						{
							if (IsClientConnected(ply) && IsClientInGame(ply))
							{
								if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(client) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
								{
									CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, client, color_drop, color_steamid, buffer_steamid, color_drop, color_drop, "drop", entArray[index][ent_color], entArray[index][ent_name]);
								}
							}
						}
					}
					break;
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:OnWeaponCanUse(client, weapon)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (G_bConfigLoaded && !G_bRoundTransition && IsValidEdict(weapon))
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_hammerid] == Entity_GetHammerID(weapon))
			{
				if (entArray[index][ent_weaponid] == -1)
				{
					entArray[index][ent_weaponid] = weapon;
					
					if (entArray[index][ent_buttonid] == -1 && entArray[index][ent_mode] != 0)
					{
						new String:buffer_targetname[32];
						Entity_GetTargetName(weapon, buffer_targetname, sizeof(buffer_targetname));
						
						new button = -1;
						while ((button = FindEntityByClassname(button, entArray[index][ent_buttonclass])) != -1)
						{
							if (IsValidEdict(button))
							{
								new String:buffer_parentname[32];
								Entity_GetParentName(button, buffer_parentname, sizeof(buffer_parentname));
								
								if (StrEqual(buffer_targetname, buffer_parentname))
								{
									SDKHook(button, SDKHook_Use, OnButtonUse);
									entArray[index][ent_buttonid] = button;
									break;
								}
							}
						}
					}
				}
				if (entArray[index][ent_weaponid] == weapon)
				{
					if (entArray[index][ent_blockpickup])
						return Plugin_Handled;
					
					if (G_bRestricted[client])
						return Plugin_Handled;
					
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:OnButtonUse(button, activator, caller, UseType:type, Float:value)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (G_bConfigLoaded && !G_bRoundTransition && IsValidEdict(button))
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_buttonid] != -1 && entArray[index][ent_buttonid] == button)
			{
				//if (entArray[index][ent_ownerid] != activator && entArray[index][ent_ownerid] != caller)
				if (entArray[index][ent_ownerid] != activator)
					return Plugin_Handled;
				
				if (entArray[index][ent_hasfiltername])
					DispatchKeyValue(activator, "targetname", entArray[index][ent_filtername]);
				
				new String:buffer_steamid[32];
				GetClientAuthId(activator, AuthId_Steam2, buffer_steamid, sizeof(buffer_steamid));
				ReplaceString(buffer_steamid, sizeof(buffer_steamid), "STEAM_", "", true);
				
				if (entArray[index][ent_mode] == 1)
				{
					return Plugin_Changed;
				}
				
				else if (entArray[index][ent_mode] == 2 && entArray[index][ent_cooldowntime] <= -1)
				{
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(activator) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, activator, color_use, color_steamid, buffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}

					entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
					return Plugin_Changed;
				}
				else if (entArray[index][ent_mode] == 3 && entArray[index][ent_uses] < entArray[index][ent_maxuses])
				{
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(activator) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, activator, color_use, color_steamid, buffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
					
					entArray[index][ent_uses]++;
					return Plugin_Changed;
				}
				else if (entArray[index][ent_mode] == 4 && entArray[index][ent_uses] < entArray[index][ent_maxuses] && entArray[index][ent_cooldowntime] <= -1)
				{
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(activator) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, activator, color_use, color_steamid, buffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
					
					entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
					entArray[index][ent_uses]++;
					return Plugin_Changed;
				}
				else if (entArray[index][ent_mode] == 5 && entArray[index][ent_cooldowntime] <= -1)
				{
					for (new ply = 1; ply <= MaxClients; ply++)
					{
						if (IsClientConnected(ply) && IsClientInGame(ply))
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == GetClientTeam(activator) || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								CPrintToChat(ply, "\x07%s[entWatch] \x07%s%N \x07%s(\x07%s%s\x07%s) \x07%s%t \x07%s%s", color_tag, color_name, activator, color_use, color_steamid, buffer_steamid, color_use, color_use, "use", entArray[index][ent_color], entArray[index][ent_name]);
							}
						}
					}
					
					entArray[index][ent_uses]++;
					if (entArray[index][ent_uses] >= entArray[index][ent_maxuses])
					{
						entArray[index][ent_cooldowntime] = entArray[index][ent_cooldown];
						entArray[index][ent_uses] = 0;
					}
					return Plugin_Changed;
				}
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
}
//----------------------------------------------------------------------------------------------------
// Purpose:ë¼ì• ì• ì• ì• ì•¡
//----------------------------------------------------------------------------------------------------
public Action:Timer_DisplayHUD(Handle:timer, Any:client)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (GetConVarBool(G_hCvar_DisplayEnabled))
	{
		if (G_bConfigLoaded && !G_bRoundTransition)
		{
			new String:buffer_teamtext[10][512];
			ItemIdx = 1 ;
			new String:buffer_hud[512];
			for (new index = 0; index < entArraySize; index++)
			{
				if (entArray[index][ent_hud] && entArray[index][ent_ownerid] != -1)
				{
					//128
					new String:buffer_temp[512];
					//13
					new String:buffer_name[64];
					if (GetConVarBool(G_hCvar_DisplayCooldowns))
					{
						if (entArray[index][ent_mode] == 2)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%d]%s:",entArray[index][ent_cooldowntime], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%s]%s:","R", entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else if (entArray[index][ent_mode] == 3)
						{
							if (entArray[index][ent_uses] < entArray[index][ent_maxuses])
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%d/%d]%s:", entArray[index][ent_uses], entArray[index][ent_maxuses], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%s]%s:", "D", entArray[index][ent_shortname]);
								Format(buffer_temp, sizeof(buffer_temp), "[%d/%d]%s:", entArray[index][ent_uses], entArray[index][ent_maxuses], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else if (entArray[index][ent_mode] == 4)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%d]%s:", entArray[index][ent_cooldowntime], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								if (entArray[index][ent_uses] < entArray[index][ent_maxuses])
								{
									Format(buffer_temp, sizeof(buffer_temp), "[%d/%d]%s:", entArray[index][ent_uses], entArray[index][ent_maxuses], entArray[index][ent_shortname]);
									Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
									if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
									{
										ShowCools[ItemIdx] = buffer_temp;
										ShowCoolsPlayerName[ItemIdx] = buffer_name;
										ItemIdx++;
									}
								}
								else
								{
									Format(buffer_temp, sizeof(buffer_temp), "[%s]%s:", "D", entArray[index][ent_shortname]);
									Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
									if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
									{
										ShowCools[ItemIdx] = buffer_temp;
										ShowCoolsPlayerName[ItemIdx] = buffer_name;
										ItemIdx++;
									}
								}
							}
						}
						else if (entArray[index][ent_mode] == 5)
						{
							if (entArray[index][ent_cooldowntime] > 0)
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%d]%s:", entArray[index][ent_cooldowntime], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
							else
							{
								Format(buffer_temp, sizeof(buffer_temp), "[%d/%d]%s:", entArray[index][ent_uses], entArray[index][ent_maxuses], entArray[index][ent_shortname]);
								Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
								if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
								{
									ShowCools[ItemIdx] = buffer_temp;
									ShowCoolsPlayerName[ItemIdx] = buffer_name;
									ItemIdx++;
								}
							}
						}
						else
						{
							Format(buffer_temp, sizeof(buffer_temp), "[%s]%s:", "N/A", entArray[index][ent_shortname]);
							Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
							if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
							{
								ShowCools[ItemIdx] = buffer_temp;
								ShowCoolsPlayerName[ItemIdx] = buffer_name;
								ItemIdx++;
							}
						}
					}
					else
					{
						Format(buffer_temp, sizeof(buffer_temp), "%s:", entArray[index][ent_shortname]);
						Format(buffer_name, sizeof(buffer_name), "%N",entArray[index][ent_ownerid]);
						if(ZR_IsClientHuman(entArray[index][ent_ownerid]))
						{
							ShowCools[ItemIdx] = buffer_temp;
							ShowCoolsPlayerName[ItemIdx] = buffer_name;
							ItemIdx++;
						}
					}
					if (strlen(buffer_temp) + strlen(buffer_teamtext[GetClientTeam(entArray[index][ent_ownerid])]) <= sizeof(buffer_teamtext[]))
					{
						StrCat(buffer_teamtext[GetClientTeam(entArray[index][ent_ownerid])], sizeof(buffer_teamtext[]), buffer_temp);
					}
				}
			}
			
			for( int idx=1 ; idx <ItemIdx;idx++)
			{
				StrCat(buffer_hud,512,ShowCools[idx]);
				StrCat(buffer_hud,512,ShowCoolsPlayerName[idx]);
				if(idx != ItemIdx-1)
				{
					StrCat(buffer_hud,512,"\n");
				}
			}
			
			if(ItemIdx >= 2)
			{
				char DefPosition[2][8];
				char DefPosValue[16];
				G_hCvar_DefaultHudPos.GetString(DefPosValue, sizeof(DefPosValue));
				ExplodeString(DefPosValue, " ", DefPosition, sizeof(DefPosition), sizeof(DefPosition[]));

				DefaultHudPos[0] = StringToFloat(DefPosition[0]);
				DefaultHudPos[1] = StringToFloat(DefPosition[1]);
				
				for(int i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && !IsFakeClient(i))
					{
						if (G_bDisplay2[i])
						{
							if(HudPosition[i][0] <= 0.0 && HudPosition[i][1] <= 0.0)
								SetHudTextParams(DefaultHudPos[0], DefaultHudPos[1], 1.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
							else
								SetHudTextParams(HudPosition[i][0], HudPosition[i][1], 1.1, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
							ShowHudText(i, 5, buffer_hud);
						}
					}
				}
			}
			else if(ItemIdx <= 1)
			{
				return Plugin_Continue;
			}
			for (new ply = 1; ply <= MaxClients; ply++)
			{
				if (IsClientConnected(ply) && IsClientInGame(ply))
				{
					if (G_bDisplay[ply])
					{
						new String:buffer_text[512];
						
						for (new teamid = 0; teamid < sizeof(buffer_teamtext); teamid++)
						{
							if (!GetConVarBool(G_hCvar_ModeTeamOnly) || (GetConVarBool(G_hCvar_ModeTeamOnly) && GetClientTeam(ply) == teamid || !IsPlayerAlive(ply) || CheckCommandAccess(ply, "entWatch_chat", ADMFLAG_CHAT)))
							{
								if (strlen(buffer_teamtext[teamid]) + strlen(buffer_text) <= sizeof(buffer_text))
								{
									StrCat(buffer_text, sizeof(buffer_text), buffer_teamtext[teamid]);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Timer_Cooldowns(Handle:timer)
{
	if (GameRules_GetProp("m_bWarmupPeriod") == 1)
		return Plugin_Continue;
	
	if (G_bConfigLoaded && !G_bRoundTransition)
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_cooldowntime] >= 0)
			{
				entArray[index][ent_cooldowntime]--;
			}
		}
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:G_bDisplay2
//----------------------------------------------------------------------------------------------------
public Action:Command_ToggleHUD(client, args)
{
	if (G_bDisplay2[client])
	{
		CPrintToChat(client, "\x07%s[entWatch] \x0b%t", color_tag, "display disabled");
		G_bDisplay2[client] = false;
	}
	else
	{
		CPrintToChat(client, "\x07%s[entWatch] \x07%t", color_tag, "display enabled");
		G_bDisplay2[client] = true;
	}
	return Plugin_Handled;
}
//-------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_Status(client, args)
{
	if (AreClientCookiesCached(client))
	{
		if (G_bRestricted[client])
		{
			CReplyToCommand(client, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status restricted");
		}
		else
		{
			CReplyToCommand(client, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "status unrestricted");
		}
	}
	else
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%s%t", color_tag, color_warning, "cookies loading");
	}
	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_Restrict(client, args)
{
	if (GetCmdArgs() < 1)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_eban <target>", color_tag, color_warning);
		return Plugin_Handled;
	}
	
	new String:target_argument[64];
	GetCmdArg(1, target_argument, sizeof(target_argument));
	
	new target = -1;
	if ((target = FindTarget(client, target_argument, true)) == -1)
		return Plugin_Handled;
	
	G_bRestricted[target] = true;
	SetClientCookie(target, G_hCookie_Restricted, "1");
	
	CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%srestricted \x07%s%N", color_tag, color_name, client, color_warning, color_name, target);
	LogAction(client, -1, "%L restricted %L", client, target);
	
	return Plugin_Handled;
}
public Action:Command_clear(client, args)
{
	return Plugin_Handled;
}
//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_Unrestrict(client, args)
{
	if (GetCmdArgs() < 1)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_eunban <target>", color_tag, color_warning);
		return Plugin_Handled;
	}
	
	new String:target_argument[64];
	GetCmdArg(1, target_argument, sizeof(target_argument));
	
	new target = -1;
	if ((target = FindTarget(client, target_argument, true)) == -1)
		return Plugin_Handled;
	
	G_bRestricted[target] = false;
	SetClientCookie(target, G_hCookie_Restricted, "0");
	
	CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%sunrestricted \x07%s%N", color_tag, color_name, client, color_warning, color_name, target);
	LogAction(client, -1, "%L unrestricted %L", client, target);
	
	return Plugin_Handled;
}
//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_Transfer(client, args)
{
	if (GetCmdArgs() < 2)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_etransfer <owner> <reciever>", color_tag, color_warning);
		return Plugin_Handled;
	}
	
	new String:target_argument[64];
	GetCmdArg(1, target_argument, sizeof(target_argument));
	
	new String:reciever_argument[64];
	GetCmdArg(2, reciever_argument, sizeof(reciever_argument));
	
	new target = -1;
	if ((target = FindTarget(client, target_argument, false)) == -1)
		return Plugin_Handled;
	
	new reciever = -1;
	if ((reciever = FindTarget(client, reciever_argument, false)) == -1)
		return Plugin_Handled;
	
	if (GetClientTeam(target) != GetClientTeam(reciever))
		return Plugin_Handled;
	
	if (G_bConfigLoaded && !G_bRoundTransition)
	{
		for (new index = 0; index < entArraySize; index++)
		{
			if (entArray[index][ent_ownerid] != -1)
			{
				if (entArray[index][ent_ownerid] == target)
				{
					if (entArray[index][ent_allowtransfer])
					{
						if (IsValidEdict(entArray[index][ent_weaponid]))
						{
							new String:buffer_classname[64];
							GetEdictClassname(entArray[index][ent_weaponid], buffer_classname, sizeof(buffer_classname));
							
							SDKHooks_DropWeapon(target, entArray[index][ent_weaponid]);
							GivePlayerItem(target, buffer_classname);
							CreateTimer(0.0, ResetScoreT, target);
							
							if (entArray[index][ent_chat])
							{
								entArray[index][ent_chat] = false;
								EquipPlayerWeapon(reciever, entArray[index][ent_weaponid]);
								CS_SetClientContributionScore(reciever, 9999);
								entArray[index][ent_chat] = true;
							}
							else
							{
								EquipPlayerWeapon(reciever, entArray[index][ent_weaponid]);
								CS_SetClientContributionScore(reciever, 9999);
							}
						}
					}
				}
			}
		}
	}
	CPrintToChatAll("\x07%s[entWatch] \x07%s%N \x07%stransfered all items from \x07%s%N \x07%sto \x07%s%N", color_tag, color_name, client, color_warning, color_name, target, color_warning, color_name, reciever);
	LogAction(client, -1, "%L transfered all items from %L to %L", client, target, reciever);
	
	return Plugin_Handled;
}
//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action:Command_Hudpos(client, args)
{
	if (GetCmdArgs() < 2)
	{
		CReplyToCommand(client, "\x07%s[entWatch] \x07%sUsage: sm_hudpos <x> <y>", color_tag, color_warning);
		return Plugin_Handled;
	}
	decl String:buffer[128];
	
	GetCmdArg(1, buffer, sizeof(buffer));
	HudPosition[client][0] = StringToFloat(buffer);
	
	GetCmdArg(2, buffer, sizeof(buffer));
	HudPosition[client][1] = StringToFloat(buffer);
	
	decl String:SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
	
	if(HudPosition[client][0] >= 0.0 && HudPosition[client][1] >= 0.0)
	{
		KvDeleteKey(Vault, SteamID);
		KvJumpToKey(Vault, "HudPosition", true);
		Format(buffer, sizeof(buffer), "%f/%f", HudPosition[client][0], HudPosition[client][1]);
		KvSetString(Vault, SteamID, buffer);
		KvRewind(Vault);
		
	}
	else
	{
		KvDeleteKey(Vault, SteamID);
		KvJumpToKey(Vault, "HudPosition", false);
		KvRewind(Vault);
	}
	KeyValuesToFile(Vault, StringPath);
	
	CPrintToChat(client, "\x07%s[entWatch] \x03%t", color_tag, "hudpos");
	
	return Plugin_Handled;
}
//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock LoadColors()
{
	new Handle:hKeyValues = CreateKeyValues("colors");
	new String:buffer_config[128];
	new String:buffer_path[PLATFORM_MAX_PATH];
	new String:buffer_temp[16];
	
	GetConVarString(G_hCvar_ConfigColor, buffer_config, sizeof(buffer_config));
	Format(buffer_path, sizeof(buffer_path), "cfg/sourcemod/entwatch/colors/%s.cfg", buffer_config);
	FileToKeyValues(hKeyValues, buffer_path);
	
	KvRewind(hKeyValues);
	
	KvGetString(hKeyValues, "color_tag", buffer_temp, sizeof(buffer_temp));
	Format(color_tag, sizeof(color_tag), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_name", buffer_temp, sizeof(buffer_temp));
	Format(color_name, sizeof(color_name), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_steamid", buffer_temp, sizeof(buffer_temp));
	Format(color_steamid, sizeof(color_steamid), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_use", buffer_temp, sizeof(buffer_temp));
	Format(color_use, sizeof(color_use), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_pickup", buffer_temp, sizeof(buffer_temp));
	Format(color_pickup, sizeof(color_pickup), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_drop", buffer_temp, sizeof(buffer_temp));
	Format(color_drop, sizeof(color_drop), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_disconnect", buffer_temp, sizeof(buffer_temp));
	Format(color_disconnect, sizeof(color_disconnect), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_death", buffer_temp, sizeof(buffer_temp));
	Format(color_death, sizeof(color_death), "%s", buffer_temp);
	
	KvGetString(hKeyValues, "color_warning", buffer_temp, sizeof(buffer_temp));
	Format(color_warning, sizeof(color_warning), "%s", buffer_temp);
	
	CloseHandle(hKeyValues);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------

stock LoadConfig()
{
	new Handle:hKeyValues = CreateKeyValues("entities");
	
	new String:buffer_map[128];
	new String:buffer_path[PLATFORM_MAX_PATH];
	new String:buffer_temp[32];
	new buffer_amount;
	
	GetCurrentMap(buffer_map, sizeof(buffer_map));
	FormatEx(buffer_path, sizeof(buffer_path), "cfg/sourcemod/entwatch/maps/%s.cfg", buffer_map);

	FileToKeyValues(hKeyValues, buffer_path);
	
	LogMessage("Loading %s", buffer_path);
	
	KvRewind(hKeyValues);
	if (KvGotoFirstSubKey(hKeyValues))
	{
		G_bConfigLoaded = true;
		entArraySize = 0;
		triggerSize = 0;
		
		do
		{
			KvGetString(hKeyValues, "maxamount", buffer_temp, sizeof(buffer_temp));
			buffer_amount = StringToInt(buffer_temp);
			
			for (new i = 0; i < buffer_amount; i++)
			{
				KvGetString(hKeyValues, "name", buffer_temp, sizeof(buffer_temp));
				Format(entArray[entArraySize][ent_name], 32, "%s", buffer_temp);
				
				KvGetString(hKeyValues, "shortname", buffer_temp, sizeof(buffer_temp));
				Format(entArray[entArraySize][ent_shortname], 32, "%s", buffer_temp);
				
				KvGetString(hKeyValues, "color", buffer_temp, sizeof(buffer_temp));
				Format(entArray[entArraySize][ent_color], 32, "%s", buffer_temp);
				
				KvGetString(hKeyValues, "buttonclass", buffer_temp, sizeof(buffer_temp));
				Format(entArray[entArraySize][ent_buttonclass], 32, "%s", buffer_temp);
				
				KvGetString(hKeyValues, "filtername", buffer_temp, sizeof(buffer_temp));
				Format(entArray[entArraySize][ent_filtername], 32, "%s", buffer_temp);
				
				KvGetString(hKeyValues, "hasfiltername", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_hasfiltername] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "blockpickup", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_blockpickup] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "allowtransfer", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_allowtransfer] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "forcedrop", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_forcedrop] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "chat", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_chat] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "hud", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_hud] = StrEqual(buffer_temp, "true", false);
				
				KvGetString(hKeyValues, "hammerid", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_hammerid] = StringToInt(buffer_temp);
				
				KvGetString(hKeyValues, "mode", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_mode] = StringToInt(buffer_temp);
				
				KvGetString(hKeyValues, "maxuses", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_maxuses] = StringToInt(buffer_temp);
				
				KvGetString(hKeyValues, "cooldown", buffer_temp, sizeof(buffer_temp));
				entArray[entArraySize][ent_cooldown] = StringToInt(buffer_temp);
				
				KvGetString(hKeyValues, "trigger", buffer_temp, sizeof(buffer_temp));

				int tindex = StringToInt(buffer_temp);
				if(tindex)
				{
					triggerArray[triggerSize] = tindex;
					triggerSize++;
				}
				entArraySize++;
			}
		}
		while (KvGotoNextKey(hKeyValues));
	}
	else
	{
		G_bConfigLoaded = false;
		
		LogMessage("Could not load %s", buffer_path);
	}
	CloseHandle(hKeyValues);
}

stock void SetGlowColor(int entity, const char[] color)
{
    char colorbuffers[3][4];
    ExplodeString(color, " ", colorbuffers, sizeof(colorbuffers), sizeof(colorbuffers[]));
    int colors[4];
    for (int i = 0; i < 3; i++)
        colors[i] = StringToInt(colorbuffers[i]);
	
    colors[3] = 255; // Set alpha
    SetVariantColor(colors);
    AcceptEntityInput(entity, "SetGlowColor");
}  