###############################################################################
# Misc
###############################################################################
set -o vi
export EDITOR=vim

# Enable color support for ls
if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
    alias ls='ls --color=auto'
fi


###############################################################################
# Tools
###############################################################################
extract () {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvjf $1    ;;
           *.tar.gz)    tar xvzf $1    ;;
           *.bz2)       bunzip2 $1     ;;
           *.rar)       unrar x $1       ;;
           *.gz)        gunzip $1      ;;
           *.tar)       tar xvf $1     ;;
           *.tbz2)      tar xvjf $1    ;;
           *.tgz)       tar xvzf $1    ;;
           *.zip)       unzip $1       ;;
           *.Z)         uncompress $1  ;;
           *.7z)        7z x $1        ;;
           *)           echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
 }


###############################################################################
# Prompt
###############################################################################
BLACK="\[\033[0;30m\]"
DARK_GRAY="\[\033[1;30m\]"
LIGHT_GRAY="\[\033[0;37m\]"
BLUE="\[\033[0;34m\]"
LIGHT_BLUE="\[\033[1;34m\]"
GREEN="\[\033[0;32m\]"
LIGHT_GREEN="\[\033[1;32m\]"
CYAN="\[\033[0;36m\]"
LIGHT_CYAN="\[\033[1;36m\]"
RED="\[\033[0;31m\]"
LIGHT_RED="\[\033[1;31m\]"
PURPLE="\[\033[0;35m\]"
LIGHT_PURPLE="\[\033[1;35m\]"
BROWN="\[\033[0;33m\]"
YELLOW="\[\033[1;33m\]"
WHITE="\[\033[1;37m\]"
DEFAULT_COLOR="\[\033[00m\]"

export PS1="\`if [ \$? = 0 ];
    then
        echo -e '\n$GREEN[$DEFAULT_COLOR\t$GREEN - $DEFAULT_COLOR\u$GREEN@$DEFAULT_COLOR\H$GREEN] {$DEFAULT_COLOR\w$GREEN}\n\\$ $DEFAULT_COLOR';
    else
        echo -e '\n$RED[$DEFAULT_COLOR\t$RED - $DEFAULT_COLOR\u$RED@$DEFAULT_COLOR\H$RED] {$DEFAULT_COLOR\w$RED}\n\\$ $DEFAULT_COLOR';
    fi;
     \`"



###############################################################################
# Aliases
###############################################################################
# Directory listings
alias ll='ls -alh'
alias la='ls -A'
alias l='ls -CFlh'

# Directory navigation aliases
alias ..='cd ..'
alias 2..='cd ../..'
alias 3..='cd ../../..'
alias 4..='cd ../../../..'

# 'tcurl' to print out timing information from a cURL request
read -r -d '' FORMAT <<'EOF'

*****************************************************
*              TIMING/SIZE INFORMATION              *
*****************************************************

 time_namelookup: %{time_namelookup} seconds
 time_connect: %{time_connect} seconds
 time_appconnect: %{time_appconnect} seconds
 time_pretransfer: %{time_pretransfer} seconds
 time_redirect: %{time_redirect} seconds
 time_starttransfer: %{time_starttransfer} seconds
 time_total:%{time_total} seconds

 speed_download: %{speed_download}
 speed_upload: %{speed_upload}

 size_download: %{size_download} bytes
 size_upload: %{size_upload} bytes
 size_header: %{size_header} bytes
 size_request: %{size_request} bytes

 num_connects: %{num_connects}
 num_redirects: %{num_redirects}

*****************************************************

EOF
alias tcurl="curl -w'${FORMAT}'"
alias icurl='curl -s -o /dev/null -D -'
