# Meku — transparent cutout

Output: `assets/images/meku_cutout.png`.
Tool: built-in imagegen, edit mode, `transparent_background: true`.
Input: user-supplied sheet `codex-clipboard-03d6d8b9-ba83-410f-bb1f-11eb80d015c5.png`.

Final prompt:

> Use case: background-extraction. Edit target: the attached reference sheet of eight Meku fox poses. Extract ONLY the first fox in the TOP LEFT, the cheerful jumping fox with its forepaws on its cheeks and tail to the right. Produce ONE standalone production PNG mascot asset with actual transparent alpha background. Preserve its exact original character design, colors, face, pose, silhouette and flat illustration style. Keep both ears, the complete fluffy tail, every paw and both feet completely inside the frame. Remove the white sheet background, all seven other foxes, and the small gray ground line/shadow below the first fox. Preserve the pale pink/white interior ear and facial fur and the white eyes as opaque parts of the fox. Center the whole fox with balanced tight transparent padding of roughly 5 percent around its full silhouette, so it fills a square icon naturally. Clean antialiased edges, no white halo, no checkerboard baked into the pixels, no text, no frame. This is a cutout of the existing first fox, not a redesign.

The original sheet remains in `assets/images/meku.png`. The component displays
the whole standalone image with `BoxFit.contain`; it no longer uses OverflowBox
or positional clipping. Alpha and transparent corners were checked before use.
