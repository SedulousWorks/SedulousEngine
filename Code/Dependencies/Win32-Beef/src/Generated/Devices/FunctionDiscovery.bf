using Win32.UI.Shell.PropertiesSystem;
using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using System;

namespace Win32.Devices.FunctionDiscovery;

#region Constants
public static
{
	public const uint32 FD_EVENTID_PRIVATE = 100;
	public const uint32 FD_EVENTID = 1000;
	public const uint32 FD_EVENTID_SEARCHCOMPLETE = 1000;
	public const uint32 FD_EVENTID_ASYNCTHREADEXIT = 1001;
	public const uint32 FD_EVENTID_SEARCHSTART = 1002;
	public const uint32 FD_EVENTID_IPADDRESSCHANGE = 1003;
	public const uint32 FD_EVENTID_QUERYREFRESH = 1004;
	public const Guid SID_PnpProvider = .(0x8101368e, 0xcabb, 0x4426, 0xac, 0xff, 0x96, 0xc4, 0x10, 0x81, 0x20, 0x00);
	public const Guid SID_UPnPActivator = .(0x0d0d66eb, 0xcf74, 0x4164, 0xb5, 0x2f, 0x08, 0x34, 0x46, 0x72, 0xdd, 0x46);
	public const Guid SID_EnumInterface = .(0x40eab0b9, 0x4d7f, 0x4b53, 0xa3, 0x34, 0x15, 0x81, 0xdd, 0x90, 0x41, 0xf4);
	public const Guid SID_PNPXPropertyStore = .(0xa86530b1, 0x542f, 0x439f, 0xb7, 0x1c, 0xb0, 0x75, 0x6b, 0x13, 0x67, 0x7a);
	public const Guid SID_PNPXAssociation = .(0xcee8ccc9, 0x4f6b, 0x4469, 0xa2, 0x35, 0x5a, 0x22, 0x86, 0x9e, 0xef, 0x03);
	public const Guid SID_PNPXServiceCollection = .(0x439e80ee, 0xa217, 0x4712, 0x9f, 0xa6, 0xde, 0xab, 0xd9, 0xc2, 0xa7, 0x27);
	public const Guid SID_FDPairingHandler = .(0x383b69fa, 0x5486, 0x49da, 0x91, 0xf5, 0xd6, 0x3c, 0x24, 0xc8, 0xe9, 0xd0);
	public const Guid SID_EnumDeviceFunction = .(0x13e0e9e2, 0xc3fa, 0x4e3c, 0x90, 0x6e, 0x64, 0x50, 0x2f, 0xa4, 0xdc, 0x95);
	public const Guid SID_UnpairProvider = .(0x89a502fc, 0x857b, 0x4698, 0xa0, 0xb7, 0x02, 0x71, 0x92, 0x00, 0x2f, 0x9e);
	public const Guid SID_DeviceDisplayStatusManager = .(0xf59aa553, 0x8309, 0x46ca, 0x97, 0x36, 0x1a, 0xc3, 0xc6, 0x2d, 0x60, 0x31);
	public const Guid SID_FunctionDiscoveryProviderRefresh = .(0x2b4cbdc9, 0x31c4, 0x40d4, 0xa6, 0x2d, 0x77, 0x2a, 0xa1, 0x74, 0xed, 0x52);
	public const Guid SID_UninstallDeviceFunction = .(0xc920566e, 0x5671, 0x4496, 0x80, 0x25, 0xbf, 0x0b, 0x89, 0xbd, 0x44, 0xcd);
	public const PROPERTYKEY PKEY_FunctionInstance = .(.(0x08c0c253, 0xa154, 0x4746, 0x90, 0x05, 0x82, 0xde, 0x53, 0x17, 0x14, 0x8b), 1);
	public const Guid FMTID_FD = .(0x904b03a2, 0x471d, 0x423c, 0xa5, 0x84, 0xf3, 0x48, 0x32, 0x38, 0xa1, 0x46);
	public const uint32 FD_Visibility_Default = 0;
	public const uint32 FD_Visibility_Hidden = 1;
	public const Guid FMTID_Device = .(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57);
	public const Guid FMTID_DeviceInterface = .(0x53808008, 0x07bb, 0x4661, 0xbc, 0x3c, 0xb5, 0x95, 0x3e, 0x70, 0x85, 0x60);
	public const PROPERTYKEY PKEY_DeviceDisplay_Address = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 51);
	public const PROPERTYKEY PKEY_DeviceDisplay_DiscoveryMethod = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 52);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsEncrypted = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 53);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsAuthenticated = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 54);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsConnected = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 55);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsPaired = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 56);
	public const PROPERTYKEY PKEY_DeviceDisplay_Icon = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 57);
	public const PROPERTYKEY PKEY_DeviceDisplay_Version = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 65);
	public const PROPERTYKEY PKEY_DeviceDisplay_Last_Seen = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 66);
	public const PROPERTYKEY PKEY_DeviceDisplay_Last_Connected = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 67);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsShowInDisconnectedState = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 68);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsLocalMachine = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 70);
	public const PROPERTYKEY PKEY_DeviceDisplay_MetadataPath = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 71);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsMetadataSearchInProgress = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 72);
	public const PROPERTYKEY PKEY_DeviceDisplay_MetadataChecksum = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 73);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsNotInterestingForDisplay = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 74);
	public const PROPERTYKEY PKEY_DeviceDisplay_LaunchDeviceStageOnDeviceConnect = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 76);
	public const PROPERTYKEY PKEY_DeviceDisplay_LaunchDeviceStageFromExplorer = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 77);
	public const PROPERTYKEY PKEY_DeviceDisplay_BaselineExperienceId = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 78);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsDeviceUniquelyIdentifiable = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 79);
	public const PROPERTYKEY PKEY_DeviceDisplay_AssociationArray = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 80);
	public const PROPERTYKEY PKEY_DeviceDisplay_DeviceDescription1 = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 81);
	public const PROPERTYKEY PKEY_DeviceDisplay_DeviceDescription2 = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 82);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsNotWorkingProperly = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 83);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsSharedDevice = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 84);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsNetworkDevice = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 85);
	public const PROPERTYKEY PKEY_DeviceDisplay_IsDefaultDevice = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 86);
	public const PROPERTYKEY PKEY_DeviceDisplay_MetadataCabinet = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 87);
	public const PROPERTYKEY PKEY_DeviceDisplay_RequiresPairingElevation = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 88);
	public const PROPERTYKEY PKEY_DeviceDisplay_ExperienceId = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 89);
	public const PROPERTYKEY PKEY_DeviceDisplay_Category = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 90);
	public const PROPERTYKEY PKEY_DeviceDisplay_Category_Desc_Singular = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 91);
	public const PROPERTYKEY PKEY_DeviceDisplay_Category_Desc_Plural = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 92);
	public const PROPERTYKEY PKEY_DeviceDisplay_Category_Icon = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 93);
	public const PROPERTYKEY PKEY_DeviceDisplay_CategoryGroup_Desc = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 94);
	public const PROPERTYKEY PKEY_DeviceDisplay_CategoryGroup_Icon = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 95);
	public const PROPERTYKEY PKEY_DeviceDisplay_PrimaryCategory = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 97);
	public const PROPERTYKEY PKEY_DeviceDisplay_UnpairUninstall = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 98);
	public const PROPERTYKEY PKEY_DeviceDisplay_RequiresUninstallElevation = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 99);
	public const PROPERTYKEY PKEY_DeviceDisplay_DeviceFunctionSubRank = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 100);
	public const PROPERTYKEY PKEY_DeviceDisplay_AlwaysShowDeviceAsConnected = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 101);
	public const PROPERTYKEY PKEY_DeviceDisplay_FriendlyName = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12288);
	public const PROPERTYKEY PKEY_DeviceDisplay_Manufacturer = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8192);
	public const PROPERTYKEY PKEY_DeviceDisplay_ModelName = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8194);
	public const PROPERTYKEY PKEY_DeviceDisplay_ModelNumber = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8195);
	public const PROPERTYKEY PKEY_DeviceDisplay_InstallInProgress = .(.(0x83da6326, 0x97a6, 0x4088, 0x94, 0x53, 0xa1, 0x92, 0x3f, 0x57, 0x3b, 0x29), 9);
	public const Guid FMTID_Pairing = .(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc);
	public const PROPERTYKEY PKEY_Pairing_ListItemText = .(.(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc), 1);
	public const PROPERTYKEY PKEY_Pairing_ListItemDescription = .(.(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc), 2);
	public const PROPERTYKEY PKEY_Pairing_ListItemIcon = .(.(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc), 3);
	public const PROPERTYKEY PKEY_Pairing_ListItemDefault = .(.(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc), 4);
	public const PROPERTYKEY PKEY_Pairing_IsWifiOnlyDevice = .(.(0x8807cae6, 0x7db6, 0x4f10, 0x8e, 0xe4, 0x43, 0x5e, 0xaa, 0x13, 0x92, 0xbc), 16);
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_BLUETOOTH = "Bluetooth";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_BLUETOOTH_LE = "Bluetooth Low Energy";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_NETBIOS = "NetBIOS";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_AD_PRINTER = "Published Printer";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_PNP = "PnP";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_UPNP = "UPnP";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_WSD = "WSD";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_WUSB = "WUSB";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_WFD = "WiFiDirect";
	public const String DEVICEDISPLAY_DISCOVERYMETHOD_ASP_INFRA = "AspInfra";
	public const PROPERTYKEY PKEY_Device_BIOSVersion = .(.(0xeaee7f1d, 0x6a33, 0x44d1, 0x94, 0x41, 0x5f, 0x46, 0xde, 0xf2, 0x31, 0x98), 9);
	public const Guid FMTID_WSD = .(0x92506491, 0xff95, 0x4724, 0xa0, 0x5a, 0x5b, 0x81, 0x88, 0x5a, 0x7c, 0x92);
	public const Guid FMTID_PNPX = .(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd);
	public const PROPERTYKEY PKEY_PNPX_GlobalIdentity = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4096);
	public const PROPERTYKEY PKEY_PNPX_Types = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4097);
	public const PROPERTYKEY PKEY_PNPX_Scopes = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4098);
	public const PROPERTYKEY PKEY_PNPX_XAddrs = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4099);
	public const PROPERTYKEY PKEY_PNPX_MetadataVersion = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4100);
	public const PROPERTYKEY PKEY_PNPX_ID = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4101);
	public const PROPERTYKEY PKEY_PNPX_RemoteAddress = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4102);
	public const PROPERTYKEY PKEY_PNPX_RootProxy = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 4103);
	public const PROPERTYKEY PKEY_PNPX_ManufacturerUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8193);
	public const PROPERTYKEY PKEY_PNPX_ModelUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8196);
	public const PROPERTYKEY PKEY_PNPX_Upc = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8197);
	public const PROPERTYKEY PKEY_PNPX_PresentationUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 8198);
	public const PROPERTYKEY PKEY_PNPX_FirmwareVersion = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12289);
	public const PROPERTYKEY PKEY_PNPX_SerialNumber = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12290);
	public const PROPERTYKEY PKEY_PNPX_DeviceCategory = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12292);
	public const PROPERTYKEY PKEY_PNPX_SecureChannel = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 28673);
	public const PROPERTYKEY PKEY_PNPX_CompactSignature = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 28674);
	public const PROPERTYKEY PKEY_PNPX_DeviceCertHash = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 28675);
	public const String PNPX_DEVICECATEGORY_COMPUTER = "Computers";
	public const String PNPX_DEVICECATEGORY_INPUTDEVICE = "Input";
	public const String PNPX_DEVICECATEGORY_PRINTER = "Printers";
	public const String PNPX_DEVICECATEGORY_SCANNER = "Scanners";
	public const String PNPX_DEVICECATEGORY_FAX = "FAX";
	public const String PNPX_DEVICECATEGORY_MFP = "MFP";
	public const String PNPX_DEVICECATEGORY_CAMERA = "Cameras";
	public const String PNPX_DEVICECATEGORY_STORAGE = "Storage";
	public const String PNPX_DEVICECATEGORY_NETWORK_INFRASTRUCTURE = "NetworkInfrastructure";
	public const String PNPX_DEVICECATEGORY_DISPLAYS = "Displays";
	public const String PNPX_DEVICECATEGORY_MULTIMEDIA_DEVICE = "MediaDevices";
	public const String PNPX_DEVICECATEGORY_GAMING_DEVICE = "Gaming";
	public const String PNPX_DEVICECATEGORY_TELEPHONE = "Phones";
	public const String PNPX_DEVICECATEGORY_HOME_AUTOMATION_SYSTEM = "HomeAutomation";
	public const String PNPX_DEVICECATEGORY_HOME_SECURITY_SYSTEM = "HomeSecurity";
	public const String PNPX_DEVICECATEGORY_OTHER = "Other";
	public const PROPERTYKEY PKEY_PNPX_DeviceCategory_Desc = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12293);
	public const PROPERTYKEY PKEY_PNPX_Category_Desc_NonPlural = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12304);
	public const PROPERTYKEY PKEY_PNPX_PhysicalAddress = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12294);
	public const PROPERTYKEY PKEY_PNPX_NetworkInterfaceLuid = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12295);
	public const PROPERTYKEY PKEY_PNPX_NetworkInterfaceGuid = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12296);
	public const PROPERTYKEY PKEY_PNPX_IpAddress = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 12297);
	public const PROPERTYKEY PKEY_PNPX_ServiceAddress = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16384);
	public const PROPERTYKEY PKEY_PNPX_ServiceId = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16385);
	public const PROPERTYKEY PKEY_PNPX_ServiceTypes = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16386);
	public const PROPERTYKEY PKEY_PNPX_ServiceControlUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16388);
	public const PROPERTYKEY PKEY_PNPX_ServiceDescUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16389);
	public const PROPERTYKEY PKEY_PNPX_ServiceEventSubUrl = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 16390);
	public const PROPERTYKEY PKEY_PNPX_DomainName = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 20480);
	public const PROPERTYKEY PKEY_PNPX_ShareName = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 20482);
	public const PROPERTYKEY PKEY_SSDP_AltLocationInfo = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 24576);
	public const PROPERTYKEY PKEY_SSDP_DevLifeTime = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 24577);
	public const PROPERTYKEY PKEY_SSDP_NetworkInterface = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 24578);
	public const Guid FMTID_PNPXDynamicProperty = .(0x4fc5077e, 0xb686, 0x44be, 0x93, 0xe3, 0x86, 0xca, 0xfe, 0x36, 0x8c, 0xcd);
	public const PROPERTYKEY PKEY_PNPX_Installable = .(.(0x4fc5077e, 0xb686, 0x44be, 0x93, 0xe3, 0x86, 0xca, 0xfe, 0x36, 0x8c, 0xcd), 1);
	public const PROPERTYKEY PKEY_PNPX_Associated = .(.(0x4fc5077e, 0xb686, 0x44be, 0x93, 0xe3, 0x86, 0xca, 0xfe, 0x36, 0x8c, 0xcd), 2);
	public const PROPERTYKEY PKEY_PNPX_CompatibleTypes = .(.(0x4fc5077e, 0xb686, 0x44be, 0x93, 0xe3, 0x86, 0xca, 0xfe, 0x36, 0x8c, 0xcd), 3);
	public const PROPERTYKEY PKEY_PNPX_InstallState = .(.(0x4fc5077e, 0xb686, 0x44be, 0x93, 0xe3, 0x86, 0xca, 0xfe, 0x36, 0x8c, 0xcd), 4);
	public const uint32 PNPX_INSTALLSTATE_NOTINSTALLED = 0;
	public const uint32 PNPX_INSTALLSTATE_INSTALLED = 1;
	public const uint32 PNPX_INSTALLSTATE_INSTALLING = 2;
	public const uint32 PNPX_INSTALLSTATE_FAILED = 3;
	public const PROPERTYKEY PKEY_PNPX_Removable = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 28672);
	public const PROPERTYKEY PKEY_PNPX_IPBusEnumerated = .(.(0x656a3bb3, 0xecc0, 0x43fd, 0x84, 0x77, 0x4a, 0xe0, 0x40, 0x4a, 0x96, 0xcd), 28688);
	public const PROPERTYKEY PKEY_WNET_Scope = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 1);
	public const PROPERTYKEY PKEY_WNET_Type = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 2);
	public const PROPERTYKEY PKEY_WNET_DisplayType = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 3);
	public const PROPERTYKEY PKEY_WNET_Usage = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 4);
	public const PROPERTYKEY PKEY_WNET_LocalName = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 5);
	public const PROPERTYKEY PKEY_WNET_RemoteName = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 6);
	public const PROPERTYKEY PKEY_WNET_Comment = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 7);
	public const PROPERTYKEY PKEY_WNET_Provider = .(.(0xdebda43a, 0x37b3, 0x4383, 0x91, 0xe7, 0x44, 0x98, 0xda, 0x29, 0x95, 0xab), 8);
	public const PROPERTYKEY PKEY_WCN_Version = .(.(0x88190b80, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 1);
	public const PROPERTYKEY PKEY_WCN_RequestType = .(.(0x88190b81, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 2);
	public const PROPERTYKEY PKEY_WCN_AuthType = .(.(0x88190b82, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 3);
	public const PROPERTYKEY PKEY_WCN_EncryptType = .(.(0x88190b83, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 4);
	public const PROPERTYKEY PKEY_WCN_ConnType = .(.(0x88190b84, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 5);
	public const PROPERTYKEY PKEY_WCN_ConfigMethods = .(.(0x88190b85, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 6);
	public const PROPERTYKEY PKEY_WCN_RfBand = .(.(0x88190b87, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 8);
	public const PROPERTYKEY PKEY_WCN_AssocState = .(.(0x88190b88, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 9);
	public const PROPERTYKEY PKEY_WCN_ConfigError = .(.(0x88190b89, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 10);
	public const PROPERTYKEY PKEY_WCN_ConfigState = .(.(0x88190b89, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 11);
	public const PROPERTYKEY PKEY_WCN_DevicePasswordId = .(.(0x88190b89, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 12);
	public const PROPERTYKEY PKEY_WCN_OSVersion = .(.(0x88190b89, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 13);
	public const PROPERTYKEY PKEY_WCN_VendorExtension = .(.(0x88190b8a, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 14);
	public const PROPERTYKEY PKEY_WCN_RegistrarType = .(.(0x88190b8b, 0x4684, 0x11da, 0xa2, 0x6a, 0x00, 0x02, 0xb3, 0x98, 0x8e, 0x81), 15);
	public const PROPERTYKEY PKEY_Hardware_Devinst = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 4097);
	public const PROPERTYKEY PKEY_Hardware_DisplayAttribute = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 5);
	public const PROPERTYKEY PKEY_Hardware_DriverDate = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 11);
	public const PROPERTYKEY PKEY_Hardware_DriverProvider = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 10);
	public const PROPERTYKEY PKEY_Hardware_DriverVersion = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 9);
	public const PROPERTYKEY PKEY_Hardware_Function = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 4099);
	public const PROPERTYKEY PKEY_Hardware_Icon = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 3);
	public const PROPERTYKEY PKEY_Hardware_Image = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 4098);
	public const PROPERTYKEY PKEY_Hardware_Manufacturer = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 6);
	public const PROPERTYKEY PKEY_Hardware_Model = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 7);
	public const PROPERTYKEY PKEY_Hardware_Name = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 2);
	public const PROPERTYKEY PKEY_Hardware_SerialNumber = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 8);
	public const PROPERTYKEY PKEY_Hardware_ShellAttributes = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 4100);
	public const PROPERTYKEY PKEY_Hardware_Status = .(.(0x5eaf3ef2, 0xe0ca, 0x4598, 0xbf, 0x06, 0x71, 0xed, 0x1d, 0x9d, 0xd9, 0x53), 4096);
	public const PROPERTYKEY PKEY_NAME = .(.(0xb725f130, 0x47ef, 0x101a, 0xa5, 0xf1, 0x02, 0x60, 0x8c, 0x9e, 0xeb, 0xac), 10);
	public const PROPERTYKEY PKEY_Device_DeviceDesc = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 2);
	public const PROPERTYKEY PKEY_Device_HardwareIds = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 3);
	public const PROPERTYKEY PKEY_Device_CompatibleIds = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 4);
	public const PROPERTYKEY PKEY_Device_Service = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 6);
	public const PROPERTYKEY PKEY_Device_Class = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 9);
	public const PROPERTYKEY PKEY_Device_ClassGuid = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 10);
	public const PROPERTYKEY PKEY_Device_Driver = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 11);
	public const PROPERTYKEY PKEY_Device_ConfigFlags = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 12);
	public const PROPERTYKEY PKEY_Device_Manufacturer = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 13);
	public const PROPERTYKEY PKEY_Device_FriendlyName = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 14);
	public const PROPERTYKEY PKEY_Device_LocationInfo = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 15);
	public const PROPERTYKEY PKEY_Device_PDOName = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 16);
	public const PROPERTYKEY PKEY_Device_Capabilities = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 17);
	public const PROPERTYKEY PKEY_Device_UINumber = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 18);
	public const PROPERTYKEY PKEY_Device_UpperFilters = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 19);
	public const PROPERTYKEY PKEY_Device_LowerFilters = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 20);
	public const PROPERTYKEY PKEY_Device_BusTypeGuid = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 21);
	public const PROPERTYKEY PKEY_Device_LegacyBusType = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 22);
	public const PROPERTYKEY PKEY_Device_BusNumber = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 23);
	public const PROPERTYKEY PKEY_Device_EnumeratorName = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 24);
	public const PROPERTYKEY PKEY_Device_Security = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 25);
	public const PROPERTYKEY PKEY_Device_SecuritySDS = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 26);
	public const PROPERTYKEY PKEY_Device_DevType = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 27);
	public const PROPERTYKEY PKEY_Device_Exclusive = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 28);
	public const PROPERTYKEY PKEY_Device_Characteristics = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 29);
	public const PROPERTYKEY PKEY_Device_Address = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 30);
	public const PROPERTYKEY PKEY_Device_UINumberDescFormat = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 31);
	public const PROPERTYKEY PKEY_Device_PowerData = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 32);
	public const PROPERTYKEY PKEY_Device_RemovalPolicy = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 33);
	public const PROPERTYKEY PKEY_Device_RemovalPolicyDefault = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 34);
	public const PROPERTYKEY PKEY_Device_RemovalPolicyOverride = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 35);
	public const PROPERTYKEY PKEY_Device_InstallState = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 36);
	public const PROPERTYKEY PKEY_Device_LocationPaths = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 37);
	public const PROPERTYKEY PKEY_Device_BaseContainerId = .(.(0xa45c254e, 0xdf1c, 0x4efd, 0x80, 0x20, 0x67, 0xd1, 0x46, 0xa8, 0x50, 0xe0), 38);
	public const PROPERTYKEY PKEY_Device_DevNodeStatus = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 2);
	public const PROPERTYKEY PKEY_Device_ProblemCode = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 3);
	public const PROPERTYKEY PKEY_Device_EjectionRelations = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 4);
	public const PROPERTYKEY PKEY_Device_RemovalRelations = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 5);
	public const PROPERTYKEY PKEY_Device_PowerRelations = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 6);
	public const PROPERTYKEY PKEY_Device_BusRelations = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 7);
	public const PROPERTYKEY PKEY_Device_Parent = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 8);
	public const PROPERTYKEY PKEY_Device_Children = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 9);
	public const PROPERTYKEY PKEY_Device_Siblings = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 10);
	public const PROPERTYKEY PKEY_Device_TransportRelations = .(.(0x4340a6c5, 0x93fa, 0x4706, 0x97, 0x2c, 0x7b, 0x64, 0x80, 0x08, 0xa5, 0xa7), 11);
	public const PROPERTYKEY PKEY_Device_Reported = .(.(0x80497100, 0x8c73, 0x48b9, 0xaa, 0xd9, 0xce, 0x38, 0x7e, 0x19, 0xc5, 0x6e), 2);
	public const PROPERTYKEY PKEY_Device_Legacy = .(.(0x80497100, 0x8c73, 0x48b9, 0xaa, 0xd9, 0xce, 0x38, 0x7e, 0x19, 0xc5, 0x6e), 3);
	public const PROPERTYKEY PKEY_Device_InstanceId = .(.(0x78c34fc8, 0x104a, 0x4aca, 0x9e, 0xa4, 0x52, 0x4d, 0x52, 0x99, 0x6e, 0x57), 256);
	public const PROPERTYKEY PKEY_Device_ContainerId = .(.(0x8c7ed206, 0x3f8a, 0x4827, 0xb3, 0xab, 0xae, 0x9e, 0x1f, 0xae, 0xfc, 0x6c), 2);
	public const PROPERTYKEY PKEY_Device_ModelId = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 2);
	public const PROPERTYKEY PKEY_Device_FriendlyNameAttributes = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 3);
	public const PROPERTYKEY PKEY_Device_ManufacturerAttributes = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 4);
	public const PROPERTYKEY PKEY_Device_PresenceNotForDevice = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 5);
	public const PROPERTYKEY PKEY_Device_SignalStrength = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 6);
	public const PROPERTYKEY PKEY_Device_IsAssociateableByUserAction = .(.(0x80d81ea6, 0x7473, 0x4b0c, 0x82, 0x16, 0xef, 0xc1, 0x1a, 0x2c, 0x4c, 0x8b), 7);
	public const PROPERTYKEY PKEY_Numa_Proximity_Domain = .(.(0x540b947e, 0x8b40, 0x45bc, 0xa8, 0xa2, 0x6a, 0x0b, 0x89, 0x4c, 0xbd, 0xa2), 1);
	public const PROPERTYKEY PKEY_Device_DHP_Rebalance_Policy = .(.(0x540b947e, 0x8b40, 0x45bc, 0xa8, 0xa2, 0x6a, 0x0b, 0x89, 0x4c, 0xbd, 0xa2), 2);
	public const PROPERTYKEY PKEY_Device_Numa_Node = .(.(0x540b947e, 0x8b40, 0x45bc, 0xa8, 0xa2, 0x6a, 0x0b, 0x89, 0x4c, 0xbd, 0xa2), 3);
	public const PROPERTYKEY PKEY_Device_BusReportedDeviceDesc = .(.(0x540b947e, 0x8b40, 0x45bc, 0xa8, 0xa2, 0x6a, 0x0b, 0x89, 0x4c, 0xbd, 0xa2), 4);
	public const PROPERTYKEY PKEY_Device_InstallInProgress = .(.(0x83da6326, 0x97a6, 0x4088, 0x94, 0x53, 0xa1, 0x92, 0x3f, 0x57, 0x3b, 0x29), 9);
	public const PROPERTYKEY PKEY_Device_DriverDate = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 2);
	public const PROPERTYKEY PKEY_Device_DriverVersion = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 3);
	public const PROPERTYKEY PKEY_Device_DriverDesc = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 4);
	public const PROPERTYKEY PKEY_Device_DriverInfPath = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 5);
	public const PROPERTYKEY PKEY_Device_DriverInfSection = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 6);
	public const PROPERTYKEY PKEY_Device_DriverInfSectionExt = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 7);
	public const PROPERTYKEY PKEY_Device_MatchingDeviceId = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 8);
	public const PROPERTYKEY PKEY_Device_DriverProvider = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 9);
	public const PROPERTYKEY PKEY_Device_DriverPropPageProvider = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 10);
	public const PROPERTYKEY PKEY_Device_DriverCoInstallers = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 11);
	public const PROPERTYKEY PKEY_Device_ResourcePickerTags = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 12);
	public const PROPERTYKEY PKEY_Device_ResourcePickerExceptions = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 13);
	public const PROPERTYKEY PKEY_Device_DriverRank = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 14);
	public const PROPERTYKEY PKEY_Device_DriverLogoLevel = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 15);
	public const PROPERTYKEY PKEY_Device_NoConnectSound = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 17);
	public const PROPERTYKEY PKEY_Device_GenericDriverInstalled = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 18);
	public const PROPERTYKEY PKEY_Device_AdditionalSoftwareRequested = .(.(0xa8b865dd, 0x2e3d, 0x4094, 0xad, 0x97, 0xe5, 0x93, 0xa7, 0x0c, 0x75, 0xd6), 19);
	public const PROPERTYKEY PKEY_Device_SafeRemovalRequired = .(.(0xafd97640, 0x86a3, 0x4210, 0xb6, 0x7c, 0x28, 0x9c, 0x41, 0xaa, 0xbe, 0x55), 2);
	public const PROPERTYKEY PKEY_Device_SafeRemovalRequiredOverride = .(.(0xafd97640, 0x86a3, 0x4210, 0xb6, 0x7c, 0x28, 0x9c, 0x41, 0xaa, 0xbe, 0x55), 3);
	public const PROPERTYKEY PKEY_DrvPkg_Model = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 2);
	public const PROPERTYKEY PKEY_DrvPkg_VendorWebSite = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 3);
	public const PROPERTYKEY PKEY_DrvPkg_DetailedDescription = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 4);
	public const PROPERTYKEY PKEY_DrvPkg_DocumentationLink = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 5);
	public const PROPERTYKEY PKEY_DrvPkg_Icon = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 6);
	public const PROPERTYKEY PKEY_DrvPkg_BrandingIcon = .(.(0xcf73bb51, 0x3abf, 0x44a2, 0x85, 0xe0, 0x9a, 0x3d, 0xc7, 0xa1, 0x21, 0x32), 7);
	public const PROPERTYKEY PKEY_DeviceClass_UpperFilters = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 19);
	public const PROPERTYKEY PKEY_DeviceClass_LowerFilters = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 20);
	public const PROPERTYKEY PKEY_DeviceClass_Security = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 25);
	public const PROPERTYKEY PKEY_DeviceClass_SecuritySDS = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 26);
	public const PROPERTYKEY PKEY_DeviceClass_DevType = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 27);
	public const PROPERTYKEY PKEY_DeviceClass_Exclusive = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 28);
	public const PROPERTYKEY PKEY_DeviceClass_Characteristics = .(.(0x4321918b, 0xf69e, 0x470d, 0xa5, 0xde, 0x4d, 0x88, 0xc7, 0x5a, 0xd2, 0x4b), 29);
	public const PROPERTYKEY PKEY_DeviceClass_Name = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 2);
	public const PROPERTYKEY PKEY_DeviceClass_ClassName = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 3);
	public const PROPERTYKEY PKEY_DeviceClass_Icon = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 4);
	public const PROPERTYKEY PKEY_DeviceClass_ClassInstaller = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 5);
	public const PROPERTYKEY PKEY_DeviceClass_PropPageProvider = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 6);
	public const PROPERTYKEY PKEY_DeviceClass_NoInstallClass = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 7);
	public const PROPERTYKEY PKEY_DeviceClass_NoDisplayClass = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 8);
	public const PROPERTYKEY PKEY_DeviceClass_SilentInstall = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 9);
	public const PROPERTYKEY PKEY_DeviceClass_NoUseClass = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 10);
	public const PROPERTYKEY PKEY_DeviceClass_DefaultService = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 11);
	public const PROPERTYKEY PKEY_DeviceClass_IconPath = .(.(0x259abffc, 0x50a7, 0x47ce, 0xaf, 0x08, 0x68, 0xc9, 0xa7, 0xd7, 0x33, 0x66), 12);
	public const PROPERTYKEY PKEY_DeviceClass_ClassCoInstallers = .(.(0x713d1703, 0xa2e2, 0x49f5, 0x92, 0x14, 0x56, 0x47, 0x2e, 0xf3, 0xda, 0x5c), 2);
	public const PROPERTYKEY PKEY_DeviceInterface_FriendlyName = .(.(0x026e516e, 0xb814, 0x414b, 0x83, 0xcd, 0x85, 0x6d, 0x6f, 0xef, 0x48, 0x22), 2);
	public const PROPERTYKEY PKEY_DeviceInterface_Enabled = .(.(0x026e516e, 0xb814, 0x414b, 0x83, 0xcd, 0x85, 0x6d, 0x6f, 0xef, 0x48, 0x22), 3);
	public const PROPERTYKEY PKEY_DeviceInterface_ClassGuid = .(.(0x026e516e, 0xb814, 0x414b, 0x83, 0xcd, 0x85, 0x6d, 0x6f, 0xef, 0x48, 0x22), 4);
	public const PROPERTYKEY PKEY_DeviceInterfaceClass_DefaultInterface = .(.(0x14c83a99, 0x0b3f, 0x44b7, 0xbe, 0x4c, 0xa1, 0x78, 0xd3, 0x99, 0x05, 0x64), 2);
	public const uint32 FD_LONGHORN = 1;
	public const String FD_SUBKEY = "SOFTWARE\\Microsoft\\Function Discovery\\";
	public const String FCTN_CATEGORY_PNP = "Provider\\Microsoft.Base.PnP";
	public const String FCTN_CATEGORY_REGISTRY = "Provider\\Microsoft.Base.Registry";
	public const String FCTN_CATEGORY_SSDP = "Provider\\Microsoft.Networking.SSDP";
	public const String FCTN_CATEGORY_WSDISCOVERY = "Provider\\Microsoft.Networking.WSD";
	public const String FCTN_CATEGORY_NETBIOS = "Provider\\Microsoft.Networking.Netbios";
	public const String FCTN_CATEGORY_WCN = "Provider\\Microsoft.Networking.WCN";
	public const String FCTN_CATEGORY_PUBLICATION = "Provider\\Microsoft.Base.Publication";
	public const String FCTN_CATEGORY_PNPXASSOCIATION = "Provider\\Microsoft.PnPX.Association";
	public const String FCTN_CATEGORY_BT = "Provider\\Microsoft.Devices.Bluetooth";
	public const String FCTN_CATEGORY_WUSB = "Provider\\Microsoft.Devices.WirelessUSB";
	public const String FCTN_CATEGORY_DEVICEDISPLAYOBJECTS = "Provider\\Microsoft.Base.DeviceDisplayObjects";
	public const String FCTN_CATEGORY_DEVQUERYOBJECTS = "Provider\\Microsoft.Base.DevQueryObjects";
	public const String FCTN_CATEGORY_NETWORKDEVICES = "Layered\\Microsoft.Networking.Devices";
	public const String FCTN_CATEGORY_DEVICES = "Layered\\Microsoft.Base.Devices";
	public const String FCTN_CATEGORY_DEVICEFUNCTIONENUMERATORS = "Layered\\Microsoft.Devices.FunctionEnumerators";
	public const String FCTN_CATEGORY_DEVICEPAIRING = "Layered\\Microsoft.Base.DevicePairing";
	public const String FCTN_SUBCAT_DEVICES_WSDPRINTERS = "WSDPrinters";
	public const String FCTN_SUBCAT_NETWORKDEVICES_SSDP = "SSDP";
	public const String FCTN_SUBCAT_NETWORKDEVICES_WSD = "WSD";
	public const String FCTN_SUBCAT_REG_PUBLICATION = "Publication";
	public const String FCTN_SUBCAT_REG_DIRECTED = "Directed";
	public const uint32 MAX_FDCONSTRAINTNAME_LENGTH = 100;
	public const uint32 MAX_FDCONSTRAINTVALUE_LENGTH = 1000;
	public const String FD_QUERYCONSTRAINT_PROVIDERINSTANCEID = "ProviderInstanceID";
	public const String FD_QUERYCONSTRAINT_SUBCATEGORY = "Subcategory";
	public const String FD_QUERYCONSTRAINT_RECURSESUBCATEGORY = "RecurseSubcategory";
	public const String FD_QUERYCONSTRAINT_VISIBILITY = "Visibility";
	public const String FD_QUERYCONSTRAINT_COMCLSCONTEXT = "COMClsContext";
	public const String FD_QUERYCONSTRAINT_ROUTINGSCOPE = "RoutingScope";
	public const String FD_CONSTRAINTVALUE_TRUE = "TRUE";
	public const String FD_CONSTRAINTVALUE_FALSE = "FALSE";
	public const String FD_CONSTRAINTVALUE_RECURSESUBCATEGORY_TRUE = "TRUE";
	public const String FD_CONSTRAINTVALUE_VISIBILITY_DEFAULT = "0";
	public const String FD_CONSTRAINTVALUE_VISIBILITY_ALL = "1";
	public const String FD_CONSTRAINTVALUE_COMCLSCONTEXT_INPROC_SERVER = "1";
	public const String FD_CONSTRAINTVALUE_COMCLSCONTEXT_LOCAL_SERVER = "4";
	public const String FD_CONSTRAINTVALUE_PAIRED = "Paired";
	public const String FD_CONSTRAINTVALUE_UNPAIRED = "UnPaired";
	public const String FD_CONSTRAINTVALUE_ALL = "All";
	public const String FD_CONSTRAINTVALUE_ROUTINGSCOPE_ALL = "All";
	public const String FD_CONSTRAINTVALUE_ROUTINGSCOPE_DIRECT = "Direct";
	public const String FD_QUERYCONSTRAINT_PAIRING_STATE = "PairingState";
	public const String FD_QUERYCONSTRAINT_INQUIRY_TIMEOUT = "InquiryModeTimeout";
	public const String PROVIDERPNP_QUERYCONSTRAINT_INTERFACECLASS = "InterfaceClass";
	public const String PROVIDERPNP_QUERYCONSTRAINT_NOTPRESENT = "NotPresent";
	public const String PROVIDERPNP_QUERYCONSTRAINT_NOTIFICATIONSONLY = "NotifyOnly";
	public const String PNP_CONSTRAINTVALUE_NOTPRESENT = "TRUE";
	public const String PNP_CONSTRAINTVALUE_NOTIFICATIONSONLY = "TRUE";
	public const String PROVIDERSSDP_QUERYCONSTRAINT_TYPE = "Type";
	public const String PROVIDERSSDP_QUERYCONSTRAINT_CUSTOMXMLPROPERTY = "CustomXmlProperty";
	public const String SSDP_CONSTRAINTVALUE_TYPE_ALL = "ssdp:all";
	public const String SSDP_CONSTRAINTVALUE_TYPE_ROOT = "upnp:rootdevice";
	public const String SSDP_CONSTRAINTVALUE_TYPE_DEVICE_PREFIX = "urn:schemas-upnp-org:device:";
	public const String SSDP_CONSTRAINTVALUE_TYPE_SVC_PREFIX = "urn:schemas-upnp-org:service:";
	public const String PROVIDERWSD_QUERYCONSTRAINT_DIRECTEDADDRESS = "RemoteAddress";
	public const String PROVIDERWSD_QUERYCONSTRAINT_TYPE = "Type";
	public const String PROVIDERWSD_QUERYCONSTRAINT_SCOPE = "Scope";
	public const String PROVIDERWSD_QUERYCONSTRAINT_SECURITY_REQUIREMENTS = "SecurityRequirements";
	public const String PROVIDERWSD_QUERYCONSTRAINT_SSL_CERT_FOR_CLIENT_AUTH = "SSLClientAuthCert";
	public const String PROVIDERWSD_QUERYCONSTRAINT_SSL_CERTHASH_FOR_SERVER_AUTH = "SSLServerAuthCertHash";
	public const String WSD_CONSTRAINTVALUE_REQUIRE_SECURECHANNEL = "1";
	public const String WSD_CONSTRAINTVALUE_REQUIRE_SECURECHANNEL_AND_COMPACTSIGNATURE = "2";
	public const String WSD_CONSTRAINTVALUE_NO_TRUST_VERIFICATION = "3";
	public const String PROVIDERWNET_QUERYCONSTRAINT_TYPE = "Type";
	public const String PROVIDERWNET_QUERYCONSTRAINT_PROPERTIES = "Properties";
	public const String PROVIDERWNET_QUERYCONSTRAINT_RESOURCETYPE = "ResourceType";
	public const String WNET_CONSTRAINTVALUE_TYPE_ALL = "All";
	public const String WNET_CONSTRAINTVALUE_TYPE_SERVER = "Server";
	public const String WNET_CONSTRAINTVALUE_TYPE_DOMAIN = "Domain";
	public const String WNET_CONSTRAINTVALUE_PROPERTIES_ALL = "All";
	public const String WNET_CONSTRAINTVALUE_PROPERTIES_LIMITED = "Limited";
	public const String WNET_CONSTRAINTVALUE_RESOURCETYPE_DISK = "Disk";
	public const String WNET_CONSTRAINTVALUE_RESOURCETYPE_PRINTER = "Printer";
	public const String WNET_CONSTRAINTVALUE_RESOURCETYPE_DISKORPRINTER = "DiskOrPrinter";
	public const String ONLINE_PROVIDER_DEVICES_QUERYCONSTRAINT_OWNERNAME = "OwnerName";
	public const String PROVIDERDDO_QUERYCONSTRAINT_DEVICEFUNCTIONDISPLAYOBJECTS = "DeviceFunctionDisplayObjects";
	public const String PROVIDERDDO_QUERYCONSTRAINT_ONLYCONNECTEDDEVICES = "OnlyConnectedDevices";
	public const String PROVIDERDDO_QUERYCONSTRAINT_DEVICEINTERFACES = "DeviceInterfaces";
	public const HRESULT E_FDPAIRING_NOCONNECTION = -1882193919;
	public const HRESULT E_FDPAIRING_HWFAILURE = -1882193918;
	public const HRESULT E_FDPAIRING_AUTHFAILURE = -1882193917;
	public const HRESULT E_FDPAIRING_CONNECTTIMEOUT = -1882193916;
	public const HRESULT E_FDPAIRING_TOOMANYCONNECTIONS = -1882193915;
	public const HRESULT E_FDPAIRING_AUTHNOTALLOWED = -1882193914;
	public const HRESULT E_FDPAIRING_IPBUSDISABLED = -1882193913;
	public const HRESULT E_FDPAIRING_NOPROFILES = -1882193912;
}
#endregion

#region Enums

[AllowDuplicates]
public enum PropertyConstraint : int32
{
	QC_EQUALS = 0,
	QC_NOTEQUAL = 1,
	QC_LESSTHAN = 2,
	QC_LESSTHANOREQUAL = 3,
	QC_GREATERTHAN = 4,
	QC_GREATERTHANOREQUAL = 5,
	QC_STARTSWITH = 6,
	QC_EXISTS = 7,
	QC_DOESNOTEXIST = 8,
	QC_CONTAINS = 9,
}


[AllowDuplicates]
public enum SystemVisibilityFlags : int32
{
	SVF_SYSTEM = 0,
	SVF_USER = 1,
}


[AllowDuplicates]
public enum QueryUpdateAction : int32
{
	QUA_ADD = 0,
	QUA_REMOVE = 1,
	QUA_CHANGE = 2,
}


[AllowDuplicates]
public enum QueryCategoryType : int32
{
	QCT_PROVIDER = 0,
	QCT_LAYERED = 1,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_PNPXAssociation = .(0xcee8ccc9, 0x4f6b, 0x4469, 0xa2, 0x35, 0x5a, 0x22, 0x86, 0x9e, 0xef, 0x03);


	public const Guid CLSID_PNPXPairingHandler = .(0xb8a27942, 0xade7, 0x4085, 0xaa, 0x6e, 0x4f, 0xad, 0xc7, 0xad, 0xa1, 0xef);


	public const Guid CLSID_FunctionDiscovery = .(0xc72be2ec, 0x8e90, 0x452c, 0xb2, 0x9a, 0xab, 0x8f, 0xf1, 0xc0, 0x71, 0xfc);


	public const Guid CLSID_PropertyStore = .(0xe4796550, 0xdf61, 0x448b, 0x91, 0x93, 0x13, 0xfc, 0x13, 0x41, 0xb1, 0x63);


	public const Guid CLSID_FunctionInstanceCollection = .(0xba818ce5, 0xb55f, 0x443f, 0xad, 0x39, 0x2f, 0xe8, 0x9b, 0xe6, 0x19, 0x1f);


	public const Guid CLSID_PropertyStoreCollection = .(0xedd36029, 0xd753, 0x4862, 0xaa, 0x5b, 0x5b, 0xcc, 0xad, 0x2a, 0x4d, 0x29);


}
#endregion

#region COM Types
[CRepr]struct IFunctionDiscoveryNotification : IUnknown
{
	public new const Guid IID = .(0x5f6c1ba8, 0x5330, 0x422e, 0xa3, 0x68, 0x57, 0x2b, 0x24, 0x4d, 0x3f, 0x87);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, QueryUpdateAction enumQueryUpdateAction, uint64 fdqcQueryContext, IFunctionInstance* pIFunctionInstance) OnUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, uint64 fdqcQueryContext, PWSTR pszProvider) OnError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwEventID, uint64 fdqcQueryContext, PWSTR pszProvider) OnEvent;
	}


	public HRESULT OnUpdate(QueryUpdateAction enumQueryUpdateAction, uint64 fdqcQueryContext, IFunctionInstance* pIFunctionInstance) mut => VT.[Friend]OnUpdate(&this, enumQueryUpdateAction, fdqcQueryContext, pIFunctionInstance);

	public HRESULT OnError(HRESULT hr, uint64 fdqcQueryContext, PWSTR pszProvider) mut => VT.[Friend]OnError(&this, hr, fdqcQueryContext, pszProvider);

	public HRESULT OnEvent(uint32 dwEventID, uint64 fdqcQueryContext, PWSTR pszProvider) mut => VT.[Friend]OnEvent(&this, dwEventID, fdqcQueryContext, pszProvider);
}

[CRepr]struct IFunctionDiscovery : IUnknown
{
	public new const Guid IID = .(0x4df99b70, 0xe148, 0x4432, 0xb0, 0x04, 0x4c, 0x9e, 0xeb, 0x53, 0x5a, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategory, PWSTR pszSubCategory, BOOL fIncludeAllSubCategories, IFunctionInstanceCollection** ppIFunctionInstanceCollection) GetInstanceCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFunctionInstanceIdentity, IFunctionInstance** ppIFunctionInstance) GetInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategory, PWSTR pszSubCategory, BOOL fIncludeAllSubCategories, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint64* pfdqcQueryContext, IFunctionInstanceCollectionQuery** ppIFunctionInstanceCollectionQuery) CreateInstanceCollectionQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFunctionInstanceIdentity, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint64* pfdqcQueryContext, IFunctionInstanceQuery** ppIFunctionInstanceQuery) CreateInstanceQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemVisibilityFlags enumSystemVisibility, PWSTR pszCategory, PWSTR pszSubCategory, PWSTR pszCategoryIdentity, IFunctionInstance** ppIFunctionInstance) AddInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemVisibilityFlags enumSystemVisibility, PWSTR pszCategory, PWSTR pszSubCategory, PWSTR pszCategoryIdentity) RemoveInstance;
	}


	public HRESULT GetInstanceCollection(PWSTR pszCategory, PWSTR pszSubCategory, BOOL fIncludeAllSubCategories, IFunctionInstanceCollection** ppIFunctionInstanceCollection) mut => VT.[Friend]GetInstanceCollection(&this, pszCategory, pszSubCategory, fIncludeAllSubCategories, ppIFunctionInstanceCollection);

	public HRESULT GetInstance(PWSTR pszFunctionInstanceIdentity, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]GetInstance(&this, pszFunctionInstanceIdentity, ppIFunctionInstance);

	public HRESULT CreateInstanceCollectionQuery(PWSTR pszCategory, PWSTR pszSubCategory, BOOL fIncludeAllSubCategories, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint64* pfdqcQueryContext, IFunctionInstanceCollectionQuery** ppIFunctionInstanceCollectionQuery) mut => VT.[Friend]CreateInstanceCollectionQuery(&this, pszCategory, pszSubCategory, fIncludeAllSubCategories, pIFunctionDiscoveryNotification, pfdqcQueryContext, ppIFunctionInstanceCollectionQuery);

	public HRESULT CreateInstanceQuery(PWSTR pszFunctionInstanceIdentity, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint64* pfdqcQueryContext, IFunctionInstanceQuery** ppIFunctionInstanceQuery) mut => VT.[Friend]CreateInstanceQuery(&this, pszFunctionInstanceIdentity, pIFunctionDiscoveryNotification, pfdqcQueryContext, ppIFunctionInstanceQuery);

	public HRESULT AddInstance(SystemVisibilityFlags enumSystemVisibility, PWSTR pszCategory, PWSTR pszSubCategory, PWSTR pszCategoryIdentity, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]AddInstance(&this, enumSystemVisibility, pszCategory, pszSubCategory, pszCategoryIdentity, ppIFunctionInstance);

	public HRESULT RemoveInstance(SystemVisibilityFlags enumSystemVisibility, PWSTR pszCategory, PWSTR pszSubCategory, PWSTR pszCategoryIdentity) mut => VT.[Friend]RemoveInstance(&this, enumSystemVisibility, pszCategory, pszSubCategory, pszCategoryIdentity);
}

[CRepr]struct IFunctionInstance : IServiceProvider
{
	public new const Guid IID = .(0x33591c10, 0x0bed, 0x4f02, 0xb0, 0xab, 0x15, 0x30, 0xd5, 0x53, 0x3e, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IServiceProvider.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppszCoMemIdentity) GetID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppszCoMemProviderInstanceIdentity) GetProviderInstanceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, STGM dwStgAccess, IPropertyStore** ppIPropertyStore) OpenPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppszCoMemCategory, uint16** ppszCoMemSubCategory) GetCategory;
	}


	public HRESULT GetID(uint16** ppszCoMemIdentity) mut => VT.[Friend]GetID(&this, ppszCoMemIdentity);

	public HRESULT GetProviderInstanceID(uint16** ppszCoMemProviderInstanceIdentity) mut => VT.[Friend]GetProviderInstanceID(&this, ppszCoMemProviderInstanceIdentity);

	public HRESULT OpenPropertyStore(STGM dwStgAccess, IPropertyStore** ppIPropertyStore) mut => VT.[Friend]OpenPropertyStore(&this, dwStgAccess, ppIPropertyStore);

	public HRESULT GetCategory(uint16** ppszCoMemCategory, uint16** ppszCoMemSubCategory) mut => VT.[Friend]GetCategory(&this, ppszCoMemCategory, ppszCoMemSubCategory);
}

[CRepr]struct IFunctionInstanceCollection : IUnknown
{
	public new const Guid IID = .(0xf0a3d895, 0x855c, 0x42a2, 0x94, 0x8d, 0x2f, 0x97, 0xd4, 0x50, 0xec, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszInstanceIdentity, uint32* pdwIndex, IFunctionInstance** ppIFunctionInstance) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IFunctionInstance** ppIFunctionInstance) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IFunctionInstance** ppIFunctionInstance) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteAll;
	}


	public HRESULT GetCount(uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pdwCount);

	public HRESULT Get(PWSTR pszInstanceIdentity, uint32* pdwIndex, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]Get(&this, pszInstanceIdentity, pdwIndex, ppIFunctionInstance);

	public HRESULT Item(uint32 dwIndex, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]Item(&this, dwIndex, ppIFunctionInstance);

	public HRESULT Add(IFunctionInstance* pIFunctionInstance) mut => VT.[Friend]Add(&this, pIFunctionInstance);

	public HRESULT Remove(uint32 dwIndex, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]Remove(&this, dwIndex, ppIFunctionInstance);

	public HRESULT Delete(uint32 dwIndex) mut => VT.[Friend]Delete(&this, dwIndex);

	public HRESULT DeleteAll() mut => VT.[Friend]DeleteAll(&this);
}

[CRepr]struct IPropertyStoreCollection : IUnknown
{
	public new const Guid IID = .(0xd14d9c30, 0x12d2, 0x42d8, 0xbc, 0xe4, 0xc6, 0x0c, 0x2b, 0xb2, 0x26, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszInstanceIdentity, uint32* pdwIndex, IPropertyStore** ppIPropertyStore) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IPropertyStore** ppIPropertyStore) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pIPropertyStore) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IPropertyStore** pIPropertyStore) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteAll;
	}


	public HRESULT GetCount(uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pdwCount);

	public HRESULT Get(PWSTR pszInstanceIdentity, uint32* pdwIndex, IPropertyStore** ppIPropertyStore) mut => VT.[Friend]Get(&this, pszInstanceIdentity, pdwIndex, ppIPropertyStore);

	public HRESULT Item(uint32 dwIndex, IPropertyStore** ppIPropertyStore) mut => VT.[Friend]Item(&this, dwIndex, ppIPropertyStore);

	public HRESULT Add(IPropertyStore* pIPropertyStore) mut => VT.[Friend]Add(&this, pIPropertyStore);

	public HRESULT Remove(uint32 dwIndex, IPropertyStore** pIPropertyStore) mut => VT.[Friend]Remove(&this, dwIndex, pIPropertyStore);

	public HRESULT Delete(uint32 dwIndex) mut => VT.[Friend]Delete(&this, dwIndex);

	public HRESULT DeleteAll() mut => VT.[Friend]DeleteAll(&this);
}

[CRepr]struct IFunctionInstanceQuery : IUnknown
{
	public new const Guid IID = .(0x6242bc6b, 0x90ec, 0x4b37, 0xbb, 0x46, 0xe2, 0x29, 0xfd, 0x84, 0xed, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance** ppIFunctionInstance) Execute;
	}


	public HRESULT Execute(IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]Execute(&this, ppIFunctionInstance);
}

[CRepr]struct IFunctionInstanceCollectionQuery : IUnknown
{
	public new const Guid IID = .(0x57cc6fd2, 0xc09a, 0x4289, 0xbb, 0x72, 0x25, 0xf0, 0x41, 0x42, 0x05, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszConstraintName, PWSTR pszConstraintValue) AddQueryConstraint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Key, PROPVARIANT* pv, PropertyConstraint enumPropertyConstraint) AddPropertyConstraint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstanceCollection** ppIFunctionInstanceCollection) Execute;
	}


	public HRESULT AddQueryConstraint(PWSTR pszConstraintName, PWSTR pszConstraintValue) mut => VT.[Friend]AddQueryConstraint(&this, pszConstraintName, pszConstraintValue);

	public HRESULT AddPropertyConstraint(PROPERTYKEY* Key, PROPVARIANT* pv, PropertyConstraint enumPropertyConstraint) mut => VT.[Friend]AddPropertyConstraint(&this, Key, pv, enumPropertyConstraint);

	public HRESULT Execute(IFunctionInstanceCollection** ppIFunctionInstanceCollection) mut => VT.[Friend]Execute(&this, ppIFunctionInstanceCollection);
}

[CRepr]struct IFunctionDiscoveryProvider : IUnknown
{
	public new const Guid IID = .(0xdcde394f, 0x1478, 0x4813, 0xa4, 0x02, 0xf6, 0xfb, 0x10, 0x65, 0x72, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionDiscoveryProviderFactory* pIFunctionDiscoveryProviderFactory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint32 lcidUserDefault, uint32* pdwStgAccessCapabilities) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionDiscoveryProviderQuery* pIFunctionDiscoveryProviderQuery, IFunctionInstanceCollection** ppIFunctionInstanceCollection) Query;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwStgAccess) InstancePropertyStoreValidateAccess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwStgAccess, IPropertyStore** ppIPropertyStore) InstancePropertyStoreOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext) InstancePropertyStoreFlush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, in Guid guidService, in Guid riid, IUnknown** ppIUnknown) InstanceQueryService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext) InstanceReleased;
	}


	public HRESULT Initialize(IFunctionDiscoveryProviderFactory* pIFunctionDiscoveryProviderFactory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification, uint32 lcidUserDefault, uint32* pdwStgAccessCapabilities) mut => VT.[Friend]Initialize(&this, pIFunctionDiscoveryProviderFactory, pIFunctionDiscoveryNotification, lcidUserDefault, pdwStgAccessCapabilities);

	public HRESULT Query(IFunctionDiscoveryProviderQuery* pIFunctionDiscoveryProviderQuery, IFunctionInstanceCollection** ppIFunctionInstanceCollection) mut => VT.[Friend]Query(&this, pIFunctionDiscoveryProviderQuery, ppIFunctionInstanceCollection);

	public HRESULT EndQuery() mut => VT.[Friend]EndQuery(&this);

	public HRESULT InstancePropertyStoreValidateAccess(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwStgAccess) mut => VT.[Friend]InstancePropertyStoreValidateAccess(&this, pIFunctionInstance, iProviderInstanceContext, dwStgAccess);

	public HRESULT InstancePropertyStoreOpen(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwStgAccess, IPropertyStore** ppIPropertyStore) mut => VT.[Friend]InstancePropertyStoreOpen(&this, pIFunctionInstance, iProviderInstanceContext, dwStgAccess, ppIPropertyStore);

	public HRESULT InstancePropertyStoreFlush(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext) mut => VT.[Friend]InstancePropertyStoreFlush(&this, pIFunctionInstance, iProviderInstanceContext);

	public HRESULT InstanceQueryService(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, in Guid guidService, in Guid riid, IUnknown** ppIUnknown) mut => VT.[Friend]InstanceQueryService(&this, pIFunctionInstance, iProviderInstanceContext, guidService, riid, ppIUnknown);

	public HRESULT InstanceReleased(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext) mut => VT.[Friend]InstanceReleased(&this, pIFunctionInstance, iProviderInstanceContext);
}

[CRepr]struct IProviderProperties : IUnknown
{
	public new const Guid IID = .(0xcf986ea6, 0x3b5f, 0x4c5f, 0xb8, 0x8a, 0x2f, 0x8b, 0x20, 0xce, 0xef, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwIndex, PROPERTYKEY* pKey) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, PROPERTYKEY* Key, PROPVARIANT* ppropVar) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, PROPERTYKEY* Key, PROPVARIANT* ppropVar) SetValue;
	}


	public HRESULT GetCount(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pIFunctionInstance, iProviderInstanceContext, pdwCount);

	public HRESULT GetAt(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, uint32 dwIndex, PROPERTYKEY* pKey) mut => VT.[Friend]GetAt(&this, pIFunctionInstance, iProviderInstanceContext, dwIndex, pKey);

	public HRESULT GetValue(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, PROPERTYKEY* Key, PROPVARIANT* ppropVar) mut => VT.[Friend]GetValue(&this, pIFunctionInstance, iProviderInstanceContext, Key, ppropVar);

	public HRESULT SetValue(IFunctionInstance* pIFunctionInstance, int iProviderInstanceContext, PROPERTYKEY* Key, PROPVARIANT* ppropVar) mut => VT.[Friend]SetValue(&this, pIFunctionInstance, iProviderInstanceContext, Key, ppropVar);
}

[CRepr]struct IProviderPublishing : IUnknown
{
	public new const Guid IID = .(0xcd1b9a04, 0x206c, 0x4a05, 0xa0, 0xc8, 0x16, 0x35, 0xa2, 0x1a, 0x2b, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemVisibilityFlags enumVisibilityFlags, PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity, IFunctionInstance** ppIFunctionInstance) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SystemVisibilityFlags enumVisibilityFlags, PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity) RemoveInstance;
	}


	public HRESULT CreateInstance(SystemVisibilityFlags enumVisibilityFlags, PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]CreateInstance(&this, enumVisibilityFlags, pszSubCategory, pszProviderInstanceIdentity, ppIFunctionInstance);

	public HRESULT RemoveInstance(SystemVisibilityFlags enumVisibilityFlags, PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity) mut => VT.[Friend]RemoveInstance(&this, enumVisibilityFlags, pszSubCategory, pszProviderInstanceIdentity);
}

[CRepr]struct IFunctionDiscoveryProviderFactory : IUnknown
{
	public new const Guid IID = .(0x86443ff0, 0x1ad5, 0x4e68, 0xa4, 0x5a, 0x40, 0xc2, 0xc3, 0x29, 0xde, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppIPropertyStore) CreatePropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity, int iProviderInstanceContext, IPropertyStore* pIPropertyStore, IFunctionDiscoveryProvider* pIFunctionDiscoveryProvider, IFunctionInstance** ppIFunctionInstance) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstanceCollection** ppIFunctionInstanceCollection) CreateFunctionInstanceCollection;
	}


	public HRESULT CreatePropertyStore(IPropertyStore** ppIPropertyStore) mut => VT.[Friend]CreatePropertyStore(&this, ppIPropertyStore);

	public HRESULT CreateInstance(PWSTR pszSubCategory, PWSTR pszProviderInstanceIdentity, int iProviderInstanceContext, IPropertyStore* pIPropertyStore, IFunctionDiscoveryProvider* pIFunctionDiscoveryProvider, IFunctionInstance** ppIFunctionInstance) mut => VT.[Friend]CreateInstance(&this, pszSubCategory, pszProviderInstanceIdentity, iProviderInstanceContext, pIPropertyStore, pIFunctionDiscoveryProvider, ppIFunctionInstance);

	public HRESULT CreateFunctionInstanceCollection(IFunctionInstanceCollection** ppIFunctionInstanceCollection) mut => VT.[Friend]CreateFunctionInstanceCollection(&this, ppIFunctionInstanceCollection);
}

[CRepr]struct IFunctionDiscoveryProviderQuery : IUnknown
{
	public new const Guid IID = .(0x6876ea98, 0xbaec, 0x46db, 0xbc, 0x20, 0x75, 0xa7, 0x6e, 0x26, 0x7a, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pisInstanceQuery, uint16** ppszConstraintValue) IsInstanceQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pisSubcategoryQuery, uint16** ppszConstraintValue) IsSubcategoryQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IProviderQueryConstraintCollection** ppIProviderQueryConstraints) GetQueryConstraints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IProviderPropertyConstraintCollection** ppIProviderPropertyConstraints) GetPropertyConstraints;
	}


	public HRESULT IsInstanceQuery(BOOL* pisInstanceQuery, uint16** ppszConstraintValue) mut => VT.[Friend]IsInstanceQuery(&this, pisInstanceQuery, ppszConstraintValue);

	public HRESULT IsSubcategoryQuery(BOOL* pisSubcategoryQuery, uint16** ppszConstraintValue) mut => VT.[Friend]IsSubcategoryQuery(&this, pisSubcategoryQuery, ppszConstraintValue);

	public HRESULT GetQueryConstraints(IProviderQueryConstraintCollection** ppIProviderQueryConstraints) mut => VT.[Friend]GetQueryConstraints(&this, ppIProviderQueryConstraints);

	public HRESULT GetPropertyConstraints(IProviderPropertyConstraintCollection** ppIProviderPropertyConstraints) mut => VT.[Friend]GetPropertyConstraints(&this, ppIProviderPropertyConstraints);
}

[CRepr]struct IProviderQueryConstraintCollection : IUnknown
{
	public new const Guid IID = .(0x9c243e11, 0x3261, 0x4bcd, 0xb9, 0x22, 0x84, 0xa8, 0x73, 0xd4, 0x60, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszConstraintName, uint16** ppszConstraintValue) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, uint16** ppszConstraintName, uint16** ppszConstraintValue) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppszConstraintName, uint16** ppszConstraintValue) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT GetCount(uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pdwCount);

	public HRESULT Get(PWSTR pszConstraintName, uint16** ppszConstraintValue) mut => VT.[Friend]Get(&this, pszConstraintName, ppszConstraintValue);

	public HRESULT Item(uint32 dwIndex, uint16** ppszConstraintName, uint16** ppszConstraintValue) mut => VT.[Friend]Item(&this, dwIndex, ppszConstraintName, ppszConstraintValue);

	public HRESULT Next(uint16** ppszConstraintName, uint16** ppszConstraintValue) mut => VT.[Friend]Next(&this, ppszConstraintName, ppszConstraintValue);

	public HRESULT Skip() mut => VT.[Friend]Skip(&this);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IProviderPropertyConstraintCollection : IUnknown
{
	public new const Guid IID = .(0xf4fae42f, 0x5778, 0x4a13, 0x85, 0x40, 0xb5, 0xfd, 0x8c, 0x13, 0x98, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Key, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) Get;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PROPERTYKEY* pKey, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pKey, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT GetCount(uint32* pdwCount) mut => VT.[Friend]GetCount(&this, pdwCount);

	public HRESULT Get(PROPERTYKEY* Key, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) mut => VT.[Friend]Get(&this, Key, pPropVar, pdwPropertyConstraint);

	public HRESULT Item(uint32 dwIndex, PROPERTYKEY* pKey, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) mut => VT.[Friend]Item(&this, dwIndex, pKey, pPropVar, pdwPropertyConstraint);

	public HRESULT Next(PROPERTYKEY* pKey, PROPVARIANT* pPropVar, uint32* pdwPropertyConstraint) mut => VT.[Friend]Next(&this, pKey, pPropVar, pdwPropertyConstraint);

	public HRESULT Skip() mut => VT.[Friend]Skip(&this);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IFunctionDiscoveryServiceProvider : IUnknown
{
	public new const Guid IID = .(0x4c81ed02, 0x1b04, 0x43f2, 0xa4, 0x51, 0x69, 0x96, 0x6c, 0xbc, 0xd1, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFunctionInstance* pIFunctionInstance, in Guid riid, void** ppv) Initialize;
	}


	public HRESULT Initialize(IFunctionInstance* pIFunctionInstance, in Guid riid, void** ppv) mut => VT.[Friend]Initialize(&this, pIFunctionInstance, riid, ppv);
}

[CRepr]struct IPNPXAssociation : IUnknown
{
	public new const Guid IID = .(0x0bd7e521, 0x4da6, 0x42d5, 0x81, 0xba, 0x19, 0x81, 0xb6, 0xb9, 0x40, 0x75);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubcategory) Associate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubcategory) Unassociate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubcategory) Delete;
	}


	public HRESULT Associate(PWSTR pszSubcategory) mut => VT.[Friend]Associate(&this, pszSubcategory);

	public HRESULT Unassociate(PWSTR pszSubcategory) mut => VT.[Friend]Unassociate(&this, pszSubcategory);

	public HRESULT Delete(PWSTR pszSubcategory) mut => VT.[Friend]Delete(&this, pszSubcategory);
}

[CRepr]struct IPNPXDeviceAssociation : IUnknown
{
	public new const Guid IID = .(0xeed366d0, 0x35b8, 0x4fc5, 0x8d, 0x20, 0x7e, 0x5b, 0xd3, 0x1f, 0x6d, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubCategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) Associate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubCategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) Unassociate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubcategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) Delete;
	}


	public HRESULT Associate(PWSTR pszSubCategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) mut => VT.[Friend]Associate(&this, pszSubCategory, pIFunctionDiscoveryNotification);

	public HRESULT Unassociate(PWSTR pszSubCategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) mut => VT.[Friend]Unassociate(&this, pszSubCategory, pIFunctionDiscoveryNotification);

	public HRESULT Delete(PWSTR pszSubcategory, IFunctionDiscoveryNotification* pIFunctionDiscoveryNotification) mut => VT.[Friend]Delete(&this, pszSubcategory, pIFunctionDiscoveryNotification);
}

#endregion
