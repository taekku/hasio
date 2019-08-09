const presets = [
  [
    "@babel/env",
    {
      targets: {
        edge: "17",
        firefox: "60",
        chrome: "67",
        safari: "11.1",
        ie: "11",
        // "browsers": ["last 2 versions", "safari >= 7", "ie 9"]
      },
      useBuiltIns: "usage",
      debug: true,
    },
  ],
];

module.exports = { presets };