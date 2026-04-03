using System;
using System.Collections;
using Sedulous.OpenDDL;

namespace Sedulous.OpenDDL.Tests;

class LexerTests
{
	[Test]
	public static void TestWhitespaceLength()
	{
		// Empty
		Test.Assert(Lexer.GetWhitespaceLength("") == 0);

		// Spaces and tabs
		Test.Assert(Lexer.GetWhitespaceLength("   hello") == 3);
		Test.Assert(Lexer.GetWhitespaceLength("\t\thello") == 2);
		Test.Assert(Lexer.GetWhitespaceLength(" \t \n hello") == 5);

		// Line comments
		Test.Assert(Lexer.GetWhitespaceLength("// comment\nhello") == 11);
		Test.Assert(Lexer.GetWhitespaceLength("//comment\n  hello") == 12);

		// Block comments
		Test.Assert(Lexer.GetWhitespaceLength("/* comment */hello") == 13);
		Test.Assert(Lexer.GetWhitespaceLength("/* multi\nline */hello") == 16);

		// Mixed
		Test.Assert(Lexer.GetWhitespaceLength("  // line\n/* block */  hello") == 23);
	}

	[Test]
	public static void TestReadIdentifier()
	{
		int len;

		// Valid identifiers
		Test.Assert(Lexer.ReadIdentifier("hello", out len) == .Ok && len == 5);
		Test.Assert(Lexer.ReadIdentifier("_test", out len) == .Ok && len == 5);
		Test.Assert(Lexer.ReadIdentifier("Test123", out len) == .Ok && len == 7);
		Test.Assert(Lexer.ReadIdentifier("a_b_c", out len) == .Ok && len == 5);

		// Identifiers followed by other content
		Test.Assert(Lexer.ReadIdentifier("hello world", out len) == .Ok && len == 5);
		Test.Assert(Lexer.ReadIdentifier("test{}", out len) == .Ok && len == 4);

		// Invalid - starts with digit
		Test.Assert(Lexer.ReadIdentifier("123abc", out len) == .IdentifierEmpty);

		// Invalid - empty
		Test.Assert(Lexer.ReadIdentifier("", out len) == .IdentifierEmpty);
	}

	[Test]
	public static void TestReadDataType()
	{
		int len;
		DataType value;

		// Long names
		Test.Assert(Lexer.ReadDataType("bool", out len, out value) == .Ok && value == .Bool && len == 4);
		Test.Assert(Lexer.ReadDataType("int8", out len, out value) == .Ok && value == .Int8 && len == 4);
		Test.Assert(Lexer.ReadDataType("int16", out len, out value) == .Ok && value == .Int16 && len == 5);
		Test.Assert(Lexer.ReadDataType("int32", out len, out value) == .Ok && value == .Int32 && len == 5);
		Test.Assert(Lexer.ReadDataType("int64", out len, out value) == .Ok && value == .Int64 && len == 5);
		Test.Assert(Lexer.ReadDataType("unsigned_int8", out len, out value) == .Ok && value == .UInt8 && len == 13);
		Test.Assert(Lexer.ReadDataType("uint16", out len, out value) == .Ok && value == .UInt16 && len == 6);
		Test.Assert(Lexer.ReadDataType("float", out len, out value) == .Ok && value == .Float && len == 5);
		Test.Assert(Lexer.ReadDataType("double", out len, out value) == .Ok && value == .Double && len == 6);
		Test.Assert(Lexer.ReadDataType("string", out len, out value) == .Ok && value == .String && len == 6);
		Test.Assert(Lexer.ReadDataType("ref", out len, out value) == .Ok && value == .Ref && len == 3);
		Test.Assert(Lexer.ReadDataType("type", out len, out value) == .Ok && value == .Type && len == 4);
		Test.Assert(Lexer.ReadDataType("base64", out len, out value) == .Ok && value == .Base64 && len == 6);

		// Float variants
		Test.Assert(Lexer.ReadDataType("half", out len, out value) == .Ok && value == .Half && len == 4);
		Test.Assert(Lexer.ReadDataType("float16", out len, out value) == .Ok && value == .Half && len == 7);
		Test.Assert(Lexer.ReadDataType("float32", out len, out value) == .Ok && value == .Float && len == 7);
		Test.Assert(Lexer.ReadDataType("float64", out len, out value) == .Ok && value == .Double && len == 7);
	}

	[Test]
	public static void TestReadBoolLiteral()
	{
		int len;
		bool value;

		// True values
		Test.Assert(Lexer.ReadBoolLiteral("true", out len, out value) == .Ok && value == true && len == 4);
		Test.Assert(Lexer.ReadBoolLiteral("1", out len, out value) == .Ok && value == true && len == 1);

		// False values
		Test.Assert(Lexer.ReadBoolLiteral("false", out len, out value) == .Ok && value == false && len == 5);
		Test.Assert(Lexer.ReadBoolLiteral("0", out len, out value) == .Ok && value == false && len == 1);

		// Invalid
		Test.Assert(Lexer.ReadBoolLiteral("yes", out len, out value) != .Ok);
		Test.Assert(Lexer.ReadBoolLiteral("2", out len, out value) != .Ok);
	}

	[Test]
	public static void TestReadIntegerLiteral()
	{
		int len;
		uint64 value;

		// Decimal
		Test.Assert(Lexer.ReadIntegerLiteral("42", out len, out value) == .Ok);
		Test.Assert(len == 2);
		Test.Assert(value == 42);

		// Hex
		Test.Assert(Lexer.ReadIntegerLiteral("0xFF", out len, out value) == .Ok);
		Test.Assert(len == 4);
		Test.Assert(value == 255);

		// Octal
		Test.Assert(Lexer.ReadIntegerLiteral("0o77", out len, out value) == .Ok);
		Test.Assert(len == 4);
		Test.Assert(value == 63);

		// Binary
		Test.Assert(Lexer.ReadIntegerLiteral("0b1010", out len, out value) == .Ok);
		Test.Assert(len == 6);
		Test.Assert(value == 10);

		// With underscores
		Test.Assert(Lexer.ReadIntegerLiteral("1_000_000", out len, out value) == .Ok);
		Test.Assert(len == 9);
		Test.Assert(value == 1000000);

		// Character literal
		Test.Assert(Lexer.ReadIntegerLiteral("'A'", out len, out value) == .Ok);
		Test.Assert(len == 3);
		Test.Assert(value == 65);
	}

	[Test]
	public static void TestReadFloatLiteral()
	{
		int len;
		double value;

		// Basic decimal
		Test.Assert(Lexer.ReadFloatLiteral("3.14", out len, out value) == .Ok);
		Test.Assert(len == 4);
		Test.Assert(Math.Abs(value - 3.14) < 0.001);

		// Negative
		Test.Assert(Lexer.ReadFloatLiteral("-2.5", out len, out value) == .Ok);
		Test.Assert(len == 4);
		Test.Assert(Math.Abs(value - (-2.5)) < 0.001);

		// Scientific notation
		Test.Assert(Lexer.ReadFloatLiteral("1.5e10", out len, out value) == .Ok);
		Test.Assert(len == 6);
		Test.Assert(value > 1.4e10 && value < 1.6e10);

		// No integer part
		Test.Assert(Lexer.ReadFloatLiteral(".5", out len, out value) == .Ok);
		Test.Assert(len == 2);
		Test.Assert(Math.Abs(value - 0.5) < 0.001);

		// No fraction part
		Test.Assert(Lexer.ReadFloatLiteral("5.", out len, out value) == .Ok);
		Test.Assert(len == 2);
		Test.Assert(Math.Abs(value - 5.0) < 0.001);
	}

	[Test]
	public static void TestReadStringLiteral()
	{
		int len;
		let output = scope String();

		// Simple string
		Test.Assert(Lexer.ReadStringLiteral("\"hello\"", out len, output) == .Ok);
		Test.Assert(len == 7);
		Test.Assert(output == "hello");

		// Escape sequences
		output.Clear();
		Test.Assert(Lexer.ReadStringLiteral("\"line1\\nline2\"", out len, output) == .Ok);
		Test.Assert(output == "line1\nline2");

		// Empty string
		output.Clear();
		Test.Assert(Lexer.ReadStringLiteral("\"\"", out len, output) == .Ok);
		Test.Assert(len == 2);
		Test.Assert(output == "");

		// Hex escape
		output.Clear();
		Test.Assert(Lexer.ReadStringLiteral("\"\\x41\"", out len, output) == .Ok);
		Test.Assert(output == "A");
	}

	[Test]
	public static void TestReadBase64Data()
	{
		int len;
		let output = scope List<uint8>();

		// Simple base64
		Test.Assert(Lexer.ReadBase64Data("SGVsbG8=", out len, output) == .Ok);
		Test.Assert(len == 8);
		Test.Assert(output.Count == 5);
		Test.Assert(output[0] == 'H');
		Test.Assert(output[1] == 'e');
		Test.Assert(output[2] == 'l');
		Test.Assert(output[3] == 'l');
		Test.Assert(output[4] == 'o');

		// No padding
		output.Clear();
		Test.Assert(Lexer.ReadBase64Data("TWFu", out len, output) == .Ok);
		Test.Assert(len == 4);
		Test.Assert(output.Count == 3);
		Test.Assert(output[0] == 'M');
		Test.Assert(output[1] == 'a');
		Test.Assert(output[2] == 'n');
	}
}
