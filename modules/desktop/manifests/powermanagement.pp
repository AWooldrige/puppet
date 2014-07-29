class desktop::powermanagement {

    package { ['cpufrequtils', 'indicator-cpufreq']:
        ensure => installed
    }

}
