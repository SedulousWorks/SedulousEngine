<screen mode="overlay">

  <Flex direction="vertical" justify="space-between" align="stretch" padding="18" spacing="10">

    <!-- The top: whom you hunt (their costume, which guests share) and your points; a word in the
         middle for a moment (a tag, a miss, a flare); the time left and your place. Masquerade.as
         fills it from the round (Ball.as). -->
    <Flex direction="horizontal" justify="space-between" align="start">
      <Panel padding="10" style="background: rounded-rect(#120814C0, radius=10);">
        <Flex direction="vertical" align="start" spacing="2">
          <Label id="hud-target" text="" font-size="20" style="text-color: #F4E6C8;"/>
          <Label id="hud-score" text="" font-size="18" style="text-color: #E0D0B0;"/>
        </Flex>
      </Panel>
      <Label id="hud-note" text="" font-size="28" visibility="hidden" style="text-color: #F4D080;"/>
      <Panel padding="10" style="background: rounded-rect(#120814C0, radius=10);">
        <Flex direction="vertical" align="end" spacing="2">
          <Label id="hud-time" text="4:00" font-size="22" style="text-color: #F4E6C8;"/>
          <Label id="hud-rank" text="" font-size="16" style="text-color: #E0D0B0;"/>
        </Flex>
      </Panel>
    </Flex>

    <!-- The controls, for a few seconds as a round starts (Masquerade.as). -->
    <Flex direction="horizontal" justify="center">
      <Panel id="hud-controls" padding="14" visibility="hidden" style="background: rounded-rect(#120814C8, radius=12);">
        <Flex direction="vertical" align="center" spacing="4">
          <Flex direction="horizontal" align="center" width="560">
            <Label text="" width="300"/>
            <Label text="Keyboard" width="120" font-size="13" style="text-color: #B09878;"/>
            <Label text="Gamepad" width="140" font-size="13" style="text-color: #B09878;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Move" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="W A S D" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Left stick" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Sprint: fast, and your hunter sees it" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="Left Shift" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Left stick press" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Tag the guest in front of you" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="F" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="A" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Dance (hold)" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="Space" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="B" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Turn the view" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="Q / E" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="LB / RB" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="560">
            <Label text="Pause" width="300" font-size="15" style="text-color: #E0D0B0;"/>
            <Label text="Escape" width="120" font-size="16" style="text-color: #FFFFFF;"/>
            <Label text="Start" width="140" font-size="16" style="text-color: #F4D080;"/>
          </Flex>
        </Flex>
      </Panel>
    </Flex>

  </Flex>

</screen>
