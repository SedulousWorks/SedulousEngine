using System;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// A part whose load contributes to a table above Runtime.
class ContributingPart : PluginPart
{
	private FakeContributionRecorder mRecorder;
	private uint64 mId;

	public this(FakeContributionRecorder recorder, uint64 id)
	{
		mRecorder = recorder;
		mId = id;
	}

	public override StringView PluginId => "contributor";
	public override PluginPartKind Kind => .Engine;

	public override void Load(PluginContext context) => mRecorder.Contribute(mId);
}
