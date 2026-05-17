namespace Sedulous.Engine.Core;

using System;
using Sedulous.Resources;

/// IComponentSerializer that applies a single property override.
/// When a component calls Serialize(this), only the property matching
/// mTargetProperty gets its value replaced from the override string.
/// All other properties are left untouched (refs not modified).
///
/// Supports primitive types (bool, int, float, string, etc.) and
/// ResourceRef fields. ResourceRef overrides use "guid|path" format.
///
/// Usage:
///   let applicator = scope OverrideApplicator("Speed", "2.5");
///   component.Serialize(applicator);
///   // component.Speed is now 2.5f, all other fields unchanged
class OverrideApplicator : IComponentSerializer
{
	private StringView mTargetProperty;
	private StringView mOverrideValue;
	private int32 mObjectDepth;
	private bool mInsideTargetObject; // True when inside BeginObject for our target (e.g. ResourceRef)

	public bool IsReading => true;
	public bool IsWriting => false;
	public int32 Version => 1;

	public this(StringView targetProperty, StringView overrideValue)
	{
		mTargetProperty = targetProperty;
		mOverrideValue = overrideValue;
	}

	private bool IsMatch(StringView name) => mObjectDepth == 0 && name == mTargetProperty;

	public void Bool(StringView name, ref bool value)
	{
		if (IsMatch(name))
			value = mOverrideValue == "true" || mOverrideValue == "1";
	}

	public void Int8(StringView name, ref int8 value)
	{
		if (IsMatch(name))
			if (int8.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void Int16(StringView name, ref int16 value)
	{
		if (IsMatch(name))
			if (int16.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void Int32(StringView name, ref int32 value)
	{
		if (IsMatch(name))
			if (int32.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void Int64(StringView name, ref int64 value)
	{
		if (IsMatch(name))
			if (int64.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void UInt8(StringView name, ref uint8 value)
	{
		if (IsMatch(name))
			if (uint8.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void UInt16(StringView name, ref uint16 value)
	{
		if (IsMatch(name))
			if (uint16.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void UInt32(StringView name, ref uint32 value)
	{
		if (IsMatch(name))
			if (uint32.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void UInt64(StringView name, ref uint64 value)
	{
		if (IsMatch(name))
			if (uint64.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void Float(StringView name, ref float value)
	{
		if (IsMatch(name))
			if (float.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void Double(StringView name, ref double value)
	{
		if (IsMatch(name))
			if (double.Parse(mOverrideValue) case .Ok(let v)) value = v;
	}

	public void String(StringView name, System.String value)
	{
		if (IsMatch(name))
			value.Set(mOverrideValue);
		// Inside a ResourceRef object, handle the "path" field
		else if (mInsideTargetObject && name == "path")
		{
			let sep = mOverrideValue.IndexOf('|');
			if (sep >= 0)
				value.Set(mOverrideValue[(sep + 1)...]);
			else
				value.Set(mOverrideValue);
		}
	}

	public void Guid(StringView name, ref System.Guid value)
	{
		if (IsMatch(name))
		{
			if (System.Guid.Parse(mOverrideValue) case .Ok(let v)) value = v;
		}
		// Inside a ResourceRef object, handle the "_id" field
		else if (mInsideTargetObject && name == "_id")
		{
			let sep = mOverrideValue.IndexOf('|');
			let guidStr = (sep >= 0) ? mOverrideValue[0..<sep] : mOverrideValue;
			if (System.Guid.Parse(guidStr) case .Ok(let v)) value = v;
		}
	}

	public void EntityRef(StringView name, ref EntityRef value)
	{
		// Entity refs in overrides not supported (would need GUID remapping)
	}

	public void BeginObject(StringView name)
	{
		// Detect ResourceRef override: component calls s.ResourceRef("MeshRef", ref mMeshRef)
		// which expands to BeginObject("MeshRef") → Guid("_id") + String("path") → EndObject()
		if (mObjectDepth == 0 && name == mTargetProperty)
			mInsideTargetObject = true;
		mObjectDepth++;
	}

	public void EndObject()
	{
		mObjectDepth--;
		if (mObjectDepth == 0)
			mInsideTargetObject = false;
	}

	public void BeginArray(StringView name, ref int32 count)
	{
		mObjectDepth++;
	}

	public void EndArray()
	{
		mObjectDepth--;
	}
}
