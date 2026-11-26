using System;
using Sedulous.Core;
using Sedulous.PropertyAnimation;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.Engine.Behavior;
using Sedulous.Engine.Sequence;

namespace Sedulous.Engine.GameScript.Tests;

/// `scene.Sequences` from a script: a behaviour plays a stored sequence, binds itself to its cast,
/// and hears the play's cue and its end on the run's bus as SequenceNotices naming its play.
class SequenceScriptTests
{
	private const String cGame = """
		class Game
		{
			void onStart() {}
		}
		""";

	/// "Actor" walks X to 10 over a second, with a cue "gate" at 0.5 on no one, so the play
	/// reports it on the bus. Its id.
	private static Guid AuthorWalk(GameRun run)
	{
		let instance = run.Database.RootGroup.CreateInstance("walk", "Sedulous.Sequence.Resource.SequenceSource");
		let source = scope SequenceSource();
		let s = source.Sequence;
		s.Bindings.Add(new .("Actor"));
		let move = new PropertySequenceTrack();
		move.Binding = 0;
		move.Property.ComponentType.Set(TrackTargets.cTransform);
		move.Property.PropertyPath.Set("Position");
		move.Property.Kind = .Float3;
		move.Property.Channels[0].AddKey(.(0.0f, 0.0f));
		move.Property.Channels[0].AddKey(.(1.0f, 10.0f));
		s.Tracks.Add(move);
		let cues = new EventSequenceTrack();
		cues.Keys.Add(new .(0.5f, "cue", "gate"));
		s.Tracks.Add(cues);
		s.Duration = 1.0f;
		Test.Assert(instance.WriteObject(source) case .Ok);
		return instance.Id;
	}

	[Test]
	public static void ABehaviourPlaysASequenceAndHearsItsNotices()
	{
		SequenceResources.RegisterAll();
		// Outlives the run, whose manager borrows it.
		let factory = scope SequenceFactory();
		let run = scope GameRun("scratch_game_sequences");
		run.Resources.AddFactory(factory);
		run.MoreSystems = new (scene) => SequenceDomain.AddSequenceSceneSystems(scene);
		let walk = AuthorWalk(run);

		let director = run.Class("Director", scope $$"""
			class Director
			{
				Entity self;
				Scene@ scene;
				SequencePlay play;
				string heard;
				bool done = false;
				void onStart()
				{
					play = scene.Sequences.Play(Guid::FromString("{{walk}}"));
					play.Bind("Actor", self);
				}
				void onSequenceEvent(SequenceNotice notice)
				{
					if (notice.Play == play.Id()) { heard = notice.Name + " " + notice.Value; }
				}
				void onSequenceFinished(SequenceNotice notice)
				{
					if (notice.Play == play.Id() && !play.IsPlaying()) { done = true; }
				}
			}
			""", .Entity);
		Test.Assert(run.Instance.StartRunBehavior(run.Class("Game", cGame)));

		let level = run.Instance.CreateScene("level");
		SceneResolve.ResolveSceneResources(level, run.Resources);
		let actor = level.CreateEntity("actor");
		let behavior = new AttachedBehavior();
		behavior.BehaviorClass.SetDirect(director);
		level.GetSystem<BehaviorComponentManager>().Add(actor).Behaviors.Add(behavior);
		level.Start();
		level.SetSimulationEnabled(true);

		// A second and a half: the play starts, runs to its end, and its reports are delivered.
		run.Step(6, 0.25f);

		let instance = level.GetSystem<BehaviorComponentManager>().Get(actor).Behaviors[0].Instance;
		Test.Assert(instance != null, "the director runs");
		let runtime = run.Instance.RunHost.Scripts.Runtime;
		var heard = ScriptValue.Nil;
		runtime.GetProperty(instance, "heard", ref heard);
		Test.Assert(heard.AsString == "cue gate", scope $"heard '{heard.AsString}'");
		var done = ScriptValue.Nil;
		runtime.GetProperty(instance, "done", ref done);
		Test.Assert(done.AsBool, "the end reached the director, naming its play");
		Test.Assert(Math.Abs(level.GetLocalTransform(actor).Position.X - 10.0f) < 1e-3f, "the play moved the actor");
	}
}
