(async () => {
  const pageS = figma.root.children.find((p) => p.name === "Screens");
  await figma.setCurrentPageAsync(pageS);
  const login = pageS.findOne((n) => n.name === "02 Login");
  if (!login) return { ok: false };
  const row = login.findOne((n) => n.type === "FRAME" && n.name === "hint-row");
  if (!row) return { ok: false, error: "hint-row not found" };
  // Counter axis = vertical for HORIZONTAL layout. AUTO lets it grow to child height.
  row.counterAxisSizingMode = "AUTO";
  row.counterAxisAlignItems = "CENTER";
  // Ensure the text child has AUTO vertical sizing too.
  const txt = row.children.find((c) => c.type === "TEXT" && c.characters.startsWith("Podaci"));
  if (txt) txt.layoutSizingVertical = "HUG";
  return { ok: true, rowH: row.height, txtH: txt ? txt.height : null };
})()
