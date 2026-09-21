using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Pipeline.Core;

/// Reading a builder's source bytes, THROUGH THE MOUNT rather than off a path.
///
/// Free functions rather than a base class every builder has to inherit: a Beef interface
/// cannot carry statics, and inheritance would buy nothing but the two helpers below.
static class AssetSource
{
	/// A whole source file, mount relative. The CALLER owns what it filled in.
	public static Result<void, ErrorCode> ReadBytes(AssetBuildContext context,
		StringView fileName, List<uint8> outBytes)
	{
		if (context.Sources == null)
			return .Err(.InvalidArgument);

		let stream = context.Sources.Open(fileName, .Read);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		let size = stream.Size();
		if (size < 0)
			return .Err(.Unknown);

		let start = outBytes.Count;
		outBytes.Count = start + (int)size;
		if ((size > 0) && (stream.Read(.(&outBytes[start], (int)size)) != (int)size))
		{
			outBytes.Count = start;
			return .Err(.Unknown);
		}
		return .Ok;
	}

	/// A whole source text file, mount relative, appended to `outText`.
	public static Result<void, ErrorCode> ReadText(AssetBuildContext context, StringView fileName,
		String outText)
	{
		let bytes = scope List<uint8>();
		if (ReadBytes(context, fileName, bytes) case .Err(let error))
			return .Err(error);

		if (!bytes.IsEmpty)
			outText.Append(StringView((char8*)&bytes[0], bytes.Count));
		return .Ok;
	}
}
