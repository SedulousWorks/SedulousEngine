using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Texture.Pipeline;

/// Deriving a cubemap's six face paths from any one of them.
///
/// PURE STRING work, with no filesystem in it: pairing it with a load is what tells you the
/// files are actually there.
static class CubemapFaces
{
	/// The naming conventions, each in the order a six layer cube expects: +X, -X, +Y, -Y, +Z,
	/// then -Z.
	private static readonly StringView[5][6] cConventions = .(
		.("px", "nx", "py", "ny", "pz", "nz"),
		.("_px", "_nx", "_py", "_ny", "_pz", "_nz"),
		.("_posx", "_negx", "_posy", "_negy", "_posz", "_negz"),
		.("_right", "_left", "_top", "_bottom", "_front", "_back"),
		.("right", "left", "top", "bottom", "front", "back"));

	/// All six face paths, in cube order, appended to the list. Fails when the path matches no
	/// convention this knows.
	public static Result<void, ErrorCode> Detect(StringView oneFacePath, List<String> outPaths)
	{
		let directory = scope String();
		PathParent(oneFacePath, directory);
		let stem = scope String();
		PathStem(oneFacePath, stem);
		let suffix = scope String();
		PathExtension(oneFacePath, suffix);

		for (let convention in cConventions)
		{
			var matched = -1;
			for (int i < 6)
			{
				if (EndsWithIgnoringCase(stem, convention[i]))
				{
					matched = i;
					break;
				}
			}
			if (matched < 0)
				continue;

			let prefix = StringView(stem, 0, stem.Length - convention[matched].Length);
			ClearAndDeleteItems!(outPaths);
			for (int i < 6)
			{
				let name = scope String();
				name.Append(prefix);
				name.Append(convention[i]);
				name.Append(suffix);

				let full = new String();
				if (directory.IsEmpty)
					full.Set(name);
				else
					PathJoin(directory, name, full);
				outPaths.Add(full);
			}
			return .Ok;
		}
		return .Err(.Unknown);
	}

	private static bool EndsWithIgnoringCase(StringView text, StringView suffix)
	{
		if (text.Length < suffix.Length)
			return false;

		let offset = text.Length - suffix.Length;
		for (int i < suffix.Length)
		{
			var a = text[offset + i];
			var b = suffix[i];
			if ((a >= 'A') && (a <= 'Z'))
				a = (char8)(a + 32);
			if ((b >= 'A') && (b <= 'Z'))
				b = (char8)(b + 32);
			if (a != b)
				return false;
		}
		return true;
	}
}
