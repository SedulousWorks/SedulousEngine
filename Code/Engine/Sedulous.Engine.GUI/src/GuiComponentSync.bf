using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.GUI;
using Sedulous.GUI.Resources;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The components live: each canvas, billboard and world panel's tree in line with its
/// component every frame (BeginFrame), in its scene's root or a root of its own for a texture;
/// the billboards placed as each view draws.
///
/// A component's tree is built from its document and built again when the document's product
/// changes (a re-cook, another document); its own sheet styles it alone, over the game's. A
/// component is a struct in a packed pool and a Beef generic cannot reach a struct's fields by
/// name, so what Raptor's templates do for each kind is written over the fields they touch.
extension GuiSubsystem
{
	/// `field` holding a reference of its own to `value`, the old one let go.
	private static void Hold(ref SceneRoot field, SceneRoot value)
	{
		if (field === value)
			return;
		if (value != null)
			value.AddRef();
		if (field != null)
			field.ReleaseRef();
		field = value;
	}

	/// A component's tree built again when its document's product changed (a re-cook, another
	/// document): the old one out of wherever it was, the component's reference to it let go.
	/// True when it was.
	private bool RebuildIfChanged(GuiDocument document, ref Node root, ref GuiDocument builtFrom, ref GuiStyleSheet sheetFrom)
	{
		if (document === builtFrom)
			return false;
		if (root != null)
		{
			if (root.Parent != null)
				root.Parent.RemoveChild(root);
			root.ReleaseRef();
			root = null;
		}
		root = (document != null) ? BuildDocument(document) : null; // with the component's reference
		sheetFrom = null;
		builtFrom = document;
		return true;
	}

	/// A component's own sheet on its tree (in a GUI by now), again when its product changed.
	private void ApplySheet(GuiStyleSheet sheet, Node root, ref GuiStyleSheet sheetFrom, StringView name)
	{
		if ((root == null) || (sheet === sheetFrom))
			return;
		if (sheet != null)
		{
			// The style manager takes a copy.
			let parsed = scope StyleSheet();
			CSSParser.Parse(sheet.Css, name, parsed);
			mStyles.SetSubtreeSheet(root, parsed);
		}
		else
			mStyles.RemoveSubtreeSheet(root);
		sheetFrom = sheet;
	}

	/// The root of its own a texture's content (a render-texture canvas, a world panel) is drawn
	/// in: made for the entity the first time, holding `content` alone, kept while seen each
	/// frame. The texture roots' list keeps it; the caller holds its own.
	private SceneRoot TextureRootFor(Scene scene, EntityHandle entity, Node content)
	{
		GuiTextureRoot found = null;
		for (let known in mTextureRoots)
		{
			if ((known.Scene === scene) && (known.Entity == entity) && !known.Seen)
				found = known;
		}
		if (found == null)
		{
			found = new GuiTextureRoot();
			found.Scene = scene;
			found.Entity = entity;
			found.Root = new SceneRoot(mContext);
			using (Node.StyleWriteScope(found.Root))
			{
				found.Root.EditLayoutStyle(scope (s) => { s.Kind = .Stack; }); // the content fills it
			}
			// E4: the root's bridge made here (MakeBridge).
			mTextureRoots.Add(found);
		}
		found.Seen = true;
		if (content.Parent !== found.Root)
		{
			if (content.Parent != null)
				content.Parent.RemoveChild(content);
			while (found.Root.ChildCount > 0)
				found.Root.RemoveChild(found.Root.GetChildAt(0));
			found.Root.AddChild(content);
		}
		return found.Root;
	}

	/// Every scene tier's components in line, the texture roots no component claimed swept: the
	/// frame's sync, before the GUI's clock.
	private void SyncComponents()
	{
		for (let root in mTextureRoots)
			root.Seen = false;
		for (let tier in mSceneTiers)
		{
			SyncBillboards(tier);
			SyncCanvases(tier);
			SyncPanels(tier);
		}
		// The roots of textures whose canvas or panel went (their textures go as RenderTextures
		// next runs).
		for (int i = mTextureRoots.Count - 1; i >= 0; i--)
		{
			if (mTextureRoots[i].Seen)
				continue;
			// E4: the active and press roots forgotten when they are this one's.
			delete mTextureRoots[i];
			mTextureRoots.RemoveAt(i);
		}
	}

	/// Each canvas's tree in line with its component: built from its document (again when the
	/// document is cooked again), in its host in the scene's root or a root of its own for its
	/// texture, its sheet, shown while the canvas and its entity are; the hosts of canvases gone
	/// swept; the hosts ordered.
	private void SyncCanvases(GuiSceneTier tier)
	{
		let seen = scope List<GuiCanvasHost>();
		if (let canvases = tier.Scene.GetSystem<GuiCanvasComponentManager>())
		{
			canvases.ForEach(scope [&] (c, entity) =>
				{
					let wantsTexture = c.RenderMode == .RenderTexture;
					if (!RebuildIfChanged(c.Document.Get, ref c.Root, ref c.BuiltFrom, ref c.SheetFrom) && (c.Root != null)
						&& (wantsTexture != (c.RenderRoot != null)))
					{
						// Its mode changed: out of where it was, its sheet applied afresh where it goes.
						if (c.Root.Parent != null)
							c.Root.Parent.RemoveChild(c.Root);
						c.SheetFrom = null;
					}
					if (wantsTexture)
					{
						// Its host, unseen, is swept below.
						if (c.Host != null)
						{
							c.Host.ReleaseRef();
							c.Host = null;
						}
						Hold(ref c.RenderRoot, (c.Root != null) ? TextureRootFor(tier.Scene, entity, c.Root) : null);
					}
					else
					{
						Hold(ref c.RenderRoot, null);
						c.RenderTexture = null;
						c.RenderTextureView = null;
						if (c.Host == null)
						{
							// The component's reference, the root's, and the tier's list's.
							let made = new GuiCanvasHost();
							tier.Root.AddChild(made);
							made.AddRef();
							tier.Canvases.Add(made);
							c.Host = made;
						}
						let host = (GuiCanvasHost)c.Host;
						host.Configure(c.Order, c.ScalerMode, c.ReferenceResolution);
						seen.Add(host);
						if ((c.Root != null) && (c.Root.Parent == null))
							host.AddChild(c.Root);
					}
					if (c.Root == null)
						return;
					ApplySheet(c.Sheet.Get, c.Root, ref c.SheetFrom, "canvas");
					c.Root.Displayed = c.Visible && tier.Scene.IsEffectivelyActive(entity);
					c.Root.SetInert(!c.Interactive);
				});
		}
		// The hosts whose canvas went (despawned, the component removed, drawn into a texture
		// now), then the order: by `order`, stably, after whatever else the root holds.
		let hosts = scope List<GuiCanvasHost>();
		for (int i = 0; i < tier.Canvases.Count;)
		{
			let host = tier.Canvases[i];
			if (seen.Contains(host))
			{
				hosts.Add(host);
				i++;
				continue;
			}
			tier.Root.RemoveChild(host);
			tier.Canvases.RemoveAt(i);
			host.ReleaseRef(); // the list's
		}
		// In the root's order, for the sort.
		for (int i = 1; i < hosts.Count; i++)
		{
			for (int j = i; (j > 0) && (tier.Root.GetChildIndex(hosts[j]) < tier.Root.GetChildIndex(hosts[j - 1])); j--)
				Swap!(hosts[j - 1], hosts[j]);
		}
		bool sorted = true;
		for (int i = 1; i < hosts.Count; i++)
			sorted = sorted && (hosts[i - 1].Order <= hosts[i].Order);
		if (sorted)
			return;
		for (int i = 1; i < hosts.Count; i++) // stable insertion sort
		{
			for (int j = i; (j > 0) && (hosts[j - 1].Order > hosts[j].Order); j--)
				Swap!(hosts[j - 1], hosts[j]);
		}
		for (let host in hosts)
			tier.Root.SetChildIndex(host, tier.Root.ChildCount - 1);
	}

	/// Each billboard's tree in line with its component, in the scene's billboard layer (rebuilt
	/// when its document changes, its sheet, shown while it and its entity are); the trees of
	/// billboards gone swept. Where each shows is a view's (PlaceBillboards).
	private void SyncBillboards(GuiSceneTier tier)
	{
		let seen = scope List<Node>();
		if (let billboards = tier.Scene.GetSystem<GuiBillboardComponentManager>())
		{
			billboards.ForEach(scope [&] (c, entity) =>
				{
					RebuildIfChanged(c.Document.Get, ref c.Root, ref c.BuiltFrom, ref c.SheetFrom);
					if (c.Root == null)
						return;
					if (c.Root.Parent == null)
					{
						c.Root.EditLayoutStyle(scope (s) => { s.Placement = .Absolute; });
						tier.Billboards.AddChild(c.Root);
					}
					seen.Add(c.Root);
					ApplySheet(c.Sheet.Get, c.Root, ref c.SheetFrom, "billboard");
					c.Root.Displayed = c.Visible && tier.Scene.IsEffectivelyActive(entity);
				});
		}
		// The layer's half of each tree whose billboard went; the component's own half is its
		// pool's, let go as it is removed.
		for (int i = tier.Billboards.ChildCount - 1; i >= 0; i--)
		{
			let child = tier.Billboards.GetChildAt(i);
			if (!seen.Contains(child))
				tier.Billboards.RemoveChild(child);
		}
	}

	/// Each world panel's tree in line with its component, in a root of its own for its texture.
	/// Its pointer (the ray, hover, click) is the input pump's (E4).
	private void SyncPanels(GuiSceneTier tier)
	{
		let panels = tier.Scene.GetSystem<GuiWorldPanelComponentManager>();
		if (panels == null)
			return;
		panels.ForEach(scope [&] (c, entity) =>
			{
				RebuildIfChanged(c.Document.Get, ref c.Root, ref c.BuiltFrom, ref c.SheetFrom);
				Hold(ref c.RenderRoot, (c.Root != null) ? TextureRootFor(tier.Scene, entity, c.Root) : null);
				if (c.Root == null)
				{
					c.RenderTexture = null;
					c.RenderTextureView = null;
					return;
				}
				ApplySheet(c.Sheet.Get, c.Root, ref c.SheetFrom, "panel");
				c.Root.Displayed = c.Visible && tier.Scene.IsEffectivelyActive(entity);
				c.Root.SetInert(!c.Interactive);
			});
	}

	/// Each shown billboard placed for `view`: hung by its bottom centre on its projected point
	/// (its size the last layout's: a new one settles the next frame), scaled toward that point,
	/// hidden behind the camera, keeping its layout so nothing else moves.
	private void PlaceBillboards(GuiSceneTier tier, SceneOverlayView view)
	{
		let billboards = tier.Scene.GetSystem<GuiBillboardComponentManager>();
		if (billboards == null)
			return;
		let viewport = Float2((float)view.ViewportWidth, (float)view.ViewportHeight);
		billboards.ForEach(scope [&] (c, entity) =>
			{
				if ((c.Root == null) || !c.Root.Displayed)
					return;
				let placement = GuiWorldMath.PlaceBillboard(*c, tier.Scene.GetWorldMatrix(entity), view.ViewProjection,
					view.CameraPosition, viewport);
				c.Root.Visible = placement.Shown;
				if (!placement.Shown)
					return;
				let size = c.Root.Size;
				let corner = Float2(placement.Anchor.X - size.X * 0.5f, placement.Anchor.Y - size.Y);
				c.Root.EditLayoutStyle(scope (s) =>
					{
						s.Left = LayoutLength.Px(corner.X);
						s.Top = LayoutLength.Px(corner.Y);
					});
				c.Root.ScaleOrigin = .(size.X * 0.5f, size.Y);
				c.Root.Scale = .(placement.Scale, placement.Scale);
			});
	}

	/// Whether a scene's GUI shows anything: a canvas, or a billboard. Its draw (and E4's input
	/// with nothing under the pointer) passes it by otherwise.
	private static bool HasContent(GuiSceneTier tier) =>
		!tier.Canvases.IsEmpty || ((tier.Billboards != null) && (tier.Billboards.ChildCount > 0));
}
