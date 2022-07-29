function edit-link
    if test $(count argv) != 1
        echo "Usage: edit-link SYMLINK"
        return 1
    end

    set file $argv[1]

    if ! test -L "$file"
        echo "$file is not a symbolic link"
        return 1
    end

    set tmp $(mktemp)
    cat "$file" > "$tmp"
    unlink "$file"
    mv "$tmp" "$file"
    "$EDITOR" "$file"
end
