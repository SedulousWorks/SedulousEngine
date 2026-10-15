<screen mode="modal" transition="fade" default-focus="play-btn">

  <!-- The title (Masquerade.as): a map to choose (the best round on each), then play it alone, host it
       on the network, or join a host at an address on the same map; or quit. -->
  <Flex direction="vertical" justify="center" align="center" padding="32">
    <Panel padding="28" style="background: rounded-rect(#120814E8, radius=16);">
      <Flex direction="vertical" align="center" spacing="6" width="600">
        <Label text="Masquerade" font-size="62" style="text-color: #F4D080;"/>
        <Label text="Find your mark among the masks, before your hunter finds you" font-size="19" style="text-color: #C8B090;"/>
        <Spacer spacer-height="10"/>
        <Button id="play-btn" text="The Palace" width="420" height="42" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Label text="A ballroom and a courtyard, four hunters, a hundred and fifty guests" font-size="15" style="text-color: #B8A080;"/>
        <Label id="palace-best" text="" font-size="14" style="text-color: #A89070;"/>
        <Button id="canal-btn" text="The Canal" width="420" height="42" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Label text="A campo on a canal at carnival: quays, bridges, gondolas passing under" font-size="15" style="text-color: #B8A080;"/>
        <Label id="canal-best" text="" font-size="14" style="text-color: #A89070;"/>
        <Button id="gardens-btn" text="The Gardens" width="420" height="42" font-size="22" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Label text="A hedge maze round a fountain, and an orangery where the orchestra plays" font-size="15" style="text-color: #B8A080;"/>
        <Label id="gardens-best" text="" font-size="14" style="text-color: #A89070;"/>
        <Spacer spacer-height="6"/>
        <Label id="map-choice" text="" font-size="17" style="text-color: #F4D080;"/>
        <Flex direction="horizontal" justify="center" spacing="10">
          <Button id="solo-btn" text="Play alone" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
          <Button id="host-btn" text="Host" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        </Flex>
        <Flex direction="horizontal" justify="center" spacing="10">
          <EditText id="address" text="127.0.0.1" placeholder="the host's address" width="200" height="40"/>
          <Button id="join-btn" text="Join" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        </Flex>
        <Label id="net-status" text="" font-size="14" style="text-color: #C8A070;"/>
        <Spacer spacer-height="8"/>
        <Button id="quit-btn" text="Quit" width="200" height="40" font-size="20" style="background: state-list(normal=rounded-rect(#22102A, radius=10, border=#7A5A28, border-width=2), hover=rounded-rect(#30183A, radius=10, border=#E0B860, border-width=3), pressed=rounded-rect(#3E2048, radius=10, border=#F4D080, border-width=4), focused=rounded-rect(#22102A, radius=10, border=#F4D080, border-width=4), disabled=rounded-rect(#140A18, radius=10, border=#3A2A20, border-width=2)); text-color: #F4E6C8;"/>
        <Spacer spacer-height="8"/>
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
