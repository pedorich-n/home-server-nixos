{
  writeShellApplication,
  fd,
  coreutils,
  ...
}:
writeShellApplication {
  name = "clean-trash";

  runtimeInputs = [
    fd
    coreutils
  ];

  text = ''
    MARKER_DIR="''${MAIL_ROOT}/.trash-markers"
    DAYS="''${DAYS:-30}"

    mkdir -p "''${MARKER_DIR}"

    # Find all Trash directories
    fd --type directory '^Trash$' "''${MAIL_ROOT}" | while read -r trash_dir; do
        echo "Processing: ''${trash_dir}"
        
        # Use hash of relative path for unique marker subdirectory
        rel_path="''${trash_dir#"''${MAIL_ROOT}/"}"
        trash_hash=$(echo "''${rel_path}" | sha256sum | cut -d" " -f1)
        marker_subdir="''${MARKER_DIR}/''${trash_hash}"
        mkdir -p "''${marker_subdir}"
        
        # Create markers for new messages
        fd --type file . "''${trash_dir}/cur" "''${trash_dir}/new" 2>/dev/null | while read -r msg; do
            marker="''${marker_subdir}/''$(basename "''${msg}")"
            if [[ ! -f "''${marker}" ]]; then
               echo "Creating marker for new message: ''${msg}"
               touch "''${marker}"
            fi
        done
        
        # Find messages (markers) older than DAYS
        fd --type file --changed-before "''${DAYS}d" . "''${marker_subdir}" 2>/dev/null | while read -r marker; do
            msg_name=$(basename "''${marker}")

            echo "Deleting message: ''${msg_name} from ''${trash_dir}/cur and/or ''${trash_dir}/new"
            
            # Delete from both cur/ and new/
            rm -f "''${trash_dir}/cur/''${msg_name}" "''${trash_dir}/new/''${msg_name}"
            rm "''${marker}"
        done
    done

    echo "Finished cleaning all Trash folders older than $DAYS days"
  '';
}
