namespace UISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.Fonts;
using Sedulous.Shell.Input;
using Sedulous.ImageData;
using Sedulous.Imaging;
using Sedulous.Imaging.STB;

/// UISandbox — gallery/showcase for Sedulous.UI, growing with each phase.
/// Phase 2: Drawable system, Label, Button, Panel, Separator, debug overlays.
class UISandboxApp : Application
{
	private UISubsystem mUI;
	private OwnedImageData mCheckerboard ~ delete _;
	private OwnedImageData mButtonNormal ~ delete _;
	private OwnedImageData mButtonPressed ~ delete _;

	public this() : base()
	{
	}

	protected override void OnInitialize(Sedulous.Runtime.Context context)
	{
		// Create the UI subsystem.
		mUI = new UISubsystem();
		context.RegisterSubsystem(mUI);

		// Initialize rendering.
		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);

		if (mUI.InitializeRendering(Device, SwapChain.Format, (int32)SwapChain.BufferCount,
			scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Load font.
		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		mUI.LoadFont("Roboto", fontPath, .() { PixelHeight = 16 });
		mUI.LoadFont("Roboto", fontPath, .() { PixelHeight = 24 });

		// Register STB image loader for PNG loading.
		STBImageLoader.Initialize();

		// Generate a checkerboard image for ImageView / ImageDrawable demos.
		let img = Image.CreateCheckerboard(64, .(200, 200, 210, 255), .(60, 60, 70, 255), 8);
		mCheckerboard = new OwnedImageData(img.Width, img.Height, .RGBA8, img.Data);
		delete img;

		// Load Kenney pixel-UI 9-slice button images.
		String nineslicePath = scope .();
		GetAssetPath("samples/kenney_pixel-ui-pack/9-Slice/Colored/blue.png", nineslicePath);
		mButtonNormal = LoadImageAsRGBA8(nineslicePath);

		String nineslicePressedPath = scope .();
		GetAssetPath("samples/kenney_pixel-ui-pack/9-Slice/Colored/blue_pressed.png", nineslicePressedPath);
		mButtonPressed = LoadImageAsRGBA8(nineslicePressedPath);

		// Build the demo tree.
		BuildDemoUI(mUI.UIContext);
	}

	private void BuildDemoUI(UIContext ctx)
	{
		let root = ctx.Root;

		// Main vertical layout — top bar + two-column body.
		let main = new LinearLayout();
		main.Orientation = .Vertical;
		main.Padding = .(12);
		main.Spacing = 8;
		root.AddView(main);

		// === Top bar: weighted colors (Phase 1) ===
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 4;
			main.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 30 });
			AddWeightedColor(row, Color(200, 70, 70, 255), 2);
			AddWeightedColor(row, Color(70, 180, 70, 255), 1);
			AddWeightedColor(row, Color(70, 100, 220, 255), 1);
		}

		// === Two-column body ===
		let columns = new LinearLayout();
		columns.Orientation = .Horizontal;
		columns.Spacing = 12;
		main.AddView(columns, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		// --- LEFT COLUMN ---
		let left = new LinearLayout();
		left.Orientation = .Vertical;
		left.Spacing = 6;
		columns.AddView(left, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		AddSectionLabel(left, "Widgets");

		// Label
		{
			let label = new Label();
			label.SetText("Label — 16px Roboto");
			label.TextColor = .(200, 210, 230, 255);
			label.FontSize = 16;
			left.AddView(label, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });
		}

		// Buttons
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 6;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 36 });
			AddButton(row, "Primary", Color(50, 100, 200, 255));
			AddButton(row, "Success", Color(50, 160, 70, 255));
			AddButton(row, "Danger", Color(200, 60, 60, 255));
		}

		// Panel
		{
			let panel = new Panel();
			panel.Background = new RoundedRectDrawable(.(40, 42, 54, 255), 6, .(60, 65, 80, 255), 1);
			panel.Padding = .(10, 6);
			left.AddView(panel, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 40 });
			let panelLabel = new Label();
			panelLabel.SetText("Panel + RoundedRectDrawable");
			panelLabel.TextColor = .(180, 190, 210, 255);
			panelLabel.FontSize = 16;
			panel.AddView(panelLabel, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
		}

		AddSeparator(left);
		AddSectionLabel(left, "FlowLayout");

		// Flow chips
		{
			let flow = new FlowLayout();
			flow.Orientation = .Horizontal;
			flow.HSpacing = 4;
			flow.VSpacing = 4;
			left.AddView(flow, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 70 });
			for (int i = 0; i < 16; i++)
			{
				let chip = new ColorView();
				chip.Color = HSLToColor((float)i / 16.0f, 0.6f, 0.45f);
				chip.PreferredWidth = 36;
				chip.PreferredHeight = 26;
				flow.AddView(chip);
			}
		}

		AddSeparator(left);
		AddSectionLabel(left, "AbsoluteLayout");

		{
			let abs = new AbsoluteLayout();
			left.AddView(abs, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 60 });
			AddAbsBox(abs, .(200, 80, 80, 200), 10, 5, 50, 35);
			AddAbsBox(abs, .(80, 200, 80, 200), 45, 18, 50, 35);
			AddAbsBox(abs, .(80, 80, 200, 200), 80, 5, 50, 35);
		}

		AddSeparator(left);
		AddSectionLabel(left, "ImageView + Spacer");

		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			left.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 48 });
			let iv = new ImageView();
			iv.Image = mCheckerboard;
			row.AddView(iv, new LinearLayout.LayoutParams() { Width = 48, Height = 48 });
			row.AddView(new Spacer(8, 0));
			let desc = new Label();
			desc.SetText("Checkerboard ImageView");
			desc.TextColor = .(180, 190, 210, 255);
			desc.FontSize = 16;
			desc.VAlign = .Middle;
			row.AddView(desc, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });
		}

		// --- RIGHT COLUMN ---
		let right = new LinearLayout();
		right.Orientation = .Vertical;
		right.Spacing = 6;
		columns.AddView(right, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = 1 });

		AddSectionLabel(right, "Drawable Showcase");

		// Drawable types — 2x2 grid
		{
			let grid = new GridLayout();
			grid.ColumnDefs.Add(.Star(1));
			grid.ColumnDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.RowDefs.Add(.Star(1));
			grid.HSpacing = 6;
			grid.VSpacing = 6;
			right.AddView(grid, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 110 });

			// Gradient
			let gradPanel = new Panel();
			gradPanel.Background = new GradientDrawable(.(80, 40, 180, 255), .(40, 160, 200, 255), .TopToBottom);
			grid.AddView(gradPanel, new GridLayout.LayoutParams() { Row = 0, Column = 0 });

			// Image
			let imgPanel = new Panel();
			imgPanel.Background = new ImageDrawable(mCheckerboard);
			grid.AddView(imgPanel, new GridLayout.LayoutParams() { Row = 0, Column = 1 });

			// Layer (gradient + border)
			let layered = new LayerDrawable();
			layered.AddLayer(new GradientDrawable(.(40, 80, 60, 255), .(20, 40, 80, 255), .LeftToRight));
			layered.AddLayer(new RoundedRectDrawable(.Transparent, 4, .(120, 200, 140, 255), 2));
			let layerPanel = new Panel();
			layerPanel.Background = layered;
			grid.AddView(layerPanel, new GridLayout.LayoutParams() { Row = 1, Column = 0 });

			// Shape (custom X)
			let shapePanel = new Panel();
			shapePanel.Background = new ShapeDrawable(new (ctx, bounds) => {
				ctx.VG.FillRect(bounds, .(40, 40, 50, 255));
				ctx.VG.DrawLine(.(bounds.X, bounds.Y), .(bounds.X + bounds.Width, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
				ctx.VG.DrawLine(.(bounds.X + bounds.Width, bounds.Y), .(bounds.X, bounds.Y + bounds.Height), .(255, 100, 100, 200), 2);
			});
			grid.AddView(shapePanel, new GridLayout.LayoutParams() { Row = 1, Column = 1 });
		}

		AddSeparator(right);
		AddSectionLabel(right, "GridLayout (Auto / Star)");

		{
			let grid = new GridLayout();
			grid.ColumnDefs.Add(.Auto());
			grid.ColumnDefs.Add(.Star(2));
			grid.ColumnDefs.Add(.Star(1));
			grid.RowDefs.Add(.Pixel(22));
			grid.RowDefs.Add(.Pixel(22));
			grid.HSpacing = 6;
			grid.VSpacing = 2;
			right.AddView(grid, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 46 });

			AddGridCell(grid, "Name:", 0, 0, .(140, 150, 170, 255));
			AddGridCell(grid, "Sedulous Engine", 0, 1, .(200, 210, 230, 255));
			AddGridCell(grid, "v1.0", 0, 2, .(120, 180, 120, 255));
			AddGridCell(grid, "Status:", 1, 0, .(140, 150, 170, 255));
			AddGridCell(grid, "Phase 2", 1, 1, .(200, 210, 230, 255));
			AddGridCell(grid, "OK", 1, 2, .(120, 180, 120, 255));
		}

		AddSeparator(right);
		AddSectionLabel(right, "NineSliceDrawable (Kenney)");

		// 9-slice buttons stretched to different widths.
		if (mButtonNormal != null)
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			right.AddView(row, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 42 });

			for (let w in float[](80, 140, 200))
			{
				let panel = new Panel();
				panel.Background = new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8));
				panel.Padding = .(8, 4);
				row.AddView(panel, new LinearLayout.LayoutParams() { Width = w, Height = LayoutParams.MatchParent });
				let label = new Label();
				label.SetText((w == 80) ? "Small" : ((w == 140) ? "Medium" : "Wide Button"));
				label.TextColor = .White;
				label.FontSize = 16;
				label.HAlign = .Center;
				panel.AddView(label, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });
			}
		}

		// 9-slice StateList button.
		if (mButtonNormal != null && mButtonPressed != null)
		{
			let sld = new StateListDrawable();
			sld.Set(.Normal, new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8)));
			sld.Set(.Pressed, new NineSliceDrawable(mButtonPressed, .(8, 8, 8, 8)));
			sld.Set(.Hover, new NineSliceDrawable(mButtonNormal, .(8, 8, 8, 8), .(220, 230, 255, 255)));

			let btn = new Button();
			btn.SetText("9-Slice StateList");
			btn.Background = sld;
			btn.FontSize = 16;
			right.AddView(btn, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 42 });
		}

		// F2=bounds  F3=padding  F4=margin
	}

	// === Helpers ===

	private void AddSectionLabel(LinearLayout parent, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.TextColor = .(255, 200, 100, 255);
		label.FontSize = 16;
		parent.AddView(label, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 22 });
	}

	private void AddSeparator(LinearLayout parent)
	{
		let sep = new Separator();
		sep.Color = .(60, 65, 75, 255);
		parent.AddView(sep, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = 1 });
	}

	private void AddWeightedColor(LinearLayout row, Color color, float weight)
	{
		let cv = new ColorView();
		cv.Color = color;
		row.AddView(cv, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent, Weight = weight });
	}

	private void AddButton(LinearLayout row, StringView text, Color bgColor)
	{
		let btn = new Button();
		btn.SetText(text);
		btn.FontSize = 16;

		let bg = new StateListDrawable();
		bg.Set(.Normal, new RoundedRectDrawable(bgColor, 4));
		bg.Set(.Hover, new RoundedRectDrawable(Lighten(bgColor, 0.15f), 4));
		bg.Set(.Pressed, new RoundedRectDrawable(Darken(bgColor, 0.15f), 4));
		bg.Set(.Disabled, new RoundedRectDrawable(Desaturate(bgColor, 0.5f), 4));
		btn.Background = bg;

		row.AddView(btn, new LinearLayout.LayoutParams() { Height = LayoutParams.MatchParent });
	}

	private void AddAbsBox(AbsoluteLayout abs, Color color, float x, float y, float w, float h)
	{
		let cv = new ColorView();
		cv.Color = color;
		cv.PreferredWidth = w;
		cv.PreferredHeight = h;
		abs.AddView(cv, new AbsoluteLayout.LayoutParams() { X = x, Y = y });
	}

	private void AddGridCell(GridLayout grid, StringView text, int32 row, int32 col, Color color)
	{
		let label = new Label();
		label.SetText(text);
		label.TextColor = color;
		label.FontSize = 16;
		grid.AddView(label, new GridLayout.LayoutParams() {
			Row = row, Column = col,
			Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent
		});
	}

	/// Load a PNG/JPG file and convert to OwnedImageData (RGBA8).
	private OwnedImageData LoadImageAsRGBA8(StringView path)
	{
		if (ImageLoaderFactory.LoadImage(path) case .Ok(let loaded))
		{
			OwnedImageData result;
			if (loaded.Format == .RGBA8)
			{
				result = new OwnedImageData(loaded.Width, loaded.Height, .RGBA8, loaded.Data);
			}
			else
			{
				// Convert to RGBA8.
				if (loaded.ConvertFormat(.RGBA8) case .Ok(let converted))
				{
					result = new OwnedImageData(converted.Width, converted.Height, .RGBA8, converted.Data);
					delete converted;
				}
				else
				{
					delete loaded;
					return null;
				}
			}
			delete loaded;
			return result;
		}
		return null;
	}

	private static Color Lighten(Color c, float amount)
	{
		return .(
			(uint8)Math.Min(255, (int)(c.R + (255 - c.R) * amount)),
			(uint8)Math.Min(255, (int)(c.G + (255 - c.G) * amount)),
			(uint8)Math.Min(255, (int)(c.B + (255 - c.B) * amount)),
			c.A);
	}

	private static Color Darken(Color c, float amount)
	{
		return .(
			(uint8)Math.Max(0, (int)(c.R * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.G * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.B * (1 - amount))),
			c.A);
	}

	private static Color Desaturate(Color c, float amount)
	{
		let gray = (uint8)((c.R + c.G + c.B) / 3);
		return .(
			(uint8)(c.R + (gray - c.R) * amount),
			(uint8)(c.G + (gray - c.G) * amount),
			(uint8)(c.B + (gray - c.B) * amount),
			(uint8)(c.A * (1 - amount * 0.5f)));
	}

	private static Color HSLToColor(float h, float s, float l)
	{
		var h;
		h = h % 1.0f;
		if (h < 0) h += 1.0f;

		float r, g, b;
		if (s <= 0.0f) { r = g = b = l; }
		else
		{
			let q = l < 0.5f ? l * (1.0f + s) : l + s - l * s;
			let p = 2.0f * l - q;
			r = HueToRGB(p, q, h + 1.0f / 3.0f);
			g = HueToRGB(p, q, h);
			b = HueToRGB(p, q, h - 1.0f / 3.0f);
		}
		return Color((uint8)(r * 255), (uint8)(g * 255), (uint8)(b * 255), 255);
	}

	private static float HueToRGB(float p, float q, float t)
	{
		var t;
		if (t < 0) t += 1.0f;
		if (t > 1) t -= 1.0f;
		if (t < 1.0f / 6.0f) return p + (q - p) * 6.0f * t;
		if (t < 1.0f / 2.0f) return q;
		if (t < 2.0f / 3.0f) return p + (q - p) * (2.0f / 3.0f - t) * 6.0f;
		return p;
	}

	protected override void OnUpdate(FrameContext frame)
	{
		if (mUI == null) return;

		let kb = Shell?.InputManager?.Keyboard;
		if (kb == null) return;

		// F2 toggles debug bounds overlay.
		if (kb.IsKeyPressed(.F2))
			mUI.UIContext.DebugSettings.ShowBounds = !mUI.UIContext.DebugSettings.ShowBounds;

		// F3 toggles padding overlay.
		if (kb.IsKeyPressed(.F3))
			mUI.UIContext.DebugSettings.ShowPadding = !mUI.UIContext.DebugSettings.ShowPadding;

		// F4 toggles margin overlay.
		if (kb.IsKeyPressed(.F4))
			mUI.UIContext.DebugSettings.ShowMargin = !mUI.UIContext.DebugSettings.ShowMargin;
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return false;

		ColorAttachment[1] clearAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.12f, 0.12f, 0.14f, 1.0f)
		});
		RenderPassDesc clearPass = .() { ColorAttachments = .(clearAttachments) };
		let rp = render.Encoder.BeginRenderPass(clearPass);
		if (rp != null) rp.End();

		mUI.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height,
			render.Frame.FrameIndex);

		return true;
	}

	protected override void OnShutdown()
	{
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope UISandboxApp();
		return app.Run(.()
		{
			Title = "UI Sandbox",
			Width = 900, Height = 620,
			EnableDepth = false
		});
	}
}
