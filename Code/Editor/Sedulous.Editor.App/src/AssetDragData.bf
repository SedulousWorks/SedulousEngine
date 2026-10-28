using System;
using System.Collections;
using Sedulous.GUI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

// What assets carry when they are dragged (Raptor's editor-gui spec, 5.2, layers 2 and 7): a GUI
// drag payload of type `asset/instance` holding, for each asset, its guid, its type's name (what a
// target takes it by) and its name (for the preview, and for a refusal's reason). A slot, a
// hierarchy or a page asks whether it takes one before the drop (Takes), naming why not when it
// does not; a group takes them all (ReadAll).

/// An asset a drag carries, read back from its payload.
class AssetDrag
{
	public const String cType = "asset/instance";
	/// A guid's length in its "D" form (00000000-0000-0000-0000-000000000000), as the payload holds it.
	private const int cGuidLength = 36;
	/// The most digits a count or a name's length is read with: enough for any payload, and few
	/// enough that the number cannot overflow an int.
	private const int cMaxDigits = 9;

	public Guid Id;
	/// The instance's type name: the asset type's full name, as the content database stores it.
	public String TypeName = new .() ~ delete _;
	public String Name = new .() ~ delete _;

	public this()
	{
	}

	/// The asset `id`, of the type named `typeName`, called `name`: one of a run to drag.
	public this(Guid id, StringView typeName, StringView name)
	{
		Id = id;
		TypeName.Set(typeName);
		Name.Set(name);
	}

	/// Fills `outPayload` with what dragging the asset carries, as a source fills its request's.
	public static void Payload(Guid id, StringView typeName, StringView name, DragPayload outPayload)
	{
		let text = scope String();
		text.Append("1\n");
		AppendRecord(text, id, typeName, name);
		Fill(outPayload, text, name);
	}

	/// Fills `outPayload` with what dragging `assets` carries (a browser's selection), in order,
	/// labelled by the one or by how many.
	///
	/// The value is one text, where Raptor carries a list of strings, three to an asset: a
	/// payload's Variant frees only the object it owns (a list, not the texts in it) and
	/// DragPayload.Set shares any object but text, so a list would leak its texts or be freed
	/// twice. The text is the count on a line of its own, then a block per asset: its guid (fixed
	/// width), its type's name (a type's name has no line break) and its name's length, each on a
	/// line of its own (the length in bytes, as a String measures it), then the name and a line
	/// break. The name is the one part that may hold a line break, so it is measured rather than
	/// escaped: it travels as it is, and a reader takes exactly its length, never looking inside it
	/// for where it ends.
	public static void Payload(Span<AssetDrag> assets, DragPayload outPayload)
	{
		let text = scope String();
		text.AppendF("{}\n", assets.Length);
		for (let asset in assets)
			AppendRecord(text, asset.Id, asset.TypeName, asset.Name);
		if (assets.Length == 1)
		{
			Fill(outPayload, text, assets[0].Name);
			return;
		}
		Fill(outPayload, text, scope String()..AppendF("{} assets", assets.Length));
	}

	/// Every asset `payload` carries, in order, into `outAssets`, which owns them: what it held is
	/// deleted first. False, `outAssets` empty, when it carries none, or when any part of the run is
	/// not as Payload writes it.
	public static bool ReadAll(DragPayload payload, List<AssetDrag> outAssets)
	{
		ClearAndDeleteItems!(outAssets);
		if ((payload.Type != cType) || !IsText(payload.Value))
			return false;
		if (Parse(TextOf(payload.Value), outAssets))
			return true;
		ClearAndDeleteItems!(outAssets);
		return false;
	}

	/// The first asset `payload` carries, into `outAsset`; false, `outAsset` untouched, when it
	/// carries none.
	public static bool Read(DragPayload payload, AssetDrag outAsset)
	{
		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		if (!ReadAll(payload, all))
			return false;
		outAsset.Set(all[0]);
		return true;
	}

	/// Whether a target of one asset that takes `types` (asset type names, full or short; empty:
	/// any) takes what `payload` carries, its first asset read into `outAsset`; when not, `outWhy`
	/// says so. Several assets are refused with the first still read, so a target refuses them
	/// rather than passing them by as no asset. A type matches by AssetTypeNames.Matches, since an
	/// instance names its type in full and a target most often by its short name.
	public static bool Takes(DragPayload payload, Span<String> types, AssetDrag outAsset, String outWhy)
	{
		let all = scope List<AssetDrag>();
		defer { ClearAndDeleteItems!(all); }
		if (!ReadAll(payload, all))
		{
			outWhy.Set("Not an asset");
			return false;
		}
		outAsset.Set(all[0]);
		if (all.Count > 1)
		{
			outWhy.Set("This takes one asset");
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

	/// This, `other`'s copy.
	private void Set(AssetDrag other)
	{
		Id = other.Id;
		TypeName.Set(other.TypeName);
		Name.Set(other.Name);
	}

	/// One asset's block, as Payload describes it.
	private static void AppendRecord(String text, Guid id, StringView typeName, StringView name)
	{
		System.Diagnostics.Debug.Assert(!typeName.Contains('\n'), "a type's name has no line break");
		id.ToString(text);
		text.Append('\n');
		text.Append(typeName);
		text.AppendF("\n{}\n", name.Length);
		text.Append(name);
		text.Append('\n');
	}

	private static void Fill(DragPayload outPayload, StringView text, StringView label)
	{
		outPayload.Type.Set(cType);
		outPayload.Value.Dispose();
		outPayload.Value = TextVariant(text);
		outPayload.Label.Set(label);
		outPayload.Allowed = DropEffectsLink | DropEffectsCopy | DropEffectsMove;
	}

	/// The run `text` holds, appended to `outAssets`; false at the first part not as Payload writes
	/// it: a count of none, a block short of its guid, type or name, or text past the last block.
	private static bool Parse(StringView text, List<AssetDrag> outAssets)
	{
		int at = 0;
		if (!ReadNumber(text, ref at, let count) || (count == 0))
			return false;
		for (int i < count)
		{
			if ((text.Length - at <= cGuidLength) || (text[at + cGuidLength] != '\n'))
				return false;
			if (!(Guid.Parse(text.Substring(at, cGuidLength)) case .Ok(let id)))
				return false;
			at += cGuidLength + 1;
			let typeEnd = text.IndexOf('\n', at);
			if (typeEnd < 0)
				return false;
			let typeName = text.Substring(at, typeEnd - at);
			at = typeEnd + 1;
			if (!ReadNumber(text, ref at, let nameLength) || (text.Length - at <= nameLength) || (text[at + nameLength] != '\n'))
				return false;
			outAssets.Add(new AssetDrag(id, typeName, text.Substring(at, nameLength)));
			at += nameLength + 1;
		}
		return at == text.Length;
	}

	/// The decimal number at `at` in `text`, its line ended by a break, `at` moved past it; false
	/// when there are no digits there, too many, or anything but digits before the break.
	private static bool ReadNumber(StringView text, ref int at, out int value)
	{
		value = 0;
		int digits = 0;
		while ((at < text.Length) && text[at].IsDigit)
		{
			if (++digits > cMaxDigits)
				return false;
			value = value * 10 + ((int)text[at] - (int)'0');
			at++;
		}
		if ((digits == 0) || (at >= text.Length) || (text[at] != '\n'))
			return false;
		at++;
		return true;
	}
}
