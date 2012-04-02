# Class: wordpress
#
# This module manages wordpress
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]
define wordpress(
    $ensure = '3.3.1',
    $path,
    $domain,
    $backups = 'false') {

    if $ensure == 'purged'

        # Remove

    else

        # exec svn checkout onlyif wordpress file doesn't exist

        # exec svn update only if version number doesn't match $ensure

    end


    }
}
