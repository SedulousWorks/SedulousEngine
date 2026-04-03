using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.System.Com;
using System;

namespace Win32.AI.MachineLearning.WinML;

#region Constants
public static
{
	public const uint32 WINML_TENSOR_DIMENSION_COUNT_MAX = 4;
}
#endregion

#region Enums

[AllowDuplicates]
public enum WINML_TENSOR_DATA_TYPE : int32
{
	WINML_TENSOR_UNDEFINED = 0,
	WINML_TENSOR_FLOAT = 1,
	WINML_TENSOR_UINT8 = 2,
	WINML_TENSOR_INT8 = 3,
	WINML_TENSOR_UINT16 = 4,
	WINML_TENSOR_INT16 = 5,
	WINML_TENSOR_INT32 = 6,
	WINML_TENSOR_INT64 = 7,
	WINML_TENSOR_STRING = 8,
	WINML_TENSOR_BOOLEAN = 9,
	WINML_TENSOR_FLOAT16 = 10,
	WINML_TENSOR_DOUBLE = 11,
	WINML_TENSOR_UINT32 = 12,
	WINML_TENSOR_UINT64 = 13,
	WINML_TENSOR_COMPLEX64 = 14,
	WINML_TENSOR_COMPLEX128 = 15,
}


[AllowDuplicates]
public enum WINML_FEATURE_TYPE : int32
{
	WINML_FEATURE_UNDEFINED = 0,
	WINML_FEATURE_TENSOR = 1,
	WINML_FEATURE_SEQUENCE = 2,
	WINML_FEATURE_MAP = 3,
	WINML_FEATURE_IMAGE = 4,
}


[AllowDuplicates]
public enum WINML_BINDING_TYPE : int32
{
	WINML_BINDING_UNDEFINED = 0,
	WINML_BINDING_TENSOR = 1,
	WINML_BINDING_SEQUENCE = 2,
	WINML_BINDING_MAP = 3,
	WINML_BINDING_IMAGE = 4,
	WINML_BINDING_RESOURCE = 5,
}


[AllowDuplicates]
public enum WINML_RUNTIME_TYPE : int32
{
	WINML_RUNTIME_CNTK = 0,
}


[AllowDuplicates]
public enum MLOperatorAttributeType : uint32
{
	Undefined = 0,
	Float = 2,
	Int = 3,
	String = 4,
	FloatArray = 7,
	IntArray = 8,
	StringArray = 9,
}


[AllowDuplicates]
public enum MLOperatorTensorDataType : uint32
{
	Undefined = 0,
	Float = 1,
	UInt8 = 2,
	Int8 = 3,
	UInt16 = 4,
	Int16 = 5,
	Int32 = 6,
	Int64 = 7,
	String = 8,
	Bool = 9,
	Float16 = 10,
	Double = 11,
	UInt32 = 12,
	UInt64 = 13,
	Complex64 = 14,
	Complex128 = 15,
}


[AllowDuplicates]
public enum MLOperatorEdgeType : uint32
{
	Undefined = 0,
	Tensor = 1,
}


[AllowDuplicates]
public enum MLOperatorParameterOptions : uint32
{
	Single = 0,
	Optional = 1,
	Variadic = 2,
}


[AllowDuplicates]
public enum MLOperatorSchemaEdgeTypeFormat : int32
{
	EdgeDescription = 0,
	Label = 1,
}


[AllowDuplicates]
public enum MLOperatorKernelOptions : uint32
{
	None = 0,
	AllowDynamicInputShapes = 1,
}


[AllowDuplicates]
public enum MLOperatorExecutionType : uint32
{
	Undefined = 0,
	Cpu = 1,
	D3D12 = 2,
}

#endregion


#region Structs
[CRepr]
public struct WINML_TENSOR_BINDING_DESC
{
	public WINML_TENSOR_DATA_TYPE DataType;
	public uint32 NumDimensions;
	public int64* pShape;
	public uint32 DataSize;
	public void* pData;
}

[CRepr]
public struct WINML_SEQUENCE_BINDING_DESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public PWSTR* pStrings;
		public int64* pInts;
		public float* pFloats;
		public double* pDoubles;
	}
	public uint32 ElementCount;
	public WINML_TENSOR_DATA_TYPE ElementType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WINML_MAP_BINDING_DESC
{
	[CRepr, Union]
	public struct _Anonymous2_e__Union
	{
		public PWSTR* pStringFields;
		public int64* pIntFields;
		public float* pFloatFields;
		public double* pDoubleFields;
	}
	[CRepr, Union]
	public struct _Anonymous1_e__Union
	{
		public PWSTR* pStringKeys;
		public int64* pIntKeys;
	}
	public uint32 ElementCount;
	public WINML_TENSOR_DATA_TYPE KeyType;
	public using _Anonymous1_e__Union Anonymous1;
	public WINML_TENSOR_DATA_TYPE Fields;
	public using _Anonymous2_e__Union Anonymous2;
}

[CRepr]
public struct WINML_IMAGE_BINDING_DESC
{
	public WINML_TENSOR_DATA_TYPE ElementType;
	public uint32 NumDimensions;
	public int64* pShape;
	public uint32 DataSize;
	public void* pData;
}

[CRepr]
public struct WINML_RESOURCE_BINDING_DESC
{
	public WINML_TENSOR_DATA_TYPE ElementType;
	public uint32 NumDimensions;
	public int64* pShape;
	public ID3D12Resource* pResource;
}

[CRepr]
public struct WINML_BINDING_DESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public WINML_TENSOR_BINDING_DESC Tensor;
		public WINML_SEQUENCE_BINDING_DESC Sequence;
		public WINML_MAP_BINDING_DESC Map;
		public WINML_IMAGE_BINDING_DESC Image;
		public WINML_RESOURCE_BINDING_DESC Resource;
	}
	public PWSTR Name;
	public WINML_BINDING_TYPE BindType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WINML_TENSOR_VARIABLE_DESC
{
	public WINML_TENSOR_DATA_TYPE ElementType;
	public uint32 NumDimensions;
	public int64* pShape;
}

[CRepr]
public struct WINML_SEQUENCE_VARIABLE_DESC
{
	public WINML_TENSOR_DATA_TYPE ElementType;
}

[CRepr]
public struct WINML_MAP_VARIABLE_DESC
{
	public WINML_TENSOR_DATA_TYPE KeyType;
	public WINML_TENSOR_DATA_TYPE Fields;
}

[CRepr]
public struct WINML_IMAGE_VARIABLE_DESC
{
	public WINML_TENSOR_DATA_TYPE ElementType;
	public uint32 NumDimensions;
	public int64* pShape;
}

[CRepr]
public struct WINML_VARIABLE_DESC
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public WINML_TENSOR_VARIABLE_DESC Tensor;
		public WINML_SEQUENCE_VARIABLE_DESC Sequence;
		public WINML_MAP_VARIABLE_DESC Map;
		public WINML_IMAGE_VARIABLE_DESC Image;
	}
	public PWSTR Name;
	public PWSTR Description;
	public WINML_FEATURE_TYPE FeatureType;
	public BOOL Required;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct WINML_MODEL_DESC
{
	public PWSTR Author;
	public PWSTR Name;
	public PWSTR Domain;
	public PWSTR Description;
	public uint Version;
}

[CRepr]
public struct MLOperatorEdgeDescription
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public uint64 reserved;
		public MLOperatorTensorDataType tensorDataType;
	}
	public MLOperatorEdgeType edgeType;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MLOperatorSchemaEdgeDescription
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* reserved;
		public PSTR typeLabel;
		public MLOperatorEdgeDescription edgeDescription;
	}
	public MLOperatorParameterOptions options;
	public MLOperatorSchemaEdgeTypeFormat typeFormat;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MLOperatorEdgeTypeConstraint
{
	public PSTR typeLabel;
	public MLOperatorEdgeDescription* allowedTypes;
	public uint32 allowedTypeCount;
}

[CRepr]
public struct MLOperatorAttribute
{
	public PSTR name;
	public MLOperatorAttributeType type;
	public uint8 required;
}

[CRepr]
public struct MLOperatorAttributeNameValue
{
	[CRepr, Union]
	public struct _Anonymous_e__Union
	{
		public void* reserved;
		public int64* ints;
		public int8** strings;
		public float* floats;
	}
	public PSTR name;
	public MLOperatorAttributeType type;
	public uint32 valueCount;
	public using _Anonymous_e__Union Anonymous;
}

[CRepr]
public struct MLOperatorSchemaDescription
{
	public PSTR name;
	public int32 operatorSetVersionAtLastChange;
	public MLOperatorSchemaEdgeDescription* inputs;
	public uint32 inputCount;
	public MLOperatorSchemaEdgeDescription* outputs;
	public uint32 outputCount;
	public MLOperatorEdgeTypeConstraint* typeConstraints;
	public uint32 typeConstraintCount;
	public MLOperatorAttribute* attributes;
	public uint32 attributeCount;
	public MLOperatorAttributeNameValue* defaultAttributes;
	public uint32 defaultAttributeCount;
}

[CRepr]
public struct MLOperatorSetId
{
	public PSTR domain;
	public int32 version;
}

[CRepr]
public struct MLOperatorKernelDescription
{
	public PSTR domain;
	public PSTR name;
	public int32 minimumOperatorSetVersion;
	public MLOperatorExecutionType executionType;
	public MLOperatorEdgeTypeConstraint* typeConstraints;
	public uint32 typeConstraintCount;
	public MLOperatorAttributeNameValue* defaultAttributes;
	public uint32 defaultAttributeCount;
	public MLOperatorKernelOptions options;
	public uint32 executionOptions;
}

#endregion

#region COM Types
[CRepr]struct IWinMLModel : IUnknown
{
	public new const Guid IID = .(0xe2eeb6a9, 0xf31f, 0x4055, 0xa5, 0x21, 0xe3, 0x0b, 0x5b, 0x33, 0x66, 0x4a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WINML_MODEL_DESC** ppDescription) GetDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, PWSTR* pKey, PWSTR* pValue) EnumerateMetadata;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, WINML_VARIABLE_DESC** ppInputDescriptor) EnumerateModelInputs;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 Index, WINML_VARIABLE_DESC** ppOutputDescriptor) EnumerateModelOutputs;
	}


	public HRESULT GetDescription(WINML_MODEL_DESC** ppDescription) mut => VT.[Friend]GetDescription(&this, ppDescription);

	public HRESULT EnumerateMetadata(uint32 Index, PWSTR* pKey, PWSTR* pValue) mut => VT.[Friend]EnumerateMetadata(&this, Index, pKey, pValue);

	public HRESULT EnumerateModelInputs(uint32 Index, WINML_VARIABLE_DESC** ppInputDescriptor) mut => VT.[Friend]EnumerateModelInputs(&this, Index, ppInputDescriptor);

	public HRESULT EnumerateModelOutputs(uint32 Index, WINML_VARIABLE_DESC** ppOutputDescriptor) mut => VT.[Friend]EnumerateModelOutputs(&this, Index, ppOutputDescriptor);
}

[CRepr]struct IWinMLEvaluationContext : IUnknown
{
	public new const Guid IID = .(0x95848f9e, 0x583d, 0x4054, 0xaf, 0x12, 0x91, 0x63, 0x87, 0xcd, 0x84, 0x26);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WINML_BINDING_DESC* pDescriptor) BindValue;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Name, WINML_BINDING_DESC** pDescriptor) GetValueByName;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self) Clear;
	}


	public HRESULT BindValue(WINML_BINDING_DESC* pDescriptor) mut => VT.[Friend]BindValue(&this, pDescriptor);

	public HRESULT GetValueByName(PWSTR Name, WINML_BINDING_DESC** pDescriptor) mut => VT.[Friend]GetValueByName(&this, Name, pDescriptor);

	public HRESULT Clear() mut => VT.[Friend]Clear(&this);
}

[CRepr]struct IWinMLRuntime : IUnknown
{
	public new const Guid IID = .(0xa0425329, 0x40ae, 0x48d9, 0xbc, 0xe3, 0x82, 0x9e, 0xf7, 0xb8, 0xa4, 0x1a);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PWSTR Path, IWinMLModel** ppModel) LoadModel;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, ID3D12Device* device, IWinMLEvaluationContext** ppContext) CreateEvaluationContext;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IWinMLEvaluationContext* pContext) EvaluateModel;
	}


	public HRESULT LoadModel(PWSTR Path, IWinMLModel** ppModel) mut => VT.[Friend]LoadModel(&this, Path, ppModel);

	public HRESULT CreateEvaluationContext(ID3D12Device* device, IWinMLEvaluationContext** ppContext) mut => VT.[Friend]CreateEvaluationContext(&this, device, ppContext);

	public HRESULT EvaluateModel(IWinMLEvaluationContext* pContext) mut => VT.[Friend]EvaluateModel(&this, pContext);
}

[CRepr]struct IWinMLRuntimeFactory : IUnknown
{
	public new const Guid IID = .(0xa807b84d, 0x4ae5, 0x4bc0, 0xa7, 0x6a, 0x94, 0x1a, 0xa2, 0x46, 0xbd, 0x41);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, WINML_RUNTIME_TYPE RuntimeType, IWinMLRuntime** ppRuntime) CreateRuntime;
	}


	public HRESULT CreateRuntime(WINML_RUNTIME_TYPE RuntimeType, IWinMLRuntime** ppRuntime) mut => VT.[Friend]CreateRuntime(&this, RuntimeType, ppRuntime);
}

[CRepr]struct IMLOperatorAttributes : IUnknown
{
	public new const Guid IID = .(0x4b1b1759, 0xec40, 0x466c, 0xaa, 0xb4, 0xbe, 0xb5, 0x34, 0x7f, 0xd2, 0x4c);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR name, MLOperatorAttributeType type, uint32* elementCount) GetAttributeElementCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR name, MLOperatorAttributeType type, uint32 elementCount, uint elementByteSize, void* value) GetAttribute;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR name, uint32 elementIndex, uint32* attributeElementByteSize) GetStringAttributeElementLength;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, PSTR name, uint32 elementIndex, uint32 attributeElementByteSize, uint8* attributeElement) GetStringAttributeElement;
	}


	public HRESULT GetAttributeElementCount(PSTR name, MLOperatorAttributeType type, uint32* elementCount) mut => VT.[Friend]GetAttributeElementCount(&this, name, type, elementCount);

	public HRESULT GetAttribute(PSTR name, MLOperatorAttributeType type, uint32 elementCount, uint elementByteSize, void* value) mut => VT.[Friend]GetAttribute(&this, name, type, elementCount, elementByteSize, value);

	public HRESULT GetStringAttributeElementLength(PSTR name, uint32 elementIndex, uint32* attributeElementByteSize) mut => VT.[Friend]GetStringAttributeElementLength(&this, name, elementIndex, attributeElementByteSize);

	public HRESULT GetStringAttributeElement(PSTR name, uint32 elementIndex, uint32 attributeElementByteSize, uint8* attributeElement) mut => VT.[Friend]GetStringAttributeElement(&this, name, elementIndex, attributeElementByteSize, attributeElement);
}

[CRepr]struct IMLOperatorTensorShapeDescription : IUnknown
{
	public new const Guid IID = .(0xf20e8cbe, 0x3b28, 0x4248, 0xbe, 0x95, 0xf9, 0x6f, 0xbc, 0x6e, 0x46, 0x43);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, uint32* dimensionCount) GetInputTensorDimensionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, uint32 dimensionCount, uint32* dimensions) GetInputTensorShape;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) HasOutputShapeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, uint32* dimensionCount) GetOutputTensorDimensionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, uint32 dimensionCount, uint32* dimensions) GetOutputTensorShape;
	}


	public HRESULT GetInputTensorDimensionCount(uint32 inputIndex, uint32* dimensionCount) mut => VT.[Friend]GetInputTensorDimensionCount(&this, inputIndex, dimensionCount);

	public HRESULT GetInputTensorShape(uint32 inputIndex, uint32 dimensionCount, uint32* dimensions) mut => VT.[Friend]GetInputTensorShape(&this, inputIndex, dimensionCount, dimensions);

	public bool HasOutputShapeDescription() mut => VT.[Friend]HasOutputShapeDescription(&this);

	public HRESULT GetOutputTensorDimensionCount(uint32 outputIndex, uint32* dimensionCount) mut => VT.[Friend]GetOutputTensorDimensionCount(&this, outputIndex, dimensionCount);

	public HRESULT GetOutputTensorShape(uint32 outputIndex, uint32 dimensionCount, uint32* dimensions) mut => VT.[Friend]GetOutputTensorShape(&this, outputIndex, dimensionCount, dimensions);
}

[CRepr]struct IMLOperatorKernelCreationContext : IMLOperatorAttributes
{
	public new const Guid IID = .(0x5459b53d, 0xa0fc, 0x4665, 0xad, 0xdd, 0x70, 0x17, 0x1e, 0xf7, 0xe6, 0x31);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLOperatorAttributes.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetInputCount;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 inputIndex) IsInputValid;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 outputIndex) IsOutputValid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) GetInputEdgeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, MLOperatorEdgeDescription* edgeDescription) GetOutputEdgeDescription;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) HasTensorShapeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorTensorShapeDescription** shapeDescription) GetTensorShapeDescription;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IUnknown** executionObject) GetExecutionInterface;
	}


	public uint32 GetInputCount() mut => VT.[Friend]GetInputCount(&this);

	public uint32 GetOutputCount() mut => VT.[Friend]GetOutputCount(&this);

	public bool IsInputValid(uint32 inputIndex) mut => VT.[Friend]IsInputValid(&this, inputIndex);

	public bool IsOutputValid(uint32 outputIndex) mut => VT.[Friend]IsOutputValid(&this, outputIndex);

	public HRESULT GetInputEdgeDescription(uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) mut => VT.[Friend]GetInputEdgeDescription(&this, inputIndex, edgeDescription);

	public HRESULT GetOutputEdgeDescription(uint32 outputIndex, MLOperatorEdgeDescription* edgeDescription) mut => VT.[Friend]GetOutputEdgeDescription(&this, outputIndex, edgeDescription);

	public bool HasTensorShapeDescription() mut => VT.[Friend]HasTensorShapeDescription(&this);

	public HRESULT GetTensorShapeDescription(IMLOperatorTensorShapeDescription** shapeDescription) mut => VT.[Friend]GetTensorShapeDescription(&this, shapeDescription);

	public void GetExecutionInterface(IUnknown** executionObject) mut => VT.[Friend]GetExecutionInterface(&this, executionObject);
}

[CRepr]struct IMLOperatorTensor : IUnknown
{
	public new const Guid IID = .(0x7fe41f41, 0xf430, 0x440e, 0xae, 0xce, 0x54, 0x41, 0x6d, 0xc8, 0xb9, 0xdb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetDimensionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 dimensionCount, uint32* dimensions) GetShape;
		protected new function [CallingConvention(.Stdcall)] MLOperatorTensorDataType(SelfOuter* self) GetTensorDataType;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsCpuData;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self) IsDataInterface;
		protected new function [CallingConvention(.Stdcall)] void*(SelfOuter* self) GetData;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IUnknown** dataInterface) GetDataInterface;
	}


	public uint32 GetDimensionCount() mut => VT.[Friend]GetDimensionCount(&this);

	public HRESULT GetShape(uint32 dimensionCount, uint32* dimensions) mut => VT.[Friend]GetShape(&this, dimensionCount, dimensions);

	public MLOperatorTensorDataType GetTensorDataType() mut => VT.[Friend]GetTensorDataType(&this);

	public bool IsCpuData() mut => VT.[Friend]IsCpuData(&this);

	public bool IsDataInterface() mut => VT.[Friend]IsDataInterface(&this);

	public void* GetData() mut => VT.[Friend]GetData(&this);

	public void GetDataInterface(IUnknown** dataInterface) mut => VT.[Friend]GetDataInterface(&this, dataInterface);
}

[CRepr]struct IMLOperatorKernelContext : IUnknown
{
	public new const Guid IID = .(0x82536a28, 0xf022, 0x4769, 0x9d, 0x3f, 0x8b, 0x27, 0x8f, 0x84, 0xc0, 0xc3);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, IMLOperatorTensor** tensor) GetInputTensor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, uint32 dimensionCount, uint32* dimensionSizes, IMLOperatorTensor** tensor) GetOutputTensor;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, IMLOperatorTensor** tensor) GetOutputTensor0;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint size, IUnknown** data) AllocateTemporaryData;
		protected new function [CallingConvention(.Stdcall)] void(SelfOuter* self, IUnknown** executionObject) GetExecutionInterface;
	}


	public HRESULT GetInputTensor(uint32 inputIndex, IMLOperatorTensor** tensor) mut => VT.[Friend]GetInputTensor(&this, inputIndex, tensor);

	public HRESULT GetOutputTensor(uint32 outputIndex, uint32 dimensionCount, uint32* dimensionSizes, IMLOperatorTensor** tensor) mut => VT.[Friend]GetOutputTensor(&this, outputIndex, dimensionCount, dimensionSizes, tensor);

	public HRESULT GetOutputTensor(uint32 outputIndex, IMLOperatorTensor** tensor) mut => VT.[Friend]GetOutputTensor0(&this, outputIndex, tensor);

	public HRESULT AllocateTemporaryData(uint size, IUnknown** data) mut => VT.[Friend]AllocateTemporaryData(&this, size, data);

	public void GetExecutionInterface(IUnknown** executionObject) mut => VT.[Friend]GetExecutionInterface(&this, executionObject);
}

[CRepr]struct IMLOperatorKernel : IUnknown
{
	public new const Guid IID = .(0x11c4b4a0, 0xb467, 0x4eaa, 0xa1, 0xa6, 0xb9, 0x61, 0xd8, 0xd0, 0xed, 0x79);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorKernelContext* context) Compute;
	}


	public HRESULT Compute(IMLOperatorKernelContext* context) mut => VT.[Friend]Compute(&this, context);
}

[CRepr]struct IMLOperatorShapeInferenceContext : IMLOperatorAttributes
{
	public new const Guid IID = .(0x105b6b29, 0x5408, 0x4a68, 0x99, 0x59, 0x09, 0xb5, 0x95, 0x5a, 0x34, 0x92);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLOperatorAttributes.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetInputCount;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 inputIndex) IsInputValid;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 outputIndex) IsOutputValid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) GetInputEdgeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, uint32* dimensionCount) GetInputTensorDimensionCount;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, uint32 dimensionCount, uint32* dimensions) GetInputTensorShape;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, uint32 dimensionCount, uint32* dimensions) SetOutputTensorShape;
	}


	public uint32 GetInputCount() mut => VT.[Friend]GetInputCount(&this);

	public uint32 GetOutputCount() mut => VT.[Friend]GetOutputCount(&this);

	public bool IsInputValid(uint32 inputIndex) mut => VT.[Friend]IsInputValid(&this, inputIndex);

	public bool IsOutputValid(uint32 outputIndex) mut => VT.[Friend]IsOutputValid(&this, outputIndex);

	public HRESULT GetInputEdgeDescription(uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) mut => VT.[Friend]GetInputEdgeDescription(&this, inputIndex, edgeDescription);

	public HRESULT GetInputTensorDimensionCount(uint32 inputIndex, uint32* dimensionCount) mut => VT.[Friend]GetInputTensorDimensionCount(&this, inputIndex, dimensionCount);

	public HRESULT GetInputTensorShape(uint32 inputIndex, uint32 dimensionCount, uint32* dimensions) mut => VT.[Friend]GetInputTensorShape(&this, inputIndex, dimensionCount, dimensions);

	public HRESULT SetOutputTensorShape(uint32 outputIndex, uint32 dimensionCount, uint32* dimensions) mut => VT.[Friend]SetOutputTensorShape(&this, outputIndex, dimensionCount, dimensions);
}

[CRepr]struct IMLOperatorTypeInferenceContext : IMLOperatorAttributes
{
	public new const Guid IID = .(0xec893bb1, 0xf938, 0x427b, 0x84, 0x88, 0xc8, 0xdc, 0xf7, 0x75, 0xf1, 0x38);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IMLOperatorAttributes.VTable
	{
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetInputCount;
		protected new function [CallingConvention(.Stdcall)] uint32(SelfOuter* self) GetOutputCount;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 inputIndex) IsInputValid;
		protected new function [CallingConvention(.Stdcall)] bool(SelfOuter* self, uint32 outputIndex) IsOutputValid;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) GetInputEdgeDescription;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, uint32 outputIndex, MLOperatorEdgeDescription* edgeDescription) SetOutputEdgeDescription;
	}


	public uint32 GetInputCount() mut => VT.[Friend]GetInputCount(&this);

	public uint32 GetOutputCount() mut => VT.[Friend]GetOutputCount(&this);

	public bool IsInputValid(uint32 inputIndex) mut => VT.[Friend]IsInputValid(&this, inputIndex);

	public bool IsOutputValid(uint32 outputIndex) mut => VT.[Friend]IsOutputValid(&this, outputIndex);

	public HRESULT GetInputEdgeDescription(uint32 inputIndex, MLOperatorEdgeDescription* edgeDescription) mut => VT.[Friend]GetInputEdgeDescription(&this, inputIndex, edgeDescription);

	public HRESULT SetOutputEdgeDescription(uint32 outputIndex, MLOperatorEdgeDescription* edgeDescription) mut => VT.[Friend]SetOutputEdgeDescription(&this, outputIndex, edgeDescription);
}

[CRepr]struct IMLOperatorTypeInferrer : IUnknown
{
	public new const Guid IID = .(0x781aeb48, 0x9bcb, 0x4797, 0xbf, 0x77, 0x8b, 0xf4, 0x55, 0x21, 0x7b, 0xeb);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorTypeInferenceContext* context) InferOutputTypes;
	}


	public HRESULT InferOutputTypes(IMLOperatorTypeInferenceContext* context) mut => VT.[Friend]InferOutputTypes(&this, context);
}

[CRepr]struct IMLOperatorShapeInferrer : IUnknown
{
	public new const Guid IID = .(0x540be5be, 0xa6c9, 0x40ee, 0x83, 0xf6, 0xd2, 0xb8, 0xb4, 0x0a, 0x77, 0x98);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorShapeInferenceContext* context) InferOutputShapes;
	}


	public HRESULT InferOutputShapes(IMLOperatorShapeInferenceContext* context) mut => VT.[Friend]InferOutputShapes(&this, context);
}

[CRepr]struct IMLOperatorKernelFactory : IUnknown
{
	public new const Guid IID = .(0xef15ad6f, 0x0dc9, 0x4908, 0xab, 0x35, 0xa5, 0x75, 0xa3, 0x0d, 0xfb, 0xf8);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, IMLOperatorKernelCreationContext* context, IMLOperatorKernel** kernel) CreateKernel;
	}


	public HRESULT CreateKernel(IMLOperatorKernelCreationContext* context, IMLOperatorKernel** kernel) mut => VT.[Friend]CreateKernel(&this, context, kernel);
}

[CRepr]struct IMLOperatorRegistry : IUnknown
{
	public new const Guid IID = .(0x2af9dd2d, 0xb516, 0x4672, 0x9a, 0xb5, 0x53, 0x0c, 0x20, 0x84, 0x93, 0xad);

	public new VTable* VT { get => (.)mVT; }

	[CRepr]public struct VTable : IUnknown.VTable
	{
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MLOperatorSetId* operatorSetId, int32 baselineVersion, MLOperatorSchemaDescription** schema, uint32 schemaCount, IMLOperatorTypeInferrer* typeInferrer, IMLOperatorShapeInferrer* shapeInferrer) RegisterOperatorSetSchema;
		protected new function [CallingConvention(.Stdcall)] HRESULT(SelfOuter* self, MLOperatorKernelDescription* operatorKernel, IMLOperatorKernelFactory* operatorKernelFactory, IMLOperatorShapeInferrer* shapeInferrer) RegisterOperatorKernel;
	}


	public HRESULT RegisterOperatorSetSchema(MLOperatorSetId* operatorSetId, int32 baselineVersion, MLOperatorSchemaDescription** schema, uint32 schemaCount, IMLOperatorTypeInferrer* typeInferrer, IMLOperatorShapeInferrer* shapeInferrer) mut => VT.[Friend]RegisterOperatorSetSchema(&this, operatorSetId, baselineVersion, schema, schemaCount, typeInferrer, shapeInferrer);

	public HRESULT RegisterOperatorKernel(MLOperatorKernelDescription* operatorKernel, IMLOperatorKernelFactory* operatorKernelFactory, IMLOperatorShapeInferrer* shapeInferrer) mut => VT.[Friend]RegisterOperatorKernel(&this, operatorKernel, operatorKernelFactory, shapeInferrer);
}

#endregion

#region Functions
public static
{
	[Import("winml.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT WinMLCreateRuntime(IWinMLRuntime** runtime);

	[Import("windows.ai.machinelearning.lib"), CLink, CallingConvention(.Stdcall)]
	public static extern HRESULT MLCreateOperatorRegistry(IMLOperatorRegistry** registry);

}
#endregion
