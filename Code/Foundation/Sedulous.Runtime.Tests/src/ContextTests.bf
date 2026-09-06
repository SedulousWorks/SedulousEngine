using System;
using Sedulous.Runtime;

namespace Sedulous.Runtime.Tests;

/// The context that owns the engine's subsystems and drives them.
class ContextTests
{
	[Test]
	public static void ASubsystemIsFoundByItsType()
	{
		let context = scope Context();
		Trace.Clear();

		Test.Assert(!context.HasSubsystem<Middle>());
		Test.Assert(context.GetSubsystem<Middle>() == null);

		let added = context.AddSubsystem<Middle>();
		Test.Assert(added != null);
		Test.Assert(context.HasSubsystem<Middle>());
		Test.Assert(context.GetSubsystem<Middle>() === added);
		Test.Assert(context.SubsystemCount == 1);

		// A different type is a different subsystem, not this one under another name.
		Test.Assert(context.GetSubsystem<Late>() == null);
	}

	/// Startup runs Init for EVERY subsystem before any Ready. A subsystem looking for its
	/// peers in Ready must find them initialised, which a single interleaved pass would
	/// not guarantee.
	[Test]
	public static void StartupInitialisesEverythingBeforeAnythingIsReady()
	{
		let context = scope Context();
		Trace.Clear();

		context.AddSubsystem<Early>();
		context.AddSubsystem<Late>();
		context.Startup();

		let order = scope String();
		Trace.Join(order);
		Test.Assert(order == "early.init,late.init,early.ready,late.ready", scope $"got {order}");
		Test.Assert(context.IsRunning);
	}

	/// Frame phases and startup run in ascending UpdateOrder; teardown runs in reverse, so
	/// a subsystem comes down before whatever it was built on.
	[Test]
	public static void OrderIsAscendingForStartupAndReverseForShutdown()
	{
		let context = scope Context();
		Trace.Clear();

		// Registered out of order on purpose.
		context.AddSubsystem<Late>();
		context.AddSubsystem<Early>();
		context.AddSubsystem<Middle>();

		context.Startup();
		Test.Assert(Trace.Before("early.init", "middle.init"));
		Test.Assert(Trace.Before("middle.init", "late.init"));

		Trace.Clear();
		context.Update(0.016f);
		let updates = scope String();
		Trace.Join(updates);
		Test.Assert(updates == "early.update,middle.update,late.update", scope $"got {updates}");

		Trace.Clear();
		context.Shutdown();
		Test.Assert(Trace.Before("late.prepare", "early.prepare"), "reverse order");
		Test.Assert(Trace.Before("late.shutdown", "early.shutdown"));
		// Every prepare runs before any shutdown, so peers are still alive while they let
		// go of each other.
		Test.Assert(Trace.Before("early.prepare", "late.shutdown"));
		Test.Assert(!context.IsRunning);
	}

	/// Two subsystems sharing an order keep the sequence they were registered in.
	[Test]
	public static void EqualOrdersKeepRegistrationSequence()
	{
		Trace.Clear();

		let first = new Recording("first", 5);
		let second = new Recording("second", 5);
		// The context has to go FIRST: its teardown unregisters what it is driving, and a
		// borrowed subsystem deleted before that leaves it walking freed objects.
		{
			let context = scope Context();
			context.RegisterSubsystem(first);
			context.RegisterSubsystem(second);
			context.Update(0.0f);
		}
		delete first;
		delete second;

		Test.Assert(Trace.Before("first.update", "second.update"), "stable sort");
	}

	/// Every frame phase reaches every subsystem.
	[Test]
	public static void EveryFramePhaseReachesEverySubsystem()
	{
		let context = scope Context();
		Trace.Clear();

		let subsystem = context.AddSubsystem<Middle>();
		context.Startup();

		Trace.Clear();
		context.BeginFrame(0.016f);
		context.Update(0.016f);
		context.PostUpdate(0.016f);
		context.EndFrame();

		let phases = scope String();
		Trace.Join(phases);
		Test.Assert(phases == "middle.begin,middle.update,middle.post,middle.end", scope $"got {phases}");
		Test.Assert(subsystem.Updates == 1);
	}

	/// A subsystem added to a RUNNING context is brought up immediately, rather than
	/// sitting uninitialised waiting for a Startup that has already happened.
	[Test]
	public static void AddingToARunningContextBringsItUpAtOnce()
	{
		let context = scope Context();
		Trace.Clear();

		context.Startup();
		Test.Assert(context.IsRunning);

		let late = context.AddSubsystem<Middle>();
		Test.Assert(late.IsInitialized, "it did not wait for a Startup that is already past");
		Test.Assert(late.Inits == 1);
		Test.Assert(late.Readies == 1);
	}

	/// Init and Shutdown are guarded, so a subsystem brought up on registration is not
	/// brought up a second time by the Startup that follows.
	[Test]
	public static void BringingUpTwiceDoesNothingTheSecondTime()
	{
		let context = scope Context();
		Trace.Clear();

		context.Startup();
		let subsystem = context.AddSubsystem<Middle>();
		Test.Assert(subsystem.Inits == 1);

		context.Startup(); // again
		Test.Assert(subsystem.Inits == 1, "Init is guarded");

		context.Shutdown();
		Test.Assert(subsystem.Shutdowns == 1);
		context.Shutdown();
		Test.Assert(subsystem.Shutdowns == 1, "and so is Shutdown");
	}

	/// Removing shuts the subsystem down and unhooks it from the frame phases.
	[Test]
	public static void RemovingShutsDownAndDetaches()
	{
		let context = scope Context();
		Trace.Clear();

		context.AddSubsystem<Middle>();
		context.Startup();
		Trace.Clear();

		context.RemoveSubsystem<Middle>();

		Test.Assert(Trace.Has("middle.prepare"));
		Test.Assert(Trace.Has("middle.shutdown"));
		Test.Assert(!context.HasSubsystem<Middle>());
		Test.Assert(context.SubsystemCount == 0);

		Trace.Clear();
		context.Update(0.0f);
		Test.Assert(Trace.Lines.IsEmpty, "it no longer runs in a frame");

		// Removing something that is not there is not an error.
		context.RemoveSubsystem<Middle>();
		context.RemoveSubsystem<Late>();
	}

	/// A registered subsystem is the CALLER's, and removing it must not destroy it.
	[Test]
	public static void ARegisteredSubsystemIsNotDestroyedByTheContext()
	{
		let borrowed = new Recording("borrowed", 0);
		defer delete borrowed;

		{
			let context = scope Context();
			Trace.Clear();
			context.RegisterSubsystem(borrowed);
			context.Startup();
			context.RemoveSubsystem<Recording>();
			Test.Assert(!context.HasSubsystem<Recording>());
		}

		// Still alive after the context is gone, so the deferred delete above is the only
		// one and not a double free.
		borrowed.Label.Set("still here");
		Test.Assert(borrowed.Label == "still here");
	}

	/// Disposing tears down what the context owns and is idempotent, so an explicit call
	/// and the destructor do not both do it.
	[Test]
	public static void DisposeIsIdempotent()
	{
		let context = scope Context();
		Trace.Clear();

		context.AddSubsystem<Middle>();
		context.Startup();
		Trace.Clear();

		context.Dispose();
		// Read through the trace, not through the subsystem: Dispose DESTROYS what the
		// context owns, so any pointer to one is dead the moment it returns.
		Test.Assert(Trace.IndexOf("middle.shutdown") >= 0);
		Test.Assert(context.SubsystemCount == 0);

		Trace.Clear();
		context.Dispose();
		context.Dispose();
		Test.Assert(Trace.Lines.IsEmpty, "the second and third calls did nothing at all");
		Test.Assert(context.SubsystemCount == 0);
	}

	/// Time scale is clamped at zero. A negative would run every accumulator backwards,
	/// which is never what a caller pausing the game means.
	[Test]
	public static void TimeScaleClampsAtZero()
	{
		let context = scope Context();
		Test.Assert(context.TimeScale == 1.0f, "realtime by default");

		context.TimeScale = 0.5f;
		Test.Assert(context.TimeScale == 0.5f);

		context.TimeScale = 0.0f;
		Test.Assert(context.TimeScale == 0.0f, "paused");

		context.TimeScale = -2.0f;
		Test.Assert(context.TimeScale == 0.0f, "not run backwards");
	}

	[Test]
	public static void TheFixedStepIsPlainConfiguration()
	{
		let context = scope Context();
		Test.Assert(context.FixedTimeStep > 0.0f, "sixty hertz by default");

		context.FixedTimeStep = 1.0f / 30.0f;
		Test.Assert(context.FixedTimeStep == 1.0f / 30.0f);
	}
}
