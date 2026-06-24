namespace Sedulous.Editor;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.VFS;
using Sedulous.Engine;

/// Creates SceneEditorPage instances for .scene files.
/// Registered with EditorContext.RegisterPageFactory() so double-clicking
/// a .scene file in the asset browser opens it as a scene editor tab.
class SceneEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".scene"));
	}

	public bool CanOpen(StringView path)
	{
		return path.EndsWith(".scene", .OrdinalIgnoreCase);
	}

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null) return null;

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		if (sceneSub == null) return null;

		// Extract scene name from filename
		let sceneName = scope String();
		System.IO.Path.GetFileNameWithoutExtension(path, sceneName);

		let scene = sceneSub.CreateScene(sceneName);

		// Editor mode: disable simulation
		scene.SimulationEnabled = false;

		// Resolve the asset-browser-supplied absolute path to a (mount, locator)
		// pair so the bytes flow through the VFS rather than File.ReadAllText.
		// Non-disk mounts (pak, remote) would simply fail to match and the
		// factory would refuse to open the file - which is the right behavior
		// since they don't have absolute paths.
		IMount mount = null;
		let locator = scope String();
		if (!MountResolver.TryResolveAbsolute(context.MountEntries, path, out mount, locator))
		{
			sceneSub.DestroyScene(scene);
			return null;
		}

		let text = scope String();
		if (!ReadTextFromMount(mount, locator, text))
		{
			sceneSub.DestroyScene(scene);
			return null;
		}

		let reader = context.ResourceSystem?.SerializerProvider?.CreateReader(text);
		if (reader == null)
		{
			sceneSub.DestroyScene(scene);
			return null;
		}
		defer delete reader;

		// Deserialize via SceneResource
		let sceneSerializer = scope SceneSerializer(mTypeRegistry,
			context.ResourceSystem?.SerializerProvider, context.ResourceSystem);
		let tempResource = scope SceneResource();
		tempResource.Scene = scene;
		tempResource.SceneSerializer = sceneSerializer;
		tempResource.Serialize(reader);

		// Create page
		let page = new SceneEditorPage(scene, path, context);

		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		let content = ScenePageBuilder.Build(page, context, mDevice, mVGRenderer,
			sceneRenderer, mKeyboard);
		page.SetContentView(content);

		return page;
	}

	/// Slurps the entire contents of `locator` from `mount` as UTF-8 text.
	private static bool ReadTextFromMount(IMount mount, StringView locator, String outText)
	{
		let openResult = mount.Open(locator);
		if (openResult case .Err) return false;
		let stream = openResult.Value;
		defer delete stream;

		let len = (int)stream.Length;
		if (len <= 0) return true;

		let buf = scope uint8[len];
		switch (stream.TryRead(.(&buf[0], len)))
		{
		case .Ok(let n):
			if (n != len) return false;
			outText.Append((char8*)&buf[0], len);
			return true;
		case .Err:
			return false;
		}
	}
}
