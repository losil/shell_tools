#!/usr/bin/env bash

# script installs und updates software from online sources like GitHub

set -e

# VAR section
INSTALL_DIR="${HOME}/.local/bin/"
KUBECTL_VERSION='v1.23.10'
OS_PACKAGES=(
    "bat"
    "exa"
    "fzf"
    "jq"
    "python3-pip"
    "zsh"
)

DEB_OS_PACKAGES=(
    "git"
)

RPM_OS_PACKAGES=(
    "git-core"
)

# functions

function ensure_install_dir() {
    # creates install-dir if needed
    mkdir -p ${INSTALL_DIR}
}

function get_latest_github_release() {
    # fetches latest release tag from a GitHub project
    project=${1}
    curl -L -s -H 'Accept: application/json' "https://github.com/${project}/releases/latest" | jq -r ."tag_name"
}

function download_github_release() {
    # downloades release from github project
    project=${1}
    version=${2}
    filename=${3}
    dir=${4}

    echo "INFO - Downloading k9s software from GitHub"
    wget -q -P "${dir}" "https://github.com/${project}/releases/download/${latest_version}/${filename}"
}

function install_os_packages() {

    DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

    if [ "${DISTRO}" = '"Ubuntu"' ]; then

        echo "INFO - Installing OS packages"
        sudo apt-get --quiet update
        sudo apt-get --quiet --yes install ${OS_PACKAGES[*]} ${DEB_OS_PACKAGES[*]}
    elif [ "${DISTRO}" = '"openSUSE Leap"' ]; then
        echo "INFO - Installing OS pacakges"
        sudo zypper --non-interactive install ${OS_PACKAGES[*]} ${RPM_OS_PACKAGES[*]}
    fi
}

function kubectl() {
    # install kubectl from kubernetes repo
    echo "INFO - installing kubectl"
    wget -q -P "${INSTALL_DIR}" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x "${INSTALL_DIR}/kubectl"
    echo "SUCCESS - successfully installed kubectl"
}

function k9s() {
    # install k9s software from github
    # https://github.com/derailed/k9s/releases/download/v0.26.7/k9s_Linux_x86_64.tar.gz
    project='derailed/k9s'
    filename='k9s_Linux_x86_64.tar.gz'
    latest_version=$(get_latest_github_release "${project}")
    dir=$(mktemp -d)

    download_github_release "${project}" "${version}" "${filename}" "${dir}"

    echo "INFO - installing k9s software"
    tar xfz "${dir}/${filename}" --directory "${dir}"
    cp "${dir}/k9s" "${INSTALL_DIR}"

    rm -rf "$dir"
    echo "SUCCESS - installed k9s"
}

function kubectx() {
    # install kubectx plugin
    # https://github.com/ahmetb/kubectx/releases/kubectx_v0.9.4_linux_x86_64.tar.gz

    project='ahmetb/kubectx'
    latest_version=$(get_latest_github_release "${project}")
    filename="kubectx_${latest_version}_linux_x86_64.tar.gz"
    dir=$(mktemp -d)

    download_github_release "${project}" "${version}" "${filename}" "${dir}"

    echo "INFO - installing kubectx software"
    tar xfz "${dir}/${filename}" --directory "${dir}"
    cp "${dir}/kubectx" "${INSTALL_DIR}"

    rm -rf "$dir"
    echo "SUCCESS - installed kubectx"
}

function kubens() {
    # install kubens plugin
    # https://github.com/ahmetb/kubectx/releases/kubens_v0.9.4_linux_x86_64.tar.gz

    project='ahmetb/kubectx'
    latest_version=$(get_latest_github_release "${project}")
    filename="kubens_${latest_version}_linux_x86_64.tar.gz"
    dir=$(mktemp -d)

    download_github_release "${project}" "${version}" "${filename}" "${dir}"

    echo "INFO - installing kubens software"
    tar xfz "${dir}/${filename}" --directory "${dir}"
    cp "${dir}/kubens" "${INSTALL_DIR}"

    rm -rf "$dir"
    echo "SUCCESS - installed kubens"
}

function oh_my_zsh() {
    # install oh_my_zsh shell and powerlevel10k style
    if [ ! -d "${HOME}/.oh-my-zsh" ] && [ -f "/bin/zsh" ]; then
        # installing oh my zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

        # installing powerlevel10k
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
        #ZSH_THEME="powerlevel10k/powerlevel10k"
        sed -i -e "s/ZSH_THEME=.*/ZSH_THEME=\"powerlevel10k\/powerlevel10k\"/g" "${HOME}/.zshrc"
    fi
}

function zsh_plugins() {
    # installs zsh plugins if oh-my-zsh is already installed

    if [ -d "${HOME}/.oh-my-zsh" ]; then
        if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
            echo "INFO - Updating oh-my-zsh autosuggestions-plugin"
            git -C "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" pull --quiet
        else
            echo "INFO - Installing oh-my-zsh autosuggestions-plugin"
            git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" --quiet
        fi

        if [ -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
            echo "INFO - Updating oh-my-zsh zsh-syntax-highlighting"
            git -C "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" pull --quiet
        else
            echo "INFO - Installing oh-my-zsh zsh-syntax-highlighting"
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" --quiet
        fi
    fi
}

function main() {
    ensure_install_dir
    install_os_packages
    kubectl
    k9s
    kubectx
    kubens
    oh_my_zsh
    zsh_plugins
}

main
