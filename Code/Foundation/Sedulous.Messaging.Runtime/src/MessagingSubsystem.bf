namespace Sedulous.Messaging.Runtime;

using System;
using Sedulous.Runtime;
using Sedulous.Messaging;

/// Subsystem that provides a MessageBus to the engine's Context.
/// Automatically drains queued messages each frame during Update.
///
/// Register:
///   context.RegisterSubsystem<MessagingSubsystem>(new MessagingSubsystem());
///
/// Retrieve:
///   let bus = context.GetSubsystem<MessagingSubsystem>().Bus;
public class MessagingSubsystem : Subsystem
{
	/// Updates early so other subsystems see drained messages in their Update.
	public override int32 UpdateOrder => -500;

	private MessageBus mBus;
	private bool mOwnsBus;

	/// The message bus managed by this subsystem.
	public MessageBus Bus => mBus;

	/// Creates a MessagingSubsystem with a new DefaultMessageBus.
	public this()
	{
		mBus = new DefaultMessageBus();
		mOwnsBus = true;
	}

	/// Creates a MessagingSubsystem with a caller-provided bus.
	/// If ownsBus is true, the subsystem takes ownership and deletes
	/// the bus on dispose.
	public this(MessageBus bus, bool ownsBus = true)
	{
		mBus = bus;
		mOwnsBus = ownsBus;
	}

	/// Drains queued messages each frame.
	public override void Update(float deltaTime)
	{
		mBus.Drain();
	}

	/// Drains remaining messages before shutdown.
	protected override void OnShutdown()
	{
		mBus.Drain();
	}

	public override void Dispose()
	{
		if (mOwnsBus && mBus != null)
		{
			mBus.Dispose();
			delete mBus;
			mBus = null;
		}
		base.Dispose();
	}
}
