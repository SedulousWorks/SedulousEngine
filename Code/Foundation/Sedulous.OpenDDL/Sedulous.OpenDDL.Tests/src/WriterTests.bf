using System;
using Sedulous.OpenDDL;
using static Sedulous.OpenDDL.OpenDDLWriterExtensions;

namespace Sedulous.OpenDDL.Tests;

class WriterTests
{
	[Test]
	public static void TestWritePrimitiveInt()
	{
		let structure = new Int32Structure(.Int32);
		structure.AddData(1);
		structure.AddData(2);
		structure.AddData(3);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		// Should contain the data type and values
		Test.Assert(output.Contains("int32"));
		Test.Assert(output.Contains("1"));
		Test.Assert(output.Contains("2"));
		Test.Assert(output.Contains("3"));

		delete structure;
	}

	[Test]
	public static void TestWritePrimitiveFloat()
	{
		let structure = new FloatStructure(.Float);
		structure.AddData(1.5f);
		structure.AddData(2.25f);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("float"));

		delete structure;
	}

	[Test]
	public static void TestWriteString()
	{
		let structure = new StringStructure();
		structure.AddData("hello");
		structure.AddData("world");

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("string"));
		Test.Assert(output.Contains("\"hello\""));
		Test.Assert(output.Contains("\"world\""));

		delete structure;
	}

	[Test]
	public static void TestWriteStringEscapes()
	{
		let structure = new StringStructure();
		structure.AddData("line1\nline2");
		structure.AddData("tab\there");

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("\\n"));
		Test.Assert(output.Contains("\\t"));

		delete structure;
	}

	[Test]
	public static void TestWriteSubarray()
	{
		let structure = new Int32Structure(.Int32, 3);
		structure.AddData(1);
		structure.AddData(2);
		structure.AddData(3);
		structure.AddData(4);
		structure.AddData(5);
		structure.AddData(6);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("int32[3]"));
		Test.Assert(output.Contains("{1"));
		Test.Assert(output.Contains("{4"));

		delete structure;
	}

	[Test]
	public static void TestWriteNamed()
	{
		let structure = new Int32Structure(.Int32);
		structure.SetName("myData", true);
		structure.AddData(42);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("$myData"));

		delete structure;
	}

	[Test]
	public static void TestWriteLocalName()
	{
		let structure = new Int32Structure(.Int32);
		structure.SetName("localData", false);
		structure.AddData(42);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("%localData"));

		delete structure;
	}

	[Test]
	public static void TestWriteCompact()
	{
		let structure = new Int32Structure(.Int32);
		structure.AddData(1);
		structure.AddData(2);
		structure.AddData(3);

		let writer = scope OpenDDLWriter();
		writer.CompactMode = true;
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		// Compact mode should not have newlines
		Test.Assert(!output.Contains("\n"));

		delete structure;
	}

	[Test]
	public static void TestWriteRef()
	{
		let structure = new RefStructure();

		let ref1 = new StructureRef(true);
		ref1.AddName("global");
		structure.AddData(ref1);

		let ref2 = new StructureRef(false);
		ref2.AddName("local");
		structure.AddData(ref2);

		let ref3 = new StructureRef();
		// Null ref (empty)
		structure.AddData(ref3);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("$global"));
		Test.Assert(output.Contains("%local"));
		Test.Assert(output.Contains("null"));

		delete structure;
	}

	[Test]
	public static void TestWriteType()
	{
		let structure = new TypeStructure();
		structure.AddData(.Int32);
		structure.AddData(.Float);
		structure.AddData(.String);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("int32"));
		Test.Assert(output.Contains("float"));
		Test.Assert(output.Contains("string"));

		delete structure;
	}

	[Test]
	public static void TestWriteBool()
	{
		let structure = new BoolStructure(.Bool);
		structure.AddData(true);
		structure.AddData(false);

		let writer = scope OpenDDLWriter();
		writer.WriteStructure(structure);

		let output = scope String();
		writer.CopyTo(output);

		Test.Assert(output.Contains("true"));
		Test.Assert(output.Contains("false"));

		delete structure;
	}

	[Test]
	public static void TestRoundTrip()
	{
		let original = "int32 $test {1, 2, 3, 4, 5}";

		// Parse
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(original);
		Test.Assert(parseResult == .Ok);

		// Write
		let output = scope String();
		doc.RootStructure.ToOpenDDL(output);

		// Re-parse
		let doc2 = scope DataDescription();
		let reParseResult = doc2.ParseText(output);
		Test.Assert(reParseResult == .Ok);

		// Compare data
		let struct1 = (Int32Structure)doc.RootStructure.FirstChild;
		let struct2 = (Int32Structure)doc2.RootStructure.FirstChild;

		Test.Assert(struct1.DataElementCount == struct2.DataElementCount);
		for (int i = 0; i < struct1.DataElementCount; i++)
		{
			Test.Assert(struct1[i] == struct2[i]);
		}
	}

	[Test]
	public static void TestRoundTripFloat()
	{
		let original = "float {1.5, 2.25, 3.125}";

		// Parse
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(original);
		Test.Assert(parseResult == .Ok);

		// Write
		let output = scope String();
		doc.RootStructure.ToOpenDDL(output);

		// Re-parse
		let doc2 = scope DataDescription();
		let reParseResult = doc2.ParseText(output);
		Test.Assert(reParseResult == .Ok);

		// Compare data
		let struct1 = (FloatStructure)doc.RootStructure.FirstChild;
		let struct2 = (FloatStructure)doc2.RootStructure.FirstChild;

		Test.Assert(struct1.DataElementCount == struct2.DataElementCount);
		for (int i = 0; i < struct1.DataElementCount; i++)
		{
			Test.Assert(Math.Abs(struct1[i] - struct2[i]) < 0.0001f);
		}
	}

	[Test]
	public static void TestRoundTripString()
	{
		let original = "string {\"hello\", \"world\\ntest\"}";

		// Parse
		let doc = scope DataDescription();
		let parseResult = doc.ParseText(original);
		Test.Assert(parseResult == .Ok);

		// Write
		let output = scope String();
		doc.RootStructure.ToOpenDDL(output);

		// Re-parse
		let doc2 = scope DataDescription();
		let reParseResult = doc2.ParseText(output);
		Test.Assert(reParseResult == .Ok);

		// Compare data
		let struct1 = (StringStructure)doc.RootStructure.FirstChild;
		let struct2 = (StringStructure)doc2.RootStructure.FirstChild;

		Test.Assert(struct1.DataElementCount == struct2.DataElementCount);
		for (int i = 0; i < struct1.DataElementCount; i++)
		{
			Test.Assert(struct1[i] == struct2[i]);
		}
	}
}
