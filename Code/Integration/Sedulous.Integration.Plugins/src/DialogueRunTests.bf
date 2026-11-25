using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.VFS;
using Sedulous.Scene;
using Sedulous.PropertyAnimation;
using Sedulous.Sequence;
using Sedulous.Sequence.Resource;
using Sedulous.Engine.Run;
using Sedulous.Engine.Behavior;
using Sedulous.Engine.Render;
using Sedulous.Engine.Sequence;
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The dialogue runner a run holds, staging in the run's scene. A conversation fades out, plays a
/// sequence whose binding is named for a speaker and waits for it, fades in, and shows a line on
/// the run's bus. The fade is a claim on the scene's fade, held at full until the fade in lets it
/// go; the sequence moves the entity the cast names for the speaker, or the one the game bound to
/// it.
class DialogueRunTests
{
	/// A content database holding a cooked conversation, its cast (the keeper played by "Keeper")
	/// and a sequence that walks its binding "keeper" to X 10 over a second.
	class DialogueStore
	{
		const String cDir = "scratch_plugins_dialogue_run";
		NativeFileSystem mMount ~ delete _;
		SerializableRegistry mTypes = new .() ~ delete _;
		SerializerFactory mSerializers = (new (stream, mode) => new BinarySerializerContext(stream, mode)) ~ delete _;
		ContentDatabase mDb ~ delete _;
		DialogueFactory mDialogues = new .() ~ delete _;
		DialogueCastFactory mCasts = new .() ~ delete _;
		SequenceFactory mSequences = new .() ~ delete _;
		public ResourceManager Resources ~ delete _;
		public Guid Gate;
		public Guid Walk;

		public this()
		{
			DialogueResources.RegisterAll();
			DialogueResources.RegisterAll(mTypes);
			SequenceResources.RegisterAll();
			SequenceResources.RegisterAll(mTypes);
			RemoveDirectoryRecursive(cDir);
			CreateDirectory(cDir);
			mMount = new .(cDir);
			mDb = new .(mMount, mSerializers, "asset", mTypes);
			let root = mDb.RootGroup;

			let walkInstance = root.CreateInstance("walk", typeof(SequenceSource).GetFullName(.. scope .()));
			Walk = walkInstance.Id;
			let walk = scope SequenceSource();
			walk.Sequence.Bindings.Add(new .("keeper"));
			let move = new PropertySequenceTrack();
			move.Binding = 0;
			move.Property.ComponentType.Set(TrackTargets.cTransform);
			move.Property.PropertyPath.Set("Position");
			move.Property.Kind = .Float3;
			move.Property.Channels[0].AddKey(.(0.0f, 0.0f));
			move.Property.Channels[0].AddKey(.(1.0f, 10.0f));
			walk.Sequence.Tracks.Add(move);
			walk.Sequence.Duration = 1.0f;
			Test.Assert(walkInstance.WriteObject(walk) case .Ok);

			let castInstance = root.CreateInstance("cast", typeof(DialogueCastSource).GetFullName(.. scope .()));
			let cast = scope DialogueCastSource();
			let keeper = new DialogueSpeaker();
			keeper.Id.Set("keeper");
			keeper.ShownName.Set("The Keeper");
			keeper.Entity.Set("Keeper");
			cast.Speakers.Add(keeper);
			Test.Assert(castInstance.WriteObject(cast) case .Ok);

			let parse = scope DialogueParse();
			DialogueFormat.ParseDialogue("conversation gate\n" +
				"fade out for 1\n" +
				"sequence walk and wait\n" +
				"fade in for 1\n" +
				"@ keeper: Done.\n", .(), parse);
			Test.Assert(parse.Ok);
			Test.Assert(parse.Conversations[0].Steps[1].Kind == .Sequence);
			parse.Conversations[0].Steps[1].Asset = Walk; // what the cook resolves through the dialogue assets
			let gateInstance = root.CreateInstance("gate", typeof(DialogueSource).GetFullName(.. scope .()));
			Gate = gateInstance.Id;
			let source = scope DialogueSource();
			source.Cast = castInstance.Id;
			Swap!(source.Conversations, parse.Conversations);
			Swap!(source.Lines, parse.Lines);
			Test.Assert(gateInstance.WriteObject(source) case .Ok);

			Resources = new .(mDb);
			Resources.AddFactory(mDialogues);
			Resources.AddFactory(mCasts);
			Resources.AddFactory(mSequences);
		}

		public ~this()
		{
			DeleteAndNullify!(Resources);
			DeleteAndNullify!(mDb);
			RemoveDirectoryRecursive(cDir);
		}
	}

	/// A run (its scripts' host finding the resources, its current scene, its save) with its
	/// runner, over a running scene that fades and plays sequences.
	class Stage
	{
		public DialogueStore Store = new .() ~ delete _;
		public DialogueSettings Settings = new .() ~ delete _;
		public ApplicationRun Run = new .() ~ delete _;
		ResourceSource mSource ~ delete _;
		public Scene World ~ delete _;
		public PostProcessSystem Post;
		public DialogueRunService Runner ~ delete _;
		public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);
		delegate void(Variant) mHeard ~ delete _;

		public this()
		{
			let resources = Store.Resources;
			mSource = new .(new () => resources);
			Run.Get<BehaviorRunHost>().SetService(mSource);
			World = new .("dialogue");
			Run.SetScene(World);
			SequenceDomain.AddSequenceSceneSystems(World);
			Post = World.AddSystem<PostProcessSystem>();
			Runner = new .(Settings, Run);
			mHeard = new (payload) =>
				{
					if (let notice = payload.Get<Object>() as DialogueLineNotice)
						Lines.Add(new $"{notice.ShownName}: {notice.Text}");
				};
			Run.Events.Subscribe(StringHash(DialogueEvents.Line), mHeard);
			World.Start();
			World.SetSimulationEnabled(true);
		}

		public ~this()
		{
			// The runner lets go of the scene's fade, then the scene goes before the run it reports
			// into.
			DeleteAndNullify!(Runner);
			Run.SetScene(null);
			DeleteAndNullify!(World);
		}

		/// A frame: the bus, the runner, then the scene (its sequences).
		public void Frame(float seconds)
		{
			Run.Events.Drain();
			Runner.Update(seconds);
			World.Update(seconds);
		}

		public float X(EntityHandle entity) => World.GetLocalTransform(entity).Position.X;
	}

	static bool Near(float a, float b) => Math.Abs(a - b) < 1e-3f;

	[Test]
	public static void ARunsDialogueRunnerFadesPlaysASequenceBoundToTheCastsEntityAndWaitsForIt()
	{
		let r = scope Stage();
		let keeper = r.World.CreateEntity("Keeper");
		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));

		r.Frame(0.5f);
		Test.Assert(Near(r.Post.Fade.Amount, 0.5f));
		r.Frame(0.5f); // the fade out ends; the sequence starts, held at full black
		Test.Assert(Near(r.Post.Fade.Amount, 1.0f));
		Test.Assert(r.Runner.Waiting == .Staging);
		for (int i < 5)
			r.Frame(0.25f);
		Test.Assert(Near(r.X(keeper), 10.0f));
		Test.Assert(Near(r.Post.Fade.Amount, 0.5f), "the sequence ended; half way into the fade in");
		Test.Assert(r.Lines.IsEmpty);

		for (int i < 3)
			r.Frame(0.25f);
		Test.Assert(Near(r.Post.Fade.Amount, 0.0f), "faded in");
		Test.Assert(!r.Post.FadeClaims.Winning(?), "the claim let go");
		r.Frame(0.0f); // the line's notice is delivered
		Test.Assert(r.Lines.Count == 1);
		Test.Assert(r.Lines[0] == "The Keeper: Done.");
		Test.Assert(r.Runner.Waiting == .Line);
	}

	[Test]
	public static void ASpeakerTheGameBindsPlaysAsThatEntityOverTheOneTheCastNames()
	{
		let r = scope Stage();
		let keeper = r.World.CreateEntity("Keeper");
		let standIn = r.World.CreateEntity("Stand-in");
		r.Runner.Bind("keeper", standIn);
		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));
		for (int i < 16)
			r.Frame(0.25f);
		Test.Assert(Near(r.X(standIn), 10.0f));
		Test.Assert(Near(r.X(keeper), 0.0f));
		Test.Assert(r.Runner.Waiting == .Line);
	}

	/// A fade held when the runner goes (its run ending mid conversation) is let go with it.
	[Test]
	public static void AFadeHeldIsLetGoWithTheRunner()
	{
		let r = scope Stage();
		r.World.CreateEntity("Keeper");
		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));
		r.Frame(1.0f);
		Test.Assert(Near(r.Post.Fade.Amount, 1.0f));
		DeleteAndNullify!(r.Runner);
		Test.Assert(!r.Post.FadeClaims.Winning(?), "released as the runner went");
	}
}
