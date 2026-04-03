using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.Com.ChannelCredentials;

#region COM Types
[CRepr]struct IChannelCredentials : IDispatch
{
	public new const Guid IID = .(0x181b448c, 0xc17c, 0x4b17, 0xac, 0x6d, 0x06, 0x69, 0x9b, 0x93, 0x19, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IDispatch.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR domain, BSTR username, BSTR password, int32 impersonationLevel, BOOL allowNtlm) SetWindowsCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR username, BSTR password) SetUserNameCredential;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR storeLocation, BSTR storeName, BSTR findYype, VARIANT findValue) SetClientCertificateFromStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR subjectName, BSTR storeLocation, BSTR storeName) SetClientCertificateFromStoreByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filename, BSTR password, BSTR keystorageFlags) SetClientCertificateFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR storeLocation, BSTR storeName, BSTR findType, VARIANT findValue) SetDefaultServiceCertificateFromStore;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR subjectName, BSTR storeLocation, BSTR storeName) SetDefaultServiceCertificateFromStoreByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR filename, BSTR password, BSTR keystorageFlags) SetDefaultServiceCertificateFromFile;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR storeLocation, BSTR revocationMode, BSTR certificateValidationMode) SetServiceCertificateAuthentication;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR localIssuerAddres, BSTR localIssuerBindingType, BSTR localIssuerBinding) SetIssuedToken;
	}


	public HRESULT SetWindowsCredential(BSTR domain, BSTR username, BSTR password, int32 impersonationLevel, BOOL allowNtlm) mut => VT.[Friend]SetWindowsCredential(&this, domain, username, password, impersonationLevel, allowNtlm);

	public HRESULT SetUserNameCredential(BSTR username, BSTR password) mut => VT.[Friend]SetUserNameCredential(&this, username, password);

	public HRESULT SetClientCertificateFromStore(BSTR storeLocation, BSTR storeName, BSTR findYype, VARIANT findValue) mut => VT.[Friend]SetClientCertificateFromStore(&this, storeLocation, storeName, findYype, findValue);

	public HRESULT SetClientCertificateFromStoreByName(BSTR subjectName, BSTR storeLocation, BSTR storeName) mut => VT.[Friend]SetClientCertificateFromStoreByName(&this, subjectName, storeLocation, storeName);

	public HRESULT SetClientCertificateFromFile(BSTR filename, BSTR password, BSTR keystorageFlags) mut => VT.[Friend]SetClientCertificateFromFile(&this, filename, password, keystorageFlags);

	public HRESULT SetDefaultServiceCertificateFromStore(BSTR storeLocation, BSTR storeName, BSTR findType, VARIANT findValue) mut => VT.[Friend]SetDefaultServiceCertificateFromStore(&this, storeLocation, storeName, findType, findValue);

	public HRESULT SetDefaultServiceCertificateFromStoreByName(BSTR subjectName, BSTR storeLocation, BSTR storeName) mut => VT.[Friend]SetDefaultServiceCertificateFromStoreByName(&this, subjectName, storeLocation, storeName);

	public HRESULT SetDefaultServiceCertificateFromFile(BSTR filename, BSTR password, BSTR keystorageFlags) mut => VT.[Friend]SetDefaultServiceCertificateFromFile(&this, filename, password, keystorageFlags);

	public HRESULT SetServiceCertificateAuthentication(BSTR storeLocation, BSTR revocationMode, BSTR certificateValidationMode) mut => VT.[Friend]SetServiceCertificateAuthentication(&this, storeLocation, revocationMode, certificateValidationMode);

	public HRESULT SetIssuedToken(BSTR localIssuerAddres, BSTR localIssuerBindingType, BSTR localIssuerBinding) mut => VT.[Friend]SetIssuedToken(&this, localIssuerAddres, localIssuerBindingType, localIssuerBinding);
}

#endregion
