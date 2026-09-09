using System;
using System.Collections;

namespace Sedulous.Render;

/// The registered renderers, in registration order.
///
/// A renderer's INDEX here is its dispatch id, which producers stamp onto their render data:
/// that is what routes a draw to the renderer that understands its concrete type, even where
/// two renderers share a category.
class RendererRegistry
{
	private List<Renderer> mUnique = new .() ~ delete _;

	/// BORROWED: the caller owns the renderer's lifetime.
	public void Register(Renderer renderer)
	{
		if (renderer == null)
			return;

		for (let existing in mUnique)
		{
			if (existing == renderer)
				return;
		}

		renderer.RendererId = (uint16)mUnique.Count;
		mUnique.Add(renderer);
	}

	public Renderer ById(uint16 id) => (id < (uint16)mUnique.Count) ? mUnique[id] : null;

	public Span<Renderer> Unique => .(mUnique.Ptr, mUnique.Count);
	public int Count => mUnique.Count;
}
