/// How sure the drawing of a historic feature or event is (P10; P15's map
/// sequence uses it too). Kept free of dart:ui so the content validator can
/// load the catalogs that name it.
enum Certainty { surviving, traced, approximate, conjectural }
