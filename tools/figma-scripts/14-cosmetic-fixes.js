(async () => {
  // Cosmetic fixes:
  // 1. TextField: input text was top-aligned — set counterAxisAlignItems=CENTER on field frames
  // 2. ✗ (U+2717) → × (U+00D7) in GuestStatusGlyph failed variants (propagates to QueueRow)
  // 3. ListTile leading glyph "⚙" → simple filled-dot placeholder (cleaner than unicode glyph)
  // 4. Foundations specimen display/Large clipped — widen type rows to 1400px

  const results = { fixed: [] };

  // ── 1. TextField vertical centering ──────────────────────────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const tfSet = pageC.findOne((n) => n.type === "COMPONENT_SET" && n.name === "TextField");
    if (tfSet) {
      for (const variant of tfSet.children) {
        // Each variant is a COMPONENT with children: [label, field, (helper?)]
        for (const child of variant.children) {
          // The field is the one with layoutMode HORIZONTAL
          if (child.type === "FRAME" && child.layoutMode === "HORIZONTAL") {
            child.counterAxisAlignItems = "CENTER";
          }
        }
      }
      results.fixed.push("TextField vertical centering");
    }
  }

  // ── 2. Failed-glyph character swap ───────────────────────────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    await figma.loadFontAsync({ family: "Manrope", style: "Bold" });
    const glyphSet = pageC.findOne(
      (n) => n.type === "COMPONENT_SET" && n.name === "GuestStatusGlyph"
    );
    if (glyphSet) {
      for (const variant of glyphSet.children) {
        if (variant.name.includes("state=failed")) {
          const txt = variant.findOne((n) => n.type === "TEXT");
          if (txt && txt.characters === "✗") {
            txt.characters = "×";
            // Re-center after character change.
            txt.x = (variant.width - txt.width) / 2;
            txt.y = (variant.height - txt.height) / 2;
          }
        }
      }
      results.fixed.push("Failed glyph ✗ → ×");
    }
  }

  // ── 3. ListTile leading — replace ⚙ text with plain dot ──────────────────
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const tile = pageC.findOne((n) => n.type === "COMPONENT" && n.name === "ListTile");
    if (tile) {
      const leading = tile.children[0];
      if (leading) {
        // Clear existing text child
        for (const ch of [...leading.children]) ch.remove();
        // Add a small filled dot as icon placeholder.
        const allVars = await figma.variables.getLocalVariablesAsync();
        const v = Object.fromEntries(allVars.map((x) => [x.name, x]));
        const boundFill = (variable) =>
          figma.variables.setBoundVariableForPaint(
            { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
            "color",
            variable
          );
        const dot = figma.createFrame();
        dot.resize(16, 16);
        dot.cornerRadius = 8;
        dot.fills = [boundFill(v["onPrimaryContainer"])];
        leading.appendChild(dot);
      }
      results.fixed.push("ListTile leading ⚙ → dot placeholder");
    }
  }

  // ── 4. Foundations specimen display/Large clip — widen type rows ─────────
  {
    const pageF = figma.root.children.find((p) => p.name !== "Components");
    await figma.setCurrentPageAsync(pageF);
    const spec = pageF.findOne((n) => n.name === "Foundations · prijavko");
    if (spec) {
      const typeSection = spec.findOne((n) => n.name === "Type scale (Manrope)");
      if (typeSection) {
        for (const row of typeSection.children) {
          if (row.type === "FRAME" && row.layoutMode === "HORIZONTAL") {
            row.resize(1400, row.height);
          }
        }
      }
      results.fixed.push("Specimen display/Large row width 900 → 1400");
    }
  }

  return { ok: true, ...results };
})()
