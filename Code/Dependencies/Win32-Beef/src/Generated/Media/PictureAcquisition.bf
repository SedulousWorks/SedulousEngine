using Win32.UI.Shell.PropertiesSystem;
using Win32.Foundation;
using Win32.System.Com;
using Win32.Graphics.Gdi;
using Win32.System.Com.StructuredStorage;
using Win32.UI.WindowsAndMessaging;
using System;

namespace Win32.Media.PictureAcquisition;

#region Constants
public static
{
	public const PROPERTYKEY PKEY_PhotoAcquire_RelativePathname = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 2);
	public const PROPERTYKEY PKEY_PhotoAcquire_FinalFilename = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 3);
	public const PROPERTYKEY PKEY_PhotoAcquire_GroupTag = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 4);
	public const PROPERTYKEY PKEY_PhotoAcquire_TransferResult = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 5);
	public const PROPERTYKEY PKEY_PhotoAcquire_OriginalFilename = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 6);
	public const PROPERTYKEY PKEY_PhotoAcquire_CameraSequenceNumber = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 7);
	public const PROPERTYKEY PKEY_PhotoAcquire_IntermediateFile = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 8);
	public const PROPERTYKEY PKEY_PhotoAcquire_SkipImport = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 9);
	public const PROPERTYKEY PKEY_PhotoAcquire_DuplicateDetectionID = .(.(0x00f23377, 0x7ac6, 0x4b7a, 0x84, 0x43, 0x34, 0x5e, 0x73, 0x1f, 0xa5, 0x7a), 10);
	public const int32 PROGRESS_INDETERMINATE = -1;
	public const HRESULT PHOTOACQ_ERROR_RESTART_REQUIRED = -2147180543;
	public const uint32 PHOTOACQ_RUN_DEFAULT = 0;
	public const uint32 PHOTOACQ_NO_GALLERY_LAUNCH = 1;
	public const uint32 PHOTOACQ_DISABLE_AUTO_ROTATE = 2;
	public const uint32 PHOTOACQ_DISABLE_PLUGINS = 4;
	public const uint32 PHOTOACQ_DISABLE_GROUP_TAG_PROMPT = 8;
	public const uint32 PHOTOACQ_DISABLE_DB_INTEGRATION = 16;
	public const uint32 PHOTOACQ_DELETE_AFTER_ACQUIRE = 32;
	public const uint32 PHOTOACQ_DISABLE_DUPLICATE_DETECTION = 64;
	public const uint32 PHOTOACQ_ENABLE_THUMBNAIL_CACHING = 128;
	public const uint32 PHOTOACQ_DISABLE_METADATA_WRITE = 256;
	public const uint32 PHOTOACQ_DISABLE_THUMBNAIL_PROGRESS = 512;
	public const uint32 PHOTOACQ_DISABLE_SETTINGS_LINK = 1024;
	public const uint32 PHOTOACQ_ABORT_ON_SETTINGS_UPDATE = 2048;
	public const uint32 PHOTOACQ_IMPORT_VIDEO_AS_MULTIPLE_FILES = 4096;
	public const uint32 DSF_WPD_DEVICES = 1;
	public const uint32 DSF_WIA_CAMERAS = 2;
	public const uint32 DSF_WIA_SCANNERS = 4;
	public const uint32 DSF_STI_DEVICES = 8;
	public const uint32 DSF_TWAIN_DEVICES = 16;
	public const uint32 DSF_FS_DEVICES = 32;
	public const uint32 DSF_DV_DEVICES = 64;
	public const uint32 DSF_ALL_DEVICES = 65535;
	public const uint32 DSF_CPL_MODE = 65536;
	public const uint32 DSF_SHOW_OFFLINE = 131072;
	public const uint32 PAPS_PRESAVE = 0;
	public const uint32 PAPS_POSTSAVE = 1;
	public const uint32 PAPS_CLEANUP = 2;
}
#endregion

#region Enums

[AllowDuplicates]
public enum USER_INPUT_STRING_TYPE : int32
{
	USER_INPUT_DEFAULT = 0,
	USER_INPUT_PATH_ELEMENT = 1,
}


[AllowDuplicates]
public enum ERROR_ADVISE_MESSAGE_TYPE : int32
{
	PHOTOACQUIRE_ERROR_SKIPRETRYCANCEL = 0,
	PHOTOACQUIRE_ERROR_RETRYCANCEL = 1,
	PHOTOACQUIRE_ERROR_YESNO = 2,
	PHOTOACQUIRE_ERROR_OK = 3,
}


[AllowDuplicates]
public enum ERROR_ADVISE_RESULT : int32
{
	PHOTOACQUIRE_RESULT_YES = 0,
	PHOTOACQUIRE_RESULT_NO = 1,
	PHOTOACQUIRE_RESULT_OK = 2,
	PHOTOACQUIRE_RESULT_SKIP = 3,
	PHOTOACQUIRE_RESULT_SKIP_ALL = 4,
	PHOTOACQUIRE_RESULT_RETRY = 5,
	PHOTOACQUIRE_RESULT_ABORT = 6,
}


[AllowDuplicates]
public enum PROGRESS_DIALOG_IMAGE_TYPE : int32
{
	PROGRESS_DIALOG_ICON_SMALL = 0,
	PROGRESS_DIALOG_ICON_LARGE = 1,
	PROGRESS_DIALOG_ICON_THUMBNAIL = 2,
	PROGRESS_DIALOG_BITMAP_THUMBNAIL = 3,
}


[AllowDuplicates]
public enum PROGRESS_DIALOG_CHECKBOX_ID : int32
{
	PROGRESS_DIALOG_CHECKBOX_ID_DEFAULT = 0,
}


[AllowDuplicates]
public enum DEVICE_SELECTION_DEVICE_TYPE : int32
{
	DST_UNKNOWN_DEVICE = 0,
	DST_WPD_DEVICE = 1,
	DST_WIA_DEVICE = 2,
	DST_STI_DEVICE = 3,
	DSF_TWAIN_DEVICE = 4,
	DST_FS_DEVICE = 5,
	DST_DV_DEVICE = 6,
}

#endregion


#region COM Class IDs
public static
{
	public const Guid CLSID_PhotoAcquire = .(0x00f26e02, 0xe9f2, 0x4a9f, 0x9f, 0xdd, 0x5a, 0x96, 0x2f, 0xb2, 0x6a, 0x98);


	public const Guid CLSID_PhotoAcquireAutoPlayDropTarget = .(0x00f20eb5, 0x8fd6, 0x4d9d, 0xb7, 0x5e, 0x36, 0x80, 0x17, 0x66, 0xc8, 0xf1);


	public const Guid CLSID_PhotoAcquireAutoPlayHWEventHandler = .(0x00f2b433, 0x44e4, 0x4d88, 0xb2, 0xb0, 0x26, 0x98, 0xa0, 0xa9, 0x1d, 0xba);


	public const Guid CLSID_PhotoAcquireOptionsDialog = .(0x00f210a1, 0x62f0, 0x438b, 0x9f, 0x7e, 0x96, 0x18, 0xd7, 0x2a, 0x18, 0x31);


	public const Guid CLSID_PhotoProgressDialog = .(0x00f24ca0, 0x748f, 0x4e8a, 0x89, 0x4f, 0x0e, 0x03, 0x57, 0xc6, 0x79, 0x9f);


	public const Guid CLSID_PhotoAcquireDeviceSelectionDialog = .(0x00f29a34, 0xb8a1, 0x482c, 0xbc, 0xf8, 0x3a, 0xc7, 0xb0, 0xfe, 0x8f, 0x62);


}
#endregion

#region COM Types
[CRepr]struct IPhotoAcquireItem : IUnknown
{
	public new const Guid IID = .(0x00f21c97, 0x28bf, 0x4c02, 0xb8, 0x42, 0x5e, 0x4e, 0x90, 0x13, 0x9a, 0x30);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrItemName) GetItemName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, SIZE sizeThumbnail, HBITMAP* phbmpThumbnail) GetThumbnail;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* pv) GetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROPERTYKEY* key, PROPVARIANT* pv) SetProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IStream** ppStream) GetStream;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCanDelete) CanDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnCount) GetSubItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItemIndex, IPhotoAcquireItem** ppPhotoAcquireItem) GetSubItemAt;
	}


	public HRESULT GetItemName(BSTR* pbstrItemName) mut => VT.[Friend]GetItemName(&this, pbstrItemName);

	public HRESULT GetThumbnail(SIZE sizeThumbnail, HBITMAP* phbmpThumbnail) mut => VT.[Friend]GetThumbnail(&this, sizeThumbnail, phbmpThumbnail);

	public HRESULT GetProperty(PROPERTYKEY* key, PROPVARIANT* pv) mut => VT.[Friend]GetProperty(&this, key, pv);

	public HRESULT SetProperty(PROPERTYKEY* key, PROPVARIANT* pv) mut => VT.[Friend]SetProperty(&this, key, pv);

	public HRESULT GetStream(IStream** ppStream) mut => VT.[Friend]GetStream(&this, ppStream);

	public HRESULT CanDelete(BOOL* pfCanDelete) mut => VT.[Friend]CanDelete(&this, pfCanDelete);

	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT GetSubItemCount(uint32* pnCount) mut => VT.[Friend]GetSubItemCount(&this, pnCount);

	public HRESULT GetSubItemAt(uint32 nItemIndex, IPhotoAcquireItem** ppPhotoAcquireItem) mut => VT.[Friend]GetSubItemAt(&this, nItemIndex, ppPhotoAcquireItem);
}

[CRepr]struct IUserInputString : IUnknown
{
	public new const Guid IID = .(0x00f243a1, 0x205b, 0x45ba, 0xae, 0x26, 0xab, 0xbc, 0x53, 0xaa, 0x7a, 0x6f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrSubmitButtonText) GetSubmitButtonText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrPromptTitle) GetPrompt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrStringId) GetStringId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, USER_INPUT_STRING_TYPE* pnStringType) GetStringType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTooltipText) GetTooltipText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pcchMaxLength) GetMaxLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDefault) GetDefault;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnMruCount) GetMruCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, BSTR* pbstrMruEntry) GetMruEntryAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nSize, HBITMAP* phBitmap, HICON* phIcon) GetImage;
	}


	public HRESULT GetSubmitButtonText(BSTR* pbstrSubmitButtonText) mut => VT.[Friend]GetSubmitButtonText(&this, pbstrSubmitButtonText);

	public HRESULT GetPrompt(BSTR* pbstrPromptTitle) mut => VT.[Friend]GetPrompt(&this, pbstrPromptTitle);

	public HRESULT GetStringId(BSTR* pbstrStringId) mut => VT.[Friend]GetStringId(&this, pbstrStringId);

	public HRESULT GetStringType(USER_INPUT_STRING_TYPE* pnStringType) mut => VT.[Friend]GetStringType(&this, pnStringType);

	public HRESULT GetTooltipText(BSTR* pbstrTooltipText) mut => VT.[Friend]GetTooltipText(&this, pbstrTooltipText);

	public HRESULT GetMaxLength(uint32* pcchMaxLength) mut => VT.[Friend]GetMaxLength(&this, pcchMaxLength);

	public HRESULT GetDefault(BSTR* pbstrDefault) mut => VT.[Friend]GetDefault(&this, pbstrDefault);

	public HRESULT GetMruCount(uint32* pnMruCount) mut => VT.[Friend]GetMruCount(&this, pnMruCount);

	public HRESULT GetMruEntryAt(uint32 nIndex, BSTR* pbstrMruEntry) mut => VT.[Friend]GetMruEntryAt(&this, nIndex, pbstrMruEntry);

	public HRESULT GetImage(uint32 nSize, HBITMAP* phBitmap, HICON* phIcon) mut => VT.[Friend]GetImage(&this, nSize, phBitmap, phIcon);
}

[CRepr]struct IPhotoAcquireProgressCB : IUnknown
{
	public new const Guid IID = .(0x00f2ce1e, 0x935e, 0x4248, 0x89, 0x2c, 0x13, 0x0f, 0x32, 0xc4, 0x5c, 0xb4);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCancelled) Cancelled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSource* pPhotoAcquireSource) StartEnumeration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireItem* pPhotoAcquireItem) FoundItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) EndEnumeration;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSource* pPhotoAcquireSource) StartTransfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem) StartItemTransfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDirectory) DirectoryCreated;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fOverall, uint32 nPercent) UpdateTransferPercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem, HRESULT hr) EndItemTransfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) EndTransfer;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSource* pPhotoAcquireSource) StartDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem) StartItemDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nPercent) UpdateDeletePercent;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem, HRESULT hr) EndItemDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) EndDelete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) EndSession;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfDeleteAfterAcquire) GetDeleteAfterAcquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr, PWSTR pszErrorMessage, ERROR_ADVISE_MESSAGE_TYPE nMessageType, ERROR_ADVISE_RESULT* pnErrorAdviseResult) ErrorAdvise;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riidType, IUnknown* pUnknown, PROPVARIANT* pPropVarResult, PROPVARIANT* pPropVarDefault) GetUserInput;
	}


	public HRESULT Cancelled(BOOL* pfCancelled) mut => VT.[Friend]Cancelled(&this, pfCancelled);

	public HRESULT StartEnumeration(IPhotoAcquireSource* pPhotoAcquireSource) mut => VT.[Friend]StartEnumeration(&this, pPhotoAcquireSource);

	public HRESULT FoundItem(IPhotoAcquireItem* pPhotoAcquireItem) mut => VT.[Friend]FoundItem(&this, pPhotoAcquireItem);

	public HRESULT EndEnumeration(HRESULT hr) mut => VT.[Friend]EndEnumeration(&this, hr);

	public HRESULT StartTransfer(IPhotoAcquireSource* pPhotoAcquireSource) mut => VT.[Friend]StartTransfer(&this, pPhotoAcquireSource);

	public HRESULT StartItemTransfer(uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem) mut => VT.[Friend]StartItemTransfer(&this, nItemIndex, pPhotoAcquireItem);

	public HRESULT DirectoryCreated(PWSTR pszDirectory) mut => VT.[Friend]DirectoryCreated(&this, pszDirectory);

	public HRESULT UpdateTransferPercent(BOOL fOverall, uint32 nPercent) mut => VT.[Friend]UpdateTransferPercent(&this, fOverall, nPercent);

	public HRESULT EndItemTransfer(uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem, HRESULT hr) mut => VT.[Friend]EndItemTransfer(&this, nItemIndex, pPhotoAcquireItem, hr);

	public HRESULT EndTransfer(HRESULT hr) mut => VT.[Friend]EndTransfer(&this, hr);

	public HRESULT StartDelete(IPhotoAcquireSource* pPhotoAcquireSource) mut => VT.[Friend]StartDelete(&this, pPhotoAcquireSource);

	public HRESULT StartItemDelete(uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem) mut => VT.[Friend]StartItemDelete(&this, nItemIndex, pPhotoAcquireItem);

	public HRESULT UpdateDeletePercent(uint32 nPercent) mut => VT.[Friend]UpdateDeletePercent(&this, nPercent);

	public HRESULT EndItemDelete(uint32 nItemIndex, IPhotoAcquireItem* pPhotoAcquireItem, HRESULT hr) mut => VT.[Friend]EndItemDelete(&this, nItemIndex, pPhotoAcquireItem, hr);

	public HRESULT EndDelete(HRESULT hr) mut => VT.[Friend]EndDelete(&this, hr);

	public HRESULT EndSession(HRESULT hr) mut => VT.[Friend]EndSession(&this, hr);

	public HRESULT GetDeleteAfterAcquire(BOOL* pfDeleteAfterAcquire) mut => VT.[Friend]GetDeleteAfterAcquire(&this, pfDeleteAfterAcquire);

	public HRESULT ErrorAdvise(HRESULT hr, PWSTR pszErrorMessage, ERROR_ADVISE_MESSAGE_TYPE nMessageType, ERROR_ADVISE_RESULT* pnErrorAdviseResult) mut => VT.[Friend]ErrorAdvise(&this, hr, pszErrorMessage, nMessageType, pnErrorAdviseResult);

	public HRESULT GetUserInput(in Guid riidType, IUnknown* pUnknown, PROPVARIANT* pPropVarResult, PROPVARIANT* pPropVarDefault) mut => VT.[Friend]GetUserInput(&this, riidType, pUnknown, pPropVarResult, pPropVarDefault);
}

[CRepr]struct IPhotoProgressActionCB : IUnknown
{
	public new const Guid IID = .(0x00f242d0, 0xb206, 0x4e7d, 0xb4, 0xc1, 0x47, 0x55, 0xbc, 0xbb, 0x9c, 0x9f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent) DoAction;
	}


	public HRESULT DoAction(HWND hWndParent) mut => VT.[Friend]DoAction(&this, hWndParent);
}

[CRepr]struct IPhotoProgressDialog : IUnknown
{
	public new const Guid IID = .(0x00f246f9, 0x0750, 0x4f08, 0x93, 0x81, 0x2c, 0xd8, 0xe9, 0x06, 0xa4, 0xae);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hwndParent) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND* phwndProgressDialog) GetWindow;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL fShow) ShowCheckbox;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, PWSTR pszCheckboxText) SetCheckboxText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL fChecked) SetCheckboxCheck;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, PWSTR pszCheckboxTooltipText) SetCheckboxTooltip;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL* pfChecked) IsCheckboxChecked;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetCaption;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PROGRESS_DIALOG_IMAGE_TYPE nImageType, HICON hIcon, HBITMAP hBitmap) SetImage;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32 nPercent) SetPercentComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszProgressText) SetProgressText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoProgressActionCB* pPhotoProgressActionCB) SetActionLinkCallback;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszCaption) SetActionLinkText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fShow) ShowActionLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfCancelled) IsCancelled;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riidType, IUnknown* pUnknown, PROPVARIANT* pPropVarResult, PROPVARIANT* pPropVarDefault) GetUserInput;
	}


	public HRESULT Create(HWND hwndParent) mut => VT.[Friend]Create(&this, hwndParent);

	public HRESULT GetWindow(HWND* phwndProgressDialog) mut => VT.[Friend]GetWindow(&this, phwndProgressDialog);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT SetTitle(PWSTR pszTitle) mut => VT.[Friend]SetTitle(&this, pszTitle);

	public HRESULT ShowCheckbox(PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL fShow) mut => VT.[Friend]ShowCheckbox(&this, nCheckboxId, fShow);

	public HRESULT SetCheckboxText(PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, PWSTR pszCheckboxText) mut => VT.[Friend]SetCheckboxText(&this, nCheckboxId, pszCheckboxText);

	public HRESULT SetCheckboxCheck(PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL fChecked) mut => VT.[Friend]SetCheckboxCheck(&this, nCheckboxId, fChecked);

	public HRESULT SetCheckboxTooltip(PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, PWSTR pszCheckboxTooltipText) mut => VT.[Friend]SetCheckboxTooltip(&this, nCheckboxId, pszCheckboxTooltipText);

	public HRESULT IsCheckboxChecked(PROGRESS_DIALOG_CHECKBOX_ID nCheckboxId, BOOL* pfChecked) mut => VT.[Friend]IsCheckboxChecked(&this, nCheckboxId, pfChecked);

	public HRESULT SetCaption(PWSTR pszTitle) mut => VT.[Friend]SetCaption(&this, pszTitle);

	public HRESULT SetImage(PROGRESS_DIALOG_IMAGE_TYPE nImageType, HICON hIcon, HBITMAP hBitmap) mut => VT.[Friend]SetImage(&this, nImageType, hIcon, hBitmap);

	public HRESULT SetPercentComplete(int32 nPercent) mut => VT.[Friend]SetPercentComplete(&this, nPercent);

	public HRESULT SetProgressText(PWSTR pszProgressText) mut => VT.[Friend]SetProgressText(&this, pszProgressText);

	public HRESULT SetActionLinkCallback(IPhotoProgressActionCB* pPhotoProgressActionCB) mut => VT.[Friend]SetActionLinkCallback(&this, pPhotoProgressActionCB);

	public HRESULT SetActionLinkText(PWSTR pszCaption) mut => VT.[Friend]SetActionLinkText(&this, pszCaption);

	public HRESULT ShowActionLink(BOOL fShow) mut => VT.[Friend]ShowActionLink(&this, fShow);

	public HRESULT IsCancelled(BOOL* pfCancelled) mut => VT.[Friend]IsCancelled(&this, pfCancelled);

	public HRESULT GetUserInput(in Guid riidType, IUnknown* pUnknown, PROPVARIANT* pPropVarResult, PROPVARIANT* pPropVarDefault) mut => VT.[Friend]GetUserInput(&this, riidType, pUnknown, pPropVarResult, pPropVarDefault);
}

[CRepr]struct IPhotoAcquireSource : IUnknown
{
	public new const Guid IID = .(0x00f2c703, 0x8613, 0x4282, 0xa5, 0x3b, 0x6e, 0xc5, 0x9c, 0x58, 0x83, 0xac);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrFriendlyName) GetFriendlyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nSize, HICON* phLargeIcon, HICON* phSmallIcon) GetDeviceIcons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fForceEnumeration, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB, uint32* pnItemCount) InitializeItemList;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pnItemCount) GetItemCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 nIndex, IPhotoAcquireItem** ppPhotoAcquireItem) GetItemAt;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSettings** ppPhotoAcquireSettings) GetPhotoAcquireSettings;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrDeviceId) GetDeviceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid riid, void** ppv) BindToObject;
	}


	public HRESULT GetFriendlyName(BSTR* pbstrFriendlyName) mut => VT.[Friend]GetFriendlyName(&this, pbstrFriendlyName);

	public HRESULT GetDeviceIcons(uint32 nSize, HICON* phLargeIcon, HICON* phSmallIcon) mut => VT.[Friend]GetDeviceIcons(&this, nSize, phLargeIcon, phSmallIcon);

	public HRESULT InitializeItemList(BOOL fForceEnumeration, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB, uint32* pnItemCount) mut => VT.[Friend]InitializeItemList(&this, fForceEnumeration, pPhotoAcquireProgressCB, pnItemCount);

	public HRESULT GetItemCount(uint32* pnItemCount) mut => VT.[Friend]GetItemCount(&this, pnItemCount);

	public HRESULT GetItemAt(uint32 nIndex, IPhotoAcquireItem** ppPhotoAcquireItem) mut => VT.[Friend]GetItemAt(&this, nIndex, ppPhotoAcquireItem);

	public HRESULT GetPhotoAcquireSettings(IPhotoAcquireSettings** ppPhotoAcquireSettings) mut => VT.[Friend]GetPhotoAcquireSettings(&this, ppPhotoAcquireSettings);

	public HRESULT GetDeviceId(BSTR* pbstrDeviceId) mut => VT.[Friend]GetDeviceId(&this, pbstrDeviceId);

	public HRESULT BindToObject(in Guid riid, void** ppv) mut => VT.[Friend]BindToObject(&this, riid, ppv);
}

[CRepr]struct IPhotoAcquire : IUnknown
{
	public new const Guid IID = .(0x00f23353, 0xe31b, 0x4955, 0xa8, 0xad, 0xca, 0x5e, 0xbf, 0x31, 0xe2, 0xce);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszDevice, IPhotoAcquireSource** ppPhotoAcquireSource) CreatePhotoSource;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSource* pPhotoAcquireSource, BOOL fShowProgress, HWND hWndParent, PWSTR pszApplicationName, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB) Acquire;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IEnumString** ppEnumFilePaths) EnumResults;
	}


	public HRESULT CreatePhotoSource(PWSTR pszDevice, IPhotoAcquireSource** ppPhotoAcquireSource) mut => VT.[Friend]CreatePhotoSource(&this, pszDevice, ppPhotoAcquireSource);

	public HRESULT Acquire(IPhotoAcquireSource* pPhotoAcquireSource, BOOL fShowProgress, HWND hWndParent, PWSTR pszApplicationName, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB) mut => VT.[Friend]Acquire(&this, pPhotoAcquireSource, fShowProgress, hWndParent, pszApplicationName, pPhotoAcquireProgressCB);

	public HRESULT EnumResults(IEnumString** ppEnumFilePaths) mut => VT.[Friend]EnumResults(&this, ppEnumFilePaths);
}

[CRepr]struct IPhotoAcquireSettings : IUnknown
{
	public new const Guid IID = .(0x00f2b868, 0xdd67, 0x487c, 0x95, 0x53, 0x04, 0x92, 0x40, 0x76, 0x7e, 0x91);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRegistryKey) InitializeFromRegistry;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwPhotoAcquireFlags) SetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTemplate) SetOutputFilenameTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwWidth) SetSequencePaddingWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL fZeroPad) SetSequenceZeroPadding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszGroupTag) SetGroupTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftAcquisitionTime) SetAcquisitionTime;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwPhotoAcquireFlags) COM_GetFlags;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrTemplate) GetOutputFilenameTemplate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwWidth) GetSequencePaddingWidth;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pfZeroPad) GetSequenceZeroPadding;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BSTR* pbstrGroupTag) GetGroupTag;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftAcquisitionTime) GetAcquisitionTime;
	}


	public HRESULT InitializeFromRegistry(PWSTR pszRegistryKey) mut => VT.[Friend]InitializeFromRegistry(&this, pszRegistryKey);

	public HRESULT SetFlags(uint32 dwPhotoAcquireFlags) mut => VT.[Friend]SetFlags(&this, dwPhotoAcquireFlags);

	public HRESULT SetOutputFilenameTemplate(PWSTR pszTemplate) mut => VT.[Friend]SetOutputFilenameTemplate(&this, pszTemplate);

	public HRESULT SetSequencePaddingWidth(uint32 dwWidth) mut => VT.[Friend]SetSequencePaddingWidth(&this, dwWidth);

	public HRESULT SetSequenceZeroPadding(BOOL fZeroPad) mut => VT.[Friend]SetSequenceZeroPadding(&this, fZeroPad);

	public HRESULT SetGroupTag(PWSTR pszGroupTag) mut => VT.[Friend]SetGroupTag(&this, pszGroupTag);

	public HRESULT SetAcquisitionTime(FILETIME* pftAcquisitionTime) mut => VT.[Friend]SetAcquisitionTime(&this, pftAcquisitionTime);

	public HRESULT GetFlags(uint32* pdwPhotoAcquireFlags) mut => VT.[Friend]COM_GetFlags(&this, pdwPhotoAcquireFlags);

	public HRESULT GetOutputFilenameTemplate(BSTR* pbstrTemplate) mut => VT.[Friend]GetOutputFilenameTemplate(&this, pbstrTemplate);

	public HRESULT GetSequencePaddingWidth(uint32* pdwWidth) mut => VT.[Friend]GetSequencePaddingWidth(&this, pdwWidth);

	public HRESULT GetSequenceZeroPadding(BOOL* pfZeroPad) mut => VT.[Friend]GetSequenceZeroPadding(&this, pfZeroPad);

	public HRESULT GetGroupTag(BSTR* pbstrGroupTag) mut => VT.[Friend]GetGroupTag(&this, pbstrGroupTag);

	public HRESULT GetAcquisitionTime(FILETIME* pftAcquisitionTime) mut => VT.[Friend]GetAcquisitionTime(&this, pftAcquisitionTime);
}

[CRepr]struct IPhotoAcquireOptionsDialog : IUnknown
{
	public new const Guid IID = .(0x00f2b3ee, 0xbf64, 0x47ee, 0x89, 0xf4, 0x4d, 0xed, 0xd7, 0x96, 0x43, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszRegistryRoot) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, HWND* phWndDialog) Create;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Destroy;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, int* ppnReturnCode) DoModal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) SaveData;
	}


	public HRESULT Initialize(PWSTR pszRegistryRoot) mut => VT.[Friend]Initialize(&this, pszRegistryRoot);

	public HRESULT Create(HWND hWndParent, HWND* phWndDialog) mut => VT.[Friend]Create(&this, hWndParent, phWndDialog);

	public HRESULT Destroy() mut => VT.[Friend]Destroy(&this);

	public HRESULT DoModal(HWND hWndParent, int* ppnReturnCode) mut => VT.[Friend]DoModal(&this, hWndParent, ppnReturnCode);

	public HRESULT SaveData() mut => VT.[Friend]SaveData(&this);
}

[CRepr]struct IPhotoAcquireDeviceSelectionDialog : IUnknown
{
	public new const Guid IID = .(0x00f28837, 0x55dd, 0x4f37, 0xaa, 0xf5, 0x68, 0x55, 0xa9, 0x64, 0x04, 0x67);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszTitle) SetTitle;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszSubmitButtonText) SetSubmitButtonText;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent, uint32 dwDeviceFlags, BSTR* pbstrDeviceId, DEVICE_SELECTION_DEVICE_TYPE* pnDeviceType) DoModal;
	}


	public HRESULT SetTitle(PWSTR pszTitle) mut => VT.[Friend]SetTitle(&this, pszTitle);

	public HRESULT SetSubmitButtonText(PWSTR pszSubmitButtonText) mut => VT.[Friend]SetSubmitButtonText(&this, pszSubmitButtonText);

	public HRESULT DoModal(HWND hWndParent, uint32 dwDeviceFlags, BSTR* pbstrDeviceId, DEVICE_SELECTION_DEVICE_TYPE* pnDeviceType) mut => VT.[Friend]DoModal(&this, hWndParent, dwDeviceFlags, pbstrDeviceId, pnDeviceType);
}

[CRepr]struct IPhotoAcquirePlugin : IUnknown
{
	public new const Guid IID = .(0x00f2dceb, 0xecb8, 0x4f77, 0x8e, 0x47, 0xe7, 0xa9, 0x87, 0xc8, 0x3d, 0xd0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IPhotoAcquireSource* pPhotoAcquireSource, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwAcquireStage, IPhotoAcquireItem* pPhotoAcquireItem, IStream* pOriginalItemStream, PWSTR pszFinalFilename, IPropertyStore* pPropertyStore) ProcessItem;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HRESULT hr) TransferComplete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, HWND hWndParent) DisplayConfigureDialog;
	}


	public HRESULT Initialize(IPhotoAcquireSource* pPhotoAcquireSource, IPhotoAcquireProgressCB* pPhotoAcquireProgressCB) mut => VT.[Friend]Initialize(&this, pPhotoAcquireSource, pPhotoAcquireProgressCB);

	public HRESULT ProcessItem(uint32 dwAcquireStage, IPhotoAcquireItem* pPhotoAcquireItem, IStream* pOriginalItemStream, PWSTR pszFinalFilename, IPropertyStore* pPropertyStore) mut => VT.[Friend]ProcessItem(&this, dwAcquireStage, pPhotoAcquireItem, pOriginalItemStream, pszFinalFilename, pPropertyStore);

	public HRESULT TransferComplete(HRESULT hr) mut => VT.[Friend]TransferComplete(&this, hr);

	public HRESULT DisplayConfigureDialog(HWND hWndParent) mut => VT.[Friend]DisplayConfigureDialog(&this, hWndParent);
}

#endregion
