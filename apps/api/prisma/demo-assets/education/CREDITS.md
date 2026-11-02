# Sample education catalogue: asset sources and licences

These files belong to the sample catalogue seeded by `npm run seed:education -w @syniastrolms/api`. The
course text, quizzes, lectures and notes are original to this repository. Nothing was copied from
Utkarsh, Classplus or any other coaching app, and no image shows a logo, a branded cover or an
identifiable teacher. `sources.json` holds the same image records in machine-readable form. The seed
appends each image's credit to its course description, so the attribution also appears in the app.

## Course covers (`covers/*.webp`)

The source for each cover is a Wikimedia Commons file. Licence data was read from the Commons API on
2026-10-13. Each file was cropped to 16:9, resized to 1280×720 and encoded as WebP with
`tools/crop16x9.py`. Adapted CC BY-SA files keep that licence.

| File | Image | Author | Licence |
| --- | --- | --- | --- |
| `ras-prelims.webp` | [Hawa Mahal in Jaipur India](https://commons.wikimedia.org/wiki/File:Hawa_Mahal_in_Jaipur_India.jpg) | Wander-earth | CC BY-SA 4.0 |
| `rajasthan-gk.webp` | [Chittor Fort, Chittorgarh](https://commons.wikimedia.org/wiki/File:Chittor_Fort_-_Chittorgarh_-_Rajasthan_-_005.jpg) | Rupeshsarkar | CC BY-SA 4.0 |
| `indian-polity.webp` | [Sansad Bhavan, Delhi](https://commons.wikimedia.org/wiki/File:Sansad_Bhavan,_Delhi,_BNK.jpg) | Nikhilb239 | CC BY-SA 4.0 |
| `ssc-gd.webp` | [The waving Indian flag](https://commons.wikimedia.org/wiki/File:The_waving_Indian_flag.jpg) | Sisheer Philip | CC BY-SA 4.0 |
| `reasoning.webp` | [Chess pieces close up](https://commons.wikimedia.org/wiki/File:Chess_pieces_close_up.jpg) | Aaaatu | CC BY-SA 4.0 |
| `quant.webp` | [20th Century Small Wooden Abacus](https://commons.wikimedia.org/wiki/File:20th_Century_Small_Wooden_Abacus.jpg) | Deinodactyla | CC0 |
| `reet-level-2.webp` | [Mathematics on a blackboard](https://commons.wikimedia.org/wiki/File:Mathematics_(cryptography)_on_a_blackboard.jpg) | David Malone | CC BY 4.0 |
| `patwari.webp` | [Agriculture Rajasthan India, mustard crop](https://commons.wikimedia.org/wiki/File:Agriculture_Rajasthan_India_-_2009_Mustard_crop.jpg) | Trees ForTheFuture | CC BY 2.0 |
| `class-10-maths.webp` | [Set of polygons, Musée des arts et métiers](https://commons.wikimedia.org/wiki/File:Set_of_polygons_-_Mus%C3%A9e_des_arts_et_m%C3%A9tiers_-_Inv_3142.jpg) | Poulpy | CC BY-SA 4.0 |
| `class-10-science.webp` | [Test tube rack in front of a chemistry book](https://commons.wikimedia.org/wiki/File:Close-up_of_a_test_tube_rack_in_front_of_a_chemistry_book_with_microscope_in_a_blurry_background.jpg) | Shixart1985 | CC BY 2.0 |
| `class-12-physics.webp` | [Newton's Cradle](https://commons.wikimedia.org/wiki/File:Newton%27s_Cradle_(15221366308).jpg) | Sheila Sund | CC BY 2.0 |
| `class-12-chemistry.webp` | [Vintage laboratory glassware, Gdansk University of Technology](https://commons.wikimedia.org/wiki/File:Vintage_laboratory_glassware_at_Chemical_Faculty,_Gdansk_University_of_Technology,_Poland.jpg) | LukaszKatlewa | CC BY-SA 4.0 |
| `english-grammar.webp` | [Library stacks of books and bookshelf](https://commons.wikimedia.org/wiki/File:Library_stacks_of_books_and_bookshelf.jpg) | Shixart1985 | CC BY 2.0 |

## Slide lectures (`lectures/*.mp4`)

Original: silent slide lectures of 36–48 seconds at 1280×720 H.264. The slide text is in
`tools/lectures.json`. `tools/slides.py` renders the slides (Pillow, macOS Arial) and
`tools/slideshow.swift` encodes them (AVFoundation).

## Study notes (PDF)

The seed writes these itself from text in `prisma/educationCatalog.ts`. They are original.

## Regenerating

```sh
python3 tools/crop16x9.py RAW covers '{"<key>": 0.5, ...}'   # RAW/<key>.jpg = Commons 1920 px renditions; needs Pillow + cwebp
python3 tools/slides.py tools/lectures.json SLIDES
swift tools/slideshow.swift lectures/<key>.mp4 12 SLIDES/<key>-*.png
```
