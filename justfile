set shell := ["bash", "-cu"]

debug scenario="initial":
    swift build --product SlopadDebugApp
    .build/debug/SlopadDebugApp --scenario "{{scenario}}"
