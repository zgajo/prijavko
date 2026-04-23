(async () => {
  // prijavko — screens v2. Match Direction A richness from ux-design-directions.html.
  // Adds: status bar, richer AppBar (title + sub + trailing), Welcome screen,
  //       doc-type prefixed queue row text, success-colored Send All header.

  let screensPage = figma.root.children.find((p) => p.name === "Screens");
  if (!screensPage) {
    screensPage = figma.createPage();
    screensPage.name = "Screens";
  }
  await figma.setCurrentPageAsync(screensPage);
  for (const n of [...screensPage.children]) n.remove();

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

  // Fetch main components.
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
    capture: byName("CaptureConfirmation"),
    closure: byName("ClosureSummary"),
    mrz: byName("MRZViewfinder"),
    ad: byName("AdBanner"),
    listTile: byName("ListTile"),
    linearProg: byName("LinearProgressIndicator"),
    queueHero_empty_fresh: getVariant("QueueHero", "state=empty_fresh"),
    queueHero_empty_recent: getVariant("QueueHero", "state=empty_recent"),
    queueHero_non_empty: getVariant("QueueHero", "state=non_empty"),
    queueHero_auth_dead: getVariant("QueueHero", "state=auth_dead"),
    queueRow_queued: getVariant("QueueRow", "state=queued"),
    queueRow_sending: getVariant("QueueRow", "state=sending"),
    queueRow_sent: getVariant("QueueRow", "state=sent"),
    queueRow_failed: getVariant("QueueRow", "state=failed"),
    banner_warning: getVariant("CredentialBanner", "variant=warning"),
    tf_default: getVariant("TextField", "state=default"),
    tf_focused: getVariant("TextField", "state=focused"),
    facilitySheet: byName("FacilityPickerSheet"),
  };

  const W = 360;
  const H = 800;
  const SB_H = 28; // status bar height
  const AB_H = 56; // app bar height

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
    screensPage.appendChild(s);
    return s;
  };

  // ── Status bar (28dp, time + signals) ────────────────────────────────────
  const statusBar = async (parent, time = "10:15") => {
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

  // ── AppBar (56dp) — title + optional sub + optional trailing icon ───────
  const appBar = async (parent, { title, sub, trailing = "⚙", titleColorVar = v["onSurface"] }) => {
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
    // 1dp bottom border using a rectangle? Simpler: outline-variant stroke bottom.
    bar.strokes = [boundFill(v["outlineVariant"])];
    bar.strokeWeight = 1;
    bar.strokeAlign = "INSIDE";
    bar.strokeTopWeight = 0;
    bar.strokeLeftWeight = 0;
    bar.strokeRightWeight = 0;
    bar.strokeBottomWeight = 1;

    const col = figma.createFrame();
    col.layoutMode = "VERTICAL";
    col.primaryAxisSizingMode = "AUTO";
    col.counterAxisSizingMode = "AUTO";
    col.itemSpacing = 2;
    col.fills = [];
    bar.appendChild(col);
    col.layoutSizingHorizontal = "FILL";

    const tt = figma.createText();
    await tt.setTextStyleIdAsync(S["title/Medium"].id);
    tt.characters = title;
    tt.fills = [boundFill(titleColorVar)];
    col.appendChild(tt);

    if (sub) {
      const st = figma.createText();
      await st.setTextStyleIdAsync(S["body/Small"].id);
      st.characters = sub;
      st.fills = [boundFill(v["onSurfaceVariant"])];
      col.appendChild(st);
    }

    if (trailing) {
      const g = figma.createFrame();
      g.resize(36, 36);
      g.cornerRadius = 18;
      g.layoutMode = "HORIZONTAL";
      g.primaryAxisAlignItems = "CENTER";
      g.counterAxisAlignItems = "CENTER";
      g.primaryAxisSizingMode = "FIXED";
      g.counterAxisSizingMode = "FIXED";
      g.fills = [];
      const gt = figma.createText();
      gt.fontName = { family: "Manrope", style: "Bold" };
      gt.characters = trailing;
      gt.fontSize = 18;
      gt.fills = [boundFill(v["onSurfaceVariant"])];
      g.appendChild(gt);
      bar.appendChild(g);
    }

    parent.appendChild(bar);
    return bar;
  };

  const vSpacer = (parent) => {
    const s = figma.createFrame();
    s.fills = [];
    s.resize(1, 1);
    parent.appendChild(s);
    s.layoutGrow = 1;
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

  // Override text in an instance by current characters match.
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

  // Enhance a queue row instance with doc-type prefixed title + custom meta.
  const customizeQueueRow = async (inst, docTitle, meta) => {
    await overrideText(inst, "HR2184…", docTitle);
    // All our queue row variants have some "Dodirom za uređivanje" / "Šaljem na eVisitor…" / "Prijavljeno" / "Neuspjeh — uredi i pošalji" as meta
    const candidates = [
      "Dodirom za uređivanje",
      "Šaljem na eVisitor…",
      "Prijavljeno",
      "Neuspjeh — uredi i pošalji",
    ];
    for (const c of candidates) {
      if (await overrideText(inst, c, meta)) return;
    }
  };

  const screenAtGrid = (s, col, row, gutter = 80) => {
    s.x = col * (W + gutter);
    s.y = row * (H + gutter);
  };

  const created = [];

  // ════════════════════════════════════════════════════════════════════════
  // 01 Welcome & consent
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("01 Welcome");
    await statusBar(s);

    const slot = contentSlot(s, 16, 32);

    const h = figma.createText();
    await h.setTextStyleIdAsync(S["headline/Large"].id);
    h.characters = "Dobrodošli u prijavko";
    h.fills = [boundFill(v["onSurface"])];
    slot.appendChild(h);
    h.layoutSizingHorizontal = "FILL";

    const p = figma.createText();
    await p.setTextStyleIdAsync(S["body/Medium"].id);
    p.characters = "Brza prijava gostiju u eVisitor — s vrata, bez tišine i bez grešaka.";
    p.fills = [boundFill(v["onSurfaceVariant"])];
    slot.appendChild(p);
    p.layoutSizingHorizontal = "FILL";

    const spacer = figma.createFrame();
    spacer.fills = [];
    spacer.resize(1, 12);
    slot.appendChild(spacer);

    const bullets = [
      { dot: "1", text: "Skeniraš putovnicu, čuva se šifrirano na uređaju." },
      { dot: "2", text: "Podaci gosta nestaju 3 dana nakon prijave." },
      { dot: "3", text: "Ne gubimo prijavu. Ne šutimo pri grešci." },
    ];
    for (const b of bullets) {
      const row = figma.createFrame();
      row.layoutMode = "HORIZONTAL";
      row.resize(328, 1);
      row.primaryAxisSizingMode = "FIXED";
      row.counterAxisSizingMode = "AUTO";
      row.counterAxisAlignItems = "CENTER";
      row.itemSpacing = 12;
      row.fills = [];
      slot.appendChild(row);

      const dot = figma.createFrame();
      dot.resize(28, 28);
      dot.cornerRadius = 14;
      dot.layoutMode = "HORIZONTAL";
      dot.primaryAxisAlignItems = "CENTER";
      dot.counterAxisAlignItems = "CENTER";
      dot.primaryAxisSizingMode = "FIXED";
      dot.counterAxisSizingMode = "FIXED";
      dot.fills = [boundFill(v["primaryContainer"])];
      const dotText = figma.createText();
      dotText.fontName = { family: "Manrope", style: "Bold" };
      dotText.characters = b.dot;
      dotText.fontSize = 14;
      dotText.fills = [boundFill(v["onPrimaryContainer"])];
      dot.appendChild(dotText);
      row.appendChild(dot);

      const txt = figma.createText();
      await txt.setTextStyleIdAsync(S["body/Medium"].id);
      txt.characters = b.text;
      txt.fills = [boundFill(v["onSurface"])];
      row.appendChild(txt);
      txt.layoutSizingHorizontal = "FILL";
    }

    vSpacer(s);

    const cta = contentSlot(s, 8, 16);
    cta.paddingBottom = 20;
    const nastavi = C.btnFilled.createInstance();
    await overrideText(nastavi, "Pošalji sve", "Nastavi");
    cta.appendChild(nastavi);
    nastavi.layoutSizingHorizontal = "FILL";

    const foot = figma.createText();
    await foot.setTextStyleIdAsync(S["body/Small"].id);
    foot.characters = "Nastavkom prihvaćaš Uvjete i Politiku privatnosti.";
    foot.fills = [boundFill(v["onSurfaceVariant"])];
    foot.textAlignHorizontal = "CENTER";
    cta.appendChild(foot);
    foot.layoutSizingHorizontal = "FILL";

    screenAtGrid(s, 0, 0);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 02 eVisitor Login
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("02 Login");
    await statusBar(s);
    await appBar(s, { title: "Prijava na eVisitor", trailing: "?" });

    const slot = contentSlot(s, 16, 24);

    const userTF = C.tf_default.createInstance();
    await overrideText(userTF, "Broj putovnice", "Korisničko ime");
    await overrideText(userTF, "HR2184596", "ana.trogir");
    slot.appendChild(userTF);
    userTF.layoutSizingHorizontal = "FILL";

    const pwTF = C.tf_focused.createInstance();
    await overrideText(pwTF, "Broj putovnice", "Lozinka");
    await overrideText(pwTF, "HR2184596", "•••••••••••");
    slot.appendChild(pwTF);
    pwTF.layoutSizingHorizontal = "FILL";

    const hint = figma.createText();
    await hint.setTextStyleIdAsync(S["body/Small"].id);
    hint.characters = "Podaci se čuvaju šifrirano u Android Keystore-u.";
    hint.fills = [boundFill(v["onSurfaceVariant"])];
    slot.appendChild(hint);
    hint.layoutSizingHorizontal = "FILL";

    vSpacer(s);

    const cta = contentSlot(s, 8, 16);
    cta.paddingBottom = 24;
    const prijavi = C.btnFilled.createInstance();
    await overrideText(prijavi, "Pošalji sve", "Prijavi se");
    cta.appendChild(prijavi);
    prijavi.layoutSizingHorizontal = "FILL";

    screenAtGrid(s, 1, 0);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 03 Facility picker (dimmed screen with sheet)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("03 Facility Picker");
    s.layoutMode = "NONE";
    s.fills = [boundFill(v["surface"])];

    // Status bar positioned manually.
    const sb = figma.createFrame();
    sb.layoutMode = "HORIZONTAL";
    sb.resize(W, SB_H);
    sb.primaryAxisSizingMode = "FIXED";
    sb.counterAxisSizingMode = "FIXED";
    sb.primaryAxisAlignItems = "SPACE_BETWEEN";
    sb.counterAxisAlignItems = "CENTER";
    sb.paddingLeft = 20;
    sb.paddingRight = 20;
    sb.fills = [boundFill(v["surface"])];
    const tt = figma.createText();
    tt.fontName = { family: "Manrope", style: "SemiBold" };
    tt.characters = "10:16";
    tt.fontSize = 12;
    tt.fills = [boundFill(v["onSurface"])];
    sb.appendChild(tt);
    const sig = figma.createText();
    sig.fontName = { family: "Manrope", style: "SemiBold" };
    sig.characters = "●●●  ⌃";
    sig.fontSize = 11;
    sig.fills = [boundFill(v["onSurface"])];
    sb.appendChild(sig);
    s.appendChild(sb);
    sb.x = 0;
    sb.y = 0;

    // Dimmed backdrop covering entire screen.
    const dim = figma.createRectangle();
    dim.resize(W, H);
    dim.fills = [{ type: "SOLID", color: { r: 0, g: 0, b: 0 }, opacity: 0.55 }];
    s.appendChild(dim);
    dim.x = 0;
    dim.y = 0;

    // FacilityPickerSheet instance at bottom.
    const sheet = C.facilitySheet.createInstance();
    s.appendChild(sheet);
    sheet.x = 0;
    sheet.y = H - sheet.height;

    screenAtGrid(s, 2, 0);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 04 Home · Empty fresh
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("04 Home · Empty fresh");
    await statusBar(s, "10:17");
    await appBar(s, { title: "Apartman Luna", sub: "Trogir · promijeni", trailing: "⚙" });

    const slot = contentSlot(s, 12, 16);
    const hero = C.queueHero_empty_fresh.createInstance();
    slot.appendChild(hero);
    hero.layoutSizingHorizontal = "FILL";

    const tip = figma.createText();
    await tip.setTextStyleIdAsync(S["body/Medium"].id);
    tip.characters = "Nema neposlanih gostiju.\nDodirni Skeniraj gosta.";
    tip.fills = [boundFill(v["onSurfaceVariant"])];
    tip.textAlignHorizontal = "CENTER";
    slot.appendChild(tip);
    tip.layoutSizingHorizontal = "FILL";

    vSpacer(s);

    const cta = contentSlot(s, 8, 16);
    const scanBtn = C.btnFilled.createInstance();
    await overrideText(scanBtn, "Pošalji sve", "Skeniraj gosta");
    cta.appendChild(scanBtn);
    scanBtn.layoutSizingHorizontal = "FILL";
    const manBtn = C.btnOutlined.createInstance();
    await overrideText(manBtn, "Ručni unos", "Ručni unos");
    cta.appendChild(manBtn);
    manBtn.layoutSizingHorizontal = "FILL";

    const ad = C.ad.createInstance();
    s.appendChild(ad);

    screenAtGrid(s, 3, 0);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 05 Home · 3 unsent (with inline rows + 3-CTA grid)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("05 Home · Queued 3");
    await statusBar(s, "21:44");
    await appBar(s, { title: "Apartman Luna", sub: "Trogir", trailing: "⚙" });

    const slot = contentSlot(s, 8, 16);
    const hero = C.queueHero_non_empty.createInstance();
    slot.appendChild(hero);
    hero.layoutSizingHorizontal = "FILL";

    const rows = [
      { doc: "Putovnica · HR2184…", time: "21:42" },
      { doc: "Putovnica · DE8830…", time: "21:44" },
      { doc: "OI · IT5521…",        time: "21:45 · ručno" },
    ];
    for (const r of rows) {
      const inst = C.queueRow_queued.createInstance();
      slot.appendChild(inst);
      inst.layoutSizingHorizontal = "FILL";
      await customizeQueueRow(inst, r.doc, r.time);
    }

    vSpacer(s);

    // CTA area: 1 primary (full-width) + 2 half-width secondary in a row.
    const cta = figma.createFrame();
    cta.layoutMode = "VERTICAL";
    cta.resize(W, 1);
    cta.primaryAxisSizingMode = "AUTO";
    cta.counterAxisSizingMode = "FIXED";
    cta.paddingLeft = cta.paddingRight = 16;
    cta.paddingTop = 16;
    cta.itemSpacing = 8;
    cta.fills = [];
    s.appendChild(cta);

    const primary = C.btnFilled.createInstance();
    await overrideText(primary, "Pošalji sve", "Pošalji sve (3)");
    cta.appendChild(primary);
    primary.layoutSizingHorizontal = "FILL";

    const twoRow = figma.createFrame();
    twoRow.layoutMode = "HORIZONTAL";
    twoRow.resize(328, 1);
    twoRow.primaryAxisSizingMode = "FIXED";
    twoRow.counterAxisSizingMode = "AUTO";
    twoRow.itemSpacing = 8;
    twoRow.fills = [];
    cta.appendChild(twoRow);

    const scan = C.btnOutlined.createInstance();
    await overrideText(scan, "Ručni unos", "Skeniraj");
    twoRow.appendChild(scan);
    scan.layoutSizingHorizontal = "FILL";

    const manual = C.btnOutlined.createInstance();
    await overrideText(manual, "Ručni unos", "Ručno");
    twoRow.appendChild(manual);
    manual.layoutSizingHorizontal = "FILL";

    const ad = C.ad.createInstance();
    s.appendChild(ad);

    screenAtGrid(s, 0, 1);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 06 Home · Auth dead (credential banner)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("06 Home · Auth dead");
    await statusBar(s, "14:22");
    await appBar(s, { title: "Apartman Luna", sub: "Trogir", trailing: "⚙" });

    const bannerWrap = figma.createFrame();
    bannerWrap.layoutMode = "HORIZONTAL";
    bannerWrap.resize(W, 1);
    bannerWrap.primaryAxisSizingMode = "FIXED";
    bannerWrap.counterAxisSizingMode = "AUTO";
    bannerWrap.paddingLeft = bannerWrap.paddingRight = 16;
    bannerWrap.paddingTop = 12;
    bannerWrap.fills = [];
    const banner = C.banner_warning.createInstance();
    bannerWrap.appendChild(banner);
    banner.layoutSizingHorizontal = "FILL";
    s.appendChild(bannerWrap);

    const slot = contentSlot(s, 8, 16);
    const hero = C.queueHero_auth_dead.createInstance();
    slot.appendChild(hero);
    hero.layoutSizingHorizontal = "FILL";

    for (const r of [
      { doc: "Putovnica · HR2184…", time: "14:19" },
      { doc: "Putovnica · DE8830…", time: "14:21" },
    ]) {
      const inst = C.queueRow_queued.createInstance();
      slot.appendChild(inst);
      inst.layoutSizingHorizontal = "FILL";
      await customizeQueueRow(inst, r.doc, r.time);
    }

    vSpacer(s);
    const cta = contentSlot(s, 8, 16);
    cta.paddingBottom = 24;
    const sendBtn = C.btnFilled.createInstance();
    await overrideText(sendBtn, "Pošalji sve", "Pošalji sve (2)");
    sendBtn.opacity = 0.4;
    cta.appendChild(sendBtn);
    sendBtn.layoutSizingHorizontal = "FILL";

    screenAtGrid(s, 1, 1);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 07 Scan (full-bleed MRZ viewfinder)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("07 Scan");
    s.layoutMode = "NONE";
    const inst = C.mrz.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    screenAtGrid(s, 2, 1);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 08 Capture Confirmation
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("08 Capture Confirmation");
    s.layoutMode = "NONE";
    const inst = C.capture.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    screenAtGrid(s, 3, 1);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 09 Send All results — AppBar title in success color
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("09 Send All Results");
    await statusBar(s, "21:47");
    await appBar(s, {
      title: "Gotovo — 3 od 4",
      trailing: "×",
      titleColorVar: v["success"],
    });

    const slot = contentSlot(s, 8, 16);
    const progress = C.linearProg.createInstance();
    slot.appendChild(progress);
    progress.layoutSizingHorizontal = "FILL";

    const rowData = [
      { row: C.queueRow_sent,    doc: "Putovnica · HR2184…", meta: "Prihvaćeno" },
      { row: C.queueRow_sent,    doc: "Putovnica · DE8830…", meta: "Prihvaćeno" },
      { row: C.queueRow_failed,  doc: "OI · IT5521…",        meta: "Nedostaje reg. broj" },
      { row: C.queueRow_sent,    doc: "Putovnica · FR1122…", meta: "Prihvaćeno" },
    ];
    for (const d of rowData) {
      const inst = d.row.createInstance();
      slot.appendChild(inst);
      inst.layoutSizingHorizontal = "FILL";
      await customizeQueueRow(inst, d.doc, d.meta);
    }

    vSpacer(s);
    const cta = contentSlot(s, 8, 16);
    cta.paddingBottom = 24;
    const retry = C.btnFilled.createInstance();
    await overrideText(retry, "Pošalji sve", "Pokušaj neuspjele (1)");
    cta.appendChild(retry);
    retry.layoutSizingHorizontal = "FILL";

    screenAtGrid(s, 0, 2);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 10 Closure Summary (instance, existing)
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("10 Closure Summary");
    s.layoutMode = "NONE";
    const inst = C.closure.createInstance();
    s.appendChild(inst);
    inst.x = 0;
    inst.y = 0;

    screenAtGrid(s, 1, 2);
    created.push(s.name);
  }

  // ════════════════════════════════════════════════════════════════════════
  // 11 Settings
  // ════════════════════════════════════════════════════════════════════════
  {
    const s = makeScreen("11 Settings");
    await statusBar(s, "10:20");
    await appBar(s, { title: "Postavke", trailing: "" });

    const slot = contentSlot(s, 0, 8);
    const tiles = [
      { t: "Jezik aplikacije", sub: "Hrvatski" },
      { t: "Zvuk skena", sub: "Uključen" },
      { t: "Ponovi unos OIB-a", sub: "Zadnji unos: prije 3 dana" },
      { t: "Obriši sve podatke", sub: "Nepovratno — traži potvrdu" },
      { t: "O aplikaciji", sub: "Verzija 1.0 · Prijavko d.o.o." },
    ];
    for (const tile of tiles) {
      const inst = C.listTile.createInstance();
      slot.appendChild(inst);
      inst.layoutSizingHorizontal = "FILL";
      await overrideText(inst, "Postavke aplikacije", tile.t);
      await overrideText(inst, "Jezik, obavještenja, o aplikaciji", tile.sub);
    }

    screenAtGrid(s, 2, 2);
    created.push(s.name);
  }

  return { ok: true, count: created.length, screens: created };
})()
