namespace AudioSandbox;

using System;
using System.Collections;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Runtime;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.Fonts;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Audio.Decoders;

/// Audio track info.
class AudioTrack
{
	public String Name ~ delete _;
	public String Path ~ delete _;
	public AudioClip Clip;

	public this(StringView name, StringView path)
	{
		Name = new String(name);
		Path = new String(path);
	}
}

/// Audio Sandbox - Audio Player with UI.
class AudioSandboxApp : Application
{
	// Audio system
	private SDL3AudioSystem mAudioSystem ~ delete _;
	private AudioDecoderFactory mDecoderFactory ~ delete _;
	private IAudioSource mCurrentSource;
	private List<AudioTrack> mTracks = new .() ~ DeleteContainerAndItems!(_);
	private int mCurrentTrackIndex = -1;
	private float mVolume = 0.7f;
	private bool mIsPlaying = false;

	// UI system
	private UISubsystem mUI;

	// UI Elements (for updating)
	private Label mNowPlayingLabel;
	private Label mVolumeLabel;
	private LinearLayout mTrackList;
	private Button mPlayPauseButton;

	public this() : base()
	{
	}

	protected override void OnInitialize(Context context)
	{
		// Initialize audio
		if (!InitializeAudio())
			return;

		// Initialize UI subsystem
		UIRegistry.RegisterBuiltins();

		mUI = new UISubsystem();
		context.RegisterSubsystem(mUI);

		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);
		if (mUI.InitializeRendering(mDevice, mSwapChain.Format, (int32)mSwapChain.BufferCount, scope StringView[](shaderPath), mShell, mWindow) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Load font
		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);
		FontLoadOptions fontOptions = .ExtendedLatin;
		fontOptions.PixelHeight = 16;
		mUI.LoadFont("Roboto", fontPath, fontOptions);

		// Also load a larger size for the title
		FontLoadOptions titleFontOptions = .ExtendedLatin;
		titleFontOptions.PixelHeight = 20;
		mUI.LoadFont("Roboto", fontPath, titleFontOptions);

		// Build UI
		BuildUI();

		// Load audio tracks
		LoadAudioTracks();
	}

	private bool InitializeAudio()
	{
		Console.WriteLine("Initializing audio system...");

		mAudioSystem = new SDL3AudioSystem();
		if (!mAudioSystem.IsInitialized)
		{
			Console.WriteLine("ERROR: Failed to initialize audio system!");
			return false;
		}

		mDecoderFactory = new AudioDecoderFactory();
		mDecoderFactory.RegisterDefaultDecoders();

		Console.WriteLine($"Audio system initialized. Decoders: {mDecoderFactory.DecoderCount}");
		return true;
	}

	private void BuildUI()
	{
		let root = mUI.Root;
		if (root == null)
			return;

		// Main vertical layout: header | track list (fills) | controls bar
		let mainLayout = new LinearLayout();
		mainLayout.Orientation = .Vertical;
		root.AddView(mainLayout, new LayoutParams() { Width = LayoutParams.MatchParent, Height = LayoutParams.MatchParent });

		// Header
		let header = new LinearLayout();
		header.Orientation = .Vertical;
		header.Padding = .(20, 15, 20, 15);
		header.Spacing = 5;
		//header.StyleId = "Header";

		let title = new Label();
		title.SetText("Audio Player");
		title.FontSize = 20;
		header.AddView(title);

		mNowPlayingLabel = new Label();
		mNowPlayingLabel.SetText("No track selected");
		mNowPlayingLabel.TextColor = .(150, 150, 160);
		header.AddView(mNowPlayingLabel);

		mainLayout.AddView(header, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });

		// Track list (scrollable, fills remaining space)
		let scrollView = new ScrollView();
		scrollView.VScrollPolicy = .Auto;
		scrollView.HScrollPolicy = .Never;

		mTrackList = new LinearLayout();
		mTrackList.Orientation = .Vertical;
		mTrackList.Spacing = 2;
		mTrackList.Padding = .(10);
		scrollView.AddView(mTrackList, new LayoutParams() { Width = LayoutParams.MatchParent });

		mainLayout.AddView(scrollView, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent, Weight = 1 });

		// Controls bar
		let controlsBar = new LinearLayout();
		controlsBar.Orientation = .Horizontal;
		controlsBar.Spacing = 15;
		controlsBar.Padding = .(20, 10, 20, 10);
		//controlsBar.StyleId = "ControlsBar";

		// Play/Pause button
		mPlayPauseButton = new Button();
		mPlayPauseButton.Text = new .("Play");
		mPlayPauseButton.Padding = .(20, 8, 20, 8);
		mPlayPauseButton.OnClick.Add(new (btn) => TogglePlayPause());
		controlsBar.AddView(mPlayPauseButton);

		// Stop button
		let stopBtn = new Button();
		stopBtn.Text = new .("Stop");
		stopBtn.Padding = .(20, 8, 20, 8);
		stopBtn.OnClick.Add(new (btn) => StopPlayback());
		controlsBar.AddView(stopBtn);

		// Spacer
		let spacer = new Spacer();
		spacer.SpacerWidth = 20;
		controlsBar.AddView(spacer);

		// Volume down
		let volDown = new Button();
		volDown.Text = new .("-");
		volDown.Padding = .(12, 8, 12, 8);
		volDown.OnClick.Add(new (btn) => AdjustVolume(-0.1f));
		controlsBar.AddView(volDown);

		// Volume label
		mVolumeLabel = new Label();
		mVolumeLabel.SetText("70%");
		mVolumeLabel.HAlign = .Center;
		controlsBar.AddView(mVolumeLabel, new LinearLayout.LayoutParams() { Width = 50, Gravity = .CenterV });

		// Volume up
		let volUp = new Button();
		volUp.Text = new .("+");
		volUp.Padding = .(12, 8, 12, 8);
		volUp.OnClick.Add(new (btn) => AdjustVolume(0.1f));
		controlsBar.AddView(volUp);

		mainLayout.AddView(controlsBar, new LinearLayout.LayoutParams() { Gravity = .CenterH });
	}

	private void LoadAudioTracks()
	{
		String audioDir = scope .();
		GetAssetPath("samples/audio/kenney_rpg-audio/Audio", audioDir);

		Console.WriteLine($"Loading audio from: {audioDir}");

		if (!Directory.Exists(audioDir))
		{
			Console.WriteLine("Audio directory not found!");
			return;
		}

		for (let entry in Directory.EnumerateFiles(audioDir, "*.ogg"))
		{
			String fileName = scope .();
			entry.GetFileName(fileName);

			String fullPath = scope .();
			entry.GetFilePath(fullPath);

			let track = new AudioTrack(fileName, fullPath);
			mTracks.Add(track);
		}

		Console.WriteLine($"Found {mTracks.Count} audio files");

		for (int i = 0; i < mTracks.Count; i++)
		{
			let track = mTracks[i];
			let trackIndex = i;

			let trackBtn = new Button();
			trackBtn.Text = new .(track.Name);
			trackBtn.Padding = .(10, 6, 10, 6);
			trackBtn.OnClick.Add(new [&this,=trackIndex](sender) => { this.SelectTrack(trackIndex); });

			mTrackList.AddView(trackBtn, new LinearLayout.LayoutParams() { Width = LayoutParams.MatchParent });
		}
	}

	// ==================== Audio Controls ====================

	private void SelectTrack(int index)
	{
		if (index < 0 || index >= mTracks.Count)
			return;

		mCurrentTrackIndex = index;
		let track = mTracks[index];

		Console.WriteLine($"Selected: {track.Name}");

		if (track.Clip == null)
		{
			Console.WriteLine($"Decoding: {track.Path}");
			if (mDecoderFactory.DecodeFile(track.Path) case .Ok(let clip))
			{
				track.Clip = clip;
				Console.WriteLine($"Decoded: {clip.Duration:F2}s, {clip.SampleRate}Hz, {clip.Channels}ch");
			}
			else
			{
				Console.WriteLine("Failed to decode audio file!");
				return;
			}
		}

		mNowPlayingLabel.SetText(track.Name);
		PlayCurrentTrack();
	}

	private void PlayCurrentTrack()
	{
		if (mCurrentTrackIndex < 0 || mCurrentTrackIndex >= mTracks.Count)
			return;

		let track = mTracks[mCurrentTrackIndex];
		if (track.Clip == null)
			return;

		StopPlayback();

		mCurrentSource = mAudioSystem.CreateSource();
		if (mCurrentSource != null)
		{
			mCurrentSource.Volume = mVolume;
			mCurrentSource.Play(track.Clip);
			mIsPlaying = true;
			mPlayPauseButton.Text.Set("Pause");
			mPlayPauseButton.InvalidateLayout();
		}
	}

	private void TogglePlayPause()
	{
		if (mCurrentSource == null)
		{
			if (mCurrentTrackIndex >= 0)
				PlayCurrentTrack();
			return;
		}

		if (mIsPlaying)
		{
			mCurrentSource.Pause();
			mIsPlaying = false;
			mPlayPauseButton.Text.Set("Play");
			mPlayPauseButton.InvalidateLayout();
		}
		else
		{
			mCurrentSource.Resume();
			mIsPlaying = true;
			mPlayPauseButton.Text.Set("Pause");
			mPlayPauseButton.InvalidateLayout();
		}
	}

	private void StopPlayback()
	{
		if (mCurrentSource != null)
		{
			mCurrentSource.Stop();
			mAudioSystem.DestroySource(mCurrentSource);
			mCurrentSource = null;
		}
		mIsPlaying = false;
		if (mPlayPauseButton?.Text != null)
		{
			mPlayPauseButton.Text.Set("Play");
			mPlayPauseButton.InvalidateLayout();
		}
	}

	private void AdjustVolume(float delta)
	{
		mVolume = Math.Clamp(mVolume + delta, 0.0f, 1.0f);

		if (mCurrentSource != null)
			mCurrentSource.Volume = mVolume;

		let pct = (int)(mVolume * 100);
		mVolumeLabel.SetText(scope:: $"{pct}%");
	}

	// ==================== Lifecycle ====================

	protected override void OnUpdate(FrameContext frame)
	{
		// Update audio system
		mAudioSystem.Update();

		// Check if track finished
		if (mCurrentSource != null && mCurrentSource.State == .Stopped && mIsPlaying)
		{
			mIsPlaying = false;
			mPlayPauseButton.Text.Set("Play");
			mPlayPauseButton.InvalidateLayout();
		}

		// Spacebar for play/pause
		if (mShell.InputManager.Keyboard.IsKeyPressed(.Space))
			TogglePlayPause();
	}

	protected override bool OnRenderFrame(RenderContext render)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return false;

		// Clear with theme background color
		let bg = mUI.UIContext.Theme?.Palette.Background ?? Color(30, 30, 35, 255);

		ColorAttachment[1] clearAttachments = .(.()
		{
			View = render.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(bg.R / 255.0f, bg.G / 255.0f, bg.B / 255.0f, bg.A / 255.0f)
		});
		RenderPassDesc clearPass = .() { ColorAttachments = .(clearAttachments) };
		let rp = render.Encoder.BeginRenderPass(clearPass);
		if (rp != null)
			rp.End();

		// Render UI
		mUI.Render(render.Encoder, render.CurrentTextureView,
			render.SwapChain.Width, render.SwapChain.Height,
			render.Frame.FrameIndex);

		return true;
	}

	protected override void OnShutdown()
	{
		StopPlayback();

		// Clean up tracks (clips are owned by tracks)
		for (let track in mTracks)
		{
			if (track.Clip != null)
				delete track.Clip;
		}
	}
}

class Program
{
	public static int Main(String[] args)
	{
		let app = scope AudioSandboxApp();
		return app.Run(.()
		{
			Title = "Audio Sandbox",
			Width = 800, Height = 600,
			EnableDepth = false
		});
	}
}
