using System;
using System.Collections;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// A recorder over a table Runtime knows nothing about, standing in for the scene
/// manager's contributions.
///
/// This is the shape a layer above Runtime supplies: its own table, its own ids, armed and
/// reversed by the host along with everything else.
class FakeContributionRecorder : IRegistrationRecorder
{
	/// The layer's own table.
	public List<uint64> Contributions = new .() ~ delete _;
	public int ArmCount;
	public int DisarmCount;

	private List<uint64> mSink;

	/// What a plugin calls into. Only a REAL addition is reported, because reversing one
	/// another party already owned would tear out something still in use.
	public void Contribute(uint64 id)
	{
		if (Contributions.Contains(id))
			return;
		Contributions.Add(id);
		if (mSink != null)
			mSink.Add(id);
	}

	public override void Arm(List<uint64> sink)
	{
		mSink = sink;
		ArmCount++;
	}

	public override void Disarm()
	{
		mSink = null;
		DisarmCount++;
	}

	public override void Reverse(uint64 id) => Contributions.Remove(id);
}
