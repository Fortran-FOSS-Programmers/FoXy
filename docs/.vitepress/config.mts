import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

export default withMermaid({
  title: 'FoXy Documentation',
  base: '/FoXy/',
  markdown: {
    math: true,
    languages: ['fortran-free-form', 'fortran-fixed-form'],
    languageAlias: {
      'fortran': 'fortran-free-form',
      'f90': 'fortran-free-form',
      'f95': 'fortran-free-form',
      'f03': 'fortran-free-form',
      'f08': 'fortran-free-form',
      'f77': 'fortran-fixed-form',
    },
  },
  themeConfig: {
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Guide',
        items: [
          { text: 'About',         link: '/guide/' },
          { text: 'Features',      link: '/guide/features' },
          { text: 'Installation',  link: '/guide/installation' },
          { text: 'Usage',         link: '/guide/usage' },
          { text: 'API Reference', link: '/guide/api-reference' },
          { text: 'Contributing',      link: '/guide/contributing' },
          { text: 'Coverage Analysis', link: '/guide/coverage-analysis' },
          { text: 'Changelog',         link: '/guide/changelog' },
        ],
      },
      { text: 'API', link: '/api/' },
      { text: 'GitHub', link: 'https://github.com/Fortran-FOSS-Programmers/FoXy' },
    ],
    sidebar: {
      '/guide/': [
        {
          text: 'Introduction',
          items: [
            { text: 'About',    link: '/guide/' },
            { text: 'Features', link: '/guide/features' },
          ],
        },
        {
          text: 'Getting Started',
          items: [
            { text: 'Installation',  link: '/guide/installation' },
            { text: 'Usage',         link: '/guide/usage' },
            { text: 'API Reference', link: '/guide/api-reference' },
          ],
        },
        {
          text: 'Project',
          items: [
            { text: 'Contributing',      link: '/guide/contributing' },
            { text: 'Coverage Analysis', link: '/guide/coverage-analysis' },
            { text: 'Changelog',         link: '/guide/changelog' },
          ],
        },
      ],
      '/api/': [
        {
          text: 'API Reference',
          items: [
            { text: 'Overview', link: '/api/' },
          ],
        },
        ...apiSidebar,
      ],
    },
    search: {
      provider: 'local',
    },
  },
  mermaid: {},
  vite: {
    // Build with an explicit modern JS target so the docs compile regardless of
    // which mermaid/vitepress/esbuild versions npm resolves. Vite's default
    // es2020 target forces esbuild to down-level modern syntax (e.g. the
    // destructuring mermaid 11.16+ emits), which it refuses to do and the build
    // dies. es2022 needs no lowering and is within VitePress's browser floor.
    build: {
      target: 'es2022',
    },
    optimizeDeps: {
      include: ['mermaid'],
    },
  },
})
