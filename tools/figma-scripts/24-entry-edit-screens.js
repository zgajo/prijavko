(async () => {
  // prijavko — Manual Entry + Edit Guest screens. Same form skeleton, different state.
  // Fields (per common eVisitor guest record shape):
  //   1. Vrsta isprave — chip group (Putovnica / OI / Ostalo)
  //   2. Broj isprave — TextField
  //   3. Ime — TextField
  //   4. Prezime — TextField
  //   5. Državljanstvo — TextField
  //   6. Datum rođenja — TextField (date picker in real app)
  //   7. Spol — chip group (M / Ž)
  //   8. Datum dolaska — TextField (date picker in real app)

  const pageS = figma.root.children.find((p) => p.name === "Screens");
  await figma.setCurrentPageAsync(pageS);

  // Idempotent: clear prior Manual Entry / Edit Guest if present.
  for (const n of [...pageS.children]) {
    if (n.name === "12 Manual Entry" || n.name === "13 Edit Guest") n.remove();
  }

  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));

  for (const f of ["Regular", "Medium", "SemiBold", "Bold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }
  const styles = await figma.getLocalTextStylesAsync();
  const S = Object.fromEntries(styles.map((s) => [s.name, s]));

  const boundFill = (variable) =>
    figma.variables.setBoundVariableForPaint(
      { type: "SOLID", color: { r: 0.5, g: 0.5, b: 0.5 } },
      "color",
      variable
    );

  // Components
  const pageC = figma.root.children.find((p) => p.name === "Components");
  const byName = (name) =>
    pageC.findOne((n) => n.type === "COMPONENT" && n.name === name);
  const getVariant = (setName, propsStr) =>
    pageC.findOne(
      (n) => n.type === "COMPONENT" && n.name === propsStr && n.parent?.name === setName
    );

  const C = {
    btnFilled: byName("Button/Filled"),
    btnOutlined: byName("Button/Outlined"),
    tf_default: getVariant("TextField", "state=default"),
    tf_focused: getVariant("TextField", "state=focused"),
    tf_error: getVariant("TextField", "state=error"),
    chip_assist: getVariant("Chip", "kind=assist"),
    chip_on: getVariant("Chip", "kind=filter-on"),
    chip_off: getVariant("Chip", "kind=filter-off"),
  };

  const W = 360;
  const H = 800;
  const SB_H = 28;
  const AB_H = 56;

  // Helpers (copied style from 18-screens-v2 — same conventions).
  const statusBar = async (parent, time = "10:30") => {
    const bar = figma.createFrame();
    bar.layoutMode = "HORIZONTAL";
    bar.resize(W, SB_H);
    bar.primaryAxisSizingMode = "FIXED";
    bar.counterAxisSizingMode = "FIXED";
    bar.primaryAxisAlignItems = "SPACE_BETWEEN";
    bar.counterAxisAlignItems = "CENTER";
    bar.paddingLeft = 20;
    bar.paddingRight = 20;
    bar.fills = [boundFill(v["surface"])];
    const t = figma.createText();
    t.fontName = { family: "Manrope", style: "SemiBold" };
    t.characters = time;
    t.fontSize = 12;
    t.fills = [boundFill(v["onSurface"])];
    bar.appendChild(t);
    const sig = figma.createText();
    sig.fontName = { family: "Manrope", style: "SemiBold" };
    sig.characters = "●●●  ⌃";
    sig.fontSize = 11;
    sig.fills = [boundFill(v["onSurface"])];
    bar.appendChild(sig);
    parent.appendChild(bar);
  };

  const appBar = async (parent, title) => {
    const bar = figma.createFrame();
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

    const tt = figma.createText();
    await tt.setTextStyleIdAsync(S["title/Medium"].id);
    tt.characters = title;
    tt.fills = [boundFill(v["onSurface"])];
    bar.appendChild(tt);
    tt.layoutSizingHorizontal = "FILL";

    // × close trailing
    const close = figma.createFrame();
    close.resize(36, 36);
    close.cornerRadius = 18;
    close.layoutMode = "HORIZONTAL";
    close.primaryAxisSizingMode = "FIXED";
    close.counterAxisSizingMode = "FIXED";
    close.primaryAxisAlignItems = "CENTER";
    close.counterAxisAlignItems = "CENTER";
    close.fills = [];
    const closeText = figma.createText();
    closeText.fontName = { family: "Manrope", style: "Bold" };
    closeText.characters = "×";
    closeText.fontSize = 22;
    closeText.fills = [boundFill(v["onSurface"])];
    close.appendChild(closeText);
    bar.appendChild(close);

    parent.appendChild(bar);
  };

  const overrideText = async (instance, oldText, newText) => {
    const texts = instance.findAll((n) => n.type === "TEXT");
    for (const t of texts) {
      if (t.characters === oldText) {
        await figma.loadFontAsync(t.fontName);
        t.characters = newText;
        return true;
      }
    }
    return false;
  };

  // Build a chip group: array of {label, selected}. Uses Chip variants.
  const chipGroup = async (parent, chipData) => {
    const group = figma.createFrame();
    group.layoutMode = "HORIZONTAL";
    group.primaryAxisSizingMode = "AUTO";
    group.counterAxisSizingMode = "AUTO";
    group.itemSpacing = 8;
    group.fills = [];
    parent.appendChild(group);
    for (const d of chipData) {
      const source = d.selected ? C.chip_on : C.chip_off;
      const inst = source.createInstance();
      await overrideText(inst, "Svi", d.label);
      await overrideText(inst, "U redu", d.label);
      group.appendChild(inst);
    }
    return group;
  };

  // Build a TextField row: fieldState = "default" | "focused" | "error"
  //   opts: { label, value, helper? }
  const tfRow = async (parent, fieldState, { label, value, helper }) => {
    const main =
      fieldState === "error" ? C.tf_error :
      fieldState === "focused" ? C.tf_focused : C.tf_default;
    const inst = main.createInstance();
    parent.appendChild(inst);
    inst.layoutSizingHorizontal = "FILL";
    await overrideText(inst, "Broj putovnice", label);
    await overrideText(inst, "HR2184596", value);
    if (helper) {
      await overrideText(inst, "Neispravan format broja", helper);
    }
    return inst;
  };

  const makeScreen = (name) => {
    const s = figma.createFrame();
    s.name = name;
    s.resize(W, H);
    s.layoutMode = "VERTICAL";
    s.itemSpacing = 0;
    s.primaryAxisSizingMode = "FIXED";
    s.counterAxisSizingMode = "FIXED";
    s.fills = [boundFill(v["surface"])];
    s.clipsContent = true;
    pageS.appendChild(s);
    return s;
  };

  const contentSlot = (parent, spacing = 16, topPad = 16) => {
    const slot = figma.createFrame();
    slot.layoutMode = "VERTICAL";
    slot.resize(W, 1);
    slot.primaryAxisSizingMode = "AUTO";
    slot.counterAxisSizingMode = "FIXED";
    slot.paddingLeft = 16;
    slot.paddingRight = 16;
    slot.paddingTop = topPad;
    slot.itemSpacing = spacing;
    slot.fills = [];
    parent.appendChild(slot);
    return slot;
  };

  const sectionLabel = async (parent, text) => {
    const t = figma.createText();
    await t.setTextStyleIdAsync(S["label/Medium"].id);
    t.characters = text;
    t.fills = [boundFill(v["onSurfaceVariant"])];
    parent.appendChild(t);
    t.layoutSizingHorizontal = "FILL";
  };

  const created = [];

  // ════════════════════════════════════════════════════════════════════════
  // 12 Manual Entry (empty form)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("12 Manual Entry");
    await statusBar(s);
    await appBar(s, "Novi gost");

    const slot = contentSlot(s, 16, 20);

    await sectionLabel(slot, "Vrsta isprave");
    await chipGroup(slot, [
      { label: "Putovnica", selected: false },
      { label: "OI", selected: false },
      { label: "Ostalo", selected: false },
    ]);

    await tfRow(slot, "default", { label: "Broj isprave", value: "" });
    await tfRow(slot, "default", { label: "Ime", value: "" });
    await tfRow(slot, "default", { label: "Prezime", value: "" });
    await tfRow(slot, "default", { label: "Državljanstvo", value: "" });
    await tfRow(slot, "default", { label: "Datum rođenja", value: "DD.MM.GGGG." });

    await sectionLabel(slot, "Spol");
    await chipGroup(slot, [
      { label: "Muško", selected: false },
      { label: "Žensko", selected: false },
    ]);

    await tfRow(slot, "default", { label: "Datum dolaska", value: "DD.MM.GGGG." });

    // Bottom CTA — NOT in auto-layout-grow area (since content overflows 800dp,
    // CTA needs to be pinned). We'll place it with layoutMode and hope content fits.
    // For skeleton: put CTA at the end of slot.
    const cta = figma.createFrame();
    cta.layoutMode = "VERTICAL";
    cta.resize(W, 1);
    cta.primaryAxisSizingMode = "AUTO";
    cta.counterAxisSizingMode = "FIXED";
    cta.paddingLeft = 16;
    cta.paddingRight = 16;
    cta.paddingTop = 16;
    cta.paddingBottom = 24;
    cta.itemSpacing = 8;
    cta.fills = [];
    s.appendChild(cta);
    const primary = C.btnFilled.createInstance();
    await overrideText(primary, "Pošalji sve", "Spremi");
    cta.appendChild(primary);
    primary.layoutSizingHorizontal = "FILL";
    const secondary = C.btnOutlined.createInstance();
    await overrideText(secondary, "Ručni unos", "Odustani");
    cta.appendChild(secondary);
    secondary.layoutSizingHorizontal = "FILL";

    // Position in grid row 3 col 0 (below existing screens).
    s.x = 0;
    s.y = 3 * (H + 80);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 13 Edit Guest (pre-filled, doc number in error state)
  //    Scenario: from Review Send All, failed row "OI · IT5521…" — missing reg nr.
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("13 Edit Guest");
    await statusBar(s);
    await appBar(s, "Uredi gosta");

    const slot = contentSlot(s, 16, 20);

    await sectionLabel(slot, "Vrsta isprave");
    await chipGroup(slot, [
      { label: "Putovnica", selected: false },
      { label: "OI", selected: true },
      { label: "Ostalo", selected: false },
    ]);

    // Error state on doc number — the bad field from the Send All failure.
    await tfRow(slot, "error", {
      label: "Broj isprave",
      value: "IT5521",
      helper: "Dodaj registarski broj iza kose crte.",
    });
    await tfRow(slot, "default", { label: "Ime", value: "Marco" });
    await tfRow(slot, "default", { label: "Prezime", value: "Rossi" });
    await tfRow(slot, "default", { label: "Državljanstvo", value: "Italija" });
    await tfRow(slot, "default", { label: "Datum rođenja", value: "14.03.1988." });

    await sectionLabel(slot, "Spol");
    await chipGroup(slot, [
      { label: "Muško", selected: true },
      { label: "Žensko", selected: false },
    ]);

    await tfRow(slot, "default", { label: "Datum dolaska", value: "23.04.2026." });

    const cta = figma.createFrame();
    cta.layoutMode = "VERTICAL";
    cta.resize(W, 1);
    cta.primaryAxisSizingMode = "AUTO";
    cta.counterAxisSizingMode = "FIXED";
    cta.paddingLeft = 16;
    cta.paddingRight = 16;
    cta.paddingTop = 16;
    cta.paddingBottom = 24;
    cta.itemSpacing = 8;
    cta.fills = [];
    s.appendChild(cta);
    const primary = C.btnFilled.createInstance();
    await overrideText(primary, "Pošalji sve", "Spremi i pošalji");
    cta.appendChild(primary);
    primary.layoutSizingHorizontal = "FILL";
    const secondary = C.btnOutlined.createInstance();
    await overrideText(secondary, "Ručni unos", "Odustani");
    cta.appendChild(secondary);
    secondary.layoutSizingHorizontal = "FILL";

    s.x = (W + 80);
    s.y = 3 * (H + 80);
    created.push(s.name);
  }

  return { ok: true, screens: created };
})()
