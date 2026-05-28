module.exports = {
  content: [
    './*.html',
    './*.md',
    './_layouts/**/*.html',
    './_includes/**/*.html',
    './_posts/**/*.md',
    './blog/**/*.html',
    './compare/**/*.{html,md}',
    './de/**/*.{html,md}',
    './es/**/*.{html,md}',
    './fr/**/*.{html,md}',
    './nl/**/*.{html,md}',
    './pt/**/*.{html,md}',
    './docs/**/*.{html,md}',
    './assets/js/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        'pool-blue': '#53849F',
        'pool-dark': '#567A8C',
        'pool-green': '#53849F',
        'pool-cyan': '#567A8C',
        'pool-surface': '#FEFEFE',
        'pool-section': '#F7F9FC',
        'pool-light': '#F7FBFD',
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'SF Pro Display', 'Segoe UI', 'Roboto', 'Helvetica Neue', 'Arial', 'sans-serif'],
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
};
