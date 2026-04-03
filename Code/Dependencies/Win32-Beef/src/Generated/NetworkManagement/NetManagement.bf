using Win32.Foundation;
using Win32.Security;
using Win32.Security.Cryptography;
using Win32.System.Com;
using Win32.System.Registry;
using Win32.Data.Xml.MsXml;
using System;

namespace Win32.NetworkManagement.NetManagement;

#region Constants
public static
{
	public const uint32 NERR_BASE = 2100;
	public const uint32 NERR_PasswordExpired = 2242;
	public const uint32 CNLEN = 15;
	public const uint32 LM20_CNLEN = 15;
	public const uint32 DNLEN = 15;
	public const uint32 LM20_DNLEN = 15;
	public const uint32 UNCLEN = 17;
	public const uint32 LM20_UNCLEN = 17;
	public const uint32 LM20_NNLEN = 12;
	public const uint32 SNLEN = 80;
	public const uint32 LM20_SNLEN = 15;
	public const uint32 STXTLEN = 256;
	public const uint32 LM20_STXTLEN = 63;
	public const uint32 PATHLEN = 256;
	public const uint32 LM20_PATHLEN = 256;
	public const uint32 DEVLEN = 80;
	public const uint32 LM20_DEVLEN = 8;
	public const uint32 EVLEN = 16;
	public const uint32 UNLEN = 256;
	public const uint32 LM20_UNLEN = 20;
	public const uint32 GNLEN = 256;
	public const uint32 LM20_GNLEN = 20;
	public const uint32 PWLEN = 256;
	public const uint32 LM20_PWLEN = 14;
	public const uint32 SHPWLEN = 8;
	public const uint32 CLTYPE_LEN = 12;
	public const uint32 MAXCOMMENTSZ = 256;
	public const uint32 LM20_MAXCOMMENTSZ = 48;
	public const uint32 QNLEN = 80;
	public const uint32 LM20_QNLEN = 12;
	public const uint32 ALERTSZ = 128;
	public const uint32 NETBIOS_NAME_LEN = 16;
	public const uint32 MAX_PREFERRED_LENGTH = 4294967295;
	public const uint32 CRYPT_KEY_LEN = 7;
	public const uint32 CRYPT_TXT_LEN = 8;
	public const uint32 ENCRYPTED_PWLEN = 16;
	public const uint32 SESSION_PWLEN = 24;
	public const uint32 SESSION_CRYPT_KLEN = 21;
	public const uint32 PARMNUM_ALL = 0;
	public const uint32 PARM_ERROR_UNKNOWN = 4294967295;
	public const uint32 PARM_ERROR_NONE = 0;
	public const uint32 PARMNUM_BASE_INFOLEVEL = 1000;
	public const String MESSAGE_FILENAME = "NETMSG";
	public const String OS2MSG_FILENAME = "BASE";
	public const String HELP_MSG_FILENAME = "NETH";
	public const String BACKUP_MSG_FILENAME = "BAK.MSG";
	public const uint32 PLATFORM_ID_DOS = 300;
	public const uint32 PLATFORM_ID_OS2 = 400;
	public const uint32 PLATFORM_ID_NT = 500;
	public const uint32 PLATFORM_ID_OSF = 600;
	public const uint32 PLATFORM_ID_VMS = 700;
	public const uint32 MIN_LANMAN_MESSAGE_ID = 2100;
	public const uint32 MAX_LANMAN_MESSAGE_ID = 5899;
	public const uint32 NERR_Success = 0;
	public const uint32 NERR_NetNotStarted = 2102;
	public const uint32 NERR_UnknownServer = 2103;
	public const uint32 NERR_ShareMem = 2104;
	public const uint32 NERR_NoNetworkResource = 2105;
	public const uint32 NERR_RemoteOnly = 2106;
	public const uint32 NERR_DevNotRedirected = 2107;
	public const uint32 NERR_ServerNotStarted = 2114;
	public const uint32 NERR_ItemNotFound = 2115;
	public const uint32 NERR_UnknownDevDir = 2116;
	public const uint32 NERR_RedirectedPath = 2117;
	public const uint32 NERR_DuplicateShare = 2118;
	public const uint32 NERR_NoRoom = 2119;
	public const uint32 NERR_TooManyItems = 2121;
	public const uint32 NERR_InvalidMaxUsers = 2122;
	public const uint32 NERR_BufTooSmall = 2123;
	public const uint32 NERR_RemoteErr = 2127;
	public const uint32 NERR_LanmanIniError = 2131;
	public const uint32 NERR_NetworkError = 2136;
	public const uint32 NERR_WkstaInconsistentState = 2137;
	public const uint32 NERR_WkstaNotStarted = 2138;
	public const uint32 NERR_BrowserNotStarted = 2139;
	public const uint32 NERR_InternalError = 2140;
	public const uint32 NERR_BadTransactConfig = 2141;
	public const uint32 NERR_InvalidAPI = 2142;
	public const uint32 NERR_BadEventName = 2143;
	public const uint32 NERR_DupNameReboot = 2144;
	public const uint32 NERR_CfgCompNotFound = 2146;
	public const uint32 NERR_CfgParamNotFound = 2147;
	public const uint32 NERR_LineTooLong = 2149;
	public const uint32 NERR_QNotFound = 2150;
	public const uint32 NERR_JobNotFound = 2151;
	public const uint32 NERR_DestNotFound = 2152;
	public const uint32 NERR_DestExists = 2153;
	public const uint32 NERR_QExists = 2154;
	public const uint32 NERR_QNoRoom = 2155;
	public const uint32 NERR_JobNoRoom = 2156;
	public const uint32 NERR_DestNoRoom = 2157;
	public const uint32 NERR_DestIdle = 2158;
	public const uint32 NERR_DestInvalidOp = 2159;
	public const uint32 NERR_ProcNoRespond = 2160;
	public const uint32 NERR_SpoolerNotLoaded = 2161;
	public const uint32 NERR_DestInvalidState = 2162;
	public const uint32 NERR_QInvalidState = 2163;
	public const uint32 NERR_JobInvalidState = 2164;
	public const uint32 NERR_SpoolNoMemory = 2165;
	public const uint32 NERR_DriverNotFound = 2166;
	public const uint32 NERR_DataTypeInvalid = 2167;
	public const uint32 NERR_ProcNotFound = 2168;
	public const uint32 NERR_ServiceTableLocked = 2180;
	public const uint32 NERR_ServiceTableFull = 2181;
	public const uint32 NERR_ServiceInstalled = 2182;
	public const uint32 NERR_ServiceEntryLocked = 2183;
	public const uint32 NERR_ServiceNotInstalled = 2184;
	public const uint32 NERR_BadServiceName = 2185;
	public const uint32 NERR_ServiceCtlTimeout = 2186;
	public const uint32 NERR_ServiceCtlBusy = 2187;
	public const uint32 NERR_BadServiceProgName = 2188;
	public const uint32 NERR_ServiceNotCtrl = 2189;
	public const uint32 NERR_ServiceKillProc = 2190;
	public const uint32 NERR_ServiceCtlNotValid = 2191;
	public const uint32 NERR_NotInDispatchTbl = 2192;
	public const uint32 NERR_BadControlRecv = 2193;
	public const uint32 NERR_ServiceNotStarting = 2194;
	public const uint32 NERR_AlreadyLoggedOn = 2200;
	public const uint32 NERR_NotLoggedOn = 2201;
	public const uint32 NERR_BadUsername = 2202;
	public const uint32 NERR_BadPassword = 2203;
	public const uint32 NERR_UnableToAddName_W = 2204;
	public const uint32 NERR_UnableToAddName_F = 2205;
	public const uint32 NERR_UnableToDelName_W = 2206;
	public const uint32 NERR_UnableToDelName_F = 2207;
	public const uint32 NERR_LogonsPaused = 2209;
	public const uint32 NERR_LogonServerConflict = 2210;
	public const uint32 NERR_LogonNoUserPath = 2211;
	public const uint32 NERR_LogonScriptError = 2212;
	public const uint32 NERR_StandaloneLogon = 2214;
	public const uint32 NERR_LogonServerNotFound = 2215;
	public const uint32 NERR_LogonDomainExists = 2216;
	public const uint32 NERR_NonValidatedLogon = 2217;
	public const uint32 NERR_ACFNotFound = 2219;
	public const uint32 NERR_GroupNotFound = 2220;
	public const uint32 NERR_UserNotFound = 2221;
	public const uint32 NERR_ResourceNotFound = 2222;
	public const uint32 NERR_GroupExists = 2223;
	public const uint32 NERR_UserExists = 2224;
	public const uint32 NERR_ResourceExists = 2225;
	public const uint32 NERR_NotPrimary = 2226;
	public const uint32 NERR_ACFNotLoaded = 2227;
	public const uint32 NERR_ACFNoRoom = 2228;
	public const uint32 NERR_ACFFileIOFail = 2229;
	public const uint32 NERR_ACFTooManyLists = 2230;
	public const uint32 NERR_UserLogon = 2231;
	public const uint32 NERR_ACFNoParent = 2232;
	public const uint32 NERR_CanNotGrowSegment = 2233;
	public const uint32 NERR_SpeGroupOp = 2234;
	public const uint32 NERR_NotInCache = 2235;
	public const uint32 NERR_UserInGroup = 2236;
	public const uint32 NERR_UserNotInGroup = 2237;
	public const uint32 NERR_AccountUndefined = 2238;
	public const uint32 NERR_AccountExpired = 2239;
	public const uint32 NERR_InvalidWorkstation = 2240;
	public const uint32 NERR_InvalidLogonHours = 2241;
	public const uint32 NERR_PasswordCantChange = 2243;
	public const uint32 NERR_PasswordHistConflict = 2244;
	public const uint32 NERR_PasswordTooShort = 2245;
	public const uint32 NERR_PasswordTooRecent = 2246;
	public const uint32 NERR_InvalidDatabase = 2247;
	public const uint32 NERR_DatabaseUpToDate = 2248;
	public const uint32 NERR_SyncRequired = 2249;
	public const uint32 NERR_UseNotFound = 2250;
	public const uint32 NERR_BadAsgType = 2251;
	public const uint32 NERR_DeviceIsShared = 2252;
	public const uint32 NERR_SameAsComputerName = 2253;
	public const uint32 NERR_NoComputerName = 2270;
	public const uint32 NERR_MsgAlreadyStarted = 2271;
	public const uint32 NERR_MsgInitFailed = 2272;
	public const uint32 NERR_NameNotFound = 2273;
	public const uint32 NERR_AlreadyForwarded = 2274;
	public const uint32 NERR_AddForwarded = 2275;
	public const uint32 NERR_AlreadyExists = 2276;
	public const uint32 NERR_TooManyNames = 2277;
	public const uint32 NERR_DelComputerName = 2278;
	public const uint32 NERR_LocalForward = 2279;
	public const uint32 NERR_GrpMsgProcessor = 2280;
	public const uint32 NERR_PausedRemote = 2281;
	public const uint32 NERR_BadReceive = 2282;
	public const uint32 NERR_NameInUse = 2283;
	public const uint32 NERR_MsgNotStarted = 2284;
	public const uint32 NERR_NotLocalName = 2285;
	public const uint32 NERR_NoForwardName = 2286;
	public const uint32 NERR_RemoteFull = 2287;
	public const uint32 NERR_NameNotForwarded = 2288;
	public const uint32 NERR_TruncatedBroadcast = 2289;
	public const uint32 NERR_InvalidDevice = 2294;
	public const uint32 NERR_WriteFault = 2295;
	public const uint32 NERR_DuplicateName = 2297;
	public const uint32 NERR_DeleteLater = 2298;
	public const uint32 NERR_IncompleteDel = 2299;
	public const uint32 NERR_MultipleNets = 2300;
	public const uint32 NERR_NetNameNotFound = 2310;
	public const uint32 NERR_DeviceNotShared = 2311;
	public const uint32 NERR_ClientNameNotFound = 2312;
	public const uint32 NERR_FileIdNotFound = 2314;
	public const uint32 NERR_ExecFailure = 2315;
	public const uint32 NERR_TmpFile = 2316;
	public const uint32 NERR_TooMuchData = 2317;
	public const uint32 NERR_DeviceShareConflict = 2318;
	public const uint32 NERR_BrowserTableIncomplete = 2319;
	public const uint32 NERR_NotLocalDomain = 2320;
	public const uint32 NERR_IsDfsShare = 2321;
	public const uint32 NERR_DevInvalidOpCode = 2331;
	public const uint32 NERR_DevNotFound = 2332;
	public const uint32 NERR_DevNotOpen = 2333;
	public const uint32 NERR_BadQueueDevString = 2334;
	public const uint32 NERR_BadQueuePriority = 2335;
	public const uint32 NERR_NoCommDevs = 2337;
	public const uint32 NERR_QueueNotFound = 2338;
	public const uint32 NERR_BadDevString = 2340;
	public const uint32 NERR_BadDev = 2341;
	public const uint32 NERR_InUseBySpooler = 2342;
	public const uint32 NERR_CommDevInUse = 2343;
	public const uint32 NERR_InvalidComputer = 2351;
	public const uint32 NERR_MaxLenExceeded = 2354;
	public const uint32 NERR_BadComponent = 2356;
	public const uint32 NERR_CantType = 2357;
	public const uint32 NERR_TooManyEntries = 2362;
	public const uint32 NERR_ProfileFileTooBig = 2370;
	public const uint32 NERR_ProfileOffset = 2371;
	public const uint32 NERR_ProfileCleanup = 2372;
	public const uint32 NERR_ProfileUnknownCmd = 2373;
	public const uint32 NERR_ProfileLoadErr = 2374;
	public const uint32 NERR_ProfileSaveErr = 2375;
	public const uint32 NERR_LogOverflow = 2377;
	public const uint32 NERR_LogFileChanged = 2378;
	public const uint32 NERR_LogFileCorrupt = 2379;
	public const uint32 NERR_SourceIsDir = 2380;
	public const uint32 NERR_BadSource = 2381;
	public const uint32 NERR_BadDest = 2382;
	public const uint32 NERR_DifferentServers = 2383;
	public const uint32 NERR_RunSrvPaused = 2385;
	public const uint32 NERR_ErrCommRunSrv = 2389;
	public const uint32 NERR_ErrorExecingGhost = 2391;
	public const uint32 NERR_ShareNotFound = 2392;
	public const uint32 NERR_InvalidLana = 2400;
	public const uint32 NERR_OpenFiles = 2401;
	public const uint32 NERR_ActiveConns = 2402;
	public const uint32 NERR_BadPasswordCore = 2403;
	public const uint32 NERR_DevInUse = 2404;
	public const uint32 NERR_LocalDrive = 2405;
	public const uint32 NERR_AlertExists = 2430;
	public const uint32 NERR_TooManyAlerts = 2431;
	public const uint32 NERR_NoSuchAlert = 2432;
	public const uint32 NERR_BadRecipient = 2433;
	public const uint32 NERR_AcctLimitExceeded = 2434;
	public const uint32 NERR_InvalidLogSeek = 2440;
	public const uint32 NERR_BadUasConfig = 2450;
	public const uint32 NERR_InvalidUASOp = 2451;
	public const uint32 NERR_LastAdmin = 2452;
	public const uint32 NERR_DCNotFound = 2453;
	public const uint32 NERR_LogonTrackingError = 2454;
	public const uint32 NERR_NetlogonNotStarted = 2455;
	public const uint32 NERR_CanNotGrowUASFile = 2456;
	public const uint32 NERR_TimeDiffAtDC = 2457;
	public const uint32 NERR_PasswordMismatch = 2458;
	public const uint32 NERR_NoSuchServer = 2460;
	public const uint32 NERR_NoSuchSession = 2461;
	public const uint32 NERR_NoSuchConnection = 2462;
	public const uint32 NERR_TooManyServers = 2463;
	public const uint32 NERR_TooManySessions = 2464;
	public const uint32 NERR_TooManyConnections = 2465;
	public const uint32 NERR_TooManyFiles = 2466;
	public const uint32 NERR_NoAlternateServers = 2467;
	public const uint32 NERR_TryDownLevel = 2470;
	public const uint32 NERR_UPSDriverNotStarted = 2480;
	public const uint32 NERR_UPSInvalidConfig = 2481;
	public const uint32 NERR_UPSInvalidCommPort = 2482;
	public const uint32 NERR_UPSSignalAsserted = 2483;
	public const uint32 NERR_UPSShutdownFailed = 2484;
	public const uint32 NERR_BadDosRetCode = 2500;
	public const uint32 NERR_ProgNeedsExtraMem = 2501;
	public const uint32 NERR_BadDosFunction = 2502;
	public const uint32 NERR_RemoteBootFailed = 2503;
	public const uint32 NERR_BadFileCheckSum = 2504;
	public const uint32 NERR_NoRplBootSystem = 2505;
	public const uint32 NERR_RplLoadrNetBiosErr = 2506;
	public const uint32 NERR_RplLoadrDiskErr = 2507;
	public const uint32 NERR_ImageParamErr = 2508;
	public const uint32 NERR_TooManyImageParams = 2509;
	public const uint32 NERR_NonDosFloppyUsed = 2510;
	public const uint32 NERR_RplBootRestart = 2511;
	public const uint32 NERR_RplSrvrCallFailed = 2512;
	public const uint32 NERR_CantConnectRplSrvr = 2513;
	public const uint32 NERR_CantOpenImageFile = 2514;
	public const uint32 NERR_CallingRplSrvr = 2515;
	public const uint32 NERR_StartingRplBoot = 2516;
	public const uint32 NERR_RplBootServiceTerm = 2517;
	public const uint32 NERR_RplBootStartFailed = 2518;
	public const uint32 NERR_RPL_CONNECTED = 2519;
	public const uint32 NERR_BrowserConfiguredToNotRun = 2550;
	public const uint32 NERR_RplNoAdaptersStarted = 2610;
	public const uint32 NERR_RplBadRegistry = 2611;
	public const uint32 NERR_RplBadDatabase = 2612;
	public const uint32 NERR_RplRplfilesShare = 2613;
	public const uint32 NERR_RplNotRplServer = 2614;
	public const uint32 NERR_RplCannotEnum = 2615;
	public const uint32 NERR_RplWkstaInfoCorrupted = 2616;
	public const uint32 NERR_RplWkstaNotFound = 2617;
	public const uint32 NERR_RplWkstaNameUnavailable = 2618;
	public const uint32 NERR_RplProfileInfoCorrupted = 2619;
	public const uint32 NERR_RplProfileNotFound = 2620;
	public const uint32 NERR_RplProfileNameUnavailable = 2621;
	public const uint32 NERR_RplProfileNotEmpty = 2622;
	public const uint32 NERR_RplConfigInfoCorrupted = 2623;
	public const uint32 NERR_RplConfigNotFound = 2624;
	public const uint32 NERR_RplAdapterInfoCorrupted = 2625;
	public const uint32 NERR_RplInternal = 2626;
	public const uint32 NERR_RplVendorInfoCorrupted = 2627;
	public const uint32 NERR_RplBootInfoCorrupted = 2628;
	public const uint32 NERR_RplWkstaNeedsUserAcct = 2629;
	public const uint32 NERR_RplNeedsRPLUSERAcct = 2630;
	public const uint32 NERR_RplBootNotFound = 2631;
	public const uint32 NERR_RplIncompatibleProfile = 2632;
	public const uint32 NERR_RplAdapterNameUnavailable = 2633;
	public const uint32 NERR_RplConfigNotEmpty = 2634;
	public const uint32 NERR_RplBootInUse = 2635;
	public const uint32 NERR_RplBackupDatabase = 2636;
	public const uint32 NERR_RplAdapterNotFound = 2637;
	public const uint32 NERR_RplVendorNotFound = 2638;
	public const uint32 NERR_RplVendorNameUnavailable = 2639;
	public const uint32 NERR_RplBootNameUnavailable = 2640;
	public const uint32 NERR_RplConfigNameUnavailable = 2641;
	public const uint32 NERR_DfsInternalCorruption = 2660;
	public const uint32 NERR_DfsVolumeDataCorrupt = 2661;
	public const uint32 NERR_DfsNoSuchVolume = 2662;
	public const uint32 NERR_DfsVolumeAlreadyExists = 2663;
	public const uint32 NERR_DfsAlreadyShared = 2664;
	public const uint32 NERR_DfsNoSuchShare = 2665;
	public const uint32 NERR_DfsNotALeafVolume = 2666;
	public const uint32 NERR_DfsLeafVolume = 2667;
	public const uint32 NERR_DfsVolumeHasMultipleServers = 2668;
	public const uint32 NERR_DfsCantCreateJunctionPoint = 2669;
	public const uint32 NERR_DfsServerNotDfsAware = 2670;
	public const uint32 NERR_DfsBadRenamePath = 2671;
	public const uint32 NERR_DfsVolumeIsOffline = 2672;
	public const uint32 NERR_DfsNoSuchServer = 2673;
	public const uint32 NERR_DfsCyclicalName = 2674;
	public const uint32 NERR_DfsNotSupportedInServerDfs = 2675;
	public const uint32 NERR_DfsDuplicateService = 2676;
	public const uint32 NERR_DfsCantRemoveLastServerShare = 2677;
	public const uint32 NERR_DfsVolumeIsInterDfs = 2678;
	public const uint32 NERR_DfsInconsistent = 2679;
	public const uint32 NERR_DfsServerUpgraded = 2680;
	public const uint32 NERR_DfsDataIsIdentical = 2681;
	public const uint32 NERR_DfsCantRemoveDfsRoot = 2682;
	public const uint32 NERR_DfsChildOrParentInDfs = 2683;
	public const uint32 NERR_DfsInternalError = 2690;
	public const uint32 NERR_SetupAlreadyJoined = 2691;
	public const uint32 NERR_SetupNotJoined = 2692;
	public const uint32 NERR_SetupDomainController = 2693;
	public const uint32 NERR_DefaultJoinRequired = 2694;
	public const uint32 NERR_InvalidWorkgroupName = 2695;
	public const uint32 NERR_NameUsesIncompatibleCodePage = 2696;
	public const uint32 NERR_ComputerAccountNotFound = 2697;
	public const uint32 NERR_PersonalSku = 2698;
	public const uint32 NERR_SetupCheckDNSConfig = 2699;
	public const uint32 NERR_AlreadyCloudDomainJoined = 2700;
	public const uint32 NERR_PasswordMustChange = 2701;
	public const uint32 NERR_AccountLockedOut = 2702;
	public const uint32 NERR_PasswordTooLong = 2703;
	public const uint32 NERR_PasswordNotComplexEnough = 2704;
	public const uint32 NERR_PasswordFilterError = 2705;
	public const uint32 NERR_NoOfflineJoinInfo = 2709;
	public const uint32 NERR_BadOfflineJoinInfo = 2710;
	public const uint32 NERR_CantCreateJoinInfo = 2711;
	public const uint32 NERR_BadDomainJoinInfo = 2712;
	public const uint32 NERR_JoinPerformedMustRestart = 2713;
	public const uint32 NERR_NoJoinPending = 2714;
	public const uint32 NERR_ValuesNotSet = 2715;
	public const uint32 NERR_CantVerifyHostname = 2716;
	public const uint32 NERR_CantLoadOfflineHive = 2717;
	public const uint32 NERR_ConnectionInsecure = 2718;
	public const uint32 NERR_ProvisioningBlobUnsupported = 2719;
	public const uint32 NERR_DS8DCRequired = 2720;
	public const uint32 NERR_LDAPCapableDCRequired = 2721;
	public const uint32 NERR_DS8DCNotFound = 2722;
	public const uint32 NERR_TargetVersionUnsupported = 2723;
	public const uint32 NERR_InvalidMachineNameForJoin = 2724;
	public const uint32 NERR_DS9DCNotFound = 2725;
	public const uint32 NERR_PlainTextSecretsRequired = 2726;
	public const uint32 NERR_CannotUnjoinAadDomain = 2727;
	public const uint32 MAX_NERR = 2999;
	public const uint32 UF_TEMP_DUPLICATE_ACCOUNT = 256;
	public const uint32 UF_NORMAL_ACCOUNT = 512;
	public const uint32 UF_INTERDOMAIN_TRUST_ACCOUNT = 2048;
	public const uint32 UF_WORKSTATION_TRUST_ACCOUNT = 4096;
	public const uint32 UF_SERVER_TRUST_ACCOUNT = 8192;
	public const uint32 UF_MNS_LOGON_ACCOUNT = 131072;
	public const uint32 UF_NO_AUTH_DATA_REQUIRED = 33554432;
	public const uint32 UF_PARTIAL_SECRETS_ACCOUNT = 67108864;
	public const uint32 UF_USE_AES_KEYS = 134217728;
	public const uint32 LG_INCLUDE_INDIRECT = 1;
	public const uint32 USER_NAME_PARMNUM = 1;
	public const uint32 USER_PASSWORD_PARMNUM = 3;
	public const uint32 USER_PASSWORD_AGE_PARMNUM = 4;
	public const uint32 USER_PRIV_PARMNUM = 5;
	public const uint32 USER_HOME_DIR_PARMNUM = 6;
	public const uint32 USER_COMMENT_PARMNUM = 7;
	public const uint32 USER_FLAGS_PARMNUM = 8;
	public const uint32 USER_SCRIPT_PATH_PARMNUM = 9;
	public const uint32 USER_AUTH_FLAGS_PARMNUM = 10;
	public const uint32 USER_FULL_NAME_PARMNUM = 11;
	public const uint32 USER_USR_COMMENT_PARMNUM = 12;
	public const uint32 USER_PARMS_PARMNUM = 13;
	public const uint32 USER_WORKSTATIONS_PARMNUM = 14;
	public const uint32 USER_LAST_LOGON_PARMNUM = 15;
	public const uint32 USER_LAST_LOGOFF_PARMNUM = 16;
	public const uint32 USER_ACCT_EXPIRES_PARMNUM = 17;
	public const uint32 USER_MAX_STORAGE_PARMNUM = 18;
	public const uint32 USER_UNITS_PER_WEEK_PARMNUM = 19;
	public const uint32 USER_LOGON_HOURS_PARMNUM = 20;
	public const uint32 USER_PAD_PW_COUNT_PARMNUM = 21;
	public const uint32 USER_NUM_LOGONS_PARMNUM = 22;
	public const uint32 USER_LOGON_SERVER_PARMNUM = 23;
	public const uint32 USER_COUNTRY_CODE_PARMNUM = 24;
	public const uint32 USER_CODE_PAGE_PARMNUM = 25;
	public const uint32 USER_PRIMARY_GROUP_PARMNUM = 51;
	public const uint32 USER_PROFILE = 52;
	public const uint32 USER_PROFILE_PARMNUM = 52;
	public const uint32 USER_HOME_DIR_DRIVE_PARMNUM = 53;
	public const String NULL_USERSETINFO_PASSWD = "              ";
	public const uint32 UNITS_PER_DAY = 24;
	public const uint32 USER_PRIV_MASK = 3;
	public const uint32 MAX_PASSWD_LEN = 256;
	public const uint32 DEF_MIN_PWLEN = 6;
	public const uint32 DEF_PWUNIQUENESS = 5;
	public const uint32 DEF_MAX_PWHIST = 8;
	public const uint32 DEF_MAX_BADPW = 0;
	public const uint32 VALIDATED_LOGON = 0;
	public const uint32 PASSWORD_EXPIRED = 2;
	public const uint32 NON_VALIDATED_LOGON = 3;
	public const uint32 VALID_LOGOFF = 1;
	public const uint32 MODALS_MIN_PASSWD_LEN_PARMNUM = 1;
	public const uint32 MODALS_MAX_PASSWD_AGE_PARMNUM = 2;
	public const uint32 MODALS_MIN_PASSWD_AGE_PARMNUM = 3;
	public const uint32 MODALS_FORCE_LOGOFF_PARMNUM = 4;
	public const uint32 MODALS_PASSWD_HIST_LEN_PARMNUM = 5;
	public const uint32 MODALS_ROLE_PARMNUM = 6;
	public const uint32 MODALS_PRIMARY_PARMNUM = 7;
	public const uint32 MODALS_DOMAIN_NAME_PARMNUM = 8;
	public const uint32 MODALS_DOMAIN_ID_PARMNUM = 9;
	public const uint32 MODALS_LOCKOUT_DURATION_PARMNUM = 10;
	public const uint32 MODALS_LOCKOUT_OBSERVATION_WINDOW_PARMNUM = 11;
	public const uint32 MODALS_LOCKOUT_THRESHOLD_PARMNUM = 12;
	public const uint32 GROUPIDMASK = 32768;
	public const String GROUP_SPECIALGRP_USERS = "USERS";
	public const String GROUP_SPECIALGRP_ADMINS = "ADMINS";
	public const String GROUP_SPECIALGRP_GUESTS = "GUESTS";
	public const String GROUP_SPECIALGRP_LOCAL = "LOCAL";
	public const uint32 GROUP_ALL_PARMNUM = 0;
	public const uint32 GROUP_NAME_PARMNUM = 1;
	public const uint32 GROUP_COMMENT_PARMNUM = 2;
	public const uint32 GROUP_ATTRIBUTES_PARMNUM = 3;
	public const uint32 LOCALGROUP_NAME_PARMNUM = 1;
	public const uint32 LOCALGROUP_COMMENT_PARMNUM = 2;
	public const uint32 MAXPERMENTRIES = 64;
	public const uint32 ACCESS_NONE = 0;
	public const uint32 ACCESS_GROUP = 32768;
	public const uint32 ACCESS_AUDIT = 1;
	public const uint32 ACCESS_SUCCESS_OPEN = 16;
	public const uint32 ACCESS_SUCCESS_WRITE = 32;
	public const uint32 ACCESS_SUCCESS_DELETE = 64;
	public const uint32 ACCESS_SUCCESS_ACL = 128;
	public const uint32 ACCESS_SUCCESS_MASK = 240;
	public const uint32 ACCESS_FAIL_OPEN = 256;
	public const uint32 ACCESS_FAIL_WRITE = 512;
	public const uint32 ACCESS_FAIL_DELETE = 1024;
	public const uint32 ACCESS_FAIL_ACL = 2048;
	public const uint32 ACCESS_FAIL_MASK = 3840;
	public const uint32 ACCESS_FAIL_SHIFT = 4;
	public const uint32 ACCESS_RESOURCE_NAME_PARMNUM = 1;
	public const uint32 ACCESS_ATTR_PARMNUM = 2;
	public const uint32 ACCESS_COUNT_PARMNUM = 3;
	public const uint32 ACCESS_ACCESS_LIST_PARMNUM = 4;
	public const String ACCESS_LETTERS = "RWCXDAP         ";
	public const uint32 NET_VALIDATE_PASSWORD_LAST_SET = 1;
	public const uint32 NET_VALIDATE_BAD_PASSWORD_TIME = 2;
	public const uint32 NET_VALIDATE_LOCKOUT_TIME = 4;
	public const uint32 NET_VALIDATE_BAD_PASSWORD_COUNT = 8;
	public const uint32 NET_VALIDATE_PASSWORD_HISTORY_LENGTH = 16;
	public const uint32 NET_VALIDATE_PASSWORD_HISTORY = 32;
	public const uint32 NETLOGON_CONTROL_QUERY = 1;
	public const uint32 NETLOGON_CONTROL_REPLICATE = 2;
	public const uint32 NETLOGON_CONTROL_SYNCHRONIZE = 3;
	public const uint32 NETLOGON_CONTROL_PDC_REPLICATE = 4;
	public const uint32 NETLOGON_CONTROL_REDISCOVER = 5;
	public const uint32 NETLOGON_CONTROL_TC_QUERY = 6;
	public const uint32 NETLOGON_CONTROL_TRANSPORT_NOTIFY = 7;
	public const uint32 NETLOGON_CONTROL_FIND_USER = 8;
	public const uint32 NETLOGON_CONTROL_CHANGE_PASSWORD = 9;
	public const uint32 NETLOGON_CONTROL_TC_VERIFY = 10;
	public const uint32 NETLOGON_CONTROL_FORCE_DNS_REG = 11;
	public const uint32 NETLOGON_CONTROL_QUERY_DNS_REG = 12;
	public const uint32 NETLOGON_CONTROL_QUERY_ENC_TYPES = 13;
	public const uint32 NETLOGON_CONTROL_UNLOAD_NETLOGON_DLL = 65531;
	public const uint32 NETLOGON_CONTROL_BACKUP_CHANGE_LOG = 65532;
	public const uint32 NETLOGON_CONTROL_TRUNCATE_LOG = 65533;
	public const uint32 NETLOGON_CONTROL_SET_DBFLAG = 65534;
	public const uint32 NETLOGON_CONTROL_BREAKPOINT = 65535;
	public const uint32 NETLOGON_REPLICATION_NEEDED = 1;
	public const uint32 NETLOGON_REPLICATION_IN_PROGRESS = 2;
	public const uint32 NETLOGON_FULL_SYNC_REPLICATION = 4;
	public const uint32 NETLOGON_REDO_NEEDED = 8;
	public const uint32 NETLOGON_HAS_IP = 16;
	public const uint32 NETLOGON_HAS_TIMESERV = 32;
	public const uint32 NETLOGON_DNS_UPDATE_FAILURE = 64;
	public const uint32 NETLOGON_VERIFY_STATUS_RETURNED = 128;
	public const String SERVICE_ACCOUNT_PASSWORD = "_SA_{262E99C9-6160-4871-ACEC-4E61736B6F21}";
	public const String SERVICE_ACCOUNT_SECRET_PREFIX = "_SC_{262E99C9-6160-4871-ACEC-4E61736B6F21}_";
	public const Guid ServiceAccountPasswordGUID = .(0x262e99c9, 0x6160, 0x4871, 0xac, 0xec, 0x4e, 0x61, 0x73, 0x6b, 0x6f, 0x21);
	public const int32 SERVICE_ACCOUNT_FLAG_LINK_TO_HOST_ONLY = 1;
	public const int32 SERVICE_ACCOUNT_FLAG_ADD_AGAINST_RODC = 2;
	public const int32 SERVICE_ACCOUNT_FLAG_UNLINK_FROM_HOST_ONLY = 1;
	public const int32 SERVICE_ACCOUNT_FLAG_REMOVE_OFFLINE = 2;
	public const String ALERTER_MAILSLOT = "\\\\.\\MAILSLOT\\Alerter";
	public const String ALERT_PRINT_EVENT = "PRINTING";
	public const String ALERT_MESSAGE_EVENT = "MESSAGE";
	public const String ALERT_ERRORLOG_EVENT = "ERRORLOG";
	public const String ALERT_ADMIN_EVENT = "ADMIN";
	public const String ALERT_USER_EVENT = "USER";
	public const uint32 PRJOB_QSTATUS = 3;
	public const uint32 PRJOB_DEVSTATUS = 508;
	public const uint32 PRJOB_COMPLETE = 4;
	public const uint32 PRJOB_INTERV = 8;
	public const uint32 PRJOB_ERROR = 16;
	public const uint32 PRJOB_DESTOFFLINE = 32;
	public const uint32 PRJOB_DESTPAUSED = 64;
	public const uint32 PRJOB_NOTIFY = 128;
	public const uint32 PRJOB_DESTNOPAPER = 256;
	public const uint32 PRJOB_DELETED = 32768;
	public const uint32 PRJOB_QS_QUEUED = 0;
	public const uint32 PRJOB_QS_PAUSED = 1;
	public const uint32 PRJOB_QS_SPOOLING = 2;
	public const uint32 PRJOB_QS_PRINTING = 3;
	public const uint32 JOB_RUN_PERIODICALLY = 1;
	public const uint32 JOB_EXEC_ERROR = 2;
	public const uint32 JOB_RUNS_TODAY = 4;
	public const uint32 JOB_ADD_CURRENT_DATE = 8;
	public const uint32 JOB_NONINTERACTIVE = 16;
	public const uint32 LOGFLAGS_FORWARD = 0;
	public const uint32 LOGFLAGS_BACKWARD = 1;
	public const uint32 LOGFLAGS_SEEK = 2;
	public const uint32 ACTION_LOCKOUT = 0;
	public const uint32 ACTION_ADMINUNLOCK = 1;
	public const uint32 AE_SRVSTATUS = 0;
	public const uint32 AE_SESSLOGON = 1;
	public const uint32 AE_SESSLOGOFF = 2;
	public const uint32 AE_SESSPWERR = 3;
	public const uint32 AE_CONNSTART = 4;
	public const uint32 AE_CONNSTOP = 5;
	public const uint32 AE_CONNREJ = 6;
	public const uint32 AE_RESACCESS = 7;
	public const uint32 AE_RESACCESSREJ = 8;
	public const uint32 AE_CLOSEFILE = 9;
	public const uint32 AE_SERVICESTAT = 11;
	public const uint32 AE_ACLMOD = 12;
	public const uint32 AE_UASMOD = 13;
	public const uint32 AE_NETLOGON = 14;
	public const uint32 AE_NETLOGOFF = 15;
	public const uint32 AE_NETLOGDENIED = 16;
	public const uint32 AE_ACCLIMITEXCD = 17;
	public const uint32 AE_RESACCESS2 = 18;
	public const uint32 AE_ACLMODFAIL = 19;
	public const uint32 AE_LOCKOUT = 20;
	public const uint32 AE_GENERIC_TYPE = 21;
	public const uint32 AE_SRVSTART = 0;
	public const uint32 AE_SRVPAUSED = 1;
	public const uint32 AE_SRVCONT = 2;
	public const uint32 AE_SRVSTOP = 3;
	public const uint32 AE_GUEST = 0;
	public const uint32 AE_USER = 1;
	public const uint32 AE_ADMIN = 2;
	public const uint32 AE_NORMAL = 0;
	public const uint32 AE_USERLIMIT = 0;
	public const uint32 AE_GENERAL = 0;
	public const uint32 AE_ERROR = 1;
	public const uint32 AE_SESSDIS = 1;
	public const uint32 AE_BADPW = 1;
	public const uint32 AE_AUTODIS = 2;
	public const uint32 AE_UNSHARE = 2;
	public const uint32 AE_ADMINPRIVREQD = 2;
	public const uint32 AE_ADMINDIS = 3;
	public const uint32 AE_NOACCESSPERM = 3;
	public const uint32 AE_ACCRESTRICT = 4;
	public const uint32 AE_NORMAL_CLOSE = 0;
	public const uint32 AE_SES_CLOSE = 1;
	public const uint32 AE_ADMIN_CLOSE = 2;
	public const uint32 AE_LIM_UNKNOWN = 0;
	public const uint32 AE_LIM_LOGONHOURS = 1;
	public const uint32 AE_LIM_EXPIRED = 2;
	public const uint32 AE_LIM_INVAL_WKSTA = 3;
	public const uint32 AE_LIM_DISABLED = 4;
	public const uint32 AE_LIM_DELETED = 5;
	public const uint32 AE_MOD = 0;
	public const uint32 AE_DELETE = 1;
	public const uint32 AE_ADD = 2;
	public const uint32 AE_UAS_USER = 0;
	public const uint32 AE_UAS_GROUP = 1;
	public const uint32 AE_UAS_MODALS = 2;
	public const uint32 SVAUD_SERVICE = 1;
	public const uint32 SVAUD_GOODSESSLOGON = 6;
	public const uint32 SVAUD_BADSESSLOGON = 24;
	public const uint32 SVAUD_GOODNETLOGON = 96;
	public const uint32 SVAUD_BADNETLOGON = 384;
	public const uint32 SVAUD_GOODUSE = 1536;
	public const uint32 SVAUD_BADUSE = 6144;
	public const uint32 SVAUD_USERLIST = 8192;
	public const uint32 SVAUD_PERMISSIONS = 16384;
	public const uint32 SVAUD_RESOURCE = 32768;
	public const uint32 SVAUD_LOGONLIM = 65536;
	public const uint32 AA_AUDIT_ALL = 1;
	public const uint32 AA_A_OWNER = 4;
	public const uint32 AA_CLOSE = 8;
	public const uint32 AA_S_OPEN = 16;
	public const uint32 AA_S_WRITE = 32;
	public const uint32 AA_S_CREATE = 32;
	public const uint32 AA_S_DELETE = 64;
	public const uint32 AA_S_ACL = 128;
	public const uint32 AA_F_OPEN = 256;
	public const uint32 AA_F_WRITE = 512;
	public const uint32 AA_F_CREATE = 512;
	public const uint32 AA_F_DELETE = 1024;
	public const uint32 AA_F_ACL = 2048;
	public const uint32 AA_A_OPEN = 4096;
	public const uint32 AA_A_WRITE = 8192;
	public const uint32 AA_A_CREATE = 8192;
	public const uint32 AA_A_DELETE = 16384;
	public const uint32 AA_A_ACL = 32768;
	public const uint32 ERRLOG_BASE = 3100;
	public const uint32 NELOG_Internal_Error = 3100;
	public const uint32 NELOG_Resource_Shortage = 3101;
	public const uint32 NELOG_Unable_To_Lock_Segment = 3102;
	public const uint32 NELOG_Unable_To_Unlock_Segment = 3103;
	public const uint32 NELOG_Uninstall_Service = 3104;
	public const uint32 NELOG_Init_Exec_Fail = 3105;
	public const uint32 NELOG_Ncb_Error = 3106;
	public const uint32 NELOG_Net_Not_Started = 3107;
	public const uint32 NELOG_Ioctl_Error = 3108;
	public const uint32 NELOG_System_Semaphore = 3109;
	public const uint32 NELOG_Init_OpenCreate_Err = 3110;
	public const uint32 NELOG_NetBios = 3111;
	public const uint32 NELOG_SMB_Illegal = 3112;
	public const uint32 NELOG_Service_Fail = 3113;
	public const uint32 NELOG_Entries_Lost = 3114;
	public const uint32 NELOG_Init_Seg_Overflow = 3120;
	public const uint32 NELOG_Srv_No_Mem_Grow = 3121;
	public const uint32 NELOG_Access_File_Bad = 3122;
	public const uint32 NELOG_Srvnet_Not_Started = 3123;
	public const uint32 NELOG_Init_Chardev_Err = 3124;
	public const uint32 NELOG_Remote_API = 3125;
	public const uint32 NELOG_Ncb_TooManyErr = 3126;
	public const uint32 NELOG_Mailslot_err = 3127;
	public const uint32 NELOG_ReleaseMem_Alert = 3128;
	public const uint32 NELOG_AT_cannot_write = 3129;
	public const uint32 NELOG_Cant_Make_Msg_File = 3130;
	public const uint32 NELOG_Exec_Netservr_NoMem = 3131;
	public const uint32 NELOG_Server_Lock_Failure = 3132;
	public const uint32 NELOG_Msg_Shutdown = 3140;
	public const uint32 NELOG_Msg_Sem_Shutdown = 3141;
	public const uint32 NELOG_Msg_Log_Err = 3150;
	public const uint32 NELOG_VIO_POPUP_ERR = 3151;
	public const uint32 NELOG_Msg_Unexpected_SMB_Type = 3152;
	public const uint32 NELOG_Wksta_Infoseg = 3160;
	public const uint32 NELOG_Wksta_Compname = 3161;
	public const uint32 NELOG_Wksta_BiosThreadFailure = 3162;
	public const uint32 NELOG_Wksta_IniSeg = 3163;
	public const uint32 NELOG_Wksta_HostTab_Full = 3164;
	public const uint32 NELOG_Wksta_Bad_Mailslot_SMB = 3165;
	public const uint32 NELOG_Wksta_UASInit = 3166;
	public const uint32 NELOG_Wksta_SSIRelogon = 3167;
	public const uint32 NELOG_Build_Name = 3170;
	public const uint32 NELOG_Name_Expansion = 3171;
	public const uint32 NELOG_Message_Send = 3172;
	public const uint32 NELOG_Mail_Slt_Err = 3173;
	public const uint32 NELOG_AT_cannot_read = 3174;
	public const uint32 NELOG_AT_sched_err = 3175;
	public const uint32 NELOG_AT_schedule_file_created = 3176;
	public const uint32 NELOG_Srvnet_NB_Open = 3177;
	public const uint32 NELOG_AT_Exec_Err = 3178;
	public const uint32 NELOG_Lazy_Write_Err = 3180;
	public const uint32 NELOG_HotFix = 3181;
	public const uint32 NELOG_HardErr_From_Server = 3182;
	public const uint32 NELOG_LocalSecFail1 = 3183;
	public const uint32 NELOG_LocalSecFail2 = 3184;
	public const uint32 NELOG_LocalSecFail3 = 3185;
	public const uint32 NELOG_LocalSecGeneralFail = 3186;
	public const uint32 NELOG_NetWkSta_Internal_Error = 3190;
	public const uint32 NELOG_NetWkSta_No_Resource = 3191;
	public const uint32 NELOG_NetWkSta_SMB_Err = 3192;
	public const uint32 NELOG_NetWkSta_VC_Err = 3193;
	public const uint32 NELOG_NetWkSta_Stuck_VC_Err = 3194;
	public const uint32 NELOG_NetWkSta_NCB_Err = 3195;
	public const uint32 NELOG_NetWkSta_Write_Behind_Err = 3196;
	public const uint32 NELOG_NetWkSta_Reset_Err = 3197;
	public const uint32 NELOG_NetWkSta_Too_Many = 3198;
	public const uint32 NELOG_Srv_Thread_Failure = 3204;
	public const uint32 NELOG_Srv_Close_Failure = 3205;
	public const uint32 NELOG_ReplUserCurDir = 3206;
	public const uint32 NELOG_ReplCannotMasterDir = 3207;
	public const uint32 NELOG_ReplUpdateError = 3208;
	public const uint32 NELOG_ReplLostMaster = 3209;
	public const uint32 NELOG_NetlogonAuthDCFail = 3210;
	public const uint32 NELOG_ReplLogonFailed = 3211;
	public const uint32 NELOG_ReplNetErr = 3212;
	public const uint32 NELOG_ReplMaxFiles = 3213;
	public const uint32 NELOG_ReplMaxTreeDepth = 3214;
	public const uint32 NELOG_ReplBadMsg = 3215;
	public const uint32 NELOG_ReplSysErr = 3216;
	public const uint32 NELOG_ReplUserLoged = 3217;
	public const uint32 NELOG_ReplBadImport = 3218;
	public const uint32 NELOG_ReplBadExport = 3219;
	public const uint32 NELOG_ReplSignalFileErr = 3220;
	public const uint32 NELOG_DiskFT = 3221;
	public const uint32 NELOG_ReplAccessDenied = 3222;
	public const uint32 NELOG_NetlogonFailedPrimary = 3223;
	public const uint32 NELOG_NetlogonPasswdSetFailed = 3224;
	public const uint32 NELOG_NetlogonTrackingError = 3225;
	public const uint32 NELOG_NetlogonSyncError = 3226;
	public const uint32 NELOG_NetlogonRequireSignOrSealError = 3227;
	public const uint32 NELOG_UPS_PowerOut = 3230;
	public const uint32 NELOG_UPS_Shutdown = 3231;
	public const uint32 NELOG_UPS_CmdFileError = 3232;
	public const uint32 NELOG_UPS_CannotOpenDriver = 3233;
	public const uint32 NELOG_UPS_PowerBack = 3234;
	public const uint32 NELOG_UPS_CmdFileConfig = 3235;
	public const uint32 NELOG_UPS_CmdFileExec = 3236;
	public const uint32 NELOG_Missing_Parameter = 3250;
	public const uint32 NELOG_Invalid_Config_Line = 3251;
	public const uint32 NELOG_Invalid_Config_File = 3252;
	public const uint32 NELOG_File_Changed = 3253;
	public const uint32 NELOG_Files_Dont_Fit = 3254;
	public const uint32 NELOG_Wrong_DLL_Version = 3255;
	public const uint32 NELOG_Error_in_DLL = 3256;
	public const uint32 NELOG_System_Error = 3257;
	public const uint32 NELOG_FT_ErrLog_Too_Large = 3258;
	public const uint32 NELOG_FT_Update_In_Progress = 3259;
	public const uint32 NELOG_Joined_Domain = 3260;
	public const uint32 NELOG_Joined_Workgroup = 3261;
	public const uint32 NELOG_OEM_Code = 3299;
	public const uint32 ERRLOG2_BASE = 5700;
	public const uint32 NELOG_NetlogonSSIInitError = 5700;
	public const uint32 NELOG_NetlogonFailedToUpdateTrustList = 5701;
	public const uint32 NELOG_NetlogonFailedToAddRpcInterface = 5702;
	public const uint32 NELOG_NetlogonFailedToReadMailslot = 5703;
	public const uint32 NELOG_NetlogonFailedToRegisterSC = 5704;
	public const uint32 NELOG_NetlogonChangeLogCorrupt = 5705;
	public const uint32 NELOG_NetlogonFailedToCreateShare = 5706;
	public const uint32 NELOG_NetlogonDownLevelLogonFailed = 5707;
	public const uint32 NELOG_NetlogonDownLevelLogoffFailed = 5708;
	public const uint32 NELOG_NetlogonNTLogonFailed = 5709;
	public const uint32 NELOG_NetlogonNTLogoffFailed = 5710;
	public const uint32 NELOG_NetlogonPartialSyncCallSuccess = 5711;
	public const uint32 NELOG_NetlogonPartialSyncCallFailed = 5712;
	public const uint32 NELOG_NetlogonFullSyncCallSuccess = 5713;
	public const uint32 NELOG_NetlogonFullSyncCallFailed = 5714;
	public const uint32 NELOG_NetlogonPartialSyncSuccess = 5715;
	public const uint32 NELOG_NetlogonPartialSyncFailed = 5716;
	public const uint32 NELOG_NetlogonFullSyncSuccess = 5717;
	public const uint32 NELOG_NetlogonFullSyncFailed = 5718;
	public const uint32 NELOG_NetlogonAuthNoDomainController = 5719;
	public const uint32 NELOG_NetlogonAuthNoTrustLsaSecret = 5720;
	public const uint32 NELOG_NetlogonAuthNoTrustSamAccount = 5721;
	public const uint32 NELOG_NetlogonServerAuthFailed = 5722;
	public const uint32 NELOG_NetlogonServerAuthNoTrustSamAccount = 5723;
	public const uint32 NELOG_FailedToRegisterSC = 5724;
	public const uint32 NELOG_FailedToSetServiceStatus = 5725;
	public const uint32 NELOG_FailedToGetComputerName = 5726;
	public const uint32 NELOG_DriverNotLoaded = 5727;
	public const uint32 NELOG_NoTranportLoaded = 5728;
	public const uint32 NELOG_NetlogonFailedDomainDelta = 5729;
	public const uint32 NELOG_NetlogonFailedGlobalGroupDelta = 5730;
	public const uint32 NELOG_NetlogonFailedLocalGroupDelta = 5731;
	public const uint32 NELOG_NetlogonFailedUserDelta = 5732;
	public const uint32 NELOG_NetlogonFailedPolicyDelta = 5733;
	public const uint32 NELOG_NetlogonFailedTrustedDomainDelta = 5734;
	public const uint32 NELOG_NetlogonFailedAccountDelta = 5735;
	public const uint32 NELOG_NetlogonFailedSecretDelta = 5736;
	public const uint32 NELOG_NetlogonSystemError = 5737;
	public const uint32 NELOG_NetlogonDuplicateMachineAccounts = 5738;
	public const uint32 NELOG_NetlogonTooManyGlobalGroups = 5739;
	public const uint32 NELOG_NetlogonBrowserDriver = 5740;
	public const uint32 NELOG_NetlogonAddNameFailure = 5741;
	public const uint32 NELOG_RplMessages = 5742;
	public const uint32 NELOG_RplXnsBoot = 5743;
	public const uint32 NELOG_RplSystem = 5744;
	public const uint32 NELOG_RplWkstaTimeout = 5745;
	public const uint32 NELOG_RplWkstaFileOpen = 5746;
	public const uint32 NELOG_RplWkstaFileRead = 5747;
	public const uint32 NELOG_RplWkstaMemory = 5748;
	public const uint32 NELOG_RplWkstaFileChecksum = 5749;
	public const uint32 NELOG_RplWkstaFileLineCount = 5750;
	public const uint32 NELOG_RplWkstaBbcFile = 5751;
	public const uint32 NELOG_RplWkstaFileSize = 5752;
	public const uint32 NELOG_RplWkstaInternal = 5753;
	public const uint32 NELOG_RplWkstaWrongVersion = 5754;
	public const uint32 NELOG_RplWkstaNetwork = 5755;
	public const uint32 NELOG_RplAdapterResource = 5756;
	public const uint32 NELOG_RplFileCopy = 5757;
	public const uint32 NELOG_RplFileDelete = 5758;
	public const uint32 NELOG_RplFilePerms = 5759;
	public const uint32 NELOG_RplCheckConfigs = 5760;
	public const uint32 NELOG_RplCreateProfiles = 5761;
	public const uint32 NELOG_RplRegistry = 5762;
	public const uint32 NELOG_RplReplaceRPLDISK = 5763;
	public const uint32 NELOG_RplCheckSecurity = 5764;
	public const uint32 NELOG_RplBackupDatabase = 5765;
	public const uint32 NELOG_RplInitDatabase = 5766;
	public const uint32 NELOG_RplRestoreDatabaseFailure = 5767;
	public const uint32 NELOG_RplRestoreDatabaseSuccess = 5768;
	public const uint32 NELOG_RplInitRestoredDatabase = 5769;
	public const uint32 NELOG_NetlogonSessionTypeWrong = 5770;
	public const uint32 NELOG_RplUpgradeDBTo40 = 5771;
	public const uint32 NELOG_NetlogonLanmanBdcsNotAllowed = 5772;
	public const uint32 NELOG_NetlogonNoDynamicDns = 5773;
	public const uint32 NELOG_NetlogonDynamicDnsRegisterFailure = 5774;
	public const uint32 NELOG_NetlogonDynamicDnsDeregisterFailure = 5775;
	public const uint32 NELOG_NetlogonFailedFileCreate = 5776;
	public const uint32 NELOG_NetlogonGetSubnetToSite = 5777;
	public const uint32 NELOG_NetlogonNoSiteForClient = 5778;
	public const uint32 NELOG_NetlogonBadSiteName = 5779;
	public const uint32 NELOG_NetlogonBadSubnetName = 5780;
	public const uint32 NELOG_NetlogonDynamicDnsServerFailure = 5781;
	public const uint32 NELOG_NetlogonDynamicDnsFailure = 5782;
	public const uint32 NELOG_NetlogonRpcCallCancelled = 5783;
	public const uint32 NELOG_NetlogonDcSiteCovered = 5784;
	public const uint32 NELOG_NetlogonDcSiteNotCovered = 5785;
	public const uint32 NELOG_NetlogonGcSiteCovered = 5786;
	public const uint32 NELOG_NetlogonGcSiteNotCovered = 5787;
	public const uint32 NELOG_NetlogonFailedSpnUpdate = 5788;
	public const uint32 NELOG_NetlogonFailedDnsHostNameUpdate = 5789;
	public const uint32 NELOG_NetlogonAuthNoUplevelDomainController = 5790;
	public const uint32 NELOG_NetlogonAuthDomainDowngraded = 5791;
	public const uint32 NELOG_NetlogonNdncSiteCovered = 5792;
	public const uint32 NELOG_NetlogonNdncSiteNotCovered = 5793;
	public const uint32 NELOG_NetlogonDcOldSiteCovered = 5794;
	public const uint32 NELOG_NetlogonDcSiteNotCoveredAuto = 5795;
	public const uint32 NELOG_NetlogonGcOldSiteCovered = 5796;
	public const uint32 NELOG_NetlogonGcSiteNotCoveredAuto = 5797;
	public const uint32 NELOG_NetlogonNdncOldSiteCovered = 5798;
	public const uint32 NELOG_NetlogonNdncSiteNotCoveredAuto = 5799;
	public const uint32 NELOG_NetlogonSpnMultipleSamAccountNames = 5800;
	public const uint32 NELOG_NetlogonSpnCrackNamesFailure = 5801;
	public const uint32 NELOG_NetlogonNoAddressToSiteMapping = 5802;
	public const uint32 NELOG_NetlogonInvalidGenericParameterValue = 5803;
	public const uint32 NELOG_NetlogonInvalidDwordParameterValue = 5804;
	public const uint32 NELOG_NetlogonServerAuthFailedNoAccount = 5805;
	public const uint32 NELOG_NetlogonNoDynamicDnsManual = 5806;
	public const uint32 NELOG_NetlogonNoSiteForClients = 5807;
	public const uint32 NELOG_NetlogonDnsDeregAborted = 5808;
	public const uint32 NELOG_NetlogonRpcPortRequestFailure = 5809;
	public const uint32 NELOG_NetlogonPartialSiteMappingForClients = 5810;
	public const uint32 NELOG_NetlogonRemoteDynamicDnsRegisterFailure = 5811;
	public const uint32 NELOG_NetlogonRemoteDynamicDnsDeregisterFailure = 5812;
	public const uint32 NELOG_NetlogonRejectedRemoteDynamicDnsRegister = 5813;
	public const uint32 NELOG_NetlogonRejectedRemoteDynamicDnsDeregister = 5814;
	public const uint32 NELOG_NetlogonRemoteDynamicDnsUpdateRequestFailure = 5815;
	public const uint32 NELOG_NetlogonUserValidationReqInitialTimeOut = 5816;
	public const uint32 NELOG_NetlogonUserValidationReqRecurringTimeOut = 5817;
	public const uint32 NELOG_NetlogonUserValidationReqWaitInitialWarning = 5818;
	public const uint32 NELOG_NetlogonUserValidationReqWaitRecurringWarning = 5819;
	public const uint32 NELOG_NetlogonFailedToAddAuthzRpcInterface = 5820;
	public const uint32 NELOG_NetLogonFailedToInitializeAuthzRm = 5821;
	public const uint32 NELOG_NetLogonFailedToInitializeRPCSD = 5822;
	public const uint32 NELOG_NetlogonMachinePasswdSetSucceeded = 5823;
	public const uint32 NELOG_NetlogonMsaPasswdSetSucceeded = 5824;
	public const uint32 NELOG_NetlogonDnsHostNameLowerCasingFailed = 5825;
	public const uint32 NETLOG_NetlogonNonWindowsSupportsSecureRpc = 5826;
	public const uint32 NETLOG_NetlogonUnsecureRpcClient = 5827;
	public const uint32 NETLOG_NetlogonUnsecureRpcTrust = 5828;
	public const uint32 NETLOG_NetlogonUnsecuredRpcMachineTemporarilyAllowed = 5829;
	public const uint32 NETLOG_NetlogonUnsecureRpcMachineAllowedBySsdl = 5830;
	public const uint32 NETLOG_NetlogonUnsecureRpcTrustAllowedBySsdl = 5831;
	public const uint32 NETSETUP_ACCT_DELETE = 4;
	public const uint32 NETSETUP_DNS_NAME_CHANGES_ONLY = 4096;
	public const uint32 NETSETUP_INSTALL_INVOCATION = 262144;
	public const uint32 NETSETUP_ALT_SAMACCOUNTNAME = 131072;
	public const uint32 NET_IGNORE_UNSUPPORTED_FLAGS = 1;
	public const uint32 NETSETUP_PROVISION_PERSISTENTSITE = 32;
	public const uint32 NETSETUP_PROVISION_CHECK_PWD_ONLY = 2147483648;
	public const uint32 NETSETUP_PROVISIONING_PARAMS_WIN8_VERSION = 1;
	public const uint32 NETSETUP_PROVISIONING_PARAMS_CURRENT_VERSION = 2;
	public const uint32 MSGNAME_NOT_FORWARDED = 0;
	public const uint32 MSGNAME_FORWARDED_TO = 4;
	public const uint32 MSGNAME_FORWARDED_FROM = 16;
	public const int32 SUPPORTS_ANY = -1;
	public const uint32 NO_PERMISSION_REQUIRED = 1;
	public const uint32 ALLOCATE_RESPONSE = 2;
	public const uint32 USE_SPECIFIC_TRANSPORT = 2147483648;
	public const uint32 SV_PLATFORM_ID_OS2 = 400;
	public const uint32 SV_PLATFORM_ID_NT = 500;
	public const uint32 MAJOR_VERSION_MASK = 15;
	public const int32 SV_NODISC = -1;
	public const uint32 SV_PLATFORM_ID_PARMNUM = 101;
	public const uint32 SV_NAME_PARMNUM = 102;
	public const uint32 SV_VERSION_MAJOR_PARMNUM = 103;
	public const uint32 SV_VERSION_MINOR_PARMNUM = 104;
	public const uint32 SV_TYPE_PARMNUM = 105;
	public const uint32 SV_COMMENT_PARMNUM = 5;
	public const uint32 SV_USERS_PARMNUM = 107;
	public const uint32 SV_DISC_PARMNUM = 10;
	public const uint32 SV_HIDDEN_PARMNUM = 16;
	public const uint32 SV_ANNOUNCE_PARMNUM = 17;
	public const uint32 SV_ANNDELTA_PARMNUM = 18;
	public const uint32 SV_USERPATH_PARMNUM = 112;
	public const uint32 SV_ULIST_MTIME_PARMNUM = 401;
	public const uint32 SV_GLIST_MTIME_PARMNUM = 402;
	public const uint32 SV_ALIST_MTIME_PARMNUM = 403;
	public const uint32 SV_ALERTS_PARMNUM = 11;
	public const uint32 SV_SECURITY_PARMNUM = 405;
	public const uint32 SV_NUMADMIN_PARMNUM = 406;
	public const uint32 SV_LANMASK_PARMNUM = 407;
	public const uint32 SV_GUESTACC_PARMNUM = 408;
	public const uint32 SV_CHDEVQ_PARMNUM = 410;
	public const uint32 SV_CHDEVJOBS_PARMNUM = 411;
	public const uint32 SV_CONNECTIONS_PARMNUM = 412;
	public const uint32 SV_SHARES_PARMNUM = 413;
	public const uint32 SV_OPENFILES_PARMNUM = 414;
	public const uint32 SV_SESSREQS_PARMNUM = 417;
	public const uint32 SV_ACTIVELOCKS_PARMNUM = 419;
	public const uint32 SV_NUMREQBUF_PARMNUM = 420;
	public const uint32 SV_NUMBIGBUF_PARMNUM = 422;
	public const uint32 SV_NUMFILETASKS_PARMNUM = 423;
	public const uint32 SV_ALERTSCHED_PARMNUM = 37;
	public const uint32 SV_ERRORALERT_PARMNUM = 38;
	public const uint32 SV_LOGONALERT_PARMNUM = 39;
	public const uint32 SV_ACCESSALERT_PARMNUM = 40;
	public const uint32 SV_DISKALERT_PARMNUM = 41;
	public const uint32 SV_NETIOALERT_PARMNUM = 42;
	public const uint32 SV_MAXAUDITSZ_PARMNUM = 43;
	public const uint32 SV_SRVHEURISTICS_PARMNUM = 431;
	public const uint32 SV_SESSOPENS_PARMNUM = 501;
	public const uint32 SV_SESSVCS_PARMNUM = 502;
	public const uint32 SV_OPENSEARCH_PARMNUM = 503;
	public const uint32 SV_SIZREQBUF_PARMNUM = 504;
	public const uint32 SV_INITWORKITEMS_PARMNUM = 505;
	public const uint32 SV_MAXWORKITEMS_PARMNUM = 506;
	public const uint32 SV_RAWWORKITEMS_PARMNUM = 507;
	public const uint32 SV_IRPSTACKSIZE_PARMNUM = 508;
	public const uint32 SV_MAXRAWBUFLEN_PARMNUM = 509;
	public const uint32 SV_SESSUSERS_PARMNUM = 510;
	public const uint32 SV_SESSCONNS_PARMNUM = 511;
	public const uint32 SV_MAXNONPAGEDMEMORYUSAGE_PARMNUM = 512;
	public const uint32 SV_MAXPAGEDMEMORYUSAGE_PARMNUM = 513;
	public const uint32 SV_ENABLESOFTCOMPAT_PARMNUM = 514;
	public const uint32 SV_ENABLEFORCEDLOGOFF_PARMNUM = 515;
	public const uint32 SV_TIMESOURCE_PARMNUM = 516;
	public const uint32 SV_ACCEPTDOWNLEVELAPIS_PARMNUM = 517;
	public const uint32 SV_LMANNOUNCE_PARMNUM = 518;
	public const uint32 SV_DOMAIN_PARMNUM = 519;
	public const uint32 SV_MAXCOPYREADLEN_PARMNUM = 520;
	public const uint32 SV_MAXCOPYWRITELEN_PARMNUM = 521;
	public const uint32 SV_MINKEEPSEARCH_PARMNUM = 522;
	public const uint32 SV_MAXKEEPSEARCH_PARMNUM = 523;
	public const uint32 SV_MINKEEPCOMPLSEARCH_PARMNUM = 524;
	public const uint32 SV_MAXKEEPCOMPLSEARCH_PARMNUM = 525;
	public const uint32 SV_THREADCOUNTADD_PARMNUM = 526;
	public const uint32 SV_NUMBLOCKTHREADS_PARMNUM = 527;
	public const uint32 SV_SCAVTIMEOUT_PARMNUM = 528;
	public const uint32 SV_MINRCVQUEUE_PARMNUM = 529;
	public const uint32 SV_MINFREEWORKITEMS_PARMNUM = 530;
	public const uint32 SV_XACTMEMSIZE_PARMNUM = 531;
	public const uint32 SV_THREADPRIORITY_PARMNUM = 532;
	public const uint32 SV_MAXMPXCT_PARMNUM = 533;
	public const uint32 SV_OPLOCKBREAKWAIT_PARMNUM = 534;
	public const uint32 SV_OPLOCKBREAKRESPONSEWAIT_PARMNUM = 535;
	public const uint32 SV_ENABLEOPLOCKS_PARMNUM = 536;
	public const uint32 SV_ENABLEOPLOCKFORCECLOSE_PARMNUM = 537;
	public const uint32 SV_ENABLEFCBOPENS_PARMNUM = 538;
	public const uint32 SV_ENABLERAW_PARMNUM = 539;
	public const uint32 SV_ENABLESHAREDNETDRIVES_PARMNUM = 540;
	public const uint32 SV_MINFREECONNECTIONS_PARMNUM = 541;
	public const uint32 SV_MAXFREECONNECTIONS_PARMNUM = 542;
	public const uint32 SV_INITSESSTABLE_PARMNUM = 543;
	public const uint32 SV_INITCONNTABLE_PARMNUM = 544;
	public const uint32 SV_INITFILETABLE_PARMNUM = 545;
	public const uint32 SV_INITSEARCHTABLE_PARMNUM = 546;
	public const uint32 SV_ALERTSCHEDULE_PARMNUM = 547;
	public const uint32 SV_ERRORTHRESHOLD_PARMNUM = 548;
	public const uint32 SV_NETWORKERRORTHRESHOLD_PARMNUM = 549;
	public const uint32 SV_DISKSPACETHRESHOLD_PARMNUM = 550;
	public const uint32 SV_MAXLINKDELAY_PARMNUM = 552;
	public const uint32 SV_MINLINKTHROUGHPUT_PARMNUM = 553;
	public const uint32 SV_LINKINFOVALIDTIME_PARMNUM = 554;
	public const uint32 SV_SCAVQOSINFOUPDATETIME_PARMNUM = 555;
	public const uint32 SV_MAXWORKITEMIDLETIME_PARMNUM = 556;
	public const uint32 SV_MAXRAWWORKITEMS_PARMNUM = 557;
	public const uint32 SV_PRODUCTTYPE_PARMNUM = 560;
	public const uint32 SV_SERVERSIZE_PARMNUM = 561;
	public const uint32 SV_CONNECTIONLESSAUTODISC_PARMNUM = 562;
	public const uint32 SV_SHARINGVIOLATIONRETRIES_PARMNUM = 563;
	public const uint32 SV_SHARINGVIOLATIONDELAY_PARMNUM = 564;
	public const uint32 SV_MAXGLOBALOPENSEARCH_PARMNUM = 565;
	public const uint32 SV_REMOVEDUPLICATESEARCHES_PARMNUM = 566;
	public const uint32 SV_LOCKVIOLATIONRETRIES_PARMNUM = 567;
	public const uint32 SV_LOCKVIOLATIONOFFSET_PARMNUM = 568;
	public const uint32 SV_LOCKVIOLATIONDELAY_PARMNUM = 569;
	public const uint32 SV_MDLREADSWITCHOVER_PARMNUM = 570;
	public const uint32 SV_CACHEDOPENLIMIT_PARMNUM = 571;
	public const uint32 SV_CRITICALTHREADS_PARMNUM = 572;
	public const uint32 SV_RESTRICTNULLSESSACCESS_PARMNUM = 573;
	public const uint32 SV_ENABLEWFW311DIRECTIPX_PARMNUM = 574;
	public const uint32 SV_OTHERQUEUEAFFINITY_PARMNUM = 575;
	public const uint32 SV_QUEUESAMPLESECS_PARMNUM = 576;
	public const uint32 SV_BALANCECOUNT_PARMNUM = 577;
	public const uint32 SV_PREFERREDAFFINITY_PARMNUM = 578;
	public const uint32 SV_MAXFREERFCBS_PARMNUM = 579;
	public const uint32 SV_MAXFREEMFCBS_PARMNUM = 580;
	public const uint32 SV_MAXFREELFCBS_PARMNUM = 581;
	public const uint32 SV_MAXFREEPAGEDPOOLCHUNKS_PARMNUM = 582;
	public const uint32 SV_MINPAGEDPOOLCHUNKSIZE_PARMNUM = 583;
	public const uint32 SV_MAXPAGEDPOOLCHUNKSIZE_PARMNUM = 584;
	public const uint32 SV_SENDSFROMPREFERREDPROCESSOR_PARMNUM = 585;
	public const uint32 SV_MAXTHREADSPERQUEUE_PARMNUM = 586;
	public const uint32 SV_CACHEDDIRECTORYLIMIT_PARMNUM = 587;
	public const uint32 SV_MAXCOPYLENGTH_PARMNUM = 588;
	public const uint32 SV_ENABLECOMPRESSION_PARMNUM = 590;
	public const uint32 SV_AUTOSHAREWKS_PARMNUM = 591;
	public const uint32 SV_AUTOSHARESERVER_PARMNUM = 592;
	public const uint32 SV_ENABLESECURITYSIGNATURE_PARMNUM = 593;
	public const uint32 SV_REQUIRESECURITYSIGNATURE_PARMNUM = 594;
	public const uint32 SV_MINCLIENTBUFFERSIZE_PARMNUM = 595;
	public const uint32 SV_CONNECTIONNOSESSIONSTIMEOUT_PARMNUM = 596;
	public const uint32 SV_IDLETHREADTIMEOUT_PARMNUM = 597;
	public const uint32 SV_ENABLEW9XSECURITYSIGNATURE_PARMNUM = 598;
	public const uint32 SV_ENFORCEKERBEROSREAUTHENTICATION_PARMNUM = 599;
	public const uint32 SV_DISABLEDOS_PARMNUM = 600;
	public const uint32 SV_LOWDISKSPACEMINIMUM_PARMNUM = 601;
	public const uint32 SV_DISABLESTRICTNAMECHECKING_PARMNUM = 602;
	public const uint32 SV_ENABLEAUTHENTICATEUSERSHARING_PARMNUM = 603;
	public const uint32 SVI1_NUM_ELEMENTS = 5;
	public const uint32 SVI2_NUM_ELEMENTS = 40;
	public const uint32 SVI3_NUM_ELEMENTS = 44;
	public const uint32 SV_MAX_CMD_LEN = 256;
	public const uint32 SW_AUTOPROF_LOAD_MASK = 1;
	public const uint32 SW_AUTOPROF_SAVE_MASK = 2;
	public const uint32 SV_MAX_SRV_HEUR_LEN = 32;
	public const uint32 SV_USERS_PER_LICENSE = 5;
	public const uint32 SVTI2_REMAP_PIPE_NAMES = 2;
	public const uint32 SVTI2_SCOPED_NAME = 4;
	public const uint32 SVTI2_CLUSTER_NAME = 8;
	public const uint32 SVTI2_CLUSTER_DNN_NAME = 16;
	public const uint32 SVTI2_UNICODE_TRANSPORT_ADDRESS = 32;
	public const uint32 SVTI2_RESERVED1 = 4096;
	public const uint32 SVTI2_RESERVED2 = 8192;
	public const uint32 SVTI2_RESERVED3 = 16384;
	public const uint32 SRV_SUPPORT_HASH_GENERATION = 1;
	public const uint32 SRV_HASH_GENERATION_ACTIVE = 2;
	public const uint32 SERVICE_INSTALL_STATE = 3;
	public const uint32 SERVICE_UNINSTALLED = 0;
	public const uint32 SERVICE_INSTALL_PENDING = 1;
	public const uint32 SERVICE_UNINSTALL_PENDING = 2;
	public const uint32 SERVICE_INSTALLED = 3;
	public const uint32 SERVICE_PAUSE_STATE = 12;
	public const uint32 LM20_SERVICE_ACTIVE = 0;
	public const uint32 LM20_SERVICE_CONTINUE_PENDING = 4;
	public const uint32 LM20_SERVICE_PAUSE_PENDING = 8;
	public const uint32 LM20_SERVICE_PAUSED = 12;
	public const uint32 SERVICE_NOT_UNINSTALLABLE = 0;
	public const uint32 SERVICE_UNINSTALLABLE = 16;
	public const uint32 SERVICE_NOT_PAUSABLE = 0;
	public const uint32 SERVICE_PAUSABLE = 32;
	public const uint32 SERVICE_REDIR_PAUSED = 1792;
	public const uint32 SERVICE_REDIR_DISK_PAUSED = 256;
	public const uint32 SERVICE_REDIR_PRINT_PAUSED = 512;
	public const uint32 SERVICE_REDIR_COMM_PAUSED = 1024;
	public const String SERVICE_DOS_ENCRYPTION = "ENCRYPT";
	public const uint32 SERVICE_CTRL_INTERROGATE = 0;
	public const uint32 SERVICE_CTRL_PAUSE = 1;
	public const uint32 SERVICE_CTRL_CONTINUE = 2;
	public const uint32 SERVICE_CTRL_UNINSTALL = 3;
	public const uint32 SERVICE_CTRL_REDIR_DISK = 1;
	public const uint32 SERVICE_CTRL_REDIR_PRINT = 2;
	public const uint32 SERVICE_CTRL_REDIR_COMM = 4;
	public const uint32 SERVICE_IP_NO_HINT = 0;
	public const uint32 SERVICE_CCP_NO_HINT = 0;
	public const uint32 SERVICE_IP_QUERY_HINT = 65536;
	public const uint32 SERVICE_CCP_QUERY_HINT = 65536;
	public const uint32 SERVICE_IP_CHKPT_NUM = 255;
	public const uint32 SERVICE_CCP_CHKPT_NUM = 255;
	public const uint32 SERVICE_IP_WAIT_TIME = 65280;
	public const uint32 SERVICE_CCP_WAIT_TIME = 65280;
	public const uint32 SERVICE_IP_WAITTIME_SHIFT = 8;
	public const uint32 SERVICE_NTIP_WAITTIME_SHIFT = 12;
	public const uint32 UPPER_HINT_MASK = 65280;
	public const uint32 LOWER_HINT_MASK = 255;
	public const uint32 UPPER_GET_HINT_MASK = 267386880;
	public const uint32 LOWER_GET_HINT_MASK = 65280;
	public const uint32 SERVICE_NT_MAXTIME = 65535;
	public const uint32 SERVICE_RESRV_MASK = 131071;
	public const uint32 SERVICE_MAXTIME = 255;
	public const uint32 SERVICE_BASE = 3050;
	public const uint32 SERVICE_UIC_NORMAL = 0;
	public const uint32 SERVICE_UIC_BADPARMVAL = 3051;
	public const uint32 SERVICE_UIC_MISSPARM = 3052;
	public const uint32 SERVICE_UIC_UNKPARM = 3053;
	public const uint32 SERVICE_UIC_RESOURCE = 3054;
	public const uint32 SERVICE_UIC_CONFIG = 3055;
	public const uint32 SERVICE_UIC_SYSTEM = 3056;
	public const uint32 SERVICE_UIC_INTERNAL = 3057;
	public const uint32 SERVICE_UIC_AMBIGPARM = 3058;
	public const uint32 SERVICE_UIC_DUPPARM = 3059;
	public const uint32 SERVICE_UIC_KILL = 3060;
	public const uint32 SERVICE_UIC_EXEC = 3061;
	public const uint32 SERVICE_UIC_SUBSERV = 3062;
	public const uint32 SERVICE_UIC_CONFLPARM = 3063;
	public const uint32 SERVICE_UIC_FILE = 3064;
	public const uint32 SERVICE_UIC_M_NULL = 0;
	public const uint32 SERVICE_UIC_M_MEMORY = 3070;
	public const uint32 SERVICE_UIC_M_DISK = 3071;
	public const uint32 SERVICE_UIC_M_THREADS = 3072;
	public const uint32 SERVICE_UIC_M_PROCESSES = 3073;
	public const uint32 SERVICE_UIC_M_SECURITY = 3074;
	public const uint32 SERVICE_UIC_M_LANROOT = 3075;
	public const uint32 SERVICE_UIC_M_REDIR = 3076;
	public const uint32 SERVICE_UIC_M_SERVER = 3077;
	public const uint32 SERVICE_UIC_M_SEC_FILE_ERR = 3078;
	public const uint32 SERVICE_UIC_M_FILES = 3079;
	public const uint32 SERVICE_UIC_M_LOGS = 3080;
	public const uint32 SERVICE_UIC_M_LANGROUP = 3081;
	public const uint32 SERVICE_UIC_M_MSGNAME = 3082;
	public const uint32 SERVICE_UIC_M_ANNOUNCE = 3083;
	public const uint32 SERVICE_UIC_M_UAS = 3084;
	public const uint32 SERVICE_UIC_M_SERVER_SEC_ERR = 3085;
	public const uint32 SERVICE_UIC_M_WKSTA = 3087;
	public const uint32 SERVICE_UIC_M_ERRLOG = 3088;
	public const uint32 SERVICE_UIC_M_FILE_UW = 3089;
	public const uint32 SERVICE_UIC_M_ADDPAK = 3090;
	public const uint32 SERVICE_UIC_M_LAZY = 3091;
	public const uint32 SERVICE_UIC_M_UAS_MACHINE_ACCT = 3092;
	public const uint32 SERVICE_UIC_M_UAS_SERVERS_NMEMB = 3093;
	public const uint32 SERVICE_UIC_M_UAS_SERVERS_NOGRP = 3094;
	public const uint32 SERVICE_UIC_M_UAS_INVALID_ROLE = 3095;
	public const uint32 SERVICE_UIC_M_NETLOGON_NO_DC = 3096;
	public const uint32 SERVICE_UIC_M_NETLOGON_DC_CFLCT = 3097;
	public const uint32 SERVICE_UIC_M_NETLOGON_AUTH = 3098;
	public const uint32 SERVICE_UIC_M_UAS_PROLOG = 3099;
	public const uint32 SERVICE2_BASE = 5600;
	public const uint32 SERVICE_UIC_M_NETLOGON_MPATH = 5600;
	public const uint32 SERVICE_UIC_M_LSA_MACHINE_ACCT = 5601;
	public const uint32 SERVICE_UIC_M_DATABASE_ERROR = 5602;
	public const uint32 USE_FLAG_GLOBAL_MAPPING = 65536;
	public const uint32 USE_LOCAL_PARMNUM = 1;
	public const uint32 USE_REMOTE_PARMNUM = 2;
	public const uint32 USE_PASSWORD_PARMNUM = 3;
	public const uint32 USE_ASGTYPE_PARMNUM = 4;
	public const uint32 USE_USERNAME_PARMNUM = 5;
	public const uint32 USE_DOMAINNAME_PARMNUM = 6;
	public const uint32 USE_FLAGS_PARMNUM = 7;
	public const uint32 USE_AUTHIDENTITY_PARMNUM = 8;
	public const uint32 USE_SD_PARMNUM = 9;
	public const uint32 USE_OPTIONS_PARMNUM = 10;
	public const uint32 USE_OK = 0;
	public const uint32 USE_PAUSED = 1;
	public const uint32 USE_SESSLOST = 2;
	public const uint32 USE_DISCONN = 2;
	public const uint32 USE_NETERR = 3;
	public const uint32 USE_CONN = 4;
	public const uint32 USE_RECONN = 5;
	public const uint32 USE_CHARDEV = 2;
	public const uint32 CREATE_NO_CONNECT = 1;
	public const uint32 CREATE_BYPASS_CSC = 2;
	public const uint32 CREATE_CRED_RESET = 4;
	public const uint32 USE_DEFAULT_CREDENTIALS = 4;
	public const uint32 CREATE_REQUIRE_CONNECTION_INTEGRITY = 8;
	public const uint32 CREATE_REQUIRE_CONNECTION_PRIVACY = 16;
	public const uint32 CREATE_PERSIST_MAPPING = 32;
	public const uint32 CREATE_WRITE_THROUGH_SEMANTICS = 64;
	public const uint32 CREATE_GLOBAL_MAPPING = 256;
	public const uint32 WKSTA_PLATFORM_ID_PARMNUM = 100;
	public const uint32 WKSTA_COMPUTERNAME_PARMNUM = 1;
	public const uint32 WKSTA_LANGROUP_PARMNUM = 2;
	public const uint32 WKSTA_VER_MAJOR_PARMNUM = 4;
	public const uint32 WKSTA_VER_MINOR_PARMNUM = 5;
	public const uint32 WKSTA_LOGGED_ON_USERS_PARMNUM = 6;
	public const uint32 WKSTA_LANROOT_PARMNUM = 7;
	public const uint32 WKSTA_LOGON_DOMAIN_PARMNUM = 8;
	public const uint32 WKSTA_LOGON_SERVER_PARMNUM = 9;
	public const uint32 WKSTA_CHARWAIT_PARMNUM = 10;
	public const uint32 WKSTA_CHARTIME_PARMNUM = 11;
	public const uint32 WKSTA_CHARCOUNT_PARMNUM = 12;
	public const uint32 WKSTA_KEEPCONN_PARMNUM = 13;
	public const uint32 WKSTA_KEEPSEARCH_PARMNUM = 14;
	public const uint32 WKSTA_MAXCMDS_PARMNUM = 15;
	public const uint32 WKSTA_NUMWORKBUF_PARMNUM = 16;
	public const uint32 WKSTA_MAXWRKCACHE_PARMNUM = 17;
	public const uint32 WKSTA_SESSTIMEOUT_PARMNUM = 18;
	public const uint32 WKSTA_SIZERROR_PARMNUM = 19;
	public const uint32 WKSTA_NUMALERTS_PARMNUM = 20;
	public const uint32 WKSTA_NUMSERVICES_PARMNUM = 21;
	public const uint32 WKSTA_NUMCHARBUF_PARMNUM = 22;
	public const uint32 WKSTA_SIZCHARBUF_PARMNUM = 23;
	public const uint32 WKSTA_ERRLOGSZ_PARMNUM = 27;
	public const uint32 WKSTA_PRINTBUFTIME_PARMNUM = 28;
	public const uint32 WKSTA_SIZWORKBUF_PARMNUM = 29;
	public const uint32 WKSTA_MAILSLOTS_PARMNUM = 30;
	public const uint32 WKSTA_NUMDGRAMBUF_PARMNUM = 31;
	public const uint32 WKSTA_WRKHEURISTICS_PARMNUM = 32;
	public const uint32 WKSTA_MAXTHREADS_PARMNUM = 33;
	public const uint32 WKSTA_LOCKQUOTA_PARMNUM = 41;
	public const uint32 WKSTA_LOCKINCREMENT_PARMNUM = 42;
	public const uint32 WKSTA_LOCKMAXIMUM_PARMNUM = 43;
	public const uint32 WKSTA_PIPEINCREMENT_PARMNUM = 44;
	public const uint32 WKSTA_PIPEMAXIMUM_PARMNUM = 45;
	public const uint32 WKSTA_DORMANTFILELIMIT_PARMNUM = 46;
	public const uint32 WKSTA_CACHEFILETIMEOUT_PARMNUM = 47;
	public const uint32 WKSTA_USEOPPORTUNISTICLOCKING_PARMNUM = 48;
	public const uint32 WKSTA_USEUNLOCKBEHIND_PARMNUM = 49;
	public const uint32 WKSTA_USECLOSEBEHIND_PARMNUM = 50;
	public const uint32 WKSTA_BUFFERNAMEDPIPES_PARMNUM = 51;
	public const uint32 WKSTA_USELOCKANDREADANDUNLOCK_PARMNUM = 52;
	public const uint32 WKSTA_UTILIZENTCACHING_PARMNUM = 53;
	public const uint32 WKSTA_USERAWREAD_PARMNUM = 54;
	public const uint32 WKSTA_USERAWWRITE_PARMNUM = 55;
	public const uint32 WKSTA_USEWRITERAWWITHDATA_PARMNUM = 56;
	public const uint32 WKSTA_USEENCRYPTION_PARMNUM = 57;
	public const uint32 WKSTA_BUFFILESWITHDENYWRITE_PARMNUM = 58;
	public const uint32 WKSTA_BUFFERREADONLYFILES_PARMNUM = 59;
	public const uint32 WKSTA_FORCECORECREATEMODE_PARMNUM = 60;
	public const uint32 WKSTA_USE512BYTESMAXTRANSFER_PARMNUM = 61;
	public const uint32 WKSTA_READAHEADTHRUPUT_PARMNUM = 62;
	public const uint32 WKSTA_OTH_DOMAINS_PARMNUM = 101;
	public const uint32 TRANSPORT_QUALITYOFSERVICE_PARMNUM = 201;
	public const uint32 TRANSPORT_NAME_PARMNUM = 202;
	public const int32 EVENT_SRV_SERVICE_FAILED = -1073739824;
	public const int32 EVENT_SRV_RESOURCE_SHORTAGE = -1073739823;
	public const int32 EVENT_SRV_CANT_CREATE_DEVICE = -1073739822;
	public const int32 EVENT_SRV_CANT_CREATE_PROCESS = -1073739821;
	public const int32 EVENT_SRV_CANT_CREATE_THREAD = -1073739820;
	public const int32 EVENT_SRV_UNEXPECTED_DISC = -1073739819;
	public const int32 EVENT_SRV_INVALID_REQUEST = -1073739818;
	public const int32 EVENT_SRV_CANT_OPEN_NPFS = -1073739817;
	public const int32 EVENT_SRV_CANT_GROW_TABLE = -2147481639;
	public const int32 EVENT_SRV_CANT_START_SCAVENGER = -1073739814;
	public const int32 EVENT_SRV_IRP_STACK_SIZE = -1073739813;
	public const int32 EVENT_SRV_NETWORK_ERROR = -2147481636;
	public const int32 EVENT_SRV_DISK_FULL = -2147481635;
	public const int32 EVENT_SRV_NO_VIRTUAL_MEMORY = -1073739808;
	public const int32 EVENT_SRV_NONPAGED_POOL_LIMIT = -1073739807;
	public const int32 EVENT_SRV_PAGED_POOL_LIMIT = -1073739806;
	public const int32 EVENT_SRV_NO_NONPAGED_POOL = -1073739805;
	public const int32 EVENT_SRV_NO_PAGED_POOL = -1073739804;
	public const int32 EVENT_SRV_NO_WORK_ITEM = -2147481627;
	public const int32 EVENT_SRV_NO_FREE_CONNECTIONS = -2147481626;
	public const int32 EVENT_SRV_NO_FREE_RAW_WORK_ITEM = -2147481625;
	public const int32 EVENT_SRV_NO_BLOCKING_IO = -2147481624;
	public const int32 EVENT_SRV_DOS_ATTACK_DETECTED = -2147481623;
	public const int32 EVENT_SRV_TOO_MANY_DOS = -2147481622;
	public const int32 EVENT_SRV_OUT_OF_WORK_ITEM_DOS = -2147481621;
	public const int32 EVENT_SRV_KEY_NOT_FOUND = -1073739323;
	public const int32 EVENT_SRV_KEY_NOT_CREATED = -1073739322;
	public const int32 EVENT_SRV_NO_TRANSPORTS_BOUND = -1073739321;
	public const int32 EVENT_SRV_CANT_BIND_TO_TRANSPORT = -2147481144;
	public const int32 EVENT_SRV_CANT_BIND_DUP_NAME = -1073739319;
	public const int32 EVENT_SRV_INVALID_REGISTRY_VALUE = -2147481142;
	public const int32 EVENT_SRV_INVALID_SD = -2147481141;
	public const int32 EVENT_SRV_CANT_LOAD_DRIVER = -2147481140;
	public const int32 EVENT_SRV_CANT_UNLOAD_DRIVER = -2147481139;
	public const int32 EVENT_SRV_CANT_MAP_ERROR = -2147481138;
	public const int32 EVENT_SRV_CANT_RECREATE_SHARE = -2147481137;
	public const int32 EVENT_SRV_CANT_CHANGE_DOMAIN_NAME = -2147481136;
	public const int32 EVENT_SRV_TXF_INIT_FAILED = -2147481135;
	public const int32 EVENT_RDR_RESOURCE_SHORTAGE = -2147480647;
	public const int32 EVENT_RDR_CANT_CREATE_DEVICE = -2147480646;
	public const int32 EVENT_RDR_CANT_CREATE_THREAD = -2147480645;
	public const int32 EVENT_RDR_CANT_SET_THREAD = -2147480644;
	public const int32 EVENT_RDR_INVALID_REPLY = -2147480643;
	public const int32 EVENT_RDR_INVALID_SMB = -2147480642;
	public const int32 EVENT_RDR_INVALID_LOCK_REPLY = -2147480641;
	public const int32 EVENT_RDR_FAILED_UNLOCK = -2147480639;
	public const int32 EVENT_RDR_CLOSE_BEHIND = -2147480637;
	public const int32 EVENT_RDR_UNEXPECTED_ERROR = -2147480636;
	public const int32 EVENT_RDR_TIMEOUT = -2147480635;
	public const int32 EVENT_RDR_INVALID_OPLOCK = -2147480634;
	public const int32 EVENT_RDR_CONNECTION_REFERENCE = -2147480633;
	public const int32 EVENT_RDR_SERVER_REFERENCE = -2147480632;
	public const int32 EVENT_RDR_SMB_REFERENCE = -2147480631;
	public const int32 EVENT_RDR_ENCRYPT = -2147480630;
	public const int32 EVENT_RDR_CONNECTION = -2147480629;
	public const int32 EVENT_RDR_MAXCMDS = -2147480627;
	public const int32 EVENT_RDR_OPLOCK_SMB = -2147480626;
	public const int32 EVENT_RDR_DISPOSITION = -2147480625;
	public const int32 EVENT_RDR_CONTEXTS = -2147480624;
	public const int32 EVENT_RDR_WRITE_BEHIND_FLUSH_FAILED = -2147480623;
	public const int32 EVENT_RDR_AT_THREAD_MAX = -2147480622;
	public const int32 EVENT_RDR_CANT_READ_REGISTRY = -2147480621;
	public const int32 EVENT_RDR_TIMEZONE_BIAS_TOO_LARGE = -2147480620;
	public const int32 EVENT_RDR_PRIMARY_TRANSPORT_CONNECT_FAILED = -2147480619;
	public const int32 EVENT_RDR_DELAYED_SET_ATTRIBUTES_FAILED = -2147480618;
	public const int32 EVENT_RDR_DELETEONCLOSE_FAILED = -2147480617;
	public const int32 EVENT_RDR_CANT_BIND_TRANSPORT = -2147480616;
	public const int32 EVENT_RDR_CANT_REGISTER_ADDRESS = -2147480615;
	public const int32 EVENT_RDR_CANT_GET_SECURITY_CONTEXT = -2147480614;
	public const int32 EVENT_RDR_CANT_BUILD_SMB_HEADER = -2147480613;
	public const int32 EVENT_RDR_SECURITY_SIGNATURE_MISMATCH = -2147480612;
	public const int32 EVENT_TCPIP6_STARTED = 1073744924;
	public const int32 EVENT_STREAMS_STRLOG = -1073737824;
	public const int32 EVENT_STREAMS_ALLOCB_FAILURE = -2147479647;
	public const int32 EVENT_STREAMS_ALLOCB_FAILURE_CNT = -2147479646;
	public const int32 EVENT_STREAMS_ESBALLOC_FAILURE = -2147479645;
	public const int32 EVENT_STREAMS_ESBALLOC_FAILURE_CNT = -2147479644;
	public const int32 EVENT_TCPIP_CREATE_DEVICE_FAILED = -1073737724;
	public const int32 EVENT_TCPIP_NO_RESOURCES_FOR_INIT = -1073737723;
	public const int32 EVENT_TCPIP_TOO_MANY_NETS = -1073737639;
	public const int32 EVENT_TCPIP_NO_MASK = -1073737638;
	public const int32 EVENT_TCPIP_INVALID_ADDRESS = -1073737637;
	public const int32 EVENT_TCPIP_INVALID_MASK = -1073737636;
	public const int32 EVENT_TCPIP_NO_ADAPTER_RESOURCES = -1073737635;
	public const int32 EVENT_TCPIP_DHCP_INIT_FAILED = -2147479458;
	public const int32 EVENT_TCPIP_ADAPTER_REG_FAILURE = -1073737633;
	public const int32 EVENT_TCPIP_INVALID_DEFAULT_GATEWAY = -2147479456;
	public const int32 EVENT_TCPIP_NO_ADDRESS_LIST = -1073737631;
	public const int32 EVENT_TCPIP_NO_MASK_LIST = -1073737630;
	public const int32 EVENT_TCPIP_NO_BINDINGS = -1073737629;
	public const int32 EVENT_TCPIP_IP_INIT_FAILED = -1073737628;
	public const int32 EVENT_TCPIP_TOO_MANY_GATEWAYS = -2147479451;
	public const int32 EVENT_TCPIP_ADDRESS_CONFLICT1 = -1073737626;
	public const int32 EVENT_TCPIP_ADDRESS_CONFLICT2 = -1073737625;
	public const int32 EVENT_TCPIP_NTE_CONTEXT_LIST_FAILURE = -1073737624;
	public const int32 EVENT_TCPIP_MEDIA_CONNECT = 1073746025;
	public const int32 EVENT_TCPIP_MEDIA_DISCONNECT = 1073746026;
	public const int32 EVENT_TCPIP_IPV4_UNINSTALLED = 1073746027;
	public const int32 EVENT_TCPIP_AUTOCONFIGURED_ADDRESS_LIMIT_REACHED = -2147479444;
	public const int32 EVENT_TCPIP_AUTOCONFIGURED_ROUTE_LIMIT_REACHED = -2147479443;
	public const int32 EVENT_TCPIP_OUT_OF_ORDER_FRAGMENTS_EXCEEDED = -2147479442;
	public const int32 EVENT_TCPIP_INTERFACE_BIND_FAILURE = -1073737617;
	public const int32 EVENT_TCPIP_TCP_INIT_FAILED = -1073737599;
	public const int32 EVENT_TCPIP_TCP_CONNECT_LIMIT_REACHED = -2147479422;
	public const int32 EVENT_TCPIP_TCP_TIME_WAIT_COLLISION = -2147479421;
	public const int32 EVENT_TCPIP_TCP_WSD_WS_RESTRICTED = -2147479420;
	public const int32 EVENT_TCPIP_TCP_MPP_ATTACKS_DETECTED = -2147479419;
	public const int32 EVENT_TCPIP_TCP_CONNECTIONS_PERF_IMPACTED = -2147479418;
	public const int32 EVENT_TCPIP_TCP_GLOBAL_EPHEMERAL_PORT_SPACE_EXHAUSTED = -2147479417;
	public const int32 EVENT_TCPIP_UDP_LIMIT_REACHED = -2147479383;
	public const int32 EVENT_TCPIP_UDP_GLOBAL_EPHEMERAL_PORT_SPACE_EXHAUSTED = -2147479382;
	public const int32 EVENT_TCPIP_PCF_MULTICAST_OID_ISSUE = -2147479358;
	public const int32 EVENT_TCPIP_PCF_MISSING_CAPABILITY = -2147479357;
	public const int32 EVENT_TCPIP_PCF_SET_FILTER_FAILURE = -2147479356;
	public const int32 EVENT_TCPIP_PCF_NO_ARP_FILTER = -2147479355;
	public const int32 EVENT_TCPIP_PCF_CLEAR_FILTER_FAILURE = -1073737530;
	public const int32 EVENT_NBT_CREATE_DRIVER = -1073737524;
	public const int32 EVENT_NBT_OPEN_REG_PARAMS = -1073737523;
	public const int32 EVENT_NBT_NO_BACKUP_WINS = -2147479346;
	public const int32 EVENT_NBT_NO_WINS = -2147479345;
	public const int32 EVENT_NBT_BAD_BACKUP_WINS_ADDR = -2147479344;
	public const int32 EVENT_NBT_BAD_PRIMARY_WINS_ADDR = -2147479343;
	public const int32 EVENT_NBT_NAME_SERVER_ADDRS = -1073737518;
	public const int32 EVENT_NBT_CREATE_ADDRESS = -1073737517;
	public const int32 EVENT_NBT_CREATE_CONNECTION = -1073737516;
	public const int32 EVENT_NBT_NON_OS_INIT = -1073737515;
	public const int32 EVENT_NBT_TIMERS = -1073737514;
	public const int32 EVENT_NBT_CREATE_DEVICE = -1073737513;
	public const int32 EVENT_NBT_NO_DEVICES = -2147479336;
	public const int32 EVENT_NBT_OPEN_REG_LINKAGE = -1073737511;
	public const int32 EVENT_NBT_READ_BIND = -1073737510;
	public const int32 EVENT_NBT_READ_EXPORT = -1073737509;
	public const int32 EVENT_NBT_OPEN_REG_NAMESERVER = -2147479332;
	public const int32 EVENT_SCOPE_LABEL_TOO_LONG = -2147479331;
	public const int32 EVENT_SCOPE_TOO_LONG = -2147479330;
	public const int32 EVENT_NBT_DUPLICATE_NAME = -1073737505;
	public const int32 EVENT_NBT_NAME_RELEASE = -1073737504;
	public const int32 EVENT_NBT_DUPLICATE_NAME_ERROR = -1073737503;
	public const int32 EVENT_NBT_NO_RESOURCES = -1073737502;
	public const int32 EVENT_NDIS_RESOURCE_CONFLICT = -1073736824;
	public const int32 EVENT_NDIS_OUT_OF_RESOURCE = -1073736823;
	public const int32 EVENT_NDIS_HARDWARE_FAILURE = -1073736822;
	public const int32 EVENT_NDIS_ADAPTER_NOT_FOUND = -1073736821;
	public const int32 EVENT_NDIS_INTERRUPT_CONNECT = -1073736820;
	public const int32 EVENT_NDIS_DRIVER_FAILURE = -1073736819;
	public const int32 EVENT_NDIS_BAD_VERSION = -1073736818;
	public const int32 EVENT_NDIS_TIMEOUT = -2147478641;
	public const int32 EVENT_NDIS_NETWORK_ADDRESS = -1073736816;
	public const int32 EVENT_NDIS_UNSUPPORTED_CONFIGURATION = -1073736815;
	public const int32 EVENT_NDIS_INVALID_VALUE_FROM_ADAPTER = -1073736814;
	public const int32 EVENT_NDIS_MISSING_CONFIGURATION_PARAMETER = -1073736813;
	public const int32 EVENT_NDIS_BAD_IO_BASE_ADDRESS = -1073736812;
	public const int32 EVENT_NDIS_RECEIVE_SPACE_SMALL = 1073746837;
	public const int32 EVENT_NDIS_ADAPTER_DISABLED = -2147478634;
	public const int32 EVENT_NDIS_IO_PORT_CONFLICT = -2147478633;
	public const int32 EVENT_NDIS_PORT_OR_DMA_CONFLICT = -2147478632;
	public const int32 EVENT_NDIS_MEMORY_CONFLICT = -2147478631;
	public const int32 EVENT_NDIS_INTERRUPT_CONFLICT = -2147478630;
	public const int32 EVENT_NDIS_DMA_CONFLICT = -2147478629;
	public const int32 EVENT_NDIS_INVALID_DOWNLOAD_FILE_ERROR = -1073736804;
	public const int32 EVENT_NDIS_MAXRECEIVES_ERROR = -2147478627;
	public const int32 EVENT_NDIS_MAXTRANSMITS_ERROR = -2147478626;
	public const int32 EVENT_NDIS_MAXFRAMESIZE_ERROR = -2147478625;
	public const int32 EVENT_NDIS_MAXINTERNALBUFS_ERROR = -2147478624;
	public const int32 EVENT_NDIS_MAXMULTICAST_ERROR = -2147478623;
	public const int32 EVENT_NDIS_PRODUCTID_ERROR = -2147478622;
	public const int32 EVENT_NDIS_LOBE_FAILUE_ERROR = -2147478621;
	public const int32 EVENT_NDIS_SIGNAL_LOSS_ERROR = -2147478620;
	public const int32 EVENT_NDIS_REMOVE_RECEIVED_ERROR = -2147478619;
	public const int32 EVENT_NDIS_TOKEN_RING_CORRECTION = 1073746854;
	public const int32 EVENT_NDIS_ADAPTER_CHECK_ERROR = -1073736793;
	public const int32 EVENT_NDIS_RESET_FAILURE_ERROR = -2147478616;
	public const int32 EVENT_NDIS_CABLE_DISCONNECTED_ERROR = -2147478615;
	public const int32 EVENT_NDIS_RESET_FAILURE_CORRECTION = -2147478614;
	public const int32 EVENT_EventlogStarted = -2147477643;
	public const int32 EVENT_EventlogStopped = -2147477642;
	public const int32 EVENT_EventlogAbnormalShutdown = -2147477640;
	public const int32 EVENT_EventLogProductInfo = -2147477639;
	public const int32 EVENT_ComputerNameChange = -2147477637;
	public const int32 EVENT_DNSDomainNameChange = -2147477636;
	public const int32 EVENT_EventlogUptime = -2147477635;
	public const int32 EVENT_UP_DRIVER_ON_MP = -1073735724;
	public const int32 EVENT_SERVICE_START_FAILED = -1073734824;
	public const int32 EVENT_SERVICE_START_FAILED_II = -1073734823;
	public const int32 EVENT_SERVICE_START_FAILED_GROUP = -1073734822;
	public const int32 EVENT_SERVICE_START_FAILED_NONE = -1073734821;
	public const int32 EVENT_CALL_TO_FUNCTION_FAILED = -1073734819;
	public const int32 EVENT_CALL_TO_FUNCTION_FAILED_II = -1073734818;
	public const int32 EVENT_REVERTED_TO_LASTKNOWNGOOD = -1073734817;
	public const int32 EVENT_BAD_ACCOUNT_NAME = -1073734816;
	public const int32 EVENT_CONNECTION_TIMEOUT = -1073734815;
	public const int32 EVENT_READFILE_TIMEOUT = -1073734814;
	public const int32 EVENT_TRANSACT_TIMEOUT = -1073734813;
	public const int32 EVENT_TRANSACT_INVALID = -1073734812;
	public const int32 EVENT_FIRST_LOGON_FAILED = -1073734811;
	public const int32 EVENT_SECOND_LOGON_FAILED = -1073734810;
	public const int32 EVENT_INVALID_DRIVER_DEPENDENCY = -1073734809;
	public const int32 EVENT_BAD_SERVICE_STATE = -1073734808;
	public const int32 EVENT_CIRCULAR_DEPENDENCY_DEMAND = -1073734807;
	public const int32 EVENT_CIRCULAR_DEPENDENCY_AUTO = -1073734806;
	public const int32 EVENT_DEPEND_ON_LATER_SERVICE = -1073734805;
	public const int32 EVENT_DEPEND_ON_LATER_GROUP = -1073734804;
	public const int32 EVENT_SEVERE_SERVICE_FAILED = -1073734803;
	public const int32 EVENT_SERVICE_START_HUNG = -1073734802;
	public const int32 EVENT_SERVICE_EXIT_FAILED = -1073734801;
	public const int32 EVENT_SERVICE_EXIT_FAILED_SPECIFIC = -1073734800;
	public const int32 EVENT_SERVICE_START_AT_BOOT_FAILED = -1073734799;
	public const int32 EVENT_BOOT_SYSTEM_DRIVERS_FAILED = -1073734798;
	public const int32 EVENT_RUNNING_LASTKNOWNGOOD = -1073734797;
	public const int32 EVENT_TAKE_OWNERSHIP = -1073734796;
	public const int32 TITLE_SC_MESSAGE_BOX = -1073734795;
	public const int32 EVENT_SERVICE_NOT_INTERACTIVE = -1073734794;
	public const int32 EVENT_SERVICE_CRASH = -1073734793;
	public const int32 EVENT_SERVICE_RECOVERY_FAILED = -1073734792;
	public const int32 EVENT_SERVICE_SCESRV_FAILED = -1073734791;
	public const int32 EVENT_SERVICE_CRASH_NO_ACTION = -1073734790;
	public const int32 EVENT_SERVICE_CONTROL_SUCCESS = 1073748859;
	public const int32 EVENT_SERVICE_STATUS_SUCCESS = 1073748860;
	public const int32 EVENT_SERVICE_CONFIG_BACKOUT_FAILED = -1073734787;
	public const int32 EVENT_FIRST_LOGON_FAILED_II = -1073734786;
	public const int32 EVENT_SERVICE_DIFFERENT_PID_CONNECTED = -2147476609;
	public const int32 EVENT_SERVICE_START_TYPE_CHANGED = 1073748864;
	public const int32 EVENT_SERVICE_LOGON_TYPE_NOT_GRANTED = -1073734783;
	public const int32 EVENT_SERVICE_STOP_SUCCESS_WITH_REASON = 1073748866;
	public const int32 EVENT_SERVICE_SHUTDOWN_FAILED = -1073734781;
	public const int32 EVENT_COMMAND_NOT_INTERACTIVE = -1073733924;
	public const int32 EVENT_COMMAND_START_FAILED = -1073733923;
	public const int32 EVENT_BOWSER_OTHER_MASTER_ON_NET = -1073733821;
	public const int32 EVENT_BOWSER_PROMOTED_WHILE_ALREADY_MASTER = -2147475644;
	public const int32 EVENT_BOWSER_NON_MASTER_MASTER_ANNOUNCE = -2147475643;
	public const int32 EVENT_BOWSER_ILLEGAL_DATAGRAM = -2147475642;
	public const int32 EVENT_BROWSER_STATUS_BITS_UPDATE_FAILED = -1073733817;
	public const int32 EVENT_BROWSER_ROLE_CHANGE_FAILED = -1073733816;
	public const int32 EVENT_BROWSER_MASTER_PROMOTION_FAILED = -1073733815;
	public const int32 EVENT_BOWSER_NAME_CONVERSION_FAILED = -1073733814;
	public const int32 EVENT_BROWSER_OTHERDOMAIN_ADD_FAILED = -1073733813;
	public const int32 EVENT_BOWSER_ELECTION_RECEIVED = 8012;
	public const int32 EVENT_BOWSER_ELECTION_SENT_GETBLIST_FAILED = 1073749837;
	public const int32 EVENT_BOWSER_ELECTION_SENT_FIND_MASTER_FAILED = 1073749838;
	public const int32 EVENT_BROWSER_ELECTION_SENT_LANMAN_NT_STARTED = 1073749839;
	public const int32 EVENT_BOWSER_ILLEGAL_DATAGRAM_THRESHOLD = -1073733808;
	public const int32 EVENT_BROWSER_DEPENDANT_SERVICE_FAILED = -1073733807;
	public const int32 EVENT_BROWSER_MASTER_PROMOTION_FAILED_STOPPING = -1073733805;
	public const int32 EVENT_BROWSER_MASTER_PROMOTION_FAILED_NO_MASTER = -1073733804;
	public const int32 EVENT_BROWSER_SERVER_LIST_FAILED = -2147475627;
	public const int32 EVENT_BROWSER_DOMAIN_LIST_FAILED = -2147475626;
	public const int32 EVENT_BROWSER_ILLEGAL_CONFIG = -2147475625;
	public const int32 EVENT_BOWSER_OLD_BACKUP_FOUND = 1073749848;
	public const int32 EVENT_BROWSER_SERVER_LIST_RETRIEVED = 8025;
	public const int32 EVENT_BROWSER_DOMAIN_LIST_RETRIEVED = 8026;
	public const int32 EVENT_BOWSER_PDC_LOST_ELECTION = 1073749851;
	public const int32 EVENT_BOWSER_NON_PDC_WON_ELECTION = 1073749852;
	public const int32 EVENT_BOWSER_CANT_READ_REGISTRY = 1073749853;
	public const int32 EVENT_BOWSER_MAILSLOT_DATAGRAM_THRESHOLD_EXCEEDED = 1073749854;
	public const int32 EVENT_BOWSER_GETBROWSERLIST_THRESHOLD_EXCEEDED = 1073749855;
	public const int32 EVENT_BROWSER_BACKUP_STOPPED = -1073733792;
	public const int32 EVENT_BROWSER_ELECTION_SENT_LANMAN_NT_STOPPED = 1073749857;
	public const int32 EVENT_BROWSER_GETBLIST_RECEIVED_NOT_MASTER = -1073733790;
	public const int32 EVENT_BROWSER_ELECTION_SENT_ROLE_CHANGED = 1073749859;
	public const int32 EVENT_BROWSER_NOT_STARTED_IPX_CONFIG_MISMATCH = -1073733788;
	public const int32 NWSAP_EVENT_KEY_NOT_FOUND = -1073733324;
	public const int32 NWSAP_EVENT_WSASTARTUP_FAILED = -1073733323;
	public const int32 NWSAP_EVENT_SOCKET_FAILED = -1073733322;
	public const int32 NWSAP_EVENT_SETOPTBCAST_FAILED = -1073733321;
	public const int32 NWSAP_EVENT_BIND_FAILED = -1073733320;
	public const int32 NWSAP_EVENT_GETSOCKNAME_FAILED = -1073733319;
	public const int32 NWSAP_EVENT_OPTEXTENDEDADDR_FAILED = -1073733318;
	public const int32 NWSAP_EVENT_OPTBCASTINADDR_FAILED = -1073733317;
	public const int32 NWSAP_EVENT_CARDMALLOC_FAILED = -1073733316;
	public const int32 NWSAP_EVENT_NOCARDS = -1073733315;
	public const int32 NWSAP_EVENT_THREADEVENT_FAIL = -1073733314;
	public const int32 NWSAP_EVENT_RECVSEM_FAIL = -1073733313;
	public const int32 NWSAP_EVENT_SENDEVENT_FAIL = -1073733312;
	public const int32 NWSAP_EVENT_STARTRECEIVE_ERROR = -1073733311;
	public const int32 NWSAP_EVENT_STARTWORKER_ERROR = -1073733310;
	public const int32 NWSAP_EVENT_TABLE_MALLOC_FAILED = -1073733309;
	public const int32 NWSAP_EVENT_HASHTABLE_MALLOC_FAILED = -1073733308;
	public const int32 NWSAP_EVENT_STARTLPCWORKER_ERROR = -1073733307;
	public const int32 NWSAP_EVENT_CREATELPCPORT_ERROR = -1073733306;
	public const int32 NWSAP_EVENT_CREATELPCEVENT_ERROR = -1073733305;
	public const int32 NWSAP_EVENT_LPCLISTENMEMORY_ERROR = -1073733304;
	public const int32 NWSAP_EVENT_LPCHANDLEMEMORY_ERROR = -1073733303;
	public const int32 NWSAP_EVENT_BADWANFILTER_VALUE = -1073733302;
	public const int32 NWSAP_EVENT_CARDLISTEVENT_FAIL = -1073733301;
	public const int32 NWSAP_EVENT_SDMDEVENT_FAIL = -1073733300;
	public const int32 NWSAP_EVENT_INVALID_FILTERNAME = -2147475123;
	public const int32 NWSAP_EVENT_WANSEM_FAIL = -1073733298;
	public const int32 NWSAP_EVENT_WANSOCKET_FAILED = -1073733297;
	public const int32 NWSAP_EVENT_WANBIND_FAILED = -1073733296;
	public const int32 NWSAP_EVENT_STARTWANWORKER_ERROR = -1073733295;
	public const int32 NWSAP_EVENT_STARTWANCHECK_ERROR = -1073733294;
	public const int32 NWSAP_EVENT_OPTMAXADAPTERNUM_ERROR = -1073733293;
	public const int32 NWSAP_EVENT_WANHANDLEMEMORY_ERROR = -1073733292;
	public const int32 NWSAP_EVENT_WANEVENT_ERROR = -1073733291;
	public const int32 EVENT_TRANSPORT_RESOURCE_POOL = -2147474647;
	public const int32 EVENT_TRANSPORT_RESOURCE_LIMIT = -2147474646;
	public const int32 EVENT_TRANSPORT_RESOURCE_SPECIFIC = -2147474645;
	public const int32 EVENT_TRANSPORT_REGISTER_FAILED = -1073732820;
	public const int32 EVENT_TRANSPORT_BINDING_FAILED = -1073732819;
	public const int32 EVENT_TRANSPORT_ADAPTER_NOT_FOUND = -1073732818;
	public const int32 EVENT_TRANSPORT_SET_OID_FAILED = -1073732817;
	public const int32 EVENT_TRANSPORT_QUERY_OID_FAILED = -1073732816;
	public const int32 EVENT_TRANSPORT_TRANSFER_DATA = 1073750833;
	public const int32 EVENT_TRANSPORT_TOO_MANY_LINKS = 1073750834;
	public const int32 EVENT_TRANSPORT_BAD_PROTOCOL = 1073750835;
	public const int32 EVENT_IPX_NEW_DEFAULT_TYPE = 1073751325;
	public const int32 EVENT_IPX_SAP_ANNOUNCE = -2147474146;
	public const int32 EVENT_IPX_ILLEGAL_CONFIG = -2147474145;
	public const int32 EVENT_IPX_INTERNAL_NET_INVALID = -1073732320;
	public const int32 EVENT_IPX_NO_FRAME_TYPES = -1073732319;
	public const int32 EVENT_IPX_CREATE_DEVICE = -1073732318;
	public const int32 EVENT_IPX_NO_ADAPTERS = -1073732317;
	public const int32 EVENT_RPCSS_CREATEPROCESS_FAILURE = -1073731824;
	public const int32 EVENT_RPCSS_RUNAS_CREATEPROCESS_FAILURE = -1073731823;
	public const int32 EVENT_RPCSS_LAUNCH_ACCESS_DENIED = -1073731822;
	public const int32 EVENT_RPCSS_DEFAULT_LAUNCH_ACCESS_DENIED = -1073731821;
	public const int32 EVENT_RPCSS_RUNAS_CANT_LOGIN = -1073731820;
	public const int32 EVENT_RPCSS_START_SERVICE_FAILURE = -1073731819;
	public const int32 EVENT_RPCSS_REMOTE_SIDE_ERROR = -1073731818;
	public const int32 EVENT_RPCSS_ACTIVATION_ERROR = -1073731817;
	public const int32 EVENT_RPCSS_REMOTE_SIDE_ERROR_WITH_FILE = -1073731816;
	public const int32 EVENT_RPCSS_REMOTE_SIDE_UNAVAILABLE = -1073731815;
	public const int32 EVENT_RPCSS_SERVER_START_TIMEOUT = -1073731814;
	public const int32 EVENT_RPCSS_SERVER_NOT_RESPONDING = -1073731813;
	public const int32 EVENT_DCOM_ASSERTION_FAILURE = -1073731812;
	public const int32 EVENT_DCOM_INVALID_ENDPOINT_DATA = -1073731811;
	public const int32 EVENT_DCOM_COMPLUS_DISABLED = -1073731810;
	public const int32 EVENT_RPCSS_STOP_SERVICE_FAILURE = -1073731795;
	public const int32 EVENT_RPCSS_CREATEDEBUGGERPROCESS_FAILURE = -1073731794;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_DLL = -1073730824;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_ENTRY = -1073730823;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_CONTROL = -1073730822;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_DONE_EVENT = -1073730821;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_RPC = -1073730820;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_SHUTDOWN_NOTIFY = -1073730819;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_NO_UPDATE = -1073730818;
	public const int32 EVENT_DNS_CACHE_START_FAILURE_LOW_MEMORY = -1073730817;
	public const int32 EVENT_DNS_CACHE_NETWORK_PERF_WARNING = -2147472598;
	public const int32 EVENT_DNS_CACHE_UNABLE_TO_REACH_SERVER_WARNING = -2147472597;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_TIMEOUT = -2147472498;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_SERVERFAIL = -2147472497;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_NOTSUPP = -2147472496;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_REFUSED = -2147472495;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_SECURITY = -2147472494;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_OTHER = -2147472493;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_TIMEOUT = -2147472492;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_SERVERFAIL = -2147472491;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_NOTSUPP = -2147472490;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_REFUSED = -2147472489;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_SECURITY = -2147472488;
	public const int32 EVENT_DNSAPI_PTR_REGISTRATION_FAILED_OTHER = -2147472487;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_TIMEOUT_PRIMARY_DN = -2147472486;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_SERVERFAIL_PRIMARY_DN = -2147472485;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_NOTSUPP_PRIMARY_DN = -2147472484;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_REFUSED_PRIMARY_DN = -2147472483;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_SECURITY_PRIMARY_DN = -2147472482;
	public const int32 EVENT_DNSAPI_REGISTRATION_FAILED_OTHER_PRIMARY_DN = -2147472481;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_TIMEOUT = -2147472468;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_SERVERFAIL = -2147472467;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_NOTSUPP = -2147472466;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_REFUSED = -2147472465;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_SECURITY = -2147472464;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_OTHER = -2147472463;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_TIMEOUT = -2147472462;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_SERVERFAIL = -2147472461;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_NOTSUPP = -2147472460;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_REFUSED = -2147472459;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_SECURITY = -2147472458;
	public const int32 EVENT_DNSAPI_PTR_DEREGISTRATION_FAILED_OTHER = -2147472457;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_TIMEOUT_PRIMARY_DN = -2147472456;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_SERVERFAIL_PRIMARY_DN = -2147472455;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_NOTSUPP_PRIMARY_DN = -2147472454;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_REFUSED_PRIMARY_DN = -2147472453;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_SECURITY_PRIMARY_DN = -2147472452;
	public const int32 EVENT_DNSAPI_DEREGISTRATION_FAILED_OTHER_PRIMARY_DN = -2147472451;
	public const int32 EVENT_DNSAPI_REGISTERED_ADAPTER = 1073753024;
	public const int32 EVENT_DNSAPI_REGISTERED_PTR = 1073753025;
	public const int32 EVENT_DNSAPI_REGISTERED_ADAPTER_PRIMARY_DN = 1073753026;
	public const int32 EVENT_TRK_INTERNAL_ERROR = -1073729324;
	public const int32 EVENT_TRK_SERVICE_START_SUCCESS = 1073754325;
	public const int32 EVENT_TRK_SERVICE_START_FAILURE = -1073729322;
	public const int32 EVENT_TRK_SERVICE_CORRUPT_LOG = -1073729321;
	public const int32 EVENT_TRK_SERVICE_VOL_QUOTA_EXCEEDED = -2147471144;
	public const int32 EVENT_TRK_SERVICE_VOLUME_CREATE = 1073754329;
	public const int32 EVENT_TRK_SERVICE_VOLUME_CLAIM = 1073754330;
	public const int32 EVENT_TRK_SERVICE_DUPLICATE_VOLIDS = 1073754331;
	public const int32 EVENT_TRK_SERVICE_MOVE_QUOTA_EXCEEDED = -2147471140;
	public const int32 EVENT_FRS_ERROR = -1073728324;
	public const int32 EVENT_FRS_STARTING = 1073755325;
	public const int32 EVENT_FRS_STOPPING = 1073755326;
	public const int32 EVENT_FRS_STOPPED = 1073755327;
	public const int32 EVENT_FRS_STOPPED_FORCE = -1073728320;
	public const int32 EVENT_FRS_STOPPED_ASSERT = -1073728319;
	public const int32 EVENT_FRS_ASSERT = -1073728318;
	public const int32 EVENT_FRS_VOLUME_NOT_SUPPORTED = -1073728317;
	public const int32 EVENT_FRS_LONG_JOIN = -2147470140;
	public const int32 EVENT_FRS_LONG_JOIN_DONE = -2147470139;
	public const int32 EVENT_FRS_CANNOT_COMMUNICATE = -1073728314;
	public const int32 EVENT_FRS_DATABASE_SPACE = -1073728313;
	public const int32 EVENT_FRS_DISK_WRITE_CACHE_ENABLED = -2147470136;
	public const int32 EVENT_FRS_JET_1414 = -1073728311;
	public const int32 EVENT_FRS_SYSVOL_NOT_READY = -2147470134;
	public const int32 EVENT_FRS_SYSVOL_NOT_READY_PRIMARY = -2147470133;
	public const int32 EVENT_FRS_SYSVOL_READY = 1073755340;
	public const int32 EVENT_FRS_ACCESS_CHECKS_DISABLED = -2147470131;
	public const int32 EVENT_FRS_ACCESS_CHECKS_FAILED_USER = -2147470130;
	public const int32 EVENT_FRS_ACCESS_CHECKS_FAILED_UNKNOWN = -1073728305;
	public const int32 EVENT_FRS_MOVED_PREEXISTING = -2147470128;
	public const int32 EVENT_FRS_CANNOT_START_BACKUP_RESTORE_IN_PROGRESS = -1073728303;
	public const int32 EVENT_FRS_STAGING_AREA_FULL = -2147470126;
	public const int32 EVENT_FRS_HUGE_FILE = -2147470125;
	public const int32 EVENT_FRS_CANNOT_CREATE_UUID = -1073728300;
	public const int32 EVENT_FRS_NO_DNS_ATTRIBUTE = -2147470123;
	public const int32 EVENT_FRS_NO_SID = -1073728298;
	public const int32 NTFRSPRF_OPEN_RPC_BINDING_ERROR_SET = -1073728297;
	public const int32 NTFRSPRF_OPEN_RPC_BINDING_ERROR_CONN = -1073728296;
	public const int32 NTFRSPRF_OPEN_RPC_CALL_ERROR_SET = -1073728295;
	public const int32 NTFRSPRF_OPEN_RPC_CALL_ERROR_CONN = -1073728294;
	public const int32 NTFRSPRF_COLLECT_RPC_BINDING_ERROR_SET = -1073728293;
	public const int32 NTFRSPRF_COLLECT_RPC_BINDING_ERROR_CONN = -1073728292;
	public const int32 NTFRSPRF_COLLECT_RPC_CALL_ERROR_SET = -1073728291;
	public const int32 NTFRSPRF_COLLECT_RPC_CALL_ERROR_CONN = -1073728290;
	public const int32 NTFRSPRF_VIRTUALALLOC_ERROR_SET = -1073728289;
	public const int32 NTFRSPRF_VIRTUALALLOC_ERROR_CONN = -1073728288;
	public const int32 NTFRSPRF_REGISTRY_ERROR_SET = -1073728287;
	public const int32 NTFRSPRF_REGISTRY_ERROR_CONN = -1073728286;
	public const int32 EVENT_FRS_ROOT_NOT_VALID = -1073728285;
	public const int32 EVENT_FRS_STAGE_NOT_VALID = -1073728284;
	public const int32 EVENT_FRS_OVERLAPS_LOGGING = -1073728283;
	public const int32 EVENT_FRS_OVERLAPS_WORKING = -1073728282;
	public const int32 EVENT_FRS_OVERLAPS_STAGE = -1073728281;
	public const int32 EVENT_FRS_OVERLAPS_ROOT = -1073728280;
	public const int32 EVENT_FRS_OVERLAPS_OTHER_STAGE = -1073728279;
	public const int32 EVENT_FRS_PREPARE_ROOT_FAILED = -1073728278;
	public const int32 EVENT_FRS_BAD_REG_DATA = -2147470101;
	public const int32 EVENT_FRS_JOIN_FAIL_TIME_SKEW = -1073728276;
	public const int32 EVENT_FRS_RMTCO_TIME_SKEW = -1073728275;
	public const int32 EVENT_FRS_CANT_OPEN_STAGE = -1073728274;
	public const int32 EVENT_FRS_CANT_OPEN_PREINSTALL = -1073728273;
	public const int32 EVENT_FRS_REPLICA_SET_CREATE_FAIL = -1073728272;
	public const int32 EVENT_FRS_REPLICA_SET_CREATE_OK = 1073755377;
	public const int32 EVENT_FRS_REPLICA_SET_CXTIONS = 1073755378;
	public const int32 EVENT_FRS_IN_ERROR_STATE = -1073728269;
	public const int32 EVENT_FRS_REPLICA_NO_ROOT_CHANGE = -1073728268;
	public const int32 EVENT_FRS_DUPLICATE_IN_CXTION_SYSVOL = -1073728267;
	public const int32 EVENT_FRS_DUPLICATE_IN_CXTION = -1073728266;
	public const int32 EVENT_FRS_ROOT_HAS_MOVED = -1073728265;
	public const int32 EVENT_FRS_ERROR_REPLICA_SET_DELETED = -2147470088;
	public const int32 EVENT_FRS_REPLICA_IN_JRNL_WRAP_ERROR = -1073728263;
	public const int32 EVENT_FRS_DS_POLL_ERROR_SUMMARY = -2147470086;
	public const int32 EVENT_PS_GPC_REGISTER_FAILED = -1073727824;
	public const int32 EVENT_PS_NO_RESOURCES_FOR_INIT = -1073727823;
	public const int32 EVENT_PS_REGISTER_PROTOCOL_FAILED = -1073727822;
	public const int32 EVENT_PS_REGISTER_MINIPORT_FAILED = -1073727821;
	public const int32 EVENT_PS_BAD_BESTEFFORT_LIMIT = -2147469548;
	public const int32 EVENT_PS_QUERY_OID_GEN_MAXIMUM_FRAME_SIZE = -1073727723;
	public const int32 EVENT_PS_QUERY_OID_GEN_MAXIMUM_TOTAL_SIZE = -1073727722;
	public const int32 EVENT_PS_QUERY_OID_GEN_LINK_SPEED = -1073727721;
	public const int32 EVENT_PS_BINDING_FAILED = -1073727720;
	public const int32 EVENT_PS_MISSING_ADAPTER_REGISTRY_DATA = -1073727719;
	public const int32 EVENT_PS_REGISTER_ADDRESS_FAMILY_FAILED = -1073727718;
	public const int32 EVENT_PS_INIT_DEVICE_FAILED = -1073727717;
	public const int32 EVENT_PS_WMI_INSTANCE_NAME_FAILED = -1073727716;
	public const int32 EVENT_PS_WAN_LIMITED_BESTEFFORT = -2147469539;
	public const int32 EVENT_PS_RESOURCE_POOL = -1073727714;
	public const int32 EVENT_PS_ADMISSIONCONTROL_OVERFLOW = -2147469537;
	public const int32 EVENT_PS_NETWORK_ADDRESS_FAIL = -1073727712;
	public const int32 EXTRA_EXIT_POINT = -1073727524;
	public const int32 MISSING_EXIT_POINT = -1073727523;
	public const int32 MISSING_VOLUME = -1073727522;
	public const int32 EXTRA_VOLUME = -1073727521;
	public const int32 EXTRA_EXIT_POINT_DELETED = -1073727520;
	public const int32 EXTRA_EXIT_POINT_NOT_DELETED = -1073727519;
	public const int32 MISSING_EXIT_POINT_CREATED = -1073727518;
	public const int32 MISSING_EXIT_POINT_NOT_CREATED = -1073727517;
	public const int32 MISSING_VOLUME_CREATED = -1073727516;
	public const int32 MISSING_VOLUME_NOT_CREATED = -1073727515;
	public const int32 EXTRA_VOLUME_DELETED = -1073727514;
	public const int32 EXTRA_VOLUME_NOT_DELETED = -1073727513;
	public const int32 COULD_NOT_VERIFY_VOLUMES = -1073727512;
	public const int32 KNOWLEDGE_INCONSISTENCY_DETECTED = -1073727511;
	public const int32 PREFIX_MISMATCH = -1073727510;
	public const int32 PREFIX_MISMATCH_FIXED = -1073727509;
	public const int32 PREFIX_MISMATCH_NOT_FIXED = -1073727508;
	public const int32 MACHINE_UNJOINED = -1073727507;
	public const int32 DFS_REFERRAL_REQUEST = 1073756142;
	public const int32 NOT_A_DFS_PATH = 1073756224;
	public const int32 LM_REDIR_FAILURE = 1073756225;
	public const int32 DFS_CONNECTION_FAILURE = 1073756226;
	public const int32 DFS_REFERRAL_FAILURE = 1073756227;
	public const int32 DFS_REFERRAL_SUCCESS = 1073756228;
	public const int32 DFS_MAX_DNR_ATTEMPTS = 1073756229;
	public const int32 DFS_SPECIAL_REFERRAL_FAILURE = 1073756230;
	public const int32 DFS_OPEN_FAILURE = 1073756231;
	public const int32 NET_DFS_ENUM = 1073756324;
	public const int32 NET_DFS_ENUMEX = 1073756325;
	public const int32 DFS_ERROR_CREATE_REPARSEPOINT_FAILURE = -1073727321;
	public const int32 DFS_ERROR_UNSUPPORTED_FILESYSTEM = -1073727320;
	public const int32 DFS_ERROR_OVERLAPPING_DIRECTORIES = -1073727319;
	public const int32 DFS_INFO_ACTIVEDIRECTORY_ONLINE = 1073756332;
	public const int32 DFS_ERROR_TOO_MANY_ERRORS = -1073727315;
	public const int32 DFS_ERROR_WINSOCKINIT_FAILED = -1073727314;
	public const int32 DFS_ERROR_SECURITYINIT_FAILED = -1073727313;
	public const int32 DFS_ERROR_THREADINIT_FAILED = -1073727312;
	public const int32 DFS_ERROR_SITECACHEINIT_FAILED = -1073727311;
	public const int32 DFS_ERROR_ROOTSYNCINIT_FAILED = -1073727310;
	public const int32 DFS_ERROR_CREATEEVENT_FAILED = -1073727309;
	public const int32 DFS_ERROR_COMPUTERINFO_FAILED = -1073727308;
	public const int32 DFS_ERROR_CLUSTERINFO_FAILED = -1073727307;
	public const int32 DFS_ERROR_DCINFO_FAILED = -1073727306;
	public const int32 DFS_ERROR_PREFIXTABLE_FAILED = -1073727305;
	public const int32 DFS_ERROR_HANDLENAMESPACE_FAILED = -1073727304;
	public const int32 DFS_ERROR_REGISTERSTORE_FAILED = -1073727303;
	public const int32 DFS_ERROR_REFLECTIONENGINE_FAILED = -1073727302;
	public const int32 DFS_ERROR_ACTIVEDIRECTORY_OFFLINE = -1073727301;
	public const int32 DFS_ERROR_SITESUPPOR_FAILED = -1073727300;
	public const int32 DFS_ERROR_DSCONNECT_FAILED = -2147469122;
	public const int32 DFS_INFO_DS_RECONNECTED = 1073756353;
	public const int32 DFS_ERROR_NO_DFS_DATA = -1073727294;
	public const int32 DFS_INFO_FINISH_INIT = 1073756355;
	public const int32 DFS_INFO_RECONNECT_DATA = 1073756356;
	public const int32 DFS_INFO_FINISH_BUILDING_NAMESPACE = 1073756357;
	public const int32 DFS_ERROR_ON_ROOT = -2147469114;
	public const int32 DFS_ERROR_MUTLIPLE_ROOTS_NOT_SUPPORTED = -1073727289;
	public const int32 DFS_WARN_DOMAIN_REFERRAL_OVERFLOW = -2147469112;
	public const int32 DFS_INFO_DOMAIN_REFERRAL_MIN_OVERFLOW = 1073756361;
	public const int32 DFS_WARN_INCOMPLETE_MOVE = -2147469110;
	public const int32 DFS_ERROR_RESYNCHRONIZE_FAILED = -1073727285;
	public const int32 DFS_ERROR_REMOVE_LINK_FAILED = -1073727284;
	public const int32 DFS_WARN_METADATA_LINK_TYPE_INCORRECT = -2147469107;
	public const int32 DFS_WARN_METADATA_LINK_INFO_INVALID = -2147469106;
	public const int32 DFS_ERROR_TARGET_LIST_INCORRECT = -1073727281;
	public const int32 DFS_ERROR_LINKS_OVERLAP = -1073727280;
	public const int32 DFS_ERROR_LINK_OVERLAP = -1073727279;
	public const int32 DFS_ERROR_CREATE_REPARSEPOINT_SUCCESS = 1073756370;
	public const int32 DFS_ERROR_DUPLICATE_LINK = -1073727277;
	public const int32 DFS_ERROR_TRUSTED_DOMAIN_INFO_FAILED = -1073727276;
	public const int32 DFS_INFO_TRUSTED_DOMAIN_INFO_SUCCESS = 1073756373;
	public const int32 DFS_ERROR_CROSS_FOREST_TRUST_INFO_FAILED = -1073727274;
	public const int32 DFS_INFO_CROSS_FOREST_TRUST_INFO_SUCCESS = 1073756375;
	public const int32 DFS_INIT_SUCCESS = 1073756376;
	public const int32 DFS_ROOT_SHARE_ACQUIRE_FAILED = -2147469095;
	public const int32 DFS_ROOT_SHARE_ACQUIRE_SUCCESS = 1073756378;
	public const int32 EVENT_BRIDGE_PROTOCOL_REGISTER_FAILED = -1073727224;
	public const int32 EVENT_BRIDGE_MINIPROT_DEVNAME_MISSING = -1073727223;
	public const int32 EVENT_BRIDGE_MINIPORT_REGISTER_FAILED = -1073727222;
	public const int32 EVENT_BRIDGE_DEVICE_CREATION_FAILED = -1073727221;
	public const int32 EVENT_BRIDGE_NO_BRIDGE_MAC_ADDR = -1073727220;
	public const int32 EVENT_BRIDGE_MINIPORT_INIT_FAILED = -1073727219;
	public const int32 EVENT_BRIDGE_ETHERNET_NOT_OFFERED = -1073727218;
	public const int32 EVENT_BRIDGE_THREAD_CREATION_FAILED = -1073727217;
	public const int32 EVENT_BRIDGE_THREAD_REF_FAILED = -1073727216;
	public const int32 EVENT_BRIDGE_PACKET_POOL_CREATION_FAILED = -1073727215;
	public const int32 EVENT_BRIDGE_BUFFER_POOL_CREATION_FAILED = -1073727214;
	public const int32 EVENT_BRIDGE_INIT_MALLOC_FAILED = -1073727213;
	public const int32 EVENT_BRIDGE_ADAPTER_LINK_SPEED_QUERY_FAILED = -1073727124;
	public const int32 EVENT_BRIDGE_ADAPTER_MAC_ADDR_QUERY_FAILED = -1073727123;
	public const int32 EVENT_BRIDGE_ADAPTER_FILTER_FAILED = -1073727122;
	public const int32 EVENT_BRIDGE_ADAPTER_NAME_QUERY_FAILED = -1073727121;
	public const int32 EVENT_BRIDGE_ADAPTER_BIND_FAILED = -1073727120;
	public const int32 EVENT_DAV_REDIR_DELAYED_WRITE_FAILED = -2147468848;
	public const int32 EVENT_WEBCLIENT_CLOSE_PUT_FAILED = -2147468747;
	public const int32 EVENT_WEBCLIENT_CLOSE_DELETE_FAILED = -2147468746;
	public const int32 EVENT_WEBCLIENT_CLOSE_PROPPATCH_FAILED = -2147468745;
	public const int32 EVENT_WEBCLIENT_SETINFO_PROPPATCH_FAILED = -2147468744;
	public const int32 EVENT_WSK_OWNINGTHREAD_PARAMETER_IGNORED = -1073725824;
	public const int32 EVENT_WINSOCK_TDI_FILTER_DETECTED = -2147467647;
	public const int32 EVENT_WINSOCK_CLOSESOCKET_STUCK = -2147467646;
	public const int32 EVENT_EQOS_INFO_MACHINE_POLICY_REFRESH_NO_CHANGE = 1073758324;
	public const int32 EVENT_EQOS_INFO_MACHINE_POLICY_REFRESH_WITH_CHANGE = 1073758325;
	public const int32 EVENT_EQOS_INFO_USER_POLICY_REFRESH_NO_CHANGE = 1073758326;
	public const int32 EVENT_EQOS_INFO_USER_POLICY_REFRESH_WITH_CHANGE = 1073758327;
	public const int32 EVENT_EQOS_INFO_TCP_AUTOTUNING_NOT_CONFIGURED = 1073758328;
	public const int32 EVENT_EQOS_INFO_TCP_AUTOTUNING_OFF = 1073758329;
	public const int32 EVENT_EQOS_INFO_TCP_AUTOTUNING_HIGHLY_RESTRICTED = 1073758330;
	public const int32 EVENT_EQOS_INFO_TCP_AUTOTUNING_RESTRICTED = 1073758331;
	public const int32 EVENT_EQOS_INFO_TCP_AUTOTUNING_NORMAL = 1073758332;
	public const int32 EVENT_EQOS_INFO_APP_MARKING_NOT_CONFIGURED = 1073758333;
	public const int32 EVENT_EQOS_INFO_APP_MARKING_IGNORED = 1073758334;
	public const int32 EVENT_EQOS_INFO_APP_MARKING_ALLOWED = 1073758335;
	public const int32 EVENT_EQOS_INFO_LOCAL_SETTING_DONT_USE_NLA = 1073758336;
	public const int32 EVENT_EQOS_URL_QOS_APPLICATION_CONFLICT = 1073758337;
	public const int32 EVENT_EQOS_WARNING_TEST_1 = -2147467048;
	public const int32 EVENT_EQOS_WARNING_TEST_2 = -2147467047;
	public const int32 EVENT_EQOS_WARNING_MACHINE_POLICY_VERSION = -2147467046;
	public const int32 EVENT_EQOS_WARNING_USER_POLICY_VERSION = -2147467045;
	public const int32 EVENT_EQOS_WARNING_MACHINE_POLICY_PROFILE_NOT_SPECIFIED = -2147467044;
	public const int32 EVENT_EQOS_WARNING_USER_POLICY_PROFILE_NOT_SPECIFIED = -2147467043;
	public const int32 EVENT_EQOS_WARNING_MACHINE_POLICY_QUOTA_EXCEEDED = -2147467042;
	public const int32 EVENT_EQOS_WARNING_USER_POLICY_QUOTA_EXCEEDED = -2147467041;
	public const int32 EVENT_EQOS_WARNING_MACHINE_POLICY_CONFLICT = -2147467040;
	public const int32 EVENT_EQOS_WARNING_USER_POLICY_CONFLICT = -2147467039;
	public const int32 EVENT_EQOS_WARNING_MACHINE_POLICY_NO_FULLPATH_APPNAME = -2147467038;
	public const int32 EVENT_EQOS_WARNING_USER_POLICY_NO_FULLPATH_APPNAME = -2147467037;
	public const int32 EVENT_EQOS_ERROR_MACHINE_POLICY_REFERESH = -1073725124;
	public const int32 EVENT_EQOS_ERROR_USER_POLICY_REFERESH = -1073725123;
	public const int32 EVENT_EQOS_ERROR_OPENING_MACHINE_POLICY_ROOT_KEY = -1073725122;
	public const int32 EVENT_EQOS_ERROR_OPENING_USER_POLICY_ROOT_KEY = -1073725121;
	public const int32 EVENT_EQOS_ERROR_MACHINE_POLICY_KEYNAME_TOO_LONG = -1073725120;
	public const int32 EVENT_EQOS_ERROR_USER_POLICY_KEYNAME_TOO_LONG = -1073725119;
	public const int32 EVENT_EQOS_ERROR_MACHINE_POLICY_KEYNAME_SIZE_ZERO = -1073725118;
	public const int32 EVENT_EQOS_ERROR_USER_POLICY_KEYNAME_SIZE_ZERO = -1073725117;
	public const int32 EVENT_EQOS_ERROR_OPENING_MACHINE_POLICY_SUBKEY = -1073725116;
	public const int32 EVENT_EQOS_ERROR_OPENING_USER_POLICY_SUBKEY = -1073725115;
	public const int32 EVENT_EQOS_ERROR_PROCESSING_MACHINE_POLICY_FIELD = -1073725114;
	public const int32 EVENT_EQOS_ERROR_PROCESSING_USER_POLICY_FIELD = -1073725113;
	public const int32 EVENT_EQOS_ERROR_SETTING_TCP_AUTOTUNING = -1073725112;
	public const int32 EVENT_EQOS_ERROR_SETTING_APP_MARKING = -1073725111;
	public const int32 EVENT_WINNAT_SESSION_LIMIT_REACHED = -2147466648;
	public const uint32 HARDWARE_ADDRESS_LENGTH = 6;
	public const uint32 NETMAN_VARTYPE_ULONG = 0;
	public const uint32 NETMAN_VARTYPE_HARDWARE_ADDRESS = 1;
	public const uint32 NETMAN_VARTYPE_STRING = 2;
	public const uint32 REPL_ROLE_EXPORT = 1;
	public const uint32 REPL_ROLE_IMPORT = 2;
	public const uint32 REPL_ROLE_BOTH = 3;
	public const uint32 REPL_INTERVAL_INFOLEVEL = 1000;
	public const uint32 REPL_PULSE_INFOLEVEL = 1001;
	public const uint32 REPL_GUARDTIME_INFOLEVEL = 1002;
	public const uint32 REPL_RANDOM_INFOLEVEL = 1003;
	public const uint32 REPL_INTEGRITY_FILE = 1;
	public const uint32 REPL_INTEGRITY_TREE = 2;
	public const uint32 REPL_EXTENT_FILE = 1;
	public const uint32 REPL_EXTENT_TREE = 2;
	public const uint32 REPL_EXPORT_INTEGRITY_INFOLEVEL = 1000;
	public const uint32 REPL_EXPORT_EXTENT_INFOLEVEL = 1001;
	public const uint32 REPL_UNLOCK_NOFORCE = 0;
	public const uint32 REPL_UNLOCK_FORCE = 1;
	public const uint32 REPL_STATE_OK = 0;
	public const uint32 REPL_STATE_NO_MASTER = 1;
	public const uint32 REPL_STATE_NO_SYNC = 2;
	public const uint32 REPL_STATE_NEVER_REPLICATED = 3;
	public const String SERVICE_WORKSTATION = "LanmanWorkstation";
	public const String SERVICE_LM20_WORKSTATION = "WORKSTATION";
	public const String WORKSTATION_DISPLAY_NAME = "Workstation";
	public const String SERVICE_SERVER = "LanmanServer";
	public const String SERVICE_LM20_SERVER = "SERVER";
	public const String SERVER_DISPLAY_NAME = "Server";
	public const String SERVICE_BROWSER = "BROWSER";
	public const String SERVICE_LM20_BROWSER = "BROWSER";
	public const String SERVICE_MESSENGER = "MESSENGER";
	public const String SERVICE_LM20_MESSENGER = "MESSENGER";
	public const String SERVICE_NETRUN = "NETRUN";
	public const String SERVICE_LM20_NETRUN = "NETRUN";
	public const String SERVICE_SPOOLER = "SPOOLER";
	public const String SERVICE_LM20_SPOOLER = "SPOOLER";
	public const String SERVICE_ALERTER = "ALERTER";
	public const String SERVICE_LM20_ALERTER = "ALERTER";
	public const String SERVICE_NETLOGON = "NETLOGON";
	public const String SERVICE_LM20_NETLOGON = "NETLOGON";
	public const String SERVICE_NETPOPUP = "NETPOPUP";
	public const String SERVICE_LM20_NETPOPUP = "NETPOPUP";
	public const String SERVICE_SQLSERVER = "SQLSERVER";
	public const String SERVICE_LM20_SQLSERVER = "SQLSERVER";
	public const String SERVICE_REPL = "REPLICATOR";
	public const String SERVICE_LM20_REPL = "REPLICATOR";
	public const String SERVICE_RIPL = "REMOTEBOOT";
	public const String SERVICE_LM20_RIPL = "REMOTEBOOT";
	public const String SERVICE_TIMESOURCE = "TIMESOURCE";
	public const String SERVICE_LM20_TIMESOURCE = "TIMESOURCE";
	public const String SERVICE_AFP = "AFP";
	public const String SERVICE_LM20_AFP = "AFP";
	public const String SERVICE_UPS = "UPS";
	public const String SERVICE_LM20_UPS = "UPS";
	public const String SERVICE_XACTSRV = "XACTSRV";
	public const String SERVICE_LM20_XACTSRV = "XACTSRV";
	public const String SERVICE_TCPIP = "TCPIP";
	public const String SERVICE_LM20_TCPIP = "TCPIP";
	public const String SERVICE_NBT = "NBT";
	public const String SERVICE_LM20_NBT = "NBT";
	public const String SERVICE_LMHOSTS = "LMHOSTS";
	public const String SERVICE_LM20_LMHOSTS = "LMHOSTS";
	public const String SERVICE_TELNET = "Telnet";
	public const String SERVICE_LM20_TELNET = "Telnet";
	public const String SERVICE_SCHEDULE = "Schedule";
	public const String SERVICE_LM20_SCHEDULE = "Schedule";
	public const String SERVICE_NTLMSSP = "NtLmSsp";
	public const String SERVICE_DHCP = "DHCP";
	public const String SERVICE_LM20_DHCP = "DHCP";
	public const String SERVICE_NWSAP = "NwSapAgent";
	public const String SERVICE_LM20_NWSAP = "NwSapAgent";
	public const String NWSAP_DISPLAY_NAME = "NW Sap Agent";
	public const String SERVICE_NWCS = "NWCWorkstation";
	public const String SERVICE_DNS_CACHE = "DnsCache";
	public const String SERVICE_W32TIME = "w32time";
	public const String SERVCE_LM20_W32TIME = "w32time";
	public const String SERVICE_KDC = "kdc";
	public const String SERVICE_LM20_KDC = "kdc";
	public const String SERVICE_RPCLOCATOR = "RPCLOCATOR";
	public const String SERVICE_LM20_RPCLOCATOR = "RPCLOCATOR";
	public const String SERVICE_TRKSVR = "TrkSvr";
	public const String SERVICE_LM20_TRKSVR = "TrkSvr";
	public const String SERVICE_TRKWKS = "TrkWks";
	public const String SERVICE_LM20_TRKWKS = "TrkWks";
	public const String SERVICE_NTFRS = "NtFrs";
	public const String SERVICE_LM20_NTFRS = "NtFrs";
	public const String SERVICE_ISMSERV = "IsmServ";
	public const String SERVICE_LM20_ISMSERV = "IsmServ";
	public const String SERVICE_NTDS = "NTDS";
	public const String SERVICE_LM20_NTDS = "NTDS";
	public const String SERVICE_ADWS = "ADWS";
	public const String SERVICE_DSROLE = "DsRoleSvc";
	public const String SERVICE_LM20_DSROLE = "DsRoleSvc";
	public const HRESULT NETCFG_E_ALREADY_INITIALIZED = -2147180512;
	public const HRESULT NETCFG_E_NOT_INITIALIZED = -2147180511;
	public const HRESULT NETCFG_E_IN_USE = -2147180510;
	public const HRESULT NETCFG_E_NO_WRITE_LOCK = -2147180508;
	public const HRESULT NETCFG_E_NEED_REBOOT = -2147180507;
	public const HRESULT NETCFG_E_ACTIVE_RAS_CONNECTIONS = -2147180506;
	public const HRESULT NETCFG_E_ADAPTER_NOT_FOUND = -2147180505;
	public const HRESULT NETCFG_E_COMPONENT_REMOVED_PENDING_REBOOT = -2147180504;
	public const HRESULT NETCFG_E_MAX_FILTER_LIMIT = -2147180503;
	public const HRESULT NETCFG_E_VMSWITCH_ACTIVE_OVER_ADAPTER = -2147180502;
	public const HRESULT NETCFG_E_DUPLICATE_INSTANCEID = -2147180501;
	public const HRESULT NETCFG_S_REBOOT = 303136;
	public const HRESULT NETCFG_S_DISABLE_QUERY = 303138;
	public const HRESULT NETCFG_S_STILL_REFERENCED = 303139;
	public const HRESULT NETCFG_S_CAUSED_SETUP_CHANGE = 303140;
	public const HRESULT NETCFG_S_COMMIT_NOW = 303141;
	public const String NETCFG_CLIENT_CID_MS_MSClient = "ms_msclient";
	public const String NETCFG_SERVICE_CID_MS_SERVER = "ms_server";
	public const String NETCFG_SERVICE_CID_MS_NETBIOS = "ms_netbios";
	public const String NETCFG_SERVICE_CID_MS_PSCHED = "ms_pschedpc";
	public const String NETCFG_SERVICE_CID_MS_WLBS = "ms_wlbs";
	public const String NETCFG_TRANS_CID_MS_APPLETALK = "ms_appletalk";
	public const String NETCFG_TRANS_CID_MS_NETBEUI = "ms_netbeui";
	public const String NETCFG_TRANS_CID_MS_NETMON = "ms_netmon";
	public const String NETCFG_TRANS_CID_MS_NWIPX = "ms_nwipx";
	public const String NETCFG_TRANS_CID_MS_NWSPX = "ms_nwspx";
	public const String NETCFG_TRANS_CID_MS_TCPIP = "ms_tcpip";
	public const uint32 WZC_PROFILE_SUCCESS = 0;
	public const uint32 WZC_PROFILE_XML_ERROR_NO_VERSION = 1;
	public const uint32 WZC_PROFILE_XML_ERROR_BAD_VERSION = 2;
	public const uint32 WZC_PROFILE_XML_ERROR_UNSUPPORTED_VERSION = 3;
	public const uint32 WZC_PROFILE_XML_ERROR_SSID_NOT_FOUND = 4;
	public const uint32 WZC_PROFILE_XML_ERROR_BAD_SSID = 5;
	public const uint32 WZC_PROFILE_XML_ERROR_CONNECTION_TYPE = 6;
	public const uint32 WZC_PROFILE_XML_ERROR_AUTHENTICATION = 7;
	public const uint32 WZC_PROFILE_XML_ERROR_ENCRYPTION = 8;
	public const uint32 WZC_PROFILE_XML_ERROR_KEY_PROVIDED_AUTOMATICALLY = 9;
	public const uint32 WZC_PROFILE_XML_ERROR_1X_ENABLED = 10;
	public const uint32 WZC_PROFILE_XML_ERROR_EAP_METHOD = 11;
	public const uint32 WZC_PROFILE_XML_ERROR_BAD_KEY_INDEX = 12;
	public const uint32 WZC_PROFILE_XML_ERROR_KEY_INDEX_RANGE = 13;
	public const uint32 WZC_PROFILE_XML_ERROR_BAD_NETWORK_KEY = 14;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_INVALID_AUTH_FOR_CONNECTION_TYPE = 15;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_INVALID_ENCRYPTION_FOR_AUTHMODE = 16;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_KEY_REQUIRED = 17;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_KEY_INDEX_REQUIRED = 18;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_KEY_INDEX_NOT_APPLICABLE = 19;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_1X_NOT_ALLOWED = 20;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_1X_NOT_ALLOWED_KEY_REQUIRED = 21;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_1X_NOT_ENABLED_KEY_PROVIDED = 22;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_EAP_METHOD_REQUIRED = 23;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_EAP_METHOD_NOT_APPLICABLE = 24;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_WPA_NOT_SUPPORTED = 25;
	public const uint32 WZC_PROFILE_CONFIG_ERROR_WPA_ENCRYPTION_NOT_SUPPORTED = 26;
	public const uint32 WZC_PROFILE_SET_ERROR_DUPLICATE_NETWORK = 27;
	public const uint32 WZC_PROFILE_SET_ERROR_MEMORY_ALLOCATION = 28;
	public const uint32 WZC_PROFILE_SET_ERROR_READING_1X_CONFIG = 29;
	public const uint32 WZC_PROFILE_SET_ERROR_WRITING_1X_CONFIG = 30;
	public const uint32 WZC_PROFILE_SET_ERROR_WRITING_WZC_CFG = 31;
	public const uint32 WZC_PROFILE_API_ERROR_NOT_SUPPORTED = 32;
	public const uint32 WZC_PROFILE_API_ERROR_FAILED_TO_LOAD_XML = 33;
	public const uint32 WZC_PROFILE_API_ERROR_FAILED_TO_LOAD_SCHEMA = 34;
	public const uint32 WZC_PROFILE_API_ERROR_XML_VALIDATION_FAILED = 35;
	public const uint32 WZC_PROFILE_API_ERROR_INTERNAL = 36;
	public const uint32 RF_ROUTING = 1;
	public const uint32 RF_ROUTINGV6 = 2;
	public const uint32 RF_DEMAND_UPDATE_ROUTES = 4;
	public const uint32 RF_ADD_ALL_INTERFACES = 16;
	public const uint32 RF_MULTICAST = 32;
	public const uint32 RF_POWER = 64;
	public const uint32 MS_ROUTER_VERSION = 1536;
	public const uint32 ROUTING_DOMAIN_INFO_REVISION_1 = 1;
	public const uint32 INTERFACE_INFO_REVISION_1 = 1;
	public const uint32 IR_PROMISCUOUS = 0;
	public const uint32 IR_PROMISCUOUS_MULTICAST = 1;
	public const uint32 PROTO_IP_MSDP = 9;
	public const uint32 PROTO_IP_IGMP = 10;
	public const uint32 PROTO_IP_BGMP = 11;
	public const uint32 PROTO_IP_VRRP = 112;
	public const uint32 PROTO_IP_BOOTP = 9999;
	public const uint32 PROTO_IPV6_DHCP = 999;
	public const uint32 PROTO_IP_DNS_PROXY = 10003;
	public const uint32 PROTO_IP_DHCP_ALLOCATOR = 10004;
	public const uint32 PROTO_IP_NAT = 10005;
	public const uint32 PROTO_IP_DIFFSERV = 10008;
	public const uint32 PROTO_IP_MGM = 10009;
	public const uint32 PROTO_IP_ALG = 10010;
	public const uint32 PROTO_IP_H323 = 10011;
	public const uint32 PROTO_IP_FTP = 10012;
	public const uint32 PROTO_IP_DTP = 10013;
	public const uint32 PROTO_TYPE_UCAST = 0;
	public const uint32 PROTO_TYPE_MCAST = 1;
	public const uint32 PROTO_TYPE_MS0 = 2;
	public const uint32 PROTO_TYPE_MS1 = 3;
	public const uint32 PROTO_VENDOR_MS0 = 0;
	public const uint32 PROTO_VENDOR_MS1 = 311;
	public const uint32 PROTO_VENDOR_MS2 = 16383;
	public const uint32 IPX_PROTOCOL_BASE = 131071;
	public const uint32 IPX_PROTOCOL_RIP = 131072;
	public const uint32 RIS_INTERFACE_ADDRESS_CHANGE = 0;
	public const uint32 RIS_INTERFACE_ENABLED = 1;
	public const uint32 RIS_INTERFACE_DISABLED = 2;
	public const uint32 RIS_INTERFACE_MEDIA_PRESENT = 3;
	public const uint32 RIS_INTERFACE_MEDIA_ABSENT = 4;
	public const uint32 MRINFO_TUNNEL_FLAG = 1;
	public const uint32 MRINFO_PIM_FLAG = 4;
	public const uint32 MRINFO_DOWN_FLAG = 16;
	public const uint32 MRINFO_DISABLED_FLAG = 32;
	public const uint32 MRINFO_QUERIER_FLAG = 64;
	public const uint32 MRINFO_LEAF_FLAG = 128;
	public const uint32 MFE_NO_ERROR = 0;
	public const uint32 MFE_REACHED_CORE = 1;
	public const uint32 MFE_OIF_PRUNED = 5;
	public const uint32 MFE_PRUNED_UPSTREAM = 4;
	public const uint32 MFE_OLD_ROUTER = 11;
	public const uint32 MFE_NOT_FORWARDING = 2;
	public const uint32 MFE_WRONG_IF = 3;
	public const uint32 MFE_BOUNDARY_REACHED = 6;
	public const uint32 MFE_NO_MULTICAST = 7;
	public const uint32 MFE_IIF = 8;
	public const uint32 MFE_NO_ROUTE = 9;
	public const uint32 MFE_NOT_LAST_HOP = 10;
	public const uint32 MFE_PROHIBITED = 12;
	public const uint32 MFE_NO_SPACE = 13;
	public const String REGISTER_PROTOCOL_ENTRY_POINT_STRING = "RegisterProtocol";
	public const uint32 ALIGN_SIZE = 8;
	public const uint32 RTR_INFO_BLOCK_VERSION = 1;
	public const uint32 TRACE_USE_FILE = 1;
	public const uint32 TRACE_USE_CONSOLE = 2;
	public const uint32 TRACE_NO_SYNCH = 4;
	public const uint32 TRACE_NO_STDINFO = 1;
	public const uint32 TRACE_USE_MASK = 2;
	public const uint32 TRACE_USE_MSEC = 4;
	public const uint32 TRACE_USE_DATE = 8;
	public const uint32 INVALID_TRACEID = 4294967295;
	public const uint32 RTUTILS_MAX_PROTOCOL_NAME_LEN = 40;
	public const uint32 RTUTILS_MAX_PROTOCOL_DLL_LEN = 48;
	public const uint32 MAX_PROTOCOL_NAME_LEN = 40;
	public const uint32 MAX_PROTOCOL_DLL_LEN = 48;
}
#endregion

#region Enums

[AllowDuplicates]
public enum NET_REQUEST_PROVISION_OPTIONS : uint32
{
	NETSETUP_PROVISION_ONLINE_CALLER = 1073741824,
}


[AllowDuplicates]
public enum NET_JOIN_DOMAIN_JOIN_OPTIONS : uint32
{
	NETSETUP_JOIN_DOMAIN = 1,
	NETSETUP_ACCT_CREATE = 2,
	NETSETUP_WIN9X_UPGRADE = 16,
	NETSETUP_DOMAIN_JOIN_IF_JOINED = 32,
	NETSETUP_JOIN_UNSECURE = 64,
	NETSETUP_MACHINE_PWD_PASSED = 128,
	NETSETUP_DEFER_SPN_SET = 256,
	NETSETUP_JOIN_DC_ACCOUNT = 512,
	NETSETUP_JOIN_WITH_NEW_NAME = 1024,
	NETSETUP_JOIN_READONLY = 2048,
	NETSETUP_AMBIGUOUS_DC = 4096,
	NETSETUP_NO_NETLOGON_CACHE = 8192,
	NETSETUP_DONT_CONTROL_SERVICES = 16384,
	NETSETUP_SET_MACHINE_NAME = 32768,
	NETSETUP_FORCE_SPN_SET = 65536,
	NETSETUP_NO_ACCT_REUSE = 131072,
	NETSETUP_IGNORE_UNSUPPORTED_FLAGS = 268435456,
}


[AllowDuplicates]
public enum NET_REMOTE_COMPUTER_SUPPORTS_OPTIONS : int32
{
	SUPPORTS_REMOTE_ADMIN_PROTOCOL = 2,
	SUPPORTS_RPC = 4,
	SUPPORTS_SAM_PROTOCOL = 8,
	SUPPORTS_UNICODE = 16,
	SUPPORTS_LOCAL = 32,
}


[AllowDuplicates]
public enum FORCE_LEVEL_FLAGS : uint32
{
	USE_NOFORCE = 0,
	USE_FORCE = 1,
	USE_LOTS_OF_FORCE = 2,
}


[AllowDuplicates]
public enum NET_SERVER_TYPE : uint32
{
	SV_TYPE_WORKSTATION = 1,
	SV_TYPE_SERVER = 2,
	SV_TYPE_SQLSERVER = 4,
	SV_TYPE_DOMAIN_CTRL = 8,
	SV_TYPE_DOMAIN_BAKCTRL = 16,
	SV_TYPE_TIME_SOURCE = 32,
	SV_TYPE_AFP = 64,
	SV_TYPE_NOVELL = 128,
	SV_TYPE_DOMAIN_MEMBER = 256,
	SV_TYPE_PRINTQ_SERVER = 512,
	SV_TYPE_DIALIN_SERVER = 1024,
	SV_TYPE_XENIX_SERVER = 2048,
	SV_TYPE_SERVER_UNIX = 2048,
	SV_TYPE_NT = 4096,
	SV_TYPE_WFW = 8192,
	SV_TYPE_SERVER_MFPN = 16384,
	SV_TYPE_SERVER_NT = 32768,
	SV_TYPE_POTENTIAL_BROWSER = 65536,
	SV_TYPE_BACKUP_BROWSER = 131072,
	SV_TYPE_MASTER_BROWSER = 262144,
	SV_TYPE_DOMAIN_MASTER = 524288,
	SV_TYPE_SERVER_OSF = 1048576,
	SV_TYPE_SERVER_VMS = 2097152,
	SV_TYPE_WINDOWS = 4194304,
	SV_TYPE_DFS = 8388608,
	SV_TYPE_CLUSTER_NT = 16777216,
	SV_TYPE_TERMINALSERVER = 33554432,
	SV_TYPE_CLUSTER_VS_NT = 67108864,
	SV_TYPE_DCE = 268435456,
	SV_TYPE_ALTERNATE_XPORT = 536870912,
	SV_TYPE_LOCAL_LIST_ONLY = 1073741824,
	SV_TYPE_DOMAIN_ENUM = 2147483648,
	SV_TYPE_ALL = 4294967295,
}


[AllowDuplicates]
public enum NET_USER_ENUM_FILTER_FLAGS : uint32
{
	FILTER_TEMP_DUPLICATE_ACCOUNT = 1,
	FILTER_NORMAL_ACCOUNT = 2,
	FILTER_INTERDOMAIN_TRUST_ACCOUNT = 8,
	FILTER_WORKSTATION_TRUST_ACCOUNT = 16,
	FILTER_SERVER_TRUST_ACCOUNT = 32,
}


[AllowDuplicates]
public enum NETSETUP_PROVISION : uint32
{
	NETSETUP_PROVISION_DOWNLEVEL_PRIV_SUPPORT = 1,
	NETSETUP_PROVISION_REUSE_ACCOUNT = 2,
	NETSETUP_PROVISION_USE_DEFAULT_PASSWORD = 4,
	NETSETUP_PROVISION_SKIP_ACCOUNT_SEARCH = 8,
	NETSETUP_PROVISION_ROOT_CA_CERTS = 16,
}


[AllowDuplicates]
public enum USER_ACCOUNT_FLAGS : uint32
{
	UF_SCRIPT = 1,
	UF_ACCOUNTDISABLE = 2,
	UF_HOMEDIR_REQUIRED = 8,
	UF_PASSWD_NOTREQD = 32,
	UF_PASSWD_CANT_CHANGE = 64,
	UF_LOCKOUT = 16,
	UF_DONT_EXPIRE_PASSWD = 65536,
	UF_ENCRYPTED_TEXT_PASSWORD_ALLOWED = 128,
	UF_NOT_DELEGATED = 1048576,
	UF_SMARTCARD_REQUIRED = 262144,
	UF_USE_DES_KEY_ONLY = 2097152,
	UF_DONT_REQUIRE_PREAUTH = 4194304,
	UF_TRUSTED_FOR_DELEGATION = 524288,
	UF_PASSWORD_EXPIRED = 8388608,
	UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION = 16777216,
}


[AllowDuplicates]
public enum AF_OP : uint32
{
	AF_OP_PRINT = 1,
	AF_OP_COMM = 2,
	AF_OP_SERVER = 4,
	AF_OP_ACCOUNTS = 8,
}


[AllowDuplicates]
public enum SERVER_INFO_SECURITY : uint32
{
	SV_SHARESECURITY = 0,
	SV_USERSECURITY = 1,
}


[AllowDuplicates]
public enum USER_PRIV : uint32
{
	USER_PRIV_GUEST = 0,
	USER_PRIV_USER = 1,
	USER_PRIV_ADMIN = 2,
}


[AllowDuplicates]
public enum USE_INFO_ASG_TYPE : uint32
{
	USE_WILDCARD = 4294967295,
	USE_DISKDEV = 0,
	USE_SPOOLDEV = 1,
	USE_IPC = 3,
}


[AllowDuplicates]
public enum SERVER_INFO_HIDDEN : uint32
{
	SV_VISIBLE = 0,
	SV_HIDDEN = 1,
}


[AllowDuplicates]
public enum USER_MODALS_ROLES : uint32
{
	UAS_ROLE_STANDALONE = 0,
	UAS_ROLE_MEMBER = 1,
	UAS_ROLE_BACKUP = 2,
	UAS_ROLE_PRIMARY = 3,
}


[AllowDuplicates]
public enum NET_VALIDATE_PASSWORD_TYPE : int32
{
	NetValidateAuthentication = 1,
	NetValidatePasswordChange = 2,
	NetValidatePasswordReset = 3,
}


[AllowDuplicates]
public enum MSA_INFO_LEVEL : int32
{
	MsaInfoLevel0 = 0,
	MsaInfoLevelMax = 1,
}


[AllowDuplicates]
public enum MSA_INFO_STATE : int32
{
	MsaInfoNotExist = 1,
	MsaInfoNotService = 2,
	MsaInfoCannotInstall = 3,
	MsaInfoCanInstall = 4,
	MsaInfoInstalled = 5,
}


[AllowDuplicates]
public enum TRANSPORT_TYPE : int32
{
	UseTransportType_None = 0,
	UseTransportType_Wsk = 1,
	UseTransportType_Quic = 2,
}


[AllowDuplicates]
public enum NETSETUP_NAME_TYPE : int32
{
	NetSetupUnknown = 0,
	NetSetupMachine = 1,
	NetSetupWorkgroup = 2,
	NetSetupDomain = 3,
	NetSetupNonExistentDomain = 4,
	NetSetupDnsMachine = 5,
}


[AllowDuplicates]
public enum DSREG_JOIN_TYPE : int32
{
	DSREG_UNKNOWN_JOIN = 0,
	DSREG_DEVICE_JOIN = 1,
	DSREG_WORKPLACE_JOIN = 2,
}


[AllowDuplicates]
public enum NET_COMPUTER_NAME_TYPE : int32
{
	NetPrimaryComputerName = 0,
	NetAlternateComputerNames = 1,
	NetAllComputerNames = 2,
	NetComputerNameTypeMax = 3,
}


[AllowDuplicates]
public enum NETSETUP_JOIN_STATUS : int32
{
	NetSetupUnknownStatus = 0,
	NetSetupUnjoined = 1,
	NetSetupWorkgroupName = 2,
	NetSetupDomainName = 3,
}


[AllowDuplicates]
public enum OBO_TOKEN_TYPE : int32
{
	OBO_USER = 1,
	OBO_COMPONENT = 2,
	OBO_SOFTWARE = 3,
}


[AllowDuplicates]
public enum COMPONENT_CHARACTERISTICS : int32
{
	NCF_VIRTUAL = 1,
	NCF_SOFTWARE_ENUMERATED = 2,
	NCF_PHYSICAL = 4,
	NCF_HIDDEN = 8,
	NCF_NO_SERVICE = 16,
	NCF_NOT_USER_REMOVABLE = 32,
	NCF_MULTIPORT_INSTANCED_ADAPTER = 64,
	NCF_HAS_UI = 128,
	NCF_SINGLE_INSTANCE = 256,
	NCF_FILTER = 1024,
	NCF_DONTEXPOSELOWER = 4096,
	NCF_HIDE_BINDING = 8192,
	NCF_NDIS_PROTOCOL = 16384,
	NCF_FIXED_BINDING = 131072,
	NCF_LW_FILTER = 262144,
}


[AllowDuplicates]
public enum NCRP_FLAGS : int32
{
	NCRP_QUERY_PROPERTY_UI = 1,
	NCRP_SHOW_PROPERTY_UI = 2,
}


[AllowDuplicates]
public enum SUPPORTS_BINDING_INTERFACE_FLAGS : int32
{
	NCF_LOWER = 1,
	NCF_UPPER = 2,
}


[AllowDuplicates]
public enum ENUM_BINDING_PATHS_FLAGS : int32
{
	EBP_ABOVE = 1,
	EBP_BELOW = 2,
}


[AllowDuplicates]
public enum NCPNP_RECONFIG_LAYER : int32
{
	NCRL_NDIS = 1,
	NCRL_TDI = 2,
}


[AllowDuplicates]
public enum NETWORK_INSTALL_TIME : int32
{
	NSF_PRIMARYINSTALL = 1,
	NSF_POSTSYSINSTALL = 2,
}


[AllowDuplicates]
public enum NETWORK_UPGRADE_TYPE : int32
{
	NSF_WIN16_UPGRADE = 16,
	NSF_WIN95_UPGRADE = 32,
	NSF_WINNT_WKS_UPGRADE = 64,
	NSF_WINNT_SVR_UPGRADE = 128,
	NSF_WINNT_SBS_UPGRADE = 256,
	NSF_COMPONENT_UPDATE = 512,
}


[AllowDuplicates]
public enum DEFAULT_PAGES : int32
{
	DPP_ADVANCED = 1,
}


[AllowDuplicates]
public enum BIND_FLAGS1 : int32
{
	NCN_ADD = 1,
	NCN_REMOVE = 2,
	NCN_UPDATE = 4,
	NCN_ENABLE = 16,
	NCN_DISABLE = 32,
	NCN_BINDING_PATH = 256,
	NCN_PROPERTYCHANGE = 512,
	NCN_NET = 65536,
	NCN_NETTRANS = 131072,
	NCN_NETCLIENT = 262144,
	NCN_NETSERVICE = 524288,
}


[AllowDuplicates]
public enum RASCON_UIINFO_FLAGS : int32
{
	RCUIF_VPN = 1,
	RCUIF_DEMAND_DIAL = 2,
	RCUIF_NOT_ADMIN = 4,
	RCUIF_USE_IPv4_STATICADDRESS = 8,
	RCUIF_USE_IPv4_NAME_SERVERS = 16,
	RCUIF_USE_IPv4_REMOTE_GATEWAY = 32,
	RCUIF_USE_IPv4_EXPLICIT_METRIC = 64,
	RCUIF_USE_HEADER_COMPRESSION = 128,
	RCUIF_USE_DISABLE_REGISTER_DNS = 256,
	RCUIF_USE_PRIVATE_DNS_SUFFIX = 512,
	RCUIF_ENABLE_NBT = 1024,
	RCUIF_USE_IPv6_STATICADDRESS = 2048,
	RCUIF_USE_IPv6_NAME_SERVERS = 4096,
	RCUIF_USE_IPv6_REMOTE_GATEWAY = 8192,
	RCUIF_USE_IPv6_EXPLICIT_METRIC = 16384,
	RCUIF_DISABLE_CLASS_BASED_ROUTE = 32768,
}

#endregion

#region Function Pointers
public function void WORKERFUNCTION(void* param0);

#endregion

#region Structs
[CRepr]
public struct USER_INFO_0
{
	public PWSTR usri0_name;
}

[CRepr]
public struct USER_INFO_1
{
	public PWSTR usri1_name;
	public PWSTR usri1_password;
	public uint32 usri1_password_age;
	public USER_PRIV usri1_priv;
	public PWSTR usri1_home_dir;
	public PWSTR usri1_comment;
	public USER_ACCOUNT_FLAGS usri1_flags;
	public PWSTR usri1_script_path;
}

[CRepr]
public struct USER_INFO_2
{
	public PWSTR usri2_name;
	public PWSTR usri2_password;
	public uint32 usri2_password_age;
	public USER_PRIV usri2_priv;
	public PWSTR usri2_home_dir;
	public PWSTR usri2_comment;
	public USER_ACCOUNT_FLAGS usri2_flags;
	public PWSTR usri2_script_path;
	public AF_OP usri2_auth_flags;
	public PWSTR usri2_full_name;
	public PWSTR usri2_usr_comment;
	public PWSTR usri2_parms;
	public PWSTR usri2_workstations;
	public uint32 usri2_last_logon;
	public uint32 usri2_last_logoff;
	public uint32 usri2_acct_expires;
	public uint32 usri2_max_storage;
	public uint32 usri2_units_per_week;
	public uint8* usri2_logon_hours;
	public uint32 usri2_bad_pw_count;
	public uint32 usri2_num_logons;
	public PWSTR usri2_logon_server;
	public uint32 usri2_country_code;
	public uint32 usri2_code_page;
}

[CRepr]
public struct USER_INFO_3
{
	public PWSTR usri3_name;
	public PWSTR usri3_password;
	public uint32 usri3_password_age;
	public USER_PRIV usri3_priv;
	public PWSTR usri3_home_dir;
	public PWSTR usri3_comment;
	public USER_ACCOUNT_FLAGS usri3_flags;
	public PWSTR usri3_script_path;
	public AF_OP usri3_auth_flags;
	public PWSTR usri3_full_name;
	public PWSTR usri3_usr_comment;
	public PWSTR usri3_parms;
	public PWSTR usri3_workstations;
	public uint32 usri3_last_logon;
	public uint32 usri3_last_logoff;
	public uint32 usri3_acct_expires;
	public uint32 usri3_max_storage;
	public uint32 usri3_units_per_week;
	public uint8* usri3_logon_hours;
	public uint32 usri3_bad_pw_count;
	public uint32 usri3_num_logons;
	public PWSTR usri3_logon_server;
	public uint32 usri3_country_code;
	public uint32 usri3_code_page;
	public uint32 usri3_user_id;
	public uint32 usri3_primary_group_id;
	public PWSTR usri3_profile;
	public PWSTR usri3_home_dir_drive;
	public uint32 usri3_password_expired;
}

[CRepr]
public struct USER_INFO_4
{
	public PWSTR usri4_name;
	public PWSTR usri4_password;
	public uint32 usri4_password_age;
	public USER_PRIV usri4_priv;
	public PWSTR usri4_home_dir;
	public PWSTR usri4_comment;
	public USER_ACCOUNT_FLAGS usri4_flags;
	public PWSTR usri4_script_path;
	public AF_OP usri4_auth_flags;
	public PWSTR usri4_full_name;
	public PWSTR usri4_usr_comment;
	public PWSTR usri4_parms;
	public PWSTR usri4_workstations;
	public uint32 usri4_last_logon;
	public uint32 usri4_last_logoff;
	public uint32 usri4_acct_expires;
	public uint32 usri4_max_storage;
	public uint32 usri4_units_per_week;
	public uint8* usri4_logon_hours;
	public uint32 usri4_bad_pw_count;
	public uint32 usri4_num_logons;
	public PWSTR usri4_logon_server;
	public uint32 usri4_country_code;
	public uint32 usri4_code_page;
	public PSID usri4_user_sid;
	public uint32 usri4_primary_group_id;
	public PWSTR usri4_profile;
	public PWSTR usri4_home_dir_drive;
	public uint32 usri4_password_expired;
}

[CRepr]
public struct USER_INFO_10
{
	public PWSTR usri10_name;
	public PWSTR usri10_comment;
	public PWSTR usri10_usr_comment;
	public PWSTR usri10_full_name;
}

[CRepr]
public struct USER_INFO_11
{
	public PWSTR usri11_name;
	public PWSTR usri11_comment;
	public PWSTR usri11_usr_comment;
	public PWSTR usri11_full_name;
	public USER_PRIV usri11_priv;
	public AF_OP usri11_auth_flags;
	public uint32 usri11_password_age;
	public PWSTR usri11_home_dir;
	public PWSTR usri11_parms;
	public uint32 usri11_last_logon;
	public uint32 usri11_last_logoff;
	public uint32 usri11_bad_pw_count;
	public uint32 usri11_num_logons;
	public PWSTR usri11_logon_server;
	public uint32 usri11_country_code;
	public PWSTR usri11_workstations;
	public uint32 usri11_max_storage;
	public uint32 usri11_units_per_week;
	public uint8* usri11_logon_hours;
	public uint32 usri11_code_page;
}

[CRepr]
public struct USER_INFO_20
{
	public PWSTR usri20_name;
	public PWSTR usri20_full_name;
	public PWSTR usri20_comment;
	public USER_ACCOUNT_FLAGS usri20_flags;
	public uint32 usri20_user_id;
}

[CRepr]
public struct USER_INFO_21
{
	public uint8[16] usri21_password;
}

[CRepr]
public struct USER_INFO_22
{
	public PWSTR usri22_name;
	public uint8[16] usri22_password;
	public uint32 usri22_password_age;
	public USER_PRIV usri22_priv;
	public PWSTR usri22_home_dir;
	public PWSTR usri22_comment;
	public USER_ACCOUNT_FLAGS usri22_flags;
	public PWSTR usri22_script_path;
	public AF_OP usri22_auth_flags;
	public PWSTR usri22_full_name;
	public PWSTR usri22_usr_comment;
	public PWSTR usri22_parms;
	public PWSTR usri22_workstations;
	public uint32 usri22_last_logon;
	public uint32 usri22_last_logoff;
	public uint32 usri22_acct_expires;
	public uint32 usri22_max_storage;
	public uint32 usri22_units_per_week;
	public uint8* usri22_logon_hours;
	public uint32 usri22_bad_pw_count;
	public uint32 usri22_num_logons;
	public PWSTR usri22_logon_server;
	public uint32 usri22_country_code;
	public uint32 usri22_code_page;
}

[CRepr]
public struct USER_INFO_23
{
	public PWSTR usri23_name;
	public PWSTR usri23_full_name;
	public PWSTR usri23_comment;
	public USER_ACCOUNT_FLAGS usri23_flags;
	public PSID usri23_user_sid;
}

[CRepr]
public struct USER_INFO_24
{
	public BOOL usri24_internet_identity;
	public uint32 usri24_flags;
	public PWSTR usri24_internet_provider_name;
	public PWSTR usri24_internet_principal_name;
	public PSID usri24_user_sid;
}

[CRepr]
public struct USER_INFO_1003
{
	public PWSTR usri1003_password;
}

[CRepr]
public struct USER_INFO_1005
{
	public USER_PRIV usri1005_priv;
}

[CRepr]
public struct USER_INFO_1006
{
	public PWSTR usri1006_home_dir;
}

[CRepr]
public struct USER_INFO_1007
{
	public PWSTR usri1007_comment;
}

[CRepr]
public struct USER_INFO_1008
{
	public USER_ACCOUNT_FLAGS usri1008_flags;
}

[CRepr]
public struct USER_INFO_1009
{
	public PWSTR usri1009_script_path;
}

[CRepr]
public struct USER_INFO_1010
{
	public AF_OP usri1010_auth_flags;
}

[CRepr]
public struct USER_INFO_1011
{
	public PWSTR usri1011_full_name;
}

[CRepr]
public struct USER_INFO_1012
{
	public PWSTR usri1012_usr_comment;
}

[CRepr]
public struct USER_INFO_1013
{
	public PWSTR usri1013_parms;
}

[CRepr]
public struct USER_INFO_1014
{
	public PWSTR usri1014_workstations;
}

[CRepr]
public struct USER_INFO_1017
{
	public uint32 usri1017_acct_expires;
}

[CRepr]
public struct USER_INFO_1018
{
	public uint32 usri1018_max_storage;
}

[CRepr]
public struct USER_INFO_1020
{
	public uint32 usri1020_units_per_week;
	public uint8* usri1020_logon_hours;
}

[CRepr]
public struct USER_INFO_1023
{
	public PWSTR usri1023_logon_server;
}

[CRepr]
public struct USER_INFO_1024
{
	public uint32 usri1024_country_code;
}

[CRepr]
public struct USER_INFO_1025
{
	public uint32 usri1025_code_page;
}

[CRepr]
public struct USER_INFO_1051
{
	public uint32 usri1051_primary_group_id;
}

[CRepr]
public struct USER_INFO_1052
{
	public PWSTR usri1052_profile;
}

[CRepr]
public struct USER_INFO_1053
{
	public PWSTR usri1053_home_dir_drive;
}

[CRepr]
public struct USER_MODALS_INFO_0
{
	public uint32 usrmod0_min_passwd_len;
	public uint32 usrmod0_max_passwd_age;
	public uint32 usrmod0_min_passwd_age;
	public uint32 usrmod0_force_logoff;
	public uint32 usrmod0_password_hist_len;
}

[CRepr]
public struct USER_MODALS_INFO_1
{
	public uint32 usrmod1_role;
	public PWSTR usrmod1_primary;
}

[CRepr]
public struct USER_MODALS_INFO_2
{
	public PWSTR usrmod2_domain_name;
	public PSID usrmod2_domain_id;
}

[CRepr]
public struct USER_MODALS_INFO_3
{
	public uint32 usrmod3_lockout_duration;
	public uint32 usrmod3_lockout_observation_window;
	public uint32 usrmod3_lockout_threshold;
}

[CRepr]
public struct USER_MODALS_INFO_1001
{
	public uint32 usrmod1001_min_passwd_len;
}

[CRepr]
public struct USER_MODALS_INFO_1002
{
	public uint32 usrmod1002_max_passwd_age;
}

[CRepr]
public struct USER_MODALS_INFO_1003
{
	public uint32 usrmod1003_min_passwd_age;
}

[CRepr]
public struct USER_MODALS_INFO_1004
{
	public uint32 usrmod1004_force_logoff;
}

[CRepr]
public struct USER_MODALS_INFO_1005
{
	public uint32 usrmod1005_password_hist_len;
}

[CRepr]
public struct USER_MODALS_INFO_1006
{
	public USER_MODALS_ROLES usrmod1006_role;
}

[CRepr]
public struct USER_MODALS_INFO_1007
{
	public PWSTR usrmod1007_primary;
}

[CRepr]
public struct GROUP_INFO_0
{
	public PWSTR grpi0_name;
}

[CRepr]
public struct GROUP_INFO_1
{
	public PWSTR grpi1_name;
	public PWSTR grpi1_comment;
}

[CRepr]
public struct GROUP_INFO_2
{
	public PWSTR grpi2_name;
	public PWSTR grpi2_comment;
	public uint32 grpi2_group_id;
	public uint32 grpi2_attributes;
}

[CRepr]
public struct GROUP_INFO_3
{
	public PWSTR grpi3_name;
	public PWSTR grpi3_comment;
	public PSID grpi3_group_sid;
	public uint32 grpi3_attributes;
}

[CRepr]
public struct GROUP_INFO_1002
{
	public PWSTR grpi1002_comment;
}

[CRepr]
public struct GROUP_INFO_1005
{
	public uint32 grpi1005_attributes;
}

[CRepr]
public struct GROUP_USERS_INFO_0
{
	public PWSTR grui0_name;
}

[CRepr]
public struct GROUP_USERS_INFO_1
{
	public PWSTR grui1_name;
	public uint32 grui1_attributes;
}

[CRepr]
public struct LOCALGROUP_INFO_0
{
	public PWSTR lgrpi0_name;
}

[CRepr]
public struct LOCALGROUP_INFO_1
{
	public PWSTR lgrpi1_name;
	public PWSTR lgrpi1_comment;
}

[CRepr]
public struct LOCALGROUP_INFO_1002
{
	public PWSTR lgrpi1002_comment;
}

[CRepr]
public struct LOCALGROUP_MEMBERS_INFO_0
{
	public PSID lgrmi0_sid;
}

[CRepr]
public struct LOCALGROUP_MEMBERS_INFO_1
{
	public PSID lgrmi1_sid;
	public SID_NAME_USE lgrmi1_sidusage;
	public PWSTR lgrmi1_name;
}

[CRepr]
public struct LOCALGROUP_MEMBERS_INFO_2
{
	public PSID lgrmi2_sid;
	public SID_NAME_USE lgrmi2_sidusage;
	public PWSTR lgrmi2_domainandname;
}

[CRepr]
public struct LOCALGROUP_MEMBERS_INFO_3
{
	public PWSTR lgrmi3_domainandname;
}

[CRepr]
public struct LOCALGROUP_USERS_INFO_0
{
	public PWSTR lgrui0_name;
}

[CRepr]
public struct NET_DISPLAY_USER
{
	public PWSTR usri1_name;
	public PWSTR usri1_comment;
	public USER_ACCOUNT_FLAGS usri1_flags;
	public PWSTR usri1_full_name;
	public uint32 usri1_user_id;
	public uint32 usri1_next_index;
}

[CRepr]
public struct NET_DISPLAY_MACHINE
{
	public PWSTR usri2_name;
	public PWSTR usri2_comment;
	public USER_ACCOUNT_FLAGS usri2_flags;
	public uint32 usri2_user_id;
	public uint32 usri2_next_index;
}

[CRepr]
public struct NET_DISPLAY_GROUP
{
	public PWSTR grpi3_name;
	public PWSTR grpi3_comment;
	public uint32 grpi3_group_id;
	public uint32 grpi3_attributes;
	public uint32 grpi3_next_index;
}

[CRepr]
public struct ACCESS_INFO_0
{
	public PWSTR acc0_resource_name;
}

[CRepr]
public struct ACCESS_INFO_1
{
	public PWSTR acc1_resource_name;
	public uint32 acc1_attr;
	public uint32 acc1_count;
}

[CRepr]
public struct ACCESS_INFO_1002
{
	public uint32 acc1002_attr;
}

[CRepr]
public struct ACCESS_LIST
{
	public PWSTR acl_ugname;
	public uint32 acl_access;
}

[CRepr]
public struct NET_VALIDATE_PASSWORD_HASH
{
	public uint32 Length;
	public uint8* Hash;
}

[CRepr]
public struct NET_VALIDATE_PERSISTED_FIELDS
{
	public uint32 PresentFields;
	public FILETIME PasswordLastSet;
	public FILETIME BadPasswordTime;
	public FILETIME LockoutTime;
	public uint32 BadPasswordCount;
	public uint32 PasswordHistoryLength;
	public NET_VALIDATE_PASSWORD_HASH* PasswordHistory;
}

[CRepr]
public struct NET_VALIDATE_OUTPUT_ARG
{
	public NET_VALIDATE_PERSISTED_FIELDS ChangedPersistedFields;
	public uint32 ValidationStatus;
}

[CRepr]
public struct NET_VALIDATE_AUTHENTICATION_INPUT_ARG
{
	public NET_VALIDATE_PERSISTED_FIELDS InputPersistedFields;
	public BOOLEAN PasswordMatched;
}

[CRepr]
public struct NET_VALIDATE_PASSWORD_CHANGE_INPUT_ARG
{
	public NET_VALIDATE_PERSISTED_FIELDS InputPersistedFields;
	public PWSTR ClearPassword;
	public PWSTR UserAccountName;
	public NET_VALIDATE_PASSWORD_HASH HashedPassword;
	public BOOLEAN PasswordMatch;
}

[CRepr]
public struct NET_VALIDATE_PASSWORD_RESET_INPUT_ARG
{
	public NET_VALIDATE_PERSISTED_FIELDS InputPersistedFields;
	public PWSTR ClearPassword;
	public PWSTR UserAccountName;
	public NET_VALIDATE_PASSWORD_HASH HashedPassword;
	public BOOLEAN PasswordMustChangeAtNextLogon;
	public BOOLEAN ClearLockout;
}

[CRepr]
public struct NETLOGON_INFO_1
{
	public uint32 netlog1_flags;
	public uint32 netlog1_pdc_connection_status;
}

[CRepr]
public struct NETLOGON_INFO_2
{
	public uint32 netlog2_flags;
	public uint32 netlog2_pdc_connection_status;
	public PWSTR netlog2_trusted_dc_name;
	public uint32 netlog2_tc_connection_status;
}

[CRepr]
public struct NETLOGON_INFO_3
{
	public uint32 netlog3_flags;
	public uint32 netlog3_logon_attempts;
	public uint32 netlog3_reserved1;
	public uint32 netlog3_reserved2;
	public uint32 netlog3_reserved3;
	public uint32 netlog3_reserved4;
	public uint32 netlog3_reserved5;
}

[CRepr]
public struct NETLOGON_INFO_4
{
	public PWSTR netlog4_trusted_dc_name;
	public PWSTR netlog4_trusted_domain_name;
}

[CRepr]
public struct MSA_INFO_0
{
	public MSA_INFO_STATE State;
}

[CRepr]
public struct STD_ALERT
{
	public uint32 alrt_timestamp;
	public char16[17] alrt_eventname;
	public char16[81] alrt_servicename;
}

[CRepr]
public struct ADMIN_OTHER_INFO
{
	public uint32 alrtad_errcode;
	public uint32 alrtad_numstrings;
}

[CRepr]
public struct ERRLOG_OTHER_INFO
{
	public uint32 alrter_errcode;
	public uint32 alrter_offset;
}

[CRepr]
public struct PRINT_OTHER_INFO
{
	public uint32 alrtpr_jobid;
	public uint32 alrtpr_status;
	public uint32 alrtpr_submitted;
	public uint32 alrtpr_size;
}

[CRepr]
public struct USER_OTHER_INFO
{
	public uint32 alrtus_errcode;
	public uint32 alrtus_numstrings;
}

[CRepr]
public struct MSG_INFO_0
{
	public PWSTR msgi0_name;
}

[CRepr]
public struct MSG_INFO_1
{
	public PWSTR msgi1_name;
	public uint32 msgi1_forward_flag;
	public PWSTR msgi1_forward;
}

[CRepr]
public struct TIME_OF_DAY_INFO
{
	public uint32 tod_elapsedt;
	public uint32 tod_msecs;
	public uint32 tod_hours;
	public uint32 tod_mins;
	public uint32 tod_secs;
	public uint32 tod_hunds;
	public int32 tod_timezone;
	public uint32 tod_tinterval;
	public uint32 tod_day;
	public uint32 tod_month;
	public uint32 tod_year;
	public uint32 tod_weekday;
}

[CRepr]
public struct REPL_INFO_0
{
	public uint32 rp0_role;
	public PWSTR rp0_exportpath;
	public PWSTR rp0_exportlist;
	public PWSTR rp0_importpath;
	public PWSTR rp0_importlist;
	public PWSTR rp0_logonusername;
	public uint32 rp0_interval;
	public uint32 rp0_pulse;
	public uint32 rp0_guardtime;
	public uint32 rp0_random;
}

[CRepr]
public struct REPL_INFO_1000
{
	public uint32 rp1000_interval;
}

[CRepr]
public struct REPL_INFO_1001
{
	public uint32 rp1001_pulse;
}

[CRepr]
public struct REPL_INFO_1002
{
	public uint32 rp1002_guardtime;
}

[CRepr]
public struct REPL_INFO_1003
{
	public uint32 rp1003_random;
}

[CRepr]
public struct REPL_EDIR_INFO_0
{
	public PWSTR rped0_dirname;
}

[CRepr]
public struct REPL_EDIR_INFO_1
{
	public PWSTR rped1_dirname;
	public uint32 rped1_integrity;
	public uint32 rped1_extent;
}

[CRepr]
public struct REPL_EDIR_INFO_2
{
	public PWSTR rped2_dirname;
	public uint32 rped2_integrity;
	public uint32 rped2_extent;
	public uint32 rped2_lockcount;
	public uint32 rped2_locktime;
}

[CRepr]
public struct REPL_EDIR_INFO_1000
{
	public uint32 rped1000_integrity;
}

[CRepr]
public struct REPL_EDIR_INFO_1001
{
	public uint32 rped1001_extent;
}

[CRepr]
public struct REPL_IDIR_INFO_0
{
	public PWSTR rpid0_dirname;
}

[CRepr]
public struct REPL_IDIR_INFO_1
{
	public PWSTR rpid1_dirname;
	public uint32 rpid1_state;
	public PWSTR rpid1_mastername;
	public uint32 rpid1_last_update_time;
	public uint32 rpid1_lockcount;
	public uint32 rpid1_locktime;
}

[CRepr]
public struct SERVER_INFO_100
{
	public uint32 sv100_platform_id;
	public PWSTR sv100_name;
}

[CRepr]
public struct SERVER_INFO_101
{
	public uint32 sv101_platform_id;
	public PWSTR sv101_name;
	public uint32 sv101_version_major;
	public uint32 sv101_version_minor;
	public NET_SERVER_TYPE sv101_type;
	public PWSTR sv101_comment;
}

[CRepr]
public struct SERVER_INFO_102
{
	public uint32 sv102_platform_id;
	public PWSTR sv102_name;
	public uint32 sv102_version_major;
	public uint32 sv102_version_minor;
	public NET_SERVER_TYPE sv102_type;
	public PWSTR sv102_comment;
	public uint32 sv102_users;
	public int32 sv102_disc;
	public SERVER_INFO_HIDDEN sv102_hidden;
	public uint32 sv102_announce;
	public uint32 sv102_anndelta;
	public uint32 sv102_licenses;
	public PWSTR sv102_userpath;
}

[CRepr]
public struct SERVER_INFO_103
{
	public uint32 sv103_platform_id;
	public PWSTR sv103_name;
	public uint32 sv103_version_major;
	public uint32 sv103_version_minor;
	public uint32 sv103_type;
	public PWSTR sv103_comment;
	public uint32 sv103_users;
	public int32 sv103_disc;
	public BOOL sv103_hidden;
	public uint32 sv103_announce;
	public uint32 sv103_anndelta;
	public uint32 sv103_licenses;
	public PWSTR sv103_userpath;
	public uint32 sv103_capabilities;
}

[CRepr]
public struct SERVER_INFO_402
{
	public uint32 sv402_ulist_mtime;
	public uint32 sv402_glist_mtime;
	public uint32 sv402_alist_mtime;
	public PWSTR sv402_alerts;
	public SERVER_INFO_SECURITY sv402_security;
	public uint32 sv402_numadmin;
	public uint32 sv402_lanmask;
	public PWSTR sv402_guestacct;
	public uint32 sv402_chdevs;
	public uint32 sv402_chdevq;
	public uint32 sv402_chdevjobs;
	public uint32 sv402_connections;
	public uint32 sv402_shares;
	public uint32 sv402_openfiles;
	public uint32 sv402_sessopens;
	public uint32 sv402_sessvcs;
	public uint32 sv402_sessreqs;
	public uint32 sv402_opensearch;
	public uint32 sv402_activelocks;
	public uint32 sv402_numreqbuf;
	public uint32 sv402_sizreqbuf;
	public uint32 sv402_numbigbuf;
	public uint32 sv402_numfiletasks;
	public uint32 sv402_alertsched;
	public uint32 sv402_erroralert;
	public uint32 sv402_logonalert;
	public uint32 sv402_accessalert;
	public uint32 sv402_diskalert;
	public uint32 sv402_netioalert;
	public uint32 sv402_maxauditsz;
	public PWSTR sv402_srvheuristics;
}

[CRepr]
public struct SERVER_INFO_403
{
	public uint32 sv403_ulist_mtime;
	public uint32 sv403_glist_mtime;
	public uint32 sv403_alist_mtime;
	public PWSTR sv403_alerts;
	public SERVER_INFO_SECURITY sv403_security;
	public uint32 sv403_numadmin;
	public uint32 sv403_lanmask;
	public PWSTR sv403_guestacct;
	public uint32 sv403_chdevs;
	public uint32 sv403_chdevq;
	public uint32 sv403_chdevjobs;
	public uint32 sv403_connections;
	public uint32 sv403_shares;
	public uint32 sv403_openfiles;
	public uint32 sv403_sessopens;
	public uint32 sv403_sessvcs;
	public uint32 sv403_sessreqs;
	public uint32 sv403_opensearch;
	public uint32 sv403_activelocks;
	public uint32 sv403_numreqbuf;
	public uint32 sv403_sizreqbuf;
	public uint32 sv403_numbigbuf;
	public uint32 sv403_numfiletasks;
	public uint32 sv403_alertsched;
	public uint32 sv403_erroralert;
	public uint32 sv403_logonalert;
	public uint32 sv403_accessalert;
	public uint32 sv403_diskalert;
	public uint32 sv403_netioalert;
	public uint32 sv403_maxauditsz;
	public PWSTR sv403_srvheuristics;
	public uint32 sv403_auditedevents;
	public uint32 sv403_autoprofile;
	public PWSTR sv403_autopath;
}

[CRepr]
public struct SERVER_INFO_502
{
	public uint32 sv502_sessopens;
	public uint32 sv502_sessvcs;
	public uint32 sv502_opensearch;
	public uint32 sv502_sizreqbuf;
	public uint32 sv502_initworkitems;
	public uint32 sv502_maxworkitems;
	public uint32 sv502_rawworkitems;
	public uint32 sv502_irpstacksize;
	public uint32 sv502_maxrawbuflen;
	public uint32 sv502_sessusers;
	public uint32 sv502_sessconns;
	public uint32 sv502_maxpagedmemoryusage;
	public uint32 sv502_maxnonpagedmemoryusage;
	public BOOL sv502_enablesoftcompat;
	public BOOL sv502_enableforcedlogoff;
	public BOOL sv502_timesource;
	public BOOL sv502_acceptdownlevelapis;
	public BOOL sv502_lmannounce;
}

[CRepr]
public struct SERVER_INFO_503
{
	public uint32 sv503_sessopens;
	public uint32 sv503_sessvcs;
	public uint32 sv503_opensearch;
	public uint32 sv503_sizreqbuf;
	public uint32 sv503_initworkitems;
	public uint32 sv503_maxworkitems;
	public uint32 sv503_rawworkitems;
	public uint32 sv503_irpstacksize;
	public uint32 sv503_maxrawbuflen;
	public uint32 sv503_sessusers;
	public uint32 sv503_sessconns;
	public uint32 sv503_maxpagedmemoryusage;
	public uint32 sv503_maxnonpagedmemoryusage;
	public BOOL sv503_enablesoftcompat;
	public BOOL sv503_enableforcedlogoff;
	public BOOL sv503_timesource;
	public BOOL sv503_acceptdownlevelapis;
	public BOOL sv503_lmannounce;
	public PWSTR sv503_domain;
	public uint32 sv503_maxcopyreadlen;
	public uint32 sv503_maxcopywritelen;
	public uint32 sv503_minkeepsearch;
	public uint32 sv503_maxkeepsearch;
	public uint32 sv503_minkeepcomplsearch;
	public uint32 sv503_maxkeepcomplsearch;
	public uint32 sv503_threadcountadd;
	public uint32 sv503_numblockthreads;
	public uint32 sv503_scavtimeout;
	public uint32 sv503_minrcvqueue;
	public uint32 sv503_minfreeworkitems;
	public uint32 sv503_xactmemsize;
	public uint32 sv503_threadpriority;
	public uint32 sv503_maxmpxct;
	public uint32 sv503_oplockbreakwait;
	public uint32 sv503_oplockbreakresponsewait;
	public BOOL sv503_enableoplocks;
	public BOOL sv503_enableoplockforceclose;
	public BOOL sv503_enablefcbopens;
	public BOOL sv503_enableraw;
	public BOOL sv503_enablesharednetdrives;
	public uint32 sv503_minfreeconnections;
	public uint32 sv503_maxfreeconnections;
}

[CRepr]
public struct SERVER_INFO_599
{
	public uint32 sv599_sessopens;
	public uint32 sv599_sessvcs;
	public uint32 sv599_opensearch;
	public uint32 sv599_sizreqbuf;
	public uint32 sv599_initworkitems;
	public uint32 sv599_maxworkitems;
	public uint32 sv599_rawworkitems;
	public uint32 sv599_irpstacksize;
	public uint32 sv599_maxrawbuflen;
	public uint32 sv599_sessusers;
	public uint32 sv599_sessconns;
	public uint32 sv599_maxpagedmemoryusage;
	public uint32 sv599_maxnonpagedmemoryusage;
	public BOOL sv599_enablesoftcompat;
	public BOOL sv599_enableforcedlogoff;
	public BOOL sv599_timesource;
	public BOOL sv599_acceptdownlevelapis;
	public BOOL sv599_lmannounce;
	public PWSTR sv599_domain;
	public uint32 sv599_maxcopyreadlen;
	public uint32 sv599_maxcopywritelen;
	public uint32 sv599_minkeepsearch;
	public uint32 sv599_maxkeepsearch;
	public uint32 sv599_minkeepcomplsearch;
	public uint32 sv599_maxkeepcomplsearch;
	public uint32 sv599_threadcountadd;
	public uint32 sv599_numblockthreads;
	public uint32 sv599_scavtimeout;
	public uint32 sv599_minrcvqueue;
	public uint32 sv599_minfreeworkitems;
	public uint32 sv599_xactmemsize;
	public uint32 sv599_threadpriority;
	public uint32 sv599_maxmpxct;
	public uint32 sv599_oplockbreakwait;
	public uint32 sv599_oplockbreakresponsewait;
	public BOOL sv599_enableoplocks;
	public BOOL sv599_enableoplockforceclose;
	public BOOL sv599_enablefcbopens;
	public BOOL sv599_enableraw;
	public BOOL sv599_enablesharednetdrives;
	public uint32 sv599_minfreeconnections;
	public uint32 sv599_maxfreeconnections;
	public uint32 sv599_initsesstable;
	public uint32 sv599_initconntable;
	public uint32 sv599_initfiletable;
	public uint32 sv599_initsearchtable;
	public uint32 sv599_alertschedule;
	public uint32 sv599_errorthreshold;
	public uint32 sv599_networkerrorthreshold;
	public uint32 sv599_diskspacethreshold;
	public uint32 sv599_reserved;
	public uint32 sv599_maxlinkdelay;
	public uint32 sv599_minlinkthroughput;
	public uint32 sv599_linkinfovalidtime;
	public uint32 sv599_scavqosinfoupdatetime;
	public uint32 sv599_maxworkitemidletime;
}

[CRepr]
public struct SERVER_INFO_598
{
	public uint32 sv598_maxrawworkitems;
	public uint32 sv598_maxthreadsperqueue;
	public uint32 sv598_producttype;
	public uint32 sv598_serversize;
	public uint32 sv598_connectionlessautodisc;
	public uint32 sv598_sharingviolationretries;
	public uint32 sv598_sharingviolationdelay;
	public uint32 sv598_maxglobalopensearch;
	public uint32 sv598_removeduplicatesearches;
	public uint32 sv598_lockviolationoffset;
	public uint32 sv598_lockviolationdelay;
	public uint32 sv598_mdlreadswitchover;
	public uint32 sv598_cachedopenlimit;
	public uint32 sv598_otherqueueaffinity;
	public BOOL sv598_restrictnullsessaccess;
	public BOOL sv598_enablewfw311directipx;
	public uint32 sv598_queuesamplesecs;
	public uint32 sv598_balancecount;
	public uint32 sv598_preferredaffinity;
	public uint32 sv598_maxfreerfcbs;
	public uint32 sv598_maxfreemfcbs;
	public uint32 sv598_maxfreelfcbs;
	public uint32 sv598_maxfreepagedpoolchunks;
	public uint32 sv598_minpagedpoolchunksize;
	public uint32 sv598_maxpagedpoolchunksize;
	public BOOL sv598_sendsfrompreferredprocessor;
	public uint32 sv598_cacheddirectorylimit;
	public uint32 sv598_maxcopylength;
	public BOOL sv598_enablecompression;
	public BOOL sv598_autosharewks;
	public BOOL sv598_autoshareserver;
	public BOOL sv598_enablesecuritysignature;
	public BOOL sv598_requiresecuritysignature;
	public uint32 sv598_minclientbuffersize;
	public Guid sv598_serverguid;
	public uint32 sv598_ConnectionNoSessionsTimeout;
	public uint32 sv598_IdleThreadTimeOut;
	public BOOL sv598_enableW9xsecuritysignature;
	public BOOL sv598_enforcekerberosreauthentication;
	public BOOL sv598_disabledos;
	public uint32 sv598_lowdiskspaceminimum;
	public BOOL sv598_disablestrictnamechecking;
	public BOOL sv598_enableauthenticateusersharing;
}

[CRepr]
public struct SERVER_INFO_1005
{
	public PWSTR sv1005_comment;
}

[CRepr]
public struct SERVER_INFO_1107
{
	public uint32 sv1107_users;
}

[CRepr]
public struct SERVER_INFO_1010
{
	public int32 sv1010_disc;
}

[CRepr]
public struct SERVER_INFO_1016
{
	public SERVER_INFO_HIDDEN sv1016_hidden;
}

[CRepr]
public struct SERVER_INFO_1017
{
	public uint32 sv1017_announce;
}

[CRepr]
public struct SERVER_INFO_1018
{
	public uint32 sv1018_anndelta;
}

[CRepr]
public struct SERVER_INFO_1501
{
	public uint32 sv1501_sessopens;
}

[CRepr]
public struct SERVER_INFO_1502
{
	public uint32 sv1502_sessvcs;
}

[CRepr]
public struct SERVER_INFO_1503
{
	public uint32 sv1503_opensearch;
}

[CRepr]
public struct SERVER_INFO_1506
{
	public uint32 sv1506_maxworkitems;
}

[CRepr]
public struct SERVER_INFO_1509
{
	public uint32 sv1509_maxrawbuflen;
}

[CRepr]
public struct SERVER_INFO_1510
{
	public uint32 sv1510_sessusers;
}

[CRepr]
public struct SERVER_INFO_1511
{
	public uint32 sv1511_sessconns;
}

[CRepr]
public struct SERVER_INFO_1512
{
	public uint32 sv1512_maxnonpagedmemoryusage;
}

[CRepr]
public struct SERVER_INFO_1513
{
	public uint32 sv1513_maxpagedmemoryusage;
}

[CRepr]
public struct SERVER_INFO_1514
{
	public BOOL sv1514_enablesoftcompat;
}

[CRepr]
public struct SERVER_INFO_1515
{
	public BOOL sv1515_enableforcedlogoff;
}

[CRepr]
public struct SERVER_INFO_1516
{
	public BOOL sv1516_timesource;
}

[CRepr]
public struct SERVER_INFO_1518
{
	public BOOL sv1518_lmannounce;
}

[CRepr]
public struct SERVER_INFO_1520
{
	public uint32 sv1520_maxcopyreadlen;
}

[CRepr]
public struct SERVER_INFO_1521
{
	public uint32 sv1521_maxcopywritelen;
}

[CRepr]
public struct SERVER_INFO_1522
{
	public uint32 sv1522_minkeepsearch;
}

[CRepr]
public struct SERVER_INFO_1523
{
	public uint32 sv1523_maxkeepsearch;
}

[CRepr]
public struct SERVER_INFO_1524
{
	public uint32 sv1524_minkeepcomplsearch;
}

[CRepr]
public struct SERVER_INFO_1525
{
	public uint32 sv1525_maxkeepcomplsearch;
}

[CRepr]
public struct SERVER_INFO_1528
{
	public uint32 sv1528_scavtimeout;
}

[CRepr]
public struct SERVER_INFO_1529
{
	public uint32 sv1529_minrcvqueue;
}

[CRepr]
public struct SERVER_INFO_1530
{
	public uint32 sv1530_minfreeworkitems;
}

[CRepr]
public struct SERVER_INFO_1533
{
	public uint32 sv1533_maxmpxct;
}

[CRepr]
public struct SERVER_INFO_1534
{
	public uint32 sv1534_oplockbreakwait;
}

[CRepr]
public struct SERVER_INFO_1535
{
	public uint32 sv1535_oplockbreakresponsewait;
}

[CRepr]
public struct SERVER_INFO_1536
{
	public BOOL sv1536_enableoplocks;
}

[CRepr]
public struct SERVER_INFO_1537
{
	public BOOL sv1537_enableoplockforceclose;
}

[CRepr]
public struct SERVER_INFO_1538
{
	public BOOL sv1538_enablefcbopens;
}

[CRepr]
public struct SERVER_INFO_1539
{
	public BOOL sv1539_enableraw;
}

[CRepr]
public struct SERVER_INFO_1540
{
	public BOOL sv1540_enablesharednetdrives;
}

[CRepr]
public struct SERVER_INFO_1541
{
	public BOOL sv1541_minfreeconnections;
}

[CRepr]
public struct SERVER_INFO_1542
{
	public BOOL sv1542_maxfreeconnections;
}

[CRepr]
public struct SERVER_INFO_1543
{
	public uint32 sv1543_initsesstable;
}

[CRepr]
public struct SERVER_INFO_1544
{
	public uint32 sv1544_initconntable;
}

[CRepr]
public struct SERVER_INFO_1545
{
	public uint32 sv1545_initfiletable;
}

[CRepr]
public struct SERVER_INFO_1546
{
	public uint32 sv1546_initsearchtable;
}

[CRepr]
public struct SERVER_INFO_1547
{
	public uint32 sv1547_alertschedule;
}

[CRepr]
public struct SERVER_INFO_1548
{
	public uint32 sv1548_errorthreshold;
}

[CRepr]
public struct SERVER_INFO_1549
{
	public uint32 sv1549_networkerrorthreshold;
}

[CRepr]
public struct SERVER_INFO_1550
{
	public uint32 sv1550_diskspacethreshold;
}

[CRepr]
public struct SERVER_INFO_1552
{
	public uint32 sv1552_maxlinkdelay;
}

[CRepr]
public struct SERVER_INFO_1553
{
	public uint32 sv1553_minlinkthroughput;
}

[CRepr]
public struct SERVER_INFO_1554
{
	public uint32 sv1554_linkinfovalidtime;
}

[CRepr]
public struct SERVER_INFO_1555
{
	public uint32 sv1555_scavqosinfoupdatetime;
}

[CRepr]
public struct SERVER_INFO_1556
{
	public uint32 sv1556_maxworkitemidletime;
}

[CRepr]
public struct SERVER_INFO_1557
{
	public uint32 sv1557_maxrawworkitems;
}

[CRepr]
public struct SERVER_INFO_1560
{
	public uint32 sv1560_producttype;
}

[CRepr]
public struct SERVER_INFO_1561
{
	public uint32 sv1561_serversize;
}

[CRepr]
public struct SERVER_INFO_1562
{
	public uint32 sv1562_connectionlessautodisc;
}

[CRepr]
public struct SERVER_INFO_1563
{
	public uint32 sv1563_sharingviolationretries;
}

[CRepr]
public struct SERVER_INFO_1564
{
	public uint32 sv1564_sharingviolationdelay;
}

[CRepr]
public struct SERVER_INFO_1565
{
	public uint32 sv1565_maxglobalopensearch;
}

[CRepr]
public struct SERVER_INFO_1566
{
	public BOOL sv1566_removeduplicatesearches;
}

[CRepr]
public struct SERVER_INFO_1567
{
	public uint32 sv1567_lockviolationretries;
}

[CRepr]
public struct SERVER_INFO_1568
{
	public uint32 sv1568_lockviolationoffset;
}

[CRepr]
public struct SERVER_INFO_1569
{
	public uint32 sv1569_lockviolationdelay;
}

[CRepr]
public struct SERVER_INFO_1570
{
	public uint32 sv1570_mdlreadswitchover;
}

[CRepr]
public struct SERVER_INFO_1571
{
	public uint32 sv1571_cachedopenlimit;
}

[CRepr]
public struct SERVER_INFO_1572
{
	public uint32 sv1572_criticalthreads;
}

[CRepr]
public struct SERVER_INFO_1573
{
	public uint32 sv1573_restrictnullsessaccess;
}

[CRepr]
public struct SERVER_INFO_1574
{
	public uint32 sv1574_enablewfw311directipx;
}

[CRepr]
public struct SERVER_INFO_1575
{
	public uint32 sv1575_otherqueueaffinity;
}

[CRepr]
public struct SERVER_INFO_1576
{
	public uint32 sv1576_queuesamplesecs;
}

[CRepr]
public struct SERVER_INFO_1577
{
	public uint32 sv1577_balancecount;
}

[CRepr]
public struct SERVER_INFO_1578
{
	public uint32 sv1578_preferredaffinity;
}

[CRepr]
public struct SERVER_INFO_1579
{
	public uint32 sv1579_maxfreerfcbs;
}

[CRepr]
public struct SERVER_INFO_1580
{
	public uint32 sv1580_maxfreemfcbs;
}

[CRepr]
public struct SERVER_INFO_1581
{
	public uint32 sv1581_maxfreemlcbs;
}

[CRepr]
public struct SERVER_INFO_1582
{
	public uint32 sv1582_maxfreepagedpoolchunks;
}

[CRepr]
public struct SERVER_INFO_1583
{
	public uint32 sv1583_minpagedpoolchunksize;
}

[CRepr]
public struct SERVER_INFO_1584
{
	public uint32 sv1584_maxpagedpoolchunksize;
}

[CRepr]
public struct SERVER_INFO_1585
{
	public BOOL sv1585_sendsfrompreferredprocessor;
}

[CRepr]
public struct SERVER_INFO_1586
{
	public uint32 sv1586_maxthreadsperqueue;
}

[CRepr]
public struct SERVER_INFO_1587
{
	public uint32 sv1587_cacheddirectorylimit;
}

[CRepr]
public struct SERVER_INFO_1588
{
	public uint32 sv1588_maxcopylength;
}

[CRepr]
public struct SERVER_INFO_1590
{
	public uint32 sv1590_enablecompression;
}

[CRepr]
public struct SERVER_INFO_1591
{
	public uint32 sv1591_autosharewks;
}

[CRepr]
public struct SERVER_INFO_1592
{
	public uint32 sv1592_autosharewks;
}

[CRepr]
public struct SERVER_INFO_1593
{
	public uint32 sv1593_enablesecuritysignature;
}

[CRepr]
public struct SERVER_INFO_1594
{
	public uint32 sv1594_requiresecuritysignature;
}

[CRepr]
public struct SERVER_INFO_1595
{
	public uint32 sv1595_minclientbuffersize;
}

[CRepr]
public struct SERVER_INFO_1596
{
	public uint32 sv1596_ConnectionNoSessionsTimeout;
}

[CRepr]
public struct SERVER_INFO_1597
{
	public uint32 sv1597_IdleThreadTimeOut;
}

[CRepr]
public struct SERVER_INFO_1598
{
	public uint32 sv1598_enableW9xsecuritysignature;
}

[CRepr]
public struct SERVER_INFO_1599
{
	public BOOLEAN sv1598_enforcekerberosreauthentication;
}

[CRepr]
public struct SERVER_INFO_1600
{
	public BOOLEAN sv1598_disabledos;
}

[CRepr]
public struct SERVER_INFO_1601
{
	public uint32 sv1598_lowdiskspaceminimum;
}

[CRepr]
public struct SERVER_INFO_1602
{
	public BOOL sv_1598_disablestrictnamechecking;
}

[CRepr]
public struct SERVER_TRANSPORT_INFO_0
{
	public uint32 svti0_numberofvcs;
	public PWSTR svti0_transportname;
	public uint8* svti0_transportaddress;
	public uint32 svti0_transportaddresslength;
	public PWSTR svti0_networkaddress;
}

[CRepr]
public struct SERVER_TRANSPORT_INFO_1
{
	public uint32 svti1_numberofvcs;
	public PWSTR svti1_transportname;
	public uint8* svti1_transportaddress;
	public uint32 svti1_transportaddresslength;
	public PWSTR svti1_networkaddress;
	public PWSTR svti1_domain;
}

[CRepr]
public struct SERVER_TRANSPORT_INFO_2
{
	public uint32 svti2_numberofvcs;
	public PWSTR svti2_transportname;
	public uint8* svti2_transportaddress;
	public uint32 svti2_transportaddresslength;
	public PWSTR svti2_networkaddress;
	public PWSTR svti2_domain;
	public uint32 svti2_flags;
}

[CRepr]
public struct SERVER_TRANSPORT_INFO_3
{
	public uint32 svti3_numberofvcs;
	public PWSTR svti3_transportname;
	public uint8* svti3_transportaddress;
	public uint32 svti3_transportaddresslength;
	public PWSTR svti3_networkaddress;
	public PWSTR svti3_domain;
	public uint32 svti3_flags;
	public uint32 svti3_passwordlength;
	public uint8[256] svti3_password;
}

[CRepr]
public struct SERVICE_INFO_0
{
	public PWSTR svci0_name;
}

[CRepr]
public struct SERVICE_INFO_1
{
	public PWSTR svci1_name;
	public uint32 svci1_status;
	public uint32 svci1_code;
	public uint32 svci1_pid;
}

[CRepr]
public struct SERVICE_INFO_2
{
	public PWSTR svci2_name;
	public uint32 svci2_status;
	public uint32 svci2_code;
	public uint32 svci2_pid;
	public PWSTR svci2_text;
	public uint32 svci2_specific_error;
	public PWSTR svci2_display_name;
}

[CRepr]
public struct USE_INFO_0
{
	public PWSTR ui0_local;
	public PWSTR ui0_remote;
}

[CRepr]
public struct USE_INFO_1
{
	public PWSTR ui1_local;
	public PWSTR ui1_remote;
	public PWSTR ui1_password;
	public uint32 ui1_status;
	public USE_INFO_ASG_TYPE ui1_asg_type;
	public uint32 ui1_refcount;
	public uint32 ui1_usecount;
}

[CRepr]
public struct USE_INFO_2
{
	public PWSTR ui2_local;
	public PWSTR ui2_remote;
	public PWSTR ui2_password;
	public uint32 ui2_status;
	public USE_INFO_ASG_TYPE ui2_asg_type;
	public uint32 ui2_refcount;
	public uint32 ui2_usecount;
	public PWSTR ui2_username;
	public PWSTR ui2_domainname;
}

[CRepr]
public struct USE_INFO_3
{
	public USE_INFO_2 ui3_ui2;
	public uint32 ui3_flags;
}

[CRepr]
public struct USE_INFO_4
{
	public USE_INFO_3 ui4_ui3;
	public uint32 ui4_auth_identity_length;
	public uint8* ui4_auth_identity;
}

[CRepr]
public struct USE_INFO_5
{
	public USE_INFO_3 ui4_ui3;
	public uint32 ui4_auth_identity_length;
	public uint8* ui4_auth_identity;
	public uint32 ui5_security_descriptor_length;
	public uint8* ui5_security_descriptor;
	public uint32 ui5_use_options_length;
	public uint8* ui5_use_options;
}

[CRepr]
public struct USE_OPTION_GENERIC
{
	public uint32 Tag;
	public uint16 Length;
	public uint16 Reserved;
}

[CRepr]
public struct USE_OPTION_DEFERRED_CONNECTION_PARAMETERS
{
	public uint32 Tag;
	public uint16 Length;
	public uint16 Reserved;
}

[CRepr]
public struct TRANSPORT_INFO
{
	public TRANSPORT_TYPE Type;
	public BOOLEAN SkipCertificateCheck;
}

[CRepr]
public struct USE_OPTION_TRANSPORT_PARAMETERS
{
	public uint32 Tag;
	public uint16 Length;
	public uint16 Reserved;
}

[CRepr]
public struct SMB_COMPRESSION_INFO
{
	public BOOLEAN Switch;
	public uint8 Reserved1;
	public uint16 Reserved2;
	public uint32 Reserved3;
}

[CRepr]
public struct SMB_USE_OPTION_COMPRESSION_PARAMETERS
{
	public uint32 Tag;
	public uint16 Length;
	public uint16 Reserved;
}

[CRepr]
public struct SMB_TREE_CONNECT_PARAMETERS
{
	public uint32 EABufferOffset;
	public uint32 EABufferLen;
	public uint32 CreateOptions;
	public uint32 TreeConnectAttributes;
}

[CRepr]
public struct USE_OPTION_PROPERTIES
{
	public uint32 Tag;
	public void* pInfo;
	public uint Length;
}

[CRepr]
public struct WKSTA_INFO_100
{
	public uint32 wki100_platform_id;
	public PWSTR wki100_computername;
	public PWSTR wki100_langroup;
	public uint32 wki100_ver_major;
	public uint32 wki100_ver_minor;
}

[CRepr]
public struct WKSTA_INFO_101
{
	public uint32 wki101_platform_id;
	public PWSTR wki101_computername;
	public PWSTR wki101_langroup;
	public uint32 wki101_ver_major;
	public uint32 wki101_ver_minor;
	public PWSTR wki101_lanroot;
}

[CRepr]
public struct WKSTA_INFO_102
{
	public uint32 wki102_platform_id;
	public PWSTR wki102_computername;
	public PWSTR wki102_langroup;
	public uint32 wki102_ver_major;
	public uint32 wki102_ver_minor;
	public PWSTR wki102_lanroot;
	public uint32 wki102_logged_on_users;
}

[CRepr]
public struct WKSTA_INFO_302
{
	public uint32 wki302_char_wait;
	public uint32 wki302_collection_time;
	public uint32 wki302_maximum_collection_count;
	public uint32 wki302_keep_conn;
	public uint32 wki302_keep_search;
	public uint32 wki302_max_cmds;
	public uint32 wki302_num_work_buf;
	public uint32 wki302_siz_work_buf;
	public uint32 wki302_max_wrk_cache;
	public uint32 wki302_sess_timeout;
	public uint32 wki302_siz_error;
	public uint32 wki302_num_alerts;
	public uint32 wki302_num_services;
	public uint32 wki302_errlog_sz;
	public uint32 wki302_print_buf_time;
	public uint32 wki302_num_char_buf;
	public uint32 wki302_siz_char_buf;
	public PWSTR wki302_wrk_heuristics;
	public uint32 wki302_mailslots;
	public uint32 wki302_num_dgram_buf;
}

[CRepr]
public struct WKSTA_INFO_402
{
	public uint32 wki402_char_wait;
	public uint32 wki402_collection_time;
	public uint32 wki402_maximum_collection_count;
	public uint32 wki402_keep_conn;
	public uint32 wki402_keep_search;
	public uint32 wki402_max_cmds;
	public uint32 wki402_num_work_buf;
	public uint32 wki402_siz_work_buf;
	public uint32 wki402_max_wrk_cache;
	public uint32 wki402_sess_timeout;
	public uint32 wki402_siz_error;
	public uint32 wki402_num_alerts;
	public uint32 wki402_num_services;
	public uint32 wki402_errlog_sz;
	public uint32 wki402_print_buf_time;
	public uint32 wki402_num_char_buf;
	public uint32 wki402_siz_char_buf;
	public PWSTR wki402_wrk_heuristics;
	public uint32 wki402_mailslots;
	public uint32 wki402_num_dgram_buf;
	public uint32 wki402_max_threads;
}

[CRepr]
public struct WKSTA_INFO_502
{
	public uint32 wki502_char_wait;
	public uint32 wki502_collection_time;
	public uint32 wki502_maximum_collection_count;
	public uint32 wki502_keep_conn;
	public uint32 wki502_max_cmds;
	public uint32 wki502_sess_timeout;
	public uint32 wki502_siz_char_buf;
	public uint32 wki502_max_threads;
	public uint32 wki502_lock_quota;
	public uint32 wki502_lock_increment;
	public uint32 wki502_lock_maximum;
	public uint32 wki502_pipe_increment;
	public uint32 wki502_pipe_maximum;
	public uint32 wki502_cache_file_timeout;
	public uint32 wki502_dormant_file_limit;
	public uint32 wki502_read_ahead_throughput;
	public uint32 wki502_num_mailslot_buffers;
	public uint32 wki502_num_srv_announce_buffers;
	public uint32 wki502_max_illegal_datagram_events;
	public uint32 wki502_illegal_datagram_event_reset_frequency;
	public BOOL wki502_log_election_packets;
	public BOOL wki502_use_opportunistic_locking;
	public BOOL wki502_use_unlock_behind;
	public BOOL wki502_use_close_behind;
	public BOOL wki502_buf_named_pipes;
	public BOOL wki502_use_lock_read_unlock;
	public BOOL wki502_utilize_nt_caching;
	public BOOL wki502_use_raw_read;
	public BOOL wki502_use_raw_write;
	public BOOL wki502_use_write_raw_data;
	public BOOL wki502_use_encryption;
	public BOOL wki502_buf_files_deny_write;
	public BOOL wki502_buf_read_only_files;
	public BOOL wki502_force_core_create_mode;
	public BOOL wki502_use_512_byte_max_transfer;
}

[CRepr]
public struct WKSTA_INFO_1010
{
	public uint32 wki1010_char_wait;
}

[CRepr]
public struct WKSTA_INFO_1011
{
	public uint32 wki1011_collection_time;
}

[CRepr]
public struct WKSTA_INFO_1012
{
	public uint32 wki1012_maximum_collection_count;
}

[CRepr]
public struct WKSTA_INFO_1027
{
	public uint32 wki1027_errlog_sz;
}

[CRepr]
public struct WKSTA_INFO_1028
{
	public uint32 wki1028_print_buf_time;
}

[CRepr]
public struct WKSTA_INFO_1032
{
	public uint32 wki1032_wrk_heuristics;
}

[CRepr]
public struct WKSTA_INFO_1013
{
	public uint32 wki1013_keep_conn;
}

[CRepr]
public struct WKSTA_INFO_1018
{
	public uint32 wki1018_sess_timeout;
}

[CRepr]
public struct WKSTA_INFO_1023
{
	public uint32 wki1023_siz_char_buf;
}

[CRepr]
public struct WKSTA_INFO_1033
{
	public uint32 wki1033_max_threads;
}

[CRepr]
public struct WKSTA_INFO_1041
{
	public uint32 wki1041_lock_quota;
}

[CRepr]
public struct WKSTA_INFO_1042
{
	public uint32 wki1042_lock_increment;
}

[CRepr]
public struct WKSTA_INFO_1043
{
	public uint32 wki1043_lock_maximum;
}

[CRepr]
public struct WKSTA_INFO_1044
{
	public uint32 wki1044_pipe_increment;
}

[CRepr]
public struct WKSTA_INFO_1045
{
	public uint32 wki1045_pipe_maximum;
}

[CRepr]
public struct WKSTA_INFO_1046
{
	public uint32 wki1046_dormant_file_limit;
}

[CRepr]
public struct WKSTA_INFO_1047
{
	public uint32 wki1047_cache_file_timeout;
}

[CRepr]
public struct WKSTA_INFO_1048
{
	public BOOL wki1048_use_opportunistic_locking;
}

[CRepr]
public struct WKSTA_INFO_1049
{
	public BOOL wki1049_use_unlock_behind;
}

[CRepr]
public struct WKSTA_INFO_1050
{
	public BOOL wki1050_use_close_behind;
}

[CRepr]
public struct WKSTA_INFO_1051
{
	public BOOL wki1051_buf_named_pipes;
}

[CRepr]
public struct WKSTA_INFO_1052
{
	public BOOL wki1052_use_lock_read_unlock;
}

[CRepr]
public struct WKSTA_INFO_1053
{
	public BOOL wki1053_utilize_nt_caching;
}

[CRepr]
public struct WKSTA_INFO_1054
{
	public BOOL wki1054_use_raw_read;
}

[CRepr]
public struct WKSTA_INFO_1055
{
	public BOOL wki1055_use_raw_write;
}

[CRepr]
public struct WKSTA_INFO_1056
{
	public BOOL wki1056_use_write_raw_data;
}

[CRepr]
public struct WKSTA_INFO_1057
{
	public BOOL wki1057_use_encryption;
}

[CRepr]
public struct WKSTA_INFO_1058
{
	public BOOL wki1058_buf_files_deny_write;
}

[CRepr]
public struct WKSTA_INFO_1059
{
	public BOOL wki1059_buf_read_only_files;
}

[CRepr]
public struct WKSTA_INFO_1060
{
	public BOOL wki1060_force_core_create_mode;
}

[CRepr]
public struct WKSTA_INFO_1061
{
	public BOOL wki1061_use_512_byte_max_transfer;
}

[CRepr]
public struct WKSTA_INFO_1062
{
	public uint32 wki1062_read_ahead_throughput;
}

[CRepr]
public struct WKSTA_USER_INFO_0
{
	public PWSTR wkui0_username;
}

[CRepr]
public struct WKSTA_USER_INFO_1
{
	public PWSTR wkui1_username;
	public PWSTR wkui1_logon_domain;
	public PWSTR wkui1_oth_domains;
	public PWSTR wkui1_logon_server;
}

[CRepr]
public struct WKSTA_USER_INFO_1101
{
	public PWSTR wkui1101_oth_domains;
}

[CRepr]
public struct WKSTA_TRANSPORT_INFO_0
{
	public uint32 wkti0_quality_of_service;
	public uint32 wkti0_number_of_vcs;
	public PWSTR wkti0_transport_name;
	public PWSTR wkti0_transport_address;
	public BOOL wkti0_wan_ish;
}

[CRepr]
public struct ERROR_LOG
{
	public uint32 el_len;
	public uint32 el_reserved;
	public uint32 el_time;
	public uint32 el_error;
	public PWSTR el_name;
	public PWSTR el_text;
	public uint8* el_data;
	public uint32 el_data_size;
	public uint32 el_nstrings;
}

[CRepr]
public struct HLOG
{
	public uint32 time;
	public uint32 last_flags;
	public uint32 offset;
	public uint32 rec_offset;
}

[CRepr]
public struct CONFIG_INFO_0
{
	public PWSTR cfgi0_key;
	public PWSTR cfgi0_data;
}

[CRepr]
public struct AUDIT_ENTRY
{
	public uint32 ae_len;
	public uint32 ae_reserved;
	public uint32 ae_time;
	public uint32 ae_type;
	public uint32 ae_data_offset;
	public uint32 ae_data_size;
}

[CRepr]
public struct AE_SRVSTATUS
{
	public uint32 ae_sv_status;
}

[CRepr]
public struct AE_SESSLOGON
{
	public uint32 ae_so_compname;
	public uint32 ae_so_username;
	public uint32 ae_so_privilege;
}

[CRepr]
public struct AE_SESSLOGOFF
{
	public uint32 ae_sf_compname;
	public uint32 ae_sf_username;
	public uint32 ae_sf_reason;
}

[CRepr]
public struct AE_SESSPWERR
{
	public uint32 ae_sp_compname;
	public uint32 ae_sp_username;
}

[CRepr]
public struct AE_CONNSTART
{
	public uint32 ae_ct_compname;
	public uint32 ae_ct_username;
	public uint32 ae_ct_netname;
	public uint32 ae_ct_connid;
}

[CRepr]
public struct AE_CONNSTOP
{
	public uint32 ae_cp_compname;
	public uint32 ae_cp_username;
	public uint32 ae_cp_netname;
	public uint32 ae_cp_connid;
	public uint32 ae_cp_reason;
}

[CRepr]
public struct AE_CONNREJ
{
	public uint32 ae_cr_compname;
	public uint32 ae_cr_username;
	public uint32 ae_cr_netname;
	public uint32 ae_cr_reason;
}

[CRepr]
public struct AE_RESACCESS
{
	public uint32 ae_ra_compname;
	public uint32 ae_ra_username;
	public uint32 ae_ra_resname;
	public uint32 ae_ra_operation;
	public uint32 ae_ra_returncode;
	public uint32 ae_ra_restype;
	public uint32 ae_ra_fileid;
}

[CRepr]
public struct AE_RESACCESSREJ
{
	public uint32 ae_rr_compname;
	public uint32 ae_rr_username;
	public uint32 ae_rr_resname;
	public uint32 ae_rr_operation;
}

[CRepr]
public struct AE_CLOSEFILE
{
	public uint32 ae_cf_compname;
	public uint32 ae_cf_username;
	public uint32 ae_cf_resname;
	public uint32 ae_cf_fileid;
	public uint32 ae_cf_duration;
	public uint32 ae_cf_reason;
}

[CRepr]
public struct AE_SERVICESTAT
{
	public uint32 ae_ss_compname;
	public uint32 ae_ss_username;
	public uint32 ae_ss_svcname;
	public uint32 ae_ss_status;
	public uint32 ae_ss_code;
	public uint32 ae_ss_text;
	public uint32 ae_ss_returnval;
}

[CRepr]
public struct AE_ACLMOD
{
	public uint32 ae_am_compname;
	public uint32 ae_am_username;
	public uint32 ae_am_resname;
	public uint32 ae_am_action;
	public uint32 ae_am_datalen;
}

[CRepr]
public struct AE_UASMOD
{
	public uint32 ae_um_compname;
	public uint32 ae_um_username;
	public uint32 ae_um_resname;
	public uint32 ae_um_rectype;
	public uint32 ae_um_action;
	public uint32 ae_um_datalen;
}

[CRepr]
public struct AE_NETLOGON
{
	public uint32 ae_no_compname;
	public uint32 ae_no_username;
	public uint32 ae_no_privilege;
	public uint32 ae_no_authflags;
}

[CRepr]
public struct AE_NETLOGOFF
{
	public uint32 ae_nf_compname;
	public uint32 ae_nf_username;
	public uint32 ae_nf_reserved1;
	public uint32 ae_nf_reserved2;
}

[CRepr]
public struct AE_ACCLIM
{
	public uint32 ae_al_compname;
	public uint32 ae_al_username;
	public uint32 ae_al_resname;
	public uint32 ae_al_limit;
}

[CRepr]
public struct AE_LOCKOUT
{
	public uint32 ae_lk_compname;
	public uint32 ae_lk_username;
	public uint32 ae_lk_action;
	public uint32 ae_lk_bad_pw_count;
}

[CRepr]
public struct AE_GENERIC
{
	public uint32 ae_ge_msgfile;
	public uint32 ae_ge_msgnum;
	public uint32 ae_ge_params;
	public uint32 ae_ge_param1;
	public uint32 ae_ge_param2;
	public uint32 ae_ge_param3;
	public uint32 ae_ge_param4;
	public uint32 ae_ge_param5;
	public uint32 ae_ge_param6;
	public uint32 ae_ge_param7;
	public uint32 ae_ge_param8;
	public uint32 ae_ge_param9;
}

[CRepr]
public struct DSREG_USER_INFO
{
	public PWSTR pszUserEmail;
	public PWSTR pszUserKeyId;
	public PWSTR pszUserKeyName;
}

[CRepr]
public struct DSREG_JOIN_INFO
{
	public DSREG_JOIN_TYPE joinType;
	public CERT_CONTEXT* pJoinCertificate;
	public PWSTR pszDeviceId;
	public PWSTR pszIdpDomain;
	public PWSTR pszTenantId;
	public PWSTR pszJoinUserEmail;
	public PWSTR pszTenantDisplayName;
	public PWSTR pszMdmEnrollmentUrl;
	public PWSTR pszMdmTermsOfUseUrl;
	public PWSTR pszMdmComplianceUrl;
	public PWSTR pszUserSettingSyncUrl;
	public DSREG_USER_INFO* pUserInfo;
}

[CRepr]
public struct NETSETUP_PROVISIONING_PARAMS
{
	public uint32 dwVersion;
	public PWSTR lpDomain;
	public PWSTR lpHostName;
	public PWSTR lpMachineAccountOU;
	public PWSTR lpDcName;
	public NETSETUP_PROVISION dwProvisionOptions;
	public PWSTR* aCertTemplateNames;
	public uint32 cCertTemplateNames;
	public PWSTR* aMachinePolicyNames;
	public uint32 cMachinePolicyNames;
	public PWSTR* aMachinePolicyPaths;
	public uint32 cMachinePolicyPaths;
	public PWSTR lpNetbiosName;
	public PWSTR lpSiteName;
	public PWSTR lpPrimaryDNSDomain;
}

[CRepr]
public struct AT_INFO
{
	public uint JobTime;
	public uint32 DaysOfMonth;
	public uint8 DaysOfWeek;
	public uint8 Flags;
	public PWSTR Command;
}

[CRepr]
public struct AT_ENUM
{
	public uint32 JobId;
	public uint JobTime;
	public uint32 DaysOfMonth;
	public uint8 DaysOfWeek;
	public uint8 Flags;
	public PWSTR Command;
}

[CRepr]
public struct FLAT_STRING
{
	public int16 MaximumLength;
	public int16 Length;
	public CHAR* Buffer mut => &Buffer_impl;
	private CHAR[ANYSIZE_ARRAY] Buffer_impl;
}

[CRepr]
public struct NETWORK_NAME
{
	public FLAT_STRING Name;
}

[CRepr]
public struct HARDWARE_ADDRESS
{
	public uint8[6] Address;
}

[CRepr]
public struct OBO_TOKEN
{
	public OBO_TOKEN_TYPE Type;
	public INetCfgComponent* pncc;
	public PWSTR pszwManufacturer;
	public PWSTR pszwProduct;
	public PWSTR pszwDisplayName;
	public BOOL fRegistered;
}

[CRepr]
public struct RASCON_IPUI
{
	public Guid guidConnection;
	public BOOL fIPv6Cfg;
	public uint32 dwFlags;
	public char16[16] pszwIpAddr;
	public char16[16] pszwDnsAddr;
	public char16[16] pszwDns2Addr;
	public char16[16] pszwWinsAddr;
	public char16[16] pszwWins2Addr;
	public char16[256] pszwDnsSuffix;
	public char16[65] pszwIpv6Addr;
	public uint32 dwIpv6PrefixLength;
	public char16[65] pszwIpv6DnsAddr;
	public char16[65] pszwIpv6Dns2Addr;
	public uint32 dwIPv4InfMetric;
	public uint32 dwIPv6InfMetric;
}

[CRepr]
public struct RTR_TOC_ENTRY
{
	public uint32 InfoType;
	public uint32 InfoSize;
	public uint32 Count;
	public uint32 Offset;
}

[CRepr]
public struct RTR_INFO_BLOCK_HEADER
{
	public uint32 Version;
	public uint32 Size;
	public uint32 TocEntriesCount;
	public RTR_TOC_ENTRY* TocEntry mut => &TocEntry_impl;
	private RTR_TOC_ENTRY[ANYSIZE_ARRAY] TocEntry_impl;
}

[CRepr]
public struct MPR_PROTOCOL_0
{
	public uint32 dwProtocolId;
	public char16[41] wszProtocol;
	public char16[49] wszDLLName;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_NetProvisioning = .(0x2aa2b5fe, 0xb846, 0x4d07, 0x81, 0x0c, 0xb2, 0x1e, 0xe4, 0x53, 0x20, 0xe3);


}
#endregion

#region COM Types
[CRepr]struct IEnumNetCfgBindingInterface : IUnknown
{
	public new const Guid IID = .(0xc0e8ae90, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetCfgBindingInterface** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetCfgBindingInterface** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, INetCfgBindingInterface** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetCfgBindingInterface** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumNetCfgBindingPath : IUnknown
{
	public new const Guid IID = .(0xc0e8ae91, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetCfgBindingPath** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetCfgBindingPath** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, INetCfgBindingPath** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetCfgBindingPath** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumNetCfgComponent : IUnknown
{
	public new const Guid IID = .(0xc0e8ae92, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, INetCfgComponent** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetCfgComponent** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, INetCfgComponent** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumNetCfgComponent** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct INetCfg : IUnknown
{
	public new const Guid IID = .(0xc0e8ae93, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pvReserved) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Uninitialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Apply;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidClass, IEnumNetCfgComponent** ppenumComponent) EnumComponents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwInfId, INetCfgComponent** pComponent) FindComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidClass, in Guid riid, void** ppvObject) QueryNetCfgClass;
	}


	public HRESULT Initialize(void* pvReserved) mut => VT.[Friend]Initialize(&this, pvReserved);

	public HRESULT Uninitialize() mut => VT.[Friend]Uninitialize(&this);

	public HRESULT Apply() mut => VT.[Friend]Apply(&this);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT EnumComponents(in Guid pguidClass, IEnumNetCfgComponent** ppenumComponent) mut => VT.[Friend]EnumComponents(&this, pguidClass, ppenumComponent);

	public HRESULT FindComponent(PWSTR pszwInfId, INetCfgComponent** pComponent) mut => VT.[Friend]FindComponent(&this, pszwInfId, pComponent);

	public HRESULT QueryNetCfgClass(in Guid pguidClass, in Guid riid, void** ppvObject) mut => VT.[Friend]QueryNetCfgClass(&this, pguidClass, riid, ppvObject);
}

[CRepr]struct INetCfgLock : IUnknown
{
	public new const Guid IID = .(0xc0e8ae9f, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cmsTimeout, PWSTR pszwClientDescription, PWSTR* ppszwClientDescription) AcquireWriteLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseWriteLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwClientDescription) IsWriteLocked;
	}


	public HRESULT AcquireWriteLock(uint32 cmsTimeout, PWSTR pszwClientDescription, PWSTR* ppszwClientDescription) mut => VT.[Friend]AcquireWriteLock(&this, cmsTimeout, pszwClientDescription, ppszwClientDescription);

	public HRESULT ReleaseWriteLock() mut => VT.[Friend]ReleaseWriteLock(&this);

	public HRESULT IsWriteLocked(PWSTR* ppszwClientDescription) mut => VT.[Friend]IsWriteLocked(&this, ppszwClientDescription);
}

[CRepr]struct INetCfgBindingInterface : IUnknown
{
	public new const Guid IID = .(0xc0e8ae94, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwInterfaceName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent** ppnccItem) GetUpperComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent** ppnccItem) GetLowerComponent;
	}


	public HRESULT GetName(PWSTR* ppszwInterfaceName) mut => VT.[Friend]GetName(&this, ppszwInterfaceName);

	public HRESULT GetUpperComponent(INetCfgComponent** ppnccItem) mut => VT.[Friend]GetUpperComponent(&this, ppnccItem);

	public HRESULT GetLowerComponent(INetCfgComponent** ppnccItem) mut => VT.[Friend]GetLowerComponent(&this, ppnccItem);
}

[CRepr]struct INetCfgBindingPath : IUnknown
{
	public new const Guid IID = .(0xc0e8ae96, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgBindingPath* pPath) IsSamePathAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgBindingPath* pPath) IsSubPathOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwPathToken) GetPathToken;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent** ppComponent) GetOwner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcInterfaces) GetDepth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetCfgBindingInterface** ppenumInterface) EnumBindingInterfaces;
	}


	public HRESULT IsSamePathAs(INetCfgBindingPath* pPath) mut => VT.[Friend]IsSamePathAs(&this, pPath);

	public HRESULT IsSubPathOf(INetCfgBindingPath* pPath) mut => VT.[Friend]IsSubPathOf(&this, pPath);

	public HRESULT IsEnabled() mut => VT.[Friend]IsEnabled(&this);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);

	public HRESULT GetPathToken(PWSTR* ppszwPathToken) mut => VT.[Friend]GetPathToken(&this, ppszwPathToken);

	public HRESULT GetOwner(INetCfgComponent** ppComponent) mut => VT.[Friend]GetOwner(&this, ppComponent);

	public HRESULT GetDepth(uint32* pcInterfaces) mut => VT.[Friend]GetDepth(&this, pcInterfaces);

	public HRESULT EnumBindingInterfaces(IEnumNetCfgBindingInterface** ppenumInterface) mut => VT.[Friend]EnumBindingInterfaces(&this, ppenumInterface);
}

[CRepr]struct INetCfgClass : IUnknown
{
	public new const Guid IID = .(0xc0e8ae97, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwInfId, INetCfgComponent** ppnccItem) FindComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumNetCfgComponent** ppenumComponent) EnumComponents;
	}


	public HRESULT FindComponent(PWSTR pszwInfId, INetCfgComponent** ppnccItem) mut => VT.[Friend]FindComponent(&this, pszwInfId, ppnccItem);

	public HRESULT EnumComponents(IEnumNetCfgComponent** ppenumComponent) mut => VT.[Friend]EnumComponents(&this, ppenumComponent);
}

[CRepr]struct INetCfgClassSetup : IUnknown
{
	public new const Guid IID = .(0xc0e8ae9d, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, OBO_TOKEN* pOboToken, INetCfgComponent** ppnccItem) SelectAndInstall;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwInfId, OBO_TOKEN* pOboToken, uint32 dwSetupFlags, uint32 dwUpgradeFromBuildNo, PWSTR pszwAnswerFile, PWSTR pszwAnswerSections, INetCfgComponent** ppnccItem) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pComponent, OBO_TOKEN* pOboToken, PWSTR* pmszwRefs) DeInstall;
	}


	public HRESULT SelectAndInstall(HWND hwndParent, OBO_TOKEN* pOboToken, INetCfgComponent** ppnccItem) mut => VT.[Friend]SelectAndInstall(&this, hwndParent, pOboToken, ppnccItem);

	public HRESULT Install(PWSTR pszwInfId, OBO_TOKEN* pOboToken, uint32 dwSetupFlags, uint32 dwUpgradeFromBuildNo, PWSTR pszwAnswerFile, PWSTR pszwAnswerSections, INetCfgComponent** ppnccItem) mut => VT.[Friend]Install(&this, pszwInfId, pOboToken, dwSetupFlags, dwUpgradeFromBuildNo, pszwAnswerFile, pszwAnswerSections, ppnccItem);

	public HRESULT DeInstall(INetCfgComponent* pComponent, OBO_TOKEN* pOboToken, PWSTR* pmszwRefs) mut => VT.[Friend]DeInstall(&this, pComponent, pOboToken, pmszwRefs);
}

[CRepr]struct INetCfgClassSetup2 : INetCfgClassSetup
{
	public new const Guid IID = .(0xc0e8aea0, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INetCfgClassSetup.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pIComp, uint32 dwSetupFlags, uint32 dwUpgradeFromBuildNo) UpdateNonEnumeratedComponent;
	}


	public HRESULT UpdateNonEnumeratedComponent(INetCfgComponent* pIComp, uint32 dwSetupFlags, uint32 dwUpgradeFromBuildNo) mut => VT.[Friend]UpdateNonEnumeratedComponent(&this, pIComp, dwSetupFlags, dwUpgradeFromBuildNo);
}

[CRepr]struct INetCfgComponent : IUnknown
{
	public new const Guid IID = .(0xc0e8ae99, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwDisplayName) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwDisplayName) SetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pszwHelpText) GetHelpText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwId) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCharacteristics) GetCharacteristics;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetInstanceGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwDevNodeId) GetPnpDevNodeId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGuid) GetClassGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszwBindName) GetBindName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulStatus) GetDeviceStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY* phkey) OpenParamKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint32 dwFlags, IUnknown* punkContext) RaisePropertyUi;
	}


	public HRESULT GetDisplayName(PWSTR* ppszwDisplayName) mut => VT.[Friend]GetDisplayName(&this, ppszwDisplayName);

	public HRESULT SetDisplayName(PWSTR pszwDisplayName) mut => VT.[Friend]SetDisplayName(&this, pszwDisplayName);

	public HRESULT GetHelpText(PWSTR* pszwHelpText) mut => VT.[Friend]GetHelpText(&this, pszwHelpText);

	public HRESULT GetId(PWSTR* ppszwId) mut => VT.[Friend]GetId(&this, ppszwId);

	public HRESULT GetCharacteristics(uint32* pdwCharacteristics) mut => VT.[Friend]GetCharacteristics(&this, pdwCharacteristics);

	public HRESULT GetInstanceGuid(Guid* pGuid) mut => VT.[Friend]GetInstanceGuid(&this, pGuid);

	public HRESULT GetPnpDevNodeId(PWSTR* ppszwDevNodeId) mut => VT.[Friend]GetPnpDevNodeId(&this, ppszwDevNodeId);

	public HRESULT GetClassGuid(Guid* pGuid) mut => VT.[Friend]GetClassGuid(&this, pGuid);

	public HRESULT GetBindName(PWSTR* ppszwBindName) mut => VT.[Friend]GetBindName(&this, ppszwBindName);

	public HRESULT GetDeviceStatus(uint32* pulStatus) mut => VT.[Friend]GetDeviceStatus(&this, pulStatus);

	public HRESULT OpenParamKey(HKEY* phkey) mut => VT.[Friend]OpenParamKey(&this, phkey);

	public HRESULT RaisePropertyUi(HWND hwndParent, uint32 dwFlags, IUnknown* punkContext) mut => VT.[Friend]RaisePropertyUi(&this, hwndParent, dwFlags, punkContext);
}

[CRepr]struct INetCfgComponentBindings : IUnknown
{
	public new const Guid IID = .(0xc0e8ae9e, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pnccItem) BindTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pnccItem) UnbindFrom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PWSTR pszwInterfaceName) SupportsBindingInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pnccItem) IsBoundTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pnccItem) IsBindableTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IEnumNetCfgBindingPath** ppIEnum) EnumBindingPaths;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgBindingPath* pncbItemSrc, INetCfgBindingPath* pncbItemDest) MoveBefore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgBindingPath* pncbItemSrc, INetCfgBindingPath* pncbItemDest) MoveAfter;
	}


	public HRESULT BindTo(INetCfgComponent* pnccItem) mut => VT.[Friend]BindTo(&this, pnccItem);

	public HRESULT UnbindFrom(INetCfgComponent* pnccItem) mut => VT.[Friend]UnbindFrom(&this, pnccItem);

	public HRESULT SupportsBindingInterface(uint32 dwFlags, PWSTR pszwInterfaceName) mut => VT.[Friend]SupportsBindingInterface(&this, dwFlags, pszwInterfaceName);

	public HRESULT IsBoundTo(INetCfgComponent* pnccItem) mut => VT.[Friend]IsBoundTo(&this, pnccItem);

	public HRESULT IsBindableTo(INetCfgComponent* pnccItem) mut => VT.[Friend]IsBindableTo(&this, pnccItem);

	public HRESULT EnumBindingPaths(uint32 dwFlags, IEnumNetCfgBindingPath** ppIEnum) mut => VT.[Friend]EnumBindingPaths(&this, dwFlags, ppIEnum);

	public HRESULT MoveBefore(INetCfgBindingPath* pncbItemSrc, INetCfgBindingPath* pncbItemDest) mut => VT.[Friend]MoveBefore(&this, pncbItemSrc, pncbItemDest);

	public HRESULT MoveAfter(INetCfgBindingPath* pncbItemSrc, INetCfgBindingPath* pncbItemDest) mut => VT.[Friend]MoveAfter(&this, pncbItemSrc, pncbItemDest);
}

[CRepr]struct INetCfgSysPrep : IUnknown
{
	public new const Guid IID = .(0xc0e8ae98, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSection, PWSTR pwszKey, uint32 dwValue) HrSetupSetFirstDword;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSection, PWSTR pwszKey, PWSTR pwszValue) HrSetupSetFirstString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSection, PWSTR pwszKey, BOOL fValue) HrSetupSetFirstStringAsBool;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszSection, PWSTR pwszKey, PWSTR pmszValue) HrSetupSetFirstMultiSzField;
	}


	public HRESULT HrSetupSetFirstDword(PWSTR pwszSection, PWSTR pwszKey, uint32 dwValue) mut => VT.[Friend]HrSetupSetFirstDword(&this, pwszSection, pwszKey, dwValue);

	public HRESULT HrSetupSetFirstString(PWSTR pwszSection, PWSTR pwszKey, PWSTR pwszValue) mut => VT.[Friend]HrSetupSetFirstString(&this, pwszSection, pwszKey, pwszValue);

	public HRESULT HrSetupSetFirstStringAsBool(PWSTR pwszSection, PWSTR pwszKey, BOOL fValue) mut => VT.[Friend]HrSetupSetFirstStringAsBool(&this, pwszSection, pwszKey, fValue);

	public HRESULT HrSetupSetFirstMultiSzField(PWSTR pwszSection, PWSTR pwszKey, PWSTR pmszValue) mut => VT.[Friend]HrSetupSetFirstMultiSzField(&this, pwszSection, pwszKey, pmszValue);
}

[CRepr]struct INetCfgPnpReconfigCallback : IUnknown
{
	public new const Guid IID = .(0x8d84bd35, 0xe227, 0x11d2, 0xb7, 0x00, 0x00, 0xa0, 0xc9, 0x8a, 0x6a, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NCPNP_RECONFIG_LAYER Layer, PWSTR pszwUpper, PWSTR pszwLower, void* pvData, uint32 dwSizeOfData) SendPnpReconfig;
	}


	public HRESULT SendPnpReconfig(NCPNP_RECONFIG_LAYER Layer, PWSTR pszwUpper, PWSTR pszwLower, void* pvData, uint32 dwSizeOfData) mut => VT.[Friend]SendPnpReconfig(&this, Layer, pszwUpper, pszwLower, pvData, dwSizeOfData);
}

[CRepr]struct INetCfgComponentControl : IUnknown
{
	public new const Guid IID = .(0x932238df, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pIComp, INetCfg* pINetCfg, BOOL fInstalling) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ApplyRegistryChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgPnpReconfigCallback* pICallback) ApplyPnpChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelChanges;
	}


	public HRESULT Initialize(INetCfgComponent* pIComp, INetCfg* pINetCfg, BOOL fInstalling) mut => VT.[Friend]Initialize(&this, pIComp, pINetCfg, fInstalling);

	public HRESULT ApplyRegistryChanges() mut => VT.[Friend]ApplyRegistryChanges(&this);

	public HRESULT ApplyPnpChanges(INetCfgPnpReconfigCallback* pICallback) mut => VT.[Friend]ApplyPnpChanges(&this, pICallback);

	public HRESULT CancelChanges() mut => VT.[Friend]CancelChanges(&this);
}

[CRepr]struct INetCfgComponentSetup : IUnknown
{
	public new const Guid IID = .(0x932238e3, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSetupFlags) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSetupFlags, uint32 dwUpgradeFomBuildNo) Upgrade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwAnswerFile, PWSTR pszwAnswerSections) ReadAnswerFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Removing;
	}


	public HRESULT Install(uint32 dwSetupFlags) mut => VT.[Friend]Install(&this, dwSetupFlags);

	public HRESULT Upgrade(uint32 dwSetupFlags, uint32 dwUpgradeFomBuildNo) mut => VT.[Friend]Upgrade(&this, dwSetupFlags, dwUpgradeFomBuildNo);

	public HRESULT ReadAnswerFile(PWSTR pszwAnswerFile, PWSTR pszwAnswerSections) mut => VT.[Friend]ReadAnswerFile(&this, pszwAnswerFile, pszwAnswerSections);

	public HRESULT Removing() mut => VT.[Friend]Removing(&this);
}

[CRepr]struct INetCfgComponentPropertyUi : IUnknown
{
	public new const Guid IID = .(0x932238e0, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkReserved) QueryPropertyUi;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkReserved) SetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDefPages, uint8** pahpspPrivate, uint32* pcPages, HWND hwndParent, PWSTR* pszStartPage) MergePropPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndSheet) ValidateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ApplyProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelProperties;
	}


	public HRESULT QueryPropertyUi(IUnknown* pUnkReserved) mut => VT.[Friend]QueryPropertyUi(&this, pUnkReserved);

	public HRESULT SetContext(IUnknown* pUnkReserved) mut => VT.[Friend]SetContext(&this, pUnkReserved);

	public HRESULT MergePropPages(uint32* pdwDefPages, uint8** pahpspPrivate, uint32* pcPages, HWND hwndParent, PWSTR* pszStartPage) mut => VT.[Friend]MergePropPages(&this, pdwDefPages, pahpspPrivate, pcPages, hwndParent, pszStartPage);

	public HRESULT ValidateProperties(HWND hwndSheet) mut => VT.[Friend]ValidateProperties(&this, hwndSheet);

	public HRESULT ApplyProperties() mut => VT.[Friend]ApplyProperties(&this);

	public HRESULT CancelProperties() mut => VT.[Friend]CancelProperties(&this);
}

[CRepr]struct INetCfgComponentNotifyBinding : IUnknown
{
	public new const Guid IID = .(0x932238e1, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeFlag, INetCfgBindingPath* pIPath) QueryBindingPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeFlag, INetCfgBindingPath* pIPath) NotifyBindingPath;
	}


	public HRESULT QueryBindingPath(uint32 dwChangeFlag, INetCfgBindingPath* pIPath) mut => VT.[Friend]QueryBindingPath(&this, dwChangeFlag, pIPath);

	public HRESULT NotifyBindingPath(uint32 dwChangeFlag, INetCfgBindingPath* pIPath) mut => VT.[Friend]NotifyBindingPath(&this, dwChangeFlag, pIPath);
}

[CRepr]struct INetCfgComponentNotifyGlobal : IUnknown
{
	public new const Guid IID = .(0x932238e2, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwNotifications) GetSupportedNotifications;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeFlag, INetCfgBindingPath* pIPath) SysQueryBindingPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeFlag, INetCfgBindingPath* pIPath) SysNotifyBindingPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwChangeFlag, INetCfgComponent* pIComp) SysNotifyComponent;
	}


	public HRESULT GetSupportedNotifications(uint32* dwNotifications) mut => VT.[Friend]GetSupportedNotifications(&this, dwNotifications);

	public HRESULT SysQueryBindingPath(uint32 dwChangeFlag, INetCfgBindingPath* pIPath) mut => VT.[Friend]SysQueryBindingPath(&this, dwChangeFlag, pIPath);

	public HRESULT SysNotifyBindingPath(uint32 dwChangeFlag, INetCfgBindingPath* pIPath) mut => VT.[Friend]SysNotifyBindingPath(&this, dwChangeFlag, pIPath);

	public HRESULT SysNotifyComponent(uint32 dwChangeFlag, INetCfgComponent* pIComp) mut => VT.[Friend]SysNotifyComponent(&this, dwChangeFlag, pIComp);
}

[CRepr]struct INetCfgComponentUpperEdge : IUnknown
{
	public new const Guid IID = .(0x932238e4, 0xbea1, 0x11d0, 0x92, 0x98, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pAdapter, uint32* pdwNumInterfaces, Guid** ppguidInterfaceIds) GetInterfaceIdsForAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddInterfacesToAdapter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgComponent* pAdapter, uint32 dwNumInterfaces, Guid* pguidInterfaceIds) RemoveInterfacesFromAdapter;
	}


	public HRESULT GetInterfaceIdsForAdapter(INetCfgComponent* pAdapter, uint32* pdwNumInterfaces, Guid** ppguidInterfaceIds) mut => VT.[Friend]GetInterfaceIdsForAdapter(&this, pAdapter, pdwNumInterfaces, ppguidInterfaceIds);

	public HRESULT AddInterfacesToAdapter() mut => VT.[Friend]AddInterfacesToAdapter(&this);

	public HRESULT RemoveInterfacesFromAdapter(INetCfgComponent* pAdapter, uint32 dwNumInterfaces, Guid* pguidInterfaceIds) mut => VT.[Friend]RemoveInterfacesFromAdapter(&this, pAdapter, dwNumInterfaces, pguidInterfaceIds);
}

[CRepr]struct INetLanConnectionUiInfo : IUnknown
{
	public new const Guid IID = .(0xc08956a6, 0x1cd3, 0x11d1, 0xb1, 0xc5, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) GetDeviceGuid;
	}


	public HRESULT GetDeviceGuid(Guid* pguid) mut => VT.[Friend]GetDeviceGuid(&this, pguid);
}

[CRepr]struct INetRasConnectionIpUiInfo : IUnknown
{
	public new const Guid IID = .(0xfaedcf58, 0x31fe, 0x11d1, 0xaa, 0xd2, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RASCON_IPUI* pInfo) GetUiInfo;
	}


	public HRESULT GetUiInfo(RASCON_IPUI* pInfo) mut => VT.[Friend]GetUiInfo(&this, pInfo);
}

[CRepr]struct INetCfgComponentSysPrep : IUnknown
{
	public new const Guid IID = .(0xc0e8ae9a, 0x306e, 0x11d1, 0xaa, 0xcf, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, INetCfgSysPrep* pncsp, PWSTR pszwAnswerSections, Guid* pAdapterInstanceGuid) SaveAdapterParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwAnswerFile, PWSTR pszwAnswerSection, Guid* pAdapterInstanceGuid) RestoreAdapterParameters;
	}


	public HRESULT SaveAdapterParameters(INetCfgSysPrep* pncsp, PWSTR pszwAnswerSections, Guid* pAdapterInstanceGuid) mut => VT.[Friend]SaveAdapterParameters(&this, pncsp, pszwAnswerSections, pAdapterInstanceGuid);

	public HRESULT RestoreAdapterParameters(PWSTR pszwAnswerFile, PWSTR pszwAnswerSection, Guid* pAdapterInstanceGuid) mut => VT.[Friend]RestoreAdapterParameters(&this, pszwAnswerFile, pszwAnswerSection, pAdapterInstanceGuid);
}

[CRepr]struct IProvisioningDomain : IUnknown
{
	public new const Guid IID = .(0xc96fbd50, 0x24dd, 0x11d8, 0x89, 0xfb, 0x00, 0x90, 0x4b, 0x2e, 0xa9, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwPathToFolder) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszwDomain, PWSTR pszwLanguage, PWSTR pszwXPathQuery, IXMLDOMNodeList** Nodes) Query;
	}


	public HRESULT Add(PWSTR pszwPathToFolder) mut => VT.[Friend]Add(&this, pszwPathToFolder);

	public HRESULT Query(PWSTR pszwDomain, PWSTR pszwLanguage, PWSTR pszwXPathQuery, IXMLDOMNodeList** Nodes) mut => VT.[Friend]Query(&this, pszwDomain, pszwLanguage, pszwXPathQuery, Nodes);
}

[CRepr]struct IProvisioningProfileWireless : IUnknown
{
	public new const Guid IID = .(0xc96fbd51, 0x24dd, 0x11d8, 0x89, 0xfb, 0x00, 0x90, 0x4b, 0x2e, 0xa9, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrXMLWirelessConfigProfile, BSTR bstrXMLConnectionConfigProfile, Guid* pAdapterInstanceGuid, uint32* pulStatus) CreateProfile;
	}


	public HRESULT CreateProfile(BSTR bstrXMLWirelessConfigProfile, BSTR bstrXMLConnectionConfigProfile, Guid* pAdapterInstanceGuid, uint32* pulStatus) mut => VT.[Friend]CreateProfile(&this, bstrXMLWirelessConfigProfile, bstrXMLConnectionConfigProfile, pAdapterInstanceGuid, pulStatus);
}

#endregion

#region Functions
public static
{
	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserEnum(PWSTR servername, uint32 level, NET_USER_ENUM_FILTER_FLAGS filter, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserGetInfo(PWSTR servername, PWSTR username, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserSetInfo(PWSTR servername, PWSTR username, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserDel(PWSTR servername, PWSTR username);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserGetGroups(PWSTR servername, PWSTR username, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserSetGroups(PWSTR servername, PWSTR username, uint32 level, uint8* buf, uint32 num_entries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserGetLocalGroups(PWSTR servername, PWSTR username, uint32 level, uint32 flags, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserModalsGet(PWSTR servername, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserModalsSet(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUserChangePassword(PWSTR domainname, PWSTR username, PWSTR oldpassword, PWSTR newpassword);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupAddUser(PWSTR servername, PWSTR GroupName, PWSTR username);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupGetInfo(PWSTR servername, PWSTR groupname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupSetInfo(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupDel(PWSTR servername, PWSTR groupname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupDelUser(PWSTR servername, PWSTR GroupName, PWSTR Username);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupGetUsers(PWSTR servername, PWSTR groupname, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint* ResumeHandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGroupSetUsers(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32 totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupAddMember(PWSTR servername, PWSTR groupname, PSID membersid);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupGetInfo(PWSTR servername, PWSTR groupname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupSetInfo(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupDel(PWSTR servername, PWSTR groupname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupDelMember(PWSTR servername, PWSTR groupname, PSID membersid);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupGetMembers(PWSTR servername, PWSTR localgroupname, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupSetMembers(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32 totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupAddMembers(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32 totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetLocalGroupDelMembers(PWSTR servername, PWSTR groupname, uint32 level, uint8* buf, uint32 totalentries);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetQueryDisplayInformation(PWSTR ServerName, uint32 Level, uint32 Index, uint32 EntriesRequested, uint32 PreferredMaximumLength, uint32* ReturnedEntryCount, void** SortedBuffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGetDisplayInformationIndex(PWSTR ServerName, uint32 Level, PWSTR Prefix, uint32* Index);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessEnum(PWSTR servername, PWSTR BasePath, uint32 Recursive, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessGetInfo(PWSTR servername, PWSTR resource, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessSetInfo(PWSTR servername, PWSTR resource, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessDel(PWSTR servername, PWSTR resource);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAccessGetUserPerms(PWSTR servername, PWSTR UGname, PWSTR resource, uint32* Perms);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetValidatePasswordPolicy(PWSTR ServerName, void* Qualifier, NET_VALIDATE_PASSWORD_TYPE ValidationType, void* InputArg, void** OutputArg);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetValidatePasswordPolicyFree(void** OutputArg);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGetDCName(PWSTR ServerName, PWSTR DomainName, uint8** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGetAnyDCName(PWSTR ServerName, PWSTR DomainName, uint8** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 I_NetLogonControl2(PWSTR ServerName, uint32 FunctionCode, uint32 QueryLevel, uint8* Data, uint8** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NetAddServiceAccount(PWSTR ServerName, PWSTR AccountName, PWSTR Password, uint32 Flags);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NetRemoveServiceAccount(PWSTR ServerName, PWSTR AccountName, uint32 Flags);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NetEnumerateServiceAccounts(PWSTR ServerName, uint32 Flags, uint32* AccountsCount, uint16*** Accounts);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NetIsServiceAccount(PWSTR ServerName, PWSTR AccountName, BOOL* IsService);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern NTSTATUS NetQueryServiceAccount(PWSTR ServerName, PWSTR AccountName, uint32 InfoLevel, uint8** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAlertRaise(PWSTR AlertType, void* Buffer, uint32 BufferSize);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAlertRaiseEx(PWSTR AlertType, void* VariableInfo, uint32 VariableInfoSize, PWSTR ServiceName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetMessageNameAdd(PWSTR servername, PWSTR msgname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetMessageNameEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetMessageNameGetInfo(PWSTR servername, PWSTR msgname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetMessageNameDel(PWSTR servername, PWSTR msgname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetMessageBufferSend(PWSTR servername, PWSTR msgname, PWSTR fromname, uint8* buf, uint32 buflen);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRemoteTOD(PWSTR UncServerName, uint8** BufferPtr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRemoteComputerSupports(PWSTR UncServerName, NET_REMOTE_COMPUTER_SUPPORTS_OPTIONS OptionsWanted, uint32* OptionsSupported);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplGetInfo(PWSTR servername, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplSetInfo(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirDel(PWSTR servername, PWSTR dirname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirGetInfo(PWSTR servername, PWSTR dirname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirSetInfo(PWSTR servername, PWSTR dirname, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirLock(PWSTR servername, PWSTR dirname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplExportDirUnlock(PWSTR servername, PWSTR dirname, uint32 unlockforce);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirAdd(PWSTR servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirDel(PWSTR servername, PWSTR dirname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirGetInfo(PWSTR servername, PWSTR dirname, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirLock(PWSTR servername, PWSTR dirname);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetReplImportDirUnlock(PWSTR servername, PWSTR dirname, uint32 unlockforce);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, NET_SERVER_TYPE servertype, PWSTR domain, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerGetInfo(PWSTR servername, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerSetInfo(PWSTR servername, uint32 level, uint8* buf, uint32* ParmError);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerDiskEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerComputerNameAdd(PWSTR ServerName, PWSTR EmulatedDomainName, PWSTR EmulatedServerName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerComputerNameDel(PWSTR ServerName, PWSTR EmulatedServerName);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerTransportAdd(PWSTR servername, uint32 level, uint8* bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerTransportAddEx(PWSTR servername, uint32 level, uint8* bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerTransportDel(PWSTR servername, uint32 level, uint8* bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServerTransportEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServiceControl(PWSTR servername, PWSTR service, uint32 opcode, uint32 arg, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServiceEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServiceGetInfo(PWSTR servername, PWSTR service, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetServiceInstall(PWSTR servername, PWSTR service, uint32 argc, PWSTR* argv, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUseAdd(int8* servername, uint32 LevelFlags, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUseDel(PWSTR UncServerName, PWSTR UseName, FORCE_LEVEL_FLAGS ForceLevelFlags);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUseEnum(PWSTR UncServerName, uint32 LevelFlags, uint8** BufPtr, uint32 PreferedMaximumSize, uint32* EntriesRead, uint32* TotalEntries, uint32* ResumeHandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUseGetInfo(PWSTR UncServerName, PWSTR UseName, uint32 LevelFlags, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaGetInfo(PWSTR servername, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaSetInfo(PWSTR servername, uint32 level, uint8* buffer, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaUserGetInfo(PWSTR reserved, uint32 level, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaUserSetInfo(PWSTR reserved, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaUserEnum(PWSTR servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resumehandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaTransportAdd(int8* servername, uint32 level, uint8* buf, uint32* parm_err);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaTransportDel(PWSTR servername, PWSTR transportname, FORCE_LEVEL_FLAGS ucond);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetWkstaTransportEnum(int8* servername, uint32 level, uint8** bufptr, uint32 prefmaxlen, uint32* entriesread, uint32* totalentries, uint32* resume_handle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetApiBufferAllocate(uint32 ByteCount, void** Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetApiBufferFree(void* Buffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetApiBufferReallocate(void* OldBuffer, uint32 NewByteCount, void** NewBuffer);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetApiBufferSize(void* Buffer, uint32* ByteCount);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetErrorLogClear(PWSTR UncServerName, PWSTR BackupFile, uint8* Reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetErrorLogRead(PWSTR UncServerName, PWSTR Reserved1, HLOG* ErrorLogHandle, uint32 Offset, uint32* Reserved2, uint32 Reserved3, uint32 OffsetFlag, uint8** BufPtr, uint32 PrefMaxSize, uint32* BytesRead, uint32* TotalAvailable);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetErrorLogWrite(uint8* Reserved1, uint32 Code, PWSTR Component, uint8* Buffer, uint32 NumBytes, uint8* MsgBuf, uint32 StrCount, uint8* Reserved2);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetConfigGet(PWSTR server, PWSTR component, PWSTR parameter, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetConfigGetAll(PWSTR server, PWSTR component, uint8** bufptr);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetConfigSet(PWSTR server, PWSTR reserved1, PWSTR component, uint32 level, uint32 reserved2, uint8* buf, uint32 reserved3);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAuditClear(PWSTR server, PWSTR backupfile, PWSTR service);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAuditRead(PWSTR server, PWSTR service, HLOG* auditloghandle, uint32 offset, uint32* reserved1, uint32 reserved2, uint32 offsetflag, uint8** bufptr, uint32 prefmaxlen, uint32* bytesread, uint32* totalavailable);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAuditWrite(uint32 type, uint8* buf, uint32 numbytes, PWSTR service, uint8* reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetJoinDomain(PWSTR lpServer, PWSTR lpDomain, PWSTR lpMachineAccountOU, PWSTR lpAccount, PWSTR lpPassword, NET_JOIN_DOMAIN_JOIN_OPTIONS fJoinOptions);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetUnjoinDomain(PWSTR lpServer, PWSTR lpAccount, PWSTR lpPassword, uint32 fUnjoinOptions);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRenameMachineInDomain(PWSTR lpServer, PWSTR lpNewMachineName, PWSTR lpAccount, PWSTR lpPassword, uint32 fRenameOptions);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetValidateName(PWSTR lpServer, PWSTR lpName, PWSTR lpAccount, PWSTR lpPassword, NETSETUP_NAME_TYPE NameType);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGetJoinableOUs(PWSTR lpServer, PWSTR lpDomain, PWSTR lpAccount, PWSTR lpPassword, uint32* OUCount, PWSTR** OUs);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetAddAlternateComputerName(PWSTR Server, PWSTR AlternateName, PWSTR DomainAccount, PWSTR DomainAccountPassword, uint32 Reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRemoveAlternateComputerName(PWSTR Server, PWSTR AlternateName, PWSTR DomainAccount, PWSTR DomainAccountPassword, uint32 Reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetSetPrimaryComputerName(PWSTR Server, PWSTR PrimaryName, PWSTR DomainAccount, PWSTR DomainAccountPassword, uint32 Reserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetEnumerateComputerNames(PWSTR Server, NET_COMPUTER_NAME_TYPE NameType, uint32 Reserved, uint32* EntryCount, PWSTR** ComputerNames);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetProvisionComputerAccount(PWSTR lpDomain, PWSTR lpMachineName, PWSTR lpMachineAccountOU, PWSTR lpDcName, NETSETUP_PROVISION dwOptions, uint8** pProvisionBinData, uint32* pdwProvisionBinDataSize, PWSTR* pProvisionTextData);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRequestOfflineDomainJoin(uint8* pProvisionBinData, uint32 cbProvisionBinDataSize, NET_REQUEST_PROVISION_OPTIONS dwOptions, PWSTR lpWindowsPath);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetCreateProvisioningPackage(NETSETUP_PROVISIONING_PARAMS* pProvisioningParams, uint8** ppPackageBinData, uint32* pdwPackageBinDataSize, PWSTR* ppPackageTextData);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetRequestProvisioningPackageInstall(uint8* pPackageBinData, uint32 dwPackageBinDataSize, NET_REQUEST_PROVISION_OPTIONS dwProvisionOptions, PWSTR lpWindowsPath, void* pvReserved);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT NetGetAadJoinInformation(PWSTR pcszTenantId, DSREG_JOIN_INFO** ppJoinInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void NetFreeAadJoinInformation(DSREG_JOIN_INFO* pJoinInfo);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetGetJoinInformation(PWSTR lpServer, PWSTR* lpNameBuffer, NETSETUP_JOIN_STATUS* BufferType);

	[Import("mstask.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetNetScheduleAccountInformation(PWSTR pwszServerName, uint32 ccAccount, char16* wszAccount);

	[Import("mstask.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetNetScheduleAccountInformation(PWSTR pwszServerName, PWSTR pwszAccount, PWSTR pwszPassword);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetScheduleJobAdd(PWSTR Servername, uint8* Buffer, uint32* JobId);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetScheduleJobDel(PWSTR Servername, uint32 MinJobId, uint32 MaxJobId);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetScheduleJobEnum(PWSTR Servername, uint8** PointerToBuffer, uint32 PrefferedMaximumLength, uint32* EntriesRead, uint32* TotalEntries, uint32* ResumeHandle);

	[Import("NETAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 NetScheduleJobGetInfo(PWSTR Servername, uint32 JobId, uint8** PointerToBuffer);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceRegisterExA(PSTR lpszCallerName, uint32 dwFlags);
	public static uint32 TraceRegisterEx(PSTR lpszCallerName, uint32 dwFlags) => TraceRegisterExA(lpszCallerName, dwFlags);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDeregisterA(uint32 dwTraceID);
	public static uint32 TraceDeregister(uint32 dwTraceID) => TraceDeregisterA(dwTraceID);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDeregisterExA(uint32 dwTraceID, uint32 dwFlags);
	public static uint32 TraceDeregisterEx(uint32 dwTraceID, uint32 dwFlags) => TraceDeregisterExA(dwTraceID, dwFlags);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceGetConsoleA(uint32 dwTraceID, HANDLE* lphConsole);
	public static uint32 TraceGetConsole(uint32 dwTraceID, HANDLE* lphConsole) => TraceGetConsoleA(dwTraceID, lphConsole);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePrintfA(uint32 dwTraceID, PSTR lpszFormat);
	public static uint32 TracePrintf(uint32 dwTraceID, PSTR lpszFormat) => TracePrintfA(dwTraceID, lpszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePrintfExA(uint32 dwTraceID, uint32 dwFlags, PSTR lpszFormat);
	public static uint32 TracePrintfEx(uint32 dwTraceID, uint32 dwFlags, PSTR lpszFormat) => TracePrintfExA(dwTraceID, dwFlags, lpszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceVprintfExA(uint32 dwTraceID, uint32 dwFlags, PSTR lpszFormat, int8* arglist);
	public static uint32 TraceVprintfEx(uint32 dwTraceID, uint32 dwFlags, PSTR lpszFormat, int8* arglist) => TraceVprintfExA(dwTraceID, dwFlags, lpszFormat, arglist);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePutsExA(uint32 dwTraceID, uint32 dwFlags, PSTR lpszString);
	public static uint32 TracePutsEx(uint32 dwTraceID, uint32 dwFlags, PSTR lpszString) => TracePutsExA(dwTraceID, dwFlags, lpszString);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDumpExA(uint32 dwTraceID, uint32 dwFlags, uint8* lpbBytes, uint32 dwByteCount, uint32 dwGroupSize, BOOL bAddressPrefix, PSTR lpszPrefix);
	public static uint32 TraceDumpEx(uint32 dwTraceID, uint32 dwFlags, uint8* lpbBytes, uint32 dwByteCount, uint32 dwGroupSize, BOOL bAddressPrefix, PSTR lpszPrefix) => TraceDumpExA(dwTraceID, dwFlags, lpbBytes, dwByteCount, dwGroupSize, bAddressPrefix, lpszPrefix);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceRegisterExW(PWSTR lpszCallerName, uint32 dwFlags);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDeregisterW(uint32 dwTraceID);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDeregisterExW(uint32 dwTraceID, uint32 dwFlags);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceGetConsoleW(uint32 dwTraceID, HANDLE* lphConsole);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePrintfW(uint32 dwTraceID, PWSTR lpszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePrintfExW(uint32 dwTraceID, uint32 dwFlags, PWSTR lpszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceVprintfExW(uint32 dwTraceID, uint32 dwFlags, PWSTR lpszFormat, int8* arglist);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TracePutsExW(uint32 dwTraceID, uint32 dwFlags, PWSTR lpszString);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 TraceDumpExW(uint32 dwTraceID, uint32 dwFlags, uint8* lpbBytes, uint32 dwByteCount, uint32 dwGroupSize, BOOL bAddressPrefix, PWSTR lpszPrefix);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LogErrorA(uint32 dwMessageId, uint32 cNumberOfSubStrings, PSTR* plpwsSubStrings, uint32 dwErrorCode);
	public static void LogError(uint32 dwMessageId, uint32 cNumberOfSubStrings, PSTR* plpwsSubStrings, uint32 dwErrorCode) => LogErrorA(dwMessageId, cNumberOfSubStrings, plpwsSubStrings, dwErrorCode);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LogEventA(uint32 wEventType, uint32 dwMessageId, uint32 cNumberOfSubStrings, PSTR* plpwsSubStrings);
	public static void LogEvent(uint32 wEventType, uint32 dwMessageId, uint32 cNumberOfSubStrings, PSTR* plpwsSubStrings) => LogEventA(wEventType, dwMessageId, cNumberOfSubStrings, plpwsSubStrings);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LogErrorW(uint32 dwMessageId, uint32 cNumberOfSubStrings, PWSTR* plpwsSubStrings, uint32 dwErrorCode);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void LogEventW(uint32 wEventType, uint32 dwMessageId, uint32 cNumberOfSubStrings, PWSTR* plpwsSubStrings);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE RouterLogRegisterA(PSTR lpszSource);
	public static HANDLE RouterLogRegister(PSTR lpszSource) => RouterLogRegisterA(lpszSource);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogDeregisterA(HANDLE hLogHandle);
	public static void RouterLogDeregister(HANDLE hLogHandle) => RouterLogDeregisterA(hLogHandle);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventA(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwErrorCode);
	public static void RouterLogEvent(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwErrorCode) => RouterLogEventA(hLogHandle, dwEventType, dwMessageId, dwSubStringCount, plpszSubStringArray, dwErrorCode);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventDataA(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwDataBytes, uint8* lpDataBytes);
	public static void RouterLogEventData(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwDataBytes, uint8* lpDataBytes) => RouterLogEventDataA(hLogHandle, dwEventType, dwMessageId, dwSubStringCount, plpszSubStringArray, dwDataBytes, lpDataBytes);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventStringA(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwErrorCode, uint32 dwErrorIndex);
	public static void RouterLogEventString(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PSTR* plpszSubStringArray, uint32 dwErrorCode, uint32 dwErrorIndex) => RouterLogEventStringA(hLogHandle, dwEventType, dwMessageId, dwSubStringCount, plpszSubStringArray, dwErrorCode, dwErrorIndex);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventExA(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PSTR ptszFormat);
	public static void RouterLogEventEx(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PSTR ptszFormat) => RouterLogEventExA(hLogHandle, dwEventType, dwErrorCode, dwMessageId, ptszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventValistExA(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PSTR ptszFormat, int8* arglist);
	public static void RouterLogEventValistEx(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PSTR ptszFormat, int8* arglist) => RouterLogEventValistExA(hLogHandle, dwEventType, dwErrorCode, dwMessageId, ptszFormat, arglist);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RouterGetErrorStringA(uint32 dwErrorCode, PSTR* lplpszErrorString);
	public static uint32 RouterGetErrorString(uint32 dwErrorCode, PSTR* lplpszErrorString) => RouterGetErrorStringA(dwErrorCode, lplpszErrorString);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE RouterLogRegisterW(PWSTR lpszSource);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogDeregisterW(HANDLE hLogHandle);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventW(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PWSTR* plpszSubStringArray, uint32 dwErrorCode);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventDataW(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PWSTR* plpszSubStringArray, uint32 dwDataBytes, uint8* lpDataBytes);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventStringW(HANDLE hLogHandle, uint32 dwEventType, uint32 dwMessageId, uint32 dwSubStringCount, PWSTR* plpszSubStringArray, uint32 dwErrorCode, uint32 dwErrorIndex);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventExW(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PWSTR ptszFormat);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterLogEventValistExW(HANDLE hLogHandle, uint32 dwEventType, uint32 dwErrorCode, uint32 dwMessageId, PWSTR ptszFormat, int8* arglist);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RouterGetErrorStringW(uint32 dwErrorCode, PWSTR* lplpwszErrorString);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RouterAssert(PSTR pszFailedAssertion, PSTR pszFileName, uint32 dwLineNumber, PSTR pszMessage);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprSetupProtocolEnum(uint32 dwTransportId, uint8** lplpBuffer, uint32* lpdwEntriesRead);

	[Import("rtutils.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprSetupProtocolFree(void* lpBuffer);

}
#endregion
