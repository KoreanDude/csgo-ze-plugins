/*
 * ============================================================================
 *
 *  Zombie:Reloaded
 *
 *  File:		  ambientsounds.inc
 *  Type:		  Core 
 *  Description:   Plays ambient sounds to clients.
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
 * Global variable that tells if ambient sound cvar data was loaded successfully.
 */ 
new bool:g_bAmbientSounds;

/**
 * Load ambient sound data.
 */
AmbientSoundsLoad()
{
	// Validate cvars.
	g_bAmbientSounds = AmbientSoundsValidateConfig();
}

/**
 * Validate ambient sounds cvars.
 */
bool:AmbientSoundsValidateConfig()
{
	// If ambience is disabled, then stop.
	new bool:ambience = GetConVarBool(g_hCvarsList[CVAR_AMBIENTSOUNDS]);
	if (!ambience)
	{
		g_bAmbientSounds = false;
		return false;
	}
	
	// Get ambient sound file.
	decl String:sound[SOUND_MAX_PATH];
	GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
	Format(sound, sizeof(sound), "sound/%s", sound);
	
	// If file doesn't exist, then log error and stop.
	if (!FileExists(sound, true))
	{
		// Log invalid sound file error.
		LogEvent(false, LogType_Error, LOG_CORE_EVENTS, LogModule_SEffects, "Config Validation", "Invalid sound file specified in \"zr_ambientsounds_file\": %s", sound);
		return false;
	}
	
	// Add sound file to downloads table.
	AddFileToDownloadsTable(sound);
	
	g_bAmbientSounds = true;
	return true;
}

/**
 * Client is spawning into the game.
 * 
 * @param client	The client index.
 */
AmbientSoundsOnClientSpawnPost(client)
{
	// If ambience is disabled, then stop.
	if (!g_bAmbientSounds)
	{
		return;
	}
	
	// Get ambient sound file.
	decl String:sound[SOUND_MAX_PATH];
	GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
	
	// Emit ambient sound.
	//SEffectsEmitAmbientSound(sound, client);
	if(IsClientInGame(client))
	{
		if(!zbDisableAmbient[client])
		{
			StopSound(client, SNDCHAN_STATIC, sound);
			CreateTimer(0.1, Play_Ambient, client);
		}
	}
}

public Action:Play_Ambient(Handle:timer, any:client)
{
	if(!IsClientInGame(client)) return;

	// Get ambient sound file.
	decl String:sound[SOUND_MAX_PATH];
	GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
	
	EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, _, _, zfAmbientVolume[client]);
}