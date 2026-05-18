namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Engine.Core;
using Sedulous.Serialization;
using Sedulous.Resources;
using static Sedulous.Resources.ResourceSerializerExtensions;

/// ComponentSerializerAdapter that records which top-level fields were
/// successfully read from the serializer. Used during prefab override
/// loading to discover which properties were overridden so they can be
/// registered in LocalModifications.
class TrackingComponentSerializer : IComponentSerializer
{
	private Serializer mSerializer;
	private int32 mVersion;
	private int32 mObjectDepth;
	private int32 mSkipDepth; // > 0 when inside a structure that failed to open

	/// Fields that were successfully read at depth 0.
	public List<String> ReadFields = new .() ~ { for (let s in _) delete s; delete _; };

	public bool IsReading => true;
	public bool IsWriting => false;
	public int32 Version => mVersion;

	public this(Serializer serializer, int32 version)
	{
		mSerializer = serializer;
		mVersion = version;
	}

	private bool IsSkipping => mSkipDepth > 0;

	private void TrackIfSuccess(StringView name, SerializationResult result)
	{
		if (mObjectDepth == 0 && result == .Ok)
			ReadFields.Add(new String(name));
	}

	public void Bool(StringView name, ref bool value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Bool(name, ref value));
	}

	public void Int8(StringView name, ref int8 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Int8(name, ref value));
	}

	public void Int16(StringView name, ref int16 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Int16(name, ref value));
	}

	public void Int32(StringView name, ref int32 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Int32(name, ref value));
	}

	public void Int64(StringView name, ref int64 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Int64(name, ref value));
	}

	public void UInt8(StringView name, ref uint8 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.UInt8(name, ref value));
	}

	public void UInt16(StringView name, ref uint16 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.UInt16(name, ref value));
	}

	public void UInt32(StringView name, ref uint32 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.UInt32(name, ref value));
	}

	public void UInt64(StringView name, ref uint64 value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.UInt64(name, ref value));
	}

	public void Float(StringView name, ref float value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Float(name, ref value));
	}

	public void Double(StringView name, ref double value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.Double(name, ref value));
	}

	public void String(StringView name, System.String value)
	{
		if (IsSkipping) return;
		TrackIfSuccess(name, mSerializer.String(name, value));
	}

	public void Guid(StringView name, ref System.Guid value)
	{
		if (IsSkipping) return;
		if (mObjectDepth > 0)
			mSerializer.Guid(name, ref value);
		else
			TrackIfSuccess(name, mSerializer.Guid(name, ref value));
	}

	public void EntityRef(StringView name, ref EntityRef value)
	{
		if (IsSkipping) return;
		var id = value.PersistentId;
		let result = mSerializer.Guid(name, ref id);
		if (result == .Ok)
		{
			value.PersistentId = id;
			value.CachedHandle = .Invalid;
		}
		TrackIfSuccess(name, result);
	}

	public void BeginObject(StringView name)
	{
		if (IsSkipping)
		{
			// Already inside a skipped structure — just track depth
			mSkipDepth++;
			mObjectDepth++;
			return;
		}

		if (mSerializer.BeginObject(name) == .Ok)
		{
			if (mObjectDepth == 0)
				ReadFields.Add(new String(name));
			mObjectDepth++;
		}
		else
		{
			// Object not found — skip everything inside
			mSkipDepth++;
			mObjectDepth++;
		}
	}

	public void EndObject()
	{
		mObjectDepth--;
		if (mSkipDepth > 0)
			mSkipDepth--;
		else
			mSerializer.EndObject();
	}

	public void BeginArray(StringView name, ref int32 count)
	{
		if (IsSkipping)
		{
			mSkipDepth++;
			mObjectDepth++;
			count = 0;
			return;
		}

		if (mSerializer.BeginArray(name, ref count) == .Ok)
		{
			if (mObjectDepth == 0)
				ReadFields.Add(new String(name));
			mObjectDepth++;
		}
		else
		{
			mSkipDepth++;
			mObjectDepth++;
			count = 0;
		}
	}

	public void EndArray()
	{
		mObjectDepth--;
		if (mSkipDepth > 0)
			mSkipDepth--;
		else
			mSerializer.EndArray();
	}
}
