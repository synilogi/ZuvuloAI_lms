import { expect, test } from '@playwright/test';

// REACT-001: every shared component renders at 1280/768/360 without page-level horizontal scroll or console
// errors, dialogs become bottom sheets on phones, and the table becomes cards below 640px.
test.describe('component gallery', () => {
  test('renders without overflow or console errors', async ({ page }) => {
    const errors: string[] = [];
    page.on('console', (message) => {
      if (message.type() === 'error') errors.push(message.text());
    });
    await page.goto('/__ui');
    await expect(page.getByRole('heading', { level: 1, name: 'Component gallery' })).toBeVisible();

    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);

    const width = page.viewportSize()!.width;
    if (width < 640) {
      await expect(page.getByRole('table', { name: 'Specimen table' })).toHaveCount(0);
      await expect(page.getByRole('list', { name: 'Specimen table' })).toBeVisible();
    } else {
      await expect(page.getByRole('table', { name: 'Specimen table' })).toBeVisible();
    }

    await page.getByRole('button', { name: 'Dialog', exact: true }).click();
    const dialog = page.getByRole('dialog', { name: 'Dialog' });
    await expect(dialog).toBeVisible();
    const box = (await dialog.boundingBox())!;
    const viewportHeight = page.viewportSize()!.height;
    if (width < 640) expect(Math.round(box.y + box.height)).toBe(viewportHeight);
    await page.keyboard.press('Escape');
    await expect(dialog).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Dialog', exact: true })).toBeFocused();

    for (const theme of ['Dark', 'Light']) {
      await page.getByRole('radio', { name: theme }).click();
      await expect(page.locator('html')).toHaveAttribute('data-theme', theme.toLowerCase());
    }
    expect(errors).toEqual([]);
  });
});
