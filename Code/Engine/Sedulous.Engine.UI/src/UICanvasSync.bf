using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.UI.Resource;

namespace Sedulous.Engine.UI;

/// The per frame reconciliation between the components and the view trees.
///
/// A document is a TEMPLATE: each canvas gets a fresh tree, a reload rebuilds it, and a theme
/// override parses per canvas as a local stylesheet. Canvases and billboards parent into
/// THEIR OWN SCENE's root, so one scene's interface can never bleed into another's by
/// construction rather than by discipline.
extension UISubsystem
{
	/// Attaches a view a parent will own. The tree's reference is separate from the
	/// component's, which is why the count goes up before the parent takes it: adding
	/// CONSUMES a reference, and the component is still holding its own.
	private static void AttachOwned(ViewGroup parent, View child)
	{
		child.AddRef();
		parent.AddView(child);
	}

	/// The mirror: the parent lets go of its reference, and then the component lets go of
	/// the one it was keeping.
	private static void DetachOwned(ViewGroup parent, ref View child)
	{
		if (child == null)
			return;

		if (parent != null)
			parent.RemoveView(child);

		child.ReleaseRef();
		child = null;
	}

	private void SyncCanvases()
	{
		for (let entry in mTextureCanvasRoots)
			entry.Seen = false;

		for (let sceneUI in mSceneUIs)
		{
			let scene = sceneUI.Scene;

			if (let canvases = scene.GetSystem<UICanvasComponentManager>())
				SyncScreenCanvases(sceneUI, scene, canvases);

			if (let billboards = scene.GetSystem<UIBillboardComponentManager>())
				SyncBillboards(sceneUI, billboards);

			if (let panels = scene.GetSystem<UIWorldPanelComponentManager>())
				SyncWorldPanels(panels);
		}

		// Sweep the standalone roots whose component has gone, whether by despawn, by removal
		// or with the scene. They are UNREGISTERED from the context, which stores roots
		// WITHOUT owning them so a stale registration would dangle, and then the reference
		// keeping them alive is dropped. A rebuild above has already unregistered its own, and
		// removing twice is harmless.
		for (int i = mTextureCanvasRoots.Count - 1; i >= 0; i--)
		{
			if (mTextureCanvasRoots[i].Seen)
				continue;

			mContext.RemoveRootView(mTextureCanvasRoots[i].Root);
			mTextureCanvasRoots[i].Root.ReleaseRef();
			delete mTextureCanvasRoots[i];
			mTextureCanvasRoots.RemoveAt(i);
		}
	}

	private void SyncScreenCanvases(UISceneUI sceneUI, Scene scene,
		UICanvasComponentManager canvases)
	{
		// MARK: a host whose component vanished this frame is swept after the walk. A
		// manager has no destroy hook, and despawning a menu entity still has to take its
		// tree out of the scene root.
		for (int i < sceneUI.Root.ChildCount)
		{
			if (let host = sceneUI.Root.GetChildAt(i) as CanvasHostView)
				host.Seen = false;
		}

		canvases.ForEach(scope [&] (component, owner) =>
			{
				BuildCanvas(sceneUI, component);
				PlaceCanvas(sceneUI, component);
				ApplyCanvasTheme(component);

				if (component.Root != null)
				{
					component.Root.Visibility = (component.Visible
						&& scene.IsEffectivelyActive(owner)) ? .Visible : .Gone;

					// Interactivity gates the SUBTREE, while the stretched document root
					// itself stays hit TRANSPARENT. The canvas root is the canvas's screen
					// AREA rather than a widget: if it consumed hits, one full screen heads
					// up display would swallow the pointer everywhere, taking the world
					// panels and the gameplay clicks with it. Content that wants a clickable
					// backdrop says so with an explicit full size child.
					component.Root.IsInteractionEnabled = component.Interactive;
					component.Root.IsHitTestVisible = false;
				}
			});

		// Sweep the hosts orphaned by a component or entity going away, then keep the
		// canvases stacked by the order they were authored with. The billboard layer stays
		// below them all.
		for (int i = sceneUI.Root.ChildCount - 1; i >= 0; i--)
		{
			let host = sceneUI.Root.GetChildAt(i) as CanvasHostView;
			if ((host != null) && !host.Seen)
				sceneUI.Root.RemoveView(host);
		}

		CanvasHostView.SortByOrder(sceneUI.Root);
	}

	/// Instantiates or rebuilds one canvas's tree, which happens on a document reload or when
	/// the render mode flips between the two shapes.
	private void BuildCanvas(UISceneUI sceneUI, UICanvasComponent* component)
	{
		let document = component.Document.Get;
		let wantsTexture = component.RenderMode == .RenderTexture;
		let builtAsTexture = component.RenderRoot != null;

		if ((document === component.BuiltFrom)
			&& !((component.Root != null) && (wantsTexture != builtAsTexture)))
		{
			MarkTextureRootSeen(component.RenderRoot);
			return;
		}

		// Tear down whichever shape was built, then instantiate for the CURRENT mode.
		if (component.Root != null)
		{
			if (component.Host != null)
				component.Host.RemoveView(component.Root);
			if (component.RenderRoot != null)
				component.RenderRoot.RemoveView(component.Root);

			component.Root.ReleaseRef();
			component.Root = null;
		}

		if (component.RenderRoot != null)
		{
			mContext.RemoveRootView(component.RenderRoot);
			component.RenderRoot.ReleaseRef();
			component.RenderRoot = null;
			// The GPU objects are swept by the next canvas texture pass.
			component.RenderTexture = null;
			component.RenderTextureView = null;
		}

		if ((document != null) && !document.Markup.IsEmpty)
		{
			component.Root = MarkupLoader.LoadFromString(document.Markup, mContext);

			if (component.Root == null)
			{
				GlobalLog(.Warning, "UISubsystem: a canvas document failed to instantiate");
			}
			else if (wantsTexture)
			{
				// A STANDALONE root: never parented into a tier, so the overlay roles never
				// draw it, and never an input root, these canvases not being interactive.
				component.RenderRoot = new RootView();
				AttachOwned(component.RenderRoot, component.Root);
				mContext.AddRootView(component.RenderRoot);

				let entry = new UITextureCanvasRoot();
				component.RenderRoot.AddRef();
				entry.Root = component.RenderRoot;
				mTextureCanvasRoots.Add(entry);
			}
		}

		component.BuiltFrom = document;
		MarkTextureRootSeen(component.RenderRoot);
	}

	private void MarkTextureRootSeen(RootView root)
	{
		if (root == null)
			return;

		for (let entry in mTextureCanvasRoots)
		{
			if (entry.Root === root)
			{
				entry.Seen = true;
				break;
			}
		}
	}

	/// Overlay canvases parent through their HOST, which is what carries the order and the
	/// scaler in the scene's root.
	private void PlaceCanvas(UISceneUI sceneUI, UICanvasComponent* component)
	{
		if (component.RenderMode == .RenderTexture)
		{
			// A stale host is simply left unseen, and the sweep takes it.
			if (component.Host != null)
			{
				component.Host.ReleaseRef();
				component.Host = null;
			}
			return;
		}

		if (component.Host == null)
		{
			let host = new CanvasHostView();
			// One reference for the component, one for the tree.
			host.AddRef();
			sceneUI.Root.AddView(host);
			component.Host = host;
		}

		let host = component.Host as CanvasHostView;
		host.Seen = true;
		host.Order = component.Order;
		host.ScalerMode = component.ScalerMode;
		host.ReferenceResolution = component.ReferenceResolution;

		if ((component.Root != null) && (component.Root.Parent == null))
			AttachOwned(host, component.Root);
	}

	private void ApplyCanvasTheme(UICanvasComponent* component)
	{
		let theme = component.Theme.Get;
		if (theme === component.ThemeFrom)
			return;

		StyleSheet sheet = null;
		if ((theme != null) && !theme.StyleSheet.IsEmpty)
		{
			let loader = scope StyleSheetLoader();
			loader.SetPalette(GameTheme.Palette());
			sheet = loader.Load(theme.StyleSheet);
		}

		// Installing CONSUMES the reference and releases whatever the view held, so the
		// component keeps only a back pointer and never releases it itself.
		component.ThemeSheet = sheet;
		if (component.Root != null)
			component.Root.SetLocalStyleSheet(sheet);
		else if (sheet != null)
			sheet.ReleaseRef();

		component.ThemeFrom = theme;
	}

	private void SyncBillboards(UISceneUI sceneUI, UIBillboardComponentManager billboards)
	{
		// Everything the walk does not claim is swept below.
		let live = scope List<View>();

		billboards.ForEach(scope [&] (component, owner) =>
			{
				let document = component.Document.Get;
				if (document !== component.BuiltFrom)
				{
					if (component.Root != null)
						DetachOwned(sceneUI.BillboardLayer, ref component.Root);

					if ((document != null) && !document.Markup.IsEmpty)
					{
						component.Root = MarkupLoader.LoadFromString(document.Markup, mContext);
						// The root keeps the placement its markup gave it; the billboard
						// layer reads the position written per frame by the view sync.
						if (component.Root != null)
							AttachOwned(sceneUI.BillboardLayer, component.Root);
					}

					component.BuiltFrom = document;
				}

				if (component.Root != null)
					live.Add(component.Root);
			});

		// The canvas hosts' sweep, applied to the nameplates: this drops the LAYER's half of
		// each tree, what is gone being what nothing claimed. The component's own half is
		// dropped by the pool's OnComponentDestroyed, which is the only place that sees a
		// removal.
		for (int i = sceneUI.BillboardLayer.ChildCount - 1; i >= 0; i--)
		{
			let child = sceneUI.BillboardLayer.GetChildAt(i);
			if (!live.Contains(child))
				sceneUI.BillboardLayer.RemoveView(child);
		}
	}

	/// The world tier: standalone roots like the texture canvases, never parented into a
	/// tier, registered through the SAME registry so its sweep handles a despawn, drawn and
	/// sprite driven by the canvas texture pass, and pointed at by a ray from the pump.
	private void SyncWorldPanels(UIWorldPanelComponentManager panels)
	{
		panels.ForEach(scope [&] (component, owner) =>
			{
				let document = component.Document.Get;
				if (document !== component.BuiltFrom)
				{
					if (component.RenderRoot != null)
					{
						mContext.RemoveRootView(component.RenderRoot);

						if (component.Root != null)
						{
							component.RenderRoot.RemoveView(component.Root);
							component.Root.ReleaseRef();
							component.Root = null;
						}

						component.RenderRoot.ReleaseRef();
						component.RenderRoot = null;
						// Swept by the next canvas texture pass.
						component.RenderTexture = null;
						component.RenderTextureView = null;
					}

					if ((document != null) && !document.Markup.IsEmpty)
					{
						component.Root = MarkupLoader.LoadFromString(document.Markup, mContext);

						if (component.Root != null)
						{
							component.RenderRoot = new RootView();
							AttachOwned(component.RenderRoot, component.Root);
							mContext.AddRootView(component.RenderRoot);

							let entry = new UITextureCanvasRoot();
							component.RenderRoot.AddRef();
							entry.Root = component.RenderRoot;
							mTextureCanvasRoots.Add(entry);
						}
						else
						{
							GlobalLog(.Warning,
								"UISubsystem: a world panel document failed to instantiate");
						}
					}

					component.BuiltFrom = document;
				}

				MarkTextureRootSeen(component.RenderRoot);
				ApplyPanelTheme(component);
			});
	}

	private void ApplyPanelTheme(UIWorldPanelComponent* component)
	{
		let theme = component.Theme.Get;
		if (theme === component.ThemeFrom)
			return;

		StyleSheet sheet = null;
		if ((theme != null) && !theme.StyleSheet.IsEmpty)
		{
			let loader = scope StyleSheetLoader();
			loader.SetPalette(GameTheme.Palette());
			sheet = loader.Load(theme.StyleSheet);
		}

		component.ThemeSheet = sheet;
		if (component.Root != null)
			component.Root.SetLocalStyleSheet(sheet);
		else if (sheet != null)
			sheet.ReleaseRef();

		component.ThemeFrom = theme;
	}

	/// Releases every reference the COMPONENTS of a scene are holding, before that scene's
	/// root goes.
	///
	/// A view is counted, and a component holds its own reference alongside the tree's. When
	/// a scene dies the tree lets go of its half, but nothing would let go of the component's:
	/// the manager is about to be destroyed with the scene and has no hook that runs first. So
	/// the subsystem does it here, which is the only place that knows both.
	public void ReleaseSceneComponents(Scene scene)
	{
		if (let canvases = scene.GetSystem<UICanvasComponentManager>())
		{
			canvases.ForEach(scope (component, owner) =>
				{
					ReleaseView(ref component.Root);
					ReleaseViewGroup(ref component.Host);
					ReleaseRoot(ref component.RenderRoot);
					ReleaseSheet(ref component.ThemeSheet);
					component.BuiltFrom = null;
					component.ThemeFrom = null;
				});
		}

		if (let billboards = scene.GetSystem<UIBillboardComponentManager>())
		{
			billboards.ForEach(scope (component, owner) =>
				{
					ReleaseView(ref component.Root);
					component.BuiltFrom = null;
				});
		}

		if (let panels = scene.GetSystem<UIWorldPanelComponentManager>())
		{
			panels.ForEach(scope [&] (component, owner) =>
				{
					ReleaseView(ref component.Root);
					ReleaseRoot(ref component.RenderRoot);
					ReleaseSheet(ref component.ThemeSheet);
					component.BuiltFrom = null;
					component.ThemeFrom = null;
				});
		}
	}

	private static void ReleaseView(ref View view)
	{
		if (view == null)
			return;
		view.ReleaseRef();
		view = null;
	}

	private static void ReleaseViewGroup(ref ViewGroup group)
	{
		if (group == null)
			return;
		group.ReleaseRef();
		group = null;
	}

	private void ReleaseRoot(ref RootView root)
	{
		if (root == null)
			return;

		// It is a context root in its own right, so it is unregistered before it goes, the
		// context storing roots without owning them.
		mContext.RemoveRootView(root);
		MarkTextureRootReleased(root);
		root.ReleaseRef();
		root = null;
	}

	/// Drops the registry's own keep alive reference for a root being released here, so the
	/// sweep does not release it a second time.
	private void MarkTextureRootReleased(RootView root)
	{
		for (int i = mTextureCanvasRoots.Count - 1; i >= 0; i--)
		{
			if (mTextureCanvasRoots[i].Root !== root)
				continue;

			mTextureCanvasRoots[i].Root.ReleaseRef();
			delete mTextureCanvasRoots[i];
			mTextureCanvasRoots.RemoveAt(i);
		}
	}

	/// The component's sheet is a BACK POINTER: the view it was installed on owns it, so this
	/// only forgets it.
	private static void ReleaseSheet(ref StyleSheet sheet)
	{
		sheet = null;
	}
}
