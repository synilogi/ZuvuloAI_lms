/// The build flavor an entry point was compiled for.
///
/// Each `main_<flavor>.dart` passes its own value; the environment values themselves come from
/// `--dart-define-from-file=config/<flavor>.json` (modules.md §24).
enum Flavor { dev, staging, prod }
