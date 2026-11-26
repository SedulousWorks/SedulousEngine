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
using Sedulous.Runtime;
using Sedulous.Engine.GUI;
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
	/// its cast (the keeper played by "Keeper") and a sequence that walks its binding "keeper", and
	/// "Cart" (no speaker), to X 10 over a second, which the conversation's `sequence walk` plays.
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
		public Guid CastId;
		/// Where a test authors more (a sequence of its own).
		public ContentDatabase Database => mDb;
		public Guid Walk;

		public this(StringView talk = cStaged)
		{
			DialogueResources.RegisterAll();
			DialogueResources.RegisterAll(mTypes);
			SequenceResources.RegisterAll();
			SequenceResources.RegisterAll(mTypes);
			// What the plugin's load registers: the line track kind.
			SequenceTracks.Register<DialogueLineTrack>();
			mTypes.Register(TypeIdOf(typeof(DialogueLineTrack).GetFullName(.. scope .())), () => new DialogueLineTrack());
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
			// A second part named for no speaker: the level entity of that name (a prop).
			walk.Sequence.Bindings.Add(new .("Cart"));
			let roll = new PropertySequenceTrack();
			roll.Binding = 1;
			roll.Property.ComponentType.Set(TrackTargets.cTransform);
			roll.Property.PropertyPath.Set("Position");
			roll.Property.Kind = .Float3;
			roll.Property.Channels[0].AddKey(.(0.0f, 0.0f));
			roll.Property.Channels[0].AddKey(.(1.0f, 10.0f));
			walk.Sequence.Tracks.Add(roll);
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
			CastId = castInstance.Id;

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
		public DialogueStore Store ~ delete _;
		public DialogueSettings Settings = new .() ~ delete _;
		public ApplicationRun Run = new .() ~ delete _;
		ResourceSource mSource ~ delete _;
		public Scene World ~ delete _;
		public PostProcessSystem Post;
		/// The run's: it holds it, as the plugin's contribution puts it there.
		public DialogueRunService Runner;
		public List<String> Lines = new .() ~ DeleteContainerAndItems!(_);
		delegate void(Variant) mHeard ~ delete _;

		public this(StringView talk = cStaged)
		{
			Store = new .(talk);
			let resources = Store.Resources;
			mSource = new .(new () => resources);
			Run.Get<BehaviorRunHost>().SetService(mSource);
			World = new .("dialogue");
			Run.SetScene(World);
			SequenceDomain.AddSequenceSceneSystems(World);
			Post = World.AddSystem<PostProcessSystem>();
			Runner = Run.Add(new DialogueRunService(Settings, Run));
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
			Run.RemoveService(typeof(DialogueRunService));
			Runner = null;
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
		let cart = r.World.CreateEntity("Cart");
		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));

		r.Frame(0.5f);
		Test.Assert(Near(r.Post.Fade.Amount, 0.5f));
		r.Frame(0.5f); // the fade out ends; the sequence starts, held at full black
		Test.Assert(Near(r.Post.Fade.Amount, 1.0f));
		Test.Assert(r.Runner.Waiting == .Staging);
		for (int i < 5)
			r.Frame(0.25f);
		Test.Assert(Near(r.X(keeper), 10.0f));
		Test.Assert(Near(r.X(cart), 10.0f), "the prop by its name");
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

	/// A sequence's line track: the play shows each line through the run's runner and holds at its
	/// end until it is advanced.
	[Test]
	public static void ASequencesLineTrackShowsItsLineThroughTheRunsRunnerAndHoldsUntilItIsAdvanced()
	{
		let r = scope Stage();
		// A sequence of one line track, cooked and loaded as any sequence: two lines, the second's
		// text from the dialogue file.
		let instance = r.Store.Database.RootGroup.CreateInstance("cutscene", typeof(SequenceSource).GetFullName(.. scope .()));
		{
			let source = scope SequenceSource();
			let lines = new DialogueLineTrack();
			lines.Cast.SetId(r.Store.CastId);
			let first = new DialogueLineSection();
			first.Start = 0.5f;
			first.Length = 1.0f;
			first.Speaker.Set("keeper");
			first.Text.Set("Look.");
			lines.Sections.Add(first);
			let second = new DialogueLineSection();
			second.Start = 2.0f;
			second.Length = 1.0f;
			second.Speaker.Set("keeper");
			second.Dialogue.SetId(r.Store.Gate);
			second.LineId.Set("gate.1");
			lines.Sections.Add(second);
			source.Sequence.Tracks.Add(lines);
			source.Sequence.Duration = 4.0f;
			Test.Assert(instance.WriteObject(source) case .Ok);
		}
		Test.Assert(SequenceTracks.IsRegistered(typeof(DialogueLineTrack)), "the sequence panel's Track menu offers it");

		let system = r.World.GetSystem<SequenceSystem>();
		let loaded = r.Store.Resources.Bind<SequenceResource>(instance.Id).Get;
		Test.Assert(loaded != null);
		Test.Assert(loaded.Sequence.Tracks.Count == 1);
		let play = system.Play(loaded, instance.Id);
		for (int i < 4)
			r.Frame(0.5f); // past the first line's end at 1.5: held there
		Test.Assert(r.Lines.Count == 1);
		Test.Assert(r.Lines[0] == "The Keeper: Look.");
		Test.Assert(system.Find(play) != null);
		Test.Assert(Near(system.Find(play).Time, 1.5f));
		Test.Assert(system.Find(play).IsHeld);

		Test.Assert(r.Runner.Advance());
		for (int i < 4)
			r.Frame(0.5f);
		Test.Assert(r.Lines.Count == 2);
		Test.Assert(r.Lines[1] == "The Keeper: Done.", "the dialogue file's line gate.1");
		Test.Assert(Near(system.Find(play).Time, 3.0f));
		Test.Assert(r.Runner.Advance());
		for (int i < 4)
			r.Frame(0.5f);
		Test.Assert(system.Find(play) == null, "played to its end");
	}

	/// The stock box on a real GUI: the line typed out, a press finishing it then advancing, an
	/// answer pressed, the box gone at the end.
	[Test]
	public static void TheStockBoxTypesALineTakesAPressToFinishItAndAnotherToAdvanceAndItsAnswers()
	{
		let dataRoot = FindDataRoot(.. scope .());
		let data = scope NativeFileSystem(dataRoot);
		let gui = new GuiSubsystem(data);
		defer delete gui;
		let application = scope SubsystemManager();
		application.RegisterSubsystem<GuiSubsystem>(gui);
		application.Startup();
		// Disposed while the borrowed GUI lives: unregistering it needs it.
		defer application.Dispose();
		let r = scope Stage(DialogueScriptTests.cTalk);
		r.Run.RunHost.Subsystems = application;
		r.Settings.StockBox = true;
		r.Settings.TypingSpeed = 10;
		r.Runner.SetFlag("met", true);
		let stockBox = r.Runner.Box;

		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));
		Test.Assert(stockBox.IsShown);
		Test.Assert(stockBox.IsStyled, "its sheet over the box alone");
		Test.Assert(gui.Screens.Top === stockBox.ScreenNode);
		Test.Assert(stockBox.ShownName == "The Keeper");
		Test.Assert(stockBox.ShownText.IsEmpty);
		r.Frame(0.25f);
		Test.Assert(stockBox.ShownText == "We", "ten a second: two and a half shown");
		Test.Assert(stockBox.IsTyping);
		stockBox.PressBox(); // finishes the typing
		r.Frame(0.0f);
		Test.Assert(stockBox.ShownText == "Welcome back.");
		Test.Assert(r.Runner.Waiting == .Line);
		stockBox.PressBox(); // advances
		r.Frame(0.0f);
		Test.Assert(r.Runner.Waiting == .Choice);
		Test.Assert(stockBox.AnswerCount == 2);
		Test.Assert(stockBox.AnswerText(1) == "Go.");
		Test.Assert(stockBox.AnswerText(2).IsEmpty, "none past the last");
		Test.Assert(stockBox.Update(0.0f, false).Choose == -1, "no press, no answer");
		Test.Assert(stockBox.Update(0.0f, true).Choose == 0, "the advance action: the focused answer, the first");
		stockBox.Focus(1);
		Test.Assert(stockBox.Update(0.0f, true).Choose == 1, "the advance action: the focused answer");
		stockBox.Press(1); // Go.
		r.Frame(0.0f);
		Test.Assert(r.Runner.Waiting == .Command);
		Test.Assert(r.Runner.Done());
		Test.Assert(!r.Runner.IsPlaying);
		Test.Assert(!stockBox.IsShown, "gone with the conversation");
		Test.Assert(!stockBox.IsStyled);
		Test.Assert(gui.Screens.Top == null, "popped");
	}

	/// A preview shows the stock box though the project's settings leave it off, and takes its
	/// presses while it shows it.
	[Test]
	public static void APreviewShowsTheStockBoxWithTheSettingOff()
	{
		let dataRoot = FindDataRoot(.. scope .());
		let data = scope NativeFileSystem(dataRoot);
		let gui = new GuiSubsystem(data);
		defer delete gui;
		let application = scope SubsystemManager();
		application.RegisterSubsystem<GuiSubsystem>(gui);
		application.Startup();
		// Disposed while the borrowed GUI lives: unregistering it needs it.
		defer application.Dispose();
		let r = scope Stage(DialogueScriptTests.cTalk);
		r.Run.RunHost.Subsystems = application;
		r.Settings.StockBox = false;
		r.Settings.TypingSpeed = 0;
		r.Runner.SetFlag("met", true);
		let stockBox = r.Runner.Box;

		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));
		Test.Assert(!stockBox.IsShown, "off in the settings");
		r.Runner.Stop();

		r.Runner.Host.ShowStockBox(true);
		Test.Assert(r.Runner.Play(r.Store.Gate, "gate"));
		Test.Assert(stockBox.IsShown, "a preview shows it");
		Test.Assert(stockBox.ShownText == "Welcome back.");
		stockBox.PressBox();
		r.Frame(0.0f);
		Test.Assert(r.Runner.Waiting == .Choice, "the box's press advances");
		Test.Assert(stockBox.AnswerCount == 2);

		r.Runner.Host.ShowStockBox(false);
		stockBox.Press(1);
		r.Frame(0.0f);
		Test.Assert(r.Runner.Waiting == .Choice, "off again: the box's presses are not taken");
		r.Runner.Stop();
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
		r.Run.RemoveService(typeof(DialogueRunService));
		r.Runner = null;
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
	public const String cTalk = "conversation gate\n" +
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
			Run.RunHost.Scripts.Configure = new (runtime) =>
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
			let runtime = Run.RunHost.Scripts.EnsureRuntime(AngelScriptBackend.cLanguage);
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
		r.Run.RunHost.Scripts.Runtime.GetProperty(instance, "log", ref log);
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
