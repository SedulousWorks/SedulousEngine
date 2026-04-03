using Win32.Networking.WinSock;
using Win32.Foundation;
using Win32.Security.Cryptography;
using Win32.NetworkManagement.IpHelper;
using System;

namespace Win32.NetworkManagement.Rras;

#region Constants
public static
{
	public const uint32 RASNAP_ProbationTime = 1;
	public const uint32 RASTUNNELENDPOINT_UNKNOWN = 0;
	public const uint32 RASTUNNELENDPOINT_IPv4 = 1;
	public const uint32 RASTUNNELENDPOINT_IPv6 = 2;
	public const uint32 RAS_MaxDeviceType = 16;
	public const uint32 RAS_MaxPhoneNumber = 128;
	public const uint32 RAS_MaxIpAddress = 15;
	public const uint32 RAS_MaxIpxAddress = 21;
	public const uint32 RAS_MaxEntryName = 256;
	public const uint32 RAS_MaxDeviceName = 128;
	public const uint32 RAS_MaxCallbackNumber = 128;
	public const uint32 RAS_MaxAreaCode = 10;
	public const uint32 RAS_MaxPadType = 32;
	public const uint32 RAS_MaxX25Address = 200;
	public const uint32 RAS_MaxFacilities = 200;
	public const uint32 RAS_MaxUserData = 200;
	public const uint32 RAS_MaxReplyMessage = 1024;
	public const uint32 RAS_MaxDnsSuffix = 256;
	public const uint32 RASCF_AllUsers = 1;
	public const uint32 RASCF_GlobalCreds = 2;
	public const uint32 RASCF_OwnerKnown = 4;
	public const uint32 RASCF_OwnerMatch = 8;
	public const uint32 RAS_MaxIDSize = 256;
	public const uint32 RASCS_PAUSED = 4096;
	public const uint32 RASCS_DONE = 8192;
	public const uint32 RASCSS_DONE = 8192;
	public const uint32 RDEOPT_UsePrefixSuffix = 1;
	public const uint32 RDEOPT_PausedStates = 2;
	public const uint32 RDEOPT_IgnoreModemSpeaker = 4;
	public const uint32 RDEOPT_SetModemSpeaker = 8;
	public const uint32 RDEOPT_IgnoreSoftwareCompression = 16;
	public const uint32 RDEOPT_SetSoftwareCompression = 32;
	public const uint32 RDEOPT_DisableConnectedUI = 64;
	public const uint32 RDEOPT_DisableReconnectUI = 128;
	public const uint32 RDEOPT_DisableReconnect = 256;
	public const uint32 RDEOPT_NoUser = 512;
	public const uint32 RDEOPT_PauseOnScript = 1024;
	public const uint32 RDEOPT_Router = 2048;
	public const uint32 RDEOPT_CustomDial = 4096;
	public const uint32 RDEOPT_UseCustomScripting = 8192;
	public const uint32 RDEOPT_InvokeAutoTriggerCredentialUI = 16384;
	public const uint32 RDEOPT_EapInfoCryptInCapable = 32768;
	public const uint32 REN_User = 0;
	public const uint32 REN_AllUsers = 1;
	public const uint32 RASIPO_VJ = 1;
	public const uint32 RASLCPO_PFC = 1;
	public const uint32 RASLCPO_ACFC = 2;
	public const uint32 RASLCPO_SSHF = 4;
	public const uint32 RASLCPO_DES_56 = 8;
	public const uint32 RASLCPO_3_DES = 16;
	public const uint32 RASLCPO_AES_128 = 32;
	public const uint32 RASLCPO_AES_256 = 64;
	public const uint32 RASLCPO_AES_192 = 128;
	public const uint32 RASLCPO_GCM_AES_128 = 256;
	public const uint32 RASLCPO_GCM_AES_192 = 512;
	public const uint32 RASLCPO_GCM_AES_256 = 1024;
	public const uint32 RASCCPCA_MPPC = 6;
	public const uint32 RASCCPCA_STAC = 5;
	public const uint32 RASCCPO_Compression = 1;
	public const uint32 RASCCPO_HistoryLess = 2;
	public const uint32 RASCCPO_Encryption56bit = 16;
	public const uint32 RASCCPO_Encryption40bit = 32;
	public const uint32 RASCCPO_Encryption128bit = 64;
	public const uint32 RASIKEv2_AUTH_MACHINECERTIFICATES = 1;
	public const uint32 RASIKEv2_AUTH_EAP = 2;
	public const uint32 RASIKEv2_AUTH_PSK = 3;
	public const String RASDIALEVENT = "RasDialEvent";
	public const uint32 WM_RASDIALEVENT = 52429;
	public const uint32 ET_None = 0;
	public const uint32 ET_Require = 1;
	public const uint32 ET_RequireMax = 2;
	public const uint32 ET_Optional = 3;
	public const uint32 VS_Default = 0;
	public const uint32 VS_PptpOnly = 1;
	public const uint32 VS_PptpFirst = 2;
	public const uint32 VS_L2tpOnly = 3;
	public const uint32 VS_L2tpFirst = 4;
	public const uint32 VS_SstpOnly = 5;
	public const uint32 VS_SstpFirst = 6;
	public const uint32 VS_Ikev2Only = 7;
	public const uint32 VS_Ikev2First = 8;
	public const uint32 VS_GREOnly = 9;
	public const uint32 VS_PptpSstp = 12;
	public const uint32 VS_L2tpSstp = 13;
	public const uint32 VS_Ikev2Sstp = 14;
	public const uint32 VS_ProtocolList = 15;
	public const uint32 RASEO_UseCountryAndAreaCodes = 1;
	public const uint32 RASEO_SpecificIpAddr = 2;
	public const uint32 RASEO_SpecificNameServers = 4;
	public const uint32 RASEO_IpHeaderCompression = 8;
	public const uint32 RASEO_RemoteDefaultGateway = 16;
	public const uint32 RASEO_DisableLcpExtensions = 32;
	public const uint32 RASEO_TerminalBeforeDial = 64;
	public const uint32 RASEO_TerminalAfterDial = 128;
	public const uint32 RASEO_ModemLights = 256;
	public const uint32 RASEO_SwCompression = 512;
	public const uint32 RASEO_RequireEncryptedPw = 1024;
	public const uint32 RASEO_RequireMsEncryptedPw = 2048;
	public const uint32 RASEO_RequireDataEncryption = 4096;
	public const uint32 RASEO_NetworkLogon = 8192;
	public const uint32 RASEO_UseLogonCredentials = 16384;
	public const uint32 RASEO_PromoteAlternates = 32768;
	public const uint32 RASEO_SecureLocalFiles = 65536;
	public const uint32 RASEO_RequireEAP = 131072;
	public const uint32 RASEO_RequirePAP = 262144;
	public const uint32 RASEO_RequireSPAP = 524288;
	public const uint32 RASEO_Custom = 1048576;
	public const uint32 RASEO_PreviewPhoneNumber = 2097152;
	public const uint32 RASEO_SharedPhoneNumbers = 8388608;
	public const uint32 RASEO_PreviewUserPw = 16777216;
	public const uint32 RASEO_PreviewDomain = 33554432;
	public const uint32 RASEO_ShowDialingProgress = 67108864;
	public const uint32 RASEO_RequireCHAP = 134217728;
	public const uint32 RASEO_RequireMsCHAP = 268435456;
	public const uint32 RASEO_RequireMsCHAP2 = 536870912;
	public const uint32 RASEO_RequireW95MSCHAP = 1073741824;
	public const uint32 RASEO_CustomScript = 2147483648;
	public const uint32 RASEO2_SecureFileAndPrint = 1;
	public const uint32 RASEO2_SecureClientForMSNet = 2;
	public const uint32 RASEO2_DontNegotiateMultilink = 4;
	public const uint32 RASEO2_DontUseRasCredentials = 8;
	public const uint32 RASEO2_UsePreSharedKey = 16;
	public const uint32 RASEO2_Internet = 32;
	public const uint32 RASEO2_DisableNbtOverIP = 64;
	public const uint32 RASEO2_UseGlobalDeviceSettings = 128;
	public const uint32 RASEO2_ReconnectIfDropped = 256;
	public const uint32 RASEO2_SharePhoneNumbers = 512;
	public const uint32 RASEO2_SecureRoutingCompartment = 1024;
	public const uint32 RASEO2_UseTypicalSettings = 2048;
	public const uint32 RASEO2_IPv6SpecificNameServers = 4096;
	public const uint32 RASEO2_IPv6RemoteDefaultGateway = 8192;
	public const uint32 RASEO2_RegisterIpWithDNS = 16384;
	public const uint32 RASEO2_UseDNSSuffixForRegistration = 32768;
	public const uint32 RASEO2_IPv4ExplicitMetric = 65536;
	public const uint32 RASEO2_IPv6ExplicitMetric = 131072;
	public const uint32 RASEO2_DisableIKENameEkuCheck = 262144;
	public const uint32 RASEO2_DisableClassBasedStaticRoute = 524288;
	public const uint32 RASEO2_SpecificIPv6Addr = 1048576;
	public const uint32 RASEO2_DisableMobility = 2097152;
	public const uint32 RASEO2_RequireMachineCertificates = 4194304;
	public const uint32 RASEO2_UsePreSharedKeyForIkev2Initiator = 8388608;
	public const uint32 RASEO2_UsePreSharedKeyForIkev2Responder = 16777216;
	public const uint32 RASEO2_CacheCredentials = 33554432;
	public const uint32 RASEO2_AutoTriggerCapable = 67108864;
	public const uint32 RASEO2_IsThirdPartyProfile = 134217728;
	public const uint32 RASEO2_AuthTypeIsOtp = 268435456;
	public const uint32 RASEO2_IsAlwaysOn = 536870912;
	public const uint32 RASEO2_IsPrivateNetwork = 1073741824;
	public const uint32 RASEO2_PlumbIKEv2TSAsRoutes = 2147483648;
	public const uint32 RASNP_NetBEUI = 1;
	public const uint32 RASNP_Ipx = 2;
	public const uint32 RASNP_Ip = 4;
	public const uint32 RASNP_Ipv6 = 8;
	public const uint32 RASFP_Ppp = 1;
	public const uint32 RASFP_Slip = 2;
	public const uint32 RASFP_Ras = 4;
	public const String RASDT_Modem = "modem";
	public const String RASDT_Isdn = "isdn";
	public const String RASDT_X25 = "x25";
	public const String RASDT_Vpn = "vpn";
	public const String RASDT_Pad = "pad";
	public const String RASDT_Generic = "GENERIC";
	public const String RASDT_Serial = "SERIAL";
	public const String RASDT_FrameRelay = "FRAMERELAY";
	public const String RASDT_Atm = "ATM";
	public const String RASDT_Sonet = "SONET";
	public const String RASDT_SW56 = "SW56";
	public const String RASDT_Irda = "IRDA";
	public const String RASDT_Parallel = "PARALLEL";
	public const String RASDT_PPPoE = "PPPoE";
	public const uint32 RASET_Phone = 1;
	public const uint32 RASET_Vpn = 2;
	public const uint32 RASET_Direct = 3;
	public const uint32 RASET_Internet = 4;
	public const uint32 RASET_Broadband = 5;
	public const uint32 RASCN_Connection = 1;
	public const uint32 RASCN_Disconnection = 2;
	public const uint32 RASCN_BandwidthAdded = 4;
	public const uint32 RASCN_BandwidthRemoved = 8;
	public const uint32 RASCN_Dormant = 16;
	public const uint32 RASCN_ReConnection = 32;
	public const uint32 RASCN_EPDGPacketArrival = 64;
	public const uint32 RASIDS_Disabled = 4294967295;
	public const uint32 RASIDS_UseGlobalValue = 0;
	public const uint32 RASADFLG_PositionDlg = 1;
	public const uint32 RASCM_UserName = 1;
	public const uint32 RASCM_Password = 2;
	public const uint32 RASCM_Domain = 4;
	public const uint32 RASCM_DefaultCreds = 8;
	public const uint32 RASCM_PreSharedKey = 16;
	public const uint32 RASCM_ServerPreSharedKey = 32;
	public const uint32 RASCM_DDMPreSharedKey = 64;
	public const uint32 RASADP_DisableConnectionQuery = 0;
	public const uint32 RASADP_LoginSessionDisable = 1;
	public const uint32 RASADP_SavedAddressesLimit = 2;
	public const uint32 RASADP_FailedConnectionTimeout = 3;
	public const uint32 RASADP_ConnectionQueryTimeout = 4;
	public const uint32 RASEAPF_NonInteractive = 2;
	public const uint32 RASEAPF_Logon = 4;
	public const uint32 RASEAPF_Preview = 8;
	public const uint32 RCD_SingleUser = 0;
	public const uint32 RCD_AllUsers = 1;
	public const uint32 RCD_Eap = 2;
	public const uint32 RCD_Logon = 4;
	public const uint32 RASPBDEVENT_AddEntry = 1;
	public const uint32 RASPBDEVENT_EditEntry = 2;
	public const uint32 RASPBDEVENT_RemoveEntry = 3;
	public const uint32 RASPBDEVENT_DialEntry = 4;
	public const uint32 RASPBDEVENT_EditGlobals = 5;
	public const uint32 RASPBDEVENT_NoUser = 6;
	public const uint32 RASPBDEVENT_NoUserEdit = 7;
	public const uint32 RASNOUSER_SmartCard = 1;
	public const uint32 RASPBDFLAG_PositionDlg = 1;
	public const uint32 RASPBDFLAG_ForceCloseOnDial = 2;
	public const uint32 RASPBDFLAG_NoUser = 16;
	public const uint32 RASPBDFLAG_UpdateDefaults = 2147483648;
	public const uint32 RASEDFLAG_PositionDlg = 1;
	public const uint32 RASEDFLAG_NewEntry = 2;
	public const uint32 RASEDFLAG_CloneEntry = 4;
	public const uint32 RASEDFLAG_NoRename = 8;
	public const uint32 RASEDFLAG_ShellOwned = 1073741824;
	public const uint32 RASEDFLAG_NewPhoneEntry = 16;
	public const uint32 RASEDFLAG_NewTunnelEntry = 32;
	public const uint32 RASEDFLAG_NewDirectEntry = 64;
	public const uint32 RASEDFLAG_NewBroadbandEntry = 128;
	public const uint32 RASEDFLAG_InternetEntry = 256;
	public const uint32 RASEDFLAG_NAT = 512;
	public const uint32 RASEDFLAG_IncomingConnection = 1024;
	public const uint32 RASDDFLAG_PositionDlg = 1;
	public const uint32 RASDDFLAG_NoPrompt = 2;
	public const uint32 RASDDFLAG_AoacRedial = 4;
	public const uint32 RASDDFLAG_LinkFailure = 2147483648;
	public const String RRAS_SERVICE_NAME = "RemoteAccess";
	public const uint32 PID_IPX = 43;
	public const uint32 PID_IP = 33;
	public const uint32 PID_IPV6 = 87;
	public const uint32 PID_NBF = 63;
	public const uint32 PID_ATALK = 41;
	public const uint32 MPR_INTERFACE_OUT_OF_RESOURCES = 1;
	public const uint32 MPR_INTERFACE_ADMIN_DISABLED = 2;
	public const uint32 MPR_INTERFACE_CONNECTION_FAILURE = 4;
	public const uint32 MPR_INTERFACE_SERVICE_PAUSED = 8;
	public const uint32 MPR_INTERFACE_DIALOUT_HOURS_RESTRICTION = 16;
	public const uint32 MPR_INTERFACE_NO_MEDIA_SENSE = 32;
	public const uint32 MPR_INTERFACE_NO_DEVICE = 64;
	public const uint32 MPR_MaxDeviceType = 16;
	public const uint32 MPR_MaxPhoneNumber = 128;
	public const uint32 MPR_MaxIpAddress = 15;
	public const uint32 MPR_MaxIpxAddress = 21;
	public const uint32 MPR_MaxEntryName = 256;
	public const uint32 MPR_MaxDeviceName = 128;
	public const uint32 MPR_MaxCallbackNumber = 128;
	public const uint32 MPR_MaxAreaCode = 10;
	public const uint32 MPR_MaxPadType = 32;
	public const uint32 MPR_MaxX25Address = 200;
	public const uint32 MPR_MaxFacilities = 200;
	public const uint32 MPR_MaxUserData = 200;
	public const uint32 MPRIO_SpecificIpAddr = 2;
	public const uint32 MPRIO_SpecificNameServers = 4;
	public const uint32 MPRIO_IpHeaderCompression = 8;
	public const uint32 MPRIO_RemoteDefaultGateway = 16;
	public const uint32 MPRIO_DisableLcpExtensions = 32;
	public const uint32 MPRIO_SwCompression = 512;
	public const uint32 MPRIO_RequireEncryptedPw = 1024;
	public const uint32 MPRIO_RequireMsEncryptedPw = 2048;
	public const uint32 MPRIO_RequireDataEncryption = 4096;
	public const uint32 MPRIO_NetworkLogon = 8192;
	public const uint32 MPRIO_PromoteAlternates = 32768;
	public const uint32 MPRIO_SecureLocalFiles = 65536;
	public const uint32 MPRIO_RequireEAP = 131072;
	public const uint32 MPRIO_RequirePAP = 262144;
	public const uint32 MPRIO_RequireSPAP = 524288;
	public const uint32 MPRIO_SharedPhoneNumbers = 8388608;
	public const uint32 MPRIO_RequireCHAP = 134217728;
	public const uint32 MPRIO_RequireMsCHAP = 268435456;
	public const uint32 MPRIO_RequireMsCHAP2 = 536870912;
	public const uint32 MPRIO_IpSecPreSharedKey = 2147483648;
	public const uint32 MPRIO_RequireMachineCertificates = 16777216;
	public const uint32 MPRIO_UsePreSharedKeyForIkev2Initiator = 33554432;
	public const uint32 MPRIO_UsePreSharedKeyForIkev2Responder = 67108864;
	public const uint32 MPRNP_Ipx = 2;
	public const uint32 MPRNP_Ip = 4;
	public const uint32 MPRNP_Ipv6 = 8;
	public const String MPRDT_Modem = "modem";
	public const String MPRDT_Isdn = "isdn";
	public const String MPRDT_X25 = "x25";
	public const String MPRDT_Vpn = "vpn";
	public const String MPRDT_Pad = "pad";
	public const String MPRDT_Generic = "GENERIC";
	public const String MPRDT_Serial = "SERIAL";
	public const String MPRDT_FrameRelay = "FRAMERELAY";
	public const String MPRDT_Atm = "ATM";
	public const String MPRDT_Sonet = "SONET";
	public const String MPRDT_SW56 = "SW56";
	public const String MPRDT_Irda = "IRDA";
	public const String MPRDT_Parallel = "PARALLEL";
	public const uint32 MPRET_Phone = 1;
	public const uint32 MPRET_Vpn = 2;
	public const uint32 MPRET_Direct = 3;
	public const uint32 MPRIDS_Disabled = 4294967295;
	public const uint32 MPRIDS_UseGlobalValue = 0;
	public const uint32 MPR_VS_Ikev2Only = 7;
	public const uint32 MPR_VS_Ikev2First = 8;
	public const uint32 MPR_ENABLE_RAS_ON_DEVICE = 1;
	public const uint32 MPR_ENABLE_ROUTING_ON_DEVICE = 2;
	public const uint32 IPADDRESSLEN = 15;
	public const uint32 IPXADDRESSLEN = 22;
	public const uint32 ATADDRESSLEN = 32;
	public const uint32 MAXIPADRESSLEN = 64;
	public const uint32 PPP_IPCP_VJ = 1;
	public const uint32 PPP_CCP_COMPRESSION = 1;
	public const uint32 PPP_CCP_ENCRYPTION40BITOLD = 16;
	public const uint32 PPP_CCP_ENCRYPTION40BIT = 32;
	public const uint32 PPP_CCP_ENCRYPTION128BIT = 64;
	public const uint32 PPP_CCP_ENCRYPTION56BIT = 128;
	public const uint32 PPP_CCP_HISTORYLESS = 16777216;
	public const uint32 PPP_LCP_MULTILINK_FRAMING = 1;
	public const uint32 PPP_LCP_PFC = 2;
	public const uint32 PPP_LCP_ACFC = 4;
	public const uint32 PPP_LCP_SSHF = 8;
	public const uint32 PPP_LCP_DES_56 = 16;
	public const uint32 PPP_LCP_3_DES = 32;
	public const uint32 PPP_LCP_AES_128 = 64;
	public const uint32 PPP_LCP_AES_256 = 128;
	public const uint32 PPP_LCP_AES_192 = 256;
	public const uint32 PPP_LCP_GCM_AES_128 = 512;
	public const uint32 PPP_LCP_GCM_AES_192 = 1024;
	public const uint32 PPP_LCP_GCM_AES_256 = 2048;
	public const uint32 RAS_FLAGS_RAS_CONNECTION = 4;
	public const uint32 RASPRIV_NoCallback = 1;
	public const uint32 RASPRIV_AdminSetCallback = 2;
	public const uint32 RASPRIV_CallerSetCallback = 4;
	public const uint32 RASPRIV_DialinPrivilege = 8;
	public const uint32 RASPRIV2_DialinPolicy = 1;
	public const uint32 MPRAPI_IKEV2_AUTH_USING_CERT = 1;
	public const uint32 MPRAPI_IKEV2_AUTH_USING_EAP = 2;
	public const uint32 MPRAPI_PPP_PROJECTION_INFO_TYPE = 1;
	public const uint32 MPRAPI_IKEV2_PROJECTION_INFO_TYPE = 2;
	public const uint32 MPRAPI_RAS_CONNECTION_OBJECT_REVISION_1 = 1;
	public const uint32 MPRAPI_MPR_IF_CUSTOM_CONFIG_OBJECT_REVISION_1 = 1;
	public const uint32 MPRAPI_IF_CUSTOM_CONFIG_FOR_IKEV2 = 1;
	public const uint32 MPRAPI_MPR_IF_CUSTOM_CONFIG_OBJECT_REVISION_3 = 3;
	public const uint32 MPRAPI_MPR_IF_CUSTOM_CONFIG_OBJECT_REVISION_2 = 2;
	public const uint32 MPRAPI_IKEV2_SET_TUNNEL_CONFIG_PARAMS = 1;
	public const uint32 MPRAPI_L2TP_SET_TUNNEL_CONFIG_PARAMS = 1;
	public const uint32 MAX_SSTP_HASH_SIZE = 32;
	public const uint32 MPRAPI_MPR_SERVER_OBJECT_REVISION_1 = 1;
	public const uint32 MPRAPI_MPR_SERVER_OBJECT_REVISION_2 = 2;
	public const uint32 MPRAPI_MPR_SERVER_OBJECT_REVISION_3 = 3;
	public const uint32 MPRAPI_MPR_SERVER_OBJECT_REVISION_4 = 4;
	public const uint32 MPRAPI_MPR_SERVER_OBJECT_REVISION_5 = 5;
	public const uint32 MPRAPI_MPR_SERVER_SET_CONFIG_OBJECT_REVISION_1 = 1;
	public const uint32 MPRAPI_MPR_SERVER_SET_CONFIG_OBJECT_REVISION_2 = 2;
	public const uint32 MPRAPI_MPR_SERVER_SET_CONFIG_OBJECT_REVISION_3 = 3;
	public const uint32 MPRAPI_MPR_SERVER_SET_CONFIG_OBJECT_REVISION_4 = 4;
	public const uint32 MPRAPI_MPR_SERVER_SET_CONFIG_OBJECT_REVISION_5 = 5;
	public const uint32 MPRAPI_SET_CONFIG_PROTOCOL_FOR_PPTP = 1;
	public const uint32 MPRAPI_SET_CONFIG_PROTOCOL_FOR_L2TP = 2;
	public const uint32 MPRAPI_SET_CONFIG_PROTOCOL_FOR_SSTP = 4;
	public const uint32 MPRAPI_SET_CONFIG_PROTOCOL_FOR_IKEV2 = 8;
	public const uint32 MPRAPI_SET_CONFIG_PROTOCOL_FOR_GRE = 16;
	public const uint32 ALLOW_NO_AUTH = 1;
	public const uint32 DO_NOT_ALLOW_NO_AUTH = 0;
	public const uint32 MPRAPI_RAS_UPDATE_CONNECTION_OBJECT_REVISION_1 = 1;
	public const uint32 MPRAPI_ADMIN_DLL_VERSION_1 = 1;
	public const uint32 MPRAPI_ADMIN_DLL_VERSION_2 = 2;
	public const uint32 MGM_JOIN_STATE_FLAG = 1;
	public const uint32 MGM_FORWARD_STATE_FLAG = 2;
	public const uint32 MGM_MFE_STATS_0 = 1;
	public const uint32 MGM_MFE_STATS_1 = 2;
	public const uint32 RTM_MAX_ADDRESS_SIZE = 16;
	public const uint32 RTM_MAX_VIEWS = 32;
	public const uint32 RTM_VIEW_ID_UCAST = 0;
	public const uint32 RTM_VIEW_ID_MCAST = 1;
	public const uint32 RTM_VIEW_MASK_SIZE = 32;
	public const uint32 RTM_VIEW_MASK_NONE = 0;
	public const uint32 RTM_VIEW_MASK_ANY = 0;
	public const uint32 RTM_VIEW_MASK_UCAST = 1;
	public const uint32 RTM_VIEW_MASK_MCAST = 2;
	public const uint32 RTM_VIEW_MASK_ALL = 4294967295;
	public const uint32 IPV6_ADDRESS_LEN_IN_BYTES = 16;
	public const uint32 RTM_DEST_FLAG_NATURAL_NET = 1;
	public const uint32 RTM_DEST_FLAG_FWD_ENGIN_ADD = 2;
	public const uint32 RTM_DEST_FLAG_DONT_FORWARD = 4;
	public const uint32 RTM_ROUTE_STATE_CREATED = 0;
	public const uint32 RTM_ROUTE_STATE_DELETING = 1;
	public const uint32 RTM_ROUTE_STATE_DELETED = 2;
	public const uint32 RTM_ROUTE_FLAGS_MARTIAN = 1;
	public const uint32 RTM_ROUTE_FLAGS_BLACKHOLE = 2;
	public const uint32 RTM_ROUTE_FLAGS_DISCARD = 4;
	public const uint32 RTM_ROUTE_FLAGS_INACTIVE = 8;
	public const uint32 RTM_ROUTE_FLAGS_LOCAL = 16;
	public const uint32 RTM_ROUTE_FLAGS_REMOTE = 32;
	public const uint32 RTM_ROUTE_FLAGS_MYSELF = 64;
	public const uint32 RTM_ROUTE_FLAGS_LOOPBACK = 128;
	public const uint32 RTM_ROUTE_FLAGS_MCAST = 256;
	public const uint32 RTM_ROUTE_FLAGS_LOCAL_MCAST = 512;
	public const uint32 RTM_ROUTE_FLAGS_LIMITED_BC = 1024;
	public const uint32 RTM_ROUTE_FLAGS_ZEROS_NETBC = 4096;
	public const uint32 RTM_ROUTE_FLAGS_ZEROS_SUBNETBC = 8192;
	public const uint32 RTM_ROUTE_FLAGS_ONES_NETBC = 16384;
	public const uint32 RTM_ROUTE_FLAGS_ONES_SUBNETBC = 32768;
	public const uint32 RTM_NEXTHOP_STATE_CREATED = 0;
	public const uint32 RTM_NEXTHOP_STATE_DELETED = 1;
	public const uint32 RTM_NEXTHOP_FLAGS_REMOTE = 1;
	public const uint32 RTM_NEXTHOP_FLAGS_DOWN = 2;
	public const uint32 METHOD_TYPE_ALL_METHODS = 4294967295;
	public const uint32 METHOD_RIP2_NEIGHBOUR_ADDR = 1;
	public const uint32 METHOD_RIP2_OUTBOUND_INTF = 2;
	public const uint32 METHOD_RIP2_ROUTE_TAG = 4;
	public const uint32 METHOD_RIP2_ROUTE_TIMESTAMP = 8;
	public const uint32 METHOD_BGP4_AS_PATH = 1;
	public const uint32 METHOD_BGP4_PEER_ID = 2;
	public const uint32 METHOD_BGP4_PA_ORIGIN = 4;
	public const uint32 METHOD_BGP4_NEXTHOP_ATTR = 8;
	public const uint32 RTM_RESUME_METHODS = 0;
	public const uint32 RTM_BLOCK_METHODS = 1;
	public const uint32 RTM_ROUTE_CHANGE_FIRST = 1;
	public const uint32 RTM_ROUTE_CHANGE_NEW = 2;
	public const uint32 RTM_ROUTE_CHANGE_BEST = 65536;
	public const uint32 RTM_NEXTHOP_CHANGE_NEW = 1;
	public const uint32 RTM_MATCH_NONE = 0;
	public const uint32 RTM_MATCH_OWNER = 1;
	public const uint32 RTM_MATCH_NEIGHBOUR = 2;
	public const uint32 RTM_MATCH_PREF = 4;
	public const uint32 RTM_MATCH_NEXTHOP = 8;
	public const uint32 RTM_MATCH_INTERFACE = 16;
	public const uint32 RTM_MATCH_FULL = 65535;
	public const uint32 RTM_ENUM_START = 0;
	public const uint32 RTM_ENUM_NEXT = 1;
	public const uint32 RTM_ENUM_RANGE = 2;
	public const uint32 RTM_ENUM_ALL_DESTS = 0;
	public const uint32 RTM_ENUM_OWN_DESTS = 16777216;
	public const uint32 RTM_ENUM_ALL_ROUTES = 0;
	public const uint32 RTM_ENUM_OWN_ROUTES = 65536;
	public const uint32 RTM_NUM_CHANGE_TYPES = 3;
	public const uint32 RTM_CHANGE_TYPE_ALL = 1;
	public const uint32 RTM_CHANGE_TYPE_BEST = 2;
	public const uint32 RTM_CHANGE_TYPE_FORWARDING = 4;
	public const uint32 RTM_NOTIFY_ONLY_MARKED_DESTS = 65536;
	public const uint32 RASBASE = 600;
	public const uint32 PENDING = 600;
	public const uint32 ERROR_INVALID_PORT_HANDLE = 601;
	public const uint32 ERROR_PORT_ALREADY_OPEN = 602;
	public const uint32 ERROR_BUFFER_TOO_SMALL = 603;
	public const uint32 ERROR_WRONG_INFO_SPECIFIED = 604;
	public const uint32 ERROR_CANNOT_SET_PORT_INFO = 605;
	public const uint32 ERROR_PORT_NOT_CONNECTED = 606;
	public const uint32 ERROR_EVENT_INVALID = 607;
	public const uint32 ERROR_DEVICE_DOES_NOT_EXIST = 608;
	public const uint32 ERROR_DEVICETYPE_DOES_NOT_EXIST = 609;
	public const uint32 ERROR_BUFFER_INVALID = 610;
	public const uint32 ERROR_ROUTE_NOT_AVAILABLE = 611;
	public const uint32 ERROR_ROUTE_NOT_ALLOCATED = 612;
	public const uint32 ERROR_INVALID_COMPRESSION_SPECIFIED = 613;
	public const uint32 ERROR_OUT_OF_BUFFERS = 614;
	public const uint32 ERROR_PORT_NOT_FOUND = 615;
	public const uint32 ERROR_ASYNC_REQUEST_PENDING = 616;
	public const uint32 ERROR_ALREADY_DISCONNECTING = 617;
	public const uint32 ERROR_PORT_NOT_OPEN = 618;
	public const uint32 ERROR_PORT_DISCONNECTED = 619;
	public const uint32 ERROR_NO_ENDPOINTS = 620;
	public const uint32 ERROR_CANNOT_OPEN_PHONEBOOK = 621;
	public const uint32 ERROR_CANNOT_LOAD_PHONEBOOK = 622;
	public const uint32 ERROR_CANNOT_FIND_PHONEBOOK_ENTRY = 623;
	public const uint32 ERROR_CANNOT_WRITE_PHONEBOOK = 624;
	public const uint32 ERROR_CORRUPT_PHONEBOOK = 625;
	public const uint32 ERROR_CANNOT_LOAD_STRING = 626;
	public const uint32 ERROR_KEY_NOT_FOUND = 627;
	public const uint32 ERROR_DISCONNECTION = 628;
	public const uint32 ERROR_REMOTE_DISCONNECTION = 629;
	public const uint32 ERROR_HARDWARE_FAILURE = 630;
	public const uint32 ERROR_USER_DISCONNECTION = 631;
	public const uint32 ERROR_INVALID_SIZE = 632;
	public const uint32 ERROR_PORT_NOT_AVAILABLE = 633;
	public const uint32 ERROR_CANNOT_PROJECT_CLIENT = 634;
	public const uint32 ERROR_UNKNOWN = 635;
	public const uint32 ERROR_WRONG_DEVICE_ATTACHED = 636;
	public const uint32 ERROR_BAD_STRING = 637;
	public const uint32 ERROR_REQUEST_TIMEOUT = 638;
	public const uint32 ERROR_CANNOT_GET_LANA = 639;
	public const uint32 ERROR_NETBIOS_ERROR = 640;
	public const uint32 ERROR_SERVER_OUT_OF_RESOURCES = 641;
	public const uint32 ERROR_NAME_EXISTS_ON_NET = 642;
	public const uint32 ERROR_SERVER_GENERAL_NET_FAILURE = 643;
	public const uint32 WARNING_MSG_ALIAS_NOT_ADDED = 644;
	public const uint32 ERROR_AUTH_INTERNAL = 645;
	public const uint32 ERROR_RESTRICTED_LOGON_HOURS = 646;
	public const uint32 ERROR_ACCT_DISABLED = 647;
	public const uint32 ERROR_PASSWD_EXPIRED = 648;
	public const uint32 ERROR_NO_DIALIN_PERMISSION = 649;
	public const uint32 ERROR_SERVER_NOT_RESPONDING = 650;
	public const uint32 ERROR_FROM_DEVICE = 651;
	public const uint32 ERROR_UNRECOGNIZED_RESPONSE = 652;
	public const uint32 ERROR_MACRO_NOT_FOUND = 653;
	public const uint32 ERROR_MACRO_NOT_DEFINED = 654;
	public const uint32 ERROR_MESSAGE_MACRO_NOT_FOUND = 655;
	public const uint32 ERROR_DEFAULTOFF_MACRO_NOT_FOUND = 656;
	public const uint32 ERROR_FILE_COULD_NOT_BE_OPENED = 657;
	public const uint32 ERROR_DEVICENAME_TOO_LONG = 658;
	public const uint32 ERROR_DEVICENAME_NOT_FOUND = 659;
	public const uint32 ERROR_NO_RESPONSES = 660;
	public const uint32 ERROR_NO_COMMAND_FOUND = 661;
	public const uint32 ERROR_WRONG_KEY_SPECIFIED = 662;
	public const uint32 ERROR_UNKNOWN_DEVICE_TYPE = 663;
	public const uint32 ERROR_ALLOCATING_MEMORY = 664;
	public const uint32 ERROR_PORT_NOT_CONFIGURED = 665;
	public const uint32 ERROR_DEVICE_NOT_READY = 666;
	public const uint32 ERROR_READING_INI_FILE = 667;
	public const uint32 ERROR_NO_CONNECTION = 668;
	public const uint32 ERROR_BAD_USAGE_IN_INI_FILE = 669;
	public const uint32 ERROR_READING_SECTIONNAME = 670;
	public const uint32 ERROR_READING_DEVICETYPE = 671;
	public const uint32 ERROR_READING_DEVICENAME = 672;
	public const uint32 ERROR_READING_USAGE = 673;
	public const uint32 ERROR_READING_MAXCONNECTBPS = 674;
	public const uint32 ERROR_READING_MAXCARRIERBPS = 675;
	public const uint32 ERROR_LINE_BUSY = 676;
	public const uint32 ERROR_VOICE_ANSWER = 677;
	public const uint32 ERROR_NO_ANSWER = 678;
	public const uint32 ERROR_NO_CARRIER = 679;
	public const uint32 ERROR_NO_DIALTONE = 680;
	public const uint32 ERROR_IN_COMMAND = 681;
	public const uint32 ERROR_WRITING_SECTIONNAME = 682;
	public const uint32 ERROR_WRITING_DEVICETYPE = 683;
	public const uint32 ERROR_WRITING_DEVICENAME = 684;
	public const uint32 ERROR_WRITING_MAXCONNECTBPS = 685;
	public const uint32 ERROR_WRITING_MAXCARRIERBPS = 686;
	public const uint32 ERROR_WRITING_USAGE = 687;
	public const uint32 ERROR_WRITING_DEFAULTOFF = 688;
	public const uint32 ERROR_READING_DEFAULTOFF = 689;
	public const uint32 ERROR_EMPTY_INI_FILE = 690;
	public const uint32 ERROR_AUTHENTICATION_FAILURE = 691;
	public const uint32 ERROR_PORT_OR_DEVICE = 692;
	public const uint32 ERROR_NOT_BINARY_MACRO = 693;
	public const uint32 ERROR_DCB_NOT_FOUND = 694;
	public const uint32 ERROR_STATE_MACHINES_NOT_STARTED = 695;
	public const uint32 ERROR_STATE_MACHINES_ALREADY_STARTED = 696;
	public const uint32 ERROR_PARTIAL_RESPONSE_LOOPING = 697;
	public const uint32 ERROR_UNKNOWN_RESPONSE_KEY = 698;
	public const uint32 ERROR_RECV_BUF_FULL = 699;
	public const uint32 ERROR_CMD_TOO_LONG = 700;
	public const uint32 ERROR_UNSUPPORTED_BPS = 701;
	public const uint32 ERROR_UNEXPECTED_RESPONSE = 702;
	public const uint32 ERROR_INTERACTIVE_MODE = 703;
	public const uint32 ERROR_BAD_CALLBACK_NUMBER = 704;
	public const uint32 ERROR_INVALID_AUTH_STATE = 705;
	public const uint32 ERROR_WRITING_INITBPS = 706;
	public const uint32 ERROR_X25_DIAGNOSTIC = 707;
	public const uint32 ERROR_ACCT_EXPIRED = 708;
	public const uint32 ERROR_CHANGING_PASSWORD = 709;
	public const uint32 ERROR_OVERRUN = 710;
	public const uint32 ERROR_RASMAN_CANNOT_INITIALIZE = 711;
	public const uint32 ERROR_BIPLEX_PORT_NOT_AVAILABLE = 712;
	public const uint32 ERROR_NO_ACTIVE_ISDN_LINES = 713;
	public const uint32 ERROR_NO_ISDN_CHANNELS_AVAILABLE = 714;
	public const uint32 ERROR_TOO_MANY_LINE_ERRORS = 715;
	public const uint32 ERROR_IP_CONFIGURATION = 716;
	public const uint32 ERROR_NO_IP_ADDRESSES = 717;
	public const uint32 ERROR_PPP_TIMEOUT = 718;
	public const uint32 ERROR_PPP_REMOTE_TERMINATED = 719;
	public const uint32 ERROR_PPP_NO_PROTOCOLS_CONFIGURED = 720;
	public const uint32 ERROR_PPP_NO_RESPONSE = 721;
	public const uint32 ERROR_PPP_INVALID_PACKET = 722;
	public const uint32 ERROR_PHONE_NUMBER_TOO_LONG = 723;
	public const uint32 ERROR_IPXCP_NO_DIALOUT_CONFIGURED = 724;
	public const uint32 ERROR_IPXCP_NO_DIALIN_CONFIGURED = 725;
	public const uint32 ERROR_IPXCP_DIALOUT_ALREADY_ACTIVE = 726;
	public const uint32 ERROR_ACCESSING_TCPCFGDLL = 727;
	public const uint32 ERROR_NO_IP_RAS_ADAPTER = 728;
	public const uint32 ERROR_SLIP_REQUIRES_IP = 729;
	public const uint32 ERROR_PROJECTION_NOT_COMPLETE = 730;
	public const uint32 ERROR_PROTOCOL_NOT_CONFIGURED = 731;
	public const uint32 ERROR_PPP_NOT_CONVERGING = 732;
	public const uint32 ERROR_PPP_CP_REJECTED = 733;
	public const uint32 ERROR_PPP_LCP_TERMINATED = 734;
	public const uint32 ERROR_PPP_REQUIRED_ADDRESS_REJECTED = 735;
	public const uint32 ERROR_PPP_NCP_TERMINATED = 736;
	public const uint32 ERROR_PPP_LOOPBACK_DETECTED = 737;
	public const uint32 ERROR_PPP_NO_ADDRESS_ASSIGNED = 738;
	public const uint32 ERROR_CANNOT_USE_LOGON_CREDENTIALS = 739;
	public const uint32 ERROR_TAPI_CONFIGURATION = 740;
	public const uint32 ERROR_NO_LOCAL_ENCRYPTION = 741;
	public const uint32 ERROR_NO_REMOTE_ENCRYPTION = 742;
	public const uint32 ERROR_REMOTE_REQUIRES_ENCRYPTION = 743;
	public const uint32 ERROR_IPXCP_NET_NUMBER_CONFLICT = 744;
	public const uint32 ERROR_INVALID_SMM = 745;
	public const uint32 ERROR_SMM_UNINITIALIZED = 746;
	public const uint32 ERROR_NO_MAC_FOR_PORT = 747;
	public const uint32 ERROR_SMM_TIMEOUT = 748;
	public const uint32 ERROR_BAD_PHONE_NUMBER = 749;
	public const uint32 ERROR_WRONG_MODULE = 750;
	public const uint32 ERROR_INVALID_CALLBACK_NUMBER = 751;
	public const uint32 ERROR_SCRIPT_SYNTAX = 752;
	public const uint32 ERROR_HANGUP_FAILED = 753;
	public const uint32 ERROR_BUNDLE_NOT_FOUND = 754;
	public const uint32 ERROR_CANNOT_DO_CUSTOMDIAL = 755;
	public const uint32 ERROR_DIAL_ALREADY_IN_PROGRESS = 756;
	public const uint32 ERROR_RASAUTO_CANNOT_INITIALIZE = 757;
	public const uint32 ERROR_CONNECTION_ALREADY_SHARED = 758;
	public const uint32 ERROR_SHARING_CHANGE_FAILED = 759;
	public const uint32 ERROR_SHARING_ROUTER_INSTALL = 760;
	public const uint32 ERROR_SHARE_CONNECTION_FAILED = 761;
	public const uint32 ERROR_SHARING_PRIVATE_INSTALL = 762;
	public const uint32 ERROR_CANNOT_SHARE_CONNECTION = 763;
	public const uint32 ERROR_NO_SMART_CARD_READER = 764;
	public const uint32 ERROR_SHARING_ADDRESS_EXISTS = 765;
	public const uint32 ERROR_NO_CERTIFICATE = 766;
	public const uint32 ERROR_SHARING_MULTIPLE_ADDRESSES = 767;
	public const uint32 ERROR_FAILED_TO_ENCRYPT = 768;
	public const uint32 ERROR_BAD_ADDRESS_SPECIFIED = 769;
	public const uint32 ERROR_CONNECTION_REJECT = 770;
	public const uint32 ERROR_CONGESTION = 771;
	public const uint32 ERROR_INCOMPATIBLE = 772;
	public const uint32 ERROR_NUMBERCHANGED = 773;
	public const uint32 ERROR_TEMPFAILURE = 774;
	public const uint32 ERROR_BLOCKED = 775;
	public const uint32 ERROR_DONOTDISTURB = 776;
	public const uint32 ERROR_OUTOFORDER = 777;
	public const uint32 ERROR_UNABLE_TO_AUTHENTICATE_SERVER = 778;
	public const uint32 ERROR_SMART_CARD_REQUIRED = 779;
	public const uint32 ERROR_INVALID_FUNCTION_FOR_ENTRY = 780;
	public const uint32 ERROR_CERT_FOR_ENCRYPTION_NOT_FOUND = 781;
	public const uint32 ERROR_SHARING_RRAS_CONFLICT = 782;
	public const uint32 ERROR_SHARING_NO_PRIVATE_LAN = 783;
	public const uint32 ERROR_NO_DIFF_USER_AT_LOGON = 784;
	public const uint32 ERROR_NO_REG_CERT_AT_LOGON = 785;
	public const uint32 ERROR_OAKLEY_NO_CERT = 786;
	public const uint32 ERROR_OAKLEY_AUTH_FAIL = 787;
	public const uint32 ERROR_OAKLEY_ATTRIB_FAIL = 788;
	public const uint32 ERROR_OAKLEY_GENERAL_PROCESSING = 789;
	public const uint32 ERROR_OAKLEY_NO_PEER_CERT = 790;
	public const uint32 ERROR_OAKLEY_NO_POLICY = 791;
	public const uint32 ERROR_OAKLEY_TIMED_OUT = 792;
	public const uint32 ERROR_OAKLEY_ERROR = 793;
	public const uint32 ERROR_UNKNOWN_FRAMED_PROTOCOL = 794;
	public const uint32 ERROR_WRONG_TUNNEL_TYPE = 795;
	public const uint32 ERROR_UNKNOWN_SERVICE_TYPE = 796;
	public const uint32 ERROR_CONNECTING_DEVICE_NOT_FOUND = 797;
	public const uint32 ERROR_NO_EAPTLS_CERTIFICATE = 798;
	public const uint32 ERROR_SHARING_HOST_ADDRESS_CONFLICT = 799;
	public const uint32 ERROR_AUTOMATIC_VPN_FAILED = 800;
	public const uint32 ERROR_VALIDATING_SERVER_CERT = 801;
	public const uint32 ERROR_READING_SCARD = 802;
	public const uint32 ERROR_INVALID_PEAP_COOKIE_CONFIG = 803;
	public const uint32 ERROR_INVALID_PEAP_COOKIE_USER = 804;
	public const uint32 ERROR_INVALID_MSCHAPV2_CONFIG = 805;
	public const uint32 ERROR_VPN_GRE_BLOCKED = 806;
	public const uint32 ERROR_VPN_DISCONNECT = 807;
	public const uint32 ERROR_VPN_REFUSED = 808;
	public const uint32 ERROR_VPN_TIMEOUT = 809;
	public const uint32 ERROR_VPN_BAD_CERT = 810;
	public const uint32 ERROR_VPN_BAD_PSK = 811;
	public const uint32 ERROR_SERVER_POLICY = 812;
	public const uint32 ERROR_BROADBAND_ACTIVE = 813;
	public const uint32 ERROR_BROADBAND_NO_NIC = 814;
	public const uint32 ERROR_BROADBAND_TIMEOUT = 815;
	public const uint32 ERROR_FEATURE_DEPRECATED = 816;
	public const uint32 ERROR_CANNOT_DELETE = 817;
	public const uint32 ERROR_RASQEC_RESOURCE_CREATION_FAILED = 818;
	public const uint32 ERROR_RASQEC_NAPAGENT_NOT_ENABLED = 819;
	public const uint32 ERROR_RASQEC_NAPAGENT_NOT_CONNECTED = 820;
	public const uint32 ERROR_RASQEC_CONN_DOESNOTEXIST = 821;
	public const uint32 ERROR_RASQEC_TIMEOUT = 822;
	public const uint32 ERROR_PEAP_CRYPTOBINDING_INVALID = 823;
	public const uint32 ERROR_PEAP_CRYPTOBINDING_NOTRECEIVED = 824;
	public const uint32 ERROR_INVALID_VPNSTRATEGY = 825;
	public const uint32 ERROR_EAPTLS_CACHE_CREDENTIALS_INVALID = 826;
	public const uint32 ERROR_IPSEC_SERVICE_STOPPED = 827;
	public const uint32 ERROR_IDLE_TIMEOUT = 828;
	public const uint32 ERROR_LINK_FAILURE = 829;
	public const uint32 ERROR_USER_LOGOFF = 830;
	public const uint32 ERROR_FAST_USER_SWITCH = 831;
	public const uint32 ERROR_HIBERNATION = 832;
	public const uint32 ERROR_SYSTEM_SUSPENDED = 833;
	public const uint32 ERROR_RASMAN_SERVICE_STOPPED = 834;
	public const uint32 ERROR_INVALID_SERVER_CERT = 835;
	public const uint32 ERROR_NOT_NAP_CAPABLE = 836;
	public const uint32 ERROR_INVALID_TUNNELID = 837;
	public const uint32 ERROR_UPDATECONNECTION_REQUEST_IN_PROCESS = 838;
	public const uint32 ERROR_PROTOCOL_ENGINE_DISABLED = 839;
	public const uint32 ERROR_INTERNAL_ADDRESS_FAILURE = 840;
	public const uint32 ERROR_FAILED_CP_REQUIRED = 841;
	public const uint32 ERROR_TS_UNACCEPTABLE = 842;
	public const uint32 ERROR_MOBIKE_DISABLED = 843;
	public const uint32 ERROR_CANNOT_INITIATE_MOBIKE_UPDATE = 844;
	public const uint32 ERROR_PEAP_SERVER_REJECTED_CLIENT_TLV = 845;
	public const uint32 ERROR_INVALID_PREFERENCES = 846;
	public const uint32 ERROR_EAPTLS_SCARD_CACHE_CREDENTIALS_INVALID = 847;
	public const uint32 ERROR_SSTP_COOKIE_SET_FAILURE = 848;
	public const uint32 ERROR_INVALID_PEAP_COOKIE_ATTRIBUTES = 849;
	public const uint32 ERROR_EAP_METHOD_NOT_INSTALLED = 850;
	public const uint32 ERROR_EAP_METHOD_DOES_NOT_SUPPORT_SSO = 851;
	public const uint32 ERROR_EAP_METHOD_OPERATION_NOT_SUPPORTED = 852;
	public const uint32 ERROR_EAP_USER_CERT_INVALID = 853;
	public const uint32 ERROR_EAP_USER_CERT_EXPIRED = 854;
	public const uint32 ERROR_EAP_USER_CERT_REVOKED = 855;
	public const uint32 ERROR_EAP_USER_CERT_OTHER_ERROR = 856;
	public const uint32 ERROR_EAP_SERVER_CERT_INVALID = 857;
	public const uint32 ERROR_EAP_SERVER_CERT_EXPIRED = 858;
	public const uint32 ERROR_EAP_SERVER_CERT_REVOKED = 859;
	public const uint32 ERROR_EAP_SERVER_CERT_OTHER_ERROR = 860;
	public const uint32 ERROR_EAP_USER_ROOT_CERT_NOT_FOUND = 861;
	public const uint32 ERROR_EAP_USER_ROOT_CERT_INVALID = 862;
	public const uint32 ERROR_EAP_USER_ROOT_CERT_EXPIRED = 863;
	public const uint32 ERROR_EAP_SERVER_ROOT_CERT_NOT_FOUND = 864;
	public const uint32 ERROR_EAP_SERVER_ROOT_CERT_INVALID = 865;
	public const uint32 ERROR_EAP_SERVER_ROOT_CERT_NAME_REQUIRED = 866;
	public const uint32 ERROR_PEAP_IDENTITY_MISMATCH = 867;
	public const uint32 ERROR_DNSNAME_NOT_RESOLVABLE = 868;
	public const uint32 ERROR_EAPTLS_PASSWD_INVALID = 869;
	public const uint32 ERROR_IKEV2_PSK_INTERFACE_ALREADY_EXISTS = 870;
	public const uint32 ERROR_INVALID_DESTINATION_IP = 871;
	public const uint32 ERROR_INVALID_INTERFACE_CONFIG = 872;
	public const uint32 ERROR_VPN_PLUGIN_GENERIC = 873;
	public const uint32 ERROR_SSO_CERT_MISSING = 874;
	public const uint32 ERROR_DEVICE_COMPLIANCE = 875;
	public const uint32 ERROR_PLUGIN_NOT_INSTALLED = 876;
	public const uint32 ERROR_ACTION_REQUIRED = 877;
	public const uint32 RASBASEEND = 877;
}
#endregion

#region TypeDefs
typealias HRASCONN = int;

#endregion


#region Enums

[AllowDuplicates]
public enum MPR_INTERFACE_DIAL_MODE : uint32
{
	MPRDM_DialFirst = 0,
	MPRDM_DialAll = 1,
	MPRDM_DialAsNeeded = 2,
}


[AllowDuplicates]
public enum RASENTRY_DIAL_MODE : uint32
{
	RASEDM_DialAll = 1,
	RASEDM_DialAsNeeded = 2,
}


[AllowDuplicates]
public enum RAS_FLAGS : uint32
{
	RAS_FLAGS_PPP_CONNECTION = 1,
	RAS_FLAGS_MESSENGER_PRESENT = 2,
	RAS_FLAGS_QUARANTINE_PRESENT = 8,
	RAS_FLAGS_ARAP_CONNECTION = 16,
	RAS_FLAGS_IKEV2_CONNECTION = 16,
	RAS_FLAGS_DORMANT = 32,
}


[AllowDuplicates]
public enum MPR_ET : uint32
{
	MPR_ET_None = 0,
	MPR_ET_Require = 1,
	MPR_ET_RequireMax = 2,
	MPR_ET_Optional = 3,
}


[AllowDuplicates]
public enum RASPPP_PROJECTION_INFO_SERVER_AUTH_DATA : uint32
{
	RASLCPAD_CHAP_MD5 = 5,
	RASLCPAD_CHAP_MS = 128,
	RASLCPAD_CHAP_MSV2 = 129,
}


[AllowDuplicates]
public enum PPP_LCP : uint32
{
	PPP_LCP_PAP = 49187,
	PPP_LCP_CHAP = 49699,
	PPP_LCP_EAP = 49703,
	PPP_LCP_SPAP = 49191,
}


[AllowDuplicates]
public enum RASPPP_PROJECTION_INFO_SERVER_AUTH_PROTOCOL : uint32
{
	RASLCPAP_PAP = 49187,
	RASLCPAP_SPAP = 49191,
	RASLCPAP_CHAP = 49699,
	RASLCPAP_EAP = 49703,
}


[AllowDuplicates]
public enum PPP_LCP_INFO_AUTH_DATA : uint32
{
	PPP_LCP_CHAP_MD5 = 5,
	PPP_LCP_CHAP_MS = 128,
	PPP_LCP_CHAP_MSV2 = 129,
}


[AllowDuplicates]
public enum RASIKEV_PROJECTION_INFO_FLAGS : uint32
{
	RASIKEv2_FLAGS_MOBIKESUPPORTED = 1,
	RASIKEv2_FLAGS_BEHIND_NAT = 2,
	RASIKEv2_FLAGS_SERVERBEHIND_NAT = 4,
}


[AllowDuplicates]
public enum MPR_VS : uint32
{
	MPR_VS_Default = 0,
	MPR_VS_PptpOnly = 1,
	MPR_VS_PptpFirst = 2,
	MPR_VS_L2tpOnly = 3,
	MPR_VS_L2tpFirst = 4,
}


[AllowDuplicates]
public enum SECURITY_MESSAGE_MSG_ID : uint32
{
	SECURITYMSG_SUCCESS = 1,
	SECURITYMSG_FAILURE = 2,
	SECURITYMSG_ERROR = 3,
}


[AllowDuplicates]
public enum RASAPIVERSION : int32
{
	RASAPIVERSION_500 = 1,
	RASAPIVERSION_501 = 2,
	RASAPIVERSION_600 = 3,
	RASAPIVERSION_601 = 4,
}


[AllowDuplicates]
public enum RASCONNSTATE : int32
{
	RASCS_OpenPort = 0,
	RASCS_PortOpened = 1,
	RASCS_ConnectDevice = 2,
	RASCS_DeviceConnected = 3,
	RASCS_AllDevicesConnected = 4,
	RASCS_Authenticate = 5,
	RASCS_AuthNotify = 6,
	RASCS_AuthRetry = 7,
	RASCS_AuthCallback = 8,
	RASCS_AuthChangePassword = 9,
	RASCS_AuthProject = 10,
	RASCS_AuthLinkSpeed = 11,
	RASCS_AuthAck = 12,
	RASCS_ReAuthenticate = 13,
	RASCS_Authenticated = 14,
	RASCS_PrepareForCallback = 15,
	RASCS_WaitForModemReset = 16,
	RASCS_WaitForCallback = 17,
	RASCS_Projected = 18,
	RASCS_StartAuthentication = 19,
	RASCS_CallbackComplete = 20,
	RASCS_LogonNetwork = 21,
	RASCS_SubEntryConnected = 22,
	RASCS_SubEntryDisconnected = 23,
	RASCS_ApplySettings = 24,
	RASCS_Interactive = 4096,
	RASCS_RetryAuthentication = 4097,
	RASCS_CallbackSetByCaller = 4098,
	RASCS_PasswordExpired = 4099,
	RASCS_InvokeEapUI = 4100,
	RASCS_Connected = 8192,
	RASCS_Disconnected = 8193,
}


[AllowDuplicates]
public enum RASCONNSUBSTATE : int32
{
	RASCSS_None = 0,
	RASCSS_Dormant = 1,
	RASCSS_Reconnecting = 2,
	RASCSS_Reconnected = 8192,
}


[AllowDuplicates]
public enum RASPROJECTION : int32
{
	RASP_Amb = 65536,
	RASP_PppNbf = 32831,
	RASP_PppIpx = 32811,
	RASP_PppIp = 32801,
	RASP_PppCcp = 33021,
	RASP_PppLcp = 49185,
	RASP_PppIpv6 = 32855,
}


[AllowDuplicates]
public enum RASPROJECTION_INFO_TYPE : int32
{
	PROJECTION_INFO_TYPE_PPP = 1,
	PROJECTION_INFO_TYPE_IKEv2 = 2,
}


[AllowDuplicates]
public enum IKEV2_ID_PAYLOAD_TYPE : int32
{
	IKEV2_ID_PAYLOAD_TYPE_INVALID = 0,
	IKEV2_ID_PAYLOAD_TYPE_IPV4_ADDR = 1,
	IKEV2_ID_PAYLOAD_TYPE_FQDN = 2,
	IKEV2_ID_PAYLOAD_TYPE_RFC822_ADDR = 3,
	IKEV2_ID_PAYLOAD_TYPE_RESERVED1 = 4,
	IKEV2_ID_PAYLOAD_TYPE_ID_IPV6_ADDR = 5,
	IKEV2_ID_PAYLOAD_TYPE_RESERVED2 = 6,
	IKEV2_ID_PAYLOAD_TYPE_RESERVED3 = 7,
	IKEV2_ID_PAYLOAD_TYPE_RESERVED4 = 8,
	IKEV2_ID_PAYLOAD_TYPE_DER_ASN1_DN = 9,
	IKEV2_ID_PAYLOAD_TYPE_DER_ASN1_GN = 10,
	IKEV2_ID_PAYLOAD_TYPE_KEY_ID = 11,
	IKEV2_ID_PAYLOAD_TYPE_MAX = 12,
}


[AllowDuplicates]
public enum ROUTER_INTERFACE_TYPE : int32
{
	ROUTER_IF_TYPE_CLIENT = 0,
	ROUTER_IF_TYPE_HOME_ROUTER = 1,
	ROUTER_IF_TYPE_FULL_ROUTER = 2,
	ROUTER_IF_TYPE_DEDICATED = 3,
	ROUTER_IF_TYPE_INTERNAL = 4,
	ROUTER_IF_TYPE_LOOPBACK = 5,
	ROUTER_IF_TYPE_TUNNEL1 = 6,
	ROUTER_IF_TYPE_DIALOUT = 7,
	ROUTER_IF_TYPE_MAX = 8,
}


[AllowDuplicates]
public enum ROUTER_CONNECTION_STATE : int32
{
	ROUTER_IF_STATE_UNREACHABLE = 0,
	ROUTER_IF_STATE_DISCONNECTED = 1,
	ROUTER_IF_STATE_CONNECTING = 2,
	ROUTER_IF_STATE_CONNECTED = 3,
}


[AllowDuplicates]
public enum RAS_PORT_CONDITION : int32
{
	RAS_PORT_NON_OPERATIONAL = 0,
	RAS_PORT_DISCONNECTED = 1,
	RAS_PORT_CALLING_BACK = 2,
	RAS_PORT_LISTENING = 3,
	RAS_PORT_AUTHENTICATING = 4,
	RAS_PORT_AUTHENTICATED = 5,
	RAS_PORT_INITIALIZING = 6,
}


[AllowDuplicates]
public enum RAS_HARDWARE_CONDITION : int32
{
	RAS_HARDWARE_OPERATIONAL = 0,
	RAS_HARDWARE_FAILURE = 1,
}


[AllowDuplicates]
public enum RAS_QUARANTINE_STATE : int32
{
	RAS_QUAR_STATE_NORMAL = 0,
	RAS_QUAR_STATE_QUARANTINE = 1,
	RAS_QUAR_STATE_PROBATION = 2,
	RAS_QUAR_STATE_NOT_CAPABLE = 3,
}


[AllowDuplicates]
public enum MPRAPI_OBJECT_TYPE : int32
{
	MPRAPI_OBJECT_TYPE_RAS_CONNECTION_OBJECT = 1,
	MPRAPI_OBJECT_TYPE_MPR_SERVER_OBJECT = 2,
	MPRAPI_OBJECT_TYPE_MPR_SERVER_SET_CONFIG_OBJECT = 3,
	MPRAPI_OBJECT_TYPE_AUTH_VALIDATION_OBJECT = 4,
	MPRAPI_OBJECT_TYPE_UPDATE_CONNECTION_OBJECT = 5,
	MPRAPI_OBJECT_TYPE_IF_CUSTOM_CONFIG_OBJECT = 6,
}


[AllowDuplicates]
public enum MPR_VPN_TS_TYPE : int32
{
	MPR_VPN_TS_IPv4_ADDR_RANGE = 7,
	MPR_VPN_TS_IPv6_ADDR_RANGE = 8,
}


[AllowDuplicates]
public enum MGM_ENUM_TYPES : int32
{
	ANY_SOURCE = 0,
	ALL_SOURCES = 1,
}


[AllowDuplicates]
public enum RTM_EVENT_TYPE : int32
{
	RTM_ENTITY_REGISTERED = 0,
	RTM_ENTITY_DEREGISTERED = 1,
	RTM_ROUTE_EXPIRED = 2,
	RTM_CHANGE_NOTIFICATION = 3,
}

#endregion

#region Function Pointers
public function void RASDIALFUNC(uint32 param0, RASCONNSTATE param1, uint32 param2);

public function void RASDIALFUNC1(HRASCONN param0, uint32 param1, RASCONNSTATE param2, uint32 param3, uint32 param4);

public function uint32 RASDIALFUNC2(uint param0, uint32 param1, HRASCONN param2, uint32 param3, RASCONNSTATE param4, uint32 param5, uint32 param6);

public function BOOL ORASADFUNC(HWND param0, PSTR param1, uint32 param2, uint32* param3);

public function BOOL RASADFUNCA(PSTR param0, PSTR param1, RASADPARAMS* param2, uint32* param3);

public function BOOL RASADFUNCW(PWSTR param0, PWSTR param1, RASADPARAMS* param2, uint32* param3);

public function uint32 PFNRASGETBUFFER(uint8** ppBuffer, uint32* pdwSize);

public function uint32 PFNRASFREEBUFFER(uint8* pBufer);

public function uint32 PFNRASSENDBUFFER(HANDLE hPort, uint8* pBuffer, uint32 dwSize);

public function uint32 PFNRASRECEIVEBUFFER(HANDLE hPort, uint8* pBuffer, uint32* pdwSize, uint32 dwTimeOut, HANDLE hEvent);

public function uint32 PFNRASRETRIEVEBUFFER(HANDLE hPort, uint8* pBuffer, uint32* pdwSize);

public function uint32 RasCustomScriptExecuteFn(HANDLE hPort, PWSTR lpszPhonebook, PWSTR lpszEntryName, PFNRASGETBUFFER pfnRasGetBuffer, PFNRASFREEBUFFER pfnRasFreeBuffer, PFNRASSENDBUFFER pfnRasSendBuffer, PFNRASRECEIVEBUFFER pfnRasReceiveBuffer, PFNRASRETRIEVEBUFFER pfnRasRetrieveBuffer, HWND hWnd, RASDIALPARAMSA* pRasDialParams, void* pvReserved);

public function uint32 PFNRASSETCOMMSETTINGS(HANDLE hPort, RASCOMMSETTINGS* pRasCommSettings, void* pvReserved);

public function uint32 RasCustomHangUpFn(HRASCONN hRasConn);

public function uint32 RasCustomDialFn(HINSTANCE hInstDll, RASDIALEXTENSIONS* lpRasDialExtensions, PWSTR lpszPhonebook, RASDIALPARAMSA* lpRasDialParams, uint32 dwNotifierType, void* lpvNotifier, HRASCONN* lphRasConn, uint32 dwFlags);

public function uint32 RasCustomDeleteEntryNotifyFn(PWSTR lpszPhonebook, PWSTR lpszEntry, uint32 dwFlags);

public function void RASPBDLGFUNCW(uint param0, uint32 param1, PWSTR param2, void* param3);

public function void RASPBDLGFUNCA(uint param0, uint32 param1, PSTR param2, void* param3);

public function BOOL RasCustomDialDlgFn(HINSTANCE hInstDll, uint32 dwFlags, PWSTR lpszPhonebook, PWSTR lpszEntry, PWSTR lpszPhoneNumber, RASDIALDLG* lpInfo, void* pvInfo);

public function BOOL RasCustomEntryDlgFn(HINSTANCE hInstDll, PWSTR lpszPhonebook, PWSTR lpszEntry, RASENTRYDLGA* lpInfo, uint32 dwFlags);

public function uint32 PMPRADMINGETIPADDRESSFORUSER(PWSTR param0, PWSTR param1, uint32* param2, BOOL* param3);

public function void PMPRADMINRELEASEIPADRESS(PWSTR param0, PWSTR param1, uint32* param2);

public function uint32 PMPRADMINGETIPV6ADDRESSFORUSER(PWSTR param0, PWSTR param1, IN6_ADDR* param2, BOOL* param3);

public function void PMPRADMINRELEASEIPV6ADDRESSFORUSER(PWSTR param0, PWSTR param1, IN6_ADDR* param2);

public function BOOL PMPRADMINACCEPTNEWCONNECTION(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1);

public function BOOL PMPRADMINACCEPTNEWCONNECTION2(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1, RAS_CONNECTION_2* param2);

public function BOOL PMPRADMINACCEPTNEWCONNECTION3(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1, RAS_CONNECTION_2* param2, RAS_CONNECTION_3* param3);

public function BOOL PMPRADMINACCEPTNEWLINK(RAS_PORT_0* param0, RAS_PORT_1* param1);

public function void PMPRADMINCONNECTIONHANGUPNOTIFICATION(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1);

public function void PMPRADMINCONNECTIONHANGUPNOTIFICATION2(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1, RAS_CONNECTION_2* param2);

public function void PMPRADMINCONNECTIONHANGUPNOTIFICATION3(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1, RAS_CONNECTION_2* param2, RAS_CONNECTION_3 param3);

public function void PMPRADMINLINKHANGUPNOTIFICATION(RAS_PORT_0* param0, RAS_PORT_1* param1);

public function uint32 PMPRADMINTERMINATEDLL();

public function BOOL PMPRADMINACCEPTREAUTHENTICATION(RAS_CONNECTION_0* param0, RAS_CONNECTION_1* param1, RAS_CONNECTION_2* param2, RAS_CONNECTION_3* param3);

public function BOOL PMPRADMINACCEPTNEWCONNECTIONEX(RAS_CONNECTION_EX* param0);

public function BOOL PMPRADMINACCEPTREAUTHENTICATIONEX(RAS_CONNECTION_EX* param0);

public function BOOL PMPRADMINACCEPTTUNNELENDPOINTCHANGEEX(RAS_CONNECTION_EX* param0);

public function void PMPRADMINCONNECTIONHANGUPNOTIFICATIONEX(RAS_CONNECTION_EX* param0);

public function uint32 PMPRADMINRASVALIDATEPREAUTHENTICATEDCONNECTIONEX(AUTH_VALIDATION_EX* param0);

public function uint32 RASSECURITYPROC();

public function uint32 PMGM_RPF_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32* pdwInIfIndex, uint32* pdwInIfNextHopAddr, uint32* pdwUpStreamNbr, uint32 dwHdrSize, uint8* pbPacketHdr, uint8* pbRoute);

public function uint32 PMGM_CREATION_ALERT_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwInIfIndex, uint32 dwInIfNextHopAddr, uint32 dwIfCount, MGM_IF_ENTRY* pmieOutIfList);

public function uint32 PMGM_PRUNE_ALERT_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwIfIndex, uint32 dwIfNextHopAddr, BOOL bMemberDelete, uint32* pdwTimeout);

public function uint32 PMGM_JOIN_ALERT_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, BOOL bMemberUpdate);

public function uint32 PMGM_WRONG_IF_CALLBACK(uint32 dwSourceAddr, uint32 dwGroupAddr, uint32 dwIfIndex, uint32 dwIfNextHopAddr, uint32 dwHdrSize, uint8* pbPacketHdr);

public function uint32 PMGM_LOCAL_JOIN_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwIfIndex, uint32 dwIfNextHopAddr);

public function uint32 PMGM_LOCAL_LEAVE_CALLBACK(uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwIfIndex, uint32 dwIfNextHopAddr);

public function uint32 PMGM_DISABLE_IGMP_CALLBACK(uint32 dwIfIndex, uint32 dwIfNextHopAddr);

public function uint32 PMGM_ENABLE_IGMP_CALLBACK(uint32 dwIfIndex, uint32 dwIfNextHopAddr);

public function uint32 RTM_EVENT_CALLBACK(int RtmRegHandle, RTM_EVENT_TYPE EventType, void* Context1, void* Context2);

public function void RTM_ENTITY_EXPORT_METHOD(int CallerHandle, int CalleeHandle, RTM_ENTITY_METHOD_INPUT* Input, RTM_ENTITY_METHOD_OUTPUT* Output);

#endregion

#region Structs
[CRepr]
public struct RASIPADDR
{
	public uint8 a;
	public uint8 b;
	public uint8 c;
	public uint8 d;
}

[CRepr]
public struct RASTUNNELENDPOINT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IN_ADDR ipv4;
		public IN6_ADDR ipv6;
	}
	public uint32 dwType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr, Packed(4)]
public struct RASCONNW
{
	public uint32 dwSize;
	public HRASCONN hrasconn;
	public char16[257] szEntryName;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[260] szPhonebook;
	public uint32 dwSubEntry;
	public Guid guidEntry;
	public uint32 dwFlags;
	public LUID luid;
	public Guid guidCorrelationId;
}

[CRepr, Packed(4)]
public struct RASCONNA
{
	public uint32 dwSize;
	public HRASCONN hrasconn;
	public CHAR[257] szEntryName;
	public CHAR[17] szDeviceType;
	public CHAR[129] szDeviceName;
	public CHAR[260] szPhonebook;
	public uint32 dwSubEntry;
	public Guid guidEntry;
	public uint32 dwFlags;
	public LUID luid;
	public Guid guidCorrelationId;
}

[CRepr]
public struct RASCONNSTATUSW
{
	public uint32 dwSize;
	public RASCONNSTATE rasconnstate;
	public uint32 dwError;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[129] szPhoneNumber;
	public RASTUNNELENDPOINT localEndPoint;
	public RASTUNNELENDPOINT remoteEndPoint;
	public RASCONNSUBSTATE rasconnsubstate;
}

[CRepr]
public struct RASCONNSTATUSA
{
	public uint32 dwSize;
	public RASCONNSTATE rasconnstate;
	public uint32 dwError;
	public CHAR[17] szDeviceType;
	public CHAR[129] szDeviceName;
	public CHAR[129] szPhoneNumber;
	public RASTUNNELENDPOINT localEndPoint;
	public RASTUNNELENDPOINT remoteEndPoint;
	public RASCONNSUBSTATE rasconnsubstate;
}

[CRepr, Packed(4)]
public struct RASDIALPARAMSW
{
	public uint32 dwSize;
	public char16[257] szEntryName;
	public char16[129] szPhoneNumber;
	public char16[129] szCallbackNumber;
	public char16[257] szUserName;
	public char16[257] szPassword;
	public char16[16] szDomain;
	public uint32 dwSubEntry;
	public uint dwCallbackId;
	public uint32 dwIfIndex;
	public PWSTR szEncPassword;
}

[CRepr, Packed(4)]
public struct RASDIALPARAMSA
{
	public uint32 dwSize;
	public CHAR[257] szEntryName;
	public CHAR[129] szPhoneNumber;
	public CHAR[129] szCallbackNumber;
	public CHAR[257] szUserName;
	public CHAR[257] szPassword;
	public CHAR[16] szDomain;
	public uint32 dwSubEntry;
	public uint dwCallbackId;
	public uint32 dwIfIndex;
	public PSTR szEncPassword;
}

[CRepr, Packed(4)]
public struct RASEAPINFO
{
	public uint32 dwSizeofEapInfo;
	public uint8* pbEapInfo;
}

[CRepr, Packed(4)]
public struct RASDEVSPECIFICINFO
{
	public uint32 dwSize;
	public uint8* pbDevSpecificInfo;
}

[CRepr, Packed(4)]
public struct RASDIALEXTENSIONS
{
	public uint32 dwSize;
	public uint32 dwfOptions;
	public HWND hwndParent;
	public uint reserved;
	public uint reserved1;
	public RASEAPINFO RasEapInfo;
	public BOOL fSkipPppAuth;
	public RASDEVSPECIFICINFO RasDevSpecificInfo;
}

[CRepr]
public struct RASENTRYNAMEW
{
	public uint32 dwSize;
	public char16[257] szEntryName;
	public uint32 dwFlags;
	public char16[261] szPhonebookPath;
}

[CRepr]
public struct RASENTRYNAMEA
{
	public uint32 dwSize;
	public CHAR[257] szEntryName;
	public uint32 dwFlags;
	public CHAR[261] szPhonebookPath;
}

[CRepr]
public struct RASAMBW
{
	public uint32 dwSize;
	public uint32 dwError;
	public char16[17] szNetBiosError;
	public uint8 bLana;
}

[CRepr]
public struct RASAMBA
{
	public uint32 dwSize;
	public uint32 dwError;
	public CHAR[17] szNetBiosError;
	public uint8 bLana;
}

[CRepr]
public struct RASPPPNBFW
{
	public uint32 dwSize;
	public uint32 dwError;
	public uint32 dwNetBiosError;
	public char16[17] szNetBiosError;
	public char16[17] szWorkstationName;
	public uint8 bLana;
}

[CRepr]
public struct RASPPPNBFA
{
	public uint32 dwSize;
	public uint32 dwError;
	public uint32 dwNetBiosError;
	public CHAR[17] szNetBiosError;
	public CHAR[17] szWorkstationName;
	public uint8 bLana;
}

[CRepr]
public struct RASIPXW
{
	public uint32 dwSize;
	public uint32 dwError;
	public char16[22] szIpxAddress;
}

[CRepr]
public struct RASPPPIPXA
{
	public uint32 dwSize;
	public uint32 dwError;
	public CHAR[22] szIpxAddress;
}

[CRepr]
public struct RASPPPIPW
{
	public uint32 dwSize;
	public uint32 dwError;
	public char16[16] szIpAddress;
	public char16[16] szServerIpAddress;
	public uint32 dwOptions;
	public uint32 dwServerOptions;
}

[CRepr]
public struct RASPPPIPA
{
	public uint32 dwSize;
	public uint32 dwError;
	public CHAR[16] szIpAddress;
	public CHAR[16] szServerIpAddress;
	public uint32 dwOptions;
	public uint32 dwServerOptions;
}

[CRepr]
public struct RASPPPIPV6
{
	public uint32 dwSize;
	public uint32 dwError;
	public uint8[8] bLocalInterfaceIdentifier;
	public uint8[8] bPeerInterfaceIdentifier;
	public uint8[2] bLocalCompressionProtocol;
	public uint8[2] bPeerCompressionProtocol;
}

[CRepr]
public struct RASPPPLCPW
{
	public uint32 dwSize;
	public BOOL fBundled;
	public uint32 dwError;
	public uint32 dwAuthenticationProtocol;
	public uint32 dwAuthenticationData;
	public uint32 dwEapTypeId;
	public uint32 dwServerAuthenticationProtocol;
	public uint32 dwServerAuthenticationData;
	public uint32 dwServerEapTypeId;
	public BOOL fMultilink;
	public uint32 dwTerminateReason;
	public uint32 dwServerTerminateReason;
	public char16[1024] szReplyMessage;
	public uint32 dwOptions;
	public uint32 dwServerOptions;
}

[CRepr]
public struct RASPPPLCPA
{
	public uint32 dwSize;
	public BOOL fBundled;
	public uint32 dwError;
	public uint32 dwAuthenticationProtocol;
	public uint32 dwAuthenticationData;
	public uint32 dwEapTypeId;
	public uint32 dwServerAuthenticationProtocol;
	public uint32 dwServerAuthenticationData;
	public uint32 dwServerEapTypeId;
	public BOOL fMultilink;
	public uint32 dwTerminateReason;
	public uint32 dwServerTerminateReason;
	public CHAR[1024] szReplyMessage;
	public uint32 dwOptions;
	public uint32 dwServerOptions;
}

[CRepr]
public struct RASPPPCCP
{
	public uint32 dwSize;
	public uint32 dwError;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwOptions;
	public uint32 dwServerCompressionAlgorithm;
	public uint32 dwServerOptions;
}

[CRepr]
public struct RASPPP_PROJECTION_INFO
{
	public uint32 dwIPv4NegotiationError;
	public IN_ADDR ipv4Address;
	public IN_ADDR ipv4ServerAddress;
	public uint32 dwIPv4Options;
	public uint32 dwIPv4ServerOptions;
	public uint32 dwIPv6NegotiationError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bServerInterfaceIdentifier;
	public BOOL fBundled;
	public BOOL fMultilink;
	public RASPPP_PROJECTION_INFO_SERVER_AUTH_PROTOCOL dwAuthenticationProtocol;
	public RASPPP_PROJECTION_INFO_SERVER_AUTH_DATA dwAuthenticationData;
	public RASPPP_PROJECTION_INFO_SERVER_AUTH_PROTOCOL dwServerAuthenticationProtocol;
	public RASPPP_PROJECTION_INFO_SERVER_AUTH_DATA dwServerAuthenticationData;
	public uint32 dwEapTypeId;
	public uint32 dwServerEapTypeId;
	public uint32 dwLcpOptions;
	public uint32 dwLcpServerOptions;
	public uint32 dwCcpError;
	public uint32 dwCcpCompressionAlgorithm;
	public uint32 dwCcpServerCompressionAlgorithm;
	public uint32 dwCcpOptions;
	public uint32 dwCcpServerOptions;
}

[CRepr, Packed(4)]
public struct RASIKEV2_PROJECTION_INFO
{
	public uint32 dwIPv4NegotiationError;
	public IN_ADDR ipv4Address;
	public IN_ADDR ipv4ServerAddress;
	public uint32 dwIPv6NegotiationError;
	public IN6_ADDR ipv6Address;
	public IN6_ADDR ipv6ServerAddress;
	public uint32 dwPrefixLength;
	public uint32 dwAuthenticationProtocol;
	public uint32 dwEapTypeId;
	public RASIKEV_PROJECTION_INFO_FLAGS dwFlags;
	public uint32 dwEncryptionMethod;
	public uint32 numIPv4ServerAddresses;
	public IN_ADDR* ipv4ServerAddresses;
	public uint32 numIPv6ServerAddresses;
	public IN6_ADDR* ipv6ServerAddresses;
}

[CRepr]
public struct RAS_PROJECTION_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public RASPPP_PROJECTION_INFO ppp;
		public RASIKEV2_PROJECTION_INFO ikev2;
	}
	public RASAPIVERSION version;
	public RASPROJECTION_INFO_TYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RASDEVINFOW
{
	public uint32 dwSize;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
}

[CRepr]
public struct RASDEVINFOA
{
	public uint32 dwSize;
	public CHAR[17] szDeviceType;
	public CHAR[129] szDeviceName;
}

[CRepr]
public struct RASCTRYINFO
{
	public uint32 dwSize;
	public uint32 dwCountryID;
	public uint32 dwNextCountryID;
	public uint32 dwCountryCode;
	public uint32 dwCountryNameOffset;
}

[CRepr]
public struct RASENTRYA
{
	public uint32 dwSize;
	public uint32 dwfOptions;
	public uint32 dwCountryID;
	public uint32 dwCountryCode;
	public CHAR[11] szAreaCode;
	public CHAR[129] szLocalPhoneNumber;
	public uint32 dwAlternateOffset;
	public RASIPADDR ipaddr;
	public RASIPADDR ipaddrDns;
	public RASIPADDR ipaddrDnsAlt;
	public RASIPADDR ipaddrWins;
	public RASIPADDR ipaddrWinsAlt;
	public uint32 dwFrameSize;
	public uint32 dwfNetProtocols;
	public uint32 dwFramingProtocol;
	public CHAR[260] szScript;
	public CHAR[260] szAutodialDll;
	public CHAR[260] szAutodialFunc;
	public CHAR[17] szDeviceType;
	public CHAR[129] szDeviceName;
	public CHAR[33] szX25PadType;
	public CHAR[201] szX25Address;
	public CHAR[201] szX25Facilities;
	public CHAR[201] szX25UserData;
	public uint32 dwChannels;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwSubEntries;
	public RASENTRY_DIAL_MODE dwDialMode;
	public uint32 dwDialExtraPercent;
	public uint32 dwDialExtraSampleSeconds;
	public uint32 dwHangUpExtraPercent;
	public uint32 dwHangUpExtraSampleSeconds;
	public uint32 dwIdleDisconnectSeconds;
	public uint32 dwType;
	public uint32 dwEncryptionType;
	public uint32 dwCustomAuthKey;
	public Guid guidId;
	public CHAR[260] szCustomDialDll;
	public uint32 dwVpnStrategy;
	public uint32 dwfOptions2;
	public uint32 dwfOptions3;
	public CHAR[256] szDnsSuffix;
	public uint32 dwTcpWindowSize;
	public CHAR[260] szPrerequisitePbk;
	public CHAR[257] szPrerequisiteEntry;
	public uint32 dwRedialCount;
	public uint32 dwRedialPause;
	public IN6_ADDR ipv6addrDns;
	public IN6_ADDR ipv6addrDnsAlt;
	public uint32 dwIPv4InterfaceMetric;
	public uint32 dwIPv6InterfaceMetric;
	public IN6_ADDR ipv6addr;
	public uint32 dwIPv6PrefixLength;
	public uint32 dwNetworkOutageTime;
	public CHAR[257] szIDi;
	public CHAR[257] szIDr;
	public BOOL fIsImsConfig;
	public IKEV2_ID_PAYLOAD_TYPE IdiType;
	public IKEV2_ID_PAYLOAD_TYPE IdrType;
	public BOOL fDisableIKEv2Fragmentation;
}

[CRepr]
public struct RASENTRYW
{
	public uint32 dwSize;
	public uint32 dwfOptions;
	public uint32 dwCountryID;
	public uint32 dwCountryCode;
	public char16[11] szAreaCode;
	public char16[129] szLocalPhoneNumber;
	public uint32 dwAlternateOffset;
	public RASIPADDR ipaddr;
	public RASIPADDR ipaddrDns;
	public RASIPADDR ipaddrDnsAlt;
	public RASIPADDR ipaddrWins;
	public RASIPADDR ipaddrWinsAlt;
	public uint32 dwFrameSize;
	public uint32 dwfNetProtocols;
	public uint32 dwFramingProtocol;
	public char16[260] szScript;
	public char16[260] szAutodialDll;
	public char16[260] szAutodialFunc;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[33] szX25PadType;
	public char16[201] szX25Address;
	public char16[201] szX25Facilities;
	public char16[201] szX25UserData;
	public uint32 dwChannels;
	public uint32 dwReserved1;
	public uint32 dwReserved2;
	public uint32 dwSubEntries;
	public RASENTRY_DIAL_MODE dwDialMode;
	public uint32 dwDialExtraPercent;
	public uint32 dwDialExtraSampleSeconds;
	public uint32 dwHangUpExtraPercent;
	public uint32 dwHangUpExtraSampleSeconds;
	public uint32 dwIdleDisconnectSeconds;
	public uint32 dwType;
	public uint32 dwEncryptionType;
	public uint32 dwCustomAuthKey;
	public Guid guidId;
	public char16[260] szCustomDialDll;
	public uint32 dwVpnStrategy;
	public uint32 dwfOptions2;
	public uint32 dwfOptions3;
	public char16[256] szDnsSuffix;
	public uint32 dwTcpWindowSize;
	public char16[260] szPrerequisitePbk;
	public char16[257] szPrerequisiteEntry;
	public uint32 dwRedialCount;
	public uint32 dwRedialPause;
	public IN6_ADDR ipv6addrDns;
	public IN6_ADDR ipv6addrDnsAlt;
	public uint32 dwIPv4InterfaceMetric;
	public uint32 dwIPv6InterfaceMetric;
	public IN6_ADDR ipv6addr;
	public uint32 dwIPv6PrefixLength;
	public uint32 dwNetworkOutageTime;
	public char16[257] szIDi;
	public char16[257] szIDr;
	public BOOL fIsImsConfig;
	public IKEV2_ID_PAYLOAD_TYPE IdiType;
	public IKEV2_ID_PAYLOAD_TYPE IdrType;
	public BOOL fDisableIKEv2Fragmentation;
}

[CRepr, Packed(4)]
public struct RASADPARAMS
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
}

[CRepr]
public struct RASSUBENTRYA
{
	public uint32 dwSize;
	public uint32 dwfFlags;
	public CHAR[17] szDeviceType;
	public CHAR[129] szDeviceName;
	public CHAR[129] szLocalPhoneNumber;
	public uint32 dwAlternateOffset;
}

[CRepr]
public struct RASSUBENTRYW
{
	public uint32 dwSize;
	public uint32 dwfFlags;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[129] szLocalPhoneNumber;
	public uint32 dwAlternateOffset;
}

[CRepr]
public struct RASCREDENTIALSA
{
	public uint32 dwSize;
	public uint32 dwMask;
	public CHAR[257] szUserName;
	public CHAR[257] szPassword;
	public CHAR[16] szDomain;
}

[CRepr]
public struct RASCREDENTIALSW
{
	public uint32 dwSize;
	public uint32 dwMask;
	public char16[257] szUserName;
	public char16[257] szPassword;
	public char16[16] szDomain;
}

[CRepr]
public struct RASAUTODIALENTRYA
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDialingLocation;
	public CHAR[257] szEntry;
}

[CRepr]
public struct RASAUTODIALENTRYW
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwDialingLocation;
	public char16[257] szEntry;
}

[CRepr]
public struct RASEAPUSERIDENTITYA
{
	public CHAR[257] szUserName;
	public uint32 dwSizeofEapInfo;
	public uint8* pbEapInfo mut => &pbEapInfo_impl;
	private uint8[ANYSIZE_ARRAY] pbEapInfo_impl;
}

[CRepr]
public struct RASEAPUSERIDENTITYW
{
	public char16[257] szUserName;
	public uint32 dwSizeofEapInfo;
	public uint8* pbEapInfo mut => &pbEapInfo_impl;
	private uint8[ANYSIZE_ARRAY] pbEapInfo_impl;
}

[CRepr]
public struct RASCOMMSETTINGS
{
	public uint32 dwSize;
	public uint8 bParity;
	public uint8 bStop;
	public uint8 bByteSize;
	public uint8 bAlign;
}

[CRepr, Packed(4)]
public struct RASCUSTOMSCRIPTEXTENSIONS
{
	public uint32 dwSize;
	public PFNRASSETCOMMSETTINGS pfnRasSetCommSettings;
}

[CRepr]
public struct RAS_STATS
{
	public uint32 dwSize;
	public uint32 dwBytesXmited;
	public uint32 dwBytesRcved;
	public uint32 dwFramesXmited;
	public uint32 dwFramesRcved;
	public uint32 dwCrcErr;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
	public uint32 dwBps;
	public uint32 dwConnectDuration;
}

[CRepr]
public struct RASUPDATECONN
{
	public RASAPIVERSION version;
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwIfIndex;
	public RASTUNNELENDPOINT localEndPoint;
	public RASTUNNELENDPOINT remoteEndPoint;
}

[CRepr]
public struct RASNOUSERW
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwTimeoutMs;
	public char16[257] szUserName;
	public char16[257] szPassword;
	public char16[16] szDomain;
}

[CRepr]
public struct RASNOUSERA
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwTimeoutMs;
	public CHAR[257] szUserName;
	public CHAR[257] szPassword;
	public CHAR[16] szDomain;
}

[CRepr, Packed(4)]
public struct RASPBDLGW
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
	public uint dwCallbackId;
	public RASPBDLGFUNCW pCallback;
	public uint32 dwError;
	public uint reserved;
	public uint reserved2;
}

[CRepr, Packed(4)]
public struct RASPBDLGA
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
	public uint dwCallbackId;
	public RASPBDLGFUNCA pCallback;
	public uint32 dwError;
	public uint reserved;
	public uint reserved2;
}

[CRepr, Packed(4)]
public struct RASENTRYDLGW
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
	public char16[257] szEntry;
	public uint32 dwError;
	public uint reserved;
	public uint reserved2;
}

[CRepr, Packed(4)]
public struct RASENTRYDLGA
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
	public CHAR[257] szEntry;
	public uint32 dwError;
	public uint reserved;
	public uint reserved2;
}

[CRepr, Packed(4)]
public struct RASDIALDLG
{
	public uint32 dwSize;
	public HWND hwndOwner;
	public uint32 dwFlags;
	public int32 xDlg;
	public int32 yDlg;
	public uint32 dwSubEntry;
	public uint32 dwError;
	public uint reserved;
	public uint reserved2;
}

[CRepr]
public struct MPR_INTERFACE_0
{
	public char16[257] wszInterfaceName;
	public HANDLE hInterface;
	public BOOL fEnabled;
	public ROUTER_INTERFACE_TYPE dwIfType;
	public ROUTER_CONNECTION_STATE dwConnectionState;
	public uint32 fUnReachabilityReasons;
	public uint32 dwLastError;
}

[CRepr]
public struct MPR_IPINIP_INTERFACE_0
{
	public char16[257] wszFriendlyName;
	public Guid Guid;
}

[CRepr]
public struct MPR_INTERFACE_1
{
	public char16[257] wszInterfaceName;
	public HANDLE hInterface;
	public BOOL fEnabled;
	public ROUTER_INTERFACE_TYPE dwIfType;
	public ROUTER_CONNECTION_STATE dwConnectionState;
	public uint32 fUnReachabilityReasons;
	public uint32 dwLastError;
	public PWSTR lpwsDialoutHoursRestriction;
}

[CRepr]
public struct MPR_INTERFACE_2
{
	public char16[257] wszInterfaceName;
	public HANDLE hInterface;
	public BOOL fEnabled;
	public ROUTER_INTERFACE_TYPE dwIfType;
	public ROUTER_CONNECTION_STATE dwConnectionState;
	public uint32 fUnReachabilityReasons;
	public uint32 dwLastError;
	public uint32 dwfOptions;
	public char16[129] szLocalPhoneNumber;
	public PWSTR szAlternates;
	public uint32 ipaddr;
	public uint32 ipaddrDns;
	public uint32 ipaddrDnsAlt;
	public uint32 ipaddrWins;
	public uint32 ipaddrWinsAlt;
	public uint32 dwfNetProtocols;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[33] szX25PadType;
	public char16[201] szX25Address;
	public char16[201] szX25Facilities;
	public char16[201] szX25UserData;
	public uint32 dwChannels;
	public uint32 dwSubEntries;
	public MPR_INTERFACE_DIAL_MODE dwDialMode;
	public uint32 dwDialExtraPercent;
	public uint32 dwDialExtraSampleSeconds;
	public uint32 dwHangUpExtraPercent;
	public uint32 dwHangUpExtraSampleSeconds;
	public uint32 dwIdleDisconnectSeconds;
	public uint32 dwType;
	public MPR_ET dwEncryptionType;
	public uint32 dwCustomAuthKey;
	public uint32 dwCustomAuthDataSize;
	public uint8* lpbCustomAuthData;
	public Guid guidId;
	public MPR_VS dwVpnStrategy;
}

[CRepr]
public struct MPR_INTERFACE_3
{
	public char16[257] wszInterfaceName;
	public HANDLE hInterface;
	public BOOL fEnabled;
	public ROUTER_INTERFACE_TYPE dwIfType;
	public ROUTER_CONNECTION_STATE dwConnectionState;
	public uint32 fUnReachabilityReasons;
	public uint32 dwLastError;
	public uint32 dwfOptions;
	public char16[129] szLocalPhoneNumber;
	public PWSTR szAlternates;
	public uint32 ipaddr;
	public uint32 ipaddrDns;
	public uint32 ipaddrDnsAlt;
	public uint32 ipaddrWins;
	public uint32 ipaddrWinsAlt;
	public uint32 dwfNetProtocols;
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[33] szX25PadType;
	public char16[201] szX25Address;
	public char16[201] szX25Facilities;
	public char16[201] szX25UserData;
	public uint32 dwChannels;
	public uint32 dwSubEntries;
	public MPR_INTERFACE_DIAL_MODE dwDialMode;
	public uint32 dwDialExtraPercent;
	public uint32 dwDialExtraSampleSeconds;
	public uint32 dwHangUpExtraPercent;
	public uint32 dwHangUpExtraSampleSeconds;
	public uint32 dwIdleDisconnectSeconds;
	public uint32 dwType;
	public MPR_ET dwEncryptionType;
	public uint32 dwCustomAuthKey;
	public uint32 dwCustomAuthDataSize;
	public uint8* lpbCustomAuthData;
	public Guid guidId;
	public MPR_VS dwVpnStrategy;
	public uint32 AddressCount;
	public IN6_ADDR ipv6addrDns;
	public IN6_ADDR ipv6addrDnsAlt;
	public IN6_ADDR* ipv6addr;
}

[CRepr]
public struct MPR_DEVICE_0
{
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
}

[CRepr]
public struct MPR_DEVICE_1
{
	public char16[17] szDeviceType;
	public char16[129] szDeviceName;
	public char16[129] szLocalPhoneNumber;
	public PWSTR szAlternates;
}

[CRepr]
public struct MPR_CREDENTIALSEX_0
{
	public uint32 dwSize;
	public uint8* lpbCredentialsInfo;
}

[CRepr]
public struct MPR_CREDENTIALSEX_1
{
	public uint32 dwSize;
	public uint8* lpbCredentialsInfo;
}

[CRepr]
public struct MPR_TRANSPORT_0
{
	public uint32 dwTransportId;
	public HANDLE hTransport;
	public char16[41] wszTransportName;
}

[CRepr]
public struct MPR_IFTRANSPORT_0
{
	public uint32 dwTransportId;
	public HANDLE hIfTransport;
	public char16[41] wszIfTransportName;
}

[CRepr]
public struct MPR_SERVER_0
{
	public BOOL fLanOnlyMode;
	public uint32 dwUpTime;
	public uint32 dwTotalPorts;
	public uint32 dwPortsInUse;
}

[CRepr]
public struct MPR_SERVER_1
{
	public uint32 dwNumPptpPorts;
	public uint32 dwPptpPortFlags;
	public uint32 dwNumL2tpPorts;
	public uint32 dwL2tpPortFlags;
}

[CRepr]
public struct MPR_SERVER_2
{
	public uint32 dwNumPptpPorts;
	public uint32 dwPptpPortFlags;
	public uint32 dwNumL2tpPorts;
	public uint32 dwL2tpPortFlags;
	public uint32 dwNumSstpPorts;
	public uint32 dwSstpPortFlags;
}

[CRepr]
public struct RAS_PORT_0
{
	public HANDLE hPort;
	public HANDLE hConnection;
	public RAS_PORT_CONDITION dwPortCondition;
	public uint32 dwTotalNumberOfCalls;
	public uint32 dwConnectDuration;
	public char16[17] wszPortName;
	public char16[17] wszMediaName;
	public char16[129] wszDeviceName;
	public char16[17] wszDeviceType;
}

[CRepr]
public struct RAS_PORT_1
{
	public HANDLE hPort;
	public HANDLE hConnection;
	public RAS_HARDWARE_CONDITION dwHardwareCondition;
	public uint32 dwLineSpeed;
	public uint32 dwBytesXmited;
	public uint32 dwBytesRcved;
	public uint32 dwFramesXmited;
	public uint32 dwFramesRcved;
	public uint32 dwCrcErr;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
}

[CRepr]
public struct RAS_PORT_2
{
	public HANDLE hPort;
	public HANDLE hConnection;
	public uint32 dwConn_State;
	public char16[17] wszPortName;
	public char16[17] wszMediaName;
	public char16[129] wszDeviceName;
	public char16[17] wszDeviceType;
	public RAS_HARDWARE_CONDITION dwHardwareCondition;
	public uint32 dwLineSpeed;
	public uint32 dwCrcErr;
	public uint32 dwSerialOverRunErrs;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
	public uint32 dwTotalErrors;
	public uint64 ullBytesXmited;
	public uint64 ullBytesRcved;
	public uint64 ullFramesXmited;
	public uint64 ullFramesRcved;
	public uint64 ullBytesTxUncompressed;
	public uint64 ullBytesTxCompressed;
	public uint64 ullBytesRcvUncompressed;
	public uint64 ullBytesRcvCompressed;
}

[CRepr]
public struct PPP_NBFCP_INFO
{
	public uint32 dwError;
	public char16[17] wszWksta;
}

[CRepr]
public struct PPP_IPCP_INFO
{
	public uint32 dwError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
}

[CRepr]
public struct PPP_IPCP_INFO2
{
	public uint32 dwError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
	public uint32 dwOptions;
	public uint32 dwRemoteOptions;
}

[CRepr]
public struct PPP_IPXCP_INFO
{
	public uint32 dwError;
	public char16[23] wszAddress;
}

[CRepr]
public struct PPP_ATCP_INFO
{
	public uint32 dwError;
	public char16[33] wszAddress;
}

[CRepr]
public struct PPP_IPV6_CP_INFO
{
	public uint32 dwVersion;
	public uint32 dwSize;
	public uint32 dwError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bRemoteInterfaceIdentifier;
	public uint32 dwOptions;
	public uint32 dwRemoteOptions;
	public uint8[8] bPrefix;
	public uint32 dwPrefixLength;
}

[CRepr]
public struct PPP_INFO
{
	public PPP_NBFCP_INFO nbf;
	public PPP_IPCP_INFO ip;
	public PPP_IPXCP_INFO ipx;
	public PPP_ATCP_INFO at;
}

[CRepr]
public struct PPP_CCP_INFO
{
	public uint32 dwError;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwOptions;
	public uint32 dwRemoteCompressionAlgorithm;
	public uint32 dwRemoteOptions;
}

[CRepr]
public struct PPP_LCP_INFO
{
	public uint32 dwError;
	public PPP_LCP dwAuthenticationProtocol;
	public PPP_LCP_INFO_AUTH_DATA dwAuthenticationData;
	public uint32 dwRemoteAuthenticationProtocol;
	public uint32 dwRemoteAuthenticationData;
	public uint32 dwTerminateReason;
	public uint32 dwRemoteTerminateReason;
	public uint32 dwOptions;
	public uint32 dwRemoteOptions;
	public uint32 dwEapTypeId;
	public uint32 dwRemoteEapTypeId;
}

[CRepr]
public struct PPP_INFO_2
{
	public PPP_NBFCP_INFO nbf;
	public PPP_IPCP_INFO2 ip;
	public PPP_IPXCP_INFO ipx;
	public PPP_ATCP_INFO at;
	public PPP_CCP_INFO ccp;
	public PPP_LCP_INFO lcp;
}

[CRepr]
public struct PPP_INFO_3
{
	public PPP_NBFCP_INFO nbf;
	public PPP_IPCP_INFO2 ip;
	public PPP_IPV6_CP_INFO ipv6;
	public PPP_CCP_INFO ccp;
	public PPP_LCP_INFO lcp;
}

[CRepr]
public struct RAS_CONNECTION_0
{
	public HANDLE hConnection;
	public HANDLE hInterface;
	public uint32 dwConnectDuration;
	public ROUTER_INTERFACE_TYPE dwInterfaceType;
	public RAS_FLAGS dwConnectionFlags;
	public char16[257] wszInterfaceName;
	public char16[257] wszUserName;
	public char16[16] wszLogonDomain;
	public char16[17] wszRemoteComputer;
}

[CRepr]
public struct RAS_CONNECTION_1
{
	public HANDLE hConnection;
	public HANDLE hInterface;
	public PPP_INFO PppInfo;
	public uint32 dwBytesXmited;
	public uint32 dwBytesRcved;
	public uint32 dwFramesXmited;
	public uint32 dwFramesRcved;
	public uint32 dwCrcErr;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
}

[CRepr]
public struct RAS_CONNECTION_2
{
	public HANDLE hConnection;
	public char16[257] wszUserName;
	public ROUTER_INTERFACE_TYPE dwInterfaceType;
	public Guid guid;
	public PPP_INFO_2 PppInfo2;
}

[CRepr]
public struct RAS_CONNECTION_3
{
	public uint32 dwVersion;
	public uint32 dwSize;
	public HANDLE hConnection;
	public char16[257] wszUserName;
	public ROUTER_INTERFACE_TYPE dwInterfaceType;
	public Guid guid;
	public PPP_INFO_3 PppInfo3;
	public RAS_QUARANTINE_STATE rasQuarState;
	public FILETIME timer;
}

[CRepr]
public struct RAS_USER_0
{
	public uint8 bfPrivilege;
	public char16[129] wszPhoneNumber;
}

[CRepr]
public struct RAS_USER_1
{
	public uint8 bfPrivilege;
	public char16[129] wszPhoneNumber;
	public uint8 bfPrivilege2;
}

[CRepr]
public struct MPR_FILTER_0
{
	public BOOL fEnable;
}

[CRepr]
public struct MPRAPI_OBJECT_HEADER
{
	public uint8 revision;
	public uint8 type;
	public uint16 size;
}

[CRepr]
public struct PPP_PROJECTION_INFO
{
	public uint32 dwIPv4NegotiationError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
	public uint32 dwIPv4Options;
	public uint32 dwIPv4RemoteOptions;
	public uint64 IPv4SubInterfaceIndex;
	public uint32 dwIPv6NegotiationError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bRemoteInterfaceIdentifier;
	public uint8[8] bPrefix;
	public uint32 dwPrefixLength;
	public uint64 IPv6SubInterfaceIndex;
	public uint32 dwLcpError;
	public PPP_LCP dwAuthenticationProtocol;
	public PPP_LCP_INFO_AUTH_DATA dwAuthenticationData;
	public PPP_LCP dwRemoteAuthenticationProtocol;
	public PPP_LCP_INFO_AUTH_DATA dwRemoteAuthenticationData;
	public uint32 dwLcpTerminateReason;
	public uint32 dwLcpRemoteTerminateReason;
	public uint32 dwLcpOptions;
	public uint32 dwLcpRemoteOptions;
	public uint32 dwEapTypeId;
	public uint32 dwRemoteEapTypeId;
	public uint32 dwCcpError;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwCcpOptions;
	public uint32 dwRemoteCompressionAlgorithm;
	public uint32 dwCcpRemoteOptions;
}

[CRepr]
public struct PPP_PROJECTION_INFO2
{
	public uint32 dwIPv4NegotiationError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
	public uint32 dwIPv4Options;
	public uint32 dwIPv4RemoteOptions;
	public uint64 IPv4SubInterfaceIndex;
	public uint32 dwIPv6NegotiationError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bRemoteInterfaceIdentifier;
	public uint8[8] bPrefix;
	public uint32 dwPrefixLength;
	public uint64 IPv6SubInterfaceIndex;
	public uint32 dwLcpError;
	public PPP_LCP dwAuthenticationProtocol;
	public PPP_LCP_INFO_AUTH_DATA dwAuthenticationData;
	public PPP_LCP dwRemoteAuthenticationProtocol;
	public PPP_LCP_INFO_AUTH_DATA dwRemoteAuthenticationData;
	public uint32 dwLcpTerminateReason;
	public uint32 dwLcpRemoteTerminateReason;
	public uint32 dwLcpOptions;
	public uint32 dwLcpRemoteOptions;
	public uint32 dwEapTypeId;
	public uint32 dwEmbeddedEAPTypeId;
	public uint32 dwRemoteEapTypeId;
	public uint32 dwCcpError;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwCcpOptions;
	public uint32 dwRemoteCompressionAlgorithm;
	public uint32 dwCcpRemoteOptions;
}

[CRepr]
public struct IKEV2_PROJECTION_INFO
{
	public uint32 dwIPv4NegotiationError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
	public uint64 IPv4SubInterfaceIndex;
	public uint32 dwIPv6NegotiationError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bRemoteInterfaceIdentifier;
	public uint8[8] bPrefix;
	public uint32 dwPrefixLength;
	public uint64 IPv6SubInterfaceIndex;
	public uint32 dwOptions;
	public uint32 dwAuthenticationProtocol;
	public uint32 dwEapTypeId;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwEncryptionMethod;
}

[CRepr]
public struct IKEV2_PROJECTION_INFO2
{
	public uint32 dwIPv4NegotiationError;
	public char16[16] wszAddress;
	public char16[16] wszRemoteAddress;
	public uint64 IPv4SubInterfaceIndex;
	public uint32 dwIPv6NegotiationError;
	public uint8[8] bInterfaceIdentifier;
	public uint8[8] bRemoteInterfaceIdentifier;
	public uint8[8] bPrefix;
	public uint32 dwPrefixLength;
	public uint64 IPv6SubInterfaceIndex;
	public uint32 dwOptions;
	public uint32 dwAuthenticationProtocol;
	public uint32 dwEapTypeId;
	public uint32 dwEmbeddedEAPTypeId;
	public uint32 dwCompressionAlgorithm;
	public uint32 dwEncryptionMethod;
}

[CRepr]
public struct PROJECTION_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PPP_PROJECTION_INFO PppProjectionInfo;
		public IKEV2_PROJECTION_INFO Ikev2ProjectionInfo;
	}
	public uint8 projectionInfoType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct PROJECTION_INFO2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PPP_PROJECTION_INFO2 PppProjectionInfo;
		public IKEV2_PROJECTION_INFO2 Ikev2ProjectionInfo;
	}
	public uint8 projectionInfoType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RAS_CONNECTION_EX
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 dwConnectDuration;
	public ROUTER_INTERFACE_TYPE dwInterfaceType;
	public RAS_FLAGS dwConnectionFlags;
	public char16[257] wszInterfaceName;
	public char16[257] wszUserName;
	public char16[16] wszLogonDomain;
	public char16[17] wszRemoteComputer;
	public Guid guid;
	public RAS_QUARANTINE_STATE rasQuarState;
	public FILETIME probationTime;
	public uint32 dwBytesXmited;
	public uint32 dwBytesRcved;
	public uint32 dwFramesXmited;
	public uint32 dwFramesRcved;
	public uint32 dwCrcErr;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
	public uint32 dwNumSwitchOvers;
	public char16[65] wszRemoteEndpointAddress;
	public char16[65] wszLocalEndpointAddress;
	public PROJECTION_INFO ProjectionInfo;
	public HANDLE hConnection;
	public HANDLE hInterface;
}

[CRepr]
public struct RAS_CONNECTION_4
{
	public uint32 dwConnectDuration;
	public ROUTER_INTERFACE_TYPE dwInterfaceType;
	public RAS_FLAGS dwConnectionFlags;
	public char16[257] wszInterfaceName;
	public char16[257] wszUserName;
	public char16[16] wszLogonDomain;
	public char16[17] wszRemoteComputer;
	public Guid guid;
	public RAS_QUARANTINE_STATE rasQuarState;
	public FILETIME probationTime;
	public FILETIME connectionStartTime;
	public uint64 ullBytesXmited;
	public uint64 ullBytesRcved;
	public uint32 dwFramesXmited;
	public uint32 dwFramesRcved;
	public uint32 dwCrcErr;
	public uint32 dwTimeoutErr;
	public uint32 dwAlignmentErr;
	public uint32 dwHardwareOverrunErr;
	public uint32 dwFramingErr;
	public uint32 dwBufferOverrunErr;
	public uint32 dwCompressionRatioIn;
	public uint32 dwCompressionRatioOut;
	public uint32 dwNumSwitchOvers;
	public char16[65] wszRemoteEndpointAddress;
	public char16[65] wszLocalEndpointAddress;
	public PROJECTION_INFO2 ProjectionInfo;
	public HANDLE hConnection;
	public HANDLE hInterface;
	public uint32 dwDeviceType;
}

[CRepr]
public struct ROUTER_CUSTOM_IKEv2_POLICY0
{
	public uint32 dwIntegrityMethod;
	public uint32 dwEncryptionMethod;
	public uint32 dwCipherTransformConstant;
	public uint32 dwAuthTransformConstant;
	public uint32 dwPfsGroup;
	public uint32 dwDhGroup;
}

[CRepr]
public struct ROUTER_IKEv2_IF_CUSTOM_CONFIG0
{
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSize;
	public CRYPTOAPI_BLOB certificateName;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
}

[CRepr]
public struct MPR_IF_CUSTOMINFOEX0
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 dwFlags;
	public ROUTER_IKEv2_IF_CUSTOM_CONFIG0 customIkev2Config;
}

[CRepr]
public struct MPR_CERT_EKU
{
	public uint32 dwSize;
	public BOOL IsEKUOID;
	public PWSTR pwszEKU;
}

[CRepr]
public struct VPN_TS_IP_ADDRESS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public IN_ADDR v4;
		public IN6_ADDR v6;
	}
	public uint16 Type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MPR_VPN_TRAFFIC_SELECTOR
{
	public MPR_VPN_TS_TYPE type;
	public uint8 protocolId;
	public uint16 portStart;
	public uint16 portEnd;
	public uint16 tsPayloadId;
	public VPN_TS_IP_ADDRESS addrStart;
	public VPN_TS_IP_ADDRESS addrEnd;
}

[CRepr]
public struct MPR_VPN_TRAFFIC_SELECTORS
{
	public uint32 numTsi;
	public uint32 numTsr;
	public MPR_VPN_TRAFFIC_SELECTOR* tsI;
	public MPR_VPN_TRAFFIC_SELECTOR* tsR;
}

[CRepr]
public struct ROUTER_IKEv2_IF_CUSTOM_CONFIG2
{
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSize;
	public CRYPTOAPI_BLOB certificateName;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
	public CRYPTOAPI_BLOB certificateHash;
	public uint32 dwMmSaLifeTime;
	public MPR_VPN_TRAFFIC_SELECTORS vpnTrafficSelectors;
}

[CRepr]
public struct MPR_IF_CUSTOMINFOEX2
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 dwFlags;
	public ROUTER_IKEv2_IF_CUSTOM_CONFIG2 customIkev2Config;
}

[CRepr]
public struct IKEV2_TUNNEL_CONFIG_PARAMS4
{
	public uint32 dwIdleTimeout;
	public uint32 dwNetworkBlackoutTime;
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSizeForRenegotiation;
	public uint32 dwConfigOptions;
	public uint32 dwTotalCertificates;
	public CRYPTOAPI_BLOB* certificateNames;
	public CRYPTOAPI_BLOB machineCertificateName;
	public uint32 dwEncryptionType;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
	public uint32 dwTotalEkus;
	public MPR_CERT_EKU* certificateEKUs;
	public CRYPTOAPI_BLOB machineCertificateHash;
	public uint32 dwMmSaLifeTime;
}

[CRepr]
public struct ROUTER_IKEv2_IF_CUSTOM_CONFIG1
{
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSize;
	public CRYPTOAPI_BLOB certificateName;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
	public CRYPTOAPI_BLOB certificateHash;
}

[CRepr]
public struct MPR_IF_CUSTOMINFOEX1
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 dwFlags;
	public ROUTER_IKEv2_IF_CUSTOM_CONFIG1 customIkev2Config;
}

[CRepr]
public struct IKEV2_TUNNEL_CONFIG_PARAMS3
{
	public uint32 dwIdleTimeout;
	public uint32 dwNetworkBlackoutTime;
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSizeForRenegotiation;
	public uint32 dwConfigOptions;
	public uint32 dwTotalCertificates;
	public CRYPTOAPI_BLOB* certificateNames;
	public CRYPTOAPI_BLOB machineCertificateName;
	public uint32 dwEncryptionType;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
	public uint32 dwTotalEkus;
	public MPR_CERT_EKU* certificateEKUs;
	public CRYPTOAPI_BLOB machineCertificateHash;
}

[CRepr]
public struct IKEV2_TUNNEL_CONFIG_PARAMS2
{
	public uint32 dwIdleTimeout;
	public uint32 dwNetworkBlackoutTime;
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSizeForRenegotiation;
	public uint32 dwConfigOptions;
	public uint32 dwTotalCertificates;
	public CRYPTOAPI_BLOB* certificateNames;
	public CRYPTOAPI_BLOB machineCertificateName;
	public uint32 dwEncryptionType;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
}

[CRepr]
public struct L2TP_TUNNEL_CONFIG_PARAMS2
{
	public uint32 dwIdleTimeout;
	public uint32 dwEncryptionType;
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSizeForRenegotiation;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
	public uint32 dwMmSaLifeTime;
}

[CRepr]
public struct L2TP_TUNNEL_CONFIG_PARAMS1
{
	public uint32 dwIdleTimeout;
	public uint32 dwEncryptionType;
	public uint32 dwSaLifeTime;
	public uint32 dwSaDataSizeForRenegotiation;
	public ROUTER_CUSTOM_IKEv2_POLICY0* customPolicy;
}

[CRepr]
public struct IKEV2_CONFIG_PARAMS
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
	public uint32 dwTunnelConfigParamFlags;
	public IKEV2_TUNNEL_CONFIG_PARAMS4 TunnelConfigParams;
}

[CRepr]
public struct PPTP_CONFIG_PARAMS
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
}

[CRepr]
public struct L2TP_CONFIG_PARAMS1
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
	public uint32 dwTunnelConfigParamFlags;
	public L2TP_TUNNEL_CONFIG_PARAMS2 TunnelConfigParams;
}

[CRepr]
public struct GRE_CONFIG_PARAMS0
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
}

[CRepr]
public struct L2TP_CONFIG_PARAMS0
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
}

[CRepr]
public struct SSTP_CERT_INFO
{
	public BOOL isDefault;
	public CRYPTOAPI_BLOB certBlob;
}

[CRepr]
public struct SSTP_CONFIG_PARAMS
{
	public uint32 dwNumPorts;
	public uint32 dwPortFlags;
	public BOOL isUseHttps;
	public uint32 certAlgorithm;
	public SSTP_CERT_INFO sstpCertDetails;
}

[CRepr]
public struct MPRAPI_TUNNEL_CONFIG_PARAMS0
{
	public IKEV2_CONFIG_PARAMS IkeConfigParams;
	public PPTP_CONFIG_PARAMS PptpConfigParams;
	public L2TP_CONFIG_PARAMS1 L2tpConfigParams;
	public SSTP_CONFIG_PARAMS SstpConfigParams;
}

[CRepr]
public struct MPRAPI_TUNNEL_CONFIG_PARAMS1
{
	public IKEV2_CONFIG_PARAMS IkeConfigParams;
	public PPTP_CONFIG_PARAMS PptpConfigParams;
	public L2TP_CONFIG_PARAMS1 L2tpConfigParams;
	public SSTP_CONFIG_PARAMS SstpConfigParams;
	public GRE_CONFIG_PARAMS0 GREConfigParams;
}

[CRepr]
public struct MPR_SERVER_EX0
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 fLanOnlyMode;
	public uint32 dwUpTime;
	public uint32 dwTotalPorts;
	public uint32 dwPortsInUse;
	public uint32 Reserved;
	public MPRAPI_TUNNEL_CONFIG_PARAMS0 ConfigParams;
}

[CRepr]
public struct MPR_SERVER_EX1
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 fLanOnlyMode;
	public uint32 dwUpTime;
	public uint32 dwTotalPorts;
	public uint32 dwPortsInUse;
	public uint32 Reserved;
	public MPRAPI_TUNNEL_CONFIG_PARAMS1 ConfigParams;
}

[CRepr]
public struct MPR_SERVER_SET_CONFIG_EX0
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 setConfigForProtocols;
	public MPRAPI_TUNNEL_CONFIG_PARAMS0 ConfigParams;
}

[CRepr]
public struct MPR_SERVER_SET_CONFIG_EX1
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 setConfigForProtocols;
	public MPRAPI_TUNNEL_CONFIG_PARAMS1 ConfigParams;
}

[CRepr]
public struct AUTH_VALIDATION_EX
{
	public MPRAPI_OBJECT_HEADER Header;
	public HANDLE hRasConnection;
	public char16[257] wszUserName;
	public char16[16] wszLogonDomain;
	public uint32 AuthInfoSize;
	public uint8* AuthInfo mut => &AuthInfo_impl;
	private uint8[ANYSIZE_ARRAY] AuthInfo_impl;
}

[CRepr]
public struct RAS_UPDATE_CONNECTION
{
	public MPRAPI_OBJECT_HEADER Header;
	public uint32 dwIfIndex;
	public char16[65] wszLocalEndpointAddress;
	public char16[65] wszRemoteEndpointAddress;
}

[CRepr]
public struct MPRAPI_ADMIN_DLL_CALLBACKS
{
	public uint8 revision;
	public PMPRADMINGETIPADDRESSFORUSER lpfnMprAdminGetIpAddressForUser;
	public PMPRADMINRELEASEIPADRESS lpfnMprAdminReleaseIpAddress;
	public PMPRADMINGETIPV6ADDRESSFORUSER lpfnMprAdminGetIpv6AddressForUser;
	public PMPRADMINRELEASEIPV6ADDRESSFORUSER lpfnMprAdminReleaseIpV6AddressForUser;
	public PMPRADMINACCEPTNEWLINK lpfnRasAdminAcceptNewLink;
	public PMPRADMINLINKHANGUPNOTIFICATION lpfnRasAdminLinkHangupNotification;
	public PMPRADMINTERMINATEDLL lpfnRasAdminTerminateDll;
	public PMPRADMINACCEPTNEWCONNECTIONEX lpfnRasAdminAcceptNewConnectionEx;
	public PMPRADMINACCEPTTUNNELENDPOINTCHANGEEX lpfnRasAdminAcceptEndpointChangeEx;
	public PMPRADMINACCEPTREAUTHENTICATIONEX lpfnRasAdminAcceptReauthenticationEx;
	public PMPRADMINCONNECTIONHANGUPNOTIFICATIONEX lpfnRasAdminConnectionHangupNotificationEx;
	public PMPRADMINRASVALIDATEPREAUTHENTICATEDCONNECTIONEX lpfnRASValidatePreAuthenticatedConnectionEx;
}

[CRepr]
public struct SECURITY_MESSAGE
{
	public SECURITY_MESSAGE_MSG_ID dwMsgId;
	public int hPort;
	public uint32 dwError;
	public CHAR[257] UserName;
	public CHAR[16] Domain;
}

[CRepr]
public struct RAS_SECURITY_INFO
{
	public uint32 LastError;
	public uint32 BytesReceived;
	public CHAR[129] DeviceName;
}

[CRepr]
public struct MGM_IF_ENTRY
{
	public uint32 dwIfIndex;
	public uint32 dwIfNextHopAddr;
	public BOOL bIGMP;
	public BOOL bIsEnabled;
}

[CRepr]
public struct ROUTING_PROTOCOL_CONFIG
{
	public uint32 dwCallbackFlags;
	public PMGM_RPF_CALLBACK pfnRpfCallback;
	public PMGM_CREATION_ALERT_CALLBACK pfnCreationAlertCallback;
	public PMGM_PRUNE_ALERT_CALLBACK pfnPruneAlertCallback;
	public PMGM_JOIN_ALERT_CALLBACK pfnJoinAlertCallback;
	public PMGM_WRONG_IF_CALLBACK pfnWrongIfCallback;
	public PMGM_LOCAL_JOIN_CALLBACK pfnLocalJoinCallback;
	public PMGM_LOCAL_LEAVE_CALLBACK pfnLocalLeaveCallback;
	public PMGM_DISABLE_IGMP_CALLBACK pfnDisableIgmpCallback;
	public PMGM_ENABLE_IGMP_CALLBACK pfnEnableIgmpCallback;
}

[CRepr]
public struct SOURCE_GROUP_ENTRY
{
	public uint32 dwSourceAddr;
	public uint32 dwSourceMask;
	public uint32 dwGroupAddr;
	public uint32 dwGroupMask;
}

[CRepr]
public struct RTM_REGN_PROFILE
{
	public uint32 MaxNextHopsInRoute;
	public uint32 MaxHandlesInEnum;
	public uint32 ViewsSupported;
	public uint32 NumberOfViews;
}

[CRepr]
public struct RTM_NET_ADDRESS
{
	public uint16 AddressFamily;
	public uint16 NumBits;
	public uint8[16] AddrBits;
}

[CRepr]
public struct RTM_PREF_INFO
{
	public uint32 Metric;
	public uint32 Preference;
}

[CRepr]
public struct RTM_NEXTHOP_LIST
{
	public uint16 NumNextHops;
	public int* NextHops mut => &NextHops_impl;
	private int[ANYSIZE_ARRAY] NextHops_impl;
}

[CRepr]
public struct RTM_DEST_INFO
{
	[CRepr]
	public struct _Anonymous_e__Struct
	{
		public int32 ViewId;
		public uint32 NumRoutes;
		public int Route;
		public int Owner;
		public uint32 DestFlags;
		public int HoldRoute;
	}
	public int DestHandle;
	public RTM_NET_ADDRESS DestAddress;
	public FILETIME LastChanged;
	public uint32 BelongsToViews;
	public uint32 NumberOfViews;
	public _Anonymous_e__Struct* ViewInfo mut => &ViewInfo_impl;
	private _Anonymous_e__Struct[ANYSIZE_ARRAY] ViewInfo_impl;
}

[CRepr]
public struct RTM_ROUTE_INFO
{
	public int DestHandle;
	public int RouteOwner;
	public int Neighbour;
	public uint8 State;
	public uint8 Flags1;
	public uint16 Flags;
	public RTM_PREF_INFO PrefInfo;
	public uint32 BelongsToViews;
	public void* EntitySpecificInfo;
	public RTM_NEXTHOP_LIST NextHopsList;
}

[CRepr]
public struct RTM_NEXTHOP_INFO
{
	public RTM_NET_ADDRESS NextHopAddress;
	public int NextHopOwner;
	public uint32 InterfaceIndex;
	public uint16 State;
	public uint16 Flags;
	public void* EntitySpecificInfo;
	public int RemoteNextHop;
}

[CRepr]
public struct RTM_ENTITY_ID
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous_e__Struct
		{
			public uint32 EntityProtocolId;
			public uint32 EntityInstanceId;
		}
		public using _Anonymous_e__Struct Anonymous;
		public uint64 EntityId;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct RTM_ENTITY_INFO
{
	public uint16 RtmInstanceId;
	public uint16 AddressFamily;
	public RTM_ENTITY_ID EntityId;
}

[CRepr]
public struct RTM_ENTITY_METHOD_INPUT
{
	public uint32 MethodType;
	public uint32 InputSize;
	public uint8* InputData mut => &InputData_impl;
	private uint8[ANYSIZE_ARRAY] InputData_impl;
}

[CRepr]
public struct RTM_ENTITY_METHOD_OUTPUT
{
	public uint32 MethodType;
	public uint32 MethodStatus;
	public uint32 OutputSize;
	public uint8* OutputData mut => &OutputData_impl;
	private uint8[ANYSIZE_ARRAY] OutputData_impl;
}

[CRepr]
public struct RTM_ENTITY_EXPORT_METHODS
{
	public uint32 NumMethods;
	public RTM_ENTITY_EXPORT_METHOD* Methods mut => &Methods_impl;
	private RTM_ENTITY_EXPORT_METHOD[ANYSIZE_ARRAY] Methods_impl;
}

#endregion

#region Functions
public static
{
	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDialA(RASDIALEXTENSIONS* param0, PSTR param1, RASDIALPARAMSA* param2, uint32 param3, void* param4, HRASCONN* param5);
	public static uint32 RasDial(RASDIALEXTENSIONS* param0, PSTR param1, RASDIALPARAMSA* param2, uint32 param3, void* param4, HRASCONN* param5) => RasDialA(param0, param1, param2, param3, param4, param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDialW(RASDIALEXTENSIONS* param0, PWSTR param1, RASDIALPARAMSW* param2, uint32 param3, void* param4, HRASCONN* param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumConnectionsA(RASCONNA* param0, uint32* param1, uint32* param2);
	public static uint32 RasEnumConnections(RASCONNA* param0, uint32* param1, uint32* param2) => RasEnumConnectionsA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumConnectionsW(RASCONNW* param0, uint32* param1, uint32* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumEntriesA(PSTR param0, PSTR param1, RASENTRYNAMEA* param2, uint32* param3, uint32* param4);
	public static uint32 RasEnumEntries(PSTR param0, PSTR param1, RASENTRYNAMEA* param2, uint32* param3, uint32* param4) => RasEnumEntriesA(param0, param1, param2, param3, param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumEntriesW(PWSTR param0, PWSTR param1, RASENTRYNAMEW* param2, uint32* param3, uint32* param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetConnectStatusA(HRASCONN param0, RASCONNSTATUSA* param1);
	public static uint32 RasGetConnectStatus(HRASCONN param0, RASCONNSTATUSA* param1) => RasGetConnectStatusA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetConnectStatusW(HRASCONN param0, RASCONNSTATUSW* param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetErrorStringA(uint32 ResourceId, uint8* lpszString, uint32 InBufSize);
	public static uint32 RasGetErrorString(uint32 ResourceId, uint8* lpszString, uint32 InBufSize) => RasGetErrorStringA(ResourceId, lpszString, InBufSize);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetErrorStringW(uint32 ResourceId, char16* lpszString, uint32 InBufSize);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasHangUpA(HRASCONN param0);
	public static uint32 RasHangUp(HRASCONN param0) => RasHangUpA(param0);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasHangUpW(HRASCONN param0);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetProjectionInfoA(HRASCONN param0, RASPROJECTION param1, void* param2, uint32* param3);
	public static uint32 RasGetProjectionInfo(HRASCONN param0, RASPROJECTION param1, void* param2, uint32* param3) => RasGetProjectionInfoA(param0, param1, param2, param3);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetProjectionInfoW(HRASCONN param0, RASPROJECTION param1, void* param2, uint32* param3);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasCreatePhonebookEntryA(HWND param0, PSTR param1);
	public static uint32 RasCreatePhonebookEntry(HWND param0, PSTR param1) => RasCreatePhonebookEntryA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasCreatePhonebookEntryW(HWND param0, PWSTR param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEditPhonebookEntryA(HWND param0, PSTR param1, PSTR param2);
	public static uint32 RasEditPhonebookEntry(HWND param0, PSTR param1, PSTR param2) => RasEditPhonebookEntryA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEditPhonebookEntryW(HWND param0, PWSTR param1, PWSTR param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEntryDialParamsA(PSTR param0, RASDIALPARAMSA* param1, BOOL param2);
	public static uint32 RasSetEntryDialParams(PSTR param0, RASDIALPARAMSA* param1, BOOL param2) => RasSetEntryDialParamsA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEntryDialParamsW(PWSTR param0, RASDIALPARAMSW* param1, BOOL param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEntryDialParamsA(PSTR param0, RASDIALPARAMSA* param1, int32* param2);
	public static uint32 RasGetEntryDialParams(PSTR param0, RASDIALPARAMSA* param1, int32* param2) => RasGetEntryDialParamsA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEntryDialParamsW(PWSTR param0, RASDIALPARAMSW* param1, int32* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumDevicesA(RASDEVINFOA* param0, uint32* param1, uint32* param2);
	public static uint32 RasEnumDevices(RASDEVINFOA* param0, uint32* param1, uint32* param2) => RasEnumDevicesA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumDevicesW(RASDEVINFOW* param0, uint32* param1, uint32* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCountryInfoA(RASCTRYINFO* param0, uint32* param1);
	public static uint32 RasGetCountryInfo(RASCTRYINFO* param0, uint32* param1) => RasGetCountryInfoA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCountryInfoW(RASCTRYINFO* param0, uint32* param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEntryPropertiesA(PSTR param0, PSTR param1, RASENTRYA* param2, uint32* param3, uint8* param4, uint32* param5);
	public static uint32 RasGetEntryProperties(PSTR param0, PSTR param1, RASENTRYA* param2, uint32* param3, uint8* param4, uint32* param5) => RasGetEntryPropertiesA(param0, param1, param2, param3, param4, param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEntryPropertiesW(PWSTR param0, PWSTR param1, RASENTRYW* param2, uint32* param3, uint8* param4, uint32* param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEntryPropertiesA(PSTR param0, PSTR param1, RASENTRYA* param2, uint32 param3, uint8* param4, uint32 param5);
	public static uint32 RasSetEntryProperties(PSTR param0, PSTR param1, RASENTRYA* param2, uint32 param3, uint8* param4, uint32 param5) => RasSetEntryPropertiesA(param0, param1, param2, param3, param4, param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEntryPropertiesW(PWSTR param0, PWSTR param1, RASENTRYW* param2, uint32 param3, uint8* param4, uint32 param5);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasRenameEntryA(PSTR param0, PSTR param1, PSTR param2);
	public static uint32 RasRenameEntry(PSTR param0, PSTR param1, PSTR param2) => RasRenameEntryA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasRenameEntryW(PWSTR param0, PWSTR param1, PWSTR param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDeleteEntryA(PSTR param0, PSTR param1);
	public static uint32 RasDeleteEntry(PSTR param0, PSTR param1) => RasDeleteEntryA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDeleteEntryW(PWSTR param0, PWSTR param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasValidateEntryNameA(PSTR param0, PSTR param1);
	public static uint32 RasValidateEntryName(PSTR param0, PSTR param1) => RasValidateEntryNameA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasValidateEntryNameW(PWSTR param0, PWSTR param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasConnectionNotificationA(HRASCONN param0, HANDLE param1, uint32 param2);
	public static uint32 RasConnectionNotification(HRASCONN param0, HANDLE param1, uint32 param2) => RasConnectionNotificationA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasConnectionNotificationW(HRASCONN param0, HANDLE param1, uint32 param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetSubEntryHandleA(HRASCONN param0, uint32 param1, HRASCONN* param2);
	public static uint32 RasGetSubEntryHandle(HRASCONN param0, uint32 param1, HRASCONN* param2) => RasGetSubEntryHandleA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetSubEntryHandleW(HRASCONN param0, uint32 param1, HRASCONN* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCredentialsA(PSTR param0, PSTR param1, RASCREDENTIALSA* param2);
	public static uint32 RasGetCredentials(PSTR param0, PSTR param1, RASCREDENTIALSA* param2) => RasGetCredentialsA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCredentialsW(PWSTR param0, PWSTR param1, RASCREDENTIALSW* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetCredentialsA(PSTR param0, PSTR param1, RASCREDENTIALSA* param2, BOOL param3);
	public static uint32 RasSetCredentials(PSTR param0, PSTR param1, RASCREDENTIALSA* param2, BOOL param3) => RasSetCredentialsA(param0, param1, param2, param3);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetCredentialsW(PWSTR param0, PWSTR param1, RASCREDENTIALSW* param2, BOOL param3);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetSubEntryPropertiesA(PSTR param0, PSTR param1, uint32 param2, RASSUBENTRYA* param3, uint32* param4, uint8* param5, uint32* param6);
	public static uint32 RasGetSubEntryProperties(PSTR param0, PSTR param1, uint32 param2, RASSUBENTRYA* param3, uint32* param4, uint8* param5, uint32* param6) => RasGetSubEntryPropertiesA(param0, param1, param2, param3, param4, param5, param6);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetSubEntryPropertiesW(PWSTR param0, PWSTR param1, uint32 param2, RASSUBENTRYW* param3, uint32* param4, uint8* param5, uint32* param6);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetSubEntryPropertiesA(PSTR param0, PSTR param1, uint32 param2, RASSUBENTRYA* param3, uint32 param4, uint8* param5, uint32 param6);
	public static uint32 RasSetSubEntryProperties(PSTR param0, PSTR param1, uint32 param2, RASSUBENTRYA* param3, uint32 param4, uint8* param5, uint32 param6) => RasSetSubEntryPropertiesA(param0, param1, param2, param3, param4, param5, param6);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetSubEntryPropertiesW(PWSTR param0, PWSTR param1, uint32 param2, RASSUBENTRYW* param3, uint32 param4, uint8* param5, uint32 param6);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialAddressA(PSTR param0, uint32* param1, RASAUTODIALENTRYA* param2, uint32* param3, uint32* param4);
	public static uint32 RasGetAutodialAddress(PSTR param0, uint32* param1, RASAUTODIALENTRYA* param2, uint32* param3, uint32* param4) => RasGetAutodialAddressA(param0, param1, param2, param3, param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialAddressW(PWSTR param0, uint32* param1, RASAUTODIALENTRYW* param2, uint32* param3, uint32* param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialAddressA(PSTR param0, uint32 param1, RASAUTODIALENTRYA* param2, uint32 param3, uint32 param4);
	public static uint32 RasSetAutodialAddress(PSTR param0, uint32 param1, RASAUTODIALENTRYA* param2, uint32 param3, uint32 param4) => RasSetAutodialAddressA(param0, param1, param2, param3, param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialAddressW(PWSTR param0, uint32 param1, RASAUTODIALENTRYW* param2, uint32 param3, uint32 param4);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumAutodialAddressesA(PSTR* lppRasAutodialAddresses, uint32* lpdwcbRasAutodialAddresses, uint32* lpdwcRasAutodialAddresses);
	public static uint32 RasEnumAutodialAddresses(PSTR* lppRasAutodialAddresses, uint32* lpdwcbRasAutodialAddresses, uint32* lpdwcRasAutodialAddresses) => RasEnumAutodialAddressesA(lppRasAutodialAddresses, lpdwcbRasAutodialAddresses, lpdwcRasAutodialAddresses);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasEnumAutodialAddressesW(PWSTR* lppRasAutodialAddresses, uint32* lpdwcbRasAutodialAddresses, uint32* lpdwcRasAutodialAddresses);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialEnableA(uint32 param0, int32* param1);
	public static uint32 RasGetAutodialEnable(uint32 param0, int32* param1) => RasGetAutodialEnableA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialEnableW(uint32 param0, int32* param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialEnableA(uint32 param0, BOOL param1);
	public static uint32 RasSetAutodialEnable(uint32 param0, BOOL param1) => RasSetAutodialEnableA(param0, param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialEnableW(uint32 param0, BOOL param1);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialParamA(uint32 param0, void* param1, uint32* param2);
	public static uint32 RasGetAutodialParam(uint32 param0, void* param1, uint32* param2) => RasGetAutodialParamA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetAutodialParamW(uint32 param0, void* param1, uint32* param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialParamA(uint32 param0, void* param1, uint32 param2);
	public static uint32 RasSetAutodialParam(uint32 param0, void* param1, uint32 param2) => RasSetAutodialParamA(param0, param1, param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetAutodialParamW(uint32 param0, void* param1, uint32 param2);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetPCscf(PWSTR lpszPCscf);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasInvokeEapUI(HRASCONN param0, uint32 param1, RASDIALEXTENSIONS* param2, HWND param3);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetLinkStatistics(HRASCONN hRasConn, uint32 dwSubEntry, RAS_STATS* lpStatistics);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetConnectionStatistics(HRASCONN hRasConn, RAS_STATS* lpStatistics);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasClearLinkStatistics(HRASCONN hRasConn, uint32 dwSubEntry);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasClearConnectionStatistics(HRASCONN hRasConn);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEapUserDataA(HANDLE hToken, PSTR pszPhonebook, PSTR pszEntry, uint8* pbEapData, uint32* pdwSizeofEapData);
	public static uint32 RasGetEapUserData(HANDLE hToken, PSTR pszPhonebook, PSTR pszEntry, uint8* pbEapData, uint32* pdwSizeofEapData) => RasGetEapUserDataA(hToken, pszPhonebook, pszEntry, pbEapData, pdwSizeofEapData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEapUserDataW(HANDLE hToken, PWSTR pszPhonebook, PWSTR pszEntry, uint8* pbEapData, uint32* pdwSizeofEapData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEapUserDataA(HANDLE hToken, PSTR pszPhonebook, PSTR pszEntry, uint8* pbEapData, uint32 dwSizeofEapData);
	public static uint32 RasSetEapUserData(HANDLE hToken, PSTR pszPhonebook, PSTR pszEntry, uint8* pbEapData, uint32 dwSizeofEapData) => RasSetEapUserDataA(hToken, pszPhonebook, pszEntry, pbEapData, dwSizeofEapData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetEapUserDataW(HANDLE hToken, PWSTR pszPhonebook, PWSTR pszEntry, uint8* pbEapData, uint32 dwSizeofEapData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCustomAuthDataA(PSTR pszPhonebook, PSTR pszEntry, uint8* pbCustomAuthData, uint32* pdwSizeofCustomAuthData);
	public static uint32 RasGetCustomAuthData(PSTR pszPhonebook, PSTR pszEntry, uint8* pbCustomAuthData, uint32* pdwSizeofCustomAuthData) => RasGetCustomAuthDataA(pszPhonebook, pszEntry, pbCustomAuthData, pdwSizeofCustomAuthData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetCustomAuthDataW(PWSTR pszPhonebook, PWSTR pszEntry, uint8* pbCustomAuthData, uint32* pdwSizeofCustomAuthData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetCustomAuthDataA(PSTR pszPhonebook, PSTR pszEntry, uint8* pbCustomAuthData, uint32 dwSizeofCustomAuthData);
	public static uint32 RasSetCustomAuthData(PSTR pszPhonebook, PSTR pszEntry, uint8* pbCustomAuthData, uint32 dwSizeofCustomAuthData) => RasSetCustomAuthDataA(pszPhonebook, pszEntry, pbCustomAuthData, dwSizeofCustomAuthData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasSetCustomAuthDataW(PWSTR pszPhonebook, PWSTR pszEntry, uint8* pbCustomAuthData, uint32 dwSizeofCustomAuthData);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEapUserIdentityW(PWSTR pszPhonebook, PWSTR pszEntry, uint32 dwFlags, HWND hwnd, RASEAPUSERIDENTITYW** ppRasEapUserIdentity);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetEapUserIdentityA(PSTR pszPhonebook, PSTR pszEntry, uint32 dwFlags, HWND hwnd, RASEAPUSERIDENTITYA** ppRasEapUserIdentity);
	public static uint32 RasGetEapUserIdentity(PSTR pszPhonebook, PSTR pszEntry, uint32 dwFlags, HWND hwnd, RASEAPUSERIDENTITYA** ppRasEapUserIdentity) => RasGetEapUserIdentityA(pszPhonebook, pszEntry, dwFlags, hwnd, ppRasEapUserIdentity);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RasFreeEapUserIdentityW(RASEAPUSERIDENTITYW* pRasEapUserIdentity);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void RasFreeEapUserIdentityA(RASEAPUSERIDENTITYA* pRasEapUserIdentity);
	public static void RasFreeEapUserIdentity(RASEAPUSERIDENTITYA* pRasEapUserIdentity) => RasFreeEapUserIdentityA(pRasEapUserIdentity);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDeleteSubEntryA(PSTR pszPhonebook, PSTR pszEntry, uint32 dwSubentryId);
	public static uint32 RasDeleteSubEntry(PSTR pszPhonebook, PSTR pszEntry, uint32 dwSubentryId) => RasDeleteSubEntryA(pszPhonebook, pszEntry, dwSubentryId);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasDeleteSubEntryW(PWSTR pszPhonebook, PWSTR pszEntry, uint32 dwSubEntryId);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasUpdateConnection(HRASCONN hrasconn, RASUPDATECONN* lprasupdateconn);

	[Import("RASAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RasGetProjectionInfoEx(HRASCONN hrasconn, RAS_PROJECTION_INFO* pRasProjection, uint32* lpdwSize);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasPhonebookDlgA(PSTR lpszPhonebook, PSTR lpszEntry, RASPBDLGA* lpInfo);
	public static BOOL RasPhonebookDlg(PSTR lpszPhonebook, PSTR lpszEntry, RASPBDLGA* lpInfo) => RasPhonebookDlgA(lpszPhonebook, lpszEntry, lpInfo);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasPhonebookDlgW(PWSTR lpszPhonebook, PWSTR lpszEntry, RASPBDLGW* lpInfo);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasEntryDlgA(PSTR lpszPhonebook, PSTR lpszEntry, RASENTRYDLGA* lpInfo);
	public static BOOL RasEntryDlg(PSTR lpszPhonebook, PSTR lpszEntry, RASENTRYDLGA* lpInfo) => RasEntryDlgA(lpszPhonebook, lpszEntry, lpInfo);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasEntryDlgW(PWSTR lpszPhonebook, PWSTR lpszEntry, RASENTRYDLGW* lpInfo);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasDialDlgA(PSTR lpszPhonebook, PSTR lpszEntry, PSTR lpszPhoneNumber, RASDIALDLG* lpInfo);
	public static BOOL RasDialDlg(PSTR lpszPhonebook, PSTR lpszEntry, PSTR lpszPhoneNumber, RASDIALDLG* lpInfo) => RasDialDlgA(lpszPhonebook, lpszEntry, lpszPhoneNumber, lpInfo);

	[Import("RASDLG.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RasDialDlgW(PWSTR lpszPhonebook, PWSTR lpszEntry, PWSTR lpszPhoneNumber, RASDIALDLG* lpInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionEnumEx(int hRasServer, MPRAPI_OBJECT_HEADER* pObjectHeader, uint32 dwPreferedMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, RAS_CONNECTION_EX** ppRasConn, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionGetInfoEx(int hRasServer, HANDLE hRasConnection, RAS_CONNECTION_EX* pRasConnection);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerGetInfoEx(int hMprServer, MPR_SERVER_EX1* pServerInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerSetInfoEx(int hMprServer, MPR_SERVER_SET_CONFIG_EX1* pServerInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerGetInfoEx(HANDLE hMprConfig, MPR_SERVER_EX1* pServerInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerSetInfoEx(HANDLE hMprConfig, MPR_SERVER_SET_CONFIG_EX1* pSetServerConfig);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminUpdateConnection(int hRasServer, HANDLE hRasConnection, RAS_UPDATE_CONNECTION* pRasUpdateConnection);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminIsServiceInitialized(PWSTR lpwsServerName, BOOL* fIsServiceInitialized);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceSetCustomInfoEx(int hMprServer, HANDLE hInterface, MPR_IF_CUSTOMINFOEX2* pCustomInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceGetCustomInfoEx(int hMprServer, HANDLE hInterface, MPR_IF_CUSTOMINFOEX2* pCustomInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceGetCustomInfoEx(HANDLE hMprConfig, HANDLE hRouterInterface, MPR_IF_CUSTOMINFOEX2* pCustomInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceSetCustomInfoEx(HANDLE hMprConfig, HANDLE hRouterInterface, MPR_IF_CUSTOMINFOEX2* pCustomInfo);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionEnum(int hRasServer, uint32 dwLevel, uint8** lplpbBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminPortEnum(int hRasServer, uint32 dwLevel, HANDLE hRasConnection, uint8** lplpbBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionGetInfo(int hRasServer, uint32 dwLevel, HANDLE hRasConnection, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminPortGetInfo(int hRasServer, uint32 dwLevel, HANDLE hPort, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionClearStats(int hRasServer, HANDLE hRasConnection);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminPortClearStats(int hRasServer, HANDLE hPort);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminPortReset(int hRasServer, HANDLE hPort);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminPortDisconnect(int hRasServer, HANDLE hPort);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminConnectionRemoveQuarantine(HANDLE hRasServer, HANDLE hRasConnection, BOOL fIsIpAddress);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminUserGetInfo(PWSTR lpszServer, PWSTR lpszUser, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminUserSetInfo(PWSTR lpszServer, PWSTR lpszUser, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminSendUserMessage(int hMprServer, HANDLE hConnection, PWSTR lpwszMessage);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminGetPDCServer(PWSTR lpszDomain, PWSTR lpszServer, PWSTR lpszPDCServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL MprAdminIsServiceRunning(PWSTR lpwsServerName);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerConnect(PWSTR lpwsServerName, int* phMprServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MprAdminServerDisconnect(int hMprServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerGetCredentials(int hMprServer, uint32 dwLevel, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerSetCredentials(int hMprServer, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminBufferFree(void* pBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminGetErrorString(uint32 dwError, PWSTR* lplpwsErrorString);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerGetInfo(int hMprServer, uint32 dwLevel, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminServerSetInfo(int hMprServer, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminEstablishDomainRasServer(PWSTR pszDomain, PWSTR pszMachine, BOOL bEnable);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminIsDomainRasServer(PWSTR pszDomain, PWSTR pszMachine, BOOL* pbIsRasServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminTransportCreate(int hMprServer, uint32 dwTransportId, PWSTR lpwsTransportName, uint8* pGlobalInfo, uint32 dwGlobalInfoSize, uint8* pClientInterfaceInfo, uint32 dwClientInterfaceInfoSize, PWSTR lpwsDLLPath);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminTransportSetInfo(int hMprServer, uint32 dwTransportId, uint8* pGlobalInfo, uint32 dwGlobalInfoSize, uint8* pClientInterfaceInfo, uint32 dwClientInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminTransportGetInfo(int hMprServer, uint32 dwTransportId, uint8** ppGlobalInfo, uint32* lpdwGlobalInfoSize, uint8** ppClientInterfaceInfo, uint32* lpdwClientInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminDeviceEnum(int hMprServer, uint32 dwLevel, uint8** lplpbBuffer, uint32* lpdwTotalEntries);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceGetHandle(int hMprServer, PWSTR lpwsInterfaceName, HANDLE* phInterface, BOOL fIncludeClientInterfaces);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceCreate(int hMprServer, uint32 dwLevel, uint8* lpbBuffer, HANDLE* phInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceGetInfo(int hMprServer, HANDLE hInterface, uint32 dwLevel, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceSetInfo(int hMprServer, HANDLE hInterface, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceDelete(int hMprServer, HANDLE hInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceDeviceGetInfo(int hMprServer, HANDLE hInterface, uint32 dwIndex, uint32 dwLevel, uint8** lplpBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceDeviceSetInfo(int hMprServer, HANDLE hInterface, uint32 dwIndex, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceTransportRemove(int hMprServer, HANDLE hInterface, uint32 dwTransportId);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceTransportAdd(int hMprServer, HANDLE hInterface, uint32 dwTransportId, uint8* pInterfaceInfo, uint32 dwInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceTransportGetInfo(int hMprServer, HANDLE hInterface, uint32 dwTransportId, uint8** ppInterfaceInfo, uint32* lpdwInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceTransportSetInfo(int hMprServer, HANDLE hInterface, uint32 dwTransportId, uint8* pInterfaceInfo, uint32 dwInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceEnum(int hMprServer, uint32 dwLevel, uint8** lplpbBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceSetCredentials(PWSTR lpwsServer, PWSTR lpwsInterfaceName, PWSTR lpwsUserName, PWSTR lpwsDomainName, PWSTR lpwsPassword);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceGetCredentials(PWSTR lpwsServer, PWSTR lpwsInterfaceName, PWSTR lpwsUserName, PWSTR lpwsPassword, PWSTR lpwsDomainName);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceSetCredentialsEx(int hMprServer, HANDLE hInterface, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceGetCredentialsEx(int hMprServer, HANDLE hInterface, uint32 dwLevel, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceConnect(int hMprServer, HANDLE hInterface, HANDLE hEvent, BOOL fSynchronous);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceDisconnect(int hMprServer, HANDLE hInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceUpdateRoutes(int hMprServer, HANDLE hInterface, uint32 dwProtocolId, HANDLE hEvent);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceQueryUpdateResult(int hMprServer, HANDLE hInterface, uint32 dwProtocolId, uint32* lpdwUpdateResult);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminInterfaceUpdatePhonebookInfo(int hMprServer, HANDLE hInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminRegisterConnectionNotification(int hMprServer, HANDLE hEventNotification);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminDeregisterConnectionNotification(int hMprServer, HANDLE hEventNotification);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBServerConnect(PWSTR lpwsServerName, int* phMibServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MprAdminMIBServerDisconnect(int hMibServer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntryCreate(int hMibServer, uint32 dwPid, uint32 dwRoutingPid, void* lpEntry, uint32 dwEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntryDelete(int hMibServer, uint32 dwProtocolId, uint32 dwRoutingPid, void* lpEntry, uint32 dwEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntrySet(int hMibServer, uint32 dwProtocolId, uint32 dwRoutingPid, void* lpEntry, uint32 dwEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntryGet(int hMibServer, uint32 dwProtocolId, uint32 dwRoutingPid, void* lpInEntry, uint32 dwInEntrySize, void** lplpOutEntry, uint32* lpOutEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntryGetFirst(int hMibServer, uint32 dwProtocolId, uint32 dwRoutingPid, void* lpInEntry, uint32 dwInEntrySize, void** lplpOutEntry, uint32* lpOutEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBEntryGetNext(int hMibServer, uint32 dwProtocolId, uint32 dwRoutingPid, void* lpInEntry, uint32 dwInEntrySize, void** lplpOutEntry, uint32* lpOutEntrySize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprAdminMIBBufferFree(void* pBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerInstall(uint32 dwLevel, void* pBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerConnect(PWSTR lpwsServerName, HANDLE* phMprConfig);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void MprConfigServerDisconnect(HANDLE hMprConfig);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerRefresh(HANDLE hMprConfig);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigBufferFree(void* pBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerGetInfo(HANDLE hMprConfig, uint32 dwLevel, uint8** lplpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerSetInfo(int hMprServer, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerBackup(HANDLE hMprConfig, PWSTR lpwsPath);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigServerRestore(HANDLE hMprConfig, PWSTR lpwsPath);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportCreate(HANDLE hMprConfig, uint32 dwTransportId, PWSTR lpwsTransportName, uint8* pGlobalInfo, uint32 dwGlobalInfoSize, uint8* pClientInterfaceInfo, uint32 dwClientInterfaceInfoSize, PWSTR lpwsDLLPath, HANDLE* phRouterTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportDelete(HANDLE hMprConfig, HANDLE hRouterTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportGetHandle(HANDLE hMprConfig, uint32 dwTransportId, HANDLE* phRouterTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportSetInfo(HANDLE hMprConfig, HANDLE hRouterTransport, uint8* pGlobalInfo, uint32 dwGlobalInfoSize, uint8* pClientInterfaceInfo, uint32 dwClientInterfaceInfoSize, PWSTR lpwsDLLPath);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportGetInfo(HANDLE hMprConfig, HANDLE hRouterTransport, uint8** ppGlobalInfo, uint32* lpdwGlobalInfoSize, uint8** ppClientInterfaceInfo, uint32* lpdwClientInterfaceInfoSize, PWSTR* lplpwsDLLPath);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigTransportEnum(HANDLE hMprConfig, uint32 dwLevel, uint8** lplpBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceCreate(HANDLE hMprConfig, uint32 dwLevel, uint8* lpbBuffer, HANDLE* phRouterInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceDelete(HANDLE hMprConfig, HANDLE hRouterInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceGetHandle(HANDLE hMprConfig, PWSTR lpwsInterfaceName, HANDLE* phRouterInterface);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceGetInfo(HANDLE hMprConfig, HANDLE hRouterInterface, uint32 dwLevel, uint8** lplpBuffer, uint32* lpdwBufferSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceSetInfo(HANDLE hMprConfig, HANDLE hRouterInterface, uint32 dwLevel, uint8* lpbBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceEnum(HANDLE hMprConfig, uint32 dwLevel, uint8** lplpBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportAdd(HANDLE hMprConfig, HANDLE hRouterInterface, uint32 dwTransportId, PWSTR lpwsTransportName, uint8* pInterfaceInfo, uint32 dwInterfaceInfoSize, HANDLE* phRouterIfTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportRemove(HANDLE hMprConfig, HANDLE hRouterInterface, HANDLE hRouterIfTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportGetHandle(HANDLE hMprConfig, HANDLE hRouterInterface, uint32 dwTransportId, HANDLE* phRouterIfTransport);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportGetInfo(HANDLE hMprConfig, HANDLE hRouterInterface, HANDLE hRouterIfTransport, uint8** ppInterfaceInfo, uint32* lpdwInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportSetInfo(HANDLE hMprConfig, HANDLE hRouterInterface, HANDLE hRouterIfTransport, uint8* pInterfaceInfo, uint32 dwInterfaceInfoSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigInterfaceTransportEnum(HANDLE hMprConfig, HANDLE hRouterInterface, uint32 dwLevel, uint8** lplpBuffer, uint32 dwPrefMaxLen, uint32* lpdwEntriesRead, uint32* lpdwTotalEntries, uint32* lpdwResumeHandle);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigGetFriendlyName(HANDLE hMprConfig, PWSTR pszGuidName, PWSTR pszBuffer, uint32 dwBufferSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigGetGuidName(HANDLE hMprConfig, PWSTR pszFriendlyName, PWSTR pszBuffer, uint32 dwBufferSize);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigFilterGetInfo(HANDLE hMprConfig, uint32 dwLevel, uint32 dwTransportId, uint8* lpBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprConfigFilterSetInfo(HANDLE hMprConfig, uint32 dwLevel, uint32 dwTransportId, uint8* lpBuffer);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoCreate(uint32 dwVersion, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoDelete(void* lpHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoRemoveAll(void* lpHeader, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoDuplicate(void* lpHeader, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoBlockAdd(void* lpHeader, uint32 dwInfoType, uint32 dwItemSize, uint32 dwItemCount, uint8* lpItemData, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoBlockRemove(void* lpHeader, uint32 dwInfoType, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoBlockSet(void* lpHeader, uint32 dwInfoType, uint32 dwItemSize, uint32 dwItemCount, uint8* lpItemData, void** lplpNewHeader);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoBlockFind(void* lpHeader, uint32 dwInfoType, uint32* lpdwItemSize, uint32* lpdwItemCount, uint8** lplpItemData);

	[Import("MPRAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MprInfoBlockQuerySize(void* lpHeader);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmRegisterMProtocol(ROUTING_PROTOCOL_CONFIG* prpiInfo, uint32 dwProtocolId, uint32 dwComponentId, HANDLE* phProtocol);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmDeRegisterMProtocol(HANDLE hProtocol);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmTakeInterfaceOwnership(HANDLE hProtocol, uint32 dwIfIndex, uint32 dwIfNextHopAddr);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmReleaseInterfaceOwnership(HANDLE hProtocol, uint32 dwIfIndex, uint32 dwIfNextHopAddr);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetProtocolOnInterface(uint32 dwIfIndex, uint32 dwIfNextHopAddr, uint32* pdwIfProtocolId, uint32* pdwIfComponentId);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmAddGroupMembershipEntry(HANDLE hProtocol, uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwIfIndex, uint32 dwIfNextHopIPAddr, uint32 dwFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmDeleteGroupMembershipEntry(HANDLE hProtocol, uint32 dwSourceAddr, uint32 dwSourceMask, uint32 dwGroupAddr, uint32 dwGroupMask, uint32 dwIfIndex, uint32 dwIfNextHopIPAddr, uint32 dwFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetMfe(MIB_IPMCAST_MFE* pimm, uint32* pdwBufferSize, uint8* pbBuffer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetFirstMfe(uint32* pdwBufferSize, uint8* pbBuffer, uint32* pdwNumEntries);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetNextMfe(MIB_IPMCAST_MFE* pimmStart, uint32* pdwBufferSize, uint8* pbBuffer, uint32* pdwNumEntries);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetMfeStats(MIB_IPMCAST_MFE* pimm, uint32* pdwBufferSize, uint8* pbBuffer, uint32 dwFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetFirstMfeStats(uint32* pdwBufferSize, uint8* pbBuffer, uint32* pdwNumEntries, uint32 dwFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGetNextMfeStats(MIB_IPMCAST_MFE* pimmStart, uint32* pdwBufferSize, uint8* pbBuffer, uint32* pdwNumEntries, uint32 dwFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGroupEnumerationStart(HANDLE hProtocol, MGM_ENUM_TYPES metEnumType, HANDLE* phEnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGroupEnumerationGetNext(HANDLE hEnum, uint32* pdwBufferSize, uint8* pbBuffer, uint32* pdwNumEntries);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MgmGroupEnumerationEnd(HANDLE hEnum);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmConvertNetAddressToIpv6AddressAndLength(RTM_NET_ADDRESS* pNetAddress, IN6_ADDR* pAddress, uint32* pLength, uint32 dwAddressSize);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmConvertIpv6AddressAndLengthToNetAddress(RTM_NET_ADDRESS* pNetAddress, IN6_ADDR Address, uint32 dwLength, uint32 dwAddressSize);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmRegisterEntity(RTM_ENTITY_INFO* RtmEntityInfo, RTM_ENTITY_EXPORT_METHODS* ExportMethods, RTM_EVENT_CALLBACK EventCallback, BOOL ReserveOpaquePointer, RTM_REGN_PROFILE* RtmRegProfile, int* RtmRegHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeregisterEntity(int RtmRegHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetRegisteredEntities(int RtmRegHandle, uint32* NumEntities, int* EntityHandles, RTM_ENTITY_INFO* EntityInfos);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseEntities(int RtmRegHandle, uint32 NumEntities, int* EntityHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmLockDestination(int RtmRegHandle, int DestHandle, BOOL Exclusive, BOOL LockDest);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetOpaqueInformationPointer(int RtmRegHandle, int DestHandle, void** OpaqueInfoPointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetEntityMethods(int RtmRegHandle, int EntityHandle, uint32* NumMethods, RTM_ENTITY_EXPORT_METHOD* ExptMethods);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmInvokeMethod(int RtmRegHandle, int EntityHandle, RTM_ENTITY_METHOD_INPUT* Input, uint32* OutputSize, RTM_ENTITY_METHOD_OUTPUT* Output);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmBlockMethods(int RtmRegHandle, HANDLE TargetHandle, uint8 TargetType, uint32 BlockingFlag);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetEntityInfo(int RtmRegHandle, int EntityHandle, RTM_ENTITY_INFO* EntityInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetDestInfo(int RtmRegHandle, int DestHandle, uint32 ProtocolId, uint32 TargetViews, RTM_DEST_INFO* DestInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetRouteInfo(int RtmRegHandle, int RouteHandle, RTM_ROUTE_INFO* RouteInfo, RTM_NET_ADDRESS* DestAddress);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetNextHopInfo(int RtmRegHandle, int NextHopHandle, RTM_NEXTHOP_INFO* NextHopInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseEntityInfo(int RtmRegHandle, RTM_ENTITY_INFO* EntityInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseDestInfo(int RtmRegHandle, RTM_DEST_INFO* DestInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseRouteInfo(int RtmRegHandle, RTM_ROUTE_INFO* RouteInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseNextHopInfo(int RtmRegHandle, RTM_NEXTHOP_INFO* NextHopInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmAddRouteToDest(int RtmRegHandle, int* RouteHandle, RTM_NET_ADDRESS* DestAddress, RTM_ROUTE_INFO* RouteInfo, uint32 TimeToLive, int RouteListHandle, uint32 NotifyType, int NotifyHandle, uint32* ChangeFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeleteRouteToDest(int RtmRegHandle, int RouteHandle, uint32* ChangeFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmHoldDestination(int RtmRegHandle, int DestHandle, uint32 TargetViews, uint32 HoldTime);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetRoutePointer(int RtmRegHandle, int RouteHandle, RTM_ROUTE_INFO** RoutePointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmLockRoute(int RtmRegHandle, int RouteHandle, BOOL Exclusive, BOOL LockRoute, RTM_ROUTE_INFO** RoutePointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmUpdateAndUnlockRoute(int RtmRegHandle, int RouteHandle, uint32 TimeToLive, int RouteListHandle, uint32 NotifyType, int NotifyHandle, uint32* ChangeFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetExactMatchDestination(int RtmRegHandle, RTM_NET_ADDRESS* DestAddress, uint32 ProtocolId, uint32 TargetViews, RTM_DEST_INFO* DestInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetMostSpecificDestination(int RtmRegHandle, RTM_NET_ADDRESS* DestAddress, uint32 ProtocolId, uint32 TargetViews, RTM_DEST_INFO* DestInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetLessSpecificDestination(int RtmRegHandle, int DestHandle, uint32 ProtocolId, uint32 TargetViews, RTM_DEST_INFO* DestInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetExactMatchRoute(int RtmRegHandle, RTM_NET_ADDRESS* DestAddress, uint32 MatchingFlags, RTM_ROUTE_INFO* RouteInfo, uint32 InterfaceIndex, uint32 TargetViews, int* RouteHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmIsBestRoute(int RtmRegHandle, int RouteHandle, uint32* BestInViews);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmAddNextHop(int RtmRegHandle, RTM_NEXTHOP_INFO* NextHopInfo, int* NextHopHandle, uint32* ChangeFlags);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmFindNextHop(int RtmRegHandle, RTM_NEXTHOP_INFO* NextHopInfo, int* NextHopHandle, RTM_NEXTHOP_INFO** NextHopPointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeleteNextHop(int RtmRegHandle, int NextHopHandle, RTM_NEXTHOP_INFO* NextHopInfo);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetNextHopPointer(int RtmRegHandle, int NextHopHandle, RTM_NEXTHOP_INFO** NextHopPointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmLockNextHop(int RtmRegHandle, int NextHopHandle, BOOL Exclusive, BOOL LockNextHop, RTM_NEXTHOP_INFO** NextHopPointer);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmCreateDestEnum(int RtmRegHandle, uint32 TargetViews, uint32 EnumFlags, RTM_NET_ADDRESS* NetAddress, uint32 ProtocolId, int* RtmEnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetEnumDests(int RtmRegHandle, int EnumHandle, uint32* NumDests, RTM_DEST_INFO* DestInfos);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseDests(int RtmRegHandle, uint32 NumDests, RTM_DEST_INFO* DestInfos);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmCreateRouteEnum(int RtmRegHandle, int DestHandle, uint32 TargetViews, uint32 EnumFlags, RTM_NET_ADDRESS* StartDest, uint32 MatchingFlags, RTM_ROUTE_INFO* CriteriaRoute, uint32 CriteriaInterface, int* RtmEnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetEnumRoutes(int RtmRegHandle, int EnumHandle, uint32* NumRoutes, int* RouteHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseRoutes(int RtmRegHandle, uint32 NumRoutes, int* RouteHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmCreateNextHopEnum(int RtmRegHandle, uint32 EnumFlags, RTM_NET_ADDRESS* NetAddress, int* RtmEnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetEnumNextHops(int RtmRegHandle, int EnumHandle, uint32* NumNextHops, int* NextHopHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseNextHops(int RtmRegHandle, uint32 NumNextHops, int* NextHopHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeleteEnumHandle(int RtmRegHandle, int EnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmRegisterForChangeNotification(int RtmRegHandle, uint32 TargetViews, uint32 NotifyFlags, void* NotifyContext, int* NotifyHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetChangedDests(int RtmRegHandle, int NotifyHandle, uint32* NumDests, RTM_DEST_INFO* ChangedDests);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReleaseChangedDests(int RtmRegHandle, int NotifyHandle, uint32 NumDests, RTM_DEST_INFO* ChangedDests);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmIgnoreChangedDests(int RtmRegHandle, int NotifyHandle, uint32 NumDests, int* ChangedDests);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetChangeStatus(int RtmRegHandle, int NotifyHandle, int DestHandle, BOOL* ChangeStatus);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmMarkDestForChangeNotification(int RtmRegHandle, int NotifyHandle, int DestHandle, BOOL MarkDest);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmIsMarkedForChangeNotification(int RtmRegHandle, int NotifyHandle, int DestHandle, BOOL* DestMarked);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeregisterFromChangeNotification(int RtmRegHandle, int NotifyHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmCreateRouteList(int RtmRegHandle, int* RouteListHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmInsertInRouteList(int RtmRegHandle, int RouteListHandle, uint32 NumRoutes, int* RouteHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmCreateRouteListEnum(int RtmRegHandle, int RouteListHandle, int* RtmEnumHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmGetListEnumRoutes(int RtmRegHandle, int EnumHandle, uint32* NumRoutes, int* RouteHandles);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmDeleteRouteList(int RtmRegHandle, int RouteListHandle);

	[Import("rtm.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RtmReferenceHandles(int RtmRegHandle, uint32 NumHandles, HANDLE* RtmHandles);

}
#endregion
