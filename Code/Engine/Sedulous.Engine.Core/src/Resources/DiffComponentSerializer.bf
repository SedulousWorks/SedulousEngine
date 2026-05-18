namespace Sedulous.Engine.Core.Resources;

using System;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// IComponentSerializer that only writes properties marked as modified
/// in a given ObjectState. Unmodified properties are silently skipped
/// (the ref value is untouched, and nothing is written to the serializer).
///
/// Used by SceneSerializer to save only the diff for prefab instance entities.
/// Currently unused pending property name alignment between comptime codegen
/// and component Serialize() methods. Will be activated once the naming is
/// unified so LocalModifications tracks the same names that Serialize() uses.
class DiffComponentSerializer : IComponentSerializer
{
	private Serializer mSerializer;
	private int32 mVersion;
	private StringView mComponentTypeId;
	private ObjectState mObjectState;
	private int32 mObjectDepth;

	public bool IsReading => false;
	public bool IsWriting => true;
	public int32 Version => mVersion;

	public this(Serializer serializer, int32 version, StringView componentTypeId, ObjectState objectState)
	{
		mSerializer = serializer;
		mVersion = version;
		mComponentTypeId = componentTypeId;
		mObjectState = objectState;
	}

	private bool IsModified(StringView name)
	{
		return mObjectDepth == 0 && mObjectState.IsPropertyModified(mComponentTypeId, name);
	}

	// --- Primitives (write only if inside a modified structure or top-level modified) ---

	private bool ShouldWrite(StringView name) => mInsideModifiedObject || IsModified(name);

	public void Bool(StringView name, ref bool value)
	{
		if (ShouldWrite(name)) mSerializer.Bool(name, ref value);
	}

	public void Int8(StringView name, ref int8 value)
	{
		if (ShouldWrite(name)) mSerializer.Int8(name, ref value);
	}

	public void Int16(StringView name, ref int16 value)
	{
		if (ShouldWrite(name)) mSerializer.Int16(name, ref value);
	}

	public void Int32(StringView name, ref int32 value)
	{
		if (ShouldWrite(name)) mSerializer.Int32(name, ref value);
	}

	public void Int64(StringView name, ref int64 value)
	{
		if (ShouldWrite(name)) mSerializer.Int64(name, ref value);
	}

	public void UInt8(StringView name, ref uint8 value)
	{
		if (ShouldWrite(name)) mSerializer.UInt8(name, ref value);
	}

	public void UInt16(StringView name, ref uint16 value)
	{
		if (ShouldWrite(name)) mSerializer.UInt16(name, ref value);
	}

	public void UInt32(StringView name, ref uint32 value)
	{
		if (ShouldWrite(name)) mSerializer.UInt32(name, ref value);
	}

	public void UInt64(StringView name, ref uint64 value)
	{
		if (ShouldWrite(name)) mSerializer.UInt64(name, ref value);
	}

	public void Float(StringView name, ref float value)
	{
		if (ShouldWrite(name)) mSerializer.Float(name, ref value);
	}

	public void Double(StringView name, ref double value)
	{
		if (ShouldWrite(name)) mSerializer.Double(name, ref value);
	}

	public void String(StringView name, System.String value)
	{
		if (mInsideModifiedObject || IsModified(name))
			mSerializer.String(name, value);
	}

	public void Guid(StringView name, ref System.Guid value)
	{
		if (mInsideModifiedObject || IsModified(name))
			mSerializer.Guid(name, ref value);
	}

	public void EntityRef(StringView name, ref EntityRef value)
	{
		if (ShouldWrite(name))
		{
			var id = value.PersistentId;
			mSerializer.Guid(name, ref id);
		}
	}

	// --- Nested structures ---

	private bool mInsideModifiedObject;

	public void BeginObject(StringView name)
	{
		if (mObjectDepth == 0)
		{
			if (mObjectState.IsPropertyModified(mComponentTypeId, name))
			{
				mInsideModifiedObject = true;
				mSerializer.BeginObject(name);
			}
		}
		else if (mInsideModifiedObject)
		{
			mSerializer.BeginObject(name);
		}
		mObjectDepth++;
	}

	public void EndObject()
	{
		mObjectDepth--;
		if (mObjectDepth == 0)
		{
			if (mInsideModifiedObject)
			{
				mSerializer.EndObject();
				mInsideModifiedObject = false;
			}
		}
		else if (mInsideModifiedObject)
		{
			mSerializer.EndObject();
		}
	}

	public void BeginArray(StringView name, ref int32 count)
	{
		if (mObjectDepth == 0 && IsModified(name))
		{
			mInsideModifiedObject = true;
			mSerializer.BeginArray(name, ref count);
		}
		else if (mInsideModifiedObject)
		{
			mSerializer.BeginArray(name, ref count);
		}
		mObjectDepth++;
	}

	public void EndArray()
	{
		mObjectDepth--;
		if (mObjectDepth == 0)
		{
			if (mInsideModifiedObject)
			{
				mSerializer.EndArray();
				mInsideModifiedObject = false;
			}
		}
		else if (mInsideModifiedObject)
		{
			mSerializer.EndArray();
		}
	}
}
