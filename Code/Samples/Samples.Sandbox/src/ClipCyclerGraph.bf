using System;
using Sedulous.Animation;
using Sedulous.Model.Resource;

namespace Samples.Sandbox;

/// A state machine over a model's own clips: one state per animation, and a "Next" trigger that
/// cross fades each to the following one, wrapping.
///
/// Built from whatever the model happens to carry rather than from authored data, so the graph
/// machinery (states, transitions, parameters, cross fades) can be exercised without a graph
/// asset existing yet.
static class ClipCyclerGraph
{
	/// THE CALLER OWNS the result. Null when the model has no clips to cycle.
	public static AnimationGraph Build(ModelResource model)
	{
		let clipCount = (int32)model.Animations.Count;
		if (clipCount == 0)
			return null;

		let graph = new AnimationGraph();
		let nextParameter = graph.AddParameter("Next", .Trigger);

		let layer = new AnimationLayer("Base");
		for (int32 i < clipCount)
		{
			let clip = model.Animations[i].Get;
			let name = (clip != null) ? clip.Name : "State";
			layer.AddState(new AnimationGraphState(name, new ClipStateNode(clip)));
		}

		for (int32 i < clipCount)
		{
			let transition = new AnimationGraphTransition();
			transition.SourceStateIndex = i;
			transition.DestStateIndex = (i + 1) % clipCount;
			transition.Duration = 0.25f;
			transition.AddBoolCondition(nextParameter, true);
			layer.AddTransition(transition);
		}

		graph.AddLayer(layer);
		return graph;
	}
}
