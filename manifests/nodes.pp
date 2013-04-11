node 'cloud-local' inherits static-content-and-build-server {
}
node /^ip-\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}$/ inherits static-content-server {
}
