define certbot::cert (
  String[1] $ensure = "installed",
  String[1] $domain = $title,
  String[1] $extraargs
) {

    require certbot

    if $ensure == 'installed' {
        exec { "issuing_certbot_cert_for_${domain}":
            creates => "/etc/letsencrypt/live/${domain}/privkey.pem",
            environment => [
                'AWS_SHARED_CREDENTIALS_FILE=/home/woolie/.aws/credentials',
                'AWS_PROFILE=ddns'
            ],
            command => "/usr/bin/certbot certonly --noninteractive --agree-tos -m certificates@wooldrige.co.uk --dns-route53 -d ${domain}${extraargs}" ,
            provider => "shell",
            tries => 3,
            try_sleep => 30,
            notify => Exec['reload-nginx']
        }
    }
    elsif $ensure == 'absent' {
        warning('Not implemented yet.')
    }
    else {
        warning('Not implemented yet.')
    }
}
