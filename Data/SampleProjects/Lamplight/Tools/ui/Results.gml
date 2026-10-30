<!-- A level's results (Lamplight.as fills them): how long, what was taken, how often seen and
     caught, the ghost medal for never being seen, and the best on this level. Styled by
     LamplightSheet.css. Back (Escape, East) is the game's own
     Pause action (Lamplight.as), not the screen stack's. -->
<Screen class="fades" nav-default="next-btn" back="none">
  <Panel class="centre">
    <Panel class="card results-card">
      <Label id="res-title" class="res-title" text="Away clean"/>
      <Label id="res-time" class="res-line" text=""/>
      <Label id="res-loot" class="res-line" text=""/>
      <Label id="res-seen" class="res-line" text=""/>
      <Label id="res-medal" class="res-medal" text=""/>
      <Label id="res-best" class="res-best" text=""/>
      <Button id="next-btn" class="amber first" text="On to the next"/>
      <Button id="again-btn" class="amber" text="This level again"/>
      <Button id="title-btn" class="amber" text="To the title"/>
    </Panel>
  </Panel>
</Screen>
