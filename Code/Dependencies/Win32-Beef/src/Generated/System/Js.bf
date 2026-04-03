using Win32.System.Diagnostics.Debug;
using Win32.Foundation;
using Win32.System.Com;
using System;

namespace Win32.System.Js;

#region Constants
public static
{
	public const uint64 JS_SOURCE_CONTEXT_NONE = 18446744073709551615;
}
#endregion

#region Enums

[AllowDuplicates]
public enum JsRuntimeVersion : int32
{
	JsRuntimeVersion10 = 0,
	JsRuntimeVersion11 = 1,
	JsRuntimeVersionEdge = -1,
}


[AllowDuplicates]
public enum JsErrorCode : uint32
{
	JsNoError = 0,
	JsErrorCategoryUsage = 65536,
	JsErrorInvalidArgument = 65537,
	JsErrorNullArgument = 65538,
	JsErrorNoCurrentContext = 65539,
	JsErrorInExceptionState = 65540,
	JsErrorNotImplemented = 65541,
	JsErrorWrongThread = 65542,
	JsErrorRuntimeInUse = 65543,
	JsErrorBadSerializedScript = 65544,
	JsErrorInDisabledState = 65545,
	JsErrorCannotDisableExecution = 65546,
	JsErrorHeapEnumInProgress = 65547,
	JsErrorArgumentNotObject = 65548,
	JsErrorInProfileCallback = 65549,
	JsErrorInThreadServiceCallback = 65550,
	JsErrorCannotSerializeDebugScript = 65551,
	JsErrorAlreadyDebuggingContext = 65552,
	JsErrorAlreadyProfilingContext = 65553,
	JsErrorIdleNotEnabled = 65554,
	JsErrorCategoryEngine = 131072,
	JsErrorOutOfMemory = 131073,
	JsErrorCategoryScript = 196608,
	JsErrorScriptException = 196609,
	JsErrorScriptCompile = 196610,
	JsErrorScriptTerminated = 196611,
	JsErrorScriptEvalDisabled = 196612,
	JsErrorCategoryFatal = 262144,
	JsErrorFatal = 262145,
}


[AllowDuplicates]
public enum JsRuntimeAttributes : int32
{
	JsRuntimeAttributeNone = 0,
	JsRuntimeAttributeDisableBackgroundWork = 1,
	JsRuntimeAttributeAllowScriptInterrupt = 2,
	JsRuntimeAttributeEnableIdleProcessing = 4,
	JsRuntimeAttributeDisableNativeCodeGeneration = 8,
	JsRuntimeAttributeDisableEval = 16,
}


[AllowDuplicates]
public enum JsMemoryEventType : int32
{
	JsMemoryAllocate = 0,
	JsMemoryFree = 1,
	JsMemoryFailure = 2,
}


[AllowDuplicates]
public enum JsValueType : int32
{
	JsUndefined = 0,
	JsNull = 1,
	JsNumber = 2,
	JsString = 3,
	JsBoolean = 4,
	JsObject = 5,
	JsFunction = 6,
	JsError = 7,
	JsArray = 8,
}

#endregion

#region Function Pointers
public function bool JsMemoryAllocationCallback(void* callbackState, JsMemoryEventType allocationEvent, uint allocationSize);

public function void JsBeforeCollectCallback(void* callbackState);

public function void JsBackgroundWorkItemCallback(void* callbackState);

public function bool JsThreadServiceCallback(JsBackgroundWorkItemCallback callback, void* callbackState);

public function void JsFinalizeCallback(void* data);

public function void* JsNativeFunction(void* callee, bool isConstructCall, void** arguments, uint16 argumentCount, void* callbackState);

#endregion

#region Functions
public static
{
#if BF_64_BIT || BF_ARM_64
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateContext(void* runtime, IDebugApplication64* debugApplication, void** newContext);

#endif
#if BF_64_BIT || BF_ARM_64
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStartDebugging(IDebugApplication64* debugApplication);

#endif
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateRuntime(JsRuntimeAttributes attributes, JsRuntimeVersion runtimeVersion, JsThreadServiceCallback threadService, void** runtime);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCollectGarbage(void* runtime);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDisposeRuntime(void* runtime);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetRuntimeMemoryUsage(void* runtime, uint* memoryUsage);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetRuntimeMemoryLimit(void* runtime, uint* memoryLimit);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetRuntimeMemoryLimit(void* runtime, uint memoryLimit);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetRuntimeMemoryAllocationCallback(void* runtime, void* callbackState, JsMemoryAllocationCallback allocationCallback);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetRuntimeBeforeCollectCallback(void* runtime, void* callbackState, JsBeforeCollectCallback beforeCollectCallback);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsAddRef(void* @ref, uint32* count);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsRelease(void* @ref, uint32* count);

#if BF_32_BIT
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateContext(void* runtime, IDebugApplication32* debugApplication, void** newContext);

#endif
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetCurrentContext(void** currentContext);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetCurrentContext(void* context);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetRuntime(void* context, void** runtime);

#if BF_32_BIT
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStartDebugging(IDebugApplication32* debugApplication);

#endif
	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsIdle(uint32* nextIdleTick);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsParseScript(PWSTR script, uint sourceContext, PWSTR sourceUrl, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsRunScript(PWSTR script, uint sourceContext, PWSTR sourceUrl, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSerializeScript(PWSTR script, uint8* buffer, uint32* bufferSize);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsParseSerializedScript(PWSTR script, uint8* buffer, uint sourceContext, PWSTR sourceUrl, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsRunSerializedScript(PWSTR script, uint8* buffer, uint sourceContext, PWSTR sourceUrl, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetPropertyIdFromName(PWSTR name, void** propertyId);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetPropertyNameFromId(void* propertyId, uint16** name);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetUndefinedValue(void** undefinedValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetNullValue(void** nullValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetTrueValue(void** trueValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetFalseValue(void** falseValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsBoolToBoolean(uint8 value, void** booleanValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsBooleanToBool(void* value, bool* boolValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsConvertValueToBoolean(void* value, void** booleanValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetValueType(void* value, JsValueType* type);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDoubleToNumber(double doubleValue, void** value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsIntToNumber(int32 intValue, void** value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsNumberToDouble(void* value, double* doubleValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsConvertValueToNumber(void* value, void** numberValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetStringLength(void* stringValue, int32* length);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsPointerToString(char16* stringValue, uint stringLength, void** value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStringToPointer(void* value, uint16** stringValue, uint* stringLength);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsConvertValueToString(void* value, void** stringValue);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsVariantToValue(VARIANT* variant, void** value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsValueToVariant(void* object, VARIANT* variant);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetGlobalObject(void** globalObject);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateObject(void** object);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateExternalObject(void* data, JsFinalizeCallback finalizeCallback, void** object);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsConvertValueToObject(void* value, void** object);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetPrototype(void* object, void** prototypeObject);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetPrototype(void* object, void* prototypeObject);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetExtensionAllowed(void* object, bool* value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsPreventExtension(void* object);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetProperty(void* object, void* propertyId, void** value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetOwnPropertyDescriptor(void* object, void* propertyId, void** propertyDescriptor);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetOwnPropertyNames(void* object, void** propertyNames);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetProperty(void* object, void* propertyId, void* value, uint8 useStrictRules);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsHasProperty(void* object, void* propertyId, bool* hasProperty);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDeleteProperty(void* object, void* propertyId, uint8 useStrictRules, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDefineProperty(void* object, void* propertyId, void* propertyDescriptor, bool* result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsHasIndexedProperty(void* object, void* index, bool* result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetIndexedProperty(void* object, void* index, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetIndexedProperty(void* object, void* index, void* value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDeleteIndexedProperty(void* object, void* index);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsEquals(void* object1, void* object2, bool* result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStrictEquals(void* object1, void* object2, bool* result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsHasExternalData(void* object, bool* value);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetExternalData(void* object, void** externalData);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetExternalData(void* object, void* externalData);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateArray(uint32 length, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCallFunction(void* @function, void** arguments, uint16 argumentCount, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsConstructObject(void* @function, void** arguments, uint16 argumentCount, void** result);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateFunction(JsNativeFunction nativeFunction, void* callbackState, void** @function);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateRangeError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateReferenceError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateSyntaxError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateTypeError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsCreateURIError(void* message, void** error);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsHasException(bool* hasException);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsGetAndClearException(void** exception);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsSetException(void* exception);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsDisableRuntimeExecution(void* runtime);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsEnableRuntimeExecution(void* runtime);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsIsRuntimeExecutionDisabled(void* runtime, bool* isDisabled);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStartProfiling(IActiveScriptProfilerCallback* callback, PROFILER_EVENT_MASK eventMask, uint32 context);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsStopProfiling(HRESULT reason);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsEnumerateHeap(IActiveScriptProfilerHeapEnum** enumerator);

	[Import("chakra.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern JsErrorCode JsIsEnumeratingHeap(bool* isEnumeratingHeap);

}
#endregion
