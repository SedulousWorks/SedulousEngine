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
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .mesh files.
/// Opens a 3D preview viewport rendering the mesh with a default material,
/// alongside a metadata panel (vertex/triangle/submesh counts, bounds).
///
/// Also hosts the small set of static helpers shared across the preview
/// page factories (BuildErrorPage, AddInfoHeader, AddInfoRow, AddSeparator).
/// They live here rather than a separate file because every other factory
/// in this folder already references them through `MeshEditorPageFactory.`.
class MeshEditorPageFactory : IEditorPageFactory
{
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
		outExtensions.Add(new .(".mesh"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".mesh", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return BuildErrorPage(path, "Mesh", "No runtime context - render subsystem unavailable.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return BuildErrorPage(path, "Mesh", "SceneSubsystem or ISceneRenderer not available.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return BuildErrorPage(path, "Mesh", "Path is not inside any mounted scheme.", context);

		StaticMeshResource meshRes = null;
		if (context.ResourceSystem.LoadResource<StaticMeshResource>(uri) case .Ok(let handle))
			meshRes = handle.Resource;
		if (meshRes == null)
			return BuildErrorPage(path, "Mesh", "Failed to load mesh resource.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "MeshPreview");
		let page = new MeshEditorPage(path, uri, meshRes, host, context);
		page.SetContentView(BuildMeshView(meshRes, host, page, context));
		return page;
	}

	private static View BuildMeshView(StaticMeshResource meshRes, PreviewSceneHost host,
		MeshEditorPage page, EditorContext context)
	{
		let root = new SplitView(.Horizontal);

		// Viewport pane (left).
		let viewportPanel = new Panel();
		viewportPanel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		viewportPanel.AddView(host.Viewport);

		// Info pane (right).
		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		AddInfoHeader(infoPanel, "Mesh Properties");
		AddSeparator(infoPanel);

		if (meshRes?.Mesh != null)
		{
			let mesh = meshRes.Mesh;
			let triCount = mesh.IndexCount / 3;
			AddInfoRow(infoPanel, "Vertices", scope $"{mesh.VertexCount}");
			AddInfoRow(infoPanel, "Triangles", scope $"{triCount}");
			AddInfoRow(infoPanel, "Submeshes", scope $"{mesh.SubMeshes.Count}");
			let b = mesh.Bounds;
			AddInfoRow(infoPanel, "Bounds Min", scope $"({b.Min.X:F2}, {b.Min.Y:F2}, {b.Min.Z:F2})");
			AddInfoRow(infoPanel, "Bounds Max", scope $"({b.Max.X:F2}, {b.Max.Y:F2}, {b.Max.Z:F2})");
			let size = b.Max - b.Min;
			AddInfoRow(infoPanel, "Size", scope $"({size.X:F2}, {size.Y:F2}, {size.Z:F2})");
		}
		else
		{
			let errorLabel = new Label();
			errorLabel.SetText("Failed to load mesh");
			errorLabel.TextColor.Value = .(220, 100, 100, 255);
			infoPanel.AddView(errorLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		// Per-slot material override pickers, mirroring the
		// SkinnedMeshEditorPage rig. Slot count comes from the unique
		// SubMesh.materialIndex values rather than SubMeshes.Count -
		// MeshComponent.MaterialRefs is indexed by materialIndex, so
		// multiple submeshes that share a slot share one row.
		let slotCount = MeshEditorPage.ComputeMaterialSlotCount(meshRes);
		if (slotCount > 0)
		{
			AddSeparator(infoPanel);
			AddInfoHeader(infoPanel, "Preview Materials");

			for (int32 slot = 0; slot < slotCount; slot++)
			{
				let row = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
				let label = new Label();
				label.SetText(scope $"Mat {slot}:");
				label.TextColor.Value = .(180, 180, 195, 255);
				label.FontSize.Value = 11;
				row.AddView(label, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(64)), Height = .Match });

				let pathLabel = new Label();
				pathLabel.SetText("(none)");
				pathLabel.TextColor.Value = .(220, 220, 230, 255);
				pathLabel.FontSize.Value = 11;
				row.AddView(pathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

				let slotCopy = slot;
				let pickBtn = new Button("Pick");
				pickBtn.OnClick.Add(new [=context, =page, =slotCopy] (btn) =>
				{
					let ctx = page.ContentView?.Context;
					if (ctx == null || context == null) return;
					let dlg = new AssetPickerDialog(context, ".material",
						new [=page, =slotCopy] (path, id) => { page.SetMaterialUri(slotCopy, path); });
					dlg.Show(ctx);
				});
				row.AddView(pickBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

				let clearBtn = new Button("Clear");
				clearBtn.OnClick.Add(new [=page, =slotCopy] (btn) => page.SetMaterialUri(slotCopy, ""));
				row.AddView(clearBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });

				infoPanel.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

				page.RegisterMaterialLabel(slot, pathLabel);
			}
		}

		root.SetPanes(viewportPanel, infoPanel);
		root.SplitRatio = 0.75f;
		return root;
	}

	public static IEditorPage BuildErrorPage(StringView path, StringView resourceType, StringView message, EditorContext context = null)
	{
		// Visible error page + log entry so the failure also surfaces in the
		// LogView panel for diagnostics, not just the open tab.
		context?.Logger?.LogError("Open {} failed: {} ({})", resourceType, message, path);

		let page = new ResourceEditorPage(path, scope String(resourceType));
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(16);
		container.Spacing = 8;

		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(path, name);

		let titleLabel = new Label();
		titleLabel.SetText(scope $"{resourceType}: {name}");
		titleLabel.FontSize.Value = 16;
		container.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		let errLabel = new Label();
		errLabel.SetText(message);
		errLabel.TextColor.Value = .(220, 100, 100, 255);
		container.AddView(errLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });

		page.SetContentView(container);
		return page;
	}

	public static void AddInfoHeader(FlexLayout container, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.FontSize.Value = 14;
		label.TextColor.Value = .(180, 180, 195, 255);
		container.AddView(label, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });
	}

	public static void AddInfoRow(FlexLayout container, StringView name, StringView value)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;

		let nameLabel = new Label();
		nameLabel.SetText(scope $"{name}:");
		nameLabel.TextColor.Value = .(140, 140, 155, 255);
		row.AddView(nameLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Match });

		let valueLabel = new Label();
		valueLabel.SetText(value);
		valueLabel.TextColor.Value = .(220, 220, 230, 255);
		row.AddView(valueLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		container.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
	}

	public static void AddSeparator(FlexLayout container)
	{
		let sep = new Panel();
		sep.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		container.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });
	}
}
