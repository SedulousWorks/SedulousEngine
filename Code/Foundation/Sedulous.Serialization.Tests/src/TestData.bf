using System;
namespace Sedulous.Serialization.Tests;

/// Test class implementing ISerializable
class TestData : ISerializable
{
	public int32 IntValue;
	public float FloatValue;
	public String StringValue = new .() ~ delete _;
	public bool BoolValue;

	public int32 SerializationVersion => 1;

	public SerializationResult Serialize(Serializer s)
	{
		var result = s.Int32("intValue", ref IntValue);
		if (result != .Ok) return result;

		result = s.Float("floatValue", ref FloatValue);
		if (result != .Ok) return result;

		result = s.String("stringValue", StringValue);
		if (result != .Ok) return result;

		result = s.Bool("boolValue", ref BoolValue);
		if (result != .Ok) return result;

		return .Ok;
	}
}

/// Nested test class
class NestedData : ISerializable
{
	public int32 Value;
	public TestData Child = new .() ~ delete _;

	public int32 SerializationVersion => 1;

	public SerializationResult Serialize(Serializer s)
	{
		var result = s.Int32("value", ref Value);
		if (result != .Ok) return result;

		result = s.Object("child", ref Child);
		if (result != .Ok) return result;

		return .Ok;
	}
}