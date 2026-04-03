using Win32.Devices.Properties;
using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com;
using Win32.System.Com.StructuredStorage;
using System;

namespace Win32.Devices.PortableDevices;

#region Constants
public static
{
	public const DEVPROPKEY DEVPKEY_MTPBTH_IsConnected = .(.(0xea1237fa, 0x589d, 0x4472, 0x84, 0xe4, 0x0a, 0xbe, 0x36, 0xfd, 0x62, 0xef), 2);
	public const Guid GUID_DEVINTERFACE_WPD = .(0x6ac27878, 0xa6fa, 0x4155, 0xba, 0x85, 0xf9, 0x8f, 0x49, 0x1d, 0x4f, 0x33);
	public const Guid GUID_DEVINTERFACE_WPD_PRIVATE = .(0xba0c718f, 0x4ded, 0x49b7, 0xbd, 0xd3, 0xfa, 0xbe, 0x28, 0x66, 0x12, 0x11);
	public const Guid GUID_DEVINTERFACE_WPD_SERVICE = .(0x9ef44f80, 0x3d64, 0x4246, 0xa6, 0xaa, 0x20, 0x6f, 0x32, 0x8d, 0x1e, 0xdc);
	public const uint32 WPD_CONTROL_FUNCTION_GENERIC_MESSAGE = 66;
	public const uint32 IOCTL_WPD_MESSAGE_READWRITE_ACCESS = 4243720;
	public const uint32 IOCTL_WPD_MESSAGE_READ_ACCESS = 4210952;
	public const String WPD_DEVICE_OBJECT_ID = "DEVICE";
	public const String PORTABLE_DEVICE_TYPE = "PortableDeviceType";
	public const String PORTABLE_DEVICE_ICON = "Icons";
	public const String PORTABLE_DEVICE_NAMESPACE_TIMEOUT = "PortableDeviceNameSpaceTimeout";
	public const String PORTABLE_DEVICE_NAMESPACE_EXCLUDE_FROM_SHELL = "PortableDeviceNameSpaceExcludeFromShell";
	public const String PORTABLE_DEVICE_NAMESPACE_THUMBNAIL_CONTENT_TYPES = "PortableDeviceNameSpaceThumbnailContentTypes";
	public const String PORTABLE_DEVICE_IS_MASS_STORAGE = "PortableDeviceIsMassStorage";
	public const String PORTABLE_DEVICE_DRM_SCHEME_WMDRM10_PD = "WMDRM10-PD";
	public const String PORTABLE_DEVICE_DRM_SCHEME_PDDRM = "PDDRM";
	public const uint32 FACILITY_WPD = 42;
	public const HRESULT E_WPD_DEVICE_ALREADY_OPENED = -2144731135;
	public const HRESULT E_WPD_DEVICE_NOT_OPEN = -2144731134;
	public const HRESULT E_WPD_OBJECT_ALREADY_ATTACHED_TO_DEVICE = -2144731133;
	public const HRESULT E_WPD_OBJECT_NOT_ATTACHED_TO_DEVICE = -2144731132;
	public const HRESULT E_WPD_OBJECT_NOT_COMMITED = -2144731131;
	public const HRESULT E_WPD_DEVICE_IS_HUNG = -2144731130;
	public const HRESULT E_WPD_SMS_INVALID_RECIPIENT = -2144731036;
	public const HRESULT E_WPD_SMS_INVALID_MESSAGE_BODY = -2144731035;
	public const HRESULT E_WPD_SMS_SERVICE_UNAVAILABLE = -2144731034;
	public const HRESULT E_WPD_SERVICE_ALREADY_OPENED = -2144730936;
	public const HRESULT E_WPD_SERVICE_NOT_OPEN = -2144730935;
	public const HRESULT E_WPD_OBJECT_ALREADY_ATTACHED_TO_SERVICE = -2144730934;
	public const HRESULT E_WPD_OBJECT_NOT_ATTACHED_TO_SERVICE = -2144730933;
	public const HRESULT E_WPD_SERVICE_BAD_PARAMETER_ORDER = -2144730932;
	public const Guid WPD_EVENT_NOTIFICATION = .(0x2ba2e40a, 0x6b4c, 0x4295, 0xbb, 0x43, 0x26, 0x32, 0x2b, 0x99, 0xae, 0xb2);
	public const Guid WPD_EVENT_OBJECT_ADDED = .(0xa726da95, 0xe207, 0x4b02, 0x8d, 0x44, 0xbe, 0xf2, 0xe8, 0x6c, 0xbf, 0xfc);
	public const Guid WPD_EVENT_OBJECT_REMOVED = .(0xbe82ab88, 0xa52c, 0x4823, 0x96, 0xe5, 0xd0, 0x27, 0x26, 0x71, 0xfc, 0x38);
	public const Guid WPD_EVENT_OBJECT_UPDATED = .(0x1445a759, 0x2e01, 0x485d, 0x9f, 0x27, 0xff, 0x07, 0xda, 0xe6, 0x97, 0xab);
	public const Guid WPD_EVENT_DEVICE_RESET = .(0x7755cf53, 0xc1ed, 0x44f3, 0xb5, 0xa2, 0x45, 0x1e, 0x2c, 0x37, 0x6b, 0x27);
	public const Guid WPD_EVENT_DEVICE_CAPABILITIES_UPDATED = .(0x36885aa1, 0xcd54, 0x4daa, 0xb3, 0xd0, 0xaf, 0xb3, 0xe0, 0x3f, 0x59, 0x99);
	public const Guid WPD_EVENT_STORAGE_FORMAT = .(0x3782616b, 0x22bc, 0x4474, 0xa2, 0x51, 0x30, 0x70, 0xf8, 0xd3, 0x88, 0x57);
	public const Guid WPD_EVENT_OBJECT_TRANSFER_REQUESTED = .(0x8d16a0a1, 0xf2c6, 0x41da, 0x8f, 0x19, 0x5e, 0x53, 0x72, 0x1a, 0xdb, 0xf2);
	public const Guid WPD_EVENT_DEVICE_REMOVED = .(0xe4cbca1b, 0x6918, 0x48b9, 0x85, 0xee, 0x02, 0xbe, 0x7c, 0x85, 0x0a, 0xf9);
	public const Guid WPD_EVENT_SERVICE_METHOD_COMPLETE = .(0x8a33f5f8, 0x0acc, 0x4d9b, 0x9c, 0xc4, 0x11, 0x2d, 0x35, 0x3b, 0x86, 0xca);
	public const Guid WPD_CONTENT_TYPE_FUNCTIONAL_OBJECT = .(0x99ed0160, 0x17ff, 0x4c44, 0x9d, 0x98, 0x1d, 0x7a, 0x6f, 0x94, 0x19, 0x21);
	public const Guid WPD_CONTENT_TYPE_FOLDER = .(0x27e2e392, 0xa111, 0x48e0, 0xab, 0x0c, 0xe1, 0x77, 0x05, 0xa0, 0x5f, 0x85);
	public const Guid WPD_CONTENT_TYPE_IMAGE = .(0xef2107d5, 0xa52a, 0x4243, 0xa2, 0x6b, 0x62, 0xd4, 0x17, 0x6d, 0x76, 0x03);
	public const Guid WPD_CONTENT_TYPE_DOCUMENT = .(0x680adf52, 0x950a, 0x4041, 0x9b, 0x41, 0x65, 0xe3, 0x93, 0x64, 0x81, 0x55);
	public const Guid WPD_CONTENT_TYPE_CONTACT = .(0xeaba8313, 0x4525, 0x4707, 0x9f, 0x0e, 0x87, 0xc6, 0x80, 0x8e, 0x94, 0x35);
	public const Guid WPD_CONTENT_TYPE_CONTACT_GROUP = .(0x346b8932, 0x4c36, 0x40d8, 0x94, 0x15, 0x18, 0x28, 0x29, 0x1f, 0x9d, 0xe9);
	public const Guid WPD_CONTENT_TYPE_AUDIO = .(0x4ad2c85e, 0x5e2d, 0x45e5, 0x88, 0x64, 0x4f, 0x22, 0x9e, 0x3c, 0x6c, 0xf0);
	public const Guid WPD_CONTENT_TYPE_VIDEO = .(0x9261b03c, 0x3d78, 0x4519, 0x85, 0xe3, 0x02, 0xc5, 0xe1, 0xf5, 0x0b, 0xb9);
	public const Guid WPD_CONTENT_TYPE_TELEVISION = .(0x60a169cf, 0xf2ae, 0x4e21, 0x93, 0x75, 0x96, 0x77, 0xf1, 0x1c, 0x1c, 0x6e);
	public const Guid WPD_CONTENT_TYPE_PLAYLIST = .(0x1a33f7e4, 0xaf13, 0x48f5, 0x99, 0x4e, 0x77, 0x36, 0x9d, 0xfe, 0x04, 0xa3);
	public const Guid WPD_CONTENT_TYPE_MIXED_CONTENT_ALBUM = .(0x00f0c3ac, 0xa593, 0x49ac, 0x92, 0x19, 0x24, 0xab, 0xca, 0x5a, 0x25, 0x63);
	public const Guid WPD_CONTENT_TYPE_AUDIO_ALBUM = .(0xaa18737e, 0x5009, 0x48fa, 0xae, 0x21, 0x85, 0xf2, 0x43, 0x83, 0xb4, 0xe6);
	public const Guid WPD_CONTENT_TYPE_IMAGE_ALBUM = .(0x75793148, 0x15f5, 0x4a30, 0xa8, 0x13, 0x54, 0xed, 0x8a, 0x37, 0xe2, 0x26);
	public const Guid WPD_CONTENT_TYPE_VIDEO_ALBUM = .(0x012b0db7, 0xd4c1, 0x45d6, 0xb0, 0x81, 0x94, 0xb8, 0x77, 0x79, 0x61, 0x4f);
	public const Guid WPD_CONTENT_TYPE_MEMO = .(0x9cd20ecf, 0x3b50, 0x414f, 0xa6, 0x41, 0xe4, 0x73, 0xff, 0xe4, 0x57, 0x51);
	public const Guid WPD_CONTENT_TYPE_EMAIL = .(0x8038044a, 0x7e51, 0x4f8f, 0x88, 0x3d, 0x1d, 0x06, 0x23, 0xd1, 0x45, 0x33);
	public const Guid WPD_CONTENT_TYPE_APPOINTMENT = .(0x0fed060e, 0x8793, 0x4b1e, 0x90, 0xc9, 0x48, 0xac, 0x38, 0x9a, 0xc6, 0x31);
	public const Guid WPD_CONTENT_TYPE_TASK = .(0x63252f2c, 0x887f, 0x4cb6, 0xb1, 0xac, 0xd2, 0x98, 0x55, 0xdc, 0xef, 0x6c);
	public const Guid WPD_CONTENT_TYPE_PROGRAM = .(0xd269f96a, 0x247c, 0x4bff, 0x98, 0xfb, 0x97, 0xf3, 0xc4, 0x92, 0x20, 0xe6);
	public const Guid WPD_CONTENT_TYPE_GENERIC_FILE = .(0x0085e0a6, 0x8d34, 0x45d7, 0xbc, 0x5c, 0x44, 0x7e, 0x59, 0xc7, 0x3d, 0x48);
	public const Guid WPD_CONTENT_TYPE_CALENDAR = .(0xa1fd5967, 0x6023, 0x49a0, 0x9d, 0xf1, 0xf8, 0x06, 0x0b, 0xe7, 0x51, 0xb0);
	public const Guid WPD_CONTENT_TYPE_GENERIC_MESSAGE = .(0xe80eaaf8, 0xb2db, 0x4133, 0xb6, 0x7e, 0x1b, 0xef, 0x4b, 0x4a, 0x6e, 0x5f);
	public const Guid WPD_CONTENT_TYPE_NETWORK_ASSOCIATION = .(0x031da7ee, 0x18c8, 0x4205, 0x84, 0x7e, 0x89, 0xa1, 0x12, 0x61, 0xd0, 0xf3);
	public const Guid WPD_CONTENT_TYPE_CERTIFICATE = .(0xdc3876e8, 0xa948, 0x4060, 0x90, 0x50, 0xcb, 0xd7, 0x7e, 0x8a, 0x3d, 0x87);
	public const Guid WPD_CONTENT_TYPE_WIRELESS_PROFILE = .(0x0bac070a, 0x9f5f, 0x4da4, 0xa8, 0xf6, 0x3d, 0xe4, 0x4d, 0x68, 0xfd, 0x6c);
	public const Guid WPD_CONTENT_TYPE_MEDIA_CAST = .(0x5e88b3cc, 0x3e65, 0x4e62, 0xbf, 0xff, 0x22, 0x94, 0x95, 0x25, 0x3a, 0xb0);
	public const Guid WPD_CONTENT_TYPE_SECTION = .(0x821089f5, 0x1d91, 0x4dc9, 0xbe, 0x3c, 0xbb, 0xb1, 0xb3, 0x5b, 0x18, 0xce);
	public const Guid WPD_CONTENT_TYPE_UNSPECIFIED = .(0x28d8d31e, 0x249c, 0x454e, 0xaa, 0xbc, 0x34, 0x88, 0x31, 0x68, 0xe6, 0x34);
	public const Guid WPD_CONTENT_TYPE_ALL = .(0x80e170d2, 0x1055, 0x4a3e, 0xb9, 0x52, 0x82, 0xcc, 0x4f, 0x8a, 0x86, 0x89);
	public const Guid WPD_FUNCTIONAL_CATEGORY_DEVICE = .(0x08ea466b, 0xe3a4, 0x4336, 0xa1, 0xf3, 0xa4, 0x4d, 0x2b, 0x5c, 0x43, 0x8c);
	public const Guid WPD_FUNCTIONAL_CATEGORY_STORAGE = .(0x23f05bbc, 0x15de, 0x4c2a, 0xa5, 0x5b, 0xa9, 0xaf, 0x5c, 0xe4, 0x12, 0xef);
	public const Guid WPD_FUNCTIONAL_CATEGORY_STILL_IMAGE_CAPTURE = .(0x613ca327, 0xab93, 0x4900, 0xb4, 0xfa, 0x89, 0x5b, 0xb5, 0x87, 0x4b, 0x79);
	public const Guid WPD_FUNCTIONAL_CATEGORY_AUDIO_CAPTURE = .(0x3f2a1919, 0xc7c2, 0x4a00, 0x85, 0x5d, 0xf5, 0x7c, 0xf0, 0x6d, 0xeb, 0xbb);
	public const Guid WPD_FUNCTIONAL_CATEGORY_VIDEO_CAPTURE = .(0xe23e5f6b, 0x7243, 0x43aa, 0x8d, 0xf1, 0x0e, 0xb3, 0xd9, 0x68, 0xa9, 0x18);
	public const Guid WPD_FUNCTIONAL_CATEGORY_SMS = .(0x0044a0b1, 0xc1e9, 0x4afd, 0xb3, 0x58, 0xa6, 0x2c, 0x61, 0x17, 0xc9, 0xcf);
	public const Guid WPD_FUNCTIONAL_CATEGORY_RENDERING_INFORMATION = .(0x08600ba4, 0xa7ba, 0x4a01, 0xab, 0x0e, 0x00, 0x65, 0xd0, 0xa3, 0x56, 0xd3);
	public const Guid WPD_FUNCTIONAL_CATEGORY_NETWORK_CONFIGURATION = .(0x48f4db72, 0x7c6a, 0x4ab0, 0x9e, 0x1a, 0x47, 0x0e, 0x3c, 0xdb, 0xf2, 0x6a);
	public const Guid WPD_FUNCTIONAL_CATEGORY_ALL = .(0x2d8a6512, 0xa74c, 0x448e, 0xba, 0x8a, 0xf4, 0xac, 0x07, 0xc4, 0x93, 0x99);
	public const Guid WPD_OBJECT_FORMAT_ICON = .(0x077232ed, 0x102c, 0x4638, 0x9c, 0x22, 0x83, 0xf1, 0x42, 0xbf, 0xc8, 0x22);
	public const Guid WPD_OBJECT_FORMAT_M4A = .(0x30aba7ac, 0x6ffd, 0x4c23, 0xa3, 0x59, 0x3e, 0x9b, 0x52, 0xf3, 0xf1, 0xc8);
	public const Guid WPD_OBJECT_FORMAT_NETWORK_ASSOCIATION = .(0xb1020000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_X509V3CERTIFICATE = .(0xb1030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MICROSOFT_WFC = .(0xb1040000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_3GPA = .(0xe5172730, 0xf971, 0x41ef, 0xa1, 0x0b, 0x22, 0x71, 0xa0, 0x01, 0x9d, 0x7a);
	public const Guid WPD_OBJECT_FORMAT_3G2A = .(0x1a11202d, 0x8759, 0x4e34, 0xba, 0x5e, 0xb1, 0x21, 0x10, 0x87, 0xee, 0xe4);
	public const Guid WPD_OBJECT_FORMAT_ALL = .(0xc1f62eb2, 0x4bb3, 0x479c, 0x9c, 0xfa, 0x05, 0xb5, 0xf3, 0xa5, 0x7b, 0x22);
	public const Guid WPD_CATEGORY_NULL = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const PROPERTYKEY WPD_PROPERTY_NULL = .(.(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00), 0);
	public const Guid WPD_OBJECT_PROPERTIES_V1 = .(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c);
	public const PROPERTYKEY WPD_OBJECT_CONTENT_TYPE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 7);
	public const PROPERTYKEY WPD_OBJECT_REFERENCES = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 14);
	public const PROPERTYKEY WPD_OBJECT_CONTAINER_FUNCTIONAL_OBJECT_ID = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 23);
	public const PROPERTYKEY WPD_OBJECT_GENERATE_THUMBNAIL_FROM_RESOURCE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 24);
	public const PROPERTYKEY WPD_OBJECT_HINT_LOCATION_DISPLAY_NAME = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 25);
	public const Guid WPD_OBJECT_PROPERTIES_V2 = .(0x0373cd3d, 0x4a46, 0x40d7, 0xb4, 0xd8, 0x73, 0xe8, 0xda, 0x74, 0xe7, 0x75);
	public const PROPERTYKEY WPD_OBJECT_SUPPORTED_UNITS = .(.(0x0373cd3d, 0x4a46, 0x40d7, 0xb4, 0xd8, 0x73, 0xe8, 0xda, 0x74, 0xe7, 0x75), 2);
	public const Guid WPD_FUNCTIONAL_OBJECT_PROPERTIES_V1 = .(0x8f052d93, 0xabca, 0x4fc5, 0xa5, 0xac, 0xb0, 0x1d, 0xf4, 0xdb, 0xe5, 0x98);
	public const PROPERTYKEY WPD_FUNCTIONAL_OBJECT_CATEGORY = .(.(0x8f052d93, 0xabca, 0x4fc5, 0xa5, 0xac, 0xb0, 0x1d, 0xf4, 0xdb, 0xe5, 0x98), 2);
	public const Guid WPD_STORAGE_OBJECT_PROPERTIES_V1 = .(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a);
	public const PROPERTYKEY WPD_STORAGE_TYPE = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 2);
	public const PROPERTYKEY WPD_STORAGE_FILE_SYSTEM_TYPE = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 3);
	public const PROPERTYKEY WPD_STORAGE_CAPACITY = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 4);
	public const PROPERTYKEY WPD_STORAGE_FREE_SPACE_IN_BYTES = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 5);
	public const PROPERTYKEY WPD_STORAGE_FREE_SPACE_IN_OBJECTS = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 6);
	public const PROPERTYKEY WPD_STORAGE_DESCRIPTION = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 7);
	public const PROPERTYKEY WPD_STORAGE_SERIAL_NUMBER = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 8);
	public const PROPERTYKEY WPD_STORAGE_MAX_OBJECT_SIZE = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 9);
	public const PROPERTYKEY WPD_STORAGE_CAPACITY_IN_OBJECTS = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 10);
	public const PROPERTYKEY WPD_STORAGE_ACCESS_CAPABILITY = .(.(0x01a3057a, 0x74d6, 0x4e80, 0xbe, 0xa7, 0xdc, 0x4c, 0x21, 0x2c, 0xe5, 0x0a), 11);
	public const Guid WPD_NETWORK_ASSOCIATION_PROPERTIES_V1 = .(0xe4c93c1f, 0xb203, 0x43f1, 0xa1, 0x00, 0x5a, 0x07, 0xd1, 0x1b, 0x02, 0x74);
	public const PROPERTYKEY WPD_NETWORK_ASSOCIATION_HOST_NETWORK_IDENTIFIERS = .(.(0xe4c93c1f, 0xb203, 0x43f1, 0xa1, 0x00, 0x5a, 0x07, 0xd1, 0x1b, 0x02, 0x74), 2);
	public const PROPERTYKEY WPD_NETWORK_ASSOCIATION_X509V3SEQUENCE = .(.(0xe4c93c1f, 0xb203, 0x43f1, 0xa1, 0x00, 0x5a, 0x07, 0xd1, 0x1b, 0x02, 0x74), 3);
	public const Guid WPD_STILL_IMAGE_CAPTURE_OBJECT_PROPERTIES_V1 = .(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAPTURE_RESOLUTION = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 2);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAPTURE_FORMAT = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 3);
	public const PROPERTYKEY WPD_STILL_IMAGE_COMPRESSION_SETTING = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 4);
	public const PROPERTYKEY WPD_STILL_IMAGE_WHITE_BALANCE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 5);
	public const PROPERTYKEY WPD_STILL_IMAGE_RGB_GAIN = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 6);
	public const PROPERTYKEY WPD_STILL_IMAGE_FNUMBER = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 7);
	public const PROPERTYKEY WPD_STILL_IMAGE_FOCAL_LENGTH = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 8);
	public const PROPERTYKEY WPD_STILL_IMAGE_FOCUS_DISTANCE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 9);
	public const PROPERTYKEY WPD_STILL_IMAGE_FOCUS_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 10);
	public const PROPERTYKEY WPD_STILL_IMAGE_EXPOSURE_METERING_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 11);
	public const PROPERTYKEY WPD_STILL_IMAGE_FLASH_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 12);
	public const PROPERTYKEY WPD_STILL_IMAGE_EXPOSURE_TIME = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 13);
	public const PROPERTYKEY WPD_STILL_IMAGE_EXPOSURE_PROGRAM_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 14);
	public const PROPERTYKEY WPD_STILL_IMAGE_EXPOSURE_INDEX = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 15);
	public const PROPERTYKEY WPD_STILL_IMAGE_EXPOSURE_BIAS_COMPENSATION = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 16);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAPTURE_DELAY = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 17);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAPTURE_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 18);
	public const PROPERTYKEY WPD_STILL_IMAGE_CONTRAST = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 19);
	public const PROPERTYKEY WPD_STILL_IMAGE_SHARPNESS = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 20);
	public const PROPERTYKEY WPD_STILL_IMAGE_DIGITAL_ZOOM = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 21);
	public const PROPERTYKEY WPD_STILL_IMAGE_EFFECT_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 22);
	public const PROPERTYKEY WPD_STILL_IMAGE_BURST_NUMBER = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 23);
	public const PROPERTYKEY WPD_STILL_IMAGE_BURST_INTERVAL = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 24);
	public const PROPERTYKEY WPD_STILL_IMAGE_TIMELAPSE_NUMBER = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 25);
	public const PROPERTYKEY WPD_STILL_IMAGE_TIMELAPSE_INTERVAL = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 26);
	public const PROPERTYKEY WPD_STILL_IMAGE_FOCUS_METERING_MODE = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 27);
	public const PROPERTYKEY WPD_STILL_IMAGE_UPLOAD_URL = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 28);
	public const PROPERTYKEY WPD_STILL_IMAGE_ARTIST = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 29);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAMERA_MODEL = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 30);
	public const PROPERTYKEY WPD_STILL_IMAGE_CAMERA_MANUFACTURER = .(.(0x58c571ec, 0x1bcb, 0x42a7, 0x8a, 0xc5, 0xbb, 0x29, 0x15, 0x73, 0xa2, 0x60), 31);
	public const Guid WPD_RENDERING_INFORMATION_OBJECT_PROPERTIES_V1 = .(0xc53d039f, 0xee23, 0x4a31, 0x85, 0x90, 0x76, 0x39, 0x87, 0x98, 0x70, 0xb4);
	public const PROPERTYKEY WPD_RENDERING_INFORMATION_PROFILES = .(.(0xc53d039f, 0xee23, 0x4a31, 0x85, 0x90, 0x76, 0x39, 0x87, 0x98, 0x70, 0xb4), 2);
	public const PROPERTYKEY WPD_RENDERING_INFORMATION_PROFILE_ENTRY_TYPE = .(.(0xc53d039f, 0xee23, 0x4a31, 0x85, 0x90, 0x76, 0x39, 0x87, 0x98, 0x70, 0xb4), 3);
	public const PROPERTYKEY WPD_RENDERING_INFORMATION_PROFILE_ENTRY_CREATABLE_RESOURCES = .(.(0xc53d039f, 0xee23, 0x4a31, 0x85, 0x90, 0x76, 0x39, 0x87, 0x98, 0x70, 0xb4), 4);
	public const Guid WPD_CLIENT_INFORMATION_PROPERTIES_V1 = .(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59);
	public const PROPERTYKEY WPD_CLIENT_NAME = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 2);
	public const PROPERTYKEY WPD_CLIENT_MAJOR_VERSION = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 3);
	public const PROPERTYKEY WPD_CLIENT_MINOR_VERSION = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 4);
	public const PROPERTYKEY WPD_CLIENT_REVISION = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 5);
	public const PROPERTYKEY WPD_CLIENT_WMDRM_APPLICATION_PRIVATE_KEY = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 6);
	public const PROPERTYKEY WPD_CLIENT_WMDRM_APPLICATION_CERTIFICATE = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 7);
	public const PROPERTYKEY WPD_CLIENT_SECURITY_QUALITY_OF_SERVICE = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 8);
	public const PROPERTYKEY WPD_CLIENT_DESIRED_ACCESS = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 9);
	public const PROPERTYKEY WPD_CLIENT_SHARE_MODE = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 10);
	public const PROPERTYKEY WPD_CLIENT_EVENT_COOKIE = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 11);
	public const PROPERTYKEY WPD_CLIENT_MINIMUM_RESULTS_BUFFER_SIZE = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 12);
	public const PROPERTYKEY WPD_CLIENT_MANUAL_CLOSE_ON_DISCONNECT = .(.(0x204d9f0c, 0x2292, 0x4080, 0x9f, 0x42, 0x40, 0x66, 0x4e, 0x70, 0xf8, 0x59), 13);
	public const Guid WPD_PROPERTY_ATTRIBUTES_V1 = .(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_FORM = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 2);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_CAN_READ = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 3);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_CAN_WRITE = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 4);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_CAN_DELETE = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 5);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_DEFAULT_VALUE = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 6);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_FAST_PROPERTY = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 7);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_RANGE_MIN = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 8);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_RANGE_MAX = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 9);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_RANGE_STEP = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 10);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_ENUMERATION_ELEMENTS = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 11);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_REGULAR_EXPRESSION = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 12);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_MAX_SIZE = .(.(0xab7943d8, 0x6332, 0x445f, 0xa0, 0x0d, 0x8d, 0x5e, 0xf1, 0xe9, 0x6f, 0x37), 13);
	public const Guid WPD_PROPERTY_ATTRIBUTES_V2 = .(0x5d9da160, 0x74ae, 0x43cc, 0x85, 0xa9, 0xfe, 0x55, 0x5a, 0x80, 0x79, 0x8e);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_NAME = .(.(0x5d9da160, 0x74ae, 0x43cc, 0x85, 0xa9, 0xfe, 0x55, 0x5a, 0x80, 0x79, 0x8e), 2);
	public const PROPERTYKEY WPD_PROPERTY_ATTRIBUTE_VARTYPE = .(.(0x5d9da160, 0x74ae, 0x43cc, 0x85, 0xa9, 0xfe, 0x55, 0x5a, 0x80, 0x79, 0x8e), 3);
	public const Guid WPD_CLASS_EXTENSION_OPTIONS_V1 = .(0x6309ffef, 0xa87c, 0x4ca7, 0x84, 0x34, 0x79, 0x75, 0x76, 0xe4, 0x0a, 0x96);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_SUPPORTED_CONTENT_TYPES = .(.(0x6309ffef, 0xa87c, 0x4ca7, 0x84, 0x34, 0x79, 0x75, 0x76, 0xe4, 0x0a, 0x96), 2);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_DONT_REGISTER_WPD_DEVICE_INTERFACE = .(.(0x6309ffef, 0xa87c, 0x4ca7, 0x84, 0x34, 0x79, 0x75, 0x76, 0xe4, 0x0a, 0x96), 3);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_REGISTER_WPD_PRIVATE_DEVICE_INTERFACE = .(.(0x6309ffef, 0xa87c, 0x4ca7, 0x84, 0x34, 0x79, 0x75, 0x76, 0xe4, 0x0a, 0x96), 4);
	public const Guid WPD_CLASS_EXTENSION_OPTIONS_V2 = .(0x3e3595da, 0x4d71, 0x49fe, 0xa0, 0xb4, 0xd4, 0x40, 0x6c, 0x3a, 0xe9, 0x3f);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_MULTITRANSPORT_MODE = .(.(0x3e3595da, 0x4d71, 0x49fe, 0xa0, 0xb4, 0xd4, 0x40, 0x6c, 0x3a, 0xe9, 0x3f), 2);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_DEVICE_IDENTIFICATION_VALUES = .(.(0x3e3595da, 0x4d71, 0x49fe, 0xa0, 0xb4, 0xd4, 0x40, 0x6c, 0x3a, 0xe9, 0x3f), 3);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_TRANSPORT_BANDWIDTH = .(.(0x3e3595da, 0x4d71, 0x49fe, 0xa0, 0xb4, 0xd4, 0x40, 0x6c, 0x3a, 0xe9, 0x3f), 4);
	public const Guid WPD_CLASS_EXTENSION_OPTIONS_V3 = .(0x65c160f8, 0x1367, 0x4ce2, 0x93, 0x9d, 0x83, 0x10, 0x83, 0x9f, 0x0d, 0x30);
	public const PROPERTYKEY WPD_CLASS_EXTENSION_OPTIONS_SILENCE_AUTOPLAY = .(.(0x65c160f8, 0x1367, 0x4ce2, 0x93, 0x9d, 0x83, 0x10, 0x83, 0x9f, 0x0d, 0x30), 2);
	public const Guid WPD_RESOURCE_ATTRIBUTES_V1 = .(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_TOTAL_SIZE = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 2);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_CAN_READ = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 3);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_CAN_WRITE = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 4);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_CAN_DELETE = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 5);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_OPTIMAL_READ_BUFFER_SIZE = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 6);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_OPTIMAL_WRITE_BUFFER_SIZE = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 7);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_FORMAT = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 8);
	public const PROPERTYKEY WPD_RESOURCE_ATTRIBUTE_RESOURCE_KEY = .(.(0x1eb6f604, 0x9278, 0x429f, 0x93, 0xcc, 0x5b, 0xb8, 0xc0, 0x66, 0x56, 0xb6), 9);
	public const Guid WPD_DEVICE_PROPERTIES_V1 = .(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc);
	public const PROPERTYKEY WPD_DEVICE_SYNC_PARTNER = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 2);
	public const PROPERTYKEY WPD_DEVICE_FIRMWARE_VERSION = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 3);
	public const PROPERTYKEY WPD_DEVICE_POWER_LEVEL = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 4);
	public const PROPERTYKEY WPD_DEVICE_POWER_SOURCE = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 5);
	public const PROPERTYKEY WPD_DEVICE_PROTOCOL = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 6);
	public const PROPERTYKEY WPD_DEVICE_MANUFACTURER = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 7);
	public const PROPERTYKEY WPD_DEVICE_MODEL = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 8);
	public const PROPERTYKEY WPD_DEVICE_SERIAL_NUMBER = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 9);
	public const PROPERTYKEY WPD_DEVICE_SUPPORTS_NON_CONSUMABLE = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 10);
	public const PROPERTYKEY WPD_DEVICE_DATETIME = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 11);
	public const PROPERTYKEY WPD_DEVICE_FRIENDLY_NAME = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 12);
	public const PROPERTYKEY WPD_DEVICE_SUPPORTED_DRM_SCHEMES = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 13);
	public const PROPERTYKEY WPD_DEVICE_SUPPORTED_FORMATS_ARE_ORDERED = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 14);
	public const PROPERTYKEY WPD_DEVICE_TYPE = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 15);
	public const PROPERTYKEY WPD_DEVICE_NETWORK_IDENTIFIER = .(.(0x26d4979a, 0xe643, 0x4626, 0x9e, 0x2b, 0x73, 0x6d, 0xc0, 0xc9, 0x2f, 0xdc), 16);
	public const Guid WPD_DEVICE_PROPERTIES_V2 = .(0x463dd662, 0x7fc4, 0x4291, 0x91, 0x1c, 0x7f, 0x4c, 0x9c, 0xca, 0x97, 0x99);
	public const PROPERTYKEY WPD_DEVICE_FUNCTIONAL_UNIQUE_ID = .(.(0x463dd662, 0x7fc4, 0x4291, 0x91, 0x1c, 0x7f, 0x4c, 0x9c, 0xca, 0x97, 0x99), 2);
	public const PROPERTYKEY WPD_DEVICE_MODEL_UNIQUE_ID = .(.(0x463dd662, 0x7fc4, 0x4291, 0x91, 0x1c, 0x7f, 0x4c, 0x9c, 0xca, 0x97, 0x99), 3);
	public const PROPERTYKEY WPD_DEVICE_TRANSPORT = .(.(0x463dd662, 0x7fc4, 0x4291, 0x91, 0x1c, 0x7f, 0x4c, 0x9c, 0xca, 0x97, 0x99), 4);
	public const PROPERTYKEY WPD_DEVICE_USE_DEVICE_STAGE = .(.(0x463dd662, 0x7fc4, 0x4291, 0x91, 0x1c, 0x7f, 0x4c, 0x9c, 0xca, 0x97, 0x99), 5);
	public const Guid WPD_DEVICE_PROPERTIES_V3 = .(0x6c2b878c, 0xc2ec, 0x490d, 0xb4, 0x25, 0xd7, 0xa7, 0x5e, 0x23, 0xe5, 0xed);
	public const PROPERTYKEY WPD_DEVICE_EDP_IDENTITY = .(.(0x6c2b878c, 0xc2ec, 0x490d, 0xb4, 0x25, 0xd7, 0xa7, 0x5e, 0x23, 0xe5, 0xed), 1);
	public const Guid WPD_SERVICE_PROPERTIES_V1 = .(0x7510698a, 0xcb54, 0x481c, 0xb8, 0xdb, 0x0d, 0x75, 0xc9, 0x3f, 0x1c, 0x06);
	public const PROPERTYKEY WPD_SERVICE_VERSION = .(.(0x7510698a, 0xcb54, 0x481c, 0xb8, 0xdb, 0x0d, 0x75, 0xc9, 0x3f, 0x1c, 0x06), 2);
	public const Guid WPD_EVENT_PROPERTIES_V1 = .(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_PNP_DEVICE_ID = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 2);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_EVENT_ID = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 3);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_OPERATION_STATE = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 4);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_OPERATION_PROGRESS = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 5);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_OBJECT_PARENT_PERSISTENT_UNIQUE_ID = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 6);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_OBJECT_CREATION_COOKIE = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 7);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_CHILD_HIERARCHY_CHANGED = .(.(0x15ab1953, 0xf817, 0x4fef, 0xa9, 0x21, 0x56, 0x76, 0xe8, 0x38, 0xf6, 0xe0), 8);
	public const Guid WPD_EVENT_PROPERTIES_V2 = .(0x52807b8a, 0x4914, 0x4323, 0x9b, 0x9a, 0x74, 0xf6, 0x54, 0xb2, 0xb8, 0x46);
	public const PROPERTYKEY WPD_EVENT_PARAMETER_SERVICE_METHOD_CONTEXT = .(.(0x52807b8a, 0x4914, 0x4323, 0x9b, 0x9a, 0x74, 0xf6, 0x54, 0xb2, 0xb8, 0x46), 2);
	public const Guid WPD_EVENT_OPTIONS_V1 = .(0xb3d8dad7, 0xa361, 0x4b83, 0x8a, 0x48, 0x5b, 0x02, 0xce, 0x10, 0x71, 0x3b);
	public const PROPERTYKEY WPD_EVENT_OPTION_IS_BROADCAST_EVENT = .(.(0xb3d8dad7, 0xa361, 0x4b83, 0x8a, 0x48, 0x5b, 0x02, 0xce, 0x10, 0x71, 0x3b), 2);
	public const PROPERTYKEY WPD_EVENT_OPTION_IS_AUTOPLAY_EVENT = .(.(0xb3d8dad7, 0xa361, 0x4b83, 0x8a, 0x48, 0x5b, 0x02, 0xce, 0x10, 0x71, 0x3b), 3);
	public const Guid WPD_EVENT_ATTRIBUTES_V1 = .(0x10c96578, 0x2e81, 0x4111, 0xad, 0xde, 0xe0, 0x8c, 0xa6, 0x13, 0x8f, 0x6d);
	public const PROPERTYKEY WPD_EVENT_ATTRIBUTE_NAME = .(.(0x10c96578, 0x2e81, 0x4111, 0xad, 0xde, 0xe0, 0x8c, 0xa6, 0x13, 0x8f, 0x6d), 2);
	public const PROPERTYKEY WPD_EVENT_ATTRIBUTE_PARAMETERS = .(.(0x10c96578, 0x2e81, 0x4111, 0xad, 0xde, 0xe0, 0x8c, 0xa6, 0x13, 0x8f, 0x6d), 3);
	public const PROPERTYKEY WPD_EVENT_ATTRIBUTE_OPTIONS = .(.(0x10c96578, 0x2e81, 0x4111, 0xad, 0xde, 0xe0, 0x8c, 0xa6, 0x13, 0x8f, 0x6d), 4);
	public const Guid WPD_API_OPTIONS_V1 = .(0x10e54a3e, 0x052d, 0x4777, 0xa1, 0x3c, 0xde, 0x76, 0x14, 0xbe, 0x2b, 0xc4);
	public const PROPERTYKEY WPD_API_OPTION_USE_CLEAR_DATA_STREAM = .(.(0x10e54a3e, 0x052d, 0x4777, 0xa1, 0x3c, 0xde, 0x76, 0x14, 0xbe, 0x2b, 0xc4), 2);
	public const PROPERTYKEY WPD_API_OPTION_IOCTL_ACCESS = .(.(0x10e54a3e, 0x052d, 0x4777, 0xa1, 0x3c, 0xde, 0x76, 0x14, 0xbe, 0x2b, 0xc4), 3);
	public const Guid WPD_FORMAT_ATTRIBUTES_V1 = .(0xa0a02000, 0xbcaf, 0x4be8, 0xb3, 0xf5, 0x23, 0x3f, 0x23, 0x1c, 0xf5, 0x8f);
	public const PROPERTYKEY WPD_FORMAT_ATTRIBUTE_NAME = .(.(0xa0a02000, 0xbcaf, 0x4be8, 0xb3, 0xf5, 0x23, 0x3f, 0x23, 0x1c, 0xf5, 0x8f), 2);
	public const PROPERTYKEY WPD_FORMAT_ATTRIBUTE_MIMETYPE = .(.(0xa0a02000, 0xbcaf, 0x4be8, 0xb3, 0xf5, 0x23, 0x3f, 0x23, 0x1c, 0xf5, 0x8f), 3);
	public const Guid WPD_METHOD_ATTRIBUTES_V1 = .(0xf17a5071, 0xf039, 0x44af, 0x8e, 0xfe, 0x43, 0x2c, 0xf3, 0x2e, 0x43, 0x2a);
	public const PROPERTYKEY WPD_METHOD_ATTRIBUTE_NAME = .(.(0xf17a5071, 0xf039, 0x44af, 0x8e, 0xfe, 0x43, 0x2c, 0xf3, 0x2e, 0x43, 0x2a), 2);
	public const PROPERTYKEY WPD_METHOD_ATTRIBUTE_ASSOCIATED_FORMAT = .(.(0xf17a5071, 0xf039, 0x44af, 0x8e, 0xfe, 0x43, 0x2c, 0xf3, 0x2e, 0x43, 0x2a), 3);
	public const PROPERTYKEY WPD_METHOD_ATTRIBUTE_ACCESS = .(.(0xf17a5071, 0xf039, 0x44af, 0x8e, 0xfe, 0x43, 0x2c, 0xf3, 0x2e, 0x43, 0x2a), 4);
	public const PROPERTYKEY WPD_METHOD_ATTRIBUTE_PARAMETERS = .(.(0xf17a5071, 0xf039, 0x44af, 0x8e, 0xfe, 0x43, 0x2c, 0xf3, 0x2e, 0x43, 0x2a), 5);
	public const Guid WPD_PARAMETER_ATTRIBUTES_V1 = .(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_ORDER = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 2);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_USAGE = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 3);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_FORM = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 4);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_DEFAULT_VALUE = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 5);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_RANGE_MIN = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 6);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_RANGE_MAX = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 7);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_RANGE_STEP = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 8);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_ENUMERATION_ELEMENTS = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 9);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_REGULAR_EXPRESSION = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 10);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_MAX_SIZE = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 11);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_VARTYPE = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 12);
	public const PROPERTYKEY WPD_PARAMETER_ATTRIBUTE_NAME = .(.(0xe6864dd7, 0xf325, 0x45ea, 0xa1, 0xd5, 0x97, 0xcf, 0x73, 0xb6, 0xca, 0x58), 13);
	public const Guid WPD_CATEGORY_COMMON = .(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a);
	public const PROPERTYKEY WPD_COMMAND_COMMON_RESET_DEVICE = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 2);
	public const PROPERTYKEY WPD_COMMAND_COMMON_GET_OBJECT_IDS_FROM_PERSISTENT_UNIQUE_IDS = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 3);
	public const PROPERTYKEY WPD_COMMAND_COMMON_SAVE_CLIENT_INFORMATION = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 4);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_COMMAND_CATEGORY = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1001);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_COMMAND_ID = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1002);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_HRESULT = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1003);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_DRIVER_ERROR_CODE = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1004);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_COMMAND_TARGET = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1006);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_PERSISTENT_UNIQUE_IDS = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1007);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_OBJECT_IDS = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1008);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_CLIENT_INFORMATION = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1009);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_CLIENT_INFORMATION_CONTEXT = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1010);
	public const PROPERTYKEY WPD_PROPERTY_COMMON_ACTIVITY_ID = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 1011);
	public const PROPERTYKEY WPD_OPTION_VALID_OBJECT_IDS = .(.(0xf0422a9c, 0x5dc8, 0x4440, 0xb5, 0xbd, 0x5d, 0xf2, 0x88, 0x35, 0x65, 0x8a), 5001);
	public const Guid WPD_CATEGORY_OBJECT_ENUMERATION = .(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_ENUMERATION_START_FIND = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 2);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_ENUMERATION_FIND_NEXT = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 3);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_ENUMERATION_END_FIND = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 4);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_ENUMERATION_PARENT_ID = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 1001);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_ENUMERATION_FILTER = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 1002);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_ENUMERATION_OBJECT_IDS = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 1003);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_ENUMERATION_CONTEXT = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 1004);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_ENUMERATION_NUM_OBJECTS_REQUESTED = .(.(0xb7474e91, 0xe7f8, 0x4ad9, 0xb4, 0x00, 0xad, 0x1a, 0x4b, 0x58, 0xee, 0xec), 1005);
	public const Guid WPD_CATEGORY_OBJECT_PROPERTIES = .(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_GET_SUPPORTED = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 2);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_GET_ATTRIBUTES = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 3);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_GET = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 4);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_SET = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 5);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_GET_ALL = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 6);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_DELETE = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 7);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_OBJECT_ID = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1001);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_PROPERTY_KEYS = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1002);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_PROPERTY_ATTRIBUTES = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1003);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_PROPERTY_VALUES = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1004);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_PROPERTY_WRITE_RESULTS = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1005);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_PROPERTY_DELETE_RESULTS = .(.(0x9e5582e4, 0x0814, 0x44e6, 0x98, 0x1a, 0xb2, 0x99, 0x8d, 0x58, 0x38, 0x04), 1006);
	public const Guid WPD_CATEGORY_OBJECT_PROPERTIES_BULK = .(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_LIST_START = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 2);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_LIST_NEXT = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 3);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_LIST_END = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 4);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_FORMAT_START = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 5);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_FORMAT_NEXT = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 6);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_GET_VALUES_BY_OBJECT_FORMAT_END = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 7);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_SET_VALUES_BY_OBJECT_LIST_START = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 8);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_SET_VALUES_BY_OBJECT_LIST_NEXT = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 9);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_PROPERTIES_BULK_SET_VALUES_BY_OBJECT_LIST_END = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 10);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_OBJECT_IDS = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1001);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_CONTEXT = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1002);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_VALUES = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1003);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_PROPERTY_KEYS = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1004);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_DEPTH = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1005);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_PARENT_OBJECT_ID = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1006);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_OBJECT_FORMAT = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1007);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_PROPERTIES_BULK_WRITE_RESULTS = .(.(0x11c824dd, 0x04cd, 0x4e4e, 0x8c, 0x7b, 0xf6, 0xef, 0xb7, 0x94, 0xd8, 0x4e), 1008);
	public const Guid WPD_CATEGORY_OBJECT_RESOURCES = .(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_GET_SUPPORTED = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 2);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_GET_ATTRIBUTES = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 3);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_OPEN = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 4);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_READ = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 5);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_WRITE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 6);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_CLOSE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 7);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_DELETE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 8);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_CREATE_RESOURCE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 9);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_REVERT = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 10);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_SEEK = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 11);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_COMMIT = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 12);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_RESOURCES_SEEK_IN_UNITS = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 13);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_OBJECT_ID = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1001);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_ACCESS_MODE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1002);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_RESOURCE_KEYS = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1003);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_RESOURCE_ATTRIBUTES = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1004);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_CONTEXT = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1005);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_NUM_BYTES_TO_READ = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1006);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_NUM_BYTES_READ = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1007);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_NUM_BYTES_TO_WRITE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1008);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_NUM_BYTES_WRITTEN = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1009);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_DATA = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1010);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_OPTIMAL_TRANSFER_BUFFER_SIZE = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1011);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_SEEK_OFFSET = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1012);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_SEEK_ORIGIN_FLAG = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1013);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_POSITION_FROM_START = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1014);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_SUPPORTS_UNITS = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1015);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_RESOURCES_STREAM_UNITS = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 1016);
	public const PROPERTYKEY WPD_OPTION_OBJECT_RESOURCES_SEEK_ON_READ_SUPPORTED = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 5001);
	public const PROPERTYKEY WPD_OPTION_OBJECT_RESOURCES_SEEK_ON_WRITE_SUPPORTED = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 5002);
	public const PROPERTYKEY WPD_OPTION_OBJECT_RESOURCES_NO_INPUT_BUFFER_ON_READ = .(.(0xb3a2b22d, 0xa595, 0x4108, 0xbe, 0x0a, 0xfc, 0x3c, 0x96, 0x5f, 0x3d, 0x4a), 5003);
	public const Guid WPD_CATEGORY_OBJECT_MANAGEMENT = .(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_CREATE_OBJECT_WITH_PROPERTIES_ONLY = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 2);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_CREATE_OBJECT_WITH_PROPERTIES_AND_DATA = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 3);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_WRITE_OBJECT_DATA = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 4);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_COMMIT_OBJECT = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 5);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_REVERT_OBJECT = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 6);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_DELETE_OBJECTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 7);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_MOVE_OBJECTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 8);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_COPY_OBJECTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 9);
	public const PROPERTYKEY WPD_COMMAND_OBJECT_MANAGEMENT_UPDATE_OBJECT_WITH_PROPERTIES_AND_DATA = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 10);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_CREATION_PROPERTIES = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1001);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_CONTEXT = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1002);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_NUM_BYTES_TO_WRITE = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1003);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_NUM_BYTES_WRITTEN = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1004);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_DATA = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1005);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_OBJECT_ID = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1006);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_DELETE_OPTIONS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1007);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_OPTIMAL_TRANSFER_BUFFER_SIZE = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1008);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_OBJECT_IDS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1009);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_DELETE_RESULTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1010);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_DESTINATION_FOLDER_OBJECT_ID = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1011);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_MOVE_RESULTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1012);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_COPY_RESULTS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1013);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_UPDATE_PROPERTIES = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1014);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_PROPERTY_KEYS = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1015);
	public const PROPERTYKEY WPD_PROPERTY_OBJECT_MANAGEMENT_OBJECT_FORMAT = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 1016);
	public const PROPERTYKEY WPD_OPTION_OBJECT_MANAGEMENT_RECURSIVE_DELETE_SUPPORTED = .(.(0xef1e43dd, 0xa9ed, 0x4341, 0x8b, 0xcc, 0x18, 0x61, 0x92, 0xae, 0xa0, 0x89), 5001);
	public const Guid WPD_CATEGORY_CAPABILITIES = .(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_COMMANDS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 2);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_COMMAND_OPTIONS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 3);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_FUNCTIONAL_CATEGORIES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 4);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_FUNCTIONAL_OBJECTS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 5);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_CONTENT_TYPES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 6);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_FORMATS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 7);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_FORMAT_PROPERTIES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 8);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_FIXED_PROPERTY_ATTRIBUTES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 9);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_SUPPORTED_EVENTS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 10);
	public const PROPERTYKEY WPD_COMMAND_CAPABILITIES_GET_EVENT_OPTIONS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 11);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_SUPPORTED_COMMANDS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1001);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_COMMAND = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1002);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_COMMAND_OPTIONS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1003);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_FUNCTIONAL_CATEGORIES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1004);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_FUNCTIONAL_CATEGORY = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1005);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_FUNCTIONAL_OBJECTS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1006);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_CONTENT_TYPES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1007);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_CONTENT_TYPE = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1008);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_FORMATS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1009);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_FORMAT = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1010);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_PROPERTY_KEYS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1011);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_PROPERTY_ATTRIBUTES = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1012);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_SUPPORTED_EVENTS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1013);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_EVENT = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1014);
	public const PROPERTYKEY WPD_PROPERTY_CAPABILITIES_EVENT_OPTIONS = .(.(0x0cabec78, 0x6b74, 0x41c6, 0x92, 0x16, 0x26, 0x39, 0xd1, 0xfc, 0xe3, 0x56), 1015);
	public const Guid WPD_CATEGORY_STORAGE = .(0xd8f907a6, 0x34cc, 0x45fa, 0x97, 0xfb, 0xd0, 0x07, 0xfa, 0x47, 0xec, 0x94);
	public const PROPERTYKEY WPD_COMMAND_STORAGE_FORMAT = .(.(0xd8f907a6, 0x34cc, 0x45fa, 0x97, 0xfb, 0xd0, 0x07, 0xfa, 0x47, 0xec, 0x94), 2);
	public const PROPERTYKEY WPD_COMMAND_STORAGE_EJECT = .(.(0xd8f907a6, 0x34cc, 0x45fa, 0x97, 0xfb, 0xd0, 0x07, 0xfa, 0x47, 0xec, 0x94), 4);
	public const PROPERTYKEY WPD_PROPERTY_STORAGE_OBJECT_ID = .(.(0xd8f907a6, 0x34cc, 0x45fa, 0x97, 0xfb, 0xd0, 0x07, 0xfa, 0x47, 0xec, 0x94), 1001);
	public const PROPERTYKEY WPD_PROPERTY_STORAGE_DESTINATION_OBJECT_ID = .(.(0xd8f907a6, 0x34cc, 0x45fa, 0x97, 0xfb, 0xd0, 0x07, 0xfa, 0x47, 0xec, 0x94), 1002);
	public const Guid WPD_CATEGORY_SMS = .(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1);
	public const PROPERTYKEY WPD_COMMAND_SMS_SEND = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 2);
	public const PROPERTYKEY WPD_PROPERTY_SMS_RECIPIENT = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 1001);
	public const PROPERTYKEY WPD_PROPERTY_SMS_MESSAGE_TYPE = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 1002);
	public const PROPERTYKEY WPD_PROPERTY_SMS_TEXT_MESSAGE = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 1003);
	public const PROPERTYKEY WPD_PROPERTY_SMS_BINARY_MESSAGE = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 1004);
	public const PROPERTYKEY WPD_OPTION_SMS_BINARY_MESSAGE_SUPPORTED = .(.(0xafc25d66, 0xfe0d, 0x4114, 0x90, 0x97, 0x97, 0x0c, 0x93, 0xe9, 0x20, 0xd1), 5001);
	public const Guid WPD_CATEGORY_STILL_IMAGE_CAPTURE = .(0x4fcd6982, 0x22a2, 0x4b05, 0xa4, 0x8b, 0x62, 0xd3, 0x8b, 0xf2, 0x7b, 0x32);
	public const PROPERTYKEY WPD_COMMAND_STILL_IMAGE_CAPTURE_INITIATE = .(.(0x4fcd6982, 0x22a2, 0x4b05, 0xa4, 0x8b, 0x62, 0xd3, 0x8b, 0xf2, 0x7b, 0x32), 2);
	public const Guid WPD_CATEGORY_MEDIA_CAPTURE = .(0x59b433ba, 0xfe44, 0x4d8d, 0x80, 0x8c, 0x6b, 0xcb, 0x9b, 0x0f, 0x15, 0xe8);
	public const PROPERTYKEY WPD_COMMAND_MEDIA_CAPTURE_START = .(.(0x59b433ba, 0xfe44, 0x4d8d, 0x80, 0x8c, 0x6b, 0xcb, 0x9b, 0x0f, 0x15, 0xe8), 2);
	public const PROPERTYKEY WPD_COMMAND_MEDIA_CAPTURE_STOP = .(.(0x59b433ba, 0xfe44, 0x4d8d, 0x80, 0x8c, 0x6b, 0xcb, 0x9b, 0x0f, 0x15, 0xe8), 3);
	public const PROPERTYKEY WPD_COMMAND_MEDIA_CAPTURE_PAUSE = .(.(0x59b433ba, 0xfe44, 0x4d8d, 0x80, 0x8c, 0x6b, 0xcb, 0x9b, 0x0f, 0x15, 0xe8), 4);
	public const Guid WPD_CATEGORY_DEVICE_HINTS = .(0x0d5fb92b, 0xcb46, 0x4c4f, 0x83, 0x43, 0x0b, 0xc3, 0xd3, 0xf1, 0x7c, 0x84);
	public const PROPERTYKEY WPD_COMMAND_DEVICE_HINTS_GET_CONTENT_LOCATION = .(.(0x0d5fb92b, 0xcb46, 0x4c4f, 0x83, 0x43, 0x0b, 0xc3, 0xd3, 0xf1, 0x7c, 0x84), 2);
	public const PROPERTYKEY WPD_PROPERTY_DEVICE_HINTS_CONTENT_TYPE = .(.(0x0d5fb92b, 0xcb46, 0x4c4f, 0x83, 0x43, 0x0b, 0xc3, 0xd3, 0xf1, 0x7c, 0x84), 1001);
	public const PROPERTYKEY WPD_PROPERTY_DEVICE_HINTS_CONTENT_LOCATIONS = .(.(0x0d5fb92b, 0xcb46, 0x4c4f, 0x83, 0x43, 0x0b, 0xc3, 0xd3, 0xf1, 0x7c, 0x84), 1002);
	public const Guid WPD_CLASS_EXTENSION_V1 = .(0x33fb0d11, 0x64a3, 0x4fac, 0xb4, 0xc7, 0x3d, 0xfe, 0xaa, 0x99, 0xb0, 0x51);
	public const PROPERTYKEY WPD_COMMAND_CLASS_EXTENSION_WRITE_DEVICE_INFORMATION = .(.(0x33fb0d11, 0x64a3, 0x4fac, 0xb4, 0xc7, 0x3d, 0xfe, 0xaa, 0x99, 0xb0, 0x51), 2);
	public const PROPERTYKEY WPD_PROPERTY_CLASS_EXTENSION_DEVICE_INFORMATION_VALUES = .(.(0x33fb0d11, 0x64a3, 0x4fac, 0xb4, 0xc7, 0x3d, 0xfe, 0xaa, 0x99, 0xb0, 0x51), 1001);
	public const PROPERTYKEY WPD_PROPERTY_CLASS_EXTENSION_DEVICE_INFORMATION_WRITE_RESULTS = .(.(0x33fb0d11, 0x64a3, 0x4fac, 0xb4, 0xc7, 0x3d, 0xfe, 0xaa, 0x99, 0xb0, 0x51), 1002);
	public const Guid WPD_CLASS_EXTENSION_V2 = .(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58);
	public const PROPERTYKEY WPD_COMMAND_CLASS_EXTENSION_REGISTER_SERVICE_INTERFACES = .(.(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58), 2);
	public const PROPERTYKEY WPD_COMMAND_CLASS_EXTENSION_UNREGISTER_SERVICE_INTERFACES = .(.(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58), 3);
	public const PROPERTYKEY WPD_PROPERTY_CLASS_EXTENSION_SERVICE_OBJECT_ID = .(.(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58), 1001);
	public const PROPERTYKEY WPD_PROPERTY_CLASS_EXTENSION_SERVICE_INTERFACES = .(.(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58), 1002);
	public const PROPERTYKEY WPD_PROPERTY_CLASS_EXTENSION_SERVICE_REGISTRATION_RESULTS = .(.(0x7f0779b5, 0xfa2b, 0x4766, 0x9c, 0xb2, 0xf7, 0x3b, 0xa3, 0x0b, 0x67, 0x58), 1003);
	public const Guid WPD_CATEGORY_NETWORK_CONFIGURATION = .(0x78f9c6fc, 0x79b8, 0x473c, 0x90, 0x60, 0x6b, 0xd2, 0x3d, 0xd0, 0x72, 0xc4);
	public const PROPERTYKEY WPD_COMMAND_GENERATE_KEYPAIR = .(.(0x78f9c6fc, 0x79b8, 0x473c, 0x90, 0x60, 0x6b, 0xd2, 0x3d, 0xd0, 0x72, 0xc4), 2);
	public const PROPERTYKEY WPD_COMMAND_COMMIT_KEYPAIR = .(.(0x78f9c6fc, 0x79b8, 0x473c, 0x90, 0x60, 0x6b, 0xd2, 0x3d, 0xd0, 0x72, 0xc4), 3);
	public const PROPERTYKEY WPD_COMMAND_PROCESS_WIRELESS_PROFILE = .(.(0x78f9c6fc, 0x79b8, 0x473c, 0x90, 0x60, 0x6b, 0xd2, 0x3d, 0xd0, 0x72, 0xc4), 4);
	public const PROPERTYKEY WPD_PROPERTY_PUBLIC_KEY = .(.(0x78f9c6fc, 0x79b8, 0x473c, 0x90, 0x60, 0x6b, 0xd2, 0x3d, 0xd0, 0x72, 0xc4), 1001);
	public const Guid WPD_CATEGORY_SERVICE_COMMON = .(0x322f071d, 0x36ef, 0x477f, 0xb4, 0xb5, 0x6f, 0x52, 0xd7, 0x34, 0xba, 0xee);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_COMMON_GET_SERVICE_OBJECT_ID = .(.(0x322f071d, 0x36ef, 0x477f, 0xb4, 0xb5, 0x6f, 0x52, 0xd7, 0x34, 0xba, 0xee), 2);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_OBJECT_ID = .(.(0x322f071d, 0x36ef, 0x477f, 0xb4, 0xb5, 0x6f, 0x52, 0xd7, 0x34, 0xba, 0xee), 1001);
	public const Guid WPD_CATEGORY_SERVICE_CAPABILITIES = .(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_METHODS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 2);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_METHODS_BY_FORMAT = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 3);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_METHOD_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 4);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_METHOD_PARAMETER_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 5);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_FORMATS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 6);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_FORMAT_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 7);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_FORMAT_PROPERTIES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 8);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_FORMAT_PROPERTY_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 9);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_EVENTS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 10);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_EVENT_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 11);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_EVENT_PARAMETER_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 12);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_INHERITED_SERVICES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 13);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_FORMAT_RENDERING_PROFILES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 14);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_SUPPORTED_COMMANDS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 15);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_CAPABILITIES_GET_COMMAND_OPTIONS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 16);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_SUPPORTED_METHODS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1001);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_FORMAT = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1002);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_METHOD = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1003);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_METHOD_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1004);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_PARAMETER = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1005);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_PARAMETER_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1006);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_FORMATS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1007);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_FORMAT_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1008);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_PROPERTY_KEYS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1009);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_PROPERTY_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1010);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_SUPPORTED_EVENTS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1011);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_EVENT = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1012);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_EVENT_ATTRIBUTES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1013);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_INHERITANCE_TYPE = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1014);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_INHERITED_SERVICES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1015);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_RENDERING_PROFILES = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1016);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_SUPPORTED_COMMANDS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1017);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_COMMAND = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1018);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_CAPABILITIES_COMMAND_OPTIONS = .(.(0x24457e74, 0x2e9f, 0x44f9, 0x8c, 0x57, 0x1d, 0x1b, 0xcb, 0x17, 0x0b, 0x89), 1019);
	public const Guid WPD_CATEGORY_SERVICE_METHODS = .(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_METHODS_START_INVOKE = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 2);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_METHODS_CANCEL_INVOKE = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 3);
	public const PROPERTYKEY WPD_COMMAND_SERVICE_METHODS_END_INVOKE = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 4);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_METHOD = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 1001);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_METHOD_PARAMETER_VALUES = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 1002);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_METHOD_RESULT_VALUES = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 1003);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_METHOD_CONTEXT = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 1004);
	public const PROPERTYKEY WPD_PROPERTY_SERVICE_METHOD_HRESULT = .(.(0x2d521ca8, 0xc1b0, 0x4268, 0xa3, 0x42, 0xcf, 0x19, 0x32, 0x15, 0x69, 0xbc), 1005);
	public const PROPERTYKEY WPD_RESOURCE_DEFAULT = .(.(0xe81e79be, 0x34f0, 0x41bf, 0xb5, 0x3f, 0xf1, 0xa0, 0x6a, 0xe8, 0x78, 0x42), 0);
	public const PROPERTYKEY WPD_RESOURCE_CONTACT_PHOTO = .(.(0x2c4d6803, 0x80ea, 0x4580, 0xaf, 0x9a, 0x5b, 0xe1, 0xa2, 0x3e, 0xdd, 0xcb), 0);
	public const PROPERTYKEY WPD_RESOURCE_THUMBNAIL = .(.(0xc7c407ba, 0x98fa, 0x46b5, 0x99, 0x60, 0x23, 0xfe, 0xc1, 0x24, 0xcf, 0xde), 0);
	public const PROPERTYKEY WPD_RESOURCE_ICON = .(.(0xf195fed8, 0xaa28, 0x4ee3, 0xb1, 0x53, 0xe1, 0x82, 0xdd, 0x5e, 0xdc, 0x39), 0);
	public const PROPERTYKEY WPD_RESOURCE_AUDIO_CLIP = .(.(0x3bc13982, 0x85b1, 0x48e0, 0x95, 0xa6, 0x8d, 0x3a, 0xd0, 0x6b, 0xe1, 0x17), 0);
	public const PROPERTYKEY WPD_RESOURCE_ALBUM_ART = .(.(0xf02aa354, 0x2300, 0x4e2d, 0xa1, 0xb9, 0x3b, 0x67, 0x30, 0xf7, 0xfa, 0x21), 0);
	public const PROPERTYKEY WPD_RESOURCE_GENERIC = .(.(0xb9b9f515, 0xba70, 0x4647, 0x94, 0xdc, 0xfa, 0x49, 0x25, 0xe9, 0x5a, 0x07), 0);
	public const PROPERTYKEY WPD_RESOURCE_VIDEO_CLIP = .(.(0xb566ee42, 0x6368, 0x4290, 0x86, 0x62, 0x70, 0x18, 0x2f, 0xb7, 0x9f, 0x20), 0);
	public const PROPERTYKEY WPD_RESOURCE_BRANDING_ART = .(.(0xb633b1ae, 0x6caf, 0x4a87, 0x95, 0x89, 0x22, 0xde, 0xd6, 0xdd, 0x58, 0x99), 0);
	public const Guid WPD_OBJECT_FORMAT_PROPERTIES_ONLY = .(0x30010000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_UNSPECIFIED = .(0x30000000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_SCRIPT = .(0x30020000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_EXECUTABLE = .(0x30030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_TEXT = .(0x30040000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_HTML = .(0x30050000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_DPOF = .(0x30060000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AIFF = .(0x30070000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WAVE = .(0x30080000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MP3 = .(0x30090000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AVI = .(0x300a0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MPEG = .(0x300b0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ASF = .(0x300c0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_EXIF = .(0x38010000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_TIFFEP = .(0x38020000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_FLASHPIX = .(0x38030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_BMP = .(0x38040000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_CIFF = .(0x38050000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_GIF = .(0x38070000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_JFIF = .(0x38080000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_PCD = .(0x38090000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_PICT = .(0x380a0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_PNG = .(0x380b0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_TIFF = .(0x380d0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_TIFFIT = .(0x380e0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_JP2 = .(0x380f0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_JPX = .(0x38100000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WBMP = .(0xb8030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_JPEGXR = .(0xb8040000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WINDOWSIMAGEFORMAT = .(0xb8810000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WMA = .(0xb9010000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WMV = .(0xb9810000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_WPLPLAYLIST = .(0xba100000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_M3UPLAYLIST = .(0xba110000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MPLPLAYLIST = .(0xba120000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ASXPLAYLIST = .(0xba130000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_PLSPLAYLIST = .(0xba140000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ABSTRACT_CONTACT_GROUP = .(0xba060000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ABSTRACT_MEDIA_CAST = .(0xba0b0000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_VCALENDAR1 = .(0xbe020000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ICALENDAR = .(0xbe030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ABSTRACT_CONTACT = .(0xbb810000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_VCARD2 = .(0xbb820000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_VCARD3 = .(0xbb830000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_XML = .(0xba820000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AAC = .(0xb9030000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AUDIBLE = .(0xb9040000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_FLAC = .(0xb9060000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_QCELP = .(0xb9070000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AMR = .(0xb9080000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_OGG = .(0xb9020000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MP4 = .(0xb9820000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MP2 = .(0xb9830000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MICROSOFT_WORD = .(0xba830000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MHT_COMPILED_HTML = .(0xba840000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MICROSOFT_EXCEL = .(0xba850000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MICROSOFT_POWERPOINT = .(0xba860000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_3GP = .(0xb9840000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_3G2 = .(0xb9850000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_AVCHD = .(0xb9860000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_ATSCTS = .(0xb9870000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_DVBTS = .(0xb9880000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const Guid WPD_OBJECT_FORMAT_MKV = .(0xb9900000, 0xae6c, 0x4804, 0x98, 0xba, 0xc5, 0x7b, 0x46, 0x96, 0x5f, 0xe7);
	public const PROPERTYKEY WPD_OBJECT_ID = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 2);
	public const PROPERTYKEY WPD_OBJECT_PARENT_ID = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 3);
	public const PROPERTYKEY WPD_OBJECT_NAME = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 4);
	public const PROPERTYKEY WPD_OBJECT_PERSISTENT_UNIQUE_ID = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 5);
	public const PROPERTYKEY WPD_OBJECT_FORMAT = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 6);
	public const PROPERTYKEY WPD_OBJECT_ISHIDDEN = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 9);
	public const PROPERTYKEY WPD_OBJECT_ISSYSTEM = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 10);
	public const PROPERTYKEY WPD_OBJECT_SIZE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 11);
	public const PROPERTYKEY WPD_OBJECT_ORIGINAL_FILE_NAME = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 12);
	public const PROPERTYKEY WPD_OBJECT_NON_CONSUMABLE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 13);
	public const PROPERTYKEY WPD_OBJECT_KEYWORDS = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 15);
	public const PROPERTYKEY WPD_OBJECT_SYNC_ID = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 16);
	public const PROPERTYKEY WPD_OBJECT_IS_DRM_PROTECTED = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 17);
	public const PROPERTYKEY WPD_OBJECT_DATE_CREATED = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 18);
	public const PROPERTYKEY WPD_OBJECT_DATE_MODIFIED = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 19);
	public const PROPERTYKEY WPD_OBJECT_DATE_AUTHORED = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 20);
	public const PROPERTYKEY WPD_OBJECT_BACK_REFERENCES = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 21);
	public const PROPERTYKEY WPD_OBJECT_CAN_DELETE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 26);
	public const PROPERTYKEY WPD_OBJECT_LANGUAGE_LOCALE = .(.(0xef6b490d, 0x5cd8, 0x437a, 0xaf, 0xfc, 0xda, 0x8b, 0x60, 0xee, 0x4a, 0x3c), 27);
	public const Guid WPD_FOLDER_OBJECT_PROPERTIES_V1 = .(0x7e9a7abf, 0xe568, 0x4b34, 0xaa, 0x2f, 0x13, 0xbb, 0x12, 0xab, 0x17, 0x7d);
	public const PROPERTYKEY WPD_FOLDER_CONTENT_TYPES_ALLOWED = .(.(0x7e9a7abf, 0xe568, 0x4b34, 0xaa, 0x2f, 0x13, 0xbb, 0x12, 0xab, 0x17, 0x7d), 2);
	public const Guid WPD_IMAGE_OBJECT_PROPERTIES_V1 = .(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb);
	public const PROPERTYKEY WPD_IMAGE_BITDEPTH = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 3);
	public const PROPERTYKEY WPD_IMAGE_CROPPED_STATUS = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 4);
	public const PROPERTYKEY WPD_IMAGE_COLOR_CORRECTED_STATUS = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 5);
	public const PROPERTYKEY WPD_IMAGE_FNUMBER = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 6);
	public const PROPERTYKEY WPD_IMAGE_EXPOSURE_TIME = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 7);
	public const PROPERTYKEY WPD_IMAGE_EXPOSURE_INDEX = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 8);
	public const PROPERTYKEY WPD_IMAGE_HORIZONTAL_RESOLUTION = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 9);
	public const PROPERTYKEY WPD_IMAGE_VERTICAL_RESOLUTION = .(.(0x63d64908, 0x9fa1, 0x479f, 0x85, 0xba, 0x99, 0x52, 0x21, 0x64, 0x47, 0xdb), 10);
	public const Guid WPD_DOCUMENT_OBJECT_PROPERTIES_V1 = .(0x0b110203, 0xeb95, 0x4f02, 0x93, 0xe0, 0x97, 0xc6, 0x31, 0x49, 0x3a, 0xd5);
	public const Guid WPD_MEDIA_PROPERTIES_V1 = .(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8);
	public const PROPERTYKEY WPD_MEDIA_TOTAL_BITRATE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 2);
	public const PROPERTYKEY WPD_MEDIA_BITRATE_TYPE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 3);
	public const PROPERTYKEY WPD_MEDIA_COPYRIGHT = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 4);
	public const PROPERTYKEY WPD_MEDIA_SUBSCRIPTION_CONTENT_ID = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 5);
	public const PROPERTYKEY WPD_MEDIA_USE_COUNT = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 6);
	public const PROPERTYKEY WPD_MEDIA_SKIP_COUNT = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 7);
	public const PROPERTYKEY WPD_MEDIA_LAST_ACCESSED_TIME = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 8);
	public const PROPERTYKEY WPD_MEDIA_PARENTAL_RATING = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 9);
	public const PROPERTYKEY WPD_MEDIA_META_GENRE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 10);
	public const PROPERTYKEY WPD_MEDIA_COMPOSER = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 11);
	public const PROPERTYKEY WPD_MEDIA_EFFECTIVE_RATING = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 12);
	public const PROPERTYKEY WPD_MEDIA_SUB_TITLE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 13);
	public const PROPERTYKEY WPD_MEDIA_RELEASE_DATE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 14);
	public const PROPERTYKEY WPD_MEDIA_SAMPLE_RATE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 15);
	public const PROPERTYKEY WPD_MEDIA_STAR_RATING = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 16);
	public const PROPERTYKEY WPD_MEDIA_USER_EFFECTIVE_RATING = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 17);
	public const PROPERTYKEY WPD_MEDIA_TITLE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 18);
	public const PROPERTYKEY WPD_MEDIA_DURATION = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 19);
	public const PROPERTYKEY WPD_MEDIA_BUY_NOW = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 20);
	public const PROPERTYKEY WPD_MEDIA_ENCODING_PROFILE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 21);
	public const PROPERTYKEY WPD_MEDIA_WIDTH = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 22);
	public const PROPERTYKEY WPD_MEDIA_HEIGHT = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 23);
	public const PROPERTYKEY WPD_MEDIA_ARTIST = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 24);
	public const PROPERTYKEY WPD_MEDIA_ALBUM_ARTIST = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 25);
	public const PROPERTYKEY WPD_MEDIA_OWNER = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 26);
	public const PROPERTYKEY WPD_MEDIA_MANAGING_EDITOR = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 27);
	public const PROPERTYKEY WPD_MEDIA_WEBMASTER = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 28);
	public const PROPERTYKEY WPD_MEDIA_SOURCE_URL = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 29);
	public const PROPERTYKEY WPD_MEDIA_DESTINATION_URL = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 30);
	public const PROPERTYKEY WPD_MEDIA_DESCRIPTION = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 31);
	public const PROPERTYKEY WPD_MEDIA_GENRE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 32);
	public const PROPERTYKEY WPD_MEDIA_TIME_BOOKMARK = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 33);
	public const PROPERTYKEY WPD_MEDIA_OBJECT_BOOKMARK = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 34);
	public const PROPERTYKEY WPD_MEDIA_LAST_BUILD_DATE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 35);
	public const PROPERTYKEY WPD_MEDIA_BYTE_BOOKMARK = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 36);
	public const PROPERTYKEY WPD_MEDIA_TIME_TO_LIVE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 37);
	public const PROPERTYKEY WPD_MEDIA_GUID = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 38);
	public const PROPERTYKEY WPD_MEDIA_SUB_DESCRIPTION = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 39);
	public const PROPERTYKEY WPD_MEDIA_AUDIO_ENCODING_PROFILE = .(.(0x2ed8ba05, 0x0ad3, 0x42dc, 0xb0, 0xd0, 0xbc, 0x95, 0xac, 0x39, 0x6a, 0xc8), 49);
	public const Guid WPD_CONTACT_OBJECT_PROPERTIES_V1 = .(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b);
	public const PROPERTYKEY WPD_CONTACT_DISPLAY_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 2);
	public const PROPERTYKEY WPD_CONTACT_FIRST_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 3);
	public const PROPERTYKEY WPD_CONTACT_MIDDLE_NAMES = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 4);
	public const PROPERTYKEY WPD_CONTACT_LAST_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 5);
	public const PROPERTYKEY WPD_CONTACT_PREFIX = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 6);
	public const PROPERTYKEY WPD_CONTACT_SUFFIX = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 7);
	public const PROPERTYKEY WPD_CONTACT_PHONETIC_FIRST_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 8);
	public const PROPERTYKEY WPD_CONTACT_PHONETIC_LAST_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 9);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_FULL_POSTAL_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 10);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_LINE1 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 11);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_LINE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 12);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_CITY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 13);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_REGION = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 14);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_POSTAL_CODE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 15);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_POSTAL_ADDRESS_COUNTRY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 16);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_FULL_POSTAL_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 17);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_LINE1 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 18);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_LINE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 19);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_CITY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 20);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_REGION = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 21);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_POSTAL_CODE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 22);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_POSTAL_ADDRESS_COUNTRY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 23);
	public const PROPERTYKEY WPD_CONTACT_OTHER_FULL_POSTAL_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 24);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_LINE1 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 25);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_LINE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 26);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_CITY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 27);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_REGION = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 28);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_POSTAL_CODE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 29);
	public const PROPERTYKEY WPD_CONTACT_OTHER_POSTAL_ADDRESS_POSTAL_COUNTRY = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 30);
	public const PROPERTYKEY WPD_CONTACT_PRIMARY_EMAIL_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 31);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_EMAIL = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 32);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_EMAIL2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 33);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_EMAIL = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 34);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_EMAIL2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 35);
	public const PROPERTYKEY WPD_CONTACT_OTHER_EMAILS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 36);
	public const PROPERTYKEY WPD_CONTACT_PRIMARY_PHONE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 37);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_PHONE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 38);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_PHONE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 39);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_PHONE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 40);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_PHONE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 41);
	public const PROPERTYKEY WPD_CONTACT_MOBILE_PHONE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 42);
	public const PROPERTYKEY WPD_CONTACT_MOBILE_PHONE2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 43);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_FAX = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 44);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_FAX = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 45);
	public const PROPERTYKEY WPD_CONTACT_PAGER = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 46);
	public const PROPERTYKEY WPD_CONTACT_OTHER_PHONES = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 47);
	public const PROPERTYKEY WPD_CONTACT_PRIMARY_WEB_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 48);
	public const PROPERTYKEY WPD_CONTACT_PERSONAL_WEB_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 49);
	public const PROPERTYKEY WPD_CONTACT_BUSINESS_WEB_ADDRESS = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 50);
	public const PROPERTYKEY WPD_CONTACT_INSTANT_MESSENGER = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 51);
	public const PROPERTYKEY WPD_CONTACT_INSTANT_MESSENGER2 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 52);
	public const PROPERTYKEY WPD_CONTACT_INSTANT_MESSENGER3 = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 53);
	public const PROPERTYKEY WPD_CONTACT_COMPANY_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 54);
	public const PROPERTYKEY WPD_CONTACT_PHONETIC_COMPANY_NAME = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 55);
	public const PROPERTYKEY WPD_CONTACT_ROLE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 56);
	public const PROPERTYKEY WPD_CONTACT_BIRTHDATE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 57);
	public const PROPERTYKEY WPD_CONTACT_PRIMARY_FAX = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 58);
	public const PROPERTYKEY WPD_CONTACT_SPOUSE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 59);
	public const PROPERTYKEY WPD_CONTACT_CHILDREN = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 60);
	public const PROPERTYKEY WPD_CONTACT_ASSISTANT = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 61);
	public const PROPERTYKEY WPD_CONTACT_ANNIVERSARY_DATE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 62);
	public const PROPERTYKEY WPD_CONTACT_RINGTONE = .(.(0xfbd4fdab, 0x987d, 0x4777, 0xb3, 0xf9, 0x72, 0x61, 0x85, 0xa9, 0x31, 0x2b), 63);
	public const Guid WPD_MUSIC_OBJECT_PROPERTIES_V1 = .(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6);
	public const PROPERTYKEY WPD_MUSIC_ALBUM = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 3);
	public const PROPERTYKEY WPD_MUSIC_TRACK = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 4);
	public const PROPERTYKEY WPD_MUSIC_LYRICS = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 6);
	public const PROPERTYKEY WPD_MUSIC_MOOD = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 8);
	public const PROPERTYKEY WPD_AUDIO_BITRATE = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 9);
	public const PROPERTYKEY WPD_AUDIO_CHANNEL_COUNT = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 10);
	public const PROPERTYKEY WPD_AUDIO_FORMAT_CODE = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 11);
	public const PROPERTYKEY WPD_AUDIO_BIT_DEPTH = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 12);
	public const PROPERTYKEY WPD_AUDIO_BLOCK_ALIGNMENT = .(.(0xb324f56a, 0xdc5d, 0x46e5, 0xb6, 0xdf, 0xd2, 0xea, 0x41, 0x48, 0x88, 0xc6), 13);
	public const Guid WPD_VIDEO_OBJECT_PROPERTIES_V1 = .(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a);
	public const PROPERTYKEY WPD_VIDEO_AUTHOR = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 2);
	public const PROPERTYKEY WPD_VIDEO_RECORDEDTV_STATION_NAME = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 4);
	public const PROPERTYKEY WPD_VIDEO_RECORDEDTV_CHANNEL_NUMBER = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 5);
	public const PROPERTYKEY WPD_VIDEO_RECORDEDTV_REPEAT = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 7);
	public const PROPERTYKEY WPD_VIDEO_BUFFER_SIZE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 8);
	public const PROPERTYKEY WPD_VIDEO_CREDITS = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 9);
	public const PROPERTYKEY WPD_VIDEO_KEY_FRAME_DISTANCE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 10);
	public const PROPERTYKEY WPD_VIDEO_QUALITY_SETTING = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 11);
	public const PROPERTYKEY WPD_VIDEO_SCAN_TYPE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 12);
	public const PROPERTYKEY WPD_VIDEO_BITRATE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 13);
	public const PROPERTYKEY WPD_VIDEO_FOURCC_CODE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 14);
	public const PROPERTYKEY WPD_VIDEO_FRAMERATE = .(.(0x346f2163, 0xf998, 0x4146, 0x8b, 0x01, 0xd1, 0x9b, 0x4c, 0x00, 0xde, 0x9a), 15);
	public const Guid WPD_COMMON_INFORMATION_OBJECT_PROPERTIES_V1 = .(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_SUBJECT = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 2);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_BODY_TEXT = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 3);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_PRIORITY = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 4);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_START_DATETIME = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 5);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_END_DATETIME = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 6);
	public const PROPERTYKEY WPD_COMMON_INFORMATION_NOTES = .(.(0xb28ae94b, 0x05a4, 0x4e8e, 0xbe, 0x01, 0x72, 0xcc, 0x7e, 0x09, 0x9d, 0x8f), 7);
	public const Guid WPD_MEMO_OBJECT_PROPERTIES_V1 = .(0x5ffbfc7b, 0x7483, 0x41ad, 0xaf, 0xb9, 0xda, 0x3f, 0x4e, 0x59, 0x2b, 0x8d);
	public const Guid WPD_EMAIL_OBJECT_PROPERTIES_V1 = .(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5);
	public const PROPERTYKEY WPD_EMAIL_TO_LINE = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 2);
	public const PROPERTYKEY WPD_EMAIL_CC_LINE = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 3);
	public const PROPERTYKEY WPD_EMAIL_BCC_LINE = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 4);
	public const PROPERTYKEY WPD_EMAIL_HAS_BEEN_READ = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 7);
	public const PROPERTYKEY WPD_EMAIL_RECEIVED_TIME = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 8);
	public const PROPERTYKEY WPD_EMAIL_HAS_ATTACHMENTS = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 9);
	public const PROPERTYKEY WPD_EMAIL_SENDER_ADDRESS = .(.(0x41f8f65a, 0x5484, 0x4782, 0xb1, 0x3d, 0x47, 0x40, 0xdd, 0x7c, 0x37, 0xc5), 10);
	public const Guid WPD_APPOINTMENT_OBJECT_PROPERTIES_V1 = .(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3);
	public const PROPERTYKEY WPD_APPOINTMENT_LOCATION = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 3);
	public const PROPERTYKEY WPD_APPOINTMENT_TYPE = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 7);
	public const PROPERTYKEY WPD_APPOINTMENT_REQUIRED_ATTENDEES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 8);
	public const PROPERTYKEY WPD_APPOINTMENT_OPTIONAL_ATTENDEES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 9);
	public const PROPERTYKEY WPD_APPOINTMENT_ACCEPTED_ATTENDEES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 10);
	public const PROPERTYKEY WPD_APPOINTMENT_RESOURCES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 11);
	public const PROPERTYKEY WPD_APPOINTMENT_TENTATIVE_ATTENDEES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 12);
	public const PROPERTYKEY WPD_APPOINTMENT_DECLINED_ATTENDEES = .(.(0xf99efd03, 0x431d, 0x40d8, 0xa1, 0xc9, 0x4e, 0x22, 0x0d, 0x9c, 0x88, 0xd3), 13);
	public const Guid WPD_TASK_OBJECT_PROPERTIES_V1 = .(0xe354e95e, 0xd8a0, 0x4637, 0xa0, 0x3a, 0x0c, 0xb2, 0x68, 0x38, 0xdb, 0xc7);
	public const PROPERTYKEY WPD_TASK_STATUS = .(.(0xe354e95e, 0xd8a0, 0x4637, 0xa0, 0x3a, 0x0c, 0xb2, 0x68, 0x38, 0xdb, 0xc7), 6);
	public const PROPERTYKEY WPD_TASK_PERCENT_COMPLETE = .(.(0xe354e95e, 0xd8a0, 0x4637, 0xa0, 0x3a, 0x0c, 0xb2, 0x68, 0x38, 0xdb, 0xc7), 8);
	public const PROPERTYKEY WPD_TASK_REMINDER_DATE = .(.(0xe354e95e, 0xd8a0, 0x4637, 0xa0, 0x3a, 0x0c, 0xb2, 0x68, 0x38, 0xdb, 0xc7), 10);
	public const PROPERTYKEY WPD_TASK_OWNER = .(.(0xe354e95e, 0xd8a0, 0x4637, 0xa0, 0x3a, 0x0c, 0xb2, 0x68, 0x38, 0xdb, 0xc7), 11);
	public const Guid WPD_SMS_OBJECT_PROPERTIES_V1 = .(0x7e1074cc, 0x50ff, 0x4dd1, 0xa7, 0x42, 0x53, 0xbe, 0x6f, 0x09, 0x3a, 0x0d);
	public const PROPERTYKEY WPD_SMS_PROVIDER = .(.(0x7e1074cc, 0x50ff, 0x4dd1, 0xa7, 0x42, 0x53, 0xbe, 0x6f, 0x09, 0x3a, 0x0d), 2);
	public const PROPERTYKEY WPD_SMS_TIMEOUT = .(.(0x7e1074cc, 0x50ff, 0x4dd1, 0xa7, 0x42, 0x53, 0xbe, 0x6f, 0x09, 0x3a, 0x0d), 3);
	public const PROPERTYKEY WPD_SMS_MAX_PAYLOAD = .(.(0x7e1074cc, 0x50ff, 0x4dd1, 0xa7, 0x42, 0x53, 0xbe, 0x6f, 0x09, 0x3a, 0x0d), 4);
	public const PROPERTYKEY WPD_SMS_ENCODING = .(.(0x7e1074cc, 0x50ff, 0x4dd1, 0xa7, 0x42, 0x53, 0xbe, 0x6f, 0x09, 0x3a, 0x0d), 5);
	public const Guid WPD_SECTION_OBJECT_PROPERTIES_V1 = .(0x516afd2b, 0xc64e, 0x44f0, 0x98, 0xdc, 0xbe, 0xe1, 0xc8, 0x8f, 0x7d, 0x66);
	public const PROPERTYKEY WPD_SECTION_DATA_OFFSET = .(.(0x516afd2b, 0xc64e, 0x44f0, 0x98, 0xdc, 0xbe, 0xe1, 0xc8, 0x8f, 0x7d, 0x66), 2);
	public const PROPERTYKEY WPD_SECTION_DATA_LENGTH = .(.(0x516afd2b, 0xc64e, 0x44f0, 0x98, 0xdc, 0xbe, 0xe1, 0xc8, 0x8f, 0x7d, 0x66), 3);
	public const PROPERTYKEY WPD_SECTION_DATA_UNITS = .(.(0x516afd2b, 0xc64e, 0x44f0, 0x98, 0xdc, 0xbe, 0xe1, 0xc8, 0x8f, 0x7d, 0x66), 4);
	public const PROPERTYKEY WPD_SECTION_DATA_REFERENCED_OBJECT_RESOURCE = .(.(0x516afd2b, 0xc64e, 0x44f0, 0x98, 0xdc, 0xbe, 0xe1, 0xc8, 0x8f, 0x7d, 0x66), 5);
	public const String NAME_Undefined = "Undefined";
	public const String NAME_Association = "Association";
	public const String NAME_DeviceScript = "DeviceScript";
	public const String NAME_DeviceExecutable = "DeviceExecutable";
	public const String NAME_TextDocument = "TextDocument";
	public const String NAME_HTMLDocument = "HTMLDocument";
	public const String NAME_DPOFDocument = "DPOFDocument";
	public const String NAME_AIFFFile = "AIFFFile";
	public const String NAME_WAVFile = "WAVFile";
	public const String NAME_MP3File = "MP3File";
	public const String NAME_AVIFile = "AVIFile";
	public const String NAME_MPEGFile = "MPEGFile";
	public const String NAME_ASFFile = "ASFFile";
	public const String NAME_UnknownImage = "UnknownImage";
	public const String NAME_EXIFImage = "EXIFImage";
	public const String NAME_TIFFEPImage = "TIFFEPImage";
	public const String NAME_FlashPixImage = "FlashPixImage";
	public const String NAME_BMPImage = "BMPImage";
	public const String NAME_CIFFImage = "CIFFImage";
	public const String NAME_GIFImage = "GIFImage";
	public const String NAME_JFIFImage = "JFIFImage";
	public const String NAME_PCDImage = "PCDImage";
	public const String NAME_PICTImage = "PICTImage";
	public const String NAME_PNGImage = "PNGImage";
	public const String NAME_TIFFImage = "TIFFImage";
	public const String NAME_TIFFITImage = "TIFFITImage";
	public const String NAME_JP2Image = "JP2Image";
	public const String NAME_JPXImage = "JPXImage";
	public const String NAME_FirmwareFile = "FirmwareFile";
	public const String NAME_WBMPImage = "WBMPImage";
	public const String NAME_JPEGXRImage = "JPEGXRImage";
	public const String NAME_HDPhotoImage = "HDPhotoImage";
	public const String NAME_UndefinedAudio = "UndefinedAudio";
	public const String NAME_WMAFile = "WMAFile";
	public const String NAME_OGGFile = "OGGFile";
	public const String NAME_AACFile = "AACFile";
	public const String NAME_AudibleFile = "AudibleFile";
	public const String NAME_FLACFile = "FLACFile";
	public const String NAME_QCELPFile = "QCELPFile";
	public const String NAME_AMRFile = "AMRFile";
	public const String NAME_UndefinedVideo = "UndefinedVideo";
	public const String NAME_WMVFile = "WMVFile";
	public const String NAME_MPEG4File = "MPEG4File";
	public const String NAME_MPEG2File = "MPEG2File";
	public const String NAME_3GPPFile = "3GPPFile";
	public const String NAME_3GPP2File = "3GPP2File";
	public const String NAME_AVCHDFile = "AVCHDFile";
	public const String NAME_ATSCTSFile = "ATSCTSFile";
	public const String NAME_DVBTSFile = "DVBTSFile";
	public const String NAME_UndefinedCollection = "UndefinedCollection";
	public const String NAME_AbstractMultimediaAlbum = "AbstractMultimediaAlbum";
	public const String NAME_AbstractImageAlbum = "AbstractImageAlbum";
	public const String NAME_AbstractAudioAlbum = "AbstractAudioAlbum";
	public const String NAME_AbstractVideoAlbum = "AbstractVideoAlbum";
	public const String NAME_AbstractAudioVideoAlbum = "AbstractAudioVideoAlbum";
	public const String NAME_AbstractChapteredProduction = "AbstractChapteredProduction";
	public const String NAME_AbstractAudioPlaylist = "AbstractAudioPlaylist";
	public const String NAME_AbstractVideoPlaylist = "AbstractVideoPlaylist";
	public const String NAME_AbstractMediacast = "AbstractMediacast";
	public const String NAME_WPLPlaylist = "WPLPlaylist";
	public const String NAME_M3UPlaylist = "M3UPlaylist";
	public const String NAME_MPLPlaylist = "MPLPlaylist";
	public const String NAME_ASXPlaylist = "ASXPlaylist";
	public const String NAME_PSLPlaylist = "PSLPlaylist";
	public const String NAME_UndefinedDocument = "UndefinedDocument";
	public const String NAME_AbstractDocument = "AbstractDocument";
	public const String NAME_XMLDocument = "XMLDocument";
	public const String NAME_WordDocument = "WordDocument";
	public const String NAME_MHTDocument = "MHTDocument";
	public const String NAME_ExcelDocument = "ExcelDocument";
	public const String NAME_PowerPointDocument = "PowerPointDocument";
	public const String NAME_GenericObj_ObjectID = "ObjectID";
	public const String NAME_GenericObj_ReferenceParentID = "ReferenceParentID";
	public const String NAME_GenericObj_StorageID = "StorageID";
	public const String NAME_GenericObj_ObjectFormat = "ObjectFormat";
	public const String NAME_GenericObj_ProtectionStatus = "ProtectionStatus";
	public const String NAME_GenericObj_ObjectSize = "ObjectSize";
	public const String NAME_GenericObj_AssociationType = "AssociationType";
	public const String NAME_GenericObj_AssociationDesc = "AssociationDesc";
	public const String NAME_GenericObj_ObjectFileName = "ObjectFileName";
	public const String NAME_GenericObj_DateCreated = "DateCreated";
	public const String NAME_GenericObj_DateModified = "DateModified";
	public const String NAME_GenericObj_Keywords = "Keywords";
	public const String NAME_GenericObj_ParentID = "ParentID";
	public const String NAME_GenericObj_AllowedFolderContents = "AllowedFolderContents";
	public const String NAME_GenericObj_Hidden = "Hidden";
	public const String NAME_GenericObj_SystemObject = "SystemObject";
	public const String NAME_GenericObj_PersistentUID = "PersistentUID";
	public const String NAME_GenericObj_SyncID = "SyncID";
	public const String NAME_GenericObj_PropertyBag = "PropertyBag";
	public const String NAME_GenericObj_Name = "Name";
	public const String NAME_MediaObj_Artist = "Artist";
	public const String NAME_GenericObj_DateAuthored = "DateAuthored";
	public const String NAME_GenericObj_Description = "Description";
	public const String NAME_GenericObj_LanguageLocale = "LanguageLocale";
	public const String NAME_GenericObj_Copyright = "Copyright";
	public const String NAME_VideoObj_Source = "Source";
	public const String NAME_MediaObj_GeographicOrigin = "GeographicOrigin";
	public const String NAME_GenericObj_DateAdded = "DateAdded";
	public const String NAME_GenericObj_NonConsumable = "NonConsumable";
	public const String NAME_GenericObj_Corrupt = "Corrupt";
	public const String NAME_MediaObj_Width = "Width";
	public const String NAME_MediaObj_Height = "Height";
	public const String NAME_MediaObj_Duration = "Duration";
	public const String NAME_MediaObj_UserRating = "UserRating";
	public const String NAME_MediaObj_Track = "Track";
	public const String NAME_MediaObj_Genre = "Genre";
	public const String NAME_MediaObj_Credits = "Credits";
	public const String NAME_AudioObj_Lyrics = "Lyrics";
	public const String NAME_MediaObj_SubscriptionContentID = "SubscriptionContentID";
	public const String NAME_MediaObj_Producer = "Producer";
	public const String NAME_MediaObj_UseCount = "UseCount";
	public const String NAME_MediaObj_SkipCount = "SkipCount";
	public const String NAME_GenericObj_DateAccessed = "DateAccessed";
	public const String NAME_MediaObj_ParentalRating = "ParentalRating";
	public const String NAME_MediaObj_MediaType = "MediaType";
	public const String NAME_MediaObj_Composer = "Composer";
	public const String NAME_MediaObj_EffectiveRating = "EffectiveRating";
	public const String NAME_MediaObj_Subtitle = "Subtitle";
	public const String NAME_MediaObj_DateOriginalRelease = "DateOriginalRelease";
	public const String NAME_MediaObj_AlbumName = "AlbumName";
	public const String NAME_MediaObj_AlbumArtist = "AlbumArtist";
	public const String NAME_MediaObj_Mood = "Mood";
	public const String NAME_GenericObj_DRMStatus = "DRMStatus";
	public const String NAME_GenericObj_SubDescription = "SubDescription";
	public const String NAME_ImageObj_IsCropped = "IsCropped";
	public const String NAME_ImageObj_IsColorCorrected = "IsColorCorrected";
	public const String NAME_ImageObj_ImageBitDepth = "ImageBitDepth";
	public const String NAME_ImageObj_Aperature = "Aperature";
	public const String NAME_ImageObj_Exposure = "Exposure";
	public const String NAME_ImageObj_ISOSpeed = "ISOSpeed";
	public const String NAME_MediaObj_Owner = "Owner";
	public const String NAME_MediaObj_Editor = "Editor";
	public const String NAME_MediaObj_WebMaster = "WebMaster";
	public const String NAME_MediaObj_URLSource = "URLSource";
	public const String NAME_MediaObj_URLLink = "URLLink";
	public const String NAME_MediaObj_BookmarkTime = "BookmarkTime";
	public const String NAME_MediaObj_BookmarkObject = "BookmarkObject";
	public const String NAME_MediaObj_BookmarkByte = "BookmarkByte";
	public const String NAME_GenericObj_DateRevised = "DateRevised";
	public const String NAME_GenericObj_TimeToLive = "TimeToLive";
	public const String NAME_MediaObj_MediaUID = "MediaUID";
	public const String NAME_MediaObj_TotalBitRate = "TotalBitRate";
	public const String NAME_MediaObj_BitRateType = "BitRateType";
	public const String NAME_MediaObj_SampleRate = "SampleRate";
	public const String NAME_AudioObj_Channels = "Channels";
	public const String NAME_AudioObj_AudioBitDepth = "AudioBitDepth";
	public const String NAME_AudioObj_AudioBlockAlignment = "AudioBlockAlignment";
	public const String NAME_VideoObj_ScanType = "ScanType";
	public const String NAME_AudioObj_AudioFormatCode = "AudioFormatCode";
	public const String NAME_AudioObj_AudioBitRate = "AudioBitRate";
	public const String NAME_VideoObj_VideoFormatCode = "VideoFormatCode";
	public const String NAME_VideoObj_VideoBitRate = "VideoBitRate";
	public const String NAME_VideoObj_VideoFrameRate = "VideoFrameRate";
	public const String NAME_VideoObj_KeyFrameDistance = "KeyFrameDistance";
	public const String NAME_MediaObj_BufferSize = "BufferSize";
	public const String NAME_MediaObj_EncodingQuality = "EncodingQuality";
	public const String NAME_MediaObj_EncodingProfile = "EncodingProfile";
	public const String NAME_MediaObj_AudioEncodingProfile = "AudioEncodingProfile";
	public const uint32 DEVSVC_SERVICEINFO_VERSION = 100;
	public const uint32 DEVSVCTYPE_DEFAULT = 0;
	public const uint32 DEVSVCTYPE_ABSTRACT = 1;
	public const String NAME_Services_ServiceDisplayName = "ServiceDisplayName";
	public const String NAME_Services_ServiceIcon = "ServiceIcon";
	public const String NAME_Services_ServiceLocale = "ServiceLocale";
	public const String NAME_CalendarSvc = "Calendar";
	public const uint32 TYPE_CalendarSvc = 0;
	public const String NAME_CalendarSvc_SyncWindowStart = "SyncWindowStart";
	public const String NAME_CalendarSvc_SyncWindowEnd = "SyncWindowEnd";
	public const String NAME_AbstractActivity = "AbstractActivity";
	public const String NAME_AbstractActivityOccurrence = "AbstractActivityOccurrence";
	public const String NAME_VCalendar1Activity = "VCalendar1";
	public const String NAME_ICalendarActivity = "ICalendar";
	public const String NAME_CalendarObj_Location = "Location";
	public const String NAME_CalendarObj_Accepted = "Accepted";
	public const String NAME_CalendarObj_Tentative = "Tentative";
	public const String NAME_CalendarObj_Declined = "Declined";
	public const String NAME_CalendarObj_TimeZone = "TimeZone";
	public const String NAME_CalendarObj_ReminderOffset = "ReminderOffset";
	public const String NAME_CalendarObj_BusyStatus = "BusyStatus";
	public const uint32 ENUM_CalendarObj_BusyStatusFree = 0;
	public const uint32 ENUM_CalendarObj_BusyStatusBusy = 1;
	public const uint32 ENUM_CalendarObj_BusyStatusOutOfOffice = 2;
	public const uint32 ENUM_CalendarObj_BusyStatusTentative = 3;
	public const String NAME_CalendarObj_PatternStartTime = "PatternStartTime";
	public const String NAME_CalendarObj_PatternDuration = "PatternDuration";
	public const String NAME_CalendarObj_BeginDateTime = "BeginDateTime";
	public const String NAME_CalendarObj_EndDateTime = "EndDateTime";
	public const String NAME_HintsSvc = "Hints";
	public const uint32 TYPE_HintsSvc = 0;
	public const String NAME_MessageSvc = "Message";
	public const uint32 TYPE_MessageSvc = 0;
	public const String NAME_AbstractMessage = "AbstractMessage";
	public const String NAME_AbstractMessageFolder = "AbstractMessageFolder";
	public const String NAME_MessageObj_Subject = "Subject";
	public const String NAME_MessageObj_Body = "Body";
	public const String NAME_MessageObj_Priority = "Priority";
	public const uint32 ENUM_MessageObj_PriorityHighest = 2;
	public const uint32 ENUM_MessageObj_PriorityNormal = 1;
	public const uint32 ENUM_MessageObj_PriorityLowest = 0;
	public const String NAME_MessageObj_Category = "Category";
	public const String NAME_MessageObj_Sender = "Sender";
	public const String NAME_MessageObj_To = "To";
	public const String NAME_MessageObj_CC = "CC";
	public const String NAME_MessageObj_BCC = "BCC";
	public const String NAME_MessageObj_Read = "Read";
	public const uint32 ENUM_MessageObj_ReadFalse = 0;
	public const uint32 ENUM_MessageObj_ReadTrue = 255;
	public const String NAME_MessageObj_ReceivedTime = "ReceivedTime";
	public const String NAME_MessageObj_PatternOriginalDateTime = "PatternOriginalDateTime";
	public const String NAME_MessageObj_PatternType = "PatternType";
	public const uint32 ENUM_MessageObj_PatternTypeDaily = 1;
	public const uint32 ENUM_MessageObj_PatternTypeWeekly = 2;
	public const uint32 ENUM_MessageObj_PatternTypeMonthly = 3;
	public const uint32 ENUM_MessageObj_PatternTypeYearly = 4;
	public const String NAME_MessageObj_PatternValidStartDate = "PatternValidStartDate";
	public const String NAME_MessageObj_PatternValidEndDate = "PatternValidEndDate";
	public const String NAME_MessageObj_PatternPeriod = "PatternPeriod";
	public const String NAME_MessageObj_PatternDayOfWeek = "PatternDayOfWeek";
	public const uint32 FLAG_MessageObj_DayOfWeekNone = 0;
	public const uint32 FLAG_MessageObj_DayOfWeekSunday = 1;
	public const uint32 FLAG_MessageObj_DayOfWeekMonday = 2;
	public const uint32 FLAG_MessageObj_DayOfWeekTuesday = 4;
	public const uint32 FLAG_MessageObj_DayOfWeekWednesday = 8;
	public const uint32 FLAG_MessageObj_DayOfWeekThursday = 16;
	public const uint32 FLAG_MessageObj_DayOfWeekFriday = 32;
	public const uint32 FLAG_MessageObj_DayOfWeekSaturday = 64;
	public const String NAME_MessageObj_PatternDayOfMonth = "PatternDayOfMonth";
	public const uint32 RANGEMIN_MessageObj_PatternDayOfMonth = 1;
	public const uint32 RANGEMAX_MessageObj_PatternDayOfMonth = 31;
	public const uint32 RANGESTEP_MessageObj_PatternDayOfMonth = 1;
	public const String NAME_MessageObj_PatternMonthOfYear = "PatternMonthOfYear";
	public const uint32 RANGEMIN_MessageObj_PatternMonthOfYear = 1;
	public const uint32 RANGEMAX_MessageObj_PatternMonthOfYear = 12;
	public const uint32 RANGESTEP_MessageObj_PatternMonthOfYear = 1;
	public const String NAME_MessageObj_PatternInstance = "PatternInstance";
	public const uint32 ENUM_MessageObj_PatternInstanceNone = 0;
	public const uint32 ENUM_MessageObj_PatternInstanceFirst = 1;
	public const uint32 ENUM_MessageObj_PatternInstanceSecond = 2;
	public const uint32 ENUM_MessageObj_PatternInstanceThird = 3;
	public const uint32 ENUM_MessageObj_PatternInstanceFourth = 4;
	public const uint32 ENUM_MessageObj_PatternInstanceLast = 5;
	public const String NAME_MessageObj_PatternDeleteDates = "PatternDeleteDates";
	public const String NAME_DeviceMetadataSvc = "Metadata";
	public const uint32 TYPE_DeviceMetadataSvc = 0;
	public const String NAME_DeviceMetadataCAB = "DeviceMetadataCAB";
	public const String NAME_DeviceMetadataObj_ContentID = "ContentID";
	public const String NAME_DeviceMetadataObj_DefaultCAB = "DefaultCAB";
	public const uint32 ENUM_DeviceMetadataObj_DefaultCABFalse = 0;
	public const uint32 ENUM_DeviceMetadataObj_DefaultCABTrue = 1;
	public const String NAME_NotesSvc = "Notes";
	public const uint32 TYPE_NotesSvc = 0;
	public const String NAME_AbstractNote = "AbstractNote";
	public const String NAME_StatusSvc = "Status";
	public const uint32 TYPE_StatusSvc = 0;
	public const String NAME_StatusSvc_SignalStrength = "SignalStrength";
	public const uint32 RANGEMIN_StatusSvc_SignalStrength = 0;
	public const uint32 RANGEMAX_StatusSvc_SignalStrength = 4;
	public const uint32 RANGESTEP_StatusSvc_SignalStrength = 1;
	public const String NAME_StatusSvc_TextMessages = "TextMessages";
	public const uint32 RANGEMAX_StatusSvc_TextMessages = 255;
	public const String NAME_StatusSvc_NewPictures = "NewPictures";
	public const uint32 RANGEMAX_StatusSvc_NewPictures = 65535;
	public const String NAME_StatusSvc_MissedCalls = "MissedCalls";
	public const uint32 RANGEMAX_StatusSvc_MissedCalls = 255;
	public const String NAME_StatusSvc_VoiceMail = "VoiceMail";
	public const uint32 RANGEMAX_StatusSvc_VoiceMail = 255;
	public const String NAME_StatusSvc_NetworkName = "NetworkName";
	public const String NAME_StatusSvc_NetworkType = "NetworkType";
	public const String NAME_StatusSvc_Roaming = "Roaming";
	public const uint32 ENUM_StatusSvc_RoamingInactive = 0;
	public const uint32 ENUM_StatusSvc_RoamingActive = 1;
	public const uint32 ENUM_StatusSvc_RoamingUnknown = 2;
	public const String NAME_StatusSvc_BatteryLife = "BatteryLife";
	public const uint32 RANGEMIN_StatusSvc_BatteryLife = 0;
	public const uint32 RANGEMAX_StatusSvc_BatteryLife = 100;
	public const uint32 RANGESTEP_StatusSvc_BatteryLife = 1;
	public const String NAME_StatusSvc_ChargingState = "ChargingState";
	public const uint32 ENUM_StatusSvc_ChargingInactive = 0;
	public const uint32 ENUM_StatusSvc_ChargingActive = 1;
	public const uint32 ENUM_StatusSvc_ChargingUnknown = 2;
	public const String NAME_StatusSvc_StorageCapacity = "StorageCapacity";
	public const String NAME_StatusSvc_StorageFreeSpace = "StorageFreeSpace";
	public const String NAME_SyncSvc_SyncFormat = "SyncFormat";
	public const String NAME_SyncSvc_LocalOnlyDelete = "LocalOnlyDelete";
	public const String NAME_SyncSvc_FilterType = "FilterType";
	public const uint32 SYNCSVC_FILTER_NONE = 0;
	public const uint32 SYNCSVC_FILTER_CONTACTS_WITH_PHONE = 1;
	public const uint32 SYNCSVC_FILTER_TASK_ACTIVE = 2;
	public const uint32 SYNCSVC_FILTER_CALENDAR_WINDOW_WITH_RECURRENCE = 3;
	public const String NAME_SyncSvc_SyncObjectReferences = "SyncObjectReferences";
	public const uint32 ENUM_SyncSvc_SyncObjectReferencesDisabled = 0;
	public const uint32 ENUM_SyncSvc_SyncObjectReferencesEnabled = 255;
	public const String NAME_SyncObj_LastAuthorProxyID = "LastAuthorProxyID";
	public const String NAME_SyncSvc_BeginSync = "BeginSync";
	public const String NAME_SyncSvc_EndSync = "EndSync";
	public const String NAME_TasksSvc = "Tasks";
	public const uint32 TYPE_TasksSvc = 0;
	public const String NAME_TasksSvc_SyncActiveOnly = "FilterType";
	public const String NAME_AbstractTask = "AbstractTask";
	public const String NAME_TaskObj_ReminderDateTime = "ReminderDateTime";
	public const String NAME_TaskObj_Complete = "Complete";
	public const uint32 ENUM_TaskObj_CompleteFalse = 0;
	public const uint32 ENUM_TaskObj_CompleteTrue = 255;
	public const String NAME_TaskObj_BeginDate = "BeginDate";
	public const String NAME_TaskObj_EndDate = "EndDate";
	public const Guid WPD_CATEGORY_MTP_EXT_VENDOR_OPERATIONS = .(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_GET_SUPPORTED_VENDOR_OPCODES = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 11);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_EXECUTE_COMMAND_WITHOUT_DATA_PHASE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 12);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_EXECUTE_COMMAND_WITH_DATA_TO_READ = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 13);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_EXECUTE_COMMAND_WITH_DATA_TO_WRITE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 14);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_READ_DATA = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 15);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_WRITE_DATA = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 16);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_END_DATA_TRANSFER = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 17);
	public const PROPERTYKEY WPD_COMMAND_MTP_EXT_GET_VENDOR_EXTENSION_DESCRIPTION = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 18);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_OPERATION_CODE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1001);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_OPERATION_PARAMS = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1002);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_RESPONSE_CODE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1003);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_RESPONSE_PARAMS = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1004);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_VENDOR_OPERATION_CODES = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1005);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_CONTEXT = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1006);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_TOTAL_DATA_SIZE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1007);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_NUM_BYTES_TO_READ = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1008);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_NUM_BYTES_READ = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1009);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_NUM_BYTES_TO_WRITE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1010);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_NUM_BYTES_WRITTEN = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1011);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_TRANSFER_DATA = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1012);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_OPTIMAL_TRANSFER_BUFFER_SIZE = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1013);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_VENDOR_EXTENSION_DESCRIPTION = .(.(0x4d545058, 0x1a2e, 0x4106, 0xa3, 0x57, 0x77, 0x1e, 0x08, 0x19, 0xfc, 0x56), 1014);
	public const Guid WPD_PROPERTIES_MTP_VENDOR_EXTENDED_OBJECT_PROPS = .(0x4d545058, 0x4fce, 0x4578, 0x95, 0xc8, 0x86, 0x98, 0xa9, 0xbc, 0x0f, 0x49);
	public const Guid WPD_PROPERTIES_MTP_VENDOR_EXTENDED_DEVICE_PROPS = .(0x4d545058, 0x8900, 0x40b3, 0x8f, 0x1d, 0xdc, 0x24, 0x6e, 0x1e, 0x83, 0x70);
	public const Guid WPD_EVENT_MTP_VENDOR_EXTENDED_EVENTS = .(0x00000000, 0x5738, 0x4ff2, 0x84, 0x45, 0xbe, 0x31, 0x26, 0x69, 0x10, 0x59);
	public const PROPERTYKEY WPD_PROPERTY_MTP_EXT_EVENT_PARAMS = .(.(0x4d545058, 0xef88, 0x4e4d, 0x95, 0xc3, 0x4f, 0x32, 0x7f, 0x72, 0x8a, 0x96), 1011);
	public const Guid CLSID_WPD_NAMESPACE_EXTENSION = .(0x35786d3c, 0xb075, 0x49b9, 0x88, 0xdd, 0x02, 0x98, 0x76, 0xe1, 0x1c, 0x01);
	public const Guid WPDNSE_OBJECT_PROPERTIES_V1 = .(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6);
	public const PROPERTYKEY WPDNSE_OBJECT_HAS_CONTACT_PHOTO = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 2);
	public const PROPERTYKEY WPDNSE_OBJECT_HAS_THUMBNAIL = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 3);
	public const PROPERTYKEY WPDNSE_OBJECT_HAS_ICON = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 4);
	public const PROPERTYKEY WPDNSE_OBJECT_HAS_AUDIO_CLIP = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 5);
	public const PROPERTYKEY WPDNSE_OBJECT_HAS_ALBUM_ART = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 6);
	public const PROPERTYKEY WPDNSE_OBJECT_OPTIMAL_READ_BLOCK_SIZE = .(.(0x34d71409, 0x4b47, 0x4d80, 0xaa, 0xac, 0x3a, 0x28, 0xa4, 0xa3, 0xb3, 0xe6), 7);
	public const uint32 WPDNSE_PROPSHEET_DEVICE_GENERAL = 1;
	public const uint32 WPDNSE_PROPSHEET_STORAGE_GENERAL = 2;
	public const uint32 WPDNSE_PROPSHEET_CONTENT_GENERAL = 4;
	public const uint32 WPDNSE_PROPSHEET_CONTENT_REFERENCES = 8;
	public const uint32 WPDNSE_PROPSHEET_CONTENT_RESOURCES = 16;
	public const uint32 WPDNSE_PROPSHEET_CONTENT_DETAILS = 32;
	public const String STR_WPDNSE_FAST_ENUM = "WPDNSE Fast Enum";
	public const String STR_WPDNSE_SIMPLE_ITEM = "WPDNSE SimpleItem";
	public const String NAME_ContactsSvc = "Contacts";
	public const uint32 TYPE_ContactsSvc = 0;
	public const String NAME_ContactSvc_SyncWithPhoneOnly = "FilterType";
	public const String NAME_AbstractContact = "AbstractContact";
	public const String NAME_VCard2Contact = "VCard2Contact";
	public const String NAME_VCard3Contact = "VCard3Contact";
	public const String NAME_AbstractContactGroup = "AbstractContactGroup";
	public const String NAME_ContactObj_GivenName = "GivenName";
	public const String NAME_ContactObj_MiddleNames = "MiddleNames";
	public const String NAME_ContactObj_FamilyName = "FamilyName";
	public const String NAME_ContactObj_Title = "Title";
	public const String NAME_ContactObj_Suffix = "Suffix";
	public const String NAME_ContactObj_PhoneticGivenName = "PhoneticGivenName";
	public const String NAME_ContactObj_PhoneticFamilyName = "PhoneticFamilyName";
	public const String NAME_ContactObj_PersonalAddressFull = "PersonalAddressFull";
	public const String NAME_ContactObj_PersonalAddressStreet = "PersonalAddressStreet";
	public const String NAME_ContactObj_PersonalAddressLine2 = "PersonalAddressLine2";
	public const String NAME_ContactObj_PersonalAddressCity = "PersonalAddressCity";
	public const String NAME_ContactObj_PersonalAddressRegion = "PersonalAddressRegion";
	public const String NAME_ContactObj_PersonalAddressPostalCode = "PersonalAddressPostalCode";
	public const String NAME_ContactObj_PersonalAddressCountry = "PersonalAddressCountry";
	public const String NAME_ContactObj_BusinessAddressFull = "BusinessAddressFull";
	public const String NAME_ContactObj_BusinessAddressStreet = "BusinessAddressStreet";
	public const String NAME_ContactObj_BusinessAddressLine2 = "BusinessAddressLine2";
	public const String NAME_ContactObj_BusinessAddressCity = "BusinessAddressCity";
	public const String NAME_ContactObj_BusinessAddressRegion = "BusinessAddressRegion";
	public const String NAME_ContactObj_BusinessAddressPostalCode = "BusinessAddressPostalCode";
	public const String NAME_ContactObj_BusinessAddressCountry = "BusinessAddressCountry";
	public const String NAME_ContactObj_OtherAddressFull = "OtherAddressFull";
	public const String NAME_ContactObj_OtherAddressStreet = "OtherAddressStreet";
	public const String NAME_ContactObj_OtherAddressLine2 = "OtherAddressLine2";
	public const String NAME_ContactObj_OtherAddressCity = "OtherAddressCity";
	public const String NAME_ContactObj_OtherAddressRegion = "OtherAddressRegion";
	public const String NAME_ContactObj_OtherAddressPostalCode = "OtherAddressPostalCode";
	public const String NAME_ContactObj_OtherAddressCountry = "OtherAddressCountry";
	public const String NAME_ContactObj_Email = "Email";
	public const String NAME_ContactObj_PersonalEmail = "PersonalEmail";
	public const String NAME_ContactObj_PersonalEmail2 = "PersonalEmail2";
	public const String NAME_ContactObj_BusinessEmail = "BusinessEmail";
	public const String NAME_ContactObj_BusinessEmail2 = "BusinessEmail2";
	public const String NAME_ContactObj_OtherEmail = "OtherEmail";
	public const String NAME_ContactObj_Phone = "Phone";
	public const String NAME_ContactObj_PersonalPhone = "PersonalPhone";
	public const String NAME_ContactObj_PersonalPhone2 = "PersonalPhone2";
	public const String NAME_ContactObj_BusinessPhone = "BusinessPhone";
	public const String NAME_ContactObj_BusinessPhone2 = "BusinessPhone2";
	public const String NAME_ContactObj_MobilePhone = "MobilePhone";
	public const String NAME_ContactObj_MobilePhone2 = "MobilePhone2";
	public const String NAME_ContactObj_PersonalFax = "PersonalFax";
	public const String NAME_ContactObj_BusinessFax = "BusinessFax";
	public const String NAME_ContactObj_Pager = "Pager";
	public const String NAME_ContactObj_OtherPhone = "OtherPhone";
	public const String NAME_ContactObj_WebAddress = "WebAddress";
	public const String NAME_ContactObj_PersonalWebAddress = "PersonalWebAddress";
	public const String NAME_ContactObj_BusinessWebAddress = "BusinessWebAddress";
	public const String NAME_ContactObj_IMAddress = "IMAddress";
	public const String NAME_ContactObj_IMAddress2 = "IMAddress2";
	public const String NAME_ContactObj_IMAddress3 = "IMAddress3";
	public const String NAME_ContactObj_Organization = "Organization";
	public const String NAME_ContactObj_PhoneticOrganization = "PhoneticOrganization";
	public const String NAME_ContactObj_Role = "Role";
	public const String NAME_ContactObj_Fax = "Fax";
	public const String NAME_ContactObj_Spouse = "Spouse";
	public const String NAME_ContactObj_Children = "Children";
	public const String NAME_ContactObj_Assistant = "Assistant";
	public const String NAME_ContactObj_Ringtone = "Ringtone";
	public const String NAME_ContactObj_Birthdate = "Birthdate";
	public const String NAME_ContactObj_AnniversaryDate = "AnniversaryDate";
	public const String NAME_RingtonesSvc = "Ringtones";
	public const uint32 TYPE_RingtonesSvc = 0;
	public const String NAME_RingtonesSvc_DefaultRingtone = "DefaultRingtone";
	public const String NAME_AnchorSyncSvc = "AnchorSync";
	public const uint32 TYPE_AnchorSyncSvc = 1;
	public const String NAME_AnchorSyncSvc_VersionProps = "AnchorVersionProps";
	public const String NAME_AnchorSyncSvc_ReplicaID = "AnchorReplicaID";
	public const String NAME_AnchorSyncSvc_KnowledgeObjectID = "AnchorKnowledgeObjectID";
	public const String NAME_AnchorSyncSvc_LastSyncProxyID = "AnchorLastSyncProxyID";
	public const String NAME_AnchorSyncSvc_CurrentAnchor = "AnchorCurrentAnchor";
	public const String NAME_AnchorSyncSvc_ProviderVersion = "AnchorProviderVersion";
	public const String NAME_AnchorSyncSvc_SyncFormat = "SyncFormat";
	public const String NAME_AnchorSyncSvc_LocalOnlyDelete = "LocalOnlyDelete";
	public const String NAME_AnchorSyncSvc_FilterType = "FilterType";
	public const String NAME_AnchorSyncKnowledge = "AnchorSyncKnowledge";
	public const String NAME_AnchorResults = "AnchorResults";
	public const String NAME_AnchorResults_AnchorState = "AnchorState";
	public const uint32 ENUM_AnchorResults_AnchorStateNormal = 0;
	public const uint32 ENUM_AnchorResults_AnchorStateInvalid = 1;
	public const uint32 ENUM_AnchorResults_AnchorStateOld = 2;
	public const String NAME_AnchorResults_Anchor = "Anchor";
	public const String NAME_AnchorResults_ResultObjectID = "ResultObjectID";
	public const String NAME_AnchorSyncSvc_GetChangesSinceAnchor = "GetChangesSinceAnchor";
	public const String NAME_AnchorSyncSvc_BeginSync = "BeginSync";
	public const String NAME_AnchorSyncSvc_EndSync = "EndSync";
	public const uint32 ENUM_AnchorResults_ItemStateInvalid = 0;
	public const uint32 ENUM_AnchorResults_ItemStateDeleted = 1;
	public const uint32 ENUM_AnchorResults_ItemStateCreated = 2;
	public const uint32 ENUM_AnchorResults_ItemStateUpdated = 3;
	public const uint32 ENUM_AnchorResults_ItemStateChanged = 4;
	public const String NAME_FullEnumSyncSvc = "FullEnumSync";
	public const uint32 TYPE_FullEnumSyncSvc = 1;
	public const String NAME_FullEnumSyncSvc_VersionProps = "FullEnumVersionProps";
	public const String NAME_FullEnumSyncSvc_ReplicaID = "FullEnumReplicaID";
	public const String NAME_FullEnumSyncSvc_KnowledgeObjectID = "FullEnumKnowledgeObjectID";
	public const String NAME_FullEnumSyncSvc_LastSyncProxyID = "FullEnumLastSyncProxyID";
	public const String NAME_FullEnumSyncSvc_ProviderVersion = "FullEnumProviderVersion";
	public const String NAME_FullEnumSyncSvc_SyncFormat = "SyncFormat";
	public const String NAME_FullEnumSyncSvc_LocalOnlyDelete = "LocalOnlyDelete";
	public const String NAME_FullEnumSyncSvc_FilterType = "FilterType";
	public const String NAME_FullEnumSyncKnowledge = "FullEnumSyncKnowledge";
	public const String NAME_FullEnumSyncSvc_BeginSync = "BeginSync";
	public const String NAME_FullEnumSyncSvc_EndSync = "EndSync";
}
#endregion

#region Enums

[AllowDuplicates]
public enum DELETE_OBJECT_OPTIONS : int32
{
	PORTABLE_DEVICE_DELETE_NO_RECURSION = 0,
	PORTABLE_DEVICE_DELETE_WITH_RECURSION = 1,
}


[AllowDuplicates]
public enum WPD_DEVICE_TYPES : int32
{
	WPD_DEVICE_TYPE_GENERIC = 0,
	WPD_DEVICE_TYPE_CAMERA = 1,
	WPD_DEVICE_TYPE_MEDIA_PLAYER = 2,
	WPD_DEVICE_TYPE_PHONE = 3,
	WPD_DEVICE_TYPE_VIDEO = 4,
	WPD_DEVICE_TYPE_PERSONAL_INFORMATION_MANAGER = 5,
	WPD_DEVICE_TYPE_AUDIO_RECORDER = 6,
}


[AllowDuplicates]
public enum WpdAttributeForm : int32
{
	WPD_PROPERTY_ATTRIBUTE_FORM_UNSPECIFIED = 0,
	WPD_PROPERTY_ATTRIBUTE_FORM_RANGE = 1,
	WPD_PROPERTY_ATTRIBUTE_FORM_ENUMERATION = 2,
	WPD_PROPERTY_ATTRIBUTE_FORM_REGULAR_EXPRESSION = 3,
	WPD_PROPERTY_ATTRIBUTE_FORM_OBJECT_IDENTIFIER = 4,
}


[AllowDuplicates]
public enum WpdParameterAttributeForm : int32
{
	WPD_PARAMETER_ATTRIBUTE_FORM_UNSPECIFIED = 0,
	WPD_PARAMETER_ATTRIBUTE_FORM_RANGE = 1,
	WPD_PARAMETER_ATTRIBUTE_FORM_ENUMERATION = 2,
	WPD_PARAMETER_ATTRIBUTE_FORM_REGULAR_EXPRESSION = 3,
	WPD_PARAMETER_ATTRIBUTE_FORM_OBJECT_IDENTIFIER = 4,
}


[AllowDuplicates]
public enum WPD_DEVICE_TRANSPORTS : int32
{
	WPD_DEVICE_TRANSPORT_UNSPECIFIED = 0,
	WPD_DEVICE_TRANSPORT_USB = 1,
	WPD_DEVICE_TRANSPORT_IP = 2,
	WPD_DEVICE_TRANSPORT_BLUETOOTH = 3,
}


[AllowDuplicates]
public enum WPD_STORAGE_TYPE_VALUES : int32
{
	WPD_STORAGE_TYPE_UNDEFINED = 0,
	WPD_STORAGE_TYPE_FIXED_ROM = 1,
	WPD_STORAGE_TYPE_REMOVABLE_ROM = 2,
	WPD_STORAGE_TYPE_FIXED_RAM = 3,
	WPD_STORAGE_TYPE_REMOVABLE_RAM = 4,
}


[AllowDuplicates]
public enum WPD_STORAGE_ACCESS_CAPABILITY_VALUES : int32
{
	WPD_STORAGE_ACCESS_CAPABILITY_READWRITE = 0,
	WPD_STORAGE_ACCESS_CAPABILITY_READ_ONLY_WITHOUT_OBJECT_DELETION = 1,
	WPD_STORAGE_ACCESS_CAPABILITY_READ_ONLY_WITH_OBJECT_DELETION = 2,
}


[AllowDuplicates]
public enum WPD_SMS_ENCODING_TYPES : int32
{
	SMS_ENCODING_7_BIT = 0,
	SMS_ENCODING_8_BIT = 1,
	SMS_ENCODING_UTF_16 = 2,
}


[AllowDuplicates]
public enum SMS_MESSAGE_TYPES : int32
{
	SMS_TEXT_MESSAGE = 0,
	SMS_BINARY_MESSAGE = 1,
}


[AllowDuplicates]
public enum WPD_POWER_SOURCES : int32
{
	WPD_POWER_SOURCE_BATTERY = 0,
	WPD_POWER_SOURCE_EXTERNAL = 1,
}


[AllowDuplicates]
public enum WPD_WHITE_BALANCE_SETTINGS : int32
{
	WPD_WHITE_BALANCE_UNDEFINED = 0,
	WPD_WHITE_BALANCE_MANUAL = 1,
	WPD_WHITE_BALANCE_AUTOMATIC = 2,
	WPD_WHITE_BALANCE_ONE_PUSH_AUTOMATIC = 3,
	WPD_WHITE_BALANCE_DAYLIGHT = 4,
	WPD_WHITE_BALANCE_FLORESCENT = 5,
	WPD_WHITE_BALANCE_TUNGSTEN = 6,
	WPD_WHITE_BALANCE_FLASH = 7,
}


[AllowDuplicates]
public enum WPD_FOCUS_MODES : int32
{
	WPD_FOCUS_UNDEFINED = 0,
	WPD_FOCUS_MANUAL = 1,
	WPD_FOCUS_AUTOMATIC = 2,
	WPD_FOCUS_AUTOMATIC_MACRO = 3,
}


[AllowDuplicates]
public enum WPD_EXPOSURE_METERING_MODES : int32
{
	WPD_EXPOSURE_METERING_MODE_UNDEFINED = 0,
	WPD_EXPOSURE_METERING_MODE_AVERAGE = 1,
	WPD_EXPOSURE_METERING_MODE_CENTER_WEIGHTED_AVERAGE = 2,
	WPD_EXPOSURE_METERING_MODE_MULTI_SPOT = 3,
	WPD_EXPOSURE_METERING_MODE_CENTER_SPOT = 4,
}


[AllowDuplicates]
public enum WPD_FLASH_MODES : int32
{
	WPD_FLASH_MODE_UNDEFINED = 0,
	WPD_FLASH_MODE_AUTO = 1,
	WPD_FLASH_MODE_OFF = 2,
	WPD_FLASH_MODE_FILL = 3,
	WPD_FLASH_MODE_RED_EYE_AUTO = 4,
	WPD_FLASH_MODE_RED_EYE_FILL = 5,
	WPD_FLASH_MODE_EXTERNAL_SYNC = 6,
}


[AllowDuplicates]
public enum WPD_EXPOSURE_PROGRAM_MODES : int32
{
	WPD_EXPOSURE_PROGRAM_MODE_UNDEFINED = 0,
	WPD_EXPOSURE_PROGRAM_MODE_MANUAL = 1,
	WPD_EXPOSURE_PROGRAM_MODE_AUTO = 2,
	WPD_EXPOSURE_PROGRAM_MODE_APERTURE_PRIORITY = 3,
	WPD_EXPOSURE_PROGRAM_MODE_SHUTTER_PRIORITY = 4,
	WPD_EXPOSURE_PROGRAM_MODE_CREATIVE = 5,
	WPD_EXPOSURE_PROGRAM_MODE_ACTION = 6,
	WPD_EXPOSURE_PROGRAM_MODE_PORTRAIT = 7,
}


[AllowDuplicates]
public enum WPD_CAPTURE_MODES : int32
{
	WPD_CAPTURE_MODE_UNDEFINED = 0,
	WPD_CAPTURE_MODE_NORMAL = 1,
	WPD_CAPTURE_MODE_BURST = 2,
	WPD_CAPTURE_MODE_TIMELAPSE = 3,
}


[AllowDuplicates]
public enum WPD_EFFECT_MODES : int32
{
	WPD_EFFECT_MODE_UNDEFINED = 0,
	WPD_EFFECT_MODE_COLOR = 1,
	WPD_EFFECT_MODE_BLACK_AND_WHITE = 2,
	WPD_EFFECT_MODE_SEPIA = 3,
}


[AllowDuplicates]
public enum WPD_FOCUS_METERING_MODES : int32
{
	WPD_FOCUS_METERING_MODE_UNDEFINED = 0,
	WPD_FOCUS_METERING_MODE_CENTER_SPOT = 1,
	WPD_FOCUS_METERING_MODE_MULTI_SPOT = 2,
}


[AllowDuplicates]
public enum WPD_BITRATE_TYPES : int32
{
	WPD_BITRATE_TYPE_UNUSED = 0,
	WPD_BITRATE_TYPE_DISCRETE = 1,
	WPD_BITRATE_TYPE_VARIABLE = 2,
	WPD_BITRATE_TYPE_FREE = 3,
}


[AllowDuplicates]
public enum WPD_META_GENRES : int32
{
	WPD_META_GENRE_UNUSED = 0,
	WPD_META_GENRE_GENERIC_MUSIC_AUDIO_FILE = 1,
	WPD_META_GENRE_GENERIC_NON_MUSIC_AUDIO_FILE = 17,
	WPD_META_GENRE_SPOKEN_WORD_AUDIO_BOOK_FILES = 18,
	WPD_META_GENRE_SPOKEN_WORD_FILES_NON_AUDIO_BOOK = 19,
	WPD_META_GENRE_SPOKEN_WORD_NEWS = 20,
	WPD_META_GENRE_SPOKEN_WORD_TALK_SHOWS = 21,
	WPD_META_GENRE_GENERIC_VIDEO_FILE = 33,
	WPD_META_GENRE_NEWS_VIDEO_FILE = 34,
	WPD_META_GENRE_MUSIC_VIDEO_FILE = 35,
	WPD_META_GENRE_HOME_VIDEO_FILE = 36,
	WPD_META_GENRE_FEATURE_FILM_VIDEO_FILE = 37,
	WPD_META_GENRE_TELEVISION_VIDEO_FILE = 38,
	WPD_META_GENRE_TRAINING_EDUCATIONAL_VIDEO_FILE = 39,
	WPD_META_GENRE_PHOTO_MONTAGE_VIDEO_FILE = 40,
	WPD_META_GENRE_GENERIC_NON_AUDIO_NON_VIDEO = 48,
	WPD_META_GENRE_AUDIO_PODCAST = 64,
	WPD_META_GENRE_VIDEO_PODCAST = 65,
	WPD_META_GENRE_MIXED_PODCAST = 66,
}


[AllowDuplicates]
public enum WPD_CROPPED_STATUS_VALUES : int32
{
	WPD_CROPPED_STATUS_NOT_CROPPED = 0,
	WPD_CROPPED_STATUS_CROPPED = 1,
	WPD_CROPPED_STATUS_SHOULD_NOT_BE_CROPPED = 2,
}


[AllowDuplicates]
public enum WPD_COLOR_CORRECTED_STATUS_VALUES : int32
{
	WPD_COLOR_CORRECTED_STATUS_NOT_CORRECTED = 0,
	WPD_COLOR_CORRECTED_STATUS_CORRECTED = 1,
	WPD_COLOR_CORRECTED_STATUS_SHOULD_NOT_BE_CORRECTED = 2,
}


[AllowDuplicates]
public enum WPD_VIDEO_SCAN_TYPES : int32
{
	WPD_VIDEO_SCAN_TYPE_UNUSED = 0,
	WPD_VIDEO_SCAN_TYPE_PROGRESSIVE = 1,
	WPD_VIDEO_SCAN_TYPE_FIELD_INTERLEAVED_UPPER_FIRST = 2,
	WPD_VIDEO_SCAN_TYPE_FIELD_INTERLEAVED_LOWER_FIRST = 3,
	WPD_VIDEO_SCAN_TYPE_FIELD_SINGLE_UPPER_FIRST = 4,
	WPD_VIDEO_SCAN_TYPE_FIELD_SINGLE_LOWER_FIRST = 5,
	WPD_VIDEO_SCAN_TYPE_MIXED_INTERLACE = 6,
	WPD_VIDEO_SCAN_TYPE_MIXED_INTERLACE_AND_PROGRESSIVE = 7,
}


[AllowDuplicates]
public enum WPD_OPERATION_STATES : int32
{
	WPD_OPERATION_STATE_UNSPECIFIED = 0,
	WPD_OPERATION_STATE_STARTED = 1,
	WPD_OPERATION_STATE_RUNNING = 2,
	WPD_OPERATION_STATE_PAUSED = 3,
	WPD_OPERATION_STATE_CANCELLED = 4,
	WPD_OPERATION_STATE_FINISHED = 5,
	WPD_OPERATION_STATE_ABORTED = 6,
}


[AllowDuplicates]
public enum WPD_SECTION_DATA_UNITS_VALUES : int32
{
	WPD_SECTION_DATA_UNITS_BYTES = 0,
	WPD_SECTION_DATA_UNITS_MILLISECONDS = 1,
}


[AllowDuplicates]
public enum WPD_RENDERING_INFORMATION_PROFILE_ENTRY_TYPES : int32
{
	WPD_RENDERING_INFORMATION_PROFILE_ENTRY_TYPE_OBJECT = 0,
	WPD_RENDERING_INFORMATION_PROFILE_ENTRY_TYPE_RESOURCE = 1,
}


[AllowDuplicates]
public enum WPD_COMMAND_ACCESS_TYPES : int32
{
	WPD_COMMAND_ACCESS_READ = 1,
	WPD_COMMAND_ACCESS_READWRITE = 3,
	WPD_COMMAND_ACCESS_FROM_PROPERTY_WITH_STGM_ACCESS = 4,
	WPD_COMMAND_ACCESS_FROM_PROPERTY_WITH_FILE_ACCESS = 8,
	WPD_COMMAND_ACCESS_FROM_ATTRIBUTE_WITH_METHOD_ACCESS = 16,
}


[AllowDuplicates]
public enum WPD_SERVICE_INHERITANCE_TYPES : int32
{
	WPD_SERVICE_INHERITANCE_IMPLEMENTATION = 0,
}


[AllowDuplicates]
public enum WPD_PARAMETER_USAGE_TYPES : int32
{
	WPD_PARAMETER_USAGE_RETURN = 0,
	WPD_PARAMETER_USAGE_IN = 1,
	WPD_PARAMETER_USAGE_OUT = 2,
	WPD_PARAMETER_USAGE_INOUT = 3,
}


[AllowDuplicates]
public enum WPD_STREAM_UNITS : int32
{
	WPD_STREAM_UNITS_BYTES = 0,
	WPD_STREAM_UNITS_FRAMES = 1,
	WPD_STREAM_UNITS_ROWS = 2,
	WPD_STREAM_UNITS_MILLISECONDS = 4,
	WPD_STREAM_UNITS_MICROSECONDS = 8,
}


[AllowDuplicates]
public enum DEVICE_RADIO_STATE : int32
{
	DRS_RADIO_ON = 0,
	DRS_SW_RADIO_OFF = 1,
	DRS_HW_RADIO_OFF = 2,
	DRS_SW_HW_RADIO_OFF = 3,
	DRS_HW_RADIO_ON_UNCONTROLLABLE = 4,
	DRS_RADIO_INVALID = 5,
	DRS_HW_RADIO_OFF_UNCONTROLLABLE = 6,
	DRS_RADIO_MAX = 6,
}


[AllowDuplicates]
public enum SYSTEM_RADIO_STATE : int32
{
	SRS_RADIO_ENABLED = 0,
	SRS_RADIO_DISABLED = 1,
}

#endregion


#region Structs
[CRepr]
public struct WPD_COMMAND_ACCESS_LOOKUP_ENTRY
{
	public PROPERTYKEY Command;
	public uint32 AccessType;
	public PROPERTYKEY AccessProperty;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_WpdSerializer = .(0x0b91a74b, 0xad7c, 0x4a9d, 0xb5, 0x63, 0x29, 0xee, 0xf9, 0x16, 0x71, 0x72);


	public const Guid CLSID_PortableDeviceValues = .(0x0c15d503, 0xd017, 0x47ce, 0x90, 0x16, 0x7b, 0x3f, 0x97, 0x87, 0x21, 0xcc);


	public const Guid CLSID_PortableDeviceKeyCollection = .(0xde2d022d, 0x2480, 0x43be, 0x97, 0xf0, 0xd1, 0xfa, 0x2c, 0xf9, 0x8f, 0x4f);


	public const Guid CLSID_PortableDevicePropVariantCollection = .(0x08a99e2f, 0x6d6d, 0x4b80, 0xaf, 0x5a, 0xba, 0xf2, 0xbc, 0xbe, 0x4c, 0xb9);


	public const Guid CLSID_PortableDeviceValuesCollection = .(0x3882134d, 0x14cf, 0x4220, 0x9c, 0xb4, 0x43, 0x5f, 0x86, 0xd8, 0x3f, 0x60);


	public const Guid CLSID_PortableDevice = .(0x728a21c5, 0x3d9e, 0x48d7, 0x98, 0x10, 0x86, 0x48, 0x48, 0xf0, 0xf4, 0x04);


	public const Guid CLSID_PortableDeviceManager = .(0x0af10cec, 0x2ecd, 0x4b92, 0x95, 0x81, 0x34, 0xf6, 0xae, 0x06, 0x37, 0xf3);


	public const Guid CLSID_PortableDeviceService = .(0xef5db4c2, 0x9312, 0x422c, 0x91, 0x52, 0x41, 0x1c, 0xd9, 0xc4, 0xdd, 0x84);


	public const Guid CLSID_PortableDeviceDispatchFactory = .(0x43232233, 0x8338, 0x4658, 0xae, 0x01, 0x0b, 0x4a, 0xe8, 0x30, 0xb6, 0xb0);


	public const Guid CLSID_PortableDeviceFTM = .(0xf7c0039a, 0x4762, 0x488a, 0xb4, 0xb3, 0x76, 0x0e, 0xf9, 0xa1, 0xba, 0x9b);


	public const Guid CLSID_PortableDeviceServiceFTM = .(0x1649b154, 0xc794, 0x497a, 0x9b, 0x03, 0xf3, 0xf0, 0x12, 0x13, 0x02, 0xf3);


	public const Guid CLSID_PortableDeviceWebControl = .(0x186dd02c, 0x2dec, 0x41b5, 0xa7, 0xd4, 0xb5, 0x90, 0x56, 0xfa, 0xde, 0x51);


	public const Guid CLSID_EnumBthMtpConnectors = .(0xa1570149, 0xe645, 0x4f43, 0x8b, 0x0d, 0x40, 0x9b, 0x06, 0x1d, 0xb2, 0xfc);


}
#endregion

#region COM Types
[CRepr]struct IWpdSerializer : IUnknown
{
	public new const Guid IID = .(0xb32f4002, 0xbb27, 0x45ff, 0xaf, 0x4f, 0x06, 0x63, 0x1c, 0x1e, 0x8d, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pBuffer, uint32 dwInputBufferLength, IPortableDeviceValues** ppParams) GetIPortableDeviceValuesFromBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOutputBufferLength, IPortableDeviceValues* pResults, uint8* pBuffer, uint32* pdwBytesWritten) WriteIPortableDeviceValuesToBuffer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pSource, uint8** ppBuffer, uint32* pdwBufferSize) GetBufferFromIPortableDeviceValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pSource, uint32* pdwSize) GetSerializedSize;
	}


	public HRESULT GetIPortableDeviceValuesFromBuffer(uint8* pBuffer, uint32 dwInputBufferLength, IPortableDeviceValues** ppParams) mut => VT.[Friend]GetIPortableDeviceValuesFromBuffer(&this, pBuffer, dwInputBufferLength, ppParams);

	public HRESULT WriteIPortableDeviceValuesToBuffer(uint32 dwOutputBufferLength, IPortableDeviceValues* pResults, uint8* pBuffer, uint32* pdwBytesWritten) mut => VT.[Friend]WriteIPortableDeviceValuesToBuffer(&this, dwOutputBufferLength, pResults, pBuffer, pdwBytesWritten);

	public HRESULT GetBufferFromIPortableDeviceValues(IPortableDeviceValues* pSource, uint8** ppBuffer, uint32* pdwBufferSize) mut => VT.[Friend]GetBufferFromIPortableDeviceValues(&this, pSource, ppBuffer, pdwBufferSize);

	public HRESULT GetSerializedSize(IPortableDeviceValues* pSource, uint32* pdwSize) mut => VT.[Friend]GetSerializedSize(&this, pSource, pdwSize);
}

[CRepr]struct IPortableDeviceValues : IUnknown
{
	public new const Guid IID = .(0x6848f6f2, 0x3155, 0x4f86, 0xb6, 0xf5, 0x26, 0x3e, 0xee, 0xab, 0x31, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcelt) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, PROPERTYKEY* pKey, PROPVARIANT* pValue) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* pValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* pValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PWSTR Value) SetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PWSTR* pValue) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint32 Value) SetUnsignedIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint32* pValue) GetUnsignedIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, int32 Value) SetSignedIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, int32* pValue) GetSignedIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint64 Value) SetUnsignedLargeIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint64* pValue) GetUnsignedLargeIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, int64 Value) SetSignedLargeIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, int64* pValue) GetSignedLargeIntegerValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, float Value) SetFloatValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, float* pValue) GetFloatValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, HRESULT Value) SetErrorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, HRESULT* pValue) GetErrorValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPERTYKEY* Value) SetKeyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPERTYKEY* pValue) GetKeyValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, BOOL Value) SetBoolValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, BOOL* pValue) GetBoolValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IUnknown* pValue) SetIUnknownValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IUnknown** ppValue) GetIUnknownValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, in Guid Value) SetGuidValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, Guid* pValue) GetGuidValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint8* pValue, uint32 cbValue) SetBufferValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint8** ppValue, uint32* pcbValue) GetBufferValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceValues* pValue) SetIPortableDeviceValuesValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceValues** ppValue) GetIPortableDeviceValuesValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDevicePropVariantCollection* pValue) SetIPortableDevicePropVariantCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDevicePropVariantCollection** ppValue) GetIPortableDevicePropVariantCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceKeyCollection* pValue) SetIPortableDeviceKeyCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceKeyCollection** ppValue) GetIPortableDeviceKeyCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceValuesCollection* pValue) SetIPortableDeviceValuesCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, IPortableDeviceValuesCollection** ppValue) GetIPortableDeviceValuesCollectionValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) RemoveValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pStore) CopyValuesFromPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pStore) CopyValuesToPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT GetCount(uint32* pcelt) mut => VT.[Friend]GetCount(&this, pcelt);

	public HRESULT GetAt(uint32 index, PROPERTYKEY* pKey, PROPVARIANT* pValue) mut => VT.[Friend]GetAt(&this, index, pKey, pValue);

	public HRESULT SetValue(PROPERTYKEY* key, PROPVARIANT* pValue) mut => VT.[Friend]SetValue(&this, key, pValue);

	public HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* pValue) mut => VT.[Friend]GetValue(&this, key, pValue);

	public HRESULT SetStringValue(PROPERTYKEY* key, PWSTR Value) mut => VT.[Friend]SetStringValue(&this, key, Value);

	public HRESULT GetStringValue(PROPERTYKEY* key, PWSTR* pValue) mut => VT.[Friend]GetStringValue(&this, key, pValue);

	public HRESULT SetUnsignedIntegerValue(PROPERTYKEY* key, uint32 Value) mut => VT.[Friend]SetUnsignedIntegerValue(&this, key, Value);

	public HRESULT GetUnsignedIntegerValue(PROPERTYKEY* key, uint32* pValue) mut => VT.[Friend]GetUnsignedIntegerValue(&this, key, pValue);

	public HRESULT SetSignedIntegerValue(PROPERTYKEY* key, int32 Value) mut => VT.[Friend]SetSignedIntegerValue(&this, key, Value);

	public HRESULT GetSignedIntegerValue(PROPERTYKEY* key, int32* pValue) mut => VT.[Friend]GetSignedIntegerValue(&this, key, pValue);

	public HRESULT SetUnsignedLargeIntegerValue(PROPERTYKEY* key, uint64 Value) mut => VT.[Friend]SetUnsignedLargeIntegerValue(&this, key, Value);

	public HRESULT GetUnsignedLargeIntegerValue(PROPERTYKEY* key, uint64* pValue) mut => VT.[Friend]GetUnsignedLargeIntegerValue(&this, key, pValue);

	public HRESULT SetSignedLargeIntegerValue(PROPERTYKEY* key, int64 Value) mut => VT.[Friend]SetSignedLargeIntegerValue(&this, key, Value);

	public HRESULT GetSignedLargeIntegerValue(PROPERTYKEY* key, int64* pValue) mut => VT.[Friend]GetSignedLargeIntegerValue(&this, key, pValue);

	public HRESULT SetFloatValue(PROPERTYKEY* key, float Value) mut => VT.[Friend]SetFloatValue(&this, key, Value);

	public HRESULT GetFloatValue(PROPERTYKEY* key, float* pValue) mut => VT.[Friend]GetFloatValue(&this, key, pValue);

	public HRESULT SetErrorValue(PROPERTYKEY* key, HRESULT Value) mut => VT.[Friend]SetErrorValue(&this, key, Value);

	public HRESULT GetErrorValue(PROPERTYKEY* key, HRESULT* pValue) mut => VT.[Friend]GetErrorValue(&this, key, pValue);

	public HRESULT SetKeyValue(PROPERTYKEY* key, PROPERTYKEY* Value) mut => VT.[Friend]SetKeyValue(&this, key, Value);

	public HRESULT GetKeyValue(PROPERTYKEY* key, PROPERTYKEY* pValue) mut => VT.[Friend]GetKeyValue(&this, key, pValue);

	public HRESULT SetBoolValue(PROPERTYKEY* key, BOOL Value) mut => VT.[Friend]SetBoolValue(&this, key, Value);

	public HRESULT GetBoolValue(PROPERTYKEY* key, BOOL* pValue) mut => VT.[Friend]GetBoolValue(&this, key, pValue);

	public HRESULT SetIUnknownValue(PROPERTYKEY* key, IUnknown* pValue) mut => VT.[Friend]SetIUnknownValue(&this, key, pValue);

	public HRESULT GetIUnknownValue(PROPERTYKEY* key, IUnknown** ppValue) mut => VT.[Friend]GetIUnknownValue(&this, key, ppValue);

	public HRESULT SetGuidValue(PROPERTYKEY* key, in Guid Value) mut => VT.[Friend]SetGuidValue(&this, key, Value);

	public HRESULT GetGuidValue(PROPERTYKEY* key, Guid* pValue) mut => VT.[Friend]GetGuidValue(&this, key, pValue);

	public HRESULT SetBufferValue(PROPERTYKEY* key, uint8* pValue, uint32 cbValue) mut => VT.[Friend]SetBufferValue(&this, key, pValue, cbValue);

	public HRESULT GetBufferValue(PROPERTYKEY* key, uint8** ppValue, uint32* pcbValue) mut => VT.[Friend]GetBufferValue(&this, key, ppValue, pcbValue);

	public HRESULT SetIPortableDeviceValuesValue(PROPERTYKEY* key, IPortableDeviceValues* pValue) mut => VT.[Friend]SetIPortableDeviceValuesValue(&this, key, pValue);

	public HRESULT GetIPortableDeviceValuesValue(PROPERTYKEY* key, IPortableDeviceValues** ppValue) mut => VT.[Friend]GetIPortableDeviceValuesValue(&this, key, ppValue);

	public HRESULT SetIPortableDevicePropVariantCollectionValue(PROPERTYKEY* key, IPortableDevicePropVariantCollection* pValue) mut => VT.[Friend]SetIPortableDevicePropVariantCollectionValue(&this, key, pValue);

	public HRESULT GetIPortableDevicePropVariantCollectionValue(PROPERTYKEY* key, IPortableDevicePropVariantCollection** ppValue) mut => VT.[Friend]GetIPortableDevicePropVariantCollectionValue(&this, key, ppValue);

	public HRESULT SetIPortableDeviceKeyCollectionValue(PROPERTYKEY* key, IPortableDeviceKeyCollection* pValue) mut => VT.[Friend]SetIPortableDeviceKeyCollectionValue(&this, key, pValue);

	public HRESULT GetIPortableDeviceKeyCollectionValue(PROPERTYKEY* key, IPortableDeviceKeyCollection** ppValue) mut => VT.[Friend]GetIPortableDeviceKeyCollectionValue(&this, key, ppValue);

	public HRESULT SetIPortableDeviceValuesCollectionValue(PROPERTYKEY* key, IPortableDeviceValuesCollection* pValue) mut => VT.[Friend]SetIPortableDeviceValuesCollectionValue(&this, key, pValue);

	public HRESULT GetIPortableDeviceValuesCollectionValue(PROPERTYKEY* key, IPortableDeviceValuesCollection** ppValue) mut => VT.[Friend]GetIPortableDeviceValuesCollectionValue(&this, key, ppValue);

	public HRESULT RemoveValue(PROPERTYKEY* key) mut => VT.[Friend]RemoveValue(&this, key);

	public HRESULT CopyValuesFromPropertyStore(IPropertyStore* pStore) mut => VT.[Friend]CopyValuesFromPropertyStore(&this, pStore);

	public HRESULT CopyValuesToPropertyStore(IPropertyStore* pStore) mut => VT.[Friend]CopyValuesToPropertyStore(&this, pStore);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IPortableDeviceKeyCollection : IUnknown
{
	public new const Guid IID = .(0xdada2357, 0xe0ad, 0x492e, 0x98, 0xdb, 0xdd, 0x61, 0xc5, 0x3b, 0xa3, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PROPERTYKEY* pKey) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Key) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) RemoveAt;
	}


	public HRESULT GetCount(uint32* pcElems) mut => VT.[Friend]GetCount(&this, pcElems);

	public HRESULT GetAt(uint32 dwIndex, PROPERTYKEY* pKey) mut => VT.[Friend]GetAt(&this, dwIndex, pKey);

	public HRESULT Add(PROPERTYKEY* Key) mut => VT.[Friend]Add(&this, Key);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT RemoveAt(uint32 dwIndex) mut => VT.[Friend]RemoveAt(&this, dwIndex);
}

[CRepr]struct IPortableDevicePropVariantCollection : IUnknown
{
	public new const Guid IID = .(0x89b2e422, 0x4f1b, 0x4316, 0xbc, 0xef, 0xa4, 0x4a, 0xfe, 0xa8, 0x3e, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, PROPVARIANT* pValue) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPVARIANT* pValue) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pvt) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 vt) ChangeType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) RemoveAt;
	}


	public HRESULT GetCount(uint32* pcElems) mut => VT.[Friend]GetCount(&this, pcElems);

	public HRESULT GetAt(uint32 dwIndex, PROPVARIANT* pValue) mut => VT.[Friend]GetAt(&this, dwIndex, pValue);

	public HRESULT Add(PROPVARIANT* pValue) mut => VT.[Friend]Add(&this, pValue);

	public HRESULT GetType(uint16* pvt) mut => VT.[Friend]COM_GetType(&this, pvt);

	public HRESULT ChangeType(uint16 vt) mut => VT.[Friend]ChangeType(&this, vt);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT RemoveAt(uint32 dwIndex) mut => VT.[Friend]RemoveAt(&this, dwIndex);
}

[CRepr]struct IPortableDeviceValuesCollection : IUnknown
{
	public new const Guid IID = .(0x6e3f2d79, 0x4e07, 0x48c4, 0x82, 0x08, 0xd8, 0xc2, 0xe5, 0xaf, 0x4a, 0x99);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcElems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IPortableDeviceValues** ppValues) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pValues) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex) RemoveAt;
	}


	public HRESULT GetCount(uint32* pcElems) mut => VT.[Friend]GetCount(&this, pcElems);

	public HRESULT GetAt(uint32 dwIndex, IPortableDeviceValues** ppValues) mut => VT.[Friend]GetAt(&this, dwIndex, ppValues);

	public HRESULT Add(IPortableDeviceValues* pValues) mut => VT.[Friend]Add(&this, pValues);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);

	public HRESULT RemoveAt(uint32 dwIndex) mut => VT.[Friend]RemoveAt(&this, dwIndex);
}

[CRepr]struct IPortableDeviceManager : IUnknown
{
	public new const Guid IID = .(0xa1567595, 0x4c2f, 0x4574, 0xa6, 0xfa, 0xec, 0xef, 0x91, 0x7b, 0x9a, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pPnPDeviceIDs, uint32* pcPnPDeviceIDs) GetDevices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshDeviceList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, PWSTR pDeviceFriendlyName, uint32* pcchDeviceFriendlyName) GetDeviceFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, PWSTR pDeviceDescription, uint32* pcchDeviceDescription) GetDeviceDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, PWSTR pDeviceManufacturer, uint32* pcchDeviceManufacturer) GetDeviceManufacturer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, PWSTR pszDevicePropertyName, uint8* pData, uint32* pcbData, uint32* pdwType) GetDeviceProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pPnPDeviceIDs, uint32* pcPnPDeviceIDs) GetPrivateDevices;
	}


	public HRESULT GetDevices(PWSTR* pPnPDeviceIDs, uint32* pcPnPDeviceIDs) mut => VT.[Friend]GetDevices(&this, pPnPDeviceIDs, pcPnPDeviceIDs);

	public HRESULT RefreshDeviceList() mut => VT.[Friend]RefreshDeviceList(&this);

	public HRESULT GetDeviceFriendlyName(PWSTR pszPnPDeviceID, PWSTR pDeviceFriendlyName, uint32* pcchDeviceFriendlyName) mut => VT.[Friend]GetDeviceFriendlyName(&this, pszPnPDeviceID, pDeviceFriendlyName, pcchDeviceFriendlyName);

	public HRESULT GetDeviceDescription(PWSTR pszPnPDeviceID, PWSTR pDeviceDescription, uint32* pcchDeviceDescription) mut => VT.[Friend]GetDeviceDescription(&this, pszPnPDeviceID, pDeviceDescription, pcchDeviceDescription);

	public HRESULT GetDeviceManufacturer(PWSTR pszPnPDeviceID, PWSTR pDeviceManufacturer, uint32* pcchDeviceManufacturer) mut => VT.[Friend]GetDeviceManufacturer(&this, pszPnPDeviceID, pDeviceManufacturer, pcchDeviceManufacturer);

	public HRESULT GetDeviceProperty(PWSTR pszPnPDeviceID, PWSTR pszDevicePropertyName, uint8* pData, uint32* pcbData, uint32* pdwType) mut => VT.[Friend]GetDeviceProperty(&this, pszPnPDeviceID, pszDevicePropertyName, pData, pcbData, pdwType);

	public HRESULT GetPrivateDevices(PWSTR* pPnPDeviceIDs, uint32* pcPnPDeviceIDs) mut => VT.[Friend]GetPrivateDevices(&this, pPnPDeviceIDs, pcPnPDeviceIDs);
}

[CRepr]struct IPortableDevice : IUnknown
{
	public new const Guid IID = .(0x625e2df8, 0x6392, 0x4cf0, 0x9a, 0xd1, 0x3c, 0xfa, 0x5f, 0x17, 0x77, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, IPortableDeviceValues* pClientInfo) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) SendCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceContent** ppContent) Content;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceCapabilities** ppCapabilities) Capabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IPortableDeviceEventCallback* pCallback, IPortableDeviceValues* pParameters, PWSTR* ppszCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPnPDeviceID) GetPnPDeviceID;
	}


	public HRESULT Open(PWSTR pszPnPDeviceID, IPortableDeviceValues* pClientInfo) mut => VT.[Friend]Open(&this, pszPnPDeviceID, pClientInfo);

	public HRESULT SendCommand(uint32 dwFlags, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) mut => VT.[Friend]SendCommand(&this, dwFlags, pParameters, ppResults);

	public HRESULT Content(IPortableDeviceContent** ppContent) mut => VT.[Friend]Content(&this, ppContent);

	public HRESULT Capabilities(IPortableDeviceCapabilities** ppCapabilities) mut => VT.[Friend]Capabilities(&this, ppCapabilities);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT Advise(uint32 dwFlags, IPortableDeviceEventCallback* pCallback, IPortableDeviceValues* pParameters, PWSTR* ppszCookie) mut => VT.[Friend]Advise(&this, dwFlags, pCallback, pParameters, ppszCookie);

	public HRESULT Unadvise(PWSTR pszCookie) mut => VT.[Friend]Unadvise(&this, pszCookie);

	public HRESULT GetPnPDeviceID(PWSTR* ppszPnPDeviceID) mut => VT.[Friend]GetPnPDeviceID(&this, ppszPnPDeviceID);
}

[CRepr]struct IPortableDeviceContent : IUnknown
{
	public new const Guid IID = .(0x6a96ed84, 0x7c73, 0x4480, 0x99, 0x38, 0xbf, 0x5a, 0xf4, 0x77, 0xd4, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PWSTR pszParentObjectID, IPortableDeviceValues* pFilter, IEnumPortableDeviceObjectIDs** ppEnum) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceProperties** ppProperties) Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceResources** ppResources) Transfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pValues, PWSTR* ppszObjectID) CreateObjectWithPropertiesOnly;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pValues, IStream** ppData, uint32* pdwOptimalWriteBufferSize, PWSTR* ppszCookie) CreateObjectWithPropertiesAndData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOptions, IPortableDevicePropVariantCollection* pObjectIDs, IPortableDevicePropVariantCollection** ppResults) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection* pPersistentUniqueIDs, IPortableDevicePropVariantCollection** ppObjectIDs) GetObjectIDsFromPersistentUniqueIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection* pObjectIDs, PWSTR pszDestinationFolderObjectID, IPortableDevicePropVariantCollection** ppResults) Move;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection* pObjectIDs, PWSTR pszDestinationFolderObjectID, IPortableDevicePropVariantCollection** ppResults) Copy;
	}


	public HRESULT EnumObjects(uint32 dwFlags, PWSTR pszParentObjectID, IPortableDeviceValues* pFilter, IEnumPortableDeviceObjectIDs** ppEnum) mut => VT.[Friend]EnumObjects(&this, dwFlags, pszParentObjectID, pFilter, ppEnum);

	public HRESULT Properties(IPortableDeviceProperties** ppProperties) mut => VT.[Friend]Properties(&this, ppProperties);

	public HRESULT Transfer(IPortableDeviceResources** ppResources) mut => VT.[Friend]Transfer(&this, ppResources);

	public HRESULT CreateObjectWithPropertiesOnly(IPortableDeviceValues* pValues, PWSTR* ppszObjectID) mut => VT.[Friend]CreateObjectWithPropertiesOnly(&this, pValues, ppszObjectID);

	public HRESULT CreateObjectWithPropertiesAndData(IPortableDeviceValues* pValues, IStream** ppData, uint32* pdwOptimalWriteBufferSize, PWSTR* ppszCookie) mut => VT.[Friend]CreateObjectWithPropertiesAndData(&this, pValues, ppData, pdwOptimalWriteBufferSize, ppszCookie);

	public HRESULT Delete(uint32 dwOptions, IPortableDevicePropVariantCollection* pObjectIDs, IPortableDevicePropVariantCollection** ppResults) mut => VT.[Friend]Delete(&this, dwOptions, pObjectIDs, ppResults);

	public HRESULT GetObjectIDsFromPersistentUniqueIDs(IPortableDevicePropVariantCollection* pPersistentUniqueIDs, IPortableDevicePropVariantCollection** ppObjectIDs) mut => VT.[Friend]GetObjectIDsFromPersistentUniqueIDs(&this, pPersistentUniqueIDs, ppObjectIDs);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Move(IPortableDevicePropVariantCollection* pObjectIDs, PWSTR pszDestinationFolderObjectID, IPortableDevicePropVariantCollection** ppResults) mut => VT.[Friend]Move(&this, pObjectIDs, pszDestinationFolderObjectID, ppResults);

	public HRESULT Copy(IPortableDevicePropVariantCollection* pObjectIDs, PWSTR pszDestinationFolderObjectID, IPortableDevicePropVariantCollection** ppResults) mut => VT.[Friend]Copy(&this, pObjectIDs, pszDestinationFolderObjectID, ppResults);
}

[CRepr]struct IPortableDeviceContent2 : IPortableDeviceContent
{
	public new const Guid IID = .(0x9b4add96, 0xf6bf, 0x4034, 0x87, 0x08, 0xec, 0xa7, 0x2b, 0xf1, 0x05, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPortableDeviceContent.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceValues* pProperties, IStream** ppData, uint32* pdwOptimalWriteBufferSize) UpdateObjectWithPropertiesAndData;
	}


	public HRESULT UpdateObjectWithPropertiesAndData(PWSTR pszObjectID, IPortableDeviceValues* pProperties, IStream** ppData, uint32* pdwOptimalWriteBufferSize) mut => VT.[Friend]UpdateObjectWithPropertiesAndData(&this, pszObjectID, pProperties, ppData, pdwOptimalWriteBufferSize);
}

[CRepr]struct IEnumPortableDeviceObjectIDs : IUnknown
{
	public new const Guid IID = .(0x10ece955, 0xcf41, 0x4728, 0xbf, 0xa0, 0x41, 0xee, 0xdf, 0x1b, 0xbf, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cObjects, PWSTR* pObjIDs, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cObjects) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumPortableDeviceObjectIDs** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT Next(uint32 cObjects, PWSTR* pObjIDs, uint32* pcFetched) mut => VT.[Friend]Next(&this, cObjects, pObjIDs, pcFetched);

	public HRESULT Skip(uint32 cObjects) mut => VT.[Friend]Skip(&this, cObjects);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumPortableDeviceObjectIDs** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPortableDeviceProperties : IUnknown
{
	public new const Guid IID = .(0x7f6d695c, 0x03df, 0x4439, 0xa8, 0x09, 0x59, 0x26, 0x6b, 0xee, 0xe3, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceKeyCollection** ppKeys) GetSupportedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, PROPERTYKEY* Key, IPortableDeviceValues** ppAttributes) GetPropertyAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys, IPortableDeviceValues** ppValues) GetValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceValues* pValues, IPortableDeviceValues** ppResults) SetValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT GetSupportedProperties(PWSTR pszObjectID, IPortableDeviceKeyCollection** ppKeys) mut => VT.[Friend]GetSupportedProperties(&this, pszObjectID, ppKeys);

	public HRESULT GetPropertyAttributes(PWSTR pszObjectID, PROPERTYKEY* Key, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetPropertyAttributes(&this, pszObjectID, Key, ppAttributes);

	public HRESULT GetValues(PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys, IPortableDeviceValues** ppValues) mut => VT.[Friend]GetValues(&this, pszObjectID, pKeys, ppValues);

	public HRESULT SetValues(PWSTR pszObjectID, IPortableDeviceValues* pValues, IPortableDeviceValues** ppResults) mut => VT.[Friend]SetValues(&this, pszObjectID, pValues, ppResults);

	public HRESULT Delete(PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys) mut => VT.[Friend]Delete(&this, pszObjectID, pKeys);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPortableDeviceResources : IUnknown
{
	public new const Guid IID = .(0xfd8878ac, 0xd841, 0x4d17, 0x89, 0x1c, 0xe6, 0x82, 0x9c, 0xdb, 0x69, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceKeyCollection** ppKeys) GetSupportedResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, PROPERTYKEY* Key, IPortableDeviceValues** ppResourceAttributes) GetResourceAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, PROPERTYKEY* Key, uint32 dwMode, uint32* pdwOptimalBufferSize, IStream** ppStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pResourceAttributes, IStream** ppData, uint32* pdwOptimalWriteBufferSize, PWSTR* ppszCookie) CreateResource;
	}


	public HRESULT GetSupportedResources(PWSTR pszObjectID, IPortableDeviceKeyCollection** ppKeys) mut => VT.[Friend]GetSupportedResources(&this, pszObjectID, ppKeys);

	public HRESULT GetResourceAttributes(PWSTR pszObjectID, PROPERTYKEY* Key, IPortableDeviceValues** ppResourceAttributes) mut => VT.[Friend]GetResourceAttributes(&this, pszObjectID, Key, ppResourceAttributes);

	public HRESULT GetStream(PWSTR pszObjectID, PROPERTYKEY* Key, uint32 dwMode, uint32* pdwOptimalBufferSize, IStream** ppStream) mut => VT.[Friend]GetStream(&this, pszObjectID, Key, dwMode, pdwOptimalBufferSize, ppStream);

	public HRESULT Delete(PWSTR pszObjectID, IPortableDeviceKeyCollection* pKeys) mut => VT.[Friend]Delete(&this, pszObjectID, pKeys);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT CreateResource(IPortableDeviceValues* pResourceAttributes, IStream** ppData, uint32* pdwOptimalWriteBufferSize, PWSTR* ppszCookie) mut => VT.[Friend]CreateResource(&this, pResourceAttributes, ppData, pdwOptimalWriteBufferSize, ppszCookie);
}

[CRepr]struct IPortableDeviceCapabilities : IUnknown
{
	public new const Guid IID = .(0x2c8c6dbf, 0xe3dc, 0x4061, 0xbe, 0xcc, 0x85, 0x42, 0xe8, 0x10, 0xd1, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceKeyCollection** ppCommands) GetSupportedCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Command, IPortableDeviceValues** ppOptions) GetCommandOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection** ppCategories) GetFunctionalCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Category, IPortableDevicePropVariantCollection** ppObjectIDs) GetFunctionalObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Category, IPortableDevicePropVariantCollection** ppContentTypes) GetSupportedContentTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ContentType, IPortableDevicePropVariantCollection** ppFormats) GetSupportedFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, IPortableDeviceKeyCollection** ppKeys) GetSupportedFormatProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, PROPERTYKEY* Key, IPortableDeviceValues** ppAttributes) GetFixedPropertyAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection** ppEvents) GetSupportedEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Event, IPortableDeviceValues** ppOptions) GetEventOptions;
	}


	public HRESULT GetSupportedCommands(IPortableDeviceKeyCollection** ppCommands) mut => VT.[Friend]GetSupportedCommands(&this, ppCommands);

	public HRESULT GetCommandOptions(PROPERTYKEY* Command, IPortableDeviceValues** ppOptions) mut => VT.[Friend]GetCommandOptions(&this, Command, ppOptions);

	public HRESULT GetFunctionalCategories(IPortableDevicePropVariantCollection** ppCategories) mut => VT.[Friend]GetFunctionalCategories(&this, ppCategories);

	public HRESULT GetFunctionalObjects(in Guid Category, IPortableDevicePropVariantCollection** ppObjectIDs) mut => VT.[Friend]GetFunctionalObjects(&this, Category, ppObjectIDs);

	public HRESULT GetSupportedContentTypes(in Guid Category, IPortableDevicePropVariantCollection** ppContentTypes) mut => VT.[Friend]GetSupportedContentTypes(&this, Category, ppContentTypes);

	public HRESULT GetSupportedFormats(in Guid ContentType, IPortableDevicePropVariantCollection** ppFormats) mut => VT.[Friend]GetSupportedFormats(&this, ContentType, ppFormats);

	public HRESULT GetSupportedFormatProperties(in Guid Format, IPortableDeviceKeyCollection** ppKeys) mut => VT.[Friend]GetSupportedFormatProperties(&this, Format, ppKeys);

	public HRESULT GetFixedPropertyAttributes(in Guid Format, PROPERTYKEY* Key, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetFixedPropertyAttributes(&this, Format, Key, ppAttributes);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT GetSupportedEvents(IPortableDevicePropVariantCollection** ppEvents) mut => VT.[Friend]GetSupportedEvents(&this, ppEvents);

	public HRESULT GetEventOptions(in Guid Event, IPortableDeviceValues** ppOptions) mut => VT.[Friend]GetEventOptions(&this, Event, ppOptions);
}

[CRepr]struct IPortableDeviceEventCallback : IUnknown
{
	public new const Guid IID = .(0xa8792a31, 0xf385, 0x493c, 0xa8, 0x93, 0x40, 0xf6, 0x4e, 0xb4, 0x5f, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValues* pEventParameters) OnEvent;
	}


	public HRESULT OnEvent(IPortableDeviceValues* pEventParameters) mut => VT.[Friend]OnEvent(&this, pEventParameters);
}

[CRepr]struct IPortableDeviceDataStream : IStream
{
	public new const Guid IID = .(0x88e04db3, 0x1012, 0x4d64, 0x99, 0x96, 0xf7, 0x03, 0xa9, 0x50, 0xd3, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszObjectID) GetObjectID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT GetObjectID(PWSTR* ppszObjectID) mut => VT.[Friend]GetObjectID(&this, ppszObjectID);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPortableDeviceUnitsStream : IUnknown
{
	public new const Guid IID = .(0x5e98025f, 0xbfc4, 0x47a2, 0x9a, 0x5f, 0xbc, 0x90, 0x0a, 0x50, 0x7c, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER dlibMove, WPD_STREAM_UNITS units, uint32 dwOrigin, ULARGE_INTEGER* plibNewPosition) SeekInUnits;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT SeekInUnits(LARGE_INTEGER dlibMove, WPD_STREAM_UNITS units, uint32 dwOrigin, ULARGE_INTEGER* plibNewPosition) mut => VT.[Friend]SeekInUnits(&this, dlibMove, units, dwOrigin, plibNewPosition);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPortableDevicePropertiesBulk : IUnknown
{
	public new const Guid IID = .(0x482b05c0, 0x4056, 0x44ed, 0x9e, 0x0f, 0x5e, 0x23, 0xb0, 0x09, 0xda, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection* pObjectIDs, IPortableDeviceKeyCollection* pKeys, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) QueueGetValuesByObjectList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidObjectFormat, PWSTR pszParentObjectID, uint32 dwDepth, IPortableDeviceKeyCollection* pKeys, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) QueueGetValuesByObjectFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceValuesCollection* pObjectValues, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) QueueSetValuesByObjectList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pContext) Start;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pContext) Cancel;
	}


	public HRESULT QueueGetValuesByObjectList(IPortableDevicePropVariantCollection* pObjectIDs, IPortableDeviceKeyCollection* pKeys, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) mut => VT.[Friend]QueueGetValuesByObjectList(&this, pObjectIDs, pKeys, pCallback, pContext);

	public HRESULT QueueGetValuesByObjectFormat(in Guid pguidObjectFormat, PWSTR pszParentObjectID, uint32 dwDepth, IPortableDeviceKeyCollection* pKeys, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) mut => VT.[Friend]QueueGetValuesByObjectFormat(&this, pguidObjectFormat, pszParentObjectID, dwDepth, pKeys, pCallback, pContext);

	public HRESULT QueueSetValuesByObjectList(IPortableDeviceValuesCollection* pObjectValues, IPortableDevicePropertiesBulkCallback* pCallback, Guid* pContext) mut => VT.[Friend]QueueSetValuesByObjectList(&this, pObjectValues, pCallback, pContext);

	public HRESULT Start(in Guid pContext) mut => VT.[Friend]Start(&this, pContext);

	public HRESULT Cancel(in Guid pContext) mut => VT.[Friend]Cancel(&this, pContext);
}

[CRepr]struct IPortableDevicePropertiesBulkCallback : IUnknown
{
	public new const Guid IID = .(0x9deacb80, 0x11e8, 0x40e3, 0xa9, 0xf3, 0xf5, 0x57, 0x98, 0x6a, 0x78, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pContext) OnStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pContext, IPortableDeviceValuesCollection* pResults) OnProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pContext, HRESULT hrStatus) OnEnd;
	}


	public HRESULT OnStart(in Guid pContext) mut => VT.[Friend]OnStart(&this, pContext);

	public HRESULT OnProgress(in Guid pContext, IPortableDeviceValuesCollection* pResults) mut => VT.[Friend]OnProgress(&this, pContext, pResults);

	public HRESULT OnEnd(in Guid pContext, HRESULT hrStatus) mut => VT.[Friend]OnEnd(&this, pContext, hrStatus);
}

[CRepr]struct IPortableDeviceServiceManager : IUnknown
{
	public new const Guid IID = .(0xa8abc4e9, 0xa84a, 0x47a9, 0x80, 0xb3, 0xc5, 0xd9, 0xb1, 0x72, 0xa9, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, in Guid guidServiceCategory, PWSTR* pServices, uint32* pcServices) GetDeviceServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPServiceID, PWSTR* ppszPnPDeviceID) GetDeviceForService;
	}


	public HRESULT GetDeviceServices(PWSTR pszPnPDeviceID, in Guid guidServiceCategory, PWSTR* pServices, uint32* pcServices) mut => VT.[Friend]GetDeviceServices(&this, pszPnPDeviceID, guidServiceCategory, pServices, pcServices);

	public HRESULT GetDeviceForService(PWSTR pszPnPServiceID, PWSTR* ppszPnPDeviceID) mut => VT.[Friend]GetDeviceForService(&this, pszPnPServiceID, ppszPnPDeviceID);
}

[CRepr]struct IPortableDeviceService : IUnknown
{
	public new const Guid IID = .(0xd3bd3a44, 0xd7b5, 0x40a9, 0x98, 0xb7, 0x2f, 0xa4, 0xd0, 0x1d, 0xec, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPServiceID, IPortableDeviceValues* pClientInfo) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceServiceCapabilities** ppCapabilities) Capabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceContent2** ppContent) Content;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceServiceMethods** ppMethods) Methods;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszServiceObjectID) GetServiceObjectID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPnPServiceID) GetPnPServiceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IPortableDeviceEventCallback* pCallback, IPortableDeviceValues* pParameters, PWSTR* ppszCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) SendCommand;
	}


	public HRESULT Open(PWSTR pszPnPServiceID, IPortableDeviceValues* pClientInfo) mut => VT.[Friend]Open(&this, pszPnPServiceID, pClientInfo);

	public HRESULT Capabilities(IPortableDeviceServiceCapabilities** ppCapabilities) mut => VT.[Friend]Capabilities(&this, ppCapabilities);

	public HRESULT Content(IPortableDeviceContent2** ppContent) mut => VT.[Friend]Content(&this, ppContent);

	public HRESULT Methods(IPortableDeviceServiceMethods** ppMethods) mut => VT.[Friend]Methods(&this, ppMethods);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT GetServiceObjectID(PWSTR* ppszServiceObjectID) mut => VT.[Friend]GetServiceObjectID(&this, ppszServiceObjectID);

	public HRESULT GetPnPServiceID(PWSTR* ppszPnPServiceID) mut => VT.[Friend]GetPnPServiceID(&this, ppszPnPServiceID);

	public HRESULT Advise(uint32 dwFlags, IPortableDeviceEventCallback* pCallback, IPortableDeviceValues* pParameters, PWSTR* ppszCookie) mut => VT.[Friend]Advise(&this, dwFlags, pCallback, pParameters, ppszCookie);

	public HRESULT Unadvise(PWSTR pszCookie) mut => VT.[Friend]Unadvise(&this, pszCookie);

	public HRESULT SendCommand(uint32 dwFlags, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) mut => VT.[Friend]SendCommand(&this, dwFlags, pParameters, ppResults);
}

[CRepr]struct IPortableDeviceServiceCapabilities : IUnknown
{
	public new const Guid IID = .(0x24dbd89d, 0x413e, 0x43e0, 0xbd, 0x5b, 0x19, 0x7f, 0x3c, 0x56, 0xc8, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection** ppMethods) GetSupportedMethods;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, IPortableDevicePropVariantCollection** ppMethods) GetSupportedMethodsByFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Method, IPortableDeviceValues** ppAttributes) GetMethodAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Method, PROPERTYKEY* Parameter, IPortableDeviceValues** ppAttributes) GetMethodParameterAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection** ppFormats) GetSupportedFormats;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, IPortableDeviceValues** ppAttributes) GetFormatAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, IPortableDeviceKeyCollection** ppKeys) GetSupportedFormatProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, PROPERTYKEY* Property, IPortableDeviceValues** ppAttributes) GetFormatPropertyAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDevicePropVariantCollection** ppEvents) GetSupportedEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Event, IPortableDeviceValues** ppAttributes) GetEventAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Event, PROPERTYKEY* Parameter, IPortableDeviceValues** ppAttributes) GetEventParameterAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInheritanceType, IPortableDevicePropVariantCollection** ppServices) GetInheritedServices;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Format, IPortableDeviceValuesCollection** ppRenderingProfiles) GetFormatRenderingProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceKeyCollection** ppCommands) GetSupportedCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* Command, IPortableDeviceValues** ppOptions) GetCommandOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
	}


	public HRESULT GetSupportedMethods(IPortableDevicePropVariantCollection** ppMethods) mut => VT.[Friend]GetSupportedMethods(&this, ppMethods);

	public HRESULT GetSupportedMethodsByFormat(in Guid Format, IPortableDevicePropVariantCollection** ppMethods) mut => VT.[Friend]GetSupportedMethodsByFormat(&this, Format, ppMethods);

	public HRESULT GetMethodAttributes(in Guid Method, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetMethodAttributes(&this, Method, ppAttributes);

	public HRESULT GetMethodParameterAttributes(in Guid Method, PROPERTYKEY* Parameter, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetMethodParameterAttributes(&this, Method, Parameter, ppAttributes);

	public HRESULT GetSupportedFormats(IPortableDevicePropVariantCollection** ppFormats) mut => VT.[Friend]GetSupportedFormats(&this, ppFormats);

	public HRESULT GetFormatAttributes(in Guid Format, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetFormatAttributes(&this, Format, ppAttributes);

	public HRESULT GetSupportedFormatProperties(in Guid Format, IPortableDeviceKeyCollection** ppKeys) mut => VT.[Friend]GetSupportedFormatProperties(&this, Format, ppKeys);

	public HRESULT GetFormatPropertyAttributes(in Guid Format, PROPERTYKEY* Property, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetFormatPropertyAttributes(&this, Format, Property, ppAttributes);

	public HRESULT GetSupportedEvents(IPortableDevicePropVariantCollection** ppEvents) mut => VT.[Friend]GetSupportedEvents(&this, ppEvents);

	public HRESULT GetEventAttributes(in Guid Event, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetEventAttributes(&this, Event, ppAttributes);

	public HRESULT GetEventParameterAttributes(in Guid Event, PROPERTYKEY* Parameter, IPortableDeviceValues** ppAttributes) mut => VT.[Friend]GetEventParameterAttributes(&this, Event, Parameter, ppAttributes);

	public HRESULT GetInheritedServices(uint32 dwInheritanceType, IPortableDevicePropVariantCollection** ppServices) mut => VT.[Friend]GetInheritedServices(&this, dwInheritanceType, ppServices);

	public HRESULT GetFormatRenderingProfiles(in Guid Format, IPortableDeviceValuesCollection** ppRenderingProfiles) mut => VT.[Friend]GetFormatRenderingProfiles(&this, Format, ppRenderingProfiles);

	public HRESULT GetSupportedCommands(IPortableDeviceKeyCollection** ppCommands) mut => VT.[Friend]GetSupportedCommands(&this, ppCommands);

	public HRESULT GetCommandOptions(PROPERTYKEY* Command, IPortableDeviceValues** ppOptions) mut => VT.[Friend]GetCommandOptions(&this, Command, ppOptions);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);
}

[CRepr]struct IPortableDeviceServiceMethods : IUnknown
{
	public new const Guid IID = .(0xe20333c9, 0xfd34, 0x412d, 0xa3, 0x81, 0xcc, 0x6f, 0x2d, 0x82, 0x0d, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Method, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) Invoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Method, IPortableDeviceValues* pParameters, IPortableDeviceServiceMethodCallback* pCallback) InvokeAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPortableDeviceServiceMethodCallback* pCallback) Cancel;
	}


	public HRESULT Invoke(in Guid Method, IPortableDeviceValues* pParameters, IPortableDeviceValues** ppResults) mut => VT.[Friend]Invoke(&this, Method, pParameters, ppResults);

	public HRESULT InvokeAsync(in Guid Method, IPortableDeviceValues* pParameters, IPortableDeviceServiceMethodCallback* pCallback) mut => VT.[Friend]InvokeAsync(&this, Method, pParameters, pCallback);

	public HRESULT Cancel(IPortableDeviceServiceMethodCallback* pCallback) mut => VT.[Friend]Cancel(&this, pCallback);
}

[CRepr]struct IPortableDeviceServiceMethodCallback : IUnknown
{
	public new const Guid IID = .(0xc424233c, 0xafce, 0x4828, 0xa7, 0x56, 0x7e, 0xd7, 0xa2, 0x35, 0x00, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrStatus, IPortableDeviceValues* pResults) OnComplete;
	}


	public HRESULT OnComplete(HRESULT hrStatus, IPortableDeviceValues* pResults) mut => VT.[Friend]OnComplete(&this, hrStatus, pResults);
}

[CRepr]struct IPortableDeviceServiceActivation : IUnknown
{
	public new const Guid IID = .(0xe56b0534, 0xd9b9, 0x425c, 0x9b, 0x99, 0x75, 0xf9, 0x7c, 0xb3, 0xd7, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPServiceID, IPortableDeviceValues* pClientInfo, IPortableDeviceServiceOpenCallback* pCallback) OpenAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelOpenAsync;
	}


	public HRESULT OpenAsync(PWSTR pszPnPServiceID, IPortableDeviceValues* pClientInfo, IPortableDeviceServiceOpenCallback* pCallback) mut => VT.[Friend]OpenAsync(&this, pszPnPServiceID, pClientInfo, pCallback);

	public HRESULT CancelOpenAsync() mut => VT.[Friend]CancelOpenAsync(&this);
}

[CRepr]struct IPortableDeviceServiceOpenCallback : IUnknown
{
	public new const Guid IID = .(0xbced49c8, 0x8efe, 0x41ed, 0x96, 0x0b, 0x61, 0x31, 0x3a, 0xbd, 0x47, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrStatus) OnComplete;
	}


	public HRESULT OnComplete(HRESULT hrStatus) mut => VT.[Friend]OnComplete(&this, hrStatus);
}

[CRepr]struct IPortableDeviceDispatchFactory : IUnknown
{
	public new const Guid IID = .(0x5e1eafc3, 0xe3d7, 0x4132, 0x96, 0xfa, 0x75, 0x9c, 0x0f, 0x9d, 0x1e, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPnPDeviceID, IDispatch** ppDeviceDispatch) GetDeviceDispatch;
	}


	public HRESULT GetDeviceDispatch(PWSTR pszPnPDeviceID, IDispatch** ppDeviceDispatch) mut => VT.[Friend]GetDeviceDispatch(&this, pszPnPDeviceID, ppDeviceDispatch);
}

[CRepr]struct IPortableDeviceWebControl : IDispatch
{
	public new const Guid IID = .(0x94fc7953, 0x5ca1, 0x483a, 0x8a, 0xee, 0xdf, 0x52, 0xe7, 0x74, 0x7d, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR deviceId, IDispatch** ppDevice) GetDeviceFromId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR deviceId, IDispatch* pCompletionHandler, IDispatch* pErrorHandler) GetDeviceFromIdAsync;
	}


	public HRESULT GetDeviceFromId(BSTR deviceId, IDispatch** ppDevice) mut => VT.[Friend]GetDeviceFromId(&this, deviceId, ppDevice);

	public HRESULT GetDeviceFromIdAsync(BSTR deviceId, IDispatch* pCompletionHandler, IDispatch* pErrorHandler) mut => VT.[Friend]GetDeviceFromIdAsync(&this, deviceId, pCompletionHandler, pErrorHandler);
}

[CRepr]struct IEnumPortableDeviceConnectors : IUnknown
{
	public new const Guid IID = .(0xbfdef549, 0x9247, 0x454f, 0xbd, 0x82, 0x06, 0xfe, 0x80, 0x85, 0x3f, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cRequested, IPortableDeviceConnector** pConnectors, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cConnectors) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumPortableDeviceConnectors** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cRequested, IPortableDeviceConnector** pConnectors, uint32* pcFetched) mut => VT.[Friend]Next(&this, cRequested, pConnectors, pcFetched);

	public HRESULT Skip(uint32 cConnectors) mut => VT.[Friend]Skip(&this, cConnectors);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumPortableDeviceConnectors** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct IPortableDeviceConnector : IUnknown
{
	public new const Guid IID = .(0x625e2df8, 0x6392, 0x4cf0, 0x9a, 0xd1, 0x3c, 0xfa, 0x5f, 0x17, 0x77, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConnectionRequestCallback* pCallback) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConnectionRequestCallback* pCallback) Disconnect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConnectionRequestCallback* pCallback) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVPROPKEY* pPropertyKey, uint32* pPropertyType, uint8** ppData, uint32* pcbData) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVPROPKEY* pPropertyKey, uint32 PropertyType, uint8* pData, uint32 cbData) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszPnPID) GetPnPID;
	}


	public HRESULT Connect(IConnectionRequestCallback* pCallback) mut => VT.[Friend]Connect(&this, pCallback);

	public HRESULT Disconnect(IConnectionRequestCallback* pCallback) mut => VT.[Friend]Disconnect(&this, pCallback);

	public HRESULT Cancel(IConnectionRequestCallback* pCallback) mut => VT.[Friend]Cancel(&this, pCallback);

	public HRESULT GetProperty(DEVPROPKEY* pPropertyKey, uint32* pPropertyType, uint8** ppData, uint32* pcbData) mut => VT.[Friend]GetProperty(&this, pPropertyKey, pPropertyType, ppData, pcbData);

	public HRESULT SetProperty(DEVPROPKEY* pPropertyKey, uint32 PropertyType, uint8* pData, uint32 cbData) mut => VT.[Friend]SetProperty(&this, pPropertyKey, PropertyType, pData, cbData);

	public HRESULT GetPnPID(PWSTR* ppwszPnPID) mut => VT.[Friend]GetPnPID(&this, ppwszPnPID);
}

[CRepr]struct IConnectionRequestCallback : IUnknown
{
	public new const Guid IID = .(0x272c9ae0, 0x7161, 0x4ae0, 0x91, 0xbd, 0x9f, 0x44, 0x8e, 0xe9, 0xc4, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrStatus) OnComplete;
	}


	public HRESULT OnComplete(HRESULT hrStatus) mut => VT.[Friend]OnComplete(&this, hrStatus);
}

[CRepr]struct IMediaRadioManager : IUnknown
{
	public new const Guid IID = .(0x6cfdcab5, 0xfc47, 0x42a5, 0x92, 0x41, 0x07, 0x4b, 0x58, 0x83, 0x0e, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRadioInstanceCollection** ppCollection) GetRadioInstances;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEM_RADIO_STATE sysRadioState, uint32 uTimeoutSec) OnSystemRadioStateChange;
	}


	public HRESULT GetRadioInstances(IRadioInstanceCollection** ppCollection) mut => VT.[Friend]GetRadioInstances(&this, ppCollection);

	public HRESULT OnSystemRadioStateChange(SYSTEM_RADIO_STATE sysRadioState, uint32 uTimeoutSec) mut => VT.[Friend]OnSystemRadioStateChange(&this, sysRadioState, uTimeoutSec);
}

[CRepr]struct IRadioInstanceCollection : IUnknown
{
	public new const Guid IID = .(0xe5791fae, 0x5665, 0x4e0c, 0x95, 0xbe, 0x5f, 0xde, 0x31, 0x64, 0x41, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcInstance) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, IRadioInstance** ppRadioInstance) GetAt;
	}


	public HRESULT GetCount(uint32* pcInstance) mut => VT.[Friend]GetCount(&this, pcInstance);

	public HRESULT GetAt(uint32 uIndex, IRadioInstance** ppRadioInstance) mut => VT.[Friend]GetAt(&this, uIndex, ppRadioInstance);
}

[CRepr]struct IRadioInstance : IUnknown
{
	public new const Guid IID = .(0x70aa1c9e, 0xf2b4, 0x4c61, 0x86, 0xd3, 0x6b, 0x9f, 0xb7, 0x5f, 0xd1, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidSignature) GetRadioManagerSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrId) GetInstanceSignature;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 lcid, BSTR* pbstrName) GetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVICE_RADIO_STATE* pRadioState) GetRadioState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVICE_RADIO_STATE radioState, uint32 uTimeoutSec) SetRadioState;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsMultiComm;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) IsAssociatingDevice;
	}


	public HRESULT GetRadioManagerSignature(Guid* pguidSignature) mut => VT.[Friend]GetRadioManagerSignature(&this, pguidSignature);

	public HRESULT GetInstanceSignature(BSTR* pbstrId) mut => VT.[Friend]GetInstanceSignature(&this, pbstrId);

	public HRESULT GetFriendlyName(uint32 lcid, BSTR* pbstrName) mut => VT.[Friend]GetFriendlyName(&this, lcid, pbstrName);

	public HRESULT GetRadioState(DEVICE_RADIO_STATE* pRadioState) mut => VT.[Friend]GetRadioState(&this, pRadioState);

	public HRESULT SetRadioState(DEVICE_RADIO_STATE radioState, uint32 uTimeoutSec) mut => VT.[Friend]SetRadioState(&this, radioState, uTimeoutSec);

	public BOOL IsMultiComm() mut => VT.[Friend]IsMultiComm(&this);

	public BOOL IsAssociatingDevice() mut => VT.[Friend]IsAssociatingDevice(&this);
}

[CRepr]struct IMediaRadioManagerNotifySink : IUnknown
{
	public new const Guid IID = .(0x89d81f5f, 0xc147, 0x49ed, 0xa1, 0x1c, 0x77, 0xb2, 0x0c, 0x31, 0xe7, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRadioInstance* pRadioInstance) OnInstanceAdd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRadioInstanceId) OnInstanceRemove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRadioInstanceId, DEVICE_RADIO_STATE radioState) OnInstanceRadioChange;
	}


	public HRESULT OnInstanceAdd(IRadioInstance* pRadioInstance) mut => VT.[Friend]OnInstanceAdd(&this, pRadioInstance);

	public HRESULT OnInstanceRemove(BSTR bstrRadioInstanceId) mut => VT.[Friend]OnInstanceRemove(&this, bstrRadioInstanceId);

	public HRESULT OnInstanceRadioChange(BSTR bstrRadioInstanceId, DEVICE_RADIO_STATE radioState) mut => VT.[Friend]OnInstanceRadioChange(&this, bstrRadioInstanceId, radioState);
}

#endregion

#region Functions
public static
{
	[Import("DMProcessXMLFiltered.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DMProcessConfigXMLFiltered(PWSTR pszXmlIn, PWSTR* rgszAllowedCspNodes, uint32 dwNumAllowedCspNodes, BSTR* pbstrXmlOut);

}
#endregion
