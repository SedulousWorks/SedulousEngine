<!-- The results of a run (Snowline.as fills it): the rows come in one at a time, then the final
     time beside the disc of the medal it earned, then the score. Jump skips to the end, then rides
     again. Over the course, which shows around it. Styled by SnowlineSheet.css. Back (Escape, East) is the game's own
     Pause action (Snowline.as), not the screen stack's. -->
<Screen blocks="false" back="none">
  <Panel class="centre">
    <Panel class="card finish-card">
      <Label class="finish-title" text="Finish"/>
      <Panel id="row-ride" class="tally-row"><Label class="tally-name mist" text="Ride"/><Label id="value-ride" class="tally-value" text=""/></Panel>
      <Panel id="row-gates" class="tally-row"><Label class="tally-name mist" text="Gates"/><Label id="value-gates" class="tally-value" text=""/></Panel>
      <Panel id="row-gems" class="tally-row"><Label class="tally-name ice" text="Gems"/><Label id="value-gems" class="tally-value" text=""/></Panel>
      <Panel id="row-tricks" class="tally-row"><Label class="tally-name sun" text="Tricks"/><Label id="value-tricks" class="tally-value" text=""/></Panel>
      <Panel id="row-bonus" class="tally-row"><Label class="tally-name mist" text="Time bonus"/><Label id="value-bonus" class="tally-value" text=""/></Panel>
      <Panel class="rule" width="380"/>
      <Panel class="final">
        <Panel id="medal" class="medal large"/>
        <Panel class="final-text">
          <Label id="final-time" class="final-time" text=""/>
          <Label id="final-medal" class="final-medal" text=""/>
        </Panel>
      </Panel>
      <Panel id="row-score" class="tally-row"><Label class="score-name" text="Score"/><Label id="final-score" class="final-score" text=""/></Panel>
      <Label id="final-best" class="final-best" text=""/>
      <Label id="final-prompt" class="final-prompt" text="Jump to skip"/>
    </Panel>
  </Panel>
</Screen>
