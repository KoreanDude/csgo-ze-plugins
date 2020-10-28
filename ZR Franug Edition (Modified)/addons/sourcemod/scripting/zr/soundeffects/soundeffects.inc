/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  soundeffects.inc
 *  Type:		  Core 
 *  Description:   Basic sound-management API.
 *
 *  Copyright (C) 2009-2013  Greyscale, Richard Helgeby
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 */

/**
 * Maximum sound path length.
 */
#define SOUND_MAX_PATH 128

/**
 * Ambient sound channel.
 */
#define SOUND_AMBIENT_CHANNEL 8

#include "zr/soundeffects/voice"
#include "zr/soundeffects/ambientsounds"
#include "zr/soundeffects/zombiesounds"

/**
 * Load sound effects data.
 */
SEffectsLoad()
{
	// Load ambient sound cvars.
	AmbientSoundsLoad();
}

/**
 * Client is joining the server.
 * 
 * @param client	The client index.
 */
SEffectsClientInit(client)
{
	// Forward event to sub-modules.
	//AmbientSoundsClientInit(client);
	ZombieSoundsClientInit(client);
}

/**
 * The round is starting.
 */
SEffectsOnRoundStart()
{
	// Forward event to sub-modules.
	VoiceOnRoundStart();
}

/**
 * The round is ending.
 */
SEffectsOnRoundEnd()
{
	// Forward event to sub-modules.
	VoiceOnRoundEnd();
	//AmbientSoundsOnRoundEnd();
	ZombieSoundsOnRoundEnd();
}

/**
 * Client is spawning into the game.
 * 
 * @param client	The client index.
 */
SEffectsOnClientSpawn(client)
{
	// Forward event to sub-modules.
	VoiceOnClientSpawn(client);
	ZombieSoundsOnClientSpawn(client);
}

/**
 * Client is spawning into the game. *Post
 * 
 * @param client	The client index.
 */
SEffectsOnClientSpawnPost(client)
{
	// Forward event to sub-modules.
	AmbientSoundsOnClientSpawnPost(client);
}

/**
 * Client has been killed.
 * 
 * @param client	The client index.
 */
SEffectsOnClientDeath(client)
{
	// Forward event to sub-modules.
	ZombieSoundsOnClientDeath(client);
}

/**
 * Client has been hurt.
 * 
 * @param client	The client index.
 */
SEffectsOnClientHurt(client)
{
	// Forward event to sub-modules.
	ZombieSoundsOnClientHurt(client);
}

/**
 * Client has been infected.
 * 
 * @param client	The client index.
 */
SEffectsOnClientInfected(client)
{
	// Forward event to sub-modules.
	VoiceOnClientInfected(client);
	ZombieSoundsOnClientInfected(client);
}

/**
 * Client has been turned back human.
 * 
 * @param client	The client index.
 */
SEffectsOnClientHuman(client)
{
	// Forward event to sub-modules.
	VoiceOnClientHuman(client);
}

/**
 * Replay an ambient sound
 * 
 * @param sound	 The path to the sound file (relative to sounds/)
 */ 

/**
 * Emits a sound from a client.
 * 
 * @param client	The client index.
 * @param sound	 The sound file relative to the sound/ directory.
 * @param level	 The attenuation of the sound.
 */
SEffectsEmitSoundFromClient(client, const String:sound[], level = SNDLEVEL_NORMAL)
{
	if (g_Game == Game_CSGO)
	{
		// Precache sound before playing.// Emit sound from client.
		PrecacheSoundAny(sound);
		// Emit sound from client.
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(!zbDisableZSounds[i]) EmitSoundToClientAny(i, sound, client, _, level, _, zfZSoundVolume[i]);
			}
		}
	}
	else
	{
		// Precache sound before playing.// Emit sound from client.
		PrecacheSound(sound);
		// Emit sound from client.
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(!zbDisableZSounds[i]) EmitSoundToClient(i, sound, client, _, level, _, zfZSoundVolume[i]);
			}
		}
	}
}