#!/bin/bash

clone_repo="True"
if [ -z "${1}" ]; then
    clone_url="https://git.popcorntime.io/stash/scm/pt/popcorn-app.git"
elif [ "${1}" = "ssh" ]; then
    clone_url="ssh://git@git.popcorntime.io/pt/popcorn-app.git"
else
    clone_url="${1}"
fi
clone_command () { 
    git clone ${clone_url} ${dir} && 
    echo "Cloned Popcorn Time successfully" || 
    echo "Popcorn Time encountered an error and could not be cloned" && exit 1; 
}

if [ -e ".git/config" ]; then
    dat=`cat .git/config | grep 'url'`
    case ${dat} in *popcorn-app*)
        echo "You appear to be inside of a Popcorn Time repository already, not cloning"
        clone_repo="False"
        ;;
    *)   
        try="True"
        tries=0
        while [ "${try}" = "True" ]; do
            read -p "Looks like we are inside a git repository, do you wish to clone inside it? (yes/no) [no] " rd_cln
            if [ -z "${rd_cln}" ]; then 
                rd_cln='no'
            fi
            tries=$((${tries}+1))
            if [ "${rd_cln}" = "yes" ] || [ "${rd_cln}" = "no" ]; then
                try="False"
            elif [ "$tries" -ge "3" ]; then
                echo "No valid input, exiting"
                exit 1
            else
                echo "Not a valid answer, please try again"
            fi
        done
        if [ "$rd_cln" = "no" ]; then
            echo "You appear to be inside of a Popcorn Time repository already, not cloning"
            clone_repo="False"
        else
            echo "You've chosen to clone inside the current directory"
        fi
        ;;
    esac
fi
if [ "${clone_repo}" = "True" ]; then
    echo "Cloning Popcorn Time"
    read -p "Where do you wish to clone popcorn time to? [popcorn-app] " dir
    if [ -z "${dir}" ]; then 
        dir='popcorn-app'
    elif [ "${dir}" = "/" ]; then
        dir='popcorn-app'
    fi
    if [ ! -d "${dir}" ]; then
        clone_command
        
    else
        try="True"
        tries=0
        while [ "$try" = "True" ]; do
            read -p "Directory ${dir} already exists, do you wish to delete it and redownload? (yes/no) [no] " rd_ans
            if [ -z "${rd_ans}" ]; then 
                rd_ans='no'
            fi
            tries=$((${tries}+1))
            if [ "${rd_ans}" = "yes" ] || [ "${rd_ans}" = "no" ]; then
                try="False"
            elif [ "$tries" -ge "3" ]; then
                echo "No valid input, exiting"
                exit 1
            else
                echo "Not a valid answer, please try again"
            fi
        done
        if [ "${rd_ans}" = "yes" ]; then
            echo "Removing old directory"
            if [ "${dir}" != "." ] || [ "${dir}" != "$PWD" ]; then
                echo "Cleaning up from inside the destination directory"
                sudo rm -rf ${dir}/*
            else
                echo "Cleaning up from outside the destination directory"
                sudo rm -rf ${dir}
            fi
            clone_command
        else
            echo "Directory already exists and you've chosen not to clone again"
        fi
    fi
fi
try="True"
tries=0
while [ "${try}" = "True" ]; do
    read -p "Do you wish to install the required dependencies for Popcorn Time and setup for building? (yes/no) [yes] " rd_dep
    if [ -z "${rd_dep}" ]; then 
        rd_dep="yes"
    fi
    tries=$((${tries}+1))
    if [ "${rd_dep}" = "yes" ] || [ "${rd_dep}" = "no" ]; then
        try="False"
    elif [ "$tries" -ge "3" ]; then
        echo "No valid input, exiting"
        exit 1
    else
        echo "Not a valid answer, please try again"
    fi
done
if [ "${rd_dep}" = "yes" ]; then
    if [ -z "${dir}" ]; then
        dir="."
    fi
    echo "Installing global dependencies"
    sudo npm install -g bower grunt-cli &&
    cd ${dir} &&
    echo "Global dependencies installed successfully!" ||
    echo "Global dependencies encountered an error while installing" && exit 1

    echo "Installing local dependencies"
    sudo npm install &&
    sudo chown -R $USER . &&
    sudo chown -R $USER ~/.cache &&
    echo "Local dependencies installed successfully!" ||
    echo "Local dependencies encountered an error while installing" && exit 1

    echo "Setting up Bower"
    bower install && 
    echo "Bower successfully installed" ||
    echo "Encountered an error while installing bower" && exit 1
    echo "Successfully setup for Popcorn Time"

fi
grunt build && 
echo "Popcorn Time built successfully!" && 
echo "Run 'grunt start' from inside the repository to launch the app" && 
echo "Enjoy!" || echo "Popcorn Time encountered an error and couldn't be built" && exit 1