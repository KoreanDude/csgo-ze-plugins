// Made with help of the following people!
//	Shanapu - timer help!
////////////////////////////////////////////////////////////////////////////////////
//	Master Shake Sidezz! - A lot of help with									////
//	teaching me how to use create cvars and use them, along with the money!		////
// 	PS : Sidez wrote the stock functions for money too! Thanks <3<3<3			////
////////////////////////////////////////////////////////////////////////////////////
//	shadowz_au - some basic help along with the code clean up
//
//
//
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Someone, Modified by. Someone"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>
#include <zombiereloaded>
#include <emitsoundany>

// Written by master shake sidezz or Eassizde! Thanks a bunch :')/////////////////////////////////////////
stock SetClientMoney(int client, int value)
{
	int offset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	SetEntData(client, offset, value);
}

stock GetClientMoney(int client) 
{
	int offset = FindSendPropInfo("CCSPlayer", "m_iAccount");
	return GetEntData(client, offset);
}

//Use this to consolidate some text and shorten the plugin
//Plus this makes it easier to change what the text says since you
//Dont use translation files. -DeweY
//stock bool CheckClientMoney(int client, int clientmoney, int weaponprice)
//{
//	if(clientmoney < weaponprice)
//	{
//		PrintToChat(client, " \x04[BuyCommands]\x06 You do not have enough money!");
//		return false;
//	}
//	return true;
//}
///////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma newdecls required
int g_iSpam[MAXPLAYERS+1];

ConVar g_Cooltime;

//RIFLE////////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_AKPrice;
ConVar g_M4Price;
ConVar g_AUGPrice;
ConVar g_FAMASPrice;
ConVar g_M4SPrice;
ConVar g_GalilPrice;
ConVar g_SG556Price;

//SNIPER //////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_SCAR20Price;
ConVar g_AWPPrice;
ConVar g_SSG08Price;
ConVar g_SniperEnabled;

//SMG//////////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_P90Price;
ConVar g_BizonPrice;
ConVar g_Mac10Price;
ConVar g_Mp9Price;
ConVar g_Mp7Price;
ConVar g_MP5SDPrice;
ConVar g_UMP45Price;
//Shotguns/////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_NovaPrice;
ConVar g_XM1014Price;

//Machine Gun//////////////////////////////////////////////////////////////////////////////////////////
ConVar g_M249Price;
ConVar g_NegevPrice;

// Pistols/////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_USPPrice;
ConVar g_DeagPrice;
ConVar g_F7Price;
ConVar g_GLOCKPrice;
ConVar g_P2KPrice;
ConVar g_CZ7Price;
ConVar g_ELITEPrice;
ConVar g_R8Price;
ConVar g_Tec9Price;
ConVar g_P250Price;

//ETC/////////////////////
ConVar g_KEVPrice;
ConVar g_FlashPrice;

//Extras///////////////////////////////////////////////////////////////////////////////////////////////
ConVar g_DropPri;
ConVar g_DropSec;
EngineVersion g_Game;

///////////////////////////////////////////////////////////////////////////////////////////////////////
public Plugin myinfo = 
{
	name = "[ZR] Buy Commands",
	author = PLUGIN_AUTHOR,
	description = "Buy Commands for Zombie:Reloaded",
	version = PLUGIN_VERSION,
	url = ""
};
 
public void OnPluginStart()
{
	//DEFAULT SPEDIT code, 
	// g_game is a global variable decleared with GetEngineVersion
	// an if statement is then written to confirm if it is indeed on CSGO
	// else write failstate
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO)
	{
		SetFailState("This plugin is for CSGO only");	
	}
	
	//Version
	CreateConVar("sm_buycommands_version", PLUGIN_VERSION, "Guncommands version");
	
	g_Cooltime = CreateConVar("sm_Cooltime", "5", "Rebuy Cooltime");
	
	//Weapon price convars//////////////////////////////////////////////////////////////////////////////////////////////////////
	g_GalilPrice = CreateConVar("sm_gc_galil_p", "2000", "Galil's price");
	g_AKPrice = CreateConVar("sm_gc_ak_p", "2500", "AK's price");
	g_SG556Price = CreateConVar("sm_gc_sg556_p", "3500", "SG556's price");
	g_M4Price = CreateConVar("sm_gc_m4_p", "3100", "M4's price");
	g_M4SPrice = CreateConVar("sm_gc_m4s_p", "3100", "M4-S's price");
	g_AUGPrice = CreateConVar("sm_gc_aug_p", "3500", "AUG's price");
	g_FAMASPrice = CreateConVar("sm_gc_famas_p", "2250", "Famas's price");
	
	//Shotguns
	g_NovaPrice = CreateConVar("sm_gc_nova_p", "1500", "Nova's price");
	g_XM1014Price = CreateConVar("sm_gc_xm1014_p", "3000", "XM1014's price");
	
	//Sniper
	g_SCAR20Price = CreateConVar("sm_gc_scar_p", "5000", "SCAR-20's price");
	g_AWPPrice = CreateConVar("sm_gc_awp_p", "4750", "AWP's price");
	g_SSG08Price = CreateConVar("sm_gc_ssg08_p", "2500", "SSG08's price");
	g_SniperEnabled = CreateConVar("sm_SniperEnabled", "0", "1 - Yes, 0 - No", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//SMG
	g_Mac10Price = CreateConVar("sm_gc_mac10_p", "1400", "Mac10's price");
	g_Mp9Price = CreateConVar("sm_gc_mp9_p", "1250", "MP9's price");
	g_Mp7Price = CreateConVar("sm_gc_mp7_p", "1700", "MP7's price");
	g_MP5SDPrice = CreateConVar("sm_gc_mp5sd_p", "1700", "MP5-SD's price");
	g_UMP45Price = CreateConVar("sm_gc_ump45_p", "1700", "UMP45's price");
	g_BizonPrice = CreateConVar("sm_gc_bizon_p", "1400", "Bizon's price");	
	g_P90Price = CreateConVar("sm_gc_p90_p", "2350", "P900000!");
	
	//Machine Gun
	g_M249Price = CreateConVar("sm_gc_m249_p", "5750", "M249's price");
	g_NegevPrice = CreateConVar("sm_gc_negev_p", "5750", "Negev's price");
	
	//Pistol convars
	g_USPPrice = CreateConVar("sm_gc_usp_p", "400", "USP's' Price");	
 	g_DeagPrice = CreateConVar("sm_gc_deag_p", "650", "Deagle's Price");	
	g_F7Price = CreateConVar("sm_gc_57_p", "750", "Five Seven's Price");	
	g_GLOCKPrice = CreateConVar("sm_gc_glock_p", "400", "Glock's Price!");	
	g_P2KPrice = CreateConVar("sm_gc_p2000_p", "300", "P2000's Price!");	
	g_CZ7Price = CreateConVar("sm_gc_cz_p", "500", "CZ's Price!");	
	g_ELITEPrice = CreateConVar("sm_gc_elites_p", "800", "Elite's Prices!!");	
	g_R8Price = CreateConVar("sm_gc_r8_p", "800", "R8's Price!");	
	g_Tec9Price = CreateConVar("sm_gc_tec9_p", "500", "Tec9's Price'!!");	
	g_P250Price = CreateConVar("sm_gc_p250_p", "300", "P250's Price");	
	
	g_KEVPrice = CreateConVar("sm_gc_kev_p", "1000", "Armor price");
	g_FlashPrice = CreateConVar("sm_gc_flash_p", "1000", "flashbang price");
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Extra convars/////////////////////////////////////////////////////////////////////////////////////////////////////////////
	g_DropPri = CreateConVar("sm_gc_dropprimary", "1", "Force the player to drop his/her primary weapon? 1- yes 0 - no");
	g_DropSec = CreateConVar("sm_gc_dropsecondary", "1", "Force the player to drop his/her secondary weapon? 1- yes 0 - no");
	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//Commands//////////////////////////////////////////////////////////
	//Primary
	RegConsoleCmd("sm_ak", Command_ak, "Spawns a ak47", 0);
	RegConsoleCmd("sm_aug", Command_aug, "Spawns a aug", 0);
	RegConsoleCmd("sm_famas", Command_famas, "Spawns a famas", 0);
	RegConsoleCmd("sm_m4", Command_m4a1, "Spawns a m4a1", 0);
	RegConsoleCmd("sm_m4s", Command_m4a1s, "Spawns a m4a1-s", 0);
	RegConsoleCmd("sm_sg556", Command_sg556, "Spawns a sg556", 0);
	RegConsoleCmd("sm_galil", Command_galil, "Spawns a galil", 0);
	
	//Shotguns
	RegConsoleCmd("sm_nova", Command_nova, "Spawns a nova", 0);
	RegConsoleCmd("sm_xm", Command_xm1014, "Spawns a xm", 0);
	
	//Sniper
	RegConsoleCmd("sm_scar", Command_scar, "Spawns a scar20", 0);
	RegConsoleCmd("sm_awp", Command_awp, "Spawns a awp", 0);
	RegConsoleCmd("sm_ssg", Command_ssg08, "Spawns a ssg08", 0);
	RegConsoleCmd("sm_ssg08", Command_ssg08, "Spawns a ssg08", 0);
	
	//SMG
	RegConsoleCmd("sm_bizon", Command_bizon, "Spawns a bizon", 0);
	RegConsoleCmd("sm_p90", Command_p90, "Spawns a p90", 0);
	RegConsoleCmd("sm_mac10", Command_mac10, "Spawns a mac10", 0);
	RegConsoleCmd("sm_mp9", Command_mp9, "Spawns a mp9", 0);
	RegConsoleCmd("sm_mp7", Command_mp7, "Spawns a mp7", 0);
	RegConsoleCmd("sm_mp5", Command_mp5, "Spawns a mp5sd", 0);
	RegConsoleCmd("sm_ump", Command_ump45, "Spawns a ump45", 0);
	
	//Machine Gun
	RegConsoleCmd("sm_m249", Command_m249, "Spawns a m249", 0);
	RegConsoleCmd("sm_negev", Command_negev, "Spawns a negev", 0);
	
	//Pistols
	RegConsoleCmd("sm_usp", Command_usp, "Spawns a usp", 0);
	RegConsoleCmd("sm_glock", Command_glock, "Spawns a glock", 0);
	RegConsoleCmd("sm_p250", Command_p250, "Spawns a p250", 0);
	RegConsoleCmd("sm_deagle", Command_deag, "Spawns a deagle", 0);
	RegConsoleCmd("sm_57", Command_57, "Spawns a fiveseven", 0);
	RegConsoleCmd("sm_cz", Command_cz, "Spawns a cz", 0);
	RegConsoleCmd("sm_r8", Command_r8, "Spawns a r8", 0);
	RegConsoleCmd("sm_elite", Command_elites, "Spawns a elite", 0);
	RegConsoleCmd("sm_tec9", Command_tec9, "Spawns a tec9", 0);
	RegConsoleCmd("sm_p2000", Command_p2k, "Spawns a p2000", 0);

	RegConsoleCmd("sm_kev", Command_armor, "Spawns a armor", 0);
	RegConsoleCmd("sm_kevlar", Command_armor, "Spawns a armor", 0);
	RegConsoleCmd("sm_fb", Command_flash, "Spawns a flashbang", 0);
	RegConsoleCmd("sm_flash", Command_flash, "Spawns a flashbang", 0);
	////////////////////////////////////////////////////////////////////
	AutoExecConfig(true, "sm_buycommands");
}

public void OnMapStart()
{
	PrecacheSoundAny("items/smallmedkit.mp3", true);
}

public void OnClientConnected(int client){

	g_iSpam[client] = 0;

}
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			g_iSpam[i] = 0;
}
//#define Cooltime 5
///////////////////////////////////////////////////////////////////////////////////////////////////////
//galil//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_galil(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_GalilPrice.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Galilar Price:\x05 $%i", g_GalilPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_galilar");
			}
			else GivePlayerItem(client, "weapon_galilar");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//AK47//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_ak(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_AKPrice.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 AK47 Price:\x05 $%i", g_AKPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_ak47");
			}
			else GivePlayerItem(client, "weapon_ak47");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//SG556//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_sg556(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_SG556Price.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 SG556 Price:\x05 $%i", g_SG556Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_sg556");
			}
			else GivePlayerItem(client, "weapon_sg556");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//nova//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_nova(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_NovaPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Nova Price:\x05 $%i", g_NovaPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_nova");
			}
			else GivePlayerItem(client, "weapon_nova");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//XM1014//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_xm1014(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_XM1014Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 XM1014 Price:\x05 $%i", g_XM1014Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_xm1014");
			}
			else GivePlayerItem(client, "weapon_xm1014");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Mac10//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_mac10(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_Mac10Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Mac10 Price:\x05 $%i", g_Mac10Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_mac10");
			}
			else GivePlayerItem(client, "weapon_mac10");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Mp9//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_mp9(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_Mp9Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 MP9 Price:\x05 $%i", g_Mp9Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_mp9");
			}
			else GivePlayerItem(client, "weapon_mp9");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Mp7//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_mp7(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_Mp7Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Mp7 Price:\x05 $%i", g_Mp7Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_mp7");
			}
			else GivePlayerItem(client, "weapon_mp7");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//MP5SD//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_mp5(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_MP5SDPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 MP5SD Price:\x05 $%i", g_MP5SDPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_mp5sd");
			}
			else GivePlayerItem(client, "weapon_mp5sd");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//UMP45//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_ump45(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_UMP45Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 UMP45 Price:\x05 $%i", g_UMP45Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_ump45");
			}
			else GivePlayerItem(client, "weapon_ump45");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//M249//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_m249(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_M249Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 M249 Price:\x05 $%i", g_M249Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_m249");
			}
			else GivePlayerItem(client, "weapon_m249");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//NEGEV//////////////////////////////////////////////////////////////////////////////////////////
public Action Command_negev(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_NegevPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Negev Price:\x05 $%i", g_NegevPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_negev");
			}
			else GivePlayerItem(client, "weapon_negev");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//BIZON///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_bizon(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_BizonPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 BIZON Price:\x05 $%i", g_BizonPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_bizon");
			}
			else GivePlayerItem(client, "weapon_bizon");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//P90///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_p90(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_P90Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 P90 Price:\x05 $%i", g_P90Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_p90");
			}
			else GivePlayerItem(client, "weapon_p90");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//SCAR20///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_scar(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	if(!g_SniperEnabled.BoolValue)
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You cat buy SCAR-20 on this map.");
		return Plugin_Handled;
	}
	
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_SCAR20Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 SCAR20 Price:\x05 $%i", g_SCAR20Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_scar20");
			}
			else GivePlayerItem(client, "weapon_scar20");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//AWP///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_awp(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	if(!g_SniperEnabled.BoolValue)
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You cat buy AWP on this map.");
		return Plugin_Handled;
	}
	
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_AWPPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 AWP Price:\x05 $%i", g_AWPPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_awp");
			}
			else GivePlayerItem(client, "weapon_awp");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//SSG08///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_ssg08(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	if(!g_SniperEnabled.BoolValue)
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You cat buy SSG08 on this map.");
		return Plugin_Handled;
	}
	
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_SSG08Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 SSG08 Price:\x05 $%i", g_SSG08Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_ssg08");
			}
			else GivePlayerItem(client, "weapon_ssg08");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//M4A1///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_m4a1(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_M4Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 M4 Price:\x05 $%i", g_M4Price.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_m4a1");
			}
			else GivePlayerItem(client, "weapon_m4a1");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//M4A1-Silenced ///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_m4a1s(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_M4SPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 M4S Price:\x05 $%i", g_M4SPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_m4a1_silencer");
			}
			else GivePlayerItem(client, "weapon_m4a1_silencer");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//AUG///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_aug(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_AUGPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 AUG Price:\x05 $%i", g_AUGPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		//Checks cvar
		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_aug");
			}
			else GivePlayerItem(client, "weapon_aug");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//FAMAS///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_famas(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	if(g_iSpam[client] > GetTime())
	{
		PrintToChat(client, " \x04[BuyCommands]\x06 You can purchase it again in %i seconds.",g_iSpam[client]-GetTime());
		return Plugin_Handled;
	}
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_FAMASPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 FAMAS Price:\x05 $%i", g_FAMASPrice.IntValue);

		g_iSpam[client] = GetTime()+g_Cooltime.IntValue;

		//Checks cvar
		if (g_DropPri.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_famas");
			}
			else GivePlayerItem(client, "weapon_famas");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//USP///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_usp(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_USPPrice.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 USP Price:\x05 $%i", g_USPPrice.IntValue);

		
		
		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_usp_silencer");
			}
			else GivePlayerItem(client, "weapon_usp_silencer");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//Glock///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_glock(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_GLOCKPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Glock Price:\x05 $%i", g_GLOCKPrice.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_glock");
			}
			else GivePlayerItem(client, "weapon_glock");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//P250///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_p250(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_P250Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 P250 Price:\x05 $%i", g_P250Price.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_p250");
			}
			else GivePlayerItem(client, "weapon_p250");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//DEAGLE///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_deag(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_DeagPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Deagle Price:\x05 $%i", g_DeagPrice.IntValue);

		
		
		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_deagle");
			}
			else GivePlayerItem(client, "weapon_deagle");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//TEC9///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_tec9(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_Tec9Price.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Tec9 Price:\x05 $%i", g_Tec9Price.IntValue);

		
		
		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_tec9");
			}
			else GivePlayerItem(client, "weapon_tec9");
		}
	}
	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//p2000///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_p2k(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_P2KPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 HKP2000 Price:\x05 $%i", g_P2KPrice.IntValue);

		
		
		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_hkp2000");
			}
			else GivePlayerItem(client, "weapon_hkp2000");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//ELITES///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_elites(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_ELITEPrice.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Elite Price:\x05 $%i", g_ELITEPrice.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_elite");
			}
			else GivePlayerItem(client, "weapon_elite");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//FIVESEVEN///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_57(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_F7Price.IntValue;
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 Fiveseven Price:\x05 $%i", g_F7Price.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_fiveseven");
			}
			else GivePlayerItem(client, "weapon_fiveseven");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//R8///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_r8(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;

	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_R8Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 R8 Price:\x05 $%i", g_R8Price.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_revolver");
			}
			else GivePlayerItem(client, "weapon_revolver");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//CZ///////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_cz(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	
	//Declaring the client's money
	int cmoney = GetClientMoney(client);
	//Declaring gunprice that links to cvar
	int gunprice = g_CZ7Price.IntValue;
	
	
	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);
		PrintToChat(client, " \x04[BuyCommands]\x06 CZ75A Price:\x05 $%i", g_CZ7Price.IntValue);

		

		//Checks cvar
		if (g_DropSec.BoolValue)
		{
			//Forces player to drop his/her weapon=====
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
			if(weapon != -1)
			{
				SDKHooks_DropWeapon(client, weapon);
				GivePlayerItem(client, "weapon_cz75a");
			}
			else GivePlayerItem(client, "weapon_cz75a");
		}
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////
//ETC////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
public Action Command_armor(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	
	int cmoney = GetClientMoney(client);
	int gunprice = g_KEVPrice.IntValue;

	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);

		// Thanks to https://forums.alliedmods.net/showthread.php?t=250093
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
public Action Command_flash(int client,int args)
{
	if(!IsPlayerAlive(client) || !IsClientInGame(client) || !IsValidClient(client) || !ZR_IsClientHuman(client)) return Plugin_Handled;
	
	int cmoney = GetClientMoney(client);
	int gunprice = g_FlashPrice.IntValue;

	if (cmoney > gunprice)
	{
		SetClientMoney(client,cmoney - gunprice);
		EmitSoundToClientAny(client, "items/smallmedkit.mp3", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 0.3);

		FlashGrenade(client);
		PrintToChat(client, " \x04[BuyCommands]\x06 Flashbang Price:\x05 $%i", g_FlashPrice.IntValue);
	}

	else if (cmoney < gunprice) PrintToChat(client, " \x04[BuyCommands]\x0F You don't have enough money.");
	
	return Plugin_Handled;
}
public void FlashGrenade(int client)
{
	int offset2 = FindDataMapInfo(client,"m_iAmmo")+(4*15);
	int current2 = GetEntData(client,offset2,4);
	if (current2 == 0)  GivePlayerItem(client, "weapon_flashbang");
	else SetEntData(client,offset2,current2+1);
}