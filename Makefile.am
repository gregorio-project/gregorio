SUBDIRS= po include lib plugins src examples tex contrib

ACLOCAL_AMFLAGS = -I m4

EXTRA_DIST = build-aux/config.rpath fonts

# Generate ChangeLog from SVN history - do not fail if there is no network
# connection or svn is not available
svn_trunk_url="svn://svn.gna.org/svn/gregorio/trunk"
dist-hook:
	-svn log $(svn_trunk_url) > $(distdir)/ChangeLog
