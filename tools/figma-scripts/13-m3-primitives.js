(async () => {
  // prijavko — M3 primitives bundle: TextField, Chip, Switch, ListTile,
  // AlertDialog, LinearProgressIndicator, CircularProgressIndicator, SnackBar.

  let page = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(page);

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

  const removeByName = (name) => {
    for (const n of page.findAll((nd) => nd.name === name)) n.remove();
  };

  const results = [];
  let nextX = 0;
  const rowY = 2550;

  // Helper: round-all-corners bind to same radius var.
  const bindCorners = (node, radiusVar) => {
    for (const c of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) {
      node.setBoundVariable(c, radiusVar);
    }
  };

  // ── TextField (3-variant set: default / focused / error) ─────────────────
  {
    removeByName("TextField");
    for (const n of page.findAll((nd) => nd.name.startsWith("state="))) {
      // only remove TextField variants — but that name clashes. Actually
      // existing state=… nodes are from other sets we already combined.
      // Skip blanket removal; we only care about the TextField set.
    }

    const makeTF = async (state) => {
      const tf = figma.createComponent();
      tf.name = `state=${state}`;
      tf.layoutMode = "VERTICAL";
      tf.primaryAxisSizingMode = "AUTO";
      tf.counterAxisSizingMode = "FIXED";
      tf.resize(280, 80);
      tf.itemSpacing = 4;
      tf.fills = [];

      const label = figma.createText();
      await label.setTextStyleIdAsync(S["label/Medium"].id);
      label.characters = "Broj putovnice";
      label.fills = [
        boundFill(state === "focused" ? v["primary"] : state === "error" ? v["error"] : v["onSurfaceVariant"]),
      ];
      tf.appendChild(label);

      const field = figma.createFrame();
      field.layoutMode = "HORIZONTAL";
      field.primaryAxisSizingMode = "FIXED";
      field.counterAxisSizingMode = "FIXED";
      field.primaryAxisAlignItems = "CENTER";
      field.resize(280, 56);
      field.paddingLeft = field.paddingRight = 16;
      field.fills = [boundFill(v["surfaceContainer"])];
      bindCorners(field, v["radius-button"]);
      const strokeVar =
        state === "focused" ? v["primary"] : state === "error" ? v["error"] : v["outline"];
      field.strokes = [boundFill(strokeVar)];
      field.strokeWeight = state === "focused" ? 2 : 1;

      const val = figma.createText();
      await val.setTextStyleIdAsync(S["body/Large"].id);
      val.characters = state === "default" ? "HR2184596" : "HR2184596";
      val.fills = [boundFill(v["onSurface"])];
      field.appendChild(val);
      tf.appendChild(field);

      if (state === "error") {
        const helper = figma.createText();
        await helper.setTextStyleIdAsync(S["body/Small"].id);
        helper.characters = "Neispravan format broja";
        helper.fills = [boundFill(v["error"])];
        tf.appendChild(helper);
      }
      return tf;
    };

    const variants = [];
    for (const st of ["default", "focused", "error"]) variants.push(await makeTF(st));
    const set = figma.combineAsVariants(variants, page);
    set.name = "TextField";
    const pad = 16, gap = 16;
    let cy = pad;
    for (const c of variants) {
      c.x = pad;
      c.y = cy;
      cy += c.height + gap;
    }
    set.resizeWithoutConstraints(variants[0].width + 2 * pad, cy - gap + pad);
    set.x = nextX;
    set.y = rowY;
    nextX += set.width + 40;
    results.push({ name: "TextField", id: set.id });
  }

  // ── Chip (assist / filter-on / filter-off) ────────────────────────────────
  {
    removeByName("Chip");
    const makeChip = async (kind, label) => {
      const c = figma.createComponent();
      c.name = `kind=${kind}`;
      c.layoutMode = "HORIZONTAL";
      c.primaryAxisSizingMode = "AUTO";
      c.counterAxisSizingMode = "AUTO";
      c.primaryAxisAlignItems = "CENTER";
      c.counterAxisAlignItems = "CENTER";
      c.paddingLeft = c.paddingRight = 12;
      c.paddingTop = c.paddingBottom = 6;
      c.itemSpacing = 6;
      c.cornerRadius = 999;
      const isOn = kind === "filter-on";
      c.fills = [boundFill(isOn ? v["primaryContainer"] : v["surfaceContainer"])];
      if (!isOn) {
        c.strokes = [boundFill(v["outline"])];
        c.strokeWeight = 1;
      }
      const t = figma.createText();
      await t.setTextStyleIdAsync(S["label/Medium"].id);
      t.characters = label;
      t.fills = [boundFill(isOn ? v["onPrimaryContainer"] : v["onSurface"])];
      c.appendChild(t);
      return c;
    };
    const chips = [
      await makeChip("assist", "Skeniraj MRZ"),
      await makeChip("filter-off", "Svi"),
      await makeChip("filter-on", "U redu"),
    ];
    const set = figma.combineAsVariants(chips, page);
    set.name = "Chip";
    const pad = 12, gap = 12;
    let cy = pad;
    for (const c of chips) {
      c.x = pad;
      c.y = cy;
      cy += c.height + gap;
    }
    set.resizeWithoutConstraints(200, cy - gap + pad);
    set.x = nextX;
    set.y = rowY;
    nextX += set.width + 40;
    results.push({ name: "Chip", id: set.id });
  }

  // ── Switch (on / off) ─────────────────────────────────────────────────────
  {
    removeByName("Switch");
    const makeSwitch = (state) => {
      const track = figma.createComponent();
      track.name = `state=${state}`;
      track.resize(52, 32);
      track.cornerRadius = 16;
      track.layoutMode = "HORIZONTAL";
      track.primaryAxisAlignItems = state === "on" ? "MAX" : "MIN";
      track.counterAxisAlignItems = "CENTER";
      track.primaryAxisSizingMode = "FIXED";
      track.counterAxisSizingMode = "FIXED";
      track.paddingLeft = track.paddingRight = 4;
      track.fills = [boundFill(state === "on" ? v["primary"] : v["surfaceContainer"])];
      if (state !== "on") {
        track.strokes = [boundFill(v["outline"])];
        track.strokeWeight = 2;
      }
      const knob = figma.createFrame();
      knob.resize(24, 24);
      knob.cornerRadius = 12;
      knob.fills = [boundFill(state === "on" ? v["onPrimary"] : v["outline"])];
      track.appendChild(knob);
      return track;
    };
    const variants = [makeSwitch("off"), makeSwitch("on")];
    const set = figma.combineAsVariants(variants, page);
    set.name = "Switch";
    const pad = 12, gap = 12;
    let cy = pad;
    for (const c of variants) {
      c.x = pad;
      c.y = cy;
      cy += c.height + gap;
    }
    set.resizeWithoutConstraints(80, cy - gap + pad);
    set.x = nextX;
    set.y = rowY;
    nextX += set.width + 40;
    results.push({ name: "Switch", id: set.id });
  }

  // ── ListTile ──────────────────────────────────────────────────────────────
  {
    removeByName("ListTile");
    const tile = figma.createComponent();
    tile.name = "ListTile";
    tile.resize(360, 72);
    tile.layoutMode = "HORIZONTAL";
    tile.primaryAxisSizingMode = "FIXED";
    tile.counterAxisSizingMode = "FIXED";
    tile.primaryAxisAlignItems = "CENTER";
    tile.counterAxisAlignItems = "CENTER";
    tile.paddingLeft = tile.paddingRight = 16;
    tile.itemSpacing = 16;
    tile.fills = [];

    const leading = figma.createFrame();
    leading.resize(40, 40);
    leading.cornerRadius = 20;
    leading.fills = [boundFill(v["primaryContainer"])];
    leading.layoutMode = "HORIZONTAL";
    leading.primaryAxisAlignItems = "CENTER";
    leading.counterAxisAlignItems = "CENTER";
    leading.primaryAxisSizingMode = "FIXED";
    leading.counterAxisSizingMode = "FIXED";
    const leadText = figma.createText();
    leadText.fontName = { family: "Manrope", style: "Bold" };
    leadText.characters = "⚙";
    leadText.fontSize = 18;
    leadText.fills = [boundFill(v["onPrimaryContainer"])];
    leading.appendChild(leadText);
    tile.appendChild(leading);

    const col = figma.createFrame();
    col.layoutMode = "VERTICAL";
    col.primaryAxisSizingMode = "AUTO";
    col.counterAxisSizingMode = "AUTO";
    col.itemSpacing = 2;
    col.fills = [];
    tile.appendChild(col);
    col.layoutSizingHorizontal = "FILL";
    const title = figma.createText();
    await title.setTextStyleIdAsync(S["title/Medium"].id);
    title.characters = "Postavke aplikacije";
    title.fills = [boundFill(v["onSurface"])];
    col.appendChild(title);
    title.layoutSizingHorizontal = "FILL";
    const sub = figma.createText();
    await sub.setTextStyleIdAsync(S["body/Small"].id);
    sub.characters = "Jezik, obavještenja, o aplikaciji";
    sub.fills = [boundFill(v["onSurfaceVariant"])];
    col.appendChild(sub);
    sub.layoutSizingHorizontal = "FILL";

    const chevron = figma.createText();
    chevron.fontName = { family: "Manrope", style: "Bold" };
    chevron.characters = "›";
    chevron.fontSize = 20;
    chevron.fills = [boundFill(v["onSurfaceVariant"])];
    tile.appendChild(chevron);

    tile.x = nextX;
    tile.y = rowY;
    nextX += tile.width + 40;
    results.push({ name: "ListTile", id: tile.id });
  }

  // ── AlertDialog (generic) ─────────────────────────────────────────────────
  {
    removeByName("AlertDialog");
    const d = figma.createComponent();
    d.name = "AlertDialog";
    d.resize(320, 200);
    d.layoutMode = "VERTICAL";
    d.primaryAxisSizingMode = "AUTO";
    d.counterAxisSizingMode = "FIXED";
    d.paddingLeft = d.paddingRight = d.paddingTop = d.paddingBottom = 24;
    d.itemSpacing = 16;
    d.fills = [boundFill(v["surfaceContainer"])];
    bindCorners(d, v["radius-card"]);

    const title = figma.createText();
    await title.setTextStyleIdAsync(S["headline/Small"].id);
    title.characters = "Naslov dijaloga";
    title.fills = [boundFill(v["onSurface"])];
    d.appendChild(title);
    title.layoutSizingHorizontal = "FILL";

    const body = figma.createText();
    await body.setTextStyleIdAsync(S["body/Medium"].id);
    body.characters = "Opis situacije koja zahtijeva potvrdu korisnika.";
    body.fills = [boundFill(v["onSurfaceVariant"])];
    d.appendChild(body);
    body.layoutSizingHorizontal = "FILL";

    const actions = figma.createFrame();
    actions.layoutMode = "HORIZONTAL";
    actions.primaryAxisSizingMode = "FIXED";
    actions.counterAxisSizingMode = "AUTO";
    actions.primaryAxisAlignItems = "MAX";
    actions.itemSpacing = 8;
    actions.resize(272, 1);
    actions.fills = [];
    d.appendChild(actions);
    for (const [label, fillVar, textVar, strokeVar] of [
      ["Odustani", null, v["primary"], null],
      ["Potvrdi",  v["primary"], v["onPrimary"], null],
    ]) {
      const b = figma.createFrame();
      b.layoutMode = "HORIZONTAL";
      b.primaryAxisSizingMode = "AUTO";
      b.counterAxisSizingMode = "AUTO";
      b.primaryAxisAlignItems = "CENTER";
      b.counterAxisAlignItems = "CENTER";
      b.paddingLeft = b.paddingRight = 16;
      b.paddingTop = b.paddingBottom = 10;
      if (fillVar) b.fills = [boundFill(fillVar)];
      else b.fills = [];
      if (strokeVar) {
        b.strokes = [boundFill(strokeVar)];
        b.strokeWeight = 1;
      }
      bindCorners(b, v["radius-button"]);
      const t = figma.createText();
      await t.setTextStyleIdAsync(S["label/Large"].id);
      t.characters = label;
      t.fills = [boundFill(textVar)];
      b.appendChild(t);
      actions.appendChild(b);
    }

    d.x = nextX;
    d.y = rowY;
    nextX += d.width + 40;
    results.push({ name: "AlertDialog", id: d.id });
  }

  // Start a new row for progress + snackbar.
  nextX = 0;
  const row2Y = rowY + 600;

  // ── LinearProgressIndicator (determinate 60%) ─────────────────────────────
  {
    removeByName("LinearProgressIndicator");
    const comp = figma.createComponent();
    comp.name = "LinearProgressIndicator";
    comp.resize(280, 4);
    comp.cornerRadius = 2;
    comp.fills = [boundFill(v["surfaceContainer"])];
    comp.layoutMode = "NONE";
    const fill = figma.createFrame();
    fill.resize(168, 4);
    fill.cornerRadius = 2;
    fill.fills = [boundFill(v["primary"])];
    comp.appendChild(fill);
    fill.x = 0;
    fill.y = 0;
    comp.x = nextX;
    comp.y = row2Y;
    nextX += comp.width + 40;
    results.push({ name: "LinearProgressIndicator", id: comp.id });
  }

  // ── CircularProgressIndicator ─────────────────────────────────────────────
  {
    removeByName("CircularProgressIndicator");
    const comp = figma.createComponent();
    comp.name = "CircularProgressIndicator";
    comp.resize(48, 48);
    comp.fills = [];
    // Use an ELLIPSE with arcData for a 3/4 arc (270°).
    const arc = figma.createEllipse();
    arc.resize(40, 40);
    arc.x = 4;
    arc.y = 4;
    arc.fills = [];
    arc.strokes = [boundFill(v["primary"])];
    arc.strokeWeight = 4;
    arc.strokeCap = "ROUND";
    arc.arcData = {
      startingAngle: 0,
      endingAngle: Math.PI * 1.5,
      innerRadius: 0,
    };
    comp.appendChild(arc);
    comp.x = nextX;
    comp.y = row2Y;
    nextX += comp.width + 40;
    results.push({ name: "CircularProgressIndicator", id: comp.id });
  }

  // ── SnackBar ──────────────────────────────────────────────────────────────
  {
    removeByName("SnackBar");
    const sb = figma.createComponent();
    sb.name = "SnackBar";
    sb.resize(360, 48);
    sb.layoutMode = "HORIZONTAL";
    sb.primaryAxisSizingMode = "FIXED";
    sb.counterAxisSizingMode = "FIXED";
    sb.primaryAxisAlignItems = "CENTER";
    sb.counterAxisAlignItems = "CENTER";
    sb.paddingLeft = sb.paddingRight = 16;
    sb.itemSpacing = 12;
    sb.fills = [boundFill(v["surfaceContainer"])];
    bindCorners(sb, v["radius-button"]);

    const msg = figma.createText();
    await msg.setTextStyleIdAsync(S["body/Medium"].id);
    msg.characters = "Gost uklonjen";
    msg.fills = [boundFill(v["onSurface"])];
    sb.appendChild(msg);
    msg.layoutSizingHorizontal = "FILL";

    const action = figma.createText();
    await action.setTextStyleIdAsync(S["label/Large"].id);
    action.characters = "PONIŠTI";
    action.fills = [boundFill(v["primary"])];
    sb.appendChild(action);

    sb.x = nextX;
    sb.y = row2Y;
    results.push({ name: "SnackBar", id: sb.id });
  }

  return { ok: true, count: results.length, components: results };
})()
