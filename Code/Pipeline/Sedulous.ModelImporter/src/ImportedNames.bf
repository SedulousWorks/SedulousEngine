using System;
using Sedulous.Model;

namespace Sedulous.ModelImporter;

/// Naming what an import creates.
///
/// An instance's name becomes a FILE NAME on disk, envelope and sidecars alike, so an authored
/// name that a filesystem would refuse has to be sanitised rather than passed through.
static class ImportedNames
{
	/// The authored name with anything a path cannot carry replaced, or a fallback with the
	/// index when nothing is left.
	public static void ForAsset(StringView authored, StringView fallback, int index, String outName)
	{
		for (int i < authored.Length)
		{
			var c = authored[i];
			switch (c)
			{
			case '/', '\\', ':', '*', '?', '"', '<', '>', '|':
				c = '_';
			default:
				if (c < (char8)0x20)
					c = '_';
			}
			outName.Append(c);
		}

		if (outName.IsEmpty)
			outName.AppendF("{}.{}", fallback, index);
	}

	/// What an imported texture is called.
	///
	/// The FILE STEM comes first and the authored image name second. The file is the identity
	/// a person sees on disk and searches for, and an authored name can disagree with it: a
	/// well known texture library names its packed maps after only one of the channels they
	/// carry, which once produced an asset whose name matched neither its file nor its
	/// contents. An embedded image has no file, so its authored name is all there is.
	public static void ForTexture(ModelTexture texture, int index, String outName)
	{
		StringView stem = default;
		let uri = (StringView)texture.Uri;
		if (!uri.IsEmpty)
		{
			var start = 0;
			for (int i = uri.Length; i > 0; --i)
			{
				let c = uri[i - 1];
				if ((c == '/') || (c == '\\'))
				{
					start = i;
					break;
				}
			}
			var end = uri.Length;
			for (int i = uri.Length; i > start; --i)
			{
				if (uri[i - 1] == '.')
				{
					end = i - 1;
					break;
				}
			}
			if (end > start)
				stem = uri.Substring(start, end - start);
		}

		if (stem.IsEmpty)
			stem = texture.Name;

		ForAsset(stem, "tex", index, outName);
	}

	/// What an imported skeleton is called.
	///
	/// The SAME name the review plan keys on, so a decision made about the skeleton in the
	/// dialog reaches the instance the import claims.
	public static void ForSkeleton(ModelSkin skin, String outName)
	{
		if (((StringView)skin.Name).IsEmpty)
		{
			outName.Append("skeleton");
			return;
		}
		ForAsset(skin.Name, "skeleton", 0, outName);
	}
}
