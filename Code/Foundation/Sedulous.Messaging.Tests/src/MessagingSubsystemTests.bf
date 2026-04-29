namespace Sedulous.Messaging.Tests;

using System;
using Sedulous.Messaging;
using Sedulous.Messaging.Runtime;
using Sedulous.Runtime;

class MessagingSubsystemTests
{
	[Test]
	public static void Subsystem_RegisterAndRetrieve()
	{
		let context = scope Context();
		let subsystem = new MessagingSubsystem();
		context.RegisterSubsystem<MessagingSubsystem>(subsystem);

		let retrieved = context.GetSubsystem<MessagingSubsystem>();
		Test.Assert(retrieved != null);
		Test.Assert(retrieved.Bus != null);
	}

	[Test]
	public static void Subsystem_DrainOnUpdate()
	{
		let context = scope Context();
		let subsystem = new MessagingSubsystem();
		context.RegisterSubsystem<MessagingSubsystem>(subsystem);
		context.Startup();

		int32 received = 0;
		var handle = subsystem.Bus.Subscribe<TestMessage>(new [&received](msg) =>
			{
				received = msg.Value;
			});

		TestMessage msg = .() { Value = 77 };
		subsystem.Bus.Queue<TestMessage>(msg);
		Test.Assert(received == 0);

		context.Update(0.016f); // triggers subsystem.Update -> Drain
		Test.Assert(received == 77);

		subsystem.Bus.Unsubscribe(handle);
	}

	[Test]
	public static void Subsystem_PublishImmediateBypassesDrain()
	{
		let context = scope Context();
		let subsystem = new MessagingSubsystem();
		context.RegisterSubsystem<MessagingSubsystem>(subsystem);
		context.Startup();

		int32 received = 0;
		var handle = subsystem.Bus.Subscribe<TestMessage>(new [&received](msg) =>
			{
				received = msg.Value;
			});

		// Publish delivers immediately, no Drain needed
		TestMessage msg = .() { Value = 55 };
		subsystem.Bus.Publish<TestMessage>(ref msg);
		Test.Assert(received == 55);

		subsystem.Bus.Unsubscribe(handle);
	}

	[Test]
	public static void Subsystem_UpdateOrder()
	{
		let subsystem = new MessagingSubsystem();
		Test.Assert(subsystem.UpdateOrder == -500);
		subsystem.Dispose();
		delete subsystem;
	}

	[Test]
	public static void Subsystem_CustomBusInjection()
	{
		let bus = new DefaultMessageBus();
		let subsystem = new MessagingSubsystem(bus, true);
		Test.Assert(subsystem.Bus == bus);
		subsystem.Dispose(); // cleans up owned bus
		Test.Assert(subsystem.Bus == null);
		delete subsystem;
	}
}
