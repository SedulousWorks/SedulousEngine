using System;
using Sedulous.Physics;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Integration;

/// The composition root adapter from physics contacts to the script layer's neutral
/// DeliverContact ingress.
///
/// Neither side knows the other: the physics subsystem publishes EntityContacts to its
/// listeners and the script subsystem takes a ScriptContactKind, so this is the one place
/// that names both, and it lives in a project the two never depend on. A host installs it
/// once both subsystems exist and uninstalls it before the physics subsystem goes.
class ScriptPhysicsContactBridge : IContactListener
{
	/// BORROWED, both.
	private PhysicsSubsystem mPhysics = null;
	private ScriptSubsystem mScripts = null;

	public ~this()
	{
		Uninstall();
	}

	public bool Installed => mPhysics != null;

	/// Points `physics` contacts at `scripts`. Calling again re-points cleanly, the prior
	/// registration dropped first, so re-wiring is safe.
	public void Install(PhysicsSubsystem physics, ScriptSubsystem scripts)
	{
		Uninstall();
		if ((physics == null) || (scripts == null))
			return;
		mScripts = scripts;
		mPhysics = physics;
		mPhysics.RegisterContactListener(this);
	}

	/// Unregisters from the physics subsystem. Idempotent; a no-op when not installed.
	public void Uninstall()
	{
		if (mPhysics != null)
		{
			mPhysics.UnregisterContactListener(this);
			mPhysics = null;
		}
		mScripts = null;
	}

	public static ScriptContactKind ToScriptContactKind(ContactKind kind)
	{
		switch (kind)
		{
		case .Begin: return .Begin;
		case .End: return .End;
		case .TriggerEnter: return .TriggerEnter;
		case .TriggerExit: return .TriggerExit;
		}
	}

	/// Only enqueues, as the listener contract asks: the script subsystem defers to its
	/// scene's queue.
	public void OnContact(EntityContact contact)
	{
		if (mScripts == null)
			return;
		mScripts.DeliverContact(contact.Scene, contact.A, contact.B, ToScriptContactKind(contact.Kind),
			contact.Point, contact.Normal, contact.Speed);
	}
}
