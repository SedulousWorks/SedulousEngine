using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App.Tests;

/// The plan view edits the external plan in place: check boxes live, names on sync.
static class ImportPlanViewTests
{
	private static void Collect<T>(View view, List<T> outViews) where T : View
	{
		if (let match = view as T)
			outViews.Add(match);
		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				Collect<T>(group.GetChildAt(i), outViews);
		}
	}

	[Test]
	public static void EditsTheExternalPlanInPlace()
	{
		let plan = scope ImportPlan();
		plan.Add(new ImportPlanEntry(.Mesh, "body", "body"));
		plan.Add(new ImportPlanEntry(.AnimationClip, "walk", "walk"));
		plan.Add(new ImportPlanEntry(.AnimationClip, "run", "run"));

		let view = new ImportPlanView(plan);
		defer view.ReleaseRef();

		// Per-entry enable check boxes write straight into the plan; the section check-all
		// drives every row of its kind. The tree holds [Meshes header][mesh row][Clips
		// header][clip row][clip row].
		let checks = scope List<CheckBox>();
		Collect<CheckBox>(view, checks);
		Test.Assert(checks.Count == 5, "2 section headers + 3 entry rows");

		// The clips header is the third check box; unchecking it disables both clips and
		// not the mesh.
		checks[2].IsChecked.Value = false;
		Test.Assert(plan.Entries[0].Enabled);
		Test.Assert(!plan.Entries[1].Enabled);
		Test.Assert(!plan.Entries[2].Enabled);

		// Renamed through the row editor; SyncNames writes it back into the plan.
		let editors = scope List<EditText>();
		Collect<EditText>(view, editors);
		Test.Assert(editors.Count == 3);
		editors[0].SetText("hero_body");
		view.SyncNames();
		Test.Assert(plan.Entries[0].TargetName == "hero_body");
		Test.Assert(plan.Entries[1].TargetName == "walk", "untouched rows keep their names");
	}
}
