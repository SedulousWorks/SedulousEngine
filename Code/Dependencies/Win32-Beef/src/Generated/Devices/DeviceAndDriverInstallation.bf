using Win32.System.Diagnostics.Debug;
using Win32.Foundation;
using Win32.UI.Controls;
using Win32.System.Registry;
using Win32.Devices.Properties;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using Win32.Data.HtmlHelp;
using System;

namespace Win32.Devices.DeviceAndDriverInstallation;

#region Constants
public static
{
	public const uint32 CM_PROB_NOT_CONFIGURED = 1;
	public const uint32 CM_PROB_DEVLOADER_FAILED = 2;
	public const uint32 CM_PROB_OUT_OF_MEMORY = 3;
	public const uint32 CM_PROB_ENTRY_IS_WRONG_TYPE = 4;
	public const uint32 CM_PROB_LACKED_ARBITRATOR = 5;
	public const uint32 CM_PROB_BOOT_CONFIG_CONFLICT = 6;
	public const uint32 CM_PROB_FAILED_FILTER = 7;
	public const uint32 CM_PROB_DEVLOADER_NOT_FOUND = 8;
	public const uint32 CM_PROB_INVALID_DATA = 9;
	public const uint32 CM_PROB_FAILED_START = 10;
	public const uint32 CM_PROB_LIAR = 11;
	public const uint32 CM_PROB_NORMAL_CONFLICT = 12;
	public const uint32 CM_PROB_NOT_VERIFIED = 13;
	public const uint32 CM_PROB_NEED_RESTART = 14;
	public const uint32 CM_PROB_REENUMERATION = 15;
	public const uint32 CM_PROB_PARTIAL_LOG_CONF = 16;
	public const uint32 CM_PROB_UNKNOWN_RESOURCE = 17;
	public const uint32 CM_PROB_REINSTALL = 18;
	public const uint32 CM_PROB_REGISTRY = 19;
	public const uint32 CM_PROB_VXDLDR = 20;
	public const uint32 CM_PROB_WILL_BE_REMOVED = 21;
	public const uint32 CM_PROB_DISABLED = 22;
	public const uint32 CM_PROB_DEVLOADER_NOT_READY = 23;
	public const uint32 CM_PROB_DEVICE_NOT_THERE = 24;
	public const uint32 CM_PROB_MOVED = 25;
	public const uint32 CM_PROB_TOO_EARLY = 26;
	public const uint32 CM_PROB_NO_VALID_LOG_CONF = 27;
	public const uint32 CM_PROB_FAILED_INSTALL = 28;
	public const uint32 CM_PROB_HARDWARE_DISABLED = 29;
	public const uint32 CM_PROB_CANT_SHARE_IRQ = 30;
	public const uint32 CM_PROB_FAILED_ADD = 31;
	public const uint32 CM_PROB_DISABLED_SERVICE = 32;
	public const uint32 CM_PROB_TRANSLATION_FAILED = 33;
	public const uint32 CM_PROB_NO_SOFTCONFIG = 34;
	public const uint32 CM_PROB_BIOS_TABLE = 35;
	public const uint32 CM_PROB_IRQ_TRANSLATION_FAILED = 36;
	public const uint32 CM_PROB_FAILED_DRIVER_ENTRY = 37;
	public const uint32 CM_PROB_DRIVER_FAILED_PRIOR_UNLOAD = 38;
	public const uint32 CM_PROB_DRIVER_FAILED_LOAD = 39;
	public const uint32 CM_PROB_DRIVER_SERVICE_KEY_INVALID = 40;
	public const uint32 CM_PROB_LEGACY_SERVICE_NO_DEVICES = 41;
	public const uint32 CM_PROB_DUPLICATE_DEVICE = 42;
	public const uint32 CM_PROB_FAILED_POST_START = 43;
	public const uint32 CM_PROB_HALTED = 44;
	public const uint32 CM_PROB_PHANTOM = 45;
	public const uint32 CM_PROB_SYSTEM_SHUTDOWN = 46;
	public const uint32 CM_PROB_HELD_FOR_EJECT = 47;
	public const uint32 CM_PROB_DRIVER_BLOCKED = 48;
	public const uint32 CM_PROB_REGISTRY_TOO_LARGE = 49;
	public const uint32 CM_PROB_SETPROPERTIES_FAILED = 50;
	public const uint32 CM_PROB_WAITING_ON_DEPENDENCY = 51;
	public const uint32 CM_PROB_UNSIGNED_DRIVER = 52;
	public const uint32 CM_PROB_USED_BY_DEBUGGER = 53;
	public const uint32 CM_PROB_DEVICE_RESET = 54;
	public const uint32 CM_PROB_CONSOLE_LOCKED = 55;
	public const uint32 CM_PROB_NEED_CLASS_CONFIG = 56;
	public const uint32 CM_PROB_GUEST_ASSIGNMENT_FAILED = 57;
	public const uint32 NUM_CM_PROB_V1 = 37;
	public const uint32 NUM_CM_PROB_V2 = 50;
	public const uint32 NUM_CM_PROB_V3 = 51;
	public const uint32 NUM_CM_PROB_V4 = 52;
	public const uint32 NUM_CM_PROB_V5 = 53;
	public const uint32 NUM_CM_PROB_V6 = 54;
	public const uint32 NUM_CM_PROB_V7 = 55;
	public const uint32 NUM_CM_PROB_V8 = 57;
	public const uint32 NUM_CM_PROB_V9 = 58;
	public const uint32 NUM_CM_PROB = 58;
	public const uint32 DN_ROOT_ENUMERATED = 1;
	public const uint32 DN_DRIVER_LOADED = 2;
	public const uint32 DN_ENUM_LOADED = 4;
	public const uint32 DN_STARTED = 8;
	public const uint32 DN_MANUAL = 16;
	public const uint32 DN_NEED_TO_ENUM = 32;
	public const uint32 DN_NOT_FIRST_TIME = 64;
	public const uint32 DN_HARDWARE_ENUM = 128;
	public const uint32 DN_LIAR = 256;
	public const uint32 DN_HAS_MARK = 512;
	public const uint32 DN_HAS_PROBLEM = 1024;
	public const uint32 DN_FILTERED = 2048;
	public const uint32 DN_MOVED = 4096;
	public const uint32 DN_DISABLEABLE = 8192;
	public const uint32 DN_REMOVABLE = 16384;
	public const uint32 DN_PRIVATE_PROBLEM = 32768;
	public const uint32 DN_MF_PARENT = 65536;
	public const uint32 DN_MF_CHILD = 131072;
	public const uint32 DN_WILL_BE_REMOVED = 262144;
	public const uint32 DN_NOT_FIRST_TIMEE = 524288;
	public const uint32 DN_STOP_FREE_RES = 1048576;
	public const uint32 DN_REBAL_CANDIDATE = 2097152;
	public const uint32 DN_BAD_PARTIAL = 4194304;
	public const uint32 DN_NT_ENUMERATOR = 8388608;
	public const uint32 DN_NT_DRIVER = 16777216;
	public const uint32 DN_NEEDS_LOCKING = 33554432;
	public const uint32 DN_ARM_WAKEUP = 67108864;
	public const uint32 DN_APM_ENUMERATOR = 134217728;
	public const uint32 DN_APM_DRIVER = 268435456;
	public const uint32 DN_SILENT_INSTALL = 536870912;
	public const uint32 DN_NO_SHOW_IN_DM = 1073741824;
	public const uint32 DN_BOOT_LOG_PROB = 2147483648;
	public const uint32 DN_NEED_RESTART = 256;
	public const uint32 DN_DRIVER_BLOCKED = 64;
	public const uint32 DN_LEGACY_DRIVER = 4096;
	public const uint32 DN_CHILD_WITH_INVALID_ID = 512;
	public const uint32 DN_DEVICE_DISCONNECTED = 33554432;
	public const uint32 DN_QUERY_REMOVE_PENDING = 65536;
	public const uint32 DN_QUERY_REMOVE_ACTIVE = 131072;
	public const uint32 LCPRI_FORCECONFIG = 0;
	public const uint32 LCPRI_BOOTCONFIG = 1;
	public const uint32 LCPRI_DESIRED = 8192;
	public const uint32 LCPRI_NORMAL = 12288;
	public const uint32 LCPRI_LASTBESTCONFIG = 16383;
	public const uint32 LCPRI_SUBOPTIMAL = 20480;
	public const uint32 LCPRI_LASTSOFTCONFIG = 32767;
	public const uint32 LCPRI_RESTART = 32768;
	public const uint32 LCPRI_REBOOT = 36864;
	public const uint32 LCPRI_POWEROFF = 40960;
	public const uint32 LCPRI_HARDRECONFIG = 49152;
	public const uint32 LCPRI_HARDWIRED = 57344;
	public const uint32 LCPRI_IMPOSSIBLE = 61440;
	public const uint32 LCPRI_DISABLED = 65535;
	public const uint32 MAX_LCPRI = 65535;
	public const uint32 CM_DEVICE_PANEL_SIDE_UNKNOWN = 0;
	public const uint32 CM_DEVICE_PANEL_SIDE_TOP = 1;
	public const uint32 CM_DEVICE_PANEL_SIDE_BOTTOM = 2;
	public const uint32 CM_DEVICE_PANEL_SIDE_LEFT = 3;
	public const uint32 CM_DEVICE_PANEL_SIDE_RIGHT = 4;
	public const uint32 CM_DEVICE_PANEL_SIDE_FRONT = 5;
	public const uint32 CM_DEVICE_PANEL_SIDE_BACK = 6;
	public const uint32 CM_DEVICE_PANEL_EDGE_UNKNOWN = 0;
	public const uint32 CM_DEVICE_PANEL_EDGE_TOP = 1;
	public const uint32 CM_DEVICE_PANEL_EDGE_BOTTOM = 2;
	public const uint32 CM_DEVICE_PANEL_EDGE_LEFT = 3;
	public const uint32 CM_DEVICE_PANEL_EDGE_RIGHT = 4;
	public const uint32 CM_DEVICE_PANEL_SHAPE_UNKNOWN = 0;
	public const uint32 CM_DEVICE_PANEL_SHAPE_RECTANGLE = 1;
	public const uint32 CM_DEVICE_PANEL_SHAPE_OVAL = 2;
	public const uint32 CM_DEVICE_PANEL_ORIENTATION_HORIZONTAL = 0;
	public const uint32 CM_DEVICE_PANEL_ORIENTATION_VERTICAL = 1;
	public const uint32 CM_DEVICE_PANEL_JOINT_TYPE_UNKNOWN = 0;
	public const uint32 CM_DEVICE_PANEL_JOINT_TYPE_PLANAR = 1;
	public const uint32 CM_DEVICE_PANEL_JOINT_TYPE_HINGE = 2;
	public const uint32 CM_DEVICE_PANEL_JOINT_TYPE_PIVOT = 3;
	public const uint32 CM_DEVICE_PANEL_JOINT_TYPE_SWIVEL = 4;
	public const Guid GUID_DEVCLASS_1394 = .(0x6bdd1fc1, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_1394DEBUG = .(0x66f250d6, 0x7801, 0x4a64, 0xb1, 0x39, 0xee, 0xa8, 0x0a, 0x45, 0x0b, 0x24);
	public const Guid GUID_DEVCLASS_61883 = .(0x7ebefbc0, 0x3200, 0x11d2, 0xb4, 0xc2, 0x00, 0xa0, 0xc9, 0x69, 0x7d, 0x07);
	public const Guid GUID_DEVCLASS_ADAPTER = .(0x4d36e964, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_APMSUPPORT = .(0xd45b1c18, 0xc8fa, 0x11d1, 0x9f, 0x77, 0x00, 0x00, 0xf8, 0x05, 0xf5, 0x30);
	public const Guid GUID_DEVCLASS_AVC = .(0xc06ff265, 0xae09, 0x48f0, 0x81, 0x2c, 0x16, 0x75, 0x3d, 0x7c, 0xba, 0x83);
	public const Guid GUID_DEVCLASS_BATTERY = .(0x72631e54, 0x78a4, 0x11d0, 0xbc, 0xf7, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_DEVCLASS_BIOMETRIC = .(0x53d29ef7, 0x377c, 0x4d14, 0x86, 0x4b, 0xeb, 0x3a, 0x85, 0x76, 0x93, 0x59);
	public const Guid GUID_DEVCLASS_BLUETOOTH = .(0xe0cbf06c, 0xcd8b, 0x4647, 0xbb, 0x8a, 0x26, 0x3b, 0x43, 0xf0, 0xf9, 0x74);
	public const Guid GUID_DEVCLASS_CAMERA = .(0xca3e7ab9, 0xb4c3, 0x4ae6, 0x82, 0x51, 0x57, 0x9e, 0xf9, 0x33, 0x89, 0x0f);
	public const Guid GUID_DEVCLASS_CDROM = .(0x4d36e965, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_COMPUTEACCELERATOR = .(0xf01a9d53, 0x3ff6, 0x48d2, 0x9f, 0x97, 0xc8, 0xa7, 0x00, 0x4b, 0xe1, 0x0c);
	public const Guid GUID_DEVCLASS_COMPUTER = .(0x4d36e966, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_DECODER = .(0x6bdd1fc2, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_DISKDRIVE = .(0x4d36e967, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_DISPLAY = .(0x4d36e968, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_DOT4 = .(0x48721b56, 0x6795, 0x11d2, 0xb1, 0xa8, 0x00, 0x80, 0xc7, 0x2e, 0x74, 0xa2);
	public const Guid GUID_DEVCLASS_DOT4PRINT = .(0x49ce6ac8, 0x6f86, 0x11d2, 0xb1, 0xe5, 0x00, 0x80, 0xc7, 0x2e, 0x74, 0xa2);
	public const Guid GUID_DEVCLASS_EHSTORAGESILO = .(0x9da2b80f, 0xf89f, 0x4a49, 0xa5, 0xc2, 0x51, 0x1b, 0x08, 0x5b, 0x9e, 0x8a);
	public const Guid GUID_DEVCLASS_ENUM1394 = .(0xc459df55, 0xdb08, 0x11d1, 0xb0, 0x09, 0x00, 0xa0, 0xc9, 0x08, 0x1f, 0xf6);
	public const Guid GUID_DEVCLASS_EXTENSION = .(0xe2f84ce7, 0x8efa, 0x411c, 0xaa, 0x69, 0x97, 0x45, 0x4c, 0xa4, 0xcb, 0x57);
	public const Guid GUID_DEVCLASS_FDC = .(0x4d36e969, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_FIRMWARE = .(0xf2e7dd72, 0x6468, 0x4e36, 0xb6, 0xf1, 0x64, 0x88, 0xf4, 0x2c, 0x1b, 0x52);
	public const Guid GUID_DEVCLASS_FLOPPYDISK = .(0x4d36e980, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_GPS = .(0x6bdd1fc3, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_HDC = .(0x4d36e96a, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_HIDCLASS = .(0x745a17a0, 0x74d3, 0x11d0, 0xb6, 0xfe, 0x00, 0xa0, 0xc9, 0x0f, 0x57, 0xda);
	public const Guid GUID_DEVCLASS_HOLOGRAPHIC = .(0xd612553d, 0x06b1, 0x49ca, 0x89, 0x38, 0xe3, 0x9e, 0xf8, 0x0e, 0xb1, 0x6f);
	public const Guid GUID_DEVCLASS_IMAGE = .(0x6bdd1fc6, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_INFINIBAND = .(0x30ef7132, 0xd858, 0x4a0c, 0xac, 0x24, 0xb9, 0x02, 0x8a, 0x5c, 0xca, 0x3f);
	public const Guid GUID_DEVCLASS_INFRARED = .(0x6bdd1fc5, 0x810f, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_KEYBOARD = .(0x4d36e96b, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_LEGACYDRIVER = .(0x8ecc055d, 0x047f, 0x11d1, 0xa5, 0x37, 0x00, 0x00, 0xf8, 0x75, 0x3e, 0xd1);
	public const Guid GUID_DEVCLASS_MEDIA = .(0x4d36e96c, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MEDIUM_CHANGER = .(0xce5939ae, 0xebde, 0x11d0, 0xb1, 0x81, 0x00, 0x00, 0xf8, 0x75, 0x3e, 0xc4);
	public const Guid GUID_DEVCLASS_MEMORY = .(0x5099944a, 0xf6b9, 0x4057, 0xa0, 0x56, 0x8c, 0x55, 0x02, 0x28, 0x54, 0x4c);
	public const Guid GUID_DEVCLASS_MODEM = .(0x4d36e96d, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MONITOR = .(0x4d36e96e, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MOUSE = .(0x4d36e96f, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MTD = .(0x4d36e970, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MULTIFUNCTION = .(0x4d36e971, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_MULTIPORTSERIAL = .(0x50906cb8, 0xba12, 0x11d1, 0xbf, 0x5d, 0x00, 0x00, 0xf8, 0x05, 0xf5, 0x30);
	public const Guid GUID_DEVCLASS_NET = .(0x4d36e972, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_NETCLIENT = .(0x4d36e973, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_NETDRIVER = .(0x87ef9ad1, 0x8f70, 0x49ee, 0xb2, 0x15, 0xab, 0x1f, 0xca, 0xdc, 0xbe, 0x3c);
	public const Guid GUID_DEVCLASS_NETSERVICE = .(0x4d36e974, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_NETTRANS = .(0x4d36e975, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_NETUIO = .(0x78912bc1, 0xcb8e, 0x4b28, 0xa3, 0x29, 0xf3, 0x22, 0xeb, 0xad, 0xbe, 0x0f);
	public const Guid GUID_DEVCLASS_NODRIVER = .(0x4d36e976, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_PCMCIA = .(0x4d36e977, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_PNPPRINTERS = .(0x4658ee7e, 0xf050, 0x11d1, 0xb6, 0xbd, 0x00, 0xc0, 0x4f, 0xa3, 0x72, 0xa7);
	public const Guid GUID_DEVCLASS_PORTS = .(0x4d36e978, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_PRINTER = .(0x4d36e979, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_PRINTERUPGRADE = .(0x4d36e97a, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_PRINTQUEUE = .(0x1ed2bbf9, 0x11f0, 0x4084, 0xb2, 0x1f, 0xad, 0x83, 0xa8, 0xe6, 0xdc, 0xdc);
	public const Guid GUID_DEVCLASS_PROCESSOR = .(0x50127dc3, 0x0f36, 0x415e, 0xa6, 0xcc, 0x4c, 0xb3, 0xbe, 0x91, 0x0b, 0x65);
	public const Guid GUID_DEVCLASS_SBP2 = .(0xd48179be, 0xec20, 0x11d1, 0xb6, 0xb8, 0x00, 0xc0, 0x4f, 0xa3, 0x72, 0xa7);
	public const Guid GUID_DEVCLASS_SCMDISK = .(0x53966cb1, 0x4d46, 0x4166, 0xbf, 0x23, 0xc5, 0x22, 0x40, 0x3c, 0xd4, 0x95);
	public const Guid GUID_DEVCLASS_SCMVOLUME = .(0x53ccb149, 0xe543, 0x4c84, 0xb6, 0xe0, 0xbc, 0xe4, 0xf6, 0xb7, 0xe8, 0x06);
	public const Guid GUID_DEVCLASS_SCSIADAPTER = .(0x4d36e97b, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_SECURITYACCELERATOR = .(0x268c95a1, 0xedfe, 0x11d3, 0x95, 0xc3, 0x00, 0x10, 0xdc, 0x40, 0x50, 0xa5);
	public const Guid GUID_DEVCLASS_SENSOR = .(0x5175d334, 0xc371, 0x4806, 0xb3, 0xba, 0x71, 0xfd, 0x53, 0xc9, 0x25, 0x8d);
	public const Guid GUID_DEVCLASS_SIDESHOW = .(0x997b5d8d, 0xc442, 0x4f2e, 0xba, 0xf3, 0x9c, 0x8e, 0x67, 0x1e, 0x9e, 0x21);
	public const Guid GUID_DEVCLASS_SMARTCARDREADER = .(0x50dd5230, 0xba8a, 0x11d1, 0xbf, 0x5d, 0x00, 0x00, 0xf8, 0x05, 0xf5, 0x30);
	public const Guid GUID_DEVCLASS_SMRDISK = .(0x53487c23, 0x680f, 0x4585, 0xac, 0xc3, 0x1f, 0x10, 0xd6, 0x77, 0x7e, 0x82);
	public const Guid GUID_DEVCLASS_SMRVOLUME = .(0x53b3cf03, 0x8f5a, 0x4788, 0x91, 0xb6, 0xd1, 0x9e, 0xd9, 0xfc, 0xcc, 0xbf);
	public const Guid GUID_DEVCLASS_SOFTWARECOMPONENT = .(0x5c4c3332, 0x344d, 0x483c, 0x87, 0x39, 0x25, 0x9e, 0x93, 0x4c, 0x9c, 0xc8);
	public const Guid GUID_DEVCLASS_SOUND = .(0x4d36e97c, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_SYSTEM = .(0x4d36e97d, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_TAPEDRIVE = .(0x6d807884, 0x7d21, 0x11cf, 0x80, 0x1c, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_UNKNOWN = .(0x4d36e97e, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18);
	public const Guid GUID_DEVCLASS_UCM = .(0xe6f1aa1c, 0x7f3b, 0x4473, 0xb2, 0xe8, 0xc9, 0x7d, 0x8a, 0xc7, 0x1d, 0x53);
	public const Guid GUID_DEVCLASS_USB = .(0x36fc9e60, 0xc465, 0x11cf, 0x80, 0x56, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);
	public const Guid GUID_DEVCLASS_VOLUME = .(0x71a27cdd, 0x812a, 0x11d0, 0xbe, 0xc7, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_DEVCLASS_VOLUMESNAPSHOT = .(0x533c5b84, 0xec70, 0x11d2, 0x95, 0x05, 0x00, 0xc0, 0x4f, 0x79, 0xde, 0xaf);
	public const Guid GUID_DEVCLASS_WCEUSBS = .(0x25dbce51, 0x6c8f, 0x4a72, 0x8a, 0x6d, 0xb5, 0x4c, 0x2b, 0x4f, 0xc8, 0x35);
	public const Guid GUID_DEVCLASS_WPD = .(0xeec5ad98, 0x8080, 0x425f, 0x92, 0x2a, 0xda, 0xbf, 0x3d, 0xe3, 0xf6, 0x9a);
	public const Guid GUID_DEVCLASS_FSFILTER_TOP = .(0xb369baf4, 0x5568, 0x4e82, 0xa8, 0x7e, 0xa9, 0x3e, 0xb1, 0x6b, 0xca, 0x87);
	public const Guid GUID_DEVCLASS_FSFILTER_ACTIVITYMONITOR = .(0xb86dff51, 0xa31e, 0x4bac, 0xb3, 0xcf, 0xe8, 0xcf, 0xe7, 0x5c, 0x9f, 0xc2);
	public const Guid GUID_DEVCLASS_FSFILTER_UNDELETE = .(0xfe8f1572, 0xc67a, 0x48c0, 0xbb, 0xac, 0x0b, 0x5c, 0x6d, 0x66, 0xca, 0xfb);
	public const Guid GUID_DEVCLASS_FSFILTER_ANTIVIRUS = .(0xb1d1a169, 0xc54f, 0x4379, 0x81, 0xdb, 0xbe, 0xe7, 0xd8, 0x8d, 0x74, 0x54);
	public const Guid GUID_DEVCLASS_FSFILTER_REPLICATION = .(0x48d3ebc4, 0x4cf8, 0x48ff, 0xb8, 0x69, 0x9c, 0x68, 0xad, 0x42, 0xeb, 0x9f);
	public const Guid GUID_DEVCLASS_FSFILTER_CONTINUOUSBACKUP = .(0x71aa14f8, 0x6fad, 0x4622, 0xad, 0x77, 0x92, 0xbb, 0x9d, 0x7e, 0x69, 0x47);
	public const Guid GUID_DEVCLASS_FSFILTER_CONTENTSCREENER = .(0x3e3f0674, 0xc83c, 0x4558, 0xbb, 0x26, 0x98, 0x20, 0xe1, 0xeb, 0xa5, 0xc5);
	public const Guid GUID_DEVCLASS_FSFILTER_QUOTAMANAGEMENT = .(0x8503c911, 0xa6c7, 0x4919, 0x8f, 0x79, 0x50, 0x28, 0xf5, 0x86, 0x6b, 0x0c);
	public const Guid GUID_DEVCLASS_FSFILTER_SYSTEMRECOVERY = .(0x2db15374, 0x706e, 0x4131, 0xa0, 0xc7, 0xd7, 0xc7, 0x8e, 0xb0, 0x28, 0x9a);
	public const Guid GUID_DEVCLASS_FSFILTER_CFSMETADATASERVER = .(0xcdcf0939, 0xb75b, 0x4630, 0xbf, 0x76, 0x80, 0xf7, 0xba, 0x65, 0x58, 0x84);
	public const Guid GUID_DEVCLASS_FSFILTER_HSM = .(0xd546500a, 0x2aeb, 0x45f6, 0x94, 0x82, 0xf4, 0xb1, 0x79, 0x9c, 0x31, 0x77);
	public const Guid GUID_DEVCLASS_FSFILTER_COMPRESSION = .(0xf3586baf, 0xb5aa, 0x49b5, 0x8d, 0x6c, 0x05, 0x69, 0x28, 0x4c, 0x63, 0x9f);
	public const Guid GUID_DEVCLASS_FSFILTER_ENCRYPTION = .(0xa0a701c0, 0xa511, 0x42ff, 0xaa, 0x6c, 0x06, 0xdc, 0x03, 0x95, 0x57, 0x6f);
	public const Guid GUID_DEVCLASS_FSFILTER_VIRTUALIZATION = .(0xf75a86c0, 0x10d8, 0x4c3a, 0xb2, 0x33, 0xed, 0x60, 0xe4, 0xcd, 0xfa, 0xac);
	public const Guid GUID_DEVCLASS_FSFILTER_PHYSICALQUOTAMANAGEMENT = .(0x6a0a8e78, 0xbba6, 0x4fc4, 0xa7, 0x09, 0x1e, 0x33, 0xcd, 0x09, 0xd6, 0x7e);
	public const Guid GUID_DEVCLASS_FSFILTER_OPENFILEBACKUP = .(0xf8ecafa6, 0x66d1, 0x41a5, 0x89, 0x9b, 0x66, 0x58, 0x5d, 0x72, 0x16, 0xb7);
	public const Guid GUID_DEVCLASS_FSFILTER_SECURITYENHANCER = .(0xd02bc3da, 0x0c8e, 0x4945, 0x9b, 0xd5, 0xf1, 0x88, 0x3c, 0x22, 0x6c, 0x8c);
	public const Guid GUID_DEVCLASS_FSFILTER_COPYPROTECTION = .(0x89786ff1, 0x9c12, 0x402f, 0x9c, 0x9e, 0x17, 0x75, 0x3c, 0x7f, 0x43, 0x75);
	public const Guid GUID_DEVCLASS_FSFILTER_BOTTOM = .(0x37765ea0, 0x5958, 0x4fc9, 0xb0, 0x4b, 0x2f, 0xdf, 0xef, 0x97, 0xe5, 0x9e);
	public const Guid GUID_DEVCLASS_FSFILTER_SYSTEM = .(0x5d1b9aaa, 0x01e2, 0x46af, 0x84, 0x9f, 0x27, 0x2b, 0x3f, 0x32, 0x4c, 0x46);
	public const Guid GUID_DEVCLASS_FSFILTER_INFRASTRUCTURE = .(0xe55fa6f9, 0x128c, 0x4d04, 0xab, 0xab, 0x63, 0x0c, 0x74, 0xb1, 0x45, 0x3a);
	public const uint32 LINE_LEN = 256;
	public const uint32 MAX_INF_STRING_LENGTH = 4096;
	public const uint32 MAX_INF_SECTION_NAME_LENGTH = 255;
	public const uint32 MAX_TITLE_LEN = 60;
	public const uint32 MAX_INSTRUCTION_LEN = 256;
	public const uint32 MAX_LABEL_LEN = 30;
	public const uint32 MAX_SERVICE_NAME_LEN = 256;
	public const uint32 MAX_SUBTITLE_LEN = 256;
	public const uint32 SP_MAX_MACHINENAME_LENGTH = 263;
	public const uint32 SP_ALTPLATFORM_FLAGS_VERSION_RANGE = 1;
	public const uint32 SP_ALTPLATFORM_FLAGS_SUITE_MASK = 2;
	public const uint32 INF_STYLE_CACHE_ENABLE = 16;
	public const uint32 INF_STYLE_CACHE_DISABLE = 32;
	public const uint32 INF_STYLE_CACHE_IGNORE = 64;
	public const int32 DIRID_ABSOLUTE = -1;
	public const uint32 DIRID_ABSOLUTE_16BIT = 65535;
	public const uint32 DIRID_NULL = 0;
	public const uint32 DIRID_SRCPATH = 1;
	public const uint32 DIRID_WINDOWS = 10;
	public const uint32 DIRID_SYSTEM = 11;
	public const uint32 DIRID_DRIVERS = 12;
	public const uint32 DIRID_IOSUBSYS = 12;
	public const uint32 DIRID_DRIVER_STORE = 13;
	public const uint32 DIRID_INF = 17;
	public const uint32 DIRID_HELP = 18;
	public const uint32 DIRID_FONTS = 20;
	public const uint32 DIRID_VIEWERS = 21;
	public const uint32 DIRID_COLOR = 23;
	public const uint32 DIRID_APPS = 24;
	public const uint32 DIRID_SHARED = 25;
	public const uint32 DIRID_BOOT = 30;
	public const uint32 DIRID_SYSTEM16 = 50;
	public const uint32 DIRID_SPOOL = 51;
	public const uint32 DIRID_SPOOLDRIVERS = 52;
	public const uint32 DIRID_USERPROFILE = 53;
	public const uint32 DIRID_LOADER = 54;
	public const uint32 DIRID_PRINTPROCESSOR = 55;
	public const uint32 DIRID_DEFAULT = 11;
	public const uint32 DIRID_COMMON_STARTMENU = 16406;
	public const uint32 DIRID_COMMON_PROGRAMS = 16407;
	public const uint32 DIRID_COMMON_STARTUP = 16408;
	public const uint32 DIRID_COMMON_DESKTOPDIRECTORY = 16409;
	public const uint32 DIRID_COMMON_FAVORITES = 16415;
	public const uint32 DIRID_COMMON_APPDATA = 16419;
	public const uint32 DIRID_PROGRAM_FILES = 16422;
	public const uint32 DIRID_SYSTEM_X86 = 16425;
	public const uint32 DIRID_PROGRAM_FILES_X86 = 16426;
	public const uint32 DIRID_PROGRAM_FILES_COMMON = 16427;
	public const uint32 DIRID_PROGRAM_FILES_COMMONX86 = 16428;
	public const uint32 DIRID_COMMON_TEMPLATES = 16429;
	public const uint32 DIRID_COMMON_DOCUMENTS = 16430;
	public const uint32 DIRID_USER = 32768;
	public const uint32 SPFILENOTIFY_STARTQUEUE = 1;
	public const uint32 SPFILENOTIFY_ENDQUEUE = 2;
	public const uint32 SPFILENOTIFY_STARTSUBQUEUE = 3;
	public const uint32 SPFILENOTIFY_ENDSUBQUEUE = 4;
	public const uint32 SPFILENOTIFY_STARTDELETE = 5;
	public const uint32 SPFILENOTIFY_ENDDELETE = 6;
	public const uint32 SPFILENOTIFY_DELETEERROR = 7;
	public const uint32 SPFILENOTIFY_STARTRENAME = 8;
	public const uint32 SPFILENOTIFY_ENDRENAME = 9;
	public const uint32 SPFILENOTIFY_RENAMEERROR = 10;
	public const uint32 SPFILENOTIFY_STARTCOPY = 11;
	public const uint32 SPFILENOTIFY_ENDCOPY = 12;
	public const uint32 SPFILENOTIFY_COPYERROR = 13;
	public const uint32 SPFILENOTIFY_NEEDMEDIA = 14;
	public const uint32 SPFILENOTIFY_QUEUESCAN = 15;
	public const uint32 SPFILENOTIFY_CABINETINFO = 16;
	public const uint32 SPFILENOTIFY_FILEINCABINET = 17;
	public const uint32 SPFILENOTIFY_NEEDNEWCABINET = 18;
	public const uint32 SPFILENOTIFY_FILEEXTRACTED = 19;
	public const uint32 SPFILENOTIFY_FILEOPDELAYED = 20;
	public const uint32 SPFILENOTIFY_STARTBACKUP = 21;
	public const uint32 SPFILENOTIFY_BACKUPERROR = 22;
	public const uint32 SPFILENOTIFY_ENDBACKUP = 23;
	public const uint32 SPFILENOTIFY_QUEUESCAN_EX = 24;
	public const uint32 SPFILENOTIFY_STARTREGISTRATION = 25;
	public const uint32 SPFILENOTIFY_ENDREGISTRATION = 32;
	public const uint32 SPFILENOTIFY_QUEUESCAN_SIGNERINFO = 64;
	public const uint32 SPFILENOTIFY_LANGMISMATCH = 65536;
	public const uint32 SPFILENOTIFY_TARGETEXISTS = 131072;
	public const uint32 SPFILENOTIFY_TARGETNEWER = 262144;
	public const uint32 FILEOP_RENAME = 1;
	public const uint32 FILEOP_BACKUP = 3;
	public const uint32 FILEOP_ABORT = 0;
	public const uint32 FILEOP_DOIT = 1;
	public const uint32 FILEOP_SKIP = 2;
	public const uint32 FILEOP_RETRY = 1;
	public const uint32 FILEOP_NEWPATH = 4;
	public const uint32 COPYFLG_WARN_IF_SKIP = 1;
	public const uint32 COPYFLG_NOSKIP = 2;
	public const uint32 COPYFLG_NOVERSIONCHECK = 4;
	public const uint32 COPYFLG_FORCE_FILE_IN_USE = 8;
	public const uint32 COPYFLG_NO_OVERWRITE = 16;
	public const uint32 COPYFLG_NO_VERSION_DIALOG = 32;
	public const uint32 COPYFLG_OVERWRITE_OLDER_ONLY = 64;
	public const uint32 COPYFLG_PROTECTED_WINDOWS_DRIVER_FILE = 256;
	public const uint32 COPYFLG_REPLACEONLY = 1024;
	public const uint32 COPYFLG_NODECOMP = 2048;
	public const uint32 COPYFLG_REPLACE_BOOT_FILE = 4096;
	public const uint32 COPYFLG_NOPRUNE = 8192;
	public const uint32 COPYFLG_IN_USE_TRY_RENAME = 16384;
	public const uint32 DELFLG_IN_USE = 1;
	public const uint32 DELFLG_IN_USE1 = 65536;
	public const uint32 SPREG_SUCCESS = 0;
	public const uint32 SPREG_LOADLIBRARY = 1;
	public const uint32 SPREG_GETPROCADDR = 2;
	public const uint32 SPREG_REGSVR = 3;
	public const uint32 SPREG_DLLINSTALL = 4;
	public const uint32 SPREG_TIMEOUT = 5;
	public const uint32 SPREG_UNKNOWN = 4294967295;
	public const uint32 SPINT_ACTIVE = 1;
	public const uint32 SPINT_DEFAULT = 2;
	public const uint32 SPINT_REMOVED = 4;
	public const uint32 SPID_ACTIVE = 1;
	public const uint32 SPID_DEFAULT = 2;
	public const uint32 SPID_REMOVED = 4;
	public const uint32 DIF_SELECTDEVICE = 1;
	public const uint32 DIF_INSTALLDEVICE = 2;
	public const uint32 DIF_ASSIGNRESOURCES = 3;
	public const uint32 DIF_PROPERTIES = 4;
	public const uint32 DIF_REMOVE = 5;
	public const uint32 DIF_FIRSTTIMESETUP = 6;
	public const uint32 DIF_FOUNDDEVICE = 7;
	public const uint32 DIF_SELECTCLASSDRIVERS = 8;
	public const uint32 DIF_VALIDATECLASSDRIVERS = 9;
	public const uint32 DIF_INSTALLCLASSDRIVERS = 10;
	public const uint32 DIF_CALCDISKSPACE = 11;
	public const uint32 DIF_DESTROYPRIVATEDATA = 12;
	public const uint32 DIF_VALIDATEDRIVER = 13;
	public const uint32 DIF_DETECT = 15;
	public const uint32 DIF_INSTALLWIZARD = 16;
	public const uint32 DIF_DESTROYWIZARDDATA = 17;
	public const uint32 DIF_PROPERTYCHANGE = 18;
	public const uint32 DIF_ENABLECLASS = 19;
	public const uint32 DIF_DETECTVERIFY = 20;
	public const uint32 DIF_INSTALLDEVICEFILES = 21;
	public const uint32 DIF_UNREMOVE = 22;
	public const uint32 DIF_SELECTBESTCOMPATDRV = 23;
	public const uint32 DIF_ALLOW_INSTALL = 24;
	public const uint32 DIF_REGISTERDEVICE = 25;
	public const uint32 DIF_NEWDEVICEWIZARD_PRESELECT = 26;
	public const uint32 DIF_NEWDEVICEWIZARD_SELECT = 27;
	public const uint32 DIF_NEWDEVICEWIZARD_PREANALYZE = 28;
	public const uint32 DIF_NEWDEVICEWIZARD_POSTANALYZE = 29;
	public const uint32 DIF_NEWDEVICEWIZARD_FINISHINSTALL = 30;
	public const uint32 DIF_UNUSED1 = 31;
	public const uint32 DIF_INSTALLINTERFACES = 32;
	public const uint32 DIF_DETECTCANCEL = 33;
	public const uint32 DIF_REGISTER_COINSTALLERS = 34;
	public const uint32 DIF_ADDPROPERTYPAGE_ADVANCED = 35;
	public const uint32 DIF_ADDPROPERTYPAGE_BASIC = 36;
	public const uint32 DIF_RESERVED1 = 37;
	public const uint32 DIF_TROUBLESHOOTER = 38;
	public const uint32 DIF_POWERMESSAGEWAKE = 39;
	public const uint32 DIF_ADDREMOTEPROPERTYPAGE_ADVANCED = 40;
	public const uint32 DIF_UPDATEDRIVER_UI = 41;
	public const uint32 DIF_FINISHINSTALL_ACTION = 42;
	public const uint32 DIF_RESERVED2 = 48;
	public const uint32 DIF_MOVEDEVICE = 14;
	public const int32 DI_SHOWOEM = 1;
	public const int32 DI_SHOWCOMPAT = 2;
	public const int32 DI_SHOWCLASS = 4;
	public const int32 DI_SHOWALL = 7;
	public const int32 DI_NOVCP = 8;
	public const int32 DI_DIDCOMPAT = 16;
	public const int32 DI_DIDCLASS = 32;
	public const int32 DI_AUTOASSIGNRES = 64;
	public const int32 DI_NEEDRESTART = 128;
	public const int32 DI_NEEDREBOOT = 256;
	public const int32 DI_NOBROWSE = 512;
	public const int32 DI_MULTMFGS = 1024;
	public const int32 DI_DISABLED = 2048;
	public const int32 DI_GENERALPAGE_ADDED = 4096;
	public const int32 DI_RESOURCEPAGE_ADDED = 8192;
	public const int32 DI_PROPERTIES_CHANGE = 16384;
	public const int32 DI_INF_IS_SORTED = 32768;
	public const int32 DI_ENUMSINGLEINF = 65536;
	public const int32 DI_DONOTCALLCONFIGMG = 131072;
	public const int32 DI_INSTALLDISABLED = 262144;
	public const int32 DI_COMPAT_FROM_CLASS = 524288;
	public const int32 DI_CLASSINSTALLPARAMS = 1048576;
	public const int32 DI_NODI_DEFAULTACTION = 2097152;
	public const int32 DI_QUIETINSTALL = 8388608;
	public const int32 DI_NOFILECOPY = 16777216;
	public const int32 DI_FORCECOPY = 33554432;
	public const int32 DI_DRIVERPAGE_ADDED = 67108864;
	public const int32 DI_USECI_SELECTSTRINGS = 134217728;
	public const int32 DI_OVERRIDE_INFFLAGS = 268435456;
	public const int32 DI_PROPS_NOCHANGEUSAGE = 536870912;
	public const int32 DI_NOSELECTICONS = 1073741824;
	public const int32 DI_NOWRITE_IDS = -2147483648;
	public const int32 DI_FLAGSEX_RESERVED2 = 1;
	public const int32 DI_FLAGSEX_RESERVED3 = 2;
	public const int32 DI_FLAGSEX_CI_FAILED = 4;
	public const int32 DI_FLAGSEX_FINISHINSTALL_ACTION = 8;
	public const int32 DI_FLAGSEX_DIDINFOLIST = 16;
	public const int32 DI_FLAGSEX_DIDCOMPATINFO = 32;
	public const int32 DI_FLAGSEX_FILTERCLASSES = 64;
	public const int32 DI_FLAGSEX_SETFAILEDINSTALL = 128;
	public const int32 DI_FLAGSEX_DEVICECHANGE = 256;
	public const int32 DI_FLAGSEX_ALWAYSWRITEIDS = 512;
	public const int32 DI_FLAGSEX_PROPCHANGE_PENDING = 1024;
	public const int32 DI_FLAGSEX_ALLOWEXCLUDEDDRVS = 2048;
	public const int32 DI_FLAGSEX_NOUIONQUERYREMOVE = 4096;
	public const int32 DI_FLAGSEX_USECLASSFORCOMPAT = 8192;
	public const int32 DI_FLAGSEX_RESERVED4 = 16384;
	public const int32 DI_FLAGSEX_NO_DRVREG_MODIFY = 32768;
	public const int32 DI_FLAGSEX_IN_SYSTEM_SETUP = 65536;
	public const int32 DI_FLAGSEX_INET_DRIVER = 131072;
	public const int32 DI_FLAGSEX_APPENDDRIVERLIST = 262144;
	public const int32 DI_FLAGSEX_PREINSTALLBACKUP = 524288;
	public const int32 DI_FLAGSEX_BACKUPONREPLACE = 1048576;
	public const int32 DI_FLAGSEX_DRIVERLIST_FROM_URL = 2097152;
	public const int32 DI_FLAGSEX_RESERVED1 = 4194304;
	public const int32 DI_FLAGSEX_EXCLUDE_OLD_INET_DRIVERS = 8388608;
	public const int32 DI_FLAGSEX_POWERPAGE_ADDED = 16777216;
	public const int32 DI_FLAGSEX_FILTERSIMILARDRIVERS = 33554432;
	public const int32 DI_FLAGSEX_INSTALLEDDRIVER = 67108864;
	public const int32 DI_FLAGSEX_NO_CLASSLIST_NODE_MERGE = 134217728;
	public const int32 DI_FLAGSEX_ALTPLATFORM_DRVSEARCH = 268435456;
	public const int32 DI_FLAGSEX_RESTART_DEVICE_ONLY = 536870912;
	public const int32 DI_FLAGSEX_RECURSIVESEARCH = 1073741824;
	public const int32 DI_FLAGSEX_SEARCH_PUBLISHED_INFS = -2147483648;
	public const uint32 ENABLECLASS_QUERY = 0;
	public const uint32 ENABLECLASS_SUCCESS = 1;
	public const uint32 ENABLECLASS_FAILURE = 2;
	public const uint32 DICS_ENABLE = 1;
	public const uint32 DICS_DISABLE = 2;
	public const uint32 DICS_PROPCHANGE = 3;
	public const uint32 DICS_START = 4;
	public const uint32 DICS_STOP = 5;
	public const uint32 DICS_FLAG_GLOBAL = 1;
	public const uint32 DICS_FLAG_CONFIGSPECIFIC = 2;
	public const uint32 DICS_FLAG_CONFIGGENERAL = 4;
	public const uint32 DI_REMOVEDEVICE_GLOBAL = 1;
	public const uint32 DI_REMOVEDEVICE_CONFIGSPECIFIC = 2;
	public const uint32 DI_UNREMOVEDEVICE_CONFIGSPECIFIC = 2;
	public const uint32 MAX_INSTALLWIZARD_DYNAPAGES = 20;
	public const uint32 NDW_INSTALLFLAG_DIDFACTDEFS = 1;
	public const uint32 NDW_INSTALLFLAG_HARDWAREALLREADYIN = 2;
	public const int32 NDW_INSTALLFLAG_NEEDRESTART = 128;
	public const int32 NDW_INSTALLFLAG_NEEDREBOOT = 256;
	public const uint32 NDW_INSTALLFLAG_NEEDSHUTDOWN = 512;
	public const uint32 NDW_INSTALLFLAG_EXPRESSINTRO = 1024;
	public const uint32 NDW_INSTALLFLAG_SKIPISDEVINSTALLED = 2048;
	public const uint32 NDW_INSTALLFLAG_NODETECTEDDEVS = 4096;
	public const uint32 NDW_INSTALLFLAG_INSTALLSPECIFIC = 8192;
	public const uint32 NDW_INSTALLFLAG_SKIPCLASSLIST = 16384;
	public const uint32 NDW_INSTALLFLAG_CI_PICKED_OEM = 32768;
	public const uint32 NDW_INSTALLFLAG_PCMCIAMODE = 65536;
	public const uint32 NDW_INSTALLFLAG_PCMCIADEVICE = 131072;
	public const uint32 NDW_INSTALLFLAG_USERCANCEL = 262144;
	public const uint32 NDW_INSTALLFLAG_KNOWNCLASS = 524288;
	public const uint32 DYNAWIZ_FLAG_PAGESADDED = 1;
	public const uint32 DYNAWIZ_FLAG_ANALYZE_HANDLECONFLICT = 8;
	public const uint32 DYNAWIZ_FLAG_INSTALLDET_NEXT = 2;
	public const uint32 DYNAWIZ_FLAG_INSTALLDET_PREV = 4;
	public const uint32 MIN_IDD_DYNAWIZ_RESOURCE_ID = 10000;
	public const uint32 MAX_IDD_DYNAWIZ_RESOURCE_ID = 11000;
	public const uint32 IDD_DYNAWIZ_FIRSTPAGE = 10000;
	public const uint32 IDD_DYNAWIZ_SELECT_PREVPAGE = 10001;
	public const uint32 IDD_DYNAWIZ_SELECT_NEXTPAGE = 10002;
	public const uint32 IDD_DYNAWIZ_ANALYZE_PREVPAGE = 10003;
	public const uint32 IDD_DYNAWIZ_ANALYZE_NEXTPAGE = 10004;
	public const uint32 IDD_DYNAWIZ_SELECTDEV_PAGE = 10009;
	public const uint32 IDD_DYNAWIZ_ANALYZEDEV_PAGE = 10010;
	public const uint32 IDD_DYNAWIZ_INSTALLDETECTEDDEVS_PAGE = 10011;
	public const uint32 IDD_DYNAWIZ_SELECTCLASS_PAGE = 10012;
	public const uint32 IDD_DYNAWIZ_INSTALLDETECTED_PREVPAGE = 10006;
	public const uint32 IDD_DYNAWIZ_INSTALLDETECTED_NEXTPAGE = 10007;
	public const uint32 IDD_DYNAWIZ_INSTALLDETECTED_NODEVS = 10008;
	public const uint32 DNF_DUPDESC = 1;
	public const uint32 DNF_OLDDRIVER = 2;
	public const uint32 DNF_EXCLUDEFROMLIST = 4;
	public const uint32 DNF_NODRIVER = 8;
	public const uint32 DNF_LEGACYINF = 16;
	public const uint32 DNF_CLASS_DRIVER = 32;
	public const uint32 DNF_COMPATIBLE_DRIVER = 64;
	public const uint32 DNF_INET_DRIVER = 128;
	public const uint32 DNF_UNUSED1 = 256;
	public const uint32 DNF_UNUSED2 = 512;
	public const uint32 DNF_OLD_INET_DRIVER = 1024;
	public const uint32 DNF_BAD_DRIVER = 2048;
	public const uint32 DNF_DUPPROVIDER = 4096;
	public const uint32 DNF_INF_IS_SIGNED = 8192;
	public const uint32 DNF_OEM_F6_INF = 16384;
	public const uint32 DNF_DUPDRIVERVER = 32768;
	public const uint32 DNF_BASIC_DRIVER = 65536;
	public const uint32 DNF_AUTHENTICODE_SIGNED = 131072;
	public const uint32 DNF_INSTALLEDDRIVER = 262144;
	public const uint32 DNF_ALWAYSEXCLUDEFROMLIST = 524288;
	public const uint32 DNF_INBOX_DRIVER = 1048576;
	public const uint32 DNF_REQUESTADDITIONALSOFTWARE = 2097152;
	public const uint32 DNF_UNUSED_22 = 4194304;
	public const uint32 DNF_UNUSED_23 = 8388608;
	public const uint32 DNF_UNUSED_24 = 16777216;
	public const uint32 DNF_UNUSED_25 = 33554432;
	public const uint32 DNF_UNUSED_26 = 67108864;
	public const uint32 DNF_UNUSED_27 = 134217728;
	public const uint32 DNF_UNUSED_28 = 268435456;
	public const uint32 DNF_UNUSED_29 = 536870912;
	public const uint32 DNF_UNUSED_30 = 1073741824;
	public const uint32 DNF_UNUSED_31 = 2147483648;
	public const uint32 DRIVER_HARDWAREID_RANK = 4095;
	public const uint32 DRIVER_HARDWAREID_MASK = 2147487743;
	public const uint32 DRIVER_UNTRUSTED_RANK = 2147483648;
	public const uint32 DRIVER_W9X_SUSPECT_RANK = 3221225472;
	public const uint32 DRIVER_COMPATID_RANK = 16383;
	public const uint32 DRIVER_UNTRUSTED_HARDWAREID_RANK = 36863;
	public const uint32 DRIVER_UNTRUSTED_COMPATID_RANK = 49151;
	public const uint32 DRIVER_W9X_SUSPECT_HARDWAREID_RANK = 53247;
	public const uint32 DRIVER_W9X_SUSPECT_COMPATID_RANK = 65535;
	public const uint32 SPPSR_SELECT_DEVICE_RESOURCES = 1;
	public const uint32 SPPSR_ENUM_BASIC_DEVICE_PROPERTIES = 2;
	public const uint32 SPPSR_ENUM_ADV_DEVICE_PROPERTIES = 3;
	public const uint32 INFINFO_INF_SPEC_IS_HINF = 1;
	public const uint32 INFINFO_INF_NAME_IS_ABSOLUTE = 2;
	public const uint32 INFINFO_DEFAULT_SEARCH = 3;
	public const uint32 INFINFO_REVERSE_DEFAULT_SEARCH = 4;
	public const uint32 INFINFO_INF_PATH_LIST_SEARCH = 5;
	public const uint32 FILE_COMPRESSION_NONE = 0;
	public const uint32 FILE_COMPRESSION_WINLZA = 1;
	public const uint32 FILE_COMPRESSION_MSZIP = 2;
	public const uint32 FILE_COMPRESSION_NTCAB = 3;
	public const uint32 SRCLIST_TEMPORARY = 1;
	public const uint32 SRCLIST_NOBROWSE = 2;
	public const uint32 SRCLIST_SYSTEM = 16;
	public const uint32 SRCLIST_USER = 32;
	public const uint32 SRCLIST_SYSIFADMIN = 64;
	public const uint32 SRCLIST_SUBDIRS = 256;
	public const uint32 SRCLIST_APPEND = 512;
	public const uint32 SRCLIST_NOSTRIPPLATFORM = 1024;
	public const uint32 IDF_NOBROWSE = 1;
	public const uint32 IDF_NOSKIP = 2;
	public const uint32 IDF_NODETAILS = 4;
	public const uint32 IDF_NOCOMPRESSED = 8;
	public const uint32 IDF_CHECKFIRST = 256;
	public const uint32 IDF_NOBEEP = 512;
	public const uint32 IDF_NOFOREGROUND = 1024;
	public const uint32 IDF_WARNIFSKIP = 2048;
	public const uint32 IDF_NOREMOVABLEMEDIAPROMPT = 4096;
	public const uint32 IDF_USEDISKNAMEASPROMPT = 8192;
	public const uint32 IDF_OEMDISK = 2147483648;
	public const uint32 DPROMPT_SUCCESS = 0;
	public const uint32 DPROMPT_CANCEL = 1;
	public const uint32 DPROMPT_SKIPFILE = 2;
	public const uint32 DPROMPT_BUFFERTOOSMALL = 3;
	public const uint32 DPROMPT_OUTOFMEMORY = 4;
	public const uint32 SETDIRID_NOT_FULL_PATH = 1;
	public const uint32 SRCINFO_PATH = 1;
	public const uint32 SRCINFO_TAGFILE = 2;
	public const uint32 SRCINFO_DESCRIPTION = 3;
	public const uint32 SRCINFO_FLAGS = 4;
	public const uint32 SRCINFO_TAGFILE2 = 5;
	public const uint32 SRC_FLAGS_CABFILE = 16;
	public const uint32 SP_FLAG_CABINETCONTINUATION = 2048;
	public const uint32 SP_BACKUP_BACKUPPASS = 1;
	public const uint32 SP_BACKUP_DEMANDPASS = 2;
	public const uint32 SP_BACKUP_SPECIAL = 4;
	public const uint32 SP_BACKUP_BOOTFILE = 8;
	public const uint32 SPQ_SCAN_FILE_PRESENCE = 1;
	public const uint32 SPQ_SCAN_FILE_VALIDITY = 2;
	public const uint32 SPQ_SCAN_USE_CALLBACK = 4;
	public const uint32 SPQ_SCAN_USE_CALLBACKEX = 8;
	public const uint32 SPQ_SCAN_INFORM_USER = 16;
	public const uint32 SPQ_SCAN_PRUNE_COPY_QUEUE = 32;
	public const uint32 SPQ_SCAN_USE_CALLBACK_SIGNERINFO = 64;
	public const uint32 SPQ_SCAN_PRUNE_DELREN = 128;
	public const uint32 SPQ_SCAN_FILE_PRESENCE_WITHOUT_SOURCE = 256;
	public const uint32 SPQ_SCAN_FILE_COMPARISON = 512;
	public const uint32 SPQ_SCAN_ACTIVATE_DRP = 1024;
	public const uint32 SPQ_DELAYED_COPY = 1;
	public const uint32 SPQ_FLAG_BACKUP_AWARE = 1;
	public const uint32 SPQ_FLAG_ABORT_IF_UNSIGNED = 2;
	public const uint32 SPQ_FLAG_FILES_MODIFIED = 4;
	public const uint32 SPQ_FLAG_DO_SHUFFLEMOVE = 8;
	public const uint32 SPQ_FLAG_VALID = 15;
	public const uint32 SPOST_MAX = 3;
	public const uint32 SUOI_FORCEDELETE = 1;
	public const uint32 SUOI_INTERNAL1 = 2;
	public const uint32 SPDSL_IGNORE_DISK = 1;
	public const uint32 SPDSL_DISALLOW_NEGATIVE_ADJUST = 2;
	public const uint32 SPFILEQ_FILE_IN_USE = 1;
	public const uint32 SPFILEQ_REBOOT_RECOMMENDED = 2;
	public const uint32 SPFILEQ_REBOOT_IN_PROGRESS = 4;
	public const uint32 FLG_ADDREG_DELREG_BIT = 32768;
	public const uint32 FLG_ADDREG_BINVALUETYPE = 1;
	public const uint32 FLG_ADDREG_NOCLOBBER = 2;
	public const uint32 FLG_ADDREG_DELVAL = 4;
	public const uint32 FLG_ADDREG_APPEND = 8;
	public const uint32 FLG_ADDREG_KEYONLY = 16;
	public const uint32 FLG_ADDREG_OVERWRITEONLY = 32;
	public const uint32 FLG_ADDREG_64BITKEY = 4096;
	public const uint32 FLG_ADDREG_KEYONLY_COMMON = 8192;
	public const uint32 FLG_ADDREG_32BITKEY = 16384;
	public const uint32 FLG_ADDREG_TYPE_SZ = 0;
	public const uint32 FLG_ADDREG_TYPE_MULTI_SZ = 65536;
	public const uint32 FLG_ADDREG_TYPE_EXPAND_SZ = 131072;
	public const uint32 FLG_DELREG_VALUE = 0;
	public const uint32 FLG_DELREG_TYPE_SZ = 0;
	public const uint32 FLG_DELREG_TYPE_MULTI_SZ = 65536;
	public const uint32 FLG_DELREG_TYPE_EXPAND_SZ = 131072;
	public const uint32 FLG_DELREG_64BITKEY = 4096;
	public const uint32 FLG_DELREG_KEYONLY_COMMON = 8192;
	public const uint32 FLG_DELREG_32BITKEY = 16384;
	public const uint32 FLG_DELREG_OPERATION_MASK = 254;
	public const uint32 FLG_BITREG_CLEARBITS = 0;
	public const uint32 FLG_BITREG_SETBITS = 1;
	public const uint32 FLG_BITREG_64BITKEY = 4096;
	public const uint32 FLG_BITREG_32BITKEY = 16384;
	public const uint32 FLG_INI2REG_64BITKEY = 4096;
	public const uint32 FLG_INI2REG_32BITKEY = 16384;
	public const uint32 FLG_REGSVR_DLLREGISTER = 1;
	public const uint32 FLG_REGSVR_DLLINSTALL = 2;
	public const uint32 FLG_PROFITEM_CURRENTUSER = 1;
	public const uint32 FLG_PROFITEM_DELETE = 2;
	public const uint32 FLG_PROFITEM_GROUP = 4;
	public const uint32 FLG_PROFITEM_CSIDL = 8;
	public const uint32 FLG_ADDPROPERTY_NOCLOBBER = 1;
	public const uint32 FLG_ADDPROPERTY_OVERWRITEONLY = 2;
	public const uint32 FLG_ADDPROPERTY_APPEND = 4;
	public const uint32 FLG_ADDPROPERTY_OR = 8;
	public const uint32 FLG_ADDPROPERTY_AND = 16;
	public const uint32 FLG_DELPROPERTY_MULTI_SZ_DELSTRING = 1;
	public const uint32 SPINST_LOGCONFIG = 1;
	public const uint32 SPINST_INIFILES = 2;
	public const uint32 SPINST_REGISTRY = 4;
	public const uint32 SPINST_INI2REG = 8;
	public const uint32 SPINST_FILES = 16;
	public const uint32 SPINST_BITREG = 32;
	public const uint32 SPINST_REGSVR = 64;
	public const uint32 SPINST_UNREGSVR = 128;
	public const uint32 SPINST_PROFILEITEMS = 256;
	public const uint32 SPINST_COPYINF = 512;
	public const uint32 SPINST_PROPERTIES = 1024;
	public const uint32 SPINST_ALL = 2047;
	public const uint32 SPINST_SINGLESECTION = 65536;
	public const uint32 SPINST_LOGCONFIG_IS_FORCED = 131072;
	public const uint32 SPINST_LOGCONFIGS_ARE_OVERRIDES = 262144;
	public const uint32 SPINST_REGISTERCALLBACKAWARE = 524288;
	public const uint32 SPINST_DEVICEINSTALL = 1048576;
	public const uint32 SPSVCINST_TAGTOFRONT = 1;
	public const uint32 SPSVCINST_ASSOCSERVICE = 2;
	public const uint32 SPSVCINST_DELETEEVENTLOGENTRY = 4;
	public const uint32 SPSVCINST_NOCLOBBER_DISPLAYNAME = 8;
	public const uint32 SPSVCINST_NOCLOBBER_STARTTYPE = 16;
	public const uint32 SPSVCINST_NOCLOBBER_ERRORCONTROL = 32;
	public const uint32 SPSVCINST_NOCLOBBER_LOADORDERGROUP = 64;
	public const uint32 SPSVCINST_NOCLOBBER_DEPENDENCIES = 128;
	public const uint32 SPSVCINST_NOCLOBBER_DESCRIPTION = 256;
	public const uint32 SPSVCINST_STOPSERVICE = 512;
	public const uint32 SPSVCINST_CLOBBER_SECURITY = 1024;
	public const uint32 SPSVCINST_STARTSERVICE = 2048;
	public const uint32 SPSVCINST_NOCLOBBER_REQUIREDPRIVILEGES = 4096;
	public const uint32 SPSVCINST_NOCLOBBER_TRIGGERS = 8192;
	public const uint32 SPSVCINST_NOCLOBBER_SERVICESIDTYPE = 16384;
	public const uint32 SPSVCINST_NOCLOBBER_DELAYEDAUTOSTART = 32768;
	public const uint32 SPSVCINST_UNIQUE_NAME = 65536;
	public const uint32 SPFILELOG_SYSTEMLOG = 1;
	public const uint32 SPFILELOG_FORCENEW = 2;
	public const uint32 SPFILELOG_QUERYONLY = 4;
	public const uint32 SPFILELOG_OEMFILE = 1;
	public const uint32 LogSevInformation = 0;
	public const uint32 LogSevWarning = 1;
	public const uint32 LogSevError = 2;
	public const uint32 LogSevFatalError = 3;
	public const uint32 LogSevMaximum = 4;
	public const uint32 DICD_GENERATE_ID = 1;
	public const uint32 DICD_INHERIT_CLASSDRVS = 2;
	public const uint32 DIOD_INHERIT_CLASSDRVS = 2;
	public const uint32 DIOD_CANCEL_REMOVE = 4;
	public const uint32 DIODI_NO_ADD = 1;
	public const uint32 SPRDI_FIND_DUPS = 1;
	public const uint32 SPDIT_NODRIVER = 0;
	public const uint32 DIGCF_DEFAULT = 1;
	public const uint32 DIGCF_PRESENT = 2;
	public const uint32 DIGCF_ALLCLASSES = 4;
	public const uint32 DIGCF_PROFILE = 8;
	public const uint32 DIGCF_DEVICEINTERFACE = 16;
	public const uint32 DIGCF_INTERFACEDEVICE = 16;
	public const uint32 DIBCI_NOINSTALLCLASS = 1;
	public const uint32 DIBCI_NODISPLAYCLASS = 2;
	public const uint32 DIOCR_INSTALLER = 1;
	public const uint32 DIOCR_INTERFACE = 2;
	public const uint32 DIREG_DEV = 1;
	public const uint32 DIREG_DRV = 2;
	public const uint32 DIREG_BOTH = 4;
	public const uint32 DICLASSPROP_INSTALLER = 1;
	public const uint32 DICLASSPROP_INTERFACE = 2;
	public const uint32 SPDRP_DEVICEDESC = 0;
	public const uint32 SPDRP_HARDWAREID = 1;
	public const uint32 SPDRP_COMPATIBLEIDS = 2;
	public const uint32 SPDRP_UNUSED0 = 3;
	public const uint32 SPDRP_SERVICE = 4;
	public const uint32 SPDRP_UNUSED1 = 5;
	public const uint32 SPDRP_UNUSED2 = 6;
	public const uint32 SPDRP_CLASS = 7;
	public const uint32 SPDRP_CLASSGUID = 8;
	public const uint32 SPDRP_DRIVER = 9;
	public const uint32 SPDRP_CONFIGFLAGS = 10;
	public const uint32 SPDRP_MFG = 11;
	public const uint32 SPDRP_FRIENDLYNAME = 12;
	public const uint32 SPDRP_LOCATION_INFORMATION = 13;
	public const uint32 SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = 14;
	public const uint32 SPDRP_CAPABILITIES = 15;
	public const uint32 SPDRP_UI_NUMBER = 16;
	public const uint32 SPDRP_UPPERFILTERS = 17;
	public const uint32 SPDRP_LOWERFILTERS = 18;
	public const uint32 SPDRP_BUSTYPEGUID = 19;
	public const uint32 SPDRP_LEGACYBUSTYPE = 20;
	public const uint32 SPDRP_BUSNUMBER = 21;
	public const uint32 SPDRP_ENUMERATOR_NAME = 22;
	public const uint32 SPDRP_SECURITY = 23;
	public const uint32 SPDRP_SECURITY_SDS = 24;
	public const uint32 SPDRP_DEVTYPE = 25;
	public const uint32 SPDRP_EXCLUSIVE = 26;
	public const uint32 SPDRP_CHARACTERISTICS = 27;
	public const uint32 SPDRP_ADDRESS = 28;
	public const uint32 SPDRP_UI_NUMBER_DESC_FORMAT = 29;
	public const uint32 SPDRP_DEVICE_POWER_DATA = 30;
	public const uint32 SPDRP_REMOVAL_POLICY = 31;
	public const uint32 SPDRP_REMOVAL_POLICY_HW_DEFAULT = 32;
	public const uint32 SPDRP_REMOVAL_POLICY_OVERRIDE = 33;
	public const uint32 SPDRP_INSTALL_STATE = 34;
	public const uint32 SPDRP_LOCATION_PATHS = 35;
	public const uint32 SPDRP_BASE_CONTAINERID = 36;
	public const uint32 SPDRP_MAXIMUM_PROPERTY = 37;
	public const uint32 SPCRP_UPPERFILTERS = 17;
	public const uint32 SPCRP_LOWERFILTERS = 18;
	public const uint32 SPCRP_SECURITY = 23;
	public const uint32 SPCRP_SECURITY_SDS = 24;
	public const uint32 SPCRP_DEVTYPE = 25;
	public const uint32 SPCRP_EXCLUSIVE = 26;
	public const uint32 SPCRP_CHARACTERISTICS = 27;
	public const uint32 SPCRP_MAXIMUM_PROPERTY = 28;
	public const uint32 DMI_MASK = 1;
	public const uint32 DMI_BKCOLOR = 2;
	public const uint32 DMI_USERECT = 4;
	public const uint32 DIGCDP_FLAG_BASIC = 1;
	public const uint32 DIGCDP_FLAG_ADVANCED = 2;
	public const uint32 DIGCDP_FLAG_REMOTE_BASIC = 3;
	public const uint32 DIGCDP_FLAG_REMOTE_ADVANCED = 4;
	public const uint32 IDI_RESOURCEFIRST = 159;
	public const uint32 IDI_RESOURCE = 159;
	public const uint32 IDI_RESOURCELAST = 161;
	public const uint32 IDI_RESOURCEOVERLAYFIRST = 161;
	public const uint32 IDI_RESOURCEOVERLAYLAST = 161;
	public const uint32 IDI_CONFLICT = 161;
	public const uint32 IDI_CLASSICON_OVERLAYFIRST = 500;
	public const uint32 IDI_CLASSICON_OVERLAYLAST = 502;
	public const uint32 IDI_PROBLEM_OVL = 500;
	public const uint32 IDI_DISABLED_OVL = 501;
	public const uint32 IDI_FORCED_OVL = 502;
	public const uint32 SPWPT_SELECTDEVICE = 1;
	public const uint32 SPWP_USE_DEVINFO_DATA = 1;
	public const uint32 SIGNERSCORE_UNKNOWN = 4278190080;
	public const uint32 SIGNERSCORE_W9X_SUSPECT = 3221225472;
	public const uint32 SIGNERSCORE_UNSIGNED = 2147483648;
	public const uint32 SIGNERSCORE_AUTHENTICODE = 251658240;
	public const uint32 SIGNERSCORE_WHQL = 218103813;
	public const uint32 SIGNERSCORE_UNCLASSIFIED = 218103812;
	public const uint32 SIGNERSCORE_INBOX = 218103811;
	public const uint32 SIGNERSCORE_LOGO_STANDARD = 218103810;
	public const uint32 SIGNERSCORE_LOGO_PREMIUM = 218103809;
	public const uint32 SIGNERSCORE_MASK = 4278190080;
	public const uint32 SIGNERSCORE_SIGNED_MASK = 4026531840;
	public const uint32 DICUSTOMDEVPROP_MERGE_MULTISZ = 1;
	public const uint32 SCWMI_CLOBBER_SECURITY = 1;
	public const uint32 MAX_DEVICE_ID_LEN = 200;
	public const uint32 MAX_DEVNODE_ID_LEN = 200;
	public const uint32 MAX_GUID_STRING_LEN = 39;
	public const uint32 MAX_CLASS_NAME_LEN = 32;
	public const uint32 MAX_PROFILE_LEN = 80;
	public const uint32 MAX_CONFIG_VALUE = 9999;
	public const uint32 MAX_INSTANCE_VALUE = 9999;
	public const uint32 MAX_MEM_REGISTERS = 9;
	public const uint32 MAX_IO_PORTS = 20;
	public const uint32 MAX_IRQS = 7;
	public const uint32 MAX_DMA_CHANNELS = 7;
	public const uint32 DWORD_MAX = 4294967295;
	public const uint32 CONFIGMG_VERSION = 1024;
	public const uint32 CM_CDMASK_DEVINST = 1;
	public const uint32 CM_CDMASK_RESDES = 2;
	public const uint32 CM_CDMASK_FLAGS = 4;
	public const uint32 CM_CDMASK_DESCRIPTION = 8;
	public const uint32 CM_CDMASK_VALID = 15;
	public const uint32 CM_CDFLAGS_DRIVER = 1;
	public const uint32 CM_CDFLAGS_ROOT_OWNED = 2;
	public const uint32 CM_CDFLAGS_RESERVED = 4;
	public const uint32 mMD_MemoryType = 1;
	public const uint32 fMD_MemoryType = 1;
	public const uint32 fMD_ROM = 0;
	public const uint32 fMD_RAM = 1;
	public const uint32 mMD_32_24 = 2;
	public const uint32 fMD_32_24 = 2;
	public const uint32 fMD_24 = 0;
	public const uint32 fMD_32 = 2;
	public const uint32 mMD_Prefetchable = 4;
	public const uint32 fMD_Prefetchable = 4;
	public const uint32 fMD_Pref = 4;
	public const uint32 fMD_PrefetchDisallowed = 0;
	public const uint32 fMD_PrefetchAllowed = 4;
	public const uint32 mMD_Readable = 8;
	public const uint32 fMD_Readable = 8;
	public const uint32 fMD_ReadAllowed = 0;
	public const uint32 fMD_ReadDisallowed = 8;
	public const uint32 mMD_CombinedWrite = 16;
	public const uint32 fMD_CombinedWrite = 16;
	public const uint32 fMD_CombinedWriteDisallowed = 0;
	public const uint32 fMD_CombinedWriteAllowed = 16;
	public const uint32 mMD_Cacheable = 32;
	public const uint32 fMD_NonCacheable = 0;
	public const uint32 fMD_Cacheable = 32;
	public const uint32 fMD_WINDOW_DECODE = 64;
	public const uint32 fMD_MEMORY_BAR = 128;
	public const uint32 fIOD_PortType = 1;
	public const uint32 fIOD_Memory = 0;
	public const uint32 fIOD_IO = 1;
	public const uint32 fIOD_DECODE = 252;
	public const uint32 fIOD_10_BIT_DECODE = 4;
	public const uint32 fIOD_12_BIT_DECODE = 8;
	public const uint32 fIOD_16_BIT_DECODE = 16;
	public const uint32 fIOD_POSITIVE_DECODE = 32;
	public const uint32 fIOD_PASSIVE_DECODE = 64;
	public const uint32 fIOD_WINDOW_DECODE = 128;
	public const uint32 fIOD_PORT_BAR = 256;
	public const uint32 IO_ALIAS_10_BIT_DECODE = 4;
	public const uint32 IO_ALIAS_12_BIT_DECODE = 16;
	public const uint32 IO_ALIAS_16_BIT_DECODE = 0;
	public const uint32 IO_ALIAS_POSITIVE_DECODE = 255;
	public const uint32 IOA_Local = 255;
	public const uint32 mDD_Width = 3;
	public const uint32 fDD_BYTE = 0;
	public const uint32 fDD_WORD = 1;
	public const uint32 fDD_DWORD = 2;
	public const uint32 fDD_BYTE_AND_WORD = 3;
	public const uint32 mDD_BusMaster = 4;
	public const uint32 fDD_NoBusMaster = 0;
	public const uint32 fDD_BusMaster = 4;
	public const uint32 mDD_Type = 24;
	public const uint32 fDD_TypeStandard = 0;
	public const uint32 fDD_TypeA = 8;
	public const uint32 fDD_TypeB = 16;
	public const uint32 fDD_TypeF = 24;
	public const uint32 mIRQD_Share = 1;
	public const uint32 fIRQD_Exclusive = 0;
	public const uint32 fIRQD_Share = 1;
	public const uint32 fIRQD_Share_Bit = 0;
	public const uint32 fIRQD_Level_Bit = 1;
	public const uint32 mIRQD_Edge_Level = 2;
	public const uint32 fIRQD_Level = 0;
	public const uint32 fIRQD_Edge = 2;
	public const uint32 CM_RESDES_WIDTH_DEFAULT = 0;
	public const uint32 CM_RESDES_WIDTH_32 = 1;
	public const uint32 CM_RESDES_WIDTH_64 = 2;
	public const uint32 CM_RESDES_WIDTH_BITS = 3;
	public const uint32 mPCD_IO_8_16 = 1;
	public const uint32 fPCD_IO_8 = 0;
	public const uint32 fPCD_IO_16 = 1;
	public const uint32 mPCD_MEM_8_16 = 2;
	public const uint32 fPCD_MEM_8 = 0;
	public const uint32 fPCD_MEM_16 = 2;
	public const uint32 mPCD_MEM_A_C = 12;
	public const uint32 fPCD_MEM1_A = 4;
	public const uint32 fPCD_MEM2_A = 8;
	public const uint32 fPCD_IO_ZW_8 = 16;
	public const uint32 fPCD_IO_SRC_16 = 32;
	public const uint32 fPCD_IO_WS_16 = 64;
	public const uint32 mPCD_MEM_WS = 768;
	public const uint32 fPCD_MEM_WS_ONE = 256;
	public const uint32 fPCD_MEM_WS_TWO = 512;
	public const uint32 fPCD_MEM_WS_THREE = 768;
	public const uint32 fPCD_MEM_A = 4;
	public const uint32 fPCD_ATTRIBUTES_PER_WINDOW = 32768;
	public const uint32 fPCD_IO1_16 = 65536;
	public const uint32 fPCD_IO1_ZW_8 = 131072;
	public const uint32 fPCD_IO1_SRC_16 = 262144;
	public const uint32 fPCD_IO1_WS_16 = 524288;
	public const uint32 fPCD_IO2_16 = 1048576;
	public const uint32 fPCD_IO2_ZW_8 = 2097152;
	public const uint32 fPCD_IO2_SRC_16 = 4194304;
	public const uint32 fPCD_IO2_WS_16 = 8388608;
	public const uint32 mPCD_MEM1_WS = 50331648;
	public const uint32 fPCD_MEM1_WS_ONE = 16777216;
	public const uint32 fPCD_MEM1_WS_TWO = 33554432;
	public const uint32 fPCD_MEM1_WS_THREE = 50331648;
	public const uint32 fPCD_MEM1_16 = 67108864;
	public const uint32 mPCD_MEM2_WS = 805306368;
	public const uint32 fPCD_MEM2_WS_ONE = 268435456;
	public const uint32 fPCD_MEM2_WS_TWO = 536870912;
	public const uint32 fPCD_MEM2_WS_THREE = 805306368;
	public const uint32 fPCD_MEM2_16 = 1073741824;
	public const uint32 PCD_MAX_MEMORY = 2;
	public const uint32 PCD_MAX_IO = 2;
	public const uint32 mPMF_AUDIO_ENABLE = 8;
	public const uint32 fPMF_AUDIO_ENABLE = 8;
	public const uint32 CM_HWPI_NOT_DOCKABLE = 0;
	public const uint32 CM_HWPI_UNDOCKED = 1;
	public const uint32 CM_HWPI_DOCKED = 2;
	public const uint32 ResType_All = 0;
	public const uint32 ResType_None = 0;
	public const uint32 ResType_Mem = 1;
	public const uint32 ResType_IO = 2;
	public const uint32 ResType_DMA = 3;
	public const uint32 ResType_IRQ = 4;
	public const uint32 ResType_DoNotUse = 5;
	public const uint32 ResType_BusNumber = 6;
	public const uint32 ResType_MemLarge = 7;
	public const uint32 ResType_MAX = 7;
	public const uint32 ResType_Ignored_Bit = 32768;
	public const uint32 ResType_ClassSpecific = 65535;
	public const uint32 ResType_Reserved = 32768;
	public const uint32 ResType_DevicePrivate = 32769;
	public const uint32 ResType_PcCardConfig = 32770;
	public const uint32 ResType_MfCardConfig = 32771;
	public const uint32 ResType_Connection = 32772;
	public const uint32 CM_ADD_RANGE_ADDIFCONFLICT = 0;
	public const uint32 CM_ADD_RANGE_DONOTADDIFCONFLICT = 1;
	public const uint32 CM_ADD_RANGE_BITS = 1;
	public const uint32 BASIC_LOG_CONF = 0;
	public const uint32 FILTERED_LOG_CONF = 1;
	public const uint32 ALLOC_LOG_CONF = 2;
	public const uint32 BOOT_LOG_CONF = 3;
	public const uint32 FORCED_LOG_CONF = 4;
	public const uint32 OVERRIDE_LOG_CONF = 5;
	public const uint32 NUM_LOG_CONF = 6;
	public const uint32 LOG_CONF_BITS = 7;
	public const uint32 PRIORITY_EQUAL_FIRST = 8;
	public const uint32 PRIORITY_EQUAL_LAST = 0;
	public const uint32 PRIORITY_BIT = 8;
	public const uint32 RegDisposition_OpenAlways = 0;
	public const uint32 RegDisposition_OpenExisting = 1;
	public const uint32 RegDisposition_Bits = 1;
	public const uint32 CM_ADD_ID_HARDWARE = 0;
	public const uint32 CM_ADD_ID_COMPATIBLE = 1;
	public const uint32 CM_ADD_ID_BITS = 1;
	public const uint32 CM_CREATE_DEVNODE_NORMAL = 0;
	public const uint32 CM_CREATE_DEVNODE_NO_WAIT_INSTALL = 1;
	public const uint32 CM_CREATE_DEVNODE_PHANTOM = 2;
	public const uint32 CM_CREATE_DEVNODE_GENERATE_ID = 4;
	public const uint32 CM_CREATE_DEVNODE_DO_NOT_INSTALL = 8;
	public const uint32 CM_CREATE_DEVNODE_BITS = 15;
	public const uint32 CM_CREATE_DEVINST_NORMAL = 0;
	public const uint32 CM_CREATE_DEVINST_NO_WAIT_INSTALL = 1;
	public const uint32 CM_CREATE_DEVINST_PHANTOM = 2;
	public const uint32 CM_CREATE_DEVINST_GENERATE_ID = 4;
	public const uint32 CM_CREATE_DEVINST_DO_NOT_INSTALL = 8;
	public const uint32 CM_CREATE_DEVINST_BITS = 15;
	public const uint32 CM_DELETE_CLASS_ONLY = 0;
	public const uint32 CM_DELETE_CLASS_SUBKEYS = 1;
	public const uint32 CM_DELETE_CLASS_INTERFACE = 2;
	public const uint32 CM_DELETE_CLASS_BITS = 3;
	public const uint32 CM_ENUMERATE_CLASSES_INSTALLER = 0;
	public const uint32 CM_ENUMERATE_CLASSES_INTERFACE = 1;
	public const uint32 CM_ENUMERATE_CLASSES_BITS = 1;
	public const uint32 CM_DETECT_NEW_PROFILE = 1;
	public const uint32 CM_DETECT_CRASHED = 2;
	public const uint32 CM_DETECT_HWPROF_FIRST_BOOT = 4;
	public const uint32 CM_DETECT_RUN = 2147483648;
	public const uint32 CM_DETECT_BITS = 2147483655;
	public const uint32 CM_DISABLE_POLITE = 0;
	public const uint32 CM_DISABLE_ABSOLUTE = 1;
	public const uint32 CM_DISABLE_HARDWARE = 2;
	public const uint32 CM_DISABLE_UI_NOT_OK = 4;
	public const uint32 CM_DISABLE_PERSIST = 8;
	public const uint32 CM_DISABLE_BITS = 15;
	public const uint32 CM_GETIDLIST_FILTER_NONE = 0;
	public const uint32 CM_GETIDLIST_FILTER_ENUMERATOR = 1;
	public const uint32 CM_GETIDLIST_FILTER_SERVICE = 2;
	public const uint32 CM_GETIDLIST_FILTER_EJECTRELATIONS = 4;
	public const uint32 CM_GETIDLIST_FILTER_REMOVALRELATIONS = 8;
	public const uint32 CM_GETIDLIST_FILTER_POWERRELATIONS = 16;
	public const uint32 CM_GETIDLIST_FILTER_BUSRELATIONS = 32;
	public const uint32 CM_GETIDLIST_DONOTGENERATE = 268435520;
	public const uint32 CM_GETIDLIST_FILTER_BITS = 268435583;
	public const uint32 CM_GETIDLIST_FILTER_TRANSPORTRELATIONS = 128;
	public const uint32 CM_GETIDLIST_FILTER_PRESENT = 256;
	public const uint32 CM_GETIDLIST_FILTER_CLASS = 512;
	public const uint32 CM_GET_DEVICE_INTERFACE_LIST_PRESENT = 0;
	public const uint32 CM_GET_DEVICE_INTERFACE_LIST_ALL_DEVICES = 1;
	public const uint32 CM_GET_DEVICE_INTERFACE_LIST_BITS = 1;
	public const uint32 CM_DRP_DEVICEDESC = 1;
	public const uint32 CM_DRP_HARDWAREID = 2;
	public const uint32 CM_DRP_COMPATIBLEIDS = 3;
	public const uint32 CM_DRP_UNUSED0 = 4;
	public const uint32 CM_DRP_SERVICE = 5;
	public const uint32 CM_DRP_UNUSED1 = 6;
	public const uint32 CM_DRP_UNUSED2 = 7;
	public const uint32 CM_DRP_CLASS = 8;
	public const uint32 CM_DRP_CLASSGUID = 9;
	public const uint32 CM_DRP_DRIVER = 10;
	public const uint32 CM_DRP_CONFIGFLAGS = 11;
	public const uint32 CM_DRP_MFG = 12;
	public const uint32 CM_DRP_FRIENDLYNAME = 13;
	public const uint32 CM_DRP_LOCATION_INFORMATION = 14;
	public const uint32 CM_DRP_PHYSICAL_DEVICE_OBJECT_NAME = 15;
	public const uint32 CM_DRP_CAPABILITIES = 16;
	public const uint32 CM_DRP_UI_NUMBER = 17;
	public const uint32 CM_DRP_UPPERFILTERS = 18;
	public const uint32 CM_CRP_UPPERFILTERS = 18;
	public const uint32 CM_DRP_LOWERFILTERS = 19;
	public const uint32 CM_CRP_LOWERFILTERS = 19;
	public const uint32 CM_DRP_BUSTYPEGUID = 20;
	public const uint32 CM_DRP_LEGACYBUSTYPE = 21;
	public const uint32 CM_DRP_BUSNUMBER = 22;
	public const uint32 CM_DRP_ENUMERATOR_NAME = 23;
	public const uint32 CM_DRP_SECURITY = 24;
	public const uint32 CM_CRP_SECURITY = 24;
	public const uint32 CM_DRP_SECURITY_SDS = 25;
	public const uint32 CM_CRP_SECURITY_SDS = 25;
	public const uint32 CM_DRP_DEVTYPE = 26;
	public const uint32 CM_CRP_DEVTYPE = 26;
	public const uint32 CM_DRP_EXCLUSIVE = 27;
	public const uint32 CM_CRP_EXCLUSIVE = 27;
	public const uint32 CM_DRP_CHARACTERISTICS = 28;
	public const uint32 CM_CRP_CHARACTERISTICS = 28;
	public const uint32 CM_DRP_ADDRESS = 29;
	public const uint32 CM_DRP_UI_NUMBER_DESC_FORMAT = 30;
	public const uint32 CM_DRP_DEVICE_POWER_DATA = 31;
	public const uint32 CM_DRP_REMOVAL_POLICY = 32;
	public const uint32 CM_DRP_REMOVAL_POLICY_HW_DEFAULT = 33;
	public const uint32 CM_DRP_REMOVAL_POLICY_OVERRIDE = 34;
	public const uint32 CM_DRP_INSTALL_STATE = 35;
	public const uint32 CM_DRP_LOCATION_PATHS = 36;
	public const uint32 CM_DRP_BASE_CONTAINERID = 37;
	public const uint32 CM_DRP_MIN = 1;
	public const uint32 CM_CRP_MIN = 1;
	public const uint32 CM_DRP_MAX = 37;
	public const uint32 CM_CRP_MAX = 37;
	public const uint32 CM_DEVCAP_LOCKSUPPORTED = 1;
	public const uint32 CM_DEVCAP_EJECTSUPPORTED = 2;
	public const uint32 CM_DEVCAP_REMOVABLE = 4;
	public const uint32 CM_DEVCAP_DOCKDEVICE = 8;
	public const uint32 CM_DEVCAP_UNIQUEID = 16;
	public const uint32 CM_DEVCAP_SILENTINSTALL = 32;
	public const uint32 CM_DEVCAP_RAWDEVICEOK = 64;
	public const uint32 CM_DEVCAP_SURPRISEREMOVALOK = 128;
	public const uint32 CM_DEVCAP_HARDWAREDISABLED = 256;
	public const uint32 CM_DEVCAP_NONDYNAMIC = 512;
	public const uint32 CM_DEVCAP_SECUREDEVICE = 1024;
	public const uint32 CM_REMOVAL_POLICY_EXPECT_NO_REMOVAL = 1;
	public const uint32 CM_REMOVAL_POLICY_EXPECT_ORDERLY_REMOVAL = 2;
	public const uint32 CM_REMOVAL_POLICY_EXPECT_SURPRISE_REMOVAL = 3;
	public const uint32 CM_INSTALL_STATE_INSTALLED = 0;
	public const uint32 CM_INSTALL_STATE_NEEDS_REINSTALL = 1;
	public const uint32 CM_INSTALL_STATE_FAILED_INSTALL = 2;
	public const uint32 CM_INSTALL_STATE_FINISH_INSTALL = 3;
	public const uint32 CM_LOCATE_DEVNODE_NORMAL = 0;
	public const uint32 CM_LOCATE_DEVNODE_PHANTOM = 1;
	public const uint32 CM_LOCATE_DEVNODE_CANCELREMOVE = 2;
	public const uint32 CM_LOCATE_DEVNODE_NOVALIDATION = 4;
	public const uint32 CM_LOCATE_DEVNODE_BITS = 7;
	public const uint32 CM_LOCATE_DEVINST_NORMAL = 0;
	public const uint32 CM_LOCATE_DEVINST_PHANTOM = 1;
	public const uint32 CM_LOCATE_DEVINST_CANCELREMOVE = 2;
	public const uint32 CM_LOCATE_DEVINST_NOVALIDATION = 4;
	public const uint32 CM_LOCATE_DEVINST_BITS = 7;
	public const uint32 CM_OPEN_CLASS_KEY_INSTALLER = 0;
	public const uint32 CM_OPEN_CLASS_KEY_INTERFACE = 1;
	public const uint32 CM_OPEN_CLASS_KEY_BITS = 1;
	public const uint32 CM_REMOVE_UI_OK = 0;
	public const uint32 CM_REMOVE_UI_NOT_OK = 1;
	public const uint32 CM_REMOVE_NO_RESTART = 2;
	public const uint32 CM_REMOVE_DISABLE = 4;
	public const uint32 CM_REMOVE_BITS = 7;
	public const uint32 CM_QUERY_REMOVE_UI_OK = 0;
	public const uint32 CM_QUERY_REMOVE_UI_NOT_OK = 1;
	public const uint32 CM_REENUMERATE_NORMAL = 0;
	public const uint32 CM_REENUMERATE_SYNCHRONOUS = 1;
	public const uint32 CM_REENUMERATE_RETRY_INSTALLATION = 2;
	public const uint32 CM_REENUMERATE_ASYNCHRONOUS = 4;
	public const uint32 CM_REENUMERATE_BITS = 7;
	public const uint32 CM_REGISTER_DEVICE_DRIVER_STATIC = 0;
	public const uint32 CM_REGISTER_DEVICE_DRIVER_DISABLEABLE = 1;
	public const uint32 CM_REGISTER_DEVICE_DRIVER_REMOVABLE = 2;
	public const uint32 CM_REGISTER_DEVICE_DRIVER_BITS = 3;
	public const uint32 CM_REGISTRY_HARDWARE = 0;
	public const uint32 CM_REGISTRY_SOFTWARE = 1;
	public const uint32 CM_REGISTRY_USER = 256;
	public const uint32 CM_REGISTRY_CONFIG = 512;
	public const uint32 CM_REGISTRY_BITS = 769;
	public const uint32 CM_SET_DEVNODE_PROBLEM_NORMAL = 0;
	public const uint32 CM_SET_DEVNODE_PROBLEM_OVERRIDE = 1;
	public const uint32 CM_SET_DEVNODE_PROBLEM_BITS = 1;
	public const uint32 CM_SET_DEVINST_PROBLEM_NORMAL = 0;
	public const uint32 CM_SET_DEVINST_PROBLEM_OVERRIDE = 1;
	public const uint32 CM_SET_DEVINST_PROBLEM_BITS = 1;
	public const uint32 CM_SET_HW_PROF_FLAGS_UI_NOT_OK = 1;
	public const uint32 CM_SET_HW_PROF_FLAGS_BITS = 1;
	public const uint32 CM_SETUP_DEVNODE_READY = 0;
	public const uint32 CM_SETUP_DEVINST_READY = 0;
	public const uint32 CM_SETUP_DOWNLOAD = 1;
	public const uint32 CM_SETUP_WRITE_LOG_CONFS = 2;
	public const uint32 CM_SETUP_PROP_CHANGE = 3;
	public const uint32 CM_SETUP_DEVNODE_RESET = 4;
	public const uint32 CM_SETUP_DEVINST_RESET = 4;
	public const uint32 CM_SETUP_DEVNODE_CONFIG = 5;
	public const uint32 CM_SETUP_DEVINST_CONFIG = 5;
	public const uint32 CM_SETUP_DEVNODE_CONFIG_CLASS = 6;
	public const uint32 CM_SETUP_DEVINST_CONFIG_CLASS = 6;
	public const uint32 CM_SETUP_DEVNODE_CONFIG_EXTENSIONS = 7;
	public const uint32 CM_SETUP_DEVINST_CONFIG_EXTENSIONS = 7;
	public const uint32 CM_SETUP_DEVNODE_CONFIG_RESET = 8;
	public const uint32 CM_SETUP_DEVINST_CONFIG_RESET = 8;
	public const uint32 CM_SETUP_BITS = 15;
	public const uint32 CM_QUERY_ARBITRATOR_RAW = 0;
	public const uint32 CM_QUERY_ARBITRATOR_TRANSLATED = 1;
	public const uint32 CM_QUERY_ARBITRATOR_BITS = 1;
	public const uint32 CM_CUSTOMDEVPROP_MERGE_MULTISZ = 1;
	public const uint32 CM_CUSTOMDEVPROP_BITS = 1;
	public const uint32 CM_NAME_ATTRIBUTE_NAME_RETRIEVED_FROM_DEVICE = 1;
	public const uint32 CM_NAME_ATTRIBUTE_USER_ASSIGNED_NAME = 2;
	public const uint32 CM_CLASS_PROPERTY_INSTALLER = 0;
	public const uint32 CM_CLASS_PROPERTY_INTERFACE = 1;
	public const uint32 CM_CLASS_PROPERTY_BITS = 1;
	public const uint32 CM_NOTIFY_FILTER_FLAG_ALL_INTERFACE_CLASSES = 1;
	public const uint32 CM_NOTIFY_FILTER_FLAG_ALL_DEVICE_INSTANCES = 2;
	public const uint32 CM_GLOBAL_STATE_CAN_DO_UI = 1;
	public const uint32 CM_GLOBAL_STATE_ON_BIG_STACK = 2;
	public const uint32 CM_GLOBAL_STATE_SERVICES_AVAILABLE = 4;
	public const uint32 CM_GLOBAL_STATE_SHUTTING_DOWN = 8;
	public const uint32 CM_GLOBAL_STATE_DETECTION_PENDING = 16;
	public const uint32 CM_GLOBAL_STATE_REBOOT_REQUIRED = 32;
	public const uint32 INSTALLFLAG_FORCE = 1;
	public const uint32 INSTALLFLAG_READONLY = 2;
	public const uint32 INSTALLFLAG_NONINTERACTIVE = 4;
	public const uint32 INSTALLFLAG_BITS = 7;
	public const uint32 DIIDFLAG_SHOWSEARCHUI = 1;
	public const uint32 DIIDFLAG_NOFINISHINSTALLUI = 2;
	public const uint32 DIIDFLAG_INSTALLNULLDRIVER = 4;
	public const uint32 DIIDFLAG_INSTALLCOPYINFDRIVERS = 8;
	public const uint32 DIIDFLAG_BITS = 15;
	public const uint32 DIIRFLAG_INF_ALREADY_COPIED = 1;
	public const uint32 DIIRFLAG_FORCE_INF = 2;
	public const uint32 DIIRFLAG_HW_USING_THE_INF = 4;
	public const uint32 DIIRFLAG_HOTPATCH = 8;
	public const uint32 DIIRFLAG_NOBACKUP = 16;
	public const uint32 DIIRFLAG_PRE_CONFIGURE_INF = 32;
	public const uint32 DIIRFLAG_INSTALL_AS_SET = 64;
	public const uint32 DIURFLAG_NO_REMOVE_INF = 1;
	public const uint32 DIURFLAG_RESERVED = 2;
	public const uint32 ROLLBACK_FLAG_NO_UI = 1;
	public const uint32 ROLLBACK_BITS = 1;
	public const uint32 MAX_KEY_LEN = 100;
	public const String SZ_KEY_OPTIONDESC = "OptionDesc";
	public const String SZ_KEY_LDIDOEM = "LdidOEM";
	public const String SZ_KEY_SRCDISKFILES = "SourceDisksFiles";
	public const String SZ_KEY_SRCDISKNAMES = "SourceDisksNames";
	public const String SZ_KEY_STRINGS = "Strings";
	public const String SZ_KEY_DESTDIRS = "DestinationDirs";
	public const String SZ_KEY_LAYOUT_FILE = "LayoutFile";
	public const String SZ_KEY_DEFDESTDIR = "DefaultDestDir";
	public const String SZ_KEY_LFN_SECTION = "VarLDID.LFN";
	public const String SZ_KEY_SFN_SECTION = "VarLDID.SFN";
	public const String SZ_KEY_UPDATEINIS = "UpdateInis";
	public const String SZ_KEY_UPDATEINIFIELDS = "UpdateIniFields";
	public const String SZ_KEY_INI2REG = "Ini2Reg";
	public const String SZ_KEY_COPYFILES = "CopyFiles";
	public const String SZ_KEY_RENFILES = "RenFiles";
	public const String SZ_KEY_DELFILES = "DelFiles";
	public const String SZ_KEY_ADDREG = "AddReg";
	public const String SZ_KEY_ADDREGNOCLOBBER = "AddRegNoClobber";
	public const String SZ_KEY_DELREG = "DelReg";
	public const String SZ_KEY_BITREG = "BitReg";
	public const String SZ_KEY_COPYINF = "CopyINF";
	public const String SZ_KEY_LOGCONFIG = "LogConfig";
	public const String SZ_KEY_ADDSERVICE = "AddService";
	public const String SZ_KEY_DELSERVICE = "DelService";
	public const String SZ_KEY_ADDTRIGGER = "AddTrigger";
	public const String SZ_KEY_ADDINTERFACE = "AddInterface";
	public const String SZ_KEY_ADDIME = "AddIme";
	public const String SZ_KEY_DELIME = "DelIme";
	public const String SZ_KEY_REGSVR = "RegisterDlls";
	public const String SZ_KEY_UNREGSVR = "UnregisterDlls";
	public const String SZ_KEY_PROFILEITEMS = "ProfileItems";
	public const String SZ_KEY_MODULES = "Modules";
	public const String SZ_KEY_DEFAULTOPTION = "DefaultOption";
	public const String SZ_KEY_LISTOPTIONS = "ListOptions";
	public const String SZ_KEY_CLEANONLY = "CleanOnly";
	public const String SZ_KEY_UPGRADEONLY = "UpgradeOnly";
	public const String SZ_KEY_EXCLUDEID = "ExcludeId";
	public const String SZ_KEY_ADDPOWERSETTING = "AddPowerSetting";
	public const String SZ_KEY_ADDPROP = "AddProperty";
	public const String SZ_KEY_DELPROP = "DelProperty";
	public const String SZ_KEY_FEATURESCORE = "FeatureScore";
	public const String SZ_KEY_ADDEVENTPROVIDER = "AddEventProvider";
	public const String SZ_KEY_ADDCHANNEL = "AddChannel";
	public const String SZ_KEY_IMPORTCHANNEL = "ImportChannel";
	public const String SZ_KEY_ADDAUTOLOGGER = "AddAutoLogger";
	public const String SZ_KEY_UPDATEAUTOLOGGER = "UpdateAutoLogger";
	public const String SZ_KEY_ADDAUTOLOGGERPROVIDER = "AddAutoLoggerProvider";
	public const String SZ_KEY_ADDFILTER = "AddFilter";
	public const String SZ_KEY_FILTERLEVEL = "FilterLevel";
	public const String SZ_KEY_FILTERPOSITION = "FilterPosition";
	public const String SZ_KEY_PHASE1 = "Phase1";
	public const String SZ_KEY_HARDWARE = "Hardware";
	public const String INFSTR_KEY_CONFIGPRIORITY = "ConfigPriority";
	public const uint32 MAX_PRIORITYSTR_LEN = 16;
	public const String INFSTR_CFGPRI_HARDWIRED = "HARDWIRED";
	public const String INFSTR_CFGPRI_DESIRED = "DESIRED";
	public const String INFSTR_CFGPRI_NORMAL = "NORMAL";
	public const String INFSTR_CFGPRI_SUBOPTIMAL = "SUBOPTIMAL";
	public const String INFSTR_CFGPRI_DISABLED = "DISABLED";
	public const String INFSTR_CFGPRI_RESTART = "RESTART";
	public const String INFSTR_CFGPRI_REBOOT = "REBOOT";
	public const String INFSTR_CFGPRI_POWEROFF = "POWEROFF";
	public const String INFSTR_CFGPRI_HARDRECONFIG = "HARDRECONFIG";
	public const String INFSTR_CFGPRI_FORCECONFIG = "FORCECONFIG";
	public const String INFSTR_CFGTYPE_BASIC = "BASIC";
	public const String INFSTR_CFGTYPE_FORCED = "FORCED";
	public const String INFSTR_CFGTYPE_OVERRIDE = "OVERRIDE";
	public const String INFSTR_KEY_MEMCONFIG = "MemConfig";
	public const String INFSTR_KEY_MEMLARGECONFIG = "MemLargeConfig";
	public const String INFSTR_KEY_IOCONFIG = "IOConfig";
	public const String INFSTR_KEY_IRQCONFIG = "IRQConfig";
	public const String INFSTR_KEY_DMACONFIG = "DMAConfig";
	public const String INFSTR_KEY_PCCARDCONFIG = "PcCardConfig";
	public const String INFSTR_KEY_MFCARDCONFIG = "MfCardConfig";
	public const String INFSTR_SECT_CLASS_INSTALL = "ClassInstall";
	public const String INFSTR_SECT_CLASS_INSTALL_32 = "ClassInstall32";
	public const String INFSTR_SECT_DEFAULT_INSTALL = "DefaultInstall";
	public const String INFSTR_SECT_DEFAULT_UNINSTALL = "DefaultUninstall";
	public const String INFSTR_SECT_INTERFACE_INSTALL_32 = "InterfaceInstall32";
	public const String INFSTR_SECT_VERSION = "Version";
	public const String INFSTR_KEY_PROVIDER = "Provider";
	public const String INFSTR_KEY_SIGNATURE = "Signature";
	public const String INFSTR_KEY_DRIVERSET = "DriverSet";
	public const uint32 MAX_INF_FLAG = 20;
	public const String INFSTR_KEY_HARDWARE_CLASS = "Class";
	public const String INFSTR_KEY_HARDWARE_CLASSGUID = "ClassGUID";
	public const String INFSTR_KEY_NOSETUPINF = "NoSetupInf";
	public const String INFSTR_KEY_FROMINET = "FromINet";
	public const String INFSTR_KEY_CATALOGFILE = "CatalogFile";
	public const String INFSTR_KEY_PNPLOCKDOWN = "PnpLockDown";
	public const String INFSTR_KEY_EXTENSIONID = "ExtensionId";
	public const String INFSTR_SECT_MFG = "Manufacturer";
	public const String INFSTR_SECT_TARGETCOMPUTERS = "TargetComputers";
	public const String INFSTR_SECT_EXTENSIONCONTRACTS = "ExtensionContracts";
	public const String INFSTR_KEY_CLASS = "Class";
	public const String INFSTR_KEY_CLASSGUID = "ClassGUID";
	public const String INFSTR_RESTART = "Restart";
	public const String INFSTR_REBOOT = "Reboot";
	public const String INFSTR_KEY_DISPLAYNAME = "DisplayName";
	public const String INFSTR_KEY_SERVICETYPE = "ServiceType";
	public const String INFSTR_KEY_STARTTYPE = "StartType";
	public const String INFSTR_KEY_ERRORCONTROL = "ErrorControl";
	public const String INFSTR_KEY_SERVICEBINARY = "ServiceBinary";
	public const String INFSTR_KEY_LOADORDERGROUP = "LoadOrderGroup";
	public const String INFSTR_KEY_DEPENDENCIES = "Dependencies";
	public const String INFSTR_KEY_REQUIREDPRIVILEGES = "RequiredPrivileges";
	public const String INFSTR_KEY_STARTNAME = "StartName";
	public const String INFSTR_KEY_SECURITY = "Security";
	public const String INFSTR_KEY_DESCRIPTION = "Description";
	public const String INFSTR_KEY_SERVICESIDTYPE = "ServiceSidType";
	public const String INFSTR_KEY_DELAYEDAUTOSTART = "DelayedAutoStart";
	public const String INFSTR_KEY_TRIGGER_TYPE = "TriggerType";
	public const String INFSTR_KEY_ACTION = "Action";
	public const String INFSTR_KEY_SUB_TYPE = "SubType";
	public const String INFSTR_KEY_DATA_ITEM = "DataItem";
	public const String INFSTR_KEY_PROVIDER_NAME = "ProviderName";
	public const String INFSTR_KEY_RESOURCE_FILE = "ResourceFile";
	public const String INFSTR_KEY_MESSAGE_FILE = "MessageFile";
	public const String INFSTR_KEY_PARAMETER_FILE = "ParameterFile";
	public const String INFSTR_KEY_CHANNEL_ACCESS = "Access";
	public const String INFSTR_KEY_CHANNEL_ISOLATION = "Isolation";
	public const String INFSTR_KEY_CHANNEL_ENABLED = "Enabled";
	public const String INFSTR_KEY_CHANNEL_VALUE = "Value";
	public const String INFSTR_KEY_LOGGING_MAXSIZE = "LoggingMaxSize";
	public const String INFSTR_KEY_LOGGING_RETENTION = "LoggingRetention";
	public const String INFSTR_KEY_LOGGING_AUTOBACKUP = "LoggingAutoBackup";
	public const String INFSTR_KEY_START = "Start";
	public const String INFSTR_KEY_BUFFER_SIZE = "BufferSize";
	public const String INFSTR_KEY_CLOCK_TYPE = "ClockType";
	public const String INFSTR_KEY_DISABLE_REALTIME_PERSISTENCE = "DisableRealtimePersistence";
	public const String INFSTR_KEY_FILE_NAME = "FileName";
	public const String INFSTR_KEY_FILE_MAX = "FileMax";
	public const String INFSTR_KEY_FLUSH_TIMER = "FlushTimer";
	public const String INFSTR_KEY_LOG_FILE_MODE = "LogFileMode";
	public const String INFSTR_KEY_MAX_FILE_SIZE = "MaxFileSize";
	public const String INFSTR_KEY_MAXIMUM_BUFFERS = "MaximumBuffers";
	public const String INFSTR_KEY_MINIMUM_BUFFERS = "MinimumBuffers";
	public const String INFSTR_KEY_ENABLED = "Enabled";
	public const String INFSTR_KEY_ENABLE_FLAGS = "EnableFlags";
	public const String INFSTR_KEY_ENABLE_LEVEL = "EnableLevel";
	public const String INFSTR_KEY_ENABLE_PROPERTY = "EnableProperty";
	public const String INFSTR_KEY_MATCH_ANY_KEYWORD = "MatchAnyKeyword";
	public const String INFSTR_KEY_MATCH_ALL_KEYWORD = "MatchAllKeyword";
	public const String INFSTR_SECT_DETMODULES = "Det.Modules";
	public const String INFSTR_SECT_DETCLASSINFO = "Det.ClassInfo";
	public const String INFSTR_SECT_MANUALDEV = "Det.ManualDev";
	public const String INFSTR_SECT_AVOIDCFGSYSDEV = "Det.AvoidCfgSysDev";
	public const String INFSTR_SECT_REGCFGSYSDEV = "Det.RegCfgSysDev";
	public const String INFSTR_SECT_DEVINFS = "Det.DevINFs";
	public const String INFSTR_SECT_AVOIDINIDEV = "Det.AvoidIniDev";
	public const String INFSTR_SECT_AVOIDENVDEV = "Det.AvoidEnvDev";
	public const String INFSTR_SECT_REGINIDEV = "Det.RegIniDev";
	public const String INFSTR_SECT_REGENVDEV = "Det.RegEnvDev";
	public const String INFSTR_SECT_HPOMNIBOOK = "Det.HPOmnibook";
	public const String INFSTR_SECT_FORCEHWVERIFY = "Det.ForceHWVerify";
	public const String INFSTR_SECT_DETOPTIONS = "Det.Options";
	public const String INFSTR_SECT_BADPNPBIOS = "BadPnpBios";
	public const String INFSTR_SECT_GOODACPIBIOS = "GoodACPIBios";
	public const String INFSTR_SECT_BADACPIBIOS = "BadACPIBios";
	public const String INFSTR_SECT_BADROUTINGTABLEBIOS = "BadPCIIRQRoutingTableBios";
	public const String INFSTR_SECT_BADPMCALLBIOS = "BadProtectedModeCallBios";
	public const String INFSTR_SECT_BADRMCALLBIOS = "BadRealModeCallBios";
	public const String INFSTR_SECT_MACHINEIDBIOS = "MachineIDBios";
	public const String INFSTR_SECT_BADDISKBIOS = "BadDiskBios";
	public const String INFSTR_SECT_BADDSBIOS = "BadDSBios";
	public const String INFSTR_KEY_DETPARAMS = "Params";
	public const String INFSTR_KEY_SKIPLIST = "SkipList";
	public const String INFSTR_KEY_DETECTLIST = "DetectList";
	public const String INFSTR_KEY_EXCLUDERES = "ExcludeRes";
	public const String INFSTR_SUBKEY_LOGCONFIG = "LogConfig";
	public const String INFSTR_SUBKEY_DET = "Det";
	public const String INFSTR_SUBKEY_FACTDEF = "FactDef";
	public const String INFSTR_SUBKEY_POSSIBLEDUPS = "PosDup";
	public const String INFSTR_SUBKEY_NORESOURCEDUPS = "NoResDup";
	public const String INFSTR_SUBKEY_HW = "Hw";
	public const String INFSTR_SUBKEY_CTL = "CTL";
	public const String INFSTR_SUBKEY_SERVICES = "Services";
	public const String INFSTR_SUBKEY_SOFTWARE = "Software";
	public const String INFSTR_SUBKEY_INTERFACES = "Interfaces";
	public const String INFSTR_SUBKEY_COINSTALLERS = "CoInstallers";
	public const String INFSTR_SUBKEY_LOGCONFIGOVERRIDE = "LogConfigOverride";
	public const String INFSTR_SUBKEY_WMI = "WMI";
	public const String INFSTR_SUBKEY_EVENTS = "Events";
	public const String INFSTR_SUBKEY_FILTERS = "Filters";
	public const String INFSTR_CONTROLFLAGS_SECTION = "ControlFlags";
	public const String INFSTR_KEY_COPYFILESONLY = "CopyFilesOnly";
	public const String INFSTR_KEY_EXCLUDEFROMSELECT = "ExcludeFromSelect";
	public const String INFSTR_KEY_ALWAYSEXCLUDEFROMSELECT = "AlwaysExcludeFromSelect";
	public const String INFSTR_KEY_INTERACTIVEINSTALL = "InteractiveInstall";
	public const String INFSTR_KEY_REQUESTADDITIONALSOFTWARE = "RequestAdditionalSoftware";
	public const String INFSTR_PLATFORM_WIN = "Win";
	public const String INFSTR_PLATFORM_NT = "NT";
	public const String INFSTR_PLATFORM_NTX86 = "NTx86";
	public const String INFSTR_PLATFORM_NTMIPS = "NTMIPS";
	public const String INFSTR_PLATFORM_NTALPHA = "NTAlpha";
	public const String INFSTR_PLATFORM_NTPPC = "NTPPC";
	public const String INFSTR_PLATFORM_NTIA64 = "NTIA64";
	public const String INFSTR_PLATFORM_NTAXP64 = "NTAXP64";
	public const String INFSTR_PLATFORM_NTAMD64 = "NTAMD64";
	public const String INFSTR_PLATFORM_NTARM = "NTARM";
	public const String INFSTR_PLATFORM_NTARM64 = "NTARM64";
	public const uint32 MAX_INFSTR_STRKEY_LEN = 32;
	public const String INFSTR_STRKEY_DRVDESC = "DriverDesc";
	public const String INFSTR_DRIVERSELECT_SECTION = "DriverSelect";
	public const String INFSTR_DRIVERSELECT_FUNCTIONS = "DriverSelectFunctions";
	public const String INFSTR_DRIVERVERSION_SECTION = "DriverVer";
	public const String INFSTR_SOFTWAREVERSION_SECTION = "SoftwareVersion";
	public const String INFSTR_SECT_CFGSYS = "ConfigSysDrivers";
	public const String INFSTR_SECT_AUTOEXECBAT = "AutoexecBatDrivers";
	public const String INFSTR_SECT_SYSINI = "SystemIniDrivers";
	public const String INFSTR_SECT_SYSINIDRV = "SystemIniDriversLine";
	public const String INFSTR_SECT_WININIRUN = "WinIniRunLine";
	public const String INFSTR_KEY_PATH = "Path";
	public const String INFSTR_KEY_NAME = "Name";
	public const String INFSTR_KEY_IO = "IO";
	public const String INFSTR_KEY_MEM = "Mem";
	public const String INFSTR_KEY_IRQ = "IRQ";
	public const String INFSTR_KEY_DMA = "DMA";
	public const String INFSTR_BUS_ISA = "BUS_ISA";
	public const String INFSTR_BUS_EISA = "BUS_EISA";
	public const String INFSTR_BUS_MCA = "BUS_MCA";
	public const String INFSTR_BUS_ALL = "BUS_ALL";
	public const String INFSTR_RISK_NONE = "RISK_NONE";
	public const String INFSTR_RISK_VERYLOW = "RISK_VERYLOW";
	public const String INFSTR_RISK_BIOSROMRD = "RISK_BIOSROMRD";
	public const String INFSTR_RISK_QUERYDRV = "RISK_QUERYDRV";
	public const String INFSTR_RISK_SWINT = "RISK_SWINT";
	public const String INFSTR_RISK_LOW = "RISK_LOW";
	public const String INFSTR_RISK_DELICATE = "RISK_DELICATE";
	public const String INFSTR_RISK_MEMRD = "RISK_MEMRD";
	public const String INFSTR_RISK_IORD = "RISK_IORD";
	public const String INFSTR_RISK_MEMWR = "RISK_MEMWR";
	public const String INFSTR_RISK_IOWR = "RISK_IOWR";
	public const String INFSTR_RISK_UNRELIABLE = "RISK_UNRELIABLE";
	public const String INFSTR_RISK_VERYHIGH = "RISK_VERYHIGH";
	public const String INFSTR_CLASS_SAFEEXCL = "SAFE_EXCL";
	public const String INFSTR_SECT_DISPLAY_CLEANUP = "DisplayCleanup";
	public const Guid GUID_HWPROFILE_QUERY_CHANGE = .(0xcb3a4001, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_HWPROFILE_CHANGE_CANCELLED = .(0xcb3a4002, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_HWPROFILE_CHANGE_COMPLETE = .(0xcb3a4003, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_DEVICE_INTERFACE_ARRIVAL = .(0xcb3a4004, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_DEVICE_INTERFACE_REMOVAL = .(0xcb3a4005, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_TARGET_DEVICE_QUERY_REMOVE = .(0xcb3a4006, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_TARGET_DEVICE_REMOVE_CANCELLED = .(0xcb3a4007, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_TARGET_DEVICE_REMOVE_COMPLETE = .(0xcb3a4008, 0x46f0, 0x11d0, 0xb0, 0x8f, 0x00, 0x60, 0x97, 0x13, 0x05, 0x3f);
	public const Guid GUID_PNP_CUSTOM_NOTIFICATION = .(0xaca73f8e, 0x8d23, 0x11d1, 0xac, 0x7d, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xd0);
	public const Guid GUID_PNP_POWER_NOTIFICATION = .(0xc2cf0660, 0xeb7a, 0x11d1, 0xbd, 0x7f, 0x00, 0x00, 0xf8, 0x75, 0x71, 0xd0);
	public const Guid GUID_PNP_POWER_SETTING_CHANGE = .(0x29c69b3e, 0xc79a, 0x43bf, 0xbb, 0xde, 0xa9, 0x32, 0xfa, 0x1b, 0xea, 0x7e);
	public const Guid GUID_TARGET_DEVICE_TRANSPORT_RELATIONS_CHANGED = .(0xfcf528f6, 0xa82f, 0x47b1, 0xad, 0x3a, 0x80, 0x50, 0x59, 0x4c, 0xad, 0x28);
	public const Guid GUID_KERNEL_SOFT_RESTART_PREPARE = .(0xde373def, 0xa85c, 0x4f76, 0x8c, 0xbf, 0xf9, 0x6b, 0xea, 0x8b, 0xd1, 0x0f);
	public const Guid GUID_KERNEL_SOFT_RESTART_CANCEL = .(0x31d737e7, 0x8c0b, 0x468a, 0x95, 0x6e, 0x9f, 0x43, 0x3e, 0xc3, 0x58, 0xfb);
	public const Guid GUID_RECOVERY_PCI_PREPARE_SHUTDOWN = .(0x90d889de, 0x8704, 0x44cf, 0x81, 0x15, 0xed, 0x85, 0x28, 0xd2, 0xb2, 0xda);
	public const Guid GUID_RECOVERY_NVMED_PREPARE_SHUTDOWN = .(0x4b9770ea, 0xbde7, 0x400b, 0xa9, 0xb9, 0x4f, 0x68, 0x4f, 0x54, 0xcc, 0x2a);
	public const Guid GUID_KERNEL_SOFT_RESTART_FINALIZE = .(0x20e91abd, 0x350a, 0x4d4f, 0x85, 0x77, 0x99, 0xc8, 0x15, 0x07, 0x47, 0x3a);
	public const Guid GUID_BUS_INTERFACE_STANDARD = .(0x496b8280, 0x6f25, 0x11d0, 0xbe, 0xaf, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_PCI_BUS_INTERFACE_STANDARD = .(0x496b8281, 0x6f25, 0x11d0, 0xbe, 0xaf, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_PCI_BUS_INTERFACE_STANDARD2 = .(0xde94e966, 0xfdff, 0x4c9c, 0x99, 0x98, 0x67, 0x47, 0xb1, 0x50, 0xe7, 0x4c);
	public const Guid GUID_ARBITER_INTERFACE_STANDARD = .(0xe644f185, 0x8c0e, 0x11d0, 0xbe, 0xcf, 0x08, 0x00, 0x2b, 0xe2, 0x09, 0x2f);
	public const Guid GUID_TRANSLATOR_INTERFACE_STANDARD = .(0x6c154a92, 0xaacf, 0x11d0, 0x8d, 0x2a, 0x00, 0xa0, 0xc9, 0x06, 0xb2, 0x44);
	public const Guid GUID_ACPI_INTERFACE_STANDARD = .(0xb091a08a, 0xba97, 0x11d0, 0xbd, 0x14, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_INT_ROUTE_INTERFACE_STANDARD = .(0x70941bf4, 0x0073, 0x11d1, 0xa0, 0x9e, 0x00, 0xc0, 0x4f, 0xc3, 0x40, 0xb1);
	public const Guid GUID_PCMCIA_BUS_INTERFACE_STANDARD = .(0x76173af0, 0xc504, 0x11d1, 0x94, 0x7f, 0x00, 0xc0, 0x4f, 0xb9, 0x60, 0xee);
	public const Guid GUID_ACPI_REGS_INTERFACE_STANDARD = .(0x06141966, 0x7245, 0x6369, 0x46, 0x2e, 0x4e, 0x65, 0x6c, 0x73, 0x6f, 0x6e);
	public const Guid GUID_LEGACY_DEVICE_DETECTION_STANDARD = .(0x50feb0de, 0x596a, 0x11d2, 0xa5, 0xb8, 0x00, 0x00, 0xf8, 0x1a, 0x46, 0x19);
	public const Guid GUID_PCI_DEVICE_PRESENT_INTERFACE = .(0xd1b82c26, 0xbf49, 0x45ef, 0xb2, 0x16, 0x71, 0xcb, 0xd7, 0x88, 0x9b, 0x57);
	public const Guid GUID_MF_ENUMERATION_INTERFACE = .(0xaeb895f0, 0x5586, 0x11d1, 0x8d, 0x84, 0x00, 0xa0, 0xc9, 0x06, 0xb2, 0x44);
	public const Guid GUID_REENUMERATE_SELF_INTERFACE_STANDARD = .(0x2aeb0243, 0x6a6e, 0x486b, 0x82, 0xfc, 0xd8, 0x15, 0xf6, 0xb9, 0x70, 0x06);
	public const Guid GUID_AGP_TARGET_BUS_INTERFACE_STANDARD = .(0xb15cfce8, 0x06d1, 0x4d37, 0x9d, 0x4c, 0xbe, 0xdd, 0xe0, 0xc2, 0xa6, 0xff);
	public const Guid GUID_ACPI_CMOS_INTERFACE_STANDARD = .(0x3a8d0384, 0x6505, 0x40ca, 0xbc, 0x39, 0x56, 0xc1, 0x5f, 0x8c, 0x5f, 0xed);
	public const Guid GUID_ACPI_PORT_RANGES_INTERFACE_STANDARD = .(0xf14f609b, 0xcbbd, 0x4957, 0xa6, 0x74, 0xbc, 0x00, 0x21, 0x3f, 0x1c, 0x97);
	public const Guid GUID_ACPI_INTERFACE_STANDARD2 = .(0xe8695f63, 0x1831, 0x4870, 0xa8, 0xcf, 0x9c, 0x2f, 0x03, 0xf9, 0xdc, 0xb5);
	public const Guid GUID_PNP_LOCATION_INTERFACE = .(0x70211b0e, 0x0afb, 0x47db, 0xaf, 0xc1, 0x41, 0x0b, 0xf8, 0x42, 0x49, 0x7a);
	public const Guid GUID_PCI_EXPRESS_LINK_QUIESCENT_INTERFACE = .(0x146cd41c, 0xdae3, 0x4437, 0x8a, 0xff, 0x2a, 0xf3, 0xf0, 0x38, 0x09, 0x9b);
	public const Guid GUID_PCI_EXPRESS_ROOT_PORT_INTERFACE = .(0x83a7734a, 0x84c7, 0x4161, 0x9a, 0x98, 0x60, 0x00, 0xed, 0x0c, 0x4a, 0x33);
	public const Guid GUID_MSIX_TABLE_CONFIG_INTERFACE = .(0x1a6a460b, 0x194f, 0x455d, 0xb3, 0x4b, 0xb8, 0x4c, 0x5b, 0x05, 0x71, 0x2b);
	public const Guid GUID_D3COLD_SUPPORT_INTERFACE = .(0xb38290e5, 0x3cd0, 0x4f9d, 0x99, 0x37, 0xf5, 0xfe, 0x2b, 0x44, 0xd4, 0x7a);
	public const Guid GUID_PROCESSOR_PCC_INTERFACE_STANDARD = .(0x37b17e9a, 0xc21c, 0x4296, 0x97, 0x2d, 0x11, 0xc4, 0xb3, 0x2b, 0x28, 0xf0);
	public const Guid GUID_PCI_VIRTUALIZATION_INTERFACE = .(0x64897b47, 0x3a4a, 0x4d75, 0xbc, 0x74, 0x89, 0xdd, 0x6c, 0x07, 0x82, 0x93);
	public const Guid GUID_PCC_INTERFACE_STANDARD = .(0x3ee8ba63, 0x0f59, 0x4a24, 0x8a, 0x45, 0x35, 0x80, 0x8b, 0xdd, 0x12, 0x49);
	public const Guid GUID_PCC_INTERFACE_INTERNAL = .(0x7cce62ce, 0xc189, 0x4814, 0xa6, 0xa7, 0x12, 0x11, 0x20, 0x89, 0xe9, 0x38);
	public const Guid GUID_THERMAL_COOLING_INTERFACE = .(0xecbe47a8, 0xc498, 0x4bb9, 0xbd, 0x70, 0xe8, 0x67, 0xe0, 0x94, 0x0d, 0x22);
	public const Guid GUID_DMA_CACHE_COHERENCY_INTERFACE = .(0xb520f7fa, 0x8a5a, 0x4e40, 0xa3, 0xf6, 0x6b, 0xe1, 0xe1, 0x62, 0xd9, 0x35);
	public const Guid GUID_DEVICE_RESET_INTERFACE_STANDARD = .(0x649fdf26, 0x3bc0, 0x4813, 0xad, 0x24, 0x7e, 0x0c, 0x1e, 0xda, 0x3f, 0xa3);
	public const Guid GUID_IOMMU_BUS_INTERFACE = .(0x1efee0b2, 0xd278, 0x4ae4, 0xbd, 0xdc, 0x1b, 0x34, 0xdd, 0x64, 0x80, 0x43);
	public const Guid GUID_PCI_SECURITY_INTERFACE = .(0x6e7f1451, 0x199e, 0x4acc, 0xba, 0x2d, 0x76, 0x2b, 0x4e, 0xdf, 0x46, 0x74);
	public const Guid GUID_SCM_BUS_INTERFACE = .(0x25944783, 0xce79, 0x4232, 0x81, 0x5e, 0x4a, 0x30, 0x01, 0x4e, 0x8e, 0xb4);
	public const Guid GUID_SECURE_DRIVER_INTERFACE = .(0x370f67e1, 0x4ff5, 0x4a94, 0x9a, 0x35, 0x06, 0xc5, 0xd9, 0xcc, 0x30, 0xe2);
	public const Guid GUID_SDEV_IDENTIFIER_INTERFACE = .(0x49d67af8, 0x916c, 0x4ee8, 0x9d, 0xf1, 0x88, 0x9f, 0x17, 0xd2, 0x1e, 0x91);
	public const Guid GUID_SCM_BUS_NVD_INTERFACE = .(0x8de064ff, 0xb630, 0x42e4, 0x88, 0xea, 0x6f, 0x24, 0xc8, 0x64, 0x11, 0x75);
	public const Guid GUID_SCM_BUS_LD_INTERFACE = .(0x9b89307d, 0xd76b, 0x4f48, 0xb1, 0x86, 0x54, 0x04, 0x1a, 0xe9, 0x2e, 0x8d);
	public const Guid GUID_SCM_PHYSICAL_NVDIMM_INTERFACE = .(0x0079c21b, 0x917e, 0x405e, 0xa9, 0xce, 0x07, 0x32, 0xb5, 0xbb, 0xce, 0xbd);
	public const Guid GUID_PNP_EXTENDED_ADDRESS_INTERFACE = .(0xb8e992ec, 0xa797, 0x4dc4, 0x88, 0x46, 0x84, 0xd0, 0x41, 0x70, 0x74, 0x46);
	public const Guid GUID_D3COLD_AUX_POWER_AND_TIMING_INTERFACE = .(0x0044d8aa, 0xf664, 0x4588, 0x9f, 0xfc, 0x2a, 0xfe, 0xaf, 0x59, 0x50, 0xb9);
	public const Guid GUID_PCI_FPGA_CONTROL_INTERFACE = .(0x2df3f7a8, 0xb9b3, 0x4063, 0x92, 0x15, 0xb5, 0xd1, 0x4a, 0x0b, 0x26, 0x6e);
	public const Guid GUID_PCI_PTM_CONTROL_INTERFACE = .(0x348a5ebb, 0xba24, 0x44b7, 0x99, 0x16, 0x28, 0x56, 0x87, 0x73, 0x51, 0x17);
	public const Guid GUID_BUS_RESOURCE_UPDATE_INTERFACE = .(0x27d0102d, 0xbfb2, 0x4164, 0x81, 0xdd, 0xdb, 0xb8, 0x2f, 0x96, 0x8b, 0x48);
	public const Guid GUID_NPEM_CONTROL_INTERFACE = .(0x4d95573d, 0xb774, 0x488a, 0xb1, 0x20, 0x4f, 0x28, 0x4a, 0x9e, 0xff, 0x51);
	public const Guid GUID_PCI_ATS_INTERFACE = .(0x010a7fe8, 0x96f5, 0x4943, 0xbe, 0xdf, 0x95, 0xe6, 0x51, 0xb9, 0x34, 0x12);
	public const Guid GUID_BUS_TYPE_INTERNAL = .(0x1530ea73, 0x086b, 0x11d1, 0xa0, 0x9f, 0x00, 0xc0, 0x4f, 0xc3, 0x40, 0xb1);
	public const Guid GUID_BUS_TYPE_PCMCIA = .(0x09343630, 0xaf9f, 0x11d0, 0x92, 0xe9, 0x00, 0x00, 0xf8, 0x1e, 0x1b, 0x30);
	public const Guid GUID_BUS_TYPE_PCI = .(0xc8ebdfb0, 0xb510, 0x11d0, 0x80, 0xe5, 0x00, 0xa0, 0xc9, 0x25, 0x42, 0xe3);
	public const Guid GUID_BUS_TYPE_ISAPNP = .(0xe676f854, 0xd87d, 0x11d0, 0x92, 0xb2, 0x00, 0xa0, 0xc9, 0x05, 0x5f, 0xc5);
	public const Guid GUID_BUS_TYPE_EISA = .(0xddc35509, 0xf3fc, 0x11d0, 0xa5, 0x37, 0x00, 0x00, 0xf8, 0x75, 0x3e, 0xd1);
	public const Guid GUID_BUS_TYPE_MCA = .(0x1c75997a, 0xdc33, 0x11d0, 0x92, 0xb2, 0x00, 0xa0, 0xc9, 0x05, 0x5f, 0xc5);
	public const Guid GUID_BUS_TYPE_SERENUM = .(0x77114a87, 0x8944, 0x11d1, 0xbd, 0x90, 0x00, 0xa0, 0xc9, 0x06, 0xbe, 0x2d);
	public const Guid GUID_BUS_TYPE_USB = .(0x9d7debbc, 0xc85d, 0x11d1, 0x9e, 0xb4, 0x00, 0x60, 0x08, 0xc3, 0xa1, 0x9a);
	public const Guid GUID_BUS_TYPE_LPTENUM = .(0xc4ca1000, 0x2ddc, 0x11d5, 0xa1, 0x7a, 0x00, 0xc0, 0x4f, 0x60, 0x52, 0x4d);
	public const Guid GUID_BUS_TYPE_USBPRINT = .(0x441ee000, 0x4342, 0x11d5, 0xa1, 0x84, 0x00, 0xc0, 0x4f, 0x60, 0x52, 0x4d);
	public const Guid GUID_BUS_TYPE_DOT4PRT = .(0x441ee001, 0x4342, 0x11d5, 0xa1, 0x84, 0x00, 0xc0, 0x4f, 0x60, 0x52, 0x4d);
	public const Guid GUID_BUS_TYPE_1394 = .(0xf74e73eb, 0x9ac5, 0x45eb, 0xbe, 0x4d, 0x77, 0x2c, 0xc7, 0x1d, 0xdf, 0xb3);
	public const Guid GUID_BUS_TYPE_HID = .(0xeeaf37d0, 0x1963, 0x47c4, 0xaa, 0x48, 0x72, 0x47, 0x6d, 0xb7, 0xcf, 0x49);
	public const Guid GUID_BUS_TYPE_AVC = .(0xc06ff265, 0xae09, 0x48f0, 0x81, 0x2c, 0x16, 0x75, 0x3d, 0x7c, 0xba, 0x83);
	public const Guid GUID_BUS_TYPE_IRDA = .(0x7ae17dc1, 0xc944, 0x44d6, 0x88, 0x1f, 0x4c, 0x2e, 0x61, 0x05, 0x3b, 0xc1);
	public const Guid GUID_BUS_TYPE_SD = .(0xe700cc04, 0x4036, 0x4e89, 0x95, 0x79, 0x89, 0xeb, 0xf4, 0x5f, 0x00, 0xcd);
	public const Guid GUID_BUS_TYPE_ACPI = .(0xd7b46895, 0x001a, 0x4942, 0x89, 0x1f, 0xa7, 0xd4, 0x66, 0x10, 0xa8, 0x43);
	public const Guid GUID_BUS_TYPE_SW_DEVICE = .(0x06d10322, 0x7de0, 0x4cef, 0x8e, 0x25, 0x19, 0x7d, 0x0e, 0x74, 0x42, 0xe2);
	public const Guid GUID_BUS_TYPE_SCM = .(0x375a5912, 0x804c, 0x45aa, 0xbd, 0xc2, 0xfd, 0xd2, 0x5a, 0x1d, 0x95, 0x12);
	public const Guid GUID_POWER_DEVICE_ENABLE = .(0x827c0a6f, 0xfeb0, 0x11d0, 0xbd, 0x26, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_POWER_DEVICE_TIMEOUTS = .(0xa45da735, 0xfeb0, 0x11d0, 0xbd, 0x26, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_POWER_DEVICE_WAKE_ENABLE = .(0xa9546a82, 0xfeb0, 0x11d0, 0xbd, 0x26, 0x00, 0xaa, 0x00, 0xb7, 0xb3, 0x2a);
	public const Guid GUID_WUDF_DEVICE_HOST_PROBLEM = .(0xc43d25bd, 0x9346, 0x40ee, 0xa2, 0xd2, 0xd7, 0x0c, 0x15, 0xf8, 0xb7, 0x5b);
	public const Guid GUID_PARTITION_UNIT_INTERFACE_STANDARD = .(0x52363f5b, 0xd891, 0x429b, 0x81, 0x95, 0xae, 0xc5, 0xfe, 0xf6, 0x85, 0x3c);
	public const Guid GUID_QUERY_CRASHDUMP_FUNCTIONS = .(0x9cc6b8ff, 0x32e2, 0x4834, 0xb1, 0xde, 0xb3, 0x2e, 0xf8, 0x88, 0x0a, 0x4b);
}
#endregion

#region TypeDefs
typealias HCMNOTIFICATION = int;

typealias HDEVINFO = int;

#endregion


#region Enums

[AllowDuplicates]
public enum SP_COPY_STYLE : uint32
{
	SP_COPY_DELETESOURCE = 1,
	SP_COPY_REPLACEONLY = 2,
	SP_COPY_NEWER_OR_SAME = 4,
	SP_COPY_NEWER_ONLY = 65536,
	SP_COPY_NOOVERWRITE = 8,
	SP_COPY_NODECOMP = 16,
	SP_COPY_LANGUAGEAWARE = 32,
	SP_COPY_SOURCE_ABSOLUTE = 64,
	SP_COPY_SOURCEPATH_ABSOLUTE = 128,
	SP_COPY_FORCE_IN_USE = 512,
	SP_COPY_IN_USE_NEEDS_REBOOT = 256,
	SP_COPY_NOSKIP = 1024,
	SP_COPY_FORCE_NOOVERWRITE = 4096,
	SP_COPY_FORCE_NEWER = 8192,
	SP_COPY_WARNIFSKIP = 16384,
	SP_COPY_NOBROWSE = 32768,
	SP_COPY_NEWER = 4,
	SP_COPY_RESERVED = 131072,
	SP_COPY_OEMINF_CATALOG_ONLY = 262144,
	SP_COPY_REPLACE_BOOT_FILE = 524288,
	SP_COPY_NOPRUNE = 1048576,
	SP_COPY_OEM_F6_INF = 2097152,
	SP_COPY_ALREADYDECOMP = 4194304,
	SP_COPY_WINDOWS_SIGNED = 16777216,
	SP_COPY_PNPLOCKED = 33554432,
	SP_COPY_IN_USE_TRY_RENAME = 67108864,
	SP_COPY_INBOX_INF = 134217728,
	SP_COPY_HARDLINK = 268435456,
}


[AllowDuplicates]
public enum SETUP_FILE_OPERATION : uint32
{
	FILEOP_DELETE = 2,
	FILEOP_COPY = 0,
}


[AllowDuplicates]
public enum OEM_SOURCE_MEDIA_TYPE : uint32
{
	SPOST_NONE = 0,
	SPOST_PATH = 1,
	SPOST_URL = 2,
}


[AllowDuplicates]
public enum SETUP_DI_BUILD_DRIVER_DRIVER_TYPE : uint32
{
	SPDIT_CLASSDRIVER = 1,
	SPDIT_COMPATDRIVER = 2,
}


[AllowDuplicates]
public enum SP_INF_STYLE : uint32
{
	INF_STYLE_NONE = 0,
	INF_STYLE_OLDNT = 1,
	INF_STYLE_WIN4 = 2,
}


[AllowDuplicates]
public enum CONFIGRET : uint32
{
	CR_SUCCESS = 0,
	CR_DEFAULT = 1,
	CR_OUT_OF_MEMORY = 2,
	CR_INVALID_POINTER = 3,
	CR_INVALID_FLAG = 4,
	CR_INVALID_DEVNODE = 5,
	CR_INVALID_DEVINST = 5,
	CR_INVALID_RES_DES = 6,
	CR_INVALID_LOG_CONF = 7,
	CR_INVALID_ARBITRATOR = 8,
	CR_INVALID_NODELIST = 9,
	CR_DEVNODE_HAS_REQS = 10,
	CR_DEVINST_HAS_REQS = 10,
	CR_INVALID_RESOURCEID = 11,
	CR_DLVXD_NOT_FOUND = 12,
	CR_NO_SUCH_DEVNODE = 13,
	CR_NO_SUCH_DEVINST = 13,
	CR_NO_MORE_LOG_CONF = 14,
	CR_NO_MORE_RES_DES = 15,
	CR_ALREADY_SUCH_DEVNODE = 16,
	CR_ALREADY_SUCH_DEVINST = 16,
	CR_INVALID_RANGE_LIST = 17,
	CR_INVALID_RANGE = 18,
	CR_FAILURE = 19,
	CR_NO_SUCH_LOGICAL_DEV = 20,
	CR_CREATE_BLOCKED = 21,
	CR_NOT_SYSTEM_VM = 22,
	CR_REMOVE_VETOED = 23,
	CR_APM_VETOED = 24,
	CR_INVALID_LOAD_TYPE = 25,
	CR_BUFFER_SMALL = 26,
	CR_NO_ARBITRATOR = 27,
	CR_NO_REGISTRY_HANDLE = 28,
	CR_REGISTRY_ERROR = 29,
	CR_INVALID_DEVICE_ID = 30,
	CR_INVALID_DATA = 31,
	CR_INVALID_API = 32,
	CR_DEVLOADER_NOT_READY = 33,
	CR_NEED_RESTART = 34,
	CR_NO_MORE_HW_PROFILES = 35,
	CR_DEVICE_NOT_THERE = 36,
	CR_NO_SUCH_VALUE = 37,
	CR_WRONG_TYPE = 38,
	CR_INVALID_PRIORITY = 39,
	CR_NOT_DISABLEABLE = 40,
	CR_FREE_RESOURCES = 41,
	CR_QUERY_VETOED = 42,
	CR_CANT_SHARE_IRQ = 43,
	CR_NO_DEPENDENT = 44,
	CR_SAME_RESOURCES = 45,
	CR_NO_SUCH_REGISTRY_KEY = 46,
	CR_INVALID_MACHINENAME = 47,
	CR_REMOTE_COMM_FAILURE = 48,
	CR_MACHINE_UNAVAILABLE = 49,
	CR_NO_CM_SERVICES = 50,
	CR_ACCESS_DENIED = 51,
	CR_CALL_NOT_IMPLEMENTED = 52,
	CR_INVALID_PROPERTY = 53,
	CR_DEVICE_INTERFACE_ACTIVE = 54,
	CR_NO_SUCH_DEVICE_INTERFACE = 55,
	CR_INVALID_REFERENCE_STRING = 56,
	CR_INVALID_CONFLICT_LIST = 57,
	CR_INVALID_INDEX = 58,
	CR_INVALID_STRUCTURE_SIZE = 59,
	NUM_CR_RESULTS = 60,
}


[AllowDuplicates]
public enum SetupFileLogInfo : int32
{
	SetupFileLogSourceFilename = 0,
	SetupFileLogChecksum = 1,
	SetupFileLogDiskTagfile = 2,
	SetupFileLogDiskDescription = 3,
	SetupFileLogOtherInfo = 4,
	SetupFileLogMax = 5,
}


[AllowDuplicates]
public enum PNP_VETO_TYPE : int32
{
	PNP_VetoTypeUnknown = 0,
	PNP_VetoLegacyDevice = 1,
	PNP_VetoPendingClose = 2,
	PNP_VetoWindowsApp = 3,
	PNP_VetoWindowsService = 4,
	PNP_VetoOutstandingOpen = 5,
	PNP_VetoDevice = 6,
	PNP_VetoDriver = 7,
	PNP_VetoIllegalDeviceRequest = 8,
	PNP_VetoInsufficientPower = 9,
	PNP_VetoNonDisableable = 10,
	PNP_VetoLegacyDriver = 11,
	PNP_VetoInsufficientRights = 12,
	PNP_VetoAlreadyRemoved = 13,
}


[AllowDuplicates]
public enum CM_NOTIFY_FILTER_TYPE : int32
{
	CM_NOTIFY_FILTER_TYPE_DEVICEINTERFACE = 0,
	CM_NOTIFY_FILTER_TYPE_DEVICEHANDLE = 1,
	CM_NOTIFY_FILTER_TYPE_DEVICEINSTANCE = 2,
	CM_NOTIFY_FILTER_TYPE_MAX = 3,
}


[AllowDuplicates]
public enum CM_NOTIFY_ACTION : int32
{
	CM_NOTIFY_ACTION_DEVICEINTERFACEARRIVAL = 0,
	CM_NOTIFY_ACTION_DEVICEINTERFACEREMOVAL = 1,
	CM_NOTIFY_ACTION_DEVICEQUERYREMOVE = 2,
	CM_NOTIFY_ACTION_DEVICEQUERYREMOVEFAILED = 3,
	CM_NOTIFY_ACTION_DEVICEREMOVEPENDING = 4,
	CM_NOTIFY_ACTION_DEVICEREMOVECOMPLETE = 5,
	CM_NOTIFY_ACTION_DEVICECUSTOMEVENT = 6,
	CM_NOTIFY_ACTION_DEVICEINSTANCEENUMERATED = 7,
	CM_NOTIFY_ACTION_DEVICEINSTANCESTARTED = 8,
	CM_NOTIFY_ACTION_DEVICEINSTANCEREMOVED = 9,
	CM_NOTIFY_ACTION_MAX = 10,
}

#endregion

#region Function Pointers
public function uint32 PSP_FILE_CALLBACK_A(void* Context, uint32 Notification, uint Param1, uint Param2);

public function uint32 PSP_FILE_CALLBACK_W(void* Context, uint32 Notification, uint Param1, uint Param2);

public function BOOL PDETECT_PROGRESS_NOTIFY(void* ProgressNotifyParam, uint32 DetectComplete);

public function uint32 PSP_DETSIG_CMPPROC(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* NewDeviceData, SP_DEVINFO_DATA* ExistingDeviceData, void* CompareContext);

public function uint32 PCM_NOTIFY_CALLBACK(HCMNOTIFICATION hNotify, void* Context, CM_NOTIFY_ACTION Action, CM_NOTIFY_EVENT_DATA* EventData, uint32 EventDataSize);

#endregion

#region Structs
#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct INFCONTEXT
{
	public void* Inf;
	public void* CurrentInf;
	public uint32 Section;
	public uint32 Line;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INF_INFORMATION
{
	public SP_INF_STYLE InfStyle;
	public uint32 InfCount;
	public uint8* VersionData mut => &VersionData_impl;
	private uint8[ANYSIZE_ARRAY] VersionData_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ALTPLATFORM_INFO_V3
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 Reserved;
		public uint16 Flags;
	}
	public uint32 cbSize;
	public uint32 Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public using _Anonymous_e__Union Anonymous;
	public uint32 FirstValidatedMajorVersion;
	public uint32 FirstValidatedMinorVersion;
	public uint8 ProductType;
	public uint16 SuiteMask;
	public uint32 BuildNumber;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ALTPLATFORM_INFO_V2
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint16 Reserved;
		public uint16 Flags;
	}
	public uint32 cbSize;
	public VER_PLATFORM Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public using _Anonymous_e__Union Anonymous;
	public uint32 FirstValidatedMajorVersion;
	public uint32 FirstValidatedMinorVersion;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ALTPLATFORM_INFO_V1
{
	public uint32 cbSize;
	public VER_PLATFORM Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public uint16 Reserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ORIGINAL_FILE_INFO_A
{
	public uint32 cbSize;
	public CHAR[260] OriginalInfName;
	public CHAR[260] OriginalCatalogName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ORIGINAL_FILE_INFO_W
{
	public uint32 cbSize;
	public char16[260] OriginalInfName;
	public char16[260] OriginalCatalogName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILEPATHS_A
{
	public PSTR Target;
	public PSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILEPATHS_W
{
	public PWSTR Target;
	public PWSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILEPATHS_SIGNERINFO_A
{
	public PSTR Target;
	public PSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
	public PSTR DigitalSigner;
	public PSTR Version;
	public PSTR CatalogFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILEPATHS_SIGNERINFO_W
{
	public PWSTR Target;
	public PWSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
	public PWSTR DigitalSigner;
	public PWSTR Version;
	public PWSTR CatalogFile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SOURCE_MEDIA_A
{
	public PSTR Reserved;
	public PSTR Tagfile;
	public PSTR Description;
	public PSTR SourcePath;
	public PSTR SourceFile;
	public uint32 Flags;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SOURCE_MEDIA_W
{
	public PWSTR Reserved;
	public PWSTR Tagfile;
	public PWSTR Description;
	public PWSTR SourcePath;
	public PWSTR SourceFile;
	public uint32 Flags;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CABINET_INFO_A
{
	public PSTR CabinetPath;
	public PSTR CabinetFile;
	public PSTR DiskName;
	public uint16 SetId;
	public uint16 CabinetNumber;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct CABINET_INFO_W
{
	public PWSTR CabinetPath;
	public PWSTR CabinetFile;
	public PWSTR DiskName;
	public uint16 SetId;
	public uint16 CabinetNumber;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILE_IN_CABINET_INFO_A
{
	public PSTR NameInCabinet;
	public uint32 FileSize;
	public uint32 Win32Error;
	public uint16 DosDate;
	public uint16 DosTime;
	public uint16 DosAttribs;
	public CHAR[260] FullTargetName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct FILE_IN_CABINET_INFO_W
{
	public PWSTR NameInCabinet;
	public uint32 FileSize;
	public uint32 Win32Error;
	public uint16 DosDate;
	public uint16 DosTime;
	public uint16 DosAttribs;
	public char16[260] FullTargetName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_REGISTER_CONTROL_STATUSA
{
	public uint32 cbSize;
	public PSTR FileName;
	public uint32 Win32Error;
	public uint32 FailureCode;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_REGISTER_CONTROL_STATUSW
{
	public uint32 cbSize;
	public PWSTR FileName;
	public uint32 Win32Error;
	public uint32 FailureCode;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_FILE_COPY_PARAMS_A
{
	public uint32 cbSize;
	public void* QueueHandle;
	public PSTR SourceRootPath;
	public PSTR SourcePath;
	public PSTR SourceFilename;
	public PSTR SourceDescription;
	public PSTR SourceTagfile;
	public PSTR TargetDirectory;
	public PSTR TargetFilename;
	public uint32 CopyStyle;
	public void* LayoutInf;
	public PSTR SecurityDescriptor;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_FILE_COPY_PARAMS_W
{
	public uint32 cbSize;
	public void* QueueHandle;
	public PWSTR SourceRootPath;
	public PWSTR SourcePath;
	public PWSTR SourceFilename;
	public PWSTR SourceDescription;
	public PWSTR SourceTagfile;
	public PWSTR TargetDirectory;
	public PWSTR TargetFilename;
	public uint32 CopyStyle;
	public void* LayoutInf;
	public PWSTR SecurityDescriptor;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVINFO_DATA
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public uint32 DevInst;
	public uint Reserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVICE_INTERFACE_DATA
{
	public uint32 cbSize;
	public Guid InterfaceClassGuid;
	public uint32 Flags;
	public uint Reserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVICE_INTERFACE_DETAIL_DATA_A
{
	public uint32 cbSize;
	public CHAR* DevicePath mut => &DevicePath_impl;
	private CHAR[ANYSIZE_ARRAY] DevicePath_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVICE_INTERFACE_DETAIL_DATA_W
{
	public uint32 cbSize;
	public char16* DevicePath mut => &DevicePath_impl;
	private char16[ANYSIZE_ARRAY] DevicePath_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVINFO_LIST_DETAIL_DATA_A
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public HANDLE RemoteMachineHandle;
	public CHAR[263] RemoteMachineName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVINFO_LIST_DETAIL_DATA_W
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public HANDLE RemoteMachineHandle;
	public char16[263] RemoteMachineName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVINSTALL_PARAMS_A
{
	public uint32 cbSize;
	public uint32 Flags;
	public uint32 FlagsEx;
	public HWND hwndParent;
	public PSP_FILE_CALLBACK_A InstallMsgHandler;
	public void* InstallMsgHandlerContext;
	public void* FileQueue;
	public uint ClassInstallReserved;
	public uint32 Reserved;
	public CHAR[260] DriverPath;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DEVINSTALL_PARAMS_W
{
	public uint32 cbSize;
	public uint32 Flags;
	public uint32 FlagsEx;
	public HWND hwndParent;
	public PSP_FILE_CALLBACK_A InstallMsgHandler;
	public void* InstallMsgHandlerContext;
	public void* FileQueue;
	public uint ClassInstallReserved;
	public uint32 Reserved;
	public char16[260] DriverPath;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_CLASSINSTALL_HEADER
{
	public uint32 cbSize;
	public uint32 InstallFunction;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_ENABLECLASS_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public Guid ClassGuid;
	public uint32 EnableMessage;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_PROPCHANGE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 StateChange;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_REMOVEDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_UNREMOVEDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_SELECTDEVICE_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[60] Title;
	public char16[256] Instructions;
	public char16[30] ListLabel;
	public char16[256] SubTitle;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DETECTDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public PDETECT_PROGRESS_NOTIFY DetectProgressNotify;
	public void* ProgressNotifyParam;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INSTALLWIZARD_DATA
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Flags;
	public HPROPSHEETPAGE[20] DynamicPages;
	public uint32 NumDynamicPages;
	public uint32 DynamicPageFlags;
	public uint32 PrivateFlags;
	public LPARAM PrivateData;
	public HWND hwndWizardDlg;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_NEWDEVICEWIZARD_DATA
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Flags;
	public HPROPSHEETPAGE[20] DynamicPages;
	public uint32 NumDynamicPages;
	public HWND hwndWizardDlg;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_TROUBLESHOOTER_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[260] ChmFile;
	public char16[260] HtmlTroubleShooter;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_POWERMESSAGEWAKE_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[512] PowerMessageWake;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DATA_V2_A
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public CHAR[256] Description;
	public CHAR[256] MfgName;
	public CHAR[256] ProviderName;
	public FILETIME DriverDate;
	public uint64 DriverVersion;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DATA_V2_W
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public char16[256] Description;
	public char16[256] MfgName;
	public char16[256] ProviderName;
	public FILETIME DriverDate;
	public uint64 DriverVersion;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DATA_V1_A
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public CHAR[256] Description;
	public CHAR[256] MfgName;
	public CHAR[256] ProviderName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DATA_V1_W
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public char16[256] Description;
	public char16[256] MfgName;
	public char16[256] ProviderName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DETAIL_DATA_A
{
	public uint32 cbSize;
	public FILETIME InfDate;
	public uint32 CompatIDsOffset;
	public uint32 CompatIDsLength;
	public uint Reserved;
	public CHAR[256] SectionName;
	public CHAR[260] InfFileName;
	public CHAR[256] DrvDescription;
	public CHAR* HardwareID mut => &HardwareID_impl;
	private CHAR[ANYSIZE_ARRAY] HardwareID_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINFO_DETAIL_DATA_W
{
	public uint32 cbSize;
	public FILETIME InfDate;
	public uint32 CompatIDsOffset;
	public uint32 CompatIDsLength;
	public uint Reserved;
	public char16[256] SectionName;
	public char16[260] InfFileName;
	public char16[256] DrvDescription;
	public char16* HardwareID mut => &HardwareID_impl;
	private char16[ANYSIZE_ARRAY] HardwareID_impl;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_DRVINSTALL_PARAMS
{
	public uint32 cbSize;
	public uint32 Rank;
	public uint32 Flags;
	public uint PrivateData;
	public uint32 Reserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct COINSTALLER_CONTEXT_DATA
{
	public BOOL PostProcessing;
	public uint32 InstallResult;
	public void* PrivateData;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_CLASSIMAGELIST_DATA
{
	public uint32 cbSize;
	public HIMAGELIST ImageList;
	public uint Reserved;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_PROPSHEETPAGE_REQUEST
{
	public uint32 cbSize;
	public uint32 PageRequested;
	public HDEVINFO DeviceInfoSet;
	public SP_DEVINFO_DATA* DeviceInfoData;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_BACKUP_QUEUE_PARAMS_V2_A
{
	public uint32 cbSize;
	public CHAR[260] FullInfPath;
	public int32 FilenameOffset;
	public CHAR[260] ReinstallInstance;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_BACKUP_QUEUE_PARAMS_V2_W
{
	public uint32 cbSize;
	public char16[260] FullInfPath;
	public int32 FilenameOffset;
	public char16[260] ReinstallInstance;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_BACKUP_QUEUE_PARAMS_V1_A
{
	public uint32 cbSize;
	public CHAR[260] FullInfPath;
	public int32 FilenameOffset;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_BACKUP_QUEUE_PARAMS_V1_W
{
	public uint32 cbSize;
	public char16[260] FullInfPath;
	public int32 FilenameOffset;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INF_SIGNER_INFO_V1_A
{
	public uint32 cbSize;
	public CHAR[260] CatalogFile;
	public CHAR[260] DigitalSigner;
	public CHAR[260] DigitalSignerVersion;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INF_SIGNER_INFO_V1_W
{
	public uint32 cbSize;
	public char16[260] CatalogFile;
	public char16[260] DigitalSigner;
	public char16[260] DigitalSignerVersion;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INF_SIGNER_INFO_V2_A
{
	public uint32 cbSize;
	public CHAR[260] CatalogFile;
	public CHAR[260] DigitalSigner;
	public CHAR[260] DigitalSignerVersion;
	public uint32 SignerScore;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SP_INF_SIGNER_INFO_V2_W
{
	public uint32 cbSize;
	public char16[260] CatalogFile;
	public char16[260] DigitalSigner;
	public char16[260] DigitalSignerVersion;
	public uint32 SignerScore;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct INFCONTEXT
{
	public void* Inf;
	public void* CurrentInf;
	public uint32 Section;
	public uint32 Line;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INF_INFORMATION
{
	public SP_INF_STYLE InfStyle;
	public uint32 InfCount;
	public uint8* VersionData mut => &VersionData_impl;
	private uint8[ANYSIZE_ARRAY] VersionData_impl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ALTPLATFORM_INFO_V3
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint16 Reserved;
		public uint16 Flags;
	}
	public uint32 cbSize;
	public uint32 Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public using _Anonymous_e__Union Anonymous;
	public uint32 FirstValidatedMajorVersion;
	public uint32 FirstValidatedMinorVersion;
	public uint8 ProductType;
	public uint16 SuiteMask;
	public uint32 BuildNumber;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ALTPLATFORM_INFO_V2
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint16 Reserved;
		public uint16 Flags;
	}
	public uint32 cbSize;
	public VER_PLATFORM Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public using _Anonymous_e__Union Anonymous;
	public uint32 FirstValidatedMajorVersion;
	public uint32 FirstValidatedMinorVersion;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ALTPLATFORM_INFO_V1
{
	public uint32 cbSize;
	public VER_PLATFORM Platform;
	public uint32 MajorVersion;
	public uint32 MinorVersion;
	public uint16 ProcessorArchitecture;
	public uint16 Reserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ORIGINAL_FILE_INFO_A
{
	public uint32 cbSize;
	public CHAR[260] OriginalInfName;
	public CHAR[260] OriginalCatalogName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ORIGINAL_FILE_INFO_W
{
	public uint32 cbSize;
	public char16[260] OriginalInfName;
	public char16[260] OriginalCatalogName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILEPATHS_A
{
	public PSTR Target;
	public PSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILEPATHS_W
{
	public PWSTR Target;
	public PWSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILEPATHS_SIGNERINFO_A
{
	public PSTR Target;
	public PSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
	public PSTR DigitalSigner;
	public PSTR Version;
	public PSTR CatalogFile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILEPATHS_SIGNERINFO_W
{
	public PWSTR Target;
	public PWSTR Source;
	public uint32 Win32Error;
	public uint32 Flags;
	public PWSTR DigitalSigner;
	public PWSTR Version;
	public PWSTR CatalogFile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SOURCE_MEDIA_A
{
	public PSTR Reserved;
	public PSTR Tagfile;
	public PSTR Description;
	public PSTR SourcePath;
	public PSTR SourceFile;
	public uint32 Flags;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SOURCE_MEDIA_W
{
	public PWSTR Reserved;
	public PWSTR Tagfile;
	public PWSTR Description;
	public PWSTR SourcePath;
	public PWSTR SourceFile;
	public uint32 Flags;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CABINET_INFO_A
{
	public PSTR CabinetPath;
	public PSTR CabinetFile;
	public PSTR DiskName;
	public uint16 SetId;
	public uint16 CabinetNumber;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct CABINET_INFO_W
{
	public PWSTR CabinetPath;
	public PWSTR CabinetFile;
	public PWSTR DiskName;
	public uint16 SetId;
	public uint16 CabinetNumber;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILE_IN_CABINET_INFO_A
{
	public PSTR NameInCabinet;
	public uint32 FileSize;
	public uint32 Win32Error;
	public uint16 DosDate;
	public uint16 DosTime;
	public uint16 DosAttribs;
	public CHAR[260] FullTargetName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct FILE_IN_CABINET_INFO_W
{
	public PWSTR NameInCabinet;
	public uint32 FileSize;
	public uint32 Win32Error;
	public uint16 DosDate;
	public uint16 DosTime;
	public uint16 DosAttribs;
	public char16[260] FullTargetName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_REGISTER_CONTROL_STATUSA
{
	public uint32 cbSize;
	public PSTR FileName;
	public uint32 Win32Error;
	public uint32 FailureCode;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_REGISTER_CONTROL_STATUSW
{
	public uint32 cbSize;
	public PWSTR FileName;
	public uint32 Win32Error;
	public uint32 FailureCode;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_FILE_COPY_PARAMS_A
{
	public uint32 cbSize;
	public void* QueueHandle;
	public PSTR SourceRootPath;
	public PSTR SourcePath;
	public PSTR SourceFilename;
	public PSTR SourceDescription;
	public PSTR SourceTagfile;
	public PSTR TargetDirectory;
	public PSTR TargetFilename;
	public uint32 CopyStyle;
	public void* LayoutInf;
	public PSTR SecurityDescriptor;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_FILE_COPY_PARAMS_W
{
	public uint32 cbSize;
	public void* QueueHandle;
	public PWSTR SourceRootPath;
	public PWSTR SourcePath;
	public PWSTR SourceFilename;
	public PWSTR SourceDescription;
	public PWSTR SourceTagfile;
	public PWSTR TargetDirectory;
	public PWSTR TargetFilename;
	public uint32 CopyStyle;
	public void* LayoutInf;
	public PWSTR SecurityDescriptor;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVINFO_DATA
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public uint32 DevInst;
	public uint Reserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVICE_INTERFACE_DATA
{
	public uint32 cbSize;
	public Guid InterfaceClassGuid;
	public uint32 Flags;
	public uint Reserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVICE_INTERFACE_DETAIL_DATA_A
{
	public uint32 cbSize;
	public CHAR* DevicePath mut => &DevicePath_impl;
	private CHAR[ANYSIZE_ARRAY] DevicePath_impl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVICE_INTERFACE_DETAIL_DATA_W
{
	public uint32 cbSize;
	public char16* DevicePath mut => &DevicePath_impl;
	private char16[ANYSIZE_ARRAY] DevicePath_impl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVINFO_LIST_DETAIL_DATA_A
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public HANDLE RemoteMachineHandle;
	public CHAR[263] RemoteMachineName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVINFO_LIST_DETAIL_DATA_W
{
	public uint32 cbSize;
	public Guid ClassGuid;
	public HANDLE RemoteMachineHandle;
	public char16[263] RemoteMachineName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVINSTALL_PARAMS_A
{
	public uint32 cbSize;
	public uint32 Flags;
	public uint32 FlagsEx;
	public HWND hwndParent;
	public PSP_FILE_CALLBACK_A InstallMsgHandler;
	public void* InstallMsgHandlerContext;
	public void* FileQueue;
	public uint ClassInstallReserved;
	public uint32 Reserved;
	public CHAR[260] DriverPath;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DEVINSTALL_PARAMS_W
{
	public uint32 cbSize;
	public uint32 Flags;
	public uint32 FlagsEx;
	public HWND hwndParent;
	public PSP_FILE_CALLBACK_A InstallMsgHandler;
	public void* InstallMsgHandlerContext;
	public void* FileQueue;
	public uint ClassInstallReserved;
	public uint32 Reserved;
	public char16[260] DriverPath;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_CLASSINSTALL_HEADER
{
	public uint32 cbSize;
	public uint32 InstallFunction;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_ENABLECLASS_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public Guid ClassGuid;
	public uint32 EnableMessage;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_PROPCHANGE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 StateChange;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_REMOVEDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_UNREMOVEDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Scope;
	public uint32 HwProfile;
}
#endif

[CRepr]
public struct SP_SELECTDEVICE_PARAMS_A
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public CHAR[60] Title;
	public CHAR[256] Instructions;
	public CHAR[30] ListLabel;
	public CHAR[256] SubTitle;
	public uint8[2] Reserved;
}

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_SELECTDEVICE_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[60] Title;
	public char16[256] Instructions;
	public char16[30] ListLabel;
	public char16[256] SubTitle;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DETECTDEVICE_PARAMS
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public PDETECT_PROGRESS_NOTIFY DetectProgressNotify;
	public void* ProgressNotifyParam;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INSTALLWIZARD_DATA
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Flags;
	public HPROPSHEETPAGE[20] DynamicPages;
	public uint32 NumDynamicPages;
	public uint32 DynamicPageFlags;
	public uint32 PrivateFlags;
	public LPARAM PrivateData;
	public HWND hwndWizardDlg;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_NEWDEVICEWIZARD_DATA
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public uint32 Flags;
	public HPROPSHEETPAGE[20] DynamicPages;
	public uint32 NumDynamicPages;
	public HWND hwndWizardDlg;
}
#endif

[CRepr]
public struct SP_TROUBLESHOOTER_PARAMS_A
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public CHAR[260] ChmFile;
	public CHAR[260] HtmlTroubleShooter;
}

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_TROUBLESHOOTER_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[260] ChmFile;
	public char16[260] HtmlTroubleShooter;
}
#endif

[CRepr]
public struct SP_POWERMESSAGEWAKE_PARAMS_A
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public CHAR[512] PowerMessageWake;
}

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_POWERMESSAGEWAKE_PARAMS_W
{
	public SP_CLASSINSTALL_HEADER ClassInstallHeader;
	public char16[512] PowerMessageWake;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DATA_V2_A
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public CHAR[256] Description;
	public CHAR[256] MfgName;
	public CHAR[256] ProviderName;
	public FILETIME DriverDate;
	public uint64 DriverVersion;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DATA_V2_W
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public char16[256] Description;
	public char16[256] MfgName;
	public char16[256] ProviderName;
	public FILETIME DriverDate;
	public uint64 DriverVersion;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DATA_V1_A
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public CHAR[256] Description;
	public CHAR[256] MfgName;
	public CHAR[256] ProviderName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DATA_V1_W
{
	public uint32 cbSize;
	public uint32 DriverType;
	public uint Reserved;
	public char16[256] Description;
	public char16[256] MfgName;
	public char16[256] ProviderName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DETAIL_DATA_A
{
	public uint32 cbSize;
	public FILETIME InfDate;
	public uint32 CompatIDsOffset;
	public uint32 CompatIDsLength;
	public uint Reserved;
	public CHAR[256] SectionName;
	public CHAR[260] InfFileName;
	public CHAR[256] DrvDescription;
	public CHAR* HardwareID mut => &HardwareID_impl;
	private CHAR[ANYSIZE_ARRAY] HardwareID_impl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINFO_DETAIL_DATA_W
{
	public uint32 cbSize;
	public FILETIME InfDate;
	public uint32 CompatIDsOffset;
	public uint32 CompatIDsLength;
	public uint Reserved;
	public char16[256] SectionName;
	public char16[260] InfFileName;
	public char16[256] DrvDescription;
	public char16* HardwareID mut => &HardwareID_impl;
	private char16[ANYSIZE_ARRAY] HardwareID_impl;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_DRVINSTALL_PARAMS
{
	public uint32 cbSize;
	public uint32 Rank;
	public uint32 Flags;
	public uint PrivateData;
	public uint32 Reserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct COINSTALLER_CONTEXT_DATA
{
	public BOOL PostProcessing;
	public uint32 InstallResult;
	public void* PrivateData;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_CLASSIMAGELIST_DATA
{
	public uint32 cbSize;
	public HIMAGELIST ImageList;
	public uint Reserved;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_PROPSHEETPAGE_REQUEST
{
	public uint32 cbSize;
	public uint32 PageRequested;
	public HDEVINFO DeviceInfoSet;
	public SP_DEVINFO_DATA* DeviceInfoData;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_BACKUP_QUEUE_PARAMS_V2_A
{
	public uint32 cbSize;
	public CHAR[260] FullInfPath;
	public int32 FilenameOffset;
	public CHAR[260] ReinstallInstance;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_BACKUP_QUEUE_PARAMS_V2_W
{
	public uint32 cbSize;
	public char16[260] FullInfPath;
	public int32 FilenameOffset;
	public char16[260] ReinstallInstance;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_BACKUP_QUEUE_PARAMS_V1_A
{
	public uint32 cbSize;
	public CHAR[260] FullInfPath;
	public int32 FilenameOffset;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_BACKUP_QUEUE_PARAMS_V1_W
{
	public uint32 cbSize;
	public char16[260] FullInfPath;
	public int32 FilenameOffset;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INF_SIGNER_INFO_V1_A
{
	public uint32 cbSize;
	public CHAR[260] CatalogFile;
	public CHAR[260] DigitalSigner;
	public CHAR[260] DigitalSignerVersion;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INF_SIGNER_INFO_V1_W
{
	public uint32 cbSize;
	public char16[260] CatalogFile;
	public char16[260] DigitalSigner;
	public char16[260] DigitalSignerVersion;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INF_SIGNER_INFO_V2_A
{
	public uint32 cbSize;
	public CHAR[260] CatalogFile;
	public CHAR[260] DigitalSigner;
	public CHAR[260] DigitalSignerVersion;
	public uint32 SignerScore;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SP_INF_SIGNER_INFO_V2_W
{
	public uint32 cbSize;
	public char16[260] CatalogFile;
	public char16[260] DigitalSigner;
	public char16[260] DigitalSignerVersion;
	public uint32 SignerScore;
}
#endif

[CRepr]
public struct CONFLICT_DETAILS_A
{
	public uint32 CD_ulSize;
	public uint32 CD_ulMask;
	public uint32 CD_dnDevInst;
	public uint CD_rdResDes;
	public uint32 CD_ulFlags;
	public CHAR[260] CD_szDescription;
}

[CRepr]
public struct CONFLICT_DETAILS_W
{
	public uint32 CD_ulSize;
	public uint32 CD_ulMask;
	public uint32 CD_dnDevInst;
	public uint CD_rdResDes;
	public uint32 CD_ulFlags;
	public char16[260] CD_szDescription;
}

[CRepr, Packed(1)]
public struct MEM_RANGE
{
	public uint64 MR_Align;
	public uint32 MR_nBytes;
	public uint64 MR_Min;
	public uint64 MR_Max;
	public uint32 MR_Flags;
	public uint32 MR_Reserved;
}

[CRepr, Packed(1)]
public struct MEM_DES
{
	public uint32 MD_Count;
	public uint32 MD_Type;
	public uint64 MD_Alloc_Base;
	public uint64 MD_Alloc_End;
	public uint32 MD_Flags;
	public uint32 MD_Reserved;
}

[CRepr, Packed(1)]
public struct MEM_RESOURCE
{
	public MEM_DES MEM_Header;
	public MEM_RANGE* MEM_Data mut => &MEM_Data_impl;
	private MEM_RANGE[ANYSIZE_ARRAY] MEM_Data_impl;
}

[CRepr, Packed(1)]
public struct MEM_LARGE_RANGE
{
	public uint64 MLR_Align;
	public uint64 MLR_nBytes;
	public uint64 MLR_Min;
	public uint64 MLR_Max;
	public uint32 MLR_Flags;
	public uint32 MLR_Reserved;
}

[CRepr, Packed(1)]
public struct MEM_LARGE_DES
{
	public uint32 MLD_Count;
	public uint32 MLD_Type;
	public uint64 MLD_Alloc_Base;
	public uint64 MLD_Alloc_End;
	public uint32 MLD_Flags;
	public uint32 MLD_Reserved;
}

[CRepr, Packed(1)]
public struct MEM_LARGE_RESOURCE
{
	public MEM_LARGE_DES MEM_LARGE_Header;
	public MEM_LARGE_RANGE* MEM_LARGE_Data mut => &MEM_LARGE_Data_impl;
	private MEM_LARGE_RANGE[ANYSIZE_ARRAY] MEM_LARGE_Data_impl;
}

[CRepr, Packed(1)]
public struct IO_RANGE
{
	public uint64 IOR_Align;
	public uint32 IOR_nPorts;
	public uint64 IOR_Min;
	public uint64 IOR_Max;
	public uint32 IOR_RangeFlags;
	public uint64 IOR_Alias;
}

[CRepr, Packed(1)]
public struct IO_DES
{
	public uint32 IOD_Count;
	public uint32 IOD_Type;
	public uint64 IOD_Alloc_Base;
	public uint64 IOD_Alloc_End;
	public uint32 IOD_DesFlags;
}

[CRepr]
public struct IO_RESOURCE
{
	public IO_DES IO_Header;
	public IO_RANGE* IO_Data mut => &IO_Data_impl;
	private IO_RANGE[ANYSIZE_ARRAY] IO_Data_impl;
}

[CRepr, Packed(1)]
public struct DMA_RANGE
{
	public uint32 DR_Min;
	public uint32 DR_Max;
	public uint32 DR_Flags;
}

[CRepr, Packed(1)]
public struct DMA_DES
{
	public uint32 DD_Count;
	public uint32 DD_Type;
	public uint32 DD_Flags;
	public uint32 DD_Alloc_Chan;
}

[CRepr, Packed(1)]
public struct DMA_RESOURCE
{
	public DMA_DES DMA_Header;
	public DMA_RANGE* DMA_Data mut => &DMA_Data_impl;
	private DMA_RANGE[ANYSIZE_ARRAY] DMA_Data_impl;
}

[CRepr, Packed(1)]
public struct IRQ_RANGE
{
	public uint32 IRQR_Min;
	public uint32 IRQR_Max;
	public uint32 IRQR_Flags;
}

[CRepr, Packed(1)]
public struct IRQ_DES_32
{
	public uint32 IRQD_Count;
	public uint32 IRQD_Type;
	public uint32 IRQD_Flags;
	public uint32 IRQD_Alloc_Num;
	public uint32 IRQD_Affinity;
}

[CRepr, Packed(1)]
public struct IRQ_DES_64
{
	public uint32 IRQD_Count;
	public uint32 IRQD_Type;
	public uint32 IRQD_Flags;
	public uint32 IRQD_Alloc_Num;
	public uint64 IRQD_Affinity;
}

[CRepr, Packed(1)]
public struct IRQ_RESOURCE_32
{
	public IRQ_DES_32 IRQ_Header;
	public IRQ_RANGE* IRQ_Data mut => &IRQ_Data_impl;
	private IRQ_RANGE[ANYSIZE_ARRAY] IRQ_Data_impl;
}

[CRepr, Packed(1)]
public struct IRQ_RESOURCE_64
{
	public IRQ_DES_64 IRQ_Header;
	public IRQ_RANGE* IRQ_Data mut => &IRQ_Data_impl;
	private IRQ_RANGE[ANYSIZE_ARRAY] IRQ_Data_impl;
}

[CRepr, Packed(1)]
public struct DEVPRIVATE_RANGE
{
	public uint32 PR_Data1;
	public uint32 PR_Data2;
	public uint32 PR_Data3;
}

[CRepr, Packed(1)]
public struct DEVPRIVATE_DES
{
	public uint32 PD_Count;
	public uint32 PD_Type;
	public uint32 PD_Data1;
	public uint32 PD_Data2;
	public uint32 PD_Data3;
	public uint32 PD_Flags;
}

[CRepr, Packed(1)]
public struct DEVPRIVATE_RESOURCE
{
	public DEVPRIVATE_DES PRV_Header;
	public DEVPRIVATE_RANGE* PRV_Data mut => &PRV_Data_impl;
	private DEVPRIVATE_RANGE[ANYSIZE_ARRAY] PRV_Data_impl;
}

[CRepr, Packed(1)]
public struct CS_DES
{
	public uint32 CSD_SignatureLength;
	public uint32 CSD_LegacyDataOffset;
	public uint32 CSD_LegacyDataSize;
	public uint32 CSD_Flags;
	public Guid CSD_ClassGuid;
	public uint8* CSD_Signature mut => &CSD_Signature_impl;
	private uint8[ANYSIZE_ARRAY] CSD_Signature_impl;
}

[CRepr, Packed(1)]
public struct CS_RESOURCE
{
	public CS_DES CS_Header;
}

[CRepr, Packed(1)]
public struct PCCARD_DES
{
	public uint32 PCD_Count;
	public uint32 PCD_Type;
	public uint32 PCD_Flags;
	public uint8 PCD_ConfigIndex;
	public uint8[3] PCD_Reserved;
	public uint32 PCD_MemoryCardBase1;
	public uint32 PCD_MemoryCardBase2;
	public uint32[2] PCD_MemoryCardBase;
	public uint16[2] PCD_MemoryFlags;
	public uint8[2] PCD_IoFlags;
}

[CRepr, Packed(1)]
public struct PCCARD_RESOURCE
{
	public PCCARD_DES PcCard_Header;
}

[CRepr, Packed(1)]
public struct MFCARD_DES
{
	public uint32 PMF_Count;
	public uint32 PMF_Type;
	public uint32 PMF_Flags;
	public uint8 PMF_ConfigOptions;
	public uint8 PMF_IoResourceIndex;
	public uint8[2] PMF_Reserved;
	public uint32 PMF_ConfigRegisterBase;
}

[CRepr, Packed(1)]
public struct MFCARD_RESOURCE
{
	public MFCARD_DES MfCard_Header;
}

[CRepr, Packed(1)]
public struct BUSNUMBER_RANGE
{
	public uint32 BUSR_Min;
	public uint32 BUSR_Max;
	public uint32 BUSR_nBusNumbers;
	public uint32 BUSR_Flags;
}

[CRepr, Packed(1)]
public struct BUSNUMBER_DES
{
	public uint32 BUSD_Count;
	public uint32 BUSD_Type;
	public uint32 BUSD_Flags;
	public uint32 BUSD_Alloc_Base;
	public uint32 BUSD_Alloc_End;
}

[CRepr, Packed(1)]
public struct BUSNUMBER_RESOURCE
{
	public BUSNUMBER_DES BusNumber_Header;
	public BUSNUMBER_RANGE* BusNumber_Data mut => &BusNumber_Data_impl;
	private BUSNUMBER_RANGE[ANYSIZE_ARRAY] BusNumber_Data_impl;
}

[CRepr, Packed(1)]
public struct CONNECTION_DES
{
	public uint32 COND_Type;
	public uint32 COND_Flags;
	public uint8 COND_Class;
	public uint8 COND_ClassType;
	public uint8 COND_Reserved1;
	public uint8 COND_Reserved2;
	public LARGE_INTEGER COND_Id;
}

[CRepr, Packed(1)]
public struct CONNECTION_RESOURCE
{
	public CONNECTION_DES Connection_Header;
}

[CRepr, Packed(1)]
public struct HWProfileInfo_sA
{
	public uint32 HWPI_ulHWProfile;
	public CHAR[80] HWPI_szFriendlyName;
	public uint32 HWPI_dwFlags;
}

[CRepr, Packed(1)]
public struct HWPROFILEINFO_W
{
	public uint32 HWPI_ulHWProfile;
	public char16[80] HWPI_szFriendlyName;
	public uint32 HWPI_dwFlags;
}

[CRepr]
public struct CM_NOTIFY_FILTER
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _DeviceInstance_e__Struct
		{
			public char16[200] InstanceId;
		}
		[CRepr]
		public struct _DeviceInterface_e__Struct
		{
			public Guid ClassGuid;
		}
		[CRepr]
		public struct _DeviceHandle_e__Struct
		{
			public HANDLE hTarget;
		}
		public _DeviceInterface_e__Struct DeviceInterface;
		public _DeviceHandle_e__Struct DeviceHandle;
		public _DeviceInstance_e__Struct DeviceInstance;
	}
	public uint32 cbSize;
	public uint32 Flags;
	public CM_NOTIFY_FILTER_TYPE FilterType;
	public uint32 Reserved;
	public _u_e__Union u;
}

[CRepr]
public struct CM_NOTIFY_EVENT_DATA
{
	[CRepr, Union]
	public struct _u_e__Union
	{
		[CRepr]
		public struct _DeviceHandle_e__Struct
		{
			public Guid EventGuid;
			public int32 NameOffset;
			public uint32 DataSize;
			public uint8* Data mut => &Data_impl;
			private uint8[ANYSIZE_ARRAY] Data_impl;
		}
		[CRepr]
		public struct _DeviceInterface_e__Struct
		{
			public Guid ClassGuid;
			public char16* SymbolicLink mut => &SymbolicLink_impl;
			private char16[ANYSIZE_ARRAY] SymbolicLink_impl;
		}
		[CRepr]
		public struct _DeviceInstance_e__Struct
		{
			public char16* InstanceId mut => &InstanceId_impl;
			private char16[ANYSIZE_ARRAY] InstanceId_impl;
		}
		public _DeviceInterface_e__Struct DeviceInterface;
		public _DeviceHandle_e__Struct DeviceHandle;
		public _DeviceInstance_e__Struct DeviceInstance;
	}
	public CM_NOTIFY_FILTER_TYPE FilterType;
	public uint32 Reserved;
	public _u_e__Union u;
}

#endregion

#region Functions
public static
{
	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfInformationA(void* InfSpec, uint32 SearchControl, SP_INF_INFORMATION* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetInfInformation(void* InfSpec, uint32 SearchControl, SP_INF_INFORMATION* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetInfInformationA(InfSpec, SearchControl, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfInformationW(void* InfSpec, uint32 SearchControl, SP_INF_INFORMATION* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfFileInformationA(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupQueryInfFileInformation(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupQueryInfFileInformationA(InfInformation, InfIndex, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfFileInformationW(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfOriginalFileInformationA(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, SP_ORIGINAL_FILE_INFO_A* OriginalFileInfo);
	public static BOOL SetupQueryInfOriginalFileInformation(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, SP_ORIGINAL_FILE_INFO_A* OriginalFileInfo) => SetupQueryInfOriginalFileInformationA(InfInformation, InfIndex, AlternatePlatformInfo, OriginalFileInfo);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfOriginalFileInformationW(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, SP_ORIGINAL_FILE_INFO_W* OriginalFileInfo);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfVersionInformationA(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, PSTR Key, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupQueryInfVersionInformation(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, PSTR Key, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupQueryInfVersionInformationA(InfInformation, InfIndex, Key, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryInfVersionInformationW(SP_INF_INFORMATION* InfInformation, uint32 InfIndex, PWSTR Key, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfDriverStoreLocationA(PSTR FileName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PSTR LocaleName, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetInfDriverStoreLocation(PSTR FileName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PSTR LocaleName, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetInfDriverStoreLocationA(FileName, AlternatePlatformInfo, LocaleName, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfDriverStoreLocationW(PWSTR FileName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PWSTR LocaleName, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfPublishedNameA(PSTR DriverStoreLocation, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetInfPublishedName(PSTR DriverStoreLocation, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetInfPublishedNameA(DriverStoreLocation, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfPublishedNameW(PWSTR DriverStoreLocation, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfFileListA(PSTR DirectoryPath, uint32 InfStyle, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetInfFileList(PSTR DirectoryPath, uint32 InfStyle, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetInfFileListA(DirectoryPath, InfStyle, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetInfFileListW(PWSTR DirectoryPath, uint32 InfStyle, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupOpenInfFileW(PWSTR FileName, PWSTR InfClass, uint32 InfStyle, uint32* ErrorLine);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupOpenInfFileA(PSTR FileName, PSTR InfClass, uint32 InfStyle, uint32* ErrorLine);
	public static void* SetupOpenInfFile(PSTR FileName, PSTR InfClass, uint32 InfStyle, uint32* ErrorLine) => SetupOpenInfFileA(FileName, InfClass, InfStyle, ErrorLine);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupOpenMasterInf();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupOpenAppendInfFileW(PWSTR FileName, void* InfHandle, uint32* ErrorLine);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupOpenAppendInfFileA(PSTR FileName, void* InfHandle, uint32* ErrorLine);
	public static BOOL SetupOpenAppendInfFile(PSTR FileName, void* InfHandle, uint32* ErrorLine) => SetupOpenAppendInfFileA(FileName, InfHandle, ErrorLine);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupCloseInfFile(void* InfHandle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFindFirstLineA(void* InfHandle, PSTR Section, PSTR Key, INFCONTEXT* Context);
	public static BOOL SetupFindFirstLine(void* InfHandle, PSTR Section, PSTR Key, INFCONTEXT* Context) => SetupFindFirstLineA(InfHandle, Section, Key, Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFindFirstLineW(void* InfHandle, PWSTR Section, PWSTR Key, INFCONTEXT* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFindNextLine(INFCONTEXT* ContextIn, INFCONTEXT* ContextOut);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFindNextMatchLineA(INFCONTEXT* ContextIn, PSTR Key, INFCONTEXT* ContextOut);
	public static BOOL SetupFindNextMatchLine(INFCONTEXT* ContextIn, PSTR Key, INFCONTEXT* ContextOut) => SetupFindNextMatchLineA(ContextIn, Key, ContextOut);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFindNextMatchLineW(INFCONTEXT* ContextIn, PWSTR Key, INFCONTEXT* ContextOut);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetLineByIndexA(void* InfHandle, PSTR Section, uint32 Index, INFCONTEXT* Context);
	public static BOOL SetupGetLineByIndex(void* InfHandle, PSTR Section, uint32 Index, INFCONTEXT* Context) => SetupGetLineByIndexA(InfHandle, Section, Index, Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetLineByIndexW(void* InfHandle, PWSTR Section, uint32 Index, INFCONTEXT* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetupGetLineCountA(void* InfHandle, PSTR Section);
	public static int32 SetupGetLineCount(void* InfHandle, PSTR Section) => SetupGetLineCountA(InfHandle, Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetupGetLineCountW(void* InfHandle, PWSTR Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetLineTextA(INFCONTEXT* Context, void* InfHandle, PSTR Section, PSTR Key, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetLineText(INFCONTEXT* Context, void* InfHandle, PSTR Section, PSTR Key, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetLineTextA(Context, InfHandle, Section, Key, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetLineTextW(INFCONTEXT* Context, void* InfHandle, PWSTR Section, PWSTR Key, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupGetFieldCount(INFCONTEXT* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetStringFieldA(INFCONTEXT* Context, uint32 FieldIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetStringField(INFCONTEXT* Context, uint32 FieldIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetStringFieldA(Context, FieldIndex, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetStringFieldW(INFCONTEXT* Context, uint32 FieldIndex, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetIntField(INFCONTEXT* Context, uint32 FieldIndex, int32* IntegerValue);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetMultiSzFieldA(INFCONTEXT* Context, uint32 FieldIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetMultiSzField(INFCONTEXT* Context, uint32 FieldIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetMultiSzFieldA(Context, FieldIndex, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetMultiSzFieldW(INFCONTEXT* Context, uint32 FieldIndex, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetBinaryField(INFCONTEXT* Context, uint32 FieldIndex, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupGetFileCompressionInfoA(PSTR SourceFileName, PSTR* ActualSourceFileName, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType);
	public static uint32 SetupGetFileCompressionInfo(PSTR SourceFileName, PSTR* ActualSourceFileName, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType) => SetupGetFileCompressionInfoA(SourceFileName, ActualSourceFileName, SourceFileSize, TargetFileSize, CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupGetFileCompressionInfoW(PWSTR SourceFileName, PWSTR* ActualSourceFileName, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetFileCompressionInfoExA(PSTR SourceFileName, uint8* ActualSourceFileNameBuffer, uint32 ActualSourceFileNameBufferLen, uint32* RequiredBufferLen, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType);
	public static BOOL SetupGetFileCompressionInfoEx(PSTR SourceFileName, uint8* ActualSourceFileNameBuffer, uint32 ActualSourceFileNameBufferLen, uint32* RequiredBufferLen, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType) => SetupGetFileCompressionInfoExA(SourceFileName, ActualSourceFileNameBuffer, ActualSourceFileNameBufferLen, RequiredBufferLen, SourceFileSize, TargetFileSize, CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetFileCompressionInfoExW(PWSTR SourceFileName, char16* ActualSourceFileNameBuffer, uint32 ActualSourceFileNameBufferLen, uint32* RequiredBufferLen, uint32* SourceFileSize, uint32* TargetFileSize, uint32* CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDecompressOrCopyFileA(PSTR SourceFileName, PSTR TargetFileName, uint32* CompressionType);
	public static uint32 SetupDecompressOrCopyFile(PSTR SourceFileName, PSTR TargetFileName, uint32* CompressionType) => SetupDecompressOrCopyFileA(SourceFileName, TargetFileName, CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDecompressOrCopyFileW(PWSTR SourceFileName, PWSTR TargetFileName, uint32* CompressionType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceFileLocationA(void* InfHandle, INFCONTEXT* InfContext, PSTR FileName, uint32* SourceId, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetSourceFileLocation(void* InfHandle, INFCONTEXT* InfContext, PSTR FileName, uint32* SourceId, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetSourceFileLocationA(InfHandle, InfContext, FileName, SourceId, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceFileLocationW(void* InfHandle, INFCONTEXT* InfContext, PWSTR FileName, uint32* SourceId, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceFileSizeA(void* InfHandle, INFCONTEXT* InfContext, PSTR FileName, PSTR Section, uint32* FileSize, uint32 RoundingFactor);
	public static BOOL SetupGetSourceFileSize(void* InfHandle, INFCONTEXT* InfContext, PSTR FileName, PSTR Section, uint32* FileSize, uint32 RoundingFactor) => SetupGetSourceFileSizeA(InfHandle, InfContext, FileName, Section, FileSize, RoundingFactor);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceFileSizeW(void* InfHandle, INFCONTEXT* InfContext, PWSTR FileName, PWSTR Section, uint32* FileSize, uint32 RoundingFactor);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetTargetPathA(void* InfHandle, INFCONTEXT* InfContext, PSTR Section, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetTargetPath(void* InfHandle, INFCONTEXT* InfContext, PSTR Section, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetTargetPathA(InfHandle, InfContext, Section, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetTargetPathW(void* InfHandle, INFCONTEXT* InfContext, PWSTR Section, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetSourceListA(uint32 Flags, PSTR* SourceList, uint32 SourceCount);
	public static BOOL SetupSetSourceList(uint32 Flags, PSTR* SourceList, uint32 SourceCount) => SetupSetSourceListA(Flags, SourceList, SourceCount);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetSourceListW(uint32 Flags, PWSTR* SourceList, uint32 SourceCount);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCancelTemporarySourceList();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddToSourceListA(uint32 Flags, PSTR Source);
	public static BOOL SetupAddToSourceList(uint32 Flags, PSTR Source) => SetupAddToSourceListA(Flags, Source);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddToSourceListW(uint32 Flags, PWSTR Source);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFromSourceListA(uint32 Flags, PSTR Source);
	public static BOOL SetupRemoveFromSourceList(uint32 Flags, PSTR Source) => SetupRemoveFromSourceListA(Flags, Source);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFromSourceListW(uint32 Flags, PWSTR Source);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQuerySourceListA(uint32 Flags, PSTR** List, uint32* Count);
	public static BOOL SetupQuerySourceList(uint32 Flags, PSTR** List, uint32* Count) => SetupQuerySourceListA(Flags, List, Count);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQuerySourceListW(uint32 Flags, PWSTR** List, uint32* Count);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFreeSourceListA(PSTR** List, uint32 Count);
	public static BOOL SetupFreeSourceList(PSTR** List, uint32 Count) => SetupFreeSourceListA(List, Count);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupFreeSourceListW(PWSTR** List, uint32 Count);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupPromptForDiskA(HWND hwndParent, PSTR DialogTitle, PSTR DiskName, PSTR PathToSource, PSTR FileSought, PSTR TagFile, uint32 DiskPromptStyle, uint8* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize);
	public static uint32 SetupPromptForDisk(HWND hwndParent, PSTR DialogTitle, PSTR DiskName, PSTR PathToSource, PSTR FileSought, PSTR TagFile, uint32 DiskPromptStyle, uint8* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize) => SetupPromptForDiskA(hwndParent, DialogTitle, DiskName, PathToSource, FileSought, TagFile, DiskPromptStyle, PathBuffer, PathBufferSize, PathRequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupPromptForDiskW(HWND hwndParent, PWSTR DialogTitle, PWSTR DiskName, PWSTR PathToSource, PWSTR FileSought, PWSTR TagFile, uint32 DiskPromptStyle, char16* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupCopyErrorA(HWND hwndParent, PSTR DialogTitle, PSTR DiskName, PSTR PathToSource, PSTR SourceFile, PSTR TargetPathFile, uint32 Win32ErrorCode, uint32 Style, uint8* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize);
	public static uint32 SetupCopyError(HWND hwndParent, PSTR DialogTitle, PSTR DiskName, PSTR PathToSource, PSTR SourceFile, PSTR TargetPathFile, uint32 Win32ErrorCode, uint32 Style, uint8* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize) => SetupCopyErrorA(hwndParent, DialogTitle, DiskName, PathToSource, SourceFile, TargetPathFile, Win32ErrorCode, Style, PathBuffer, PathBufferSize, PathRequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupCopyErrorW(HWND hwndParent, PWSTR DialogTitle, PWSTR DiskName, PWSTR PathToSource, PWSTR SourceFile, PWSTR TargetPathFile, uint32 Win32ErrorCode, uint32 Style, char16* PathBuffer, uint32 PathBufferSize, uint32* PathRequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupRenameErrorA(HWND hwndParent, PSTR DialogTitle, PSTR SourceFile, PSTR TargetFile, uint32 Win32ErrorCode, uint32 Style);
	public static uint32 SetupRenameError(HWND hwndParent, PSTR DialogTitle, PSTR SourceFile, PSTR TargetFile, uint32 Win32ErrorCode, uint32 Style) => SetupRenameErrorA(hwndParent, DialogTitle, SourceFile, TargetFile, Win32ErrorCode, Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupRenameErrorW(HWND hwndParent, PWSTR DialogTitle, PWSTR SourceFile, PWSTR TargetFile, uint32 Win32ErrorCode, uint32 Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDeleteErrorA(HWND hwndParent, PSTR DialogTitle, PSTR File, uint32 Win32ErrorCode, uint32 Style);
	public static uint32 SetupDeleteError(HWND hwndParent, PSTR DialogTitle, PSTR File, uint32 Win32ErrorCode, uint32 Style) => SetupDeleteErrorA(hwndParent, DialogTitle, File, Win32ErrorCode, Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDeleteErrorW(HWND hwndParent, PWSTR DialogTitle, PWSTR File, uint32 Win32ErrorCode, uint32 Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupBackupErrorA(HWND hwndParent, PSTR DialogTitle, PSTR SourceFile, PSTR TargetFile, uint32 Win32ErrorCode, uint32 Style);
	public static uint32 SetupBackupError(HWND hwndParent, PSTR DialogTitle, PSTR SourceFile, PSTR TargetFile, uint32 Win32ErrorCode, uint32 Style) => SetupBackupErrorA(hwndParent, DialogTitle, SourceFile, TargetFile, Win32ErrorCode, Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupBackupErrorW(HWND hwndParent, PWSTR DialogTitle, PWSTR SourceFile, PWSTR TargetFile, uint32 Win32ErrorCode, uint32 Style);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetDirectoryIdA(void* InfHandle, uint32 Id, PSTR Directory);
	public static BOOL SetupSetDirectoryId(void* InfHandle, uint32 Id, PSTR Directory) => SetupSetDirectoryIdA(InfHandle, Id, Directory);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetDirectoryIdW(void* InfHandle, uint32 Id, PWSTR Directory);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetDirectoryIdExA(void* InfHandle, uint32 Id, PSTR Directory, uint32 Flags, uint32 Reserved1, void* Reserved2);
	public static BOOL SetupSetDirectoryIdEx(void* InfHandle, uint32 Id, PSTR Directory, uint32 Flags, uint32 Reserved1, void* Reserved2) => SetupSetDirectoryIdExA(InfHandle, Id, Directory, Flags, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetDirectoryIdExW(void* InfHandle, uint32 Id, PWSTR Directory, uint32 Flags, uint32 Reserved1, void* Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceInfoA(void* InfHandle, uint32 SourceId, uint32 InfoDesired, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupGetSourceInfo(void* InfHandle, uint32 SourceId, uint32 InfoDesired, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupGetSourceInfoA(InfHandle, SourceId, InfoDesired, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetSourceInfoW(void* InfHandle, uint32 SourceId, uint32 InfoDesired, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFileA(void* InfHandle, INFCONTEXT* InfContext, PSTR SourceFile, PSTR SourcePathRoot, PSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_A CopyMsgHandler, void* Context);
	public static BOOL SetupInstallFile(void* InfHandle, INFCONTEXT* InfContext, PSTR SourceFile, PSTR SourcePathRoot, PSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_A CopyMsgHandler, void* Context) => SetupInstallFileA(InfHandle, InfContext, SourceFile, SourcePathRoot, DestinationName, CopyStyle, CopyMsgHandler, Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFileW(void* InfHandle, INFCONTEXT* InfContext, PWSTR SourceFile, PWSTR SourcePathRoot, PWSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_W CopyMsgHandler, void* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFileExA(void* InfHandle, INFCONTEXT* InfContext, PSTR SourceFile, PSTR SourcePathRoot, PSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_A CopyMsgHandler, void* Context, BOOL* FileWasInUse);
	public static BOOL SetupInstallFileEx(void* InfHandle, INFCONTEXT* InfContext, PSTR SourceFile, PSTR SourcePathRoot, PSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_A CopyMsgHandler, void* Context, BOOL* FileWasInUse) => SetupInstallFileExA(InfHandle, InfContext, SourceFile, SourcePathRoot, DestinationName, CopyStyle, CopyMsgHandler, Context, FileWasInUse);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFileExW(void* InfHandle, INFCONTEXT* InfContext, PWSTR SourceFile, PWSTR SourcePathRoot, PWSTR DestinationName, SP_COPY_STYLE CopyStyle, PSP_FILE_CALLBACK_W CopyMsgHandler, void* Context, BOOL* FileWasInUse);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupOpenFileQueue();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCloseFileQueue(void* QueueHandle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetFileQueueAlternatePlatformA(void* QueueHandle, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PSTR AlternateDefaultCatalogFile);
	public static BOOL SetupSetFileQueueAlternatePlatform(void* QueueHandle, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PSTR AlternateDefaultCatalogFile) => SetupSetFileQueueAlternatePlatformA(QueueHandle, AlternatePlatformInfo, AlternateDefaultCatalogFile);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetFileQueueAlternatePlatformW(void* QueueHandle, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, PWSTR AlternateDefaultCatalogFile);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetPlatformPathOverrideA(PSTR Override);
	public static BOOL SetupSetPlatformPathOverride(PSTR Override) => SetupSetPlatformPathOverrideA(Override);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetPlatformPathOverrideW(PWSTR Override);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopyA(void* QueueHandle, PSTR SourceRootPath, PSTR SourcePath, PSTR SourceFilename, PSTR SourceDescription, PSTR SourceTagfile, PSTR TargetDirectory, PSTR TargetFilename, uint32 CopyStyle);
	public static BOOL SetupQueueCopy(void* QueueHandle, PSTR SourceRootPath, PSTR SourcePath, PSTR SourceFilename, PSTR SourceDescription, PSTR SourceTagfile, PSTR TargetDirectory, PSTR TargetFilename, uint32 CopyStyle) => SetupQueueCopyA(QueueHandle, SourceRootPath, SourcePath, SourceFilename, SourceDescription, SourceTagfile, TargetDirectory, TargetFilename, CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopyW(void* QueueHandle, PWSTR SourceRootPath, PWSTR SourcePath, PWSTR SourceFilename, PWSTR SourceDescription, PWSTR SourceTagfile, PWSTR TargetDirectory, PWSTR TargetFilename, uint32 CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopyIndirectA(SP_FILE_COPY_PARAMS_A* CopyParams);
	public static BOOL SetupQueueCopyIndirect(SP_FILE_COPY_PARAMS_A* CopyParams) => SetupQueueCopyIndirectA(CopyParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopyIndirectW(SP_FILE_COPY_PARAMS_W* CopyParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDefaultCopyA(void* QueueHandle, void* InfHandle, PSTR SourceRootPath, PSTR SourceFilename, PSTR TargetFilename, uint32 CopyStyle);
	public static BOOL SetupQueueDefaultCopy(void* QueueHandle, void* InfHandle, PSTR SourceRootPath, PSTR SourceFilename, PSTR TargetFilename, uint32 CopyStyle) => SetupQueueDefaultCopyA(QueueHandle, InfHandle, SourceRootPath, SourceFilename, TargetFilename, CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDefaultCopyW(void* QueueHandle, void* InfHandle, PWSTR SourceRootPath, PWSTR SourceFilename, PWSTR TargetFilename, uint32 CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopySectionA(void* QueueHandle, PSTR SourceRootPath, void* InfHandle, void* ListInfHandle, PSTR Section, uint32 CopyStyle);
	public static BOOL SetupQueueCopySection(void* QueueHandle, PSTR SourceRootPath, void* InfHandle, void* ListInfHandle, PSTR Section, uint32 CopyStyle) => SetupQueueCopySectionA(QueueHandle, SourceRootPath, InfHandle, ListInfHandle, Section, CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueCopySectionW(void* QueueHandle, PWSTR SourceRootPath, void* InfHandle, void* ListInfHandle, PWSTR Section, uint32 CopyStyle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDeleteA(void* QueueHandle, PSTR PathPart1, PSTR PathPart2);
	public static BOOL SetupQueueDelete(void* QueueHandle, PSTR PathPart1, PSTR PathPart2) => SetupQueueDeleteA(QueueHandle, PathPart1, PathPart2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDeleteW(void* QueueHandle, PWSTR PathPart1, PWSTR PathPart2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDeleteSectionA(void* QueueHandle, void* InfHandle, void* ListInfHandle, PSTR Section);
	public static BOOL SetupQueueDeleteSection(void* QueueHandle, void* InfHandle, void* ListInfHandle, PSTR Section) => SetupQueueDeleteSectionA(QueueHandle, InfHandle, ListInfHandle, Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueDeleteSectionW(void* QueueHandle, void* InfHandle, void* ListInfHandle, PWSTR Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueRenameA(void* QueueHandle, PSTR SourcePath, PSTR SourceFilename, PSTR TargetPath, PSTR TargetFilename);
	public static BOOL SetupQueueRename(void* QueueHandle, PSTR SourcePath, PSTR SourceFilename, PSTR TargetPath, PSTR TargetFilename) => SetupQueueRenameA(QueueHandle, SourcePath, SourceFilename, TargetPath, TargetFilename);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueRenameW(void* QueueHandle, PWSTR SourcePath, PWSTR SourceFilename, PWSTR TargetPath, PWSTR TargetFilename);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueRenameSectionA(void* QueueHandle, void* InfHandle, void* ListInfHandle, PSTR Section);
	public static BOOL SetupQueueRenameSection(void* QueueHandle, void* InfHandle, void* ListInfHandle, PSTR Section) => SetupQueueRenameSectionA(QueueHandle, InfHandle, ListInfHandle, Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueueRenameSectionW(void* QueueHandle, void* InfHandle, void* ListInfHandle, PWSTR Section);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCommitFileQueueA(HWND Owner, void* QueueHandle, PSP_FILE_CALLBACK_A MsgHandler, void* Context);
	public static BOOL SetupCommitFileQueue(HWND Owner, void* QueueHandle, PSP_FILE_CALLBACK_A MsgHandler, void* Context) => SetupCommitFileQueueA(Owner, QueueHandle, MsgHandler, Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCommitFileQueueW(HWND Owner, void* QueueHandle, PSP_FILE_CALLBACK_W MsgHandler, void* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupScanFileQueueA(void* FileQueue, uint32 Flags, HWND Window, PSP_FILE_CALLBACK_A CallbackRoutine, void* CallbackContext, uint32* Result);
	public static BOOL SetupScanFileQueue(void* FileQueue, uint32 Flags, HWND Window, PSP_FILE_CALLBACK_A CallbackRoutine, void* CallbackContext, uint32* Result) => SetupScanFileQueueA(FileQueue, Flags, Window, CallbackRoutine, CallbackContext, Result);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupScanFileQueueW(void* FileQueue, uint32 Flags, HWND Window, PSP_FILE_CALLBACK_W CallbackRoutine, void* CallbackContext, uint32* Result);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetFileQueueCount(void* FileQueue, uint32 SubQueueFileOp, uint32* NumOperations);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetFileQueueFlags(void* FileQueue, uint32* Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetFileQueueFlags(void* FileQueue, uint32 FlagMask, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCopyOEMInfA(PSTR SourceInfFileName, PSTR OEMSourceMediaLocation, OEM_SOURCE_MEDIA_TYPE OEMSourceMediaType, uint32 CopyStyle, uint8* DestinationInfFileName, uint32 DestinationInfFileNameSize, uint32* RequiredSize, PSTR* DestinationInfFileNameComponent);
	public static BOOL SetupCopyOEMInf(PSTR SourceInfFileName, PSTR OEMSourceMediaLocation, OEM_SOURCE_MEDIA_TYPE OEMSourceMediaType, uint32 CopyStyle, uint8* DestinationInfFileName, uint32 DestinationInfFileNameSize, uint32* RequiredSize, PSTR* DestinationInfFileNameComponent) => SetupCopyOEMInfA(SourceInfFileName, OEMSourceMediaLocation, OEMSourceMediaType, CopyStyle, DestinationInfFileName, DestinationInfFileNameSize, RequiredSize, DestinationInfFileNameComponent);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupCopyOEMInfW(PWSTR SourceInfFileName, PWSTR OEMSourceMediaLocation, OEM_SOURCE_MEDIA_TYPE OEMSourceMediaType, uint32 CopyStyle, char16* DestinationInfFileName, uint32 DestinationInfFileNameSize, uint32* RequiredSize, PWSTR* DestinationInfFileNameComponent);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupUninstallOEMInfA(PSTR InfFileName, uint32 Flags, void* Reserved);
	public static BOOL SetupUninstallOEMInf(PSTR InfFileName, uint32 Flags, void* Reserved) => SetupUninstallOEMInfA(InfFileName, Flags, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupUninstallOEMInfW(PWSTR InfFileName, uint32 Flags, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupUninstallNewlyCopiedInfs(void* FileQueue, uint32 Flags, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupCreateDiskSpaceListA(void* Reserved1, uint32 Reserved2, uint32 Flags);
	public static void* SetupCreateDiskSpaceList(void* Reserved1, uint32 Reserved2, uint32 Flags) => SetupCreateDiskSpaceListA(Reserved1, Reserved2, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupCreateDiskSpaceListW(void* Reserved1, uint32 Reserved2, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupDuplicateDiskSpaceListA(void* DiskSpace, void* Reserved1, uint32 Reserved2, uint32 Flags);
	public static void* SetupDuplicateDiskSpaceList(void* DiskSpace, void* Reserved1, uint32 Reserved2, uint32 Flags) => SetupDuplicateDiskSpaceListA(DiskSpace, Reserved1, Reserved2, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupDuplicateDiskSpaceListW(void* DiskSpace, void* Reserved1, uint32 Reserved2, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDestroyDiskSpaceList(void* DiskSpace);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryDrivesInDiskSpaceListA(void* DiskSpace, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupQueryDrivesInDiskSpaceList(void* DiskSpace, uint8* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupQueryDrivesInDiskSpaceListA(DiskSpace, ReturnBuffer, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryDrivesInDiskSpaceListW(void* DiskSpace, char16* ReturnBuffer, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQuerySpaceRequiredOnDriveA(void* DiskSpace, PSTR DriveSpec, int64* SpaceRequired, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupQuerySpaceRequiredOnDrive(void* DiskSpace, PSTR DriveSpec, int64* SpaceRequired, void* Reserved1, uint32 Reserved2) => SetupQuerySpaceRequiredOnDriveA(DiskSpace, DriveSpec, SpaceRequired, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQuerySpaceRequiredOnDriveW(void* DiskSpace, PWSTR DriveSpec, int64* SpaceRequired, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAdjustDiskSpaceListA(void* DiskSpace, PSTR DriveRoot, int64 Amount, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupAdjustDiskSpaceList(void* DiskSpace, PSTR DriveRoot, int64 Amount, void* Reserved1, uint32 Reserved2) => SetupAdjustDiskSpaceListA(DiskSpace, DriveRoot, Amount, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAdjustDiskSpaceListW(void* DiskSpace, PWSTR DriveRoot, int64 Amount, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddToDiskSpaceListA(void* DiskSpace, PSTR TargetFilespec, int64 FileSize, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupAddToDiskSpaceList(void* DiskSpace, PSTR TargetFilespec, int64 FileSize, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2) => SetupAddToDiskSpaceListA(DiskSpace, TargetFilespec, FileSize, Operation, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddToDiskSpaceListW(void* DiskSpace, PWSTR TargetFilespec, int64 FileSize, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddSectionToDiskSpaceListA(void* DiskSpace, void* InfHandle, void* ListInfHandle, PSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupAddSectionToDiskSpaceList(void* DiskSpace, void* InfHandle, void* ListInfHandle, PSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2) => SetupAddSectionToDiskSpaceListA(DiskSpace, InfHandle, ListInfHandle, SectionName, Operation, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddSectionToDiskSpaceListW(void* DiskSpace, void* InfHandle, void* ListInfHandle, PWSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddInstallSectionToDiskSpaceListA(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PSTR SectionName, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupAddInstallSectionToDiskSpaceList(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PSTR SectionName, void* Reserved1, uint32 Reserved2) => SetupAddInstallSectionToDiskSpaceListA(DiskSpace, InfHandle, LayoutInfHandle, SectionName, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupAddInstallSectionToDiskSpaceListW(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PWSTR SectionName, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFromDiskSpaceListA(void* DiskSpace, PSTR TargetFilespec, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupRemoveFromDiskSpaceList(void* DiskSpace, PSTR TargetFilespec, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2) => SetupRemoveFromDiskSpaceListA(DiskSpace, TargetFilespec, Operation, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFromDiskSpaceListW(void* DiskSpace, PWSTR TargetFilespec, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveSectionFromDiskSpaceListA(void* DiskSpace, void* InfHandle, void* ListInfHandle, PSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupRemoveSectionFromDiskSpaceList(void* DiskSpace, void* InfHandle, void* ListInfHandle, PSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2) => SetupRemoveSectionFromDiskSpaceListA(DiskSpace, InfHandle, ListInfHandle, SectionName, Operation, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveSectionFromDiskSpaceListW(void* DiskSpace, void* InfHandle, void* ListInfHandle, PWSTR SectionName, SETUP_FILE_OPERATION Operation, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveInstallSectionFromDiskSpaceListA(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PSTR SectionName, void* Reserved1, uint32 Reserved2);
	public static BOOL SetupRemoveInstallSectionFromDiskSpaceList(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PSTR SectionName, void* Reserved1, uint32 Reserved2) => SetupRemoveInstallSectionFromDiskSpaceListA(DiskSpace, InfHandle, LayoutInfHandle, SectionName, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveInstallSectionFromDiskSpaceListW(void* DiskSpace, void* InfHandle, void* LayoutInfHandle, PWSTR SectionName, void* Reserved1, uint32 Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupIterateCabinetA(PSTR CabinetFile, uint32 Reserved, PSP_FILE_CALLBACK_A MsgHandler, void* Context);
	public static BOOL SetupIterateCabinet(PSTR CabinetFile, uint32 Reserved, PSP_FILE_CALLBACK_A MsgHandler, void* Context) => SetupIterateCabinetA(CabinetFile, Reserved, MsgHandler, Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupIterateCabinetW(PWSTR CabinetFile, uint32 Reserved, PSP_FILE_CALLBACK_W MsgHandler, void* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetupPromptReboot(void* FileQueue, HWND Owner, BOOL ScanOnly);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupInitDefaultQueueCallback(HWND OwnerWindow);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupInitDefaultQueueCallbackEx(HWND OwnerWindow, HWND AlternateProgressWindow, uint32 ProgressMessage, uint32 Reserved1, void* Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupTermDefaultQueueCallback(void* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDefaultQueueCallbackA(void* Context, uint32 Notification, uint Param1, uint Param2);
	public static uint32 SetupDefaultQueueCallback(void* Context, uint32 Notification, uint Param1, uint Param2) => SetupDefaultQueueCallbackA(Context, Notification, Param1, Param2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SetupDefaultQueueCallbackW(void* Context, uint32 Notification, uint Param1, uint Param2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFromInfSectionA(HWND Owner, void* InfHandle, PSTR SectionName, uint32 Flags, HKEY RelativeKeyRoot, PSTR SourceRootPath, uint32 CopyFlags, PSP_FILE_CALLBACK_A MsgHandler, void* Context, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);
	public static BOOL SetupInstallFromInfSection(HWND Owner, void* InfHandle, PSTR SectionName, uint32 Flags, HKEY RelativeKeyRoot, PSTR SourceRootPath, uint32 CopyFlags, PSP_FILE_CALLBACK_A MsgHandler, void* Context, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData) => SetupInstallFromInfSectionA(Owner, InfHandle, SectionName, Flags, RelativeKeyRoot, SourceRootPath, CopyFlags, MsgHandler, Context, DeviceInfoSet, DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFromInfSectionW(HWND Owner, void* InfHandle, PWSTR SectionName, uint32 Flags, HKEY RelativeKeyRoot, PWSTR SourceRootPath, uint32 CopyFlags, PSP_FILE_CALLBACK_W MsgHandler, void* Context, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFilesFromInfSectionA(void* InfHandle, void* LayoutInfHandle, void* FileQueue, PSTR SectionName, PSTR SourceRootPath, uint32 CopyFlags);
	public static BOOL SetupInstallFilesFromInfSection(void* InfHandle, void* LayoutInfHandle, void* FileQueue, PSTR SectionName, PSTR SourceRootPath, uint32 CopyFlags) => SetupInstallFilesFromInfSectionA(InfHandle, LayoutInfHandle, FileQueue, SectionName, SourceRootPath, CopyFlags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallFilesFromInfSectionW(void* InfHandle, void* LayoutInfHandle, void* FileQueue, PWSTR SectionName, PWSTR SourceRootPath, uint32 CopyFlags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallServicesFromInfSectionA(void* InfHandle, PSTR SectionName, uint32 Flags);
	public static BOOL SetupInstallServicesFromInfSection(void* InfHandle, PSTR SectionName, uint32 Flags) => SetupInstallServicesFromInfSectionA(InfHandle, SectionName, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallServicesFromInfSectionW(void* InfHandle, PWSTR SectionName, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallServicesFromInfSectionExA(void* InfHandle, PSTR SectionName, uint32 Flags, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, void* Reserved1, void* Reserved2);
	public static BOOL SetupInstallServicesFromInfSectionEx(void* InfHandle, PSTR SectionName, uint32 Flags, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, void* Reserved1, void* Reserved2) => SetupInstallServicesFromInfSectionExA(InfHandle, SectionName, Flags, DeviceInfoSet, DeviceInfoData, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupInstallServicesFromInfSectionExW(void* InfHandle, PWSTR SectionName, uint32 Flags, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, void* Reserved1, void* Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InstallHinfSectionA(HWND Window, HINSTANCE ModuleHandle, PSTR CommandLine, int32 ShowCommand);
	public static void InstallHinfSection(HWND Window, HINSTANCE ModuleHandle, PSTR CommandLine, int32 ShowCommand) => InstallHinfSectionA(Window, ModuleHandle, CommandLine, ShowCommand);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void InstallHinfSectionW(HWND Window, HINSTANCE ModuleHandle, PWSTR CommandLine, int32 ShowCommand);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupInitializeFileLogA(PSTR LogFileName, uint32 Flags);
	public static void* SetupInitializeFileLog(PSTR LogFileName, uint32 Flags) => SetupInitializeFileLogA(LogFileName, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SetupInitializeFileLogW(PWSTR LogFileName, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupTerminateFileLog(void* FileLogHandle);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupLogFileA(void* FileLogHandle, PSTR LogSectionName, PSTR SourceFilename, PSTR TargetFilename, uint32 Checksum, PSTR DiskTagfile, PSTR DiskDescription, PSTR OtherInfo, uint32 Flags);
	public static BOOL SetupLogFile(void* FileLogHandle, PSTR LogSectionName, PSTR SourceFilename, PSTR TargetFilename, uint32 Checksum, PSTR DiskTagfile, PSTR DiskDescription, PSTR OtherInfo, uint32 Flags) => SetupLogFileA(FileLogHandle, LogSectionName, SourceFilename, TargetFilename, Checksum, DiskTagfile, DiskDescription, OtherInfo, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupLogFileW(void* FileLogHandle, PWSTR LogSectionName, PWSTR SourceFilename, PWSTR TargetFilename, uint32 Checksum, PWSTR DiskTagfile, PWSTR DiskDescription, PWSTR OtherInfo, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFileLogEntryA(void* FileLogHandle, PSTR LogSectionName, PSTR TargetFilename);
	public static BOOL SetupRemoveFileLogEntry(void* FileLogHandle, PSTR LogSectionName, PSTR TargetFilename) => SetupRemoveFileLogEntryA(FileLogHandle, LogSectionName, TargetFilename);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupRemoveFileLogEntryW(void* FileLogHandle, PWSTR LogSectionName, PWSTR TargetFilename);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryFileLogA(void* FileLogHandle, PSTR LogSectionName, PSTR TargetFilename, SetupFileLogInfo DesiredInfo, uint8* DataOut, uint32 ReturnBufferSize, uint32* RequiredSize);
	public static BOOL SetupQueryFileLog(void* FileLogHandle, PSTR LogSectionName, PSTR TargetFilename, SetupFileLogInfo DesiredInfo, uint8* DataOut, uint32 ReturnBufferSize, uint32* RequiredSize) => SetupQueryFileLogA(FileLogHandle, LogSectionName, TargetFilename, DesiredInfo, DataOut, ReturnBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupQueryFileLogW(void* FileLogHandle, PWSTR LogSectionName, PWSTR TargetFilename, SetupFileLogInfo DesiredInfo, char16* DataOut, uint32 ReturnBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupOpenLog(BOOL Erase);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupLogErrorA(PSTR MessageString, uint32 Severity);
	public static BOOL SetupLogError(PSTR MessageString, uint32 Severity) => SetupLogErrorA(MessageString, Severity);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupLogErrorW(PWSTR MessageString, uint32 Severity);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupCloseLog();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint64 SetupGetThreadLogToken();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupSetThreadLogToken(uint64 LogToken);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupWriteTextLog(uint64 LogToken, uint32 Category, uint32 Flags, PSTR MessageStr);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupWriteTextLogError(uint64 LogToken, uint32 Category, uint32 LogFlags, uint32 Error, PSTR MessageStr);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SetupWriteTextLogInfLine(uint64 LogToken, uint32 Flags, void* InfHandle, INFCONTEXT* Context);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetBackupInformationA(void* QueueHandle, SP_BACKUP_QUEUE_PARAMS_V2_A* BackupParams);
	public static BOOL SetupGetBackupInformation(void* QueueHandle, SP_BACKUP_QUEUE_PARAMS_V2_A* BackupParams) => SetupGetBackupInformationA(QueueHandle, BackupParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetBackupInformationW(void* QueueHandle, SP_BACKUP_QUEUE_PARAMS_V2_W* BackupParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupPrepareQueueForRestoreA(void* QueueHandle, PSTR BackupPath, uint32 RestoreFlags);
	public static BOOL SetupPrepareQueueForRestore(void* QueueHandle, PSTR BackupPath, uint32 RestoreFlags) => SetupPrepareQueueForRestoreA(QueueHandle, BackupPath, RestoreFlags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupPrepareQueueForRestoreW(void* QueueHandle, PWSTR BackupPath, uint32 RestoreFlags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupSetNonInteractiveMode(BOOL NonInteractiveFlag);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupGetNonInteractiveMode();

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiCreateDeviceInfoList(Guid* ClassGuid, HWND hwndParent);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiCreateDeviceInfoListExA(Guid* ClassGuid, HWND hwndParent, PSTR MachineName, void* Reserved);
	public static HDEVINFO SetupDiCreateDeviceInfoListEx(Guid* ClassGuid, HWND hwndParent, PSTR MachineName, void* Reserved) => SetupDiCreateDeviceInfoListExA(ClassGuid, hwndParent, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiCreateDeviceInfoListExW(Guid* ClassGuid, HWND hwndParent, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInfoListClass(HDEVINFO DeviceInfoSet, Guid* ClassGuid);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInfoListDetailA(HDEVINFO DeviceInfoSet, SP_DEVINFO_LIST_DETAIL_DATA_A* DeviceInfoSetDetailData);
	public static BOOL SetupDiGetDeviceInfoListDetail(HDEVINFO DeviceInfoSet, SP_DEVINFO_LIST_DETAIL_DATA_A* DeviceInfoSetDetailData) => SetupDiGetDeviceInfoListDetailA(DeviceInfoSet, DeviceInfoSetDetailData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInfoListDetailW(HDEVINFO DeviceInfoSet, SP_DEVINFO_LIST_DETAIL_DATA_W* DeviceInfoSetDetailData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCreateDeviceInfoA(HDEVINFO DeviceInfoSet, PSTR DeviceName, in Guid ClassGuid, PSTR DeviceDescription, HWND hwndParent, uint32 CreationFlags, SP_DEVINFO_DATA* DeviceInfoData);
	public static BOOL SetupDiCreateDeviceInfo(HDEVINFO DeviceInfoSet, PSTR DeviceName, in Guid ClassGuid, PSTR DeviceDescription, HWND hwndParent, uint32 CreationFlags, SP_DEVINFO_DATA* DeviceInfoData) => SetupDiCreateDeviceInfoA(DeviceInfoSet, DeviceName, ClassGuid, DeviceDescription, hwndParent, CreationFlags, DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCreateDeviceInfoW(HDEVINFO DeviceInfoSet, PWSTR DeviceName, in Guid ClassGuid, PWSTR DeviceDescription, HWND hwndParent, uint32 CreationFlags, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiOpenDeviceInfoA(HDEVINFO DeviceInfoSet, PSTR DeviceInstanceId, HWND hwndParent, uint32 OpenFlags, SP_DEVINFO_DATA* DeviceInfoData);
	public static BOOL SetupDiOpenDeviceInfo(HDEVINFO DeviceInfoSet, PSTR DeviceInstanceId, HWND hwndParent, uint32 OpenFlags, SP_DEVINFO_DATA* DeviceInfoData) => SetupDiOpenDeviceInfoA(DeviceInfoSet, DeviceInstanceId, hwndParent, OpenFlags, DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiOpenDeviceInfoW(HDEVINFO DeviceInfoSet, PWSTR DeviceInstanceId, HWND hwndParent, uint32 OpenFlags, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInstanceIdA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint8* DeviceInstanceId, uint32 DeviceInstanceIdSize, uint32* RequiredSize);
	public static BOOL SetupDiGetDeviceInstanceId(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint8* DeviceInstanceId, uint32 DeviceInstanceIdSize, uint32* RequiredSize) => SetupDiGetDeviceInstanceIdA(DeviceInfoSet, DeviceInfoData, DeviceInstanceId, DeviceInstanceIdSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInstanceIdW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, char16* DeviceInstanceId, uint32 DeviceInstanceIdSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDeleteDeviceInfo(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiEnumDeviceInfo(HDEVINFO DeviceInfoSet, uint32 MemberIndex, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDestroyDeviceInfoList(HDEVINFO DeviceInfoSet);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiEnumDeviceInterfaces(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, in Guid InterfaceClassGuid, uint32 MemberIndex, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCreateDeviceInterfaceA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, in Guid InterfaceClassGuid, PSTR ReferenceString, uint32 CreationFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);
	public static BOOL SetupDiCreateDeviceInterface(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, in Guid InterfaceClassGuid, PSTR ReferenceString, uint32 CreationFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData) => SetupDiCreateDeviceInterfaceA(DeviceInfoSet, DeviceInfoData, InterfaceClassGuid, ReferenceString, CreationFlags, DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCreateDeviceInterfaceW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, in Guid InterfaceClassGuid, PWSTR ReferenceString, uint32 CreationFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiOpenDeviceInterfaceA(HDEVINFO DeviceInfoSet, PSTR DevicePath, uint32 OpenFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);
	public static BOOL SetupDiOpenDeviceInterface(HDEVINFO DeviceInfoSet, PSTR DevicePath, uint32 OpenFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData) => SetupDiOpenDeviceInterfaceA(DeviceInfoSet, DevicePath, OpenFlags, DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiOpenDeviceInterfaceW(HDEVINFO DeviceInfoSet, PWSTR DevicePath, uint32 OpenFlags, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInterfaceAlias(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, in Guid AliasInterfaceClassGuid, SP_DEVICE_INTERFACE_DATA* AliasDeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDeleteDeviceInterfaceData(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiRemoveDeviceInterface(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInterfaceDetailA(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, SP_DEVICE_INTERFACE_DETAIL_DATA_A* DeviceInterfaceDetailData, uint32 DeviceInterfaceDetailDataSize, uint32* RequiredSize, SP_DEVINFO_DATA* DeviceInfoData);
	public static BOOL SetupDiGetDeviceInterfaceDetail(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, SP_DEVICE_INTERFACE_DETAIL_DATA_A* DeviceInterfaceDetailData, uint32 DeviceInterfaceDetailDataSize, uint32* RequiredSize, SP_DEVINFO_DATA* DeviceInfoData) => SetupDiGetDeviceInterfaceDetailA(DeviceInfoSet, DeviceInterfaceData, DeviceInterfaceDetailData, DeviceInterfaceDetailDataSize, RequiredSize, DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInterfaceDetailW(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, SP_DEVICE_INTERFACE_DETAIL_DATA_W* DeviceInterfaceDetailData, uint32 DeviceInterfaceDetailDataSize, uint32* RequiredSize, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallDeviceInterfaces(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceInterfaceDefault(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Flags, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiRegisterDeviceInfo(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Flags, PSP_DETSIG_CMPPROC CompareProc, void* CompareContext, SP_DEVINFO_DATA* DupDeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiBuildDriverInfoList(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SETUP_DI_BUILD_DRIVER_DRIVER_TYPE DriverType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCancelDriverInfoSearch(HDEVINFO DeviceInfoSet);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiEnumDriverInfoA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 DriverType, uint32 MemberIndex, SP_DRVINFO_DATA_V2_A* DriverInfoData);
	public static BOOL SetupDiEnumDriverInfo(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 DriverType, uint32 MemberIndex, SP_DRVINFO_DATA_V2_A* DriverInfoData) => SetupDiEnumDriverInfoA(DeviceInfoSet, DeviceInfoData, DriverType, MemberIndex, DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiEnumDriverInfoW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 DriverType, uint32 MemberIndex, SP_DRVINFO_DATA_V2_W* DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetSelectedDriverA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData);
	public static BOOL SetupDiGetSelectedDriver(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData) => SetupDiGetSelectedDriverA(DeviceInfoSet, DeviceInfoData, DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetSelectedDriverW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_W* DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetSelectedDriverA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData);
	public static BOOL SetupDiSetSelectedDriver(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData) => SetupDiSetSelectedDriverA(DeviceInfoSet, DeviceInfoData, DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetSelectedDriverW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_W* DriverInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDriverInfoDetailA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINFO_DETAIL_DATA_A* DriverInfoDetailData, uint32 DriverInfoDetailDataSize, uint32* RequiredSize);
	public static BOOL SetupDiGetDriverInfoDetail(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINFO_DETAIL_DATA_A* DriverInfoDetailData, uint32 DriverInfoDetailDataSize, uint32* RequiredSize) => SetupDiGetDriverInfoDetailA(DeviceInfoSet, DeviceInfoData, DriverInfoData, DriverInfoDetailData, DriverInfoDetailDataSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDriverInfoDetailW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_W* DriverInfoData, SP_DRVINFO_DETAIL_DATA_W* DriverInfoDetailData, uint32 DriverInfoDetailDataSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDestroyDriverInfoList(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 DriverType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiGetClassDevsA(Guid* ClassGuid, PSTR Enumerator, HWND hwndParent, uint32 Flags);
	public static HDEVINFO SetupDiGetClassDevs(Guid* ClassGuid, PSTR Enumerator, HWND hwndParent, uint32 Flags) => SetupDiGetClassDevsA(ClassGuid, Enumerator, hwndParent, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiGetClassDevsW(Guid* ClassGuid, PWSTR Enumerator, HWND hwndParent, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiGetClassDevsExA(Guid* ClassGuid, PSTR Enumerator, HWND hwndParent, uint32 Flags, HDEVINFO DeviceInfoSet, PSTR MachineName, void* Reserved);
	public static HDEVINFO SetupDiGetClassDevsEx(Guid* ClassGuid, PSTR Enumerator, HWND hwndParent, uint32 Flags, HDEVINFO DeviceInfoSet, PSTR MachineName, void* Reserved) => SetupDiGetClassDevsExA(ClassGuid, Enumerator, hwndParent, Flags, DeviceInfoSet, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HDEVINFO SetupDiGetClassDevsExW(Guid* ClassGuid, PWSTR Enumerator, HWND hwndParent, uint32 Flags, HDEVINFO DeviceInfoSet, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetINFClassA(PSTR InfName, Guid* ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize);
	public static BOOL SetupDiGetINFClass(PSTR InfName, Guid* ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize) => SetupDiGetINFClassA(InfName, ClassGuid, ClassName, ClassNameSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetINFClassW(PWSTR InfName, Guid* ClassGuid, char16* ClassName, uint32 ClassNameSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiBuildClassInfoList(uint32 Flags, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiBuildClassInfoListExA(uint32 Flags, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiBuildClassInfoListEx(uint32 Flags, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiBuildClassInfoListExA(Flags, ClassGuidList, ClassGuidListSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiBuildClassInfoListExW(uint32 Flags, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDescriptionA(in Guid ClassGuid, uint8* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize);
	public static BOOL SetupDiGetClassDescription(in Guid ClassGuid, uint8* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize) => SetupDiGetClassDescriptionA(ClassGuid, ClassDescription, ClassDescriptionSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDescriptionW(in Guid ClassGuid, char16* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDescriptionExA(in Guid ClassGuid, uint8* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiGetClassDescriptionEx(in Guid ClassGuid, uint8* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiGetClassDescriptionExA(ClassGuid, ClassDescription, ClassDescriptionSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDescriptionExW(in Guid ClassGuid, char16* ClassDescription, uint32 ClassDescriptionSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiCallClassInstaller(uint32 InstallFunction, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSelectDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSelectBestCompatDrv(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallDriverFiles(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiRegisterCoDeviceInstallers(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiRemoveDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiUnremoveDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiRestartDevices(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiChangeState(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallClassA(HWND hwndParent, PSTR InfFileName, uint32 Flags, void* FileQueue);
	public static BOOL SetupDiInstallClass(HWND hwndParent, PSTR InfFileName, uint32 Flags, void* FileQueue) => SetupDiInstallClassA(hwndParent, InfFileName, Flags, FileQueue);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallClassW(HWND hwndParent, PWSTR InfFileName, uint32 Flags, void* FileQueue);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallClassExA(HWND hwndParent, PSTR InfFileName, uint32 Flags, void* FileQueue, Guid* InterfaceClassGuid, void* Reserved1, void* Reserved2);
	public static BOOL SetupDiInstallClassEx(HWND hwndParent, PSTR InfFileName, uint32 Flags, void* FileQueue, Guid* InterfaceClassGuid, void* Reserved1, void* Reserved2) => SetupDiInstallClassExA(hwndParent, InfFileName, Flags, FileQueue, InterfaceClassGuid, Reserved1, Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiInstallClassExW(HWND hwndParent, PWSTR InfFileName, uint32 Flags, void* FileQueue, Guid* InterfaceClassGuid, void* Reserved1, void* Reserved2);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiOpenClassRegKey(Guid* ClassGuid, uint32 samDesired);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiOpenClassRegKeyExA(Guid* ClassGuid, uint32 samDesired, uint32 Flags, PSTR MachineName, void* Reserved);
	public static HKEY SetupDiOpenClassRegKeyEx(Guid* ClassGuid, uint32 samDesired, uint32 Flags, PSTR MachineName, void* Reserved) => SetupDiOpenClassRegKeyExA(ClassGuid, samDesired, Flags, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiOpenClassRegKeyExW(Guid* ClassGuid, uint32 samDesired, uint32 Flags, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiCreateDeviceInterfaceRegKeyA(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Reserved, uint32 samDesired, void* InfHandle, PSTR InfSectionName);
	public static HKEY SetupDiCreateDeviceInterfaceRegKey(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Reserved, uint32 samDesired, void* InfHandle, PSTR InfSectionName) => SetupDiCreateDeviceInterfaceRegKeyA(DeviceInfoSet, DeviceInterfaceData, Reserved, samDesired, InfHandle, InfSectionName);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiCreateDeviceInterfaceRegKeyW(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Reserved, uint32 samDesired, void* InfHandle, PWSTR InfSectionName);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiOpenDeviceInterfaceRegKey(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Reserved, uint32 samDesired);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDeleteDeviceInterfaceRegKey(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, uint32 Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiCreateDevRegKeyA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Scope, uint32 HwProfile, uint32 KeyType, void* InfHandle, PSTR InfSectionName);
	public static HKEY SetupDiCreateDevRegKey(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Scope, uint32 HwProfile, uint32 KeyType, void* InfHandle, PSTR InfSectionName) => SetupDiCreateDevRegKeyA(DeviceInfoSet, DeviceInfoData, Scope, HwProfile, KeyType, InfHandle, InfSectionName);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiCreateDevRegKeyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Scope, uint32 HwProfile, uint32 KeyType, void* InfHandle, PWSTR InfSectionName);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SetupDiOpenDevRegKey(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Scope, uint32 HwProfile, uint32 KeyType, uint32 samDesired);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDeleteDevRegKey(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Scope, uint32 HwProfile, uint32 KeyType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileList(uint32* HwProfileList, uint32 HwProfileListSize, uint32* RequiredSize, uint32* CurrentlyActiveIndex);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileListExA(uint32* HwProfileList, uint32 HwProfileListSize, uint32* RequiredSize, uint32* CurrentlyActiveIndex, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiGetHwProfileListEx(uint32* HwProfileList, uint32 HwProfileListSize, uint32* RequiredSize, uint32* CurrentlyActiveIndex, PSTR MachineName, void* Reserved) => SetupDiGetHwProfileListExA(HwProfileList, HwProfileListSize, RequiredSize, CurrentlyActiveIndex, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileListExW(uint32* HwProfileList, uint32 HwProfileListSize, uint32* RequiredSize, uint32* CurrentlyActiveIndex, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDevicePropertyKeys(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, DEVPROPKEY* PropertyKeyArray, uint32 PropertyKeyCount, uint32* RequiredPropertyKeyCount, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDevicePropertyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDevicePropertyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInterfacePropertyKeys(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, DEVPROPKEY* PropertyKeyArray, uint32 PropertyKeyCount, uint32* RequiredPropertyKeyCount, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInterfacePropertyW(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceInterfacePropertyW(HDEVINFO DeviceInfoSet, SP_DEVICE_INTERFACE_DATA* DeviceInterfaceData, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassPropertyKeys(in Guid ClassGuid, DEVPROPKEY* PropertyKeyArray, uint32 PropertyKeyCount, uint32* RequiredPropertyKeyCount, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassPropertyKeysExW(in Guid ClassGuid, DEVPROPKEY* PropertyKeyArray, uint32 PropertyKeyCount, uint32* RequiredPropertyKeyCount, uint32 Flags, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassPropertyW(in Guid ClassGuid, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassPropertyExW(in Guid ClassGuid, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, uint32 Flags, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassPropertyW(in Guid ClassGuid, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassPropertyExW(in Guid ClassGuid, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 Flags, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceRegistryPropertyA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize);
	public static BOOL SetupDiGetDeviceRegistryProperty(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize) => SetupDiGetDeviceRegistryPropertyA(DeviceInfoSet, DeviceInfoData, Property, PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceRegistryPropertyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassRegistryPropertyA(in Guid ClassGuid, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiGetClassRegistryProperty(in Guid ClassGuid, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiGetClassRegistryPropertyA(ClassGuid, Property, PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassRegistryPropertyW(in Guid ClassGuid, uint32 Property, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceRegistryPropertyA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize);
	public static BOOL SetupDiSetDeviceRegistryProperty(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize) => SetupDiSetDeviceRegistryPropertyA(DeviceInfoSet, DeviceInfoData, Property, PropertyBuffer, PropertyBufferSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceRegistryPropertyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassRegistryPropertyA(in Guid ClassGuid, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiSetClassRegistryProperty(in Guid ClassGuid, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize, PSTR MachineName, void* Reserved) => SetupDiSetClassRegistryPropertyA(ClassGuid, Property, PropertyBuffer, PropertyBufferSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassRegistryPropertyW(in Guid ClassGuid, uint32 Property, uint8* PropertyBuffer, uint32 PropertyBufferSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_A* DeviceInstallParams);
	public static BOOL SetupDiGetDeviceInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_A* DeviceInstallParams) => SetupDiGetDeviceInstallParamsA(DeviceInfoSet, DeviceInfoData, DeviceInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDeviceInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_W* DeviceInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize, uint32* RequiredSize);
	public static BOOL SetupDiGetClassInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize, uint32* RequiredSize) => SetupDiGetClassInstallParamsA(DeviceInfoSet, DeviceInfoData, ClassInstallParams, ClassInstallParamsSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_A* DeviceInstallParams);
	public static BOOL SetupDiSetDeviceInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_A* DeviceInstallParams) => SetupDiSetDeviceInstallParamsA(DeviceInfoSet, DeviceInfoData, DeviceInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDeviceInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DEVINSTALL_PARAMS_W* DeviceInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize);
	public static BOOL SetupDiSetClassInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize) => SetupDiSetClassInstallParamsA(DeviceInfoSet, DeviceInfoData, ClassInstallParams, ClassInstallParamsSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetClassInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_CLASSINSTALL_HEADER* ClassInstallParams, uint32 ClassInstallParamsSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDriverInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams);
	public static BOOL SetupDiGetDriverInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams) => SetupDiGetDriverInstallParamsA(DeviceInfoSet, DeviceInfoData, DriverInfoData, DriverInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetDriverInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_W* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDriverInstallParamsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams);
	public static BOOL SetupDiSetDriverInstallParams(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams) => SetupDiSetDriverInstallParamsA(DeviceInfoSet, DeviceInfoData, DriverInfoData, DriverInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetDriverInstallParamsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_W* DriverInfoData, SP_DRVINSTALL_PARAMS* DriverInstallParams);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiLoadClassIcon(in Guid ClassGuid, HICON* LargeIcon, int32* MiniIconIndex);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiLoadDeviceIcon(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 cxIcon, uint32 cyIcon, uint32 Flags, HICON* hIcon);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SetupDiDrawMiniIcon(HDC hdc, RECT rc, int32 MiniIconIndex, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassBitmapIndex(Guid* ClassGuid, int32* MiniIconIndex);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassImageList(SP_CLASSIMAGELIST_DATA* ClassImageListData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassImageListExA(SP_CLASSIMAGELIST_DATA* ClassImageListData, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiGetClassImageListEx(SP_CLASSIMAGELIST_DATA* ClassImageListData, PSTR MachineName, void* Reserved) => SetupDiGetClassImageListExA(ClassImageListData, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassImageListExW(SP_CLASSIMAGELIST_DATA* ClassImageListData, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassImageIndex(SP_CLASSIMAGELIST_DATA* ClassImageListData, in Guid ClassGuid, int32* ImageIndex);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiDestroyClassImageList(SP_CLASSIMAGELIST_DATA* ClassImageListData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDevPropertySheetsA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PROPSHEETHEADERA_V2* PropertySheetHeader, uint32 PropertySheetHeaderPageListSize, uint32* RequiredSize, uint32 PropertySheetType);
	public static BOOL SetupDiGetClassDevPropertySheets(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PROPSHEETHEADERA_V2* PropertySheetHeader, uint32 PropertySheetHeaderPageListSize, uint32* RequiredSize, uint32 PropertySheetType) => SetupDiGetClassDevPropertySheetsA(DeviceInfoSet, DeviceInfoData, PropertySheetHeader, PropertySheetHeaderPageListSize, RequiredSize, PropertySheetType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetClassDevPropertySheetsW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PROPSHEETHEADERW_V2* PropertySheetHeader, uint32 PropertySheetHeaderPageListSize, uint32* RequiredSize, uint32 PropertySheetType);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiAskForOEMDisk(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSelectOEMDrv(HWND hwndParent, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassNameFromGuidA(in Guid ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize);
	public static BOOL SetupDiClassNameFromGuid(in Guid ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize) => SetupDiClassNameFromGuidA(ClassGuid, ClassName, ClassNameSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassNameFromGuidW(in Guid ClassGuid, char16* ClassName, uint32 ClassNameSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassNameFromGuidExA(in Guid ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiClassNameFromGuidEx(in Guid ClassGuid, uint8* ClassName, uint32 ClassNameSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiClassNameFromGuidExA(ClassGuid, ClassName, ClassNameSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassNameFromGuidExW(in Guid ClassGuid, char16* ClassName, uint32 ClassNameSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassGuidsFromNameA(PSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize);
	public static BOOL SetupDiClassGuidsFromName(PSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize) => SetupDiClassGuidsFromNameA(ClassName, ClassGuidList, ClassGuidListSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassGuidsFromNameW(PWSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassGuidsFromNameExA(PSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiClassGuidsFromNameEx(PSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiClassGuidsFromNameExA(ClassName, ClassGuidList, ClassGuidListSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiClassGuidsFromNameExW(PWSTR ClassName, Guid* ClassGuidList, uint32 ClassGuidListSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileFriendlyNameA(uint32 HwProfile, uint8* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize);
	public static BOOL SetupDiGetHwProfileFriendlyName(uint32 HwProfile, uint8* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize) => SetupDiGetHwProfileFriendlyNameA(HwProfile, FriendlyName, FriendlyNameSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileFriendlyNameW(uint32 HwProfile, char16* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileFriendlyNameExA(uint32 HwProfile, uint8* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize, PSTR MachineName, void* Reserved);
	public static BOOL SetupDiGetHwProfileFriendlyNameEx(uint32 HwProfile, uint8* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize, PSTR MachineName, void* Reserved) => SetupDiGetHwProfileFriendlyNameExA(HwProfile, FriendlyName, FriendlyNameSize, RequiredSize, MachineName, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetHwProfileFriendlyNameExW(uint32 HwProfile, char16* FriendlyName, uint32 FriendlyNameSize, uint32* RequiredSize, PWSTR MachineName, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPROPSHEETPAGE SetupDiGetWizardPage(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_INSTALLWIZARD_DATA* InstallWizardData, uint32 PageType, uint32 Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetSelectedDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiSetSelectedDevice(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualModelsSectionA(INFCONTEXT* Context, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, void* Reserved);
	public static BOOL SetupDiGetActualModelsSection(INFCONTEXT* Context, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, void* Reserved) => SetupDiGetActualModelsSectionA(Context, AlternatePlatformInfo, InfSectionWithExt, InfSectionWithExtSize, RequiredSize, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualModelsSectionW(INFCONTEXT* Context, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, char16* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualSectionToInstallA(void* InfHandle, PSTR InfSectionName, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PSTR* Extension);
	public static BOOL SetupDiGetActualSectionToInstall(void* InfHandle, PSTR InfSectionName, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PSTR* Extension) => SetupDiGetActualSectionToInstallA(InfHandle, InfSectionName, InfSectionWithExt, InfSectionWithExtSize, RequiredSize, Extension);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualSectionToInstallW(void* InfHandle, PWSTR InfSectionName, char16* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PWSTR* Extension);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualSectionToInstallExA(void* InfHandle, PSTR InfSectionName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PSTR* Extension, void* Reserved);
	public static BOOL SetupDiGetActualSectionToInstallEx(void* InfHandle, PSTR InfSectionName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, uint8* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PSTR* Extension, void* Reserved) => SetupDiGetActualSectionToInstallExA(InfHandle, InfSectionName, AlternatePlatformInfo, InfSectionWithExt, InfSectionWithExtSize, RequiredSize, Extension, Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetActualSectionToInstallExW(void* InfHandle, PWSTR InfSectionName, SP_ALTPLATFORM_INFO_V2* AlternatePlatformInfo, char16* InfSectionWithExt, uint32 InfSectionWithExtSize, uint32* RequiredSize, PWSTR* Extension, void* Reserved);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupEnumInfSectionsA(void* InfHandle, uint32 Index, uint8* Buffer, uint32 Size, uint32* SizeNeeded);
	public static BOOL SetupEnumInfSections(void* InfHandle, uint32 Index, uint8* Buffer, uint32 Size, uint32* SizeNeeded) => SetupEnumInfSectionsA(InfHandle, Index, Buffer, Size, SizeNeeded);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupEnumInfSectionsW(void* InfHandle, uint32 Index, char16* Buffer, uint32 Size, uint32* SizeNeeded);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupVerifyInfFileA(PSTR InfName, SP_ALTPLATFORM_INFO_V2* AltPlatformInfo, SP_INF_SIGNER_INFO_V2_A* InfSignerInfo);
	public static BOOL SetupVerifyInfFile(PSTR InfName, SP_ALTPLATFORM_INFO_V2* AltPlatformInfo, SP_INF_SIGNER_INFO_V2_A* InfSignerInfo) => SetupVerifyInfFileA(InfName, AltPlatformInfo, InfSignerInfo);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupVerifyInfFileW(PWSTR InfName, SP_ALTPLATFORM_INFO_V2* AltPlatformInfo, SP_INF_SIGNER_INFO_V2_W* InfSignerInfo);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetCustomDevicePropertyA(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PSTR CustomPropertyName, uint32 Flags, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize);
	public static BOOL SetupDiGetCustomDeviceProperty(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PSTR CustomPropertyName, uint32 Flags, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize) => SetupDiGetCustomDevicePropertyA(DeviceInfoSet, DeviceInfoData, CustomPropertyName, Flags, PropertyRegDataType, PropertyBuffer, PropertyBufferSize, RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupDiGetCustomDevicePropertyW(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, PWSTR CustomPropertyName, uint32 Flags, uint32* PropertyRegDataType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32* RequiredSize);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupConfigureWmiFromInfSectionA(void* InfHandle, PSTR SectionName, uint32 Flags);
	public static BOOL SetupConfigureWmiFromInfSection(void* InfHandle, PSTR SectionName, uint32 Flags) => SetupConfigureWmiFromInfSectionA(InfHandle, SectionName, Flags);

	[Import("SETUPAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetupConfigureWmiFromInfSectionW(void* InfHandle, PWSTR SectionName, uint32 Flags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_Empty_Log_Conf(uint* plcLogConf, uint32 dnDevInst, PRIORITY Priority, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_Empty_Log_Conf_Ex(uint* plcLogConf, uint32 dnDevInst, PRIORITY Priority, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_IDA(uint32 dnDevInst, PSTR pszID, uint32 ulFlags);
	public static CONFIGRET CM_Add_ID(uint32 dnDevInst, PSTR pszID, uint32 ulFlags) => CM_Add_IDA(dnDevInst, pszID, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_IDW(uint32 dnDevInst, PWSTR pszID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_ID_ExA(uint32 dnDevInst, PSTR pszID, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Add_ID_Ex(uint32 dnDevInst, PSTR pszID, uint32 ulFlags, int hMachine) => CM_Add_ID_ExA(dnDevInst, pszID, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_ID_ExW(uint32 dnDevInst, PWSTR pszID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_Range(uint64 ullStartValue, uint64 ullEndValue, uint rlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_Res_Des(uint* prdResDes, uint lcLogConf, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Add_Res_Des_Ex(uint* prdResDes, uint lcLogConf, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Connect_MachineA(PSTR UNCServerName, int* phMachine);
	public static CONFIGRET CM_Connect_Machine(PSTR UNCServerName, int* phMachine) => CM_Connect_MachineA(UNCServerName, phMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Connect_MachineW(PWSTR UNCServerName, int* phMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Create_DevNodeA(uint32* pdnDevInst, PSTR pDeviceID, uint32 dnParent, uint32 ulFlags);
	public static CONFIGRET CM_Create_DevNode(uint32* pdnDevInst, PSTR pDeviceID, uint32 dnParent, uint32 ulFlags) => CM_Create_DevNodeA(pdnDevInst, pDeviceID, dnParent, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Create_DevNodeW(uint32* pdnDevInst, PWSTR pDeviceID, uint32 dnParent, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Create_DevNode_ExA(uint32* pdnDevInst, PSTR pDeviceID, uint32 dnParent, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Create_DevNode_Ex(uint32* pdnDevInst, PSTR pDeviceID, uint32 dnParent, uint32 ulFlags, int hMachine) => CM_Create_DevNode_ExA(pdnDevInst, pDeviceID, dnParent, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Create_DevNode_ExW(uint32* pdnDevInst, PWSTR pDeviceID, uint32 dnParent, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Create_Range_List(uint* prlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Class_Key(Guid* ClassGuid, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Class_Key_Ex(Guid* ClassGuid, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_DevNode_Key(uint32 dnDevNode, uint32 ulHardwareProfile, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_DevNode_Key_Ex(uint32 dnDevNode, uint32 ulHardwareProfile, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Range(uint64 ullStartValue, uint64 ullEndValue, uint rlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Detect_Resource_Conflict(uint32 dnDevInst, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, BOOL* pbConflictDetected, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Detect_Resource_Conflict_Ex(uint32 dnDevInst, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, BOOL* pbConflictDetected, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Disable_DevNode(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Disable_DevNode_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Disconnect_Machine(int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Dup_Range_List(uint rlhOld, uint rlhNew, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enable_DevNode(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enable_DevNode_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_Classes(uint32 ulClassIndex, Guid* ClassGuid, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_Classes_Ex(uint32 ulClassIndex, Guid* ClassGuid, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_EnumeratorsA(uint32 ulEnumIndex, uint8* Buffer, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Enumerate_Enumerators(uint32 ulEnumIndex, uint8* Buffer, uint32* pulLength, uint32 ulFlags) => CM_Enumerate_EnumeratorsA(ulEnumIndex, Buffer, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_EnumeratorsW(uint32 ulEnumIndex, char16* Buffer, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_Enumerators_ExA(uint32 ulEnumIndex, uint8* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Enumerate_Enumerators_Ex(uint32 ulEnumIndex, uint8* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Enumerate_Enumerators_ExA(ulEnumIndex, Buffer, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Enumerate_Enumerators_ExW(uint32 ulEnumIndex, char16* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Find_Range(uint64* pullStart, uint64 ullStart, uint32 ulLength, uint64 ullAlignment, uint64 ullEnd, uint rlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_First_Range(uint rlh, uint64* pullStart, uint64* pullEnd, uint* preElement, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Log_Conf(uint lcLogConfToBeFreed, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Log_Conf_Ex(uint lcLogConfToBeFreed, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Log_Conf_Handle(uint lcLogConf);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Range_List(uint rlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Res_Des(uint* prdResDes, uint rdResDes, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Res_Des_Ex(uint* prdResDes, uint rdResDes, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Res_Des_Handle(uint rdResDes);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Child(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Child_Ex(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_NameA(Guid* ClassGuid, uint8* Buffer, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Get_Class_Name(Guid* ClassGuid, uint8* Buffer, uint32* pulLength, uint32 ulFlags) => CM_Get_Class_NameA(ClassGuid, Buffer, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_NameW(Guid* ClassGuid, char16* Buffer, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Name_ExA(Guid* ClassGuid, uint8* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Class_Name_Ex(Guid* ClassGuid, uint8* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_Class_Name_ExA(ClassGuid, Buffer, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Name_ExW(Guid* ClassGuid, char16* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Key_NameA(Guid* ClassGuid, uint8* pszKeyName, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Get_Class_Key_Name(Guid* ClassGuid, uint8* pszKeyName, uint32* pulLength, uint32 ulFlags) => CM_Get_Class_Key_NameA(ClassGuid, pszKeyName, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Key_NameW(Guid* ClassGuid, char16* pszKeyName, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Key_Name_ExA(Guid* ClassGuid, uint8* pszKeyName, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Class_Key_Name_Ex(Guid* ClassGuid, uint8* pszKeyName, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_Class_Key_Name_ExA(ClassGuid, pszKeyName, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Key_Name_ExW(Guid* ClassGuid, char16* pszKeyName, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Depth(uint32* pulDepth, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Depth_Ex(uint32* pulDepth, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_IDA(uint32 dnDevInst, uint8* Buffer, uint32 BufferLen, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_ID(uint32 dnDevInst, uint8* Buffer, uint32 BufferLen, uint32 ulFlags) => CM_Get_Device_IDA(dnDevInst, Buffer, BufferLen, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_IDW(uint32 dnDevInst, char16* Buffer, uint32 BufferLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_ExA(uint32 dnDevInst, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_ID_Ex(uint32 dnDevInst, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine) => CM_Get_Device_ID_ExA(dnDevInst, Buffer, BufferLen, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_ExW(uint32 dnDevInst, char16* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_ListA(PSTR pszFilter, uint8* Buffer, uint32 BufferLen, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_ID_List(PSTR pszFilter, uint8* Buffer, uint32 BufferLen, uint32 ulFlags) => CM_Get_Device_ID_ListA(pszFilter, Buffer, BufferLen, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_ListW(PWSTR pszFilter, char16* Buffer, uint32 BufferLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_ExA(PSTR pszFilter, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_ID_List_Ex(PSTR pszFilter, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine) => CM_Get_Device_ID_List_ExA(pszFilter, Buffer, BufferLen, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_ExW(PWSTR pszFilter, char16* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_SizeA(uint32* pulLen, PSTR pszFilter, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_ID_List_Size(uint32* pulLen, PSTR pszFilter, uint32 ulFlags) => CM_Get_Device_ID_List_SizeA(pulLen, pszFilter, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_SizeW(uint32* pulLen, PWSTR pszFilter, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_Size_ExA(uint32* pulLen, PSTR pszFilter, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_ID_List_Size_Ex(uint32* pulLen, PSTR pszFilter, uint32 ulFlags, int hMachine) => CM_Get_Device_ID_List_Size_ExA(pulLen, pszFilter, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_List_Size_ExW(uint32* pulLen, PWSTR pszFilter, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_Size(uint32* pulLen, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_ID_Size_Ex(uint32* pulLen, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_PropertyW(uint32 dnDevInst, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Property_ExW(uint32 dnDevInst, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Property_Keys(uint32 dnDevInst, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Property_Keys_Ex(uint32 dnDevInst, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Registry_PropertyA(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Get_DevNode_Registry_Property(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags) => CM_Get_DevNode_Registry_PropertyA(dnDevInst, ulProperty, pulRegDataType, Buffer, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Registry_PropertyW(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Registry_Property_ExA(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_DevNode_Registry_Property_Ex(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_DevNode_Registry_Property_ExA(dnDevInst, ulProperty, pulRegDataType, Buffer, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Registry_Property_ExW(uint32 dnDevInst, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Custom_PropertyA(uint32 dnDevInst, PSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Get_DevNode_Custom_Property(uint32 dnDevInst, PSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags) => CM_Get_DevNode_Custom_PropertyA(dnDevInst, pszCustomPropertyName, pulRegDataType, Buffer, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Custom_PropertyW(uint32 dnDevInst, PWSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Custom_Property_ExA(uint32 dnDevInst, PSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_DevNode_Custom_Property_Ex(uint32 dnDevInst, PSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_DevNode_Custom_Property_ExA(dnDevInst, pszCustomPropertyName, pulRegDataType, Buffer, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Custom_Property_ExW(uint32 dnDevInst, PWSTR pszCustomPropertyName, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Status(uint32* pulStatus, uint32* pulProblemNumber, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_DevNode_Status_Ex(uint32* pulStatus, uint32* pulProblemNumber, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_First_Log_Conf(uint* plcLogConf, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_First_Log_Conf_Ex(uint* plcLogConf, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Global_State(uint32* pulState, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Global_State_Ex(uint32* pulState, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Hardware_Profile_InfoA(uint32 ulIndex, HWProfileInfo_sA* pHWProfileInfo, uint32 ulFlags);
	public static CONFIGRET CM_Get_Hardware_Profile_Info(uint32 ulIndex, HWProfileInfo_sA* pHWProfileInfo, uint32 ulFlags) => CM_Get_Hardware_Profile_InfoA(ulIndex, pHWProfileInfo, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Hardware_Profile_Info_ExA(uint32 ulIndex, HWProfileInfo_sA* pHWProfileInfo, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Hardware_Profile_Info_Ex(uint32 ulIndex, HWProfileInfo_sA* pHWProfileInfo, uint32 ulFlags, int hMachine) => CM_Get_Hardware_Profile_Info_ExA(ulIndex, pHWProfileInfo, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Hardware_Profile_InfoW(uint32 ulIndex, HWPROFILEINFO_W* pHWProfileInfo, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Hardware_Profile_Info_ExW(uint32 ulIndex, HWPROFILEINFO_W* pHWProfileInfo, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_HW_Prof_FlagsA(PSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags);
	public static CONFIGRET CM_Get_HW_Prof_Flags(PSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags) => CM_Get_HW_Prof_FlagsA(pDeviceID, ulHardwareProfile, pulValue, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_HW_Prof_FlagsW(PWSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_HW_Prof_Flags_ExA(PSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_HW_Prof_Flags_Ex(PSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags, int hMachine) => CM_Get_HW_Prof_Flags_ExA(pDeviceID, ulHardwareProfile, pulValue, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_HW_Prof_Flags_ExW(PWSTR pDeviceID, uint32 ulHardwareProfile, uint32* pulValue, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_AliasA(PSTR pszDeviceInterface, Guid* AliasInterfaceGuid, uint8* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_Interface_Alias(PSTR pszDeviceInterface, Guid* AliasInterfaceGuid, uint8* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags) => CM_Get_Device_Interface_AliasA(pszDeviceInterface, AliasInterfaceGuid, pszAliasDeviceInterface, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_AliasW(PWSTR pszDeviceInterface, Guid* AliasInterfaceGuid, char16* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_Alias_ExA(PSTR pszDeviceInterface, Guid* AliasInterfaceGuid, uint8* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_Interface_Alias_Ex(PSTR pszDeviceInterface, Guid* AliasInterfaceGuid, uint8* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_Device_Interface_Alias_ExA(pszDeviceInterface, AliasInterfaceGuid, pszAliasDeviceInterface, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_Alias_ExW(PWSTR pszDeviceInterface, Guid* AliasInterfaceGuid, char16* pszAliasDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_ListA(Guid* InterfaceClassGuid, PSTR pDeviceID, uint8* Buffer, uint32 BufferLen, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_Interface_List(Guid* InterfaceClassGuid, PSTR pDeviceID, uint8* Buffer, uint32 BufferLen, uint32 ulFlags) => CM_Get_Device_Interface_ListA(InterfaceClassGuid, pDeviceID, Buffer, BufferLen, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_ListW(Guid* InterfaceClassGuid, PWSTR pDeviceID, char16* Buffer, uint32 BufferLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_ExA(Guid* InterfaceClassGuid, PSTR pDeviceID, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_Interface_List_Ex(Guid* InterfaceClassGuid, PSTR pDeviceID, uint8* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine) => CM_Get_Device_Interface_List_ExA(InterfaceClassGuid, pDeviceID, Buffer, BufferLen, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_ExW(Guid* InterfaceClassGuid, PWSTR pDeviceID, char16* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_SizeA(uint32* pulLen, Guid* InterfaceClassGuid, PSTR pDeviceID, uint32 ulFlags);
	public static CONFIGRET CM_Get_Device_Interface_List_Size(uint32* pulLen, Guid* InterfaceClassGuid, PSTR pDeviceID, uint32 ulFlags) => CM_Get_Device_Interface_List_SizeA(pulLen, InterfaceClassGuid, pDeviceID, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_SizeW(uint32* pulLen, Guid* InterfaceClassGuid, PWSTR pDeviceID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_Size_ExA(uint32* pulLen, Guid* InterfaceClassGuid, PSTR pDeviceID, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Device_Interface_List_Size_Ex(uint32* pulLen, Guid* InterfaceClassGuid, PSTR pDeviceID, uint32 ulFlags, int hMachine) => CM_Get_Device_Interface_List_Size_ExA(pulLen, InterfaceClassGuid, pDeviceID, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_List_Size_ExW(uint32* pulLen, Guid* InterfaceClassGuid, PWSTR pDeviceID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_PropertyW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_Property_ExW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_Property_KeysW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Device_Interface_Property_Keys_ExW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Log_Conf_Priority(uint lcLogConf, uint32* pPriority, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Log_Conf_Priority_Ex(uint lcLogConf, uint32* pPriority, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Next_Log_Conf(uint* plcLogConf, uint lcLogConf, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Next_Log_Conf_Ex(uint* plcLogConf, uint lcLogConf, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Parent(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Parent_Ex(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Res_Des_Data(uint rdResDes, void* Buffer, uint32 BufferLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Res_Des_Data_Ex(uint rdResDes, void* Buffer, uint32 BufferLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Res_Des_Data_Size(uint32* pulSize, uint rdResDes, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Res_Des_Data_Size_Ex(uint32* pulSize, uint rdResDes, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Sibling(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Sibling_Ex(uint32* pdnDevInst, uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 CM_Get_Version();

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint16 CM_Get_Version_Ex(int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CM_Is_Version_Available(uint16 wVersion);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL CM_Is_Version_Available_Ex(uint16 wVersion, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Intersect_Range_List(uint rlhOld1, uint rlhOld2, uint rlhNew, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Invert_Range_List(uint rlhOld, uint rlhNew, uint64 ullMaxValue, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Locate_DevNodeA(uint32* pdnDevInst, PSTR pDeviceID, uint32 ulFlags);
	public static CONFIGRET CM_Locate_DevNode(uint32* pdnDevInst, PSTR pDeviceID, uint32 ulFlags) => CM_Locate_DevNodeA(pdnDevInst, pDeviceID, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Locate_DevNodeW(uint32* pdnDevInst, PWSTR pDeviceID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Locate_DevNode_ExA(uint32* pdnDevInst, PSTR pDeviceID, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Locate_DevNode_Ex(uint32* pdnDevInst, PSTR pDeviceID, uint32 ulFlags, int hMachine) => CM_Locate_DevNode_ExA(pdnDevInst, pDeviceID, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Locate_DevNode_ExW(uint32* pdnDevInst, PWSTR pDeviceID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Merge_Range_List(uint rlhOld1, uint rlhOld2, uint rlhNew, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Modify_Res_Des(uint* prdResDes, uint rdResDes, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Modify_Res_Des_Ex(uint* prdResDes, uint rdResDes, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Move_DevNode(uint32 dnFromDevInst, uint32 dnToDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Move_DevNode_Ex(uint32 dnFromDevInst, uint32 dnToDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Next_Range(uint* preElement, uint64* pullStart, uint64* pullEnd, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Next_Res_Des(uint* prdResDes, uint rdResDes, uint32 ForResource, uint32* pResourceID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Next_Res_Des_Ex(uint* prdResDes, uint rdResDes, uint32 ForResource, uint32* pResourceID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Class_KeyA(Guid* ClassGuid, PSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags);
	public static CONFIGRET CM_Open_Class_Key(Guid* ClassGuid, PSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags) => CM_Open_Class_KeyA(ClassGuid, pszClassName, samDesired, Disposition, phkClass, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Class_KeyW(Guid* ClassGuid, PWSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Class_Key_ExA(Guid* ClassGuid, PSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Open_Class_Key_Ex(Guid* ClassGuid, PSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags, int hMachine) => CM_Open_Class_Key_ExA(ClassGuid, pszClassName, samDesired, Disposition, phkClass, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Class_Key_ExW(Guid* ClassGuid, PWSTR pszClassName, uint32 samDesired, uint32 Disposition, HKEY* phkClass, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_DevNode_Key(uint32 dnDevNode, uint32 samDesired, uint32 ulHardwareProfile, uint32 Disposition, HKEY* phkDevice, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_DevNode_Key_Ex(uint32 dnDevNode, uint32 samDesired, uint32 ulHardwareProfile, uint32 Disposition, HKEY* phkDevice, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Device_Interface_KeyA(PSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags);
	public static CONFIGRET CM_Open_Device_Interface_Key(PSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags) => CM_Open_Device_Interface_KeyA(pszDeviceInterface, samDesired, Disposition, phkDeviceInterface, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Device_Interface_KeyW(PWSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Device_Interface_Key_ExA(PSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Open_Device_Interface_Key_Ex(PSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags, int hMachine) => CM_Open_Device_Interface_Key_ExA(pszDeviceInterface, samDesired, Disposition, phkDeviceInterface, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Open_Device_Interface_Key_ExW(PWSTR pszDeviceInterface, uint32 samDesired, uint32 Disposition, HKEY* phkDeviceInterface, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Device_Interface_KeyA(PSTR pszDeviceInterface, uint32 ulFlags);
	public static CONFIGRET CM_Delete_Device_Interface_Key(PSTR pszDeviceInterface, uint32 ulFlags) => CM_Delete_Device_Interface_KeyA(pszDeviceInterface, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Device_Interface_KeyW(PWSTR pszDeviceInterface, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Device_Interface_Key_ExA(PSTR pszDeviceInterface, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Delete_Device_Interface_Key_Ex(PSTR pszDeviceInterface, uint32 ulFlags, int hMachine) => CM_Delete_Device_Interface_Key_ExA(pszDeviceInterface, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Delete_Device_Interface_Key_ExW(PWSTR pszDeviceInterface, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Arbitrator_Free_Data(void* pData, uint32 DataLen, uint32 dnDevInst, uint32 ResourceID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Arbitrator_Free_Data_Ex(void* pData, uint32 DataLen, uint32 dnDevInst, uint32 ResourceID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Arbitrator_Free_Size(uint32* pulSize, uint32 dnDevInst, uint32 ResourceID, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Arbitrator_Free_Size_Ex(uint32* pulSize, uint32 dnDevInst, uint32 ResourceID, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Remove_SubTree(uint32 dnAncestor, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Remove_SubTree_Ex(uint32 dnAncestor, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_And_Remove_SubTreeA(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags);
	public static CONFIGRET CM_Query_And_Remove_SubTree(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags) => CM_Query_And_Remove_SubTreeA(dnAncestor, pVetoType, pszVetoName, ulNameLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_And_Remove_SubTreeW(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, char16* pszVetoName, uint32 ulNameLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_And_Remove_SubTree_ExA(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Query_And_Remove_SubTree_Ex(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine) => CM_Query_And_Remove_SubTree_ExA(dnAncestor, pVetoType, pszVetoName, ulNameLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_And_Remove_SubTree_ExW(uint32 dnAncestor, PNP_VETO_TYPE* pVetoType, char16* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Device_EjectA(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags);
	public static CONFIGRET CM_Request_Device_Eject(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags) => CM_Request_Device_EjectA(dnDevInst, pVetoType, pszVetoName, ulNameLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Device_Eject_ExA(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Request_Device_Eject_Ex(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, uint8* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine) => CM_Request_Device_Eject_ExA(dnDevInst, pVetoType, pszVetoName, ulNameLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Device_EjectW(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, char16* pszVetoName, uint32 ulNameLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Device_Eject_ExW(uint32 dnDevInst, PNP_VETO_TYPE* pVetoType, char16* pszVetoName, uint32 ulNameLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Reenumerate_DevNode(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Reenumerate_DevNode_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_InterfaceA(uint32 dnDevInst, Guid* InterfaceClassGuid, PSTR pszReference, uint8* pszDeviceInterface, uint32* pulLength, uint32 ulFlags);
	public static CONFIGRET CM_Register_Device_Interface(uint32 dnDevInst, Guid* InterfaceClassGuid, PSTR pszReference, uint8* pszDeviceInterface, uint32* pulLength, uint32 ulFlags) => CM_Register_Device_InterfaceA(dnDevInst, InterfaceClassGuid, pszReference, pszDeviceInterface, pulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_InterfaceW(uint32 dnDevInst, Guid* InterfaceClassGuid, PWSTR pszReference, char16* pszDeviceInterface, uint32* pulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_Interface_ExA(uint32 dnDevInst, Guid* InterfaceClassGuid, PSTR pszReference, uint8* pszDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Register_Device_Interface_Ex(uint32 dnDevInst, Guid* InterfaceClassGuid, PSTR pszReference, uint8* pszDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Register_Device_Interface_ExA(dnDevInst, InterfaceClassGuid, pszReference, pszDeviceInterface, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_Interface_ExW(uint32 dnDevInst, Guid* InterfaceClassGuid, PWSTR pszReference, char16* pszDeviceInterface, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Problem_Ex(uint32 dnDevInst, uint32 ulProblem, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Problem(uint32 dnDevInst, uint32 ulProblem, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Unregister_Device_InterfaceA(PSTR pszDeviceInterface, uint32 ulFlags);
	public static CONFIGRET CM_Unregister_Device_Interface(PSTR pszDeviceInterface, uint32 ulFlags) => CM_Unregister_Device_InterfaceA(pszDeviceInterface, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Unregister_Device_InterfaceW(PWSTR pszDeviceInterface, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Unregister_Device_Interface_ExA(PSTR pszDeviceInterface, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Unregister_Device_Interface_Ex(PSTR pszDeviceInterface, uint32 ulFlags, int hMachine) => CM_Unregister_Device_Interface_ExA(pszDeviceInterface, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Unregister_Device_Interface_ExW(PWSTR pszDeviceInterface, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_Driver(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Device_Driver_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Remove_SubTree(uint32 dnAncestor, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Remove_SubTree_Ex(uint32 dnAncestor, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_PropertyW(uint32 dnDevInst, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Property_ExW(uint32 dnDevInst, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Registry_PropertyA(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags);
	public static CONFIGRET CM_Set_DevNode_Registry_Property(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags) => CM_Set_DevNode_Registry_PropertyA(dnDevInst, ulProperty, Buffer, ulLength, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Registry_PropertyW(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Registry_Property_ExA(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Set_DevNode_Registry_Property_Ex(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine) => CM_Set_DevNode_Registry_Property_ExA(dnDevInst, ulProperty, Buffer, ulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_DevNode_Registry_Property_ExW(uint32 dnDevInst, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Device_Interface_PropertyW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Device_Interface_Property_ExW(PWSTR pszDeviceInterface, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Is_Dock_Station_Present(BOOL* pbPresent);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Is_Dock_Station_Present_Ex(BOOL* pbPresent, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Eject_PC();

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Request_Eject_PC_Ex(int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof_FlagsA(PSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags);
	public static CONFIGRET CM_Set_HW_Prof_Flags(PSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags) => CM_Set_HW_Prof_FlagsA(pDeviceID, ulConfig, ulValue, ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof_FlagsW(PWSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof_Flags_ExA(PSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Set_HW_Prof_Flags_Ex(PSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags, int hMachine) => CM_Set_HW_Prof_Flags_ExA(pDeviceID, ulConfig, ulValue, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof_Flags_ExW(PWSTR pDeviceID, uint32 ulConfig, uint32 ulValue, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Setup_DevNode(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Setup_DevNode_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Test_Range_Available(uint64 ullStartValue, uint64 ullEndValue, uint rlh, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Uninstall_DevNode(uint32 dnDevInst, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Uninstall_DevNode_Ex(uint32 dnDevInst, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Run_Detection(uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Run_Detection_Ex(uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof(uint32 ulHardwareProfile, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_HW_Prof_Ex(uint32 ulHardwareProfile, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Query_Resource_Conflict_List(uint* pclConflictList, uint32 dnDevInst, uint32 ResourceID, void* ResourceData, uint32 ResourceLen, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Free_Resource_Conflict_Handle(uint clConflictList);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Resource_Conflict_Count(uint clConflictList, uint32* pulCount);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Resource_Conflict_DetailsA(uint clConflictList, uint32 ulIndex, CONFLICT_DETAILS_A* pConflictDetails);
	public static CONFIGRET CM_Get_Resource_Conflict_Details(uint clConflictList, uint32 ulIndex, CONFLICT_DETAILS_A* pConflictDetails) => CM_Get_Resource_Conflict_DetailsA(clConflictList, ulIndex, pConflictDetails);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Resource_Conflict_DetailsW(uint clConflictList, uint32 ulIndex, CONFLICT_DETAILS_W* pConflictDetails);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_PropertyW(in Guid ClassGUID, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Property_ExW(in Guid ClassGUID, DEVPROPKEY* PropertyKey, uint32* PropertyType, uint8* PropertyBuffer, uint32* PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Property_Keys(in Guid ClassGUID, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Property_Keys_Ex(in Guid ClassGUID, DEVPROPKEY* PropertyKeyArray, uint32* PropertyKeyCount, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Class_PropertyW(in Guid ClassGUID, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Class_Property_ExW(in Guid ClassGUID, DEVPROPKEY* PropertyKey, uint32 PropertyType, uint8* PropertyBuffer, uint32 PropertyBufferSize, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Registry_PropertyA(Guid* ClassGuid, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Get_Class_Registry_Property(Guid* ClassGuid, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine) => CM_Get_Class_Registry_PropertyA(ClassGuid, ulProperty, pulRegDataType, Buffer, pulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Get_Class_Registry_PropertyW(Guid* ClassGuid, uint32 ulProperty, uint32* pulRegDataType, void* Buffer, uint32* pulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Class_Registry_PropertyA(Guid* ClassGuid, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine);
	public static CONFIGRET CM_Set_Class_Registry_Property(Guid* ClassGuid, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine) => CM_Set_Class_Registry_PropertyA(ClassGuid, ulProperty, Buffer, ulLength, ulFlags, hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Set_Class_Registry_PropertyW(Guid* ClassGuid, uint32 ulProperty, void* Buffer, uint32 ulLength, uint32 ulFlags, int hMachine);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CMP_WaitNoPendingInstallEvents(uint32 dwTimeout);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Register_Notification(CM_NOTIFY_FILTER* pFilter, void* pContext, PCM_NOTIFY_CALLBACK pCallback, int* pNotifyContext);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CONFIGRET CM_Unregister_Notification(HCMNOTIFICATION NotifyContext);

	[Import("CFGMGR32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 CM_MapCrToWin32Err(CONFIGRET CmReturnCode, uint32 DefaultErr);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateDriverForPlugAndPlayDevicesA(HWND hwndParent, PSTR HardwareId, PSTR FullInfPath, uint32 InstallFlags, BOOL* bRebootRequired);
	public static BOOL UpdateDriverForPlugAndPlayDevices(HWND hwndParent, PSTR HardwareId, PSTR FullInfPath, uint32 InstallFlags, BOOL* bRebootRequired) => UpdateDriverForPlugAndPlayDevicesA(hwndParent, HardwareId, FullInfPath, InstallFlags, bRebootRequired);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UpdateDriverForPlugAndPlayDevicesW(HWND hwndParent, PWSTR HardwareId, PWSTR FullInfPath, uint32 InstallFlags, BOOL* bRebootRequired);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiInstallDevice(HWND hwndParent, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, SP_DRVINFO_DATA_V2_A* DriverInfoData, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiInstallDriverW(HWND hwndParent, PWSTR InfPath, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiInstallDriverA(HWND hwndParent, PSTR InfPath, uint32 Flags, BOOL* NeedReboot);
	public static BOOL DiInstallDriver(HWND hwndParent, PSTR InfPath, uint32 Flags, BOOL* NeedReboot) => DiInstallDriverA(hwndParent, InfPath, Flags, NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiUninstallDevice(HWND hwndParent, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiUninstallDriverW(HWND hwndParent, PWSTR InfPath, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiUninstallDriverA(HWND hwndParent, PSTR InfPath, uint32 Flags, BOOL* NeedReboot);
	public static BOOL DiUninstallDriver(HWND hwndParent, PSTR InfPath, uint32 Flags, BOOL* NeedReboot) => DiUninstallDriverA(hwndParent, InfPath, Flags, NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiShowUpdateDevice(HWND hwndParent, HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiRollbackDriver(HDEVINFO DeviceInfoSet, SP_DEVINFO_DATA* DeviceInfoData, HWND hwndParent, uint32 Flags, BOOL* NeedReboot);

	[Import("newdev.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DiShowUpdateDriver(HWND hwndParent, PWSTR FilePath, uint32 Flags, BOOL* NeedReboot);

}
#endregion
