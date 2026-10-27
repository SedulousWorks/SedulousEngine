using System;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// What an asset carries when it is dragged (Raptor's editor-gui spec, 5.2, layer 2): a GUI drag
// payload of type `asset/instance` holding the asset's guid, its type's name (what a target takes
// it by) and its name (for the preview, and for a refusal's reason). A slot, a hierarchy or a page
// asks whether it takes the asset before the drop (Takes), naming why not when it does not.

/// An asset a drag carries, read back from its payload.
class AssetDrag
{
	public const String cType = "asset/instance";
	/// A guid's length in its "D" form (00000000-0000-0000-0000-000000000000), as the payload holds it.
	private const int cGuidLength = 36;

	public Guid Id;
	/// The instance's type name: the asset type's full name, as the content database stores it.
	public String TypeName = new .() ~ delete _;
	public String Name = new .() ~ delete _;

	/// Fills `outPayload` with what dragging the asset carries, as a source fills its request's.
	///
	/// The value is one text, the guid, the type's name and the name on lines of their own, where
	/// Raptor carries a list of three strings: a payload's Variant frees only the object it owns
	/// (a list, not the texts in it) and DragPayload.Set shares any object but text, so a list
	/// would leak its texts or be freed twice. The guid is fixed width and a type's name has no
	/// line break, so the name is whatever follows, line breaks and all.
	public static void Payload(Guid id, StringView typeName, StringView name, DragPayload outPayload)
	{
		let text = scope String();
		id.ToString(text);
		text.Append('\n');
		text.Append(typeName);
		text.Append('\n');
		text.Append(name);
		outPayload.Type.Set(cType);
		outPayload.Value.Dispose();
		outPayload.Value = TextVariant(text);
		outPayload.Label.Set(name);
		outPayload.Allowed = DropEffectsLink | DropEffectsCopy;
	}

	/// The asset `payload` carries, into `outAsset`; false, `outAsset` untouched, when it carries
	/// none.
	public static bool Read(DragPayload payload, AssetDrag outAsset)
	{
		if ((payload.Type != cType) || !IsText(payload.Value))
			return false;
		let text = TextOf(payload.Value);
		if ((text.Length <= cGuidLength) || (text[cGuidLength] != '\n'))
			return false;
		let typeEnd = text.IndexOf('\n', cGuidLength + 1);
		if (typeEnd < 0)
			return false;
		if (!(Guid.Parse(text.Substring(0, cGuidLength)) case .Ok(let id)))
			return false;
		outAsset.Id = id;
		outAsset.TypeName.Set(text.Substring(cGuidLength + 1, typeEnd - cGuidLength - 1));
		outAsset.Name.Set(text.Substring(typeEnd + 1));
		return true;
	}

	/// Whether a target that takes `types` (asset type names, full or short; empty: any) takes
	/// what `payload` carries, read into `outAsset`; when not, `outWhy` says so. A type matches
	/// by AssetTypeNames.Matches, since an instance names its type in full and a target most often
	/// by its short name.
	public static bool Takes(DragPayload payload, Span<String> types, AssetDrag outAsset, String outWhy)
	{
		if (!Read(payload, outAsset))
		{
			outWhy.Set("Not an asset");
			return false;
		}
		if (types.IsEmpty)
			return true;
		for (let type in types)
		{
			if (AssetTypeNames.Matches(outAsset.TypeName, type))
				return true;
		}
		outWhy.Clear();
		outWhy.AppendF("{} is a {}, not one this takes", outAsset.Name, AssetTypeNames.Short(outAsset.TypeName));
		return false;
	}
}
