(async () => {
  // prijavko — GuestStatusGlyph component set.
  // 3 sizes (small=24 / large=56 / hero=64) × 5 states = 15 variants.
  // UX spec §Custom Components #1.

  const hexToRgb = (hex) => {
    const n = hex.replace("#", "");
    return {
      r: parseInt(n.slice(0, 2), 16) / 255,
      g: parseInt(n.slice(2, 4), 16) / 255,
      b: parseInt(n.slice(4, 6), 16) / 255,
    };
  };

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  // ── JIT: add onSuccess/onError color tokens from UX spec hexes ──────────
  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const colorCol = collections.find((c) => c.name === "color");
  const modeId = colorCol.modes[0].modeId;
  let allVars = await figma.variables.getLocalVariablesAsync();
  const colorByName = new Map(
    allVars.filter((x) => x.variableCollectionId === colorCol.id).map((x) => [x.name, x])
  );
  const ensureColor = (name, hex) => {
    let v = colorByName.get(name);
    if (!v) {
      v = figma.variables.createVariable(name, colorCol, "COLOR");
      v.scopes = ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL", "STROKE_COLOR"];
      colorByName.set(name, v);
    }
    v.setValueForMode(modeId, hexToRgb(hex));
    return v;
  };
  ensureColor("onSuccess", "#003812");
  ensureColor("onError", "#601410");

  // Re-fetch after additions.
  allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  // ── Clear any prior GuestStatusGlyph set ─────────────────────────────────
  for (const node of page.findAll(
    (n) => n.name === "GuestStatusGlyph" || n.name.startsWith("size=")
  )) {
    node.remove();
  }

  await figma.loadFontAsync({ family: "Manrope", style: "Bold" });

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  // State → { bgVar, fgVar, glyph }. queued has no bg (ring only).
  const states = [
    { name: "queued",                bgVar: null,                     fgVar: v["outline"],              glyph: null     }, // ring only
    { name: "sending",               bgVar: v["primaryContainer"],    fgVar: v["onPrimaryContainer"],   glyph: "↑"      },
    { name: "sent",                  bgVar: v["success"],             fgVar: v["onSuccess"],            glyph: "✓"      },
    { name: "failed",                bgVar: v["error"],               fgVar: v["onError"],              glyph: "✗"      },
    { name: "in_flight_unresolved",  bgVar: v["surfaceContainer"],    fgVar: v["onSurfaceVariant"],     glyph: "⋯"      },
  ];

  // Size → { px, fontPx, ringStroke }. Glyph font size is ~45% of container.
  const sizes = [
    { name: "small", px: 24, fontPx: 10, ringStroke: 1.5 },
    { name: "large", px: 56, fontPx: 24, ringStroke: 2.5 },
    { name: "hero",  px: 64, fontPx: 28, ringStroke: 3   },
  ];

  const components = [];
  for (const size of sizes) {
    for (const state of states) {
      const comp = figma.createComponent();
      comp.name = `size=${size.name}, state=${state.name}`;
      comp.resize(size.px, size.px);
      // Circle via corner radius = half.
      comp.cornerRadius = size.px / 2;
      comp.clipsContent = true;

      if (state.bgVar) {
        comp.fills = [boundFill(state.bgVar)];
        comp.strokes = [];
      } else {
        comp.fills = [];
        comp.strokes = [boundFill(state.fgVar)];
        comp.strokeWeight = size.ringStroke;
        comp.strokeAlign = "INSIDE";
      }

      if (state.glyph) {
        const t = figma.createText();
        t.fontName = { family: "Manrope", style: "Bold" };
        t.characters = state.glyph;
        t.fontSize = size.fontPx;
        t.textAlignHorizontal = "CENTER";
        t.textAlignVertical = "CENTER";
        t.fills = [boundFill(state.fgVar)];
        comp.appendChild(t);
        // Center glyph inside circle.
        t.x = (size.px - t.width) / 2;
        t.y = (size.px - t.height) / 2;
      }

      components.push(comp);
    }
  }

  // Combine into variant set.
  const set = figma.combineAsVariants(components, page);
  set.name = "GuestStatusGlyph";
  set.layoutMode = "NONE";

  // Place set below Card (Card y=120, height=120 → start at y=280).
  set.x = 0;
  set.y = 280;

  // Add 16dp padding around variants for readability.
  set.paddingLeft = set.paddingRight = set.paddingTop = set.paddingBottom = 16;
  set.itemSpacing = 16;
  set.counterAxisSpacing = 16;

  return {
    ok: true,
    setId: set.id,
    setName: set.name,
    variantCount: components.length,
    tokensAdded: ["onSuccess", "onError"],
  };
})()
