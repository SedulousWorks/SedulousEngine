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
using Sedulous.Script;
using Sedulous.Script.AngelScript;
using Sedulous.Script.Resource;
using Sedulous.Engine.Composition;
using Sedulous.Run;
using Dialogue;

namespace Sedulous.Integration.Plugins;

/// The dialogue runner a run holds, staging in the run's scene. A conversation fades out, plays a
/// sequence whose binding is named for a speaker and waits for it, fades in, and shows a line on
/// the run's bus. The fade is a claim on the scene's fade, held at full until the fade in lets it
/// go; the sequence moves the entity the cast names for the speaker, or the one the game bound to
/// it.
class DialogueRunTests
{
	/// The conversation the staging tests play: a fade out, the walk, a fade in and a line.
	const String cStaged = "conversation gate\n" +
		"fade out for 1\n" +
		"sequence walk and wait\n" +
		"fade in for 1\n" +
		"@ keeper: Done.\n";

	/// A content database holding a cooked conversation (`talk`, parsed with the command `cue`),
	/// its cast (the keeper played by "Keeper") and a sequence that walks its binding "keeper" to X
	/// 10 over a second, which the conversation's `sequence walk` plays.
	public class DialogueStore
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

		public this(StringView talk = cStaged)
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

			let cue = scope DialogueCommandForm();
			let error = scope String();
			Test.Assert(DialogueFormat.ParseCommandForm("cue <event:text> waits", cue, error), error);
			DialogueCommandForm[1] forms = .(cue);
			let parse = scope DialogueParse();
			DialogueFormat.ParseDialogue(talk, forms, parse);
			Test.Assert(parse.Ok);
			// What the cook resolves through the dialogue assets.
			for (let step in parse.Conversations[0].Steps)
			{
				if (step.Kind == .Sequence)
					step.Asset = Walk;
			}
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

/// The `Dialogue` script service from a behavior: it binds a speaker, sets a flag, plays a
/// conversation and answers each notice through the facade, reading a notice's fields and its
/// answers and arguments by method.
class DialogueScriptTests
{
	static bool sRegistered = false;

	/// A conversation that reads a flag set from script, shows a line, walks the keeper (whoever
	/// plays them), offers a choice and, on the second answer, a command that waits.
	const String cTalk = "conversation gate\n" +
		"if met\n" +
		"  @ keeper: Welcome back.\n" +
		"end\n" +
		"sequence walk\n" +
		"choice\n" +
		"> Stay.\n" +
		"> Go.\n" +
		"  cue lights out\n" +
		"end\n";

	/// A run wired as the application wires one for its scripts: its run host bound to the
	/// engine's surface with the dialogue's types on it, its scenes composed with the script
	/// managers; the runner and the `Dialogue` service in it, as the plugin's contributions put
	/// them.
	class ScriptedRun
	{
		public DialogueRunTests.DialogueStore Store;
		public DialogueSettings Settings = new .();
		public ScriptSurface Surface = new .();
		public ApplicationRun Run;
		public DialogueRunService Runner;
		ResourceSource mSource;
		delegate void(Scene) mInstaller;
		List<BehaviorClass> mClasses = new .();
		int mHarvested = 0;

		public this(StringView talk)
		{
			if (!sRegistered)
			{
				AngelScriptBackend.Register();
				ScriptResources.RegisterAll();
				sRegistered = true;
			}
			Store = new .(talk);
			EngineScriptSurface.Populate(Surface);
			DialogueScriptSurface.Populate(Surface);
			Run = new .();
			Run.RunHost.Configure = new (runtime) =>
				{
					runtime.Bind(Surface);
					for (let p in runtime.Problems)
						Console.WriteLine("  {}", p);
					ClearAndDeleteItems!(runtime.Problems);
				};
			mInstaller = new (scene) =>
				{
					BehaviorScene.AddBehaviorSceneManagers(scene);
					scene.GetSystem<BehaviorSystem>().SetRunHost(RunServices.Get<BehaviorRunHost>(scene.Run));
					SequenceDomain.AddSequenceSceneSystems(scene);
				};
			Run.Scenes.SetSceneInstaller(mInstaller);
			let resources = Store.Resources;
			mSource = new .(new () => resources);
			Run.RunHost.SetService(mSource);
			Runner = Run.Add(new DialogueRunService(Settings, Run));
			Run.Add(new DialogueFacade(Run));
		}

		public ~this()
		{
			// The run first: its scenes and its scripts go before what they read.
			delete Run;
			ClearAndDeleteItems!(mClasses);
			delete mClasses;
			delete mInstaller;
			delete mSource;
			delete Surface;
			delete Settings;
			delete Store;
		}

		/// Compiles and harvests a class through the run's own runtime, as the cook does.
		public BehaviorClass Class(StringView className, StringView source, BehaviorKind kind)
		{
			let runtime = Run.RunHost.EnsureRuntime(AngelScriptBackend.cLanguage);
			Test.Assert(runtime != null);
			let module = scope $"harvest#{mHarvested++}";
			let ok = runtime.Compile(module, "Game.as", source);
			for (let p in runtime.Problems)
				Console.WriteLine("  {}", p);
			Test.Assert(ok, "the class compiled");
			let record = scope BehaviorClassSource();
			record.Language.Set(AngelScriptBackend.cLanguage);
			record.ClassName.Set(className);
			record.Kind = kind;
			record.SourceName.Set("Game.as");
			record.Source.Set(source);
			Test.Assert(ScriptHarvest.Harvest(runtime, module, className, record), "harvested");
			runtime.DiscardModule(module);
			let product = new BehaviorClass();
			product.From(record);
			mClasses.Add(product);
			return product;
		}

		/// Frames of the run: its script and services ticked, its bus drained, its scenes updated.
		public void Step(int frames, float dt)
		{
			for (int i < frames)
			{
				Run.TickScript(dt, 1.0f);
				Run.DrainRunEvents();
				Run.Scenes.Update(FrameTime(dt));
			}
		}
	}

	[Test]
	public static void AnAngelScriptBehaviorPlaysAConversationThroughDialogueAndAnswersItsNotices()
	{
		let r = scope ScriptedRun(cTalk);
		let director = r.Class("Director", scope $$"""
			class Director
			{
				Entity self;
				string log;
				void say(const string &in what) { log += "|" + what; }
				void onStart()
				{
					Dialogue.Bind("keeper", self);
					Dialogue.SetFlag("met", true);
					if (Dialogue.Play(Guid::FromString("{{r.Store.Gate}}"), "gate") && Dialogue.IsPlaying()) { say("playing"); }
				}
				void onDialogueLine(DialogueLineNotice@ notice)
				{
					say(notice.ShownName + ": " + notice.Text);
					Dialogue.Advance();
				}
				void onDialogueChoice(DialogueChoiceNotice@ notice)
				{
					say(notice.Answer(0) + " or " + notice.Answer(1));
					Dialogue.Choose(1);
				}
				void onDialogueCommand(DialogueCommandNotice@ notice)
				{
					say(notice.Name + " " + notice.Text("event"));
					if (notice.Waits) { Dialogue.Done(); }
				}
				void onDialogueEnded(DialogueEndedNotice@ notice)
				{
					say("ended " + notice.Conversation + (Dialogue.Flag("met") ? " met" : ""));
				}
			}
			""", .Entity);
		Test.Assert(r.Run.StartRunBehavior(r.Class("Game", "class Game { void onStart() {} }", .Run)));

		let level = r.Run.CreateScene("level");
		r.Run.SetScene(level);
		let actor = level.CreateEntity("director");
		let behavior = new AttachedBehavior();
		behavior.BehaviorClass.SetDirect(director);
		level.GetSystem<BehaviorComponentManager>().Add(actor).Behaviors.Add(behavior);
		level.Start();
		level.SetSimulationEnabled(true);
		r.Step(8, 0.25f);

		let instance = level.GetSystem<BehaviorComponentManager>().Get(actor).Behaviors[0].Instance;
		Test.Assert(instance != null, "the director runs");
		var log = ScriptValue.Nil;
		r.Run.RunHost.Runtime.GetProperty(instance, "log", ref log);
		Test.Assert(log.AsString == "|playing|The Keeper: Welcome back.|Stay. or Go.|cue lights out|ended gate met", scope $"heard '{log.AsString}'");
		Test.Assert(!r.Runner.IsPlaying);
		Test.Assert(Math.Abs(level.GetLocalTransform(actor).Position.X - 10.0f) < 1e-3f, "the keeper, bound to the director, walked");
	}

	/// Outside every run, the idle service refuses each call and does nothing.
	[Test]
	public static void TheIdleServiceRefusesEveryCall()
	{
		let idle = scope DialogueFacade(null);
		Test.Assert(!idle.Play(Guid(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11), "gate"));
		Test.Assert(!idle.IsPlaying() && !idle.Advance() && !idle.Choose(0) && !idle.Done() && !idle.Resume());
		Test.Assert(!idle.Flag("met"));
		idle.SetFlag("met", true);
		idle.Stop();
		idle.Bind("keeper", .Invalid);
	}
}
