<screen mode="modal" transition="fade" default-focus="resume-btn">

  <!-- The pause menu over a round that holds still (Masquerade.as). -->
  <Flex direction="vertical" justify="center" align="center">
    <Panel padding="24" style="background: rounded-rect(#120814E8, radius=16);">
      <Flex direction="vertical" align="stretch" spacing="10" width="580">
        <Label text="Paused" font-size="36" style="text-color: #F4D080;"/>
        <Button id="resume-btn" text="Resume" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Button id="restart-btn" text="Start the round over" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Button id="title-btn" text="Leave to the title" height="44" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Spacer spacer-height="6"/>
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
      </Flex>
    </Panel>
  </Flex>

</screen>
