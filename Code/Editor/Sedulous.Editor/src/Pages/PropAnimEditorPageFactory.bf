namespace Sedulous.Editor.Pages;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.Editor.Core;
using Sedulous.Editor;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Animation.Resources;
using Sedulous.Resources;
using Sedulous.Engine.Core.Resources;

/// Creates editor pages for `.propanim` files.
///
/// Phase 1: real editor scaffold (preview source picker + entity hierarchy
/// + scrub slider). Dopesheet / keyframe editing comes in Phase 2 - see
/// `Documentation/Roadmap/PropAnimRoadmap.md`.
class PropAnimEditorPageFactory : IEditorPageFactory
{
	private IDevice mDevice;
	private VGRenderer mVGRenderer;
	private IKeyboard mKeyboard;
	private ComponentTypeRegistry mTypeRegistry;

	public this(IDevice device, VGRenderer vgRenderer, IKeyboard keyboard,
		ComponentTypeRegistry typeRegistry)
	{
		mDevice = device;
		mVGRenderer = vgRenderer;
		mKeyboard = keyboard;
		mTypeRegistry = typeRegistry;
	}

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".propanim"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".propanim", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "PropertyAnimation", "No runtime context.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "PropertyAnimation",
				"SceneSubsystem or ISceneRenderer unavailable.", context);

		// Resolve the asset-browser-supplied absolute path to a project://
		// URI so we can hand it to LoadResource.
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "PropertyAnimation",
				"Path is not inside any mounted scheme.", context);

		PropertyAnimationClipResource clipRes = null;
		if (context.ResourceSystem.LoadResource<PropertyAnimationClipResource>(uri) case .Ok(let handle))
			clipRes = handle.Resource;
		if (clipRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "PropertyAnimation",
				"Failed to load property animation clip resource.", context);

		// Spin up a preview host. We hold the only ref to this scene, so
		// loading a `.scene` / `.prefab` into it doesn't disturb anything
		// else the editor has open.
		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "PropAnimPreview");
		let page = new PropAnimEditorPage(path, clipRes, host, context, mTypeRegistry);
		page.SetContentView(PropAnimPageBuilder.Build(page));
		return page;
	}
}
