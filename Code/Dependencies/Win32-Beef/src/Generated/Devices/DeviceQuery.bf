using Win32.Devices.Properties;
using Win32.Foundation;
using System;

namespace Win32.Devices.DeviceQuery;

#region Enums

[AllowDuplicates]
public enum DEVPROP_OPERATOR : uint32
{
	DEVPROP_OPERATOR_MODIFIER_NOT = 65536,
	DEVPROP_OPERATOR_MODIFIER_IGNORE_CASE = 131072,
	DEVPROP_OPERATOR_NONE = 0,
	DEVPROP_OPERATOR_EXISTS = 1,
	DEVPROP_OPERATOR_NOT_EXISTS = 65537,
	DEVPROP_OPERATOR_EQUALS = 2,
	DEVPROP_OPERATOR_NOT_EQUALS = 65538,
	DEVPROP_OPERATOR_GREATER_THAN = 3,
	DEVPROP_OPERATOR_LESS_THAN = 4,
	DEVPROP_OPERATOR_GREATER_THAN_EQUALS = 5,
	DEVPROP_OPERATOR_LESS_THAN_EQUALS = 6,
	DEVPROP_OPERATOR_EQUALS_IGNORE_CASE = 131074,
	DEVPROP_OPERATOR_NOT_EQUALS_IGNORE_CASE = 196610,
	DEVPROP_OPERATOR_BITWISE_AND = 7,
	DEVPROP_OPERATOR_BITWISE_OR = 8,
	DEVPROP_OPERATOR_BEGINS_WITH = 9,
	DEVPROP_OPERATOR_ENDS_WITH = 10,
	DEVPROP_OPERATOR_CONTAINS = 11,
	DEVPROP_OPERATOR_BEGINS_WITH_IGNORE_CASE = 131081,
	DEVPROP_OPERATOR_ENDS_WITH_IGNORE_CASE = 131082,
	DEVPROP_OPERATOR_CONTAINS_IGNORE_CASE = 131083,
	DEVPROP_OPERATOR_LIST_CONTAINS = 4096,
	DEVPROP_OPERATOR_LIST_ELEMENT_BEGINS_WITH = 8192,
	DEVPROP_OPERATOR_LIST_ELEMENT_ENDS_WITH = 12288,
	DEVPROP_OPERATOR_LIST_ELEMENT_CONTAINS = 16384,
	DEVPROP_OPERATOR_LIST_CONTAINS_IGNORE_CASE = 135168,
	DEVPROP_OPERATOR_LIST_ELEMENT_BEGINS_WITH_IGNORE_CASE = 139264,
	DEVPROP_OPERATOR_LIST_ELEMENT_ENDS_WITH_IGNORE_CASE = 143360,
	DEVPROP_OPERATOR_LIST_ELEMENT_CONTAINS_IGNORE_CASE = 147456,
	DEVPROP_OPERATOR_AND_OPEN = 1048576,
	DEVPROP_OPERATOR_AND_CLOSE = 2097152,
	DEVPROP_OPERATOR_OR_OPEN = 3145728,
	DEVPROP_OPERATOR_OR_CLOSE = 4194304,
	DEVPROP_OPERATOR_NOT_OPEN = 5242880,
	DEVPROP_OPERATOR_NOT_CLOSE = 6291456,
	DEVPROP_OPERATOR_ARRAY_CONTAINS = 268435456,
	DEVPROP_OPERATOR_MASK_EVAL = 4095,
	DEVPROP_OPERATOR_MASK_LIST = 61440,
	DEVPROP_OPERATOR_MASK_MODIFIER = 983040,
	DEVPROP_OPERATOR_MASK_NOT_LOGICAL = 4027580415,
	DEVPROP_OPERATOR_MASK_LOGICAL = 267386880,
	DEVPROP_OPERATOR_MASK_ARRAY = 4026531840,
}


[AllowDuplicates]
public enum DEV_OBJECT_TYPE : int32
{
	DevObjectTypeUnknown = 0,
	DevObjectTypeDeviceInterface = 1,
	DevObjectTypeDeviceContainer = 2,
	DevObjectTypeDevice = 3,
	DevObjectTypeDeviceInterfaceClass = 4,
	DevObjectTypeAEP = 5,
	DevObjectTypeAEPContainer = 6,
	DevObjectTypeDeviceInstallerClass = 7,
	DevObjectTypeDeviceInterfaceDisplay = 8,
	DevObjectTypeDeviceContainerDisplay = 9,
	DevObjectTypeAEPService = 10,
	DevObjectTypeDevicePanel = 11,
}


[AllowDuplicates]
public enum DEV_QUERY_FLAGS : int32
{
	DevQueryFlagNone = 0,
	DevQueryFlagUpdateResults = 1,
	DevQueryFlagAllProperties = 2,
	DevQueryFlagLocalize = 4,
	DevQueryFlagAsyncClose = 8,
}


[AllowDuplicates]
public enum DEV_QUERY_STATE : int32
{
	DevQueryStateInitialized = 0,
	DevQueryStateEnumCompleted = 1,
	DevQueryStateAborted = 2,
	DevQueryStateClosed = 3,
}


[AllowDuplicates]
public enum DEV_QUERY_RESULT_ACTION : int32
{
	DevQueryResultStateChange = 0,
	DevQueryResultAdd = 1,
	DevQueryResultUpdate = 2,
	DevQueryResultRemove = 3,
}

#endregion

#region Function Pointers
public function void PDEV_QUERY_RESULT_CALLBACK(HDEVQUERY__* hDevQuery, void* pContext, DEV_QUERY_RESULT_ACTION_DATA* pActionData);

#endregion

#region Structs
[CRepr]
public struct DEVPROP_FILTER_EXPRESSION
{
	public DEVPROP_OPERATOR Operator;
	public DEVPROPERTY Property;
}

[CRepr]
public struct DEV_OBJECT
{
	public DEV_OBJECT_TYPE ObjectType;
	public PWSTR pszObjectId;
	public uint32 cPropertyCount;
	public DEVPROPERTY* pProperties;
}

[CRepr]
public struct DEV_QUERY_RESULT_ACTION_DATA
{
	[CRepr, Union]
	public struct _DEV_QUERY_RESULT_UPDATE_PAYLOAD
	{
		public DEV_QUERY_STATE State;
		public DEV_OBJECT DeviceObject;
	}
	public DEV_QUERY_RESULT_ACTION Action;
	public _DEV_QUERY_RESULT_UPDATE_PAYLOAD Data;
}

[CRepr]
public struct DEV_QUERY_PARAMETER
{
	public DEVPROPKEY Key;
	public uint32 Type;
	public uint32 BufferSize;
	public void* Buffer;
}

[CRepr]
public struct HDEVQUERY__
{
	public int32 unused;
}

#endregion

#region Functions
public static
{
	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQuery(DEV_OBJECT_TYPE ObjectType, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQueryEx(DEV_OBJECT_TYPE ObjectType, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, uint32 cExtendedParameterCount, DEV_QUERY_PARAMETER* pExtendedParameters, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQueryFromId(DEV_OBJECT_TYPE ObjectType, PWSTR pszObjectId, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQueryFromIdEx(DEV_OBJECT_TYPE ObjectType, PWSTR pszObjectId, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, uint32 cExtendedParameterCount, DEV_QUERY_PARAMETER* pExtendedParameters, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQueryFromIds(DEV_OBJECT_TYPE ObjectType, PWSTR pszzObjectIds, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevCreateObjectQueryFromIdsEx(DEV_OBJECT_TYPE ObjectType, PWSTR pszzObjectIds, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, uint32 cExtendedParameterCount, DEV_QUERY_PARAMETER* pExtendedParameters, PDEV_QUERY_RESULT_CALLBACK pCallback, void* pContext, HDEVQUERY__** phDevQuery);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DevCloseObjectQuery(HDEVQUERY__* hDevQuery);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevGetObjects(DEV_OBJECT_TYPE ObjectType, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, uint32* pcObjectCount, DEV_OBJECT** ppObjects);

	[Import("api-ms-win-devices-query-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevGetObjectsEx(DEV_OBJECT_TYPE ObjectType, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cFilterExpressionCount, DEVPROP_FILTER_EXPRESSION* pFilter, uint32 cExtendedParameterCount, DEV_QUERY_PARAMETER* pExtendedParameters, uint32* pcObjectCount, DEV_OBJECT** ppObjects);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DevFreeObjects(uint32 cObjectCount, DEV_OBJECT* pObjects);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevGetObjectProperties(DEV_OBJECT_TYPE ObjectType, PWSTR pszObjectId, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32* pcPropertyCount, DEVPROPERTY** ppProperties);

	[Import("api-ms-win-devices-query-l1-1-1.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT DevGetObjectPropertiesEx(DEV_OBJECT_TYPE ObjectType, PWSTR pszObjectId, uint32 QueryFlags, uint32 cRequestedProperties, DEVPROPCOMPKEY* pRequestedProperties, uint32 cExtendedParameterCount, DEV_QUERY_PARAMETER* pExtendedParameters, uint32* pcPropertyCount, DEVPROPERTY** ppProperties);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern void DevFreeObjectProperties(uint32 cPropertyCount, DEVPROPERTY* pProperties);

	[Import("api-ms-win-devices-query-l1-1-0.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern DEVPROPERTY* DevFindProperty(DEVPROPKEY* pKey, DEVPROPSTORE Store, PWSTR pszLocaleName, uint32 cProperties, DEVPROPERTY* pProperties);

}
#endregion
