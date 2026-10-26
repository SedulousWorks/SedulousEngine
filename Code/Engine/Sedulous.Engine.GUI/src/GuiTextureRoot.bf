using System;
using Sedulous.GUI;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// A root of its own a texture's content is drawn in (a render-texture canvas's, a world
/// panel's), never in a scene's tier: made for its entity the first time, holding that content
/// alone, kept while its component claims it each frame.
class GuiTextureRoot
{
	/// BORROWED, and with the entity the key: compared, never followed once the scene goes.
	public Scene Scene = null;
	public EntityHandle Entity = .Invalid;
	/// A HELD reference; the component holds one of its own.
	public SceneRoot Root = null ~ _?.ReleaseRef();
	/// Claimed this frame; an unclaimed root goes at the end of the sync.
	public bool Seen = false;
	/// Its input, into the root's dispatcher (MakeBridge). OWNED; declared last, so it goes first.
	public GuiInputBridge Bridge = null ~ delete _;
}
