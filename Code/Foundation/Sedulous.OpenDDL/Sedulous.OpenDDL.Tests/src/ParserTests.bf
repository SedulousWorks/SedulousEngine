using System;
using Sedulous.OpenDDL;

namespace Sedulous.OpenDDL.Tests;

class ParserTests
{
	[Test]
	public static void TestParsePrimitiveFlatData()
	{
		let doc = scope DataDescription();

		// Int32 data
		let result1 = doc.ParseText("int32 {1, 2, 3, 4, 5}");
		Test.Assert(result1 == .Ok);

		let root = doc.RootStructure;
		Test.Assert(root.ChildCount == 1);

		let child = root.FirstChild;
		Test.Assert(child.BaseStructureType == StructureTypes.Primitive);

		let intStruct = (Int32Structure)child;
		Test.Assert(intStruct.DataElementCount == 5);
		Test.Assert(intStruct[0] == 1);
		Test.Assert(intStruct[1] == 2);
		Test.Assert(intStruct[2] == 3);
		Test.Assert(intStruct[3] == 4);
		Test.Assert(intStruct[4] == 5);
	}

	[Test]
	public static void TestParsePrimitiveSubarrays()
	{
		let doc = scope DataDescription();

		// Float array with subarrays
		let result = doc.ParseText("float[3] {{1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (FloatStructure)root.FirstChild;

		Test.Assert(child.ArraySize == 3);
		Test.Assert(child.DataElementCount == 6);
		Test.Assert(child.SubarrayCount == 2);

		// First subarray
		let sub1 = child.GetSubarray(0);
		Test.Assert(Math.Abs(sub1[0] - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(sub1[1] - 2.0f) < 0.001f);
		Test.Assert(Math.Abs(sub1[2] - 3.0f) < 0.001f);

		// Second subarray
		let sub2 = child.GetSubarray(1);
		Test.Assert(Math.Abs(sub2[0] - 4.0f) < 0.001f);
		Test.Assert(Math.Abs(sub2[1] - 5.0f) < 0.001f);
		Test.Assert(Math.Abs(sub2[2] - 6.0f) < 0.001f);
	}

	[Test]
	public static void TestParseStringData()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("string {\"hello\", \"world\"}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (StringStructure)root.FirstChild;

		Test.Assert(child.DataElementCount == 2);
		Test.Assert(child[0] == "hello");
		Test.Assert(child[1] == "world");
	}

	[Test]
	public static void TestParseStructureName()
	{
		let doc = scope DataDescription();

		// Global name
		let result1 = doc.ParseText("int32 $myData {42}");
		Test.Assert(result1 == .Ok);

		let root1 = doc.RootStructure;
		let child1 = root1.FirstChild;

		Test.Assert(child1.HasName);
		Test.Assert(child1.StructureName == "myData");
		Test.Assert(child1.IsGlobalName);

		// Find by global reference
		let ref1 = scope StructureRef(true);
		ref1.AddName("myData");
		Test.Assert(doc.FindStructure(ref1) == child1);
	}

	[Test]
	public static void TestParseLocalName()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("int32 %localData {42}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = root.FirstChild;

		Test.Assert(child.HasName);
		Test.Assert(child.StructureName == "localData");
		Test.Assert(!child.IsGlobalName);
	}

	[Test]
	public static void TestParseNestedStructures()
	{
		let doc = scope DataDescription();

		// Note: Unknown custom structure types (like "Parent") are parsed but then
		// removed from the tree along with their children. This is by design.
		// To test nested structures, we would need a derived DataDescription
		// that recognizes "Parent" as a valid structure type.

		// Test that unknown structures are successfully parsed but removed
		let result = doc.ParseText("""
			Parent $root
			{
				int32 $data {1, 2, 3}
				float $values {1.5, 2.5}
			}
			""");
		Test.Assert(result == .Ok);

		// Unknown structures are removed after parsing
		let root = doc.RootStructure;
		Test.Assert(root.ChildCount == 0);

		// Test multiple top-level primitives (which are retained)
		let doc2 = scope DataDescription();
		let result2 = doc2.ParseText("""
			int32 $first {1, 2, 3}
			float $second {1.5, 2.5}
			string $third {"hello"}
			""");
		Test.Assert(result2 == .Ok);

		let root2 = doc2.RootStructure;
		Test.Assert(root2.ChildCount == 3);

		// Check first structure
		let intStruct = (Int32Structure)root2.FirstChild;
		Test.Assert(intStruct != null);
		Test.Assert(intStruct.StructureName == "first");
		Test.Assert(intStruct.DataElementCount == 3);

		// Check second structure
		let floatStruct = (FloatStructure)intStruct.NextSibling;
		Test.Assert(floatStruct != null);
		Test.Assert(floatStruct.StructureName == "second");
		Test.Assert(floatStruct.DataElementCount == 2);

		// Check third structure
		let stringStruct = (StringStructure)floatStruct.NextSibling;
		Test.Assert(stringStruct != null);
		Test.Assert(stringStruct.StructureName == "third");
		Test.Assert(stringStruct.DataElementCount == 1);
		Test.Assert(stringStruct[0] == "hello");
	}

	[Test]
	public static void TestParseMultipleStructures()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			int32 $a {1}
			int32 $b {2}
			int32 $c {3}
			""");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		Test.Assert(root.ChildCount == 3);

		// Find each by name
		let refA = scope StructureRef(true);
		refA.AddName("a");
		let foundA = doc.FindStructure(refA);
		Test.Assert(foundA != null);
		Test.Assert(((Int32Structure)foundA)[0] == 1);

		let refB = scope StructureRef(true);
		refB.AddName("b");
		let foundB = doc.FindStructure(refB);
		Test.Assert(foundB != null);
		Test.Assert(((Int32Structure)foundB)[0] == 2);

		let refC = scope StructureRef(true);
		refC.AddName("c");
		let foundC = doc.FindStructure(refC);
		Test.Assert(foundC != null);
		Test.Assert(((Int32Structure)foundC)[0] == 3);
	}

	[Test]
	public static void TestParseRefData()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("ref {$target, null, %local}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (RefStructure)root.FirstChild;

		Test.Assert(child.DataElementCount == 3);

		// First ref - global
		Test.Assert(child[0].IsGlobal);
		Test.Assert(child[0].Count == 1);
		Test.Assert(child[0][0] == "target");

		// Second ref - null
		Test.Assert(child[1].IsNull);

		// Third ref - local
		Test.Assert(child[2].IsLocal);
		Test.Assert(child[2][0] == "local");
	}

	[Test]
	public static void TestParseTypeData()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("type {int32, float, string}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (TypeStructure)root.FirstChild;

		Test.Assert(child.DataElementCount == 3);
		Test.Assert(child[0] == .Int32);
		Test.Assert(child[1] == .Float);
		Test.Assert(child[2] == .String);
	}

	[Test]
	public static void TestParseBoolData()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("bool {true, false, 1, 0}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (BoolStructure)root.FirstChild;

		Test.Assert(child.DataElementCount == 4);
		Test.Assert(child[0] == true);
		Test.Assert(child[1] == false);
		Test.Assert(child[2] == true);
		Test.Assert(child[3] == false);
	}

	[Test]
	public static void TestParseComments()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			// This is a comment
			int32 {
				1, // inline comment
				/* block comment */ 2,
				3
			}
			""");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (Int32Structure)root.FirstChild;

		Test.Assert(child.DataElementCount == 3);
		Test.Assert(child[0] == 1);
		Test.Assert(child[1] == 2);
		Test.Assert(child[2] == 3);
	}

	[Test]
	public static void TestParseHexValues()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("uint32 {0xFF, 0x100, 0xDEADBEEF}");
		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		let child = (UInt32Structure)root.FirstChild;

		Test.Assert(child.DataElementCount == 3);
		Test.Assert(child[0] == 0xFF);
		Test.Assert(child[1] == 0x100);
		Test.Assert(child[2] == 0xDEADBEEF);
	}

	[Test]
	public static void TestParseError()
	{
		let doc = scope DataDescription();

		// Missing closing brace
		let result1 = doc.ParseText("int32 {1, 2, 3");
		Test.Assert(result1 != .Ok);

		// Custom/unknown structure types are parsed but then removed
		let doc2 = scope DataDescription();
		let result2 = doc2.ParseText("custom_type {}");
		// Unknown structures are parsed OK but removed from the tree
		Test.Assert(result2 == .Ok);
		Test.Assert(doc2.RootStructure.ChildCount == 0);

		// Missing data
		let doc3 = scope DataDescription();
		let result3 = doc3.ParseText("int32 {}");
		Test.Assert(result3 == .Ok);  // Empty data is valid

		// Unclosed string
		let doc4 = scope DataDescription();
		let result4 = doc4.ParseText("string {\"unclosed}");
		Test.Assert(result4 != .Ok);

		// Invalid integer literal
		let doc5 = scope DataDescription();
		let result5 = doc5.ParseText("int32 {abc}");
		Test.Assert(result5 != .Ok);

		// Missing comma between elements
		let doc6 = scope DataDescription();
		let result6 = doc6.ParseText("int32 {1 2 3}");
		Test.Assert(result6 != .Ok);
	}

	[Test]
	public static void TestParseArraySizeError()
	{
		let doc = scope DataDescription();

		// Wrong number of elements in subarray
		let result1 = doc.ParseText("int32[3] {{1, 2}}");
		Test.Assert(result1 == .PrimitiveArrayUnderSize);

		let result2 = doc.ParseText("int32[2] {{1, 2, 3}}");
		Test.Assert(result2 == .PrimitiveArrayOverSize);
	}

	[Test]
	public static void TestParseDuplicateName()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			int32 $same {1}
			int32 $same {2}
			""");
		Test.Assert(result == .StructNameExists);
	}
}
