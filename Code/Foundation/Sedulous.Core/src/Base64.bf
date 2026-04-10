namespace Sedulous.Core;

using System;
using System.Collections;

/// Base64 encoding and decoding utilities (RFC 4648).
static class Base64
{
	private const char8[64] sEncodeTable = .('A','B','C','D','E','F','G','H','I','J','K','L','M',
		'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
		'a','b','c','d','e','f','g','h','i','j','k','l','m',
		'n','o','p','q','r','s','t','u','v','w','x','y','z',
		'0','1','2','3','4','5','6','7','8','9','+','/');

	/// Encodes binary data to a base64 string.
	public static void Encode(Span<uint8> data, String outStr)
	{
		int i = 0;
		let len = data.Length;

		while (i + 2 < len)
		{
			let b0 = (uint32)data[i];
			let b1 = (uint32)data[i + 1];
			let b2 = (uint32)data[i + 2];
			let triple = (b0 << 16) | (b1 << 8) | b2;
			outStr.Append(sEncodeTable[(triple >> 18) & 0x3F]);
			outStr.Append(sEncodeTable[(triple >> 12) & 0x3F]);
			outStr.Append(sEncodeTable[(triple >> 6) & 0x3F]);
			outStr.Append(sEncodeTable[triple & 0x3F]);
			i += 3;
		}

		let remaining = len - i;
		if (remaining == 1)
		{
			let b0 = (uint32)data[i];
			outStr.Append(sEncodeTable[(b0 >> 2) & 0x3F]);
			outStr.Append(sEncodeTable[(b0 << 4) & 0x3F]);
			outStr.Append('=');
			outStr.Append('=');
		}
		else if (remaining == 2)
		{
			let b0 = (uint32)data[i];
			let b1 = (uint32)data[i + 1];
			let pair = (b0 << 8) | b1;
			outStr.Append(sEncodeTable[(pair >> 10) & 0x3F]);
			outStr.Append(sEncodeTable[(pair >> 4) & 0x3F]);
			outStr.Append(sEncodeTable[(pair << 2) & 0x3F]);
			outStr.Append('=');
		}
	}

	/// Decodes a base64 string to binary data.
	public static Result<void> Decode(StringView str, List<uint8> outData)
	{
		if (str.Length == 0)
			return .Ok;

		if (str.Length % 4 != 0)
			return .Err;

		for (int i = 0; i < str.Length; i += 4)
		{
			let c0 = DecodeChar(str[i]);
			let c1 = DecodeChar(str[i + 1]);
			if (c0 < 0 || c1 < 0)
				return .Err;

			let isPad2 = str[i + 2] == '=';
			let isPad3 = str[i + 3] == '=';

			if (isPad2)
			{
				// Last group, one output byte
				outData.Add((uint8)(((uint32)c0 << 2) | ((uint32)c1 >> 4)));
			}
			else if (isPad3)
			{
				// Last group, two output bytes
				let c2 = DecodeChar(str[i + 2]);
				if (c2 < 0) return .Err;
				outData.Add((uint8)(((uint32)c0 << 2) | ((uint32)c1 >> 4)));
				outData.Add((uint8)((((uint32)c1 & 0xF) << 4) | ((uint32)c2 >> 2)));
			}
			else
			{
				// Full group, three output bytes
				let c2 = DecodeChar(str[i + 2]);
				let c3 = DecodeChar(str[i + 3]);
				if (c2 < 0 || c3 < 0) return .Err;
				outData.Add((uint8)(((uint32)c0 << 2) | ((uint32)c1 >> 4)));
				outData.Add((uint8)((((uint32)c1 & 0xF) << 4) | ((uint32)c2 >> 2)));
				outData.Add((uint8)((((uint32)c2 & 0x3) << 6) | (uint32)c3));
			}
		}

		return .Ok;
	}

	private static int32 DecodeChar(char8 c)
	{
		if (c >= 'A' && c <= 'Z') return (int32)(c - 'A');
		if (c >= 'a' && c <= 'z') return (int32)(c - 'a' + 26);
		if (c >= '0' && c <= '9') return (int32)(c - '0' + 52);
		if (c == '+') return 62;
		if (c == '/') return 63;
		return -1;
	}
}
