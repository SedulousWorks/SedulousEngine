using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.Com.Events;

#region Enums

[AllowDuplicates]
public enum EOC_ChangeType : int32
{
	EOC_NewObject = 0,
	EOC_ModifiedObject = 1,
	EOC_DeletedObject = 2,
}

#endregion


#region Structs
[CRepr]
public struct COMEVENTSYSCHANGEINFO
{
	public uint32 cbSize;
	public EOC_ChangeType changeType;
	public BSTR objectId;
	public BSTR partitionId;
	public BSTR applicationId;
	public Guid[10] reserved;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_CEventSystem = .(0x4e14fba2, 0x2e22, 0x11d1, 0x99, 0x64, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);


	public const Guid CLSID_CEventPublisher = .(0xab944620, 0x79c6, 0x11d1, 0x88, 0xf9, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);


	public const Guid CLSID_CEventClass = .(0xcdbec9c0, 0x7a68, 0x11d1, 0x88, 0xf9, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);


	public const Guid CLSID_CEventSubscription = .(0x7542e960, 0x79c7, 0x11d1, 0x88, 0xf9, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);


	public const Guid CLSID_EventObjectChange = .(0xd0565000, 0x9df4, 0x11d1, 0xa2, 0x81, 0x00, 0xc0, 0x4f, 0xca, 0x0a, 0xa7);


	public const Guid CLSID_EventObjectChange2 = .(0xbb07bacd, 0xcd56, 0x4e63, 0xa8, 0xff, 0xcb, 0xf0, 0x35, 0x5f, 0xb9, 0xf4);


}
#endregion

#region COM Types
[CRepr]struct IEventSystem : IDispatch
{
	public new const Guid IID = .(0x4e14fb9f, 0x2e22, 0x11d1, 0x99, 0x64, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR progID, BSTR queryCriteria, int32* errorIndex, IUnknown** ppInterface) Query;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR ProgID, IUnknown* pInterface) Store;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR progID, BSTR queryCriteria, int32* errorIndex) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrEventClassID) get_EventObjectChangeEventClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR progID, BSTR queryCriteria, IUnknown** ppInterface) QueryS;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR progID, BSTR queryCriteria) RemoveS;
	}


	public HRESULT Query(BSTR progID, BSTR queryCriteria, int32* errorIndex, IUnknown** ppInterface) mut => VT.[Friend]Query(&this, progID, queryCriteria, errorIndex, ppInterface);

	public HRESULT Store(BSTR ProgID, IUnknown* pInterface) mut => VT.[Friend]Store(&this, ProgID, pInterface);

	public HRESULT Remove(BSTR progID, BSTR queryCriteria, int32* errorIndex) mut => VT.[Friend]Remove(&this, progID, queryCriteria, errorIndex);

	public HRESULT get_EventObjectChangeEventClassID(BSTR* pbstrEventClassID) mut => VT.[Friend]get_EventObjectChangeEventClassID(&this, pbstrEventClassID);

	public HRESULT QueryS(BSTR progID, BSTR queryCriteria, IUnknown** ppInterface) mut => VT.[Friend]QueryS(&this, progID, queryCriteria, ppInterface);

	public HRESULT RemoveS(BSTR progID, BSTR queryCriteria) mut => VT.[Friend]RemoveS(&this, progID, queryCriteria);
}

[CRepr]struct IEventPublisher : IDispatch
{
	public new const Guid IID = .(0xe341516b, 0x2e32, 0x11d1, 0x99, 0x64, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPublisherID) get_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPublisherID) put_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPublisherName) get_PublisherName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPublisherName) put_PublisherName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPublisherType) get_PublisherType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPublisherType) put_PublisherType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOwnerSID) get_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOwnerSID) put_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) GetDefaultProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) PutDefaultProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName) RemoveDefaultProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEventObjectCollection** collection) GetDefaultPropertyCollection;
	}


	public HRESULT get_PublisherID(BSTR* pbstrPublisherID) mut => VT.[Friend]get_PublisherID(&this, pbstrPublisherID);

	public HRESULT put_PublisherID(BSTR bstrPublisherID) mut => VT.[Friend]put_PublisherID(&this, bstrPublisherID);

	public HRESULT get_PublisherName(BSTR* pbstrPublisherName) mut => VT.[Friend]get_PublisherName(&this, pbstrPublisherName);

	public HRESULT put_PublisherName(BSTR bstrPublisherName) mut => VT.[Friend]put_PublisherName(&this, bstrPublisherName);

	public HRESULT get_PublisherType(BSTR* pbstrPublisherType) mut => VT.[Friend]get_PublisherType(&this, pbstrPublisherType);

	public HRESULT put_PublisherType(BSTR bstrPublisherType) mut => VT.[Friend]put_PublisherType(&this, bstrPublisherType);

	public HRESULT get_OwnerSID(BSTR* pbstrOwnerSID) mut => VT.[Friend]get_OwnerSID(&this, pbstrOwnerSID);

	public HRESULT put_OwnerSID(BSTR bstrOwnerSID) mut => VT.[Friend]put_OwnerSID(&this, bstrOwnerSID);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT GetDefaultProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]GetDefaultProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT PutDefaultProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]PutDefaultProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT RemoveDefaultProperty(BSTR bstrPropertyName) mut => VT.[Friend]RemoveDefaultProperty(&this, bstrPropertyName);

	public HRESULT GetDefaultPropertyCollection(IEventObjectCollection** collection) mut => VT.[Friend]GetDefaultPropertyCollection(&this, collection);
}

[CRepr]struct IEventClass : IDispatch
{
	public new const Guid IID = .(0xfb2b72a0, 0x7a68, 0x11d1, 0x88, 0xf9, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrEventClassID) get_EventClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEventClassID) put_EventClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrEventClassName) get_EventClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEventClassName) put_EventClassName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOwnerSID) get_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOwnerSID) put_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFiringInterfaceID) get_FiringInterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrFiringInterfaceID) put_FiringInterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrCustomConfigCLSID) get_CustomConfigCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrCustomConfigCLSID) put_CustomConfigCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTypeLib) get_TypeLib;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrTypeLib) put_TypeLib;
	}


	public HRESULT get_EventClassID(BSTR* pbstrEventClassID) mut => VT.[Friend]get_EventClassID(&this, pbstrEventClassID);

	public HRESULT put_EventClassID(BSTR bstrEventClassID) mut => VT.[Friend]put_EventClassID(&this, bstrEventClassID);

	public HRESULT get_EventClassName(BSTR* pbstrEventClassName) mut => VT.[Friend]get_EventClassName(&this, pbstrEventClassName);

	public HRESULT put_EventClassName(BSTR bstrEventClassName) mut => VT.[Friend]put_EventClassName(&this, bstrEventClassName);

	public HRESULT get_OwnerSID(BSTR* pbstrOwnerSID) mut => VT.[Friend]get_OwnerSID(&this, pbstrOwnerSID);

	public HRESULT put_OwnerSID(BSTR bstrOwnerSID) mut => VT.[Friend]put_OwnerSID(&this, bstrOwnerSID);

	public HRESULT get_FiringInterfaceID(BSTR* pbstrFiringInterfaceID) mut => VT.[Friend]get_FiringInterfaceID(&this, pbstrFiringInterfaceID);

	public HRESULT put_FiringInterfaceID(BSTR bstrFiringInterfaceID) mut => VT.[Friend]put_FiringInterfaceID(&this, bstrFiringInterfaceID);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_CustomConfigCLSID(BSTR* pbstrCustomConfigCLSID) mut => VT.[Friend]get_CustomConfigCLSID(&this, pbstrCustomConfigCLSID);

	public HRESULT put_CustomConfigCLSID(BSTR bstrCustomConfigCLSID) mut => VT.[Friend]put_CustomConfigCLSID(&this, bstrCustomConfigCLSID);

	public HRESULT get_TypeLib(BSTR* pbstrTypeLib) mut => VT.[Friend]get_TypeLib(&this, pbstrTypeLib);

	public HRESULT put_TypeLib(BSTR bstrTypeLib) mut => VT.[Friend]put_TypeLib(&this, bstrTypeLib);
}

[CRepr]struct IEventClass2 : IEventClass
{
	public new const Guid IID = .(0xfb2b72a1, 0x7a68, 0x11d1, 0x88, 0xf9, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IEventClass.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPublisherID) get_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPublisherID) put_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPubFilCLSID) get_MultiInterfacePublisherFilterCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPubFilCLSID) put_MultiInterfacePublisherFilterCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAllowInprocActivation) get_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fAllowInprocActivation) put_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfFireInParallel) get_FireInParallel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFireInParallel) put_FireInParallel;
	}


	public HRESULT get_PublisherID(BSTR* pbstrPublisherID) mut => VT.[Friend]get_PublisherID(&this, pbstrPublisherID);

	public HRESULT put_PublisherID(BSTR bstrPublisherID) mut => VT.[Friend]put_PublisherID(&this, bstrPublisherID);

	public HRESULT get_MultiInterfacePublisherFilterCLSID(BSTR* pbstrPubFilCLSID) mut => VT.[Friend]get_MultiInterfacePublisherFilterCLSID(&this, pbstrPubFilCLSID);

	public HRESULT put_MultiInterfacePublisherFilterCLSID(BSTR bstrPubFilCLSID) mut => VT.[Friend]put_MultiInterfacePublisherFilterCLSID(&this, bstrPubFilCLSID);

	public HRESULT get_AllowInprocActivation(BOOL* pfAllowInprocActivation) mut => VT.[Friend]get_AllowInprocActivation(&this, pfAllowInprocActivation);

	public HRESULT put_AllowInprocActivation(BOOL fAllowInprocActivation) mut => VT.[Friend]put_AllowInprocActivation(&this, fAllowInprocActivation);

	public HRESULT get_FireInParallel(BOOL* pfFireInParallel) mut => VT.[Friend]get_FireInParallel(&this, pfFireInParallel);

	public HRESULT put_FireInParallel(BOOL fFireInParallel) mut => VT.[Friend]put_FireInParallel(&this, fFireInParallel);
}

[CRepr]struct IEventSubscription : IDispatch
{
	public new const Guid IID = .(0x4a6b0e15, 0x2e38, 0x11d1, 0x99, 0x65, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubscriptionID) get_SubscriptionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubscriptionID) put_SubscriptionID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubscriptionName) get_SubscriptionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubscriptionName) put_SubscriptionName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPublisherID) get_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPublisherID) put_PublisherID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrEventClassID) get_EventClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrEventClassID) put_EventClassID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMethodName) get_MethodName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMethodName) put_MethodName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubscriberCLSID) get_SubscriberCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrSubscriberCLSID) put_SubscriberCLSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppSubscriberInterface) get_SubscriberInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown* pSubscriberInterface) put_SubscriberInterface;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfPerUser) get_PerUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fPerUser) put_PerUser;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrOwnerSID) get_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrOwnerSID) put_OwnerSID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfEnabled) get_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fEnabled) put_Enabled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDescription) get_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrDescription) put_Description;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrMachineName) get_MachineName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrMachineName) put_MachineName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) GetPublisherProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) PutPublisherProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName) RemovePublisherProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEventObjectCollection** collection) GetPublisherPropertyCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) GetSubscriberProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName, VARIANT* propertyValue) PutSubscriberProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrPropertyName) RemoveSubscriberProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEventObjectCollection** collection) GetSubscriberPropertyCollection;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrInterfaceID) get_InterfaceID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR bstrInterfaceID) put_InterfaceID;
	}


	public HRESULT get_SubscriptionID(BSTR* pbstrSubscriptionID) mut => VT.[Friend]get_SubscriptionID(&this, pbstrSubscriptionID);

	public HRESULT put_SubscriptionID(BSTR bstrSubscriptionID) mut => VT.[Friend]put_SubscriptionID(&this, bstrSubscriptionID);

	public HRESULT get_SubscriptionName(BSTR* pbstrSubscriptionName) mut => VT.[Friend]get_SubscriptionName(&this, pbstrSubscriptionName);

	public HRESULT put_SubscriptionName(BSTR bstrSubscriptionName) mut => VT.[Friend]put_SubscriptionName(&this, bstrSubscriptionName);

	public HRESULT get_PublisherID(BSTR* pbstrPublisherID) mut => VT.[Friend]get_PublisherID(&this, pbstrPublisherID);

	public HRESULT put_PublisherID(BSTR bstrPublisherID) mut => VT.[Friend]put_PublisherID(&this, bstrPublisherID);

	public HRESULT get_EventClassID(BSTR* pbstrEventClassID) mut => VT.[Friend]get_EventClassID(&this, pbstrEventClassID);

	public HRESULT put_EventClassID(BSTR bstrEventClassID) mut => VT.[Friend]put_EventClassID(&this, bstrEventClassID);

	public HRESULT get_MethodName(BSTR* pbstrMethodName) mut => VT.[Friend]get_MethodName(&this, pbstrMethodName);

	public HRESULT put_MethodName(BSTR bstrMethodName) mut => VT.[Friend]put_MethodName(&this, bstrMethodName);

	public HRESULT get_SubscriberCLSID(BSTR* pbstrSubscriberCLSID) mut => VT.[Friend]get_SubscriberCLSID(&this, pbstrSubscriberCLSID);

	public HRESULT put_SubscriberCLSID(BSTR bstrSubscriberCLSID) mut => VT.[Friend]put_SubscriberCLSID(&this, bstrSubscriberCLSID);

	public HRESULT get_SubscriberInterface(IUnknown** ppSubscriberInterface) mut => VT.[Friend]get_SubscriberInterface(&this, ppSubscriberInterface);

	public HRESULT put_SubscriberInterface(IUnknown* pSubscriberInterface) mut => VT.[Friend]put_SubscriberInterface(&this, pSubscriberInterface);

	public HRESULT get_PerUser(BOOL* pfPerUser) mut => VT.[Friend]get_PerUser(&this, pfPerUser);

	public HRESULT put_PerUser(BOOL fPerUser) mut => VT.[Friend]put_PerUser(&this, fPerUser);

	public HRESULT get_OwnerSID(BSTR* pbstrOwnerSID) mut => VT.[Friend]get_OwnerSID(&this, pbstrOwnerSID);

	public HRESULT put_OwnerSID(BSTR bstrOwnerSID) mut => VT.[Friend]put_OwnerSID(&this, bstrOwnerSID);

	public HRESULT get_Enabled(BOOL* pfEnabled) mut => VT.[Friend]get_Enabled(&this, pfEnabled);

	public HRESULT put_Enabled(BOOL fEnabled) mut => VT.[Friend]put_Enabled(&this, fEnabled);

	public HRESULT get_Description(BSTR* pbstrDescription) mut => VT.[Friend]get_Description(&this, pbstrDescription);

	public HRESULT put_Description(BSTR bstrDescription) mut => VT.[Friend]put_Description(&this, bstrDescription);

	public HRESULT get_MachineName(BSTR* pbstrMachineName) mut => VT.[Friend]get_MachineName(&this, pbstrMachineName);

	public HRESULT put_MachineName(BSTR bstrMachineName) mut => VT.[Friend]put_MachineName(&this, bstrMachineName);

	public HRESULT GetPublisherProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]GetPublisherProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT PutPublisherProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]PutPublisherProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT RemovePublisherProperty(BSTR bstrPropertyName) mut => VT.[Friend]RemovePublisherProperty(&this, bstrPropertyName);

	public HRESULT GetPublisherPropertyCollection(IEventObjectCollection** collection) mut => VT.[Friend]GetPublisherPropertyCollection(&this, collection);

	public HRESULT GetSubscriberProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]GetSubscriberProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT PutSubscriberProperty(BSTR bstrPropertyName, VARIANT* propertyValue) mut => VT.[Friend]PutSubscriberProperty(&this, bstrPropertyName, propertyValue);

	public HRESULT RemoveSubscriberProperty(BSTR bstrPropertyName) mut => VT.[Friend]RemoveSubscriberProperty(&this, bstrPropertyName);

	public HRESULT GetSubscriberPropertyCollection(IEventObjectCollection** collection) mut => VT.[Friend]GetSubscriberPropertyCollection(&this, collection);

	public HRESULT get_InterfaceID(BSTR* pbstrInterfaceID) mut => VT.[Friend]get_InterfaceID(&this, pbstrInterfaceID);

	public HRESULT put_InterfaceID(BSTR bstrInterfaceID) mut => VT.[Friend]put_InterfaceID(&this, bstrInterfaceID);
}

[CRepr]struct IFiringControl : IDispatch
{
	public new const Guid IID = .(0xe0498c93, 0x4efe, 0x11d1, 0x99, 0x71, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEventSubscription* subscription) FireSubscription;
	}


	public HRESULT FireSubscription(IEventSubscription* subscription) mut => VT.[Friend]FireSubscription(&this, subscription);
}

[CRepr]struct IPublisherFilter : IUnknown
{
	public new const Guid IID = .(0x465e5cc0, 0x7b26, 0x11d1, 0x88, 0xfb, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR methodName, IDispatch* dispUserDefined) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR methodName, IFiringControl* firingControl) PrepareToFire;
	}


	public HRESULT Initialize(BSTR methodName, IDispatch* dispUserDefined) mut => VT.[Friend]Initialize(&this, methodName, dispUserDefined);

	public HRESULT PrepareToFire(BSTR methodName, IFiringControl* firingControl) mut => VT.[Friend]PrepareToFire(&this, methodName, firingControl);
}

[CRepr]struct IMultiInterfacePublisherFilter : IUnknown
{
	public new const Guid IID = .(0x465e5cc1, 0x7b26, 0x11d1, 0x88, 0xfb, 0x00, 0x80, 0xc7, 0xd7, 0x71, 0xbf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMultiInterfaceEventControl* pEIC) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid iid, BSTR methodName, IFiringControl* firingControl) PrepareToFire;
	}


	public HRESULT Initialize(IMultiInterfaceEventControl* pEIC) mut => VT.[Friend]Initialize(&this, pEIC);

	public HRESULT PrepareToFire(in Guid iid, BSTR methodName, IFiringControl* firingControl) mut => VT.[Friend]PrepareToFire(&this, iid, methodName, firingControl);
}

[CRepr]struct IEventObjectChange : IUnknown
{
	public new const Guid IID = .(0xf4a07d70, 0x2e25, 0x11d1, 0x99, 0x64, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EOC_ChangeType changeType, BSTR bstrSubscriptionID) ChangedSubscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EOC_ChangeType changeType, BSTR bstrEventClassID) ChangedEventClass;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, EOC_ChangeType changeType, BSTR bstrPublisherID) ChangedPublisher;
	}


	public HRESULT ChangedSubscription(EOC_ChangeType changeType, BSTR bstrSubscriptionID) mut => VT.[Friend]ChangedSubscription(&this, changeType, bstrSubscriptionID);

	public HRESULT ChangedEventClass(EOC_ChangeType changeType, BSTR bstrEventClassID) mut => VT.[Friend]ChangedEventClass(&this, changeType, bstrEventClassID);

	public HRESULT ChangedPublisher(EOC_ChangeType changeType, BSTR bstrPublisherID) mut => VT.[Friend]ChangedPublisher(&this, changeType, bstrPublisherID);
}

[CRepr]struct IEventObjectChange2 : IUnknown
{
	public new const Guid IID = .(0x7701a9c3, 0xbd68, 0x438f, 0x83, 0xe0, 0x67, 0xbf, 0x4f, 0x53, 0xa4, 0x22);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMEVENTSYSCHANGEINFO* pInfo) ChangedSubscription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, COMEVENTSYSCHANGEINFO* pInfo) ChangedEventClass;
	}


	public HRESULT ChangedSubscription(COMEVENTSYSCHANGEINFO* pInfo) mut => VT.[Friend]ChangedSubscription(&this, pInfo);

	public HRESULT ChangedEventClass(COMEVENTSYSCHANGEINFO* pInfo) mut => VT.[Friend]ChangedEventClass(&this, pInfo);
}

[CRepr]struct IEnumEventObject : IUnknown
{
	public new const Guid IID = .(0xf4a07d63, 0x2e25, 0x11d1, 0x99, 0x64, 0x00, 0xc0, 0x4f, 0xbb, 0xb3, 0x45);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumEventObject** ppInterface) Clone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cReqElem, IUnknown** ppInterface, uint32* cRetElem) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 cSkipElem) Skip;
	}


	public HRESULT Clone(IEnumEventObject** ppInterface) mut => VT.[Friend]Clone(&this, ppInterface);

	public HRESULT Next(uint32 cReqElem, IUnknown** ppInterface, uint32* cRetElem) mut => VT.[Friend]Next(&this, cReqElem, ppInterface, cRetElem);

	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Skip(uint32 cSkipElem) mut => VT.[Friend]Skip(&this, cSkipElem);
}

[CRepr]struct IEventObjectCollection : IDispatch
{
	public new const Guid IID = .(0xf89ac270, 0xd4eb, 0x11d1, 0xb6, 0x82, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IUnknown** ppUnkEnum) get__NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR objectID, VARIANT* pItem) get_Item;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumEventObject** ppEnum) get_NewEnum;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* item, BSTR objectID) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR objectID) Remove;
	}


	public HRESULT get__NewEnum(IUnknown** ppUnkEnum) mut => VT.[Friend]get__NewEnum(&this, ppUnkEnum);

	public HRESULT get_Item(BSTR objectID, VARIANT* pItem) mut => VT.[Friend]get_Item(&this, objectID, pItem);

	public HRESULT get_NewEnum(IEnumEventObject** ppEnum) mut => VT.[Friend]get_NewEnum(&this, ppEnum);

	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT Add(VARIANT* item, BSTR objectID) mut => VT.[Friend]Add(&this, item, objectID);

	public HRESULT Remove(BSTR objectID) mut => VT.[Friend]Remove(&this, objectID);
}

[CRepr]struct IEventProperty : IDispatch
{
	public new const Guid IID = .(0xda538ee2, 0xf4de, 0x11d1, 0xb6, 0xbb, 0x00, 0x80, 0x5f, 0xc7, 0x92, 0x16);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* propertyName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR propertyName) put_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* propertyValue) get_Value;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, VARIANT* propertyValue) put_Value;
	}


	public HRESULT get_Name(BSTR* propertyName) mut => VT.[Friend]get_Name(&this, propertyName);

	public HRESULT put_Name(BSTR propertyName) mut => VT.[Friend]put_Name(&this, propertyName);

	public HRESULT get_Value(VARIANT* propertyValue) mut => VT.[Friend]get_Value(&this, propertyValue);

	public HRESULT put_Value(VARIANT* propertyValue) mut => VT.[Friend]put_Value(&this, propertyValue);
}

[CRepr]struct IEventControl : IDispatch
{
	public new const Guid IID = .(0x0343e2f4, 0x86f6, 0x11d1, 0xb7, 0x60, 0x00, 0xc0, 0x4f, 0xb9, 0x26, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR methodName, IPublisherFilter* pPublisherFilter) SetPublisherFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAllowInprocActivation) get_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fAllowInprocActivation) put_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR methodName, BSTR optionalCriteria, int32* optionalErrorIndex, IEventObjectCollection** ppCollection) GetSubscriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR methodName, BSTR criteria, int32* errorIndex) SetDefaultQuery;
	}


	public HRESULT SetPublisherFilter(BSTR methodName, IPublisherFilter* pPublisherFilter) mut => VT.[Friend]SetPublisherFilter(&this, methodName, pPublisherFilter);

	public HRESULT get_AllowInprocActivation(BOOL* pfAllowInprocActivation) mut => VT.[Friend]get_AllowInprocActivation(&this, pfAllowInprocActivation);

	public HRESULT put_AllowInprocActivation(BOOL fAllowInprocActivation) mut => VT.[Friend]put_AllowInprocActivation(&this, fAllowInprocActivation);

	public HRESULT GetSubscriptions(BSTR methodName, BSTR optionalCriteria, int32* optionalErrorIndex, IEventObjectCollection** ppCollection) mut => VT.[Friend]GetSubscriptions(&this, methodName, optionalCriteria, optionalErrorIndex, ppCollection);

	public HRESULT SetDefaultQuery(BSTR methodName, BSTR criteria, int32* errorIndex) mut => VT.[Friend]SetDefaultQuery(&this, methodName, criteria, errorIndex);
}

[CRepr]struct IMultiInterfaceEventControl : IUnknown
{
	public new const Guid IID = .(0x0343e2f5, 0x86f6, 0x11d1, 0xb7, 0x60, 0x00, 0xc0, 0x4f, 0xb9, 0x26, 0xaf);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMultiInterfacePublisherFilter* classFilter) SetMultiInterfacePublisherFilter;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid eventIID, BSTR bstrMethodName, BSTR optionalCriteria, int32* optionalErrorIndex, IEventObjectCollection** ppCollection) GetSubscriptions;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid eventIID, BSTR bstrMethodName, BSTR bstrCriteria, int32* errorIndex) SetDefaultQuery;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfAllowInprocActivation) get_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fAllowInprocActivation) put_AllowInprocActivation;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfFireInParallel) get_FireInParallel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fFireInParallel) put_FireInParallel;
	}


	public HRESULT SetMultiInterfacePublisherFilter(IMultiInterfacePublisherFilter* classFilter) mut => VT.[Friend]SetMultiInterfacePublisherFilter(&this, classFilter);

	public HRESULT GetSubscriptions(in Guid eventIID, BSTR bstrMethodName, BSTR optionalCriteria, int32* optionalErrorIndex, IEventObjectCollection** ppCollection) mut => VT.[Friend]GetSubscriptions(&this, eventIID, bstrMethodName, optionalCriteria, optionalErrorIndex, ppCollection);

	public HRESULT SetDefaultQuery(in Guid eventIID, BSTR bstrMethodName, BSTR bstrCriteria, int32* errorIndex) mut => VT.[Friend]SetDefaultQuery(&this, eventIID, bstrMethodName, bstrCriteria, errorIndex);

	public HRESULT get_AllowInprocActivation(BOOL* pfAllowInprocActivation) mut => VT.[Friend]get_AllowInprocActivation(&this, pfAllowInprocActivation);

	public HRESULT put_AllowInprocActivation(BOOL fAllowInprocActivation) mut => VT.[Friend]put_AllowInprocActivation(&this, fAllowInprocActivation);

	public HRESULT get_FireInParallel(BOOL* pfFireInParallel) mut => VT.[Friend]get_FireInParallel(&this, pfFireInParallel);

	public HRESULT put_FireInParallel(BOOL fFireInParallel) mut => VT.[Friend]put_FireInParallel(&this, fFireInParallel);
}

[CRepr]struct IDontSupportEventSubscription : IUnknown
{
	public new const Guid IID = .(0x784121f1, 0x62a6, 0x4b89, 0x85, 0x5f, 0xd6, 0x5f, 0x29, 0x6d, 0xe8, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
	}

}

#endregion
