import * as assets from "hanami-assets";

/*
  Front-end builds are powered by esbuild (https://esbuild.github.io)
  and can be customized below. Read more at: 
  https://guides.hanamirb.org/assets/customization/
*/

await assets.run({
  esbuildOptionsFn: (args, esbuildOptions) => {
    /* 
      You can modify or add to Hanami's preset esbuild options here.
      Use `args.watch` as a condition for different options for 
      `hanami assets compile` vs `hanami assets watch`.
    */

    return esbuildOptions;
  }
});
