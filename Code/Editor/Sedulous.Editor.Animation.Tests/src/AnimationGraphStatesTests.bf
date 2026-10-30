using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Animation;
using Sedulous.Animation.Pipeline;
using Sedulous.GUI;

namespace Sedulous.Editor.Animation.Tests;

/// An animation graph as a graph source (AnimationGraphStates), no widgets: a layer's states and Any
/// State its nodes, its transitions node links; a transition into Any State or into its own state
/// refused; each change one edit; a state deleted taking its transitions and moving the indices after
/// it down while every other id stays; a layer keeping one state; a move one step, a cancelled one
/// none; and the graph edits the page's lists share (a parameter removed, a layer added and removed).
class AnimationGraphStatesTests
{
	private static bool Near(float a, float b) => Math.Abs(a - b) <= 1e-4f;

	/// Locomotion (the default), Attack and Die; Locomotion to Attack on the Attack trigger, Attack
	/// back at its end, Any State to Die while Dead; Speed drives nothing yet.
	private class Bed
	{
		public AnimationGraphAsset Asset = new .() ~ delete _;
		public int Edits = 0;
		public AnimationGraphStates States ~ delete _;
		/// The asset's source as nested objects, read again by Read.
		private GraphDocument mDoc = new .() ~ delete _;

		public this()
		{
			AnimationGraphEdits.AddParameter(Asset, "Speed", .Float);
			AnimationGraphEdits.AddParameter(Asset, "Attack", .Trigger);
			AnimationGraphEdits.AddParameter(Asset, "Dead", .Bool);
			AnimationGraphEdits.Edit(Asset, scope (doc) => { doc.AddLayer("Base"); });
			AnimationGraphEdits.AddState(Asset, 0, "Locomotion", .Blend1D, .(300.0f, 200.0f));
			AnimationGraphEdits.AddState(Asset, 0, "Attack", .Clip, .(600.0f, 80.0f));
			AnimationGraphEdits.AddState(Asset, 0, "Die", .Clip, .(60.0f, 320.0f));
			AnimationGraphEdits.Edit(Asset, scope (doc) =>
				{
					let layer = doc.Layers[0];
					layer.States[0].ParamIndex = 0;
					Transition(layer, 0, 1, 1);
					Transition(layer, 1, 0, -1);
					Transition(layer, -1, 2, 2);
				});
			States = new AnimationGraphStates(new [=this] () => Asset, new [=this] (typeId, mutate) =>
				{
					Edits++;
					mutate(Asset);
				});
		}

		private static void Transition(GraphLayer layer, int32 src, int32 dst, int32 parameter)
		{
			let transition = layer.AddTransition(src, dst);
			if (parameter >= 0)
			{
				let condition = new GraphCondition();
				condition.ParamIndex = parameter;
				condition.Threshold = 1.0f;
				transition.Conditions.Add(condition);
			}
		}

		/// The asset's source as it is now.
		public GraphDocument Read()
		{
			mDoc.Load(Asset.Source);
			return mDoc;
		}

		public GraphLayer Layer => Read().Layers[0];
		public List<Float2> Positions => Asset.LayerLayouts[0].StatePositions;

		public static GraphLinkInfo NodeLink(GraphId from, GraphId to)
		{
			var link = GraphLinkInfo();
			link.Kind = .Nodes;
			link.FromNode = from;
			link.ToNode = to;
			return link;
		}

		public bool Allowed(GraphLinkInfo link)
		{
			let check = scope GraphLinkCheck();
			States.CheckLink(link, check);
			return check.Allowed;
		}
	}

	[Test]
	public static void TheStatesAndAnyStateAreTheNodesTheTransitionsNodeLinks()
	{
		let bed = scope Bed();
		let nodes = scope List<GraphId>();
		bed.States.GetNodes(nodes);
		Test.Assert(nodes.Count == 4);
		Test.Assert(nodes[0] == AnimationGraphStates.cAnyState);
		let any = bed.States.GetNode(AnimationGraphStates.cAnyState);
		Test.Assert(any != null);
		Test.Assert(any.Title == "Any State");
		Test.Assert(!any.Deletable);
		let locomotion = bed.States.GetNode(bed.States.StateId(0));
		Test.Assert(locomotion != null);
		Test.Assert(locomotion.Title == "Locomotion");
		Test.Assert(locomotion.Subtitle == "Starts here · Blends 0 by Speed", locomotion.Subtitle);
		Test.Assert(Near(locomotion.Position.X, 300.0f));
		Test.Assert(bed.States.GetNode(bed.States.StateId(1)).Subtitle == "No clip");

		let links = scope List<GraphLinkInfo>();
		bed.States.GetLinks(links);
		Test.Assert(links.Count == 3);
		Test.Assert(links[0].Kind == .Nodes);
		Test.Assert(links[0].FromNode == bed.States.StateId(0));
		Test.Assert(links[0].ToNode == bed.States.StateId(1));
		Test.Assert(links[2].FromNode == AnimationGraphStates.cAnyState);
		Test.Assert(links[2].ToNode == bed.States.StateId(2));
	}

	[Test]
	public static void ATransitionIntoAnyStateOrItsOwnStateIsRefusedOneMadeIsOneEdit()
	{
		let bed = scope Bed();
		let die = bed.States.StateId(2);
		let attack = bed.States.StateId(1);
		Test.Assert(bed.Allowed(Bed.NodeLink(die, 0)), "one may begin at a state");
		Test.Assert(bed.Allowed(Bed.NodeLink(AnimationGraphStates.cAnyState, 0)));
		Test.Assert(!bed.Allowed(Bed.NodeLink(die, AnimationGraphStates.cAnyState)));
		Test.Assert(!bed.Allowed(Bed.NodeLink(die, die)));
		Test.Assert(bed.States.Connect(Bed.NodeLink(die, die)) == 0);
		Test.Assert(bed.Edits == 0);

		let made = bed.States.Connect(Bed.NodeLink(die, bed.States.StateId(0)));
		Test.Assert(made != 0);
		Test.Assert(bed.Edits == 1);
		Test.Assert(bed.Layer.Transitions.Count == 4);
		Test.Assert(bed.Layer.Transitions[3].Src == 2);
		Test.Assert(bed.Layer.Transitions[3].Dst == 0);
		Test.Assert(bed.States.TransitionOf(made) == 3);

		// Relinked: its ends move, its id stays.
		Test.Assert(bed.States.Relink(made, Bed.NodeLink(attack, die)));
		Test.Assert(bed.Layer.Transitions[3].Src == 1);
		Test.Assert(bed.Layer.Transitions[3].Dst == 2);
		Test.Assert(bed.States.TransitionOf(made) == 3);

		// Taken away: the others keep their ids.
		let first = bed.States.TransitionId(0);
		GraphId[1] gone = .(bed.States.TransitionId(1));
		Test.Assert(bed.States.Disconnect(gone));
		Test.Assert(bed.Layer.Transitions.Count == 3);
		Test.Assert(bed.States.TransitionOf(first) == 0);
		Test.Assert(bed.States.TransitionOf(made) == 2);
		Test.Assert(bed.Edits == 3);
	}

	[Test]
	public static void AStateDeletedTakesItsTransitionsAndMovesThoseAfterItDownALayerKeepsOne()
	{
		let bed = scope Bed();
		let locomotion = bed.States.StateId(0);
		let attack = bed.States.StateId(1);
		let die = bed.States.StateId(2);
		let toDie = bed.States.TransitionId(2);
		GraphId[1] attackOnly = .(attack);
		Test.Assert(bed.States.DeleteNodes(attackOnly));
		Test.Assert(bed.Edits == 1);
		Test.Assert(bed.Layer.States.Count == 2);
		Test.Assert(bed.Layer.States[1].Name == "Die");
		Test.Assert(bed.Layer.Transitions.Count == 1, "both of Attack's went");
		Test.Assert(bed.Layer.Transitions[0].Src == -1);
		Test.Assert(bed.Layer.Transitions[0].Dst == 1, "Die moved down");
		Test.Assert(bed.States.StateOf(die) == 1, "its id stayed with it");
		Test.Assert(bed.States.StateOf(locomotion) == 0);
		Test.Assert(bed.States.TransitionOf(toDie) == 0);
		Test.Assert(bed.Positions.Count == 2);
		Test.Assert(Near(bed.Positions[1].X, 60.0f));

		// Any State is never deleted; nor is a layer's last state.
		GraphId[3] everything = .(AnimationGraphStates.cAnyState, locomotion, die);
		Test.Assert(bed.States.DeleteNodes(everything));
		Test.Assert(bed.Layer.States.Count == 1);
		Test.Assert(bed.Layer.States[0].Name == "Locomotion");
		Test.Assert(bed.Layer.DefaultState == 0);
		Test.Assert(bed.Layer.Transitions.IsEmpty);
		GraphId[1] last = .(locomotion);
		Test.Assert(!bed.States.DeleteNodes(last));
	}

	[Test]
	public static void AMoveIsOneStepACancelledOneNoneANewStateNamedApart()
	{
		let bed = scope Bed();
		let attack = bed.States.StateId(1);
		GraphId[2] moving = .(attack, AnimationGraphStates.cAnyState);
		bed.States.BeginMove();
		bed.States.PreviewMove(moving, .(), .(10.0f, 5.0f));
		bed.States.PreviewMove(moving, .(), .(20.0f, 15.0f));
		Test.Assert(Near(bed.States.GetNode(attack).Position.X, 620.0f), "live");
		Test.Assert(bed.Edits == 0);
		bed.States.CommitMove();
		Test.Assert(bed.Edits == 1);
		Test.Assert(Near(bed.Positions[1].X, 620.0f));
		Test.Assert(Near(bed.Positions[1].Y, 95.0f));
		Test.Assert(Near(bed.Asset.LayerLayouts[0].AnyStatePosition.X, 60.0f));

		GraphId[1] attackOnly = .(attack);
		bed.States.BeginMove();
		bed.States.PreviewMove(attackOnly, .(), .(100.0f, 0.0f));
		bed.States.CancelMove();
		Test.Assert(Near(bed.Positions[1].X, 620.0f));
		Test.Assert(bed.Edits == 1);

		let made = bed.States.CreateNode("clip", .(50.0f, 60.0f), 0);
		Test.Assert(made != 0);
		Test.Assert(bed.States.CreateNode("clip", .(90.0f, 60.0f), 0) != 0);
		Test.Assert(bed.States.CreateNode("blend1d", .(90.0f, 60.0f), 0) != 0);
		Test.Assert(bed.States.CreateNode("something else", .(0.0f, 0.0f), 0) == 0);
		Test.Assert(bed.Layer.States.Count == 6);
		Test.Assert(bed.Layer.States[3].Name == "State");
		Test.Assert(bed.Layer.States[4].Name == "State 2");
		Test.Assert(bed.Layer.States[5].Name == "Blend");
		Test.Assert(bed.Layer.States[5].NodeKind == (uint8)AnimationStateKind.Blend1D);
		Test.Assert(bed.States.StateOf(made) == 3);
		Test.Assert(Near(bed.Positions[3].X, 50.0f));
	}

	[Test]
	public static void AParameterRemovedTakesItsConditionsAndDriversLayersAddedAndRemoved()
	{
		let bed = scope Bed();
		Test.Assert(AnimationGraphEdits.RemoveParameter(bed.Asset, 0)); // Speed: the blend's driver
		Test.Assert(bed.Asset.Source.ParamName.Count == 2);
		Test.Assert(bed.Asset.Source.ParamType.Count == 2);
		Test.Assert(bed.Layer.States[0].ParamIndex == -1);
		Test.Assert(bed.Layer.Transitions[0].Conditions[0].ParamIndex == 0, "Attack moved down");
		Test.Assert(bed.Layer.Transitions[2].Conditions[0].ParamIndex == 1, "Dead moved down");
		Test.Assert(AnimationGraphEdits.RemoveParameter(bed.Asset, 0)); // Attack: its condition goes
		Test.Assert(bed.Layer.Transitions[0].Conditions.IsEmpty);
		Test.Assert(bed.Layer.Transitions[2].Conditions[0].ParamIndex == 0);
		Test.Assert(AnimationGraphEdits.AddParameter(bed.Asset, "Dead", .Bool) == 1);
		Test.Assert(bed.Asset.Source.ParamName[1] == "Dead 2");

		Test.Assert(AnimationGraphEdits.AddLayer(bed.Asset, "Base") == 1);
		Test.Assert(bed.Read().Layers[1].Name == "Base 2");
		Test.Assert(bed.Read().Layers[1].States.Count == 1);
		Test.Assert(bed.Asset.LayerLayouts.Count == 2);
		Test.Assert(AnimationGraphEdits.RemoveLayer(bed.Asset, 0));
		Test.Assert(bed.Read().Layers[0].Name == "Base 2");
		Test.Assert(!AnimationGraphEdits.RemoveLayer(bed.Asset, 0), "the last stays");
	}
}
