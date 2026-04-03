using System;
using System.Collections;
using Sedulous.OpenDDL;
using Sedulous.Serialization;
using static Sedulous.OpenDDL.OpenDDLWriterExtensions;

namespace Sedulous.Serialization.OpenDDL;

/// DataDescription that recognizes the structure types used by OpenDDLSerializer.
/// This prevents the parser from deleting "Obj_" and "Arr_" structures as unknown.
class SerializerDataDescription : DataDescription
{
	public override Structure CreateStructure(StringView identifier)
	{
		// Recognize the structure types used by OpenDDLSerializer
		if (identifier == "Obj_")
			return new Structure(StructureTypes.MakeFourCC("Obj_"));
		if (identifier == "Arr_")
			return new Structure(StructureTypes.MakeFourCC("Arr_"));
		return base.CreateStructure(identifier);
	}
}

/// OpenDDL-based serializer implementation.
/// Serializes data to and from the OpenDDL format.
class OpenDDLSerializer : Serializer
{
	// Writer mode state - builds a structure tree
	protected Structure mWriteRoot ~ delete _;
	protected Structure mCurrentWriteStructure;
	protected List<Structure> mWriteStructureStack = new .() ~ delete _;

	// Reader mode state
	protected DataDescription mDocument;
	protected Structure mCurrentStructure;
	protected List<Structure> mStructureStack = new .() ~ delete _;
	protected int mChildIndex;
	protected List<int> mChildIndexStack = new .() ~ delete _;

	/// Creates a serializer in write mode.
	public static OpenDDLSerializer CreateWriter()
	{
		let serializer = new OpenDDLSerializer();
		serializer.mMode = .Write;
		serializer.mWriteRoot = new RootStructure();
		serializer.mCurrentWriteStructure = serializer.mWriteRoot;
		return serializer;
	}

	/// Creates a serializer in read mode from a parsed OpenDDL document.
	public static OpenDDLSerializer CreateReader(DataDescription document)
	{
		let serializer = new OpenDDLSerializer();
		serializer.mMode = .Read;
		serializer.mDocument = document;
		serializer.mCurrentStructure = document.RootStructure;
		serializer.mChildIndex = 0;
		return serializer;
	}

	protected this() { }

	/// Gets the serialized output (write mode only).
	public void GetOutput(String output)
	{
		if (mWriteRoot != null)
		{
			mWriteRoot.ToOpenDDL(output);
		}
	}

	// ---- Helper Methods ----

	private Structure FindNextUnnamedChild()
	{
		if (mCurrentStructure == null)
			return null;

		int32 found = 0;
		for (let child in mCurrentStructure.Children)
		{
			if (child.StructureName.IsEmpty)
			{
				if (found == mChildIndex)
					return child;
				found++;
			}
		}
		return null;
	}

	private Structure FindChildByName(StringView name)
	{
		if (mCurrentStructure == null)
			return null;

		// Try the local name map first (fast O(1) lookup)
		if (let child = mCurrentStructure.FindLocalChild(name))
			return child;

		// Fall back to iteration for structures that might not be in the map
		for (let child in mCurrentStructure.Children)
		{
			if (child.StructureName == name)
				return child;
		}
		return null;
	}

	// ---- Primitive Types ----

	public override SerializationResult Bool(StringView name, ref bool value)
	{
		if (IsWriting)
		{
			let structure = new BoolStructure(.Bool);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let boolStruct = structure as BoolStructure;
			if (boolStruct == null || boolStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = boolStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Int8(StringView name, ref int8 value)
	{
		if (IsWriting)
		{
			let structure = new Int8Structure(.Int8);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int8Structure;
			if (intStruct == null || intStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = intStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Int16(StringView name, ref int16 value)
	{
		if (IsWriting)
		{
			let structure = new Int16Structure(.Int16);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int16Structure;
			if (intStruct == null || intStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = intStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Int32(StringView name, ref int32 value)
	{
		if (IsWriting)
		{
			let structure = new Int32Structure(.Int32);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int32Structure;
			if (intStruct == null || intStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = intStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Int64(StringView name, ref int64 value)
	{
		if (IsWriting)
		{
			let structure = new Int64Structure(.Int64);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int64Structure;
			if (intStruct == null || intStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = intStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult UInt8(StringView name, ref uint8 value)
	{
		if (IsWriting)
		{
			let structure = new UInt8Structure(.UInt8);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let uintStruct = structure as UInt8Structure;
			if (uintStruct == null || uintStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = uintStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult UInt16(StringView name, ref uint16 value)
	{
		if (IsWriting)
		{
			let structure = new UInt16Structure(.UInt16);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let uintStruct = structure as UInt16Structure;
			if (uintStruct == null || uintStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = uintStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult UInt32(StringView name, ref uint32 value)
	{
		if (IsWriting)
		{
			let structure = new UInt32Structure(.UInt32);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let uintStruct = structure as UInt32Structure;
			if (uintStruct == null || uintStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = uintStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult UInt64(StringView name, ref uint64 value)
	{
		if (IsWriting)
		{
			let structure = new UInt64Structure(.UInt64);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let uintStruct = structure as UInt64Structure;
			if (uintStruct == null || uintStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = uintStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Float(StringView name, ref float value)
	{
		if (IsWriting)
		{
			let structure = new FloatStructure(.Float);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let floatStruct = structure as FloatStructure;
			if (floatStruct == null || floatStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = floatStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult Double(StringView name, ref double value)
	{
		if (IsWriting)
		{
			let structure = new DoubleStructure(.Double);
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let doubleStruct = structure as DoubleStructure;
			if (doubleStruct == null || doubleStruct.DataElementCount == 0)
				return .TypeMismatch;

			value = doubleStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult String(StringView name, String value)
	{
		if (IsWriting)
		{
			let structure = new StringStructure();
			structure.SetName(name, false);
			structure.AddData(value);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let stringStruct = structure as StringStructure;
			if (stringStruct == null || stringStruct.DataElementCount == 0)
				return .TypeMismatch;

			value.Clear();
			value.Append(stringStruct[0]);
			return .Ok;
		}
	}

	// ---- Fixed Arrays ----

	public override SerializationResult FixedFloatArray(StringView name, float* data, int32 count)
	{
		if (IsWriting)
		{
			let structure = new FloatStructure(.Float, (uint32)count);
			structure.SetName(name, false);
			for (int32 i = 0; i < count; i++)
				structure.AddData(data[i]);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let floatStruct = structure as FloatStructure;
			if (floatStruct == null)
				return .TypeMismatch;

			if (floatStruct.DataElementCount != count)
				return .ArraySizeMismatch;

			for (int32 i = 0; i < count; i++)
				data[i] = floatStruct[i];

			return .Ok;
		}
	}

	public override SerializationResult FixedInt32Array(StringView name, int32* data, int32 count)
	{
		if (IsWriting)
		{
			let structure = new Int32Structure(.Int32, (uint32)count);
			structure.SetName(name, false);
			for (int32 i = 0; i < count; i++)
				structure.AddData(data[i]);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int32Structure;
			if (intStruct == null)
				return .TypeMismatch;

			if (intStruct.DataElementCount != count)
				return .ArraySizeMismatch;

			for (int32 i = 0; i < count; i++)
				data[i] = intStruct[i];

			return .Ok;
		}
	}

	// ---- Dynamic Arrays ----

	public override SerializationResult ArrayInt32(StringView name, List<int32> values)
	{
		if (IsWriting)
		{
			let structure = new Int32Structure(.Int32);
			structure.SetName(name, false);
			for (let val in values)
				structure.AddData(val);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let intStruct = structure as Int32Structure;
			if (intStruct == null)
				return .TypeMismatch;

			values.Clear();
			for (int i = 0; i < intStruct.DataElementCount; i++)
				values.Add(intStruct[i]);

			return .Ok;
		}
	}

	public override SerializationResult ArrayFloat(StringView name, List<float> values)
	{
		if (IsWriting)
		{
			let structure = new FloatStructure(.Float);
			structure.SetName(name, false);
			for (let val in values)
				structure.AddData(val);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let floatStruct = structure as FloatStructure;
			if (floatStruct == null)
				return .TypeMismatch;

			values.Clear();
			for (int i = 0; i < floatStruct.DataElementCount; i++)
				values.Add(floatStruct[i]);

			return .Ok;
		}
	}

	public override SerializationResult ArrayString(StringView name, List<String> values)
	{
		if (IsWriting)
		{
			let structure = new StringStructure();
			structure.SetName(name, false);
			for (let val in values)
				structure.AddData(val);
			mCurrentWriteStructure.AppendChild(structure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			let stringStruct = structure as StringStructure;
			if (stringStruct == null)
				return .TypeMismatch;

			// Clear and delete old strings
			for (let s in values)
				delete s;
			values.Clear();

			for (int i = 0; i < stringStruct.DataElementCount; i++)
				values.Add(new String(stringStruct[i]));

			return .Ok;
		}
	}

	// ---- Nested Objects ----

	public override SerializationResult BeginObject(StringView name, StringView typeName = default)
	{
		if (IsWriting)
		{
			// Use "Obj_" as the 4-char structure type for objects
			let structure = new Structure(StructureTypes.MakeFourCC("Obj_"));
			structure.SetName(name, false);
			mCurrentWriteStructure.AppendChild(structure);

			// Push current state
			mWriteStructureStack.Add(mCurrentWriteStructure);
			mCurrentWriteStructure = structure;
			return .Ok;
		}
		else
		{
			Structure structure;
			if (name.IsEmpty)
			{
				// Find the next unnamed child using the cursor
				structure = FindNextUnnamedChild();
				if (structure != null)
					mChildIndex++;
			}
			else
			{
				structure = FindChildByName(name);
			}

			if (structure == null)
				return .FieldNotFound;

			// Push current state
			mStructureStack.Add(mCurrentStructure);
			mChildIndexStack.Add(mChildIndex);

			// Enter the new structure
			mCurrentStructure = structure;
			mChildIndex = 0;
			return .Ok;
		}
	}

	public override SerializationResult EndObject()
	{
		if (IsWriting)
		{
			if (mWriteStructureStack.Count == 0)
				return .InvalidData;

			// Pop state
			mCurrentWriteStructure = mWriteStructureStack.PopBack();
			return .Ok;
		}
		else
		{
			if (mStructureStack.Count == 0)
				return .InvalidData;

			// Pop state
			mCurrentStructure = mStructureStack.PopBack();
			mChildIndex = mChildIndexStack.PopBack();
			return .Ok;
		}
	}

	// ---- Collections ----

	public override SerializationResult BeginArray(StringView name, ref int32 count)
	{
		if (IsWriting)
		{
			// Use "Arr_" as the 4-char structure type for arrays
			let structure = new Structure(StructureTypes.MakeFourCC("Arr_"));
			structure.SetName(name, false);
			mCurrentWriteStructure.AppendChild(structure);

			// Push current state
			mWriteStructureStack.Add(mCurrentWriteStructure);
			mCurrentWriteStructure = structure;

			// Write the count
			let countStructure = new Int32Structure(.Int32);
			countStructure.SetName("_count", false);
			countStructure.AddData(count);
			mCurrentWriteStructure.AppendChild(countStructure);
			return .Ok;
		}
		else
		{
			let structure = FindChildByName(name);
			if (structure == null)
				return .FieldNotFound;

			// Push current state
			mStructureStack.Add(mCurrentStructure);
			mChildIndexStack.Add(mChildIndex);

			// Enter the array structure
			mCurrentStructure = structure;
			mChildIndex = 0;

			// Read the count
			let countStructure = FindChildByName("_count");
			if (countStructure == null)
				return .InvalidData;

			let intStruct = countStructure as Int32Structure;
			if (intStruct == null || intStruct.DataElementCount == 0)
				return .TypeMismatch;

			count = intStruct[0];
			return .Ok;
		}
	}

	public override SerializationResult EndArray()
	{
		return EndObject();
	}

	// ---- Utility ----

	public override bool HasField(StringView name)
	{
		if (IsWriting)
			return false;
		return FindChildByName(name) != null;
	}

	public override void GetFieldNames(List<String> outNames)
	{
		if (IsWriting || mCurrentStructure == null)
			return;
		for (let child in mCurrentStructure.Children)
		{
			if (child.StructureName.Length > 0)
				outNames.Add(new String(child.StructureName));
		}
	}

	public override bool CaptureScope(String output, StringView excludeField = default)
	{
		if (!IsReading || mCurrentStructure == null)
			return false;

		for (let child in mCurrentStructure.Children)
		{
			if (!excludeField.IsEmpty && child.StructureName == excludeField)
				continue;
			child.StructureToOpenDDL(output);
		}
		return true;
	}

	public override bool RestoreScope(StringView data)
	{
		if (!IsWriting || data.IsEmpty)
			return false;

		// Parse the OpenDDL text
		let doc = scope SerializerDataDescription();
		if (doc.ProcessText(data) != .Ok)
			return false;

		// Collect children first (iterating while modifying is unsafe)
		let children = scope List<Structure>();
		for (let child in doc.RootStructure.Children)
			children.Add(child);

		// Reparent parsed structures into the current write scope
		for (let child in children)
		{
			child.RemoveFromParent();
			mCurrentWriteStructure.AppendChild(child);
		}

		return true;
	}
}
