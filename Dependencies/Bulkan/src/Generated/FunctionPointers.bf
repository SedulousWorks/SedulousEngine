using System;

namespace Bulkan;

public typealias PFN_vkInternalAllocationNotification = function void(
	void* pUserData,
	uint size,
	VkInternalAllocationType allocationType,
	VkSystemAllocationScope allocationScope);

public typealias PFN_vkInternalFreeNotification = function void(
	void* pUserData,
	uint size,
	VkInternalAllocationType allocationType,
	VkSystemAllocationScope allocationScope);

public typealias PFN_vkReallocationFunction = function void*(
	void* pUserData,
	void* pOriginal,
	uint size,
	uint alignment,
	VkSystemAllocationScope allocationScope);

public typealias PFN_vkAllocationFunction = function void*(
	void* pUserData,
	uint size,
	uint alignment,
	VkSystemAllocationScope allocationScope);

public typealias PFN_vkFreeFunction = function void(
	void* pUserData,
	void* pMemory);

public typealias PFN_vkVoidFunction = function void();

public typealias PFN_vkDebugReportCallbackEXT = function VkBool32(
	uint32 flags,
	VkDebugReportObjectTypeEXT objectType,
	uint64 object,
	uint location,
	int32 messageCode,
	char8* pLayerPrefix,
	char8* pMessage,
	void* pUserData);

public typealias PFN_vkDebugUtilsMessengerCallbackEXT = function VkBool32(
	VkDebugUtilsMessageSeverityFlagsEXT messageSeverity,
	uint32 messageTypes,
	VkDebugUtilsMessengerCallbackDataEXT* pCallbackData,
	void* pUserData);

public typealias PFN_vkFaultCallbackFunction = function void(
	VkBool32 unrecordedFaults,
	uint32 faultCount,
	VkFaultData* pFaults);

public typealias PFN_vkDeviceMemoryReportCallbackEXT = function void(
	VkDeviceMemoryReportCallbackDataEXT* pCallbackData,
	void* pUserData);

public typealias PFN_vkGetInstanceProcAddrLUNARG = function PFN_vkVoidFunction(
	VkInstance instance,
	char8* pName);


