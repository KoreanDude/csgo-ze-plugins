#if defined _SoundLib_included
    #endinput
#endif
#define _SoundLib_included

methodmap Sound < Handle
{
    /* 
     *  Open a sound file.
     *
     * @param path          The path of sound file.
     * @param valve_fs      Open file via IFileSystem. (helpful for map music)
     *
     * @return              sound hanld. if sound has been opened, but does not close, 
     *                      u will get null handle when you trying to open twice.
     * @error               if can not create dummy file. trhow an error.
    */
	public native Sound(const char[] path, bool value_file_system = false);
    
    /* 
     *  Retrieve sound length in float.
     *
     * @return              value of sound length. @(-1.0 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native float GetLength();
    
    /* 
     *  Retrieve sound length in milliseconds.
     *
     * @return              value of sound length. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
    public native int GetLengthInMilliseconds();
    
    /* 
     *  Retrieve sound bitrate.
     *
     * @return              value of sound bitrate. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native int GetBitRate();
    
    /* 
     *  Retrieve sound sampling rate.
     *
     * @return              value of sound sampling rate. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native int GetSamplingRate();
    
    /* 
     *  Retrieve sound channels.
     *
     * @return              value of sound channels. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native int GetChannels();
    
    /* 
     *  Retrieve sound tracks.
     *
     * @return              value of sound tracks. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native int GetTrack();
    
    /* 
     *  Retrieve sound tracks.
     *
     * @return              value of sound tracks. @(-1 if failure)
     * 
     * @error               if invalid sound handle given. trhow an error.
    */
	public native int GetYear();
    
    /* 
     *  Retrieve sound title.
     *
     * @param title         The buffer to store sound title.
     * @param maxLen        The buffer size.
     *
     * @error               if invalid sound handle given. trhow an error.
    */
	public native void GetTitle(char[] title, int maxLen);
    
    /* 
     *  Retrieve sound artist.
     *
     * @param artist        The buffer to store sound artist.
     * @param maxLen        The buffer size.
     *
     * @error               if invalid sound handle given. trhow an error.
    */
	public native void GetArtist(char[] artist, int maxLen);
    
    /* 
     *  Retrieve sound album.
     *
     * @param album         The buffer to store sound album.
     * @param maxLen        The buffer size.
     *
     * @error               if invalid sound handle given. trhow an error.
    */
	public native void GetAlbum(char[] album, int maxLen);
    
    /* 
     *  Retrieve sound comment.
     *
     * @param comment       The buffer to store sound comment.
     * @param maxLen        The buffer size.
     *
     * @error               if invalid sound handle given. trhow an error.
    */
	public native void GetComment(char[] comment, int maxLen);
    
    /* 
     *  Retrieve sound genre.
     *
     * @param genre         The buffer to store sound genre.
     * @param maxLen        The buffer size.
     *
     * @error               if invalid sound handle given. trhow an error.
    */
	public native void GetGenre(char[] genre, int maxLen);
};

public Extension __ext_SoundLib = 
{
	name = "soundlib",
	file = "SoundLib.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_EXTENSIONS
public void __ext_SoundLib_SetNTVOptional()
{
	MarkNativeAsOptional("Sound.Sound");
	MarkNativeAsOptional("Sound.GetLength");
	MarkNativeAsOptional("Sound.GetDuration");
	MarkNativeAsOptional("Sound.GetBitRate");
	MarkNativeAsOptional("Sound.GetSamplingRate");
	MarkNativeAsOptional("Sound.GetChannels");
	MarkNativeAsOptional("Sound.GetTrack");
	MarkNativeAsOptional("Sound.GetYear");
	MarkNativeAsOptional("Sound.IsSet");
	MarkNativeAsOptional("Sound.GetTitle");
	MarkNativeAsOptional("Sound.GetArtist");
	MarkNativeAsOptional("Sound.GetAlbum");
	MarkNativeAsOptional("Sound.GetComment");
	MarkNativeAsOptional("Sound.GetGenre");
}
#endif