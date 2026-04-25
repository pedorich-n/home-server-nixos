{
  fetchPackwizModpack,
}:
let
  ref = "7de99d0f0d4211f9e1a576372cc63edfeb412595";
  version = "0.0.12";
in
fetchPackwizModpack {
  pname = "monkegeddoon";
  inherit version;
  url = "https://gitlab.com/pablo_peraza/monke-abyss/-/raw/${ref}/pack.toml";
  packHash = "sha256-VAYmFYFrHk48BhL5avlOXor37RF98Ia4lAlKIiFknFc=";
}
