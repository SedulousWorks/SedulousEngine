namespace UISandbox;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.UI.Runtime;

/// UISandbox — gallery/showcase for Sedulous.UI, growing with each phase.
/// Phase 1: first-light rendering with ColorViews in LinearLayout + FrameLayout.
class UISandboxApp : Application
{
	private UISubsystem mUI;

	public this() : base()
	{
	}

	protected override void OnInitialize(Sedulous.Runtime.Context context)
	{
		// Create the UI subsystem.
		mUI = new UISubsystem();
		context.RegisterSubsystem(mUI);

		// Initialize rendering (shader path, device, swap chain).
		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);

		if (mUI.InitializeRendering(Device, SwapChain.Format, (int32)SwapChain.BufferCount,
			scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Build the Phase 1 demo tree.
		BuildDemoUI(mUI.UIContext);
	}

	private void BuildDemoUI(UIContext ctx)
	{
		// Root → vertical LinearLayout with 3 rows:
		//   Row 1: horizontal bar of weighted color panels
		//   Row 2: a FrameLayout demonstrating gravity
		//   Row 3: another horizontal bar

		let root = ctx.Root;

		let mainLayout = new LinearLayout();
		mainLayout.Orientation = .Vertical;
		mainLayout.Padding = .(16);
		mainLayout.Spacing = 12;
		root.AddView(mainLayout);

		// Row 1 — horizontal bar with 3 weighted color panels.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 8;
			mainLayout.AddView(row, new LinearLayout.LayoutParams()
			{
				Width = LayoutParams.MatchParent,
				Height = 60
			});

			AddWeightedColor(row, Color(200, 70, 70, 255), 2);   // red, weight 2
			AddWeightedColor(row, Color(70, 180, 70, 255), 1);   // green, weight 1
			AddWeightedColor(row, Color(70, 100, 220, 255), 1);  // blue, weight 1
		}

		// Row 2 — FrameLayout showing gravity positioning.
		{
			let frame = new FrameLayout();
			frame.Padding = .(8);
			mainLayout.AddView(frame, new LinearLayout.LayoutParams()
			{
				Width = LayoutParams.MatchParent,
				Height = LayoutParams.MatchParent,
				Weight = 1  // fill remaining vertical space
			});

			// Background fill
			let bg = new ColorView();
			bg.Color = Color(30, 30, 40, 255);
			frame.AddView(bg, new FrameLayout.LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

			// Top-left
			AddGravityBox(frame, Color(255, 200, 80, 255), .Left | .Top, 80, 50);
			// Center
			AddGravityBox(frame, Color(130, 200, 255, 255), .Center, 100, 60);
			// Bottom-right
			AddGravityBox(frame, Color(200, 130, 255, 255), .Right | .Bottom, 80, 50);
		}

		// Row 3 — another horizontal bar showing spacing + margin.
		{
			let row = new LinearLayout();
			row.Orientation = .Horizontal;
			row.Spacing = 4;
			mainLayout.AddView(row, new LinearLayout.LayoutParams()
			{
				Width = LayoutParams.MatchParent,
				Height = 40
			});

			for (int i = 0; i < 8; i++)
			{
				let hue = (float)i / 8.0f;
				let color = HSLToColor(hue, 0.6f, 0.5f);

				let cv = new ColorView();
				cv.Color = color;
				row.AddView(cv, new LinearLayout.LayoutParams()
				{
					Width = LayoutParams.MatchParent,
					Height = LayoutParams.MatchParent,
					Weight = 1
				});
			}
		}
	}

	private void AddWeightedColor(LinearLayout row, Color color, float weight)
	{
		let cv = new ColorView();
		cv.Color = color;
		row.AddView(cv, new LinearLayout.LayoutParams()
		{
			Width = LayoutParams.MatchParent,
			Height = LayoutParams.MatchParent,
			Weight = weight
		});
	}

	private void AddGravityBox(FrameLayout frame, Color color, Gravity gravity, float w, float h)
	{
		let cv = new ColorView();
		cv.Color = color;
		cv.PreferredWidth = w;
		cv.PreferredHeight = h;
		frame.AddView(cv, new FrameLayout.LayoutParams()
		{
			Width = w,
			Height = h,
			Gravity = gravity
		});
	}

	private static Color HSLToColor(float h, float s, float l)
	{
		var h;
		h = h % 1.0f;
		if (h < 0) h += 1.0f;

		float r, g, b;
		if (s <= 0.0f)
		{
			r = g = b = l;
		}
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

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return false;

		// Clear the background first.
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

		// Render UI overlay (LoadOp=Load preserves the clear).
		mUI.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height,
			render.Frame.FrameIndex);

		return true;
	}

	protected override void OnShutdown()
	{
		// UISubsystem is owned by Context — it's shut down + deleted via
		// Context.Shutdown(). Nothing explicit needed here.
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
			Width = 800, Height = 600,
			EnableDepth = false
		});
	}
}
