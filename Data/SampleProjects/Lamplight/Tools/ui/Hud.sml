<screen mode="overlay">

  <Flex direction="vertical" justify="space-between" align="stretch" padding="18" spacing="10">

    <!-- The top: the level's target and what has been taken (Lamplight.as), and a word for a
         moment in the middle (a checkpoint reached, the exit with nothing to show). -->
    <Flex direction="horizontal" justify="space-between" align="start">
      <Panel padding="10" style="background: rounded-rect(#0A0E18C0, radius=10);">
        <Flex direction="vertical" align="start" spacing="2">
          <Label id="hud-target" text="" font-size="20" style="text-color: #F0E0C0;"/>
          <Label id="hud-loot" text="" font-size="18" style="text-color: #D8C8A8;"/>
        </Flex>
      </Panel>
      <Label id="hud-note" text="Checkpoint" font-size="28" visibility="hidden" style="text-color: #F0E0C0;"/>
      <Panel padding="10" style="background: rounded-rect(#0A0E18C0, radius=10);">
        <Label id="hud-time" text="0:00" font-size="22" style="text-color: #F0E0C0;"/>
      </Panel>
    </Flex>

    <Flex direction="vertical" justify="end" align="stretch" spacing="10">

      <!-- What the thief can do here (put out a lamp, pick a lock), set by whatever is in reach. -->
      <Flex direction="horizontal" justify="center">
        <Panel id="hud-prompt-panel" padding="10" visibility="hidden" style="background: rounded-rect(#0A0E18C0, radius=10);">
          <Flex direction="vertical" align="center" spacing="6">
            <Label id="hud-prompt" text="" font-size="22" style="text-color: #F0E0C0;"/>
            <ProgressBar id="hud-pick" value="0" width="220" height="8" visibility="hidden"/>
          </Flex>
        </Panel>
      </Flex>

      <!-- The controls, keyboard and pad, for a few seconds as a level starts (Lamplight.as). -->
      <Flex direction="horizontal" justify="center">
        <Panel id="hud-controls" padding="14" visibility="hidden" style="background: rounded-rect(#0A0E18C8, radius=12);">
          <Flex direction="vertical" align="center" spacing="4">
            <Flex direction="horizontal" align="center" width="560">
              <Label text="" width="300"/>
              <Label text="Keyboard" width="120" font-size="13" style="text-color: #A89878;"/>
              <Label text="Gamepad" width="140" font-size="13" style="text-color: #A89878;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Move" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="W A S D" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="Left stick" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Sneak: slow and silent" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="C" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="B" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Run: fast and loud" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="Left Shift" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="Left stick press" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Use: open, put out, hold to pick a lock" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="F" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="A" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Throw a pebble" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="G" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="X" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Turn the view" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="Q / E" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="LB / RB" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
            <Flex direction="horizontal" align="center" width="560">
              <Label text="Pause" width="300" font-size="15" style="text-color: #D8C8A8;"/>
              <Label text="Escape" width="120" font-size="17" style="text-color: #FFFFFF;"/>
              <Label text="Start" width="140" font-size="17" style="text-color: #F0C070;"/>
            </Flex>
          </Flex>
        </Panel>
      </Flex>

      <!-- The light meter, bottom left: how lit the thief is, the one thing to read before moving. -->
      <Flex direction="horizontal" justify="start">
        <Panel padding="12" style="background: rounded-rect(#0A0E18C0, radius=10);">
          <Flex direction="vertical" align="start" spacing="6" width="240">
            <Label id="hud-light-label" text="Hidden" font-size="20" style="text-color: #D8C8A8;"/>
            <ProgressBar id="hud-light" value="0" width="240" height="12"/>
          </Flex>
        </Panel>
      </Flex>

    </Flex>
  </Flex>

</screen>
