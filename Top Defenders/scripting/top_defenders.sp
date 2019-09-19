
/*	Copyright (C) 2017 IT-KiLLER
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#pragma semicolon 1
#pragma newdecls required
//#define DEBUG // this enabled debug mode!
#define TAG_COLOR 	"{green}[SM]{default}"

ConVar sm_top_defenders_enabled, sm_top_defenders_top_list, sm_top_defenders_winners,
 sm_top_defenders_minium_damage;

enum player_damange
{
	playerid,
	hits,
	kills,
	damange,
};
	/* list texts format START */
	static char top_header[128];
	static char top_winner[128];
	static char top_nonwinner[128];
	static char top_footer[128];
	/* list text format END */

	int entity_client[MAXPLAYERS+1]={INVALID_ENT_REFERENCE,...}; 
	int damangeArray[MAXPLAYERS+1][player_damange];
	int tempArray[5][player_damange]; 
	Handle timer_client[MAXPLAYERS+1]={INVALID_HANDLE,...};
	float cooldowntime[MAXPLAYERS+1] = {0.0, ...};

public Plugin myinfo = 
{
	name = "[CS:GO] TOP DEFENDERS", 
	author = "IT-KiLLER, Modefied by. Someone", 
	description = "The players who have made the most damage are presented after each round.", 
	version = "1.0", 
	url = "https://github.com/IT-KiLLER"
}

public void OnPluginStart()
{
	sm_top_defenders_enabled = CreateConVar("sm_top_defenders_enabled", "1.0", "Plugin is enabled or disabled.", _, true, 0.0, true, 1.0);
	sm_top_defenders_top_list = CreateConVar("sm_top_defenders_top_list", "5.0", "How many players will be listed on the top list. (1.0-20.0)", _, true, 1.0, true, 64.0);
	sm_top_defenders_winners = CreateConVar("sm_top_defenders_winners", "1.0", "How many will be top winners and get !hat permission. (1.0-10.0)", _, true, 1.0, true, 64.0);
	sm_top_defenders_minium_damage = CreateConVar("sm_top_defenders_minium_damage", "500.0", "The total minimum damage for players to be listed. (1.0-5000.0)", _, true, 1.0, true, 5000.0);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_PostNoCopy);
	LoadConfig();
}

stock void LoadConfig()
{
	KeyValues hKeyValues = new KeyValues("top defenders");
	char config_path[PLATFORM_MAX_PATH]="addons/sourcemod/configs/top_defenders.cfg";

	hKeyValues.ImportFromFile(config_path);
	LogMessage("Loading %s", config_path);

	hKeyValues.Rewind();
	if(hKeyValues.JumpToKey("colors"))
	{
		hKeyValues.GetString("top_header", top_header, sizeof(top_header));
		#if defined DEBUG
			PrintToServer("color: %s", top_header); // debuging
		#endif
		hKeyValues.GetString("top_winner", top_winner, sizeof(top_winner));
		#if defined DEBUG
			PrintToServer("color: %s", top_winner); // debuging
		#endif
		hKeyValues.GetString("top_nonwinner", top_nonwinner, sizeof(top_nonwinner));
		#if defined DEBUG
			PrintToServer("color: %s", top_nonwinner); // debuging
		#endif
		hKeyValues.GetString("top_footer", top_footer, sizeof(top_footer));
		#if defined DEBUG
			PrintToServer("color: %s", top_footer); // debuging
		#endif
		hKeyValues.Rewind();
	} else {
		//LogMessage("Could not load colors from path: %s", config_path);
		SetFailState("Could not load colors from path: %s", config_path);
		CloseHandle(hKeyValues);
		return;
	}
	CloseHandle(hKeyValues);
}

public void OnMapStart() 
{
	if(!sm_top_defenders_enabled.BoolValue) return;

	resetDamangesArrays();
	LoadConfig();
}

public void OnClientDisconnect_Post(int client)
{
	damangeArray[client][playerid] = client;
	damangeArray[client][damange] = 0;
	damangeArray[client][hits] = 0;
	damangeArray[client][kills] = 0;
	timer_client[client] = INVALID_HANDLE;
	cooldowntime[client] = 0.0;
	entity_client[client] = INVALID_ENT_REFERENCE;
}
	
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_top_defenders_enabled.BoolValue) return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker) return;
	int damage = GetEventInt(event, "dmg_health");
	damangeArray[attacker][damange] += damage;
	damangeArray[attacker][hits] += 1;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_top_defenders_enabled.BoolValue) return;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker) return;
	damangeArray[attacker][kills] += 1;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_top_defenders_enabled.BoolValue) return;

	char buffer_temp[256];
	bool loop = true;
	int myindex = 0;

	do {
		loop=false;
		myindex++;
		/* SORTING LOOP */
		for(int client = 1; client < MaxClients - myindex; client++) {
			if(damangeArray[client][damange] < damangeArray[client + 1][damange]) {
				tempArray[1]=damangeArray[client];
				damangeArray[client]=damangeArray[client + 1];
				damangeArray[client + 1] = tempArray[1];
				loop = true;
				}
			}
	} while (loop);

	char top_text[128];
	
	for(int index = 1; index <= sm_top_defenders_top_list.IntValue; index++) {
		if(damangeArray[index][damange]>=sm_top_defenders_minium_damage.IntValue || index==sm_top_defenders_top_list.IntValue) {
			if(index==1) {
				CPrintToChatAll(top_header);
				PrintToConsoleAll2(top_header);
			}
			if(damangeArray[index][damange]>=sm_top_defenders_minium_damage.IntValue) {
				if(index<=sm_top_defenders_winners.IntValue){ /* top 1 */
					top_text=top_winner;
				} else { /* top 2-5 */
					top_text=top_nonwinner; 
				}

				ReplaceString(top_text, sizeof(top_text), "{INDEX}", toString(index), true);
				Format(buffer_temp, sizeof(buffer_temp), "%N", damangeArray[index][playerid], true);
				ReplaceString(top_text, sizeof(top_text), "{NAME}", buffer_temp, true);
				ReplaceString(top_text, sizeof(top_text), "{DAMANGE}", toString(damangeArray[index][damange]), true);
				ReplaceString(top_text, sizeof(top_text), "{HITS}", toString(damangeArray[index][hits]), true);
				ReplaceString(top_text, sizeof(top_text), "{KILLS}", toString(damangeArray[index][kills]), true);
				CPrintToChatAll(top_text);
				PrintToConsoleAll2(top_text);
			}
			if(index==sm_top_defenders_top_list.IntValue) {
				CPrintToChatAll(top_footer);	
				PrintToConsoleAll2(top_footer);	
			}
			} else if (index==1) break;
		} 
	
	resetDamangesArrays(); 
}

stock void resetDamangesArrays(){
	for(int client = 1; client <= MaxClients; client++) {
		timer_client[client]=INVALID_HANDLE;
		entity_client[client] = INVALID_ENT_REFERENCE;
		damangeArray[client][playerid]=client;
		cooldowntime[client]=0.0;
		damangeArray[client][damange] = 0;
		damangeArray[client][kills] = 0;
		damangeArray[client][hits] = 0;
	}
}

stock bool IsValidClient(int client, bool nobots = false )
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
		return false; 
	return IsClientInGame(client); 
}  

stock void PrintToConsoleAll2(const char[] format, any...) 
{
	char text[192];
	VFormat(text, sizeof(text), format, 2);
	/* Removes color variables */
	char removecolor[][] = {"{default}", "{darkred}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}", "{lime}", "{lightred}", "{purple}", "{grey}", "{orange}", "{bluegrey}", "{lightblue}", "{darkblue}", "{grey2}", "{orchid}", "{lightred2}"};
	for(int color = 0; color < sizeof(removecolor); color++ ) {
		ReplaceString(text, sizeof(text), removecolor[color], "", false);
	}
	for(int client = 1; client <= MaxClients; client++)
		if (IsClientInGame(client)) {
			PrintToConsole(client, text);
		}
}  

stock char toString(int digi)
{ 
	char text[50];
	IntToString(digi, text, sizeof(text));
	/* 
	Format(text, sizeof(text), "%d", digi); 
	*/
	return text; 
}  
