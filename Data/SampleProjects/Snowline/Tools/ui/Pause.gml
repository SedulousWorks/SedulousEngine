<!-- The pause menu (Snowline.as): the run holds still under it. Escape, Start or B resumes. Styled
     by SnowlineSheet.css. Back (Escape, East) is the game's own
     Pause action (Snowline.as), not the screen stack's. -->
<Screen class="fades" nav-default="resume-btn" back="none">
  <Panel class="centre">
    <Panel class="card pause-card">
      <Label class="pause-title" text="Paused"/>
      <Button id="resume-btn" class="slate wide" text="Resume"/>
      <Button id="restart-btn" class="slate wide" text="Restart run"/>
      <Button id="courses-btn" class="slate wide" text="Courses"/>
      <Panel class="controls pause-controls">
        <Panel class="controls-row"><Label class="controls-action" text=""/><Label class="controls-key controls-head" text="Keyboard"/><Label class="controls-pad controls-head" text="Gamepad"/></Panel>
        <Panel class="controls-row"><Label class="controls-action" text="Carve, and spin in the air"/><Label class="controls-key" text="A / D"/><Label class="controls-pad" text="Left stick"/></Panel>
        <Panel class="controls-row"><Label class="controls-action" text="Jump"/><Label class="controls-key" text="Space"/><Label class="controls-pad" text="A"/></Panel>
        <Panel class="controls-row"><Label class="controls-action" text="Tuck"/><Label class="controls-key" text="Left Shift"/><Label class="controls-pad" text="X or RB"/></Panel>
        <Panel class="controls-row"><Label class="controls-action" text="Grab, in the air"/><Label class="controls-key" text="E"/><Label class="controls-pad" text="B"/></Panel>
        <Panel class="controls-row"><Label class="controls-action" text="Pause"/><Label class="controls-key" text="Escape"/><Label class="controls-pad" text="Start"/></Panel>
      </Panel>
      <Label class="pause-hint" text="Escape, Start or B to ride on"/>
    </Panel>
  </Panel>
</Screen>
