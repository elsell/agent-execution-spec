import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const pages = ['', 'terminology/', 'reference/', 'sequence/', 'gaps/'];
for (const page of pages) {
  const html = readFileSync(`dist/${page}index.html`, 'utf8');
  const sidebar = html.match(/<nav\b[^>]*class="[^"]*\bsidebar\b[^\"]*"[^>]*>[\s\S]*?<\/nav>/)?.[0];
  assert.ok(sidebar, `Missing sidebar on ${page || 'home'}`);
  for (const destination of pages) {
    assert.ok(sidebar.includes(`href="/agent-execution-spec/${destination}"`), `Missing ${destination || 'home'} link on ${page || 'home'}`);
  }
  assert.ok(html.includes('id="sidebar-toggle"'), `Missing collapse control on ${page || 'home'}`);
}
console.log('All five pages include the full navigation and sidebar toggle.');
