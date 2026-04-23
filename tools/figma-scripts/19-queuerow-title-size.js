(async () => {
  // QueueRow primary text currently uses title/Large (22px). Too big — wraps
  // for "Putovnica · HR2184…" content. Drop to title/Medium (16px) which
  // matches the HTML mockup density and reads fine on mobile.

  const componentsPage = figma.root.children.find((p) => p.name === "Components");
  await figma.setCurrentPageAsync(componentsPage);

  for (const f of ["Regular", "Medium", "SemiBold"]) {
    await figma.loadFontAsync({ family: "Manrope", style: f });
  }

  const styles = await figma.getLocalTextStylesAsync();
  const titleMedium = styles.find((s) => s.name === "title/Medium");

  const qrSet = componentsPage.findOne(
    (n) => n.type === "COMPONENT_SET" && n.name === "QueueRow"
  );
  if (!qrSet) return { ok: false, error: "QueueRow not found" };

  let count = 0;
  for (const variant of qrSet.children) {
    // Primary text node — the one currently starting with "HR2184…"
    const texts = variant.findAll((n) => n.type === "TEXT");
    for (const t of texts) {
      if (t.characters === "HR2184…") {
        await figma.loadFontAsync(t.fontName);
        await t.setTextStyleIdAsync(titleMedium.id);
        count++;
      }
    }
  }

  return { ok: true, updated: count };
})()
