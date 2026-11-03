import { withMermaid } from 'vitepress-plugin-mermaid'
import apiSidebar from '../api/_sidebar.json'

// one sidebar for every page but the API, in reading order: the "previous" and "next" links at the bottom of a page
// follow it, so the documentation reads from the first page to the last
const docs = [
  {
    text: 'Start here',
    items: [
      { text: 'Introduction', link: '/guide/' },
      { text: 'Installation', link: '/guide/installation' },
    ],
  },
  {
    text: 'Tutorial',
    items: [
      { text: 'Overview',                     link: '/manual/' },
      { text: '1. A first document',          link: '/manual/tutorial/01-first-document' },
      { text: '2. Reading the case file',     link: '/manual/tutorial/02-reading' },
      { text: '3. Walking the tree',          link: '/manual/tutorial/03-walking' },
      { text: '4. Editing and saving',        link: '/manual/tutorial/04-editing' },
      { text: '5. Writing the results',       link: '/manual/tutorial/05-writing' },
      { text: '6. Large outputs: the index',  link: '/manual/tutorial/06-index' },
      { text: '7. Your own handler',          link: '/manual/tutorial/07-handler' },
      { text: '8. Namespaces',                link: '/manual/tutorial/08-namespaces' },
      { text: '9. Robust input and text',     link: '/manual/tutorial/09-robust' },
    ],
  },
  {
    text: 'Recipes',
    items: [
      { text: 'Cookbook', link: '/manual/cookbook' },
    ],
  },
  {
    text: 'Reference',
    items: [
      { text: 'Feature map',     link: '/guide/features' },
      { text: 'Parsing',         link: '/guide/parsing' },
      { text: 'Querying',        link: '/guide/querying' },
      { text: 'Typed values',    link: '/guide/values' },
      { text: 'Editing',         link: '/guide/editing' },
      { text: 'Writing',         link: '/guide/writing' },
      { text: 'The index',       link: '/guide/index-files' },
      { text: 'Streaming parser', link: '/guide/events' },
      { text: 'Namespaces',      link: '/guide/namespaces' },
      { text: 'Regular expressions', link: '/guide/regex' },
      { text: 'Single tags',     link: '/guide/tags' },
      { text: 'Methods summary', link: '/guide/api-reference' },
    ],
  },
  {
    text: 'Project',
    items: [
      { text: 'Upgrading',         link: '/guide/upgrading' },
      { text: 'Changelog',         link: '/guide/changelog' },
      { text: 'Contributing',      link: '/guide/contributing' },
      { text: 'Coverage analysis', link: '/guide/coverage-analysis' },
    ],
  },
]

export default withMermaid({
  title: 'FoXy Documentation',
  base: '/FoXy/',
  head: [['link', { rel: 'icon', type: 'image/svg+xml', href: '/FoXy/logo.svg' }]],
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
    logo: '/logo.svg',
    siteTitle: 'FoXy',
    socialLinks: [{ icon: 'github', link: 'https://github.com/Fortran-FOSS-Programmers/FoXy' }],
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Start here', link: '/guide/', activeMatch: '^/guide/(index|installation)' },
      { text: 'Tutorial', link: '/manual/tutorial/01-first-document', activeMatch: '^/manual/(index|tutorial/)' },
      { text: 'Cookbook', link: '/manual/cookbook', activeMatch: '^/manual/cookbook' },
      {
        text: 'Reference',
        link: '/guide/features',
        activeMatch: '^/guide/(features|parsing|querying|values|editing|writing|index-files|events|namespaces|regex|tags|api-reference)',
      },
      { text: 'API', link: '/api/' },
      {
        text: 'Project',
        items: [
          { text: 'Changelog',         link: '/guide/changelog' },
          { text: 'Contributing',      link: '/guide/contributing' },
          { text: 'Coverage analysis', link: '/guide/coverage-analysis' },
        ],
      },
    ],
    sidebar: {
      '/guide/': docs,
      '/manual/': docs,
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
