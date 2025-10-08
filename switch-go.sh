#!/bin/bash

# File: ~/go-versions/switch-go.sh

GO_VERSIONS_DIR="$HOME/go-versions"

# Function to list available versions
list_versions() {
    echo "Available Go versions:"
    for version in $(ls -d $GO_VERSIONS_DIR/go*/ | xargs -n1 basename); do
        if [ -L "$GO_VERSIONS_DIR/current" ] && [ "$(readlink -f $GO_VERSIONS_DIR/current)" = "$GO_VERSIONS_DIR/$version" ]; then
            echo "  * $version (active)"
        else
            echo "  - $version"
        fi
    done
}

# Function to switch version
switch_version() {
    local version=$1
    local version_path="$GO_VERSIONS_DIR/$version"
    
    if [ ! -d "$version_path" ]; then
        echo "Error: Version $version not found!"
        list_versions
        return 1
    fi
    
    # Remove existing symlink
    rm -f "$GO_VERSIONS_DIR/current"
    
    # Create new symlink
    ln -s "$version_path" "$GO_VERSIONS_DIR/current"
    
    # Update PATH in bashrc
    if grep -q "go-versions/current" ~/.bashrc; then
        sed -i 's|export PATH=.*go-versions/current/bin|export PATH=$PATH:'$GO_VERSIONS_DIR'/current/bin|' ~/.bashrc
    else
        echo "export PATH=\$PATH:$GO_VERSIONS_DIR/current/bin" >> ~/.bashrc
        echo "export GOROOT=$GO_VERSIONS_DIR/current" >> ~/.bashrc
    fi
    
    echo "Switched to Go $version"
    source ~/.bashrc
    go version
}

# Function to add new version
add_version() {
    local version=$1
    local tar_file="go$version.linux-amd64.tar.gz"
    
    cd "$GO_VERSIONS_DIR"
    wget "https://go.dev/dl/$tar_file"
    tar -xzf "$tar_file"
    mv go "go$version"
    rm "$tar_file"
    
    echo "Added Go $version successfully"
}

case "$1" in
    list)
        list_versions
        ;;
    use)
        if [ -z "$2" ]; then
            echo "Usage: $0 use <version>"
            exit 1
        fi
        switch_version "$2"
        ;;
    add)
        if [ -z "$2" ]; then
            echo "Usage: $0 add <version>"
            exit 1
        fi
        add_version "$2"
        ;;
    current)
        if [ -L "$GO_VERSIONS_DIR/current" ]; then
            current_version=$(basename $(readlink -f "$GO_VERSIONS_DIR/current"))
            echo "Current Go version: $current_version"
            go version
        else
            echo "No active Go version"
        fi
        ;;
    *)
        echo "Go Version Manager"
        echo "Usage: $0 {list|use <version>|add <version>|current}"
        echo ""
        echo "Examples:"
        echo "  $0 list               List available versions"
        echo "  $0 use go1.18         Switch to Go 1.18"
        echo "  $0 add go1.21.0       Download and add Go 1.21.0"
        echo "  $0 current            Show current active version"
        exit 1
        ;;
esac