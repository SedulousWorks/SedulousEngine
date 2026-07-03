using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Platform.Input;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Geometry;
using Sedulous.Geometry.Resources;
namespace Sedulous.Editor.Pages;

/// Creates editor pages for .skinnedmesh files.
/// 3D preview viewport rendering the skinned mesh (bind pose by default)
/// alongside a metadata + preview-rig panel. The user can pick a clip +
/// skeleton in the panel to animate the mesh; picks are persisted
/// per-asset through `EditorContext.AssetCache`.
class SkinnedMeshEditorPageFactory : IEditorPageFactory
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
		outExtensions.Add(new .(".skinnedmesh"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".skinnedmesh", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let runtimeContext = context.RuntimeContext;
		if (runtimeContext == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "No runtime context - render subsystem unavailable.", context);

		let sceneSub = runtimeContext.GetSubsystem<SceneSubsystem>();
		let sceneRenderer = runtimeContext.GetSubsystemByInterface<ISceneRenderer>();
		if (sceneSub == null || sceneRenderer == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "SceneSubsystem or ISceneRenderer not available.", context);

		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "Path is not inside any mounted scheme.", context);

		SkinnedMeshResource meshRes = null;
		if (context.ResourceSystem.LoadResource<SkinnedMeshResource>(uri) case .Ok(let handle))
			meshRes = handle.Resource;
		if (meshRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Skinned Mesh", "Failed to load skinned mesh resource.", context);

		let host = new PreviewSceneHost(mDevice, mVGRenderer, mKeyboard, sceneSub, sceneRenderer, "SkinnedMeshPreview");
		let page = new SkinnedMeshEditorPage(path, uri, meshRes, host, context);
		page.SetContentView(BuildView(meshRes, host, page, context));
		return page;
	}

	private static View BuildView(SkinnedMeshResource meshRes, PreviewSceneHost host,
		SkinnedMeshEditorPage page, EditorContext context)
	{
		// Standard resource-page shape: viewport left, details docked right.
		let root = new SplitView(.Horizontal);

		let viewportPanel = new Panel();
		viewportPanel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		viewportPanel.AddView(host.Viewport);

		let infoPanel = new FlexLayout();
		infoPanel.Direction = .Vertical;
		infoPanel.Padding = .(8);
		infoPanel.Spacing = 4;

		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Skinned Mesh Properties");
		MeshEditorPageFactory.AddSeparator(infoPanel);

		if (meshRes?.Mesh != null)
		{
			let mesh = meshRes.Mesh;
			let triCount = mesh.IndexCount / 3;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Vertices", scope $"{mesh.VertexCount}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Triangles", scope $"{triCount}");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Submeshes", scope $"{mesh.SubMeshes.Count}");
			let b = mesh.Bounds;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Bounds Min", scope $"({b.Min.X:F2}, {b.Min.Y:F2}, {b.Min.Z:F2})");
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Bounds Max", scope $"({b.Max.X:F2}, {b.Max.Y:F2}, {b.Max.Z:F2})");
			let size = b.Max - b.Min;
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Size", scope $"({size.X:F2}, {size.Y:F2}, {size.Z:F2})");
			let skel = meshRes.SkeletonRef.HasPath ? meshRes.SkeletonRef.Path : "(none)";
			MeshEditorPageFactory.AddInfoRow(infoPanel, "Skeleton", skel);
		}
		else
		{
			let errorLabel = new Label();
			errorLabel.SetText("Failed to load skinned mesh");
			errorLabel.TextColor.Value = .(220, 100, 100, 255);
			infoPanel.AddView(errorLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		// === Preview rig section ===
		MeshEditorPageFactory.AddSeparator(infoPanel);
		MeshEditorPageFactory.AddInfoHeader(infoPanel, "Preview Animation");

		// Clip picker row.
		let clipRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		let clipLabel = new Label();
		clipLabel.SetText("Clip:");
		clipLabel.TextColor.Value = .(180, 180, 195, 255);
		clipLabel.FontSize.Value = 11;
		clipRow.AddView(clipLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(64)), Height = .Match });

		let clipPathLabel = new Label();
		clipPathLabel.SetText("(none)");
		clipPathLabel.TextColor.Value = .(220, 220, 230, 255);
		clipPathLabel.FontSize.Value = 11;
		clipRow.AddView(clipPathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let pickClipBtn = new Button("Pick");
		pickClipBtn.OnClick.Add(new [=context, =page] (btn) =>
		{
			let ctx = page.ContentView?.Context;
			if (ctx == null || context == null) return;
			let dlg = new AssetPickerDialog(context, ".animation",
				new [=page] (path, id) => { page.SetClipUri(path); });
			dlg.Show(ctx);
		});
		clipRow.AddView(pickClipBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

		let clearClipBtn = new Button("Clear");
		clearClipBtn.OnClick.Add(new [=page] (btn) => page.SetClipUri(""));
		clipRow.AddView(clearClipBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });
		infoPanel.AddView(clipRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		// Skeleton picker row (defaults to mesh's SkeletonRef when empty).
		let skelRow = new FlexLayout() { Direction = .Horizontal, Spacing = 4 };
		let skelLabel = new Label();
		skelLabel.SetText("Skeleton:");
		skelLabel.TextColor.Value = .(180, 180, 195, 255);
		skelLabel.FontSize.Value = 11;
		skelRow.AddView(skelLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(64)), Height = .Match });

		let skelPathLabel = new Label();
		skelPathLabel.SetText("(none)");
		skelPathLabel.TextColor.Value = .(220, 220, 230, 255);
		skelPathLabel.FontSize.Value = 11;
		skelRow.AddView(skelPathLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		let pickSkelBtn = new Button("Pick");
		pickSkelBtn.OnClick.Add(new [=context, =page] (btn) =>
		{
			let ctx = page.ContentView?.Context;
			if (ctx == null || context == null) return;
			let dlg = new AssetPickerDialog(context, ".skeleton",
				new [=page] (path, id) => { page.SetSkeletonUri(path); });
			dlg.Show(ctx);
		});
		skelRow.AddView(pickSkelBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(48)), Height = .Fixed(.Px(22)) });

		let clearSkelBtn = new Button("Clear");
		clearSkelBtn.OnClick.Add(new [=page] (btn) => page.SetSkeletonUri(""));
		skelRow.AddView(clearSkelBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(50)), Height = .Fixed(.Px(22)) });
		infoPanel.AddView(skelRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		// Hand the labels to the page so SetClipUri / SetSkeletonUri
		// can refresh them when picks change (avoids rebuilding the
		// panel on every pick).
		page.RegisterStateLabels(clipPathLabel, skelPathLabel);

		// Material override pickers - one row per distinct material slot
		// referenced by submeshes (via SubMesh.materialIndex), NOT per
		// submesh. SkinnedMeshComponent.MaterialRefs is indexed by
		// materialIndex, so multiple submeshes sharing a slot share one
		// row. Empty pick falls back to the component manager's default
		// material.
		let slotCount = SkinnedMeshEditorPage.ComputeMaterialSlotCount(meshRes);
		if (slotCount > 0)
		{
			MeshEditorPageFactory.AddSeparator(infoPanel);
			MeshEditorPageFactory.AddInfoHeader(infoPanel, "Preview Materials");

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
}
