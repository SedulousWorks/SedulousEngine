using System;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Pipeline.Importer.Tests;

/// A part's own settings (ImportPlanEntry.Settings): one object the plan's copies share, taken onto
/// a fresh plan from a stored one, and what the import reads for that part.
class PartSettingsTests
{
	class LidSettings : RefCounted
	{
		public bool Open = false;
	}

	[Test]
	public static void APartsSettingsAreSharedTakenOntoAFreshPlanAndReadForThatPartOnly()
	{
		let settings = new LidSettings();
		let stored = scope ImportPlan();
		let kept = new ImportPlanEntry(.Mesh, "Lid", "Lid");
		kept.SetSettings(settings);
		settings.ReleaseRef(); // the entry's reference holds it
		stored.Add(kept);
		Test.Assert(kept.Settings === settings);

		let options = scope ImportOptions();
		options.Selection.Add(new ImportPlanEntry(.Mesh, "Lid", "Lid"));
		options.Selection.Add(new ImportPlanEntry(.Mesh, "Box", "Box"));
		Test.Assert(options.SelectionSettings(.Mesh, "Lid") == null, "nobody asked: none");
		options.Selection.MergeStoredSelection(stored);
		Test.Assert(options.SelectionSettings(.Mesh, "Lid") === settings, "the stored entry's, shared");
		Test.Assert(options.SelectionSettings(.Mesh, "Box") == null, "another part's");
		Test.Assert(options.SelectionSettings(.Texture, "Lid") == null, "another kind's");
		Test.Assert(options.SelectionSettings(.Mesh, "Hinge") == null, "not in the plan");

		// Let go by one, still the other's.
		kept.SetSettings(null);
		Test.Assert(kept.Settings == null);
		let shared = options.SelectionSettings(.Mesh, "Lid") as LidSettings;
		Test.Assert(shared != null);
		shared.Open = true;
		Test.Assert(shared.Open);
	}
}
