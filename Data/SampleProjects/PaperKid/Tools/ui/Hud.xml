<!-- The HUD (PaperKidGame.as and Level.as fill it): a folded strip of paper top left with the time,
     the deliveries, the papers, the score and the lives; the minimap top right (the Minimap render
     texture the block's top-down camera draws) with markers over it that MapMarkers.as places from
     world positions; a delivery's points rising from under the score, and a cleared block's banner
     dropping in, both over the street. Over the block, taking none of its input. Styled by
     PaperKidSheet.css. Back (Escape, East) is the game's own Pause
     action (PaperKidGame.as), not the screen stack's. -->
<Screen blocks="false" back="none">
  <Panel class="hud-screen">
    <Panel class="hud stats">
      <Panel class="stat"><Label class="hud-caption" text="TIME"/><Label id="hud-time" class="hud-alert" text="0"/></Panel>
      <Panel class="stat"><Label class="hud-caption" text="DELIVERED"/><Label id="hud-deliveries" class="hud-value" text="0 / 0"/></Panel>
      <Panel class="stat"><Label class="hud-caption" text="PAPERS"/><Label id="hud-papers" class="hud-value" text="0"/></Panel>
      <Panel class="stat"><Label class="hud-caption" text="SCORE"/><Label id="hud-score" class="hud-value" text="0"/></Panel>
      <Panel class="stat"><Label class="hud-caption" text="LIVES"/><Label id="hud-lives" class="hud-alert" text="3"/></Panel>
    </Panel>
    <Panel class="hud map-card">
      <Panel id="map" class="map">
        <Image id="map-image" class="map-image" src="{{Minimap}}"/>
        <Panel id="map-sub-0" class="map-dot"/>
        <Panel id="map-sub-1" class="map-dot"/>
        <Panel id="map-sub-2" class="map-dot"/>
        <Panel id="map-sub-3" class="map-dot"/>
        <Panel id="map-sub-4" class="map-dot"/>
        <Panel id="map-sub-5" class="map-dot"/>
        <Panel id="map-sub-6" class="map-dot"/>
        <Panel id="map-sub-7" class="map-dot"/>
        <!-- The bike: a long body with a white nose, turned to its heading. -->
        <Panel id="map-bike" class="map-bike"><Panel class="map-bike-nose"/></Panel>
      </Panel>
    </Panel>
    <!-- A delivery's points (PaperKidGame.as moves it from under the score). -->
    <Label id="hud-pop" class="over-scene hud-pop" text="+100"/>
    <!-- A cleared block's banner, in the middle of the street. -->
    <Panel class="banner-layer"><Label id="hud-banner" class="over-scene hud-banner" text="Block cleared!"/></Panel>
  </Panel>
</Screen>
