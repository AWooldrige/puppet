//#######################################################################
//##   This file is controlled by Puppet - changes will be overwritten  ##
//#######################################################################
// GNOME stays at 100% and this does the work instead. 720x1280 / 1.4 gives a
// 516x917 CSS px viewport
//
// Do not raise this past about 1.44. Firefox will not make a window narrower than
// roughly 500 CSS px, so a larger divisor puts the screen below that floor and the
// window is clamped wider than the display, leaving the right hand edge hanging off
// it. At 1.5 the screen is 480 CSS px and the window comes up 500: everything fits
// internally and the last 20 px are simply not on the panel. Check by comparing
// document.documentElement.clientWidth with screen.availWidth; they should match.
user_pref("layout.css.devPixelsPerPx", "1.4");

// Links open in the tab that is already there. Kiosk mode has no tab bar
user_pref("browser.link.open_newwindow", 1);
user_pref("browser.link.open_newwindow.restriction", 0);
user_pref("browser.link.open_newwindow.override.external", 1);

// The Home Assistant login has to survive a reboot
user_pref("privacy.sanitize.sanitizeOnShutdown", false);
user_pref("privacy.clearOnShutdown.cookies", false);
user_pref("privacy.clearOnShutdown.offlineApps", false);
user_pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);

user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.coverage.opt-out", true);
user_pref("toolkit.coverage.enabled", false);
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("browser.ping-centre.telemetry", false);

user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("app.shield.optoutstudies.enabled", false);

user_pref("extensions.blocklist.enabled", false);
user_pref("services.settings.server", "");

user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
// Never offer to restore a crashed session: the kiosk must come back
user_pref("browser.sessionstore.resume_from_crash", false);

user_pref("browser.sessionstore.interval", 600000);
user_pref("browser.cache.disk.enable", false);
user_pref("browser.cache.memory.enable", true);

user_pref("extensions.pocket.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.newtabpage.activity-stream.default.sites", "");
user_pref("browser.discovery.enabled", false);
user_pref("extensions.getAddons.showPane", false);
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("browser.messaging-system.whatsNewPanel.enabled", false);
// Suppresses the "what's new" page
user_pref("browser.startup.homepage_override.mstone", "ignore");

user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);
user_pref("browser.urlbar.suggest.quicksuggest.nonsponsored", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.urlbar.groupLabels.enabled", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.urlbar.trimURLs", false);

user_pref("network.prefetch-next", false);
user_pref("network.dns.disablePrefetch", true);
user_pref("network.dns.disablePrefetchFromHTTPS", true);
user_pref("network.predictor.enabled", false);
user_pref("network.predictor.enable-prefetch", false);
user_pref("network.http.speculative-parallel-limit", 0);

// The board it has its own upstream reachability probe.
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("captivedetect.canonicalURL", "");

// DNS over HTTPS
// 5 = off by choice
user_pref("network.trr.mode", 5);

// Safe Browsing
// A Google phone-home that downloads lists on a timer.
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.downloads.remote.enabled", false);
user_pref("browser.safebrowsing.provider.google4.updateURL", "");
user_pref("browser.safebrowsing.provider.google4.gethashURL", "");
user_pref("browser.safebrowsing.provider.google.updateURL", "");
user_pref("browser.safebrowsing.provider.google.gethashURL", "");

// Accounts and sync
user_pref("identity.fxaccounts.enabled", false);
user_pref("identity.fxaccounts.toolbar.enabled", false);

// AI features
user_pref("browser.ml.enable", false);
user_pref("browser.ml.chat.enabled", false);
user_pref("browser.ml.linkPreview.enabled", false);
user_pref("browser.tabs.groups.smart.enabled", false);
user_pref("extensions.ml.enabled", false);
user_pref("browser.urlbar.quicksuggest.mlEnabled", false);

// Geolocation and region
user_pref("geo.enabled", false);
user_pref("permissions.default.geo", 2);
user_pref("browser.region.network.url", "");
user_pref("browser.region.update.enabled", false);

// Kiosk housekeeping
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.rights.3.shown", true);
user_pref("browser.warnOnQuit", false);
user_pref("full-screen-api.warning.timeout", 0);
user_pref("full-screen-api.warning.delay", 0);
user_pref("browser.download.useDownloadDir", true);
user_pref("pdfjs.disabled", true);
user_pref("places.history.enabled", false);
