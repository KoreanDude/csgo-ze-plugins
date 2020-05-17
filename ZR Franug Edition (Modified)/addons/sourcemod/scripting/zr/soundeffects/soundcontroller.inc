#define ZSOUND_COUNTDOWN_COOKIE_ENABLED "zr_disabledcountdown"
#define ZSOUND_ZOMBIE_COOKIE_ENABLED "zr_disabledzombiesound"
#define ZSOUND_AMBIENT_COOKIE_ENABLED "zr_disabledambient"
#define ZVOLUME_COUNTDOWN_COOKIE_ENABLED "zr_countdownvolume"
#define ZVOLUME_ZOMBIE_COOKIE_ENABLED "zr_zombievolume"
#define ZVOLUME_AMBIENT_COOKIE_ENABLED "zr_ambientvolume"

#define SOUND_MAX_PATH 128

Handle zhDisableCountdown = INVALID_HANDLE;
Handle zhDisableZSound = INVALID_HANDLE;
Handle zhDisableAmbient = INVALID_HANDLE;
Handle zhCountdownVolume = INVALID_HANDLE;
Handle zhZSoundVolume = INVALID_HANDLE;
Handle zhZAmbientVolume = INVALID_HANDLE;

float zfZSoundVolume[MAXPLAYERS+1];
float zfCountdownVolume[MAXPLAYERS+1];
float zfAmbientVolume[MAXPLAYERS+1];
bool zbDisableZSounds[MAXPLAYERS+1];
bool zbDisableCountdown[MAXPLAYERS+1];
bool zbDisableAmbient[MAXPLAYERS+1];

// Plugin Load
ZVolumeInit()
{
	RegConsoleCmd("sm_zvol", Command_ZVolume, "Brings up the zvolume menu");
	RegConsoleCmd("sm_zvolume", Command_ZVolume, "Brings up the zvolume menu");
	RegConsoleCmd("sm_zcount", Command_Countdown, "Brings up the countdown menu");
	RegConsoleCmd("sm_zsound", Command_ZSound, "Brings up the zsound menu");
	RegConsoleCmd("sm_zambient", Command_ZAmbient, "Brings up the ambient menu");
}

MusicCookiesCreate()
{
	if (zhDisableCountdown == INVALID_HANDLE) zhDisableCountdown = RegClientCookie(ZSOUND_COUNTDOWN_COOKIE_ENABLED, "Disable Countdown Sound.", CookieAccess_Protected);
	if (zhDisableZSound == INVALID_HANDLE) zhDisableZSound = RegClientCookie(ZSOUND_ZOMBIE_COOKIE_ENABLED, "Disable Zombie Sound.", CookieAccess_Protected);
	if (zhDisableAmbient == INVALID_HANDLE) zhDisableAmbient = RegClientCookie(ZSOUND_AMBIENT_COOKIE_ENABLED, "Disable Ambient Sound.", CookieAccess_Protected);
	if (zhCountdownVolume == INVALID_HANDLE) zhCountdownVolume = RegClientCookie(ZVOLUME_COUNTDOWN_COOKIE_ENABLED, "Control Countdown Sound.", CookieAccess_Protected);
	if (zhZSoundVolume == INVALID_HANDLE) zhZSoundVolume = RegClientCookie(ZVOLUME_ZOMBIE_COOKIE_ENABLED, "Control Zombie Sound.", CookieAccess_Protected);
	if (zhZAmbientVolume == INVALID_HANDLE) zhZAmbientVolume = RegClientCookie(ZVOLUME_AMBIENT_COOKIE_ENABLED, "Control Ambient Sound.", CookieAccess_Protected);
}

MusicCookiesCached(client)
{
	char sValue[8];

	sValue[0] = '\0';
	GetClientCookie(client, zhZSoundVolume, sValue, sizeof(sValue));
	if (sValue[0] == '\0')
	{
		SetClientCookie(client, zhZSoundVolume, "50");
		strcopy(sValue, sizeof(sValue), "50");
	}
	SetVolume_ZSound(client, StringToInt(sValue));

	sValue[0] = '\0';
	GetClientCookie(client, zhDisableZSound, sValue, sizeof(sValue));
	if (sValue[0] == '\0')
	{
		SetClientCookie(client, zhDisableZSound, "0");
		strcopy(sValue, sizeof(sValue), "0");
	}
	SetStatus_ZSound(client, view_as<bool>(StringToInt(sValue)));

	sValue[0] = '\0';
	GetClientCookie(client, zhDisableCountdown, sValue, sizeof(sValue));
	if (sValue[0] == '\0')
	{
		SetClientCookie(client, zhDisableCountdown, "0");
		strcopy(sValue, sizeof(sValue), "0");
	}
	SetStatus_Countdown(client, view_as<bool>(StringToInt(sValue)));
	
	sValue[0] = '\0';
	GetClientCookie(client, zhCountdownVolume, sValue, sizeof(sValue));
	if (sValue[0] == '\0') 
	{
		SetClientCookie(client, zhCountdownVolume, "50");
		strcopy(sValue, sizeof(sValue), "50");
	}
	SetVolume_Countdown(client, StringToInt(sValue));
	
	sValue[0] = '\0';
	GetClientCookie(client, zhDisableAmbient, sValue, sizeof(sValue));
	if (sValue[0] == '\0')
	{
		SetClientCookie(client, zhDisableAmbient, "0");
		strcopy(sValue, sizeof(sValue), "0");
	}
	SetStatus_Ambient(client, view_as<bool>(StringToInt(sValue)));
	
	sValue[0] = '\0';
	GetClientCookie(client, zhZAmbientVolume, sValue, sizeof(sValue));
	if (sValue[0] == '\0') 
	{
		SetClientCookie(client, zhZAmbientVolume, "50");
		strcopy(sValue, sizeof(sValue), "50");
	}
	SetVolume_Ambient(client, StringToInt(sValue));
}

public Action Command_ZVolume(int client, int args)
{
	if (client < 1 || client > MaxClients) return Plugin_Handled;

	if (GetCmdArgs() < 1)
	{
		DisplaySettingsMenu(client);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_Countdown(int client, int args)
{
	if (client < 1 || client > MaxClients) return Plugin_Handled;

	if (GetCmdArgs() < 1)
	{
		CountdownMenu(client);
		return Plugin_Handled;
	}
	
	char sArguments[256];
	GetCmdArg(1, sArguments, sizeof(sArguments));

	if (StrContains(sArguments, "off", false) > -1 || StrContains(sArguments, "disable", false) > -1 || StrContains(sArguments, "stop", false) > -1 || (strncmp(sArguments, "0", 1) == 0 && sArguments[1] == '\0'))
	{
		SetStatus_Countdown(client, true);
		return Plugin_Handled;
	}
	else if (StrContains(sArguments, "on", false) > -1 || StrContains(sArguments, "enable", false) > -1 || StrContains(sArguments, "play", false) > -1)
	{
		SetStatus_Countdown(client, false);
		return Plugin_Handled;
	}
	SetVolume_Countdown(client, StringToInt(sArguments));

	return Plugin_Handled;
}

public Action Command_ZSound(int client, int args)
{
	if (client < 1 || client > MaxClients) return Plugin_Handled;

	if (GetCmdArgs() < 1)
	{
		ZSoundMenu(client);
		return Plugin_Handled;
	}
	
	char sArguments[256];
	GetCmdArg(1, sArguments, sizeof(sArguments));

	if (StrContains(sArguments, "off", false) > -1 || StrContains(sArguments, "disable", false) > -1 || StrContains(sArguments, "stop", false) > -1 || (strncmp(sArguments, "0", 1) == 0 && sArguments[1] == '\0'))
	{
		SetStatus_ZSound(client, true);
		return Plugin_Handled;
	}
	else if (StrContains(sArguments, "on", false) > -1 || StrContains(sArguments, "enable", false) > -1 || StrContains(sArguments, "play", false) > -1)
	{
		SetStatus_ZSound(client, false);
		return Plugin_Handled;
	}
	SetVolume_ZSound(client, StringToInt(sArguments));

	return Plugin_Handled;
}

public Action Command_ZAmbient(int client, int args)
{
	if (client < 1 || client > MaxClients) return Plugin_Handled;

	if (GetCmdArgs() < 1)
	{
		AmbientMenu(client);
		return Plugin_Handled;
	}
	
	// Get ambient sound file.
	decl String:sound[SOUND_MAX_PATH];
	GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
	
	StopSound(client, SNDCHAN_STATIC, sound);
	
	char sArguments[256];
	GetCmdArg(1, sArguments, sizeof(sArguments));

	if (StrContains(sArguments, "off", false) > -1 || StrContains(sArguments, "disable", false) > -1 || StrContains(sArguments, "stop", false) > -1 || (strncmp(sArguments, "0", 1) == 0 && sArguments[1] == '\0'))
	{
		SetStatus_Ambient(client, true);
		return Plugin_Handled;
	}
	else if (StrContains(sArguments, "on", false) > -1 || StrContains(sArguments, "enable", false) > -1 || StrContains(sArguments, "play", false) > -1)
	{
		SetStatus_Ambient(client, false);
		return Plugin_Handled;
	}
	SetVolume_Ambient(client, StringToInt(sArguments));

	return Plugin_Handled;
}

public DisplaySettingsMenu(int client)
{
	Menu prefmenu = CreateMenu(PrefMenuHandler, MENU_ACTIONS_DEFAULT);

	char szMenuTitle[64];
	Format(szMenuTitle, sizeof(szMenuTitle), "%T", "Menu_Title_Main", client);
	prefmenu.SetTitle(szMenuTitle);
	
	char szZSound[256];
	Format(szZSound, sizeof(szZSound), "%T", "Menu_ZSound", client);
	prefmenu.AddItem("zsound", szZSound);
	
	char szCountdown[256];
	Format(szCountdown, sizeof(szCountdown), "%T", "Menu_Countdown", client);
	prefmenu.AddItem("countdown", szCountdown);
	
	char szAmbient[256];
	Format(szAmbient, sizeof(szAmbient), "%T", "Menu_Ambient", client);
	prefmenu.AddItem("ambient", szAmbient);

	prefmenu.ExitBackButton = true;

	prefmenu.Display(client, MENU_TIME_FOREVER);
	
	return true;
}

public int PrefMenuHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
	if (actions == MenuAction_Select)
	{
		char preference[16];
		GetMenuItem(prefmenu, item, preference, sizeof(preference));
		
		if (StrEqual(preference, "zsound"))
		{
			ZSoundMenu(client);
		}
		else if (StrEqual(preference, "countdown"))
		{
			CountdownMenu(client);
		}
		else if (StrEqual(preference, "ambient"))
		{
			AmbientMenu(client);
		}
	}
	else if (actions == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			ZMenuMain(client);
		}
	}
	else if (actions == MenuAction_End)
	{
		delete prefmenu;
	}
}

void ZSoundMenu(int client)
{
	Menu prefmenu = CreateMenu(ZSoundMenuHandler, MENU_ACTIONS_DEFAULT);

	char szMenuTitle[64];
	Format(szMenuTitle, sizeof(szMenuTitle), "%T", "Menu_Title_ZSound", client);
	prefmenu.SetTitle(szMenuTitle);

	char szEnable[256];
	Format(szEnable, sizeof(szEnable), "%T\n \n%T", "Menu_Music_ZSound", client, GetStatus_ZSound(client) ? "Disabled" : "Enabled", client, "Menu_AdjustDesc_ZSound", client);
	prefmenu.AddItem(GetStatus_ZSound(client) ? "enable" : "disable", szEnable);

	char szItem[32];
	int iVolume = GetVolume_ZSound(client);
	Format(szItem, sizeof(szItem), "%T", "Menu_Vol_ZSound", client, iVolume);
	switch (iVolume)
	{
		case 100:
		{
			prefmenu.AddItem("vol_90", szItem);
		}
		case 90:
		{
			prefmenu.AddItem("vol_80", szItem);
		}
		case 80:
		{
			prefmenu.AddItem("vol_70", szItem);
		}
		case 70:
		{
			prefmenu.AddItem("vol_60", szItem);
		}
		case 60:
		{
			prefmenu.AddItem("vol_50", szItem);
		}
		case 50:
		{
			prefmenu.AddItem("vol_40", szItem);
		}
		case 40:
		{
			prefmenu.AddItem("vol_30", szItem);
		}
		case 30:
		{
			prefmenu.AddItem("vol_20", szItem);
		}
		case 20:
		{
			prefmenu.AddItem("vol_10", szItem);
		}
		case 10:
		{
			prefmenu.AddItem("vol_5", szItem);
		}
		case 5:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
		default:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
	}

	prefmenu.ExitBackButton = true;

	prefmenu.Display(client, MENU_TIME_FOREVER);
}

public int ZSoundMenuHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
	if (actions == MenuAction_Select)
	{
		char preference[8];
		GetMenuItem(prefmenu, item, preference, sizeof(preference));

		if (StrEqual(preference, "disable"))
		{
			SetStatus_ZSound(client, true);
		}
		else if (StrEqual(preference, "enable"))
		{
			SetStatus_ZSound(client, false);
		}

		if (strncmp(preference, "vol_", 4) == 0)
		{
			SetVolume_ZSound(client, StringToInt(preference[4]));
		}

		ZSoundMenu(client);
	}
	else if (actions == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			DisplaySettingsMenu(client);
		}
	}
	else if (actions == MenuAction_End)
	{
		delete prefmenu;
	}
}

void CountdownMenu(int client)
{
	Menu prefmenu = CreateMenu(CountdownMenuHandler, MENU_ACTIONS_DEFAULT);

	char szMenuTitle[64];
	Format(szMenuTitle, sizeof(szMenuTitle), "%T", "Menu_Title_Countdown", client);
	prefmenu.SetTitle(szMenuTitle);

	char szEnable[256];
	Format(szEnable, sizeof(szEnable), "%T\n \n%T", "Menu_Music_Countdown", client, GetStatus_Countdown(client) ? "Disabled" : "Enabled", client, "Menu_AdjustDesc_Countdown", client);
	prefmenu.AddItem(GetStatus_Countdown(client) ? "enable" : "disable", szEnable);

	char szItem[32];
	int iVolume = GetVolume_Countdown(client);
	Format(szItem, sizeof(szItem), "%T", "Menu_Vol_Countdown", client, iVolume);
	switch (iVolume)
	{
		case 100:
		{
			prefmenu.AddItem("vol_90", szItem);
		}
		case 90:
		{
			prefmenu.AddItem("vol_80", szItem);
		}
		case 80:
		{
			prefmenu.AddItem("vol_70", szItem);
		}
		case 70:
		{
			prefmenu.AddItem("vol_60", szItem);
		}
		case 60:
		{
			prefmenu.AddItem("vol_50", szItem);
		}
		case 50:
		{
			prefmenu.AddItem("vol_40", szItem);
		}
		case 40:
		{
			prefmenu.AddItem("vol_30", szItem);
		}
		case 30:
		{
			prefmenu.AddItem("vol_20", szItem);
		}
		case 20:
		{
			prefmenu.AddItem("vol_10", szItem);
		}
		case 10:
		{
			prefmenu.AddItem("vol_5", szItem);
		}
		case 5:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
		default:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
	}

	prefmenu.ExitBackButton = true;

	prefmenu.Display(client, MENU_TIME_FOREVER);
}

public int CountdownMenuHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
	if (actions == MenuAction_Select)
	{
		char preference[8];
		GetMenuItem(prefmenu, item, preference, sizeof(preference));

		if (StrEqual(preference, "disable"))
		{
			SetStatus_Countdown(client, true);
		}
		else if (StrEqual(preference, "enable"))
		{
			SetStatus_Countdown(client, false);
		}

		if (strncmp(preference, "vol_", 4) == 0)
		{
			SetVolume_Countdown(client, StringToInt(preference[4]));
		}

		CountdownMenu(client);
	}
	else if (actions == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			DisplaySettingsMenu(client);
		}
	}
	else if (actions == MenuAction_End)
	{
		delete prefmenu;
	}
}

void AmbientMenu(int client)
{
	Menu prefmenu = CreateMenu(AmbientMenuHandler, MENU_ACTIONS_DEFAULT);

	char szMenuTitle[64];
	Format(szMenuTitle, sizeof(szMenuTitle), "%T", "Menu_Title_Ambient", client);
	prefmenu.SetTitle(szMenuTitle);

	char szEnable[256];
	Format(szEnable, sizeof(szEnable), "%T\n \n%T", "Menu_Music_Ambient", client, GetStatus_Ambient(client) ? "Disabled" : "Enabled", client, "Menu_AdjustDesc_Ambient", client);
	prefmenu.AddItem(GetStatus_Ambient(client) ? "enable" : "disable", szEnable);

	char szItem[32];
	int iVolume = GetVolume_Ambient(client);
	Format(szItem, sizeof(szItem), "%T", "Menu_Vol_Ambient", client, iVolume);
	switch (iVolume)
	{
		case 100:
		{
			prefmenu.AddItem("vol_90", szItem);
		}
		case 90:
		{
			prefmenu.AddItem("vol_80", szItem);
		}
		case 80:
		{
			prefmenu.AddItem("vol_70", szItem);
		}
		case 70:
		{
			prefmenu.AddItem("vol_60", szItem);
		}
		case 60:
		{
			prefmenu.AddItem("vol_50", szItem);
		}
		case 50:
		{
			prefmenu.AddItem("vol_40", szItem);
		}
		case 40:
		{
			prefmenu.AddItem("vol_30", szItem);
		}
		case 30:
		{
			prefmenu.AddItem("vol_20", szItem);
		}
		case 20:
		{
			prefmenu.AddItem("vol_10", szItem);
		}
		case 10:
		{
			prefmenu.AddItem("vol_5", szItem);
		}
		case 5:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
		default:
		{
			prefmenu.AddItem("vol_100", szItem);
		}
	}

	prefmenu.ExitBackButton = true;

	prefmenu.Display(client, MENU_TIME_FOREVER);
}

public int AmbientMenuHandler(Menu prefmenu, MenuAction actions, int client, int item)
{
	if (actions == MenuAction_Select)
	{
		char preference[8];
		GetMenuItem(prefmenu, item, preference, sizeof(preference));
		
		// Get ambient sound file.
		decl String:sound[SOUND_MAX_PATH];
		GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
		
		StopSound(client, SNDCHAN_STATIC, sound);

		if (StrEqual(preference, "disable"))
		{
			SetStatus_Ambient(client, true);
		}
		else if (StrEqual(preference, "enable"))
		{
			SetStatus_Ambient(client, false);
		}

		if (strncmp(preference, "vol_", 4) == 0)
		{
			SetVolume_Ambient(client, StringToInt(preference[4]));
		}

		AmbientMenu(client);
	}
	else if (actions == MenuAction_Cancel)
	{
		if (item == MenuCancel_ExitBack)
		{
			DisplaySettingsMenu(client);
		}
	}
	else if (actions == MenuAction_End)
	{
		delete prefmenu;
	}
}

int GetVolume_ZSound(int client)
{
	return RoundToCeil(zfZSoundVolume[client] * 100);
}

void SetVolume_ZSound(int client, int volume)
{
	zfZSoundVolume[client] = volume * 0.01;

	if (volume <= 0)
	{
		zfZSoundVolume[client] = 0.0;
	}

	if (volume > 100)
	{
		zfZSoundVolume[client] = 1.0;
	}
	
	char sValue[8];
	IntToString(volume, sValue, sizeof(sValue));
	SetClientCookie(client, zhZSoundVolume, sValue);
	if(IsClientInGame(client)) TranslationPrintToChat(client, "Text_ZSoundVolume", volume);
	
	zbDisableZSounds[client] = false;
	char sValue_Block[8];
	IntToString(view_as<int>(zbDisableZSounds[client]), sValue_Block, sizeof(sValue_Block));
	SetClientCookie(client, zhDisableZSound, sValue_Block);
}

bool GetStatus_ZSound(int client)
{
	return zbDisableZSounds[client];
}

void SetStatus_ZSound(int client, bool bBlockZombieSound)
{
	zbDisableZSounds[client] = bBlockZombieSound;
	
	char sValue[8];
	IntToString(view_as<int>(bBlockZombieSound), sValue, sizeof(sValue));
	SetClientCookie(client, zhDisableZSound, sValue);
	
	if(IsClientInGame(client)) TranslationPrintToChat(client, bBlockZombieSound ? "Text_ZSoundDisable" : "Text_ZSoundEnable");
}

int GetVolume_Countdown(int client)
{
	return RoundToCeil(zfCountdownVolume[client] * 100);
}

void SetVolume_Countdown(int client, int volume)
{
	zfCountdownVolume[client] = volume * 0.01;

	if (volume <= 0)
	{
		zfCountdownVolume[client] = 0.0;
	}

	if (volume > 100)
	{
		zfCountdownVolume[client] = 1.0;
	}
	
	char sValue[8];
	IntToString(volume, sValue, sizeof(sValue));
	SetClientCookie(client, zhCountdownVolume, sValue);
	if(IsClientInGame(client)) TranslationPrintToChat(client, "Text_CountdownVolume", volume);
	
	zbDisableCountdown[client] = false;
	char sValue_Block[8];
	IntToString(view_as<int>(zbDisableCountdown[client]), sValue_Block, sizeof(sValue_Block));
	SetClientCookie(client, zhDisableCountdown, sValue_Block);
}

bool GetStatus_Countdown(int client)
{
	return zbDisableCountdown[client];
}

void SetStatus_Countdown(int client, bool bBlockCountdownSound)
{
	zbDisableCountdown[client] = bBlockCountdownSound;
	
	char sValue[8];
	IntToString(view_as<int>(bBlockCountdownSound), sValue, sizeof(sValue));
	SetClientCookie(client, zhDisableCountdown, sValue);
	
	if(IsClientInGame(client)) TranslationPrintToChat(client, bBlockCountdownSound ? "Text_CountdownDisable" : "Text_CountdownEnable");
}

int GetVolume_Ambient(int client)
{
	return RoundToCeil(zfAmbientVolume[client] * 100);
}

void SetVolume_Ambient(int client, int volume)
{
	zfAmbientVolume[client] = volume * 0.01;

	if (volume <= 0)
	{
		zfAmbientVolume[client] = 0.0;
	}

	if (volume > 100)
	{
		zfAmbientVolume[client] = 1.0;
	}
	
	char sValue[8];
	IntToString(volume, sValue, sizeof(sValue));
	SetClientCookie(client, zhZAmbientVolume, sValue);
	
	zbDisableAmbient[client] = false;
	char sValue_Block[8];
	IntToString(view_as<int>(zbDisableAmbient[client]), sValue_Block, sizeof(sValue_Block));
	SetClientCookie(client, zhDisableAmbient, sValue_Block);
	
	if(IsClientInGame(client))
	{
		TranslationPrintToChat(client, "Text_AmbientVolume", volume);
		
		// Get ambient sound file.
		decl String:sound[SOUND_MAX_PATH];
		GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));

		StopSound(client, SNDCHAN_STATIC, sound);
		EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, _, _, zfAmbientVolume[client]);
	}
}

bool GetStatus_Ambient(int client)
{
	return zbDisableAmbient[client];
}

void SetStatus_Ambient(int client, bool bBlockAmbientSound)
{
	zbDisableAmbient[client] = bBlockAmbientSound;
	
	char sValue[8];
	IntToString(view_as<int>(bBlockAmbientSound), sValue, sizeof(sValue));
	SetClientCookie(client, zhDisableAmbient, sValue);
	
	if(IsClientInGame(client))
	{
		TranslationPrintToChat(client, bBlockAmbientSound ? "Text_AmbientDisable" : "Text_AmbientEnable");
		
		// Get ambient sound file.
		decl String:sound[SOUND_MAX_PATH];
		GetConVarString(g_hCvarsList[CVAR_AMBIENTSOUNDS_FILE], sound, sizeof(sound));
		
		if(bBlockAmbientSound)
		{
			StopSound(client, SNDCHAN_STATIC, sound);
		}
		else
		{
			StopSound(client, SNDCHAN_STATIC, sound);
			EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_STATIC, _, _, zfAmbientVolume[client]);
		}
	}
}