# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub, dockerTools }:
{
  mc-monitor = {
    pname = "mc-monitor";
    version = "0.15.3";
    src = fetchFromGitHub {
      owner = "itzg";
      repo = "mc-monitor";
      rev = "0.15.3";
      fetchSubmodules = false;
      sha256 = "sha256-sdSjMkewux6Pgsf3bssfRRMWURCjLbFZkn2qgFIoa8s=";
    };
    vendorHash = "sha256-q56mlGz6Qx+S3YRcYMI2a412Y0VeziUFvhQZOz3ifg4=";
  };
}
