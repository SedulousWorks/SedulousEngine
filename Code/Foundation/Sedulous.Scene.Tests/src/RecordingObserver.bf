namespace Sedulous.Scene.Tests;

/// Counts the stage callbacks it receives, and logs its tag on the destroying stage so the
/// ORDER observers ran in is observable and not merely their count.
class RecordingObserver : ISceneObserver
{
	public int Composing = 0;
	public int Ready = 0;
	public int Destroying = 0;
	public int32 ObserverOrder = 0;
	public char8 Tag = '?';

	public this(char8 tag, int32 order = 0)
	{
		Tag = tag;
		ObserverOrder = order;
	}

	public int32 Order => ObserverOrder;

	public void OnComposing(Scene scene) { Composing++; }
	public void OnSystemsReady(Scene scene) { Ready++; }

	public void OnDestroying(Scene scene)
	{
		Destroying++;
		CompositionProbes.ObserverOrder.Append(Tag);
	}
}
