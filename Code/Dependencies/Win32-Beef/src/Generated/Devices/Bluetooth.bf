using Win32.Foundation;
using System;

namespace Win32.Devices.Bluetooth;

#region Constants
public static
{
	public const uint32 BTH_MAJORVERSION = 2;
	public const uint32 BTH_MINORVERSION = 1;
	public const Guid GUID_BTHPORT_DEVICE_INTERFACE = .(0x0850302a, 0xb344, 0x4fda, 0x9b, 0xe9, 0x90, 0x57, 0x6b, 0x8d, 0x46, 0xf0);
	public const Guid GUID_BTH_RFCOMM_SERVICE_DEVICE_INTERFACE = .(0xb142fc3e, 0xfa4e, 0x460b, 0x8a, 0xbc, 0x07, 0x2b, 0x62, 0x8b, 0x3c, 0x70);
	public const Guid GUID_BLUETOOTH_RADIO_IN_RANGE = .(0xea3b5b82, 0x26ee, 0x450e, 0xb0, 0xd8, 0xd2, 0x6f, 0xe3, 0x0a, 0x38, 0x69);
	public const Guid GUID_BLUETOOTH_RADIO_OUT_OF_RANGE = .(0xe28867c9, 0xc2aa, 0x4ced, 0xb9, 0x69, 0x45, 0x70, 0x86, 0x60, 0x37, 0xc4);
	public const Guid GUID_BLUETOOTH_L2CAP_EVENT = .(0x7eae4030, 0xb709, 0x4aa8, 0xac, 0x55, 0xe9, 0x53, 0x82, 0x9c, 0x9d, 0xaa);
	public const Guid GUID_BLUETOOTH_HCI_EVENT = .(0xfc240062, 0x1541, 0x49be, 0xb4, 0x63, 0x84, 0xc4, 0xdc, 0xd7, 0xbf, 0x7f);
	public const Guid GUID_BLUETOOTH_AUTHENTICATION_REQUEST = .(0x5dc9136d, 0x996c, 0x46db, 0x84, 0xf5, 0x32, 0xc0, 0xa3, 0xf4, 0x73, 0x52);
	public const Guid GUID_BLUETOOTH_KEYPRESS_EVENT = .(0xd668dfcd, 0x0f4e, 0x4efc, 0xbf, 0xe0, 0x39, 0x2e, 0xee, 0xc5, 0x10, 0x9c);
	public const Guid GUID_BLUETOOTH_HCI_VENDOR_EVENT = .(0x547247e6, 0x45bb, 0x4c33, 0xaf, 0x8c, 0xc0, 0x0e, 0xfe, 0x15, 0xa7, 0x1d);
	public const Guid Bluetooth_Base_UUID = .(0x00000000, 0x0000, 0x1000, 0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb);
	public const uint32 SDP_PROTOCOL_UUID16 = 1;
	public const uint32 UDP_PROTOCOL_UUID16 = 2;
	public const uint32 RFCOMM_PROTOCOL_UUID16 = 3;
	public const uint32 TCP_PROTOCOL_UUID16 = 4;
	public const uint32 TCSBIN_PROTOCOL_UUID16 = 5;
	public const uint32 TCSAT_PROTOCOL_UUID16 = 6;
	public const uint32 ATT_PROTOCOL_UUID16 = 7;
	public const uint32 OBEX_PROTOCOL_UUID16 = 8;
	public const uint32 IP_PROTOCOL_UUID16 = 9;
	public const uint32 FTP_PROTOCOL_UUID16 = 10;
	public const uint32 HTTP_PROTOCOL_UUID16 = 12;
	public const uint32 WSP_PROTOCOL_UUID16 = 14;
	public const uint32 BNEP_PROTOCOL_UUID16 = 15;
	public const uint32 UPNP_PROTOCOL_UUID16 = 16;
	public const uint32 HID_PROTOCOL_UUID16 = 17;
	public const uint32 HCCC_PROTOCOL_UUID16 = 18;
	public const uint32 HCDC_PROTOCOL_UUID16 = 20;
	public const uint32 HCN_PROTOCOL_UUID16 = 22;
	public const uint32 AVCTP_PROTOCOL_UUID16 = 23;
	public const uint32 AVDTP_PROTOCOL_UUID16 = 25;
	public const uint32 CMPT_PROTOCOL_UUID16 = 27;
	public const uint32 UDI_C_PLANE_PROTOCOL_UUID16 = 29;
	public const uint32 L2CAP_PROTOCOL_UUID16 = 256;
	public const uint32 ServiceDiscoveryServerServiceClassID_UUID16 = 4096;
	public const uint32 BrowseGroupDescriptorServiceClassID_UUID16 = 4097;
	public const uint32 PublicBrowseGroupServiceClassID_UUID16 = 4098;
	public const uint32 SerialPortServiceClassID_UUID16 = 4353;
	public const uint32 LANAccessUsingPPPServiceClassID_UUID16 = 4354;
	public const uint32 DialupNetworkingServiceClassID_UUID16 = 4355;
	public const uint32 IrMCSyncServiceClassID_UUID16 = 4356;
	public const uint32 OBEXObjectPushServiceClassID_UUID16 = 4357;
	public const uint32 OBEXFileTransferServiceClassID_UUID16 = 4358;
	public const uint32 IrMcSyncCommandServiceClassID_UUID16 = 4359;
	public const uint32 HeadsetServiceClassID_UUID16 = 4360;
	public const uint32 CordlessTelephonyServiceClassID_UUID16 = 4361;
	public const uint32 AudioSourceServiceClassID_UUID16 = 4362;
	public const uint32 AudioSinkServiceClassID_UUID16 = 4363;
	public const uint32 AVRemoteControlTargetServiceClassID_UUID16 = 4364;
	public const uint32 AVRemoteControlServiceClassID_UUID16 = 4366;
	public const uint32 AVRemoteControlControllerServiceClass_UUID16 = 4367;
	public const uint32 IntercomServiceClassID_UUID16 = 4368;
	public const uint32 FaxServiceClassID_UUID16 = 4369;
	public const uint32 HeadsetAudioGatewayServiceClassID_UUID16 = 4370;
	public const uint32 WAPServiceClassID_UUID16 = 4371;
	public const uint32 WAPClientServiceClassID_UUID16 = 4372;
	public const uint32 PANUServiceClassID_UUID16 = 4373;
	public const uint32 NAPServiceClassID_UUID16 = 4374;
	public const uint32 GNServiceClassID_UUID16 = 4375;
	public const uint32 DirectPrintingServiceClassID_UUID16 = 4376;
	public const uint32 ReferencePrintingServiceClassID_UUID16 = 4377;
	public const uint32 ImagingResponderServiceClassID_UUID16 = 4379;
	public const uint32 ImagingAutomaticArchiveServiceClassID_UUID16 = 4380;
	public const uint32 ImagingReferenceObjectsServiceClassID_UUID16 = 4381;
	public const uint32 HandsfreeServiceClassID_UUID16 = 4382;
	public const uint32 HandsfreeAudioGatewayServiceClassID_UUID16 = 4383;
	public const uint32 DirectPrintingReferenceObjectsServiceClassID_UUID16 = 4384;
	public const uint32 ReflectsUIServiceClassID_UUID16 = 4385;
	public const uint32 PrintingStatusServiceClassID_UUID16 = 4387;
	public const uint32 HumanInterfaceDeviceServiceClassID_UUID16 = 4388;
	public const uint32 HCRPrintServiceClassID_UUID16 = 4390;
	public const uint32 HCRScanServiceClassID_UUID16 = 4391;
	public const uint32 CommonISDNAccessServiceClassID_UUID16 = 4392;
	public const uint32 VideoConferencingGWServiceClassID_UUID16 = 4393;
	public const uint32 UDIMTServiceClassID_UUID16 = 4394;
	public const uint32 UDITAServiceClassID_UUID16 = 4395;
	public const uint32 AudioVideoServiceClassID_UUID16 = 4396;
	public const uint32 SimAccessServiceClassID_UUID16 = 4397;
	public const uint32 PhonebookAccessPceServiceClassID_UUID16 = 4398;
	public const uint32 PhonebookAccessPseServiceClassID_UUID16 = 4399;
	public const uint32 HeadsetHSServiceClassID_UUID16 = 4401;
	public const uint32 MessageAccessServerServiceClassID_UUID16 = 4402;
	public const uint32 MessageNotificationServerServiceClassID_UUID16 = 4403;
	public const uint32 GNSSServerServiceClassID_UUID16 = 4406;
	public const uint32 ThreeDimensionalDisplayServiceClassID_UUID16 = 4407;
	public const uint32 ThreeDimensionalGlassesServiceClassID_UUID16 = 4408;
	public const uint32 MPSServiceClassID_UUID16 = 4411;
	public const uint32 CTNAccessServiceClassID_UUID16 = 4412;
	public const uint32 CTNNotificationServiceClassID_UUID16 = 4413;
	public const uint32 PnPInformationServiceClassID_UUID16 = 4608;
	public const uint32 GenericNetworkingServiceClassID_UUID16 = 4609;
	public const uint32 GenericFileTransferServiceClassID_UUID16 = 4610;
	public const uint32 GenericAudioServiceClassID_UUID16 = 4611;
	public const uint32 GenericTelephonyServiceClassID_UUID16 = 4612;
	public const uint32 UPnpServiceClassID_UUID16 = 4613;
	public const uint32 UPnpIpServiceClassID_UUID16 = 4614;
	public const uint32 ESdpUpnpIpPanServiceClassID_UUID16 = 4864;
	public const uint32 ESdpUpnpIpLapServiceClassID_UUID16 = 4865;
	public const uint32 ESdpUpnpL2capServiceClassID_UUID16 = 4866;
	public const uint32 VideoSourceServiceClassID_UUID16 = 4867;
	public const uint32 VideoSinkServiceClassID_UUID16 = 4868;
	public const uint32 HealthDeviceProfileSourceServiceClassID_UUID16 = 5121;
	public const uint32 HealthDeviceProfileSinkServiceClassID_UUID16 = 5122;
	public const uint32 AdvancedAudioDistributionProfileID_UUID16 = 4365;
	public const uint32 ImagingServiceProfileID_UUID16 = 4378;
	public const uint32 BasicPrintingProfileID_UUID16 = 4386;
	public const uint32 HardcopyCableReplacementProfileID_UUID16 = 4389;
	public const uint32 PhonebookAccessProfileID_UUID16 = 4400;
	public const uint32 MessageAccessProfileID_UUID16 = 4404;
	public const uint32 GNSSProfileID_UUID16 = 4405;
	public const uint32 ThreeDimensionalSynchronizationProfileID_UUID16 = 4409;
	public const uint32 MPSProfileID_UUID16 = 4410;
	public const uint32 CTNProfileID_UUID16 = 4414;
	public const uint32 VideoDistributionProfileID_UUID16 = 4869;
	public const uint32 HealthDeviceProfileID_UUID16 = 5120;
	public const uint32 VideoConferencingServiceClassID_UUID16 = 4367;
	public const uint32 CommonISDNAccessServiceClass_UUID16 = 4392;
	public const uint32 VideoConferencingGWServiceClass_UUID16 = 4393;
	public const uint32 UDIMTServiceClass_UUID16 = 4394;
	public const uint32 UDITAServiceClass_UUID16 = 4395;
	public const uint32 AudioVideoServiceClass_UUID16 = 4396;
	public const uint32 CordlessServiceClassID_UUID16 = 4361;
	public const uint32 AudioSinkSourceServiceClassID_UUID16 = 4363;
	public const uint32 AdvancedAudioDistributionServiceClassID_UUID16 = 4365;
	public const uint32 ImagingServiceClassID_UUID16 = 4378;
	public const uint32 BasicPrintingServiceClassID_UUID16 = 4386;
	public const uint32 HardcopyCableReplacementServiceClassID_UUID16 = 4389;
	public const uint32 BTH_MAX_NAME_SIZE = 248;
	public const uint32 BTH_MAX_PIN_SIZE = 16;
	public const uint32 BTH_LINK_KEY_LENGTH = 16;
	public const uint32 BTH_MFG_ERICSSON = 0;
	public const uint32 BTH_MFG_NOKIA = 1;
	public const uint32 BTH_MFG_INTEL = 2;
	public const uint32 BTH_MFG_IBM = 3;
	public const uint32 BTH_MFG_TOSHIBA = 4;
	public const uint32 BTH_MFG_3COM = 5;
	public const uint32 BTH_MFG_MICROSOFT = 6;
	public const uint32 BTH_MFG_LUCENT = 7;
	public const uint32 BTH_MFG_MOTOROLA = 8;
	public const uint32 BTH_MFG_INFINEON = 9;
	public const uint32 BTH_MFG_CSR = 10;
	public const uint32 BTH_MFG_SILICONWAVE = 11;
	public const uint32 BTH_MFG_DIGIANSWER = 12;
	public const uint32 BTH_MFG_TI = 13;
	public const uint32 BTH_MFG_PARTHUS = 14;
	public const uint32 BTH_MFG_BROADCOM = 15;
	public const uint32 BTH_MFG_MITEL = 16;
	public const uint32 BTH_MFG_WIDCOMM = 17;
	public const uint32 BTH_MFG_ZEEVO = 18;
	public const uint32 BTH_MFG_ATMEL = 19;
	public const uint32 BTH_MFG_MITSIBUSHI = 20;
	public const uint32 BTH_MFG_RTX_TELECOM = 21;
	public const uint32 BTH_MFG_KC_TECHNOLOGY = 22;
	public const uint32 BTH_MFG_NEWLOGIC = 23;
	public const uint32 BTH_MFG_TRANSILICA = 24;
	public const uint32 BTH_MFG_ROHDE_SCHWARZ = 25;
	public const uint32 BTH_MFG_TTPCOM = 26;
	public const uint32 BTH_MFG_SIGNIA = 27;
	public const uint32 BTH_MFG_CONEXANT = 28;
	public const uint32 BTH_MFG_QUALCOMM = 29;
	public const uint32 BTH_MFG_INVENTEL = 30;
	public const uint32 BTH_MFG_AVM_BERLIN = 31;
	public const uint32 BTH_MFG_BANDSPEED = 32;
	public const uint32 BTH_MFG_MANSELLA = 33;
	public const uint32 BTH_MFG_NEC = 34;
	public const uint32 BTH_MFG_WAVEPLUS_TECHNOLOGY_CO = 35;
	public const uint32 BTH_MFG_ALCATEL = 36;
	public const uint32 BTH_MFG_PHILIPS_SEMICONDUCTOR = 37;
	public const uint32 BTH_MFG_C_TECHNOLOGIES = 38;
	public const uint32 BTH_MFG_OPEN_INTERFACE = 39;
	public const uint32 BTH_MFG_RF_MICRO_DEVICES = 40;
	public const uint32 BTH_MFG_HITACHI = 41;
	public const uint32 BTH_MFG_SYMBOL_TECHNOLOGIES = 42;
	public const uint32 BTH_MFG_TENOVIS = 43;
	public const uint32 BTH_MFG_MACRONIX_INTERNATIONAL = 44;
	public const uint32 BTH_MFG_MARVELL = 72;
	public const uint32 BTH_MFG_APPLE = 76;
	public const uint32 BTH_MFG_NORDIC_SEMICONDUCTORS_ASA = 89;
	public const uint32 BTH_MFG_ARUBA_NETWORKS = 283;
	public const uint32 BTH_MFG_INTERNAL_USE = 65535;
	public const uint32 SAP_BIT_OFFSET = 0;
	public const uint32 COD_FORMAT_BIT_OFFSET = 0;
	public const uint32 COD_MINOR_BIT_OFFSET = 2;
	public const uint32 COD_FORMAT_MASK = 3;
	public const uint32 COD_MINOR_MASK = 252;
	public const uint32 COD_MAJOR_MASK = 7936;
	public const uint32 COD_SERVICE_MASK = 16769024;
	public const uint32 COD_VERSION = 0;
	public const uint32 COD_SERVICE_LIMITED = 1;
	public const uint32 COD_SERVICE_POSITIONING = 8;
	public const uint32 COD_SERVICE_NETWORKING = 16;
	public const uint32 COD_SERVICE_RENDERING = 32;
	public const uint32 COD_SERVICE_CAPTURING = 64;
	public const uint32 COD_SERVICE_OBJECT_XFER = 128;
	public const uint32 COD_SERVICE_AUDIO = 256;
	public const uint32 COD_SERVICE_TELEPHONY = 512;
	public const uint32 COD_SERVICE_INFORMATION = 1024;
	public const uint32 COD_SERVICE_MAX_COUNT = 9;
	public const uint32 COD_MAJOR_MISCELLANEOUS = 0;
	public const uint32 COD_MAJOR_COMPUTER = 1;
	public const uint32 COD_MAJOR_PHONE = 2;
	public const uint32 COD_MAJOR_LAN_ACCESS = 3;
	public const uint32 COD_MAJOR_AUDIO = 4;
	public const uint32 COD_MAJOR_PERIPHERAL = 5;
	public const uint32 COD_MAJOR_IMAGING = 6;
	public const uint32 COD_MAJOR_WEARABLE = 7;
	public const uint32 COD_MAJOR_TOY = 8;
	public const uint32 COD_MAJOR_HEALTH = 9;
	public const uint32 COD_MAJOR_UNCLASSIFIED = 31;
	public const uint32 COD_COMPUTER_MINOR_UNCLASSIFIED = 0;
	public const uint32 COD_COMPUTER_MINOR_DESKTOP = 1;
	public const uint32 COD_COMPUTER_MINOR_SERVER = 2;
	public const uint32 COD_COMPUTER_MINOR_LAPTOP = 3;
	public const uint32 COD_COMPUTER_MINOR_HANDHELD = 4;
	public const uint32 COD_COMPUTER_MINOR_PALM = 5;
	public const uint32 COD_COMPUTER_MINOR_WEARABLE = 6;
	public const uint32 COD_PHONE_MINOR_UNCLASSIFIED = 0;
	public const uint32 COD_PHONE_MINOR_CELLULAR = 1;
	public const uint32 COD_PHONE_MINOR_CORDLESS = 2;
	public const uint32 COD_PHONE_MINOR_SMART = 3;
	public const uint32 COD_PHONE_MINOR_WIRED_MODEM = 4;
	public const uint32 COD_AUDIO_MINOR_UNCLASSIFIED = 0;
	public const uint32 COD_AUDIO_MINOR_HEADSET = 1;
	public const uint32 COD_AUDIO_MINOR_HANDS_FREE = 2;
	public const uint32 COD_AUDIO_MINOR_HEADSET_HANDS_FREE = 3;
	public const uint32 COD_AUDIO_MINOR_MICROPHONE = 4;
	public const uint32 COD_AUDIO_MINOR_LOUDSPEAKER = 5;
	public const uint32 COD_AUDIO_MINOR_HEADPHONES = 6;
	public const uint32 COD_AUDIO_MINOR_PORTABLE_AUDIO = 7;
	public const uint32 COD_AUDIO_MINOR_CAR_AUDIO = 8;
	public const uint32 COD_AUDIO_MINOR_SET_TOP_BOX = 9;
	public const uint32 COD_AUDIO_MINOR_HIFI_AUDIO = 10;
	public const uint32 COD_AUDIO_MINOR_VCR = 11;
	public const uint32 COD_AUDIO_MINOR_VIDEO_CAMERA = 12;
	public const uint32 COD_AUDIO_MINOR_CAMCORDER = 13;
	public const uint32 COD_AUDIO_MINOR_VIDEO_MONITOR = 14;
	public const uint32 COD_AUDIO_MINOR_VIDEO_DISPLAY_LOUDSPEAKER = 15;
	public const uint32 COD_AUDIO_MINOR_VIDEO_DISPLAY_CONFERENCING = 16;
	public const uint32 COD_AUDIO_MINOR_GAMING_TOY = 18;
	public const uint32 COD_PERIPHERAL_MINOR_KEYBOARD_MASK = 16;
	public const uint32 COD_PERIPHERAL_MINOR_POINTER_MASK = 32;
	public const uint32 COD_PERIPHERAL_MINOR_NO_CATEGORY = 0;
	public const uint32 COD_PERIPHERAL_MINOR_JOYSTICK = 1;
	public const uint32 COD_PERIPHERAL_MINOR_GAMEPAD = 2;
	public const uint32 COD_PERIPHERAL_MINOR_REMOTE_CONTROL = 3;
	public const uint32 COD_PERIPHERAL_MINOR_SENSING = 4;
	public const uint32 COD_IMAGING_MINOR_DISPLAY_MASK = 4;
	public const uint32 COD_IMAGING_MINOR_CAMERA_MASK = 8;
	public const uint32 COD_IMAGING_MINOR_SCANNER_MASK = 16;
	public const uint32 COD_IMAGING_MINOR_PRINTER_MASK = 32;
	public const uint32 COD_WEARABLE_MINOR_WRIST_WATCH = 1;
	public const uint32 COD_WEARABLE_MINOR_PAGER = 2;
	public const uint32 COD_WEARABLE_MINOR_JACKET = 3;
	public const uint32 COD_WEARABLE_MINOR_HELMET = 4;
	public const uint32 COD_WEARABLE_MINOR_GLASSES = 5;
	public const uint32 COD_TOY_MINOR_ROBOT = 1;
	public const uint32 COD_TOY_MINOR_VEHICLE = 2;
	public const uint32 COD_TOY_MINOR_DOLL_ACTION_FIGURE = 3;
	public const uint32 COD_TOY_MINOR_CONTROLLER = 4;
	public const uint32 COD_TOY_MINOR_GAME = 5;
	public const uint32 COD_HEALTH_MINOR_BLOOD_PRESSURE_MONITOR = 1;
	public const uint32 COD_HEALTH_MINOR_THERMOMETER = 2;
	public const uint32 COD_HEALTH_MINOR_WEIGHING_SCALE = 3;
	public const uint32 COD_HEALTH_MINOR_GLUCOSE_METER = 4;
	public const uint32 COD_HEALTH_MINOR_PULSE_OXIMETER = 5;
	public const uint32 COD_HEALTH_MINOR_HEART_PULSE_MONITOR = 6;
	public const uint32 COD_HEALTH_MINOR_HEALTH_DATA_DISPLAY = 7;
	public const uint32 COD_HEALTH_MINOR_STEP_COUNTER = 8;
	public const uint32 COD_LAN_ACCESS_BIT_OFFSET = 5;
	public const uint32 COD_LAN_MINOR_MASK = 28;
	public const uint32 COD_LAN_ACCESS_MASK = 224;
	public const uint32 COD_LAN_MINOR_UNCLASSIFIED = 0;
	public const uint32 COD_LAN_ACCESS_0_USED = 0;
	public const uint32 COD_LAN_ACCESS_17_USED = 1;
	public const uint32 COD_LAN_ACCESS_33_USED = 2;
	public const uint32 COD_LAN_ACCESS_50_USED = 3;
	public const uint32 COD_LAN_ACCESS_67_USED = 4;
	public const uint32 COD_LAN_ACCESS_83_USED = 5;
	public const uint32 COD_LAN_ACCESS_99_USED = 6;
	public const uint32 COD_LAN_ACCESS_FULL = 7;
	public const uint32 BTH_EIR_FLAGS_ID = 1;
	public const uint32 BTH_EIR_16_UUIDS_PARTIAL_ID = 2;
	public const uint32 BTH_EIR_16_UUIDS_COMPLETE_ID = 3;
	public const uint32 BTH_EIR_32_UUIDS_PARTIAL_ID = 4;
	public const uint32 BTH_EIR_32_UUIDS_COMPLETE_ID = 5;
	public const uint32 BTH_EIR_128_UUIDS_PARTIAL_ID = 6;
	public const uint32 BTH_EIR_128_UUIDS_COMPLETE_ID = 7;
	public const uint32 BTH_EIR_LOCAL_NAME_PARTIAL_ID = 8;
	public const uint32 BTH_EIR_LOCAL_NAME_COMPLETE_ID = 9;
	public const uint32 BTH_EIR_TX_POWER_LEVEL_ID = 10;
	public const uint32 BTH_EIR_OOB_OPT_DATA_LEN_ID = 11;
	public const uint32 BTH_EIR_OOB_BD_ADDR_ID = 12;
	public const uint32 BTH_EIR_OOB_COD_ID = 13;
	public const uint32 BTH_EIR_OOB_SP_HASH_ID = 14;
	public const uint32 BTH_EIR_OOB_SP_RANDOMIZER_ID = 15;
	public const uint32 BTH_EIR_MANUFACTURER_ID = 255;
	public const uint32 BTH_EIR_SIZE = 240;
	public const uint32 LAP_GIAC_VALUE = 10390323;
	public const uint32 LAP_LIAC_VALUE = 10390272;
	public const uint32 BTH_ADDR_IAC_FIRST = 10390272;
	public const uint32 BTH_ADDR_IAC_LAST = 10390335;
	public const uint32 BTH_ADDR_LIAC = 10390272;
	public const uint32 BTH_ADDR_GIAC = 10390323;
	public const uint32 BTH_ERROR_SUCCESS = 0;
	public const uint32 BTH_ERROR_UNKNOWN_HCI_COMMAND = 1;
	public const uint32 BTH_ERROR_NO_CONNECTION = 2;
	public const uint32 BTH_ERROR_HARDWARE_FAILURE = 3;
	public const uint32 BTH_ERROR_PAGE_TIMEOUT = 4;
	public const uint32 BTH_ERROR_AUTHENTICATION_FAILURE = 5;
	public const uint32 BTH_ERROR_KEY_MISSING = 6;
	public const uint32 BTH_ERROR_MEMORY_FULL = 7;
	public const uint32 BTH_ERROR_CONNECTION_TIMEOUT = 8;
	public const uint32 BTH_ERROR_MAX_NUMBER_OF_CONNECTIONS = 9;
	public const uint32 BTH_ERROR_MAX_NUMBER_OF_SCO_CONNECTIONS = 10;
	public const uint32 BTH_ERROR_ACL_CONNECTION_ALREADY_EXISTS = 11;
	public const uint32 BTH_ERROR_COMMAND_DISALLOWED = 12;
	public const uint32 BTH_ERROR_HOST_REJECTED_LIMITED_RESOURCES = 13;
	public const uint32 BTH_ERROR_HOST_REJECTED_SECURITY_REASONS = 14;
	public const uint32 BTH_ERROR_HOST_REJECTED_PERSONAL_DEVICE = 15;
	public const uint32 BTH_ERROR_HOST_TIMEOUT = 16;
	public const uint32 BTH_ERROR_UNSUPPORTED_FEATURE_OR_PARAMETER = 17;
	public const uint32 BTH_ERROR_INVALID_HCI_PARAMETER = 18;
	public const uint32 BTH_ERROR_REMOTE_USER_ENDED_CONNECTION = 19;
	public const uint32 BTH_ERROR_REMOTE_LOW_RESOURCES = 20;
	public const uint32 BTH_ERROR_REMOTE_POWERING_OFF = 21;
	public const uint32 BTH_ERROR_LOCAL_HOST_TERMINATED_CONNECTION = 22;
	public const uint32 BTH_ERROR_REPEATED_ATTEMPTS = 23;
	public const uint32 BTH_ERROR_PAIRING_NOT_ALLOWED = 24;
	public const uint32 BTH_ERROR_UKNOWN_LMP_PDU = 25;
	public const uint32 BTH_ERROR_UNSUPPORTED_REMOTE_FEATURE = 26;
	public const uint32 BTH_ERROR_SCO_OFFSET_REJECTED = 27;
	public const uint32 BTH_ERROR_SCO_INTERVAL_REJECTED = 28;
	public const uint32 BTH_ERROR_SCO_AIRMODE_REJECTED = 29;
	public const uint32 BTH_ERROR_INVALID_LMP_PARAMETERS = 30;
	public const uint32 BTH_ERROR_UNSPECIFIED_ERROR = 31;
	public const uint32 BTH_ERROR_UNSUPPORTED_LMP_PARM_VALUE = 32;
	public const uint32 BTH_ERROR_ROLE_CHANGE_NOT_ALLOWED = 33;
	public const uint32 BTH_ERROR_LMP_RESPONSE_TIMEOUT = 34;
	public const uint32 BTH_ERROR_LMP_TRANSACTION_COLLISION = 35;
	public const uint32 BTH_ERROR_LMP_PDU_NOT_ALLOWED = 36;
	public const uint32 BTH_ERROR_ENCRYPTION_MODE_NOT_ACCEPTABLE = 37;
	public const uint32 BTH_ERROR_UNIT_KEY_NOT_USED = 38;
	public const uint32 BTH_ERROR_QOS_IS_NOT_SUPPORTED = 39;
	public const uint32 BTH_ERROR_INSTANT_PASSED = 40;
	public const uint32 BTH_ERROR_PAIRING_WITH_UNIT_KEY_NOT_SUPPORTED = 41;
	public const uint32 BTH_ERROR_DIFFERENT_TRANSACTION_COLLISION = 42;
	public const uint32 BTH_ERROR_QOS_UNACCEPTABLE_PARAMETER = 44;
	public const uint32 BTH_ERROR_QOS_REJECTED = 45;
	public const uint32 BTH_ERROR_CHANNEL_CLASSIFICATION_NOT_SUPPORTED = 46;
	public const uint32 BTH_ERROR_INSUFFICIENT_SECURITY = 47;
	public const uint32 BTH_ERROR_PARAMETER_OUT_OF_MANDATORY_RANGE = 48;
	public const uint32 BTH_ERROR_ROLE_SWITCH_PENDING = 50;
	public const uint32 BTH_ERROR_RESERVED_SLOT_VIOLATION = 52;
	public const uint32 BTH_ERROR_ROLE_SWITCH_FAILED = 53;
	public const uint32 BTH_ERROR_EXTENDED_INQUIRY_RESPONSE_TOO_LARGE = 54;
	public const uint32 BTH_ERROR_SECURE_SIMPLE_PAIRING_NOT_SUPPORTED_BY_HOST = 55;
	public const uint32 BTH_ERROR_HOST_BUSY_PAIRING = 56;
	public const uint32 BTH_ERROR_CONNECTION_REJECTED_DUE_TO_NO_SUITABLE_CHANNEL_FOUND = 57;
	public const uint32 BTH_ERROR_CONTROLLER_BUSY = 58;
	public const uint32 BTH_ERROR_UNACCEPTABLE_CONNECTION_INTERVAL = 59;
	public const uint32 BTH_ERROR_DIRECTED_ADVERTISING_TIMEOUT = 60;
	public const uint32 BTH_ERROR_CONNECTION_TERMINATED_DUE_TO_MIC_FAILURE = 61;
	public const uint32 BTH_ERROR_CONNECTION_FAILED_TO_BE_ESTABLISHED = 62;
	public const uint32 BTH_ERROR_MAC_CONNECTION_FAILED = 63;
	public const uint32 BTH_ERROR_COARSE_CLOCK_ADJUSTMENT_REJECTED = 64;
	public const uint32 BTH_ERROR_TYPE_0_SUBMAP_NOT_DEFINED = 65;
	public const uint32 BTH_ERROR_UNKNOWN_ADVERTISING_IDENTIFIER = 66;
	public const uint32 BTH_ERROR_LIMIT_REACHED = 67;
	public const uint32 BTH_ERROR_OPERATION_CANCELLED_BY_HOST = 68;
	public const uint32 BTH_ERROR_PACKET_TOO_LONG = 69;
	public const uint32 BTH_ERROR_UNSPECIFIED = 255;
	public const uint32 L2CAP_MIN_MTU = 48;
	public const uint32 L2CAP_MAX_MTU = 65535;
	public const uint32 L2CAP_DEFAULT_MTU = 672;
	public const uint32 MAX_L2CAP_PING_DATA_LENGTH = 44;
	public const uint32 MAX_L2CAP_INFO_DATA_LENGTH = 44;
	public const uint32 BDIF_ADDRESS = 1;
	public const uint32 BDIF_COD = 2;
	public const uint32 BDIF_NAME = 4;
	public const uint32 BDIF_PAIRED = 8;
	public const uint32 BDIF_PERSONAL = 16;
	public const uint32 BDIF_CONNECTED = 32;
	public const uint32 BDIF_SHORT_NAME = 64;
	public const uint32 BDIF_VISIBLE = 128;
	public const uint32 BDIF_SSP_SUPPORTED = 256;
	public const uint32 BDIF_SSP_PAIRED = 512;
	public const uint32 BDIF_SSP_MITM_PROTECTED = 1024;
	public const uint32 BDIF_RSSI = 4096;
	public const uint32 BDIF_EIR = 8192;
	public const uint32 BDIF_BR = 16384;
	public const uint32 BDIF_LE = 32768;
	public const uint32 BDIF_LE_PAIRED = 65536;
	public const uint32 BDIF_LE_PERSONAL = 131072;
	public const uint32 BDIF_LE_MITM_PROTECTED = 262144;
	public const uint32 BDIF_LE_PRIVACY_ENABLED = 524288;
	public const uint32 BDIF_LE_RANDOM_ADDRESS_TYPE = 1048576;
	public const uint32 BDIF_LE_DISCOVERABLE = 2097152;
	public const uint32 BDIF_LE_NAME = 4194304;
	public const uint32 BDIF_LE_VISIBLE = 8388608;
	public const uint32 BDIF_LE_CONNECTED = 16777216;
	public const uint32 BDIF_LE_CONNECTABLE = 33554432;
	public const uint32 BDIF_CONNECTION_INBOUND = 67108864;
	public const uint32 BDIF_BR_SECURE_CONNECTION_PAIRED = 134217728;
	public const uint32 BDIF_LE_SECURE_CONNECTION_PAIRED = 268435456;
	public const uint32 BDIF_DEBUGKEY = 536870912;
	public const uint32 BDIF_LE_DEBUGKEY = 1073741824;
	public const uint32 BDIF_TX_POWER = 2147483648;
	public const uint32 HCI_CONNECTION_TYPE_ACL = 1;
	public const uint32 HCI_CONNECTION_TYPE_SCO = 2;
	public const uint32 HCI_CONNECTION_TYPE_LE = 3;
	public const uint32 HCI_CONNNECTION_TYPE_ACL = 1;
	public const uint32 HCI_CONNNECTION_TYPE_SCO = 2;
	public const uint32 BTH_MAX_SERVICE_NAME_SIZE = 256;
	public const uint32 MAX_UUIDS_IN_QUERY = 12;
	public const uint32 BTH_VID_DEFAULT_VALUE = 65535;
	public const uint32 SDP_ERROR_INVALID_SDP_VERSION = 1;
	public const uint32 SDP_ERROR_INVALID_RECORD_HANDLE = 2;
	public const uint32 SDP_ERROR_INVALID_REQUEST_SYNTAX = 3;
	public const uint32 SDP_ERROR_INVALID_PDU_SIZE = 4;
	public const uint32 SDP_ERROR_INVALID_CONTINUATION_STATE = 5;
	public const uint32 SDP_ERROR_INSUFFICIENT_RESOURCES = 6;
	public const uint32 SDP_ATTRIB_RECORD_HANDLE = 0;
	public const uint32 SDP_ATTRIB_CLASS_ID_LIST = 1;
	public const uint32 SDP_ATTRIB_RECORD_STATE = 2;
	public const uint32 SDP_ATTRIB_SERVICE_ID = 3;
	public const uint32 SDP_ATTRIB_PROTOCOL_DESCRIPTOR_LIST = 4;
	public const uint32 SDP_ATTRIB_BROWSE_GROUP_LIST = 5;
	public const uint32 SDP_ATTRIB_LANG_BASE_ATTRIB_ID_LIST = 6;
	public const uint32 SDP_ATTRIB_INFO_TIME_TO_LIVE = 7;
	public const uint32 SDP_ATTRIB_AVAILABILITY = 8;
	public const uint32 SDP_ATTRIB_PROFILE_DESCRIPTOR_LIST = 9;
	public const uint32 SDP_ATTRIB_DOCUMENTATION_URL = 10;
	public const uint32 SDP_ATTRIB_CLIENT_EXECUTABLE_URL = 11;
	public const uint32 SDP_ATTRIB_ICON_URL = 12;
	public const uint32 SDP_ATTRIB_ADDITIONAL_PROTOCOL_DESCRIPTOR_LIST = 13;
	public const uint32 SDP_ATTRIB_PROFILE_SPECIFIC = 512;
	public const uint32 LANG_BASE_LANGUAGE_INDEX = 0;
	public const uint32 LANG_BASE_ENCODING_INDEX = 1;
	public const uint32 LANG_BASE_OFFSET_INDEX = 2;
	public const uint32 LANG_DEFAULT_ID = 256;
	public const uint32 LANGUAGE_EN_US = 25966;
	public const uint32 ENCODING_UTF_8 = 106;
	public const uint32 STRING_NAME_OFFSET = 0;
	public const uint32 STRING_DESCRIPTION_OFFSET = 1;
	public const uint32 STRING_PROVIDER_NAME_OFFSET = 2;
	public const uint32 SDP_ATTRIB_SDP_VERSION_NUMBER_LIST = 512;
	public const uint32 SDP_ATTRIB_SDP_DATABASE_STATE = 513;
	public const uint32 SDP_ATTRIB_BROWSE_GROUP_ID = 512;
	public const uint32 SDP_ATTRIB_CORDLESS_EXTERNAL_NETWORK = 769;
	public const uint32 SDP_ATTRIB_FAX_CLASS_1_SUPPORT = 770;
	public const uint32 SDP_ATTRIB_FAX_CLASS_2_0_SUPPORT = 771;
	public const uint32 SDP_ATTRIB_FAX_CLASS_2_SUPPORT = 772;
	public const uint32 SDP_ATTRIB_FAX_AUDIO_FEEDBACK_SUPPORT = 773;
	public const uint32 SDP_ATTRIB_HEADSET_REMOTE_AUDIO_VOLUME_CONTROL = 770;
	public const uint32 SDP_ATTRIB_LAN_LPSUBNET = 512;
	public const uint32 SDP_ATTRIB_OBJECT_PUSH_SUPPORTED_FORMATS_LIST = 771;
	public const uint32 SDP_ATTRIB_SYNCH_SUPPORTED_DATA_STORES_LIST = 769;
	public const uint32 SDP_ATTRIB_SERVICE_VERSION = 768;
	public const uint32 SDP_ATTRIB_PAN_NETWORK_ADDRESS = 774;
	public const uint32 SDP_ATTRIB_PAN_WAP_GATEWAY = 775;
	public const uint32 SDP_ATTRIB_PAN_HOME_PAGE_URL = 776;
	public const uint32 SDP_ATTRIB_PAN_WAP_STACK_TYPE = 777;
	public const uint32 SDP_ATTRIB_PAN_SECURITY_DESCRIPTION = 778;
	public const uint32 SDP_ATTRIB_PAN_NET_ACCESS_TYPE = 779;
	public const uint32 SDP_ATTRIB_PAN_MAX_NET_ACCESS_RATE = 780;
	public const uint32 SDP_ATTRIB_IMAGING_SUPPORTED_CAPABILITIES = 784;
	public const uint32 SDP_ATTRIB_IMAGING_SUPPORTED_FEATURES = 785;
	public const uint32 SDP_ATTRIB_IMAGING_SUPPORTED_FUNCTIONS = 786;
	public const uint32 SDP_ATTRIB_IMAGING_TOTAL_DATA_CAPACITY = 787;
	public const uint32 SDP_ATTRIB_DI_SPECIFICATION_ID = 512;
	public const uint32 SDP_ATTRIB_DI_VENDOR_ID = 513;
	public const uint32 SDP_ATTRIB_DI_PRODUCT_ID = 514;
	public const uint32 SDP_ATTRIB_DI_VERSION = 515;
	public const uint32 SDP_ATTRIB_DI_PRIMARY_RECORD = 516;
	public const uint32 SDP_ATTRIB_DI_VENDOR_ID_SOURCE = 517;
	public const uint32 SDP_ATTRIB_HID_DEVICE_RELEASE_NUMBER = 512;
	public const uint32 SDP_ATTRIB_HID_PARSER_VERSION = 513;
	public const uint32 SDP_ATTRIB_HID_DEVICE_SUBCLASS = 514;
	public const uint32 SDP_ATTRIB_HID_COUNTRY_CODE = 515;
	public const uint32 SDP_ATTRIB_HID_VIRTUAL_CABLE = 516;
	public const uint32 SDP_ATTRIB_HID_RECONNECT_INITIATE = 517;
	public const uint32 SDP_ATTRIB_HID_DESCRIPTOR_LIST = 518;
	public const uint32 SDP_ATTRIB_HID_LANG_ID_BASE_LIST = 519;
	public const uint32 SDP_ATTRIB_HID_SDP_DISABLE = 520;
	public const uint32 SDP_ATTRIB_HID_BATTERY_POWER = 521;
	public const uint32 SDP_ATTRIB_HID_REMOTE_WAKE = 522;
	public const uint32 SDP_ATTRIB_HID_PROFILE_VERSION = 523;
	public const uint32 SDP_ATTRIB_HID_SUPERVISION_TIMEOUT = 524;
	public const uint32 SDP_ATTRIB_HID_NORMALLY_CONNECTABLE = 525;
	public const uint32 SDP_ATTRIB_HID_BOOT_DEVICE = 526;
	public const uint32 SDP_ATTRIB_HID_SSR_HOST_MAX_LATENCY = 527;
	public const uint32 SDP_ATTRIB_HID_SSR_HOST_MIN_TIMEOUT = 528;
	public const uint32 SDP_ATTRIB_A2DP_SUPPORTED_FEATURES = 785;
	public const uint32 SDP_ATTRIB_AVRCP_SUPPORTED_FEATURES = 785;
	public const uint32 SDP_ATTRIB_HFP_SUPPORTED_FEATURES = 785;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CATEGORY_1 = 1;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CATEGORY_2 = 2;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CATEGORY_3 = 4;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CATEGORY_4 = 8;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CT_BROWSING = 64;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CT_COVER_ART_IMAGE_PROPERTIES = 128;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CT_COVER_ART_IMAGE = 256;
	public const uint32 AVRCP_SUPPORTED_FEATURES_CT_COVER_ART_LINKED_THUMBNAIL = 512;
	public const uint32 AVRCP_SUPPORTED_FEATURES_TG_PLAYER_APPLICATION_SETTINGS = 16;
	public const uint32 AVRCP_SUPPORTED_FEATURES_TG_GROUP_NAVIGATION = 32;
	public const uint32 AVRCP_SUPPORTED_FEATURES_TG_BROWSING = 64;
	public const uint32 AVRCP_SUPPORTED_FEATURES_TG_MULTIPLE_PLAYER_APPLICATIONS = 128;
	public const uint32 AVRCP_SUPPORTED_FEATURES_TG_COVER_ART = 256;
	public const uint32 A2DP_SINK_SUPPORTED_FEATURES_HEADPHONE = 1;
	public const uint32 A2DP_SINK_SUPPORTED_FEATURES_SPEAKER = 2;
	public const uint32 A2DP_SINK_SUPPORTED_FEATURES_RECORDER = 4;
	public const uint32 A2DP_SINK_SUPPORTED_FEATURES_AMPLIFIER = 8;
	public const uint32 A2DP_SOURCE_SUPPORTED_FEATURES_PLAYER = 1;
	public const uint32 A2DP_SOURCE_SUPPORTED_FEATURES_MICROPHONE = 2;
	public const uint32 A2DP_SOURCE_SUPPORTED_FEATURES_TUNER = 4;
	public const uint32 A2DP_SOURCE_SUPPORTED_FEATURES_MIXER = 8;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_PSTN = 1;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_ISDN = 2;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_GSM = 3;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_CDMA = 4;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_ANALOG_CELLULAR = 5;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_PACKET_SWITCHED = 6;
	public const uint32 CORDLESS_EXTERNAL_NETWORK_OTHER = 7;
	public const uint32 OBJECT_PUSH_FORMAT_VCARD_2_1 = 1;
	public const uint32 OBJECT_PUSH_FORMAT_VCARD_3_0 = 2;
	public const uint32 OBJECT_PUSH_FORMAT_VCAL_1_0 = 3;
	public const uint32 OBJECT_PUSH_FORMAT_ICAL_2_0 = 4;
	public const uint32 OBJECT_PUSH_FORMAT_VNOTE = 5;
	public const uint32 OBJECT_PUSH_FORMAT_VMESSAGE = 6;
	public const uint32 OBJECT_PUSH_FORMAT_ANY = 255;
	public const uint32 SYNCH_DATA_STORE_PHONEBOOK = 1;
	public const uint32 SYNCH_DATA_STORE_CALENDAR = 3;
	public const uint32 SYNCH_DATA_STORE_NOTES = 5;
	public const uint32 SYNCH_DATA_STORE_MESSAGES = 6;
	public const uint32 DI_VENDOR_ID_SOURCE_BLUETOOTH_SIG = 1;
	public const uint32 DI_VENDOR_ID_SOURCE_USB_IF = 2;
	public const uint32 PSM_SDP = 1;
	public const uint32 PSM_RFCOMM = 3;
	public const uint32 PSM_TCS_BIN = 5;
	public const uint32 PSM_TCS_BIN_CORDLESS = 7;
	public const uint32 PSM_BNEP = 15;
	public const uint32 PSM_HID_CONTROL = 17;
	public const uint32 PSM_HID_INTERRUPT = 19;
	public const uint32 PSM_UPNP = 21;
	public const uint32 PSM_AVCTP = 23;
	public const uint32 PSM_AVDTP = 25;
	public const uint32 PSM_AVCTP_BROWSE = 27;
	public const uint32 PSM_UDI_C_PLANE = 29;
	public const uint32 PSM_ATT = 31;
	public const uint32 PSM_3DSP = 33;
	public const uint32 PSM_LE_IPSP = 35;
	public const String STR_ADDR_FMTA = "(%02x:%02x:%02x:%02x:%02x:%02x)";
	public const String STR_ADDR_FMTW = "(%02x:%02x:%02x:%02x:%02x:%02x)";
	public const String STR_ADDR_SHORT_FMTA = "%04x%08x";
	public const String STR_ADDR_SHORT_FMTW = "%04x%08x";
	public const String STR_USBHCI_CLASS_HARDWAREIDA = "USB\\Class_E0&SubClass_01&Prot_01";
	public const String STR_USBHCI_CLASS_HARDWAREIDW = "USB\\Class_E0&SubClass_01&Prot_01";
	public const String STR_ADDR_FMT = "(%02x:%02x:%02x:%02x:%02x:%02x)";
	public const String STR_ADDR_SHORT_FMT = "%04x%08x";
	public const String STR_USBHCI_CLASS_HARDWAREID = "USB\\Class_E0&SubClass_01&Prot_01";
	public const uint32 BTH_IOCTL_BASE = 0;
	public const uint32 SDP_CONNECT_CACHE = 1;
	public const uint32 SDP_CONNECT_ALLOW_PIN = 2;
	public const uint32 SDP_REQUEST_TO_DEFAULT = 0;
	public const uint32 SDP_REQUEST_TO_MIN = 10;
	public const uint32 SDP_REQUEST_TO_MAX = 45;
	public const uint32 SERVICE_OPTION_DO_NOT_PUBLISH = 2;
	public const uint32 SERVICE_OPTION_NO_PUBLIC_BROWSE = 4;
	public const uint32 SERVICE_OPTION_DO_NOT_PUBLISH_EIR = 8;
	public const uint32 SERVICE_SECURITY_USE_DEFAULTS = 0;
	public const uint32 SERVICE_SECURITY_NONE = 1;
	public const uint32 SERVICE_SECURITY_AUTHORIZE = 2;
	public const uint32 SERVICE_SECURITY_AUTHENTICATE = 4;
	public const uint32 SERVICE_SECURITY_ENCRYPT_REQUIRED = 16;
	public const uint32 SERVICE_SECURITY_ENCRYPT_OPTIONAL = 32;
	public const uint32 SERVICE_SECURITY_DISABLED = 268435456;
	public const uint32 SERVICE_SECURITY_NO_ASK = 536870912;
	public const uint32 SDP_SEARCH_NO_PARSE_CHECK = 1;
	public const uint32 SDP_SEARCH_NO_FORMAT_CHECK = 2;
	public const uint64 BTH_HOST_FEATURE_ENHANCED_RETRANSMISSION_MODE = 1;
	public const uint64 BTH_HOST_FEATURE_STREAMING_MODE = 2;
	public const uint64 BTH_HOST_FEATURE_LOW_ENERGY = 4;
	public const uint64 BTH_HOST_FEATURE_SCO_HCI = 8;
	public const uint64 BTH_HOST_FEATURE_SCO_HCIBYPASS = 16;
	public const uint32 BLUETOOTH_MAX_NAME_SIZE = 248;
	public const uint32 BLUETOOTH_MAX_PASSKEY_SIZE = 16;
	public const uint32 BLUETOOTH_MAX_PASSKEY_BUFFER_SIZE = 17;
	public const uint32 BLUETOOTH_MAX_SERVICE_NAME_SIZE = 256;
	public const uint32 BLUETOOTH_DEVICE_NAME_SIZE = 256;
	public const uint32 BLUETOOTH_SERVICE_DISABLE = 0;
	public const uint32 BLUETOOTH_SERVICE_ENABLE = 1;
	public const Guid GUID_BLUETOOTHLE_DEVICE_INTERFACE = .(0x781aee18, 0x7733, 0x4ce4, 0xad, 0xd0, 0x91, 0xf4, 0x1c, 0x67, 0xb5, 0x92);
	public const Guid GUID_BLUETOOTH_GATT_SERVICE_DEVICE_INTERFACE = .(0x6e3bb679, 0x4372, 0x40c8, 0x9e, 0xaa, 0x45, 0x09, 0xdf, 0x26, 0x0c, 0xd8);
	public const Guid BTH_LE_ATT_BLUETOOTH_BASE_GUID = .(0x00000000, 0x0000, 0x1000, 0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb);
	public const uint32 BTH_LE_SERVICE_GAP = 6144;
	public const uint32 BTH_LE_SERVICE_GATT = 6145;
	public const uint32 BTH_LE_GATT_ATTRIBUTE_TYPE_PRIMARY_SERVICE = 10240;
	public const uint32 BTH_LE_GATT_ATTRIBUTE_TYPE_SECONDARY_SERVICE = 10241;
	public const uint32 BTH_LE_GATT_ATTRIBUTE_TYPE_INCLUDE = 10242;
	public const uint32 BTH_LE_GATT_ATTRIBUTE_TYPE_CHARACTERISTIC = 10243;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_EXTENDED_PROPERTIES = 10496;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_USER_DESCRIPTION = 10497;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_CLIENT_CONFIGURATION = 10498;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_SERVER_CONFIGURATION = 10499;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_FORMAT = 10500;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_DESCRIPTOR_AGGREGATE_FORMAT = 10501;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_DEVICE_NAME = 10752;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_APPEARANCE = 10753;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_PERIPHERAL_PRIVACY_FLAG = 10754;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_RECONNECTION_ADDRESS = 10755;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_PERIPHERAL_PREFERED_CONNECTION_PARAMETER = 10756;
	public const uint32 BTH_LE_GATT_CHARACTERISTIC_TYPE_SERVICE_CHANGED = 10757;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_OFFSET = 6;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_MASK = 1023;
	public const uint32 BTH_LE_GAP_APPEARANCE_SUB_CATEGORY_MASK = 63;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_UNCATEGORIZED = 0;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_PHONE = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_COMPUTER = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_WATCH = 3;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_CLOCK = 4;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_DISPLAY = 5;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_REMOTE_CONTROL = 6;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_EYE_GLASSES = 7;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_TAG = 8;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_KEYRING = 9;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_MEDIA_PLAYER = 10;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_BARCODE_SCANNER = 11;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_THERMOMETER = 12;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_HEART_RATE = 13;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_BLOOD_PRESSURE = 14;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_HID = 15;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_GLUCOSE_METER = 16;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_RUNNING_WALKING_SENSOR = 17;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_CYCLING = 18;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_PLUSE_OXIMETER = 49;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_WEIGHT_SCALE = 50;
	public const uint32 BTH_LE_GAP_APPEARANCE_CATEGORY_OUTDOOR_SPORTS_ACTIVITY = 81;
	public const uint32 BTH_LE_GAP_APPEARANCE_SUBCATEGORY_GENERIC = 0;
	public const uint32 BTH_LE_GAP_APPEARANCE_WATCH_SUBCATEGORY_SPORTS_WATCH = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_THERMOMETER_SUBCATEGORY_EAR = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_HEART_RATE_SUBCATEGORY_HEART_RATE_BELT = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_BLOOD_PRESSURE_SUBCATEGORY_ARM = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_BLOOD_PRESSURE_SUBCATEGORY_WRIST = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_KEYBOARD = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_MOUSE = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_JOYSTICK = 3;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_GAMEPAD = 4;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_DIGITIZER_TABLET = 5;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_CARD_READER = 6;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_DIGITAL_PEN = 7;
	public const uint32 BTH_LE_GAP_APPEARANCE_HID_SUBCATEGORY_BARCODE_SCANNER = 8;
	public const uint32 BTH_LE_GAP_APPEARANCE_RUNNING_WALKING_SENSOR_SUBCATEGORY_IN_SHOE = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_RUNNING_WALKING_SENSOR_SUBCATEGORY_ON_SHOE = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_RUNNING_WALKING_SENSOR_SUBCATEGORY_ON_HIP = 3;
	public const uint32 BTH_LE_GAP_APPEARANCE_CYCLING_SUBCATEGORY_CYCLING_COMPUTER = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_CYCLING_SUBCATEGORY_SPEED_SENSOR = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_CYCLING_SUBCATEGORY_CADENCE_SENSOR = 3;
	public const uint32 BTH_LE_GAP_APPEARANCE_CYCLING_SUBCATEGORY_POWER_SENSOR = 4;
	public const uint32 BTH_LE_GAP_APPEARANCE_CYCLING_SUBCATEGORY_SPEED_AND_CADENCE_SENSOR = 5;
	public const uint32 BTH_LE_GAP_APPEARANCE_PULSE_OXIMETER_SUBCATEGORY_FINGERTIP = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_PULSE_OXIMETER_SUBCATEGORY_WRIST_WORN = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_OUTDOOR_SPORTS_ACTIVITY_SUBCATEGORY_LOCATION_DISPLAY_DEVICE = 1;
	public const uint32 BTH_LE_GAP_APPEARANCE_OUTDOOR_SPORTS_ACTIVITY_SUBCATEGORY_LOCATION_NAVIGATION_DISPLAY_DEVICE = 2;
	public const uint32 BTH_LE_GAP_APPEARANCE_OUTDOOR_SPORTS_ACTIVITY_SUBCATEGORY_LOCATION_POD = 3;
	public const uint32 BTH_LE_GAP_APPEARANCE_OUTDOOR_SPORTS_ACTIVITY_SUBCATEGORY_LOCATION_NAVIGATION_POD = 4;
	public const uint32 BTH_LE_GATT_DEFAULT_MAX_INCLUDED_SERVICES_DEPTH = 3;
	public const uint32 BTH_LE_ATT_TRANSACTION_TIMEOUT = 30;
	public const uint32 BTH_LE_ATT_MAX_VALUE_SIZE = 512;
	public const uint32 BTH_LE_ATT_CID = 4;
	public const uint32 BTHLEENUM_ATT_MTU_MIN = 23;
	public const uint32 BTHLEENUM_ATT_MTU_MAX = 65535;
	public const uint32 BTHLEENUM_ATT_MTU_DEFAULT = 23;
	public const uint32 BTHLEENUM_ATT_MTU_INITIAL_NEGOTIATION = 525;
	public const uint32 BTH_LE_ERROR_INVALID_HANDLE = 1;
	public const uint32 BTH_LE_ERROR_READ_NOT_PERMITTED = 2;
	public const uint32 BTH_LE_ERROR_WRITE_NOT_PERMITTED = 3;
	public const uint32 BTH_LE_ERROR_INVALID_PDU = 4;
	public const uint32 BTH_LE_ERROR_INSUFFICIENT_AUTHENTICATION = 5;
	public const uint32 BTH_LE_ERROR_REQUEST_NOT_SUPPORTED = 6;
	public const uint32 BTH_LE_ERROR_INVALID_OFFSET = 7;
	public const uint32 BTH_LE_ERROR_INSUFFICIENT_AUTHORIZATION = 8;
	public const uint32 BTH_LE_ERROR_PREPARE_QUEUE_FULL = 9;
	public const uint32 BTH_LE_ERROR_ATTRIBUTE_NOT_FOUND = 10;
	public const uint32 BTH_LE_ERROR_ATTRIBUTE_NOT_LONG = 11;
	public const uint32 BTH_LE_ERROR_INSUFFICIENT_ENCRYPTION_KEY_SIZE = 12;
	public const uint32 BTH_LE_ERROR_INVALID_ATTRIBUTE_VALUE_LENGTH = 13;
	public const uint32 BTH_LE_ERROR_UNLIKELY = 14;
	public const uint32 BTH_LE_ERROR_INSUFFICIENT_ENCRYPTION = 15;
	public const uint32 BTH_LE_ERROR_UNSUPPORTED_GROUP_TYPE = 16;
	public const uint32 BTH_LE_ERROR_INSUFFICIENT_RESOURCES = 17;
	public const uint32 BTH_LE_ERROR_UNKNOWN = 4096;
	public const uint32 BLUETOOTH_GATT_FLAG_NONE = 0;
	public const uint32 BLUETOOTH_GATT_FLAG_CONNECTION_ENCRYPTED = 1;
	public const uint32 BLUETOOTH_GATT_FLAG_CONNECTION_AUTHENTICATED = 2;
	public const uint32 BLUETOOTH_GATT_FLAG_FORCE_READ_FROM_DEVICE = 4;
	public const uint32 BLUETOOTH_GATT_FLAG_FORCE_READ_FROM_CACHE = 8;
	public const uint32 BLUETOOTH_GATT_FLAG_SIGNED_WRITE = 16;
	public const uint32 BLUETOOTH_GATT_FLAG_WRITE_WITHOUT_RESPONSE = 32;
	public const uint32 BLUETOOTH_GATT_FLAG_RETURN_ALL = 64;
	public const uint32 BT_PORT_MIN = 1;
	public const uint32 BT_PORT_MAX = 65535;
	public const uint32 BT_PORT_DYN_FIRST = 4097;
	public const uint16 AF_BTH = 32;
	public const uint16 PF_BTH = 32;
	public const uint32 NS_BTH = 16;
	public const Guid SVCID_BTH_PROVIDER = .(0x06aa63e0, 0x7d60, 0x41ff, 0xaf, 0xb2, 0x3e, 0xe6, 0xd2, 0xd9, 0x39, 0x2d);
	public const uint32 BTH_ADDR_STRING_SIZE = 12;
	public const uint32 BTHPROTO_RFCOMM = 3;
	public const uint32 BTHPROTO_L2CAP = 256;
	public const uint32 SOL_RFCOMM = 3;
	public const uint32 SOL_L2CAP = 256;
	public const uint32 SOL_SDP = 257;
	public const uint32 SO_BTH_AUTHENTICATE = 2147483649;
	public const uint32 SO_BTH_ENCRYPT = 2;
	public const uint32 SO_BTH_MTU = 2147483655;
	public const uint32 SO_BTH_MTU_MAX = 2147483656;
	public const uint32 SO_BTH_MTU_MIN = 2147483658;
	public const uint32 RFCOMM_MAX_MTU = 1011;
	public const uint32 RFCOMM_MIN_MTU = 23;
	public const uint32 BTH_SDP_VERSION = 1;
	public const uint32 SDP_DEFAULT_INQUIRY_SECONDS = 6;
	public const uint32 SDP_MAX_INQUIRY_SECONDS = 60;
	public const uint32 SDP_DEFAULT_INQUIRY_MAX_RESPONSES = 255;
	public const uint32 SDP_SERVICE_SEARCH_REQUEST = 1;
	public const uint32 SDP_SERVICE_ATTRIBUTE_REQUEST = 2;
	public const uint32 SDP_SERVICE_SEARCH_ATTRIBUTE_REQUEST = 3;
	public const uint32 BTHNS_RESULT_DEVICE_CONNECTED = 65536;
	public const uint32 BTHNS_RESULT_DEVICE_REMEMBERED = 131072;
	public const uint32 BTHNS_RESULT_DEVICE_AUTHENTICATED = 262144;
	public const uint32 RLS_ERROR = 1;
	public const uint32 RLS_OVERRUN = 2;
	public const uint32 RLS_PARITY = 4;
	public const uint32 RLS_FRAMING = 8;
	public const uint32 RPN_BAUD_2400 = 0;
	public const uint32 RPN_BAUD_4800 = 1;
	public const uint32 RPN_BAUD_7200 = 2;
	public const uint32 RPN_BAUD_9600 = 3;
	public const uint32 RPN_BAUD_19200 = 4;
	public const uint32 RPN_BAUD_38400 = 5;
	public const uint32 RPN_BAUD_57600 = 6;
	public const uint32 RPN_BAUD_115200 = 7;
	public const uint32 RPN_BAUD_230400 = 8;
	public const uint32 RPN_DATA_5 = 0;
	public const uint32 RPN_DATA_6 = 1;
	public const uint32 RPN_DATA_7 = 2;
	public const uint32 RPN_DATA_8 = 3;
	public const uint32 RPN_STOP_1 = 0;
	public const uint32 RPN_STOP_1_5 = 4;
	public const uint32 RPN_PARITY_NONE = 0;
	public const uint32 RPN_PARITY_ODD = 8;
	public const uint32 RPN_PARITY_EVEN = 24;
	public const uint32 RPN_PARITY_MARK = 40;
	public const uint32 RPN_PARITY_SPACE = 56;
	public const uint32 RPN_FLOW_X_IN = 1;
	public const uint32 RPN_FLOW_X_OUT = 2;
	public const uint32 RPN_FLOW_RTR_IN = 4;
	public const uint32 RPN_FLOW_RTR_OUT = 8;
	public const uint32 RPN_FLOW_RTC_IN = 16;
	public const uint32 RPN_FLOW_RTC_OUT = 32;
	public const uint32 RPN_PARAM_BAUD = 1;
	public const uint32 RPN_PARAM_DATA = 2;
	public const uint32 RPN_PARAM_STOP = 4;
	public const uint32 RPN_PARAM_PARITY = 8;
	public const uint32 RPN_PARAM_P_TYPE = 16;
	public const uint32 RPN_PARAM_XON = 32;
	public const uint32 RPN_PARAM_XOFF = 64;
	public const uint32 RPN_PARAM_X_IN = 1;
	public const uint32 RPN_PARAM_X_OUT = 2;
	public const uint32 RPN_PARAM_RTR_IN = 4;
	public const uint32 RPN_PARAM_RTR_OUT = 8;
	public const uint32 RPN_PARAM_RTC_IN = 16;
	public const uint32 RPN_PARAM_RTC_OUT = 32;
	public const uint32 RFCOMM_CMD_NONE = 0;
	public const uint32 RFCOMM_CMD_MSC = 1;
	public const uint32 RFCOMM_CMD_RLS = 2;
	public const uint32 RFCOMM_CMD_RPN = 3;
	public const uint32 RFCOMM_CMD_RPN_REQUEST = 4;
	public const uint32 RFCOMM_CMD_RPN_RESPONSE = 5;
}
#endregion

#region TypeDefs
typealias HANDLE_SDP_TYPE = uint64;

#endregion


#region Enums

[AllowDuplicates]
public enum NodeContainerType : int32
{
	NodeContainerTypeSequence = 0,
	NodeContainerTypeAlternative = 1,
}


[AllowDuplicates]
public enum SDP_TYPE : int32
{
	SDP_TYPE_NIL = 0,
	SDP_TYPE_UINT = 1,
	SDP_TYPE_INT = 2,
	SDP_TYPE_UUID = 3,
	SDP_TYPE_STRING = 4,
	SDP_TYPE_BOOLEAN = 5,
	SDP_TYPE_SEQUENCE = 6,
	SDP_TYPE_ALTERNATIVE = 7,
	SDP_TYPE_URL = 8,
	SDP_TYPE_CONTAINER = 32,
}


[AllowDuplicates]
public enum SDP_SPECIFICTYPE : int32
{
	SDP_ST_NONE = 0,
	SDP_ST_UINT8 = 16,
	SDP_ST_UINT16 = 272,
	SDP_ST_UINT32 = 528,
	SDP_ST_UINT64 = 784,
	SDP_ST_UINT128 = 1040,
	SDP_ST_INT8 = 32,
	SDP_ST_INT16 = 288,
	SDP_ST_INT32 = 544,
	SDP_ST_INT64 = 800,
	SDP_ST_INT128 = 1056,
	SDP_ST_UUID16 = 304,
	SDP_ST_UUID32 = 544,
	SDP_ST_UUID128 = 1072,
}


[AllowDuplicates]
public enum IO_CAPABILITY : int32
{
	IoCaps_DisplayOnly = 0,
	IoCaps_DisplayYesNo = 1,
	IoCaps_KeyboardOnly = 2,
	IoCaps_NoInputNoOutput = 3,
	IoCaps_Undefined = 255,
}


[AllowDuplicates]
public enum AUTHENTICATION_REQUIREMENTS : int32
{
	MITMProtectionNotRequired = 0,
	MITMProtectionRequired = 1,
	MITMProtectionNotRequiredBonding = 2,
	MITMProtectionRequiredBonding = 3,
	MITMProtectionNotRequiredGeneralBonding = 4,
	MITMProtectionRequiredGeneralBonding = 5,
	MITMProtectionNotDefined = 255,
}


[AllowDuplicates]
public enum BLUETOOTH_AUTHENTICATION_METHOD : int32
{
	BLUETOOTH_AUTHENTICATION_METHOD_LEGACY = 1,
	BLUETOOTH_AUTHENTICATION_METHOD_OOB = 2,
	BLUETOOTH_AUTHENTICATION_METHOD_NUMERIC_COMPARISON = 3,
	BLUETOOTH_AUTHENTICATION_METHOD_PASSKEY_NOTIFICATION = 4,
	BLUETOOTH_AUTHENTICATION_METHOD_PASSKEY = 5,
}


[AllowDuplicates]
public enum BLUETOOTH_IO_CAPABILITY : int32
{
	BLUETOOTH_IO_CAPABILITY_DISPLAYONLY = 0,
	BLUETOOTH_IO_CAPABILITY_DISPLAYYESNO = 1,
	BLUETOOTH_IO_CAPABILITY_KEYBOARDONLY = 2,
	BLUETOOTH_IO_CAPABILITY_NOINPUTNOOUTPUT = 3,
	BLUETOOTH_IO_CAPABILITY_UNDEFINED = 255,
}


[AllowDuplicates]
public enum BLUETOOTH_AUTHENTICATION_REQUIREMENTS : int32
{
	BLUETOOTH_MITM_ProtectionNotRequired = 0,
	BLUETOOTH_MITM_ProtectionRequired = 1,
	BLUETOOTH_MITM_ProtectionNotRequiredBonding = 2,
	BLUETOOTH_MITM_ProtectionRequiredBonding = 3,
	BLUETOOTH_MITM_ProtectionNotRequiredGeneralBonding = 4,
	BLUETOOTH_MITM_ProtectionRequiredGeneralBonding = 5,
	BLUETOOTH_MITM_ProtectionNotDefined = 255,
}


[AllowDuplicates]
public enum BTH_LE_GATT_DESCRIPTOR_TYPE : int32
{
	CharacteristicExtendedProperties = 0,
	CharacteristicUserDescription = 1,
	ClientCharacteristicConfiguration = 2,
	ServerCharacteristicConfiguration = 3,
	CharacteristicFormat = 4,
	CharacteristicAggregateFormat = 5,
	CustomDescriptor = 6,
}


[AllowDuplicates]
public enum BTH_LE_GATT_EVENT_TYPE : int32
{
	CharacteristicValueChangedEvent = 0,
}

#endregion

#region Function Pointers
public function BOOL PFN_DEVICE_CALLBACK(void* pvParam, BLUETOOTH_DEVICE_INFO_STRUCT* pDevice);

public function BOOL PFN_AUTHENTICATION_CALLBACK(void* pvParam, BLUETOOTH_DEVICE_INFO_STRUCT* pDevice);

public function BOOL PFN_AUTHENTICATION_CALLBACK_EX(void* pvParam, BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS* pAuthCallbackParams);

public function BOOL PFN_BLUETOOTH_ENUM_ATTRIBUTES_CALLBACK(uint32 uAttribId, uint8* pValueStream, uint32 cbStreamSize, void* pvParam);

public function void PFNBLUETOOTH_GATT_EVENT_CALLBACK(BTH_LE_GATT_EVENT_TYPE EventType, void* EventOutParameter, void* Context);

#endregion

#region Structs
[CRepr]
public struct SDP_LARGE_INTEGER_16
{
	public uint64 LowPart;
	public int64 HighPart;
}

[CRepr]
public struct SDP_ULARGE_INTEGER_16
{
	public uint64 LowPart;
	public uint64 HighPart;
}

[CRepr]
public struct SdpAttributeRange
{
	public uint16 minAttribute;
	public uint16 maxAttribute;
}

[CRepr, Union]
public struct SdpQueryUuidUnion
{
	public Guid uuid128;
	public uint32 uuid32;
	public uint16 uuid16;
}

[CRepr]
public struct SdpQueryUuid
{
	public SdpQueryUuidUnion u;
	public uint16 uuidType;
}

[CRepr]
public struct BTH_DEVICE_INFO
{
	public uint32 flags;
	public uint64 address;
	public uint32 classOfDevice;
	public CHAR[248] name;
}

[CRepr]
public struct BTH_RADIO_IN_RANGE
{
	public BTH_DEVICE_INFO deviceInfo;
	public uint32 previousDeviceFlags;
}

[CRepr]
public struct BTH_L2CAP_EVENT_INFO
{
	public uint64 bthAddress;
	public uint16 psm;
	public uint8 connected;
	public uint8 initiated;
}

[CRepr]
public struct BTH_HCI_EVENT_INFO
{
	public uint64 bthAddress;
	public uint8 connectionType;
	public uint8 connected;
}

[CRepr]
public struct BLUETOOTH_ADDRESS_STRUCT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 ullLong;
		public uint8[6] rgBytes;
	}
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct BLUETOOTH_LOCAL_SERVICE_INFO_STRUCT
{
	public BOOL Enabled;
	public BLUETOOTH_ADDRESS_STRUCT btAddr;
	public char16[256] szName;
	public char16[256] szDeviceString;
}

[CRepr]
public struct BLUETOOTH_FIND_RADIO_PARAMS
{
	public uint32 dwSize;
}

[CRepr]
public struct BLUETOOTH_RADIO_INFO
{
	public uint32 dwSize;
	public BLUETOOTH_ADDRESS_STRUCT address;
	public char16[248] szName;
	public uint32 ulClassofDevice;
	public uint16 lmpSubversion;
	public uint16 manufacturer;
}

[CRepr]
public struct BLUETOOTH_DEVICE_INFO_STRUCT
{
	public uint32 dwSize;
	public BLUETOOTH_ADDRESS_STRUCT Address;
	public uint32 ulClassofDevice;
	public BOOL fConnected;
	public BOOL fRemembered;
	public BOOL fAuthenticated;
	public SYSTEMTIME stLastSeen;
	public SYSTEMTIME stLastUsed;
	public char16[248] szName;
}

[CRepr]
public struct BLUETOOTH_AUTHENTICATION_CALLBACK_PARAMS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 Numeric_Value;
		public uint32 Passkey;
	}
	public BLUETOOTH_DEVICE_INFO_STRUCT deviceInfo;
	public BLUETOOTH_AUTHENTICATION_METHOD authenticationMethod;
	public BLUETOOTH_IO_CAPABILITY ioCapability;
	public BLUETOOTH_AUTHENTICATION_REQUIREMENTS authenticationRequirements;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct BLUETOOTH_DEVICE_SEARCH_PARAMS
{
	public uint32 dwSize;
	public BOOL fReturnAuthenticated;
	public BOOL fReturnRemembered;
	public BOOL fReturnUnknown;
	public BOOL fReturnConnected;
	public BOOL fIssueInquiry;
	public uint8 cTimeoutMultiplier;
	public HANDLE hRadio;
}

[CRepr]
public struct BLUETOOTH_COD_PAIRS
{
	public uint32 ulCODMask;
	public PWSTR pcszDescription;
}

[CRepr]
public struct BLUETOOTH_SELECT_DEVICE_PARAMS
{
	public uint32 dwSize;
	public uint32 cNumOfClasses;
	public BLUETOOTH_COD_PAIRS* prgClassOfDevices;
	public PWSTR pszInfo;
	public HWND hwndParent;
	public BOOL fForceAuthentication;
	public BOOL fShowAuthenticated;
	public BOOL fShowRemembered;
	public BOOL fShowUnknown;
	public BOOL fAddNewDeviceWizard;
	public BOOL fSkipServicesPage;
	public PFN_DEVICE_CALLBACK pfnDeviceCallback;
	public void* pvParam;
	public uint32 cNumDevices;
	public BLUETOOTH_DEVICE_INFO_STRUCT* pDevices;
}

[CRepr]
public struct BLUETOOTH_PIN_INFO
{
	public uint8[16] pin;
	public uint8 pinLength;
}

[CRepr]
public struct BLUETOOTH_OOB_DATA_INFO
{
	public uint8[16] C;
	public uint8[16] R;
}

[CRepr]
public struct BLUETOOTH_NUMERIC_COMPARISON_INFO
{
	public uint32 NumericValue;
}

[CRepr]
public struct BLUETOOTH_PASSKEY_INFO
{
	public uint32 passkey;
}

[CRepr]
public struct BLUETOOTH_AUTHENTICATE_RESPONSE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public BLUETOOTH_PIN_INFO pinInfo;
		public BLUETOOTH_OOB_DATA_INFO oobInfo;
		public BLUETOOTH_NUMERIC_COMPARISON_INFO numericCompInfo;
		public BLUETOOTH_PASSKEY_INFO passkeyInfo;
	}
	public BLUETOOTH_ADDRESS_STRUCT bthAddressRemote;
	public BLUETOOTH_AUTHENTICATION_METHOD authMethod;
	public using _Anonymous_e__Union Anonymous;
	public uint8 negativeResponse;
}

[CRepr]
public struct SDP_ELEMENT_DATA
{
	[CRepr, Union]
	public struct _data_e__Union
	{
		[CRepr]
		public struct _alternative_e__Struct
		{
			public uint8* value;
			public uint32 length;
		}
		[CRepr]
		public struct _url_e__Struct
		{
			public uint8* value;
			public uint32 length;
		}
		[CRepr]
		public struct _string_e__Struct
		{
			public uint8* value;
			public uint32 length;
		}
		[CRepr]
		public struct _sequence_e__Struct
		{
			public uint8* value;
			public uint32 length;
		}
		public SDP_LARGE_INTEGER_16 int128;
		public int64 int64;
		public int32 int32;
		public int16 int16;
		public CHAR int8;
		public SDP_ULARGE_INTEGER_16 uint128;
		public uint64 uint64;
		public uint32 uint32;
		public uint16 uint16;
		public uint8 uint8;
		public uint8 booleanVal;
		public Guid uuid128;
		public uint32 uuid32;
		public uint16 uuid16;
		public _string_e__Struct string;
		public _url_e__Struct url;
		public _sequence_e__Struct sequence;
		public _alternative_e__Struct alternative;
	}
	public SDP_TYPE type;
	public SDP_SPECIFICTYPE specificType;
	public _data_e__Union data;
}

[CRepr]
public struct SDP_STRING_TYPE_DATA
{
	public uint16 encoding;
	public uint16 mibeNum;
	public uint16 attributeId;
}

[CRepr]
public struct BTH_LE_UUID
{
	[CRepr, Union]
	public struct _Value_e__Union
	{
		public uint16 ShortUuid;
		public Guid LongUuid;
	}
	public BOOLEAN IsShortUuid;
	public _Value_e__Union Value;
}

[CRepr]
public struct BTH_LE_GATT_SERVICE
{
	public BTH_LE_UUID ServiceUuid;
	public uint16 AttributeHandle;
}

[CRepr]
public struct BTH_LE_GATT_CHARACTERISTIC
{
	public uint16 ServiceHandle;
	public BTH_LE_UUID CharacteristicUuid;
	public uint16 AttributeHandle;
	public uint16 CharacteristicValueHandle;
	public BOOLEAN IsBroadcastable;
	public BOOLEAN IsReadable;
	public BOOLEAN IsWritable;
	public BOOLEAN IsWritableWithoutResponse;
	public BOOLEAN IsSignedWritable;
	public BOOLEAN IsNotifiable;
	public BOOLEAN IsIndicatable;
	public BOOLEAN HasExtendedProperties;
}

[CRepr]
public struct BTH_LE_GATT_CHARACTERISTIC_VALUE
{
	public uint32 DataSize;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct BTH_LE_GATT_DESCRIPTOR
{
	public uint16 ServiceHandle;
	public uint16 CharacteristicHandle;
	public BTH_LE_GATT_DESCRIPTOR_TYPE DescriptorType;
	public BTH_LE_UUID DescriptorUuid;
	public uint16 AttributeHandle;
}

[CRepr]
public struct BTH_LE_GATT_DESCRIPTOR_VALUE
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _ServerCharacteristicConfiguration_e__Struct
		{
			public BOOLEAN IsBroadcast;
		}
		[CRepr]
		public struct _CharacteristicExtendedProperties_e__Struct
		{
			public BOOLEAN IsReliableWriteEnabled;
			public BOOLEAN IsAuxiliariesWritable;
		}
		[CRepr]
		public struct _CharacteristicFormat_e__Struct
		{
			public uint8 Format;
			public uint8 Exponent;
			public BTH_LE_UUID Unit;
			public uint8 NameSpace;
			public BTH_LE_UUID Description;
		}
		[CRepr]
		public struct _ClientCharacteristicConfiguration_e__Struct
		{
			public BOOLEAN IsSubscribeToNotification;
			public BOOLEAN IsSubscribeToIndication;
		}
		public _CharacteristicExtendedProperties_e__Struct CharacteristicExtendedProperties;
		public _ClientCharacteristicConfiguration_e__Struct ClientCharacteristicConfiguration;
		public _ServerCharacteristicConfiguration_e__Struct ServerCharacteristicConfiguration;
		public _CharacteristicFormat_e__Struct CharacteristicFormat;
	}
	public BTH_LE_GATT_DESCRIPTOR_TYPE DescriptorType;
	public BTH_LE_UUID DescriptorUuid;
	public using _Anonymous_e__Union Anonymous;
	public uint32 DataSize;
	public uint8* Data mut => &Data_impl;
	private uint8[ANYSIZE_ARRAY] Data_impl;
}

[CRepr]
public struct BLUETOOTH_GATT_VALUE_CHANGED_EVENT_REGISTRATION
{
	public uint16 NumCharacteristics;
	public BTH_LE_GATT_CHARACTERISTIC* Characteristics mut => &Characteristics_impl;
	private BTH_LE_GATT_CHARACTERISTIC[ANYSIZE_ARRAY] Characteristics_impl;
}

[CRepr]
public struct BLUETOOTH_GATT_VALUE_CHANGED_EVENT
{
	public uint16 ChangedAttributeHandle;
	public uint CharacteristicValueDataSize;
	public BTH_LE_GATT_CHARACTERISTIC_VALUE* CharacteristicValue;
}

[CRepr, Packed(1)]
public struct SOCKADDR_BTH
{
	public uint16 addressFamily;
	public uint64 btAddr;
	public Guid serviceClassId;
	public uint32 port;
}

[CRepr, Packed(1)]
public struct BTH_SET_SERVICE
{
	public uint32* pSdpVersion;
	public HANDLE* pRecordHandle;
	public uint32 fCodService;
	public uint32[5] Reserved;
	public uint32 ulRecordLength;
	public uint8* pRecord mut => &pRecord_impl;
	private uint8[ANYSIZE_ARRAY] pRecord_impl;
}

[CRepr, Packed(1)]
public struct BTH_QUERY_DEVICE
{
	public uint32 LAP;
	public uint8 length;
}

[CRepr, Packed(1)]
public struct BTH_QUERY_SERVICE
{
	public uint32 type;
	public uint32 serviceHandle;
	public SdpQueryUuid[12] uuids;
	public uint32 numRange;
	public SdpAttributeRange* pRange mut => &pRange_impl;
	private SdpAttributeRange[ANYSIZE_ARRAY] pRange_impl;
}

[CRepr]
public struct RFCOMM_MSC_DATA
{
	public uint8 Signals;
	public uint8 Break;
}

[CRepr]
public struct RFCOMM_RLS_DATA
{
	public uint8 LineStatus;
}

[CRepr]
public struct RFCOMM_RPN_DATA
{
	public uint8 Baud;
	public uint8 Data;
	public uint8 FlowControl;
	public uint8 XonChar;
	public uint8 XoffChar;
	public uint8 ParameterMask1;
	public uint8 ParameterMask2;
}

[CRepr, Packed(1)]
public struct RFCOMM_COMMAND
{
	[CRepr, Union]
	public struct _Data_e__Union
	{
		public RFCOMM_MSC_DATA MSC;
		public RFCOMM_RLS_DATA RLS;
		public RFCOMM_RPN_DATA RPN;
	}
	public uint32 CmdType;
	public _Data_e__Union Data;
}

[CRepr, Packed(1)]
public struct BTH_PING_REQ
{
	public uint64 btAddr;
	public uint8 dataLen;
	public uint8[44] data;
}

[CRepr]
public struct BTH_PING_RSP
{
	public uint8 dataLen;
	public uint8[44] data;
}

[CRepr, Packed(1)]
public struct BTH_INFO_REQ
{
	public uint64 btAddr;
	public uint16 infoType;
}

[CRepr, Packed(1)]
public struct BTH_INFO_RSP
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint16 connectionlessMTU;
		public uint8[44] data;
	}
	public uint16 result;
	public uint8 dataLen;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region Functions
public static
{
	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int BluetoothFindFirstRadio(BLUETOOTH_FIND_RADIO_PARAMS* pbtfrp, HANDLE* phRadio);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothFindNextRadio(int hFind, HANDLE* phRadio);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothFindRadioClose(int hFind);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothGetRadioInfo(HANDLE hRadio, BLUETOOTH_RADIO_INFO* pRadioInfo);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int BluetoothFindFirstDevice(BLUETOOTH_DEVICE_SEARCH_PARAMS* pbtsp, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothFindNextDevice(int hFind, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothFindDeviceClose(int hFind);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothGetDeviceInfo(HANDLE hRadio, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothUpdateDeviceRecord(BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothRemoveDevice(BLUETOOTH_ADDRESS_STRUCT* pAddress);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothSelectDevices(BLUETOOTH_SELECT_DEVICE_PARAMS* pbtsdp);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothSelectDevicesFree(BLUETOOTH_SELECT_DEVICE_PARAMS* pbtsdp);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothDisplayDeviceProperties(HWND hwndParent, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothAuthenticateDevice(HWND hwndParent, HANDLE hRadio, BLUETOOTH_DEVICE_INFO_STRUCT* pbtbi, char16* pszPasskey, uint32 ulPasskeyLength);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothAuthenticateDeviceEx(HWND hwndParentIn, HANDLE hRadioIn, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdiInout, BLUETOOTH_OOB_DATA_INFO* pbtOobData, AUTHENTICATION_REQUIREMENTS authenticationRequirement);

	[Import("bthprops.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothAuthenticateMultipleDevices(HWND hwndParent, HANDLE hRadio, uint32 cDevices, BLUETOOTH_DEVICE_INFO_STRUCT* rgbtdi);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSetServiceState(HANDLE hRadio, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi, in Guid pGuidService, uint32 dwServiceFlags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothEnumerateInstalledServices(HANDLE hRadio, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi, uint32* pcServiceInout, Guid* pGuidServices);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothEnableDiscovery(HANDLE hRadio, BOOL fEnabled);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothIsDiscoverable(HANDLE hRadio);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothEnableIncomingConnections(HANDLE hRadio, BOOL fEnabled);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothIsConnectable(HANDLE hRadio);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothRegisterForAuthentication(BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi, int* phRegHandle, PFN_AUTHENTICATION_CALLBACK pfnCallback, void* pvParam);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothRegisterForAuthenticationEx(BLUETOOTH_DEVICE_INFO_STRUCT* pbtdiIn, int* phRegHandleOut, PFN_AUTHENTICATION_CALLBACK_EX pfnCallbackIn, void* pvParam);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothUnregisterAuthentication(int hRegHandle);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSendAuthenticationResponse(HANDLE hRadio, BLUETOOTH_DEVICE_INFO_STRUCT* pbtdi, PWSTR pszPasskey);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSendAuthenticationResponseEx(HANDLE hRadioIn, BLUETOOTH_AUTHENTICATE_RESPONSE* pauthResponse);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSdpGetElementData(uint8* pSdpStream, uint32 cbSdpStreamLength, SDP_ELEMENT_DATA* pData);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSdpGetContainerElementData(uint8* pContainerStream, uint32 cbContainerLength, int* pElement, SDP_ELEMENT_DATA* pData);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSdpGetAttributeValue(uint8* pRecordStream, uint32 cbRecordLength, uint16 usAttributeId, SDP_ELEMENT_DATA* pAttributeData);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSdpGetString(uint8* pRecordStream, uint32 cbRecordLength, SDP_STRING_TYPE_DATA* pStringData, uint16 usStringOffset, char16* pszString, uint32* pcchStringLength);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothSdpEnumAttributes(uint8* pSDPStream, uint32 cbStreamSize, PFN_BLUETOOTH_ENUM_ATTRIBUTES_CALLBACK pfnCallback, void* pvParam);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 BluetoothSetLocalServiceInfo(HANDLE hRadioIn, in Guid pClassGuid, uint32 ulInstance, BLUETOOTH_LOCAL_SERVICE_INFO_STRUCT* pServiceInfoIn);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL BluetoothIsVersionAvailable(uint8 MajorVersion, uint8 MinorVersion);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetServices(HANDLE hDevice, uint16 ServicesBufferCount, BTH_LE_GATT_SERVICE* ServicesBuffer, uint16* ServicesBufferActual, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetIncludedServices(HANDLE hDevice, BTH_LE_GATT_SERVICE* ParentService, uint16 IncludedServicesBufferCount, BTH_LE_GATT_SERVICE* IncludedServicesBuffer, uint16* IncludedServicesBufferActual, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetCharacteristics(HANDLE hDevice, BTH_LE_GATT_SERVICE* Service, uint16 CharacteristicsBufferCount, BTH_LE_GATT_CHARACTERISTIC* CharacteristicsBuffer, uint16* CharacteristicsBufferActual, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetDescriptors(HANDLE hDevice, BTH_LE_GATT_CHARACTERISTIC* Characteristic, uint16 DescriptorsBufferCount, BTH_LE_GATT_DESCRIPTOR* DescriptorsBuffer, uint16* DescriptorsBufferActual, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetCharacteristicValue(HANDLE hDevice, BTH_LE_GATT_CHARACTERISTIC* Characteristic, uint32 CharacteristicValueDataSize, BTH_LE_GATT_CHARACTERISTIC_VALUE* CharacteristicValue, uint16* CharacteristicValueSizeRequired, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTGetDescriptorValue(HANDLE hDevice, BTH_LE_GATT_DESCRIPTOR* Descriptor, uint32 DescriptorValueDataSize, BTH_LE_GATT_DESCRIPTOR_VALUE* DescriptorValue, uint16* DescriptorValueSizeRequired, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTBeginReliableWrite(HANDLE hDevice, uint64* ReliableWriteContext, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTSetCharacteristicValue(HANDLE hDevice, BTH_LE_GATT_CHARACTERISTIC* Characteristic, BTH_LE_GATT_CHARACTERISTIC_VALUE* CharacteristicValue, uint64 ReliableWriteContext, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTEndReliableWrite(HANDLE hDevice, uint64 ReliableWriteContext, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTAbortReliableWrite(HANDLE hDevice, uint64 ReliableWriteContext, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTSetDescriptorValue(HANDLE hDevice, BTH_LE_GATT_DESCRIPTOR* Descriptor, BTH_LE_GATT_DESCRIPTOR_VALUE* DescriptorValue, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTRegisterEvent(HANDLE hService, BTH_LE_GATT_EVENT_TYPE EventType, void* EventParameterIn, PFNBLUETOOTH_GATT_EVENT_CALLBACK Callback, void* CallbackContext, int* pEventHandle, uint32 Flags);

	[Import("BluetoothApis.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT BluetoothGATTUnregisterEvent(int EventHandle, uint32 Flags);

}
#endregion
