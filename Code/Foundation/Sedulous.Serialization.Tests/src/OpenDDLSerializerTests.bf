using System;
using System.Collections;
using Sedulous.Serialization;
using Sedulous.Serialization.OpenDDL;
using Sedulous.OpenDDL;

namespace Sedulous.Serialization.Tests;

class OpenDDLSerializerTests
{
	[Test]
	public static void TestWritePrimitives()
	{
		let serializer = OpenDDLSerializer.CreateWriter();
		defer delete serializer;

		int32 intVal = 42;
		float floatVal = 3.14f;
		String strVal = scope .("hello");
		bool boolVal = true;

		Test.Assert(serializer.Int32("myInt", ref intVal) == .Ok);
		Test.Assert(serializer.Float("myFloat", ref floatVal) == .Ok);
		Test.Assert(serializer.String("myString", strVal) == .Ok);
		Test.Assert(serializer.Bool("myBool", ref boolVal) == .Ok);

		let output = scope String();
		serializer.GetOutput(output);

		// Verify output contains expected data
		Test.Assert(output.Contains("int32"));
		Test.Assert(output.Contains("42"));
		Test.Assert(output.Contains("float"));
		Test.Assert(output.Contains("string"));
		Test.Assert(output.Contains("\"hello\""));
		Test.Assert(output.Contains("bool"));
		Test.Assert(output.Contains("true"));
	}

	[Test]
	public static void TestRoundTripPrimitives()
	{
		// Write
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		int32 writeInt = 42;
		float writeFloat = 3.14f;
		String writeStr = scope .("hello world");
		bool writeBool = true;

		writer.Int32("myInt", ref writeInt);
		writer.Float("myFloat", ref writeFloat);
		writer.String("myString", writeStr);
		writer.Bool("myBool", ref writeBool);

		let output = scope String();
		writer.GetOutput(output);

		// Parse and read
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(output);
		Test.Assert(parseResult == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		int32 readInt = 0;
		float readFloat = 0;
		String readStr = scope .();
		bool readBool = false;

		Test.Assert(reader.Int32("myInt", ref readInt) == .Ok);
		Test.Assert(reader.Float("myFloat", ref readFloat) == .Ok);
		Test.Assert(reader.String("myString", readStr) == .Ok);
		Test.Assert(reader.Bool("myBool", ref readBool) == .Ok);

		// Verify values match
		Test.Assert(readInt == writeInt);
		Test.Assert(Math.Abs(readFloat - writeFloat) < 0.001f);
		Test.Assert(readStr == writeStr);
		Test.Assert(readBool == writeBool);
	}

	[Test]
	public static void TestRoundTripObject()
	{
		// Create test data
		let original = scope TestData();
		original.IntValue = 123;
		original.FloatValue = 2.5f;
		original.StringValue.Set("test string");
		original.BoolValue = true;

		// Write
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		TestData writeData = original;
		Test.Assert(writer.Object("data", ref writeData) == .Ok);

		let output = scope String();
		writer.GetOutput(output);

		// Parse with SerializableDataDescription which keeps "Obj_" structures
		let doc = scope SerializableDataDescription();
		let parseResult = doc.ParseText(output);
		Test.Assert(parseResult == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		TestData readData = null;
		Test.Assert(reader.Object("data", ref readData) == .Ok);
		defer delete readData;

		// Verify values match
		Test.Assert(readData.IntValue == original.IntValue);
		Test.Assert(Math.Abs(readData.FloatValue - original.FloatValue) < 0.001f);
		Test.Assert(readData.StringValue == original.StringValue);
		Test.Assert(readData.BoolValue == original.BoolValue);
	}

	[Test]
	public static void TestRoundTripNestedObject()
	{
		// Create test data
		let original = scope NestedData();
		original.Value = 99;
		original.Child.IntValue = 42;
		original.Child.FloatValue = 1.5f;
		original.Child.StringValue.Set("nested");
		original.Child.BoolValue = false;

		// Write
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		NestedData writeData = original;
		Test.Assert(writer.Object("data", ref writeData) == .Ok);

		let output = scope String();
		writer.GetOutput(output);

		// Parse with SerializableDataDescription which keeps "Obj_" structures
		let doc = scope SerializableDataDescription();
		let parseResult = doc.ParseText(output);
		Test.Assert(parseResult == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		NestedData readData = null;
		Test.Assert(reader.Object("data", ref readData) == .Ok);
		defer delete readData;

		// Verify values match
		Test.Assert(readData.Value == original.Value);
		Test.Assert(readData.Child.IntValue == original.Child.IntValue);
		Test.Assert(Math.Abs(readData.Child.FloatValue - original.Child.FloatValue) < 0.001f);
		Test.Assert(readData.Child.StringValue == original.Child.StringValue);
		Test.Assert(readData.Child.BoolValue == original.Child.BoolValue);
	}

	[Test]
	public static void TestRoundTripArrays()
	{
		// Write
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		List<int32> writeInts = scope .() { 1, 2, 3, 4, 5 };
		List<float> writeFloats = scope .() { 1.1f, 2.2f, 3.3f };

		writer.ArrayInt32("ints", writeInts);
		writer.ArrayFloat("floats", writeFloats);

		let output = scope String();
		writer.GetOutput(output);

		// Parse and read
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(output);
		Test.Assert(parseResult == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		List<int32> readInts = scope .();
		List<float> readFloats = scope .();

		Test.Assert(reader.ArrayInt32("ints", readInts) == .Ok);
		Test.Assert(reader.ArrayFloat("floats", readFloats) == .Ok);

		// Verify arrays match
		Test.Assert(readInts.Count == writeInts.Count);
		for (int i = 0; i < readInts.Count; i++)
			Test.Assert(readInts[i] == writeInts[i]);

		Test.Assert(readFloats.Count == writeFloats.Count);
		for (int i = 0; i < readFloats.Count; i++)
			Test.Assert(Math.Abs(readFloats[i] - writeFloats[i]) < 0.001f);
	}

	[Test]
	public static void TestRoundTripFixedArrays()
	{
		// Write
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		float[3] writePosition = .(1.0f, 2.0f, 3.0f);
		int32[4] writeIndices = .(10, 20, 30, 40);

		writer.FixedFloatArray("position", &writePosition[0], 3);
		writer.FixedInt32Array("indices", &writeIndices[0], 4);

		let output = scope String();
		writer.GetOutput(output);

		// Parse and read
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(output);
		Test.Assert(parseResult == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		float[3] readPosition = .();
		int32[4] readIndices = .();

		Test.Assert(reader.FixedFloatArray("position", &readPosition[0], 3) == .Ok);
		Test.Assert(reader.FixedInt32Array("indices", &readIndices[0], 4) == .Ok);

		// Verify arrays match
		for (int i = 0; i < 3; i++)
			Test.Assert(Math.Abs(readPosition[i] - writePosition[i]) < 0.001f);

		for (int i = 0; i < 4; i++)
			Test.Assert(readIndices[i] == writeIndices[i]);
	}

	[Test]
	public static void TestFieldNotFound()
	{
		let doc = scope DataDescription();
		doc.ParseText("int32 $something {42}");

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		int32 value = 0;
		Test.Assert(reader.Int32("nonexistent", ref value) == .FieldNotFound);
	}

	[Test]
	public static void TestHasField()
	{
		let doc = scope DataDescription();
		doc.ParseText("int32 $myField {42}");

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		Test.Assert(reader.HasField("myField"));
		Test.Assert(!reader.HasField("otherField"));
	}

	// ---- ObjectList Tests ----

	[Test]
	public static void TestRoundTripObjectList()
	{
		// Write a list of objects
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		List<TestData> writeList = scope .();
		let item1 = scope TestData();
		item1.IntValue = 10;
		item1.FloatValue = 1.1f;
		item1.StringValue.Set("alpha");
		item1.BoolValue = true;
		writeList.Add(item1);

		let item2 = scope TestData();
		item2.IntValue = 20;
		item2.FloatValue = 2.2f;
		item2.StringValue.Set("beta");
		item2.BoolValue = false;
		writeList.Add(item2);

		let item3 = scope TestData();
		item3.IntValue = 30;
		item3.FloatValue = 3.3f;
		item3.StringValue.Set("gamma");
		item3.BoolValue = true;
		writeList.Add(item3);

		writer.ObjectList("Items", writeList);

		let output = scope String();
		writer.GetOutput(output);

		// Parse and read back
		let doc = scope SerializableDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		List<TestData> readList = scope .();
		defer { for (let item in readList) delete item; }

		Test.Assert(reader.ObjectList("Items", readList) == .Ok);

		// Verify all 3 items read correctly with distinct values
		Test.Assert(readList.Count == 3);

		Test.Assert(readList[0].IntValue == 10);
		Test.Assert(readList[0].StringValue == "alpha");
		Test.Assert(readList[0].BoolValue == true);

		Test.Assert(readList[1].IntValue == 20);
		Test.Assert(readList[1].StringValue == "beta");
		Test.Assert(readList[1].BoolValue == false);

		Test.Assert(readList[2].IntValue == 30);
		Test.Assert(readList[2].StringValue == "gamma");
		Test.Assert(readList[2].BoolValue == true);
	}

	[Test]
	public static void TestObjectListInsideObject()
	{
		// Round-trip an object that contains an ObjectList field
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		let container = scope ListContainerData();
		container.Name.Set("my_list");

		let item1 = new TestData();
		item1.IntValue = 42;
		item1.StringValue.Set("hello");
		container.Items.Add(item1);

		let item2 = new TestData();
		item2.IntValue = 99;
		item2.StringValue.Set("world");
		container.Items.Add(item2);

		ListContainerData writeData = container;
		Test.Assert(writer.Object("data", ref writeData) == .Ok);

		let output = scope String();
		writer.GetOutput(output);

		// Read back
		let doc = scope SerializableDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		ListContainerData readData = null;
		Test.Assert(reader.Object("data", ref readData) == .Ok);
		defer delete readData;

		Test.Assert(readData.Name == "my_list");
		Test.Assert(readData.Items.Count == 2);
		Test.Assert(readData.Items[0].IntValue == 42);
		Test.Assert(readData.Items[0].StringValue == "hello");
		Test.Assert(readData.Items[1].IntValue == 99);
		Test.Assert(readData.Items[1].StringValue == "world");
	}

	[Test]
	public static void TestNestedObjectLists()
	{
		// Round-trip: parent has ObjectList of children, each child has its own ObjectList
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		let parent = scope ParentWithNestedList();
		parent.Id = 1;

		let child1 = new ChildWithSubList();
		child1.Label.Set("group_a");
		let sub1 = new TestData();
		sub1.IntValue = 10;
		sub1.StringValue.Set("a1");
		child1.SubItems.Add(sub1);
		let sub2 = new TestData();
		sub2.IntValue = 11;
		sub2.StringValue.Set("a2");
		child1.SubItems.Add(sub2);
		parent.Children.Add(child1);

		let child2 = new ChildWithSubList();
		child2.Label.Set("group_b");
		let sub3 = new TestData();
		sub3.IntValue = 20;
		sub3.StringValue.Set("b1");
		child2.SubItems.Add(sub3);
		parent.Children.Add(child2);

		ParentWithNestedList writeData = parent;
		Test.Assert(writer.Object("root", ref writeData) == .Ok);

		let output = scope String();
		writer.GetOutput(output);

		// Read back
		let doc = scope SerializableDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		ParentWithNestedList readData = null;
		Test.Assert(reader.Object("root", ref readData) == .Ok);
		defer delete readData;

		Test.Assert(readData.Id == 1);
		Test.Assert(readData.Children.Count == 2);

		Test.Assert(readData.Children[0].Label == "group_a");
		Test.Assert(readData.Children[0].SubItems.Count == 2);
		Test.Assert(readData.Children[0].SubItems[0].IntValue == 10);
		Test.Assert(readData.Children[0].SubItems[0].StringValue == "a1");
		Test.Assert(readData.Children[0].SubItems[1].IntValue == 11);
		Test.Assert(readData.Children[0].SubItems[1].StringValue == "a2");

		Test.Assert(readData.Children[1].Label == "group_b");
		Test.Assert(readData.Children[1].SubItems.Count == 1);
		Test.Assert(readData.Children[1].SubItems[0].IntValue == 20);
		Test.Assert(readData.Children[1].SubItems[0].StringValue == "b1");
	}

	[Test]
	public static void TestObjectListEmpty()
	{
		// Round-trip an empty ObjectList
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		List<TestData> writeList = scope .();
		writer.ObjectList("Items", writeList);

		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializableDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		List<TestData> readList = scope .();
		defer { for (let item in readList) delete item; }

		Test.Assert(reader.ObjectList("Items", readList) == .Ok);
		Test.Assert(readList.Count == 0);
	}

	[Test]
	public static void TestObjectListSingleItem()
	{
		// Round-trip an ObjectList with exactly one item
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		List<TestData> writeList = scope .();
		let item = scope TestData();
		item.IntValue = 77;
		item.FloatValue = 7.7f;
		item.StringValue.Set("single");
		item.BoolValue = true;
		writeList.Add(item);

		writer.ObjectList("Items", writeList);

		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializableDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		List<TestData> readList = scope .();
		defer { for (let item2 in readList) delete item2; }

		Test.Assert(reader.ObjectList("Items", readList) == .Ok);
		Test.Assert(readList.Count == 1);
		Test.Assert(readList[0].IntValue == 77);
		Test.Assert(Math.Abs(readList[0].FloatValue - 7.7f) < 0.001f);
		Test.Assert(readList[0].StringValue == "single");
		Test.Assert(readList[0].BoolValue == true);
	}

	// ---- CaptureScope / RestoreScope Tests ----

	[Test]
	public static void TestCaptureScope_CapturesAllFields()
	{
		// Write some fields into an object scope
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		writer.BeginObject("myObj");
		int32 a = 42;
		float b = 3.14f;
		writer.Int32("fieldA", ref a);
		writer.Float("fieldB", ref b);
		writer.String("fieldC", scope String("hello"));
		writer.EndObject();

		let output = scope String();
		writer.GetOutput(output);

		// Read and capture the scope
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		reader.BeginObject("myObj");
		let captured = scope String();
		Test.Assert(reader.CaptureScope(captured));
		Test.Assert(!captured.IsEmpty);
		reader.EndObject();

		// Restore into a new writer
		let writer2 = OpenDDLSerializer.CreateWriter();
		defer delete writer2;

		writer2.BeginObject("myObj");
		Test.Assert(writer2.RestoreScope(captured));
		writer2.EndObject();

		let output2 = scope String();
		writer2.GetOutput(output2);

		// Read back and verify values survived the roundtrip
		let doc2 = scope SerializerDataDescription();
		Test.Assert(doc2.ParseText(output2) == .Ok);

		let reader2 = OpenDDLSerializer.CreateReader(doc2);
		defer delete reader2;

		reader2.BeginObject("myObj");
		int32 readA = 0;
		float readB = 0;
		let readC = scope String();
		Test.Assert(reader2.Int32("fieldA", ref readA) == .Ok);
		Test.Assert(reader2.Float("fieldB", ref readB) == .Ok);
		Test.Assert(reader2.String("fieldC", readC) == .Ok);
		reader2.EndObject();

		Test.Assert(readA == 42);
		Test.Assert(Math.Abs(readB - 3.14f) < 0.001f);
		Test.Assert(readC == "hello");
	}

	[Test]
	public static void TestCaptureScope_ExcludesField()
	{
		// Write some fields
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		writer.BeginObject("myObj");
		int32 entity = 5;
		int32 value = 99;
		writer.Int32("entity", ref entity);
		writer.Int32("value", ref value);
		writer.EndObject();

		let output = scope String();
		writer.GetOutput(output);

		// Capture excluding "entity"
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		reader.BeginObject("myObj");
		let captured = scope String();
		Test.Assert(reader.CaptureScope(captured, "entity"));
		reader.EndObject();

		// Verify captured text does NOT contain "entity" but does contain "value"
		// Restore and verify only "value" is present
		let writer2 = OpenDDLSerializer.CreateWriter();
		defer delete writer2;

		writer2.BeginObject("myObj");
		Test.Assert(writer2.RestoreScope(captured));
		writer2.EndObject();

		let output2 = scope String();
		writer2.GetOutput(output2);

		let doc2 = scope SerializerDataDescription();
		Test.Assert(doc2.ParseText(output2) == .Ok);

		let reader2 = OpenDDLSerializer.CreateReader(doc2);
		defer delete reader2;

		reader2.BeginObject("myObj");
		Test.Assert(!reader2.HasField("entity"));
		int32 readValue = 0;
		Test.Assert(reader2.Int32("value", ref readValue) == .Ok);
		Test.Assert(readValue == 99);
		reader2.EndObject();
	}

	[Test]
	public static void TestCaptureScope_NestedObject()
	{
		// Write a scope with a nested object
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		writer.BeginObject("outer");
		int32 id = 1;
		writer.Int32("id", ref id);
		writer.BeginObject("inner");
		int32 x = 10;
		int32 y = 20;
		writer.Int32("x", ref x);
		writer.Int32("y", ref y);
		writer.EndObject();
		writer.EndObject();

		let output = scope String();
		writer.GetOutput(output);

		// Capture the outer scope (excluding "id")
		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		reader.BeginObject("outer");
		let captured = scope String();
		Test.Assert(reader.CaptureScope(captured, "id"));
		reader.EndObject();

		// Restore and verify nested object survived
		let writer2 = OpenDDLSerializer.CreateWriter();
		defer delete writer2;

		writer2.BeginObject("outer");
		Test.Assert(writer2.RestoreScope(captured));
		writer2.EndObject();

		let output2 = scope String();
		writer2.GetOutput(output2);

		let doc2 = scope SerializerDataDescription();
		Test.Assert(doc2.ParseText(output2) == .Ok);

		let reader2 = OpenDDLSerializer.CreateReader(doc2);
		defer delete reader2;

		reader2.BeginObject("outer");
		Test.Assert(!reader2.HasField("id"));
		reader2.BeginObject("inner");
		int32 readX = 0;
		int32 readY = 0;
		Test.Assert(reader2.Int32("x", ref readX) == .Ok);
		Test.Assert(reader2.Int32("y", ref readY) == .Ok);
		Test.Assert(readX == 10);
		Test.Assert(readY == 20);
		reader2.EndObject();
		reader2.EndObject();
	}

	[Test]
	public static void TestCaptureScope_EmptyScope()
	{
		// Capture an empty scope
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		writer.BeginObject("empty");
		writer.EndObject();

		let output = scope String();
		writer.GetOutput(output);

		let doc = scope SerializerDataDescription();
		Test.Assert(doc.ParseText(output) == .Ok);

		let reader = OpenDDLSerializer.CreateReader(doc);
		defer delete reader;

		reader.BeginObject("empty");
		let captured = scope String();
		Test.Assert(reader.CaptureScope(captured));
		Test.Assert(captured.IsEmpty);
		reader.EndObject();
	}

	[Test]
	public static void TestRestoreScope_EmptyData()
	{
		let writer = OpenDDLSerializer.CreateWriter();
		defer delete writer;

		writer.BeginObject("obj");
		Test.Assert(!writer.RestoreScope(""));
		writer.EndObject();
	}
}
