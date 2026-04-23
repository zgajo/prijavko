(async () => {
  // Per-instance text overrides on screens.
  let page = figma.root.children.find((p) => p.name === "Screens");
  await figma.setCurrentPageAsync(page);

  for (const f of ["Regular", "Medium", "SemiBold", "Bold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }

  // Collect instance metadata once (async getMainComponent is required in dynamic-page mode).
  const findInstancesInScreen = async (screen, predicate) => {
    const all = screen.findAll((n) => n.type === "INSTANCE");
    const out = [];
    for (const inst of all) {
      const main = await inst.getMainComponentAsync();
      if (main && predicate(main, inst)) out.push({ inst, main });
    }
    return out;
  };

  const setTextByCurrent = async (instance, oldText, newText) => {
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

  const setFirstText = async (instance, newText) => {
    const t = instance.findOne((n) => n.type === "TEXT");
    if (t) {
      await figma.loadFontAsync(t.fontName);
      t.characters = newText;
      return true;
    }
    return false;
  };

  const findScreen = (name) => page.findOne((n) => n.name === name);
  const changes = [];

  // ── 01 Login ─────────────────────────────────────────────────────────────
  {
    const s = findScreen("01 Login");
    if (s) {
      const tfInstances = await findInstancesInScreen(
        s,
        (main) => main.parent?.name === "TextField"
      );
      // First TF = OIB, second TF = Password
      if (tfInstances[0]) {
        await setTextByCurrent(tfInstances[0].inst, "Broj putovnice", "OIB");
        await setTextByCurrent(tfInstances[0].inst, "HR2184596", "98765432104");
      }
      if (tfInstances[1]) {
        await setTextByCurrent(tfInstances[1].inst, "Broj putovnice", "Lozinka");
        await setTextByCurrent(tfInstances[1].inst, "HR2184596", "••••••••");
      }
      const btnFilled = await findInstancesInScreen(s, (m) => m.name === "Button/Filled");
      if (btnFilled[0]) await setFirstText(btnFilled[0].inst, "Prijavi se");
      changes.push("01 Login");
    }
  }

  // ── 02 Home empty ────────────────────────────────────────────────────────
  {
    const s = findScreen("02 Home · Empty fresh");
    if (s) {
      const btnFilled = await findInstancesInScreen(s, (m) => m.name === "Button/Filled");
      if (btnFilled[0]) await setFirstText(btnFilled[0].inst, "Skeniraj gosta");
      changes.push("02 Home empty");
    }
  }

  // ── 03 Home queued ───────────────────────────────────────────────────────
  {
    const s = findScreen("03 Home · Queued 3");
    if (s) {
      const btnOutlined = await findInstancesInScreen(s, (m) => m.name === "Button/Outlined");
      if (btnOutlined[0]) await setFirstText(btnOutlined[0].inst, "Skeniraj još");
      changes.push("03 Home queued");
    }
  }

  // ── 07 Review ────────────────────────────────────────────────────────────
  {
    const s = findScreen("07 Review Send All");
    if (s) {
      const btnFilled = await findInstancesInScreen(s, (m) => m.name === "Button/Filled");
      if (btnFilled[0]) await setFirstText(btnFilled[0].inst, "Ponovi neuspjele");
      changes.push("07 Review");
    }
  }

  // ── 09 Settings ──────────────────────────────────────────────────────────
  {
    const s = findScreen("09 Settings");
    if (s) {
      const tiles = await findInstancesInScreen(s, (m) => m.name === "ListTile");
      const labels = [
        { t: "Jezik aplikacije",    sub: "Hrvatski" },
        { t: "Zvuk skena",          sub: "Uključen" },
        { t: "Ponovi unos OIB-a",   sub: "Zadnji unos: prije 3 dana" },
        { t: "O aplikaciji",        sub: "Verzija 1.0 · Prijavko d.o.o." },
      ];
      for (let i = 0; i < tiles.length && i < labels.length; i++) {
        await setTextByCurrent(tiles[i].inst, "Postavke aplikacije", labels[i].t);
        await setTextByCurrent(tiles[i].inst, "Jezik, obavještenja, o aplikaciji", labels[i].sub);
      }
      changes.push("09 Settings");
    }
  }

  return { ok: true, changes };
})()
