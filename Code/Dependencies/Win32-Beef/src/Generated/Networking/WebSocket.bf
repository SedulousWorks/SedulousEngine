using Win32.Foundation;
using System;

namespace Win32.Networking.WebSocket;

#region Constants
public static
{
	public const uint32 WEB_SOCKET_MAX_CLOSE_REASON_LENGTH = 123;
}
#endregion

#region TypeDefs
typealias WEB_SOCKET_HANDLE = int;

#endregion


#region Enums

[AllowDuplicates]
public enum WEB_SOCKET_CLOSE_STATUS : int32
{
	WEB_SOCKET_SUCCESS_CLOSE_STATUS = 1000,
	WEB_SOCKET_ENDPOINT_UNAVAILABLE_CLOSE_STATUS = 1001,
	WEB_SOCKET_PROTOCOL_ERROR_CLOSE_STATUS = 1002,
	WEB_SOCKET_INVALID_DATA_TYPE_CLOSE_STATUS = 1003,
	WEB_SOCKET_EMPTY_CLOSE_STATUS = 1005,
	WEB_SOCKET_ABORTED_CLOSE_STATUS = 1006,
	WEB_SOCKET_INVALID_PAYLOAD_CLOSE_STATUS = 1007,
	WEB_SOCKET_POLICY_VIOLATION_CLOSE_STATUS = 1008,
	WEB_SOCKET_MESSAGE_TOO_BIG_CLOSE_STATUS = 1009,
	WEB_SOCKET_UNSUPPORTED_EXTENSIONS_CLOSE_STATUS = 1010,
	WEB_SOCKET_SERVER_ERROR_CLOSE_STATUS = 1011,
	WEB_SOCKET_SECURE_HANDSHAKE_ERROR_CLOSE_STATUS = 1015,
}


[AllowDuplicates]
public enum WEB_SOCKET_PROPERTY_TYPE : int32
{
	WEB_SOCKET_RECEIVE_BUFFER_SIZE_PROPERTY_TYPE = 0,
	WEB_SOCKET_SEND_BUFFER_SIZE_PROPERTY_TYPE = 1,
	WEB_SOCKET_DISABLE_MASKING_PROPERTY_TYPE = 2,
	WEB_SOCKET_ALLOCATED_BUFFER_PROPERTY_TYPE = 3,
	WEB_SOCKET_DISABLE_UTF8_VERIFICATION_PROPERTY_TYPE = 4,
	WEB_SOCKET_KEEPALIVE_INTERVAL_PROPERTY_TYPE = 5,
	WEB_SOCKET_SUPPORTED_VERSIONS_PROPERTY_TYPE = 6,
}


[AllowDuplicates]
public enum WEB_SOCKET_ACTION_QUEUE : int32
{
	WEB_SOCKET_SEND_ACTION_QUEUE = 1,
	WEB_SOCKET_RECEIVE_ACTION_QUEUE = 2,
	WEB_SOCKET_ALL_ACTION_QUEUE = 3,
}


[AllowDuplicates]
public enum WEB_SOCKET_BUFFER_TYPE : int32
{
	WEB_SOCKET_UTF8_MESSAGE_BUFFER_TYPE = -2147483648,
	WEB_SOCKET_UTF8_FRAGMENT_BUFFER_TYPE = -2147483647,
	WEB_SOCKET_BINARY_MESSAGE_BUFFER_TYPE = -2147483646,
	WEB_SOCKET_BINARY_FRAGMENT_BUFFER_TYPE = -2147483645,
	WEB_SOCKET_CLOSE_BUFFER_TYPE = -2147483644,
	WEB_SOCKET_PING_PONG_BUFFER_TYPE = -2147483643,
	WEB_SOCKET_UNSOLICITED_PONG_BUFFER_TYPE = -2147483642,
}


[AllowDuplicates]
public enum WEB_SOCKET_ACTION : int32
{
	WEB_SOCKET_NO_ACTION = 0,
	WEB_SOCKET_SEND_TO_NETWORK_ACTION = 1,
	WEB_SOCKET_INDICATE_SEND_COMPLETE_ACTION = 2,
	WEB_SOCKET_RECEIVE_FROM_NETWORK_ACTION = 3,
	WEB_SOCKET_INDICATE_RECEIVE_COMPLETE_ACTION = 4,
}

#endregion


#region Structs
[CRepr]
public struct WEB_SOCKET_PROPERTY
{
	public WEB_SOCKET_PROPERTY_TYPE Type;
	public void* pvValue;
	public uint32 ulValueSize;
}

[CRepr]
public struct WEB_SOCKET_HTTP_HEADER
{
	public PSTR pcName;
	public uint32 ulNameLength;
	public PSTR pcValue;
	public uint32 ulValueLength;
}

[CRepr, Union]
public struct WEB_SOCKET_BUFFER
{
	[CRepr]
	public struct _Data_e__Struct
	{
		public uint8* pbBuffer;
		public uint32 ulBufferLength;
	}
	[CRepr]
	public struct _CloseStatus_e__Struct
	{
		public uint8* pbReason;
		public uint32 ulReasonLength;
		public uint16 usStatus;
	}
	public _Data_e__Struct Data;
	public _CloseStatus_e__Struct CloseStatus;
}

#endregion

#region Functions
public static
{
	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketCreateClientHandle(WEB_SOCKET_PROPERTY* pProperties, uint32 ulPropertyCount, WEB_SOCKET_HANDLE* phWebSocket);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketBeginClientHandshake(WEB_SOCKET_HANDLE hWebSocket, PSTR* pszSubprotocols, uint32 ulSubprotocolCount, PSTR* pszExtensions, uint32 ulExtensionCount, WEB_SOCKET_HTTP_HEADER* pInitialHeaders, uint32 ulInitialHeaderCount, WEB_SOCKET_HTTP_HEADER** pAdditionalHeaders, uint32* pulAdditionalHeaderCount);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketEndClientHandshake(WEB_SOCKET_HANDLE hWebSocket, WEB_SOCKET_HTTP_HEADER* pResponseHeaders, uint32 ulReponseHeaderCount, uint32* pulSelectedExtensions, uint32* pulSelectedExtensionCount, uint32* pulSelectedSubprotocol);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketCreateServerHandle(WEB_SOCKET_PROPERTY* pProperties, uint32 ulPropertyCount, WEB_SOCKET_HANDLE* phWebSocket);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketBeginServerHandshake(WEB_SOCKET_HANDLE hWebSocket, PSTR pszSubprotocolSelected, PSTR* pszExtensionSelected, uint32 ulExtensionSelectedCount, WEB_SOCKET_HTTP_HEADER* pRequestHeaders, uint32 ulRequestHeaderCount, WEB_SOCKET_HTTP_HEADER** pResponseHeaders, uint32* pulResponseHeaderCount);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketEndServerHandshake(WEB_SOCKET_HANDLE hWebSocket);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketSend(WEB_SOCKET_HANDLE hWebSocket, WEB_SOCKET_BUFFER_TYPE BufferType, WEB_SOCKET_BUFFER* pBuffer, void* Context);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketReceive(WEB_SOCKET_HANDLE hWebSocket, WEB_SOCKET_BUFFER* pBuffer, void* pvContext);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketGetAction(WEB_SOCKET_HANDLE hWebSocket, WEB_SOCKET_ACTION_QUEUE eActionQueue, WEB_SOCKET_BUFFER* pDataBuffers, uint32* pulDataBufferCount, WEB_SOCKET_ACTION* pAction, WEB_SOCKET_BUFFER_TYPE* pBufferType, void** pvApplicationContext, void** pvActionContext);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WebSocketCompleteAction(WEB_SOCKET_HANDLE hWebSocket, void* pvActionContext, uint32 ulBytesTransferred);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WebSocketAbortHandle(WEB_SOCKET_HANDLE hWebSocket);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void WebSocketDeleteHandle(WEB_SOCKET_HANDLE hWebSocket);

	[Import("websocket.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WebSocketGetGlobalProperty(WEB_SOCKET_PROPERTY_TYPE eType, void* pvValue, uint32* ulSize);

}
#endregion
