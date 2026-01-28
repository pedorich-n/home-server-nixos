{
  config,
  lib,
  ...
}:
let

  mkMbsyncEntry =
    {
      account,
      patterns ? [ "*" ],
      tlsType ? "IMAPS",
    }:
    let
      email = config.sops.placeholder."mbsync/accounts/${account}/email";
    in
    ''
      IMAPAccount ${email}
      Host ${config.sops.placeholder."mbsync/accounts/${account}/imap"}
      User ${email}
      Pass ${config.sops.placeholder."mbsync/accounts/${account}/password"}
      TLSType ${tlsType}

      IMAPStore ${email}-remote
      Account ${email}

      MaildirStore ${email}-local
      SubFolders Verbatim
      # The trailing "/" is important
      Path /mnt/store/mail/archive/${email}/
      Inbox /mnt/store/mail/archive/${email}/Inbox

      Channel ${email}
      Far :${email}-remote:
      Near :${email}-local:
      Patterns ${lib.concatStringsSep " " patterns}
      # Automatically create missing mailboxes locally
      Create Near
      # Never delete mail locally
      Expunge None
      # Only pull changes from the remote server
      Sync Pull
      # Preserve the original arrival date when copying messages
      CopyArrivalDate yes
      # Save the synchronization state files in the relevant directory
      SyncState *
    '';

  gmailPatterns = [
    "*"
    "![Gmail]*"
    ''"[Gmail]/Sent Mail"''
    ''"[Gmail]/Starred"''
    ''"[Gmail]/All Mail"''
    ''"[Gmail]/Trash"''
  ];

  accounts = [
    {
      account = "email_1";
      patterns = gmailPatterns;
    }
    {
      account = "email_2";
      patterns = gmailPatterns;
    }
    {
      account = "email_3";
      patterns = gmailPatterns;
    }
    {
      account = "email_4";
      patterns = [
        "*"
        "!Junk"
        "!Spam"
      ];
      tlsType = "STARTTLS";
    }
  ];
in
{
  sops.templates = {
    "mbsyncrc" = {
      content = lib.concatMapStringsSep "\n\n" mkMbsyncEntry accounts;
    };
  };

}
