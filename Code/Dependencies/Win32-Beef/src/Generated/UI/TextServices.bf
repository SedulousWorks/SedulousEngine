using Win32.Foundation;
using Win32.System.Com;
using Win32.UI.WindowsAndMessaging;
using Win32.Graphics.Gdi;
using System;

namespace Win32.UI.TextServices;

#region Constants
public static
{
	public const Guid GUID_PROP_TEXTOWNER = .(0xf1e2d520, 0x0969, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_PROP_ATTRIBUTE = .(0x34b45670, 0x7526, 0x11d2, 0xa1, 0x47, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_PROP_LANGID = .(0x3280ce20, 0x8032, 0x11d2, 0xb6, 0x03, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_PROP_READING = .(0x5463f7c0, 0x8e31, 0x11d2, 0xbf, 0x46, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_PROP_COMPOSING = .(0xe12ac060, 0xaf15, 0x11d2, 0xaf, 0xc5, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_PROP_TKB_ALTERNATES = .(0x70b2a803, 0x968d, 0x462e, 0xb9, 0x3b, 0x21, 0x64, 0xc9, 0x15, 0x17, 0xf7);
	public const Guid GUID_SYSTEM_FUNCTIONPROVIDER = .(0x9a698bb0, 0x0f21, 0x11d3, 0x8d, 0xf1, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);
	public const Guid GUID_APP_FUNCTIONPROVIDER = .(0x4caef01e, 0x12af, 0x4b0e, 0x9d, 0xb1, 0xa6, 0xec, 0x5b, 0x88, 0x12, 0x08);
	public const Guid GUID_TFCAT_CATEGORY_OF_TIP = .(0x534c48c1, 0x0607, 0x4098, 0xa5, 0x21, 0x4f, 0xc8, 0x99, 0xc7, 0x3e, 0x90);
	public const Guid GUID_TFCAT_TIP_KEYBOARD = .(0x34745c63, 0xb2f0, 0x4784, 0x8b, 0x67, 0x5e, 0x12, 0xc8, 0x70, 0x1a, 0x31);
	public const Guid GUID_TFCAT_TIP_SPEECH = .(0xb5a73cd1, 0x8355, 0x426b, 0xa1, 0x61, 0x25, 0x98, 0x08, 0xf2, 0x6b, 0x14);
	public const Guid GUID_TFCAT_TIP_HANDWRITING = .(0x246ecb87, 0xc2f2, 0x4abe, 0x90, 0x5b, 0xc8, 0xb3, 0x8a, 0xdd, 0x2c, 0x43);
	public const Guid GUID_TFCAT_PROP_AUDIODATA = .(0x9b7be3a9, 0xe8ab, 0x4d47, 0xa8, 0xfe, 0x25, 0x4f, 0xa4, 0x23, 0x43, 0x6d);
	public const Guid GUID_TFCAT_PROP_INKDATA = .(0x7c6a82ae, 0xb0d7, 0x4f14, 0xa7, 0x45, 0x14, 0xf2, 0x8b, 0x00, 0x9d, 0x61);
	public const Guid GUID_COMPARTMENT_SAPI_AUDIO = .(0x51af2086, 0xcc6b, 0x457d, 0xb5, 0xaa, 0x8b, 0x19, 0xdc, 0x29, 0x0a, 0xb4);
	public const Guid GUID_COMPARTMENT_KEYBOARD_DISABLED = .(0x71a5b253, 0x1951, 0x466b, 0x9f, 0xbc, 0x9c, 0x88, 0x08, 0xfa, 0x84, 0xf2);
	public const Guid GUID_COMPARTMENT_KEYBOARD_OPENCLOSE = .(0x58273aad, 0x01bb, 0x4164, 0x95, 0xc6, 0x75, 0x5b, 0xa0, 0xb5, 0x16, 0x2d);
	public const Guid GUID_COMPARTMENT_HANDWRITING_OPENCLOSE = .(0xf9ae2c6b, 0x1866, 0x4361, 0xaf, 0x72, 0x7a, 0xa3, 0x09, 0x48, 0x89, 0x0e);
	public const Guid GUID_COMPARTMENT_SPEECH_DISABLED = .(0x56c5c607, 0x0703, 0x4e59, 0x8e, 0x52, 0xcb, 0xc8, 0x4e, 0x8b, 0xbe, 0x35);
	public const Guid GUID_COMPARTMENT_SPEECH_OPENCLOSE = .(0x544d6a63, 0xe2e8, 0x4752, 0xbb, 0xd1, 0x00, 0x09, 0x60, 0xbc, 0xa0, 0x83);
	public const Guid GUID_COMPARTMENT_SPEECH_GLOBALSTATE = .(0x2a54fe8e, 0x0d08, 0x460c, 0xa7, 0x5d, 0x87, 0x03, 0x5f, 0xf4, 0x36, 0xc5);
	public const Guid GUID_COMPARTMENT_CONVERSIONMODEBIAS = .(0x5497f516, 0xee91, 0x436e, 0xb9, 0x46, 0xaa, 0x2c, 0x05, 0xf1, 0xac, 0x5b);
	public const Guid GUID_PROP_MODEBIAS = .(0x372e0716, 0x974f, 0x40ac, 0xa0, 0x88, 0x08, 0xcd, 0xc9, 0x2e, 0xbf, 0xbc);
	public const Guid GUID_COMPARTMENT_KEYBOARD_INPUTMODE = .(0xb6592511, 0xbcee, 0x4122, 0xa7, 0xc4, 0x09, 0xf4, 0xb3, 0xfa, 0x43, 0x96);
	public const Guid GUID_MODEBIAS_NONE = .(0x00000000, 0x0000, 0x0000, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid GUID_MODEBIAS_URLHISTORY = .(0x8b0e54d9, 0x63f2, 0x4c68, 0x84, 0xd4, 0x79, 0xae, 0xe7, 0xa5, 0x9f, 0x09);
	public const Guid GUID_MODEBIAS_FILENAME = .(0xd7f707fe, 0x44c6, 0x4fca, 0x8e, 0x76, 0x86, 0xab, 0x50, 0xc7, 0x93, 0x1b);
	public const Guid GUID_MODEBIAS_READING = .(0xe31643a3, 0x6466, 0x4cbf, 0x8d, 0x8b, 0x0b, 0xd4, 0xd8, 0x54, 0x54, 0x61);
	public const Guid GUID_MODEBIAS_DATETIME = .(0xf2bdb372, 0x7f61, 0x4039, 0x92, 0xef, 0x1c, 0x35, 0x59, 0x9f, 0x02, 0x22);
	public const Guid GUID_MODEBIAS_NAME = .(0xfddc10f0, 0xd239, 0x49bf, 0xb8, 0xfc, 0x54, 0x10, 0xca, 0xaa, 0x42, 0x7e);
	public const Guid GUID_MODEBIAS_CONVERSATION = .(0x0f4ec104, 0x1790, 0x443b, 0x95, 0xf1, 0xe1, 0x0f, 0x93, 0x9d, 0x65, 0x46);
	public const Guid GUID_MODEBIAS_NUMERIC = .(0x4021766c, 0xe872, 0x48fd, 0x9c, 0xee, 0x4e, 0xc5, 0xc7, 0x5e, 0x16, 0xc3);
	public const Guid GUID_MODEBIAS_HIRAGANA = .(0xd73d316e, 0x9b91, 0x46f1, 0xa2, 0x80, 0x31, 0x59, 0x7f, 0x52, 0xc6, 0x94);
	public const Guid GUID_MODEBIAS_KATAKANA = .(0x2e0eeddd, 0x3a1a, 0x499e, 0x85, 0x43, 0x3c, 0x7e, 0xe7, 0x94, 0x98, 0x11);
	public const Guid GUID_MODEBIAS_HANGUL = .(0x76ef0541, 0x23b3, 0x4d77, 0xa0, 0x74, 0x69, 0x18, 0x01, 0xcc, 0xea, 0x17);
	public const Guid GUID_MODEBIAS_CHINESE = .(0x7add26de, 0x4328, 0x489b, 0x83, 0xae, 0x64, 0x93, 0x75, 0x0c, 0xad, 0x5c);
	public const Guid GUID_MODEBIAS_HALFWIDTHKATAKANA = .(0x005f6b63, 0x78d4, 0x41cc, 0x88, 0x59, 0x48, 0x5c, 0xa8, 0x21, 0xa7, 0x95);
	public const Guid GUID_MODEBIAS_FULLWIDTHALPHANUMERIC = .(0x81489fb8, 0xb36a, 0x473d, 0x81, 0x46, 0xe4, 0xa2, 0x25, 0x8b, 0x24, 0xae);
	public const Guid GUID_MODEBIAS_FULLWIDTHHANGUL = .(0xc01ae6c9, 0x45b5, 0x4fd0, 0x9c, 0xb1, 0x9f, 0x4c, 0xeb, 0xc3, 0x9f, 0xea);
	public const Guid GUID_TFCAT_PROPSTYLE_STATIC = .(0x565fb8d8, 0x6bd4, 0x4ca1, 0xb2, 0x23, 0x0f, 0x2c, 0xcb, 0x8f, 0x4f, 0x96);
	public const Guid GUID_TFCAT_DISPLAYATTRIBUTEPROVIDER = .(0x046b8c80, 0x1647, 0x40f7, 0x9b, 0x21, 0xb9, 0x3b, 0x81, 0xaa, 0xbc, 0x1b);
	public const Guid GUID_TFCAT_DISPLAYATTRIBUTEPROPERTY = .(0xb95f181b, 0xea4c, 0x4af1, 0x80, 0x56, 0x7c, 0x32, 0x1a, 0xbb, 0xb0, 0x91);
	public const Guid GUID_COMPARTMENT_SPEECH_UI_STATUS = .(0xd92016f0, 0x9367, 0x4fe7, 0x9a, 0xbf, 0xbc, 0x59, 0xda, 0xcb, 0xe0, 0xe3);
	public const Guid GUID_COMPARTMENT_EMPTYCONTEXT = .(0xd7487dbf, 0x804e, 0x41c5, 0x89, 0x4d, 0xad, 0x96, 0xfd, 0x4e, 0xea, 0x13);
	public const Guid GUID_COMPARTMENT_TIPUISTATUS = .(0x148ca3ec, 0x0366, 0x401c, 0x8d, 0x75, 0xed, 0x97, 0x8d, 0x85, 0xfb, 0xc9);
	public const Guid GUID_COMPARTMENT_SPEECH_CFGMENU = .(0xfb6c5c2d, 0x4e83, 0x4bb6, 0x91, 0xa2, 0xe0, 0x19, 0xbf, 0xf6, 0x76, 0x2d);
	public const Guid GUID_LBI_SAPILAYR_CFGMENUBUTTON = .(0xd02f24a1, 0x942d, 0x422e, 0x8d, 0x99, 0xb4, 0xf2, 0xad, 0xde, 0xe9, 0x99);
	public const Guid GUID_TFCAT_TIPCAP_SECUREMODE = .(0x49d2f9ce, 0x1f5e, 0x11d7, 0xa6, 0xd3, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_TFCAT_TIPCAP_UIELEMENTENABLED = .(0x49d2f9cf, 0x1f5e, 0x11d7, 0xa6, 0xd3, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_TFCAT_TIPCAP_INPUTMODECOMPARTMENT = .(0xccf05dd7, 0x4a87, 0x11d7, 0xa6, 0xe2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_TFCAT_TIPCAP_COMLESS = .(0x364215d9, 0x75bc, 0x11d7, 0xa6, 0xef, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_TFCAT_TIPCAP_WOW16 = .(0x364215da, 0x75bc, 0x11d7, 0xa6, 0xef, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_TFCAT_TIPCAP_IMMERSIVESUPPORT = .(0x13a016df, 0x560b, 0x46cd, 0x94, 0x7a, 0x4c, 0x3a, 0xf1, 0xe0, 0xe3, 0x5d);
	public const Guid GUID_TFCAT_TIPCAP_IMMERSIVEONLY = .(0x3a4259ac, 0x640d, 0x4ad4, 0x89, 0xf7, 0x1e, 0xb6, 0x7e, 0x7c, 0x4e, 0xe8);
	public const Guid GUID_TFCAT_TIPCAP_LOCALSERVER = .(0x74769ee9, 0x4a66, 0x4f9d, 0x90, 0xd6, 0xbf, 0x8b, 0x7c, 0x3e, 0xb4, 0x61);
	public const Guid GUID_TFCAT_TIPCAP_TSF3 = .(0x07dcb4af, 0x98de, 0x4548, 0xbe, 0xf7, 0x25, 0xbd, 0x45, 0x97, 0x9a, 0x1f);
	public const Guid GUID_TFCAT_TIPCAP_DUALMODE = .(0x3af314a2, 0xd79f, 0x4b1b, 0x99, 0x92, 0x15, 0x08, 0x6d, 0x33, 0x9b, 0x05);
	public const Guid GUID_TFCAT_TIPCAP_SYSTRAYSUPPORT = .(0x25504fb4, 0x7bab, 0x4bc1, 0x9c, 0x69, 0xcf, 0x81, 0x89, 0x0f, 0x0e, 0xf5);
	public const Guid GUID_COMPARTMENT_KEYBOARD_INPUTMODE_CONVERSION = .(0xccf05dd8, 0x4a87, 0x11d7, 0xa6, 0xe2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_COMPARTMENT_KEYBOARD_INPUTMODE_SENTENCE = .(0xccf05dd9, 0x4a87, 0x11d7, 0xa6, 0xe2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_COMPARTMENT_TRANSITORYEXTENSION = .(0x8be347f5, 0xc7a0, 0x11d7, 0xb4, 0x08, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_COMPARTMENT_TRANSITORYEXTENSION_DOCUMENTMANAGER = .(0x8be347f7, 0xc7a0, 0x11d7, 0xb4, 0x08, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_COMPARTMENT_TRANSITORYEXTENSION_PARENT = .(0x8be347f8, 0xc7a0, 0x11d7, 0xb4, 0x08, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);
	public const Guid GUID_COMPARTMENT_ENABLED_PROFILES_UPDATED = .(0x92c1fd48, 0xa9ae, 0x4a7c, 0xbe, 0x08, 0x43, 0x29, 0xe4, 0x72, 0x38, 0x17);
	public const Guid GUID_TFCAT_TRANSITORYEXTENSIONUI = .(0x6302de22, 0xa5cf, 0x4b02, 0xbf, 0xe8, 0x4d, 0x72, 0xb2, 0xbe, 0xd3, 0xc6);
	public const Guid GUID_LBI_INPUTMODE = .(0x2c77a81e, 0x41cc, 0x4178, 0xa3, 0xa7, 0x5f, 0x8a, 0x98, 0x75, 0x68, 0xe6);
	public const Guid CLSID_TF_ThreadMgr = .(0x529a9e6b, 0x6587, 0x4f23, 0xab, 0x9e, 0x9c, 0x7d, 0x68, 0x3e, 0x3c, 0x50);
	public const Guid CLSID_TF_LangBarMgr = .(0xebb08c45, 0x6c4a, 0x4fdc, 0xae, 0x53, 0x4e, 0xb8, 0xc4, 0xc7, 0xdb, 0x8e);
	public const Guid CLSID_TF_DisplayAttributeMgr = .(0x3ce74de4, 0x53d3, 0x4d74, 0x8b, 0x83, 0x43, 0x1b, 0x38, 0x28, 0xba, 0x53);
	public const Guid CLSID_TF_CategoryMgr = .(0xa4b544a1, 0x438d, 0x4b41, 0x93, 0x25, 0x86, 0x95, 0x23, 0xe2, 0xd6, 0xc7);
	public const Guid CLSID_TF_InputProcessorProfiles = .(0x33c53a50, 0xf456, 0x4884, 0xb0, 0x49, 0x85, 0xfd, 0x64, 0x3e, 0xcf, 0xed);
	public const Guid CLSID_TF_LangBarItemMgr = .(0xb9931692, 0xa2b3, 0x4fab, 0xbf, 0x33, 0x9e, 0xc6, 0xf9, 0xfb, 0x96, 0xac);
	public const Guid CLSID_TF_ClassicLangBar = .(0x3318360c, 0x1afc, 0x4d09, 0xa8, 0x6b, 0x9f, 0x9c, 0xb6, 0xdc, 0xeb, 0x9c);
	public const Guid CLSID_TF_TransitoryExtensionUIEntry = .(0xae6be008, 0x07fb, 0x400d, 0x8b, 0xeb, 0x33, 0x7a, 0x64, 0xf7, 0x05, 0x1f);
	public const Guid CLSID_TsfServices = .(0x39aedc00, 0x6b60, 0x46db, 0x8d, 0x31, 0x36, 0x42, 0xbe, 0x0e, 0x43, 0x73);
	public const Guid GUID_TS_SERVICE_DATAOBJECT = .(0x6086fbb5, 0xe225, 0x46ce, 0xa7, 0x70, 0xc1, 0xbb, 0xd3, 0xe0, 0x5d, 0x7b);
	public const Guid GUID_TS_SERVICE_ACCESSIBLE = .(0xf9786200, 0xa5bf, 0x4a0f, 0x8c, 0x24, 0xfb, 0x16, 0xf5, 0xd1, 0xaa, 0xbb);
	public const Guid GUID_TS_SERVICE_ACTIVEX = .(0xea937a50, 0xc9a6, 0x4b7d, 0x89, 0x4a, 0x49, 0xd9, 0x9b, 0x78, 0x48, 0x34);
	public const HRESULT TS_E_INVALIDPOS = -2147220992;
	public const HRESULT TS_E_NOLOCK = -2147220991;
	public const HRESULT TS_E_NOOBJECT = -2147220990;
	public const HRESULT TS_E_NOSERVICE = -2147220989;
	public const HRESULT TS_E_NOINTERFACE = -2147220988;
	public const HRESULT TS_E_NOSELECTION = -2147220987;
	public const HRESULT TS_E_NOLAYOUT = -2147220986;
	public const HRESULT TS_E_INVALIDPOINT = -2147220985;
	public const HRESULT TS_E_SYNCHRONOUS = -2147220984;
	public const HRESULT TS_E_READONLY = -2147220983;
	public const HRESULT TS_E_FORMAT = -2147220982;
	public const HRESULT TS_S_ASYNC = 262912;
	public const uint32 TS_AS_TEXT_CHANGE = 1;
	public const uint32 TS_AS_SEL_CHANGE = 2;
	public const uint32 TS_AS_LAYOUT_CHANGE = 4;
	public const uint32 TS_AS_ATTR_CHANGE = 8;
	public const uint32 TS_AS_STATUS_CHANGE = 16;
	public const uint32 TS_LF_SYNC = 1;
	public const uint32 TS_SD_READONLY = 1;
	public const uint32 TS_SD_LOADING = 2;
	public const uint32 TS_SD_RESERVED = 4;
	public const uint32 TS_SD_TKBAUTOCORRECTENABLE = 8;
	public const uint32 TS_SD_TKBPREDICTIONENABLE = 16;
	public const uint32 TS_SD_UIINTEGRATIONENABLE = 32;
	public const uint32 TS_SD_INPUTPANEMANUALDISPLAYENABLE = 64;
	public const uint32 TS_SD_EMBEDDEDHANDWRITINGVIEW_ENABLED = 128;
	public const uint32 TS_SD_EMBEDDEDHANDWRITINGVIEW_VISIBLE = 256;
	public const uint32 TS_SS_DISJOINTSEL = 1;
	public const uint32 TS_SS_REGIONS = 2;
	public const uint32 TS_SS_TRANSITORY = 4;
	public const uint32 TS_SS_NOHIDDENTEXT = 8;
	public const uint32 TS_SS_TKBAUTOCORRECTENABLE = 16;
	public const uint32 TS_SS_TKBPREDICTIONENABLE = 32;
	public const uint32 TS_SS_UWPCONTROL = 64;
	public const uint32 TS_IE_CORRECTION = 1;
	public const uint32 TS_IE_COMPOSITION = 2;
	public const uint32 TS_IAS_NOQUERY = 1;
	public const uint32 TS_IAS_QUERYONLY = 2;
	public const uint32 GXFPF_ROUND_NEAREST = 1;
	public const uint32 GXFPF_NEAREST = 2;
	public const uint32 TS_CHAR_EMBEDDED = 65532;
	public const uint32 TS_CHAR_REGION = 0;
	public const uint32 TS_CHAR_REPLACEMENT = 65533;
	public const uint32 TS_ATTR_FIND_BACKWARDS = 1;
	public const uint32 TS_ATTR_FIND_WANT_OFFSET = 2;
	public const uint32 TS_ATTR_FIND_UPDATESTART = 4;
	public const uint32 TS_ATTR_FIND_WANT_VALUE = 8;
	public const uint32 TS_ATTR_FIND_WANT_END = 16;
	public const uint32 TS_ATTR_FIND_HIDDEN = 32;
	public const uint32 TS_VCOOKIE_NUL = 4294967295;
	public const uint32 TS_SHIFT_COUNT_HIDDEN = 1;
	public const uint32 TS_SHIFT_HALT_HIDDEN = 2;
	public const uint32 TS_SHIFT_HALT_VISIBLE = 4;
	public const uint32 TS_SHIFT_COUNT_ONLY = 8;
	public const uint32 TS_GTA_HIDDEN = 1;
	public const uint32 TS_GEA_HIDDEN = 1;
	public const HRESULT TF_E_LOCKED = -2147220224;
	public const HRESULT TF_E_STACKFULL = -2147220223;
	public const HRESULT TF_E_NOTOWNEDRANGE = -2147220222;
	public const HRESULT TF_E_NOPROVIDER = -2147220221;
	public const HRESULT TF_E_DISCONNECTED = -2147220220;
	public const HRESULT TF_E_INVALIDVIEW = -2147220219;
	public const HRESULT TF_E_ALREADY_EXISTS = -2147220218;
	public const HRESULT TF_E_RANGE_NOT_COVERED = -2147220217;
	public const HRESULT TF_E_COMPOSITION_REJECTED = -2147220216;
	public const HRESULT TF_E_EMPTYCONTEXT = -2147220215;
	public const HRESULT TF_E_INVALIDPOS = -2147220992;
	public const HRESULT TF_E_NOLOCK = -2147220991;
	public const HRESULT TF_E_NOOBJECT = -2147220990;
	public const HRESULT TF_E_NOSERVICE = -2147220989;
	public const HRESULT TF_E_NOINTERFACE = -2147220988;
	public const HRESULT TF_E_NOSELECTION = -2147220987;
	public const HRESULT TF_E_NOLAYOUT = -2147220986;
	public const HRESULT TF_E_INVALIDPOINT = -2147220985;
	public const HRESULT TF_E_SYNCHRONOUS = -2147220984;
	public const HRESULT TF_E_READONLY = -2147220983;
	public const HRESULT TF_E_FORMAT = -2147220982;
	public const HRESULT TF_S_ASYNC = 262912;
	public const uint32 TF_RCM_COMLESS = 1;
	public const uint32 TF_RCM_VKEY = 2;
	public const uint32 TF_RCM_HINT_READING_LENGTH = 4;
	public const uint32 TF_RCM_HINT_COLLISION = 8;
	public const uint32 TKB_ALTERNATES_STANDARD = 1;
	public const uint32 TKB_ALTERNATES_FOR_AUTOCORRECTION = 2;
	public const uint32 TKB_ALTERNATES_FOR_PREDICTION = 3;
	public const uint32 TKB_ALTERNATES_AUTOCORRECTION_APPLIED = 4;
	public const uint32 TF_TMAE_NOACTIVATETIP = 1;
	public const uint32 TF_TMAE_SECUREMODE = 2;
	public const uint32 TF_TMAE_UIELEMENTENABLEDONLY = 4;
	public const uint32 TF_TMAE_COMLESS = 8;
	public const uint32 TF_TMAE_WOW16 = 16;
	public const uint32 TF_TMAE_NOACTIVATEKEYBOARDLAYOUT = 32;
	public const uint32 TF_TMAE_CONSOLE = 64;
	public const uint32 TF_TMF_NOACTIVATETIP = 1;
	public const uint32 TF_TMF_SECUREMODE = 2;
	public const uint32 TF_TMF_UIELEMENTENABLEDONLY = 4;
	public const uint32 TF_TMF_COMLESS = 8;
	public const uint32 TF_TMF_WOW16 = 16;
	public const uint32 TF_TMF_CONSOLE = 64;
	public const uint32 TF_TMF_IMMERSIVEMODE = 1073741824;
	public const uint32 TF_TMF_ACTIVATED = 2147483648;
	public const uint32 TF_MOD_ALT = 1;
	public const uint32 TF_MOD_CONTROL = 2;
	public const uint32 TF_MOD_SHIFT = 4;
	public const uint32 TF_MOD_RALT = 8;
	public const uint32 TF_MOD_RCONTROL = 16;
	public const uint32 TF_MOD_RSHIFT = 32;
	public const uint32 TF_MOD_LALT = 64;
	public const uint32 TF_MOD_LCONTROL = 128;
	public const uint32 TF_MOD_LSHIFT = 256;
	public const uint32 TF_MOD_ON_KEYUP = 512;
	public const uint32 TF_MOD_IGNORE_ALL_MODIFIER = 1024;
	public const uint32 TF_US_HIDETIPUI = 1;
	public const uint32 TF_DISABLE_SPEECH = 1;
	public const uint32 TF_DISABLE_DICTATION = 2;
	public const uint32 TF_DISABLE_COMMANDING = 4;
	public const String TF_PROCESS_ATOM = "_CTF_PROCESS_ATOM_";
	public const String TF_ENABLE_PROCESS_ATOM = "_CTF_ENABLE_PROCESS_ATOM_";
	public const uint32 TF_CLUIE_DOCUMENTMGR = 1;
	public const uint32 TF_CLUIE_COUNT = 2;
	public const uint32 TF_CLUIE_SELECTION = 4;
	public const uint32 TF_CLUIE_STRING = 8;
	public const uint32 TF_CLUIE_PAGEINDEX = 16;
	public const uint32 TF_CLUIE_CURRENTPAGE = 32;
	public const uint32 TF_RIUIE_CONTEXT = 1;
	public const uint32 TF_RIUIE_STRING = 2;
	public const uint32 TF_RIUIE_MAXREADINGSTRINGLENGTH = 4;
	public const uint32 TF_RIUIE_ERRORINDEX = 8;
	public const uint32 TF_RIUIE_VERTICALORDER = 16;
	public const uint32 TF_CONVERSIONMODE_ALPHANUMERIC = 0;
	public const uint32 TF_CONVERSIONMODE_NATIVE = 1;
	public const uint32 TF_CONVERSIONMODE_KATAKANA = 2;
	public const uint32 TF_CONVERSIONMODE_FULLSHAPE = 8;
	public const uint32 TF_CONVERSIONMODE_ROMAN = 16;
	public const uint32 TF_CONVERSIONMODE_CHARCODE = 32;
	public const uint32 TF_CONVERSIONMODE_SOFTKEYBOARD = 128;
	public const uint32 TF_CONVERSIONMODE_NOCONVERSION = 256;
	public const uint32 TF_CONVERSIONMODE_EUDC = 512;
	public const uint32 TF_CONVERSIONMODE_SYMBOL = 1024;
	public const uint32 TF_CONVERSIONMODE_FIXED = 2048;
	public const uint32 TF_SENTENCEMODE_NONE = 0;
	public const uint32 TF_SENTENCEMODE_PLAURALCLAUSE = 1;
	public const uint32 TF_SENTENCEMODE_SINGLECONVERT = 2;
	public const uint32 TF_SENTENCEMODE_AUTOMATIC = 4;
	public const uint32 TF_SENTENCEMODE_PHRASEPREDICT = 8;
	public const uint32 TF_SENTENCEMODE_CONVERSATION = 16;
	public const uint32 TF_TRANSITORYEXTENSION_NONE = 0;
	public const uint32 TF_TRANSITORYEXTENSION_FLOATING = 1;
	public const uint32 TF_TRANSITORYEXTENSION_ATSELECTION = 2;
	public const uint32 TF_PROFILETYPE_INPUTPROCESSOR = 1;
	public const uint32 TF_PROFILETYPE_KEYBOARDLAYOUT = 2;
	public const uint32 TF_RIP_FLAG_FREEUNUSEDLIBRARIES = 1;
	public const uint32 TF_IPP_FLAG_ACTIVE = 1;
	public const uint32 TF_IPP_FLAG_ENABLED = 2;
	public const uint32 TF_IPP_FLAG_SUBSTITUTEDBYINPUTPROCESSOR = 4;
	public const uint32 TF_IPP_CAPS_DISABLEONTRANSITORY = 1;
	public const uint32 TF_IPP_CAPS_SECUREMODESUPPORT = 2;
	public const uint32 TF_IPP_CAPS_UIELEMENTENABLED = 4;
	public const uint32 TF_IPP_CAPS_COMLESSSUPPORT = 8;
	public const uint32 TF_IPP_CAPS_WOW16SUPPORT = 16;
	public const uint32 TF_IPP_CAPS_IMMERSIVESUPPORT = 65536;
	public const uint32 TF_IPP_CAPS_SYSTRAYSUPPORT = 131072;
	public const uint32 TF_IPPMF_FORPROCESS = 268435456;
	public const uint32 TF_IPPMF_FORSESSION = 536870912;
	public const uint32 TF_IPPMF_FORSYSTEMALL = 1073741824;
	public const uint32 TF_IPPMF_ENABLEPROFILE = 1;
	public const uint32 TF_IPPMF_DISABLEPROFILE = 2;
	public const uint32 TF_IPPMF_DONTCARECURRENTINPUTLANGUAGE = 4;
	public const uint32 TF_RP_HIDDENINSETTINGUI = 2;
	public const uint32 TF_RP_LOCALPROCESS = 4;
	public const uint32 TF_RP_LOCALTHREAD = 8;
	public const uint32 TF_RP_SUBITEMINSETTINGUI = 16;
	public const uint32 TF_URP_ALLPROFILES = 2;
	public const uint32 TF_URP_LOCALPROCESS = 4;
	public const uint32 TF_URP_LOCALTHREAD = 8;
	public const uint32 TF_IPSINK_FLAG_ACTIVE = 1;
	public const uint32 TF_INVALID_EDIT_COOKIE = 0;
	public const uint32 TF_POPF_ALL = 1;
	public const uint32 TF_SD_READONLY = 1;
	public const uint32 TF_SD_LOADING = 2;
	public const uint32 TF_SS_DISJOINTSEL = 1;
	public const uint32 TF_SS_REGIONS = 2;
	public const uint32 TF_SS_TRANSITORY = 4;
	public const uint32 TF_SS_TKBAUTOCORRECTENABLE = 16;
	public const uint32 TF_SS_TKBPREDICTIONENABLE = 32;
	public const uint32 TF_CHAR_EMBEDDED = 65532;
	public const uint32 TF_HF_OBJECT = 1;
	public const uint32 TF_TF_MOVESTART = 1;
	public const uint32 TF_TF_IGNOREEND = 2;
	public const uint32 TF_ST_CORRECTION = 1;
	public const uint32 TF_IE_CORRECTION = 1;
	public const uint32 TF_TU_CORRECTION = 1;
	public const uint32 TF_INVALID_COOKIE = 4294967295;
	public const Guid TF_PROFILE_NEWPHONETIC = .(0xb2f9c502, 0x1742, 0x11d4, 0x97, 0x90, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_PHONETIC = .(0x761309de, 0x317a, 0x11d4, 0x9b, 0x5d, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_NEWCHANGJIE = .(0xf3ba907a, 0x6c7e, 0x11d4, 0x97, 0xfa, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_CHANGJIE = .(0x4bdf9f03, 0xc7d3, 0x11d4, 0xb2, 0xab, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_NEWQUICK = .(0x0b883ba0, 0xc1c7, 0x11d4, 0x87, 0xf9, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_QUICK = .(0x6024b45f, 0x5c54, 0x11d4, 0xb9, 0x21, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_CANTONESE = .(0x0aec109c, 0x7e96, 0x11d4, 0xb2, 0xef, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_PINYIN = .(0xf3ba9077, 0x6c7e, 0x11d4, 0x97, 0xfa, 0x00, 0x80, 0xc8, 0x82, 0x68, 0x7e);
	public const Guid TF_PROFILE_SIMPLEFAST = .(0xfa550b04, 0x5ad7, 0x411f, 0xa5, 0xac, 0xca, 0x03, 0x8e, 0xc5, 0x15, 0xd7);
	public const Guid TF_PROFILE_WUBI = .(0x82590c13, 0xf4dd, 0x44f4, 0xba, 0x1d, 0x86, 0x67, 0x24, 0x6f, 0xdf, 0x8e);
	public const Guid TF_PROFILE_DAYI = .(0x037b2c25, 0x480c, 0x4d7f, 0xb0, 0x27, 0xd6, 0xca, 0x6b, 0x69, 0x78, 0x8a);
	public const Guid TF_PROFILE_ARRAY = .(0xd38eff65, 0xaa46, 0x4fd5, 0x91, 0xa7, 0x67, 0x84, 0x5f, 0xb0, 0x2f, 0x5b);
	public const Guid TF_PROFILE_YI = .(0x409c8376, 0x007b, 0x4357, 0xae, 0x8e, 0x26, 0x31, 0x6e, 0xe3, 0xfb, 0x0d);
	public const Guid TF_PROFILE_TIGRINYA = .(0x3cab88b7, 0xcc3e, 0x46a6, 0x97, 0x65, 0xb7, 0x72, 0xad, 0x77, 0x61, 0xff);
	public const HRESULT TF_E_NOCONVERSION = -2147219968;
	public const uint32 TF_DICTATION_ON = 1;
	public const uint32 TF_DICTATION_ENABLED = 2;
	public const uint32 TF_COMMANDING_ENABLED = 4;
	public const uint32 TF_COMMANDING_ON = 8;
	public const uint32 TF_SPEECHUI_SHOWN = 16;
	public const uint32 TF_SHOW_BALLOON = 1;
	public const uint32 TF_DISABLE_BALLOON = 2;
	public const uint32 TF_MENUREADY = 1;
	public const uint32 TF_PROPUI_STATUS_SAVETOFILE = 1;
	public const Guid GUID_INTEGRATIONSTYLE_SEARCHBOX = .(0xe6d1bd11, 0x82f7, 0x4903, 0xae, 0x21, 0x1a, 0x63, 0x97, 0xcd, 0xe2, 0xeb);
	public const uint32 TKBL_UNDEFINED = 0;
	public const uint32 TKBL_CLASSIC_TRADITIONAL_CHINESE_PHONETIC = 1028;
	public const uint32 TKBL_CLASSIC_TRADITIONAL_CHINESE_CHANGJIE = 61506;
	public const uint32 TKBL_CLASSIC_TRADITIONAL_CHINESE_DAYI = 61507;
	public const uint32 TKBL_OPT_JAPANESE_ABC = 1041;
	public const uint32 TKBL_OPT_KOREAN_HANGUL_2_BULSIK = 1042;
	public const uint32 TKBL_OPT_SIMPLIFIED_CHINESE_PINYIN = 2052;
	public const uint32 TKBL_OPT_TRADITIONAL_CHINESE_PHONETIC = 1028;
	public const String TF_FLOATINGLANGBAR_WNDTITLEW = "TF_FloatingLangBar_WndTitle";
	public const String TF_FLOATINGLANGBAR_WNDTITLEA = "TF_FloatingLangBar_WndTitle";
	public const String TF_FLOATINGLANGBAR_WNDTITLE = "TF_FloatingLangBar_WndTitle";
	public const uint32 TF_LBI_ICON = 1;
	public const uint32 TF_LBI_TEXT = 2;
	public const uint32 TF_LBI_TOOLTIP = 4;
	public const uint32 TF_LBI_BITMAP = 8;
	public const uint32 TF_LBI_BALLOON = 16;
	public const uint32 TF_LBI_CUSTOMUI = 32;
	public const uint32 TF_LBI_STATUS = 65536;
	public const uint32 TF_LBI_STYLE_HIDDENSTATUSCONTROL = 1;
	public const uint32 TF_LBI_STYLE_SHOWNINTRAY = 2;
	public const uint32 TF_LBI_STYLE_HIDEONNOOTHERITEMS = 4;
	public const uint32 TF_LBI_STYLE_SHOWNINTRAYONLY = 8;
	public const uint32 TF_LBI_STYLE_HIDDENBYDEFAULT = 16;
	public const uint32 TF_LBI_STYLE_TEXTCOLORICON = 32;
	public const uint32 TF_LBI_STYLE_BTN_BUTTON = 65536;
	public const uint32 TF_LBI_STYLE_BTN_MENU = 131072;
	public const uint32 TF_LBI_STYLE_BTN_TOGGLE = 262144;
	public const uint32 TF_LBI_STATUS_HIDDEN = 1;
	public const uint32 TF_LBI_STATUS_DISABLED = 2;
	public const uint32 TF_LBI_STATUS_BTN_TOGGLED = 65536;
	public const uint32 TF_LBI_BMPF_VERTICAL = 1;
	public const uint32 TF_SFT_SHOWNORMAL = 1;
	public const uint32 TF_SFT_DOCK = 2;
	public const uint32 TF_SFT_MINIMIZED = 4;
	public const uint32 TF_SFT_HIDDEN = 8;
	public const uint32 TF_SFT_NOTRANSPARENCY = 16;
	public const uint32 TF_SFT_LOWTRANSPARENCY = 32;
	public const uint32 TF_SFT_HIGHTRANSPARENCY = 64;
	public const uint32 TF_SFT_LABELS = 128;
	public const uint32 TF_SFT_NOLABELS = 256;
	public const uint32 TF_SFT_EXTRAICONSONMINIMIZED = 512;
	public const uint32 TF_SFT_NOEXTRAICONSONMINIMIZED = 1024;
	public const uint32 TF_SFT_DESKBAND = 2048;
	public const uint32 TF_LBI_DESC_MAXLEN = 32;
	public const uint32 TF_LBMENUF_CHECKED = 1;
	public const uint32 TF_LBMENUF_SUBMENU = 2;
	public const uint32 TF_LBMENUF_SEPARATOR = 4;
	public const uint32 TF_LBMENUF_RADIOCHECKED = 8;
	public const uint32 TF_LBMENUF_GRAYED = 16;
	public const Guid GUID_PROP_INPUTSCOPE = .(0x1713dd5a, 0x68e7, 0x4a5b, 0x9a, 0xf6, 0x59, 0x2a, 0x59, 0x5c, 0x77, 0x8d);
	public const uint32 DCM_FLAGS_TASKENG = 1;
	public const uint32 DCM_FLAGS_CTFMON = 2;
	public const uint32 DCM_FLAGS_LOCALTHREADTSF = 4;
	public const uint32 ILMCM_CHECKLAYOUTANDTIPENABLED = 1;
	public const uint32 ILMCM_LANGUAGEBAROFF = 2;
	public const Guid LIBID_MSAATEXTLib = .(0x150e2d7a, 0xdac1, 0x4582, 0x94, 0x7d, 0x2a, 0x8f, 0xd7, 0x8b, 0x82, 0xcd);
	public const uint32 TS_STRF_START = 0;
	public const uint32 TS_STRF_MID = 1;
	public const uint32 TS_STRF_END = 2;
	public const Guid TSATTRID_OTHERS = .(0xb3c32af9, 0x57d0, 0x46a9, 0xbc, 0xa8, 0xda, 0xc2, 0x38, 0xa1, 0x30, 0x57);
	public const Guid TSATTRID_Font = .(0x573ea825, 0x749b, 0x4f8a, 0x9c, 0xfd, 0x21, 0xc3, 0x60, 0x5c, 0xa8, 0x28);
	public const Guid TSATTRID_Font_FaceName = .(0xb536aeb6, 0x053b, 0x4eb8, 0xb6, 0x5a, 0x50, 0xda, 0x1e, 0x81, 0xe7, 0x2e);
	public const Guid TSATTRID_Font_SizePts = .(0xc8493302, 0xa5e9, 0x456d, 0xaf, 0x04, 0x80, 0x05, 0xe4, 0x13, 0x0f, 0x03);
	public const Guid TSATTRID_Font_Style = .(0x68b2a77f, 0x6b0e, 0x4f28, 0x81, 0x77, 0x57, 0x1c, 0x2f, 0x3a, 0x42, 0xb1);
	public const Guid TSATTRID_Font_Style_Bold = .(0x48813a43, 0x8a20, 0x4940, 0x8e, 0x58, 0x97, 0x82, 0x3f, 0x7b, 0x26, 0x8a);
	public const Guid TSATTRID_Font_Style_Italic = .(0x8740682a, 0xa765, 0x48e1, 0xac, 0xfc, 0xd2, 0x22, 0x22, 0xb2, 0xf8, 0x10);
	public const Guid TSATTRID_Font_Style_SmallCaps = .(0xfacb6bc6, 0x9100, 0x4cc6, 0xb9, 0x69, 0x11, 0xee, 0xa4, 0x5a, 0x86, 0xb4);
	public const Guid TSATTRID_Font_Style_Capitalize = .(0x7d85a3ba, 0xb4fd, 0x43b3, 0xbe, 0xfc, 0x6b, 0x98, 0x5c, 0x84, 0x31, 0x41);
	public const Guid TSATTRID_Font_Style_Uppercase = .(0x33a300e8, 0xe340, 0x4937, 0xb6, 0x97, 0x8f, 0x23, 0x40, 0x45, 0xcd, 0x9a);
	public const Guid TSATTRID_Font_Style_Lowercase = .(0x76d8ccb5, 0xca7b, 0x4498, 0x8e, 0xe9, 0xd5, 0xc4, 0xf6, 0xf7, 0x4c, 0x60);
	public const Guid TSATTRID_Font_Style_Animation = .(0xdcf73d22, 0xe029, 0x47b7, 0xbb, 0x36, 0xf2, 0x63, 0xa3, 0xd0, 0x04, 0xcc);
	public const Guid TSATTRID_Font_Style_Animation_LasVegasLights = .(0xf40423d5, 0x0f87, 0x4f8f, 0xba, 0xda, 0xe6, 0xd6, 0x0c, 0x25, 0xe1, 0x52);
	public const Guid TSATTRID_Font_Style_Animation_BlinkingBackground = .(0x86e5b104, 0x0104, 0x4b10, 0xb5, 0x85, 0x00, 0xf2, 0x52, 0x75, 0x22, 0xb5);
	public const Guid TSATTRID_Font_Style_Animation_SparkleText = .(0x533aad20, 0x962c, 0x4e9f, 0x8c, 0x09, 0xb4, 0x2e, 0xa4, 0x74, 0x97, 0x11);
	public const Guid TSATTRID_Font_Style_Animation_MarchingBlackAnts = .(0x7644e067, 0xf186, 0x4902, 0xbf, 0xc6, 0xec, 0x81, 0x5a, 0xa2, 0x0e, 0x9d);
	public const Guid TSATTRID_Font_Style_Animation_MarchingRedAnts = .(0x78368dad, 0x50fb, 0x4c6f, 0x84, 0x0b, 0xd4, 0x86, 0xbb, 0x6c, 0xf7, 0x81);
	public const Guid TSATTRID_Font_Style_Animation_Shimmer = .(0x2ce31b58, 0x5293, 0x4c36, 0x88, 0x09, 0xbf, 0x8b, 0xb5, 0x1a, 0x27, 0xb3);
	public const Guid TSATTRID_Font_Style_Animation_WipeDown = .(0x5872e874, 0x367b, 0x4803, 0xb1, 0x60, 0xc9, 0x0f, 0xf6, 0x25, 0x69, 0xd0);
	public const Guid TSATTRID_Font_Style_Animation_WipeRight = .(0xb855cbe3, 0x3d2c, 0x4600, 0xb1, 0xe9, 0xe1, 0xc9, 0xce, 0x02, 0xf8, 0x42);
	public const Guid TSATTRID_Font_Style_Emboss = .(0xbd8ed742, 0x349e, 0x4e37, 0x82, 0xfb, 0x43, 0x79, 0x79, 0xcb, 0x53, 0xa7);
	public const Guid TSATTRID_Font_Style_Engrave = .(0x9c3371de, 0x8332, 0x4897, 0xbe, 0x5d, 0x89, 0x23, 0x32, 0x23, 0x17, 0x9a);
	public const Guid TSATTRID_Font_Style_Hidden = .(0xb1e28770, 0x881c, 0x475f, 0x86, 0x3f, 0x88, 0x7a, 0x64, 0x7b, 0x10, 0x90);
	public const Guid TSATTRID_Font_Style_Kerning = .(0xcc26e1b4, 0x2f9a, 0x47c8, 0x8b, 0xff, 0xbf, 0x1e, 0xb7, 0xcc, 0xe0, 0xdd);
	public const Guid TSATTRID_Font_Style_Outlined = .(0x10e6db31, 0xdb0d, 0x4ac6, 0xa7, 0xf5, 0x9c, 0x9c, 0xff, 0x6f, 0x2a, 0xb4);
	public const Guid TSATTRID_Font_Style_Position = .(0x15cd26ab, 0xf2fb, 0x4062, 0xb5, 0xa6, 0x9a, 0x49, 0xe1, 0xa5, 0xcc, 0x0b);
	public const Guid TSATTRID_Font_Style_Protected = .(0x1c557cb2, 0x14cf, 0x4554, 0xa5, 0x74, 0xec, 0xb2, 0xf7, 0xe7, 0xef, 0xd4);
	public const Guid TSATTRID_Font_Style_Shadow = .(0x5f686d2f, 0xc6cd, 0x4c56, 0x8a, 0x1a, 0x99, 0x4a, 0x4b, 0x97, 0x66, 0xbe);
	public const Guid TSATTRID_Font_Style_Spacing = .(0x98c1200d, 0x8f06, 0x409a, 0x8e, 0x49, 0x6a, 0x55, 0x4b, 0xf7, 0xc1, 0x53);
	public const Guid TSATTRID_Font_Style_Weight = .(0x12f3189c, 0x8bb0, 0x461b, 0xb1, 0xfa, 0xea, 0xf9, 0x07, 0x04, 0x7f, 0xe0);
	public const Guid TSATTRID_Font_Style_Height = .(0x7e937477, 0x12e6, 0x458b, 0x92, 0x6a, 0x1f, 0xa4, 0x4e, 0xe8, 0xf3, 0x91);
	public const Guid TSATTRID_Font_Style_Underline = .(0xc3c9c9f3, 0x7902, 0x444b, 0x9a, 0x7b, 0x48, 0xe7, 0x0f, 0x4b, 0x50, 0xf7);
	public const Guid TSATTRID_Font_Style_Underline_Single = .(0x1b6720e5, 0x0f73, 0x4951, 0xa6, 0xb3, 0x6f, 0x19, 0xe4, 0x3c, 0x94, 0x61);
	public const Guid TSATTRID_Font_Style_Underline_Double = .(0x74d24aa6, 0x1db3, 0x4c69, 0xa1, 0x76, 0x31, 0x12, 0x0e, 0x75, 0x86, 0xd5);
	public const Guid TSATTRID_Font_Style_Strikethrough = .(0x0c562193, 0x2d08, 0x4668, 0x96, 0x01, 0xce, 0xd4, 0x13, 0x09, 0xd7, 0xaf);
	public const Guid TSATTRID_Font_Style_Strikethrough_Single = .(0x75d736b6, 0x3c8f, 0x4b97, 0xab, 0x78, 0x18, 0x77, 0xcb, 0x99, 0x0d, 0x31);
	public const Guid TSATTRID_Font_Style_Strikethrough_Double = .(0x62489b31, 0xa3e7, 0x4f94, 0xac, 0x43, 0xeb, 0xaf, 0x8f, 0xcc, 0x7a, 0x9f);
	public const Guid TSATTRID_Font_Style_Overline = .(0xe3989f4a, 0x992b, 0x4301, 0x8c, 0xe1, 0xa5, 0xb7, 0xc6, 0xd1, 0xf3, 0xc8);
	public const Guid TSATTRID_Font_Style_Overline_Single = .(0x8440d94c, 0x51ce, 0x47b2, 0x8d, 0x4c, 0x15, 0x75, 0x1e, 0x5f, 0x72, 0x1b);
	public const Guid TSATTRID_Font_Style_Overline_Double = .(0xdc46063a, 0xe115, 0x46e3, 0xbc, 0xd8, 0xca, 0x67, 0x72, 0xaa, 0x95, 0xb4);
	public const Guid TSATTRID_Font_Style_Blink = .(0xbfb2c036, 0x7acf, 0x4532, 0xb7, 0x20, 0xb4, 0x16, 0xdd, 0x77, 0x65, 0xa8);
	public const Guid TSATTRID_Font_Style_Subscript = .(0x5774fb84, 0x389b, 0x43bc, 0xa7, 0x4b, 0x15, 0x68, 0x34, 0x7c, 0xf0, 0xf4);
	public const Guid TSATTRID_Font_Style_Superscript = .(0x2ea4993c, 0x563c, 0x49aa, 0x93, 0x72, 0x0b, 0xef, 0x09, 0xa9, 0x25, 0x5b);
	public const Guid TSATTRID_Font_Style_Color = .(0x857a7a37, 0xb8af, 0x4e9a, 0x81, 0xb4, 0xac, 0xf7, 0x00, 0xc8, 0x41, 0x1b);
	public const Guid TSATTRID_Font_Style_BackgroundColor = .(0xb50eaa4e, 0x3091, 0x4468, 0x81, 0xdb, 0xd7, 0x9e, 0xa1, 0x90, 0xc7, 0xc7);
	public const Guid TSATTRID_Text = .(0x7edb8e68, 0x81f9, 0x449d, 0xa1, 0x5a, 0x87, 0xa8, 0x38, 0x8f, 0xaa, 0xc0);
	public const Guid TSATTRID_Text_VerticalWriting = .(0x6bba8195, 0x046f, 0x4ea9, 0xb3, 0x11, 0x97, 0xfd, 0x66, 0xc4, 0x27, 0x4b);
	public const Guid TSATTRID_Text_RightToLeft = .(0xca666e71, 0x1b08, 0x453d, 0xbf, 0xdd, 0x28, 0xe0, 0x8c, 0x8a, 0xaf, 0x7a);
	public const Guid TSATTRID_Text_Orientation = .(0x6bab707f, 0x8785, 0x4c39, 0x8b, 0x52, 0x96, 0xf8, 0x78, 0x30, 0x3f, 0xfb);
	public const Guid TSATTRID_Text_Language = .(0xd8c04ef1, 0x5753, 0x4c25, 0x88, 0x87, 0x85, 0x44, 0x3f, 0xe5, 0xf8, 0x19);
	public const Guid TSATTRID_Text_ReadOnly = .(0x85836617, 0xde32, 0x4afd, 0xa5, 0x0f, 0xa2, 0xdb, 0x11, 0x0e, 0x6e, 0x4d);
	public const Guid TSATTRID_Text_EmbeddedObject = .(0x7edb8e68, 0x81f9, 0x449d, 0xa1, 0x5a, 0x87, 0xa8, 0x38, 0x8f, 0xaa, 0xc0);
	public const Guid TSATTRID_Text_Alignment = .(0x139941e6, 0x1767, 0x456d, 0x93, 0x8e, 0x35, 0xba, 0x56, 0x8b, 0x5c, 0xd4);
	public const Guid TSATTRID_Text_Alignment_Left = .(0x16ae95d3, 0x6361, 0x43a2, 0x84, 0x95, 0xd0, 0x0f, 0x39, 0x7f, 0x16, 0x93);
	public const Guid TSATTRID_Text_Alignment_Right = .(0xb36f0f98, 0x1b9e, 0x4360, 0x86, 0x16, 0x03, 0xfb, 0x08, 0xa7, 0x84, 0x56);
	public const Guid TSATTRID_Text_Alignment_Center = .(0xa4a95c16, 0x53bf, 0x4d55, 0x8b, 0x87, 0x4b, 0xdd, 0x8d, 0x42, 0x75, 0xfc);
	public const Guid TSATTRID_Text_Alignment_Justify = .(0xed350740, 0xa0f7, 0x42d3, 0x8e, 0xa8, 0xf8, 0x1b, 0x64, 0x88, 0xfa, 0xf0);
	public const Guid TSATTRID_Text_Link = .(0x47cd9051, 0x3722, 0x4cd8, 0xb7, 0xc8, 0x4e, 0x17, 0xca, 0x17, 0x59, 0xf5);
	public const Guid TSATTRID_Text_Hyphenation = .(0xdadf4525, 0x618e, 0x49eb, 0xb1, 0xa8, 0x3b, 0x68, 0xbd, 0x76, 0x48, 0xe3);
	public const Guid TSATTRID_Text_Para = .(0x5edc5822, 0x99dc, 0x4dd6, 0xae, 0xc3, 0xb6, 0x2b, 0xaa, 0x5b, 0x2e, 0x7c);
	public const Guid TSATTRID_Text_Para_FirstLineIndent = .(0x07c97a13, 0x7472, 0x4dd8, 0x90, 0xa9, 0x91, 0xe3, 0xd7, 0xe4, 0xf2, 0x9c);
	public const Guid TSATTRID_Text_Para_LeftIndent = .(0xfb2848e9, 0x7471, 0x41c9, 0xb6, 0xb3, 0x8a, 0x14, 0x50, 0xe0, 0x18, 0x97);
	public const Guid TSATTRID_Text_Para_RightIndent = .(0x2c7f26f9, 0xa5e2, 0x48da, 0xb9, 0x8a, 0x52, 0x0c, 0xb1, 0x65, 0x13, 0xbf);
	public const Guid TSATTRID_Text_Para_SpaceAfter = .(0x7b0a3f55, 0x22dc, 0x425f, 0xa4, 0x11, 0x93, 0xda, 0x1d, 0x8f, 0x9b, 0xaa);
	public const Guid TSATTRID_Text_Para_SpaceBefore = .(0x8df98589, 0x194a, 0x4601, 0xb2, 0x51, 0x98, 0x65, 0xa3, 0xe9, 0x06, 0xdd);
	public const Guid TSATTRID_Text_Para_LineSpacing = .(0x699b380d, 0x7f8c, 0x46d6, 0xa7, 0x3b, 0xdf, 0xe3, 0xd1, 0x53, 0x8d, 0xf3);
	public const Guid TSATTRID_Text_Para_LineSpacing_Single = .(0xed350740, 0xa0f7, 0x42d3, 0x8e, 0xa8, 0xf8, 0x1b, 0x64, 0x88, 0xfa, 0xf0);
	public const Guid TSATTRID_Text_Para_LineSpacing_OnePtFive = .(0x0428a021, 0x0397, 0x4b57, 0x9a, 0x17, 0x07, 0x95, 0x99, 0x4c, 0xd3, 0xc5);
	public const Guid TSATTRID_Text_Para_LineSpacing_Double = .(0x82fb1805, 0xa6c4, 0x4231, 0xac, 0x12, 0x62, 0x60, 0xaf, 0x2a, 0xba, 0x28);
	public const Guid TSATTRID_Text_Para_LineSpacing_AtLeast = .(0xadfedf31, 0x2d44, 0x4434, 0xa5, 0xff, 0x7f, 0x4c, 0x49, 0x90, 0xa9, 0x05);
	public const Guid TSATTRID_Text_Para_LineSpacing_Exactly = .(0x3d45ad40, 0x23de, 0x48d7, 0xa6, 0xb3, 0x76, 0x54, 0x20, 0xc6, 0x20, 0xcc);
	public const Guid TSATTRID_Text_Para_LineSpacing_Multiple = .(0x910f1e3c, 0xd6d0, 0x4f65, 0x8a, 0x3c, 0x42, 0xb4, 0xb3, 0x18, 0x68, 0xc5);
	public const Guid TSATTRID_List = .(0x436d673b, 0x26f1, 0x4aee, 0x9e, 0x65, 0x8f, 0x83, 0xa4, 0xed, 0x48, 0x84);
	public const Guid TSATTRID_List_LevelIndel = .(0x7f7cc899, 0x311f, 0x487b, 0xad, 0x5d, 0xe2, 0xa4, 0x59, 0xe1, 0x2d, 0x42);
	public const Guid TSATTRID_List_Type = .(0xae3e665e, 0x4bce, 0x49e3, 0xa0, 0xfe, 0x2d, 0xb4, 0x7d, 0x3a, 0x17, 0xae);
	public const Guid TSATTRID_List_Type_Bullet = .(0xbccd77c5, 0x4c4d, 0x4ce2, 0xb1, 0x02, 0x55, 0x9f, 0x3b, 0x2b, 0xfc, 0xea);
	public const Guid TSATTRID_List_Type_Arabic = .(0x1338c5d6, 0x98a3, 0x4fa3, 0x9b, 0xd1, 0x7a, 0x60, 0xee, 0xf8, 0xe9, 0xe0);
	public const Guid TSATTRID_List_Type_LowerLetter = .(0x96372285, 0xf3cf, 0x491e, 0xa9, 0x25, 0x38, 0x32, 0x34, 0x7f, 0xd2, 0x37);
	public const Guid TSATTRID_List_Type_UpperLetter = .(0x7987b7cd, 0xce52, 0x428b, 0x9b, 0x95, 0xa3, 0x57, 0xf6, 0xf1, 0x0c, 0x45);
	public const Guid TSATTRID_List_Type_LowerRoman = .(0x90466262, 0x3980, 0x4b8e, 0x93, 0x68, 0x91, 0x8b, 0xd1, 0x21, 0x8a, 0x41);
	public const Guid TSATTRID_List_Type_UpperRoman = .(0x0f6ab552, 0x4a80, 0x467f, 0xb2, 0xf1, 0x12, 0x7e, 0x2a, 0xa3, 0xba, 0x9e);
	public const Guid TSATTRID_App = .(0xa80f77df, 0x4237, 0x40e5, 0x84, 0x9c, 0xb5, 0xfa, 0x51, 0xc1, 0x3a, 0xc7);
	public const Guid TSATTRID_App_IncorrectSpelling = .(0xf42de43c, 0xef12, 0x430d, 0x94, 0x4c, 0x9a, 0x08, 0x97, 0x0a, 0x25, 0xd2);
	public const Guid TSATTRID_App_IncorrectGrammar = .(0xbd54e398, 0xad03, 0x4b74, 0xb6, 0xb3, 0x5e, 0xdb, 0x19, 0x99, 0x63, 0x88);
}
#endregion

#region TypeDefs
typealias HKL = int;

#endregion


#region Enums

[AllowDuplicates]
public enum LANG_BAR_ITEM_ICON_MODE_FLAGS : uint32
{
	TF_DTLBI_NONE = 0,
	TF_DTLBI_USEPROFILEICON = 1,
}


[AllowDuplicates]
public enum TEXT_STORE_TEXT_CHANGE_FLAGS : uint32
{
	TS_ST_NONE = 0,
	TS_ST_CORRECTION = 1,
}


[AllowDuplicates]
public enum TEXT_STORE_CHANGE_FLAGS : uint32
{
	TS_TC_NONE = 0,
	TS_TC_CORRECTION = 1,
}


[AllowDuplicates]
public enum INSERT_TEXT_AT_SELECTION_FLAGS : uint32
{
	TF_IAS_NOQUERY = 1,
	TF_IAS_QUERYONLY = 2,
	TF_IAS_NO_DEFAULT_COMPOSITION = 2147483648,
}


[AllowDuplicates]
public enum ANCHOR_CHANGE_HISTORY_FLAGS : uint32
{
	TS_CH_PRECEDING_DEL = 1,
	TS_CH_FOLLOWING_DEL = 2,
}


[AllowDuplicates]
public enum TEXT_STORE_LOCK_FLAGS : uint32
{
	TS_LF_READ = 2,
	TS_LF_READWRITE = 6,
}


[AllowDuplicates]
public enum GET_TEXT_AND_PROPERTY_UPDATES_FLAGS : uint32
{
	TF_GTP_NONE = 0,
	TF_GTP_INCL_TEXT = 1,
}


[AllowDuplicates]
public enum TF_CONTEXT_EDIT_CONTEXT_FLAGS : uint32
{
	TF_ES_ASYNCDONTCARE = 0,
	TF_ES_SYNC = 1,
	TF_ES_READ = 2,
	TF_ES_READWRITE = 6,
	TF_ES_ASYNC = 8,
}


[AllowDuplicates]
public enum TsActiveSelEnd : int32
{
	TS_AE_NONE = 0,
	TS_AE_START = 1,
	TS_AE_END = 2,
}


[AllowDuplicates]
public enum TsLayoutCode : int32
{
	TS_LC_CREATE = 0,
	TS_LC_CHANGE = 1,
	TS_LC_DESTROY = 2,
}


[AllowDuplicates]
public enum TsRunType : int32
{
	TS_RT_PLAIN = 0,
	TS_RT_HIDDEN = 1,
	TS_RT_OPAQUE = 2,
}


[AllowDuplicates]
public enum TsGravity : int32
{
	TS_GR_BACKWARD = 0,
	TS_GR_FORWARD = 1,
}


[AllowDuplicates]
public enum TsShiftDir : int32
{
	TS_SD_BACKWARD = 0,
	TS_SD_FORWARD = 1,
}


[AllowDuplicates]
public enum TfLBIClick : int32
{
	TF_LBI_CLK_RIGHT = 1,
	TF_LBI_CLK_LEFT = 2,
}


[AllowDuplicates]
public enum TfLBBalloonStyle : int32
{
	TF_LB_BALLOON_RECO = 0,
	TF_LB_BALLOON_SHOW = 1,
	TF_LB_BALLOON_MISS = 2,
}


[AllowDuplicates]
public enum TfAnchor : int32
{
	TF_ANCHOR_START = 0,
	TF_ANCHOR_END = 1,
}


[AllowDuplicates]
public enum TfActiveSelEnd : int32
{
	TF_AE_NONE = 0,
	TF_AE_START = 1,
	TF_AE_END = 2,
}


[AllowDuplicates]
public enum TfLayoutCode : int32
{
	TF_LC_CREATE = 0,
	TF_LC_CHANGE = 1,
	TF_LC_DESTROY = 2,
}


[AllowDuplicates]
public enum TfGravity : int32
{
	TF_GRAVITY_BACKWARD = 0,
	TF_GRAVITY_FORWARD = 1,
}


[AllowDuplicates]
public enum TfShiftDir : int32
{
	TF_SD_BACKWARD = 0,
	TF_SD_FORWARD = 1,
}


[AllowDuplicates]
public enum TF_DA_LINESTYLE : int32
{
	TF_LS_NONE = 0,
	TF_LS_SOLID = 1,
	TF_LS_DOT = 2,
	TF_LS_DASH = 3,
	TF_LS_SQUIGGLE = 4,
}


[AllowDuplicates]
public enum TF_DA_COLORTYPE : int32
{
	TF_CT_NONE = 0,
	TF_CT_SYSCOLOR = 1,
	TF_CT_COLORREF = 2,
}


[AllowDuplicates]
public enum TF_DA_ATTR_INFO : int32
{
	TF_ATTR_INPUT = 0,
	TF_ATTR_TARGET_CONVERTED = 1,
	TF_ATTR_CONVERTED = 2,
	TF_ATTR_TARGET_NOTCONVERTED = 3,
	TF_ATTR_INPUT_ERROR = 4,
	TF_ATTR_FIXEDCONVERTED = 5,
	TF_ATTR_OTHER = -1,
}


[AllowDuplicates]
public enum TfCandidateResult : int32
{
	CAND_FINALIZED = 0,
	CAND_SELECTED = 1,
	CAND_CANCELED = 2,
}


[AllowDuplicates]
public enum TfSapiObject : int32
{
	GETIF_RESMGR = 0,
	GETIF_RECOCONTEXT = 1,
	GETIF_RECOGNIZER = 2,
	GETIF_VOICE = 3,
	GETIF_DICTGRAM = 4,
	GETIF_RECOGNIZERNOINIT = 5,
}


[AllowDuplicates]
public enum TfIntegratableCandidateListSelectionStyle : int32
{
	STYLE_ACTIVE_SELECTION = 0,
	STYLE_IMPLIED_SELECTION = 1,
}


[AllowDuplicates]
public enum TKBLayoutType : int32
{
	TKBLT_UNDEFINED = 0,
	TKBLT_CLASSIC = 1,
	TKBLT_OPTIMIZED = 2,
}


[AllowDuplicates]
public enum InputScope : int32
{
	IS_DEFAULT = 0,
	IS_URL = 1,
	IS_FILE_FULLFILEPATH = 2,
	IS_FILE_FILENAME = 3,
	IS_EMAIL_USERNAME = 4,
	IS_EMAIL_SMTPEMAILADDRESS = 5,
	IS_LOGINNAME = 6,
	IS_PERSONALNAME_FULLNAME = 7,
	IS_PERSONALNAME_PREFIX = 8,
	IS_PERSONALNAME_GIVENNAME = 9,
	IS_PERSONALNAME_MIDDLENAME = 10,
	IS_PERSONALNAME_SURNAME = 11,
	IS_PERSONALNAME_SUFFIX = 12,
	IS_ADDRESS_FULLPOSTALADDRESS = 13,
	IS_ADDRESS_POSTALCODE = 14,
	IS_ADDRESS_STREET = 15,
	IS_ADDRESS_STATEORPROVINCE = 16,
	IS_ADDRESS_CITY = 17,
	IS_ADDRESS_COUNTRYNAME = 18,
	IS_ADDRESS_COUNTRYSHORTNAME = 19,
	IS_CURRENCY_AMOUNTANDSYMBOL = 20,
	IS_CURRENCY_AMOUNT = 21,
	IS_DATE_FULLDATE = 22,
	IS_DATE_MONTH = 23,
	IS_DATE_DAY = 24,
	IS_DATE_YEAR = 25,
	IS_DATE_MONTHNAME = 26,
	IS_DATE_DAYNAME = 27,
	IS_DIGITS = 28,
	IS_NUMBER = 29,
	IS_ONECHAR = 30,
	IS_PASSWORD = 31,
	IS_TELEPHONE_FULLTELEPHONENUMBER = 32,
	IS_TELEPHONE_COUNTRYCODE = 33,
	IS_TELEPHONE_AREACODE = 34,
	IS_TELEPHONE_LOCALNUMBER = 35,
	IS_TIME_FULLTIME = 36,
	IS_TIME_HOUR = 37,
	IS_TIME_MINORSEC = 38,
	IS_NUMBER_FULLWIDTH = 39,
	IS_ALPHANUMERIC_HALFWIDTH = 40,
	IS_ALPHANUMERIC_FULLWIDTH = 41,
	IS_CURRENCY_CHINESE = 42,
	IS_BOPOMOFO = 43,
	IS_HIRAGANA = 44,
	IS_KATAKANA_HALFWIDTH = 45,
	IS_KATAKANA_FULLWIDTH = 46,
	IS_HANJA = 47,
	IS_HANGUL_HALFWIDTH = 48,
	IS_HANGUL_FULLWIDTH = 49,
	IS_SEARCH = 50,
	IS_FORMULA = 51,
	IS_SEARCH_INCREMENTAL = 52,
	IS_CHINESE_HALFWIDTH = 53,
	IS_CHINESE_FULLWIDTH = 54,
	IS_NATIVE_SCRIPT = 55,
	IS_YOMI = 56,
	IS_TEXT = 57,
	IS_CHAT = 58,
	IS_NAME_OR_PHONENUMBER = 59,
	IS_EMAILNAME_OR_ADDRESS = 60,
	IS_PRIVATE = 61,
	IS_MAPS = 62,
	IS_NUMERIC_PASSWORD = 63,
	IS_NUMERIC_PIN = 64,
	IS_ALPHANUMERIC_PIN = 65,
	IS_ALPHANUMERIC_PIN_SET = 66,
	IS_FORMULA_NUMBER = 67,
	IS_CHAT_WITHOUT_EMOJI = 68,
	IS_PHRASELIST = -1,
	IS_REGULAREXPRESSION = -2,
	IS_SRGS = -3,
	IS_XML = -4,
	IS_ENUMSTRING = -5,
}

#endregion


#region Structs
[CRepr]
public struct TS_STATUS
{
	public uint32 dwDynamicFlags;
	public uint32 dwStaticFlags;
}

[CRepr]
public struct TS_TEXTCHANGE
{
	public int32 acpStart;
	public int32 acpOldEnd;
	public int32 acpNewEnd;
}

[CRepr]
public struct TS_SELECTIONSTYLE
{
	public TsActiveSelEnd ase;
	public BOOL fInterimChar;
}

[CRepr]
public struct TS_SELECTION_ACP
{
	public int32 acpStart;
	public int32 acpEnd;
	public TS_SELECTIONSTYLE style;
}

[CRepr]
public struct TS_SELECTION_ANCHOR
{
	public IAnchor* paStart;
	public IAnchor* paEnd;
	public TS_SELECTIONSTYLE style;
}

[CRepr]
public struct TS_ATTRVAL
{
	public Guid idAttr;
	public uint32 dwOverlapId;
	public VARIANT varValue;
}

[CRepr]
public struct TS_RUNINFO
{
	public uint32 uCount;
	public TsRunType type;
}

[CRepr]
public struct TF_LANGBARITEMINFO
{
	public Guid clsidService;
	public Guid guidItem;
	public uint32 dwStyle;
	public uint32 ulSort;
	public char16[32] szDescription;
}

[CRepr]
public struct TF_LBBALLOONINFO
{
	public TfLBBalloonStyle style;
	public BSTR bstrText;
}

[CRepr]
public struct TF_PERSISTENT_PROPERTY_HEADER_ACP
{
	public Guid guidType;
	public int32 ichStart;
	public int32 cch;
	public uint32 cb;
	public uint32 dwPrivate;
	public Guid clsidTIP;
}

[CRepr]
public struct TF_LANGUAGEPROFILE
{
	public Guid clsid;
	public uint16 langid;
	public Guid catid;
	public BOOL fActive;
	public Guid guidProfile;
}

[CRepr]
public struct TF_SELECTIONSTYLE
{
	public TfActiveSelEnd ase;
	public BOOL fInterimChar;
}

[CRepr]
public struct TF_SELECTION
{
	public ITfRange* range;
	public TF_SELECTIONSTYLE style;
}

[CRepr]
public struct TF_PROPERTYVAL
{
	public Guid guidId;
	public VARIANT varValue;
}

[CRepr]
public struct TF_HALTCOND
{
	public ITfRange* pHaltRange;
	public TfAnchor aHaltPos;
	public uint32 dwFlags;
}

[CRepr]
public struct TF_INPUTPROCESSORPROFILE
{
	public uint32 dwProfileType;
	public uint16 langid;
	public Guid clsid;
	public Guid guidProfile;
	public Guid catid;
	public HKL hklSubstitute;
	public uint32 dwCaps;
	public HKL hkl;
	public uint32 dwFlags;
}

[CRepr]
public struct TF_PRESERVEDKEY
{
	public uint32 uVKey;
	public uint32 uModifiers;
}

[CRepr]
public struct TF_DA_COLOR
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int32 nIndex;
		public COLORREF cr;
	}
	public TF_DA_COLORTYPE type;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct TF_DISPLAYATTRIBUTE
{
	public TF_DA_COLOR crText;
	public TF_DA_COLOR crBk;
	public TF_DA_LINESTYLE lsStyle;
	public BOOL fBoldLine;
	public TF_DA_COLOR crLine;
	public TF_DA_ATTR_INFO bAttr;
}

[CRepr]
public struct TF_LMLATTELEMENT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int32 iCost;
	}
	public uint32 dwFrameStart;
	public uint32 dwFrameLen;
	public uint32 dwFlags;
	public using _Anonymous_e__Union Anonymous;
	public BSTR bstrText;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_MSAAControl = .(0x08cd963f, 0x7a3e, 0x4f5c, 0x9b, 0xd8, 0xd6, 0x92, 0xbb, 0x04, 0x3c, 0x5b);


	public const Guid CLSID_AccStore = .(0x5440837f, 0x4bff, 0x4ae5, 0xa1, 0xb1, 0x77, 0x22, 0xec, 0xc6, 0x33, 0x2a);


	public const Guid CLSID_AccDictionary = .(0x6572ee16, 0x5fe5, 0x4331, 0xbb, 0x6d, 0x76, 0xa4, 0x9c, 0x56, 0xe4, 0x23);


	public const Guid CLSID_AccServerDocMgr = .(0x6089a37e, 0xeb8a, 0x482d, 0xbd, 0x6f, 0xf9, 0xf4, 0x69, 0x04, 0xd1, 0x6d);


	public const Guid CLSID_AccClientDocMgr = .(0xfc48cc30, 0x4f3e, 0x4fa1, 0x80, 0x3b, 0xad, 0x0e, 0x19, 0x6a, 0x83, 0xb1);


	public const Guid CLSID_DocWrap = .(0xbf426f7e, 0x7a5e, 0x44d6, 0x83, 0x0c, 0xa3, 0x90, 0xea, 0x94, 0x62, 0xa3);


}
#endregion

#region COM Types
[CRepr]struct ITextStoreACP : IUnknown
{
	public new const Guid IID = .(0x28888fe3, 0xc2a0, 0x483a, 0xa3, 0xea, 0x8c, 0xb1, 0xce, 0x51, 0xff, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk, uint32 dwMask) AdviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) UnadviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLockFlags, HRESULT* phrSession) RequestLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TS_STATUS* pdcs) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpTestStart, int32 acpTestEnd, uint32 cch, int32* pacpResultStart, int32* pacpResultEnd) QueryInsert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, uint32 ulCount, TS_SELECTION_ACP* pSelection, uint32* pcFetched) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_SELECTION_ACP* pSelection) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, char16* pchPlain, uint32 cchPlainReq, uint32* pcchPlainRet, TS_RUNINFO* prgRunInfo, uint32 cRunInfoReq, uint32* pcRunInfoRet, int32* pacpNext) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, int32 acpStart, int32 acpEnd, char16* pchText, uint32 cch, TS_TEXTCHANGE* pChange) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, IDataObject** ppDataObject) GetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) GetEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) QueryInsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, int32 acpStart, int32 acpEnd, IDataObject* pDataObject, TS_TEXTCHANGE* pChange) InsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, char16* pchText, uint32 cch, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) InsertTextAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IDataObject* pDataObject, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) InsertEmbeddedAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) RequestSupportedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsTransitioningAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, int32* pacpNext, BOOL* pfFound, int32* plFoundOffset) FindNextAttrTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) RetrieveRequestedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pacp) GetEndACP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pvcView) GetActiveView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, POINT* ptScreen, uint32 dwFlags, int32* pacp) GetACPFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) GetTextExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, RECT* prc) GetScreenExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, HWND* phwnd) GetWnd;
	}


	public HRESULT AdviseSink(in Guid riid, IUnknown* punk, uint32 dwMask) mut => VT.[Friend]AdviseSink(&this, riid, punk, dwMask);

	public HRESULT UnadviseSink(IUnknown* punk) mut => VT.[Friend]UnadviseSink(&this, punk);

	public HRESULT RequestLock(uint32 dwLockFlags, HRESULT* phrSession) mut => VT.[Friend]RequestLock(&this, dwLockFlags, phrSession);

	public HRESULT GetStatus(TS_STATUS* pdcs) mut => VT.[Friend]GetStatus(&this, pdcs);

	public HRESULT QueryInsert(int32 acpTestStart, int32 acpTestEnd, uint32 cch, int32* pacpResultStart, int32* pacpResultEnd) mut => VT.[Friend]QueryInsert(&this, acpTestStart, acpTestEnd, cch, pacpResultStart, pacpResultEnd);

	public HRESULT GetSelection(uint32 ulIndex, uint32 ulCount, TS_SELECTION_ACP* pSelection, uint32* pcFetched) mut => VT.[Friend]GetSelection(&this, ulIndex, ulCount, pSelection, pcFetched);

	public HRESULT SetSelection(uint32 ulCount, TS_SELECTION_ACP* pSelection) mut => VT.[Friend]SetSelection(&this, ulCount, pSelection);

	public HRESULT GetText(int32 acpStart, int32 acpEnd, char16* pchPlain, uint32 cchPlainReq, uint32* pcchPlainRet, TS_RUNINFO* prgRunInfo, uint32 cRunInfoReq, uint32* pcRunInfoRet, int32* pacpNext) mut => VT.[Friend]GetText(&this, acpStart, acpEnd, pchPlain, cchPlainReq, pcchPlainRet, prgRunInfo, cRunInfoReq, pcRunInfoRet, pacpNext);

	public HRESULT SetText(uint32 dwFlags, int32 acpStart, int32 acpEnd, char16* pchText, uint32 cch, TS_TEXTCHANGE* pChange) mut => VT.[Friend]SetText(&this, dwFlags, acpStart, acpEnd, pchText, cch, pChange);

	public HRESULT GetFormattedText(int32 acpStart, int32 acpEnd, IDataObject** ppDataObject) mut => VT.[Friend]GetFormattedText(&this, acpStart, acpEnd, ppDataObject);

	public HRESULT GetEmbedded(int32 acpPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetEmbedded(&this, acpPos, rguidService, riid, ppunk);

	public HRESULT QueryInsertEmbedded(in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) mut => VT.[Friend]QueryInsertEmbedded(&this, pguidService, pFormatEtc, pfInsertable);

	public HRESULT InsertEmbedded(uint32 dwFlags, int32 acpStart, int32 acpEnd, IDataObject* pDataObject, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertEmbedded(&this, dwFlags, acpStart, acpEnd, pDataObject, pChange);

	public HRESULT InsertTextAtSelection(uint32 dwFlags, char16* pchText, uint32 cch, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertTextAtSelection(&this, dwFlags, pchText, cch, pacpStart, pacpEnd, pChange);

	public HRESULT InsertEmbeddedAtSelection(uint32 dwFlags, IDataObject* pDataObject, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertEmbeddedAtSelection(&this, dwFlags, pDataObject, pacpStart, pacpEnd, pChange);

	public HRESULT RequestSupportedAttrs(uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) mut => VT.[Friend]RequestSupportedAttrs(&this, dwFlags, cFilterAttrs, paFilterAttrs);

	public HRESULT RequestAttrsAtPosition(int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsAtPosition(&this, acpPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT RequestAttrsTransitioningAtPosition(int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsTransitioningAtPosition(&this, acpPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT FindNextAttrTransition(int32 acpStart, int32 acpHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, int32* pacpNext, BOOL* pfFound, int32* plFoundOffset) mut => VT.[Friend]FindNextAttrTransition(&this, acpStart, acpHalt, cFilterAttrs, paFilterAttrs, dwFlags, pacpNext, pfFound, plFoundOffset);

	public HRESULT RetrieveRequestedAttrs(uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) mut => VT.[Friend]RetrieveRequestedAttrs(&this, ulCount, paAttrVals, pcFetched);

	public HRESULT GetEndACP(int32* pacp) mut => VT.[Friend]GetEndACP(&this, pacp);

	public HRESULT GetActiveView(uint32* pvcView) mut => VT.[Friend]GetActiveView(&this, pvcView);

	public HRESULT GetACPFromPoint(uint32 vcView, POINT* ptScreen, uint32 dwFlags, int32* pacp) mut => VT.[Friend]GetACPFromPoint(&this, vcView, ptScreen, dwFlags, pacp);

	public HRESULT GetTextExt(uint32 vcView, int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) mut => VT.[Friend]GetTextExt(&this, vcView, acpStart, acpEnd, prc, pfClipped);

	public HRESULT GetScreenExt(uint32 vcView, RECT* prc) mut => VT.[Friend]GetScreenExt(&this, vcView, prc);

	public HRESULT GetWnd(uint32 vcView, HWND* phwnd) mut => VT.[Friend]GetWnd(&this, vcView, phwnd);
}

[CRepr]struct ITextStoreACP2 : IUnknown
{
	public new const Guid IID = .(0xf86ad89f, 0x5fe4, 0x4b8d, 0xbb, 0x9f, 0xef, 0x37, 0x97, 0xa8, 0x4f, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk, uint32 dwMask) AdviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) UnadviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLockFlags, HRESULT* phrSession) RequestLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TS_STATUS* pdcs) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpTestStart, int32 acpTestEnd, uint32 cch, int32* pacpResultStart, int32* pacpResultEnd) QueryInsert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, uint32 ulCount, TS_SELECTION_ACP* pSelection, uint32* pcFetched) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_SELECTION_ACP* pSelection) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, char16* pchPlain, uint32 cchPlainReq, uint32* pcchPlainRet, TS_RUNINFO* prgRunInfo, uint32 cRunInfoReq, uint32* pcRunInfoRet, int32* pacpNext) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, int32 acpStart, int32 acpEnd, char16* pchText, uint32 cch, TS_TEXTCHANGE* pChange) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, IDataObject** ppDataObject) GetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) GetEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) QueryInsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, int32 acpStart, int32 acpEnd, IDataObject* pDataObject, TS_TEXTCHANGE* pChange) InsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, char16* pchText, uint32 cch, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) InsertTextAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IDataObject* pDataObject, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) InsertEmbeddedAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) RequestSupportedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsTransitioningAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, int32* pacpNext, BOOL* pfFound, int32* plFoundOffset) FindNextAttrTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) RetrieveRequestedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pacp) GetEndACP;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pvcView) GetActiveView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, POINT* ptScreen, uint32 dwFlags, int32* pacp) GetACPFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) GetTextExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, RECT* prc) GetScreenExt;
	}


	public HRESULT AdviseSink(in Guid riid, IUnknown* punk, uint32 dwMask) mut => VT.[Friend]AdviseSink(&this, riid, punk, dwMask);

	public HRESULT UnadviseSink(IUnknown* punk) mut => VT.[Friend]UnadviseSink(&this, punk);

	public HRESULT RequestLock(uint32 dwLockFlags, HRESULT* phrSession) mut => VT.[Friend]RequestLock(&this, dwLockFlags, phrSession);

	public HRESULT GetStatus(TS_STATUS* pdcs) mut => VT.[Friend]GetStatus(&this, pdcs);

	public HRESULT QueryInsert(int32 acpTestStart, int32 acpTestEnd, uint32 cch, int32* pacpResultStart, int32* pacpResultEnd) mut => VT.[Friend]QueryInsert(&this, acpTestStart, acpTestEnd, cch, pacpResultStart, pacpResultEnd);

	public HRESULT GetSelection(uint32 ulIndex, uint32 ulCount, TS_SELECTION_ACP* pSelection, uint32* pcFetched) mut => VT.[Friend]GetSelection(&this, ulIndex, ulCount, pSelection, pcFetched);

	public HRESULT SetSelection(uint32 ulCount, TS_SELECTION_ACP* pSelection) mut => VT.[Friend]SetSelection(&this, ulCount, pSelection);

	public HRESULT GetText(int32 acpStart, int32 acpEnd, char16* pchPlain, uint32 cchPlainReq, uint32* pcchPlainRet, TS_RUNINFO* prgRunInfo, uint32 cRunInfoReq, uint32* pcRunInfoRet, int32* pacpNext) mut => VT.[Friend]GetText(&this, acpStart, acpEnd, pchPlain, cchPlainReq, pcchPlainRet, prgRunInfo, cRunInfoReq, pcRunInfoRet, pacpNext);

	public HRESULT SetText(uint32 dwFlags, int32 acpStart, int32 acpEnd, char16* pchText, uint32 cch, TS_TEXTCHANGE* pChange) mut => VT.[Friend]SetText(&this, dwFlags, acpStart, acpEnd, pchText, cch, pChange);

	public HRESULT GetFormattedText(int32 acpStart, int32 acpEnd, IDataObject** ppDataObject) mut => VT.[Friend]GetFormattedText(&this, acpStart, acpEnd, ppDataObject);

	public HRESULT GetEmbedded(int32 acpPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetEmbedded(&this, acpPos, rguidService, riid, ppunk);

	public HRESULT QueryInsertEmbedded(in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) mut => VT.[Friend]QueryInsertEmbedded(&this, pguidService, pFormatEtc, pfInsertable);

	public HRESULT InsertEmbedded(uint32 dwFlags, int32 acpStart, int32 acpEnd, IDataObject* pDataObject, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertEmbedded(&this, dwFlags, acpStart, acpEnd, pDataObject, pChange);

	public HRESULT InsertTextAtSelection(uint32 dwFlags, char16* pchText, uint32 cch, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertTextAtSelection(&this, dwFlags, pchText, cch, pacpStart, pacpEnd, pChange);

	public HRESULT InsertEmbeddedAtSelection(uint32 dwFlags, IDataObject* pDataObject, int32* pacpStart, int32* pacpEnd, TS_TEXTCHANGE* pChange) mut => VT.[Friend]InsertEmbeddedAtSelection(&this, dwFlags, pDataObject, pacpStart, pacpEnd, pChange);

	public HRESULT RequestSupportedAttrs(uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) mut => VT.[Friend]RequestSupportedAttrs(&this, dwFlags, cFilterAttrs, paFilterAttrs);

	public HRESULT RequestAttrsAtPosition(int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsAtPosition(&this, acpPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT RequestAttrsTransitioningAtPosition(int32 acpPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsTransitioningAtPosition(&this, acpPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT FindNextAttrTransition(int32 acpStart, int32 acpHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, int32* pacpNext, BOOL* pfFound, int32* plFoundOffset) mut => VT.[Friend]FindNextAttrTransition(&this, acpStart, acpHalt, cFilterAttrs, paFilterAttrs, dwFlags, pacpNext, pfFound, plFoundOffset);

	public HRESULT RetrieveRequestedAttrs(uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) mut => VT.[Friend]RetrieveRequestedAttrs(&this, ulCount, paAttrVals, pcFetched);

	public HRESULT GetEndACP(int32* pacp) mut => VT.[Friend]GetEndACP(&this, pacp);

	public HRESULT GetActiveView(uint32* pvcView) mut => VT.[Friend]GetActiveView(&this, pvcView);

	public HRESULT GetACPFromPoint(uint32 vcView, POINT* ptScreen, uint32 dwFlags, int32* pacp) mut => VT.[Friend]GetACPFromPoint(&this, vcView, ptScreen, dwFlags, pacp);

	public HRESULT GetTextExt(uint32 vcView, int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) mut => VT.[Friend]GetTextExt(&this, vcView, acpStart, acpEnd, prc, pfClipped);

	public HRESULT GetScreenExt(uint32 vcView, RECT* prc) mut => VT.[Friend]GetScreenExt(&this, vcView, prc);
}

[CRepr]struct ITextStoreACPSink : IUnknown
{
	public new const Guid IID = .(0x22d44c94, 0xa419, 0x4542, 0xa2, 0x72, 0xae, 0x26, 0x09, 0x3e, 0xce, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXT_STORE_TEXT_CHANGE_FLAGS dwFlags, TS_TEXTCHANGE* pChange) OnTextChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnSelectionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TsLayoutCode lcode, uint32 vcView) OnLayoutChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) OnStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, uint32 cAttrs, Guid* paAttrs) OnAttrsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXT_STORE_LOCK_FLAGS dwLockFlags) OnLockGranted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnStartEditTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnEndEditTransaction;
	}


	public HRESULT OnTextChange(TEXT_STORE_TEXT_CHANGE_FLAGS dwFlags, TS_TEXTCHANGE* pChange) mut => VT.[Friend]OnTextChange(&this, dwFlags, pChange);

	public HRESULT OnSelectionChange() mut => VT.[Friend]OnSelectionChange(&this);

	public HRESULT OnLayoutChange(TsLayoutCode lcode, uint32 vcView) mut => VT.[Friend]OnLayoutChange(&this, lcode, vcView);

	public HRESULT OnStatusChange(uint32 dwFlags) mut => VT.[Friend]OnStatusChange(&this, dwFlags);

	public HRESULT OnAttrsChange(int32 acpStart, int32 acpEnd, uint32 cAttrs, Guid* paAttrs) mut => VT.[Friend]OnAttrsChange(&this, acpStart, acpEnd, cAttrs, paAttrs);

	public HRESULT OnLockGranted(TEXT_STORE_LOCK_FLAGS dwLockFlags) mut => VT.[Friend]OnLockGranted(&this, dwLockFlags);

	public HRESULT OnStartEditTransaction() mut => VT.[Friend]OnStartEditTransaction(&this);

	public HRESULT OnEndEditTransaction() mut => VT.[Friend]OnEndEditTransaction(&this);
}

[CRepr]struct IAnchor : IUnknown
{
	public new const Guid IID = .(0x0feb7e34, 0x5a60, 0x4356, 0x8e, 0xf7, 0xab, 0xde, 0xc2, 0xff, 0x7c, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TsGravity gravity) SetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TsGravity* pgravity) GetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paWith, BOOL* pfEqual) IsEqual;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paWith, int32* plResult) Compare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, int32 cchReq, int32* pcch, IAnchor* paHaltAnchor) Shift;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paSite) ShiftTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, TsShiftDir dir, BOOL* pfNoRegion) ShiftRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask) SetChangeHistoryMask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ANCHOR_CHANGE_HISTORY_FLAGS* pdwHistory) GetChangeHistory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearChangeHistory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor** ppaClone) Clone;
	}


	public HRESULT SetGravity(TsGravity gravity) mut => VT.[Friend]SetGravity(&this, gravity);

	public HRESULT GetGravity(TsGravity* pgravity) mut => VT.[Friend]GetGravity(&this, pgravity);

	public HRESULT IsEqual(IAnchor* paWith, BOOL* pfEqual) mut => VT.[Friend]IsEqual(&this, paWith, pfEqual);

	public HRESULT Compare(IAnchor* paWith, int32* plResult) mut => VT.[Friend]Compare(&this, paWith, plResult);

	public HRESULT Shift(uint32 dwFlags, int32 cchReq, int32* pcch, IAnchor* paHaltAnchor) mut => VT.[Friend]Shift(&this, dwFlags, cchReq, pcch, paHaltAnchor);

	public HRESULT ShiftTo(IAnchor* paSite) mut => VT.[Friend]ShiftTo(&this, paSite);

	public HRESULT ShiftRegion(uint32 dwFlags, TsShiftDir dir, BOOL* pfNoRegion) mut => VT.[Friend]ShiftRegion(&this, dwFlags, dir, pfNoRegion);

	public HRESULT SetChangeHistoryMask(uint32 dwMask) mut => VT.[Friend]SetChangeHistoryMask(&this, dwMask);

	public HRESULT GetChangeHistory(ANCHOR_CHANGE_HISTORY_FLAGS* pdwHistory) mut => VT.[Friend]GetChangeHistory(&this, pdwHistory);

	public HRESULT ClearChangeHistory() mut => VT.[Friend]ClearChangeHistory(&this);

	public HRESULT Clone(IAnchor** ppaClone) mut => VT.[Friend]Clone(&this, ppaClone);
}

[CRepr]struct ITextStoreAnchor : IUnknown
{
	public new const Guid IID = .(0x9b2077b0, 0x5f18, 0x4dec, 0xbe, 0xe9, 0x3c, 0xc7, 0x22, 0xf5, 0xdf, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk, uint32 dwMask) AdviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) UnadviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLockFlags, HRESULT* phrSession) RequestLock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TS_STATUS* pdcs) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paTestStart, IAnchor* paTestEnd, uint32 cch, IAnchor** ppaResultStart, IAnchor** ppaResultEnd) QueryInsert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulIndex, uint32 ulCount, TS_SELECTION_ANCHOR* pSelection, uint32* pcFetched) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_SELECTION_ANCHOR* pSelection) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, char16* pchText, uint32 cchReq, uint32* pcch, BOOL fUpdateAnchor) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, char16* pchText, uint32 cch) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paStart, IAnchor* paEnd, IDataObject** ppDataObject) GetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IAnchor* paPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) GetEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, IDataObject* pDataObject) InsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) RequestSupportedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) RequestAttrsTransitioningAtPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paStart, IAnchor* paHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, BOOL* pfFound, int32* plFoundOffset) FindNextAttrTransition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) RetrieveRequestedAttrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor** ppaStart) GetStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor** ppaEnd) GetEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pvcView) GetActiveView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, POINT* ptScreen, uint32 dwFlags, IAnchor** ppaSite) GetAnchorFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, IAnchor* paStart, IAnchor* paEnd, RECT* prc, BOOL* pfClipped) GetTextExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, RECT* prc) GetScreenExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 vcView, HWND* phwnd) GetWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) QueryInsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, char16* pchText, uint32 cch, IAnchor** ppaStart, IAnchor** ppaEnd) InsertTextAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IDataObject* pDataObject, IAnchor** ppaStart, IAnchor** ppaEnd) InsertEmbeddedAtSelection;
	}


	public HRESULT AdviseSink(in Guid riid, IUnknown* punk, uint32 dwMask) mut => VT.[Friend]AdviseSink(&this, riid, punk, dwMask);

	public HRESULT UnadviseSink(IUnknown* punk) mut => VT.[Friend]UnadviseSink(&this, punk);

	public HRESULT RequestLock(uint32 dwLockFlags, HRESULT* phrSession) mut => VT.[Friend]RequestLock(&this, dwLockFlags, phrSession);

	public HRESULT GetStatus(TS_STATUS* pdcs) mut => VT.[Friend]GetStatus(&this, pdcs);

	public HRESULT QueryInsert(IAnchor* paTestStart, IAnchor* paTestEnd, uint32 cch, IAnchor** ppaResultStart, IAnchor** ppaResultEnd) mut => VT.[Friend]QueryInsert(&this, paTestStart, paTestEnd, cch, ppaResultStart, ppaResultEnd);

	public HRESULT GetSelection(uint32 ulIndex, uint32 ulCount, TS_SELECTION_ANCHOR* pSelection, uint32* pcFetched) mut => VT.[Friend]GetSelection(&this, ulIndex, ulCount, pSelection, pcFetched);

	public HRESULT SetSelection(uint32 ulCount, TS_SELECTION_ANCHOR* pSelection) mut => VT.[Friend]SetSelection(&this, ulCount, pSelection);

	public HRESULT GetText(uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, char16* pchText, uint32 cchReq, uint32* pcch, BOOL fUpdateAnchor) mut => VT.[Friend]GetText(&this, dwFlags, paStart, paEnd, pchText, cchReq, pcch, fUpdateAnchor);

	public HRESULT SetText(uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, char16* pchText, uint32 cch) mut => VT.[Friend]SetText(&this, dwFlags, paStart, paEnd, pchText, cch);

	public HRESULT GetFormattedText(IAnchor* paStart, IAnchor* paEnd, IDataObject** ppDataObject) mut => VT.[Friend]GetFormattedText(&this, paStart, paEnd, ppDataObject);

	public HRESULT GetEmbedded(uint32 dwFlags, IAnchor* paPos, in Guid rguidService, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetEmbedded(&this, dwFlags, paPos, rguidService, riid, ppunk);

	public HRESULT InsertEmbedded(uint32 dwFlags, IAnchor* paStart, IAnchor* paEnd, IDataObject* pDataObject) mut => VT.[Friend]InsertEmbedded(&this, dwFlags, paStart, paEnd, pDataObject);

	public HRESULT RequestSupportedAttrs(uint32 dwFlags, uint32 cFilterAttrs, Guid* paFilterAttrs) mut => VT.[Friend]RequestSupportedAttrs(&this, dwFlags, cFilterAttrs, paFilterAttrs);

	public HRESULT RequestAttrsAtPosition(IAnchor* paPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsAtPosition(&this, paPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT RequestAttrsTransitioningAtPosition(IAnchor* paPos, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags) mut => VT.[Friend]RequestAttrsTransitioningAtPosition(&this, paPos, cFilterAttrs, paFilterAttrs, dwFlags);

	public HRESULT FindNextAttrTransition(IAnchor* paStart, IAnchor* paHalt, uint32 cFilterAttrs, Guid* paFilterAttrs, uint32 dwFlags, BOOL* pfFound, int32* plFoundOffset) mut => VT.[Friend]FindNextAttrTransition(&this, paStart, paHalt, cFilterAttrs, paFilterAttrs, dwFlags, pfFound, plFoundOffset);

	public HRESULT RetrieveRequestedAttrs(uint32 ulCount, TS_ATTRVAL* paAttrVals, uint32* pcFetched) mut => VT.[Friend]RetrieveRequestedAttrs(&this, ulCount, paAttrVals, pcFetched);

	public HRESULT GetStart(IAnchor** ppaStart) mut => VT.[Friend]GetStart(&this, ppaStart);

	public HRESULT GetEnd(IAnchor** ppaEnd) mut => VT.[Friend]GetEnd(&this, ppaEnd);

	public HRESULT GetActiveView(uint32* pvcView) mut => VT.[Friend]GetActiveView(&this, pvcView);

	public HRESULT GetAnchorFromPoint(uint32 vcView, POINT* ptScreen, uint32 dwFlags, IAnchor** ppaSite) mut => VT.[Friend]GetAnchorFromPoint(&this, vcView, ptScreen, dwFlags, ppaSite);

	public HRESULT GetTextExt(uint32 vcView, IAnchor* paStart, IAnchor* paEnd, RECT* prc, BOOL* pfClipped) mut => VT.[Friend]GetTextExt(&this, vcView, paStart, paEnd, prc, pfClipped);

	public HRESULT GetScreenExt(uint32 vcView, RECT* prc) mut => VT.[Friend]GetScreenExt(&this, vcView, prc);

	public HRESULT GetWnd(uint32 vcView, HWND* phwnd) mut => VT.[Friend]GetWnd(&this, vcView, phwnd);

	public HRESULT QueryInsertEmbedded(in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) mut => VT.[Friend]QueryInsertEmbedded(&this, pguidService, pFormatEtc, pfInsertable);

	public HRESULT InsertTextAtSelection(uint32 dwFlags, char16* pchText, uint32 cch, IAnchor** ppaStart, IAnchor** ppaEnd) mut => VT.[Friend]InsertTextAtSelection(&this, dwFlags, pchText, cch, ppaStart, ppaEnd);

	public HRESULT InsertEmbeddedAtSelection(uint32 dwFlags, IDataObject* pDataObject, IAnchor** ppaStart, IAnchor** ppaEnd) mut => VT.[Friend]InsertEmbeddedAtSelection(&this, dwFlags, pDataObject, ppaStart, ppaEnd);
}

[CRepr]struct ITextStoreAnchorSink : IUnknown
{
	public new const Guid IID = .(0xaa80e905, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXT_STORE_CHANGE_FLAGS dwFlags, IAnchor* paStart, IAnchor* paEnd) OnTextChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnSelectionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TsLayoutCode lcode, uint32 vcView) OnLayoutChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) OnStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* paStart, IAnchor* paEnd, uint32 cAttrs, Guid* paAttrs) OnAttrsChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TEXT_STORE_LOCK_FLAGS dwLockFlags) OnLockGranted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnStartEditTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnEndEditTransaction;
	}


	public HRESULT OnTextChange(TEXT_STORE_CHANGE_FLAGS dwFlags, IAnchor* paStart, IAnchor* paEnd) mut => VT.[Friend]OnTextChange(&this, dwFlags, paStart, paEnd);

	public HRESULT OnSelectionChange() mut => VT.[Friend]OnSelectionChange(&this);

	public HRESULT OnLayoutChange(TsLayoutCode lcode, uint32 vcView) mut => VT.[Friend]OnLayoutChange(&this, lcode, vcView);

	public HRESULT OnStatusChange(uint32 dwFlags) mut => VT.[Friend]OnStatusChange(&this, dwFlags);

	public HRESULT OnAttrsChange(IAnchor* paStart, IAnchor* paEnd, uint32 cAttrs, Guid* paAttrs) mut => VT.[Friend]OnAttrsChange(&this, paStart, paEnd, cAttrs, paAttrs);

	public HRESULT OnLockGranted(TEXT_STORE_LOCK_FLAGS dwLockFlags) mut => VT.[Friend]OnLockGranted(&this, dwLockFlags);

	public HRESULT OnStartEditTransaction() mut => VT.[Friend]OnStartEditTransaction(&this);

	public HRESULT OnEndEditTransaction() mut => VT.[Friend]OnEndEditTransaction(&this);
}

[CRepr]struct ITfLangBarMgr : IUnknown
{
	public new const Guid IID = .(0x87955690, 0xe627, 0x11d2, 0x8d, 0xdb, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfLangBarEventSink* pSink, HWND hwnd, uint32 dwFlags, uint32* pdwCookie) AdviseEventSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnadviseEventSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, uint32 dwType, in Guid riid, IUnknown** ppunk) GetThreadMarshalInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, ITfLangBarItemMgr** pplbi, uint32* pdwThreadid) GetThreadLangBarItemMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, ITfInputProcessorProfiles** ppaip, uint32* pdwThreadid) GetInputProcessorProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwThreadId, BOOL fPrev) RestoreLastFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfLangBarEventSink* pSink, uint32 dwThreadId, uint32 dwFlags) SetModalInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) ShowFloating;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetShowFloatingStatus;
	}


	public HRESULT AdviseEventSink(ITfLangBarEventSink* pSink, HWND hwnd, uint32 dwFlags, uint32* pdwCookie) mut => VT.[Friend]AdviseEventSink(&this, pSink, hwnd, dwFlags, pdwCookie);

	public HRESULT UnadviseEventSink(uint32 dwCookie) mut => VT.[Friend]UnadviseEventSink(&this, dwCookie);

	public HRESULT GetThreadMarshalInterface(uint32 dwThreadId, uint32 dwType, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetThreadMarshalInterface(&this, dwThreadId, dwType, riid, ppunk);

	public HRESULT GetThreadLangBarItemMgr(uint32 dwThreadId, ITfLangBarItemMgr** pplbi, uint32* pdwThreadid) mut => VT.[Friend]GetThreadLangBarItemMgr(&this, dwThreadId, pplbi, pdwThreadid);

	public HRESULT GetInputProcessorProfiles(uint32 dwThreadId, ITfInputProcessorProfiles** ppaip, uint32* pdwThreadid) mut => VT.[Friend]GetInputProcessorProfiles(&this, dwThreadId, ppaip, pdwThreadid);

	public HRESULT RestoreLastFocus(uint32* pdwThreadId, BOOL fPrev) mut => VT.[Friend]RestoreLastFocus(&this, pdwThreadId, fPrev);

	public HRESULT SetModalInput(ITfLangBarEventSink* pSink, uint32 dwThreadId, uint32 dwFlags) mut => VT.[Friend]SetModalInput(&this, pSink, dwThreadId, dwFlags);

	public HRESULT ShowFloating(uint32 dwFlags) mut => VT.[Friend]ShowFloating(&this, dwFlags);

	public HRESULT GetShowFloatingStatus(uint32* pdwFlags) mut => VT.[Friend]GetShowFloatingStatus(&this, pdwFlags);
}

[CRepr]struct ITfLangBarEventSink : IUnknown
{
	public new const Guid IID = .(0x18a4e900, 0xe0ae, 0x11d2, 0xaf, 0xdd, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId) OnSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId) OnThreadTerminate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId) OnThreadItemChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, uint32 uMsg, WPARAM wParam, LPARAM lParam) OnModalInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) ShowFloating;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, in Guid rguid, RECT* prc) GetItemFloatingRect;
	}


	public HRESULT OnSetFocus(uint32 dwThreadId) mut => VT.[Friend]OnSetFocus(&this, dwThreadId);

	public HRESULT OnThreadTerminate(uint32 dwThreadId) mut => VT.[Friend]OnThreadTerminate(&this, dwThreadId);

	public HRESULT OnThreadItemChange(uint32 dwThreadId) mut => VT.[Friend]OnThreadItemChange(&this, dwThreadId);

	public HRESULT OnModalInput(uint32 dwThreadId, uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]OnModalInput(&this, dwThreadId, uMsg, wParam, lParam);

	public HRESULT ShowFloating(uint32 dwFlags) mut => VT.[Friend]ShowFloating(&this, dwFlags);

	public HRESULT GetItemFloatingRect(uint32 dwThreadId, in Guid rguid, RECT* prc) mut => VT.[Friend]GetItemFloatingRect(&this, dwThreadId, rguid, prc);
}

[CRepr]struct ITfLangBarItemSink : IUnknown
{
	public new const Guid IID = .(0x57dbe1a0, 0xde25, 0x11d2, 0xaf, 0xdd, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) OnUpdate;
	}


	public HRESULT OnUpdate(uint32 dwFlags) mut => VT.[Friend]OnUpdate(&this, dwFlags);
}

[CRepr]struct IEnumTfLangBarItems : IUnknown
{
	public new const Guid IID = .(0x583f34d0, 0xde25, 0x11d2, 0xaf, 0xdd, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfLangBarItems** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfLangBarItem** ppItem, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfLangBarItems** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfLangBarItem** ppItem, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, ppItem, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfLangBarItemMgr : IUnknown
{
	public new const Guid IID = .(0xba468c55, 0x9956, 0x4fb1, 0xa5, 0x9d, 0x52, 0xa7, 0xdd, 0x7c, 0xc6, 0xaa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfLangBarItems** ppEnum) EnumItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, ITfLangBarItem** ppItem) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfLangBarItem* punk) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfLangBarItem* punk) RemoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfLangBarItemSink* punk, uint32* pdwCookie, in Guid rguidItem) AdviseItemSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnadviseItemSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadId, in Guid rguid, RECT* prc) GetItemFloatingRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, Guid* prgguid, uint32* pdwStatus) GetItemsStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pulCount) GetItemNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfLangBarItem** ppItem, TF_LANGBARITEMINFO* pInfo, uint32* pdwStatus, uint32* pcFetched) GetItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfLangBarItemSink** ppunk, Guid* pguidItem, uint32* pdwCookie) AdviseItemsSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, uint32* pdwCookie) UnadviseItemsSink;
	}


	public HRESULT EnumItems(IEnumTfLangBarItems** ppEnum) mut => VT.[Friend]EnumItems(&this, ppEnum);

	public HRESULT GetItem(in Guid rguid, ITfLangBarItem** ppItem) mut => VT.[Friend]GetItem(&this, rguid, ppItem);

	public HRESULT AddItem(ITfLangBarItem* punk) mut => VT.[Friend]AddItem(&this, punk);

	public HRESULT RemoveItem(ITfLangBarItem* punk) mut => VT.[Friend]RemoveItem(&this, punk);

	public HRESULT AdviseItemSink(ITfLangBarItemSink* punk, uint32* pdwCookie, in Guid rguidItem) mut => VT.[Friend]AdviseItemSink(&this, punk, pdwCookie, rguidItem);

	public HRESULT UnadviseItemSink(uint32 dwCookie) mut => VT.[Friend]UnadviseItemSink(&this, dwCookie);

	public HRESULT GetItemFloatingRect(uint32 dwThreadId, in Guid rguid, RECT* prc) mut => VT.[Friend]GetItemFloatingRect(&this, dwThreadId, rguid, prc);

	public HRESULT GetItemsStatus(uint32 ulCount, Guid* prgguid, uint32* pdwStatus) mut => VT.[Friend]GetItemsStatus(&this, ulCount, prgguid, pdwStatus);

	public HRESULT GetItemNum(uint32* pulCount) mut => VT.[Friend]GetItemNum(&this, pulCount);

	public HRESULT GetItems(uint32 ulCount, ITfLangBarItem** ppItem, TF_LANGBARITEMINFO* pInfo, uint32* pdwStatus, uint32* pcFetched) mut => VT.[Friend]GetItems(&this, ulCount, ppItem, pInfo, pdwStatus, pcFetched);

	public HRESULT AdviseItemsSink(uint32 ulCount, ITfLangBarItemSink** ppunk, Guid* pguidItem, uint32* pdwCookie) mut => VT.[Friend]AdviseItemsSink(&this, ulCount, ppunk, pguidItem, pdwCookie);

	public HRESULT UnadviseItemsSink(uint32 ulCount, uint32* pdwCookie) mut => VT.[Friend]UnadviseItemsSink(&this, ulCount, pdwCookie);
}

[CRepr]struct ITfLangBarItem : IUnknown
{
	public new const Guid IID = .(0x73540d69, 0xedeb, 0x4ee9, 0x96, 0xc9, 0x23, 0xaa, 0x30, 0xb2, 0x59, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_LANGBARITEMINFO* pInfo) GetInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrToolTip) GetTooltipString;
	}


	public HRESULT GetInfo(TF_LANGBARITEMINFO* pInfo) mut => VT.[Friend]GetInfo(&this, pInfo);

	public HRESULT GetStatus(uint32* pdwStatus) mut => VT.[Friend]GetStatus(&this, pdwStatus);

	public HRESULT Show(BOOL fShow) mut => VT.[Friend]Show(&this, fShow);

	public HRESULT GetTooltipString(BSTR* pbstrToolTip) mut => VT.[Friend]GetTooltipString(&this, pbstrToolTip);
}

[CRepr]struct ITfSystemLangBarItemSink : IUnknown
{
	public new const Guid IID = .(0x1449d9ab, 0x13cf, 0x4687, 0xaa, 0x3e, 0x8d, 0x8b, 0x18, 0x57, 0x43, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfMenu* pMenu) InitMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 wID) OnMenuSelect;
	}


	public HRESULT InitMenu(ITfMenu* pMenu) mut => VT.[Friend]InitMenu(&this, pMenu);

	public HRESULT OnMenuSelect(uint32 wID) mut => VT.[Friend]OnMenuSelect(&this, wID);
}

[CRepr]struct ITfSystemLangBarItem : IUnknown
{
	public new const Guid IID = .(0x1e13e9ec, 0x6b33, 0x4d4a, 0xb5, 0xeb, 0x8a, 0x92, 0xf0, 0x29, 0xf3, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON hIcon) SetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pchToolTip, uint32 cch) SetTooltipString;
	}


	public HRESULT SetIcon(HICON hIcon) mut => VT.[Friend]SetIcon(&this, hIcon);

	public HRESULT SetTooltipString(char16* pchToolTip, uint32 cch) mut => VT.[Friend]SetTooltipString(&this, pchToolTip, cch);
}

[CRepr]struct ITfSystemLangBarItemText : IUnknown
{
	public new const Guid IID = .(0x5c4ce0e5, 0xba49, 0x4b52, 0xac, 0x6b, 0x3b, 0x39, 0x7b, 0x4f, 0x70, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pch, uint32 cch) SetItemText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) GetItemText;
	}


	public HRESULT SetItemText(char16* pch, uint32 cch) mut => VT.[Friend]SetItemText(&this, pch, cch);

	public HRESULT GetItemText(BSTR* pbstrText) mut => VT.[Friend]GetItemText(&this, pbstrText);
}

[CRepr]struct ITfSystemDeviceTypeLangBarItem : IUnknown
{
	public new const Guid IID = .(0x45672eb9, 0x9059, 0x46a2, 0x83, 0x8d, 0x45, 0x30, 0x35, 0x5f, 0x6a, 0x77);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LANG_BAR_ITEM_ICON_MODE_FLAGS dwFlags) SetIconMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetIconMode;
	}


	public HRESULT SetIconMode(LANG_BAR_ITEM_ICON_MODE_FLAGS dwFlags) mut => VT.[Friend]SetIconMode(&this, dwFlags);

	public HRESULT GetIconMode(uint32* pdwFlags) mut => VT.[Friend]GetIconMode(&this, pdwFlags);
}

[CRepr]struct ITfLangBarItemButton : ITfLangBarItem
{
	public new const Guid IID = .(0x28c7f1d0, 0xde25, 0x11d2, 0xaf, 0xdd, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfLangBarItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBIClick click, POINT pt, RECT* prcArea) OnClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfMenu* pMenu) InitMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 wID) OnMenuSelect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON* phIcon) GetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) GetText;
	}


	public HRESULT OnClick(TfLBIClick click, POINT pt, RECT* prcArea) mut => VT.[Friend]OnClick(&this, click, pt, prcArea);

	public HRESULT InitMenu(ITfMenu* pMenu) mut => VT.[Friend]InitMenu(&this, pMenu);

	public HRESULT OnMenuSelect(uint32 wID) mut => VT.[Friend]OnMenuSelect(&this, wID);

	public HRESULT GetIcon(HICON* phIcon) mut => VT.[Friend]GetIcon(&this, phIcon);

	public HRESULT GetText(BSTR* pbstrText) mut => VT.[Friend]GetText(&this, pbstrText);
}

[CRepr]struct ITfLangBarItemBitmapButton : ITfLangBarItem
{
	public new const Guid IID = .(0xa26a0525, 0x3fae, 0x4fa0, 0x89, 0xee, 0x88, 0xa9, 0x64, 0xf9, 0xf1, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfLangBarItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBIClick click, POINT pt, RECT* prcArea) OnClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfMenu* pMenu) InitMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 wID) OnMenuSelect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pszDefault, SIZE* psz) GetPreferredSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 bmWidth, int32 bmHeight, uint32 dwFlags, HBITMAP* phbmp, HBITMAP* phbmpMask) DrawBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrText) GetText;
	}


	public HRESULT OnClick(TfLBIClick click, POINT pt, RECT* prcArea) mut => VT.[Friend]OnClick(&this, click, pt, prcArea);

	public HRESULT InitMenu(ITfMenu* pMenu) mut => VT.[Friend]InitMenu(&this, pMenu);

	public HRESULT OnMenuSelect(uint32 wID) mut => VT.[Friend]OnMenuSelect(&this, wID);

	public HRESULT GetPreferredSize(SIZE* pszDefault, SIZE* psz) mut => VT.[Friend]GetPreferredSize(&this, pszDefault, psz);

	public HRESULT DrawBitmap(int32 bmWidth, int32 bmHeight, uint32 dwFlags, HBITMAP* phbmp, HBITMAP* phbmpMask) mut => VT.[Friend]DrawBitmap(&this, bmWidth, bmHeight, dwFlags, phbmp, phbmpMask);

	public HRESULT GetText(BSTR* pbstrText) mut => VT.[Friend]GetText(&this, pbstrText);
}

[CRepr]struct ITfLangBarItemBitmap : ITfLangBarItem
{
	public new const Guid IID = .(0x73830352, 0xd722, 0x4179, 0xad, 0xa5, 0xf0, 0x45, 0xc9, 0x8d, 0xf3, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfLangBarItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBIClick click, POINT pt, RECT* prcArea) OnClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pszDefault, SIZE* psz) GetPreferredSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 bmWidth, int32 bmHeight, uint32 dwFlags, HBITMAP* phbmp, HBITMAP* phbmpMask) DrawBitmap;
	}


	public HRESULT OnClick(TfLBIClick click, POINT pt, RECT* prcArea) mut => VT.[Friend]OnClick(&this, click, pt, prcArea);

	public HRESULT GetPreferredSize(SIZE* pszDefault, SIZE* psz) mut => VT.[Friend]GetPreferredSize(&this, pszDefault, psz);

	public HRESULT DrawBitmap(int32 bmWidth, int32 bmHeight, uint32 dwFlags, HBITMAP* phbmp, HBITMAP* phbmpMask) mut => VT.[Friend]DrawBitmap(&this, bmWidth, bmHeight, dwFlags, phbmp, phbmpMask);
}

[CRepr]struct ITfLangBarItemBalloon : ITfLangBarItem
{
	public new const Guid IID = .(0x01c2d285, 0xd3c7, 0x4b7b, 0xb5, 0xb5, 0xd9, 0x74, 0x11, 0xd0, 0xc2, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfLangBarItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBIClick click, POINT pt, RECT* prcArea) OnClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pszDefault, SIZE* psz) GetPreferredSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_LBBALLOONINFO* pInfo) GetBalloonInfo;
	}


	public HRESULT OnClick(TfLBIClick click, POINT pt, RECT* prcArea) mut => VT.[Friend]OnClick(&this, click, pt, prcArea);

	public HRESULT GetPreferredSize(SIZE* pszDefault, SIZE* psz) mut => VT.[Friend]GetPreferredSize(&this, pszDefault, psz);

	public HRESULT GetBalloonInfo(TF_LBBALLOONINFO* pInfo) mut => VT.[Friend]GetBalloonInfo(&this, pInfo);
}

[CRepr]struct ITfMenu : IUnknown
{
	public new const Guid IID = .(0x6f8a98e4, 0xaaa0, 0x4f15, 0x8c, 0x5b, 0x07, 0xe0, 0xdf, 0x0a, 0x3d, 0xd8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uId, uint32 dwFlags, HBITMAP hbmp, HBITMAP hbmpMask, char16* pch, uint32 cch, ITfMenu** ppMenu) AddMenuItem;
	}


	public HRESULT AddMenuItem(uint32 uId, uint32 dwFlags, HBITMAP hbmp, HBITMAP hbmpMask, char16* pch, uint32 cch, ITfMenu** ppMenu) mut => VT.[Friend]AddMenuItem(&this, uId, dwFlags, hbmp, hbmpMask, pch, cch, ppMenu);
}

[CRepr]struct ITfThreadMgr : IUnknown
{
	public new const Guid IID = .(0xaa80e801, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* ptid) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Deactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdim) CreateDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDocumentMgrs** ppEnum) EnumDocumentMgrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdimFocus) GetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr* pdimFocus) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, ITfDocumentMgr* pdimNew, ITfDocumentMgr** ppdimPrev) AssociateFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfThreadFocus) IsThreadFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, ITfFunctionProvider** ppFuncProv) GetFunctionProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfFunctionProviders** ppEnum) EnumFunctionProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompartmentMgr** ppCompMgr) GetGlobalCompartment;
	}


	public HRESULT Activate(uint32* ptid) mut => VT.[Friend]Activate(&this, ptid);

	public HRESULT Deactivate() mut => VT.[Friend]Deactivate(&this);

	public HRESULT CreateDocumentMgr(ITfDocumentMgr** ppdim) mut => VT.[Friend]CreateDocumentMgr(&this, ppdim);

	public HRESULT EnumDocumentMgrs(IEnumTfDocumentMgrs** ppEnum) mut => VT.[Friend]EnumDocumentMgrs(&this, ppEnum);

	public HRESULT GetFocus(ITfDocumentMgr** ppdimFocus) mut => VT.[Friend]GetFocus(&this, ppdimFocus);

	public HRESULT SetFocus(ITfDocumentMgr* pdimFocus) mut => VT.[Friend]SetFocus(&this, pdimFocus);

	public HRESULT AssociateFocus(HWND hwnd, ITfDocumentMgr* pdimNew, ITfDocumentMgr** ppdimPrev) mut => VT.[Friend]AssociateFocus(&this, hwnd, pdimNew, ppdimPrev);

	public HRESULT IsThreadFocus(BOOL* pfThreadFocus) mut => VT.[Friend]IsThreadFocus(&this, pfThreadFocus);

	public HRESULT GetFunctionProvider(in Guid clsid, ITfFunctionProvider** ppFuncProv) mut => VT.[Friend]GetFunctionProvider(&this, clsid, ppFuncProv);

	public HRESULT EnumFunctionProviders(IEnumTfFunctionProviders** ppEnum) mut => VT.[Friend]EnumFunctionProviders(&this, ppEnum);

	public HRESULT GetGlobalCompartment(ITfCompartmentMgr** ppCompMgr) mut => VT.[Friend]GetGlobalCompartment(&this, ppCompMgr);
}

[CRepr]struct ITfThreadMgrEx : ITfThreadMgr
{
	public new const Guid IID = .(0x3e90ade3, 0x7594, 0x4cb0, 0xbb, 0x58, 0x69, 0x62, 0x8f, 0x5f, 0x45, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfThreadMgr.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* ptid, uint32 dwFlags) ActivateEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpdwFlags) GetActiveFlags;
	}


	public HRESULT ActivateEx(uint32* ptid, uint32 dwFlags) mut => VT.[Friend]ActivateEx(&this, ptid, dwFlags);

	public HRESULT GetActiveFlags(uint32* lpdwFlags) mut => VT.[Friend]GetActiveFlags(&this, lpdwFlags);
}

[CRepr]struct ITfThreadMgr2 : IUnknown
{
	public new const Guid IID = .(0x0ab198ef, 0x6477, 0x4ee8, 0x88, 0x12, 0x67, 0x80, 0xed, 0xb8, 0x2d, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* ptid) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Deactivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdim) CreateDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDocumentMgrs** ppEnum) EnumDocumentMgrs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdimFocus) GetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr* pdimFocus) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfThreadFocus) IsThreadFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, ITfFunctionProvider** ppFuncProv) GetFunctionProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfFunctionProviders** ppEnum) EnumFunctionProviders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompartmentMgr** ppCompMgr) GetGlobalCompartment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* ptid, uint32 dwFlags) ActivateEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* lpdwFlags) GetActiveFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SuspendKeystrokeHandling;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeKeystrokeHandling;
	}


	public HRESULT Activate(uint32* ptid) mut => VT.[Friend]Activate(&this, ptid);

	public HRESULT Deactivate() mut => VT.[Friend]Deactivate(&this);

	public HRESULT CreateDocumentMgr(ITfDocumentMgr** ppdim) mut => VT.[Friend]CreateDocumentMgr(&this, ppdim);

	public HRESULT EnumDocumentMgrs(IEnumTfDocumentMgrs** ppEnum) mut => VT.[Friend]EnumDocumentMgrs(&this, ppEnum);

	public HRESULT GetFocus(ITfDocumentMgr** ppdimFocus) mut => VT.[Friend]GetFocus(&this, ppdimFocus);

	public HRESULT SetFocus(ITfDocumentMgr* pdimFocus) mut => VT.[Friend]SetFocus(&this, pdimFocus);

	public HRESULT IsThreadFocus(BOOL* pfThreadFocus) mut => VT.[Friend]IsThreadFocus(&this, pfThreadFocus);

	public HRESULT GetFunctionProvider(in Guid clsid, ITfFunctionProvider** ppFuncProv) mut => VT.[Friend]GetFunctionProvider(&this, clsid, ppFuncProv);

	public HRESULT EnumFunctionProviders(IEnumTfFunctionProviders** ppEnum) mut => VT.[Friend]EnumFunctionProviders(&this, ppEnum);

	public HRESULT GetGlobalCompartment(ITfCompartmentMgr** ppCompMgr) mut => VT.[Friend]GetGlobalCompartment(&this, ppCompMgr);

	public HRESULT ActivateEx(uint32* ptid, uint32 dwFlags) mut => VT.[Friend]ActivateEx(&this, ptid, dwFlags);

	public HRESULT GetActiveFlags(uint32* lpdwFlags) mut => VT.[Friend]GetActiveFlags(&this, lpdwFlags);

	public HRESULT SuspendKeystrokeHandling() mut => VT.[Friend]SuspendKeystrokeHandling(&this);

	public HRESULT ResumeKeystrokeHandling() mut => VT.[Friend]ResumeKeystrokeHandling(&this);
}

[CRepr]struct ITfThreadMgrEventSink : IUnknown
{
	public new const Guid IID = .(0xaa80e80e, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr* pdim) OnInitDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr* pdim) OnUninitDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr* pdimFocus, ITfDocumentMgr* pdimPrevFocus) OnSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic) OnPushContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic) OnPopContext;
	}


	public HRESULT OnInitDocumentMgr(ITfDocumentMgr* pdim) mut => VT.[Friend]OnInitDocumentMgr(&this, pdim);

	public HRESULT OnUninitDocumentMgr(ITfDocumentMgr* pdim) mut => VT.[Friend]OnUninitDocumentMgr(&this, pdim);

	public HRESULT OnSetFocus(ITfDocumentMgr* pdimFocus, ITfDocumentMgr* pdimPrevFocus) mut => VT.[Friend]OnSetFocus(&this, pdimFocus, pdimPrevFocus);

	public HRESULT OnPushContext(ITfContext* pic) mut => VT.[Friend]OnPushContext(&this, pic);

	public HRESULT OnPopContext(ITfContext* pic) mut => VT.[Friend]OnPopContext(&this, pic);
}

[CRepr]struct ITfConfigureSystemKeystrokeFeed : IUnknown
{
	public new const Guid IID = .(0x0d2c969a, 0xbc9c, 0x437c, 0x84, 0xee, 0x95, 0x1c, 0x49, 0xb1, 0xa7, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisableSystemKeystrokeFeed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableSystemKeystrokeFeed;
	}


	public HRESULT DisableSystemKeystrokeFeed() mut => VT.[Friend]DisableSystemKeystrokeFeed(&this);

	public HRESULT EnableSystemKeystrokeFeed() mut => VT.[Friend]EnableSystemKeystrokeFeed(&this);
}

[CRepr]struct IEnumTfDocumentMgrs : IUnknown
{
	public new const Guid IID = .(0xaa80e808, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDocumentMgrs** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfDocumentMgr** rgDocumentMgr, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfDocumentMgrs** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfDocumentMgr** rgDocumentMgr, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgDocumentMgr, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfDocumentMgr : IUnknown
{
	public new const Guid IID = .(0xaa80e7f4, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tidOwner, uint32 dwFlags, IUnknown* punk, ITfContext** ppic, uint32* pecTextStore) CreateContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic) Push;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) Pop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext** ppic) GetTop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext** ppic) GetBase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfContexts** ppEnum) EnumContexts;
	}


	public HRESULT CreateContext(uint32 tidOwner, uint32 dwFlags, IUnknown* punk, ITfContext** ppic, uint32* pecTextStore) mut => VT.[Friend]CreateContext(&this, tidOwner, dwFlags, punk, ppic, pecTextStore);

	public HRESULT Push(ITfContext* pic) mut => VT.[Friend]Push(&this, pic);

	public HRESULT Pop(uint32 dwFlags) mut => VT.[Friend]Pop(&this, dwFlags);

	public HRESULT GetTop(ITfContext** ppic) mut => VT.[Friend]GetTop(&this, ppic);

	public HRESULT GetBase(ITfContext** ppic) mut => VT.[Friend]GetBase(&this, ppic);

	public HRESULT EnumContexts(IEnumTfContexts** ppEnum) mut => VT.[Friend]EnumContexts(&this, ppEnum);
}

[CRepr]struct IEnumTfContexts : IUnknown
{
	public new const Guid IID = .(0x8f1a7ea6, 0x1654, 0x4502, 0xa8, 0x6e, 0xb2, 0x90, 0x23, 0x44, 0xd5, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfContexts** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfContext** rgContext, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfContexts** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfContext** rgContext, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgContext, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfCompositionView : IUnknown
{
	public new const Guid IID = .(0xd7540241, 0xf9a1, 0x4364, 0xbe, 0xfc, 0xdb, 0xcd, 0x2c, 0x43, 0x95, 0xb7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetOwnerClsid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange** ppRange) GetRange;
	}


	public HRESULT GetOwnerClsid(Guid* pclsid) mut => VT.[Friend]GetOwnerClsid(&this, pclsid);

	public HRESULT GetRange(ITfRange** ppRange) mut => VT.[Friend]GetRange(&this, ppRange);
}

[CRepr]struct IEnumITfCompositionView : IUnknown
{
	public new const Guid IID = .(0x5efd22ba, 0x7838, 0x46cb, 0x88, 0xe2, 0xca, 0xdb, 0x14, 0x12, 0x4f, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumITfCompositionView** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfCompositionView** rgCompositionView, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumITfCompositionView** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfCompositionView** rgCompositionView, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgCompositionView, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfComposition : IUnknown
{
	public new const Guid IID = .(0x20168d64, 0x5a8f, 0x4a5a, 0xb7, 0xbd, 0xcf, 0xa2, 0x9f, 0x4d, 0x0f, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange** ppRange) GetRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfRange* pNewStart) ShiftStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfRange* pNewEnd) ShiftEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite) EndComposition;
	}


	public HRESULT GetRange(ITfRange** ppRange) mut => VT.[Friend]GetRange(&this, ppRange);

	public HRESULT ShiftStart(uint32 ecWrite, ITfRange* pNewStart) mut => VT.[Friend]ShiftStart(&this, ecWrite, pNewStart);

	public HRESULT ShiftEnd(uint32 ecWrite, ITfRange* pNewEnd) mut => VT.[Friend]ShiftEnd(&this, ecWrite, pNewEnd);

	public HRESULT EndComposition(uint32 ecWrite) mut => VT.[Friend]EndComposition(&this, ecWrite);
}

[CRepr]struct ITfCompositionSink : IUnknown
{
	public new const Guid IID = .(0xa781718c, 0x579a, 0x4b15, 0xa2, 0x80, 0x32, 0xb8, 0x57, 0x7a, 0xcc, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfComposition* pComposition) OnCompositionTerminated;
	}


	public HRESULT OnCompositionTerminated(uint32 ecWrite, ITfComposition* pComposition) mut => VT.[Friend]OnCompositionTerminated(&this, ecWrite, pComposition);
}

[CRepr]struct ITfContextComposition : IUnknown
{
	public new const Guid IID = .(0xd40c8aae, 0xac92, 0x4fc7, 0x9a, 0x11, 0x0e, 0xe0, 0xe2, 0x3a, 0xa3, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfRange* pCompositionRange, ITfCompositionSink* pSink, ITfComposition** ppComposition) StartComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumITfCompositionView** ppEnum) EnumCompositions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecRead, ITfRange* pTestRange, IEnumITfCompositionView** ppEnum) FindComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfCompositionView* pComposition, ITfCompositionSink* pSink, ITfComposition** ppComposition) TakeOwnership;
	}


	public HRESULT StartComposition(uint32 ecWrite, ITfRange* pCompositionRange, ITfCompositionSink* pSink, ITfComposition** ppComposition) mut => VT.[Friend]StartComposition(&this, ecWrite, pCompositionRange, pSink, ppComposition);

	public HRESULT EnumCompositions(IEnumITfCompositionView** ppEnum) mut => VT.[Friend]EnumCompositions(&this, ppEnum);

	public HRESULT FindComposition(uint32 ecRead, ITfRange* pTestRange, IEnumITfCompositionView** ppEnum) mut => VT.[Friend]FindComposition(&this, ecRead, pTestRange, ppEnum);

	public HRESULT TakeOwnership(uint32 ecWrite, ITfCompositionView* pComposition, ITfCompositionSink* pSink, ITfComposition** ppComposition) mut => VT.[Friend]TakeOwnership(&this, ecWrite, pComposition, pSink, ppComposition);
}

[CRepr]struct ITfContextOwnerCompositionServices : ITfContextComposition
{
	public new const Guid IID = .(0x86462810, 0x593b, 0x4916, 0x97, 0x64, 0x19, 0xc0, 0x8e, 0x9c, 0xe1, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfContextComposition.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompositionView* pComposition) TerminateComposition;
	}


	public HRESULT TerminateComposition(ITfCompositionView* pComposition) mut => VT.[Friend]TerminateComposition(&this, pComposition);
}

[CRepr]struct ITfContextOwnerCompositionSink : IUnknown
{
	public new const Guid IID = .(0x5f20aa40, 0xb57a, 0x4f34, 0x96, 0xab, 0x35, 0x76, 0xf3, 0x77, 0xcc, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompositionView* pComposition, BOOL* pfOk) OnStartComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompositionView* pComposition, ITfRange* pRangeNew) OnUpdateComposition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfCompositionView* pComposition) OnEndComposition;
	}


	public HRESULT OnStartComposition(ITfCompositionView* pComposition, BOOL* pfOk) mut => VT.[Friend]OnStartComposition(&this, pComposition, pfOk);

	public HRESULT OnUpdateComposition(ITfCompositionView* pComposition, ITfRange* pRangeNew) mut => VT.[Friend]OnUpdateComposition(&this, pComposition, pRangeNew);

	public HRESULT OnEndComposition(ITfCompositionView* pComposition) mut => VT.[Friend]OnEndComposition(&this, pComposition);
}

[CRepr]struct ITfContextView : IUnknown
{
	public new const Guid IID = .(0x2433bf8e, 0x0f9b, 0x435c, 0xba, 0x2c, 0x18, 0x06, 0x11, 0x97, 0x8c, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, POINT* ppt, uint32 dwFlags, ITfRange** ppRange) GetRangeFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, RECT* prc, BOOL* pfClipped) GetTextExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) GetScreenExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetWnd;
	}


	public HRESULT GetRangeFromPoint(uint32 ec, POINT* ppt, uint32 dwFlags, ITfRange** ppRange) mut => VT.[Friend]GetRangeFromPoint(&this, ec, ppt, dwFlags, ppRange);

	public HRESULT GetTextExt(uint32 ec, ITfRange* pRange, RECT* prc, BOOL* pfClipped) mut => VT.[Friend]GetTextExt(&this, ec, pRange, prc, pfClipped);

	public HRESULT GetScreenExt(RECT* prc) mut => VT.[Friend]GetScreenExt(&this, prc);

	public HRESULT GetWnd(HWND* phwnd) mut => VT.[Friend]GetWnd(&this, phwnd);
}

[CRepr]struct IEnumTfContextViews : IUnknown
{
	public new const Guid IID = .(0xf0c0f8dd, 0xcf38, 0x44e1, 0xbb, 0x0f, 0x68, 0xcf, 0x0d, 0x55, 0x1c, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfContextViews** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfContextView** rgViews, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfContextViews** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfContextView** rgViews, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgViews, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfContext : IUnknown
{
	public new const Guid IID = .(0xaa80e7fd, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, ITfEditSession* pes, TF_CONTEXT_EDIT_CONTEXT_FLAGS dwFlags, HRESULT* phrSession) RequestEditSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, BOOL* pfWriteSession) InWriteSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 ulIndex, uint32 ulCount, TF_SELECTION* pSelection, uint32* pcFetched) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 ulCount, TF_SELECTION* pSelection) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange** ppStart) GetStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange** ppEnd) GetEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContextView** ppView) GetActiveView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfContextViews** ppEnum) EnumViews;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TS_STATUS* pdcs) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProp, ITfProperty** ppProp) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProp, ITfReadOnlyProperty** ppProp) GetAppProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid** prgProp, uint32 cProp, Guid** prgAppProp, uint32 cAppProp, ITfReadOnlyProperty** ppProperty) TrackProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfProperties** ppEnum) EnumProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppDm) GetDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, ITfRangeBackup** ppBackup) CreateRangeBackup;
	}


	public HRESULT RequestEditSession(uint32 tid, ITfEditSession* pes, TF_CONTEXT_EDIT_CONTEXT_FLAGS dwFlags, HRESULT* phrSession) mut => VT.[Friend]RequestEditSession(&this, tid, pes, dwFlags, phrSession);

	public HRESULT InWriteSession(uint32 tid, BOOL* pfWriteSession) mut => VT.[Friend]InWriteSession(&this, tid, pfWriteSession);

	public HRESULT GetSelection(uint32 ec, uint32 ulIndex, uint32 ulCount, TF_SELECTION* pSelection, uint32* pcFetched) mut => VT.[Friend]GetSelection(&this, ec, ulIndex, ulCount, pSelection, pcFetched);

	public HRESULT SetSelection(uint32 ec, uint32 ulCount, TF_SELECTION* pSelection) mut => VT.[Friend]SetSelection(&this, ec, ulCount, pSelection);

	public HRESULT GetStart(uint32 ec, ITfRange** ppStart) mut => VT.[Friend]GetStart(&this, ec, ppStart);

	public HRESULT GetEnd(uint32 ec, ITfRange** ppEnd) mut => VT.[Friend]GetEnd(&this, ec, ppEnd);

	public HRESULT GetActiveView(ITfContextView** ppView) mut => VT.[Friend]GetActiveView(&this, ppView);

	public HRESULT EnumViews(IEnumTfContextViews** ppEnum) mut => VT.[Friend]EnumViews(&this, ppEnum);

	public HRESULT GetStatus(TS_STATUS* pdcs) mut => VT.[Friend]GetStatus(&this, pdcs);

	public HRESULT GetProperty(in Guid guidProp, ITfProperty** ppProp) mut => VT.[Friend]GetProperty(&this, guidProp, ppProp);

	public HRESULT GetAppProperty(in Guid guidProp, ITfReadOnlyProperty** ppProp) mut => VT.[Friend]GetAppProperty(&this, guidProp, ppProp);

	public HRESULT TrackProperties(Guid** prgProp, uint32 cProp, Guid** prgAppProp, uint32 cAppProp, ITfReadOnlyProperty** ppProperty) mut => VT.[Friend]TrackProperties(&this, prgProp, cProp, prgAppProp, cAppProp, ppProperty);

	public HRESULT EnumProperties(IEnumTfProperties** ppEnum) mut => VT.[Friend]EnumProperties(&this, ppEnum);

	public HRESULT GetDocumentMgr(ITfDocumentMgr** ppDm) mut => VT.[Friend]GetDocumentMgr(&this, ppDm);

	public HRESULT CreateRangeBackup(uint32 ec, ITfRange* pRange, ITfRangeBackup** ppBackup) mut => VT.[Friend]CreateRangeBackup(&this, ec, pRange, ppBackup);
}

[CRepr]struct ITfQueryEmbedded : IUnknown
{
	public new const Guid IID = .(0x0fab9bdb, 0xd250, 0x4169, 0x84, 0xe5, 0x6b, 0xe1, 0x18, 0xfd, 0xd7, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) QueryInsertEmbedded;
	}


	public HRESULT QueryInsertEmbedded(in Guid pguidService, FORMATETC* pFormatEtc, BOOL* pfInsertable) mut => VT.[Friend]QueryInsertEmbedded(&this, pguidService, pFormatEtc, pfInsertable);
}

[CRepr]struct ITfInsertAtSelection : IUnknown
{
	public new const Guid IID = .(0x55ce16ba, 0x3014, 0x41c1, 0x9c, 0xeb, 0xfa, 0xde, 0x14, 0x46, 0xac, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, INSERT_TEXT_AT_SELECTION_FLAGS dwFlags, char16* pchText, int32 cch, ITfRange** ppRange) InsertTextAtSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 dwFlags, IDataObject* pDataObject, ITfRange** ppRange) InsertEmbeddedAtSelection;
	}


	public HRESULT InsertTextAtSelection(uint32 ec, INSERT_TEXT_AT_SELECTION_FLAGS dwFlags, char16* pchText, int32 cch, ITfRange** ppRange) mut => VT.[Friend]InsertTextAtSelection(&this, ec, dwFlags, pchText, cch, ppRange);

	public HRESULT InsertEmbeddedAtSelection(uint32 ec, uint32 dwFlags, IDataObject* pDataObject, ITfRange** ppRange) mut => VT.[Friend]InsertEmbeddedAtSelection(&this, ec, dwFlags, pDataObject, ppRange);
}

[CRepr]struct ITfCleanupContextSink : IUnknown
{
	public new const Guid IID = .(0x01689689, 0x7acb, 0x4e9b, 0xab, 0x7c, 0x7e, 0xa4, 0x6b, 0x12, 0xb5, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ecWrite, ITfContext* pic) OnCleanupContext;
	}


	public HRESULT OnCleanupContext(uint32 ecWrite, ITfContext* pic) mut => VT.[Friend]OnCleanupContext(&this, ecWrite, pic);
}

[CRepr]struct ITfCleanupContextDurationSink : IUnknown
{
	public new const Guid IID = .(0x45c35144, 0x154e, 0x4797, 0xbe, 0xd8, 0xd3, 0x3a, 0xe7, 0xbf, 0x87, 0x94);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnStartCleanupContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnEndCleanupContext;
	}


	public HRESULT OnStartCleanupContext() mut => VT.[Friend]OnStartCleanupContext(&this);

	public HRESULT OnEndCleanupContext() mut => VT.[Friend]OnEndCleanupContext(&this);
}

[CRepr]struct ITfReadOnlyProperty : IUnknown
{
	public new const Guid IID = .(0x17d49a3d, 0xf8b8, 0x4b2f, 0xb2, 0x54, 0x52, 0x31, 0x9d, 0xd6, 0x4c, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, IEnumTfRanges** ppEnum, ITfRange* pTargetRange) EnumRanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, VARIANT* pvarValue) GetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext** ppContext) GetContext;
	}


	public HRESULT GetType(Guid* pguid) mut => VT.[Friend]COM_GetType(&this, pguid);

	public HRESULT EnumRanges(uint32 ec, IEnumTfRanges** ppEnum, ITfRange* pTargetRange) mut => VT.[Friend]EnumRanges(&this, ec, ppEnum, pTargetRange);

	public HRESULT GetValue(uint32 ec, ITfRange* pRange, VARIANT* pvarValue) mut => VT.[Friend]GetValue(&this, ec, pRange, pvarValue);

	public HRESULT GetContext(ITfContext** ppContext) mut => VT.[Friend]GetContext(&this, ppContext);
}

[CRepr]struct IEnumTfPropertyValue : IUnknown
{
	public new const Guid IID = .(0x8ed8981b, 0x7c10, 0x4d7d, 0x9f, 0xb3, 0xab, 0x72, 0xe9, 0xc7, 0x5f, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfPropertyValue** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TF_PROPERTYVAL* rgValues, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfPropertyValue** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, TF_PROPERTYVAL* rgValues, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgValues, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfMouseTracker : IUnknown
{
	public new const Guid IID = .(0x09d146cd, 0xa544, 0x4132, 0x92, 0x5b, 0x7a, 0xfa, 0x8e, 0xf3, 0x22, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* range, ITfMouseSink* pSink, uint32* pdwCookie) AdviseMouseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnadviseMouseSink;
	}


	public HRESULT AdviseMouseSink(ITfRange* range, ITfMouseSink* pSink, uint32* pdwCookie) mut => VT.[Friend]AdviseMouseSink(&this, range, pSink, pdwCookie);

	public HRESULT UnadviseMouseSink(uint32 dwCookie) mut => VT.[Friend]UnadviseMouseSink(&this, dwCookie);
}

[CRepr]struct ITfMouseTrackerACP : IUnknown
{
	public new const Guid IID = .(0x3bdd78e2, 0xc16e, 0x47fd, 0xb8, 0x83, 0xce, 0x6f, 0xac, 0xc1, 0xa2, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRangeACP* range, ITfMouseSink* pSink, uint32* pdwCookie) AdviseMouseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnadviseMouseSink;
	}


	public HRESULT AdviseMouseSink(ITfRangeACP* range, ITfMouseSink* pSink, uint32* pdwCookie) mut => VT.[Friend]AdviseMouseSink(&this, range, pSink, pdwCookie);

	public HRESULT UnadviseMouseSink(uint32 dwCookie) mut => VT.[Friend]UnadviseMouseSink(&this, dwCookie);
}

[CRepr]struct ITfMouseSink : IUnknown
{
	public new const Guid IID = .(0xa1adaaa2, 0x3a24, 0x449d, 0xac, 0x96, 0x51, 0x83, 0xe7, 0xf5, 0xc2, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uEdge, uint32 uQuadrant, uint32 dwBtnStatus, BOOL* pfEaten) OnMouseEvent;
	}


	public HRESULT OnMouseEvent(uint32 uEdge, uint32 uQuadrant, uint32 dwBtnStatus, BOOL* pfEaten) mut => VT.[Friend]OnMouseEvent(&this, uEdge, uQuadrant, dwBtnStatus, pfEaten);
}

[CRepr]struct ITfEditRecord : IUnknown
{
	public new const Guid IID = .(0x42d4d099, 0x7c1a, 0x4a89, 0xb8, 0x36, 0x6c, 0x6f, 0x22, 0x16, 0x0d, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfChanged) GetSelectionStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GET_TEXT_AND_PROPERTY_UPDATES_FLAGS dwFlags, Guid** prgProperties, uint32 cProperties, IEnumTfRanges** ppEnum) GetTextAndPropertyUpdates;
	}


	public HRESULT GetSelectionStatus(BOOL* pfChanged) mut => VT.[Friend]GetSelectionStatus(&this, pfChanged);

	public HRESULT GetTextAndPropertyUpdates(GET_TEXT_AND_PROPERTY_UPDATES_FLAGS dwFlags, Guid** prgProperties, uint32 cProperties, IEnumTfRanges** ppEnum) mut => VT.[Friend]GetTextAndPropertyUpdates(&this, dwFlags, prgProperties, cProperties, ppEnum);
}

[CRepr]struct ITfTextEditSink : IUnknown
{
	public new const Guid IID = .(0x8127d409, 0xccd3, 0x4683, 0x96, 0x7a, 0xb4, 0x3d, 0x5b, 0x48, 0x2b, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, uint32 ecReadOnly, ITfEditRecord* pEditRecord) OnEndEdit;
	}


	public HRESULT OnEndEdit(ITfContext* pic, uint32 ecReadOnly, ITfEditRecord* pEditRecord) mut => VT.[Friend]OnEndEdit(&this, pic, ecReadOnly, pEditRecord);
}

[CRepr]struct ITfTextLayoutSink : IUnknown
{
	public new const Guid IID = .(0x2af2d06a, 0xdd5b, 0x4927, 0xa0, 0xb4, 0x54, 0xf1, 0x9c, 0x91, 0xfa, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, TfLayoutCode lcode, ITfContextView* pView) OnLayoutChange;
	}


	public HRESULT OnLayoutChange(ITfContext* pic, TfLayoutCode lcode, ITfContextView* pView) mut => VT.[Friend]OnLayoutChange(&this, pic, lcode, pView);
}

[CRepr]struct ITfStatusSink : IUnknown
{
	public new const Guid IID = .(0x6b7d8d73, 0xb267, 0x4f69, 0xb3, 0x2e, 0x1c, 0xa3, 0x21, 0xce, 0x4f, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, uint32 dwFlags) OnStatusChange;
	}


	public HRESULT OnStatusChange(ITfContext* pic, uint32 dwFlags) mut => VT.[Friend]OnStatusChange(&this, pic, dwFlags);
}

[CRepr]struct ITfEditTransactionSink : IUnknown
{
	public new const Guid IID = .(0x708fbf70, 0xb520, 0x416b, 0xb0, 0x6c, 0x2c, 0x41, 0xab, 0x44, 0xf8, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic) OnStartEditTransaction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic) OnEndEditTransaction;
	}


	public HRESULT OnStartEditTransaction(ITfContext* pic) mut => VT.[Friend]OnStartEditTransaction(&this, pic);

	public HRESULT OnEndEditTransaction(ITfContext* pic) mut => VT.[Friend]OnEndEditTransaction(&this, pic);
}

[CRepr]struct ITfContextOwner : IUnknown
{
	public new const Guid IID = .(0xaa80e80c, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ptScreen, uint32 dwFlags, int32* pacp) GetACPFromPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) GetTextExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) GetScreenExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TS_STATUS* pdcs) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetWnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidAttribute, VARIANT* pvarValue) GetAttribute;
	}


	public HRESULT GetACPFromPoint(POINT* ptScreen, uint32 dwFlags, int32* pacp) mut => VT.[Friend]GetACPFromPoint(&this, ptScreen, dwFlags, pacp);

	public HRESULT GetTextExt(int32 acpStart, int32 acpEnd, RECT* prc, BOOL* pfClipped) mut => VT.[Friend]GetTextExt(&this, acpStart, acpEnd, prc, pfClipped);

	public HRESULT GetScreenExt(RECT* prc) mut => VT.[Friend]GetScreenExt(&this, prc);

	public HRESULT GetStatus(TS_STATUS* pdcs) mut => VT.[Friend]GetStatus(&this, pdcs);

	public HRESULT GetWnd(HWND* phwnd) mut => VT.[Friend]GetWnd(&this, phwnd);

	public HRESULT GetAttribute(in Guid rguidAttribute, VARIANT* pvarValue) mut => VT.[Friend]GetAttribute(&this, rguidAttribute, pvarValue);
}

[CRepr]struct ITfContextOwnerServices : IUnknown
{
	public new const Guid IID = .(0xb23eb630, 0x3e1c, 0x11d3, 0xa7, 0x45, 0x00, 0x50, 0x04, 0x0a, 0xb4, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnLayoutChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) OnStatusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidAttribute) OnAttributeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp, ITfRange* pRange, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream, ITfPersistentPropertyLoaderACP* pLoader) Unserialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp) ForceLoadProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, ITfRangeACP** ppRange) CreateRange;
	}


	public HRESULT OnLayoutChange() mut => VT.[Friend]OnLayoutChange(&this);

	public HRESULT OnStatusChange(uint32 dwFlags) mut => VT.[Friend]OnStatusChange(&this, dwFlags);

	public HRESULT OnAttributeChange(in Guid rguidAttribute) mut => VT.[Friend]OnAttributeChange(&this, rguidAttribute);

	public HRESULT Serialize(ITfProperty* pProp, ITfRange* pRange, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream) mut => VT.[Friend]Serialize(&this, pProp, pRange, pHdr, pStream);

	public HRESULT Unserialize(ITfProperty* pProp, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream, ITfPersistentPropertyLoaderACP* pLoader) mut => VT.[Friend]Unserialize(&this, pProp, pHdr, pStream, pLoader);

	public HRESULT ForceLoadProperty(ITfProperty* pProp) mut => VT.[Friend]ForceLoadProperty(&this, pProp);

	public HRESULT CreateRange(int32 acpStart, int32 acpEnd, ITfRangeACP** ppRange) mut => VT.[Friend]CreateRange(&this, acpStart, acpEnd, ppRange);
}

[CRepr]struct ITfContextKeyEventSink : IUnknown
{
	public new const Guid IID = .(0x0552ba5d, 0xc835, 0x4934, 0xbf, 0x50, 0x84, 0x6a, 0xaa, 0x67, 0x43, 0x2f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnKeyUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnTestKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnTestKeyUp;
	}


	public HRESULT OnKeyDown(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnKeyDown(&this, wParam, lParam, pfEaten);

	public HRESULT OnKeyUp(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnKeyUp(&this, wParam, lParam, pfEaten);

	public HRESULT OnTestKeyDown(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnTestKeyDown(&this, wParam, lParam, pfEaten);

	public HRESULT OnTestKeyUp(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnTestKeyUp(&this, wParam, lParam, pfEaten);
}

[CRepr]struct ITfEditSession : IUnknown
{
	public new const Guid IID = .(0xaa80e803, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec) DoEditSession;
	}


	public HRESULT DoEditSession(uint32 ec) mut => VT.[Friend]DoEditSession(&this, ec);
}

[CRepr]struct ITfRange : IUnknown
{
	public new const Guid IID = .(0xaa80e7ff, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 dwFlags, char16* pchText, uint32 cchMax, uint32* pcch) GetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 dwFlags, char16* pchText, int32 cch) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, IDataObject** ppDataObject) GetFormattedText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, in Guid rguidService, in Guid riid, IUnknown** ppunk) GetEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 dwFlags, IDataObject* pDataObject) InsertEmbedded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, int32 cchReq, int32* pcch, TF_HALTCOND* pHalt) ShiftStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, int32 cchReq, int32* pcch, TF_HALTCOND* pHalt) ShiftEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, TfAnchor aPos) ShiftStartToRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, TfAnchor aPos) ShiftEndToRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, TfShiftDir dir, BOOL* pfNoRegion) ShiftStartRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, TfShiftDir dir, BOOL* pfNoRegion) ShiftEndRegion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, BOOL* pfEmpty) IsEmpty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, TfAnchor aPos) Collapse;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pWith, TfAnchor aPos, BOOL* pfEqual) IsEqualStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pWith, TfAnchor aPos, BOOL* pfEqual) IsEqualEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pWith, TfAnchor aPos, int32* plResult) CompareStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pWith, TfAnchor aPos, int32* plResult) CompareEnd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, uint32 cchInsert, BOOL* pfInsertOk) AdjustForInsert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfGravity* pgStart, TfGravity* pgEnd) GetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, TfGravity gStart, TfGravity gEnd) SetGravity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange** ppClone) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext** ppContext) GetContext;
	}


	public HRESULT GetText(uint32 ec, uint32 dwFlags, char16* pchText, uint32 cchMax, uint32* pcch) mut => VT.[Friend]GetText(&this, ec, dwFlags, pchText, cchMax, pcch);

	public HRESULT SetText(uint32 ec, uint32 dwFlags, char16* pchText, int32 cch) mut => VT.[Friend]SetText(&this, ec, dwFlags, pchText, cch);

	public HRESULT GetFormattedText(uint32 ec, IDataObject** ppDataObject) mut => VT.[Friend]GetFormattedText(&this, ec, ppDataObject);

	public HRESULT GetEmbedded(uint32 ec, in Guid rguidService, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetEmbedded(&this, ec, rguidService, riid, ppunk);

	public HRESULT InsertEmbedded(uint32 ec, uint32 dwFlags, IDataObject* pDataObject) mut => VT.[Friend]InsertEmbedded(&this, ec, dwFlags, pDataObject);

	public HRESULT ShiftStart(uint32 ec, int32 cchReq, int32* pcch, TF_HALTCOND* pHalt) mut => VT.[Friend]ShiftStart(&this, ec, cchReq, pcch, pHalt);

	public HRESULT ShiftEnd(uint32 ec, int32 cchReq, int32* pcch, TF_HALTCOND* pHalt) mut => VT.[Friend]ShiftEnd(&this, ec, cchReq, pcch, pHalt);

	public HRESULT ShiftStartToRange(uint32 ec, ITfRange* pRange, TfAnchor aPos) mut => VT.[Friend]ShiftStartToRange(&this, ec, pRange, aPos);

	public HRESULT ShiftEndToRange(uint32 ec, ITfRange* pRange, TfAnchor aPos) mut => VT.[Friend]ShiftEndToRange(&this, ec, pRange, aPos);

	public HRESULT ShiftStartRegion(uint32 ec, TfShiftDir dir, BOOL* pfNoRegion) mut => VT.[Friend]ShiftStartRegion(&this, ec, dir, pfNoRegion);

	public HRESULT ShiftEndRegion(uint32 ec, TfShiftDir dir, BOOL* pfNoRegion) mut => VT.[Friend]ShiftEndRegion(&this, ec, dir, pfNoRegion);

	public HRESULT IsEmpty(uint32 ec, BOOL* pfEmpty) mut => VT.[Friend]IsEmpty(&this, ec, pfEmpty);

	public HRESULT Collapse(uint32 ec, TfAnchor aPos) mut => VT.[Friend]Collapse(&this, ec, aPos);

	public HRESULT IsEqualStart(uint32 ec, ITfRange* pWith, TfAnchor aPos, BOOL* pfEqual) mut => VT.[Friend]IsEqualStart(&this, ec, pWith, aPos, pfEqual);

	public HRESULT IsEqualEnd(uint32 ec, ITfRange* pWith, TfAnchor aPos, BOOL* pfEqual) mut => VT.[Friend]IsEqualEnd(&this, ec, pWith, aPos, pfEqual);

	public HRESULT CompareStart(uint32 ec, ITfRange* pWith, TfAnchor aPos, int32* plResult) mut => VT.[Friend]CompareStart(&this, ec, pWith, aPos, plResult);

	public HRESULT CompareEnd(uint32 ec, ITfRange* pWith, TfAnchor aPos, int32* plResult) mut => VT.[Friend]CompareEnd(&this, ec, pWith, aPos, plResult);

	public HRESULT AdjustForInsert(uint32 ec, uint32 cchInsert, BOOL* pfInsertOk) mut => VT.[Friend]AdjustForInsert(&this, ec, cchInsert, pfInsertOk);

	public HRESULT GetGravity(TfGravity* pgStart, TfGravity* pgEnd) mut => VT.[Friend]GetGravity(&this, pgStart, pgEnd);

	public HRESULT SetGravity(uint32 ec, TfGravity gStart, TfGravity gEnd) mut => VT.[Friend]SetGravity(&this, ec, gStart, gEnd);

	public HRESULT Clone(ITfRange** ppClone) mut => VT.[Friend]Clone(&this, ppClone);

	public HRESULT GetContext(ITfContext** ppContext) mut => VT.[Friend]GetContext(&this, ppContext);
}

[CRepr]struct ITfRangeACP : ITfRange
{
	public new const Guid IID = .(0x057a6296, 0x029b, 0x4154, 0xb7, 0x9a, 0x0d, 0x46, 0x1d, 0x4e, 0xa9, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfRange.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pacpAnchor, int32* pcch) GetExtent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpAnchor, int32 cch) SetExtent;
	}


	public HRESULT GetExtent(int32* pacpAnchor, int32* pcch) mut => VT.[Friend]GetExtent(&this, pacpAnchor, pcch);

	public HRESULT SetExtent(int32 acpAnchor, int32 cch) mut => VT.[Friend]SetExtent(&this, acpAnchor, cch);
}

[CRepr]struct ITextStoreACPServices : IUnknown
{
	public new const Guid IID = .(0xaa80e901, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp, ITfRange* pRange, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream) Serialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream, ITfPersistentPropertyLoaderACP* pLoader) Unserialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfProperty* pProp) ForceLoadProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, ITfRangeACP** ppRange) CreateRange;
	}


	public HRESULT Serialize(ITfProperty* pProp, ITfRange* pRange, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream) mut => VT.[Friend]Serialize(&this, pProp, pRange, pHdr, pStream);

	public HRESULT Unserialize(ITfProperty* pProp, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream* pStream, ITfPersistentPropertyLoaderACP* pLoader) mut => VT.[Friend]Unserialize(&this, pProp, pHdr, pStream, pLoader);

	public HRESULT ForceLoadProperty(ITfProperty* pProp) mut => VT.[Friend]ForceLoadProperty(&this, pProp);

	public HRESULT CreateRange(int32 acpStart, int32 acpEnd, ITfRangeACP** ppRange) mut => VT.[Friend]CreateRange(&this, acpStart, acpEnd, ppRange);
}

[CRepr]struct ITfRangeBackup : IUnknown
{
	public new const Guid IID = .(0x463a506d, 0x6992, 0x49d2, 0x9b, 0x88, 0x93, 0xd5, 0x5e, 0x70, 0xbb, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange) Restore;
	}


	public HRESULT Restore(uint32 ec, ITfRange* pRange) mut => VT.[Friend]Restore(&this, ec, pRange);
}

[CRepr]struct ITfPropertyStore : IUnknown
{
	public new const Guid IID = .(0x6834b120, 0x88cb, 0x11d2, 0xbf, 0x45, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwReserved) GetDataType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, ITfRange* pRangeNew, BOOL* pfAccept) OnTextUpdated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRangeNew, BOOL* pfFree) Shrink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRangeThis, ITfRange* pRangeNew, ITfPropertyStore** ppPropStore) Divide;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfPropertyStore** pPropStore) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetPropertyRangeCreator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, uint32* pcb) Serialize;
	}


	public HRESULT GetType(Guid* pguid) mut => VT.[Friend]COM_GetType(&this, pguid);

	public HRESULT GetDataType(uint32* pdwReserved) mut => VT.[Friend]GetDataType(&this, pdwReserved);

	public HRESULT GetData(VARIANT* pvarValue) mut => VT.[Friend]GetData(&this, pvarValue);

	public HRESULT OnTextUpdated(uint32 dwFlags, ITfRange* pRangeNew, BOOL* pfAccept) mut => VT.[Friend]OnTextUpdated(&this, dwFlags, pRangeNew, pfAccept);

	public HRESULT Shrink(ITfRange* pRangeNew, BOOL* pfFree) mut => VT.[Friend]Shrink(&this, pRangeNew, pfFree);

	public HRESULT Divide(ITfRange* pRangeThis, ITfRange* pRangeNew, ITfPropertyStore** ppPropStore) mut => VT.[Friend]Divide(&this, pRangeThis, pRangeNew, ppPropStore);

	public HRESULT Clone(ITfPropertyStore** pPropStore) mut => VT.[Friend]Clone(&this, pPropStore);

	public HRESULT GetPropertyRangeCreator(Guid* pclsid) mut => VT.[Friend]GetPropertyRangeCreator(&this, pclsid);

	public HRESULT Serialize(IStream* pStream, uint32* pcb) mut => VT.[Friend]Serialize(&this, pStream, pcb);
}

[CRepr]struct IEnumTfRanges : IUnknown
{
	public new const Guid IID = .(0xf99d3f40, 0x8e32, 0x11d2, 0xbf, 0x46, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfRanges** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfRange** ppRange, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfRanges** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfRange** ppRange, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, ppRange, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfCreatePropertyStore : IUnknown
{
	public new const Guid IID = .(0x2463fbf0, 0xb0af, 0x11d2, 0xaf, 0xc5, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProp, ITfRange* pRange, ITfPropertyStore* pPropStore, BOOL* pfSerializable) IsStoreSerializable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProp, ITfRange* pRange, uint32 cb, IStream* pStream, ITfPropertyStore** ppStore) CreatePropertyStore;
	}


	public HRESULT IsStoreSerializable(in Guid guidProp, ITfRange* pRange, ITfPropertyStore* pPropStore, BOOL* pfSerializable) mut => VT.[Friend]IsStoreSerializable(&this, guidProp, pRange, pPropStore, pfSerializable);

	public HRESULT CreatePropertyStore(in Guid guidProp, ITfRange* pRange, uint32 cb, IStream* pStream, ITfPropertyStore** ppStore) mut => VT.[Friend]CreatePropertyStore(&this, guidProp, pRange, cb, pStream, ppStore);
}

[CRepr]struct ITfPersistentPropertyLoaderACP : IUnknown
{
	public new const Guid IID = .(0x4ef89150, 0x0807, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream** ppStream) LoadProperty;
	}


	public HRESULT LoadProperty(TF_PERSISTENT_PROPERTY_HEADER_ACP* pHdr, IStream** ppStream) mut => VT.[Friend]LoadProperty(&this, pHdr, ppStream);
}

[CRepr]struct ITfProperty : ITfReadOnlyProperty
{
	public new const Guid IID = .(0xe2449660, 0x9542, 0x11d2, 0xbf, 0x46, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfReadOnlyProperty.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, ITfRange** ppRange, TfAnchor aPos) FindRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, ITfPropertyStore* pPropStore) SetValueStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange, VARIANT* pvarValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ec, ITfRange* pRange) Clear;
	}


	public HRESULT FindRange(uint32 ec, ITfRange* pRange, ITfRange** ppRange, TfAnchor aPos) mut => VT.[Friend]FindRange(&this, ec, pRange, ppRange, aPos);

	public HRESULT SetValueStore(uint32 ec, ITfRange* pRange, ITfPropertyStore* pPropStore) mut => VT.[Friend]SetValueStore(&this, ec, pRange, pPropStore);

	public HRESULT SetValue(uint32 ec, ITfRange* pRange, VARIANT* pvarValue) mut => VT.[Friend]SetValue(&this, ec, pRange, pvarValue);

	public HRESULT Clear(uint32 ec, ITfRange* pRange) mut => VT.[Friend]Clear(&this, ec, pRange);
}

[CRepr]struct IEnumTfProperties : IUnknown
{
	public new const Guid IID = .(0x19188cb0, 0xaca9, 0x11d2, 0xaf, 0xc5, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfProperties** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfProperty** ppProp, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfProperties** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfProperty** ppProp, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, ppProp, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfCompartment : IUnknown
{
	public new const Guid IID = .(0xbb08f7a9, 0x607a, 0x4384, 0x86, 0x23, 0x05, 0x68, 0x92, 0xb6, 0x43, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, VARIANT* pvarValue) SetValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarValue) GetValue;
	}


	public HRESULT SetValue(uint32 tid, VARIANT* pvarValue) mut => VT.[Friend]SetValue(&this, tid, pvarValue);

	public HRESULT GetValue(VARIANT* pvarValue) mut => VT.[Friend]GetValue(&this, pvarValue);
}

[CRepr]struct ITfCompartmentEventSink : IUnknown
{
	public new const Guid IID = .(0x743abd5f, 0xf26d, 0x48df, 0x8c, 0xc5, 0x23, 0x84, 0x92, 0x41, 0x9b, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid) OnChange;
	}


	public HRESULT OnChange(in Guid rguid) mut => VT.[Friend]OnChange(&this, rguid);
}

[CRepr]struct ITfCompartmentMgr : IUnknown
{
	public new const Guid IID = .(0x7dcf57ac, 0x18ad, 0x438b, 0x82, 0x4d, 0x97, 0x9b, 0xff, 0xb7, 0x4b, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, ITfCompartment** ppcomp) GetCompartment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, in Guid rguid) ClearCompartment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumGUID** ppEnum) EnumCompartments;
	}


	public HRESULT GetCompartment(in Guid rguid, ITfCompartment** ppcomp) mut => VT.[Friend]GetCompartment(&this, rguid, ppcomp);

	public HRESULT ClearCompartment(uint32 tid, in Guid rguid) mut => VT.[Friend]ClearCompartment(&this, tid, rguid);

	public HRESULT EnumCompartments(IEnumGUID** ppEnum) mut => VT.[Friend]EnumCompartments(&this, ppEnum);
}

[CRepr]struct ITfFunction : IUnknown
{
	public new const Guid IID = .(0xdb593490, 0x098f, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) GetDisplayName;
	}


	public HRESULT GetDisplayName(BSTR* pbstrName) mut => VT.[Friend]GetDisplayName(&this, pbstrName);
}

[CRepr]struct ITfFunctionProvider : IUnknown
{
	public new const Guid IID = .(0x101d6610, 0x0990, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDesc) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, in Guid riid, IUnknown** ppunk) GetFunction;
	}


	public HRESULT GetType(Guid* pguid) mut => VT.[Friend]COM_GetType(&this, pguid);

	public HRESULT GetDescription(BSTR* pbstrDesc) mut => VT.[Friend]GetDescription(&this, pbstrDesc);

	public HRESULT GetFunction(in Guid rguid, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetFunction(&this, rguid, riid, ppunk);
}

[CRepr]struct IEnumTfFunctionProviders : IUnknown
{
	public new const Guid IID = .(0xe4b24db0, 0x0990, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfFunctionProviders** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfFunctionProvider** ppCmdobj, uint32* pcFetch) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfFunctionProviders** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfFunctionProvider** ppCmdobj, uint32* pcFetch) mut => VT.[Friend]Next(&this, ulCount, ppCmdobj, pcFetch);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfInputProcessorProfiles : IUnknown
{
	public new const Guid IID = .(0x1f02b6c5, 0x7842, 0x4ee6, 0x8a, 0x0b, 0x9a, 0x24, 0x18, 0x3a, 0x95, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid) Unregister;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchDesc, uint32 cchDesc, char16* pchIconFile, uint32 cchFile, uint32 uIconIndex) AddLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile) RemoveLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumGUID** ppEnum) EnumInputProcessorInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, in Guid catid, Guid* pclsid, Guid* pguidProfile) GetDefaultLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, in Guid rclsid, in Guid guidProfiles) SetDefaultLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfiles) ActivateLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16* plangid, Guid* pguidProfile) GetActiveLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, BSTR* pbstrProfile) GetLanguageProfileDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* plangid) GetCurrentLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid) ChangeCurrentLanguage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** ppLangId, uint32* pulCount) GetLanguageList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, IEnumTfLanguageProfiles** ppEnum) EnumLanguageProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL fEnable) EnableLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL* pfEnable) IsEnabledLanguageProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL fEnable) EnableLanguageProfileByDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, HKL hKL) SubstituteKeyboardLayout;
	}


	public HRESULT Register(in Guid rclsid) mut => VT.[Friend]Register(&this, rclsid);

	public HRESULT Unregister(in Guid rclsid) mut => VT.[Friend]Unregister(&this, rclsid);

	public HRESULT AddLanguageProfile(in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchDesc, uint32 cchDesc, char16* pchIconFile, uint32 cchFile, uint32 uIconIndex) mut => VT.[Friend]AddLanguageProfile(&this, rclsid, langid, guidProfile, pchDesc, cchDesc, pchIconFile, cchFile, uIconIndex);

	public HRESULT RemoveLanguageProfile(in Guid rclsid, uint16 langid, in Guid guidProfile) mut => VT.[Friend]RemoveLanguageProfile(&this, rclsid, langid, guidProfile);

	public HRESULT EnumInputProcessorInfo(IEnumGUID** ppEnum) mut => VT.[Friend]EnumInputProcessorInfo(&this, ppEnum);

	public HRESULT GetDefaultLanguageProfile(uint16 langid, in Guid catid, Guid* pclsid, Guid* pguidProfile) mut => VT.[Friend]GetDefaultLanguageProfile(&this, langid, catid, pclsid, pguidProfile);

	public HRESULT SetDefaultLanguageProfile(uint16 langid, in Guid rclsid, in Guid guidProfiles) mut => VT.[Friend]SetDefaultLanguageProfile(&this, langid, rclsid, guidProfiles);

	public HRESULT ActivateLanguageProfile(in Guid rclsid, uint16 langid, in Guid guidProfiles) mut => VT.[Friend]ActivateLanguageProfile(&this, rclsid, langid, guidProfiles);

	public HRESULT GetActiveLanguageProfile(in Guid rclsid, uint16* plangid, Guid* pguidProfile) mut => VT.[Friend]GetActiveLanguageProfile(&this, rclsid, plangid, pguidProfile);

	public HRESULT GetLanguageProfileDescription(in Guid rclsid, uint16 langid, in Guid guidProfile, BSTR* pbstrProfile) mut => VT.[Friend]GetLanguageProfileDescription(&this, rclsid, langid, guidProfile, pbstrProfile);

	public HRESULT GetCurrentLanguage(uint16* plangid) mut => VT.[Friend]GetCurrentLanguage(&this, plangid);

	public HRESULT ChangeCurrentLanguage(uint16 langid) mut => VT.[Friend]ChangeCurrentLanguage(&this, langid);

	public HRESULT GetLanguageList(uint16** ppLangId, uint32* pulCount) mut => VT.[Friend]GetLanguageList(&this, ppLangId, pulCount);

	public HRESULT EnumLanguageProfiles(uint16 langid, IEnumTfLanguageProfiles** ppEnum) mut => VT.[Friend]EnumLanguageProfiles(&this, langid, ppEnum);

	public HRESULT EnableLanguageProfile(in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL fEnable) mut => VT.[Friend]EnableLanguageProfile(&this, rclsid, langid, guidProfile, fEnable);

	public HRESULT IsEnabledLanguageProfile(in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL* pfEnable) mut => VT.[Friend]IsEnabledLanguageProfile(&this, rclsid, langid, guidProfile, pfEnable);

	public HRESULT EnableLanguageProfileByDefault(in Guid rclsid, uint16 langid, in Guid guidProfile, BOOL fEnable) mut => VT.[Friend]EnableLanguageProfileByDefault(&this, rclsid, langid, guidProfile, fEnable);

	public HRESULT SubstituteKeyboardLayout(in Guid rclsid, uint16 langid, in Guid guidProfile, HKL hKL) mut => VT.[Friend]SubstituteKeyboardLayout(&this, rclsid, langid, guidProfile, hKL);
}

[CRepr]struct ITfInputProcessorProfilesEx : ITfInputProcessorProfiles
{
	public new const Guid IID = .(0x892f230f, 0xfe00, 0x4a41, 0xa9, 0x8e, 0xfc, 0xd6, 0xde, 0x0d, 0x35, 0xef);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfInputProcessorProfiles.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchFile, uint32 cchFile, uint32 uResId) SetLanguageProfileDisplayName;
	}


	public HRESULT SetLanguageProfileDisplayName(in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchFile, uint32 cchFile, uint32 uResId) mut => VT.[Friend]SetLanguageProfileDisplayName(&this, rclsid, langid, guidProfile, pchFile, cchFile, uResId);
}

[CRepr]struct ITfInputProcessorProfileSubstituteLayout : IUnknown
{
	public new const Guid IID = .(0x4fd67194, 0x1002, 0x4513, 0xbf, 0xf2, 0xc0, 0xdd, 0xf6, 0x25, 0x85, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, HKL* phKL) GetSubstituteKeyboardLayout;
	}


	public HRESULT GetSubstituteKeyboardLayout(in Guid rclsid, uint16 langid, in Guid guidProfile, HKL* phKL) mut => VT.[Friend]GetSubstituteKeyboardLayout(&this, rclsid, langid, guidProfile, phKL);
}

[CRepr]struct ITfActiveLanguageProfileNotifySink : IUnknown
{
	public new const Guid IID = .(0xb246cb75, 0xa93e, 0x4652, 0xbf, 0x8c, 0xb3, 0xfe, 0x0c, 0xfd, 0x7e, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid, in Guid guidProfile, BOOL fActivated) OnActivated;
	}


	public HRESULT OnActivated(in Guid clsid, in Guid guidProfile, BOOL fActivated) mut => VT.[Friend]OnActivated(&this, clsid, guidProfile, fActivated);
}

[CRepr]struct IEnumTfLanguageProfiles : IUnknown
{
	public new const Guid IID = .(0x3d61bf11, 0xac5f, 0x42c8, 0xa4, 0xcb, 0x93, 0x1b, 0xcc, 0x28, 0xc7, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfLanguageProfiles** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TF_LANGUAGEPROFILE* pProfile, uint32* pcFetch) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfLanguageProfiles** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, TF_LANGUAGEPROFILE* pProfile, uint32* pcFetch) mut => VT.[Friend]Next(&this, ulCount, pProfile, pcFetch);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfLanguageProfileNotifySink : IUnknown
{
	public new const Guid IID = .(0x43c9fe15, 0xf494, 0x4c17, 0x9d, 0xe2, 0xb8, 0xa4, 0xac, 0x35, 0x0a, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, BOOL* pfAccept) OnLanguageChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnLanguageChanged;
	}


	public HRESULT OnLanguageChange(uint16 langid, BOOL* pfAccept) mut => VT.[Friend]OnLanguageChange(&this, langid, pfAccept);

	public HRESULT OnLanguageChanged() mut => VT.[Friend]OnLanguageChanged(&this);
}

[CRepr]struct ITfInputProcessorProfileMgr : IUnknown
{
	public new const Guid IID = .(0x71c6e74c, 0x0f28, 0x11d8, 0xa8, 0x2a, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, uint32 dwFlags) ActivateProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, uint32 dwFlags) DeactivateProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, TF_INPUTPROCESSORPROFILE* pProfile) GetProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, IEnumTfInputProcessorProfiles** ppEnum) EnumProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 dwFlags) ReleaseInputProcessor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchDesc, uint32 cchDesc, char16* pchIconFile, uint32 cchFile, uint32 uIconIndex, HKL hklsubstitute, uint32 dwPreferredLayout, BOOL bEnabledByDefault, uint32 dwFlags) RegisterProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint16 langid, in Guid guidProfile, uint32 dwFlags) UnregisterProfile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid catid, TF_INPUTPROCESSORPROFILE* pProfile) GetActiveProfile;
	}


	public HRESULT ActivateProfile(uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, uint32 dwFlags) mut => VT.[Friend]ActivateProfile(&this, dwProfileType, langid, clsid, guidProfile, hkl, dwFlags);

	public HRESULT DeactivateProfile(uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, uint32 dwFlags) mut => VT.[Friend]DeactivateProfile(&this, dwProfileType, langid, clsid, guidProfile, hkl, dwFlags);

	public HRESULT GetProfile(uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid guidProfile, HKL hkl, TF_INPUTPROCESSORPROFILE* pProfile) mut => VT.[Friend]GetProfile(&this, dwProfileType, langid, clsid, guidProfile, hkl, pProfile);

	public HRESULT EnumProfiles(uint16 langid, IEnumTfInputProcessorProfiles** ppEnum) mut => VT.[Friend]EnumProfiles(&this, langid, ppEnum);

	public HRESULT ReleaseInputProcessor(in Guid rclsid, uint32 dwFlags) mut => VT.[Friend]ReleaseInputProcessor(&this, rclsid, dwFlags);

	public HRESULT RegisterProfile(in Guid rclsid, uint16 langid, in Guid guidProfile, char16* pchDesc, uint32 cchDesc, char16* pchIconFile, uint32 cchFile, uint32 uIconIndex, HKL hklsubstitute, uint32 dwPreferredLayout, BOOL bEnabledByDefault, uint32 dwFlags) mut => VT.[Friend]RegisterProfile(&this, rclsid, langid, guidProfile, pchDesc, cchDesc, pchIconFile, cchFile, uIconIndex, hklsubstitute, dwPreferredLayout, bEnabledByDefault, dwFlags);

	public HRESULT UnregisterProfile(in Guid rclsid, uint16 langid, in Guid guidProfile, uint32 dwFlags) mut => VT.[Friend]UnregisterProfile(&this, rclsid, langid, guidProfile, dwFlags);

	public HRESULT GetActiveProfile(in Guid catid, TF_INPUTPROCESSORPROFILE* pProfile) mut => VT.[Friend]GetActiveProfile(&this, catid, pProfile);
}

[CRepr]struct IEnumTfInputProcessorProfiles : IUnknown
{
	public new const Guid IID = .(0x71c6e74d, 0x0f28, 0x11d8, 0xa8, 0x2a, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfInputProcessorProfiles** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TF_INPUTPROCESSORPROFILE* pProfile, uint32* pcFetch) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfInputProcessorProfiles** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, TF_INPUTPROCESSORPROFILE* pProfile, uint32* pcFetch) mut => VT.[Friend]Next(&this, ulCount, pProfile, pcFetch);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfInputProcessorProfileActivationSink : IUnknown
{
	public new const Guid IID = .(0x71c6e74e, 0x0f28, 0x11d8, 0xa8, 0x2a, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid catid, in Guid guidProfile, HKL hkl, uint32 dwFlags) OnActivated;
	}


	public HRESULT OnActivated(uint32 dwProfileType, uint16 langid, in Guid clsid, in Guid catid, in Guid guidProfile, HKL hkl, uint32 dwFlags) mut => VT.[Friend]OnActivated(&this, dwProfileType, langid, clsid, catid, guidProfile, hkl, dwFlags);
}

[CRepr]struct ITfKeystrokeMgr : IUnknown
{
	public new const Guid IID = .(0xaa80e7f0, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, ITfKeyEventSink* pSink, BOOL fForeground) AdviseKeyEventSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid) UnadviseKeyEventSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetForeground;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) TestKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) TestKeyUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) KeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) KeyUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, TF_PRESERVEDKEY* pprekey, Guid* pguid) GetPreservedKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, TF_PRESERVEDKEY* pprekey, BOOL* pfRegistered) IsPreservedKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, in Guid rguid, TF_PRESERVEDKEY* prekey, char16* pchDesc, uint32 cchDesc) PreserveKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, TF_PRESERVEDKEY* pprekey) UnpreserveKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, char16* pchDesc, uint32 cchDesc) SetPreservedKeyDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, BSTR* pbstrDesc) GetPreservedKeyDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, in Guid rguid, BOOL* pfEaten) SimulatePreservedKey;
	}


	public HRESULT AdviseKeyEventSink(uint32 tid, ITfKeyEventSink* pSink, BOOL fForeground) mut => VT.[Friend]AdviseKeyEventSink(&this, tid, pSink, fForeground);

	public HRESULT UnadviseKeyEventSink(uint32 tid) mut => VT.[Friend]UnadviseKeyEventSink(&this, tid);

	public HRESULT GetForeground(Guid* pclsid) mut => VT.[Friend]GetForeground(&this, pclsid);

	public HRESULT TestKeyDown(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]TestKeyDown(&this, wParam, lParam, pfEaten);

	public HRESULT TestKeyUp(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]TestKeyUp(&this, wParam, lParam, pfEaten);

	public HRESULT KeyDown(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]KeyDown(&this, wParam, lParam, pfEaten);

	public HRESULT KeyUp(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]KeyUp(&this, wParam, lParam, pfEaten);

	public HRESULT GetPreservedKey(ITfContext* pic, TF_PRESERVEDKEY* pprekey, Guid* pguid) mut => VT.[Friend]GetPreservedKey(&this, pic, pprekey, pguid);

	public HRESULT IsPreservedKey(in Guid rguid, TF_PRESERVEDKEY* pprekey, BOOL* pfRegistered) mut => VT.[Friend]IsPreservedKey(&this, rguid, pprekey, pfRegistered);

	public HRESULT PreserveKey(uint32 tid, in Guid rguid, TF_PRESERVEDKEY* prekey, char16* pchDesc, uint32 cchDesc) mut => VT.[Friend]PreserveKey(&this, tid, rguid, prekey, pchDesc, cchDesc);

	public HRESULT UnpreserveKey(in Guid rguid, TF_PRESERVEDKEY* pprekey) mut => VT.[Friend]UnpreserveKey(&this, rguid, pprekey);

	public HRESULT SetPreservedKeyDescription(in Guid rguid, char16* pchDesc, uint32 cchDesc) mut => VT.[Friend]SetPreservedKeyDescription(&this, rguid, pchDesc, cchDesc);

	public HRESULT GetPreservedKeyDescription(in Guid rguid, BSTR* pbstrDesc) mut => VT.[Friend]GetPreservedKeyDescription(&this, rguid, pbstrDesc);

	public HRESULT SimulatePreservedKey(ITfContext* pic, in Guid rguid, BOOL* pfEaten) mut => VT.[Friend]SimulatePreservedKey(&this, pic, rguid, pfEaten);
}

[CRepr]struct ITfKeyEventSink : IUnknown
{
	public new const Guid IID = .(0xaa80e7f5, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForeground) OnSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnTestKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnTestKeyUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnKeyUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, in Guid rguid, BOOL* pfEaten) OnPreservedKey;
	}


	public HRESULT OnSetFocus(BOOL fForeground) mut => VT.[Friend]OnSetFocus(&this, fForeground);

	public HRESULT OnTestKeyDown(ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnTestKeyDown(&this, pic, wParam, lParam, pfEaten);

	public HRESULT OnTestKeyUp(ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnTestKeyUp(&this, pic, wParam, lParam, pfEaten);

	public HRESULT OnKeyDown(ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnKeyDown(&this, pic, wParam, lParam, pfEaten);

	public HRESULT OnKeyUp(ITfContext* pic, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnKeyUp(&this, pic, wParam, lParam, pfEaten);

	public HRESULT OnPreservedKey(ITfContext* pic, in Guid rguid, BOOL* pfEaten) mut => VT.[Friend]OnPreservedKey(&this, pic, rguid, pfEaten);
}

[CRepr]struct ITfKeyTraceEventSink : IUnknown
{
	public new const Guid IID = .(0x1cd4c13b, 0x1c36, 0x4191, 0xa7, 0x0a, 0x7f, 0x3e, 0x61, 0x1f, 0x36, 0x7d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam) OnKeyTraceDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam) OnKeyTraceUp;
	}


	public HRESULT OnKeyTraceDown(WPARAM wParam, LPARAM lParam) mut => VT.[Friend]OnKeyTraceDown(&this, wParam, lParam);

	public HRESULT OnKeyTraceUp(WPARAM wParam, LPARAM lParam) mut => VT.[Friend]OnKeyTraceUp(&this, wParam, lParam);
}

[CRepr]struct ITfPreservedKeyNotifySink : IUnknown
{
	public new const Guid IID = .(0x6f77c993, 0xd2b1, 0x446e, 0x85, 0x3e, 0x59, 0x12, 0xef, 0xc8, 0xa2, 0x86);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_PRESERVEDKEY* pprekey) OnUpdated;
	}


	public HRESULT OnUpdated(TF_PRESERVEDKEY* pprekey) mut => VT.[Friend]OnUpdated(&this, pprekey);
}

[CRepr]struct ITfMessagePump : IUnknown
{
	public new const Guid IID = .(0x8f1b8ad8, 0x0b6b, 0x4874, 0x90, 0xc5, 0xbd, 0x76, 0x01, 0x1e, 0x8f, 0x7c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, uint32 wRemoveMsg, BOOL* pfResult) PeekMessageA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, BOOL* pfResult) GetMessageA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, uint32 wRemoveMsg, BOOL* pfResult) PeekMessageW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, BOOL* pfResult) GetMessageW;
	}


	public HRESULT PeekMessageA(MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, uint32 wRemoveMsg, BOOL* pfResult) mut => VT.[Friend]PeekMessageA(&this, pMsg, hwnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg, pfResult);

	public HRESULT GetMessageA(MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, BOOL* pfResult) mut => VT.[Friend]GetMessageA(&this, pMsg, hwnd, wMsgFilterMin, wMsgFilterMax, pfResult);

	public HRESULT PeekMessageW(MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, uint32 wRemoveMsg, BOOL* pfResult) mut => VT.[Friend]PeekMessageW(&this, pMsg, hwnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg, pfResult);

	public HRESULT GetMessageW(MSG* pMsg, HWND hwnd, uint32 wMsgFilterMin, uint32 wMsgFilterMax, BOOL* pfResult) mut => VT.[Friend]GetMessageW(&this, pMsg, hwnd, wMsgFilterMin, wMsgFilterMax, pfResult);
}

[CRepr]struct ITfThreadFocusSink : IUnknown
{
	public new const Guid IID = .(0xc0f1db0c, 0x3a20, 0x405c, 0xa3, 0x03, 0x96, 0xb6, 0x01, 0x0a, 0x88, 0x5f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnSetThreadFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnKillThreadFocus;
	}


	public HRESULT OnSetThreadFocus() mut => VT.[Friend]OnSetThreadFocus(&this);

	public HRESULT OnKillThreadFocus() mut => VT.[Friend]OnKillThreadFocus(&this);
}

[CRepr]struct ITfTextInputProcessor : IUnknown
{
	public new const Guid IID = .(0xaa80e7f7, 0x2021, 0x11d2, 0x93, 0xe0, 0x00, 0x60, 0xb0, 0x67, 0xb8, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfThreadMgr* ptim, uint32 tid) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Deactivate;
	}


	public HRESULT Activate(ITfThreadMgr* ptim, uint32 tid) mut => VT.[Friend]Activate(&this, ptim, tid);

	public HRESULT Deactivate() mut => VT.[Friend]Deactivate(&this);
}

[CRepr]struct ITfTextInputProcessorEx : ITfTextInputProcessor
{
	public new const Guid IID = .(0x6e4e2102, 0xf9cd, 0x433d, 0xb4, 0x96, 0x30, 0x3c, 0xe0, 0x3a, 0x65, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfTextInputProcessor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfThreadMgr* ptim, uint32 tid, uint32 dwFlags) ActivateEx;
	}


	public HRESULT ActivateEx(ITfThreadMgr* ptim, uint32 tid, uint32 dwFlags) mut => VT.[Friend]ActivateEx(&this, ptim, tid, dwFlags);
}

[CRepr]struct ITfClientId : IUnknown
{
	public new const Guid IID = .(0xd60a7b49, 0x1b9f, 0x4be2, 0xb7, 0x02, 0x47, 0xe9, 0xdc, 0x05, 0xde, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32* ptid) GetClientId;
	}


	public HRESULT GetClientId(in Guid rclsid, uint32* ptid) mut => VT.[Friend]GetClientId(&this, rclsid, ptid);
}

[CRepr]struct ITfDisplayAttributeInfo : IUnknown
{
	public new const Guid IID = .(0x70528852, 0x2f26, 0x4aea, 0x8c, 0x96, 0x21, 0x51, 0x50, 0x57, 0x89, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) GetGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDesc) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_DISPLAYATTRIBUTE* pda) GetAttributeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TF_DISPLAYATTRIBUTE* pda) SetAttributeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT GetGUID(Guid* pguid) mut => VT.[Friend]GetGUID(&this, pguid);

	public HRESULT GetDescription(BSTR* pbstrDesc) mut => VT.[Friend]GetDescription(&this, pbstrDesc);

	public HRESULT GetAttributeInfo(TF_DISPLAYATTRIBUTE* pda) mut => VT.[Friend]GetAttributeInfo(&this, pda);

	public HRESULT SetAttributeInfo(TF_DISPLAYATTRIBUTE* pda) mut => VT.[Friend]SetAttributeInfo(&this, pda);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IEnumTfDisplayAttributeInfo : IUnknown
{
	public new const Guid IID = .(0x7cef04d7, 0xcb75, 0x4e80, 0xa7, 0xab, 0x5f, 0x5b, 0xc7, 0xd3, 0x32, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDisplayAttributeInfo** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfDisplayAttributeInfo** rgInfo, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfDisplayAttributeInfo** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfDisplayAttributeInfo** rgInfo, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgInfo, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfDisplayAttributeProvider : IUnknown
{
	public new const Guid IID = .(0xfee47777, 0x163c, 0x4769, 0x99, 0x6a, 0x6e, 0x9c, 0x50, 0xad, 0x8f, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDisplayAttributeInfo** ppEnum) EnumDisplayAttributeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, ITfDisplayAttributeInfo** ppInfo) GetDisplayAttributeInfo;
	}


	public HRESULT EnumDisplayAttributeInfo(IEnumTfDisplayAttributeInfo** ppEnum) mut => VT.[Friend]EnumDisplayAttributeInfo(&this, ppEnum);

	public HRESULT GetDisplayAttributeInfo(in Guid guid, ITfDisplayAttributeInfo** ppInfo) mut => VT.[Friend]GetDisplayAttributeInfo(&this, guid, ppInfo);
}

[CRepr]struct ITfDisplayAttributeMgr : IUnknown
{
	public new const Guid IID = .(0x8ded7393, 0x5db1, 0x475c, 0x9e, 0x71, 0xa3, 0x91, 0x11, 0xb0, 0xff, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnUpdateInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfDisplayAttributeInfo** ppEnum) EnumDisplayAttributeInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid, ITfDisplayAttributeInfo** ppInfo, Guid* pclsidOwner) GetDisplayAttributeInfo;
	}


	public HRESULT OnUpdateInfo() mut => VT.[Friend]OnUpdateInfo(&this);

	public HRESULT EnumDisplayAttributeInfo(IEnumTfDisplayAttributeInfo** ppEnum) mut => VT.[Friend]EnumDisplayAttributeInfo(&this, ppEnum);

	public HRESULT GetDisplayAttributeInfo(in Guid guid, ITfDisplayAttributeInfo** ppInfo, Guid* pclsidOwner) mut => VT.[Friend]GetDisplayAttributeInfo(&this, guid, ppInfo, pclsidOwner);
}

[CRepr]struct ITfDisplayAttributeNotifySink : IUnknown
{
	public new const Guid IID = .(0xad56f402, 0xe162, 0x4f25, 0x90, 0x8f, 0x7d, 0x57, 0x7c, 0xf9, 0xbd, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnUpdateInfo;
	}


	public HRESULT OnUpdateInfo() mut => VT.[Friend]OnUpdateInfo(&this);
}

[CRepr]struct ITfCategoryMgr : IUnknown
{
	public new const Guid IID = .(0xc3acefb5, 0xf69d, 0x4905, 0x93, 0x8f, 0xfc, 0xad, 0xcf, 0x4b, 0xe8, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rcatid, in Guid rguid) RegisterCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rcatid, in Guid rguid) UnregisterCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, IEnumGUID** ppEnum) EnumCategoriesInItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rcatid, IEnumGUID** ppEnum) EnumItemsInCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, Guid* pcatid, Guid** ppcatidList, uint32 ulCount) FindClosestCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rguid, char16* pchDesc, uint32 cch) RegisterGUIDDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rguid) UnregisterGUIDDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, BSTR* pbstrDesc) GetGUIDDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rguid, uint32 dw) RegisterGUIDDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, in Guid rguid) UnregisterGUIDDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, uint32* pdw) GetGUIDDWORD;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguid, uint32* pguidatom) RegisterGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 guidatom, Guid* pguid) GetGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 guidatom, in Guid rguid, BOOL* pfEqual) IsEqualTfGuidAtom;
	}


	public HRESULT RegisterCategory(in Guid rclsid, in Guid rcatid, in Guid rguid) mut => VT.[Friend]RegisterCategory(&this, rclsid, rcatid, rguid);

	public HRESULT UnregisterCategory(in Guid rclsid, in Guid rcatid, in Guid rguid) mut => VT.[Friend]UnregisterCategory(&this, rclsid, rcatid, rguid);

	public HRESULT EnumCategoriesInItem(in Guid rguid, IEnumGUID** ppEnum) mut => VT.[Friend]EnumCategoriesInItem(&this, rguid, ppEnum);

	public HRESULT EnumItemsInCategory(in Guid rcatid, IEnumGUID** ppEnum) mut => VT.[Friend]EnumItemsInCategory(&this, rcatid, ppEnum);

	public HRESULT FindClosestCategory(in Guid rguid, Guid* pcatid, Guid** ppcatidList, uint32 ulCount) mut => VT.[Friend]FindClosestCategory(&this, rguid, pcatid, ppcatidList, ulCount);

	public HRESULT RegisterGUIDDescription(in Guid rclsid, in Guid rguid, char16* pchDesc, uint32 cch) mut => VT.[Friend]RegisterGUIDDescription(&this, rclsid, rguid, pchDesc, cch);

	public HRESULT UnregisterGUIDDescription(in Guid rclsid, in Guid rguid) mut => VT.[Friend]UnregisterGUIDDescription(&this, rclsid, rguid);

	public HRESULT GetGUIDDescription(in Guid rguid, BSTR* pbstrDesc) mut => VT.[Friend]GetGUIDDescription(&this, rguid, pbstrDesc);

	public HRESULT RegisterGUIDDWORD(in Guid rclsid, in Guid rguid, uint32 dw) mut => VT.[Friend]RegisterGUIDDWORD(&this, rclsid, rguid, dw);

	public HRESULT UnregisterGUIDDWORD(in Guid rclsid, in Guid rguid) mut => VT.[Friend]UnregisterGUIDDWORD(&this, rclsid, rguid);

	public HRESULT GetGUIDDWORD(in Guid rguid, uint32* pdw) mut => VT.[Friend]GetGUIDDWORD(&this, rguid, pdw);

	public HRESULT RegisterGUID(in Guid rguid, uint32* pguidatom) mut => VT.[Friend]RegisterGUID(&this, rguid, pguidatom);

	public HRESULT GetGUID(uint32 guidatom, Guid* pguid) mut => VT.[Friend]GetGUID(&this, guidatom, pguid);

	public HRESULT IsEqualTfGuidAtom(uint32 guidatom, in Guid rguid, BOOL* pfEqual) mut => VT.[Friend]IsEqualTfGuidAtom(&this, guidatom, rguid, pfEqual);
}

[CRepr]struct ITfSource : IUnknown
{
	public new const Guid IID = .(0x4ea48a35, 0x60ae, 0x446f, 0x8f, 0xd6, 0xe6, 0xa8, 0xd8, 0x24, 0x59, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk, uint32* pdwCookie) AdviseSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnadviseSink;
	}


	public HRESULT AdviseSink(in Guid riid, IUnknown* punk, uint32* pdwCookie) mut => VT.[Friend]AdviseSink(&this, riid, punk, pdwCookie);

	public HRESULT UnadviseSink(uint32 dwCookie) mut => VT.[Friend]UnadviseSink(&this, dwCookie);
}

[CRepr]struct ITfSourceSingle : IUnknown
{
	public new const Guid IID = .(0x73131f9c, 0x56a9, 0x49dd, 0xb0, 0xee, 0xd0, 0x46, 0x63, 0x3f, 0x75, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, in Guid riid, IUnknown* punk) AdviseSingleSink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 tid, in Guid riid) UnadviseSingleSink;
	}


	public HRESULT AdviseSingleSink(uint32 tid, in Guid riid, IUnknown* punk) mut => VT.[Friend]AdviseSingleSink(&this, tid, riid, punk);

	public HRESULT UnadviseSingleSink(uint32 tid, in Guid riid) mut => VT.[Friend]UnadviseSingleSink(&this, tid, riid);
}

[CRepr]struct ITfUIElementMgr : IUnknown
{
	public new const Guid IID = .(0xea1ea135, 0x19df, 0x11d7, 0xa6, 0xd2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfUIElement* pElement, BOOL* pbShow, uint32* pdwUIElementId) BeginUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIElementId) UpdateUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIElementId) EndUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIELementId, ITfUIElement** ppElement) GetUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfUIElements** ppEnum) EnumUIElements;
	}


	public HRESULT BeginUIElement(ITfUIElement* pElement, BOOL* pbShow, uint32* pdwUIElementId) mut => VT.[Friend]BeginUIElement(&this, pElement, pbShow, pdwUIElementId);

	public HRESULT UpdateUIElement(uint32 dwUIElementId) mut => VT.[Friend]UpdateUIElement(&this, dwUIElementId);

	public HRESULT EndUIElement(uint32 dwUIElementId) mut => VT.[Friend]EndUIElement(&this, dwUIElementId);

	public HRESULT GetUIElement(uint32 dwUIELementId, ITfUIElement** ppElement) mut => VT.[Friend]GetUIElement(&this, dwUIELementId, ppElement);

	public HRESULT EnumUIElements(IEnumTfUIElements** ppEnum) mut => VT.[Friend]EnumUIElements(&this, ppEnum);
}

[CRepr]struct IEnumTfUIElements : IUnknown
{
	public new const Guid IID = .(0x887aa91e, 0xacba, 0x4931, 0x84, 0xda, 0x3c, 0x52, 0x08, 0xcf, 0x54, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfUIElements** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfUIElement** ppElement, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfUIElements** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfUIElement** ppElement, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, ppElement, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfUIElementSink : IUnknown
{
	public new const Guid IID = .(0xea1ea136, 0x19df, 0x11d7, 0xa6, 0xd2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIElementId, BOOL* pbShow) BeginUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIElementId) UpdateUIElement;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwUIElementId) EndUIElement;
	}


	public HRESULT BeginUIElement(uint32 dwUIElementId, BOOL* pbShow) mut => VT.[Friend]BeginUIElement(&this, dwUIElementId, pbShow);

	public HRESULT UpdateUIElement(uint32 dwUIElementId) mut => VT.[Friend]UpdateUIElement(&this, dwUIElementId);

	public HRESULT EndUIElement(uint32 dwUIElementId) mut => VT.[Friend]EndUIElement(&this, dwUIElementId);
}

[CRepr]struct ITfUIElement : IUnknown
{
	public new const Guid IID = .(0xea1ea137, 0x19df, 0x11d7, 0xa6, 0xd2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) GetGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bShow) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbShow) IsShown;
	}


	public HRESULT GetDescription(BSTR* pbstrDescription) mut => VT.[Friend]GetDescription(&this, pbstrDescription);

	public HRESULT GetGUID(Guid* pguid) mut => VT.[Friend]GetGUID(&this, pguid);

	public HRESULT Show(BOOL bShow) mut => VT.[Friend]Show(&this, bShow);

	public HRESULT IsShown(BOOL* pbShow) mut => VT.[Friend]IsShown(&this, pbShow);
}

[CRepr]struct ITfCandidateListUIElement : ITfUIElement
{
	public new const Guid IID = .(0xea1ea138, 0x19df, 0x11d7, 0xa6, 0xd2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfUIElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetUpdatedFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdim) GetDocumentMgr;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puIndex) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pstr) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pIndex, uint32 uSize, uint32* puPageCnt) GetPageIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pIndex, uint32 uPageCnt) SetPageIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puPage) GetCurrentPage;
	}


	public HRESULT GetUpdatedFlags(uint32* pdwFlags) mut => VT.[Friend]GetUpdatedFlags(&this, pdwFlags);

	public HRESULT GetDocumentMgr(ITfDocumentMgr** ppdim) mut => VT.[Friend]GetDocumentMgr(&this, ppdim);

	public HRESULT GetCount(uint32* puCount) mut => VT.[Friend]GetCount(&this, puCount);

	public HRESULT GetSelection(uint32* puIndex) mut => VT.[Friend]GetSelection(&this, puIndex);

	public HRESULT GetString(uint32 uIndex, BSTR* pstr) mut => VT.[Friend]GetString(&this, uIndex, pstr);

	public HRESULT GetPageIndex(uint32* pIndex, uint32 uSize, uint32* puPageCnt) mut => VT.[Friend]GetPageIndex(&this, pIndex, uSize, puPageCnt);

	public HRESULT SetPageIndex(uint32* pIndex, uint32 uPageCnt) mut => VT.[Friend]SetPageIndex(&this, pIndex, uPageCnt);

	public HRESULT GetCurrentPage(uint32* puPage) mut => VT.[Friend]GetCurrentPage(&this, puPage);
}

[CRepr]struct ITfCandidateListUIElementBehavior : ITfCandidateListUIElement
{
	public new const Guid IID = .(0x85fad185, 0x58ce, 0x497a, 0x94, 0x60, 0x35, 0x53, 0x66, 0xb6, 0x4b, 0x9a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfCandidateListUIElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Finalize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Abort;
	}


	public HRESULT SetSelection(uint32 nIndex) mut => VT.[Friend]SetSelection(&this, nIndex);

	public HRESULT Finalize() mut => VT.[Friend]Finalize(&this);

	public HRESULT Abort() mut => VT.[Friend]Abort(&this);
}

[CRepr]struct ITfReadingInformationUIElement : ITfUIElement
{
	public new const Guid IID = .(0xea1ea139, 0x19df, 0x11d7, 0xa6, 0xd2, 0x00, 0x06, 0x5b, 0x84, 0x43, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfUIElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetUpdatedFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext** ppic) GetContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstr) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchMax) GetMaxReadingStringLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pErrorIndex) GetErrorIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfVertical) IsVerticalOrderPreferred;
	}


	public HRESULT GetUpdatedFlags(uint32* pdwFlags) mut => VT.[Friend]GetUpdatedFlags(&this, pdwFlags);

	public HRESULT GetContext(ITfContext** ppic) mut => VT.[Friend]GetContext(&this, ppic);

	public HRESULT GetString(BSTR* pstr) mut => VT.[Friend]GetString(&this, pstr);

	public HRESULT GetMaxReadingStringLength(uint32* pcchMax) mut => VT.[Friend]GetMaxReadingStringLength(&this, pcchMax);

	public HRESULT GetErrorIndex(uint32* pErrorIndex) mut => VT.[Friend]GetErrorIndex(&this, pErrorIndex);

	public HRESULT IsVerticalOrderPreferred(BOOL* pfVertical) mut => VT.[Friend]IsVerticalOrderPreferred(&this, pfVertical);
}

[CRepr]struct ITfTransitoryExtensionUIElement : ITfUIElement
{
	public new const Guid IID = .(0x858f956a, 0x972f, 0x42a2, 0xa2, 0xf2, 0x03, 0x21, 0xe1, 0xab, 0xe2, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfUIElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfDocumentMgr** ppdim) GetDocumentMgr;
	}


	public HRESULT GetDocumentMgr(ITfDocumentMgr** ppdim) mut => VT.[Friend]GetDocumentMgr(&this, ppdim);
}

[CRepr]struct ITfTransitoryExtensionSink : IUnknown
{
	public new const Guid IID = .(0xa615096f, 0x1c57, 0x4813, 0x8a, 0x15, 0x55, 0xee, 0x6e, 0x5a, 0x83, 0x9c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, uint32 ecReadOnly, ITfRange* pResultRange, ITfRange* pCompositionRange, BOOL* pfDeleteResultRange) OnTransitoryExtensionUpdated;
	}


	public HRESULT OnTransitoryExtensionUpdated(ITfContext* pic, uint32 ecReadOnly, ITfRange* pResultRange, ITfRange* pCompositionRange, BOOL* pfDeleteResultRange) mut => VT.[Friend]OnTransitoryExtensionUpdated(&this, pic, ecReadOnly, pResultRange, pCompositionRange, pfDeleteResultRange);
}

[CRepr]struct ITfToolTipUIElement : ITfUIElement
{
	public new const Guid IID = .(0x52b18b5c, 0x555d, 0x46b2, 0xb0, 0x0a, 0xfa, 0x68, 0x01, 0x44, 0xfb, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfUIElement.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstr) GetString;
	}


	public HRESULT GetString(BSTR* pstr) mut => VT.[Friend]GetString(&this, pstr);
}

[CRepr]struct ITfReverseConversionList : IUnknown
{
	public new const Guid IID = .(0x151d69f0, 0x86f4, 0x4674, 0xb7, 0x21, 0x56, 0x91, 0x1e, 0x79, 0x7f, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puIndex) GetLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uIndex, BSTR* pbstr) GetString;
	}


	public HRESULT GetLength(uint32* puIndex) mut => VT.[Friend]GetLength(&this, puIndex);

	public HRESULT GetString(uint32 uIndex, BSTR* pbstr) mut => VT.[Friend]GetString(&this, uIndex, pbstr);
}

[CRepr]struct ITfReverseConversion : IUnknown
{
	public new const Guid IID = .(0xa415e162, 0x157d, 0x417d, 0x8a, 0x8c, 0x0a, 0xb2, 0x6c, 0x7d, 0x27, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpstr, ITfReverseConversionList** ppList) DoReverseConversion;
	}


	public HRESULT DoReverseConversion(PWSTR lpstr, ITfReverseConversionList** ppList) mut => VT.[Friend]DoReverseConversion(&this, lpstr, ppList);
}

[CRepr]struct ITfReverseConversionMgr : IUnknown
{
	public new const Guid IID = .(0xb643c236, 0xc493, 0x41b6, 0xab, 0xb3, 0x69, 0x24, 0x12, 0x77, 0x5c, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, in Guid guidProfile, uint32 dwflag, ITfReverseConversion** ppReverseConversion) GetReverseConversion;
	}


	public HRESULT GetReverseConversion(uint16 langid, in Guid guidProfile, uint32 dwflag, ITfReverseConversion** ppReverseConversion) mut => VT.[Friend]GetReverseConversion(&this, langid, guidProfile, dwflag, ppReverseConversion);
}

[CRepr]struct ITfCandidateString : IUnknown
{
	public new const Guid IID = .(0x581f317e, 0xfd9d, 0x443f, 0xb9, 0x72, 0xed, 0x00, 0x46, 0x7c, 0x5d, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstr) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnIndex) GetIndex;
	}


	public HRESULT GetString(BSTR* pbstr) mut => VT.[Friend]GetString(&this, pbstr);

	public HRESULT GetIndex(uint32* pnIndex) mut => VT.[Friend]GetIndex(&this, pnIndex);
}

[CRepr]struct IEnumTfCandidates : IUnknown
{
	public new const Guid IID = .(0xdefb1926, 0x6c80, 0x4ce8, 0x87, 0xd4, 0xd6, 0xb7, 0x2b, 0x81, 0x2b, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfCandidates** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, ITfCandidateString** ppCand, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfCandidates** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, ITfCandidateString** ppCand, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, ppCand, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfCandidateList : IUnknown
{
	public new const Guid IID = .(0xa3ad50fb, 0x9bdb, 0x49e3, 0xa8, 0x43, 0x6c, 0x76, 0x52, 0x0f, 0xbf, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfCandidates** ppEnum) EnumCandidates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, ITfCandidateString** ppCand) GetCandidate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnCnt) GetCandidateNum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, TfCandidateResult imcr) SetResult;
	}


	public HRESULT EnumCandidates(IEnumTfCandidates** ppEnum) mut => VT.[Friend]EnumCandidates(&this, ppEnum);

	public HRESULT GetCandidate(uint32 nIndex, ITfCandidateString** ppCand) mut => VT.[Friend]GetCandidate(&this, nIndex, ppCand);

	public HRESULT GetCandidateNum(uint32* pnCnt) mut => VT.[Friend]GetCandidateNum(&this, pnCnt);

	public HRESULT SetResult(uint32 nIndex, TfCandidateResult imcr) mut => VT.[Friend]SetResult(&this, nIndex, imcr);
}

[CRepr]struct ITfFnReconversion : ITfFunction
{
	public new const Guid IID = .(0x4cea93c0, 0x0a58, 0x11d3, 0x8d, 0xf0, 0x00, 0x10, 0x5a, 0x27, 0x99, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfConvertable) QueryRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfCandidateList** ppCandList) GetReconversion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange) Reconvert;
	}


	public HRESULT QueryRange(ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfConvertable) mut => VT.[Friend]QueryRange(&this, pRange, ppNewRange, pfConvertable);

	public HRESULT GetReconversion(ITfRange* pRange, ITfCandidateList** ppCandList) mut => VT.[Friend]GetReconversion(&this, pRange, ppCandList);

	public HRESULT Reconvert(ITfRange* pRange) mut => VT.[Friend]Reconvert(&this, pRange);
}

[CRepr]struct ITfFnPlayBack : ITfFunction
{
	public new const Guid IID = .(0xa3a416a4, 0x0f64, 0x11d3, 0xb5, 0xb7, 0x00, 0xc0, 0x4f, 0xc3, 0x24, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfPlayable) QueryRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange) Play;
	}


	public HRESULT QueryRange(ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfPlayable) mut => VT.[Friend]QueryRange(&this, pRange, ppNewRange, pfPlayable);

	public HRESULT Play(ITfRange* pRange) mut => VT.[Friend]Play(&this, pRange);
}

[CRepr]struct ITfFnLangProfileUtil : ITfFunction
{
	public new const Guid IID = .(0xa87a8574, 0xa6c1, 0x4e15, 0x99, 0xf0, 0x3d, 0x39, 0x65, 0xf5, 0x48, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RegisterActiveProfiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, BOOL* pfAvailable) IsProfileAvailableForLang;
	}


	public HRESULT RegisterActiveProfiles() mut => VT.[Friend]RegisterActiveProfiles(&this);

	public HRESULT IsProfileAvailableForLang(uint16 langid, BOOL* pfAvailable) mut => VT.[Friend]IsProfileAvailableForLang(&this, langid, pfAvailable);
}

[CRepr]struct ITfFnConfigure : ITfFunction
{
	public new const Guid IID = .(0x88f567c6, 0x1757, 0x49f8, 0xa1, 0xb2, 0x89, 0x23, 0x4c, 0x1e, 0xef, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint16 langid, in Guid rguidProfile) Show;
	}


	public HRESULT Show(HWND hwndParent, uint16 langid, in Guid rguidProfile) mut => VT.[Friend]Show(&this, hwndParent, langid, rguidProfile);
}

[CRepr]struct ITfFnConfigureRegisterWord : ITfFunction
{
	public new const Guid IID = .(0xbb95808a, 0x6d8f, 0x4bca, 0x84, 0x00, 0x53, 0x90, 0xb5, 0x86, 0xae, 0xdf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint16 langid, in Guid rguidProfile, BSTR bstrRegistered) Show;
	}


	public HRESULT Show(HWND hwndParent, uint16 langid, in Guid rguidProfile, BSTR bstrRegistered) mut => VT.[Friend]Show(&this, hwndParent, langid, rguidProfile, bstrRegistered);
}

[CRepr]struct ITfFnConfigureRegisterEudc : ITfFunction
{
	public new const Guid IID = .(0xb5e26ff5, 0xd7ad, 0x4304, 0x91, 0x3f, 0x21, 0xa2, 0xed, 0x95, 0xa1, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, uint16 langid, in Guid rguidProfile, BSTR bstrRegistered) Show;
	}


	public HRESULT Show(HWND hwndParent, uint16 langid, in Guid rguidProfile, BSTR bstrRegistered) mut => VT.[Friend]Show(&this, hwndParent, langid, rguidProfile, bstrRegistered);
}

[CRepr]struct ITfFnShowHelp : ITfFunction
{
	public new const Guid IID = .(0x5ab1d30c, 0x094d, 0x4c29, 0x8e, 0xa5, 0x0b, 0xf5, 0x9b, 0xe8, 0x7b, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) Show;
	}


	public HRESULT Show(HWND hwndParent) mut => VT.[Friend]Show(&this, hwndParent);
}

[CRepr]struct ITfFnBalloon : IUnknown
{
	public new const Guid IID = .(0x3bab89e4, 0x5fbe, 0x45f4, 0xa5, 0xbc, 0xdc, 0xa3, 0x6a, 0xd2, 0x25, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBBalloonStyle style, char16* pch, uint32 cch) UpdateBalloon;
	}


	public HRESULT UpdateBalloon(TfLBBalloonStyle style, char16* pch, uint32 cch) mut => VT.[Friend]UpdateBalloon(&this, style, pch, cch);
}

[CRepr]struct ITfFnGetSAPIObject : ITfFunction
{
	public new const Guid IID = .(0x5c0ab7ea, 0x167d, 0x4f59, 0xbf, 0xb5, 0x46, 0x93, 0x75, 0x5e, 0x90, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfSapiObject sObj, IUnknown** ppunk) Get;
	}


	public HRESULT Get(TfSapiObject sObj, IUnknown** ppunk) mut => VT.[Friend]Get(&this, sObj, ppunk);
}

[CRepr]struct ITfFnPropertyUIStatus : ITfFunction
{
	public new const Guid IID = .(0x2338ac6e, 0x2b9d, 0x44c0, 0xa7, 0x5e, 0xee, 0x64, 0xf2, 0x56, 0xb3, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid refguidProp, uint32* pdw) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid refguidProp, uint32 dw) SetStatus;
	}


	public HRESULT GetStatus(in Guid refguidProp, uint32* pdw) mut => VT.[Friend]GetStatus(&this, refguidProp, pdw);

	public HRESULT SetStatus(in Guid refguidProp, uint32 dw) mut => VT.[Friend]SetStatus(&this, refguidProp, dw);
}

[CRepr]struct IEnumSpeechCommands : IUnknown
{
	public new const Guid IID = .(0x8c5dac4f, 0x083c, 0x4b85, 0xa4, 0xc9, 0x71, 0x74, 0x60, 0x48, 0xad, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSpeechCommands** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, uint16** pSpCmds, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumSpeechCommands** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, uint16** pSpCmds, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, pSpCmds, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ISpeechCommandProvider : IUnknown
{
	public new const Guid IID = .(0x38e09d4c, 0x586d, 0x435a, 0xb5, 0x92, 0xc8, 0xa8, 0x66, 0x91, 0xde, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, IEnumSpeechCommands** ppEnum) EnumSpeechCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszCommand, uint32 cch, uint16 langid) ProcessCommand;
	}


	public HRESULT EnumSpeechCommands(uint16 langid, IEnumSpeechCommands** ppEnum) mut => VT.[Friend]EnumSpeechCommands(&this, langid, ppEnum);

	public HRESULT ProcessCommand(char16* pszCommand, uint32 cch, uint16 langid) mut => VT.[Friend]ProcessCommand(&this, pszCommand, cch, langid);
}

[CRepr]struct ITfFnCustomSpeechCommand : ITfFunction
{
	public new const Guid IID = .(0xfca6c349, 0xa12f, 0x43a3, 0x8d, 0xd6, 0x5a, 0x5a, 0x42, 0x82, 0x57, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pspcmdProvider) SetSpeechCommandProvider;
	}


	public HRESULT SetSpeechCommandProvider(IUnknown* pspcmdProvider) mut => VT.[Friend]SetSpeechCommandProvider(&this, pspcmdProvider);
}

[CRepr]struct ITfFnLMProcessor : ITfFunction
{
	public new const Guid IID = .(0x7afbf8e7, 0xac4b, 0x4082, 0xb0, 0x58, 0x89, 0x08, 0x99, 0xd3, 0xa0, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfAccepted) QueryRange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 langid, BOOL* pfAccepted) QueryLangID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfCandidateList** ppCandList) GetReconversion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange) Reconvert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUp, WPARAM vKey, LPARAM lparamKeydata, BOOL* pfInterested) QueryKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fUp, WPARAM vKey, LPARAM lparamKeyData) InvokeKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfContext* pic, in Guid refguidFunc) InvokeFunc;
	}


	public HRESULT QueryRange(ITfRange* pRange, ITfRange** ppNewRange, BOOL* pfAccepted) mut => VT.[Friend]QueryRange(&this, pRange, ppNewRange, pfAccepted);

	public HRESULT QueryLangID(uint16 langid, BOOL* pfAccepted) mut => VT.[Friend]QueryLangID(&this, langid, pfAccepted);

	public HRESULT GetReconversion(ITfRange* pRange, ITfCandidateList** ppCandList) mut => VT.[Friend]GetReconversion(&this, pRange, ppCandList);

	public HRESULT Reconvert(ITfRange* pRange) mut => VT.[Friend]Reconvert(&this, pRange);

	public HRESULT QueryKey(BOOL fUp, WPARAM vKey, LPARAM lparamKeydata, BOOL* pfInterested) mut => VT.[Friend]QueryKey(&this, fUp, vKey, lparamKeydata, pfInterested);

	public HRESULT InvokeKey(BOOL fUp, WPARAM vKey, LPARAM lparamKeyData) mut => VT.[Friend]InvokeKey(&this, fUp, vKey, lparamKeyData);

	public HRESULT InvokeFunc(ITfContext* pic, in Guid refguidFunc) mut => VT.[Friend]InvokeFunc(&this, pic, refguidFunc);
}

[CRepr]struct ITfFnLMInternal : ITfFnLMProcessor
{
	public new const Guid IID = .(0x04b825b1, 0xac9a, 0x4f7b, 0xb5, 0xad, 0xc7, 0x16, 0x8f, 0x1e, 0xe4, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFnLMProcessor.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange) ProcessLattice;
	}


	public HRESULT ProcessLattice(ITfRange* pRange) mut => VT.[Friend]ProcessLattice(&this, pRange);
}

[CRepr]struct IEnumTfLatticeElements : IUnknown
{
	public new const Guid IID = .(0x56988052, 0x47da, 0x4a05, 0x91, 0x1a, 0xe3, 0xd9, 0x41, 0xf1, 0x71, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTfLatticeElements** ppEnum) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount, TF_LMLATTELEMENT* rgsElements, uint32* pcFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulCount) Skip;
	}


	public HRESULT Clone(IEnumTfLatticeElements** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);

	public HRESULT Next(uint32 ulCount, TF_LMLATTELEMENT* rgsElements, uint32* pcFetched) mut => VT.[Friend]Next(&this, ulCount, rgsElements, pcFetched);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 ulCount) mut => VT.[Friend]Skip(&this, ulCount);
}

[CRepr]struct ITfLMLattice : IUnknown
{
	public new const Guid IID = .(0xd4236675, 0xa5bf, 0x4570, 0x9d, 0x42, 0x5d, 0x6d, 0x7b, 0x02, 0xd5, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidType, BOOL* pfSupported) QueryType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFrameStart, in Guid rguidType, IEnumTfLatticeElements** ppEnum) EnumLatticeElements;
	}


	public HRESULT QueryType(in Guid rguidType, BOOL* pfSupported) mut => VT.[Friend]QueryType(&this, rguidType, pfSupported);

	public HRESULT EnumLatticeElements(uint32 dwFrameStart, in Guid rguidType, IEnumTfLatticeElements** ppEnum) mut => VT.[Friend]EnumLatticeElements(&this, dwFrameStart, rguidType, ppEnum);
}

[CRepr]struct ITfFnAdviseText : ITfFunction
{
	public new const Guid IID = .(0x3527268b, 0x7d53, 0x4dd9, 0x92, 0xb7, 0x72, 0x96, 0xae, 0x46, 0x12, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, char16* pchText, int32 cch) OnTextUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfLMLattice* pLattice) OnLatticeUpdate;
	}


	public HRESULT OnTextUpdate(ITfRange* pRange, char16* pchText, int32 cch) mut => VT.[Friend]OnTextUpdate(&this, pRange, pchText, cch);

	public HRESULT OnLatticeUpdate(ITfRange* pRange, ITfLMLattice* pLattice) mut => VT.[Friend]OnLatticeUpdate(&this, pRange, pLattice);
}

[CRepr]struct ITfFnSearchCandidateProvider : ITfFunction
{
	public new const Guid IID = .(0x87a2ad8f, 0xf27b, 0x4920, 0x85, 0x01, 0x67, 0x60, 0x22, 0x80, 0x17, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrQuery, BSTR bstrApplicationId, ITfCandidateList** pplist) GetSearchCandidates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrQuery, BSTR bstrApplicationID, BSTR bstrResult) SetResult;
	}


	public HRESULT GetSearchCandidates(BSTR bstrQuery, BSTR bstrApplicationId, ITfCandidateList** pplist) mut => VT.[Friend]GetSearchCandidates(&this, bstrQuery, bstrApplicationId, pplist);

	public HRESULT SetResult(BSTR bstrQuery, BSTR bstrApplicationID, BSTR bstrResult) mut => VT.[Friend]SetResult(&this, bstrQuery, bstrApplicationID, bstrResult);
}

[CRepr]struct ITfIntegratableCandidateListUIElement : IUnknown
{
	public new const Guid IID = .(0xc7a6f54f, 0xb180, 0x416f, 0xb2, 0xbf, 0x7b, 0xf2, 0xe4, 0x68, 0x3d, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid guidIntegrationStyle) SetIntegrationStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfIntegratableCandidateListSelectionStyle* ptfSelectionStyle) GetSelectionStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam, BOOL* pfEaten) OnKeyDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfShow) ShowCandidateNumbers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FinalizeExactCompositionString;
	}


	public HRESULT SetIntegrationStyle(Guid guidIntegrationStyle) mut => VT.[Friend]SetIntegrationStyle(&this, guidIntegrationStyle);

	public HRESULT GetSelectionStyle(TfIntegratableCandidateListSelectionStyle* ptfSelectionStyle) mut => VT.[Friend]GetSelectionStyle(&this, ptfSelectionStyle);

	public HRESULT OnKeyDown(WPARAM wParam, LPARAM lParam, BOOL* pfEaten) mut => VT.[Friend]OnKeyDown(&this, wParam, lParam, pfEaten);

	public HRESULT ShowCandidateNumbers(BOOL* pfShow) mut => VT.[Friend]ShowCandidateNumbers(&this, pfShow);

	public HRESULT FinalizeExactCompositionString() mut => VT.[Friend]FinalizeExactCompositionString(&this);
}

[CRepr]struct ITfFnGetPreferredTouchKeyboardLayout : ITfFunction
{
	public new const Guid IID = .(0x5f309a41, 0x590a, 0x4acc, 0xa9, 0x7f, 0xd8, 0xef, 0xff, 0x13, 0xfd, 0xfc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TKBLayoutType* pTKBLayoutType, uint16* pwPreferredLayoutId) GetLayout;
	}


	public HRESULT GetLayout(TKBLayoutType* pTKBLayoutType, uint16* pwPreferredLayoutId) mut => VT.[Friend]GetLayout(&this, pTKBLayoutType, pwPreferredLayoutId);
}

[CRepr]struct ITfFnGetLinguisticAlternates : ITfFunction
{
	public new const Guid IID = .(0xea163ce2, 0x7a65, 0x4506, 0x82, 0xa3, 0xc5, 0x28, 0x21, 0x5d, 0xa6, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfFunction.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITfRange* pRange, ITfCandidateList** ppCandidateList) GetAlternates;
	}


	public HRESULT GetAlternates(ITfRange* pRange, ITfCandidateList** ppCandidateList) mut => VT.[Friend]GetAlternates(&this, pRange, ppCandidateList);
}

[CRepr]struct IUIManagerEventSink : IUnknown
{
	public new const Guid IID = .(0xcd91d690, 0xa7e8, 0x4265, 0x9b, 0x38, 0x8b, 0xb3, 0xbb, 0xab, 0xa7, 0xde);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcBounds) OnWindowOpening;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcBounds) OnWindowOpened;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcUpdatedBounds) OnWindowUpdating;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcUpdatedBounds) OnWindowUpdated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnWindowClosing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnWindowClosed;
	}


	public HRESULT OnWindowOpening(RECT* prcBounds) mut => VT.[Friend]OnWindowOpening(&this, prcBounds);

	public HRESULT OnWindowOpened(RECT* prcBounds) mut => VT.[Friend]OnWindowOpened(&this, prcBounds);

	public HRESULT OnWindowUpdating(RECT* prcUpdatedBounds) mut => VT.[Friend]OnWindowUpdating(&this, prcUpdatedBounds);

	public HRESULT OnWindowUpdated(RECT* prcUpdatedBounds) mut => VT.[Friend]OnWindowUpdated(&this, prcUpdatedBounds);

	public HRESULT OnWindowClosing() mut => VT.[Friend]OnWindowClosing(&this);

	public HRESULT OnWindowClosed() mut => VT.[Friend]OnWindowClosed(&this);
}

[CRepr]struct ITfInputScope : IUnknown
{
	public new const Guid IID = .(0xfde1eaee, 0x6924, 0x4cdf, 0x91, 0xe7, 0xda, 0x38, 0xcf, 0xf5, 0x55, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, InputScope** pprgInputScopes, uint32* pcCount) GetInputScopes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR** ppbstrPhrases, uint32* pcCount) GetPhrase;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrRegExp) GetRegularExpression;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSRGS) GetSRGS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrXML) GetXML;
	}


	public HRESULT GetInputScopes(InputScope** pprgInputScopes, uint32* pcCount) mut => VT.[Friend]GetInputScopes(&this, pprgInputScopes, pcCount);

	public HRESULT GetPhrase(BSTR** ppbstrPhrases, uint32* pcCount) mut => VT.[Friend]GetPhrase(&this, ppbstrPhrases, pcCount);

	public HRESULT GetRegularExpression(BSTR* pbstrRegExp) mut => VT.[Friend]GetRegularExpression(&this, pbstrRegExp);

	public HRESULT GetSRGS(BSTR* pbstrSRGS) mut => VT.[Friend]GetSRGS(&this, pbstrSRGS);

	public HRESULT GetXML(BSTR* pbstrXML) mut => VT.[Friend]GetXML(&this, pbstrXML);
}

[CRepr]struct ITfInputScope2 : ITfInputScope
{
	public new const Guid IID = .(0x5731eaa0, 0x6bc2, 0x4681, 0xa5, 0x32, 0x92, 0xfb, 0xb7, 0x4d, 0x7c, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITfInputScope.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppEnumString) EnumWordList;
	}


	public HRESULT EnumWordList(IEnumString** ppEnumString) mut => VT.[Friend]EnumWordList(&this, ppEnumString);
}

[CRepr]struct ITfMSAAControl : IUnknown
{
	public new const Guid IID = .(0xb5f8fb3b, 0x393f, 0x4f7c, 0x84, 0xcb, 0x50, 0x49, 0x24, 0xc2, 0x70, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SystemEnableMSAA;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SystemDisableMSAA;
	}


	public HRESULT SystemEnableMSAA() mut => VT.[Friend]SystemEnableMSAA(&this);

	public HRESULT SystemDisableMSAA() mut => VT.[Friend]SystemDisableMSAA(&this);
}

[CRepr]struct IInternalDocWrap : IUnknown
{
	public new const Guid IID = .(0xe1aa6466, 0x9db4, 0x40ba, 0xbe, 0x03, 0x77, 0xc3, 0x8e, 0x8e, 0x60, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NotifyRevoke;
	}


	public HRESULT NotifyRevoke() mut => VT.[Friend]NotifyRevoke(&this);
}

[CRepr]struct ITextStoreACPEx : IUnknown
{
	public new const Guid IID = .(0xa2de3bc2, 0x3d8e, 0x11d3, 0x81, 0xa9, 0xf7, 0x53, 0xfb, 0xe6, 0x1a, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 acpStart, int32 acpEnd, RECT rc, uint32 dwPosition) ScrollToRect;
	}


	public HRESULT ScrollToRect(int32 acpStart, int32 acpEnd, RECT rc, uint32 dwPosition) mut => VT.[Friend]ScrollToRect(&this, acpStart, acpEnd, rc, dwPosition);
}

[CRepr]struct ITextStoreAnchorEx : IUnknown
{
	public new const Guid IID = .(0xa2de3bc1, 0x3d8e, 0x11d3, 0x81, 0xa9, 0xf7, 0x53, 0xfb, 0xe6, 0x1a, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAnchor* pStart, IAnchor* pEnd, RECT rc, uint32 dwPosition) ScrollToRect;
	}


	public HRESULT ScrollToRect(IAnchor* pStart, IAnchor* pEnd, RECT rc, uint32 dwPosition) mut => VT.[Friend]ScrollToRect(&this, pStart, pEnd, rc, dwPosition);
}

[CRepr]struct ITextStoreACPSinkEx : ITextStoreACPSink
{
	public new const Guid IID = .(0x2bdf9464, 0x41e2, 0x43e3, 0x95, 0x0c, 0xa6, 0x86, 0x5b, 0xa2, 0x5c, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextStoreACPSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnDisconnect;
	}


	public HRESULT OnDisconnect() mut => VT.[Friend]OnDisconnect(&this);
}

[CRepr]struct ITextStoreSinkAnchorEx : ITextStoreAnchorSink
{
	public new const Guid IID = .(0x25642426, 0x028d, 0x4474, 0x97, 0x7b, 0x11, 0x1b, 0xb1, 0x14, 0xfe, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITextStoreAnchorSink.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnDisconnect;
	}


	public HRESULT OnDisconnect() mut => VT.[Friend]OnDisconnect(&this);
}

[CRepr]struct IAccDictionary : IUnknown
{
	public new const Guid IID = .(0x1dc4cb5f, 0xd737, 0x474d, 0xad, 0xe9, 0x5c, 0xcf, 0xc9, 0xbc, 0x1c, 0xc9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Term, uint32 lcid, BSTR* pResult, uint32* plcid) GetLocalizedString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Term, Guid* pParentTerm) GetParentTerm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Term, BSTR* pResult) GetMnemonicString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMnemonic, Guid* pTerm) LookupMnemonicTerm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid Term, uint32 lcid, VARIANT varValue, BSTR* pbstrResult, uint32* plcid) ConvertValueToString;
	}


	public HRESULT GetLocalizedString(in Guid Term, uint32 lcid, BSTR* pResult, uint32* plcid) mut => VT.[Friend]GetLocalizedString(&this, Term, lcid, pResult, plcid);

	public HRESULT GetParentTerm(in Guid Term, Guid* pParentTerm) mut => VT.[Friend]GetParentTerm(&this, Term, pParentTerm);

	public HRESULT GetMnemonicString(in Guid Term, BSTR* pResult) mut => VT.[Friend]GetMnemonicString(&this, Term, pResult);

	public HRESULT LookupMnemonicTerm(BSTR bstrMnemonic, Guid* pTerm) mut => VT.[Friend]LookupMnemonicTerm(&this, bstrMnemonic, pTerm);

	public HRESULT ConvertValueToString(in Guid Term, uint32 lcid, VARIANT varValue, BSTR* pbstrResult, uint32* plcid) mut => VT.[Friend]ConvertValueToString(&this, Term, lcid, varValue, pbstrResult, plcid);
}

[CRepr]struct IVersionInfo : IUnknown
{
	public new const Guid IID = .(0x401518ec, 0xdb00, 0x4611, 0x9b, 0x29, 0x2a, 0x0e, 0x4b, 0x9a, 0xfa, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSub, uint32* ulCount) GetSubcomponentCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSub, Guid* implid) GetImplementationID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSub, uint32* pdwMajor, uint32* pdwMinor) GetBuildVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSub, BSTR* pImplStr) GetComponentDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulSub, BSTR* pImplStr) GetInstanceDescription;
	}


	public HRESULT GetSubcomponentCount(uint32 ulSub, uint32* ulCount) mut => VT.[Friend]GetSubcomponentCount(&this, ulSub, ulCount);

	public HRESULT GetImplementationID(uint32 ulSub, Guid* implid) mut => VT.[Friend]GetImplementationID(&this, ulSub, implid);

	public HRESULT GetBuildVersion(uint32 ulSub, uint32* pdwMajor, uint32* pdwMinor) mut => VT.[Friend]GetBuildVersion(&this, ulSub, pdwMajor, pdwMinor);

	public HRESULT GetComponentDescription(uint32 ulSub, BSTR* pImplStr) mut => VT.[Friend]GetComponentDescription(&this, ulSub, pImplStr);

	public HRESULT GetInstanceDescription(uint32 ulSub, BSTR* pImplStr) mut => VT.[Friend]GetInstanceDescription(&this, ulSub, pImplStr);
}

[CRepr]struct ICoCreateLocally : IUnknown
{
	public new const Guid IID = .(0x03de00aa, 0xf272, 0x41e3, 0x99, 0xcb, 0x03, 0xc5, 0xe8, 0x11, 0x4e, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid, uint32 dwClsContext, in Guid riid, IUnknown** punk, in Guid riidParam, IUnknown* punkParam, VARIANT varParam) CoCreateLocally;
	}


	public HRESULT CoCreateLocally(in Guid rclsid, uint32 dwClsContext, in Guid riid, IUnknown** punk, in Guid riidParam, IUnknown* punkParam, VARIANT varParam) mut => VT.[Friend]CoCreateLocally(&this, rclsid, dwClsContext, riid, punk, riidParam, punkParam, varParam);
}

[CRepr]struct ICoCreatedLocally : IUnknown
{
	public new const Guid IID = .(0x0a53eb6c, 0x1908, 0x4742, 0x8c, 0xff, 0x2c, 0xee, 0x2e, 0x93, 0xf9, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkLocalObject, in Guid riidParam, IUnknown* punkParam, VARIANT varParam) LocalInit;
	}


	public HRESULT LocalInit(IUnknown* punkLocalObject, in Guid riidParam, IUnknown* punkParam, VARIANT varParam) mut => VT.[Friend]LocalInit(&this, punkLocalObject, riidParam, punkParam, varParam);
}

[CRepr]struct IAccStore : IUnknown
{
	public new const Guid IID = .(0xe2cd4a63, 0x2b72, 0x4d48, 0xb7, 0x39, 0x95, 0xe4, 0x76, 0x51, 0x95, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) Unregister;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** enumUnknown) GetDocuments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, in Guid riid, IUnknown** ppunk) LookupByHWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt, in Guid riid, IUnknown** ppunk) LookupByPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) OnDocumentFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppunk) GetFocused;
	}


	public HRESULT Register(in Guid riid, IUnknown* punk) mut => VT.[Friend]Register(&this, riid, punk);

	public HRESULT Unregister(IUnknown* punk) mut => VT.[Friend]Unregister(&this, punk);

	public HRESULT GetDocuments(IEnumUnknown** enumUnknown) mut => VT.[Friend]GetDocuments(&this, enumUnknown);

	public HRESULT LookupByHWND(HWND hWnd, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]LookupByHWND(&this, hWnd, riid, ppunk);

	public HRESULT LookupByPoint(POINT pt, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]LookupByPoint(&this, pt, riid, ppunk);

	public HRESULT OnDocumentFocus(IUnknown* punk) mut => VT.[Friend]OnDocumentFocus(&this, punk);

	public HRESULT GetFocused(in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetFocused(&this, riid, ppunk);
}

[CRepr]struct IAccServerDocMgr : IUnknown
{
	public new const Guid IID = .(0xad7c73cf, 0x6dd5, 0x4855, 0xab, 0xc2, 0xb0, 0x4b, 0xad, 0x5b, 0x91, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk) NewDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) RevokeDocument;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) OnDocumentFocus;
	}


	public HRESULT NewDocument(in Guid riid, IUnknown* punk) mut => VT.[Friend]NewDocument(&this, riid, punk);

	public HRESULT RevokeDocument(IUnknown* punk) mut => VT.[Friend]RevokeDocument(&this, punk);

	public HRESULT OnDocumentFocus(IUnknown* punk) mut => VT.[Friend]OnDocumentFocus(&this, punk);
}

[CRepr]struct IAccClientDocMgr : IUnknown
{
	public new const Guid IID = .(0x4c896039, 0x7b6d, 0x49e6, 0xa8, 0xc1, 0x45, 0x11, 0x6a, 0x98, 0x29, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumUnknown** enumUnknown) GetDocuments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWnd, in Guid riid, IUnknown** ppunk) LookupByHWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt, in Guid riid, IUnknown** ppunk) LookupByPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppunk) GetFocused;
	}


	public HRESULT GetDocuments(IEnumUnknown** enumUnknown) mut => VT.[Friend]GetDocuments(&this, enumUnknown);

	public HRESULT LookupByHWND(HWND hWnd, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]LookupByHWND(&this, hWnd, riid, ppunk);

	public HRESULT LookupByPoint(POINT pt, in Guid riid, IUnknown** ppunk) mut => VT.[Friend]LookupByPoint(&this, pt, riid, ppunk);

	public HRESULT GetFocused(in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetFocused(&this, riid, ppunk);
}

[CRepr]struct IDocWrap : IUnknown
{
	public new const Guid IID = .(0xdcd285fe, 0x0be0, 0x43bd, 0x99, 0xc9, 0xaa, 0xae, 0xc5, 0x13, 0xc5, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown* punk) SetDoc;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IUnknown** ppunk) GetWrappedDoc;
	}


	public HRESULT SetDoc(in Guid riid, IUnknown* punk) mut => VT.[Friend]SetDoc(&this, riid, punk);

	public HRESULT GetWrappedDoc(in Guid riid, IUnknown** ppunk) mut => VT.[Friend]GetWrappedDoc(&this, riid, ppunk);
}

[CRepr]struct IClonableWrapper : IUnknown
{
	public new const Guid IID = .(0xb33e75ff, 0xe84c, 0x4dca, 0xa2, 0x5c, 0x33, 0xb8, 0xdc, 0x00, 0x33, 0x74);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) CloneNewWrapper;
	}


	public HRESULT CloneNewWrapper(in Guid riid, void** ppv) mut => VT.[Friend]CloneNewWrapper(&this, riid, ppv);
}

[CRepr]struct ITfSpeechUIServer : IUnknown
{
	public new const Guid IID = .(0x90e9a944, 0x9244, 0x489f, 0xa7, 0x8f, 0xde, 0x67, 0xaf, 0xc0, 0x13, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) ShowUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TfLBBalloonStyle style, char16* pch, uint32 cch) UpdateBalloon;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);

	public HRESULT ShowUI(BOOL fShow) mut => VT.[Friend]ShowUI(&this, fShow);

	public HRESULT UpdateBalloon(TfLBBalloonStyle style, char16* pch, uint32 cch) mut => VT.[Friend]UpdateBalloon(&this, style, pch, cch);
}

#endregion

#region Functions
public static
{
	[Import("MsCtfMonitor.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DoMsCtfMonitor(uint32 dwFlags, HANDLE hEventForServiceStop);

	[Import("MsCtfMonitor.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitLocalMsCtfMonitor(uint32 dwFlags);

	[Import("MsCtfMonitor.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UninitLocalMsCtfMonitor();

}
#endregion
