using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Dxgi.Common;
using Win32.System.WinRT;
using System;

namespace Win32.UI.Xaml.Diagnostics;

#region Constants
public static
{
	public const HRESULT E_UNKNOWNTYPE = -2144665560;
}
#endregion

#region Enums

[AllowDuplicates]
public enum VisualMutationType : int32
{
	Add = 0,
	Remove = 1,
}


[AllowDuplicates]
public enum BaseValueSource : int32
{
	BaseValueSourceUnknown = 0,
	BaseValueSourceDefault = 1,
	BaseValueSourceBuiltInStyle = 2,
	BaseValueSourceStyle = 3,
	BaseValueSourceLocal = 4,
	Inherited = 5,
	DefaultStyleTrigger = 6,
	TemplateTrigger = 7,
	StyleTrigger = 8,
	ImplicitStyleReference = 9,
	ParentTemplate = 10,
	ParentTemplateTrigger = 11,
	Animation = 12,
	Coercion = 13,
	BaseValueSourceVisualState = 14,
}


[AllowDuplicates]
public enum MetadataBit : int32
{
	None = 0,
	IsValueHandle = 1,
	IsPropertyReadOnly = 2,
	IsValueCollection = 4,
	IsValueCollectionReadOnly = 8,
	IsValueBindingExpression = 16,
	IsValueNull = 32,
	IsValueHandleAndEvaluatedValue = 64,
}


[AllowDuplicates]
public enum RenderTargetBitmapOptions : int32
{
	RenderTarget = 0,
	RenderTargetAndChildren = 1,
}


[AllowDuplicates]
public enum ResourceType : int32
{
	ResourceTypeStatic = 0,
	ResourceTypeTheme = 1,
}


[AllowDuplicates]
public enum VisualElementState : int32
{
	ErrorResolved = 0,
	ErrorResourceNotFound = 1,
	ErrorInvalidResource = 2,
}

#endregion


#region Structs
[CRepr]
public struct SourceInfo
{
	public BSTR FileName;
	public uint32 LineNumber;
	public uint32 ColumnNumber;
	public uint32 CharPosition;
	public BSTR Hash;
}

[CRepr]
public struct ParentChildRelation
{
	public uint64 Parent;
	public uint64 Child;
	public uint32 ChildIndex;
}

[CRepr]
public struct VisualElement
{
	public uint64 Handle;
	public SourceInfo SrcInfo;
	public BSTR Type;
	public BSTR Name;
	public uint32 NumChildren;
}

[CRepr]
public struct PropertyChainSource
{
	public uint64 Handle;
	public BSTR TargetType;
	public BSTR Name;
	public BaseValueSource Source;
	public SourceInfo SrcInfo;
}

[CRepr]
public struct PropertyChainValue
{
	public uint32 Index;
	public BSTR Type;
	public BSTR DeclaringType;
	public BSTR ValueType;
	public BSTR ItemType;
	public BSTR Value;
	public BOOL Overridden;
	public int64 MetadataBits;
	public BSTR PropertyName;
	public uint32 PropertyChainIndex;
}

[CRepr]
public struct EnumType
{
	public BSTR Name;
	public SAFEARRAY* ValueInts;
	public SAFEARRAY* ValueStrings;
}

[CRepr]
public struct CollectionElementValue
{
	public uint32 Index;
	public BSTR ValueType;
	public BSTR Value;
	public int64 MetadataBits;
}

[CRepr]
public struct BitmapDescription
{
	public uint32 Width;
	public uint32 Height;
	public DXGI_FORMAT Format;
	public DXGI_ALPHA_MODE AlphaMode;
}

#endregion

#region COM Types
[CRepr]struct IVisualTreeServiceCallback : IUnknown
{
	public new const Guid IID = .(0xaa7a8931, 0x80e4, 0x4fec, 0x8f, 0x3b, 0x55, 0x3f, 0x87, 0xb4, 0x96, 0x6e);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ParentChildRelation relation, VisualElement element, VisualMutationType mutationType) OnVisualTreeChange;
	}


	public HRESULT OnVisualTreeChange(ParentChildRelation relation, VisualElement element, VisualMutationType mutationType) mut => VT.[Friend]OnVisualTreeChange(&this, relation, element, mutationType);
}

[CRepr]struct IVisualTreeServiceCallback2 : IVisualTreeServiceCallback
{
	public new const Guid IID = .(0xbad9eb88, 0xae77, 0x4397, 0xb9, 0x48, 0x5f, 0xa2, 0xdb, 0x0a, 0x19, 0xea);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVisualTreeServiceCallback.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 element, VisualElementState elementState, PWSTR context) OnElementStateChanged;
	}


	public HRESULT OnElementStateChanged(uint64 element, VisualElementState elementState, PWSTR context) mut => VT.[Friend]OnElementStateChanged(&this, element, elementState, context);
}

[CRepr]struct IVisualTreeService : IUnknown
{
	public new const Guid IID = .(0xa593b11a, 0xd17f, 0x48bb, 0x8f, 0x66, 0x83, 0x91, 0x07, 0x31, 0xc8, 0xa5);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVisualTreeServiceCallback* pCallback) AdviseVisualTreeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IVisualTreeServiceCallback* pCallback) UnadviseVisualTreeChange;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount, EnumType** ppEnums) GetEnums;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR typeName, BSTR value, uint64* pInstanceHandle) CreateInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, uint32* pSourceCount, PropertyChainSource** ppPropertySources, uint32* pPropertyCount, PropertyChainValue** ppPropertyValues) GetPropertyValuesChain;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, uint64 value, uint32 propertyIndex) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, uint32 propertyIndex) ClearProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, uint32* pCollectionSize) GetCollectionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, uint32 startIndex, uint32* pElementCount, CollectionElementValue** ppElementValues) GetCollectionElements;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 parent, uint64 child, uint32 index) AddChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 parent, uint32 index) RemoveChild;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 parent) ClearChildren;
	}


	public HRESULT AdviseVisualTreeChange(IVisualTreeServiceCallback* pCallback) mut => VT.[Friend]AdviseVisualTreeChange(&this, pCallback);

	public HRESULT UnadviseVisualTreeChange(IVisualTreeServiceCallback* pCallback) mut => VT.[Friend]UnadviseVisualTreeChange(&this, pCallback);

	public HRESULT GetEnums(uint32* pCount, EnumType** ppEnums) mut => VT.[Friend]GetEnums(&this, pCount, ppEnums);

	public HRESULT CreateInstance(BSTR typeName, BSTR value, uint64* pInstanceHandle) mut => VT.[Friend]CreateInstance(&this, typeName, value, pInstanceHandle);

	public HRESULT GetPropertyValuesChain(uint64 instanceHandle, uint32* pSourceCount, PropertyChainSource** ppPropertySources, uint32* pPropertyCount, PropertyChainValue** ppPropertyValues) mut => VT.[Friend]GetPropertyValuesChain(&this, instanceHandle, pSourceCount, ppPropertySources, pPropertyCount, ppPropertyValues);

	public HRESULT SetProperty(uint64 instanceHandle, uint64 value, uint32 propertyIndex) mut => VT.[Friend]SetProperty(&this, instanceHandle, value, propertyIndex);

	public HRESULT ClearProperty(uint64 instanceHandle, uint32 propertyIndex) mut => VT.[Friend]ClearProperty(&this, instanceHandle, propertyIndex);

	public HRESULT GetCollectionCount(uint64 instanceHandle, uint32* pCollectionSize) mut => VT.[Friend]GetCollectionCount(&this, instanceHandle, pCollectionSize);

	public HRESULT GetCollectionElements(uint64 instanceHandle, uint32 startIndex, uint32* pElementCount, CollectionElementValue** ppElementValues) mut => VT.[Friend]GetCollectionElements(&this, instanceHandle, startIndex, pElementCount, ppElementValues);

	public HRESULT AddChild(uint64 parent, uint64 child, uint32 index) mut => VT.[Friend]AddChild(&this, parent, child, index);

	public HRESULT RemoveChild(uint64 parent, uint32 index) mut => VT.[Friend]RemoveChild(&this, parent, index);

	public HRESULT ClearChildren(uint64 parent) mut => VT.[Friend]ClearChildren(&this, parent);
}

[CRepr]struct IXamlDiagnostics : IUnknown
{
	public new const Guid IID = .(0x18c9e2b6, 0x3f43, 0x4116, 0x9f, 0x2b, 0xff, 0x93, 0x5d, 0x77, 0x70, 0xd2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable** ppDispatcher) GetDispatcher;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable** ppLayer) GetUiLayer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable** ppApplication) GetApplication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 instanceHandle, IInspectable** ppInstance) GetIInspectableFromHandle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable* pInstance, uint64* pHandle) GetHandleFromIInspectable;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, RECT rect, uint32* pCount, uint64** ppInstanceHandles) HitTest;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IInspectable* pInstance, uint64* pInstanceHandle) RegisterInstance;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pInitializationData) GetInitializationData;
	}


	public HRESULT GetDispatcher(IInspectable** ppDispatcher) mut => VT.[Friend]GetDispatcher(&this, ppDispatcher);

	public HRESULT GetUiLayer(IInspectable** ppLayer) mut => VT.[Friend]GetUiLayer(&this, ppLayer);

	public HRESULT GetApplication(IInspectable** ppApplication) mut => VT.[Friend]GetApplication(&this, ppApplication);

	public HRESULT GetIInspectableFromHandle(uint64 instanceHandle, IInspectable** ppInstance) mut => VT.[Friend]GetIInspectableFromHandle(&this, instanceHandle, ppInstance);

	public HRESULT GetHandleFromIInspectable(IInspectable* pInstance, uint64* pHandle) mut => VT.[Friend]GetHandleFromIInspectable(&this, pInstance, pHandle);

	public HRESULT HitTest(RECT rect, uint32* pCount, uint64** ppInstanceHandles) mut => VT.[Friend]HitTest(&this, rect, pCount, ppInstanceHandles);

	public HRESULT RegisterInstance(IInspectable* pInstance, uint64* pInstanceHandle) mut => VT.[Friend]RegisterInstance(&this, pInstance, pInstanceHandle);

	public HRESULT GetInitializationData(BSTR* pInitializationData) mut => VT.[Friend]GetInitializationData(&this, pInitializationData);
}

[CRepr]struct IBitmapData : IUnknown
{
	public new const Guid IID = .(0xd1a34ef2, 0xcad8, 0x4635, 0xa3, 0xd2, 0xfc, 0xda, 0x8d, 0x3f, 0x3c, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 sourceOffsetInBytes, uint32 maxBytesToCopy, uint8* pvBytes, uint32* numberOfBytesCopied) CopyBytesTo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pStride) GetStride;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BitmapDescription* pBitmapDescription) GetBitmapDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BitmapDescription* pBitmapDescription) GetSourceBitmapDescription;
	}


	public HRESULT CopyBytesTo(uint32 sourceOffsetInBytes, uint32 maxBytesToCopy, uint8* pvBytes, uint32* numberOfBytesCopied) mut => VT.[Friend]CopyBytesTo(&this, sourceOffsetInBytes, maxBytesToCopy, pvBytes, numberOfBytesCopied);

	public HRESULT GetStride(uint32* pStride) mut => VT.[Friend]GetStride(&this, pStride);

	public HRESULT GetBitmapDescription(BitmapDescription* pBitmapDescription) mut => VT.[Friend]GetBitmapDescription(&this, pBitmapDescription);

	public HRESULT GetSourceBitmapDescription(BitmapDescription* pBitmapDescription) mut => VT.[Friend]GetSourceBitmapDescription(&this, pBitmapDescription);
}

[CRepr]struct IVisualTreeService2 : IVisualTreeService
{
	public new const Guid IID = .(0x130f5136, 0xec43, 0x4f61, 0x89, 0xc7, 0x98, 0x01, 0xa3, 0x6d, 0x2e, 0x95);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVisualTreeService.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 object, PWSTR propertyName, uint32* pPropertyIndex) GetPropertyIndex;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 object, uint32 propertyIndex, uint64* pValue) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 resourceDictionary, uint64 key, uint64 newValue) ReplaceResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 handle, RenderTargetBitmapOptions options, uint32 maxPixelWidth, uint32 maxPixelHeight, IBitmapData** ppBitmapData) RenderTargetBitmap;
	}


	public HRESULT GetPropertyIndex(uint64 object, PWSTR propertyName, uint32* pPropertyIndex) mut => VT.[Friend]GetPropertyIndex(&this, object, propertyName, pPropertyIndex);

	public HRESULT GetProperty(uint64 object, uint32 propertyIndex, uint64* pValue) mut => VT.[Friend]GetProperty(&this, object, propertyIndex, pValue);

	public HRESULT ReplaceResource(uint64 resourceDictionary, uint64 key, uint64 newValue) mut => VT.[Friend]ReplaceResource(&this, resourceDictionary, key, newValue);

	public HRESULT RenderTargetBitmap(uint64 handle, RenderTargetBitmapOptions options, uint32 maxPixelWidth, uint32 maxPixelHeight, IBitmapData** ppBitmapData) mut => VT.[Friend]RenderTargetBitmap(&this, handle, options, maxPixelWidth, maxPixelHeight, ppBitmapData);
}

[CRepr]struct IVisualTreeService3 : IVisualTreeService2
{
	public new const Guid IID = .(0x0e79c6e0, 0x85a0, 0x4be8, 0xb4, 0x1a, 0x65, 0x5c, 0xf1, 0xfd, 0x19, 0xbd);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IVisualTreeService2.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 resourceContext, PWSTR resourceName, ResourceType resourceType, uint32 propertyIndex) ResolveResource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dictionaryHandle, PWSTR resourceName, BOOL resourceIsImplicitStyle, uint64* resourceHandle) GetDictionaryItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dictionaryHandle, uint64 resourceKey, uint64 resourceHandle) AddDictionaryItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint64 dictionaryHandle, uint64 resourceKey) RemoveDictionaryItem;
	}


	public HRESULT ResolveResource(uint64 resourceContext, PWSTR resourceName, ResourceType resourceType, uint32 propertyIndex) mut => VT.[Friend]ResolveResource(&this, resourceContext, resourceName, resourceType, propertyIndex);

	public HRESULT GetDictionaryItem(uint64 dictionaryHandle, PWSTR resourceName, BOOL resourceIsImplicitStyle, uint64* resourceHandle) mut => VT.[Friend]GetDictionaryItem(&this, dictionaryHandle, resourceName, resourceIsImplicitStyle, resourceHandle);

	public HRESULT AddDictionaryItem(uint64 dictionaryHandle, uint64 resourceKey, uint64 resourceHandle) mut => VT.[Friend]AddDictionaryItem(&this, dictionaryHandle, resourceKey, resourceHandle);

	public HRESULT RemoveDictionaryItem(uint64 dictionaryHandle, uint64 resourceKey) mut => VT.[Friend]RemoveDictionaryItem(&this, dictionaryHandle, resourceKey);
}

#endregion

#region Functions
public static
{
	[Import("Windows.UI.Xaml.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitializeXamlDiagnostic(PWSTR endPointName, uint32 pid, PWSTR wszDllXamlDiagnostics, PWSTR wszTAPDllName, Guid tapClsid);

	[Import("Windows.UI.Xaml.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT InitializeXamlDiagnosticsEx(PWSTR endPointName, uint32 pid, PWSTR wszDllXamlDiagnostics, PWSTR wszTAPDllName, Guid tapClsid, PWSTR wszInitializationData);

}
#endregion
