(async () => {
  // Prepend icons to button labels by rewriting the label text with "icon  label".
  // No structural changes — just text override on each instance.

  for (const f of ["Regular", "Medium", "SemiBold", "Bold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }

  const setLabelWithIcon = async (instance, newLabel) => {
    const t = instance.findOne((n) => n.type === "TEXT");
    if (!t) return false;
    await figma.loadFontAsync(t.fontName);
    t.characters = newLabel;
    return true;
  };

  const findBtnByLabel = async (screen, label) => {
    const instances = screen.findAll((n) => n.type === "INSTANCE");
    for (const inst of instances) {
      const main = await inst.getMainComponentAsync();
      if (!main || !main.name.startsWith("Button/")) continue;
      const t = inst.findOne((n) => n.type === "TEXT" && n.characters === label);
      if (t) return inst;
    }
    return null;
  };

  const pageS = figma.root.children.find((p) => p.name === "Screens");
  await figma.setCurrentPageAsync(pageS);

  const plan = [
    ["04 Home · Empty fresh", "Skeniraj gosta",   "📷  Skeniraj gosta"],
    ["04 Home · Empty fresh", "Ručni unos",        "⌨  Ručni unos"],
    ["05 Home · Queued 3",    "Pošalji sve (3)",   "↑  Pošalji sve (3)"],
    ["05 Home · Queued 3",    "Skeniraj",          "📷  Skeniraj"],
    ["05 Home · Queued 3",    "Ručno",             "⌨  Ručno"],
    ["06 Home · Auth dead",   "Pošalji sve (2)",   "↑  Pošalji sve (2)"],
  ];

  const results = [];
  for (const [screenName, oldLabel, newLabel] of plan) {
    const screen = pageS.findOne((n) => n.name === screenName);
    if (!screen) continue;
    const inst = await findBtnByLabel(screen, oldLabel);
    if (inst) {
      await setLabelWithIcon(inst, newLabel);
      results.push(`${screenName} → "${newLabel}"`);
    }
  }

  // Closure Summary — internal Podijeli button (not an instance, part of main comp).
  {
    const pageC = figma.root.children.find((p) => p.name === "Components");
    await figma.setCurrentPageAsync(pageC);
    const closure = pageC.findOne(
      (n) => n.type === "COMPONENT" && n.name === "ClosureSummary"
    );
    if (closure) {
      const share = closure.findOne((n) => n.type === "FRAME" && n.name === "share");
      if (share) {
        const t = share.findOne((n) => n.type === "TEXT");
        if (t && t.characters === "Podijeli") {
          await figma.loadFontAsync(t.fontName);
          t.characters = "↗  Podijeli";
          results.push("ClosureSummary · Podijeli → ↗ Podijeli");
        }
      }
    }
  }

  return { ok: true, count: results.length, results };
})()
