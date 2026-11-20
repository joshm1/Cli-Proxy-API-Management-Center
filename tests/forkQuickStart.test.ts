import { expect, test } from 'bun:test';

test('the fork hides sponsored Quick Start and redirects old bookmarks', async () => {
  const layout = await Bun.file(
    new URL('../src/components/layout/MainLayout.tsx', import.meta.url)
  ).text();
  const routes = await Bun.file(new URL('../src/router/MainRoutes.tsx', import.meta.url)).text();

  expect(layout).not.toMatch(/quick.?start|apikey.?fun/i);
  expect(routes).not.toMatch(/apikey.?fun|SponsorQuickStartPanel/i);
  expect(routes.match(/['"]\/quick-start(?:\/\*)?['"]/g)).toHaveLength(1);
  expect(routes).toMatch(
    /path:\s*['"]\/quick-start\/\*['"],\s*element:\s*<Navigate to=['"]\/ai-providers['"]/
  );
});
