(async () => {
  // prijavko — 9 screens composed from component instances.
  // All 360×800. Placed on dedicated Screens page.

  // ── Bootstrap: Screens page ──────────────────────────────────────────────
  let screensPage = figma.root.children.find((p) => p.name === "Screens");
  if (!screensPage) {
    screensPage = figma.createPage();
    screensPage.name = "Screens";
  }
  await figma.setCurrentPageAsync(screensPage);
  // Clear any prior screens so this script is idempotent.
  for (const n of [...screensPage.children]) n.remove();

  // ── Fetch tokens + fonts + styles ────────────────────────────────────────
  const allVars = await figma.variables.getLocalVariablesAsync();
  const v = Object.fromEntries(allVars.map((x) => [x.name, x]));
  for (const f of ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold"]) {
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

  // ── Fetch main components from Components page ───────────────────────────
  const componentsPage = figma.root.children.find((p) => p.name === "Components");
  const byName = (name) =>
    componentsPage.findOne((n) => n.type === "COMPONENT" && n.name === name);

  const getVariant = (setName, propsStr) =>
    componentsPage.findOne(
      (n) => n.type === "COMPONENT" && n.name === propsStr && n.parent?.name === setName
    );

  const C = {
    btnFilled: byName("Button/Filled"),
    btnOutlined: byName("Button/Outlined"),
    btnText: byName("Button/Text"),
    card: byName("Card"),
    capture: byName("CaptureConfirmation"),
    closure: byName("ClosureSummary"),
    facilitySheet: byName("FacilityPickerSheet"),
    mrz: byName("MRZViewfinder"),
    typedDialog: byName("TypedConfirmationDialog"),
    ad: byName("AdBanner"),
    listTile: byName("ListTile"),
    alert: byName("AlertDialog"),
    linearProg: byName("LinearProgressIndicator"),
    circProg: byName("CircularProgressIndicator"),
    snack: byName("SnackBar"),
    queueHero_empty_fresh: getVariant("QueueHero", "state=empty_fresh"),
    queueHero_non_empty: getVariant("QueueHero", "state=non_empty"),
    queueHero_auth_dead: getVariant("QueueHero", "state=auth_dead"),
    queueRow_queued: getVariant("QueueRow", "state=queued"),
    queueRow_sending: getVariant("QueueRow", "state=sending"),
    queueRow_sent: getVariant("QueueRow", "state=sent"),
    queueRow_failed: getVariant("QueueRow", "state=failed"),
    banner_warning: getVariant("CredentialBanner", "variant=warning"),
    tf_default: getVariant("TextField", "state=default"),
    tf_focused: getVariant("TextField", "state=focused"),
    tf_error: getVariant("TextField", "state=error"),
    chip_assist: getVariant("Chip", "kind=assist"),
    chip_filter_on: getVariant("Chip", "kind=filter-on"),
    chip_filter_off: getVariant("Chip", "kind=filter-off"),
    switchOn: getVariant("Switch", "state=on"),
    switchOff: getVariant("Switch", "state=off"),
  };

  // ── Helpers ──────────────────────────────────────────────────────────────
  const W = 360;
  const H = 800;

  // Create a phone-frame screen shell: 360×800, surface bg, vertical auto-layout.
  const makeScreen = (name) => {
    const f = figma.createFrame();
    f.name = name;
    f.resize(W, H);
    f.layoutMode = "VERTICAL";
    f.primaryAxisSizingMode = "FIXED";
    f.counterAxisSizingMode = "FIXED";
    f.itemSpacing = 0;
    f.fills = [boundFill(v["surface"])];
    f.clipsContent = true;
    return f;
  };

  // AppBar: 64dp, title + optional trailing.
  const appBar = async (parent, title, trailing) => {
    const bar = figma.createFrame();
    bar.layoutMode = "HORIZONTAL";
    bar.primaryAxisSizingMode = "FIXED";
    bar.counterAxisSizingMode = "FIXED";
    bar.primaryAxisAlignItems = "CENTER";
    bar.counterAxisAlignItems = "CENTER";
    bar.resize(W, 64);
    bar.paddingLeft = bar.paddingRight = 16;
    bar.itemSpacing = 12;
    bar.fills = [boundFill(v["surface"])];
    const t = figma.createText();
    await t.setTextStyleIdAsync(S["headline/Small"].id);
    t.characters = title;
    t.fills = [boundFill(v["onSurface"])];
    bar.appendChild(t);
    t.layoutSizingHorizontal = "FILL";
    if (trailing) bar.appendChild(trailing);
    parent.appendChild(bar);
    return bar;
  };

  // Spacer that grows to fill remaining space in a VERTICAL layout parent.
  const vSpacer = (parent) => {
    const s = figma.createFrame();
    s.fills = [];
    s.resize(1, 1);
    parent.appendChild(s);
    s.layoutGrow = 1;
  };

  // Horizontally-padded content slot — 16dp horizontal padding wrapper.
  // IMPORTANT: resize() resets sizing modes to FIXED — set modes AFTER resize.
  const contentSlot = (parent, spacing = 16) => {
    const slot = figma.createFrame();
    slot.layoutMode = "VERTICAL";
    slot.resize(W, 1);
    slot.primaryAxisSizingMode = "AUTO";
    slot.counterAxisSizingMode = "FIXED";
    slot.paddingLeft = slot.paddingRight = 16;
    slot.itemSpacing = spacing;
    slot.fills = [];
    parent.appendChild(slot);
    return slot;
  };

  // Body text helper.
  const bodyText = async (parent, styleName, text, colorVar) => {
    const t = figma.createText();
    await t.setTextStyleIdAsync(S[styleName].id);
    t.characters = text;
    t.fills = [boundFill(colorVar)];
    parent.appendChild(t);
    return t;
  };

  // Position screens in a 3×3 grid at x,y starting (0, 0) with 80dp gutters.
  const positionScreen = (screen, col, row) => {
    const gutter = 80;
    screen.x = col * (W + gutter);
    screen.y = row * (H + gutter);
  };

  const createdScreens = [];

  // ════════════════════════════════════════════════════════════════════════
  // Screen 1: Login
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("01 Login");
    await appBar(s, "prijavko");

    const slot = contentSlot(s, 24);
    slot.paddingTop = 32;

    const h = figma.createText();
    await h.setTextStyleIdAsync(S["headline/Large"].id);
    h.characters = "Prijavi se na eVisitor";
    h.fills = [boundFill(v["onSurface"])];
    slot.appendChild(h);
    h.layoutSizingHorizontal = "FILL";

    const sub = figma.createText();
    await sub.setTextStyleIdAsync(S["body/Medium"].id);
    sub.characters = "Jedna prijava koja radi za sve objekte.";
    sub.fills = [boundFill(v["onSurfaceVariant"])];
    slot.appendChild(sub);
    sub.layoutSizingHorizontal = "FILL";

    const oibInst = C.tf_default.createInstance();
    slot.appendChild(oibInst);
    oibInst.layoutSizingHorizontal = "FILL";
    const pwInst = C.tf_focused.createInstance();
    slot.appendChild(pwInst);
    pwInst.layoutSizingHorizontal = "FILL";

    vSpacer(s);

    const ctaSlot = contentSlot(s, 12);
    ctaSlot.paddingTop = 16;
    ctaSlot.paddingBottom = 24;
    const prijaviBtn = C.btnFilled.createInstance();
    ctaSlot.appendChild(prijaviBtn);
    prijaviBtn.layoutSizingHorizontal = "FILL";

    positionScreen(s, 0, 0);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 2: Home — empty, fresh
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("02 Home · Empty fresh");
    await appBar(s, "Villa Primorje");

    const slot = contentSlot(s, 16);
    slot.paddingTop = 16;

    const heroInst = C.queueHero_empty_fresh.createInstance();
    slot.appendChild(heroInst);
    heroInst.layoutSizingHorizontal = "FILL";

    const tip = figma.createText();
    await tip.setTextStyleIdAsync(S["body/Medium"].id);
    tip.characters = "Skeniraj osobnu prvog gosta — ostalo ide automatski.";
    tip.fills = [boundFill(v["onSurfaceVariant"])];
    tip.textAlignHorizontal = "CENTER";
    slot.appendChild(tip);
    tip.layoutSizingHorizontal = "FILL";

    vSpacer(s);

    const ctaSlot = contentSlot(s, 12);
    ctaSlot.paddingTop = 16;
    const scanBtn = C.btnFilled.createInstance();
    scanBtn.setProperties({}); // keep default
    ctaSlot.appendChild(scanBtn);
    scanBtn.layoutSizingHorizontal = "FILL";
    const manualBtn = C.btnOutlined.createInstance();
    ctaSlot.appendChild(manualBtn);
    manualBtn.layoutSizingHorizontal = "FILL";

    const ad = C.ad.createInstance();
    s.appendChild(ad);

    positionScreen(s, 1, 0);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 3: Home — 3 guests queued
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("03 Home · Queued 3");
    await appBar(s, "Villa Primorje");

    const slot = contentSlot(s, 12);
    slot.paddingTop = 16;

    const heroInst = C.queueHero_non_empty.createInstance();
    slot.appendChild(heroInst);
    heroInst.layoutSizingHorizontal = "FILL";

    for (let i = 0; i < 3; i++) {
      const row = C.queueRow_queued.createInstance();
      slot.appendChild(row);
      row.layoutSizingHorizontal = "FILL";
    }

    vSpacer(s);

    const ctaSlot = contentSlot(s, 12);
    ctaSlot.paddingTop = 16;
    const sendAll = C.btnFilled.createInstance();
    ctaSlot.appendChild(sendAll);
    sendAll.layoutSizingHorizontal = "FILL";
    const scanMore = C.btnOutlined.createInstance();
    ctaSlot.appendChild(scanMore);
    scanMore.layoutSizingHorizontal = "FILL";

    const ad = C.ad.createInstance();
    s.appendChild(ad);

    positionScreen(s, 2, 0);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 4: Home — auth dead (credential banner active)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("04 Home · Auth dead");
    await appBar(s, "Villa Primorje");

    // Banner pinned at top under AppBar.
    const bannerWrap = figma.createFrame();
    bannerWrap.layoutMode = "HORIZONTAL";
    bannerWrap.resize(W, 1);
    bannerWrap.primaryAxisSizingMode = "FIXED";
    bannerWrap.counterAxisSizingMode = "AUTO";
    bannerWrap.paddingLeft = bannerWrap.paddingRight = 16;
    bannerWrap.paddingTop = 8;
    bannerWrap.fills = [];
    const banner = C.banner_warning.createInstance();
    bannerWrap.appendChild(banner);
    banner.layoutSizingHorizontal = "FILL";
    s.appendChild(bannerWrap);

    const slot = contentSlot(s, 12);
    slot.paddingTop = 16;
    const heroInst = C.queueHero_auth_dead.createInstance();
    slot.appendChild(heroInst);
    heroInst.layoutSizingHorizontal = "FILL";

    for (let i = 0; i < 2; i++) {
      const row = C.queueRow_queued.createInstance();
      slot.appendChild(row);
      row.layoutSizingHorizontal = "FILL";
    }

    vSpacer(s);

    const ctaSlot = contentSlot(s, 12);
    ctaSlot.paddingTop = 16;
    const sendAll = C.btnFilled.createInstance();
    sendAll.opacity = 0.4; // visually disabled — spec: "Slanje blokirano"
    ctaSlot.appendChild(sendAll);
    sendAll.layoutSizingHorizontal = "FILL";

    positionScreen(s, 0, 1);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 5: Scan (MRZ Viewfinder — use instance, it's already a full screen)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("05 Scan");
    s.fills = [{ type: "SOLID", color: { r: 0.05, g: 0.05, b: 0.05 } }];
    s.layoutMode = "NONE";
    const inst = C.mrz.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    positionScreen(s, 1, 1);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 6: Capture Confirmation (instance in device frame)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("06 Capture Confirmation");
    s.layoutMode = "NONE";
    const inst = C.capture.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    positionScreen(s, 2, 1);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 7: Review Send All (mix of states + progress bar)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("07 Review Send All");
    await appBar(s, "Slanje 3 od 4");

    const slot = contentSlot(s, 12);
    slot.paddingTop = 16;

    // Progress bar
    const progInst = C.linearProg.createInstance();
    slot.appendChild(progInst);
    progInst.layoutSizingHorizontal = "FILL";

    // Mix: 2 sent, 1 sending, 1 failed
    const sequence = [
      C.queueRow_sent,
      C.queueRow_sent,
      C.queueRow_sending,
      C.queueRow_failed,
    ];
    for (const main of sequence) {
      const row = main.createInstance();
      slot.appendChild(row);
      row.layoutSizingHorizontal = "FILL";
    }

    vSpacer(s);

    const ctaSlot = contentSlot(s, 12);
    ctaSlot.paddingTop = 16;
    ctaSlot.paddingBottom = 24;
    const retryBtn = C.btnFilled.createInstance();
    ctaSlot.appendChild(retryBtn);
    retryBtn.layoutSizingHorizontal = "FILL";

    positionScreen(s, 0, 2);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 8: Closure Summary
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("08 Closure Summary");
    s.layoutMode = "NONE";
    const inst = C.closure.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    positionScreen(s, 1, 2);
    createdScreens.push({ name: s.name, id: s.id });
  }

  // ════════════════════════════════════════════════════════════════════════
  // Screen 9: Settings
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("09 Settings");
    await appBar(s, "Postavke");

    const slot = contentSlot(s, 0);
    slot.paddingTop = 8;

    // 4 settings rows.
    const rows = [
      "Jezik — Hrvatski",
      "Obavještenja",
      "Ponovi unos OIB-a",
      "O aplikaciji",
    ];
    for (const label of rows) {
      const tile = C.listTile.createInstance();
      slot.appendChild(tile);
      tile.layoutSizingHorizontal = "FILL";
    }

    positionScreen(s, 2, 2);
    createdScreens.push({ name: s.name, id: s.id });
  }

  return { ok: true, count: createdScreens.length, screens: createdScreens };
})()
