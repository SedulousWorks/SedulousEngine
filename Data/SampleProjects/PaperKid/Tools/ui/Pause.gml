<!-- The pause menu over a block that holds still (PaperKidGame.as). Styled by PaperKidSheet.css.
     Back (Escape, East) is the game's own Pause
     action (PaperKidGame.as), not the screen stack's. -->
<Screen class="fades" nav-default="resume-btn" back="none">
  <Panel class="dim">
    <Panel class="card result-card">
      <Label id="pause-title" class="headline slab" text="Paused"/>
      <Panel class="menu pause-menu">
        <Button id="resume-btn" class="primary" text="Resume"/>
        <Button id="restart-btn" text="Restart block"/>
        <Button id="settings-btn" text="Settings"/>
        <Button id="menu-btn" text="Quit to menu"/>
      </Panel>
    </Panel>
  </Panel>
</Screen>
