using System;

namespace Sedulous.Content;

/// Which instance a data stream's file belongs to. A sidecar is "<name>.<stream>.data" (text)
/// or "<name>.<stream>.bin" (binary), and a stream name holds no dot. An instance name may hold
/// one (a second "Rock" is named "Rock.2"), so the dot rule is what makes
/// "Rock.2.geometry.bin" the "geometry" stream of "Rock.2", never a "2.geometry" stream of
/// "Rock".
static class Sidecars
{
	public const String cTextSuffix = ".data";
	public const String cBinarySuffix = ".bin";

	/// A data stream's name: not empty, with no '.', '/' or '\'.
	public static bool IsStreamName(StringView name)
	{
		if (name.IsEmpty)
			return false;
		for (let c in name)
		{
			if ((c == '.') || (c == '/') || (c == '\\'))
				return false;
		}
		return true;
	}

	/// Whether `fileName` is a sidecar of the instance named `instanceName`, and if so its
	/// stream and encoding.
	public static bool MatchSidecar(StringView instanceName, StringView fileName, out StringView stream, out StreamEncoding encoding)
	{
		stream = default;
		StringView stem = default;
		if (!StripSuffix(fileName, out stem, out encoding) || instanceName.IsEmpty)
			return false;

		// "<name>.<stream>": the name, a dot, then a stream name, which has no dot of its own.
		if ((stem.Length <= instanceName.Length + 1) || !stem.StartsWith(instanceName) || (stem[instanceName.Length] != '.'))
			return false;
		let candidate = StringView(stem, instanceName.Length + 1);
		if (!IsStreamName(candidate))
			return false;
		stream = candidate;
		return true;
	}

	/// The instance path (mount-relative, no extension) that owns `file`: the envelope
	/// "<path>.<envelopeExtension>" or a sidecar "<path>.<stream>.data|.bin". Empty when
	/// `file` is neither.
	public static StringView OwnerPathOf(StringView file, StringView envelopeExtension)
	{
		// LastIndexOf gives -1 for a file at the root, whose name starts at 0.
		let nameStart = file.LastIndexOf('/') + 1;
		if (!envelopeExtension.IsEmpty)
		{
			let envelopeLength = envelopeExtension.Length + 1;
			if ((file.Length - envelopeLength > nameStart) && file.EndsWith(envelopeExtension) && (file[file.Length - envelopeLength] == '.'))
				return StringView(file, 0, file.Length - envelopeLength);
		}

		StringView stem = default;
		StreamEncoding encoding = .Binary;
		if (!StripSuffix(file, out stem, out encoding))
			return default;
		// The stream is what follows the stem's last dot; the owner is everything before it.
		let dot = stem.LastIndexOf('.');
		if ((dot <= nameStart) || !IsStreamName(StringView(stem, dot + 1)))
			return default;
		return StringView(stem, 0, dot);
	}

	/// A sidecar's "<owner>.<stream>" without its suffix, and the suffix's encoding; false when
	/// the name ends in neither suffix.
	private static bool StripSuffix(StringView fileName, out StringView stem, out StreamEncoding encoding)
	{
		if (fileName.EndsWith(cTextSuffix))
		{
			stem = StringView(fileName, 0, fileName.Length - cTextSuffix.Length);
			encoding = .Text;
			return true;
		}
		encoding = .Binary;
		if (fileName.EndsWith(cBinarySuffix))
		{
			stem = StringView(fileName, 0, fileName.Length - cBinarySuffix.Length);
			return true;
		}
		stem = default;
		return false;
	}
}
