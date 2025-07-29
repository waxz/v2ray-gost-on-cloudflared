cat << 'EOF' | tee -a $HOME/.bashrc

# gh_install vi/websocat websocat.x86_64-unknown-linux-musl
gh_install() {
  echo "Number of arguments: $#"
  echo "All arguments as separate words: $@"
  echo "All arguments as a single string: $*"

  if [[ $# -ne 3 ]]; then
    echo "Please set repo, arch, and filename"
    return 1
  fi

  local repo="$1"
  local arch="$2"
  local filename="$3"

  echo "Set repo: $repo, arch: $arch, filename: $filename"

  local url
  local count=0

  while [[ -z "$url" && $count -lt 5 ]]; do
    content=$(curl -s -L -H "Accept: application/vnd.github+json" "https://api.github.com/repos/$repo/releases")
    url=$(echo "$content" | jq -r --arg arch "$arch" '.[0] | .assets[] | .browser_download_url | select(endswith($arch))')
    count=$((count + 1))
  done

  if [[ -z "$url" ]]; then
    echo "Failed to find a valid download URL after $count attempts."
    return 1
  fi

  echo "Download URL: $url"
  wget -q "$url" -O "$filename" && echo "Downloaded $filename successfully." || echo "Failed to download $filename."
}


EOF

source $HOME/.bashrc
