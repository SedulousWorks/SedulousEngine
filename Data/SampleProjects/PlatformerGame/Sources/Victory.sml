<screen mode="modal" transition="fade" default-focus="victory-title-btn">

  <Panel class="veil-heavy">
  <Flex direction="vertical" justify="center" align="center" padding="32">

    <Panel padding="40" class="cloud-gold">
      <Flex direction="vertical" align="center" spacing="8">
        <Label id="victory-title" font-family="Lilita One" text="You Win!" font-size="56" class="headline-gold"/>
        <Label id="victory-summary" text="" font-size="18" class="body"/>
        <Flex direction="horizontal" align="center" spacing="8">
          <Label text="Final score" font-size="20" class="tally-name"/>
          <Label id="victory-score" text="0" font-family="Lilita One" font-size="40" class="tally-total"/>
        </Flex>
        <Flex direction="horizontal" align="center" spacing="8">
          <Panel class="icon-star" width="28" height="28"/>
          <Label id="victory-stars" text="0 / 15" font-family="Lilita One" font-size="24" class="tally-value"/>
        </Flex>
        <Label id="victory-best" text="" font-family="Lilita One" font-size="20" class="best"/>
        <Spacer spacer-height="24"/>
        <Flex direction="vertical" spacing="8" width="260">
          <Button id="victory-title-btn" text="Back to Title" height="46" class="primary"/>
        </Flex>
      </Flex>
    </Panel>

  </Flex>
  </Panel>

</screen>
