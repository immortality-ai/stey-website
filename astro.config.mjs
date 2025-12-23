// @ts-check
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';

// https://astro.build/config
export default defineConfig({
  integrations: [tailwind({
    configFile: './tailwind.config.mjs',
  })],
  site: 'https://stey.app',
  output: 'static',
  build: {
    assets: 'assets',
  },
  compressHTML: true,
  vite: {
    build: {
      cssMinify: true,
    },
  },
});
