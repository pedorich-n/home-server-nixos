# Basically a mix of
# https://github.com/the-computer-club/lynx/blob/49a2a4ff4adfd9792c8097fb010076069819abff/flake-modules/deploy-rs/default.nix &
# https://github.com/serokell/deploy-rs/pull/269/files#diff-a29363f3de3f608cf01080e1c73bea2ac93897a5ae57c01bf3be916eb15f423e

# Hopefully https://github.com/serokell/deploy-rs/pull/269 gets merged soon, and I won't need this module
{ lib, ... }:
with lib;
let
  genericSettings = {
    options = {
      sshOpts = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = '' This is an optional list of arguments that will be passed to SSH. '';
      };

      sshUser = mkOption {
        type = types.str;
        default = "root";
        description = ''
          This is the user that the profile will be deployed to (will use sudo if not the same as above).
          If `sshUser` is specified, this will be the default (though it will _not_ default to your own username)
        '';
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = ''
          This is the user that deploy-rs will use when connecting.
          This will default to your own username if not specified anywhere
        '';
      };

      sudo = mkOption {
        type = types.str;
        default = "sudo -u";
        description = ''
          Which sudo command to use. Must accept at least two arguments:
          the user name to execute commands as and the rest is the command to execute
          This will default to "sudo -u" if not specified anywhere.
        '';
      };

      interactiveSudo = mkOption {
        type = types.bool;
        default = false;
      };

      magicRollback = mkOption {
        type = types.bool;
        default = true;
        description = ''
          There is a built-in feature to prevent you making changes that might render your machine unconnectable or unusuable,
          which works by connecting to the machine after profile activation to confirm the machine is still available,
          and instructing the target node to automatically roll back if it is not confirmed.
          If you do not disable magicRollback in your configuration (see later sections) or with the CLI flag,
          you will be unable to make changes to the system which will affect you connecting to it
          (changing SSH port, changing your IP, etc).
        '';
      };

      autoRollback = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If the previous profile should be re-activated if activation fails.
          This defaults to `true`
        '';
      };

      fastConnection = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Fast connection to the node.
          If this is true, copy the whole closure instead of letting the node substitute.
          This defaults to `false`
        '';
      };

      tempPath = mkOption {
        type = types.path;
        default = "/tmp";
        description = ''
          The path which deploy-rs will use for temporary files, this is currently only used by `magicRollback` to create an inotify watcher in for confirmations
          If not specified, this will default to `/tmp`
          (if `magicRollback` is in use, this _must_ be writable by `user`)
        '';
      };

      remoteBuild = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Build the derivation on the target system.
          Will also fetch all external dependencies from the target system's substituters.
          This default to `false`
        '';
      };

      activationTimeout = mkOption {
        type = types.int;
        default = 240;
        description = ''
          Timeout for profile activation.
          This defaults to 240 seconds.
        '';
      };

      confirmTimeout = mkOption {
        type = types.int;
        default = 30;
        description = ''
          Timeout for confirmation.
          This defaults to 30 seconds.
        '';
      };
    };
  };

  profileSettings = {
    options = {
      path = mkOption {
        default = { };
        description = ''
          A derivation containing your required software, and a script to activate it in `''${path}/deploy-rs-activate`
          For ease of use, `deploy-rs` provides a function to easily add the required activation script to any derivation
          Both the working directory and `$PROFILE` will point to `profilePath`
        '';
      };
    };
  };

  nodeSettings = {
    options = {
      hostname = mkOption {
        type = types.str;
        description = "The hostname of your server. Can be overridden at invocation time with a flag.";
      };

      profileOrder = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          An optional list containing the order you want profiles to be deployed.
          This will take effect whenever you run `deploy` without specifying a profile, causing it to deploy every profile automatically.
          Any profiles not in this list will still be deployed (in an arbitrary order) after those which are listed
        '';
      };

      profiles = mkOption {
        type = types.attrsOf profileModule;
        default = { };
        description = ''
          allows for lesser-privileged deployments,
          and the ability to update different things independently of each other.
          You can deploy any type of profile to any user, not just a NixOS profile to root.
        '';
      };
    };
  };

  nodesSettings = {
    options.nodes = mkOption {
      type = types.attrsOf nodeModule;
    };
  };

  profileModule = types.submoduleWith {
    modules = [ genericSettings profileSettings ];
  };

  nodeModule = types.submoduleWith {
    modules = [ genericSettings nodeSettings ];
  };

  rootModule = types.submoduleWith {
    modules = [ genericSettings nodesSettings ];
  };
in
{
  options.flake.deploy = mkOption {
    type = rootModule;
  };
}
