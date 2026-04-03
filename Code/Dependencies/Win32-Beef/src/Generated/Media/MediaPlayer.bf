using Win32.System.Com;
using Win32.Foundation;
using Win32.Media.MediaFoundation;
using Win32.System.Ole;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Media.MediaPlayer;

#region Constants
public static
{
	public const Guid CLSID_XFeedsManager = .(0xfe6b11c3, 0xc72e, 0x4061, 0x86, 0xc6, 0x9d, 0x16, 0x31, 0x21, 0xf2, 0x29);
	public const uint32 WMPGC_FLAGS_ALLOW_PREROLL = 1;
	public const uint32 WMPGC_FLAGS_SUPPRESS_DIALOGS = 2;
	public const uint32 WMPGC_FLAGS_IGNORE_AV_SYNC = 4;
	public const uint32 WMPGC_FLAGS_DISABLE_PLUGINS = 8;
	public const uint32 WMPGC_FLAGS_USE_CUSTOM_GRAPH = 16;
	public const uint32 WMPUE_EC_USER = 33024;
	public const uint32 WMP_MDRT_FLAGS_UNREPORTED_DELETED_ITEMS = 1;
	public const uint32 WMP_MDRT_FLAGS_UNREPORTED_ADDED_ITEMS = 2;
	public const uint32 IOCTL_WMP_METADATA_ROUND_TRIP = 827346263;
	public const uint32 IOCTL_WMP_DEVICE_CAN_SYNC = 844123479;
	public const uint32 EFFECT_CANGOFULLSCREEN = 1;
	public const uint32 EFFECT_HASPROPERTYPAGE = 2;
	public const uint32 EFFECT_VARIABLEFREQSTEP = 4;
	public const uint32 EFFECT_WINDOWEDONLY = 8;
	public const uint32 EFFECT2_FULLSCREENEXCLUSIVE = 16;
	public const uint32 SA_BUFFER_SIZE = 1024;
	public const String PLUGIN_INSTALLREGKEY = "Software\\Microsoft\\MediaPlayer\\UIPlugins";
	public const String PLUGIN_INSTALLREGKEY_FRIENDLYNAME = "FriendlyName";
	public const String PLUGIN_INSTALLREGKEY_DESCRIPTION = "Description";
	public const String PLUGIN_INSTALLREGKEY_CAPABILITIES = "Capabilities";
	public const String PLUGIN_INSTALLREGKEY_UNINSTALL = "UninstallPath";
	public const uint32 PLUGIN_TYPE_BACKGROUND = 1;
	public const uint32 PLUGIN_TYPE_SEPARATEWINDOW = 2;
	public const uint32 PLUGIN_TYPE_DISPLAYAREA = 3;
	public const uint32 PLUGIN_TYPE_SETTINGSAREA = 4;
	public const uint32 PLUGIN_TYPE_METADATAAREA = 5;
	public const uint32 PLUGIN_FLAGS_HASPROPERTYPAGE = 2147483648;
	public const uint32 PLUGIN_FLAGS_INSTALLAUTORUN = 1073741824;
	public const uint32 PLUGIN_FLAGS_LAUNCHPROPERTYPAGE = 536870912;
	public const uint32 PLUGIN_FLAGS_ACCEPTSMEDIA = 268435456;
	public const uint32 PLUGIN_FLAGS_ACCEPTSPLAYLISTS = 134217728;
	public const uint32 PLUGIN_FLAGS_HASPRESETS = 67108864;
	public const uint32 PLUGIN_FLAGS_HIDDEN = 33554432;
	public const String PLUGIN_MISC_PRESETCOUNT = "PresetCount";
	public const String PLUGIN_MISC_PRESETNAMES = "PresetNames";
	public const String PLUGIN_MISC_CURRENTPRESET = "CurrentPreset";
	public const String PLUGIN_SEPARATEWINDOW_RESIZABLE = "Resizable";
	public const String PLUGIN_SEPARATEWINDOW_DEFAULTWIDTH = "DefaultWidth";
	public const String PLUGIN_SEPARATEWINDOW_DEFAULTHEIGHT = "DefaultHeight";
	public const String PLUGIN_SEPARATEWINDOW_MINWIDTH = "MinWidth";
	public const String PLUGIN_SEPARATEWINDOW_MINHEIGHT = "MinHeight";
	public const String PLUGIN_SEPARATEWINDOW_MAXWIDTH = "MaxWidth";
	public const String PLUGIN_SEPARATEWINDOW_MAXHEIGHT = "MaxHeight";
	public const String PLUGIN_MISC_QUERYDESTROY = "QueryDestroy";
	public const String PLUGIN_ALL_MEDIASENDTO = "MediaSendTo";
	public const String PLUGIN_ALL_PLAYLISTSENDTO = "PlaylistSendTo";
	public const uint32 SUBSCRIPTION_CAP_DEVICEAVAILABLE = 16;
	public const uint32 SUBSCRIPTION_CAP_BACKGROUNDPROCESSING = 8;
	public const uint32 SUBSCRIPTION_CAP_IS_CONTENTPARTNER = 64;
	public const uint32 SUBSCRIPTION_CAP_ALTLOGIN = 128;
	public const uint32 SUBSCRIPTION_CAP_ALLOWPLAY = 1;
	public const uint32 SUBSCRIPTION_CAP_ALLOWCDBURN = 2;
	public const uint32 SUBSCRIPTION_CAP_ALLOWPDATRANSFER = 4;
	public const uint32 SUBSCRIPTION_CAP_PREPAREFORSYNC = 32;
	public const uint32 SUBSCRIPTION_V1_CAPS = 15;
	public const uint32 SUBSCRIPTION_CAP_UILESSMODE_ALLOWPLAY = 256;
	public const String WMP_SUBSCR_DL_TYPE_BACKGROUND = "background";
	public const String WMP_SUBSCR_DL_TYPE_REALTIME = "real time";
	public const uint32 DISPID_FEEDS_RootFolder = 4096;
	public const uint32 DISPID_FEEDS_IsSubscribed = 4097;
	public const uint32 DISPID_FEEDS_ExistsFeed = 4098;
	public const uint32 DISPID_FEEDS_GetFeed = 4099;
	public const uint32 DISPID_FEEDS_ExistsFolder = 4100;
	public const uint32 DISPID_FEEDS_GetFolder = 4101;
	public const uint32 DISPID_FEEDS_DeleteFeed = 4102;
	public const uint32 DISPID_FEEDS_DeleteFolder = 4103;
	public const uint32 DISPID_FEEDS_GetFeedByUrl = 4104;
	public const uint32 DISPID_FEEDS_BackgroundSync = 4105;
	public const uint32 DISPID_FEEDS_BackgroundSyncStatus = 4106;
	public const uint32 DISPID_FEEDS_DefaultInterval = 4107;
	public const uint32 DISPID_FEEDS_AsyncSyncAll = 4108;
	public const uint32 DISPID_FEEDS_Normalize = 4109;
	public const uint32 DISPID_FEEDS_ItemCountLimit = 4110;
	public const uint32 DISPID_FEEDSENUM_Count = 8192;
	public const uint32 DISPID_FEEDSENUM_Item = 8193;
	public const uint32 DISPID_FEEDFOLDER_Feeds = 12288;
	public const uint32 DISPID_FEEDFOLDER_Subfolders = 12289;
	public const uint32 DISPID_FEEDFOLDER_CreateFeed = 12290;
	public const uint32 DISPID_FEEDFOLDER_CreateSubfolder = 12291;
	public const uint32 DISPID_FEEDFOLDER_ExistsFeed = 12292;
	public const uint32 DISPID_FEEDFOLDER_GetFeed = 12293;
	public const uint32 DISPID_FEEDFOLDER_ExistsSubfolder = 12294;
	public const uint32 DISPID_FEEDFOLDER_GetSubfolder = 12295;
	public const uint32 DISPID_FEEDFOLDER_Delete = 12296;
	public const uint32 DISPID_FEEDFOLDER_Name = 12297;
	public const uint32 DISPID_FEEDFOLDER_Rename = 12298;
	public const uint32 DISPID_FEEDFOLDER_Path = 12299;
	public const uint32 DISPID_FEEDFOLDER_Move = 12300;
	public const uint32 DISPID_FEEDFOLDER_Parent = 12301;
	public const uint32 DISPID_FEEDFOLDER_IsRoot = 12302;
	public const uint32 DISPID_FEEDFOLDER_TotalUnreadItemCount = 12303;
	public const uint32 DISPID_FEEDFOLDER_TotalItemCount = 12304;
	public const uint32 DISPID_FEEDFOLDER_GetWatcher = 12305;
	public const uint32 DISPID_FEED_Xml = 16384;
	public const uint32 DISPID_FEED_Name = 16385;
	public const uint32 DISPID_FEED_Rename = 16386;
	public const uint32 DISPID_FEED_Url = 16387;
	public const uint32 DISPID_FEED_LocalId = 16388;
	public const uint32 DISPID_FEED_Path = 16389;
	public const uint32 DISPID_FEED_Move = 16390;
	public const uint32 DISPID_FEED_Parent = 16391;
	public const uint32 DISPID_FEED_LastWriteTime = 16392;
	public const uint32 DISPID_FEED_Delete = 16393;
	public const uint32 DISPID_FEED_Download = 16394;
	public const uint32 DISPID_FEED_AsyncDownload = 16395;
	public const uint32 DISPID_FEED_CancelAsyncDownload = 16396;
	public const uint32 DISPID_FEED_Interval = 16397;
	public const uint32 DISPID_FEED_SyncSetting = 16398;
	public const uint32 DISPID_FEED_LastDownloadTime = 16399;
	public const uint32 DISPID_FEED_LocalEnclosurePath = 16400;
	public const uint32 DISPID_FEED_Items = 16401;
	public const uint32 DISPID_FEED_GetItem = 16402;
	public const uint32 DISPID_FEED_Title = 16403;
	public const uint32 DISPID_FEED_Description = 16404;
	public const uint32 DISPID_FEED_Link = 16405;
	public const uint32 DISPID_FEED_Image = 16406;
	public const uint32 DISPID_FEED_LastBuildDate = 16407;
	public const uint32 DISPID_FEED_PubDate = 16408;
	public const uint32 DISPID_FEED_Ttl = 16409;
	public const uint32 DISPID_FEED_Language = 16410;
	public const uint32 DISPID_FEED_Copyright = 16411;
	public const uint32 DISPID_FEED_DownloadEnclosuresAutomatically = 16412;
	public const uint32 DISPID_FEED_DownloadStatus = 16413;
	public const uint32 DISPID_FEED_LastDownloadError = 16414;
	public const uint32 DISPID_FEED_Merge = 16415;
	public const uint32 DISPID_FEED_DownloadUrl = 16416;
	public const uint32 DISPID_FEED_IsList = 16417;
	public const uint32 DISPID_FEED_MarkAllItemsRead = 16418;
	public const uint32 DISPID_FEED_GetWatcher = 16419;
	public const uint32 DISPID_FEED_UnreadItemCount = 16420;
	public const uint32 DISPID_FEED_ItemCount = 16421;
	public const uint32 DISPID_FEED_MaxItemCount = 16422;
	public const uint32 DISPID_FEED_GetItemByEffectiveId = 16423;
	public const uint32 DISPID_FEED_LastItemDownloadTime = 16424;
	public const uint32 DISPID_FEED_Username = 16425;
	public const uint32 DISPID_FEED_Password = 16426;
	public const uint32 DISPID_FEED_SetCredentials = 16427;
	public const uint32 DISPID_FEED_ClearCredentials = 16428;
	public const uint32 DISPID_FEEDITEM_Xml = 20480;
	public const uint32 DISPID_FEEDITEM_Title = 20481;
	public const uint32 DISPID_FEEDITEM_Link = 20482;
	public const uint32 DISPID_FEEDITEM_Guid = 20483;
	public const uint32 DISPID_FEEDITEM_Description = 20484;
	public const uint32 DISPID_FEEDITEM_PubDate = 20485;
	public const uint32 DISPID_FEEDITEM_Comments = 20486;
	public const uint32 DISPID_FEEDITEM_Author = 20487;
	public const uint32 DISPID_FEEDITEM_Enclosure = 20488;
	public const uint32 DISPID_FEEDITEM_IsRead = 20489;
	public const uint32 DISPID_FEEDITEM_LocalId = 20490;
	public const uint32 DISPID_FEEDITEM_Parent = 20491;
	public const uint32 DISPID_FEEDITEM_Delete = 20492;
	public const uint32 DISPID_FEEDITEM_DownloadUrl = 20493;
	public const uint32 DISPID_FEEDITEM_LastDownloadTime = 20494;
	public const uint32 DISPID_FEEDITEM_Modified = 20495;
	public const uint32 DISPID_FEEDITEM_EffectiveId = 20496;
	public const uint32 DISPID_FEEDENCLOSURE_Url = 24576;
	public const uint32 DISPID_FEEDENCLOSURE_Type = 24577;
	public const uint32 DISPID_FEEDENCLOSURE_Length = 24578;
	public const uint32 DISPID_FEEDENCLOSURE_AsyncDownload = 24579;
	public const uint32 DISPID_FEEDENCLOSURE_CancelAsyncDownload = 24580;
	public const uint32 DISPID_FEEDENCLOSURE_DownloadStatus = 24581;
	public const uint32 DISPID_FEEDENCLOSURE_LastDownloadError = 24582;
	public const uint32 DISPID_FEEDENCLOSURE_LocalPath = 24583;
	public const uint32 DISPID_FEEDENCLOSURE_Parent = 24584;
	public const uint32 DISPID_FEEDENCLOSURE_DownloadUrl = 24585;
	public const uint32 DISPID_FEEDENCLOSURE_DownloadMimeType = 24586;
	public const uint32 DISPID_FEEDENCLOSURE_RemoveFile = 24587;
	public const uint32 DISPID_FEEDENCLOSURE_SetFile = 24588;
	public const uint32 DISPID_FEEDFOLDEREVENTS_Error = 28672;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderAdded = 28673;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderDeleted = 28674;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderRenamed = 28675;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderMovedFrom = 28676;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderMovedTo = 28677;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FolderItemCountChanged = 28678;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedAdded = 28679;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedDeleted = 28680;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedRenamed = 28681;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedUrlChanged = 28682;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedMovedFrom = 28683;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedMovedTo = 28684;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedDownloading = 28685;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedDownloadCompleted = 28686;
	public const uint32 DISPID_FEEDFOLDEREVENTS_FeedItemCountChanged = 28687;
	public const uint32 DISPID_FEEDEVENTS_Error = 32768;
	public const uint32 DISPID_FEEDEVENTS_FeedDeleted = 32769;
	public const uint32 DISPID_FEEDEVENTS_FeedRenamed = 32770;
	public const uint32 DISPID_FEEDEVENTS_FeedUrlChanged = 32771;
	public const uint32 DISPID_FEEDEVENTS_FeedMoved = 32772;
	public const uint32 DISPID_FEEDEVENTS_FeedDownloading = 32773;
	public const uint32 DISPID_FEEDEVENTS_FeedDownloadCompleted = 32774;
	public const uint32 DISPID_FEEDEVENTS_FeedItemCountChanged = 32775;
	public const uint32 DISPID_DELTA = 50;
	public const uint32 DISPID_WMPCORE_BASE = 0;
	public const uint32 DISPID_WMPCORE_URL = 1;
	public const uint32 DISPID_WMPCORE_OPENSTATE = 2;
	public const uint32 DISPID_WMPCORE_CLOSE = 3;
	public const uint32 DISPID_WMPCORE_CONTROLS = 4;
	public const uint32 DISPID_WMPCORE_SETTINGS = 5;
	public const uint32 DISPID_WMPCORE_CURRENTMEDIA = 6;
	public const uint32 DISPID_WMPCORE_NETWORK = 7;
	public const uint32 DISPID_WMPCORE_MEDIACOLLECTION = 8;
	public const uint32 DISPID_WMPCORE_PLAYLISTCOLLECTION = 9;
	public const uint32 DISPID_WMPCORE_PLAYSTATE = 10;
	public const uint32 DISPID_WMPCORE_VERSIONINFO = 11;
	public const uint32 DISPID_WMPCORE_LAUNCHURL = 12;
	public const uint32 DISPID_WMPCORE_CURRENTPLAYLIST = 13;
	public const uint32 DISPID_WMPCORE_CDROMCOLLECTION = 14;
	public const uint32 DISPID_WMPCORE_CLOSEDCAPTION = 15;
	public const uint32 DISPID_WMPCORE_ISONLINE = 16;
	public const uint32 DISPID_WMPCORE_ERROR = 17;
	public const uint32 DISPID_WMPCORE_STATUS = 18;
	public const uint32 DISPID_WMPCORE_LAST = 18;
	public const uint32 DISPID_WMPOCX_BASE = 18;
	public const uint32 DISPID_WMPOCX_ENABLED = 19;
	public const uint32 DISPID_WMPOCX_TRANSPARENTATSTART = 20;
	public const uint32 DISPID_WMPOCX_FULLSCREEN = 21;
	public const uint32 DISPID_WMPOCX_ENABLECONTEXTMENU = 22;
	public const uint32 DISPID_WMPOCX_UIMODE = 23;
	public const uint32 DISPID_WMPOCX_LAST = 23;
	public const uint32 DISPID_WMPOCX2_BASE = 23;
	public const uint32 DISPID_WMPOCX2_STRETCHTOFIT = 24;
	public const uint32 DISPID_WMPOCX2_WINDOWLESSVIDEO = 25;
	public const uint32 DISPID_WMPOCX4_ISREMOTE = 26;
	public const uint32 DISPID_WMPOCX4_PLAYERAPPLICATION = 27;
	public const uint32 DISPID_WMPOCX4_OPENPLAYER = 28;
	public const uint32 DISPID_WMPCORE2_BASE = 39;
	public const uint32 DISPID_WMPCORE2_DVD = 40;
	public const uint32 DISPID_WMPCORE3_NEWPLAYLIST = 41;
	public const uint32 DISPID_WMPCORE3_NEWMEDIA = 42;
	public const uint32 DISPID_WMPCONTROLS_PLAY = 51;
	public const uint32 DISPID_WMPCONTROLS_STOP = 52;
	public const uint32 DISPID_WMPCONTROLS_PAUSE = 53;
	public const uint32 DISPID_WMPCONTROLS_FASTFORWARD = 54;
	public const uint32 DISPID_WMPCONTROLS_FASTREVERSE = 55;
	public const uint32 DISPID_WMPCONTROLS_CURRENTPOSITION = 56;
	public const uint32 DISPID_WMPCONTROLS_CURRENTPOSITIONSTRING = 57;
	public const uint32 DISPID_WMPCONTROLS_NEXT = 58;
	public const uint32 DISPID_WMPCONTROLS_PREVIOUS = 59;
	public const uint32 DISPID_WMPCONTROLS_CURRENTITEM = 60;
	public const uint32 DISPID_WMPCONTROLS_CURRENTMARKER = 61;
	public const uint32 DISPID_WMPCONTROLS_ISAVAILABLE = 62;
	public const uint32 DISPID_WMPCONTROLS_PLAYITEM = 63;
	public const uint32 DISPID_WMPCONTROLS2_STEP = 64;
	public const uint32 DISPID_WMPCONTROLS3_AUDIOLANGUAGECOUNT = 65;
	public const uint32 DISPID_WMPCONTROLS3_GETAUDIOLANGUAGEID = 66;
	public const uint32 DISPID_WMPCONTROLS3_GETAUDIOLANGUAGEDESC = 67;
	public const uint32 DISPID_WMPCONTROLS3_CURRENTAUDIOLANGUAGE = 68;
	public const uint32 DISPID_WMPCONTROLS3_CURRENTAUDIOLANGUAGEINDEX = 69;
	public const uint32 DISPID_WMPCONTROLS3_GETLANGUAGENAME = 70;
	public const uint32 DISPID_WMPCONTROLS3_CURRENTPOSITIONTIMECODE = 71;
	public const uint32 DISPID_WMPCONTROLSFAKE_TIMECOMPRESSION = 72;
	public const uint32 DISPID_WMPSETTINGS_AUTOSTART = 101;
	public const uint32 DISPID_WMPSETTINGS_BALANCE = 102;
	public const uint32 DISPID_WMPSETTINGS_INVOKEURLS = 103;
	public const uint32 DISPID_WMPSETTINGS_MUTE = 104;
	public const uint32 DISPID_WMPSETTINGS_PLAYCOUNT = 105;
	public const uint32 DISPID_WMPSETTINGS_RATE = 106;
	public const uint32 DISPID_WMPSETTINGS_VOLUME = 107;
	public const uint32 DISPID_WMPSETTINGS_BASEURL = 108;
	public const uint32 DISPID_WMPSETTINGS_DEFAULTFRAME = 109;
	public const uint32 DISPID_WMPSETTINGS_GETMODE = 110;
	public const uint32 DISPID_WMPSETTINGS_SETMODE = 111;
	public const uint32 DISPID_WMPSETTINGS_ENABLEERRORDIALOGS = 112;
	public const uint32 DISPID_WMPSETTINGS_ISAVAILABLE = 113;
	public const uint32 DISPID_WMPSETTINGS2_DEFAULTAUDIOLANGUAGE = 114;
	public const uint32 DISPID_WMPSETTINGS2_LIBRARYACCESSRIGHTS = 115;
	public const uint32 DISPID_WMPSETTINGS2_REQUESTLIBRARYACCESSRIGHTS = 116;
	public const uint32 DISPID_WMPPLAYLIST_COUNT = 201;
	public const uint32 DISPID_WMPPLAYLIST_NAME = 202;
	public const uint32 DISPID_WMPPLAYLIST_GETITEMINFO = 203;
	public const uint32 DISPID_WMPPLAYLIST_SETITEMINFO = 204;
	public const uint32 DISPID_WMPPLAYLIST_CLEAR = 205;
	public const uint32 DISPID_WMPPLAYLIST_INSERTITEM = 206;
	public const uint32 DISPID_WMPPLAYLIST_APPENDITEM = 207;
	public const uint32 DISPID_WMPPLAYLIST_REMOVEITEM = 208;
	public const uint32 DISPID_WMPPLAYLIST_MOVEITEM = 209;
	public const uint32 DISPID_WMPPLAYLIST_ATTRIBUTECOUNT = 210;
	public const uint32 DISPID_WMPPLAYLIST_ATTRIBUTENAME = 211;
	public const uint32 DISPID_WMPPLAYLIST_ITEM = 212;
	public const uint32 DISPID_WMPPLAYLIST_ISIDENTICAL = 213;
	public const uint32 DISPID_WMPCDROM_DRIVESPECIFIER = 251;
	public const uint32 DISPID_WMPCDROM_PLAYLIST = 252;
	public const uint32 DISPID_WMPCDROM_EJECT = 253;
	public const uint32 DISPID_WMPCDROMCOLLECTION_COUNT = 301;
	public const uint32 DISPID_WMPCDROMCOLLECTION_ITEM = 302;
	public const uint32 DISPID_WMPCDROMCOLLECTION_GETBYDRIVESPECIFIER = 303;
	public const uint32 DISPID_WMPCDROMCOLLECTION_STARTMONITORINGCDROMS = 304;
	public const uint32 DISPID_WMPCDROMCOLLECTION_STOPMONITORINGCDROMS = 305;
	public const uint32 DISPID_WMPSTRINGCOLLECTION_COUNT = 401;
	public const uint32 DISPID_WMPSTRINGCOLLECTION_ITEM = 402;
	public const uint32 DISPID_WMPMEDIACOLLECTION_ADD = 452;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETALL = 453;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYNAME = 454;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYGENRE = 455;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYAUTHOR = 456;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYALBUM = 457;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYATTRIBUTE = 458;
	public const uint32 DISPID_WMPMEDIACOLLECTION_REMOVE = 459;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETATTRIBUTESTRINGCOLLECTION = 461;
	public const uint32 DISPID_WMPMEDIACOLLECTION_NEWQUERY = 462;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STARTMONITORING = 463;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STOPMONITORING = 464;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STARTCONTENTSCAN = 465;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STOPCONTENTSCAN = 466;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STARTSEARCH = 467;
	public const uint32 DISPID_WMPMEDIACOLLECTION_STOPSEARCH = 468;
	public const uint32 DISPID_WMPMEDIACOLLECTION_UPDATEMETADATA = 469;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETMEDIAATOM = 470;
	public const uint32 DISPID_WMPMEDIACOLLECTION_SETDELETED = 471;
	public const uint32 DISPID_WMPMEDIACOLLECTION_ISDELETED = 472;
	public const uint32 DISPID_WMPMEDIACOLLECTION_GETBYQUERYDESCRIPTION = 473;
	public const uint32 DISPID_WMPMEDIACOLLECTION_FREEZECOLLECTIONCHANGE = 474;
	public const uint32 DISPID_WMPMEDIACOLLECTION_UNFREEZECOLLECTIONCHANGE = 475;
	public const uint32 DISPID_WMPMEDIACOLLECTION_POSTCOLLECTIONCHANGE = 476;
	public const uint32 DISPID_WMPPLAYLISTARRAY_COUNT = 501;
	public const uint32 DISPID_WMPPLAYLISTARRAY_ITEM = 502;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_NEWPLAYLIST = 552;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_GETALL = 553;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_GETBYNAME = 554;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_GETBYQUERYDESCRIPTION = 555;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_REMOVE = 556;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_NEWQUERY = 557;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_STARTMONITORING = 558;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_STOPMONITORING = 559;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_SETDELETED = 560;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_ISDELETED = 561;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_IMPORTPLAYLIST = 562;
	public const uint32 DISPID_WMPMEDIA_SOURCEURL = 751;
	public const uint32 DISPID_WMPMEDIA_IMAGESOURCEWIDTH = 752;
	public const uint32 DISPID_WMPMEDIA_IMAGESOURCEHEIGHT = 753;
	public const uint32 DISPID_WMPMEDIA_MARKERCOUNT = 754;
	public const uint32 DISPID_WMPMEDIA_GETMARKERTIME = 755;
	public const uint32 DISPID_WMPMEDIA_GETMARKERNAME = 756;
	public const uint32 DISPID_WMPMEDIA_DURATION = 757;
	public const uint32 DISPID_WMPMEDIA_DURATIONSTRING = 758;
	public const uint32 DISPID_WMPMEDIA_ATTRIBUTECOUNT = 759;
	public const uint32 DISPID_WMPMEDIA_GETATTRIBUTENAME = 760;
	public const uint32 DISPID_WMPMEDIA_GETITEMINFO = 761;
	public const uint32 DISPID_WMPMEDIA_SETITEMINFO = 762;
	public const uint32 DISPID_WMPMEDIA_ISIDENTICAL = 763;
	public const uint32 DISPID_WMPMEDIA_NAME = 764;
	public const uint32 DISPID_WMPMEDIA_GETITEMINFOBYATOM = 765;
	public const uint32 DISPID_WMPMEDIA_ISMEMBEROF = 766;
	public const uint32 DISPID_WMPMEDIA_ISREADONLYITEM = 767;
	public const uint32 DISPID_WMPMEDIA2_ERROR = 768;
	public const uint32 DISPID_WMPMEDIA3_GETATTRIBUTECOUNTBYTYPE = 769;
	public const uint32 DISPID_WMPMEDIA3_GETITEMINFOBYTYPE = 770;
	public const uint32 DISPID_WMPNETWORK_BANDWIDTH = 801;
	public const uint32 DISPID_WMPNETWORK_RECOVEREDPACKETS = 802;
	public const uint32 DISPID_WMPNETWORK_SOURCEPROTOCOL = 803;
	public const uint32 DISPID_WMPNETWORK_RECEIVEDPACKETS = 804;
	public const uint32 DISPID_WMPNETWORK_LOSTPACKETS = 805;
	public const uint32 DISPID_WMPNETWORK_RECEPTIONQUALITY = 806;
	public const uint32 DISPID_WMPNETWORK_BUFFERINGCOUNT = 807;
	public const uint32 DISPID_WMPNETWORK_BUFFERINGPROGRESS = 808;
	public const uint32 DISPID_WMPNETWORK_BUFFERINGTIME = 809;
	public const uint32 DISPID_WMPNETWORK_FRAMERATE = 810;
	public const uint32 DISPID_WMPNETWORK_MAXBITRATE = 811;
	public const uint32 DISPID_WMPNETWORK_BITRATE = 812;
	public const uint32 DISPID_WMPNETWORK_GETPROXYSETTINGS = 813;
	public const uint32 DISPID_WMPNETWORK_SETPROXYSETTINGS = 814;
	public const uint32 DISPID_WMPNETWORK_GETPROXYNAME = 815;
	public const uint32 DISPID_WMPNETWORK_SETPROXYNAME = 816;
	public const uint32 DISPID_WMPNETWORK_GETPROXYPORT = 817;
	public const uint32 DISPID_WMPNETWORK_SETPROXYPORT = 818;
	public const uint32 DISPID_WMPNETWORK_GETPROXYEXCEPTIONLIST = 819;
	public const uint32 DISPID_WMPNETWORK_SETPROXYEXCEPTIONLIST = 820;
	public const uint32 DISPID_WMPNETWORK_GETPROXYBYPASSFORLOCAL = 821;
	public const uint32 DISPID_WMPNETWORK_SETPROXYBYPASSFORLOCAL = 822;
	public const uint32 DISPID_WMPNETWORK_MAXBANDWIDTH = 823;
	public const uint32 DISPID_WMPNETWORK_DOWNLOADPROGRESS = 824;
	public const uint32 DISPID_WMPNETWORK_ENCODEDFRAMERATE = 825;
	public const uint32 DISPID_WMPNETWORK_FRAMESSKIPPED = 826;
	public const uint32 DISPID_WMPERROR_CLEARERRORQUEUE = 851;
	public const uint32 DISPID_WMPERROR_ERRORCOUNT = 852;
	public const uint32 DISPID_WMPERROR_ITEM = 853;
	public const uint32 DISPID_WMPERROR_WEBHELP = 854;
	public const uint32 DISPID_WMPERRORITEM_ERRORCODE = 901;
	public const uint32 DISPID_WMPERRORITEM_ERRORDESCRIPTION = 902;
	public const uint32 DISPID_WMPERRORITEM_ERRORCONTEXT = 903;
	public const uint32 DISPID_WMPERRORITEM_REMEDY = 904;
	public const uint32 DISPID_WMPERRORITEM_CUSTOMURL = 905;
	public const uint32 DISPID_WMPERRORITEM2_CONDITION = 906;
	public const uint32 DISPID_WMPCLOSEDCAPTION_SAMISTYLE = 951;
	public const uint32 DISPID_WMPCLOSEDCAPTION_SAMILANG = 952;
	public const uint32 DISPID_WMPCLOSEDCAPTION_SAMIFILENAME = 953;
	public const uint32 DISPID_WMPCLOSEDCAPTION_CAPTIONINGID = 954;
	public const uint32 DISPID_WMPCLOSEDCAPTION2_GETLANGCOUNT = 955;
	public const uint32 DISPID_WMPCLOSEDCAPTION2_GETLANGNAME = 956;
	public const uint32 DISPID_WMPCLOSEDCAPTION2_GETLANGID = 957;
	public const uint32 DISPID_WMPCLOSEDCAPTION2_GETSTYLECOUNT = 958;
	public const uint32 DISPID_WMPCLOSEDCAPTION2_GETSTYLENAME = 959;
	public const uint32 DISPID_WMPDVD_ISAVAILABLE = 1001;
	public const uint32 DISPID_WMPDVD_DOMAIN = 1002;
	public const uint32 DISPID_WMPDVD_TOPMENU = 1003;
	public const uint32 DISPID_WMPDVD_TITLEMENU = 1004;
	public const uint32 DISPID_WMPDVD_BACK = 1005;
	public const uint32 DISPID_WMPDVD_RESUME = 1006;
	public const uint32 DISPID_WMPMETADATA_PICTURE_MIMETYPE = 1051;
	public const uint32 DISPID_WMPMETADATA_PICTURE_PICTURETYPE = 1052;
	public const uint32 DISPID_WMPMETADATA_PICTURE_DESCRIPTION = 1053;
	public const uint32 DISPID_WMPMETADATA_PICTURE_URL = 1054;
	public const uint32 DISPID_WMPMETADATA_TEXT_TEXT = 1055;
	public const uint32 DISPID_WMPMETADATA_TEXT_DESCRIPTION = 1056;
	public const uint32 DISPID_WMPPLAYERAPP_SWITCHTOPLAYERAPPLICATION = 1101;
	public const uint32 DISPID_WMPPLAYERAPP_SWITCHTOCONTROL = 1102;
	public const uint32 DISPID_WMPPLAYERAPP_PLAYERDOCKED = 1103;
	public const uint32 DISPID_WMPPLAYERAPP_HASDISPLAY = 1104;
	public const uint32 DISPID_WMPPLAYERAPP_REMOTESTATUS = 1105;
	public const uint32 DISPID_WMPDOWNLOADMANAGER_GETDOWNLOADCOLLECTION = 1151;
	public const uint32 DISPID_WMPDOWNLOADMANAGER_CREATEDOWNLOADCOLLECTION = 1152;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_ID = 1201;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_COUNT = 1202;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_ITEM = 1203;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_STARTDOWNLOAD = 1204;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_REMOVEITEM = 1205;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_CLEAR = 1206;
	public const uint32 DISPID_WMPDOWNLOADITEM_SOURCEURL = 1251;
	public const uint32 DISPID_WMPDOWNLOADITEM_SIZE = 1252;
	public const uint32 DISPID_WMPDOWNLOADITEM_TYPE = 1253;
	public const uint32 DISPID_WMPDOWNLOADITEM_PROGRESS = 1254;
	public const uint32 DISPID_WMPDOWNLOADITEM_DOWNLOADSTATE = 1255;
	public const uint32 DISPID_WMPDOWNLOADITEM_PAUSE = 1256;
	public const uint32 DISPID_WMPDOWNLOADITEM_RESUME = 1257;
	public const uint32 DISPID_WMPDOWNLOADITEM_CANCEL = 1258;
	public const uint32 DISPID_WMPDOWNLOADITEM2_GETITEMINFO = 1301;
	public const uint32 DISPID_WMPQUERY_ADDCONDITION = 1351;
	public const uint32 DISPID_WMPQUERY_BEGINNEXTGROUP = 1352;
	public const uint32 DISPID_WMPMEDIACOLLECTION2_CREATEQUERY = 1401;
	public const uint32 DISPID_WMPMEDIACOLLECTION2_GETPLAYLISTBYQUERY = 1402;
	public const uint32 DISPID_WMPMEDIACOLLECTION2_GETSTRINGCOLLBYQUERY = 1403;
	public const uint32 DISPID_WMPMEDIACOLLECTION2_GETBYATTRANDMEDIATYPE = 1404;
	public const uint32 DISPID_WMPSTRINGCOLLECTION2_ISIDENTICAL = 1451;
	public const uint32 DISPID_WMPSTRINGCOLLECTION2_GETITEMINFO = 1452;
	public const uint32 DISPID_WMPSTRINGCOLLECTION2_GETATTRCOUNTBYTYPE = 1453;
	public const uint32 DISPID_WMPSTRINGCOLLECTION2_GETITEMINFOBYTYPE = 1454;
	public const uint32 DISPID_WMPCORE_MIN = 1;
	public const uint32 DISPID_WMPCORE_MAX = 1454;
	public const uint32 WMPCOREEVENT_BASE = 5000;
	public const uint32 DISPID_WMPCOREEVENT_OPENSTATECHANGE = 5001;
	public const uint32 DISPID_WMPCOREEVENT_STATUSCHANGE = 5002;
	public const uint32 WMPCOREEVENT_CONTROL_BASE = 5100;
	public const uint32 DISPID_WMPCOREEVENT_PLAYSTATECHANGE = 5101;
	public const uint32 DISPID_WMPCOREEVENT_AUDIOLANGUAGECHANGE = 5102;
	public const uint32 WMPCOREEVENT_SEEK_BASE = 5200;
	public const uint32 DISPID_WMPCOREEVENT_ENDOFSTREAM = 5201;
	public const uint32 DISPID_WMPCOREEVENT_POSITIONCHANGE = 5202;
	public const uint32 DISPID_WMPCOREEVENT_MARKERHIT = 5203;
	public const uint32 DISPID_WMPCOREEVENT_DURATIONUNITCHANGE = 5204;
	public const uint32 WMPCOREEVENT_CONTENT_BASE = 5300;
	public const uint32 DISPID_WMPCOREEVENT_SCRIPTCOMMAND = 5301;
	public const uint32 WMPCOREEVENT_NETWORK_BASE = 5400;
	public const uint32 DISPID_WMPCOREEVENT_DISCONNECT = 5401;
	public const uint32 DISPID_WMPCOREEVENT_BUFFERING = 5402;
	public const uint32 DISPID_WMPCOREEVENT_NEWSTREAM = 5403;
	public const uint32 WMPCOREEVENT_ERROR_BASE = 5500;
	public const uint32 DISPID_WMPCOREEVENT_ERROR = 5501;
	public const uint32 WMPCOREEVENT_WARNING_BASE = 5600;
	public const uint32 DISPID_WMPCOREEVENT_WARNING = 5601;
	public const uint32 WMPCOREEVENT_CDROM_BASE = 5700;
	public const uint32 DISPID_WMPCOREEVENT_CDROMMEDIACHANGE = 5701;
	public const uint32 WMPCOREEVENT_PLAYLIST_BASE = 5800;
	public const uint32 DISPID_WMPCOREEVENT_PLAYLISTCHANGE = 5801;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACHANGE = 5802;
	public const uint32 DISPID_WMPCOREEVENT_CURRENTMEDIAITEMAVAILABLE = 5803;
	public const uint32 DISPID_WMPCOREEVENT_CURRENTPLAYLISTCHANGE = 5804;
	public const uint32 DISPID_WMPCOREEVENT_CURRENTPLAYLISTITEMAVAILABLE = 5805;
	public const uint32 DISPID_WMPCOREEVENT_CURRENTITEMCHANGE = 5806;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONCHANGE = 5807;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONATTRIBUTESTRINGADDED = 5808;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONATTRIBUTESTRINGREMOVED = 5809;
	public const uint32 DISPID_WMPCOREEVENT_PLAYLISTCOLLECTIONCHANGE = 5810;
	public const uint32 DISPID_WMPCOREEVENT_PLAYLISTCOLLECTIONPLAYLISTADDED = 5811;
	public const uint32 DISPID_WMPCOREEVENT_PLAYLISTCOLLECTIONPLAYLISTREMOVED = 5812;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONCONTENTSCANADDEDITEM = 5813;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONCONTENTSCANPROGRESS = 5814;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONSEARCHFOUNDITEM = 5815;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONSEARCHPROGRESS = 5816;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONSEARCHCOMPLETE = 5817;
	public const uint32 DISPID_WMPCOREEVENT_PLAYLISTCOLLECTIONPLAYLISTSETASDELETED = 5818;
	public const uint32 DISPID_WMPCOREEVENT_MODECHANGE = 5819;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONATTRIBUTESTRINGCHANGED = 5820;
	public const uint32 DISPID_WMPCOREEVENT_MEDIAERROR = 5821;
	public const uint32 DISPID_WMPCOREEVENT_DOMAINCHANGE = 5822;
	public const uint32 DISPID_WMPCOREEVENT_OPENPLAYLISTSWITCH = 5823;
	public const uint32 DISPID_WMPCOREEVENT_STRINGCOLLECTIONCHANGE = 5824;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONMEDIAADDED = 5825;
	public const uint32 DISPID_WMPCOREEVENT_MEDIACOLLECTIONMEDIAREMOVED = 5826;
	public const uint32 WMPOCXEVENT_BASE = 6500;
	public const uint32 DISPID_WMPOCXEVENT_SWITCHEDTOPLAYERAPPLICATION = 6501;
	public const uint32 DISPID_WMPOCXEVENT_SWITCHEDTOCONTROL = 6502;
	public const uint32 DISPID_WMPOCXEVENT_PLAYERDOCKEDSTATECHANGE = 6503;
	public const uint32 DISPID_WMPOCXEVENT_PLAYERRECONNECT = 6504;
	public const uint32 DISPID_WMPOCXEVENT_CLICK = 6505;
	public const uint32 DISPID_WMPOCXEVENT_DOUBLECLICK = 6506;
	public const uint32 DISPID_WMPOCXEVENT_KEYDOWN = 6507;
	public const uint32 DISPID_WMPOCXEVENT_KEYPRESS = 6508;
	public const uint32 DISPID_WMPOCXEVENT_KEYUP = 6509;
	public const uint32 DISPID_WMPOCXEVENT_MOUSEDOWN = 6510;
	public const uint32 DISPID_WMPOCXEVENT_MOUSEMOVE = 6511;
	public const uint32 DISPID_WMPOCXEVENT_MOUSEUP = 6512;
	public const uint32 DISPID_WMPOCXEVENT_DEVICECONNECT = 6513;
	public const uint32 DISPID_WMPOCXEVENT_DEVICEDISCONNECT = 6514;
	public const uint32 DISPID_WMPOCXEVENT_DEVICESTATUSCHANGE = 6515;
	public const uint32 DISPID_WMPOCXEVENT_DEVICESYNCSTATECHANGE = 6516;
	public const uint32 DISPID_WMPOCXEVENT_DEVICESYNCERROR = 6517;
	public const uint32 DISPID_WMPOCXEVENT_CREATEPARTNERSHIPCOMPLETE = 6518;
	public const uint32 DISPID_WMPOCXEVENT_CDROMRIPSTATECHANGE = 6519;
	public const uint32 DISPID_WMPOCXEVENT_CDROMRIPMEDIAERROR = 6520;
	public const uint32 DISPID_WMPOCXEVENT_CDROMBURNSTATECHANGE = 6521;
	public const uint32 DISPID_WMPOCXEVENT_CDROMBURNMEDIAERROR = 6522;
	public const uint32 DISPID_WMPOCXEVENT_CDROMBURNERROR = 6523;
	public const uint32 DISPID_WMPOCXEVENT_LIBRARYCONNECT = 6524;
	public const uint32 DISPID_WMPOCXEVENT_LIBRARYDISCONNECT = 6525;
	public const uint32 DISPID_WMPOCXEVENT_FOLDERSCANSTATECHANGE = 6526;
	public const uint32 DISPID_WMPOCXEVENT_DEVICEESTIMATION = 6527;
	public const uint32 DISPID_WMPCONTROLS_BASE = 50;
	public const uint32 DISPID_WMPSETTINGS_BASE = 100;
	public const uint32 DISPID_WMPPLAYLIST_BASE = 200;
	public const uint32 DISPID_WMPCDROM_BASE = 250;
	public const uint32 DISPID_WMPCDROMCOLLECTION_BASE = 300;
	public const uint32 DISPID_WMPSTRINGCOLLECTION_BASE = 400;
	public const uint32 DISPID_WMPMEDIACOLLECTION_BASE = 450;
	public const uint32 DISPID_WMPPLAYLISTARRAY_BASE = 500;
	public const uint32 DISPID_WMPPLAYLISTCOLLECTION_BASE = 550;
	public const uint32 DISPID_WMPMEDIA_BASE = 750;
	public const uint32 DISPID_WMPNETWORK_BASE = 800;
	public const uint32 DISPID_WMPERROR_BASE = 850;
	public const uint32 DISPID_WMPERRORITEM_BASE = 900;
	public const uint32 DISPID_WMPCLOSEDCAPTION_BASE = 950;
	public const uint32 DISPID_WMPDVD_BASE = 1000;
	public const uint32 DISPID_WMPMETADATA_BASE = 1050;
	public const uint32 DISPID_WMPPLAYERAPP_BASE = 1100;
	public const uint32 DISPID_WMPDOWNLOADMANAGER_BASE = 1150;
	public const uint32 DISPID_WMPDOWNLOADCOLLECTION_BASE = 1200;
	public const uint32 DISPID_WMPDOWNLOADITEM_BASE = 1250;
	public const uint32 DISPID_WMPDOWNLOADITEM2_BASE = 1300;
	public const uint32 DISPID_WMPQUERY_BASE = 1350;
	public const uint32 DISPID_WMPMEDIACOLLECTION2_BASE = 1400;
	public const uint32 DISPID_WMPSTRINGCOLLECTION2_BASE = 1450;
	public const Guid CLSID_WMPSkinManager = .(0xb2a7fd52, 0x301f, 0x4348, 0xb9, 0x3a, 0x63, 0x8c, 0x6d, 0xe4, 0x92, 0x29);
	public const Guid CLSID_WMPMediaPluginRegistrar = .(0x5569e7f5, 0x424b, 0x4b93, 0x89, 0xca, 0x79, 0xd1, 0x79, 0x24, 0x68, 0x9a);
	public const Guid WMP_PLUGINTYPE_DSP = .(0x6434baea, 0x4954, 0x498d, 0xab, 0xd5, 0x2b, 0x07, 0x12, 0x3e, 0x1f, 0x04);
	public const Guid WMP_PLUGINTYPE_DSP_OUTOFPROC = .(0xef29b174, 0xc347, 0x44cc, 0x9a, 0x4f, 0x23, 0x99, 0x11, 0x8f, 0xf3, 0x8c);
	public const Guid WMP_PLUGINTYPE_RENDERING = .(0xa8554541, 0x115d, 0x406a, 0xa4, 0xc7, 0x51, 0x11, 0x1c, 0x33, 0x01, 0x83);
	public const float kfltTimedLevelMaximumFrequency = 22050f;
	public const float kfltTimedLevelMinimumFrequency = 20f;
	public const String g_szContentPartnerInfo_LoginState = "LoginState";
	public const String g_szContentPartnerInfo_MediaPlayerAccountType = "MediaPlayerAccountType";
	public const String g_szContentPartnerInfo_AccountType = "AccountType";
	public const String g_szContentPartnerInfo_HasCachedCredentials = "HasCachedCredentials";
	public const String g_szContentPartnerInfo_LicenseRefreshAdvanceWarning = "LicenseRefreshAdvanceWarning";
	public const String g_szContentPartnerInfo_PurchasedTrackRequiresReDownload = "PurchasedTrackRequiresReDownload";
	public const String g_szContentPartnerInfo_MaximumTrackPurchasePerPurchase = "MaximumNumberOfTracksPerPurchase";
	public const String g_szContentPartnerInfo_AccountBalance = "AccountBalance";
	public const String g_szContentPartnerInfo_UserName = "UserName";
	public const String g_szMediaPlayerTask_Burn = "Burn";
	public const String g_szMediaPlayerTask_Browse = "Browse";
	public const String g_szMediaPlayerTask_Sync = "Sync";
	public const String g_szItemInfo_PopupURL = "Popup";
	public const String g_szItemInfo_AuthenticationSuccessURL = "AuthenticationSuccessURL";
	public const String g_szItemInfo_LoginFailureURL = "LoginFailureURL";
	public const String g_szItemInfo_HTMLViewURL = "HTMLViewURL";
	public const String g_szItemInfo_PopupCaption = "PopupCaption";
	public const String g_szItemInfo_ALTLoginURL = "ALTLoginURL";
	public const String g_szItemInfo_ALTLoginCaption = "ALTLoginCaption";
	public const String g_szItemInfo_ForgetPasswordURL = "ForgotPassword";
	public const String g_szItemInfo_CreateAccountURL = "CreateAccount";
	public const String g_szItemInfo_ArtistArtURL = "ArtistArt";
	public const String g_szItemInfo_AlbumArtURL = "AlbumArt";
	public const String g_szItemInfo_ListArtURL = "ListArt";
	public const String g_szItemInfo_GenreArtURL = "GenreArt";
	public const String g_szItemInfo_SubGenreArtURL = "SubGenreArt";
	public const String g_szItemInfo_RadioArtURL = "RadioArt";
	public const String g_szItemInfo_TreeListIconURL = "CPListIDIcon";
	public const String g_szItemInfo_ErrorDescription = "CPErrorDescription";
	public const String g_szItemInfo_ErrorURL = "CPErrorURL";
	public const String g_szItemInfo_ErrorURLLinkText = "CPErrorURLLinkText";
	public const String g_szUnknownLocation = "UnknownLocation";
	public const String g_szRootLocation = "RootLocation";
	public const String g_szFlyoutMenu = "FlyoutMenu";
	public const String g_szOnlineStore = "OnlineStore";
	public const String g_szVideoRecent = "VideoRecent";
	public const String g_szVideoRoot = "VideoRoot";
	public const String g_szCPListID = "CPListID";
	public const String g_szAllCPListIDs = "AllCPListIDs";
	public const String g_szCPTrackID = "CPTrackID";
	public const String g_szAllCPTrackIDs = "AllCPTrackIDs";
	public const String g_szCPArtistID = "CPArtistID";
	public const String g_szAllCPArtistIDs = "AllCPArtistIDs";
	public const String g_szCPAlbumID = "CPAlbumID";
	public const String g_szAllCPAlbumIDs = "AllCPAlbumIDs";
	public const String g_szCPGenreID = "CPGenreID";
	public const String g_szAllCPGenreIDs = "AllCPGenreIDs";
	public const String g_szCPAlbumSubGenreID = "CPAlbumSubGenreID";
	public const String g_szAllCPAlbumSubGenreIDs = "AllCPAlbumSubGenreIDs";
	public const String g_szReleaseDateYear = "ReleaseDateYear";
	public const String g_szAllReleaseDateYears = "AllReleaseDateYears";
	public const String g_szCPRadioID = "CPRadioID";
	public const String g_szAllCPRadioIDs = "AllCPRadioIDs";
	public const String g_szAuthor = "Author";
	public const String g_szAllAuthors = "AllAuthors";
	public const String g_szWMParentalRating = "WMParentalRating";
	public const String g_szAllWMParentalRatings = "AllWMParentalRatings";
	public const String g_szAllUserEffectiveRatingStarss = "AllUserEffectiveRatingStarss";
	public const String g_szUserEffectiveRatingStars = "UserEffectiveRatingStars";
	public const String g_szUserPlaylist = "UserPlaylist";
	public const String g_szViewMode_Report = "ViewModeReport";
	public const String g_szViewMode_Details = "ViewModeDetails";
	public const String g_szViewMode_Icon = "ViewModeIcon";
	public const String g_szViewMode_Tile = "ViewModeTile";
	public const String g_szViewMode_OrderedList = "ViewModeOrderedList";
	public const String g_szContentPrice_Unknown = "PriceUnknown";
	public const String g_szContentPrice_CannotBuy = "PriceCannotBuy";
	public const String g_szContentPrice_Free = "PriceFree";
	public const String g_szRefreshLicensePlay = "RefreshForPlay";
	public const String g_szRefreshLicenseBurn = "RefreshForBurn";
	public const String g_szRefreshLicenseSync = "RefreshForSync";
	public const String g_szVerifyPermissionSync = "VerifyPermissionSync";
	public const String g_szStationEvent_Started = "TrackStarted";
	public const String g_szStationEvent_Complete = "TrackComplete";
	public const String g_szStationEvent_Skipped = "TrackSkipped";
	public const Guid WMProfile_V40_DialUpMBR = .(0xfd7f47f1, 0x72a6, 0x45a4, 0x80, 0xf0, 0x3a, 0xec, 0xef, 0xc3, 0x2c, 0x07);
	public const Guid WMProfile_V40_IntranetMBR = .(0x82cd3321, 0xa94a, 0x4ffc, 0x9c, 0x2b, 0x09, 0x2c, 0x10, 0xca, 0x16, 0xe7);
	public const Guid WMProfile_V40_2856100MBR = .(0x5a1c2206, 0xdc5e, 0x4186, 0xbe, 0xb2, 0x4c, 0x5a, 0x99, 0x4b, 0x13, 0x2e);
	public const Guid WMProfile_V40_6VoiceAudio = .(0xd508978a, 0x11a0, 0x4d15, 0xb0, 0xda, 0xac, 0xdc, 0x99, 0xd4, 0xf8, 0x90);
	public const Guid WMProfile_V40_16AMRadio = .(0x0f4be81f, 0xd57d, 0x41e1, 0xb2, 0xe3, 0x2f, 0xad, 0x98, 0x6b, 0xfe, 0xc2);
	public const Guid WMProfile_V40_288FMRadioMono = .(0x7fa57fc8, 0x6ea4, 0x4645, 0x8a, 0xbf, 0xb6, 0xe5, 0xa8, 0xf8, 0x14, 0xa1);
	public const Guid WMProfile_V40_288FMRadioStereo = .(0x22fcf466, 0xaa40, 0x431f, 0xa2, 0x89, 0x06, 0xd0, 0xea, 0x1a, 0x1e, 0x40);
	public const Guid WMProfile_V40_56DialUpStereo = .(0xe8026f87, 0xe905, 0x4594, 0xa3, 0xc7, 0x00, 0xd0, 0x00, 0x41, 0xd1, 0xd9);
	public const Guid WMProfile_V40_64Audio = .(0x4820b3f7, 0xcbec, 0x41dc, 0x93, 0x91, 0x78, 0x59, 0x87, 0x14, 0xc8, 0xe5);
	public const Guid WMProfile_V40_96Audio = .(0x0efa0ee3, 0x9e64, 0x41e2, 0x83, 0x7f, 0x3c, 0x00, 0x38, 0xf3, 0x27, 0xba);
	public const Guid WMProfile_V40_128Audio = .(0x93ddbe12, 0x13dc, 0x4e32, 0xa3, 0x5e, 0x40, 0x37, 0x8e, 0x34, 0x27, 0x9a);
	public const Guid WMProfile_V40_288VideoVoice = .(0xbb2bc274, 0x0eb6, 0x4da9, 0xb5, 0x50, 0xec, 0xf7, 0xf2, 0xb9, 0x94, 0x8f);
	public const Guid WMProfile_V40_288VideoAudio = .(0xac617f2d, 0x6cbe, 0x4e84, 0x8e, 0x9a, 0xce, 0x15, 0x1a, 0x12, 0xa3, 0x54);
	public const Guid WMProfile_V40_288VideoWebServer = .(0xabf2f00d, 0xd555, 0x4815, 0x94, 0xce, 0x82, 0x75, 0xf3, 0xa7, 0x0b, 0xfe);
	public const Guid WMProfile_V40_56DialUpVideo = .(0xe21713bb, 0x652f, 0x4dab, 0x99, 0xde, 0x71, 0xe0, 0x44, 0x00, 0x27, 0x0f);
	public const Guid WMProfile_V40_56DialUpVideoWebServer = .(0xb756ff10, 0x520f, 0x4749, 0xa3, 0x99, 0xb7, 0x80, 0xe2, 0xfc, 0x92, 0x50);
	public const Guid WMProfile_V40_100Video = .(0x8f99ddd8, 0x6684, 0x456b, 0xa0, 0xa3, 0x33, 0xe1, 0x31, 0x68, 0x95, 0xf0);
	public const Guid WMProfile_V40_250Video = .(0x541841c3, 0x9339, 0x4f7b, 0x9a, 0x22, 0xb1, 0x15, 0x40, 0x89, 0x4e, 0x42);
	public const Guid WMProfile_V40_512Video = .(0x70440e6d, 0xc4ef, 0x4f84, 0x8c, 0xd0, 0xd5, 0xc2, 0x86, 0x86, 0xe7, 0x84);
	public const Guid WMProfile_V40_1MBVideo = .(0xb4482a4c, 0xcc17, 0x4b07, 0xa9, 0x4e, 0x98, 0x18, 0xd5, 0xe0, 0xf1, 0x3f);
	public const Guid WMProfile_V40_3MBVideo = .(0x55374ac0, 0x309b, 0x4396, 0xb8, 0x8f, 0xe6, 0xe2, 0x92, 0x11, 0x3f, 0x28);
	public const Guid WMProfile_V70_DialUpMBR = .(0x5b16e74b, 0x4068, 0x45b5, 0xb8, 0x0e, 0x7b, 0xf8, 0xc8, 0x0d, 0x2c, 0x2f);
	public const Guid WMProfile_V70_IntranetMBR = .(0x045880dc, 0x34b6, 0x4ca9, 0xa3, 0x26, 0x73, 0x55, 0x7e, 0xd1, 0x43, 0xf3);
	public const Guid WMProfile_V70_2856100MBR = .(0x07df7a25, 0x3fe2, 0x4a5b, 0x8b, 0x1e, 0x34, 0x8b, 0x07, 0x21, 0xca, 0x70);
	public const Guid WMProfile_V70_288VideoVoice = .(0xb952f38e, 0x7dbc, 0x4533, 0xa9, 0xca, 0xb0, 0x0b, 0x1c, 0x6e, 0x98, 0x00);
	public const Guid WMProfile_V70_288VideoAudio = .(0x58bba0ee, 0x896a, 0x4948, 0x99, 0x53, 0x85, 0xb7, 0x36, 0xf8, 0x39, 0x47);
	public const Guid WMProfile_V70_288VideoWebServer = .(0x70a32e2b, 0xe2df, 0x4ebd, 0x91, 0x05, 0xd9, 0xca, 0x19, 0x4a, 0x2d, 0x50);
	public const Guid WMProfile_V70_56VideoWebServer = .(0xdef99e40, 0x57bc, 0x4ab3, 0xb2, 0xd1, 0xb6, 0xe3, 0xca, 0xf6, 0x42, 0x57);
	public const Guid WMProfile_V70_64VideoISDN = .(0xc2b7a7e9, 0x7b8e, 0x4992, 0xa1, 0xa1, 0x06, 0x82, 0x17, 0xa3, 0xb3, 0x11);
	public const Guid WMProfile_V70_100Video = .(0xd9f3c932, 0x5ea9, 0x4c6d, 0x89, 0xb4, 0x26, 0x86, 0xe5, 0x15, 0x42, 0x6e);
	public const Guid WMProfile_V70_256Video = .(0xafe69b3a, 0x403f, 0x4a1b, 0x80, 0x07, 0x0e, 0x21, 0xcf, 0xb3, 0xdf, 0x84);
	public const Guid WMProfile_V70_384Video = .(0xf3d45fbb, 0x8782, 0x44df, 0x97, 0xc6, 0x86, 0x78, 0xe2, 0xf9, 0xb1, 0x3d);
	public const Guid WMProfile_V70_768Video = .(0x0326ebb6, 0xf76e, 0x4964, 0xb0, 0xdb, 0xe7, 0x29, 0x97, 0x8d, 0x35, 0xee);
	public const Guid WMProfile_V70_1500Video = .(0x0b89164a, 0x5490, 0x4686, 0x9e, 0x37, 0x5a, 0x80, 0x88, 0x4e, 0x51, 0x46);
	public const Guid WMProfile_V70_2000Video = .(0xaa980124, 0xbf10, 0x4e4f, 0x9a, 0xfd, 0x43, 0x29, 0xa7, 0x39, 0x5c, 0xff);
	public const Guid WMProfile_V70_700FilmContentVideo = .(0x7a747920, 0x2449, 0x4d76, 0x99, 0xcb, 0xfd, 0xb0, 0xc9, 0x04, 0x84, 0xd4);
	public const Guid WMProfile_V70_1500FilmContentVideo = .(0xf6a5f6df, 0xee3f, 0x434c, 0xa4, 0x33, 0x52, 0x3c, 0xe5, 0x5f, 0x51, 0x6b);
	public const Guid WMProfile_V70_6VoiceAudio = .(0xeaba9fbf, 0xb64f, 0x49b3, 0xaa, 0x0c, 0x73, 0xfb, 0xdd, 0x15, 0x0a, 0xd0);
	public const Guid WMProfile_V70_288FMRadioMono = .(0xc012a833, 0xa03b, 0x44a5, 0x96, 0xdc, 0xed, 0x95, 0xcc, 0x65, 0x58, 0x2d);
	public const Guid WMProfile_V70_288FMRadioStereo = .(0xe96d67c9, 0x1a39, 0x4dc4, 0xb9, 0x00, 0xb1, 0x18, 0x4d, 0xc8, 0x36, 0x20);
	public const Guid WMProfile_V70_56DialUpStereo = .(0x674ee767, 0x0949, 0x4fac, 0x87, 0x5e, 0xf4, 0xc9, 0xc2, 0x92, 0x01, 0x3b);
	public const Guid WMProfile_V70_64AudioISDN = .(0x91dea458, 0x9d60, 0x4212, 0x9c, 0x59, 0xd4, 0x09, 0x19, 0xc9, 0x39, 0xe4);
	public const Guid WMProfile_V70_64Audio = .(0xb29cffc6, 0xf131, 0x41db, 0xb5, 0xe8, 0x99, 0xd8, 0xb0, 0xb9, 0x45, 0xf4);
	public const Guid WMProfile_V70_96Audio = .(0xa9d4b819, 0x16cc, 0x4a59, 0x9f, 0x37, 0x69, 0x3d, 0xbb, 0x03, 0x02, 0xd6);
	public const Guid WMProfile_V70_128Audio = .(0xc64cf5da, 0xdf45, 0x40d3, 0x80, 0x27, 0xde, 0x69, 0x8d, 0x68, 0xdc, 0x66);
	public const Guid WMProfile_V70_225VideoPDA = .(0xf55ea573, 0x4c02, 0x42b5, 0x90, 0x26, 0xa8, 0x26, 0x0c, 0x43, 0x8a, 0x9f);
	public const Guid WMProfile_V70_150VideoPDA = .(0x0f472967, 0xe3c6, 0x4797, 0x96, 0x94, 0xf0, 0x30, 0x4c, 0x5e, 0x2f, 0x17);
	public const Guid WMProfile_V80_255VideoPDA = .(0xfeedbcdf, 0x3fac, 0x4c93, 0xac, 0x0d, 0x47, 0x94, 0x1e, 0xc7, 0x2c, 0x0b);
	public const Guid WMProfile_V80_150VideoPDA = .(0xaee16dfa, 0x2c14, 0x4a2f, 0xad, 0x3f, 0xa3, 0x03, 0x40, 0x31, 0x78, 0x4f);
	public const Guid WMProfile_V80_28856VideoMBR = .(0xd66920c4, 0xc21f, 0x4ec8, 0xa0, 0xb4, 0x95, 0xcf, 0x2b, 0xd5, 0x7f, 0xc4);
	public const Guid WMProfile_V80_100768VideoMBR = .(0x5bdb5a0e, 0x979e, 0x47d3, 0x95, 0x96, 0x73, 0xb3, 0x86, 0x39, 0x2a, 0x55);
	public const Guid WMProfile_V80_288100VideoMBR = .(0xd8722c69, 0x2419, 0x4b36, 0xb4, 0xe0, 0x6e, 0x17, 0xb6, 0x05, 0x64, 0xe5);
	public const Guid WMProfile_V80_288Video = .(0x3df678d9, 0x1352, 0x4186, 0xbb, 0xf8, 0x74, 0xf0, 0xc1, 0x9b, 0x6a, 0xe2);
	public const Guid WMProfile_V80_56Video = .(0x254e8a96, 0x2612, 0x405c, 0x80, 0x39, 0xf0, 0xbf, 0x72, 0x5c, 0xed, 0x7d);
	public const Guid WMProfile_V80_100Video = .(0xa2e300b4, 0xc2d4, 0x4fc0, 0xb5, 0xdd, 0xec, 0xbd, 0x94, 0x8d, 0xc0, 0xdf);
	public const Guid WMProfile_V80_256Video = .(0xbbc75500, 0x33d2, 0x4466, 0xb8, 0x6b, 0x12, 0x2b, 0x20, 0x1c, 0xc9, 0xae);
	public const Guid WMProfile_V80_384Video = .(0x29b00c2b, 0x09a9, 0x48bd, 0xad, 0x09, 0xcd, 0xae, 0x11, 0x7d, 0x1d, 0xa7);
	public const Guid WMProfile_V80_768Video = .(0x74d01102, 0xe71a, 0x4820, 0x8f, 0x0d, 0x13, 0xd2, 0xec, 0x1e, 0x48, 0x72);
	public const Guid WMProfile_V80_700NTSCVideo = .(0xc8c2985f, 0xe5d9, 0x4538, 0x9e, 0x23, 0x9b, 0x21, 0xbf, 0x78, 0xf7, 0x45);
	public const Guid WMProfile_V80_1400NTSCVideo = .(0x931d1bee, 0x617a, 0x4bcd, 0x99, 0x05, 0xcc, 0xd0, 0x78, 0x66, 0x83, 0xee);
	public const Guid WMProfile_V80_384PALVideo = .(0x9227c692, 0xae62, 0x4f72, 0xa7, 0xea, 0x73, 0x60, 0x62, 0xd0, 0xe2, 0x1e);
	public const Guid WMProfile_V80_700PALVideo = .(0xec298949, 0x639b, 0x45e2, 0x96, 0xfd, 0x4a, 0xb3, 0x2d, 0x59, 0x19, 0xc2);
	public const Guid WMProfile_V80_288MonoAudio = .(0x7ea3126d, 0xe1ba, 0x4716, 0x89, 0xaf, 0xf6, 0x5c, 0xee, 0x0c, 0x0c, 0x67);
	public const Guid WMProfile_V80_288StereoAudio = .(0x7e4cab5c, 0x35dc, 0x45bb, 0xa7, 0xc0, 0x19, 0xb2, 0x80, 0x70, 0xd0, 0xcc);
	public const Guid WMProfile_V80_32StereoAudio = .(0x60907f9f, 0xb352, 0x47e5, 0xb2, 0x10, 0x0e, 0xf1, 0xf4, 0x7e, 0x9f, 0x9d);
	public const Guid WMProfile_V80_48StereoAudio = .(0x5ee06be5, 0x492b, 0x480a, 0x8a, 0x8f, 0x12, 0xf3, 0x73, 0xec, 0xf9, 0xd4);
	public const Guid WMProfile_V80_64StereoAudio = .(0x09bb5bc4, 0x3176, 0x457f, 0x8d, 0xd6, 0x3c, 0xd9, 0x19, 0x12, 0x3e, 0x2d);
	public const Guid WMProfile_V80_96StereoAudio = .(0x1fc81930, 0x61f2, 0x436f, 0x9d, 0x33, 0x34, 0x9f, 0x2a, 0x1c, 0x0f, 0x10);
	public const Guid WMProfile_V80_128StereoAudio = .(0x407b9450, 0x8bdc, 0x4ee5, 0x88, 0xb8, 0x6f, 0x52, 0x7b, 0xd9, 0x41, 0xf2);
	public const Guid WMProfile_V80_288VideoOnly = .(0x8c45b4c7, 0x4aeb, 0x4f78, 0xa5, 0xec, 0x88, 0x42, 0x0b, 0x9d, 0xad, 0xef);
	public const Guid WMProfile_V80_56VideoOnly = .(0x6e2a6955, 0x81df, 0x4943, 0xba, 0x50, 0x68, 0xa9, 0x86, 0xa7, 0x08, 0xf6);
	public const Guid WMProfile_V80_FAIRVBRVideo = .(0x3510a862, 0x5850, 0x4886, 0x83, 0x5f, 0xd7, 0x8e, 0xc6, 0xa6, 0x40, 0x42);
	public const Guid WMProfile_V80_HIGHVBRVideo = .(0x0f10d9d3, 0x3b04, 0x4fb0, 0xa3, 0xd3, 0x88, 0xd4, 0xac, 0x85, 0x4a, 0xcc);
	public const Guid WMProfile_V80_BESTVBRVideo = .(0x048439ba, 0x309c, 0x440e, 0x9c, 0xb4, 0x3d, 0xcc, 0xa3, 0x75, 0x64, 0x23);
}
#endregion

#region Enums

[AllowDuplicates]
public enum WMPOpenState : int32
{
	wmposUndefined = 0,
	wmposPlaylistChanging = 1,
	wmposPlaylistLocating = 2,
	wmposPlaylistConnecting = 3,
	wmposPlaylistLoading = 4,
	wmposPlaylistOpening = 5,
	wmposPlaylistOpenNoMedia = 6,
	wmposPlaylistChanged = 7,
	wmposMediaChanging = 8,
	wmposMediaLocating = 9,
	wmposMediaConnecting = 10,
	wmposMediaLoading = 11,
	wmposMediaOpening = 12,
	wmposMediaOpen = 13,
	wmposBeginCodecAcquisition = 14,
	wmposEndCodecAcquisition = 15,
	wmposBeginLicenseAcquisition = 16,
	wmposEndLicenseAcquisition = 17,
	wmposBeginIndividualization = 18,
	wmposEndIndividualization = 19,
	wmposMediaWaiting = 20,
	wmposOpeningUnknownURL = 21,
}


[AllowDuplicates]
public enum WMPPlayState : int32
{
	wmppsUndefined = 0,
	wmppsStopped = 1,
	wmppsPaused = 2,
	wmppsPlaying = 3,
	wmppsScanForward = 4,
	wmppsScanReverse = 5,
	wmppsBuffering = 6,
	wmppsWaiting = 7,
	wmppsMediaEnded = 8,
	wmppsTransitioning = 9,
	wmppsReady = 10,
	wmppsReconnecting = 11,
	wmppsLast = 12,
}


[AllowDuplicates]
public enum WMPPlaylistChangeEventType : int32
{
	wmplcUnknown = 0,
	wmplcClear = 1,
	wmplcInfoChange = 2,
	wmplcMove = 3,
	wmplcDelete = 4,
	wmplcInsert = 5,
	wmplcAppend = 6,
	wmplcPrivate = 7,
	wmplcNameChange = 8,
	wmplcMorph = 9,
	wmplcSort = 10,
	wmplcLast = 11,
}


[AllowDuplicates]
public enum WMPSyncState : int32
{
	wmpssUnknown = 0,
	wmpssSynchronizing = 1,
	wmpssStopped = 2,
	wmpssEstimating = 3,
	wmpssLast = 4,
}


[AllowDuplicates]
public enum WMPDeviceStatus : int32
{
	wmpdsUnknown = 0,
	wmpdsPartnershipExists = 1,
	wmpdsPartnershipDeclined = 2,
	wmpdsPartnershipAnother = 3,
	wmpdsManualDevice = 4,
	wmpdsNewDevice = 5,
	wmpdsLast = 6,
}


[AllowDuplicates]
public enum WMPRipState : int32
{
	wmprsUnknown = 0,
	wmprsRipping = 1,
	wmprsStopped = 2,
}


[AllowDuplicates]
public enum WMPBurnFormat : int32
{
	wmpbfAudioCD = 0,
	wmpbfDataCD = 1,
}


[AllowDuplicates]
public enum WMPBurnState : int32
{
	wmpbsUnknown = 0,
	wmpbsBusy = 1,
	wmpbsReady = 2,
	wmpbsWaitingForDisc = 3,
	wmpbsRefreshStatusPending = 4,
	wmpbsPreparingToBurn = 5,
	wmpbsBurning = 6,
	wmpbsStopped = 7,
	wmpbsErasing = 8,
	wmpbsDownloading = 9,
}


[AllowDuplicates]
public enum WMPStringCollectionChangeEventType : int32
{
	wmpsccetUnknown = 0,
	wmpsccetInsert = 1,
	wmpsccetChange = 2,
	wmpsccetDelete = 3,
	wmpsccetClear = 4,
	wmpsccetBeginUpdates = 5,
	wmpsccetEndUpdates = 6,
}


[AllowDuplicates]
public enum WMPLibraryType : int32
{
	wmpltUnknown = 0,
	wmpltAll = 1,
	wmpltLocal = 2,
	wmpltRemote = 3,
	wmpltDisc = 4,
	wmpltPortableDevice = 5,
}


[AllowDuplicates]
public enum WMPFolderScanState : int32
{
	wmpfssUnknown = 0,
	wmpfssScanning = 1,
	wmpfssUpdating = 2,
	wmpfssStopped = 3,
}


[AllowDuplicates]
public enum WMPServices_StreamState : int32
{
	WMPServices_StreamState_Stop = 0,
	WMPServices_StreamState_Pause = 1,
	WMPServices_StreamState_Play = 2,
}


[AllowDuplicates]
public enum WMPPlugin_Caps : int32
{
	WMPPlugin_Caps_CannotConvertFormats = 1,
}


[AllowDuplicates]
public enum FEEDS_BACKGROUNDSYNC_ACTION : int32
{
	FBSA_DISABLE = 0,
	FBSA_ENABLE = 1,
	FBSA_RUNNOW = 2,
}


[AllowDuplicates]
public enum FEEDS_BACKGROUNDSYNC_STATUS : int32
{
	FBSS_DISABLED = 0,
	FBSS_ENABLED = 1,
}


[AllowDuplicates]
public enum FEEDS_EVENTS_SCOPE : int32
{
	FES_ALL = 0,
	FES_SELF_ONLY = 1,
	FES_SELF_AND_CHILDREN_ONLY = 2,
}


[AllowDuplicates]
public enum FEEDS_EVENTS_MASK : int32
{
	FEM_FOLDEREVENTS = 1,
	FEM_FEEDEVENTS = 2,
}


[AllowDuplicates]
public enum FEEDS_XML_SORT_PROPERTY : int32
{
	FXSP_NONE = 0,
	FXSP_PUBDATE = 1,
	FXSP_DOWNLOADTIME = 2,
}


[AllowDuplicates]
public enum FEEDS_XML_SORT_ORDER : int32
{
	FXSO_NONE = 0,
	FXSO_ASCENDING = 1,
	FXSO_DESCENDING = 2,
}


[AllowDuplicates]
public enum FEEDS_XML_FILTER_FLAGS : int32
{
	FXFF_ALL = 0,
	FXFF_UNREAD = 1,
	FXFF_READ = 2,
}


[AllowDuplicates]
public enum FEEDS_XML_INCLUDE_FLAGS : int32
{
	FXIF_NONE = 0,
	FXIF_CF_EXTENSIONS = 1,
}


[AllowDuplicates]
public enum FEEDS_DOWNLOAD_STATUS : int32
{
	FDS_NONE = 0,
	FDS_PENDING = 1,
	FDS_DOWNLOADING = 2,
	FDS_DOWNLOADED = 3,
	FDS_DOWNLOAD_FAILED = 4,
}


[AllowDuplicates]
public enum FEEDS_SYNC_SETTING : int32
{
	FSS_DEFAULT = 0,
	FSS_INTERVAL = 1,
	FSS_MANUAL = 2,
	FSS_SUGGESTED = 3,
}


[AllowDuplicates]
public enum FEEDS_DOWNLOAD_ERROR : int32
{
	FDE_NONE = 0,
	FDE_DOWNLOAD_FAILED = 1,
	FDE_INVALID_FEED_FORMAT = 2,
	FDE_NORMALIZATION_FAILED = 3,
	FDE_PERSISTENCE_FAILED = 4,
	FDE_DOWNLOAD_BLOCKED = 5,
	FDE_CANCELED = 6,
	FDE_UNSUPPORTED_AUTH = 7,
	FDE_BACKGROUND_DOWNLOAD_DISABLED = 8,
	FDE_NOT_EXIST = 9,
	FDE_UNSUPPORTED_MSXML = 10,
	FDE_UNSUPPORTED_DTD = 11,
	FDE_DOWNLOAD_SIZE_LIMIT_EXCEEDED = 12,
	FDE_ACCESS_DENIED = 13,
	FDE_AUTH_FAILED = 14,
	FDE_INVALID_AUTH = 15,
}


[AllowDuplicates]
public enum FEEDS_EVENTS_ITEM_COUNT_FLAGS : int32
{
	FEICF_READ_ITEM_COUNT_CHANGED = 1,
	FEICF_UNREAD_ITEM_COUNT_CHANGED = 2,
}


[AllowDuplicates]
public enum FEEDS_ERROR_CODE : int32
{
	FEC_E_ERRORBASE = -1073479168,
	FEC_E_INVALIDMSXMLPROPERTY = -1073479168,
	FEC_E_DOWNLOADSIZELIMITEXCEEDED = -1073479167,
}


[AllowDuplicates]
public enum PlayerState : int32
{
	stop_state = 0,
	pause_state = 1,
	play_state = 2,
}


[AllowDuplicates]
public enum WMPPartnerNotification : int32
{
	wmpsnBackgroundProcessingBegin = 1,
	wmpsnBackgroundProcessingEnd = 2,
	wmpsnCatalogDownloadFailure = 3,
	wmpsnCatalogDownloadComplete = 4,
}


[AllowDuplicates]
public enum WMPCallbackNotification : int32
{
	wmpcnLoginStateChange = 1,
	wmpcnAuthResult = 2,
	wmpcnLicenseUpdated = 3,
	wmpcnNewCatalogAvailable = 4,
	wmpcnNewPluginAvailable = 5,
	wmpcnDisableRadioSkipping = 6,
}


[AllowDuplicates]
public enum WMPTaskType : int32
{
	wmpttBrowse = 1,
	wmpttSync = 2,
	wmpttBurn = 3,
	wmpttCurrent = 4,
}


[AllowDuplicates]
public enum WMPTransactionType : int32
{
	wmpttNoTransaction = 0,
	wmpttDownload = 1,
	wmpttBuy = 2,
}


[AllowDuplicates]
public enum WMPTemplateSize : int32
{
	wmptsSmall = 0,
	wmptsMedium = 1,
	wmptsLarge = 2,
}


[AllowDuplicates]
public enum WMPStreamingType : int32
{
	wmpstUnknown = 0,
	wmpstMusic = 1,
	wmpstVideo = 2,
	wmpstRadio = 3,
}


[AllowDuplicates]
public enum WMPAccountType : int32
{
	wmpatBuyOnly = 1,
	wmpatSubscription = 2,
	wmpatJanus = 3,
}


[AllowDuplicates]
public enum WMPSubscriptionServiceEvent : int32
{
	wmpsseCurrentBegin = 1,
	wmpsseCurrentEnd = 2,
	wmpsseFullBegin = 3,
	wmpsseFullEnd = 4,
}


[AllowDuplicates]
public enum WMPSubscriptionDownloadState : int32
{
	wmpsdlsDownloading = 0,
	wmpsdlsPaused = 1,
	wmpsdlsProcessing = 2,
	wmpsdlsCompleted = 3,
	wmpsdlsCancelled = 4,
}

#endregion


#region Structs
[CRepr]
public struct TimedLevel
{
	public uint8[2048] frequency;
	public uint8[2048] waveform;
	public int32 state;
	public int64 timeStamp;
}

[CRepr]
public struct WMPContextMenuInfo
{
	public uint32 dwID;
	public BSTR bstrMenuText;
	public BSTR bstrHelpText;
}

[CRepr, Packed(1)]
public struct WMP_WMDM_METADATA_ROUND_TRIP_PC2DEVICE
{
	public uint32 dwChangesSinceTransactionID;
	public uint32 dwResultSetStartingIndex;
}

[CRepr, Packed(1)]
public struct WMP_WMDM_METADATA_ROUND_TRIP_DEVICE2PC
{
	public uint32 dwCurrentTransactionID;
	public uint32 dwReturnedObjectCount;
	public uint32 dwUnretrievedObjectCount;
	public uint32 dwDeletedObjectStartingOffset;
	public uint32 dwFlags;
	public char16* wsObjectPathnameList mut => &wsObjectPathnameList_impl;
	private char16[ANYSIZE_ARRAY] wsObjectPathnameList_impl;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WindowsMediaPlayer = .(0x6bf52a52, 0x394a, 0x11d3, 0xb1, 0x53, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);


	public const Guid CLSID_WMPLib = .(0x6bf52a50, 0x394a, 0x11d3, 0xb1, 0x53, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);


	public const Guid CLSID_WMPRemoteMediaServices = .(0xdf333473, 0x2cf7, 0x4be2, 0x90, 0x7f, 0x9a, 0xad, 0x56, 0x61, 0x36, 0x4f);


	public const Guid CLSID_FeedsManager = .(0xfaeb54c4, 0xf66f, 0x4806, 0x83, 0xa0, 0x80, 0x52, 0x99, 0xf5, 0xe3, 0xad);


	public const Guid CLSID_FeedFolderWatcher = .(0x281001ed, 0x7765, 0x4cb0, 0x84, 0xaf, 0xe9, 0xb3, 0x87, 0xaf, 0x01, 0xff);


	public const Guid CLSID_FeedWatcher = .(0x18a6737b, 0xf433, 0x4687, 0x89, 0xbc, 0xa1, 0xb4, 0xdf, 0xb9, 0xf1, 0x23);


}
#endregion

#region COM Types
[CRepr]struct IWMPErrorItem : IDispatch
{
	public new const Guid IID = .(0x3614c646, 0x3b3b, 0x4de7, 0xa8, 0x1e, 0x93, 0x0e, 0x3f, 0x21, 0x27, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* phr) get_errorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_errorDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarContext) get_errorContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRemedy) get_remedy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCustomUrl) get_customUrl;
	}


	public HRESULT get_errorCode(int32* phr) mut => VT.[Friend]get_errorCode(&this, phr);

	public HRESULT get_errorDescription(BSTR* pbstrDescription) mut => VT.[Friend]get_errorDescription(&this, pbstrDescription);

	public HRESULT get_errorContext(VARIANT* pvarContext) mut => VT.[Friend]get_errorContext(&this, pvarContext);

	public HRESULT get_remedy(int32* plRemedy) mut => VT.[Friend]get_remedy(&this, plRemedy);

	public HRESULT get_customUrl(BSTR* pbstrCustomUrl) mut => VT.[Friend]get_customUrl(&this, pbstrCustomUrl);
}

[CRepr]struct IWMPError : IDispatch
{
	public new const Guid IID = .(0xa12dcf7d, 0x14ab, 0x4c1b, 0xa8, 0xcd, 0x63, 0x90, 0x9f, 0x06, 0x02, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) clearErrorQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plNumErrors) get_errorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dwIndex, IWMPErrorItem** ppErrorItem) get_item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) webHelp;
	}


	public HRESULT clearErrorQueue() mut => VT.[Friend]clearErrorQueue(&this);

	public HRESULT get_errorCount(int32* plNumErrors) mut => VT.[Friend]get_errorCount(&this, plNumErrors);

	public HRESULT get_item(int32 dwIndex, IWMPErrorItem** ppErrorItem) mut => VT.[Friend]get_item(&this, dwIndex, ppErrorItem);

	public HRESULT webHelp() mut => VT.[Friend]webHelp(&this);
}

[CRepr]struct IWMPMedia : IDispatch
{
	public new const Guid IID = .(0x94d55e95, 0x3fac, 0x11d3, 0xb1, 0x55, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pIWMPMedia, int16* pvbool) get_isIdentical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSourceURL) get_sourceURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pWidth) get_imageSourceWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pHeight) get_imageSourceHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pMarkerCount) get_markerCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarkerNum, double* pMarkerTime) getMarkerTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 MarkerNum, BSTR* pbstrMarkerName) getMarkerName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pDuration) get_duration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDuration) get_durationString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_attributeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR* pbstrItemName) getAttributeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR* pbstrVal) getItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR bstrVal) setItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lAtom, BSTR* pbstrVal) getItemInfoByAtom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pPlaylist, int16* pvarfIsMemberOf) isMemberOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, int16* pvarfIsReadOnly) isReadOnlyItem;
	}


	public HRESULT get_isIdentical(IWMPMedia* pIWMPMedia, int16* pvbool) mut => VT.[Friend]get_isIdentical(&this, pIWMPMedia, pvbool);

	public HRESULT get_sourceURL(BSTR* pbstrSourceURL) mut => VT.[Friend]get_sourceURL(&this, pbstrSourceURL);

	public HRESULT get_name(BSTR* pbstrName) mut => VT.[Friend]get_name(&this, pbstrName);

	public HRESULT put_name(BSTR bstrName) mut => VT.[Friend]put_name(&this, bstrName);

	public HRESULT get_imageSourceWidth(int32* pWidth) mut => VT.[Friend]get_imageSourceWidth(&this, pWidth);

	public HRESULT get_imageSourceHeight(int32* pHeight) mut => VT.[Friend]get_imageSourceHeight(&this, pHeight);

	public HRESULT get_markerCount(int32* pMarkerCount) mut => VT.[Friend]get_markerCount(&this, pMarkerCount);

	public HRESULT getMarkerTime(int32 MarkerNum, double* pMarkerTime) mut => VT.[Friend]getMarkerTime(&this, MarkerNum, pMarkerTime);

	public HRESULT getMarkerName(int32 MarkerNum, BSTR* pbstrMarkerName) mut => VT.[Friend]getMarkerName(&this, MarkerNum, pbstrMarkerName);

	public HRESULT get_duration(double* pDuration) mut => VT.[Friend]get_duration(&this, pDuration);

	public HRESULT get_durationString(BSTR* pbstrDuration) mut => VT.[Friend]get_durationString(&this, pbstrDuration);

	public HRESULT get_attributeCount(int32* plCount) mut => VT.[Friend]get_attributeCount(&this, plCount);

	public HRESULT getAttributeName(int32 lIndex, BSTR* pbstrItemName) mut => VT.[Friend]getAttributeName(&this, lIndex, pbstrItemName);

	public HRESULT getItemInfo(BSTR bstrItemName, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrItemName, pbstrVal);

	public HRESULT setItemInfo(BSTR bstrItemName, BSTR bstrVal) mut => VT.[Friend]setItemInfo(&this, bstrItemName, bstrVal);

	public HRESULT getItemInfoByAtom(int32 lAtom, BSTR* pbstrVal) mut => VT.[Friend]getItemInfoByAtom(&this, lAtom, pbstrVal);

	public HRESULT isMemberOf(IWMPPlaylist* pPlaylist, int16* pvarfIsMemberOf) mut => VT.[Friend]isMemberOf(&this, pPlaylist, pvarfIsMemberOf);

	public HRESULT isReadOnlyItem(BSTR bstrItemName, int16* pvarfIsReadOnly) mut => VT.[Friend]isReadOnlyItem(&this, bstrItemName, pvarfIsReadOnly);
}

[CRepr]struct IWMPControls : IDispatch
{
	public new const Guid IID = .(0x74c09e02, 0xf828, 0x11d2, 0xa7, 0x4b, 0x00, 0xa0, 0xc9, 0x05, 0xf3, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItem, int16* pIsAvailable) get_isAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) play;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) fastForward;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) fastReverse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdCurrentPosition) get_currentPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dCurrentPosition) put_currentPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCurrentPosition) get_currentPositionString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) previous;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia** ppIWMPMedia) get_currentItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pIWMPMedia) put_currentItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMarker) get_currentMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMarker) put_currentMarker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pIWMPMedia) playItem;
	}


	public HRESULT get_isAvailable(BSTR bstrItem, int16* pIsAvailable) mut => VT.[Friend]get_isAvailable(&this, bstrItem, pIsAvailable);

	public HRESULT play() mut => VT.[Friend]play(&this);

	public HRESULT stop() mut => VT.[Friend]stop(&this);

	public HRESULT pause() mut => VT.[Friend]pause(&this);

	public HRESULT fastForward() mut => VT.[Friend]fastForward(&this);

	public HRESULT fastReverse() mut => VT.[Friend]fastReverse(&this);

	public HRESULT get_currentPosition(double* pdCurrentPosition) mut => VT.[Friend]get_currentPosition(&this, pdCurrentPosition);

	public HRESULT put_currentPosition(double dCurrentPosition) mut => VT.[Friend]put_currentPosition(&this, dCurrentPosition);

	public HRESULT get_currentPositionString(BSTR* pbstrCurrentPosition) mut => VT.[Friend]get_currentPositionString(&this, pbstrCurrentPosition);

	public HRESULT next() mut => VT.[Friend]next(&this);

	public HRESULT previous() mut => VT.[Friend]previous(&this);

	public HRESULT get_currentItem(IWMPMedia** ppIWMPMedia) mut => VT.[Friend]get_currentItem(&this, ppIWMPMedia);

	public HRESULT put_currentItem(IWMPMedia* pIWMPMedia) mut => VT.[Friend]put_currentItem(&this, pIWMPMedia);

	public HRESULT get_currentMarker(int32* plMarker) mut => VT.[Friend]get_currentMarker(&this, plMarker);

	public HRESULT put_currentMarker(int32 lMarker) mut => VT.[Friend]put_currentMarker(&this, lMarker);

	public HRESULT playItem(IWMPMedia* pIWMPMedia) mut => VT.[Friend]playItem(&this, pIWMPMedia);
}

[CRepr]struct IWMPSettings : IDispatch
{
	public new const Guid IID = .(0x9104d1ab, 0x80c9, 0x4fed, 0xab, 0xf0, 0x2e, 0x64, 0x17, 0xa6, 0xdf, 0x14);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItem, int16* pIsAvailable) get_isAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfAutoStart) get_autoStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fAutoStart) put_autoStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrBaseURL) get_baseURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrBaseURL) put_baseURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDefaultFrame) get_defaultFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDefaultFrame) put_defaultFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfInvokeURLs) get_invokeURLs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fInvokeURLs) put_invokeURLs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfMute) get_mute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fMute) put_mute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_playCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCount) put_playCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdRate) get_rate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dRate) put_rate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBalance) get_balance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBalance) put_balance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plVolume) get_volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVolume) put_volume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode, int16* pvarfMode) getMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode, int16 varfMode) setMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnableErrorDialogs) get_enableErrorDialogs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fEnableErrorDialogs) put_enableErrorDialogs;
	}


	public HRESULT get_isAvailable(BSTR bstrItem, int16* pIsAvailable) mut => VT.[Friend]get_isAvailable(&this, bstrItem, pIsAvailable);

	public HRESULT get_autoStart(int16* pfAutoStart) mut => VT.[Friend]get_autoStart(&this, pfAutoStart);

	public HRESULT put_autoStart(int16 fAutoStart) mut => VT.[Friend]put_autoStart(&this, fAutoStart);

	public HRESULT get_baseURL(BSTR* pbstrBaseURL) mut => VT.[Friend]get_baseURL(&this, pbstrBaseURL);

	public HRESULT put_baseURL(BSTR bstrBaseURL) mut => VT.[Friend]put_baseURL(&this, bstrBaseURL);

	public HRESULT get_defaultFrame(BSTR* pbstrDefaultFrame) mut => VT.[Friend]get_defaultFrame(&this, pbstrDefaultFrame);

	public HRESULT put_defaultFrame(BSTR bstrDefaultFrame) mut => VT.[Friend]put_defaultFrame(&this, bstrDefaultFrame);

	public HRESULT get_invokeURLs(int16* pfInvokeURLs) mut => VT.[Friend]get_invokeURLs(&this, pfInvokeURLs);

	public HRESULT put_invokeURLs(int16 fInvokeURLs) mut => VT.[Friend]put_invokeURLs(&this, fInvokeURLs);

	public HRESULT get_mute(int16* pfMute) mut => VT.[Friend]get_mute(&this, pfMute);

	public HRESULT put_mute(int16 fMute) mut => VT.[Friend]put_mute(&this, fMute);

	public HRESULT get_playCount(int32* plCount) mut => VT.[Friend]get_playCount(&this, plCount);

	public HRESULT put_playCount(int32 lCount) mut => VT.[Friend]put_playCount(&this, lCount);

	public HRESULT get_rate(double* pdRate) mut => VT.[Friend]get_rate(&this, pdRate);

	public HRESULT put_rate(double dRate) mut => VT.[Friend]put_rate(&this, dRate);

	public HRESULT get_balance(int32* plBalance) mut => VT.[Friend]get_balance(&this, plBalance);

	public HRESULT put_balance(int32 lBalance) mut => VT.[Friend]put_balance(&this, lBalance);

	public HRESULT get_volume(int32* plVolume) mut => VT.[Friend]get_volume(&this, plVolume);

	public HRESULT put_volume(int32 lVolume) mut => VT.[Friend]put_volume(&this, lVolume);

	public HRESULT getMode(BSTR bstrMode, int16* pvarfMode) mut => VT.[Friend]getMode(&this, bstrMode, pvarfMode);

	public HRESULT setMode(BSTR bstrMode, int16 varfMode) mut => VT.[Friend]setMode(&this, bstrMode, varfMode);

	public HRESULT get_enableErrorDialogs(int16* pfEnableErrorDialogs) mut => VT.[Friend]get_enableErrorDialogs(&this, pfEnableErrorDialogs);

	public HRESULT put_enableErrorDialogs(int16 fEnableErrorDialogs) mut => VT.[Friend]put_enableErrorDialogs(&this, fEnableErrorDialogs);
}

[CRepr]struct IWMPClosedCaption : IDispatch
{
	public new const Guid IID = .(0x4f2df574, 0xc588, 0x11d3, 0x9e, 0xd0, 0x00, 0xc0, 0x4f, 0xb6, 0xe9, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSAMIStyle) get_SAMIStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSAMIStyle) put_SAMIStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSAMILang) get_SAMILang;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSAMILang) put_SAMILang;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSAMIFileName) get_SAMIFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSAMIFileName) put_SAMIFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCaptioningID) get_captioningId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCaptioningID) put_captioningId;
	}


	public HRESULT get_SAMIStyle(BSTR* pbstrSAMIStyle) mut => VT.[Friend]get_SAMIStyle(&this, pbstrSAMIStyle);

	public HRESULT put_SAMIStyle(BSTR bstrSAMIStyle) mut => VT.[Friend]put_SAMIStyle(&this, bstrSAMIStyle);

	public HRESULT get_SAMILang(BSTR* pbstrSAMILang) mut => VT.[Friend]get_SAMILang(&this, pbstrSAMILang);

	public HRESULT put_SAMILang(BSTR bstrSAMILang) mut => VT.[Friend]put_SAMILang(&this, bstrSAMILang);

	public HRESULT get_SAMIFileName(BSTR* pbstrSAMIFileName) mut => VT.[Friend]get_SAMIFileName(&this, pbstrSAMIFileName);

	public HRESULT put_SAMIFileName(BSTR bstrSAMIFileName) mut => VT.[Friend]put_SAMIFileName(&this, bstrSAMIFileName);

	public HRESULT get_captioningId(BSTR* pbstrCaptioningID) mut => VT.[Friend]get_captioningId(&this, pbstrCaptioningID);

	public HRESULT put_captioningId(BSTR bstrCaptioningID) mut => VT.[Friend]put_captioningId(&this, bstrCaptioningID);
}

[CRepr]struct IWMPPlaylist : IDispatch
{
	public new const Guid IID = .(0xd5f0f4f1, 0x130c, 0x11d3, 0xb1, 0x4e, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_attributeCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR* pbstrAttributeName) get_attributeName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IWMPMedia** ppIWMPMedia) get_item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR* pbstrVal) getItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrValue) setItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pIWMPPlaylist, int16* pvbool) get_isIdentical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IWMPMedia* pIWMPMedia) insertItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pIWMPMedia) appendItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pIWMPMedia) removeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndexOld, int32 lIndexNew) moveItem;
	}


	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT get_name(BSTR* pbstrName) mut => VT.[Friend]get_name(&this, pbstrName);

	public HRESULT put_name(BSTR bstrName) mut => VT.[Friend]put_name(&this, bstrName);

	public HRESULT get_attributeCount(int32* plCount) mut => VT.[Friend]get_attributeCount(&this, plCount);

	public HRESULT get_attributeName(int32 lIndex, BSTR* pbstrAttributeName) mut => VT.[Friend]get_attributeName(&this, lIndex, pbstrAttributeName);

	public HRESULT get_item(int32 lIndex, IWMPMedia** ppIWMPMedia) mut => VT.[Friend]get_item(&this, lIndex, ppIWMPMedia);

	public HRESULT getItemInfo(BSTR bstrName, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrName, pbstrVal);

	public HRESULT setItemInfo(BSTR bstrName, BSTR bstrValue) mut => VT.[Friend]setItemInfo(&this, bstrName, bstrValue);

	public HRESULT get_isIdentical(IWMPPlaylist* pIWMPPlaylist, int16* pvbool) mut => VT.[Friend]get_isIdentical(&this, pIWMPPlaylist, pvbool);

	public HRESULT clear() mut => VT.[Friend]clear(&this);

	public HRESULT insertItem(int32 lIndex, IWMPMedia* pIWMPMedia) mut => VT.[Friend]insertItem(&this, lIndex, pIWMPMedia);

	public HRESULT appendItem(IWMPMedia* pIWMPMedia) mut => VT.[Friend]appendItem(&this, pIWMPMedia);

	public HRESULT removeItem(IWMPMedia* pIWMPMedia) mut => VT.[Friend]removeItem(&this, pIWMPMedia);

	public HRESULT moveItem(int32 lIndexOld, int32 lIndexNew) mut => VT.[Friend]moveItem(&this, lIndexOld, lIndexNew);
}

[CRepr]struct IWMPCdrom : IDispatch
{
	public new const Guid IID = .(0xcfab6e98, 0x8730, 0x11d3, 0xb3, 0x88, 0x00, 0xc0, 0x4f, 0x68, 0x57, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDrive) get_driveSpecifier;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist** ppPlaylist) get_playlist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) eject;
	}


	public HRESULT get_driveSpecifier(BSTR* pbstrDrive) mut => VT.[Friend]get_driveSpecifier(&this, pbstrDrive);

	public HRESULT get_playlist(IWMPPlaylist** ppPlaylist) mut => VT.[Friend]get_playlist(&this, ppPlaylist);

	public HRESULT eject() mut => VT.[Friend]eject(&this);
}

[CRepr]struct IWMPCdromCollection : IDispatch
{
	public new const Guid IID = .(0xee4c8fe2, 0x34b2, 0x11d3, 0xa3, 0xbf, 0x00, 0x60, 0x97, 0xc9, 0xb3, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IWMPCdrom** ppItem) item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDriveSpecifier, IWMPCdrom** ppCdrom) getByDriveSpecifier;
	}


	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT item(int32 lIndex, IWMPCdrom** ppItem) mut => VT.[Friend]item(&this, lIndex, ppItem);

	public HRESULT getByDriveSpecifier(BSTR bstrDriveSpecifier, IWMPCdrom** ppCdrom) mut => VT.[Friend]getByDriveSpecifier(&this, bstrDriveSpecifier, ppCdrom);
}

[CRepr]struct IWMPStringCollection : IDispatch
{
	public new const Guid IID = .(0x4a976298, 0x8c0d, 0x11d3, 0xb3, 0x89, 0x00, 0xc0, 0x4f, 0x68, 0x57, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR* pbstrString) item;
	}


	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT item(int32 lIndex, BSTR* pbstrString) mut => VT.[Friend]item(&this, lIndex, pbstrString);
}

[CRepr]struct IWMPMediaCollection : IDispatch
{
	public new const Guid IID = .(0x8363bc22, 0xb4b4, 0x4b19, 0x98, 0x9d, 0x1c, 0xd7, 0x65, 0x74, 0x9d, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrURL, IWMPMedia** ppItem) add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist** ppMediaItems) getAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IWMPPlaylist** ppMediaItems) getByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGenre, IWMPPlaylist** ppMediaItems) getByGenre;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAuthor, IWMPPlaylist** ppMediaItems) getByAuthor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAlbum, IWMPPlaylist** ppMediaItems) getByAlbum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAttribute, BSTR bstrValue, IWMPPlaylist** ppMediaItems) getByAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pItem, int16 varfDeleteFile) remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAttribute, BSTR bstrMediaType, IWMPStringCollection** ppStringCollection) getAttributeStringCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, int32* plAtom) getMediaAtom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pItem, int16 varfIsDeleted) setDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pItem, int16* pvarfIsDeleted) isDeleted;
	}


	public HRESULT add(BSTR bstrURL, IWMPMedia** ppItem) mut => VT.[Friend]add(&this, bstrURL, ppItem);

	public HRESULT getAll(IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getAll(&this, ppMediaItems);

	public HRESULT getByName(BSTR bstrName, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByName(&this, bstrName, ppMediaItems);

	public HRESULT getByGenre(BSTR bstrGenre, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByGenre(&this, bstrGenre, ppMediaItems);

	public HRESULT getByAuthor(BSTR bstrAuthor, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByAuthor(&this, bstrAuthor, ppMediaItems);

	public HRESULT getByAlbum(BSTR bstrAlbum, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByAlbum(&this, bstrAlbum, ppMediaItems);

	public HRESULT getByAttribute(BSTR bstrAttribute, BSTR bstrValue, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByAttribute(&this, bstrAttribute, bstrValue, ppMediaItems);

	public HRESULT remove(IWMPMedia* pItem, int16 varfDeleteFile) mut => VT.[Friend]remove(&this, pItem, varfDeleteFile);

	public HRESULT getAttributeStringCollection(BSTR bstrAttribute, BSTR bstrMediaType, IWMPStringCollection** ppStringCollection) mut => VT.[Friend]getAttributeStringCollection(&this, bstrAttribute, bstrMediaType, ppStringCollection);

	public HRESULT getMediaAtom(BSTR bstrItemName, int32* plAtom) mut => VT.[Friend]getMediaAtom(&this, bstrItemName, plAtom);

	public HRESULT setDeleted(IWMPMedia* pItem, int16 varfIsDeleted) mut => VT.[Friend]setDeleted(&this, pItem, varfIsDeleted);

	public HRESULT isDeleted(IWMPMedia* pItem, int16* pvarfIsDeleted) mut => VT.[Friend]isDeleted(&this, pItem, pvarfIsDeleted);
}

[CRepr]struct IWMPPlaylistArray : IDispatch
{
	public new const Guid IID = .(0x679409c0, 0x99f7, 0x11d3, 0x9f, 0xb7, 0x00, 0x10, 0x5a, 0xa6, 0x20, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IWMPPlaylist** ppItem) item;
	}


	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT item(int32 lIndex, IWMPPlaylist** ppItem) mut => VT.[Friend]item(&this, lIndex, ppItem);
}

[CRepr]struct IWMPPlaylistCollection : IDispatch
{
	public new const Guid IID = .(0x10a13217, 0x23a7, 0x439b, 0xb1, 0xc0, 0xd8, 0x47, 0xc7, 0x9b, 0x77, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IWMPPlaylist** ppItem) newPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylistArray** ppPlaylistArray) getAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, IWMPPlaylistArray** ppPlaylistArray) getByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pItem) remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pItem, int16 varfIsDeleted) setDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pItem, int16* pvarfIsDeleted) isDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pItem, IWMPPlaylist** ppImportedItem) importPlaylist;
	}


	public HRESULT newPlaylist(BSTR bstrName, IWMPPlaylist** ppItem) mut => VT.[Friend]newPlaylist(&this, bstrName, ppItem);

	public HRESULT getAll(IWMPPlaylistArray** ppPlaylistArray) mut => VT.[Friend]getAll(&this, ppPlaylistArray);

	public HRESULT getByName(BSTR bstrName, IWMPPlaylistArray** ppPlaylistArray) mut => VT.[Friend]getByName(&this, bstrName, ppPlaylistArray);

	public HRESULT remove(IWMPPlaylist* pItem) mut => VT.[Friend]remove(&this, pItem);

	public HRESULT setDeleted(IWMPPlaylist* pItem, int16 varfIsDeleted) mut => VT.[Friend]setDeleted(&this, pItem, varfIsDeleted);

	public HRESULT isDeleted(IWMPPlaylist* pItem, int16* pvarfIsDeleted) mut => VT.[Friend]isDeleted(&this, pItem, pvarfIsDeleted);

	public HRESULT importPlaylist(IWMPPlaylist* pItem, IWMPPlaylist** ppImportedItem) mut => VT.[Friend]importPlaylist(&this, pItem, ppImportedItem);
}

[CRepr]struct IWMPNetwork : IDispatch
{
	public new const Guid IID = .(0xec21b779, 0xedef, 0x462d, 0xbb, 0xa4, 0xad, 0x9d, 0xde, 0x2b, 0x29, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBandwidth) get_bandWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plRecoveredPackets) get_recoveredPackets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSourceProtocol) get_sourceProtocol;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plReceivedPackets) get_receivedPackets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLostPackets) get_lostPackets;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plReceptionQuality) get_receptionQuality;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBufferingCount) get_bufferingCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBufferingProgress) get_bufferingProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBufferingTime) get_bufferingTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lBufferingTime) put_bufferingTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFrameRate) get_frameRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBitRate) get_maxBitRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plBitRate) get_bitRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int32* plProxySetting) getProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int32 lProxySetting) setProxySettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR* pbstrProxyName) getProxyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR bstrProxyName) setProxyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int32* lProxyPort) getProxyPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int32 lProxyPort) setProxyPort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR* pbstrExceptionList) getProxyExceptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, BSTR pbstrExceptionList) setProxyExceptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int16* pfBypassForLocal) getProxyBypassForLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProtocol, int16 fBypassForLocal) setProxyBypassForLocal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lMaxBandwidth) get_maxBandwidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lMaxBandwidth) put_maxBandwidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plDownloadProgress) get_downloadProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFrameRate) get_encodedFrameRate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plFrames) get_framesSkipped;
	}


	public HRESULT get_bandWidth(int32* plBandwidth) mut => VT.[Friend]get_bandWidth(&this, plBandwidth);

	public HRESULT get_recoveredPackets(int32* plRecoveredPackets) mut => VT.[Friend]get_recoveredPackets(&this, plRecoveredPackets);

	public HRESULT get_sourceProtocol(BSTR* pbstrSourceProtocol) mut => VT.[Friend]get_sourceProtocol(&this, pbstrSourceProtocol);

	public HRESULT get_receivedPackets(int32* plReceivedPackets) mut => VT.[Friend]get_receivedPackets(&this, plReceivedPackets);

	public HRESULT get_lostPackets(int32* plLostPackets) mut => VT.[Friend]get_lostPackets(&this, plLostPackets);

	public HRESULT get_receptionQuality(int32* plReceptionQuality) mut => VT.[Friend]get_receptionQuality(&this, plReceptionQuality);

	public HRESULT get_bufferingCount(int32* plBufferingCount) mut => VT.[Friend]get_bufferingCount(&this, plBufferingCount);

	public HRESULT get_bufferingProgress(int32* plBufferingProgress) mut => VT.[Friend]get_bufferingProgress(&this, plBufferingProgress);

	public HRESULT get_bufferingTime(int32* plBufferingTime) mut => VT.[Friend]get_bufferingTime(&this, plBufferingTime);

	public HRESULT put_bufferingTime(int32 lBufferingTime) mut => VT.[Friend]put_bufferingTime(&this, lBufferingTime);

	public HRESULT get_frameRate(int32* plFrameRate) mut => VT.[Friend]get_frameRate(&this, plFrameRate);

	public HRESULT get_maxBitRate(int32* plBitRate) mut => VT.[Friend]get_maxBitRate(&this, plBitRate);

	public HRESULT get_bitRate(int32* plBitRate) mut => VT.[Friend]get_bitRate(&this, plBitRate);

	public HRESULT getProxySettings(BSTR bstrProtocol, int32* plProxySetting) mut => VT.[Friend]getProxySettings(&this, bstrProtocol, plProxySetting);

	public HRESULT setProxySettings(BSTR bstrProtocol, int32 lProxySetting) mut => VT.[Friend]setProxySettings(&this, bstrProtocol, lProxySetting);

	public HRESULT getProxyName(BSTR bstrProtocol, BSTR* pbstrProxyName) mut => VT.[Friend]getProxyName(&this, bstrProtocol, pbstrProxyName);

	public HRESULT setProxyName(BSTR bstrProtocol, BSTR bstrProxyName) mut => VT.[Friend]setProxyName(&this, bstrProtocol, bstrProxyName);

	public HRESULT getProxyPort(BSTR bstrProtocol, int32* lProxyPort) mut => VT.[Friend]getProxyPort(&this, bstrProtocol, lProxyPort);

	public HRESULT setProxyPort(BSTR bstrProtocol, int32 lProxyPort) mut => VT.[Friend]setProxyPort(&this, bstrProtocol, lProxyPort);

	public HRESULT getProxyExceptionList(BSTR bstrProtocol, BSTR* pbstrExceptionList) mut => VT.[Friend]getProxyExceptionList(&this, bstrProtocol, pbstrExceptionList);

	public HRESULT setProxyExceptionList(BSTR bstrProtocol, BSTR pbstrExceptionList) mut => VT.[Friend]setProxyExceptionList(&this, bstrProtocol, pbstrExceptionList);

	public HRESULT getProxyBypassForLocal(BSTR bstrProtocol, int16* pfBypassForLocal) mut => VT.[Friend]getProxyBypassForLocal(&this, bstrProtocol, pfBypassForLocal);

	public HRESULT setProxyBypassForLocal(BSTR bstrProtocol, int16 fBypassForLocal) mut => VT.[Friend]setProxyBypassForLocal(&this, bstrProtocol, fBypassForLocal);

	public HRESULT get_maxBandwidth(int32* lMaxBandwidth) mut => VT.[Friend]get_maxBandwidth(&this, lMaxBandwidth);

	public HRESULT put_maxBandwidth(int32 lMaxBandwidth) mut => VT.[Friend]put_maxBandwidth(&this, lMaxBandwidth);

	public HRESULT get_downloadProgress(int32* plDownloadProgress) mut => VT.[Friend]get_downloadProgress(&this, plDownloadProgress);

	public HRESULT get_encodedFrameRate(int32* plFrameRate) mut => VT.[Friend]get_encodedFrameRate(&this, plFrameRate);

	public HRESULT get_framesSkipped(int32* plFrames) mut => VT.[Friend]get_framesSkipped(&this, plFrames);
}

[CRepr]struct IWMPCore : IDispatch
{
	public new const Guid IID = .(0xd84cca99, 0xcce2, 0x11d2, 0x9e, 0xcc, 0x00, 0x00, 0xf8, 0x08, 0x59, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrURL) get_URL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrURL) put_URL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPOpenState* pwmpos) get_openState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPPlayState* pwmpps) get_playState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPControls** ppControl) get_controls;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPSettings** ppSettings) get_settings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia** ppMedia) get_currentMedia;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pMedia) put_currentMedia;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMediaCollection** ppMediaCollection) get_mediaCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylistCollection** ppPlaylistCollection) get_playlistCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrVersionInfo) get_versionInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrURL) launchURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPNetwork** ppQNI) get_network;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist** ppPL) get_currentPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pPL) put_currentPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPCdromCollection** ppCdromCollection) get_cdromCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPClosedCaption** ppClosedCaption) get_closedCaption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfOnline) get_isOnline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPError** ppError) get_error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrStatus) get_status;
	}


	public HRESULT close() mut => VT.[Friend]close(&this);

	public HRESULT get_URL(BSTR* pbstrURL) mut => VT.[Friend]get_URL(&this, pbstrURL);

	public HRESULT put_URL(BSTR bstrURL) mut => VT.[Friend]put_URL(&this, bstrURL);

	public HRESULT get_openState(WMPOpenState* pwmpos) mut => VT.[Friend]get_openState(&this, pwmpos);

	public HRESULT get_playState(WMPPlayState* pwmpps) mut => VT.[Friend]get_playState(&this, pwmpps);

	public HRESULT get_controls(IWMPControls** ppControl) mut => VT.[Friend]get_controls(&this, ppControl);

	public HRESULT get_settings(IWMPSettings** ppSettings) mut => VT.[Friend]get_settings(&this, ppSettings);

	public HRESULT get_currentMedia(IWMPMedia** ppMedia) mut => VT.[Friend]get_currentMedia(&this, ppMedia);

	public HRESULT put_currentMedia(IWMPMedia* pMedia) mut => VT.[Friend]put_currentMedia(&this, pMedia);

	public HRESULT get_mediaCollection(IWMPMediaCollection** ppMediaCollection) mut => VT.[Friend]get_mediaCollection(&this, ppMediaCollection);

	public HRESULT get_playlistCollection(IWMPPlaylistCollection** ppPlaylistCollection) mut => VT.[Friend]get_playlistCollection(&this, ppPlaylistCollection);

	public HRESULT get_versionInfo(BSTR* pbstrVersionInfo) mut => VT.[Friend]get_versionInfo(&this, pbstrVersionInfo);

	public HRESULT launchURL(BSTR bstrURL) mut => VT.[Friend]launchURL(&this, bstrURL);

	public HRESULT get_network(IWMPNetwork** ppQNI) mut => VT.[Friend]get_network(&this, ppQNI);

	public HRESULT get_currentPlaylist(IWMPPlaylist** ppPL) mut => VT.[Friend]get_currentPlaylist(&this, ppPL);

	public HRESULT put_currentPlaylist(IWMPPlaylist* pPL) mut => VT.[Friend]put_currentPlaylist(&this, pPL);

	public HRESULT get_cdromCollection(IWMPCdromCollection** ppCdromCollection) mut => VT.[Friend]get_cdromCollection(&this, ppCdromCollection);

	public HRESULT get_closedCaption(IWMPClosedCaption** ppClosedCaption) mut => VT.[Friend]get_closedCaption(&this, ppClosedCaption);

	public HRESULT get_isOnline(int16* pfOnline) mut => VT.[Friend]get_isOnline(&this, pfOnline);

	public HRESULT get_error(IWMPError** ppError) mut => VT.[Friend]get_error(&this, ppError);

	public HRESULT get_status(BSTR* pbstrStatus) mut => VT.[Friend]get_status(&this, pbstrStatus);
}

[CRepr]struct IWMPPlayer : IWMPCore
{
	public new const Guid IID = .(0x6bf52a4f, 0x394a, 0x11d3, 0xb1, 0x53, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbFullScreen) get_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bFullScreen) put_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnableContextMenu) get_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnableContextMenu) put_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode) put_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMode) get_uiMode;
	}


	public HRESULT get_enabled(int16* pbEnabled) mut => VT.[Friend]get_enabled(&this, pbEnabled);

	public HRESULT put_enabled(int16 bEnabled) mut => VT.[Friend]put_enabled(&this, bEnabled);

	public HRESULT get_fullScreen(int16* pbFullScreen) mut => VT.[Friend]get_fullScreen(&this, pbFullScreen);

	public HRESULT put_fullScreen(int16 bFullScreen) mut => VT.[Friend]put_fullScreen(&this, bFullScreen);

	public HRESULT get_enableContextMenu(int16* pbEnableContextMenu) mut => VT.[Friend]get_enableContextMenu(&this, pbEnableContextMenu);

	public HRESULT put_enableContextMenu(int16 bEnableContextMenu) mut => VT.[Friend]put_enableContextMenu(&this, bEnableContextMenu);

	public HRESULT put_uiMode(BSTR bstrMode) mut => VT.[Friend]put_uiMode(&this, bstrMode);

	public HRESULT get_uiMode(BSTR* pbstrMode) mut => VT.[Friend]get_uiMode(&this, pbstrMode);
}

[CRepr]struct IWMPPlayer2 : IWMPCore
{
	public new const Guid IID = .(0x0e6b01d1, 0xd407, 0x4c85, 0xbf, 0x5f, 0x1c, 0x01, 0xf6, 0x15, 0x02, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbFullScreen) get_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bFullScreen) put_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnableContextMenu) get_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnableContextMenu) put_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode) put_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMode) get_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_windowlessVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_windowlessVideo;
	}


	public HRESULT get_enabled(int16* pbEnabled) mut => VT.[Friend]get_enabled(&this, pbEnabled);

	public HRESULT put_enabled(int16 bEnabled) mut => VT.[Friend]put_enabled(&this, bEnabled);

	public HRESULT get_fullScreen(int16* pbFullScreen) mut => VT.[Friend]get_fullScreen(&this, pbFullScreen);

	public HRESULT put_fullScreen(int16 bFullScreen) mut => VT.[Friend]put_fullScreen(&this, bFullScreen);

	public HRESULT get_enableContextMenu(int16* pbEnableContextMenu) mut => VT.[Friend]get_enableContextMenu(&this, pbEnableContextMenu);

	public HRESULT put_enableContextMenu(int16 bEnableContextMenu) mut => VT.[Friend]put_enableContextMenu(&this, bEnableContextMenu);

	public HRESULT put_uiMode(BSTR bstrMode) mut => VT.[Friend]put_uiMode(&this, bstrMode);

	public HRESULT get_uiMode(BSTR* pbstrMode) mut => VT.[Friend]get_uiMode(&this, pbstrMode);

	public HRESULT get_stretchToFit(int16* pbEnabled) mut => VT.[Friend]get_stretchToFit(&this, pbEnabled);

	public HRESULT put_stretchToFit(int16 bEnabled) mut => VT.[Friend]put_stretchToFit(&this, bEnabled);

	public HRESULT get_windowlessVideo(int16* pbEnabled) mut => VT.[Friend]get_windowlessVideo(&this, pbEnabled);

	public HRESULT put_windowlessVideo(int16 bEnabled) mut => VT.[Friend]put_windowlessVideo(&this, bEnabled);
}

[CRepr]struct IWMPMedia2 : IWMPMedia
{
	public new const Guid IID = .(0xab7c88bb, 0x143e, 0x4ea4, 0xac, 0xc3, 0xe4, 0x35, 0x0b, 0x21, 0x06, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPMedia.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPErrorItem** ppIWMPErrorItem) get_error;
	}


	public HRESULT get_error(IWMPErrorItem** ppIWMPErrorItem) mut => VT.[Friend]get_error(&this, ppIWMPErrorItem);
}

[CRepr]struct IWMPControls2 : IWMPControls
{
	public new const Guid IID = .(0x6f030d25, 0x0890, 0x480f, 0x97, 0x75, 0x1f, 0x7e, 0x40, 0xab, 0x5b, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPControls.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lStep) step;
	}


	public HRESULT step(int32 lStep) mut => VT.[Friend]step(&this, lStep);
}

[CRepr]struct IWMPDVD : IDispatch
{
	public new const Guid IID = .(0x8da61686, 0x4668, 0x4a5c, 0xae, 0x5d, 0x80, 0x31, 0x93, 0x29, 0x3d, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItem, int16* pIsAvailable) get_isAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* strDomain) get_domain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) topMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) titleMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) back;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resume;
	}


	public HRESULT get_isAvailable(BSTR bstrItem, int16* pIsAvailable) mut => VT.[Friend]get_isAvailable(&this, bstrItem, pIsAvailable);

	public HRESULT get_domain(BSTR* strDomain) mut => VT.[Friend]get_domain(&this, strDomain);

	public HRESULT topMenu() mut => VT.[Friend]topMenu(&this);

	public HRESULT titleMenu() mut => VT.[Friend]titleMenu(&this);

	public HRESULT back() mut => VT.[Friend]back(&this);

	public HRESULT resume() mut => VT.[Friend]resume(&this);
}

[CRepr]struct IWMPCore2 : IWMPCore
{
	public new const Guid IID = .(0xbc17e5b7, 0x7561, 0x4c18, 0xbb, 0x90, 0x17, 0xd4, 0x85, 0x77, 0x56, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPDVD** ppDVD) get_dvd;
	}


	public HRESULT get_dvd(IWMPDVD** ppDVD) mut => VT.[Friend]get_dvd(&this, ppDVD);
}

[CRepr]struct IWMPPlayer3 : IWMPCore2
{
	public new const Guid IID = .(0x54062b68, 0x052a, 0x4c25, 0xa3, 0x9f, 0x8b, 0x63, 0x34, 0x65, 0x11, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbFullScreen) get_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bFullScreen) put_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnableContextMenu) get_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnableContextMenu) put_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode) put_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMode) get_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_windowlessVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_windowlessVideo;
	}


	public HRESULT get_enabled(int16* pbEnabled) mut => VT.[Friend]get_enabled(&this, pbEnabled);

	public HRESULT put_enabled(int16 bEnabled) mut => VT.[Friend]put_enabled(&this, bEnabled);

	public HRESULT get_fullScreen(int16* pbFullScreen) mut => VT.[Friend]get_fullScreen(&this, pbFullScreen);

	public HRESULT put_fullScreen(int16 bFullScreen) mut => VT.[Friend]put_fullScreen(&this, bFullScreen);

	public HRESULT get_enableContextMenu(int16* pbEnableContextMenu) mut => VT.[Friend]get_enableContextMenu(&this, pbEnableContextMenu);

	public HRESULT put_enableContextMenu(int16 bEnableContextMenu) mut => VT.[Friend]put_enableContextMenu(&this, bEnableContextMenu);

	public HRESULT put_uiMode(BSTR bstrMode) mut => VT.[Friend]put_uiMode(&this, bstrMode);

	public HRESULT get_uiMode(BSTR* pbstrMode) mut => VT.[Friend]get_uiMode(&this, pbstrMode);

	public HRESULT get_stretchToFit(int16* pbEnabled) mut => VT.[Friend]get_stretchToFit(&this, pbEnabled);

	public HRESULT put_stretchToFit(int16 bEnabled) mut => VT.[Friend]put_stretchToFit(&this, bEnabled);

	public HRESULT get_windowlessVideo(int16* pbEnabled) mut => VT.[Friend]get_windowlessVideo(&this, pbEnabled);

	public HRESULT put_windowlessVideo(int16 bEnabled) mut => VT.[Friend]put_windowlessVideo(&this, bEnabled);
}

[CRepr]struct IWMPErrorItem2 : IWMPErrorItem
{
	public new const Guid IID = .(0xf75ccec0, 0xc67c, 0x475c, 0x93, 0x1e, 0x87, 0x19, 0x87, 0x0b, 0xee, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPErrorItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCondition) get_condition;
	}


	public HRESULT get_condition(int32* plCondition) mut => VT.[Friend]get_condition(&this, plCondition);
}

[CRepr]struct IWMPRemoteMediaServices : IUnknown
{
	public new const Guid IID = .(0xcbb92747, 0x741f, 0x44fe, 0xab, 0x5b, 0xf1, 0xa4, 0x8f, 0x3b, 0x2a, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) GetServiceType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) GetApplicationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName, IDispatch** ppDispatch) GetScriptableObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFile) GetCustomUIMode;
	}


	public HRESULT GetServiceType(BSTR* pbstrType) mut => VT.[Friend]GetServiceType(&this, pbstrType);

	public HRESULT GetApplicationName(BSTR* pbstrName) mut => VT.[Friend]GetApplicationName(&this, pbstrName);

	public HRESULT GetScriptableObject(BSTR* pbstrName, IDispatch** ppDispatch) mut => VT.[Friend]GetScriptableObject(&this, pbstrName, ppDispatch);

	public HRESULT GetCustomUIMode(BSTR* pbstrFile) mut => VT.[Friend]GetCustomUIMode(&this, pbstrFile);
}

[CRepr]struct IWMPSkinManager : IUnknown
{
	public new const Guid IID = .(0x076f2fa6, 0xed30, 0x448b, 0x8c, 0xc5, 0x3f, 0x3e, 0xf3, 0x52, 0x9c, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPath) SetVisualStyle;
	}


	public HRESULT SetVisualStyle(BSTR bstrPath) mut => VT.[Friend]SetVisualStyle(&this, bstrPath);
}

[CRepr]struct IWMPMetadataPicture : IDispatch
{
	public new const Guid IID = .(0x5c29bbe0, 0xf87d, 0x4c45, 0xaa, 0x28, 0xa7, 0x0f, 0x02, 0x30, 0xff, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMimeType) get_mimeType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPictureType) get_pictureType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrURL) get_URL;
	}


	public HRESULT get_mimeType(BSTR* pbstrMimeType) mut => VT.[Friend]get_mimeType(&this, pbstrMimeType);

	public HRESULT get_pictureType(BSTR* pbstrPictureType) mut => VT.[Friend]get_pictureType(&this, pbstrPictureType);

	public HRESULT get_description(BSTR* pbstrDescription) mut => VT.[Friend]get_description(&this, pbstrDescription);

	public HRESULT get_URL(BSTR* pbstrURL) mut => VT.[Friend]get_URL(&this, pbstrURL);
}

[CRepr]struct IWMPMetadataText : IDispatch
{
	public new const Guid IID = .(0x769a72db, 0x13d2, 0x45e2, 0x9c, 0x48, 0x53, 0xca, 0x9d, 0x5b, 0x74, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) get_text;
	}


	public HRESULT get_description(BSTR* pbstrDescription) mut => VT.[Friend]get_description(&this, pbstrDescription);

	public HRESULT get_text(BSTR* pbstrText) mut => VT.[Friend]get_text(&this, pbstrText);
}

[CRepr]struct IWMPMedia3 : IWMPMedia2
{
	public new const Guid IID = .(0xf118efc7, 0xf03a, 0x4fb4, 0x99, 0xc9, 0x1c, 0x02, 0xa5, 0xc1, 0x06, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPMedia2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType, BSTR bstrLanguage, int32* plCount) getAttributeCountByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType, BSTR bstrLanguage, int32 lIndex, VARIANT* pvarValue) getItemInfoByType;
	}


	public HRESULT getAttributeCountByType(BSTR bstrType, BSTR bstrLanguage, int32* plCount) mut => VT.[Friend]getAttributeCountByType(&this, bstrType, bstrLanguage, plCount);

	public HRESULT getItemInfoByType(BSTR bstrType, BSTR bstrLanguage, int32 lIndex, VARIANT* pvarValue) mut => VT.[Friend]getItemInfoByType(&this, bstrType, bstrLanguage, lIndex, pvarValue);
}

[CRepr]struct IWMPSettings2 : IWMPSettings
{
	public new const Guid IID = .(0xfda937a4, 0xeece, 0x4da5, 0xa0, 0xb6, 0x39, 0xbf, 0x89, 0xad, 0xe2, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPSettings.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLangID) get_defaultAudioLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRights) get_mediaAccessRights;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDesiredAccess, int16* pvbAccepted) requestMediaAccessRights;
	}


	public HRESULT get_defaultAudioLanguage(int32* plLangID) mut => VT.[Friend]get_defaultAudioLanguage(&this, plLangID);

	public HRESULT get_mediaAccessRights(BSTR* pbstrRights) mut => VT.[Friend]get_mediaAccessRights(&this, pbstrRights);

	public HRESULT requestMediaAccessRights(BSTR bstrDesiredAccess, int16* pvbAccepted) mut => VT.[Friend]requestMediaAccessRights(&this, bstrDesiredAccess, pvbAccepted);
}

[CRepr]struct IWMPControls3 : IWMPControls2
{
	public new const Guid IID = .(0xa1d1110e, 0xd545, 0x476a, 0x9a, 0x78, 0xac, 0x3e, 0x4c, 0xb1, 0xe6, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPControls2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_audioLanguageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, int32* plLangID) getAudioLanguageID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR* pbstrLangDesc) getAudioLanguageDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLangID) get_currentAudioLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLangID) put_currentAudioLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plIndex) get_currentAudioLanguageIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) put_currentAudioLanguageIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lLangID, BSTR* pbstrLangName) getLanguageName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrTimecode) get_currentPositionTimecode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTimecode) put_currentPositionTimecode;
	}


	public HRESULT get_audioLanguageCount(int32* plCount) mut => VT.[Friend]get_audioLanguageCount(&this, plCount);

	public HRESULT getAudioLanguageID(int32 lIndex, int32* plLangID) mut => VT.[Friend]getAudioLanguageID(&this, lIndex, plLangID);

	public HRESULT getAudioLanguageDescription(int32 lIndex, BSTR* pbstrLangDesc) mut => VT.[Friend]getAudioLanguageDescription(&this, lIndex, pbstrLangDesc);

	public HRESULT get_currentAudioLanguage(int32* plLangID) mut => VT.[Friend]get_currentAudioLanguage(&this, plLangID);

	public HRESULT put_currentAudioLanguage(int32 lLangID) mut => VT.[Friend]put_currentAudioLanguage(&this, lLangID);

	public HRESULT get_currentAudioLanguageIndex(int32* plIndex) mut => VT.[Friend]get_currentAudioLanguageIndex(&this, plIndex);

	public HRESULT put_currentAudioLanguageIndex(int32 lIndex) mut => VT.[Friend]put_currentAudioLanguageIndex(&this, lIndex);

	public HRESULT getLanguageName(int32 lLangID, BSTR* pbstrLangName) mut => VT.[Friend]getLanguageName(&this, lLangID, pbstrLangName);

	public HRESULT get_currentPositionTimecode(BSTR* bstrTimecode) mut => VT.[Friend]get_currentPositionTimecode(&this, bstrTimecode);

	public HRESULT put_currentPositionTimecode(BSTR bstrTimecode) mut => VT.[Friend]put_currentPositionTimecode(&this, bstrTimecode);
}

[CRepr]struct IWMPClosedCaption2 : IWMPClosedCaption
{
	public new const Guid IID = .(0x350ba78b, 0x6bc8, 0x4113, 0xa5, 0xf5, 0x31, 0x20, 0x56, 0x93, 0x4e, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPClosedCaption.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_SAMILangCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex, BSTR* pbstrName) getSAMILangName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex, int32* plLangID) getSAMILangID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_SAMIStyleCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex, BSTR* pbstrName) getSAMIStyleName;
	}


	public HRESULT get_SAMILangCount(int32* plCount) mut => VT.[Friend]get_SAMILangCount(&this, plCount);

	public HRESULT getSAMILangName(int32 nIndex, BSTR* pbstrName) mut => VT.[Friend]getSAMILangName(&this, nIndex, pbstrName);

	public HRESULT getSAMILangID(int32 nIndex, int32* plLangID) mut => VT.[Friend]getSAMILangID(&this, nIndex, plLangID);

	public HRESULT get_SAMIStyleCount(int32* plCount) mut => VT.[Friend]get_SAMIStyleCount(&this, plCount);

	public HRESULT getSAMIStyleName(int32 nIndex, BSTR* pbstrName) mut => VT.[Friend]getSAMIStyleName(&this, nIndex, pbstrName);
}

[CRepr]struct IWMPPlayerApplication : IDispatch
{
	public new const Guid IID = .(0x40897764, 0xceab, 0x47be, 0xad, 0x4a, 0x8e, 0x28, 0x53, 0x7f, 0x9b, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) switchToPlayerApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) switchToControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbPlayerDocked) get_playerDocked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbHasDisplay) get_hasDisplay;
	}


	public HRESULT switchToPlayerApplication() mut => VT.[Friend]switchToPlayerApplication(&this);

	public HRESULT switchToControl() mut => VT.[Friend]switchToControl(&this);

	public HRESULT get_playerDocked(int16* pbPlayerDocked) mut => VT.[Friend]get_playerDocked(&this, pbPlayerDocked);

	public HRESULT get_hasDisplay(int16* pbHasDisplay) mut => VT.[Friend]get_hasDisplay(&this, pbHasDisplay);
}

[CRepr]struct IWMPCore3 : IWMPCore2
{
	public new const Guid IID = .(0x7587c667, 0x628f, 0x499f, 0x88, 0xe7, 0x6a, 0x6f, 0x4e, 0x88, 0x84, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrURL, IWMPPlaylist** ppPlaylist) newPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrURL, IWMPMedia** ppMedia) newMedia;
	}


	public HRESULT newPlaylist(BSTR bstrName, BSTR bstrURL, IWMPPlaylist** ppPlaylist) mut => VT.[Friend]newPlaylist(&this, bstrName, bstrURL, ppPlaylist);

	public HRESULT newMedia(BSTR bstrURL, IWMPMedia** ppMedia) mut => VT.[Friend]newMedia(&this, bstrURL, ppMedia);
}

[CRepr]struct IWMPPlayer4 : IWMPCore3
{
	public new const Guid IID = .(0x6c497d62, 0x8919, 0x413c, 0x82, 0xdb, 0xe9, 0x35, 0xfb, 0x3e, 0xc5, 0x84);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPCore3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbFullScreen) get_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bFullScreen) put_fullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnableContextMenu) get_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnableContextMenu) put_enableContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMode) put_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMode) get_uiMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_stretchToFit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbEnabled) get_windowlessVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bEnabled) put_windowlessVideo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvarfIsRemote) get_isRemote;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlayerApplication** ppIWMPPlayerApplication) get_playerApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrURL) openPlayer;
	}


	public HRESULT get_enabled(int16* pbEnabled) mut => VT.[Friend]get_enabled(&this, pbEnabled);

	public HRESULT put_enabled(int16 bEnabled) mut => VT.[Friend]put_enabled(&this, bEnabled);

	public HRESULT get_fullScreen(int16* pbFullScreen) mut => VT.[Friend]get_fullScreen(&this, pbFullScreen);

	public HRESULT put_fullScreen(int16 bFullScreen) mut => VT.[Friend]put_fullScreen(&this, bFullScreen);

	public HRESULT get_enableContextMenu(int16* pbEnableContextMenu) mut => VT.[Friend]get_enableContextMenu(&this, pbEnableContextMenu);

	public HRESULT put_enableContextMenu(int16 bEnableContextMenu) mut => VT.[Friend]put_enableContextMenu(&this, bEnableContextMenu);

	public HRESULT put_uiMode(BSTR bstrMode) mut => VT.[Friend]put_uiMode(&this, bstrMode);

	public HRESULT get_uiMode(BSTR* pbstrMode) mut => VT.[Friend]get_uiMode(&this, pbstrMode);

	public HRESULT get_stretchToFit(int16* pbEnabled) mut => VT.[Friend]get_stretchToFit(&this, pbEnabled);

	public HRESULT put_stretchToFit(int16 bEnabled) mut => VT.[Friend]put_stretchToFit(&this, bEnabled);

	public HRESULT get_windowlessVideo(int16* pbEnabled) mut => VT.[Friend]get_windowlessVideo(&this, pbEnabled);

	public HRESULT put_windowlessVideo(int16 bEnabled) mut => VT.[Friend]put_windowlessVideo(&this, bEnabled);

	public HRESULT get_isRemote(int16* pvarfIsRemote) mut => VT.[Friend]get_isRemote(&this, pvarfIsRemote);

	public HRESULT get_playerApplication(IWMPPlayerApplication** ppIWMPPlayerApplication) mut => VT.[Friend]get_playerApplication(&this, ppIWMPPlayerApplication);

	public HRESULT openPlayer(BSTR bstrURL) mut => VT.[Friend]openPlayer(&this, bstrURL);
}

[CRepr]struct IWMPPlayerServices : IUnknown
{
	public new const Guid IID = .(0x1d01fbdb, 0xade2, 0x4c8d, 0x98, 0x42, 0xc1, 0x90, 0xb9, 0x5c, 0x33, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPlugin) activateUIPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskPane) setTaskPane;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTaskPane, BSTR bstrURL, BSTR bstrFriendlyName) setTaskPaneURL;
	}


	public HRESULT activateUIPlugin(BSTR bstrPlugin) mut => VT.[Friend]activateUIPlugin(&this, bstrPlugin);

	public HRESULT setTaskPane(BSTR bstrTaskPane) mut => VT.[Friend]setTaskPane(&this, bstrTaskPane);

	public HRESULT setTaskPaneURL(BSTR bstrTaskPane, BSTR bstrURL, BSTR bstrFriendlyName) mut => VT.[Friend]setTaskPaneURL(&this, bstrTaskPane, bstrURL, bstrFriendlyName);
}

[CRepr]struct IWMPSyncDevice : IUnknown
{
	public new const Guid IID = .(0x82a2986c, 0x0293, 0x4fd0, 0xb2, 0x79, 0xb2, 0x1b, 0x86, 0xc0, 0x58, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_friendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName) put_friendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_deviceName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceId) get_deviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plIndex) get_partnershipIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbConnected) get_connected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPDeviceStatus* pwmpds) get_status;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPSyncState* pwmpss) get_syncState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProgress) get_progress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR* pbstrVal) getItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vbShowUI) createPartnership;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) deletePartnership;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) showSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPSyncDevice* pDevice, int16* pvbool) isIdentical;
	}


	public HRESULT get_friendlyName(BSTR* pbstrName) mut => VT.[Friend]get_friendlyName(&this, pbstrName);

	public HRESULT put_friendlyName(BSTR bstrName) mut => VT.[Friend]put_friendlyName(&this, bstrName);

	public HRESULT get_deviceName(BSTR* pbstrName) mut => VT.[Friend]get_deviceName(&this, pbstrName);

	public HRESULT get_deviceId(BSTR* pbstrDeviceId) mut => VT.[Friend]get_deviceId(&this, pbstrDeviceId);

	public HRESULT get_partnershipIndex(int32* plIndex) mut => VT.[Friend]get_partnershipIndex(&this, plIndex);

	public HRESULT get_connected(int16* pvbConnected) mut => VT.[Friend]get_connected(&this, pvbConnected);

	public HRESULT get_status(WMPDeviceStatus* pwmpds) mut => VT.[Friend]get_status(&this, pwmpds);

	public HRESULT get_syncState(WMPSyncState* pwmpss) mut => VT.[Friend]get_syncState(&this, pwmpss);

	public HRESULT get_progress(int32* plProgress) mut => VT.[Friend]get_progress(&this, plProgress);

	public HRESULT getItemInfo(BSTR bstrItemName, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrItemName, pbstrVal);

	public HRESULT createPartnership(int16 vbShowUI) mut => VT.[Friend]createPartnership(&this, vbShowUI);

	public HRESULT deletePartnership() mut => VT.[Friend]deletePartnership(&this);

	public HRESULT start() mut => VT.[Friend]start(&this);

	public HRESULT stop() mut => VT.[Friend]stop(&this);

	public HRESULT showSettings() mut => VT.[Friend]showSettings(&this);

	public HRESULT isIdentical(IWMPSyncDevice* pDevice, int16* pvbool) mut => VT.[Friend]isIdentical(&this, pDevice, pvbool);
}

[CRepr]struct IWMPSyncServices : IUnknown
{
	public new const Guid IID = .(0x8b5050ff, 0xe0a4, 0x4808, 0xb3, 0xa8, 0x89, 0x3a, 0x9e, 0x1e, 0xd8, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_deviceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, IWMPSyncDevice** ppDevice) getDevice;
	}


	public HRESULT get_deviceCount(int32* plCount) mut => VT.[Friend]get_deviceCount(&this, plCount);

	public HRESULT getDevice(int32 lIndex, IWMPSyncDevice** ppDevice) mut => VT.[Friend]getDevice(&this, lIndex, ppDevice);
}

[CRepr]struct IWMPPlayerServices2 : IWMPPlayerServices
{
	public new const Guid IID = .(0x1bb1592f, 0xf040, 0x418a, 0x9f, 0x71, 0x17, 0xc7, 0x51, 0x2b, 0x4d, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPPlayerServices.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPriority) setBackgroundProcessingPriority;
	}


	public HRESULT setBackgroundProcessingPriority(BSTR bstrPriority) mut => VT.[Friend]setBackgroundProcessingPriority(&this, bstrPriority);
}

[CRepr]struct IWMPCdromRip : IUnknown
{
	public new const Guid IID = .(0x56e2294f, 0x69ed, 0x4629, 0xa8, 0x69, 0xae, 0xa7, 0x2c, 0x0d, 0xcc, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPRipState* pwmprs) get_ripState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProgress) get_ripProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) startRip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stopRip;
	}


	public HRESULT get_ripState(WMPRipState* pwmprs) mut => VT.[Friend]get_ripState(&this, pwmprs);

	public HRESULT get_ripProgress(int32* plProgress) mut => VT.[Friend]get_ripProgress(&this, plProgress);

	public HRESULT startRip() mut => VT.[Friend]startRip(&this);

	public HRESULT stopRip() mut => VT.[Friend]stopRip(&this);
}

[CRepr]struct IWMPCdromBurn : IUnknown
{
	public new const Guid IID = .(0xbd94dbeb, 0x417f, 0x4928, 0xaa, 0x06, 0x08, 0x7d, 0x56, 0xed, 0x9b, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItem, int16* pIsAvailable) isAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItem, BSTR* pbstrVal) getItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrLabel) get_label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrLabel) put_label;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPBurnFormat* pwmpbf) get_burnFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPBurnFormat wmpbf) put_burnFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist** ppPlaylist) get_burnPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pPlaylist) put_burnPlaylist;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) refreshStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPBurnState* pwmpbs) get_burnState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProgress) get_burnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) startBurn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stopBurn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) erase;
	}


	public HRESULT isAvailable(BSTR bstrItem, int16* pIsAvailable) mut => VT.[Friend]isAvailable(&this, bstrItem, pIsAvailable);

	public HRESULT getItemInfo(BSTR bstrItem, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrItem, pbstrVal);

	public HRESULT get_label(BSTR* pbstrLabel) mut => VT.[Friend]get_label(&this, pbstrLabel);

	public HRESULT put_label(BSTR bstrLabel) mut => VT.[Friend]put_label(&this, bstrLabel);

	public HRESULT get_burnFormat(WMPBurnFormat* pwmpbf) mut => VT.[Friend]get_burnFormat(&this, pwmpbf);

	public HRESULT put_burnFormat(WMPBurnFormat wmpbf) mut => VT.[Friend]put_burnFormat(&this, wmpbf);

	public HRESULT get_burnPlaylist(IWMPPlaylist** ppPlaylist) mut => VT.[Friend]get_burnPlaylist(&this, ppPlaylist);

	public HRESULT put_burnPlaylist(IWMPPlaylist* pPlaylist) mut => VT.[Friend]put_burnPlaylist(&this, pPlaylist);

	public HRESULT refreshStatus() mut => VT.[Friend]refreshStatus(&this);

	public HRESULT get_burnState(WMPBurnState* pwmpbs) mut => VT.[Friend]get_burnState(&this, pwmpbs);

	public HRESULT get_burnProgress(int32* plProgress) mut => VT.[Friend]get_burnProgress(&this, plProgress);

	public HRESULT startBurn() mut => VT.[Friend]startBurn(&this);

	public HRESULT stopBurn() mut => VT.[Friend]stopBurn(&this);

	public HRESULT erase() mut => VT.[Friend]erase(&this);
}

[CRepr]struct IWMPQuery : IDispatch
{
	public new const Guid IID = .(0xa00918f3, 0xa6b0, 0x4bfb, 0x91, 0x89, 0xfd, 0x83, 0x4c, 0x7b, 0xc5, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAttribute, BSTR bstrOperator, BSTR bstrValue) addCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) beginNextGroup;
	}


	public HRESULT addCondition(BSTR bstrAttribute, BSTR bstrOperator, BSTR bstrValue) mut => VT.[Friend]addCondition(&this, bstrAttribute, bstrOperator, bstrValue);

	public HRESULT beginNextGroup() mut => VT.[Friend]beginNextGroup(&this);
}

[CRepr]struct IWMPMediaCollection2 : IWMPMediaCollection
{
	public new const Guid IID = .(0x8ba957f5, 0xfd8c, 0x4791, 0xb8, 0x2d, 0xf8, 0x40, 0x40, 0x1e, 0xe4, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPMediaCollection.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPQuery** ppQuery) createQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPQuery* pQuery, BSTR bstrMediaType, BSTR bstrSortAttribute, int16 fSortAscending, IWMPPlaylist** ppPlaylist) getPlaylistByQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAttribute, IWMPQuery* pQuery, BSTR bstrMediaType, BSTR bstrSortAttribute, int16 fSortAscending, IWMPStringCollection** ppStringCollection) getStringCollectionByQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrAttribute, BSTR bstrValue, BSTR bstrMediaType, IWMPPlaylist** ppMediaItems) getByAttributeAndMediaType;
	}


	public HRESULT createQuery(IWMPQuery** ppQuery) mut => VT.[Friend]createQuery(&this, ppQuery);

	public HRESULT getPlaylistByQuery(IWMPQuery* pQuery, BSTR bstrMediaType, BSTR bstrSortAttribute, int16 fSortAscending, IWMPPlaylist** ppPlaylist) mut => VT.[Friend]getPlaylistByQuery(&this, pQuery, bstrMediaType, bstrSortAttribute, fSortAscending, ppPlaylist);

	public HRESULT getStringCollectionByQuery(BSTR bstrAttribute, IWMPQuery* pQuery, BSTR bstrMediaType, BSTR bstrSortAttribute, int16 fSortAscending, IWMPStringCollection** ppStringCollection) mut => VT.[Friend]getStringCollectionByQuery(&this, bstrAttribute, pQuery, bstrMediaType, bstrSortAttribute, fSortAscending, ppStringCollection);

	public HRESULT getByAttributeAndMediaType(BSTR bstrAttribute, BSTR bstrValue, BSTR bstrMediaType, IWMPPlaylist** ppMediaItems) mut => VT.[Friend]getByAttributeAndMediaType(&this, bstrAttribute, bstrValue, bstrMediaType, ppMediaItems);
}

[CRepr]struct IWMPStringCollection2 : IWMPStringCollection
{
	public new const Guid IID = .(0x46ad648d, 0x53f1, 0x4a74, 0x92, 0xe2, 0x2a, 0x1b, 0x68, 0xd6, 0x3f, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPStringCollection.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPStringCollection2* pIWMPStringCollection2, int16* pvbool) isIdentical;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCollectionIndex, BSTR bstrItemName, BSTR* pbstrValue) getItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCollectionIndex, BSTR bstrType, BSTR bstrLanguage, int32* plCount) getAttributeCountByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCollectionIndex, BSTR bstrType, BSTR bstrLanguage, int32 lAttributeIndex, VARIANT* pvarValue) getItemInfoByType;
	}


	public HRESULT isIdentical(IWMPStringCollection2* pIWMPStringCollection2, int16* pvbool) mut => VT.[Friend]isIdentical(&this, pIWMPStringCollection2, pvbool);

	public HRESULT getItemInfo(int32 lCollectionIndex, BSTR bstrItemName, BSTR* pbstrValue) mut => VT.[Friend]getItemInfo(&this, lCollectionIndex, bstrItemName, pbstrValue);

	public HRESULT getAttributeCountByType(int32 lCollectionIndex, BSTR bstrType, BSTR bstrLanguage, int32* plCount) mut => VT.[Friend]getAttributeCountByType(&this, lCollectionIndex, bstrType, bstrLanguage, plCount);

	public HRESULT getItemInfoByType(int32 lCollectionIndex, BSTR bstrType, BSTR bstrLanguage, int32 lAttributeIndex, VARIANT* pvarValue) mut => VT.[Friend]getItemInfoByType(&this, lCollectionIndex, bstrType, bstrLanguage, lAttributeIndex, pvarValue);
}

[CRepr]struct IWMPLibrary : IUnknown
{
	public new const Guid IID = .(0x3df47861, 0x7df1, 0x4c1f, 0xa8, 0x1b, 0x4c, 0x26, 0xf0, 0xf7, 0xa7, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) get_name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPLibraryType* pwmplt) get_type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMediaCollection** ppIWMPMediaCollection) get_mediaCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPLibrary* pIWMPLibrary, int16* pvbool) isIdentical;
	}


	public HRESULT get_name(BSTR* pbstrName) mut => VT.[Friend]get_name(&this, pbstrName);

	public HRESULT get_type(WMPLibraryType* pwmplt) mut => VT.[Friend]get_type(&this, pwmplt);

	public HRESULT get_mediaCollection(IWMPMediaCollection** ppIWMPMediaCollection) mut => VT.[Friend]get_mediaCollection(&this, ppIWMPMediaCollection);

	public HRESULT isIdentical(IWMPLibrary* pIWMPLibrary, int16* pvbool) mut => VT.[Friend]isIdentical(&this, pIWMPLibrary, pvbool);
}

[CRepr]struct IWMPLibraryServices : IUnknown
{
	public new const Guid IID = .(0x39c2f8d5, 0x1cf2, 0x4d5e, 0xae, 0x09, 0xd7, 0x34, 0x92, 0xcf, 0x9e, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPLibraryType wmplt, int32* plCount) getCountByType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPLibraryType wmplt, int32 lIndex, IWMPLibrary** ppIWMPLibrary) getLibraryByType;
	}


	public HRESULT getCountByType(WMPLibraryType wmplt, int32* plCount) mut => VT.[Friend]getCountByType(&this, wmplt, plCount);

	public HRESULT getLibraryByType(WMPLibraryType wmplt, int32 lIndex, IWMPLibrary** ppIWMPLibrary) mut => VT.[Friend]getLibraryByType(&this, wmplt, lIndex, ppIWMPLibrary);
}

[CRepr]struct IWMPLibrarySharingServices : IUnknown
{
	public new const Guid IID = .(0x82cba86b, 0x9f04, 0x474b, 0xa3, 0x65, 0xd6, 0xdd, 0x14, 0x66, 0xe5, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbShared) isLibraryShared;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbEnabled) isLibrarySharingEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) showLibrarySharing;
	}


	public HRESULT isLibraryShared(int16* pvbShared) mut => VT.[Friend]isLibraryShared(&this, pvbShared);

	public HRESULT isLibrarySharingEnabled(int16* pvbEnabled) mut => VT.[Friend]isLibrarySharingEnabled(&this, pvbEnabled);

	public HRESULT showLibrarySharing() mut => VT.[Friend]showLibrarySharing(&this);
}

[CRepr]struct IWMPFolderMonitorServices : IUnknown
{
	public new const Guid IID = .(0x788c8743, 0xe57f, 0x439d, 0xa4, 0x68, 0x5b, 0xc7, 0x7f, 0x2e, 0x59, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR* pbstrFolder) item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFolder) add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex) remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPFolderScanState* pwmpfss) get_scanState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFolder) get_currentFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_scannedFilesCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_addedFilesCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProgress) get_updateProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) startScan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stopScan;
	}


	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT item(int32 lIndex, BSTR* pbstrFolder) mut => VT.[Friend]item(&this, lIndex, pbstrFolder);

	public HRESULT add(BSTR bstrFolder) mut => VT.[Friend]add(&this, bstrFolder);

	public HRESULT remove(int32 lIndex) mut => VT.[Friend]remove(&this, lIndex);

	public HRESULT get_scanState(WMPFolderScanState* pwmpfss) mut => VT.[Friend]get_scanState(&this, pwmpfss);

	public HRESULT get_currentFolder(BSTR* pbstrFolder) mut => VT.[Friend]get_currentFolder(&this, pbstrFolder);

	public HRESULT get_scannedFilesCount(int32* plCount) mut => VT.[Friend]get_scannedFilesCount(&this, plCount);

	public HRESULT get_addedFilesCount(int32* plCount) mut => VT.[Friend]get_addedFilesCount(&this, plCount);

	public HRESULT get_updateProgress(int32* plProgress) mut => VT.[Friend]get_updateProgress(&this, plProgress);

	public HRESULT startScan() mut => VT.[Friend]startScan(&this);

	public HRESULT stopScan() mut => VT.[Friend]stopScan(&this);
}

[CRepr]struct IWMPSyncDevice2 : IWMPSyncDevice
{
	public new const Guid IID = .(0x88afb4b2, 0x140a, 0x44d2, 0x91, 0xe6, 0x45, 0x43, 0xda, 0x46, 0x7c, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPSyncDevice.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR bstrVal) setItemInfo;
	}


	public HRESULT setItemInfo(BSTR bstrItemName, BSTR bstrVal) mut => VT.[Friend]setItemInfo(&this, bstrItemName, bstrVal);
}

[CRepr]struct IWMPSyncDevice3 : IWMPSyncDevice2
{
	public new const Guid IID = .(0xb22c85f9, 0x263c, 0x4372, 0xa0, 0xda, 0xb5, 0x18, 0xdb, 0x9b, 0x40, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPSyncDevice2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPPlaylist* pNonRulePlaylist, IWMPPlaylist* pRulesPlaylist) estimateSyncSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) cancelEstimation;
	}


	public HRESULT estimateSyncSize(IWMPPlaylist* pNonRulePlaylist, IWMPPlaylist* pRulesPlaylist) mut => VT.[Friend]estimateSyncSize(&this, pNonRulePlaylist, pRulesPlaylist);

	public HRESULT cancelEstimation() mut => VT.[Friend]cancelEstimation(&this);
}

[CRepr]struct IWMPLibrary2 : IWMPLibrary
{
	public new const Guid IID = .(0xdd578a4e, 0x79b1, 0x426c, 0xbf, 0x8f, 0x3a, 0xdd, 0x90, 0x72, 0x50, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPLibrary.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR* pbstrVal) getItemInfo;
	}


	public HRESULT getItemInfo(BSTR bstrItemName, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrItemName, pbstrVal);
}

[CRepr]struct IWMPEvents : IUnknown
{
	public new const Guid IID = .(0x19a6627b, 0xda9e, 0x47c1, 0xbb, 0x23, 0x00, 0xb5, 0xe6, 0x68, 0x23, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 NewState) OpenStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 NewState) PlayStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 LangID) AudioLanguageChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) StatusChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR scType, BSTR Param) ScriptCommand;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) NewStream;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 Result) Disconnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 Start) Buffering;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Error;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 WarningType, int32 Param, BSTR Description) Warning;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 Result) EndOfStream;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, double oldPosition, double newPosition) PositionChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 MarkerNum) MarkerHit;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 NewDurationUnit) DurationUnitChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int32 CdromNum) CdromMediaChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* Playlist, WMPPlaylistChangeEventType change) PlaylistChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, WMPPlaylistChangeEventType change) CurrentPlaylistChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrItemName) CurrentPlaylistItemAvailable;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* Item) MediaChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrItemName) CurrentMediaItemAvailable;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pdispMedia) CurrentItemChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) MediaCollectionChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrAttribName, BSTR bstrAttribVal) MediaCollectionAttributeStringAdded;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrAttribName, BSTR bstrAttribVal) MediaCollectionAttributeStringRemoved;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrAttribName, BSTR bstrOldAttribVal, BSTR bstrNewAttribVal) MediaCollectionAttributeStringChanged;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PlaylistCollectionChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrPlaylistName) PlaylistCollectionPlaylistAdded;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrPlaylistName) PlaylistCollectionPlaylistRemoved;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR bstrPlaylistName, int16 varfIsDeleted) PlaylistCollectionPlaylistSetAsDeleted;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR ModeName, int16 NewValue) ModeChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pMediaObject) MediaError;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pItem) OpenPlaylistSwitch;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, BSTR strDomain) DomainChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) SwitchedToPlayerApplication;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) SwitchedToControl;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PlayerDockedStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) PlayerReconnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nButton, int16 nShiftState, int32 fX, int32 fY) Click;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nButton, int16 nShiftState, int32 fX, int32 fY) DoubleClick;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nKeyCode, int16 nShiftState) KeyDown;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nKeyAscii) KeyPress;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nKeyCode, int16 nShiftState) KeyUp;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nButton, int16 nShiftState, int32 fX, int32 fY) MouseDown;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nButton, int16 nShiftState, int32 fX, int32 fY) MouseMove;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, int16 nButton, int16 nShiftState, int32 fX, int32 fY) MouseUp;
	}


	public void OpenStateChange(int32 NewState) mut => VT.[Friend]OpenStateChange(&this, NewState);

	public void PlayStateChange(int32 NewState) mut => VT.[Friend]PlayStateChange(&this, NewState);

	public void AudioLanguageChange(int32 LangID) mut => VT.[Friend]AudioLanguageChange(&this, LangID);

	public void StatusChange() mut => VT.[Friend]StatusChange(&this);

	public void ScriptCommand(BSTR scType, BSTR Param) mut => VT.[Friend]ScriptCommand(&this, scType, Param);

	public void NewStream() mut => VT.[Friend]NewStream(&this);

	public void Disconnect(int32 Result) mut => VT.[Friend]Disconnect(&this, Result);

	public void Buffering(int16 Start) mut => VT.[Friend]Buffering(&this, Start);

	public void Error() mut => VT.[Friend]Error(&this);

	public void Warning(int32 WarningType, int32 Param, BSTR Description) mut => VT.[Friend]Warning(&this, WarningType, Param, Description);

	public void EndOfStream(int32 Result) mut => VT.[Friend]EndOfStream(&this, Result);

	public void PositionChange(double oldPosition, double newPosition) mut => VT.[Friend]PositionChange(&this, oldPosition, newPosition);

	public void MarkerHit(int32 MarkerNum) mut => VT.[Friend]MarkerHit(&this, MarkerNum);

	public void DurationUnitChange(int32 NewDurationUnit) mut => VT.[Friend]DurationUnitChange(&this, NewDurationUnit);

	public void CdromMediaChange(int32 CdromNum) mut => VT.[Friend]CdromMediaChange(&this, CdromNum);

	public void PlaylistChange(IDispatch* Playlist, WMPPlaylistChangeEventType change) mut => VT.[Friend]PlaylistChange(&this, Playlist, change);

	public void CurrentPlaylistChange(WMPPlaylistChangeEventType change) mut => VT.[Friend]CurrentPlaylistChange(&this, change);

	public void CurrentPlaylistItemAvailable(BSTR bstrItemName) mut => VT.[Friend]CurrentPlaylistItemAvailable(&this, bstrItemName);

	public void MediaChange(IDispatch* Item) mut => VT.[Friend]MediaChange(&this, Item);

	public void CurrentMediaItemAvailable(BSTR bstrItemName) mut => VT.[Friend]CurrentMediaItemAvailable(&this, bstrItemName);

	public void CurrentItemChange(IDispatch* pdispMedia) mut => VT.[Friend]CurrentItemChange(&this, pdispMedia);

	public void MediaCollectionChange() mut => VT.[Friend]MediaCollectionChange(&this);

	public void MediaCollectionAttributeStringAdded(BSTR bstrAttribName, BSTR bstrAttribVal) mut => VT.[Friend]MediaCollectionAttributeStringAdded(&this, bstrAttribName, bstrAttribVal);

	public void MediaCollectionAttributeStringRemoved(BSTR bstrAttribName, BSTR bstrAttribVal) mut => VT.[Friend]MediaCollectionAttributeStringRemoved(&this, bstrAttribName, bstrAttribVal);

	public void MediaCollectionAttributeStringChanged(BSTR bstrAttribName, BSTR bstrOldAttribVal, BSTR bstrNewAttribVal) mut => VT.[Friend]MediaCollectionAttributeStringChanged(&this, bstrAttribName, bstrOldAttribVal, bstrNewAttribVal);

	public void PlaylistCollectionChange() mut => VT.[Friend]PlaylistCollectionChange(&this);

	public void PlaylistCollectionPlaylistAdded(BSTR bstrPlaylistName) mut => VT.[Friend]PlaylistCollectionPlaylistAdded(&this, bstrPlaylistName);

	public void PlaylistCollectionPlaylistRemoved(BSTR bstrPlaylistName) mut => VT.[Friend]PlaylistCollectionPlaylistRemoved(&this, bstrPlaylistName);

	public void PlaylistCollectionPlaylistSetAsDeleted(BSTR bstrPlaylistName, int16 varfIsDeleted) mut => VT.[Friend]PlaylistCollectionPlaylistSetAsDeleted(&this, bstrPlaylistName, varfIsDeleted);

	public void ModeChange(BSTR ModeName, int16 NewValue) mut => VT.[Friend]ModeChange(&this, ModeName, NewValue);

	public void MediaError(IDispatch* pMediaObject) mut => VT.[Friend]MediaError(&this, pMediaObject);

	public void OpenPlaylistSwitch(IDispatch* pItem) mut => VT.[Friend]OpenPlaylistSwitch(&this, pItem);

	public void DomainChange(BSTR strDomain) mut => VT.[Friend]DomainChange(&this, strDomain);

	public void SwitchedToPlayerApplication() mut => VT.[Friend]SwitchedToPlayerApplication(&this);

	public void SwitchedToControl() mut => VT.[Friend]SwitchedToControl(&this);

	public void PlayerDockedStateChange() mut => VT.[Friend]PlayerDockedStateChange(&this);

	public void PlayerReconnect() mut => VT.[Friend]PlayerReconnect(&this);

	public void Click(int16 nButton, int16 nShiftState, int32 fX, int32 fY) mut => VT.[Friend]Click(&this, nButton, nShiftState, fX, fY);

	public void DoubleClick(int16 nButton, int16 nShiftState, int32 fX, int32 fY) mut => VT.[Friend]DoubleClick(&this, nButton, nShiftState, fX, fY);

	public void KeyDown(int16 nKeyCode, int16 nShiftState) mut => VT.[Friend]KeyDown(&this, nKeyCode, nShiftState);

	public void KeyPress(int16 nKeyAscii) mut => VT.[Friend]KeyPress(&this, nKeyAscii);

	public void KeyUp(int16 nKeyCode, int16 nShiftState) mut => VT.[Friend]KeyUp(&this, nKeyCode, nShiftState);

	public void MouseDown(int16 nButton, int16 nShiftState, int32 fX, int32 fY) mut => VT.[Friend]MouseDown(&this, nButton, nShiftState, fX, fY);

	public void MouseMove(int16 nButton, int16 nShiftState, int32 fX, int32 fY) mut => VT.[Friend]MouseMove(&this, nButton, nShiftState, fX, fY);

	public void MouseUp(int16 nButton, int16 nShiftState, int32 fX, int32 fY) mut => VT.[Friend]MouseUp(&this, nButton, nShiftState, fX, fY);
}

[CRepr]struct IWMPEvents2 : IWMPEvents
{
	public new const Guid IID = .(0x1e7601fa, 0x47ea, 0x4107, 0x9e, 0xa9, 0x90, 0x04, 0xed, 0x96, 0x84, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPEvents.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice) DeviceConnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice) DeviceDisconnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice, WMPDeviceStatus NewStatus) DeviceStatusChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice, WMPSyncState NewState) DeviceSyncStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice, IDispatch* pMedia) DeviceSyncError;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice, HRESULT hrResult) CreatePartnershipComplete;
	}


	public void DeviceConnect(IWMPSyncDevice* pDevice) mut => VT.[Friend]DeviceConnect(&this, pDevice);

	public void DeviceDisconnect(IWMPSyncDevice* pDevice) mut => VT.[Friend]DeviceDisconnect(&this, pDevice);

	public void DeviceStatusChange(IWMPSyncDevice* pDevice, WMPDeviceStatus NewStatus) mut => VT.[Friend]DeviceStatusChange(&this, pDevice, NewStatus);

	public void DeviceSyncStateChange(IWMPSyncDevice* pDevice, WMPSyncState NewState) mut => VT.[Friend]DeviceSyncStateChange(&this, pDevice, NewState);

	public void DeviceSyncError(IWMPSyncDevice* pDevice, IDispatch* pMedia) mut => VT.[Friend]DeviceSyncError(&this, pDevice, pMedia);

	public void CreatePartnershipComplete(IWMPSyncDevice* pDevice, HRESULT hrResult) mut => VT.[Friend]CreatePartnershipComplete(&this, pDevice, hrResult);
}

[CRepr]struct IWMPEvents3 : IWMPEvents2
{
	public new const Guid IID = .(0x1f504270, 0xa66b, 0x4223, 0x8e, 0x96, 0x26, 0xa0, 0x6c, 0x63, 0xd6, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPEvents2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPCdromRip* pCdromRip, WMPRipState wmprs) CdromRipStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPCdromRip* pCdromRip, IDispatch* pMedia) CdromRipMediaError;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPCdromBurn* pCdromBurn, WMPBurnState wmpbs) CdromBurnStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPCdromBurn* pCdromBurn, IDispatch* pMedia) CdromBurnMediaError;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPCdromBurn* pCdromBurn, HRESULT hrError) CdromBurnError;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPLibrary* pLibrary) LibraryConnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPLibrary* pLibrary) LibraryDisconnect;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, WMPFolderScanState wmpfss) FolderScanStateChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pdispStringCollection, WMPStringCollectionChangeEventType change, int32 lCollectionIndex) StringCollectionChange;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pdispMedia) MediaCollectionMediaAdded;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IDispatch* pdispMedia) MediaCollectionMediaRemoved;
	}


	public void CdromRipStateChange(IWMPCdromRip* pCdromRip, WMPRipState wmprs) mut => VT.[Friend]CdromRipStateChange(&this, pCdromRip, wmprs);

	public void CdromRipMediaError(IWMPCdromRip* pCdromRip, IDispatch* pMedia) mut => VT.[Friend]CdromRipMediaError(&this, pCdromRip, pMedia);

	public void CdromBurnStateChange(IWMPCdromBurn* pCdromBurn, WMPBurnState wmpbs) mut => VT.[Friend]CdromBurnStateChange(&this, pCdromBurn, wmpbs);

	public void CdromBurnMediaError(IWMPCdromBurn* pCdromBurn, IDispatch* pMedia) mut => VT.[Friend]CdromBurnMediaError(&this, pCdromBurn, pMedia);

	public void CdromBurnError(IWMPCdromBurn* pCdromBurn, HRESULT hrError) mut => VT.[Friend]CdromBurnError(&this, pCdromBurn, hrError);

	public void LibraryConnect(IWMPLibrary* pLibrary) mut => VT.[Friend]LibraryConnect(&this, pLibrary);

	public void LibraryDisconnect(IWMPLibrary* pLibrary) mut => VT.[Friend]LibraryDisconnect(&this, pLibrary);

	public void FolderScanStateChange(WMPFolderScanState wmpfss) mut => VT.[Friend]FolderScanStateChange(&this, wmpfss);

	public void StringCollectionChange(IDispatch* pdispStringCollection, WMPStringCollectionChangeEventType change, int32 lCollectionIndex) mut => VT.[Friend]StringCollectionChange(&this, pdispStringCollection, change, lCollectionIndex);

	public void MediaCollectionMediaAdded(IDispatch* pdispMedia) mut => VT.[Friend]MediaCollectionMediaAdded(&this, pdispMedia);

	public void MediaCollectionMediaRemoved(IDispatch* pdispMedia) mut => VT.[Friend]MediaCollectionMediaRemoved(&this, pdispMedia);
}

[CRepr]struct IWMPEvents4 : IWMPEvents3
{
	public new const Guid IID = .(0x26dabcfa, 0x306b, 0x404d, 0x9a, 0x6f, 0x63, 0x0a, 0x84, 0x05, 0x04, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPEvents3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IWMPSyncDevice* pDevice, HRESULT hrResult, int64 qwEstimatedUsedSpace, int64 qwEstimatedSpace) DeviceEstimation;
	}


	public void DeviceEstimation(IWMPSyncDevice* pDevice, HRESULT hrResult, int64 qwEstimatedUsedSpace, int64 qwEstimatedSpace) mut => VT.[Friend]DeviceEstimation(&this, pDevice, hrResult, qwEstimatedUsedSpace, qwEstimatedSpace);
}

[CRepr]struct _WMPOCXEvents : IDispatch
{
	public new const Guid IID = .(0x6bf52a51, 0x394a, 0x11d3, 0xb1, 0x53, 0x00, 0xc0, 0x4f, 0x79, 0xfa, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IWMPNodeRealEstate : IUnknown
{
	public new const Guid IID = .(0x42751198, 0x5a50, 0x4460, 0xbc, 0xb4, 0x70, 0x9f, 0x8b, 0xdc, 0x8e, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSize) GetDesiredSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pSrc, RECT* pDest, RECT* pClip) SetRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* pSrc, RECT* pDest, RECT* pClip) GetRects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fWindowless) SetWindowless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfWindowless) GetWindowless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFullScreen) SetFullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfFullScreen) GetFullScreen;
	}


	public HRESULT GetDesiredSize(SIZE* pSize) mut => VT.[Friend]GetDesiredSize(&this, pSize);

	public HRESULT SetRects(RECT* pSrc, RECT* pDest, RECT* pClip) mut => VT.[Friend]SetRects(&this, pSrc, pDest, pClip);

	public HRESULT GetRects(RECT* pSrc, RECT* pDest, RECT* pClip) mut => VT.[Friend]GetRects(&this, pSrc, pDest, pClip);

	public HRESULT SetWindowless(BOOL fWindowless) mut => VT.[Friend]SetWindowless(&this, fWindowless);

	public HRESULT GetWindowless(BOOL* pfWindowless) mut => VT.[Friend]GetWindowless(&this, pfWindowless);

	public HRESULT SetFullScreen(BOOL fFullScreen) mut => VT.[Friend]SetFullScreen(&this, fFullScreen);

	public HRESULT GetFullScreen(BOOL* pfFullScreen) mut => VT.[Friend]GetFullScreen(&this, pfFullScreen);
}

[CRepr]struct IWMPNodeRealEstateHost : IUnknown
{
	public new const Guid IID = .(0x1491087d, 0x2c6b, 0x44c8, 0xb0, 0x19, 0xb3, 0xc9, 0x29, 0xd2, 0xad, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSize) OnDesiredSizeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFullScreen) OnFullScreenTransition;
	}


	public HRESULT OnDesiredSizeChange(SIZE* pSize) mut => VT.[Friend]OnDesiredSizeChange(&this, pSize);

	public HRESULT OnFullScreenTransition(BOOL fFullScreen) mut => VT.[Friend]OnFullScreenTransition(&this, fFullScreen);
}

[CRepr]struct IWMPNodeWindowed : IUnknown
{
	public new const Guid IID = .(0x96740bfa, 0xc56a, 0x45d1, 0xa3, 0xa4, 0x76, 0x29, 0x14, 0xd4, 0xad, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hwnd) SetOwnerWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* phwnd) GetOwnerWindow;
	}


	public HRESULT SetOwnerWindow(int hwnd) mut => VT.[Friend]SetOwnerWindow(&this, hwnd);

	public HRESULT GetOwnerWindow(int* phwnd) mut => VT.[Friend]GetOwnerWindow(&this, phwnd);
}

[CRepr]struct IWMPNodeWindowedHost : IUnknown
{
	public new const Guid IID = .(0xa300415a, 0x54aa, 0x4081, 0xad, 0xbf, 0x3b, 0x13, 0x61, 0x0d, 0x89, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMsg, WPARAM wparam, LPARAM lparam, LRESULT* plRet, BOOL* pfHandled) OnWindowMessageFromRenderer;
	}


	public HRESULT OnWindowMessageFromRenderer(uint32 uMsg, WPARAM wparam, LPARAM lparam, LRESULT* plRet, BOOL* pfHandled) mut => VT.[Friend]OnWindowMessageFromRenderer(&this, uMsg, wparam, lparam, plRet, pfHandled);
}

[CRepr]struct IWMPWindowMessageSink : IUnknown
{
	public new const Guid IID = .(0x3a0daa30, 0x908d, 0x4789, 0xba, 0x87, 0xae, 0xd8, 0x79, 0xb5, 0xc4, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMsg, WPARAM wparam, LPARAM lparam, LRESULT* plRet, BOOL* pfHandled) OnWindowMessage;
	}


	public HRESULT OnWindowMessage(uint32 uMsg, WPARAM wparam, LPARAM lparam, LRESULT* plRet, BOOL* pfHandled) mut => VT.[Friend]OnWindowMessage(&this, uMsg, wparam, lparam, plRet, pfHandled);
}

[CRepr]struct IWMPNodeWindowless : IWMPWindowMessageSink
{
	public new const Guid IID = .(0x9b9199ad, 0x780c, 0x4eda, 0xb8, 0x16, 0x26, 0x1e, 0xba, 0x5d, 0x15, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPWindowMessageSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hdc, RECT* prcDraw) OnDraw;
	}


	public HRESULT OnDraw(int hdc, RECT* prcDraw) mut => VT.[Friend]OnDraw(&this, hdc, prcDraw);
}

[CRepr]struct IWMPNodeWindowlessHost : IUnknown
{
	public new const Guid IID = .(0xbe7017c6, 0xce34, 0x4901, 0x81, 0x06, 0x77, 0x03, 0x81, 0xaa, 0x6e, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc, BOOL fErase) InvalidateRect;
	}


	public HRESULT InvalidateRect(RECT* prc, BOOL fErase) mut => VT.[Friend]InvalidateRect(&this, prc, fErase);
}

[CRepr]struct IWMPVideoRenderConfig : IUnknown
{
	public new const Guid IID = .(0x6d6cf803, 0x1ec0, 0x4c8d, 0xb3, 0xca, 0xf1, 0x8e, 0x27, 0x28, 0x20, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMFActivate* pActivate) put_presenterActivate;
	}


	public HRESULT put_presenterActivate(IMFActivate* pActivate) mut => VT.[Friend]put_presenterActivate(&this, pActivate);
}

[CRepr]struct IWMPAudioRenderConfig : IUnknown
{
	public new const Guid IID = .(0xe79c6349, 0x5997, 0x4ce4, 0x91, 0x7c, 0x22, 0xa3, 0x39, 0x1e, 0xc5, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOutputDevice) get_audioOutputDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOutputDevice) put_audioOutputDevice;
	}


	public HRESULT get_audioOutputDevice(BSTR* pbstrOutputDevice) mut => VT.[Friend]get_audioOutputDevice(&this, pbstrOutputDevice);

	public HRESULT put_audioOutputDevice(BSTR bstrOutputDevice) mut => VT.[Friend]put_audioOutputDevice(&this, bstrOutputDevice);
}

[CRepr]struct IWMPRenderConfig : IUnknown
{
	public new const Guid IID = .(0x959506c1, 0x0314, 0x4ec5, 0x9e, 0x61, 0x85, 0x28, 0xdb, 0x5e, 0x54, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fInProc) put_inProcOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfInProc) get_inProcOnly;
	}


	public HRESULT put_inProcOnly(BOOL fInProc) mut => VT.[Friend]put_inProcOnly(&this, fInProc);

	public HRESULT get_inProcOnly(BOOL* pfInProc) mut => VT.[Friend]get_inProcOnly(&this, pfInProc);
}

[CRepr]struct IWMPServices : IUnknown
{
	public new const Guid IID = .(0xafb6b76b, 0x1e20, 0x4198, 0x83, 0xb3, 0x19, 0x1d, 0xb6, 0xe0, 0xb1, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int64* prt) GetStreamTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPServices_StreamState* pState) GetStreamState;
	}


	public HRESULT GetStreamTime(int64* prt) mut => VT.[Friend]GetStreamTime(&this, prt);

	public HRESULT GetStreamState(WMPServices_StreamState* pState) mut => VT.[Friend]GetStreamState(&this, pState);
}

[CRepr]struct IWMPMediaPluginRegistrar : IUnknown
{
	public new const Guid IID = .(0x68e27045, 0x05bd, 0x40b2, 0x97, 0x20, 0x23, 0x08, 0x8c, 0x78, 0xe3, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszFriendlyName, PWSTR pwszDescription, PWSTR pwszUninstallString, uint32 dwPriority, Guid guidPluginType, Guid clsid, uint32 cMediaTypes, void* pMediaTypes) WMPRegisterPlayerPlugin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidPluginType, Guid clsid) WMPUnRegisterPlayerPlugin;
	}


	public HRESULT WMPRegisterPlayerPlugin(PWSTR pwszFriendlyName, PWSTR pwszDescription, PWSTR pwszUninstallString, uint32 dwPriority, Guid guidPluginType, Guid clsid, uint32 cMediaTypes, void* pMediaTypes) mut => VT.[Friend]WMPRegisterPlayerPlugin(&this, pwszFriendlyName, pwszDescription, pwszUninstallString, dwPriority, guidPluginType, clsid, cMediaTypes, pMediaTypes);

	public HRESULT WMPUnRegisterPlayerPlugin(Guid guidPluginType, Guid clsid) mut => VT.[Friend]WMPUnRegisterPlayerPlugin(&this, guidPluginType, clsid);
}

[CRepr]struct IWMPPlugin : IUnknown
{
	public new const Guid IID = .(0xf1392a70, 0x024c, 0x42bb, 0xa9, 0x98, 0x73, 0xdf, 0xdf, 0xe7, 0xd5, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint dwPlaybackContext) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Shutdown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGUID) GetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetCaps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPServices* pWMPServices) AdviseWMPServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnAdviseWMPServices;
	}


	public HRESULT Init(uint dwPlaybackContext) mut => VT.[Friend]Init(&this, dwPlaybackContext);

	public HRESULT Shutdown() mut => VT.[Friend]Shutdown(&this);

	public HRESULT GetID(Guid* pGUID) mut => VT.[Friend]GetID(&this, pGUID);

	public HRESULT GetCaps(uint32* pdwFlags) mut => VT.[Friend]GetCaps(&this, pdwFlags);

	public HRESULT AdviseWMPServices(IWMPServices* pWMPServices) mut => VT.[Friend]AdviseWMPServices(&this, pWMPServices);

	public HRESULT UnAdviseWMPServices() mut => VT.[Friend]UnAdviseWMPServices(&this);
}

[CRepr]struct IWMPPluginEnable : IUnknown
{
	public new const Guid IID = .(0x5fca444c, 0x7ad1, 0x479d, 0xa4, 0xef, 0x40, 0x56, 0x6a, 0x53, 0x09, 0xd6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) SetEnable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnable) GetEnable;
	}


	public HRESULT SetEnable(BOOL fEnable) mut => VT.[Friend]SetEnable(&this, fEnable);

	public HRESULT GetEnable(BOOL* pfEnable) mut => VT.[Friend]GetEnable(&this, pfEnable);
}

[CRepr]struct IWMPGraphCreation : IUnknown
{
	public new const Guid IID = .(0xbfb377e5, 0xc594, 0x4369, 0xa9, 0x70, 0xde, 0x89, 0x6d, 0x5e, 0xce, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilterGraph, IUnknown* pReserved) GraphCreationPreRender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pFilterGraph) GraphCreationPostRender;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetGraphCreationFlags;
	}


	public HRESULT GraphCreationPreRender(IUnknown* pFilterGraph, IUnknown* pReserved) mut => VT.[Friend]GraphCreationPreRender(&this, pFilterGraph, pReserved);

	public HRESULT GraphCreationPostRender(IUnknown* pFilterGraph) mut => VT.[Friend]GraphCreationPostRender(&this, pFilterGraph);

	public HRESULT GetGraphCreationFlags(uint32* pdwFlags) mut => VT.[Friend]GetGraphCreationFlags(&this, pdwFlags);
}

[CRepr]struct IWMPConvert : IUnknown
{
	public new const Guid IID = .(0xd683162f, 0x57d4, 0x4108, 0x83, 0x73, 0x4a, 0x96, 0x76, 0xd1, 0xc2, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInputFile, BSTR bstrDestinationFolder, BSTR* pbstrOutputFile) ConvertFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrURL) GetErrorURL;
	}


	public HRESULT ConvertFile(BSTR bstrInputFile, BSTR bstrDestinationFolder, BSTR* pbstrOutputFile) mut => VT.[Friend]ConvertFile(&this, bstrInputFile, bstrDestinationFolder, pbstrOutputFile);

	public HRESULT GetErrorURL(BSTR* pbstrURL) mut => VT.[Friend]GetErrorURL(&this, pbstrURL);
}

[CRepr]struct IWMPTranscodePolicy : IUnknown
{
	public new const Guid IID = .(0xb64cbac3, 0x401c, 0x4327, 0xa3, 0xe8, 0xb9, 0xfe, 0xb3, 0xa8, 0xc2, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pvbAllow) allowTranscode;
	}


	public HRESULT allowTranscode(int16* pvbAllow) mut => VT.[Friend]allowTranscode(&this, pvbAllow);
}

[CRepr]struct IWMPUserEventSink : IUnknown
{
	public new const Guid IID = .(0xcfccfa72, 0xc343, 0x48c3, 0xa2, 0xde, 0xb7, 0xa4, 0x40, 0x2e, 0x39, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 EventCode) NotifyUserEvent;
	}


	public HRESULT NotifyUserEvent(int32 EventCode) mut => VT.[Friend]NotifyUserEvent(&this, EventCode);
}

[CRepr]struct IXFeedsManager : IUnknown
{
	public new const Guid IID = .(0x5357e238, 0xfb12, 0x4aca, 0xa9, 0x30, 0xca, 0xb7, 0x83, 0x2b, 0x84, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) RootFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrl, BOOL* pbSubscribed) IsSubscribed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, BOOL* pbFeedExists) ExistsFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, in Guid riid, void** ppv) GetFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrl, in Guid riid, void** ppv) GetFeedByUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, BOOL* pbFolderExists) ExistsFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, in Guid riid, void** ppv) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) DeleteFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) DeleteFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_BACKGROUNDSYNC_ACTION fbsa) BackgroundSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_BACKGROUNDSYNC_STATUS* pfbss) BackgroundSyncStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiInterval) DefaultInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiInterval) SetDefaultInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncSyncAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStreamIn, IStream** ppStreamOut) Normalize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiItemCountLimit) ItemCountLimit;
	}


	public HRESULT RootFolder(in Guid riid, void** ppv) mut => VT.[Friend]RootFolder(&this, riid, ppv);

	public HRESULT IsSubscribed(PWSTR pszUrl, BOOL* pbSubscribed) mut => VT.[Friend]IsSubscribed(&this, pszUrl, pbSubscribed);

	public HRESULT ExistsFeed(PWSTR pszPath, BOOL* pbFeedExists) mut => VT.[Friend]ExistsFeed(&this, pszPath, pbFeedExists);

	public HRESULT GetFeed(PWSTR pszPath, in Guid riid, void** ppv) mut => VT.[Friend]GetFeed(&this, pszPath, riid, ppv);

	public HRESULT GetFeedByUrl(PWSTR pszUrl, in Guid riid, void** ppv) mut => VT.[Friend]GetFeedByUrl(&this, pszUrl, riid, ppv);

	public HRESULT ExistsFolder(PWSTR pszPath, BOOL* pbFolderExists) mut => VT.[Friend]ExistsFolder(&this, pszPath, pbFolderExists);

	public HRESULT GetFolder(PWSTR pszPath, in Guid riid, void** ppv) mut => VT.[Friend]GetFolder(&this, pszPath, riid, ppv);

	public HRESULT DeleteFeed(PWSTR pszPath) mut => VT.[Friend]DeleteFeed(&this, pszPath);

	public HRESULT DeleteFolder(PWSTR pszPath) mut => VT.[Friend]DeleteFolder(&this, pszPath);

	public HRESULT BackgroundSync(FEEDS_BACKGROUNDSYNC_ACTION fbsa) mut => VT.[Friend]BackgroundSync(&this, fbsa);

	public HRESULT BackgroundSyncStatus(FEEDS_BACKGROUNDSYNC_STATUS* pfbss) mut => VT.[Friend]BackgroundSyncStatus(&this, pfbss);

	public HRESULT DefaultInterval(uint32* puiInterval) mut => VT.[Friend]DefaultInterval(&this, puiInterval);

	public HRESULT SetDefaultInterval(uint32 uiInterval) mut => VT.[Friend]SetDefaultInterval(&this, uiInterval);

	public HRESULT AsyncSyncAll() mut => VT.[Friend]AsyncSyncAll(&this);

	public HRESULT Normalize(IStream* pStreamIn, IStream** ppStreamOut) mut => VT.[Friend]Normalize(&this, pStreamIn, ppStreamOut);

	public HRESULT ItemCountLimit(uint32* puiItemCountLimit) mut => VT.[Friend]ItemCountLimit(&this, puiItemCountLimit);
}

[CRepr]struct IXFeedsEnum : IUnknown
{
	public new const Guid IID = .(0xdc43a9d5, 0x5015, 0x4301, 0x8c, 0x96, 0xa4, 0x74, 0x34, 0xb4, 0xd6, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiCount) Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiIndex, in Guid riid, void** ppv) Item;
	}


	public HRESULT Count(uint32* puiCount) mut => VT.[Friend]Count(&this, puiCount);

	public HRESULT Item(uint32 uiIndex, in Guid riid, void** ppv) mut => VT.[Friend]Item(&this, uiIndex, riid, ppv);
}

[CRepr]struct IXFeedFolder : IUnknown
{
	public new const Guid IID = .(0x4c963678, 0x3a51, 0x4b88, 0x85, 0x31, 0x98, 0xb9, 0x0b, 0x65, 0x08, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXFeedsEnum** ppfe) Feeds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXFeedsEnum** ppfe) Subfolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PWSTR pszUrl, in Guid riid, void** ppv) CreateFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, in Guid riid, void** ppv) CreateSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, BOOL* pbFeedExists) ExistsFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, BOOL* pbSubfolderExists) ExistsSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, in Guid riid, void** ppv) GetFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, in Guid riid, void** ppv) GetSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsRootFeedFolder) IsRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, in Guid riid, void** ppv) GetWatcher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiTotalUnreadItemCount) TotalUnreadItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiTotalItemCount) TotalItemCount;
	}


	public HRESULT Feeds(IXFeedsEnum** ppfe) mut => VT.[Friend]Feeds(&this, ppfe);

	public HRESULT Subfolders(IXFeedsEnum** ppfe) mut => VT.[Friend]Subfolders(&this, ppfe);

	public HRESULT CreateFeed(PWSTR pszName, PWSTR pszUrl, in Guid riid, void** ppv) mut => VT.[Friend]CreateFeed(&this, pszName, pszUrl, riid, ppv);

	public HRESULT CreateSubfolder(PWSTR pszName, in Guid riid, void** ppv) mut => VT.[Friend]CreateSubfolder(&this, pszName, riid, ppv);

	public HRESULT ExistsFeed(PWSTR pszName, BOOL* pbFeedExists) mut => VT.[Friend]ExistsFeed(&this, pszName, pbFeedExists);

	public HRESULT ExistsSubfolder(PWSTR pszName, BOOL* pbSubfolderExists) mut => VT.[Friend]ExistsSubfolder(&this, pszName, pbSubfolderExists);

	public HRESULT GetFeed(PWSTR pszName, in Guid riid, void** ppv) mut => VT.[Friend]GetFeed(&this, pszName, riid, ppv);

	public HRESULT GetSubfolder(PWSTR pszName, in Guid riid, void** ppv) mut => VT.[Friend]GetSubfolder(&this, pszName, riid, ppv);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Name(PWSTR* ppszName) mut => VT.[Friend]Name(&this, ppszName);

	public HRESULT Rename(PWSTR pszName) mut => VT.[Friend]Rename(&this, pszName);

	public HRESULT Path(PWSTR* ppszPath) mut => VT.[Friend]Path(&this, ppszPath);

	public HRESULT Move(PWSTR pszPath) mut => VT.[Friend]Move(&this, pszPath);

	public HRESULT Parent(in Guid riid, void** ppv) mut => VT.[Friend]Parent(&this, riid, ppv);

	public HRESULT IsRoot(BOOL* pbIsRootFeedFolder) mut => VT.[Friend]IsRoot(&this, pbIsRootFeedFolder);

	public HRESULT GetWatcher(FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, in Guid riid, void** ppv) mut => VT.[Friend]GetWatcher(&this, @scope, mask, riid, ppv);

	public HRESULT TotalUnreadItemCount(uint32* puiTotalUnreadItemCount) mut => VT.[Friend]TotalUnreadItemCount(&this, puiTotalUnreadItemCount);

	public HRESULT TotalItemCount(uint32* puiTotalItemCount) mut => VT.[Friend]TotalItemCount(&this, puiTotalItemCount);
}

[CRepr]struct IXFeedFolderEvents : IUnknown
{
	public new const Guid IID = .(0x7964b769, 0x234a, 0x4bb1, 0xa5, 0xf4, 0x90, 0x45, 0x4c, 0x8a, 0xd0, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FolderAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FolderDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FolderRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FolderMovedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FolderMovedTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, int32 feicfFlags) FolderItemCountChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FeedRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedUrlChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FeedMovedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FeedMovedTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedDownloading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, FEEDS_DOWNLOAD_ERROR fde) FeedDownloadCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, int32 feicfFlags) FeedItemCountChanged;
	}


	public HRESULT Error() mut => VT.[Friend]Error(&this);

	public HRESULT FolderAdded(PWSTR pszPath) mut => VT.[Friend]FolderAdded(&this, pszPath);

	public HRESULT FolderDeleted(PWSTR pszPath) mut => VT.[Friend]FolderDeleted(&this, pszPath);

	public HRESULT FolderRenamed(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FolderRenamed(&this, pszPath, pszOldPath);

	public HRESULT FolderMovedFrom(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FolderMovedFrom(&this, pszPath, pszOldPath);

	public HRESULT FolderMovedTo(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FolderMovedTo(&this, pszPath, pszOldPath);

	public HRESULT FolderItemCountChanged(PWSTR pszPath, int32 feicfFlags) mut => VT.[Friend]FolderItemCountChanged(&this, pszPath, feicfFlags);

	public HRESULT FeedAdded(PWSTR pszPath) mut => VT.[Friend]FeedAdded(&this, pszPath);

	public HRESULT FeedDeleted(PWSTR pszPath) mut => VT.[Friend]FeedDeleted(&this, pszPath);

	public HRESULT FeedRenamed(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FeedRenamed(&this, pszPath, pszOldPath);

	public HRESULT FeedUrlChanged(PWSTR pszPath) mut => VT.[Friend]FeedUrlChanged(&this, pszPath);

	public HRESULT FeedMovedFrom(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FeedMovedFrom(&this, pszPath, pszOldPath);

	public HRESULT FeedMovedTo(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FeedMovedTo(&this, pszPath, pszOldPath);

	public HRESULT FeedDownloading(PWSTR pszPath) mut => VT.[Friend]FeedDownloading(&this, pszPath);

	public HRESULT FeedDownloadCompleted(PWSTR pszPath, FEEDS_DOWNLOAD_ERROR fde) mut => VT.[Friend]FeedDownloadCompleted(&this, pszPath, fde);

	public HRESULT FeedItemCountChanged(PWSTR pszPath, int32 feicfFlags) mut => VT.[Friend]FeedItemCountChanged(&this, pszPath, feicfFlags);
}

[CRepr]struct IXFeed : IUnknown
{
	public new const Guid IID = .(0xa44179a4, 0xe0f6, 0x403b, 0xaf, 0x8d, 0xd0, 0x80, 0xf4, 0x25, 0xa4, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiItemCount, FEEDS_XML_SORT_PROPERTY sortProperty, FEEDS_XML_SORT_ORDER sortOrder, FEEDS_XML_FILTER_FLAGS filterFlags, FEEDS_XML_INCLUDE_FLAGS includeFlags, IStream** pps) Xml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrl) SetUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) LocalId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastWriteTime) LastWriteTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Download;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelAsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_SYNC_SETTING* pfss) SyncSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_SYNC_SETTING fss) SetSyncSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiInterval) Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiInterval) SetInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastDownloadTime) LastDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) LocalEnclosurePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IXFeedsEnum** ppfe) Items;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiId, in Guid riid, void** ppv) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MarkAllItemsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiMaxItemCount) MaxItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiMaxItemCount) SetMaxItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbDownloadEnclosuresAutomatically) DownloadEnclosuresAutomatically;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bDownloadEnclosuresAutomatically) SetDownloadEnclosuresAutomatically;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_STATUS* pfds) DownloadStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_ERROR* pfde) LastDownloadError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, PWSTR pszUrl) Merge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTitle) Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDescription) Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszHomePage) Link;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszImageUrl) Image;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastBuildDate) LastBuildDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstPubDate) PubDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiTtl) Ttl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszLanguage) Language;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszCopyright) Copyright;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsList) IsList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, in Guid riid, void** ppv) GetWatcher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiUnreadItemCount) UnreadItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiItemCount) ItemCount;
	}


	public HRESULT Xml(uint32 uiItemCount, FEEDS_XML_SORT_PROPERTY sortProperty, FEEDS_XML_SORT_ORDER sortOrder, FEEDS_XML_FILTER_FLAGS filterFlags, FEEDS_XML_INCLUDE_FLAGS includeFlags, IStream** pps) mut => VT.[Friend]Xml(&this, uiItemCount, sortProperty, sortOrder, filterFlags, includeFlags, pps);

	public HRESULT Name(PWSTR* ppszName) mut => VT.[Friend]Name(&this, ppszName);

	public HRESULT Rename(PWSTR pszName) mut => VT.[Friend]Rename(&this, pszName);

	public HRESULT Url(PWSTR* ppszUrl) mut => VT.[Friend]Url(&this, ppszUrl);

	public HRESULT SetUrl(PWSTR pszUrl) mut => VT.[Friend]SetUrl(&this, pszUrl);

	public HRESULT LocalId(Guid* pguid) mut => VT.[Friend]LocalId(&this, pguid);

	public HRESULT Path(PWSTR* ppszPath) mut => VT.[Friend]Path(&this, ppszPath);

	public HRESULT Move(PWSTR pszPath) mut => VT.[Friend]Move(&this, pszPath);

	public HRESULT Parent(in Guid riid, void** ppv) mut => VT.[Friend]Parent(&this, riid, ppv);

	public HRESULT LastWriteTime(SYSTEMTIME* pstLastWriteTime) mut => VT.[Friend]LastWriteTime(&this, pstLastWriteTime);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Download() mut => VT.[Friend]Download(&this);

	public HRESULT AsyncDownload() mut => VT.[Friend]AsyncDownload(&this);

	public HRESULT CancelAsyncDownload() mut => VT.[Friend]CancelAsyncDownload(&this);

	public HRESULT SyncSetting(FEEDS_SYNC_SETTING* pfss) mut => VT.[Friend]SyncSetting(&this, pfss);

	public HRESULT SetSyncSetting(FEEDS_SYNC_SETTING fss) mut => VT.[Friend]SetSyncSetting(&this, fss);

	public HRESULT Interval(uint32* puiInterval) mut => VT.[Friend]Interval(&this, puiInterval);

	public HRESULT SetInterval(uint32 uiInterval) mut => VT.[Friend]SetInterval(&this, uiInterval);

	public HRESULT LastDownloadTime(SYSTEMTIME* pstLastDownloadTime) mut => VT.[Friend]LastDownloadTime(&this, pstLastDownloadTime);

	public HRESULT LocalEnclosurePath(PWSTR* ppszPath) mut => VT.[Friend]LocalEnclosurePath(&this, ppszPath);

	public HRESULT Items(IXFeedsEnum** ppfe) mut => VT.[Friend]Items(&this, ppfe);

	public HRESULT GetItem(uint32 uiId, in Guid riid, void** ppv) mut => VT.[Friend]GetItem(&this, uiId, riid, ppv);

	public HRESULT MarkAllItemsRead() mut => VT.[Friend]MarkAllItemsRead(&this);

	public HRESULT MaxItemCount(uint32* puiMaxItemCount) mut => VT.[Friend]MaxItemCount(&this, puiMaxItemCount);

	public HRESULT SetMaxItemCount(uint32 uiMaxItemCount) mut => VT.[Friend]SetMaxItemCount(&this, uiMaxItemCount);

	public HRESULT DownloadEnclosuresAutomatically(BOOL* pbDownloadEnclosuresAutomatically) mut => VT.[Friend]DownloadEnclosuresAutomatically(&this, pbDownloadEnclosuresAutomatically);

	public HRESULT SetDownloadEnclosuresAutomatically(BOOL bDownloadEnclosuresAutomatically) mut => VT.[Friend]SetDownloadEnclosuresAutomatically(&this, bDownloadEnclosuresAutomatically);

	public HRESULT DownloadStatus(FEEDS_DOWNLOAD_STATUS* pfds) mut => VT.[Friend]DownloadStatus(&this, pfds);

	public HRESULT LastDownloadError(FEEDS_DOWNLOAD_ERROR* pfde) mut => VT.[Friend]LastDownloadError(&this, pfde);

	public HRESULT Merge(IStream* pStream, PWSTR pszUrl) mut => VT.[Friend]Merge(&this, pStream, pszUrl);

	public HRESULT DownloadUrl(PWSTR* ppszUrl) mut => VT.[Friend]DownloadUrl(&this, ppszUrl);

	public HRESULT Title(PWSTR* ppszTitle) mut => VT.[Friend]Title(&this, ppszTitle);

	public HRESULT Description(PWSTR* ppszDescription) mut => VT.[Friend]Description(&this, ppszDescription);

	public HRESULT Link(PWSTR* ppszHomePage) mut => VT.[Friend]Link(&this, ppszHomePage);

	public HRESULT Image(PWSTR* ppszImageUrl) mut => VT.[Friend]Image(&this, ppszImageUrl);

	public HRESULT LastBuildDate(SYSTEMTIME* pstLastBuildDate) mut => VT.[Friend]LastBuildDate(&this, pstLastBuildDate);

	public HRESULT PubDate(SYSTEMTIME* pstPubDate) mut => VT.[Friend]PubDate(&this, pstPubDate);

	public HRESULT Ttl(uint32* puiTtl) mut => VT.[Friend]Ttl(&this, puiTtl);

	public HRESULT Language(PWSTR* ppszLanguage) mut => VT.[Friend]Language(&this, ppszLanguage);

	public HRESULT Copyright(PWSTR* ppszCopyright) mut => VT.[Friend]Copyright(&this, ppszCopyright);

	public HRESULT IsList(BOOL* pbIsList) mut => VT.[Friend]IsList(&this, pbIsList);

	public HRESULT GetWatcher(FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, in Guid riid, void** ppv) mut => VT.[Friend]GetWatcher(&this, @scope, mask, riid, ppv);

	public HRESULT UnreadItemCount(uint32* puiUnreadItemCount) mut => VT.[Friend]UnreadItemCount(&this, puiUnreadItemCount);

	public HRESULT ItemCount(uint32* puiItemCount) mut => VT.[Friend]ItemCount(&this, puiItemCount);
}

[CRepr]struct IXFeed2 : IXFeed
{
	public new const Guid IID = .(0xce528e77, 0x3716, 0x4eb7, 0x95, 0x6d, 0xf5, 0xe3, 0x75, 0x02, 0xe1, 0x2a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXFeed.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiEffectiveId, in Guid riid, void** ppv) GetItemByEffectiveId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastItemDownloadTime) LastItemDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUsername) Username;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPassword) Password;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUsername, PWSTR pszPassword) SetCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearCredentials;
	}


	public HRESULT GetItemByEffectiveId(uint32 uiEffectiveId, in Guid riid, void** ppv) mut => VT.[Friend]GetItemByEffectiveId(&this, uiEffectiveId, riid, ppv);

	public HRESULT LastItemDownloadTime(SYSTEMTIME* pstLastItemDownloadTime) mut => VT.[Friend]LastItemDownloadTime(&this, pstLastItemDownloadTime);

	public HRESULT Username(PWSTR* ppszUsername) mut => VT.[Friend]Username(&this, ppszUsername);

	public HRESULT Password(PWSTR* ppszPassword) mut => VT.[Friend]Password(&this, ppszPassword);

	public HRESULT SetCredentials(PWSTR pszUsername, PWSTR pszPassword) mut => VT.[Friend]SetCredentials(&this, pszUsername, pszPassword);

	public HRESULT ClearCredentials() mut => VT.[Friend]ClearCredentials(&this);
}

[CRepr]struct IXFeedEvents : IUnknown
{
	public new const Guid IID = .(0x1630852e, 0x1263, 0x465b, 0x98, 0xe5, 0xfe, 0x60, 0xff, 0xec, 0x4a, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FeedRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedUrlChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, PWSTR pszOldPath) FeedMoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath) FeedDownloading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, FEEDS_DOWNLOAD_ERROR fde) FeedDownloadCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, int32 feicfFlags) FeedItemCountChanged;
	}


	public HRESULT Error() mut => VT.[Friend]Error(&this);

	public HRESULT FeedDeleted(PWSTR pszPath) mut => VT.[Friend]FeedDeleted(&this, pszPath);

	public HRESULT FeedRenamed(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FeedRenamed(&this, pszPath, pszOldPath);

	public HRESULT FeedUrlChanged(PWSTR pszPath) mut => VT.[Friend]FeedUrlChanged(&this, pszPath);

	public HRESULT FeedMoved(PWSTR pszPath, PWSTR pszOldPath) mut => VT.[Friend]FeedMoved(&this, pszPath, pszOldPath);

	public HRESULT FeedDownloading(PWSTR pszPath) mut => VT.[Friend]FeedDownloading(&this, pszPath);

	public HRESULT FeedDownloadCompleted(PWSTR pszPath, FEEDS_DOWNLOAD_ERROR fde) mut => VT.[Friend]FeedDownloadCompleted(&this, pszPath, fde);

	public HRESULT FeedItemCountChanged(PWSTR pszPath, int32 feicfFlags) mut => VT.[Friend]FeedItemCountChanged(&this, pszPath, feicfFlags);
}

[CRepr]struct IXFeedItem : IUnknown
{
	public new const Guid IID = .(0xe757b2f5, 0xe73e, 0x434e, 0xa1, 0xbf, 0x2b, 0xd7, 0xc3, 0xe6, 0x0f, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_XML_INCLUDE_FLAGS fxif, IStream** pps) Xml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTitle) Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) Link;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszGuid) Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDescription) Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstPubDate) PubDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) Comments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszAuthor) Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Enclosure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbIsRead) IsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bIsRead) SetIsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiId) LocalId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstLastDownloadTime) LastDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstModifiedTime) Modified;
	}


	public HRESULT Xml(FEEDS_XML_INCLUDE_FLAGS fxif, IStream** pps) mut => VT.[Friend]Xml(&this, fxif, pps);

	public HRESULT Title(PWSTR* ppszTitle) mut => VT.[Friend]Title(&this, ppszTitle);

	public HRESULT Link(PWSTR* ppszUrl) mut => VT.[Friend]Link(&this, ppszUrl);

	public HRESULT Guid(PWSTR* ppszGuid) mut => VT.[Friend]Guid(&this, ppszGuid);

	public HRESULT Description(PWSTR* ppszDescription) mut => VT.[Friend]Description(&this, ppszDescription);

	public HRESULT PubDate(SYSTEMTIME* pstPubDate) mut => VT.[Friend]PubDate(&this, pstPubDate);

	public HRESULT Comments(PWSTR* ppszUrl) mut => VT.[Friend]Comments(&this, ppszUrl);

	public HRESULT Author(PWSTR* ppszAuthor) mut => VT.[Friend]Author(&this, ppszAuthor);

	public HRESULT Enclosure(in Guid riid, void** ppv) mut => VT.[Friend]Enclosure(&this, riid, ppv);

	public HRESULT IsRead(BOOL* pbIsRead) mut => VT.[Friend]IsRead(&this, pbIsRead);

	public HRESULT SetIsRead(BOOL bIsRead) mut => VT.[Friend]SetIsRead(&this, bIsRead);

	public HRESULT LocalId(uint32* puiId) mut => VT.[Friend]LocalId(&this, puiId);

	public HRESULT Parent(in Guid riid, void** ppv) mut => VT.[Friend]Parent(&this, riid, ppv);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT DownloadUrl(PWSTR* ppszUrl) mut => VT.[Friend]DownloadUrl(&this, ppszUrl);

	public HRESULT LastDownloadTime(SYSTEMTIME* pstLastDownloadTime) mut => VT.[Friend]LastDownloadTime(&this, pstLastDownloadTime);

	public HRESULT Modified(SYSTEMTIME* pstModifiedTime) mut => VT.[Friend]Modified(&this, pstModifiedTime);
}

[CRepr]struct IXFeedItem2 : IXFeedItem
{
	public new const Guid IID = .(0x6cda2dc7, 0x9013, 0x4522, 0x99, 0x70, 0x2a, 0x9d, 0xd9, 0xea, 0xd5, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IXFeedItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiEffectiveId) EffectiveId;
	}


	public HRESULT EffectiveId(uint32* puiEffectiveId) mut => VT.[Friend]EffectiveId(&this, puiEffectiveId);
}

[CRepr]struct IXFeedEnclosure : IUnknown
{
	public new const Guid IID = .(0xbfbfb953, 0x644f, 0x4792, 0xb6, 0x9c, 0xdf, 0xac, 0xa4, 0xcb, 0xf8, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszMimeType) Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiLength) Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelAsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_STATUS* pfds) DownloadStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_ERROR* pfde) LastDownloadError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath) LocalPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszUrl) DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszMimeType) DownloadMimeType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDownloadUrl, PWSTR pszDownloadFilePath, PWSTR pszDownloadMimeType, PWSTR pszEnclosureFilename) SetFile;
	}


	public HRESULT Url(PWSTR* ppszUrl) mut => VT.[Friend]Url(&this, ppszUrl);

	public HRESULT Type(PWSTR* ppszMimeType) mut => VT.[Friend]Type(&this, ppszMimeType);

	public HRESULT Length(uint32* puiLength) mut => VT.[Friend]Length(&this, puiLength);

	public HRESULT AsyncDownload() mut => VT.[Friend]AsyncDownload(&this);

	public HRESULT CancelAsyncDownload() mut => VT.[Friend]CancelAsyncDownload(&this);

	public HRESULT DownloadStatus(FEEDS_DOWNLOAD_STATUS* pfds) mut => VT.[Friend]DownloadStatus(&this, pfds);

	public HRESULT LastDownloadError(FEEDS_DOWNLOAD_ERROR* pfde) mut => VT.[Friend]LastDownloadError(&this, pfde);

	public HRESULT LocalPath(PWSTR* ppszPath) mut => VT.[Friend]LocalPath(&this, ppszPath);

	public HRESULT Parent(in Guid riid, void** ppv) mut => VT.[Friend]Parent(&this, riid, ppv);

	public HRESULT DownloadUrl(PWSTR* ppszUrl) mut => VT.[Friend]DownloadUrl(&this, ppszUrl);

	public HRESULT DownloadMimeType(PWSTR* ppszMimeType) mut => VT.[Friend]DownloadMimeType(&this, ppszMimeType);

	public HRESULT RemoveFile() mut => VT.[Friend]RemoveFile(&this);

	public HRESULT SetFile(PWSTR pszDownloadUrl, PWSTR pszDownloadFilePath, PWSTR pszDownloadMimeType, PWSTR pszEnclosureFilename) mut => VT.[Friend]SetFile(&this, pszDownloadUrl, pszDownloadFilePath, pszDownloadMimeType, pszEnclosureFilename);
}

[CRepr]struct IFeedsManager : IDispatch
{
	public new const Guid IID = .(0xa74029cc, 0x1f1a, 0x4906, 0x88, 0xf0, 0x81, 0x06, 0x38, 0xd8, 0x65, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_RootFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedUrl, int16* subscribed) IsSubscribed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedPath, int16* exists) ExistsFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedPath, IDispatch** disp) GetFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedUrl, IDispatch** disp) GetFeedByUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderPath, int16* exists) ExistsFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderPath, IDispatch** disp) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedPath) DeleteFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderPath) DeleteFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_BACKGROUNDSYNC_ACTION action) BackgroundSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_BACKGROUNDSYNC_STATUS* status) get_BackgroundSyncStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* minutes) get_DefaultInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 minutes) put_DefaultInterval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncSyncAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedXmlIn, BSTR* feedXmlOut) Normalize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* itemCountLimit) get_ItemCountLimit;
	}


	public HRESULT get_RootFolder(IDispatch** disp) mut => VT.[Friend]get_RootFolder(&this, disp);

	public HRESULT IsSubscribed(BSTR feedUrl, int16* subscribed) mut => VT.[Friend]IsSubscribed(&this, feedUrl, subscribed);

	public HRESULT ExistsFeed(BSTR feedPath, int16* exists) mut => VT.[Friend]ExistsFeed(&this, feedPath, exists);

	public HRESULT GetFeed(BSTR feedPath, IDispatch** disp) mut => VT.[Friend]GetFeed(&this, feedPath, disp);

	public HRESULT GetFeedByUrl(BSTR feedUrl, IDispatch** disp) mut => VT.[Friend]GetFeedByUrl(&this, feedUrl, disp);

	public HRESULT ExistsFolder(BSTR folderPath, int16* exists) mut => VT.[Friend]ExistsFolder(&this, folderPath, exists);

	public HRESULT GetFolder(BSTR folderPath, IDispatch** disp) mut => VT.[Friend]GetFolder(&this, folderPath, disp);

	public HRESULT DeleteFeed(BSTR feedPath) mut => VT.[Friend]DeleteFeed(&this, feedPath);

	public HRESULT DeleteFolder(BSTR folderPath) mut => VT.[Friend]DeleteFolder(&this, folderPath);

	public HRESULT BackgroundSync(FEEDS_BACKGROUNDSYNC_ACTION action) mut => VT.[Friend]BackgroundSync(&this, action);

	public HRESULT get_BackgroundSyncStatus(FEEDS_BACKGROUNDSYNC_STATUS* status) mut => VT.[Friend]get_BackgroundSyncStatus(&this, status);

	public HRESULT get_DefaultInterval(int32* minutes) mut => VT.[Friend]get_DefaultInterval(&this, minutes);

	public HRESULT put_DefaultInterval(int32 minutes) mut => VT.[Friend]put_DefaultInterval(&this, minutes);

	public HRESULT AsyncSyncAll() mut => VT.[Friend]AsyncSyncAll(&this);

	public HRESULT Normalize(BSTR feedXmlIn, BSTR* feedXmlOut) mut => VT.[Friend]Normalize(&this, feedXmlIn, feedXmlOut);

	public HRESULT get_ItemCountLimit(int32* itemCountLimit) mut => VT.[Friend]get_ItemCountLimit(&this, itemCountLimit);
}

[CRepr]struct IFeedsEnum : IDispatch
{
	public new const Guid IID = .(0xe3cd0028, 0x2eed, 0x4c60, 0x8f, 0xae, 0xa3, 0x22, 0x53, 0x09, 0xa8, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, IDispatch** disp) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumVARIANT** enumVar) get__NewEnum;
	}


	public HRESULT get_Count(int32* count) mut => VT.[Friend]get_Count(&this, count);

	public HRESULT Item(int32 index, IDispatch** disp) mut => VT.[Friend]Item(&this, index, disp);

	public HRESULT get__NewEnum(IEnumVARIANT** enumVar) mut => VT.[Friend]get__NewEnum(&this, enumVar);
}

[CRepr]struct IFeedFolder : IDispatch
{
	public new const Guid IID = .(0x81f04ad1, 0x4194, 0x4d7d, 0x86, 0xd6, 0x11, 0x81, 0x3c, 0xec, 0x16, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Feeds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Subfolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedName, BSTR feedUrl, IDispatch** disp) CreateFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderName, IDispatch** disp) CreateSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedName, int16* exists) ExistsFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedName, IDispatch** disp) GetFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderName, int16* exists) ExistsSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderName, IDispatch** disp) GetSubfolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* folderName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR folderName) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* folderPath) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newParentPath) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* isRoot) get_IsRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_TotalUnreadItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_TotalItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, IDispatch** disp) GetWatcher;
	}


	public HRESULT get_Feeds(IDispatch** disp) mut => VT.[Friend]get_Feeds(&this, disp);

	public HRESULT get_Subfolders(IDispatch** disp) mut => VT.[Friend]get_Subfolders(&this, disp);

	public HRESULT CreateFeed(BSTR feedName, BSTR feedUrl, IDispatch** disp) mut => VT.[Friend]CreateFeed(&this, feedName, feedUrl, disp);

	public HRESULT CreateSubfolder(BSTR folderName, IDispatch** disp) mut => VT.[Friend]CreateSubfolder(&this, folderName, disp);

	public HRESULT ExistsFeed(BSTR feedName, int16* exists) mut => VT.[Friend]ExistsFeed(&this, feedName, exists);

	public HRESULT GetFeed(BSTR feedName, IDispatch** disp) mut => VT.[Friend]GetFeed(&this, feedName, disp);

	public HRESULT ExistsSubfolder(BSTR folderName, int16* exists) mut => VT.[Friend]ExistsSubfolder(&this, folderName, exists);

	public HRESULT GetSubfolder(BSTR folderName, IDispatch** disp) mut => VT.[Friend]GetSubfolder(&this, folderName, disp);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT get_Name(BSTR* folderName) mut => VT.[Friend]get_Name(&this, folderName);

	public HRESULT Rename(BSTR folderName) mut => VT.[Friend]Rename(&this, folderName);

	public HRESULT get_Path(BSTR* folderPath) mut => VT.[Friend]get_Path(&this, folderPath);

	public HRESULT Move(BSTR newParentPath) mut => VT.[Friend]Move(&this, newParentPath);

	public HRESULT get_Parent(IDispatch** disp) mut => VT.[Friend]get_Parent(&this, disp);

	public HRESULT get_IsRoot(int16* isRoot) mut => VT.[Friend]get_IsRoot(&this, isRoot);

	public HRESULT get_TotalUnreadItemCount(int32* count) mut => VT.[Friend]get_TotalUnreadItemCount(&this, count);

	public HRESULT get_TotalItemCount(int32* count) mut => VT.[Friend]get_TotalItemCount(&this, count);

	public HRESULT GetWatcher(FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, IDispatch** disp) mut => VT.[Friend]GetWatcher(&this, @scope, mask, disp);
}

[CRepr]struct IFeedFolderEvents : IDispatch
{
	public new const Guid IID = .(0x20a59fa6, 0xa844, 0x4630, 0x9e, 0x98, 0x17, 0x5f, 0x70, 0xb4, 0xd5, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FolderAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FolderDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FolderRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FolderMovedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FolderMovedTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, int32 itemCountType) FolderItemCountChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FeedRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedUrlChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FeedMovedFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FeedMovedTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedDownloading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FEEDS_DOWNLOAD_ERROR error) FeedDownloadCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, int32 itemCountType) FeedItemCountChanged;
	}


	public HRESULT Error() mut => VT.[Friend]Error(&this);

	public HRESULT FolderAdded(BSTR path) mut => VT.[Friend]FolderAdded(&this, path);

	public HRESULT FolderDeleted(BSTR path) mut => VT.[Friend]FolderDeleted(&this, path);

	public HRESULT FolderRenamed(BSTR path, BSTR oldPath) mut => VT.[Friend]FolderRenamed(&this, path, oldPath);

	public HRESULT FolderMovedFrom(BSTR path, BSTR oldPath) mut => VT.[Friend]FolderMovedFrom(&this, path, oldPath);

	public HRESULT FolderMovedTo(BSTR path, BSTR oldPath) mut => VT.[Friend]FolderMovedTo(&this, path, oldPath);

	public HRESULT FolderItemCountChanged(BSTR path, int32 itemCountType) mut => VT.[Friend]FolderItemCountChanged(&this, path, itemCountType);

	public HRESULT FeedAdded(BSTR path) mut => VT.[Friend]FeedAdded(&this, path);

	public HRESULT FeedDeleted(BSTR path) mut => VT.[Friend]FeedDeleted(&this, path);

	public HRESULT FeedRenamed(BSTR path, BSTR oldPath) mut => VT.[Friend]FeedRenamed(&this, path, oldPath);

	public HRESULT FeedUrlChanged(BSTR path) mut => VT.[Friend]FeedUrlChanged(&this, path);

	public HRESULT FeedMovedFrom(BSTR path, BSTR oldPath) mut => VT.[Friend]FeedMovedFrom(&this, path, oldPath);

	public HRESULT FeedMovedTo(BSTR path, BSTR oldPath) mut => VT.[Friend]FeedMovedTo(&this, path, oldPath);

	public HRESULT FeedDownloading(BSTR path) mut => VT.[Friend]FeedDownloading(&this, path);

	public HRESULT FeedDownloadCompleted(BSTR path, FEEDS_DOWNLOAD_ERROR error) mut => VT.[Friend]FeedDownloadCompleted(&this, path, error);

	public HRESULT FeedItemCountChanged(BSTR path, int32 itemCountType) mut => VT.[Friend]FeedItemCountChanged(&this, path, itemCountType);
}

[CRepr]struct IFeed : IDispatch
{
	public new const Guid IID = .(0xf7f915d8, 0x2ede, 0x42bc, 0x98, 0xe7, 0xa5, 0xd0, 0x50, 0x63, 0xa7, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 count, FEEDS_XML_SORT_PROPERTY sortProperty, FEEDS_XML_SORT_ORDER sortOrder, FEEDS_XML_FILTER_FLAGS filterFlags, FEEDS_XML_INCLUDE_FLAGS includeFlags, BSTR* xml) Xml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name) Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* feedUrl) get_Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedUrl) put_Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* feedGuid) get_LocalId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR newParentPath) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastWrite) get_LastWriteTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Download;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelAsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_SYNC_SETTING* syncSetting) get_SyncSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_SYNC_SETTING syncSetting) put_SyncSetting;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* minutes) get_Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 minutes) put_Interval;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastDownload) get_LastDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* path) get_LocalEnclosurePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Items;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 itemId, IDispatch** disp) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* title) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* homePage) get_Link;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* imageUrl) get_Image;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastBuildDate) get_LastBuildDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastPopulateDate) get_PubDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* ttl) get_Ttl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* language) get_Language;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* copyright) get_Copyright;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_MaxItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 count) put_MaxItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* downloadEnclosuresAutomatically) get_DownloadEnclosuresAutomatically;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 downloadEnclosuresAutomatically) put_DownloadEnclosuresAutomatically;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_STATUS* status) get_DownloadStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_ERROR* error) get_LastDownloadError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR feedXml, BSTR feedUrl) Merge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* feedUrl) get_DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* isList) get_IsList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MarkAllItemsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, IDispatch** disp) GetWatcher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_UnreadItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* count) get_ItemCount;
	}


	public HRESULT Xml(int32 count, FEEDS_XML_SORT_PROPERTY sortProperty, FEEDS_XML_SORT_ORDER sortOrder, FEEDS_XML_FILTER_FLAGS filterFlags, FEEDS_XML_INCLUDE_FLAGS includeFlags, BSTR* xml) mut => VT.[Friend]Xml(&this, count, sortProperty, sortOrder, filterFlags, includeFlags, xml);

	public HRESULT get_Name(BSTR* name) mut => VT.[Friend]get_Name(&this, name);

	public HRESULT Rename(BSTR name) mut => VT.[Friend]Rename(&this, name);

	public HRESULT get_Url(BSTR* feedUrl) mut => VT.[Friend]get_Url(&this, feedUrl);

	public HRESULT put_Url(BSTR feedUrl) mut => VT.[Friend]put_Url(&this, feedUrl);

	public HRESULT get_LocalId(BSTR* feedGuid) mut => VT.[Friend]get_LocalId(&this, feedGuid);

	public HRESULT get_Path(BSTR* path) mut => VT.[Friend]get_Path(&this, path);

	public HRESULT Move(BSTR newParentPath) mut => VT.[Friend]Move(&this, newParentPath);

	public HRESULT get_Parent(IDispatch** disp) mut => VT.[Friend]get_Parent(&this, disp);

	public HRESULT get_LastWriteTime(double* lastWrite) mut => VT.[Friend]get_LastWriteTime(&this, lastWrite);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Download() mut => VT.[Friend]Download(&this);

	public HRESULT AsyncDownload() mut => VT.[Friend]AsyncDownload(&this);

	public HRESULT CancelAsyncDownload() mut => VT.[Friend]CancelAsyncDownload(&this);

	public HRESULT get_SyncSetting(FEEDS_SYNC_SETTING* syncSetting) mut => VT.[Friend]get_SyncSetting(&this, syncSetting);

	public HRESULT put_SyncSetting(FEEDS_SYNC_SETTING syncSetting) mut => VT.[Friend]put_SyncSetting(&this, syncSetting);

	public HRESULT get_Interval(int32* minutes) mut => VT.[Friend]get_Interval(&this, minutes);

	public HRESULT put_Interval(int32 minutes) mut => VT.[Friend]put_Interval(&this, minutes);

	public HRESULT get_LastDownloadTime(double* lastDownload) mut => VT.[Friend]get_LastDownloadTime(&this, lastDownload);

	public HRESULT get_LocalEnclosurePath(BSTR* path) mut => VT.[Friend]get_LocalEnclosurePath(&this, path);

	public HRESULT get_Items(IDispatch** disp) mut => VT.[Friend]get_Items(&this, disp);

	public HRESULT GetItem(int32 itemId, IDispatch** disp) mut => VT.[Friend]GetItem(&this, itemId, disp);

	public HRESULT get_Title(BSTR* title) mut => VT.[Friend]get_Title(&this, title);

	public HRESULT get_Description(BSTR* description) mut => VT.[Friend]get_Description(&this, description);

	public HRESULT get_Link(BSTR* homePage) mut => VT.[Friend]get_Link(&this, homePage);

	public HRESULT get_Image(BSTR* imageUrl) mut => VT.[Friend]get_Image(&this, imageUrl);

	public HRESULT get_LastBuildDate(double* lastBuildDate) mut => VT.[Friend]get_LastBuildDate(&this, lastBuildDate);

	public HRESULT get_PubDate(double* lastPopulateDate) mut => VT.[Friend]get_PubDate(&this, lastPopulateDate);

	public HRESULT get_Ttl(int32* ttl) mut => VT.[Friend]get_Ttl(&this, ttl);

	public HRESULT get_Language(BSTR* language) mut => VT.[Friend]get_Language(&this, language);

	public HRESULT get_Copyright(BSTR* copyright) mut => VT.[Friend]get_Copyright(&this, copyright);

	public HRESULT get_MaxItemCount(int32* count) mut => VT.[Friend]get_MaxItemCount(&this, count);

	public HRESULT put_MaxItemCount(int32 count) mut => VT.[Friend]put_MaxItemCount(&this, count);

	public HRESULT get_DownloadEnclosuresAutomatically(int16* downloadEnclosuresAutomatically) mut => VT.[Friend]get_DownloadEnclosuresAutomatically(&this, downloadEnclosuresAutomatically);

	public HRESULT put_DownloadEnclosuresAutomatically(int16 downloadEnclosuresAutomatically) mut => VT.[Friend]put_DownloadEnclosuresAutomatically(&this, downloadEnclosuresAutomatically);

	public HRESULT get_DownloadStatus(FEEDS_DOWNLOAD_STATUS* status) mut => VT.[Friend]get_DownloadStatus(&this, status);

	public HRESULT get_LastDownloadError(FEEDS_DOWNLOAD_ERROR* error) mut => VT.[Friend]get_LastDownloadError(&this, error);

	public HRESULT Merge(BSTR feedXml, BSTR feedUrl) mut => VT.[Friend]Merge(&this, feedXml, feedUrl);

	public HRESULT get_DownloadUrl(BSTR* feedUrl) mut => VT.[Friend]get_DownloadUrl(&this, feedUrl);

	public HRESULT get_IsList(int16* isList) mut => VT.[Friend]get_IsList(&this, isList);

	public HRESULT MarkAllItemsRead() mut => VT.[Friend]MarkAllItemsRead(&this);

	public HRESULT GetWatcher(FEEDS_EVENTS_SCOPE @scope, FEEDS_EVENTS_MASK mask, IDispatch** disp) mut => VT.[Friend]GetWatcher(&this, @scope, mask, disp);

	public HRESULT get_UnreadItemCount(int32* count) mut => VT.[Friend]get_UnreadItemCount(&this, count);

	public HRESULT get_ItemCount(int32* count) mut => VT.[Friend]get_ItemCount(&this, count);
}

[CRepr]struct IFeed2 : IFeed
{
	public new const Guid IID = .(0x33f2ea09, 0x1398, 0x4ab9, 0xb6, 0xa4, 0xf9, 0x4b, 0x49, 0xd0, 0xa4, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFeed.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 itemEffectiveId, IDispatch** disp) GetItemByEffectiveId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastItemDownloadTime) get_LastItemDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* username) get_Username;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* password) get_Password;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR username, BSTR password) SetCredentials;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearCredentials;
	}


	public HRESULT GetItemByEffectiveId(int32 itemEffectiveId, IDispatch** disp) mut => VT.[Friend]GetItemByEffectiveId(&this, itemEffectiveId, disp);

	public HRESULT get_LastItemDownloadTime(double* lastItemDownloadTime) mut => VT.[Friend]get_LastItemDownloadTime(&this, lastItemDownloadTime);

	public HRESULT get_Username(BSTR* username) mut => VT.[Friend]get_Username(&this, username);

	public HRESULT get_Password(BSTR* password) mut => VT.[Friend]get_Password(&this, password);

	public HRESULT SetCredentials(BSTR username, BSTR password) mut => VT.[Friend]SetCredentials(&this, username, password);

	public HRESULT ClearCredentials() mut => VT.[Friend]ClearCredentials(&this);
}

[CRepr]struct IFeedEvents : IDispatch
{
	public new const Guid IID = .(0xabf35c99, 0x0681, 0x47ea, 0x9a, 0x8c, 0x14, 0x36, 0xa3, 0x75, 0xa9, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Error;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FeedRenamed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedUrlChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, BSTR oldPath) FeedMoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path) FeedDownloading;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, FEEDS_DOWNLOAD_ERROR error) FeedDownloadCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR path, int32 itemCountType) FeedItemCountChanged;
	}


	public HRESULT Error() mut => VT.[Friend]Error(&this);

	public HRESULT FeedDeleted(BSTR path) mut => VT.[Friend]FeedDeleted(&this, path);

	public HRESULT FeedRenamed(BSTR path, BSTR oldPath) mut => VT.[Friend]FeedRenamed(&this, path, oldPath);

	public HRESULT FeedUrlChanged(BSTR path) mut => VT.[Friend]FeedUrlChanged(&this, path);

	public HRESULT FeedMoved(BSTR path, BSTR oldPath) mut => VT.[Friend]FeedMoved(&this, path, oldPath);

	public HRESULT FeedDownloading(BSTR path) mut => VT.[Friend]FeedDownloading(&this, path);

	public HRESULT FeedDownloadCompleted(BSTR path, FEEDS_DOWNLOAD_ERROR error) mut => VT.[Friend]FeedDownloadCompleted(&this, path, error);

	public HRESULT FeedItemCountChanged(BSTR path, int32 itemCountType) mut => VT.[Friend]FeedItemCountChanged(&this, path, itemCountType);
}

[CRepr]struct IFeedItem : IDispatch
{
	public new const Guid IID = .(0x0a1e6cad, 0x0a47, 0x4da2, 0xa1, 0x3d, 0x5b, 0xaa, 0xa5, 0xc8, 0xbd, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_XML_INCLUDE_FLAGS includeFlags, BSTR* xml) Xml;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* title) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* linkUrl) get_Link;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* itemGuid) get_Guid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* description) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pubDate) get_PubDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* comments) get_Comments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* author) get_Author;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Enclosure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* isRead) get_IsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 isRead) put_IsRead;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* itemId) get_LocalId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* itemUrl) get_DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* lastDownload) get_LastDownloadTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* modified) get_Modified;
	}


	public HRESULT Xml(FEEDS_XML_INCLUDE_FLAGS includeFlags, BSTR* xml) mut => VT.[Friend]Xml(&this, includeFlags, xml);

	public HRESULT get_Title(BSTR* title) mut => VT.[Friend]get_Title(&this, title);

	public HRESULT get_Link(BSTR* linkUrl) mut => VT.[Friend]get_Link(&this, linkUrl);

	public HRESULT get_Guid(BSTR* itemGuid) mut => VT.[Friend]get_Guid(&this, itemGuid);

	public HRESULT get_Description(BSTR* description) mut => VT.[Friend]get_Description(&this, description);

	public HRESULT get_PubDate(double* pubDate) mut => VT.[Friend]get_PubDate(&this, pubDate);

	public HRESULT get_Comments(BSTR* comments) mut => VT.[Friend]get_Comments(&this, comments);

	public HRESULT get_Author(BSTR* author) mut => VT.[Friend]get_Author(&this, author);

	public HRESULT get_Enclosure(IDispatch** disp) mut => VT.[Friend]get_Enclosure(&this, disp);

	public HRESULT get_IsRead(int16* isRead) mut => VT.[Friend]get_IsRead(&this, isRead);

	public HRESULT put_IsRead(int16 isRead) mut => VT.[Friend]put_IsRead(&this, isRead);

	public HRESULT get_LocalId(int32* itemId) mut => VT.[Friend]get_LocalId(&this, itemId);

	public HRESULT get_Parent(IDispatch** disp) mut => VT.[Friend]get_Parent(&this, disp);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT get_DownloadUrl(BSTR* itemUrl) mut => VT.[Friend]get_DownloadUrl(&this, itemUrl);

	public HRESULT get_LastDownloadTime(double* lastDownload) mut => VT.[Friend]get_LastDownloadTime(&this, lastDownload);

	public HRESULT get_Modified(double* modified) mut => VT.[Friend]get_Modified(&this, modified);
}

[CRepr]struct IFeedItem2 : IFeedItem
{
	public new const Guid IID = .(0x79ac9ef4, 0xf9c1, 0x4d2b, 0xa5, 0x0b, 0xa7, 0xff, 0xba, 0x4d, 0xcf, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFeedItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* effectiveId) get_EffectiveId;
	}


	public HRESULT get_EffectiveId(int32* effectiveId) mut => VT.[Friend]get_EffectiveId(&this, effectiveId);
}

[CRepr]struct IFeedEnclosure : IDispatch
{
	public new const Guid IID = .(0x361c26f7, 0x90a4, 0x4e67, 0xae, 0x09, 0x3a, 0x36, 0xa5, 0x46, 0x43, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* enclosureUrl) get_Url;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mimeType) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* length) get_Length;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelAsyncDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_STATUS* status) get_DownloadStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FEEDS_DOWNLOAD_ERROR* error) get_LastDownloadError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* localPath) get_LocalPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** disp) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* enclosureUrl) get_DownloadUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* mimeType) get_DownloadMimeType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR downloadUrl, BSTR downloadFilePath, BSTR downloadMimeType, BSTR enclosureFilename) SetFile;
	}


	public HRESULT get_Url(BSTR* enclosureUrl) mut => VT.[Friend]get_Url(&this, enclosureUrl);

	public HRESULT get_Type(BSTR* mimeType) mut => VT.[Friend]get_Type(&this, mimeType);

	public HRESULT get_Length(int32* length) mut => VT.[Friend]get_Length(&this, length);

	public HRESULT AsyncDownload() mut => VT.[Friend]AsyncDownload(&this);

	public HRESULT CancelAsyncDownload() mut => VT.[Friend]CancelAsyncDownload(&this);

	public HRESULT get_DownloadStatus(FEEDS_DOWNLOAD_STATUS* status) mut => VT.[Friend]get_DownloadStatus(&this, status);

	public HRESULT get_LastDownloadError(FEEDS_DOWNLOAD_ERROR* error) mut => VT.[Friend]get_LastDownloadError(&this, error);

	public HRESULT get_LocalPath(BSTR* localPath) mut => VT.[Friend]get_LocalPath(&this, localPath);

	public HRESULT get_Parent(IDispatch** disp) mut => VT.[Friend]get_Parent(&this, disp);

	public HRESULT get_DownloadUrl(BSTR* enclosureUrl) mut => VT.[Friend]get_DownloadUrl(&this, enclosureUrl);

	public HRESULT get_DownloadMimeType(BSTR* mimeType) mut => VT.[Friend]get_DownloadMimeType(&this, mimeType);

	public HRESULT RemoveFile() mut => VT.[Friend]RemoveFile(&this);

	public HRESULT SetFile(BSTR downloadUrl, BSTR downloadFilePath, BSTR downloadMimeType, BSTR enclosureFilename) mut => VT.[Friend]SetFile(&this, downloadUrl, downloadFilePath, downloadMimeType, enclosureFilename);
}

[CRepr]struct IWMPEffects : IUnknown
{
	public new const Guid IID = .(0xd3984c13, 0xc3cb, 0x48e2, 0x8b, 0xe5, 0x51, 0x68, 0x34, 0x0b, 0x4f, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TimedLevel* pLevels, HDC hdc, RECT* prc) Render;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lChannelCount, int32 lSampleRate, BSTR bstrTitle) MediaInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrTitle) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nPreset, BSTR* bstrPresetTitle) GetPresetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnPresetCount) GetPresetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nPreset) SetCurrentPreset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pnPreset) GetCurrentPreset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner) DisplayPropertyPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFullScreen) GoFullscreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TimedLevel* pLevels) RenderFullScreen;
	}


	public HRESULT Render(TimedLevel* pLevels, HDC hdc, RECT* prc) mut => VT.[Friend]Render(&this, pLevels, hdc, prc);

	public HRESULT MediaInfo(int32 lChannelCount, int32 lSampleRate, BSTR bstrTitle) mut => VT.[Friend]MediaInfo(&this, lChannelCount, lSampleRate, bstrTitle);

	public HRESULT GetCapabilities(uint32* pdwCapabilities) mut => VT.[Friend]GetCapabilities(&this, pdwCapabilities);

	public HRESULT GetTitle(BSTR* bstrTitle) mut => VT.[Friend]GetTitle(&this, bstrTitle);

	public HRESULT GetPresetTitle(int32 nPreset, BSTR* bstrPresetTitle) mut => VT.[Friend]GetPresetTitle(&this, nPreset, bstrPresetTitle);

	public HRESULT GetPresetCount(int32* pnPresetCount) mut => VT.[Friend]GetPresetCount(&this, pnPresetCount);

	public HRESULT SetCurrentPreset(int32 nPreset) mut => VT.[Friend]SetCurrentPreset(&this, nPreset);

	public HRESULT GetCurrentPreset(int32* pnPreset) mut => VT.[Friend]GetCurrentPreset(&this, pnPreset);

	public HRESULT DisplayPropertyPage(HWND hwndOwner) mut => VT.[Friend]DisplayPropertyPage(&this, hwndOwner);

	public HRESULT GoFullscreen(BOOL fFullScreen) mut => VT.[Friend]GoFullscreen(&this, fFullScreen);

	public HRESULT RenderFullScreen(TimedLevel* pLevels) mut => VT.[Friend]RenderFullScreen(&this, pLevels);
}

[CRepr]struct IWMPEffects2 : IWMPEffects
{
	public new const Guid IID = .(0x695386ec, 0xaa3c, 0x4618, 0xa5, 0xe1, 0xdd, 0x9a, 0x8b, 0x98, 0x76, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPEffects.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPCore* pPlayer) SetCore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPMedia* pMedia) NotifyNewMedia;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 msg, WPARAM WParam, LPARAM LParam, LRESULT* plResultParam) OnWindowMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TimedLevel* pData, BOOL fRequiredRender) RenderWindowed;
	}


	public HRESULT SetCore(IWMPCore* pPlayer) mut => VT.[Friend]SetCore(&this, pPlayer);

	public HRESULT Create(HWND hwndParent) mut => VT.[Friend]Create(&this, hwndParent);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT NotifyNewMedia(IWMPMedia* pMedia) mut => VT.[Friend]NotifyNewMedia(&this, pMedia);

	public HRESULT OnWindowMessage(uint32 msg, WPARAM WParam, LPARAM LParam, LRESULT* plResultParam) mut => VT.[Friend]OnWindowMessage(&this, msg, WParam, LParam, plResultParam);

	public HRESULT RenderWindowed(TimedLevel* pData, BOOL fRequiredRender) mut => VT.[Friend]RenderWindowed(&this, pData, fRequiredRender);
}

[CRepr]struct IWMPPluginUI : IUnknown
{
	public new const Guid IID = .(0x4c5e8f9f, 0xad3e, 0x4bf9, 0x97, 0x53, 0xfc, 0xd3, 0x0d, 0x6d, 0x38, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPCore* pCore) SetCore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, HWND* phwndWindow) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) DisplayPropertyPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, VARIANT* pvarProperty) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszName, VARIANT* pvarProperty) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* lpmsg) TranslateAccelerator;
	}


	public HRESULT SetCore(IWMPCore* pCore) mut => VT.[Friend]SetCore(&this, pCore);

	public HRESULT Create(HWND hwndParent, HWND* phwndWindow) mut => VT.[Friend]Create(&this, hwndParent, phwndWindow);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT DisplayPropertyPage(HWND hwndParent) mut => VT.[Friend]DisplayPropertyPage(&this, hwndParent);

	public HRESULT GetProperty(PWSTR pwszName, VARIANT* pvarProperty) mut => VT.[Friend]GetProperty(&this, pwszName, pvarProperty);

	public HRESULT SetProperty(PWSTR pwszName, VARIANT* pvarProperty) mut => VT.[Friend]SetProperty(&this, pwszName, pvarProperty);

	public HRESULT TranslateAccelerator(MSG* lpmsg) mut => VT.[Friend]TranslateAccelerator(&this, lpmsg);
}

[CRepr]struct IWMPContentContainer : IUnknown
{
	public new const Guid IID = .(0xad7f4d9c, 0x1a9f, 0x4ed2, 0x98, 0x15, 0xec, 0xc0, 0xb5, 0x8c, 0xb6, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pContentID) GetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPrice) GetPrice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcContent) GetContentCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idxContent, BSTR* pbstrPrice) GetContentPrice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idxContent, uint32* pContentID) GetContentID;
	}


	public HRESULT GetID(uint32* pContentID) mut => VT.[Friend]GetID(&this, pContentID);

	public HRESULT GetPrice(BSTR* pbstrPrice) mut => VT.[Friend]GetPrice(&this, pbstrPrice);

	public HRESULT GetType(BSTR* pbstrType) mut => VT.[Friend]COM_GetType(&this, pbstrType);

	public HRESULT GetContentCount(uint32* pcContent) mut => VT.[Friend]GetContentCount(&this, pcContent);

	public HRESULT GetContentPrice(uint32 idxContent, BSTR* pbstrPrice) mut => VT.[Friend]GetContentPrice(&this, idxContent, pbstrPrice);

	public HRESULT GetContentID(uint32 idxContent, uint32* pContentID) mut => VT.[Friend]GetContentID(&this, idxContent, pContentID);
}

[CRepr]struct IWMPContentContainerList : IUnknown
{
	public new const Guid IID = .(0xa9937f78, 0x0802, 0x4af8, 0x8b, 0x8d, 0xe3, 0xf0, 0x45, 0xbc, 0x8a, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPTransactionType* pwmptt) GetTransactionType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcContainer) GetContainerCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 idxContainer, IWMPContentContainer** ppContent) GetContainer;
	}


	public HRESULT GetTransactionType(WMPTransactionType* pwmptt) mut => VT.[Friend]GetTransactionType(&this, pwmptt);

	public HRESULT GetContainerCount(uint32* pcContainer) mut => VT.[Friend]GetContainerCount(&this, pcContainer);

	public HRESULT GetContainer(uint32 idxContainer, IWMPContentContainer** ppContent) mut => VT.[Friend]GetContainer(&this, idxContainer, ppContent);
}

[CRepr]struct IWMPContentPartnerCallback : IUnknown
{
	public new const Guid IID = .(0x9e8f7da2, 0x0695, 0x403c, 0xb6, 0x97, 0xda, 0x10, 0xfa, 0xfa, 0xa6, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPCallbackNotification type, VARIANT* pContext) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrResult, uint32 dwBuyCookie) BuyComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie, BSTR bstrTrackURL, uint32 dwServiceTrackID, BSTR bstrDownloadParams, HRESULT hrDownload) DownloadTrack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion, uint32* pdwSchemaVersion, uint32* plcid) GetCatalogVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceName) UpdateDeviceComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrType, BSTR bstrID, BSTR bstrFilter) ChangeView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwListCookie, uint32 cItems, uint32* prgItems) AddListContents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwListCookie, HRESULT hrSuccess) ListContentsComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMsg, BSTR bstrParam, BSTR bstrResult) SendMessageComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcContentIDs, uint32** pprgIDs) GetContentIDsInLibrary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie, uint32 contentID, HRESULT hrRefresh) RefreshLicenseComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lIndex, BSTR bstrParameters) ShowPopup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPermission, VARIANT* pContext, HRESULT hrPermission) VerifyPermissionComplete;
	}


	public HRESULT Notify(WMPCallbackNotification type, VARIANT* pContext) mut => VT.[Friend]Notify(&this, type, pContext);

	public HRESULT BuyComplete(HRESULT hrResult, uint32 dwBuyCookie) mut => VT.[Friend]BuyComplete(&this, hrResult, dwBuyCookie);

	public HRESULT DownloadTrack(uint32 cookie, BSTR bstrTrackURL, uint32 dwServiceTrackID, BSTR bstrDownloadParams, HRESULT hrDownload) mut => VT.[Friend]DownloadTrack(&this, cookie, bstrTrackURL, dwServiceTrackID, bstrDownloadParams, hrDownload);

	public HRESULT GetCatalogVersion(uint32* pdwVersion, uint32* pdwSchemaVersion, uint32* plcid) mut => VT.[Friend]GetCatalogVersion(&this, pdwVersion, pdwSchemaVersion, plcid);

	public HRESULT UpdateDeviceComplete(BSTR bstrDeviceName) mut => VT.[Friend]UpdateDeviceComplete(&this, bstrDeviceName);

	public HRESULT ChangeView(BSTR bstrType, BSTR bstrID, BSTR bstrFilter) mut => VT.[Friend]ChangeView(&this, bstrType, bstrID, bstrFilter);

	public HRESULT AddListContents(uint32 dwListCookie, uint32 cItems, uint32* prgItems) mut => VT.[Friend]AddListContents(&this, dwListCookie, cItems, prgItems);

	public HRESULT ListContentsComplete(uint32 dwListCookie, HRESULT hrSuccess) mut => VT.[Friend]ListContentsComplete(&this, dwListCookie, hrSuccess);

	public HRESULT SendMessageComplete(BSTR bstrMsg, BSTR bstrParam, BSTR bstrResult) mut => VT.[Friend]SendMessageComplete(&this, bstrMsg, bstrParam, bstrResult);

	public HRESULT GetContentIDsInLibrary(uint32* pcContentIDs, uint32** pprgIDs) mut => VT.[Friend]GetContentIDsInLibrary(&this, pcContentIDs, pprgIDs);

	public HRESULT RefreshLicenseComplete(uint32 dwCookie, uint32 contentID, HRESULT hrRefresh) mut => VT.[Friend]RefreshLicenseComplete(&this, dwCookie, contentID, hrRefresh);

	public HRESULT ShowPopup(int32 lIndex, BSTR bstrParameters) mut => VT.[Friend]ShowPopup(&this, lIndex, bstrParameters);

	public HRESULT VerifyPermissionComplete(BSTR bstrPermission, VARIANT* pContext, HRESULT hrPermission) mut => VT.[Friend]VerifyPermissionComplete(&this, bstrPermission, pContext, hrPermission);
}

[CRepr]struct IWMPContentPartner : IUnknown
{
	public new const Guid IID = .(0x55455073, 0x41b5, 0x4e75, 0x87, 0xb8, 0xf1, 0x3b, 0xdb, 0x29, 0x1d, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPContentPartnerCallback* pCallback) SetCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPPartnerNotification type, VARIANT* pContext) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInfoName, VARIANT* pContext, VARIANT* pData) GetItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInfoName, VARIANT* pData) GetContentPartnerInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR location, VARIANT* pLocationContext, BSTR itemLocation, uint32 cItemIDs, uint32* prgItemIDs, uint32* pcItemIDs, WMPContextMenuInfo** pprgItems) GetCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCommandID, BSTR location, VARIANT* pLocationContext, BSTR itemLocation, uint32 cItemIDs, uint32* rgItemIDs) InvokeCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPContentContainerList* pInfo, BSTR* pbstrTotalPrice, int16* pSilentOK) CanBuySilent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPContentContainerList* pInfo, uint32 cookie) Buy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPStreamingType st, VARIANT* pStreamContext, BSTR* pbstrURL) GetStreamingURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPContentContainerList* pInfo, uint32 cookie) Download;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrResult, uint32 contentID, BSTR downloadTrackParam) DownloadTrackComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie, int16 fLocal, BSTR bstrURL, WMPStreamingType type, uint32 contentID, BSTR bstrRefreshReason, VARIANT* pReasonContext) RefreshLicense;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCatalogVersion, uint32 dwCatalogSchemaVersion, uint32 catalogLCID, uint32* pdwNewCatalogVersion, BSTR* pbstrCatalogURL, VARIANT* pExpirationDate) GetCatalogURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPTaskType task, BSTR location, VARIANT* pContext, BSTR clickLocation, VARIANT* pClickContext, BSTR bstrFilter, BSTR bstrViewParams, BSTR* pbstrTemplateURL, WMPTemplateSize* pTemplateSize) GetTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceName) UpdateDevice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR location, VARIANT* pContext, BSTR bstrListType, BSTR bstrParams, uint32 dwListCookie) GetListContents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BLOB userInfo, BLOB pwdInfo, int16 fUsedCachedCreds, int16 fOkToCache) Login;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BLOB userInfo, BLOB pwdInfo) Authenticate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Logout;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMsg, BSTR bstrParam) SendMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrStationEventType, uint32 StationId, uint32 PlaylistIndex, uint32 TrackID, BSTR TrackData, uint32 dwSecondsPlayed) StationEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPContentContainerList* pListBase, IWMPContentContainerList* pListCompare, int32* pResult) CompareContainerListPrices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPermission, VARIANT* pContext) VerifyPermission;
	}


	public HRESULT SetCallback(IWMPContentPartnerCallback* pCallback) mut => VT.[Friend]SetCallback(&this, pCallback);

	public HRESULT Notify(WMPPartnerNotification type, VARIANT* pContext) mut => VT.[Friend]Notify(&this, type, pContext);

	public HRESULT GetItemInfo(BSTR bstrInfoName, VARIANT* pContext, VARIANT* pData) mut => VT.[Friend]GetItemInfo(&this, bstrInfoName, pContext, pData);

	public HRESULT GetContentPartnerInfo(BSTR bstrInfoName, VARIANT* pData) mut => VT.[Friend]GetContentPartnerInfo(&this, bstrInfoName, pData);

	public HRESULT GetCommands(BSTR location, VARIANT* pLocationContext, BSTR itemLocation, uint32 cItemIDs, uint32* prgItemIDs, uint32* pcItemIDs, WMPContextMenuInfo** pprgItems) mut => VT.[Friend]GetCommands(&this, location, pLocationContext, itemLocation, cItemIDs, prgItemIDs, pcItemIDs, pprgItems);

	public HRESULT InvokeCommand(uint32 dwCommandID, BSTR location, VARIANT* pLocationContext, BSTR itemLocation, uint32 cItemIDs, uint32* rgItemIDs) mut => VT.[Friend]InvokeCommand(&this, dwCommandID, location, pLocationContext, itemLocation, cItemIDs, rgItemIDs);

	public HRESULT CanBuySilent(IWMPContentContainerList* pInfo, BSTR* pbstrTotalPrice, int16* pSilentOK) mut => VT.[Friend]CanBuySilent(&this, pInfo, pbstrTotalPrice, pSilentOK);

	public HRESULT Buy(IWMPContentContainerList* pInfo, uint32 cookie) mut => VT.[Friend]Buy(&this, pInfo, cookie);

	public HRESULT GetStreamingURL(WMPStreamingType st, VARIANT* pStreamContext, BSTR* pbstrURL) mut => VT.[Friend]GetStreamingURL(&this, st, pStreamContext, pbstrURL);

	public HRESULT Download(IWMPContentContainerList* pInfo, uint32 cookie) mut => VT.[Friend]Download(&this, pInfo, cookie);

	public HRESULT DownloadTrackComplete(HRESULT hrResult, uint32 contentID, BSTR downloadTrackParam) mut => VT.[Friend]DownloadTrackComplete(&this, hrResult, contentID, downloadTrackParam);

	public HRESULT RefreshLicense(uint32 dwCookie, int16 fLocal, BSTR bstrURL, WMPStreamingType type, uint32 contentID, BSTR bstrRefreshReason, VARIANT* pReasonContext) mut => VT.[Friend]RefreshLicense(&this, dwCookie, fLocal, bstrURL, type, contentID, bstrRefreshReason, pReasonContext);

	public HRESULT GetCatalogURL(uint32 dwCatalogVersion, uint32 dwCatalogSchemaVersion, uint32 catalogLCID, uint32* pdwNewCatalogVersion, BSTR* pbstrCatalogURL, VARIANT* pExpirationDate) mut => VT.[Friend]GetCatalogURL(&this, dwCatalogVersion, dwCatalogSchemaVersion, catalogLCID, pdwNewCatalogVersion, pbstrCatalogURL, pExpirationDate);

	public HRESULT GetTemplate(WMPTaskType task, BSTR location, VARIANT* pContext, BSTR clickLocation, VARIANT* pClickContext, BSTR bstrFilter, BSTR bstrViewParams, BSTR* pbstrTemplateURL, WMPTemplateSize* pTemplateSize) mut => VT.[Friend]GetTemplate(&this, task, location, pContext, clickLocation, pClickContext, bstrFilter, bstrViewParams, pbstrTemplateURL, pTemplateSize);

	public HRESULT UpdateDevice(BSTR bstrDeviceName) mut => VT.[Friend]UpdateDevice(&this, bstrDeviceName);

	public HRESULT GetListContents(BSTR location, VARIANT* pContext, BSTR bstrListType, BSTR bstrParams, uint32 dwListCookie) mut => VT.[Friend]GetListContents(&this, location, pContext, bstrListType, bstrParams, dwListCookie);

	public HRESULT Login(BLOB userInfo, BLOB pwdInfo, int16 fUsedCachedCreds, int16 fOkToCache) mut => VT.[Friend]Login(&this, userInfo, pwdInfo, fUsedCachedCreds, fOkToCache);

	public HRESULT Authenticate(BLOB userInfo, BLOB pwdInfo) mut => VT.[Friend]Authenticate(&this, userInfo, pwdInfo);

	public HRESULT Logout() mut => VT.[Friend]Logout(&this);

	public HRESULT SendMessage(BSTR bstrMsg, BSTR bstrParam) mut => VT.[Friend]SendMessage(&this, bstrMsg, bstrParam);

	public HRESULT StationEvent(BSTR bstrStationEventType, uint32 StationId, uint32 PlaylistIndex, uint32 TrackID, BSTR TrackData, uint32 dwSecondsPlayed) mut => VT.[Friend]StationEvent(&this, bstrStationEventType, StationId, PlaylistIndex, TrackID, TrackData, dwSecondsPlayed);

	public HRESULT CompareContainerListPrices(IWMPContentContainerList* pListBase, IWMPContentContainerList* pListCompare, int32* pResult) mut => VT.[Friend]CompareContainerListPrices(&this, pListBase, pListCompare, pResult);

	public HRESULT VerifyPermission(BSTR bstrPermission, VARIANT* pContext) mut => VT.[Friend]VerifyPermission(&this, bstrPermission, pContext);
}

[CRepr]struct IWMPSubscriptionService : IUnknown
{
	public new const Guid IID = .(0x376055f8, 0x2a59, 0x4a73, 0x95, 0x01, 0xdc, 0xa5, 0x27, 0x3a, 0x7a, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IWMPMedia* pMedia, BOOL* pfAllowPlay) allowPlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IWMPPlaylist* pPlaylist, BOOL* pfAllowBurn) allowCDBurn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IWMPPlaylist* pPlaylist, BOOL* pfAllowTransfer) allowPDATransfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) startBackgroundProcessing;
	}


	public HRESULT allowPlay(HWND hwnd, IWMPMedia* pMedia, BOOL* pfAllowPlay) mut => VT.[Friend]allowPlay(&this, hwnd, pMedia, pfAllowPlay);

	public HRESULT allowCDBurn(HWND hwnd, IWMPPlaylist* pPlaylist, BOOL* pfAllowBurn) mut => VT.[Friend]allowCDBurn(&this, hwnd, pPlaylist, pfAllowBurn);

	public HRESULT allowPDATransfer(HWND hwnd, IWMPPlaylist* pPlaylist, BOOL* pfAllowTransfer) mut => VT.[Friend]allowPDATransfer(&this, hwnd, pPlaylist, pfAllowTransfer);

	public HRESULT startBackgroundProcessing(HWND hwnd) mut => VT.[Friend]startBackgroundProcessing(&this, hwnd);
}

[CRepr]struct IWMPSubscriptionServiceCallback : IUnknown
{
	public new const Guid IID = .(0xdd01d127, 0x2dc2, 0x4c3a, 0x87, 0x6e, 0x63, 0x31, 0x20, 0x79, 0xf9, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrResult) onComplete;
	}


	public HRESULT onComplete(HRESULT hrResult) mut => VT.[Friend]onComplete(&this, hrResult);
}

[CRepr]struct IWMPSubscriptionService2 : IWMPSubscriptionService
{
	public new const Guid IID = .(0xa94c120e, 0xd600, 0x4ec6, 0xb0, 0x5e, 0xec, 0x9d, 0x56, 0xd8, 0x4d, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPSubscriptionService.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) stopBackgroundProcessing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPSubscriptionServiceEvent event) serviceEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDeviceName, IWMPSubscriptionServiceCallback* pCB) deviceAvailable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFilename, BSTR bstrDeviceName, IWMPSubscriptionServiceCallback* pCB) prepareForSync;
	}


	public HRESULT stopBackgroundProcessing() mut => VT.[Friend]stopBackgroundProcessing(&this);

	public HRESULT serviceEvent(WMPSubscriptionServiceEvent event) mut => VT.[Friend]serviceEvent(&this, event);

	public HRESULT deviceAvailable(BSTR bstrDeviceName, IWMPSubscriptionServiceCallback* pCB) mut => VT.[Friend]deviceAvailable(&this, bstrDeviceName, pCB);

	public HRESULT prepareForSync(BSTR bstrFilename, BSTR bstrDeviceName, IWMPSubscriptionServiceCallback* pCB) mut => VT.[Friend]prepareForSync(&this, bstrFilename, bstrDeviceName, pCB);
}

[CRepr]struct IWMPDownloadItem : IDispatch
{
	public new const Guid IID = .(0xc9470e8e, 0x3f6b, 0x46a9, 0xa0, 0xa9, 0x45, 0x28, 0x15, 0xc3, 0x42, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrURL) get_sourceURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plSize) get_size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrType) get_type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plProgress) get_progress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WMPSubscriptionDownloadState* pwmpsdls) get_downloadState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) pause;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) cancel;
	}


	public HRESULT get_sourceURL(BSTR* pbstrURL) mut => VT.[Friend]get_sourceURL(&this, pbstrURL);

	public HRESULT get_size(int32* plSize) mut => VT.[Friend]get_size(&this, plSize);

	public HRESULT get_type(BSTR* pbstrType) mut => VT.[Friend]get_type(&this, pbstrType);

	public HRESULT get_progress(int32* plProgress) mut => VT.[Friend]get_progress(&this, plProgress);

	public HRESULT get_downloadState(WMPSubscriptionDownloadState* pwmpsdls) mut => VT.[Friend]get_downloadState(&this, pwmpsdls);

	public HRESULT pause() mut => VT.[Friend]pause(&this);

	public HRESULT resume() mut => VT.[Friend]resume(&this);

	public HRESULT cancel() mut => VT.[Friend]cancel(&this);
}

[CRepr]struct IWMPDownloadItem2 : IWMPDownloadItem
{
	public new const Guid IID = .(0x9fbb3336, 0x6da3, 0x479d, 0xb8, 0xff, 0x67, 0xd4, 0x6e, 0x20, 0xa9, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWMPDownloadItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrItemName, BSTR* pbstrVal) getItemInfo;
	}


	public HRESULT getItemInfo(BSTR bstrItemName, BSTR* pbstrVal) mut => VT.[Friend]getItemInfo(&this, bstrItemName, pbstrVal);
}

[CRepr]struct IWMPDownloadCollection : IDispatch
{
	public new const Guid IID = .(0x0a319c7f, 0x85f9, 0x436c, 0xb8, 0x8e, 0x82, 0xfd, 0x88, 0x00, 0x0e, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plId) get_id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lItem, IWMPDownloadItem2** ppDownload) item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSourceURL, BSTR bstrType, IWMPDownloadItem2** ppDownload) startDownload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lItem) removeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT get_id(int32* plId) mut => VT.[Friend]get_id(&this, plId);

	public HRESULT get_count(int32* plCount) mut => VT.[Friend]get_count(&this, plCount);

	public HRESULT item(int32 lItem, IWMPDownloadItem2** ppDownload) mut => VT.[Friend]item(&this, lItem, ppDownload);

	public HRESULT startDownload(BSTR bstrSourceURL, BSTR bstrType, IWMPDownloadItem2** ppDownload) mut => VT.[Friend]startDownload(&this, bstrSourceURL, bstrType, ppDownload);

	public HRESULT removeItem(int32 lItem) mut => VT.[Friend]removeItem(&this, lItem);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IWMPDownloadManager : IDispatch
{
	public new const Guid IID = .(0xe15e9ad1, 0x8f20, 0x4cc4, 0x9e, 0xc7, 0x1a, 0x32, 0x8c, 0xa8, 0x6a, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCollectionId, IWMPDownloadCollection** ppCollection) getDownloadCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWMPDownloadCollection** ppCollection) createDownloadCollection;
	}


	public HRESULT getDownloadCollection(int32 lCollectionId, IWMPDownloadCollection** ppCollection) mut => VT.[Friend]getDownloadCollection(&this, lCollectionId, ppCollection);

	public HRESULT createDownloadCollection(IWMPDownloadCollection** ppCollection) mut => VT.[Friend]createDownloadCollection(&this, ppCollection);
}

#endregion
