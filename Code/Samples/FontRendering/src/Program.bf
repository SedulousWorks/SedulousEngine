namespace FontRendering;

using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;
using Sedulous.Fonts.TTF;
using Sedulous.Shell.SDL3;

/// Vertex structure for text rendering with position, UV, and color.
[CRepr]
struct TextVertex
{
	public float[2] Position;
	public float[2] TexCoord;
	public float[4] Color;

	public this(float x, float y, float u, float v, Color32 color)
	{
		Position = .(x, y);
		TexCoord = .(u, v);
		// Normalize uint8 color components (0-255) to float (0-1)
		Color = .(color.R / 255.0f, color.G / 255.0f, color.B / 255.0f, color.A / 255.0f);
	}
}

/// Uniform buffer data for the projection matrix.
[CRepr]
struct Uniforms
{
	public Matrix Projection;
}

/// Font rendering sample demonstrating text rendering using font atlases.
class FontRenderingSample : IApplication
{
	// Font resources
	private IFont mFont;
	private IFontAtlas mFontAtlas;
	private TrueTypeTextShaper mTextShaper;
	private List<GlyphPosition> mShapedPositions = new .() ~ delete _;

	// Shader system
	private ShaderSystem mShaderSystem;

	// GPU resources
	private IBuffer mVertexBuffer;
	private IBuffer mIndexBuffer;
	private IBuffer mUniformBuffer;
	private ITexture mFontTexture;
	private ITextureView mFontTextureView;
	private ISampler mFontSampler;
	private IShaderModule mVertShader;
	private IShaderModule mFragShader;
	private IBindGroupLayout mBindGroupLayout;
	private IBindGroup mBindGroup;
	private IPipelineLayout mPipelineLayout;
	private IRenderPipeline mPipeline;

	// Dynamic vertex/index data
	private List<TextVertex> mVertices = new .() ~ delete _;
	private List<uint16> mIndices = new .() ~ delete _;
	private int mMaxQuads = 1024;
	private bool mVertexBufferDirty = true;

	// Animation state
	private float mAnimationTime = 0;

	// Timing
	private float mTotalTime = 0;

	// FPS tracking
	private int mFrameCount = 0;
	private float mFpsTimer = 0;
	private int mCurrentFps = 0;

	// Cached device
	private IDevice mDevice;

	// Asset directory
	private String mBuiltInAssetDirectory = new .() ~ delete _;

	// Cached screen dimensions
	private uint32 mWidth;
	private uint32 mHeight;

	public ApplicationSettings Settings()
	{
		return .() { Title = "Font Rendering", Width = 1024, Height = 768, ClearColor = .(0.1f, 0.1f, 0.15f, 1.0f), EnableDepth = false };
	}

	public void Configure(IApplicationHost host)
	{
		DiscoverAssets();
		mDevice = host.Graphics.Raw;
	}

	public void OnStartup(IApplicationHost host)
	{
		mShaderSystem = new ShaderSystem();
		String shaderPath = scope .();
		Path.InternalCombine(shaderPath, mBuiltInAssetDirectory, "samples/FontRendering/shaders");
		if (mShaderSystem.Initialize(mDevice, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		if (!InitializeFont())
			return;

		if (!CreateFontTexture())
			return;

		if (!CreateBuffers())
			return;

		if (!CreateBindings())
			return;

		let rw = host.MainWindow;
		if (!CreatePipeline(rw.Swap.Format))
			return;
	}

	private bool InitializeFont()
	{
		// Use Roboto font from assets
		String fontPath = scope .();
		Path.InternalCombine(fontPath, mBuiltInAssetDirectory, "fonts/roboto/Roboto-Regular.ttf");

		if (!File.Exists(fontPath))
		{
			Console.WriteLine(scope $"Font not found: {fontPath}");
			return false;
		}

		Console.WriteLine(scope $"Loading font: {fontPath}");

		// Initialize TrueType font support
		TrueTypeFonts.Initialize();

		// Load font with default size 32
		FontLoadOptions options = .Default;
		options.PixelHeight = 32;
		options.AtlasWidth = 512;
		options.AtlasHeight = 512;

		if (FontParserFactory.ParseFromFile(fontPath, options) case .Ok(let font))
		{
			mFont = font;
		}
		else
		{
			Console.WriteLine("Failed to load font");
			return false;
		}

		// Create font atlas
		if (FontAtlasBakerFactory.Bake(mFont, options) case .Ok(let atlas))
		{
			mFontAtlas = atlas;
			Console.WriteLine(scope $"Font atlas created: {mFontAtlas.Width}x{mFontAtlas.Height}");
		}
		else
		{
			Console.WriteLine("Failed to create font atlas");
			return false;
		}

		// Create text shaper
		mTextShaper = new TrueTypeTextShaper();

		return true;
	}

	private bool CreateFontTexture()
	{
		// Create texture from atlas data
		TextureDesc textureDesc = TextureDesc.Texture2D(
			mFontAtlas.Width,
			mFontAtlas.Height,
			.R8Unorm,
			.Sampled | .CopyDst
		);

		if (mDevice.CreateTexture(textureDesc) not case .Ok(let texture))
		{
			Console.WriteLine("Failed to create font texture");
			return false;
		}
		mFontTexture = texture;

		// Upload atlas data
		TextureDataLayout dataLayout = .()
		{
			Offset = 0,
			BytesPerRow = mFontAtlas.Width,
			RowsPerImage = mFontAtlas.Height
		};

		Extent3D writeSize = .(mFontAtlas.Width, mFontAtlas.Height, 1);
		TransferHelper.WriteTextureSync(mDevice.GetQueue(.Graphics), mDevice, mFontTexture, mFontAtlas.PixelData, dataLayout, writeSize);

		// Create texture view - must match texture format (R8Unorm)
		TextureViewDesc viewDesc = .()
		{
			Format = .R8Unorm
		};
		if (mDevice.CreateTextureView(mFontTexture, viewDesc) not case .Ok(let view))
		{
			Console.WriteLine("Failed to create font texture view");
			return false;
		}
		mFontTextureView = view;

		// Create sampler with linear filtering for smooth text
		SamplerDesc samplerDesc = .()
		{
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge,
			MagFilter = .Linear,
			MinFilter = .Linear,
			MipmapFilter = .Linear
		};
		if (mDevice.CreateSampler(samplerDesc) not case .Ok(let sampler))
		{
			Console.WriteLine("Failed to create sampler");
			return false;
		}
		mFontSampler = sampler;

		Console.WriteLine("Font texture created");
		return true;
	}

	private bool CreateBuffers()
	{
		// Vertex buffer (dynamic)
		uint64 vertexBufferSize = (uint64)(sizeof(TextVertex) * mMaxQuads * 4);
		BufferDesc vertexDesc = .()
		{
			Size = vertexBufferSize,
			Usage = .Vertex,
			Memory = .CpuToGpu
		};

		if (mDevice.CreateBuffer(vertexDesc) not case .Ok(let vb))
		{
			Console.WriteLine("Failed to create vertex buffer");
			return false;
		}
		mVertexBuffer = vb;

		// Index buffer (dynamic)
		uint64 indexBufferSize = (uint64)(sizeof(uint16) * mMaxQuads * 6);
		BufferDesc indexDesc = .()
		{
			Size = indexBufferSize,
			Usage = .Index,
			Memory = .CpuToGpu
		};

		if (mDevice.CreateBuffer(indexDesc) not case .Ok(let ib))
		{
			Console.WriteLine("Failed to create index buffer");
			return false;
		}
		mIndexBuffer = ib;

		// Uniform buffer
		BufferDesc uniformDesc = .()
		{
			Size = (uint64)sizeof(Uniforms),
			Usage = .Uniform,
			Memory = .CpuToGpu
		};

		if (mDevice.CreateBuffer(uniformDesc) not case .Ok(let ub))
		{
			Console.WriteLine("Failed to create uniform buffer");
			return false;
		}
		mUniformBuffer = ub;

		Console.WriteLine("Buffers created");
		return true;
	}

	private bool CreateBindings()
	{
		// Load text shaders
		let shaderResult = mShaderSystem.GetShaderPair("text");
		if (shaderResult case .Err)
		{
			Console.WriteLine("Failed to load text shaders");
			return false;
		}

		mVertShader = shaderResult.Value.vert.Module;
		mFragShader = shaderResult.Value.frag.Module;
		Console.WriteLine("Shaders compiled");

		// Create bind group layout (uniform buffer + texture + sampler)
		BindGroupLayoutEntry[3] layoutEntries = .(
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(0, .Fragment),
			BindGroupLayoutEntry.Sampler(0, .Fragment)
		);
		BindGroupLayoutDesc bindGroupLayoutDesc = .(layoutEntries);
		if (mDevice.CreateBindGroupLayout(bindGroupLayoutDesc) not case .Ok(let layout))
		{
			Console.WriteLine("Failed to create bind group layout");
			return false;
		}
		mBindGroupLayout = layout;

		// Create bind group
		BindGroupEntry[3] bindGroupEntries = .(
			BindGroupEntry.Buffer(mUniformBuffer, 0, 0),
			BindGroupEntry.Texture(mFontTextureView),
			BindGroupEntry.Sampler(mFontSampler)
		);
		BindGroupDesc bindGroupDesc = .(mBindGroupLayout, bindGroupEntries);
		if (mDevice.CreateBindGroup(bindGroupDesc) not case .Ok(let group))
		{
			Console.WriteLine("Failed to create bind group");
			return false;
		}
		mBindGroup = group;

		// Create pipeline layout
		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		PipelineLayoutDesc pipelineLayoutDesc = .(layouts);
		if (mDevice.CreatePipelineLayout(pipelineLayoutDesc) not case .Ok(let pipelineLayout))
		{
			Console.WriteLine("Failed to create pipeline layout");
			return false;
		}
		mPipelineLayout = pipelineLayout;

		Console.WriteLine("Bindings created");
		return true;
	}

	private bool CreatePipeline(TextureFormat swapFormat)
	{
		// Vertex attributes
		VertexAttribute[3] vertexAttributes = .(
			.(VertexFormat.Float2, 0, 0),  // Position at location 0
			.(VertexFormat.Float2, 8, 1),  // TexCoord at location 1
			.(VertexFormat.Float4, 16, 2)  // Color at location 2
		);
		VertexBufferLayout[1] vertexBuffers = .(
			.((uint64)sizeof(TextVertex), vertexAttributes)
		);

		// Color target with alpha blending
		ColorTargetState[1] colorTargets = .(.(swapFormat, .AlphaBlend));

		// Pipeline descriptor
		RenderPipelineDesc pipelineDesc = .()
		{
			Layout = mPipelineLayout,
			Vertex = .()
			{
				Shader = .(mVertShader, "main"),
				Buffers = vertexBuffers
			},
			Fragment = .()
			{
				Shader = .(mFragShader, "main"),
				Targets = colorTargets
			},
			Primitive = .()
			{
				Topology = .TriangleList,
				FrontFace = .CCW,
				CullMode = .None
			},
			DepthStencil = null,
			Multisample = .()
			{
				Count = 1,
				Mask = uint32.MaxValue,
				AlphaToCoverageEnabled = false
			}
		};

		if (mDevice.CreateRenderPipeline(pipelineDesc) not case .Ok(let pipeline))
		{
			Console.WriteLine("Failed to create pipeline");
			return false;
		}
		mPipeline = pipeline;

		Console.WriteLine("Pipeline created");
		return true;
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		mTotalTime += deltaTime;
		mAnimationTime = mTotalTime;

		// FPS calculation
		mFrameCount++;
		mFpsTimer += deltaTime;
		if (mFpsTimer >= 1.0f)
		{
			mCurrentFps = mFrameCount;
			mFrameCount = 0;
			mFpsTimer -= 1.0f;
		}
	}

	public void OnRenderWindow(IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		mWidth = frame.Width;
		mHeight = frame.Height;

		// Update projection matrix
		UpdateProjection();

		// Build text quads
		BuildTextQuads();

		// Begin render pass
		let rp = frame.BeginBackbufferPass(ClearColor(0.1f, 0.1f, 0.15f, 1.0f));
		if (rp != null)
		{
			// Render text
			if (mIndices.Count > 0)
			{
				rp.SetPipeline(mPipeline);
				rp.SetBindGroup(0, mBindGroup);
				rp.SetVertexBuffer(0, mVertexBuffer, 0);
				rp.SetIndexBuffer(mIndexBuffer, .UInt16, 0);
				rp.DrawIndexed((uint32)mIndices.Count, 1, 0, 0, 0);
			}
		}
		frame.EndBackbufferPass();
	}

	private void UpdateProjection()
	{
		// Orthographic projection for 2D text rendering (origin top-left)
		float width = (float)mWidth;
		float height = (float)mHeight;

		Matrix projection = Matrix.CreateOrthographicOffCenter(0, width, height, 0, -1, 1);

		Uniforms uniforms = .()
		{
			Projection = projection
		};

		Span<uint8> uniformData = .((uint8*)&uniforms, sizeof(Uniforms));
		TransferHelper.WriteMappedBuffer(mUniformBuffer, 0, uniformData);
	}

	private void BuildTextQuads()
	{
		mVertices.Clear();
		mIndices.Clear();

		float screenWidth = (float)mWidth;
		float screenHeight = (float)mHeight;
		float lineHeight = mFont.Metrics.LineHeight;
		float margin = 20;
		float columnWidth = screenWidth / 2 - margin * 2;

		// ============ LEFT COLUMN ============

		// Title and subtitle
		DrawText("Font Rendering Sample", margin, 0, Color32.White);
		DrawText("Sedulous.Fonts + stb_truetype", margin, lineHeight, Color32(0.6f, 0.6f, 0.6f, 1.0f));

		// --- Text Alignment Section ---
		float alignY = lineHeight * 2.5f;
		DrawText("Text Alignment:", margin, alignY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		alignY += lineHeight;
		DrawText("Left aligned text", margin, alignY, Color32(0.8f, 0.8f, 0.9f, 1.0f));

		alignY += lineHeight;
		DrawTextAligned("Center aligned text", margin, alignY, columnWidth, .Center, Color32(0.8f, 0.9f, 0.8f, 1.0f));

		alignY += lineHeight;
		DrawTextAligned("Right aligned text", margin, alignY, columnWidth, .Right, Color32(0.9f, 0.8f, 0.8f, 1.0f));

		// --- Colors Section ---
		float colorY = alignY + lineHeight * 1.5f;
		DrawText("Colors:", margin, colorY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		colorY += lineHeight;
		float colorX = margin;
		DrawText("Red", colorX, colorY, Color32.Red);
		colorX += mFont.MeasureString("Red") + 20;
		DrawText("Green", colorX, colorY, Color32.Green);
		colorX += mFont.MeasureString("Green") + 20;
		DrawText("Blue", colorX, colorY, Color32.Blue);
		colorX += mFont.MeasureString("Blue") + 20;
		DrawText("Yellow", colorX, colorY, Color32.Yellow);

		colorY += lineHeight;
		colorX = margin;
		DrawText("Cyan", colorX, colorY, Color32.Cyan);
		colorX += mFont.MeasureString("Cyan") + 20;
		DrawText("Magenta", colorX, colorY, Color32.Magenta);
		colorX += mFont.MeasureString("Magenta") + 20;
		DrawText("Orange", colorX, colorY, Color32(1.0f, 0.5f, 0.0f, 1.0f));

		// --- Rainbow Text (animated) ---
		float rainbowY = colorY + lineHeight * 1.5f;
		DrawText("Animation:", margin, rainbowY, Color32(0.9f, 0.9f, 0.5f, 1.0f));
		rainbowY += lineHeight;
		DrawTextRainbow("Rainbow animated text!", margin, rainbowY, mAnimationTime);

		// --- Text Decorations Section ---
		float decorY = rainbowY + lineHeight * 1.5f;
		DrawText("Text Decorations:", margin, decorY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		decorY += lineHeight;
		DrawTextWithUnderline("Underlined text", margin, decorY, Color32(0.8f, 0.9f, 0.8f, 1.0f));

		decorY += lineHeight;
		DrawTextWithStrikethrough("Strikethrough text", margin, decorY, Color32(0.9f, 0.8f, 0.8f, 1.0f));

		decorY += lineHeight;
		DrawTextWithBothDecorations("Both decorations", margin, decorY, Color32(0.8f, 0.8f, 0.9f, 1.0f));

		// --- Kerning Demo ---
		float kernY = decorY + lineHeight * 1.5f;
		DrawText("Kerning Pairs:", margin, kernY, Color32(0.9f, 0.9f, 0.5f, 1.0f));
		kernY += lineHeight;
		DrawText("AV  To  WA  Ty  VA", margin, kernY, Color32(0.8f, 0.8f, 0.9f, 1.0f));

		// ============ RIGHT COLUMN ============
		float rightX = screenWidth / 2 + margin;

		// --- Word Wrapping Section ---
		float wrapY = lineHeight * 2.5f;
		DrawText("Word Wrapping:", rightX, wrapY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		wrapY += lineHeight;
		StringView wrappedText = "The text shaper handles word wrapping automatically. Long sentences will be broken at word boundaries to fit within the specified maximum width.";
		DrawTextWrapped(wrappedText, rightX, wrapY, columnWidth, Color32(0.8f, 0.8f, 0.9f, 1.0f));

		// --- Font Metrics Section ---
		float metricsY = wrapY + lineHeight * 5;
		DrawText("Font Metrics:", rightX, metricsY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		metricsY += lineHeight;
		String metricsText = scope $"Pixel Height: {mFont.PixelHeight:0.0}";
		DrawText(metricsText, rightX, metricsY, Color32(0.7f, 0.7f, 0.8f, 1.0f));

		metricsY += lineHeight;
		metricsText.Set(scope $"Ascent: {mFont.Metrics.Ascent:0.0}");
		DrawText(metricsText, rightX, metricsY, Color32(0.7f, 0.7f, 0.8f, 1.0f));

		metricsY += lineHeight;
		metricsText.Set(scope $"Descent: {mFont.Metrics.Descent:0.0}");
		DrawText(metricsText, rightX, metricsY, Color32(0.7f, 0.7f, 0.8f, 1.0f));

		metricsY += lineHeight;
		metricsText.Set(scope $"Line Height: {mFont.Metrics.LineHeight:0.0}");
		DrawText(metricsText, rightX, metricsY, Color32(0.7f, 0.7f, 0.8f, 1.0f));

		// --- String Measurement ---
		float measureY = metricsY + lineHeight * 1.5f;
		DrawText("MeasureString:", rightX, measureY, Color32(0.9f, 0.9f, 0.5f, 1.0f));

		measureY += lineHeight;
		StringView sampleText = "Sample Text";
		float measuredWidth = mFont.MeasureString(sampleText);
		String measureInfo = scope $"\"{sampleText}\" = {measuredWidth:0.0}px";
		DrawText(measureInfo, rightX, measureY, Color32(0.7f, 0.7f, 0.8f, 1.0f));

		// ============ BOTTOM SECTION ============

		// Character sets
		float charY = screenHeight - lineHeight * 4;
		DrawTextAligned("ABCDEFGHIJKLMNOPQRSTUVWXYZ", margin, charY, screenWidth - margin * 2, .Center, Color32(0.5f, 0.5f, 0.7f, 1.0f));
		charY += lineHeight;
		DrawTextAligned("abcdefghijklmnopqrstuvwxyz  0123456789", margin, charY, screenWidth - margin * 2, .Center, Color32(0.5f, 0.5f, 0.7f, 1.0f));
		charY += lineHeight;
		DrawTextAligned("!@#$%^&*()_+-=[]{}|;':\",./<>?", margin, charY, screenWidth - margin * 2, .Center, Color32(0.5f, 0.5f, 0.7f, 1.0f));

		// FPS counter (top right)
		String fpsText = scope $"FPS: {mCurrentFps}";
		DrawTextAligned(fpsText, 0, 0, screenWidth - margin, .Right, Color32(0.0f, 1.0f, 0.0f, 1.0f));

		// Instructions at bottom
		DrawTextAligned("Press Escape to exit", margin, screenHeight - lineHeight, screenWidth - margin * 2, .Center, Color32(0.4f, 0.4f, 0.4f, 1.0f));

		// Upload vertex data
		if (mVertices.Count > 0)
		{
			let vertexData = Span<uint8>((uint8*)mVertices.Ptr, mVertices.Count * sizeof(TextVertex));
			TransferHelper.WriteMappedBuffer(mVertexBuffer, 0, vertexData);

			let indexData = Span<uint8>((uint8*)mIndices.Ptr, mIndices.Count * sizeof(uint16));
			TransferHelper.WriteMappedBuffer(mIndexBuffer, 0, indexData);
		}
	}

	private void DrawText(StringView text, float x, float y, Color32 color)
	{
		float cursorX = x;
		// Offset Y by ascent so that y=0 means top of text, not baseline
		float cursorY = y + mFont.Metrics.Ascent;

		for (let char in text.DecodedChars)
		{
			int32 codepoint = (int32)char;

			// Skip non-printable characters
			if (codepoint < 32 || codepoint > 126)
				continue;

			// Get glyph quad from atlas
			GlyphQuad quad = .();
			if (mFontAtlas.GetGlyphQuad(codepoint, ref cursorX, cursorY, out quad))
			{
				AddQuad(quad, color);
			}
		}
	}

	/// Draw text with horizontal alignment within a given width
	private void DrawTextAligned(StringView text, float x, float y, float width, TextAlignment alignment, Color32 color)
	{
		float textWidth = mFont.MeasureString(text);

		float offsetX = 0;
		switch (alignment)
		{
		case .Left:
			offsetX = 0;
		case .Center:
			offsetX = (width - textWidth) / 2;
		case .Right:
			offsetX = width - textWidth;
		}

		DrawText(text, x + offsetX, y, color);
	}

	/// Draw text with per-character rainbow colors (animated)
	private void DrawTextRainbow(StringView text, float x, float y, float time)
	{
		float cursorX = x;
		float cursorY = y + mFont.Metrics.Ascent;
		int charIndex = 0;

		for (let char in text.DecodedChars)
		{
			int32 codepoint = (int32)char;

			if (codepoint < 32 || codepoint > 126)
				continue;

			// Calculate rainbow color based on character position and time
			float hue = ((float)charIndex * 0.1f + time * 0.5f) % 1.0f;
			Color32 color = HsvToRgb(hue, 0.8f, 1.0f);

			GlyphQuad quad = .();
			if (mFontAtlas.GetGlyphQuad(codepoint, ref cursorX, cursorY, out quad))
			{
				AddQuad(quad, color);
			}

			charIndex++;
		}
	}

	/// Draw text using the text shaper with word wrapping
	private void DrawTextWrapped(StringView text, float x, float y, float maxWidth, Color32 color)
	{
		float totalHeight;
		if (mTextShaper.ShapeTextWrapped(mFont, text, maxWidth, mShapedPositions, out totalHeight) case .Err)
			return;

		// Offset Y by ascent so that y=0 means top of text, not baseline
		float yOffset = y + mFont.Metrics.Ascent;

		for (let pos in mShapedPositions)
		{
			// Skip spaces (they have no visible glyph)
			if (pos.Codepoint == (int32)' ')
				continue;

			// Calculate cursor position from shaped position
			float cursorX = x + pos.X;
			float cursorY = yOffset + pos.Y;

			// Get glyph quad from atlas
			GlyphQuad quad = .();
			if (mFontAtlas.GetGlyphQuad(pos.Codepoint, ref cursorX, cursorY, out quad))
			{
				AddQuad(quad, color);
			}
		}
	}

	/// Draw text with underline decoration
	private void DrawTextWithUnderline(StringView text, float x, float y, Color32 color)
	{
		DrawText(text, x, y, color);

		// Draw underline using font decoration metrics
		let decorations = mFont.Metrics.Decorations;
		float textWidth = mFont.MeasureString(text);
		float baseline = y + mFont.Metrics.Ascent;
		float underlineY = baseline + decorations.UnderlinePosition;

		DrawHorizontalLine(x, underlineY, textWidth, decorations.UnderlineThickness, color);
	}

	/// Draw text with strikethrough decoration
	private void DrawTextWithStrikethrough(StringView text, float x, float y, Color32 color)
	{
		DrawText(text, x, y, color);

		// Draw strikethrough using font decoration metrics
		let decorations = mFont.Metrics.Decorations;
		float textWidth = mFont.MeasureString(text);
		float baseline = y + mFont.Metrics.Ascent;
		float strikeY = baseline + decorations.StrikethroughPosition;

		DrawHorizontalLine(x, strikeY, textWidth, decorations.StrikethroughThickness, color);
	}

	/// Draw text with both underline and strikethrough decorations
	private void DrawTextWithBothDecorations(StringView text, float x, float y, Color32 color)
	{
		DrawText(text, x, y, color);

		let decorations = mFont.Metrics.Decorations;
		float textWidth = mFont.MeasureString(text);
		float baseline = y + mFont.Metrics.Ascent;

		// Draw underline
		float underlineY = baseline + decorations.UnderlinePosition;
		DrawHorizontalLine(x, underlineY, textWidth, decorations.UnderlineThickness, color);

		// Draw strikethrough
		float strikeY = baseline + decorations.StrikethroughPosition;
		DrawHorizontalLine(x, strikeY, textWidth, decorations.StrikethroughThickness, color);
	}

	/// Draw a horizontal line (used for underline/strikethrough)
	private void DrawHorizontalLine(float x, float y, float width, float thickness, Color32 color)
	{
		uint16 baseIndex = (uint16)mVertices.Count;

		float halfThickness = thickness * 0.5f;
		float y0 = y - halfThickness;
		float y1 = y + halfThickness;

		// Use the white pixel UV from the atlas for solid color drawing
		let (u, v) = mFontAtlas.WhitePixelUV;

		mVertices.Add(.(x, y0, u, v, color));
		mVertices.Add(.(x + width, y0, u, v, color));
		mVertices.Add(.(x + width, y1, u, v, color));
		mVertices.Add(.(x, y1, u, v, color));

		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 1);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 3);
	}

	/// Draw text using shaped positions (for custom shaping)
	private void DrawTextShaped(float baseX, float baseY, Color32 color)
	{
		// Offset Y by ascent so that y=0 means top of text, not baseline
		float yOffset = baseY + mFont.Metrics.Ascent;

		for (let pos in mShapedPositions)
		{
			// Skip spaces
			if (pos.Codepoint == (int32)' ')
				continue;

			float cursorX = baseX + pos.X;
			float cursorY = yOffset + pos.Y;

			GlyphQuad quad = .();
			if (mFontAtlas.GetGlyphQuad(pos.Codepoint, ref cursorX, cursorY, out quad))
			{
				AddQuad(quad, color);
			}
		}
	}

	private void AddQuad(GlyphQuad quad, Color32 color)
	{
		uint16 baseIndex = (uint16)mVertices.Count;

		// Add vertices (4 per quad)
		mVertices.Add(.(quad.X0, quad.Y0, quad.U0, quad.V0, color));  // Top-left
		mVertices.Add(.(quad.X1, quad.Y0, quad.U1, quad.V0, color));  // Top-right
		mVertices.Add(.(quad.X1, quad.Y1, quad.U1, quad.V1, color));  // Bottom-right
		mVertices.Add(.(quad.X0, quad.Y1, quad.U0, quad.V1, color));  // Bottom-left

		// Add indices (6 per quad, 2 triangles)
		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 1);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 0);
		mIndices.Add(baseIndex + 2);
		mIndices.Add(baseIndex + 3);
	}

	private Color32 HsvToRgb(float h, float s, float v)
	{
		if (s <= 0)
			return Color32(v, v, v, 1.0f);

		float hue = h * 6.0f;
		int i = (int)hue;
		float f = hue - (float)i;
		float p = v * (1.0f - s);
		float q = v * (1.0f - s * f);
		float t = v * (1.0f - s * (1.0f - f));

		switch (i % 6)
		{
		case 0: return Color32(v, t, p, 1.0f);
		case 1: return Color32(q, v, p, 1.0f);
		case 2: return Color32(p, v, t, 1.0f);
		case 3: return Color32(p, q, v, 1.0f);
		case 4: return Color32(t, p, v, 1.0f);
		case 5: return Color32(v, p, q, 1.0f);
		default: return Color32(v, v, v, 1.0f);
		}
	}

	public void OnShutdown(IApplicationHost host)
	{
		if (mDevice != null)
		{
			mDevice.DestroyRenderPipeline(ref mPipeline);
			mDevice.DestroyPipelineLayout(ref mPipelineLayout);
			mDevice.DestroyBindGroup(ref mBindGroup);
			mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
			//mDevice.DestroyShaderModule(ref mFragShader);
			//mDevice.DestroyShaderModule(ref mVertShader);
			mDevice.DestroySampler(ref mFontSampler);
			mDevice.DestroyTextureView(ref mFontTextureView);
			mDevice.DestroyTexture(ref mFontTexture);
			mDevice.DestroyBuffer(ref mUniformBuffer);
			mDevice.DestroyBuffer(ref mIndexBuffer);
			mDevice.DestroyBuffer(ref mVertexBuffer);
		}

		if (mShaderSystem != null) { mShaderSystem.Dispose(); delete mShaderSystem; }

		// Clean up font resources
		if (mTextShaper != null) delete mTextShaper;
		if (mFontAtlas != null) delete (Object)mFontAtlas;
		if (mFont != null) delete (Object)mFont;

		TrueTypeFonts.Shutdown();
	}

	private void DiscoverAssets()
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		var searchDir = scope String(cwd);
		while (true)
		{
			let assetsPath = scope String();
			Path.InternalCombine(assetsPath, searchDir, "Assets");
			if (Directory.Exists(assetsPath))
			{
				let marker = scope String();
				Path.InternalCombine(marker, assetsPath, ".assets");
				if (File.Exists(marker)) { mBuiltInAssetDirectory.Set(assetsPath); return; }
			}
			let parent = Path.GetDirectoryPath(searchDir, .. scope .());
			if (parent.IsEmpty || parent == searchDir) { mBuiltInAssetDirectory.Set(cwd); return; }
			searchDir.Set(parent);
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let shell = scope SDL3Shell();
		if (shell.Initialize() case .Err)
		{
			Console.WriteLine("ERROR: Failed to initialize shell");
			return 1;
		}
		defer shell.Shutdown();

		let graphicsResult = GraphicsDevice.Create(.() { EnableValidation = true });
		if (graphicsResult case .Err)
		{
			Console.WriteLine("ERROR: Failed to create graphics device");
			return 1;
		}
		let graphics = graphicsResult.Value;
		defer delete graphics;

		let app = scope FontRenderingSample();
		return ApplicationHost.RunApplication(app, shell, graphics);
	}
}
