<!-- The HUD (PlatformerGame.as fills it): lives and coins top left (the gem beside them once
     found), the level and its clock in the middle, the score top right with the gains that float
     up under it. Over the level, taking none of its input. Styled by SkyHopperSheet.css. Back
     (Escape, East) is the game's own Pause action, not the screen stack's. -->
<Screen blocks="false" back="none">
  <Panel class="hud-screen">
    <!-- Lives and coins: the run's stakes, each an icon and a count. -->
    <Panel class="hud hud-row">
      <Image id="hud-heart" class="icon icon-30" src="{d44e698e-ec68-d744-93e0-a8f8a73f5a8f}"/>
      <Label id="hud-lives" class="hud-value lilita hud-number" text="x 3"/>
      <Image id="hud-coin" class="icon icon-28 hud-gap" src="{f56cf7af-ed10-1043-b18c-4e5fea416978}"/>
      <Label id="hud-coins" class="hud-coins lilita hud-number" text="0 / 0"/>
      <Image id="hud-gem" class="icon icon-26 hud-gem" src="{8865d430-daf0-244d-8aec-9be7763901dc}"/>
    </Panel>
    <!-- The level and its clock. -->
    <Panel class="hud hud-row">
      <Label id="hud-level" class="hud-level" text="1  Grassy Hills"/>
      <Image class="icon icon-24 hud-gap" src="{49e807a1-2ebe-244b-96b8-4eb121159eff}"/>
      <Label id="hud-time" class="hud-value lilita hud-clock" text="0:00"/>
    </Panel>
    <!-- The score, and the gains that float up from it. -->
    <Panel class="hud-right">
      <Panel class="hud hud-score-card">
        <Label id="hud-score" class="hud-score lilita" text="0"/>
      </Panel>
      <Label id="hud-popup" class="popup lilita" text="+100"/>
      <Label id="hud-life-popup" class="popup-life lilita" text="1UP"/>
    </Panel>
  </Panel>
</Screen>
