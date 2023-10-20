inputs: _: prev:
{
  playit-cli = prev.callPackage ../pkgs/playit-agent { inherit (inputs) playit-agent-source crane; };
}
