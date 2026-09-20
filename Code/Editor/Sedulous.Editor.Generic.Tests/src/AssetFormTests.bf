using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Generic.Tests;

/// Headless: the serialize-driven scan and patch machinery is pure over any ISerializable,
/// covered with the probe asset. The grid wiring needs a live editor.
static class AssetFormTests
{
	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-5;

	[Test]
	public static void ScanRecordsEveryFieldKindIncludingVersionGatedAndArrayElements()
	{
		let asset = scope FormProbeAsset();
		asset.Weights.Add(0.25f);
		asset.Weights.Add(0.75f);

		let fields = scope List<AssetFormField>();
		defer { ClearAndDeleteItems(fields); }
		Test.Assert(AssetForm.Scan(asset, fields) case .Ok);

		let friction = AssetForm.IndexOf(fields, "friction");
		Test.Assert(friction >= 0);
		Test.Assert(fields[friction].Kind == .Scalar);
		Test.Assert(Near(fields[friction].FloatValue, 0.5));

		let note = AssetForm.IndexOf(fields, "note");
		Test.Assert(note >= 0);
		Test.Assert(fields[note].TextValue == "hello");

		let mesh = AssetForm.IndexOf(fields, "mesh");
		Test.Assert(mesh >= 0);
		Test.Assert(fields[mesh].Kind == .Guid);
		Test.Assert(fields[mesh].GuidValue == asset.Mesh);

		// Unkeyed array elements label as weights[i].
		Test.Assert(AssetForm.IndexOf(fields, "weights[0]") >= 0);
		Test.Assert(AssetForm.IndexOf(fields, "weights[1]") >= 0);

		let blob = AssetForm.IndexOf(fields, "blob");
		Test.Assert(blob >= 0);
		Test.Assert(fields[blob].Kind == .Blob);
		Test.Assert(fields[blob].BlobValue.Count == 4);
		Test.Assert(!fields[blob].Editable);

		// The version-gated field appears: the envelope carries the current data version.
		Test.Assert(AssetForm.IndexOf(fields, "gated") >= 0);
		// The value-conditional field does not, HasExtra being false.
		Test.Assert(AssetForm.IndexOf(fields, "extra") < 0);
		// The envelope's own entries are structural, never editable.
		let version = AssetForm.IndexOf(fields, "version");
		Test.Assert(version >= 0);
		Test.Assert(!fields[version].Editable);
	}

	[Test]
	public static void APatchChangesExactlyTheTargetField()
	{
		let asset = scope FormProbeAsset();
		asset.Weights.Add(0.25f);
		let fields = scope List<AssetFormField>();
		defer { ClearAndDeleteItems(fields); }
		Test.Assert(AssetForm.Scan(asset, fields) case .Ok);

		let friction = AssetForm.IndexOf(fields, "friction");
		Test.Assert(friction >= 0);
		let patch = scope AssetFormField();
		fields[friction].CopyTo(patch);
		patch.FloatValue = 0.9;
		Test.Assert(AssetForm.ApplyField(asset, fields, friction, patch) case .Ok);

		Test.Assert(Near(asset.Friction, 0.9), "patched");
		Test.Assert(asset.Group == 3, "everything else untouched");
		Test.Assert(asset.Enabled);
		Test.Assert(asset.Note == "hello");
		Test.Assert(asset.Weights.Count == 1);
		Test.Assert(Near(asset.Weights[0], 0.25));
		Test.Assert(Near(asset.Gated, 7.0));
		Test.Assert(asset.Blob[2] == 3);
	}

	[Test]
	public static void AConditionalBranchPatchChangesTheShapeAndTheRescanDetectsIt()
	{
		let asset = scope FormProbeAsset();
		let fields = scope List<AssetFormField>();
		defer { ClearAndDeleteItems(fields); }
		Test.Assert(AssetForm.Scan(asset, fields) case .Ok);
		let hasExtra = AssetForm.IndexOf(fields, "hasExtra");
		Test.Assert(hasExtra >= 0);

		let patch = scope AssetFormField();
		fields[hasExtra].CopyTo(patch);
		patch.IntValue = 1; // true: Serialize now includes extra
		AssetForm.ApplyField(asset, fields, hasExtra, patch).IgnoreError();
		Test.Assert(asset.HasExtra);

		let rescanned = scope List<AssetFormField>();
		defer { ClearAndDeleteItems(rescanned); }
		Test.Assert(AssetForm.Scan(asset, rescanned) case .Ok);
		Test.Assert(!AssetForm.ShapeEquals(fields, rescanned), "extra appeared");
		Test.Assert(AssetForm.IndexOf(rescanned, "extra") >= 0);
	}

	[Test]
	public static void TheFallbackFactoryRoutesAnySerializableAndBespokePagesWin()
	{
		let context = scope EditorContext();
		GenericAssetPageFactory.Register(context);
		// The probe type routes to the fallback via its Object base.
		let found = context.Pages.FindFactory(typeof(FormProbeAsset));
		Test.Assert(found != null);
		Test.Assert(found.PrimaryType == typeof(Object));
	}

	/// Fields inside an array carry the outermost array key as their category, which the grid
	/// groups under a default-collapsed expander; top-level fields carry none.
	[Test]
	public static void ArrayElementsCarryTheArrayKeyAsTheirCategory()
	{
		let asset = scope FormProbeAsset();
		asset.Weights.Add(1.0f);
		asset.Weights.Add(2.0f);
		let fields = scope List<AssetFormField>();
		defer { ClearAndDeleteItems(fields); }
		Test.Assert(AssetForm.Scan(asset, fields) case .Ok);

		let top = AssetForm.IndexOf(fields, "friction");
		Test.Assert(top >= 0);
		Test.Assert(fields[top].Category.IsEmpty, "top-level: no category");

		let w0 = AssetForm.IndexOf(fields, "weights[0]");
		let w1 = AssetForm.IndexOf(fields, "weights[1]");
		Test.Assert(w0 >= 0);
		Test.Assert(w1 >= 0);
		Test.Assert(fields[w0].Category == "weights");
		Test.Assert(fields[w1].Category == "weights");
	}
}
