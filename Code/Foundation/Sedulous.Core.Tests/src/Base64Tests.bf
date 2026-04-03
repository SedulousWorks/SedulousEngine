namespace Sedulous.Core.Tests;

using System;
using System.Collections;
using Sedulous.Core;

class Base64Tests
{
	[Test]
	public static void Encode_Empty()
	{
		let result = scope String();
		Base64.Encode(Span<uint8>(), result);
		Test.Assert(result.IsEmpty);
	}

	[Test]
	public static void Encode_OneByte()
	{
		// "f" -> "Zg=="
		uint8[1] data = .((uint8)'f');
		let result = scope String();
		Base64.Encode(Span<uint8>(&data, 1), result);
		Test.Assert(result.Equals("Zg=="));
	}

	[Test]
	public static void Encode_TwoBytes()
	{
		// "fo" -> "Zm8="
		uint8[2] data = .((uint8)'f', (uint8)'o');
		let result = scope String();
		Base64.Encode(Span<uint8>(&data, 2), result);
		Test.Assert(result.Equals("Zm8="));
	}

	[Test]
	public static void Encode_ThreeBytes()
	{
		// "foo" -> "Zm9v"
		uint8[3] data = .((uint8)'f', (uint8)'o', (uint8)'o');
		let result = scope String();
		Base64.Encode(Span<uint8>(&data, 3), result);
		Test.Assert(result.Equals("Zm9v"));
	}

	[Test]
	public static void Encode_RFC4648_Vector()
	{
		// "Hello" -> "SGVsbG8="
		let str = "Hello";
		let result = scope String();
		Base64.Encode(Span<uint8>((uint8*)str.Ptr, str.Length), result);
		Test.Assert(result.Equals("SGVsbG8="));
	}

	[Test]
	public static void Decode_Empty()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("", decoded) case .Ok);
		Test.Assert(decoded.Count == 0);
	}

	[Test]
	public static void Decode_WithPadding()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("Zg==", decoded) case .Ok);
		Test.Assert(decoded.Count == 1);
		Test.Assert(decoded[0] == (uint8)'f');
	}

	[Test]
	public static void Decode_TwoPadding()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("Zm8=", decoded) case .Ok);
		Test.Assert(decoded.Count == 2);
		Test.Assert(decoded[0] == (uint8)'f');
		Test.Assert(decoded[1] == (uint8)'o');
	}

	[Test]
	public static void Decode_NoPadding()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("Zm9v", decoded) case .Ok);
		Test.Assert(decoded.Count == 3);
		Test.Assert(decoded[0] == (uint8)'f');
		Test.Assert(decoded[1] == (uint8)'o');
		Test.Assert(decoded[2] == (uint8)'o');
	}

	[Test]
	public static void Decode_Roundtrip()
	{
		let original = "The quick brown fox";
		let encoded = scope String();
		Base64.Encode(Span<uint8>((uint8*)original.Ptr, original.Length), encoded);

		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode(encoded, decoded) case .Ok);
		Test.Assert(decoded.Count == original.Length);

		let decodedStr = scope String();
		decodedStr.Append((char8*)decoded.Ptr, decoded.Count);
		Test.Assert(decodedStr.Equals(original));
	}

	[Test]
	public static void Decode_BinaryRoundtrip()
	{
		// Test with binary data including zero bytes
		uint8[8] data = .(0, 1, 127, 128, 200, 255, 42, 0);
		let encoded = scope String();
		Base64.Encode(Span<uint8>(&data, 8), encoded);

		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode(encoded, decoded) case .Ok);
		Test.Assert(decoded.Count == 8);
		for (int i = 0; i < 8; i++)
			Test.Assert(decoded[i] == data[i]);
	}

	[Test]
	public static void Decode_InvalidLength()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("abc", decoded) case .Err);
	}

	[Test]
	public static void Decode_InvalidChars()
	{
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("!@#$", decoded) case .Err);
	}

	[Test]
	public static void Decode_KnownVector()
	{
		// "dGhlIHNhbXBsZSBub25jZQ==" decodes to "the sample nonce"
		let decoded = scope List<uint8>();
		Test.Assert(Base64.Decode("dGhlIHNhbXBsZSBub25jZQ==", decoded) case .Ok);
		let str = scope String();
		str.Append((char8*)decoded.Ptr, decoded.Count);
		Test.Assert(str.Equals("the sample nonce"));
	}
}
