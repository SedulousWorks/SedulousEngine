using System;
using System.Collections;

namespace Sedulous.OpenDDL;

/// <summary>
/// Base class for all primitive data structures in OpenDDL.
/// Primitive structures contain arrays of homogeneous data values.
/// </summary>
abstract class PrimitiveStructure : Structure
{
	private uint32 mArraySize;
	private bool mStateFlag;

	/// <summary>
	/// Creates a new primitive structure with the specified type.
	/// </summary>
	protected this(StructureType type) : base(type)
	{
		BaseStructureType = StructureTypes.Primitive;
		mArraySize = 0;
		mStateFlag = false;
	}

	/// <summary>
	/// Creates a new primitive structure with the specified type and array configuration.
	/// </summary>
	protected this(StructureType type, uint32 arraySize, bool stateFlag) : base(type)
	{
		BaseStructureType = StructureTypes.Primitive;
		mArraySize = arraySize;
		mStateFlag = stateFlag;
	}

	/// <summary>
	/// Gets the subarray size for this primitive structure.
	/// Zero means the structure contains a flat list of values.
	/// A positive value means the structure contains subarrays of that size.
	/// </summary>
	public uint32 ArraySize
	{
		get => mArraySize;
		set => mArraySize = value;
	}

	/// <summary>
	/// Returns true if this primitive structure uses subarrays (ArraySize > 0).
	/// </summary>
	public bool HasSubarrays => mArraySize > 0;

	/// <summary>
	/// Returns true if this primitive structure contains state data for subarrays.
	/// State data can only exist when ArraySize > 0.
	/// </summary>
	public bool HasStateData
	{
		get => mStateFlag;
		set => mStateFlag = value;
	}

	/// <summary>
	/// Gets the data type of this primitive structure.
	/// </summary>
	public abstract DataType DataType { get; }

	/// <summary>
	/// Gets the total number of data elements in this structure.
	/// </summary>
	public abstract int DataElementCount { get; }

	/// <summary>
	/// Gets the number of subarrays in this structure.
	/// Returns DataElementCount if ArraySize is 0.
	/// </summary>
	public int SubarrayCount
	{
		get
		{
			if (mArraySize == 0)
				return DataElementCount;
			return DataElementCount / (int)mArraySize;
		}
	}

	/// <summary>
	/// Parses the primitive data from text.
	/// </summary>
	protected abstract DataResult ParseData(ref StringView text);

	/// <summary>
	/// Clears all data from this structure.
	/// </summary>
	public abstract void ClearData();
}

/// <summary>
/// Typed primitive structure containing data of a specific type.
/// </summary>
/// <typeparam name="T">The primitive data type.</typeparam>
class DataStructure<T> : PrimitiveStructure
{
	private List<T> mDataArray = new .() ~ delete _;
	private List<uint32> mStateArray = new .() ~ delete _;
	private DataType mDataType;

	public this(DataType dataType) : base((StructureType)(uint32)dataType)
	{
		mDataType = dataType;
	}

	public this(DataType dataType, uint32 arraySize, bool stateFlag = false)
		: base((StructureType)(uint32)dataType, arraySize, stateFlag)
	{
		mDataType = dataType;
	}

	public override DataType DataType => mDataType;

	public override int DataElementCount => mDataArray.Count;

	/// <summary>
	/// Gets the data array.
	/// </summary>
	public List<T> DataArray => mDataArray;

	/// <summary>
	/// Gets the state array (one state per subarray).
	/// </summary>
	public List<uint32> StateArray => mStateArray;

	/// <summary>
	/// Gets a data element at the specified index.
	/// </summary>
	public ref T this[int index] => ref mDataArray[index];

	/// <summary>
	/// Gets a pointer to the beginning of a subarray.
	/// </summary>
	public Span<T> GetSubarray(int index)
	{
		Runtime.Assert(ArraySize > 0, "Structure does not have subarrays");
		let start = index * (int)ArraySize;
		return .(&mDataArray[start], (int)ArraySize);
	}

	/// <summary>
	/// Gets the state associated with a subarray.
	/// </summary>
	public uint32 GetSubarrayState(int index)
	{
		Runtime.Assert(HasStateData, "Structure does not have state data");
		return mStateArray[index];
	}

	/// <summary>
	/// Adds a data element.
	/// </summary>
	public void AddData(T value)
	{
		mDataArray.Add(value);
	}

	/// <summary>
	/// Adds a state value for a subarray.
	/// </summary>
	public void AddState(uint32 state)
	{
		mStateArray.Add(state);
	}

	/// <summary>
	/// Sets the count of data elements.
	/// </summary>
	public void SetDataCount(int count)
	{
		mDataArray.Count = count;
	}

	/// <summary>
	/// Sets the count of state elements.
	/// </summary>
	public void SetStateCount(int count)
	{
		mStateArray.Count = count;
	}

	public override void ClearData()
	{
		mDataArray.Clear();
		mStateArray.Clear();
	}

	protected override DataResult ParseData(ref StringView text)
	{
		// This method should be overridden by specific type implementations
		// or handled by the parser directly based on the data type
		return .PrimitiveInvalidFormat;
	}
}

// Type aliases for specific primitive structures
typealias BoolStructure = DataStructure<bool>;
typealias Int8Structure = DataStructure<int8>;
typealias Int16Structure = DataStructure<int16>;
typealias Int32Structure = DataStructure<int32>;
typealias Int64Structure = DataStructure<int64>;
typealias UInt8Structure = DataStructure<uint8>;
typealias UInt16Structure = DataStructure<uint16>;
typealias UInt32Structure = DataStructure<uint32>;
typealias UInt64Structure = DataStructure<uint64>;
typealias FloatStructure = DataStructure<float>;
typealias DoubleStructure = DataStructure<double>;

/// <summary>
/// Primitive structure for 16-bit half-precision floats.
/// Stored as uint16 internally (IEEE 754 half-precision format).
/// </summary>
typealias HalfStructure = DataStructure<uint16>;

/// <summary>
/// Primitive structure for string data.
/// </summary>
class StringStructure : PrimitiveStructure
{
	private List<String> mDataArray = new .() ~ DeleteContainerAndItems!(_);

	public this() : base((StructureType)(uint32)Sedulous.OpenDDL.DataType.String)
	{
	}

	public this(uint32 arraySize, bool stateFlag = false)
		: base((StructureType)(uint32)Sedulous.OpenDDL.DataType.String, arraySize, stateFlag)
	{
	}

	private List<uint32> mStateArray = new .() ~ delete _;

	public override DataType DataType => .String;
	public override int DataElementCount => mDataArray.Count;

	public List<String> DataArray => mDataArray;
	public List<uint32> StateArray => mStateArray;

	public String this[int index] => mDataArray[index];

	public void AddData(StringView value)
	{
		mDataArray.Add(new String(value));
	}

	public void AddState(uint32 state)
	{
		mStateArray.Add(state);
	}

	public override void ClearData()
	{
		DeleteContainerAndItems!(mDataArray);
		mDataArray = new .();
		mStateArray.Clear();
	}

	protected override DataResult ParseData(ref StringView text)
	{
		return .PrimitiveInvalidFormat;
	}
}

/// <summary>
/// Primitive structure for reference data.
/// </summary>
class RefStructure : PrimitiveStructure
{
	private List<StructureRef> mDataArray = new .() ~ DeleteContainerAndItems!(_);

	public this() : base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Ref)
	{
	}

	public this(uint32 arraySize, bool stateFlag = false)
		: base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Ref, arraySize, stateFlag)
	{
	}

	private List<uint32> mStateArray = new .() ~ delete _;

	public override DataType DataType => .Ref;
	public override int DataElementCount => mDataArray.Count;

	public List<StructureRef> DataArray => mDataArray;
	public List<uint32> StateArray => mStateArray;

	public StructureRef this[int index] => mDataArray[index];

	public void AddData(StructureRef value)
	{
		mDataArray.Add(value);
	}

	public void AddState(uint32 state)
	{
		mStateArray.Add(state);
	}

	public override void ClearData()
	{
		DeleteContainerAndItems!(mDataArray);
		mDataArray = new .();
		mStateArray.Clear();
	}

	protected override DataResult ParseData(ref StringView text)
	{
		return .PrimitiveInvalidFormat;
	}
}

/// <summary>
/// Primitive structure for type data.
/// </summary>
class TypeStructure : PrimitiveStructure
{
	private List<DataType> mDataArray = new .() ~ delete _;

	public this() : base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Type)
	{
	}

	public this(uint32 arraySize, bool stateFlag = false)
		: base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Type, arraySize, stateFlag)
	{
	}

	private List<uint32> mStateArray = new .() ~ delete _;

	public override DataType DataType => .Type;
	public override int DataElementCount => mDataArray.Count;

	public List<DataType> DataArray => mDataArray;
	public List<uint32> StateArray => mStateArray;

	public DataType this[int index] => mDataArray[index];

	public void AddData(DataType value)
	{
		mDataArray.Add(value);
	}

	public void AddState(uint32 state)
	{
		mStateArray.Add(state);
	}

	public override void ClearData()
	{
		mDataArray.Clear();
		mStateArray.Clear();
	}

	protected override DataResult ParseData(ref StringView text)
	{
		return .PrimitiveInvalidFormat;
	}
}

/// <summary>
/// Primitive structure for base64 data.
/// </summary>
class Base64Structure : PrimitiveStructure
{
	private List<List<uint8>> mDataArray = new .() ~ {
		for (let item in _)
			delete item;
		delete _;
	};

	public this() : base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Base64)
	{
	}

	public this(uint32 arraySize, bool stateFlag = false)
		: base((StructureType)(uint32)Sedulous.OpenDDL.DataType.Base64, arraySize, stateFlag)
	{
	}

	private List<uint32> mStateArray = new .() ~ delete _;

	public override DataType DataType => .Base64;
	public override int DataElementCount => mDataArray.Count;

	public List<List<uint8>> DataArray => mDataArray;
	public List<uint32> StateArray => mStateArray;

	public List<uint8> this[int index] => mDataArray[index];

	public void AddData(List<uint8> value)
	{
		mDataArray.Add(value);
	}

	public void AddState(uint32 state)
	{
		mStateArray.Add(state);
	}

	public override void ClearData()
	{
		for (let item in mDataArray)
			delete item;
		mDataArray.Clear();
		mStateArray.Clear();
	}

	protected override DataResult ParseData(ref StringView text)
	{
		return .PrimitiveInvalidFormat;
	}
}
