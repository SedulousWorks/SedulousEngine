using System;
using System.Collections;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Editor.App;

/// One source file of a batch import review: its candidate importers, the chosen one, its
/// options and worker payload, and the described plan.
class BatchImportFile
{
	public String Path = new .() ~ delete _;
	/// At least one, in registry order; borrowed.
	public List<IFileImporter> Candidates = new .() ~ delete _;
	public int ImporterIndex = 0;
	public bool Enabled = true;
	/// For the current importer choice. Owned.
	public ImportOptions Options = null ~ delete _;
	/// The worker payload for heavy importers. Owned.
	public Object Prepared = null ~ delete _;
	/// Owned.
	public ImportPlan Plan = new .() ~ delete _;
	/// The plan and toggles are ready to show and commit.
	public bool Described = false;

	public IFileImporter Importer => Candidates[ImporterIndex];
}
