# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Repo rules

- **Keep `README.md` current.** It is the public front page. Whenever a project is added, renamed or removed, or its main print file, build command or requirements change, update the projects table and the build section in the same change.
- **ALWAYS give every project preview images and its own `README.md` that shows them.** No exceptions: this applies to every new project and every design change, with no need to ask first.
  - Each project folder has a `render.scad` and a `make images` target that render preview PNGs into `img/` straight from the source. Never use screenshots or hand-made images.
  - The project `README.md` embeds those PNGs at the top, then covers what the project is, how to print it, the hardware and the fit tests.
  - When starting a project, set up `render.scad`, `make images`, `img/*.png` and the README before calling it done, and add a thumbnail row to the root README.
  - Whenever a change alters the geometry, re-run `make images` and update the README in the same change, then commit the PNGs with the `.scad` change. Fresh images and an up-to-date README are part of "done".
  - Look at each rendered PNG before committing it, and check that it shows the current design clearly. Renders need `--render` or an explicit `color()` on every part: the quick preview mode paints cut faces orange or yellow.
- **Public repo, non-commercial licence** (CC BY-NC-SA 4.0, see `LICENSE`). New projects fall under it, so don't add a separate licence per project.
- **Never commit third-party material:** other people's models (for example `trim-kit-case/ref/*`), meshes derived from them, or brand logo source files. They stay on the local disk.
- **`trim-kit-case/` is whitelisted in `.gitignore`.** Only the files listed there are tracked. To publish a new file from that folder, add a `!` line for it. The folder also holds local-only history: v4 `deburr_case.scad`, `Makefile.v4`, `DESIGN-v4.md` and older designs. Don't publish these.
- STL and 3MF files go through Git LFS (`.gitattributes`). Commit regenerated outputs together with the `.scad` change that produced them, so the print files never lag the source.
- Each project's `DESIGN.md` is its decision log. Append a dated section for each design change and fit-test result, giving the parameter names and values.

## Layout and build

One folder per project, each self-contained with its own `Makefile`, `.scad` sources and `DESIGN.md`. There is no top-level build.

```sh
cd trim-kit-case && make          # trim_case_print.3mf + body/lid _2color.3mf
cd trim-kit-case && make tests    # fit-test pieces
cd trim-kit-case && make images   # README pictures -> img/*.png (render.scad)
cd trim-kit-case && make check    # closed-halves overlap check -> .build/closed_check.stl
cd lens-wipe-box && make
cd desk-dial-pod && make && make test     # STLs; pytest geometry checks (tests/)
cd desk-dial-pod && make print            # desk_dial_pod.3mf (pack_plate.py, cap supports per object)
cd desk-dial-knob && make && make test     # STLs, each on its print face; pytest checks
cd desk-accent-case && make               # stacked + side-by-side STLs
cd <project> && make images               # README pictures -> img/*.png, in every project
openscad --backend=manifold -D 'part="lid"' -o out.stl trim_case.scad   # any single part
```

Always pass `--backend=manifold`: CGAL is far too slow for these models. Note that GNU make on macOS takes the first pattern rule that matches, so specific pattern rules such as `trim_case_clip_test_%.stl` must come before the generic `trim_case_%.stl`.

## OpenSCAD conventions

- **One file per design.** Parameters sit at the top and a `part = "..."` switch at the bottom selects what to render, including test pieces and check parts. The Makefile selects it with `-D 'part="name"'`.
- **Top-level assignments are evaluated in order.** A parameter that refers to one defined further down the file comes out `undef`, without an error: only a warning, and the geometry silently lands in the wrong place. Use literal values or define things in order, and check the warnings or `echo()` the value after changing a parameter.
- **Checks are part modes.** Each renders an `intersection()` that must come out empty, or overlap only where intended. An empty top-level object means pass.
  - `trim_case.scad`: `closed_check` (body vs. closed lid; the only allowed overlap is the seam at z = 17).
  - `swing_check` with `-D swing_a=N`: clear from 1 to 299°, tooth on the stop at 300.
  - Lid vs. the `lid_tools()` blade and handle models: only the clip squeezing the handle may overlap.
- Test pieces are `intersection()`s of the real part, so they always match the current design. They are labelled on the back with mirrored engraved text (`back_label`).

## trim-kit-case architecture

- **Frames:**
  - The lid frame is the lid as printed: z = 0 is its back, which is the bed face, and the hinge is at -x.
  - The closed frame is the body frame: z = 0 is the body bottom, and the hinge is at +x.
  - `to_closed()` and `to_lid()` both apply (x, y, z) -> (-x, y, H - z).
- **Fitted values from tests:** blade seat `snap_slot()` (Ø3.2 channel, 2.9 slit, Ø3.12 keyhole at the deep end, 0.8 lead-in), handle clip `clip_x` / `clip_sq = 0.3`, hinge M2 pilot 1.7 / clearance 2.3, stop `stop_a = 300`. Don't change these without a new fit test.
- **Two-colour inlays:** pockets are cut 0.6 deep into the bed face (0.4 for the logo), which is exactly 3 (or 2) layers at 0.2.
  - `part="inlays"` / `"body_inlays"` export the inlay solids.
  - `pack_2color.py` packs a half and its inlays into one two-part 3MF object (filament 1 / filament 2).
  - `pack_plate.py` lays several objects on one plate, with `--stack` for front-to-back and `--settings` to embed project settings.
- **Print file pipeline:**
  - `print_profile.py` flattens Bambu's system profiles (P2S 0.4, 0.20 Standard, PETG Matte) and applies the tuned overrides in `PROCESS_SET` / `MACHINE_SET`.
  - The Bambu Studio CLI slices a seed to merge them into `project_settings.config`. `print_profile.py --project` then sets colours and a 2×2 flush matrix.
  - `pack_plate.py --settings` embeds the result in `trim_case_print.3mf`.
- **Bambu CLI quirks:**
  - A 3MF with no project settings segfaults it (exit 139).
  - The output directory must already exist.
  - The bed type must be set (textured PEI), or it rejects the filament.
  - The flush matrix must be N×N for N filaments.
  - To verify the print file: `BambuStudio --slice 0 --outputdir DIR trim_case_print.3mf`, then read the time and grams from the G-code header.
- The logo inlay reads `ref/bambu-lab.svg`, which is local-only (see `ref/README.md`). Without it the body builds with no logo.
