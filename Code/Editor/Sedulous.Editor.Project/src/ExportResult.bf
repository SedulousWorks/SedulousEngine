using System;
using System.Collections;

namespace Sedulous.Editor.Project;

/// What one export produced.
class ExportResult
{
	public ExportStats Content = new .() ~ delete _;
	/// The player, the files its build left beside it, the shader pack and the preset's additional
	/// files copied.
	public int FilesStaged = 0;
	public String OutputDir = new .() ~ delete _;
	public PruningReport Pruning = new .() ~ delete _;
	/// Which player the dist runs: what was built ("SkyHopperPlayer, ShippingRelease, Linux64").
	public String PlayerReason = new .() ~ delete _;
	/// Why the export stopped short (the project's plugins, another host's platform, the player's
	/// build, a failing export hook); empty when it did not.
	public String Refusal = new .() ~ delete _;
	/// The build job that compiled the player (PlayerBuild.Job), one reference of its own; null
	/// when nothing compiled it (the last build reused, a stand-in staged) or the export stopped
	/// before its player was built.
	public BuildJob PlayerJob => mPlayerJob;
	private BuildJob mPlayerJob ~ _?.ReleaseRef();

	/// `job` as the one that compiled the player (a reference taken; null: none), the last let go.
	public void SetPlayerJob(BuildJob job)
	{
		if (job != null)
			job.AddRef();
		mPlayerJob?.ReleaseRef();
		mPlayerJob = job;
	}

	public void CopyTo(ExportResult other)
	{
		other.PlayerReason.Set(PlayerReason);
		other.Refusal.Set(Refusal);
		Content.CopyTo(other.Content);
		other.FilesStaged = FilesStaged;
		other.OutputDir.Set(OutputDir);
		Pruning.CopyTo(other.Pruning);
		other.SetPlayerJob(mPlayerJob);
	}
}

/// What ExportAll did with the presets: how many exported and failed, and the names of those
/// skipped for another host's platform.
class ExportAllSummary
{
	public int Exported = 0;
	public int Failed = 0;
	public List<String> Skipped = new .() ~ DeleteContainerAndItems!(_);

	public void CopyTo(ExportAllSummary other)
	{
		other.Exported = Exported;
		other.Failed = Failed;
		ClearAndDeleteItems!(other.Skipped);
		for (let name in Skipped)
			other.Skipped.Add(new .(name));
	}
}
