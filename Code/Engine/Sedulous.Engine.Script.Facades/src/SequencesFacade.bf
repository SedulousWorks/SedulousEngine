using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Sequence;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Sequences`: starting the scene's sequences.
[Scriptable, SceneFacade("Sequences")]
class SequencesFacade : SceneFacade
{
	private SequenceSystem System => Scene.GetSystem<SequenceSystem>();

	/// Starts the sequence asset `sequence` and returns its play, already at time 0; it ends as
	/// "release" (what it moved stays where it is).
	[Scriptable]
	public SequencePlay Play(Guid sequence) => Play(sequence, "release");

	/// The same, ending as `finish`: "release", "hold" (everything stays as its last frame left it
	/// until Stop()) or "restore" (every value it changed goes back).
	[Scriptable]
	public SequencePlay Play(Guid sequence, StringView finish)
	{
		let system = System;
		if (system == null)
			return .();
		return .(Scene, system.Play(sequence, SequenceSystem.ParseFinish(finish)));
	}

	/// Ends every play in the scene (a skip).
	[Scriptable]
	public void StopAll() => System?.StopAll();
}
