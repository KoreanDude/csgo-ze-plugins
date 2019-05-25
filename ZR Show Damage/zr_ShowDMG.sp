#include <sourcemod>
#include <zombiereloaded>
#include <colorvariables>

public Plugin:myinfo =
{
	name = "[ZR] Show Damage",
	author = "Franc1sco, Modified by. Someone",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!attacker)
		return;

	if(GetClientTeam(attacker) == 2 || ZR_IsClientZombie(attacker))
		return;
		
	if(attacker == client)
		return;
	
	new restante = GetClientHealth(client);
	decl String:input[512];
	
	if(restante > 0)
	{
		new damage = GetEventInt(event, "dmg_health");
		Format(input, 512, "<font class='fontSize-l'>You did <font color='#FF0000'>%i <font color='#FFFFFF'>Damage to <font color='#0066FF'>%N\n<font color='#FFFFFF'>Health Remaining: <font color='#00CC00'>%i", damage, client, restante);
	}
	PrintHintText(attacker, input);
}