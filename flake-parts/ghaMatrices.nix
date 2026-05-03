{
  inputs,
  flake,
  ...
}:
{
  flake.ghaMatrices = {
    cache =
      (inputs.nix-github-actions.lib.mkGithubMatrix {
        checks = flake.ciJobs;
        attrPrefix = "ciJobs";
      }).matrix;
  };
}
