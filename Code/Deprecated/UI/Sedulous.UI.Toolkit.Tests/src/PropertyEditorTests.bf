using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// What every editor shares: the edit transaction, the tooltip, conditional row visibility, and
/// the live display name.
class PropertyEditorTests
{
	/// Exposes the protected transaction methods, which are otherwise only reachable from
	/// inside an editor's own controls.
	private class ProbeEditor : BoolEditor
	{
		public this(StringView name, bool value) : base(name, value) {}

		public void Begin() => BeginEdit();
		public void End() => EndEdit();
		public void Cancel() => CancelEdit();
	}

	[Test]
	public static void ATransactionOpensAndClosesOnce()
	{
		let editor = scope ProbeEditor("Test", false);

		var began = 0;
		var ended = 0;
		editor.OnEditBegin.Add(new [&began](sender) => { began++; });
		editor.OnEditEnd.Add(new [&ended](sender) => { ended++; });

		editor.Begin();
		Test.Assert(began == 1);
		Test.Assert(editor.IsEditing);

		// Opening an open transaction changes nothing, which is what lets focus move between a
		// vector's fields without starting a second edit.
		editor.Begin();
		Test.Assert(began == 1);

		editor.End();
		Test.Assert(ended == 1);
		Test.Assert(!editor.IsEditing);

		// And closing a closed one is equally quiet.
		editor.End();
		Test.Assert(ended == 1);
	}

	[Test]
	public static void CancellingReportsSeparatelyFromEnding()
	{
		let editor = scope ProbeEditor("Test", false);

		var ended = false;
		var cancelled = false;
		editor.OnEditEnd.Add(new [&ended](sender) => { ended = true; });
		editor.OnEditCancelled.Add(new [&cancelled](sender) => { cancelled = true; });

		editor.Begin();
		editor.Cancel();
		Test.Assert(cancelled);
		Test.Assert(!ended, "an abandoned gesture must not look like a completed one");
		Test.Assert(!editor.IsEditing);
	}

	[Test]
	public static void TheTooltipRoundTrips()
	{
		let editor = scope FloatEditor("Turbidity", 3.0);

		Test.Assert(editor.Tooltip.IsEmpty);
		editor.SetTooltip("Preetham haze");
		Test.Assert(editor.Tooltip == "Preetham haze");
	}

	/// Visibility set BEFORE the row exists still applies when it is wired, so a property
	/// hidden at build time never flashes visible for a frame.
	[Test]
	public static void RowVisibilityAppliesWhenTheRowIsWired()
	{
		let editor = scope FloatEditor("Turbidity", 3.0);
		let row = new Label();
		defer row.ReleaseRef();

		Test.Assert(editor.RowVisible);
		editor.SetRowVisible(false);
		Test.Assert(!editor.RowVisible);

		editor.SetRowView(row);
		Test.Assert(row.Visibility == .Gone);

		editor.SetRowVisible(true);
		Test.Assert(row.Visibility == .Visible);
	}

	[Test]
	public static void TheDisplayNameFallsBackToTheIdentity()
	{
		let editor = scope BoolEditor("CastsShadows", false);

		Test.Assert(editor.Name == "CastsShadows");
		Test.Assert(editor.DisplayName == "CastsShadows");

		editor.SetDisplayName("Casts Shadows");
		Test.Assert(editor.DisplayName == "Casts Shadows");
		Test.Assert(editor.Name == "CastsShadows", "the identity does not move");
	}

	/// The grid binds each row's label through the sink, so a display name that changes later,
	/// such as an inspector marking a prefab override, updates the LIVE label rather than a
	/// string nobody reads again.
	[Test]
	public static void DisplayNameChangesReachTheBoundSink()
	{
		let editor = scope ButtonEditor("Revert to Prefab", null);

		let seen = scope String();
		editor.BindDisplayNameSink(new(text) => { seen.Set(text); });
		editor.SetDisplayName("Revert to Prefab \u{25CF}");

		Test.Assert(seen == "Revert to Prefab \u{25CF}");
		Test.Assert(editor.DisplayName == "Revert to Prefab \u{25CF}");
	}
}
