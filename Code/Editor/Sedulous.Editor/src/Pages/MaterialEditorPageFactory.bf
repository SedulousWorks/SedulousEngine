using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Shell.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Materials;
using Sedulous.Materials.Resources;
using Sedulous.Core.Mathematics;
namespace Sedulous.Editor.Pages;

/// Creates editor pages for `.material` files.
///
/// The right panel exposes editors for everything the user can change
/// without swapping the shader: per-property uniform values, texture
/// refs (one per `[Texture2D|TextureCube]` property), sampler
/// addressing + filter modes, and pipeline blend / cull / depth.
/// Mutations flow through `page.OnMaterialMutated()`, which bumps
/// `Resource.Generation` so the render resource resolver rebuilds the
/// `MaterialInstance` on the preview sphere for live feedback.
class MaterialEditorPageFactory : IEditorPageFactory
{
	const String SPHERE_URI = "builtin://primitives/sphere.mesh";

	private IDevice mDevice;
	private VGRenderer mVGRenderer;
	private IKeyboard mKeyboard;

	public this(IDevice device, VGRenderer vgRenderer, IKeyboard keyboard)
	{
		mDevice = device;
		mVGRenderer = vgRenderer;
		mKeyboard = keyboard;
	}

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".material"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".material", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "No runtime context.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "SceneSubsystem or ISceneRenderer unavailable.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Path is not inside any mounted scheme.", context);

		MaterialResource matRes = null;
		if (context.ResourceSystem.LoadResource<MaterialResource>(uri) case .Ok(let handle))
			matRes = handle.Resource;
		if (matRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Failed to load material resource.", context);

		Sedulous.Geometry.Resources.StaticMeshResource sphereRes = null;
		if (context.ResourceSystem.LoadResource<Sedulous.Geometry.Resources.StaticMeshResource>(SPHERE_URI) case .Ok(let sphereHandle))
			sphereRes = sphereHandle.Resource;
		if (sphereRes == null)
		{
			matRes.ReleaseRef();
			return MeshEditorPageFactory.BuildErrorPage(path, "Material", "Failed to load builtin sphere mesh.", context);
		}

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "MaterialPreview");
		let page = new MaterialEditorPage(path, uri, matRes, sphereRes, SPHERE_URI, host, context);
		page.SetContentView(BuildMaterialView(matRes, host, page, context));
		return page;
	}

	private static View BuildMaterialView(MaterialResource matRes, PreviewSceneHost host,
		MaterialEditorPage page, EditorContext context)
	{
		let root = new SplitView(.Horizontal);

		let viewportPanel = new Panel();
		viewportPanel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		viewportPanel.AddView(host.Viewport);

		// Right side scrolls - the property list grows with the material.
		let editScroll = new ScrollView();
		let editPanel = new FlexLayout();
		editPanel.Direction = .Vertical;
		editPanel.Padding = .(8);
		editPanel.Spacing = 4;
		editScroll.AddView(editPanel, new LayoutParams() { Width = .Match, Height = .Wrap });

		BuildHeaderSection(editPanel, matRes);
		if (matRes?.Material != null)
		{
			BuildPropertiesSection(editPanel, matRes, page, context);
			BuildSamplerSection(editPanel, matRes, page);
			BuildPipelineSection(editPanel, matRes, page);
		}

		root.SetPanes(viewportPanel, editScroll);
		root.SplitRatio = 0.55f;
		return root;
	}

	// === Header (read-only fields) ===

	private static void BuildHeaderSection(FlexLayout panel, MaterialResource matRes)
	{
		MeshEditorPageFactory.AddInfoHeader(panel, "Material");
		MeshEditorPageFactory.AddSeparator(panel);

		if (matRes?.Material != null)
		{
			MeshEditorPageFactory.AddInfoRow(panel, "Shader", matRes.Material.ShaderName);
			MeshEditorPageFactory.AddInfoRow(panel, "Properties", scope $"{matRes.Material.PropertyCount}");
		}
		else
		{
			let err = new Label();
			err.SetText("Material data unavailable");
			err.TextColor.Value = .(220, 100, 100, 255);
			panel.AddView(err, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}
	}

	// === Per-property uniforms + texture pickers ===

	private static void BuildPropertiesSection(FlexLayout panel, MaterialResource matRes,
		MaterialEditorPage page, EditorContext context)
	{
		let mat = matRes.Material;

		// Defensive: if the asset never got uniform storage (shouldn't
		// happen on the load path, but cheap to handle) allocate so
		// editor writes have somewhere to land.
		if (mat.DefaultUniformData.Length == 0 && mat.PropertyCount > 0)
			mat.AllocateDefaultUniformData();

		bool hasUniforms = false;
		bool hasTextures = false;
		for (int i = 0; i < mat.PropertyCount; i++)
		{
			let prop = mat.GetProperty(i);
			if (prop.IsUniform) hasUniforms = true;
			if (prop.IsTexture) hasTextures = true;
		}

		if (hasUniforms)
		{
			MeshEditorPageFactory.AddSeparator(panel);
			MeshEditorPageFactory.AddInfoHeader(panel, "Uniforms");
			for (int i = 0; i < mat.PropertyCount; i++)
			{
				let prop = mat.GetProperty(i);
				if (!prop.IsUniform) continue;
				BuildUniformRow(panel, mat, prop, page);
			}
		}

		if (hasTextures)
		{
			MeshEditorPageFactory.AddSeparator(panel);
			MeshEditorPageFactory.AddInfoHeader(panel, "Textures");
			for (int i = 0; i < mat.PropertyCount; i++)
			{
				let prop = mat.GetProperty(i);
				if (!prop.IsTexture) continue;
				BuildTextureRow(panel, matRes, prop, page, context);
			}
		}
	}

	private static void BuildUniformRow(FlexLayout panel, Material mat, MaterialPropertyDef prop,
		MaterialEditorPage page)
	{
		let data = mat.DefaultUniformData;
		if (data.Length < (int)(prop.Offset + prop.Size)) return;

		// Reading happens via pointer because the storage is a flat
		// uint8[]; setters in Material write back to the same offset
		// and we lean on those to avoid open-coding bytewise writes.
		let basePtr = &data[(int)prop.Offset];

		// Capture the property name into a String the page owns -
		// scope-allocated copies would die at function return while
		// the closure stays live on the field's OnValueChanged event.
		let propName = page.AddOwnedString(prop.Name);

		switch (prop.Type)
		{
		case .Float:
			let cur = *(float*)basePtr;
			let nf = new NumericField();
			nf.ShowSpinButtons.Value = false;
			nf.Min = -1e9; nf.Max = 1e9;
			nf.DecimalPlaces = 4;
			nf.Step = 0.01;
			nf.Value = cur;
			nf.OnValueChanged.Add(new [=mat, =propName, =page] (n, v) =>
			{
				mat.SetDefaultFloat(propName, (float)v);
				page.OnMaterialMutated();
			});
			AddLabeledRow(panel, propName, nf);

		case .Float2:
			let cur = *(Vector2*)basePtr;
			let field = new Vector2Field();
			field.Value = cur;
			field.OnValueChanged.Add(new [=mat, =propName, =page] (val) =>
			{
				mat.SetDefaultFloat2(propName, val);
				page.OnMaterialMutated();
			});
			AddLabeledRow(panel, propName, field, .Px(22));

		case .Float3:
			let cur = *(Vector3*)basePtr;
			let field = new Vector3Field();
			field.Value = cur;
			field.OnValueChanged.Add(new [=mat, =propName, =page] (val) =>
			{
				mat.SetDefaultFloat3(propName, val);
				page.OnMaterialMutated();
			});
			AddLabeledRow(panel, propName, field, .Px(22));

		case .Float4:
			let cur = *(Vector4*)basePtr;
			let field = new Vector4Field();
			field.Value = cur;
			field.OnValueChanged.Add(new [=mat, =propName, =page] (val) =>
			{
				mat.SetDefaultFloat4(propName, val);
				page.OnMaterialMutated();
			});
			AddLabeledRow(panel, propName, field, .Px(22));

		default:
			// Int* / Matrix4x4: no editor yet, just show as read-only.
			let note = new Label();
			note.SetText(scope $"({prop.Type} - read-only)");
			note.TextColor.Value = .(140, 140, 155, 255);
			note.FontSize.Value = 11;
			AddLabeledRow(panel, propName, note, .Px(18));
		}
	}

	private static void BuildTextureRow(FlexLayout panel, MaterialResource matRes,
		MaterialPropertyDef prop, MaterialEditorPage page, EditorContext context)
	{
		// Same lifetime concern as BuildUniformRow - the picker / clear
		// callbacks live past this function's return.
		let propName = page.AddOwnedString(prop.Name);

		let row = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };

		let label = new Label();
		label.SetText(scope $"{propName}:");
		label.TextColor.Value = .(180, 180, 195, 255);
		label.FontSize.Value = 11;
		row.AddView(label, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(110)), Height = .Match });

		let pathLabel = new Label();
		let curRef = matRes.GetTextureRef(propName);
		pathLabel.SetText(TextureRefDisplay(curRef));
		pathLabel.TextColor.Value = .(220, 220, 230, 255);
		pathLabel.FontSize.Value = 11;
		row.AddView(pathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let pickBtn = new Button("Pick");
		pickBtn.OnClick.Add(new [=context, =page, =matRes, =propName, =pathLabel] (btn) =>
		{
			let ctx = page.ContentView?.Context;
			if (ctx == null || context == null) return;
			let dlg = new AssetPickerDialog(context, ".texture",
				new [=matRes, =propName, =page, =pathLabel] (path, id) =>
				{
					matRes.SetTextureRef(propName, ResourceRef(id, path));
					pathLabel.SetText(TextureRefDisplay(matRes.GetTextureRef(propName)));
					page.OnMaterialMutated();
				});
			dlg.Show(ctx);
		});
		row.AddView(pickBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

		let clearBtn = new Button("Clear");
		clearBtn.OnClick.Add(new [=matRes, =propName, =page, =pathLabel] (btn) =>
		{
			matRes.SetTextureRef(propName, ResourceRef(.Empty, ""));
			pathLabel.SetText("(none)");
			page.OnMaterialMutated();
		});
		row.AddView(clearBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });

		panel.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });
	}

	private static StringView TextureRefDisplay(ResourceRef @ref)
	{
		if (!@ref.IsValid && !@ref.HasPath) return "(none)";
		let p = @ref.Path;
		if (p.IsEmpty) return "(unresolved)";
		let lastSlash = p.LastIndexOf('/');
		return (lastSlash >= 0) ? p.Substring(lastSlash + 1) : p;
	}

	// === Samplers ===

	private static void BuildSamplerSection(FlexLayout panel, MaterialResource matRes,
		MaterialEditorPage page)
	{
		MeshEditorPageFactory.AddSeparator(panel);
		MeshEditorPageFactory.AddInfoHeader(panel, "Samplers");

		AddEnumRow(panel, "Wrap U", StringView[](
			"Repeat", "MirrorRepeat", "ClampToEdge", "ClampToBorder"),
			(int)matRes.WrapU,
			new [=matRes, =page] (cb, idx) =>
			{
				matRes.WrapU = (SamplerAddressMode)idx;
				page.OnMaterialMutated();
			});

		AddEnumRow(panel, "Wrap V", StringView[](
			"Repeat", "MirrorRepeat", "ClampToEdge", "ClampToBorder"),
			(int)matRes.WrapV,
			new [=matRes, =page] (cb, idx) =>
			{
				matRes.WrapV = (SamplerAddressMode)idx;
				page.OnMaterialMutated();
			});

		AddEnumRow(panel, "Min Filter", StringView[](
			"Nearest", "Linear", "NearestMipmapNearest", "LinearMipmapNearest",
			"NearestMipmapLinear", "LinearMipmapLinear"),
			(int)matRes.MinFilter,
			new [=matRes, =page] (cb, idx) =>
			{
				matRes.MinFilter = (SamplerMinFilter)idx;
				page.OnMaterialMutated();
			});

		AddEnumRow(panel, "Mag Filter", StringView[]("Nearest", "Linear"),
			(int)matRes.MagFilter,
			new [=matRes, =page] (cb, idx) =>
			{
				matRes.MagFilter = (SamplerMagFilter)idx;
				page.OnMaterialMutated();
			});
	}

	// === Pipeline ===

	private static void BuildPipelineSection(FlexLayout panel, MaterialResource matRes,
		MaterialEditorPage page)
	{
		MeshEditorPageFactory.AddSeparator(panel);
		MeshEditorPageFactory.AddInfoHeader(panel, "Pipeline");

		// PipelineConfig is a value-type field on Material - copy out,
		// mutate, write back. Direct field mutation on the property
		// accessor wouldn't compile against the struct.
		AddEnumRow(panel, "Blend Mode", StringView[](
			"Opaque", "Masked", "AlphaBlend", "Additive", "Multiply", "PremultipliedAlpha"),
			(int)matRes.Material.PipelineConfig.BlendMode,
			new [=matRes, =page] (cb, idx) =>
			{
				var cfg = matRes.Material.PipelineConfig;
				cfg.BlendMode = (BlendMode)idx;
				matRes.Material.PipelineConfig = cfg;
				page.OnMaterialMutated();
			});

		AddEnumRow(panel, "Cull Mode", StringView[]("None", "Back", "Front"),
			(int)matRes.Material.PipelineConfig.CullMode,
			new [=matRes, =page] (cb, idx) =>
			{
				var cfg = matRes.Material.PipelineConfig;
				cfg.CullMode = (CullModeConfig)idx;
				matRes.Material.PipelineConfig = cfg;
				page.OnMaterialMutated();
			});

		AddEnumRow(panel, "Depth Mode", StringView[](
			"Disabled", "ReadWrite", "ReadOnly", "WriteOnly"),
			(int)matRes.Material.PipelineConfig.DepthMode,
			new [=matRes, =page] (cb, idx) =>
			{
				var cfg = matRes.Material.PipelineConfig;
				cfg.DepthMode = (DepthMode)idx;
				matRes.Material.PipelineConfig = cfg;
				page.OnMaterialMutated();
			});
	}

	// === Helpers ===

	private static void AddLabeledRow(FlexLayout panel, StringView name, View editor, Unit rowHeight = .Px(22))
	{
		let row = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };

		let label = new Label();
		label.SetText(scope $"{name}:");
		label.TextColor.Value = .(180, 180, 195, 255);
		label.FontSize.Value = 11;
		row.AddView(label, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(110)), Height = .Match });

		row.AddView(editor, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(rowHeight) });

		panel.AddView(row, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});
	}

	/// Builds a ComboBox row for an enum-like value. Items are passed
	/// as string names in index order; the callback uses ComboBox's
	/// native event shape so `Event.Add` takes ownership of the
	/// delegate (wrapping the caller-provided delegate would leak the
	/// outer allocation - the inner closure captures it without
	/// claiming ownership).
	private static void AddEnumRow(FlexLayout panel, StringView name, Span<StringView> items,
		int currentIndex, delegate void(ComboBox, int) onChanged)
	{
		let combo = new ComboBox();
		for (let it in items) combo.AddItem(it);
		combo.SelectedIndex = (currentIndex >= 0 && currentIndex < items.Length) ? currentIndex : 0;
		combo.OnSelectionChanged.Add(onChanged);

		AddLabeledRow(panel, name, combo);
	}
}
