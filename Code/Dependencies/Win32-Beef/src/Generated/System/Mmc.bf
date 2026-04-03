using Win32.Foundation;
using Win32.System.Com;
using Win32.UI.Controls;
using Win32.Graphics.Gdi;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.System.Mmc;

#region Constants
public static
{
	public const uint32 MMC_VER = 512;
	public const uint32 MMC_PROP_CHANGEAFFECTSUI = 1;
	public const uint32 MMC_PROP_MODIFIABLE = 2;
	public const uint32 MMC_PROP_REMOVABLE = 4;
	public const uint32 MMC_PROP_PERSIST = 8;
	public const int32 MMCLV_AUTO = -1;
	public const int32 MMCLV_NOPARAM = -2;
	public const int32 MMCLV_NOICON = -1;
	public const uint32 MMCLV_VIEWSTYLE_ICON = 0;
	public const uint32 MMCLV_VIEWSTYLE_SMALLICON = 2;
	public const uint32 MMCLV_VIEWSTYLE_LIST = 3;
	public const uint32 MMCLV_VIEWSTYLE_REPORT = 1;
	public const uint32 MMCLV_VIEWSTYLE_FILTERED = 4;
	public const uint32 MMCLV_NOPTR = 0;
	public const uint32 MMCLV_UPDATE_NOINVALIDATEALL = 1;
	public const uint32 MMCLV_UPDATE_NOSCROLL = 2;
	public const int32 MMC_IMAGECALLBACK = -1;
	public const uint32 RDI_STR = 2;
	public const uint32 RDI_IMAGE = 4;
	public const uint32 RDI_STATE = 8;
	public const uint32 RDI_PARAM = 16;
	public const uint32 RDI_INDEX = 32;
	public const uint32 RDI_INDENT = 64;
	public const uint32 MMC_VIEW_OPTIONS_NONE = 0;
	public const uint32 MMC_VIEW_OPTIONS_NOLISTVIEWS = 1;
	public const uint32 MMC_VIEW_OPTIONS_MULTISELECT = 2;
	public const uint32 MMC_VIEW_OPTIONS_OWNERDATALIST = 4;
	public const uint32 MMC_VIEW_OPTIONS_FILTERED = 8;
	public const uint32 MMC_VIEW_OPTIONS_CREATENEW = 16;
	public const uint32 MMC_VIEW_OPTIONS_USEFONTLINKING = 32;
	public const uint32 MMC_VIEW_OPTIONS_EXCLUDE_SCOPE_ITEMS_FROM_LIST = 64;
	public const uint32 MMC_VIEW_OPTIONS_LEXICAL_SORT = 128;
	public const uint32 MMC_PSO_NOAPPLYNOW = 1;
	public const uint32 MMC_PSO_HASHELP = 2;
	public const uint32 MMC_PSO_NEWWIZARDTYPE = 4;
	public const uint32 MMC_PSO_NO_PROPTITLE = 8;
	public const uint32 RFI_PARTIAL = 1;
	public const uint32 RFI_WRAP = 2;
	public const uint32 RSI_DESCENDING = 1;
	public const uint32 RSI_NOSORTICON = 2;
	public const uint32 SDI_STR = 2;
	public const uint32 SDI_IMAGE = 4;
	public const uint32 SDI_OPENIMAGE = 8;
	public const uint32 SDI_STATE = 16;
	public const uint32 SDI_PARAM = 32;
	public const uint32 SDI_CHILDREN = 64;
	public const uint32 SDI_PARENT = 0;
	public const uint32 SDI_PREVIOUS = 268435456;
	public const uint32 SDI_NEXT = 536870912;
	public const uint32 SDI_FIRST = 134217728;
	public const int32 MMC_MULTI_SELECT_COOKIE = -2;
	public const int32 MMC_WINDOW_COOKIE = -3;
	public const int32 SPECIAL_COOKIE_MIN = -10;
	public const int32 SPECIAL_COOKIE_MAX = -1;
	public const uint32 MMC_NW_OPTION_NONE = 0;
	public const uint32 MMC_NW_OPTION_NOSCOPEPANE = 1;
	public const uint32 MMC_NW_OPTION_NOTOOLBARS = 2;
	public const uint32 MMC_NW_OPTION_SHORTTITLE = 4;
	public const uint32 MMC_NW_OPTION_CUSTOMTITLE = 8;
	public const uint32 MMC_NW_OPTION_NOPERSIST = 16;
	public const uint32 MMC_NW_OPTION_NOACTIONPANE = 32;
	public const uint32 MMC_NODEID_SLOW_RETRIEVAL = 1;
	public const int32 SPECIAL_DOBJ_MIN = -10;
	public const uint32 SPECIAL_DOBJ_MAX = 0;
	public const int32 AUTO_WIDTH = -1;
	public const int32 HIDE_COLUMN = -4;
	public const uint32 ILSIF_LEAVE_LARGE_ICON = 1073741824;
	public const uint32 ILSIF_LEAVE_SMALL_ICON = 536870912;
	public const uint32 HDI_HIDDEN = 1;
	public const uint32 RDCI_ScopeItem = 2147483648;
	public const uint32 RVTI_MISC_OPTIONS_NOLISTVIEWS = 1;
	public const uint32 RVTI_LIST_OPTIONS_NONE = 0;
	public const uint32 RVTI_LIST_OPTIONS_OWNERDATALIST = 2;
	public const uint32 RVTI_LIST_OPTIONS_MULTISELECT = 4;
	public const uint32 RVTI_LIST_OPTIONS_FILTERED = 8;
	public const uint32 RVTI_LIST_OPTIONS_USEFONTLINKING = 32;
	public const uint32 RVTI_LIST_OPTIONS_EXCLUDE_SCOPE_ITEMS_FROM_LIST = 64;
	public const uint32 RVTI_LIST_OPTIONS_LEXICAL_SORT = 128;
	public const uint32 RVTI_LIST_OPTIONS_ALLOWPASTE = 256;
	public const uint32 RVTI_HTML_OPTIONS_NONE = 0;
	public const uint32 RVTI_HTML_OPTIONS_NOLISTVIEW = 1;
	public const uint32 RVTI_OCX_OPTIONS_NONE = 0;
	public const uint32 RVTI_OCX_OPTIONS_NOLISTVIEW = 1;
	public const uint32 RVTI_OCX_OPTIONS_CACHE_OCX = 2;
	public const uint32 MMC_DEFAULT_OPERATION_COPY = 1;
	public const uint32 MMC_ITEM_OVERLAY_STATE_MASK = 3840;
	public const uint32 MMC_ITEM_OVERLAY_STATE_SHIFT = 8;
	public const uint32 MMC_ITEM_STATE_MASK = 255;
}
#endregion

#region Enums

[AllowDuplicates]
public enum MMC_PROPERTY_ACTION : int32
{
	MMC_PROPACT_DELETING = 1,
	MMC_PROPACT_CHANGING = 2,
	MMC_PROPACT_INITIALIZED = 3,
}


[AllowDuplicates]
public enum _DocumentMode : int32
{
	DocumentMode_Author = 0,
	DocumentMode_User = 1,
	DocumentMode_User_MDI = 2,
	DocumentMode_User_SDI = 3,
}


[AllowDuplicates]
public enum _ListViewMode : int32
{
	ListMode_Small_Icons = 0,
	ListMode_Large_Icons = 1,
	ListMode_List = 2,
	ListMode_Detail = 3,
	ListMode_Filtered = 4,
}


[AllowDuplicates]
public enum _ViewOptions : int32
{
	ViewOption_Default = 0,
	ViewOption_ScopeTreeHidden = 1,
	ViewOption_NoToolBars = 2,
	ViewOption_NotPersistable = 4,
	ViewOption_ActionPaneHidden = 8,
}


[AllowDuplicates]
public enum _ExportListOptions : int32
{
	ExportListOptions_Default = 0,
	ExportListOptions_Unicode = 1,
	ExportListOptions_TabDelimited = 2,
	ExportListOptions_SelectedItemsOnly = 4,
}


[AllowDuplicates]
public enum _ColumnSortOrder : int32
{
	SortOrder_Ascending = 0,
	SortOrder_Descending = 1,
}


[AllowDuplicates]
public enum MMC_RESULT_VIEW_STYLE : int32
{
	MMC_SINGLESEL = 1,
	MMC_SHOWSELALWAYS = 2,
	MMC_NOSORTHEADER = 4,
	MMC_ENSUREFOCUSVISIBLE = 8,
}


[AllowDuplicates]
public enum MMC_CONTROL_TYPE : int32
{
	TOOLBAR = 0,
	MENUBUTTON = 1,
	COMBOBOXBAR = 2,
}


[AllowDuplicates]
public enum MMC_CONSOLE_VERB : int32
{
	MMC_VERB_NONE = 0,
	MMC_VERB_OPEN = 32768,
	MMC_VERB_COPY = 32769,
	MMC_VERB_PASTE = 32770,
	MMC_VERB_DELETE = 32771,
	MMC_VERB_PROPERTIES = 32772,
	MMC_VERB_RENAME = 32773,
	MMC_VERB_REFRESH = 32774,
	MMC_VERB_PRINT = 32775,
	MMC_VERB_CUT = 32776,
	MMC_VERB_MAX = 32777,
	MMC_VERB_FIRST = 32768,
	MMC_VERB_LAST = 32776,
}


[AllowDuplicates]
public enum MMC_BUTTON_STATE : int32
{
	ENABLED = 1,
	CHECKED = 2,
	HIDDEN = 4,
	INDETERMINATE = 8,
	BUTTONPRESSED = 16,
}


[AllowDuplicates]
public enum MMC_SCOPE_ITEM_STATE : int32
{
	MMC_SCOPE_ITEM_STATE_NORMAL = 1,
	MMC_SCOPE_ITEM_STATE_BOLD = 2,
	MMC_SCOPE_ITEM_STATE_EXPANDEDONCE = 3,
}


[AllowDuplicates]
public enum MMC_MENU_COMMAND_IDS : int32
{
	MMCC_STANDARD_VIEW_SELECT = -1,
}


[AllowDuplicates]
public enum MMC_FILTER_TYPE : int32
{
	MMC_STRING_FILTER = 0,
	MMC_INT_FILTER = 1,
	MMC_FILTER_NOVALUE = 32768,
}


[AllowDuplicates]
public enum MMC_FILTER_CHANGE_CODE : int32
{
	MFCC_DISABLE = 0,
	MFCC_ENABLE = 1,
	MFCC_VALUE_CHANGE = 2,
}


[AllowDuplicates]
public enum MMC_NOTIFY_TYPE : int32
{
	MMCN_ACTIVATE = 32769,
	MMCN_ADD_IMAGES = 32770,
	MMCN_BTN_CLICK = 32771,
	MMCN_CLICK = 32772,
	MMCN_COLUMN_CLICK = 32773,
	MMCN_CONTEXTMENU = 32774,
	MMCN_CUTORMOVE = 32775,
	MMCN_DBLCLICK = 32776,
	MMCN_DELETE = 32777,
	MMCN_DESELECT_ALL = 32778,
	MMCN_EXPAND = 32779,
	MMCN_HELP = 32780,
	MMCN_MENU_BTNCLICK = 32781,
	MMCN_MINIMIZED = 32782,
	MMCN_PASTE = 32783,
	MMCN_PROPERTY_CHANGE = 32784,
	MMCN_QUERY_PASTE = 32785,
	MMCN_REFRESH = 32786,
	MMCN_REMOVE_CHILDREN = 32787,
	MMCN_RENAME = 32788,
	MMCN_SELECT = 32789,
	MMCN_SHOW = 32790,
	MMCN_VIEW_CHANGE = 32791,
	MMCN_SNAPINHELP = 32792,
	MMCN_CONTEXTHELP = 32793,
	MMCN_INITOCX = 32794,
	MMCN_FILTER_CHANGE = 32795,
	MMCN_FILTERBTN_CLICK = 32796,
	MMCN_RESTORE_VIEW = 32797,
	MMCN_PRINT = 32798,
	MMCN_PRELOAD = 32799,
	MMCN_LISTPAD = 32800,
	MMCN_EXPANDSYNC = 32801,
	MMCN_COLUMNS_CHANGED = 32802,
	MMCN_CANPASTE_OUTOFPROC = 32803,
}


[AllowDuplicates]
public enum DATA_OBJECT_TYPES : int32
{
	CCT_SCOPE = 32768,
	CCT_RESULT = 32769,
	CCT_SNAPIN_MANAGER = 32770,
	CCT_UNINITIALIZED = 65535,
}


[AllowDuplicates]
public enum CCM_INSERTIONPOINTID : int32
{
	CCM_INSERTIONPOINTID_MASK_SPECIAL = -65536,
	CCM_INSERTIONPOINTID_MASK_SHARED = -2147483648,
	CCM_INSERTIONPOINTID_MASK_CREATE_PRIMARY = 1073741824,
	CCM_INSERTIONPOINTID_MASK_ADD_PRIMARY = 536870912,
	CCM_INSERTIONPOINTID_MASK_ADD_3RDPARTY = 268435456,
	CCM_INSERTIONPOINTID_MASK_RESERVED = 268369920,
	CCM_INSERTIONPOINTID_MASK_FLAGINDEX = 31,
	CCM_INSERTIONPOINTID_PRIMARY_TOP = -1610612736,
	CCM_INSERTIONPOINTID_PRIMARY_NEW = -1610612735,
	CCM_INSERTIONPOINTID_PRIMARY_TASK = -1610612734,
	CCM_INSERTIONPOINTID_PRIMARY_VIEW = -1610612733,
	CCM_INSERTIONPOINTID_PRIMARY_HELP = -1610612732,
	CCM_INSERTIONPOINTID_3RDPARTY_NEW = -1879048191,
	CCM_INSERTIONPOINTID_3RDPARTY_TASK = -1879048190,
	CCM_INSERTIONPOINTID_ROOT_MENU = -2147483648,
}


[AllowDuplicates]
public enum CCM_INSERTIONALLOWED : int32
{
	CCM_INSERTIONALLOWED_TOP = 1,
	CCM_INSERTIONALLOWED_NEW = 2,
	CCM_INSERTIONALLOWED_TASK = 4,
	CCM_INSERTIONALLOWED_VIEW = 8,
}


[AllowDuplicates]
public enum CCM_COMMANDID_MASK_CONSTANTS : uint32
{
	CCM_COMMANDID_MASK_RESERVED = 4294901760,
}


[AllowDuplicates]
public enum CCM_SPECIAL : int32
{
	CCM_SPECIAL_SEPARATOR = 1,
	CCM_SPECIAL_SUBMENU = 2,
	CCM_SPECIAL_DEFAULT_ITEM = 4,
	CCM_SPECIAL_INSERTION_POINT = 8,
	CCM_SPECIAL_TESTONLY = 16,
}


[AllowDuplicates]
public enum MMC_TASK_DISPLAY_TYPE : int32
{
	MMC_TASK_DISPLAY_UNINITIALIZED = 0,
	MMC_TASK_DISPLAY_TYPE_SYMBOL = 1,
	MMC_TASK_DISPLAY_TYPE_VANILLA_GIF = 2,
	MMC_TASK_DISPLAY_TYPE_CHOCOLATE_GIF = 3,
	MMC_TASK_DISPLAY_TYPE_BITMAP = 4,
}


[AllowDuplicates]
public enum MMC_ACTION_TYPE : int32
{
	MMC_ACTION_UNINITIALIZED = -1,
	MMC_ACTION_ID = 0,
	MMC_ACTION_LINK = 1,
	MMC_ACTION_SCRIPT = 2,
}


[AllowDuplicates]
public enum IconIdentifier : int32
{
	Icon_None = 0,
	Icon_Error = 32513,
	Icon_Question = 32514,
	Icon_Warning = 32515,
	Icon_Information = 32516,
	Icon_First = 32513,
	Icon_Last = 32516,
}


[AllowDuplicates]
public enum MMC_VIEW_TYPE : int32
{
	MMC_VIEW_TYPE_LIST = 0,
	MMC_VIEW_TYPE_HTML = 1,
	MMC_VIEW_TYPE_OCX = 2,
}

#endregion


#region Structs
[CRepr]
public struct MMC_SNAPIN_PROPERTY
{
	public PWSTR pszPropName;
	public VARIANT varValue;
	public MMC_PROPERTY_ACTION eAction;
}

[CRepr]
public struct MMCBUTTON
{
	public int32 nBitmap;
	public int32 idCommand;
	public uint8 fsState;
	public uint8 fsType;
	public PWSTR lpButtonText;
	public PWSTR lpTooltipText;
}

[CRepr]
public struct RESULTDATAITEM
{
	public uint32 mask;
	public BOOL bScopeItem;
	public int itemID;
	public int32 nIndex;
	public int32 nCol;
	public PWSTR str;
	public int32 nImage;
	public uint32 nState;
	public LPARAM lParam;
	public int32 iIndent;
}

[CRepr]
public struct RESULTFINDINFO
{
	public PWSTR psz;
	public int32 nStart;
	public uint32 dwOptions;
}

[CRepr]
public struct SCOPEDATAITEM
{
	public uint32 mask;
	public PWSTR displayname;
	public int32 nImage;
	public int32 nOpenImage;
	public uint32 nState;
	public int32 cChildren;
	public LPARAM lParam;
	public int relativeID;
	public int ID;
}

[CRepr]
public struct CONTEXTMENUITEM
{
	public PWSTR strName;
	public PWSTR strStatusBarText;
	public int32 lCommandID;
	public int32 lInsertionPointID;
	public int32 fFlags;
	public int32 fSpecialFlags;
}

[CRepr]
public struct MENUBUTTONDATA
{
	public int32 idCommand;
	public int32 x;
	public int32 y;
}

[CRepr]
public struct MMC_FILTERDATA
{
	public PWSTR pszText;
	public int32 cchTextMax;
	public int32 lValue;
}

[CRepr]
public struct MMC_RESTORE_VIEW
{
	public uint32 dwSize;
	public int cookie;
	public PWSTR pViewType;
	public int32 lViewOptions;
}

[CRepr]
public struct MMC_EXPANDSYNC_STRUCT
{
	public BOOL bHandled;
	public BOOL bExpanding;
	public int hItem;
}

[CRepr]
public struct MMC_VISIBLE_COLUMNS
{
	public int32 nVisibleColumns;
	public int32* rgVisibleCols mut => &rgVisibleCols_impl;
	private int32[ANYSIZE_ARRAY] rgVisibleCols_impl;
}

[CRepr]
public struct SMMCDataObjects
{
	public uint32 count;
	public IDataObject** lpDataObject mut => &lpDataObject_impl;
	private IDataObject*[ANYSIZE_ARRAY] lpDataObject_impl;
}

[CRepr]
public struct SMMCObjectTypes
{
	public uint32 count;
	public Guid* guid mut => &guid_impl;
	private Guid[ANYSIZE_ARRAY] guid_impl;
}

[CRepr]
public struct SNodeID
{
	public uint32 cBytes;
	public uint8* id mut => &id_impl;
	private uint8[ANYSIZE_ARRAY] id_impl;
}

[CRepr]
public struct SNodeID2
{
	public uint32 dwFlags;
	public uint32 cBytes;
	public uint8* id mut => &id_impl;
	private uint8[ANYSIZE_ARRAY] id_impl;
}

[CRepr]
public struct SColumnSetID
{
	public uint32 dwFlags;
	public uint32 cBytes;
	public uint8* id mut => &id_impl;
	private uint8[ANYSIZE_ARRAY] id_impl;
}

[CRepr]
public struct MMC_TASK_DISPLAY_SYMBOL
{
	public PWSTR szFontFamilyName;
	public PWSTR szURLtoEOT;
	public PWSTR szSymbolString;
}

[CRepr]
public struct MMC_TASK_DISPLAY_BITMAP
{
	public PWSTR szMouseOverBitmap;
	public PWSTR szMouseOffBitmap;
}

[CRepr]
public struct MMC_TASK_DISPLAY_OBJECT
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public MMC_TASK_DISPLAY_BITMAP uBitmap;
		public MMC_TASK_DISPLAY_SYMBOL uSymbol;
	}
	public MMC_TASK_DISPLAY_TYPE eDisplayType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MMC_TASK
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int nCommandID;
		public PWSTR szActionURL;
		public PWSTR szScript;
	}
	public MMC_TASK_DISPLAY_OBJECT sDisplayObject;
	public PWSTR szText;
	public PWSTR szHelpString;
	public MMC_ACTION_TYPE eActionType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MMC_LISTPAD_INFO
{
	public PWSTR szTitle;
	public PWSTR szButtonText;
	public int nCommandID;
}

[CRepr]
public struct MMC_COLUMN_DATA
{
	public int32 nColIndex;
	public uint32 dwFlags;
	public int32 nWidth;
	public uint ulReserved;
}

[CRepr]
public struct MMC_COLUMN_SET_DATA
{
	public int32 cbSize;
	public int32 nNumCols;
	public MMC_COLUMN_DATA* pColData;
}

[CRepr]
public struct MMC_SORT_DATA
{
	public int32 nColIndex;
	public uint32 dwSortOptions;
	public uint ulReserved;
}

[CRepr]
public struct MMC_SORT_SET_DATA
{
	public int32 cbSize;
	public int32 nNumItems;
	public MMC_SORT_DATA* pSortData;
}

[CRepr]
public struct RDITEMHDR
{
	public uint32 dwFlags;
	public int cookie;
	public LPARAM lpReserved;
}

[CRepr]
public struct RDCOMPARE
{
	public uint32 cbSize;
	public uint32 dwFlags;
	public int32 nColumn;
	public LPARAM lUserParam;
	public RDITEMHDR* prdch1;
	public RDITEMHDR* prdch2;
}

[CRepr]
public struct RESULT_VIEW_TYPE_INFO
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		[CRepr]
		public struct _Anonymous2_e__Struct
		{
			public uint32 dwOCXOptions;
			public IUnknown* pUnkControl;
		}
		[CRepr]
		public struct _Anonymous1_e__Struct
		{
			public uint32 dwHTMLOptions;
			public PWSTR pstrURL;
		}
		public uint32 dwListOptions;
		public using _Anonymous1_e__Struct Anonymous1;
		public using _Anonymous2_e__Struct Anonymous2;
	}
	public PWSTR pstrPersistableViewDescription;
	public MMC_VIEW_TYPE eViewType;
	public uint32 dwMiscOptions;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct CONTEXTMENUITEM2
{
	public PWSTR strName;
	public PWSTR strStatusBarText;
	public int32 lCommandID;
	public int32 lInsertionPointID;
	public int32 fFlags;
	public int32 fSpecialFlags;
	public PWSTR strLanguageIndependentName;
}

[CRepr]
public struct MMC_EXT_VIEW_DATA
{
	public Guid viewID;
	public PWSTR pszURL;
	public PWSTR pszViewTitle;
	public PWSTR pszTooltipText;
	public BOOL bReplacesDefaultView;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_Application = .(0x49b2791a, 0xb1ae, 0x4c90, 0x9b, 0x8e, 0xe8, 0x60, 0xba, 0x07, 0xf8, 0x89);


	public const Guid CLSID_AppEventsDHTMLConnector = .(0xade6444b, 0xc91f, 0x4e37, 0x92, 0xa4, 0x5b, 0xb4, 0x30, 0xa3, 0x33, 0x40);


	public const Guid CLSID_MMCVersionInfo = .(0xd6fedb1d, 0xcf21, 0x4bd9, 0xaf, 0x3b, 0xc5, 0x46, 0x8e, 0x9c, 0x66, 0x84);


	public const Guid CLSID_ConsolePower = .(0xf0285374, 0xdff1, 0x11d3, 0xb4, 0x33, 0x00, 0xc0, 0x4f, 0x8e, 0xcd, 0x78);


}
#endregion

#region COM Types
[CRepr]struct ISnapinProperties : IUnknown
{
	public new const Guid IID = .(0xf7889da9, 0x4a02, 0x4837, 0xbf, 0x89, 0x1a, 0x6f, 0x2a, 0x02, 0x10, 0x10);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Properties* pProperties) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ISnapinPropertiesCallback* pCallback) QueryPropertyNames;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 cProperties, MMC_SNAPIN_PROPERTY* pProperties) PropertiesChanged;
	}


	public HRESULT Initialize(Properties* pProperties) mut => VT.[Friend]Initialize(&this, pProperties);

	public HRESULT QueryPropertyNames(ISnapinPropertiesCallback* pCallback) mut => VT.[Friend]QueryPropertyNames(&this, pCallback);

	public HRESULT PropertiesChanged(int32 cProperties, MMC_SNAPIN_PROPERTY* pProperties) mut => VT.[Friend]PropertiesChanged(&this, cProperties, pProperties);
}

[CRepr]struct ISnapinPropertiesCallback : IUnknown
{
	public new const Guid IID = .(0xa50fa2e5, 0x7e61, 0x45eb, 0xa8, 0xd4, 0x9a, 0x07, 0xb3, 0xe8, 0x51, 0xa8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropName, uint32 dwFlags) AddPropertyName;
	}


	public HRESULT AddPropertyName(PWSTR pszPropName, uint32 dwFlags) mut => VT.[Friend]AddPropertyName(&this, pszPropName, dwFlags);
}

[CRepr]struct _Application : IDispatch
{
	public new const Guid IID = .(0xa3afb9cc, 0xb653, 0x4741, 0x86, 0xab, 0xf0, 0x47, 0x0e, 0xc1, 0x38, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Help;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self) Quit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document** Document) get_Document;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Filename) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Frame** Frame) get_Frame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Visible) get_Visible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Show;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Hide;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* UserControl) get_UserControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL UserControl) put_UserControl;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* VersionMajor) get_VersionMajor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* VersionMinor) get_VersionMinor;
	}


	public void Help() mut => VT.[Friend]Help(&this);

	public void Quit() mut => VT.[Friend]Quit(&this);

	public HRESULT get_Document(Document** Document) mut => VT.[Friend]get_Document(&this, Document);

	public HRESULT Load(BSTR Filename) mut => VT.[Friend]Load(&this, Filename);

	public HRESULT get_Frame(Frame** Frame) mut => VT.[Friend]get_Frame(&this, Frame);

	public HRESULT get_Visible(BOOL* Visible) mut => VT.[Friend]get_Visible(&this, Visible);

	public HRESULT Show() mut => VT.[Friend]Show(&this);

	public HRESULT Hide() mut => VT.[Friend]Hide(&this);

	public HRESULT get_UserControl(BOOL* UserControl) mut => VT.[Friend]get_UserControl(&this, UserControl);

	public HRESULT put_UserControl(BOOL UserControl) mut => VT.[Friend]put_UserControl(&this, UserControl);

	public HRESULT get_VersionMajor(int32* VersionMajor) mut => VT.[Friend]get_VersionMajor(&this, VersionMajor);

	public HRESULT get_VersionMinor(int32* VersionMinor) mut => VT.[Friend]get_VersionMinor(&this, VersionMinor);
}

[CRepr]struct _AppEvents : IDispatch
{
	public new const Guid IID = .(0xde46cbdd, 0x53f5, 0x4635, 0xaf, 0x54, 0x4f, 0xe7, 0x1e, 0x92, 0x3d, 0x3f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _Application* Application) OnQuit;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document* Document, BOOL New) OnDocumentOpen;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document* Document) OnDocumentClose;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document* Document, SnapIn* SnapIn) OnSnapInAdded;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document* Document, SnapIn* SnapIn) OnSnapInRemoved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View) OnNewView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View) OnViewClose;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View, Node* NewOwnerNode) OnViewChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View, Nodes* NewNodes) OnSelectionChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MenuItem* MenuItem) OnContextMenuExecuted;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) OnToolbarButtonClicked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View) OnListUpdated;
	}


	public HRESULT OnQuit(_Application* Application) mut => VT.[Friend]OnQuit(&this, Application);

	public HRESULT OnDocumentOpen(Document* Document, BOOL New) mut => VT.[Friend]OnDocumentOpen(&this, Document, New);

	public HRESULT OnDocumentClose(Document* Document) mut => VT.[Friend]OnDocumentClose(&this, Document);

	public HRESULT OnSnapInAdded(Document* Document, SnapIn* SnapIn) mut => VT.[Friend]OnSnapInAdded(&this, Document, SnapIn);

	public HRESULT OnSnapInRemoved(Document* Document, SnapIn* SnapIn) mut => VT.[Friend]OnSnapInRemoved(&this, Document, SnapIn);

	public HRESULT OnNewView(View* View) mut => VT.[Friend]OnNewView(&this, View);

	public HRESULT OnViewClose(View* View) mut => VT.[Friend]OnViewClose(&this, View);

	public HRESULT OnViewChange(View* View, Node* NewOwnerNode) mut => VT.[Friend]OnViewChange(&this, View, NewOwnerNode);

	public HRESULT OnSelectionChange(View* View, Nodes* NewNodes) mut => VT.[Friend]OnSelectionChange(&this, View, NewNodes);

	public HRESULT OnContextMenuExecuted(MenuItem* MenuItem) mut => VT.[Friend]OnContextMenuExecuted(&this, MenuItem);

	public HRESULT OnToolbarButtonClicked() mut => VT.[Friend]OnToolbarButtonClicked(&this);

	public HRESULT OnListUpdated(View* View) mut => VT.[Friend]OnListUpdated(&this, View);
}

[CRepr]struct AppEvents : IDispatch
{
	public new const Guid IID = .(0xfc7a4252, 0x78ac, 0x4532, 0x8c, 0x5a, 0x56, 0x3c, 0xfe, 0x13, 0x88, 0x63);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
	}

}

[CRepr]struct _EventConnector : IDispatch
{
	public new const Guid IID = .(0xc0bccd30, 0xde44, 0x4528, 0x84, 0x03, 0xa0, 0x5a, 0x6a, 0x1c, 0xc8, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _Application* Application) ConnectTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Disconnect;
	}


	public HRESULT ConnectTo(_Application* Application) mut => VT.[Friend]ConnectTo(&this, Application);

	public HRESULT Disconnect() mut => VT.[Friend]Disconnect(&this);
}

[CRepr]struct Frame : IDispatch
{
	public new const Guid IID = .(0xe5e2d970, 0x5bb3, 0x4306, 0x88, 0x04, 0xb0, 0x96, 0x8a, 0x31, 0xc8, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Maximize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Minimize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Restore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Top) get_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 top) put_Top;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Bottom) get_Bottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 bottom) put_Bottom;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Left) get_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 left) put_Left;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Right) get_Right;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 right) put_Right;
	}


	public HRESULT Maximize() mut => VT.[Friend]Maximize(&this);

	public HRESULT Minimize() mut => VT.[Friend]Minimize(&this);

	public HRESULT Restore() mut => VT.[Friend]Restore(&this);

	public HRESULT get_Top(int32* Top) mut => VT.[Friend]get_Top(&this, Top);

	public HRESULT put_Top(int32 top) mut => VT.[Friend]put_Top(&this, top);

	public HRESULT get_Bottom(int32* Bottom) mut => VT.[Friend]get_Bottom(&this, Bottom);

	public HRESULT put_Bottom(int32 bottom) mut => VT.[Friend]put_Bottom(&this, bottom);

	public HRESULT get_Left(int32* Left) mut => VT.[Friend]get_Left(&this, Left);

	public HRESULT put_Left(int32 left) mut => VT.[Friend]put_Left(&this, left);

	public HRESULT get_Right(int32* Right) mut => VT.[Friend]get_Right(&this, Right);

	public HRESULT put_Right(int32 right) mut => VT.[Friend]put_Right(&this, right);
}

[CRepr]struct Node : IDispatch
{
	public new const Guid IID = .(0xf81ed800, 0x7839, 0x4447, 0x94, 0x5d, 0x8e, 0x15, 0xda, 0x59, 0xca, 0x55);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR PropertyName, uint16** PropertyValue) get_Property;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Bookmark) get_Bookmark;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* IsScopeNode) IsScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Nodetype) get_Nodetype;
	}


	public HRESULT get_Name(uint16** Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Property(BSTR PropertyName, uint16** PropertyValue) mut => VT.[Friend]get_Property(&this, PropertyName, PropertyValue);

	public HRESULT get_Bookmark(uint16** Bookmark) mut => VT.[Friend]get_Bookmark(&this, Bookmark);

	public HRESULT IsScopeNode(BOOL* IsScopeNode) mut => VT.[Friend]IsScopeNode(&this, IsScopeNode);

	public HRESULT get_Nodetype(uint16** Nodetype) mut => VT.[Friend]get_Nodetype(&this, Nodetype);
}

[CRepr]struct ScopeNamespace : IDispatch
{
	public new const Guid IID = .(0xebbb48dc, 0x1a3b, 0x4d86, 0xb7, 0x86, 0xc2, 0x1b, 0x28, 0x38, 0x90, 0x12);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, Node** Parent) GetParent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, Node** Child) GetChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, Node** Next) GetNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node** Root) GetRoot;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node) Expand;
	}


	public HRESULT GetParent(Node* Node, Node** Parent) mut => VT.[Friend]GetParent(&this, Node, Parent);

	public HRESULT GetChild(Node* Node, Node** Child) mut => VT.[Friend]GetChild(&this, Node, Child);

	public HRESULT GetNext(Node* Node, Node** Next) mut => VT.[Friend]GetNext(&this, Node, Next);

	public HRESULT GetRoot(Node** Root) mut => VT.[Friend]GetRoot(&this, Root);

	public HRESULT Expand(Node* Node) mut => VT.[Friend]Expand(&this, Node);
}

[CRepr]struct Document : IDispatch
{
	public new const Guid IID = .(0x225120d6, 0x1e0f, 0x40a3, 0x93, 0xfe, 0x10, 0x79, 0xe6, 0xa8, 0x01, 0x7b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Filename) SaveAs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL SaveChanges) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Views** Views) get_Views;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SnapIns** SnapIns) get_SnapIns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View** View) get_ActiveView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Location) get_Location;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* IsSaved) get_IsSaved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _DocumentMode* Mode) get_Mode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _DocumentMode Mode) put_Mode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node** Node) get_RootNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ScopeNamespace** ScopeNamespace) get_ScopeNamespace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Properties** Properties) CreateProperties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _Application** Application) get_Application;
	}


	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT SaveAs(BSTR Filename) mut => VT.[Friend]SaveAs(&this, Filename);

	public HRESULT Close(BOOL SaveChanges) mut => VT.[Friend]Close(&this, SaveChanges);

	public HRESULT get_Views(Views** Views) mut => VT.[Friend]get_Views(&this, Views);

	public HRESULT get_SnapIns(SnapIns** SnapIns) mut => VT.[Friend]get_SnapIns(&this, SnapIns);

	public HRESULT get_ActiveView(View** View) mut => VT.[Friend]get_ActiveView(&this, View);

	public HRESULT get_Name(uint16** Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT put_Name(BSTR Name) mut => VT.[Friend]put_Name(&this, Name);

	public HRESULT get_Location(uint16** Location) mut => VT.[Friend]get_Location(&this, Location);

	public HRESULT get_IsSaved(BOOL* IsSaved) mut => VT.[Friend]get_IsSaved(&this, IsSaved);

	public HRESULT get_Mode(_DocumentMode* Mode) mut => VT.[Friend]get_Mode(&this, Mode);

	public HRESULT put_Mode(_DocumentMode Mode) mut => VT.[Friend]put_Mode(&this, Mode);

	public HRESULT get_RootNode(Node** Node) mut => VT.[Friend]get_RootNode(&this, Node);

	public HRESULT get_ScopeNamespace(ScopeNamespace** ScopeNamespace) mut => VT.[Friend]get_ScopeNamespace(&this, ScopeNamespace);

	public HRESULT CreateProperties(Properties** Properties) mut => VT.[Friend]CreateProperties(&this, Properties);

	public HRESULT get_Application(_Application** Application) mut => VT.[Friend]get_Application(&this, Application);
}

[CRepr]struct SnapIn : IDispatch
{
	public new const Guid IID = .(0x3be910f6, 0x3459, 0x49c6, 0xa1, 0xbb, 0x41, 0xe6, 0xbe, 0x9d, 0xf3, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Vendor) get_Vendor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Version) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Extensions** Extensions) get_Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** SnapinCLSID) get_SnapinCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Properties** Properties) get_Properties;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Enable) EnableAllExtensions;
	}


	public HRESULT get_Name(uint16** Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Vendor(uint16** Vendor) mut => VT.[Friend]get_Vendor(&this, Vendor);

	public HRESULT get_Version(uint16** Version) mut => VT.[Friend]get_Version(&this, Version);

	public HRESULT get_Extensions(Extensions** Extensions) mut => VT.[Friend]get_Extensions(&this, Extensions);

	public HRESULT get_SnapinCLSID(uint16** SnapinCLSID) mut => VT.[Friend]get_SnapinCLSID(&this, SnapinCLSID);

	public HRESULT get_Properties(Properties** Properties) mut => VT.[Friend]get_Properties(&this, Properties);

	public HRESULT EnableAllExtensions(BOOL Enable) mut => VT.[Friend]EnableAllExtensions(&this, Enable);
}

[CRepr]struct SnapIns : IDispatch
{
	public new const Guid IID = .(0x2ef3de1d, 0xb12a, 0x49d1, 0x92, 0xc5, 0x0b, 0x00, 0x79, 0x87, 0x68, 0xf1);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, SnapIn** SnapIn) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR SnapinNameOrCLSID, VARIANT ParentSnapin, VARIANT Properties, SnapIn** SnapIn) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SnapIn* SnapIn) Remove;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Item(int32 Index, SnapIn** SnapIn) mut => VT.[Friend]Item(&this, Index, SnapIn);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Add(BSTR SnapinNameOrCLSID, VARIANT ParentSnapin, VARIANT Properties, SnapIn** SnapIn) mut => VT.[Friend]Add(&this, SnapinNameOrCLSID, ParentSnapin, Properties, SnapIn);

	public HRESULT Remove(SnapIn* SnapIn) mut => VT.[Friend]Remove(&this, SnapIn);
}

[CRepr]struct Extension : IDispatch
{
	public new const Guid IID = .(0xad4d6ca6, 0x912f, 0x409b, 0xa2, 0x6e, 0x7f, 0xd2, 0x34, 0xae, 0xf5, 0x42);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Name) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Vendor) get_Vendor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Version) get_Version;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Extensions** Extensions) get_Extensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** SnapinCLSID) get_SnapinCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Enable) EnableAllExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Enable) Enable;
	}


	public HRESULT get_Name(uint16** Name) mut => VT.[Friend]get_Name(&this, Name);

	public HRESULT get_Vendor(uint16** Vendor) mut => VT.[Friend]get_Vendor(&this, Vendor);

	public HRESULT get_Version(uint16** Version) mut => VT.[Friend]get_Version(&this, Version);

	public HRESULT get_Extensions(Extensions** Extensions) mut => VT.[Friend]get_Extensions(&this, Extensions);

	public HRESULT get_SnapinCLSID(uint16** SnapinCLSID) mut => VT.[Friend]get_SnapinCLSID(&this, SnapinCLSID);

	public HRESULT EnableAllExtensions(BOOL Enable) mut => VT.[Friend]EnableAllExtensions(&this, Enable);

	public HRESULT Enable(BOOL Enable) mut => VT.[Friend]Enable(&this, Enable);
}

[CRepr]struct Extensions : IDispatch
{
	public new const Guid IID = .(0x82dbea43, 0x8ca4, 0x44bc, 0xa2, 0xca, 0xd1, 0x87, 0x41, 0x05, 0x9e, 0xc8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, Extension** Extension) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Item(int32 Index, Extension** Extension) mut => VT.[Friend]Item(&this, Index, Extension);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);
}

[CRepr]struct Columns : IDispatch
{
	public new const Guid IID = .(0x383d4d97, 0xfc44, 0x478b, 0xb1, 0x39, 0x63, 0x23, 0xdc, 0x48, 0x61, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, Column** Column) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
	}


	public HRESULT Item(int32 Index, Column** Column) mut => VT.[Friend]Item(&this, Index, Column);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);
}

[CRepr]struct Column : IDispatch
{
	public new const Guid IID = .(0xfd1c5f63, 0x2b16, 0x4d06, 0x9a, 0xb3, 0xf4, 0x53, 0x50, 0xb9, 0x40, 0xab);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* Name) Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Width) get_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Width) put_Width;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* DisplayPosition) get_DisplayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index) put_DisplayPosition;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Hidden) get_Hidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Hidden) put_Hidden;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _ColumnSortOrder SortOrder) SetAsSortColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* IsSortColumn) IsSortColumn;
	}


	public HRESULT Name(BSTR* Name) mut => VT.[Friend]Name(&this, Name);

	public HRESULT get_Width(int32* Width) mut => VT.[Friend]get_Width(&this, Width);

	public HRESULT put_Width(int32 Width) mut => VT.[Friend]put_Width(&this, Width);

	public HRESULT get_DisplayPosition(int32* DisplayPosition) mut => VT.[Friend]get_DisplayPosition(&this, DisplayPosition);

	public HRESULT put_DisplayPosition(int32 Index) mut => VT.[Friend]put_DisplayPosition(&this, Index);

	public HRESULT get_Hidden(BOOL* Hidden) mut => VT.[Friend]get_Hidden(&this, Hidden);

	public HRESULT put_Hidden(BOOL Hidden) mut => VT.[Friend]put_Hidden(&this, Hidden);

	public HRESULT SetAsSortColumn(_ColumnSortOrder SortOrder) mut => VT.[Friend]SetAsSortColumn(&this, SortOrder);

	public HRESULT IsSortColumn(BOOL* IsSortColumn) mut => VT.[Friend]IsSortColumn(&this, IsSortColumn);
}

[CRepr]struct Views : IDispatch
{
	public new const Guid IID = .(0xd6b8c29d, 0xa1ff, 0x4d72, 0xaa, 0xb0, 0xe3, 0x81, 0xe9, 0xb9, 0x33, 0x8d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, View** View) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, _ViewOptions viewOptions) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
	}


	public HRESULT Item(int32 Index, View** View) mut => VT.[Friend]Item(&this, Index, View);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Add(Node* Node, _ViewOptions viewOptions) mut => VT.[Friend]Add(&this, Node, viewOptions);

	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);
}

[CRepr]struct View : IDispatch
{
	public new const Guid IID = .(0x6efc2da2, 0xb38c, 0x457e, 0x9a, 0xbb, 0xed, 0x2d, 0x18, 0x9b, 0x8c, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node** Node) get_ActiveScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node) put_ActiveScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Nodes** Nodes) get_Selection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Nodes** Nodes) get_ListItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode, IDispatch** ScopeNodeObject) SnapinScopeObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** SelectionObject) SnapinSelectionObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, View* View, int16* TheSame) Is;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Document** Document) get_Document;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SelectAll;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node) Select;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node) Deselect;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, BOOL* IsSelected) IsSelected;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode) DisplayScopeNodePropertySheet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DisplaySelectionPropertySheet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode) CopyScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) CopySelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode) DeleteScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR NewName, VARIANT ScopeNode) RenameScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR NewName) RenameSelectedItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode, ContextMenu** ContextMenu) get_ScopeNodeContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ContextMenu** ContextMenu) get_SelectionContextMenu;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT ScopeNode) RefreshScopeNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) RefreshSelection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR MenuItemPath) ExecuteSelectionMenuItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR MenuItemPath, VARIANT ScopeNode) ExecuteScopeNodeMenuItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Command, BSTR Directory, BSTR Parameters, BSTR WindowState) ExecuteShellCommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Frame** Frame) get_Frame;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Close;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Visible) get_ScopeTreeVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL Visible) put_ScopeTreeVisible;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Back;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Forward;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR StatusBarText) put_StatusBarText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Memento) get_Memento;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Memento) ViewMemento;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Columns** Columns) get_Columns;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Node* Node, int32 Column, uint16** CellContents) get_CellContents;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR File, _ExportListOptions exportoptions) ExportList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _ListViewMode* Mode) get_ListViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, _ListViewMode mode) put_ListViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDispatch** Control) get_ControlObject;
	}


	public HRESULT get_ActiveScopeNode(Node** Node) mut => VT.[Friend]get_ActiveScopeNode(&this, Node);

	public HRESULT put_ActiveScopeNode(Node* Node) mut => VT.[Friend]put_ActiveScopeNode(&this, Node);

	public HRESULT get_Selection(Nodes** Nodes) mut => VT.[Friend]get_Selection(&this, Nodes);

	public HRESULT get_ListItems(Nodes** Nodes) mut => VT.[Friend]get_ListItems(&this, Nodes);

	public HRESULT SnapinScopeObject(VARIANT ScopeNode, IDispatch** ScopeNodeObject) mut => VT.[Friend]SnapinScopeObject(&this, ScopeNode, ScopeNodeObject);

	public HRESULT SnapinSelectionObject(IDispatch** SelectionObject) mut => VT.[Friend]SnapinSelectionObject(&this, SelectionObject);

	public HRESULT Is(View* View, int16* TheSame) mut => VT.[Friend]Is(&this, View, TheSame);

	public HRESULT get_Document(Document** Document) mut => VT.[Friend]get_Document(&this, Document);

	public HRESULT SelectAll() mut => VT.[Friend]SelectAll(&this);

	public HRESULT Select(Node* Node) mut => VT.[Friend]Select(&this, Node);

	public HRESULT Deselect(Node* Node) mut => VT.[Friend]Deselect(&this, Node);

	public HRESULT IsSelected(Node* Node, BOOL* IsSelected) mut => VT.[Friend]IsSelected(&this, Node, IsSelected);

	public HRESULT DisplayScopeNodePropertySheet(VARIANT ScopeNode) mut => VT.[Friend]DisplayScopeNodePropertySheet(&this, ScopeNode);

	public HRESULT DisplaySelectionPropertySheet() mut => VT.[Friend]DisplaySelectionPropertySheet(&this);

	public HRESULT CopyScopeNode(VARIANT ScopeNode) mut => VT.[Friend]CopyScopeNode(&this, ScopeNode);

	public HRESULT CopySelection() mut => VT.[Friend]CopySelection(&this);

	public HRESULT DeleteScopeNode(VARIANT ScopeNode) mut => VT.[Friend]DeleteScopeNode(&this, ScopeNode);

	public HRESULT DeleteSelection() mut => VT.[Friend]DeleteSelection(&this);

	public HRESULT RenameScopeNode(BSTR NewName, VARIANT ScopeNode) mut => VT.[Friend]RenameScopeNode(&this, NewName, ScopeNode);

	public HRESULT RenameSelectedItem(BSTR NewName) mut => VT.[Friend]RenameSelectedItem(&this, NewName);

	public HRESULT get_ScopeNodeContextMenu(VARIANT ScopeNode, ContextMenu** ContextMenu) mut => VT.[Friend]get_ScopeNodeContextMenu(&this, ScopeNode, ContextMenu);

	public HRESULT get_SelectionContextMenu(ContextMenu** ContextMenu) mut => VT.[Friend]get_SelectionContextMenu(&this, ContextMenu);

	public HRESULT RefreshScopeNode(VARIANT ScopeNode) mut => VT.[Friend]RefreshScopeNode(&this, ScopeNode);

	public HRESULT RefreshSelection() mut => VT.[Friend]RefreshSelection(&this);

	public HRESULT ExecuteSelectionMenuItem(BSTR MenuItemPath) mut => VT.[Friend]ExecuteSelectionMenuItem(&this, MenuItemPath);

	public HRESULT ExecuteScopeNodeMenuItem(BSTR MenuItemPath, VARIANT ScopeNode) mut => VT.[Friend]ExecuteScopeNodeMenuItem(&this, MenuItemPath, ScopeNode);

	public HRESULT ExecuteShellCommand(BSTR Command, BSTR Directory, BSTR Parameters, BSTR WindowState) mut => VT.[Friend]ExecuteShellCommand(&this, Command, Directory, Parameters, WindowState);

	public HRESULT get_Frame(Frame** Frame) mut => VT.[Friend]get_Frame(&this, Frame);

	public HRESULT Close() mut => VT.[Friend]Close(&this);

	public HRESULT get_ScopeTreeVisible(BOOL* Visible) mut => VT.[Friend]get_ScopeTreeVisible(&this, Visible);

	public HRESULT put_ScopeTreeVisible(BOOL Visible) mut => VT.[Friend]put_ScopeTreeVisible(&this, Visible);

	public HRESULT Back() mut => VT.[Friend]Back(&this);

	public HRESULT Forward() mut => VT.[Friend]Forward(&this);

	public HRESULT put_StatusBarText(BSTR StatusBarText) mut => VT.[Friend]put_StatusBarText(&this, StatusBarText);

	public HRESULT get_Memento(uint16** Memento) mut => VT.[Friend]get_Memento(&this, Memento);

	public HRESULT ViewMemento(BSTR Memento) mut => VT.[Friend]ViewMemento(&this, Memento);

	public HRESULT get_Columns(Columns** Columns) mut => VT.[Friend]get_Columns(&this, Columns);

	public HRESULT get_CellContents(Node* Node, int32 Column, uint16** CellContents) mut => VT.[Friend]get_CellContents(&this, Node, Column, CellContents);

	public HRESULT ExportList(BSTR File, _ExportListOptions exportoptions) mut => VT.[Friend]ExportList(&this, File, exportoptions);

	public HRESULT get_ListViewMode(_ListViewMode* Mode) mut => VT.[Friend]get_ListViewMode(&this, Mode);

	public HRESULT put_ListViewMode(_ListViewMode mode) mut => VT.[Friend]put_ListViewMode(&this, mode);

	public HRESULT get_ControlObject(IDispatch** Control) mut => VT.[Friend]get_ControlObject(&this, Control);
}

[CRepr]struct Nodes : IDispatch
{
	public new const Guid IID = .(0x313b01df, 0xb22f, 0x4d42, 0xb1, 0xb8, 0x48, 0x3c, 0xdc, 0xf5, 0x1d, 0x35);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 Index, Node** Node) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Item(int32 Index, Node** Node) mut => VT.[Friend]Item(&this, Index, Node);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);
}

[CRepr]struct ContextMenu : IDispatch
{
	public new const Guid IID = .(0xdab39ce0, 0x25e6, 0x4e07, 0x83, 0x62, 0xba, 0x9c, 0x95, 0x70, 0x65, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT IndexOrPath, MenuItem** MenuItem) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT get_Item(VARIANT IndexOrPath, MenuItem** MenuItem) mut => VT.[Friend]get_Item(&this, IndexOrPath, MenuItem);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);
}

[CRepr]struct MenuItem : IDispatch
{
	public new const Guid IID = .(0x0178fad1, 0xb361, 0x4b27, 0x96, 0xad, 0x67, 0xc5, 0x7e, 0xbf, 0x2e, 0x1d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** DisplayName) get_DisplayName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** LanguageIndependentName) get_LanguageIndependentName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Path) get_Path;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** LanguageIndependentPath) get_LanguageIndependentPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Execute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* Enabled) get_Enabled;
	}


	public HRESULT get_DisplayName(uint16** DisplayName) mut => VT.[Friend]get_DisplayName(&this, DisplayName);

	public HRESULT get_LanguageIndependentName(uint16** LanguageIndependentName) mut => VT.[Friend]get_LanguageIndependentName(&this, LanguageIndependentName);

	public HRESULT get_Path(uint16** Path) mut => VT.[Friend]get_Path(&this, Path);

	public HRESULT get_LanguageIndependentPath(uint16** LanguageIndependentPath) mut => VT.[Friend]get_LanguageIndependentPath(&this, LanguageIndependentPath);

	public HRESULT Execute() mut => VT.[Friend]Execute(&this);

	public HRESULT get_Enabled(BOOL* Enabled) mut => VT.[Friend]get_Enabled(&this, Enabled);
}

[CRepr]struct Properties : IDispatch
{
	public new const Guid IID = .(0x2886abc2, 0xa425, 0x42b2, 0x91, 0xc6, 0xe2, 0x5c, 0x0e, 0x04, 0x58, 0x1c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** retval) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name, Property** Property) Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* Count) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR Name) Remove;
	}


	public HRESULT get__NewEnum(IUnknown** retval) mut => VT.[Friend]get__NewEnum(&this, retval);

	public HRESULT Item(BSTR Name, Property** Property) mut => VT.[Friend]Item(&this, Name, Property);

	public HRESULT get_Count(int32* Count) mut => VT.[Friend]get_Count(&this, Count);

	public HRESULT Remove(BSTR Name) mut => VT.[Friend]Remove(&this, Name);
}

[CRepr]struct Property : IDispatch
{
	public new const Guid IID = .(0x4600c3a5, 0xe301, 0x41d8, 0xb6, 0xd0, 0xef, 0x2e, 0x42, 0x12, 0xe0, 0xca);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* Value) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT Value) put_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint16** Name) get_Name;
	}


	public HRESULT get_Value(VARIANT* Value) mut => VT.[Friend]get_Value(&this, Value);

	public HRESULT put_Value(VARIANT Value) mut => VT.[Friend]put_Value(&this, Value);

	public HRESULT get_Name(uint16** Name) mut => VT.[Friend]get_Name(&this, Name);
}

[CRepr]struct IComponentData : IUnknown
{
	public new const Guid IID = .(0x955ab28a, 0x5218, 0x11d0, 0xa9, 0x85, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pUnknown) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IComponent** ppComponent) CreateComponent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObject, MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param3) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, DATA_OBJECT_TYPES type, IDataObject** ppDataObject) QueryDataObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SCOPEDATAITEM* pScopeDataItem) GetDisplayInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObjectA, IDataObject* lpDataObjectB) CompareObjects;
	}


	public HRESULT Initialize(IUnknown* pUnknown) mut => VT.[Friend]Initialize(&this, pUnknown);

	public HRESULT CreateComponent(IComponent** ppComponent) mut => VT.[Friend]CreateComponent(&this, ppComponent);

	public HRESULT Notify(IDataObject* lpDataObject, MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param3) mut => VT.[Friend]Notify(&this, lpDataObject, event, arg, param3);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT QueryDataObject(int cookie, DATA_OBJECT_TYPES type, IDataObject** ppDataObject) mut => VT.[Friend]QueryDataObject(&this, cookie, type, ppDataObject);

	public HRESULT GetDisplayInfo(SCOPEDATAITEM* pScopeDataItem) mut => VT.[Friend]GetDisplayInfo(&this, pScopeDataItem);

	public HRESULT CompareObjects(IDataObject* lpDataObjectA, IDataObject* lpDataObjectB) mut => VT.[Friend]CompareObjects(&this, lpDataObjectA, lpDataObjectB);
}

[CRepr]struct IComponent : IUnknown
{
	public new const Guid IID = .(0x43136eb2, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConsole* lpConsole) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObject, MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param3) Notify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, DATA_OBJECT_TYPES type, IDataObject** ppDataObject) QueryDataObject;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, PWSTR* ppViewType, int32* pViewOptions) GetResultViewType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTDATAITEM* pResultDataItem) GetDisplayInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObjectA, IDataObject* lpDataObjectB) CompareObjects;
	}


	public HRESULT Initialize(IConsole* lpConsole) mut => VT.[Friend]Initialize(&this, lpConsole);

	public HRESULT Notify(IDataObject* lpDataObject, MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param3) mut => VT.[Friend]Notify(&this, lpDataObject, event, arg, param3);

	public HRESULT Destroy(int cookie) mut => VT.[Friend]Destroy(&this, cookie);

	public HRESULT QueryDataObject(int cookie, DATA_OBJECT_TYPES type, IDataObject** ppDataObject) mut => VT.[Friend]QueryDataObject(&this, cookie, type, ppDataObject);

	public HRESULT GetResultViewType(int cookie, PWSTR* ppViewType, int32* pViewOptions) mut => VT.[Friend]GetResultViewType(&this, cookie, ppViewType, pViewOptions);

	public HRESULT GetDisplayInfo(RESULTDATAITEM* pResultDataItem) mut => VT.[Friend]GetDisplayInfo(&this, pResultDataItem);

	public HRESULT CompareObjects(IDataObject* lpDataObjectA, IDataObject* lpDataObjectB) mut => VT.[Friend]CompareObjects(&this, lpDataObjectA, lpDataObjectB);
}

[CRepr]struct IResultDataCompare : IUnknown
{
	public new const Guid IID = .(0xe8315a52, 0x7a1a, 0x11d0, 0xa2, 0xd2, 0x00, 0xc0, 0x4f, 0xd9, 0x09, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM lUserParam, int cookieA, int cookieB, int32* pnResult) Compare;
	}


	public HRESULT Compare(LPARAM lUserParam, int cookieA, int cookieB, int32* pnResult) mut => VT.[Friend]Compare(&this, lUserParam, cookieA, cookieB, pnResult);
}

[CRepr]struct IResultOwnerData : IUnknown
{
	public new const Guid IID = .(0x9cb396d8, 0xea83, 0x11d0, 0xae, 0xf1, 0x00, 0xc0, 0x4f, 0xb6, 0xdd, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTFINDINFO* pFindInfo, int32* pnFoundIndex) FindItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nStartIndex, int32 nEndIndex) CacheHint;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nColumn, uint32 dwSortOptions, LPARAM lUserParam) SortItems;
	}


	public HRESULT FindItem(RESULTFINDINFO* pFindInfo, int32* pnFoundIndex) mut => VT.[Friend]FindItem(&this, pFindInfo, pnFoundIndex);

	public HRESULT CacheHint(int32 nStartIndex, int32 nEndIndex) mut => VT.[Friend]CacheHint(&this, nStartIndex, nEndIndex);

	public HRESULT SortItems(int32 nColumn, uint32 dwSortOptions, LPARAM lUserParam) mut => VT.[Friend]SortItems(&this, nColumn, dwSortOptions, lUserParam);
}

[CRepr]struct IConsole : IUnknown
{
	public new const Guid IID = .(0x43136eb1, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IHeaderCtrl* pHeader) SetHeader;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IToolbar* pToolbar) SetToolbar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** pUnknown) QueryResultView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Win32.System.Mmc.IImageList** ppImageList) QueryScopeImageList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Win32.System.Mmc.IImageList** ppImageList) QueryResultImageList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObject, LPARAM data, int hint) UpdateAllViews;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR lpszText, PWSTR lpszTitle, uint32 fuStyle, int32* piRetval) MessageBox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IConsoleVerb** ppConsoleVerb) QueryConsoleVerb;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hScopeItem) SelectScopeItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwnd) GetMainWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hScopeItem, uint32 lOptions) NewWindow;
	}


	public HRESULT SetHeader(IHeaderCtrl* pHeader) mut => VT.[Friend]SetHeader(&this, pHeader);

	public HRESULT SetToolbar(IToolbar* pToolbar) mut => VT.[Friend]SetToolbar(&this, pToolbar);

	public HRESULT QueryResultView(IUnknown** pUnknown) mut => VT.[Friend]QueryResultView(&this, pUnknown);

	public HRESULT QueryScopeImageList(Win32.System.Mmc.IImageList** ppImageList) mut => VT.[Friend]QueryScopeImageList(&this, ppImageList);

	public HRESULT QueryResultImageList(Win32.System.Mmc.IImageList** ppImageList) mut => VT.[Friend]QueryResultImageList(&this, ppImageList);

	public HRESULT UpdateAllViews(IDataObject* lpDataObject, LPARAM data, int hint) mut => VT.[Friend]UpdateAllViews(&this, lpDataObject, data, hint);

	public HRESULT MessageBox(PWSTR lpszText, PWSTR lpszTitle, uint32 fuStyle, int32* piRetval) mut => VT.[Friend]MessageBox(&this, lpszText, lpszTitle, fuStyle, piRetval);

	public HRESULT QueryConsoleVerb(IConsoleVerb** ppConsoleVerb) mut => VT.[Friend]QueryConsoleVerb(&this, ppConsoleVerb);

	public HRESULT SelectScopeItem(int hScopeItem) mut => VT.[Friend]SelectScopeItem(&this, hScopeItem);

	public HRESULT GetMainWindow(HWND* phwnd) mut => VT.[Friend]GetMainWindow(&this, phwnd);

	public HRESULT NewWindow(int hScopeItem, uint32 lOptions) mut => VT.[Friend]NewWindow(&this, hScopeItem, lOptions);
}

[CRepr]struct IHeaderCtrl : IUnknown
{
	public new const Guid IID = .(0x43136eb3, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol, PWSTR title, int32 nFormat, int32 nWidth) InsertColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol) DeleteColumn;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol, PWSTR title) SetColumnText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol, PWSTR* pText) GetColumnText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol, int32 nWidth) SetColumnWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nCol, int32* pWidth) GetColumnWidth;
	}


	public HRESULT InsertColumn(int32 nCol, PWSTR title, int32 nFormat, int32 nWidth) mut => VT.[Friend]InsertColumn(&this, nCol, title, nFormat, nWidth);

	public HRESULT DeleteColumn(int32 nCol) mut => VT.[Friend]DeleteColumn(&this, nCol);

	public HRESULT SetColumnText(int32 nCol, PWSTR title) mut => VT.[Friend]SetColumnText(&this, nCol, title);

	public HRESULT GetColumnText(int32 nCol, PWSTR* pText) mut => VT.[Friend]GetColumnText(&this, nCol, pText);

	public HRESULT SetColumnWidth(int32 nCol, int32 nWidth) mut => VT.[Friend]SetColumnWidth(&this, nCol, nWidth);

	public HRESULT GetColumnWidth(int32 nCol, int32* pWidth) mut => VT.[Friend]GetColumnWidth(&this, nCol, pWidth);
}

[CRepr]struct IContextMenuCallback : IUnknown
{
	public new const Guid IID = .(0x43136eb7, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTEXTMENUITEM* pItem) AddItem;
	}


	public HRESULT AddItem(CONTEXTMENUITEM* pItem) mut => VT.[Friend]AddItem(&this, pItem);
}

[CRepr]struct IContextMenuProvider : IContextMenuCallback
{
	public new const Guid IID = .(0x43136eb6, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IContextMenuCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EmptyMenuList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* piExtension, IDataObject* piDataObject) AddPrimaryExtensionItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* piDataObject) AddThirdPartyExtensionItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent, int32 xPos, int32 yPos, int32* plSelected) ShowContextMenu;
	}


	public HRESULT EmptyMenuList() mut => VT.[Friend]EmptyMenuList(&this);

	public HRESULT AddPrimaryExtensionItems(IUnknown* piExtension, IDataObject* piDataObject) mut => VT.[Friend]AddPrimaryExtensionItems(&this, piExtension, piDataObject);

	public HRESULT AddThirdPartyExtensionItems(IDataObject* piDataObject) mut => VT.[Friend]AddThirdPartyExtensionItems(&this, piDataObject);

	public HRESULT ShowContextMenu(HWND hwndParent, int32 xPos, int32 yPos, int32* plSelected) mut => VT.[Friend]ShowContextMenu(&this, hwndParent, xPos, yPos, plSelected);
}

[CRepr]struct IExtendContextMenu : IUnknown
{
	public new const Guid IID = .(0x4f3b7a4f, 0xcfac, 0x11cf, 0xb8, 0xe3, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0xb0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* piDataObject, IContextMenuCallback* piCallback, int32* pInsertionAllowed) AddMenuItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lCommandID, IDataObject* piDataObject) Command;
	}


	public HRESULT AddMenuItems(IDataObject* piDataObject, IContextMenuCallback* piCallback, int32* pInsertionAllowed) mut => VT.[Friend]AddMenuItems(&this, piDataObject, piCallback, pInsertionAllowed);

	public HRESULT Command(int32 lCommandID, IDataObject* piDataObject) mut => VT.[Friend]Command(&this, lCommandID, piDataObject);
}

[CRepr]struct IImageList : IUnknown
{
	public new const Guid IID = .(0x43136eb8, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* pIcon, int32 nLoc) ImageListSetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int* pBMapSm, int* pBMapLg, int32 nStartLoc, COLORREF cMask) ImageListSetStrip;
	}


	public HRESULT ImageListSetIcon(int* pIcon, int32 nLoc) mut => VT.[Friend]ImageListSetIcon(&this, pIcon, nLoc);

	public HRESULT ImageListSetStrip(int* pBMapSm, int* pBMapLg, int32 nStartLoc, COLORREF cMask) mut => VT.[Friend]ImageListSetStrip(&this, pBMapSm, pBMapLg, nStartLoc, cMask);
}

[CRepr]struct IResultData : IUnknown
{
	public new const Guid IID = .(0x31da5fa0, 0xe0eb, 0x11cf, 0x9f, 0x21, 0x00, 0xaa, 0x00, 0x3c, 0xa9, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTDATAITEM* item) InsertItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int itemID, int32 nCol) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, LPARAM lParam, int* pItemID) FindItemByLParam;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteAllRsltItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTDATAITEM* item) SetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTDATAITEM* item) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RESULTDATAITEM* item) GetNextItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex, int itemID, uint32 uAdd, uint32 uRemove) ModifyItemState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_RESULT_VIEW_STYLE add, MMC_RESULT_VIEW_STYLE remove) ModifyViewStyle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 lViewMode) SetViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* lViewMode) GetViewMode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int itemID) UpdateItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nColumn, uint32 dwSortOptions, LPARAM lUserParam) Sort;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR DescText) SetDescBarText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nItemCount, uint32 dwOptions) SetItemCount;
	}


	public HRESULT InsertItem(RESULTDATAITEM* item) mut => VT.[Friend]InsertItem(&this, item);

	public HRESULT DeleteItem(int itemID, int32 nCol) mut => VT.[Friend]DeleteItem(&this, itemID, nCol);

	public HRESULT FindItemByLParam(LPARAM lParam, int* pItemID) mut => VT.[Friend]FindItemByLParam(&this, lParam, pItemID);

	public HRESULT DeleteAllRsltItems() mut => VT.[Friend]DeleteAllRsltItems(&this);

	public HRESULT SetItem(RESULTDATAITEM* item) mut => VT.[Friend]SetItem(&this, item);

	public HRESULT GetItem(RESULTDATAITEM* item) mut => VT.[Friend]GetItem(&this, item);

	public HRESULT GetNextItem(RESULTDATAITEM* item) mut => VT.[Friend]GetNextItem(&this, item);

	public HRESULT ModifyItemState(int32 nIndex, int itemID, uint32 uAdd, uint32 uRemove) mut => VT.[Friend]ModifyItemState(&this, nIndex, itemID, uAdd, uRemove);

	public HRESULT ModifyViewStyle(MMC_RESULT_VIEW_STYLE add, MMC_RESULT_VIEW_STYLE remove) mut => VT.[Friend]ModifyViewStyle(&this, add, remove);

	public HRESULT SetViewMode(int32 lViewMode) mut => VT.[Friend]SetViewMode(&this, lViewMode);

	public HRESULT GetViewMode(int32* lViewMode) mut => VT.[Friend]GetViewMode(&this, lViewMode);

	public HRESULT UpdateItem(int itemID) mut => VT.[Friend]UpdateItem(&this, itemID);

	public HRESULT Sort(int32 nColumn, uint32 dwSortOptions, LPARAM lUserParam) mut => VT.[Friend]Sort(&this, nColumn, dwSortOptions, lUserParam);

	public HRESULT SetDescBarText(PWSTR DescText) mut => VT.[Friend]SetDescBarText(&this, DescText);

	public HRESULT SetItemCount(int32 nItemCount, uint32 dwOptions) mut => VT.[Friend]SetItemCount(&this, nItemCount, dwOptions);
}

[CRepr]struct IConsoleNameSpace : IUnknown
{
	public new const Guid IID = .(0xbedeb620, 0xf24d, 0x11cf, 0x8a, 0xfc, 0x00, 0xaa, 0x00, 0x3c, 0xa9, 0xf6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SCOPEDATAITEM* item) InsertItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hItem, int32 fDeleteThis) DeleteItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SCOPEDATAITEM* item) SetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SCOPEDATAITEM* item) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int item, int* pItemChild, int* pCookie) GetChildItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int item, int* pItemNext, int* pCookie) GetNextItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int item, int* pItemParent, int* pCookie) GetParentItem;
	}


	public HRESULT InsertItem(SCOPEDATAITEM* item) mut => VT.[Friend]InsertItem(&this, item);

	public HRESULT DeleteItem(int hItem, int32 fDeleteThis) mut => VT.[Friend]DeleteItem(&this, hItem, fDeleteThis);

	public HRESULT SetItem(SCOPEDATAITEM* item) mut => VT.[Friend]SetItem(&this, item);

	public HRESULT GetItem(SCOPEDATAITEM* item) mut => VT.[Friend]GetItem(&this, item);

	public HRESULT GetChildItem(int item, int* pItemChild, int* pCookie) mut => VT.[Friend]GetChildItem(&this, item, pItemChild, pCookie);

	public HRESULT GetNextItem(int item, int* pItemNext, int* pCookie) mut => VT.[Friend]GetNextItem(&this, item, pItemNext, pCookie);

	public HRESULT GetParentItem(int item, int* pItemParent, int* pCookie) mut => VT.[Friend]GetParentItem(&this, item, pItemParent, pCookie);
}

[CRepr]struct IConsoleNameSpace2 : IConsoleNameSpace
{
	public new const Guid IID = .(0x255f18cc, 0x65db, 0x11d1, 0xa7, 0xdc, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConsoleNameSpace.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hItem) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hItem, Guid* lpClsid) AddExtension;
	}


	public HRESULT Expand(int hItem) mut => VT.[Friend]Expand(&this, hItem);

	public HRESULT AddExtension(int hItem, Guid* lpClsid) mut => VT.[Friend]AddExtension(&this, hItem, lpClsid);
}

[CRepr]struct IPropertySheetCallback : IUnknown
{
	public new const Guid IID = .(0x85de64dd, 0xef21, 0x11cf, 0xa2, 0x85, 0x00, 0xc0, 0x4f, 0xd8, 0xdb, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE hPage) AddPage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HPROPSHEETPAGE hPage) RemovePage;
	}


	public HRESULT AddPage(HPROPSHEETPAGE hPage) mut => VT.[Friend]AddPage(&this, hPage);

	public HRESULT RemovePage(HPROPSHEETPAGE hPage) mut => VT.[Friend]RemovePage(&this, hPage);
}

[CRepr]struct IPropertySheetProvider : IUnknown
{
	public new const Guid IID = .(0x85de64de, 0xef21, 0x11cf, 0xa2, 0x85, 0x00, 0xc0, 0x4f, 0xd8, 0xdb, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR title, uint8 type, int cookie, IDataObject* pIDataObjectm, uint32 dwOptions) CreatePropertySheet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hItem, IComponent* lpComponent, IDataObject* lpDataObject) FindPropertySheet;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* lpUnknown, BOOL bCreateHandle, HWND hNotifyWindow, BOOL bScopePane) AddPrimaryPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) AddExtensionPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int window, int32 page) Show;
	}


	public HRESULT CreatePropertySheet(PWSTR title, uint8 type, int cookie, IDataObject* pIDataObjectm, uint32 dwOptions) mut => VT.[Friend]CreatePropertySheet(&this, title, type, cookie, pIDataObjectm, dwOptions);

	public HRESULT FindPropertySheet(int hItem, IComponent* lpComponent, IDataObject* lpDataObject) mut => VT.[Friend]FindPropertySheet(&this, hItem, lpComponent, lpDataObject);

	public HRESULT AddPrimaryPages(IUnknown* lpUnknown, BOOL bCreateHandle, HWND hNotifyWindow, BOOL bScopePane) mut => VT.[Friend]AddPrimaryPages(&this, lpUnknown, bCreateHandle, hNotifyWindow, bScopePane);

	public HRESULT AddExtensionPages() mut => VT.[Friend]AddExtensionPages(&this);

	public HRESULT Show(int window, int32 page) mut => VT.[Friend]Show(&this, window, page);
}

[CRepr]struct IExtendPropertySheet : IUnknown
{
	public new const Guid IID = .(0x85de64dc, 0xef21, 0x11cf, 0xa2, 0x85, 0x00, 0xc0, 0x4f, 0xd8, 0xdb, 0xe6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPropertySheetCallback* lpProvider, int handle, IDataObject* lpIDataObject) CreatePropertyPages;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpDataObject) QueryPagesFor;
	}


	public HRESULT CreatePropertyPages(IPropertySheetCallback* lpProvider, int handle, IDataObject* lpIDataObject) mut => VT.[Friend]CreatePropertyPages(&this, lpProvider, handle, lpIDataObject);

	public HRESULT QueryPagesFor(IDataObject* lpDataObject) mut => VT.[Friend]QueryPagesFor(&this, lpDataObject);
}

[CRepr]struct IControlbar : IUnknown
{
	public new const Guid IID = .(0x69fb811e, 0x6c1c, 0x11d0, 0xa2, 0xcb, 0x00, 0xc0, 0x4f, 0xd9, 0x09, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONTROL_TYPE nType, IExtendControlbar* pExtendControlbar, IUnknown** ppUnknown) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONTROL_TYPE nType, IUnknown* lpUnknown) Attach;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* lpUnknown) Detach;
	}


	public HRESULT Create(MMC_CONTROL_TYPE nType, IExtendControlbar* pExtendControlbar, IUnknown** ppUnknown) mut => VT.[Friend]Create(&this, nType, pExtendControlbar, ppUnknown);

	public HRESULT Attach(MMC_CONTROL_TYPE nType, IUnknown* lpUnknown) mut => VT.[Friend]Attach(&this, nType, lpUnknown);

	public HRESULT Detach(IUnknown* lpUnknown) mut => VT.[Friend]Detach(&this, lpUnknown);
}

[CRepr]struct IExtendControlbar : IUnknown
{
	public new const Guid IID = .(0x49506520, 0x6f40, 0x11d0, 0xa9, 0x8b, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IControlbar* pControlbar) SetControlbar;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param2) ControlbarNotify;
	}


	public HRESULT SetControlbar(IControlbar* pControlbar) mut => VT.[Friend]SetControlbar(&this, pControlbar);

	public HRESULT ControlbarNotify(MMC_NOTIFY_TYPE event, LPARAM arg, LPARAM param2) mut => VT.[Friend]ControlbarNotify(&this, event, arg, param2);
}

[CRepr]struct IToolbar : IUnknown
{
	public new const Guid IID = .(0x43136eb9, 0xd36c, 0x11cf, 0xad, 0xbc, 0x00, 0xaa, 0x00, 0xa8, 0x00, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nImages, HBITMAP hbmp, int32 cxSize, int32 cySize, COLORREF crMask) AddBitmap;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nButtons, MMCBUTTON* lpButtons) AddButtons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex, MMCBUTTON* lpButton) InsertButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nIndex) DeleteButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idCommand, MMC_BUTTON_STATE nState, BOOL* pState) GetButtonState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idCommand, MMC_BUTTON_STATE nState, BOOL bState) SetButtonState;
	}


	public HRESULT AddBitmap(int32 nImages, HBITMAP hbmp, int32 cxSize, int32 cySize, COLORREF crMask) mut => VT.[Friend]AddBitmap(&this, nImages, hbmp, cxSize, cySize, crMask);

	public HRESULT AddButtons(int32 nButtons, MMCBUTTON* lpButtons) mut => VT.[Friend]AddButtons(&this, nButtons, lpButtons);

	public HRESULT InsertButton(int32 nIndex, MMCBUTTON* lpButton) mut => VT.[Friend]InsertButton(&this, nIndex, lpButton);

	public HRESULT DeleteButton(int32 nIndex) mut => VT.[Friend]DeleteButton(&this, nIndex);

	public HRESULT GetButtonState(int32 idCommand, MMC_BUTTON_STATE nState, BOOL* pState) mut => VT.[Friend]GetButtonState(&this, idCommand, nState, pState);

	public HRESULT SetButtonState(int32 idCommand, MMC_BUTTON_STATE nState, BOOL bState) mut => VT.[Friend]SetButtonState(&this, idCommand, nState, bState);
}

[CRepr]struct IConsoleVerb : IUnknown
{
	public new const Guid IID = .(0xe49f7a60, 0x74af, 0x11d0, 0xa2, 0x86, 0x00, 0xc0, 0x4f, 0xd8, 0xfe, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONSOLE_VERB eCmdID, MMC_BUTTON_STATE nState, BOOL* pState) GetVerbState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONSOLE_VERB eCmdID, MMC_BUTTON_STATE nState, BOOL bState) SetVerbState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONSOLE_VERB eCmdID) SetDefaultVerb;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_CONSOLE_VERB* peCmdID) GetDefaultVerb;
	}


	public HRESULT GetVerbState(MMC_CONSOLE_VERB eCmdID, MMC_BUTTON_STATE nState, BOOL* pState) mut => VT.[Friend]GetVerbState(&this, eCmdID, nState, pState);

	public HRESULT SetVerbState(MMC_CONSOLE_VERB eCmdID, MMC_BUTTON_STATE nState, BOOL bState) mut => VT.[Friend]SetVerbState(&this, eCmdID, nState, bState);

	public HRESULT SetDefaultVerb(MMC_CONSOLE_VERB eCmdID) mut => VT.[Friend]SetDefaultVerb(&this, eCmdID);

	public HRESULT GetDefaultVerb(MMC_CONSOLE_VERB* peCmdID) mut => VT.[Friend]GetDefaultVerb(&this, peCmdID);
}

[CRepr]struct ISnapinAbout : IUnknown
{
	public new const Guid IID = .(0x1245208c, 0xa151, 0x11d0, 0xa7, 0xd7, 0x00, 0xc0, 0x4f, 0xd9, 0x09, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lpDescription) GetSnapinDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lpName) GetProvider;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lpVersion) GetSnapinVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HICON* hAppIcon) GetSnapinImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* hSmallImage, HBITMAP* hSmallImageOpen, HBITMAP* hLargeImage, COLORREF* cMask) GetStaticFolderImage;
	}


	public HRESULT GetSnapinDescription(PWSTR* lpDescription) mut => VT.[Friend]GetSnapinDescription(&this, lpDescription);

	public HRESULT GetProvider(PWSTR* lpName) mut => VT.[Friend]GetProvider(&this, lpName);

	public HRESULT GetSnapinVersion(PWSTR* lpVersion) mut => VT.[Friend]GetSnapinVersion(&this, lpVersion);

	public HRESULT GetSnapinImage(HICON* hAppIcon) mut => VT.[Friend]GetSnapinImage(&this, hAppIcon);

	public HRESULT GetStaticFolderImage(HBITMAP* hSmallImage, HBITMAP* hSmallImageOpen, HBITMAP* hLargeImage, COLORREF* cMask) mut => VT.[Friend]GetStaticFolderImage(&this, hSmallImage, hSmallImageOpen, hLargeImage, cMask);
}

[CRepr]struct IMenuButton : IUnknown
{
	public new const Guid IID = .(0x951ed750, 0xd080, 0x11d0, 0xb1, 0x97, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idCommand, PWSTR lpButtonText, PWSTR lpTooltipText) AddButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idCommand, PWSTR lpButtonText, PWSTR lpTooltipText) SetButton;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 idCommand, MMC_BUTTON_STATE nState, BOOL bState) SetButtonState;
	}


	public HRESULT AddButton(int32 idCommand, PWSTR lpButtonText, PWSTR lpTooltipText) mut => VT.[Friend]AddButton(&this, idCommand, lpButtonText, lpTooltipText);

	public HRESULT SetButton(int32 idCommand, PWSTR lpButtonText, PWSTR lpTooltipText) mut => VT.[Friend]SetButton(&this, idCommand, lpButtonText, lpTooltipText);

	public HRESULT SetButtonState(int32 idCommand, MMC_BUTTON_STATE nState, BOOL bState) mut => VT.[Friend]SetButtonState(&this, idCommand, nState, bState);
}

[CRepr]struct ISnapinHelp : IUnknown
{
	public new const Guid IID = .(0xa6b15ace, 0xdf59, 0x11d0, 0xa7, 0xdd, 0x00, 0xc0, 0x4f, 0xd9, 0x09, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lpCompiledHelpFile) GetHelpTopic;
	}


	public HRESULT GetHelpTopic(PWSTR* lpCompiledHelpFile) mut => VT.[Friend]GetHelpTopic(&this, lpCompiledHelpFile);
}

[CRepr]struct IExtendPropertySheet2 : IExtendPropertySheet
{
	public new const Guid IID = .(0xb7a87232, 0x4a51, 0x11d1, 0xa7, 0xea, 0x00, 0xc0, 0x4f, 0xd9, 0x09, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IExtendPropertySheet.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* lpIDataObject, HBITMAP* lphWatermark, HBITMAP* lphHeader, HPALETTE* lphPalette, BOOL* bStretch) GetWatermarks;
	}


	public HRESULT GetWatermarks(IDataObject* lpIDataObject, HBITMAP* lphWatermark, HBITMAP* lphHeader, HPALETTE* lphPalette, BOOL* bStretch) mut => VT.[Friend]GetWatermarks(&this, lpIDataObject, lphWatermark, lphHeader, lphPalette, bStretch);
}

[CRepr]struct IHeaderCtrl2 : IHeaderCtrl
{
	public new const Guid IID = .(0x9757abb8, 0x1b32, 0x11d1, 0xa7, 0xce, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IHeaderCtrl.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 uTimeout) SetChangeTimeOut;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nColumn, uint32 dwType, MMC_FILTERDATA* pFilterData) SetColumnFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nColumn, uint32* pdwType, MMC_FILTERDATA* pFilterData) GetColumnFilter;
	}


	public HRESULT SetChangeTimeOut(uint32 uTimeout) mut => VT.[Friend]SetChangeTimeOut(&this, uTimeout);

	public HRESULT SetColumnFilter(uint32 nColumn, uint32 dwType, MMC_FILTERDATA* pFilterData) mut => VT.[Friend]SetColumnFilter(&this, nColumn, dwType, pFilterData);

	public HRESULT GetColumnFilter(uint32 nColumn, uint32* pdwType, MMC_FILTERDATA* pFilterData) mut => VT.[Friend]GetColumnFilter(&this, nColumn, pdwType, pFilterData);
}

[CRepr]struct ISnapinHelp2 : ISnapinHelp
{
	public new const Guid IID = .(0x4861a010, 0x20f9, 0x11d2, 0xa5, 0x10, 0x00, 0xc0, 0x4f, 0xb6, 0xdd, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : ISnapinHelp.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* lpCompiledHelpFiles) GetLinkedTopics;
	}


	public HRESULT GetLinkedTopics(PWSTR* lpCompiledHelpFiles) mut => VT.[Friend]GetLinkedTopics(&this, lpCompiledHelpFiles);
}

[CRepr]struct IEnumTASK : IUnknown
{
	public new const Guid IID = .(0x338698b1, 0x5a02, 0x11d1, 0x9f, 0xec, 0x00, 0x60, 0x08, 0x32, 0xdb, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt, MMC_TASK* rgelt, uint32* pceltFetched) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 celt) Skip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumTASK** ppenum) Clone;
	}


	public HRESULT Next(uint32 celt, MMC_TASK* rgelt, uint32* pceltFetched) mut => VT.[Friend]Next(&this, celt, rgelt, pceltFetched);

	public HRESULT Skip(uint32 celt) mut => VT.[Friend]Skip(&this, celt);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Clone(IEnumTASK** ppenum) mut => VT.[Friend]Clone(&this, ppenum);
}

[CRepr]struct IExtendTaskPad : IUnknown
{
	public new const Guid IID = .(0x8dee6511, 0x554d, 0x11d1, 0x9f, 0xea, 0x00, 0x60, 0x08, 0x32, 0xdb, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pdo, VARIANT* arg, VARIANT* param2) TaskNotify;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pdo, PWSTR szTaskGroup, IEnumTASK** ppEnumTASK) EnumTasks;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGroup, PWSTR* pszTitle) GetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGroup, PWSTR* pszDescriptiveText) GetDescriptiveText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGroup, MMC_TASK_DISPLAY_OBJECT* pTDO) GetBackground;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGroup, MMC_LISTPAD_INFO* lpListPadInfo) GetListPadInfo;
	}


	public HRESULT TaskNotify(IDataObject* pdo, VARIANT* arg, VARIANT* param2) mut => VT.[Friend]TaskNotify(&this, pdo, arg, param2);

	public HRESULT EnumTasks(IDataObject* pdo, PWSTR szTaskGroup, IEnumTASK** ppEnumTASK) mut => VT.[Friend]EnumTasks(&this, pdo, szTaskGroup, ppEnumTASK);

	public HRESULT GetTitle(PWSTR pszGroup, PWSTR* pszTitle) mut => VT.[Friend]GetTitle(&this, pszGroup, pszTitle);

	public HRESULT GetDescriptiveText(PWSTR pszGroup, PWSTR* pszDescriptiveText) mut => VT.[Friend]GetDescriptiveText(&this, pszGroup, pszDescriptiveText);

	public HRESULT GetBackground(PWSTR pszGroup, MMC_TASK_DISPLAY_OBJECT* pTDO) mut => VT.[Friend]GetBackground(&this, pszGroup, pTDO);

	public HRESULT GetListPadInfo(PWSTR pszGroup, MMC_LISTPAD_INFO* lpListPadInfo) mut => VT.[Friend]GetListPadInfo(&this, pszGroup, lpListPadInfo);
}

[CRepr]struct IConsole2 : IConsole
{
	public new const Guid IID = .(0x103d842a, 0xaa63, 0x11d1, 0xa7, 0xe1, 0x00, 0xc0, 0x4f, 0xd8, 0xd5, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConsole.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hItem, BOOL bExpand) Expand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) IsTaskpadViewPreferred;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszStatusText) SetStatusText;
	}


	public HRESULT Expand(int hItem, BOOL bExpand) mut => VT.[Friend]Expand(&this, hItem, bExpand);

	public HRESULT IsTaskpadViewPreferred() mut => VT.[Friend]IsTaskpadViewPreferred(&this);

	public HRESULT SetStatusText(PWSTR pszStatusText) mut => VT.[Friend]SetStatusText(&this, pszStatusText);
}

[CRepr]struct IDisplayHelp : IUnknown
{
	public new const Guid IID = .(0xcc593830, 0xb926, 0x11d1, 0x80, 0x63, 0x00, 0x00, 0xf8, 0x75, 0xa9, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszHelpTopic) ShowTopic;
	}


	public HRESULT ShowTopic(PWSTR pszHelpTopic) mut => VT.[Friend]ShowTopic(&this, pszHelpTopic);
}

[CRepr]struct IRequiredExtensions : IUnknown
{
	public new const Guid IID = .(0x72782d7a, 0xa4a0, 0x11d1, 0xaf, 0x0f, 0x00, 0xc0, 0x4f, 0xb6, 0xdd, 0x2c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) EnableAllExtensions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pExtCLSID) GetFirstExtension;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pExtCLSID) GetNextExtension;
	}


	public HRESULT EnableAllExtensions() mut => VT.[Friend]EnableAllExtensions(&this);

	public HRESULT GetFirstExtension(Guid* pExtCLSID) mut => VT.[Friend]GetFirstExtension(&this, pExtCLSID);

	public HRESULT GetNextExtension(Guid* pExtCLSID) mut => VT.[Friend]GetNextExtension(&this, pExtCLSID);
}

[CRepr]struct IStringTable : IUnknown
{
	public new const Guid IID = .(0xde40b7a4, 0x0f65, 0x11d2, 0x8e, 0x25, 0x00, 0xc0, 0x4f, 0x8e, 0xcd, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAdd, uint32* pStringID) AddString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StringID, uint32 cchBuffer, char16* lpBuffer, uint32* pcchOut) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StringID, uint32* pcchString) GetStringLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 StringID) DeleteString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) DeleteAllStrings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszFind, uint32* pStringID) FindString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppEnum) Enumerate;
	}


	public HRESULT AddString(PWSTR pszAdd, uint32* pStringID) mut => VT.[Friend]AddString(&this, pszAdd, pStringID);

	public HRESULT GetString(uint32 StringID, uint32 cchBuffer, char16* lpBuffer, uint32* pcchOut) mut => VT.[Friend]GetString(&this, StringID, cchBuffer, lpBuffer, pcchOut);

	public HRESULT GetStringLength(uint32 StringID, uint32* pcchString) mut => VT.[Friend]GetStringLength(&this, StringID, pcchString);

	public HRESULT DeleteString(uint32 StringID) mut => VT.[Friend]DeleteString(&this, StringID);

	public HRESULT DeleteAllStrings() mut => VT.[Friend]DeleteAllStrings(&this);

	public HRESULT FindString(PWSTR pszFind, uint32* pStringID) mut => VT.[Friend]FindString(&this, pszFind, pStringID);

	public HRESULT Enumerate(IEnumString** ppEnum) mut => VT.[Friend]Enumerate(&this, ppEnum);
}

[CRepr]struct IColumnData : IUnknown
{
	public new const Guid IID = .(0x547c1354, 0x024d, 0x11d3, 0xa7, 0x07, 0x00, 0xc0, 0x4f, 0x8e, 0xf4, 0xcb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SColumnSetID* pColID, MMC_COLUMN_SET_DATA* pColSetData) SetColumnConfigData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SColumnSetID* pColID, MMC_COLUMN_SET_DATA** ppColSetData) GetColumnConfigData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SColumnSetID* pColID, MMC_SORT_SET_DATA* pColSortData) SetColumnSortData;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SColumnSetID* pColID, MMC_SORT_SET_DATA** ppColSortData) GetColumnSortData;
	}


	public HRESULT SetColumnConfigData(SColumnSetID* pColID, MMC_COLUMN_SET_DATA* pColSetData) mut => VT.[Friend]SetColumnConfigData(&this, pColID, pColSetData);

	public HRESULT GetColumnConfigData(SColumnSetID* pColID, MMC_COLUMN_SET_DATA** ppColSetData) mut => VT.[Friend]GetColumnConfigData(&this, pColID, ppColSetData);

	public HRESULT SetColumnSortData(SColumnSetID* pColID, MMC_SORT_SET_DATA* pColSortData) mut => VT.[Friend]SetColumnSortData(&this, pColID, pColSortData);

	public HRESULT GetColumnSortData(SColumnSetID* pColID, MMC_SORT_SET_DATA** ppColSortData) mut => VT.[Friend]GetColumnSortData(&this, pColID, ppColSortData);
}

[CRepr]struct IMessageView : IUnknown
{
	public new const Guid IID = .(0x80f94174, 0xfccc, 0x11d2, 0xb9, 0x91, 0x00, 0xc0, 0x4f, 0x8e, 0xcd, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitleText) SetTitleText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszBodyText) SetBodyText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IconIdentifier id) SetIcon;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT SetTitleText(PWSTR pszTitleText) mut => VT.[Friend]SetTitleText(&this, pszTitleText);

	public HRESULT SetBodyText(PWSTR pszBodyText) mut => VT.[Friend]SetBodyText(&this, pszBodyText);

	public HRESULT SetIcon(IconIdentifier id) mut => VT.[Friend]SetIcon(&this, id);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IResultDataCompareEx : IUnknown
{
	public new const Guid IID = .(0x96933476, 0x0251, 0x11d3, 0xae, 0xb0, 0x00, 0xc0, 0x4f, 0x8e, 0xcd, 0x78);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RDCOMPARE* prdc, int32* pnResult) Compare;
	}


	public HRESULT Compare(RDCOMPARE* prdc, int32* pnResult) mut => VT.[Friend]Compare(&this, prdc, pnResult);
}

[CRepr]struct IComponentData2 : IComponentData
{
	public new const Guid IID = .(0xcca0f2d2, 0x82de, 0x41b5, 0xbf, 0x47, 0x3b, 0x20, 0x76, 0x27, 0x3d, 0x5c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IComponentData.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, DATA_OBJECT_TYPES type, IDispatch** ppDispatch) QueryDispatch;
	}


	public HRESULT QueryDispatch(int cookie, DATA_OBJECT_TYPES type, IDispatch** ppDispatch) mut => VT.[Friend]QueryDispatch(&this, cookie, type, ppDispatch);
}

[CRepr]struct IComponent2 : IComponent
{
	public new const Guid IID = .(0x79a2d615, 0x4a10, 0x4ed4, 0x8c, 0x65, 0x86, 0x33, 0xf9, 0x33, 0x50, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IComponent.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, DATA_OBJECT_TYPES type, IDispatch** ppDispatch) QueryDispatch;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, RESULT_VIEW_TYPE_INFO* pResultViewType) GetResultViewType2;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int cookie, RESULT_VIEW_TYPE_INFO* pResultViewType) RestoreResultView;
	}


	public HRESULT QueryDispatch(int cookie, DATA_OBJECT_TYPES type, IDispatch** ppDispatch) mut => VT.[Friend]QueryDispatch(&this, cookie, type, ppDispatch);

	public HRESULT GetResultViewType2(int cookie, RESULT_VIEW_TYPE_INFO* pResultViewType) mut => VT.[Friend]GetResultViewType2(&this, cookie, pResultViewType);

	public HRESULT RestoreResultView(int cookie, RESULT_VIEW_TYPE_INFO* pResultViewType) mut => VT.[Friend]RestoreResultView(&this, cookie, pResultViewType);
}

[CRepr]struct IContextMenuCallback2 : IUnknown
{
	public new const Guid IID = .(0xe178bc0e, 0x2ed0, 0x4b5e, 0x80, 0x97, 0x42, 0xc9, 0x08, 0x7e, 0x8b, 0x33);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTEXTMENUITEM2* pItem) AddItem;
	}


	public HRESULT AddItem(CONTEXTMENUITEM2* pItem) mut => VT.[Friend]AddItem(&this, pItem);
}

[CRepr]struct IMMCVersionInfo : IUnknown
{
	public new const Guid IID = .(0xa8d2c5fe, 0xcdcb, 0x4b9d, 0xbd, 0xe5, 0xa2, 0x73, 0x43, 0xff, 0x54, 0xbc);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pVersionMajor, int32* pVersionMinor) GetMMCVersion;
	}


	public HRESULT GetMMCVersion(int32* pVersionMajor, int32* pVersionMinor) mut => VT.[Friend]GetMMCVersion(&this, pVersionMajor, pVersionMinor);
}

[CRepr]struct IExtendView : IUnknown
{
	public new const Guid IID = .(0x89995cee, 0xd2ed, 0x4c0e, 0xae, 0x5e, 0xdf, 0x7e, 0x76, 0xf3, 0xfa, 0x53);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, IViewExtensionCallback* pViewExtensionCallback) GetViews;
	}


	public HRESULT GetViews(IDataObject* pDataObject, IViewExtensionCallback* pViewExtensionCallback) mut => VT.[Friend]GetViews(&this, pDataObject, pViewExtensionCallback);
}

[CRepr]struct IViewExtensionCallback : IUnknown
{
	public new const Guid IID = .(0x34dd928a, 0x7599, 0x41e5, 0x9f, 0x5e, 0xd6, 0xbc, 0x30, 0x62, 0xc2, 0xda);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MMC_EXT_VIEW_DATA* pExtViewData) AddView;
	}


	public HRESULT AddView(MMC_EXT_VIEW_DATA* pExtViewData) mut => VT.[Friend]AddView(&this, pExtViewData);
}

[CRepr]struct IConsolePower : IUnknown
{
	public new const Guid IID = .(0x1cfbdd0e, 0x62ca, 0x49ce, 0xa3, 0xaf, 0xdb, 0xb2, 0xde, 0x61, 0xb0, 0x68);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAdd, uint32 dwRemove) SetExecutionState;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwFlags) ResetIdleTimer;
	}


	public HRESULT SetExecutionState(uint32 dwAdd, uint32 dwRemove) mut => VT.[Friend]SetExecutionState(&this, dwAdd, dwRemove);

	public HRESULT ResetIdleTimer(uint32 dwFlags) mut => VT.[Friend]ResetIdleTimer(&this, dwFlags);
}

[CRepr]struct IConsolePowerSink : IUnknown
{
	public new const Guid IID = .(0x3333759f, 0xfe4f, 0x4975, 0xb1, 0x43, 0xfe, 0xc0, 0xa5, 0xdd, 0x6d, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nEvent, LPARAM lParam, LRESULT* plReturn) OnPowerBroadcast;
	}


	public HRESULT OnPowerBroadcast(uint32 nEvent, LPARAM lParam, LRESULT* plReturn) mut => VT.[Friend]OnPowerBroadcast(&this, nEvent, lParam, plReturn);
}

[CRepr]struct INodeProperties : IUnknown
{
	public new const Guid IID = .(0x15bc4d24, 0xa522, 0x4406, 0xaa, 0x55, 0x07, 0x49, 0x53, 0x7a, 0x68, 0x65);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IDataObject* pDataObject, BSTR szPropertyName, uint16** pbstrProperty) GetProperty;
	}


	public HRESULT GetProperty(IDataObject* pDataObject, BSTR szPropertyName, uint16** pbstrProperty) mut => VT.[Friend]GetProperty(&this, pDataObject, szPropertyName, pbstrProperty);
}

[CRepr]struct IConsole3 : IConsole2
{
	public new const Guid IID = .(0x4f85efdb, 0xd0e1, 0x498c, 0x8d, 0x4a, 0xd0, 0x10, 0xdf, 0xdd, 0x40, 0x4f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IConsole2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int hScopeItem) RenameScopeItem;
	}


	public HRESULT RenameScopeItem(int hScopeItem) mut => VT.[Friend]RenameScopeItem(&this, hScopeItem);
}

[CRepr]struct IResultData2 : IResultData
{
	public new const Guid IID = .(0x0f36e0eb, 0xa7f1, 0x4a81, 0xbe, 0x5a, 0x92, 0x47, 0xf7, 0xde, 0x4b, 0x1b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IResultData.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int itemID) RenameResultItem;
	}


	public HRESULT RenameResultItem(int itemID) mut => VT.[Friend]RenameResultItem(&this, itemID);
}

#endregion
