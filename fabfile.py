from fabric.api import *
from fabric.contrib.console import confirm

import os
import base64
import tempfile
import pystache
import ftplib
import urllib
from StringIO import StringIO
from xml.etree import ElementTree as et
from urlparse import urlparse
from github2.client import Github
from datetime import datetime

##
# Configuration
##
project_name = 'ShiftIt'
src_dir = 'ShiftIt'
private_key = '/Users/krikava/Dropbox/Personal/Keys/ShiftIt/dsa_priv.pem'
archive_name_template = project_name + '-{version}.zip'
appcast_url = 'http://fikovnik.net/projects/shiftit/appcast/profileInfo.php'
appcast_ftpurl = 'ftp://fikovnik.net/www/projects/shiftit/appcast/appcast.xml'
release_notes_ftpurl_template = 'ftp://fikovnik.net/www/projects/shiftit/release-notes-{version}.html'
release_notes_url_template = 'http://fikovnik.net/projects/shiftit/release-notes-{version}.html'
download_url_template = 'http://fikovnik.net/projects/shiftit/downloads/' + archive_name_template
download_ftpurl_template = 'ftp://fikovnik.net/www/projects/shiftit/downloads/' + archive_name_template
gitub_keychain_item = 'github'
fikovnik_ftp_keychain_item = 'fikovnik.net'
release_notes_template = '''
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<body>
<h1>Version {{version}}</h1>

<h2>Changes</h2>
{{#issues}}
<ul>
    <li><b>#{{number}}</b> - <a href="{{html_url}}">{{title}}</a><li>
</ul>
{{/issues}}

If you find any bug please report them in <a href="http://github.com/fikovnik/ShiftIt/issues">github</a>

</body>
</html>
'''

src_dir = os.path.join(os.getcwd(), src_dir)
app_dir = os.path.join(src_dir,'build','Release',project_name+'.app')
info_plist_path = os.path.join(app_dir,'Contents','Info.plist')
public_key = os.path.join(src_dir,'dsa_pub.pem')

@task
def build():
   _xcodebuild(src_dir, project_name)

@task
def archive():
    # dependencies
    execute(build)

    version = _get_bundle_version()
    archive_path = archive_name_template.format(version=version)

    _pack(app_dir, archive_path)

@task
def release():
    # dependencies
    #execute(archive)

    version = _get_bundle_version()
    archive_path = archive_name_template.format(version=version)

    appcast = AppCast(appcast_url)
    appcast.add_version(version, \
            release_notes_url_template.format(version=version), \
            download_url_template.format(version=version), \
            datetime.now().strftime('%a, %d %b %G %T %z'), \
            _sign(archive_path, private_key, public_key), \
            os.path.getsize(archive_path))

    appcast_str = appcast.to_string()
    release_notes_str = _gen_release_notes(version)

    release_notes_ftpurl =  release_notes_ftpurl_template.format(version=version)
    download_ftpurl = download_ftpurl_template.format(version=version)

    puts('Version: '+version)
    puts('Archive: '+archive_path)
    puts('Appcast:')
    puts(appcast_str)
    puts('Release Notes:')
    puts(release_notes_str)
    puts('Upload file:')
    puts('\n'.join([appcast_ftpurl, release_notes_ftpurl, download_ftpurl]))

    if confirm('Proceed with upload?'):
        ftp_username = _keychain_get_username(fikovnik_ftp_keychain_item)
        ftp_password = _keychain_get_password(fikovnik_ftp_keychain_item)

        _ftp_put(StringIO(appcast_str), appcast_ftpurl,
                ftp_username, ftp_password)

        _ftp_put(StringIO(release_notes_str), release_notes_ftpurl,
                ftp_username, ftp_password)

        _ftp_put(open(archive_path,'rb'), download_ftpurl,
                ftp_username, ftp_password)

    print _gen_release_notes(version)

def _gen_release_notes(version):
    def _convert(i):
        return { \
                'number': i.number, \
                'html_url': i.html_url, \
                'title': i.title, \
            }

    github = Github(_keychain_get_username(gitub_keychain_item),
                    _keychain_get_password(gitub_keychain_item))

    issues = github.issues.list('fikovnik/ShiftIt',state='closed')
    issues = [e for e in issues if 'v'+version in e.labels]
    issues.sort(key=lambda i: i.closed_at)

    return pystache.render(release_notes_template, \
                           version=version, \
                           issues=[_convert(e) for e in issues])

def _get_bundle_version():
    version = local('defaults read %s CFBundleVersion' % info_plist_path, capture=True)
    return version.strip()

def _pack(src, dest):
    local('ditto -ck --keepParent %s %s' % (src, dest))

def _xcodebuild(src_dir, target):
     with lcd(src_dir):
        local('xcodebuild -target %s -configuration Release' % target)

def _sign(path, private_key, public_key):
    sign_file = tempfile.mktemp()

    local('openssl dgst -sha1 -binary < %s | openssl dgst -dss1 -sign %s > %s'
            % (path, private_key, sign_file))
    local('openssl dgst -sha1 -binary < %s | openssl dgst -dss1 -verify %s -signature %s'
            % (path, public_key, sign_file))

    signature = None
    with open(sign_file) as f:
        signature = base64.b64encode(f.read())

    os.remove(sign_file)

    return signature

def _keychain_get_username(account):
    username = local("security find-generic-password -l %s | grep 'acct' | " \
                     "cut -d '\"' -f 4" % account, capture=True)
    return username

def _keychain_get_password(account):
    password = local("security 2>&1 > /dev/null find-generic-password -g -l" \
                     " %s | cut -d '\"' -f 2" % account, capture=True)
    return password

def _ftp_put(f, url, username, password):
    r = urlparse(url)
    host = r.netloc
    dirname = os.path.dirname(r.path)
    basename = os.path.basename(r.path)

    puts('Uploading to %s@%s:%s/%s' % (username, host, dirname, basename))

    ftp = ftplib.FTP()
    try:
        ftp.connect(host)
        ftp.login(username, password)
        ftp.cwd(dirname)
        ftp.storlines('STOR %s' % basename, f)
    finally:
        ftp.quit()


class AppCast:

    _appcast_template = '''<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
    <item>
        <title>Version {version}</title>
        <sparkle:releaseNotesLink>{release_notes_url}</sparkle:releaseNotesLink>
        <pubDate>{pub_date}</pubDate>
        <enclosure
            url="{download_url}"
            sparkle:version="{version}"
            length="{size}"
            type="application/octet-stream"
            sparkle:dsaSignature="{signature}" />
    </item>
</rss>'''

    def __init__(self,url):
        et.register_namespace('sparkle','http://www.andymatuschak.org/xml-namespaces/sparkle')
        self.url = url
        self.appcast = et.parse(urllib.urlopen(url))

    def add_version(self, version, release_notes_url, download_url, pub_date,
            signature, size):

        fragment = et.XML(self._appcast_template.format( \
            version = version,\
            release_notes_url = release_notes_url,\
            download_url = download_url,\
            pub_date = pub_date,\
            signature = signature,\
            size = size))

        self.appcast.find('channel').append(fragment.find('item'))

    def to_string(self):
        return et.tostring(self.appcast.getroot())
