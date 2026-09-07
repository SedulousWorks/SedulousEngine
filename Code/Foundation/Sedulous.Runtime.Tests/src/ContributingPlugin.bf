using System;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// A plugin whose OnLoad contributes to a table above Runtime.
class ContributingPlugin : IRuntimePlugin
{
	private FakeContributionRecorder mRecorder;
	private uint64 mId;

	public this(FakeContributionRecorder recorder, uint64 id)
	{
		mRecorder = recorder;
		mId = id;
	}

	public StringView Name => "contributor";

	public void OnLoad(Context context) => mRecorder.Contribute(mId);
	public void OnUnload(Context context) {}
}
