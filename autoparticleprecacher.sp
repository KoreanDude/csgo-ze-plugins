#pragma newdecls required
#pragma semicolon 1 

#define MANIFEST_FOLDER         "maps/" 
#define MANIFEST_EXTENSION      "_particles.txt" 
  
public Plugin myinfo = 
{ 
    name = "CS:GO particle auto-precacher", 
    author = "Copypaste Slim", 
    description = "Precaches particle systems in the same manner as the per-map manifest system in older Source titles.", 
    version = "1.2.4", 
    url = "http://a.b.c.d.e.f.g.h.is.a.valid.url.com/" 
}; 

public void OnPluginStart()
{  
    RegAdminCmd("sm_precache_particles", Command_PrecacheParticles, ADMFLAG_ROOT, "Precaches a particle system."); 
} 

public void OnMapStart() 
{ 
    char sMap[PLATFORM_MAX_PATH]; 
    GetCurrentMap(sMap, sizeof(sMap)); 
     
    char sManifestFullPath[PLATFORM_MAX_PATH]; 
    FormatEx(sManifestFullPath, sizeof(sManifestFullPath), "%s%s%s", MANIFEST_FOLDER, sMap, MANIFEST_EXTENSION); 

    // If the file exists then we jump into the depths of it and precache stuff 
    if (!FileExists(sManifestFullPath, true, NULL_STRING)) 
    { 
        //PrintToServer("\n\nManifest file \'%s\' not found.", sManifestFullPath); 
        return; 
    } 
     
    ProcessParticleManifest(sManifestFullPath); 
} 

public Action Command_PrecacheParticles(int client, int args)
{ 
    if (args < 1){ 
        return Plugin_Handled; 
    } 
    char path[256]; 
    GetCmdArg(1, path, 256); 
    PrintToConsole(client, "Particle precacher called for: %s", path); 
    PrecacheParticle(path); 
    return Plugin_Handled; 
} 

void ProcessParticleManifest(const char[] path) 
{ 
    File hFile = OpenFile(path, "r", true, NULL_STRING); 

    KeyValues hKeyValue = CreateKeyValues("particles_manifest"); 
    FileToKeyValues(hKeyValue, path); 

    if (!KvJumpToKey(hKeyValue, "file", false)) 
    { 
        //PrintToServer("\n\nFailed going to first key"); 
        delete hKeyValue; 
        hFile.Close(); 
        return; 
    } 
     
    char buffer[256]; 
    do 
    { 
        KvGetString(hKeyValue, NULL_STRING, buffer, 256, NULL_STRING); 
        PrecacheParticle(buffer); 
    } while (KvGotoNextKey(hKeyValue, false)); 
  
    delete hKeyValue; 
    hFile.Close(); 
} 

public void PrecacheParticle(const char[] path) 
{ 
    if(!FileExists(path, true, NULL_STRING)) 
    { 
        //PrintToServer("\nParticle file \'%s\' not found.", path); 
        //return; 
    } 
     
    PrecacheGeneric(path, true); 
}