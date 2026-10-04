#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
off=$(sed -nE 's/^[[:space:]]*([a-z_]+)[[:space:]]*=[[:space:]]*false[[:space:]]*$/\1/p' /etc/toggles.toml 2>/dev/null | tr '\n' ' ')
if [ -n "$off" ]; then
    echo "Switched off in /etc/toggles.toml: ${off% }"
fi
unset off
