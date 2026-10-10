import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://elsell.github.io',
  base: '/agent-execution-spec',
  integrations: [starlight({
    title: 'Agent Execution Spec',
    description: 'A minimal execution contract for discover-and-run agents. Draft for review.',
    social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/elsell/agent-execution-spec' }],
    editLink: { baseUrl: 'https://github.com/elsell/agent-execution-spec/edit/main/' },
    sidebar: [{ label: 'Specification', slug: '' }, { label: 'Sequence diagram', slug: 'sequence' }, { label: 'Unresolved details', slug: 'gaps' }],
    customCss: ['./src/styles/custom.css'],
    components: { Head: './src/components/Head.astro' },
  })],
});
