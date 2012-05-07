backend default {
    .host = "<%= httpd_http_host %>";
    .port = "<%= httpd_http_port %>";
}

sub vcl_recv {

    set req.grace = 6h;

    # Always cache these types
    if (req.url ~ "\.(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)(\?.*|)$") {
        unset req.http.Cookie;
        set req.url = regsub(req.url, "\?.*$", "");
    }


    if (req.url ~ "\?(utm_(campaign|medium|source|term)|adParams|client|cx|eid|fbid|feed|ref(id|src)?|v(er|iew))=") {
        set req.url = regsub(req.url, "\?.*$", "");
    }

    if (req.http.cookie) {

        # Replace wordpress_test_cookie with wptestcookie to avoid preventing
        # cache
        if (req.http.Cookie ~ "wordpress_test_cookie") {
            set req.http.Cookie = regsuball(req.http.Cookie, "wordpress_test_cookie=", "; wptestcookie=");
        }

        # Only pay attention to wordpress_ cookie
        if (req.http.cookie ~ "(wordpress_|wp-settings-)") {
            return(pass);
        } else {
            unset req.http.cookie;
        }
    }
}

sub vcl_fetch {

    set beresp.grace = 6h;

    # Don't cache the admin section, post previews or xmlrpc
    if (req.url ~ "wp-(login|admin)" || req.url ~ "preview=true" || req.url ~ "xmlrpc.php") {
        return (hit_for_pass);
    }
    if ( (!(req.url ~ "(wp-(login|admin)|login)")) || (req.request == "GET") ) {
        unset beresp.http.set-cookie;
    }
    if (req.url ~ "\.(gif|jpg|jpeg|swf|css|js|flv|mp3|mp4|pdf|ico|png)(\?.*|)$") {
        set beresp.ttl = 365d;
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
