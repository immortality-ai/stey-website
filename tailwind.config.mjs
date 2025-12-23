/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      fontFamily: {
        serif: ['Instrument Serif', 'Georgia', 'serif'],
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      colors: {
        // Deep dark palette
        void: {
          DEFAULT: '#0a0a0a',
          50: '#171717',
          100: '#1a1a1a',
          200: '#262626',
          300: '#404040',
          400: '#525252',
          500: '#737373',
          600: '#a3a3a3',
          700: '#d4d4d4',
          800: '#e5e5e5',
          900: '#fafafa',
        },
        // Warm amber/gold accent
        ember: {
          DEFAULT: '#d4a574',
          50: '#fdf8f3',
          100: '#f5e6d3',
          200: '#e8c9a0',
          300: '#d4a574',
          400: '#c4864d',
          500: '#b06b35',
          600: '#8f512a',
          700: '#6d3d24',
          800: '#4a2a1a',
          900: '#2d1a10',
        },
        // Soft cream for text
        parchment: {
          DEFAULT: '#f5f0e8',
          muted: '#a39e93',
          dark: '#6b6660',
        },
      },
      animation: {
        'fade-in': 'fadeIn 1.2s ease-out',
        'fade-in-slow': 'fadeIn 2s ease-out',
        'rise': 'rise 1s ease-out',
        'rise-slow': 'rise 1.5s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        rise: {
          '0%': { opacity: '0', transform: 'translateY(30px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
};
