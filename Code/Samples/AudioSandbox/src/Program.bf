namespace AudioSandbox;

using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.RuntimeGraphics;
using Sedulous.UI;
using Sedulous.UI.Runtime;
using Sedulous.Fonts;
using Sedulous.Audio;
using Sedulous.Audio.SDL3;
using Sedulous.Audio.Decoders;
using RuntimeSampleFramework;

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
class AudioSandboxApp : RuntimeSampleApp
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
	private UIContext mUIContext;
	private RootView mRoot;

	// UI Elements (for updating)
	private Label mNowPlayingLabel;
	private Label mVolumeLabel;
	private FlexLayout mTrackList;
	private Button mPlayPauseButton;

	public override ApplicationSettings Settings()
	{
		return .()
		{
			Title = "Audio Sandbox",
			Width = 800, Height = 600,
		};
	}

	protected override void OnInit(Sedulous.Runtime.Client.IApplicationHost host)
	{
		// Initialize audio
		if (!InitializeAudio())
			return;

		// Create UI context and root
		mUIContext = new UIContext();
		mRoot = new RootView();

		// Set default theme
		let sheet = DarkTheme.Create();
		mUIContext.StyleSheet = sheet;
		sheet.ReleaseRef();

		// Initialize UI subsystem
		mUI = new UISubsystem();
		host.Ctx.RegisterSubsystem(mUI);

		let rw = host.MainWindow;
		String shaderPath = scope .();
		Path.InternalCombine(shaderPath, BuiltInAssetDirectory, "shaders");
		// Pass BuiltinMount so the UI subsystem's font service routes font
		// loads through the `builtin://` VFS scheme.
		if (mUI.InitializeRendering(mUIContext, mRoot, Device, rw.Swap.Format, (int32)rw.Swap.BufferCount, scope StringView[](shaderPath), Shell, rw.Window, BuiltinMount) case .Err)
		{
			Console.WriteLine("Failed to initialize UI rendering");
			return;
		}

		// Load font through the VFS-routed service. Locator is relative to
		// BuiltinMount.
		let fontLocator = "fonts/roboto/Roboto-Regular.ttf";
		mUI.LoadFont("Roboto", fontLocator, .() { PixelHeight = 16 });
		mUI.LoadFont("Roboto", fontLocator, .() { PixelHeight = 20 });

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
		// Main vertical layout: header | track list (fills) | controls bar
		let mainLayout = new FlexLayout();
		mainLayout.Direction = .Vertical;
		mRoot.AddView(mainLayout);

		// Header
		let header = new FlexLayout();
		header.Direction = .Vertical;
		header.Padding = .(20, 15, 20, 15);
		header.Spacing = 5;

		let title = new Label("Audio Player");
		title.FontSize.Value = 20;
		header.AddView(title);

		mNowPlayingLabel = new Label("No track selected");
		header.AddView(mNowPlayingLabel, new FlexLayout.LayoutParams() { Width = .Match });

		mainLayout.AddView(header, new FlexLayout.LayoutParams() { Width = .Match });

		// Track list (scrollable, fills remaining space)
		let scrollView = new ScrollView();
		scrollView.VScrollBarPolicy.Value = .Auto;
		scrollView.HScrollBarPolicy.Value = .Never;

		mTrackList = new FlexLayout();
		mTrackList.Direction = .Vertical;
		mTrackList.Spacing = 2;
		mTrackList.Padding = .(10);
		scrollView.AddView(mTrackList, new LayoutParams() { Width = .Match });

		mainLayout.AddView(scrollView, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Controls bar
		let controlsBar = new FlexLayout();
		controlsBar.Direction = .Horizontal;
		controlsBar.Spacing = 15;
		controlsBar.Padding = .(20, 10, 20, 10);
		controlsBar.AlignItems = .Center;
		controlsBar.JustifyContent = .Center;

		// Play/Pause button
		mPlayPauseButton = new Button("Play");
		mPlayPauseButton.OnClick.Add(new (btn) => TogglePlayPause());
		controlsBar.AddView(mPlayPauseButton);

		// Stop button
		let stopBtn = new Button("Stop");
		stopBtn.OnClick.Add(new (btn) => StopPlayback());
		controlsBar.AddView(stopBtn);

		// Spacer
		controlsBar.AddView(new Spacer(20, 0));

		// Volume down
		let volDown = new Button("-");
		volDown.OnClick.Add(new (btn) => AdjustVolume(-0.1f));
		controlsBar.AddView(volDown);

		// Volume label
		mVolumeLabel = new Label("70%");
		mVolumeLabel.HAlign.Value = .Center;
		controlsBar.AddView(mVolumeLabel);

		// Volume up
		let volUp = new Button("+");
		volUp.OnClick.Add(new (btn) => AdjustVolume(0.1f));
		controlsBar.AddView(volUp);

		mainLayout.AddView(controlsBar);
	}

	private void LoadAudioTracks()
	{
		String audioDir = scope .();
		Path.InternalCombine(audioDir, BuiltInAssetDirectory, "samples/audio/kenney_rpg-audio/Audio");

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

			let trackBtn = new Button(track.Name);
			trackBtn.OnClick.Add(new [&this, =trackIndex](sender) => { this.SelectTrack(trackIndex); });

			mTrackList.AddView(trackBtn, new FlexLayout.LayoutParams() { Width = .Match });
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
			mPlayPauseButton.SetText("Pause");
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
			mPlayPauseButton.SetText("Play");
		}
		else
		{
			mCurrentSource.Resume();
			mIsPlaying = true;
			mPlayPauseButton.SetText("Pause");
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
		if (mPlayPauseButton != null)
		{
			mPlayPauseButton.SetText("Play");
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

	protected override void OnUpdate(Sedulous.Runtime.Client.IApplicationHost host, float deltaTime, float totalTime)
	{
		// Update audio system
		mAudioSystem.Update();

		// Check if track finished
		if (mCurrentSource != null && mCurrentSource.State == .Stopped && mIsPlaying)
		{
			mIsPlaying = false;
			mPlayPauseButton.SetText("Play");
		}

		// Spacebar for play/pause
		if (Shell.InputManager.Keyboard.IsKeyPressed(.Space))
			TogglePlayPause();
	}

	protected override void OnRender(Sedulous.Runtime.Client.IApplicationHost host, ref Sedulous.RuntimeGraphics.FrameContext frame)
	{
		if (mUI == null || !mUI.IsRenderingInitialized)
			return;

		// Clear with dark background
		ColorAttachment[1] clearAttachments = .(.()
		{
			View = frame.BackbufferView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(30 / 255.0f, 30 / 255.0f, 35 / 255.0f, 1.0f)
		});
		RenderPassDesc clearPass = .() { ColorAttachments = .(clearAttachments) };
		let rp = frame.Encoder.BeginRenderPass(clearPass);
		if (rp != null)
			rp.End();

		// Render UI
		mUI.Render(frame.Encoder, frame.BackbufferView,
			frame.Width, frame.Height,
			(int32)frame.FrameIndex);
	}

	protected override void OnCleanup(Sedulous.Runtime.Client.IApplicationHost host)
	{
		StopPlayback();
		mAudioSystem?.Dispose();

		// Clean up tracks (clips are owned by tracks)
		for (let track in mTracks)
		{
			if (track.Clip != null)
				delete track.Clip;
		}

		// Clean up UI
		if (mUIContext != null && mRoot != null)
			mUIContext.RemoveRootView(mRoot);
		delete mRoot;
		delete mUIContext;

		delete mAudioSystem;
		mAudioSystem = null;
	}
}

class Program
{
	public static int Main(String[] args)
	{
		return RuntimeSampleApp.Run<AudioSandboxApp>();
	}
}
