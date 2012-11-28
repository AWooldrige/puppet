#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
# Some snippets have used the following as a base:
# https://github.com/mattiasgeniar/varnish-3.0-configuration-templates

# This VCL implements a WordPress 'Cookie Firewall':
# Unless on a admin or login page, all 'Cookie' and 'Set-Cookie' headers are
# dropped

include "backends.vcl";
include "acl.vcl";

sub vcl_recv {
    set req.grace = 6h;

    # Allow purging only from the purgeallow ACL
    if (req.request == "PURGE") {
        if (!client.ip ~ purgeallow) {
            error 403 "PURGE requests not allowed from this IP";
        }
        return (lookup);
    }

    # Append or set X-Forwarded-For with IP of Varnish
    if (req.restarts == 0) {
        if (req.http.X-Forwarded-For) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # Remove any Google Analytics query strings
    if (req.url ~ "(\?|&)(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=") {
        set req.url = regsuball(req.url, "&(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "");
        set req.url = regsuball(req.url, "\?(utm_source|utm_medium|utm_campaign|gclid|cx|ie|cof|siteurl)=([A-z0-9_\-\.%25]+)", "?");
        set req.url = regsub(req.url, "\?&", "?");
        set req.url = regsub(req.url, "\?$", "");
    }

    # Remove Cookie header for static files and duck out
    if (req.url ~ "^[^?]*\.(bmp|bz2|css|doc|eot|flv|gif|gz|ico|jpeg|jpg|js|less|mp[34]|pdf|png|rar|rtf|swf|tar|tgz|txt|wav|woff|xml|zip)(\?.*)?$") {
        unset req.http.Cookie;
        return (lookup);
    }

    # If we're on the admin/login/rpc pages, duck out
    if (req.url ~ "(wp-(login|admin)|login)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
        return (pass);
    }

    # Normal guest, remove cookie and head off!
    remove req.http.cookie;
}

sub vcl_hit {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged";
    }
}

sub vcl_miss {
    if (req.request == "PURGE") {
        purge;
        error 200 "Purged";
    }
}

sub vcl_fetch {
    set beresp.grace = 6h;

    #Only allow Set-Cookie from the admin/login pages and not on GETs
    if ((!(req.url ~ "(wp-(login|admin)|login)")) || (req.request == "GET") ) {
        unset beresp.http.set-cookie;
    }
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    }
    else {
        set resp.http.X-Cache = "MISS";
    }
}
