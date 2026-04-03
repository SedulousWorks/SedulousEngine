using Win32.System.Com;
using Win32.Foundation;
using Win32.UI.Shell.PropertiesSystem;
using Win32.System.Com.StructuredStorage;
using Win32.Graphics.Gdi;
using System;

namespace Win32.UI.Ribbon;

#region Constants
public static
{
	public const uint32 UI_ALL_COMMANDS = 0;
	public const uint32 UI_COLLECTION_INVALIDINDEX = 4294967295;
	public const Guid LIBID_UIRibbon = .(0x942f35c2, 0xe83b, 0x45ef, 0xb0, 0x85, 0xac, 0x29, 0x5d, 0xd6, 0x3d, 0x5b);
}
#endregion

#region Enums

[AllowDuplicates]
public enum UI_CONTEXTAVAILABILITY : int32
{
	UI_CONTEXTAVAILABILITY_NOTAVAILABLE = 0,
	UI_CONTEXTAVAILABILITY_AVAILABLE = 1,
	UI_CONTEXTAVAILABILITY_ACTIVE = 2,
}


[AllowDuplicates]
public enum UI_FONTPROPERTIES : int32
{
	UI_FONTPROPERTIES_NOTAVAILABLE = 0,
	UI_FONTPROPERTIES_NOTSET = 1,
	UI_FONTPROPERTIES_SET = 2,
}


[AllowDuplicates]
public enum UI_FONTVERTICALPOSITION : int32
{
	UI_FONTVERTICALPOSITION_NOTAVAILABLE = 0,
	UI_FONTVERTICALPOSITION_NOTSET = 1,
	UI_FONTVERTICALPOSITION_SUPERSCRIPT = 2,
	UI_FONTVERTICALPOSITION_SUBSCRIPT = 3,
}


[AllowDuplicates]
public enum UI_FONTUNDERLINE : int32
{
	UI_FONTUNDERLINE_NOTAVAILABLE = 0,
	UI_FONTUNDERLINE_NOTSET = 1,
	UI_FONTUNDERLINE_SET = 2,
}


[AllowDuplicates]
public enum UI_FONTDELTASIZE : int32
{
	UI_FONTDELTASIZE_GROW = 0,
	UI_FONTDELTASIZE_SHRINK = 1,
}


[AllowDuplicates]
public enum UI_CONTROLDOCK : int32
{
	UI_CONTROLDOCK_TOP = 1,
	UI_CONTROLDOCK_BOTTOM = 3,
}


[AllowDuplicates]
public enum UI_SWATCHCOLORTYPE : int32
{
	UI_SWATCHCOLORTYPE_NOCOLOR = 0,
	UI_SWATCHCOLORTYPE_AUTOMATIC = 1,
	UI_SWATCHCOLORTYPE_RGB = 2,
}


[AllowDuplicates]
public enum UI_SWATCHCOLORMODE : int32
{
	UI_SWATCHCOLORMODE_NORMAL = 0,
	UI_SWATCHCOLORMODE_MONOCHROME = 1,
}


[AllowDuplicates]
public enum UI_EVENTTYPE : int32
{
	UI_EVENTTYPE_ApplicationMenuOpened = 0,
	UI_EVENTTYPE_RibbonMinimized = 1,
	UI_EVENTTYPE_RibbonExpanded = 2,
	UI_EVENTTYPE_ApplicationModeSwitched = 3,
	UI_EVENTTYPE_TabActivated = 4,
	UI_EVENTTYPE_MenuOpened = 5,
	UI_EVENTTYPE_CommandExecuted = 6,
	UI_EVENTTYPE_TooltipShown = 7,
}


[AllowDuplicates]
public enum UI_EVENTLOCATION : int32
{
	UI_EVENTLOCATION_Ribbon = 0,
	UI_EVENTLOCATION_QAT = 1,
	UI_EVENTLOCATION_ApplicationMenu = 2,
	UI_EVENTLOCATION_ContextPopup = 3,
}


[AllowDuplicates]
public enum UI_INVALIDATIONS : int32
{
	UI_INVALIDATIONS_STATE = 1,
	UI_INVALIDATIONS_VALUE = 2,
	UI_INVALIDATIONS_PROPERTY = 4,
	UI_INVALIDATIONS_ALLPROPERTIES = 8,
}


[AllowDuplicates]
public enum UI_COLLECTIONCHANGE : int32
{
	UI_COLLECTIONCHANGE_INSERT = 0,
	UI_COLLECTIONCHANGE_REMOVE = 1,
	UI_COLLECTIONCHANGE_REPLACE = 2,
	UI_COLLECTIONCHANGE_RESET = 3,
}


[AllowDuplicates]
public enum UI_EXECUTIONVERB : int32
{
	UI_EXECUTIONVERB_EXECUTE = 0,
	UI_EXECUTIONVERB_PREVIEW = 1,
	UI_EXECUTIONVERB_CANCELPREVIEW = 2,
}


[AllowDuplicates]
public enum UI_COMMANDTYPE : int32
{
	UI_COMMANDTYPE_UNKNOWN = 0,
	UI_COMMANDTYPE_GROUP = 1,
	UI_COMMANDTYPE_ACTION = 2,
	UI_COMMANDTYPE_ANCHOR = 3,
	UI_COMMANDTYPE_CONTEXT = 4,
	UI_COMMANDTYPE_COLLECTION = 5,
	UI_COMMANDTYPE_COMMANDCOLLECTION = 6,
	UI_COMMANDTYPE_DECIMAL = 7,
	UI_COMMANDTYPE_BOOLEAN = 8,
	UI_COMMANDTYPE_FONT = 9,
	UI_COMMANDTYPE_RECENTITEMS = 10,
	UI_COMMANDTYPE_COLORANCHOR = 11,
	UI_COMMANDTYPE_COLORCOLLECTION = 12,
}


[AllowDuplicates]
public enum UI_VIEWTYPE : int32
{
	UI_VIEWTYPE_RIBBON = 1,
}


[AllowDuplicates]
public enum UI_VIEWVERB : int32
{
	UI_VIEWVERB_CREATE = 0,
	UI_VIEWVERB_DESTROY = 1,
	UI_VIEWVERB_SIZE = 2,
	UI_VIEWVERB_ERROR = 3,
}


[AllowDuplicates]
public enum UI_OWNERSHIP : int32
{
	UI_OWNERSHIP_TRANSFER = 0,
	UI_OWNERSHIP_COPY = 1,
}

#endregion


#region Structs
[CRepr]
public struct UI_EVENTPARAMS_COMMAND
{
	public uint32 CommandID;
	public PWSTR CommandName;
	public uint32 ParentCommandID;
	public PWSTR ParentCommandName;
	public uint32 SelectionIndex;
	public UI_EVENTLOCATION Location;
}

[CRepr]
public struct UI_EVENTPARAMS
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public int32 Modes;
		public UI_EVENTPARAMS_COMMAND Params;
	}
	public UI_EVENTTYPE EventType;
	public using _Anonymous_e__Union Anonymous;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_UIRibbonFramework = .(0x926749fa, 0x2615, 0x4987, 0x88, 0x45, 0xc3, 0x3e, 0x65, 0xf2, 0xb9, 0x57);


	public const Guid CLSID_UIRibbonImageFromBitmapFactory = .(0x0f7434b6, 0x59b6, 0x4250, 0x99, 0x9e, 0xd1, 0x68, 0xd6, 0xae, 0x42, 0x93);


}
#endregion

#region COM Types
[CRepr]struct IUISimplePropertySet : IUnknown
{
	public new const Guid IID = .(0xc205bb48, 0x5b1c, 0x4219, 0xa1, 0x06, 0x15, 0xbd, 0x0a, 0x5f, 0x24, 0xe2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* value) GetValue;
	}


	public HRESULT GetValue(PROPERTYKEY* key, PROPVARIANT* value) mut => VT.[Friend]GetValue(&this, key, value);
}

[CRepr]struct IUIRibbon : IUnknown
{
	public new const Guid IID = .(0x803982ab, 0x370a, 0x4f7e, 0xa9, 0xe7, 0x87, 0x84, 0x03, 0x6a, 0x6e, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* cy) GetHeight;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream) LoadSettingsFromStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream* pStream) SaveSettingsToStream;
	}


	public HRESULT GetHeight(uint32* cy) mut => VT.[Friend]GetHeight(&this, cy);

	public HRESULT LoadSettingsFromStream(IStream* pStream) mut => VT.[Friend]LoadSettingsFromStream(&this, pStream);

	public HRESULT SaveSettingsToStream(IStream* pStream) mut => VT.[Friend]SaveSettingsToStream(&this, pStream);
}

[CRepr]struct IUIFramework : IUnknown
{
	public new const Guid IID = .(0xf4f0385d, 0x6872, 0x43a8, 0xad, 0x09, 0x4c, 0x33, 0x9c, 0xb3, 0xf5, 0xc5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND frameWnd, IUIApplication* application) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HINSTANCE instance, PWSTR resourceName) LoadUI;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 viewId, in Guid riid, void** ppv) GetView;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, PROPERTYKEY* key, PROPVARIANT* value) GetUICommandProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, PROPERTYKEY* key, PROPVARIANT* value) SetUICommandProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, UI_INVALIDATIONS flags, PROPERTYKEY* key) InvalidateUICommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) FlushPendingInvalidations;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 iModes) SetModes;
	}


	public HRESULT Initialize(HWND frameWnd, IUIApplication* application) mut => VT.[Friend]Initialize(&this, frameWnd, application);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT LoadUI(HINSTANCE instance, PWSTR resourceName) mut => VT.[Friend]LoadUI(&this, instance, resourceName);

	public HRESULT GetView(uint32 viewId, in Guid riid, void** ppv) mut => VT.[Friend]GetView(&this, viewId, riid, ppv);

	public HRESULT GetUICommandProperty(uint32 commandId, PROPERTYKEY* key, PROPVARIANT* value) mut => VT.[Friend]GetUICommandProperty(&this, commandId, key, value);

	public HRESULT SetUICommandProperty(uint32 commandId, PROPERTYKEY* key, PROPVARIANT* value) mut => VT.[Friend]SetUICommandProperty(&this, commandId, key, value);

	public HRESULT InvalidateUICommand(uint32 commandId, UI_INVALIDATIONS flags, PROPERTYKEY* key) mut => VT.[Friend]InvalidateUICommand(&this, commandId, flags, key);

	public HRESULT FlushPendingInvalidations() mut => VT.[Friend]FlushPendingInvalidations(&this);

	public HRESULT SetModes(int32 iModes) mut => VT.[Friend]SetModes(&this, iModes);
}

[CRepr]struct IUIEventLogger : IUnknown
{
	public new const Guid IID = .(0xec3e1034, 0xdbf4, 0x41a1, 0x95, 0xd5, 0x03, 0xe0, 0xf1, 0x02, 0x6e, 0x05);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, UI_EVENTPARAMS* pEventParams) OnUIEvent;
	}


	public void OnUIEvent(UI_EVENTPARAMS* pEventParams) mut => VT.[Friend]OnUIEvent(&this, pEventParams);
}

[CRepr]struct IUIEventingManager : IUnknown
{
	public new const Guid IID = .(0x3be6ea7f, 0x9a9b, 0x4198, 0x93, 0x68, 0x9b, 0x0f, 0x92, 0x3b, 0xd5, 0x34);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUIEventLogger* eventLogger) SetEventLogger;
	}


	public HRESULT SetEventLogger(IUIEventLogger* eventLogger) mut => VT.[Friend]SetEventLogger(&this, eventLogger);
}

[CRepr]struct IUIContextualUI : IUnknown
{
	public new const Guid IID = .(0xeea11f37, 0x7c46, 0x437c, 0x8e, 0x55, 0xb5, 0x21, 0x22, 0xb2, 0x92, 0x93);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 x, int32 y) ShowAtLocation;
	}


	public HRESULT ShowAtLocation(int32 x, int32 y) mut => VT.[Friend]ShowAtLocation(&this, x, y);
}

[CRepr]struct IUICollection : IUnknown
{
	public new const Guid IID = .(0xdf4f45bf, 0x6f9d, 0x4dd7, 0x9d, 0x68, 0xd8, 0xf9, 0xcd, 0x18, 0xc4, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* count) GetCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IUnknown** item) GetItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* item) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index, IUnknown* item) Insert;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 index) RemoveAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 indexReplaced, IUnknown* itemReplaceWith) Replace;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT GetCount(uint32* count) mut => VT.[Friend]GetCount(&this, count);

	public HRESULT GetItem(uint32 index, IUnknown** item) mut => VT.[Friend]GetItem(&this, index, item);

	public HRESULT Add(IUnknown* item) mut => VT.[Friend]Add(&this, item);

	public HRESULT Insert(uint32 index, IUnknown* item) mut => VT.[Friend]Insert(&this, index, item);

	public HRESULT RemoveAt(uint32 index) mut => VT.[Friend]RemoveAt(&this, index);

	public HRESULT Replace(uint32 indexReplaced, IUnknown* itemReplaceWith) mut => VT.[Friend]Replace(&this, indexReplaced, itemReplaceWith);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IUICollectionChangedEvent : IUnknown
{
	public new const Guid IID = .(0x6502ae91, 0xa14d, 0x44b5, 0xbb, 0xd0, 0x62, 0xaa, 0xcc, 0x58, 0x1d, 0x52);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, UI_COLLECTIONCHANGE action, uint32 oldIndex, IUnknown* oldItem, uint32 newIndex, IUnknown* newItem) OnChanged;
	}


	public HRESULT OnChanged(UI_COLLECTIONCHANGE action, uint32 oldIndex, IUnknown* oldItem, uint32 newIndex, IUnknown* newItem) mut => VT.[Friend]OnChanged(&this, action, oldIndex, oldItem, newIndex, newItem);
}

[CRepr]struct IUICommandHandler : IUnknown
{
	public new const Guid IID = .(0x75ae0a2d, 0xdc03, 0x4c9f, 0x88, 0x83, 0x06, 0x96, 0x60, 0xd0, 0xbe, 0xb6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, UI_EXECUTIONVERB verb, PROPERTYKEY* key, PROPVARIANT* currentValue, IUISimplePropertySet* commandExecutionProperties) Execute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, PROPERTYKEY* key, PROPVARIANT* currentValue, PROPVARIANT* newValue) UpdateProperty;
	}


	public HRESULT Execute(uint32 commandId, UI_EXECUTIONVERB verb, PROPERTYKEY* key, PROPVARIANT* currentValue, IUISimplePropertySet* commandExecutionProperties) mut => VT.[Friend]Execute(&this, commandId, verb, key, currentValue, commandExecutionProperties);

	public HRESULT UpdateProperty(uint32 commandId, PROPERTYKEY* key, PROPVARIANT* currentValue, PROPVARIANT* newValue) mut => VT.[Friend]UpdateProperty(&this, commandId, key, currentValue, newValue);
}

[CRepr]struct IUIApplication : IUnknown
{
	public new const Guid IID = .(0xd428903c, 0x729a, 0x491d, 0x91, 0x0d, 0x68, 0x2a, 0x08, 0xff, 0x25, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 viewId, UI_VIEWTYPE typeID, IUnknown* view, UI_VIEWVERB verb, int32 uReasonCode) OnViewChanged;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, UI_COMMANDTYPE typeID, IUICommandHandler** commandHandler) OnCreateUICommand;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 commandId, UI_COMMANDTYPE typeID, IUICommandHandler* commandHandler) OnDestroyUICommand;
	}


	public HRESULT OnViewChanged(uint32 viewId, UI_VIEWTYPE typeID, IUnknown* view, UI_VIEWVERB verb, int32 uReasonCode) mut => VT.[Friend]OnViewChanged(&this, viewId, typeID, view, verb, uReasonCode);

	public HRESULT OnCreateUICommand(uint32 commandId, UI_COMMANDTYPE typeID, IUICommandHandler** commandHandler) mut => VT.[Friend]OnCreateUICommand(&this, commandId, typeID, commandHandler);

	public HRESULT OnDestroyUICommand(uint32 commandId, UI_COMMANDTYPE typeID, IUICommandHandler* commandHandler) mut => VT.[Friend]OnDestroyUICommand(&this, commandId, typeID, commandHandler);
}

[CRepr]struct IUIImage : IUnknown
{
	public new const Guid IID = .(0x23c8c838, 0x4de6, 0x436b, 0xab, 0x01, 0x55, 0x54, 0xbb, 0x7c, 0x30, 0xdd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP* bitmap) GetBitmap;
	}


	public HRESULT GetBitmap(HBITMAP* bitmap) mut => VT.[Friend]GetBitmap(&this, bitmap);
}

[CRepr]struct IUIImageFromBitmap : IUnknown
{
	public new const Guid IID = .(0x18aba7f3, 0x4c1c, 0x4ba2, 0xbf, 0x6c, 0xf5, 0xc3, 0x32, 0x6f, 0xa8, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HBITMAP bitmap, UI_OWNERSHIP options, IUIImage** image) CreateImage;
	}


	public HRESULT CreateImage(HBITMAP bitmap, UI_OWNERSHIP options, IUIImage** image) mut => VT.[Friend]CreateImage(&this, bitmap, options, image);
}

#endregion
