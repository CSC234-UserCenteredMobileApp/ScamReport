// scripts/capture-design.mjs
// Captures design screenshots + accessibility snapshots from the bundled HTML prototypes.
// Prerequisites: python -m http.server 8765 --bind 127.0.0.1  (run in Downloads folder)
import { chromium } from 'playwright';
import { writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SCREENSHOTS = path.join(ROOT, 'docs', 'design', 'screenshots');
const SNAPSHOTS   = path.join(ROOT, 'docs', 'design', 'snapshots');
const PORT = 8765;
const BASE = `http://localhost:${PORT}`;

const ROLES = ['user', 'admin', 'guest'];

const SCREENS = [
  'home', 'check-input', 'feed', 'report-detail', 'search',
  'submit-report', 'my-reports', 'alerts', 'announcement-detail',
  'me', 'privacy', 'terms', 'login', 'onboarding',
  'mod', 'admin-review', 'announcement-editor',
];

// Verdict tweak values → label in the segmented control → file suffix
const VERDICT_VARIANTS = [
  { value: 'scam',       label: 'Scam',  suffix: 'scam'       },
  { value: 'suspicious', label: 'Susp',  suffix: 'suspicious' },
  { value: 'safe',       label: 'Safe',  suffix: 'safe'       },
  { value: 'unknown',    label: '?',     suffix: 'unknown'    },
];

async function openTweaksPanel(page) {
  // Activate the TweaksPanel via the __activate_edit_mode protocol
  await page.evaluate(() => {
    window.dispatchEvent(new MessageEvent('message', {
      data: { type: '__activate_edit_mode' },
      origin: window.location.origin,
      source: window,
    }));
  });
  await page.waitForSelector('.twk-panel', { timeout: 5000 });
  await page.waitForTimeout(300);
}

async function selectScreen(page, screen) {
  // Use Playwright's selectOption on the TweaksPanel select
  await page.selectOption('select.twk-field', screen);
  // 'verdict' triggers runCheck() which has a ~1.5s loading state
  await page.waitForTimeout(screen === 'verdict' ? 2500 : 700);
}

// Click the verdict segment button in the STATE section of the TweaksPanel.
// Must use Playwright's real click (not JS element.click()) — the .twk-seg uses
// onPointerDown which requires genuine mouse events.
async function setVerdictVariant(page, label) {
  await page.locator('.twk-row')
    .filter({ hasText: 'Verdict' })
    .first()
    .locator('button', { hasText: label })
    .click();
  await page.waitForTimeout(400);
}

async function captureScreenshot(page, filePath) {
  await page.locator('.sr-app').first().screenshot({ path: filePath });
}

async function captureSnapshot(page, filePath) {
  const text = await page.evaluate(() => {
    const el = document.querySelector('.sr-app');
    return el ? el.innerText.trim() : '';
  });
  await writeFile(filePath, text, 'utf8');
}

const browser = await chromium.launch({ channel: 'chrome', headless: true });

for (const role of ROLES) {
  console.log(`\n▶ ${role}`);
  const page = await browser.newPage({ viewport: { width: 860, height: 960 } });
  await page.goto(`${BASE}/${role}.html`);
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(1500);

  await openTweaksPanel(page);

  const ssDir = path.join(SCREENSHOTS, role);
  const snDir = path.join(SNAPSHOTS, role);

  for (const screen of SCREENS) {
    process.stdout.write(`  ${screen}...`);
    await selectScreen(page, screen);
    await captureScreenshot(page, path.join(ssDir, `${screen}.png`));
    await captureSnapshot(page,    path.join(snDir, `${screen}.txt`));
    console.log(' done');
  }

  // Verdict variants — set STATE > Verdict segment THEN navigate so runCheck captures the right colour
  for (const v of VERDICT_VARIANTS) {
    process.stdout.write(`  verdict-${v.suffix}...`);
    await setVerdictVariant(page, v.label);
    await selectScreen(page, 'verdict');
    await captureScreenshot(page, path.join(ssDir, `verdict-${v.suffix}.png`));
    await captureSnapshot(page,    path.join(snDir, `verdict-${v.suffix}.txt`));
    console.log(' done');
  }

  await page.close();
}

await browser.close();
console.log('\n✓ 63 screenshots + 63 snapshots written.');
