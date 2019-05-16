#include <sourcemod>
#include <sdktools>

#define NORMAL_LINE_LENGTH 64
#define PLATFORM_LINE_LENGTH 256

#pragma tabsize 0

public Plugin:myinfo =
{
	name = "[ZR] Uncache Particles",
	author = "gubka, Modified by Someone",
	description = "Uncache Particles",
	version = "1.1",
	url = ""
};

/**
 * Variables to store SDK calls handlers.
 **/
Handle hSDKCallDestructorParticleDictionary;
Handle hSDKCallContainerFindTable;
Handle hSDKCallTableDeleteAllStrings;

/**
 * Variables to store virtual SDK offsets.
 **/
Address particleSystemDictionary;
Address networkStringTable;
int ParticleSystem_Count;

ArrayList Particles;

public void OnPluginStart()
{
	// Starts the preparation of an SDK call
	Handle hConf = LoadGameConfigFile("plugin.UncacheParticles");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CParticleSystemDictionary::~CParticleSystemDictionary");
	hSDKCallDestructorParticleDictionary = EndPrepSDKCall();
	
	// Validate call
	if((hSDKCallDestructorParticleDictionary = EndPrepSDKCall()) == null)
	{
		// Log failure
		//LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CParticleSystemDictionary::~CParticleSystemDictionary\". Update signature in \"%s\"", PLUGIN_CONFIG);
		SetFailState("Failed to load SDK call \"CParticleSystemDictionary::~CParticleSystemDictionary\". Please update signature.");
		return;
	}
	/*_________________________________________________________________________________________________________________________________________*/

	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CNetworkStringTableContainer::FindTable");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	//PrepSDKCall_SetReturnInfo - Crash
	//PrepSDKCall_AddParameter - Working, but it has error logs
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSDKCallContainerFindTable = EndPrepSDKCall();
	
	// Validate call
	if((hSDKCallContainerFindTable = EndPrepSDKCall()) == null)
	{
		// Log failure
		//LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTableContainer::FindTable\". Update virtual offset in \"%s\"", PLUGIN_CONFIG);
		SetFailState("Failed to load SDK call \"CNetworkStringTableContainer::FindTable\". Please update signature.");
		return;
	}
	/*_________________________________________________________________________________________________________________________________________*/
	// Starts the preparation of an SDK call
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CNetworkStringTable::DeleteAllStrings");
	hSDKCallTableDeleteAllStrings = EndPrepSDKCall();
	
	// Validate call
	if((hSDKCallTableDeleteAllStrings = EndPrepSDKCall()) == null)
	{
		// Log failure
		//LogEvent(false, LogType_Fatal, LOG_GAME_EVENTS, LogModule_Effects, "GameData Validation", "Failed to load SDK call \"CNetworkStringTable::DeleteAllStrings\". Update signature in \"%s\"", PLUGIN_CONFIG);
		SetFailState("Failed to load SDK call \"CNetworkStringTable::DeleteAllStrings\". Please update signature.");
		return;
	}
	/*_________________________________________________________________________________________________________________________________________*/

	fnInitGameConfAddress(hConf, particleSystemDictionary, "m_pParticleSystemDictionary");
	fnInitGameConfAddress(hConf, networkStringTable, "s_NetworkStringTable");
	fnInitGameConfOffset(hConf, ParticleSystem_Count, "CParticleSystemDictionary::Count");
}

public void OnMapStart()
{
	ParticlesOnCacheData();
	ParticlesOnPrecache();
}

public void OnMapEnd()
{
	ParticlesOnPurge();
}

void ParticlesOnPurge(/*void*/)
{
    /// @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.cpp#L81
    SDKCall(hSDKCallDestructorParticleDictionary, particleSystemDictionary);

    // Clear particles in the effect table
    Address pTable = ParticlesFindTable("ParticleEffectNames");
    if(pTable != Address_Null)   
    {
        ParticlesClearTable(pTable);
    }

    // Clear particles in the extra effect table
    pTable = ParticlesFindTable("ExtraParticleFilesTable");
    if(pTable != Address_Null)   
    {
        ParticlesClearTable(pTable);
    }
}

void ParticlesOnCacheData(/*void*/)
{
    // Validate that table is exist and it empty
    Address pTable = ParticlesFindTable("ParticleEffectNames");
    if(pTable != Address_Null && !ParticlesCount())
    {
        // Opens the file
        File hFile = OpenFile("particles/particles_manifest.txt", "rt", true);
        
        // If doesn't exist stop
		if(hFile == null)
		{
			//LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Effects, "Config Validation", "Error opening file: \"particles/particles_manifest.txt\"");
			SetFailState("Error opening file: \"particles/particles_manifest.txt\"");
			return;
		}

		// Read lines in the file
        static char sPath[PLATFORM_LINE_LENGTH];
        while(hFile.ReadLine(sPath, sizeof(sPath)))
        {
            // Checks if string has correct quotes
            int iQuotes = CountCharInString(sPath, '"');
            if(iQuotes == 4)
            {
                // Trim string
                TrimString(sPath);

                // Copy value string
                strcopy(sPath, sizeof(sPath), sPath[strlen("\"file\"")]);
                
                // Trim string
                TrimString(sPath);
                
                // Strips a quote pair off a string 
                StripQuotes(sPath);

                // Precache model
                int i; if(sPath[i] == '!') i++;
                PrecacheGeneric(sPath[i], true);
                ParticlesClearTable(pTable); /// HACK~HACK
                /// Clear tables after each file because some of them contains
                /// huge amount of particles and we work around the limit
            }
        }
    }
}
/**
 * @brief Find the table pointer by a name.
 *
 * @return                  The address of the table.                
 **/
Address ParticlesFindTable(char[] sTable)
{
    return SDKCall(hSDKCallContainerFindTable, networkStringTable, sTable);
}    
/**
 * @brief Clear the table by a pointer.  
 * 
 * @param pTable            The table address.
 **/
void ParticlesClearTable(Address pTable) 
{
    SDKCall(hSDKCallTableDeleteAllStrings, pTable);
}
/**
 * @brief Gets the amount of precached particles in the dictionary.
 *
 * @return                  The amount of particles.
 *
 * @link https://github.com/VSES/SourceEngine2007/blob/43a5c90a5ada1e69ca044595383be67f40b33c61/src_main/particles/particles.cpp#L54                  
 **/
int ParticlesCount(/*void*/)
{
    return LoadFromAddress(particleSystemDictionary + view_as<Address>(ParticleSystem_Count), NumberType_Int16);
}
/**
 * @brief Caches particles data from the manifest file.
 **/
void ParticlesOnPrecache(/*void*/)
{
    // Initialize buffer char
    static char sBuffer[PLATFORM_LINE_LENGTH];

    // If array hasn't been created, then create
    if(Particles == null)
    {
        // Initialize a particle list array
        Particles = CreateArray(NORMAL_LINE_LENGTH); 

        // i = string index
        int iCount = GetParticleEffectCount();
        for(int i = 0; i < iCount; i++)
        {
            // Gets the string at a given index
            GetParticleEffectName(i, sBuffer, sizeof(sBuffer));
            
            // Push data into array 
            Particles.PushString(sBuffer);
        }
    }
    else
    {
        // i = string index
        int iCount = Particles.Length;
        for(int i = 0; i < iCount; i++)
        {
            // Gets the string at a given index
            Particles.GetString(i, sBuffer, sizeof(sBuffer));
            
            // Push data into table 
            PrecacheParticleEffect(sBuffer);
        }
    }
}
stock int GetParticleEffectCount(/*void*/)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;
    
    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }
    
    // Returns the count of strings that exist in a given table
    return GetStringTableNumStrings(tableIndex);
}
stock void GetParticleEffectName(int iIndex, char[] sEffect, int iMaxLen)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;
    
    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }
    
    // Gets the string at a given index
    ReadStringTable(tableIndex, iIndex, sEffect, iMaxLen);
}
stock void PrecacheParticleEffect(char[] sEffect)
{
    // Initialize the table index
    static int tableIndex = INVALID_STRING_TABLE;
    
    // Validate table
    if(tableIndex == INVALID_STRING_TABLE)
    {
        // Searches for a string table
        tableIndex = FindStringTable("ParticleEffectNames");
    }
    
    // Precache particle
    bool bSave = LockStringTables(false);
    AddToStringTable(tableIndex, sEffect);
    LockStringTables(bSave);
}
stock void fnInitGameConfAddress(Handle gameConf, Address &xAddress, char[] sKey)
{
	// Validate address
	if((xAddress = GameConfGetAddress(gameConf, sKey)) == Address_Null)
	{
		//LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get address: \"%s\"", sKey);
		SetFailState("Failed to get address: \"%s\"", sKey);
	}
}
stock void fnInitGameConfOffset(Handle gameConf, int &iOffset, char[] sKey)
{
	// Validate offset
	if((iOffset = GameConfGetOffset(gameConf, sKey)) == -1)
	{
		//LogEvent(false, LogType_Fatal, LOG_CORE_EVENTS, LogModule_Engine, "GameData Validation", "Failed to get offset: \"%s\"", sKey);
		SetFailState("Failed to get offset: \"%s\"", sKey);
	}
}
/**
 * @brief Particles module load function.
 **/
int CountCharInString(char[] sBuffer, char cSymbol)
{
    // Initialize index
    int iAmount;
    
    // i = char index
    int iLen = strlen(sBuffer);
    for(int i = 0; i < iLen; i++) 
    {
        // Validate char
        if (sBuffer[i] == cSymbol)
        {
            // Increment amount
            iAmount++;
        }
    }

    // Return amount
    return iAmount ? iAmount : -1;
}