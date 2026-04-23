(async () => {
  // prijavko — remaining custom components: CaptureConfirmation, ClosureSummary,
  // FacilityPickerSheet, MRZViewfinder, TypedConfirmationDialog, AdBanner.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  const fonts = ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold"];
  for (const f of fonts) await figma.loadFontAsync({ family: "Manrope", style: f });

  const styles = await figma.getLocalTextStylesAsync();
  const S = Object.fromEntries(styles.map((s) => [s.name, s]));

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  const removeByName = (name) => {
    for (const n of page.findAll((nd) => nd.name === name)) n.remove();
  };

  const results = [];

  // ════════════════════════════════════════════════════════════════════════
  // 1. CaptureConfirmation — full-bleed 360×600, surface bg
  //    72×72 success circle + check, headlineMedium title, bodyMedium sub.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("CaptureConfirmation");
    const frame = figma.createComponent();
    frame.name = "CaptureConfirmation";
    frame.resize(360, 600);
    frame.layoutMode = "VERTICAL";
    frame.primaryAxisSizingMode = "FIXED";
    frame.counterAxisSizingMode = "FIXED";
    frame.primaryAxisAlignItems = "CENTER";
    frame.counterAxisAlignItems = "CENTER";
    frame.itemSpacing = 24;
    frame.paddingLeft = frame.paddingRight = 32;
    frame.fills = [boundFill(v["surface"])];

    // Push content to vertical center via spacers.
    const topSpacer = figma.createFrame();
    topSpacer.layoutMode = "NONE";
    topSpacer.fills = [];
    topSpacer.resize(1, 1);
    frame.appendChild(topSpacer);
    topSpacer.layoutGrow = 1;

    // 72×72 success circle.
    const circle = figma.createFrame();
    circle.name = "success-circle";
    circle.resize(72, 72);
    circle.cornerRadius = 36;
    circle.fills = [boundFill(v["success"])];
    circle.layoutMode = "HORIZONTAL";
    circle.primaryAxisAlignItems = "CENTER";
    circle.counterAxisAlignItems = "CENTER";
    circle.primaryAxisSizingMode = "FIXED";
    circle.counterAxisSizingMode = "FIXED";
    const check = figma.createText();
    check.fontName = { family: "Manrope", style: "Bold" };
    check.characters = "✓";
    check.fontSize = 40;
    check.fills = [boundFill(v["onSuccess"])];
    circle.appendChild(check);
    frame.appendChild(circle);

    const title = figma.createText();
    await title.setTextStyleIdAsync(S["headline/Medium"].id);
    title.characters = "Gost 3 dodan";
    title.fills = [boundFill(v["onSurface"])];
    title.textAlignHorizontal = "CENTER";
    frame.appendChild(title);

    const sub = figma.createText();
    await sub.setTextStyleIdAsync(S["body/Medium"].id);
    sub.characters = "Skeniram sljedećeg…";
    sub.fills = [boundFill(v["onSurfaceVariant"])];
    sub.textAlignHorizontal = "CENTER";
    frame.appendChild(sub);

    const bottomSpacer = figma.createFrame();
    bottomSpacer.layoutMode = "NONE";
    bottomSpacer.fills = [];
    bottomSpacer.resize(1, 1);
    frame.appendChild(bottomSpacer);
    bottomSpacer.layoutGrow = 1;

    frame.x = 0;
    frame.y = 1500;
    results.push({ name: frame.name, id: frame.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // 2. ClosureSummary — full-bleed 360×800, primaryContainer→surface gradient,
  //    gold count (displayLarge, closureAccent), Share/Done CTAs.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("ClosureSummary");
    const frame = figma.createComponent();
    frame.name = "ClosureSummary";
    frame.resize(360, 800);
    frame.layoutMode = "VERTICAL";
    frame.primaryAxisSizingMode = "FIXED";
    frame.counterAxisSizingMode = "FIXED";
    frame.counterAxisAlignItems = "CENTER";
    frame.paddingLeft = frame.paddingRight = 24;
    frame.paddingTop = 96;
    frame.paddingBottom = 48;
    frame.itemSpacing = 16;

    // Linear gradient top→bottom: primaryContainer (dark teal) → surface (near black).
    // Dark-mode hexes: primaryContainer=#004F52, surface=#0E1515.
    frame.fills = [
      {
        type: "GRADIENT_LINEAR",
        gradientTransform: [
          [0, 1, 0],
          [-1, 0, 1],
        ],
        gradientStops: [
          { position: 0, color: { r: 0x00 / 255, g: 0x4F / 255, b: 0x52 / 255, a: 1 } },
          { position: 0.55, color: { r: 0x0E / 255, g: 0x15 / 255, b: 0x15 / 255, a: 1 } },
        ],
      },
    ];

    // 56×56 success circle
    const circle = figma.createFrame();
    circle.name = "success-circle";
    circle.resize(56, 56);
    circle.cornerRadius = 28;
    circle.fills = [boundFill(v["success"])];
    circle.layoutMode = "HORIZONTAL";
    circle.primaryAxisAlignItems = "CENTER";
    circle.counterAxisAlignItems = "CENTER";
    circle.primaryAxisSizingMode = "FIXED";
    circle.counterAxisSizingMode = "FIXED";
    const check = figma.createText();
    check.fontName = { family: "Manrope", style: "Bold" };
    check.characters = "✓";
    check.fontSize = 32;
    check.fills = [boundFill(v["onSuccess"])];
    circle.appendChild(check);
    frame.appendChild(circle);

    // Big gold count
    const count = figma.createText();
    await count.setTextStyleIdAsync(S["display/Large"].id);
    count.characters = "4";
    count.fills = [boundFill(v["closureAccent"])];
    count.textAlignHorizontal = "CENTER";
    frame.appendChild(count);

    const label = figma.createText();
    await label.setTextStyleIdAsync(S["title/Large"].id);
    label.characters = "gostiju prijavljeno";
    label.fills = [boundFill(v["onSurface"])];
    label.textAlignHorizontal = "CENTER";
    frame.appendChild(label);

    const sub = figma.createText();
    await sub.setTextStyleIdAsync(S["body/Medium"].id);
    sub.characters = "Villa Primorje · 14:32";
    sub.fills = [boundFill(v["onSurfaceVariant"])];
    sub.textAlignHorizontal = "CENTER";
    frame.appendChild(sub);

    const spacer = figma.createFrame();
    spacer.fills = [];
    spacer.resize(1, 1);
    frame.appendChild(spacer);
    spacer.layoutGrow = 1;

    // Share primary button
    const shareBtn = figma.createFrame();
    shareBtn.name = "share";
    shareBtn.layoutMode = "HORIZONTAL";
    shareBtn.primaryAxisAlignItems = "CENTER";
    shareBtn.counterAxisAlignItems = "CENTER";
    shareBtn.primaryAxisSizingMode = "FIXED";
    shareBtn.counterAxisSizingMode = "FIXED";
    shareBtn.resize(312, 56);
    shareBtn.paddingLeft = shareBtn.paddingRight = 24;
    shareBtn.fills = [boundFill(v["primary"])];
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      shareBtn.setBoundVariable(c, v["radius-button"]);
    }
    shareBtn.setBoundVariable("minHeight", v["button-min-height"]);
    const shareText = figma.createText();
    await shareText.setTextStyleIdAsync(S["label/Large"].id);
    shareText.characters = "Podijeli";
    shareText.fills = [boundFill(v["onPrimary"])];
    shareBtn.appendChild(shareText);
    frame.appendChild(shareBtn);

    // Done outlined button
    const doneBtn = figma.createFrame();
    doneBtn.name = "done";
    doneBtn.layoutMode = "HORIZONTAL";
    doneBtn.primaryAxisAlignItems = "CENTER";
    doneBtn.counterAxisAlignItems = "CENTER";
    doneBtn.primaryAxisSizingMode = "FIXED";
    doneBtn.counterAxisSizingMode = "FIXED";
    doneBtn.resize(312, 56);
    doneBtn.paddingLeft = doneBtn.paddingRight = 24;
    doneBtn.fills = [];
    doneBtn.strokes = [boundFill(v["outline"])];
    doneBtn.strokeWeight = 1;
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      doneBtn.setBoundVariable(c, v["radius-button"]);
    }
    doneBtn.setBoundVariable("minHeight", v["button-min-height"]);
    const doneText = figma.createText();
    await doneText.setTextStyleIdAsync(S["label/Large"].id);
    doneText.characters = "Gotovo";
    doneText.fills = [boundFill(v["primary"])];
    doneBtn.appendChild(doneText);
    frame.appendChild(doneBtn);

    frame.x = 400;
    frame.y = 1500;
    results.push({ name: frame.name, id: frame.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // 3. FacilityPickerSheet — 360×420, bottom sheet chrome + rows.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("FacilityPickerSheet");
    const sheet = figma.createComponent();
    sheet.name = "FacilityPickerSheet";
    sheet.resize(360, 420);
    sheet.layoutMode = "VERTICAL";
    sheet.primaryAxisSizingMode = "FIXED";
    sheet.counterAxisSizingMode = "FIXED";
    sheet.counterAxisAlignItems = "CENTER";
    sheet.paddingTop = 12;
    sheet.paddingLeft = sheet.paddingRight = 16;
    sheet.paddingBottom = 24;
    sheet.itemSpacing = 16;
    sheet.fills = [boundFill(v["surface"])];
    // Top radius 20dp, bottom 0.
    sheet.topLeftRadius = 20;
    sheet.topRightRadius = 20;
    sheet.bottomLeftRadius = 0;
    sheet.bottomRightRadius = 0;

    // Handle (32×4 rounded bar)
    const handle = figma.createFrame();
    handle.resize(32, 4);
    handle.cornerRadius = 2;
    handle.fills = [boundFill(v["outline"])];
    sheet.appendChild(handle);

    // Title
    const title = figma.createText();
    await title.setTextStyleIdAsync(S["headline/Small"].id);
    title.characters = "Odaberi objekt";
    title.fills = [boundFill(v["onSurface"])];
    sheet.appendChild(title);
    title.layoutSizingHorizontal = "FILL";

    // Facility rows — last-used first with "Zadnji" pill + primary border.
    const facilities = [
      { name: "Villa Primorje", sub: "Opatija · 4 gosta trenutno",  last: true },
      { name: "Apartman Mare",  sub: "Rovinj · prazno",              last: false },
      { name: "Vila Ana",       sub: "Split · prazno",               last: false },
    ];
    for (const f of facilities) {
      const row = figma.createFrame();
      row.name = f.name;
      row.layoutMode = "HORIZONTAL";
      row.primaryAxisSizingMode = "FIXED";
      row.counterAxisSizingMode = "AUTO";
      row.primaryAxisAlignItems = "CENTER";
      row.counterAxisAlignItems = "CENTER";
      row.resize(328, 64);
      row.paddingLeft = row.paddingRight = 16;
      row.paddingTop = row.paddingBottom = 12;
      row.itemSpacing = 12;
      row.fills = [boundFill(v["surfaceContainer"])];
      for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
        row.setBoundVariable(c, v["radius-card"]);
      }
      if (f.last) {
        row.strokes = [boundFill(v["primary"])];
        row.strokeWeight = 1.5;
      }

      const col = figma.createFrame();
      col.layoutMode = "VERTICAL";
      col.primaryAxisSizingMode = "AUTO";
      col.counterAxisSizingMode = "AUTO";
      col.itemSpacing = 2;
      col.fills = [];
      row.appendChild(col);
      col.layoutSizingHorizontal = "FILL";

      const n = figma.createText();
      await n.setTextStyleIdAsync(S["title/Medium"].id);
      n.characters = f.name;
      n.fills = [boundFill(v["onSurface"])];
      col.appendChild(n);
      n.layoutSizingHorizontal = "FILL";

      const sub = figma.createText();
      await sub.setTextStyleIdAsync(S["body/Small"].id);
      sub.characters = f.sub;
      sub.fills = [boundFill(v["onSurfaceVariant"])];
      col.appendChild(sub);
      sub.layoutSizingHorizontal = "FILL";

      if (f.last) {
        const pill = figma.createFrame();
        pill.layoutMode = "HORIZONTAL";
        pill.primaryAxisSizingMode = "AUTO";
        pill.counterAxisSizingMode = "AUTO";
        pill.primaryAxisAlignItems = "CENTER";
        pill.counterAxisAlignItems = "CENTER";
        pill.paddingLeft = pill.paddingRight = 10;
        pill.paddingTop = pill.paddingBottom = 4;
        pill.cornerRadius = 999;
        pill.fills = [boundFill(v["primaryContainer"])];
        const pillText = figma.createText();
        await pillText.setTextStyleIdAsync(S["label/Medium"].id);
        pillText.characters = "Zadnji";
        pillText.fills = [boundFill(v["onPrimaryContainer"])];
        pill.appendChild(pillText);
        row.appendChild(pill);
      }
      sheet.appendChild(row);
    }

    sheet.x = 830;
    sheet.y = 1500;
    results.push({ name: sheet.name, id: sheet.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // 4. MRZViewfinder — 360×800 scan overlay.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("MRZViewfinder");
    const vf = figma.createComponent();
    vf.name = "MRZViewfinder";
    vf.resize(360, 800);
    vf.fills = [{ type: "SOLID", color: { r: 0.05, g: 0.05, b: 0.05 } }];

    // Reticle: 200×130, rounded 16, stroke.
    const reticle = figma.createFrame();
    reticle.name = "reticle";
    reticle.resize(240, 152);
    reticle.cornerRadius = 16;
    reticle.fills = [];
    reticle.strokes = [boundFill(v["primary"])];
    reticle.strokeWeight = 2;
    reticle.x = (360 - 240) / 2;
    reticle.y = (800 - 152) / 2;
    vf.appendChild(reticle);

    // 4 corner accents — L-shapes in primary.
    const cornerSize = 20;
    const cornerThick = 3;
    const addCorner = (x, y, orient) => {
      const h = figma.createRectangle();
      h.resize(cornerSize, cornerThick);
      h.fills = [boundFill(v["primary"])];
      h.x = orient.includes("E") ? x - cornerSize : x;
      h.y = orient.includes("S") ? y - cornerThick : y;
      vf.appendChild(h);
      const vn = figma.createRectangle();
      vn.resize(cornerThick, cornerSize);
      vn.fills = [boundFill(v["primary"])];
      vn.x = orient.includes("E") ? x - cornerThick : x;
      vn.y = orient.includes("S") ? y - cornerSize : y;
      vf.appendChild(vn);
    };
    addCorner(reticle.x, reticle.y, "NW");
    addCorner(reticle.x + reticle.width, reticle.y, "NE");
    addCorner(reticle.x, reticle.y + reticle.height, "SW");
    addCorner(reticle.x + reticle.width, reticle.y + reticle.height, "SE");

    // Top-left close
    const close = figma.createFrame();
    close.name = "close";
    close.layoutMode = "HORIZONTAL";
    close.primaryAxisAlignItems = "CENTER";
    close.counterAxisAlignItems = "CENTER";
    close.primaryAxisSizingMode = "FIXED";
    close.counterAxisSizingMode = "FIXED";
    close.resize(48, 48);
    close.cornerRadius = 24;
    close.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 }, opacity: 0.08 }];
    const closeText = figma.createText();
    closeText.fontName = { family: "Manrope", style: "Bold" };
    closeText.characters = "×";
    closeText.fontSize = 22;
    closeText.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 } }];
    close.appendChild(closeText);
    close.x = 16;
    close.y = 48;
    vf.appendChild(close);

    // Top-right scan counter chip
    const chip = figma.createFrame();
    chip.name = "counter";
    chip.layoutMode = "HORIZONTAL";
    chip.primaryAxisAlignItems = "CENTER";
    chip.counterAxisAlignItems = "CENTER";
    chip.primaryAxisSizingMode = "AUTO";
    chip.counterAxisSizingMode = "AUTO";
    chip.paddingLeft = chip.paddingRight = 12;
    chip.paddingTop = chip.paddingBottom = 8;
    chip.cornerRadius = 999;
    chip.fills = [boundFill(v["primaryContainer"])];
    const chipText = figma.createText();
    await chipText.setTextStyleIdAsync(S["label/Large"].id);
    chipText.characters = "Gost 3";
    chipText.fills = [boundFill(v["onPrimaryContainer"])];
    chip.appendChild(chipText);
    vf.appendChild(chip);
    chip.x = 360 - chip.width - 16;
    chip.y = 48;

    // Bottom hint
    const hint = figma.createText();
    await hint.setTextStyleIdAsync(S["body/Medium"].id);
    hint.characters = "Drži osobnu ravno u okviru";
    hint.fills = [{ type: "SOLID", color: { r: 1, g: 1, b: 1 }, opacity: 0.85 }];
    hint.textAlignHorizontal = "CENTER";
    vf.appendChild(hint);
    hint.x = (360 - hint.width) / 2;
    hint.y = 800 - 96;

    vf.x = 1260;
    vf.y = 1500;
    results.push({ name: vf.name, id: vf.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // 5. TypedConfirmationDialog — 320×340, AlertDialog shape.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("TypedConfirmationDialog");
    const d = figma.createComponent();
    d.name = "TypedConfirmationDialog";
    d.resize(320, 340);
    d.layoutMode = "VERTICAL";
    d.primaryAxisSizingMode = "AUTO";
    d.counterAxisSizingMode = "FIXED";
    d.paddingLeft = d.paddingRight = d.paddingTop = d.paddingBottom = 24;
    d.itemSpacing = 16;
    d.fills = [boundFill(v["surfaceContainer"])];
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      d.setBoundVariable(c, v["radius-card"]);
    }

    const title = figma.createText();
    await title.setTextStyleIdAsync(S["headline/Small"].id);
    title.characters = "Obriši sve podatke?";
    title.fills = [boundFill(v["onSurface"])];
    d.appendChild(title);
    title.layoutSizingHorizontal = "FILL";

    const desc = figma.createText();
    await desc.setTextStyleIdAsync(S["body/Medium"].id);
    desc.characters =
      "Ovo je nepovratno. Upiši OBRIŠI za potvrdu.";
    desc.fills = [boundFill(v["onSurfaceVariant"])];
    d.appendChild(desc);
    desc.layoutSizingHorizontal = "FILL";

    // Input field (visual only).
    const input = figma.createFrame();
    input.layoutMode = "HORIZONTAL";
    input.primaryAxisSizingMode = "FIXED";
    input.counterAxisSizingMode = "FIXED";
    input.primaryAxisAlignItems = "CENTER";
    input.resize(272, 48);
    input.paddingLeft = input.paddingRight = 12;
    input.fills = [];
    input.strokes = [boundFill(v["outline"])];
    input.strokeWeight = 1;
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      input.setBoundVariable(c, v["radius-button"]);
    }
    const inputText = figma.createText();
    await inputText.setTextStyleIdAsync(S["body/Large"].id);
    inputText.characters = "OBRIŠI";
    inputText.fills = [boundFill(v["onSurface"])];
    input.appendChild(inputText);
    d.appendChild(input);

    // Actions row
    const actions = figma.createFrame();
    actions.layoutMode = "HORIZONTAL";
    actions.primaryAxisSizingMode = "FIXED";
    actions.counterAxisSizingMode = "AUTO";
    actions.primaryAxisAlignItems = "MAX";
    actions.itemSpacing = 8;
    actions.resize(272, 48);
    actions.fills = [];
    d.appendChild(actions);

    const cancelBtn = figma.createFrame();
    cancelBtn.layoutMode = "HORIZONTAL";
    cancelBtn.primaryAxisAlignItems = "CENTER";
    cancelBtn.counterAxisAlignItems = "CENTER";
    cancelBtn.primaryAxisSizingMode = "AUTO";
    cancelBtn.counterAxisSizingMode = "AUTO";
    cancelBtn.paddingLeft = cancelBtn.paddingRight = 16;
    cancelBtn.paddingTop = cancelBtn.paddingBottom = 12;
    cancelBtn.fills = [];
    const cancelText = figma.createText();
    await cancelText.setTextStyleIdAsync(S["label/Large"].id);
    cancelText.characters = "Odustani";
    cancelText.fills = [boundFill(v["primary"])];
    cancelBtn.appendChild(cancelText);
    actions.appendChild(cancelBtn);

    const destBtn = figma.createFrame();
    destBtn.layoutMode = "HORIZONTAL";
    destBtn.primaryAxisAlignItems = "CENTER";
    destBtn.counterAxisAlignItems = "CENTER";
    destBtn.primaryAxisSizingMode = "AUTO";
    destBtn.counterAxisSizingMode = "AUTO";
    destBtn.paddingLeft = destBtn.paddingRight = 16;
    destBtn.paddingTop = destBtn.paddingBottom = 12;
    destBtn.fills = [boundFill(v["error"])];
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      destBtn.setBoundVariable(c, v["radius-button"]);
    }
    const destText = figma.createText();
    await destText.setTextStyleIdAsync(S["label/Large"].id);
    destText.characters = "Obriši";
    destText.fills = [boundFill(v["onError"])];
    destBtn.appendChild(destText);
    actions.appendChild(destBtn);

    d.x = 1720;
    d.y = 1500;
    results.push({ name: d.name, id: d.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // 6. AdBanner — 360×50 placeholder with collapse ×.
  // ════════════════════════════════════════════════════════════════════════
  {
    removeByName("AdBanner");
    const ad = figma.createComponent();
    ad.name = "AdBanner";
    ad.resize(360, 50);
    ad.layoutMode = "HORIZONTAL";
    ad.primaryAxisSizingMode = "FIXED";
    ad.counterAxisSizingMode = "FIXED";
    ad.primaryAxisAlignItems = "CENTER";
    ad.counterAxisAlignItems = "CENTER";
    ad.paddingLeft = ad.paddingRight = 16;
    ad.itemSpacing = 12;
    ad.fills = [boundFill(v["surfaceContainer"])];

    const label = figma.createText();
    await label.setTextStyleIdAsync(S["label/Medium"].id);
    label.characters = "Oglas (AdMob 50dp)";
    label.fills = [boundFill(v["onSurfaceVariant"])];
    ad.appendChild(label);
    label.layoutSizingHorizontal = "FILL";

    const xBtn = figma.createText();
    xBtn.fontName = { family: "Manrope", style: "Bold" };
    xBtn.characters = "×";
    xBtn.fontSize = 18;
    xBtn.fills = [boundFill(v["onSurfaceVariant"])];
    ad.appendChild(xBtn);

    ad.x = 0;
    ad.y = 2400;
    results.push({ name: ad.name, id: ad.id });
  }

  return { ok: true, count: results.length, components: results };
})()
