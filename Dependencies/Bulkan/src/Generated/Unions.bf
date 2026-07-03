using System;
namespace Bulkan;

[CRepr, Union]
public struct VkClearColorValue
{
	public float[4] float32;
	public int32[4] int32;
	public uint32[4] uint32;
}

[CRepr, Union]
public struct VkClearValue
{
	public VkClearColorValue color;
	public VkClearDepthStencilValue depthStencil;
}

[CRepr, Union]
public struct VkClusterAccelerationStructureOpInputNV
{
	public VkClusterAccelerationStructureClustersBottomLevelInputNV* pClustersBottomLevel;
	public VkClusterAccelerationStructureTriangleClusterInputNV* pTriangleClusters;
	public VkClusterAccelerationStructureMoveObjectsInputNV* pMoveObjects;
}

[CRepr, Union]
public struct VkPerformanceCounterResultKHR
{
	public int32 int32;
	public int64 int64;
	public uint32 uint32;
	public uint64 uint64;
	public float float32;
	public double float64;
}

[CRepr, Union]
public struct VkPerformanceValueDataINTEL
{
	public uint32 value32;
	public uint64 value64;
	public float valueFloat;
	public VkBool32 valueBool;
	public char8* valueString;
}

[CRepr, Union]
public struct VkPipelineExecutableStatisticValueKHR
{
	public VkBool32 b32;
	public int64 i64;
	public uint64 u64;
	public double f64;
}

[CRepr, Union]
public struct VkDeviceOrHostAddressKHR
{
	public uint64 deviceAddress;
	public void* hostAddress;
}

[CRepr, Union]
public struct VkDeviceOrHostAddressConstKHR
{
	public uint64 deviceAddress;
	public void* hostAddress;
}

[CRepr, Union]
public struct VkDeviceOrHostAddressConstAMDX
{
	public uint64 deviceAddress;
	public void* hostAddress;
}

[CRepr, Union]
public struct VkAccelerationStructureGeometryDataKHR
{
	public VkAccelerationStructureGeometryTrianglesDataKHR triangles;
	public VkAccelerationStructureGeometryAabbsDataKHR aabbs;
	public VkAccelerationStructureGeometryInstancesDataKHR instances;
}

[CRepr, Union]
public struct VkIndirectExecutionSetInfoEXT
{
	public VkIndirectExecutionSetPipelineInfoEXT* pPipelineInfo;
	public VkIndirectExecutionSetShaderInfoEXT* pShaderInfo;
}

[CRepr, Union]
public struct VkIndirectCommandsTokenDataEXT
{
	public VkIndirectCommandsPushConstantTokenEXT* pPushConstant;
	public VkIndirectCommandsVertexBufferTokenEXT* pVertexBuffer;
	public VkIndirectCommandsIndexBufferTokenEXT* pIndexBuffer;
	public VkIndirectCommandsExecutionSetTokenEXT* pExecutionSet;
}

[CRepr, Union]
public struct VkDescriptorDataEXT
{
	public VkSampler* pSampler;
	public VkDescriptorImageInfo* pCombinedImageSampler;
	public VkDescriptorImageInfo* pInputAttachmentImage;
	public VkDescriptorImageInfo* pSampledImage;
	public VkDescriptorImageInfo* pStorageImage;
	public VkDescriptorAddressInfoEXT* pUniformTexelBuffer;
	public VkDescriptorAddressInfoEXT* pStorageTexelBuffer;
	public VkDescriptorAddressInfoEXT* pUniformBuffer;
	public VkDescriptorAddressInfoEXT* pStorageBuffer;
	public uint64 accelerationStructure;
}

[CRepr, Union]
public struct VkAccelerationStructureMotionInstanceDataNV
{
	public VkAccelerationStructureInstanceKHR staticInstance;
	public VkAccelerationStructureMatrixMotionInstanceNV matrixMotionInstance;
	public VkAccelerationStructureSRTMotionInstanceNV srtMotionInstance;
}

[CRepr, Union]
public struct VkResourceDescriptorDataEXT
{
	public VkImageDescriptorInfoEXT* pImage;
	public VkTexelBufferDescriptorInfoEXT* pTexelBuffer;
	public VkDeviceAddressRangeEXT* pAddressRange;
	public VkTensorViewCreateInfoARM* pTensorARM;
}

[CRepr, Union]
public struct VkDescriptorMappingSourceDataEXT
{
	public VkDescriptorMappingSourceConstantOffsetEXT constantOffset;
	public VkDescriptorMappingSourcePushIndexEXT pushIndex;
	public VkDescriptorMappingSourceIndirectIndexEXT indirectIndex;
	public VkDescriptorMappingSourceIndirectIndexArrayEXT indirectIndexArray;
	public VkDescriptorMappingSourceHeapDataEXT heapData;
	public uint32 pushDataOffset;
	public uint32 pushAddressOffset;
	public VkDescriptorMappingSourceIndirectAddressEXT indirectAddress;
	public VkDescriptorMappingSourceShaderRecordIndexEXT shaderRecordIndex;
	public uint32 shaderRecordDataOffset;
	public uint32 shaderRecordAddressOffset;
}



