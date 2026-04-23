(async () => {
  // prijavko — Material 3 typescale, Manrope. UX spec §Typography System.
  // Idempotent: reuses text styles by name.

  const weightToStyle = {
    400: "Regular",
    500: "Medium",
    600: "SemiBold",
    700: "Bold",
    800: "ExtraBold",
  };

  // [name, size, weight, lineHeight]
  const scale = [
    ["display/Large",   57, 800, 64],
    ["display/Medium",  45, 700, 52],
    ["headline/Large",  32, 700, 40],
    ["headline/Medium", 28, 700, 36],
    ["headline/Small",  24, 600, 32],
    ["title/Large",     22, 600, 28],
    ["title/Medium",    16, 600, 24],
    ["body/Large",      16, 400, 24],
    ["body/Medium",     14, 400, 20],
    ["body/Small",      12, 500, 16],
    ["label/Large",     14, 600, 20],
    ["label/Medium",    12, 600, 16],
  ];

  // Load all Manrope weights we need.
  const weights = [...new Set(scale.map((r) => r[2]))];
  for (const w of weights) {
    await figma.loadFontAsync({ family: "Manrope", style: weightToStyle[w] });
  }

  const existing = await figma.getLocalTextStylesAsync();
  const byName = new Map(existing.map((s) => [s.name, s]));

  const results = [];
  for (const [name, size, weight, lineHeight] of scale) {
    let s = byName.get(name);
    const reused = !!s;
    if (!s) s = figma.createTextStyle();
    s.name = name;
    s.fontName = { family: "Manrope", style: weightToStyle[weight] };
    s.fontSize = size;
    s.lineHeight = { unit: "PIXELS", value: lineHeight };
    s.letterSpacing = { unit: "PIXELS", value: 0 };
    results.push({ name, id: s.id, reused });
  }

  return {
    ok: true,
    font: "Manrope",
    styleCount: results.length,
    styles: results.map((r) => ({ name: r.name, reused: r.reused })),
  };
})()
