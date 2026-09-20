using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Generic;

/// The serialize-driven form model: assets are not reflected, their fields exist only in
/// Serialize, so a scanning serializer runs the object's own Serialize in write mode and
/// records every named value as an ordinal field list; edits replay Serialize in read mode
/// feeding the recorded values back with one field patched. The versioned envelope a type
/// writes first carries its own version scope, so a version-gated field scans and replays
/// naturally. A patch that changes Serialize's control flow desyncs the replay fail-safe and
/// the caller re-scans.
static class AssetForm
{
	/// Runs the object's Serialize in write mode into a field list; the list owns them.
	public static Result<void, ErrorCode> Scan(ISerializable object, List<AssetFormField> outFields)
	{
		ClearAndDeleteItems(outFields);
		let scanner = scope FormScanSerializer(outFields);
		object.Serialize(scanner);
		return scanner.Status;
	}

	/// Replays the fields through Serialize in read mode with fields[index] replaced by the
	/// new value. On a shape mismatch the replay goes inert from that point; callers re-scan
	/// afterwards regardless.
	public static Result<void, ErrorCode> ApplyField(ISerializable object, List<AssetFormField> fields, int index, AssetFormField newValue)
	{
		if ((index < 0) || (index >= fields.Count))
			return .Err(.InvalidArgument);
		let replayer = scope FormReplaySerializer(fields, index, newValue);
		object.Serialize(replayer);
		return replayer.Status;
	}

	/// True when two scans have the same shape (count, kinds, labels): a shape change after a
	/// patch means a conditional branch flipped and the grid must rebuild.
	public static bool ShapeEquals(List<AssetFormField> a, List<AssetFormField> b)
	{
		if (a.Count != b.Count)
			return false;
		for (int i < a.Count)
		{
			if ((a[i].Kind != b[i].Kind) || (a[i].ScalarKind != b[i].ScalarKind) || (a[i].Label != b[i].Label))
				return false;
		}
		return true;
	}

	/// The index of the field with this label, or -1.
	public static int IndexOf(List<AssetFormField> fields, StringView label)
	{
		for (int i < fields.Count)
		{
			if (fields[i].Label == label)
				return i;
		}
		return -1;
	}
}
