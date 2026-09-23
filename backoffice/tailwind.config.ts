import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{ts,tsx}', './components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        prolink: {
          primary: '#1A237E',
          secondary: '#00838F',
          accent: '#F57F17',
          success: '#2E7D32',
          danger: '#C62828',
          surface: '#F6F8FB',
          textPrimary: '#263238',
          textSecondary: '#607D8B',
          divider: '#E0E4EA',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Playfair Display', 'serif'],
      },
    },
  },
  plugins: [],
};
export default config;
