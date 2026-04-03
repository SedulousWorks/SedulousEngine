using Win32.Foundation;
using System;

namespace Win32.System.Mapi;

#region Constants
public static
{
	public const uint32 MAPI_OLE = 1;
	public const uint32 MAPI_OLE_STATIC = 2;
	public const uint32 MAPI_ORIG = 0;
	public const uint32 MAPI_TO = 1;
	public const uint32 MAPI_CC = 2;
	public const uint32 MAPI_BCC = 3;
	public const uint32 MAPI_UNREAD = 1;
	public const uint32 MAPI_RECEIPT_REQUESTED = 2;
	public const uint32 MAPI_SENT = 4;
	public const uint32 MAPI_LOGON_UI = 1;
	public const uint32 MAPI_PASSWORD_UI = 131072;
	public const uint32 MAPI_NEW_SESSION = 2;
	public const uint32 MAPI_FORCE_DOWNLOAD = 4096;
	public const uint32 MAPI_EXTENDED = 32;
	public const uint32 MAPI_DIALOG = 8;
	public const uint32 MAPI_FORCE_UNICODE = 262144;
	public const uint32 MAPI_UNREAD_ONLY = 32;
	public const uint32 MAPI_GUARANTEE_FIFO = 256;
	public const uint32 MAPI_LONG_MSGID = 16384;
	public const uint32 MAPI_PEEK = 128;
	public const uint32 MAPI_SUPPRESS_ATTACH = 2048;
	public const uint32 MAPI_ENVELOPE_ONLY = 64;
	public const uint32 MAPI_BODY_AS_FILE = 512;
	public const uint32 MAPI_AB_NOMODIFY = 1024;
	public const uint32 SUCCESS_SUCCESS = 0;
	public const uint32 MAPI_USER_ABORT = 1;
	public const uint32 MAPI_E_USER_ABORT = 1;
	public const uint32 MAPI_E_FAILURE = 2;
	public const uint32 MAPI_E_LOGON_FAILURE = 3;
	public const uint32 MAPI_E_LOGIN_FAILURE = 3;
	public const uint32 MAPI_E_DISK_FULL = 4;
	public const uint32 MAPI_E_INSUFFICIENT_MEMORY = 5;
	public const uint32 MAPI_E_ACCESS_DENIED = 6;
	public const uint32 MAPI_E_TOO_MANY_SESSIONS = 8;
	public const uint32 MAPI_E_TOO_MANY_FILES = 9;
	public const uint32 MAPI_E_TOO_MANY_RECIPIENTS = 10;
	public const uint32 MAPI_E_ATTACHMENT_NOT_FOUND = 11;
	public const uint32 MAPI_E_ATTACHMENT_OPEN_FAILURE = 12;
	public const uint32 MAPI_E_ATTACHMENT_WRITE_FAILURE = 13;
	public const uint32 MAPI_E_UNKNOWN_RECIPIENT = 14;
	public const uint32 MAPI_E_BAD_RECIPTYPE = 15;
	public const uint32 MAPI_E_NO_MESSAGES = 16;
	public const uint32 MAPI_E_INVALID_MESSAGE = 17;
	public const uint32 MAPI_E_TEXT_TOO_LARGE = 18;
	public const uint32 MAPI_E_INVALID_SESSION = 19;
	public const uint32 MAPI_E_TYPE_NOT_SUPPORTED = 20;
	public const uint32 MAPI_E_AMBIGUOUS_RECIPIENT = 21;
	public const uint32 MAPI_E_AMBIG_RECIP = 21;
	public const uint32 MAPI_E_MESSAGE_IN_USE = 22;
	public const uint32 MAPI_E_NETWORK_FAILURE = 23;
	public const uint32 MAPI_E_INVALID_EDITFIELDS = 24;
	public const uint32 MAPI_E_INVALID_RECIPS = 25;
	public const uint32 MAPI_E_NOT_SUPPORTED = 26;
	public const uint32 MAPI_E_UNICODE_NOT_SUPPORTED = 27;
	public const uint32 MAPI_E_ATTACHMENT_TOO_LARGE = 28;
}
#endregion
#region Function Pointers
public function uint32 LPMAPILOGON(uint ulUIParam, PSTR lpszProfileName, PSTR lpszPassword, uint32 flFlags, uint32 ulReserved, uint* lplhSession);

public function uint32 LPMAPILOGOFF(uint lhSession, uint ulUIParam, uint32 flFlags, uint32 ulReserved);

public function uint32 LPMAPISENDMAIL(uint lhSession, uint ulUIParam, MapiMessage* lpMessage, uint32 flFlags, uint32 ulReserved);

public function uint32 LPMAPISENDMAILW(uint lhSession, uint ulUIParam, MapiMessageW* lpMessage, uint32 flFlags, uint32 ulReserved);

public function uint32 LPMAPISENDDOCUMENTS(uint ulUIParam, PSTR lpszDelimChar, PSTR lpszFilePaths, PSTR lpszFileNames, uint32 ulReserved);

public function uint32 LPMAPIFINDNEXT(uint lhSession, uint ulUIParam, PSTR lpszMessageType, PSTR lpszSeedMessageID, uint32 flFlags, uint32 ulReserved, PSTR lpszMessageID);

public function uint32 LPMAPIREADMAIL(uint lhSession, uint ulUIParam, PSTR lpszMessageID, uint32 flFlags, uint32 ulReserved, MapiMessage** lppMessage);

public function uint32 LPMAPISAVEMAIL(uint lhSession, uint ulUIParam, MapiMessage* lpMessage, uint32 flFlags, uint32 ulReserved, PSTR lpszMessageID);

public function uint32 LPMAPIDELETEMAIL(uint lhSession, uint ulUIParam, PSTR lpszMessageID, uint32 flFlags, uint32 ulReserved);

public function uint32 LPMAPIFREEBUFFER(void* pv);

public function uint32 LPMAPIADDRESS(uint lhSession, uint ulUIParam, PSTR lpszCaption, uint32 nEditFields, PSTR lpszLabels, uint32 nRecips, MapiRecipDesc* lpRecips, uint32 flFlags, uint32 ulReserved, uint32* lpnNewRecips, MapiRecipDesc** lppNewRecips);

public function uint32 LPMAPIDETAILS(uint lhSession, uint ulUIParam, MapiRecipDesc* lpRecip, uint32 flFlags, uint32 ulReserved);

public function uint32 LPMAPIRESOLVENAME(uint lhSession, uint ulUIParam, PSTR lpszName, uint32 flFlags, uint32 ulReserved, MapiRecipDesc** lppRecip);

#endregion

#region Structs
[CRepr]
public struct MapiFileDesc
{
	public uint32 ulReserved;
	public uint32 flFlags;
	public uint32 nPosition;
	public PSTR lpszPathName;
	public PSTR lpszFileName;
	public void* lpFileType;
}

[CRepr]
public struct MapiFileDescW
{
	public uint32 ulReserved;
	public uint32 flFlags;
	public uint32 nPosition;
	public PWSTR lpszPathName;
	public PWSTR lpszFileName;
	public void* lpFileType;
}

[CRepr]
public struct MapiFileTagExt
{
	public uint32 ulReserved;
	public uint32 cbTag;
	public uint8* lpTag;
	public uint32 cbEncoding;
	public uint8* lpEncoding;
}

[CRepr]
public struct MapiRecipDesc
{
	public uint32 ulReserved;
	public uint32 ulRecipClass;
	public PSTR lpszName;
	public PSTR lpszAddress;
	public uint32 ulEIDSize;
	public void* lpEntryID;
}

[CRepr]
public struct MapiRecipDescW
{
	public uint32 ulReserved;
	public uint32 ulRecipClass;
	public PWSTR lpszName;
	public PWSTR lpszAddress;
	public uint32 ulEIDSize;
	public void* lpEntryID;
}

[CRepr]
public struct MapiMessage
{
	public uint32 ulReserved;
	public PSTR lpszSubject;
	public PSTR lpszNoteText;
	public PSTR lpszMessageType;
	public PSTR lpszDateReceived;
	public PSTR lpszConversationID;
	public uint32 flFlags;
	public MapiRecipDesc* lpOriginator;
	public uint32 nRecipCount;
	public MapiRecipDesc* lpRecips;
	public uint32 nFileCount;
	public MapiFileDesc* lpFiles;
}

[CRepr]
public struct MapiMessageW
{
	public uint32 ulReserved;
	public PWSTR lpszSubject;
	public PWSTR lpszNoteText;
	public PWSTR lpszMessageType;
	public PWSTR lpszDateReceived;
	public PWSTR lpszConversationID;
	public uint32 flFlags;
	public MapiRecipDescW* lpOriginator;
	public uint32 nRecipCount;
	public MapiRecipDescW* lpRecips;
	public uint32 nFileCount;
	public MapiFileDescW* lpFiles;
}

#endregion

#region Functions
public static
{
	[Import("MAPI32.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern uint32 MAPIFreeBuffer(void* pv);

}
#endregion
