<screen mode="overlay">

  <Flex direction="vertical" justify="space-between" align="stretch">

    <Flex direction="horizontal" justify="space-between" align="start" padding="18">

      <!-- The clock (penalties included), the flash of a missed gate's penalty, the avalanche. -->
      <Flex direction="vertical" align="start" spacing="4">
        <Panel padding="10" style="background: rounded-rect(#10182AB0, radius=10);">
          <Label id="hud-time" text="0:00.00" font-size="30" style="text-color: #FFFFFF;"/>
        </Panel>
        <Label id="hud-penalty" text="+2 s" font-size="24" style="text-color: #FF5A4A;" visibility="hidden"/>
        <!-- How far behind the avalanche is, from the moment it breaks loose (Ridge). -->
        <Panel id="hud-avalanche-panel" padding="10" visibility="hidden" style="background: rounded-rect(#5A1A1AC0, radius=10);">
          <Flex direction="horizontal" align="center" spacing="8">
            <Label text="Avalanche" font-size="18" style="text-color: #FFC8C0;"/>
            <Label id="hud-avalanche" text="" font-size="26" style="text-color: #FFFFFF;"/>
          </Flex>
        </Panel>
      </Flex>

      <!-- A landed trick, named with its points, for a moment; under it the combo, while there is one. -->
      <Flex direction="vertical" align="center" spacing="2">
        <Label id="hud-trick" text="" font-size="30" style="text-color: #FFE38A;" visibility="hidden"/>
        <Label id="hud-combo" text="" font-size="22" style="text-color: #FFFFFF;" visibility="hidden"/>
      </Flex>

      <!-- Gates passed of the course's, and gems taken of its gems. -->
      <Flex direction="vertical" align="end" spacing="8">
        <Panel padding="10" style="background: rounded-rect(#10182AB0, radius=10);">
          <Flex direction="horizontal" align="center" spacing="8">
            <Label text="Gates" font-size="18" style="text-color: #B8C8E8;"/>
            <Label id="hud-gates" text="0 / 0" font-size="26" style="text-color: #FFFFFF;"/>
          </Flex>
        </Panel>
        <Panel padding="10" style="background: rounded-rect(#10182AB0, radius=10);">
          <Flex direction="horizontal" align="center" spacing="8">
            <Label text="Gems" font-size="18" style="text-color: #7FDFFF;"/>
            <Label id="hud-gems" text="0 / 0" font-size="26" style="text-color: #FFFFFF;"/>
          </Flex>
        </Panel>
      </Flex>

    </Flex>

    <!-- The controls, keyboard and pad, for a few seconds as a run starts (Snowline.as). -->
    <Flex direction="horizontal" justify="center" padding="18">
      <Panel id="hud-controls" padding="14" visibility="hidden" style="background: rounded-rect(#10182AC8, radius=12);">
        <Flex direction="vertical" align="center" spacing="4">
          <Flex direction="horizontal" align="center" width="480">
            <Label text="" width="240"/>
            <Label text="Keyboard" width="120" font-size="13" style="text-color: #8FA3C8;"/>
            <Label text="Gamepad" width="120" font-size="13" style="text-color: #8FA3C8;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Carve, and spin in the air" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="A / D" width="120" font-size="17" style="text-color: #FFFFFF;"/>
            <Label text="Left stick" width="120" font-size="17" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Jump" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Space" width="120" font-size="17" style="text-color: #FFFFFF;"/>
            <Label text="A" width="120" font-size="17" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Tuck" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Left Shift" width="120" font-size="17" style="text-color: #FFFFFF;"/>
            <Label text="X or RB" width="120" font-size="17" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Grab, in the air" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="E" width="120" font-size="17" style="text-color: #FFFFFF;"/>
            <Label text="B" width="120" font-size="17" style="text-color: #FFE38A;"/>
          </Flex>
          <Flex direction="horizontal" align="center" width="480">
            <Label text="Pause" width="240" font-size="15" style="text-color: #B8C8E8;"/>
            <Label text="Escape" width="120" font-size="17" style="text-color: #FFFFFF;"/>
            <Label text="Start" width="120" font-size="17" style="text-color: #FFE38A;"/>
          </Flex>
        </Flex>
      </Panel>
    </Flex>

  </Flex>

</screen>
