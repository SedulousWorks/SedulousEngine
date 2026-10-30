<!-- The HUD (Lamplight.as fills it from the level): the target and what has been taken top left, a
     word for a moment in the middle (a checkpoint reached, the exit with nothing to show), the time
     top right; what the thief can do here (put out a lamp, pick a lock: Lamp.as, Door.as) above the
     controls, which show for a few seconds as a level starts; the light meter bottom left
     (LightMeter.as). Over the level, taking none of its input. Styled by LamplightSheet.css. Back (Escape, East) is the game's own
     Pause action (Lamplight.as), not the screen stack's. -->
<Screen blocks="false" back="none">
  <Panel class="hud">
    <Panel class="hud-top">
      <Panel class="hud-card">
        <Label id="hud-target" class="hud-target" text=""/>
        <Label id="hud-loot" class="hud-loot" text=""/>
      </Panel>
      <Label id="hud-note" class="hud-note" text="Checkpoint"/>
      <Panel class="hud-card"><Label id="hud-time" class="hud-time" text="0:00"/></Panel>
    </Panel>
    <Panel class="hud-foot">
      <Panel class="hud-row">
        <Panel id="hud-prompt-panel" class="hud-card hud-prompt-card">
          <Label id="hud-prompt" class="hud-prompt" text=""/>
          <ProgressBar id="hud-pick" class="hud-pick" value="0"/>
        </Panel>
      </Panel>
      <Panel class="hud-row">
        <Panel id="hud-controls" class="controls hud-controls">
          <Panel class="controls-row"><Label class="controls-action" text=""/><Label class="controls-key controls-head" text="Keyboard"/><Label class="controls-pad controls-head" text="Gamepad"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Move"/><Label class="controls-key" text="W A S D"/><Label class="controls-pad" text="Left stick"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Sneak: slow and silent"/><Label class="controls-key" text="C"/><Label class="controls-pad" text="B"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Run: fast and loud"/><Label class="controls-key" text="Left Shift"/><Label class="controls-pad" text="Left stick press"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Use: open, put out, hold to pick a lock"/><Label class="controls-key" text="F"/><Label class="controls-pad" text="A"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Throw a pebble"/><Label class="controls-key" text="G"/><Label class="controls-pad" text="X"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Turn the view"/><Label class="controls-key" text="Q / E"/><Label class="controls-pad" text="LB / RB"/></Panel>
          <Panel class="controls-row"><Label class="controls-action" text="Pause"/><Label class="controls-key" text="Escape"/><Label class="controls-pad" text="Start"/></Panel>
        </Panel>
      </Panel>
      <Panel class="hud-meter-row">
        <Panel class="hud-card hud-meter">
          <Label id="hud-light-label" class="hud-light-label" text="Hidden"/>
          <ProgressBar id="hud-light" class="hud-light" value="0"/>
        </Panel>
      </Panel>
    </Panel>
  </Panel>
</Screen>
