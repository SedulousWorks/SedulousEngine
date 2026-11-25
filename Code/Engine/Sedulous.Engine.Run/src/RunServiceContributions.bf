using System;
using System.Collections;
using Sedulous.Run;

namespace Sedulous.Engine.Run;

/// A service every run gets: its type, and what installs one into a run (`run.Add(new T())`).
struct RunServiceContribution
{
	/// What it is called, for logs; borrowed, the contributor's.
	public StringView Id;
	public Type Type;
	public function void(RunBase run) Install;

	public this(StringView id, Type type, function void(RunBase run) install)
	{
		Id = id;
		Type = type;
		Install = install;
	}
}

/// The services a run gets from outside its own members: each contribution installs one into a run
/// (a plugin's per-run state, such as the dialogue's runner), as a scene's managers come from the
/// scene contributions. Every ApplicationRun installs them all as it is made. A contribution added
/// while runs exist (a plugin loading under a running game) is installed into those runs at once,
/// and one removed (the plugin unloading) is taken out of every live run, so no run keeps a service
/// whose code is gone.
class RunServiceContributions
{
	private struct Entry
	{
		public uint64 Token;
		public RunServiceContribution Contribution;
	}

	/// The process's.
	public static RunServiceContributions Global = new .() ~ delete _;

	private List<Entry> mContributions = new .() ~ delete _;
	/// BORROWED: the live runs, each forgetting itself as it goes (Detach).
	private List<RunBase> mRuns = new .() ~ delete _;
	private uint64 mNextToken = 1;

	public int Count => mContributions.Count;

	/// Adds `contribution` and installs it into every live run; its token for Remove (0, nothing
	/// added, for one with no type or no install).
	public uint64 Add(RunServiceContribution contribution)
	{
		if ((contribution.Type == null) || (contribution.Install == null))
			return 0;
		let token = mNextToken++;
		Entry entry;
		entry.Token = token;
		entry.Contribution = contribution;
		mContributions.Add(entry);
		for (let run in mRuns)
			contribution.Install(run);
		return token;
	}

	/// Removes the contribution `token`, taking its service out of every live run.
	public void Remove(uint64 token)
	{
		for (int i < mContributions.Count)
		{
			if (mContributions[i].Token != token)
				continue;
			let type = mContributions[i].Contribution.Type;
			mContributions.RemoveAt(i);
			for (let run in mRuns)
				run.RemoveService(type);
			return;
		}
	}

	/// Installs every contribution into `run` and keeps it as a live run (a run's construction).
	public void Attach(RunBase run)
	{
		if (mRuns.Contains(run))
			return;
		mRuns.Add(run);
		for (let entry in mContributions)
			entry.Contribution.Install(run);
	}

	/// Forgets `run` (its destruction): its services go with it.
	public void Detach(RunBase run)
	{
		mRuns.Remove(run);
	}
}
