using System;
using Sedulous.OpenDDL;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;

namespace Sedulous.Resources.Tests;

/// A simple test resource.
class TestResource : Resource
{
	public int32 Value;
	public String Data = new .() ~ delete _;

	public override ResourceType ResourceType => .("test");

	public override int32 SerializationVersion => 1;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		s.Int32("value", ref Value);
		s.String("data", Data);
		return .Ok;
	}
}

class ResourceTests
{
	[Test]
	public static void TestResourceCreation()
	{
		let resource = new TestResource();
		defer delete resource;

		Test.Assert(resource.RefCount == 0);
		Test.Assert(resource.Id != default);
	}

	[Test]
	public static void TestResourceRefCounting()
	{
		let resource = new TestResource();

		Test.Assert(resource.RefCount == 0);

		resource.AddRef();
		Test.Assert(resource.RefCount == 1);

		resource.AddRef();
		Test.Assert(resource.RefCount == 2);

		resource.ReleaseRefNoDelete();
		Test.Assert(resource.RefCount == 1);

		resource.ReleaseRef(); // This will delete
	}

	[Test]
	public static void TestResourceHandle()
	{
		let resource = new TestResource();
		resource.AddRef(); // Keep a ref so we control deletion

		var handle = ResourceHandle<TestResource>(resource);
		Test.Assert(handle.IsValid);
		Test.Assert(handle.Resource == resource);
		Test.Assert(resource.RefCount == 2);

		handle.Release();
		Test.Assert(!handle.IsValid);
		Test.Assert(resource.RefCount == 1);

		resource.ReleaseRef(); // Delete
	}

	[Test]
	public static void TestResourceSerialization()
	{
		// Create a resource
		let original = scope TestResource();
		original.Name.Set("TestResource");
		original.Value = 42;
		original.Data.Set("Hello, World!");

		// Serialize
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		original.Serialize(writer);

		let output = scope String();
		writer.GetOutput(output);

		Test.Assert(output.Length > 0);

		// Deserialize
		let doc = scope DataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		let loaded = scope TestResource();
		loaded.Serialize(reader);

		Test.Assert(loaded.Name == original.Name);
		Test.Assert(loaded.Value == original.Value);
		Test.Assert(loaded.Data == original.Data);
	}
}
