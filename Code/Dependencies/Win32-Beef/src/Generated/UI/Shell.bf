using Win32.Foundation;
using Win32.System.Com;
using Win32.System.Registry;
using Win32.Security;
using Win32.System.Threading;
using Win32.UI.WindowsAndMessaging;
using Win32.UI.Shell.Common;
using Win32.Graphics.Gdi;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Ole;
using Win32.UI.Controls;
using Win32.System.Com.StructuredStorage;
using Win32.System.SystemServices;
using Win32.Storage.FileSystem;
using Win32.System.Search;
using Win32.System.IO;
using Win32.Data.Xml.MsXml;
using Win32.System.Console;
using Win32.NetworkManagement.WNet;
using Win32.Graphics.DirectComposition;
using Win32.System.Com.Urlmon;
using System;

namespace Win32.UI.Shell;

#region Constants
public static
{
	public const HRESULT HLINK_E_FIRST = -2147221248;
	public const HRESULT HLINK_S_FIRST = 262400;
	public const uint32 WM_CPL_LAUNCH = 2024;
	public const uint32 WM_CPL_LAUNCHED = 2025;
	public const uint32 CPL_DYNAMIC_RES = 0;
	public const uint32 CPL_INIT = 1;
	public const uint32 CPL_GETCOUNT = 2;
	public const uint32 CPL_INQUIRE = 3;
	public const uint32 CPL_SELECT = 4;
	public const uint32 CPL_DBLCLK = 5;
	public const uint32 CPL_STOP = 6;
	public const uint32 CPL_EXIT = 7;
	public const uint32 CPL_NEWINQUIRE = 8;
	public const uint32 CPL_STARTWPARMSA = 9;
	public const uint32 CPL_STARTWPARMSW = 10;
	public const uint32 CPL_STARTWPARMS = 10;
	public const uint32 CPL_SETUP = 200;
	public const int32 HLINK_S_DONTHIDE = 262400;
	public const Guid FOLDERID_NetworkFolder = .(0xd20beec4, 0x5ca8, 0x4905, 0xae, 0x3b, 0xbf, 0x25, 0x1e, 0xa0, 0x9b, 0x53);
	public const Guid FOLDERID_ComputerFolder = .(0x0ac0837c, 0xbbf8, 0x452a, 0x85, 0x0d, 0x79, 0xd0, 0x8e, 0x66, 0x7c, 0xa7);
	public const Guid FOLDERID_InternetFolder = .(0x4d9f7874, 0x4e0c, 0x4904, 0x96, 0x7b, 0x40, 0xb0, 0xd2, 0x0c, 0x3e, 0x4b);
	public const Guid FOLDERID_ControlPanelFolder = .(0x82a74aeb, 0xaeb4, 0x465c, 0xa0, 0x14, 0xd0, 0x97, 0xee, 0x34, 0x6d, 0x63);
	public const Guid FOLDERID_PrintersFolder = .(0x76fc4e2d, 0xd6ad, 0x4519, 0xa6, 0x63, 0x37, 0xbd, 0x56, 0x06, 0x81, 0x85);
	public const Guid FOLDERID_SyncManagerFolder = .(0x43668bf8, 0xc14e, 0x49b2, 0x97, 0xc9, 0x74, 0x77, 0x84, 0xd7, 0x84, 0xb7);
	public const Guid FOLDERID_SyncSetupFolder = .(0x0f214138, 0xb1d3, 0x4a90, 0xbb, 0xa9, 0x27, 0xcb, 0xc0, 0xc5, 0x38, 0x9a);
	public const Guid FOLDERID_ConflictFolder = .(0x4bfefb45, 0x347d, 0x4006, 0xa5, 0xbe, 0xac, 0x0c, 0xb0, 0x56, 0x71, 0x92);
	public const Guid FOLDERID_SyncResultsFolder = .(0x289a9a43, 0xbe44, 0x4057, 0xa4, 0x1b, 0x58, 0x7a, 0x76, 0xd7, 0xe7, 0xf9);
	public const Guid FOLDERID_RecycleBinFolder = .(0xb7534046, 0x3ecb, 0x4c18, 0xbe, 0x4e, 0x64, 0xcd, 0x4c, 0xb7, 0xd6, 0xac);
	public const Guid FOLDERID_ConnectionsFolder = .(0x6f0cd92b, 0x2e97, 0x45d1, 0x88, 0xff, 0xb0, 0xd1, 0x86, 0xb8, 0xde, 0xdd);
	public const Guid FOLDERID_Fonts = .(0xfd228cb7, 0xae11, 0x4ae3, 0x86, 0x4c, 0x16, 0xf3, 0x91, 0x0a, 0xb8, 0xfe);
	public const Guid FOLDERID_Desktop = .(0xb4bfcc3a, 0xdb2c, 0x424c, 0xb0, 0x29, 0x7f, 0xe9, 0x9a, 0x87, 0xc6, 0x41);
	public const Guid FOLDERID_Startup = .(0xb97d20bb, 0xf46a, 0x4c97, 0xba, 0x10, 0x5e, 0x36, 0x08, 0x43, 0x08, 0x54);
	public const Guid FOLDERID_Programs = .(0xa77f5d77, 0x2e2b, 0x44c3, 0xa6, 0xa2, 0xab, 0xa6, 0x01, 0x05, 0x4a, 0x51);
	public const Guid FOLDERID_StartMenu = .(0x625b53c3, 0xab48, 0x4ec1, 0xba, 0x1f, 0xa1, 0xef, 0x41, 0x46, 0xfc, 0x19);
	public const Guid FOLDERID_Recent = .(0xae50c081, 0xebd2, 0x438a, 0x86, 0x55, 0x8a, 0x09, 0x2e, 0x34, 0x98, 0x7a);
	public const Guid FOLDERID_SendTo = .(0x8983036c, 0x27c0, 0x404b, 0x8f, 0x08, 0x10, 0x2d, 0x10, 0xdc, 0xfd, 0x74);
	public const Guid FOLDERID_Documents = .(0xfdd39ad0, 0x238f, 0x46af, 0xad, 0xb4, 0x6c, 0x85, 0x48, 0x03, 0x69, 0xc7);
	public const Guid FOLDERID_Favorites = .(0x1777f761, 0x68ad, 0x4d8a, 0x87, 0xbd, 0x30, 0xb7, 0x59, 0xfa, 0x33, 0xdd);
	public const Guid FOLDERID_NetHood = .(0xc5abbf53, 0xe17f, 0x4121, 0x89, 0x00, 0x86, 0x62, 0x6f, 0xc2, 0xc9, 0x73);
	public const Guid FOLDERID_PrintHood = .(0x9274bd8d, 0xcfd1, 0x41c3, 0xb3, 0x5e, 0xb1, 0x3f, 0x55, 0xa7, 0x58, 0xf4);
	public const Guid FOLDERID_Templates = .(0xa63293e8, 0x664e, 0x48db, 0xa0, 0x79, 0xdf, 0x75, 0x9e, 0x05, 0x09, 0xf7);
	public const Guid FOLDERID_CommonStartup = .(0x82a5ea35, 0xd9cd, 0x47c5, 0x96, 0x29, 0xe1, 0x5d, 0x2f, 0x71, 0x4e, 0x6e);
	public const Guid FOLDERID_CommonPrograms = .(0x0139d44e, 0x6afe, 0x49f2, 0x86, 0x90, 0x3d, 0xaf, 0xca, 0xe6, 0xff, 0xb8);
	public const Guid FOLDERID_CommonStartMenu = .(0xa4115719, 0xd62e, 0x491d, 0xaa, 0x7c, 0xe7, 0x4b, 0x8b, 0xe3, 0xb0, 0x67);
	public const Guid FOLDERID_PublicDesktop = .(0xc4aa340d, 0xf20f, 0x4863, 0xaf, 0xef, 0xf8, 0x7e, 0xf2, 0xe6, 0xba, 0x25);
	public const Guid FOLDERID_ProgramData = .(0x62ab5d82, 0xfdc1, 0x4dc3, 0xa9, 0xdd, 0x07, 0x0d, 0x1d, 0x49, 0x5d, 0x97);
	public const Guid FOLDERID_CommonTemplates = .(0xb94237e7, 0x57ac, 0x4347, 0x91, 0x51, 0xb0, 0x8c, 0x6c, 0x32, 0xd1, 0xf7);
	public const Guid FOLDERID_PublicDocuments = .(0xed4824af, 0xdce4, 0x45a8, 0x81, 0xe2, 0xfc, 0x79, 0x65, 0x08, 0x36, 0x34);
	public const Guid FOLDERID_RoamingAppData = .(0x3eb685db, 0x65f9, 0x4cf6, 0xa0, 0x3a, 0xe3, 0xef, 0x65, 0x72, 0x9f, 0x3d);
	public const Guid FOLDERID_LocalAppData = .(0xf1b32785, 0x6fba, 0x4fcf, 0x9d, 0x55, 0x7b, 0x8e, 0x7f, 0x15, 0x70, 0x91);
	public const Guid FOLDERID_LocalAppDataLow = .(0xa520a1a4, 0x1780, 0x4ff6, 0xbd, 0x18, 0x16, 0x73, 0x43, 0xc5, 0xaf, 0x16);
	public const Guid FOLDERID_InternetCache = .(0x352481e8, 0x33be, 0x4251, 0xba, 0x85, 0x60, 0x07, 0xca, 0xed, 0xcf, 0x9d);
	public const Guid FOLDERID_Cookies = .(0x2b0f765d, 0xc0e9, 0x4171, 0x90, 0x8e, 0x08, 0xa6, 0x11, 0xb8, 0x4f, 0xf6);
	public const Guid FOLDERID_History = .(0xd9dc8a3b, 0xb784, 0x432e, 0xa7, 0x81, 0x5a, 0x11, 0x30, 0xa7, 0x59, 0x63);
	public const Guid FOLDERID_System = .(0x1ac14e77, 0x02e7, 0x4e5d, 0xb7, 0x44, 0x2e, 0xb1, 0xae, 0x51, 0x98, 0xb7);
	public const Guid FOLDERID_SystemX86 = .(0xd65231b0, 0xb2f1, 0x4857, 0xa4, 0xce, 0xa8, 0xe7, 0xc6, 0xea, 0x7d, 0x27);
	public const Guid FOLDERID_Windows = .(0xf38bf404, 0x1d43, 0x42f2, 0x93, 0x05, 0x67, 0xde, 0x0b, 0x28, 0xfc, 0x23);
	public const Guid FOLDERID_Profile = .(0x5e6c858f, 0x0e22, 0x4760, 0x9a, 0xfe, 0xea, 0x33, 0x17, 0xb6, 0x71, 0x73);
	public const Guid FOLDERID_Pictures = .(0x33e28130, 0x4e1e, 0x4676, 0x83, 0x5a, 0x98, 0x39, 0x5c, 0x3b, 0xc3, 0xbb);
	public const Guid FOLDERID_ProgramFilesX86 = .(0x7c5a40ef, 0xa0fb, 0x4bfc, 0x87, 0x4a, 0xc0, 0xf2, 0xe0, 0xb9, 0xfa, 0x8e);
	public const Guid FOLDERID_ProgramFilesCommonX86 = .(0xde974d24, 0xd9c6, 0x4d3e, 0xbf, 0x91, 0xf4, 0x45, 0x51, 0x20, 0xb9, 0x17);
	public const Guid FOLDERID_ProgramFilesX64 = .(0x6d809377, 0x6af0, 0x444b, 0x89, 0x57, 0xa3, 0x77, 0x3f, 0x02, 0x20, 0x0e);
	public const Guid FOLDERID_ProgramFilesCommonX64 = .(0x6365d5a7, 0x0f0d, 0x45e5, 0x87, 0xf6, 0x0d, 0xa5, 0x6b, 0x6a, 0x4f, 0x7d);
	public const Guid FOLDERID_ProgramFiles = .(0x905e63b6, 0xc1bf, 0x494e, 0xb2, 0x9c, 0x65, 0xb7, 0x32, 0xd3, 0xd2, 0x1a);
	public const Guid FOLDERID_ProgramFilesCommon = .(0xf7f1ed05, 0x9f6d, 0x47a2, 0xaa, 0xae, 0x29, 0xd3, 0x17, 0xc6, 0xf0, 0x66);
	public const Guid FOLDERID_UserProgramFiles = .(0x5cd7aee2, 0x2219, 0x4a67, 0xb8, 0x5d, 0x6c, 0x9c, 0xe1, 0x56, 0x60, 0xcb);
	public const Guid FOLDERID_UserProgramFilesCommon = .(0xbcbd3057, 0xca5c, 0x4622, 0xb4, 0x2d, 0xbc, 0x56, 0xdb, 0x0a, 0xe5, 0x16);
	public const Guid FOLDERID_AdminTools = .(0x724ef170, 0xa42d, 0x4fef, 0x9f, 0x26, 0xb6, 0x0e, 0x84, 0x6f, 0xba, 0x4f);
	public const Guid FOLDERID_CommonAdminTools = .(0xd0384e7d, 0xbac3, 0x4797, 0x8f, 0x14, 0xcb, 0xa2, 0x29, 0xb3, 0x92, 0xb5);
	public const Guid FOLDERID_Music = .(0x4bd8d571, 0x6d19, 0x48d3, 0xbe, 0x97, 0x42, 0x22, 0x20, 0x08, 0x0e, 0x43);
	public const Guid FOLDERID_Videos = .(0x18989b1d, 0x99b5, 0x455b, 0x84, 0x1c, 0xab, 0x7c, 0x74, 0xe4, 0xdd, 0xfc);
	public const Guid FOLDERID_Ringtones = .(0xc870044b, 0xf49e, 0x4126, 0xa9, 0xc3, 0xb5, 0x2a, 0x1f, 0xf4, 0x11, 0xe8);
	public const Guid FOLDERID_PublicPictures = .(0xb6ebfb86, 0x6907, 0x413c, 0x9a, 0xf7, 0x4f, 0xc2, 0xab, 0xf0, 0x7c, 0xc5);
	public const Guid FOLDERID_PublicMusic = .(0x3214fab5, 0x9757, 0x4298, 0xbb, 0x61, 0x92, 0xa9, 0xde, 0xaa, 0x44, 0xff);
	public const Guid FOLDERID_PublicVideos = .(0x2400183a, 0x6185, 0x49fb, 0xa2, 0xd8, 0x4a, 0x39, 0x2a, 0x60, 0x2b, 0xa3);
	public const Guid FOLDERID_PublicRingtones = .(0xe555ab60, 0x153b, 0x4d17, 0x9f, 0x04, 0xa5, 0xfe, 0x99, 0xfc, 0x15, 0xec);
	public const Guid FOLDERID_ResourceDir = .(0x8ad10c31, 0x2adb, 0x4296, 0xa8, 0xf7, 0xe4, 0x70, 0x12, 0x32, 0xc9, 0x72);
	public const Guid FOLDERID_LocalizedResourcesDir = .(0x2a00375e, 0x224c, 0x49de, 0xb8, 0xd1, 0x44, 0x0d, 0xf7, 0xef, 0x3d, 0xdc);
	public const Guid FOLDERID_CommonOEMLinks = .(0xc1bae2d0, 0x10df, 0x4334, 0xbe, 0xdd, 0x7a, 0xa2, 0x0b, 0x22, 0x7a, 0x9d);
	public const Guid FOLDERID_CDBurning = .(0x9e52ab10, 0xf80d, 0x49df, 0xac, 0xb8, 0x43, 0x30, 0xf5, 0x68, 0x78, 0x55);
	public const Guid FOLDERID_UserProfiles = .(0x0762d272, 0xc50a, 0x4bb0, 0xa3, 0x82, 0x69, 0x7d, 0xcd, 0x72, 0x9b, 0x80);
	public const Guid FOLDERID_Playlists = .(0xde92c1c7, 0x837f, 0x4f69, 0xa3, 0xbb, 0x86, 0xe6, 0x31, 0x20, 0x4a, 0x23);
	public const Guid FOLDERID_SamplePlaylists = .(0x15ca69b3, 0x30ee, 0x49c1, 0xac, 0xe1, 0x6b, 0x5e, 0xc3, 0x72, 0xaf, 0xb5);
	public const Guid FOLDERID_SampleMusic = .(0xb250c668, 0xf57d, 0x4ee1, 0xa6, 0x3c, 0x29, 0x0e, 0xe7, 0xd1, 0xaa, 0x1f);
	public const Guid FOLDERID_SamplePictures = .(0xc4900540, 0x2379, 0x4c75, 0x84, 0x4b, 0x64, 0xe6, 0xfa, 0xf8, 0x71, 0x6b);
	public const Guid FOLDERID_SampleVideos = .(0x859ead94, 0x2e85, 0x48ad, 0xa7, 0x1a, 0x09, 0x69, 0xcb, 0x56, 0xa6, 0xcd);
	public const Guid FOLDERID_PhotoAlbums = .(0x69d2cf90, 0xfc33, 0x4fb7, 0x9a, 0x0c, 0xeb, 0xb0, 0xf0, 0xfc, 0xb4, 0x3c);
	public const Guid FOLDERID_Public = .(0xdfdf76a2, 0xc82a, 0x4d63, 0x90, 0x6a, 0x56, 0x44, 0xac, 0x45, 0x73, 0x85);
	public const Guid FOLDERID_ChangeRemovePrograms = .(0xdf7266ac, 0x9274, 0x4867, 0x8d, 0x55, 0x3b, 0xd6, 0x61, 0xde, 0x87, 0x2d);
	public const Guid FOLDERID_AppUpdates = .(0xa305ce99, 0xf527, 0x492b, 0x8b, 0x1a, 0x7e, 0x76, 0xfa, 0x98, 0xd6, 0xe4);
	public const Guid FOLDERID_AddNewPrograms = .(0xde61d971, 0x5ebc, 0x4f02, 0xa3, 0xa9, 0x6c, 0x82, 0x89, 0x5e, 0x5c, 0x04);
	public const Guid FOLDERID_Downloads = .(0x374de290, 0x123f, 0x4565, 0x91, 0x64, 0x39, 0xc4, 0x92, 0x5e, 0x46, 0x7b);
	public const Guid FOLDERID_PublicDownloads = .(0x3d644c9b, 0x1fb8, 0x4f30, 0x9b, 0x45, 0xf6, 0x70, 0x23, 0x5f, 0x79, 0xc0);
	public const Guid FOLDERID_SavedSearches = .(0x7d1d3a04, 0xdebb, 0x4115, 0x95, 0xcf, 0x2f, 0x29, 0xda, 0x29, 0x20, 0xda);
	public const Guid FOLDERID_QuickLaunch = .(0x52a4f021, 0x7b75, 0x48a9, 0x9f, 0x6b, 0x4b, 0x87, 0xa2, 0x10, 0xbc, 0x8f);
	public const Guid FOLDERID_Contacts = .(0x56784854, 0xc6cb, 0x462b, 0x81, 0x69, 0x88, 0xe3, 0x50, 0xac, 0xb8, 0x82);
	public const Guid FOLDERID_SidebarParts = .(0xa75d362e, 0x50fc, 0x4fb7, 0xac, 0x2c, 0xa8, 0xbe, 0xaa, 0x31, 0x44, 0x93);
	public const Guid FOLDERID_SidebarDefaultParts = .(0x7b396e54, 0x9ec5, 0x4300, 0xbe, 0x0a, 0x24, 0x82, 0xeb, 0xae, 0x1a, 0x26);
	public const Guid FOLDERID_PublicGameTasks = .(0xdebf2536, 0xe1a8, 0x4c59, 0xb6, 0xa2, 0x41, 0x45, 0x86, 0x47, 0x6a, 0xea);
	public const Guid FOLDERID_GameTasks = .(0x054fae61, 0x4dd8, 0x4787, 0x80, 0xb6, 0x09, 0x02, 0x20, 0xc4, 0xb7, 0x00);
	public const Guid FOLDERID_SavedGames = .(0x4c5c32ff, 0xbb9d, 0x43b0, 0xb5, 0xb4, 0x2d, 0x72, 0xe5, 0x4e, 0xaa, 0xa4);
	public const Guid FOLDERID_Games = .(0xcac52c1a, 0xb53d, 0x4edc, 0x92, 0xd7, 0x6b, 0x2e, 0x8a, 0xc1, 0x94, 0x34);
	public const Guid FOLDERID_SEARCH_MAPI = .(0x98ec0e18, 0x2098, 0x4d44, 0x86, 0x44, 0x66, 0x97, 0x93, 0x15, 0xa2, 0x81);
	public const Guid FOLDERID_SEARCH_CSC = .(0xee32e446, 0x31ca, 0x4aba, 0x81, 0x4f, 0xa5, 0xeb, 0xd2, 0xfd, 0x6d, 0x5e);
	public const Guid FOLDERID_Links = .(0xbfb9d5e0, 0xc6a9, 0x404c, 0xb2, 0xb2, 0xae, 0x6d, 0xb6, 0xaf, 0x49, 0x68);
	public const Guid FOLDERID_UsersFiles = .(0xf3ce0f7c, 0x4901, 0x4acc, 0x86, 0x48, 0xd5, 0xd4, 0x4b, 0x04, 0xef, 0x8f);
	public const Guid FOLDERID_UsersLibraries = .(0xa302545d, 0xdeff, 0x464b, 0xab, 0xe8, 0x61, 0xc8, 0x64, 0x8d, 0x93, 0x9b);
	public const Guid FOLDERID_SearchHome = .(0x190337d1, 0xb8ca, 0x4121, 0xa6, 0x39, 0x6d, 0x47, 0x2d, 0x16, 0x97, 0x2a);
	public const Guid FOLDERID_OriginalImages = .(0x2c36c0aa, 0x5812, 0x4b87, 0xbf, 0xd0, 0x4c, 0xd0, 0xdf, 0xb1, 0x9b, 0x39);
	public const Guid FOLDERID_DocumentsLibrary = .(0x7b0db17d, 0x9cd2, 0x4a93, 0x97, 0x33, 0x46, 0xcc, 0x89, 0x02, 0x2e, 0x7c);
	public const Guid FOLDERID_MusicLibrary = .(0x2112ab0a, 0xc86a, 0x4ffe, 0xa3, 0x68, 0x0d, 0xe9, 0x6e, 0x47, 0x01, 0x2e);
	public const Guid FOLDERID_PicturesLibrary = .(0xa990ae9f, 0xa03b, 0x4e80, 0x94, 0xbc, 0x99, 0x12, 0xd7, 0x50, 0x41, 0x04);
	public const Guid FOLDERID_VideosLibrary = .(0x491e922f, 0x5643, 0x4af4, 0xa7, 0xeb, 0x4e, 0x7a, 0x13, 0x8d, 0x81, 0x74);
	public const Guid FOLDERID_RecordedTVLibrary = .(0x1a6fdba2, 0xf42d, 0x4358, 0xa7, 0x98, 0xb7, 0x4d, 0x74, 0x59, 0x26, 0xc5);
	public const Guid FOLDERID_HomeGroup = .(0x52528a6b, 0xb9e3, 0x4add, 0xb6, 0x0d, 0x58, 0x8c, 0x2d, 0xba, 0x84, 0x2d);
	public const Guid FOLDERID_HomeGroupCurrentUser = .(0x9b74b6a3, 0x0dfd, 0x4f11, 0x9e, 0x78, 0x5f, 0x78, 0x00, 0xf2, 0xe7, 0x72);
	public const Guid FOLDERID_DeviceMetadataStore = .(0x5ce4a5e9, 0xe4eb, 0x479d, 0xb8, 0x9f, 0x13, 0x0c, 0x02, 0x88, 0x61, 0x55);
	public const Guid FOLDERID_Libraries = .(0x1b3ea5dc, 0xb587, 0x4786, 0xb4, 0xef, 0xbd, 0x1d, 0xc3, 0x32, 0xae, 0xae);
	public const Guid FOLDERID_PublicLibraries = .(0x48daf80b, 0xe6cf, 0x4f4e, 0xb8, 0x00, 0x0e, 0x69, 0xd8, 0x4e, 0xe3, 0x84);
	public const Guid FOLDERID_UserPinned = .(0x9e3995ab, 0x1f9c, 0x4f13, 0xb8, 0x27, 0x48, 0xb2, 0x4b, 0x6c, 0x71, 0x74);
	public const Guid FOLDERID_ImplicitAppShortcuts = .(0xbcb5256f, 0x79f6, 0x4cee, 0xb7, 0x25, 0xdc, 0x34, 0xe4, 0x02, 0xfd, 0x46);
	public const Guid FOLDERID_AccountPictures = .(0x008ca0b1, 0x55b4, 0x4c56, 0xb8, 0xa8, 0x4d, 0xe4, 0xb2, 0x99, 0xd3, 0xbe);
	public const Guid FOLDERID_PublicUserTiles = .(0x0482af6c, 0x08f1, 0x4c34, 0x8c, 0x90, 0xe1, 0x7e, 0xc9, 0x8b, 0x1e, 0x17);
	public const Guid FOLDERID_AppsFolder = .(0x1e87508d, 0x89c2, 0x42f0, 0x8a, 0x7e, 0x64, 0x5a, 0x0f, 0x50, 0xca, 0x58);
	public const Guid FOLDERID_StartMenuAllPrograms = .(0xf26305ef, 0x6948, 0x40b9, 0xb2, 0x55, 0x81, 0x45, 0x3d, 0x09, 0xc7, 0x85);
	public const Guid FOLDERID_CommonStartMenuPlaces = .(0xa440879f, 0x87a0, 0x4f7d, 0xb7, 0x00, 0x02, 0x07, 0xb9, 0x66, 0x19, 0x4a);
	public const Guid FOLDERID_ApplicationShortcuts = .(0xa3918781, 0xe5f2, 0x4890, 0xb3, 0xd9, 0xa7, 0xe5, 0x43, 0x32, 0x32, 0x8c);
	public const Guid FOLDERID_RoamingTiles = .(0x00bcfc5a, 0xed94, 0x4e48, 0x96, 0xa1, 0x3f, 0x62, 0x17, 0xf2, 0x19, 0x90);
	public const Guid FOLDERID_RoamedTileImages = .(0xaaa8d5a5, 0xf1d6, 0x4259, 0xba, 0xa8, 0x78, 0xe7, 0xef, 0x60, 0x83, 0x5e);
	public const Guid FOLDERID_Screenshots = .(0xb7bede81, 0xdf94, 0x4682, 0xa7, 0xd8, 0x57, 0xa5, 0x26, 0x20, 0xb8, 0x6f);
	public const Guid FOLDERID_CameraRoll = .(0xab5fb87b, 0x7ce2, 0x4f83, 0x91, 0x5d, 0x55, 0x08, 0x46, 0xc9, 0x53, 0x7b);
	public const Guid FOLDERID_SkyDrive = .(0xa52bba46, 0xe9e1, 0x435f, 0xb3, 0xd9, 0x28, 0xda, 0xa6, 0x48, 0xc0, 0xf6);
	public const Guid FOLDERID_OneDrive = .(0xa52bba46, 0xe9e1, 0x435f, 0xb3, 0xd9, 0x28, 0xda, 0xa6, 0x48, 0xc0, 0xf6);
	public const Guid FOLDERID_SkyDriveDocuments = .(0x24d89e24, 0x2f19, 0x4534, 0x9d, 0xde, 0x6a, 0x66, 0x71, 0xfb, 0xb8, 0xfe);
	public const Guid FOLDERID_SkyDrivePictures = .(0x339719b5, 0x8c47, 0x4894, 0x94, 0xc2, 0xd8, 0xf7, 0x7a, 0xdd, 0x44, 0xa6);
	public const Guid FOLDERID_SkyDriveMusic = .(0xc3f2459e, 0x80d6, 0x45dc, 0xbf, 0xef, 0x1f, 0x76, 0x9f, 0x2b, 0xe7, 0x30);
	public const Guid FOLDERID_SkyDriveCameraRoll = .(0x767e6811, 0x49cb, 0x4273, 0x87, 0xc2, 0x20, 0xf3, 0x55, 0xe1, 0x08, 0x5b);
	public const Guid FOLDERID_SearchHistory = .(0x0d4c3db6, 0x03a3, 0x462f, 0xa0, 0xe6, 0x08, 0x92, 0x4c, 0x41, 0xb5, 0xd4);
	public const Guid FOLDERID_SearchTemplates = .(0x7e636bfe, 0xdfa9, 0x4d5e, 0xb4, 0x56, 0xd7, 0xb3, 0x98, 0x51, 0xd8, 0xa9);
	public const Guid FOLDERID_CameraRollLibrary = .(0x2b20df75, 0x1eda, 0x4039, 0x80, 0x97, 0x38, 0x79, 0x82, 0x27, 0xd5, 0xb7);
	public const Guid FOLDERID_SavedPictures = .(0x3b193882, 0xd3ad, 0x4eab, 0x96, 0x5a, 0x69, 0x82, 0x9d, 0x1f, 0xb5, 0x9f);
	public const Guid FOLDERID_SavedPicturesLibrary = .(0xe25b5812, 0xbe88, 0x4bd9, 0x94, 0xb0, 0x29, 0x23, 0x34, 0x77, 0xb6, 0xc3);
	public const Guid FOLDERID_RetailDemo = .(0x12d4c69e, 0x24ad, 0x4923, 0xbe, 0x19, 0x31, 0x32, 0x1c, 0x43, 0xa7, 0x67);
	public const Guid FOLDERID_Device = .(0x1c2ac1dc, 0x4358, 0x4b6c, 0x97, 0x33, 0xaf, 0x21, 0x15, 0x65, 0x76, 0xf0);
	public const Guid FOLDERID_DevelopmentFiles = .(0xdbe8e08e, 0x3053, 0x4bbc, 0xb1, 0x83, 0x2a, 0x7b, 0x2b, 0x19, 0x1e, 0x59);
	public const Guid FOLDERID_Objects3D = .(0x31c0dd25, 0x9439, 0x4f12, 0xbf, 0x41, 0x7f, 0xf4, 0xed, 0xa3, 0x87, 0x22);
	public const Guid FOLDERID_AppCaptures = .(0xedc0fe71, 0x98d8, 0x4f4a, 0xb9, 0x20, 0xc8, 0xdc, 0x13, 0x3c, 0xb1, 0x65);
	public const Guid FOLDERID_LocalDocuments = .(0xf42ee2d3, 0x909f, 0x4907, 0x88, 0x71, 0x4c, 0x22, 0xfc, 0x0b, 0xf7, 0x56);
	public const Guid FOLDERID_LocalPictures = .(0x0ddd015d, 0xb06c, 0x45d5, 0x8c, 0x4c, 0xf5, 0x97, 0x13, 0x85, 0x46, 0x39);
	public const Guid FOLDERID_LocalVideos = .(0x35286a68, 0x3c57, 0x41a1, 0xbb, 0xb1, 0x0e, 0xae, 0x73, 0xd7, 0x6c, 0x95);
	public const Guid FOLDERID_LocalMusic = .(0xa0c69a99, 0x21c8, 0x4671, 0x87, 0x03, 0x79, 0x34, 0x16, 0x2f, 0xcf, 0x1d);
	public const Guid FOLDERID_LocalDownloads = .(0x7d83ee9b, 0x2244, 0x4e70, 0xb1, 0xf5, 0x53, 0x93, 0x04, 0x2a, 0xf1, 0xe4);
	public const Guid FOLDERID_RecordedCalls = .(0x2f8b40c2, 0x83ed, 0x48ee, 0xb3, 0x83, 0xa1, 0xf1, 0x57, 0xec, 0x6f, 0x9a);
	public const Guid FOLDERID_AllAppMods = .(0x7ad67899, 0x66af, 0x43ba, 0x91, 0x56, 0x6a, 0xad, 0x42, 0xe6, 0xc5, 0x96);
	public const Guid FOLDERID_CurrentAppMods = .(0x3db40b20, 0x2a30, 0x4dbe, 0x91, 0x7e, 0x77, 0x1d, 0xd2, 0x1d, 0xd0, 0x99);
	public const Guid FOLDERID_AppDataDesktop = .(0xb2c5e279, 0x7add, 0x439f, 0xb2, 0x8c, 0xc4, 0x1f, 0xe1, 0xbb, 0xf6, 0x72);
	public const Guid FOLDERID_AppDataDocuments = .(0x7be16610, 0x1f7f, 0x44ac, 0xbf, 0xf0, 0x83, 0xe1, 0x5f, 0x2f, 0xfc, 0xa1);
	public const Guid FOLDERID_AppDataFavorites = .(0x7cfbefbc, 0xde1f, 0x45aa, 0xb8, 0x43, 0xa5, 0x42, 0xac, 0x53, 0x6c, 0xc9);
	public const Guid FOLDERID_AppDataProgramData = .(0x559d40a3, 0xa036, 0x40fa, 0xaf, 0x61, 0x84, 0xcb, 0x43, 0x0a, 0x4d, 0x34);
	public const Guid FOLDERID_LocalStorage = .(0xb3eb08d3, 0xa1f3, 0x496b, 0x86, 0x5a, 0x42, 0xb5, 0x36, 0xcd, 0xa0, 0xec);
	public const Guid CLSID_InternetShortcut = .(0xfbf23b40, 0xe3f0, 0x101b, 0x84, 0x88, 0x00, 0xaa, 0x00, 0x3e, 0x56, 0xf8);
	public const Guid CLSID_NetworkDomain = .(0x46e06680, 0x4bf0, 0x11d1, 0x83, 0xee, 0x00, 0xa0, 0xc9, 0x0d, 0xc8, 0x49);
	public const Guid CLSID_NetworkServer = .(0xc0542a90, 0x4bf0, 0x11d1, 0x83, 0xee, 0x00, 0xa0, 0xc9, 0x0d, 0xc8, 0x49);
	public const Guid CLSID_NetworkShare = .(0x54a754c0, 0x4bf0, 0x11d1, 0x83, 0xee, 0x00, 0xa0, 0xc9, 0x0d, 0xc8, 0x49);
	public const Guid CLSID_MyComputer = .(0x20d04fe0, 0x3aea, 0x1069, 0xa2, 0xd8, 0x08, 0x00, 0x2b, 0x30, 0x30, 0x9d);
	public const Guid CLSID_Internet = .(0x871c5380, 0x42a0, 0x1069, 0xa2, 0xea, 0x08, 0x00, 0x2b, 0x30, 0x30, 0x9d);
	public const Guid CLSID_RecycleBin = .(0x645ff040, 0x5081, 0x101b, 0x9f, 0x08, 0x00, 0xaa, 0x00, 0x2f, 0x95, 0x4e);
	public const Guid CLSID_ControlPanel = .(0x21ec2020, 0x3aea, 0x1069, 0xa2, 0xdd, 0x08, 0x00, 0x2b, 0x30, 0x30, 0x9d);
	public const Guid CLSID_Printers = .(0x2227a280, 0x3aea, 0x1069, 0xa2, 0xde, 0x08, 0x00, 0x2b, 0x30, 0x30, 0x9d);
	public const Guid CLSID_MyDocuments = .(0x450d8fba, 0xad25, 0x11d0, 0x98, 0xa8, 0x08, 0x00, 0x36, 0x1b, 0x11, 0x03);
	public const String STR_MYDOCS_CLSID = "{450D8FBA-AD25-11D0-98A8-0800361B1103}";
	public const Guid CATID_BrowsableShellExt = .(0x00021490, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CATID_BrowseInPlace = .(0x00021491, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CATID_DeskBand = .(0x00021492, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CATID_InfoBand = .(0x00021493, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CATID_CommBand = .(0x00021494, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid FMTID_Intshcut = .(0x000214a0, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid FMTID_InternetSite = .(0x000214a1, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CGID_Explorer = .(0x000214d0, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CGID_ShellDocView = .(0x000214d1, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CGID_ShellServiceObject = .(0x000214d2, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CGID_ExplorerBarDoc = .(0x000214d3, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);
	public const Guid CLSID_FolderShortcut = .(0x0afaced1, 0xe828, 0x11d1, 0x91, 0x87, 0xb5, 0x32, 0xf1, 0xe9, 0x57, 0x5d);
	public const Guid CLSID_CFSIconOverlayManager = .(0x63b51f81, 0xc868, 0x11d0, 0x99, 0x9c, 0x00, 0xc0, 0x4f, 0xd6, 0x55, 0xe1);
	public const Guid CLSID_ShellThumbnailDiskCache = .(0x1ebdcf80, 0xa200, 0x11d0, 0xa3, 0xa4, 0x00, 0xc0, 0x4f, 0xd7, 0x06, 0xec);
	public const Guid SID_DefView = .(0x6d12fe80, 0x7911, 0x11cf, 0x95, 0x34, 0x00, 0x00, 0xc0, 0x5b, 0xae, 0x0b);
	public const Guid CGID_DefView = .(0x4af07f10, 0xd231, 0x11d0, 0xb9, 0x42, 0x00, 0xa0, 0xc9, 0x03, 0x12, 0xe1);
	public const Guid CLSID_MenuBand = .(0x5b4dae26, 0xb807, 0x11d0, 0x98, 0x15, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0x72);
	public const Guid VID_LargeIcons = .(0x0057d0e0, 0x3573, 0x11cf, 0xae, 0x69, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);
	public const Guid VID_SmallIcons = .(0x089000c0, 0x3573, 0x11cf, 0xae, 0x69, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);
	public const Guid VID_List = .(0x0e1fa5e0, 0x3573, 0x11cf, 0xae, 0x69, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);
	public const Guid VID_Details = .(0x137e7700, 0x3573, 0x11cf, 0xae, 0x69, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);
	public const Guid VID_Tile = .(0x65f125e5, 0x7be1, 0x4810, 0xba, 0x9d, 0xd2, 0x71, 0xc8, 0x43, 0x2c, 0xe3);
	public const Guid VID_Content = .(0x30c2c434, 0x0889, 0x4c8d, 0x98, 0x5d, 0xa9, 0xf7, 0x18, 0x30, 0xb0, 0xa9);
	public const Guid VID_Thumbnails = .(0x8bebb290, 0x52d0, 0x11d0, 0xb7, 0xf4, 0x00, 0xc0, 0x4f, 0xd7, 0x06, 0xec);
	public const Guid VID_ThumbStrip = .(0x8eefa624, 0xd1e9, 0x445b, 0x94, 0xb7, 0x74, 0xfb, 0xce, 0x2e, 0xa1, 0x1a);
	public const Guid SID_SInPlaceBrowser = .(0x1d2ae02b, 0x3655, 0x46cc, 0xb6, 0x3a, 0x28, 0x59, 0x88, 0x15, 0x3b, 0xca);
	public const Guid SID_SSearchBoxInfo = .(0x142daa61, 0x516b, 0x4713, 0xb4, 0x9c, 0xfb, 0x98, 0x5e, 0xf8, 0x29, 0x98);
	public const Guid SID_CommandsPropertyBag = .(0x6e043250, 0x4416, 0x485c, 0xb1, 0x43, 0xe6, 0x2a, 0x76, 0x0d, 0x9f, 0xe5);
	public const Guid CLSID_CUrlHistory = .(0x3c374a40, 0xbae4, 0x11cf, 0xbf, 0x7d, 0x00, 0xaa, 0x00, 0x69, 0x46, 0xee);
	public const Guid CLSID_CURLSearchHook = .(0xcfbfae00, 0x17a6, 0x11d0, 0x99, 0xcb, 0x00, 0xc0, 0x4f, 0xd6, 0x44, 0x97);
	public const Guid CLSID_AutoComplete = .(0x00bb2763, 0x6a77, 0x11d0, 0xa5, 0x35, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);
	public const Guid CLSID_ACLHistory = .(0x00bb2764, 0x6a77, 0x11d0, 0xa5, 0x35, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);
	public const Guid CLSID_ACListISF = .(0x03c036f1, 0xa186, 0x11d0, 0x82, 0x4a, 0x00, 0xaa, 0x00, 0x5b, 0x43, 0x83);
	public const Guid CLSID_ACLMRU = .(0x6756a641, 0xde71, 0x11d0, 0x83, 0x1b, 0x00, 0xaa, 0x00, 0x5b, 0x43, 0x83);
	public const Guid CLSID_ACLMulti = .(0x00bb2765, 0x6a77, 0x11d0, 0xa5, 0x35, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);
	public const Guid CLSID_ACLCustomMRU = .(0x6935db93, 0x21e8, 0x4ccc, 0xbe, 0xb9, 0x9f, 0xe3, 0xc7, 0x7a, 0x29, 0x7a);
	public const Guid CLSID_ProgressDialog = .(0xf8383852, 0xfcd3, 0x11d1, 0xa6, 0xb9, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);
	public const Guid SID_STopLevelBrowser = .(0x4c96be40, 0x915c, 0x11cf, 0x99, 0xd3, 0x00, 0xaa, 0x00, 0x4a, 0xe8, 0x37);
	public const Guid CLSID_FileTypes = .(0xb091e540, 0x83e3, 0x11cf, 0xa7, 0x13, 0x00, 0x20, 0xaf, 0xd7, 0x97, 0x62);
	public const Guid CLSID_ActiveDesktop = .(0x75048700, 0xef1f, 0x11d0, 0x98, 0x88, 0x00, 0x60, 0x97, 0xde, 0xac, 0xf9);
	public const Guid CLSID_QueryAssociations = .(0xa07034fd, 0x6caa, 0x4954, 0xac, 0x3f, 0x97, 0xa2, 0x72, 0x16, 0xf9, 0x8a);
	public const Guid CLSID_LinkColumnProvider = .(0x24f14f02, 0x7b1c, 0x11d1, 0x83, 0x8f, 0x00, 0x00, 0xf8, 0x04, 0x61, 0xcf);
	public const Guid CGID_ShortCut = .(0x93a68750, 0x951a, 0x11d1, 0x94, 0x6f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
	public const Guid CLSID_InternetButtons = .(0x1e796980, 0x9cc5, 0x11d1, 0xa8, 0x3f, 0x00, 0xc0, 0x4f, 0xc9, 0x9d, 0x61);
	public const Guid CLSID_MSOButtons = .(0x178f34b8, 0xa282, 0x11d2, 0x86, 0xc5, 0x00, 0xc0, 0x4f, 0x8e, 0xea, 0x99);
	public const Guid CLSID_ToolbarExtButtons = .(0x2ce4b5d8, 0xa28f, 0x11d2, 0x86, 0xc5, 0x00, 0xc0, 0x4f, 0x8e, 0xea, 0x99);
	public const Guid CLSID_DarwinAppPublisher = .(0xcfccc7a0, 0xa282, 0x11d1, 0x90, 0x82, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);
	public const Guid CLSID_DocHostUIHandler = .(0x7057e952, 0xbd1b, 0x11d1, 0x89, 0x19, 0x00, 0xc0, 0x4f, 0xc2, 0xc8, 0x36);
	public const Guid FMTID_ShellDetails = .(0x28636aa6, 0x953d, 0x11d2, 0xb5, 0xd6, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);
	public const uint32 PID_FINDDATA = 0;
	public const uint32 PID_NETRESOURCE = 1;
	public const uint32 PID_DESCRIPTIONID = 2;
	public const uint32 PID_WHICHFOLDER = 3;
	public const uint32 PID_NETWORKLOCATION = 4;
	public const uint32 PID_COMPUTERNAME = 5;
	public const Guid FMTID_Storage = .(0xb725f130, 0x47ef, 0x101a, 0xa5, 0xf1, 0x02, 0x60, 0x8c, 0x9e, 0xeb, 0xac);
	public const Guid FMTID_ImageProperties = .(0x14b81da1, 0x0135, 0x4d31, 0x96, 0xd9, 0x6c, 0xbf, 0xc9, 0x67, 0x1a, 0x99);
	public const Guid FMTID_CustomImageProperties = .(0x7ecd8b0e, 0xc136, 0x4a9b, 0x94, 0x11, 0x4e, 0xbd, 0x66, 0x73, 0xcc, 0xc3);
	public const Guid FMTID_LibraryProperties = .(0x5d76b67f, 0x9b3d, 0x44bb, 0xb6, 0xae, 0x25, 0xda, 0x4f, 0x63, 0x8a, 0x67);
	public const Guid FMTID_Displaced = .(0x9b174b33, 0x40ff, 0x11d2, 0xa2, 0x7e, 0x00, 0xc0, 0x4f, 0xc3, 0x08, 0x71);
	public const uint32 PID_DISPLACED_FROM = 2;
	public const uint32 PID_DISPLACED_DATE = 3;
	public const Guid FMTID_Briefcase = .(0x328d8b21, 0x7729, 0x4bfc, 0x95, 0x4c, 0x90, 0x2b, 0x32, 0x9d, 0x56, 0xb0);
	public const uint32 PID_SYNC_COPY_IN = 2;
	public const Guid FMTID_Misc = .(0x9b174b34, 0x40ff, 0x11d2, 0xa2, 0x7e, 0x00, 0xc0, 0x4f, 0xc3, 0x08, 0x71);
	public const uint32 PID_MISC_STATUS = 2;
	public const uint32 PID_MISC_ACCESSCOUNT = 3;
	public const uint32 PID_MISC_OWNER = 4;
	public const uint32 PID_HTMLINFOTIPFILE = 5;
	public const uint32 PID_MISC_PICS = 6;
	public const Guid FMTID_WebView = .(0xf2275480, 0xf782, 0x4291, 0xbd, 0x94, 0xf1, 0x36, 0x93, 0x51, 0x3a, 0xec);
	public const uint32 PID_DISPLAY_PROPERTIES = 0;
	public const uint32 PID_INTROTEXT = 1;
	public const Guid FMTID_MUSIC = .(0x56a3372e, 0xce9c, 0x11d2, 0x9f, 0x0e, 0x00, 0x60, 0x97, 0xc6, 0x86, 0xf6);
	public const uint32 PIDSI_ARTIST = 2;
	public const uint32 PIDSI_SONGTITLE = 3;
	public const uint32 PIDSI_ALBUM = 4;
	public const uint32 PIDSI_YEAR = 5;
	public const uint32 PIDSI_COMMENT = 6;
	public const uint32 PIDSI_TRACK = 7;
	public const uint32 PIDSI_GENRE = 11;
	public const uint32 PIDSI_LYRICS = 12;
	public const Guid FMTID_DRM = .(0xaeac19e4, 0x89ae, 0x4508, 0xb9, 0xb7, 0xbb, 0x86, 0x7a, 0xbe, 0xe2, 0xed);
	public const uint32 PIDDRSI_PROTECTED = 2;
	public const uint32 PIDDRSI_DESCRIPTION = 3;
	public const uint32 PIDDRSI_PLAYCOUNT = 4;
	public const uint32 PIDDRSI_PLAYSTARTS = 5;
	public const uint32 PIDDRSI_PLAYEXPIRES = 6;
	public const uint32 PIDVSI_STREAM_NAME = 2;
	public const uint32 PIDVSI_FRAME_WIDTH = 3;
	public const uint32 PIDVSI_FRAME_HEIGHT = 4;
	public const uint32 PIDVSI_TIMELENGTH = 7;
	public const uint32 PIDVSI_FRAME_COUNT = 5;
	public const uint32 PIDVSI_FRAME_RATE = 6;
	public const uint32 PIDVSI_DATA_RATE = 8;
	public const uint32 PIDVSI_SAMPLE_SIZE = 9;
	public const uint32 PIDVSI_COMPRESSION = 10;
	public const uint32 PIDVSI_STREAM_NUMBER = 11;
	public const uint32 PIDASI_FORMAT = 2;
	public const uint32 PIDASI_TIMELENGTH = 3;
	public const uint32 PIDASI_AVG_DATA_RATE = 4;
	public const uint32 PIDASI_SAMPLE_RATE = 5;
	public const uint32 PIDASI_SAMPLE_SIZE = 6;
	public const uint32 PIDASI_CHANNEL_COUNT = 7;
	public const uint32 PIDASI_STREAM_NUMBER = 8;
	public const uint32 PIDASI_STREAM_NAME = 9;
	public const uint32 PIDASI_COMPRESSION = 10;
	public const uint32 PID_CONTROLPANEL_CATEGORY = 2;
	public const Guid FMTID_Volume = .(0x9b174b35, 0x40ff, 0x11d2, 0xa2, 0x7e, 0x00, 0xc0, 0x4f, 0xc3, 0x08, 0x71);
	public const uint32 PID_VOLUME_FREE = 2;
	public const uint32 PID_VOLUME_CAPACITY = 3;
	public const uint32 PID_VOLUME_FILESYSTEM = 4;
	public const uint32 PID_SHARE_CSC_STATUS = 2;
	public const uint32 PID_LINK_TARGET = 2;
	public const uint32 PID_LINK_TARGET_TYPE = 3;
	public const Guid FMTID_Query = .(0x49691c90, 0x7e17, 0x101a, 0xa9, 0x1c, 0x08, 0x00, 0x2b, 0x2e, 0xcd, 0xa9);
	public const uint32 PID_QUERY_RANK = 2;
	public const Guid CLSID_HWShellExecute = .(0xffb8655f, 0x81b9, 0x4fce, 0xb8, 0x9c, 0x9a, 0x6b, 0xa7, 0x6d, 0x13, 0xe7);
	public const Guid CLSID_DragDropHelper = .(0x4657278a, 0x411b, 0x11d2, 0x83, 0x9a, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);
	public const Guid CLSID_CAnchorBrowsePropertyPage = .(0x3050f3bb, 0x98b5, 0x11cf, 0xbb, 0x82, 0x00, 0xaa, 0x00, 0xbd, 0xce, 0x0b);
	public const Guid CLSID_CImageBrowsePropertyPage = .(0x3050f3b3, 0x98b5, 0x11cf, 0xbb, 0x82, 0x00, 0xaa, 0x00, 0xbd, 0xce, 0x0b);
	public const Guid CLSID_CDocBrowsePropertyPage = .(0x3050f3b4, 0x98b5, 0x11cf, 0xbb, 0x82, 0x00, 0xaa, 0x00, 0xbd, 0xce, 0x0b);
	public const Guid SID_STopWindow = .(0x49e1b500, 0x4636, 0x11d3, 0x97, 0xf7, 0x00, 0xc0, 0x4f, 0x45, 0xd0, 0xb3);
	public const Guid SID_SGetViewFromViewDual = .(0x889a935d, 0x971e, 0x4b12, 0xb9, 0x0c, 0x24, 0xdf, 0xc9, 0xe1, 0xe5, 0xe8);
	public const Guid CLSID_FolderItemsMultiLevel = .(0x53c74826, 0xab99, 0x4d33, 0xac, 0xa4, 0x31, 0x17, 0xf5, 0x1d, 0x37, 0x88);
	public const Guid CLSID_NewMenu = .(0xd969a300, 0xe7ff, 0x11d0, 0xa9, 0x3b, 0x00, 0xa0, 0xc9, 0x0f, 0x27, 0x19);
	public const Guid BHID_SFObject = .(0x3981e224, 0xf559, 0x11d3, 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);
	public const Guid BHID_SFUIObject = .(0x3981e225, 0xf559, 0x11d3, 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);
	public const Guid BHID_SFViewObject = .(0x3981e226, 0xf559, 0x11d3, 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);
	public const Guid BHID_Storage = .(0x3981e227, 0xf559, 0x11d3, 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);
	public const Guid BHID_Stream = .(0x1cebb3ab, 0x7c10, 0x499a, 0xa4, 0x17, 0x92, 0xca, 0x16, 0xc4, 0xcb, 0x83);
	public const Guid BHID_RandomAccessStream = .(0xf16fc93b, 0x77ae, 0x4cfe, 0xbd, 0xa7, 0xa8, 0x66, 0xee, 0xa6, 0x87, 0x8d);
	public const Guid BHID_LinkTargetItem = .(0x3981e228, 0xf559, 0x11d3, 0x8e, 0x3a, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);
	public const Guid BHID_StorageEnum = .(0x4621a4e3, 0xf0d6, 0x4773, 0x8a, 0x9c, 0x46, 0xe7, 0x7b, 0x17, 0x48, 0x40);
	public const Guid BHID_Transfer = .(0xd5e346a1, 0xf753, 0x4932, 0xb4, 0x03, 0x45, 0x74, 0x80, 0x0e, 0x24, 0x98);
	public const Guid BHID_PropertyStore = .(0x0384e1a4, 0x1523, 0x439c, 0xa4, 0xc8, 0xab, 0x91, 0x10, 0x52, 0xf5, 0x86);
	public const Guid BHID_ThumbnailHandler = .(0x7b2e650a, 0x8e20, 0x4f4a, 0xb0, 0x9e, 0x65, 0x97, 0xaf, 0xc7, 0x2f, 0xb0);
	public const Guid BHID_EnumItems = .(0x94f60519, 0x2850, 0x4924, 0xaa, 0x5a, 0xd1, 0x5e, 0x84, 0x86, 0x80, 0x39);
	public const Guid BHID_DataObject = .(0xb8c0bd9f, 0xed24, 0x455c, 0x83, 0xe6, 0xd5, 0x39, 0x0c, 0x4f, 0xe8, 0xc4);
	public const Guid BHID_AssociationArray = .(0xbea9ef17, 0x82f1, 0x4f60, 0x92, 0x84, 0x4f, 0x8d, 0xb7, 0x5c, 0x3b, 0xe9);
	public const Guid BHID_Filter = .(0x38d08778, 0xf557, 0x4690, 0x9e, 0xbf, 0xba, 0x54, 0x70, 0x6a, 0xd8, 0xf7);
	public const Guid BHID_EnumAssocHandlers = .(0xb8ab0b9c, 0xc2ec, 0x4f7a, 0x91, 0x8d, 0x31, 0x49, 0x00, 0xe6, 0x28, 0x0a);
	public const Guid BHID_StorageItem = .(0x404e2109, 0x77d2, 0x4699, 0xa5, 0xa0, 0x4f, 0xdf, 0x10, 0xdb, 0x98, 0x37);
	public const Guid BHID_FilePlaceholder = .(0x8677dceb, 0xaae0, 0x4005, 0x8d, 0x3d, 0x54, 0x7f, 0xa8, 0x52, 0xf8, 0x25);
	public const Guid CATID_FilePlaceholderMergeHandler = .(0x3e9c9a51, 0xd4aa, 0x4870, 0xb4, 0x7c, 0x74, 0x24, 0xb4, 0x91, 0xf1, 0xcc);
	public const Guid SID_CtxQueryAssociations = .(0xfaadfc40, 0xb777, 0x4b69, 0xaa, 0x81, 0x77, 0x03, 0x5e, 0xf0, 0xe6, 0xe8);
	public const Guid CLSID_QuickLinks = .(0x0e5cbf21, 0xd15f, 0x11d0, 0x83, 0x01, 0x00, 0xaa, 0x00, 0x5b, 0x43, 0x83);
	public const Guid CLSID_ISFBand = .(0xd82be2b0, 0x5764, 0x11d0, 0xa9, 0x6e, 0x00, 0xc0, 0x4f, 0xd7, 0x05, 0xa2);
	public const Guid CLSID_ShellFldSetExt = .(0x6d5313c0, 0x8c62, 0x11d1, 0xb2, 0xcd, 0x00, 0x60, 0x97, 0xdf, 0x8c, 0x11);
	public const Guid SID_SMenuBandChild = .(0xed9cc020, 0x08b9, 0x11d1, 0x98, 0x23, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0x72);
	public const Guid SID_SMenuBandParent = .(0x8c278eec, 0x3eab, 0x11d1, 0x8c, 0xb0, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);
	public const Guid SID_SMenuPopup = .(0xd1e7afeb, 0x6a2e, 0x11d0, 0x8c, 0x78, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xb4);
	public const Guid SID_SMenuBandBottomSelected = .(0x165ebaf4, 0x6d51, 0x11d2, 0x83, 0xad, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);
	public const Guid SID_SMenuBandBottom = .(0x743ca664, 0x0deb, 0x11d1, 0x98, 0x25, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0x72);
	public const Guid SID_MenuShellFolder = .(0xa6c17eb4, 0x2d65, 0x11d2, 0x83, 0x8f, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);
	public const Guid SID_SMenuBandContextMenuModifier = .(0x39545874, 0x7162, 0x465e, 0xb7, 0x83, 0x2a, 0xa1, 0x87, 0x4f, 0xef, 0x81);
	public const Guid SID_SMenuBandBKContextMenu = .(0x164bbd86, 0x1d0d, 0x4de0, 0x9a, 0x3b, 0xd9, 0x72, 0x96, 0x47, 0xc2, 0xb8);
	public const Guid CGID_MENUDESKBAR = .(0x5c9f0a12, 0x959e, 0x11d0, 0xa3, 0xa4, 0x00, 0xa0, 0xc9, 0x08, 0x26, 0x36);
	public const Guid SID_SMenuBandTop = .(0x9493a810, 0xec38, 0x11d0, 0xbc, 0x46, 0x00, 0xaa, 0x00, 0x6c, 0xe2, 0xf5);
	public const Guid CLSID_MenuToolbarBase = .(0x40b96610, 0xb522, 0x11d1, 0xb3, 0xb4, 0x00, 0xaa, 0x00, 0x6e, 0xfd, 0xe7);
	public const Guid CLSID_MenuBandSite = .(0xe13ef4e4, 0xd2f2, 0x11d0, 0x98, 0x16, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0x72);
	public const Guid SID_SCommDlgBrowser = .(0x80f30233, 0xb7df, 0x11d2, 0xa3, 0x3b, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);
	public const Guid CPFG_LOGON_USERNAME = .(0xda15bbe8, 0x954d, 0x4fd3, 0xb0, 0xf4, 0x1f, 0xb5, 0xb9, 0x0b, 0x17, 0x4b);
	public const Guid CPFG_LOGON_PASSWORD = .(0x60624cfa, 0xa477, 0x47b1, 0x8a, 0x8e, 0x3a, 0x4a, 0x19, 0x98, 0x18, 0x27);
	public const Guid CPFG_SMARTCARD_USERNAME = .(0x3e1ecf69, 0x568c, 0x4d96, 0x9d, 0x59, 0x46, 0x44, 0x41, 0x74, 0xe2, 0xd6);
	public const Guid CPFG_SMARTCARD_PIN = .(0x4fe5263b, 0x9181, 0x46c1, 0xb0, 0xa4, 0x9d, 0xed, 0xd4, 0xdb, 0x7d, 0xea);
	public const Guid CPFG_CREDENTIAL_PROVIDER_LOGO = .(0x2d837775, 0xf6cd, 0x464e, 0xa7, 0x45, 0x48, 0x2f, 0xd0, 0xb4, 0x74, 0x93);
	public const Guid CPFG_CREDENTIAL_PROVIDER_LABEL = .(0x286bbff3, 0xbad4, 0x438f, 0xb0, 0x07, 0x79, 0xb7, 0x26, 0x7c, 0x3d, 0x48);
	public const Guid CPFG_STANDALONE_SUBMIT_BUTTON = .(0x0b7b0ad8, 0xcc36, 0x4d59, 0x80, 0x2b, 0x82, 0xf7, 0x14, 0xfa, 0x70, 0x22);
	public const Guid CPFG_STYLE_LINK_AS_BUTTON = .(0x088fa508, 0x94a6, 0x4430, 0xa4, 0xcb, 0x6f, 0xc6, 0xe3, 0xc0, 0xb9, 0xe2);
	public const Guid FOLDERTYPEID_Invalid = .(0x57807898, 0x8c4f, 0x4462, 0xbb, 0x63, 0x71, 0x04, 0x23, 0x80, 0xb1, 0x09);
	public const Guid FOLDERTYPEID_Generic = .(0x5c4f28b5, 0xf869, 0x4e84, 0x8e, 0x60, 0xf1, 0x1d, 0xb9, 0x7c, 0x5c, 0xc7);
	public const Guid FOLDERTYPEID_GenericSearchResults = .(0x7fde1a1e, 0x8b31, 0x49a5, 0x93, 0xb8, 0x6b, 0xe1, 0x4c, 0xfa, 0x49, 0x43);
	public const Guid FOLDERTYPEID_GenericLibrary = .(0x5f4eab9a, 0x6833, 0x4f61, 0x89, 0x9d, 0x31, 0xcf, 0x46, 0x97, 0x9d, 0x49);
	public const Guid FOLDERTYPEID_Documents = .(0x7d49d726, 0x3c21, 0x4f05, 0x99, 0xaa, 0xfd, 0xc2, 0xc9, 0x47, 0x46, 0x56);
	public const Guid FOLDERTYPEID_Pictures = .(0xb3690e58, 0xe961, 0x423b, 0xb6, 0x87, 0x38, 0x6e, 0xbf, 0xd8, 0x32, 0x39);
	public const Guid FOLDERTYPEID_Music = .(0x94d6ddcc, 0x4a68, 0x4175, 0xa3, 0x74, 0xbd, 0x58, 0x4a, 0x51, 0x0b, 0x78);
	public const Guid FOLDERTYPEID_Videos = .(0x5fa96407, 0x7e77, 0x483c, 0xac, 0x93, 0x69, 0x1d, 0x05, 0x85, 0x0d, 0xe8);
	public const Guid FOLDERTYPEID_Downloads = .(0x885a186e, 0xa440, 0x4ada, 0x81, 0x2b, 0xdb, 0x87, 0x1b, 0x94, 0x22, 0x59);
	public const Guid FOLDERTYPEID_UserFiles = .(0xcd0fc69b, 0x71e2, 0x46e5, 0x96, 0x90, 0x5b, 0xcd, 0x9f, 0x57, 0xaa, 0xb3);
	public const Guid FOLDERTYPEID_UsersLibraries = .(0xc4d98f09, 0x6124, 0x4fe0, 0x99, 0x42, 0x82, 0x64, 0x16, 0x08, 0x2d, 0xa9);
	public const Guid FOLDERTYPEID_OtherUsers = .(0xb337fd00, 0x9dd5, 0x4635, 0xa6, 0xd4, 0xda, 0x33, 0xfd, 0x10, 0x2b, 0x7a);
	public const Guid FOLDERTYPEID_PublishedItems = .(0x7f2f5b96, 0xff74, 0x41da, 0xaf, 0xd8, 0x1c, 0x78, 0xa5, 0xf3, 0xae, 0xa2);
	public const Guid FOLDERTYPEID_Communications = .(0x91475fe5, 0x586b, 0x4eba, 0x8d, 0x75, 0xd1, 0x74, 0x34, 0xb8, 0xcd, 0xf6);
	public const Guid FOLDERTYPEID_Contacts = .(0xde2b70ec, 0x9bf7, 0x4a93, 0xbd, 0x3d, 0x24, 0x3f, 0x78, 0x81, 0xd4, 0x92);
	public const Guid FOLDERTYPEID_StartMenu = .(0xef87b4cb, 0xf2ce, 0x4785, 0x86, 0x58, 0x4c, 0xa6, 0xc6, 0x3e, 0x38, 0xc6);
	public const Guid FOLDERTYPEID_RecordedTV = .(0x5557a28f, 0x5da6, 0x4f83, 0x88, 0x09, 0xc2, 0xc9, 0x8a, 0x11, 0xa6, 0xfa);
	public const Guid FOLDERTYPEID_SavedGames = .(0xd0363307, 0x28cb, 0x4106, 0x9f, 0x23, 0x29, 0x56, 0xe3, 0xe5, 0xe0, 0xe7);
	public const Guid FOLDERTYPEID_OpenSearch = .(0x8faf9629, 0x1980, 0x46ff, 0x80, 0x23, 0x9d, 0xce, 0xab, 0x9c, 0x3e, 0xe3);
	public const Guid FOLDERTYPEID_SearchConnector = .(0x982725ee, 0x6f47, 0x479e, 0xb4, 0x47, 0x81, 0x2b, 0xfa, 0x7d, 0x2e, 0x8f);
	public const Guid FOLDERTYPEID_AccountPictures = .(0xdb2a5d8f, 0x06e6, 0x4007, 0xab, 0xa6, 0xaf, 0x87, 0x7d, 0x52, 0x6e, 0xa6);
	public const Guid FOLDERTYPEID_Games = .(0xb689b0d0, 0x76d3, 0x4cbb, 0x87, 0xf7, 0x58, 0x5d, 0x0e, 0x0c, 0xe0, 0x70);
	public const Guid FOLDERTYPEID_ControlPanelCategory = .(0xde4f0660, 0xfa10, 0x4b8f, 0xa4, 0x94, 0x06, 0x8b, 0x20, 0xb2, 0x23, 0x07);
	public const Guid FOLDERTYPEID_ControlPanelClassic = .(0x0c3794f3, 0xb545, 0x43aa, 0xa3, 0x29, 0xc3, 0x74, 0x30, 0xc5, 0x8d, 0x2a);
	public const Guid FOLDERTYPEID_Printers = .(0x2c7bbec6, 0xc844, 0x4a0a, 0x91, 0xfa, 0xce, 0xf6, 0xf5, 0x9c, 0xfd, 0xa1);
	public const Guid FOLDERTYPEID_RecycleBin = .(0xd6d9e004, 0xcd87, 0x442b, 0x9d, 0x57, 0x5e, 0x0a, 0xeb, 0x4f, 0x6f, 0x72);
	public const Guid FOLDERTYPEID_SoftwareExplorer = .(0xd674391b, 0x52d9, 0x4e07, 0x83, 0x4e, 0x67, 0xc9, 0x86, 0x10, 0xf3, 0x9d);
	public const Guid FOLDERTYPEID_CompressedFolder = .(0x80213e82, 0xbcfd, 0x4c4f, 0x88, 0x17, 0xbb, 0x27, 0x60, 0x12, 0x67, 0xa9);
	public const Guid FOLDERTYPEID_NetworkExplorer = .(0x25cc242b, 0x9a7c, 0x4f51, 0x80, 0xe0, 0x7a, 0x29, 0x28, 0xfe, 0xbe, 0x42);
	public const Guid FOLDERTYPEID_Searches = .(0x0b0ba2e3, 0x405f, 0x415e, 0xa6, 0xee, 0xca, 0xd6, 0x25, 0x20, 0x78, 0x53);
	public const Guid FOLDERTYPEID_SearchHome = .(0x834d8a44, 0x0974, 0x4ed6, 0x86, 0x6e, 0xf2, 0x03, 0xd8, 0x0b, 0x38, 0x10);
	public const Guid FOLDERTYPEID_StorageProviderGeneric = .(0x4f01ebc5, 0x2385, 0x41f2, 0xa2, 0x8e, 0x2c, 0x5c, 0x91, 0xfb, 0x56, 0xe0);
	public const Guid FOLDERTYPEID_StorageProviderDocuments = .(0xdd61bd66, 0x70e8, 0x48dd, 0x96, 0x55, 0x65, 0xc5, 0xe1, 0xaa, 0xc2, 0xd1);
	public const Guid FOLDERTYPEID_StorageProviderPictures = .(0x71d642a9, 0xf2b1, 0x42cd, 0xad, 0x92, 0xeb, 0x93, 0x00, 0xc7, 0xcc, 0x0a);
	public const Guid FOLDERTYPEID_StorageProviderMusic = .(0x672ecd7e, 0xaf04, 0x4399, 0x87, 0x5c, 0x02, 0x90, 0x84, 0x5b, 0x62, 0x47);
	public const Guid FOLDERTYPEID_StorageProviderVideos = .(0x51294da1, 0xd7b1, 0x485b, 0x9e, 0x9a, 0x17, 0xcf, 0xfe, 0x33, 0xe1, 0x87);
	public const Guid SYNCMGR_OBJECTID_Icon = .(0x6dbc85c3, 0x5d07, 0x4c72, 0xa7, 0x77, 0x7f, 0xec, 0x78, 0x07, 0x2c, 0x06);
	public const Guid SYNCMGR_OBJECTID_EventStore = .(0x4bef34b9, 0xa786, 0x4075, 0xba, 0x88, 0x0c, 0x2b, 0x9d, 0x89, 0xa9, 0x8f);
	public const Guid SYNCMGR_OBJECTID_ConflictStore = .(0xd78181f4, 0x2389, 0x47e4, 0xa9, 0x60, 0x60, 0xbc, 0xc2, 0xed, 0x93, 0x0b);
	public const Guid SYNCMGR_OBJECTID_BrowseContent = .(0x57cbb584, 0xe9b4, 0x47ae, 0xa1, 0x20, 0xc4, 0xdf, 0x33, 0x35, 0xde, 0xe2);
	public const Guid SYNCMGR_OBJECTID_ShowSchedule = .(0xedc6f3e3, 0x8441, 0x4109, 0xad, 0xf3, 0x6c, 0x1c, 0xa0, 0xb7, 0xde, 0x47);
	public const Guid SYNCMGR_OBJECTID_QueryBeforeActivate = .(0xd882d80b, 0xe7aa, 0x49ed, 0x86, 0xb7, 0xe6, 0xe1, 0xf7, 0x14, 0xcd, 0xfe);
	public const Guid SYNCMGR_OBJECTID_QueryBeforeDeactivate = .(0xa0efc282, 0x60e0, 0x460e, 0x93, 0x74, 0xea, 0x88, 0x51, 0x3c, 0xfc, 0x80);
	public const Guid SYNCMGR_OBJECTID_QueryBeforeEnable = .(0x04cbf7f0, 0x5beb, 0x4de1, 0xbc, 0x90, 0x90, 0x83, 0x45, 0xc4, 0x80, 0xf6);
	public const Guid SYNCMGR_OBJECTID_QueryBeforeDisable = .(0xbb5f64aa, 0xf004, 0x4eb5, 0x8e, 0x4d, 0x26, 0x75, 0x19, 0x66, 0x34, 0x4c);
	public const Guid SYNCMGR_OBJECTID_QueryBeforeDelete = .(0xf76c3397, 0xafb3, 0x45d7, 0xa5, 0x9f, 0x5a, 0x49, 0xe9, 0x05, 0x43, 0x7e);
	public const Guid SYNCMGR_OBJECTID_EventLinkClick = .(0x2203bdc1, 0x1af1, 0x4082, 0x8c, 0x30, 0x28, 0x39, 0x9f, 0x41, 0x38, 0x4c);
	public const Guid EP_NavPane = .(0xcb316b22, 0x25f7, 0x42b8, 0x8a, 0x09, 0x54, 0x0d, 0x23, 0xa4, 0x3c, 0x2f);
	public const Guid EP_Commands = .(0xd9745868, 0xca5f, 0x4a76, 0x91, 0xcd, 0xf5, 0xa1, 0x29, 0xfb, 0xb0, 0x76);
	public const Guid EP_Commands_Organize = .(0x72e81700, 0xe3ec, 0x4660, 0xbf, 0x24, 0x3c, 0x3b, 0x7b, 0x64, 0x88, 0x06);
	public const Guid EP_Commands_View = .(0x21f7c32d, 0xeeaa, 0x439b, 0xbb, 0x51, 0x37, 0xb9, 0x6f, 0xd6, 0xa9, 0x43);
	public const Guid EP_DetailsPane = .(0x43abf98b, 0x89b8, 0x472d, 0xb9, 0xce, 0xe6, 0x9b, 0x82, 0x29, 0xf0, 0x19);
	public const Guid EP_PreviewPane = .(0x893c63d1, 0x45c8, 0x4d17, 0xbe, 0x19, 0x22, 0x3b, 0xe7, 0x1b, 0xe3, 0x65);
	public const Guid EP_QueryPane = .(0x65bcde4f, 0x4f07, 0x4f27, 0x83, 0xa7, 0x1a, 0xfc, 0xa4, 0xdf, 0x7d, 0xdd);
	public const Guid EP_AdvQueryPane = .(0xb4e9db8b, 0x34ba, 0x4c39, 0xb5, 0xcc, 0x16, 0xa1, 0xbd, 0x2c, 0x41, 0x1c);
	public const Guid EP_StatusBar = .(0x65fe56ce, 0x5cfe, 0x4bc4, 0xad, 0x8a, 0x7a, 0xe3, 0xfe, 0x7e, 0x8f, 0x7c);
	public const Guid EP_Ribbon = .(0xd27524a8, 0xc9f2, 0x4834, 0xa1, 0x06, 0xdf, 0x88, 0x89, 0xfd, 0x4f, 0x37);
	public const Guid CATID_LocationFactory = .(0x965c4d51, 0x8b76, 0x4e57, 0x80, 0xb7, 0x56, 0x4d, 0x2e, 0xa4, 0xb5, 0x5e);
	public const Guid CATID_LocationProvider = .(0x1b3ca474, 0x2614, 0x414b, 0xb8, 0x13, 0x1a, 0xce, 0xca, 0x3e, 0x3d, 0xd8);
	public const Guid ItemCount_Property_GUID = .(0xabbf5c45, 0x5ccc, 0x47b7, 0xbb, 0x4e, 0x87, 0xcb, 0x87, 0xbb, 0xd1, 0x62);
	public const Guid SelectedItemCount_Property_GUID = .(0x8fe316d2, 0x0e52, 0x460a, 0x9c, 0x1e, 0x48, 0xf2, 0x73, 0xd4, 0x70, 0xa3);
	public const Guid ItemIndex_Property_GUID = .(0x92a053da, 0x2969, 0x4021, 0xbf, 0x27, 0x51, 0x4c, 0xfc, 0x2e, 0x4a, 0x69);
	public const Guid CATID_SearchableApplication = .(0x366c292a, 0xd9b3, 0x4dbf, 0xbb, 0x70, 0xe6, 0x2e, 0xc3, 0xd0, 0xbb, 0xbf);
	public const uint32 IDD_WIZEXTN_FIRST = 20480;
	public const uint32 IDD_WIZEXTN_LAST = 20736;
	public const uint32 SHPWHF_NORECOMPRESS = 1;
	public const uint32 SHPWHF_NONETPLACECREATE = 2;
	public const uint32 SHPWHF_NOFILESELECTOR = 4;
	public const uint32 SHPWHF_USEMRU = 8;
	public const uint32 SHPWHF_ANYLOCATION = 256;
	public const uint32 SHPWHF_VALIDATEVIAWEBFOLDERS = 65536;
	public const uint32 ACDD_VISIBLE = 1;
	public const String PROPSTR_EXTENSIONCOMPLETIONSTATE = "ExtensionCompletionState";
	public const Guid SID_SCommandBarState = .(0xb99eaa5c, 0x3850, 0x4400, 0xbc, 0x33, 0x2c, 0xe5, 0x34, 0x04, 0x8b, 0xf8);
	public const int32 NSTCDHPOS_ONTOP = -1;
	public const uint32 FVSIF_RECT = 1;
	public const uint32 FVSIF_PINNED = 2;
	public const uint32 FVSIF_NEWFAILED = 134217728;
	public const uint32 FVSIF_NEWFILE = 2147483648;
	public const uint32 FVSIF_CANVIEWIT = 1073741824;
	public const uint32 FCIDM_TOOLBAR = 40960;
	public const uint32 FCIDM_STATUS = 40961;
	public const uint32 IDC_OFFLINE_HAND = 103;
	public const uint32 IDC_PANTOOL_HAND_OPEN = 104;
	public const uint32 IDC_PANTOOL_HAND_CLOSED = 105;
	public const uint32 PANE_NONE = 4294967295;
	public const uint32 PANE_ZONE = 1;
	public const uint32 PANE_OFFLINE = 2;
	public const uint32 PANE_PRINTER = 3;
	public const uint32 PANE_SSL = 4;
	public const uint32 PANE_NAVIGATION = 5;
	public const uint32 PANE_PROGRESS = 6;
	public const uint32 PANE_PRIVACY = 7;
	public const uint32 DWFRF_NORMAL = 0;
	public const uint32 DWFRF_DELETECONFIGDATA = 1;
	public const uint32 DWFAF_HIDDEN = 1;
	public const uint32 DWFAF_GROUP1 = 2;
	public const uint32 DWFAF_GROUP2 = 4;
	public const uint32 DWFAF_AUTOHIDE = 16;
	public const uint32 SHIMSTCAPFLAG_LOCKABLE = 1;
	public const uint32 SHIMSTCAPFLAG_PURGEABLE = 2;
	public const uint32 ISFB_MASK_STATE = 1;
	public const uint32 ISFB_MASK_BKCOLOR = 2;
	public const uint32 ISFB_MASK_VIEWMODE = 4;
	public const uint32 ISFB_MASK_SHELLFOLDER = 8;
	public const uint32 ISFB_MASK_IDLIST = 16;
	public const uint32 ISFB_MASK_COLORS = 32;
	public const uint32 ISFB_STATE_DEFAULT = 0;
	public const uint32 ISFB_STATE_DEBOSSED = 1;
	public const uint32 ISFB_STATE_ALLOWRENAME = 2;
	public const uint32 ISFB_STATE_NOSHOWTEXT = 4;
	public const uint32 ISFB_STATE_CHANNELBAR = 16;
	public const uint32 ISFB_STATE_QLINKSMODE = 32;
	public const uint32 ISFB_STATE_FULLOPEN = 64;
	public const uint32 ISFB_STATE_NONAMESORT = 128;
	public const uint32 ISFB_STATE_BTNMINSIZE = 256;
	public const uint32 ISFBVIEWMODE_SMALLICONS = 1;
	public const uint32 ISFBVIEWMODE_LARGEICONS = 2;
	public const uint32 ISFBVIEWMODE_LOGOS = 3;
	public const uint32 DBC_GS_IDEAL = 0;
	public const uint32 DBC_GS_SIZEDOWN = 1;
	public const uint32 DBC_HIDE = 0;
	public const uint32 DBC_SHOW = 1;
	public const uint32 DBC_SHOWOBSCURE = 2;
	public const uint32 SSM_CLEAR = 0;
	public const uint32 SSM_SET = 1;
	public const uint32 SSM_REFRESH = 2;
	public const uint32 SSM_UPDATE = 4;
	public const uint32 SCHEME_DISPLAY = 1;
	public const uint32 SCHEME_EDIT = 2;
	public const uint32 SCHEME_LOCAL = 4;
	public const uint32 SCHEME_GLOBAL = 8;
	public const uint32 SCHEME_REFRESH = 16;
	public const uint32 SCHEME_UPDATE = 32;
	public const uint32 SCHEME_DONOTUSE = 64;
	public const uint32 SCHEME_CREATE = 128;
	public const uint32 GADOF_DIRTY = 1;
	public const uint32 SHCDF_UPDATEITEM = 1;
	public const uint32 PPCF_ADDQUOTES = 1;
	public const uint32 PPCF_ADDARGUMENTS = 3;
	public const uint32 PPCF_NODIRECTORIES = 16;
	public const uint32 PPCF_FORCEQUALIFY = 64;
	public const uint32 PPCF_LONGESTPOSSIBLE = 128;
	public const uint32 OPENPROPS_NONE = 0;
	public const uint32 OPENPROPS_INHIBITPIF = 32768;
	public const uint32 GETPROPS_NONE = 0;
	public const uint32 SETPROPS_NONE = 0;
	public const uint32 CLOSEPROPS_NONE = 0;
	public const uint32 CLOSEPROPS_DISCARD = 1;
	public const uint32 TBIF_APPEND = 0;
	public const uint32 TBIF_PREPEND = 1;
	public const uint32 TBIF_REPLACE = 2;
	public const uint32 TBIF_DEFAULT = 0;
	public const uint32 TBIF_INTERNETBAR = 65536;
	public const uint32 TBIF_STANDARDTOOLBAR = 131072;
	public const uint32 TBIF_NOTOOLBAR = 196608;
	public const uint32 SFVM_REARRANGE = 1;
	public const uint32 SFVM_ADDOBJECT = 3;
	public const uint32 SFVM_REMOVEOBJECT = 6;
	public const uint32 SFVM_UPDATEOBJECT = 7;
	public const uint32 SFVM_GETSELECTEDOBJECTS = 9;
	public const uint32 SFVM_SETITEMPOS = 14;
	public const uint32 SFVM_SETCLIPBOARD = 16;
	public const uint32 SFVM_SETPOINTS = 23;
	public const uint32 GIL_OPENICON = 1;
	public const uint32 GIL_FORSHELL = 2;
	public const uint32 GIL_ASYNC = 32;
	public const uint32 GIL_DEFAULTICON = 64;
	public const uint32 GIL_FORSHORTCUT = 128;
	public const uint32 GIL_CHECKSHIELD = 512;
	public const uint32 GIL_SIMULATEDOC = 1;
	public const uint32 GIL_PERINSTANCE = 2;
	public const uint32 GIL_PERCLASS = 4;
	public const uint32 GIL_NOTFILENAME = 8;
	public const uint32 GIL_DONTCACHE = 16;
	public const uint32 GIL_SHIELD = 512;
	public const uint32 GIL_FORCENOSHIELD = 1024;
	public const uint32 SIOM_OVERLAYINDEX = 1;
	public const uint32 SIOM_ICONINDEX = 2;
	public const uint32 SIOM_RESERVED_SHARED = 0;
	public const uint32 SIOM_RESERVED_LINK = 1;
	public const uint32 SIOM_RESERVED_SLOWFILE = 2;
	public const uint32 SIOM_RESERVED_DEFAULT = 3;
	public const uint32 OI_DEFAULT = 0;
	public const uint32 OI_ASYNC = 4294962926;
	public const uint32 IDO_SHGIOI_SHARE = 268435455;
	public const uint32 IDO_SHGIOI_LINK = 268435454;
	public const uint64 IDO_SHGIOI_SLOWFILE = 4294967293;
	public const uint64 IDO_SHGIOI_DEFAULT = 4294967292;
	public const uint32 NT_CONSOLE_PROPS_SIG = 2684354562;
	public const uint32 NT_FE_CONSOLE_PROPS_SIG = 2684354564;
	public const uint32 EXP_DARWIN_ID_SIG = 2684354566;
	public const uint32 EXP_SPECIAL_FOLDER_SIG = 2684354565;
	public const uint32 EXP_SZ_LINK_SIG = 2684354561;
	public const uint32 EXP_SZ_ICON_SIG = 2684354567;
	public const uint32 EXP_PROPERTYSTORAGE_SIG = 2684354569;
	public const uint32 FCIDM_SHVIEWFIRST = 0;
	public const uint32 FCIDM_SHVIEWLAST = 32767;
	public const uint32 FCIDM_BROWSERFIRST = 40960;
	public const uint32 FCIDM_BROWSERLAST = 48896;
	public const uint32 FCIDM_GLOBALFIRST = 32768;
	public const uint32 FCIDM_GLOBALLAST = 40959;
	public const uint32 FCIDM_MENU_FILE = 32768;
	public const uint32 FCIDM_MENU_EDIT = 32832;
	public const uint32 FCIDM_MENU_VIEW = 32896;
	public const uint32 FCIDM_MENU_VIEW_SEP_OPTIONS = 32897;
	public const uint32 FCIDM_MENU_TOOLS = 32960;
	public const uint32 FCIDM_MENU_TOOLS_SEP_GOTO = 32961;
	public const uint32 FCIDM_MENU_HELP = 33024;
	public const uint32 FCIDM_MENU_FIND = 33088;
	public const uint32 FCIDM_MENU_EXPLORE = 33104;
	public const uint32 FCIDM_MENU_FAVORITES = 33136;
	public const uint32 OFASI_EDIT = 1;
	public const uint32 OFASI_OPENDESKTOP = 2;
	public const uint32 CSIDL_DESKTOP = 0;
	public const uint32 CSIDL_INTERNET = 1;
	public const uint32 CSIDL_PROGRAMS = 2;
	public const uint32 CSIDL_CONTROLS = 3;
	public const uint32 CSIDL_PRINTERS = 4;
	public const uint32 CSIDL_PERSONAL = 5;
	public const uint32 CSIDL_FAVORITES = 6;
	public const uint32 CSIDL_STARTUP = 7;
	public const uint32 CSIDL_RECENT = 8;
	public const uint32 CSIDL_SENDTO = 9;
	public const uint32 CSIDL_BITBUCKET = 10;
	public const uint32 CSIDL_STARTMENU = 11;
	public const uint32 CSIDL_MYDOCUMENTS = 5;
	public const uint32 CSIDL_MYMUSIC = 13;
	public const uint32 CSIDL_MYVIDEO = 14;
	public const uint32 CSIDL_DESKTOPDIRECTORY = 16;
	public const uint32 CSIDL_DRIVES = 17;
	public const uint32 CSIDL_NETWORK = 18;
	public const uint32 CSIDL_NETHOOD = 19;
	public const uint32 CSIDL_FONTS = 20;
	public const uint32 CSIDL_TEMPLATES = 21;
	public const uint32 CSIDL_COMMON_STARTMENU = 22;
	public const uint32 CSIDL_COMMON_PROGRAMS = 23;
	public const uint32 CSIDL_COMMON_STARTUP = 24;
	public const uint32 CSIDL_COMMON_DESKTOPDIRECTORY = 25;
	public const uint32 CSIDL_APPDATA = 26;
	public const uint32 CSIDL_PRINTHOOD = 27;
	public const uint32 CSIDL_LOCAL_APPDATA = 28;
	public const uint32 CSIDL_ALTSTARTUP = 29;
	public const uint32 CSIDL_COMMON_ALTSTARTUP = 30;
	public const uint32 CSIDL_COMMON_FAVORITES = 31;
	public const uint32 CSIDL_INTERNET_CACHE = 32;
	public const uint32 CSIDL_COOKIES = 33;
	public const uint32 CSIDL_HISTORY = 34;
	public const uint32 CSIDL_COMMON_APPDATA = 35;
	public const uint32 CSIDL_WINDOWS = 36;
	public const uint32 CSIDL_SYSTEM = 37;
	public const uint32 CSIDL_PROGRAM_FILES = 38;
	public const uint32 CSIDL_MYPICTURES = 39;
	public const uint32 CSIDL_PROFILE = 40;
	public const uint32 CSIDL_SYSTEMX86 = 41;
	public const uint32 CSIDL_PROGRAM_FILESX86 = 42;
	public const uint32 CSIDL_PROGRAM_FILES_COMMON = 43;
	public const uint32 CSIDL_PROGRAM_FILES_COMMONX86 = 44;
	public const uint32 CSIDL_COMMON_TEMPLATES = 45;
	public const uint32 CSIDL_COMMON_DOCUMENTS = 46;
	public const uint32 CSIDL_COMMON_ADMINTOOLS = 47;
	public const uint32 CSIDL_ADMINTOOLS = 48;
	public const uint32 CSIDL_CONNECTIONS = 49;
	public const uint32 CSIDL_COMMON_MUSIC = 53;
	public const uint32 CSIDL_COMMON_PICTURES = 54;
	public const uint32 CSIDL_COMMON_VIDEO = 55;
	public const uint32 CSIDL_RESOURCES = 56;
	public const uint32 CSIDL_RESOURCES_LOCALIZED = 57;
	public const uint32 CSIDL_COMMON_OEM_LINKS = 58;
	public const uint32 CSIDL_CDBURN_AREA = 59;
	public const uint32 CSIDL_COMPUTERSNEARME = 61;
	public const uint32 CSIDL_FLAG_CREATE = 32768;
	public const uint32 CSIDL_FLAG_DONT_VERIFY = 16384;
	public const uint32 CSIDL_FLAG_DONT_UNEXPAND = 8192;
	public const uint32 CSIDL_FLAG_NO_ALIAS = 4096;
	public const uint32 CSIDL_FLAG_PER_USER_INIT = 2048;
	public const uint32 CSIDL_FLAG_MASK = 65280;
	public const uint32 FCS_READ = 1;
	public const uint32 FCS_FORCEWRITE = 2;
	public const uint32 FCS_FLAG_DRAGDROP = 2;
	public const uint32 FCSM_VIEWID = 1;
	public const uint32 FCSM_WEBVIEWTEMPLATE = 2;
	public const uint32 FCSM_INFOTIP = 4;
	public const uint32 FCSM_CLSID = 8;
	public const uint32 FCSM_ICONFILE = 16;
	public const uint32 FCSM_LOGO = 32;
	public const uint32 FCSM_FLAGS = 64;
	public const uint32 BIF_RETURNONLYFSDIRS = 1;
	public const uint32 BIF_DONTGOBELOWDOMAIN = 2;
	public const uint32 BIF_STATUSTEXT = 4;
	public const uint32 BIF_RETURNFSANCESTORS = 8;
	public const uint32 BIF_EDITBOX = 16;
	public const uint32 BIF_VALIDATE = 32;
	public const uint32 BIF_NEWDIALOGSTYLE = 64;
	public const uint32 BIF_BROWSEINCLUDEURLS = 128;
	public const uint32 BIF_UAHINT = 256;
	public const uint32 BIF_NONEWFOLDERBUTTON = 512;
	public const uint32 BIF_NOTRANSLATETARGETS = 1024;
	public const uint32 BIF_BROWSEFORCOMPUTER = 4096;
	public const uint32 BIF_BROWSEFORPRINTER = 8192;
	public const uint32 BIF_BROWSEINCLUDEFILES = 16384;
	public const uint32 BIF_SHAREABLE = 32768;
	public const uint32 BIF_BROWSEFILEJUNCTIONS = 65536;
	public const uint32 BFFM_INITIALIZED = 1;
	public const uint32 BFFM_SELCHANGED = 2;
	public const uint32 BFFM_VALIDATEFAILEDA = 3;
	public const uint32 BFFM_VALIDATEFAILEDW = 4;
	public const uint32 BFFM_IUNKNOWN = 5;
	public const uint32 BFFM_SETSTATUSTEXTA = 1124;
	public const uint32 BFFM_ENABLEOK = 1125;
	public const uint32 BFFM_SETSELECTIONA = 1126;
	public const uint32 BFFM_SETSELECTIONW = 1127;
	public const uint32 BFFM_SETSTATUSTEXTW = 1128;
	public const uint32 BFFM_SETOKTEXT = 1129;
	public const uint32 BFFM_SETEXPANDED = 1130;
	public const uint32 BFFM_SETSTATUSTEXT = 1128;
	public const uint32 BFFM_SETSELECTION = 1127;
	public const uint32 BFFM_VALIDATEFAILED = 4;
	public const int32 CMDID_INTSHORTCUTCREATE = 1;
	public const String STR_PARSE_WITH_PROPERTIES = "ParseWithProperties";
	public const String STR_PARSE_PARTIAL_IDLIST = "ParseOriginalItem";
	public const uint32 PROGDLG_NORMAL = 0;
	public const uint32 PROGDLG_MODAL = 1;
	public const uint32 PROGDLG_AUTOTIME = 2;
	public const uint32 PROGDLG_NOTIME = 4;
	public const uint32 PROGDLG_NOMINIMIZE = 8;
	public const uint32 PROGDLG_NOPROGRESSBAR = 16;
	public const uint32 PROGDLG_MARQUEEPROGRESS = 32;
	public const uint32 PROGDLG_NOCANCEL = 64;
	public const uint32 PDTIMER_RESET = 1;
	public const uint32 PDTIMER_PAUSE = 2;
	public const uint32 PDTIMER_RESUME = 3;
	public const uint32 COMPONENT_TOP = 1073741823;
	public const uint32 COMP_TYPE_HTMLDOC = 0;
	public const uint32 COMP_TYPE_PICTURE = 1;
	public const uint32 COMP_TYPE_WEBSITE = 2;
	public const uint32 COMP_TYPE_CONTROL = 3;
	public const uint32 COMP_TYPE_CFHTML = 4;
	public const uint32 COMP_TYPE_MAX = 4;
	public const uint32 IS_NORMAL = 1;
	public const uint32 IS_FULLSCREEN = 2;
	public const uint32 IS_SPLIT = 4;
	public const uint32 AD_APPLY_SAVE = 1;
	public const uint32 AD_APPLY_HTMLGEN = 2;
	public const uint32 AD_APPLY_REFRESH = 4;
	public const uint32 AD_APPLY_FORCE = 8;
	public const uint32 AD_APPLY_BUFFERED_REFRESH = 16;
	public const uint32 AD_APPLY_DYNAMICREFRESH = 32;
	public const uint32 AD_GETWP_BMP = 0;
	public const uint32 AD_GETWP_IMAGE = 1;
	public const uint32 AD_GETWP_LAST_APPLIED = 2;
	public const uint32 WPSTYLE_CENTER = 0;
	public const uint32 WPSTYLE_TILE = 1;
	public const uint32 WPSTYLE_STRETCH = 2;
	public const uint32 WPSTYLE_KEEPASPECT = 3;
	public const uint32 WPSTYLE_CROPTOFIT = 4;
	public const uint32 WPSTYLE_SPAN = 5;
	public const uint32 WPSTYLE_MAX = 6;
	public const uint32 COMP_ELEM_TYPE = 1;
	public const uint32 COMP_ELEM_CHECKED = 2;
	public const uint32 COMP_ELEM_DIRTY = 4;
	public const uint32 COMP_ELEM_NOSCROLL = 8;
	public const uint32 COMP_ELEM_POS_LEFT = 16;
	public const uint32 COMP_ELEM_POS_TOP = 32;
	public const uint32 COMP_ELEM_SIZE_WIDTH = 64;
	public const uint32 COMP_ELEM_SIZE_HEIGHT = 128;
	public const uint32 COMP_ELEM_POS_ZINDEX = 256;
	public const uint32 COMP_ELEM_SOURCE = 512;
	public const uint32 COMP_ELEM_FRIENDLYNAME = 1024;
	public const uint32 COMP_ELEM_SUBSCRIBEDURL = 2048;
	public const uint32 COMP_ELEM_ORIGINAL_CSI = 4096;
	public const uint32 COMP_ELEM_RESTORED_CSI = 8192;
	public const uint32 COMP_ELEM_CURITEMSTATE = 16384;
	public const uint32 ADDURL_SILENT = 1;
	public const uint32 COMPONENT_DEFAULT_LEFT = 65535;
	public const uint32 COMPONENT_DEFAULT_TOP = 65535;
	public const uint32 MAX_COLUMN_NAME_LEN = 80;
	public const uint32 MAX_COLUMN_DESC_LEN = 128;
	public const String CFSTR_SHELLIDLIST = "Shell IDList Array";
	public const String CFSTR_SHELLIDLISTOFFSET = "Shell Object Offsets";
	public const String CFSTR_NETRESOURCES = "Net Resource";
	public const String CFSTR_FILEDESCRIPTORA = "FileGroupDescriptor";
	public const String CFSTR_FILEDESCRIPTORW = "FileGroupDescriptorW";
	public const String CFSTR_FILECONTENTS = "FileContents";
	public const String CFSTR_FILENAMEA = "FileName";
	public const String CFSTR_FILENAMEW = "FileNameW";
	public const String CFSTR_PRINTERGROUP = "PrinterFriendlyName";
	public const String CFSTR_FILENAMEMAPA = "FileNameMap";
	public const String CFSTR_FILENAMEMAPW = "FileNameMapW";
	public const String CFSTR_SHELLURL = "UniformResourceLocator";
	public const String CFSTR_INETURLA = "UniformResourceLocator";
	public const String CFSTR_INETURLW = "UniformResourceLocatorW";
	public const String CFSTR_PREFERREDDROPEFFECT = "Preferred DropEffect";
	public const String CFSTR_PERFORMEDDROPEFFECT = "Performed DropEffect";
	public const String CFSTR_PASTESUCCEEDED = "Paste Succeeded";
	public const String CFSTR_INDRAGLOOP = "InShellDragLoop";
	public const String CFSTR_MOUNTEDVOLUME = "MountedVolume";
	public const String CFSTR_PERSISTEDDATAOBJECT = "PersistedDataObject";
	public const String CFSTR_TARGETCLSID = "TargetCLSID";
	public const String CFSTR_LOGICALPERFORMEDDROPEFFECT = "Logical Performed DropEffect";
	public const String CFSTR_AUTOPLAY_SHELLIDLISTS = "Autoplay Enumerated IDList Array";
	public const String CFSTR_UNTRUSTEDDRAGDROP = "UntrustedDragDrop";
	public const String CFSTR_FILE_ATTRIBUTES_ARRAY = "File Attributes Array";
	public const String CFSTR_INVOKECOMMAND_DROPPARAM = "InvokeCommand DropParam";
	public const String CFSTR_SHELLDROPHANDLER = "DropHandlerCLSID";
	public const String CFSTR_DROPDESCRIPTION = "DropDescription";
	public const String CFSTR_ZONEIDENTIFIER = "ZoneIdentifier";
	public const String CFSTR_FILEDESCRIPTOR = "FileGroupDescriptorW";
	public const String CFSTR_FILENAME = "FileNameW";
	public const String CFSTR_FILENAMEMAP = "FileNameMapW";
	public const String CFSTR_INETURL = "UniformResourceLocatorW";
	public const uint32 DVASPECT_SHORTNAME = 2;
	public const uint32 DVASPECT_COPY = 3;
	public const uint32 DVASPECT_LINK = 4;
	public const int32 SHCNEE_ORDERCHANGED = 2;
	public const int32 SHCNEE_MSI_CHANGE = 4;
	public const int32 SHCNEE_MSI_UNINSTALL = 5;
	public const uint32 NUM_POINTS = 3;
	public const uint32 CABINETSTATE_VERSION = 2;
	public const uint32 PIFNAMESIZE = 30;
	public const uint32 PIFSTARTLOCSIZE = 63;
	public const uint32 PIFDEFPATHSIZE = 64;
	public const uint32 PIFPARAMSSIZE = 64;
	public const uint32 PIFSHPROGSIZE = 64;
	public const uint32 PIFSHDATASIZE = 64;
	public const uint32 PIFDEFFILESIZE = 80;
	public const uint32 PIFMAXFILEPATH = 260;
	public const uint32 QCMINFO_PLACE_BEFORE = 0;
	public const uint32 QCMINFO_PLACE_AFTER = 1;
	public const uint32 SFVSOC_INVALIDATE_ALL = 1;
	public const uint32 SFVSOC_NOSCROLL = 2;
	public const uint32 SHELLSTATEVERSION_IE4 = 9;
	public const uint32 SHELLSTATEVERSION_WIN2K = 10;
	public const uint32 SHPPFW_NONE = 0;
	public const uint32 SHPPFW_DIRCREATE = 1;
	public const uint32 SHPPFW_ASKDIRCREATE = 2;
	public const uint32 SHPPFW_IGNOREFILENAME = 4;
	public const uint32 SHPPFW_NOWRITECHECK = 8;
	public const uint32 SHPPFW_MEDIACHECKONLY = 16;
	public const uint32 CMF_NORMAL = 0;
	public const uint32 CMF_DEFAULTONLY = 1;
	public const uint32 CMF_VERBSONLY = 2;
	public const uint32 CMF_EXPLORE = 4;
	public const uint32 CMF_NOVERBS = 8;
	public const uint32 CMF_CANRENAME = 16;
	public const uint32 CMF_NODEFAULT = 32;
	public const uint32 CMF_INCLUDESTATIC = 64;
	public const uint32 CMF_ITEMMENU = 128;
	public const uint32 CMF_EXTENDEDVERBS = 256;
	public const uint32 CMF_DISABLEDVERBS = 512;
	public const uint32 CMF_ASYNCVERBSTATE = 1024;
	public const uint32 CMF_OPTIMIZEFORINVOKE = 2048;
	public const uint32 CMF_SYNCCASCADEMENU = 4096;
	public const uint32 CMF_DONOTPICKDEFAULT = 8192;
	public const uint32 CMF_RESERVED = 4294901760;
	public const uint32 GCS_VERBA = 0;
	public const uint32 GCS_HELPTEXTA = 1;
	public const uint32 GCS_VALIDATEA = 2;
	public const uint32 GCS_VERBW = 4;
	public const uint32 GCS_HELPTEXTW = 5;
	public const uint32 GCS_VALIDATEW = 6;
	public const uint32 GCS_VERBICONW = 20;
	public const uint32 GCS_UNICODE = 4;
	public const uint32 GCS_VERB = 4;
	public const uint32 GCS_HELPTEXT = 5;
	public const uint32 GCS_VALIDATE = 6;
	public const String CMDSTR_NEWFOLDERA = "NewFolder";
	public const String CMDSTR_VIEWLISTA = "ViewList";
	public const String CMDSTR_VIEWDETAILSA = "ViewDetails";
	public const String CMDSTR_NEWFOLDERW = "NewFolder";
	public const String CMDSTR_VIEWLISTW = "ViewList";
	public const String CMDSTR_VIEWDETAILSW = "ViewDetails";
	public const String CMDSTR_NEWFOLDER = "NewFolder";
	public const String CMDSTR_VIEWLIST = "ViewList";
	public const String CMDSTR_VIEWDETAILS = "ViewDetails";
	public const uint32 CMIC_MASK_SHIFT_DOWN = 268435456;
	public const uint32 CMIC_MASK_CONTROL_DOWN = 1073741824;
	public const uint32 CMIC_MASK_PTINVOKE = 536870912;
	public const uint32 IRTIR_TASK_NOT_RUNNING = 0;
	public const uint32 IRTIR_TASK_RUNNING = 1;
	public const uint32 IRTIR_TASK_SUSPENDED = 2;
	public const uint32 IRTIR_TASK_PENDING = 3;
	public const uint32 IRTIR_TASK_FINISHED = 4;
	public const uint32 ITSAT_DEFAULT_PRIORITY = 268435456;
	public const uint32 ITSAT_MAX_PRIORITY = 2147483647;
	public const uint32 ITSAT_MIN_PRIORITY = 0;
	public const uint32 ITSSFLAG_COMPLETE_ON_DESTROY = 0;
	public const uint32 ITSSFLAG_KILL_ON_DESTROY = 1;
	public const uint32 ITSSFLAG_FLAGS_MASK = 3;
	public const uint32 CSIDL_FLAG_PFTI_TRACKTARGET = 16384;
	public const int32 SHCIDS_ALLFIELDS = -2147483648;
	public const int32 SHCIDS_CANONICALONLY = 268435456;
	public const int32 SHCIDS_BITMASK = -65536;
	public const int32 SHCIDS_COLUMNMASK = 65535;
	public const String CONFLICT_RESOLUTION_CLSID_KEY = "ConflictResolutionCLSID";
	public const String STR_BIND_FORCE_FOLDER_SHORTCUT_RESOLVE = "Force Folder Shortcut Resolve";
	public const String STR_AVOID_DRIVE_RESTRICTION_POLICY = "Avoid Drive Restriction Policy";
	public const String STR_SKIP_BINDING_CLSID = "Skip Binding CLSID";
	public const String STR_PARSE_PREFER_FOLDER_BROWSING = "Parse Prefer Folder Browsing";
	public const String STR_DONT_PARSE_RELATIVE = "Don't Parse Relative";
	public const String STR_PARSE_TRANSLATE_ALIASES = "Parse Translate Aliases";
	public const String STR_PARSE_SKIP_NET_CACHE = "Skip Net Resource Cache";
	public const String STR_PARSE_SHELL_PROTOCOL_TO_FILE_OBJECTS = "Parse Shell Protocol To File Objects";
	public const String STR_TRACK_CLSID = "Track the CLSID";
	public const String STR_INTERNAL_NAVIGATE = "Internal Navigation";
	public const String STR_PARSE_PROPERTYSTORE = "DelegateNamedProperties";
	public const String STR_NO_VALIDATE_FILENAME_CHARS = "NoValidateFilenameChars";
	public const String STR_BIND_DELEGATE_CREATE_OBJECT = "Delegate Object Creation";
	public const String STR_PARSE_ALLOW_INTERNET_SHELL_FOLDERS = "Allow binding to Internet shell folder handlers and negate STR_PARSE_PREFER_WEB_BROWSING";
	public const String STR_PARSE_PREFER_WEB_BROWSING = "Do not bind to Internet shell folder handlers";
	public const String STR_PARSE_SHOW_NET_DIAGNOSTICS_UI = "Show network diagnostics UI";
	public const String STR_PARSE_DONT_REQUIRE_VALIDATED_URLS = "Do not require validated URLs";
	public const String STR_INTERNETFOLDER_PARSE_ONLY_URLMON_BINDABLE = "Validate URL";
	public const uint32 BIND_INTERRUPTABLE = 4294967295;
	public const String STR_BIND_FOLDERS_READ_ONLY = "Folders As Read Only";
	public const String STR_BIND_FOLDER_ENUM_MODE = "Folder Enum Mode";
	public const String STR_PARSE_WITH_EXPLICIT_PROGID = "ExplicitProgid";
	public const String STR_PARSE_WITH_EXPLICIT_ASSOCAPP = "ExplicitAssociationApp";
	public const String STR_PARSE_EXPLICIT_ASSOCIATION_SUCCESSFUL = "ExplicitAssociationSuccessful";
	public const String STR_PARSE_AND_CREATE_ITEM = "ParseAndCreateItem";
	public const String STR_PROPERTYBAG_PARAM = "SHBindCtxPropertyBag";
	public const String STR_ENUM_ITEMS_FLAGS = "SHCONTF";
	public const String STR_STORAGEITEM_CREATION_FLAGS = "SHGETSTORAGEITEM";
	public const String STR_ITEM_CACHE_CONTEXT = "ItemCacheContext";
	public const uint32 CDBOSC_SETFOCUS = 0;
	public const uint32 CDBOSC_KILLFOCUS = 1;
	public const uint32 CDBOSC_SELCHANGE = 2;
	public const uint32 CDBOSC_RENAME = 3;
	public const uint32 CDBOSC_STATECHANGE = 4;
	public const uint32 CDB2N_CONTEXTMENU_DONE = 1;
	public const uint32 CDB2N_CONTEXTMENU_START = 2;
	public const uint32 CDB2GVF_SHOWALLFILES = 1;
	public const uint32 CDB2GVF_ISFILESAVE = 2;
	public const uint32 CDB2GVF_ALLOWPREVIEWPANE = 4;
	public const uint32 CDB2GVF_NOSELECTVERB = 8;
	public const uint32 CDB2GVF_NOINCLUDEITEM = 16;
	public const uint32 CDB2GVF_ISFOLDERPICKER = 32;
	public const uint32 CDB2GVF_ADDSHIELD = 64;
	public const uint32 SBSP_DEFBROWSER = 0;
	public const uint32 SBSP_SAMEBROWSER = 1;
	public const uint32 SBSP_NEWBROWSER = 2;
	public const uint32 SBSP_DEFMODE = 0;
	public const uint32 SBSP_OPENMODE = 16;
	public const uint32 SBSP_EXPLOREMODE = 32;
	public const uint32 SBSP_HELPMODE = 64;
	public const uint32 SBSP_NOTRANSFERHIST = 128;
	public const uint32 SBSP_ABSOLUTE = 0;
	public const uint32 SBSP_RELATIVE = 4096;
	public const uint32 SBSP_PARENT = 8192;
	public const uint32 SBSP_NAVIGATEBACK = 16384;
	public const uint32 SBSP_NAVIGATEFORWARD = 32768;
	public const uint32 SBSP_ALLOW_AUTONAVIGATE = 65536;
	public const uint32 SBSP_KEEPSAMETEMPLATE = 131072;
	public const uint32 SBSP_KEEPWORDWHEELTEXT = 262144;
	public const uint32 SBSP_ACTIVATE_NOFOCUS = 524288;
	public const uint32 SBSP_CREATENOHISTORY = 1048576;
	public const uint32 SBSP_PLAYNOSOUND = 2097152;
	public const uint32 SBSP_CALLERUNTRUSTED = 8388608;
	public const uint32 SBSP_TRUSTFIRSTDOWNLOAD = 16777216;
	public const uint32 SBSP_UNTRUSTEDFORDOWNLOAD = 33554432;
	public const uint32 SBSP_NOAUTOSELECT = 67108864;
	public const uint32 SBSP_WRITENOHISTORY = 134217728;
	public const uint32 SBSP_TRUSTEDFORACTIVEX = 268435456;
	public const uint32 SBSP_FEEDNAVIGATION = 536870912;
	public const uint32 SBSP_REDIRECT = 1073741824;
	public const uint32 SBSP_INITIATEDBYHLINKFRAME = 2147483648;
	public const uint32 FCW_STATUS = 1;
	public const uint32 FCW_TOOLBAR = 2;
	public const uint32 FCW_TREE = 3;
	public const uint32 FCW_INTERNETBAR = 6;
	public const uint32 FCW_PROGRESS = 8;
	public const uint32 FCT_MERGE = 1;
	public const uint32 FCT_CONFIGABLE = 2;
	public const uint32 FCT_ADDTOEND = 4;
	public const String STR_DONT_RESOLVE_LINK = "Don't Resolve Link";
	public const String STR_GET_ASYNC_HANDLER = "GetAsyncHandler";
	public const String STR_GPS_HANDLERPROPERTIESONLY = "GPS_HANDLERPROPERTIESONLY";
	public const String STR_GPS_FASTPROPERTIESONLY = "GPS_FASTPROPERTIESONLY";
	public const String STR_GPS_OPENSLOWITEM = "GPS_OPENSLOWITEM";
	public const String STR_GPS_DELAYCREATION = "GPS_DELAYCREATION";
	public const String STR_GPS_BESTEFFORT = "GPS_BESTEFFORT";
	public const String STR_GPS_NO_OPLOCK = "GPS_NO_OPLOCK";
	public const String DI_GETDRAGIMAGE = "ShellGetDragImage";
	public const uint32 ARCONTENT_AUTORUNINF = 2;
	public const uint32 ARCONTENT_AUDIOCD = 4;
	public const uint32 ARCONTENT_DVDMOVIE = 8;
	public const uint32 ARCONTENT_BLANKCD = 16;
	public const uint32 ARCONTENT_BLANKDVD = 32;
	public const uint32 ARCONTENT_UNKNOWNCONTENT = 64;
	public const uint32 ARCONTENT_AUTOPLAYPIX = 128;
	public const uint32 ARCONTENT_AUTOPLAYMUSIC = 256;
	public const uint32 ARCONTENT_AUTOPLAYVIDEO = 512;
	public const uint32 ARCONTENT_VCD = 1024;
	public const uint32 ARCONTENT_SVCD = 2048;
	public const uint32 ARCONTENT_DVDAUDIO = 4096;
	public const uint32 ARCONTENT_BLANKBD = 8192;
	public const uint32 ARCONTENT_BLURAY = 16384;
	public const uint32 ARCONTENT_CAMERASTORAGE = 32768;
	public const uint32 ARCONTENT_CUSTOMEVENT = 65536;
	public const uint32 ARCONTENT_NONE = 0;
	public const uint32 ARCONTENT_MASK = 131070;
	public const uint32 ARCONTENT_PHASE_UNKNOWN = 0;
	public const uint32 ARCONTENT_PHASE_PRESNIFF = 268435456;
	public const uint32 ARCONTENT_PHASE_SNIFFING = 536870912;
	public const uint32 ARCONTENT_PHASE_FINAL = 1073741824;
	public const uint32 ARCONTENT_PHASE_MASK = 1879048192;
	public const uint32 IEI_PRIORITY_MAX = 2147483647;
	public const uint32 IEI_PRIORITY_MIN = 0;
	public const uint32 IEIT_PRIORITY_NORMAL = 268435456;
	public const uint32 IEIFLAG_ASYNC = 1;
	public const uint32 IEIFLAG_CACHE = 2;
	public const uint32 IEIFLAG_ASPECT = 4;
	public const uint32 IEIFLAG_OFFLINE = 8;
	public const uint32 IEIFLAG_GLEAM = 16;
	public const uint32 IEIFLAG_SCREEN = 32;
	public const uint32 IEIFLAG_ORIGSIZE = 64;
	public const uint32 IEIFLAG_NOSTAMP = 128;
	public const uint32 IEIFLAG_NOBORDER = 256;
	public const uint32 IEIFLAG_QUALITY = 512;
	public const uint32 IEIFLAG_REFRESH = 1024;
	public const uint32 DBIM_MINSIZE = 1;
	public const uint32 DBIM_MAXSIZE = 2;
	public const uint32 DBIM_INTEGRAL = 4;
	public const uint32 DBIM_ACTUAL = 8;
	public const uint32 DBIM_TITLE = 16;
	public const uint32 DBIM_MODEFLAGS = 32;
	public const uint32 DBIM_BKCOLOR = 64;
	public const uint32 DBIMF_NORMAL = 0;
	public const uint32 DBIMF_FIXED = 1;
	public const uint32 DBIMF_FIXEDBMP = 4;
	public const uint32 DBIMF_VARIABLEHEIGHT = 8;
	public const uint32 DBIMF_UNDELETEABLE = 16;
	public const uint32 DBIMF_DEBOSSED = 32;
	public const uint32 DBIMF_BKCOLOR = 64;
	public const uint32 DBIMF_USECHEVRON = 128;
	public const uint32 DBIMF_BREAK = 256;
	public const uint32 DBIMF_ADDTOFRONT = 512;
	public const uint32 DBIMF_TOPALIGN = 1024;
	public const uint32 DBIMF_NOGRIPPER = 2048;
	public const uint32 DBIMF_ALWAYSGRIPPER = 4096;
	public const uint32 DBIMF_NOMARGINS = 8192;
	public const uint32 DBIF_VIEWMODE_NORMAL = 0;
	public const uint32 DBIF_VIEWMODE_VERTICAL = 1;
	public const uint32 DBIF_VIEWMODE_FLOATING = 2;
	public const uint32 DBIF_VIEWMODE_TRANSPARENT = 4;
	public const uint32 DBPC_SELECTFIRST = 4294967295;
	public const uint32 THBN_CLICKED = 6144;
	public const uint32 FOFX_NOSKIPJUNCTIONS = 65536;
	public const uint32 FOFX_PREFERHARDLINK = 131072;
	public const uint32 FOFX_SHOWELEVATIONPROMPT = 262144;
	public const uint32 FOFX_RECYCLEONDELETE = 524288;
	public const uint32 FOFX_EARLYFAILURE = 1048576;
	public const uint32 FOFX_PRESERVEFILEEXTENSIONS = 2097152;
	public const uint32 FOFX_KEEPNEWERFILE = 4194304;
	public const uint32 FOFX_NOCOPYHOOKS = 8388608;
	public const uint32 FOFX_NOMINIMIZEBOX = 16777216;
	public const uint32 FOFX_MOVEACLSACROSSVOLUMES = 33554432;
	public const uint32 FOFX_DONTDISPLAYSOURCEPATH = 67108864;
	public const uint32 FOFX_DONTDISPLAYDESTPATH = 134217728;
	public const uint32 FOFX_REQUIREELEVATION = 268435456;
	public const uint32 FOFX_ADDUNDORECORD = 536870912;
	public const uint32 FOFX_COPYASDOWNLOAD = 1073741824;
	public const uint32 FOFX_DONTDISPLAYLOCATIONS = 2147483648;
	public const uint32 BSIM_STATE = 1;
	public const uint32 BSIM_STYLE = 2;
	public const uint32 BSSF_VISIBLE = 1;
	public const uint32 BSSF_NOTITLE = 2;
	public const uint32 BSSF_UNDELETEABLE = 4096;
	public const uint32 BSIS_AUTOGRIPPER = 0;
	public const uint32 BSIS_NOGRIPPER = 1;
	public const uint32 BSIS_ALWAYSGRIPPER = 2;
	public const uint32 BSIS_LEFTALIGN = 4;
	public const uint32 BSIS_SINGLECLICK = 8;
	public const uint32 BSIS_NOCONTEXTMENU = 16;
	public const uint32 BSIS_NODROPTARGET = 32;
	public const uint32 BSIS_NOCAPTION = 64;
	public const uint32 BSIS_PREFERNOLINEBREAK = 128;
	public const uint32 BSIS_LOCKED = 256;
	public const uint32 BSIS_PRESERVEORDERDURINGLAYOUT = 512;
	public const uint32 BSIS_FIXEDORDER = 1024;
	public const uint32 OF_CAP_CANSWITCHTO = 1;
	public const uint32 OF_CAP_CANCLOSE = 2;
	public const uint32 SMDM_SHELLFOLDER = 1;
	public const uint32 SMDM_HMENU = 2;
	public const uint32 SMDM_TOOLBAR = 4;
	public const uint32 SMC_INITMENU = 1;
	public const uint32 SMC_CREATE = 2;
	public const uint32 SMC_EXITMENU = 3;
	public const uint32 SMC_GETINFO = 5;
	public const uint32 SMC_GETSFINFO = 6;
	public const uint32 SMC_GETOBJECT = 7;
	public const uint32 SMC_GETSFOBJECT = 8;
	public const uint32 SMC_SFEXEC = 9;
	public const uint32 SMC_SFSELECTITEM = 10;
	public const uint32 SMC_REFRESH = 16;
	public const uint32 SMC_DEMOTE = 17;
	public const uint32 SMC_PROMOTE = 18;
	public const uint32 SMC_DEFAULTICON = 22;
	public const uint32 SMC_NEWITEM = 23;
	public const uint32 SMC_CHEVRONEXPAND = 25;
	public const uint32 SMC_DISPLAYCHEVRONTIP = 42;
	public const uint32 SMC_SETSFOBJECT = 45;
	public const uint32 SMC_SHCHANGENOTIFY = 46;
	public const uint32 SMC_CHEVRONGETTIP = 47;
	public const uint32 SMC_SFDDRESTRICTED = 48;
	public const uint32 SMC_SFEXEC_MIDDLE = 49;
	public const uint32 SMC_GETAUTOEXPANDSTATE = 65;
	public const uint32 SMC_AUTOEXPANDCHANGE = 66;
	public const uint32 SMC_GETCONTEXTMENUMODIFIER = 67;
	public const uint32 SMC_GETBKCONTEXTMENU = 68;
	public const uint32 SMC_OPEN = 69;
	public const uint32 SMAE_EXPANDED = 1;
	public const uint32 SMAE_CONTRACTED = 2;
	public const uint32 SMAE_USER = 4;
	public const uint32 SMAE_VALID = 7;
	public const uint32 SMINIT_DEFAULT = 0;
	public const uint32 SMINIT_RESTRICT_DRAGDROP = 2;
	public const uint32 SMINIT_TOPLEVEL = 4;
	public const uint32 SMINIT_CACHED = 16;
	public const uint32 SMINIT_AUTOEXPAND = 256;
	public const uint32 SMINIT_AUTOTOOLTIP = 512;
	public const uint32 SMINIT_DROPONCONTAINER = 1024;
	public const uint32 SMINIT_VERTICAL = 268435456;
	public const uint32 SMINIT_HORIZONTAL = 536870912;
	public const uint32 SMSET_TOP = 268435456;
	public const uint32 SMSET_BOTTOM = 536870912;
	public const uint32 SMSET_DONTOWN = 1;
	public const uint32 SMINV_REFRESH = 1;
	public const uint32 SMINV_ID = 8;
	public const HRESULT E_PREVIEWHANDLER_DRM_FAIL = -2042494975;
	public const HRESULT E_PREVIEWHANDLER_NOAUTH = -2042494974;
	public const HRESULT E_PREVIEWHANDLER_NOTFOUND = -2042494973;
	public const HRESULT E_PREVIEWHANDLER_CORRUPT = -2042494972;
	public const String STR_FILE_SYS_BIND_DATA = "File System Bind Data";
	public const String STR_FILE_SYS_BIND_DATA_WIN7_FORMAT = "Win7FileSystemIdList";
	public const String HOMEGROUP_SECURITY_GROUP_MULTI = "HUG";
	public const String HOMEGROUP_SECURITY_GROUP = "HomeUsers";
	public const String PROP_CONTRACT_DELEGATE = "ContractDelegate";
	public const Guid SID_URLExecutionContext = .(0xfb5f8ebc, 0xbbb6, 0x4d10, 0xa4, 0x61, 0x77, 0x72, 0x91, 0xa0, 0x90, 0x30);
	public const String STR_TAB_REUSE_IDENTIFIER = "Tab Reuse Identifier";
	public const String STR_REFERRER_IDENTIFIER = "Referrer Identifier";
	public const Guid SID_LaunchSourceViewSizePreference = .(0x80605492, 0x67d9, 0x414f, 0xaf, 0x89, 0xa1, 0xcd, 0xf1, 0x24, 0x2b, 0xc1);
	public const Guid SID_LaunchTargetViewSizePreference = .(0x26db2472, 0xb7b7, 0x406b, 0x97, 0x02, 0x73, 0x0a, 0x4e, 0x20, 0xd3, 0xbf);
	public const Guid SID_LaunchSourceAppUserModelId = .(0x2ce78010, 0x74db, 0x48bc, 0x9c, 0x6a, 0x10, 0xf3, 0x72, 0x49, 0x57, 0x23);
	public const Guid SID_ShellExecuteNamedPropertyStore = .(0xeb84ada2, 0x00ff, 0x4992, 0x83, 0x24, 0xed, 0x5c, 0xe0, 0x61, 0xcb, 0x29);
	public const uint32 ISIOI_ICONFILE = 1;
	public const uint32 ISIOI_ICONINDEX = 2;
	public const uint32 ABM_NEW = 0;
	public const uint32 ABM_REMOVE = 1;
	public const uint32 ABM_QUERYPOS = 2;
	public const uint32 ABM_SETPOS = 3;
	public const uint32 ABM_GETSTATE = 4;
	public const uint32 ABM_GETTASKBARPOS = 5;
	public const uint32 ABM_ACTIVATE = 6;
	public const uint32 ABM_GETAUTOHIDEBAR = 7;
	public const uint32 ABM_SETAUTOHIDEBAR = 8;
	public const uint32 ABM_WINDOWPOSCHANGED = 9;
	public const uint32 ABM_SETSTATE = 10;
	public const uint32 ABM_GETAUTOHIDEBAREX = 11;
	public const uint32 ABM_SETAUTOHIDEBAREX = 12;
	public const uint32 ABN_STATECHANGE = 0;
	public const uint32 ABN_POSCHANGED = 1;
	public const uint32 ABN_FULLSCREENAPP = 2;
	public const uint32 ABN_WINDOWARRANGE = 3;
	public const uint32 ABS_AUTOHIDE = 1;
	public const uint32 ABS_ALWAYSONTOP = 2;
	public const uint32 ABE_LEFT = 0;
	public const uint32 ABE_TOP = 1;
	public const uint32 ABE_RIGHT = 2;
	public const uint32 ABE_BOTTOM = 3;
	public const uint32 FO_MOVE = 1;
	public const uint32 FO_COPY = 2;
	public const uint32 FO_DELETE = 3;
	public const uint32 FO_RENAME = 4;
	public const uint32 FOF_MULTIDESTFILES = 1;
	public const uint32 FOF_CONFIRMMOUSE = 2;
	public const uint32 FOF_SILENT = 4;
	public const uint32 FOF_RENAMEONCOLLISION = 8;
	public const uint32 FOF_NOCONFIRMATION = 16;
	public const uint32 FOF_WANTMAPPINGHANDLE = 32;
	public const uint32 FOF_ALLOWUNDO = 64;
	public const uint32 FOF_FILESONLY = 128;
	public const uint32 FOF_SIMPLEPROGRESS = 256;
	public const uint32 FOF_NOCONFIRMMKDIR = 512;
	public const uint32 FOF_NOERRORUI = 1024;
	public const uint32 FOF_NOCOPYSECURITYATTRIBS = 2048;
	public const uint32 FOF_NORECURSION = 4096;
	public const uint32 FOF_NO_CONNECTED_ELEMENTS = 8192;
	public const uint32 FOF_WANTNUKEWARNING = 16384;
	public const uint32 FOF_NORECURSEREPARSE = 32768;
	public const uint32 PO_DELETE = 19;
	public const uint32 PO_RENAME = 20;
	public const uint32 PO_PORTCHANGE = 32;
	public const uint32 PO_REN_PORT = 52;
	public const uint32 SE_ERR_FNF = 2;
	public const uint32 SE_ERR_PNF = 3;
	public const uint32 SE_ERR_ACCESSDENIED = 5;
	public const uint32 SE_ERR_OOM = 8;
	public const uint32 SE_ERR_DLLNOTFOUND = 32;
	public const uint32 SE_ERR_SHARE = 26;
	public const uint32 SE_ERR_ASSOCINCOMPLETE = 27;
	public const uint32 SE_ERR_DDETIMEOUT = 28;
	public const uint32 SE_ERR_DDEFAIL = 29;
	public const uint32 SE_ERR_DDEBUSY = 30;
	public const uint32 SE_ERR_NOASSOC = 31;
	public const uint32 SEE_MASK_DEFAULT = 0;
	public const uint32 SEE_MASK_CLASSNAME = 1;
	public const uint32 SEE_MASK_CLASSKEY = 3;
	public const uint32 SEE_MASK_IDLIST = 4;
	public const uint32 SEE_MASK_INVOKEIDLIST = 12;
	public const uint32 SEE_MASK_ICON = 16;
	public const uint32 SEE_MASK_HOTKEY = 32;
	public const uint32 SEE_MASK_NOCLOSEPROCESS = 64;
	public const uint32 SEE_MASK_CONNECTNETDRV = 128;
	public const uint32 SEE_MASK_NOASYNC = 256;
	public const uint32 SEE_MASK_FLAG_DDEWAIT = 256;
	public const uint32 SEE_MASK_DOENVSUBST = 512;
	public const uint32 SEE_MASK_FLAG_NO_UI = 1024;
	public const uint32 SEE_MASK_UNICODE = 16384;
	public const uint32 SEE_MASK_NO_CONSOLE = 32768;
	public const uint32 SEE_MASK_ASYNCOK = 1048576;
	public const uint32 SEE_MASK_HMONITOR = 2097152;
	public const uint32 SEE_MASK_NOZONECHECKS = 8388608;
	public const uint32 SEE_MASK_NOQUERYCLASSSTORE = 16777216;
	public const uint32 SEE_MASK_WAITFORINPUTIDLE = 33554432;
	public const uint32 SEE_MASK_FLAG_LOG_USAGE = 67108864;
	public const uint32 SEE_MASK_FLAG_HINST_IS_SITE = 134217728;
	public const uint32 SHERB_NOCONFIRMATION = 1;
	public const uint32 SHERB_NOPROGRESSUI = 2;
	public const uint32 SHERB_NOSOUND = 4;
	public const uint32 NIN_SELECT = 1024;
	public const uint32 NINF_KEY = 1;
	public const uint32 NIN_BALLOONSHOW = 1026;
	public const uint32 NIN_BALLOONHIDE = 1027;
	public const uint32 NIN_BALLOONTIMEOUT = 1028;
	public const uint32 NIN_BALLOONUSERCLICK = 1029;
	public const uint32 NIN_POPUPOPEN = 1030;
	public const uint32 NIN_POPUPCLOSE = 1031;
	public const uint32 NOTIFYICON_VERSION = 3;
	public const uint32 NOTIFYICON_VERSION_4 = 4;
	public const uint32 SHGSI_ICONLOCATION = 0;
	public const uint64 SHGNLI_PIDL = 1;
	public const uint64 SHGNLI_PREFIXNAME = 2;
	public const uint64 SHGNLI_NOUNIQUE = 4;
	public const uint64 SHGNLI_NOLNK = 8;
	public const uint64 SHGNLI_NOLOCNAME = 16;
	public const uint64 SHGNLI_USEURLEXT = 32;
	public const uint32 PRINTACTION_OPEN = 0;
	public const uint32 PRINTACTION_PROPERTIES = 1;
	public const uint32 PRINTACTION_NETINSTALL = 2;
	public const uint32 PRINTACTION_NETINSTALLLINK = 3;
	public const uint32 PRINTACTION_TESTPAGE = 4;
	public const uint32 PRINTACTION_OPENNETPRN = 5;
	public const uint32 PRINTACTION_DOCUMENTDEFAULTS = 6;
	public const uint32 PRINTACTION_SERVERPROPERTIES = 7;
	public const uint32 PRINT_PROP_FORCE_NAME = 1;
	public const uint32 OFFLINE_STATUS_LOCAL = 1;
	public const uint32 OFFLINE_STATUS_REMOTE = 2;
	public const uint32 OFFLINE_STATUS_INCOMPLETE = 4;
	public const uint32 SHIL_LARGE = 0;
	public const uint32 SHIL_SMALL = 1;
	public const uint32 SHIL_EXTRALARGE = 2;
	public const uint32 SHIL_SYSSMALL = 3;
	public const uint32 SHIL_JUMBO = 4;
	public const uint32 SHIL_LAST = 4;
	public const String WC_NETADDRESS = "msctls_netaddress";
	public const uint32 NCM_GETADDRESS = 1025;
	public const uint32 NCM_SETALLOWTYPE = 1026;
	public const uint32 NCM_GETALLOWTYPE = 1027;
	public const uint32 NCM_DISPLAYERRORTIP = 1028;
	public const uint32 CREDENTIAL_PROVIDER_NO_DEFAULT = 4294967295;
	public const Guid Identity_LocalUserProvider = .(0xa198529b, 0x730f, 0x4089, 0xb6, 0x46, 0xa1, 0x25, 0x57, 0xf5, 0x66, 0x5e);
	public const uint32 MAX_SYNCMGR_ID = 64;
	public const uint32 MAX_SYNCMGR_PROGRESSTEXT = 260;
	public const uint32 MAX_SYNCMGR_NAME = 128;
	public const int32 STIF_DEFAULT = 0;
	public const int32 STIF_SUPPORT_HEX = 1;
	public const String SZ_CONTENTTYPE_HTMLA = "text/html";
	public const String SZ_CONTENTTYPE_HTMLW = "text/html";
	public const String SZ_CONTENTTYPE_CDFA = "application/x-cdf";
	public const String SZ_CONTENTTYPE_CDFW = "application/x-cdf";
	public const String SZ_CONTENTTYPE_HTML = "text/html";
	public const String SZ_CONTENTTYPE_CDF = "application/x-cdf";
	public const uint32 GCT_INVALID = 0;
	public const uint32 GCT_LFNCHAR = 1;
	public const uint32 GCT_SHORTCHAR = 2;
	public const uint32 GCT_WILD = 4;
	public const uint32 GCT_SEPARATOR = 8;
	public const uint32 PMSF_NORMAL = 0;
	public const uint32 PMSF_MULTIPLE = 1;
	public const uint32 PMSF_DONT_STRIP_SPACES = 65536;
	public const uint32 URL_UNESCAPE = 268435456;
	public const uint32 URL_ESCAPE_UNSAFE = 536870912;
	public const uint32 URL_PLUGGABLE_PROTOCOL = 1073741824;
	public const uint32 URL_WININET_COMPATIBILITY = 2147483648;
	public const uint32 URL_DONT_ESCAPE_EXTRA_INFO = 33554432;
	public const uint32 URL_DONT_UNESCAPE_EXTRA_INFO = 33554432;
	public const uint32 URL_BROWSER_MODE = 33554432;
	public const uint32 URL_ESCAPE_SPACES_ONLY = 67108864;
	public const uint32 URL_DONT_SIMPLIFY = 134217728;
	public const uint32 URL_NO_META = 134217728;
	public const uint32 URL_UNESCAPE_INPLACE = 1048576;
	public const uint32 URL_CONVERT_IF_DOSPATH = 2097152;
	public const uint32 URL_UNESCAPE_HIGH_ANSI_ONLY = 4194304;
	public const uint32 URL_INTERNAL_PATH = 8388608;
	public const uint32 URL_FILE_USE_PATHURL = 65536;
	public const uint32 URL_DONT_UNESCAPE = 131072;
	public const uint32 URL_ESCAPE_AS_UTF8 = 262144;
	public const uint32 URL_UNESCAPE_AS_UTF8 = 262144;
	public const uint32 URL_ESCAPE_ASCII_URI_COMPONENT = 524288;
	public const uint32 URL_UNESCAPE_URI_COMPONENT = 262144;
	public const uint32 URL_ESCAPE_PERCENT = 4096;
	public const uint32 URL_ESCAPE_SEGMENT_ONLY = 8192;
	public const uint32 URL_PARTFLAG_KEEPSCHEME = 1;
	public const uint32 URL_APPLY_DEFAULT = 1;
	public const uint32 URL_APPLY_GUESSSCHEME = 2;
	public const uint32 URL_APPLY_GUESSFILE = 4;
	public const uint32 URL_APPLY_FORCEAPPLY = 8;
	public const uint32 SRRF_RT_REG_NONE = 1;
	public const uint32 SRRF_RT_REG_SZ = 2;
	public const uint32 SRRF_RT_REG_EXPAND_SZ = 4;
	public const uint32 SRRF_RT_REG_BINARY = 8;
	public const uint32 SRRF_RT_REG_DWORD = 16;
	public const uint32 SRRF_RT_REG_MULTI_SZ = 32;
	public const uint32 SRRF_RT_REG_QWORD = 64;
	public const uint32 SRRF_RT_ANY = 65535;
	public const uint32 SRRF_RM_ANY = 0;
	public const uint32 SRRF_RM_NORMAL = 65536;
	public const uint32 SRRF_RM_SAFE = 131072;
	public const uint32 SRRF_RM_SAFENETWORK = 262144;
	public const uint32 SRRF_NOEXPAND = 268435456;
	public const uint32 SRRF_ZEROONFAILURE = 536870912;
	public const uint32 SRRF_NOVIRT = 1073741824;
	public const uint32 SHREGSET_HKCU = 1;
	public const uint32 SHREGSET_FORCE_HKCU = 2;
	public const uint32 SHREGSET_HKLM = 4;
	public const uint32 SHREGSET_FORCE_HKLM = 8;
	public const uint32 SPMODE_SHELL = 1;
	public const uint32 SPMODE_DEBUGOUT = 2;
	public const uint32 SPMODE_TEST = 4;
	public const uint32 SPMODE_BROWSER = 8;
	public const uint32 SPMODE_FLUSH = 16;
	public const uint32 SPMODE_EVENT = 32;
	public const uint32 SPMODE_MSVM = 64;
	public const uint32 SPMODE_FORMATTEXT = 128;
	public const uint32 SPMODE_PROFILE = 256;
	public const uint32 SPMODE_DEBUGBREAK = 512;
	public const uint32 SPMODE_MSGTRACE = 1024;
	public const uint32 SPMODE_PERFTAGS = 2048;
	public const uint32 SPMODE_MEMWATCH = 4096;
	public const uint32 SPMODE_DBMON = 8192;
	public const uint32 SPMODE_MULTISTOP = 16384;
	public const uint32 SPMODE_EVENTTRACE = 32768;
	public const uint32 SHGVSPB_PERUSER = 1;
	public const uint32 SHGVSPB_ALLUSERS = 2;
	public const uint32 SHGVSPB_PERFOLDER = 4;
	public const uint32 SHGVSPB_ALLFOLDERS = 8;
	public const uint32 SHGVSPB_INHERIT = 16;
	public const uint32 SHGVSPB_ROAM = 32;
	public const uint32 SHGVSPB_NOAUTODEFAULTS = 2147483648;
	public const uint32 FDTF_SHORTTIME = 1;
	public const uint32 FDTF_SHORTDATE = 2;
	public const uint32 FDTF_LONGDATE = 4;
	public const uint32 FDTF_LONGTIME = 8;
	public const uint32 FDTF_RELATIVE = 16;
	public const uint32 FDTF_LTRDATE = 256;
	public const uint32 FDTF_RTLDATE = 512;
	public const uint32 FDTF_NOAUTOREADINGORDER = 1024;
	public const uint32 PLATFORM_UNKNOWN = 0;
	public const uint32 PLATFORM_IE3 = 1;
	public const uint32 PLATFORM_BROWSERONLY = 1;
	public const uint32 PLATFORM_INTEGRATED = 2;
	public const uint32 ILMM_IE4 = 0;
	public const uint32 DLLVER_PLATFORM_WINDOWS = 1;
	public const uint32 DLLVER_PLATFORM_NT = 2;
	public const uint64 DLLVER_MAJOR_MASK = 18446462598732840960;
	public const uint64 DLLVER_MINOR_MASK = 281470681743360;
	public const uint64 DLLVER_BUILD_MASK = 4294901760;
	public const uint64 DLLVER_QFE_MASK = 65535;
	public const HRESULT WTS_E_FAILEDEXTRACTION = -2147175936;
	public const HRESULT WTS_E_EXTRACTIONTIMEDOUT = -2147175935;
	public const HRESULT WTS_E_SURROGATEUNAVAILABLE = -2147175934;
	public const HRESULT WTS_E_FASTEXTRACTIONNOTSUPPORTED = -2147175933;
	public const HRESULT WTS_E_DATAFILEUNAVAILABLE = -2147175932;
	public const HRESULT WTS_E_EXTRACTIONPENDING = -2147175931;
	public const HRESULT WTS_E_EXTRACTIONBLOCKED = -2147175930;
	public const HRESULT WTS_E_NOSTORAGEPROVIDERTHUMBNAILHANDLER = -2147175929;
	public const String SHIMGKEY_QUALITY = "Compression";
	public const String SHIMGKEY_RAWFORMAT = "RawDataFormat";
	public const uint32 SHIMGDEC_DEFAULT = 0;
	public const uint32 SHIMGDEC_THUMBNAIL = 1;
	public const uint32 SHIMGDEC_LOADFULL = 2;
	public const HRESULT E_NOTVALIDFORANIMATEDIMAGE = -2147221503;
	public const HRESULT S_SYNCMGR_MISSINGITEMS = 262657;
	public const HRESULT S_SYNCMGR_RETRYSYNC = 262658;
	public const HRESULT S_SYNCMGR_CANCELITEM = 262659;
	public const HRESULT S_SYNCMGR_CANCELALL = 262660;
	public const HRESULT S_SYNCMGR_ITEMDELETED = 262672;
	public const HRESULT S_SYNCMGR_ENUMITEMS = 262673;
	public const uint32 SYNCMGRPROGRESSITEM_STATUSTEXT = 1;
	public const uint32 SYNCMGRPROGRESSITEM_STATUSTYPE = 2;
	public const uint32 SYNCMGRPROGRESSITEM_PROGVALUE = 4;
	public const uint32 SYNCMGRPROGRESSITEM_MAXVALUE = 8;
	public const uint32 SYNCMGRLOGERROR_ERRORFLAGS = 1;
	public const uint32 SYNCMGRLOGERROR_ERRORID = 2;
	public const uint32 SYNCMGRLOGERROR_ITEMID = 4;
	public const uint32 SYNCMGRITEM_ITEMFLAGMASK = 127;
	public const uint32 MAX_SYNCMGRITEMNAME = 128;
	public const uint32 SYNCMGRHANDLERFLAG_MASK = 15;
	public const uint32 MAX_SYNCMGRHANDLERNAME = 32;
	public const uint32 SYNCMGRREGISTERFLAGS_MASK = 7;
	public const int32 TLOG_BACK = -1;
	public const uint32 TLOG_CURRENT = 0;
	public const uint32 TLOG_FORE = 1;
	public const uint32 TLMENUF_INCLUDECURRENT = 1;
	public const uint32 TLMENUF_BACK = 16;
	public const uint32 TLMENUF_FORE = 32;
	public const uint32 BSF_REGISTERASDROPTARGET = 1;
	public const uint32 BSF_THEATERMODE = 2;
	public const uint32 BSF_NOLOCALFILEWARNING = 16;
	public const uint32 BSF_UISETBYAUTOMATION = 256;
	public const uint32 BSF_RESIZABLE = 512;
	public const uint32 BSF_CANMAXIMIZE = 1024;
	public const uint32 BSF_TOPBROWSER = 2048;
	public const uint32 BSF_NAVNOHISTORY = 4096;
	public const uint32 BSF_HTMLNAVCANCELED = 8192;
	public const uint32 BSF_DONTSHOWNAVCANCELPAGE = 16384;
	public const uint32 BSF_SETNAVIGATABLECODEPAGE = 32768;
	public const uint32 BSF_DELEGATEDNAVIGATION = 65536;
	public const uint32 BSF_TRUSTEDFORACTIVEX = 131072;
	public const uint32 BSF_MERGEDMENUS = 262144;
	public const uint32 BSF_FEEDNAVIGATION = 524288;
	public const uint32 BSF_FEEDSUBSCRIBED = 1048576;
	public const uint32 HLNF_CALLERUNTRUSTED = 2097152;
	public const uint32 HLNF_TRUSTEDFORACTIVEX = 4194304;
	public const uint32 HLNF_DISABLEWINDOWRESTRICTIONS = 8388608;
	public const uint32 HLNF_TRUSTFIRSTDOWNLOAD = 16777216;
	public const uint32 HLNF_UNTRUSTEDFORDOWNLOAD = 33554432;
	public const uint32 SHHLNF_NOAUTOSELECT = 67108864;
	public const uint32 SHHLNF_WRITENOHISTORY = 134217728;
	public const uint32 HLNF_EXTERNALNAVIGATE = 268435456;
	public const uint32 HLNF_ALLOW_AUTONAVIGATE = 536870912;
	public const uint32 HLNF_NEWWINDOWSMANAGED = 2147483648;
	public const uint32 INTERNET_MAX_PATH_LENGTH = 2048;
	public const uint32 INTERNET_MAX_SCHEME_LENGTH = 32;
	public const uint32 VIEW_PRIORITY_RESTRICTED = 112;
	public const uint32 VIEW_PRIORITY_CACHEHIT = 80;
	public const uint32 VIEW_PRIORITY_STALECACHEHIT = 69;
	public const uint32 VIEW_PRIORITY_USEASDEFAULT = 67;
	public const uint32 VIEW_PRIORITY_SHELLEXT = 64;
	public const uint32 VIEW_PRIORITY_CACHEMISS = 48;
	public const uint32 VIEW_PRIORITY_INHERIT = 32;
	public const uint32 VIEW_PRIORITY_SHELLEXT_ASBACKUP = 21;
	public const uint32 VIEW_PRIORITY_DESPERATE = 16;
	public const uint32 VIEW_PRIORITY_NONE = 0;
	public const String VOLUME_PREFIX = "\\\\?\\Volume";
	public const uint32 PATHCCH_MAX_CCH = 32768;
	public const uint32 IDS_DESCRIPTION = 1;
	public const uint32 ID_APP = 100;
	public const uint32 DLG_SCRNSAVECONFIGURE = 2003;
	public const uint32 idsIsPassword = 1000;
	public const uint32 idsIniFile = 1001;
	public const uint32 idsScreenSaver = 1002;
	public const uint32 idsPassword = 1003;
	public const uint32 idsDifferentPW = 1004;
	public const uint32 idsChangePW = 1005;
	public const uint32 idsBadOldPW = 1006;
	public const uint32 idsAppName = 1007;
	public const uint32 idsNoHelpMemory = 1008;
	public const uint32 idsHelpFile = 1009;
	public const uint32 idsDefKeyword = 1010;
	public const uint32 MAXFILELEN = 13;
	public const uint32 TITLEBARNAMELEN = 40;
	public const uint32 APPNAMEBUFFERLEN = 40;
	public const uint32 BUFFLEN = 255;
	public const uint32 SCRM_VERIFYPW = 32768;
	public const HRESULT E_FLAGS = -2147217408;
	public const HRESULT IS_E_EXEC_FAILED = -2147213310;
	public const HRESULT URL_E_INVALID_SYNTAX = -2147217407;
	public const HRESULT URL_E_UNREGISTERED_PROTOCOL = -2147217406;
	public const uint32 CPLPAGE_MOUSE_BUTTONS = 1;
	public const uint32 CPLPAGE_MOUSE_PTRMOTION = 2;
	public const uint32 CPLPAGE_MOUSE_WHEEL = 3;
	public const uint32 CPLPAGE_KEYBOARD_SPEED = 1;
	public const uint32 CPLPAGE_DISPLAY_BACKGROUND = 1;
	public const uint32 DISPID_SELECTIONCHANGED = 200;
	public const uint32 DISPID_FILELISTENUMDONE = 201;
	public const uint32 DISPID_VERBINVOKED = 202;
	public const uint32 DISPID_DEFAULTVERBINVOKED = 203;
	public const uint32 DISPID_BEGINDRAG = 204;
	public const uint32 DISPID_VIEWMODECHANGED = 205;
	public const uint32 DISPID_NOITEMSTATE_CHANGED = 206;
	public const uint32 DISPID_CONTENTSCHANGED = 207;
	public const uint32 DISPID_FOCUSCHANGED = 208;
	public const uint32 DISPID_CHECKSTATECHANGED = 209;
	public const uint32 DISPID_ORDERCHANGED = 210;
	public const uint32 DISPID_VIEWPAINTDONE = 211;
	public const uint32 DISPID_COLUMNSCHANGED = 212;
	public const uint32 DISPID_CTRLMOUSEWHEEL = 213;
	public const uint32 DISPID_SORTDONE = 214;
	public const uint32 DISPID_ICONSIZECHANGED = 215;
	public const uint32 DISPID_FOLDERCHANGED = 217;
	public const uint32 DISPID_FILTERINVOKED = 218;
	public const uint32 DISPID_WORDWHEELEDITED = 219;
	public const uint32 DISPID_SELECTEDITEMCHANGED = 220;
	public const uint32 DISPID_EXPLORERWINDOWREADY = 221;
	public const uint32 DISPID_UPDATEIMAGE = 222;
	public const uint32 DISPID_INITIALENUMERATIONDONE = 223;
	public const uint32 DISPID_ENTERPRISEIDCHANGED = 224;
	public const uint32 DISPID_ENTERPRESSED = 200;
	public const uint32 DISPID_SEARCHCOMMAND_START = 1;
	public const uint32 DISPID_SEARCHCOMMAND_COMPLETE = 2;
	public const uint32 DISPID_SEARCHCOMMAND_ABORT = 3;
	public const uint32 DISPID_SEARCHCOMMAND_UPDATE = 4;
	public const uint32 DISPID_SEARCHCOMMAND_PROGRESSTEXT = 5;
	public const uint32 DISPID_SEARCHCOMMAND_ERROR = 6;
	public const uint32 DISPID_SEARCHCOMMAND_RESTORE = 7;
	public const uint32 DISPID_IADCCTL_DIRTY = 256;
	public const uint32 DISPID_IADCCTL_PUBCAT = 257;
	public const uint32 DISPID_IADCCTL_SORT = 258;
	public const uint32 DISPID_IADCCTL_FORCEX86 = 259;
	public const uint32 DISPID_IADCCTL_SHOWPOSTSETUP = 260;
	public const uint32 DISPID_IADCCTL_ONDOMAIN = 261;
	public const uint32 DISPID_IADCCTL_DEFAULTCAT = 262;
	public const HRESULT COPYENGINE_S_YES = 2555905;
	public const HRESULT COPYENGINE_S_NOT_HANDLED = 2555907;
	public const HRESULT COPYENGINE_S_USER_RETRY = 2555908;
	public const HRESULT COPYENGINE_S_USER_IGNORED = 2555909;
	public const HRESULT COPYENGINE_S_MERGE = 2555910;
	public const HRESULT COPYENGINE_S_DONT_PROCESS_CHILDREN = 2555912;
	public const HRESULT COPYENGINE_S_ALREADY_DONE = 2555914;
	public const HRESULT COPYENGINE_S_PENDING = 2555915;
	public const HRESULT COPYENGINE_S_KEEP_BOTH = 2555916;
	public const HRESULT COPYENGINE_S_CLOSE_PROGRAM = 2555917;
	public const HRESULT COPYENGINE_S_COLLISIONRESOLVED = 2555918;
	public const HRESULT COPYENGINE_S_PROGRESS_PAUSE = 2555919;
	public const HRESULT COPYENGINE_E_USER_CANCELLED = -2144927744;
	public const HRESULT COPYENGINE_E_CANCELLED = -2144927743;
	public const HRESULT COPYENGINE_E_REQUIRES_ELEVATION = -2144927742;
	public const HRESULT COPYENGINE_E_SAME_FILE = -2144927741;
	public const HRESULT COPYENGINE_E_DIFF_DIR = -2144927740;
	public const HRESULT COPYENGINE_E_MANY_SRC_1_DEST = -2144927739;
	public const HRESULT COPYENGINE_E_DEST_SUBTREE = -2144927735;
	public const HRESULT COPYENGINE_E_DEST_SAME_TREE = -2144927734;
	public const HRESULT COPYENGINE_E_FLD_IS_FILE_DEST = -2144927733;
	public const HRESULT COPYENGINE_E_FILE_IS_FLD_DEST = -2144927732;
	public const HRESULT COPYENGINE_E_FILE_TOO_LARGE = -2144927731;
	public const HRESULT COPYENGINE_E_REMOVABLE_FULL = -2144927730;
	public const HRESULT COPYENGINE_E_DEST_IS_RO_CD = -2144927729;
	public const HRESULT COPYENGINE_E_DEST_IS_RW_CD = -2144927728;
	public const HRESULT COPYENGINE_E_DEST_IS_R_CD = -2144927727;
	public const HRESULT COPYENGINE_E_DEST_IS_RO_DVD = -2144927726;
	public const HRESULT COPYENGINE_E_DEST_IS_RW_DVD = -2144927725;
	public const HRESULT COPYENGINE_E_DEST_IS_R_DVD = -2144927724;
	public const HRESULT COPYENGINE_E_SRC_IS_RO_CD = -2144927723;
	public const HRESULT COPYENGINE_E_SRC_IS_RW_CD = -2144927722;
	public const HRESULT COPYENGINE_E_SRC_IS_R_CD = -2144927721;
	public const HRESULT COPYENGINE_E_SRC_IS_RO_DVD = -2144927720;
	public const HRESULT COPYENGINE_E_SRC_IS_RW_DVD = -2144927719;
	public const HRESULT COPYENGINE_E_SRC_IS_R_DVD = -2144927718;
	public const HRESULT COPYENGINE_E_INVALID_FILES_SRC = -2144927717;
	public const HRESULT COPYENGINE_E_INVALID_FILES_DEST = -2144927716;
	public const HRESULT COPYENGINE_E_PATH_TOO_DEEP_SRC = -2144927715;
	public const HRESULT COPYENGINE_E_PATH_TOO_DEEP_DEST = -2144927714;
	public const HRESULT COPYENGINE_E_ROOT_DIR_SRC = -2144927713;
	public const HRESULT COPYENGINE_E_ROOT_DIR_DEST = -2144927712;
	public const HRESULT COPYENGINE_E_ACCESS_DENIED_SRC = -2144927711;
	public const HRESULT COPYENGINE_E_ACCESS_DENIED_DEST = -2144927710;
	public const HRESULT COPYENGINE_E_PATH_NOT_FOUND_SRC = -2144927709;
	public const HRESULT COPYENGINE_E_PATH_NOT_FOUND_DEST = -2144927708;
	public const HRESULT COPYENGINE_E_NET_DISCONNECT_SRC = -2144927707;
	public const HRESULT COPYENGINE_E_NET_DISCONNECT_DEST = -2144927706;
	public const HRESULT COPYENGINE_E_SHARING_VIOLATION_SRC = -2144927705;
	public const HRESULT COPYENGINE_E_SHARING_VIOLATION_DEST = -2144927704;
	public const HRESULT COPYENGINE_E_ALREADY_EXISTS_NORMAL = -2144927703;
	public const HRESULT COPYENGINE_E_ALREADY_EXISTS_READONLY = -2144927702;
	public const HRESULT COPYENGINE_E_ALREADY_EXISTS_SYSTEM = -2144927701;
	public const HRESULT COPYENGINE_E_ALREADY_EXISTS_FOLDER = -2144927700;
	public const HRESULT COPYENGINE_E_STREAM_LOSS = -2144927699;
	public const HRESULT COPYENGINE_E_EA_LOSS = -2144927698;
	public const HRESULT COPYENGINE_E_PROPERTY_LOSS = -2144927697;
	public const HRESULT COPYENGINE_E_PROPERTIES_LOSS = -2144927696;
	public const HRESULT COPYENGINE_E_ENCRYPTION_LOSS = -2144927695;
	public const HRESULT COPYENGINE_E_DISK_FULL = -2144927694;
	public const HRESULT COPYENGINE_E_DISK_FULL_CLEAN = -2144927693;
	public const HRESULT COPYENGINE_E_EA_NOT_SUPPORTED = -2144927692;
	public const HRESULT COPYENGINE_E_CANT_REACH_SOURCE = -2144927691;
	public const HRESULT COPYENGINE_E_RECYCLE_UNKNOWN_ERROR = -2144927691;
	public const HRESULT COPYENGINE_E_RECYCLE_FORCE_NUKE = -2144927690;
	public const HRESULT COPYENGINE_E_RECYCLE_SIZE_TOO_BIG = -2144927689;
	public const HRESULT COPYENGINE_E_RECYCLE_PATH_TOO_LONG = -2144927688;
	public const HRESULT COPYENGINE_E_RECYCLE_BIN_NOT_FOUND = -2144927686;
	public const HRESULT COPYENGINE_E_NEWFILE_NAME_TOO_LONG = -2144927685;
	public const HRESULT COPYENGINE_E_NEWFOLDER_NAME_TOO_LONG = -2144927684;
	public const HRESULT COPYENGINE_E_DIR_NOT_EMPTY = -2144927683;
	public const HRESULT COPYENGINE_E_FAT_MAX_IN_ROOT = -2144927682;
	public const HRESULT COPYENGINE_E_ACCESSDENIED_READONLY = -2144927681;
	public const HRESULT COPYENGINE_E_REDIRECTED_TO_WEBPAGE = -2144927680;
	public const HRESULT COPYENGINE_E_SERVER_BAD_FILE_TYPE = -2144927679;
	public const HRESULT COPYENGINE_E_INTERNET_ITEM_UNAVAILABLE = -2144927678;
	public const HRESULT COPYENGINE_E_CANNOT_MOVE_FROM_RECYCLE_BIN = -2144927677;
	public const HRESULT COPYENGINE_E_CANNOT_MOVE_SHARED_FOLDER = -2144927676;
	public const HRESULT COPYENGINE_E_INTERNET_ITEM_STORAGE_PROVIDER_ERROR = -2144927675;
	public const HRESULT COPYENGINE_E_INTERNET_ITEM_STORAGE_PROVIDER_PAUSED = -2144927674;
	public const HRESULT COPYENGINE_E_REQUIRES_EDP_CONSENT = -2144927673;
	public const HRESULT COPYENGINE_E_BLOCKED_BY_EDP_POLICY = -2144927672;
	public const HRESULT COPYENGINE_E_REQUIRES_EDP_CONSENT_FOR_REMOVABLE_DRIVE = -2144927671;
	public const HRESULT COPYENGINE_E_BLOCKED_BY_EDP_FOR_REMOVABLE_DRIVE = -2144927670;
	public const HRESULT COPYENGINE_E_RMS_REQUIRES_EDP_CONSENT_FOR_REMOVABLE_DRIVE = -2144927669;
	public const HRESULT COPYENGINE_E_RMS_BLOCKED_BY_EDP_FOR_REMOVABLE_DRIVE = -2144927668;
	public const HRESULT COPYENGINE_E_WARNED_BY_DLP_POLICY = -2144927667;
	public const HRESULT COPYENGINE_E_BLOCKED_BY_DLP_POLICY = -2144927666;
	public const HRESULT COPYENGINE_E_SILENT_FAIL_BY_DLP_POLICY = -2144927665;
	public const HRESULT NETCACHE_E_NEGATIVE_CACHE = -2144927488;
	public const HRESULT EXECUTE_E_LAUNCH_APPLICATION = -2144927487;
	public const HRESULT SHELL_E_WRONG_BITDEPTH = -2144927486;
	public const HRESULT LINK_E_DELETE = -2144927485;
	public const HRESULT STORE_E_NEWER_VERSION_AVAILABLE = -2144927484;
	public const HRESULT E_FILE_PLACEHOLDER_NOT_INITIALIZED = -2144927472;
	public const HRESULT E_FILE_PLACEHOLDER_VERSION_MISMATCH = -2144927471;
	public const HRESULT E_FILE_PLACEHOLDER_SERVER_TIMED_OUT = -2144927470;
	public const HRESULT E_FILE_PLACEHOLDER_STORAGEPROVIDER_NOT_FOUND = -2144927469;
	public const HRESULT CAMERAROLL_E_NO_DOWNSAMPLING_REQUIRED = -2144927456;
	public const HRESULT E_ACTIVATIONDENIED_USERCLOSE = -2144927440;
	public const HRESULT E_ACTIVATIONDENIED_SHELLERROR = -2144927439;
	public const HRESULT E_ACTIVATIONDENIED_SHELLRESTART = -2144927438;
	public const HRESULT E_ACTIVATIONDENIED_UNEXPECTED = -2144927437;
	public const HRESULT E_ACTIVATIONDENIED_SHELLNOTREADY = -2144927436;
	public const HRESULT LIBRARY_E_NO_SAVE_LOCATION = -2144927232;
	public const HRESULT LIBRARY_E_NO_ACCESSIBLE_LOCATION = -2144927231;
	public const HRESULT E_USERTILE_UNSUPPORTEDFILETYPE = -2144927216;
	public const HRESULT E_USERTILE_CHANGEDISABLED = -2144927215;
	public const HRESULT E_USERTILE_LARGEORDYNAMIC = -2144927214;
	public const HRESULT E_USERTILE_VIDEOFRAMESIZE = -2144927213;
	public const HRESULT E_USERTILE_FILESIZE = -2144927212;
	public const HRESULT IMM_ACC_DOCKING_E_INSUFFICIENTHEIGHT = -2144927184;
	public const HRESULT IMM_ACC_DOCKING_E_DOCKOCCUPIED = -2144927183;
	public const HRESULT IMSC_E_SHELL_COMPONENT_STARTUP_FAILURE = -2144927181;
	public const HRESULT SHC_E_SHELL_COMPONENT_STARTUP_FAILURE = -2144927180;
	public const HRESULT E_TILE_NOTIFICATIONS_PLATFORM_FAILURE = -2144927159;
	public const HRESULT E_SHELL_EXTENSION_BLOCKED = -2144926975;
	public const HRESULT E_IMAGEFEED_CHANGEDISABLED = -2144926960;
	public const int32 ISHCUTCMDID_DOWNLOADICON = 0;
	public const int32 ISHCUTCMDID_INTSHORTCUTCREATE = 1;
	public const int32 ISHCUTCMDID_COMMITHISTORY = 2;
	public const int32 ISHCUTCMDID_SETUSERAWURL = 3;
	public const int32 SFBID_PIDLCHANGED = 0;
	public const int32 DBCID_EMPTY = 0;
	public const int32 DBCID_ONDRAG = 1;
	public const int32 DBCID_CLSIDOFBAR = 2;
	public const int32 DBCID_RESIZE = 3;
	public const int32 DBCID_GETBAR = 4;
	public const int32 DBCID_UPDATESIZE = 5;
	public const int32 BMICON_LARGE = 0;
	public const int32 BMICON_SMALL = 1;
	public const int32 ASSOCF_NONE = 0;
	public const int32 ASSOCF_INIT_NOREMAPCLSID = 1;
	public const int32 ASSOCF_INIT_BYEXENAME = 2;
	public const int32 ASSOCF_OPEN_BYEXENAME = 2;
	public const int32 ASSOCF_INIT_DEFAULTTOSTAR = 4;
	public const int32 ASSOCF_INIT_DEFAULTTOFOLDER = 8;
	public const int32 ASSOCF_NOUSERSETTINGS = 16;
	public const int32 ASSOCF_NOTRUNCATE = 32;
	public const int32 ASSOCF_VERIFY = 64;
	public const int32 ASSOCF_REMAPRUNDLL = 128;
	public const int32 ASSOCF_NOFIXUPS = 256;
	public const int32 ASSOCF_IGNOREBASECLASS = 512;
	public const int32 ASSOCF_INIT_IGNOREUNKNOWN = 1024;
	public const int32 ASSOCF_INIT_FIXED_PROGID = 2048;
	public const int32 ASSOCF_IS_PROTOCOL = 4096;
	public const int32 ASSOCF_INIT_FOR_FILE = 8192;
	public const int32 ASSOCF_IS_FULL_URI = 16384;
	public const int32 ASSOCF_PER_MACHINE_ONLY = 32768;
	public const int32 ASSOCF_APP_TO_APP = 65536;
	public const int32 CTF_INSIST = 1;
	public const int32 CTF_THREAD_REF = 2;
	public const int32 CTF_PROCESS_REF = 4;
	public const int32 CTF_COINIT_STA = 8;
	public const int32 CTF_COINIT = 8;
	public const int32 CTF_FREELIBANDEXIT = 16;
	public const int32 CTF_REF_COUNTED = 32;
	public const int32 CTF_WAIT_ALLOWCOM = 64;
	public const int32 CTF_UNUSED = 128;
	public const int32 CTF_INHERITWOW64 = 256;
	public const int32 CTF_WAIT_NO_REENTRANCY = 512;
	public const int32 CTF_KEYBOARD_LOCALE = 1024;
	public const int32 CTF_OLEINITIALIZE = 2048;
	public const int32 CTF_COINIT_MTA = 4096;
	public const int32 CTF_NOADDREFLIB = 8192;
}
#endregion

#region TypeDefs
typealias ShFindChangeNotificationHandle = int;

typealias HDROP = int;

typealias HPSXA = int;

#endregion


#region Enums

[AllowDuplicates]
public enum SHGFI_FLAGS : int32
{
	SHGFI_ADDOVERLAYS = 32,
	SHGFI_ATTR_SPECIFIED = 131072,
	SHGFI_ATTRIBUTES = 2048,
	SHGFI_DISPLAYNAME = 512,
	SHGFI_EXETYPE = 8192,
	SHGFI_ICON = 256,
	SHGFI_ICONLOCATION = 4096,
	SHGFI_LARGEICON = 0,
	SHGFI_LINKOVERLAY = 32768,
	SHGFI_OPENICON = 2,
	SHGFI_OVERLAYINDEX = 64,
	SHGFI_PIDL = 8,
	SHGFI_SELECTED = 65536,
	SHGFI_SHELLICONSIZE = 4,
	SHGFI_SMALLICON = 1,
	SHGFI_SYSICONINDEX = 16384,
	SHGFI_TYPENAME = 1024,
	SHGFI_USEFILEATTRIBUTES = 16,
}


[AllowDuplicates]
public enum SHCNE_ID : uint32
{
	SHCNE_RENAMEITEM = 1,
	SHCNE_CREATE = 2,
	SHCNE_DELETE = 4,
	SHCNE_MKDIR = 8,
	SHCNE_RMDIR = 16,
	SHCNE_MEDIAINSERTED = 32,
	SHCNE_MEDIAREMOVED = 64,
	SHCNE_DRIVEREMOVED = 128,
	SHCNE_DRIVEADD = 256,
	SHCNE_NETSHARE = 512,
	SHCNE_NETUNSHARE = 1024,
	SHCNE_ATTRIBUTES = 2048,
	SHCNE_UPDATEDIR = 4096,
	SHCNE_UPDATEITEM = 8192,
	SHCNE_SERVERDISCONNECT = 16384,
	SHCNE_UPDATEIMAGE = 32768,
	SHCNE_DRIVEADDGUI = 65536,
	SHCNE_RENAMEFOLDER = 131072,
	SHCNE_FREESPACE = 262144,
	SHCNE_EXTENDED_EVENT = 67108864,
	SHCNE_ASSOCCHANGED = 134217728,
	SHCNE_DISKEVENTS = 145439,
	SHCNE_GLOBALEVENTS = 201687520,
	SHCNE_ALLEVENTS = 2147483647,
	SHCNE_INTERRUPT = 2147483648,
}


[AllowDuplicates]
public enum SHCNRF_SOURCE : int32
{
	SHCNRF_InterruptLevel = 1,
	SHCNRF_ShellLevel = 2,
	SHCNRF_RecursiveInterrupt = 4096,
	SHCNRF_NewDelivery = 32768,
}


[AllowDuplicates]
public enum SHCNF_FLAGS : uint32
{
	SHCNF_IDLIST = 0,
	SHCNF_PATHA = 1,
	SHCNF_PRINTERA = 2,
	SHCNF_DWORD = 3,
	SHCNF_PATHW = 5,
	SHCNF_PRINTERW = 6,
	SHCNF_TYPE = 255,
	SHCNF_FLUSH = 4096,
	SHCNF_FLUSHNOWAIT = 12288,
	SHCNF_NOTIFYRECURSIVE = 65536,
	SHCNF_PATH = 5,
	SHCNF_PRINTER = 6,
}


[AllowDuplicates]
public enum QITIPF_FLAGS : int32
{
	QITIPF_DEFAULT = 0,
	QITIPF_USENAME = 1,
	QITIPF_LINKNOTARGET = 2,
	QITIPF_LINKUSETARGET = 4,
	QITIPF_USESLOWTIP = 8,
	QITIPF_SINGLELINE = 16,
	QIF_CACHED = 1,
	QIF_DONTEXPANDFOLDER = 2,
}


[AllowDuplicates]
public enum SHDID_ID : int32
{
	SHDID_ROOT_REGITEM = 1,
	SHDID_FS_FILE = 2,
	SHDID_FS_DIRECTORY = 3,
	SHDID_FS_OTHER = 4,
	SHDID_COMPUTER_DRIVE35 = 5,
	SHDID_COMPUTER_DRIVE525 = 6,
	SHDID_COMPUTER_REMOVABLE = 7,
	SHDID_COMPUTER_FIXED = 8,
	SHDID_COMPUTER_NETDRIVE = 9,
	SHDID_COMPUTER_CDROM = 10,
	SHDID_COMPUTER_RAMDISK = 11,
	SHDID_COMPUTER_OTHER = 12,
	SHDID_NET_DOMAIN = 13,
	SHDID_NET_SERVER = 14,
	SHDID_NET_SHARE = 15,
	SHDID_NET_RESTOFNET = 16,
	SHDID_NET_OTHER = 17,
	SHDID_COMPUTER_IMAGING = 18,
	SHDID_COMPUTER_AUDIO = 19,
	SHDID_COMPUTER_SHAREDDOCS = 20,
	SHDID_MOBILE_DEVICE = 21,
	SHDID_REMOTE_DESKTOP_DRIVE = 22,
}


[AllowDuplicates]
public enum SHGDFIL_FORMAT : int32
{
	SHGDFIL_FINDDATA = 1,
	SHGDFIL_NETRESOURCE = 2,
	SHGDFIL_DESCRIPTIONID = 3,
}


[AllowDuplicates]
public enum PRF_FLAGS : int32
{
	PRF_VERIFYEXISTS = 1,
	PRF_TRYPROGRAMEXTENSIONS = 3,
	PRF_FIRSTDIRDEF = 4,
	PRF_DONTFINDLNK = 8,
	PRF_REQUIREABSOLUTE = 16,
}


[AllowDuplicates]
public enum PCS_RET : uint32
{
	PCS_FATAL = 2147483648,
	PCS_REPLACEDCHAR = 1,
	PCS_REMOVEDCHAR = 2,
	PCS_TRUNCATED = 4,
	PCS_PATHTOOLONG = 8,
}


[AllowDuplicates]
public enum MM_FLAGS : uint32
{
	MM_ADDSEPARATOR = 1,
	MM_SUBMENUSHAVEIDS = 2,
	MM_DONTREMOVESEPS = 4,
}


[AllowDuplicates]
public enum SHOP_TYPE : int32
{
	SHOP_PRINTERNAME = 1,
	SHOP_FILEPATH = 2,
	SHOP_VOLUMEGUID = 4,
}


[AllowDuplicates]
public enum SHFMT_ID : uint32
{
	SHFMT_ID_DEFAULT = 65535,
}


[AllowDuplicates]
public enum SHFMT_OPT : int32
{
	SHFMT_OPT_NONE = 0,
	SHFMT_OPT_FULL = 1,
	SHFMT_OPT_SYSONLY = 2,
}


[AllowDuplicates]
public enum SHFMT_RET : uint32
{
	SHFMT_ERROR = 4294967295,
	SHFMT_CANCEL = 4294967294,
	SHFMT_NOFORMAT = 4294967293,
}


[AllowDuplicates]
public enum VALIDATEUNC_OPTION : int32
{
	VALIDATEUNC_CONNECT = 1,
	VALIDATEUNC_NOUI = 2,
	VALIDATEUNC_PRINT = 4,
	VALIDATEUNC_PERSIST = 8,
	VALIDATEUNC_VALID = 15,
}


[AllowDuplicates]
public enum SFVM_MESSAGE_ID : int32
{
	SFVM_MERGEMENU = 1,
	SFVM_INVOKECOMMAND = 2,
	SFVM_GETHELPTEXT = 3,
	SFVM_GETTOOLTIPTEXT = 4,
	SFVM_GETBUTTONINFO = 5,
	SFVM_GETBUTTONS = 6,
	SFVM_INITMENUPOPUP = 7,
	SFVM_FSNOTIFY = 14,
	SFVM_WINDOWCREATED = 15,
	SFVM_GETDETAILSOF = 23,
	SFVM_COLUMNCLICK = 24,
	SFVM_QUERYFSNOTIFY = 25,
	SFVM_DEFITEMCOUNT = 26,
	SFVM_DEFVIEWMODE = 27,
	SFVM_UNMERGEMENU = 28,
	SFVM_UPDATESTATUSBAR = 31,
	SFVM_BACKGROUNDENUM = 32,
	SFVM_DIDDRAGDROP = 36,
	SFVM_SETISFV = 39,
	SFVM_THISIDLIST = 41,
	SFVM_ADDPROPERTYPAGES = 47,
	SFVM_BACKGROUNDENUMDONE = 48,
	SFVM_GETNOTIFY = 49,
	SFVM_GETSORTDEFAULTS = 53,
	SFVM_SIZE = 57,
	SFVM_GETZONE = 58,
	SFVM_GETPANE = 59,
	SFVM_GETHELPTOPIC = 63,
	SFVM_GETANIMATION = 68,
}


[AllowDuplicates]
public enum SFVS_SELECT : int32
{
	SFVS_SELECT_NONE = 0,
	SFVS_SELECT_ALLITEMS = 1,
	SFVS_SELECT_INVERT = 2,
}


[AllowDuplicates]
public enum DFM_MESSAGE_ID : int32
{
	DFM_MERGECONTEXTMENU = 1,
	DFM_INVOKECOMMAND = 2,
	DFM_GETHELPTEXT = 5,
	DFM_WM_MEASUREITEM = 6,
	DFM_WM_DRAWITEM = 7,
	DFM_WM_INITMENUPOPUP = 8,
	DFM_VALIDATECMD = 9,
	DFM_MERGECONTEXTMENU_TOP = 10,
	DFM_GETHELPTEXTW = 11,
	DFM_INVOKECOMMANDEX = 12,
	DFM_MAPCOMMANDNAME = 13,
	DFM_GETDEFSTATICID = 14,
	DFM_GETVERBW = 15,
	DFM_GETVERBA = 16,
	DFM_MERGECONTEXTMENU_BOTTOM = 17,
	DFM_MODIFYQCMFLAGS = 18,
}


[AllowDuplicates]
public enum DFM_CMD : int32
{
	DFM_CMD_DELETE = -1,
	DFM_CMD_MOVE = -2,
	DFM_CMD_COPY = -3,
	DFM_CMD_LINK = -4,
	DFM_CMD_PROPERTIES = -5,
	DFM_CMD_NEWFOLDER = -6,
	DFM_CMD_PASTE = -7,
	DFM_CMD_VIEWLIST = -8,
	DFM_CMD_VIEWDETAILS = -9,
	DFM_CMD_PASTELINK = -10,
	DFM_CMD_PASTESPECIAL = -11,
	DFM_CMD_MODALPROP = -12,
	DFM_CMD_RENAME = -13,
}


[AllowDuplicates]
public enum PID_IS : int32
{
	PID_IS_URL = 2,
	PID_IS_NAME = 4,
	PID_IS_WORKINGDIR = 5,
	PID_IS_HOTKEY = 6,
	PID_IS_SHOWCMD = 7,
	PID_IS_ICONINDEX = 8,
	PID_IS_ICONFILE = 9,
	PID_IS_WHATSNEW = 10,
	PID_IS_AUTHOR = 11,
	PID_IS_DESCRIPTION = 12,
	PID_IS_COMMENT = 13,
	PID_IS_ROAMED = 15,
}


[AllowDuplicates]
public enum PID_INTSITE : int32
{
	PID_INTSITE_WHATSNEW = 2,
	PID_INTSITE_AUTHOR = 3,
	PID_INTSITE_LASTVISIT = 4,
	PID_INTSITE_LASTMOD = 5,
	PID_INTSITE_VISITCOUNT = 6,
	PID_INTSITE_DESCRIPTION = 7,
	PID_INTSITE_COMMENT = 8,
	PID_INTSITE_FLAGS = 9,
	PID_INTSITE_CONTENTLEN = 10,
	PID_INTSITE_CONTENTCODE = 11,
	PID_INTSITE_RECURSE = 12,
	PID_INTSITE_WATCH = 13,
	PID_INTSITE_SUBSCRIPTION = 14,
	PID_INTSITE_URL = 15,
	PID_INTSITE_TITLE = 16,
	PID_INTSITE_CODEPAGE = 18,
	PID_INTSITE_TRACKING = 19,
	PID_INTSITE_ICONINDEX = 20,
	PID_INTSITE_ICONFILE = 21,
	PID_INTSITE_ROAMED = 34,
}


[AllowDuplicates]
public enum PIDISF_FLAGS : int32
{
	PIDISF_RECENTLYCHANGED = 1,
	PIDISF_CACHEDSTICKY = 2,
	PIDISF_CACHEIMAGES = 16,
	PIDISF_FOLLOWALLLINKS = 32,
}


[AllowDuplicates]
public enum PIDISM_OPTIONS : int32
{
	PIDISM_GLOBAL = 0,
	PIDISM_WATCH = 1,
	PIDISM_DONTWATCH = 2,
}


[AllowDuplicates]
public enum PIDISR_INFO : int32
{
	PIDISR_UP_TO_DATE = 0,
	PIDISR_NEEDS_ADD = 1,
	PIDISR_NEEDS_UPDATE = 2,
	PIDISR_NEEDS_DELETE = 3,
}


[AllowDuplicates]
public enum SSF_MASK : uint32
{
	SSF_SHOWALLOBJECTS = 1,
	SSF_SHOWEXTENSIONS = 2,
	SSF_HIDDENFILEEXTS = 4,
	SSF_SERVERADMINUI = 4,
	SSF_SHOWCOMPCOLOR = 8,
	SSF_SORTCOLUMNS = 16,
	SSF_SHOWSYSFILES = 32,
	SSF_DOUBLECLICKINWEBVIEW = 128,
	SSF_SHOWATTRIBCOL = 256,
	SSF_DESKTOPHTML = 512,
	SSF_WIN95CLASSIC = 1024,
	SSF_DONTPRETTYPATH = 2048,
	SSF_SHOWINFOTIP = 8192,
	SSF_MAPNETDRVBUTTON = 4096,
	SSF_NOCONFIRMRECYCLE = 32768,
	SSF_HIDEICONS = 16384,
	SSF_FILTER = 65536,
	SSF_WEBVIEW = 131072,
	SSF_SHOWSUPERHIDDEN = 262144,
	SSF_SEPPROCESS = 524288,
	SSF_NONETCRAWLING = 1048576,
	SSF_STARTPANELON = 2097152,
	SSF_SHOWSTARTPAGE = 4194304,
	SSF_AUTOCHECKSELECT = 8388608,
	SSF_ICONSONLY = 16777216,
	SSF_SHOWTYPEOVERLAY = 33554432,
	SSF_SHOWSTATUSBAR = 67108864,
}


[AllowDuplicates]
public enum NOTIFY_ICON_MESSAGE : uint32
{
	NIM_ADD = 0,
	NIM_MODIFY = 1,
	NIM_DELETE = 2,
	NIM_SETFOCUS = 3,
	NIM_SETVERSION = 4,
}


[AllowDuplicates]
public enum NOTIFY_ICON_DATA_FLAGS : uint32
{
	NIF_MESSAGE = 1,
	NIF_ICON = 2,
	NIF_TIP = 4,
	NIF_STATE = 8,
	NIF_INFO = 16,
	NIF_GUID = 32,
	NIF_REALTIME = 64,
	NIF_SHOWTIP = 128,
}


[AllowDuplicates]
public enum OS : uint32
{
	OS_WINDOWS = 0,
	OS_NT = 1,
	OS_WIN95ORGREATER = 2,
	OS_NT4ORGREATER = 3,
	OS_WIN98ORGREATER = 5,
	OS_WIN98_GOLD = 6,
	OS_WIN2000ORGREATER = 7,
	OS_WIN2000PRO = 8,
	OS_WIN2000SERVER = 9,
	OS_WIN2000ADVSERVER = 10,
	OS_WIN2000DATACENTER = 11,
	OS_WIN2000TERMINAL = 12,
	OS_EMBEDDED = 13,
	OS_TERMINALCLIENT = 14,
	OS_TERMINALREMOTEADMIN = 15,
	OS_WIN95_GOLD = 16,
	OS_MEORGREATER = 17,
	OS_XPORGREATER = 18,
	OS_HOME = 19,
	OS_PROFESSIONAL = 20,
	OS_DATACENTER = 21,
	OS_ADVSERVER = 22,
	OS_SERVER = 23,
	OS_TERMINALSERVER = 24,
	OS_PERSONALTERMINALSERVER = 25,
	OS_FASTUSERSWITCHING = 26,
	OS_WELCOMELOGONUI = 27,
	OS_DOMAINMEMBER = 28,
	OS_ANYSERVER = 29,
	OS_WOW6432 = 30,
	OS_WEBSERVER = 31,
	OS_SMALLBUSINESSSERVER = 32,
	OS_TABLETPC = 33,
	OS_SERVERADMINUI = 34,
	OS_MEDIACENTER = 35,
	OS_APPLIANCE = 36,
}


[AllowDuplicates]
public enum SHELL_AUTOCOMPLETE_FLAGS : uint32
{
	SHACF_DEFAULT = 0,
	SHACF_FILESYSTEM = 1,
	SHACF_URLALL = 6,
	SHACF_URLHISTORY = 2,
	SHACF_URLMRU = 4,
	SHACF_USETAB = 8,
	SHACF_FILESYS_ONLY = 16,
	SHACF_FILESYS_DIRS = 32,
	SHACF_VIRTUAL_NAMESPACE = 64,
	SHACF_AUTOSUGGEST_FORCE_ON = 268435456,
	SHACF_AUTOSUGGEST_FORCE_OFF = 536870912,
	SHACF_AUTOAPPEND_FORCE_ON = 1073741824,
	SHACF_AUTOAPPEND_FORCE_OFF = 2147483648,
}


[AllowDuplicates]
public enum HELP_INFO_TYPE : int32
{
	HELPINFO_WINDOW = 1,
	HELPINFO_MENUITEM = 2,
}


[AllowDuplicates]
public enum NOTIFY_ICON_INFOTIP_FLAGS : uint32
{
	NIIF_NONE = 0,
	NIIF_INFO = 1,
	NIIF_WARNING = 2,
	NIIF_ERROR = 3,
	NIIF_USER = 4,
	NIIF_ICON_MASK = 15,
	NIIF_NOSOUND = 16,
	NIIF_LARGE_ICON = 32,
	NIIF_RESPECT_QUIET_TIME = 128,
}


[AllowDuplicates]
public enum NOTIFY_ICON_STATE : uint32
{
	NIS_HIDDEN = 1,
	NIS_SHAREDICON = 2,
}


[AllowDuplicates]
public enum GPFIDL_FLAGS : uint32
{
	GPFIDL_DEFAULT = 0,
	GPFIDL_ALTNAME = 1,
	GPFIDL_UNCPRINTER = 2,
}


[AllowDuplicates]
public enum SHGDNF : uint32
{
	SHGDN_NORMAL = 0,
	SHGDN_INFOLDER = 1,
	SHGDN_FOREDITING = 4096,
	SHGDN_FORADDRESSBAR = 16384,
	SHGDN_FORPARSING = 32768,
}


[AllowDuplicates]
public enum _SHCONTF : int32
{
	SHCONTF_CHECKING_FOR_CHILDREN = 16,
	SHCONTF_FOLDERS = 32,
	SHCONTF_NONFOLDERS = 64,
	SHCONTF_INCLUDEHIDDEN = 128,
	SHCONTF_INIT_ON_FIRST_NEXT = 256,
	SHCONTF_NETPRINTERSRCH = 512,
	SHCONTF_SHAREABLE = 1024,
	SHCONTF_STORAGE = 2048,
	SHCONTF_NAVIGATION_ENUM = 4096,
	SHCONTF_FASTITEMS = 8192,
	SHCONTF_FLATLIST = 16384,
	SHCONTF_ENABLE_ASYNC = 32768,
	SHCONTF_INCLUDESUPERHIDDEN = 65536,
}


[AllowDuplicates]
public enum STORAGE_PROVIDER_FILE_FLAGS : int32
{
	SPFF_NONE = 0,
	SPFF_DOWNLOAD_BY_DEFAULT = 1,
	SPFF_CREATED_ON_THIS_DEVICE = 2,
}


[AllowDuplicates]
public enum MERGE_UPDATE_STATUS : int32
{
	MUS_COMPLETE = 0,
	MUS_USERINPUTNEEDED = 1,
	MUS_FAILED = 2,
}


[AllowDuplicates]
public enum FOLDER_ENUM_MODE : int32
{
	FEM_VIEWRESULT = 0,
	FEM_NAVIGATION = 1,
}


[AllowDuplicates]
public enum FOLDERFLAGS : int32
{
	FWF_NONE = 0,
	FWF_AUTOARRANGE = 1,
	FWF_ABBREVIATEDNAMES = 2,
	FWF_SNAPTOGRID = 4,
	FWF_OWNERDATA = 8,
	FWF_BESTFITWINDOW = 16,
	FWF_DESKTOP = 32,
	FWF_SINGLESEL = 64,
	FWF_NOSUBFOLDERS = 128,
	FWF_TRANSPARENT = 256,
	FWF_NOCLIENTEDGE = 512,
	FWF_NOSCROLL = 1024,
	FWF_ALIGNLEFT = 2048,
	FWF_NOICONS = 4096,
	FWF_SHOWSELALWAYS = 8192,
	FWF_NOVISIBLE = 16384,
	FWF_SINGLECLICKACTIVATE = 32768,
	FWF_NOWEBVIEW = 65536,
	FWF_HIDEFILENAMES = 131072,
	FWF_CHECKSELECT = 262144,
	FWF_NOENUMREFRESH = 524288,
	FWF_NOGROUPING = 1048576,
	FWF_FULLROWSELECT = 2097152,
	FWF_NOFILTERS = 4194304,
	FWF_NOCOLUMNHEADER = 8388608,
	FWF_NOHEADERINALLVIEWS = 16777216,
	FWF_EXTENDEDTILES = 33554432,
	FWF_TRICHECKSELECT = 67108864,
	FWF_AUTOCHECKSELECT = 134217728,
	FWF_NOBROWSERVIEWSTATE = 268435456,
	FWF_SUBSETGROUPS = 536870912,
	FWF_USESEARCHFOLDER = 1073741824,
	FWF_ALLOWRTLREADING = -2147483648,
}


[AllowDuplicates]
public enum FOLDERVIEWMODE : int32
{
	FVM_AUTO = -1,
	FVM_FIRST = 1,
	FVM_ICON = 1,
	FVM_SMALLICON = 2,
	FVM_LIST = 3,
	FVM_DETAILS = 4,
	FVM_THUMBNAIL = 5,
	FVM_TILE = 6,
	FVM_THUMBSTRIP = 7,
	FVM_CONTENT = 8,
	FVM_LAST = 8,
}


[AllowDuplicates]
public enum FOLDERLOGICALVIEWMODE : int32
{
	FLVM_UNSPECIFIED = -1,
	FLVM_FIRST = 1,
	FLVM_DETAILS = 1,
	FLVM_TILES = 2,
	FLVM_ICONS = 3,
	FLVM_LIST = 4,
	FLVM_CONTENT = 5,
	FLVM_LAST = 5,
}


[AllowDuplicates]
public enum _SVSIF : int32
{
	SVSI_DESELECT = 0,
	SVSI_SELECT = 1,
	SVSI_EDIT = 3,
	SVSI_DESELECTOTHERS = 4,
	SVSI_ENSUREVISIBLE = 8,
	SVSI_FOCUSED = 16,
	SVSI_TRANSLATEPT = 32,
	SVSI_SELECTIONMARK = 64,
	SVSI_POSITIONITEM = 128,
	SVSI_CHECK = 256,
	SVSI_CHECK2 = 512,
	SVSI_KEYBOARDSELECT = 1025,
	SVSI_NOTAKEFOCUS = 1073741824,
}


[AllowDuplicates]
public enum _SVGIO : int32
{
	SVGIO_BACKGROUND = 0,
	SVGIO_SELECTION = 1,
	SVGIO_ALLVIEW = 2,
	SVGIO_CHECKED = 3,
	SVGIO_TYPE_MASK = 15,
	SVGIO_FLAG_VIEWORDER = -2147483648,
}


[AllowDuplicates]
public enum SVUIA_STATUS : int32
{
	SVUIA_DEACTIVATE = 0,
	SVUIA_ACTIVATE_NOFOCUS = 1,
	SVUIA_ACTIVATE_FOCUS = 2,
	SVUIA_INPLACEACTIVATE = 3,
}


[AllowDuplicates]
public enum SORTDIRECTION : int32
{
	SORT_DESCENDING = -1,
	SORT_ASCENDING = 1,
}


[AllowDuplicates]
public enum FVTEXTTYPE : int32
{
	FVST_EMPTYTEXT = 0,
}


[AllowDuplicates]
public enum CM_MASK : int32
{
	CM_MASK_WIDTH = 1,
	CM_MASK_DEFAULTWIDTH = 2,
	CM_MASK_IDEALWIDTH = 4,
	CM_MASK_NAME = 8,
	CM_MASK_STATE = 16,
}


[AllowDuplicates]
public enum CM_STATE : int32
{
	CM_STATE_NONE = 0,
	CM_STATE_VISIBLE = 1,
	CM_STATE_FIXEDWIDTH = 2,
	CM_STATE_NOSORTBYFOLDERNESS = 4,
	CM_STATE_ALWAYSVISIBLE = 8,
}


[AllowDuplicates]
public enum CM_ENUM_FLAGS : int32
{
	CM_ENUM_ALL = 1,
	CM_ENUM_VISIBLE = 2,
}


[AllowDuplicates]
public enum CM_SET_WIDTH_VALUE : int32
{
	CM_WIDTH_USEDEFAULT = -1,
	CM_WIDTH_AUTOSIZE = -2,
}


[AllowDuplicates]
public enum SIGDN : int32
{
	SIGDN_NORMALDISPLAY = 0,
	SIGDN_PARENTRELATIVEPARSING = -2147385343,
	SIGDN_DESKTOPABSOLUTEPARSING = -2147319808,
	SIGDN_PARENTRELATIVEEDITING = -2147282943,
	SIGDN_DESKTOPABSOLUTEEDITING = -2147172352,
	SIGDN_FILESYSPATH = -2147123200,
	SIGDN_URL = -2147057664,
	SIGDN_PARENTRELATIVEFORADDRESSBAR = -2146975743,
	SIGDN_PARENTRELATIVE = -2146959359,
	SIGDN_PARENTRELATIVEFORUI = -2146877439,
}


[AllowDuplicates]
public enum _SICHINTF : int32
{
	SICHINT_DISPLAY = 0,
	SICHINT_ALLFIELDS = -2147483648,
	SICHINT_CANONICAL = 268435456,
	SICHINT_TEST_FILESYSPATH_IF_NOT_EQUAL = 536870912,
}


[AllowDuplicates]
public enum DATAOBJ_GET_ITEM_FLAGS : int32
{
	DOGIF_DEFAULT = 0,
	DOGIF_TRAVERSE_LINK = 1,
	DOGIF_NO_HDROP = 2,
	DOGIF_NO_URL = 4,
	DOGIF_ONLY_IF_ONE = 8,
}


[AllowDuplicates]
public enum SIIGBF : int32
{
	SIIGBF_RESIZETOFIT = 0,
	SIIGBF_BIGGERSIZEOK = 1,
	SIIGBF_MEMORYONLY = 2,
	SIIGBF_ICONONLY = 4,
	SIIGBF_THUMBNAILONLY = 8,
	SIIGBF_INCACHEONLY = 16,
	SIIGBF_CROPTOSQUARE = 32,
	SIIGBF_WIDETHUMBNAILS = 64,
	SIIGBF_ICONBACKGROUND = 128,
	SIIGBF_SCALEUP = 256,
}


[AllowDuplicates]
public enum STGOP : int32
{
	STGOP_MOVE = 1,
	STGOP_COPY = 2,
	STGOP_SYNC = 3,
	STGOP_REMOVE = 5,
	STGOP_RENAME = 6,
	STGOP_APPLYPROPERTIES = 8,
	STGOP_NEW = 10,
}


[AllowDuplicates]
public enum _TRANSFER_SOURCE_FLAGS : int32
{
	TSF_NORMAL = 0,
	TSF_FAIL_EXIST = 0,
	TSF_RENAME_EXIST = 1,
	TSF_OVERWRITE_EXIST = 2,
	TSF_ALLOW_DECRYPTION = 4,
	TSF_NO_SECURITY = 8,
	TSF_COPY_CREATION_TIME = 16,
	TSF_COPY_WRITE_TIME = 32,
	TSF_USE_FULL_ACCESS = 64,
	TSF_DELETE_RECYCLE_IF_POSSIBLE = 128,
	TSF_COPY_HARD_LINK = 256,
	TSF_COPY_LOCALIZED_NAME = 512,
	TSF_MOVE_AS_COPY_DELETE = 1024,
	TSF_SUSPEND_SHELLEVENTS = 2048,
}


[AllowDuplicates]
public enum _TRANSFER_ADVISE_STATE : int32
{
	TS_NONE = 0,
	TS_PERFORMING = 1,
	TS_PREPARING = 2,
	TS_INDETERMINATE = 4,
}


[AllowDuplicates]
public enum SIATTRIBFLAGS : int32
{
	SIATTRIBFLAGS_AND = 1,
	SIATTRIBFLAGS_OR = 2,
	SIATTRIBFLAGS_APPCOMPAT = 3,
	SIATTRIBFLAGS_MASK = 3,
	SIATTRIBFLAGS_ALLITEMS = 16384,
}


[AllowDuplicates]
public enum CATEGORYINFO_FLAGS : int32
{
	CATINFO_NORMAL = 0,
	CATINFO_COLLAPSED = 1,
	CATINFO_HIDDEN = 2,
	CATINFO_EXPANDED = 4,
	CATINFO_NOHEADER = 8,
	CATINFO_NOTCOLLAPSIBLE = 16,
	CATINFO_NOHEADERCOUNT = 32,
	CATINFO_SUBSETTED = 64,
	CATINFO_SEPARATE_IMAGES = 128,
	CATINFO_SHOWEMPTY = 256,
}


[AllowDuplicates]
public enum CATSORT_FLAGS : int32
{
	CATSORT_DEFAULT = 0,
	CATSORT_NAME = 1,
}


[AllowDuplicates]
public enum SLR_FLAGS : int32
{
	SLR_NONE = 0,
	SLR_NO_UI = 1,
	SLR_ANY_MATCH = 2,
	SLR_UPDATE = 4,
	SLR_NOUPDATE = 8,
	SLR_NOSEARCH = 16,
	SLR_NOTRACK = 32,
	SLR_NOLINKINFO = 64,
	SLR_INVOKE_MSI = 128,
	SLR_NO_UI_WITH_MSG_PUMP = 257,
	SLR_OFFER_DELETE_WITHOUT_FILE = 512,
	SLR_KNOWNFOLDER = 1024,
	SLR_MACHINE_IN_LOCAL_TARGET = 2048,
	SLR_UPDATE_MACHINE_AND_SID = 4096,
	SLR_NO_OBJECT_ID = 8192,
}


[AllowDuplicates]
public enum SLGP_FLAGS : int32
{
	SLGP_SHORTPATH = 1,
	SLGP_UNCPRIORITY = 2,
	SLGP_RAWPATH = 4,
	SLGP_RELATIVEPRIORITY = 8,
}


[AllowDuplicates]
public enum _SPINITF : int32
{
	SPINITF_NORMAL = 0,
	SPINITF_MODAL = 1,
	SPINITF_NOMINIMIZE = 8,
}


[AllowDuplicates]
public enum _SPBEGINF : int32
{
	SPBEGINF_NORMAL = 0,
	SPBEGINF_AUTOTIME = 2,
	SPBEGINF_NOPROGRESSBAR = 16,
	SPBEGINF_MARQUEEPROGRESS = 32,
	SPBEGINF_NOCANCELBUTTON = 64,
}


[AllowDuplicates]
public enum SPACTION : int32
{
	SPACTION_NONE = 0,
	SPACTION_MOVING = 1,
	SPACTION_COPYING = 2,
	SPACTION_RECYCLING = 3,
	SPACTION_APPLYINGATTRIBS = 4,
	SPACTION_DOWNLOADING = 5,
	SPACTION_SEARCHING_INTERNET = 6,
	SPACTION_CALCULATING = 7,
	SPACTION_UPLOADING = 8,
	SPACTION_SEARCHING_FILES = 9,
	SPACTION_DELETING = 10,
	SPACTION_RENAMING = 11,
	SPACTION_FORMATTING = 12,
	SPACTION_COPY_MOVING = 13,
}


[AllowDuplicates]
public enum SPTEXT : int32
{
	SPTEXT_ACTIONDESCRIPTION = 1,
	SPTEXT_ACTIONDETAIL = 2,
}


[AllowDuplicates]
public enum _EXPPS : int32
{
	EXPPS_FILETYPES = 1,
}


[AllowDuplicates]
public enum DESKBANDCID : int32
{
	DBID_BANDINFOCHANGED = 0,
	DBID_SHOWONLY = 1,
	DBID_MAXIMIZEBAND = 2,
	DBID_PUSHCHEVRON = 3,
	DBID_DELAYINIT = 4,
	DBID_FINISHINIT = 5,
	DBID_SETWINDOWTHEME = 6,
	DBID_PERMITAUTOHIDE = 7,
}


[AllowDuplicates]
public enum THUMBBUTTONFLAGS : int32
{
	THBF_ENABLED = 0,
	THBF_DISABLED = 1,
	THBF_DISMISSONCLICK = 2,
	THBF_NOBACKGROUND = 4,
	THBF_HIDDEN = 8,
	THBF_NONINTERACTIVE = 16,
}


[AllowDuplicates]
public enum THUMBBUTTONMASK : int32
{
	THB_BITMAP = 1,
	THB_ICON = 2,
	THB_TOOLTIP = 4,
	THB_FLAGS = 8,
}


[AllowDuplicates]
public enum TBPFLAG : int32
{
	TBPF_NOPROGRESS = 0,
	TBPF_INDETERMINATE = 1,
	TBPF_NORMAL = 2,
	TBPF_ERROR = 4,
	TBPF_PAUSED = 8,
}


[AllowDuplicates]
public enum STPFLAG : int32
{
	STPF_NONE = 0,
	STPF_USEAPPTHUMBNAILALWAYS = 1,
	STPF_USEAPPTHUMBNAILWHENACTIVE = 2,
	STPF_USEAPPPEEKALWAYS = 4,
	STPF_USEAPPPEEKWHENACTIVE = 8,
}


[AllowDuplicates]
public enum EXPLORER_BROWSER_OPTIONS : int32
{
	EBO_NONE = 0,
	EBO_NAVIGATEONCE = 1,
	EBO_SHOWFRAMES = 2,
	EBO_ALWAYSNAVIGATE = 4,
	EBO_NOTRAVELLOG = 8,
	EBO_NOWRAPPERWINDOW = 16,
	EBO_HTMLSHAREPOINTVIEW = 32,
	EBO_NOBORDER = 64,
	EBO_NOPERSISTVIEWSTATE = 128,
}


[AllowDuplicates]
public enum EXPLORER_BROWSER_FILL_FLAGS : int32
{
	EBF_NONE = 0,
	EBF_SELECTFROMDATAOBJECT = 256,
	EBF_NODROPTARGET = 512,
}


[AllowDuplicates]
public enum _OPPROGDLGF : int32
{
	OPPROGDLG_DEFAULT = 0,
	OPPROGDLG_ENABLEPAUSE = 128,
	OPPROGDLG_ALLOWUNDO = 256,
	OPPROGDLG_DONTDISPLAYSOURCEPATH = 512,
	OPPROGDLG_DONTDISPLAYDESTPATH = 1024,
	OPPROGDLG_NOMULTIDAYESTIMATES = 2048,
	OPPROGDLG_DONTDISPLAYLOCATIONS = 4096,
}


[AllowDuplicates]
public enum _PDMODE : int32
{
	PDM_DEFAULT = 0,
	PDM_RUN = 1,
	PDM_PREFLIGHT = 2,
	PDM_UNDOING = 4,
	PDM_ERRORSBLOCKING = 8,
	PDM_INDETERMINATE = 16,
}


[AllowDuplicates]
public enum FILE_OPERATION_FLAGS2 : int32
{
	FOF2_NONE = 0,
	FOF2_MERGEFOLDERSONCOLLISION = 1,
}


[AllowDuplicates]
public enum NAMESPACEWALKFLAG : int32
{
	NSWF_DEFAULT = 0,
	NSWF_NONE_IMPLIES_ALL = 1,
	NSWF_ONE_IMPLIES_ALL = 2,
	NSWF_DONT_TRAVERSE_LINKS = 4,
	NSWF_DONT_ACCUMULATE_RESULT = 8,
	NSWF_TRAVERSE_STREAM_JUNCTIONS = 16,
	NSWF_FILESYSTEM_ONLY = 32,
	NSWF_SHOW_PROGRESS = 64,
	NSWF_FLAG_VIEWORDER = 128,
	NSWF_IGNORE_AUTOPLAY_HIDA = 256,
	NSWF_ASYNC = 512,
	NSWF_DONT_RESOLVE_LINKS = 1024,
	NSWF_ACCUMULATE_FOLDERS = 2048,
	NSWF_DONT_SORT = 4096,
	NSWF_USE_TRANSFER_MEDIUM = 8192,
	NSWF_DONT_TRAVERSE_STREAM_JUNCTIONS = 16384,
	NSWF_ANY_IMPLIES_ALL = 32768,
}


[AllowDuplicates]
public enum BANDSITECID : int32
{
	BSID_BANDADDED = 0,
	BSID_BANDREMOVED = 1,
}


[AllowDuplicates]
public enum MENUBANDHANDLERCID : int32
{
	MBHANDCID_PIDLSELECT = 0,
}


[AllowDuplicates]
public enum MENUPOPUPSELECT : int32
{
	MPOS_EXECUTE = 0,
	MPOS_FULLCANCEL = 1,
	MPOS_CANCELLEVEL = 2,
	MPOS_SELECTLEFT = 3,
	MPOS_SELECTRIGHT = 4,
	MPOS_CHILDTRACKING = 5,
}


[AllowDuplicates]
public enum MENUPOPUPPOPUPFLAGS : int32
{
	MPPF_SETFOCUS = 1,
	MPPF_INITIALSELECT = 2,
	MPPF_NOANIMATE = 4,
	MPPF_KEYBOARD = 16,
	MPPF_REPOSITION = 32,
	MPPF_FORCEZORDER = 64,
	MPPF_FINALSELECT = 128,
	MPPF_TOP = 536870912,
	MPPF_LEFT = 1073741824,
	MPPF_RIGHT = 1610612736,
	MPPF_BOTTOM = -2147483648,
	MPPF_POS_MASK = -536870912,
	MPPF_ALIGN_LEFT = 33554432,
	MPPF_ALIGN_RIGHT = 67108864,
}


[AllowDuplicates]
public enum FILE_USAGE_TYPE : int32
{
	FUT_PLAYING = 0,
	FUT_EDITING = 1,
	FUT_GENERIC = 2,
}


[AllowDuplicates]
public enum FDE_OVERWRITE_RESPONSE : int32
{
	FDEOR_DEFAULT = 0,
	FDEOR_ACCEPT = 1,
	FDEOR_REFUSE = 2,
}


[AllowDuplicates]
public enum FDE_SHAREVIOLATION_RESPONSE : int32
{
	FDESVR_DEFAULT = 0,
	FDESVR_ACCEPT = 1,
	FDESVR_REFUSE = 2,
}


[AllowDuplicates]
public enum FDAP : int32
{
	FDAP_BOTTOM = 0,
	FDAP_TOP = 1,
}


[AllowDuplicates]
public enum FILEOPENDIALOGOPTIONS : uint32
{
	FOS_OVERWRITEPROMPT = 2,
	FOS_STRICTFILETYPES = 4,
	FOS_NOCHANGEDIR = 8,
	FOS_PICKFOLDERS = 32,
	FOS_FORCEFILESYSTEM = 64,
	FOS_ALLNONSTORAGEITEMS = 128,
	FOS_NOVALIDATE = 256,
	FOS_ALLOWMULTISELECT = 512,
	FOS_PATHMUSTEXIST = 2048,
	FOS_FILEMUSTEXIST = 4096,
	FOS_CREATEPROMPT = 8192,
	FOS_SHAREAWARE = 16384,
	FOS_NOREADONLYRETURN = 32768,
	FOS_NOTESTFILECREATE = 65536,
	FOS_HIDEMRUPLACES = 131072,
	FOS_HIDEPINNEDPLACES = 262144,
	FOS_NODEREFERENCELINKS = 1048576,
	FOS_OKBUTTONNEEDSINTERACTION = 2097152,
	FOS_DONTADDTORECENT = 33554432,
	FOS_FORCESHOWHIDDEN = 268435456,
	FOS_DEFAULTNOMINIMODE = 536870912,
	FOS_FORCEPREVIEWPANEON = 1073741824,
	FOS_SUPPORTSTREAMABLEITEMS = 2147483648,
}


[AllowDuplicates]
public enum CDCONTROLSTATEF : int32
{
	CDCS_INACTIVE = 0,
	CDCS_ENABLED = 1,
	CDCS_VISIBLE = 2,
	CDCS_ENABLEDVISIBLE = 3,
}


[AllowDuplicates]
public enum ASSOCIATIONLEVEL : int32
{
	AL_MACHINE = 0,
	AL_EFFECTIVE = 1,
	AL_USER = 2,
}


[AllowDuplicates]
public enum ASSOCIATIONTYPE : int32
{
	AT_FILEEXTENSION = 0,
	AT_URLPROTOCOL = 1,
	AT_STARTMENUCLIENT = 2,
	AT_MIMETYPE = 3,
}


[AllowDuplicates]
public enum _BROWSERFRAMEOPTIONS : int32
{
	BFO_NONE = 0,
	BFO_BROWSER_PERSIST_SETTINGS = 1,
	BFO_RENAME_FOLDER_OPTIONS_TOINTERNET = 2,
	BFO_BOTH_OPTIONS = 4,
	BIF_PREFER_INTERNET_SHORTCUT = 8,
	BFO_BROWSE_NO_IN_NEW_PROCESS = 16,
	BFO_ENABLE_HYPERLINK_TRACKING = 32,
	BFO_USE_IE_OFFLINE_SUPPORT = 64,
	BFO_SUBSTITUE_INTERNET_START_PAGE = 128,
	BFO_USE_IE_LOGOBANDING = 256,
	BFO_ADD_IE_TOCAPTIONBAR = 512,
	BFO_USE_DIALUP_REF = 1024,
	BFO_USE_IE_TOOLBAR = 2048,
	BFO_NO_PARENT_FOLDER_SUPPORT = 4096,
	BFO_NO_REOPEN_NEXT_RESTART = 8192,
	BFO_GO_HOME_PAGE = 16384,
	BFO_PREFER_IEPROCESS = 32768,
	BFO_SHOW_NAVIGATION_CANCELLED = 65536,
	BFO_USE_IE_STATUSBAR = 131072,
	BFO_QUERY_ALL = -1,
}


[AllowDuplicates]
public enum NWMF : int32
{
	NWMF_UNLOADING = 1,
	NWMF_USERINITED = 2,
	NWMF_FIRST = 4,
	NWMF_OVERRIDEKEY = 8,
	NWMF_SHOWHELP = 16,
	NWMF_HTMLDIALOG = 32,
	NWMF_FROMDIALOGCHILD = 64,
	NWMF_USERREQUESTED = 128,
	NWMF_USERALLOWED = 256,
	NWMF_FORCEWINDOW = 65536,
	NWMF_FORCETAB = 131072,
	NWMF_SUGGESTWINDOW = 262144,
	NWMF_SUGGESTTAB = 524288,
	NWMF_INACTIVETAB = 1048576,
}


[AllowDuplicates]
public enum ATTACHMENT_PROMPT : int32
{
	ATTACHMENT_PROMPT_NONE = 0,
	ATTACHMENT_PROMPT_SAVE = 1,
	ATTACHMENT_PROMPT_EXEC = 2,
	ATTACHMENT_PROMPT_EXEC_OR_SAVE = 3,
}


[AllowDuplicates]
public enum ATTACHMENT_ACTION : int32
{
	ATTACHMENT_ACTION_CANCEL = 0,
	ATTACHMENT_ACTION_SAVE = 1,
	ATTACHMENT_ACTION_EXEC = 2,
}


[AllowDuplicates]
public enum SMINFOMASK : int32
{
	SMIM_TYPE = 1,
	SMIM_FLAGS = 2,
	SMIM_ICON = 4,
}


[AllowDuplicates]
public enum SMINFOTYPE : int32
{
	SMIT_SEPARATOR = 1,
	SMIT_STRING = 2,
}


[AllowDuplicates]
public enum SMINFOFLAGS : int32
{
	SMIF_ICON = 1,
	SMIF_ACCELERATOR = 2,
	SMIF_DROPTARGET = 4,
	SMIF_SUBMENU = 8,
	SMIF_CHECKED = 32,
	SMIF_DROPCASCADE = 64,
	SMIF_HIDDEN = 128,
	SMIF_DISABLED = 256,
	SMIF_TRACKPOPUP = 512,
	SMIF_DEMOTED = 1024,
	SMIF_ALTSTATE = 2048,
	SMIF_DRAGNDROP = 4096,
	SMIF_NEW = 8192,
}


[AllowDuplicates]
public enum KF_CATEGORY : int32
{
	KF_CATEGORY_VIRTUAL = 1,
	KF_CATEGORY_FIXED = 2,
	KF_CATEGORY_COMMON = 3,
	KF_CATEGORY_PERUSER = 4,
}


[AllowDuplicates]
public enum _KF_DEFINITION_FLAGS : int32
{
	KFDF_LOCAL_REDIRECT_ONLY = 2,
	KFDF_ROAMABLE = 4,
	KFDF_PRECREATE = 8,
	KFDF_STREAM = 16,
	KFDF_PUBLISHEXPANDEDPATH = 32,
	KFDF_NO_REDIRECT_UI = 64,
}


[AllowDuplicates]
public enum _KF_REDIRECT_FLAGS : int32
{
	KF_REDIRECT_USER_EXCLUSIVE = 1,
	KF_REDIRECT_COPY_SOURCE_DACL = 2,
	KF_REDIRECT_OWNER_USER = 4,
	KF_REDIRECT_SET_OWNER_EXPLICIT = 8,
	KF_REDIRECT_CHECK_ONLY = 16,
	KF_REDIRECT_WITH_UI = 32,
	KF_REDIRECT_UNPIN = 64,
	KF_REDIRECT_PIN = 128,
	KF_REDIRECT_COPY_CONTENTS = 512,
	KF_REDIRECT_DEL_SOURCE_CONTENTS = 1024,
	KF_REDIRECT_EXCLUDE_ALL_KNOWN_SUBFOLDERS = 2048,
}


[AllowDuplicates]
public enum _KF_REDIRECTION_CAPABILITIES : int32
{
	KF_REDIRECTION_CAPABILITIES_ALLOW_ALL = 255,
	KF_REDIRECTION_CAPABILITIES_REDIRECTABLE = 1,
	KF_REDIRECTION_CAPABILITIES_DENY_ALL = 1048320,
	KF_REDIRECTION_CAPABILITIES_DENY_POLICY_REDIRECTED = 256,
	KF_REDIRECTION_CAPABILITIES_DENY_POLICY = 512,
	KF_REDIRECTION_CAPABILITIES_DENY_PERMISSIONS = 1024,
}


[AllowDuplicates]
public enum FFFP_MODE : int32
{
	FFFP_EXACTMATCH = 0,
	FFFP_NEARESTPARENTMATCH = 1,
}


[AllowDuplicates]
public enum SHARE_ROLE : int32
{
	SHARE_ROLE_INVALID = -1,
	SHARE_ROLE_READER = 0,
	SHARE_ROLE_CONTRIBUTOR = 1,
	SHARE_ROLE_CO_OWNER = 2,
	SHARE_ROLE_OWNER = 3,
	SHARE_ROLE_CUSTOM = 4,
	SHARE_ROLE_MIXED = 5,
}


[AllowDuplicates]
public enum DEF_SHARE_ID : int32
{
	DEFSHAREID_USERS = 1,
	DEFSHAREID_PUBLIC = 2,
}


[AllowDuplicates]
public enum _NMCII_FLAGS : int32
{
	NMCII_NONE = 0,
	NMCII_ITEMS = 1,
	NMCII_FOLDERS = 2,
}


[AllowDuplicates]
public enum _NMCSAEI_FLAGS : int32
{
	NMCSAEI_SELECT = 0,
	NMCSAEI_EDIT = 1,
}


[AllowDuplicates]
public enum _NSTCSTYLE : int32
{
	NSTCS_HASEXPANDOS = 1,
	NSTCS_HASLINES = 2,
	NSTCS_SINGLECLICKEXPAND = 4,
	NSTCS_FULLROWSELECT = 8,
	NSTCS_SPRINGEXPAND = 16,
	NSTCS_HORIZONTALSCROLL = 32,
	NSTCS_ROOTHASEXPANDO = 64,
	NSTCS_SHOWSELECTIONALWAYS = 128,
	NSTCS_NOINFOTIP = 512,
	NSTCS_EVENHEIGHT = 1024,
	NSTCS_NOREPLACEOPEN = 2048,
	NSTCS_DISABLEDRAGDROP = 4096,
	NSTCS_NOORDERSTREAM = 8192,
	NSTCS_RICHTOOLTIP = 16384,
	NSTCS_BORDER = 32768,
	NSTCS_NOEDITLABELS = 65536,
	NSTCS_TABSTOP = 131072,
	NSTCS_FAVORITESMODE = 524288,
	NSTCS_AUTOHSCROLL = 1048576,
	NSTCS_FADEINOUTEXPANDOS = 2097152,
	NSTCS_EMPTYTEXT = 4194304,
	NSTCS_CHECKBOXES = 8388608,
	NSTCS_PARTIALCHECKBOXES = 16777216,
	NSTCS_EXCLUSIONCHECKBOXES = 33554432,
	NSTCS_DIMMEDCHECKBOXES = 67108864,
	NSTCS_NOINDENTCHECKS = 134217728,
	NSTCS_ALLOWJUNCTIONS = 268435456,
	NSTCS_SHOWTABSBUTTON = 536870912,
	NSTCS_SHOWDELETEBUTTON = 1073741824,
	NSTCS_SHOWREFRESHBUTTON = -2147483648,
}


[AllowDuplicates]
public enum _NSTCROOTSTYLE : int32
{
	NSTCRS_VISIBLE = 0,
	NSTCRS_HIDDEN = 1,
	NSTCRS_EXPANDED = 2,
}


[AllowDuplicates]
public enum _NSTCITEMSTATE : int32
{
	NSTCIS_NONE = 0,
	NSTCIS_SELECTED = 1,
	NSTCIS_EXPANDED = 2,
	NSTCIS_BOLD = 4,
	NSTCIS_DISABLED = 8,
	NSTCIS_SELECTEDNOEXPAND = 16,
}


[AllowDuplicates]
public enum NSTCGNI : int32
{
	NSTCGNI_NEXT = 0,
	NSTCGNI_NEXTVISIBLE = 1,
	NSTCGNI_PREV = 2,
	NSTCGNI_PREVVISIBLE = 3,
	NSTCGNI_PARENT = 4,
	NSTCGNI_CHILD = 5,
	NSTCGNI_FIRSTVISIBLE = 6,
	NSTCGNI_LASTVISIBLE = 7,
}


[AllowDuplicates]
public enum NSTCFOLDERCAPABILITIES : int32
{
	NSTCFC_NONE = 0,
	NSTCFC_PINNEDITEMFILTERING = 1,
	NSTCFC_DELAY_REGISTER_NOTIFY = 2,
}


[AllowDuplicates]
public enum _EXPLORERPANESTATE : int32
{
	EPS_DONTCARE = 0,
	EPS_DEFAULT_ON = 1,
	EPS_DEFAULT_OFF = 2,
	EPS_STATEMASK = 65535,
	EPS_INITIALSTATE = 65536,
	EPS_FORCE = 131072,
}


[AllowDuplicates]
public enum _EXPCMDSTATE : int32
{
	ECS_ENABLED = 0,
	ECS_DISABLED = 1,
	ECS_HIDDEN = 2,
	ECS_CHECKBOX = 4,
	ECS_CHECKED = 8,
	ECS_RADIOCHECK = 16,
}


[AllowDuplicates]
public enum _EXPCMDFLAGS : int32
{
	ECF_DEFAULT = 0,
	ECF_HASSUBCOMMANDS = 1,
	ECF_HASSPLITBUTTON = 2,
	ECF_HIDELABEL = 4,
	ECF_ISSEPARATOR = 8,
	ECF_HASLUASHIELD = 16,
	ECF_SEPARATORBEFORE = 32,
	ECF_SEPARATORAFTER = 64,
	ECF_ISDROPDOWN = 128,
	ECF_TOGGLEABLE = 256,
	ECF_AUTOMENUICONS = 512,
}


[AllowDuplicates]
public enum CPVIEW : int32
{
	CPVIEW_CLASSIC = 0,
	CPVIEW_ALLITEMS = 0,
	CPVIEW_CATEGORY = 1,
	CPVIEW_HOME = 1,
}


[AllowDuplicates]
public enum KNOWNDESTCATEGORY : int32
{
	KDC_FREQUENT = 1,
	KDC_RECENT = 2,
}


[AllowDuplicates]
public enum APPDOCLISTTYPE : int32
{
	ADLT_RECENT = 0,
	ADLT_FREQUENT = 1,
}


[AllowDuplicates]
public enum DESKTOP_SLIDESHOW_OPTIONS : int32
{
	DSO_SHUFFLEIMAGES = 1,
}


[AllowDuplicates]
public enum DESKTOP_SLIDESHOW_STATE : int32
{
	DSS_ENABLED = 1,
	DSS_SLIDESHOW = 2,
	DSS_DISABLED_BY_REMOTE_SESSION = 4,
}


[AllowDuplicates]
public enum DESKTOP_SLIDESHOW_DIRECTION : int32
{
	DSD_FORWARD = 0,
	DSD_BACKWARD = 1,
}


[AllowDuplicates]
public enum DESKTOP_WALLPAPER_POSITION : int32
{
	DWPOS_CENTER = 0,
	DWPOS_TILE = 1,
	DWPOS_STRETCH = 2,
	DWPOS_FIT = 3,
	DWPOS_FILL = 4,
	DWPOS_SPAN = 5,
}


[AllowDuplicates]
public enum HOMEGROUPSHARINGCHOICES : int32
{
	HGSC_NONE = 0,
	HGSC_MUSICLIBRARY = 1,
	HGSC_PICTURESLIBRARY = 2,
	HGSC_VIDEOSLIBRARY = 4,
	HGSC_DOCUMENTSLIBRARY = 8,
	HGSC_PRINTERS = 16,
}


[AllowDuplicates]
public enum LIBRARYFOLDERFILTER : int32
{
	LFF_FORCEFILESYSTEM = 1,
	LFF_STORAGEITEMS = 2,
	LFF_ALLITEMS = 3,
}


[AllowDuplicates]
public enum LIBRARYOPTIONFLAGS : int32
{
	LOF_DEFAULT = 0,
	LOF_PINNEDTONAVPANE = 1,
	LOF_MASK_ALL = 1,
}


[AllowDuplicates]
public enum DEFAULTSAVEFOLDERTYPE : int32
{
	DSFT_DETECT = 1,
	DSFT_PRIVATE = 2,
	DSFT_PUBLIC = 3,
}


[AllowDuplicates]
public enum LIBRARYSAVEFLAGS : int32
{
	LSF_FAILIFTHERE = 0,
	LSF_OVERRIDEEXISTING = 1,
	LSF_MAKEUNIQUENAME = 2,
}


[AllowDuplicates]
public enum DEFAULT_FOLDER_MENU_RESTRICTIONS : int32
{
	DFMR_DEFAULT = 0,
	DFMR_NO_STATIC_VERBS = 8,
	DFMR_STATIC_VERBS_ONLY = 16,
	DFMR_NO_RESOURCE_VERBS = 32,
	DFMR_OPTIN_HANDLERS_ONLY = 64,
	DFMR_RESOURCE_AND_FOLDER_VERBS_ONLY = 128,
	DFMR_USE_SPECIFIED_HANDLERS = 256,
	DFMR_USE_SPECIFIED_VERBS = 512,
	DFMR_NO_ASYNC_VERBS = 1024,
	DFMR_NO_NATIVECPU_VERBS = 2048,
	DFMR_NO_NONWOW_VERBS = 4096,
}


[AllowDuplicates]
public enum ACTIVATEOPTIONS : int32
{
	AO_NONE = 0,
	AO_DESIGNMODE = 1,
	AO_NOERRORUI = 2,
	AO_NOSPLASHSCREEN = 4,
	AO_PRELAUNCH = 33554432,
}


[AllowDuplicates]
public enum LIBRARYMANAGEDIALOGOPTIONS : int32
{
	LMD_DEFAULT = 0,
	LMD_ALLOWUNINDEXABLENETWORKLOCATIONS = 1,
}


[AllowDuplicates]
public enum AHTYPE : int32
{
	AHTYPE_UNDEFINED = 0,
	AHTYPE_USER_APPLICATION = 8,
	AHTYPE_ANY_APPLICATION = 16,
	AHTYPE_MACHINEDEFAULT = 32,
	AHTYPE_PROGID = 64,
	AHTYPE_APPLICATION = 128,
	AHTYPE_CLASS_APPLICATION = 256,
	AHTYPE_ANY_PROGID = 512,
}


[AllowDuplicates]
public enum ASSOC_FILTER : int32
{
	ASSOC_FILTER_NONE = 0,
	ASSOC_FILTER_RECOMMENDED = 1,
}


[AllowDuplicates]
public enum MONITOR_APP_VISIBILITY : int32
{
	MAV_UNKNOWN = 0,
	MAV_NO_APP_VISIBLE = 1,
	MAV_APP_VISIBLE = 2,
}


[AllowDuplicates]
public enum PACKAGE_EXECUTION_STATE : int32
{
	PES_UNKNOWN = 0,
	PES_RUNNING = 1,
	PES_SUSPENDING = 2,
	PES_SUSPENDED = 3,
	PES_TERMINATED = 4,
}


[AllowDuplicates]
public enum AHE_TYPE : int32
{
	AHE_DESKTOP = 0,
	AHE_IMMERSIVE = 1,
}


[AllowDuplicates]
public enum EC_HOST_UI_MODE : int32
{
	ECHUIM_DESKTOP = 0,
	ECHUIM_IMMERSIVE = 1,
	ECHUIM_SYSTEM_LAUNCHER = 2,
}


[AllowDuplicates]
public enum APPLICATION_VIEW_STATE : int32
{
	AVS_FULLSCREEN_LANDSCAPE = 0,
	AVS_FILLED = 1,
	AVS_SNAPPED = 2,
	AVS_FULLSCREEN_PORTRAIT = 3,
}


[AllowDuplicates]
public enum EDGE_GESTURE_KIND : int32
{
	EGK_TOUCH = 0,
	EGK_KEYBOARD = 1,
	EGK_MOUSE = 2,
}


[AllowDuplicates]
public enum NATIVE_DISPLAY_ORIENTATION : int32
{
	NDO_LANDSCAPE = 0,
	NDO_PORTRAIT = 1,
}


[AllowDuplicates]
public enum APPLICATION_VIEW_ORIENTATION : int32
{
	AVO_LANDSCAPE = 0,
	AVO_PORTRAIT = 1,
}


[AllowDuplicates]
public enum ADJACENT_DISPLAY_EDGES : int32
{
	ADE_NONE = 0,
	ADE_LEFT = 1,
	ADE_RIGHT = 2,
}


[AllowDuplicates]
public enum APPLICATION_VIEW_MIN_WIDTH : int32
{
	AVMW_DEFAULT = 0,
	AVMW_320 = 1,
	AVMW_500 = 2,
}


[AllowDuplicates]
public enum APPLICATION_VIEW_SIZE_PREFERENCE : int32
{
	AVSP_DEFAULT = 0,
	AVSP_USE_LESS = 1,
	AVSP_USE_HALF = 2,
	AVSP_USE_MORE = 3,
	AVSP_USE_MINIMUM = 4,
	AVSP_USE_NONE = 5,
	AVSP_CUSTOM = 6,
}


[AllowDuplicates]
public enum FLYOUT_PLACEMENT : int32
{
	FP_DEFAULT = 0,
	FP_ABOVE = 1,
	FP_BELOW = 2,
	FP_LEFT = 3,
	FP_RIGHT = 4,
}


[AllowDuplicates]
public enum BANNER_NOTIFICATION_EVENT : int32
{
	BNE_Rendered = 0,
	BNE_Hovered = 1,
	BNE_Closed = 2,
	BNE_Dismissed = 3,
	BNE_Button1Clicked = 4,
	BNE_Button2Clicked = 5,
}


[AllowDuplicates]
public enum SORT_ORDER_TYPE : int32
{
	SOT_DEFAULT = 0,
	SOT_IGNORE_FOLDERNESS = 1,
}


[AllowDuplicates]
public enum FOLDERVIEWOPTIONS : int32
{
	FVO_DEFAULT = 0,
	FVO_VISTALAYOUT = 1,
	FVO_CUSTOMPOSITION = 2,
	FVO_CUSTOMORDERING = 4,
	FVO_SUPPORTHYPERLINKS = 8,
	FVO_NOANIMATIONS = 16,
	FVO_NOSCROLLTIPS = 32,
}


[AllowDuplicates]
public enum _SV3CVW3_FLAGS : int32
{
	SV3CVW3_DEFAULT = 0,
	SV3CVW3_NONINTERACTIVE = 1,
	SV3CVW3_FORCEVIEWMODE = 2,
	SV3CVW3_FORCEFOLDERFLAGS = 4,
}


[AllowDuplicates]
public enum VPWATERMARKFLAGS : int32
{
	VPWF_DEFAULT = 0,
	VPWF_ALPHABLEND = 1,
}


[AllowDuplicates]
public enum VPCOLORFLAGS : int32
{
	VPCF_TEXT = 1,
	VPCF_BACKGROUND = 2,
	VPCF_SORTCOLUMN = 3,
	VPCF_SUBTEXT = 4,
	VPCF_TEXTBACKGROUND = 5,
}


[AllowDuplicates]
public enum DSH_FLAGS : int32
{
	DSH_ALLOWDROPDESCRIPTIONTEXT = 1,
}


[AllowDuplicates]
public enum CDBURNINGEXTENSIONRET : int32
{
	CDBE_RET_DEFAULT = 0,
	CDBE_RET_DONTRUNOTHEREXTS = 1,
	CDBE_RET_STOPWIZARD = 2,
}


[AllowDuplicates]
public enum _CDBE_ACTIONS : int32
{
	CDBE_TYPE_MUSIC = 1,
	CDBE_TYPE_DATA = 2,
	CDBE_TYPE_ALL = -1,
}


[AllowDuplicates]
public enum NSTCSTYLE2 : int32
{
	NSTCS2_DEFAULT = 0,
	NSTCS2_INTERRUPTNOTIFICATIONS = 1,
	NSTCS2_SHOWNULLSPACEMENU = 2,
	NSTCS2_DISPLAYPADDING = 4,
	NSTCS2_DISPLAYPINNEDONLY = 8,
	NTSCS2_NOSINGLETONAUTOEXPAND = 16,
	NTSCS2_NEVERINSERTNONENUMERATED = 32,
}


[AllowDuplicates]
public enum _NSTCEHITTEST : int32
{
	NSTCEHT_NOWHERE = 1,
	NSTCEHT_ONITEMICON = 2,
	NSTCEHT_ONITEMLABEL = 4,
	NSTCEHT_ONITEMINDENT = 8,
	NSTCEHT_ONITEMBUTTON = 16,
	NSTCEHT_ONITEMRIGHT = 32,
	NSTCEHT_ONITEMSTATEICON = 64,
	NSTCEHT_ONITEM = 70,
	NSTCEHT_ONITEMTABBUTTON = 4096,
}


[AllowDuplicates]
public enum _NSTCECLICKTYPE : int32
{
	NSTCECT_LBUTTON = 1,
	NSTCECT_MBUTTON = 2,
	NSTCECT_RBUTTON = 3,
	NSTCECT_BUTTON = 3,
	NSTCECT_DBLCLICK = 4,
}


[AllowDuplicates]
public enum UNDOCK_REASON : int32
{
	UR_RESOLUTION_CHANGE = 0,
	UR_MONITOR_DISCONNECT = 1,
}


[AllowDuplicates]
public enum CommandStateChangeConstants : int32
{
	CSC_UPDATECOMMANDS = -1,
	CSC_NAVIGATEFORWARD = 1,
	CSC_NAVIGATEBACK = 2,
}


[AllowDuplicates]
public enum SecureLockIconConstants : int32
{
	secureLockIconUnsecure = 0,
	secureLockIconMixed = 1,
	secureLockIconSecureUnknownBits = 2,
	secureLockIconSecure40Bit = 3,
	secureLockIconSecure56Bit = 4,
	secureLockIconSecureFortezza = 5,
	secureLockIconSecure128Bit = 6,
}


[AllowDuplicates]
public enum NewProcessCauseConstants : int32
{
	ProtectedModeRedirect = 1,
}


[AllowDuplicates]
public enum ShellWindowTypeConstants : int32
{
	SWC_EXPLORER = 0,
	SWC_BROWSER = 1,
	SWC_3RDPARTY = 2,
	SWC_CALLBACK = 4,
	SWC_DESKTOP = 8,
}


[AllowDuplicates]
public enum ShellWindowFindWindowOptions : int32
{
	SWFO_NEEDDISPATCH = 1,
	SWFO_INCLUDEPENDING = 2,
	SWFO_COOKIEPASSED = 4,
}


[AllowDuplicates]
public enum BrowserNavConstants : int32
{
	navOpenInNewWindow = 1,
	navNoHistory = 2,
	navNoReadFromCache = 4,
	navNoWriteToCache = 8,
	navAllowAutosearch = 16,
	navBrowserBar = 32,
	navHyperlink = 64,
	navEnforceRestricted = 128,
	navNewWindowsManaged = 256,
	navUntrustedForDownload = 512,
	navTrustedForActiveX = 1024,
	navOpenInNewTab = 2048,
	navOpenInBackgroundTab = 4096,
	navKeepWordWheelText = 8192,
	navVirtualTab = 16384,
	navBlockRedirectsXDomain = 32768,
	navOpenNewForegroundTab = 65536,
	navTravelLogScreenshot = 131072,
	navDeferUnload = 262144,
	navSpeculative = 524288,
	navSuggestNewWindow = 1048576,
	navSuggestNewTab = 2097152,
	navReserved1 = 4194304,
	navHomepageNavigate = 8388608,
	navRefresh = 16777216,
	navHostNavigation = 33554432,
	navReserved2 = 67108864,
	navReserved3 = 134217728,
	navReserved4 = 268435456,
	navReserved5 = 536870912,
	navReserved6 = 1073741824,
	navReserved7 = -2147483648,
}


[AllowDuplicates]
public enum RefreshConstants : int32
{
	REFRESH_NORMAL = 0,
	REFRESH_IFEXPIRED = 1,
	REFRESH_COMPLETELY = 3,
}


[AllowDuplicates]
public enum OfflineFolderStatus : int32
{
	OFS_INACTIVE = -1,
	OFS_ONLINE = 0,
	OFS_OFFLINE = 1,
	OFS_SERVERBACK = 2,
	OFS_DIRTYCACHE = 3,
}


[AllowDuplicates]
public enum ShellFolderViewOptions : int32
{
	SFVVO_SHOWALLOBJECTS = 1,
	SFVVO_SHOWEXTENSIONS = 2,
	SFVVO_SHOWCOMPCOLOR = 8,
	SFVVO_SHOWSYSFILES = 32,
	SFVVO_WIN95CLASSIC = 64,
	SFVVO_DOUBLECLICKINWEBVIEW = 128,
	SFVVO_DESKTOPHTML = 512,
}


[AllowDuplicates]
public enum ShellSpecialFolderConstants : int32
{
	ssfDESKTOP = 0,
	ssfPROGRAMS = 2,
	ssfCONTROLS = 3,
	ssfPRINTERS = 4,
	ssfPERSONAL = 5,
	ssfFAVORITES = 6,
	ssfSTARTUP = 7,
	ssfRECENT = 8,
	ssfSENDTO = 9,
	ssfBITBUCKET = 10,
	ssfSTARTMENU = 11,
	ssfDESKTOPDIRECTORY = 16,
	ssfDRIVES = 17,
	ssfNETWORK = 18,
	ssfNETHOOD = 19,
	ssfFONTS = 20,
	ssfTEMPLATES = 21,
	ssfCOMMONSTARTMENU = 22,
	ssfCOMMONPROGRAMS = 23,
	ssfCOMMONSTARTUP = 24,
	ssfCOMMONDESKTOPDIR = 25,
	ssfAPPDATA = 26,
	ssfPRINTHOOD = 27,
	ssfLOCALAPPDATA = 28,
	ssfALTSTARTUP = 29,
	ssfCOMMONALTSTARTUP = 30,
	ssfCOMMONFAVORITES = 31,
	ssfINTERNETCACHE = 32,
	ssfCOOKIES = 33,
	ssfHISTORY = 34,
	ssfCOMMONAPPDATA = 35,
	ssfWINDOWS = 36,
	ssfSYSTEM = 37,
	ssfPROGRAMFILES = 38,
	ssfMYPICTURES = 39,
	ssfPROFILE = 40,
	ssfSYSTEMx86 = 41,
	ssfPROGRAMFILESx86 = 48,
}


[AllowDuplicates]
public enum AUTOCOMPLETEOPTIONS : int32
{
	ACO_NONE = 0,
	ACO_AUTOSUGGEST = 1,
	ACO_AUTOAPPEND = 2,
	ACO_SEARCH = 4,
	ACO_FILTERPREFIXES = 8,
	ACO_USETAB = 16,
	ACO_UPDOWNKEYDROPSLIST = 32,
	ACO_RTLREADING = 64,
	ACO_WORD_FILTER = 128,
	ACO_NOPREFIXFILTERING = 256,
}


[AllowDuplicates]
public enum ACENUMOPTION : int32
{
	ACEO_NONE = 0,
	ACEO_MOSTRECENTFIRST = 1,
	ACEO_FIRSTUNUSED = 65536,
}


[AllowDuplicates]
public enum SHELL_LINK_DATA_FLAGS : int32
{
	SLDF_DEFAULT = 0,
	SLDF_HAS_ID_LIST = 1,
	SLDF_HAS_LINK_INFO = 2,
	SLDF_HAS_NAME = 4,
	SLDF_HAS_RELPATH = 8,
	SLDF_HAS_WORKINGDIR = 16,
	SLDF_HAS_ARGS = 32,
	SLDF_HAS_ICONLOCATION = 64,
	SLDF_UNICODE = 128,
	SLDF_FORCE_NO_LINKINFO = 256,
	SLDF_HAS_EXP_SZ = 512,
	SLDF_RUN_IN_SEPARATE = 1024,
	SLDF_HAS_DARWINID = 4096,
	SLDF_RUNAS_USER = 8192,
	SLDF_HAS_EXP_ICON_SZ = 16384,
	SLDF_NO_PIDL_ALIAS = 32768,
	SLDF_FORCE_UNCNAME = 65536,
	SLDF_RUN_WITH_SHIMLAYER = 131072,
	SLDF_FORCE_NO_LINKTRACK = 262144,
	SLDF_ENABLE_TARGET_METADATA = 524288,
	SLDF_DISABLE_LINK_PATH_TRACKING = 1048576,
	SLDF_DISABLE_KNOWNFOLDER_RELATIVE_TRACKING = 2097152,
	SLDF_NO_KF_ALIAS = 4194304,
	SLDF_ALLOW_LINK_TO_LINK = 8388608,
	SLDF_UNALIAS_ON_SAVE = 16777216,
	SLDF_PREFER_ENVIRONMENT_PATH = 33554432,
	SLDF_KEEP_LOCAL_IDLIST_FOR_UNC_TARGET = 67108864,
	SLDF_PERSIST_VOLUME_ID_RELATIVE = 134217728,
	SLDF_VALID = 268433407,
	SLDF_RESERVED = -2147483648,
}


[AllowDuplicates]
public enum SHGFP_TYPE : int32
{
	SHGFP_TYPE_CURRENT = 0,
	SHGFP_TYPE_DEFAULT = 1,
}


[AllowDuplicates]
public enum KNOWN_FOLDER_FLAG : int32
{
	KF_FLAG_DEFAULT = 0,
	KF_FLAG_FORCE_APP_DATA_REDIRECTION = 524288,
	KF_FLAG_RETURN_FILTER_REDIRECTION_TARGET = 262144,
	KF_FLAG_FORCE_PACKAGE_REDIRECTION = 131072,
	KF_FLAG_NO_PACKAGE_REDIRECTION = 65536,
	KF_FLAG_FORCE_APPCONTAINER_REDIRECTION = 131072,
	KF_FLAG_NO_APPCONTAINER_REDIRECTION = 65536,
	KF_FLAG_CREATE = 32768,
	KF_FLAG_DONT_VERIFY = 16384,
	KF_FLAG_DONT_UNEXPAND = 8192,
	KF_FLAG_NO_ALIAS = 4096,
	KF_FLAG_INIT = 2048,
	KF_FLAG_DEFAULT_PATH = 1024,
	KF_FLAG_NOT_PARENT_RELATIVE = 512,
	KF_FLAG_SIMPLE_IDLIST = 256,
	KF_FLAG_ALIAS_ONLY = -2147483648,
}


[AllowDuplicates]
public enum AUTOCOMPLETELISTOPTIONS : int32
{
	ACLO_NONE = 0,
	ACLO_CURRENTDIR = 1,
	ACLO_MYCOMPUTER = 2,
	ACLO_DESKTOP = 4,
	ACLO_FAVORITES = 8,
	ACLO_FILESYSONLY = 16,
	ACLO_FILESYSDIRS = 32,
	ACLO_VIRTUALNAMESPACE = 64,
}


[AllowDuplicates]
public enum FD_FLAGS : int32
{
	FD_CLSID = 1,
	FD_SIZEPOINT = 2,
	FD_ATTRIBUTES = 4,
	FD_CREATETIME = 8,
	FD_ACCESSTIME = 16,
	FD_WRITESTIME = 32,
	FD_FILESIZE = 64,
	FD_PROGRESSUI = 16384,
	FD_LINKUI = 32768,
	FD_UNICODE = -2147483648,
}


[AllowDuplicates]
public enum DROPIMAGETYPE : int32
{
	DROPIMAGE_INVALID = -1,
	DROPIMAGE_NONE = 0,
	DROPIMAGE_COPY = 1,
	DROPIMAGE_MOVE = 2,
	DROPIMAGE_LINK = 4,
	DROPIMAGE_LABEL = 6,
	DROPIMAGE_WARNING = 7,
	DROPIMAGE_NOIMAGE = 8,
}


[AllowDuplicates]
public enum SHARD : int32
{
	SHARD_PIDL = 1,
	SHARD_PATHA = 2,
	SHARD_PATHW = 3,
	SHARD_APPIDINFO = 4,
	SHARD_APPIDINFOIDLIST = 5,
	SHARD_LINK = 6,
	SHARD_APPIDINFOLINK = 7,
	SHARD_SHELLITEM = 8,
}


[AllowDuplicates]
public enum SCNRT_STATUS : int32
{
	SCNRT_ENABLE = 0,
	SCNRT_DISABLE = 1,
}


[AllowDuplicates]
public enum RESTRICTIONS : int32
{
	REST_NONE = 0,
	REST_NORUN = 1,
	REST_NOCLOSE = 2,
	REST_NOSAVESET = 4,
	REST_NOFILEMENU = 8,
	REST_NOSETFOLDERS = 16,
	REST_NOSETTASKBAR = 32,
	REST_NODESKTOP = 64,
	REST_NOFIND = 128,
	REST_NODRIVES = 256,
	REST_NODRIVEAUTORUN = 512,
	REST_NODRIVETYPEAUTORUN = 1024,
	REST_NONETHOOD = 2048,
	REST_STARTBANNER = 4096,
	REST_RESTRICTRUN = 8192,
	REST_NOPRINTERTABS = 16384,
	REST_NOPRINTERDELETE = 32768,
	REST_NOPRINTERADD = 65536,
	REST_NOSTARTMENUSUBFOLDERS = 131072,
	REST_MYDOCSONNET = 262144,
	REST_NOEXITTODOS = 524288,
	REST_ENFORCESHELLEXTSECURITY = 1048576,
	REST_LINKRESOLVEIGNORELINKINFO = 2097152,
	REST_NOCOMMONGROUPS = 4194304,
	REST_SEPARATEDESKTOPPROCESS = 8388608,
	REST_NOWEB = 16777216,
	REST_NOTRAYCONTEXTMENU = 33554432,
	REST_NOVIEWCONTEXTMENU = 67108864,
	REST_NONETCONNECTDISCONNECT = 134217728,
	REST_STARTMENULOGOFF = 268435456,
	REST_NOSETTINGSASSIST = 536870912,
	REST_NOINTERNETICON = 1073741825,
	REST_NORECENTDOCSHISTORY = 1073741826,
	REST_NORECENTDOCSMENU = 1073741827,
	REST_NOACTIVEDESKTOP = 1073741828,
	REST_NOACTIVEDESKTOPCHANGES = 1073741829,
	REST_NOFAVORITESMENU = 1073741830,
	REST_CLEARRECENTDOCSONEXIT = 1073741831,
	REST_CLASSICSHELL = 1073741832,
	REST_NOCUSTOMIZEWEBVIEW = 1073741833,
	REST_NOHTMLWALLPAPER = 1073741840,
	REST_NOCHANGINGWALLPAPER = 1073741841,
	REST_NODESKCOMP = 1073741842,
	REST_NOADDDESKCOMP = 1073741843,
	REST_NODELDESKCOMP = 1073741844,
	REST_NOCLOSEDESKCOMP = 1073741845,
	REST_NOCLOSE_DRAGDROPBAND = 1073741846,
	REST_NOMOVINGBAND = 1073741847,
	REST_NOEDITDESKCOMP = 1073741848,
	REST_NORESOLVESEARCH = 1073741849,
	REST_NORESOLVETRACK = 1073741850,
	REST_FORCECOPYACLWITHFILE = 1073741851,
	REST_NOFORGETSOFTWAREUPDATE = 1073741853,
	REST_NOSETACTIVEDESKTOP = 1073741854,
	REST_NOUPDATEWINDOWS = 1073741855,
	REST_NOCHANGESTARMENU = 1073741856,
	REST_NOFOLDEROPTIONS = 1073741857,
	REST_HASFINDCOMPUTERS = 1073741858,
	REST_INTELLIMENUS = 1073741859,
	REST_RUNDLGMEMCHECKBOX = 1073741860,
	REST_ARP_ShowPostSetup = 1073741861,
	REST_NOCSC = 1073741862,
	REST_NOCONTROLPANEL = 1073741863,
	REST_ENUMWORKGROUP = 1073741864,
	REST_ARP_NOARP = 1073741865,
	REST_ARP_NOREMOVEPAGE = 1073741866,
	REST_ARP_NOADDPAGE = 1073741867,
	REST_ARP_NOWINSETUPPAGE = 1073741868,
	REST_GREYMSIADS = 1073741869,
	REST_NOCHANGEMAPPEDDRIVELABEL = 1073741870,
	REST_NOCHANGEMAPPEDDRIVECOMMENT = 1073741871,
	REST_MaxRecentDocs = 1073741872,
	REST_NONETWORKCONNECTIONS = 1073741873,
	REST_FORCESTARTMENULOGOFF = 1073741874,
	REST_NOWEBVIEW = 1073741875,
	REST_NOCUSTOMIZETHISFOLDER = 1073741876,
	REST_NOENCRYPTION = 1073741877,
	REST_DONTSHOWSUPERHIDDEN = 1073741879,
	REST_NOSHELLSEARCHBUTTON = 1073741880,
	REST_NOHARDWARETAB = 1073741881,
	REST_NORUNASINSTALLPROMPT = 1073741882,
	REST_PROMPTRUNASINSTALLNETPATH = 1073741883,
	REST_NOMANAGEMYCOMPUTERVERB = 1073741884,
	REST_DISALLOWRUN = 1073741886,
	REST_NOWELCOMESCREEN = 1073741887,
	REST_RESTRICTCPL = 1073741888,
	REST_DISALLOWCPL = 1073741889,
	REST_NOSMBALLOONTIP = 1073741890,
	REST_NOSMHELP = 1073741891,
	REST_NOWINKEYS = 1073741892,
	REST_NOENCRYPTONMOVE = 1073741893,
	REST_NOLOCALMACHINERUN = 1073741894,
	REST_NOCURRENTUSERRUN = 1073741895,
	REST_NOLOCALMACHINERUNONCE = 1073741896,
	REST_NOCURRENTUSERRUNONCE = 1073741897,
	REST_FORCEACTIVEDESKTOPON = 1073741898,
	REST_NOVIEWONDRIVE = 1073741900,
	REST_NONETCRAWL = 1073741901,
	REST_NOSHAREDDOCUMENTS = 1073741902,
	REST_NOSMMYDOCS = 1073741903,
	REST_NOSMMYPICS = 1073741904,
	REST_ALLOWBITBUCKDRIVES = 1073741905,
	REST_NONLEGACYSHELLMODE = 1073741906,
	REST_NOCONTROLPANELBARRICADE = 1073741907,
	REST_NOSTARTPAGE = 1073741908,
	REST_NOAUTOTRAYNOTIFY = 1073741909,
	REST_NOTASKGROUPING = 1073741910,
	REST_NOCDBURNING = 1073741911,
	REST_MYCOMPNOPROP = 1073741912,
	REST_MYDOCSNOPROP = 1073741913,
	REST_NOSTARTPANEL = 1073741914,
	REST_NODISPLAYAPPEARANCEPAGE = 1073741915,
	REST_NOTHEMESTAB = 1073741916,
	REST_NOVISUALSTYLECHOICE = 1073741917,
	REST_NOSIZECHOICE = 1073741918,
	REST_NOCOLORCHOICE = 1073741919,
	REST_SETVISUALSTYLE = 1073741920,
	REST_STARTRUNNOHOMEPATH = 1073741921,
	REST_NOUSERNAMEINSTARTPANEL = 1073741922,
	REST_NOMYCOMPUTERICON = 1073741923,
	REST_NOSMNETWORKPLACES = 1073741924,
	REST_NOSMPINNEDLIST = 1073741925,
	REST_NOSMMYMUSIC = 1073741926,
	REST_NOSMEJECTPC = 1073741927,
	REST_NOSMMOREPROGRAMS = 1073741928,
	REST_NOSMMFUPROGRAMS = 1073741929,
	REST_NOTRAYITEMSDISPLAY = 1073741930,
	REST_NOTOOLBARSONTASKBAR = 1073741931,
	REST_NOSMCONFIGUREPROGRAMS = 1073741935,
	REST_HIDECLOCK = 1073741936,
	REST_NOLOWDISKSPACECHECKS = 1073741937,
	REST_NOENTIRENETWORK = 1073741938,
	REST_NODESKTOPCLEANUP = 1073741939,
	REST_BITBUCKNUKEONDELETE = 1073741940,
	REST_BITBUCKCONFIRMDELETE = 1073741941,
	REST_BITBUCKNOPROP = 1073741942,
	REST_NODISPBACKGROUND = 1073741943,
	REST_NODISPSCREENSAVEPG = 1073741944,
	REST_NODISPSETTINGSPG = 1073741945,
	REST_NODISPSCREENSAVEPREVIEW = 1073741946,
	REST_NODISPLAYCPL = 1073741947,
	REST_HIDERUNASVERB = 1073741948,
	REST_NOTHUMBNAILCACHE = 1073741949,
	REST_NOSTRCMPLOGICAL = 1073741950,
	REST_NOPUBLISHWIZARD = 1073741951,
	REST_NOONLINEPRINTSWIZARD = 1073741952,
	REST_NOWEBSERVICES = 1073741953,
	REST_ALLOWUNHASHEDWEBVIEW = 1073741954,
	REST_ALLOWLEGACYWEBVIEW = 1073741955,
	REST_REVERTWEBVIEWSECURITY = 1073741956,
	REST_INHERITCONSOLEHANDLES = 1073741958,
	REST_NOREMOTERECURSIVEEVENTS = 1073741961,
	REST_NOREMOTECHANGENOTIFY = 1073741969,
	REST_NOENUMENTIRENETWORK = 1073741971,
	REST_NOINTERNETOPENWITH = 1073741973,
	REST_DONTRETRYBADNETNAME = 1073741979,
	REST_ALLOWFILECLSIDJUNCTIONS = 1073741980,
	REST_NOUPNPINSTALL = 1073741981,
	REST_ARP_DONTGROUPPATCHES = 1073741996,
	REST_ARP_NOCHOOSEPROGRAMSPAGE = 1073741997,
	REST_NODISCONNECT = 1090519041,
	REST_NOSECURITY = 1090519042,
	REST_NOFILEASSOCIATE = 1090519043,
	REST_ALLOWCOMMENTTOGGLE = 1090519044,
}


[AllowDuplicates]
public enum OPEN_AS_INFO_FLAGS : uint32
{
	OAIF_ALLOW_REGISTRATION = 1,
	OAIF_REGISTER_EXT = 2,
	OAIF_EXEC = 4,
	OAIF_FORCE_REGISTRATION = 8,
	OAIF_HIDE_REGISTRATION = 32,
	OAIF_URL_PROTOCOL = 64,
	OAIF_FILE_IS_URI = 128,
}


[AllowDuplicates]
public enum IESHORTCUTFLAGS : int32
{
	IESHORTCUT_NEWBROWSER = 1,
	IESHORTCUT_OPENNEWTAB = 2,
	IESHORTCUT_FORCENAVIGATE = 4,
	IESHORTCUT_BACKGROUNDTAB = 8,
}


[AllowDuplicates]
public enum DISPLAY_DEVICE_TYPE : int32
{
	DEVICE_PRIMARY = 0,
	DEVICE_IMMERSIVE = 1,
}


[AllowDuplicates]
public enum SCALE_CHANGE_FLAGS : uint32
{
	SCF_VALUE_NONE = 0,
	SCF_SCALE = 1,
	SCF_PHYSICAL = 2,
}


[AllowDuplicates]
public enum SHELL_UI_COMPONENT : int32
{
	SHELL_UI_COMPONENT_TASKBARS = 0,
	SHELL_UI_COMPONENT_NOTIFICATIONAREA = 1,
	SHELL_UI_COMPONENT_DESKBAND = 2,
}


[AllowDuplicates]
public enum ASSOCCLASS : int32
{
	ASSOCCLASS_SHELL_KEY = 0,
	ASSOCCLASS_PROGID_KEY = 1,
	ASSOCCLASS_PROGID_STR = 2,
	ASSOCCLASS_CLSID_KEY = 3,
	ASSOCCLASS_CLSID_STR = 4,
	ASSOCCLASS_APP_KEY = 5,
	ASSOCCLASS_APP_STR = 6,
	ASSOCCLASS_SYSTEM_STR = 7,
	ASSOCCLASS_FOLDER = 8,
	ASSOCCLASS_STAR = 9,
	ASSOCCLASS_FIXED_PROGID_STR = 10,
	ASSOCCLASS_PROTOCOL_STR = 11,
}


[AllowDuplicates]
public enum QUERY_USER_NOTIFICATION_STATE : int32
{
	QUNS_NOT_PRESENT = 1,
	QUNS_BUSY = 2,
	QUNS_RUNNING_D3D_FULL_SCREEN = 3,
	QUNS_PRESENTATION_MODE = 4,
	QUNS_ACCEPTS_NOTIFICATIONS = 5,
	QUNS_QUIET_TIME = 6,
	QUNS_APP = 7,
}


[AllowDuplicates]
public enum SHSTOCKICONID : int32
{
	SIID_DOCNOASSOC = 0,
	SIID_DOCASSOC = 1,
	SIID_APPLICATION = 2,
	SIID_FOLDER = 3,
	SIID_FOLDEROPEN = 4,
	SIID_DRIVE525 = 5,
	SIID_DRIVE35 = 6,
	SIID_DRIVEREMOVE = 7,
	SIID_DRIVEFIXED = 8,
	SIID_DRIVENET = 9,
	SIID_DRIVENETDISABLED = 10,
	SIID_DRIVECD = 11,
	SIID_DRIVERAM = 12,
	SIID_WORLD = 13,
	SIID_SERVER = 15,
	SIID_PRINTER = 16,
	SIID_MYNETWORK = 17,
	SIID_FIND = 22,
	SIID_HELP = 23,
	SIID_SHARE = 28,
	SIID_LINK = 29,
	SIID_SLOWFILE = 30,
	SIID_RECYCLER = 31,
	SIID_RECYCLERFULL = 32,
	SIID_MEDIACDAUDIO = 40,
	SIID_LOCK = 47,
	SIID_AUTOLIST = 49,
	SIID_PRINTERNET = 50,
	SIID_SERVERSHARE = 51,
	SIID_PRINTERFAX = 52,
	SIID_PRINTERFAXNET = 53,
	SIID_PRINTERFILE = 54,
	SIID_STACK = 55,
	SIID_MEDIASVCD = 56,
	SIID_STUFFEDFOLDER = 57,
	SIID_DRIVEUNKNOWN = 58,
	SIID_DRIVEDVD = 59,
	SIID_MEDIADVD = 60,
	SIID_MEDIADVDRAM = 61,
	SIID_MEDIADVDRW = 62,
	SIID_MEDIADVDR = 63,
	SIID_MEDIADVDROM = 64,
	SIID_MEDIACDAUDIOPLUS = 65,
	SIID_MEDIACDRW = 66,
	SIID_MEDIACDR = 67,
	SIID_MEDIACDBURN = 68,
	SIID_MEDIABLANKCD = 69,
	SIID_MEDIACDROM = 70,
	SIID_AUDIOFILES = 71,
	SIID_IMAGEFILES = 72,
	SIID_VIDEOFILES = 73,
	SIID_MIXEDFILES = 74,
	SIID_FOLDERBACK = 75,
	SIID_FOLDERFRONT = 76,
	SIID_SHIELD = 77,
	SIID_WARNING = 78,
	SIID_INFO = 79,
	SIID_ERROR = 80,
	SIID_KEY = 81,
	SIID_SOFTWARE = 82,
	SIID_RENAME = 83,
	SIID_DELETE = 84,
	SIID_MEDIAAUDIODVD = 85,
	SIID_MEDIAMOVIEDVD = 86,
	SIID_MEDIAENHANCEDCD = 87,
	SIID_MEDIAENHANCEDDVD = 88,
	SIID_MEDIAHDDVD = 89,
	SIID_MEDIABLURAY = 90,
	SIID_MEDIAVCD = 91,
	SIID_MEDIADVDPLUSR = 92,
	SIID_MEDIADVDPLUSRW = 93,
	SIID_DESKTOPPC = 94,
	SIID_MOBILEPC = 95,
	SIID_USERS = 96,
	SIID_MEDIASMARTMEDIA = 97,
	SIID_MEDIACOMPACTFLASH = 98,
	SIID_DEVICECELLPHONE = 99,
	SIID_DEVICECAMERA = 100,
	SIID_DEVICEVIDEOCAMERA = 101,
	SIID_DEVICEAUDIOPLAYER = 102,
	SIID_NETWORKCONNECT = 103,
	SIID_INTERNET = 104,
	SIID_ZIPFILE = 105,
	SIID_SETTINGS = 106,
	SIID_DRIVEHDDVD = 132,
	SIID_DRIVEBD = 133,
	SIID_MEDIAHDDVDROM = 134,
	SIID_MEDIAHDDVDR = 135,
	SIID_MEDIAHDDVDRAM = 136,
	SIID_MEDIABDROM = 137,
	SIID_MEDIABDR = 138,
	SIID_MEDIABDRE = 139,
	SIID_CLUSTEREDDRIVE = 140,
	SIID_MAX_ICONS = 181,
}


[AllowDuplicates]
public enum SFBS_FLAGS : int32
{
	SFBS_FLAGS_ROUND_TO_NEAREST_DISPLAYED_DIGIT = 1,
	SFBS_FLAGS_TRUNCATE_UNDISPLAYED_DECIMAL_DIGITS = 2,
}


[AllowDuplicates]
public enum URL_SCHEME : int32
{
	URL_SCHEME_INVALID = -1,
	URL_SCHEME_UNKNOWN = 0,
	URL_SCHEME_FTP = 1,
	URL_SCHEME_HTTP = 2,
	URL_SCHEME_GOPHER = 3,
	URL_SCHEME_MAILTO = 4,
	URL_SCHEME_NEWS = 5,
	URL_SCHEME_NNTP = 6,
	URL_SCHEME_TELNET = 7,
	URL_SCHEME_WAIS = 8,
	URL_SCHEME_FILE = 9,
	URL_SCHEME_MK = 10,
	URL_SCHEME_HTTPS = 11,
	URL_SCHEME_SHELL = 12,
	URL_SCHEME_SNEWS = 13,
	URL_SCHEME_LOCAL = 14,
	URL_SCHEME_JAVASCRIPT = 15,
	URL_SCHEME_VBSCRIPT = 16,
	URL_SCHEME_ABOUT = 17,
	URL_SCHEME_RES = 18,
	URL_SCHEME_MSSHELLROOTED = 19,
	URL_SCHEME_MSSHELLIDLIST = 20,
	URL_SCHEME_MSHELP = 21,
	URL_SCHEME_MSSHELLDEVICE = 22,
	URL_SCHEME_WILDCARD = 23,
	URL_SCHEME_SEARCH_MS = 24,
	URL_SCHEME_SEARCH = 25,
	URL_SCHEME_KNOWNFOLDER = 26,
	URL_SCHEME_MAXVALUE = 27,
}


[AllowDuplicates]
public enum URL_PART : int32
{
	URL_PART_NONE = 0,
	URL_PART_SCHEME = 1,
	URL_PART_HOSTNAME = 2,
	URL_PART_USERNAME = 3,
	URL_PART_PASSWORD = 4,
	URL_PART_PORT = 5,
	URL_PART_QUERY = 6,
}


[AllowDuplicates]
public enum URLIS : int32
{
	URLIS_URL = 0,
	URLIS_OPAQUE = 1,
	URLIS_NOHISTORY = 2,
	URLIS_FILEURL = 3,
	URLIS_APPLIABLE = 4,
	URLIS_DIRECTORY = 5,
	URLIS_HASQUERY = 6,
}


[AllowDuplicates]
public enum SHREGDEL_FLAGS : int32
{
	SHREGDEL_DEFAULT = 0,
	SHREGDEL_HKCU = 1,
	SHREGDEL_HKLM = 16,
	SHREGDEL_BOTH = 17,
}


[AllowDuplicates]
public enum SHREGENUM_FLAGS : int32
{
	SHREGENUM_DEFAULT = 0,
	SHREGENUM_HKCU = 1,
	SHREGENUM_HKLM = 16,
	SHREGENUM_BOTH = 17,
}


[AllowDuplicates]
public enum ASSOCSTR : int32
{
	ASSOCSTR_COMMAND = 1,
	ASSOCSTR_EXECUTABLE = 2,
	ASSOCSTR_FRIENDLYDOCNAME = 3,
	ASSOCSTR_FRIENDLYAPPNAME = 4,
	ASSOCSTR_NOOPEN = 5,
	ASSOCSTR_SHELLNEWVALUE = 6,
	ASSOCSTR_DDECOMMAND = 7,
	ASSOCSTR_DDEIFEXEC = 8,
	ASSOCSTR_DDEAPPLICATION = 9,
	ASSOCSTR_DDETOPIC = 10,
	ASSOCSTR_INFOTIP = 11,
	ASSOCSTR_QUICKTIP = 12,
	ASSOCSTR_TILEINFO = 13,
	ASSOCSTR_CONTENTTYPE = 14,
	ASSOCSTR_DEFAULTICON = 15,
	ASSOCSTR_SHELLEXTENSION = 16,
	ASSOCSTR_DROPTARGET = 17,
	ASSOCSTR_DELEGATEEXECUTE = 18,
	ASSOCSTR_SUPPORTED_URI_PROTOCOLS = 19,
	ASSOCSTR_PROGID = 20,
	ASSOCSTR_APPID = 21,
	ASSOCSTR_APPPUBLISHER = 22,
	ASSOCSTR_APPICONREFERENCE = 23,
	ASSOCSTR_MAX = 24,
}


[AllowDuplicates]
public enum ASSOCKEY : int32
{
	ASSOCKEY_SHELLEXECCLASS = 1,
	ASSOCKEY_APP = 2,
	ASSOCKEY_CLASS = 3,
	ASSOCKEY_BASECLASS = 4,
	ASSOCKEY_MAX = 5,
}


[AllowDuplicates]
public enum ASSOCDATA : int32
{
	ASSOCDATA_MSIDESCRIPTOR = 1,
	ASSOCDATA_NOACTIVATEHANDLER = 2,
	ASSOCDATA_UNUSED1 = 3,
	ASSOCDATA_HASPERUSERASSOC = 4,
	ASSOCDATA_EDITFLAGS = 5,
	ASSOCDATA_VALUE = 6,
	ASSOCDATA_MAX = 7,
}


[AllowDuplicates]
public enum ASSOCENUM : int32
{
	ASSOCENUM_NONE = 0,
}


[AllowDuplicates]
public enum FILETYPEATTRIBUTEFLAGS : int32
{
	FTA_None = 0,
	FTA_Exclude = 1,
	FTA_Show = 2,
	FTA_HasExtension = 4,
	FTA_NoEdit = 8,
	FTA_NoRemove = 16,
	FTA_NoNewVerb = 32,
	FTA_NoEditVerb = 64,
	FTA_NoRemoveVerb = 128,
	FTA_NoEditDesc = 256,
	FTA_NoEditIcon = 512,
	FTA_NoEditDflt = 1024,
	FTA_NoEditVerbCmd = 2048,
	FTA_NoEditVerbExe = 4096,
	FTA_NoDDE = 8192,
	FTA_NoEditMIME = 32768,
	FTA_OpenIsSafe = 65536,
	FTA_AlwaysUnsafe = 131072,
	FTA_NoRecentDocs = 1048576,
	FTA_SafeForElevation = 2097152,
	FTA_AlwaysUseDirectInvoke = 4194304,
}


[AllowDuplicates]
public enum SHGLOBALCOUNTER : int32
{
	GLOBALCOUNTER_SEARCHMANAGER = 0,
	GLOBALCOUNTER_SEARCHOPTIONS = 1,
	GLOBALCOUNTER_FOLDERSETTINGSCHANGE = 2,
	GLOBALCOUNTER_RATINGS = 3,
	GLOBALCOUNTER_APPROVEDSITES = 4,
	GLOBALCOUNTER_RESTRICTIONS = 5,
	GLOBALCOUNTER_SHELLSETTINGSCHANGED = 6,
	GLOBALCOUNTER_SYSTEMPIDLCHANGE = 7,
	GLOBALCOUNTER_OVERLAYMANAGER = 8,
	GLOBALCOUNTER_QUERYASSOCIATIONS = 9,
	GLOBALCOUNTER_IESESSIONS = 10,
	GLOBALCOUNTER_IEONLY_SESSIONS = 11,
	GLOBALCOUNTER_APPLICATION_DESTINATIONS = 12,
	__UNUSED_RECYCLE_WAS_GLOBALCOUNTER_CSCSYNCINPROGRESS = 13,
	GLOBALCOUNTER_BITBUCKETNUMDELETERS = 14,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_SHARES = 15,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_A = 16,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_B = 17,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_C = 18,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_D = 19,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_E = 20,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_F = 21,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_G = 22,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_H = 23,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_I = 24,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_J = 25,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_K = 26,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_L = 27,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_M = 28,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_N = 29,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_O = 30,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_P = 31,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_Q = 32,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_R = 33,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_S = 34,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_T = 35,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_U = 36,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_V = 37,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_W = 38,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_X = 39,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_Y = 40,
	GLOBALCOUNTER_RECYCLEDIRTYCOUNT_DRIVE_Z = 41,
	__UNUSED_RECYCLE_WAS_GLOBALCOUNTER_RECYCLEDIRTYCOUNT_SERVERDRIVE = 42,
	__UNUSED_RECYCLE_WAS_GLOBALCOUNTER_RECYCLEGLOBALDIRTYCOUNT = 43,
	GLOBALCOUNTER_RECYCLEBINENUM = 44,
	GLOBALCOUNTER_RECYCLEBINCORRUPTED = 45,
	GLOBALCOUNTER_RATINGS_STATECOUNTER = 46,
	GLOBALCOUNTER_PRIVATE_PROFILE_CACHE = 47,
	GLOBALCOUNTER_INTERNETTOOLBAR_LAYOUT = 48,
	GLOBALCOUNTER_FOLDERDEFINITION_CACHE = 49,
	GLOBALCOUNTER_COMMONPLACES_LIST_CACHE = 50,
	GLOBALCOUNTER_PRIVATE_PROFILE_CACHE_MACHINEWIDE = 51,
	GLOBALCOUNTER_ASSOCCHANGED = 52,
	GLOBALCOUNTER_APP_ITEMS_STATE_STORE_CACHE = 53,
	GLOBALCOUNTER_SETTINGSYNC_ENABLED = 54,
	GLOBALCOUNTER_APPSFOLDER_FILETYPEASSOCIATION_COUNTER = 55,
	GLOBALCOUNTER_USERINFOCHANGED = 56,
	GLOBALCOUNTER_SYNC_ENGINE_INFORMATION_CACHE_MACHINEWIDE = 57,
	GLOBALCOUNTER_BANNERS_DATAMODEL_CACHE_MACHINEWIDE = 58,
	GLOBALCOUNTER_MAXIMUMVALUE = 59,
}


[AllowDuplicates]
public enum APPINFODATAFLAGS : int32
{
	AIM_DISPLAYNAME = 1,
	AIM_VERSION = 2,
	AIM_PUBLISHER = 4,
	AIM_PRODUCTID = 8,
	AIM_REGISTEREDOWNER = 16,
	AIM_REGISTEREDCOMPANY = 32,
	AIM_LANGUAGE = 64,
	AIM_SUPPORTURL = 128,
	AIM_SUPPORTTELEPHONE = 256,
	AIM_HELPLINK = 512,
	AIM_INSTALLLOCATION = 1024,
	AIM_INSTALLSOURCE = 2048,
	AIM_INSTALLDATE = 4096,
	AIM_CONTACT = 16384,
	AIM_COMMENTS = 32768,
	AIM_IMAGE = 131072,
	AIM_READMEURL = 262144,
	AIM_UPDATEINFOURL = 524288,
}


[AllowDuplicates]
public enum APPACTIONFLAGS : int32
{
	APPACTION_INSTALL = 1,
	APPACTION_UNINSTALL = 2,
	APPACTION_MODIFY = 4,
	APPACTION_REPAIR = 8,
	APPACTION_UPGRADE = 16,
	APPACTION_CANGETSIZE = 32,
	APPACTION_MODIFYREMOVE = 128,
	APPACTION_ADDLATER = 256,
	APPACTION_UNSCHEDULE = 512,
}


[AllowDuplicates]
public enum PUBAPPINFOFLAGS : int32
{
	PAI_SOURCE = 1,
	PAI_ASSIGNEDTIME = 2,
	PAI_PUBLISHEDTIME = 4,
	PAI_SCHEDULEDTIME = 8,
	PAI_EXPIRETIME = 16,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_USAGE_SCENARIO : int32
{
	CPUS_INVALID = 0,
	CPUS_LOGON = 1,
	CPUS_UNLOCK_WORKSTATION = 2,
	CPUS_CHANGE_PASSWORD = 3,
	CPUS_CREDUI = 4,
	CPUS_PLAP = 5,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_FIELD_TYPE : int32
{
	CPFT_INVALID = 0,
	CPFT_LARGE_TEXT = 1,
	CPFT_SMALL_TEXT = 2,
	CPFT_COMMAND_LINK = 3,
	CPFT_EDIT_TEXT = 4,
	CPFT_PASSWORD_TEXT = 5,
	CPFT_TILE_IMAGE = 6,
	CPFT_CHECKBOX = 7,
	CPFT_COMBOBOX = 8,
	CPFT_SUBMIT_BUTTON = 9,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_FIELD_STATE : int32
{
	CPFS_HIDDEN = 0,
	CPFS_DISPLAY_IN_SELECTED_TILE = 1,
	CPFS_DISPLAY_IN_DESELECTED_TILE = 2,
	CPFS_DISPLAY_IN_BOTH = 3,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_FIELD_INTERACTIVE_STATE : int32
{
	CPFIS_NONE = 0,
	CPFIS_READONLY = 1,
	CPFIS_DISABLED = 2,
	CPFIS_FOCUSED = 3,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_GET_SERIALIZATION_RESPONSE : int32
{
	CPGSR_NO_CREDENTIAL_NOT_FINISHED = 0,
	CPGSR_NO_CREDENTIAL_FINISHED = 1,
	CPGSR_RETURN_CREDENTIAL_FINISHED = 2,
	CPGSR_RETURN_NO_CREDENTIAL_FINISHED = 3,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_STATUS_ICON : int32
{
	CPSI_NONE = 0,
	CPSI_ERROR = 1,
	CPSI_WARNING = 2,
	CPSI_SUCCESS = 3,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_ACCOUNT_OPTIONS : int32
{
	CPAO_NONE = 0,
	CPAO_EMPTY_LOCAL = 1,
	CPAO_EMPTY_CONNECTED = 2,
}


[AllowDuplicates]
public enum CREDENTIAL_PROVIDER_CREDENTIAL_FIELD_OPTIONS : int32
{
	CPCFO_NONE = 0,
	CPCFO_ENABLE_PASSWORD_REVEAL = 1,
	CPCFO_IS_EMAIL_ADDRESS = 2,
	CPCFO_ENABLE_TOUCH_KEYBOARD_AUTO_INVOKE = 4,
	CPCFO_NUMBERS_ONLY = 8,
	CPCFO_SHOW_ENGLISH_KEYBOARD = 16,
}


[AllowDuplicates]
public enum SYNCMGR_HANDLER_CAPABILITIES : int32
{
	SYNCMGR_HCM_NONE = 0,
	SYNCMGR_HCM_PROVIDES_ICON = 1,
	SYNCMGR_HCM_EVENT_STORE = 2,
	SYNCMGR_HCM_CONFLICT_STORE = 4,
	SYNCMGR_HCM_SUPPORTS_CONCURRENT_SESSIONS = 16,
	SYNCMGR_HCM_CAN_BROWSE_CONTENT = 65536,
	SYNCMGR_HCM_CAN_SHOW_SCHEDULE = 131072,
	SYNCMGR_HCM_QUERY_BEFORE_ACTIVATE = 1048576,
	SYNCMGR_HCM_QUERY_BEFORE_DEACTIVATE = 2097152,
	SYNCMGR_HCM_QUERY_BEFORE_ENABLE = 4194304,
	SYNCMGR_HCM_QUERY_BEFORE_DISABLE = 8388608,
	SYNCMGR_HCM_VALID_MASK = 15925271,
}


[AllowDuplicates]
public enum SYNCMGR_HANDLER_POLICIES : int32
{
	SYNCMGR_HPM_NONE = 0,
	SYNCMGR_HPM_PREVENT_ACTIVATE = 1,
	SYNCMGR_HPM_PREVENT_DEACTIVATE = 2,
	SYNCMGR_HPM_PREVENT_ENABLE = 4,
	SYNCMGR_HPM_PREVENT_DISABLE = 8,
	SYNCMGR_HPM_PREVENT_START_SYNC = 16,
	SYNCMGR_HPM_PREVENT_STOP_SYNC = 32,
	SYNCMGR_HPM_DISABLE_ENABLE = 256,
	SYNCMGR_HPM_DISABLE_DISABLE = 512,
	SYNCMGR_HPM_DISABLE_START_SYNC = 1024,
	SYNCMGR_HPM_DISABLE_STOP_SYNC = 2048,
	SYNCMGR_HPM_DISABLE_BROWSE = 4096,
	SYNCMGR_HPM_DISABLE_SCHEDULE = 8192,
	SYNCMGR_HPM_HIDDEN_BY_DEFAULT = 65536,
	SYNCMGR_HPM_BACKGROUND_SYNC_ONLY = 48,
	SYNCMGR_HPM_VALID_MASK = 77631,
}


[AllowDuplicates]
public enum SYNCMGR_HANDLER_TYPE : int32
{
	SYNCMGR_HT_UNSPECIFIED = 0,
	SYNCMGR_HT_APPLICATION = 1,
	SYNCMGR_HT_DEVICE = 2,
	SYNCMGR_HT_FOLDER = 3,
	SYNCMGR_HT_SERVICE = 4,
	SYNCMGR_HT_COMPUTER = 5,
	SYNCMGR_HT_MIN = 0,
	SYNCMGR_HT_MAX = 5,
}


[AllowDuplicates]
public enum SYNCMGR_ITEM_CAPABILITIES : int32
{
	SYNCMGR_ICM_NONE = 0,
	SYNCMGR_ICM_PROVIDES_ICON = 1,
	SYNCMGR_ICM_EVENT_STORE = 2,
	SYNCMGR_ICM_CONFLICT_STORE = 4,
	SYNCMGR_ICM_CAN_DELETE = 16,
	SYNCMGR_ICM_CAN_BROWSE_CONTENT = 65536,
	SYNCMGR_ICM_QUERY_BEFORE_ENABLE = 1048576,
	SYNCMGR_ICM_QUERY_BEFORE_DISABLE = 2097152,
	SYNCMGR_ICM_QUERY_BEFORE_DELETE = 4194304,
	SYNCMGR_ICM_VALID_MASK = 7405591,
}


[AllowDuplicates]
public enum SYNCMGR_ITEM_POLICIES : int32
{
	SYNCMGR_IPM_NONE = 0,
	SYNCMGR_IPM_PREVENT_ENABLE = 1,
	SYNCMGR_IPM_PREVENT_DISABLE = 2,
	SYNCMGR_IPM_PREVENT_START_SYNC = 4,
	SYNCMGR_IPM_PREVENT_STOP_SYNC = 8,
	SYNCMGR_IPM_DISABLE_ENABLE = 16,
	SYNCMGR_IPM_DISABLE_DISABLE = 32,
	SYNCMGR_IPM_DISABLE_START_SYNC = 64,
	SYNCMGR_IPM_DISABLE_STOP_SYNC = 128,
	SYNCMGR_IPM_DISABLE_BROWSE = 256,
	SYNCMGR_IPM_DISABLE_DELETE = 512,
	SYNCMGR_IPM_HIDDEN_BY_DEFAULT = 65536,
	SYNCMGR_IPM_VALID_MASK = 66303,
}


[AllowDuplicates]
public enum SYNCMGR_PROGRESS_STATUS : int32
{
	SYNCMGR_PS_UPDATING = 1,
	SYNCMGR_PS_UPDATING_INDETERMINATE = 2,
	SYNCMGR_PS_SUCCEEDED = 3,
	SYNCMGR_PS_FAILED = 4,
	SYNCMGR_PS_CANCELED = 5,
	SYNCMGR_PS_DISCONNECTED = 6,
	SYNCMGR_PS_MAX = 6,
}


[AllowDuplicates]
public enum SYNCMGR_CANCEL_REQUEST : int32
{
	SYNCMGR_CR_NONE = 0,
	SYNCMGR_CR_CANCEL_ITEM = 1,
	SYNCMGR_CR_CANCEL_ALL = 2,
	SYNCMGR_CR_MAX = 2,
}


[AllowDuplicates]
public enum SYNCMGR_EVENT_LEVEL : int32
{
	SYNCMGR_EL_INFORMATION = 1,
	SYNCMGR_EL_WARNING = 2,
	SYNCMGR_EL_ERROR = 3,
	SYNCMGR_EL_MAX = 3,
}


[AllowDuplicates]
public enum SYNCMGR_EVENT_FLAGS : int32
{
	SYNCMGR_EF_NONE = 0,
	SYNCMGR_EF_VALID = 0,
}


[AllowDuplicates]
public enum SYNCMGR_CONTROL_FLAGS : int32
{
	SYNCMGR_CF_NONE = 0,
	SYNCMGR_CF_NOWAIT = 0,
	SYNCMGR_CF_WAIT = 1,
	SYNCMGR_CF_NOUI = 2,
	SYNCMGR_CF_VALID = 3,
}


[AllowDuplicates]
public enum SYNCMGR_SYNC_CONTROL_FLAGS : int32
{
	SYNCMGR_SCF_NONE = 0,
	SYNCMGR_SCF_IGNORE_IF_ALREADY_SYNCING = 1,
	SYNCMGR_SCF_VALID = 1,
}


[AllowDuplicates]
public enum SYNCMGR_UPDATE_REASON : int32
{
	SYNCMGR_UR_ADDED = 0,
	SYNCMGR_UR_CHANGED = 1,
	SYNCMGR_UR_REMOVED = 2,
	SYNCMGR_UR_MAX = 2,
}


[AllowDuplicates]
public enum SYNCMGR_CONFLICT_ITEM_TYPE : int32
{
	SYNCMGR_CIT_UPDATED = 1,
	SYNCMGR_CIT_DELETED = 2,
}


[AllowDuplicates]
public enum SYNCMGR_RESOLUTION_ABILITIES : int32
{
	SYNCMGR_RA_KEEPOTHER = 1,
	SYNCMGR_RA_KEEPRECENT = 2,
	SYNCMGR_RA_REMOVEFROMSYNCSET = 4,
	SYNCMGR_RA_KEEP_SINGLE = 8,
	SYNCMGR_RA_KEEP_MULTIPLE = 16,
	SYNCMGR_RA_VALID = 31,
}


[AllowDuplicates]
public enum SYNCMGR_RESOLUTION_FEEDBACK : int32
{
	SYNCMGR_RF_CONTINUE = 0,
	SYNCMGR_RF_REFRESH = 1,
	SYNCMGR_RF_CANCEL = 2,
}


[AllowDuplicates]
public enum SYNCMGR_PRESENTER_NEXT_STEP : int32
{
	SYNCMGR_PNS_CONTINUE = 0,
	SYNCMGR_PNS_DEFAULT = 1,
	SYNCMGR_PNS_CANCEL = 2,
}


[AllowDuplicates]
public enum SYNCMGR_PRESENTER_CHOICE : int32
{
	SYNCMGR_PC_NO_CHOICE = 0,
	SYNCMGR_PC_KEEP_ONE = 1,
	SYNCMGR_PC_KEEP_MULTIPLE = 2,
	SYNCMGR_PC_KEEP_RECENT = 3,
	SYNCMGR_PC_REMOVE_FROM_SYNC_SET = 4,
	SYNCMGR_PC_SKIP = 5,
}


[AllowDuplicates]
public enum WTS_FLAGS : int32
{
	WTS_NONE = 0,
	WTS_EXTRACT = 0,
	WTS_INCACHEONLY = 1,
	WTS_FASTEXTRACT = 2,
	WTS_FORCEEXTRACTION = 4,
	WTS_SLOWRECLAIM = 8,
	WTS_EXTRACTDONOTCACHE = 32,
	WTS_SCALETOREQUESTEDSIZE = 64,
	WTS_SKIPFASTEXTRACT = 128,
	WTS_EXTRACTINPROC = 256,
	WTS_CROPTOSQUARE = 512,
	WTS_INSTANCESURROGATE = 1024,
	WTS_REQUIRESURROGATE = 2048,
	WTS_APPSTYLE = 8192,
	WTS_WIDETHUMBNAILS = 16384,
	WTS_IDEALCACHESIZEONLY = 32768,
	WTS_SCALEUP = 65536,
}


[AllowDuplicates]
public enum WTS_CACHEFLAGS : int32
{
	WTS_DEFAULT = 0,
	WTS_LOWQUALITY = 1,
	WTS_CACHED = 2,
}


[AllowDuplicates]
public enum WTS_CONTEXTFLAGS : int32
{
	WTSCF_DEFAULT = 0,
	WTSCF_APPSTYLE = 1,
	WTSCF_SQUARE = 2,
	WTSCF_WIDE = 4,
	WTSCF_FAST = 8,
}


[AllowDuplicates]
public enum WTS_ALPHATYPE : int32
{
	WTSAT_UNKNOWN = 0,
	WTSAT_RGB = 1,
	WTSAT_ARGB = 2,
}


[AllowDuplicates]
public enum SYNCMGRSTATUS : int32
{
	SYNCMGRSTATUS_STOPPED = 0,
	SYNCMGRSTATUS_SKIPPED = 1,
	SYNCMGRSTATUS_PENDING = 2,
	SYNCMGRSTATUS_UPDATING = 3,
	SYNCMGRSTATUS_SUCCEEDED = 4,
	SYNCMGRSTATUS_FAILED = 5,
	SYNCMGRSTATUS_PAUSED = 6,
	SYNCMGRSTATUS_RESUMING = 7,
	SYNCMGRSTATUS_UPDATING_INDETERMINATE = 8,
	SYNCMGRSTATUS_DELETED = 256,
}


[AllowDuplicates]
public enum SYNCMGRLOGLEVEL : int32
{
	SYNCMGRLOGLEVEL_INFORMATION = 1,
	SYNCMGRLOGLEVEL_WARNING = 2,
	SYNCMGRLOGLEVEL_ERROR = 3,
	SYNCMGRLOGLEVEL_LOGLEVELMAX = 3,
}


[AllowDuplicates]
public enum SYNCMGRERRORFLAGS : int32
{
	SYNCMGRERRORFLAG_ENABLEJUMPTEXT = 1,
}


[AllowDuplicates]
public enum SYNCMGRITEMFLAGS : int32
{
	SYNCMGRITEM_HASPROPERTIES = 1,
	SYNCMGRITEM_TEMPORARY = 2,
	SYNCMGRITEM_ROAMINGUSER = 4,
	SYNCMGRITEM_LASTUPDATETIME = 8,
	SYNCMGRITEM_MAYDELETEITEM = 16,
	SYNCMGRITEM_HIDDEN = 32,
}


[AllowDuplicates]
public enum SYNCMGRFLAG : int32
{
	SYNCMGRFLAG_CONNECT = 1,
	SYNCMGRFLAG_PENDINGDISCONNECT = 2,
	SYNCMGRFLAG_MANUAL = 3,
	SYNCMGRFLAG_IDLE = 4,
	SYNCMGRFLAG_INVOKE = 5,
	SYNCMGRFLAG_SCHEDULED = 6,
	SYNCMGRFLAG_EVENTMASK = 255,
	SYNCMGRFLAG_SETTINGS = 256,
	SYNCMGRFLAG_MAYBOTHERUSER = 512,
}


[AllowDuplicates]
public enum SYNCMGRHANDLERFLAGS : int32
{
	SYNCMGRHANDLER_HASPROPERTIES = 1,
	SYNCMGRHANDLER_MAYESTABLISHCONNECTION = 2,
	SYNCMGRHANDLER_ALWAYSLISTHANDLER = 4,
	SYNCMGRHANDLER_HIDDEN = 8,
}


[AllowDuplicates]
public enum SYNCMGRITEMSTATE : int32
{
	SYNCMGRITEMSTATE_UNCHECKED = 0,
	SYNCMGRITEMSTATE_CHECKED = 1,
}


[AllowDuplicates]
public enum SYNCMGRINVOKEFLAGS : int32
{
	SYNCMGRINVOKE_STARTSYNC = 2,
	SYNCMGRINVOKE_MINIMIZED = 4,
}


[AllowDuplicates]
public enum SYNCMGRREGISTERFLAGS : int32
{
	SYNCMGRREGISTERFLAG_CONNECT = 1,
	SYNCMGRREGISTERFLAG_PENDINGDISCONNECT = 2,
	SYNCMGRREGISTERFLAG_IDLE = 4,
}


[AllowDuplicates]
public enum ThumbnailStreamCacheOptions : int32
{
	ExtractIfNotCached = 0,
	ReturnOnlyIfCached = 1,
	ResizeThumbnail = 2,
	AllowSmallerSize = 4,
}


[AllowDuplicates]
public enum TLENUMF : int32
{
	TLEF_RELATIVE_INCLUDE_CURRENT = 1,
	TLEF_RELATIVE_BACK = 16,
	TLEF_RELATIVE_FORE = 32,
	TLEF_INCLUDE_UNINVOKEABLE = 64,
	TLEF_ABSOLUTE = 49,
	TLEF_EXCLUDE_SUBFRAME_ENTRIES = 128,
	TLEF_EXCLUDE_ABOUT_PAGES = 256,
}


[AllowDuplicates]
public enum HLSR : int32
{
	HLSR_HOME = 0,
	HLSR_SEARCHPAGE = 1,
	HLSR_HISTORYFOLDER = 2,
}


[AllowDuplicates]
public enum HLSHORTCUTF : int32
{
	HLSHORTCUTF_DEFAULT = 0,
	HLSHORTCUTF_DONTACTUALLYCREATE = 1,
	HLSHORTCUTF_USEFILENAMEFROMFRIENDLYNAME = 2,
	HLSHORTCUTF_USEUNIQUEFILENAME = 4,
	HLSHORTCUTF_MAYUSEEXISTINGSHORTCUT = 8,
}


[AllowDuplicates]
public enum HLTRANSLATEF : int32
{
	HLTRANSLATEF_DEFAULT = 0,
	HLTRANSLATEF_DONTAPPLYDEFAULTPREFIX = 1,
}


[AllowDuplicates]
public enum HLNF : uint32
{
	HLNF_INTERNALJUMP = 1,
	HLNF_OPENINNEWWINDOW = 2,
	HLNF_NAVIGATINGBACK = 4,
	HLNF_NAVIGATINGFORWARD = 8,
	HLNF_NAVIGATINGTOSTACKITEM = 16,
	HLNF_CREATENOHISTORY = 32,
}


[AllowDuplicates]
public enum HLINKGETREF : int32
{
	HLINKGETREF_DEFAULT = 0,
	HLINKGETREF_ABSOLUTE = 1,
	HLINKGETREF_RELATIVE = 2,
}


[AllowDuplicates]
public enum HLFNAMEF : uint32
{
	HLFNAMEF_DEFAULT = 0,
	HLFNAMEF_TRYCACHE = 1,
	HLFNAMEF_TRYPRETTYTARGET = 2,
	HLFNAMEF_TRYFULLTARGET = 4,
	HLFNAMEF_TRYWIN95SHORTCUT = 8,
}


[AllowDuplicates]
public enum HLINKMISC : int32
{
	HLINKMISC_RELATIVE = 1,
}


[AllowDuplicates]
public enum HLINKSETF : int32
{
	HLINKSETF_TARGET = 1,
	HLINKSETF_LOCATION = 2,
}


[AllowDuplicates]
public enum HLINKWHICHMK : int32
{
	HLINKWHICHMK_CONTAINER = 1,
	HLINKWHICHMK_BASE = 2,
}


[AllowDuplicates]
public enum HLTB_INFO : int32
{
	HLTB_DOCKEDLEFT = 0,
	HLTB_DOCKEDTOP = 1,
	HLTB_DOCKEDRIGHT = 2,
	HLTB_DOCKEDBOTTOM = 3,
	HLTB_FLOATING = 4,
}


[AllowDuplicates]
public enum HLBWIF_FLAGS : uint32
{
	HLBWIF_HASFRAMEWNDINFO = 1,
	HLBWIF_HASDOCWNDINFO = 2,
	HLBWIF_FRAMEWNDMAXIMIZED = 4,
	HLBWIF_DOCWNDMAXIMIZED = 8,
	HLBWIF_HASWEBTOOLBARINFO = 16,
	HLBWIF_WEBTOOLBARHIDDEN = 32,
}


[AllowDuplicates]
public enum HLID_INFO : uint32
{
	HLID_INVALID = 0,
	HLID_PREVIOUS = 4294967295,
	HLID_NEXT = 4294967294,
	HLID_CURRENT = 4294967293,
	HLID_STACKBOTTOM = 4294967292,
	HLID_STACKTOP = 4294967291,
}


[AllowDuplicates]
public enum HLQF_INFO : int32
{
	HLQF_ISVALID = 1,
	HLQF_ISCURRENT = 2,
}


[AllowDuplicates]
public enum BNSTATE : int32
{
	BNS_NORMAL = 0,
	BNS_BEGIN_NAVIGATE = 1,
	BNS_NAVIGATE = 2,
}


[AllowDuplicates]
public enum SHELLBROWSERSHOWCONTROL : int32
{
	SBSC_HIDE = 0,
	SBSC_SHOW = 1,
	SBSC_TOGGLE = 2,
	SBSC_QUERY = 3,
}


[AllowDuplicates]
public enum SECURELOCKCODE : int32
{
	SECURELOCK_NOCHANGE = -1,
	SECURELOCK_SET_UNSECURE = 0,
	SECURELOCK_SET_MIXED = 1,
	SECURELOCK_SET_SECUREUNKNOWNBIT = 2,
	SECURELOCK_SET_SECURE40BIT = 3,
	SECURELOCK_SET_SECURE56BIT = 4,
	SECURELOCK_SET_FORTEZZA = 5,
	SECURELOCK_SET_SECURE128BIT = 6,
	SECURELOCK_FIRSTSUGGEST = 7,
	SECURELOCK_SUGGEST_UNSECURE = 7,
	SECURELOCK_SUGGEST_MIXED = 8,
	SECURELOCK_SUGGEST_SECUREUNKNOWNBIT = 9,
	SECURELOCK_SUGGEST_SECURE40BIT = 10,
	SECURELOCK_SUGGEST_SECURE56BIT = 11,
	SECURELOCK_SUGGEST_FORTEZZA = 12,
	SECURELOCK_SUGGEST_SECURE128BIT = 13,
}


[AllowDuplicates]
public enum IEPDNFLAGS : int32
{
	IEPDN_BINDINGUI = 1,
}


[AllowDuplicates]
public enum TI_FLAGS : int32
{
	TI_BITMAP = 1,
	TI_JPEG = 2,
}


[AllowDuplicates]
public enum PATHCCH_OPTIONS : uint32
{
	PATHCCH_NONE = 0,
	PATHCCH_ALLOW_LONG_PATHS = 1,
	PATHCCH_FORCE_ENABLE_LONG_NAME_PROCESS = 2,
	PATHCCH_FORCE_DISABLE_LONG_NAME_PROCESS = 4,
	PATHCCH_DO_NOT_NORMALIZE_SEGMENTS = 8,
	PATHCCH_ENSURE_IS_EXTENDED_LENGTH_PATH = 16,
	PATHCCH_ENSURE_TRAILING_SLASH = 32,
	PATHCCH_CANONICALIZE_SLASHES = 64,
}


[AllowDuplicates]
public enum IURL_SETURL_FLAGS : int32
{
	IURL_SETURL_FL_GUESS_PROTOCOL = 1,
	IURL_SETURL_FL_USE_DEFAULT_PROTOCOL = 2,
}


[AllowDuplicates]
public enum IURL_INVOKECOMMAND_FLAGS : int32
{
	IURL_INVOKECOMMAND_FL_ALLOW_UI = 1,
	IURL_INVOKECOMMAND_FL_USE_DEFAULT_VERB = 2,
	IURL_INVOKECOMMAND_FL_DDEWAIT = 4,
	IURL_INVOKECOMMAND_FL_ASYNCOK = 8,
	IURL_INVOKECOMMAND_FL_LOG_USAGE = 16,
}


[AllowDuplicates]
public enum TRANSLATEURL_IN_FLAGS : int32
{
	TRANSLATEURL_FL_GUESS_PROTOCOL = 1,
	TRANSLATEURL_FL_USE_DEFAULT_PROTOCOL = 2,
}


[AllowDuplicates]
public enum URLASSOCIATIONDIALOG_IN_FLAGS : int32
{
	URLASSOCDLG_FL_USE_DEFAULT_NAME = 1,
	URLASSOCDLG_FL_REGISTER_ASSOC = 2,
}


[AllowDuplicates]
public enum MIMEASSOCIATIONDIALOG_IN_FLAGS : int32
{
	MIMEASSOCDLG_FL_REGISTER_ASSOC = 1,
}

#endregion

#region Function Pointers
public function LRESULT SUBCLASSPROC(HWND hWnd, uint32 uMsg, WPARAM wParam, LPARAM lParam, uint uIdSubclass, uint dwRefData);

public function int32 BFFCALLBACK(HWND hwnd, uint32 uMsg, LPARAM lParam, LPARAM lpData);

public function HRESULT LPFNDFMCALLBACK(IShellFolder* psf, HWND hwnd, IDataObject* pdtobj, uint32 uMsg, WPARAM wParam, LPARAM lParam);

public function HRESULT LPFNVIEWCALLBACK(IShellView* psvOuter, IShellFolder* psf, HWND hwndMain, uint32 uMsg, WPARAM wParam, LPARAM lParam);

public function HRESULT PFNCANSHAREFOLDERW(PWSTR pszPath);

public function HRESULT PFNSHOWSHAREFOLDERUIW(HWND hwndParent, PWSTR pszPath);

public function HRESULT DLLGETVERSIONPROC(DLLVERSIONINFO* param0);

public function int32 APPLET_PROC(HWND hwndCpl, uint32 msg, LPARAM lParam1, LPARAM lParam2);

public function void PAPPSTATE_CHANGE_ROUTINE(BOOLEAN Quiesced, void* Context);

public function void PAPPCONSTRAIN_CHANGE_ROUTINE(BOOLEAN Constrained, void* Context);

#endregion

#region Structs
[CRepr]
public struct _APPSTATE_REGISTRATION
{
}

[CRepr]
public struct _APPCONSTRAIN_REGISTRATION
{
}

[CRepr]
public struct APPCATEGORYINFO
{
	public uint32 Locale;
	public PWSTR pszDescription;
	public Guid AppCategoryId;
}

[CRepr]
public struct APPCATEGORYINFOLIST
{
	public uint32 cCategory;
	public APPCATEGORYINFO* pCategoryInfo;
}

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DRAGINFOA
{
	public uint32 uSize;
	public POINT pt;
	public BOOL fNC;
	public PSTR lpFileList;
	public uint32 grfKeyState;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct DRAGINFOW
{
	public uint32 uSize;
	public POINT pt;
	public BOOL fNC;
	public PWSTR lpFileList;
	public uint32 grfKeyState;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct APPBARDATA
{
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uCallbackMessage;
	public uint32 uEdge;
	public RECT rc;
	public LPARAM lParam;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHFILEOPSTRUCTA
{
	public HWND hwnd;
	public uint32 wFunc;
	public int8* pFrom;
	public int8* pTo;
	public uint16 fFlags;
	public BOOL fAnyOperationsAborted;
	public void* hNameMappings;
	public PSTR lpszProgressTitle;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHFILEOPSTRUCTW
{
	public HWND hwnd;
	public uint32 wFunc;
	public PWSTR pFrom;
	public PWSTR pTo;
	public uint16 fFlags;
	public BOOL fAnyOperationsAborted;
	public void* hNameMappings;
	public PWSTR lpszProgressTitle;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHNAMEMAPPINGA
{
	public PSTR pszOldPath;
	public PSTR pszNewPath;
	public int32 cchOldPath;
	public int32 cchNewPath;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHNAMEMAPPINGW
{
	public PWSTR pszOldPath;
	public PWSTR pszNewPath;
	public int32 cchOldPath;
	public int32 cchNewPath;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHELLEXECUTEINFOA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public HANDLE hIcon;
		public HANDLE hMonitor;
	}
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PSTR lpVerb;
	public PSTR lpFile;
	public PSTR lpParameters;
	public PSTR lpDirectory;
	public int32 nShow;
	public HINSTANCE hInstApp;
	public void* lpIDList;
	public PSTR lpClass;
	public HKEY hkeyClass;
	public uint32 dwHotKey;
	public using _Anonymous_e__Union Anonymous;
	public HANDLE hProcess;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHELLEXECUTEINFOW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public HANDLE hIcon;
		public HANDLE hMonitor;
	}
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PWSTR lpVerb;
	public PWSTR lpFile;
	public PWSTR lpParameters;
	public PWSTR lpDirectory;
	public int32 nShow;
	public HINSTANCE hInstApp;
	public void* lpIDList;
	public PWSTR lpClass;
	public HKEY hkeyClass;
	public uint32 dwHotKey;
	public using _Anonymous_e__Union Anonymous;
	public HANDLE hProcess;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHCREATEPROCESSINFOW
{
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PWSTR pszFile;
	public PWSTR pszParameters;
	public PWSTR pszCurrentDirectory;
	public HANDLE hUserToken;
	public SECURITY_ATTRIBUTES* lpProcessAttributes;
	public SECURITY_ATTRIBUTES* lpThreadAttributes;
	public BOOL bInheritHandles;
	public uint32 dwCreationFlags;
	public STARTUPINFOW* lpStartupInfo;
	public PROCESS_INFORMATION* lpProcessInformation;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct ASSOCIATIONELEMENT
{
	public ASSOCCLASS ac;
	public HKEY hkClass;
	public PWSTR pszClass;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHQUERYRBINFO
{
	public uint32 cbSize;
	public int64 i64Size;
	public int64 i64NumItems;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct NOTIFYICONDATAA
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 uTimeout;
		public uint32 uVersion;
	}
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public NOTIFY_ICON_DATA_FLAGS uFlags;
	public uint32 uCallbackMessage;
	public HICON hIcon;
	public CHAR[128] szTip;
	public NOTIFY_ICON_STATE dwState;
	public uint32 dwStateMask;
	public CHAR[256] szInfo;
	public using _Anonymous_e__Union Anonymous;
	public CHAR[64] szInfoTitle;
	public NOTIFY_ICON_INFOTIP_FLAGS dwInfoFlags;
	public Guid guidItem;
	public HICON hBalloonIcon;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct NOTIFYICONDATAW
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint32 uTimeout;
		public uint32 uVersion;
	}
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public NOTIFY_ICON_DATA_FLAGS uFlags;
	public uint32 uCallbackMessage;
	public HICON hIcon;
	public char16[128] szTip;
	public NOTIFY_ICON_STATE dwState;
	public uint32 dwStateMask;
	public char16[256] szInfo;
	public using _Anonymous_e__Union Anonymous;
	public char16[64] szInfoTitle;
	public NOTIFY_ICON_INFOTIP_FLAGS dwInfoFlags;
	public Guid guidItem;
	public HICON hBalloonIcon;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct NOTIFYICONIDENTIFIER
{
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public Guid guidItem;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHFILEINFOA
{
	public HICON hIcon;
	public int32 iIcon;
	public uint32 dwAttributes;
	public CHAR[260] szDisplayName;
	public CHAR[80] szTypeName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHFILEINFOW
{
	public HICON hIcon;
	public int32 iIcon;
	public uint32 dwAttributes;
	public char16[260] szDisplayName;
	public char16[80] szTypeName;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct SHSTOCKICONINFO
{
	public uint32 cbSize;
	public HICON hIcon;
	public int32 iSysImageIndex;
	public int32 iIcon;
	public char16[260] szPath;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPEN_PRINTER_PROPS_INFOA
{
	public uint32 dwSize;
	public PSTR pszSheetName;
	public uint32 uSheetIndex;
	public uint32 dwFlags;
	public BOOL bModal;
}
#endif

#if BF_64_BIT || BF_ARM_64
[CRepr]
public struct OPEN_PRINTER_PROPS_INFOW
{
	public uint32 dwSize;
	public PWSTR pszSheetName;
	public uint32 uSheetIndex;
	public uint32 dwFlags;
	public BOOL bModal;
}
#endif

[CRepr]
public struct HELPINFO
{
	public uint32 cbSize;
	public HELP_INFO_TYPE iContextType;
	public int32 iCtrlId;
	public HANDLE hItemHandle;
	public uint dwContextId;
	public POINT MousePos;
}

[CRepr]
public struct MULTIKEYHELPA
{
	public uint32 mkSize;
	public CHAR mkKeylist;
	public CHAR* szKeyphrase mut => &szKeyphrase_impl;
	private CHAR[ANYSIZE_ARRAY] szKeyphrase_impl;
}

[CRepr]
public struct MULTIKEYHELPW
{
	public uint32 mkSize;
	public char16 mkKeylist;
	public char16* szKeyphrase mut => &szKeyphrase_impl;
	private char16[ANYSIZE_ARRAY] szKeyphrase_impl;
}

[CRepr]
public struct HELPWININFOA
{
	public int32 wStructSize;
	public int32 x;
	public int32 y;
	public int32 dx;
	public int32 dy;
	public int32 wMax;
	public CHAR[2] rgchMember;
}

[CRepr]
public struct HELPWININFOW
{
	public int32 wStructSize;
	public int32 x;
	public int32 y;
	public int32 dx;
	public int32 dy;
	public int32 wMax;
	public char16[2] rgchMember;
}

[CRepr]
public struct CMINVOKECOMMANDINFO
{
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PSTR lpVerb;
	public PSTR lpParameters;
	public PSTR lpDirectory;
	public int32 nShow;
	public uint32 dwHotKey;
	public HANDLE hIcon;
}

[CRepr]
public struct CMINVOKECOMMANDINFOEX
{
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PSTR lpVerb;
	public PSTR lpParameters;
	public PSTR lpDirectory;
	public int32 nShow;
	public uint32 dwHotKey;
	public HANDLE hIcon;
	public PSTR lpTitle;
	public PWSTR lpVerbW;
	public PWSTR lpParametersW;
	public PWSTR lpDirectoryW;
	public PWSTR lpTitleW;
	public POINT ptInvoke;
}

[CRepr]
public struct CMINVOKECOMMANDINFOEX_REMOTE
{
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PSTR lpVerbString;
	public PSTR lpParameters;
	public PSTR lpDirectory;
	public int32 nShow;
	public uint32 dwHotKey;
	public PSTR lpTitle;
	public PWSTR lpVerbWString;
	public PWSTR lpParametersW;
	public PWSTR lpDirectoryW;
	public PWSTR lpTitleW;
	public POINT ptInvoke;
	public uint32 lpVerbInt;
	public uint32 lpVerbWInt;
}

[CRepr]
public struct PERSIST_FOLDER_TARGET_INFO
{
	public ITEMIDLIST* pidlTargetFolder;
	public char16[260] szTargetParsingName;
	public char16[260] szNetworkProvider;
	public uint32 dwAttributes;
	public int32 csidl;
}

[CRepr]
public struct EXTRASEARCH
{
	public Guid guidSearch;
	public char16[80] wszFriendlyName;
	public char16[2084] wszUrl;
}

[CRepr]
public struct FOLDERSETTINGS
{
	public uint32 ViewMode;
	public uint32 fFlags;
}

[CRepr]
public struct SV2CVW2_PARAMS
{
	public uint32 cbSize;
	public IShellView* psvPrev;
	public FOLDERSETTINGS* pfs;
	public IShellBrowser* psbOwner;
	public RECT* prcView;
	public Guid* pvid;
	public HWND hwndView;
}

[CRepr]
public struct SORTCOLUMN
{
	public PROPERTYKEY propkey;
	public SORTDIRECTION direction;
}

[CRepr]
public struct CM_COLUMNINFO
{
	public uint32 cbSize;
	public uint32 dwMask;
	public uint32 dwState;
	public uint32 uWidth;
	public uint32 uDefaultWidth;
	public uint32 uIdealWidth;
	public char16[80] wszName;
}

[CRepr]
public struct SHELL_ITEM_RESOURCE
{
	public Guid guidType;
	public char16[260] szName;
}

[CRepr]
public struct CATEGORY_INFO
{
	public CATEGORYINFO_FLAGS cif;
	public char16[260] wszName;
}

[CRepr]
public struct SHDRAGIMAGE
{
	public SIZE sizeDragImage;
	public POINT ptOffset;
	public HBITMAP hbmpDragImage;
	public COLORREF crColorKey;
}

[CRepr]
public struct DESKBANDINFO
{
	public uint32 dwMask;
	public POINTL ptMinSize;
	public POINTL ptMaxSize;
	public POINTL ptIntegral;
	public POINTL ptActual;
	public char16[256] wszTitle;
	public uint32 dwModeFlags;
	public COLORREF crBkgnd;
}

[CRepr]
public struct THUMBBUTTON
{
	public THUMBBUTTONMASK dwMask;
	public uint32 iId;
	public uint32 iBitmap;
	public HICON hIcon;
	public char16[260] szTip;
	public THUMBBUTTONFLAGS dwFlags;
}

[CRepr]
public struct BANDSITEINFO
{
	public uint32 dwMask;
	public uint32 dwState;
	public uint32 dwStyle;
}

[CRepr, Packed(1)]
public struct DELEGATEITEMID
{
	public uint16 cbSize;
	public uint16 wOuter;
	public uint16 cbInner;
	public uint8* rgb mut => &rgb_impl;
	private uint8[ANYSIZE_ARRAY] rgb_impl;
}

[CRepr]
public struct SMDATA
{
	public uint32 dwMask;
	public uint32 dwFlags;
	public HMENU hmenu;
	public HWND hwnd;
	public uint32 uId;
	public uint32 uIdParent;
	public uint32 uIdAncestor;
	public IUnknown* punk;
	public ITEMIDLIST* pidlFolder;
	public ITEMIDLIST* pidlItem;
	public IShellFolder* psf;
	public void* pvUserData;
}

[CRepr]
public struct SMINFO
{
	public uint32 dwMask;
	public uint32 dwType;
	public uint32 dwFlags;
	public int32 iIcon;
}

[CRepr]
public struct SMCSHCHANGENOTIFYSTRUCT
{
	public int32 lEvent;
	public ITEMIDLIST* pidl1;
	public ITEMIDLIST* pidl2;
}

[CRepr]
public struct KNOWNFOLDER_DEFINITION
{
	public KF_CATEGORY category;
	public PWSTR pszName;
	public PWSTR pszDescription;
	public Guid fidParent;
	public PWSTR pszRelativePath;
	public PWSTR pszParsingName;
	public PWSTR pszTooltip;
	public PWSTR pszLocalizedName;
	public PWSTR pszIcon;
	public PWSTR pszSecurity;
	public uint32 dwAttributes;
	public uint32 kfdFlags;
	public Guid ftidType;
}

[CRepr]
public struct PREVIEWHANDLERFRAMEINFO
{
	public HACCEL haccel;
	public uint32 cAccelEntries;
}

[CRepr]
public struct BANNER_NOTIFICATION
{
	public BANNER_NOTIFICATION_EVENT event;
	public PWSTR providerIdentity;
	public PWSTR contentId;
}

[CRepr]
public struct NSTCCUSTOMDRAW
{
	public IShellItem* psi;
	public uint32 uItemState;
	public uint32 nstcis;
	public PWSTR pszText;
	public int32 iImage;
	public HIMAGELIST himl;
	public int32 iLevel;
	public int32 iIndent;
}

[CRepr, Packed(1)]
public struct DATABLOCK_HEADER
{
	public uint32 cbSize;
	public uint32 dwSignature;
}

[CRepr, Packed(1)]
public struct NT_CONSOLE_PROPS
{
	public DATABLOCK_HEADER dbh;
	public uint16 wFillAttribute;
	public uint16 wPopupFillAttribute;
	public COORD dwScreenBufferSize;
	public COORD dwWindowSize;
	public COORD dwWindowOrigin;
	public uint32 nFont;
	public uint32 nInputBufferSize;
	public COORD dwFontSize;
	public uint32 uFontFamily;
	public uint32 uFontWeight;
	public char16[32] FaceName;
	public uint32 uCursorSize;
	public BOOL bFullScreen;
	public BOOL bQuickEdit;
	public BOOL bInsertMode;
	public BOOL bAutoPosition;
	public uint32 uHistoryBufferSize;
	public uint32 uNumberOfHistoryBuffers;
	public BOOL bHistoryNoDup;
	public COLORREF[16] ColorTable;
}

[CRepr, Packed(1)]
public struct NT_FE_CONSOLE_PROPS
{
	public DATABLOCK_HEADER dbh;
	public uint32 uCodePage;
}

[CRepr, Packed(1)]
public struct EXP_DARWIN_LINK
{
	public DATABLOCK_HEADER dbh;
	public CHAR[260] szDarwinID;
	public char16[260] szwDarwinID;
}

[CRepr, Packed(1)]
public struct EXP_SPECIAL_FOLDER
{
	public uint32 cbSize;
	public uint32 dwSignature;
	public uint32 idSpecialFolder;
	public uint32 cbOffset;
}

[CRepr, Packed(1)]
public struct EXP_SZ_LINK
{
	public uint32 cbSize;
	public uint32 dwSignature;
	public CHAR[260] szTarget;
	public char16[260] swzTarget;
}

[CRepr, Packed(1)]
public struct EXP_PROPERTYSTORAGE
{
	public uint32 cbSize;
	public uint32 dwSignature;
	public uint8* abPropertyStorage mut => &abPropertyStorage_impl;
	private uint8[ANYSIZE_ARRAY] abPropertyStorage_impl;
}

[CRepr]
public struct SHFOLDERCUSTOMSETTINGS
{
	public uint32 dwSize;
	public uint32 dwMask;
	public Guid* pvid;
	public PWSTR pszWebViewTemplate;
	public uint32 cchWebViewTemplate;
	public PWSTR pszWebViewTemplateVersion;
	public PWSTR pszInfoTip;
	public uint32 cchInfoTip;
	public Guid* pclsid;
	public uint32 dwFlags;
	public PWSTR pszIconFile;
	public uint32 cchIconFile;
	public int32 iIconIndex;
	public PWSTR pszLogo;
	public uint32 cchLogo;
}

[CRepr]
public struct BROWSEINFOA
{
	public HWND hwndOwner;
	public ITEMIDLIST* pidlRoot;
	public PSTR pszDisplayName;
	public PSTR lpszTitle;
	public uint32 ulFlags;
	public BFFCALLBACK lpfn;
	public LPARAM lParam;
	public int32 iImage;
}

[CRepr]
public struct BROWSEINFOW
{
	public HWND hwndOwner;
	public ITEMIDLIST* pidlRoot;
	public PWSTR pszDisplayName;
	public PWSTR lpszTitle;
	public uint32 ulFlags;
	public BFFCALLBACK lpfn;
	public LPARAM lParam;
	public int32 iImage;
}

[CRepr]
public struct NRESARRAY
{
	public uint32 cItems;
	public NETRESOURCEA* nr mut => &nr_impl;
	private NETRESOURCEA[ANYSIZE_ARRAY] nr_impl;
}

[CRepr, Packed(1)]
public struct CIDA
{
	public uint32 cidl;
	public uint32* aoffset mut => &aoffset_impl;
	private uint32[ANYSIZE_ARRAY] aoffset_impl;
}

[CRepr, Packed(1)]
public struct FILEDESCRIPTORA
{
	public uint32 dwFlags;
	public Guid clsid;
	public SIZE sizel;
	public POINTL pointl;
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
	public CHAR[260] cFileName;
}

[CRepr, Packed(1)]
public struct FILEDESCRIPTORW
{
	public uint32 dwFlags;
	public Guid clsid;
	public SIZE sizel;
	public POINTL pointl;
	public uint32 dwFileAttributes;
	public FILETIME ftCreationTime;
	public FILETIME ftLastAccessTime;
	public FILETIME ftLastWriteTime;
	public uint32 nFileSizeHigh;
	public uint32 nFileSizeLow;
	public char16[260] cFileName;
}

[CRepr, Packed(1)]
public struct FILEGROUPDESCRIPTORA
{
	public uint32 cItems;
	public FILEDESCRIPTORA* fgd mut => &fgd_impl;
	private FILEDESCRIPTORA[ANYSIZE_ARRAY] fgd_impl;
}

[CRepr, Packed(1)]
public struct FILEGROUPDESCRIPTORW
{
	public uint32 cItems;
	public FILEDESCRIPTORW* fgd mut => &fgd_impl;
	private FILEDESCRIPTORW[ANYSIZE_ARRAY] fgd_impl;
}

[CRepr, Packed(1)]
public struct DROPFILES
{
	public uint32 pFiles;
	public POINT pt;
	public BOOL fNC;
	public BOOL fWide;
}

[CRepr, Packed(1)]
public struct FILE_ATTRIBUTES_ARRAY
{
	public uint32 cItems;
	public uint32 dwSumFileAttributes;
	public uint32 dwProductFileAttributes;
	public uint32* rgdwFileAttributes mut => &rgdwFileAttributes_impl;
	private uint32[ANYSIZE_ARRAY] rgdwFileAttributes_impl;
}

[CRepr, Packed(1)]
public struct DROPDESCRIPTION
{
	public DROPIMAGETYPE type;
	public char16[260] szMessage;
	public char16[260] szInsert;
}

[CRepr, Packed(1)]
public struct SHChangeNotifyEntry
{
	public ITEMIDLIST* pidl;
	public BOOL fRecursive;
}

[CRepr, Packed(1)]
public struct SHARDAPPIDINFO
{
	public IShellItem* psi;
	public PWSTR pszAppID;
}

[CRepr, Packed(1)]
public struct SHARDAPPIDINFOIDLIST
{
	public ITEMIDLIST* pidl;
	public PWSTR pszAppID;
}

[CRepr, Packed(1)]
public struct SHARDAPPIDINFOLINK
{
	public IShellLinkA* psl;
	public PWSTR pszAppID;
}

[CRepr, Packed(1)]
public struct SHChangeDWORDAsIDList
{
	public uint16 cb;
	public uint32 dwItem1;
	public uint32 dwItem2;
	public uint16 cbZero;
}

[CRepr, Packed(1)]
public struct SHChangeUpdateImageIDList
{
	public uint16 cb;
	public int32 iIconIndex;
	public int32 iCurIndex;
	public uint32 uFlags;
	public uint32 dwProcessID;
	public char16[260] szName;
	public uint16 cbZero;
}

[CRepr]
public struct SHDESCRIPTIONID
{
	public SHDID_ID dwDescriptionId;
	public Guid clsid;
}

[CRepr, Packed(1)]
public struct AUTO_SCROLL_DATA
{
	public int32 iNextSample;
	public uint32 dwLastScroll;
	public BOOL bFull;
	public POINT[3] pts;
	public uint32[3] dwTimes;
}

[CRepr, Packed(1)]
public struct CABINETSTATE
{
	public uint16 cLength;
	public uint16 nVersion;
	public int32 _bitfield;
	public uint32 fMenuEnumFilter;
}

[CRepr]
public struct OPENASINFO
{
	public PWSTR pcszFile;
	public PWSTR pcszClass;
	public OPEN_AS_INFO_FLAGS oaifInFlags;
}

[CRepr]
public struct QCMINFO_IDMAP_PLACEMENT
{
	public uint32 id;
	public uint32 fFlags;
}

[CRepr]
public struct QCMINFO_IDMAP
{
	public uint32 nMaxIds;
	public QCMINFO_IDMAP_PLACEMENT* pIdList mut => &pIdList_impl;
	private QCMINFO_IDMAP_PLACEMENT[ANYSIZE_ARRAY] pIdList_impl;
}

[CRepr]
public struct QCMINFO
{
	public HMENU hmenu;
	public uint32 indexMenu;
	public uint32 idCmdFirst;
	public uint32 idCmdLast;
	public QCMINFO_IDMAP* pIdMap;
}

[CRepr]
public struct DETAILSINFO
{
	public ITEMIDLIST* pidl;
	public int32 fmt;
	public int32 cxChar;
	public STRRET str;
	public int32 iImage;
}

[CRepr]
public struct SFVM_PROPPAGE_DATA
{
	public uint32 dwReserved;
	public LPFNSVADDPROPSHEETPAGE pfn;
	public LPARAM lParam;
}

[CRepr]
public struct SFVM_HELPTOPIC_DATA
{
	public char16[260] wszHelpFile;
	public char16[260] wszHelpTopic;
}

[CRepr]
public struct ITEMSPACING
{
	public int32 cxSmall;
	public int32 cySmall;
	public int32 cxLarge;
	public int32 cyLarge;
}

[CRepr]
public struct SFV_CREATE
{
	public uint32 cbSize;
	public IShellFolder* pshf;
	public IShellView* psvOuter;
	public IShellFolderViewCB* psfvcb;
}

[CRepr]
public struct DEFCONTEXTMENU
{
	public HWND hwnd;
	public IContextMenuCB* pcmcb;
	public ITEMIDLIST* pidlFolder;
	public IShellFolder* psf;
	public uint32 cidl;
	public ITEMIDLIST** apidl;
	public IUnknown* punkAssociationInfo;
	public uint32 cKeys;
	public HKEY* aKeys;
}

[CRepr]
public struct DFMICS
{
	public uint32 cbSize;
	public uint32 fMask;
	public LPARAM lParam;
	public uint32 idCmdFirst;
	public uint32 idDefMax;
	public CMINVOKECOMMANDINFO* pici;
	public IUnknown* punkSite;
}

[CRepr]
public struct CSFV
{
	public uint32 cbSize;
	public IShellFolder* pshf;
	public IShellView* psvOuter;
	public ITEMIDLIST* pidl;
	public int32 lEvents;
	public LPFNVIEWCALLBACK pfnCallback;
	public FOLDERVIEWMODE fvm;
}

[CRepr, Packed(1)]
public struct SHELLSTATEA
{
	public int32 _bitfield1;
	public uint32 dwWin95Unused;
	public uint32 uWin95Unused;
	public int32 lParamSort;
	public int32 iSortDirection;
	public uint32 version;
	public uint32 uNotUsed;
	public int32 _bitfield2;
}

[CRepr, Packed(1)]
public struct SHELLSTATEW
{
	public int32 _bitfield1;
	public uint32 dwWin95Unused;
	public uint32 uWin95Unused;
	public int32 lParamSort;
	public int32 iSortDirection;
	public uint32 version;
	public uint32 uNotUsed;
	public int32 _bitfield2;
}

[CRepr, Packed(1)]
public struct SHELLFLAGSTATE
{
	public int32 _bitfield;
}

[CRepr]
public struct BANDINFOSFB
{
	public uint32 dwMask;
	public uint32 dwStateMask;
	public uint32 dwState;
	public COLORREF crBkgnd;
	public COLORREF crBtnLt;
	public COLORREF crBtnDk;
	public uint16 wViewMode;
	public uint16 wAlign;
	public IShellFolder* psf;
	public ITEMIDLIST* pidl;
}

[CRepr, Packed(1)]
public struct SHCOLUMNINFO
{
	public PROPERTYKEY scid;
	public VARENUM vt;
	public uint32 fmt;
	public uint32 cChars;
	public uint32 csFlags;
	public char16[80] wszTitle;
	public char16[128] wszDescription;
}

[CRepr]
public struct SHCOLUMNINIT
{
	public uint32 dwFlags;
	public uint32 dwReserved;
	public char16[260] wszFolder;
}

[CRepr]
public struct SHCOLUMNDATA
{
	public uint32 dwFlags;
	public uint32 dwFileAttributes;
	public uint32 dwReserved;
	public PWSTR pwszExt;
	public char16[260] wszFile;
}

[CRepr, Packed(1)]
public struct SHChangeProductKeyAsIDList
{
	public uint16 cb;
	public char16[39] wszProductKey;
	public uint16 cbZero;
}

[CRepr]
public struct TBINFO
{
	public uint32 cbuttons;
	public uint32 uFlags;
}

[CRepr]
public struct SFV_SETITEMPOS
{
	public ITEMIDLIST* pidl;
	public POINT pt;
}

[CRepr]
public struct AASHELLMENUFILENAME
{
	public int16 cbTotal;
	public uint8[12] rgbReserved;
	public char16* szFileName mut => &szFileName_impl;
	private char16[ANYSIZE_ARRAY] szFileName_impl;
}

[CRepr]
public struct AASHELLMENUITEM
{
	public void* lpReserved1;
	public int32 iReserved;
	public uint32 uiReserved;
	public AASHELLMENUFILENAME* lpName;
	public PWSTR psz;
}

#if BF_32_BIT
[CRepr, Packed(1)]
public struct DRAGINFOA
{
	public uint32 uSize;
	public POINT pt;
	public BOOL fNC;
	public PSTR lpFileList;
	public uint32 grfKeyState;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct DRAGINFOW
{
	public uint32 uSize;
	public POINT pt;
	public BOOL fNC;
	public PWSTR lpFileList;
	public uint32 grfKeyState;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct APPBARDATA
{
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uCallbackMessage;
	public uint32 uEdge;
	public RECT rc;
	public LPARAM lParam;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHFILEOPSTRUCTA
{
	public HWND hwnd;
	public uint32 wFunc;
	public int8* pFrom;
	public int8* pTo;
	public uint16 fFlags;
	public BOOL fAnyOperationsAborted;
	public void* hNameMappings;
	public PSTR lpszProgressTitle;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHFILEOPSTRUCTW
{
	public HWND hwnd;
	public uint32 wFunc;
	public PWSTR pFrom;
	public PWSTR pTo;
	public uint16 fFlags;
	public BOOL fAnyOperationsAborted;
	public void* hNameMappings;
	public PWSTR lpszProgressTitle;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHNAMEMAPPINGA
{
	public PSTR pszOldPath;
	public PSTR pszNewPath;
	public int32 cchOldPath;
	public int32 cchNewPath;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHNAMEMAPPINGW
{
	public PWSTR pszOldPath;
	public PWSTR pszNewPath;
	public int32 cchOldPath;
	public int32 cchNewPath;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHELLEXECUTEINFOA
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public HANDLE hIcon;
		public HANDLE hMonitor;
	}
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PSTR lpVerb;
	public PSTR lpFile;
	public PSTR lpParameters;
	public PSTR lpDirectory;
	public int32 nShow;
	public HINSTANCE hInstApp;
	public void* lpIDList;
	public PSTR lpClass;
	public HKEY hkeyClass;
	public uint32 dwHotKey;
	public using _Anonymous_e__Union Anonymous;
	public HANDLE hProcess;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHELLEXECUTEINFOW
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public HANDLE hIcon;
		public HANDLE hMonitor;
	}
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PWSTR lpVerb;
	public PWSTR lpFile;
	public PWSTR lpParameters;
	public PWSTR lpDirectory;
	public int32 nShow;
	public HINSTANCE hInstApp;
	public void* lpIDList;
	public PWSTR lpClass;
	public HKEY hkeyClass;
	public uint32 dwHotKey;
	public using _Anonymous_e__Union Anonymous;
	public HANDLE hProcess;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHCREATEPROCESSINFOW
{
	public uint32 cbSize;
	public uint32 fMask;
	public HWND hwnd;
	public PWSTR pszFile;
	public PWSTR pszParameters;
	public PWSTR pszCurrentDirectory;
	public HANDLE hUserToken;
	public SECURITY_ATTRIBUTES* lpProcessAttributes;
	public SECURITY_ATTRIBUTES* lpThreadAttributes;
	public BOOL bInheritHandles;
	public uint32 dwCreationFlags;
	public STARTUPINFOW* lpStartupInfo;
	public PROCESS_INFORMATION* lpProcessInformation;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct ASSOCIATIONELEMENT
{
	public ASSOCCLASS ac;
	public HKEY hkClass;
	public PWSTR pszClass;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHQUERYRBINFO
{
	public uint32 cbSize;
	public int64 i64Size;
	public int64 i64NumItems;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct NOTIFYICONDATAA
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint32 uTimeout;
		public uint32 uVersion;
	}
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public NOTIFY_ICON_DATA_FLAGS uFlags;
	public uint32 uCallbackMessage;
	public HICON hIcon;
	public CHAR[128] szTip;
	public NOTIFY_ICON_STATE dwState;
	public uint32 dwStateMask;
	public CHAR[256] szInfo;
	public using _Anonymous_e__Union Anonymous;
	public CHAR[64] szInfoTitle;
	public NOTIFY_ICON_INFOTIP_FLAGS dwInfoFlags;
	public Guid guidItem;
	public HICON hBalloonIcon;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct NOTIFYICONDATAW
{
	[CRepr, Union, Packed(1)]
	public struct _Anonymous_e__Union
	{
		public uint32 uTimeout;
		public uint32 uVersion;
	}
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public NOTIFY_ICON_DATA_FLAGS uFlags;
	public uint32 uCallbackMessage;
	public HICON hIcon;
	public char16[128] szTip;
	public NOTIFY_ICON_STATE dwState;
	public uint32 dwStateMask;
	public char16[256] szInfo;
	public using _Anonymous_e__Union Anonymous;
	public char16[64] szInfoTitle;
	public NOTIFY_ICON_INFOTIP_FLAGS dwInfoFlags;
	public Guid guidItem;
	public HICON hBalloonIcon;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct NOTIFYICONIDENTIFIER
{
	public uint32 cbSize;
	public HWND hWnd;
	public uint32 uID;
	public Guid guidItem;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHFILEINFOA
{
	public HICON hIcon;
	public int32 iIcon;
	public uint32 dwAttributes;
	public CHAR[260] szDisplayName;
	public CHAR[80] szTypeName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHFILEINFOW
{
	public HICON hIcon;
	public int32 iIcon;
	public uint32 dwAttributes;
	public char16[260] szDisplayName;
	public char16[80] szTypeName;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct SHSTOCKICONINFO
{
	public uint32 cbSize;
	public HICON hIcon;
	public int32 iSysImageIndex;
	public int32 iIcon;
	public char16[260] szPath;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPEN_PRINTER_PROPS_INFOA
{
	public uint32 dwSize;
	public PSTR pszSheetName;
	public uint32 uSheetIndex;
	public uint32 dwFlags;
	public BOOL bModal;
}
#endif

#if BF_32_BIT
[CRepr, Packed(1)]
public struct OPEN_PRINTER_PROPS_INFOW
{
	public uint32 dwSize;
	public PWSTR pszSheetName;
	public uint32 uSheetIndex;
	public uint32 dwFlags;
	public BOOL bModal;
}
#endif

[CRepr]
public struct NC_ADDRESS
{
	[CRepr]
	public struct NET_ADDRESS_INFO
	{
	}
	public NET_ADDRESS_INFO* pAddrInfo;
	public uint16 PortNumber;
	public uint8 PrefixLength;
}

[CRepr]
public struct PARSEDURLA
{
	public uint32 cbSize;
	public PSTR pszProtocol;
	public uint32 cchProtocol;
	public PSTR pszSuffix;
	public uint32 cchSuffix;
	public uint32 nScheme;
}

[CRepr]
public struct PARSEDURLW
{
	public uint32 cbSize;
	public PWSTR pszProtocol;
	public uint32 cchProtocol;
	public PWSTR pszSuffix;
	public uint32 cchSuffix;
	public uint32 nScheme;
}

[CRepr]
public struct QITAB
{
	public Guid* piid;
	public uint32 dwOffset;
}

[CRepr]
public struct DLLVERSIONINFO
{
	public uint32 cbSize;
	public uint32 dwMajorVersion;
	public uint32 dwMinorVersion;
	public uint32 dwBuildNumber;
	public uint32 dwPlatformID;
}

[CRepr]
public struct DLLVERSIONINFO2
{
	public DLLVERSIONINFO info1;
	public uint32 dwFlags;
	public uint64 ullVersion;
}

[CRepr]
public struct APPINFODATA
{
	public uint32 cbSize;
	public uint32 dwMask;
	public PWSTR pszDisplayName;
	public PWSTR pszVersion;
	public PWSTR pszPublisher;
	public PWSTR pszProductID;
	public PWSTR pszRegisteredOwner;
	public PWSTR pszRegisteredCompany;
	public PWSTR pszLanguage;
	public PWSTR pszSupportUrl;
	public PWSTR pszSupportTelephone;
	public PWSTR pszHelpLink;
	public PWSTR pszInstallLocation;
	public PWSTR pszInstallSource;
	public PWSTR pszInstallDate;
	public PWSTR pszContact;
	public PWSTR pszComments;
	public PWSTR pszImage;
	public PWSTR pszReadmeUrl;
	public PWSTR pszUpdateInfoUrl;
}

[CRepr]
public struct SLOWAPPINFO
{
	public uint64 ullSize;
	public FILETIME ftLastUsed;
	public int32 iTimesUsed;
	public PWSTR pszImage;
}

[CRepr]
public struct PUBAPPINFO
{
	public uint32 cbSize;
	public uint32 dwMask;
	public PWSTR pszSource;
	public SYSTEMTIME stAssigned;
	public SYSTEMTIME stPublished;
	public SYSTEMTIME stScheduled;
	public SYSTEMTIME stExpire;
}

[CRepr]
public struct CREDENTIAL_PROVIDER_FIELD_DESCRIPTOR
{
	public uint32 dwFieldID;
	public CREDENTIAL_PROVIDER_FIELD_TYPE cpft;
	public PWSTR pszLabel;
	public Guid guidFieldType;
}

[CRepr]
public struct CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION
{
	public uint32 ulAuthenticationPackage;
	public Guid clsidCredentialProvider;
	public uint32 cbSerialization;
	public uint8* rgbSerialization;
}

[CRepr]
public struct SYNCMGR_CONFLICT_ID_INFO
{
	public BYTE_BLOB* pblobID;
	public BYTE_BLOB* pblobExtra;
}

[CRepr]
public struct CONFIRM_CONFLICT_ITEM
{
	public IShellItem2* pShellItem;
	public PWSTR pszOriginalName;
	public PWSTR pszAlternateName;
	public PWSTR pszLocationShort;
	public PWSTR pszLocationFull;
	public SYNCMGR_CONFLICT_ITEM_TYPE nType;
}

[CRepr]
public struct CONFIRM_CONFLICT_RESULT_INFO
{
	public PWSTR pszNewName;
	public uint32 iItemIndex;
}

[CRepr]
public struct WTS_THUMBNAILID
{
	public uint8[16] rgbKey;
}

[CRepr]
public struct SYNCMGRPROGRESSITEM
{
	public uint32 cbSize;
	public uint32 mask;
	public PWSTR lpcStatusText;
	public uint32 dwStatusType;
	public int32 iProgValue;
	public int32 iMaxValue;
}

[CRepr]
public struct SYNCMGRLOGERRORINFO
{
	public uint32 cbSize;
	public uint32 mask;
	public uint32 dwSyncMgrErrorFlags;
	public Guid ErrorID;
	public Guid ItemID;
}

[CRepr]
public struct SYNCMGRITEM
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public Guid ItemID;
	public uint32 dwItemState;
	public HICON hIcon;
	public char16[128] wszItemName;
	public FILETIME ftLastUpdate;
}

[CRepr]
public struct SYNCMGRHANDLERINFO
{
	public uint32 cbSize;
	public HICON hIcon;
	public uint32 SyncMgrHandlerFlags;
	public char16[32] wszHandlerName;
}

[CRepr]
public struct WINDOWDATA
{
	public uint32 dwWindowID;
	public uint32 uiCP;
	public ITEMIDLIST* pidl;
	public PWSTR lpszUrl;
	public PWSTR lpszUrlLocation;
	public PWSTR lpszTitle;
}

[CRepr]
public struct HLITEM
{
	public uint32 uHLID;
	public PWSTR pwzFriendlyName;
}

[CRepr]
public struct HLTBINFO
{
	public uint32 uDockType;
	public RECT rcTbPos;
}

[CRepr]
public struct HLBWINFO
{
	public uint32 cbSize;
	public uint32 grfHLBWIF;
	public RECT rcFramePos;
	public RECT rcDocPos;
	public HLTBINFO hltbinfo;
}

[CRepr]
public struct BASEBROWSERDATAXP
{
	public HWND _hwnd;
	public ITravelLog* _ptl;
	public IHlinkFrame* _phlf;
	public IWebBrowser2* _pautoWB2;
	public IExpDispSupportXP* _pautoEDS;
	public IShellService* _pautoSS;
	public int32 _eSecureLockIcon;
	public uint32 _bitfield;
	public uint32 _uActivateState;
	public ITEMIDLIST* _pidlViewState;
	public IOleCommandTarget* _pctView;
	public ITEMIDLIST* _pidlCur;
	public IShellView* _psv;
	public IShellFolder* _psf;
	public HWND _hwndView;
	public PWSTR _pszTitleCur;
	public ITEMIDLIST* _pidlPending;
	public IShellView* _psvPending;
	public IShellFolder* _psfPending;
	public HWND _hwndViewPending;
	public PWSTR _pszTitlePending;
	public BOOL _fIsViewMSHTML;
	public BOOL _fPrivacyImpacted;
	public Guid _clsidView;
	public Guid _clsidViewPending;
	public HWND _hwndFrame;
}

[CRepr]
public struct BASEBROWSERDATALH
{
	public HWND _hwnd;
	public ITravelLog* _ptl;
	public IHlinkFrame* _phlf;
	public IWebBrowser2* _pautoWB2;
	public IExpDispSupport* _pautoEDS;
	public IShellService* _pautoSS;
	public int32 _eSecureLockIcon;
	public uint32 _bitfield;
	public uint32 _uActivateState;
	public ITEMIDLIST* _pidlViewState;
	public IOleCommandTarget* _pctView;
	public ITEMIDLIST* _pidlCur;
	public IShellView* _psv;
	public IShellFolder* _psf;
	public HWND _hwndView;
	public PWSTR _pszTitleCur;
	public ITEMIDLIST* _pidlPending;
	public IShellView* _psvPending;
	public IShellFolder* _psfPending;
	public HWND _hwndViewPending;
	public PWSTR _pszTitlePending;
	public BOOL _fIsViewMSHTML;
	public BOOL _fPrivacyImpacted;
	public Guid _clsidView;
	public Guid _clsidViewPending;
	public HWND _hwndFrame;
	public int32 _lPhishingFilterStatus;
}

[CRepr]
public struct FOLDERSETDATA
{
	public FOLDERSETTINGS _fs;
	public Guid _vidRestore;
	public uint32 _dwViewPriority;
}

[CRepr]
public struct TOOLBARITEM
{
	public IDockingWindow* ptbar;
	public RECT rcBorderTool;
	public PWSTR pwszItem;
	public BOOL fShow;
	public HMONITOR hMon;
}

[CRepr, Packed(1)]
public struct CPLINFO
{
	public int32 idIcon;
	public int32 idName;
	public int32 idInfo;
	public int lData;
}

[CRepr, Packed(1)]
public struct NEWCPLINFOA
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwHelpContext;
	public int lData;
	public HICON hIcon;
	public CHAR[32] szName;
	public CHAR[64] szInfo;
	public CHAR[128] szHelpFile;
}

[CRepr, Packed(1)]
public struct NEWCPLINFOW
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public uint32 dwHelpContext;
	public int lData;
	public HICON hIcon;
	public char16[32] szName;
	public char16[64] szInfo;
	public char16[128] szHelpFile;
}

[CRepr]
public struct PROFILEINFOA
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PSTR lpUserName;
	public PSTR lpProfilePath;
	public PSTR lpDefaultPath;
	public PSTR lpServerName;
	public PSTR lpPolicyPath;
	public HANDLE hProfile;
}

[CRepr]
public struct PROFILEINFOW
{
	public uint32 dwSize;
	public uint32 dwFlags;
	public PWSTR lpUserName;
	public PWSTR lpProfilePath;
	public PWSTR lpDefaultPath;
	public PWSTR lpServerName;
	public PWSTR lpPolicyPath;
	public HANDLE hProfile;
}

[CRepr]
public struct URLINVOKECOMMANDINFOA
{
	public uint32 dwcbSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public PSTR pcszVerb;
}

[CRepr]
public struct URLINVOKECOMMANDINFOW
{
	public uint32 dwcbSize;
	public uint32 dwFlags;
	public HWND hwndParent;
	public PWSTR pcszVerb;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_QueryCancelAutoPlay = .(0x331f1768, 0x05a9, 0x4ddd, 0xb8, 0x6e, 0xda, 0xe3, 0x4d, 0xdc, 0x99, 0x8a);


	public const Guid CLSID_TimeCategorizer = .(0x3bb4118f, 0xddfd, 0x4d30, 0xa3, 0x48, 0x9f, 0xb5, 0xd6, 0xbf, 0x1a, 0xfe);


	public const Guid CLSID_AlphabeticalCategorizer = .(0x3c2654c6, 0x7372, 0x4f6b, 0xb3, 0x10, 0x55, 0xd6, 0x12, 0x8f, 0x49, 0xd2);


	public const Guid CLSID_MergedCategorizer = .(0x8e827c11, 0x33e7, 0x4bc1, 0xb2, 0x42, 0x8c, 0xd9, 0xa1, 0xc2, 0xb3, 0x04);


	public const Guid CLSID_ImageProperties = .(0x7ab770c7, 0x0e23, 0x4d7a, 0x8a, 0xa2, 0x19, 0xbf, 0xad, 0x47, 0x98, 0x29);


	public const Guid CLSID_CDBurn = .(0xfbeb8a05, 0xbeee, 0x4442, 0x80, 0x4e, 0x40, 0x9d, 0x6c, 0x45, 0x15, 0xe9);


	public const Guid CLSID_StartMenuPin = .(0xa2a9545d, 0xa0c2, 0x42b4, 0x97, 0x08, 0xa0, 0xb2, 0xba, 0xdd, 0x77, 0xc8);


	public const Guid CLSID_WebWizardHost = .(0xc827f149, 0x55c1, 0x4d28, 0x93, 0x5e, 0x57, 0xe4, 0x7c, 0xae, 0xd9, 0x73);


	public const Guid CLSID_PublishDropTarget = .(0xcc6eeffb, 0x43f6, 0x46c5, 0x96, 0x19, 0x51, 0xd5, 0x71, 0x96, 0x7f, 0x7d);


	public const Guid CLSID_PublishingWizard = .(0x6b33163c, 0x76a5, 0x4b6c, 0xbf, 0x21, 0x45, 0xde, 0x9c, 0xd5, 0x03, 0xa1);


	public const Guid CLSID_InternetPrintOrdering = .(0xadd36aa8, 0x751a, 0x4579, 0xa2, 0x66, 0xd6, 0x6f, 0x52, 0x02, 0xcc, 0xbb);


	public const Guid CLSID_FolderViewHost = .(0x20b1cb23, 0x6968, 0x4eb9, 0xb7, 0xd4, 0xa6, 0x6d, 0x00, 0xd0, 0x7c, 0xee);


	public const Guid CLSID_ExplorerBrowser = .(0x71f96385, 0xddd6, 0x48d3, 0xa0, 0xc1, 0xae, 0x06, 0xe8, 0xb0, 0x55, 0xfb);


	public const Guid CLSID_ImageRecompress = .(0x6e33091c, 0xd2f8, 0x4740, 0xb5, 0x5e, 0x2e, 0x11, 0xd1, 0x47, 0x7a, 0x2c);


	public const Guid CLSID_TrayBandSiteService = .(0xf60ad0a0, 0xe5e1, 0x45cb, 0xb5, 0x1a, 0xe1, 0x5b, 0x9f, 0x8b, 0x29, 0x34);


	public const Guid CLSID_TrayDeskBand = .(0xe6442437, 0x6c68, 0x4f52, 0x94, 0xdd, 0x2c, 0xfe, 0xd2, 0x67, 0xef, 0xb9);


	public const Guid CLSID_AttachmentServices = .(0x4125dd96, 0xe03a, 0x4103, 0x8f, 0x70, 0xe0, 0x59, 0x7d, 0x80, 0x3b, 0x9c);


	public const Guid CLSID_DocPropShellExtension = .(0x883373c3, 0xbf89, 0x11d1, 0xbe, 0x35, 0x08, 0x00, 0x36, 0xb1, 0x1a, 0x03);


	public const Guid CLSID_FSCopyHandler = .(0xd197380a, 0x0a79, 0x4dc8, 0xa0, 0x33, 0xed, 0x88, 0x2c, 0x2f, 0xa1, 0x4b);


	public const Guid CLSID_PreviousVersions = .(0x596ab062, 0xb4d2, 0x4215, 0x9f, 0x74, 0xe9, 0x10, 0x9b, 0x0a, 0x81, 0x53);


	public const Guid CLSID_NamespaceTreeControl = .(0xae054212, 0x3535, 0x4430, 0x83, 0xed, 0xd5, 0x01, 0xaa, 0x66, 0x80, 0xe6);


	public const Guid CLSID_IENamespaceTreeControl = .(0xace52d03, 0xe5cd, 0x4b20, 0x82, 0xff, 0xe7, 0x1b, 0x11, 0xbe, 0xae, 0x1d);


	public const Guid CLSID_ApplicationAssociationRegistrationUI = .(0x1968106d, 0xf3b5, 0x44cf, 0x89, 0x0e, 0x11, 0x6f, 0xcb, 0x9e, 0xce, 0xf1);


	public const Guid CLSID_DesktopGadget = .(0x924ccc1b, 0x6562, 0x4c85, 0x86, 0x57, 0xd1, 0x77, 0x92, 0x52, 0x22, 0xb6);


	public const Guid CLSID_AccessibilityDockingService = .(0x29ce1d46, 0xb481, 0x4aa0, 0xa0, 0x8a, 0xd3, 0xeb, 0xc8, 0xac, 0xa4, 0x02);


	public const Guid CLSID_ExecuteFolder = .(0x11dbb47c, 0xa525, 0x400b, 0x9e, 0x80, 0xa5, 0x46, 0x15, 0xa0, 0x90, 0xc0);


	public const Guid CLSID_VirtualDesktopManager = .(0xaa509086, 0x5ca9, 0x4c25, 0x8f, 0x95, 0x58, 0x9d, 0x3c, 0x07, 0xb4, 0x8a);


	public const Guid CLSID_StorageProviderBanners = .(0x7ccdf9f4, 0xe576, 0x455a, 0x8b, 0xc7, 0xf6, 0xec, 0x68, 0xd6, 0xf0, 0x63);


	public const Guid CLSID_DesktopWallpaper = .(0xc2cf3110, 0x460e, 0x4fc1, 0xb9, 0xd0, 0x8a, 0x1c, 0x0c, 0x9c, 0xc4, 0xbd);


	public const Guid CLSID_ShellDesktop = .(0x00021400, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);


	public const Guid CLSID_ShellFSFolder = .(0xf3364ba0, 0x65b9, 0x11ce, 0xa9, 0xba, 0x00, 0xaa, 0x00, 0x4a, 0xe8, 0x37);


	public const Guid CLSID_NetworkPlaces = .(0x208d2c60, 0x3aea, 0x1069, 0xa2, 0xd7, 0x08, 0x00, 0x2b, 0x30, 0x30, 0x9d);


	public const Guid CLSID_ShellLink = .(0x00021401, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);


	public const Guid CLSID_DriveSizeCategorizer = .(0x94357b53, 0xca29, 0x4b78, 0x83, 0xae, 0xe8, 0xfe, 0x74, 0x09, 0x13, 0x4f);


	public const Guid CLSID_DriveTypeCategorizer = .(0xb0a8f3cf, 0x4333, 0x4bab, 0x88, 0x73, 0x1c, 0xcb, 0x1c, 0xad, 0xa4, 0x8b);


	public const Guid CLSID_FreeSpaceCategorizer = .(0xb5607793, 0x24ac, 0x44c7, 0x82, 0xe2, 0x83, 0x17, 0x26, 0xaa, 0x6c, 0xb7);


	public const Guid CLSID_SizeCategorizer = .(0x55d7b852, 0xf6d1, 0x42f2, 0xaa, 0x75, 0x87, 0x28, 0xa1, 0xb2, 0xd2, 0x64);


	public const Guid CLSID_PropertiesUI = .(0xd912f8cf, 0x0396, 0x4915, 0x88, 0x4e, 0xfb, 0x42, 0x5d, 0x32, 0x94, 0x3b);


	public const Guid CLSID_UserNotification = .(0x0010890e, 0x8789, 0x413c, 0xad, 0xbc, 0x48, 0xf5, 0xb5, 0x11, 0xb3, 0xaf);


	public const Guid CLSID_TaskbarList = .(0x56fdf344, 0xfd6d, 0x11d0, 0x95, 0x8a, 0x00, 0x60, 0x97, 0xc9, 0xa0, 0x90);


	public const Guid CLSID_ShellItem = .(0x9ac9fbe1, 0xe0a2, 0x4ad6, 0xb4, 0xee, 0xe2, 0x12, 0x01, 0x3e, 0xa9, 0x17);


	public const Guid CLSID_NamespaceWalker = .(0x72eb61e0, 0x8672, 0x4303, 0x91, 0x75, 0xf2, 0xe4, 0xc6, 0x8b, 0x2e, 0x7c);


	public const Guid CLSID_FileOperation = .(0x3ad05575, 0x8857, 0x4850, 0x92, 0x77, 0x11, 0xb8, 0x5b, 0xdb, 0x8e, 0x09);


	public const Guid CLSID_FileOpenDialog = .(0xdc1c5a9c, 0xe88a, 0x4dde, 0xa5, 0xa1, 0x60, 0xf8, 0x2a, 0x20, 0xae, 0xf7);


	public const Guid CLSID_FileSaveDialog = .(0xc0b4e2f3, 0xba21, 0x4773, 0x8d, 0xba, 0x33, 0x5e, 0xc9, 0x46, 0xeb, 0x8b);


	public const Guid CLSID_KnownFolderManager = .(0x4df0c730, 0xdf9d, 0x4ae3, 0x91, 0x53, 0xaa, 0x6b, 0x82, 0xe9, 0x79, 0x5a);


	public const Guid CLSID_SharingConfigurationManager = .(0x49f371e1, 0x8c5c, 0x4d9c, 0x9a, 0x3b, 0x54, 0xa6, 0x82, 0x7f, 0x51, 0x3c);


	public const Guid CLSID_NetworkConnections = .(0x7007acc7, 0x3202, 0x11d1, 0xaa, 0xd2, 0x00, 0x80, 0x5f, 0xc1, 0x27, 0x0e);


	public const Guid CLSID_ScheduledTasks = .(0xd6277990, 0x4c6a, 0x11cf, 0x8d, 0x87, 0x00, 0xaa, 0x00, 0x60, 0xf5, 0xbf);


	public const Guid CLSID_ApplicationAssociationRegistration = .(0x591209c7, 0x767b, 0x42b2, 0x9f, 0xba, 0x44, 0xee, 0x46, 0x15, 0xf2, 0xc7);


	public const Guid CLSID_SearchFolderItemFactory = .(0x14010e02, 0xbbbd, 0x41f0, 0x88, 0xe3, 0xed, 0xa3, 0x71, 0x21, 0x65, 0x84);


	public const Guid CLSID_OpenControlPanel = .(0x06622d85, 0x6856, 0x4460, 0x8d, 0xe1, 0xa8, 0x19, 0x21, 0xb4, 0x1c, 0x4b);


	public const Guid CLSID_MailRecipient = .(0x9e56be60, 0xc50f, 0x11cf, 0x9a, 0x2c, 0x00, 0xa0, 0xc9, 0x0a, 0x90, 0xce);


	public const Guid CLSID_NetworkExplorerFolder = .(0xf02c1a0d, 0xbe21, 0x4350, 0x88, 0xb0, 0x73, 0x67, 0xfc, 0x96, 0xef, 0x3c);


	public const Guid CLSID_DestinationList = .(0x77f10cf0, 0x3db5, 0x4966, 0xb5, 0x20, 0xb7, 0xc5, 0x4f, 0xd3, 0x5e, 0xd6);


	public const Guid CLSID_ApplicationDestinations = .(0x86c14003, 0x4d6b, 0x4ef3, 0xa7, 0xb4, 0x05, 0x06, 0x66, 0x3b, 0x2e, 0x68);


	public const Guid CLSID_ApplicationDocumentLists = .(0x86bec222, 0x30f2, 0x47e0, 0x9f, 0x25, 0x60, 0xd1, 0x1c, 0xd7, 0x5c, 0x28);


	public const Guid CLSID_HomeGroup = .(0xde77ba04, 0x3c92, 0x4d11, 0xa1, 0xa5, 0x42, 0x35, 0x2a, 0x53, 0xe0, 0xe3);


	public const Guid CLSID_ShellLibrary = .(0xd9b3211d, 0xe57f, 0x4426, 0xaa, 0xef, 0x30, 0xa8, 0x06, 0xad, 0xd3, 0x97);


	public const Guid CLSID_AppStartupLink = .(0x273eb5e7, 0x88b0, 0x4843, 0xbf, 0xef, 0xe2, 0xc8, 0x1d, 0x43, 0xaa, 0xe5);


	public const Guid CLSID_EnumerableObjectCollection = .(0x2d3468c1, 0x36a7, 0x43b6, 0xac, 0x24, 0xd3, 0xf0, 0x2f, 0xd9, 0x60, 0x7a);


	public const Guid CLSID_FrameworkInputPane = .(0xd5120aa3, 0x46ba, 0x44c5, 0x82, 0x2d, 0xca, 0x80, 0x92, 0xc1, 0xfc, 0x72);


	public const Guid CLSID_DefFolderMenu = .(0xc63382be, 0x7933, 0x48d0, 0x9a, 0xc8, 0x85, 0xfb, 0x46, 0xbe, 0x2f, 0xdd);


	public const Guid CLSID_AppVisibility = .(0x7e5fe3d9, 0x985f, 0x4908, 0x91, 0xf9, 0xee, 0x19, 0xf9, 0xfd, 0x15, 0x14);


	public const Guid CLSID_AppShellVerbHandler = .(0x4ed3a719, 0xcea8, 0x4bd9, 0x91, 0x0d, 0xe2, 0x52, 0xf9, 0x97, 0xaf, 0xc2);


	public const Guid CLSID_ExecuteUnknown = .(0xe44e9428, 0xbdbc, 0x4987, 0xa0, 0x99, 0x40, 0xdc, 0x8f, 0xd2, 0x55, 0xe7);


	public const Guid CLSID_PackageDebugSettings = .(0xb1aec16f, 0x2383, 0x4852, 0xb0, 0xe9, 0x8f, 0x0b, 0x1d, 0xc6, 0x6b, 0x4d);


	public const Guid CLSID_SuspensionDependencyManager = .(0x6b273fc5, 0x61fd, 0x4918, 0x95, 0xa2, 0xc3, 0xb5, 0xe9, 0xd7, 0xf5, 0x81);


	public const Guid CLSID_ApplicationActivationManager = .(0x45ba127d, 0x10a8, 0x46ea, 0x8a, 0xb7, 0x56, 0xea, 0x90, 0x78, 0x94, 0x3c);


	public const Guid CLSID_ApplicationDesignModeSettings = .(0x958a6fb5, 0xdcb2, 0x4faf, 0xaa, 0xfd, 0x7f, 0xb0, 0x54, 0xad, 0x1a, 0x3b);


	public const Guid CLSID_WebBrowser_V1 = .(0xeab22ac3, 0x30c1, 0x11cf, 0xa7, 0xeb, 0x00, 0x00, 0xc0, 0x5b, 0xae, 0x0b);


	public const Guid CLSID_WebBrowser = .(0x8856f961, 0x340a, 0x11d0, 0xa9, 0x6b, 0x00, 0xc0, 0x4f, 0xd7, 0x05, 0xa2);


	public const Guid CLSID_InternetExplorer = .(0x0002df01, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);


	public const Guid CLSID_InternetExplorerMedium = .(0xd5e8041d, 0x920f, 0x45e9, 0xb8, 0xfb, 0xb1, 0xde, 0xb8, 0x2c, 0x6e, 0x5e);


	public const Guid CLSID_ShellBrowserWindow = .(0xc08afd90, 0xf2a1, 0x11d1, 0x84, 0x55, 0x00, 0xa0, 0xc9, 0x1f, 0x38, 0x80);


	public const Guid CLSID_ShellWindows = .(0x9ba05972, 0xf6a8, 0x11cf, 0xa4, 0x42, 0x00, 0xa0, 0xc9, 0x0a, 0x8f, 0x39);


	public const Guid CLSID_ShellUIHelper = .(0x64ab4bb7, 0x111e, 0x11d1, 0x8f, 0x79, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);


	public const Guid CLSID_ShellNameSpace = .(0x55136805, 0xb2de, 0x11d1, 0xb9, 0xf2, 0x00, 0xa0, 0xc9, 0x8b, 0xc5, 0x47);


	public const Guid CLSID_CScriptErrorList = .(0xefd01300, 0x160f, 0x11d2, 0xbb, 0x2e, 0x00, 0x80, 0x5f, 0xf7, 0xef, 0xca);


	public const Guid CLSID_ShellFolderViewOC = .(0x9ba05971, 0xf6a8, 0x11cf, 0xa4, 0x42, 0x00, 0xa0, 0xc9, 0x0a, 0x8f, 0x39);


	public const Guid CLSID_ShellFolderItem = .(0x2fe352ea, 0xfd1f, 0x11d2, 0xb1, 0xf4, 0x00, 0xc0, 0x4f, 0x8e, 0xeb, 0x3e);


	public const Guid CLSID_ShellLinkObject = .(0x11219420, 0x1768, 0x11d1, 0x95, 0xbe, 0x00, 0x60, 0x97, 0x97, 0xea, 0x4f);


	public const Guid CLSID_ShellFolderView = .(0x62112aa1, 0xebe4, 0x11cf, 0xa5, 0xfb, 0x00, 0x20, 0xaf, 0xe7, 0x29, 0x2d);


	public const Guid CLSID_Shell = .(0x13709620, 0xc279, 0x11ce, 0xa4, 0x9e, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);


	public const Guid CLSID_ShellDispatchInproc = .(0x0a89a860, 0xd7b1, 0x11ce, 0x83, 0x50, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);


	public const Guid CLSID_FileSearchBand = .(0xc4ee31f3, 0x4768, 0x11d2, 0xbe, 0x5c, 0x00, 0xa0, 0xc9, 0xa8, 0x3d, 0xa1);


	public const Guid CLSID_PasswordCredentialProvider = .(0x60b78e88, 0xead8, 0x445c, 0x9c, 0xfd, 0x0b, 0x87, 0xf7, 0x4e, 0xa6, 0xcd);


	public const Guid CLSID_V1PasswordCredentialProvider = .(0x6f45dc1e, 0x5384, 0x457a, 0xbc, 0x13, 0x2c, 0xd8, 0x1b, 0x0d, 0x28, 0xed);


	public const Guid CLSID_PINLogonCredentialProvider = .(0xcb82ea12, 0x9f71, 0x446d, 0x89, 0xe1, 0x8d, 0x09, 0x24, 0xe1, 0x25, 0x6e);


	public const Guid CLSID_NPCredentialProvider = .(0x3dd6bec0, 0x8193, 0x4ffe, 0xae, 0x25, 0xe0, 0x8e, 0x39, 0xea, 0x40, 0x63);


	public const Guid CLSID_SmartcardCredentialProvider = .(0x8fd7e19c, 0x3bf7, 0x489b, 0xa7, 0x2c, 0x84, 0x6a, 0xb3, 0x67, 0x8c, 0x96);


	public const Guid CLSID_V1SmartcardCredentialProvider = .(0x8bf9a910, 0xa8ff, 0x457f, 0x99, 0x9f, 0xa5, 0xca, 0x10, 0xb4, 0xa8, 0x85);


	public const Guid CLSID_SmartcardPinProvider = .(0x94596c7e, 0x3744, 0x41ce, 0x89, 0x3e, 0xbb, 0xf0, 0x91, 0x22, 0xf7, 0x6a);


	public const Guid CLSID_SmartcardReaderSelectionProvider = .(0x1b283861, 0x754f, 0x4022, 0xad, 0x47, 0xa5, 0xea, 0xaa, 0x61, 0x88, 0x94);


	public const Guid CLSID_SmartcardWinRTProvider = .(0x1ee7337f, 0x85ac, 0x45e2, 0xa2, 0x3c, 0x37, 0xc7, 0x53, 0x20, 0x97, 0x69);


	public const Guid CLSID_GenericCredentialProvider = .(0x25cbb996, 0x92ed, 0x457e, 0xb2, 0x8c, 0x47, 0x74, 0x08, 0x4b, 0xd5, 0x62);


	public const Guid CLSID_RASProvider = .(0x5537e283, 0xb1e7, 0x4ef8, 0x9c, 0x6e, 0x7a, 0xb0, 0xaf, 0xe5, 0x05, 0x6d);


	public const Guid CLSID_OnexCredentialProvider = .(0x07aa0886, 0xcc8d, 0x4e19, 0xa4, 0x10, 0x1c, 0x75, 0xaf, 0x68, 0x6e, 0x62);


	public const Guid CLSID_OnexPlapSmartcardCredentialProvider = .(0x33c86cd6, 0x705f, 0x4ba1, 0x9a, 0xdb, 0x67, 0x07, 0x0b, 0x83, 0x77, 0x75);


	public const Guid CLSID_VaultProvider = .(0x503739d0, 0x4c5e, 0x4cfd, 0xb3, 0xba, 0xd8, 0x81, 0x33, 0x4f, 0x0d, 0xf2);


	public const Guid CLSID_WinBioCredentialProvider = .(0xbec09223, 0xb018, 0x416d, 0xa0, 0xac, 0x52, 0x39, 0x71, 0xb6, 0x39, 0xf5);


	public const Guid CLSID_V1WinBioCredentialProvider = .(0xac3ac249, 0xe820, 0x4343, 0xa6, 0x5b, 0x37, 0x7a, 0xc6, 0x34, 0xdc, 0x09);


	public const Guid CLSID_SyncMgrClient = .(0x1202db60, 0x1dac, 0x42c5, 0xae, 0xd5, 0x1a, 0xbd, 0xd4, 0x32, 0x24, 0x8e);


	public const Guid CLSID_SyncMgrControl = .(0x1a1f4206, 0x0688, 0x4e7f, 0xbe, 0x03, 0xd8, 0x2e, 0xc6, 0x9d, 0xf9, 0xa5);


	public const Guid CLSID_SyncMgrScheduleWizard = .(0x8d8b8e30, 0xc451, 0x421b, 0x85, 0x53, 0xd2, 0x97, 0x6a, 0xfa, 0x64, 0x8c);


	public const Guid CLSID_SyncMgrFolder = .(0x9c73f5e5, 0x7ae7, 0x4e32, 0xa8, 0xe8, 0x8d, 0x23, 0xb8, 0x52, 0x55, 0xbf);


	public const Guid CLSID_SyncSetupFolder = .(0x2e9e59c0, 0xb437, 0x4981, 0xa6, 0x47, 0x9c, 0x34, 0xb9, 0xb9, 0x08, 0x91);


	public const Guid CLSID_ConflictFolder = .(0x289978ac, 0xa101, 0x4341, 0xa8, 0x17, 0x21, 0xeb, 0xa7, 0xfd, 0x04, 0x6d);


	public const Guid CLSID_SyncResultsFolder = .(0x71d99464, 0x3b6b, 0x475c, 0xb2, 0x41, 0xe1, 0x58, 0x83, 0x20, 0x75, 0x29);


	public const Guid CLSID_SimpleConflictPresenter = .(0x7a0f6ab7, 0xed84, 0x46b6, 0xb4, 0x7e, 0x02, 0xaa, 0x15, 0x9a, 0x15, 0x2b);


	public const Guid CLSID_InputPanelConfiguration = .(0x2853add3, 0xf096, 0x4c63, 0xa7, 0x8f, 0x7f, 0xa3, 0xea, 0x83, 0x7f, 0xb7);


	public const Guid CLSID_LocalThumbnailCache = .(0x50ef4544, 0xac9f, 0x4a8e, 0xb2, 0x1b, 0x8a, 0x26, 0x18, 0x0d, 0xb1, 0x3f);


	public const Guid CLSID_SharedBitmap = .(0x4db26476, 0x6787, 0x4046, 0xb8, 0x36, 0xe8, 0x41, 0x2a, 0x9e, 0x8a, 0x27);


	public const Guid CLSID_ShellImageDataFactory = .(0x66e4e4fb, 0xf385, 0x4dd0, 0x8d, 0x74, 0xa2, 0xef, 0xd1, 0xbc, 0x61, 0x78);


	public const Guid CLSID_SyncMgr = .(0x6295df27, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);


	public const Guid CLSID_ThumbnailStreamCache = .(0xcbe0fed3, 0x4b91, 0x4e90, 0x83, 0x54, 0x8a, 0x8c, 0x84, 0xec, 0x68, 0x72);


	public const Guid CLSID_TrackShellMenu = .(0x8278f931, 0x2a3e, 0x11d2, 0x83, 0x8f, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);


	public const Guid CLSID_ImageTranscode = .(0x17b75166, 0x928f, 0x417d, 0x96, 0x85, 0x64, 0xaa, 0x13, 0x55, 0x65, 0xc1);


	public const Guid CLSID_ShowInputPaneAnimationCoordinator = .(0x1f046abf, 0x3202, 0x4dc1, 0x8c, 0xb5, 0x3c, 0x67, 0x61, 0x7c, 0xe1, 0xfa);


	public const Guid CLSID_HideInputPaneAnimationCoordinator = .(0x384742b1, 0x2a77, 0x4cb3, 0x8c, 0xf8, 0x11, 0x36, 0xf5, 0xe1, 0x7e, 0x59);


}
#endregion

#region COM Types
[CRepr]struct INotifyReplica : IUnknown
{
	public new const Guid IID = .(0x99180163, 0xda16, 0x101a, 0x93, 0x5c, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ulcOtherReplicas, IMoniker** rgpmkOtherReplicas) YouAreAReplica;
	}


	public HRESULT YouAreAReplica(uint32 ulcOtherReplicas, IMoniker** rgpmkOtherReplicas) mut => VT.[Friend]YouAreAReplica(&this, ulcOtherReplicas, rgpmkOtherReplicas);
}

[CRepr]struct IContextMenu : IUnknown
{
	public new const Guid IID = .(0x000214e4, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, uint32 indexMenu, uint32 idCmdFirst, uint32 idCmdLast, uint32 uFlags) QueryContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CMINVOKECOMMANDINFO* pici) InvokeCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint idCmd, uint32 uType, uint32* pReserved, PSTR pszName, uint32 cchMax) GetCommandString;
	}


	public HRESULT QueryContextMenu(HMENU hmenu, uint32 indexMenu, uint32 idCmdFirst, uint32 idCmdLast, uint32 uFlags) mut => VT.[Friend]QueryContextMenu(&this, hmenu, indexMenu, idCmdFirst, idCmdLast, uFlags);

	public HRESULT InvokeCommand(CMINVOKECOMMANDINFO* pici) mut => VT.[Friend]InvokeCommand(&this, pici);

	public HRESULT GetCommandString(uint idCmd, uint32 uType, uint32* pReserved, PSTR pszName, uint32 cchMax) mut => VT.[Friend]GetCommandString(&this, idCmd, uType, pReserved, pszName, cchMax);
}

[CRepr]struct IContextMenu2 : IContextMenu
{
	public new const Guid IID = .(0x000214f4, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IContextMenu.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMsg, WPARAM wParam, LPARAM lParam) HandleMenuMsg;
	}


	public HRESULT HandleMenuMsg(uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]HandleMenuMsg(&this, uMsg, wParam, lParam);
}

[CRepr]struct IContextMenu3 : IContextMenu2
{
	public new const Guid IID = .(0xbcfce0a0, 0xec17, 0x11d0, 0x8d, 0x10, 0x00, 0xa0, 0xc9, 0x0f, 0x27, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IContextMenu2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) HandleMenuMsg2;
	}


	public HRESULT HandleMenuMsg2(uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* plResult) mut => VT.[Friend]HandleMenuMsg2(&this, uMsg, wParam, lParam, plResult);
}

[CRepr]struct IExecuteCommand : IUnknown
{
	public new const Guid IID = .(0x7f9185b0, 0xcb92, 0x43c5, 0x80, 0xa9, 0x92, 0x27, 0x7a, 0x4f, 0x7b, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfKeyState) SetKeyState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszParameters) SetParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT pt) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nShow) SetShowWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoShowUI) SetNoShowUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDirectory) SetDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Execute;
	}


	public HRESULT SetKeyState(uint32 grfKeyState) mut => VT.[Friend]SetKeyState(&this, grfKeyState);

	public HRESULT SetParameters(PWSTR pszParameters) mut => VT.[Friend]SetParameters(&this, pszParameters);

	public HRESULT SetPosition(POINT pt) mut => VT.[Friend]SetPosition(&this, pt);

	public HRESULT SetShowWindow(int32 nShow) mut => VT.[Friend]SetShowWindow(&this, nShow);

	public HRESULT SetNoShowUI(BOOL fNoShowUI) mut => VT.[Friend]SetNoShowUI(&this, fNoShowUI);

	public HRESULT SetDirectory(PWSTR pszDirectory) mut => VT.[Friend]SetDirectory(&this, pszDirectory);

	public HRESULT Execute() mut => VT.[Friend]Execute(&this);
}

[CRepr]struct IPersistFolder : IPersist
{
	public new const Guid IID = .(0x000214ea, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) Initialize;
	}


	public HRESULT Initialize(ITEMIDLIST* pidl) mut => VT.[Friend]Initialize(&this, pidl);
}

[CRepr]struct IRunnableTask : IUnknown
{
	public new const Guid IID = .(0x85788d00, 0x6807, 0x11d0, 0xb8, 0x10, 0x00, 0xc0, 0x4f, 0xd7, 0x06, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Run;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bWait) Kill;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Resume;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) IsRunning;
	}


	public HRESULT Run() mut => VT.[Friend]Run(&this);

	public HRESULT Kill(BOOL bWait) mut => VT.[Friend]Kill(&this, bWait);

	public HRESULT Suspend() mut => VT.[Friend]Suspend(&this);

	public HRESULT Resume() mut => VT.[Friend]Resume(&this);

	public uint32 IsRunning() mut => VT.[Friend]IsRunning(&this);
}

[CRepr]struct IShellTaskScheduler : IUnknown
{
	public new const Guid IID = .(0x6ccb7be0, 0x6807, 0x11d0, 0xb8, 0x10, 0x00, 0xc0, 0x4f, 0xd7, 0x06, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IRunnableTask* prt, in Guid rtoid, uint lParam, uint32 dwPriority) AddTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rtoid, uint lParam, BOOL bWaitIfRunning) RemoveTasks;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, in Guid rtoid) CountTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReleaseStatus, uint32 dwThreadTimeout) Status;
	}


	public HRESULT AddTask(IRunnableTask* prt, in Guid rtoid, uint lParam, uint32 dwPriority) mut => VT.[Friend]AddTask(&this, prt, rtoid, lParam, dwPriority);

	public HRESULT RemoveTasks(in Guid rtoid, uint lParam, BOOL bWaitIfRunning) mut => VT.[Friend]RemoveTasks(&this, rtoid, lParam, bWaitIfRunning);

	public uint32 CountTasks(in Guid rtoid) mut => VT.[Friend]CountTasks(&this, rtoid);

	public HRESULT Status(uint32 dwReleaseStatus, uint32 dwThreadTimeout) mut => VT.[Friend]Status(&this, dwReleaseStatus, dwThreadTimeout);
}

[CRepr]struct IPersistFolder2 : IPersistFolder
{
	public new const Guid IID = .(0x1ac3d9f0, 0x175c, 0x11d1, 0x95, 0xbe, 0x00, 0x60, 0x97, 0x97, 0xea, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistFolder.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetCurFolder;
	}


	public HRESULT GetCurFolder(ITEMIDLIST** ppidl) mut => VT.[Friend]GetCurFolder(&this, ppidl);
}

[CRepr]struct IPersistFolder3 : IPersistFolder2
{
	public new const Guid IID = .(0xcef04fdf, 0xfe72, 0x11d2, 0x87, 0xa5, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersistFolder2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, ITEMIDLIST* pidlRoot, PERSIST_FOLDER_TARGET_INFO* ppfti) InitializeEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PERSIST_FOLDER_TARGET_INFO* ppfti) GetFolderTargetInfo;
	}


	public HRESULT InitializeEx(IBindCtx* pbc, ITEMIDLIST* pidlRoot, PERSIST_FOLDER_TARGET_INFO* ppfti) mut => VT.[Friend]InitializeEx(&this, pbc, pidlRoot, ppfti);

	public HRESULT GetFolderTargetInfo(PERSIST_FOLDER_TARGET_INFO* ppfti) mut => VT.[Friend]GetFolderTargetInfo(&this, ppfti);
}

[CRepr]struct IPersistIDList : IPersist
{
	public new const Guid IID = .(0x1079acfc, 0x29bd, 0x11d3, 0x8e, 0x0d, 0x00, 0xc0, 0x4f, 0x68, 0x37, 0xd5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPersist.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) SetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetIDList;
	}


	public HRESULT SetIDList(ITEMIDLIST* pidl) mut => VT.[Friend]SetIDList(&this, pidl);

	public HRESULT GetIDList(ITEMIDLIST** ppidl) mut => VT.[Friend]GetIDList(&this, ppidl);
}

[CRepr]struct IEnumIDList : IUnknown
{
	public new const Guid IID = .(0x000214f2, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ITEMIDLIST** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumIDList** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ITEMIDLIST** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumIDList** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IEnumFullIDList : IUnknown
{
	public new const Guid IID = .(0xd0191542, 0x7954, 0x4908, 0xbc, 0x06, 0xb2, 0x36, 0x0b, 0xbe, 0x45, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ITEMIDLIST** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumFullIDList** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ITEMIDLIST** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumFullIDList** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IFileSyncMergeHandler : IUnknown
{
	public new const Guid IID = .(0xd97b5aac, 0xc792, 0x433c, 0x97, 0x5d, 0x35, 0xc4, 0xea, 0xdc, 0x7a, 0x9d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR localFilePath, PWSTR serverFilePath, MERGE_UPDATE_STATUS* updateStatus) Merge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR localFilePath, HMONITOR monitorToDisplayOn) ShowResolveConflictUIAsync;
	}


	public HRESULT Merge(PWSTR localFilePath, PWSTR serverFilePath, MERGE_UPDATE_STATUS* updateStatus) mut => VT.[Friend]Merge(&this, localFilePath, serverFilePath, updateStatus);

	public HRESULT ShowResolveConflictUIAsync(PWSTR localFilePath, HMONITOR monitorToDisplayOn) mut => VT.[Friend]ShowResolveConflictUIAsync(&this, localFilePath, monitorToDisplayOn);
}

[CRepr]struct IObjectWithFolderEnumMode : IUnknown
{
	public new const Guid IID = .(0x6a9d9026, 0x0e6e, 0x464c, 0xb0, 0x00, 0x42, 0xec, 0xc0, 0x7d, 0xe6, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDER_ENUM_MODE feMode) SetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDER_ENUM_MODE* pfeMode) GetMode;
	}


	public HRESULT SetMode(FOLDER_ENUM_MODE feMode) mut => VT.[Friend]SetMode(&this, feMode);

	public HRESULT GetMode(FOLDER_ENUM_MODE* pfeMode) mut => VT.[Friend]GetMode(&this, pfeMode);
}

[CRepr]struct IParseAndCreateItem : IUnknown
{
	public new const Guid IID = .(0x67efed0e, 0xe827, 0x4408, 0xb4, 0x93, 0x78, 0xf3, 0x98, 0x2b, 0x68, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) SetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetItem;
	}


	public HRESULT SetItem(IShellItem* psi) mut => VT.[Friend]SetItem(&this, psi);

	public HRESULT GetItem(in Guid riid, void** ppv) mut => VT.[Friend]GetItem(&this, riid, ppv);
}

[CRepr]struct IShellFolder : IUnknown
{
	public new const Guid IID = .(0x000214e6, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IBindCtx* pbc, PWSTR pszDisplayName, uint32* pchEaten, ITEMIDLIST** ppidl, uint32* pdwAttributes) ParseDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 grfFlags, IEnumIDList** ppenumIDList) EnumObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, IBindCtx* pbc, in Guid riid, void** ppv) BindToObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, IBindCtx* pbc, in Guid riid, void** ppv) BindToStorage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM lParam, ITEMIDLIST* pidl1, ITEMIDLIST* pidl2) CompareIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner, in Guid riid, void** ppv) CreateViewObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cidl, ITEMIDLIST** apidl, uint32* rgfInOut) GetAttributesOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner, uint32 cidl, ITEMIDLIST** apidl, in Guid riid, uint32* rgfReserved, void** ppv) GetUIObjectOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, SHGDNF uFlags, STRRET* pName) GetDisplayNameOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, ITEMIDLIST* pidl, PWSTR pszName, SHGDNF uFlags, ITEMIDLIST** ppidlOut) SetNameOf;
	}


	public HRESULT ParseDisplayName(HWND hwnd, IBindCtx* pbc, PWSTR pszDisplayName, uint32* pchEaten, ITEMIDLIST** ppidl, uint32* pdwAttributes) mut => VT.[Friend]ParseDisplayName(&this, hwnd, pbc, pszDisplayName, pchEaten, ppidl, pdwAttributes);

	public HRESULT EnumObjects(HWND hwnd, uint32 grfFlags, IEnumIDList** ppenumIDList) mut => VT.[Friend]EnumObjects(&this, hwnd, grfFlags, ppenumIDList);

	public HRESULT BindToObject(ITEMIDLIST* pidl, IBindCtx* pbc, in Guid riid, void** ppv) mut => VT.[Friend]BindToObject(&this, pidl, pbc, riid, ppv);

	public HRESULT BindToStorage(ITEMIDLIST* pidl, IBindCtx* pbc, in Guid riid, void** ppv) mut => VT.[Friend]BindToStorage(&this, pidl, pbc, riid, ppv);

	public HRESULT CompareIDs(LPARAM lParam, ITEMIDLIST* pidl1, ITEMIDLIST* pidl2) mut => VT.[Friend]CompareIDs(&this, lParam, pidl1, pidl2);

	public HRESULT CreateViewObject(HWND hwndOwner, in Guid riid, void** ppv) mut => VT.[Friend]CreateViewObject(&this, hwndOwner, riid, ppv);

	public HRESULT GetAttributesOf(uint32 cidl, ITEMIDLIST** apidl, uint32* rgfInOut) mut => VT.[Friend]GetAttributesOf(&this, cidl, apidl, rgfInOut);

	public HRESULT GetUIObjectOf(HWND hwndOwner, uint32 cidl, ITEMIDLIST** apidl, in Guid riid, uint32* rgfReserved, void** ppv) mut => VT.[Friend]GetUIObjectOf(&this, hwndOwner, cidl, apidl, riid, rgfReserved, ppv);

	public HRESULT GetDisplayNameOf(ITEMIDLIST* pidl, SHGDNF uFlags, STRRET* pName) mut => VT.[Friend]GetDisplayNameOf(&this, pidl, uFlags, pName);

	public HRESULT SetNameOf(HWND hwnd, ITEMIDLIST* pidl, PWSTR pszName, SHGDNF uFlags, ITEMIDLIST** ppidlOut) mut => VT.[Friend]SetNameOf(&this, hwnd, pidl, pszName, uFlags, ppidlOut);
}

[CRepr]struct IEnumExtraSearch : IUnknown
{
	public new const Guid IID = .(0x0e700be1, 0x9db6, 0x11d1, 0xa1, 0xce, 0x00, 0xc0, 0x4f, 0xd7, 0x5d, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, EXTRASEARCH* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumExtraSearch** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, EXTRASEARCH* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumExtraSearch** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IShellFolder2 : IShellFolder
{
	public new const Guid IID = .(0x93f2f68c, 0x1d1b, 0x11d3, 0xa3, 0x0e, 0x00, 0xc0, 0x4f, 0x79, 0xab, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellFolder.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid) GetDefaultSearchGUID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumExtraSearch** ppenum) EnumSearches;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRes, uint32* pSort, uint32* pDisplay) GetDefaultColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iColumn, uint32* pcsFlags) GetDefaultColumnState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PROPERTYKEY* pscid, VARIANT* pv) GetDetailsEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 iColumn, SHELLDETAILS* psd) GetDetailsOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iColumn, PROPERTYKEY* pscid) MapColumnToSCID;
	}


	public HRESULT GetDefaultSearchGUID(Guid* pguid) mut => VT.[Friend]GetDefaultSearchGUID(&this, pguid);

	public HRESULT EnumSearches(IEnumExtraSearch** ppenum) mut => VT.[Friend]EnumSearches(&this, ppenum);

	public HRESULT GetDefaultColumn(uint32 dwRes, uint32* pSort, uint32* pDisplay) mut => VT.[Friend]GetDefaultColumn(&this, dwRes, pSort, pDisplay);

	public HRESULT GetDefaultColumnState(uint32 iColumn, uint32* pcsFlags) mut => VT.[Friend]GetDefaultColumnState(&this, iColumn, pcsFlags);

	public HRESULT GetDetailsEx(ITEMIDLIST* pidl, PROPERTYKEY* pscid, VARIANT* pv) mut => VT.[Friend]GetDetailsEx(&this, pidl, pscid, pv);

	public HRESULT GetDetailsOf(ITEMIDLIST* pidl, uint32 iColumn, SHELLDETAILS* psd) mut => VT.[Friend]GetDetailsOf(&this, pidl, iColumn, psd);

	public HRESULT MapColumnToSCID(uint32 iColumn, PROPERTYKEY* pscid) mut => VT.[Friend]MapColumnToSCID(&this, iColumn, pscid);
}

[CRepr]struct IShellView : IOleWindow
{
	public new const Guid IID = .(0x000214e3, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg) TranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) EnableModeless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uState) UIActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psvPrevious, FOLDERSETTINGS* pfs, IShellBrowser* psb, RECT* prcView, HWND* phWnd) CreateViewWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DestroyViewWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERSETTINGS* pfs) GetCurrentInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, LPFNSVADDPROPSHEETPAGE pfn, LPARAM lparam) AddPropertySheetPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveViewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlItem, uint32 uFlags) SelectItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uItem, in Guid riid, void** ppv) GetItemObject;
	}


	public HRESULT TranslateAccelerator(MSG* pmsg) mut => VT.[Friend]TranslateAccelerator(&this, pmsg);

	public HRESULT EnableModeless(BOOL fEnable) mut => VT.[Friend]EnableModeless(&this, fEnable);

	public HRESULT UIActivate(uint32 uState) mut => VT.[Friend]UIActivate(&this, uState);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT CreateViewWindow(IShellView* psvPrevious, FOLDERSETTINGS* pfs, IShellBrowser* psb, RECT* prcView, HWND* phWnd) mut => VT.[Friend]CreateViewWindow(&this, psvPrevious, pfs, psb, prcView, phWnd);

	public HRESULT DestroyViewWindow() mut => VT.[Friend]DestroyViewWindow(&this);

	public HRESULT GetCurrentInfo(FOLDERSETTINGS* pfs) mut => VT.[Friend]GetCurrentInfo(&this, pfs);

	public HRESULT AddPropertySheetPages(uint32 dwReserved, LPFNSVADDPROPSHEETPAGE pfn, LPARAM lparam) mut => VT.[Friend]AddPropertySheetPages(&this, dwReserved, pfn, lparam);

	public HRESULT SaveViewState() mut => VT.[Friend]SaveViewState(&this);

	public HRESULT SelectItem(ITEMIDLIST* pidlItem, uint32 uFlags) mut => VT.[Friend]SelectItem(&this, pidlItem, uFlags);

	public HRESULT GetItemObject(uint32 uItem, in Guid riid, void** ppv) mut => VT.[Friend]GetItemObject(&this, uItem, riid, ppv);
}

[CRepr]struct IShellView2 : IShellView
{
	public new const Guid IID = .(0x88e39e80, 0x3578, 0x11cf, 0xae, 0x69, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellView.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pvid, uint32 uView) GetView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SV2CVW2_PARAMS* lpParams) CreateViewWindow2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlNew) HandleRename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlItem, uint32 uFlags, POINT* ppt) SelectAndPositionItem;
	}


	public HRESULT GetView(Guid* pvid, uint32 uView) mut => VT.[Friend]GetView(&this, pvid, uView);

	public HRESULT CreateViewWindow2(SV2CVW2_PARAMS* lpParams) mut => VT.[Friend]CreateViewWindow2(&this, lpParams);

	public HRESULT HandleRename(ITEMIDLIST* pidlNew) mut => VT.[Friend]HandleRename(&this, pidlNew);

	public HRESULT SelectAndPositionItem(ITEMIDLIST* pidlItem, uint32 uFlags, POINT* ppt) mut => VT.[Friend]SelectAndPositionItem(&this, pidlItem, uFlags, ppt);
}

[CRepr]struct IFolderView : IUnknown
{
	public new const Guid IID = .(0xcde725b0, 0xccc9, 0x4519, 0x91, 0x7e, 0x32, 0x5d, 0x72, 0xfa, 0xb4, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pViewMode) GetCurrentViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ViewMode) SetCurrentViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iItemIndex, ITEMIDLIST** ppidl) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFlags, int32* pcItems) ItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFlags, in Guid riid, void** ppv) Items;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piItem) GetSelectionMarkedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piItem) GetFocusedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, POINT* ppt) GetItemPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt) GetSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt) GetDefaultSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetAutoArrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iItem, uint32 dwFlags) SelectItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cidl, ITEMIDLIST** apidl, POINT* apt, uint32 dwFlags) SelectAndPositionItems;
	}


	public HRESULT GetCurrentViewMode(uint32* pViewMode) mut => VT.[Friend]GetCurrentViewMode(&this, pViewMode);

	public HRESULT SetCurrentViewMode(uint32 ViewMode) mut => VT.[Friend]SetCurrentViewMode(&this, ViewMode);

	public HRESULT GetFolder(in Guid riid, void** ppv) mut => VT.[Friend]GetFolder(&this, riid, ppv);

	public HRESULT Item(int32 iItemIndex, ITEMIDLIST** ppidl) mut => VT.[Friend]Item(&this, iItemIndex, ppidl);

	public HRESULT ItemCount(uint32 uFlags, int32* pcItems) mut => VT.[Friend]ItemCount(&this, uFlags, pcItems);

	public HRESULT Items(uint32 uFlags, in Guid riid, void** ppv) mut => VT.[Friend]Items(&this, uFlags, riid, ppv);

	public HRESULT GetSelectionMarkedItem(int32* piItem) mut => VT.[Friend]GetSelectionMarkedItem(&this, piItem);

	public HRESULT GetFocusedItem(int32* piItem) mut => VT.[Friend]GetFocusedItem(&this, piItem);

	public HRESULT GetItemPosition(ITEMIDLIST* pidl, POINT* ppt) mut => VT.[Friend]GetItemPosition(&this, pidl, ppt);

	public HRESULT GetSpacing(POINT* ppt) mut => VT.[Friend]GetSpacing(&this, ppt);

	public HRESULT GetDefaultSpacing(POINT* ppt) mut => VT.[Friend]GetDefaultSpacing(&this, ppt);

	public HRESULT GetAutoArrange() mut => VT.[Friend]GetAutoArrange(&this);

	public HRESULT SelectItem(int32 iItem, uint32 dwFlags) mut => VT.[Friend]SelectItem(&this, iItem, dwFlags);

	public HRESULT SelectAndPositionItems(uint32 cidl, ITEMIDLIST** apidl, POINT* apt, uint32 dwFlags) mut => VT.[Friend]SelectAndPositionItems(&this, cidl, apidl, apt, dwFlags);
}

[CRepr]struct IFolderView2 : IFolderView
{
	public new const Guid IID = .(0x1af3a467, 0x214f, 0x4298, 0x90, 0x8e, 0x06, 0xb0, 0x3e, 0x0b, 0x39, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFolderView.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, BOOL fAscending) SetGroupBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pkey, BOOL* pfAscending) GetGroupBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PROPERTYKEY* propkey, PROPVARIANT* propvar) SetViewProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PROPERTYKEY* propkey, PROPVARIANT* ppropvar) GetViewProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PWSTR pszPropList) SetTileViewProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PWSTR pszPropList) SetExtendedTileViewProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FVTEXTTYPE iType, PWSTR pwszText) SetText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask, uint32 dwFlags) SetCurrentFolderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetCurrentFolderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcColumns) GetSortColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SORTCOLUMN* rgSortColumns, int32 cColumns) SetSortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SORTCOLUMN* rgSortColumns, int32 cColumns) GetSortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iItem, in Guid riid, void** ppv) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iStart, BOOL fPrevious, int32* piItem) GetVisibleItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iStart, int32* piItem) GetSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoneImpliesFolder, IShellItemArray** ppsia) GetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32* pdwFlags) GetSelectionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszVerb) InvokeVerbOnSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERVIEWMODE uViewMode, int32 iImageSize) SetViewModeAndIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERVIEWMODE* puViewMode, int32* piImageSize) GetViewModeAndIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cVisibleRows) SetGroupSubsetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcVisibleRows) GetGroupSubsetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fRedrawOn) SetRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsMoveInSameFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DoRename;
	}


	public HRESULT SetGroupBy(PROPERTYKEY* key, BOOL fAscending) mut => VT.[Friend]SetGroupBy(&this, key, fAscending);

	public HRESULT GetGroupBy(PROPERTYKEY* pkey, BOOL* pfAscending) mut => VT.[Friend]GetGroupBy(&this, pkey, pfAscending);

	public HRESULT SetViewProperty(ITEMIDLIST* pidl, PROPERTYKEY* propkey, PROPVARIANT* propvar) mut => VT.[Friend]SetViewProperty(&this, pidl, propkey, propvar);

	public HRESULT GetViewProperty(ITEMIDLIST* pidl, PROPERTYKEY* propkey, PROPVARIANT* ppropvar) mut => VT.[Friend]GetViewProperty(&this, pidl, propkey, ppropvar);

	public HRESULT SetTileViewProperties(ITEMIDLIST* pidl, PWSTR pszPropList) mut => VT.[Friend]SetTileViewProperties(&this, pidl, pszPropList);

	public HRESULT SetExtendedTileViewProperties(ITEMIDLIST* pidl, PWSTR pszPropList) mut => VT.[Friend]SetExtendedTileViewProperties(&this, pidl, pszPropList);

	public HRESULT SetText(FVTEXTTYPE iType, PWSTR pwszText) mut => VT.[Friend]SetText(&this, iType, pwszText);

	public HRESULT SetCurrentFolderFlags(uint32 dwMask, uint32 dwFlags) mut => VT.[Friend]SetCurrentFolderFlags(&this, dwMask, dwFlags);

	public HRESULT GetCurrentFolderFlags(uint32* pdwFlags) mut => VT.[Friend]GetCurrentFolderFlags(&this, pdwFlags);

	public HRESULT GetSortColumnCount(int32* pcColumns) mut => VT.[Friend]GetSortColumnCount(&this, pcColumns);

	public HRESULT SetSortColumns(SORTCOLUMN* rgSortColumns, int32 cColumns) mut => VT.[Friend]SetSortColumns(&this, rgSortColumns, cColumns);

	public HRESULT GetSortColumns(SORTCOLUMN* rgSortColumns, int32 cColumns) mut => VT.[Friend]GetSortColumns(&this, rgSortColumns, cColumns);

	public HRESULT GetItem(int32 iItem, in Guid riid, void** ppv) mut => VT.[Friend]GetItem(&this, iItem, riid, ppv);

	public HRESULT GetVisibleItem(int32 iStart, BOOL fPrevious, int32* piItem) mut => VT.[Friend]GetVisibleItem(&this, iStart, fPrevious, piItem);

	public HRESULT GetSelectedItem(int32 iStart, int32* piItem) mut => VT.[Friend]GetSelectedItem(&this, iStart, piItem);

	public HRESULT GetSelection(BOOL fNoneImpliesFolder, IShellItemArray** ppsia) mut => VT.[Friend]GetSelection(&this, fNoneImpliesFolder, ppsia);

	public HRESULT GetSelectionState(ITEMIDLIST* pidl, uint32* pdwFlags) mut => VT.[Friend]GetSelectionState(&this, pidl, pdwFlags);

	public HRESULT InvokeVerbOnSelection(PSTR pszVerb) mut => VT.[Friend]InvokeVerbOnSelection(&this, pszVerb);

	public HRESULT SetViewModeAndIconSize(FOLDERVIEWMODE uViewMode, int32 iImageSize) mut => VT.[Friend]SetViewModeAndIconSize(&this, uViewMode, iImageSize);

	public HRESULT GetViewModeAndIconSize(FOLDERVIEWMODE* puViewMode, int32* piImageSize) mut => VT.[Friend]GetViewModeAndIconSize(&this, puViewMode, piImageSize);

	public HRESULT SetGroupSubsetCount(uint32 cVisibleRows) mut => VT.[Friend]SetGroupSubsetCount(&this, cVisibleRows);

	public HRESULT GetGroupSubsetCount(uint32* pcVisibleRows) mut => VT.[Friend]GetGroupSubsetCount(&this, pcVisibleRows);

	public HRESULT SetRedraw(BOOL fRedrawOn) mut => VT.[Friend]SetRedraw(&this, fRedrawOn);

	public HRESULT IsMoveInSameFolder() mut => VT.[Friend]IsMoveInSameFolder(&this);

	public HRESULT DoRename() mut => VT.[Friend]DoRename(&this);
}

[CRepr]struct IFolderViewSettings : IUnknown
{
	public new const Guid IID = .(0xae8c987d, 0x8797, 0x4ed3, 0xbe, 0x72, 0x2a, 0x47, 0xdd, 0x93, 0x8d, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetColumnPropertyList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pkey, BOOL* pfGroupAscending) GetGroupByProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERLOGICALVIEWMODE* plvm) GetViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puIconSize) GetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERFLAGS* pfolderMask, FOLDERFLAGS* pfolderFlags) GetFolderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SORTCOLUMN* rgSortColumns, uint32 cColumnsIn, uint32* pcColumnsOut) GetSortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcVisibleRows) GetGroupSubsetCount;
	}


	public HRESULT GetColumnPropertyList(in Guid riid, void** ppv) mut => VT.[Friend]GetColumnPropertyList(&this, riid, ppv);

	public HRESULT GetGroupByProperty(PROPERTYKEY* pkey, BOOL* pfGroupAscending) mut => VT.[Friend]GetGroupByProperty(&this, pkey, pfGroupAscending);

	public HRESULT GetViewMode(FOLDERLOGICALVIEWMODE* plvm) mut => VT.[Friend]GetViewMode(&this, plvm);

	public HRESULT GetIconSize(uint32* puIconSize) mut => VT.[Friend]GetIconSize(&this, puIconSize);

	public HRESULT GetFolderFlags(FOLDERFLAGS* pfolderMask, FOLDERFLAGS* pfolderFlags) mut => VT.[Friend]GetFolderFlags(&this, pfolderMask, pfolderFlags);

	public HRESULT GetSortColumns(SORTCOLUMN* rgSortColumns, uint32 cColumnsIn, uint32* pcColumnsOut) mut => VT.[Friend]GetSortColumns(&this, rgSortColumns, cColumnsIn, pcColumnsOut);

	public HRESULT GetGroupSubsetCount(uint32* pcVisibleRows) mut => VT.[Friend]GetGroupSubsetCount(&this, pcVisibleRows);
}

[CRepr]struct IInitializeNetworkFolder : IUnknown
{
	public new const Guid IID = .(0x6e0f9881, 0x42a8, 0x4f2a, 0x97, 0xf8, 0x8a, 0xf4, 0xe0, 0x26, 0xd9, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, ITEMIDLIST* pidlTarget, uint32 uDisplayType, PWSTR pszResName, PWSTR pszProvider) Initialize;
	}


	public HRESULT Initialize(ITEMIDLIST* pidl, ITEMIDLIST* pidlTarget, uint32 uDisplayType, PWSTR pszResName, PWSTR pszProvider) mut => VT.[Friend]Initialize(&this, pidl, pidlTarget, uDisplayType, pszResName, pszProvider);
}

[CRepr]struct INetworkFolderInternal : IUnknown
{
	public new const Guid IID = .(0xceb38218, 0xc971, 0x47bb, 0xa7, 0x03, 0xf0, 0xbc, 0x99, 0xcc, 0xdb, 0x81);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* displayType) GetResourceDisplayType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** idList) GetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itemIdCount, ITEMIDLIST** itemIds, uint32 providerMaxLength, char16* provider) GetProvider;
	}


	public HRESULT GetResourceDisplayType(uint32* displayType) mut => VT.[Friend]GetResourceDisplayType(&this, displayType);

	public HRESULT GetIDList(ITEMIDLIST** idList) mut => VT.[Friend]GetIDList(&this, idList);

	public HRESULT GetProvider(uint32 itemIdCount, ITEMIDLIST** itemIds, uint32 providerMaxLength, char16* provider) mut => VT.[Friend]GetProvider(&this, itemIdCount, itemIds, providerMaxLength, provider);
}

[CRepr]struct IPreviewHandlerVisuals : IUnknown
{
	public new const Guid IID = .(0x196bf9a5, 0xb346, 0x4ef0, 0xaa, 0x1e, 0x5d, 0xcd, 0xb7, 0x67, 0x68, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF color) SetBackgroundColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGFONTW* plf) SetFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF color) SetTextColor;
	}


	public HRESULT SetBackgroundColor(COLORREF color) mut => VT.[Friend]SetBackgroundColor(&this, color);

	public HRESULT SetFont(LOGFONTW* plf) mut => VT.[Friend]SetFont(&this, plf);

	public HRESULT SetTextColor(COLORREF color) mut => VT.[Friend]SetTextColor(&this, color);
}

[CRepr]struct ICommDlgBrowser : IUnknown
{
	public new const Guid IID = .(0x000214f1, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv) OnDefaultCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv, uint32 uChange) OnStateChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv, ITEMIDLIST* pidl) IncludeObject;
	}


	public HRESULT OnDefaultCommand(IShellView* ppshv) mut => VT.[Friend]OnDefaultCommand(&this, ppshv);

	public HRESULT OnStateChange(IShellView* ppshv, uint32 uChange) mut => VT.[Friend]OnStateChange(&this, ppshv, uChange);

	public HRESULT IncludeObject(IShellView* ppshv, ITEMIDLIST* pidl) mut => VT.[Friend]IncludeObject(&this, ppshv, pidl);
}

[CRepr]struct ICommDlgBrowser2 : ICommDlgBrowser
{
	public new const Guid IID = .(0x10339516, 0x2894, 0x11d2, 0x90, 0x39, 0x00, 0xc0, 0x4f, 0x8e, 0xeb, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICommDlgBrowser.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv, uint32 dwNotifyType) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv, char16* pszText, int32 cchMax) GetDefaultMenuText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetViewFlags;
	}


	public HRESULT Notify(IShellView* ppshv, uint32 dwNotifyType) mut => VT.[Friend]Notify(&this, ppshv, dwNotifyType);

	public HRESULT GetDefaultMenuText(IShellView* ppshv, char16* pszText, int32 cchMax) mut => VT.[Friend]GetDefaultMenuText(&this, ppshv, pszText, cchMax);

	public HRESULT GetViewFlags(uint32* pdwFlags) mut => VT.[Friend]GetViewFlags(&this, pdwFlags);
}

[CRepr]struct IColumnManager : IUnknown
{
	public new const Guid IID = .(0xd8ec27bb, 0x3f3b, 0x4042, 0xb1, 0x0a, 0x4a, 0xcf, 0xd9, 0x24, 0xd4, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CM_COLUMNINFO* pcmci) SetColumnInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, CM_COLUMNINFO* pcmci) GetColumnInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CM_ENUM_FLAGS dwFlags, uint32* puCount) GetColumnCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CM_ENUM_FLAGS dwFlags, PROPERTYKEY* rgkeyOrder, uint32 cColumns) GetColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* rgkeyOrder, uint32 cVisible) SetColumns;
	}


	public HRESULT SetColumnInfo(PROPERTYKEY* propkey, CM_COLUMNINFO* pcmci) mut => VT.[Friend]SetColumnInfo(&this, propkey, pcmci);

	public HRESULT GetColumnInfo(PROPERTYKEY* propkey, CM_COLUMNINFO* pcmci) mut => VT.[Friend]GetColumnInfo(&this, propkey, pcmci);

	public HRESULT GetColumnCount(CM_ENUM_FLAGS dwFlags, uint32* puCount) mut => VT.[Friend]GetColumnCount(&this, dwFlags, puCount);

	public HRESULT GetColumns(CM_ENUM_FLAGS dwFlags, PROPERTYKEY* rgkeyOrder, uint32 cColumns) mut => VT.[Friend]GetColumns(&this, dwFlags, rgkeyOrder, cColumns);

	public HRESULT SetColumns(PROPERTYKEY* rgkeyOrder, uint32 cVisible) mut => VT.[Friend]SetColumns(&this, rgkeyOrder, cVisible);
}

[CRepr]struct IFolderFilterSite : IUnknown
{
	public new const Guid IID = .(0xc0a651f5, 0xb48b, 0x11d2, 0xb5, 0xed, 0x00, 0x60, 0x97, 0xc6, 0x86, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) SetFilter;
	}


	public HRESULT SetFilter(IUnknown* punk) mut => VT.[Friend]SetFilter(&this, punk);
}

[CRepr]struct IFolderFilter : IUnknown
{
	public new const Guid IID = .(0x9cc22886, 0xdc8e, 0x11d2, 0xb1, 0xd0, 0x00, 0xc0, 0x4f, 0x8e, 0xeb, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidlFolder, ITEMIDLIST* pidlItem) ShouldShow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidlFolder, HWND* phwnd, uint32* pgrfFlags) GetEnumFlags;
	}


	public HRESULT ShouldShow(IShellFolder* psf, ITEMIDLIST* pidlFolder, ITEMIDLIST* pidlItem) mut => VT.[Friend]ShouldShow(&this, psf, pidlFolder, pidlItem);

	public HRESULT GetEnumFlags(IShellFolder* psf, ITEMIDLIST* pidlFolder, HWND* phwnd, uint32* pgrfFlags) mut => VT.[Friend]GetEnumFlags(&this, psf, pidlFolder, phwnd, pgrfFlags);
}

[CRepr]struct IInputObjectSite : IUnknown
{
	public new const Guid IID = .(0xf1db8392, 0x7331, 0x11d0, 0x8c, 0x99, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkObj, BOOL fSetFocus) OnFocusChangeIS;
	}


	public HRESULT OnFocusChangeIS(IUnknown* punkObj, BOOL fSetFocus) mut => VT.[Friend]OnFocusChangeIS(&this, punkObj, fSetFocus);
}

[CRepr]struct IInputObject : IUnknown
{
	public new const Guid IID = .(0x68284faa, 0x6a48, 0x11d0, 0x8c, 0x78, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActivate, MSG* pMsg) UIActivateIO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HasFocusIO;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg) TranslateAcceleratorIO;
	}


	public HRESULT UIActivateIO(BOOL fActivate, MSG* pMsg) mut => VT.[Friend]UIActivateIO(&this, fActivate, pMsg);

	public HRESULT HasFocusIO() mut => VT.[Friend]HasFocusIO(&this);

	public HRESULT TranslateAcceleratorIO(MSG* pMsg) mut => VT.[Friend]TranslateAcceleratorIO(&this, pMsg);
}

[CRepr]struct IInputObject2 : IInputObject
{
	public new const Guid IID = .(0x6915c085, 0x510b, 0x44cd, 0x94, 0xaf, 0x28, 0xdf, 0xa5, 0x6c, 0xf9, 0x2b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IInputObject.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg) TranslateAcceleratorGlobal;
	}


	public HRESULT TranslateAcceleratorGlobal(MSG* pMsg) mut => VT.[Friend]TranslateAcceleratorGlobal(&this, pMsg);
}

[CRepr]struct IShellIcon : IUnknown
{
	public new const Guid IID = .(0x000214e5, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 flags, int32* pIconIndex) GetIconOf;
	}


	public HRESULT GetIconOf(ITEMIDLIST* pidl, uint32 flags, int32* pIconIndex) mut => VT.[Friend]GetIconOf(&this, pidl, flags, pIconIndex);
}

[CRepr]struct IShellBrowser : IOleWindow
{
	public new const Guid IID = .(0x000214e2, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared, OLEMENUGROUPWIDTHS* lpMenuWidths) InsertMenusSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared, int holemenuRes, HWND hwndActiveObject) SetMenuSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenuShared) RemoveMenusSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStatusText) SetStatusTextSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) EnableModelessSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg, uint16 wID) TranslateAcceleratorSB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 wFlags) BrowseObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfMode, IStream** ppStrm) GetViewStateStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 id, HWND* phwnd) GetControlWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 id, uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* pret) SendControlMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView** ppshv) QueryActiveShellView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* pshv) OnViewWindowActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TBBUTTON* lpButtons, uint32 nButtons, uint32 uFlags) SetToolbarItems;
	}


	public HRESULT InsertMenusSB(HMENU hmenuShared, OLEMENUGROUPWIDTHS* lpMenuWidths) mut => VT.[Friend]InsertMenusSB(&this, hmenuShared, lpMenuWidths);

	public HRESULT SetMenuSB(HMENU hmenuShared, int holemenuRes, HWND hwndActiveObject) mut => VT.[Friend]SetMenuSB(&this, hmenuShared, holemenuRes, hwndActiveObject);

	public HRESULT RemoveMenusSB(HMENU hmenuShared) mut => VT.[Friend]RemoveMenusSB(&this, hmenuShared);

	public HRESULT SetStatusTextSB(PWSTR pszStatusText) mut => VT.[Friend]SetStatusTextSB(&this, pszStatusText);

	public HRESULT EnableModelessSB(BOOL fEnable) mut => VT.[Friend]EnableModelessSB(&this, fEnable);

	public HRESULT TranslateAcceleratorSB(MSG* pmsg, uint16 wID) mut => VT.[Friend]TranslateAcceleratorSB(&this, pmsg, wID);

	public HRESULT BrowseObject(ITEMIDLIST* pidl, uint32 wFlags) mut => VT.[Friend]BrowseObject(&this, pidl, wFlags);

	public HRESULT GetViewStateStream(uint32 grfMode, IStream** ppStrm) mut => VT.[Friend]GetViewStateStream(&this, grfMode, ppStrm);

	public HRESULT GetControlWindow(uint32 id, HWND* phwnd) mut => VT.[Friend]GetControlWindow(&this, id, phwnd);

	public HRESULT SendControlMsg(uint32 id, uint32 uMsg, WPARAM wParam, LPARAM lParam, LRESULT* pret) mut => VT.[Friend]SendControlMsg(&this, id, uMsg, wParam, lParam, pret);

	public HRESULT QueryActiveShellView(IShellView** ppshv) mut => VT.[Friend]QueryActiveShellView(&this, ppshv);

	public HRESULT OnViewWindowActive(IShellView* pshv) mut => VT.[Friend]OnViewWindowActive(&this, pshv);

	public HRESULT SetToolbarItems(TBBUTTON* lpButtons, uint32 nButtons, uint32 uFlags) mut => VT.[Friend]SetToolbarItems(&this, lpButtons, nButtons, uFlags);
}

[CRepr]struct IProfferService : IUnknown
{
	public new const Guid IID = .(0xcb728b20, 0xf786, 0x11ce, 0x92, 0xad, 0x00, 0xaa, 0x00, 0xa7, 0x4c, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid serviceId, IServiceProvider* serviceProvider, uint32* cookie) ProfferService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cookie) RevokeService;
	}


	public HRESULT ProfferService(in Guid serviceId, IServiceProvider* serviceProvider, uint32* cookie) mut => VT.[Friend]ProfferService(&this, serviceId, serviceProvider, cookie);

	public HRESULT RevokeService(uint32 cookie) mut => VT.[Friend]RevokeService(&this, cookie);
}

[CRepr]struct IGetServiceIds : IUnknown
{
	public new const Guid IID = .(0x4a073526, 0x6103, 0x4e21, 0xb7, 0xbc, 0xf5, 0x19, 0xd1, 0x52, 0x4e, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* serviceIdCount, Guid** serviceIds) GetServiceIds;
	}


	public HRESULT GetServiceIds(uint32* serviceIdCount, Guid** serviceIds) mut => VT.[Friend]GetServiceIds(&this, serviceIdCount, serviceIds);
}

[CRepr]struct IShellItem : IUnknown
{
	public new const Guid IID = .(0x43826d1e, 0xe718, 0x42ee, 0xbc, 0x55, 0xa1, 0xe2, 0x61, 0xc3, 0x7b, 0xfe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, in Guid bhid, in Guid riid, void** ppv) BindToHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem** ppsi) GetParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIGDN sigdnName, PWSTR* ppszName) GetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SFGAO_FLAGS sfgaoMask, SFGAO_FLAGS* psfgaoAttribs) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 hint, int32* piOrder) Compare;
	}


	public HRESULT BindToHandler(IBindCtx* pbc, in Guid bhid, in Guid riid, void** ppv) mut => VT.[Friend]BindToHandler(&this, pbc, bhid, riid, ppv);

	public HRESULT GetParent(IShellItem** ppsi) mut => VT.[Friend]GetParent(&this, ppsi);

	public HRESULT GetDisplayName(SIGDN sigdnName, PWSTR* ppszName) mut => VT.[Friend]GetDisplayName(&this, sigdnName, ppszName);

	public HRESULT GetAttributes(SFGAO_FLAGS sfgaoMask, SFGAO_FLAGS* psfgaoAttribs) mut => VT.[Friend]GetAttributes(&this, sfgaoMask, psfgaoAttribs);

	public HRESULT Compare(IShellItem* psi, uint32 hint, int32* piOrder) mut => VT.[Friend]Compare(&this, psi, hint, piOrder);
}

[CRepr]struct IShellItem2 : IShellItem
{
	public new const Guid IID = .(0x7e9fb0d3, 0x919f, 0x4307, 0xab, 0x2e, 0x9b, 0x18, 0x60, 0x31, 0x0c, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) GetPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GETPROPERTYSTOREFLAGS flags, IUnknown* punkCreateObject, in Guid riid, void** ppv) GetPropertyStoreWithCreateObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* rgKeys, uint32 cKeys, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) GetPropertyStoreForKeys;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* keyType, in Guid riid, void** ppv) GetPropertyDescriptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* ppropvar) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, Guid* pclsid) GetCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, FILETIME* pft) GetFileTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, int32* pi) GetInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PWSTR* ppsz) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint32* pui) GetUInt32;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, uint64* pull) GetUInt64;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, BOOL* pf) GetBool;
	}


	public HRESULT GetPropertyStore(GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStore(&this, flags, riid, ppv);

	public HRESULT GetPropertyStoreWithCreateObject(GETPROPERTYSTOREFLAGS flags, IUnknown* punkCreateObject, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStoreWithCreateObject(&this, flags, punkCreateObject, riid, ppv);

	public HRESULT GetPropertyStoreForKeys(PROPERTYKEY* rgKeys, uint32 cKeys, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStoreForKeys(&this, rgKeys, cKeys, flags, riid, ppv);

	public HRESULT GetPropertyDescriptionList(PROPERTYKEY* keyType, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyDescriptionList(&this, keyType, riid, ppv);

	public HRESULT Update(IBindCtx* pbc) mut => VT.[Friend]Update(&this, pbc);

	public HRESULT GetProperty(PROPERTYKEY* key, PROPVARIANT* ppropvar) mut => VT.[Friend]GetProperty(&this, key, ppropvar);

	public HRESULT GetCLSID(PROPERTYKEY* key, Guid* pclsid) mut => VT.[Friend]GetCLSID(&this, key, pclsid);

	public HRESULT GetFileTime(PROPERTYKEY* key, FILETIME* pft) mut => VT.[Friend]GetFileTime(&this, key, pft);

	public HRESULT GetInt32(PROPERTYKEY* key, int32* pi) mut => VT.[Friend]GetInt32(&this, key, pi);

	public HRESULT GetString(PROPERTYKEY* key, PWSTR* ppsz) mut => VT.[Friend]GetString(&this, key, ppsz);

	public HRESULT GetUInt32(PROPERTYKEY* key, uint32* pui) mut => VT.[Friend]GetUInt32(&this, key, pui);

	public HRESULT GetUInt64(PROPERTYKEY* key, uint64* pull) mut => VT.[Friend]GetUInt64(&this, key, pull);

	public HRESULT GetBool(PROPERTYKEY* key, BOOL* pf) mut => VT.[Friend]GetBool(&this, key, pf);
}

[CRepr]struct IShellItemImageFactory : IUnknown
{
	public new const Guid IID = .(0xbcc18b79, 0xba16, 0x442f, 0x80, 0xc4, 0x8a, 0x59, 0xc3, 0x0c, 0x46, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE size, SIIGBF flags, HBITMAP* phbm) GetImage;
	}


	public HRESULT GetImage(SIZE size, SIIGBF flags, HBITMAP* phbm) mut => VT.[Friend]GetImage(&this, size, flags, phbm);
}

[CRepr]struct IEnumShellItems : IUnknown
{
	public new const Guid IID = .(0x70629033, 0xe363, 0x4a28, 0xa5, 0x67, 0x0d, 0xb7, 0x80, 0x06, 0xe6, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IShellItem** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumShellItems** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IShellItem** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumShellItems** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ITransferAdviseSink : IUnknown
{
	public new const Guid IID = .(0xd594d0d8, 0x8da7, 0x457b, 0xb3, 0xb4, 0xce, 0x5d, 0xba, 0xac, 0x0b, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullSizeCurrent, uint64 ullSizeTotal, int32 nFilesCurrent, int32 nFilesTotal, int32 nFoldersCurrent, int32 nFoldersTotal) UpdateProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ts) UpdateTransferState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem* psiDestParent, PWSTR pszName) ConfirmOverwrite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource) ConfirmEncryptionLoss;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, PWSTR pszItem, HRESULT hrError, char16* pszRename, uint32 cchRename) FileFailure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, PWSTR pszStreamName, HRESULT hrError) SubStreamFailure;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, PROPERTYKEY* pkey, HRESULT hrError) PropertyFailure;
	}


	public HRESULT UpdateProgress(uint64 ullSizeCurrent, uint64 ullSizeTotal, int32 nFilesCurrent, int32 nFilesTotal, int32 nFoldersCurrent, int32 nFoldersTotal) mut => VT.[Friend]UpdateProgress(&this, ullSizeCurrent, ullSizeTotal, nFilesCurrent, nFilesTotal, nFoldersCurrent, nFoldersTotal);

	public HRESULT UpdateTransferState(uint32 ts) mut => VT.[Friend]UpdateTransferState(&this, ts);

	public HRESULT ConfirmOverwrite(IShellItem* psiSource, IShellItem* psiDestParent, PWSTR pszName) mut => VT.[Friend]ConfirmOverwrite(&this, psiSource, psiDestParent, pszName);

	public HRESULT ConfirmEncryptionLoss(IShellItem* psiSource) mut => VT.[Friend]ConfirmEncryptionLoss(&this, psiSource);

	public HRESULT FileFailure(IShellItem* psi, PWSTR pszItem, HRESULT hrError, char16* pszRename, uint32 cchRename) mut => VT.[Friend]FileFailure(&this, psi, pszItem, hrError, pszRename, cchRename);

	public HRESULT SubStreamFailure(IShellItem* psi, PWSTR pszStreamName, HRESULT hrError) mut => VT.[Friend]SubStreamFailure(&this, psi, pszStreamName, hrError);

	public HRESULT PropertyFailure(IShellItem* psi, PROPERTYKEY* pkey, HRESULT hrError) mut => VT.[Friend]PropertyFailure(&this, psi, pkey, hrError);
}

[CRepr]struct ITransferSource : IUnknown
{
	public new const Guid IID = .(0x00adb003, 0xbde9, 0x45c6, 0x8e, 0x29, 0xd0, 0x9f, 0x93, 0x53, 0xe1, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransferAdviseSink* psink, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyChangeArray* pproparray) SetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 flags, in Guid riid, void** ppv) OpenItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, IShellItem* psiParentDst, PWSTR pszNameDst, uint32 flags, IShellItem** ppsiNew) MoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem* psiParentDest, uint32 flags, IShellItem** ppsiNewDest) RecycleItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, uint32 flags) RemoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, PWSTR pszNewName, uint32 flags, IShellItem** ppsiNewDest) RenameItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem* psiParentDest, PWSTR pszNewName, uint32 flags, IShellItem** ppsiNewDest) LinkItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem** ppsiNew) ApplyPropertiesToItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem* psiParentDest, PWSTR* ppszDestinationName) GetDefaultDestinationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiChildFolderDest) EnterFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiChildFolderDest) LeaveFolder;
	}


	public HRESULT Advise(ITransferAdviseSink* psink, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, psink, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT SetProperties(IPropertyChangeArray* pproparray) mut => VT.[Friend]SetProperties(&this, pproparray);

	public HRESULT OpenItem(IShellItem* psi, uint32 flags, in Guid riid, void** ppv) mut => VT.[Friend]OpenItem(&this, psi, flags, riid, ppv);

	public HRESULT MoveItem(IShellItem* psi, IShellItem* psiParentDst, PWSTR pszNameDst, uint32 flags, IShellItem** ppsiNew) mut => VT.[Friend]MoveItem(&this, psi, psiParentDst, pszNameDst, flags, ppsiNew);

	public HRESULT RecycleItem(IShellItem* psiSource, IShellItem* psiParentDest, uint32 flags, IShellItem** ppsiNewDest) mut => VT.[Friend]RecycleItem(&this, psiSource, psiParentDest, flags, ppsiNewDest);

	public HRESULT RemoveItem(IShellItem* psiSource, uint32 flags) mut => VT.[Friend]RemoveItem(&this, psiSource, flags);

	public HRESULT RenameItem(IShellItem* psiSource, PWSTR pszNewName, uint32 flags, IShellItem** ppsiNewDest) mut => VT.[Friend]RenameItem(&this, psiSource, pszNewName, flags, ppsiNewDest);

	public HRESULT LinkItem(IShellItem* psiSource, IShellItem* psiParentDest, PWSTR pszNewName, uint32 flags, IShellItem** ppsiNewDest) mut => VT.[Friend]LinkItem(&this, psiSource, psiParentDest, pszNewName, flags, ppsiNewDest);

	public HRESULT ApplyPropertiesToItem(IShellItem* psiSource, IShellItem** ppsiNew) mut => VT.[Friend]ApplyPropertiesToItem(&this, psiSource, ppsiNew);

	public HRESULT GetDefaultDestinationName(IShellItem* psiSource, IShellItem* psiParentDest, PWSTR* ppszDestinationName) mut => VT.[Friend]GetDefaultDestinationName(&this, psiSource, psiParentDest, ppszDestinationName);

	public HRESULT EnterFolder(IShellItem* psiChildFolderDest) mut => VT.[Friend]EnterFolder(&this, psiChildFolderDest);

	public HRESULT LeaveFolder(IShellItem* psiChildFolderDest) mut => VT.[Friend]LeaveFolder(&this, psiChildFolderDest);
}

[CRepr]struct IEnumResources : IUnknown
{
	public new const Guid IID = .(0x2dd81fe3, 0xa83c, 0x4da9, 0xa3, 0x30, 0x47, 0x24, 0x9d, 0x34, 0x5b, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, SHELL_ITEM_RESOURCE* psir, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumResources** ppenumr) Clone;
	}


	public HRESULT Next(uint32 celt, SHELL_ITEM_RESOURCE* psir, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, psir, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumResources** ppenumr) mut => VT.[Friend]Clone(&this, ppenumr);
}

[CRepr]struct IShellItemResources : IUnknown
{
	public new const Guid IID = .(0xff5693be, 0x2ce0, 0x4d48, 0xb5, 0xc5, 0x40, 0x81, 0x7d, 0x1a, 0xcd, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAttributes) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullSize) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftCreation, FILETIME* pftWrite, FILETIME* pftAccess) GetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftCreation, FILETIME* pftWrite, FILETIME* pftAccess) SetTimes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHELL_ITEM_RESOURCE* pcsir, PWSTR* ppszDescription) GetResourceDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumResources** ppenumr) EnumResources;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHELL_ITEM_RESOURCE* pcsir) SupportsResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHELL_ITEM_RESOURCE* pcsir, in Guid riid, void** ppv) OpenResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHELL_ITEM_RESOURCE* pcsir, in Guid riid, void** ppv) CreateResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MarkForDelete;
	}


	public HRESULT GetAttributes(uint32* pdwAttributes) mut => VT.[Friend]GetAttributes(&this, pdwAttributes);

	public HRESULT GetSize(uint64* pullSize) mut => VT.[Friend]GetSize(&this, pullSize);

	public HRESULT GetTimes(FILETIME* pftCreation, FILETIME* pftWrite, FILETIME* pftAccess) mut => VT.[Friend]GetTimes(&this, pftCreation, pftWrite, pftAccess);

	public HRESULT SetTimes(FILETIME* pftCreation, FILETIME* pftWrite, FILETIME* pftAccess) mut => VT.[Friend]SetTimes(&this, pftCreation, pftWrite, pftAccess);

	public HRESULT GetResourceDescription(SHELL_ITEM_RESOURCE* pcsir, PWSTR* ppszDescription) mut => VT.[Friend]GetResourceDescription(&this, pcsir, ppszDescription);

	public HRESULT EnumResources(IEnumResources** ppenumr) mut => VT.[Friend]EnumResources(&this, ppenumr);

	public HRESULT SupportsResource(SHELL_ITEM_RESOURCE* pcsir) mut => VT.[Friend]SupportsResource(&this, pcsir);

	public HRESULT OpenResource(SHELL_ITEM_RESOURCE* pcsir, in Guid riid, void** ppv) mut => VT.[Friend]OpenResource(&this, pcsir, riid, ppv);

	public HRESULT CreateResource(SHELL_ITEM_RESOURCE* pcsir, in Guid riid, void** ppv) mut => VT.[Friend]CreateResource(&this, pcsir, riid, ppv);

	public HRESULT MarkForDelete() mut => VT.[Friend]MarkForDelete(&this);
}

[CRepr]struct ITransferDestination : IUnknown
{
	public new const Guid IID = .(0x48addd32, 0x3ca5, 0x4124, 0xab, 0xe3, 0xb5, 0xa7, 0x25, 0x31, 0xb2, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITransferAdviseSink* psink, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, uint32 dwAttributes, uint64 ullSize, uint32 flags, in Guid riidItem, void** ppvItem, in Guid riidResources, void** ppvResources) CreateItem;
	}


	public HRESULT Advise(ITransferAdviseSink* psink, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, psink, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT CreateItem(PWSTR pszName, uint32 dwAttributes, uint64 ullSize, uint32 flags, in Guid riidItem, void** ppvItem, in Guid riidResources, void** ppvResources) mut => VT.[Friend]CreateItem(&this, pszName, dwAttributes, ullSize, flags, riidItem, ppvItem, riidResources, ppvResources);
}

[CRepr]struct IFileOperationProgressSink : IUnknown
{
	public new const Guid IID = .(0x04b0f1a7, 0x9490, 0x44bc, 0x96, 0xe1, 0x42, 0x96, 0xa3, 0x12, 0x52, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StartOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hrResult) FinishOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, PWSTR pszNewName) PreRenameItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, PWSTR pszNewName, HRESULT hrRename, IShellItem* psiNewlyCreated) PostRenameItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName) PreMoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, HRESULT hrMove, IShellItem* psiNewlyCreated) PostMoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName) PreCopyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, HRESULT hrCopy, IShellItem* psiNewlyCreated) PostCopyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem) PreDeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiItem, HRESULT hrDelete, IShellItem* psiNewlyCreated) PostDeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiDestinationFolder, PWSTR pszNewName) PreNewItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, IShellItem* psiDestinationFolder, PWSTR pszNewName, PWSTR pszTemplateName, uint32 dwFileAttributes, HRESULT hrNew, IShellItem* psiNewItem) PostNewItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iWorkTotal, uint32 iWorkSoFar) UpdateProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PauseTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeTimer;
	}


	public HRESULT StartOperations() mut => VT.[Friend]StartOperations(&this);

	public HRESULT FinishOperations(HRESULT hrResult) mut => VT.[Friend]FinishOperations(&this, hrResult);

	public HRESULT PreRenameItem(uint32 dwFlags, IShellItem* psiItem, PWSTR pszNewName) mut => VT.[Friend]PreRenameItem(&this, dwFlags, psiItem, pszNewName);

	public HRESULT PostRenameItem(uint32 dwFlags, IShellItem* psiItem, PWSTR pszNewName, HRESULT hrRename, IShellItem* psiNewlyCreated) mut => VT.[Friend]PostRenameItem(&this, dwFlags, psiItem, pszNewName, hrRename, psiNewlyCreated);

	public HRESULT PreMoveItem(uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName) mut => VT.[Friend]PreMoveItem(&this, dwFlags, psiItem, psiDestinationFolder, pszNewName);

	public HRESULT PostMoveItem(uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, HRESULT hrMove, IShellItem* psiNewlyCreated) mut => VT.[Friend]PostMoveItem(&this, dwFlags, psiItem, psiDestinationFolder, pszNewName, hrMove, psiNewlyCreated);

	public HRESULT PreCopyItem(uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName) mut => VT.[Friend]PreCopyItem(&this, dwFlags, psiItem, psiDestinationFolder, pszNewName);

	public HRESULT PostCopyItem(uint32 dwFlags, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, HRESULT hrCopy, IShellItem* psiNewlyCreated) mut => VT.[Friend]PostCopyItem(&this, dwFlags, psiItem, psiDestinationFolder, pszNewName, hrCopy, psiNewlyCreated);

	public HRESULT PreDeleteItem(uint32 dwFlags, IShellItem* psiItem) mut => VT.[Friend]PreDeleteItem(&this, dwFlags, psiItem);

	public HRESULT PostDeleteItem(uint32 dwFlags, IShellItem* psiItem, HRESULT hrDelete, IShellItem* psiNewlyCreated) mut => VT.[Friend]PostDeleteItem(&this, dwFlags, psiItem, hrDelete, psiNewlyCreated);

	public HRESULT PreNewItem(uint32 dwFlags, IShellItem* psiDestinationFolder, PWSTR pszNewName) mut => VT.[Friend]PreNewItem(&this, dwFlags, psiDestinationFolder, pszNewName);

	public HRESULT PostNewItem(uint32 dwFlags, IShellItem* psiDestinationFolder, PWSTR pszNewName, PWSTR pszTemplateName, uint32 dwFileAttributes, HRESULT hrNew, IShellItem* psiNewItem) mut => VT.[Friend]PostNewItem(&this, dwFlags, psiDestinationFolder, pszNewName, pszTemplateName, dwFileAttributes, hrNew, psiNewItem);

	public HRESULT UpdateProgress(uint32 iWorkTotal, uint32 iWorkSoFar) mut => VT.[Friend]UpdateProgress(&this, iWorkTotal, iWorkSoFar);

	public HRESULT ResetTimer() mut => VT.[Friend]ResetTimer(&this);

	public HRESULT PauseTimer() mut => VT.[Friend]PauseTimer(&this);

	public HRESULT ResumeTimer() mut => VT.[Friend]ResumeTimer(&this);
}

[CRepr]struct IShellItemArray : IUnknown
{
	public new const Guid IID = .(0xb63ea76d, 0x1f85, 0x456f, 0xa1, 0x9c, 0x48, 0x15, 0x9e, 0xfa, 0x85, 0x8b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, in Guid bhid, in Guid riid, void** ppvOut) BindToHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) GetPropertyStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* keyType, in Guid riid, void** ppv) GetPropertyDescriptionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIATTRIBFLAGS AttribFlags, SFGAO_FLAGS sfgaoMask, SFGAO_FLAGS* psfgaoAttribs) GetAttributes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwNumItems) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, IShellItem** ppsi) GetItemAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumShellItems** ppenumShellItems) EnumItems;
	}


	public HRESULT BindToHandler(IBindCtx* pbc, in Guid bhid, in Guid riid, void** ppvOut) mut => VT.[Friend]BindToHandler(&this, pbc, bhid, riid, ppvOut);

	public HRESULT GetPropertyStore(GETPROPERTYSTOREFLAGS flags, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyStore(&this, flags, riid, ppv);

	public HRESULT GetPropertyDescriptionList(PROPERTYKEY* keyType, in Guid riid, void** ppv) mut => VT.[Friend]GetPropertyDescriptionList(&this, keyType, riid, ppv);

	public HRESULT GetAttributes(SIATTRIBFLAGS AttribFlags, SFGAO_FLAGS sfgaoMask, SFGAO_FLAGS* psfgaoAttribs) mut => VT.[Friend]GetAttributes(&this, AttribFlags, sfgaoMask, psfgaoAttribs);

	public HRESULT GetCount(uint32* pdwNumItems) mut => VT.[Friend]GetCount(&this, pdwNumItems);

	public HRESULT GetItemAt(uint32 dwIndex, IShellItem** ppsi) mut => VT.[Friend]GetItemAt(&this, dwIndex, ppsi);

	public HRESULT EnumItems(IEnumShellItems** ppenumShellItems) mut => VT.[Friend]EnumItems(&this, ppenumShellItems);
}

[CRepr]struct IInitializeWithItem : IUnknown
{
	public new const Guid IID = .(0x7f73be3f, 0xfb79, 0x493c, 0xa6, 0xc7, 0x7e, 0xe1, 0x4e, 0x24, 0x58, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 grfMode) Initialize;
	}


	public HRESULT Initialize(IShellItem* psi, uint32 grfMode) mut => VT.[Friend]Initialize(&this, psi, grfMode);
}

[CRepr]struct IObjectWithSelection : IUnknown
{
	public new const Guid IID = .(0x1c9cd5bb, 0x98e9, 0x4491, 0xa6, 0x0f, 0x31, 0xaa, 0xcc, 0x72, 0xb8, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psia) SetSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetSelection;
	}


	public HRESULT SetSelection(IShellItemArray* psia) mut => VT.[Friend]SetSelection(&this, psia);

	public HRESULT GetSelection(in Guid riid, void** ppv) mut => VT.[Friend]GetSelection(&this, riid, ppv);
}

[CRepr]struct IObjectWithBackReferences : IUnknown
{
	public new const Guid IID = .(0x321a6a6a, 0xd61f, 0x4bf3, 0x97, 0xae, 0x14, 0xbe, 0x29, 0x86, 0xbb, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveBackReferences;
	}


	public HRESULT RemoveBackReferences() mut => VT.[Friend]RemoveBackReferences(&this);
}

[CRepr]struct ICategoryProvider : IUnknown
{
	public new const Guid IID = .(0x9af64809, 0x5864, 0x4c26, 0xa7, 0x20, 0xc1, 0xf7, 0x8c, 0x08, 0x6e, 0xe3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pscid) CanCategorizeOnSCID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguid, PROPERTYKEY* pscid) GetDefaultCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pscid, Guid* pguid) GetCategoryForSCID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumGUID** penum) EnumCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguid, char16* pszName, uint32 cch) GetCategoryName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pguid, in Guid riid, void** ppv) CreateCategory;
	}


	public HRESULT CanCategorizeOnSCID(PROPERTYKEY* pscid) mut => VT.[Friend]CanCategorizeOnSCID(&this, pscid);

	public HRESULT GetDefaultCategory(Guid* pguid, PROPERTYKEY* pscid) mut => VT.[Friend]GetDefaultCategory(&this, pguid, pscid);

	public HRESULT GetCategoryForSCID(PROPERTYKEY* pscid, Guid* pguid) mut => VT.[Friend]GetCategoryForSCID(&this, pscid, pguid);

	public HRESULT EnumCategories(IEnumGUID** penum) mut => VT.[Friend]EnumCategories(&this, penum);

	public HRESULT GetCategoryName(in Guid pguid, char16* pszName, uint32 cch) mut => VT.[Friend]GetCategoryName(&this, pguid, pszName, cch);

	public HRESULT CreateCategory(in Guid pguid, in Guid riid, void** ppv) mut => VT.[Friend]CreateCategory(&this, pguid, riid, ppv);
}

[CRepr]struct ICategorizer : IUnknown
{
	public new const Guid IID = .(0xa3b14589, 0x9174, 0x49a8, 0x89, 0xa3, 0x06, 0xa1, 0xae, 0x2b, 0x9b, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszDesc, uint32 cch) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cidl, ITEMIDLIST** apidl, uint32* rgCategoryIds) GetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCategoryId, CATEGORY_INFO* pci) GetCategoryInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CATSORT_FLAGS csfFlags, uint32 dwCategoryId1, uint32 dwCategoryId2) CompareCategory;
	}


	public HRESULT GetDescription(char16* pszDesc, uint32 cch) mut => VT.[Friend]GetDescription(&this, pszDesc, cch);

	public HRESULT GetCategory(uint32 cidl, ITEMIDLIST** apidl, uint32* rgCategoryIds) mut => VT.[Friend]GetCategory(&this, cidl, apidl, rgCategoryIds);

	public HRESULT GetCategoryInfo(uint32 dwCategoryId, CATEGORY_INFO* pci) mut => VT.[Friend]GetCategoryInfo(&this, dwCategoryId, pci);

	public HRESULT CompareCategory(CATSORT_FLAGS csfFlags, uint32 dwCategoryId1, uint32 dwCategoryId2) mut => VT.[Friend]CompareCategory(&this, csfFlags, dwCategoryId1, dwCategoryId2);
}

[CRepr]struct IDropTargetHelper : IUnknown
{
	public new const Guid IID = .(0x4657278b, 0x411b, 0x11d2, 0x83, 0x9a, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTarget, IDataObject* pDataObject, POINT* ppt, DROPEFFECT dwEffect) DragEnter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DragLeave;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt, DROPEFFECT dwEffect) DragOver;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, POINT* ppt, DROPEFFECT dwEffect) Drop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) Show;
	}


	public HRESULT DragEnter(HWND hwndTarget, IDataObject* pDataObject, POINT* ppt, DROPEFFECT dwEffect) mut => VT.[Friend]DragEnter(&this, hwndTarget, pDataObject, ppt, dwEffect);

	public HRESULT DragLeave() mut => VT.[Friend]DragLeave(&this);

	public HRESULT DragOver(POINT* ppt, DROPEFFECT dwEffect) mut => VT.[Friend]DragOver(&this, ppt, dwEffect);

	public HRESULT Drop(IDataObject* pDataObject, POINT* ppt, DROPEFFECT dwEffect) mut => VT.[Friend]Drop(&this, pDataObject, ppt, dwEffect);

	public HRESULT Show(BOOL fShow) mut => VT.[Friend]Show(&this, fShow);
}

[CRepr]struct IDragSourceHelper : IUnknown
{
	public new const Guid IID = .(0xde5bf786, 0x477a, 0x11d2, 0x83, 0x9d, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHDRAGIMAGE* pshdi, IDataObject* pDataObject) InitializeFromBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, POINT* ppt, IDataObject* pDataObject) InitializeFromWindow;
	}


	public HRESULT InitializeFromBitmap(SHDRAGIMAGE* pshdi, IDataObject* pDataObject) mut => VT.[Friend]InitializeFromBitmap(&this, pshdi, pDataObject);

	public HRESULT InitializeFromWindow(HWND hwnd, POINT* ppt, IDataObject* pDataObject) mut => VT.[Friend]InitializeFromWindow(&this, hwnd, ppt, pDataObject);
}

[CRepr]struct IShellLinkA : IUnknown
{
	public new const Guid IID = .(0x000214ee, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszFile, int32 cch, WIN32_FIND_DATAA* pfd, uint32 fFlags) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) SetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszName, int32 cch) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszName) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszDir, int32 cch) GetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszDir) SetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszArgs, int32 cch) GetArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszArgs) SetArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwHotkey) GetHotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wHotkey) SetHotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piShowCmd) GetShowCmd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iShowCmd) SetShowCmd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszIconPath, int32 cch, int32* piIcon) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszIconPath, int32 iIcon) SetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszPathRel, uint32 dwReserved) SetRelativePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 fFlags) Resolve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFile) SetPath;
	}


	public HRESULT GetPath(uint8* pszFile, int32 cch, WIN32_FIND_DATAA* pfd, uint32 fFlags) mut => VT.[Friend]GetPath(&this, pszFile, cch, pfd, fFlags);

	public HRESULT GetIDList(ITEMIDLIST** ppidl) mut => VT.[Friend]GetIDList(&this, ppidl);

	public HRESULT SetIDList(ITEMIDLIST* pidl) mut => VT.[Friend]SetIDList(&this, pidl);

	public HRESULT GetDescription(uint8* pszName, int32 cch) mut => VT.[Friend]GetDescription(&this, pszName, cch);

	public HRESULT SetDescription(PSTR pszName) mut => VT.[Friend]SetDescription(&this, pszName);

	public HRESULT GetWorkingDirectory(uint8* pszDir, int32 cch) mut => VT.[Friend]GetWorkingDirectory(&this, pszDir, cch);

	public HRESULT SetWorkingDirectory(PSTR pszDir) mut => VT.[Friend]SetWorkingDirectory(&this, pszDir);

	public HRESULT GetArguments(uint8* pszArgs, int32 cch) mut => VT.[Friend]GetArguments(&this, pszArgs, cch);

	public HRESULT SetArguments(PSTR pszArgs) mut => VT.[Friend]SetArguments(&this, pszArgs);

	public HRESULT GetHotkey(uint16* pwHotkey) mut => VT.[Friend]GetHotkey(&this, pwHotkey);

	public HRESULT SetHotkey(uint16 wHotkey) mut => VT.[Friend]SetHotkey(&this, wHotkey);

	public HRESULT GetShowCmd(int32* piShowCmd) mut => VT.[Friend]GetShowCmd(&this, piShowCmd);

	public HRESULT SetShowCmd(int32 iShowCmd) mut => VT.[Friend]SetShowCmd(&this, iShowCmd);

	public HRESULT GetIconLocation(uint8* pszIconPath, int32 cch, int32* piIcon) mut => VT.[Friend]GetIconLocation(&this, pszIconPath, cch, piIcon);

	public HRESULT SetIconLocation(PSTR pszIconPath, int32 iIcon) mut => VT.[Friend]SetIconLocation(&this, pszIconPath, iIcon);

	public HRESULT SetRelativePath(PSTR pszPathRel, uint32 dwReserved) mut => VT.[Friend]SetRelativePath(&this, pszPathRel, dwReserved);

	public HRESULT Resolve(HWND hwnd, uint32 fFlags) mut => VT.[Friend]Resolve(&this, hwnd, fFlags);

	public HRESULT SetPath(PSTR pszFile) mut => VT.[Friend]SetPath(&this, pszFile);
}

[CRepr]struct IShellLinkW : IUnknown
{
	public new const Guid IID = .(0x000214f9, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszFile, int32 cch, WIN32_FIND_DATAW* pfd, uint32 fFlags) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) SetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cch) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) SetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszDir, int32 cch) GetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDir) SetWorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszArgs, int32 cch) GetArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArgs) SetArguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16* pwHotkey) GetHotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wHotkey) SetHotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piShowCmd) GetShowCmd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iShowCmd) SetShowCmd;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszIconPath, int32 cch, int32* piIcon) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszIconPath, int32 iIcon) SetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPathRel, uint32 dwReserved) SetRelativePath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 fFlags) Resolve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile) SetPath;
	}


	public HRESULT GetPath(char16* pszFile, int32 cch, WIN32_FIND_DATAW* pfd, uint32 fFlags) mut => VT.[Friend]GetPath(&this, pszFile, cch, pfd, fFlags);

	public HRESULT GetIDList(ITEMIDLIST** ppidl) mut => VT.[Friend]GetIDList(&this, ppidl);

	public HRESULT SetIDList(ITEMIDLIST* pidl) mut => VT.[Friend]SetIDList(&this, pidl);

	public HRESULT GetDescription(char16* pszName, int32 cch) mut => VT.[Friend]GetDescription(&this, pszName, cch);

	public HRESULT SetDescription(PWSTR pszName) mut => VT.[Friend]SetDescription(&this, pszName);

	public HRESULT GetWorkingDirectory(char16* pszDir, int32 cch) mut => VT.[Friend]GetWorkingDirectory(&this, pszDir, cch);

	public HRESULT SetWorkingDirectory(PWSTR pszDir) mut => VT.[Friend]SetWorkingDirectory(&this, pszDir);

	public HRESULT GetArguments(char16* pszArgs, int32 cch) mut => VT.[Friend]GetArguments(&this, pszArgs, cch);

	public HRESULT SetArguments(PWSTR pszArgs) mut => VT.[Friend]SetArguments(&this, pszArgs);

	public HRESULT GetHotkey(uint16* pwHotkey) mut => VT.[Friend]GetHotkey(&this, pwHotkey);

	public HRESULT SetHotkey(uint16 wHotkey) mut => VT.[Friend]SetHotkey(&this, wHotkey);

	public HRESULT GetShowCmd(int32* piShowCmd) mut => VT.[Friend]GetShowCmd(&this, piShowCmd);

	public HRESULT SetShowCmd(int32 iShowCmd) mut => VT.[Friend]SetShowCmd(&this, iShowCmd);

	public HRESULT GetIconLocation(char16* pszIconPath, int32 cch, int32* piIcon) mut => VT.[Friend]GetIconLocation(&this, pszIconPath, cch, piIcon);

	public HRESULT SetIconLocation(PWSTR pszIconPath, int32 iIcon) mut => VT.[Friend]SetIconLocation(&this, pszIconPath, iIcon);

	public HRESULT SetRelativePath(PWSTR pszPathRel, uint32 dwReserved) mut => VT.[Friend]SetRelativePath(&this, pszPathRel, dwReserved);

	public HRESULT Resolve(HWND hwnd, uint32 fFlags) mut => VT.[Friend]Resolve(&this, hwnd, fFlags);

	public HRESULT SetPath(PWSTR pszFile) mut => VT.[Friend]SetPath(&this, pszFile);
}

[CRepr]struct IShellLinkDataList : IUnknown
{
	public new const Guid IID = .(0x45e2b4ae, 0xb1c3, 0x11d0, 0xb9, 0x2f, 0x00, 0xa0, 0xc9, 0x03, 0x12, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pDataBlock) AddDataBlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSig, void** ppDataBlock) CopyDataBlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSig) RemoveDataBlock;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetFlags;
	}


	public HRESULT AddDataBlock(void* pDataBlock) mut => VT.[Friend]AddDataBlock(&this, pDataBlock);

	public HRESULT CopyDataBlock(uint32 dwSig, void** ppDataBlock) mut => VT.[Friend]CopyDataBlock(&this, dwSig, ppDataBlock);

	public HRESULT RemoveDataBlock(uint32 dwSig) mut => VT.[Friend]RemoveDataBlock(&this, dwSig);

	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);

	public HRESULT SetFlags(uint32 dwFlags) mut => VT.[Friend]SetFlags(&this, dwFlags);
}

[CRepr]struct IResolveShellLink : IUnknown
{
	public new const Guid IID = .(0x5cd52983, 0x9449, 0x11d2, 0x96, 0x3a, 0x00, 0xc0, 0x4f, 0x79, 0xad, 0xf0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkLink, HWND hwnd, uint32 fFlags) ResolveShellLink;
	}


	public HRESULT ResolveShellLink(IUnknown* punkLink, HWND hwnd, uint32 fFlags) mut => VT.[Friend]ResolveShellLink(&this, punkLink, hwnd, fFlags);
}

[CRepr]struct IActionProgressDialog : IUnknown
{
	public new const Guid IID = .(0x49ff1172, 0xeadc, 0x446d, 0x92, 0x85, 0x15, 0x64, 0x53, 0xa6, 0x43, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, PWSTR pszTitle, PWSTR pszCancel) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
	}


	public HRESULT Initialize(uint32 flags, PWSTR pszTitle, PWSTR pszCancel) mut => VT.[Friend]Initialize(&this, flags, pszTitle, pszCancel);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);
}

[CRepr]struct IActionProgress : IUnknown
{
	public new const Guid IID = .(0x49ff1173, 0xeadc, 0x446d, 0x92, 0x85, 0x15, 0x64, 0x53, 0xa6, 0x43, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPACTION action, uint32 flags) Begin;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ulCompleted, uint64 ulTotal) UpdateProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPTEXT sptext, PWSTR pszText, BOOL fMayCompact) UpdateText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCancelled) QueryCancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetCancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) End;
	}


	public HRESULT Begin(SPACTION action, uint32 flags) mut => VT.[Friend]Begin(&this, action, flags);

	public HRESULT UpdateProgress(uint64 ulCompleted, uint64 ulTotal) mut => VT.[Friend]UpdateProgress(&this, ulCompleted, ulTotal);

	public HRESULT UpdateText(SPTEXT sptext, PWSTR pszText, BOOL fMayCompact) mut => VT.[Friend]UpdateText(&this, sptext, pszText, fMayCompact);

	public HRESULT QueryCancel(BOOL* pfCancelled) mut => VT.[Friend]QueryCancel(&this, pfCancelled);

	public HRESULT ResetCancel() mut => VT.[Friend]ResetCancel(&this);

	public HRESULT End() mut => VT.[Friend]End(&this);
}

[CRepr]struct IShellExtInit : IUnknown
{
	public new const Guid IID = .(0x000214e8, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlFolder, IDataObject* pdtobj, HKEY hkeyProgID) Initialize;
	}


	public HRESULT Initialize(ITEMIDLIST* pidlFolder, IDataObject* pdtobj, HKEY hkeyProgID) mut => VT.[Friend]Initialize(&this, pidlFolder, pdtobj, hkeyProgID);
}

[CRepr]struct IShellPropSheetExt : IUnknown
{
	public new const Guid IID = .(0x000214e9, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPFNSVADDPROPSHEETPAGE pfnAddPage, LPARAM lParam) AddPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uPageID, LPFNSVADDPROPSHEETPAGE pfnReplaceWith, LPARAM lParam) ReplacePage;
	}


	public HRESULT AddPages(LPFNSVADDPROPSHEETPAGE pfnAddPage, LPARAM lParam) mut => VT.[Friend]AddPages(&this, pfnAddPage, lParam);

	public HRESULT ReplacePage(uint32 uPageID, LPFNSVADDPROPSHEETPAGE pfnReplaceWith, LPARAM lParam) mut => VT.[Friend]ReplacePage(&this, uPageID, pfnReplaceWith, lParam);
}

[CRepr]struct IRemoteComputer : IUnknown
{
	public new const Guid IID = .(0x000214fe, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMachine, BOOL bEnumerating) Initialize;
	}


	public HRESULT Initialize(PWSTR pszMachine, BOOL bEnumerating) mut => VT.[Friend]Initialize(&this, pszMachine, bEnumerating);
}

[CRepr]struct IQueryContinue : IUnknown
{
	public new const Guid IID = .(0x7307055c, 0xb24a, 0x486b, 0x9f, 0x25, 0x16, 0x3e, 0x59, 0x7a, 0x28, 0xa9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) QueryContinue;
	}


	public HRESULT QueryContinue() mut => VT.[Friend]QueryContinue(&this);
}

[CRepr]struct IObjectWithCancelEvent : IUnknown
{
	public new const Guid IID = .(0xf279b885, 0x0ae9, 0x4b85, 0xac, 0x06, 0xdd, 0xec, 0xf9, 0x40, 0x89, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE* phEvent) GetCancelEvent;
	}


	public HRESULT GetCancelEvent(HANDLE* phEvent) mut => VT.[Friend]GetCancelEvent(&this, phEvent);
}

[CRepr]struct IUserNotification : IUnknown
{
	public new const Guid IID = .(0xba9711ba, 0x5893, 0x4787, 0xa7, 0xe1, 0x41, 0x27, 0x71, 0x51, 0x55, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle, PWSTR pszText, uint32 dwInfoFlags) SetBalloonInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwShowTime, uint32 dwInterval, uint32 cRetryCount) SetBalloonRetry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON hIcon, PWSTR pszToolTip) SetIconInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IQueryContinue* pqc, uint32 dwContinuePollInterval) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSoundName) PlaySound;
	}


	public HRESULT SetBalloonInfo(PWSTR pszTitle, PWSTR pszText, uint32 dwInfoFlags) mut => VT.[Friend]SetBalloonInfo(&this, pszTitle, pszText, dwInfoFlags);

	public HRESULT SetBalloonRetry(uint32 dwShowTime, uint32 dwInterval, uint32 cRetryCount) mut => VT.[Friend]SetBalloonRetry(&this, dwShowTime, dwInterval, cRetryCount);

	public HRESULT SetIconInfo(HICON hIcon, PWSTR pszToolTip) mut => VT.[Friend]SetIconInfo(&this, hIcon, pszToolTip);

	public HRESULT Show(IQueryContinue* pqc, uint32 dwContinuePollInterval) mut => VT.[Friend]Show(&this, pqc, dwContinuePollInterval);

	public HRESULT PlaySound(PWSTR pszSoundName) mut => VT.[Friend]PlaySound(&this, pszSoundName);
}

[CRepr]struct IItemNameLimits : IUnknown
{
	public new const Guid IID = .(0x1df0d7f1, 0xb267, 0x4d28, 0x8b, 0x10, 0x12, 0xe2, 0x32, 0x02, 0xa5, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwszValidChars, PWSTR* ppwszInvalidChars) GetValidCharacters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, int32* piMaxNameLen) GetMaxLength;
	}


	public HRESULT GetValidCharacters(PWSTR* ppwszValidChars, PWSTR* ppwszInvalidChars) mut => VT.[Friend]GetValidCharacters(&this, ppwszValidChars, ppwszInvalidChars);

	public HRESULT GetMaxLength(PWSTR pszName, int32* piMaxNameLen) mut => VT.[Friend]GetMaxLength(&this, pszName, piMaxNameLen);
}

[CRepr]struct ISearchFolderItemFactory : IUnknown
{
	public new const Guid IID = .(0xa0ffbc28, 0x5482, 0x4366, 0xbe, 0x27, 0x3e, 0x81, 0xe7, 0x8e, 0x06, 0xc2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDisplayName) SetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid ftid) SetFolderTypeID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERLOGICALVIEWMODE flvm) SetFolderLogicalViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iIconSize) SetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cVisibleColumns, PROPERTYKEY* rgKey) SetVisibleColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cSortColumns, SORTCOLUMN* rgSortColumns) SetSortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* keyGroup) SetGroupColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cStackKeys, PROPERTYKEY* rgStackKeys) SetStacks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiaScope) SetScope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICondition* pCondition) SetCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetShellItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetIDList;
	}


	public HRESULT SetDisplayName(PWSTR pszDisplayName) mut => VT.[Friend]SetDisplayName(&this, pszDisplayName);

	public HRESULT SetFolderTypeID(Guid ftid) mut => VT.[Friend]SetFolderTypeID(&this, ftid);

	public HRESULT SetFolderLogicalViewMode(FOLDERLOGICALVIEWMODE flvm) mut => VT.[Friend]SetFolderLogicalViewMode(&this, flvm);

	public HRESULT SetIconSize(int32 iIconSize) mut => VT.[Friend]SetIconSize(&this, iIconSize);

	public HRESULT SetVisibleColumns(uint32 cVisibleColumns, PROPERTYKEY* rgKey) mut => VT.[Friend]SetVisibleColumns(&this, cVisibleColumns, rgKey);

	public HRESULT SetSortColumns(uint32 cSortColumns, SORTCOLUMN* rgSortColumns) mut => VT.[Friend]SetSortColumns(&this, cSortColumns, rgSortColumns);

	public HRESULT SetGroupColumn(PROPERTYKEY* keyGroup) mut => VT.[Friend]SetGroupColumn(&this, keyGroup);

	public HRESULT SetStacks(uint32 cStackKeys, PROPERTYKEY* rgStackKeys) mut => VT.[Friend]SetStacks(&this, cStackKeys, rgStackKeys);

	public HRESULT SetScope(IShellItemArray* psiaScope) mut => VT.[Friend]SetScope(&this, psiaScope);

	public HRESULT SetCondition(ICondition* pCondition) mut => VT.[Friend]SetCondition(&this, pCondition);

	public HRESULT GetShellItem(in Guid riid, void** ppv) mut => VT.[Friend]GetShellItem(&this, riid, ppv);

	public HRESULT GetIDList(ITEMIDLIST** ppidl) mut => VT.[Friend]GetIDList(&this, ppidl);
}

[CRepr]struct IExtractImage : IUnknown
{
	public new const Guid IID = .(0xbb2e617c, 0x0920, 0x11d1, 0x9a, 0x0b, 0x00, 0xc0, 0x4f, 0xc2, 0xd6, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszPathBuffer, uint32 cch, uint32* pdwPriority, SIZE* prgSize, uint32 dwRecClrDepth, uint32* pdwFlags) GetLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* phBmpThumbnail) Extract;
	}


	public HRESULT GetLocation(char16* pszPathBuffer, uint32 cch, uint32* pdwPriority, SIZE* prgSize, uint32 dwRecClrDepth, uint32* pdwFlags) mut => VT.[Friend]GetLocation(&this, pszPathBuffer, cch, pdwPriority, prgSize, dwRecClrDepth, pdwFlags);

	public HRESULT Extract(HBITMAP* phBmpThumbnail) mut => VT.[Friend]Extract(&this, phBmpThumbnail);
}

[CRepr]struct IExtractImage2 : IExtractImage
{
	public new const Guid IID = .(0x953bb1ee, 0x93b4, 0x11d1, 0x98, 0xa3, 0x00, 0xc0, 0x4f, 0xb6, 0x87, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IExtractImage.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pDateStamp) GetDateStamp;
	}


	public HRESULT GetDateStamp(FILETIME* pDateStamp) mut => VT.[Friend]GetDateStamp(&this, pDateStamp);
}

[CRepr]struct IThumbnailHandlerFactory : IUnknown
{
	public new const Guid IID = .(0xe35b4b2e, 0x00da, 0x4bc1, 0x9f, 0x13, 0x38, 0xbc, 0x11, 0xf5, 0xd4, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlChild, IBindCtx* pbc, in Guid riid, void** ppv) GetThumbnailHandler;
	}


	public HRESULT GetThumbnailHandler(ITEMIDLIST* pidlChild, IBindCtx* pbc, in Guid riid, void** ppv) mut => VT.[Friend]GetThumbnailHandler(&this, pidlChild, pbc, riid, ppv);
}

[CRepr]struct IParentAndItem : IUnknown
{
	public new const Guid IID = .(0xb3a4b685, 0xb685, 0x4805, 0x99, 0xd9, 0x5d, 0xea, 0xd2, 0x87, 0x32, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlParent, IShellFolder* psf, ITEMIDLIST* pidlChild) SetParentAndItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidlParent, IShellFolder** ppsf, ITEMIDLIST** ppidlChild) GetParentAndItem;
	}


	public HRESULT SetParentAndItem(ITEMIDLIST* pidlParent, IShellFolder* psf, ITEMIDLIST* pidlChild) mut => VT.[Friend]SetParentAndItem(&this, pidlParent, psf, pidlChild);

	public HRESULT GetParentAndItem(ITEMIDLIST** ppidlParent, IShellFolder** ppsf, ITEMIDLIST** ppidlChild) mut => VT.[Friend]GetParentAndItem(&this, ppidlParent, ppsf, ppidlChild);
}

[CRepr]struct IDockingWindow : IOleWindow
{
	public new const Guid IID = .(0x012dd920, 0x7b26, 0x11d0, 0x8c, 0xa9, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) ShowDW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved) CloseDW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcBorder, IUnknown* punkToolbarSite, BOOL fReserved) ResizeBorderDW;
	}


	public HRESULT ShowDW(BOOL fShow) mut => VT.[Friend]ShowDW(&this, fShow);

	public HRESULT CloseDW(uint32 dwReserved) mut => VT.[Friend]CloseDW(&this, dwReserved);

	public HRESULT ResizeBorderDW(RECT* prcBorder, IUnknown* punkToolbarSite, BOOL fReserved) mut => VT.[Friend]ResizeBorderDW(&this, prcBorder, punkToolbarSite, fReserved);
}

[CRepr]struct IDeskBand : IDockingWindow
{
	public new const Guid IID = .(0xeb0fe172, 0x1a3a, 0x11d0, 0x89, 0xb3, 0x00, 0xa0, 0xc9, 0x0a, 0x90, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDockingWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID, uint32 dwViewMode, DESKBANDINFO* pdbi) GetBandInfo;
	}


	public HRESULT GetBandInfo(uint32 dwBandID, uint32 dwViewMode, DESKBANDINFO* pdbi) mut => VT.[Friend]GetBandInfo(&this, dwBandID, dwViewMode, pdbi);
}

[CRepr]struct IDeskBandInfo : IUnknown
{
	public new const Guid IID = .(0x77e425fc, 0xcbf9, 0x4307, 0xba, 0x6a, 0xbb, 0x57, 0x27, 0x74, 0x56, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID, uint32 dwViewMode, int32* pnWidth) GetDefaultBandWidth;
	}


	public HRESULT GetDefaultBandWidth(uint32 dwBandID, uint32 dwViewMode, int32* pnWidth) mut => VT.[Friend]GetDefaultBandWidth(&this, dwBandID, dwViewMode, pnWidth);
}

[CRepr]struct ITaskbarList : IUnknown
{
	public new const Guid IID = .(0x56fdf342, 0xfd6d, 0x11d0, 0x95, 0x8a, 0x00, 0x60, 0x97, 0xc9, 0xa0, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) HrInit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) AddTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) DeleteTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) ActivateTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) SetActiveAlt;
	}


	public HRESULT HrInit() mut => VT.[Friend]HrInit(&this);

	public HRESULT AddTab(HWND hwnd) mut => VT.[Friend]AddTab(&this, hwnd);

	public HRESULT DeleteTab(HWND hwnd) mut => VT.[Friend]DeleteTab(&this, hwnd);

	public HRESULT ActivateTab(HWND hwnd) mut => VT.[Friend]ActivateTab(&this, hwnd);

	public HRESULT SetActiveAlt(HWND hwnd) mut => VT.[Friend]SetActiveAlt(&this, hwnd);
}

[CRepr]struct ITaskbarList2 : ITaskbarList
{
	public new const Guid IID = .(0x602d4995, 0xb13a, 0x429b, 0xa6, 0x6e, 0x19, 0x35, 0xe4, 0x4f, 0x43, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITaskbarList.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, BOOL fFullscreen) MarkFullscreenWindow;
	}


	public HRESULT MarkFullscreenWindow(HWND hwnd, BOOL fFullscreen) mut => VT.[Friend]MarkFullscreenWindow(&this, hwnd, fFullscreen);
}

[CRepr]struct ITaskbarList3 : ITaskbarList2
{
	public new const Guid IID = .(0xea1afb91, 0x9e28, 0x4b86, 0x90, 0xe9, 0x9e, 0x9f, 0x8a, 0x5e, 0xef, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITaskbarList2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint64 ullCompleted, uint64 ullTotal) SetProgressValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, TBPFLAG tbpFlags) SetProgressState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTab, HWND hwndMDI) RegisterTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTab) UnregisterTab;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTab, HWND hwndInsertBefore) SetTabOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTab, HWND hwndMDI, uint32 dwReserved) SetTabActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 cButtons, THUMBBUTTON* pButton) ThumbBarAddButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 cButtons, THUMBBUTTON* pButton) ThumbBarUpdateButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, HIMAGELIST himl) ThumbBarSetImageList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, HICON hIcon, PWSTR pszDescription) SetOverlayIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, PWSTR pszTip) SetThumbnailTooltip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, RECT* prcClip) SetThumbnailClip;
	}


	public HRESULT SetProgressValue(HWND hwnd, uint64 ullCompleted, uint64 ullTotal) mut => VT.[Friend]SetProgressValue(&this, hwnd, ullCompleted, ullTotal);

	public HRESULT SetProgressState(HWND hwnd, TBPFLAG tbpFlags) mut => VT.[Friend]SetProgressState(&this, hwnd, tbpFlags);

	public HRESULT RegisterTab(HWND hwndTab, HWND hwndMDI) mut => VT.[Friend]RegisterTab(&this, hwndTab, hwndMDI);

	public HRESULT UnregisterTab(HWND hwndTab) mut => VT.[Friend]UnregisterTab(&this, hwndTab);

	public HRESULT SetTabOrder(HWND hwndTab, HWND hwndInsertBefore) mut => VT.[Friend]SetTabOrder(&this, hwndTab, hwndInsertBefore);

	public HRESULT SetTabActive(HWND hwndTab, HWND hwndMDI, uint32 dwReserved) mut => VT.[Friend]SetTabActive(&this, hwndTab, hwndMDI, dwReserved);

	public HRESULT ThumbBarAddButtons(HWND hwnd, uint32 cButtons, THUMBBUTTON* pButton) mut => VT.[Friend]ThumbBarAddButtons(&this, hwnd, cButtons, pButton);

	public HRESULT ThumbBarUpdateButtons(HWND hwnd, uint32 cButtons, THUMBBUTTON* pButton) mut => VT.[Friend]ThumbBarUpdateButtons(&this, hwnd, cButtons, pButton);

	public HRESULT ThumbBarSetImageList(HWND hwnd, HIMAGELIST himl) mut => VT.[Friend]ThumbBarSetImageList(&this, hwnd, himl);

	public HRESULT SetOverlayIcon(HWND hwnd, HICON hIcon, PWSTR pszDescription) mut => VT.[Friend]SetOverlayIcon(&this, hwnd, hIcon, pszDescription);

	public HRESULT SetThumbnailTooltip(HWND hwnd, PWSTR pszTip) mut => VT.[Friend]SetThumbnailTooltip(&this, hwnd, pszTip);

	public HRESULT SetThumbnailClip(HWND hwnd, RECT* prcClip) mut => VT.[Friend]SetThumbnailClip(&this, hwnd, prcClip);
}

[CRepr]struct ITaskbarList4 : ITaskbarList3
{
	public new const Guid IID = .(0xc43dc798, 0x95d1, 0x4bea, 0x90, 0x30, 0xbb, 0x99, 0xe2, 0x98, 0x3a, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ITaskbarList3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTab, STPFLAG stpFlags) SetTabProperties;
	}


	public HRESULT SetTabProperties(HWND hwndTab, STPFLAG stpFlags) mut => VT.[Friend]SetTabProperties(&this, hwndTab, stpFlags);
}

[CRepr]struct IExplorerBrowserEvents : IUnknown
{
	public new const Guid IID = .(0x361bbdc7, 0xe6ee, 0x4e13, 0xbe, 0x58, 0x58, 0xe2, 0x24, 0x0c, 0x81, 0x0f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlFolder) OnNavigationPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv) OnViewCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlFolder) OnNavigationComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlFolder) OnNavigationFailed;
	}


	public HRESULT OnNavigationPending(ITEMIDLIST* pidlFolder) mut => VT.[Friend]OnNavigationPending(&this, pidlFolder);

	public HRESULT OnViewCreated(IShellView* psv) mut => VT.[Friend]OnViewCreated(&this, psv);

	public HRESULT OnNavigationComplete(ITEMIDLIST* pidlFolder) mut => VT.[Friend]OnNavigationComplete(&this, pidlFolder);

	public HRESULT OnNavigationFailed(ITEMIDLIST* pidlFolder) mut => VT.[Friend]OnNavigationFailed(&this, pidlFolder);
}

[CRepr]struct IExplorerBrowser : IUnknown
{
	public new const Guid IID = .(0xdfd3b6b5, 0xc10c, 0x4be9, 0x85, 0xf6, 0xa6, 0x69, 0x69, 0xf4, 0x02, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, RECT* prc, FOLDERSETTINGS* pfs) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* phdwp, RECT rcBrowser) SetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyBag) SetPropertyBag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszEmptyText) SetEmptyText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERSETTINGS* pfs) SetFolderSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IExplorerBrowserEvents* psbe, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXPLORER_BROWSER_OPTIONS dwFlag) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EXPLORER_BROWSER_OPTIONS* pdwFlag) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 uFlags) BrowseToIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, uint32 uFlags) BrowseToObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, EXPLORER_BROWSER_FILL_FLAGS dwFlags) FillFromObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetCurrentView;
	}


	public HRESULT Initialize(HWND hwndParent, RECT* prc, FOLDERSETTINGS* pfs) mut => VT.[Friend]Initialize(&this, hwndParent, prc, pfs);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT SetRect(int* phdwp, RECT rcBrowser) mut => VT.[Friend]SetRect(&this, phdwp, rcBrowser);

	public HRESULT SetPropertyBag(PWSTR pszPropertyBag) mut => VT.[Friend]SetPropertyBag(&this, pszPropertyBag);

	public HRESULT SetEmptyText(PWSTR pszEmptyText) mut => VT.[Friend]SetEmptyText(&this, pszEmptyText);

	public HRESULT SetFolderSettings(FOLDERSETTINGS* pfs) mut => VT.[Friend]SetFolderSettings(&this, pfs);

	public HRESULT Advise(IExplorerBrowserEvents* psbe, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, psbe, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT SetOptions(EXPLORER_BROWSER_OPTIONS dwFlag) mut => VT.[Friend]SetOptions(&this, dwFlag);

	public HRESULT GetOptions(EXPLORER_BROWSER_OPTIONS* pdwFlag) mut => VT.[Friend]GetOptions(&this, pdwFlag);

	public HRESULT BrowseToIDList(ITEMIDLIST* pidl, uint32 uFlags) mut => VT.[Friend]BrowseToIDList(&this, pidl, uFlags);

	public HRESULT BrowseToObject(IUnknown* punk, uint32 uFlags) mut => VT.[Friend]BrowseToObject(&this, punk, uFlags);

	public HRESULT FillFromObject(IUnknown* punk, EXPLORER_BROWSER_FILL_FLAGS dwFlags) mut => VT.[Friend]FillFromObject(&this, punk, dwFlags);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);

	public HRESULT GetCurrentView(in Guid riid, void** ppv) mut => VT.[Friend]GetCurrentView(&this, riid, ppv);
}

[CRepr]struct IEnumObjects : IUnknown
{
	public new const Guid IID = .(0x2c1c7e2e, 0x2d0e, 0x4059, 0x83, 0x1e, 0x1e, 0x6f, 0x82, 0x33, 0x5c, 0x2e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, in Guid riid, void** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumObjects** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, in Guid riid, void** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, riid, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumObjects** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IOperationsProgressDialog : IUnknown
{
	public new const Guid IID = .(0x0c9fb851, 0xe5c9, 0x43eb, 0xa3, 0x70, 0xf0, 0x67, 0x7b, 0x13, 0x87, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner, uint32 flags) StartProgressDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopProgressDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SPACTION action) SetOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 mode) SetMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullPointsCurrent, uint64 ullPointsTotal, uint64 ullSizeCurrent, uint64 ullSizeTotal, uint64 ullItemsCurrent, uint64 ullItemsTotal) UpdateProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiSource, IShellItem* psiTarget, IShellItem* psiItem) UpdateLocations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PauseTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResumeTimer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64* pullElapsed, uint64* pullRemaining) GetMilliseconds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PDOPSTATUS* popstatus) GetOperationStatus;
	}


	public HRESULT StartProgressDialog(HWND hwndOwner, uint32 flags) mut => VT.[Friend]StartProgressDialog(&this, hwndOwner, flags);

	public HRESULT StopProgressDialog() mut => VT.[Friend]StopProgressDialog(&this);

	public HRESULT SetOperation(SPACTION action) mut => VT.[Friend]SetOperation(&this, action);

	public HRESULT SetMode(uint32 mode) mut => VT.[Friend]SetMode(&this, mode);

	public HRESULT UpdateProgress(uint64 ullPointsCurrent, uint64 ullPointsTotal, uint64 ullSizeCurrent, uint64 ullSizeTotal, uint64 ullItemsCurrent, uint64 ullItemsTotal) mut => VT.[Friend]UpdateProgress(&this, ullPointsCurrent, ullPointsTotal, ullSizeCurrent, ullSizeTotal, ullItemsCurrent, ullItemsTotal);

	public HRESULT UpdateLocations(IShellItem* psiSource, IShellItem* psiTarget, IShellItem* psiItem) mut => VT.[Friend]UpdateLocations(&this, psiSource, psiTarget, psiItem);

	public HRESULT ResetTimer() mut => VT.[Friend]ResetTimer(&this);

	public HRESULT PauseTimer() mut => VT.[Friend]PauseTimer(&this);

	public HRESULT ResumeTimer() mut => VT.[Friend]ResumeTimer(&this);

	public HRESULT GetMilliseconds(uint64* pullElapsed, uint64* pullRemaining) mut => VT.[Friend]GetMilliseconds(&this, pullElapsed, pullRemaining);

	public HRESULT GetOperationStatus(PDOPSTATUS* popstatus) mut => VT.[Friend]GetOperationStatus(&this, popstatus);
}

[CRepr]struct IIOCancelInformation : IUnknown
{
	public new const Guid IID = .(0xf5b0bf81, 0x8cb5, 0x4b1b, 0x94, 0x49, 0x1a, 0x15, 0x9e, 0x0c, 0x73, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwThreadID, uint32 uMsgCancel) SetCancelInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwThreadID, uint32* puMsgCancel) GetCancelInformation;
	}


	public HRESULT SetCancelInformation(uint32 dwThreadID, uint32 uMsgCancel) mut => VT.[Friend]SetCancelInformation(&this, dwThreadID, uMsgCancel);

	public HRESULT GetCancelInformation(uint32* pdwThreadID, uint32* puMsgCancel) mut => VT.[Friend]GetCancelInformation(&this, pdwThreadID, puMsgCancel);
}

[CRepr]struct IFileOperation : IUnknown
{
	public new const Guid IID = .(0x947aab5f, 0x0a5c, 0x4c13, 0xb4, 0xd6, 0x4b, 0xf7, 0x83, 0x6f, 0xc9, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileOperationProgressSink* pfops, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOperationFlags) SetOperationFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszMessage) SetProgressMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOperationsProgressDialog* popd) SetProgressDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyChangeArray* pproparray) SetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner) SetOwnerWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiItem) ApplyPropertiesToItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkItems) ApplyPropertiesToItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiItem, PWSTR pszNewName, IFileOperationProgressSink* pfopsItem) RenameItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnkItems, PWSTR pszNewName) RenameItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, IFileOperationProgressSink* pfopsItem) MoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkItems, IShellItem* psiDestinationFolder) MoveItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszCopyName, IFileOperationProgressSink* pfopsItem) CopyItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkItems, IShellItem* psiDestinationFolder) CopyItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiItem, IFileOperationProgressSink* pfopsItem) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkItems) DeleteItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiDestinationFolder, uint32 dwFileAttributes, PWSTR pszName, PWSTR pszTemplateName, IFileOperationProgressSink* pfopsItem) NewItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PerformOperations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAnyOperationsAborted) GetAnyOperationsAborted;
	}


	public HRESULT Advise(IFileOperationProgressSink* pfops, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pfops, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT SetOperationFlags(uint32 dwOperationFlags) mut => VT.[Friend]SetOperationFlags(&this, dwOperationFlags);

	public HRESULT SetProgressMessage(PWSTR pszMessage) mut => VT.[Friend]SetProgressMessage(&this, pszMessage);

	public HRESULT SetProgressDialog(IOperationsProgressDialog* popd) mut => VT.[Friend]SetProgressDialog(&this, popd);

	public HRESULT SetProperties(IPropertyChangeArray* pproparray) mut => VT.[Friend]SetProperties(&this, pproparray);

	public HRESULT SetOwnerWindow(HWND hwndOwner) mut => VT.[Friend]SetOwnerWindow(&this, hwndOwner);

	public HRESULT ApplyPropertiesToItem(IShellItem* psiItem) mut => VT.[Friend]ApplyPropertiesToItem(&this, psiItem);

	public HRESULT ApplyPropertiesToItems(IUnknown* punkItems) mut => VT.[Friend]ApplyPropertiesToItems(&this, punkItems);

	public HRESULT RenameItem(IShellItem* psiItem, PWSTR pszNewName, IFileOperationProgressSink* pfopsItem) mut => VT.[Friend]RenameItem(&this, psiItem, pszNewName, pfopsItem);

	public HRESULT RenameItems(IUnknown* pUnkItems, PWSTR pszNewName) mut => VT.[Friend]RenameItems(&this, pUnkItems, pszNewName);

	public HRESULT MoveItem(IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszNewName, IFileOperationProgressSink* pfopsItem) mut => VT.[Friend]MoveItem(&this, psiItem, psiDestinationFolder, pszNewName, pfopsItem);

	public HRESULT MoveItems(IUnknown* punkItems, IShellItem* psiDestinationFolder) mut => VT.[Friend]MoveItems(&this, punkItems, psiDestinationFolder);

	public HRESULT CopyItem(IShellItem* psiItem, IShellItem* psiDestinationFolder, PWSTR pszCopyName, IFileOperationProgressSink* pfopsItem) mut => VT.[Friend]CopyItem(&this, psiItem, psiDestinationFolder, pszCopyName, pfopsItem);

	public HRESULT CopyItems(IUnknown* punkItems, IShellItem* psiDestinationFolder) mut => VT.[Friend]CopyItems(&this, punkItems, psiDestinationFolder);

	public HRESULT DeleteItem(IShellItem* psiItem, IFileOperationProgressSink* pfopsItem) mut => VT.[Friend]DeleteItem(&this, psiItem, pfopsItem);

	public HRESULT DeleteItems(IUnknown* punkItems) mut => VT.[Friend]DeleteItems(&this, punkItems);

	public HRESULT NewItem(IShellItem* psiDestinationFolder, uint32 dwFileAttributes, PWSTR pszName, PWSTR pszTemplateName, IFileOperationProgressSink* pfopsItem) mut => VT.[Friend]NewItem(&this, psiDestinationFolder, dwFileAttributes, pszName, pszTemplateName, pfopsItem);

	public HRESULT PerformOperations() mut => VT.[Friend]PerformOperations(&this);

	public HRESULT GetAnyOperationsAborted(BOOL* pfAnyOperationsAborted) mut => VT.[Friend]GetAnyOperationsAborted(&this, pfAnyOperationsAborted);
}

[CRepr]struct IFileOperation2 : IFileOperation
{
	public new const Guid IID = .(0xcd8f23c1, 0x8f61, 0x4916, 0x90, 0x9d, 0x55, 0xbd, 0xd0, 0x91, 0x87, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFileOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILE_OPERATION_FLAGS2 operationFlags2) SetOperationFlags2;
	}


	public HRESULT SetOperationFlags2(FILE_OPERATION_FLAGS2 operationFlags2) mut => VT.[Friend]SetOperationFlags2(&this, operationFlags2);
}

[CRepr]struct IObjectProvider : IUnknown
{
	public new const Guid IID = .(0xa6087428, 0x3be3, 0x4d73, 0xb3, 0x08, 0x7c, 0x04, 0xa5, 0x40, 0xbf, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidObject, in Guid riid, void** ppvOut) QueryObject;
	}


	public HRESULT QueryObject(in Guid guidObject, in Guid riid, void** ppvOut) mut => VT.[Friend]QueryObject(&this, guidObject, riid, ppvOut);
}

[CRepr]struct INamespaceWalkCB : IUnknown
{
	public new const Guid IID = .(0xd92995f8, 0xcf5e, 0x4a76, 0xbf, 0x59, 0xea, 0xd3, 0x9e, 0xa2, 0xb9, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidl) FoundItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidl) EnterFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidl) LeaveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTitle, PWSTR* ppszCancel) InitializeProgressDialog;
	}


	public HRESULT FoundItem(IShellFolder* psf, ITEMIDLIST* pidl) mut => VT.[Friend]FoundItem(&this, psf, pidl);

	public HRESULT EnterFolder(IShellFolder* psf, ITEMIDLIST* pidl) mut => VT.[Friend]EnterFolder(&this, psf, pidl);

	public HRESULT LeaveFolder(IShellFolder* psf, ITEMIDLIST* pidl) mut => VT.[Friend]LeaveFolder(&this, psf, pidl);

	public HRESULT InitializeProgressDialog(PWSTR* ppszTitle, PWSTR* ppszCancel) mut => VT.[Friend]InitializeProgressDialog(&this, ppszTitle, ppszCancel);
}

[CRepr]struct INamespaceWalkCB2 : INamespaceWalkCB
{
	public new const Guid IID = .(0x7ac7492b, 0xc38e, 0x438a, 0x87, 0xdb, 0x68, 0x73, 0x78, 0x44, 0xff, 0x70);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INamespaceWalkCB.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) WalkComplete;
	}


	public HRESULT WalkComplete(HRESULT hr) mut => VT.[Friend]WalkComplete(&this, hr);
}

[CRepr]struct INamespaceWalk : IUnknown
{
	public new const Guid IID = .(0x57ced8a7, 0x3f4a, 0x432c, 0x93, 0x50, 0x30, 0xf2, 0x44, 0x83, 0xf7, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkToWalk, uint32 dwFlags, int32 cDepth, INamespaceWalkCB* pnswcb) Walk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcItems, ITEMIDLIST*** prgpidl) GetIDArrayResult;
	}


	public HRESULT Walk(IUnknown* punkToWalk, uint32 dwFlags, int32 cDepth, INamespaceWalkCB* pnswcb) mut => VT.[Friend]Walk(&this, punkToWalk, dwFlags, cDepth, pnswcb);

	public HRESULT GetIDArrayResult(uint32* pcItems, ITEMIDLIST*** prgpidl) mut => VT.[Friend]GetIDArrayResult(&this, pcItems, prgpidl);
}

[CRepr]struct IBandSite : IUnknown
{
	public new const Guid IID = .(0x4cf504b0, 0xde96, 0x11d0, 0x8b, 0x3f, 0x00, 0xa0, 0xc9, 0x11, 0xe8, 0xe5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) AddBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uBand, uint32* pdwBandID) EnumBands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID, IDeskBand** ppstb, uint32* pdwState, char16* pszName, int32 cchName) QueryBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID, uint32 dwMask, uint32 dwState) SetBandState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID) RemoveBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwBandID, in Guid riid, void** ppv) GetBandObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BANDSITEINFO* pbsinfo) SetBandSiteInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BANDSITEINFO* pbsinfo) GetBandSiteInfo;
	}


	public HRESULT AddBand(IUnknown* punk) mut => VT.[Friend]AddBand(&this, punk);

	public HRESULT EnumBands(uint32 uBand, uint32* pdwBandID) mut => VT.[Friend]EnumBands(&this, uBand, pdwBandID);

	public HRESULT QueryBand(uint32 dwBandID, IDeskBand** ppstb, uint32* pdwState, char16* pszName, int32 cchName) mut => VT.[Friend]QueryBand(&this, dwBandID, ppstb, pdwState, pszName, cchName);

	public HRESULT SetBandState(uint32 dwBandID, uint32 dwMask, uint32 dwState) mut => VT.[Friend]SetBandState(&this, dwBandID, dwMask, dwState);

	public HRESULT RemoveBand(uint32 dwBandID) mut => VT.[Friend]RemoveBand(&this, dwBandID);

	public HRESULT GetBandObject(uint32 dwBandID, in Guid riid, void** ppv) mut => VT.[Friend]GetBandObject(&this, dwBandID, riid, ppv);

	public HRESULT SetBandSiteInfo(BANDSITEINFO* pbsinfo) mut => VT.[Friend]SetBandSiteInfo(&this, pbsinfo);

	public HRESULT GetBandSiteInfo(BANDSITEINFO* pbsinfo) mut => VT.[Friend]GetBandSiteInfo(&this, pbsinfo);
}

[CRepr]struct IModalWindow : IUnknown
{
	public new const Guid IID = .(0xb4db1657, 0x70d7, 0x485e, 0x8e, 0x3e, 0x6f, 0xcb, 0x5a, 0x5c, 0x18, 0x02);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner) Show;
	}


	public HRESULT Show(HWND hwndOwner) mut => VT.[Friend]Show(&this, hwndOwner);
}

[CRepr]struct IContextMenuSite : IUnknown
{
	public new const Guid IID = .(0x0811aebe, 0x0b87, 0x4c54, 0x9e, 0x72, 0x54, 0x8c, 0xf6, 0x49, 0x01, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkContextMenu, uint32 fFlags, POINT pt) DoContextMenuPopup;
	}


	public HRESULT DoContextMenuPopup(IUnknown* punkContextMenu, uint32 fFlags, POINT pt) mut => VT.[Friend]DoContextMenuPopup(&this, punkContextMenu, fFlags, pt);
}

[CRepr]struct IMenuBand : IUnknown
{
	public new const Guid IID = .(0x568804cd, 0xcbd7, 0x11d0, 0x98, 0x16, 0x00, 0xc0, 0x4f, 0xd9, 0x19, 0x72);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg) IsMenuMessage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg, LRESULT* plRet) TranslateMenuMessage;
	}


	public HRESULT IsMenuMessage(MSG* pmsg) mut => VT.[Friend]IsMenuMessage(&this, pmsg);

	public HRESULT TranslateMenuMessage(MSG* pmsg, LRESULT* plRet) mut => VT.[Friend]TranslateMenuMessage(&this, pmsg, plRet);
}

[CRepr]struct IRegTreeItem : IUnknown
{
	public new const Guid IID = .(0xa9521922, 0x0812, 0x4d44, 0x9e, 0xc3, 0x7f, 0xd3, 0x8c, 0x72, 0x6f, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbCheck) GetCheckState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bCheck) SetCheckState;
	}


	public HRESULT GetCheckState(BOOL* pbCheck) mut => VT.[Friend]GetCheckState(&this, pbCheck);

	public HRESULT SetCheckState(BOOL bCheck) mut => VT.[Friend]SetCheckState(&this, bCheck);
}

[CRepr]struct IDeskBar : IOleWindow
{
	public new const Guid IID = .(0xeb0fe173, 0x1a3a, 0x11d0, 0x89, 0xb3, 0x00, 0xa0, 0xc9, 0x0a, 0x90, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkClient) SetClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunkClient) GetClient;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) OnPosRectChangeDB;
	}


	public HRESULT SetClient(IUnknown* punkClient) mut => VT.[Friend]SetClient(&this, punkClient);

	public HRESULT GetClient(IUnknown** ppunkClient) mut => VT.[Friend]GetClient(&this, ppunkClient);

	public HRESULT OnPosRectChangeDB(RECT* prc) mut => VT.[Friend]OnPosRectChangeDB(&this, prc);
}

[CRepr]struct IMenuPopup : IDeskBar
{
	public new const Guid IID = .(0xd1e7afeb, 0x6a2e, 0x11d0, 0x8c, 0x78, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDeskBar.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINTL* ppt, RECTL* prcExclude, int32 dwFlags) Popup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSelectType) OnSelect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMenuPopup* pmp, BOOL fSet) SetSubMenu;
	}


	public HRESULT Popup(POINTL* ppt, RECTL* prcExclude, int32 dwFlags) mut => VT.[Friend]Popup(&this, ppt, prcExclude, dwFlags);

	public HRESULT OnSelect(uint32 dwSelectType) mut => VT.[Friend]OnSelect(&this, dwSelectType);

	public HRESULT SetSubMenu(IMenuPopup* pmp, BOOL fSet) mut => VT.[Friend]SetSubMenu(&this, pmp, fSet);
}

[CRepr]struct IFileIsInUse : IUnknown
{
	public new const Guid IID = .(0x64a1cbf0, 0x3a1a, 0x4461, 0x91, 0x58, 0x37, 0x69, 0x69, 0x69, 0x39, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetAppName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILE_USAGE_TYPE* pfut) GetUsage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCapFlags) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetSwitchToHWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CloseFile;
	}


	public HRESULT GetAppName(PWSTR* ppszName) mut => VT.[Friend]GetAppName(&this, ppszName);

	public HRESULT GetUsage(FILE_USAGE_TYPE* pfut) mut => VT.[Friend]GetUsage(&this, pfut);

	public HRESULT GetCapabilities(uint32* pdwCapFlags) mut => VT.[Friend]GetCapabilities(&this, pdwCapFlags);

	public HRESULT GetSwitchToHWND(HWND* phwnd) mut => VT.[Friend]GetSwitchToHWND(&this, phwnd);

	public HRESULT CloseFile() mut => VT.[Friend]CloseFile(&this);
}

[CRepr]struct IFileDialogEvents : IUnknown
{
	public new const Guid IID = .(0x973510db, 0x7d7f, 0x452b, 0x89, 0x75, 0x74, 0xa8, 0x58, 0x28, 0xd3, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd) OnFileOk;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd, IShellItem* psiFolder) OnFolderChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd) OnFolderChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd) OnSelectionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd, IShellItem* psi, FDE_SHAREVIOLATION_RESPONSE* pResponse) OnShareViolation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd) OnTypeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialog* pfd, IShellItem* psi, FDE_OVERWRITE_RESPONSE* pResponse) OnOverwrite;
	}


	public HRESULT OnFileOk(IFileDialog* pfd) mut => VT.[Friend]OnFileOk(&this, pfd);

	public HRESULT OnFolderChanging(IFileDialog* pfd, IShellItem* psiFolder) mut => VT.[Friend]OnFolderChanging(&this, pfd, psiFolder);

	public HRESULT OnFolderChange(IFileDialog* pfd) mut => VT.[Friend]OnFolderChange(&this, pfd);

	public HRESULT OnSelectionChange(IFileDialog* pfd) mut => VT.[Friend]OnSelectionChange(&this, pfd);

	public HRESULT OnShareViolation(IFileDialog* pfd, IShellItem* psi, FDE_SHAREVIOLATION_RESPONSE* pResponse) mut => VT.[Friend]OnShareViolation(&this, pfd, psi, pResponse);

	public HRESULT OnTypeChange(IFileDialog* pfd) mut => VT.[Friend]OnTypeChange(&this, pfd);

	public HRESULT OnOverwrite(IFileDialog* pfd, IShellItem* psi, FDE_OVERWRITE_RESPONSE* pResponse) mut => VT.[Friend]OnOverwrite(&this, pfd, psi, pResponse);
}

[CRepr]struct IFileDialog : IModalWindow
{
	public new const Guid IID = .(0x42f85136, 0xdb7e, 0x439c, 0x85, 0xf1, 0xe4, 0x07, 0x5d, 0x13, 0x5f, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IModalWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cFileTypes, COMDLG_FILTERSPEC* rgFilterSpec) SetFileTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iFileType) SetFileTypeIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* piFileType) GetFileTypeIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialogEvents* pfde, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILEOPENDIALOGOPTIONS fos) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILEOPENDIALOGOPTIONS* pfos) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) SetDefaultFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) SetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem** ppsi) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem** ppsi) GetCurrentSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) SetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* pszName) GetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszText) SetOkButtonLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLabel) SetFileNameLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem** ppsi) GetResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, FDAP fdap) AddPlace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDefaultExtension) SetDefaultExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid) SetClientGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearClientData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemFilter* pFilter) SetFilter;
	}


	public HRESULT SetFileTypes(uint32 cFileTypes, COMDLG_FILTERSPEC* rgFilterSpec) mut => VT.[Friend]SetFileTypes(&this, cFileTypes, rgFilterSpec);

	public HRESULT SetFileTypeIndex(uint32 iFileType) mut => VT.[Friend]SetFileTypeIndex(&this, iFileType);

	public HRESULT GetFileTypeIndex(uint32* piFileType) mut => VT.[Friend]GetFileTypeIndex(&this, piFileType);

	public HRESULT Advise(IFileDialogEvents* pfde, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pfde, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT SetOptions(FILEOPENDIALOGOPTIONS fos) mut => VT.[Friend]SetOptions(&this, fos);

	public HRESULT GetOptions(FILEOPENDIALOGOPTIONS* pfos) mut => VT.[Friend]GetOptions(&this, pfos);

	public HRESULT SetDefaultFolder(IShellItem* psi) mut => VT.[Friend]SetDefaultFolder(&this, psi);

	public HRESULT SetFolder(IShellItem* psi) mut => VT.[Friend]SetFolder(&this, psi);

	public HRESULT GetFolder(IShellItem** ppsi) mut => VT.[Friend]GetFolder(&this, ppsi);

	public HRESULT GetCurrentSelection(IShellItem** ppsi) mut => VT.[Friend]GetCurrentSelection(&this, ppsi);

	public HRESULT SetFileName(PWSTR pszName) mut => VT.[Friend]SetFileName(&this, pszName);

	public HRESULT GetFileName(PWSTR* pszName) mut => VT.[Friend]GetFileName(&this, pszName);

	public HRESULT SetTitle(PWSTR pszTitle) mut => VT.[Friend]SetTitle(&this, pszTitle);

	public HRESULT SetOkButtonLabel(PWSTR pszText) mut => VT.[Friend]SetOkButtonLabel(&this, pszText);

	public HRESULT SetFileNameLabel(PWSTR pszLabel) mut => VT.[Friend]SetFileNameLabel(&this, pszLabel);

	public HRESULT GetResult(IShellItem** ppsi) mut => VT.[Friend]GetResult(&this, ppsi);

	public HRESULT AddPlace(IShellItem* psi, FDAP fdap) mut => VT.[Friend]AddPlace(&this, psi, fdap);

	public HRESULT SetDefaultExtension(PWSTR pszDefaultExtension) mut => VT.[Friend]SetDefaultExtension(&this, pszDefaultExtension);

	public HRESULT Close(HRESULT hr) mut => VT.[Friend]Close(&this, hr);

	public HRESULT SetClientGuid(in Guid guid) mut => VT.[Friend]SetClientGuid(&this, guid);

	public HRESULT ClearClientData() mut => VT.[Friend]ClearClientData(&this);

	public HRESULT SetFilter(IShellItemFilter* pFilter) mut => VT.[Friend]SetFilter(&this, pFilter);
}

[CRepr]struct IFileSaveDialog : IFileDialog
{
	public new const Guid IID = .(0x84bccd23, 0x5fde, 0x4cdb, 0xae, 0xa4, 0xaf, 0x64, 0xb8, 0x3d, 0x78, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFileDialog.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) SetSaveAsItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pStore) SetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyDescriptionList* pList, BOOL fAppendDefault) SetCollectedProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore** ppStore) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, IPropertyStore* pStore, HWND hwnd, IFileOperationProgressSink* pSink) ApplyProperties;
	}


	public HRESULT SetSaveAsItem(IShellItem* psi) mut => VT.[Friend]SetSaveAsItem(&this, psi);

	public HRESULT SetProperties(IPropertyStore* pStore) mut => VT.[Friend]SetProperties(&this, pStore);

	public HRESULT SetCollectedProperties(IPropertyDescriptionList* pList, BOOL fAppendDefault) mut => VT.[Friend]SetCollectedProperties(&this, pList, fAppendDefault);

	public HRESULT GetProperties(IPropertyStore** ppStore) mut => VT.[Friend]GetProperties(&this, ppStore);

	public HRESULT ApplyProperties(IShellItem* psi, IPropertyStore* pStore, HWND hwnd, IFileOperationProgressSink* pSink) mut => VT.[Friend]ApplyProperties(&this, psi, pStore, hwnd, pSink);
}

[CRepr]struct IFileOpenDialog : IFileDialog
{
	public new const Guid IID = .(0xd57c7288, 0xd4ad, 0x4768, 0xbe, 0x02, 0x9d, 0x96, 0x95, 0x32, 0xd9, 0x60);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFileDialog.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray** ppenum) GetResults;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray** ppsai) GetSelectedItems;
	}


	public HRESULT GetResults(IShellItemArray** ppenum) mut => VT.[Friend]GetResults(&this, ppenum);

	public HRESULT GetSelectedItems(IShellItemArray** ppsai) mut => VT.[Friend]GetSelectedItems(&this, ppsai);
}

[CRepr]struct IFileDialogCustomize : IUnknown
{
	public new const Guid IID = .(0xe6fdd21a, 0x163f, 0x4975, 0x9c, 0x8c, 0xa6, 0x9f, 0x1b, 0xa3, 0x70, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) EnableOpenDropDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszLabel) AddMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszLabel) AddPushButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) AddComboBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) AddRadioButtonList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszLabel, BOOL bChecked) AddCheckButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszText) AddEditBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) AddSeparator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszText) AddText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszLabel) SetControlLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, CDCONTROLSTATEF* pdwState) GetControlState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, CDCONTROLSTATEF dwState) SetControlState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint16** ppszText) GetEditBoxText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszText) SetEditBoxText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, BOOL* pbChecked) GetCheckButtonState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, BOOL bChecked) SetCheckButtonState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem, PWSTR pszLabel) AddControlItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem) RemoveControlItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) RemoveAllControlItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem, CDCONTROLSTATEF* pdwState) GetControlItemState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem, CDCONTROLSTATEF dwState) SetControlItemState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32* pdwIDItem) GetSelectedControlItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem) SetSelectedControlItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, PWSTR pszLabel) StartVisualGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndVisualGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl) MakeProminent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIDCtl, uint32 dwIDItem, PWSTR pszLabel) SetControlItemText;
	}


	public HRESULT EnableOpenDropDown(uint32 dwIDCtl) mut => VT.[Friend]EnableOpenDropDown(&this, dwIDCtl);

	public HRESULT AddMenu(uint32 dwIDCtl, PWSTR pszLabel) mut => VT.[Friend]AddMenu(&this, dwIDCtl, pszLabel);

	public HRESULT AddPushButton(uint32 dwIDCtl, PWSTR pszLabel) mut => VT.[Friend]AddPushButton(&this, dwIDCtl, pszLabel);

	public HRESULT AddComboBox(uint32 dwIDCtl) mut => VT.[Friend]AddComboBox(&this, dwIDCtl);

	public HRESULT AddRadioButtonList(uint32 dwIDCtl) mut => VT.[Friend]AddRadioButtonList(&this, dwIDCtl);

	public HRESULT AddCheckButton(uint32 dwIDCtl, PWSTR pszLabel, BOOL bChecked) mut => VT.[Friend]AddCheckButton(&this, dwIDCtl, pszLabel, bChecked);

	public HRESULT AddEditBox(uint32 dwIDCtl, PWSTR pszText) mut => VT.[Friend]AddEditBox(&this, dwIDCtl, pszText);

	public HRESULT AddSeparator(uint32 dwIDCtl) mut => VT.[Friend]AddSeparator(&this, dwIDCtl);

	public HRESULT AddText(uint32 dwIDCtl, PWSTR pszText) mut => VT.[Friend]AddText(&this, dwIDCtl, pszText);

	public HRESULT SetControlLabel(uint32 dwIDCtl, PWSTR pszLabel) mut => VT.[Friend]SetControlLabel(&this, dwIDCtl, pszLabel);

	public HRESULT GetControlState(uint32 dwIDCtl, CDCONTROLSTATEF* pdwState) mut => VT.[Friend]GetControlState(&this, dwIDCtl, pdwState);

	public HRESULT SetControlState(uint32 dwIDCtl, CDCONTROLSTATEF dwState) mut => VT.[Friend]SetControlState(&this, dwIDCtl, dwState);

	public HRESULT GetEditBoxText(uint32 dwIDCtl, uint16** ppszText) mut => VT.[Friend]GetEditBoxText(&this, dwIDCtl, ppszText);

	public HRESULT SetEditBoxText(uint32 dwIDCtl, PWSTR pszText) mut => VT.[Friend]SetEditBoxText(&this, dwIDCtl, pszText);

	public HRESULT GetCheckButtonState(uint32 dwIDCtl, BOOL* pbChecked) mut => VT.[Friend]GetCheckButtonState(&this, dwIDCtl, pbChecked);

	public HRESULT SetCheckButtonState(uint32 dwIDCtl, BOOL bChecked) mut => VT.[Friend]SetCheckButtonState(&this, dwIDCtl, bChecked);

	public HRESULT AddControlItem(uint32 dwIDCtl, uint32 dwIDItem, PWSTR pszLabel) mut => VT.[Friend]AddControlItem(&this, dwIDCtl, dwIDItem, pszLabel);

	public HRESULT RemoveControlItem(uint32 dwIDCtl, uint32 dwIDItem) mut => VT.[Friend]RemoveControlItem(&this, dwIDCtl, dwIDItem);

	public HRESULT RemoveAllControlItems(uint32 dwIDCtl) mut => VT.[Friend]RemoveAllControlItems(&this, dwIDCtl);

	public HRESULT GetControlItemState(uint32 dwIDCtl, uint32 dwIDItem, CDCONTROLSTATEF* pdwState) mut => VT.[Friend]GetControlItemState(&this, dwIDCtl, dwIDItem, pdwState);

	public HRESULT SetControlItemState(uint32 dwIDCtl, uint32 dwIDItem, CDCONTROLSTATEF dwState) mut => VT.[Friend]SetControlItemState(&this, dwIDCtl, dwIDItem, dwState);

	public HRESULT GetSelectedControlItem(uint32 dwIDCtl, uint32* pdwIDItem) mut => VT.[Friend]GetSelectedControlItem(&this, dwIDCtl, pdwIDItem);

	public HRESULT SetSelectedControlItem(uint32 dwIDCtl, uint32 dwIDItem) mut => VT.[Friend]SetSelectedControlItem(&this, dwIDCtl, dwIDItem);

	public HRESULT StartVisualGroup(uint32 dwIDCtl, PWSTR pszLabel) mut => VT.[Friend]StartVisualGroup(&this, dwIDCtl, pszLabel);

	public HRESULT EndVisualGroup() mut => VT.[Friend]EndVisualGroup(&this);

	public HRESULT MakeProminent(uint32 dwIDCtl) mut => VT.[Friend]MakeProminent(&this, dwIDCtl);

	public HRESULT SetControlItemText(uint32 dwIDCtl, uint32 dwIDItem, PWSTR pszLabel) mut => VT.[Friend]SetControlItemText(&this, dwIDCtl, dwIDItem, pszLabel);
}

[CRepr]struct IApplicationAssociationRegistration : IUnknown
{
	public new const Guid IID = .(0x4e530b0a, 0xe611, 0x4c77, 0xa3, 0xac, 0x90, 0x31, 0xd0, 0x22, 0x28, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszQuery, ASSOCIATIONTYPE atQueryType, ASSOCIATIONLEVEL alQueryLevel, PWSTR* ppszAssociation) QueryCurrentDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszQuery, ASSOCIATIONTYPE atQueryType, ASSOCIATIONLEVEL alQueryLevel, PWSTR pszAppRegistryName, BOOL* pfDefault) QueryAppIsDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ASSOCIATIONLEVEL alQueryLevel, PWSTR pszAppRegistryName, BOOL* pfDefault) QueryAppIsDefaultAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppRegistryName, PWSTR pszSet, ASSOCIATIONTYPE atSetType) SetAppAsDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppRegistryName) SetAppAsDefaultAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearUserAssociations;
	}


	public HRESULT QueryCurrentDefault(PWSTR pszQuery, ASSOCIATIONTYPE atQueryType, ASSOCIATIONLEVEL alQueryLevel, PWSTR* ppszAssociation) mut => VT.[Friend]QueryCurrentDefault(&this, pszQuery, atQueryType, alQueryLevel, ppszAssociation);

	public HRESULT QueryAppIsDefault(PWSTR pszQuery, ASSOCIATIONTYPE atQueryType, ASSOCIATIONLEVEL alQueryLevel, PWSTR pszAppRegistryName, BOOL* pfDefault) mut => VT.[Friend]QueryAppIsDefault(&this, pszQuery, atQueryType, alQueryLevel, pszAppRegistryName, pfDefault);

	public HRESULT QueryAppIsDefaultAll(ASSOCIATIONLEVEL alQueryLevel, PWSTR pszAppRegistryName, BOOL* pfDefault) mut => VT.[Friend]QueryAppIsDefaultAll(&this, alQueryLevel, pszAppRegistryName, pfDefault);

	public HRESULT SetAppAsDefault(PWSTR pszAppRegistryName, PWSTR pszSet, ASSOCIATIONTYPE atSetType) mut => VT.[Friend]SetAppAsDefault(&this, pszAppRegistryName, pszSet, atSetType);

	public HRESULT SetAppAsDefaultAll(PWSTR pszAppRegistryName) mut => VT.[Friend]SetAppAsDefaultAll(&this, pszAppRegistryName);

	public HRESULT ClearUserAssociations() mut => VT.[Friend]ClearUserAssociations(&this);
}

[CRepr]struct IDelegateFolder : IUnknown
{
	public new const Guid IID = .(0xadd8ba80, 0x002b, 0x11d0, 0x8f, 0x0f, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMalloc* pmalloc) SetItemAlloc;
	}


	public HRESULT SetItemAlloc(IMalloc* pmalloc) mut => VT.[Friend]SetItemAlloc(&this, pmalloc);
}

[CRepr]struct IBrowserFrameOptions : IUnknown
{
	public new const Guid IID = .(0x10df43c8, 0x1dbe, 0x11d3, 0x8b, 0x34, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMask, uint32* pdwOptions) GetFrameOptions;
	}


	public HRESULT GetFrameOptions(uint32 dwMask, uint32* pdwOptions) mut => VT.[Friend]GetFrameOptions(&this, dwMask, pdwOptions);
}

[CRepr]struct INewWindowManager : IUnknown
{
	public new const Guid IID = .(0xd2bc4c84, 0x3f72, 0x4a52, 0xa6, 0x04, 0x7b, 0xcb, 0xf3, 0x98, 0x2c, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrl, PWSTR pszName, PWSTR pszUrlContext, PWSTR pszFeatures, BOOL fReplace, uint32 dwFlags, uint32 dwUserActionTime) EvaluateNewWindow;
	}


	public HRESULT EvaluateNewWindow(PWSTR pszUrl, PWSTR pszName, PWSTR pszUrlContext, PWSTR pszFeatures, BOOL fReplace, uint32 dwFlags, uint32 dwUserActionTime) mut => VT.[Friend]EvaluateNewWindow(&this, pszUrl, pszName, pszUrlContext, pszFeatures, fReplace, dwFlags, dwUserActionTime);
}

[CRepr]struct IAttachmentExecute : IUnknown
{
	public new const Guid IID = .(0x73db1241, 0x1e85, 0x4581, 0x8e, 0x4f, 0xa8, 0x1e, 0x1d, 0x0f, 0x8c, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetClientTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guid) SetClientGuid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLocalPath) SetLocalPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFileName) SetFileName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSource) SetSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszReferrer) SetReferrer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CheckPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, ATTACHMENT_PROMPT prompt, ATTACHMENT_ACTION* paction) Prompt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, PWSTR pszVerb, HANDLE* phProcess) Execute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) SaveWithUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ClearClientState;
	}


	public HRESULT SetClientTitle(PWSTR pszTitle) mut => VT.[Friend]SetClientTitle(&this, pszTitle);

	public HRESULT SetClientGuid(in Guid guid) mut => VT.[Friend]SetClientGuid(&this, guid);

	public HRESULT SetLocalPath(PWSTR pszLocalPath) mut => VT.[Friend]SetLocalPath(&this, pszLocalPath);

	public HRESULT SetFileName(PWSTR pszFileName) mut => VT.[Friend]SetFileName(&this, pszFileName);

	public HRESULT SetSource(PWSTR pszSource) mut => VT.[Friend]SetSource(&this, pszSource);

	public HRESULT SetReferrer(PWSTR pszReferrer) mut => VT.[Friend]SetReferrer(&this, pszReferrer);

	public HRESULT CheckPolicy() mut => VT.[Friend]CheckPolicy(&this);

	public HRESULT Prompt(HWND hwnd, ATTACHMENT_PROMPT prompt, ATTACHMENT_ACTION* paction) mut => VT.[Friend]Prompt(&this, hwnd, prompt, paction);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT Execute(HWND hwnd, PWSTR pszVerb, HANDLE* phProcess) mut => VT.[Friend]Execute(&this, hwnd, pszVerb, phProcess);

	public HRESULT SaveWithUI(HWND hwnd) mut => VT.[Friend]SaveWithUI(&this, hwnd);

	public HRESULT ClearClientState() mut => VT.[Friend]ClearClientState(&this);
}

[CRepr]struct IShellMenuCallback : IUnknown
{
	public new const Guid IID = .(0x4ca300a1, 0x9b8d, 0x11d1, 0x8b, 0x22, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SMDATA* psmd, uint32 uMsg, WPARAM wParam, LPARAM lParam) CallbackSM;
	}


	public HRESULT CallbackSM(SMDATA* psmd, uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]CallbackSM(&this, psmd, uMsg, wParam, lParam);
}

[CRepr]struct IShellMenu : IUnknown
{
	public new const Guid IID = .(0xee1f7637, 0xe138, 0x11d1, 0x83, 0x79, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellMenuCallback* psmc, uint32 uId, uint32 uIdAncestor, uint32 dwFlags) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellMenuCallback** ppsmc, uint32* puId, uint32* puIdAncestor, uint32* pdwFlags) GetMenuInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidlFolder, HKEY hKey, uint32 dwFlags) SetShellFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags, ITEMIDLIST** ppidl, in Guid riid, void** ppv) GetShellFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU hmenu, HWND hwnd, uint32 dwFlags) SetMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMENU* phmenu, HWND* phwnd, uint32* pdwFlags) GetMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SMDATA* psmd, uint32 dwFlags) InvalidateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SMDATA* psmd) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, uint32 dwFlags) SetMenuToolbar;
	}


	public HRESULT Initialize(IShellMenuCallback* psmc, uint32 uId, uint32 uIdAncestor, uint32 dwFlags) mut => VT.[Friend]Initialize(&this, psmc, uId, uIdAncestor, dwFlags);

	public HRESULT GetMenuInfo(IShellMenuCallback** ppsmc, uint32* puId, uint32* puIdAncestor, uint32* pdwFlags) mut => VT.[Friend]GetMenuInfo(&this, ppsmc, puId, puIdAncestor, pdwFlags);

	public HRESULT SetShellFolder(IShellFolder* psf, ITEMIDLIST* pidlFolder, HKEY hKey, uint32 dwFlags) mut => VT.[Friend]SetShellFolder(&this, psf, pidlFolder, hKey, dwFlags);

	public HRESULT GetShellFolder(uint32* pdwFlags, ITEMIDLIST** ppidl, in Guid riid, void** ppv) mut => VT.[Friend]GetShellFolder(&this, pdwFlags, ppidl, riid, ppv);

	public HRESULT SetMenu(HMENU hmenu, HWND hwnd, uint32 dwFlags) mut => VT.[Friend]SetMenu(&this, hmenu, hwnd, dwFlags);

	public HRESULT GetMenu(HMENU* phmenu, HWND* phwnd, uint32* pdwFlags) mut => VT.[Friend]GetMenu(&this, phmenu, phwnd, pdwFlags);

	public HRESULT InvalidateItem(SMDATA* psmd, uint32 dwFlags) mut => VT.[Friend]InvalidateItem(&this, psmd, dwFlags);

	public HRESULT GetState(SMDATA* psmd) mut => VT.[Friend]GetState(&this, psmd);

	public HRESULT SetMenuToolbar(IUnknown* punk, uint32 dwFlags) mut => VT.[Friend]SetMenuToolbar(&this, punk, dwFlags);
}

[CRepr]struct IKnownFolder : IUnknown
{
	public new const Guid IID = .(0x3aa7af7e, 0x9b36, 0x420c, 0xa8, 0xe3, 0xf7, 0x7d, 0x46, 0x74, 0xa4, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pkfid) GetId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KF_CATEGORY* pCategory) GetCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, in Guid riid, void** ppv) GetShellItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PWSTR* ppszPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, PWSTR pszPath) SetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, ITEMIDLIST** ppidl) GetIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pftid) GetFolderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCapabilities) GetRedirectionCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KNOWNFOLDER_DEFINITION* pKFD) GetFolderDefinition;
	}


	public HRESULT GetId(Guid* pkfid) mut => VT.[Friend]GetId(&this, pkfid);

	public HRESULT GetCategory(KF_CATEGORY* pCategory) mut => VT.[Friend]GetCategory(&this, pCategory);

	public HRESULT GetShellItem(uint32 dwFlags, in Guid riid, void** ppv) mut => VT.[Friend]GetShellItem(&this, dwFlags, riid, ppv);

	public HRESULT GetPath(uint32 dwFlags, PWSTR* ppszPath) mut => VT.[Friend]GetPath(&this, dwFlags, ppszPath);

	public HRESULT SetPath(uint32 dwFlags, PWSTR pszPath) mut => VT.[Friend]SetPath(&this, dwFlags, pszPath);

	public HRESULT GetIDList(uint32 dwFlags, ITEMIDLIST** ppidl) mut => VT.[Friend]GetIDList(&this, dwFlags, ppidl);

	public HRESULT GetFolderType(Guid* pftid) mut => VT.[Friend]GetFolderType(&this, pftid);

	public HRESULT GetRedirectionCapabilities(uint32* pCapabilities) mut => VT.[Friend]GetRedirectionCapabilities(&this, pCapabilities);

	public HRESULT GetFolderDefinition(KNOWNFOLDER_DEFINITION* pKFD) mut => VT.[Friend]GetFolderDefinition(&this, pKFD);
}

[CRepr]struct IKnownFolderManager : IUnknown
{
	public new const Guid IID = .(0x8be2d872, 0x86aa, 0x4d47, 0xb7, 0x76, 0x32, 0xcc, 0xa4, 0x0c, 0x70, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCsidl, Guid* pfid) FolderIdFromCsidl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfid, int32* pnCsidl) FolderIdToCsidl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid** ppKFId, uint32* pCount) GetFolderIds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfid, IKnownFolder** ppkf) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCanonicalName, IKnownFolder** ppkf) GetFolderByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfid, KNOWNFOLDER_DEFINITION* pKFD) RegisterFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfid) UnregisterFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, FFFP_MODE mode, IKnownFolder** ppkf) FindFolderFromPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, IKnownFolder** ppkf) FindFolderFromIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rfid, HWND hwnd, uint32 flags, PWSTR pszTargetPath, uint32 cFolders, Guid* pExclusion, PWSTR* ppszError) Redirect;
	}


	public HRESULT FolderIdFromCsidl(int32 nCsidl, Guid* pfid) mut => VT.[Friend]FolderIdFromCsidl(&this, nCsidl, pfid);

	public HRESULT FolderIdToCsidl(in Guid rfid, int32* pnCsidl) mut => VT.[Friend]FolderIdToCsidl(&this, rfid, pnCsidl);

	public HRESULT GetFolderIds(Guid** ppKFId, uint32* pCount) mut => VT.[Friend]GetFolderIds(&this, ppKFId, pCount);

	public HRESULT GetFolder(in Guid rfid, IKnownFolder** ppkf) mut => VT.[Friend]GetFolder(&this, rfid, ppkf);

	public HRESULT GetFolderByName(PWSTR pszCanonicalName, IKnownFolder** ppkf) mut => VT.[Friend]GetFolderByName(&this, pszCanonicalName, ppkf);

	public HRESULT RegisterFolder(in Guid rfid, KNOWNFOLDER_DEFINITION* pKFD) mut => VT.[Friend]RegisterFolder(&this, rfid, pKFD);

	public HRESULT UnregisterFolder(in Guid rfid) mut => VT.[Friend]UnregisterFolder(&this, rfid);

	public HRESULT FindFolderFromPath(PWSTR pszPath, FFFP_MODE mode, IKnownFolder** ppkf) mut => VT.[Friend]FindFolderFromPath(&this, pszPath, mode, ppkf);

	public HRESULT FindFolderFromIDList(ITEMIDLIST* pidl, IKnownFolder** ppkf) mut => VT.[Friend]FindFolderFromIDList(&this, pidl, ppkf);

	public HRESULT Redirect(in Guid rfid, HWND hwnd, uint32 flags, PWSTR pszTargetPath, uint32 cFolders, Guid* pExclusion, PWSTR* ppszError) mut => VT.[Friend]Redirect(&this, rfid, hwnd, flags, pszTargetPath, cFolders, pExclusion, ppszError);
}

[CRepr]struct ISharingConfigurationManager : IUnknown
{
	public new const Guid IID = .(0xb4cd448a, 0x9c86, 0x4466, 0x92, 0x01, 0x2e, 0x62, 0x10, 0x5b, 0x87, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEF_SHARE_ID dsid, SHARE_ROLE role) CreateShare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEF_SHARE_ID dsid) DeleteShare;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEF_SHARE_ID dsid) ShareExists;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEF_SHARE_ID dsid, SHARE_ROLE* pRole) GetSharePermissions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SharePrinters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopSharingPrinters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ArePrintersShared;
	}


	public HRESULT CreateShare(DEF_SHARE_ID dsid, SHARE_ROLE role) mut => VT.[Friend]CreateShare(&this, dsid, role);

	public HRESULT DeleteShare(DEF_SHARE_ID dsid) mut => VT.[Friend]DeleteShare(&this, dsid);

	public HRESULT ShareExists(DEF_SHARE_ID dsid) mut => VT.[Friend]ShareExists(&this, dsid);

	public HRESULT GetSharePermissions(DEF_SHARE_ID dsid, SHARE_ROLE* pRole) mut => VT.[Friend]GetSharePermissions(&this, dsid, pRole);

	public HRESULT SharePrinters() mut => VT.[Friend]SharePrinters(&this);

	public HRESULT StopSharingPrinters() mut => VT.[Friend]StopSharingPrinters(&this);

	public HRESULT ArePrintersShared() mut => VT.[Friend]ArePrintersShared(&this);
}

[CRepr]struct IRelatedItem : IUnknown
{
	public new const Guid IID = .(0xa73ce67a, 0x8ab1, 0x44f1, 0x8d, 0x43, 0xd2, 0xfc, 0xbf, 0x6b, 0x1c, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetItemIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem** ppsi) GetItem;
	}


	public HRESULT GetItemIDList(ITEMIDLIST** ppidl) mut => VT.[Friend]GetItemIDList(&this, ppidl);

	public HRESULT GetItem(IShellItem** ppsi) mut => VT.[Friend]GetItem(&this, ppsi);
}

[CRepr]struct IIdentityName : IRelatedItem
{
	public new const Guid IID = .(0x7d903fca, 0xd6f9, 0x4810, 0x83, 0x32, 0x94, 0x6c, 0x01, 0x77, 0xe2, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct IDelegateItem : IRelatedItem
{
	public new const Guid IID = .(0x3c5a1c94, 0xc951, 0x4cb7, 0xbb, 0x6d, 0x3b, 0x93, 0xf3, 0x0c, 0xce, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct ICurrentItem : IRelatedItem
{
	public new const Guid IID = .(0x240a7174, 0xd653, 0x4a1d, 0xa6, 0xd3, 0xd4, 0x94, 0x3c, 0xfb, 0xfe, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct ITransferMediumItem : IRelatedItem
{
	public new const Guid IID = .(0x77f295d5, 0x2d6f, 0x4e19, 0xb8, 0xae, 0x32, 0x2f, 0x3e, 0x72, 0x1a, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct IDisplayItem : IRelatedItem
{
	public new const Guid IID = .(0xc6fd5997, 0x9f6b, 0x4888, 0x87, 0x03, 0x94, 0xe8, 0x0e, 0x8c, 0xde, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct IViewStateIdentityItem : IRelatedItem
{
	public new const Guid IID = .(0x9d264146, 0xa94f, 0x4195, 0x9f, 0x9f, 0x3b, 0xb1, 0x2c, 0xe0, 0xc9, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct IPreviewItem : IRelatedItem
{
	public new const Guid IID = .(0x36149969, 0x0a8f, 0x49c8, 0x8b, 0x00, 0x4a, 0xec, 0xb2, 0x02, 0x22, 0xfb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct IDestinationStreamFactory : IUnknown
{
	public new const Guid IID = .(0x8a87781b, 0x39a7, 0x4a1f, 0xaa, 0xb3, 0xa3, 0x9b, 0x9c, 0x34, 0xa7, 0xd9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppstm) GetDestinationStream;
	}


	public HRESULT GetDestinationStream(IStream** ppstm) mut => VT.[Friend]GetDestinationStream(&this, ppstm);
}

[CRepr]struct ICreateProcessInputs : IUnknown
{
	public new const Guid IID = .(0xf6ef6140, 0xe26f, 0x4d82, 0xba, 0xc4, 0xe9, 0xba, 0x5f, 0xd2, 0x39, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCreationFlags) GetCreateFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCreationFlags) SetCreateFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCreationFlags) AddCreateFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16 wHotKey) SetHotKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwStartupInfoFlags) AddStartupFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PWSTR pszValue) SetEnvironmentVariable;
	}


	public HRESULT GetCreateFlags(uint32* pdwCreationFlags) mut => VT.[Friend]GetCreateFlags(&this, pdwCreationFlags);

	public HRESULT SetCreateFlags(uint32 dwCreationFlags) mut => VT.[Friend]SetCreateFlags(&this, dwCreationFlags);

	public HRESULT AddCreateFlags(uint32 dwCreationFlags) mut => VT.[Friend]AddCreateFlags(&this, dwCreationFlags);

	public HRESULT SetHotKey(uint16 wHotKey) mut => VT.[Friend]SetHotKey(&this, wHotKey);

	public HRESULT AddStartupFlags(uint32 dwStartupInfoFlags) mut => VT.[Friend]AddStartupFlags(&this, dwStartupInfoFlags);

	public HRESULT SetTitle(PWSTR pszTitle) mut => VT.[Friend]SetTitle(&this, pszTitle);

	public HRESULT SetEnvironmentVariable(PWSTR pszName, PWSTR pszValue) mut => VT.[Friend]SetEnvironmentVariable(&this, pszName, pszValue);
}

[CRepr]struct ICreatingProcess : IUnknown
{
	public new const Guid IID = .(0xc2b937a9, 0x3110, 0x4398, 0x8a, 0x56, 0xf3, 0x4c, 0x63, 0x42, 0xd2, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICreateProcessInputs* pcpi) OnCreating;
	}


	public HRESULT OnCreating(ICreateProcessInputs* pcpi) mut => VT.[Friend]OnCreating(&this, pcpi);
}

[CRepr]struct ILaunchUIContext : IUnknown
{
	public new const Guid IID = .(0x1791e8f6, 0x21c7, 0x4340, 0x88, 0x2a, 0xa6, 0xa9, 0x3e, 0x3f, 0xd7, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND value) SetAssociatedWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 value) SetTabGroupingPreference;
	}


	public HRESULT SetAssociatedWindow(HWND value) mut => VT.[Friend]SetAssociatedWindow(&this, value);

	public HRESULT SetTabGroupingPreference(uint32 value) mut => VT.[Friend]SetTabGroupingPreference(&this, value);
}

[CRepr]struct ILaunchUIContextProvider : IUnknown
{
	public new const Guid IID = .(0x0d12c4c8, 0xa3d9, 0x4e24, 0x94, 0xc1, 0x0e, 0x20, 0xc5, 0xa9, 0x56, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ILaunchUIContext* context) UpdateContext;
	}


	public HRESULT UpdateContext(ILaunchUIContext* context) mut => VT.[Friend]UpdateContext(&this, context);
}

[CRepr]struct INewMenuClient : IUnknown
{
	public new const Guid IID = .(0xdcb07fdc, 0x3bb5, 0x451c, 0x90, 0xbe, 0x96, 0x66, 0x44, 0xfe, 0xd7, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pflags) IncludeItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlItem, int32 flags) SelectAndEditItem;
	}


	public HRESULT IncludeItems(int32* pflags) mut => VT.[Friend]IncludeItems(&this, pflags);

	public HRESULT SelectAndEditItem(ITEMIDLIST* pidlItem, int32 flags) mut => VT.[Friend]SelectAndEditItem(&this, pidlItem, flags);
}

[CRepr]struct IInitializeWithBindCtx : IUnknown
{
	public new const Guid IID = .(0x71c0d2bc, 0x726d, 0x45cc, 0xa6, 0xc0, 0x2e, 0x31, 0xc1, 0xdb, 0x21, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc) Initialize;
	}


	public HRESULT Initialize(IBindCtx* pbc) mut => VT.[Friend]Initialize(&this, pbc);
}

[CRepr]struct IShellItemFilter : IUnknown
{
	public new const Guid IID = .(0x2659b475, 0xeeb8, 0x48b7, 0x8f, 0x07, 0xb3, 0x78, 0x81, 0x0f, 0x48, 0xcf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) IncludeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32* pgrfFlags) GetEnumFlagsForItem;
	}


	public HRESULT IncludeItem(IShellItem* psi) mut => VT.[Friend]IncludeItem(&this, psi);

	public HRESULT GetEnumFlagsForItem(IShellItem* psi, uint32* pgrfFlags) mut => VT.[Friend]GetEnumFlagsForItem(&this, psi, pgrfFlags);
}

[CRepr]struct INameSpaceTreeControl : IUnknown
{
	public new const Guid IID = .(0x028212a3, 0xb627, 0x47e9, 0x88, 0x56, 0xc1, 0x42, 0x65, 0x55, 0x4e, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, RECT* prc, uint32 nsctsFlags) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, uint32* pdwCookie) TreeAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) TreeUnadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiRoot, uint32 grfEnumFlags, uint32 grfRootStyle, IShellItemFilter* pif) AppendRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iIndex, IShellItem* psiRoot, uint32 grfEnumFlags, uint32 grfRootStyle, IShellItemFilter* pif) InsertRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiRoot) RemoveRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllRoots;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray** ppsiaRootItems) GetRootItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 nstcisMask, uint32 nstcisFlags) SetItemState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 nstcisMask, uint32* pnstcisFlags) GetItemState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray** psiaItems) GetSelectedItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, int32* piStateNumber) GetItemCustomState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, int32 iStateNumber) SetItemCustomState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) EnsureItemVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTheme) SetTheme;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, NSTCGNI nstcgi, IShellItem** ppsiNext) GetNextItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt, IShellItem** ppsiOut) HitTest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, RECT* prect) GetItemRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CollapseAll;
	}


	public HRESULT Initialize(HWND hwndParent, RECT* prc, uint32 nsctsFlags) mut => VT.[Friend]Initialize(&this, hwndParent, prc, nsctsFlags);

	public HRESULT TreeAdvise(IUnknown* punk, uint32* pdwCookie) mut => VT.[Friend]TreeAdvise(&this, punk, pdwCookie);

	public HRESULT TreeUnadvise(uint32 dwCookie) mut => VT.[Friend]TreeUnadvise(&this, dwCookie);

	public HRESULT AppendRoot(IShellItem* psiRoot, uint32 grfEnumFlags, uint32 grfRootStyle, IShellItemFilter* pif) mut => VT.[Friend]AppendRoot(&this, psiRoot, grfEnumFlags, grfRootStyle, pif);

	public HRESULT InsertRoot(int32 iIndex, IShellItem* psiRoot, uint32 grfEnumFlags, uint32 grfRootStyle, IShellItemFilter* pif) mut => VT.[Friend]InsertRoot(&this, iIndex, psiRoot, grfEnumFlags, grfRootStyle, pif);

	public HRESULT RemoveRoot(IShellItem* psiRoot) mut => VT.[Friend]RemoveRoot(&this, psiRoot);

	public HRESULT RemoveAllRoots() mut => VT.[Friend]RemoveAllRoots(&this);

	public HRESULT GetRootItems(IShellItemArray** ppsiaRootItems) mut => VT.[Friend]GetRootItems(&this, ppsiaRootItems);

	public HRESULT SetItemState(IShellItem* psi, uint32 nstcisMask, uint32 nstcisFlags) mut => VT.[Friend]SetItemState(&this, psi, nstcisMask, nstcisFlags);

	public HRESULT GetItemState(IShellItem* psi, uint32 nstcisMask, uint32* pnstcisFlags) mut => VT.[Friend]GetItemState(&this, psi, nstcisMask, pnstcisFlags);

	public HRESULT GetSelectedItems(IShellItemArray** psiaItems) mut => VT.[Friend]GetSelectedItems(&this, psiaItems);

	public HRESULT GetItemCustomState(IShellItem* psi, int32* piStateNumber) mut => VT.[Friend]GetItemCustomState(&this, psi, piStateNumber);

	public HRESULT SetItemCustomState(IShellItem* psi, int32 iStateNumber) mut => VT.[Friend]SetItemCustomState(&this, psi, iStateNumber);

	public HRESULT EnsureItemVisible(IShellItem* psi) mut => VT.[Friend]EnsureItemVisible(&this, psi);

	public HRESULT SetTheme(PWSTR pszTheme) mut => VT.[Friend]SetTheme(&this, pszTheme);

	public HRESULT GetNextItem(IShellItem* psi, NSTCGNI nstcgi, IShellItem** ppsiNext) mut => VT.[Friend]GetNextItem(&this, psi, nstcgi, ppsiNext);

	public HRESULT HitTest(POINT* ppt, IShellItem** ppsiOut) mut => VT.[Friend]HitTest(&this, ppt, ppsiOut);

	public HRESULT GetItemRect(IShellItem* psi, RECT* prect) mut => VT.[Friend]GetItemRect(&this, psi, prect);

	public HRESULT CollapseAll() mut => VT.[Friend]CollapseAll(&this);
}

[CRepr]struct INameSpaceTreeControlFolderCapabilities : IUnknown
{
	public new const Guid IID = .(0xe9701183, 0xe6b3, 0x4ff2, 0x85, 0x68, 0x81, 0x36, 0x15, 0xfe, 0xc7, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NSTCFOLDERCAPABILITIES nfcMask, NSTCFOLDERCAPABILITIES* pnfcValue) GetFolderCapabilities;
	}


	public HRESULT GetFolderCapabilities(NSTCFOLDERCAPABILITIES nfcMask, NSTCFOLDERCAPABILITIES* pnfcValue) mut => VT.[Friend]GetFolderCapabilities(&this, nfcMask, pnfcValue);
}

[CRepr]struct IPreviewHandler : IUnknown
{
	public new const Guid IID = .(0x8895b1c6, 0xb41f, 0x4c1c, 0xa5, 0x62, 0x0d, 0x56, 0x42, 0x50, 0x83, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, RECT* prc) SetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) SetRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DoPreview;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unload;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) QueryFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg) TranslateAccelerator;
	}


	public HRESULT SetWindow(HWND hwnd, RECT* prc) mut => VT.[Friend]SetWindow(&this, hwnd, prc);

	public HRESULT SetRect(RECT* prc) mut => VT.[Friend]SetRect(&this, prc);

	public HRESULT DoPreview() mut => VT.[Friend]DoPreview(&this);

	public HRESULT Unload() mut => VT.[Friend]Unload(&this);

	public HRESULT SetFocus() mut => VT.[Friend]SetFocus(&this);

	public HRESULT QueryFocus(HWND* phwnd) mut => VT.[Friend]QueryFocus(&this, phwnd);

	public HRESULT TranslateAccelerator(MSG* pmsg) mut => VT.[Friend]TranslateAccelerator(&this, pmsg);
}

[CRepr]struct IPreviewHandlerFrame : IUnknown
{
	public new const Guid IID = .(0xfec87aaf, 0x35f9, 0x447a, 0xad, 0xb7, 0x20, 0x23, 0x44, 0x91, 0x40, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PREVIEWHANDLERFRAMEINFO* pinfo) GetWindowContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg) TranslateAccelerator;
	}


	public HRESULT GetWindowContext(PREVIEWHANDLERFRAMEINFO* pinfo) mut => VT.[Friend]GetWindowContext(&this, pinfo);

	public HRESULT TranslateAccelerator(MSG* pmsg) mut => VT.[Friend]TranslateAccelerator(&this, pmsg);
}

[CRepr]struct IExplorerPaneVisibility : IUnknown
{
	public new const Guid IID = .(0xe07010ec, 0xbc17, 0x44c0, 0x97, 0xb0, 0x46, 0xc7, 0xc9, 0x5b, 0x9e, 0xdc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ep, uint32* peps) GetPaneState;
	}


	public HRESULT GetPaneState(in Guid ep, uint32* peps) mut => VT.[Friend]GetPaneState(&this, ep, peps);
}

[CRepr]struct IContextMenuCB : IUnknown
{
	public new const Guid IID = .(0x3409e930, 0x5a39, 0x11d1, 0x83, 0xfa, 0x00, 0xa0, 0xc9, 0x0d, 0xc8, 0x49);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, HWND hwndOwner, IDataObject* pdtobj, uint32 uMsg, WPARAM wParam, LPARAM lParam) CallBack;
	}


	public HRESULT CallBack(IShellFolder* psf, HWND hwndOwner, IDataObject* pdtobj, uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]CallBack(&this, psf, hwndOwner, pdtobj, uMsg, wParam, lParam);
}

[CRepr]struct IDefaultExtractIconInit : IUnknown
{
	public new const Guid IID = .(0x41ded17d, 0xd6b3, 0x4261, 0x99, 0x7d, 0x88, 0xc6, 0x0e, 0x4b, 0x1d, 0x58);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFlags) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HKEY hkey) SetKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, int32 iIcon) SetNormalIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, int32 iIcon) SetOpenIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, int32 iIcon) SetShortcutIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, int32 iIcon) SetDefaultIcon;
	}


	public HRESULT SetFlags(uint32 uFlags) mut => VT.[Friend]SetFlags(&this, uFlags);

	public HRESULT SetKey(HKEY hkey) mut => VT.[Friend]SetKey(&this, hkey);

	public HRESULT SetNormalIcon(PWSTR pszFile, int32 iIcon) mut => VT.[Friend]SetNormalIcon(&this, pszFile, iIcon);

	public HRESULT SetOpenIcon(PWSTR pszFile, int32 iIcon) mut => VT.[Friend]SetOpenIcon(&this, pszFile, iIcon);

	public HRESULT SetShortcutIcon(PWSTR pszFile, int32 iIcon) mut => VT.[Friend]SetShortcutIcon(&this, pszFile, iIcon);

	public HRESULT SetDefaultIcon(PWSTR pszFile, int32 iIcon) mut => VT.[Friend]SetDefaultIcon(&this, pszFile, iIcon);
}

[CRepr]struct IExplorerCommand : IUnknown
{
	public new const Guid IID = .(0xa08ce4d0, 0xfa25, 0x44ab, 0xb5, 0x7c, 0xc7, 0xb1, 0xc3, 0x23, 0xe0, 0xb9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, PWSTR* ppszName) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, PWSTR* ppszIcon) GetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, PWSTR* ppszInfotip) GetToolTip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidCommandName) GetCanonicalName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, BOOL fOkToBeSlow, uint32* pCmdState) GetState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, IBindCtx* pbc) Invoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumExplorerCommand** ppEnum) EnumSubCommands;
	}


	public HRESULT GetTitle(IShellItemArray* psiItemArray, PWSTR* ppszName) mut => VT.[Friend]GetTitle(&this, psiItemArray, ppszName);

	public HRESULT GetIcon(IShellItemArray* psiItemArray, PWSTR* ppszIcon) mut => VT.[Friend]GetIcon(&this, psiItemArray, ppszIcon);

	public HRESULT GetToolTip(IShellItemArray* psiItemArray, PWSTR* ppszInfotip) mut => VT.[Friend]GetToolTip(&this, psiItemArray, ppszInfotip);

	public HRESULT GetCanonicalName(Guid* pguidCommandName) mut => VT.[Friend]GetCanonicalName(&this, pguidCommandName);

	public HRESULT GetState(IShellItemArray* psiItemArray, BOOL fOkToBeSlow, uint32* pCmdState) mut => VT.[Friend]GetState(&this, psiItemArray, fOkToBeSlow, pCmdState);

	public HRESULT Invoke(IShellItemArray* psiItemArray, IBindCtx* pbc) mut => VT.[Friend]Invoke(&this, psiItemArray, pbc);

	public HRESULT GetFlags(uint32* pFlags) mut => VT.[Friend]COM_GetFlags(&this, pFlags);

	public HRESULT EnumSubCommands(IEnumExplorerCommand** ppEnum) mut => VT.[Friend]EnumSubCommands(&this, ppEnum);
}

[CRepr]struct IExplorerCommandState : IUnknown
{
	public new const Guid IID = .(0xbddacb60, 0x7657, 0x47ae, 0x84, 0x45, 0xd2, 0x3e, 0x1a, 0xcf, 0x82, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiItemArray, BOOL fOkToBeSlow, uint32* pCmdState) GetState;
	}


	public HRESULT GetState(IShellItemArray* psiItemArray, BOOL fOkToBeSlow, uint32* pCmdState) mut => VT.[Friend]GetState(&this, psiItemArray, fOkToBeSlow, pCmdState);
}

[CRepr]struct IInitializeCommand : IUnknown
{
	public new const Guid IID = .(0x85075acf, 0x231f, 0x40ea, 0x96, 0x10, 0xd2, 0x6b, 0x7b, 0x58, 0xf6, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCommandName, IPropertyBag* ppb) Initialize;
	}


	public HRESULT Initialize(PWSTR pszCommandName, IPropertyBag* ppb) mut => VT.[Friend]Initialize(&this, pszCommandName, ppb);
}

[CRepr]struct IEnumExplorerCommand : IUnknown
{
	public new const Guid IID = .(0xa88826f8, 0x186f, 0x4987, 0xaa, 0xde, 0xea, 0x0c, 0xef, 0x8f, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IExplorerCommand** pUICommand, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumExplorerCommand** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, IExplorerCommand** pUICommand, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, pUICommand, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumExplorerCommand** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IExplorerCommandProvider : IUnknown
{
	public new const Guid IID = .(0x64961751, 0x0835, 0x43c0, 0x8f, 0xfe, 0xd5, 0x76, 0x86, 0x53, 0x0e, 0x64);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkSite, in Guid riid, void** ppv) GetCommands;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidCommandId, in Guid riid, void** ppv) GetCommand;
	}


	public HRESULT GetCommands(IUnknown* punkSite, in Guid riid, void** ppv) mut => VT.[Friend]GetCommands(&this, punkSite, riid, ppv);

	public HRESULT GetCommand(in Guid rguidCommandId, in Guid riid, void** ppv) mut => VT.[Friend]GetCommand(&this, rguidCommandId, riid, ppv);
}

[CRepr]struct IOpenControlPanel : IUnknown
{
	public new const Guid IID = .(0xd11ad862, 0x66de, 0x4df4, 0xbf, 0x6c, 0x1f, 0x56, 0x21, 0x99, 0x6a, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, PWSTR pszPage, IUnknown* punkSite) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName, char16* pszPath, uint32 cchPath) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CPVIEW* pView) GetCurrentView;
	}


	public HRESULT Open(PWSTR pszName, PWSTR pszPage, IUnknown* punkSite) mut => VT.[Friend]Open(&this, pszName, pszPage, punkSite);

	public HRESULT GetPath(PWSTR pszName, char16* pszPath, uint32 cchPath) mut => VT.[Friend]GetPath(&this, pszName, pszPath, cchPath);

	public HRESULT GetCurrentView(CPVIEW* pView) mut => VT.[Friend]GetCurrentView(&this, pView);
}

[CRepr]struct IFileSystemBindData : IUnknown
{
	public new const Guid IID = .(0x01e18d10, 0x4d8b, 0x11d2, 0x85, 0x5d, 0x00, 0x60, 0x08, 0x05, 0x93, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIN32_FIND_DATAW* pfd) SetFindData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WIN32_FIND_DATAW* pfd) GetFindData;
	}


	public HRESULT SetFindData(WIN32_FIND_DATAW* pfd) mut => VT.[Friend]SetFindData(&this, pfd);

	public HRESULT GetFindData(WIN32_FIND_DATAW* pfd) mut => VT.[Friend]GetFindData(&this, pfd);
}

[CRepr]struct IFileSystemBindData2 : IFileSystemBindData
{
	public new const Guid IID = .(0x3acf075f, 0x71db, 0x4afa, 0x81, 0xf0, 0x3f, 0xc4, 0xfd, 0xf2, 0xa5, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFileSystemBindData.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER liFileID) SetFileID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LARGE_INTEGER* pliFileID) GetFileID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) SetJunctionCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pclsid) GetJunctionCLSID;
	}


	public HRESULT SetFileID(LARGE_INTEGER liFileID) mut => VT.[Friend]SetFileID(&this, liFileID);

	public HRESULT GetFileID(LARGE_INTEGER* pliFileID) mut => VT.[Friend]GetFileID(&this, pliFileID);

	public HRESULT SetJunctionCLSID(in Guid clsid) mut => VT.[Friend]SetJunctionCLSID(&this, clsid);

	public HRESULT GetJunctionCLSID(Guid* pclsid) mut => VT.[Friend]GetJunctionCLSID(&this, pclsid);
}

[CRepr]struct ICustomDestinationList : IUnknown
{
	public new const Guid IID = .(0x6332debf, 0x87b5, 0x4670, 0x90, 0xc0, 0x5e, 0x57, 0xb4, 0x08, 0xa4, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppID) SetAppID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcMinSlots, in Guid riid, void** ppv) BeginList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCategory, IObjectArray* poa) AppendCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, KNOWNDESTCATEGORY category) AppendKnownCategory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IObjectArray* poa) AddUserTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CommitList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetRemovedDestinations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppID) DeleteList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AbortList;
	}


	public HRESULT SetAppID(PWSTR pszAppID) mut => VT.[Friend]SetAppID(&this, pszAppID);

	public HRESULT BeginList(uint32* pcMinSlots, in Guid riid, void** ppv) mut => VT.[Friend]BeginList(&this, pcMinSlots, riid, ppv);

	public HRESULT AppendCategory(PWSTR pszCategory, IObjectArray* poa) mut => VT.[Friend]AppendCategory(&this, pszCategory, poa);

	public HRESULT AppendKnownCategory(KNOWNDESTCATEGORY category) mut => VT.[Friend]AppendKnownCategory(&this, category);

	public HRESULT AddUserTasks(IObjectArray* poa) mut => VT.[Friend]AddUserTasks(&this, poa);

	public HRESULT CommitList() mut => VT.[Friend]CommitList(&this);

	public HRESULT GetRemovedDestinations(in Guid riid, void** ppv) mut => VT.[Friend]GetRemovedDestinations(&this, riid, ppv);

	public HRESULT DeleteList(PWSTR pszAppID) mut => VT.[Friend]DeleteList(&this, pszAppID);

	public HRESULT AbortList() mut => VT.[Friend]AbortList(&this);
}

[CRepr]struct IApplicationDestinations : IUnknown
{
	public new const Guid IID = .(0x12337d35, 0x94c6, 0x48a0, 0xbc, 0xe7, 0x6a, 0x9c, 0x69, 0xd4, 0xd6, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppID) SetAppID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) RemoveDestination;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAllDestinations;
	}


	public HRESULT SetAppID(PWSTR pszAppID) mut => VT.[Friend]SetAppID(&this, pszAppID);

	public HRESULT RemoveDestination(IUnknown* punk) mut => VT.[Friend]RemoveDestination(&this, punk);

	public HRESULT RemoveAllDestinations() mut => VT.[Friend]RemoveAllDestinations(&this);
}

[CRepr]struct IApplicationDocumentLists : IUnknown
{
	public new const Guid IID = .(0x3c594f9f, 0x9f30, 0x47a1, 0x97, 0x9a, 0xc9, 0xe8, 0x3d, 0x3d, 0x0a, 0x06);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppID) SetAppID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPDOCLISTTYPE listtype, uint32 cItemsDesired, in Guid riid, void** ppv) GetList;
	}


	public HRESULT SetAppID(PWSTR pszAppID) mut => VT.[Friend]SetAppID(&this, pszAppID);

	public HRESULT GetList(APPDOCLISTTYPE listtype, uint32 cItemsDesired, in Guid riid, void** ppv) mut => VT.[Friend]GetList(&this, listtype, cItemsDesired, riid, ppv);
}

[CRepr]struct IObjectWithAppUserModelID : IUnknown
{
	public new const Guid IID = .(0x36db0196, 0x9665, 0x46d1, 0x9b, 0xa7, 0xd3, 0x70, 0x9e, 0xec, 0xf9, 0xed);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppID) SetAppID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszAppID) GetAppID;
	}


	public HRESULT SetAppID(PWSTR pszAppID) mut => VT.[Friend]SetAppID(&this, pszAppID);

	public HRESULT GetAppID(PWSTR* ppszAppID) mut => VT.[Friend]GetAppID(&this, ppszAppID);
}

[CRepr]struct IObjectWithProgID : IUnknown
{
	public new const Guid IID = .(0x71e806fb, 0x8dee, 0x46fc, 0xbf, 0x8c, 0x77, 0x48, 0xa8, 0xa1, 0xae, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszProgID) SetProgID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszProgID) GetProgID;
	}


	public HRESULT SetProgID(PWSTR pszProgID) mut => VT.[Friend]SetProgID(&this, pszProgID);

	public HRESULT GetProgID(PWSTR* ppszProgID) mut => VT.[Friend]GetProgID(&this, ppszProgID);
}

[CRepr]struct IUpdateIDList : IUnknown
{
	public new const Guid IID = .(0x6589b6d2, 0x5f8d, 0x4b9e, 0xb7, 0xe0, 0x23, 0xcd, 0xd9, 0x71, 0x7d, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbc, ITEMIDLIST* pidlIn, ITEMIDLIST** ppidlOut) Update;
	}


	public HRESULT Update(IBindCtx* pbc, ITEMIDLIST* pidlIn, ITEMIDLIST** ppidlOut) mut => VT.[Friend]Update(&this, pbc, pidlIn, ppidlOut);
}

[CRepr]struct IDesktopWallpaper : IUnknown
{
	public new const Guid IID = .(0xb92b56a9, 0x8b55, 0x4e14, 0x9a, 0x89, 0x01, 0x99, 0xbb, 0xb6, 0xf9, 0x3b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR monitorID, PWSTR wallpaper) SetWallpaper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR monitorID, PWSTR* wallpaper) GetWallpaper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 monitorIndex, PWSTR* monitorID) GetMonitorDevicePathAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetMonitorDevicePathCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR monitorID, RECT* displayRect) GetMonitorRECT;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF color) SetBackgroundColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COLORREF* color) GetBackgroundColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DESKTOP_WALLPAPER_POSITION position) SetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DESKTOP_WALLPAPER_POSITION* position) GetPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* items) SetSlideshow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray** items) GetSlideshow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DESKTOP_SLIDESHOW_OPTIONS options, uint32 slideshowTick) SetSlideshowOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DESKTOP_SLIDESHOW_OPTIONS* options, uint32* slideshowTick) GetSlideshowOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR monitorID, DESKTOP_SLIDESHOW_DIRECTION direction) AdvanceSlideshow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DESKTOP_SLIDESHOW_STATE* state) GetStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL enable) Enable;
	}


	public HRESULT SetWallpaper(PWSTR monitorID, PWSTR wallpaper) mut => VT.[Friend]SetWallpaper(&this, monitorID, wallpaper);

	public HRESULT GetWallpaper(PWSTR monitorID, PWSTR* wallpaper) mut => VT.[Friend]GetWallpaper(&this, monitorID, wallpaper);

	public HRESULT GetMonitorDevicePathAt(uint32 monitorIndex, PWSTR* monitorID) mut => VT.[Friend]GetMonitorDevicePathAt(&this, monitorIndex, monitorID);

	public HRESULT GetMonitorDevicePathCount(uint32* count) mut => VT.[Friend]GetMonitorDevicePathCount(&this, count);

	public HRESULT GetMonitorRECT(PWSTR monitorID, RECT* displayRect) mut => VT.[Friend]GetMonitorRECT(&this, monitorID, displayRect);

	public HRESULT SetBackgroundColor(COLORREF color) mut => VT.[Friend]SetBackgroundColor(&this, color);

	public HRESULT GetBackgroundColor(COLORREF* color) mut => VT.[Friend]GetBackgroundColor(&this, color);

	public HRESULT SetPosition(DESKTOP_WALLPAPER_POSITION position) mut => VT.[Friend]SetPosition(&this, position);

	public HRESULT GetPosition(DESKTOP_WALLPAPER_POSITION* position) mut => VT.[Friend]GetPosition(&this, position);

	public HRESULT SetSlideshow(IShellItemArray* items) mut => VT.[Friend]SetSlideshow(&this, items);

	public HRESULT GetSlideshow(IShellItemArray** items) mut => VT.[Friend]GetSlideshow(&this, items);

	public HRESULT SetSlideshowOptions(DESKTOP_SLIDESHOW_OPTIONS options, uint32 slideshowTick) mut => VT.[Friend]SetSlideshowOptions(&this, options, slideshowTick);

	public HRESULT GetSlideshowOptions(DESKTOP_SLIDESHOW_OPTIONS* options, uint32* slideshowTick) mut => VT.[Friend]GetSlideshowOptions(&this, options, slideshowTick);

	public HRESULT AdvanceSlideshow(PWSTR monitorID, DESKTOP_SLIDESHOW_DIRECTION direction) mut => VT.[Friend]AdvanceSlideshow(&this, monitorID, direction);

	public HRESULT GetStatus(DESKTOP_SLIDESHOW_STATE* state) mut => VT.[Friend]GetStatus(&this, state);

	public HRESULT Enable(BOOL enable) mut => VT.[Friend]Enable(&this, enable);
}

[CRepr]struct IHomeGroup : IUnknown
{
	public new const Guid IID = .(0x7a3bd1d9, 0x35a9, 0x4fb3, 0xa4, 0x67, 0xf4, 0x8c, 0xac, 0x35, 0xe2, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* member) IsMember;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND owner, HOMEGROUPSHARINGCHOICES* sharingchoices) ShowSharingWizard;
	}


	public HRESULT IsMember(BOOL* member) mut => VT.[Friend]IsMember(&this, member);

	public HRESULT ShowSharingWizard(HWND owner, HOMEGROUPSHARINGCHOICES* sharingchoices) mut => VT.[Friend]ShowSharingWizard(&this, owner, sharingchoices);
}

[CRepr]struct IInitializeWithPropertyStore : IUnknown
{
	public new const Guid IID = .(0xc3e12eb5, 0x7d8d, 0x44f8, 0xb6, 0xdd, 0x0e, 0x77, 0xb3, 0x4d, 0x6d, 0xe4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* pps) Initialize;
	}


	public HRESULT Initialize(IPropertyStore* pps) mut => VT.[Friend]Initialize(&this, pps);
}

[CRepr]struct IOpenSearchSource : IUnknown
{
	public new const Guid IID = .(0xf0ee7333, 0xe6fc, 0x479b, 0x9f, 0x25, 0xa8, 0x60, 0xc2, 0x34, 0xa3, 0x8e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, PWSTR pszQuery, uint32 dwStartIndex, uint32 dwCount, in Guid riid, void** ppv) GetResults;
	}


	public HRESULT GetResults(HWND hwnd, PWSTR pszQuery, uint32 dwStartIndex, uint32 dwCount, in Guid riid, void** ppv) mut => VT.[Friend]GetResults(&this, hwnd, pszQuery, dwStartIndex, dwCount, riid, ppv);
}

[CRepr]struct IShellLibrary : IUnknown
{
	public new const Guid IID = .(0x11a66efa, 0x382e, 0x451a, 0x92, 0x34, 0x1e, 0x0e, 0x12, 0xef, 0x30, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiLibrary, uint32 grfMode) LoadLibraryFromItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid kfidLibrary, uint32 grfMode) LoadLibraryFromKnownFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiLocation) AddFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiLocation) RemoveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LIBRARYFOLDERFILTER lff, in Guid riid, void** ppv) GetFolders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiFolderToResolve, uint32 dwTimeout, in Guid riid, void** ppv) ResolveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEFAULTSAVEFOLDERTYPE dsft, in Guid riid, void** ppv) GetDefaultSaveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEFAULTSAVEFOLDERTYPE dsft, IShellItem* psi) SetDefaultSaveFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LIBRARYOPTIONFLAGS* plofOptions) GetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LIBRARYOPTIONFLAGS lofMask, LIBRARYOPTIONFLAGS lofOptions) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pftid) GetFolderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ftid) SetFolderType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszIcon) GetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszIcon) SetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Commit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiFolderToSaveIn, PWSTR pszLibraryName, LIBRARYSAVEFLAGS lsf, IShellItem** ppsiSavedTo) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid kfidToSaveIn, PWSTR pszLibraryName, LIBRARYSAVEFLAGS lsf, IShellItem** ppsiSavedTo) SaveInKnownFolder;
	}


	public HRESULT LoadLibraryFromItem(IShellItem* psiLibrary, uint32 grfMode) mut => VT.[Friend]LoadLibraryFromItem(&this, psiLibrary, grfMode);

	public HRESULT LoadLibraryFromKnownFolder(in Guid kfidLibrary, uint32 grfMode) mut => VT.[Friend]LoadLibraryFromKnownFolder(&this, kfidLibrary, grfMode);

	public HRESULT AddFolder(IShellItem* psiLocation) mut => VT.[Friend]AddFolder(&this, psiLocation);

	public HRESULT RemoveFolder(IShellItem* psiLocation) mut => VT.[Friend]RemoveFolder(&this, psiLocation);

	public HRESULT GetFolders(LIBRARYFOLDERFILTER lff, in Guid riid, void** ppv) mut => VT.[Friend]GetFolders(&this, lff, riid, ppv);

	public HRESULT ResolveFolder(IShellItem* psiFolderToResolve, uint32 dwTimeout, in Guid riid, void** ppv) mut => VT.[Friend]ResolveFolder(&this, psiFolderToResolve, dwTimeout, riid, ppv);

	public HRESULT GetDefaultSaveFolder(DEFAULTSAVEFOLDERTYPE dsft, in Guid riid, void** ppv) mut => VT.[Friend]GetDefaultSaveFolder(&this, dsft, riid, ppv);

	public HRESULT SetDefaultSaveFolder(DEFAULTSAVEFOLDERTYPE dsft, IShellItem* psi) mut => VT.[Friend]SetDefaultSaveFolder(&this, dsft, psi);

	public HRESULT GetOptions(LIBRARYOPTIONFLAGS* plofOptions) mut => VT.[Friend]GetOptions(&this, plofOptions);

	public HRESULT SetOptions(LIBRARYOPTIONFLAGS lofMask, LIBRARYOPTIONFLAGS lofOptions) mut => VT.[Friend]SetOptions(&this, lofMask, lofOptions);

	public HRESULT GetFolderType(Guid* pftid) mut => VT.[Friend]GetFolderType(&this, pftid);

	public HRESULT SetFolderType(in Guid ftid) mut => VT.[Friend]SetFolderType(&this, ftid);

	public HRESULT GetIcon(PWSTR* ppszIcon) mut => VT.[Friend]GetIcon(&this, ppszIcon);

	public HRESULT SetIcon(PWSTR pszIcon) mut => VT.[Friend]SetIcon(&this, pszIcon);

	public HRESULT Commit() mut => VT.[Friend]Commit(&this);

	public HRESULT Save(IShellItem* psiFolderToSaveIn, PWSTR pszLibraryName, LIBRARYSAVEFLAGS lsf, IShellItem** ppsiSavedTo) mut => VT.[Friend]Save(&this, psiFolderToSaveIn, pszLibraryName, lsf, ppsiSavedTo);

	public HRESULT SaveInKnownFolder(in Guid kfidToSaveIn, PWSTR pszLibraryName, LIBRARYSAVEFLAGS lsf, IShellItem** ppsiSavedTo) mut => VT.[Friend]SaveInKnownFolder(&this, kfidToSaveIn, pszLibraryName, lsf, ppsiSavedTo);
}

[CRepr]struct IDefaultFolderMenuInitialize : IUnknown
{
	public new const Guid IID = .(0x7690aa79, 0xf8fc, 0x4615, 0xa3, 0x27, 0x36, 0xf7, 0xd1, 0x8f, 0x5d, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IContextMenuCB* pcmcb, ITEMIDLIST* pidlFolder, IShellFolder* psf, uint32 cidl, ITEMIDLIST** apidl, IUnknown* punkAssociation, uint32 cKeys, HKEY* aKeys) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEFAULT_FOLDER_MENU_RESTRICTIONS dfmrValues) SetMenuRestrictions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEFAULT_FOLDER_MENU_RESTRICTIONS dfmrMask, DEFAULT_FOLDER_MENU_RESTRICTIONS* pdfmrValues) GetMenuRestrictions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsid) SetHandlerClsid;
	}


	public HRESULT Initialize(HWND hwnd, IContextMenuCB* pcmcb, ITEMIDLIST* pidlFolder, IShellFolder* psf, uint32 cidl, ITEMIDLIST** apidl, IUnknown* punkAssociation, uint32 cKeys, HKEY* aKeys) mut => VT.[Friend]Initialize(&this, hwnd, pcmcb, pidlFolder, psf, cidl, apidl, punkAssociation, cKeys, aKeys);

	public HRESULT SetMenuRestrictions(DEFAULT_FOLDER_MENU_RESTRICTIONS dfmrValues) mut => VT.[Friend]SetMenuRestrictions(&this, dfmrValues);

	public HRESULT GetMenuRestrictions(DEFAULT_FOLDER_MENU_RESTRICTIONS dfmrMask, DEFAULT_FOLDER_MENU_RESTRICTIONS* pdfmrValues) mut => VT.[Friend]GetMenuRestrictions(&this, dfmrMask, pdfmrValues);

	public HRESULT SetHandlerClsid(in Guid rclsid) mut => VT.[Friend]SetHandlerClsid(&this, rclsid);
}

[CRepr]struct IApplicationActivationManager : IUnknown
{
	public new const Guid IID = .(0x2e941141, 0x7f97, 0x4756, 0xba, 0x1d, 0x9d, 0xec, 0xde, 0x89, 0x4a, 0x3d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appUserModelId, PWSTR arguments, ACTIVATEOPTIONS options, uint32* processId) ActivateApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appUserModelId, IShellItemArray* itemArray, PWSTR verb, uint32* processId) ActivateForFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR appUserModelId, IShellItemArray* itemArray, uint32* processId) ActivateForProtocol;
	}


	public HRESULT ActivateApplication(PWSTR appUserModelId, PWSTR arguments, ACTIVATEOPTIONS options, uint32* processId) mut => VT.[Friend]ActivateApplication(&this, appUserModelId, arguments, options, processId);

	public HRESULT ActivateForFile(PWSTR appUserModelId, IShellItemArray* itemArray, PWSTR verb, uint32* processId) mut => VT.[Friend]ActivateForFile(&this, appUserModelId, itemArray, verb, processId);

	public HRESULT ActivateForProtocol(PWSTR appUserModelId, IShellItemArray* itemArray, uint32* processId) mut => VT.[Friend]ActivateForProtocol(&this, appUserModelId, itemArray, processId);
}

[CRepr]struct IVirtualDesktopManager : IUnknown
{
	public new const Guid IID = .(0xa5cd92ff, 0x29be, 0x454c, 0x8d, 0x04, 0xd8, 0x28, 0x79, 0xfb, 0x3f, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND topLevelWindow, BOOL* onCurrentDesktop) IsWindowOnCurrentVirtualDesktop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND topLevelWindow, Guid* desktopId) GetWindowDesktopId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND topLevelWindow, in Guid desktopId) MoveWindowToDesktop;
	}


	public HRESULT IsWindowOnCurrentVirtualDesktop(HWND topLevelWindow, BOOL* onCurrentDesktop) mut => VT.[Friend]IsWindowOnCurrentVirtualDesktop(&this, topLevelWindow, onCurrentDesktop);

	public HRESULT GetWindowDesktopId(HWND topLevelWindow, Guid* desktopId) mut => VT.[Friend]GetWindowDesktopId(&this, topLevelWindow, desktopId);

	public HRESULT MoveWindowToDesktop(HWND topLevelWindow, in Guid desktopId) mut => VT.[Friend]MoveWindowToDesktop(&this, topLevelWindow, desktopId);
}

[CRepr]struct IAssocHandlerInvoker : IUnknown
{
	public new const Guid IID = .(0x92218cab, 0xecaa, 0x4335, 0x81, 0x33, 0x80, 0x7f, 0xd2, 0x34, 0xc2, 0xee);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SupportsSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Invoke;
	}


	public HRESULT SupportsSelection() mut => VT.[Friend]SupportsSelection(&this);

	public HRESULT Invoke() mut => VT.[Friend]Invoke(&this);
}

[CRepr]struct IAssocHandler : IUnknown
{
	public new const Guid IID = .(0xf04061ac, 0x1659, 0x4a3f, 0xa9, 0x54, 0x77, 0x5a, 0xa5, 0x7f, 0xc0, 0x83);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppsz) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppsz) GetUIName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszPath, int32* pIndex) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsRecommended;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDescription) MakeDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pdo) Invoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pdo, IAssocHandlerInvoker** ppInvoker) CreateInvoker;
	}


	public HRESULT GetName(PWSTR* ppsz) mut => VT.[Friend]GetName(&this, ppsz);

	public HRESULT GetUIName(PWSTR* ppsz) mut => VT.[Friend]GetUIName(&this, ppsz);

	public HRESULT GetIconLocation(PWSTR* ppszPath, int32* pIndex) mut => VT.[Friend]GetIconLocation(&this, ppszPath, pIndex);

	public HRESULT IsRecommended() mut => VT.[Friend]IsRecommended(&this);

	public HRESULT MakeDefault(PWSTR pszDescription) mut => VT.[Friend]MakeDefault(&this, pszDescription);

	public HRESULT Invoke(IDataObject* pdo) mut => VT.[Friend]Invoke(&this, pdo);

	public HRESULT CreateInvoker(IDataObject* pdo, IAssocHandlerInvoker** ppInvoker) mut => VT.[Friend]CreateInvoker(&this, pdo, ppInvoker);
}

[CRepr]struct IEnumAssocHandlers : IUnknown
{
	public new const Guid IID = .(0x973810ae, 0x9599, 0x4b88, 0x9e, 0x4d, 0x6e, 0xe9, 0x8c, 0x95, 0x52, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, IAssocHandler** rgelt, uint32* pceltFetched) Next;
	}


	public HRESULT Next(uint32 celt, IAssocHandler** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);
}

[CRepr]struct IDataObjectProvider : IUnknown
{
	public new const Guid IID = .(0x3d25f6d6, 0x4b2a, 0x433c, 0x91, 0x84, 0x7c, 0x33, 0xad, 0x35, 0xd0, 0x01);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject** dataObject) GetDataObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* dataObject) SetDataObject;
	}


	public HRESULT GetDataObject(IDataObject** dataObject) mut => VT.[Friend]GetDataObject(&this, dataObject);

	public HRESULT SetDataObject(IDataObject* dataObject) mut => VT.[Friend]SetDataObject(&this, dataObject);
}

[CRepr]struct IDataTransferManagerInterop : IUnknown
{
	public new const Guid IID = .(0x3a3dcd6c, 0x3eab, 0x43dc, 0xbc, 0xde, 0x45, 0x67, 0x1c, 0xe8, 0x00, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, in Guid riid, void** dataTransferManager) GetForWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow) ShowShareUIForWindow;
	}


	public HRESULT GetForWindow(HWND appWindow, in Guid riid, void** dataTransferManager) mut => VT.[Friend]GetForWindow(&this, appWindow, riid, dataTransferManager);

	public HRESULT ShowShareUIForWindow(HWND appWindow) mut => VT.[Friend]ShowShareUIForWindow(&this, appWindow);
}

[CRepr]struct IFrameworkInputPaneHandler : IUnknown
{
	public new const Guid IID = .(0x226c537b, 0x1e76, 0x4d9e, 0xa7, 0x60, 0x33, 0xdb, 0x29, 0x92, 0x2f, 0x18);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcInputPaneScreenLocation, BOOL fEnsureFocusedElementInView) Showing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnsureFocusedElementInView) Hiding;
	}


	public HRESULT Showing(RECT* prcInputPaneScreenLocation, BOOL fEnsureFocusedElementInView) mut => VT.[Friend]Showing(&this, prcInputPaneScreenLocation, fEnsureFocusedElementInView);

	public HRESULT Hiding(BOOL fEnsureFocusedElementInView) mut => VT.[Friend]Hiding(&this, fEnsureFocusedElementInView);
}

[CRepr]struct IFrameworkInputPane : IUnknown
{
	public new const Guid IID = .(0x5752238b, 0x24f0, 0x495a, 0x82, 0xf1, 0x2f, 0xd5, 0x93, 0x05, 0x67, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pWindow, IFrameworkInputPaneHandler* pHandler, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IFrameworkInputPaneHandler* pHandler, uint32* pdwCookie) AdviseWithHWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prcInputPaneScreenLocation) Location;
	}


	public HRESULT Advise(IUnknown* pWindow, IFrameworkInputPaneHandler* pHandler, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pWindow, pHandler, pdwCookie);

	public HRESULT AdviseWithHWND(HWND hwnd, IFrameworkInputPaneHandler* pHandler, uint32* pdwCookie) mut => VT.[Friend]AdviseWithHWND(&this, hwnd, pHandler, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);

	public HRESULT Location(RECT* prcInputPaneScreenLocation) mut => VT.[Friend]Location(&this, prcInputPaneScreenLocation);
}

[CRepr]struct IAppVisibilityEvents : IUnknown
{
	public new const Guid IID = .(0x6584ce6b, 0x7d82, 0x49c2, 0x89, 0xc9, 0xc6, 0xbc, 0x02, 0xba, 0x8c, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR hMonitor, MONITOR_APP_VISIBILITY previousMode, MONITOR_APP_VISIBILITY currentMode) AppVisibilityOnMonitorChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL currentVisibleState) LauncherVisibilityChange;
	}


	public HRESULT AppVisibilityOnMonitorChanged(HMONITOR hMonitor, MONITOR_APP_VISIBILITY previousMode, MONITOR_APP_VISIBILITY currentMode) mut => VT.[Friend]AppVisibilityOnMonitorChanged(&this, hMonitor, previousMode, currentMode);

	public HRESULT LauncherVisibilityChange(BOOL currentVisibleState) mut => VT.[Friend]LauncherVisibilityChange(&this, currentVisibleState);
}

[CRepr]struct IAppVisibility : IUnknown
{
	public new const Guid IID = .(0x2246ea2d, 0xcaea, 0x4444, 0xa3, 0xc4, 0x6d, 0xe8, 0x27, 0xe4, 0x43, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR hMonitor, MONITOR_APP_VISIBILITY* pMode) GetAppVisibilityOnMonitor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfVisible) IsLauncherVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IAppVisibilityEvents* pCallback, uint32* pdwCookie) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) Unadvise;
	}


	public HRESULT GetAppVisibilityOnMonitor(HMONITOR hMonitor, MONITOR_APP_VISIBILITY* pMode) mut => VT.[Friend]GetAppVisibilityOnMonitor(&this, hMonitor, pMode);

	public HRESULT IsLauncherVisible(BOOL* pfVisible) mut => VT.[Friend]IsLauncherVisible(&this, pfVisible);

	public HRESULT Advise(IAppVisibilityEvents* pCallback, uint32* pdwCookie) mut => VT.[Friend]Advise(&this, pCallback, pdwCookie);

	public HRESULT Unadvise(uint32 dwCookie) mut => VT.[Friend]Unadvise(&this, dwCookie);
}

[CRepr]struct IPackageExecutionStateChangeNotification : IUnknown
{
	public new const Guid IID = .(0x1bb12a62, 0x2ad8, 0x432b, 0x8c, 0xcf, 0x0c, 0x2c, 0x52, 0xaf, 0xcd, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPackageFullName, PACKAGE_EXECUTION_STATE pesNewState) OnStateChanged;
	}


	public HRESULT OnStateChanged(PWSTR pszPackageFullName, PACKAGE_EXECUTION_STATE pesNewState) mut => VT.[Friend]OnStateChanged(&this, pszPackageFullName, pesNewState);
}

[CRepr]struct IPackageDebugSettings : IUnknown
{
	public new const Guid IID = .(0xf27c3930, 0x8029, 0x4ad1, 0x94, 0xe3, 0x3d, 0xba, 0x41, 0x78, 0x10, 0xc1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, PWSTR debuggerCommandLine, PWSTR environment) EnableDebugging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) DisableDebugging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) Resume;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) TerminateAllProcesses;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 sessionId) SetTargetSessionId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, uint32* taskCount, Guid** taskIds, PWSTR** taskNames) EnumerateBackgroundTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid taskId) ActivateBackgroundTask;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) StartServicing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) StopServicing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, uint32 sessionId) StartSessionRedirection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName) StopSessionRedirection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, PACKAGE_EXECUTION_STATE* packageExecutionState) GetPackageExecutionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, IPackageExecutionStateChangeNotification* pPackageExecutionStateChangeNotification, uint32* pdwCookie) RegisterForPackageStateChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCookie) UnregisterForPackageStateChanges;
	}


	public HRESULT EnableDebugging(PWSTR packageFullName, PWSTR debuggerCommandLine, PWSTR environment) mut => VT.[Friend]EnableDebugging(&this, packageFullName, debuggerCommandLine, environment);

	public HRESULT DisableDebugging(PWSTR packageFullName) mut => VT.[Friend]DisableDebugging(&this, packageFullName);

	public HRESULT Suspend(PWSTR packageFullName) mut => VT.[Friend]Suspend(&this, packageFullName);

	public HRESULT Resume(PWSTR packageFullName) mut => VT.[Friend]Resume(&this, packageFullName);

	public HRESULT TerminateAllProcesses(PWSTR packageFullName) mut => VT.[Friend]TerminateAllProcesses(&this, packageFullName);

	public HRESULT SetTargetSessionId(uint32 sessionId) mut => VT.[Friend]SetTargetSessionId(&this, sessionId);

	public HRESULT EnumerateBackgroundTasks(PWSTR packageFullName, uint32* taskCount, Guid** taskIds, PWSTR** taskNames) mut => VT.[Friend]EnumerateBackgroundTasks(&this, packageFullName, taskCount, taskIds, taskNames);

	public HRESULT ActivateBackgroundTask(in Guid taskId) mut => VT.[Friend]ActivateBackgroundTask(&this, taskId);

	public HRESULT StartServicing(PWSTR packageFullName) mut => VT.[Friend]StartServicing(&this, packageFullName);

	public HRESULT StopServicing(PWSTR packageFullName) mut => VT.[Friend]StopServicing(&this, packageFullName);

	public HRESULT StartSessionRedirection(PWSTR packageFullName, uint32 sessionId) mut => VT.[Friend]StartSessionRedirection(&this, packageFullName, sessionId);

	public HRESULT StopSessionRedirection(PWSTR packageFullName) mut => VT.[Friend]StopSessionRedirection(&this, packageFullName);

	public HRESULT GetPackageExecutionState(PWSTR packageFullName, PACKAGE_EXECUTION_STATE* packageExecutionState) mut => VT.[Friend]GetPackageExecutionState(&this, packageFullName, packageExecutionState);

	public HRESULT RegisterForPackageStateChanges(PWSTR packageFullName, IPackageExecutionStateChangeNotification* pPackageExecutionStateChangeNotification, uint32* pdwCookie) mut => VT.[Friend]RegisterForPackageStateChanges(&this, packageFullName, pPackageExecutionStateChangeNotification, pdwCookie);

	public HRESULT UnregisterForPackageStateChanges(uint32 dwCookie) mut => VT.[Friend]UnregisterForPackageStateChanges(&this, dwCookie);
}

[CRepr]struct IPackageDebugSettings2 : IPackageDebugSettings
{
	public new const Guid IID = .(0x6e3194bb, 0xab82, 0x4d22, 0x93, 0xf5, 0xfa, 0xbd, 0xa4, 0x0e, 0x7b, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPackageDebugSettings.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR packageFullName, uint32* appCount, PWSTR** appUserModelIds, PWSTR** appDisplayNames) EnumerateApps;
	}


	public HRESULT EnumerateApps(PWSTR packageFullName, uint32* appCount, PWSTR** appUserModelIds, PWSTR** appDisplayNames) mut => VT.[Friend]EnumerateApps(&this, packageFullName, appCount, appUserModelIds, appDisplayNames);
}

[CRepr]struct ISuspensionDependencyManager : IUnknown
{
	public new const Guid IID = .(0x52b83a42, 0x2543, 0x416a, 0x81, 0xd9, 0xc0, 0xde, 0x79, 0x69, 0xc8, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE processHandle) RegisterAsChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE childProcessHandle) GroupChildWithParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HANDLE childProcessHandle) UngroupChildFromParent;
	}


	public HRESULT RegisterAsChild(HANDLE processHandle) mut => VT.[Friend]RegisterAsChild(&this, processHandle);

	public HRESULT GroupChildWithParent(HANDLE childProcessHandle) mut => VT.[Friend]GroupChildWithParent(&this, childProcessHandle);

	public HRESULT UngroupChildFromParent(HANDLE childProcessHandle) mut => VT.[Friend]UngroupChildFromParent(&this, childProcessHandle);
}

[CRepr]struct IExecuteCommandApplicationHostEnvironment : IUnknown
{
	public new const Guid IID = .(0x18b21aa9, 0xe184, 0x4ff0, 0x9f, 0x5e, 0xf8, 0x82, 0xd0, 0x37, 0x71, 0xb3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, AHE_TYPE* pahe) GetValue;
	}


	public HRESULT GetValue(AHE_TYPE* pahe) mut => VT.[Friend]GetValue(&this, pahe);
}

[CRepr]struct IExecuteCommandHost : IUnknown
{
	public new const Guid IID = .(0x4b6832a2, 0x5f04, 0x4c9d, 0xb8, 0x9d, 0x72, 0x7a, 0x15, 0xd1, 0x03, 0xe7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EC_HOST_UI_MODE* pUIMode) GetUIMode;
	}


	public HRESULT GetUIMode(EC_HOST_UI_MODE* pUIMode) mut => VT.[Friend]GetUIMode(&this, pUIMode);
}

[CRepr]struct IApplicationDesignModeSettings : IUnknown
{
	public new const Guid IID = .(0x2a3dee9a, 0xe31d, 0x46d6, 0x85, 0x08, 0xbc, 0xc5, 0x97, 0xdb, 0x35, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE nativeDisplaySizePixels) SetNativeDisplaySize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, DEVICE_SCALE_FACTOR scaleFactor) SetScaleFactor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_STATE viewState) SetApplicationViewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* applicationSizePixels) ComputeApplicationSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_STATE viewState, SIZE nativeDisplaySizePixels, DEVICE_SCALE_FACTOR scaleFactor, BOOL* supported) IsApplicationViewStateSupported;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EDGE_GESTURE_KIND edgeGestureKind) TriggerEdgeGesture;
	}


	public HRESULT SetNativeDisplaySize(SIZE nativeDisplaySizePixels) mut => VT.[Friend]SetNativeDisplaySize(&this, nativeDisplaySizePixels);

	public HRESULT SetScaleFactor(DEVICE_SCALE_FACTOR scaleFactor) mut => VT.[Friend]SetScaleFactor(&this, scaleFactor);

	public HRESULT SetApplicationViewState(APPLICATION_VIEW_STATE viewState) mut => VT.[Friend]SetApplicationViewState(&this, viewState);

	public HRESULT ComputeApplicationSize(SIZE* applicationSizePixels) mut => VT.[Friend]ComputeApplicationSize(&this, applicationSizePixels);

	public HRESULT IsApplicationViewStateSupported(APPLICATION_VIEW_STATE viewState, SIZE nativeDisplaySizePixels, DEVICE_SCALE_FACTOR scaleFactor, BOOL* supported) mut => VT.[Friend]IsApplicationViewStateSupported(&this, viewState, nativeDisplaySizePixels, scaleFactor, supported);

	public HRESULT TriggerEdgeGesture(EDGE_GESTURE_KIND edgeGestureKind) mut => VT.[Friend]TriggerEdgeGesture(&this, edgeGestureKind);
}

[CRepr]struct IApplicationDesignModeSettings2 : IApplicationDesignModeSettings
{
	public new const Guid IID = .(0x490514e1, 0x675a, 0x4d6e, 0xa5, 0x8d, 0xe5, 0x49, 0x01, 0xb4, 0xca, 0x2f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IApplicationDesignModeSettings.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NATIVE_DISPLAY_ORIENTATION nativeDisplayOrientation) SetNativeDisplayOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_ORIENTATION viewOrientation) SetApplicationViewOrientation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ADJACENT_DISPLAY_EDGES adjacentDisplayEdges) SetAdjacentDisplayEdges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isOnLockScreen) SetIsOnLockScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_MIN_WIDTH viewMinWidth) SetApplicationViewMinWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* minApplicationSizePixels, SIZE* maxApplicationSizePixels) GetApplicationSizeBounds;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE applicationSizePixels, APPLICATION_VIEW_ORIENTATION* viewOrientation) GetApplicationViewOrientation;
	}


	public HRESULT SetNativeDisplayOrientation(NATIVE_DISPLAY_ORIENTATION nativeDisplayOrientation) mut => VT.[Friend]SetNativeDisplayOrientation(&this, nativeDisplayOrientation);

	public HRESULT SetApplicationViewOrientation(APPLICATION_VIEW_ORIENTATION viewOrientation) mut => VT.[Friend]SetApplicationViewOrientation(&this, viewOrientation);

	public HRESULT SetAdjacentDisplayEdges(ADJACENT_DISPLAY_EDGES adjacentDisplayEdges) mut => VT.[Friend]SetAdjacentDisplayEdges(&this, adjacentDisplayEdges);

	public HRESULT SetIsOnLockScreen(BOOL isOnLockScreen) mut => VT.[Friend]SetIsOnLockScreen(&this, isOnLockScreen);

	public HRESULT SetApplicationViewMinWidth(APPLICATION_VIEW_MIN_WIDTH viewMinWidth) mut => VT.[Friend]SetApplicationViewMinWidth(&this, viewMinWidth);

	public HRESULT GetApplicationSizeBounds(SIZE* minApplicationSizePixels, SIZE* maxApplicationSizePixels) mut => VT.[Friend]GetApplicationSizeBounds(&this, minApplicationSizePixels, maxApplicationSizePixels);

	public HRESULT GetApplicationViewOrientation(SIZE applicationSizePixels, APPLICATION_VIEW_ORIENTATION* viewOrientation) mut => VT.[Friend]GetApplicationViewOrientation(&this, applicationSizePixels, viewOrientation);
}

[CRepr]struct ILaunchTargetMonitor : IUnknown
{
	public new const Guid IID = .(0x266fbc7e, 0x490d, 0x46ed, 0xa9, 0x6b, 0x22, 0x74, 0xdb, 0x25, 0x20, 0x03);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR* monitor) GetMonitor;
	}


	public HRESULT GetMonitor(HMONITOR* monitor) mut => VT.[Friend]GetMonitor(&this, monitor);
}

[CRepr]struct ILaunchSourceViewSizePreference : IUnknown
{
	public new const Guid IID = .(0xe5aa01f7, 0x1fb8, 0x4830, 0x87, 0x20, 0x4e, 0x67, 0x34, 0xcb, 0xd5, 0xf3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* hwnd) GetSourceViewToPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_SIZE_PREFERENCE* sourceSizeAfterLaunch) GetSourceViewSizePreference;
	}


	public HRESULT GetSourceViewToPosition(HWND* hwnd) mut => VT.[Friend]GetSourceViewToPosition(&this, hwnd);

	public HRESULT GetSourceViewSizePreference(APPLICATION_VIEW_SIZE_PREFERENCE* sourceSizeAfterLaunch) mut => VT.[Friend]GetSourceViewSizePreference(&this, sourceSizeAfterLaunch);
}

[CRepr]struct ILaunchTargetViewSizePreference : IUnknown
{
	public new const Guid IID = .(0x2f0666c6, 0x12f7, 0x4360, 0xb5, 0x11, 0xa3, 0x94, 0xa0, 0x55, 0x37, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPLICATION_VIEW_SIZE_PREFERENCE* targetSizeOnLaunch) GetTargetViewSizePreference;
	}


	public HRESULT GetTargetViewSizePreference(APPLICATION_VIEW_SIZE_PREFERENCE* targetSizeOnLaunch) mut => VT.[Friend]GetTargetViewSizePreference(&this, targetSizeOnLaunch);
}

[CRepr]struct ILaunchSourceAppUserModelId : IUnknown
{
	public new const Guid IID = .(0x989191ac, 0x28ff, 0x4cf0, 0x95, 0x84, 0xe0, 0xd0, 0x78, 0xbc, 0x23, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* launchingApp) GetAppUserModelId;
	}


	public HRESULT GetAppUserModelId(PWSTR* launchingApp) mut => VT.[Friend]GetAppUserModelId(&this, launchingApp);
}

[CRepr]struct IInitializeWithWindow : IUnknown
{
	public new const Guid IID = .(0x3e68d4bd, 0x7135, 0x4d10, 0x80, 0x18, 0x9f, 0xb6, 0xd9, 0xf3, 0x3f, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) Initialize;
	}


	public HRESULT Initialize(HWND hwnd) mut => VT.[Friend]Initialize(&this, hwnd);
}

[CRepr]struct IHandlerInfo : IUnknown
{
	public new const Guid IID = .(0x997706ef, 0xf880, 0x453b, 0x81, 0x18, 0x39, 0xe1, 0xa2, 0xd2, 0x65, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetApplicationDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetApplicationPublisher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetApplicationIconReference;
	}


	public HRESULT GetApplicationDisplayName(PWSTR* value) mut => VT.[Friend]GetApplicationDisplayName(&this, value);

	public HRESULT GetApplicationPublisher(PWSTR* value) mut => VT.[Friend]GetApplicationPublisher(&this, value);

	public HRESULT GetApplicationIconReference(PWSTR* value) mut => VT.[Friend]GetApplicationIconReference(&this, value);
}

[CRepr]struct IHandlerInfo2 : IHandlerInfo
{
	public new const Guid IID = .(0x31cca04c, 0x04d3, 0x4ea9, 0x90, 0xde, 0x97, 0xb1, 0x5e, 0x87, 0xa5, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IHandlerInfo.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* value) GetApplicationId;
	}


	public HRESULT GetApplicationId(PWSTR* value) mut => VT.[Friend]GetApplicationId(&this, value);
}

[CRepr]struct IHandlerActivationHost : IUnknown
{
	public new const Guid IID = .(0x35094a87, 0x8bb1, 0x4237, 0x96, 0xc6, 0xc4, 0x17, 0xee, 0xbd, 0xb0, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidHandler, IShellItemArray* itemsBeingActivated, IHandlerInfo* handlerInfo) BeforeCoCreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR applicationPath, PWSTR commandLine, IHandlerInfo* handlerInfo) BeforeCreateProcess;
	}


	public HRESULT BeforeCoCreateInstance(in Guid clsidHandler, IShellItemArray* itemsBeingActivated, IHandlerInfo* handlerInfo) mut => VT.[Friend]BeforeCoCreateInstance(&this, clsidHandler, itemsBeingActivated, handlerInfo);

	public HRESULT BeforeCreateProcess(PWSTR applicationPath, PWSTR commandLine, IHandlerInfo* handlerInfo) mut => VT.[Friend]BeforeCreateProcess(&this, applicationPath, commandLine, handlerInfo);
}

[CRepr]struct IAppActivationUIInfo : IUnknown
{
	public new const Guid IID = .(0xabad189d, 0x9fa3, 0x4278, 0xb3, 0xca, 0x8c, 0xa4, 0x48, 0xa8, 0x8d, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR* value) GetMonitor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* value) GetInvokePoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* value) GetShowCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* value) GetShowUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* value) GetKeyState;
	}


	public HRESULT GetMonitor(HMONITOR* value) mut => VT.[Friend]GetMonitor(&this, value);

	public HRESULT GetInvokePoint(POINT* value) mut => VT.[Friend]GetInvokePoint(&this, value);

	public HRESULT GetShowCommand(int32* value) mut => VT.[Friend]GetShowCommand(&this, value);

	public HRESULT GetShowUI(BOOL* value) mut => VT.[Friend]GetShowUI(&this, value);

	public HRESULT GetKeyState(uint32* value) mut => VT.[Friend]GetKeyState(&this, value);
}

[CRepr]struct IContactManagerInterop : IUnknown
{
	public new const Guid IID = .(0x99eacba7, 0xe073, 0x43b6, 0xa8, 0x96, 0x55, 0xaf, 0xe4, 0x8a, 0x08, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND appWindow, IUnknown* contact, RECT* selection, FLYOUT_PLACEMENT preferredPlacement) ShowContactCardForWindow;
	}


	public HRESULT ShowContactCardForWindow(HWND appWindow, IUnknown* contact, RECT* selection, FLYOUT_PLACEMENT preferredPlacement) mut => VT.[Friend]ShowContactCardForWindow(&this, appWindow, contact, selection, preferredPlacement);
}

[CRepr]struct IShellIconOverlayIdentifier : IUnknown
{
	public new const Guid IID = .(0x0c6c4200, 0xc589, 0x11d0, 0x99, 0x9a, 0x00, 0xc0, 0x4f, 0xd6, 0x55, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPath, uint32 dwAttrib) IsMemberOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszIconFile, int32 cchMax, int32* pIndex, uint32* pdwFlags) GetOverlayInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pPriority) GetPriority;
	}


	public HRESULT IsMemberOf(PWSTR pwszPath, uint32 dwAttrib) mut => VT.[Friend]IsMemberOf(&this, pwszPath, dwAttrib);

	public HRESULT GetOverlayInfo(char16* pwszIconFile, int32 cchMax, int32* pIndex, uint32* pdwFlags) mut => VT.[Friend]GetOverlayInfo(&this, pwszIconFile, cchMax, pIndex, pdwFlags);

	public HRESULT GetPriority(int32* pPriority) mut => VT.[Friend]GetPriority(&this, pPriority);
}

[CRepr]struct IBannerNotificationHandler : IUnknown
{
	public new const Guid IID = .(0x8d7b2ba7, 0xdb05, 0x46a8, 0x82, 0x3c, 0xd2, 0xb6, 0xde, 0x08, 0xee, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BANNER_NOTIFICATION* notification) OnBannerEvent;
	}


	public HRESULT OnBannerEvent(BANNER_NOTIFICATION* notification) mut => VT.[Friend]OnBannerEvent(&this, notification);
}

[CRepr]struct ISortColumnArray : IUnknown
{
	public new const Guid IID = .(0x6dfc60fb, 0xf2e9, 0x459b, 0xbe, 0xb5, 0x28, 0x8f, 0x1a, 0x7c, 0x7d, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* columnCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, SORTCOLUMN* sortcolumn) GetAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SORT_ORDER_TYPE* type) GetSortType;
	}


	public HRESULT GetCount(uint32* columnCount) mut => VT.[Friend]GetCount(&this, columnCount);

	public HRESULT GetAt(uint32 index, SORTCOLUMN* sortcolumn) mut => VT.[Friend]GetAt(&this, index, sortcolumn);

	public HRESULT GetSortType(SORT_ORDER_TYPE* type) mut => VT.[Friend]GetSortType(&this, type);
}

[CRepr]struct IPropertyKeyStore : IUnknown
{
	public new const Guid IID = .(0x75bd59aa, 0xf23b, 0x4963, 0xab, 0xa4, 0x0b, 0x35, 0x57, 0x52, 0xa9, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* keyCount) GetKeyCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index, PROPERTYKEY* pkey) GetKeyAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) AppendKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 index) DeleteKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) IsKeyInStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key) RemoveKey;
	}


	public HRESULT GetKeyCount(int32* keyCount) mut => VT.[Friend]GetKeyCount(&this, keyCount);

	public HRESULT GetKeyAt(int32 index, PROPERTYKEY* pkey) mut => VT.[Friend]GetKeyAt(&this, index, pkey);

	public HRESULT AppendKey(PROPERTYKEY* key) mut => VT.[Friend]AppendKey(&this, key);

	public HRESULT DeleteKey(int32 index) mut => VT.[Friend]DeleteKey(&this, index);

	public HRESULT IsKeyInStore(PROPERTYKEY* key) mut => VT.[Friend]IsKeyInStore(&this, key);

	public HRESULT RemoveKey(PROPERTYKEY* key) mut => VT.[Friend]RemoveKey(&this, key);
}

[CRepr]struct IQueryCodePage : IUnknown
{
	public new const Guid IID = .(0xc7b236ce, 0xee80, 0x11d0, 0x98, 0x5f, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puiCodePage) GetCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCodePage) SetCodePage;
	}


	public HRESULT GetCodePage(uint32* puiCodePage) mut => VT.[Friend]GetCodePage(&this, puiCodePage);

	public HRESULT SetCodePage(uint32 uiCodePage) mut => VT.[Friend]SetCodePage(&this, uiCodePage);
}

[CRepr]struct IFolderViewOptions : IUnknown
{
	public new const Guid IID = .(0x3cc974d2, 0xb302, 0x4d36, 0xad, 0x3e, 0x06, 0xd9, 0x3f, 0x69, 0x5d, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERVIEWOPTIONS fvoMask, FOLDERVIEWOPTIONS fvoFlags) SetFolderViewOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERVIEWOPTIONS* pfvoFlags) GetFolderViewOptions;
	}


	public HRESULT SetFolderViewOptions(FOLDERVIEWOPTIONS fvoMask, FOLDERVIEWOPTIONS fvoFlags) mut => VT.[Friend]SetFolderViewOptions(&this, fvoMask, fvoFlags);

	public HRESULT GetFolderViewOptions(FOLDERVIEWOPTIONS* pfvoFlags) mut => VT.[Friend]GetFolderViewOptions(&this, pfvoFlags);
}

[CRepr]struct IShellView3 : IShellView2
{
	public new const Guid IID = .(0xec39fa88, 0xf8af, 0x41c5, 0x84, 0x21, 0x38, 0xbe, 0xd2, 0x8f, 0x46, 0x73);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellView2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellBrowser* psbOwner, IShellView* psvPrev, uint32 dwViewFlags, FOLDERFLAGS dwMask, FOLDERFLAGS dwFlags, FOLDERVIEWMODE fvMode, in Guid pvid, RECT* prcView, HWND* phwndView) CreateViewWindow3;
	}


	public HRESULT CreateViewWindow3(IShellBrowser* psbOwner, IShellView* psvPrev, uint32 dwViewFlags, FOLDERFLAGS dwMask, FOLDERFLAGS dwFlags, FOLDERVIEWMODE fvMode, in Guid pvid, RECT* prcView, HWND* phwndView) mut => VT.[Friend]CreateViewWindow3(&this, psbOwner, psvPrev, dwViewFlags, dwMask, dwFlags, fvMode, pvid, prcView, phwndView);
}

[CRepr]struct ISearchBoxInfo : IUnknown
{
	public new const Guid IID = .(0x6af6e03f, 0xd664, 0x4ef4, 0x96, 0x26, 0xf7, 0xe0, 0xed, 0x36, 0x75, 0x5e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) GetCondition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppsz) GetText;
	}


	public HRESULT GetCondition(in Guid riid, void** ppv) mut => VT.[Friend]GetCondition(&this, riid, ppv);

	public HRESULT GetText(PWSTR* ppsz) mut => VT.[Friend]GetText(&this, ppsz);
}

[CRepr]struct IVisualProperties : IUnknown
{
	public new const Guid IID = .(0xe693cf68, 0xd967, 0x4112, 0x87, 0x63, 0x99, 0x17, 0x2a, 0xee, 0x5e, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hbmp, VPWATERMARKFLAGS vpwf) SetWatermark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VPCOLORFLAGS vpcf, COLORREF cr) SetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VPCOLORFLAGS vpcf, COLORREF* pcr) GetColor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cyItemInPixels) SetItemHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* cyItemInPixels) GetItemHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGFONTW* plf, BOOL bRedraw) SetFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LOGFONTW* plf) GetFont;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubAppName, PWSTR pszSubIdList) SetTheme;
	}


	public HRESULT SetWatermark(HBITMAP hbmp, VPWATERMARKFLAGS vpwf) mut => VT.[Friend]SetWatermark(&this, hbmp, vpwf);

	public HRESULT SetColor(VPCOLORFLAGS vpcf, COLORREF cr) mut => VT.[Friend]SetColor(&this, vpcf, cr);

	public HRESULT GetColor(VPCOLORFLAGS vpcf, COLORREF* pcr) mut => VT.[Friend]GetColor(&this, vpcf, pcr);

	public HRESULT SetItemHeight(int32 cyItemInPixels) mut => VT.[Friend]SetItemHeight(&this, cyItemInPixels);

	public HRESULT GetItemHeight(int32* cyItemInPixels) mut => VT.[Friend]GetItemHeight(&this, cyItemInPixels);

	public HRESULT SetFont(LOGFONTW* plf, BOOL bRedraw) mut => VT.[Friend]SetFont(&this, plf, bRedraw);

	public HRESULT GetFont(LOGFONTW* plf) mut => VT.[Friend]GetFont(&this, plf);

	public HRESULT SetTheme(PWSTR pszSubAppName, PWSTR pszSubIdList) mut => VT.[Friend]SetTheme(&this, pszSubAppName, pszSubIdList);
}

[CRepr]struct ICommDlgBrowser3 : ICommDlgBrowser2
{
	public new const Guid IID = .(0xc8ad25a1, 0x3294, 0x41ee, 0x81, 0x65, 0x71, 0x17, 0x4b, 0xd0, 0x1c, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICommDlgBrowser2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv, int32 iColumn) OnColumnClicked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszFileSpec, int32 cchFileSpec) GetCurrentFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* ppshv) OnPreViewCreated;
	}


	public HRESULT OnColumnClicked(IShellView* ppshv, int32 iColumn) mut => VT.[Friend]OnColumnClicked(&this, ppshv, iColumn);

	public HRESULT GetCurrentFilter(char16* pszFileSpec, int32 cchFileSpec) mut => VT.[Friend]GetCurrentFilter(&this, pszFileSpec, cchFileSpec);

	public HRESULT OnPreViewCreated(IShellView* ppshv) mut => VT.[Friend]OnPreViewCreated(&this, ppshv);
}

[CRepr]struct IUserAccountChangeCallback : IUnknown
{
	public new const Guid IID = .(0xa561e69a, 0xb4b8, 0x4113, 0x91, 0xa5, 0x64, 0xc6, 0xbc, 0xca, 0x34, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUserName) OnPictureChange;
	}


	public HRESULT OnPictureChange(PWSTR pszUserName) mut => VT.[Friend]OnPictureChange(&this, pszUserName);
}

[CRepr]struct IStreamAsync : IStream
{
	public new const Guid IID = .(0xfe0b6665, 0xe0ca, 0x49b9, 0xa1, 0x78, 0x2b, 0x5c, 0xb4, 0x8d, 0x92, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IStream.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* pv, uint32 cb, uint32* pcbRead, OVERLAPPED* lpOverlapped) ReadAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, void* lpBuffer, uint32 cb, uint32* pcbWritten, OVERLAPPED* lpOverlapped) WriteAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, BOOL bWait) OverlappedResult;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CancelIo;
	}


	public HRESULT ReadAsync(void* pv, uint32 cb, uint32* pcbRead, OVERLAPPED* lpOverlapped) mut => VT.[Friend]ReadAsync(&this, pv, cb, pcbRead, lpOverlapped);

	public HRESULT WriteAsync(void* lpBuffer, uint32 cb, uint32* pcbWritten, OVERLAPPED* lpOverlapped) mut => VT.[Friend]WriteAsync(&this, lpBuffer, cb, pcbWritten, lpOverlapped);

	public HRESULT OverlappedResult(OVERLAPPED* lpOverlapped, uint32* lpNumberOfBytesTransferred, BOOL bWait) mut => VT.[Friend]OverlappedResult(&this, lpOverlapped, lpNumberOfBytesTransferred, bWait);

	public HRESULT CancelIo() mut => VT.[Friend]CancelIo(&this);
}

[CRepr]struct IStreamUnbufferedInfo : IUnknown
{
	public new const Guid IID = .(0x8a68fdda, 0x1fdc, 0x4c20, 0x8c, 0xeb, 0x41, 0x66, 0x43, 0xb5, 0xa6, 0x25);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcbSectorSize) GetSectorSize;
	}


	public HRESULT GetSectorSize(uint32* pcbSectorSize) mut => VT.[Friend]GetSectorSize(&this, pcbSectorSize);
}

[CRepr]struct IDragSourceHelper2 : IDragSourceHelper
{
	public new const Guid IID = .(0x83e07d0d, 0x0c5f, 0x4163, 0xbf, 0x1a, 0x60, 0xb2, 0x74, 0x05, 0x1e, 0x40);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDragSourceHelper.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) SetFlags;
	}


	public HRESULT SetFlags(uint32 dwFlags) mut => VT.[Friend]SetFlags(&this, dwFlags);
}

[CRepr]struct IHWEventHandler : IUnknown
{
	public new const Guid IID = .(0xc1fb73d0, 0xec3a, 0x4ba2, 0xb5, 0x12, 0x8c, 0xdb, 0x91, 0x87, 0xb6, 0xd1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszParams) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType) HandleEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType, PWSTR pszContentTypeHandler, IDataObject* pdataobject) HandleEventWithContent;
	}


	public HRESULT Initialize(PWSTR pszParams) mut => VT.[Friend]Initialize(&this, pszParams);

	public HRESULT HandleEvent(PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType) mut => VT.[Friend]HandleEvent(&this, pszDeviceID, pszAltDeviceID, pszEventType);

	public HRESULT HandleEventWithContent(PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType, PWSTR pszContentTypeHandler, IDataObject* pdataobject) mut => VT.[Friend]HandleEventWithContent(&this, pszDeviceID, pszAltDeviceID, pszEventType, pszContentTypeHandler, pdataobject);
}

[CRepr]struct IHWEventHandler2 : IHWEventHandler
{
	public new const Guid IID = .(0xcfcc809f, 0x295d, 0x42e8, 0x9f, 0xfc, 0x42, 0x4b, 0x33, 0xc4, 0x87, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IHWEventHandler.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType, HWND hwndOwner) HandleEventWithHWND;
	}


	public HRESULT HandleEventWithHWND(PWSTR pszDeviceID, PWSTR pszAltDeviceID, PWSTR pszEventType, HWND hwndOwner) mut => VT.[Friend]HandleEventWithHWND(&this, pszDeviceID, pszAltDeviceID, pszEventType, hwndOwner);
}

[CRepr]struct IQueryCancelAutoPlay : IUnknown
{
	public new const Guid IID = .(0xddefe873, 0x6997, 0x4e68, 0xbe, 0x26, 0x39, 0xb6, 0x33, 0xad, 0xbe, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, uint32 dwContentType, PWSTR pszLabel, uint32 dwSerialNumber) AllowAutoPlay;
	}


	public HRESULT AllowAutoPlay(PWSTR pszPath, uint32 dwContentType, PWSTR pszLabel, uint32 dwSerialNumber) mut => VT.[Friend]AllowAutoPlay(&this, pszPath, dwContentType, pszLabel, dwSerialNumber);
}

[CRepr]struct IDynamicHWHandler : IUnknown
{
	public new const Guid IID = .(0xdc2601d7, 0x059e, 0x42fc, 0xa0, 0x9d, 0x2a, 0xfd, 0x21, 0xb6, 0xd5, 0xf7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDeviceID, uint32 dwContentType, PWSTR* ppszAction) GetDynamicInfo;
	}


	public HRESULT GetDynamicInfo(PWSTR pszDeviceID, uint32 dwContentType, PWSTR* ppszAction) mut => VT.[Friend]GetDynamicInfo(&this, pszDeviceID, dwContentType, ppszAction);
}

[CRepr]struct IUserNotificationCallback : IUnknown
{
	public new const Guid IID = .(0x19108294, 0x0441, 0x4aff, 0x80, 0x13, 0xfa, 0x0a, 0x73, 0x0b, 0x0b, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* pt) OnBalloonUserClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* pt) OnLeftClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* pt) OnContextMenu;
	}


	public HRESULT OnBalloonUserClick(POINT* pt) mut => VT.[Friend]OnBalloonUserClick(&this, pt);

	public HRESULT OnLeftClick(POINT* pt) mut => VT.[Friend]OnLeftClick(&this, pt);

	public HRESULT OnContextMenu(POINT* pt) mut => VT.[Friend]OnContextMenu(&this, pt);
}

[CRepr]struct IUserNotification2 : IUnknown
{
	public new const Guid IID = .(0x215913cc, 0x57eb, 0x4fab, 0xab, 0x5a, 0xe5, 0xfa, 0x7b, 0xea, 0x2a, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle, PWSTR pszText, uint32 dwInfoFlags) SetBalloonInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwShowTime, uint32 dwInterval, uint32 cRetryCount) SetBalloonRetry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON hIcon, PWSTR pszToolTip) SetIconInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IQueryContinue* pqc, uint32 dwContinuePollInterval, IUserNotificationCallback* pSink) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSoundName) PlaySound;
	}


	public HRESULT SetBalloonInfo(PWSTR pszTitle, PWSTR pszText, uint32 dwInfoFlags) mut => VT.[Friend]SetBalloonInfo(&this, pszTitle, pszText, dwInfoFlags);

	public HRESULT SetBalloonRetry(uint32 dwShowTime, uint32 dwInterval, uint32 cRetryCount) mut => VT.[Friend]SetBalloonRetry(&this, dwShowTime, dwInterval, cRetryCount);

	public HRESULT SetIconInfo(HICON hIcon, PWSTR pszToolTip) mut => VT.[Friend]SetIconInfo(&this, hIcon, pszToolTip);

	public HRESULT Show(IQueryContinue* pqc, uint32 dwContinuePollInterval, IUserNotificationCallback* pSink) mut => VT.[Friend]Show(&this, pqc, dwContinuePollInterval, pSink);

	public HRESULT PlaySound(PWSTR pszSoundName) mut => VT.[Friend]PlaySound(&this, pszSoundName);
}

[CRepr]struct IDeskBand2 : IDeskBand
{
	public new const Guid IID = .(0x79d16de4, 0xabee, 0x4021, 0x8d, 0x9d, 0x91, 0x69, 0xb2, 0x61, 0xd6, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDeskBand.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCanRenderComposited) CanRenderComposited;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fCompositionEnabled) SetCompositionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCompositionEnabled) GetCompositionState;
	}


	public HRESULT CanRenderComposited(BOOL* pfCanRenderComposited) mut => VT.[Friend]CanRenderComposited(&this, pfCanRenderComposited);

	public HRESULT SetCompositionState(BOOL fCompositionEnabled) mut => VT.[Friend]SetCompositionState(&this, fCompositionEnabled);

	public HRESULT GetCompositionState(BOOL* pfCompositionEnabled) mut => VT.[Friend]GetCompositionState(&this, pfCompositionEnabled);
}

[CRepr]struct IStartMenuPinnedList : IUnknown
{
	public new const Guid IID = .(0x4cd19ada, 0x25a5, 0x4a32, 0xb3, 0xb7, 0x34, 0x7b, 0xee, 0x5b, 0xe3, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* pitem) RemoveFromList;
	}


	public HRESULT RemoveFromList(IShellItem* pitem) mut => VT.[Friend]RemoveFromList(&this, pitem);
}

[CRepr]struct ICDBurn : IUnknown
{
	public new const Guid IID = .(0x3d73a659, 0xe5d0, 0x4d42, 0xaf, 0xc0, 0x51, 0x21, 0xba, 0x42, 0x5c, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszDrive, uint32 cch) GetRecorderDriveLetter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) Burn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfHasRecorder) HasRecordableDrive;
	}


	public HRESULT GetRecorderDriveLetter(char16* pszDrive, uint32 cch) mut => VT.[Friend]GetRecorderDriveLetter(&this, pszDrive, cch);

	public HRESULT Burn(HWND hwnd) mut => VT.[Friend]Burn(&this, hwnd);

	public HRESULT HasRecordableDrive(BOOL* pfHasRecorder) mut => VT.[Friend]HasRecordableDrive(&this, pfHasRecorder);
}

[CRepr]struct IWizardSite : IUnknown
{
	public new const Guid IID = .(0x88960f5b, 0x422f, 0x4e7b, 0x80, 0x13, 0x73, 0x41, 0x53, 0x81, 0xc3, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* phpage) GetPreviousPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* phpage) GetNextPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* phpage) GetCancelledPage;
	}


	public HRESULT GetPreviousPage(HPROPSHEETPAGE* phpage) mut => VT.[Friend]GetPreviousPage(&this, phpage);

	public HRESULT GetNextPage(HPROPSHEETPAGE* phpage) mut => VT.[Friend]GetNextPage(&this, phpage);

	public HRESULT GetCancelledPage(HPROPSHEETPAGE* phpage) mut => VT.[Friend]GetCancelledPage(&this, phpage);
}

[CRepr]struct IWizardExtension : IUnknown
{
	public new const Guid IID = .(0xc02ea696, 0x86cc, 0x491e, 0x9b, 0x23, 0x74, 0x39, 0x4a, 0x04, 0x44, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* aPages, uint32 cPages, uint32* pnPagesAdded) AddPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* phpage) GetFirstPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE* phpage) GetLastPage;
	}


	public HRESULT AddPages(HPROPSHEETPAGE* aPages, uint32 cPages, uint32* pnPagesAdded) mut => VT.[Friend]AddPages(&this, aPages, cPages, pnPagesAdded);

	public HRESULT GetFirstPage(HPROPSHEETPAGE* phpage) mut => VT.[Friend]GetFirstPage(&this, phpage);

	public HRESULT GetLastPage(HPROPSHEETPAGE* phpage) mut => VT.[Friend]GetLastPage(&this, phpage);
}

[CRepr]struct IWebWizardExtension : IWizardExtension
{
	public new const Guid IID = .(0x0e6b3f66, 0x98d1, 0x48c0, 0xa2, 0x22, 0xfb, 0xde, 0x74, 0xe2, 0xfb, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWizardExtension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszURL) SetInitialURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszErrorURL) SetErrorURL;
	}


	public HRESULT SetInitialURL(PWSTR pszURL) mut => VT.[Friend]SetInitialURL(&this, pszURL);

	public HRESULT SetErrorURL(PWSTR pszErrorURL) mut => VT.[Friend]SetErrorURL(&this, pszErrorURL);
}

[CRepr]struct IPublishingWizard : IWizardExtension
{
	public new const Guid IID = .(0xaa9198bb, 0xccec, 0x472d, 0xbe, 0xed, 0x19, 0xa4, 0xf6, 0x73, 0x3f, 0x7a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWizardExtension.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pdo, uint32 dwOptions, PWSTR pszServiceScope) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT* phrFromTransfer, IXMLDOMDocument** pdocManifest) GetTransferManifest;
	}


	public HRESULT Initialize(IDataObject* pdo, uint32 dwOptions, PWSTR pszServiceScope) mut => VT.[Friend]Initialize(&this, pdo, dwOptions, pszServiceScope);

	public HRESULT GetTransferManifest(HRESULT* phrFromTransfer, IXMLDOMDocument** pdocManifest) mut => VT.[Friend]GetTransferManifest(&this, phrFromTransfer, pdocManifest);
}

[CRepr]struct IFolderViewHost : IUnknown
{
	public new const Guid IID = .(0x1ea58f02, 0xd55a, 0x411d, 0xb0, 0x9e, 0x9e, 0x65, 0xac, 0x21, 0x60, 0x5b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IDataObject* pdo, RECT* prc) Initialize;
	}


	public HRESULT Initialize(HWND hwndParent, IDataObject* pdo, RECT* prc) mut => VT.[Friend]Initialize(&this, hwndParent, pdo, prc);
}

[CRepr]struct IAccessibleObject : IUnknown
{
	public new const Guid IID = .(0x95a391c5, 0x9ed4, 0x4c28, 0x84, 0x01, 0xab, 0x9e, 0x06, 0x71, 0x9e, 0x11);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszName) SetAccessibleName;
	}


	public HRESULT SetAccessibleName(PWSTR pszName) mut => VT.[Friend]SetAccessibleName(&this, pszName);
}

[CRepr]struct IResultsFolder : IUnknown
{
	public new const Guid IID = .(0x96e5ae6d, 0x6ae1, 0x4b1c, 0x90, 0x0c, 0xc6, 0x48, 0x0e, 0xaa, 0x88, 0x28);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) AddItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, ITEMIDLIST** ppidlAdded) AddIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) RemoveItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) RemoveIDList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RemoveAll;
	}


	public HRESULT AddItem(IShellItem* psi) mut => VT.[Friend]AddItem(&this, psi);

	public HRESULT AddIDList(ITEMIDLIST* pidl, ITEMIDLIST** ppidlAdded) mut => VT.[Friend]AddIDList(&this, pidl, ppidlAdded);

	public HRESULT RemoveItem(IShellItem* psi) mut => VT.[Friend]RemoveItem(&this, psi);

	public HRESULT RemoveIDList(ITEMIDLIST* pidl) mut => VT.[Friend]RemoveIDList(&this, pidl);

	public HRESULT RemoveAll() mut => VT.[Friend]RemoveAll(&this);
}

[CRepr]struct IAutoCompleteDropDown : IUnknown
{
	public new const Guid IID = .(0x3cd141f4, 0x3c6a, 0x11d2, 0xbc, 0xaa, 0x00, 0xc0, 0x4f, 0xd9, 0x29, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags, PWSTR* ppwszString) GetDropDownStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetEnumerator;
	}


	public HRESULT GetDropDownStatus(uint32* pdwFlags, PWSTR* ppwszString) mut => VT.[Friend]GetDropDownStatus(&this, pdwFlags, ppwszString);

	public HRESULT ResetEnumerator() mut => VT.[Friend]ResetEnumerator(&this);
}

[CRepr]struct ICDBurnExt : IUnknown
{
	public new const Guid IID = .(0x2271dcca, 0x74fc, 0x4414, 0x8f, 0xb7, 0xc5, 0x6b, 0x05, 0xac, 0xe2, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwActions) GetSupportedActionTypes;
	}


	public HRESULT GetSupportedActionTypes(uint32* pdwActions) mut => VT.[Friend]GetSupportedActionTypes(&this, pdwActions);
}

[CRepr]struct IEnumReadyCallback : IUnknown
{
	public new const Guid IID = .(0x61e00d45, 0x8fff, 0x4e60, 0x92, 0x4e, 0x65, 0x37, 0xb6, 0x16, 0x12, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnumReady;
	}


	public HRESULT EnumReady() mut => VT.[Friend]EnumReady(&this);
}

[CRepr]struct IEnumerableView : IUnknown
{
	public new const Guid IID = .(0x8c8bf236, 0x1aec, 0x495f, 0x98, 0x94, 0x91, 0xd5, 0x7c, 0x3c, 0x68, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumReadyCallback* percb) SetEnumReadyCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlFolder, uint32 dwEnumFlags, IEnumIDList** ppEnumIDList) CreateEnumIDListFromContents;
	}


	public HRESULT SetEnumReadyCallback(IEnumReadyCallback* percb) mut => VT.[Friend]SetEnumReadyCallback(&this, percb);

	public HRESULT CreateEnumIDListFromContents(ITEMIDLIST* pidlFolder, uint32 dwEnumFlags, IEnumIDList** ppEnumIDList) mut => VT.[Friend]CreateEnumIDListFromContents(&this, pidlFolder, dwEnumFlags, ppEnumIDList);
}

[CRepr]struct IInsertItem : IUnknown
{
	public new const Guid IID = .(0xd2b57227, 0x3d23, 0x4b95, 0x93, 0xc0, 0x49, 0x2b, 0xd4, 0x54, 0xc3, 0x56);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) InsertItem;
	}


	public HRESULT InsertItem(ITEMIDLIST* pidl) mut => VT.[Friend]InsertItem(&this, pidl);
}

[CRepr]struct IFolderBandPriv : IUnknown
{
	public new const Guid IID = .(0x47c01f95, 0xe185, 0x412c, 0xb5, 0xc5, 0x4f, 0x27, 0xdf, 0x96, 0x5a, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fCascade) SetCascade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fAccelerators) SetAccelerators;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoIcons) SetNoIcons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fNoText) SetNoText;
	}


	public HRESULT SetCascade(BOOL fCascade) mut => VT.[Friend]SetCascade(&this, fCascade);

	public HRESULT SetAccelerators(BOOL fAccelerators) mut => VT.[Friend]SetAccelerators(&this, fAccelerators);

	public HRESULT SetNoIcons(BOOL fNoIcons) mut => VT.[Friend]SetNoIcons(&this, fNoIcons);

	public HRESULT SetNoText(BOOL fNoText) mut => VT.[Friend]SetNoText(&this, fNoText);
}

[CRepr]struct IImageRecompress : IUnknown
{
	public new const Guid IID = .(0x505f1513, 0x6b3e, 0x4892, 0xa2, 0x72, 0x59, 0xf8, 0x88, 0x9a, 0x4d, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, int32 cx, int32 cy, int32 iQuality, IStorage* pstg, IStream** ppstrmOut) RecompressImage;
	}


	public HRESULT RecompressImage(IShellItem* psi, int32 cx, int32 cy, int32 iQuality, IStorage* pstg, IStream** ppstrmOut) mut => VT.[Friend]RecompressImage(&this, psi, cx, cy, iQuality, pstg, ppstrmOut);
}

[CRepr]struct IFileDialogControlEvents : IUnknown
{
	public new const Guid IID = .(0x36116642, 0xd713, 0x4b97, 0x9b, 0x83, 0x74, 0x84, 0xa9, 0xd0, 0x04, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialogCustomize* pfdc, uint32 dwIDCtl, uint32 dwIDItem) OnItemSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialogCustomize* pfdc, uint32 dwIDCtl) OnButtonClicked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialogCustomize* pfdc, uint32 dwIDCtl, BOOL bChecked) OnCheckButtonToggled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IFileDialogCustomize* pfdc, uint32 dwIDCtl) OnControlActivating;
	}


	public HRESULT OnItemSelected(IFileDialogCustomize* pfdc, uint32 dwIDCtl, uint32 dwIDItem) mut => VT.[Friend]OnItemSelected(&this, pfdc, dwIDCtl, dwIDItem);

	public HRESULT OnButtonClicked(IFileDialogCustomize* pfdc, uint32 dwIDCtl) mut => VT.[Friend]OnButtonClicked(&this, pfdc, dwIDCtl);

	public HRESULT OnCheckButtonToggled(IFileDialogCustomize* pfdc, uint32 dwIDCtl, BOOL bChecked) mut => VT.[Friend]OnCheckButtonToggled(&this, pfdc, dwIDCtl, bChecked);

	public HRESULT OnControlActivating(IFileDialogCustomize* pfdc, uint32 dwIDCtl) mut => VT.[Friend]OnControlActivating(&this, pfdc, dwIDCtl);
}

[CRepr]struct IFileDialog2 : IFileDialog
{
	public new const Guid IID = .(0x61744fc7, 0x85b5, 0x4791, 0xa9, 0xb0, 0x27, 0x22, 0x76, 0x30, 0x9b, 0x13);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IFileDialog.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszLabel) SetCancelButtonLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) SetNavigationRoot;
	}


	public HRESULT SetCancelButtonLabel(PWSTR pszLabel) mut => VT.[Friend]SetCancelButtonLabel(&this, pszLabel);

	public HRESULT SetNavigationRoot(IShellItem* psi) mut => VT.[Friend]SetNavigationRoot(&this, psi);
}

[CRepr]struct IApplicationAssociationRegistrationUI : IUnknown
{
	public new const Guid IID = .(0x1f76a169, 0xf994, 0x40ac, 0x8f, 0xc8, 0x09, 0x59, 0xe8, 0x87, 0x47, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppRegistryName) LaunchAdvancedAssociationUI;
	}


	public HRESULT LaunchAdvancedAssociationUI(PWSTR pszAppRegistryName) mut => VT.[Friend]LaunchAdvancedAssociationUI(&this, pszAppRegistryName);
}

[CRepr]struct IShellRunDll : IUnknown
{
	public new const Guid IID = .(0xfce4bde0, 0x4b68, 0x4b80, 0x8e, 0x9c, 0x74, 0x26, 0x31, 0x5a, 0x73, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArgs) Run;
	}


	public HRESULT Run(PWSTR pszArgs) mut => VT.[Friend]Run(&this, pszArgs);
}

[CRepr]struct IPreviousVersionsInfo : IUnknown
{
	public new const Guid IID = .(0x76e54780, 0xad74, 0x48e3, 0xa6, 0x95, 0x3b, 0xa9, 0xa0, 0xaf, 0xf1, 0x0d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, BOOL fOkToBeSlow, BOOL* pfAvailable) AreSnapshotsAvailable;
	}


	public HRESULT AreSnapshotsAvailable(PWSTR pszPath, BOOL fOkToBeSlow, BOOL* pfAvailable) mut => VT.[Friend]AreSnapshotsAvailable(&this, pszPath, fOkToBeSlow, pfAvailable);
}

[CRepr]struct IUseToBrowseItem : IRelatedItem
{
	public new const Guid IID = .(0x05edda5c, 0x98a3, 0x4717, 0x8a, 0xdb, 0xc5, 0xe7, 0xda, 0x99, 0x1e, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IRelatedItem.VTable
	{
	}

}

[CRepr]struct INameSpaceTreeControl2 : INameSpaceTreeControl
{
	public new const Guid IID = .(0x7cc7aed8, 0x290e, 0x49bc, 0x89, 0x45, 0xc1, 0x40, 0x1c, 0xc9, 0x30, 0x6c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : INameSpaceTreeControl.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nstcsMask, uint32 nstcsStyle) SetControlStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nstcsMask, uint32* pnstcsStyle) GetControlStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NSTCSTYLE2 nstcsMask, NSTCSTYLE2 nstcsStyle) SetControlStyle2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NSTCSTYLE2 nstcsMask, NSTCSTYLE2* pnstcsStyle) GetControlStyle2;
	}


	public HRESULT SetControlStyle(uint32 nstcsMask, uint32 nstcsStyle) mut => VT.[Friend]SetControlStyle(&this, nstcsMask, nstcsStyle);

	public HRESULT GetControlStyle(uint32 nstcsMask, uint32* pnstcsStyle) mut => VT.[Friend]GetControlStyle(&this, nstcsMask, pnstcsStyle);

	public HRESULT SetControlStyle2(NSTCSTYLE2 nstcsMask, NSTCSTYLE2 nstcsStyle) mut => VT.[Friend]SetControlStyle2(&this, nstcsMask, nstcsStyle);

	public HRESULT GetControlStyle2(NSTCSTYLE2 nstcsMask, NSTCSTYLE2* pnstcsStyle) mut => VT.[Friend]GetControlStyle2(&this, nstcsMask, pnstcsStyle);
}

[CRepr]struct INameSpaceTreeControlEvents : IUnknown
{
	public new const Guid IID = .(0x93d77985, 0xb3d8, 0x4484, 0x83, 0x18, 0x67, 0x2c, 0xdd, 0xa0, 0x02, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 nstceHitTest, uint32 nstceClickType) OnItemClick;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnPropertyItemCommit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 nstcisMask, uint32 nstcisState) OnItemStateChanging;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, uint32 nstcisMask, uint32 nstcisState) OnItemStateChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItemArray* psiaSelection) OnSelectionChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMsg, WPARAM wParam, LPARAM lParam) OnKeyboardInput;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnBeforeExpand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnAfterExpand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnBeginLabelEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnEndLabelEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, char16* pszTip, int32 cchTip) OnGetToolTip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnBeforeItemDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, BOOL fIsRoot) OnItemAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, BOOL fIsRoot) OnItemDeleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, in Guid riid, void** ppv) OnBeforeContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, IContextMenu* pcmIn, in Guid riid, void** ppv) OnAfterContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnBeforeStateImageChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, int32* piDefaultIcon, int32* piOpenIcon) OnGetDefaultIconIndex;
	}


	public HRESULT OnItemClick(IShellItem* psi, uint32 nstceHitTest, uint32 nstceClickType) mut => VT.[Friend]OnItemClick(&this, psi, nstceHitTest, nstceClickType);

	public HRESULT OnPropertyItemCommit(IShellItem* psi) mut => VT.[Friend]OnPropertyItemCommit(&this, psi);

	public HRESULT OnItemStateChanging(IShellItem* psi, uint32 nstcisMask, uint32 nstcisState) mut => VT.[Friend]OnItemStateChanging(&this, psi, nstcisMask, nstcisState);

	public HRESULT OnItemStateChanged(IShellItem* psi, uint32 nstcisMask, uint32 nstcisState) mut => VT.[Friend]OnItemStateChanged(&this, psi, nstcisMask, nstcisState);

	public HRESULT OnSelectionChanged(IShellItemArray* psiaSelection) mut => VT.[Friend]OnSelectionChanged(&this, psiaSelection);

	public HRESULT OnKeyboardInput(uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]OnKeyboardInput(&this, uMsg, wParam, lParam);

	public HRESULT OnBeforeExpand(IShellItem* psi) mut => VT.[Friend]OnBeforeExpand(&this, psi);

	public HRESULT OnAfterExpand(IShellItem* psi) mut => VT.[Friend]OnAfterExpand(&this, psi);

	public HRESULT OnBeginLabelEdit(IShellItem* psi) mut => VT.[Friend]OnBeginLabelEdit(&this, psi);

	public HRESULT OnEndLabelEdit(IShellItem* psi) mut => VT.[Friend]OnEndLabelEdit(&this, psi);

	public HRESULT OnGetToolTip(IShellItem* psi, char16* pszTip, int32 cchTip) mut => VT.[Friend]OnGetToolTip(&this, psi, pszTip, cchTip);

	public HRESULT OnBeforeItemDelete(IShellItem* psi) mut => VT.[Friend]OnBeforeItemDelete(&this, psi);

	public HRESULT OnItemAdded(IShellItem* psi, BOOL fIsRoot) mut => VT.[Friend]OnItemAdded(&this, psi, fIsRoot);

	public HRESULT OnItemDeleted(IShellItem* psi, BOOL fIsRoot) mut => VT.[Friend]OnItemDeleted(&this, psi, fIsRoot);

	public HRESULT OnBeforeContextMenu(IShellItem* psi, in Guid riid, void** ppv) mut => VT.[Friend]OnBeforeContextMenu(&this, psi, riid, ppv);

	public HRESULT OnAfterContextMenu(IShellItem* psi, IContextMenu* pcmIn, in Guid riid, void** ppv) mut => VT.[Friend]OnAfterContextMenu(&this, psi, pcmIn, riid, ppv);

	public HRESULT OnBeforeStateImageChange(IShellItem* psi) mut => VT.[Friend]OnBeforeStateImageChange(&this, psi);

	public HRESULT OnGetDefaultIconIndex(IShellItem* psi, int32* piDefaultIcon, int32* piOpenIcon) mut => VT.[Friend]OnGetDefaultIconIndex(&this, psi, piDefaultIcon, piOpenIcon);
}

[CRepr]struct INameSpaceTreeControlDropHandler : IUnknown
{
	public new const Guid IID = .(0xf9c665d6, 0xc2f2, 0x4c19, 0xbf, 0x33, 0x83, 0x22, 0xd7, 0x35, 0x2f, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver, IShellItemArray* psiaData, BOOL fOutsideSource, uint32 grfKeyState, uint32* pdwEffect) OnDragEnter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver, IShellItemArray* psiaData, uint32 grfKeyState, uint32* pdwEffect) OnDragOver;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver, IShellItemArray* psiaData, int32 iNewPosition, int32 iOldPosition) OnDragPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver, IShellItemArray* psiaData, int32 iPosition, uint32 grfKeyState, uint32* pdwEffect) OnDrop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver, IShellItemArray* psiaData, int32 iNewPosition, int32 iOldPosition) OnDropPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOver) OnDragLeave;
	}


	public HRESULT OnDragEnter(IShellItem* psiOver, IShellItemArray* psiaData, BOOL fOutsideSource, uint32 grfKeyState, uint32* pdwEffect) mut => VT.[Friend]OnDragEnter(&this, psiOver, psiaData, fOutsideSource, grfKeyState, pdwEffect);

	public HRESULT OnDragOver(IShellItem* psiOver, IShellItemArray* psiaData, uint32 grfKeyState, uint32* pdwEffect) mut => VT.[Friend]OnDragOver(&this, psiOver, psiaData, grfKeyState, pdwEffect);

	public HRESULT OnDragPosition(IShellItem* psiOver, IShellItemArray* psiaData, int32 iNewPosition, int32 iOldPosition) mut => VT.[Friend]OnDragPosition(&this, psiOver, psiaData, iNewPosition, iOldPosition);

	public HRESULT OnDrop(IShellItem* psiOver, IShellItemArray* psiaData, int32 iPosition, uint32 grfKeyState, uint32* pdwEffect) mut => VT.[Friend]OnDrop(&this, psiOver, psiaData, iPosition, grfKeyState, pdwEffect);

	public HRESULT OnDropPosition(IShellItem* psiOver, IShellItemArray* psiaData, int32 iNewPosition, int32 iOldPosition) mut => VT.[Friend]OnDropPosition(&this, psiOver, psiaData, iNewPosition, iOldPosition);

	public HRESULT OnDragLeave(IShellItem* psiOver) mut => VT.[Friend]OnDragLeave(&this, psiOver);
}

[CRepr]struct INameSpaceTreeAccessible : IUnknown
{
	public new const Guid IID = .(0x71f312de, 0x43ed, 0x4190, 0x84, 0x77, 0xe9, 0x53, 0x6b, 0x82, 0x35, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, BSTR* pbstrDefaultAction) OnGetDefaultAccessibilityAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi) OnDoDefaultAccessibilityAction;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, VARIANT* pvarRole) OnGetAccessibilityRole;
	}


	public HRESULT OnGetDefaultAccessibilityAction(IShellItem* psi, BSTR* pbstrDefaultAction) mut => VT.[Friend]OnGetDefaultAccessibilityAction(&this, psi, pbstrDefaultAction);

	public HRESULT OnDoDefaultAccessibilityAction(IShellItem* psi) mut => VT.[Friend]OnDoDefaultAccessibilityAction(&this, psi);

	public HRESULT OnGetAccessibilityRole(IShellItem* psi, VARIANT* pvarRole) mut => VT.[Friend]OnGetAccessibilityRole(&this, psi, pvarRole);
}

[CRepr]struct INameSpaceTreeControlCustomDraw : IUnknown
{
	public new const Guid IID = .(0x2d3ba758, 0x33ee, 0x42d5, 0xbb, 0x7b, 0x5f, 0x34, 0x31, 0xd8, 0x6c, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hdc, RECT* prc, LRESULT* plres) PrePaint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hdc, RECT* prc) PostPaint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hdc, RECT* prc, NSTCCUSTOMDRAW* pnstccdItem, COLORREF* pclrText, COLORREF* pclrTextBk, LRESULT* plres) ItemPrePaint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hdc, RECT* prc, NSTCCUSTOMDRAW* pnstccdItem) ItemPostPaint;
	}


	public HRESULT PrePaint(HDC hdc, RECT* prc, LRESULT* plres) mut => VT.[Friend]PrePaint(&this, hdc, prc, plres);

	public HRESULT PostPaint(HDC hdc, RECT* prc) mut => VT.[Friend]PostPaint(&this, hdc, prc);

	public HRESULT ItemPrePaint(HDC hdc, RECT* prc, NSTCCUSTOMDRAW* pnstccdItem, COLORREF* pclrText, COLORREF* pclrTextBk, LRESULT* plres) mut => VT.[Friend]ItemPrePaint(&this, hdc, prc, pnstccdItem, pclrText, pclrTextBk, plres);

	public HRESULT ItemPostPaint(HDC hdc, RECT* prc, NSTCCUSTOMDRAW* pnstccdItem) mut => VT.[Friend]ItemPostPaint(&this, hdc, prc, pnstccdItem);
}

[CRepr]struct ITrayDeskBand : IUnknown
{
	public new const Guid IID = .(0x6d67e846, 0x5b9c, 0x4db8, 0x9c, 0xbc, 0xdd, 0xe1, 0x2f, 0x42, 0x54, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) ShowDeskBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) HideDeskBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsid) IsDeskBandShown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeskBandRegistrationChanged;
	}


	public HRESULT ShowDeskBand(in Guid clsid) mut => VT.[Friend]ShowDeskBand(&this, clsid);

	public HRESULT HideDeskBand(in Guid clsid) mut => VT.[Friend]HideDeskBand(&this, clsid);

	public HRESULT IsDeskBandShown(in Guid clsid) mut => VT.[Friend]IsDeskBandShown(&this, clsid);

	public HRESULT DeskBandRegistrationChanged() mut => VT.[Friend]DeskBandRegistrationChanged(&this);
}

[CRepr]struct IBandHost : IUnknown
{
	public new const Guid IID = .(0xb9075c7c, 0xd48e, 0x403f, 0xab, 0x99, 0xd6, 0xc7, 0x7a, 0x10, 0x84, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsidBand, BOOL fAvailable, BOOL fVisible, in Guid riid, void** ppv) CreateBand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsidBand, BOOL fAvailable) SetBandAvailability;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsidBand) DestroyBand;
	}


	public HRESULT CreateBand(in Guid rclsidBand, BOOL fAvailable, BOOL fVisible, in Guid riid, void** ppv) mut => VT.[Friend]CreateBand(&this, rclsidBand, fAvailable, fVisible, riid, ppv);

	public HRESULT SetBandAvailability(in Guid rclsidBand, BOOL fAvailable) mut => VT.[Friend]SetBandAvailability(&this, rclsidBand, fAvailable);

	public HRESULT DestroyBand(in Guid rclsidBand) mut => VT.[Friend]DestroyBand(&this, rclsidBand);
}

[CRepr]struct IComputerInfoChangeNotify : IUnknown
{
	public new const Guid IID = .(0x0df60d92, 0x6818, 0x46d6, 0xb3, 0x58, 0xd6, 0x61, 0x70, 0xdd, 0xe4, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ComputerInfoChanged;
	}


	public HRESULT ComputerInfoChanged() mut => VT.[Friend]ComputerInfoChanged(&this);
}

[CRepr]struct IDesktopGadget : IUnknown
{
	public new const Guid IID = .(0xc1646bc4, 0xf298, 0x4f91, 0xa2, 0x04, 0xeb, 0x2d, 0xd1, 0x70, 0x9d, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR gadgetPath) RunGadget;
	}


	public HRESULT RunGadget(PWSTR gadgetPath) mut => VT.[Friend]RunGadget(&this, gadgetPath);
}

[CRepr]struct IAccessibilityDockingServiceCallback : IUnknown
{
	public new const Guid IID = .(0x157733fd, 0xa592, 0x42e5, 0xb5, 0x94, 0x24, 0x84, 0x68, 0xc5, 0xa8, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UNDOCK_REASON undockReason) Undocked;
	}


	public HRESULT Undocked(UNDOCK_REASON undockReason) mut => VT.[Friend]Undocked(&this, undockReason);
}

[CRepr]struct IAccessibilityDockingService : IUnknown
{
	public new const Guid IID = .(0x8849dc22, 0xcedf, 0x4c95, 0x99, 0x8d, 0x05, 0x14, 0x19, 0xdd, 0x3f, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HMONITOR hMonitor, uint32* pcxFixed, uint32* pcyMax) GetAvailableSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, HMONITOR hMonitor, uint32 cyRequested, IAccessibilityDockingServiceCallback* pCallback) DockWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd) UndockWindow;
	}


	public HRESULT GetAvailableSize(HMONITOR hMonitor, uint32* pcxFixed, uint32* pcyMax) mut => VT.[Friend]GetAvailableSize(&this, hMonitor, pcxFixed, pcyMax);

	public HRESULT DockWindow(HWND hwnd, HMONITOR hMonitor, uint32 cyRequested, IAccessibilityDockingServiceCallback* pCallback) mut => VT.[Friend]DockWindow(&this, hwnd, hMonitor, cyRequested, pCallback);

	public HRESULT UndockWindow(HWND hwnd) mut => VT.[Friend]UndockWindow(&this, hwnd);
}

[CRepr]struct IStorageProviderBanners : IUnknown
{
	public new const Guid IID = .(0x5efb46d7, 0x47c0, 0x4b68, 0xac, 0xda, 0xde, 0xd4, 0x7c, 0x90, 0xec, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR providerIdentity, PWSTR subscriptionId, PWSTR contentId) SetBanner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR providerIdentity, PWSTR subscriptionId) ClearBanner;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR providerIdentity) ClearAllBanners;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR providerIdentity, PWSTR subscriptionId, PWSTR* contentId) GetBanner;
	}


	public HRESULT SetBanner(PWSTR providerIdentity, PWSTR subscriptionId, PWSTR contentId) mut => VT.[Friend]SetBanner(&this, providerIdentity, subscriptionId, contentId);

	public HRESULT ClearBanner(PWSTR providerIdentity, PWSTR subscriptionId) mut => VT.[Friend]ClearBanner(&this, providerIdentity, subscriptionId);

	public HRESULT ClearAllBanners(PWSTR providerIdentity) mut => VT.[Friend]ClearAllBanners(&this, providerIdentity);

	public HRESULT GetBanner(PWSTR providerIdentity, PWSTR subscriptionId, PWSTR* contentId) mut => VT.[Friend]GetBanner(&this, providerIdentity, subscriptionId, contentId);
}

[CRepr]struct IStorageProviderCopyHook : IUnknown
{
	public new const Guid IID = .(0x7bf992a9, 0xaf7a, 0x4dba, 0xb2, 0xe5, 0x4d, 0x08, 0x0b, 0x1e, 0xcb, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, uint32 operation, uint32 flags, PWSTR srcFile, uint32 srcAttribs, PWSTR destFile, uint32 destAttribs, uint32* result) CopyCallback;
	}


	public HRESULT CopyCallback(HWND hwnd, uint32 operation, uint32 flags, PWSTR srcFile, uint32 srcAttribs, PWSTR destFile, uint32 destAttribs, uint32* result) mut => VT.[Friend]CopyCallback(&this, hwnd, operation, flags, srcFile, srcAttribs, destFile, destAttribs, result);
}

[CRepr]struct IWebBrowser : IDispatch
{
	public new const Guid IID = .(0xeab22ac1, 0x30c1, 0x11cf, 0xa7, 0xeb, 0x00, 0x00, 0xc0, 0x5b, 0xae, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GoBack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GoForward;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GoHome;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GoSearch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, VARIANT* Flags, VARIANT* TargetFrameName, VARIANT* PostData, VARIANT* Headers) Navigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Refresh;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Level) Refresh2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Stop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) get_Container;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) get_Document;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) get_TopLevelContainer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Type) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pl) get_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Left) put_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pl) get_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Top) put_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pl) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Width) put_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pl) get_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Height) put_Height;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* LocationName) get_LocationName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* LocationURL) get_LocationURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) get_Busy;
	}


	public HRESULT GoBack() mut => VT.[Friend]GoBack(&this);

	public HRESULT GoForward() mut => VT.[Friend]GoForward(&this);

	public HRESULT GoHome() mut => VT.[Friend]GoHome(&this);

	public HRESULT GoSearch() mut => VT.[Friend]GoSearch(&this);

	public HRESULT Navigate(BSTR URL, VARIANT* Flags, VARIANT* TargetFrameName, VARIANT* PostData, VARIANT* Headers) mut => VT.[Friend]Navigate(&this, URL, Flags, TargetFrameName, PostData, Headers);

	public HRESULT Refresh() mut => VT.[Friend]Refresh(&this);

	public HRESULT Refresh2(VARIANT* Level) mut => VT.[Friend]Refresh2(&this, Level);

	public HRESULT Stop() mut => VT.[Friend]Stop(&this);

	public HRESULT get_Application(IDispatch** ppDisp) mut => VT.[Friend]get_Application(&this, ppDisp);

	public HRESULT get_Parent(IDispatch** ppDisp) mut => VT.[Friend]get_Parent(&this, ppDisp);

	public HRESULT get_Container(IDispatch** ppDisp) mut => VT.[Friend]get_Container(&this, ppDisp);

	public HRESULT get_Document(IDispatch** ppDisp) mut => VT.[Friend]get_Document(&this, ppDisp);

	public HRESULT get_TopLevelContainer(int16* pBool) mut => VT.[Friend]get_TopLevelContainer(&this, pBool);

	public HRESULT get_Type(BSTR* Type) mut => VT.[Friend]get_Type(&this, Type);

	public HRESULT get_Left(int32* pl) mut => VT.[Friend]get_Left(&this, pl);

	public HRESULT put_Left(int32 Left) mut => VT.[Friend]put_Left(&this, Left);

	public HRESULT get_Top(int32* pl) mut => VT.[Friend]get_Top(&this, pl);

	public HRESULT put_Top(int32 Top) mut => VT.[Friend]put_Top(&this, Top);

	public HRESULT get_Width(int32* pl) mut => VT.[Friend]get_Width(&this, pl);

	public HRESULT put_Width(int32 Width) mut => VT.[Friend]put_Width(&this, Width);

	public HRESULT get_Height(int32* pl) mut => VT.[Friend]get_Height(&this, pl);

	public HRESULT put_Height(int32 Height) mut => VT.[Friend]put_Height(&this, Height);

	public HRESULT get_LocationName(BSTR* LocationName) mut => VT.[Friend]get_LocationName(&this, LocationName);

	public HRESULT get_LocationURL(BSTR* LocationURL) mut => VT.[Friend]get_LocationURL(&this, LocationURL);

	public HRESULT get_Busy(int16* pBool) mut => VT.[Friend]get_Busy(&this, pBool);
}

[CRepr]struct DWebBrowserEvents : IDispatch
{
	public new const Guid IID = .(0xeab22ac2, 0x30c1, 0x11cf, 0xa7, 0xeb, 0x00, 0x00, 0xc0, 0x5b, 0xae, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IWebBrowserApp : IWebBrowser
{
	public new const Guid IID = .(0x0002df05, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWebBrowser.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Quit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pcx, int32* pcy) ClientToWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Property, VARIANT vtValue) PutProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Property, VARIANT* pvtValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHANDLE_PTR* pHWND) get_HWND;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* FullName) get_FullName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) get_Visible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Visible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) get_StatusBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_StatusBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* StatusText) get_StatusText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR StatusText) put_StatusText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Value) get_ToolBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Value) put_ToolBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Value) get_MenuBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_MenuBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbFullScreen) get_FullScreen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bFullScreen) put_FullScreen;
	}


	public HRESULT Quit() mut => VT.[Friend]Quit(&this);

	public HRESULT ClientToWindow(int32* pcx, int32* pcy) mut => VT.[Friend]ClientToWindow(&this, pcx, pcy);

	public HRESULT PutProperty(BSTR Property, VARIANT vtValue) mut => VT.[Friend]PutProperty(&this, Property, vtValue);

	public HRESULT GetProperty(BSTR Property, VARIANT* pvtValue) mut => VT.[Friend]GetProperty(&this, Property, pvtValue);

	public HRESULT get_Name(BSTR* Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_HWND(SHANDLE_PTR* pHWND) mut => VT.[Friend]get_HWND(&this, pHWND);

	public HRESULT get_FullName(BSTR* FullName) mut => VT.[Friend]get_FullName(&this, FullName);

	public HRESULT get_Path(BSTR* Path) mut => VT.[Friend]get_Path(&this, Path);

	public HRESULT get_Visible(int16* pBool) mut => VT.[Friend]get_Visible(&this, pBool);

	public HRESULT put_Visible(int16 Value) mut => VT.[Friend]put_Visible(&this, Value);

	public HRESULT get_StatusBar(int16* pBool) mut => VT.[Friend]get_StatusBar(&this, pBool);

	public HRESULT put_StatusBar(int16 Value) mut => VT.[Friend]put_StatusBar(&this, Value);

	public HRESULT get_StatusText(BSTR* StatusText) mut => VT.[Friend]get_StatusText(&this, StatusText);

	public HRESULT put_StatusText(BSTR StatusText) mut => VT.[Friend]put_StatusText(&this, StatusText);

	public HRESULT get_ToolBar(int32* Value) mut => VT.[Friend]get_ToolBar(&this, Value);

	public HRESULT put_ToolBar(int32 Value) mut => VT.[Friend]put_ToolBar(&this, Value);

	public HRESULT get_MenuBar(int16* Value) mut => VT.[Friend]get_MenuBar(&this, Value);

	public HRESULT put_MenuBar(int16 Value) mut => VT.[Friend]put_MenuBar(&this, Value);

	public HRESULT get_FullScreen(int16* pbFullScreen) mut => VT.[Friend]get_FullScreen(&this, pbFullScreen);

	public HRESULT put_FullScreen(int16 bFullScreen) mut => VT.[Friend]put_FullScreen(&this, bFullScreen);
}

[CRepr]struct IWebBrowser2 : IWebBrowserApp
{
	public new const Guid IID = .(0xd30c1661, 0xcdaf, 0x11d0, 0x8a, 0x3e, 0x00, 0xc0, 0x4f, 0xc9, 0xe2, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWebBrowserApp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* URL, VARIANT* Flags, VARIANT* TargetFrameName, VARIANT* PostData, VARIANT* Headers) Navigate2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLECMDID cmdID, OLECMDF* pcmdf) QueryStatusWB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, OLECMDID cmdID, OLECMDEXECOPT cmdexecopt, VARIANT* pvaIn, VARIANT* pvaOut) ExecWB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvaClsid, VARIANT* pvarShow, VARIANT* pvarSize) ShowBrowserBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, READYSTATE* plReadyState) get_ReadyState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbOffline) get_Offline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bOffline) put_Offline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbSilent) get_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bSilent) put_Silent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRegister) get_RegisterAsBrowser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRegister) put_RegisterAsBrowser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRegister) get_RegisterAsDropTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRegister) put_RegisterAsDropTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbRegister) get_TheaterMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bRegister) put_TheaterMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Value) get_AddressBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_AddressBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* Value) get_Resizable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 Value) put_Resizable;
	}


	public HRESULT Navigate2(VARIANT* URL, VARIANT* Flags, VARIANT* TargetFrameName, VARIANT* PostData, VARIANT* Headers) mut => VT.[Friend]Navigate2(&this, URL, Flags, TargetFrameName, PostData, Headers);

	public HRESULT QueryStatusWB(OLECMDID cmdID, OLECMDF* pcmdf) mut => VT.[Friend]QueryStatusWB(&this, cmdID, pcmdf);

	public HRESULT ExecWB(OLECMDID cmdID, OLECMDEXECOPT cmdexecopt, VARIANT* pvaIn, VARIANT* pvaOut) mut => VT.[Friend]ExecWB(&this, cmdID, cmdexecopt, pvaIn, pvaOut);

	public HRESULT ShowBrowserBar(VARIANT* pvaClsid, VARIANT* pvarShow, VARIANT* pvarSize) mut => VT.[Friend]ShowBrowserBar(&this, pvaClsid, pvarShow, pvarSize);

	public HRESULT get_ReadyState(READYSTATE* plReadyState) mut => VT.[Friend]get_ReadyState(&this, plReadyState);

	public HRESULT get_Offline(int16* pbOffline) mut => VT.[Friend]get_Offline(&this, pbOffline);

	public HRESULT put_Offline(int16 bOffline) mut => VT.[Friend]put_Offline(&this, bOffline);

	public HRESULT get_Silent(int16* pbSilent) mut => VT.[Friend]get_Silent(&this, pbSilent);

	public HRESULT put_Silent(int16 bSilent) mut => VT.[Friend]put_Silent(&this, bSilent);

	public HRESULT get_RegisterAsBrowser(int16* pbRegister) mut => VT.[Friend]get_RegisterAsBrowser(&this, pbRegister);

	public HRESULT put_RegisterAsBrowser(int16 bRegister) mut => VT.[Friend]put_RegisterAsBrowser(&this, bRegister);

	public HRESULT get_RegisterAsDropTarget(int16* pbRegister) mut => VT.[Friend]get_RegisterAsDropTarget(&this, pbRegister);

	public HRESULT put_RegisterAsDropTarget(int16 bRegister) mut => VT.[Friend]put_RegisterAsDropTarget(&this, bRegister);

	public HRESULT get_TheaterMode(int16* pbRegister) mut => VT.[Friend]get_TheaterMode(&this, pbRegister);

	public HRESULT put_TheaterMode(int16 bRegister) mut => VT.[Friend]put_TheaterMode(&this, bRegister);

	public HRESULT get_AddressBar(int16* Value) mut => VT.[Friend]get_AddressBar(&this, Value);

	public HRESULT put_AddressBar(int16 Value) mut => VT.[Friend]put_AddressBar(&this, Value);

	public HRESULT get_Resizable(int16* Value) mut => VT.[Friend]get_Resizable(&this, Value);

	public HRESULT put_Resizable(int16 Value) mut => VT.[Friend]put_Resizable(&this, Value);
}

[CRepr]struct DWebBrowserEvents2 : IDispatch
{
	public new const Guid IID = .(0x34a715a0, 0x6587, 0x11d0, 0x92, 0x4a, 0x00, 0x20, 0xaf, 0xc7, 0xac, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct DShellWindowsEvents : IDispatch
{
	public new const Guid IID = .(0xfe4106e0, 0x399a, 0x11d0, 0xa4, 0x8c, 0x00, 0xa0, 0xc9, 0x0a, 0x8f, 0x39);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IShellWindows : IDispatch
{
	public new const Guid IID = .(0x85cb6900, 0x4d95, 0x11cf, 0x96, 0x0c, 0x00, 0x80, 0xc7, 0xf4, 0xee, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, IDispatch** Folder) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) _NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pid, int32 hwnd, int32 swClass, int32* plCookie) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lThreadId, VARIANT* pvarloc, VARIANT* pvarlocRoot, int32 swClass, int32* plCookie) RegisterPending;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCookie) Revoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCookie, VARIANT* pvarLoc) OnNavigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCookie, int16 fActive) OnActivated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarLoc, VARIANT* pvarLocRoot, int32 swClass, int32* phwnd, int32 swfwOptions, IDispatch** ppdispOut) FindWindowSW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCookie, IUnknown* punk) OnCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fAttach) ProcessAttachDetach;
	}


	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Item(VARIANT index, IDispatch** Folder) mut => VT.[Friend]Item(&this, index, Folder);

	public HRESULT _NewEnum(IUnknown** ppunk) mut => VT.[Friend]_NewEnum(&this, ppunk);

	public HRESULT Register(IDispatch* pid, int32 hwnd, int32 swClass, int32* plCookie) mut => VT.[Friend]Register(&this, pid, hwnd, swClass, plCookie);

	public HRESULT RegisterPending(int32 lThreadId, VARIANT* pvarloc, VARIANT* pvarlocRoot, int32 swClass, int32* plCookie) mut => VT.[Friend]RegisterPending(&this, lThreadId, pvarloc, pvarlocRoot, swClass, plCookie);

	public HRESULT Revoke(int32 lCookie) mut => VT.[Friend]Revoke(&this, lCookie);

	public HRESULT OnNavigate(int32 lCookie, VARIANT* pvarLoc) mut => VT.[Friend]OnNavigate(&this, lCookie, pvarLoc);

	public HRESULT OnActivated(int32 lCookie, int16 fActive) mut => VT.[Friend]OnActivated(&this, lCookie, fActive);

	public HRESULT FindWindowSW(VARIANT* pvarLoc, VARIANT* pvarLocRoot, int32 swClass, int32* phwnd, int32 swfwOptions, IDispatch** ppdispOut) mut => VT.[Friend]FindWindowSW(&this, pvarLoc, pvarLocRoot, swClass, phwnd, swfwOptions, ppdispOut);

	public HRESULT OnCreated(int32 lCookie, IUnknown* punk) mut => VT.[Friend]OnCreated(&this, lCookie, punk);

	public HRESULT ProcessAttachDetach(int16 fAttach) mut => VT.[Friend]ProcessAttachDetach(&this, fAttach);
}

[CRepr]struct IShellUIHelper : IDispatch
{
	public new const Guid IID = .(0x729fe2f8, 0x1ea8, 0x11d1, 0x8f, 0x85, 0x00, 0xc0, 0x4f, 0xc2, 0xfb, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetFirstBootMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetSafeMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshOfflineDesktop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, VARIANT* Title) AddFavorite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL) AddChannel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, BSTR Type, VARIANT* Left, VARIANT* Top, VARIANT* Width, VARIANT* Height) AddDesktopComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, int16* pBool) IsSubscribed;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, BSTR strQuery, VARIANT* varTargetFrame) NavigateAndFind;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fImport, BSTR strImpExpPath) ImportExportFavorites;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Form) AutoCompleteSaveForm;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strSearch, BSTR strFailureUrl, VARIANT* pvarTargetFrame) AutoScan;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Reserved) AutoCompleteAttach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, VARIANT* pvarIn, VARIANT* pvarOut) ShowBrowserUI;
	}


	public HRESULT ResetFirstBootMode() mut => VT.[Friend]ResetFirstBootMode(&this);

	public HRESULT ResetSafeMode() mut => VT.[Friend]ResetSafeMode(&this);

	public HRESULT RefreshOfflineDesktop() mut => VT.[Friend]RefreshOfflineDesktop(&this);

	public HRESULT AddFavorite(BSTR URL, VARIANT* Title) mut => VT.[Friend]AddFavorite(&this, URL, Title);

	public HRESULT AddChannel(BSTR URL) mut => VT.[Friend]AddChannel(&this, URL);

	public HRESULT AddDesktopComponent(BSTR URL, BSTR Type, VARIANT* Left, VARIANT* Top, VARIANT* Width, VARIANT* Height) mut => VT.[Friend]AddDesktopComponent(&this, URL, Type, Left, Top, Width, Height);

	public HRESULT IsSubscribed(BSTR URL, int16* pBool) mut => VT.[Friend]IsSubscribed(&this, URL, pBool);

	public HRESULT NavigateAndFind(BSTR URL, BSTR strQuery, VARIANT* varTargetFrame) mut => VT.[Friend]NavigateAndFind(&this, URL, strQuery, varTargetFrame);

	public HRESULT ImportExportFavorites(int16 fImport, BSTR strImpExpPath) mut => VT.[Friend]ImportExportFavorites(&this, fImport, strImpExpPath);

	public HRESULT AutoCompleteSaveForm(VARIANT* Form) mut => VT.[Friend]AutoCompleteSaveForm(&this, Form);

	public HRESULT AutoScan(BSTR strSearch, BSTR strFailureUrl, VARIANT* pvarTargetFrame) mut => VT.[Friend]AutoScan(&this, strSearch, strFailureUrl, pvarTargetFrame);

	public HRESULT AutoCompleteAttach(VARIANT* Reserved) mut => VT.[Friend]AutoCompleteAttach(&this, Reserved);

	public HRESULT ShowBrowserUI(BSTR bstrName, VARIANT* pvarIn, VARIANT* pvarOut) mut => VT.[Friend]ShowBrowserUI(&this, bstrName, pvarIn, pvarOut);
}

[CRepr]struct IShellUIHelper2 : IShellUIHelper
{
	public new const Guid IID = .(0xa7fe6eda, 0x1932, 0x4281, 0xb8, 0x81, 0x87, 0xb3, 0x1b, 0x8b, 0xc5, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL) AddSearchProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RunOnceShown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SkipRunOnce;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fSQM, int16 fPhishing, BSTR bstrLocale) CustomizeSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) SqmEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) PhishingEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUri) BrandImageUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SkipTabsWelcome;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DiagnoseConnection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fSet) CustomizeClearType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, uint32* pdwResult) IsSearchProviderInstalled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfMigrated) IsSearchMigrated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrName) DefaultSearchProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fComplete) RunOnceRequiredSettingsComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfShown) RunOnceHasShown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrUrl) SearchGuideUrl;
	}


	public HRESULT AddSearchProvider(BSTR URL) mut => VT.[Friend]AddSearchProvider(&this, URL);

	public HRESULT RunOnceShown() mut => VT.[Friend]RunOnceShown(&this);

	public HRESULT SkipRunOnce() mut => VT.[Friend]SkipRunOnce(&this);

	public HRESULT CustomizeSettings(int16 fSQM, int16 fPhishing, BSTR bstrLocale) mut => VT.[Friend]CustomizeSettings(&this, fSQM, fPhishing, bstrLocale);

	public HRESULT SqmEnabled(int16* pfEnabled) mut => VT.[Friend]SqmEnabled(&this, pfEnabled);

	public HRESULT PhishingEnabled(int16* pfEnabled) mut => VT.[Friend]PhishingEnabled(&this, pfEnabled);

	public HRESULT BrandImageUri(BSTR* pbstrUri) mut => VT.[Friend]BrandImageUri(&this, pbstrUri);

	public HRESULT SkipTabsWelcome() mut => VT.[Friend]SkipTabsWelcome(&this);

	public HRESULT DiagnoseConnection() mut => VT.[Friend]DiagnoseConnection(&this);

	public HRESULT CustomizeClearType(int16 fSet) mut => VT.[Friend]CustomizeClearType(&this, fSet);

	public HRESULT IsSearchProviderInstalled(BSTR URL, uint32* pdwResult) mut => VT.[Friend]IsSearchProviderInstalled(&this, URL, pdwResult);

	public HRESULT IsSearchMigrated(int16* pfMigrated) mut => VT.[Friend]IsSearchMigrated(&this, pfMigrated);

	public HRESULT DefaultSearchProvider(BSTR* pbstrName) mut => VT.[Friend]DefaultSearchProvider(&this, pbstrName);

	public HRESULT RunOnceRequiredSettingsComplete(int16 fComplete) mut => VT.[Friend]RunOnceRequiredSettingsComplete(&this, fComplete);

	public HRESULT RunOnceHasShown(int16* pfShown) mut => VT.[Friend]RunOnceHasShown(&this, pfShown);

	public HRESULT SearchGuideUrl(BSTR* pbstrUrl) mut => VT.[Friend]SearchGuideUrl(&this, pbstrUrl);
}

[CRepr]struct IShellUIHelper3 : IShellUIHelper2
{
	public new const Guid IID = .(0x528df2ec, 0xd419, 0x40bc, 0x9b, 0x6d, 0xdc, 0xdb, 0xf9, 0xc1, 0xb2, 0x5d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL) AddService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, BSTR Verb, uint32* pdwResult) IsServiceInstalled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) InPrivateFilteringEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, BSTR Title, VARIANT* Type) AddToFavoritesBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BuildNewTabPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fVisible) SetRecentlyClosedVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fVisible) SetActivitiesVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ContentDiscoveryReset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) IsSuggestedSitesEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fEnable) EnableSuggestedSites;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrRelativeUrl) NavigateToSuggestedSites;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowTabsHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShowInPrivateHelp;
	}


	public HRESULT AddService(BSTR URL) mut => VT.[Friend]AddService(&this, URL);

	public HRESULT IsServiceInstalled(BSTR URL, BSTR Verb, uint32* pdwResult) mut => VT.[Friend]IsServiceInstalled(&this, URL, Verb, pdwResult);

	public HRESULT InPrivateFilteringEnabled(int16* pfEnabled) mut => VT.[Friend]InPrivateFilteringEnabled(&this, pfEnabled);

	public HRESULT AddToFavoritesBar(BSTR URL, BSTR Title, VARIANT* Type) mut => VT.[Friend]AddToFavoritesBar(&this, URL, Title, Type);

	public HRESULT BuildNewTabPage() mut => VT.[Friend]BuildNewTabPage(&this);

	public HRESULT SetRecentlyClosedVisible(int16 fVisible) mut => VT.[Friend]SetRecentlyClosedVisible(&this, fVisible);

	public HRESULT SetActivitiesVisible(int16 fVisible) mut => VT.[Friend]SetActivitiesVisible(&this, fVisible);

	public HRESULT ContentDiscoveryReset() mut => VT.[Friend]ContentDiscoveryReset(&this);

	public HRESULT IsSuggestedSitesEnabled(int16* pfEnabled) mut => VT.[Friend]IsSuggestedSitesEnabled(&this, pfEnabled);

	public HRESULT EnableSuggestedSites(int16 fEnable) mut => VT.[Friend]EnableSuggestedSites(&this, fEnable);

	public HRESULT NavigateToSuggestedSites(BSTR bstrRelativeUrl) mut => VT.[Friend]NavigateToSuggestedSites(&this, bstrRelativeUrl);

	public HRESULT ShowTabsHelp() mut => VT.[Friend]ShowTabsHelp(&this);

	public HRESULT ShowInPrivateHelp() mut => VT.[Friend]ShowInPrivateHelp(&this);
}

[CRepr]struct IShellUIHelper4 : IShellUIHelper3
{
	public new const Guid IID = .(0xb36e6a53, 0x8073, 0x499e, 0x82, 0x4c, 0xd7, 0x76, 0x33, 0x0a, 0x33, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfSiteMode) msIsSiteMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeShowThumbBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrIconURL, BSTR bstrTooltip, VARIANT* pvarButtonID) msSiteModeAddThumbBarButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ButtonID, int16 fEnabled, int16 fVisible) msSiteModeUpdateThumbBarButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR IconUrl, VARIANT* pvarDescription) msSiteModeSetIconOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeClearIconOverlay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msAddSiteMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHeader) msSiteModeCreateJumpList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrName, BSTR bstrActionUri, BSTR bstrIconUri, VARIANT* pvarWindowType) msSiteModeAddJumpListItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeClearJumpList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeShowJumpList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT uiButtonID, BSTR bstrIconUrl, BSTR bstrTooltip, VARIANT* pvarStyleID) msSiteModeAddButtonStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT uiButtonID, VARIANT uiStyleID) msSiteModeShowButtonStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeActivate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fPreserveState, VARIANT* puiFirstRun) msIsSiteModeFirstRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR URL, BSTR bstrFilterName) msAddTrackingProtectionList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) msTrackingProtectionEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pfEnabled) msActiveXFilteringEnabled;
	}


	public HRESULT msIsSiteMode(int16* pfSiteMode) mut => VT.[Friend]msIsSiteMode(&this, pfSiteMode);

	public HRESULT msSiteModeShowThumbBar() mut => VT.[Friend]msSiteModeShowThumbBar(&this);

	public HRESULT msSiteModeAddThumbBarButton(BSTR bstrIconURL, BSTR bstrTooltip, VARIANT* pvarButtonID) mut => VT.[Friend]msSiteModeAddThumbBarButton(&this, bstrIconURL, bstrTooltip, pvarButtonID);

	public HRESULT msSiteModeUpdateThumbBarButton(VARIANT ButtonID, int16 fEnabled, int16 fVisible) mut => VT.[Friend]msSiteModeUpdateThumbBarButton(&this, ButtonID, fEnabled, fVisible);

	public HRESULT msSiteModeSetIconOverlay(BSTR IconUrl, VARIANT* pvarDescription) mut => VT.[Friend]msSiteModeSetIconOverlay(&this, IconUrl, pvarDescription);

	public HRESULT msSiteModeClearIconOverlay() mut => VT.[Friend]msSiteModeClearIconOverlay(&this);

	public HRESULT msAddSiteMode() mut => VT.[Friend]msAddSiteMode(&this);

	public HRESULT msSiteModeCreateJumpList(BSTR bstrHeader) mut => VT.[Friend]msSiteModeCreateJumpList(&this, bstrHeader);

	public HRESULT msSiteModeAddJumpListItem(BSTR bstrName, BSTR bstrActionUri, BSTR bstrIconUri, VARIANT* pvarWindowType) mut => VT.[Friend]msSiteModeAddJumpListItem(&this, bstrName, bstrActionUri, bstrIconUri, pvarWindowType);

	public HRESULT msSiteModeClearJumpList() mut => VT.[Friend]msSiteModeClearJumpList(&this);

	public HRESULT msSiteModeShowJumpList() mut => VT.[Friend]msSiteModeShowJumpList(&this);

	public HRESULT msSiteModeAddButtonStyle(VARIANT uiButtonID, BSTR bstrIconUrl, BSTR bstrTooltip, VARIANT* pvarStyleID) mut => VT.[Friend]msSiteModeAddButtonStyle(&this, uiButtonID, bstrIconUrl, bstrTooltip, pvarStyleID);

	public HRESULT msSiteModeShowButtonStyle(VARIANT uiButtonID, VARIANT uiStyleID) mut => VT.[Friend]msSiteModeShowButtonStyle(&this, uiButtonID, uiStyleID);

	public HRESULT msSiteModeActivate() mut => VT.[Friend]msSiteModeActivate(&this);

	public HRESULT msIsSiteModeFirstRun(int16 fPreserveState, VARIANT* puiFirstRun) mut => VT.[Friend]msIsSiteModeFirstRun(&this, fPreserveState, puiFirstRun);

	public HRESULT msAddTrackingProtectionList(BSTR URL, BSTR bstrFilterName) mut => VT.[Friend]msAddTrackingProtectionList(&this, URL, bstrFilterName);

	public HRESULT msTrackingProtectionEnabled(int16* pfEnabled) mut => VT.[Friend]msTrackingProtectionEnabled(&this, pfEnabled);

	public HRESULT msActiveXFilteringEnabled(int16* pfEnabled) mut => VT.[Friend]msActiveXFilteringEnabled(&this, pfEnabled);
}

[CRepr]struct IShellUIHelper5 : IShellUIHelper4
{
	public new const Guid IID = .(0xa2a08b09, 0x103d, 0x4d3f, 0xb9, 0x1c, 0xea, 0x45, 0x5c, 0xa8, 0x2e, 0xfa);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrProvisioningXml, VARIANT* puiResult) msProvisionNetworks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msReportSafeUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeRefreshBadge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msSiteModeClearBadge;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msDiagnoseConnectionUILess;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msLaunchNetworkClientHelp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fChange) msChangeDefaultBrowser;
	}


	public HRESULT msProvisionNetworks(BSTR bstrProvisioningXml, VARIANT* puiResult) mut => VT.[Friend]msProvisionNetworks(&this, bstrProvisioningXml, puiResult);

	public HRESULT msReportSafeUrl() mut => VT.[Friend]msReportSafeUrl(&this);

	public HRESULT msSiteModeRefreshBadge() mut => VT.[Friend]msSiteModeRefreshBadge(&this);

	public HRESULT msSiteModeClearBadge() mut => VT.[Friend]msSiteModeClearBadge(&this);

	public HRESULT msDiagnoseConnectionUILess() mut => VT.[Friend]msDiagnoseConnectionUILess(&this);

	public HRESULT msLaunchNetworkClientHelp() mut => VT.[Friend]msLaunchNetworkClientHelp(&this);

	public HRESULT msChangeDefaultBrowser(int16 fChange) mut => VT.[Friend]msChangeDefaultBrowser(&this, fChange);
}

[CRepr]struct IShellUIHelper6 : IShellUIHelper5
{
	public new const Guid IID = .(0x987a573e, 0x46ee, 0x4e89, 0x96, 0xab, 0xdd, 0xf7, 0xf8, 0xfd, 0xc9, 0x8c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msStopPeriodicTileUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pollingUris, VARIANT startTime, VARIANT uiUpdateRecurrence) msStartPeriodicTileUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT pollingUris, VARIANT startTime, VARIANT uiUpdateRecurrence) msStartPeriodicTileUpdateBatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msClearTile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fChange) msEnableTileNotificationQueue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarSiteState) msPinnedSiteState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fChange) msEnableTileNotificationQueueForSquare150x150;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fChange) msEnableTileNotificationQueueForWide310x150;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 fChange) msEnableTileNotificationQueueForSquare310x310;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNotificationXml, BSTR bstrNotificationId, BSTR bstrNotificationTag, VARIANT startTime, VARIANT expirationTime) msScheduledTileNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrNotificationId) msRemoveScheduledTileNotification;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR pollingUri, VARIANT startTime, VARIANT uiUpdateRecurrence) msStartPeriodicBadgeUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msStopPeriodicBadgeUpdate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) msLaunchInternetOptions;
	}


	public HRESULT msStopPeriodicTileUpdate() mut => VT.[Friend]msStopPeriodicTileUpdate(&this);

	public HRESULT msStartPeriodicTileUpdate(VARIANT pollingUris, VARIANT startTime, VARIANT uiUpdateRecurrence) mut => VT.[Friend]msStartPeriodicTileUpdate(&this, pollingUris, startTime, uiUpdateRecurrence);

	public HRESULT msStartPeriodicTileUpdateBatch(VARIANT pollingUris, VARIANT startTime, VARIANT uiUpdateRecurrence) mut => VT.[Friend]msStartPeriodicTileUpdateBatch(&this, pollingUris, startTime, uiUpdateRecurrence);

	public HRESULT msClearTile() mut => VT.[Friend]msClearTile(&this);

	public HRESULT msEnableTileNotificationQueue(int16 fChange) mut => VT.[Friend]msEnableTileNotificationQueue(&this, fChange);

	public HRESULT msPinnedSiteState(VARIANT* pvarSiteState) mut => VT.[Friend]msPinnedSiteState(&this, pvarSiteState);

	public HRESULT msEnableTileNotificationQueueForSquare150x150(int16 fChange) mut => VT.[Friend]msEnableTileNotificationQueueForSquare150x150(&this, fChange);

	public HRESULT msEnableTileNotificationQueueForWide310x150(int16 fChange) mut => VT.[Friend]msEnableTileNotificationQueueForWide310x150(&this, fChange);

	public HRESULT msEnableTileNotificationQueueForSquare310x310(int16 fChange) mut => VT.[Friend]msEnableTileNotificationQueueForSquare310x310(&this, fChange);

	public HRESULT msScheduledTileNotification(BSTR bstrNotificationXml, BSTR bstrNotificationId, BSTR bstrNotificationTag, VARIANT startTime, VARIANT expirationTime) mut => VT.[Friend]msScheduledTileNotification(&this, bstrNotificationXml, bstrNotificationId, bstrNotificationTag, startTime, expirationTime);

	public HRESULT msRemoveScheduledTileNotification(BSTR bstrNotificationId) mut => VT.[Friend]msRemoveScheduledTileNotification(&this, bstrNotificationId);

	public HRESULT msStartPeriodicBadgeUpdate(BSTR pollingUri, VARIANT startTime, VARIANT uiUpdateRecurrence) mut => VT.[Friend]msStartPeriodicBadgeUpdate(&this, pollingUri, startTime, uiUpdateRecurrence);

	public HRESULT msStopPeriodicBadgeUpdate() mut => VT.[Friend]msStopPeriodicBadgeUpdate(&this);

	public HRESULT msLaunchInternetOptions() mut => VT.[Friend]msLaunchInternetOptions(&this);
}

[CRepr]struct IShellUIHelper7 : IShellUIHelper6
{
	public new const Guid IID = .(0x60e567c8, 0x9573, 0x4ab2, 0xa2, 0x64, 0x63, 0x7c, 0x6c, 0x16, 0x1c, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper6.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFlagString, int16 vfFlag) SetExperimentalFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFlagString, int16* vfFlag) GetExperimentalFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrValueString, uint32 dwValue) SetExperimentalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrValueString, uint32* pdwValue) GetExperimentalValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetAllExperimentalFlagsAndValues;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl, int16* flag) GetNeedIEAutoLaunchFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl, int16 flag) SetNeedIEAutoLaunchFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl, int16* exists) HasNeedIEAutoLaunchFlag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl, int16 automated) LaunchIE;
	}


	public HRESULT SetExperimentalFlag(BSTR bstrFlagString, int16 vfFlag) mut => VT.[Friend]SetExperimentalFlag(&this, bstrFlagString, vfFlag);

	public HRESULT GetExperimentalFlag(BSTR bstrFlagString, int16* vfFlag) mut => VT.[Friend]GetExperimentalFlag(&this, bstrFlagString, vfFlag);

	public HRESULT SetExperimentalValue(BSTR bstrValueString, uint32 dwValue) mut => VT.[Friend]SetExperimentalValue(&this, bstrValueString, dwValue);

	public HRESULT GetExperimentalValue(BSTR bstrValueString, uint32* pdwValue) mut => VT.[Friend]GetExperimentalValue(&this, bstrValueString, pdwValue);

	public HRESULT ResetAllExperimentalFlagsAndValues() mut => VT.[Friend]ResetAllExperimentalFlagsAndValues(&this);

	public HRESULT GetNeedIEAutoLaunchFlag(BSTR bstrUrl, int16* flag) mut => VT.[Friend]GetNeedIEAutoLaunchFlag(&this, bstrUrl, flag);

	public HRESULT SetNeedIEAutoLaunchFlag(BSTR bstrUrl, int16 flag) mut => VT.[Friend]SetNeedIEAutoLaunchFlag(&this, bstrUrl, flag);

	public HRESULT HasNeedIEAutoLaunchFlag(BSTR bstrUrl, int16* exists) mut => VT.[Friend]HasNeedIEAutoLaunchFlag(&this, bstrUrl, exists);

	public HRESULT LaunchIE(BSTR bstrUrl, int16 automated) mut => VT.[Friend]LaunchIE(&this, bstrUrl, automated);
}

[CRepr]struct IShellUIHelper8 : IShellUIHelper7
{
	public new const Guid IID = .(0x66debcf2, 0x05b0, 0x4f07, 0xb4, 0x9b, 0xb9, 0x62, 0x41, 0xa6, 0x5d, 0xb2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper7.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrResult) GetCVListData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrResult) GetCVListLocalData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrResult) GetEMIEListData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrResult) GetEMIEListLocalData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OpenFavoritesPane;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OpenFavoritesSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrUrl) LaunchInHVSI;
	}


	public HRESULT GetCVListData(BSTR* pbstrResult) mut => VT.[Friend]GetCVListData(&this, pbstrResult);

	public HRESULT GetCVListLocalData(BSTR* pbstrResult) mut => VT.[Friend]GetCVListLocalData(&this, pbstrResult);

	public HRESULT GetEMIEListData(BSTR* pbstrResult) mut => VT.[Friend]GetEMIEListData(&this, pbstrResult);

	public HRESULT GetEMIEListLocalData(BSTR* pbstrResult) mut => VT.[Friend]GetEMIEListLocalData(&this, pbstrResult);

	public HRESULT OpenFavoritesPane() mut => VT.[Friend]OpenFavoritesPane(&this);

	public HRESULT OpenFavoritesSettings() mut => VT.[Friend]OpenFavoritesSettings(&this);

	public HRESULT LaunchInHVSI(BSTR bstrUrl) mut => VT.[Friend]LaunchInHVSI(&this, bstrUrl);
}

[CRepr]struct IShellUIHelper9 : IShellUIHelper8
{
	public new const Guid IID = .(0x6cdf73b0, 0x7f2f, 0x451f, 0xbc, 0x0f, 0x63, 0xe0, 0xf3, 0x28, 0x4e, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellUIHelper8.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwResult) GetOSSku;
	}


	public HRESULT GetOSSku(uint32* pdwResult) mut => VT.[Friend]GetOSSku(&this, pdwResult);
}

[CRepr]struct DShellNameSpaceEvents : IDispatch
{
	public new const Guid IID = .(0x55136806, 0xb2de, 0x11d1, 0xb9, 0xf2, 0x00, 0xa0, 0xc9, 0x8b, 0xc5, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct IShellFavoritesNameSpace : IDispatch
{
	public new const Guid IID = .(0x55136804, 0xb2de, 0x11d1, 0xb9, 0xf2, 0x00, 0xa0, 0xc9, 0x8b, 0xc5, 0x47);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveSelectionUp;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveSelectionDown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ResetSort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NewFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Synchronize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Import;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Export;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR strCommand) InvokeContextMenuCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MoveSelectionTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) get_SubscriptionsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) CreateSubscriptionForSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pBool) DeleteSubscriptionForSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFullPath) SetRoot;
	}


	public HRESULT MoveSelectionUp() mut => VT.[Friend]MoveSelectionUp(&this);

	public HRESULT MoveSelectionDown() mut => VT.[Friend]MoveSelectionDown(&this);

	public HRESULT ResetSort() mut => VT.[Friend]ResetSort(&this);

	public HRESULT NewFolder() mut => VT.[Friend]NewFolder(&this);

	public HRESULT Synchronize() mut => VT.[Friend]Synchronize(&this);

	public HRESULT Import() mut => VT.[Friend]Import(&this);

	public HRESULT Export() mut => VT.[Friend]Export(&this);

	public HRESULT InvokeContextMenuCommand(BSTR strCommand) mut => VT.[Friend]InvokeContextMenuCommand(&this, strCommand);

	public HRESULT MoveSelectionTo() mut => VT.[Friend]MoveSelectionTo(&this);

	public HRESULT get_SubscriptionsEnabled(int16* pBool) mut => VT.[Friend]get_SubscriptionsEnabled(&this, pBool);

	public HRESULT CreateSubscriptionForSelection(int16* pBool) mut => VT.[Friend]CreateSubscriptionForSelection(&this, pBool);

	public HRESULT DeleteSubscriptionForSelection(int16* pBool) mut => VT.[Friend]DeleteSubscriptionForSelection(&this, pBool);

	public HRESULT SetRoot(BSTR bstrFullPath) mut => VT.[Friend]SetRoot(&this, bstrFullPath);
}

[CRepr]struct IShellNameSpace : IShellFavoritesNameSpace
{
	public new const Guid IID = .(0xe572d3c9, 0x37be, 0x4ae2, 0x82, 0x5d, 0xd5, 0x21, 0x76, 0x3e, 0x31, 0x08);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellFavoritesNameSpace.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pgrfEnumFlags) get_EnumOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lVal) put_EnumOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** pItem) get_SelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pItem) put_SelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvar) get_Root;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT @var) put_Root;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piDepth) get_Depth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iDepth) put_Depth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puMode) get_Mode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uMode) put_Mode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) get_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) put_Flags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) put_TVFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* dwFlags) get_TVFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* bstrColumns) get_Columns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrColumns) put_Columns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piTypes) get_CountViewTypes;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iType) SetViewType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) SelectedItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT @var, int32 iDepth) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnselectAll;
	}


	public HRESULT get_EnumOptions(int32* pgrfEnumFlags) mut => VT.[Friend]get_EnumOptions(&this, pgrfEnumFlags);

	public HRESULT put_EnumOptions(int32 lVal) mut => VT.[Friend]put_EnumOptions(&this, lVal);

	public HRESULT get_SelectedItem(IDispatch** pItem) mut => VT.[Friend]get_SelectedItem(&this, pItem);

	public HRESULT put_SelectedItem(IDispatch* pItem) mut => VT.[Friend]put_SelectedItem(&this, pItem);

	public HRESULT get_Root(VARIANT* pvar) mut => VT.[Friend]get_Root(&this, pvar);

	public HRESULT put_Root(VARIANT @var) mut => VT.[Friend]put_Root(&this, @var);

	public HRESULT get_Depth(int32* piDepth) mut => VT.[Friend]get_Depth(&this, piDepth);

	public HRESULT put_Depth(int32 iDepth) mut => VT.[Friend]put_Depth(&this, iDepth);

	public HRESULT get_Mode(uint32* puMode) mut => VT.[Friend]get_Mode(&this, puMode);

	public HRESULT put_Mode(uint32 uMode) mut => VT.[Friend]put_Mode(&this, uMode);

	public HRESULT get_Flags(uint32* pdwFlags) mut => VT.[Friend]get_Flags(&this, pdwFlags);

	public HRESULT put_Flags(uint32 dwFlags) mut => VT.[Friend]put_Flags(&this, dwFlags);

	public HRESULT put_TVFlags(uint32 dwFlags) mut => VT.[Friend]put_TVFlags(&this, dwFlags);

	public HRESULT get_TVFlags(uint32* dwFlags) mut => VT.[Friend]get_TVFlags(&this, dwFlags);

	public HRESULT get_Columns(BSTR* bstrColumns) mut => VT.[Friend]get_Columns(&this, bstrColumns);

	public HRESULT put_Columns(BSTR bstrColumns) mut => VT.[Friend]put_Columns(&this, bstrColumns);

	public HRESULT get_CountViewTypes(int32* piTypes) mut => VT.[Friend]get_CountViewTypes(&this, piTypes);

	public HRESULT SetViewType(int32 iType) mut => VT.[Friend]SetViewType(&this, iType);

	public HRESULT SelectedItems(IDispatch** ppid) mut => VT.[Friend]SelectedItems(&this, ppid);

	public HRESULT Expand(VARIANT @var, int32 iDepth) mut => VT.[Friend]Expand(&this, @var, iDepth);

	public HRESULT UnselectAll() mut => VT.[Friend]UnselectAll(&this);
}

[CRepr]struct IScriptErrorList : IDispatch
{
	public new const Guid IID = .(0xf3470f24, 0x15fd, 0x11d2, 0xbb, 0x2e, 0x00, 0x80, 0x5f, 0xf7, 0xef, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) advanceError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) retreatError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCanAdvance) canAdvanceError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCanRetreat) canRetreatError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plLine) getErrorLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plChar) getErrorChar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCode) getErrorCode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstr) getErrorMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pstr) getErrorUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAlwaysShowLocked) getAlwaysShowLockState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfDetailsPaneOpen) getDetailsPaneOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDetailsPaneOpen) setDetailsPaneOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfPerErrorDisplay) getPerErrorDisplay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fPerErrorDisplay) setPerErrorDisplay;
	}


	public HRESULT advanceError() mut => VT.[Friend]advanceError(&this);

	public HRESULT retreatError() mut => VT.[Friend]retreatError(&this);

	public HRESULT canAdvanceError(BOOL* pfCanAdvance) mut => VT.[Friend]canAdvanceError(&this, pfCanAdvance);

	public HRESULT canRetreatError(BOOL* pfCanRetreat) mut => VT.[Friend]canRetreatError(&this, pfCanRetreat);

	public HRESULT getErrorLine(int32* plLine) mut => VT.[Friend]getErrorLine(&this, plLine);

	public HRESULT getErrorChar(int32* plChar) mut => VT.[Friend]getErrorChar(&this, plChar);

	public HRESULT getErrorCode(int32* plCode) mut => VT.[Friend]getErrorCode(&this, plCode);

	public HRESULT getErrorMsg(BSTR* pstr) mut => VT.[Friend]getErrorMsg(&this, pstr);

	public HRESULT getErrorUrl(BSTR* pstr) mut => VT.[Friend]getErrorUrl(&this, pstr);

	public HRESULT getAlwaysShowLockState(BOOL* pfAlwaysShowLocked) mut => VT.[Friend]getAlwaysShowLockState(&this, pfAlwaysShowLocked);

	public HRESULT getDetailsPaneOpen(BOOL* pfDetailsPaneOpen) mut => VT.[Friend]getDetailsPaneOpen(&this, pfDetailsPaneOpen);

	public HRESULT setDetailsPaneOpen(BOOL fDetailsPaneOpen) mut => VT.[Friend]setDetailsPaneOpen(&this, fDetailsPaneOpen);

	public HRESULT getPerErrorDisplay(BOOL* pfPerErrorDisplay) mut => VT.[Friend]getPerErrorDisplay(&this, pfPerErrorDisplay);

	public HRESULT setPerErrorDisplay(BOOL fPerErrorDisplay) mut => VT.[Friend]setPerErrorDisplay(&this, fPerErrorDisplay);
}

[CRepr]struct IFolderViewOC : IDispatch
{
	public new const Guid IID = .(0x9ba05970, 0xf6a8, 0x11cf, 0xa4, 0x42, 0x00, 0xa0, 0xc9, 0x0a, 0x8f, 0x39);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pdisp) SetFolderView;
	}


	public HRESULT SetFolderView(IDispatch* pdisp) mut => VT.[Friend]SetFolderView(&this, pdisp);
}

[CRepr]struct DShellFolderViewEvents : IDispatch
{
	public new const Guid IID = .(0x62112aa2, 0xebe4, 0x11cf, 0xa5, 0xfb, 0x00, 0x20, 0xaf, 0xe7, 0x29, 0x2d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct DFConstraint : IDispatch
{
	public new const Guid IID = .(0x4a3df050, 0x23bd, 0x11d2, 0x93, 0x9f, 0x00, 0xa0, 0xc9, 0x1e, 0xed, 0xba);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pv) get_Value;
	}


	public HRESULT get_Name(BSTR* pbs) mut => VT.[Friend]get_Name(&this, pbs);

	public HRESULT get_Value(VARIANT* pv) mut => VT.[Friend]get_Value(&this, pv);
}

[CRepr]struct FolderItem : IDispatch
{
	public new const Guid IID = .(0xfac32c80, 0xcbe4, 0x11ce, 0x83, 0x50, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_GetLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pb) get_IsLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pb) get_IsFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pb) get_IsFileSystem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pb) get_IsBrowsable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double* pdt) get_ModifyDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, double dt) put_ModifyDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pul) get_Size;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Type;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItemVerbs** ppfic) Verbs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vVerb) InvokeVerb;
	}


	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT get_Name(BSTR* pbs) mut => VT.[Friend]get_Name(&this, pbs);

	public HRESULT put_Name(BSTR bs) mut => VT.[Friend]put_Name(&this, bs);

	public HRESULT get_Path(BSTR* pbs) mut => VT.[Friend]get_Path(&this, pbs);

	public HRESULT get_GetLink(IDispatch** ppid) mut => VT.[Friend]get_GetLink(&this, ppid);

	public HRESULT get_GetFolder(IDispatch** ppid) mut => VT.[Friend]get_GetFolder(&this, ppid);

	public HRESULT get_IsLink(int16* pb) mut => VT.[Friend]get_IsLink(&this, pb);

	public HRESULT get_IsFolder(int16* pb) mut => VT.[Friend]get_IsFolder(&this, pb);

	public HRESULT get_IsFileSystem(int16* pb) mut => VT.[Friend]get_IsFileSystem(&this, pb);

	public HRESULT get_IsBrowsable(int16* pb) mut => VT.[Friend]get_IsBrowsable(&this, pb);

	public HRESULT get_ModifyDate(double* pdt) mut => VT.[Friend]get_ModifyDate(&this, pdt);

	public HRESULT put_ModifyDate(double dt) mut => VT.[Friend]put_ModifyDate(&this, dt);

	public HRESULT get_Size(int32* pul) mut => VT.[Friend]get_Size(&this, pul);

	public HRESULT get_Type(BSTR* pbs) mut => VT.[Friend]get_Type(&this, pbs);

	public HRESULT Verbs(FolderItemVerbs** ppfic) mut => VT.[Friend]Verbs(&this, ppfic);

	public HRESULT InvokeVerb(VARIANT vVerb) mut => VT.[Friend]InvokeVerb(&this, vVerb);
}

[CRepr]struct FolderItems : IDispatch
{
	public new const Guid IID = .(0x744129e0, 0xcbe5, 0x11ce, 0x83, 0x50, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, FolderItem** ppid) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) _NewEnum;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT Item(VARIANT index, FolderItem** ppid) mut => VT.[Friend]Item(&this, index, ppid);

	public HRESULT _NewEnum(IUnknown** ppunk) mut => VT.[Friend]_NewEnum(&this, ppunk);
}

[CRepr]struct FolderItemVerb : IDispatch
{
	public new const Guid IID = .(0x08ec3e00, 0x50b0, 0x11cf, 0x96, 0x0c, 0x00, 0x80, 0xc7, 0xf4, 0xee, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DoIt;
	}


	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT get_Name(BSTR* pbs) mut => VT.[Friend]get_Name(&this, pbs);

	public HRESULT DoIt() mut => VT.[Friend]DoIt(&this);
}

[CRepr]struct FolderItemVerbs : IDispatch
{
	public new const Guid IID = .(0x1f8352c0, 0x50b0, 0x11cf, 0x96, 0x0c, 0x00, 0x80, 0xc7, 0xf4, 0xee, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT index, FolderItemVerb** ppid) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppunk) _NewEnum;
	}


	public HRESULT get_Count(int32* plCount) mut => VT.[Friend]get_Count(&this, plCount);

	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT Item(VARIANT index, FolderItemVerb** ppid) mut => VT.[Friend]Item(&this, index, ppid);

	public HRESULT _NewEnum(IUnknown** ppunk) mut => VT.[Friend]_NewEnum(&this, ppunk);
}

[CRepr]struct Folder : IDispatch
{
	public new const Guid IID = .(0xbbcbde60, 0xc3ff, 0x11ce, 0x83, 0x50, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Title;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Folder** ppsf) get_ParentFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItems** ppid) Items;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bName, FolderItem** ppid) ParseName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bName, VARIANT vOptions) NewFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vItem, VARIANT vOptions) MoveHere;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vItem, VARIANT vOptions) CopyHere;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vItem, int32 iColumn, BSTR* pbs) GetDetailsOf;
	}


	public HRESULT get_Title(BSTR* pbs) mut => VT.[Friend]get_Title(&this, pbs);

	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT get_ParentFolder(Folder** ppsf) mut => VT.[Friend]get_ParentFolder(&this, ppsf);

	public HRESULT Items(FolderItems** ppid) mut => VT.[Friend]Items(&this, ppid);

	public HRESULT ParseName(BSTR bName, FolderItem** ppid) mut => VT.[Friend]ParseName(&this, bName, ppid);

	public HRESULT NewFolder(BSTR bName, VARIANT vOptions) mut => VT.[Friend]NewFolder(&this, bName, vOptions);

	public HRESULT MoveHere(VARIANT vItem, VARIANT vOptions) mut => VT.[Friend]MoveHere(&this, vItem, vOptions);

	public HRESULT CopyHere(VARIANT vItem, VARIANT vOptions) mut => VT.[Friend]CopyHere(&this, vItem, vOptions);

	public HRESULT GetDetailsOf(VARIANT vItem, int32 iColumn, BSTR* pbs) mut => VT.[Friend]GetDetailsOf(&this, vItem, iColumn, pbs);
}

[CRepr]struct Folder2 : Folder
{
	public new const Guid IID = .(0xf0d2d8ef, 0x3890, 0x11d2, 0xbf, 0x8b, 0x00, 0xc0, 0x4f, 0xb9, 0x36, 0x61);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : Folder.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItem** ppfi) get_Self;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pul) get_OfflineStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Synchronize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbHaveToShowWebViewBarricade) get_HaveToShowWebViewBarricade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DismissedWebViewBarricade;
	}


	public HRESULT get_Self(FolderItem** ppfi) mut => VT.[Friend]get_Self(&this, ppfi);

	public HRESULT get_OfflineStatus(int32* pul) mut => VT.[Friend]get_OfflineStatus(&this, pul);

	public HRESULT Synchronize() mut => VT.[Friend]Synchronize(&this);

	public HRESULT get_HaveToShowWebViewBarricade(int16* pbHaveToShowWebViewBarricade) mut => VT.[Friend]get_HaveToShowWebViewBarricade(&this, pbHaveToShowWebViewBarricade);

	public HRESULT DismissedWebViewBarricade() mut => VT.[Friend]DismissedWebViewBarricade(&this);
}

[CRepr]struct Folder3 : Folder2
{
	public new const Guid IID = .(0xa7ae5f64, 0xc4d7, 0x4d7f, 0x93, 0x07, 0x4d, 0x24, 0xee, 0x54, 0xb8, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : Folder2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16* pbShowWebViewBarricade) get_ShowWebViewBarricade;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 bShowWebViewBarricade) put_ShowWebViewBarricade;
	}


	public HRESULT get_ShowWebViewBarricade(int16* pbShowWebViewBarricade) mut => VT.[Friend]get_ShowWebViewBarricade(&this, pbShowWebViewBarricade);

	public HRESULT put_ShowWebViewBarricade(int16 bShowWebViewBarricade) mut => VT.[Friend]put_ShowWebViewBarricade(&this, bShowWebViewBarricade);
}

[CRepr]struct FolderItem2 : FolderItem
{
	public new const Guid IID = .(0xedc817aa, 0x92b8, 0x11d1, 0xb0, 0x75, 0x00, 0xc0, 0x4f, 0xc3, 0x3a, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : FolderItem.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vVerb, VARIANT vArgs) InvokeVerbEx;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropName, VARIANT* pvRet) ExtendedProperty;
	}


	public HRESULT InvokeVerbEx(VARIANT vVerb, VARIANT vArgs) mut => VT.[Friend]InvokeVerbEx(&this, vVerb, vArgs);

	public HRESULT ExtendedProperty(BSTR bstrPropName, VARIANT* pvRet) mut => VT.[Friend]ExtendedProperty(&this, bstrPropName, pvRet);
}

[CRepr]struct FolderItems2 : FolderItems
{
	public new const Guid IID = .(0xc94f0ad0, 0xf363, 0x11d2, 0xa3, 0x27, 0x00, 0xc0, 0x4f, 0x8e, 0xec, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : FolderItems.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vVerb, VARIANT vArgs) InvokeVerbEx;
	}


	public HRESULT InvokeVerbEx(VARIANT vVerb, VARIANT vArgs) mut => VT.[Friend]InvokeVerbEx(&this, vVerb, vArgs);
}

[CRepr]struct FolderItems3 : FolderItems2
{
	public new const Guid IID = .(0xeaa7c309, 0xbbec, 0x49d5, 0x82, 0x1d, 0x64, 0xd9, 0x66, 0xcb, 0x66, 0x7f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : FolderItems2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 grfFlags, BSTR bstrFileSpec) Filter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItemVerbs** ppfic) get_Verbs;
	}


	public HRESULT Filter(int32 grfFlags, BSTR bstrFileSpec) mut => VT.[Friend]Filter(&this, grfFlags, bstrFileSpec);

	public HRESULT get_Verbs(FolderItemVerbs** ppfic) mut => VT.[Friend]get_Verbs(&this, ppfic);
}

[CRepr]struct IShellLinkDual : IDispatch
{
	public new const Guid IID = .(0x88a05c00, 0xf000, 0x11ce, 0x83, 0x50, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs) put_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_WorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs) put_WorkingDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs) get_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs) put_Arguments;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piHK) get_Hotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iHK) put_Hotkey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piShowCommand) get_ShowCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iShowCommand) put_ShowCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 fFlags) Resolve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbs, int32* piIcon) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bs, int32 iIcon) SetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vWhere) Save;
	}


	public HRESULT get_Path(BSTR* pbs) mut => VT.[Friend]get_Path(&this, pbs);

	public HRESULT put_Path(BSTR bs) mut => VT.[Friend]put_Path(&this, bs);

	public HRESULT get_Description(BSTR* pbs) mut => VT.[Friend]get_Description(&this, pbs);

	public HRESULT put_Description(BSTR bs) mut => VT.[Friend]put_Description(&this, bs);

	public HRESULT get_WorkingDirectory(BSTR* pbs) mut => VT.[Friend]get_WorkingDirectory(&this, pbs);

	public HRESULT put_WorkingDirectory(BSTR bs) mut => VT.[Friend]put_WorkingDirectory(&this, bs);

	public HRESULT get_Arguments(BSTR* pbs) mut => VT.[Friend]get_Arguments(&this, pbs);

	public HRESULT put_Arguments(BSTR bs) mut => VT.[Friend]put_Arguments(&this, bs);

	public HRESULT get_Hotkey(int32* piHK) mut => VT.[Friend]get_Hotkey(&this, piHK);

	public HRESULT put_Hotkey(int32 iHK) mut => VT.[Friend]put_Hotkey(&this, iHK);

	public HRESULT get_ShowCommand(int32* piShowCommand) mut => VT.[Friend]get_ShowCommand(&this, piShowCommand);

	public HRESULT put_ShowCommand(int32 iShowCommand) mut => VT.[Friend]put_ShowCommand(&this, iShowCommand);

	public HRESULT Resolve(int32 fFlags) mut => VT.[Friend]Resolve(&this, fFlags);

	public HRESULT GetIconLocation(BSTR* pbs, int32* piIcon) mut => VT.[Friend]GetIconLocation(&this, pbs, piIcon);

	public HRESULT SetIconLocation(BSTR bs, int32 iIcon) mut => VT.[Friend]SetIconLocation(&this, bs, iIcon);

	public HRESULT Save(VARIANT vWhere) mut => VT.[Friend]Save(&this, vWhere);
}

[CRepr]struct IShellLinkDual2 : IShellLinkDual
{
	public new const Guid IID = .(0x317ee249, 0xf12e, 0x11d2, 0xb1, 0xe4, 0x00, 0xc0, 0x4f, 0x8e, 0xeb, 0x3e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellLinkDual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItem** ppfi) get_Target;
	}


	public HRESULT get_Target(FolderItem** ppfi) mut => VT.[Friend]get_Target(&this, ppfi);
}

[CRepr]struct IShellFolderViewDual : IDispatch
{
	public new const Guid IID = .(0xe7a1af80, 0x4d96, 0x11cf, 0x96, 0x0c, 0x00, 0x80, 0xc7, 0xf4, 0xee, 0x85);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Folder** ppid) get_Folder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItems** ppid) SelectedItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItem** ppid) get_FocusedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvfi, int32 dwFlags) SelectItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FolderItem* pfi, VARIANT vx, VARIANT vy, BSTR* pbs) PopupItemMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppDisp) get_Script;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plViewOptions) get_ViewOptions;
	}


	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT get_Folder(Folder** ppid) mut => VT.[Friend]get_Folder(&this, ppid);

	public HRESULT SelectedItems(FolderItems** ppid) mut => VT.[Friend]SelectedItems(&this, ppid);

	public HRESULT get_FocusedItem(FolderItem** ppid) mut => VT.[Friend]get_FocusedItem(&this, ppid);

	public HRESULT SelectItem(VARIANT* pvfi, int32 dwFlags) mut => VT.[Friend]SelectItem(&this, pvfi, dwFlags);

	public HRESULT PopupItemMenu(FolderItem* pfi, VARIANT vx, VARIANT vy, BSTR* pbs) mut => VT.[Friend]PopupItemMenu(&this, pfi, vx, vy, pbs);

	public HRESULT get_Script(IDispatch** ppDisp) mut => VT.[Friend]get_Script(&this, ppDisp);

	public HRESULT get_ViewOptions(int32* plViewOptions) mut => VT.[Friend]get_ViewOptions(&this, plViewOptions);
}

[CRepr]struct IShellFolderViewDual2 : IShellFolderViewDual
{
	public new const Guid IID = .(0x31c147b6, 0x0ade, 0x4a3c, 0xb5, 0x14, 0xdd, 0xf9, 0x32, 0xef, 0x6d, 0x17);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellFolderViewDual.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pViewMode) get_CurrentViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 ViewMode) put_CurrentViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iRelative) SelectItemRelative;
	}


	public HRESULT get_CurrentViewMode(uint32* pViewMode) mut => VT.[Friend]get_CurrentViewMode(&this, pViewMode);

	public HRESULT put_CurrentViewMode(uint32 ViewMode) mut => VT.[Friend]put_CurrentViewMode(&this, ViewMode);

	public HRESULT SelectItemRelative(int32 iRelative) mut => VT.[Friend]SelectItemRelative(&this, iRelative);
}

[CRepr]struct IShellFolderViewDual3 : IShellFolderViewDual2
{
	public new const Guid IID = .(0x29ec8e6c, 0x46d3, 0x411f, 0xba, 0xaa, 0x61, 0x1a, 0x6c, 0x9c, 0xac, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellFolderViewDual2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGroupBy) get_GroupBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrGroupBy) put_GroupBy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) get_FolderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) put_FolderFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSortColumns) get_SortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSortColumns) put_SortColumns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iIconSize) put_IconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* piIconSize) get_IconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFilterText) FilterView;
	}


	public HRESULT get_GroupBy(BSTR* pbstrGroupBy) mut => VT.[Friend]get_GroupBy(&this, pbstrGroupBy);

	public HRESULT put_GroupBy(BSTR bstrGroupBy) mut => VT.[Friend]put_GroupBy(&this, bstrGroupBy);

	public HRESULT get_FolderFlags(uint32* pdwFlags) mut => VT.[Friend]get_FolderFlags(&this, pdwFlags);

	public HRESULT put_FolderFlags(uint32 dwFlags) mut => VT.[Friend]put_FolderFlags(&this, dwFlags);

	public HRESULT get_SortColumns(BSTR* pbstrSortColumns) mut => VT.[Friend]get_SortColumns(&this, pbstrSortColumns);

	public HRESULT put_SortColumns(BSTR bstrSortColumns) mut => VT.[Friend]put_SortColumns(&this, bstrSortColumns);

	public HRESULT put_IconSize(int32 iIconSize) mut => VT.[Friend]put_IconSize(&this, iIconSize);

	public HRESULT get_IconSize(int32* piIconSize) mut => VT.[Friend]get_IconSize(&this, piIconSize);

	public HRESULT FilterView(BSTR bstrFilterText) mut => VT.[Friend]FilterView(&this, bstrFilterText);
}

[CRepr]struct IShellDispatch : IDispatch
{
	public new const Guid IID = .(0xd8f015c0, 0xc278, 0x11ce, 0xa4, 0x9e, 0x44, 0x45, 0x53, 0x54, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Application;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) get_Parent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDir, Folder** ppsdf) NameSpace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Hwnd, BSTR Title, int32 Options, VARIANT RootFolder, Folder** ppsdf) BrowseForFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** ppid) Windows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDir) Open;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT vDir) Explore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) MinimizeAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UndoMinimizeALL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FileRun;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CascadeWindows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TileVertically;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TileHorizontally;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ShutdownWindows;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Suspend;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EjectPC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) TrayProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Help;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FindFiles;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FindComputer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDir) ControlPanelItem;
	}


	public HRESULT get_Application(IDispatch** ppid) mut => VT.[Friend]get_Application(&this, ppid);

	public HRESULT get_Parent(IDispatch** ppid) mut => VT.[Friend]get_Parent(&this, ppid);

	public HRESULT NameSpace(VARIANT vDir, Folder** ppsdf) mut => VT.[Friend]NameSpace(&this, vDir, ppsdf);

	public HRESULT BrowseForFolder(int32 Hwnd, BSTR Title, int32 Options, VARIANT RootFolder, Folder** ppsdf) mut => VT.[Friend]BrowseForFolder(&this, Hwnd, Title, Options, RootFolder, ppsdf);

	public HRESULT Windows(IDispatch** ppid) mut => VT.[Friend]Windows(&this, ppid);

	public HRESULT Open(VARIANT vDir) mut => VT.[Friend]Open(&this, vDir);

	public HRESULT Explore(VARIANT vDir) mut => VT.[Friend]Explore(&this, vDir);

	public HRESULT MinimizeAll() mut => VT.[Friend]MinimizeAll(&this);

	public HRESULT UndoMinimizeALL() mut => VT.[Friend]UndoMinimizeALL(&this);

	public HRESULT FileRun() mut => VT.[Friend]FileRun(&this);

	public HRESULT CascadeWindows() mut => VT.[Friend]CascadeWindows(&this);

	public HRESULT TileVertically() mut => VT.[Friend]TileVertically(&this);

	public HRESULT TileHorizontally() mut => VT.[Friend]TileHorizontally(&this);

	public HRESULT ShutdownWindows() mut => VT.[Friend]ShutdownWindows(&this);

	public HRESULT Suspend() mut => VT.[Friend]Suspend(&this);

	public HRESULT EjectPC() mut => VT.[Friend]EjectPC(&this);

	public HRESULT SetTime() mut => VT.[Friend]SetTime(&this);

	public HRESULT TrayProperties() mut => VT.[Friend]TrayProperties(&this);

	public HRESULT Help() mut => VT.[Friend]Help(&this);

	public HRESULT FindFiles() mut => VT.[Friend]FindFiles(&this);

	public HRESULT FindComputer() mut => VT.[Friend]FindComputer(&this);

	public HRESULT RefreshMenu() mut => VT.[Friend]RefreshMenu(&this);

	public HRESULT ControlPanelItem(BSTR bstrDir) mut => VT.[Friend]ControlPanelItem(&this, bstrDir);
}

[CRepr]struct IShellDispatch2 : IShellDispatch
{
	public new const Guid IID = .(0xa4c6892c, 0x3ba9, 0x11d2, 0x9d, 0xea, 0x00, 0xc0, 0x4f, 0xb1, 0x61, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Group, BSTR Restriction, int32* plRestrictValue) IsRestricted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR File, VARIANT vArgs, VARIANT vDir, VARIANT vOperation, VARIANT vShow) ShellExecute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, BSTR location, BSTR model) FindPrinter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR name, VARIANT* pv) GetSystemInformation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ServiceName, VARIANT Persistent, VARIANT* pSuccess) ServiceStart;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ServiceName, VARIANT Persistent, VARIANT* pSuccess) ServiceStop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ServiceName, VARIANT* pRunning) IsServiceRunning;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ServiceName, VARIANT* pCanStartStop) CanStartStopService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrClsid, VARIANT bShow, VARIANT* pSuccess) ShowBrowserBar;
	}


	public HRESULT IsRestricted(BSTR Group, BSTR Restriction, int32* plRestrictValue) mut => VT.[Friend]IsRestricted(&this, Group, Restriction, plRestrictValue);

	public HRESULT ShellExecute(BSTR File, VARIANT vArgs, VARIANT vDir, VARIANT vOperation, VARIANT vShow) mut => VT.[Friend]ShellExecute(&this, File, vArgs, vDir, vOperation, vShow);

	public HRESULT FindPrinter(BSTR name, BSTR location, BSTR model) mut => VT.[Friend]FindPrinter(&this, name, location, model);

	public HRESULT GetSystemInformation(BSTR name, VARIANT* pv) mut => VT.[Friend]GetSystemInformation(&this, name, pv);

	public HRESULT ServiceStart(BSTR ServiceName, VARIANT Persistent, VARIANT* pSuccess) mut => VT.[Friend]ServiceStart(&this, ServiceName, Persistent, pSuccess);

	public HRESULT ServiceStop(BSTR ServiceName, VARIANT Persistent, VARIANT* pSuccess) mut => VT.[Friend]ServiceStop(&this, ServiceName, Persistent, pSuccess);

	public HRESULT IsServiceRunning(BSTR ServiceName, VARIANT* pRunning) mut => VT.[Friend]IsServiceRunning(&this, ServiceName, pRunning);

	public HRESULT CanStartStopService(BSTR ServiceName, VARIANT* pCanStartStop) mut => VT.[Friend]CanStartStopService(&this, ServiceName, pCanStartStop);

	public HRESULT ShowBrowserBar(BSTR bstrClsid, VARIANT bShow, VARIANT* pSuccess) mut => VT.[Friend]ShowBrowserBar(&this, bstrClsid, bShow, pSuccess);
}

[CRepr]struct IShellDispatch3 : IShellDispatch2
{
	public new const Guid IID = .(0x177160ca, 0xbb5a, 0x411c, 0x84, 0x1d, 0xbd, 0x38, 0xfa, 0xcd, 0xea, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellDispatch2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT varFile, BSTR bstrCategory) AddToRecent;
	}


	public HRESULT AddToRecent(VARIANT varFile, BSTR bstrCategory) mut => VT.[Friend]AddToRecent(&this, varFile, bstrCategory);
}

[CRepr]struct IShellDispatch4 : IShellDispatch3
{
	public new const Guid IID = .(0xefd84b2d, 0x4bcf, 0x4298, 0xbe, 0x25, 0xeb, 0x54, 0x2a, 0x59, 0xfb, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellDispatch3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WindowsSecurity;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ToggleDesktop;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPolicyName, VARIANT* pValue) ExplorerPolicy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lSetting, int16* pResult) GetSetting;
	}


	public HRESULT WindowsSecurity() mut => VT.[Friend]WindowsSecurity(&this);

	public HRESULT ToggleDesktop() mut => VT.[Friend]ToggleDesktop(&this);

	public HRESULT ExplorerPolicy(BSTR bstrPolicyName, VARIANT* pValue) mut => VT.[Friend]ExplorerPolicy(&this, bstrPolicyName, pValue);

	public HRESULT GetSetting(int32 lSetting, int16* pResult) mut => VT.[Friend]GetSetting(&this, lSetting, pResult);
}

[CRepr]struct IShellDispatch5 : IShellDispatch4
{
	public new const Guid IID = .(0x866738b9, 0x6cf2, 0x4de8, 0x87, 0x67, 0xf7, 0x94, 0xeb, 0xe7, 0x4f, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellDispatch4.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) WindowSwitcher;
	}


	public HRESULT WindowSwitcher() mut => VT.[Friend]WindowSwitcher(&this);
}

[CRepr]struct IShellDispatch6 : IShellDispatch5
{
	public new const Guid IID = .(0x286e6f1b, 0x7113, 0x4355, 0x95, 0x62, 0x96, 0xb7, 0xe9, 0xd6, 0x4c, 0x54);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellDispatch5.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SearchCommand;
	}


	public HRESULT SearchCommand() mut => VT.[Friend]SearchCommand(&this);
}

[CRepr]struct IFileSearchBand : IDispatch
{
	public new const Guid IID = .(0x2d91eea1, 0x9932, 0x11d2, 0xbe, 0x86, 0x00, 0xa0, 0xc9, 0xa8, 0x3d, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSearchID, int16 bNavToResults, VARIANT* pvarScope, VARIANT* pvarQueryFile) SetSearchParameters;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSearchID) get_SearchID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarScope) get_Scope;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarFile) get_QueryFile;
	}


	public HRESULT SetFocus() mut => VT.[Friend]SetFocus(&this);

	public HRESULT SetSearchParameters(BSTR* pbstrSearchID, int16 bNavToResults, VARIANT* pvarScope, VARIANT* pvarQueryFile) mut => VT.[Friend]SetSearchParameters(&this, pbstrSearchID, bNavToResults, pvarScope, pvarQueryFile);

	public HRESULT get_SearchID(BSTR* pbstrSearchID) mut => VT.[Friend]get_SearchID(&this, pbstrSearchID);

	public HRESULT get_Scope(VARIANT* pvarScope) mut => VT.[Friend]get_Scope(&this, pvarScope);

	public HRESULT get_QueryFile(VARIANT* pvarFile) mut => VT.[Friend]get_QueryFile(&this, pvarFile);
}

[CRepr]struct IWebWizardHost : IDispatch
{
	public new const Guid IID = .(0x18bcc359, 0x4990, 0x4bfb, 0xb9, 0x51, 0x3c, 0x83, 0x70, 0x2b, 0xe5, 0xf9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FinalBack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FinalNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Cancel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCaption) put_Caption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCaption) get_Caption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* pvProperty) put_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* pvProperty) get_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int16 vfEnableBack, int16 vfEnableNext, int16 vfLastPage) SetWizardButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrHeaderTitle, BSTR bstrHeaderSubtitle) SetHeaderText;
	}


	public HRESULT FinalBack() mut => VT.[Friend]FinalBack(&this);

	public HRESULT FinalNext() mut => VT.[Friend]FinalNext(&this);

	public HRESULT Cancel() mut => VT.[Friend]Cancel(&this);

	public HRESULT put_Caption(BSTR bstrCaption) mut => VT.[Friend]put_Caption(&this, bstrCaption);

	public HRESULT get_Caption(BSTR* pbstrCaption) mut => VT.[Friend]get_Caption(&this, pbstrCaption);

	public HRESULT put_Property(BSTR bstrPropertyName, VARIANT* pvProperty) mut => VT.[Friend]put_Property(&this, bstrPropertyName, pvProperty);

	public HRESULT get_Property(BSTR bstrPropertyName, VARIANT* pvProperty) mut => VT.[Friend]get_Property(&this, bstrPropertyName, pvProperty);

	public HRESULT SetWizardButtons(int16 vfEnableBack, int16 vfEnableNext, int16 vfLastPage) mut => VT.[Friend]SetWizardButtons(&this, vfEnableBack, vfEnableNext, vfLastPage);

	public HRESULT SetHeaderText(BSTR bstrHeaderTitle, BSTR bstrHeaderSubtitle) mut => VT.[Friend]SetHeaderText(&this, bstrHeaderTitle, bstrHeaderSubtitle);
}

[CRepr]struct IWebWizardHost2 : IWebWizardHost
{
	public new const Guid IID = .(0xf9c013dc, 0x3c23, 0x4041, 0x8e, 0x39, 0xcf, 0xb4, 0x02, 0xf7, 0xea, 0x59);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWebWizardHost.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR value, BSTR* signedValue) SignString;
	}


	public HRESULT SignString(BSTR value, BSTR* signedValue) mut => VT.[Friend]SignString(&this, value, signedValue);
}

[CRepr]struct INewWDEvents : IWebWizardHost
{
	public new const Guid IID = .(0x0751c551, 0x7568, 0x41c9, 0x8e, 0x5b, 0xe2, 0x2e, 0x38, 0x91, 0x92, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IWebWizardHost.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSignInUrl, int16* pvfAuthenitcated) PassportAuthenticate;
	}


	public HRESULT PassportAuthenticate(BSTR bstrSignInUrl, int16* pvfAuthenitcated) mut => VT.[Friend]PassportAuthenticate(&this, bstrSignInUrl, pvfAuthenitcated);
}

[CRepr]struct IAutoComplete : IUnknown
{
	public new const Guid IID = .(0x00bb2762, 0x6a77, 0x11d0, 0xa5, 0x35, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndEdit, IUnknown* punkACL, PWSTR pwszRegKeyPath, PWSTR pwszQuickComplete) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
	}


	public HRESULT Init(HWND hwndEdit, IUnknown* punkACL, PWSTR pwszRegKeyPath, PWSTR pwszQuickComplete) mut => VT.[Friend]Init(&this, hwndEdit, punkACL, pwszRegKeyPath, pwszQuickComplete);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);
}

[CRepr]struct IAutoComplete2 : IAutoComplete
{
	public new const Guid IID = .(0xeac04bc0, 0x3791, 0x11d2, 0xbb, 0x95, 0x00, 0x60, 0x97, 0x7b, 0x46, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IAutoComplete.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlag) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlag) GetOptions;
	}


	public HRESULT SetOptions(uint32 dwFlag) mut => VT.[Friend]SetOptions(&this, dwFlag);

	public HRESULT GetOptions(uint32* pdwFlag) mut => VT.[Friend]GetOptions(&this, pdwFlag);
}

[CRepr]struct IEnumACString : IEnumString
{
	public new const Guid IID = .(0x8e74c210, 0xcf9d, 0x4eaf, 0xa4, 0x03, 0x73, 0x56, 0x42, 0x8f, 0x0a, 0x5a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEnumString.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszUrl, uint32 cchMax, uint32* pulSortIndex) NextItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwOptions) SetEnumOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwOptions) GetEnumOptions;
	}


	public HRESULT NextItem(char16* pszUrl, uint32 cchMax, uint32* pulSortIndex) mut => VT.[Friend]NextItem(&this, pszUrl, cchMax, pulSortIndex);

	public HRESULT SetEnumOptions(uint32 dwOptions) mut => VT.[Friend]SetEnumOptions(&this, dwOptions);

	public HRESULT GetEnumOptions(uint32* pdwOptions) mut => VT.[Friend]GetEnumOptions(&this, pdwOptions);
}

[CRepr]struct IDataObjectAsyncCapability : IUnknown
{
	public new const Guid IID = .(0x3d8b0590, 0xf691, 0x11d2, 0x8e, 0xa9, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fDoOpAsync) SetAsyncMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfIsOpAsync) GetAsyncMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IBindCtx* pbcReserved) StartOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfInAsyncOp) InOperation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hResult, IBindCtx* pbcReserved, uint32 dwEffects) EndOperation;
	}


	public HRESULT SetAsyncMode(BOOL fDoOpAsync) mut => VT.[Friend]SetAsyncMode(&this, fDoOpAsync);

	public HRESULT GetAsyncMode(BOOL* pfIsOpAsync) mut => VT.[Friend]GetAsyncMode(&this, pfIsOpAsync);

	public HRESULT StartOperation(IBindCtx* pbcReserved) mut => VT.[Friend]StartOperation(&this, pbcReserved);

	public HRESULT InOperation(BOOL* pfInAsyncOp) mut => VT.[Friend]InOperation(&this, pfInAsyncOp);

	public HRESULT EndOperation(HRESULT hResult, IBindCtx* pbcReserved, uint32 dwEffects) mut => VT.[Friend]EndOperation(&this, hResult, pbcReserved, dwEffects);
}

[CRepr]struct IExtractIconA : IUnknown
{
	public new const Guid IID = .(0x000214eb, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFlags, uint8* pszIconFile, uint32 cchMax, int32* piIndex, uint32* pwFlags) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pszFile, uint32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize) Extract;
	}


	public HRESULT GetIconLocation(uint32 uFlags, uint8* pszIconFile, uint32 cchMax, int32* piIndex, uint32* pwFlags) mut => VT.[Friend]GetIconLocation(&this, uFlags, pszIconFile, cchMax, piIndex, pwFlags);

	public HRESULT Extract(PSTR pszFile, uint32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize) mut => VT.[Friend]Extract(&this, pszFile, nIconIndex, phiconLarge, phiconSmall, nIconSize);
}

[CRepr]struct IExtractIconW : IUnknown
{
	public new const Guid IID = .(0x000214fa, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uFlags, char16* pszIconFile, uint32 cchMax, int32* piIndex, uint32* pwFlags) GetIconLocation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFile, uint32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize) Extract;
	}


	public HRESULT GetIconLocation(uint32 uFlags, char16* pszIconFile, uint32 cchMax, int32* piIndex, uint32* pwFlags) mut => VT.[Friend]GetIconLocation(&this, uFlags, pszIconFile, cchMax, piIndex, pwFlags);

	public HRESULT Extract(PWSTR pszFile, uint32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize) mut => VT.[Friend]Extract(&this, pszFile, nIconIndex, phiconLarge, phiconSmall, nIconSize);
}

[CRepr]struct IShellIconOverlayManager : IUnknown
{
	public new const Guid IID = .(0xf10b5e34, 0xdd3b, 0x42a7, 0xaa, 0x7d, 0x2f, 0x4e, 0xc5, 0x4b, 0xb0, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPath, uint32 dwAttrib, int32* pIndex, uint32 dwflags) GetFileOverlayInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszPath, uint32 dwAttrib, int32* pIndex, uint32 dwflags, int32 iReservedID) GetReservedOverlayInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) RefreshOverlayImages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) LoadNonloadedOverlayIdentifiers;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iImage, int32* piIndex, BOOL fAdd) OverlayIndexFromImageIndex;
	}


	public HRESULT GetFileOverlayInfo(PWSTR pwszPath, uint32 dwAttrib, int32* pIndex, uint32 dwflags) mut => VT.[Friend]GetFileOverlayInfo(&this, pwszPath, dwAttrib, pIndex, dwflags);

	public HRESULT GetReservedOverlayInfo(PWSTR pwszPath, uint32 dwAttrib, int32* pIndex, uint32 dwflags, int32 iReservedID) mut => VT.[Friend]GetReservedOverlayInfo(&this, pwszPath, dwAttrib, pIndex, dwflags, iReservedID);

	public HRESULT RefreshOverlayImages(uint32 dwFlags) mut => VT.[Friend]RefreshOverlayImages(&this, dwFlags);

	public HRESULT LoadNonloadedOverlayIdentifiers() mut => VT.[Friend]LoadNonloadedOverlayIdentifiers(&this);

	public HRESULT OverlayIndexFromImageIndex(int32 iImage, int32* piIndex, BOOL fAdd) mut => VT.[Friend]OverlayIndexFromImageIndex(&this, iImage, piIndex, fAdd);
}

[CRepr]struct IShellIconOverlay : IUnknown
{
	public new const Guid IID = .(0x7d688a70, 0xc613, 0x11d0, 0x99, 0x9b, 0x00, 0xc0, 0x4f, 0xd6, 0x55, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, int32* pIndex) GetOverlayIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, int32* pIconIndex) GetOverlayIconIndex;
	}


	public HRESULT GetOverlayIndex(ITEMIDLIST* pidl, int32* pIndex) mut => VT.[Friend]GetOverlayIndex(&this, pidl, pIndex);

	public HRESULT GetOverlayIconIndex(ITEMIDLIST* pidl, int32* pIconIndex) mut => VT.[Friend]GetOverlayIconIndex(&this, pidl, pIconIndex);
}

[CRepr]struct IURLSearchHook : IUnknown
{
	public new const Guid IID = .(0xac60f6a0, 0x0fd9, 0x11d0, 0x99, 0xcb, 0x00, 0xc0, 0x4f, 0xd6, 0x44, 0x97);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszSearchURL, uint32 cchBufferSize) Translate;
	}


	public HRESULT Translate(char16* pwszSearchURL, uint32 cchBufferSize) mut => VT.[Friend]Translate(&this, pwszSearchURL, cchBufferSize);
}

[CRepr]struct ISearchContext : IUnknown
{
	public new const Guid IID = .(0x09f656a2, 0x41af, 0x480c, 0x88, 0xf7, 0x16, 0xcc, 0x0d, 0x16, 0x46, 0x15);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSearchUrl) GetSearchUrl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSearchText) GetSearchText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSearchStyle) GetSearchStyle;
	}


	public HRESULT GetSearchUrl(BSTR* pbstrSearchUrl) mut => VT.[Friend]GetSearchUrl(&this, pbstrSearchUrl);

	public HRESULT GetSearchText(BSTR* pbstrSearchText) mut => VT.[Friend]GetSearchText(&this, pbstrSearchText);

	public HRESULT GetSearchStyle(uint32* pdwSearchStyle) mut => VT.[Friend]GetSearchStyle(&this, pdwSearchStyle);
}

[CRepr]struct IURLSearchHook2 : IURLSearchHook
{
	public new const Guid IID = .(0x5ee44da4, 0x6d32, 0x46e3, 0x86, 0xbc, 0x07, 0x54, 0x0d, 0xed, 0xd0, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IURLSearchHook.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwszSearchURL, uint32 cchBufferSize, ISearchContext* pSearchContext) TranslateWithSearchContext;
	}


	public HRESULT TranslateWithSearchContext(char16* pwszSearchURL, uint32 cchBufferSize, ISearchContext* pSearchContext) mut => VT.[Friend]TranslateWithSearchContext(&this, pwszSearchURL, cchBufferSize, pSearchContext);
}

[CRepr]struct IShellDetails : IUnknown
{
	public new const Guid IID = .(0x000214ec, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 iColumn, SHELLDETAILS* pDetails) GetDetailsOf;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iColumn) ColumnClick;
	}


	public HRESULT GetDetailsOf(ITEMIDLIST* pidl, uint32 iColumn, SHELLDETAILS* pDetails) mut => VT.[Friend]GetDetailsOf(&this, pidl, iColumn, pDetails);

	public HRESULT ColumnClick(uint32 iColumn) mut => VT.[Friend]ColumnClick(&this, iColumn);
}

[CRepr]struct IObjMgr : IUnknown
{
	public new const Guid IID = .(0x00bb2761, 0x6a77, 0x11d0, 0xa5, 0x35, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) Append;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) Remove;
	}


	public HRESULT Append(IUnknown* punk) mut => VT.[Friend]Append(&this, punk);

	public HRESULT Remove(IUnknown* punk) mut => VT.[Friend]Remove(&this, punk);
}

[CRepr]struct IACList : IUnknown
{
	public new const Guid IID = .(0x77a130b0, 0x94fd, 0x11d0, 0xa5, 0x44, 0x00, 0xc0, 0x4f, 0xd7, 0xd0, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszExpand) Expand;
	}


	public HRESULT Expand(PWSTR pszExpand) mut => VT.[Friend]Expand(&this, pszExpand);
}

[CRepr]struct IACList2 : IACList
{
	public new const Guid IID = .(0x470141a0, 0x5186, 0x11d2, 0xbb, 0xb6, 0x00, 0x60, 0x97, 0x7b, 0x46, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IACList.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlag) SetOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlag) GetOptions;
	}


	public HRESULT SetOptions(uint32 dwFlag) mut => VT.[Friend]SetOptions(&this, dwFlag);

	public HRESULT GetOptions(uint32* pdwFlag) mut => VT.[Friend]GetOptions(&this, pdwFlag);
}

[CRepr]struct IProgressDialog : IUnknown
{
	public new const Guid IID = .(0xebbc7c04, 0x315e, 0x11d2, 0xb6, 0x2f, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, IUnknown* punkEnableModless, uint32 dwFlags, void* pvResevered) StartProgressDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopProgressDialog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzTitle) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE hInstAnimation, uint32 idAnimation) SetAnimation;
		protected new function [CallingConvention(.Stdcall)] BOOL(SelfOuter* self) HasUserCancelled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCompleted, uint32 dwTotal) SetProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 ullCompleted, uint64 ullTotal) SetProgress64;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwLineNum, PWSTR pwzString, BOOL fCompactPath, void* pvResevered) SetLine;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzCancelMsg, void* pvResevered) SetCancelMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwTimerAction, void* pvResevered) Timer;
	}


	public HRESULT StartProgressDialog(HWND hwndParent, IUnknown* punkEnableModless, uint32 dwFlags, void* pvResevered) mut => VT.[Friend]StartProgressDialog(&this, hwndParent, punkEnableModless, dwFlags, pvResevered);

	public HRESULT StopProgressDialog() mut => VT.[Friend]StopProgressDialog(&this);

	public HRESULT SetTitle(PWSTR pwzTitle) mut => VT.[Friend]SetTitle(&this, pwzTitle);

	public HRESULT SetAnimation(HINSTANCE hInstAnimation, uint32 idAnimation) mut => VT.[Friend]SetAnimation(&this, hInstAnimation, idAnimation);

	public BOOL HasUserCancelled() mut => VT.[Friend]HasUserCancelled(&this);

	public HRESULT SetProgress(uint32 dwCompleted, uint32 dwTotal) mut => VT.[Friend]SetProgress(&this, dwCompleted, dwTotal);

	public HRESULT SetProgress64(uint64 ullCompleted, uint64 ullTotal) mut => VT.[Friend]SetProgress64(&this, ullCompleted, ullTotal);

	public HRESULT SetLine(uint32 dwLineNum, PWSTR pwzString, BOOL fCompactPath, void* pvResevered) mut => VT.[Friend]SetLine(&this, dwLineNum, pwzString, fCompactPath, pvResevered);

	public HRESULT SetCancelMsg(PWSTR pwzCancelMsg, void* pvResevered) mut => VT.[Friend]SetCancelMsg(&this, pwzCancelMsg, pvResevered);

	public HRESULT Timer(uint32 dwTimerAction, void* pvResevered) mut => VT.[Friend]Timer(&this, dwTimerAction, pvResevered);
}

[CRepr]struct IDockingWindowSite : IOleWindow
{
	public new const Guid IID = .(0x2a342fc2, 0x7b26, 0x11d0, 0x8c, 0xa9, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkObj, RECT* prcBorder) GetBorderDW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkObj, RECT* pbw) RequestBorderSpaceDW;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkObj, RECT* pbw) SetBorderSpaceDW;
	}


	public HRESULT GetBorderDW(IUnknown* punkObj, RECT* prcBorder) mut => VT.[Friend]GetBorderDW(&this, punkObj, prcBorder);

	public HRESULT RequestBorderSpaceDW(IUnknown* punkObj, RECT* pbw) mut => VT.[Friend]RequestBorderSpaceDW(&this, punkObj, pbw);

	public HRESULT SetBorderSpaceDW(IUnknown* punkObj, RECT* pbw) mut => VT.[Friend]SetBorderSpaceDW(&this, punkObj, pbw);
}

[CRepr]struct IShellChangeNotify : IUnknown
{
	public new const Guid IID = .(0xd82be2b1, 0x5764, 0x11d0, 0xa9, 0x6e, 0x00, 0xc0, 0x4f, 0xd7, 0x05, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lEvent, ITEMIDLIST* pidl1, ITEMIDLIST* pidl2) OnChange;
	}


	public HRESULT OnChange(int32 lEvent, ITEMIDLIST* pidl1, ITEMIDLIST* pidl2) mut => VT.[Friend]OnChange(&this, lEvent, pidl1, pidl2);
}

[CRepr]struct IQueryInfo : IUnknown
{
	public new const Guid IID = .(0x00021500, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, QITIPF_FLAGS dwFlags, PWSTR* ppwszTip) GetInfoTip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) GetInfoFlags;
	}


	public HRESULT GetInfoTip(QITIPF_FLAGS dwFlags, PWSTR* ppwszTip) mut => VT.[Friend]GetInfoTip(&this, dwFlags, ppwszTip);

	public HRESULT GetInfoFlags(uint32* pdwFlags) mut => VT.[Friend]GetInfoFlags(&this, pdwFlags);
}

[CRepr]struct IShellFolderViewCB : IUnknown
{
	public new const Guid IID = .(0x2047e320, 0xf2a9, 0x11ce, 0xae, 0x65, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SFVM_MESSAGE_ID uMsg, WPARAM wParam, LPARAM lParam) MessageSFVCB;
	}


	public HRESULT MessageSFVCB(SFVM_MESSAGE_ID uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]MessageSFVCB(&this, uMsg, wParam, lParam);
}

[CRepr]struct IShellFolderView : IUnknown
{
	public new const Guid IID = .(0x37a378c0, 0xf82d, 0x11ce, 0xae, 0x65, 0x08, 0x00, 0x2b, 0x2e, 0x12, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM lParamSort) Rearrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM* plParamSort) GetArrangeParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ArrangeGrid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AutoArrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) GetAutoArrange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32* puItem) AddObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl, uint32 uItem) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32* puItem) RemoveObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puCount) GetObjectCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uCount, uint32 dwFlags) SetObjectCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidlOld, ITEMIDLIST* pidlNew, uint32* puItem) UpdateObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32* puItem) RefreshObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bRedraw) SetRedraw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puSelected) GetSelectedCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST*** pppidl, uint32* puItems) GetSelectedObjects;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDropTarget* pDropTarget) IsDropOnSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt) GetDragPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, POINT* ppt) GetDropPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject) MoveIcons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, POINT* ppt) SetItemPos;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDropTarget* pDropTarget) IsBkDropTarget;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL bMove) SetClipboard;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject) SetPoints;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMSPACING* pSpacing) GetItemSpacing;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolderViewCB* pNewCB, IShellFolderViewCB** ppOldCB) SetCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SFVS_SELECT dwFlags) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwSupport) QuerySupport;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch* pdisp) SetAutomationObject;
	}


	public HRESULT Rearrange(LPARAM lParamSort) mut => VT.[Friend]Rearrange(&this, lParamSort);

	public HRESULT GetArrangeParam(LPARAM* plParamSort) mut => VT.[Friend]GetArrangeParam(&this, plParamSort);

	public HRESULT ArrangeGrid() mut => VT.[Friend]ArrangeGrid(&this);

	public HRESULT AutoArrange() mut => VT.[Friend]AutoArrange(&this);

	public HRESULT GetAutoArrange() mut => VT.[Friend]GetAutoArrange(&this);

	public HRESULT AddObject(ITEMIDLIST* pidl, uint32* puItem) mut => VT.[Friend]AddObject(&this, pidl, puItem);

	public HRESULT GetObject(ITEMIDLIST** ppidl, uint32 uItem) mut => VT.[Friend]GetObject(&this, ppidl, uItem);

	public HRESULT RemoveObject(ITEMIDLIST* pidl, uint32* puItem) mut => VT.[Friend]RemoveObject(&this, pidl, puItem);

	public HRESULT GetObjectCount(uint32* puCount) mut => VT.[Friend]GetObjectCount(&this, puCount);

	public HRESULT SetObjectCount(uint32 uCount, uint32 dwFlags) mut => VT.[Friend]SetObjectCount(&this, uCount, dwFlags);

	public HRESULT UpdateObject(ITEMIDLIST* pidlOld, ITEMIDLIST* pidlNew, uint32* puItem) mut => VT.[Friend]UpdateObject(&this, pidlOld, pidlNew, puItem);

	public HRESULT RefreshObject(ITEMIDLIST* pidl, uint32* puItem) mut => VT.[Friend]RefreshObject(&this, pidl, puItem);

	public HRESULT SetRedraw(BOOL bRedraw) mut => VT.[Friend]SetRedraw(&this, bRedraw);

	public HRESULT GetSelectedCount(uint32* puSelected) mut => VT.[Friend]GetSelectedCount(&this, puSelected);

	public HRESULT GetSelectedObjects(ITEMIDLIST*** pppidl, uint32* puItems) mut => VT.[Friend]GetSelectedObjects(&this, pppidl, puItems);

	public HRESULT IsDropOnSource(IDropTarget* pDropTarget) mut => VT.[Friend]IsDropOnSource(&this, pDropTarget);

	public HRESULT GetDragPoint(POINT* ppt) mut => VT.[Friend]GetDragPoint(&this, ppt);

	public HRESULT GetDropPoint(POINT* ppt) mut => VT.[Friend]GetDropPoint(&this, ppt);

	public HRESULT MoveIcons(IDataObject* pDataObject) mut => VT.[Friend]MoveIcons(&this, pDataObject);

	public HRESULT SetItemPos(ITEMIDLIST* pidl, POINT* ppt) mut => VT.[Friend]SetItemPos(&this, pidl, ppt);

	public HRESULT IsBkDropTarget(IDropTarget* pDropTarget) mut => VT.[Friend]IsBkDropTarget(&this, pDropTarget);

	public HRESULT SetClipboard(BOOL bMove) mut => VT.[Friend]SetClipboard(&this, bMove);

	public HRESULT SetPoints(IDataObject* pDataObject) mut => VT.[Friend]SetPoints(&this, pDataObject);

	public HRESULT GetItemSpacing(ITEMSPACING* pSpacing) mut => VT.[Friend]GetItemSpacing(&this, pSpacing);

	public HRESULT SetCallback(IShellFolderViewCB* pNewCB, IShellFolderViewCB** ppOldCB) mut => VT.[Friend]SetCallback(&this, pNewCB, ppOldCB);

	public HRESULT Select(SFVS_SELECT dwFlags) mut => VT.[Friend]Select(&this, dwFlags);

	public HRESULT QuerySupport(uint32* pdwSupport) mut => VT.[Friend]QuerySupport(&this, pdwSupport);

	public HRESULT SetAutomationObject(IDispatch* pdisp) mut => VT.[Friend]SetAutomationObject(&this, pdisp);
}

[CRepr]struct INamedPropertyBag : IUnknown
{
	public new const Guid IID = .(0xfb700430, 0x952c, 0x11d1, 0x94, 0x6f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBagname, PWSTR pszPropName, PROPVARIANT* pVar) ReadPropertyNPB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBagname, PWSTR pszPropName, PROPVARIANT* pVar) WritePropertyNPB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBagname, PWSTR pszPropName) RemovePropertyNPB;
	}


	public HRESULT ReadPropertyNPB(PWSTR pszBagname, PWSTR pszPropName, PROPVARIANT* pVar) mut => VT.[Friend]ReadPropertyNPB(&this, pszBagname, pszPropName, pVar);

	public HRESULT WritePropertyNPB(PWSTR pszBagname, PWSTR pszPropName, PROPVARIANT* pVar) mut => VT.[Friend]WritePropertyNPB(&this, pszBagname, pszPropName, pVar);

	public HRESULT RemovePropertyNPB(PWSTR pszBagname, PWSTR pszPropName) mut => VT.[Friend]RemovePropertyNPB(&this, pszBagname, pszPropName);
}

[CRepr]struct INewShortcutHookA : IUnknown
{
	public new const Guid IID = .(0x000214e1, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pcszReferent, HWND hwnd) SetReferent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszReferent, int32 cchReferent) GetReferent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pcszFolder) SetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszFolder, int32 cchFolder) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszName, int32 cchName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pszExtension, int32 cchExtension) GetExtension;
	}


	public HRESULT SetReferent(PSTR pcszReferent, HWND hwnd) mut => VT.[Friend]SetReferent(&this, pcszReferent, hwnd);

	public HRESULT GetReferent(uint8* pszReferent, int32 cchReferent) mut => VT.[Friend]GetReferent(&this, pszReferent, cchReferent);

	public HRESULT SetFolder(PSTR pcszFolder) mut => VT.[Friend]SetFolder(&this, pcszFolder);

	public HRESULT GetFolder(uint8* pszFolder, int32 cchFolder) mut => VT.[Friend]GetFolder(&this, pszFolder, cchFolder);

	public HRESULT GetName(uint8* pszName, int32 cchName) mut => VT.[Friend]GetName(&this, pszName, cchName);

	public HRESULT GetExtension(uint8* pszExtension, int32 cchExtension) mut => VT.[Friend]GetExtension(&this, pszExtension, cchExtension);
}

[CRepr]struct INewShortcutHookW : IUnknown
{
	public new const Guid IID = .(0x000214f7, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcszReferent, HWND hwnd) SetReferent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszReferent, int32 cchReferent) GetReferent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcszFolder) SetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszFolder, int32 cchFolder) GetFolder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszName, int32 cchName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszExtension, int32 cchExtension) GetExtension;
	}


	public HRESULT SetReferent(PWSTR pcszReferent, HWND hwnd) mut => VT.[Friend]SetReferent(&this, pcszReferent, hwnd);

	public HRESULT GetReferent(char16* pszReferent, int32 cchReferent) mut => VT.[Friend]GetReferent(&this, pszReferent, cchReferent);

	public HRESULT SetFolder(PWSTR pcszFolder) mut => VT.[Friend]SetFolder(&this, pcszFolder);

	public HRESULT GetFolder(char16* pszFolder, int32 cchFolder) mut => VT.[Friend]GetFolder(&this, pszFolder, cchFolder);

	public HRESULT GetName(char16* pszName, int32 cchName) mut => VT.[Friend]GetName(&this, pszName, cchName);

	public HRESULT GetExtension(char16* pszExtension, int32 cchExtension) mut => VT.[Friend]GetExtension(&this, pszExtension, cchExtension);
}

[CRepr]struct ICopyHookA : IUnknown
{
	public new const Guid IID = .(0x000214ef, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, HWND hwnd, uint32 wFunc, uint32 wFlags, PSTR pszSrcFile, uint32 dwSrcAttribs, PSTR pszDestFile, uint32 dwDestAttribs) CopyCallback;
	}


	public uint32 CopyCallback(HWND hwnd, uint32 wFunc, uint32 wFlags, PSTR pszSrcFile, uint32 dwSrcAttribs, PSTR pszDestFile, uint32 dwDestAttribs) mut => VT.[Friend]CopyCallback(&this, hwnd, wFunc, wFlags, pszSrcFile, dwSrcAttribs, pszDestFile, dwDestAttribs);
}

[CRepr]struct ICopyHookW : IUnknown
{
	public new const Guid IID = .(0x000214fc, 0x0000, 0x0000, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, HWND hwnd, uint32 wFunc, uint32 wFlags, PWSTR pszSrcFile, uint32 dwSrcAttribs, PWSTR pszDestFile, uint32 dwDestAttribs) CopyCallback;
	}


	public uint32 CopyCallback(HWND hwnd, uint32 wFunc, uint32 wFlags, PWSTR pszSrcFile, uint32 dwSrcAttribs, PWSTR pszDestFile, uint32 dwDestAttribs) mut => VT.[Friend]CopyCallback(&this, hwnd, wFunc, wFlags, pszSrcFile, dwSrcAttribs, pszDestFile, dwDestAttribs);
}

[CRepr]struct ICurrentWorkingDirectory : IUnknown
{
	public new const Guid IID = .(0x91956d21, 0x9276, 0x11d1, 0x92, 0x1a, 0x00, 0x60, 0x97, 0xdf, 0x5b, 0xd4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pwzPath, uint32 cchSize) GetDirectory;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzPath) SetDirectory;
	}


	public HRESULT GetDirectory(char16* pwzPath, uint32 cchSize) mut => VT.[Friend]GetDirectory(&this, pwzPath, cchSize);

	public HRESULT SetDirectory(PWSTR pwzPath) mut => VT.[Friend]SetDirectory(&this, pwzPath);
}

[CRepr]struct IDockingWindowFrame : IOleWindow
{
	public new const Guid IID = .(0x47d2657a, 0x7b27, 0x11d0, 0x8c, 0xa9, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkSrc, PWSTR pwszItem, uint32 dwAddFlags) AddToolbar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkSrc, uint32 dwRemoveFlags) RemoveToolbar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszItem, in Guid riid, void** ppv) FindToolbar;
	}


	public HRESULT AddToolbar(IUnknown* punkSrc, PWSTR pwszItem, uint32 dwAddFlags) mut => VT.[Friend]AddToolbar(&this, punkSrc, pwszItem, dwAddFlags);

	public HRESULT RemoveToolbar(IUnknown* punkSrc, uint32 dwRemoveFlags) mut => VT.[Friend]RemoveToolbar(&this, punkSrc, dwRemoveFlags);

	public HRESULT FindToolbar(PWSTR pwszItem, in Guid riid, void** ppv) mut => VT.[Friend]FindToolbar(&this, pwszItem, riid, ppv);
}

[CRepr]struct IThumbnailCapture : IUnknown
{
	public new const Guid IID = .(0x4ea39266, 0x7211, 0x409f, 0xb6, 0x22, 0xf6, 0x3d, 0xbd, 0x16, 0xc5, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pMaxSize, IUnknown* pHTMLDoc2, HBITMAP* phbmThumbnail) CaptureThumbnail;
	}


	public HRESULT CaptureThumbnail(SIZE* pMaxSize, IUnknown* pHTMLDoc2, HBITMAP* phbmThumbnail) mut => VT.[Friend]CaptureThumbnail(&this, pMaxSize, pHTMLDoc2, phbmThumbnail);
}

[CRepr]struct IShellFolderBand : IUnknown
{
	public new const Guid IID = .(0x7fe80cc8, 0xc247, 0x11d0, 0xb9, 0x3a, 0x00, 0xa0, 0xc9, 0x03, 0x12, 0xe1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellFolder* psf, ITEMIDLIST* pidl) InitializeSFB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BANDINFOSFB* pbi) SetBandInfoSFB;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BANDINFOSFB* pbi) GetBandInfoSFB;
	}


	public HRESULT InitializeSFB(IShellFolder* psf, ITEMIDLIST* pidl) mut => VT.[Friend]InitializeSFB(&this, psf, pidl);

	public HRESULT SetBandInfoSFB(BANDINFOSFB* pbi) mut => VT.[Friend]SetBandInfoSFB(&this, pbi);

	public HRESULT GetBandInfoSFB(BANDINFOSFB* pbi) mut => VT.[Friend]GetBandInfoSFB(&this, pbi);
}

[CRepr]struct IDeskBarClient : IOleWindow
{
	public new const Guid IID = .(0xeb0fe175, 0x1a3a, 0x11d0, 0x89, 0xb3, 0x00, 0xa0, 0xc9, 0x0a, 0x90, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IOleWindow.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkSite) SetDeskBarSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode) SetModeDBC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwState) UIActivateDBC;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWhich, RECT* prc) GetSize;
	}


	public HRESULT SetDeskBarSite(IUnknown* punkSite) mut => VT.[Friend]SetDeskBarSite(&this, punkSite);

	public HRESULT SetModeDBC(uint32 dwMode) mut => VT.[Friend]SetModeDBC(&this, dwMode);

	public HRESULT UIActivateDBC(uint32 dwState) mut => VT.[Friend]UIActivateDBC(&this, dwState);

	public HRESULT GetSize(uint32 dwWhich, RECT* prc) mut => VT.[Friend]GetSize(&this, dwWhich, prc);
}

[CRepr]struct IColumnProvider : IUnknown
{
	public new const Guid IID = .(0xe8025004, 0x1c42, 0x11d2, 0xbe, 0x2c, 0x00, 0xa0, 0xc9, 0xa8, 0x3d, 0xa1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SHCOLUMNINIT* psci) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, SHCOLUMNINFO* psci) GetColumnInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* pscid, SHCOLUMNDATA* pscd, VARIANT* pvarData) GetItemData;
	}


	public HRESULT Initialize(SHCOLUMNINIT* psci) mut => VT.[Friend]Initialize(&this, psci);

	public HRESULT GetColumnInfo(uint32 dwIndex, SHCOLUMNINFO* psci) mut => VT.[Friend]GetColumnInfo(&this, dwIndex, psci);

	public HRESULT GetItemData(PROPERTYKEY* pscid, SHCOLUMNDATA* pscd, VARIANT* pvarData) mut => VT.[Friend]GetItemData(&this, pscid, pscd, pvarData);
}

[CRepr]struct IDocViewSite : IUnknown
{
	public new const Guid IID = .(0x87d605e0, 0xc511, 0x11cf, 0x89, 0xa9, 0x00, 0xa0, 0xc9, 0x05, 0x41, 0x29);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvTitle) OnSetTitle;
	}


	public HRESULT OnSetTitle(VARIANT* pvTitle) mut => VT.[Friend]OnSetTitle(&this, pvTitle);
}

[CRepr]struct IInitializeObject : IUnknown
{
	public new const Guid IID = .(0x4622ad16, 0xff23, 0x11d0, 0x8d, 0x34, 0x00, 0xa0, 0xc9, 0x0f, 0x27, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Initialize;
	}


	public HRESULT Initialize() mut => VT.[Friend]Initialize(&this);
}

[CRepr]struct IBanneredBar : IUnknown
{
	public new const Guid IID = .(0x596a9a94, 0x013e, 0x11d1, 0x8d, 0x34, 0x00, 0xa0, 0xc9, 0x0f, 0x27, 0x19);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIcon) SetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* piIcon) GetIconSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hBitmap) SetBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* phBitmap) GetBitmap;
	}


	public HRESULT SetIconSize(uint32 iIcon) mut => VT.[Friend]SetIconSize(&this, iIcon);

	public HRESULT GetIconSize(uint32* piIcon) mut => VT.[Friend]GetIconSize(&this, piIcon);

	public HRESULT SetBitmap(HBITMAP hBitmap) mut => VT.[Friend]SetBitmap(&this, hBitmap);

	public HRESULT GetBitmap(HBITMAP* phBitmap) mut => VT.[Friend]GetBitmap(&this, phBitmap);
}

[CRepr]struct IQueryAssociations : IUnknown
{
	public new const Guid IID = .(0xc46ca590, 0x3c3f, 0x11d2, 0xbe, 0xe6, 0x00, 0x00, 0xf8, 0x05, 0xca, 0x57);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, PWSTR pszAssoc, HKEY hkProgid, HWND hwnd) Init;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, ASSOCSTR str, PWSTR pszExtra, char16* pszOut, uint32* pcchOut) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, ASSOCKEY key, PWSTR pszExtra, HKEY* phkeyOut) GetKey;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, ASSOCDATA data, PWSTR pszExtra, void* pvOut, uint32* pcbOut) GetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 flags, ASSOCENUM assocenum, PWSTR pszExtra, in Guid riid, void** ppvOut) GetEnum;
	}


	public HRESULT Init(uint32 flags, PWSTR pszAssoc, HKEY hkProgid, HWND hwnd) mut => VT.[Friend]Init(&this, flags, pszAssoc, hkProgid, hwnd);

	public HRESULT GetString(uint32 flags, ASSOCSTR str, PWSTR pszExtra, char16* pszOut, uint32* pcchOut) mut => VT.[Friend]GetString(&this, flags, str, pszExtra, pszOut, pcchOut);

	public HRESULT GetKey(uint32 flags, ASSOCKEY key, PWSTR pszExtra, HKEY* phkeyOut) mut => VT.[Friend]GetKey(&this, flags, key, pszExtra, phkeyOut);

	public HRESULT GetData(uint32 flags, ASSOCDATA data, PWSTR pszExtra, void* pvOut, uint32* pcbOut) mut => VT.[Friend]GetData(&this, flags, data, pszExtra, pvOut, pcbOut);

	public HRESULT GetEnum(uint32 flags, ASSOCENUM assocenum, PWSTR pszExtra, in Guid riid, void** ppvOut) mut => VT.[Friend]GetEnum(&this, flags, assocenum, pszExtra, riid, ppvOut);
}

[CRepr]struct IShellApp : IUnknown
{
	public new const Guid IID = .(0xa3e14960, 0x935f, 0x11d1, 0xb8, 0xb8, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPINFODATA* pai) GetAppInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwActions) GetPossibleActions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SLOWAPPINFO* psaid) GetSlowAppInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SLOWAPPINFO* psaid) GetCachedSlowAppInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsInstalled;
	}


	public HRESULT GetAppInfo(APPINFODATA* pai) mut => VT.[Friend]GetAppInfo(&this, pai);

	public HRESULT GetPossibleActions(uint32* pdwActions) mut => VT.[Friend]GetPossibleActions(&this, pdwActions);

	public HRESULT GetSlowAppInfo(SLOWAPPINFO* psaid) mut => VT.[Friend]GetSlowAppInfo(&this, psaid);

	public HRESULT GetCachedSlowAppInfo(SLOWAPPINFO* psaid) mut => VT.[Friend]GetCachedSlowAppInfo(&this, psaid);

	public HRESULT IsInstalled() mut => VT.[Friend]IsInstalled(&this);
}

[CRepr]struct IPublishedApp : IShellApp
{
	public new const Guid IID = .(0x1bc752e0, 0x9046, 0x11d1, 0xb8, 0xb3, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellApp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstInstall) Install;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PUBAPPINFO* ppai) GetPublishedAppInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unschedule;
	}


	public HRESULT Install(SYSTEMTIME* pstInstall) mut => VT.[Friend]Install(&this, pstInstall);

	public HRESULT GetPublishedAppInfo(PUBAPPINFO* ppai) mut => VT.[Friend]GetPublishedAppInfo(&this, ppai);

	public HRESULT Unschedule() mut => VT.[Friend]Unschedule(&this);
}

[CRepr]struct IPublishedApp2 : IPublishedApp
{
	public new const Guid IID = .(0x12b81347, 0x1b3a, 0x4a04, 0xaa, 0x61, 0x3f, 0x76, 0x8b, 0x67, 0xfd, 0x7e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IPublishedApp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYSTEMTIME* pstInstall, HWND hwndParent) Install2;
	}


	public HRESULT Install2(SYSTEMTIME* pstInstall, HWND hwndParent) mut => VT.[Friend]Install2(&this, pstInstall, hwndParent);
}

[CRepr]struct IEnumPublishedApps : IUnknown
{
	public new const Guid IID = .(0x0b124f8c, 0x91f0, 0x11d1, 0xb8, 0xb5, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPublishedApp** pia) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
	}


	public HRESULT Next(IPublishedApp** pia) mut => VT.[Friend]Next(&this, pia);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);
}

[CRepr]struct IAppPublisher : IUnknown
{
	public new const Guid IID = .(0x07250a10, 0x9cf9, 0x11d1, 0x90, 0x76, 0x00, 0x60, 0x08, 0x05, 0x93, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCat) GetNumberOfCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, APPCATEGORYINFOLIST* pAppCategoryList) GetCategories;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwApps) GetNumberOfApps;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pAppCategoryId, IEnumPublishedApps** ppepa) EnumApps;
	}


	public HRESULT GetNumberOfCategories(uint32* pdwCat) mut => VT.[Friend]GetNumberOfCategories(&this, pdwCat);

	public HRESULT GetCategories(APPCATEGORYINFOLIST* pAppCategoryList) mut => VT.[Friend]GetCategories(&this, pAppCategoryList);

	public HRESULT GetNumberOfApps(uint32* pdwApps) mut => VT.[Friend]GetNumberOfApps(&this, pdwApps);

	public HRESULT EnumApps(Guid* pAppCategoryId, IEnumPublishedApps** ppepa) mut => VT.[Friend]EnumApps(&this, pAppCategoryId, ppepa);
}

[CRepr]struct ICredentialProviderCredential : IUnknown
{
	public new const Guid IID = .(0x63913a93, 0x40c1, 0x481a, 0x81, 0x8d, 0x40, 0x72, 0xff, 0x8c, 0x70, 0xcc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredentialEvents* pcpce) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pbAutoLogon) SetSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetDeselected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_STATE* pcpfs, CREDENTIAL_PROVIDER_FIELD_INTERACTIVE_STATE* pcpfis) GetFieldState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, PWSTR* ppsz) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, HBITMAP* phbmp) GetBitmapValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, BOOL* pbChecked, PWSTR* ppszLabel) GetCheckboxValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, uint32* pdwAdjacentTo) GetSubmitButtonValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, uint32* pcItems, uint32* pdwSelectedItem) GetComboBoxValueCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, uint32 dwItem, PWSTR* ppszItem) GetComboBoxValueAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, PWSTR psz) SetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, BOOL bChecked) SetCheckboxValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID, uint32 dwSelectedItem) SetComboBoxSelectedValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFieldID) CommandLinkClicked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_GET_SERIALIZATION_RESPONSE* pcpgsr, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcs, PWSTR* ppszOptionalStatusText, CREDENTIAL_PROVIDER_STATUS_ICON* pcpsiOptionalStatusIcon) GetSerialization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, NTSTATUS ntsStatus, NTSTATUS ntsSubstatus, PWSTR* ppszOptionalStatusText, CREDENTIAL_PROVIDER_STATUS_ICON* pcpsiOptionalStatusIcon) ReportResult;
	}


	public HRESULT Advise(ICredentialProviderCredentialEvents* pcpce) mut => VT.[Friend]Advise(&this, pcpce);

	public HRESULT UnAdvise() mut => VT.[Friend]UnAdvise(&this);

	public HRESULT SetSelected(BOOL* pbAutoLogon) mut => VT.[Friend]SetSelected(&this, pbAutoLogon);

	public HRESULT SetDeselected() mut => VT.[Friend]SetDeselected(&this);

	public HRESULT GetFieldState(uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_STATE* pcpfs, CREDENTIAL_PROVIDER_FIELD_INTERACTIVE_STATE* pcpfis) mut => VT.[Friend]GetFieldState(&this, dwFieldID, pcpfs, pcpfis);

	public HRESULT GetStringValue(uint32 dwFieldID, PWSTR* ppsz) mut => VT.[Friend]GetStringValue(&this, dwFieldID, ppsz);

	public HRESULT GetBitmapValue(uint32 dwFieldID, HBITMAP* phbmp) mut => VT.[Friend]GetBitmapValue(&this, dwFieldID, phbmp);

	public HRESULT GetCheckboxValue(uint32 dwFieldID, BOOL* pbChecked, PWSTR* ppszLabel) mut => VT.[Friend]GetCheckboxValue(&this, dwFieldID, pbChecked, ppszLabel);

	public HRESULT GetSubmitButtonValue(uint32 dwFieldID, uint32* pdwAdjacentTo) mut => VT.[Friend]GetSubmitButtonValue(&this, dwFieldID, pdwAdjacentTo);

	public HRESULT GetComboBoxValueCount(uint32 dwFieldID, uint32* pcItems, uint32* pdwSelectedItem) mut => VT.[Friend]GetComboBoxValueCount(&this, dwFieldID, pcItems, pdwSelectedItem);

	public HRESULT GetComboBoxValueAt(uint32 dwFieldID, uint32 dwItem, PWSTR* ppszItem) mut => VT.[Friend]GetComboBoxValueAt(&this, dwFieldID, dwItem, ppszItem);

	public HRESULT SetStringValue(uint32 dwFieldID, PWSTR psz) mut => VT.[Friend]SetStringValue(&this, dwFieldID, psz);

	public HRESULT SetCheckboxValue(uint32 dwFieldID, BOOL bChecked) mut => VT.[Friend]SetCheckboxValue(&this, dwFieldID, bChecked);

	public HRESULT SetComboBoxSelectedValue(uint32 dwFieldID, uint32 dwSelectedItem) mut => VT.[Friend]SetComboBoxSelectedValue(&this, dwFieldID, dwSelectedItem);

	public HRESULT CommandLinkClicked(uint32 dwFieldID) mut => VT.[Friend]CommandLinkClicked(&this, dwFieldID);

	public HRESULT GetSerialization(CREDENTIAL_PROVIDER_GET_SERIALIZATION_RESPONSE* pcpgsr, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcs, PWSTR* ppszOptionalStatusText, CREDENTIAL_PROVIDER_STATUS_ICON* pcpsiOptionalStatusIcon) mut => VT.[Friend]GetSerialization(&this, pcpgsr, pcpcs, ppszOptionalStatusText, pcpsiOptionalStatusIcon);

	public HRESULT ReportResult(NTSTATUS ntsStatus, NTSTATUS ntsSubstatus, PWSTR* ppszOptionalStatusText, CREDENTIAL_PROVIDER_STATUS_ICON* pcpsiOptionalStatusIcon) mut => VT.[Friend]ReportResult(&this, ntsStatus, ntsSubstatus, ppszOptionalStatusText, pcpsiOptionalStatusIcon);
}

[CRepr]struct IQueryContinueWithStatus : IQueryContinue
{
	public new const Guid IID = .(0x9090be5b, 0x502b, 0x41fb, 0xbc, 0xcc, 0x00, 0x49, 0xa6, 0xc7, 0x25, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IQueryContinue.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR psz) SetStatusMessage;
	}


	public HRESULT SetStatusMessage(PWSTR psz) mut => VT.[Friend]SetStatusMessage(&this, psz);
}

[CRepr]struct IConnectableCredentialProviderCredential : ICredentialProviderCredential
{
	public new const Guid IID = .(0x9387928b, 0xac75, 0x4bf9, 0x8a, 0xb2, 0x2b, 0x93, 0xc4, 0xa5, 0x52, 0x90);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICredentialProviderCredential.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IQueryContinueWithStatus* pqcws) Connect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
	}


	public HRESULT Connect(IQueryContinueWithStatus* pqcws) mut => VT.[Friend]Connect(&this, pqcws);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);
}

[CRepr]struct ICredentialProviderCredentialEvents : IUnknown
{
	public new const Guid IID = .(0xfa6fa76b, 0x66b7, 0x4b11, 0x95, 0xf1, 0x86, 0x17, 0x11, 0x18, 0xe8, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_STATE cpfs) SetFieldState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_INTERACTIVE_STATE cpfis) SetFieldInteractiveState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, PWSTR psz) SetFieldString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, BOOL bChecked, PWSTR pszLabel) SetFieldCheckbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, HBITMAP hbmp) SetFieldBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwSelectedItem) SetFieldComboBoxSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwItem) DeleteFieldComboBoxItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, PWSTR pszItem) AppendFieldComboBoxItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwAdjacentTo) SetFieldSubmitButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwndOwner) OnCreatingWindow;
	}


	public HRESULT SetFieldState(ICredentialProviderCredential* pcpc, uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_STATE cpfs) mut => VT.[Friend]SetFieldState(&this, pcpc, dwFieldID, cpfs);

	public HRESULT SetFieldInteractiveState(ICredentialProviderCredential* pcpc, uint32 dwFieldID, CREDENTIAL_PROVIDER_FIELD_INTERACTIVE_STATE cpfis) mut => VT.[Friend]SetFieldInteractiveState(&this, pcpc, dwFieldID, cpfis);

	public HRESULT SetFieldString(ICredentialProviderCredential* pcpc, uint32 dwFieldID, PWSTR psz) mut => VT.[Friend]SetFieldString(&this, pcpc, dwFieldID, psz);

	public HRESULT SetFieldCheckbox(ICredentialProviderCredential* pcpc, uint32 dwFieldID, BOOL bChecked, PWSTR pszLabel) mut => VT.[Friend]SetFieldCheckbox(&this, pcpc, dwFieldID, bChecked, pszLabel);

	public HRESULT SetFieldBitmap(ICredentialProviderCredential* pcpc, uint32 dwFieldID, HBITMAP hbmp) mut => VT.[Friend]SetFieldBitmap(&this, pcpc, dwFieldID, hbmp);

	public HRESULT SetFieldComboBoxSelectedItem(ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwSelectedItem) mut => VT.[Friend]SetFieldComboBoxSelectedItem(&this, pcpc, dwFieldID, dwSelectedItem);

	public HRESULT DeleteFieldComboBoxItem(ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwItem) mut => VT.[Friend]DeleteFieldComboBoxItem(&this, pcpc, dwFieldID, dwItem);

	public HRESULT AppendFieldComboBoxItem(ICredentialProviderCredential* pcpc, uint32 dwFieldID, PWSTR pszItem) mut => VT.[Friend]AppendFieldComboBoxItem(&this, pcpc, dwFieldID, pszItem);

	public HRESULT SetFieldSubmitButton(ICredentialProviderCredential* pcpc, uint32 dwFieldID, uint32 dwAdjacentTo) mut => VT.[Friend]SetFieldSubmitButton(&this, pcpc, dwFieldID, dwAdjacentTo);

	public HRESULT OnCreatingWindow(HWND* phwndOwner) mut => VT.[Friend]OnCreatingWindow(&this, phwndOwner);
}

[CRepr]struct ICredentialProvider : IUnknown
{
	public new const Guid IID = .(0xd27c3481, 0x5a1c, 0x45b2, 0x8a, 0xaa, 0xc2, 0x0e, 0xbb, 0xe8, 0x22, 0x9e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_USAGE_SCENARIO cpus, uint32 dwFlags) SetUsageScenario;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcs) SetSerialization;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderEvents* pcpe, uint upAdviseContext) Advise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UnAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount) GetFieldDescriptorCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, CREDENTIAL_PROVIDER_FIELD_DESCRIPTOR** ppcpfd) GetFieldDescriptorAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwCount, uint32* pdwDefault, BOOL* pbAutoLogonWithDefault) GetCredentialCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwIndex, ICredentialProviderCredential** ppcpc) GetCredentialAt;
	}


	public HRESULT SetUsageScenario(CREDENTIAL_PROVIDER_USAGE_SCENARIO cpus, uint32 dwFlags) mut => VT.[Friend]SetUsageScenario(&this, cpus, dwFlags);

	public HRESULT SetSerialization(CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcs) mut => VT.[Friend]SetSerialization(&this, pcpcs);

	public HRESULT Advise(ICredentialProviderEvents* pcpe, uint upAdviseContext) mut => VT.[Friend]Advise(&this, pcpe, upAdviseContext);

	public HRESULT UnAdvise() mut => VT.[Friend]UnAdvise(&this);

	public HRESULT GetFieldDescriptorCount(uint32* pdwCount) mut => VT.[Friend]GetFieldDescriptorCount(&this, pdwCount);

	public HRESULT GetFieldDescriptorAt(uint32 dwIndex, CREDENTIAL_PROVIDER_FIELD_DESCRIPTOR** ppcpfd) mut => VT.[Friend]GetFieldDescriptorAt(&this, dwIndex, ppcpfd);

	public HRESULT GetCredentialCount(uint32* pdwCount, uint32* pdwDefault, BOOL* pbAutoLogonWithDefault) mut => VT.[Friend]GetCredentialCount(&this, pdwCount, pdwDefault, pbAutoLogonWithDefault);

	public HRESULT GetCredentialAt(uint32 dwIndex, ICredentialProviderCredential** ppcpc) mut => VT.[Friend]GetCredentialAt(&this, dwIndex, ppcpc);
}

[CRepr]struct ICredentialProviderEvents : IUnknown
{
	public new const Guid IID = .(0x34201e5a, 0xa787, 0x41a3, 0xa5, 0xa4, 0xbd, 0x6d, 0xcf, 0x2a, 0x85, 0x4e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint upAdviseContext) CredentialsChanged;
	}


	public HRESULT CredentialsChanged(uint upAdviseContext) mut => VT.[Friend]CredentialsChanged(&this, upAdviseContext);
}

[CRepr]struct ICredentialProviderFilter : IUnknown
{
	public new const Guid IID = .(0xa5da53f9, 0xd475, 0x4080, 0xa1, 0x20, 0x91, 0x0c, 0x4a, 0x73, 0x98, 0x80);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_USAGE_SCENARIO cpus, uint32 dwFlags, Guid* rgclsidProviders, BOOL* rgbAllow, uint32 cProviders) Filter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcsIn, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcsOut) UpdateRemoteCredential;
	}


	public HRESULT Filter(CREDENTIAL_PROVIDER_USAGE_SCENARIO cpus, uint32 dwFlags, Guid* rgclsidProviders, BOOL* rgbAllow, uint32 cProviders) mut => VT.[Friend]Filter(&this, cpus, dwFlags, rgclsidProviders, rgbAllow, cProviders);

	public HRESULT UpdateRemoteCredential(CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcsIn, CREDENTIAL_PROVIDER_CREDENTIAL_SERIALIZATION* pcpcsOut) mut => VT.[Friend]UpdateRemoteCredential(&this, pcpcsIn, pcpcsOut);
}

[CRepr]struct ICredentialProviderCredential2 : ICredentialProviderCredential
{
	public new const Guid IID = .(0xfd672c54, 0x40ea, 0x4d6e, 0x9b, 0x49, 0xcf, 0xb1, 0xa7, 0x50, 0x7b, 0xd7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICredentialProviderCredential.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sid) GetUserSid;
	}


	public HRESULT GetUserSid(PWSTR* sid) mut => VT.[Friend]GetUserSid(&this, sid);
}

[CRepr]struct ICredentialProviderCredentialWithFieldOptions : IUnknown
{
	public new const Guid IID = .(0xdbc6fb30, 0xc843, 0x49e3, 0xa6, 0x45, 0x57, 0x3e, 0x6f, 0x39, 0x44, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 fieldID, CREDENTIAL_PROVIDER_CREDENTIAL_FIELD_OPTIONS* options) GetFieldOptions;
	}


	public HRESULT GetFieldOptions(uint32 fieldID, CREDENTIAL_PROVIDER_CREDENTIAL_FIELD_OPTIONS* options) mut => VT.[Friend]GetFieldOptions(&this, fieldID, options);
}

[CRepr]struct ICredentialProviderCredentialEvents2 : ICredentialProviderCredentialEvents
{
	public new const Guid IID = .(0xb53c00b6, 0x9922, 0x4b78, 0xb1, 0xf4, 0xdd, 0xfe, 0x77, 0x4d, 0xc3, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ICredentialProviderCredentialEvents.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) BeginFieldUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EndFieldUpdates;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderCredential* credential, uint32 fieldID, CREDENTIAL_PROVIDER_CREDENTIAL_FIELD_OPTIONS options) SetFieldOptions;
	}


	public HRESULT BeginFieldUpdates() mut => VT.[Friend]BeginFieldUpdates(&this);

	public HRESULT EndFieldUpdates() mut => VT.[Friend]EndFieldUpdates(&this);

	public HRESULT SetFieldOptions(ICredentialProviderCredential* credential, uint32 fieldID, CREDENTIAL_PROVIDER_CREDENTIAL_FIELD_OPTIONS options) mut => VT.[Friend]SetFieldOptions(&this, credential, fieldID, options);
}

[CRepr]struct ICredentialProviderUser : IUnknown
{
	public new const Guid IID = .(0x13793285, 0x3ea6, 0x40fd, 0xb4, 0x20, 0x15, 0xf4, 0x7d, 0xa4, 0x1f, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* sid) GetSid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* providerID) GetProviderID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PWSTR* stringValue) GetStringValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* value) GetValue;
	}


	public HRESULT GetSid(PWSTR* sid) mut => VT.[Friend]GetSid(&this, sid);

	public HRESULT GetProviderID(Guid* providerID) mut => VT.[Friend]GetProviderID(&this, providerID);

	public HRESULT GetStringValue(PROPERTYKEY* key, PWSTR* stringValue) mut => VT.[Friend]GetStringValue(&this, key, stringValue);

	public HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* value) mut => VT.[Friend]GetValue(&this, key, value);
}

[CRepr]struct ICredentialProviderUserArray : IUnknown
{
	public new const Guid IID = .(0x90c119ae, 0x0f18, 0x4520, 0xa1, 0xf1, 0x11, 0x43, 0x66, 0xa4, 0x0f, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid guidProviderToFilterTo) SetProviderFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREDENTIAL_PROVIDER_ACCOUNT_OPTIONS* credentialProviderAccountOptions) GetAccountOptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* userCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 userIndex, ICredentialProviderUser** user) GetAt;
	}


	public HRESULT SetProviderFilter(in Guid guidProviderToFilterTo) mut => VT.[Friend]SetProviderFilter(&this, guidProviderToFilterTo);

	public HRESULT GetAccountOptions(CREDENTIAL_PROVIDER_ACCOUNT_OPTIONS* credentialProviderAccountOptions) mut => VT.[Friend]GetAccountOptions(&this, credentialProviderAccountOptions);

	public HRESULT GetCount(uint32* userCount) mut => VT.[Friend]GetCount(&this, userCount);

	public HRESULT GetAt(uint32 userIndex, ICredentialProviderUser** user) mut => VT.[Friend]GetAt(&this, userIndex, user);
}

[CRepr]struct ICredentialProviderSetUserArray : IUnknown
{
	public new const Guid IID = .(0x095c1484, 0x1c0c, 0x4388, 0x9c, 0x6d, 0x50, 0x0e, 0x61, 0xbf, 0x84, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ICredentialProviderUserArray* users) SetUserArray;
	}


	public HRESULT SetUserArray(ICredentialProviderUserArray* users) mut => VT.[Friend]SetUserArray(&this, users);
}

[CRepr]struct ISyncMgrHandlerCollection : IUnknown
{
	public new const Guid IID = .(0xa7f337a3, 0xd20b, 0x45cb, 0x9e, 0xd7, 0x87, 0xd0, 0x94, 0xca, 0x50, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppenum) GetHandlerEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, in Guid riid, void** ppv) BindToHandler;
	}


	public HRESULT GetHandlerEnumerator(IEnumString** ppenum) mut => VT.[Friend]GetHandlerEnumerator(&this, ppenum);

	public HRESULT BindToHandler(PWSTR pszHandlerID, in Guid riid, void** ppv) mut => VT.[Friend]BindToHandler(&this, pszHandlerID, riid, ppv);
}

[CRepr]struct ISyncMgrHandler : IUnknown
{
	public new const Guid IID = .(0x04ec2e43, 0xac77, 0x49f9, 0x9b, 0x98, 0x03, 0x07, 0xef, 0x7a, 0x72, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrHandlerInfo** ppHandlerInfo) GetHandlerInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidObjectID, in Guid riid, void** ppv) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_HANDLER_CAPABILITIES* pmCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_HANDLER_POLICIES* pmPolicies) GetPolicies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActivate) Activate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszItemIDs, uint32 cItems, HWND hwndOwner, ISyncMgrSessionCreator* pSessionCreator, IUnknown* punk) Synchronize;
	}


	public HRESULT GetName(PWSTR* ppszName) mut => VT.[Friend]GetName(&this, ppszName);

	public HRESULT GetHandlerInfo(ISyncMgrHandlerInfo** ppHandlerInfo) mut => VT.[Friend]GetHandlerInfo(&this, ppHandlerInfo);

	public HRESULT GetObject(in Guid rguidObjectID, in Guid riid, void** ppv) mut => VT.[Friend]GetObject(&this, rguidObjectID, riid, ppv);

	public HRESULT GetCapabilities(SYNCMGR_HANDLER_CAPABILITIES* pmCapabilities) mut => VT.[Friend]GetCapabilities(&this, pmCapabilities);

	public HRESULT GetPolicies(SYNCMGR_HANDLER_POLICIES* pmPolicies) mut => VT.[Friend]GetPolicies(&this, pmPolicies);

	public HRESULT Activate(BOOL fActivate) mut => VT.[Friend]Activate(&this, fActivate);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);

	public HRESULT Synchronize(PWSTR* ppszItemIDs, uint32 cItems, HWND hwndOwner, ISyncMgrSessionCreator* pSessionCreator, IUnknown* punk) mut => VT.[Friend]Synchronize(&this, ppszItemIDs, cItems, hwndOwner, pSessionCreator, punk);
}

[CRepr]struct ISyncMgrHandlerInfo : IUnknown
{
	public new const Guid IID = .(0x4ff1d798, 0xecf7, 0x4524, 0xaa, 0x81, 0x1e, 0x36, 0x2a, 0x0a, 0xef, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_HANDLER_TYPE* pnType) COM_GetType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTypeLabel) GetTypeLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszComment) GetComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftLastSync) GetLastSyncTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsActive;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsConnected;
	}


	public HRESULT GetType(SYNCMGR_HANDLER_TYPE* pnType) mut => VT.[Friend]COM_GetType(&this, pnType);

	public HRESULT GetTypeLabel(PWSTR* ppszTypeLabel) mut => VT.[Friend]GetTypeLabel(&this, ppszTypeLabel);

	public HRESULT GetComment(PWSTR* ppszComment) mut => VT.[Friend]GetComment(&this, ppszComment);

	public HRESULT GetLastSyncTime(FILETIME* pftLastSync) mut => VT.[Friend]GetLastSyncTime(&this, pftLastSync);

	public HRESULT IsActive() mut => VT.[Friend]IsActive(&this);

	public HRESULT IsEnabled() mut => VT.[Friend]IsEnabled(&this);

	public HRESULT IsConnected() mut => VT.[Friend]IsConnected(&this);
}

[CRepr]struct ISyncMgrSyncItemContainer : IUnknown
{
	public new const Guid IID = .(0x90701133, 0xbe32, 0x4129, 0xa6, 0x5c, 0x99, 0xe6, 0x16, 0xca, 0xff, 0xf4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID, ISyncMgrSyncItem** ppItem) GetSyncItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncMgrSyncItems** ppenum) GetSyncItemEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcItems) GetSyncItemCount;
	}


	public HRESULT GetSyncItem(PWSTR pszItemID, ISyncMgrSyncItem** ppItem) mut => VT.[Friend]GetSyncItem(&this, pszItemID, ppItem);

	public HRESULT GetSyncItemEnumerator(IEnumSyncMgrSyncItems** ppenum) mut => VT.[Friend]GetSyncItemEnumerator(&this, ppenum);

	public HRESULT GetSyncItemCount(uint32* pcItems) mut => VT.[Friend]GetSyncItemCount(&this, pcItems);
}

[CRepr]struct ISyncMgrSyncItem : IUnknown
{
	public new const Guid IID = .(0xb20b24ce, 0x2593, 0x4f04, 0xbd, 0x8b, 0x7a, 0xd6, 0xc4, 0x50, 0x51, 0xcd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszItemID) GetItemID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrSyncItemInfo** ppItemInfo) GetItemInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidObjectID, in Guid riid, void** ppv) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_ITEM_CAPABILITIES* pmCapabilities) GetCapabilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_ITEM_POLICIES* pmPolicies) GetPolicies;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) Enable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
	}


	public HRESULT GetItemID(PWSTR* ppszItemID) mut => VT.[Friend]GetItemID(&this, ppszItemID);

	public HRESULT GetName(PWSTR* ppszName) mut => VT.[Friend]GetName(&this, ppszName);

	public HRESULT GetItemInfo(ISyncMgrSyncItemInfo** ppItemInfo) mut => VT.[Friend]GetItemInfo(&this, ppItemInfo);

	public HRESULT GetObject(in Guid rguidObjectID, in Guid riid, void** ppv) mut => VT.[Friend]GetObject(&this, rguidObjectID, riid, ppv);

	public HRESULT GetCapabilities(SYNCMGR_ITEM_CAPABILITIES* pmCapabilities) mut => VT.[Friend]GetCapabilities(&this, pmCapabilities);

	public HRESULT GetPolicies(SYNCMGR_ITEM_POLICIES* pmPolicies) mut => VT.[Friend]GetPolicies(&this, pmPolicies);

	public HRESULT Enable(BOOL fEnable) mut => VT.[Friend]Enable(&this, fEnable);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);
}

[CRepr]struct ISyncMgrSyncItemInfo : IUnknown
{
	public new const Guid IID = .(0xe7fd9502, 0xbe0c, 0x4464, 0x90, 0xa1, 0x2b, 0x52, 0x77, 0x03, 0x12, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTypeLabel) GetTypeLabel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszComment) GetComment;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftLastSync) GetLastSyncTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsEnabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsConnected;
	}


	public HRESULT GetTypeLabel(PWSTR* ppszTypeLabel) mut => VT.[Friend]GetTypeLabel(&this, ppszTypeLabel);

	public HRESULT GetComment(PWSTR* ppszComment) mut => VT.[Friend]GetComment(&this, ppszComment);

	public HRESULT GetLastSyncTime(FILETIME* pftLastSync) mut => VT.[Friend]GetLastSyncTime(&this, pftLastSync);

	public HRESULT IsEnabled() mut => VT.[Friend]IsEnabled(&this);

	public HRESULT IsConnected() mut => VT.[Friend]IsConnected(&this);
}

[CRepr]struct IEnumSyncMgrSyncItems : IUnknown
{
	public new const Guid IID = .(0x54b3abf3, 0xf085, 0x4181, 0xb5, 0x46, 0xe2, 0x9c, 0x40, 0x3c, 0x72, 0x6b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISyncMgrSyncItem** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncMgrSyncItems** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ISyncMgrSyncItem** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncMgrSyncItems** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISyncMgrSessionCreator : IUnknown
{
	public new const Guid IID = .(0x17f48517, 0xf305, 0x4321, 0xa0, 0x8d, 0xb2, 0x5a, 0x83, 0x49, 0x18, 0xfd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems, ISyncMgrSyncCallback** ppCallback) CreateSession;
	}


	public HRESULT CreateSession(PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems, ISyncMgrSyncCallback** ppCallback) mut => VT.[Friend]CreateSession(&this, pszHandlerID, ppszItemIDs, cItems, ppCallback);
}

[CRepr]struct ISyncMgrSyncCallback : IUnknown
{
	public new const Guid IID = .(0x884ccd87, 0xb139, 0x4937, 0xa4, 0xba, 0x4f, 0x8e, 0x19, 0x51, 0x3f, 0xbe);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID, PWSTR pszProgressText, SYNCMGR_PROGRESS_STATUS nStatus, uint32 uCurrentStep, uint32 uMaxStep, SYNCMGR_CANCEL_REQUEST* pnCancelRequest) ReportProgress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszProgressText, SYNCMGR_CANCEL_REQUEST* pnCancelRequest) SetHandlerProgressText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID, SYNCMGR_EVENT_LEVEL nLevel, SYNCMGR_EVENT_FLAGS nFlags, PWSTR pszName, PWSTR pszDescription, PWSTR pszLinkText, PWSTR pszLinkReference, PWSTR pszContext, Guid* pguidEventID) ReportEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID) CanContinue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppenumItemIDs, IEnumUnknown** ppenumPunks) QueryForAdditionalItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID) AddItemToSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) AddIUnknownToSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrSyncItem* pNewItem) ProposeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszItemID) CommitItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReportManualSync;
	}


	public HRESULT ReportProgress(PWSTR pszItemID, PWSTR pszProgressText, SYNCMGR_PROGRESS_STATUS nStatus, uint32 uCurrentStep, uint32 uMaxStep, SYNCMGR_CANCEL_REQUEST* pnCancelRequest) mut => VT.[Friend]ReportProgress(&this, pszItemID, pszProgressText, nStatus, uCurrentStep, uMaxStep, pnCancelRequest);

	public HRESULT SetHandlerProgressText(PWSTR pszProgressText, SYNCMGR_CANCEL_REQUEST* pnCancelRequest) mut => VT.[Friend]SetHandlerProgressText(&this, pszProgressText, pnCancelRequest);

	public HRESULT ReportEvent(PWSTR pszItemID, SYNCMGR_EVENT_LEVEL nLevel, SYNCMGR_EVENT_FLAGS nFlags, PWSTR pszName, PWSTR pszDescription, PWSTR pszLinkText, PWSTR pszLinkReference, PWSTR pszContext, Guid* pguidEventID) mut => VT.[Friend]ReportEvent(&this, pszItemID, nLevel, nFlags, pszName, pszDescription, pszLinkText, pszLinkReference, pszContext, pguidEventID);

	public HRESULT CanContinue(PWSTR pszItemID) mut => VT.[Friend]CanContinue(&this, pszItemID);

	public HRESULT QueryForAdditionalItems(IEnumString** ppenumItemIDs, IEnumUnknown** ppenumPunks) mut => VT.[Friend]QueryForAdditionalItems(&this, ppenumItemIDs, ppenumPunks);

	public HRESULT AddItemToSession(PWSTR pszItemID) mut => VT.[Friend]AddItemToSession(&this, pszItemID);

	public HRESULT AddIUnknownToSession(IUnknown* punk) mut => VT.[Friend]AddIUnknownToSession(&this, punk);

	public HRESULT ProposeItem(ISyncMgrSyncItem* pNewItem) mut => VT.[Friend]ProposeItem(&this, pNewItem);

	public HRESULT CommitItem(PWSTR pszItemID) mut => VT.[Friend]CommitItem(&this, pszItemID);

	public HRESULT ReportManualSync() mut => VT.[Friend]ReportManualSync(&this);
}

[CRepr]struct ISyncMgrUIOperation : IUnknown
{
	public new const Guid IID = .(0xfc7cfa47, 0xdfe1, 0x45b5, 0xa0, 0x49, 0x8c, 0xfd, 0x82, 0xbe, 0xc2, 0x71);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner) Run;
	}


	public HRESULT Run(HWND hwndOwner) mut => VT.[Friend]Run(&this, hwndOwner);
}

[CRepr]struct ISyncMgrEventLinkUIOperation : ISyncMgrUIOperation
{
	public new const Guid IID = .(0x64522e52, 0x848b, 0x4015, 0x89, 0xce, 0x5a, 0x36, 0xf0, 0x0b, 0x94, 0xff);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncMgrUIOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidEventID, ISyncMgrEvent* pEvent) Init;
	}


	public HRESULT Init(in Guid rguidEventID, ISyncMgrEvent* pEvent) mut => VT.[Friend]Init(&this, rguidEventID, pEvent);
}

[CRepr]struct ISyncMgrScheduleWizardUIOperation : ISyncMgrUIOperation
{
	public new const Guid IID = .(0x459a6c84, 0x21d2, 0x4ddc, 0x8a, 0x53, 0xf0, 0x23, 0xa4, 0x60, 0x66, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISyncMgrUIOperation.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID) InitWizard;
	}


	public HRESULT InitWizard(PWSTR pszHandlerID) mut => VT.[Friend]InitWizard(&this, pszHandlerID);
}

[CRepr]struct ISyncMgrSyncResult : IUnknown
{
	public new const Guid IID = .(0x2b90f17e, 0x5a3e, 0x4b33, 0xbb, 0x7f, 0x1b, 0xc4, 0x80, 0x56, 0xb9, 0x4d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_PROGRESS_STATUS nStatus, uint32 cError, uint32 cConflicts) Result;
	}


	public HRESULT Result(SYNCMGR_PROGRESS_STATUS nStatus, uint32 cError, uint32 cConflicts) mut => VT.[Friend]Result(&this, nStatus, cError, cConflicts);
}

[CRepr]struct ISyncMgrControl : IUnknown
{
	public new const Guid IID = .(0x9b63616c, 0x36b2, 0x46bc, 0x95, 0x9f, 0xc1, 0x59, 0x39, 0x52, 0xd1, 0x9b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, HWND hwndOwner, IUnknown* punk, SYNCMGR_SYNC_CONTROL_FLAGS nSyncControlFlags, ISyncMgrSyncResult* pResult) StartHandlerSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems, HWND hwndOwner, IUnknown* punk, SYNCMGR_SYNC_CONTROL_FLAGS nSyncControlFlags, ISyncMgrSyncResult* pResult) StartItemSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndOwner) StartSyncAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID) StopHandlerSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems) StopItemSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) StopSyncAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rclsidCollectionID, SYNCMGR_CONTROL_FLAGS nControlFlags) UpdateHandlerCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, SYNCMGR_CONTROL_FLAGS nControlFlags) UpdateHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) UpdateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) UpdateEvents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, ISyncMgrConflict* pConflict, SYNCMGR_UPDATE_REASON nReason) UpdateConflict;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) UpdateConflicts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActivate, PWSTR pszHandlerID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) ActivateHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable, PWSTR pszHandlerID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) EnableHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable, PWSTR pszHandlerID, PWSTR pszItemID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) EnableItem;
	}


	public HRESULT StartHandlerSync(PWSTR pszHandlerID, HWND hwndOwner, IUnknown* punk, SYNCMGR_SYNC_CONTROL_FLAGS nSyncControlFlags, ISyncMgrSyncResult* pResult) mut => VT.[Friend]StartHandlerSync(&this, pszHandlerID, hwndOwner, punk, nSyncControlFlags, pResult);

	public HRESULT StartItemSync(PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems, HWND hwndOwner, IUnknown* punk, SYNCMGR_SYNC_CONTROL_FLAGS nSyncControlFlags, ISyncMgrSyncResult* pResult) mut => VT.[Friend]StartItemSync(&this, pszHandlerID, ppszItemIDs, cItems, hwndOwner, punk, nSyncControlFlags, pResult);

	public HRESULT StartSyncAll(HWND hwndOwner) mut => VT.[Friend]StartSyncAll(&this, hwndOwner);

	public HRESULT StopHandlerSync(PWSTR pszHandlerID) mut => VT.[Friend]StopHandlerSync(&this, pszHandlerID);

	public HRESULT StopItemSync(PWSTR pszHandlerID, PWSTR* ppszItemIDs, uint32 cItems) mut => VT.[Friend]StopItemSync(&this, pszHandlerID, ppszItemIDs, cItems);

	public HRESULT StopSyncAll() mut => VT.[Friend]StopSyncAll(&this);

	public HRESULT UpdateHandlerCollection(in Guid rclsidCollectionID, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]UpdateHandlerCollection(&this, rclsidCollectionID, nControlFlags);

	public HRESULT UpdateHandler(PWSTR pszHandlerID, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]UpdateHandler(&this, pszHandlerID, nControlFlags);

	public HRESULT UpdateItem(PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]UpdateItem(&this, pszHandlerID, pszItemID, nControlFlags);

	public HRESULT UpdateEvents(PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]UpdateEvents(&this, pszHandlerID, pszItemID, nControlFlags);

	public HRESULT UpdateConflict(PWSTR pszHandlerID, PWSTR pszItemID, ISyncMgrConflict* pConflict, SYNCMGR_UPDATE_REASON nReason) mut => VT.[Friend]UpdateConflict(&this, pszHandlerID, pszItemID, pConflict, nReason);

	public HRESULT UpdateConflicts(PWSTR pszHandlerID, PWSTR pszItemID, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]UpdateConflicts(&this, pszHandlerID, pszItemID, nControlFlags);

	public HRESULT ActivateHandler(BOOL fActivate, PWSTR pszHandlerID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]ActivateHandler(&this, fActivate, pszHandlerID, hwndOwner, nControlFlags);

	public HRESULT EnableHandler(BOOL fEnable, PWSTR pszHandlerID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]EnableHandler(&this, fEnable, pszHandlerID, hwndOwner, nControlFlags);

	public HRESULT EnableItem(BOOL fEnable, PWSTR pszHandlerID, PWSTR pszItemID, HWND hwndOwner, SYNCMGR_CONTROL_FLAGS nControlFlags) mut => VT.[Friend]EnableItem(&this, fEnable, pszHandlerID, pszItemID, hwndOwner, nControlFlags);
}

[CRepr]struct ISyncMgrEventStore : IUnknown
{
	public new const Guid IID = .(0x37e412f9, 0x016e, 0x44c2, 0x81, 0xff, 0xdb, 0x3a, 0xdd, 0x77, 0x42, 0x66);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncMgrEvents** ppenum) GetEventEnumerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcEvents) GetEventCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid rguidEventID, ISyncMgrEvent** ppEvent) GetEvent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidEventIDs, uint32 cEvents) RemoveEvent;
	}


	public HRESULT GetEventEnumerator(IEnumSyncMgrEvents** ppenum) mut => VT.[Friend]GetEventEnumerator(&this, ppenum);

	public HRESULT GetEventCount(uint32* pcEvents) mut => VT.[Friend]GetEventCount(&this, pcEvents);

	public HRESULT GetEvent(in Guid rguidEventID, ISyncMgrEvent** ppEvent) mut => VT.[Friend]GetEvent(&this, rguidEventID, ppEvent);

	public HRESULT RemoveEvent(Guid* pguidEventIDs, uint32 cEvents) mut => VT.[Friend]RemoveEvent(&this, pguidEventIDs, cEvents);
}

[CRepr]struct ISyncMgrEvent : IUnknown
{
	public new const Guid IID = .(0xfee0ef8b, 0x46bd, 0x4db4, 0xb7, 0xe6, 0xff, 0x2c, 0x68, 0x73, 0x13, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidEventID) GetEventID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszHandlerID) GetHandlerID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszItemID) GetItemID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_EVENT_LEVEL* pnLevel) GetLevel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_EVENT_FLAGS* pnFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pfCreationTime) GetTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszName) GetName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszLinkText) GetLinkText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszLinkReference) GetLinkReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszContext) GetContext;
	}


	public HRESULT GetEventID(Guid* pguidEventID) mut => VT.[Friend]GetEventID(&this, pguidEventID);

	public HRESULT GetHandlerID(PWSTR* ppszHandlerID) mut => VT.[Friend]GetHandlerID(&this, ppszHandlerID);

	public HRESULT GetItemID(PWSTR* ppszItemID) mut => VT.[Friend]GetItemID(&this, ppszItemID);

	public HRESULT GetLevel(SYNCMGR_EVENT_LEVEL* pnLevel) mut => VT.[Friend]GetLevel(&this, pnLevel);

	public HRESULT GetFlags(SYNCMGR_EVENT_FLAGS* pnFlags) mut => VT.[Friend]COM_GetFlags(&this, pnFlags);

	public HRESULT GetTime(FILETIME* pfCreationTime) mut => VT.[Friend]GetTime(&this, pfCreationTime);

	public HRESULT GetName(PWSTR* ppszName) mut => VT.[Friend]GetName(&this, ppszName);

	public HRESULT GetDescription(PWSTR* ppszDescription) mut => VT.[Friend]GetDescription(&this, ppszDescription);

	public HRESULT GetLinkText(PWSTR* ppszLinkText) mut => VT.[Friend]GetLinkText(&this, ppszLinkText);

	public HRESULT GetLinkReference(PWSTR* ppszLinkReference) mut => VT.[Friend]GetLinkReference(&this, ppszLinkReference);

	public HRESULT GetContext(PWSTR* ppszContext) mut => VT.[Friend]GetContext(&this, ppszContext);
}

[CRepr]struct IEnumSyncMgrEvents : IUnknown
{
	public new const Guid IID = .(0xc81a1d4e, 0x8cf7, 0x4683, 0x80, 0xe0, 0xbc, 0xae, 0x88, 0xd6, 0x77, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISyncMgrEvent** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncMgrEvents** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ISyncMgrEvent** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncMgrEvents** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISyncMgrConflictStore : IUnknown
{
	public new const Guid IID = .(0xcf8fc579, 0xc396, 0x4774, 0x85, 0xf1, 0xd9, 0x08, 0xa8, 0x31, 0x15, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, IEnumSyncMgrConflict** ppEnum) EnumConflicts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_CONFLICT_ID_INFO* pConflictIdInfo, in Guid riid, void** ppv) BindToConflict;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_CONFLICT_ID_INFO* rgConflictIdInfo, uint32 cConflicts) RemoveConflicts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHandlerID, PWSTR pszItemID, uint32* pnConflicts) GetCount;
	}


	public HRESULT EnumConflicts(PWSTR pszHandlerID, PWSTR pszItemID, IEnumSyncMgrConflict** ppEnum) mut => VT.[Friend]EnumConflicts(&this, pszHandlerID, pszItemID, ppEnum);

	public HRESULT BindToConflict(SYNCMGR_CONFLICT_ID_INFO* pConflictIdInfo, in Guid riid, void** ppv) mut => VT.[Friend]BindToConflict(&this, pConflictIdInfo, riid, ppv);

	public HRESULT RemoveConflicts(SYNCMGR_CONFLICT_ID_INFO* rgConflictIdInfo, uint32 cConflicts) mut => VT.[Friend]RemoveConflicts(&this, rgConflictIdInfo, cConflicts);

	public HRESULT GetCount(PWSTR pszHandlerID, PWSTR pszItemID, uint32* pnConflicts) mut => VT.[Friend]GetCount(&this, pszHandlerID, pszItemID, pnConflicts);
}

[CRepr]struct IEnumSyncMgrConflict : IUnknown
{
	public new const Guid IID = .(0x82705914, 0xdda3, 0x4893, 0xba, 0x99, 0x49, 0xde, 0x6c, 0x8c, 0x80, 0x36);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, ISyncMgrConflict** rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumSyncMgrConflict** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, ISyncMgrConflict** rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumSyncMgrConflict** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISyncMgrConflict : IUnknown
{
	public new const Guid IID = .(0x9c204249, 0xc443, 0x4ba4, 0x85, 0xed, 0xc9, 0x72, 0x68, 0x1d, 0xb1, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propkey, PROPVARIANT* ppropvar) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_CONFLICT_ID_INFO* pConflictIdInfo) GetConflictIdInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrConflictItems** ppArray) GetItemsArray;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrConflictResolveInfo* pResolveInfo) Resolve;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppvResolutionHandler) GetResolutionHandler;
	}


	public HRESULT GetProperty(PROPERTYKEY* propkey, PROPVARIANT* ppropvar) mut => VT.[Friend]GetProperty(&this, propkey, ppropvar);

	public HRESULT GetConflictIdInfo(SYNCMGR_CONFLICT_ID_INFO* pConflictIdInfo) mut => VT.[Friend]GetConflictIdInfo(&this, pConflictIdInfo);

	public HRESULT GetItemsArray(ISyncMgrConflictItems** ppArray) mut => VT.[Friend]GetItemsArray(&this, ppArray);

	public HRESULT Resolve(ISyncMgrConflictResolveInfo* pResolveInfo) mut => VT.[Friend]Resolve(&this, pResolveInfo);

	public HRESULT GetResolutionHandler(in Guid riid, void** ppvResolutionHandler) mut => VT.[Friend]GetResolutionHandler(&this, riid, ppvResolutionHandler);
}

[CRepr]struct ISyncMgrResolutionHandler : IUnknown
{
	public new const Guid IID = .(0x40a3d052, 0x8bff, 0x4c4b, 0xa3, 0x38, 0xd4, 0xa3, 0x95, 0x70, 0x0d, 0xe9);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwAbilities) QueryAbilities;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psiOther, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) KeepOther;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) KeepRecent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) RemoveFromSyncSet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrConflictResolutionItems* pArray, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) KeepItems;
	}


	public HRESULT QueryAbilities(uint32* pdwAbilities) mut => VT.[Friend]QueryAbilities(&this, pdwAbilities);

	public HRESULT KeepOther(IShellItem* psiOther, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) mut => VT.[Friend]KeepOther(&this, psiOther, pFeedback);

	public HRESULT KeepRecent(SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) mut => VT.[Friend]KeepRecent(&this, pFeedback);

	public HRESULT RemoveFromSyncSet(SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) mut => VT.[Friend]RemoveFromSyncSet(&this, pFeedback);

	public HRESULT KeepItems(ISyncMgrConflictResolutionItems* pArray, SYNCMGR_RESOLUTION_FEEDBACK* pFeedback) mut => VT.[Friend]KeepItems(&this, pArray, pFeedback);
}

[CRepr]struct ISyncMgrConflictPresenter : IUnknown
{
	public new const Guid IID = .(0x0b4f5353, 0xfd2b, 0x42cd, 0x87, 0x63, 0x47, 0x79, 0xf2, 0xd5, 0x08, 0xa3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrConflict* pConflict, ISyncMgrConflictResolveInfo* pResolveInfo) PresentConflict;
	}


	public HRESULT PresentConflict(ISyncMgrConflict* pConflict, ISyncMgrConflictResolveInfo* pResolveInfo) mut => VT.[Friend]PresentConflict(&this, pConflict, pResolveInfo);
}

[CRepr]struct ISyncMgrConflictResolveInfo : IUnknown
{
	public new const Guid IID = .(0xc405a219, 0x25a2, 0x442e, 0x87, 0x43, 0xb8, 0x45, 0xa2, 0xce, 0xe9, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnCurrentConflict, uint32* pcConflicts, uint32* pcRemainingForApplyToAll) GetIterationInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_PRESENTER_NEXT_STEP* pnPresenterNextStep) GetPresenterNextStep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_PRESENTER_CHOICE* pnPresenterChoice, BOOL* pfApplyToAll) GetPresenterChoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcChoices) GetItemChoiceCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iChoice, uint32* piChoiceIndex) GetItemChoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_PRESENTER_NEXT_STEP nPresenterNextStep) SetPresenterNextStep;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGR_PRESENTER_CHOICE nPresenterChoice, BOOL fApplyToAll) SetPresenterChoice;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* prgiConflictItemIndexes, uint32 cChoices) SetItemChoices;
	}


	public HRESULT GetIterationInfo(uint32* pnCurrentConflict, uint32* pcConflicts, uint32* pcRemainingForApplyToAll) mut => VT.[Friend]GetIterationInfo(&this, pnCurrentConflict, pcConflicts, pcRemainingForApplyToAll);

	public HRESULT GetPresenterNextStep(SYNCMGR_PRESENTER_NEXT_STEP* pnPresenterNextStep) mut => VT.[Friend]GetPresenterNextStep(&this, pnPresenterNextStep);

	public HRESULT GetPresenterChoice(SYNCMGR_PRESENTER_CHOICE* pnPresenterChoice, BOOL* pfApplyToAll) mut => VT.[Friend]GetPresenterChoice(&this, pnPresenterChoice, pfApplyToAll);

	public HRESULT GetItemChoiceCount(uint32* pcChoices) mut => VT.[Friend]GetItemChoiceCount(&this, pcChoices);

	public HRESULT GetItemChoice(uint32 iChoice, uint32* piChoiceIndex) mut => VT.[Friend]GetItemChoice(&this, iChoice, piChoiceIndex);

	public HRESULT SetPresenterNextStep(SYNCMGR_PRESENTER_NEXT_STEP nPresenterNextStep) mut => VT.[Friend]SetPresenterNextStep(&this, nPresenterNextStep);

	public HRESULT SetPresenterChoice(SYNCMGR_PRESENTER_CHOICE nPresenterChoice, BOOL fApplyToAll) mut => VT.[Friend]SetPresenterChoice(&this, nPresenterChoice, fApplyToAll);

	public HRESULT SetItemChoices(uint32* prgiConflictItemIndexes, uint32 cChoices) mut => VT.[Friend]SetItemChoices(&this, prgiConflictItemIndexes, cChoices);
}

[CRepr]struct ISyncMgrConflictFolder : IUnknown
{
	public new const Guid IID = .(0x59287f5e, 0xbc81, 0x4fca, 0xa7, 0xf1, 0xe5, 0xa8, 0xec, 0xdb, 0x1d, 0x69);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrConflict* pConflict, ITEMIDLIST** ppidlConflict) GetConflictIDList;
	}


	public HRESULT GetConflictIDList(ISyncMgrConflict* pConflict, ITEMIDLIST** ppidlConflict) mut => VT.[Friend]GetConflictIDList(&this, pConflict, ppidlConflict);
}

[CRepr]struct ISyncMgrConflictItems : IUnknown
{
	public new const Guid IID = .(0x9c7ead52, 0x8023, 0x4936, 0xa4, 0xdb, 0xd2, 0xa9, 0xa9, 0x9e, 0x43, 0x6a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, CONFIRM_CONFLICT_ITEM* pItemInfo) GetItem;
	}


	public HRESULT GetCount(uint32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetItem(uint32 iIndex, CONFIRM_CONFLICT_ITEM* pItemInfo) mut => VT.[Friend]GetItem(&this, iIndex, pItemInfo);
}

[CRepr]struct ISyncMgrConflictResolutionItems : IUnknown
{
	public new const Guid IID = .(0x458725b9, 0x129d, 0x4135, 0xa9, 0x98, 0x9c, 0xea, 0xfe, 0xc2, 0x70, 0x07);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iIndex, CONFIRM_CONFLICT_RESULT_INFO* pItemInfo) GetItem;
	}


	public HRESULT GetCount(uint32* pCount) mut => VT.[Friend]GetCount(&this, pCount);

	public HRESULT GetItem(uint32 iIndex, CONFIRM_CONFLICT_RESULT_INFO* pItemInfo) mut => VT.[Friend]GetItem(&this, iIndex, pItemInfo);
}

[CRepr]struct IInputPanelConfiguration : IUnknown
{
	public new const Guid IID = .(0x41c81592, 0x514c, 0x48bd, 0xa2, 0x2e, 0xe6, 0xaf, 0x63, 0x85, 0x21, 0xa6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableFocusTracking;
	}


	public HRESULT EnableFocusTracking() mut => VT.[Friend]EnableFocusTracking(&this);
}

[CRepr]struct IInputPanelInvocationConfiguration : IUnknown
{
	public new const Guid IID = .(0xa213f136, 0x3b45, 0x4362, 0xa3, 0x32, 0xef, 0xb6, 0x54, 0x7c, 0xd4, 0x32);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RequireTouchInEditControl;
	}


	public HRESULT RequireTouchInEditControl() mut => VT.[Friend]RequireTouchInEditControl(&this);
}

[CRepr]struct ISharedBitmap : IUnknown
{
	public new const Guid IID = .(0x091162a4, 0xbc96, 0x411f, 0xaa, 0xe8, 0xc5, 0x12, 0x2c, 0xd0, 0x33, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* phbm) GetSharedBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSize) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_ALPHATYPE* pat) GetFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP hbm, WTS_ALPHATYPE wtsAT) InitializeBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* phbm) Detach;
	}


	public HRESULT GetSharedBitmap(HBITMAP* phbm) mut => VT.[Friend]GetSharedBitmap(&this, phbm);

	public HRESULT GetSize(SIZE* pSize) mut => VT.[Friend]GetSize(&this, pSize);

	public HRESULT GetFormat(WTS_ALPHATYPE* pat) mut => VT.[Friend]GetFormat(&this, pat);

	public HRESULT InitializeBitmap(HBITMAP hbm, WTS_ALPHATYPE wtsAT) mut => VT.[Friend]InitializeBitmap(&this, hbm, wtsAT);

	public HRESULT Detach(HBITMAP* phbm) mut => VT.[Friend]Detach(&this, phbm);
}

[CRepr]struct IThumbnailCache : IUnknown
{
	public new const Guid IID = .(0xf676c15d, 0x596a, 0x4ce2, 0x82, 0x34, 0x33, 0x99, 0x6f, 0x44, 0x5d, 0xb1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* pShellItem, uint32 cxyRequestedThumbSize, WTS_FLAGS flags, ISharedBitmap** ppvThumb, WTS_CACHEFLAGS* pOutFlags, WTS_THUMBNAILID* pThumbnailID) GetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_THUMBNAILID thumbnailID, uint32 cxyRequestedThumbSize, ISharedBitmap** ppvThumb, WTS_CACHEFLAGS* pOutFlags) GetThumbnailByID;
	}


	public HRESULT GetThumbnail(IShellItem* pShellItem, uint32 cxyRequestedThumbSize, WTS_FLAGS flags, ISharedBitmap** ppvThumb, WTS_CACHEFLAGS* pOutFlags, WTS_THUMBNAILID* pThumbnailID) mut => VT.[Friend]GetThumbnail(&this, pShellItem, cxyRequestedThumbSize, flags, ppvThumb, pOutFlags, pThumbnailID);

	public HRESULT GetThumbnailByID(WTS_THUMBNAILID thumbnailID, uint32 cxyRequestedThumbSize, ISharedBitmap** ppvThumb, WTS_CACHEFLAGS* pOutFlags) mut => VT.[Friend]GetThumbnailByID(&this, thumbnailID, cxyRequestedThumbSize, ppvThumb, pOutFlags);
}

[CRepr]struct IThumbnailProvider : IUnknown
{
	public new const Guid IID = .(0xe357fccd, 0xa995, 0x4576, 0xb0, 0x1f, 0x23, 0x46, 0x30, 0x15, 0x4e, 0x96);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cx, HBITMAP* phbmp, WTS_ALPHATYPE* pdwAlpha) GetThumbnail;
	}


	public HRESULT GetThumbnail(uint32 cx, HBITMAP* phbmp, WTS_ALPHATYPE* pdwAlpha) mut => VT.[Friend]GetThumbnail(&this, cx, phbmp, pdwAlpha);
}

[CRepr]struct IThumbnailSettings : IUnknown
{
	public new const Guid IID = .(0xf4376f00, 0xbef5, 0x4d45, 0x80, 0xf3, 0x1e, 0x02, 0x3b, 0xbf, 0x12, 0x09);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WTS_CONTEXTFLAGS dwContext) SetContext;
	}


	public HRESULT SetContext(WTS_CONTEXTFLAGS dwContext) mut => VT.[Friend]SetContext(&this, dwContext);
}

[CRepr]struct IThumbnailCachePrimer : IUnknown
{
	public new const Guid IID = .(0x0f03f8fe, 0x2b26, 0x46f0, 0x96, 0x5a, 0x21, 0x2a, 0xa8, 0xd6, 0x6b, 0x76);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* psi, WTS_FLAGS wtsFlags, uint32 cxyRequestedThumbSize) PageInThumbnail;
	}


	public HRESULT PageInThumbnail(IShellItem* psi, WTS_FLAGS wtsFlags, uint32 cxyRequestedThumbSize) mut => VT.[Friend]PageInThumbnail(&this, psi, wtsFlags, cxyRequestedThumbSize);
}

[CRepr]struct IShellImageDataFactory : IUnknown
{
	public new const Guid IID = .(0x9be8ed5c, 0xedab, 0x4d75, 0x90, 0xf3, 0xbd, 0x5b, 0xdb, 0xb2, 0x1c, 0x82);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellImageData** ppshimg) CreateIShellImageData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, IShellImageData** ppshimg) CreateImageFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, IShellImageData** ppshimg) CreateImageFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPath, Guid* pDataFormat) GetDataFormatFromPath;
	}


	public HRESULT CreateIShellImageData(IShellImageData** ppshimg) mut => VT.[Friend]CreateIShellImageData(&this, ppshimg);

	public HRESULT CreateImageFromFile(PWSTR pszPath, IShellImageData** ppshimg) mut => VT.[Friend]CreateImageFromFile(&this, pszPath, ppshimg);

	public HRESULT CreateImageFromStream(IStream* pStream, IShellImageData** ppshimg) mut => VT.[Friend]CreateImageFromStream(&this, pStream, ppshimg);

	public HRESULT GetDataFormatFromPath(PWSTR pszPath, Guid* pDataFormat) mut => VT.[Friend]GetDataFormatFromPath(&this, pszPath, pDataFormat);
}

[CRepr]struct IShellImageData : IUnknown
{
	public new const Guid IID = .(0xbfdeec12, 0x8040, 0x4403, 0xa5, 0xea, 0x9e, 0x07, 0xda, 0xfc, 0xf5, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 cxDesired, uint32 cyDesired) Decode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HDC hdc, RECT* prcDest, RECT* prcSrc) Draw;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NextFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) NextPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) PrevPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsTransparent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsAnimated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsVector;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsMultipage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsEditable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsPrintable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsDecoded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnPage) GetCurrentPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcPages) GetPageCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 iPage) SelectPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE* pSize) GetSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pDataFormat) GetRawDataFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFormat) GetPixelFormat;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwDelay) GetDelay;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwMode, IPropertySetStorage** ppPropSet) GetProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAngle) Rotate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cx, uint32 cy, uint32 hints) Scale;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DiscardEdit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyBag* pbagEnc) SetEncoderParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR wszName, uint32 cch) DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* puResolutionX, uint32* puResolutionY) GetResolution;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pguidFmt, uint8** ppEncParams) GetEncoderParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellImageDataAbort* pAbort, IShellImageDataAbort** ppAbortPrev) RegisterAbort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8** ppImg) CloneFrame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint8* pImg) ReplaceFrame;
	}


	public HRESULT Decode(uint32 dwFlags, uint32 cxDesired, uint32 cyDesired) mut => VT.[Friend]Decode(&this, dwFlags, cxDesired, cyDesired);

	public HRESULT Draw(HDC hdc, RECT* prcDest, RECT* prcSrc) mut => VT.[Friend]Draw(&this, hdc, prcDest, prcSrc);

	public HRESULT NextFrame() mut => VT.[Friend]NextFrame(&this);

	public HRESULT NextPage() mut => VT.[Friend]NextPage(&this);

	public HRESULT PrevPage() mut => VT.[Friend]PrevPage(&this);

	public HRESULT IsTransparent() mut => VT.[Friend]IsTransparent(&this);

	public HRESULT IsAnimated() mut => VT.[Friend]IsAnimated(&this);

	public HRESULT IsVector() mut => VT.[Friend]IsVector(&this);

	public HRESULT IsMultipage() mut => VT.[Friend]IsMultipage(&this);

	public HRESULT IsEditable() mut => VT.[Friend]IsEditable(&this);

	public HRESULT IsPrintable() mut => VT.[Friend]IsPrintable(&this);

	public HRESULT IsDecoded() mut => VT.[Friend]IsDecoded(&this);

	public HRESULT GetCurrentPage(uint32* pnPage) mut => VT.[Friend]GetCurrentPage(&this, pnPage);

	public HRESULT GetPageCount(uint32* pcPages) mut => VT.[Friend]GetPageCount(&this, pcPages);

	public HRESULT SelectPage(uint32 iPage) mut => VT.[Friend]SelectPage(&this, iPage);

	public HRESULT GetSize(SIZE* pSize) mut => VT.[Friend]GetSize(&this, pSize);

	public HRESULT GetRawDataFormat(Guid* pDataFormat) mut => VT.[Friend]GetRawDataFormat(&this, pDataFormat);

	public HRESULT GetPixelFormat(uint32* pFormat) mut => VT.[Friend]GetPixelFormat(&this, pFormat);

	public HRESULT GetDelay(uint32* pdwDelay) mut => VT.[Friend]GetDelay(&this, pdwDelay);

	public HRESULT GetProperties(uint32 dwMode, IPropertySetStorage** ppPropSet) mut => VT.[Friend]GetProperties(&this, dwMode, ppPropSet);

	public HRESULT Rotate(uint32 dwAngle) mut => VT.[Friend]Rotate(&this, dwAngle);

	public HRESULT Scale(uint32 cx, uint32 cy, uint32 hints) mut => VT.[Friend]Scale(&this, cx, cy, hints);

	public HRESULT DiscardEdit() mut => VT.[Friend]DiscardEdit(&this);

	public HRESULT SetEncoderParams(IPropertyBag* pbagEnc) mut => VT.[Friend]SetEncoderParams(&this, pbagEnc);

	public HRESULT DisplayName(PWSTR wszName, uint32 cch) mut => VT.[Friend]DisplayName(&this, wszName, cch);

	public HRESULT GetResolution(uint32* puResolutionX, uint32* puResolutionY) mut => VT.[Friend]GetResolution(&this, puResolutionX, puResolutionY);

	public HRESULT GetEncoderParams(Guid* pguidFmt, uint8** ppEncParams) mut => VT.[Friend]GetEncoderParams(&this, pguidFmt, ppEncParams);

	public HRESULT RegisterAbort(IShellImageDataAbort* pAbort, IShellImageDataAbort** ppAbortPrev) mut => VT.[Friend]RegisterAbort(&this, pAbort, ppAbortPrev);

	public HRESULT CloneFrame(uint8** ppImg) mut => VT.[Friend]CloneFrame(&this, ppImg);

	public HRESULT ReplaceFrame(uint8* pImg) mut => VT.[Friend]ReplaceFrame(&this, pImg);
}

[CRepr]struct IShellImageDataAbort : IUnknown
{
	public new const Guid IID = .(0x53fb8e58, 0x50c0, 0x4003, 0xb4, 0xaa, 0x0c, 0x8d, 0xf2, 0x8e, 0x7f, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) QueryAbort;
	}


	public HRESULT QueryAbort() mut => VT.[Friend]QueryAbort(&this);
}

[CRepr]struct IStorageProviderPropertyHandler : IUnknown
{
	public new const Guid IID = .(0x301dfbe5, 0x524c, 0x4b0f, 0x8b, 0x2d, 0x21, 0xc4, 0x0b, 0x3a, 0x29, 0x88);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* propertiesToRetrieve, uint32 propertiesToRetrieveCount, IPropertyStore** retrievedProperties) RetrieveProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertyStore* propertiesToSave) SaveProperties;
	}


	public HRESULT RetrieveProperties(PROPERTYKEY* propertiesToRetrieve, uint32 propertiesToRetrieveCount, IPropertyStore** retrievedProperties) mut => VT.[Friend]RetrieveProperties(&this, propertiesToRetrieve, propertiesToRetrieveCount, retrievedProperties);

	public HRESULT SaveProperties(IPropertyStore* propertiesToSave) mut => VT.[Friend]SaveProperties(&this, propertiesToSave);
}

[CRepr]struct IStorageProviderHandler : IUnknown
{
	public new const Guid IID = .(0x162c6fb5, 0x44d3, 0x435b, 0x90, 0x3d, 0xe6, 0x13, 0xfa, 0x09, 0x3f, 0xb5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, IStorageProviderPropertyHandler** propertyHandler) GetPropertyHandlerFromPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR uri, IStorageProviderPropertyHandler** propertyHandler) GetPropertyHandlerFromUri;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR fileId, IStorageProviderPropertyHandler** propertyHandler) GetPropertyHandlerFromFileId;
	}


	public HRESULT GetPropertyHandlerFromPath(PWSTR path, IStorageProviderPropertyHandler** propertyHandler) mut => VT.[Friend]GetPropertyHandlerFromPath(&this, path, propertyHandler);

	public HRESULT GetPropertyHandlerFromUri(PWSTR uri, IStorageProviderPropertyHandler** propertyHandler) mut => VT.[Friend]GetPropertyHandlerFromUri(&this, uri, propertyHandler);

	public HRESULT GetPropertyHandlerFromFileId(PWSTR fileId, IStorageProviderPropertyHandler** propertyHandler) mut => VT.[Friend]GetPropertyHandlerFromFileId(&this, fileId, propertyHandler);
}

[CRepr]struct ISyncMgrSynchronizeCallback : IUnknown
{
	public new const Guid IID = .(0x6295df41, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) ShowPropertiesCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) PrepareForSyncCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) SynchronizeCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, uint32 cItems, Guid* pItemIDs) ShowErrorCompleted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnable) EnableModeless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ItemID, SYNCMGRPROGRESSITEM* pSyncProgressItem) Progress;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwErrorLevel, PWSTR pszErrorText, SYNCMGRLOGERRORINFO* pSyncLogError) LogError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ErrorID, uint32 dwReserved) DeleteLogError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwszConnection, uint32 dwReserved) EstablishConnection;
	}


	public HRESULT ShowPropertiesCompleted(HRESULT hr) mut => VT.[Friend]ShowPropertiesCompleted(&this, hr);

	public HRESULT PrepareForSyncCompleted(HRESULT hr) mut => VT.[Friend]PrepareForSyncCompleted(&this, hr);

	public HRESULT SynchronizeCompleted(HRESULT hr) mut => VT.[Friend]SynchronizeCompleted(&this, hr);

	public HRESULT ShowErrorCompleted(HRESULT hr, uint32 cItems, Guid* pItemIDs) mut => VT.[Friend]ShowErrorCompleted(&this, hr, cItems, pItemIDs);

	public HRESULT EnableModeless(BOOL fEnable) mut => VT.[Friend]EnableModeless(&this, fEnable);

	public HRESULT Progress(in Guid ItemID, SYNCMGRPROGRESSITEM* pSyncProgressItem) mut => VT.[Friend]Progress(&this, ItemID, pSyncProgressItem);

	public HRESULT LogError(uint32 dwErrorLevel, PWSTR pszErrorText, SYNCMGRLOGERRORINFO* pSyncLogError) mut => VT.[Friend]LogError(&this, dwErrorLevel, pszErrorText, pSyncLogError);

	public HRESULT DeleteLogError(in Guid ErrorID, uint32 dwReserved) mut => VT.[Friend]DeleteLogError(&this, ErrorID, dwReserved);

	public HRESULT EstablishConnection(PWSTR pwszConnection, uint32 dwReserved) mut => VT.[Friend]EstablishConnection(&this, pwszConnection, dwReserved);
}

[CRepr]struct ISyncMgrEnumItems : IUnknown
{
	public new const Guid IID = .(0x6295df2a, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, SYNCMGRITEM* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrEnumItems** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, SYNCMGRITEM* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(ISyncMgrEnumItems** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct ISyncMgrSynchronize : IUnknown
{
	public new const Guid IID = .(0x6295df40, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, uint32 dwSyncMgrFlags, uint32 cbCookie, uint8* lpCookie) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SYNCMGRHANDLERINFO** ppSyncMgrHandlerInfo) GetHandlerInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrEnumItems** ppSyncMgrEnumItems) EnumSyncMgrItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid ItemID, in Guid riid, void** ppv) GetItemObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, in Guid ItemID) ShowProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISyncMgrSynchronizeCallback* lpCallBack) SetProgressCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cbNumItems, Guid* pItemIDs, HWND hWndParent, uint32 dwReserved) PrepareForSync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent) Synchronize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pItemID, uint32 dwSyncMgrStatus) SetItemStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, in Guid ErrorID) ShowError;
	}


	public HRESULT Initialize(uint32 dwReserved, uint32 dwSyncMgrFlags, uint32 cbCookie, uint8* lpCookie) mut => VT.[Friend]Initialize(&this, dwReserved, dwSyncMgrFlags, cbCookie, lpCookie);

	public HRESULT GetHandlerInfo(SYNCMGRHANDLERINFO** ppSyncMgrHandlerInfo) mut => VT.[Friend]GetHandlerInfo(&this, ppSyncMgrHandlerInfo);

	public HRESULT EnumSyncMgrItems(ISyncMgrEnumItems** ppSyncMgrEnumItems) mut => VT.[Friend]EnumSyncMgrItems(&this, ppSyncMgrEnumItems);

	public HRESULT GetItemObject(in Guid ItemID, in Guid riid, void** ppv) mut => VT.[Friend]GetItemObject(&this, ItemID, riid, ppv);

	public HRESULT ShowProperties(HWND hWndParent, in Guid ItemID) mut => VT.[Friend]ShowProperties(&this, hWndParent, ItemID);

	public HRESULT SetProgressCallback(ISyncMgrSynchronizeCallback* lpCallBack) mut => VT.[Friend]SetProgressCallback(&this, lpCallBack);

	public HRESULT PrepareForSync(uint32 cbNumItems, Guid* pItemIDs, HWND hWndParent, uint32 dwReserved) mut => VT.[Friend]PrepareForSync(&this, cbNumItems, pItemIDs, hWndParent, dwReserved);

	public HRESULT Synchronize(HWND hWndParent) mut => VT.[Friend]Synchronize(&this, hWndParent);

	public HRESULT SetItemStatus(in Guid pItemID, uint32 dwSyncMgrStatus) mut => VT.[Friend]SetItemStatus(&this, pItemID, dwSyncMgrStatus);

	public HRESULT ShowError(HWND hWndParent, in Guid ErrorID) mut => VT.[Friend]ShowError(&this, hWndParent, ErrorID);
}

[CRepr]struct ISyncMgrSynchronizeInvoke : IUnknown
{
	public new const Guid IID = .(0x6295df2c, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwInvokeFlags, in Guid clsid, uint32 cbCookie, uint8* pCookie) UpdateItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateAll;
	}


	public HRESULT UpdateItems(uint32 dwInvokeFlags, in Guid clsid, uint32 cbCookie, uint8* pCookie) mut => VT.[Friend]UpdateItems(&this, dwInvokeFlags, clsid, cbCookie, pCookie);

	public HRESULT UpdateAll() mut => VT.[Friend]UpdateAll(&this);
}

[CRepr]struct ISyncMgrRegister : IUnknown
{
	public new const Guid IID = .(0x6295df42, 0x35ee, 0x11d1, 0x87, 0x07, 0x00, 0xc0, 0x4f, 0xd9, 0x33, 0x27);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidHandler, PWSTR pwszDescription, uint32 dwSyncMgrRegisterFlags) RegisterSyncMgrHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidHandler, uint32 dwReserved) UnregisterSyncMgrHandler;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid clsidHandler, uint32* pdwSyncMgrRegisterFlags) GetHandlerRegistrationInfo;
	}


	public HRESULT RegisterSyncMgrHandler(in Guid clsidHandler, PWSTR pwszDescription, uint32 dwSyncMgrRegisterFlags) mut => VT.[Friend]RegisterSyncMgrHandler(&this, clsidHandler, pwszDescription, dwSyncMgrRegisterFlags);

	public HRESULT UnregisterSyncMgrHandler(in Guid clsidHandler, uint32 dwReserved) mut => VT.[Friend]UnregisterSyncMgrHandler(&this, clsidHandler, dwReserved);

	public HRESULT GetHandlerRegistrationInfo(in Guid clsidHandler, uint32* pdwSyncMgrRegisterFlags) mut => VT.[Friend]GetHandlerRegistrationInfo(&this, clsidHandler, pdwSyncMgrRegisterFlags);
}

[CRepr]struct IThumbnailStreamCache : IUnknown
{
	public new const Guid IID = .(0x90e11430, 0x9569, 0x41d8, 0xae, 0x75, 0x6d, 0x4d, 0x2a, 0xe7, 0xcc, 0xa0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, uint64 cacheId, ThumbnailStreamCacheOptions options, uint32 requestedThumbnailSize, SIZE* thumbnailSize, IStream** thumbnailStream) GetThumbnailStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR path, uint64 cacheId, SIZE thumbnailSize, IStream* thumbnailStream) SetThumbnailStream;
	}


	public HRESULT GetThumbnailStream(PWSTR path, uint64 cacheId, ThumbnailStreamCacheOptions options, uint32 requestedThumbnailSize, SIZE* thumbnailSize, IStream** thumbnailStream) mut => VT.[Friend]GetThumbnailStream(&this, path, cacheId, options, requestedThumbnailSize, thumbnailSize, thumbnailStream);

	public HRESULT SetThumbnailStream(PWSTR path, uint64 cacheId, SIZE thumbnailSize, IStream* thumbnailStream) mut => VT.[Friend]SetThumbnailStream(&this, path, cacheId, thumbnailSize, thumbnailStream);
}

[CRepr]struct ITravelLogEntry : IUnknown
{
	public new const Guid IID = .(0x7ebfdd87, 0xad18, 0x11d3, 0xa4, 0xc5, 0x00, 0xc0, 0x4f, 0x72, 0xd6, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszTitle) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszURL) GetURL;
	}


	public HRESULT GetTitle(PWSTR* ppszTitle) mut => VT.[Friend]GetTitle(&this, ppszTitle);

	public HRESULT GetURL(PWSTR* ppszURL) mut => VT.[Friend]GetURL(&this, ppszURL);
}

[CRepr]struct ITravelLogClient : IUnknown
{
	public new const Guid IID = .(0x241c033e, 0xe659, 0x43da, 0xaa, 0x4d, 0x40, 0x86, 0xdb, 0xc4, 0x75, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwID, IUnknown** ppunk) FindWindowByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream, WINDOWDATA* pWinData) GetWindowData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrlLocation, uint32 dwPosition) LoadHistoryPosition;
	}


	public HRESULT FindWindowByIndex(uint32 dwID, IUnknown** ppunk) mut => VT.[Friend]FindWindowByIndex(&this, dwID, ppunk);

	public HRESULT GetWindowData(IStream* pStream, WINDOWDATA* pWinData) mut => VT.[Friend]GetWindowData(&this, pStream, pWinData);

	public HRESULT LoadHistoryPosition(PWSTR pszUrlLocation, uint32 dwPosition) mut => VT.[Friend]LoadHistoryPosition(&this, pszUrlLocation, dwPosition);
}

[CRepr]struct IEnumTravelLogEntry : IUnknown
{
	public new const Guid IID = .(0x7ebfdd85, 0xad18, 0x11d3, 0xa4, 0xc5, 0x00, 0xc0, 0x4f, 0x72, 0xd6, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt, ITravelLogEntry** rgElt, uint32* pcEltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cElt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTravelLogEntry** ppEnum) Clone;
	}


	public HRESULT Next(uint32 cElt, ITravelLogEntry** rgElt, uint32* pcEltFetched) mut => VT.[Friend]Next(&this, cElt, rgElt, pcEltFetched);

	public HRESULT Skip(uint32 cElt) mut => VT.[Friend]Skip(&this, cElt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumTravelLogEntry** ppEnum) mut => VT.[Friend]Clone(&this, ppEnum);
}

[CRepr]struct ITravelLogStg : IUnknown
{
	public new const Guid IID = .(0x7ebfdd80, 0xad18, 0x11d3, 0xa4, 0xc5, 0x00, 0xc0, 0x4f, 0x72, 0xd6, 0xb8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszUrl, PWSTR pszTitle, ITravelLogEntry* ptleRelativeTo, BOOL fPrepend, ITravelLogEntry** pptle) CreateEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITravelLogEntry* ptle) TravelTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TLENUMF flags, IEnumTravelLogEntry** ppenum) EnumEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TLENUMF flags, PWSTR pszUrl, IEnumTravelLogEntry** ppenum) FindEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TLENUMF flags, uint32* pcEntries) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITravelLogEntry* ptle) RemoveEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iOffset, ITravelLogEntry** ptle) GetRelativeEntry;
	}


	public HRESULT CreateEntry(PWSTR pszUrl, PWSTR pszTitle, ITravelLogEntry* ptleRelativeTo, BOOL fPrepend, ITravelLogEntry** pptle) mut => VT.[Friend]CreateEntry(&this, pszUrl, pszTitle, ptleRelativeTo, fPrepend, pptle);

	public HRESULT TravelTo(ITravelLogEntry* ptle) mut => VT.[Friend]TravelTo(&this, ptle);

	public HRESULT EnumEntries(TLENUMF flags, IEnumTravelLogEntry** ppenum) mut => VT.[Friend]EnumEntries(&this, flags, ppenum);

	public HRESULT FindEntries(TLENUMF flags, PWSTR pszUrl, IEnumTravelLogEntry** ppenum) mut => VT.[Friend]FindEntries(&this, flags, pszUrl, ppenum);

	public HRESULT GetCount(TLENUMF flags, uint32* pcEntries) mut => VT.[Friend]GetCount(&this, flags, pcEntries);

	public HRESULT RemoveEntry(ITravelLogEntry* ptle) mut => VT.[Friend]RemoveEntry(&this, ptle);

	public HRESULT GetRelativeEntry(int32 iOffset, ITravelLogEntry** ptle) mut => VT.[Friend]GetRelativeEntry(&this, iOffset, ptle);
}

[CRepr]struct IHlink : IUnknown
{
	public new const Guid IID = .(0x79eac9c3, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkSite* pihlSite, uint32 dwSiteData) SetHlinkSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkSite** ppihlSite, uint32* pdwSiteData) GetHlinkSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLSETF, IMoniker* pimkTarget, PWSTR pwzLocation) SetMonikerReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWhichRef, IMoniker** ppimkTarget, PWSTR* ppwzLocation) GetMonikerReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLSETF, PWSTR pwzTarget, PWSTR pwzLocation) SetStringReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWhichRef, PWSTR* ppwzTarget, PWSTR* ppwzLocation) GetStringReference;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzFriendlyName) SetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLFNAMEF, PWSTR* ppwzFriendlyName) GetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzTargetFrameName) SetTargetFrameName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwzTargetFrameName) GetTargetFrameName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwStatus) GetMiscStatus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLNF, IBindCtx* pibc, IBindStatusCallback* pibsc, IHlinkBrowseContext* pihlbc) Navigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzAdditionalParams) SetAdditionalParams;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppwzAdditionalParams) GetAdditionalParams;
	}


	public HRESULT SetHlinkSite(IHlinkSite* pihlSite, uint32 dwSiteData) mut => VT.[Friend]SetHlinkSite(&this, pihlSite, dwSiteData);

	public HRESULT GetHlinkSite(IHlinkSite** ppihlSite, uint32* pdwSiteData) mut => VT.[Friend]GetHlinkSite(&this, ppihlSite, pdwSiteData);

	public HRESULT SetMonikerReference(uint32 grfHLSETF, IMoniker* pimkTarget, PWSTR pwzLocation) mut => VT.[Friend]SetMonikerReference(&this, grfHLSETF, pimkTarget, pwzLocation);

	public HRESULT GetMonikerReference(uint32 dwWhichRef, IMoniker** ppimkTarget, PWSTR* ppwzLocation) mut => VT.[Friend]GetMonikerReference(&this, dwWhichRef, ppimkTarget, ppwzLocation);

	public HRESULT SetStringReference(uint32 grfHLSETF, PWSTR pwzTarget, PWSTR pwzLocation) mut => VT.[Friend]SetStringReference(&this, grfHLSETF, pwzTarget, pwzLocation);

	public HRESULT GetStringReference(uint32 dwWhichRef, PWSTR* ppwzTarget, PWSTR* ppwzLocation) mut => VT.[Friend]GetStringReference(&this, dwWhichRef, ppwzTarget, ppwzLocation);

	public HRESULT SetFriendlyName(PWSTR pwzFriendlyName) mut => VT.[Friend]SetFriendlyName(&this, pwzFriendlyName);

	public HRESULT GetFriendlyName(uint32 grfHLFNAMEF, PWSTR* ppwzFriendlyName) mut => VT.[Friend]GetFriendlyName(&this, grfHLFNAMEF, ppwzFriendlyName);

	public HRESULT SetTargetFrameName(PWSTR pwzTargetFrameName) mut => VT.[Friend]SetTargetFrameName(&this, pwzTargetFrameName);

	public HRESULT GetTargetFrameName(PWSTR* ppwzTargetFrameName) mut => VT.[Friend]GetTargetFrameName(&this, ppwzTargetFrameName);

	public HRESULT GetMiscStatus(uint32* pdwStatus) mut => VT.[Friend]GetMiscStatus(&this, pdwStatus);

	public HRESULT Navigate(uint32 grfHLNF, IBindCtx* pibc, IBindStatusCallback* pibsc, IHlinkBrowseContext* pihlbc) mut => VT.[Friend]Navigate(&this, grfHLNF, pibc, pibsc, pihlbc);

	public HRESULT SetAdditionalParams(PWSTR pwzAdditionalParams) mut => VT.[Friend]SetAdditionalParams(&this, pwzAdditionalParams);

	public HRESULT GetAdditionalParams(PWSTR* ppwzAdditionalParams) mut => VT.[Friend]GetAdditionalParams(&this, ppwzAdditionalParams);
}

[CRepr]struct IHlinkSite : IUnknown
{
	public new const Guid IID = .(0x79eac9c2, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSiteData, in Guid guidService, in Guid riid, IUnknown** ppiunk) QueryService;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSiteData, uint32 dwAssign, uint32 dwWhich, IMoniker** ppimk) GetMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSiteData, uint32 dwReserved) ReadyToNavigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwSiteData, uint32 dwreserved, HRESULT hrError, PWSTR pwzError) OnNavigationComplete;
	}


	public HRESULT QueryService(uint32 dwSiteData, in Guid guidService, in Guid riid, IUnknown** ppiunk) mut => VT.[Friend]QueryService(&this, dwSiteData, guidService, riid, ppiunk);

	public HRESULT GetMoniker(uint32 dwSiteData, uint32 dwAssign, uint32 dwWhich, IMoniker** ppimk) mut => VT.[Friend]GetMoniker(&this, dwSiteData, dwAssign, dwWhich, ppimk);

	public HRESULT ReadyToNavigate(uint32 dwSiteData, uint32 dwReserved) mut => VT.[Friend]ReadyToNavigate(&this, dwSiteData, dwReserved);

	public HRESULT OnNavigationComplete(uint32 dwSiteData, uint32 dwreserved, HRESULT hrError, PWSTR pwzError) mut => VT.[Friend]OnNavigationComplete(&this, dwSiteData, dwreserved, hrError, pwzError);
}

[CRepr]struct IHlinkTarget : IUnknown
{
	public new const Guid IID = .(0x79eac9c4, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkBrowseContext* pihlbc) SetBrowseContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkBrowseContext** ppihlbc) GetBrowseContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLNF, PWSTR pwzJumpLocation) Navigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzLocation, uint32 dwAssign, IMoniker** ppimkLocation) GetMoniker;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzLocation, PWSTR* ppwzFriendlyName) GetFriendlyName;
	}


	public HRESULT SetBrowseContext(IHlinkBrowseContext* pihlbc) mut => VT.[Friend]SetBrowseContext(&this, pihlbc);

	public HRESULT GetBrowseContext(IHlinkBrowseContext** ppihlbc) mut => VT.[Friend]GetBrowseContext(&this, ppihlbc);

	public HRESULT Navigate(uint32 grfHLNF, PWSTR pwzJumpLocation) mut => VT.[Friend]Navigate(&this, grfHLNF, pwzJumpLocation);

	public HRESULT GetMoniker(PWSTR pwzLocation, uint32 dwAssign, IMoniker** ppimkLocation) mut => VT.[Friend]GetMoniker(&this, pwzLocation, dwAssign, ppimkLocation);

	public HRESULT GetFriendlyName(PWSTR pwzLocation, PWSTR* ppwzFriendlyName) mut => VT.[Friend]GetFriendlyName(&this, pwzLocation, ppwzFriendlyName);
}

[CRepr]struct IHlinkFrame : IUnknown
{
	public new const Guid IID = .(0x79eac9c5, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkBrowseContext* pihlbc) SetBrowseContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHlinkBrowseContext** ppihlbc) GetBrowseContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLNF, IBindCtx* pbc, IBindStatusCallback* pibsc, IHlink* pihlNavigate) Navigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLNF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, uint32 dwreserved) OnNavigate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uHLID, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) UpdateHlink;
	}


	public HRESULT SetBrowseContext(IHlinkBrowseContext* pihlbc) mut => VT.[Friend]SetBrowseContext(&this, pihlbc);

	public HRESULT GetBrowseContext(IHlinkBrowseContext** ppihlbc) mut => VT.[Friend]GetBrowseContext(&this, ppihlbc);

	public HRESULT Navigate(uint32 grfHLNF, IBindCtx* pbc, IBindStatusCallback* pibsc, IHlink* pihlNavigate) mut => VT.[Friend]Navigate(&this, grfHLNF, pbc, pibsc, pihlNavigate);

	public HRESULT OnNavigate(uint32 grfHLNF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, uint32 dwreserved) mut => VT.[Friend]OnNavigate(&this, grfHLNF, pimkTarget, pwzLocation, pwzFriendlyName, dwreserved);

	public HRESULT UpdateHlink(uint32 uHLID, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) mut => VT.[Friend]UpdateHlink(&this, uHLID, pimkTarget, pwzLocation, pwzFriendlyName);
}

[CRepr]struct IEnumHLITEM : IUnknown
{
	public new const Guid IID = .(0x79eac9c6, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, HLITEM* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumHLITEM** ppienumhlitem) Clone;
	}


	public HRESULT Next(uint32 celt, HLITEM* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumHLITEM** ppienumhlitem) mut => VT.[Friend]Clone(&this, ppienumhlitem);
}

[CRepr]struct IHlinkBrowseContext : IUnknown
{
	public new const Guid IID = .(0x79eac9c7, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 reserved, IUnknown* piunk, IMoniker* pimk, uint32* pdwRegister) Register;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pimk, BOOL fBindIfRootRegistered, IUnknown** ppiunk) GetObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwRegister) Revoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HLBWINFO* phlbwi) SetBrowseWindowInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HLBWINFO* phlbwi) GetBrowseWindowInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) SetInitialHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLNF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, uint32* puHLID) OnNavigateHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uHLID, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) UpdateHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwReserved, uint32 grfHLFNAMEF, IEnumHLITEM** ppienumhlitem) EnumNavigationStack;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 grfHLQF, uint32 uHLID) QueryHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uHLID, IHlink** ppihl) GetHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uHLID) SetCurrentHlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piunkOuter, in Guid riid, IUnknown** ppiunkObj) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 reserved) Close;
	}


	public HRESULT Register(uint32 reserved, IUnknown* piunk, IMoniker* pimk, uint32* pdwRegister) mut => VT.[Friend]Register(&this, reserved, piunk, pimk, pdwRegister);

	public HRESULT GetObject(IMoniker* pimk, BOOL fBindIfRootRegistered, IUnknown** ppiunk) mut => VT.[Friend]GetObject(&this, pimk, fBindIfRootRegistered, ppiunk);

	public HRESULT Revoke(uint32 dwRegister) mut => VT.[Friend]Revoke(&this, dwRegister);

	public HRESULT SetBrowseWindowInfo(HLBWINFO* phlbwi) mut => VT.[Friend]SetBrowseWindowInfo(&this, phlbwi);

	public HRESULT GetBrowseWindowInfo(HLBWINFO* phlbwi) mut => VT.[Friend]GetBrowseWindowInfo(&this, phlbwi);

	public HRESULT SetInitialHlink(IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) mut => VT.[Friend]SetInitialHlink(&this, pimkTarget, pwzLocation, pwzFriendlyName);

	public HRESULT OnNavigateHlink(uint32 grfHLNF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, uint32* puHLID) mut => VT.[Friend]OnNavigateHlink(&this, grfHLNF, pimkTarget, pwzLocation, pwzFriendlyName, puHLID);

	public HRESULT UpdateHlink(uint32 uHLID, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName) mut => VT.[Friend]UpdateHlink(&this, uHLID, pimkTarget, pwzLocation, pwzFriendlyName);

	public HRESULT EnumNavigationStack(uint32 dwReserved, uint32 grfHLFNAMEF, IEnumHLITEM** ppienumhlitem) mut => VT.[Friend]EnumNavigationStack(&this, dwReserved, grfHLFNAMEF, ppienumhlitem);

	public HRESULT QueryHlink(uint32 grfHLQF, uint32 uHLID) mut => VT.[Friend]QueryHlink(&this, grfHLQF, uHLID);

	public HRESULT GetHlink(uint32 uHLID, IHlink** ppihl) mut => VT.[Friend]GetHlink(&this, uHLID, ppihl);

	public HRESULT SetCurrentHlink(uint32 uHLID) mut => VT.[Friend]SetCurrentHlink(&this, uHLID);

	public HRESULT Clone(IUnknown* piunkOuter, in Guid riid, IUnknown** ppiunkObj) mut => VT.[Friend]Clone(&this, piunkOuter, riid, ppiunkObj);

	public HRESULT Close(uint32 reserved) mut => VT.[Friend]Close(&this, reserved);
}

[CRepr]struct IExtensionServices : IUnknown
{
	public new const Guid IID = .(0x79eac9cb, 0xbaf9, 0x11ce, 0x8c, 0x82, 0x00, 0xaa, 0x00, 0x4b, 0xa9, 0x0b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pwzAdditionalHeaders) SetAdditionalHeaders;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND phwnd, PWSTR pwzUsername, PWSTR pwzPassword) SetAuthenticateData;
	}


	public HRESULT SetAdditionalHeaders(PWSTR pwzAdditionalHeaders) mut => VT.[Friend]SetAdditionalHeaders(&this, pwzAdditionalHeaders);

	public HRESULT SetAuthenticateData(HWND phwnd, PWSTR pwzUsername, PWSTR pwzPassword) mut => VT.[Friend]SetAuthenticateData(&this, phwnd, pwzUsername, pwzPassword);
}

[CRepr]struct ITravelEntry : IUnknown
{
	public new const Guid IID = .(0xf46edb3b, 0xbc2f, 0x11d0, 0x94, 0x12, 0x00, 0xaa, 0x00, 0xa3, 0xeb, 0xd3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk) Invoke;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, BOOL fIsLocalAnchor) Update;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetPidl;
	}


	public HRESULT Invoke(IUnknown* punk) mut => VT.[Friend]Invoke(&this, punk);

	public HRESULT Update(IUnknown* punk, BOOL fIsLocalAnchor) mut => VT.[Friend]Update(&this, punk, fIsLocalAnchor);

	public HRESULT GetPidl(ITEMIDLIST** ppidl) mut => VT.[Friend]GetPidl(&this, ppidl);
}

[CRepr]struct ITravelLog : IUnknown
{
	public new const Guid IID = .(0x66a9cb08, 0x4802, 0x11d2, 0xa5, 0x61, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, BOOL fIsLocalAnchor) AddEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, BOOL fIsLocalAnchor) UpdateEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, IUnknown* punkHLBrowseContext) UpdateExternal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, int32 iOffset) Travel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, int32 iOffset, ITravelEntry** ppte) GetTravelEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, ITEMIDLIST* pidl, ITravelEntry** ppte) FindTravelEntry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, int32 iOffset, int32 idsTemplate, char16* pwzText, uint32 cchText) GetToolTipText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punk, HMENU hmenu, int32 nPos, int32 idFirst, int32 idLast, uint32 dwFlags) InsertMenuEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITravelLog** pptl) Clone;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, IUnknown* punk) CountEntries;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Revert;
	}


	public HRESULT AddEntry(IUnknown* punk, BOOL fIsLocalAnchor) mut => VT.[Friend]AddEntry(&this, punk, fIsLocalAnchor);

	public HRESULT UpdateEntry(IUnknown* punk, BOOL fIsLocalAnchor) mut => VT.[Friend]UpdateEntry(&this, punk, fIsLocalAnchor);

	public HRESULT UpdateExternal(IUnknown* punk, IUnknown* punkHLBrowseContext) mut => VT.[Friend]UpdateExternal(&this, punk, punkHLBrowseContext);

	public HRESULT Travel(IUnknown* punk, int32 iOffset) mut => VT.[Friend]Travel(&this, punk, iOffset);

	public HRESULT GetTravelEntry(IUnknown* punk, int32 iOffset, ITravelEntry** ppte) mut => VT.[Friend]GetTravelEntry(&this, punk, iOffset, ppte);

	public HRESULT FindTravelEntry(IUnknown* punk, ITEMIDLIST* pidl, ITravelEntry** ppte) mut => VT.[Friend]FindTravelEntry(&this, punk, pidl, ppte);

	public HRESULT GetToolTipText(IUnknown* punk, int32 iOffset, int32 idsTemplate, char16* pwzText, uint32 cchText) mut => VT.[Friend]GetToolTipText(&this, punk, iOffset, idsTemplate, pwzText, cchText);

	public HRESULT InsertMenuEntries(IUnknown* punk, HMENU hmenu, int32 nPos, int32 idFirst, int32 idLast, uint32 dwFlags) mut => VT.[Friend]InsertMenuEntries(&this, punk, hmenu, nPos, idFirst, idLast, dwFlags);

	public HRESULT Clone(ITravelLog** pptl) mut => VT.[Friend]Clone(&this, pptl);

	public uint32 CountEntries(IUnknown* punk) mut => VT.[Friend]CountEntries(&this, punk);

	public HRESULT Revert() mut => VT.[Friend]Revert(&this);
}

[CRepr]struct CIE4ConnectionPoint : IConnectionPoint
{
	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConnectionPoint.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pf, void** ppv, int32 dispid, DISPPARAMS* pdispparams) DoInvokeIE4;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispid, ITEMIDLIST* pidl, BOOL fCanCancel) DoInvokePIDLIE4;
	}


	public HRESULT DoInvokeIE4(BOOL* pf, void** ppv, int32 dispid, DISPPARAMS* pdispparams) mut => VT.[Friend]DoInvokeIE4(&this, pf, ppv, dispid, pdispparams);

	public HRESULT DoInvokePIDLIE4(int32 dispid, ITEMIDLIST* pidl, BOOL fCanCancel) mut => VT.[Friend]DoInvokePIDLIE4(&this, dispid, pidl, fCanCancel);
}

[CRepr]struct IExpDispSupportXP : IUnknown
{
	public new const Guid IID = .(0x2f0dd58c, 0xf789, 0x4f14, 0x99, 0xfb, 0x92, 0x93, 0xb3, 0xc9, 0xc2, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, CIE4ConnectionPoint** ppccp) FindCIE4ConnectionPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, uint32 grfModifiers) OnTranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispidMember, in Guid iid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pVarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) OnInvoke;
	}


	public HRESULT FindCIE4ConnectionPoint(in Guid riid, CIE4ConnectionPoint** ppccp) mut => VT.[Friend]FindCIE4ConnectionPoint(&this, riid, ppccp);

	public HRESULT OnTranslateAccelerator(MSG* pMsg, uint32 grfModifiers) mut => VT.[Friend]OnTranslateAccelerator(&this, pMsg, grfModifiers);

	public HRESULT OnInvoke(int32 dispidMember, in Guid iid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pVarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) mut => VT.[Friend]OnInvoke(&this, dispidMember, iid, lcid, wFlags, pdispparams, pVarResult, pexcepinfo, puArgErr);
}

[CRepr]struct IExpDispSupport : IUnknown
{
	public new const Guid IID = .(0x0d7d1d00, 0x6fc0, 0x11d0, 0xa9, 0x74, 0x00, 0xc0, 0x4f, 0xd7, 0x05, 0xa2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, IConnectionPoint** ppccp) FindConnectionPoint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pMsg, uint32 grfModifiers) OnTranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 dispidMember, in Guid iid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pVarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) OnInvoke;
	}


	public HRESULT FindConnectionPoint(in Guid riid, IConnectionPoint** ppccp) mut => VT.[Friend]FindConnectionPoint(&this, riid, ppccp);

	public HRESULT OnTranslateAccelerator(MSG* pMsg, uint32 grfModifiers) mut => VT.[Friend]OnTranslateAccelerator(&this, pMsg, grfModifiers);

	public HRESULT OnInvoke(int32 dispidMember, in Guid iid, uint32 lcid, uint16 wFlags, DISPPARAMS* pdispparams, VARIANT* pVarResult, EXCEPINFO* pexcepinfo, uint32* puArgErr) mut => VT.[Friend]OnInvoke(&this, dispidMember, iid, lcid, wFlags, pdispparams, pVarResult, pexcepinfo, puArgErr);
}

[CRepr]struct IBrowserService : IUnknown
{
	public new const Guid IID = .(0x02ba3b52, 0x0547, 0x11d1, 0xb8, 0x33, 0x00, 0xc0, 0x4f, 0xc9, 0xb3, 0x1f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleInPlaceSite** ppipsite) GetParentSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv, PWSTR pszName) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv, char16* pszName, uint32 cchName) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject** ppobjv) GetOleObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITravelLog** pptl) GetTravelLog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 id, BOOL fShow) ShowControlWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 id, BOOL* pfShown) IsControlWindowShown;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, PWSTR pwszName, uint32 uFlags) IEGetDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCP, PWSTR pwszPath, ITEMIDLIST** ppidlOut) IEParseDisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hres, PWSTR pwszPath) DisplayParseError;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 grfHLNF) NavigateToPidl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BNSTATE bnstate) SetNavigateState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BNSTATE* pbnstate) GetNavigateState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv, ITEMIDLIST* pidl, BOOL* pfDidBrowse) NotifyRedirect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateWindowList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) UpdateBackForwardState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags, uint32 dwFlagMask) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CanNavigateNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST** ppidl) GetPidl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) SetReferrer;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetBrowserIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwID, IUnknown** ppunk) GetBrowserByIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject** ppole, IStream** pstm, IBindCtx** ppbc) GetHistoryObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject* pole, BOOL fIsLocalAnchor) SetHistoryObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IOleObject* pole) CacheOLEServer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* pvarIn, VARIANT* pvarOut) GetSetCodePage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv, BOOL fDone, VARIANT* pvarargIn, VARIANT* pvarargOut) OnHttpEquiv;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPALETTE* hpal) GetPalette;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForceRegister, int32 swc) RegisterWindow;
	}


	public HRESULT GetParentSite(IOleInPlaceSite** ppipsite) mut => VT.[Friend]GetParentSite(&this, ppipsite);

	public HRESULT SetTitle(IShellView* psv, PWSTR pszName) mut => VT.[Friend]SetTitle(&this, psv, pszName);

	public HRESULT GetTitle(IShellView* psv, char16* pszName, uint32 cchName) mut => VT.[Friend]GetTitle(&this, psv, pszName, cchName);

	public HRESULT GetOleObject(IOleObject** ppobjv) mut => VT.[Friend]GetOleObject(&this, ppobjv);

	public HRESULT GetTravelLog(ITravelLog** pptl) mut => VT.[Friend]GetTravelLog(&this, pptl);

	public HRESULT ShowControlWindow(uint32 id, BOOL fShow) mut => VT.[Friend]ShowControlWindow(&this, id, fShow);

	public HRESULT IsControlWindowShown(uint32 id, BOOL* pfShown) mut => VT.[Friend]IsControlWindowShown(&this, id, pfShown);

	public HRESULT IEGetDisplayName(ITEMIDLIST* pidl, PWSTR pwszName, uint32 uFlags) mut => VT.[Friend]IEGetDisplayName(&this, pidl, pwszName, uFlags);

	public HRESULT IEParseDisplayName(uint32 uiCP, PWSTR pwszPath, ITEMIDLIST** ppidlOut) mut => VT.[Friend]IEParseDisplayName(&this, uiCP, pwszPath, ppidlOut);

	public HRESULT DisplayParseError(HRESULT hres, PWSTR pwszPath) mut => VT.[Friend]DisplayParseError(&this, hres, pwszPath);

	public HRESULT NavigateToPidl(ITEMIDLIST* pidl, uint32 grfHLNF) mut => VT.[Friend]NavigateToPidl(&this, pidl, grfHLNF);

	public HRESULT SetNavigateState(BNSTATE bnstate) mut => VT.[Friend]SetNavigateState(&this, bnstate);

	public HRESULT GetNavigateState(BNSTATE* pbnstate) mut => VT.[Friend]GetNavigateState(&this, pbnstate);

	public HRESULT NotifyRedirect(IShellView* psv, ITEMIDLIST* pidl, BOOL* pfDidBrowse) mut => VT.[Friend]NotifyRedirect(&this, psv, pidl, pfDidBrowse);

	public HRESULT UpdateWindowList() mut => VT.[Friend]UpdateWindowList(&this);

	public HRESULT UpdateBackForwardState() mut => VT.[Friend]UpdateBackForwardState(&this);

	public HRESULT SetFlags(uint32 dwFlags, uint32 dwFlagMask) mut => VT.[Friend]SetFlags(&this, dwFlags, dwFlagMask);

	public HRESULT GetFlags(uint32* pdwFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwFlags);

	public HRESULT CanNavigateNow() mut => VT.[Friend]CanNavigateNow(&this);

	public HRESULT GetPidl(ITEMIDLIST** ppidl) mut => VT.[Friend]GetPidl(&this, ppidl);

	public HRESULT SetReferrer(ITEMIDLIST* pidl) mut => VT.[Friend]SetReferrer(&this, pidl);

	public uint32 GetBrowserIndex() mut => VT.[Friend]GetBrowserIndex(&this);

	public HRESULT GetBrowserByIndex(uint32 dwID, IUnknown** ppunk) mut => VT.[Friend]GetBrowserByIndex(&this, dwID, ppunk);

	public HRESULT GetHistoryObject(IOleObject** ppole, IStream** pstm, IBindCtx** ppbc) mut => VT.[Friend]GetHistoryObject(&this, ppole, pstm, ppbc);

	public HRESULT SetHistoryObject(IOleObject* pole, BOOL fIsLocalAnchor) mut => VT.[Friend]SetHistoryObject(&this, pole, fIsLocalAnchor);

	public HRESULT CacheOLEServer(IOleObject* pole) mut => VT.[Friend]CacheOLEServer(&this, pole);

	public HRESULT GetSetCodePage(VARIANT* pvarIn, VARIANT* pvarOut) mut => VT.[Friend]GetSetCodePage(&this, pvarIn, pvarOut);

	public HRESULT OnHttpEquiv(IShellView* psv, BOOL fDone, VARIANT* pvarargIn, VARIANT* pvarargOut) mut => VT.[Friend]OnHttpEquiv(&this, psv, fDone, pvarargIn, pvarargOut);

	public HRESULT GetPalette(HPALETTE* hpal) mut => VT.[Friend]GetPalette(&this, hpal);

	public HRESULT RegisterWindow(BOOL fForceRegister, int32 swc) mut => VT.[Friend]RegisterWindow(&this, fForceRegister, swc);
}

[CRepr]struct IShellService : IUnknown
{
	public new const Guid IID = .(0x5836fb00, 0x8187, 0x11cf, 0xa1, 0x2b, 0x00, 0xaa, 0x00, 0x4a, 0xe8, 0x37);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkOwner) SetOwner;
	}


	public HRESULT SetOwner(IUnknown* punkOwner) mut => VT.[Friend]SetOwner(&this, punkOwner);
}

[CRepr]struct IBrowserService2 : IBrowserService
{
	public new const Guid IID = .(0x68bd21cc, 0x438b, 0x11d2, 0xa5, 0x60, 0x00, 0xa0, 0xc9, 0x2d, 0xbf, 0xe8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBrowserService.VTable
	{
		protected new function [CallingConvention(.Stdcall)] LRESULT(SelfOuter* self, HWND hwnd, uint32 uMsg, WPARAM wParam, LPARAM lParam) WndProcBS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetAsDefFolderSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) GetViewRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WPARAM wParam) OnSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CREATESTRUCTW* pcs) OnCreate;
		protected new function [CallingConvention(.Stdcall)] LRESULT(SelfOuter* self, WPARAM wParam, LPARAM lParam) OnCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnDestroy;
		protected new function [CallingConvention(.Stdcall)] LRESULT(SelfOuter* self, NMHDR* pnm) OnNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnSetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fActive) OnFrameWindowActivateBS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ReleaseShellView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) ActivatePendingView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psvNew, IShellView* psvOld, RECT* prcView, HWND* phwnd) CreateViewWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) CreateBrowserPropSheetExt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwndView) GetViewWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BASEBROWSERDATALH** pbbd) GetBaseBrowserData;
		protected new function [CallingConvention(.Stdcall)] BASEBROWSERDATALH*(SelfOuter* self) PutBaseBrowserData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITravelLog* ptl, uint32 dw) InitializeTravelLog;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SetTopBrowser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iCmd) Offline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL f) AllowViewResize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 u) SetActivateState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 eSecureLock) UpdateSecureLockIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeDownloadManager;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) InitializeTransitionSite;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, IUnknown* pauto) _Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _CancelPendingNavigationAsync;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _CancelPendingView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _MaySaveChanges;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fPaused) _PauseOrResumeView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _DisableModeless;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl, uint32 grfHLNF, uint32 dwFlags) _NavigateToPidl2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellView* psv, ITEMIDLIST* pidlNew) _TryShell2Rename;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _SwitchActivationNow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkBar, BOOL fBroadcast, Guid* pguidCmdGroup, uint32 nCmdID, uint32 nCmdexecopt, VARIANT* pvarargIn, VARIANT* pvarargOut) _ExecChildren;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndBar, BOOL fBroadcast, uint32 uMsg, WPARAM wParam, LPARAM lParam) _SendChildren;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FOLDERSETDATA* pfsd) GetFolderSetData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itb) _OnFocusChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fChildOnly) v_ShowHideChildWindows;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) _get_itbLastFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itbLastFocus) _put_itbLastFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uState) _UIActivateView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* prc) _GetViewBorderRect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _UpdateViewRectSize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itb) _ResizeNextBorder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _ResizeView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT* lprectBorder, HMONITOR hmon) _GetEffectiveClientArea;
		protected new function [CallingConvention(.Stdcall)] IStream*(SelfOuter* self, ITEMIDLIST* pidl, uint32 grfMode, PWSTR pwszName) v_GetViewStream;
		protected new function [CallingConvention(.Stdcall)] LRESULT(SelfOuter* self, uint32 uMsg, WPARAM wParam, LPARAM lParam) ForwardViewMsg;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HACCEL hacc) SetAcceleratorMenu;
		protected new function [CallingConvention(.Stdcall)] int32(SelfOuter* self) _GetToolbarCount;
		protected new function [CallingConvention(.Stdcall)] TOOLBARITEM*(SelfOuter* self, int32 itb) _GetToolbarItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm) _SaveToolbars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pstm) _LoadToolbars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fClose) _CloseAndReleaseToolbars;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* lpMsg, uint32 itbNext, int32 citb, TOOLBARITEM** pptbi, HWND* phwnd) v_MayGetNextToolbarFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 itb, BOOL bUseHmonitor) _ResizeNextBorderHelper;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self, IUnknown* punkSrc) _FindTBar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, TOOLBARITEM* ptbi, HWND hwnd, MSG* lpMsg) _SetFocus;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MSG* pmsg) v_MayTranslateAccelerator;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* punkSrc, RECT* lprectBorder, BOOL bUseHmonitor) _GetBorderDWHelper;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ITEMIDLIST* pidl) v_CheckZoneCrossing;
	}


	public LRESULT WndProcBS(HWND hwnd, uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]WndProcBS(&this, hwnd, uMsg, wParam, lParam);

	public HRESULT SetAsDefFolderSettings() mut => VT.[Friend]SetAsDefFolderSettings(&this);

	public HRESULT GetViewRect(RECT* prc) mut => VT.[Friend]GetViewRect(&this, prc);

	public HRESULT OnSize(WPARAM wParam) mut => VT.[Friend]OnSize(&this, wParam);

	public HRESULT OnCreate(CREATESTRUCTW* pcs) mut => VT.[Friend]OnCreate(&this, pcs);

	public LRESULT OnCommand(WPARAM wParam, LPARAM lParam) mut => VT.[Friend]OnCommand(&this, wParam, lParam);

	public HRESULT OnDestroy() mut => VT.[Friend]OnDestroy(&this);

	public LRESULT OnNotify(NMHDR* pnm) mut => VT.[Friend]OnNotify(&this, pnm);

	public HRESULT OnSetFocus() mut => VT.[Friend]OnSetFocus(&this);

	public HRESULT OnFrameWindowActivateBS(BOOL fActive) mut => VT.[Friend]OnFrameWindowActivateBS(&this, fActive);

	public HRESULT ReleaseShellView() mut => VT.[Friend]ReleaseShellView(&this);

	public HRESULT ActivatePendingView() mut => VT.[Friend]ActivatePendingView(&this);

	public HRESULT CreateViewWindow(IShellView* psvNew, IShellView* psvOld, RECT* prcView, HWND* phwnd) mut => VT.[Friend]CreateViewWindow(&this, psvNew, psvOld, prcView, phwnd);

	public HRESULT CreateBrowserPropSheetExt(in Guid riid, void** ppv) mut => VT.[Friend]CreateBrowserPropSheetExt(&this, riid, ppv);

	public HRESULT GetViewWindow(HWND* phwndView) mut => VT.[Friend]GetViewWindow(&this, phwndView);

	public HRESULT GetBaseBrowserData(BASEBROWSERDATALH** pbbd) mut => VT.[Friend]GetBaseBrowserData(&this, pbbd);

	public BASEBROWSERDATALH* PutBaseBrowserData() mut => VT.[Friend]PutBaseBrowserData(&this);

	public HRESULT InitializeTravelLog(ITravelLog* ptl, uint32 dw) mut => VT.[Friend]InitializeTravelLog(&this, ptl, dw);

	public HRESULT SetTopBrowser() mut => VT.[Friend]SetTopBrowser(&this);

	public HRESULT Offline(int32 iCmd) mut => VT.[Friend]Offline(&this, iCmd);

	public HRESULT AllowViewResize(BOOL f) mut => VT.[Friend]AllowViewResize(&this, f);

	public HRESULT SetActivateState(uint32 u) mut => VT.[Friend]SetActivateState(&this, u);

	public HRESULT UpdateSecureLockIcon(int32 eSecureLock) mut => VT.[Friend]UpdateSecureLockIcon(&this, eSecureLock);

	public HRESULT InitializeDownloadManager() mut => VT.[Friend]InitializeDownloadManager(&this);

	public HRESULT InitializeTransitionSite() mut => VT.[Friend]InitializeTransitionSite(&this);

	public HRESULT _Initialize(HWND hwnd, IUnknown* pauto) mut => VT.[Friend]_Initialize(&this, hwnd, pauto);

	public HRESULT _CancelPendingNavigationAsync() mut => VT.[Friend]_CancelPendingNavigationAsync(&this);

	public HRESULT _CancelPendingView() mut => VT.[Friend]_CancelPendingView(&this);

	public HRESULT _MaySaveChanges() mut => VT.[Friend]_MaySaveChanges(&this);

	public HRESULT _PauseOrResumeView(BOOL fPaused) mut => VT.[Friend]_PauseOrResumeView(&this, fPaused);

	public HRESULT _DisableModeless() mut => VT.[Friend]_DisableModeless(&this);

	public HRESULT _NavigateToPidl2(ITEMIDLIST* pidl, uint32 grfHLNF, uint32 dwFlags) mut => VT.[Friend]_NavigateToPidl2(&this, pidl, grfHLNF, dwFlags);

	public HRESULT _TryShell2Rename(IShellView* psv, ITEMIDLIST* pidlNew) mut => VT.[Friend]_TryShell2Rename(&this, psv, pidlNew);

	public HRESULT _SwitchActivationNow() mut => VT.[Friend]_SwitchActivationNow(&this);

	public HRESULT _ExecChildren(IUnknown* punkBar, BOOL fBroadcast, Guid* pguidCmdGroup, uint32 nCmdID, uint32 nCmdexecopt, VARIANT* pvarargIn, VARIANT* pvarargOut) mut => VT.[Friend]_ExecChildren(&this, punkBar, fBroadcast, pguidCmdGroup, nCmdID, nCmdexecopt, pvarargIn, pvarargOut);

	public HRESULT _SendChildren(HWND hwndBar, BOOL fBroadcast, uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]_SendChildren(&this, hwndBar, fBroadcast, uMsg, wParam, lParam);

	public HRESULT GetFolderSetData(FOLDERSETDATA* pfsd) mut => VT.[Friend]GetFolderSetData(&this, pfsd);

	public HRESULT _OnFocusChange(uint32 itb) mut => VT.[Friend]_OnFocusChange(&this, itb);

	public HRESULT v_ShowHideChildWindows(BOOL fChildOnly) mut => VT.[Friend]v_ShowHideChildWindows(&this, fChildOnly);

	public uint32 _get_itbLastFocus() mut => VT.[Friend]_get_itbLastFocus(&this);

	public HRESULT _put_itbLastFocus(uint32 itbLastFocus) mut => VT.[Friend]_put_itbLastFocus(&this, itbLastFocus);

	public HRESULT _UIActivateView(uint32 uState) mut => VT.[Friend]_UIActivateView(&this, uState);

	public HRESULT _GetViewBorderRect(RECT* prc) mut => VT.[Friend]_GetViewBorderRect(&this, prc);

	public HRESULT _UpdateViewRectSize() mut => VT.[Friend]_UpdateViewRectSize(&this);

	public HRESULT _ResizeNextBorder(uint32 itb) mut => VT.[Friend]_ResizeNextBorder(&this, itb);

	public HRESULT _ResizeView() mut => VT.[Friend]_ResizeView(&this);

	public HRESULT _GetEffectiveClientArea(RECT* lprectBorder, HMONITOR hmon) mut => VT.[Friend]_GetEffectiveClientArea(&this, lprectBorder, hmon);

	public IStream* v_GetViewStream(ITEMIDLIST* pidl, uint32 grfMode, PWSTR pwszName) mut => VT.[Friend]v_GetViewStream(&this, pidl, grfMode, pwszName);

	public LRESULT ForwardViewMsg(uint32 uMsg, WPARAM wParam, LPARAM lParam) mut => VT.[Friend]ForwardViewMsg(&this, uMsg, wParam, lParam);

	public HRESULT SetAcceleratorMenu(HACCEL hacc) mut => VT.[Friend]SetAcceleratorMenu(&this, hacc);

	public int32 _GetToolbarCount() mut => VT.[Friend]_GetToolbarCount(&this);

	public TOOLBARITEM* _GetToolbarItem(int32 itb) mut => VT.[Friend]_GetToolbarItem(&this, itb);

	public HRESULT _SaveToolbars(IStream* pstm) mut => VT.[Friend]_SaveToolbars(&this, pstm);

	public HRESULT _LoadToolbars(IStream* pstm) mut => VT.[Friend]_LoadToolbars(&this, pstm);

	public HRESULT _CloseAndReleaseToolbars(BOOL fClose) mut => VT.[Friend]_CloseAndReleaseToolbars(&this, fClose);

	public HRESULT v_MayGetNextToolbarFocus(MSG* lpMsg, uint32 itbNext, int32 citb, TOOLBARITEM** pptbi, HWND* phwnd) mut => VT.[Friend]v_MayGetNextToolbarFocus(&this, lpMsg, itbNext, citb, pptbi, phwnd);

	public HRESULT _ResizeNextBorderHelper(uint32 itb, BOOL bUseHmonitor) mut => VT.[Friend]_ResizeNextBorderHelper(&this, itb, bUseHmonitor);

	public uint32 _FindTBar(IUnknown* punkSrc) mut => VT.[Friend]_FindTBar(&this, punkSrc);

	public HRESULT _SetFocus(TOOLBARITEM* ptbi, HWND hwnd, MSG* lpMsg) mut => VT.[Friend]_SetFocus(&this, ptbi, hwnd, lpMsg);

	public HRESULT v_MayTranslateAccelerator(MSG* pmsg) mut => VT.[Friend]v_MayTranslateAccelerator(&this, pmsg);

	public HRESULT _GetBorderDWHelper(IUnknown* punkSrc, RECT* lprectBorder, BOOL bUseHmonitor) mut => VT.[Friend]_GetBorderDWHelper(&this, punkSrc, lprectBorder, bUseHmonitor);

	public HRESULT v_CheckZoneCrossing(ITEMIDLIST* pidl) mut => VT.[Friend]v_CheckZoneCrossing(&this, pidl);
}

[CRepr]struct IBrowserService3 : IBrowserService2
{
	public new const Guid IID = .(0x27d7ce21, 0x762d, 0x48f3, 0x86, 0xf3, 0x40, 0xe2, 0xfd, 0x37, 0x49, 0xc4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBrowserService2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, RECT* prc) _PositionViewWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uiCP, PWSTR pwszPath, uint32 dwFlags, ITEMIDLIST** ppidlOut) IEParseDisplayNameEx;
	}


	public HRESULT _PositionViewWindow(HWND hwnd, RECT* prc) mut => VT.[Friend]_PositionViewWindow(&this, hwnd, prc);

	public HRESULT IEParseDisplayNameEx(uint32 uiCP, PWSTR pwszPath, uint32 dwFlags, ITEMIDLIST** ppidlOut) mut => VT.[Friend]IEParseDisplayNameEx(&this, uiCP, pwszPath, dwFlags, ppidlOut);
}

[CRepr]struct IBrowserService4 : IBrowserService3
{
	public new const Guid IID = .(0x639f1bff, 0xe135, 0x4096, 0xab, 0xd8, 0xe0, 0xf5, 0x04, 0xd6, 0x49, 0xa4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IBrowserService3.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fPendingView) ActivateView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveViewState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) _ResizeAllBorders;
	}


	public HRESULT ActivateView(BOOL fPendingView) mut => VT.[Friend]ActivateView(&this, fPendingView);

	public HRESULT SaveViewState() mut => VT.[Friend]SaveViewState(&this);

	public HRESULT _ResizeAllBorders() mut => VT.[Friend]_ResizeAllBorders(&this);
}

[CRepr]struct ITrackShellMenu : IShellMenu
{
	public new const Guid IID = .(0x8278f932, 0x2a3e, 0x11d2, 0x83, 0x8f, 0x00, 0xc0, 0x4f, 0xd9, 0x18, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IShellMenu.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndTB, IUnknown* punkBand, uint32 dwSMSetFlags) SetObscured;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwnd, POINTL* ppt, RECTL* prcExclude, int32 dwFlags) Popup;
	}


	public HRESULT SetObscured(HWND hwndTB, IUnknown* punkBand, uint32 dwSMSetFlags) mut => VT.[Friend]SetObscured(&this, hwndTB, punkBand, dwSMSetFlags);

	public HRESULT Popup(HWND hwnd, POINTL* ppt, RECTL* prcExclude, int32 dwFlags) mut => VT.[Friend]Popup(&this, hwnd, ppt, prcExclude, dwFlags);
}

[CRepr]struct ITranscodeImage : IUnknown
{
	public new const Guid IID = .(0xbae86ddd, 0xdc11, 0x421c, 0xb7, 0xab, 0xcc, 0x55, 0xd1, 0xd6, 0x5c, 0x44);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IShellItem* pShellItem, uint32 uiMaxWidth, uint32 uiMaxHeight, uint32 flags, IStream* pvImage, uint32* puiWidth, uint32* puiHeight) TranscodeImage;
	}


	public HRESULT TranscodeImage(IShellItem* pShellItem, uint32 uiMaxWidth, uint32 uiMaxHeight, uint32 flags, IStream* pvImage, uint32* puiWidth, uint32* puiHeight) mut => VT.[Friend]TranscodeImage(&this, pShellItem, uiMaxWidth, uiMaxHeight, flags, pvImage, puiWidth, puiHeight);
}

[CRepr]struct IUniformResourceLocatorA : IUnknown
{
	public new const Guid IID = .(0xfbf23b80, 0xe3f0, 0x101b, 0x84, 0x88, 0x00, 0xaa, 0x00, 0x3e, 0x56, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR pcszURL, uint32 dwInFlags) SetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR* ppszURL) GetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, URLINVOKECOMMANDINFOA* purlici) InvokeCommand;
	}


	public HRESULT SetURL(PSTR pcszURL, uint32 dwInFlags) mut => VT.[Friend]SetURL(&this, pcszURL, dwInFlags);

	public HRESULT GetURL(PSTR* ppszURL) mut => VT.[Friend]GetURL(&this, ppszURL);

	public HRESULT InvokeCommand(URLINVOKECOMMANDINFOA* purlici) mut => VT.[Friend]InvokeCommand(&this, purlici);
}

[CRepr]struct IUniformResourceLocatorW : IUnknown
{
	public new const Guid IID = .(0xcabb0da0, 0xda57, 0x11cf, 0x99, 0x74, 0x00, 0x20, 0xaf, 0xd7, 0x97, 0x62);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pcszURL, uint32 dwInFlags) SetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppszURL) GetURL;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, URLINVOKECOMMANDINFOW* purlici) InvokeCommand;
	}


	public HRESULT SetURL(PWSTR pcszURL, uint32 dwInFlags) mut => VT.[Friend]SetURL(&this, pcszURL, dwInFlags);

	public HRESULT GetURL(PWSTR* ppszURL) mut => VT.[Friend]GetURL(&this, ppszURL);

	public HRESULT InvokeCommand(URLINVOKECOMMANDINFOW* purlici) mut => VT.[Friend]InvokeCommand(&this, purlici);
}

[CRepr]struct IInputPaneAnimationCoordinator : IUnknown
{
	public new const Guid IID = .(0x2af16ba9, 0x2de5, 0x4b75, 0x82, 0xd9, 0x01, 0x37, 0x2a, 0xfb, 0xff, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* device, IDCompositionAnimation* animation) AddAnimation;
	}


	public HRESULT AddAnimation(IUnknown* device, IDCompositionAnimation* animation) mut => VT.[Friend]AddAnimation(&this, device, animation);
}

#endregion

#region Functions
public static
{
	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LoadUserProfileA(HANDLE hToken, PROFILEINFOA* lpProfileInfo);
	public static BOOL LoadUserProfile(HANDLE hToken, PROFILEINFOA* lpProfileInfo) => LoadUserProfileA(hToken, lpProfileInfo);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL LoadUserProfileW(HANDLE hToken, PROFILEINFOW* lpProfileInfo);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UnloadUserProfile(HANDLE hToken, HANDLE hProfile);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProfilesDirectoryA(uint8* lpProfileDir, uint32* lpcchSize);
	public static BOOL GetProfilesDirectory(uint8* lpProfileDir, uint32* lpcchSize) => GetProfilesDirectoryA(lpProfileDir, lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProfilesDirectoryW(char16* lpProfileDir, uint32* lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetProfileType(uint32* dwFlags);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteProfileA(PSTR lpSidString, PSTR lpProfilePath, PSTR lpComputerName);
	public static BOOL DeleteProfile(PSTR lpSidString, PSTR lpProfilePath, PSTR lpComputerName) => DeleteProfileA(lpSidString, lpProfilePath, lpComputerName);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DeleteProfileW(PWSTR lpSidString, PWSTR lpProfilePath, PWSTR lpComputerName);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CreateProfile(PWSTR pszUserSid, PWSTR pszUserName, char16* pszProfilePath, uint32 cchProfilePath);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultUserProfileDirectoryA(uint8* lpProfileDir, uint32* lpcchSize);
	public static BOOL GetDefaultUserProfileDirectory(uint8* lpProfileDir, uint32* lpcchSize) => GetDefaultUserProfileDirectoryA(lpProfileDir, lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetDefaultUserProfileDirectoryW(char16* lpProfileDir, uint32* lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAllUsersProfileDirectoryA(uint8* lpProfileDir, uint32* lpcchSize);
	public static BOOL GetAllUsersProfileDirectory(uint8* lpProfileDir, uint32* lpcchSize) => GetAllUsersProfileDirectoryA(lpProfileDir, lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetAllUsersProfileDirectoryW(char16* lpProfileDir, uint32* lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserProfileDirectoryA(HANDLE hToken, uint8* lpProfileDir, uint32* lpcchSize);
	public static BOOL GetUserProfileDirectory(HANDLE hToken, uint8* lpProfileDir, uint32* lpcchSize) => GetUserProfileDirectoryA(hToken, lpProfileDir, lpcchSize);

	[Import("USERENV.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetUserProfileDirectoryW(HANDLE hToken, char16* lpProfileDir, uint32* lpcchSize);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWindowSubclass(HWND hWnd, SUBCLASSPROC pfnSubclass, uint uIdSubclass, uint dwRefData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetWindowSubclass(HWND hWnd, SUBCLASSPROC pfnSubclass, uint uIdSubclass, uint* pdwRefData);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL RemoveWindowSubclass(HWND hWnd, SUBCLASSPROC pfnSubclass, uint uIdSubclass);

	[Import("COMCTL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT DefSubclassProc(HWND hWnd, uint32 uMsg, WPARAM wParam, LPARAM lParam);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetWindowContextHelpId(HWND param0, uint32 param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetWindowContextHelpId(HWND param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SetMenuContextHelpId(HMENU param0, uint32 param1);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetMenuContextHelpId(HMENU param0);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHelpA(HWND hWndMain, PSTR lpszHelp, uint32 uCommand, uint dwData);
	public static BOOL WinHelp(HWND hWndMain, PSTR lpszHelp, uint32 uCommand, uint dwData) => WinHelpA(hWndMain, lpszHelp, uCommand, dwData);

	[Import("USER32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WinHelpW(HWND hWndMain, PWSTR lpszHelp, uint32 uCommand, uint dwData);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* SHSimpleIDListFromPath(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateItemFromIDList(ITEMIDLIST* pidl, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateItemFromParsingName(PWSTR pszPath, IBindCtx* pbc, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateItemWithParent(ITEMIDLIST* pidlParent, IShellFolder* psfParent, ITEMIDLIST* pidl, in Guid riid, void** ppvItem);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateItemFromRelativeName(IShellItem* psiParent, PWSTR pszName, IBindCtx* pbc, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateItemInKnownFolder(in Guid kfid, uint32 dwKFFlags, PWSTR pszItem, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetIDListFromObject(IUnknown* punk, ITEMIDLIST** ppidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetItemFromObject(IUnknown* punk, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetNameFromIDList(ITEMIDLIST* pidl, SIGDN sigdnName, PWSTR* ppszName);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetItemFromDataObject(IDataObject* pdtobj, DATAOBJ_GET_ITEM_FLAGS dwFlags, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellItemArray(ITEMIDLIST* pidlParent, IShellFolder* psf, uint32 cidl, ITEMIDLIST** ppidl, IShellItemArray** ppsiItemArray);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellItemArrayFromDataObject(IDataObject* pdo, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellItemArrayFromIDLists(uint32 cidl, ITEMIDLIST** rgpidl, IShellItemArray** ppsiItemArray);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellItemArrayFromShellItem(IShellItem* psi, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateAssociationRegistration(in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateDefaultExtractIcon(in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SetCurrentProcessExplicitAppUserModelID(PWSTR AppID);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetCurrentProcessExplicitAppUserModelID(PWSTR* AppID);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetTemporaryPropertyForItem(IShellItem* psi, PROPERTYKEY* propkey, PROPVARIANT* ppropvar);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetTemporaryPropertyForItem(IShellItem* psi, PROPERTYKEY* propkey, PROPVARIANT* propvar);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHShowManageLibraryUI(IShellItem* psiLibrary, HWND hwndOwner, PWSTR pszTitle, PWSTR pszInstruction, LIBRARYMANAGEDIALOGOPTIONS lmdOptions);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHResolveLibrary(IShellItem* psiLibrary);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHAssocEnumHandlers(PWSTR pszExtra, ASSOC_FILTER afFilter, IEnumAssocHandlers** ppEnumHandler);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHAssocEnumHandlersForProtocolByApplication(PWSTR protocol, in Guid riid, void** enumHandlers);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HMONITOR_UserSize(uint32* param0, uint32 param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HMONITOR_UserMarshal(uint32* param0, uint8* param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HMONITOR_UserUnmarshal(uint32* param0, uint8* param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HMONITOR_UserFree(uint32* param0, HMONITOR* param1);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 HMONITOR_UserSize64(uint32* param0, uint32 param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HMONITOR_UserMarshal64(uint32* param0, uint8* param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint8* HMONITOR_UserUnmarshal64(uint32* param0, uint8* param1, HMONITOR* param2);

	[Import("OLE32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void HMONITOR_UserFree64(uint32* param0, HMONITOR* param1);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateDefaultPropertiesOp(IShellItem* psi, IFileOperation** ppFileOp);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetDefaultProperties(HWND hwnd, IShellItem* psi, uint32 dwFileOpFlags, IFileOperationProgressSink* pfops);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetMalloc(IMalloc** ppMalloc);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SHAlloc(uint cb);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHFree(void* pv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHGetIconOverlayIndexA(PSTR pszIconPath, int32 iIconIndex);
	public static int32 SHGetIconOverlayIndex(PSTR pszIconPath, int32 iIconIndex) => SHGetIconOverlayIndexA(pszIconPath, iIconIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHGetIconOverlayIndexW(PWSTR pszIconPath, int32 iIconIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILClone(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILCloneFirst(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILCombine(ITEMIDLIST* pidl1, ITEMIDLIST* pidl2);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ILFree(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILGetNext(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ILGetSize(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILFindChild(ITEMIDLIST* pidlParent, ITEMIDLIST* pidlChild);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILFindLastID(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ILRemoveLastID(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ILIsEqual(ITEMIDLIST* pidl1, ITEMIDLIST* pidl2);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ILIsParent(ITEMIDLIST* pidl1, ITEMIDLIST* pidl2, BOOL fImmediate);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ILSaveToStream(IStream* pstm, ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ILLoadFromStreamEx(IStream* pstm, ITEMIDLIST** pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILCreateFromPathA(PSTR pszPath);
	public static ITEMIDLIST* ILCreateFromPath(PSTR pszPath) => ILCreateFromPathA(pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILCreateFromPathW(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHILCreateFromPath(PWSTR pszPath, ITEMIDLIST** ppidl, uint32* rgfInOut);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* ILAppendID(ITEMIDLIST* pidl, SHITEMID* pmkid, BOOL fAppend);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetPathFromIDListEx(ITEMIDLIST* pidl, char16* pszPath, uint32 cchPath, GPFIDL_FLAGS uOpts);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetPathFromIDListA(ITEMIDLIST* pidl, uint8* pszPath);
	public static BOOL SHGetPathFromIDList(ITEMIDLIST* pidl, uint8* pszPath) => SHGetPathFromIDListA(pidl, pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetPathFromIDListW(ITEMIDLIST* pidl, char16* pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHCreateDirectory(HWND hwnd, PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHCreateDirectoryExA(HWND hwnd, PSTR pszPath, SECURITY_ATTRIBUTES* psa);
	public static int32 SHCreateDirectoryEx(HWND hwnd, PSTR pszPath, SECURITY_ATTRIBUTES* psa) => SHCreateDirectoryExA(hwnd, pszPath, psa);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHCreateDirectoryExW(HWND hwnd, PWSTR pszPath, SECURITY_ATTRIBUTES* psa);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHOpenFolderAndSelectItems(ITEMIDLIST* pidlFolder, uint32 cidl, ITEMIDLIST** apidl, uint32 dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellItem(ITEMIDLIST* pidlParent, IShellFolder* psfParent, ITEMIDLIST* pidl, IShellItem** ppsi);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetSpecialFolderLocation(HWND hwnd, int32 csidl, ITEMIDLIST** ppidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* SHCloneSpecialIDList(HWND hwnd, int32 csidl, BOOL fCreate);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetSpecialFolderPathA(HWND hwnd, uint8* pszPath, int32 csidl, BOOL fCreate);
	public static BOOL SHGetSpecialFolderPath(HWND hwnd, uint8* pszPath, int32 csidl, BOOL fCreate) => SHGetSpecialFolderPathA(hwnd, pszPath, csidl, fCreate);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetSpecialFolderPathW(HWND hwnd, char16* pszPath, int32 csidl, BOOL fCreate);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHFlushSFCache();

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetFolderPathA(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, uint8* pszPath);
	public static HRESULT SHGetFolderPath(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, uint8* pszPath) => SHGetFolderPathA(hwnd, csidl, hToken, dwFlags, pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetFolderPathW(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, char16* pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetFolderLocation(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, ITEMIDLIST** ppidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetFolderPathA(int32 csidl, HANDLE hToken, uint32 dwFlags, PSTR pszPath);
	public static HRESULT SHSetFolderPath(int32 csidl, HANDLE hToken, uint32 dwFlags, PSTR pszPath) => SHSetFolderPathA(csidl, hToken, dwFlags, pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetFolderPathW(int32 csidl, HANDLE hToken, uint32 dwFlags, PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetFolderPathAndSubDirA(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, PSTR pszSubDir, uint8* pszPath);
	public static HRESULT SHGetFolderPathAndSubDir(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, PSTR pszSubDir, uint8* pszPath) => SHGetFolderPathAndSubDirA(hwnd, csidl, hToken, dwFlags, pszSubDir, pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetFolderPathAndSubDirW(HWND hwnd, int32 csidl, HANDLE hToken, uint32 dwFlags, PWSTR pszSubDir, char16* pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetKnownFolderIDList(in Guid rfid, uint32 dwFlags, HANDLE hToken, ITEMIDLIST** ppidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetKnownFolderPath(in Guid rfid, uint32 dwFlags, HANDLE hToken, PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetKnownFolderPath(in Guid rfid, KNOWN_FOLDER_FLAG dwFlags, HANDLE hToken, PWSTR* ppszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetKnownFolderItem(in Guid rfid, KNOWN_FOLDER_FLAG flags, HANDLE hToken, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetSetFolderCustomSettings(SHFOLDERCUSTOMSETTINGS* pfcs, PWSTR pszPath, uint32 dwReadWrite);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* SHBrowseForFolderA(BROWSEINFOA* lpbi);
	public static ITEMIDLIST* SHBrowseForFolder(BROWSEINFOA* lpbi) => SHBrowseForFolderA(lpbi);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ITEMIDLIST* SHBrowseForFolderW(BROWSEINFOW* lpbi);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHLoadInProc(in Guid rclsid);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetDesktopFolder(IShellFolder** ppshf);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHChangeNotify(SHCNE_ID wEventId, SHCNF_FLAGS uFlags, void* dwItem1, void* dwItem2);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHAddToRecentDocs(uint32 uFlags, void* pv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHHandleUpdateImage(ITEMIDLIST* pidlExtra);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHUpdateImageA(PSTR pszHashItem, int32 iIndex, uint32 uFlags, int32 iImageIndex);
	public static void SHUpdateImage(PSTR pszHashItem, int32 iIndex, uint32 uFlags, int32 iImageIndex) => SHUpdateImageA(pszHashItem, iIndex, uFlags, iImageIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHUpdateImageW(PWSTR pszHashItem, int32 iIndex, uint32 uFlags, int32 iImageIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SHChangeNotifyRegister(HWND hwnd, SHCNRF_SOURCE fSources, int32 fEvents, uint32 wMsg, int32 cEntries, SHChangeNotifyEntry* pshcne);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHChangeNotifyDeregister(uint32 ulID);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern ShFindChangeNotificationHandle SHChangeNotification_Lock(HANDLE hChange, uint32 dwProcId, ITEMIDLIST*** pppidl, int32* plEvent);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHChangeNotification_Unlock(HANDLE hLock);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetRealIDL(IShellFolder* psf, ITEMIDLIST* pidlSimple, ITEMIDLIST** ppidlReal);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetInstanceExplorer(IUnknown** ppunk);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetDataFromIDListA(IShellFolder* psf, ITEMIDLIST* pidl, SHGDFIL_FORMAT nFormat, void* pv, int32 cb);
	public static HRESULT SHGetDataFromIDList(IShellFolder* psf, ITEMIDLIST* pidl, SHGDFIL_FORMAT nFormat, void* pv, int32 cb) => SHGetDataFromIDListA(psf, pidl, nFormat, pv, cb);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetDataFromIDListW(IShellFolder* psf, ITEMIDLIST* pidl, SHGDFIL_FORMAT nFormat, void* pv, int32 cb);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RestartDialog(HWND hwnd, PWSTR pszPrompt, uint32 dwReturn);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RestartDialogEx(HWND hwnd, PWSTR pszPrompt, uint32 dwReturn, uint32 dwReasonCode);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCoCreateInstance(PWSTR pszCLSID, Guid* pclsid, IUnknown* pUnkOuter, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateDataObject(ITEMIDLIST* pidlFolder, uint32 cidl, ITEMIDLIST** apidl, IDataObject* pdtInner, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CIDLData_CreateFromIDArray(ITEMIDLIST* pidlFolder, uint32 cidl, ITEMIDLIST** apidl, IDataObject** ppdtobj);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateStdEnumFmtEtc(uint32 cfmt, FORMATETC* afmt, IEnumFORMATETC** ppenumFormatEtc);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHDoDragDrop(HWND hwnd, IDataObject* pdata, IDropSource* pdsrc, DROPEFFECT dwEffect, DROPEFFECT* pdwEffect);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_SetDragImage(HIMAGELIST him, POINT* pptOffset);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_DragEnterEx(HWND hwndTarget, POINT ptStart);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_DragEnterEx2(HWND hwndTarget, POINT ptStart, IDataObject* pdtObject);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_ShowDragImage(BOOL fShow);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_DragMove(POINT pt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_DragLeave();

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DAD_AutoScroll(HWND hwnd, AUTO_SCROLL_DATA* pad, POINT* pptNow);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ReadCabinetState(CABINETSTATE* pcs, int32 cLength);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL WriteCabinetState(CABINETSTATE* pcs);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMakeUniqueName(char16* pszUniqueName, uint32 cchMax, PWSTR pszTemplate, PWSTR pszLongPlate, PWSTR pszDir);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsExe(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PCS_RET PathCleanupSpec(PWSTR pszDir, PWSTR pszSpec);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathResolve(char16* pszPath, uint16** dirs, PRF_FLAGS fFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL GetFileNameFromBrowse(HWND hwnd, char16* pszFilePath, uint32 cchFilePath, PWSTR pszWorkingDir, PWSTR pszDefExt, PWSTR pszFilters, PWSTR pszTitle);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 DriveType(int32 iDrive);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 RealDriveType(int32 iDrive, BOOL fOKToHitNet);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 IsNetDrive(int32 iDrive);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 Shell_MergeMenus(HMENU hmDst, HMENU hmSrc, uint32 uInsert, uint32 uIDAdjust, uint32 uIDAdjustMax, MM_FLAGS uFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHObjectProperties(HWND hwnd, SHOP_TYPE shopObjectType, PWSTR pszObjectName, PWSTR pszPropertyPage);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SHFormatDrive(HWND hwnd, uint32 drive, SHFMT_ID fmtID, SHFMT_OPT options);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHDestroyPropSheetExtArray(HPSXA hpsxa);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SHAddFromPropSheetExtArray(HPSXA hpsxa, LPFNSVADDPROPSHEETPAGE lpfnAddPage, LPARAM lParam);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SHReplaceFromPropSheetExtArray(HPSXA hpsxa, uint32 uPageID, LPFNSVADDPROPSHEETPAGE lpfnReplaceWith, LPARAM lParam);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* OpenRegStream(HKEY hkey, PWSTR pszSubkey, PWSTR pszValue, uint32 grfMode);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHFindFiles(ITEMIDLIST* pidlFolder, ITEMIDLIST* pidlSaveFile);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathGetShortPath(char16* pszLongPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathYetAnotherMakeUniqueName(char16* pszUniqueName, PWSTR pszPath, PWSTR pszShort, PWSTR pszFileSpec);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Win32DeleteFile(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SHRestricted(RESTRICTIONS rest);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SignalFileOpen(ITEMIDLIST* pidl);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocGetDetailsOfPropKey(IShellFolder* psf, ITEMIDLIST* pidl, PROPERTYKEY* pkey, VARIANT* pv, BOOL* pfFoundPropKey);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHStartNetConnectionDialogW(HWND hwnd, PWSTR pszRemoteName, uint32 dwType);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHDefExtractIconA(PSTR pszIconFile, int32 iIndex, uint32 uFlags, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize);
	public static HRESULT SHDefExtractIcon(PSTR pszIconFile, int32 iIndex, uint32 uFlags, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize) => SHDefExtractIconA(pszIconFile, iIndex, uFlags, phiconLarge, phiconSmall, nIconSize);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHDefExtractIconW(PWSTR pszIconFile, int32 iIndex, uint32 uFlags, HICON* phiconLarge, HICON* phiconSmall, uint32 nIconSize);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHOpenWithDialog(HWND hwndParent, OPENASINFO* poainfo);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Shell_GetImageLists(HIMAGELIST* phiml, HIMAGELIST* phimlSmall);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 Shell_GetCachedImageIndex(PWSTR pwszIconPath, int32 iIconIndex, uint32 uIconFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 Shell_GetCachedImageIndexA(PSTR pszIconPath, int32 iIconIndex, uint32 uIconFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 Shell_GetCachedImageIndexW(PWSTR pszIconPath, int32 iIconIndex, uint32 uIconFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHValidateUNC(HWND hwndOwner, PWSTR pszFile, VALIDATEUNC_OPTION fConnect);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHSetInstanceExplorer(IUnknown* punk);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsUserAnAdmin();

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SHShellFolderView_Message(HWND hwndMain, uint32 uMsg, LPARAM lParam);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellFolderView(SFV_CREATE* pcsfv, IShellView** ppsv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT CDefFolderMenu_Create2(ITEMIDLIST* pidlFolder, HWND hwnd, uint32 cidl, ITEMIDLIST** apidl, IShellFolder* psf, LPFNDFMCALLBACK pfn, uint32 nKeys, HKEY* ahkeys, IContextMenu** ppcm);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateDefaultContextMenu(DEFCONTEXTMENU* pdcm, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IContextMenu* SHFind_InitMenuPopup(HMENU hmenu, HWND hwndOwner, uint32 idCmdFirst, uint32 idCmdLast);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateShellFolderViewEx(CSFV* pcsfv, IShellView** ppsv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHGetSetSettings(SHELLSTATEA* lpss, SSF_MASK dwMask, BOOL bSet);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHGetSettings(SHELLFLAGSTATE* psfs, uint32 dwMask);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHBindToParent(ITEMIDLIST* pidl, in Guid riid, void** ppv, ITEMIDLIST** ppidlLast);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHBindToFolderIDListParent(IShellFolder* psfRoot, ITEMIDLIST* pidl, in Guid riid, void** ppv, ITEMIDLIST** ppidlLast);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHBindToFolderIDListParentEx(IShellFolder* psfRoot, ITEMIDLIST* pidl, IBindCtx* ppbc, in Guid riid, void** ppv, ITEMIDLIST** ppidlLast);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHBindToObject(IShellFolder* psf, ITEMIDLIST* pidl, IBindCtx* pbc, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHParseDisplayName(PWSTR pszName, IBindCtx* pbc, ITEMIDLIST** ppidl, uint32 sfgaoIn, uint32* psfgaoOut);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHPathPrepareForWriteA(HWND hwnd, IUnknown* punkEnableModless, PSTR pszPath, uint32 dwFlags);
	public static HRESULT SHPathPrepareForWrite(HWND hwnd, IUnknown* punkEnableModless, PSTR pszPath, uint32 dwFlags) => SHPathPrepareForWriteA(hwnd, punkEnableModless, pszPath, dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHPathPrepareForWriteW(HWND hwnd, IUnknown* punkEnableModless, PWSTR pszPath, uint32 dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateFileExtractIconW(PWSTR pszFile, uint32 dwFileAttributes, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHLimitInputEdit(HWND hwndEdit, IShellFolder* psf);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetAttributesFromDataObject(IDataObject* pdo, uint32 dwAttributeMask, uint32* pdwAttributes, uint32* pcItems);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHMapPIDLToSystemImageListIndex(IShellFolder* pshf, ITEMIDLIST* pidl, int32* piIndexSel);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCLSIDFromString(PWSTR psz, Guid* pclsid);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PickIconDlg(HWND hwnd, char16* pszIconPath, uint32 cchIconPath, int32* piIconIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StgMakeUniqueName(IStorage* pstgParent, PWSTR pszFileSpec, uint32 grfMode, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHChangeNotifyRegisterThread(SCNRT_STATUS status);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathQualify(PWSTR psz);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSlowA(PSTR pszFile, uint32 dwAttr);
	public static BOOL PathIsSlow(PSTR pszFile, uint32 dwAttr) => PathIsSlowA(pszFile, dwAttr);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSlowW(PWSTR pszFile, uint32 dwAttr);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPSXA SHCreatePropSheetExtArray(HKEY hKey, PWSTR pszSubKey, uint32 max_iface);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHOpenPropSheetW(PWSTR pszCaption, HKEY* ahkeys, uint32 ckeys, Guid* pclsidDefault, IDataObject* pdtobj, IShellBrowser* psb, PWSTR pStartPage);

	[Import("SHDOCVW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 SoftwareUpdateMessageBox(HWND hWnd, PWSTR pszDistUnit, uint32 dwFlags, SOFTDISTINFO* psdi);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHMultiFileProperties(IDataObject* pdtobj, uint32 dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateQueryCancelAutoPlayMoniker(IMoniker** ppmoniker);

	[Import("SHDOCVW.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ImportPrivacySettings(PWSTR pszFilename, BOOL* pfParsePrivacyPreferences, BOOL* pfParsePerSiteRules);

	[Import("api-ms-win-shcore-scaling-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DEVICE_SCALE_FACTOR GetScaleFactorForDevice(DISPLAY_DEVICE_TYPE deviceType);

	[Import("api-ms-win-shcore-scaling-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterScaleChangeNotifications(DISPLAY_DEVICE_TYPE displayDevice, HWND hwndNotify, uint32 uMsgNotify, uint32* pdwCookie);

	[Import("api-ms-win-shcore-scaling-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RevokeScaleChangeNotifications(DISPLAY_DEVICE_TYPE displayDevice, uint32 dwCookie);

	[Import("api-ms-win-shcore-scaling-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetScaleFactorForMonitor(HMONITOR hMon, DEVICE_SCALE_FACTOR* pScale);

	[Import("api-ms-win-shcore-scaling-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT RegisterScaleChangeEvent(HANDLE hEvent, uint* pdwCookie);

	[Import("api-ms-win-shcore-scaling-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UnregisterScaleChangeEvent(uint dwCookie);

	[Import("api-ms-win-shcore-scaling-l1-1-2.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 GetDpiForShellUIComponent(SHELL_UI_COMPONENT param0);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR* CommandLineToArgvW(PWSTR lpCmdLine, int32* pNumArgs);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DragQueryFileA(HDROP hDrop, uint32 iFile, uint8* lpszFile, uint32 cch);
	public static uint32 DragQueryFile(HDROP hDrop, uint32 iFile, uint8* lpszFile, uint32 cch) => DragQueryFileA(hDrop, iFile, lpszFile, cch);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DragQueryFileW(HDROP hDrop, uint32 iFile, char16* lpszFile, uint32 cch);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL DragQueryPoint(HDROP hDrop, POINT* ppt);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DragFinish(HDROP hDrop);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DragAcceptFiles(HWND hWnd, BOOL fAccept);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE ShellExecuteA(HWND hwnd, PSTR lpOperation, PSTR lpFile, PSTR lpParameters, PSTR lpDirectory, SHOW_WINDOW_CMD nShowCmd);
	public static HINSTANCE ShellExecute(HWND hwnd, PSTR lpOperation, PSTR lpFile, PSTR lpParameters, PSTR lpDirectory, SHOW_WINDOW_CMD nShowCmd) => ShellExecuteA(hwnd, lpOperation, lpFile, lpParameters, lpDirectory, nShowCmd);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE ShellExecuteW(HWND hwnd, PWSTR lpOperation, PWSTR lpFile, PWSTR lpParameters, PWSTR lpDirectory, SHOW_WINDOW_CMD nShowCmd);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE FindExecutableA(PSTR lpFile, PSTR lpDirectory, uint8* lpResult);
	public static HINSTANCE FindExecutable(PSTR lpFile, PSTR lpDirectory, uint8* lpResult) => FindExecutableA(lpFile, lpDirectory, lpResult);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HINSTANCE FindExecutableW(PWSTR lpFile, PWSTR lpDirectory, char16* lpResult);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ShellAboutA(HWND hWnd, PSTR szApp, PSTR szOtherStuff, HICON hIcon);
	public static int32 ShellAbout(HWND hWnd, PSTR szApp, PSTR szOtherStuff, HICON hIcon) => ShellAboutA(hWnd, szApp, szOtherStuff, hIcon);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ShellAboutW(HWND hWnd, PWSTR szApp, PWSTR szOtherStuff, HICON hIcon);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON DuplicateIcon(HINSTANCE hInst, HICON hIcon);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractAssociatedIconA(HINSTANCE hInst, uint8* pszIconPath, uint16* piIcon);
	public static HICON ExtractAssociatedIcon(HINSTANCE hInst, uint8* pszIconPath, uint16* piIcon) => ExtractAssociatedIconA(hInst, pszIconPath, piIcon);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractAssociatedIconW(HINSTANCE hInst, char16* pszIconPath, uint16* piIcon);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractAssociatedIconExA(HINSTANCE hInst, uint8* pszIconPath, uint16* piIconIndex, uint16* piIconId);
	public static HICON ExtractAssociatedIconEx(HINSTANCE hInst, uint8* pszIconPath, uint16* piIconIndex, uint16* piIconId) => ExtractAssociatedIconExA(hInst, pszIconPath, piIconIndex, piIconId);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractAssociatedIconExW(HINSTANCE hInst, char16* pszIconPath, uint16* piIconIndex, uint16* piIconId);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractIconA(HINSTANCE hInst, PSTR pszExeFileName, uint32 nIconIndex);
	public static HICON ExtractIcon(HINSTANCE hInst, PSTR pszExeFileName, uint32 nIconIndex) => ExtractIconA(hInst, pszExeFileName, nIconIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HICON ExtractIconW(HINSTANCE hInst, PWSTR pszExeFileName, uint32 nIconIndex);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint SHAppBarMessage(uint32 dwMessage, APPBARDATA* pData);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DoEnvironmentSubstA(uint8* pszSrc, uint32 cchSrc);
	public static uint32 DoEnvironmentSubst(uint8* pszSrc, uint32 cchSrc) => DoEnvironmentSubstA(pszSrc, cchSrc);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 DoEnvironmentSubstW(char16* pszSrc, uint32 cchSrc);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ExtractIconExA(PSTR lpszFile, int32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIcons);
	public static uint32 ExtractIconEx(PSTR lpszFile, int32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIcons) => ExtractIconExA(lpszFile, nIconIndex, phiconLarge, phiconSmall, nIcons);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 ExtractIconExW(PWSTR lpszFile, int32 nIconIndex, HICON* phiconLarge, HICON* phiconSmall, uint32 nIcons);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHFileOperationA(SHFILEOPSTRUCTA* lpFileOp);
	public static int32 SHFileOperation(SHFILEOPSTRUCTA* lpFileOp) => SHFileOperationA(lpFileOp);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHFileOperationW(SHFILEOPSTRUCTW* lpFileOp);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void SHFreeNameMappings(HANDLE hNameMappings);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShellExecuteExA(SHELLEXECUTEINFOA* pExecInfo);
	public static BOOL ShellExecuteEx(SHELLEXECUTEINFOA* pExecInfo) => ShellExecuteExA(pExecInfo);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ShellExecuteExW(SHELLEXECUTEINFOW* pExecInfo);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHCreateProcessAsUserW(SHCREATEPROCESSINFOW* pscpi);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHEvaluateSystemCommandTemplate(PWSTR pszCmdTemplate, PWSTR* ppszApplication, PWSTR* ppszCommandLine, PWSTR* ppszParameters);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocCreateForClasses(ASSOCIATIONELEMENT* rgClasses, uint32 cClasses, in Guid riid, void** ppv);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHQueryRecycleBinA(PSTR pszRootPath, SHQUERYRBINFO* pSHQueryRBInfo);
	public static HRESULT SHQueryRecycleBin(PSTR pszRootPath, SHQUERYRBINFO* pSHQueryRBInfo) => SHQueryRecycleBinA(pszRootPath, pSHQueryRBInfo);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHQueryRecycleBinW(PWSTR pszRootPath, SHQUERYRBINFO* pSHQueryRBInfo);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHEmptyRecycleBinA(HWND hwnd, PSTR pszRootPath, uint32 dwFlags);
	public static HRESULT SHEmptyRecycleBin(HWND hwnd, PSTR pszRootPath, uint32 dwFlags) => SHEmptyRecycleBinA(hwnd, pszRootPath, dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHEmptyRecycleBinW(HWND hwnd, PWSTR pszRootPath, uint32 dwFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHQueryUserNotificationState(QUERY_USER_NOTIFICATION_STATE* pquns);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Shell_NotifyIconA(NOTIFY_ICON_MESSAGE dwMessage, NOTIFYICONDATAA* lpData);
	public static BOOL Shell_NotifyIcon(NOTIFY_ICON_MESSAGE dwMessage, NOTIFYICONDATAA* lpData) => Shell_NotifyIconA(dwMessage, lpData);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL Shell_NotifyIconW(NOTIFY_ICON_MESSAGE dwMessage, NOTIFYICONDATAW* lpData);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT Shell_NotifyIconGetRect(NOTIFYICONIDENTIFIER* identifier, RECT* iconLocation);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint SHGetFileInfoA(PSTR pszPath, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes, SHFILEINFOA* psfi, uint32 cbFileInfo, SHGFI_FLAGS uFlags);
	public static uint SHGetFileInfo(PSTR pszPath, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes, SHFILEINFOA* psfi, uint32 cbFileInfo, SHGFI_FLAGS uFlags) => SHGetFileInfoA(pszPath, dwFileAttributes, psfi, cbFileInfo, uFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint SHGetFileInfoW(PWSTR pszPath, FILE_FLAGS_AND_ATTRIBUTES dwFileAttributes, SHFILEINFOW* psfi, uint32 cbFileInfo, SHGFI_FLAGS uFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetStockIconInfo(SHSTOCKICONID siid, uint32 uFlags, SHSTOCKICONINFO* psii);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetDiskFreeSpaceExA(PSTR pszDirectoryName, ULARGE_INTEGER* pulFreeBytesAvailableToCaller, ULARGE_INTEGER* pulTotalNumberOfBytes, ULARGE_INTEGER* pulTotalNumberOfFreeBytes);
	public static BOOL SHGetDiskFreeSpaceEx(PSTR pszDirectoryName, ULARGE_INTEGER* pulFreeBytesAvailableToCaller, ULARGE_INTEGER* pulTotalNumberOfBytes, ULARGE_INTEGER* pulTotalNumberOfFreeBytes) => SHGetDiskFreeSpaceExA(pszDirectoryName, pulFreeBytesAvailableToCaller, pulTotalNumberOfBytes, pulTotalNumberOfFreeBytes);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetDiskFreeSpaceExW(PWSTR pszDirectoryName, ULARGE_INTEGER* pulFreeBytesAvailableToCaller, ULARGE_INTEGER* pulTotalNumberOfBytes, ULARGE_INTEGER* pulTotalNumberOfFreeBytes);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetNewLinkInfoA(PSTR pszLinkTo, PSTR pszDir, uint8* pszName, BOOL* pfMustCopy, uint32 uFlags);
	public static BOOL SHGetNewLinkInfo(PSTR pszLinkTo, PSTR pszDir, uint8* pszName, BOOL* pfMustCopy, uint32 uFlags) => SHGetNewLinkInfoA(pszLinkTo, pszDir, pszName, pfMustCopy, uFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHGetNewLinkInfoW(PWSTR pszLinkTo, PWSTR pszDir, char16* pszName, BOOL* pfMustCopy, uint32 uFlags);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHInvokePrinterCommandA(HWND hwnd, uint32 uAction, PSTR lpBuf1, PSTR lpBuf2, BOOL fModal);
	public static BOOL SHInvokePrinterCommand(HWND hwnd, uint32 uAction, PSTR lpBuf1, PSTR lpBuf2, BOOL fModal) => SHInvokePrinterCommandA(hwnd, uAction, lpBuf1, lpBuf2, fModal);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHInvokePrinterCommandW(HWND hwnd, uint32 uAction, PWSTR lpBuf1, PWSTR lpBuf2, BOOL fModal);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHLoadNonloadedIconOverlayIdentifiers();

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHIsFileAvailableOffline(PWSTR pwszPath, uint32* pdwStatus);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetLocalizedName(PWSTR pszPath, PWSTR pszResModule, int32 idsRes);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHRemoveLocalizedName(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetLocalizedName(PWSTR pszPath, char16* pszResModule, uint32 cch, int32* pidsRes);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ShellMessageBoxA(HINSTANCE hAppInst, HWND hWnd, PSTR lpcText, PSTR lpcTitle, uint32 fuStyle);
	public static int32 ShellMessageBox(HINSTANCE hAppInst, HWND hWnd, PSTR lpcText, PSTR lpcTitle, uint32 fuStyle) => ShellMessageBoxA(hAppInst, hWnd, lpcText, lpcTitle, fuStyle);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 ShellMessageBoxW(HINSTANCE hAppInst, HWND hWnd, PWSTR lpcText, PWSTR lpcTitle, uint32 fuStyle);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsLFNDriveA(PSTR pszPath);
	public static BOOL IsLFNDrive(PSTR pszPath) => IsLFNDriveA(pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsLFNDriveW(PWSTR pszPath);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHEnumerateUnreadMailAccountsW(HKEY hKeyUser, uint32 dwIndex, char16* pszMailAddress, int32 cchMailAddress);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetUnreadMailCountW(HKEY hKeyUser, PWSTR pszMailAddress, uint32* pdwCount, FILETIME* pFileTime, char16* pszShellExecuteCommand, int32 cchShellExecuteCommand);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetUnreadMailCountW(PWSTR pszMailAddress, uint32 dwCount, PWSTR pszShellExecuteCommand);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHTestTokenMembership(HANDLE hToken, uint32 ulRID);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetImageList(int32 iImageList, in Guid riid, void** ppvObj);

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL InitNetworkAddressControl();

	[Import("SHELL32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetDriveMedia(PWSTR pszDrive, uint32* pdwMediaContent);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrChrA(PSTR pszStart, uint16 wMatch);
	public static PSTR StrChr(PSTR pszStart, uint16 wMatch) => StrChrA(pszStart, wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrChrW(PWSTR pszStart, char16 wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrChrIA(PSTR pszStart, uint16 wMatch);
	public static PSTR StrChrI(PSTR pszStart, uint16 wMatch) => StrChrIA(pszStart, wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrChrIW(PWSTR pszStart, char16 wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrChrNW(PWSTR pszStart, char16 wMatch, uint32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrChrNIW(PWSTR pszStart, char16 wMatch, uint32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNA(PSTR psz1, PSTR psz2, int32 nChar);
	public static int32 StrCmpN(PSTR psz1, PSTR psz2, int32 nChar) => StrCmpNA(psz1, psz2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNW(PWSTR psz1, PWSTR psz2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNIA(PSTR psz1, PSTR psz2, int32 nChar);
	public static int32 StrCmpNI(PSTR psz1, PSTR psz2, int32 nChar) => StrCmpNIA(psz1, psz2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNIW(PWSTR psz1, PWSTR psz2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCSpnA(PSTR pszStr, PSTR pszSet);
	public static int32 StrCSpn(PSTR pszStr, PSTR pszSet) => StrCSpnA(pszStr, pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCSpnW(PWSTR pszStr, PWSTR pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCSpnIA(PSTR pszStr, PSTR pszSet);
	public static int32 StrCSpnI(PSTR pszStr, PSTR pszSet) => StrCSpnIA(pszStr, pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCSpnIW(PWSTR pszStr, PWSTR pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrDupA(PSTR pszSrch);
	public static PSTR StrDup(PSTR pszSrch) => StrDupA(pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrDupW(PWSTR pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrFormatByteSizeEx(uint64 ull, SFBS_FLAGS flags, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrFormatByteSizeA(uint32 dw, uint8* pszBuf, uint32 cchBuf);
	public static PSTR StrFormatByteSize(uint32 dw, uint8* pszBuf, uint32 cchBuf) => StrFormatByteSizeA(dw, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrFormatByteSize64A(int64 qdw, uint8* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrFormatByteSizeW(int64 qdw, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrFormatKBSizeW(int64 qdw, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrFormatKBSizeA(int64 qdw, uint8* pszBuf, uint32 cchBuf);
	public static PSTR StrFormatKBSize(int64 qdw, uint8* pszBuf, uint32 cchBuf) => StrFormatKBSizeA(qdw, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrFromTimeIntervalA(uint8* pszOut, uint32 cchMax, uint32 dwTimeMS, int32 digits);
	public static int32 StrFromTimeInterval(uint8* pszOut, uint32 cchMax, uint32 dwTimeMS, int32 digits) => StrFromTimeIntervalA(pszOut, cchMax, dwTimeMS, digits);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrFromTimeIntervalW(char16* pszOut, uint32 cchMax, uint32 dwTimeMS, int32 digits);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrIsIntlEqualA(BOOL fCaseSens, PSTR pszString1, PSTR pszString2, int32 nChar);
	public static BOOL StrIsIntlEqual(BOOL fCaseSens, PSTR pszString1, PSTR pszString2, int32 nChar) => StrIsIntlEqualA(fCaseSens, pszString1, pszString2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrIsIntlEqualW(BOOL fCaseSens, PWSTR pszString1, PWSTR pszString2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrNCatA(uint8* psz1, PSTR psz2, int32 cchMax);
	public static PSTR StrNCat(uint8* psz1, PSTR psz2, int32 cchMax) => StrNCatA(psz1, psz2, cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrNCatW(char16* psz1, PWSTR psz2, int32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrPBrkA(PSTR psz, PSTR pszSet);
	public static PSTR StrPBrk(PSTR psz, PSTR pszSet) => StrPBrkA(psz, pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrPBrkW(PWSTR psz, PWSTR pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrRChrA(PSTR pszStart, PSTR pszEnd, uint16 wMatch);
	public static PSTR StrRChr(PSTR pszStart, PSTR pszEnd, uint16 wMatch) => StrRChrA(pszStart, pszEnd, wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrRChrW(PWSTR pszStart, PWSTR pszEnd, char16 wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrRChrIA(PSTR pszStart, PSTR pszEnd, uint16 wMatch);
	public static PSTR StrRChrI(PSTR pszStart, PSTR pszEnd, uint16 wMatch) => StrRChrIA(pszStart, pszEnd, wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrRChrIW(PWSTR pszStart, PWSTR pszEnd, char16 wMatch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrRStrIA(PSTR pszSource, PSTR pszLast, PSTR pszSrch);
	public static PSTR StrRStrI(PSTR pszSource, PSTR pszLast, PSTR pszSrch) => StrRStrIA(pszSource, pszLast, pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrRStrIW(PWSTR pszSource, PWSTR pszLast, PWSTR pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrSpnA(PSTR psz, PSTR pszSet);
	public static int32 StrSpn(PSTR psz, PSTR pszSet) => StrSpnA(psz, pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrSpnW(PWSTR psz, PWSTR pszSet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrStrA(PSTR pszFirst, PSTR pszSrch);
	public static PSTR StrStr(PSTR pszFirst, PSTR pszSrch) => StrStrA(pszFirst, pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrStrW(PWSTR pszFirst, PWSTR pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrStrIA(PSTR pszFirst, PSTR pszSrch);
	public static PSTR StrStrI(PSTR pszFirst, PSTR pszSrch) => StrStrIA(pszFirst, pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrStrIW(PWSTR pszFirst, PWSTR pszSrch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrStrNW(PWSTR pszFirst, PWSTR pszSrch, uint32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrStrNIW(PWSTR pszFirst, PWSTR pszSrch, uint32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrToIntA(PSTR pszSrc);
	public static int32 StrToInt(PSTR pszSrc) => StrToIntA(pszSrc);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrToIntW(PWSTR pszSrc);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrToIntExA(PSTR pszString, int32 dwFlags, int32* piRet);
	public static BOOL StrToIntEx(PSTR pszString, int32 dwFlags, int32* piRet) => StrToIntExA(pszString, dwFlags, piRet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrToIntExW(PWSTR pszString, int32 dwFlags, int32* piRet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrToInt64ExA(PSTR pszString, int32 dwFlags, int64* pllRet);
	public static BOOL StrToInt64Ex(PSTR pszString, int32 dwFlags, int64* pllRet) => StrToInt64ExA(pszString, dwFlags, pllRet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrToInt64ExW(PWSTR pszString, int32 dwFlags, int64* pllRet);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrTrimA(PSTR psz, PSTR pszTrimChars);
	public static BOOL StrTrim(PSTR psz, PSTR pszTrimChars) => StrTrimA(psz, pszTrimChars);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL StrTrimW(PWSTR psz, PWSTR pszTrimChars);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrCatW(PWSTR psz1, PWSTR psz2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpW(PWSTR psz1, PWSTR psz2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpIW(PWSTR psz1, PWSTR psz2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrCpyW(PWSTR psz1, PWSTR psz2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrCpyNW(char16* pszDst, PWSTR pszSrc, int32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR StrCatBuffW(char16* pszDest, PWSTR pszSrc, int32 cchDestBuffSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR StrCatBuffA(uint8* pszDest, PSTR pszSrc, int32 cchDestBuffSize);
	public static PSTR StrCatBuff(uint8* pszDest, PSTR pszSrc, int32 cchDestBuffSize) => StrCatBuffA(pszDest, pszSrc, cchDestBuffSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChrCmpIA(uint16 w1, uint16 w2);
	public static BOOL ChrCmpI(uint16 w1, uint16 w2) => ChrCmpIA(w1, w2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL ChrCmpIW(char16 w1, char16 w2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wvnsprintfA(uint8* pszDest, int32 cchDest, PSTR pszFmt, int8* arglist);
	public static int32 wvnsprintf(uint8* pszDest, int32 cchDest, PSTR pszFmt, int8* arglist) => wvnsprintfA(pszDest, cchDest, pszFmt, arglist);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wvnsprintfW(char16* pszDest, int32 cchDest, PWSTR pszFmt, int8* arglist);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wnsprintfA(uint8* pszDest, int32 cchDest, PSTR pszFmt);
	public static int32 wnsprintf(uint8* pszDest, int32 cchDest, PSTR pszFmt) => wnsprintfA(pszDest, cchDest, pszFmt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 wnsprintfW(char16* pszDest, int32 cchDest, PWSTR pszFmt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrRetToStrA(STRRET* pstr, ITEMIDLIST* pidl, PSTR* ppsz);
	public static HRESULT StrRetToStr(STRRET* pstr, ITEMIDLIST* pidl, PSTR* ppsz) => StrRetToStrA(pstr, pidl, ppsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrRetToStrW(STRRET* pstr, ITEMIDLIST* pidl, PWSTR* ppsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrRetToBufA(STRRET* pstr, ITEMIDLIST* pidl, uint8* pszBuf, uint32 cchBuf);
	public static HRESULT StrRetToBuf(STRRET* pstr, ITEMIDLIST* pidl, uint8* pszBuf, uint32 cchBuf) => StrRetToBufA(pstr, pidl, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrRetToBufW(STRRET* pstr, ITEMIDLIST* pidl, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHStrDupA(PSTR psz, PWSTR* ppwsz);
	public static HRESULT SHStrDup(PSTR psz, PWSTR* ppwsz) => SHStrDupA(psz, ppwsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHStrDupW(PWSTR psz, PWSTR* ppwsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpLogicalW(PWSTR psz1, PWSTR psz2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 StrCatChainW(char16* pszDst, uint32 cchDst, uint32 ichAt, PWSTR pszSrc);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT StrRetToBSTR(STRRET* pstr, ITEMIDLIST* pidl, BSTR* pbstr);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHLoadIndirectString(PWSTR pszSource, char16* pszOutBuf, uint32 cchOutBuf, void** ppvReserved);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsCharSpaceA(CHAR wch);
	public static BOOL IsCharSpace(CHAR wch) => IsCharSpaceA(wch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsCharSpaceW(char16 wch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpCA(PSTR pszStr1, PSTR pszStr2);
	public static int32 StrCmpC(PSTR pszStr1, PSTR pszStr2) => StrCmpCA(pszStr1, pszStr2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpCW(PWSTR pszStr1, PWSTR pszStr2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpICA(PSTR pszStr1, PSTR pszStr2);
	public static int32 StrCmpIC(PSTR pszStr1, PSTR pszStr2) => StrCmpICA(pszStr1, pszStr2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpICW(PWSTR pszStr1, PWSTR pszStr2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNCA(PSTR pszStr1, PSTR pszStr2, int32 nChar);
	public static int32 StrCmpNC(PSTR pszStr1, PSTR pszStr2, int32 nChar) => StrCmpNCA(pszStr1, pszStr2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNCW(PWSTR pszStr1, PWSTR pszStr2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNICA(PSTR pszStr1, PSTR pszStr2, int32 nChar);
	public static int32 StrCmpNIC(PSTR pszStr1, PSTR pszStr2, int32 nChar) => StrCmpNICA(pszStr1, pszStr2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 StrCmpNICW(PWSTR pszStr1, PWSTR pszStr2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IntlStrEqWorkerA(BOOL fCaseSens, uint8* lpString1, uint8* lpString2, int32 nChar);
	public static BOOL IntlStrEqWorker(BOOL fCaseSens, uint8* lpString1, uint8* lpString2, int32 nChar) => IntlStrEqWorkerA(fCaseSens, lpString1, lpString2, nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IntlStrEqWorkerW(BOOL fCaseSens, char16* lpString1, char16* lpString2, int32 nChar);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathAddBackslashA(uint8* pszPath);
	public static PSTR PathAddBackslash(uint8* pszPath) => PathAddBackslashA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathAddBackslashW(char16* pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathAddExtensionA(uint8* pszPath, PSTR pszExt);
	public static BOOL PathAddExtension(uint8* pszPath, PSTR pszExt) => PathAddExtensionA(pszPath, pszExt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathAddExtensionW(char16* pszPath, PWSTR pszExt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathAppendA(uint8* pszPath, PSTR pszMore);
	public static BOOL PathAppend(uint8* pszPath, PSTR pszMore) => PathAppendA(pszPath, pszMore);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathAppendW(char16* pszPath, PWSTR pszMore);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathBuildRootA(uint8* pszRoot, int32 iDrive);
	public static PSTR PathBuildRoot(uint8* pszRoot, int32 iDrive) => PathBuildRootA(pszRoot, iDrive);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathBuildRootW(char16* pszRoot, int32 iDrive);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCanonicalizeA(uint8* pszBuf, PSTR pszPath);
	public static BOOL PathCanonicalize(uint8* pszBuf, PSTR pszPath) => PathCanonicalizeA(pszBuf, pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCanonicalizeW(char16* pszBuf, PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathCombineA(uint8* pszDest, PSTR pszDir, PSTR pszFile);
	public static PSTR PathCombine(uint8* pszDest, PSTR pszDir, PSTR pszFile) => PathCombineA(pszDest, pszDir, pszFile);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathCombineW(char16* pszDest, PWSTR pszDir, PWSTR pszFile);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCompactPathA(HDC hDC, uint8* pszPath, uint32 dx);
	public static BOOL PathCompactPath(HDC hDC, uint8* pszPath, uint32 dx) => PathCompactPathA(hDC, pszPath, dx);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCompactPathW(HDC hDC, char16* pszPath, uint32 dx);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCompactPathExA(uint8* pszOut, PSTR pszSrc, uint32 cchMax, uint32 dwFlags);
	public static BOOL PathCompactPathEx(uint8* pszOut, PSTR pszSrc, uint32 cchMax, uint32 dwFlags) => PathCompactPathExA(pszOut, pszSrc, cchMax, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCompactPathExW(char16* pszOut, PWSTR pszSrc, uint32 cchMax, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathCommonPrefixA(PSTR pszFile1, PSTR pszFile2, uint8* achPath);
	public static int32 PathCommonPrefix(PSTR pszFile1, PSTR pszFile2, uint8* achPath) => PathCommonPrefixA(pszFile1, pszFile2, achPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathCommonPrefixW(PWSTR pszFile1, PWSTR pszFile2, char16* achPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathFileExistsA(PSTR pszPath);
	public static BOOL PathFileExists(PSTR pszPath) => PathFileExistsA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathFileExistsW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathFindExtensionA(PSTR pszPath);
	public static PSTR PathFindExtension(PSTR pszPath) => PathFindExtensionA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathFindExtensionW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathFindFileNameA(PSTR pszPath);
	public static PSTR PathFindFileName(PSTR pszPath) => PathFindFileNameA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathFindFileNameW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathFindNextComponentA(PSTR pszPath);
	public static PSTR PathFindNextComponent(PSTR pszPath) => PathFindNextComponentA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathFindNextComponentW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathFindOnPathA(uint8* pszPath, int8** ppszOtherDirs);
	public static BOOL PathFindOnPath(uint8* pszPath, int8** ppszOtherDirs) => PathFindOnPathA(pszPath, ppszOtherDirs);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathFindOnPathW(char16* pszPath, uint16** ppszOtherDirs);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathFindSuffixArrayA(PSTR pszPath, PSTR* apszSuffix, int32 iArraySize);
	public static PSTR PathFindSuffixArray(PSTR pszPath, PSTR* apszSuffix, int32 iArraySize) => PathFindSuffixArrayA(pszPath, apszSuffix, iArraySize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathFindSuffixArrayW(PWSTR pszPath, PWSTR* apszSuffix, int32 iArraySize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathGetArgsA(PSTR pszPath);
	public static PSTR PathGetArgs(PSTR pszPath) => PathGetArgsA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathGetArgsW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsLFNFileSpecA(PSTR pszName);
	public static BOOL PathIsLFNFileSpec(PSTR pszName) => PathIsLFNFileSpecA(pszName);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsLFNFileSpecW(PWSTR pszName);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PathGetCharTypeA(uint8 ch);
	public static uint32 PathGetCharType(uint8 ch) => PathGetCharTypeA(ch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 PathGetCharTypeW(char16 ch);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathGetDriveNumberA(PSTR pszPath);
	public static int32 PathGetDriveNumber(PSTR pszPath) => PathGetDriveNumberA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathGetDriveNumberW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsDirectoryA(PSTR pszPath);
	public static BOOL PathIsDirectory(PSTR pszPath) => PathIsDirectoryA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsDirectoryW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsDirectoryEmptyA(PSTR pszPath);
	public static BOOL PathIsDirectoryEmpty(PSTR pszPath) => PathIsDirectoryEmptyA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsDirectoryEmptyW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsFileSpecA(PSTR pszPath);
	public static BOOL PathIsFileSpec(PSTR pszPath) => PathIsFileSpecA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsFileSpecW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsPrefixA(PSTR pszPrefix, PSTR pszPath);
	public static BOOL PathIsPrefix(PSTR pszPrefix, PSTR pszPath) => PathIsPrefixA(pszPrefix, pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsPrefixW(PWSTR pszPrefix, PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsRelativeA(PSTR pszPath);
	public static BOOL PathIsRelative(PSTR pszPath) => PathIsRelativeA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsRelativeW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsRootA(PSTR pszPath);
	public static BOOL PathIsRoot(PSTR pszPath) => PathIsRootA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsRootW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSameRootA(PSTR pszPath1, PSTR pszPath2);
	public static BOOL PathIsSameRoot(PSTR pszPath1, PSTR pszPath2) => PathIsSameRootA(pszPath1, pszPath2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSameRootW(PWSTR pszPath1, PWSTR pszPath2);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCA(PSTR pszPath);
	public static BOOL PathIsUNC(PSTR pszPath) => PathIsUNCA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsNetworkPathA(PSTR pszPath);
	public static BOOL PathIsNetworkPath(PSTR pszPath) => PathIsNetworkPathA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsNetworkPathW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCServerA(PSTR pszPath);
	public static BOOL PathIsUNCServer(PSTR pszPath) => PathIsUNCServerA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCServerW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCServerShareA(PSTR pszPath);
	public static BOOL PathIsUNCServerShare(PSTR pszPath) => PathIsUNCServerShareA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCServerShareW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsContentTypeA(PSTR pszPath, PSTR pszContentType);
	public static BOOL PathIsContentType(PSTR pszPath, PSTR pszContentType) => PathIsContentTypeA(pszPath, pszContentType);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsContentTypeW(PWSTR pszPath, PWSTR pszContentType);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsURLA(PSTR pszPath);
	public static BOOL PathIsURL(PSTR pszPath) => PathIsURLA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsURLW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMakePrettyA(PSTR pszPath);
	public static BOOL PathMakePretty(PSTR pszPath) => PathMakePrettyA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMakePrettyW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMatchSpecA(PSTR pszFile, PSTR pszSpec);
	public static BOOL PathMatchSpec(PSTR pszFile, PSTR pszSpec) => PathMatchSpecA(pszFile, pszSpec);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMatchSpecW(PWSTR pszFile, PWSTR pszSpec);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathMatchSpecExA(PSTR pszFile, PSTR pszSpec, uint32 dwFlags);
	public static HRESULT PathMatchSpecEx(PSTR pszFile, PSTR pszSpec, uint32 dwFlags) => PathMatchSpecExA(pszFile, pszSpec, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathMatchSpecExW(PWSTR pszFile, PWSTR pszSpec, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathParseIconLocationA(PSTR pszIconFile);
	public static int32 PathParseIconLocation(PSTR pszIconFile) => PathParseIconLocationA(pszIconFile);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 PathParseIconLocationW(PWSTR pszIconFile);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathQuoteSpacesA(uint8* lpsz);
	public static BOOL PathQuoteSpaces(uint8* lpsz) => PathQuoteSpacesA(lpsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathQuoteSpacesW(char16* lpsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRelativePathToA(uint8* pszPath, PSTR pszFrom, uint32 dwAttrFrom, PSTR pszTo, uint32 dwAttrTo);
	public static BOOL PathRelativePathTo(uint8* pszPath, PSTR pszFrom, uint32 dwAttrFrom, PSTR pszTo, uint32 dwAttrTo) => PathRelativePathToA(pszPath, pszFrom, dwAttrFrom, pszTo, dwAttrTo);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRelativePathToW(char16* pszPath, PWSTR pszFrom, uint32 dwAttrFrom, PWSTR pszTo, uint32 dwAttrTo);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveArgsA(PSTR pszPath);
	public static void PathRemoveArgs(PSTR pszPath) => PathRemoveArgsA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveArgsW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathRemoveBackslashA(PSTR pszPath);
	public static PSTR PathRemoveBackslash(PSTR pszPath) => PathRemoveBackslashA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathRemoveBackslashW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveBlanksA(PSTR pszPath);
	public static void PathRemoveBlanks(PSTR pszPath) => PathRemoveBlanksA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveBlanksW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveExtensionA(PSTR pszPath);
	public static void PathRemoveExtension(PSTR pszPath) => PathRemoveExtensionA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathRemoveExtensionW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRemoveFileSpecA(PSTR pszPath);
	public static BOOL PathRemoveFileSpec(PSTR pszPath) => PathRemoveFileSpecA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRemoveFileSpecW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRenameExtensionA(uint8* pszPath, PSTR pszExt);
	public static BOOL PathRenameExtension(uint8* pszPath, PSTR pszExt) => PathRenameExtensionA(pszPath, pszExt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathRenameExtensionW(char16* pszPath, PWSTR pszExt);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathSearchAndQualifyA(PSTR pszPath, uint8* pszBuf, uint32 cchBuf);
	public static BOOL PathSearchAndQualify(PSTR pszPath, uint8* pszBuf, uint32 cchBuf) => PathSearchAndQualifyA(pszPath, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathSearchAndQualifyW(PWSTR pszPath, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathSetDlgItemPathA(HWND hDlg, int32 id, PSTR pszPath);
	public static void PathSetDlgItemPath(HWND hDlg, int32 id, PSTR pszPath) => PathSetDlgItemPathA(hDlg, id, pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathSetDlgItemPathW(HWND hDlg, int32 id, PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR PathSkipRootA(PSTR pszPath);
	public static PSTR PathSkipRoot(PSTR pszPath) => PathSkipRootA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR PathSkipRootW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathStripPathA(PSTR pszPath);
	public static void PathStripPath(PSTR pszPath) => PathStripPathA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathStripPathW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathStripToRootA(PSTR pszPath);
	public static BOOL PathStripToRoot(PSTR pszPath) => PathStripToRootA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathStripToRootW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnquoteSpacesA(PSTR lpsz);
	public static BOOL PathUnquoteSpaces(PSTR lpsz) => PathUnquoteSpacesA(lpsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnquoteSpacesW(PWSTR lpsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMakeSystemFolderA(PSTR pszPath);
	public static BOOL PathMakeSystemFolder(PSTR pszPath) => PathMakeSystemFolderA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathMakeSystemFolderW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnmakeSystemFolderA(PSTR pszPath);
	public static BOOL PathUnmakeSystemFolder(PSTR pszPath) => PathUnmakeSystemFolderA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnmakeSystemFolderW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSystemFolderA(PSTR pszPath, uint32 dwAttrb);
	public static BOOL PathIsSystemFolder(PSTR pszPath, uint32 dwAttrb) => PathIsSystemFolderA(pszPath, dwAttrb);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsSystemFolderW(PWSTR pszPath, uint32 dwAttrb);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathUndecorateA(PSTR pszPath);
	public static void PathUndecorate(PSTR pszPath) => PathUndecorateA(pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void PathUndecorateW(PWSTR pszPath);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnExpandEnvStringsA(PSTR pszPath, uint8* pszBuf, uint32 cchBuf);
	public static BOOL PathUnExpandEnvStrings(PSTR pszPath, uint8* pszBuf, uint32 cchBuf) => PathUnExpandEnvStringsA(pszPath, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathUnExpandEnvStringsW(PWSTR pszPath, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UrlCompareA(PSTR psz1, PSTR psz2, BOOL fIgnoreSlash);
	public static int32 UrlCompare(PSTR psz1, PSTR psz2, BOOL fIgnoreSlash) => UrlCompareA(psz1, psz2, fIgnoreSlash);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 UrlCompareW(PWSTR psz1, PWSTR psz2, BOOL fIgnoreSlash);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCombineA(PSTR pszBase, PSTR pszRelative, uint8* pszCombined, uint32* pcchCombined, uint32 dwFlags);
	public static HRESULT UrlCombine(PSTR pszBase, PSTR pszRelative, uint8* pszCombined, uint32* pcchCombined, uint32 dwFlags) => UrlCombineA(pszBase, pszRelative, pszCombined, pcchCombined, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCombineW(PWSTR pszBase, PWSTR pszRelative, char16* pszCombined, uint32* pcchCombined, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCanonicalizeA(PSTR pszUrl, uint8* pszCanonicalized, uint32* pcchCanonicalized, uint32 dwFlags);
	public static HRESULT UrlCanonicalize(PSTR pszUrl, uint8* pszCanonicalized, uint32* pcchCanonicalized, uint32 dwFlags) => UrlCanonicalizeA(pszUrl, pszCanonicalized, pcchCanonicalized, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCanonicalizeW(PWSTR pszUrl, char16* pszCanonicalized, uint32* pcchCanonicalized, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsOpaqueA(PSTR pszURL);
	public static BOOL UrlIsOpaque(PSTR pszURL) => UrlIsOpaqueA(pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsOpaqueW(PWSTR pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsNoHistoryA(PSTR pszURL);
	public static BOOL UrlIsNoHistory(PSTR pszURL) => UrlIsNoHistoryA(pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsNoHistoryW(PWSTR pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsA(PSTR pszUrl, URLIS UrlIs);
	public static BOOL UrlIs(PSTR pszUrl, URLIS UrlIs) => UrlIsA(pszUrl, UrlIs);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL UrlIsW(PWSTR pszUrl, URLIS UrlIs);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PSTR UrlGetLocationA(PSTR pszURL);
	public static PSTR UrlGetLocation(PSTR pszURL) => UrlGetLocationA(pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern PWSTR UrlGetLocationW(PWSTR pszURL);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlUnescapeA(PSTR pszUrl, uint8* pszUnescaped, uint32* pcchUnescaped, uint32 dwFlags);
	public static HRESULT UrlUnescape(PSTR pszUrl, uint8* pszUnescaped, uint32* pcchUnescaped, uint32 dwFlags) => UrlUnescapeA(pszUrl, pszUnescaped, pcchUnescaped, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlUnescapeW(PWSTR pszUrl, char16* pszUnescaped, uint32* pcchUnescaped, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlEscapeA(PSTR pszUrl, uint8* pszEscaped, uint32* pcchEscaped, uint32 dwFlags);
	public static HRESULT UrlEscape(PSTR pszUrl, uint8* pszEscaped, uint32* pcchEscaped, uint32 dwFlags) => UrlEscapeA(pszUrl, pszEscaped, pcchEscaped, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlEscapeW(PWSTR pszUrl, char16* pszEscaped, uint32* pcchEscaped, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCreateFromPathA(PSTR pszPath, uint8* pszUrl, uint32* pcchUrl, uint32 dwFlags);
	public static HRESULT UrlCreateFromPath(PSTR pszPath, uint8* pszUrl, uint32* pcchUrl, uint32 dwFlags) => UrlCreateFromPathA(pszPath, pszUrl, pcchUrl, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlCreateFromPathW(PWSTR pszPath, char16* pszUrl, uint32* pcchUrl, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCreateFromUrlA(PSTR pszUrl, uint8* pszPath, uint32* pcchPath, uint32 dwFlags);
	public static HRESULT PathCreateFromUrl(PSTR pszUrl, uint8* pszPath, uint32* pcchPath, uint32 dwFlags) => PathCreateFromUrlA(pszUrl, pszPath, pcchPath, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCreateFromUrlW(PWSTR pszUrl, char16* pszPath, uint32* pcchPath, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCreateFromUrlAlloc(PWSTR pszIn, PWSTR* ppszOut, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlHashA(PSTR pszUrl, uint8* pbHash, uint32 cbHash);
	public static HRESULT UrlHash(PSTR pszUrl, uint8* pbHash, uint32 cbHash) => UrlHashA(pszUrl, pbHash, cbHash);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlHashW(PWSTR pszUrl, uint8* pbHash, uint32 cbHash);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlGetPartW(PWSTR pszIn, char16* pszOut, uint32* pcchOut, uint32 dwPart, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlGetPartA(PSTR pszIn, uint8* pszOut, uint32* pcchOut, uint32 dwPart, uint32 dwFlags);
	public static HRESULT UrlGetPart(PSTR pszIn, uint8* pszOut, uint32* pcchOut, uint32 dwPart, uint32 dwFlags) => UrlGetPartA(pszIn, pszOut, pcchOut, dwPart, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlApplySchemeA(PSTR pszIn, uint8* pszOut, uint32* pcchOut, uint32 dwFlags);
	public static HRESULT UrlApplyScheme(PSTR pszIn, uint8* pszOut, uint32* pcchOut, uint32 dwFlags) => UrlApplySchemeA(pszIn, pszOut, pcchOut, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlApplySchemeW(PWSTR pszIn, char16* pszOut, uint32* pcchOut, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HashData(uint8* pbData, uint32 cbData, uint8* pbHash, uint32 cbHash);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT UrlFixupW(PWSTR pcszUrl, char16* pszTranslatedUrl, uint32 cchMax);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ParseURLA(PSTR pcszURL, PARSEDURLA* ppu);
	public static HRESULT ParseURL(PSTR pcszURL, PARSEDURLA* ppu) => ParseURLA(pcszURL, ppu);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ParseURLW(PWSTR pcszURL, PARSEDURLW* ppu);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteEmptyKeyA(HKEY hkey, PSTR pszSubKey);
	public static WIN32_ERROR SHDeleteEmptyKey(HKEY hkey, PSTR pszSubKey) => SHDeleteEmptyKeyA(hkey, pszSubKey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteEmptyKeyW(HKEY hkey, PWSTR pszSubKey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteKeyA(HKEY hkey, PSTR pszSubKey);
	public static WIN32_ERROR SHDeleteKey(HKEY hkey, PSTR pszSubKey) => SHDeleteKeyA(hkey, pszSubKey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteKeyW(HKEY hkey, PWSTR pszSubKey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HKEY SHRegDuplicateHKey(HKEY hkey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteValueA(HKEY hkey, PSTR pszSubKey, PSTR pszValue);
	public static WIN32_ERROR SHDeleteValue(HKEY hkey, PSTR pszSubKey, PSTR pszValue) => SHDeleteValueA(hkey, pszSubKey, pszValue);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHDeleteValueW(HKEY hkey, PWSTR pszSubKey, PWSTR pszValue);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHGetValueA(HKEY hkey, PSTR pszSubKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData);
	public static WIN32_ERROR SHGetValue(HKEY hkey, PSTR pszSubKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData) => SHGetValueA(hkey, pszSubKey, pszValue, pdwType, pvData, pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHGetValueW(HKEY hkey, PWSTR pszSubKey, PWSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHSetValueA(HKEY hkey, PSTR pszSubKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData);
	public static int32 SHSetValue(HKEY hkey, PSTR pszSubKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData) => SHSetValueA(hkey, pszSubKey, pszValue, dwType, pvData, cbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHSetValueW(HKEY hkey, PWSTR pszSubKey, PWSTR pszValue, uint32 dwType, void* pvData, uint32 cbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetValueA(HKEY hkey, PSTR pszSubKey, PSTR pszValue, int32 srrfFlags, uint32* pdwType, void* pvData, uint32* pcbData);
	public static WIN32_ERROR SHRegGetValue(HKEY hkey, PSTR pszSubKey, PSTR pszValue, int32 srrfFlags, uint32* pdwType, void* pvData, uint32* pcbData) => SHRegGetValueA(hkey, pszSubKey, pszValue, srrfFlags, pdwType, pvData, pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetValueW(HKEY hkey, PWSTR pszSubKey, PWSTR pszValue, int32 srrfFlags, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetValueFromHKCUHKLM(PWSTR pwszKey, PWSTR pwszValue, int32 srrfFlags, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHQueryValueExA(HKEY hkey, PSTR pszValue, uint32* pdwReserved, uint32* pdwType, void* pvData, uint32* pcbData);
	public static WIN32_ERROR SHQueryValueEx(HKEY hkey, PSTR pszValue, uint32* pdwReserved, uint32* pdwType, void* pvData, uint32* pcbData) => SHQueryValueExA(hkey, pszValue, pdwReserved, pdwType, pvData, pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHQueryValueExW(HKEY hkey, PWSTR pszValue, uint32* pdwReserved, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHEnumKeyExA(HKEY hkey, uint32 dwIndex, uint8* pszName, uint32* pcchName);
	public static WIN32_ERROR SHEnumKeyEx(HKEY hkey, uint32 dwIndex, uint8* pszName, uint32* pcchName) => SHEnumKeyExA(hkey, dwIndex, pszName, pcchName);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHEnumKeyExW(HKEY hkey, uint32 dwIndex, char16* pszName, uint32* pcchName);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHEnumValueA(HKEY hkey, uint32 dwIndex, uint8* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData);
	public static WIN32_ERROR SHEnumValue(HKEY hkey, uint32 dwIndex, uint8* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData) => SHEnumValueA(hkey, dwIndex, pszValueName, pcchValueName, pdwType, pvData, pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHEnumValueW(HKEY hkey, uint32 dwIndex, char16* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHQueryInfoKeyA(HKEY hkey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen);
	public static WIN32_ERROR SHQueryInfoKey(HKEY hkey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen) => SHQueryInfoKeyA(hkey, pcSubKeys, pcchMaxSubKeyLen, pcValues, pcchMaxValueNameLen);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHQueryInfoKeyW(HKEY hkey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHCopyKeyA(HKEY hkeySrc, PSTR pszSrcSubKey, HKEY hkeyDest, uint32 fReserved);
	public static WIN32_ERROR SHCopyKey(HKEY hkeySrc, PSTR pszSrcSubKey, HKEY hkeyDest, uint32 fReserved) => SHCopyKeyA(hkeySrc, pszSrcSubKey, hkeyDest, fReserved);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHCopyKeyW(HKEY hkeySrc, PWSTR pszSrcSubKey, HKEY hkeyDest, uint32 fReserved);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetPathA(HKEY hKey, PSTR pcszSubKey, PSTR pcszValue, uint8* pszPath, uint32 dwFlags);
	public static WIN32_ERROR SHRegGetPath(HKEY hKey, PSTR pcszSubKey, PSTR pcszValue, uint8* pszPath, uint32 dwFlags) => SHRegGetPathA(hKey, pcszSubKey, pcszValue, pszPath, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetPathW(HKEY hKey, PWSTR pcszSubKey, PWSTR pcszValue, char16* pszPath, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegSetPathA(HKEY hKey, PSTR pcszSubKey, PSTR pcszValue, PSTR pcszPath, uint32 dwFlags);
	public static WIN32_ERROR SHRegSetPath(HKEY hKey, PSTR pcszSubKey, PSTR pcszValue, PSTR pcszPath, uint32 dwFlags) => SHRegSetPathA(hKey, pcszSubKey, pcszValue, pcszPath, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegSetPathW(HKEY hKey, PWSTR pcszSubKey, PWSTR pcszValue, PWSTR pcszPath, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegCreateUSKeyA(PSTR pszPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, uint32 dwFlags);
	public static WIN32_ERROR SHRegCreateUSKey(PSTR pszPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, uint32 dwFlags) => SHRegCreateUSKeyA(pszPath, samDesired, hRelativeUSKey, phNewUSKey, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegCreateUSKeyW(PWSTR pwzPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegOpenUSKeyA(PSTR pszPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, BOOL fIgnoreHKCU);
	public static WIN32_ERROR SHRegOpenUSKey(PSTR pszPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, BOOL fIgnoreHKCU) => SHRegOpenUSKeyA(pszPath, samDesired, hRelativeUSKey, phNewUSKey, fIgnoreHKCU);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegOpenUSKeyW(PWSTR pwzPath, uint32 samDesired, int hRelativeUSKey, int* phNewUSKey, BOOL fIgnoreHKCU);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegQueryUSValueA(int hUSKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize);
	public static WIN32_ERROR SHRegQueryUSValue(int hUSKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize) => SHRegQueryUSValueA(hUSKey, pszValue, pdwType, pvData, pcbData, fIgnoreHKCU, pvDefaultData, dwDefaultDataSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegQueryUSValueW(int hUSKey, PWSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegWriteUSValueA(int hUSKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags);
	public static WIN32_ERROR SHRegWriteUSValue(int hUSKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags) => SHRegWriteUSValueA(hUSKey, pszValue, dwType, pvData, cbData, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegWriteUSValueW(int hUSKey, PWSTR pwzValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegDeleteUSValueA(int hUSKey, PSTR pszValue, SHREGDEL_FLAGS delRegFlags);
	public static WIN32_ERROR SHRegDeleteUSValue(int hUSKey, PSTR pszValue, SHREGDEL_FLAGS delRegFlags) => SHRegDeleteUSValueA(hUSKey, pszValue, delRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegDeleteUSValueW(int hUSKey, PWSTR pwzValue, SHREGDEL_FLAGS delRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegDeleteEmptyUSKeyW(int hUSKey, PWSTR pwzSubKey, SHREGDEL_FLAGS delRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegDeleteEmptyUSKeyA(int hUSKey, PSTR pszSubKey, SHREGDEL_FLAGS delRegFlags);
	public static WIN32_ERROR SHRegDeleteEmptyUSKey(int hUSKey, PSTR pszSubKey, SHREGDEL_FLAGS delRegFlags) => SHRegDeleteEmptyUSKeyA(hUSKey, pszSubKey, delRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegEnumUSKeyA(int hUSKey, uint32 dwIndex, uint8* pszName, uint32* pcchName, SHREGENUM_FLAGS enumRegFlags);
	public static WIN32_ERROR SHRegEnumUSKey(int hUSKey, uint32 dwIndex, uint8* pszName, uint32* pcchName, SHREGENUM_FLAGS enumRegFlags) => SHRegEnumUSKeyA(hUSKey, dwIndex, pszName, pcchName, enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegEnumUSKeyW(int hUSKey, uint32 dwIndex, char16* pwzName, uint32* pcchName, SHREGENUM_FLAGS enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegEnumUSValueA(int hUSkey, uint32 dwIndex, uint8* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData, SHREGENUM_FLAGS enumRegFlags);
	public static WIN32_ERROR SHRegEnumUSValue(int hUSkey, uint32 dwIndex, uint8* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData, SHREGENUM_FLAGS enumRegFlags) => SHRegEnumUSValueA(hUSkey, dwIndex, pszValueName, pcchValueName, pdwType, pvData, pcbData, enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegEnumUSValueW(int hUSkey, uint32 dwIndex, char16* pszValueName, uint32* pcchValueName, uint32* pdwType, void* pvData, uint32* pcbData, SHREGENUM_FLAGS enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegQueryInfoUSKeyA(int hUSKey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen, SHREGENUM_FLAGS enumRegFlags);
	public static WIN32_ERROR SHRegQueryInfoUSKey(int hUSKey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen, SHREGENUM_FLAGS enumRegFlags) => SHRegQueryInfoUSKeyA(hUSKey, pcSubKeys, pcchMaxSubKeyLen, pcValues, pcchMaxValueNameLen, enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegQueryInfoUSKeyW(int hUSKey, uint32* pcSubKeys, uint32* pcchMaxSubKeyLen, uint32* pcValues, uint32* pcchMaxValueNameLen, SHREGENUM_FLAGS enumRegFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegCloseUSKey(int hUSKey);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetUSValueA(PSTR pszSubKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize);
	public static WIN32_ERROR SHRegGetUSValue(PSTR pszSubKey, PSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize) => SHRegGetUSValueA(pszSubKey, pszValue, pdwType, pvData, pcbData, fIgnoreHKCU, pvDefaultData, dwDefaultDataSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetUSValueW(PWSTR pszSubKey, PWSTR pszValue, uint32* pdwType, void* pvData, uint32* pcbData, BOOL fIgnoreHKCU, void* pvDefaultData, uint32 dwDefaultDataSize);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegSetUSValueA(PSTR pszSubKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags);
	public static WIN32_ERROR SHRegSetUSValue(PSTR pszSubKey, PSTR pszValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags) => SHRegSetUSValueA(pszSubKey, pszValue, dwType, pvData, cbData, dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegSetUSValueW(PWSTR pwzSubKey, PWSTR pwzValue, uint32 dwType, void* pvData, uint32 cbData, uint32 dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern WIN32_ERROR SHRegGetIntW(HKEY hk, PWSTR pwzKey, int32 iDefault);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHRegGetBoolUSValueA(PSTR pszSubKey, PSTR pszValue, BOOL fIgnoreHKCU, BOOL fDefault);
	public static BOOL SHRegGetBoolUSValue(PSTR pszSubKey, PSTR pszValue, BOOL fIgnoreHKCU, BOOL fDefault) => SHRegGetBoolUSValueA(pszSubKey, pszValue, fIgnoreHKCU, fDefault);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHRegGetBoolUSValueW(PWSTR pszSubKey, PWSTR pszValue, BOOL fIgnoreHKCU, BOOL fDefault);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocCreate(Guid clsid, in Guid riid, void** ppv);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryStringA(uint32 flags, ASSOCSTR str, PSTR pszAssoc, PSTR pszExtra, uint8* pszOut, uint32* pcchOut);
	public static HRESULT AssocQueryString(uint32 flags, ASSOCSTR str, PSTR pszAssoc, PSTR pszExtra, uint8* pszOut, uint32* pcchOut) => AssocQueryStringA(flags, str, pszAssoc, pszExtra, pszOut, pcchOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryStringW(uint32 flags, ASSOCSTR str, PWSTR pszAssoc, PWSTR pszExtra, char16* pszOut, uint32* pcchOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryStringByKeyA(uint32 flags, ASSOCSTR str, HKEY hkAssoc, PSTR pszExtra, uint8* pszOut, uint32* pcchOut);
	public static HRESULT AssocQueryStringByKey(uint32 flags, ASSOCSTR str, HKEY hkAssoc, PSTR pszExtra, uint8* pszOut, uint32* pcchOut) => AssocQueryStringByKeyA(flags, str, hkAssoc, pszExtra, pszOut, pcchOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryStringByKeyW(uint32 flags, ASSOCSTR str, HKEY hkAssoc, PWSTR pszExtra, char16* pszOut, uint32* pcchOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryKeyA(uint32 flags, ASSOCKEY key, PSTR pszAssoc, PSTR pszExtra, HKEY* phkeyOut);
	public static HRESULT AssocQueryKey(uint32 flags, ASSOCKEY key, PSTR pszAssoc, PSTR pszExtra, HKEY* phkeyOut) => AssocQueryKeyA(flags, key, pszAssoc, pszExtra, phkeyOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocQueryKeyW(uint32 flags, ASSOCKEY key, PWSTR pszAssoc, PWSTR pszExtra, HKEY* phkeyOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL AssocIsDangerous(PWSTR pszAssoc);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT AssocGetPerceivedType(PWSTR pszExt, PERCEIVED* ptype, uint32* pflag, PWSTR* ppszType);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* SHOpenRegStreamA(HKEY hkey, PSTR pszSubkey, PSTR pszValue, uint32 grfMode);
	public static IStream* SHOpenRegStream(HKEY hkey, PSTR pszSubkey, PSTR pszValue, uint32 grfMode) => SHOpenRegStreamA(hkey, pszSubkey, pszValue, grfMode);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* SHOpenRegStreamW(HKEY hkey, PWSTR pszSubkey, PWSTR pszValue, uint32 grfMode);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* SHOpenRegStream2A(HKEY hkey, PSTR pszSubkey, PSTR pszValue, uint32 grfMode);
	public static IStream* SHOpenRegStream2(HKEY hkey, PSTR pszSubkey, PSTR pszValue, uint32 grfMode) => SHOpenRegStream2A(hkey, pszSubkey, pszValue, grfMode);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* SHOpenRegStream2W(HKEY hkey, PWSTR pszSubkey, PWSTR pszValue, uint32 grfMode);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateStreamOnFileA(PSTR pszFile, uint32 grfMode, IStream** ppstm);
	public static HRESULT SHCreateStreamOnFile(PSTR pszFile, uint32 grfMode, IStream** ppstm) => SHCreateStreamOnFileA(pszFile, grfMode, ppstm);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateStreamOnFileW(PWSTR pszFile, uint32 grfMode, IStream** ppstm);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateStreamOnFileEx(PWSTR pszFile, uint32 grfMode, uint32 dwAttributes, BOOL fCreate, IStream* pstmTemplate, IStream** ppstm);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern IStream* SHCreateMemStream(uint8* pInit, uint32 cbInit);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAcceptLanguagesA(uint8* pszLanguages, uint32* pcchLanguages);
	public static HRESULT GetAcceptLanguages(uint8* pszLanguages, uint32* pcchLanguages) => GetAcceptLanguagesA(pszLanguages, pcchLanguages);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT GetAcceptLanguagesW(char16* pszLanguages, uint32* pcchLanguages);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void IUnknown_Set(IUnknown** ppunk, IUnknown* punk);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void IUnknown_AtomicRelease(void** ppunk);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IUnknown_GetWindow(IUnknown* punk, HWND* phwnd);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IUnknown_SetSite(IUnknown* punk, IUnknown* punkSite);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IUnknown_GetSite(IUnknown* punk, in Guid riid, void** ppv);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IUnknown_QueryService(IUnknown* punk, in Guid guidService, in Guid riid, void** ppvOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_Read(IStream* pstm, void* pv, uint32 cb);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_Write(IStream* pstm, void* pv, uint32 cb);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_Reset(IStream* pstm);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_Size(IStream* pstm, ULARGE_INTEGER* pui);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT ConnectToConnectionPoint(IUnknown* punk, in Guid riidEvent, BOOL fConnect, IUnknown* punkTarget, uint32* pdwCookie, IConnectionPoint** ppcpOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_ReadPidl(IStream* pstm, ITEMIDLIST** ppidlOut);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_WritePidl(IStream* pstm, ITEMIDLIST* pidlWrite);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_ReadStr(IStream* pstm, PWSTR* ppsz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_WriteStr(IStream* pstm, PWSTR psz);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT IStream_Copy(IStream* pstmFrom, IStream* pstmTo, uint32 cb);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetViewStatePropertyBag(ITEMIDLIST* pidl, PWSTR pszBagName, uint32 dwFlags, in Guid riid, void** ppv);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHFormatDateTimeA(FILETIME* pft, uint32* pdwFlags, uint8* pszBuf, uint32 cchBuf);
	public static int32 SHFormatDateTime(FILETIME* pft, uint32* pdwFlags, uint8* pszBuf, uint32 cchBuf) => SHFormatDateTimeA(pft, pdwFlags, pszBuf, cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHFormatDateTimeW(FILETIME* pft, uint32* pdwFlags, char16* pszBuf, uint32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHAnsiToUnicode(PSTR pszSrc, char16* pwszDst, int32 cwchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHAnsiToAnsi(PSTR pszSrc, uint8* pszDst, int32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHUnicodeToAnsi(PWSTR pwszSrc, uint8* pszDst, int32 cchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHUnicodeToUnicode(PWSTR pwzSrc, char16* pwzDst, int32 cwchBuf);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHMessageBoxCheckA(HWND hwnd, PSTR pszText, PSTR pszCaption, uint32 uType, int32 iDefault, PSTR pszRegVal);
	public static int32 SHMessageBoxCheck(HWND hwnd, PSTR pszText, PSTR pszCaption, uint32 uType, int32 iDefault, PSTR pszRegVal) => SHMessageBoxCheckA(hwnd, pszText, pszCaption, uType, iDefault, pszRegVal);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHMessageBoxCheckW(HWND hwnd, PWSTR pszText, PWSTR pszCaption, uint32 uType, int32 iDefault, PWSTR pszRegVal);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SHSendMessageBroadcastA(uint32 uMsg, WPARAM wParam, LPARAM lParam);
	public static LRESULT SHSendMessageBroadcast(uint32 uMsg, WPARAM wParam, LPARAM lParam) => SHSendMessageBroadcastA(uMsg, wParam, lParam);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern LRESULT SHSendMessageBroadcastW(uint32 uMsg, WPARAM wParam, LPARAM lParam);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern CHAR SHStripMneumonicA(PSTR pszMenu);
	public static CHAR SHStripMneumonic(PSTR pszMenu) => SHStripMneumonicA(pszMenu);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern char16 SHStripMneumonicW(PWSTR pszMenu);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsOS(OS dwOS);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHGlobalCounterGetValue(SHGLOBALCOUNTER id);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHGlobalCounterIncrement(SHGLOBALCOUNTER id);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 SHGlobalCounterDecrement(SHGLOBALCOUNTER id);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HANDLE SHAllocShared(void* pvData, uint32 dwSize, uint32 dwProcessId);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHFreeShared(HANDLE hData, uint32 dwProcessId);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void* SHLockShared(HANDLE hData, uint32 dwProcessId);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHUnlockShared(void* pvData);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 WhichPlatform();

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT QISearch(void* that, QITAB* pqit, in Guid riid, void** ppv);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHIsLowMemoryMachine(uint32 dwType);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern int32 GetMenuPosFromID(HMENU hmenu, uint32 id);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetInverseCMAP(uint8* pbMap, uint32 cbMap);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHAutoComplete(HWND hwndEdit, SHELL_AUTOCOMPLETE_FLAGS dwFlags);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHCreateThreadRef(int32* pcRef, IUnknown** ppunk);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHSetThreadRef(IUnknown* punk);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHGetThreadRef(IUnknown** ppunk);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHSkipJunction(IBindCtx* pbc, in Guid pclsid);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHCreateThread(LPTHREAD_START_ROUTINE pfnThreadProc, void* pData, uint32 flags, LPTHREAD_START_ROUTINE pfnCallback);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL SHCreateThreadWithHandle(LPTHREAD_START_ROUTINE pfnThreadProc, void* pData, uint32 flags, LPTHREAD_START_ROUTINE pfnCallback, HANDLE* pHandle);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT SHReleaseThreadRef();

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HPALETTE SHCreateShellPalette(HDC hdc);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void ColorRGBToHLS(COLORREF clrRGB, uint16* pwHue, uint16* pwLuminance, uint16* pwSaturation);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF ColorHLSToRGB(uint16 wHue, uint16 wLuminance, uint16 wSaturation);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern COLORREF ColorAdjustLuma(COLORREF clrRGB, int32 n, BOOL fScale);

	[Import("SHLWAPI.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL IsInternetESCEnabled();

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateFromMoniker(IMoniker* pimkTrgt, PWSTR pwzLocation, PWSTR pwzFriendlyName, IHlinkSite* pihlsite, uint32 dwSiteData, IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateFromString(PWSTR pwzTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, IHlinkSite* pihlsite, uint32 dwSiteData, IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateFromData(IDataObject* piDataObj, IHlinkSite* pihlsite, uint32 dwSiteData, IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkQueryCreateFromData(IDataObject* piDataObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkClone(IHlink* pihl, in Guid riid, IHlinkSite* pihlsiteForClone, uint32 dwSiteData, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateBrowseContext(IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkNavigateToStringReference(PWSTR pwzTarget, PWSTR pwzLocation, IHlinkSite* pihlsite, uint32 dwSiteData, IHlinkFrame* pihlframe, uint32 grfHLNF, IBindCtx* pibc, IBindStatusCallback* pibsc, IHlinkBrowseContext* pihlbc);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkNavigate(IHlink* pihl, IHlinkFrame* pihlframe, uint32 grfHLNF, IBindCtx* pbc, IBindStatusCallback* pibsc, IHlinkBrowseContext* pihlbc);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkOnNavigate(IHlinkFrame* pihlframe, IHlinkBrowseContext* pihlbc, uint32 grfHLNF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzFriendlyName, uint32* puHLID);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkUpdateStackItem(IHlinkFrame* pihlframe, IHlinkBrowseContext* pihlbc, uint32 uHLID, IMoniker* pimkTrgt, PWSTR pwzLocation, PWSTR pwzFriendlyName);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkOnRenameDocument(uint32 dwReserved, IHlinkBrowseContext* pihlbc, IMoniker* pimkOld, IMoniker* pimkNew);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkResolveMonikerForData(IMoniker* pimkReference, uint32 reserved, IBindCtx* pibc, uint32 cFmtetc, FORMATETC* rgFmtetc, IBindStatusCallback* pibsc, IMoniker* pimkBase);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkResolveStringForData(PWSTR pwzReference, uint32 reserved, IBindCtx* pibc, uint32 cFmtetc, FORMATETC* rgFmtetc, IBindStatusCallback* pibsc, IMoniker* pimkBase);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkParseDisplayName(IBindCtx* pibc, PWSTR pwzDisplayName, BOOL fNoForceAbs, uint32* pcchEaten, IMoniker** ppimk);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateExtensionServices(PWSTR pwzAdditionalHeaders, HWND phwnd, PWSTR pszUsername, PWSTR pszPassword, IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkPreprocessMoniker(IBindCtx* pibc, IMoniker* pimkIn, IMoniker** ppimkOut);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT OleSaveToStreamEx(IUnknown* piunk, IStream* pistm, BOOL fClearDirty);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkSetSpecialReference(uint32 uReference, PWSTR pwzReference);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkGetSpecialReference(uint32 uReference, PWSTR* ppwzReference);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateShortcut(uint32 grfHLSHORTCUTF, IHlink* pihl, PWSTR pwzDir, PWSTR pwzFileName, PWSTR* ppwzShortcutFile, uint32 dwReserved);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateShortcutFromMoniker(uint32 grfHLSHORTCUTF, IMoniker* pimkTarget, PWSTR pwzLocation, PWSTR pwzDir, PWSTR pwzFileName, PWSTR* ppwzShortcutFile, uint32 dwReserved);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkCreateShortcutFromString(uint32 grfHLSHORTCUTF, PWSTR pwzTarget, PWSTR pwzLocation, PWSTR pwzDir, PWSTR pwzFileName, PWSTR* ppwzShortcutFile, uint32 dwReserved);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkResolveShortcut(PWSTR pwzShortcutFileName, IHlinkSite* pihlsite, uint32 dwSiteData, IUnknown* piunkOuter, in Guid riid, void** ppvObj);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkResolveShortcutToMoniker(PWSTR pwzShortcutFileName, IMoniker** ppimkTarget, PWSTR* ppwzLocation);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkResolveShortcutToString(PWSTR pwzShortcutFileName, PWSTR* ppwzTarget, PWSTR* ppwzLocation);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkIsShortcut(PWSTR pwzFileName);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkGetValueFromParams(PWSTR pwzParams, PWSTR pwzName, PWSTR* ppwzValue);

	[Import("hlink.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT HlinkTranslateURL(PWSTR pwzURL, uint32 grfFlags, PWSTR* ppwzTranslatedURL);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathIsUNCEx(PWSTR pszPath, PWSTR* ppszServer);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern BOOL PathCchIsRoot(PWSTR pszPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchAddBackslashEx(char16* pszPath, uint cchPath, PWSTR* ppszEnd, uint* pcchRemaining);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchAddBackslash(char16* pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchRemoveBackslashEx(PWSTR pszPath, uint cchPath, PWSTR* ppszEnd, uint* pcchRemaining);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchRemoveBackslash(char16* pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchSkipRoot(PWSTR pszPath, PWSTR* ppszRootEnd);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchStripToRoot(PWSTR pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchRemoveFileSpec(PWSTR pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchFindExtension(PWSTR pszPath, uint cchPath, PWSTR* ppszExt);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchAddExtension(char16* pszPath, uint cchPath, PWSTR pszExt);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchRenameExtension(char16* pszPath, uint cchPath, PWSTR pszExt);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchRemoveExtension(PWSTR pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchCanonicalizeEx(char16* pszPathOut, uint cchPathOut, PWSTR pszPathIn, PATHCCH_OPTIONS dwFlags);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchCanonicalize(char16* pszPathOut, uint cchPathOut, PWSTR pszPathIn);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchCombineEx(char16* pszPathOut, uint cchPathOut, PWSTR pszPathIn, PWSTR pszMore, PATHCCH_OPTIONS dwFlags);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchCombine(char16* pszPathOut, uint cchPathOut, PWSTR pszPathIn, PWSTR pszMore);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchAppendEx(char16* pszPath, uint cchPath, PWSTR pszMore, PATHCCH_OPTIONS dwFlags);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchAppend(char16* pszPath, uint cchPath, PWSTR pszMore);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathCchStripPrefix(char16* pszPath, uint cchPath);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathAllocCombine(PWSTR pszPathIn, PWSTR pszMore, PATHCCH_OPTIONS dwFlags, PWSTR* ppszPathOut);

	[Import("api-ms-win-core-path-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT PathAllocCanonicalize(PWSTR pszPathIn, PATHCCH_OPTIONS dwFlags, PWSTR* ppszPathOut);

	[Import("api-ms-win-core-psm-appnotify-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterAppStateChangeNotification(PAPPSTATE_CHANGE_ROUTINE Routine, void* Context, _APPSTATE_REGISTRATION** Registration);

	[Import("api-ms-win-core-psm-appnotify-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UnregisterAppStateChangeNotification(_APPSTATE_REGISTRATION* Registration);

	[Import("api-ms-win-core-psm-appnotify-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 RegisterAppConstrainedChangeNotification(PAPPCONSTRAIN_CHANGE_ROUTINE Routine, void* Context, _APPCONSTRAIN_REGISTRATION** Registration);

	[Import("api-ms-win-core-psm-appnotify-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void UnregisterAppConstrainedChangeNotification(_APPCONSTRAIN_REGISTRATION* Registration);

}
#endregion
