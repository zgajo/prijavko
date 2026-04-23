(async () => {
  // Three targeted fixes:
  // 1. FacilityPickerSheet main component: title → "Za ovu sesiju", 🏠 icon on rows
  // 2. Welcome screen: bullets 1/2/3 → 📷/🔒/⚡ + refine text per HTML mockup
  // 3. Facility Picker screen: add AppBar with "Odaberi objekt" + ✕ close

  for (const f of ["Regular", "Medium", "SemiBold", "Bold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));
  const styles = await figma.getLocalTextStylesAsync();
  const S = Object.fromEntries(styles.map((s) => [s.name, s]));

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  const results = [];

  // ════════════════════════════════════════════════════════════════════════
  // 1. FacilityPickerSheet: title + row icons
  // ════════════════════════════════════════════════════════════════════════
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const sheet = pageC.findOne(
      (n) => n.type === "COMPONENT" && n.name === "FacilityPickerSheet"
    );
    if (sheet) {
      // Fix title
      const titleNode = sheet.findOne(
        (n) => n.type === "TEXT" && n.characters === "Odaberi objekt"
      );
      if (titleNode) {
        await figma.loadFontAsync(titleNode.fontName);
        titleNode.characters = "Za ovu sesiju";
      }

      // Identify facility rows — they're FRAME children of the sheet with names
      // matching "Villa Primorje" / "Apartman Mare" / "Vila Ana".
      const rowNames = ["Villa Primorje", "Apartman Mare", "Vila Ana"];
      for (const row of sheet.children) {
        if (row.type !== "FRAME" || !rowNames.includes(row.name)) continue;

        // If an icon is already there (idempotent), skip.
        const alreadyIconed = row.children[0] && row.children[0].name === "facility-icon";
        if (alreadyIconed) continue;

        const icon = figma.createFrame();
        icon.name = "facility-icon";
        icon.resize(32, 32);
        icon.cornerRadius = 8;
        icon.layoutMode = "HORIZONTAL";
        icon.primaryAxisSizingMode = "FIXED";
        icon.counterAxisSizingMode = "FIXED";
        icon.primaryAxisAlignItems = "CENTER";
        icon.counterAxisAlignItems = "CENTER";
        icon.fills = [boundFill(v["primaryContainer"])];

        const glyph = figma.createText();
        glyph.fontName = { family: "Manrope", style: "Regular" };
        glyph.characters = "🏠";
        glyph.fontSize = 16;
        icon.appendChild(glyph);

        // Insert as first child of the row (before the column).
        row.insertChild(0, icon);
      }
      results.push("FacilityPickerSheet: title + 3 house icons");
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 2. Welcome screen bullets → emoji
  // ════════════════════════════════════════════════════════════════════════
  {
    const pageS = figma.root.children.find((p) => p.name === "Screens");
    await figma.setCurrentPageAsync(pageS);
    const welcome = pageS.findOne((n) => n.name === "01 Welcome");
    if (welcome) {
      // Replace bullet dot chars "1" → 📷, "2" → 🔒, "3" → ⚡
      const map = { "1": "📷", "2": "🔒", "3": "⚡" };
      const allTexts = welcome.findAll((n) => n.type === "TEXT");
      for (const t of allTexts) {
        if (map[t.characters]) {
          await figma.loadFontAsync(t.fontName);
          t.characters = map[t.characters];
          t.fontSize = 16; // emoji renders better at slightly bigger
        }
      }
      // Refine bullet body text to match HTML mockup (subtle edits).
      const textEdits = [
        [
          "Skeniraš putovnicu, čuva se šifrirano na uređaju.",
          "Skeniraš putovnicu, čuva se šifrirano.",
        ],
        [
          "Ne gubimo prijavu. Ne šutimo pri grešci.",
          "Ne gubi prijavu. Ne šuti pri grešci.",
        ],
      ];
      for (const [oldT, newT] of textEdits) {
        const n = allTexts.find((x) => x.characters === oldT);
        if (n) {
          await figma.loadFontAsync(n.fontName);
          n.characters = newT;
        }
      }
      results.push("Welcome: 📷 🔒 ⚡ icons + text polish");
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // 3. Facility Picker screen: add AppBar with Odaberi objekt + ✕
  // ════════════════════════════════════════════════════════════════════════
  {
    const pageS = figma.root.children.find((p) => p.name === "Screens");
    await figma.setCurrentPageAsync(pageS);
    const screen = pageS.findOne((n) => n.name === "03 Facility Picker");
    if (screen) {
      // Check if AppBar already added (idempotent).
      const existingAppBar = screen.findOne(
        (n) => n.type === "FRAME" && n.name === "appbar"
      );
      if (!existingAppBar) {
        const W = 360;
        const SB_H = 28;
        const AB_H = 56;

        // Build AppBar inline (screen uses layoutMode=NONE with manual positioning).
        const bar = figma.createFrame();
        bar.name = "appbar";
        bar.layoutMode = "HORIZONTAL";
        bar.resize(W, AB_H);
        bar.primaryAxisSizingMode = "FIXED";
        bar.counterAxisSizingMode = "FIXED";
        bar.primaryAxisAlignItems = "CENTER";
        bar.counterAxisAlignItems = "CENTER";
        bar.paddingLeft = 16;
        bar.paddingRight = 16;
        bar.itemSpacing = 12;
        bar.fills = [boundFill(v["surface"])];
        bar.strokes = [boundFill(v["outlineVariant"])];
        bar.strokeWeight = 1;
        bar.strokeAlign = "INSIDE";
        bar.strokeTopWeight = 0;
        bar.strokeLeftWeight = 0;
        bar.strokeRightWeight = 0;
        bar.strokeBottomWeight = 1;

        const title = figma.createText();
        await title.setTextStyleIdAsync(S["title/Medium"].id);
        title.characters = "Odaberi objekt";
        title.fills = [boundFill(v["onSurface"])];
        bar.appendChild(title);
        title.layoutSizingHorizontal = "FILL";

        const closeBtn = figma.createFrame();
        closeBtn.resize(36, 36);
        closeBtn.cornerRadius = 18;
        closeBtn.layoutMode = "HORIZONTAL";
        closeBtn.primaryAxisSizingMode = "FIXED";
        closeBtn.counterAxisSizingMode = "FIXED";
        closeBtn.primaryAxisAlignItems = "CENTER";
        closeBtn.counterAxisAlignItems = "CENTER";
        closeBtn.fills = [];
        const closeText = figma.createText();
        closeText.fontName = { family: "Manrope", style: "Bold" };
        closeText.characters = "×";
        closeText.fontSize = 22;
        closeText.fills = [boundFill(v["onSurface"])];
        closeBtn.appendChild(closeText);
        bar.appendChild(closeBtn);

        screen.appendChild(bar);
        bar.x = 0;
        bar.y = SB_H;

        // Ensure the dimmed backdrop still covers below the AppBar.
        // (Backdrop is at (0,0) w=360 h=800 — it also covers the AppBar area.
        // That's fine; AppBar fills surface on top. Move AppBar below dim to
        // ensure it's VISIBLE — actually AppBar was appended last so it's
        // above everything including the sheet. Reorder: AppBar should be
        // above dim but below the sheet. Push it behind the sheet.)
        // The sheet is at y=H-sheet.height, which is well below AppBar — no
        // z-order conflict. AppBar at y=SB_H=28 renders above dim (good).
      }

      results.push("Facility Picker: AppBar with Odaberi objekt + ×");
    }
  }

  return { ok: true, results };
})()
