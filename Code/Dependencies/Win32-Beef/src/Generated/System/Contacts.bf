using Win32.System.Com;
using Win32.Foundation;
using System;

namespace Win32.System.Contacts;

#region Constants
public static
{
	public const uint32 CGD_DEFAULT = 0;
	public const uint32 CGD_UNKNOWN_PROPERTY = 0;
	public const uint32 CGD_STRING_PROPERTY = 1;
	public const uint32 CGD_DATE_PROPERTY = 2;
	public const uint32 CGD_BINARY_PROPERTY = 4;
	public const uint32 CGD_ARRAY_NODE = 8;
	public const Guid CLSID_ContactAggregationManager = .(0x96c8ad95, 0xc199, 0x44de, 0xb3, 0x4e, 0xac, 0x33, 0xc4, 0x42, 0xdf, 0x39);
	public const String CONTACTPROP_PUB_NOTES = "Notes";
	public const String CONTACTPROP_PUB_MAILER = "Mailer";
	public const String CONTACTPROP_PUB_PROGID = "ProgID";
	public const String CONTACTPROP_PUB_GENDER = "Gender";
	public const String CONTACTPROP_PUB_GENDER_UNSPECIFIED = "Unspecified";
	public const String CONTACTPROP_PUB_GENDER_MALE = "Male";
	public const String CONTACTPROP_PUB_GENDER_FEMALE = "Female";
	public const String CONTACTPROP_PUB_CREATIONDATE = "CreationDate";
	public const String CONTACTPROP_PUB_L1_CONTACTIDCOLLECTION = "ContactIDCollection";
	public const String CONTACTPROP_PUB_L2_CONTACTID = "/ContactID";
	public const String CONTACTPROP_PUB_L3_VALUE = "/Value";
	public const String CONTACTPROP_PUB_L1_NAMECOLLECTION = "NameCollection";
	public const String CONTACTPROP_PUB_L2_NAME = "/Name";
	public const String CONTACTPROP_PUB_L3_FORMATTEDNAME = "/FormattedName";
	public const String CONTACTPROP_PUB_L3_PHONETIC = "/Phonetic";
	public const String CONTACTPROP_PUB_L3_PREFIX = "/Prefix";
	public const String CONTACTPROP_PUB_L3_TITLE = "/Title";
	public const String CONTACTPROP_PUB_L3_GIVENNAME = "/GivenName";
	public const String CONTACTPROP_PUB_L3_FAMILYNAME = "/FamilyName";
	public const String CONTACTPROP_PUB_L3_MIDDLENAME = "/MiddleName";
	public const String CONTACTPROP_PUB_L3_GENERATION = "/Generation";
	public const String CONTACTPROP_PUB_L3_SUFFIX = "/Suffix";
	public const String CONTACTPROP_PUB_L3_NICKNAME = "/NickName";
	public const String CONTACTPROP_PUB_L1_POSITIONCOLLECTION = "PositionCollection";
	public const String CONTACTPROP_PUB_L2_POSITION = "/Position";
	public const String CONTACTPROP_PUB_L3_ORGANIZATION = "/Organization";
	public const String CONTACTPROP_PUB_L3_COMPANY = "/Company";
	public const String CONTACTPROP_PUB_L3_DEPARTMENT = "/Department";
	public const String CONTACTPROP_PUB_L3_OFFICE = "/Office";
	public const String CONTACTPROP_PUB_L3_JOB_TITLE = "/JobTitle";
	public const String CONTACTPROP_PUB_L3_PROFESSION = "/Profession";
	public const String CONTACTPROP_PUB_L3_ROLE = "/Role";
	public const String CONTACTPROP_PUB_L1_PERSONCOLLECTION = "PersonCollection";
	public const String CONTACTPROP_PUB_L2_PERSON = "/Person";
	public const String CONTACTPROP_PUB_L3_PERSONID = "/PersonID";
	public const String CONTACTPROP_PUB_L1_DATECOLLECTION = "DateCollection";
	public const String CONTACTPROP_PUB_L2_DATE = "/Date";
	public const String CONTACTPROP_PUB_L1_EMAILADDRESSCOLLECTION = "EmailAddressCollection";
	public const String CONTACTPROP_PUB_L2_EMAILADDRESS = "/EmailAddress";
	public const String CONTACTPROP_PUB_L3_ADDRESS = "/Address";
	public const String CONTACTPROP_PUB_L3_TYPE = "/Type";
	public const String CONTACTPROP_PUB_L1_CERTIFICATECOLLECTION = "CertificateCollection";
	public const String CONTACTPROP_PUB_L2_CERTIFICATE = "/Certificate";
	public const String CONTACTPROP_PUB_L3_THUMBPRINT = "/ThumbPrint";
	public const String CONTACTPROP_PUB_L1_PHONENUMBERCOLLECTION = "PhoneNumberCollection";
	public const String CONTACTPROP_PUB_L2_PHONENUMBER = "/PhoneNumber";
	public const String CONTACTPROP_PUB_L3_NUMBER = "/Number";
	public const String CONTACTPROP_PUB_L3_ALTERNATE = "/Alternate";
	public const String CONTACTPROP_PUB_L1_PHYSICALADDRESSCOLLECTION = "PhysicalAddressCollection";
	public const String CONTACTPROP_PUB_L2_PHYSICALADDRESS = "/PhysicalAddress";
	public const String CONTACTPROP_PUB_L3_ADDRESSLABEL = "/AddressLabel";
	public const String CONTACTPROP_PUB_L3_STREET = "/Street";
	public const String CONTACTPROP_PUB_L3_LOCALITY = "/Locality";
	public const String CONTACTPROP_PUB_L3_REGION = "/Region";
	public const String CONTACTPROP_PUB_L3_POSTALCODE = "/PostalCode";
	public const String CONTACTPROP_PUB_L3_COUNTRY = "/Country";
	public const String CONTACTPROP_PUB_L3_POBOX = "/POBox";
	public const String CONTACTPROP_PUB_L3_EXTENDEDADDRESS = "/ExtendedAddress";
	public const String CONTACTPROP_PUB_L1_IMADDRESSCOLLECTION = "IMAddressCollection";
	public const String CONTACTPROP_PUB_L2_IMADDRESSENTRY = "/IMAddress";
	public const String CONTACTPROP_PUB_L3_PROTOCOL = "/Protocol";
	public const String CONTACTPROP_PUB_L1_URLCOLLECTION = "UrlCollection";
	public const String CONTACTPROP_PUB_L2_URL = "/Url";
	public const String CONTACTPROP_PUB_L1_PHOTOCOLLECTION = "PhotoCollection";
	public const String CONTACTPROP_PUB_L2_PHOTO = "/Photo";
	public const String CONTACTPROP_PUB_L3_URL = "/Url";
	public const String CONTACTLABEL_PUB_PREFERRED = "Preferred";
	public const String CONTACTLABEL_PUB_PERSONAL = "Personal";
	public const String CONTACTLABEL_PUB_BUSINESS = "Business";
	public const String CONTACTLABEL_PUB_OTHER = "Other";
	public const String CONTACTLABEL_PUB_VOICE = "Voice";
	public const String CONTACTLABEL_PUB_MOBILE = "Mobile";
	public const String CONTACTLABEL_PUB_PCS = "PCS";
	public const String CONTACTLABEL_PUB_CELLULAR = "Cellular";
	public const String CONTACTLABEL_PUB_CAR = "Car";
	public const String CONTACTLABEL_PUB_PAGER = "Pager";
	public const String CONTACTLABEL_PUB_TTY = "TTY";
	public const String CONTACTLABEL_PUB_FAX = "Fax";
	public const String CONTACTLABEL_PUB_VIDEO = "Video";
	public const String CONTACTLABEL_PUB_MODEM = "Modem";
	public const String CONTACTLABEL_PUB_BBS = "BBS";
	public const String CONTACTLABEL_PUB_ISDN = "ISDN";
	public const String CONTACTLABEL_PUB_AGENT = "Agent";
	public const String CONTACTLABEL_PUB_DOMESTIC = "Domestic";
	public const String CONTACTLABEL_PUB_INTERNATIONAL = "International";
	public const String CONTACTLABEL_PUB_POSTAL = "Postal";
	public const String CONTACTLABEL_PUB_PARCEL = "Parcel";
	public const String CONTACTLABEL_PUB_USERTILE = "UserTile";
	public const String CONTACTLABEL_PUB_LOGO = "Logo";
	public const String CONTACTLABEL_WAB_SPOUSE = "wab:Spouse";
	public const String CONTACTLABEL_WAB_CHILD = "wab:Child";
	public const String CONTACTLABEL_WAB_MANAGER = "wab:Manager";
	public const String CONTACTLABEL_WAB_ASSISTANT = "wab:Assistant";
	public const String CONTACTLABEL_WAB_BIRTHDAY = "wab:Birthday";
	public const String CONTACTLABEL_WAB_ANNIVERSARY = "wab:Anniversary";
	public const String CONTACTLABEL_WAB_SOCIALNETWORK = "wab:SocialNetwork";
	public const String CONTACTLABEL_WAB_SCHOOL = "wab:School";
	public const String CONTACTLABEL_WAB_WISHLIST = "wab:WishList";
}
#endregion

#region Enums

[AllowDuplicates]
public enum CONTACT_AGGREGATION_CREATE_OR_OPEN_OPTIONS : int32
{
	CA_CREATE_LOCAL = 0,
	CA_CREATE_EXTERNAL = 1,
}


[AllowDuplicates]
public enum CONTACT_AGGREGATION_COLLECTION_OPTIONS : int32
{
	CACO_DEFAULT = 0,
	CACO_INCLUDE_EXTERNAL = 1,
	CACO_EXTERNAL_ONLY = 2,
}

#endregion


#region Structs
[CRepr]
public struct CONTACT_AGGREGATION_BLOB
{
	public uint32 dwCount;
	public uint8* lpb;
}

#endregion

#region COM Class IDs
public static
{
	public const Guid CLSID_Contact = .(0x61b68808, 0x8eee, 0x4fd1, 0xac, 0xb8, 0x3d, 0x80, 0x4c, 0x8d, 0xb0, 0x56);


	public const Guid CLSID_ContactManager = .(0x7165c8ab, 0xaf88, 0x42bd, 0x86, 0xfd, 0x53, 0x10, 0xb4, 0x28, 0x5a, 0x02);


}
#endregion

#region COM Types
[CRepr]struct IContactManager : IUnknown
{
	public new const Guid IID = .(0xad553d98, 0xdeb1, 0x474a, 0x8e, 0x17, 0xfc, 0x0c, 0x20, 0x75, 0xb7, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszAppName, PWSTR pszAppVersion) Initialize;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszContactID, IContact** ppContact) Load;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszNewContactID, PWSTR pszOldContactID) MergeContactIDs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContact** ppMeContact) GetMeContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContact* pMeContact) SetMeContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactCollection** ppContactCollection) GetContactCollection;
	}


	public HRESULT Initialize(PWSTR pszAppName, PWSTR pszAppVersion) mut => VT.[Friend]Initialize(&this, pszAppName, pszAppVersion);

	public HRESULT Load(PWSTR pszContactID, IContact** ppContact) mut => VT.[Friend]Load(&this, pszContactID, ppContact);

	public HRESULT MergeContactIDs(PWSTR pszNewContactID, PWSTR pszOldContactID) mut => VT.[Friend]MergeContactIDs(&this, pszNewContactID, pszOldContactID);

	public HRESULT GetMeContact(IContact** ppMeContact) mut => VT.[Friend]GetMeContact(&this, ppMeContact);

	public HRESULT SetMeContact(IContact* pMeContact) mut => VT.[Friend]SetMeContact(&this, pMeContact);

	public HRESULT GetContactCollection(IContactCollection** ppContactCollection) mut => VT.[Friend]GetContactCollection(&this, ppContactCollection);
}

[CRepr]struct IContactCollection : IUnknown
{
	public new const Guid IID = .(0xb6afa338, 0xd779, 0x11d9, 0x8b, 0xde, 0xf6, 0x6b, 0xad, 0x1e, 0x3f, 0x3a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContact** ppContact) GetCurrent;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next() mut => VT.[Friend]Next(&this);

	public HRESULT GetCurrent(IContact** ppContact) mut => VT.[Friend]GetCurrent(&this, ppContact);
}

[CRepr]struct IContactProperties : IUnknown
{
	public new const Guid IID = .(0x70dd27dd, 0x5cbd, 0x46e8, 0xbe, 0xf0, 0x23, 0xb6, 0xb3, 0x46, 0x28, 0x8f);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, char16* pszValue, uint32 cchValue, uint32* pdwcchPropertyValueRequired) GetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, FILETIME* pftDateTime) GetDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, char16* pszContentType, uint32 cchContentType, uint32* pdwcchContentTypeRequired, IStream** ppStream) GetBinary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArrayElementName, uint32 dwFlags, char16* pszLabels, uint32 cchLabels, uint32* pdwcchLabelsRequired) GetLabels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, PWSTR pszValue) SetString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, FILETIME ftDateTime) SetDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags, PWSTR pszContentType, IStream* pStream) SetBinary;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArrayElementName, uint32 dwFlags, uint32 dwLabelCount, PWSTR* ppszLabels) SetLabels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArrayName, uint32 dwFlags, BOOL fAppend, char16* pszNewArrayElementName, uint32 cchNewArrayElementName, uint32* pdwcchNewArrayElementNameRequired) CreateArrayNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszPropertyName, uint32 dwFlags) DeleteProperty;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArrayElementName, uint32 dwFlags) DeleteArrayNode;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pszArrayElementName, uint32 dwFlags) DeleteLabels;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactPropertyCollection** ppPropertyCollection, uint32 dwFlags, PWSTR pszMultiValueName, uint32 dwLabelCount, PWSTR* ppszLabels, BOOL fAnyLabelMatches) GetPropertyCollection;
	}


	public HRESULT GetString(PWSTR pszPropertyName, uint32 dwFlags, char16* pszValue, uint32 cchValue, uint32* pdwcchPropertyValueRequired) mut => VT.[Friend]GetString(&this, pszPropertyName, dwFlags, pszValue, cchValue, pdwcchPropertyValueRequired);

	public HRESULT GetDate(PWSTR pszPropertyName, uint32 dwFlags, FILETIME* pftDateTime) mut => VT.[Friend]GetDate(&this, pszPropertyName, dwFlags, pftDateTime);

	public HRESULT GetBinary(PWSTR pszPropertyName, uint32 dwFlags, char16* pszContentType, uint32 cchContentType, uint32* pdwcchContentTypeRequired, IStream** ppStream) mut => VT.[Friend]GetBinary(&this, pszPropertyName, dwFlags, pszContentType, cchContentType, pdwcchContentTypeRequired, ppStream);

	public HRESULT GetLabels(PWSTR pszArrayElementName, uint32 dwFlags, char16* pszLabels, uint32 cchLabels, uint32* pdwcchLabelsRequired) mut => VT.[Friend]GetLabels(&this, pszArrayElementName, dwFlags, pszLabels, cchLabels, pdwcchLabelsRequired);

	public HRESULT SetString(PWSTR pszPropertyName, uint32 dwFlags, PWSTR pszValue) mut => VT.[Friend]SetString(&this, pszPropertyName, dwFlags, pszValue);

	public HRESULT SetDate(PWSTR pszPropertyName, uint32 dwFlags, FILETIME ftDateTime) mut => VT.[Friend]SetDate(&this, pszPropertyName, dwFlags, ftDateTime);

	public HRESULT SetBinary(PWSTR pszPropertyName, uint32 dwFlags, PWSTR pszContentType, IStream* pStream) mut => VT.[Friend]SetBinary(&this, pszPropertyName, dwFlags, pszContentType, pStream);

	public HRESULT SetLabels(PWSTR pszArrayElementName, uint32 dwFlags, uint32 dwLabelCount, PWSTR* ppszLabels) mut => VT.[Friend]SetLabels(&this, pszArrayElementName, dwFlags, dwLabelCount, ppszLabels);

	public HRESULT CreateArrayNode(PWSTR pszArrayName, uint32 dwFlags, BOOL fAppend, char16* pszNewArrayElementName, uint32 cchNewArrayElementName, uint32* pdwcchNewArrayElementNameRequired) mut => VT.[Friend]CreateArrayNode(&this, pszArrayName, dwFlags, fAppend, pszNewArrayElementName, cchNewArrayElementName, pdwcchNewArrayElementNameRequired);

	public HRESULT DeleteProperty(PWSTR pszPropertyName, uint32 dwFlags) mut => VT.[Friend]DeleteProperty(&this, pszPropertyName, dwFlags);

	public HRESULT DeleteArrayNode(PWSTR pszArrayElementName, uint32 dwFlags) mut => VT.[Friend]DeleteArrayNode(&this, pszArrayElementName, dwFlags);

	public HRESULT DeleteLabels(PWSTR pszArrayElementName, uint32 dwFlags) mut => VT.[Friend]DeleteLabels(&this, pszArrayElementName, dwFlags);

	public HRESULT GetPropertyCollection(IContactPropertyCollection** ppPropertyCollection, uint32 dwFlags, PWSTR pszMultiValueName, uint32 dwLabelCount, PWSTR* ppszLabels, BOOL fAnyLabelMatches) mut => VT.[Friend]GetPropertyCollection(&this, ppPropertyCollection, dwFlags, pszMultiValueName, dwLabelCount, ppszLabels, fAnyLabelMatches);
}

[CRepr]struct IContact : IUnknown
{
	public new const Guid IID = .(0xf941b671, 0xbda7, 0x4f77, 0x88, 0x4a, 0xf4, 0x64, 0x62, 0xf2, 0x26, 0xa7);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszContactID, uint32 cchContactID, uint32* pdwcchContactIDRequired) GetContactID;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszPath, uint32 cchPath, uint32* pdwcchPathRequired) GetPath;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dwCommitFlags) CommitChanges;
	}


	public HRESULT GetContactID(char16* pszContactID, uint32 cchContactID, uint32* pdwcchContactIDRequired) mut => VT.[Friend]GetContactID(&this, pszContactID, cchContactID, pdwcchContactIDRequired);

	public HRESULT GetPath(char16* pszPath, uint32 cchPath, uint32* pdwcchPathRequired) mut => VT.[Friend]GetPath(&this, pszPath, cchPath, pdwcchPathRequired);

	public HRESULT CommitChanges(uint32 dwCommitFlags) mut => VT.[Friend]CommitChanges(&this, dwCommitFlags);
}

[CRepr]struct IContactPropertyCollection : IUnknown
{
	public new const Guid IID = .(0xffd3adf8, 0xfa64, 0x4328, 0xb1, 0xb6, 0x2e, 0x0d, 0xb5, 0x09, 0xcb, 0x3c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Reset;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Next;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszPropertyName, uint32 cchPropertyName, uint32* pdwcchPropertyNameRequired) GetPropertyName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwType) GetPropertyType;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pdwVersion) GetPropertyVersion;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, FILETIME* pftModificationDate) GetPropertyModificationDate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, char16* pszArrayElementID, uint32 cchArrayElementID, uint32* pdwcchArrayElementIDRequired) GetPropertyArrayElementID;
	}


	public HRESULT Reset() mut => VT.[Friend]Reset(&this);

	public HRESULT Next() mut => VT.[Friend]Next(&this);

	public HRESULT GetPropertyName(char16* pszPropertyName, uint32 cchPropertyName, uint32* pdwcchPropertyNameRequired) mut => VT.[Friend]GetPropertyName(&this, pszPropertyName, cchPropertyName, pdwcchPropertyNameRequired);

	public HRESULT GetPropertyType(uint32* pdwType) mut => VT.[Friend]GetPropertyType(&this, pdwType);

	public HRESULT GetPropertyVersion(uint32* pdwVersion) mut => VT.[Friend]GetPropertyVersion(&this, pdwVersion);

	public HRESULT GetPropertyModificationDate(FILETIME* pftModificationDate) mut => VT.[Friend]GetPropertyModificationDate(&this, pftModificationDate);

	public HRESULT GetPropertyArrayElementID(char16* pszArrayElementID, uint32 cchArrayElementID, uint32* pdwcchArrayElementIDRequired) mut => VT.[Friend]GetPropertyArrayElementID(&this, pszArrayElementID, cchArrayElementID, pdwcchArrayElementIDRequired);
}

[CRepr]struct IContactAggregationManager : IUnknown
{
	public new const Guid IID = .(0x1d865989, 0x4b1f, 0x4b60, 0x8f, 0x34, 0xc2, 0xad, 0x46, 0x8b, 0x2b, 0x50);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* plMajorVersion, int32* plMinorVersion) GetVersionInfo;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pGroupName, CONTACT_AGGREGATION_CREATE_OR_OPEN_OPTIONS options, BOOL* pCreatedGroup, IContactAggregationGroup** ppGroup) CreateOrOpenGroup;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationContact** ppItem) CreateExternalContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationServerPerson** ppServerPerson) CreateServerPerson;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationLink** ppServerContactLink) CreateServerContactLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Flush;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pItemId, IContactAggregationAggregate** ppItem) OpenAggregateContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pItemId, IContactAggregationContact** ppItem) OpenContact;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pItemId, IContactAggregationLink** ppItem) OpenServerContactLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pItemId, IContactAggregationServerPerson** ppItem) OpenServerPerson;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationContactCollection** ppItems) get_Contacts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationAggregateCollection** ppAggregates) get_AggregateContacts;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationGroupCollection** ppGroups) get_Groups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationServerPersonCollection** ppServerPersonCollection) get_ServerPersons;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pPersonItemId, IContactAggregationLinkCollection** ppServerContactLinkCollection) get_ServerContactLinks;
	}


	public HRESULT GetVersionInfo(int32* plMajorVersion, int32* plMinorVersion) mut => VT.[Friend]GetVersionInfo(&this, plMajorVersion, plMinorVersion);

	public HRESULT CreateOrOpenGroup(PWSTR pGroupName, CONTACT_AGGREGATION_CREATE_OR_OPEN_OPTIONS options, BOOL* pCreatedGroup, IContactAggregationGroup** ppGroup) mut => VT.[Friend]CreateOrOpenGroup(&this, pGroupName, options, pCreatedGroup, ppGroup);

	public HRESULT CreateExternalContact(IContactAggregationContact** ppItem) mut => VT.[Friend]CreateExternalContact(&this, ppItem);

	public HRESULT CreateServerPerson(IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]CreateServerPerson(&this, ppServerPerson);

	public HRESULT CreateServerContactLink(IContactAggregationLink** ppServerContactLink) mut => VT.[Friend]CreateServerContactLink(&this, ppServerContactLink);

	public HRESULT Flush() mut => VT.[Friend]Flush(&this);

	public HRESULT OpenAggregateContact(PWSTR pItemId, IContactAggregationAggregate** ppItem) mut => VT.[Friend]OpenAggregateContact(&this, pItemId, ppItem);

	public HRESULT OpenContact(PWSTR pItemId, IContactAggregationContact** ppItem) mut => VT.[Friend]OpenContact(&this, pItemId, ppItem);

	public HRESULT OpenServerContactLink(PWSTR pItemId, IContactAggregationLink** ppItem) mut => VT.[Friend]OpenServerContactLink(&this, pItemId, ppItem);

	public HRESULT OpenServerPerson(PWSTR pItemId, IContactAggregationServerPerson** ppItem) mut => VT.[Friend]OpenServerPerson(&this, pItemId, ppItem);

	public HRESULT get_Contacts(CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationContactCollection** ppItems) mut => VT.[Friend]get_Contacts(&this, options, ppItems);

	public HRESULT get_AggregateContacts(CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationAggregateCollection** ppAggregates) mut => VT.[Friend]get_AggregateContacts(&this, options, ppAggregates);

	public HRESULT get_Groups(CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationGroupCollection** ppGroups) mut => VT.[Friend]get_Groups(&this, options, ppGroups);

	public HRESULT get_ServerPersons(IContactAggregationServerPersonCollection** ppServerPersonCollection) mut => VT.[Friend]get_ServerPersons(&this, ppServerPersonCollection);

	public HRESULT get_ServerContactLinks(PWSTR pPersonItemId, IContactAggregationLinkCollection** ppServerContactLinkCollection) mut => VT.[Friend]get_ServerContactLinks(&this, pPersonItemId, ppServerContactLinkCollection);
}

[CRepr]struct IContactAggregationContact : IUnknown
{
	public new const Guid IID = .(0x1eb22e86, 0x4c86, 0x41f0, 0x9f, 0x9f, 0xc2, 0x51, 0xe9, 0xfd, 0xa6, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId) MoveToAggregate;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Unlink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAccountId) get_AccountId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAccountId) put_AccountId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAggregateId) get_AggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppItemId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pIsMe) get_IsMe;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pIsExternal) get_IsExternal;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pNetworkSourceId) get_NetworkSourceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 networkSourceId) put_NetworkSourceId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppNetworkSourceId) get_NetworkSourceIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pNetworkSourceId) put_NetworkSourceIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** ppRemoteObjectId) get_RemoteObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pRemoteObjectId) put_RemoteObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** ppSyncIdentityHash) get_SyncIdentityHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pSyncIdentityHash) put_SyncIdentityHash;
	}


	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT MoveToAggregate(PWSTR pAggregateId) mut => VT.[Friend]MoveToAggregate(&this, pAggregateId);

	public HRESULT Unlink() mut => VT.[Friend]Unlink(&this);

	public HRESULT get_AccountId(PWSTR* ppAccountId) mut => VT.[Friend]get_AccountId(&this, ppAccountId);

	public HRESULT put_AccountId(PWSTR pAccountId) mut => VT.[Friend]put_AccountId(&this, pAccountId);

	public HRESULT get_AggregateId(PWSTR* ppAggregateId) mut => VT.[Friend]get_AggregateId(&this, ppAggregateId);

	public HRESULT get_Id(PWSTR* ppItemId) mut => VT.[Friend]get_Id(&this, ppItemId);

	public HRESULT get_IsMe(BOOL* pIsMe) mut => VT.[Friend]get_IsMe(&this, pIsMe);

	public HRESULT get_IsExternal(BOOL* pIsExternal) mut => VT.[Friend]get_IsExternal(&this, pIsExternal);

	public HRESULT get_NetworkSourceId(uint32* pNetworkSourceId) mut => VT.[Friend]get_NetworkSourceId(&this, pNetworkSourceId);

	public HRESULT put_NetworkSourceId(uint32 networkSourceId) mut => VT.[Friend]put_NetworkSourceId(&this, networkSourceId);

	public HRESULT get_NetworkSourceIdString(PWSTR* ppNetworkSourceId) mut => VT.[Friend]get_NetworkSourceIdString(&this, ppNetworkSourceId);

	public HRESULT put_NetworkSourceIdString(PWSTR pNetworkSourceId) mut => VT.[Friend]put_NetworkSourceIdString(&this, pNetworkSourceId);

	public HRESULT get_RemoteObjectId(CONTACT_AGGREGATION_BLOB** ppRemoteObjectId) mut => VT.[Friend]get_RemoteObjectId(&this, ppRemoteObjectId);

	public HRESULT put_RemoteObjectId(CONTACT_AGGREGATION_BLOB* pRemoteObjectId) mut => VT.[Friend]put_RemoteObjectId(&this, pRemoteObjectId);

	public HRESULT get_SyncIdentityHash(CONTACT_AGGREGATION_BLOB** ppSyncIdentityHash) mut => VT.[Friend]get_SyncIdentityHash(&this, ppSyncIdentityHash);

	public HRESULT put_SyncIdentityHash(CONTACT_AGGREGATION_BLOB* pSyncIdentityHash) mut => VT.[Friend]put_SyncIdentityHash(&this, pSyncIdentityHash);
}

[CRepr]struct IContactAggregationContactCollection : IUnknown
{
	public new const Guid IID = .(0x826e66fa, 0x81de, 0x43ca, 0xa6, 0xfb, 0x8c, 0x78, 0x5c, 0xd9, 0x96, 0xc6);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationContact** ppItem) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationContact** ppItem) FindNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pIdentityHash, IContactAggregationContact** ppItem) FindFirstByIdentityHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pRemoteObjectId, IContactAggregationContact** ppItem) FindFirstByRemoteId;
	}


	public HRESULT FindFirst(IContactAggregationContact** ppItem) mut => VT.[Friend]FindFirst(&this, ppItem);

	public HRESULT FindNext(IContactAggregationContact** ppItem) mut => VT.[Friend]FindNext(&this, ppItem);

	public HRESULT FindFirstByIdentityHash(PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pIdentityHash, IContactAggregationContact** ppItem) mut => VT.[Friend]FindFirstByIdentityHash(&this, pSourceType, pAccountId, pIdentityHash, ppItem);

	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);

	public HRESULT FindFirstByRemoteId(PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pRemoteObjectId, IContactAggregationContact** ppItem) mut => VT.[Friend]FindFirstByRemoteId(&this, pSourceType, pAccountId, pRemoteObjectId, ppItem);
}

[CRepr]struct IContactAggregationAggregate : IUnknown
{
	public new const Guid IID = .(0x7ed1c814, 0xcd30, 0x43c8, 0x9b, 0x8d, 0x2e, 0x48, 0x9e, 0x53, 0xd5, 0x4b);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationContactCollection** pComponentItems) GetComponentItems;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId) Link;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationGroupCollection** ppGroups) get_Groups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAntiLink) get_AntiLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAntiLink) put_AntiLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFavoriteOrder) get_FavoriteOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 favoriteOrder) put_FavoriteOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppItemId) get_Id;
	}


	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT GetComponentItems(IContactAggregationContactCollection** pComponentItems) mut => VT.[Friend]GetComponentItems(&this, pComponentItems);

	public HRESULT Link(PWSTR pAggregateId) mut => VT.[Friend]Link(&this, pAggregateId);

	public HRESULT get_Groups(CONTACT_AGGREGATION_COLLECTION_OPTIONS options, IContactAggregationGroupCollection** ppGroups) mut => VT.[Friend]get_Groups(&this, options, ppGroups);

	public HRESULT get_AntiLink(PWSTR* ppAntiLink) mut => VT.[Friend]get_AntiLink(&this, ppAntiLink);

	public HRESULT put_AntiLink(PWSTR pAntiLink) mut => VT.[Friend]put_AntiLink(&this, pAntiLink);

	public HRESULT get_FavoriteOrder(uint32* pFavoriteOrder) mut => VT.[Friend]get_FavoriteOrder(&this, pFavoriteOrder);

	public HRESULT put_FavoriteOrder(uint32 favoriteOrder) mut => VT.[Friend]put_FavoriteOrder(&this, favoriteOrder);

	public HRESULT get_Id(PWSTR* ppItemId) mut => VT.[Friend]get_Id(&this, ppItemId);
}

[CRepr]struct IContactAggregationAggregateCollection : IUnknown
{
	public new const Guid IID = .(0x2359f3a6, 0x3a68, 0x40af, 0x98, 0xdb, 0x0f, 0x9e, 0xb1, 0x43, 0xc3, 0xbb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationAggregate** ppAggregate) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAntiLinkId, IContactAggregationAggregate** ppAggregate) FindFirstByAntiLinkId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationAggregate** ppAggregate) FindNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, int32* pCount) get_Count;
	}


	public HRESULT FindFirst(IContactAggregationAggregate** ppAggregate) mut => VT.[Friend]FindFirst(&this, ppAggregate);

	public HRESULT FindFirstByAntiLinkId(PWSTR pAntiLinkId, IContactAggregationAggregate** ppAggregate) mut => VT.[Friend]FindFirstByAntiLinkId(&this, pAntiLinkId, ppAggregate);

	public HRESULT FindNext(IContactAggregationAggregate** ppAggregate) mut => VT.[Friend]FindNext(&this, ppAggregate);

	public HRESULT get_Count(int32* pCount) mut => VT.[Friend]get_Count(&this, pCount);
}

[CRepr]struct IContactAggregationGroup : IUnknown
{
	public new const Guid IID = .(0xc93c545f, 0x1284, 0x499b, 0x96, 0xaf, 0x07, 0x37, 0x2a, 0xf4, 0x73, 0xe0);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId) Add;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId) Remove;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationAggregateCollection** ppAggregateContactCollection) get_Members;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, Guid* pGlobalObjectId) get_GlobalObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pGlobalObjectId) put_GlobalObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppItemId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppName) get_Name;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pName) put_Name;
	}


	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT Add(PWSTR pAggregateId) mut => VT.[Friend]Add(&this, pAggregateId);

	public HRESULT Remove(PWSTR pAggregateId) mut => VT.[Friend]Remove(&this, pAggregateId);

	public HRESULT get_Members(IContactAggregationAggregateCollection** ppAggregateContactCollection) mut => VT.[Friend]get_Members(&this, ppAggregateContactCollection);

	public HRESULT get_GlobalObjectId(Guid* pGlobalObjectId) mut => VT.[Friend]get_GlobalObjectId(&this, pGlobalObjectId);

	public HRESULT put_GlobalObjectId(in Guid pGlobalObjectId) mut => VT.[Friend]put_GlobalObjectId(&this, pGlobalObjectId);

	public HRESULT get_Id(PWSTR* ppItemId) mut => VT.[Friend]get_Id(&this, ppItemId);

	public HRESULT get_Name(PWSTR* ppName) mut => VT.[Friend]get_Name(&this, ppName);

	public HRESULT put_Name(PWSTR pName) mut => VT.[Friend]put_Name(&this, pName);
}

[CRepr]struct IContactAggregationGroupCollection : IUnknown
{
	public new const Guid IID = .(0x20a19a9c, 0xd2f3, 0x4b83, 0x91, 0x43, 0xbe, 0xff, 0xd2, 0xcc, 0x22, 0x6d);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationGroup** ppGroup) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, in Guid pGlobalObjectId, IContactAggregationGroup** ppGroup) FindFirstByGlobalObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationGroup** ppGroup) FindNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) get_Count;
	}


	public HRESULT FindFirst(IContactAggregationGroup** ppGroup) mut => VT.[Friend]FindFirst(&this, ppGroup);

	public HRESULT FindFirstByGlobalObjectId(in Guid pGlobalObjectId, IContactAggregationGroup** ppGroup) mut => VT.[Friend]FindFirstByGlobalObjectId(&this, pGlobalObjectId, ppGroup);

	public HRESULT FindNext(IContactAggregationGroup** ppGroup) mut => VT.[Friend]FindNext(&this, ppGroup);

	public HRESULT get_Count(uint32* pCount) mut => VT.[Friend]get_Count(&this, pCount);
}

[CRepr]struct IContactAggregationLink : IUnknown
{
	public new const Guid IID = .(0xb6813323, 0xa183, 0x4654, 0x86, 0x27, 0x79, 0xb3, 0x0d, 0xe3, 0xa0, 0xec);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAccountId) get_AccountId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAccountId) put_AccountId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppItemId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pIsLinkResolved) get_IsLinkResolved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isLinkResolved) put_IsLinkResolved;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppNetworkSourceId) get_NetworkSourceIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pNetworkSourceId) put_NetworkSourceIdString;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** ppRemoteObjectId) get_RemoteObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pRemoteObjectId) put_RemoteObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppServerPersonId) get_ServerPerson;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pServerPersonId) put_ServerPerson;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppServerPersonId) get_ServerPersonBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pServerPersonId) put_ServerPersonBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** ppSyncIdentityHash) get_SyncIdentityHash;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pSyncIdentityHash) put_SyncIdentityHash;
	}


	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT get_AccountId(PWSTR* ppAccountId) mut => VT.[Friend]get_AccountId(&this, ppAccountId);

	public HRESULT put_AccountId(PWSTR pAccountId) mut => VT.[Friend]put_AccountId(&this, pAccountId);

	public HRESULT get_Id(PWSTR* ppItemId) mut => VT.[Friend]get_Id(&this, ppItemId);

	public HRESULT get_IsLinkResolved(BOOL* pIsLinkResolved) mut => VT.[Friend]get_IsLinkResolved(&this, pIsLinkResolved);

	public HRESULT put_IsLinkResolved(BOOL isLinkResolved) mut => VT.[Friend]put_IsLinkResolved(&this, isLinkResolved);

	public HRESULT get_NetworkSourceIdString(PWSTR* ppNetworkSourceId) mut => VT.[Friend]get_NetworkSourceIdString(&this, ppNetworkSourceId);

	public HRESULT put_NetworkSourceIdString(PWSTR pNetworkSourceId) mut => VT.[Friend]put_NetworkSourceIdString(&this, pNetworkSourceId);

	public HRESULT get_RemoteObjectId(CONTACT_AGGREGATION_BLOB** ppRemoteObjectId) mut => VT.[Friend]get_RemoteObjectId(&this, ppRemoteObjectId);

	public HRESULT put_RemoteObjectId(CONTACT_AGGREGATION_BLOB* pRemoteObjectId) mut => VT.[Friend]put_RemoteObjectId(&this, pRemoteObjectId);

	public HRESULT get_ServerPerson(PWSTR* ppServerPersonId) mut => VT.[Friend]get_ServerPerson(&this, ppServerPersonId);

	public HRESULT put_ServerPerson(PWSTR pServerPersonId) mut => VT.[Friend]put_ServerPerson(&this, pServerPersonId);

	public HRESULT get_ServerPersonBaseline(PWSTR* ppServerPersonId) mut => VT.[Friend]get_ServerPersonBaseline(&this, ppServerPersonId);

	public HRESULT put_ServerPersonBaseline(PWSTR pServerPersonId) mut => VT.[Friend]put_ServerPersonBaseline(&this, pServerPersonId);

	public HRESULT get_SyncIdentityHash(CONTACT_AGGREGATION_BLOB** ppSyncIdentityHash) mut => VT.[Friend]get_SyncIdentityHash(&this, ppSyncIdentityHash);

	public HRESULT put_SyncIdentityHash(CONTACT_AGGREGATION_BLOB* pSyncIdentityHash) mut => VT.[Friend]put_SyncIdentityHash(&this, pSyncIdentityHash);
}

[CRepr]struct IContactAggregationLinkCollection : IUnknown
{
	public new const Guid IID = .(0xf8bc0e93, 0xfb55, 0x4f28, 0xb9, 0xfa, 0xb1, 0xc2, 0x74, 0x15, 0x32, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationLink** ppServerContactLink) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pRemoteId, IContactAggregationLink** ppServerContactLink) FindFirstByRemoteId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationLink** ppServerContactLink) FindNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) get_Count;
	}


	public HRESULT FindFirst(IContactAggregationLink** ppServerContactLink) mut => VT.[Friend]FindFirst(&this, ppServerContactLink);

	public HRESULT FindFirstByRemoteId(PWSTR pSourceType, PWSTR pAccountId, CONTACT_AGGREGATION_BLOB* pRemoteId, IContactAggregationLink** ppServerContactLink) mut => VT.[Friend]FindFirstByRemoteId(&this, pSourceType, pAccountId, pRemoteId, ppServerContactLink);

	public HRESULT FindNext(IContactAggregationLink** ppServerContactLink) mut => VT.[Friend]FindNext(&this, ppServerContactLink);

	public HRESULT get_Count(uint32* pCount) mut => VT.[Friend]get_Count(&this, pCount);
}

[CRepr]struct IContactAggregationServerPerson : IUnknown
{
	public new const Guid IID = .(0x7fdc3d4b, 0x1b82, 0x4334, 0x85, 0xc5, 0x25, 0x18, 0x4e, 0xe5, 0xa5, 0xf2);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Delete;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Save;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAggregateId) get_AggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId) put_AggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAntiLink) get_AntiLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAntiLink) put_AntiLink;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppAntiLink) get_AntiLinkBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAntiLink) put_AntiLinkBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFavoriteOrder) get_FavoriteOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 favoriteOrder) put_FavoriteOrder;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pFavoriteOrder) get_FavoriteOrderBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 favoriteOrder) put_FavoriteOrderBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** pGroups) get_Groups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pGroups) put_Groups;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB** ppGroups) get_GroupsBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, CONTACT_AGGREGATION_BLOB* pGroups) put_GroupsBaseline;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppId) get_Id;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL* pIsTombstone) get_IsTombstone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, BOOL isTombstone) put_IsTombstone;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppLinkedAggregateId) get_LinkedAggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pLinkedAggregateId) put_LinkedAggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR* ppObjectId) get_ObjectId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pObjectId) put_ObjectId;
	}


	public HRESULT Delete() mut => VT.[Friend]Delete(&this);

	public HRESULT Save() mut => VT.[Friend]Save(&this);

	public HRESULT get_AggregateId(PWSTR* ppAggregateId) mut => VT.[Friend]get_AggregateId(&this, ppAggregateId);

	public HRESULT put_AggregateId(PWSTR pAggregateId) mut => VT.[Friend]put_AggregateId(&this, pAggregateId);

	public HRESULT get_AntiLink(PWSTR* ppAntiLink) mut => VT.[Friend]get_AntiLink(&this, ppAntiLink);

	public HRESULT put_AntiLink(PWSTR pAntiLink) mut => VT.[Friend]put_AntiLink(&this, pAntiLink);

	public HRESULT get_AntiLinkBaseline(PWSTR* ppAntiLink) mut => VT.[Friend]get_AntiLinkBaseline(&this, ppAntiLink);

	public HRESULT put_AntiLinkBaseline(PWSTR pAntiLink) mut => VT.[Friend]put_AntiLinkBaseline(&this, pAntiLink);

	public HRESULT get_FavoriteOrder(uint32* pFavoriteOrder) mut => VT.[Friend]get_FavoriteOrder(&this, pFavoriteOrder);

	public HRESULT put_FavoriteOrder(uint32 favoriteOrder) mut => VT.[Friend]put_FavoriteOrder(&this, favoriteOrder);

	public HRESULT get_FavoriteOrderBaseline(uint32* pFavoriteOrder) mut => VT.[Friend]get_FavoriteOrderBaseline(&this, pFavoriteOrder);

	public HRESULT put_FavoriteOrderBaseline(uint32 favoriteOrder) mut => VT.[Friend]put_FavoriteOrderBaseline(&this, favoriteOrder);

	public HRESULT get_Groups(CONTACT_AGGREGATION_BLOB** pGroups) mut => VT.[Friend]get_Groups(&this, pGroups);

	public HRESULT put_Groups(CONTACT_AGGREGATION_BLOB* pGroups) mut => VT.[Friend]put_Groups(&this, pGroups);

	public HRESULT get_GroupsBaseline(CONTACT_AGGREGATION_BLOB** ppGroups) mut => VT.[Friend]get_GroupsBaseline(&this, ppGroups);

	public HRESULT put_GroupsBaseline(CONTACT_AGGREGATION_BLOB* pGroups) mut => VT.[Friend]put_GroupsBaseline(&this, pGroups);

	public HRESULT get_Id(PWSTR* ppId) mut => VT.[Friend]get_Id(&this, ppId);

	public HRESULT get_IsTombstone(BOOL* pIsTombstone) mut => VT.[Friend]get_IsTombstone(&this, pIsTombstone);

	public HRESULT put_IsTombstone(BOOL isTombstone) mut => VT.[Friend]put_IsTombstone(&this, isTombstone);

	public HRESULT get_LinkedAggregateId(PWSTR* ppLinkedAggregateId) mut => VT.[Friend]get_LinkedAggregateId(&this, ppLinkedAggregateId);

	public HRESULT put_LinkedAggregateId(PWSTR pLinkedAggregateId) mut => VT.[Friend]put_LinkedAggregateId(&this, pLinkedAggregateId);

	public HRESULT get_ObjectId(PWSTR* ppObjectId) mut => VT.[Friend]get_ObjectId(&this, ppObjectId);

	public HRESULT put_ObjectId(PWSTR pObjectId) mut => VT.[Friend]put_ObjectId(&this, pObjectId);
}

[CRepr]struct IContactAggregationServerPersonCollection : IUnknown
{
	public new const Guid IID = .(0x4f730a4a, 0x6604, 0x47b6, 0xa9, 0x87, 0x66, 0x9e, 0xcf, 0x1e, 0x57, 0x51);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationServerPerson** ppServerPerson) FindFirst;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pServerId, IContactAggregationServerPerson** ppServerPerson) FindFirstByServerId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId, IContactAggregationServerPerson** ppServerPerson) FindFirstByAggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR pAggregateId, IContactAggregationServerPerson** ppServerPerson) FindFirstByLinkedAggregateId;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IContactAggregationServerPerson** ppServerPerson) FindNext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32* pCount) get_Count;
	}


	public HRESULT FindFirst(IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]FindFirst(&this, ppServerPerson);

	public HRESULT FindFirstByServerId(PWSTR pServerId, IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]FindFirstByServerId(&this, pServerId, ppServerPerson);

	public HRESULT FindFirstByAggregateId(PWSTR pAggregateId, IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]FindFirstByAggregateId(&this, pAggregateId, ppServerPerson);

	public HRESULT FindFirstByLinkedAggregateId(PWSTR pAggregateId, IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]FindFirstByLinkedAggregateId(&this, pAggregateId, ppServerPerson);

	public HRESULT FindNext(IContactAggregationServerPerson** ppServerPerson) mut => VT.[Friend]FindNext(&this, ppServerPerson);

	public HRESULT get_Count(uint32* pCount) mut => VT.[Friend]get_Count(&this, pCount);
}

#endregion
