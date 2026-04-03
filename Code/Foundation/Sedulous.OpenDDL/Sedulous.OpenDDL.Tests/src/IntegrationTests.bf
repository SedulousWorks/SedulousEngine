using System;
using Sedulous.OpenDDL;
using static Sedulous.OpenDDL.OpenDDLWriterExtensions;

namespace Sedulous.OpenDDL.Tests;

class IntegrationTests
{
	[Test]
	public static void TestComplexDocument()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			// Vertex data
			float[3] $positions
			{
				{0.0, 0.0, 0.0},
				{1.0, 0.0, 0.0},
				{0.0, 1.0, 0.0}
			}

			// Indices
			uint16 $indices {0, 1, 2}

			// Colors (RGBA)
			float[4] $colors
			{
				{1.0, 0.0, 0.0, 1.0},
				{0.0, 1.0, 0.0, 1.0},
				{0.0, 0.0, 1.0, 1.0}
			}
			""");

		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		Test.Assert(root.ChildCount == 3);

		// Find positions
		let posRef = scope StructureRef(true);
		posRef.AddName("positions");
		let positions = (FloatStructure)doc.FindStructure(posRef);
		Test.Assert(positions != null);
		Test.Assert(positions.ArraySize == 3);
		Test.Assert(positions.SubarrayCount == 3);

		// Find indices
		let idxRef = scope StructureRef(true);
		idxRef.AddName("indices");
		let indices = (UInt16Structure)doc.FindStructure(idxRef);
		Test.Assert(indices != null);
		Test.Assert(indices.DataElementCount == 3);

		// Find colors
		let colRef = scope StructureRef(true);
		colRef.AddName("colors");
		let colors = (FloatStructure)doc.FindStructure(colRef);
		Test.Assert(colors != null);
		Test.Assert(colors.ArraySize == 4);
		Test.Assert(colors.SubarrayCount == 3);
	}

	[Test]
	public static void TestAllPrimitiveTypes()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			bool $boolData {true, false}
			int8 $i8Data {-128, 127}
			int16 $i16Data {-32768, 32767}
			int32 $i32Data {-2147483648, 2147483647}
			int64 $i64Data {-9223372036854775808, 9223372036854775807}
			uint8 $u8Data {0, 255}
			uint16 $u16Data {0, 65535}
			uint32 $u32Data {0, 4294967295}
			uint64 $u64Data {0, 18446744073709551615}
			half $halfData {1.0}
			float $floatData {3.14159}
			double $doubleData {3.141592653589793}
			string $stringData {"test"}
			ref $refData {$boolData, null}
			type $typeData {int32, float}
			""");

		Test.Assert(result == .Ok);

		let root = doc.RootStructure;
		Test.Assert(root.ChildCount == 15);
	}

	[Test]
	public static void TestHexOctalBinary()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			uint32 $hex {0xFF, 0xDEADBEEF, 0x1234_5678}
			uint32 $octal {0o777, 0o12_34}
			uint32 $binary {0b1010, 0b1111_0000}
			""");

		Test.Assert(result == .Ok);

		// Check hex values
		let hexRef = scope StructureRef(true);
		hexRef.AddName("hex");
		let hex = (UInt32Structure)doc.FindStructure(hexRef);
		Test.Assert(hex != null);
		Test.Assert(hex[0] == 0xFF);
		Test.Assert(hex[1] == 0xDEADBEEF);
		Test.Assert(hex[2] == 0x12345678);

		// Check octal values
		let octRef = scope StructureRef(true);
		octRef.AddName("octal");
		let octal = (UInt32Structure)doc.FindStructure(octRef);
		Test.Assert(octal != null);
		Test.Assert(octal[0] == 511);  // 0o777
		Test.Assert(octal[1] == 668);  // 0o1234

		// Check binary values
		let binRef = scope StructureRef(true);
		binRef.AddName("binary");
		let binary = (UInt32Structure)doc.FindStructure(binRef);
		Test.Assert(binary != null);
		Test.Assert(binary[0] == 10);   // 0b1010
		Test.Assert(binary[1] == 240);  // 0b11110000
	}

	[Test]
	public static void TestStringEscapes()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			string $escaped {
				"line1\\nline2",
				"tab\\there",
				"quote\\"here\\"",
				"backslash\\\\here"
			}
			""");

		Test.Assert(result == .Ok);

		let ref1 = scope StructureRef(true);
		ref1.AddName("escaped");
		let strings = (StringStructure)doc.FindStructure(ref1);
		Test.Assert(strings != null);
		Test.Assert(strings.DataElementCount == 4);
		Test.Assert(strings[0] == "line1\nline2");
		Test.Assert(strings[1] == "tab\there");
		Test.Assert(strings[2] == "quote\"here\"");
		Test.Assert(strings[3] == "backslash\\here");
	}

	[Test]
	public static void TestEmptyStructures()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			int32 $empty {}
			""");

		Test.Assert(result == .Ok);

		let ref1 = scope StructureRef(true);
		ref1.AddName("empty");
		let empty = (Int32Structure)doc.FindStructure(ref1);
		Test.Assert(empty != null);
		Test.Assert(empty.DataElementCount == 0);
	}

	[Test]
	public static void TestShortTypeNames()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			b $bool {true}
			i8 $i8 {1}
			i16 $i16 {2}
			i32 $i32 {3}
			i64 $i64 {4}
			u8 $u8 {5}
			u16 $u16 {6}
			u32 $u32 {7}
			u64 $u64 {8}
			h $half {1.0}
			f $float {1.0}
			d $double {1.0}
			s $string {"test"}
			r $ref {null}
			t $type {int32}
			z $base64 {SGVsbG8=}
			""");

		Test.Assert(result == .Ok);
		Test.Assert(doc.RootStructure.ChildCount == 16);
	}

	[Test]
	public static void TestCharacterLiterals()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			int32 $chars {'A', 'B', '\\n', '\\t'}
			""");

		Test.Assert(result == .Ok);

		let ref1 = scope StructureRef(true);
		ref1.AddName("chars");
		let chars = (Int32Structure)doc.FindStructure(ref1);
		Test.Assert(chars != null);
		Test.Assert(chars.DataElementCount == 4);
		Test.Assert(chars[0] == 65);  // 'A'
		Test.Assert(chars[1] == 66);  // 'B'
		Test.Assert(chars[2] == 10);  // '\n'
		Test.Assert(chars[3] == 9);   // '\t'
	}

	[Test]
	public static void TestNegativeValues()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			int32 $negative {-1, -100, -2147483648}
			float $negFloat {-1.5, -3.14}
			""");

		Test.Assert(result == .Ok);

		let ref1 = scope StructureRef(true);
		ref1.AddName("negative");
		let neg = (Int32Structure)doc.FindStructure(ref1);
		Test.Assert(neg != null);
		Test.Assert(neg[0] == -1);
		Test.Assert(neg[1] == -100);
		Test.Assert(neg[2] == int32.MinValue);

		let ref2 = scope StructureRef(true);
		ref2.AddName("negFloat");
		let negF = (FloatStructure)doc.FindStructure(ref2);
		Test.Assert(negF != null);
		Test.Assert(Math.Abs(negF[0] - (-1.5f)) < 0.001f);
		Test.Assert(Math.Abs(negF[1] - (-3.14f)) < 0.01f);
	}

	[Test]
	public static void TestScientificNotation()
	{
		let doc = scope DataDescription();

		let result = doc.ParseText("""
			double $scientific {1.0e10, 2.5E-5, -3.14e+2}
			""");

		Test.Assert(result == .Ok);

		let ref1 = scope StructureRef(true);
		ref1.AddName("scientific");
		let sci = (DoubleStructure)doc.FindStructure(ref1);
		Test.Assert(sci != null);
		Test.Assert(sci.DataElementCount == 3);
		Test.Assert(sci[0] > 9e9 && sci[0] < 1.1e10);
		Test.Assert(sci[1] > 2.4e-5 && sci[1] < 2.6e-5);
		Test.Assert(sci[2] > -320 && sci[2] < -310);
	}

	[Test]
	public static void TestFullRoundTrip()
	{
		let original = """
			float[3] $positions {
				{0.0, 1.0, 2.0},
				{3.0, 4.0, 5.0}
			}
			int32 $indices {0, 1, 2}
			string $name {"test model"}
			bool $visible {true}
			""";

		// Parse original
		let doc1 = scope DataDescription();
		let result1 = doc1.ParseText(original);
		Test.Assert(result1 == .Ok);

		// Write to string
		let output = scope String();
		doc1.RootStructure.ToOpenDDL(output);

		// Parse written output
		let doc2 = scope DataDescription();
		let result2 = doc2.ParseText(output);
		Test.Assert(result2 == .Ok);

		// Verify same number of structures
		Test.Assert(doc1.RootStructure.ChildCount == doc2.RootStructure.ChildCount);

		// Verify positions
		let posRef = scope StructureRef(true);
		posRef.AddName("positions");
		let pos1 = (FloatStructure)doc1.FindStructure(posRef);
		let pos2 = (FloatStructure)doc2.FindStructure(posRef);
		Test.Assert(pos1.DataElementCount == pos2.DataElementCount);

		// Verify indices
		let idxRef = scope StructureRef(true);
		idxRef.AddName("indices");
		let idx1 = (Int32Structure)doc1.FindStructure(idxRef);
		let idx2 = (Int32Structure)doc2.FindStructure(idxRef);
		Test.Assert(idx1.DataElementCount == idx2.DataElementCount);

		// Verify string
		let strRef = scope StructureRef(true);
		strRef.AddName("name");
		let str1 = (StringStructure)doc1.FindStructure(strRef);
		let str2 = (StringStructure)doc2.FindStructure(strRef);
		Test.Assert(str1[0] == str2[0]);

		// Verify bool
		let boolRef = scope StructureRef(true);
		boolRef.AddName("visible");
		let bool1 = (BoolStructure)doc1.FindStructure(boolRef);
		let bool2 = (BoolStructure)doc2.FindStructure(boolRef);
		Test.Assert(bool1[0] == bool2[0]);
	}
}
