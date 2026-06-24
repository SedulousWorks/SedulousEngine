namespace TowerDefense;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Engine.App;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.UI;
using Sedulous.Renderer;

/// Thin EngineApplication subclass. Configuration / startup / shutdown all
/// live on TowerDefenseModule (an IApplicationModule). The App exists only
/// to satisfy EngineApplication's abstract base and to dispatch per-frame
/// input (camera, tower placement, pause toggle) into the module's state
/// during the transition - per-frame logic will migrate to a Subsystem in
/// a later phase, at which point TowerDefenseApp collapses to a constructor.
class TowerDefenseApp : EngineApplication
{
	private TowerDefenseModule mModule = new .() ~ delete _;

	public this()
	{
		Module = mModule;
	}

	protected override void OnUpdate(float deltaTime)
	{
		let scene = mModule.Scene;
		if (scene == null)
			return;

		// Clean up expired particle effects
		mModule.ParticleEffects.Update(deltaTime);

		let keyboard = mShell.InputManager.Keyboard;
		let mouse = mShell.InputManager.Mouse;
		let gameSub = mModule.GameSub;
		let camera = mModule.Camera;
		let towerPlacement = mModule.TowerPlacement;
		let pauseUI = mModule.PauseUI;

		// Camera controls (always available except menu)
		if (gameSub.Phase != .MainMenu)
		{
			camera.Update(deltaTime, keyboard, mouse);
			camera.ApplyToScene(scene);
		}

		// Pause toggle (P or Escape during gameplay)
		if (keyboard.IsKeyPressed(.P) || keyboard.IsKeyPressed(.Escape))
		{
			if (gameSub.IsGameplayPhase)
			{
				gameSub.PauseGame();
				let uiSub = Context.GetSubsystem<EngineUISubsystem>();
				if (uiSub?.ScreenView != null)
					pauseUI.Show();
			}
			else if (gameSub.Phase == .Paused)
			{
				gameSub.ResumeGame();
				pauseUI.Hide();
			}
		}

		// Gameplay input (active gameplay phases only)
		if (gameSub.IsGameplayPhase)
		{
			// Space to start next wave
			if (keyboard.IsKeyPressed(.Space) && (gameSub.Phase == .WaitingToStart || gameSub.Phase == .WavePaused))
			{
				mModule.StartWave();
			}

			// Tower selection (1-4 keys, 0 to deselect)
			if (keyboard.IsKeyPressed(.Num1)) { towerPlacement.SelectedType = .Ballista; }
			if (keyboard.IsKeyPressed(.Num2)) { towerPlacement.SelectedType = .Cannon; }
			if (keyboard.IsKeyPressed(.Num3)) { towerPlacement.SelectedType = .Catapult; }
			if (keyboard.IsKeyPressed(.Num4)) { towerPlacement.SelectedType = .Turret; }
			if (keyboard.IsKeyPressed(.Num0)) { towerPlacement.SelectedType = null; }

			// Tower placement (mouse click on grid)
			towerPlacement.Update(mouse, scene, gameSub, gameSub.TowerMgr, camera.CameraEntity);

			// Draw debug markers on tower slots and hover
			let renderSub = Context.GetSubsystem<RenderSubsystem>();
			if (renderSub != null)
			{
				towerPlacement.DrawDebug(renderSub.DebugDraw, gameSub);

				// Health bars - billboard using camera vectors
				let offsetY = camera.Zoom * Math.Cos(camera.ViewAngle);
				let offsetZ = camera.Zoom * Math.Sin(camera.ViewAngle);
				let camPos = camera.LookTarget + Vector3(0, offsetY, offsetZ);
				let camFwd = Vector3.Normalize(camera.LookTarget - camPos);
				let camRight = Vector3.Normalize(Vector3.Cross(camFwd, .(0, 1, 0)));
				let camUp = Vector3.Cross(camRight, camFwd);
				gameSub.EnemyMgr?.DrawHealthBars(renderSub.DebugDraw, camRight, camUp);
			}
		}
	}
}
