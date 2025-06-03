import { test, expect } from '@playwright/test';

test('Laravel homepage loads', async ({ page }) => {
  await page.goto('http://localhost:8000');
  await expect(page).toHaveTitle(/Laravel/i);
});
