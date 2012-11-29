from fabric.api import local, execute, abort, task, lcd, puts
from fabric.contrib.console import confirm
from xml.etree import ElementTree

import os
import pystache
import github3
import tempfile
import base64
import datetime

################################################################################
## Configuration
################################################################################

proj_name = 'ShiftIt'
proj_info_plist = 'ShiftIt-Info.plist'
proj_src_dir = 'ShiftIt'
proj_private_key = '/Users/krikava/Dropbox/Personal/Keys/ShiftIt/dsa_priv.pem'

release_notes_template = '''
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<body>
<h1>{{proj_name}} version {{proj_version}}</h1>

{{#devel}}
  <b>This is a development release that is intended for testing purposes only!</b>
{{/devel}}

{{#has_issues}}
<h2>Issues closed</h2>
<ul>
{{#issues}}
    <li><a href="{{html_url}}"><b>#{{number}}</b></a> - {{title}}</li>
{{/issues}}
</ul>
{{/has_issues}}

More information about this release can be found on the <a href="{{milestone_url}}">here</a>.
<br/><br/>
If you find any bugs please report them on <a href="http://github.com/fikovnik/ShiftIt/issues">github</a>.

</body>
</html>
'''.strip()

appcast_template = '''
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
   <channel>
      <title>{{proj_name}} Changelog</title>
      <link>{{proj_appcast_url}}</link>
      <language>en</language>
         <item>
            <title>{{proj_name}} version {{proj_version}}</title>
                <sparkle:releaseNotesLink>
                    {{proj_release_notes_url}}
                </sparkle:releaseNotesLink>
            <pubDate>{{date}}</pubDate>
            <enclosure url="{{download_url}}" sparkle:version="{{proj_version}}" length="{{download_size}}" type="application/octet-stream" sparkle:dsaSignature="{{download_signature}}" />
         </item>
   </channel>
</rss>
'''.strip()


################################################################################
## Prerequisites
################################################################################

# if not local('git diff-index --quiet HEAD --').return_code:
#     abort('There are pending changes in the repository. Run git status')


################################################################################
## Code
################################################################################

def _find(f, seq):
  """Return first item in sequence where f(item) == True."""
  
  for item in seq:
    if f(item): 
      return item

def _get_bundle_version(info_plist):
    version = local('defaults read %s CFBundleVersion' % info_plist, capture=True)
    return version.strip()

def _get_git_branch():
    branch = local('git symbolic-ref HEAD', capture=True)
    return branch[len('refs/heads/'):].strip()

def _gen_release_notes():
    def _convert(i):
        return { \
                'number': i.number, \
                'html_url': i.html_url, \
                'title': i.title, \
            }

    github = _github()
    shiftit = github.repository('fikovnik','ShiftIt')

    milestone = _find(lambda m: proj_version.startswith(m.title), shiftit.iter_milestones())
    if not milestone:
        raise Exception('Unable to find milestone: %s' % proj_version)


    open_issues = list(shiftit.iter_issues(milestone=milestone.number, state='open'))
    if len(open_issues) > 0 and not proj_is_dev:
        puts('Warning: there are still open issues')
        for i in open_issues:
            print '\t * #%s: %s' % (i.number, i.title)

    closed_issues = list(shiftit.iter_issues(milestone=milestone.number, state='closed'))
    closed_issues.sort(key=lambda i: i.closed_at)

    release_notes = dict( \
        has_issues = len(closed_issues) > 0, \
        issues = closed_issues, \
        proj_name=proj_name, \
        proj_version=proj_version, \
        devel=proj_is_dev, \
        milestone_url='https://github.com/fikovnik/ShiftIt/issues?milestone=%d' % milestone.number, \
        )

    puts('Release notes properties:')
    for (k,v) in release_notes.items():
        print "\t%s: %s" % (k,v)

    return pystache.render(release_notes_template, release_notes)

def _github():
    return github3.login(_keychain_get_username('github.com'),
        _keychain_get_password('github.com'))


def _keychain_get_username(account):
    username = local("security find-internet-password -l %s | grep 'acct' | " \
                     "cut -d '\"' -f 4" % account, capture=True)
    return username

def _keychain_get_password(account):
    password = local("security 2>&1 > /dev/null find-internet-password -g -l" \
                     " %s | cut -d '\"' -f 2" % account, capture=True)
    return password


################################################################################
## Project settings
################################################################################

proj_branch = _get_git_branch()
proj_is_dev = not proj_branch.startswith('release')
proj_src_dir = os.path.join(os.getcwd(), proj_src_dir)
proj_build_dir = os.path.join(os.getcwd(), 'build')
proj_app_dir = os.path.join(proj_src_dir,'build','Release',proj_name+'.app')
proj_public_key = os.path.join(proj_src_dir,'dsa_pub.pem')
proj_info_plist = os.path.join(proj_src_dir, proj_info_plist)

proj_version = _get_bundle_version(proj_info_plist)
proj_archive_tag = '-develop' if proj_is_dev else ''
proj_archive_name = proj_name + proj_archive_tag + '-' + proj_version + '.zip'
proj_archive_path = os.path.join(proj_build_dir, proj_archive_name)

proj_download_url = 'https://github.com/downloads/fikovnik/ShiftIt/'+proj_archive_name
proj_release_notes_url = 'http://htmlpreview.github.com/?https://raw.github.com/fikovnik/ShiftIt/'+proj_branch+'/release/release-notes-'+proj_version+'.html'
proj_release_notes_file = os.path.join(os.getcwd(),'release','release-notes-'+proj_version+'.html')
proj_appcast_url = 'https://raw.github.com/fikovnik/ShiftIt/'+proj_branch+'/release/appcast.xml'
proj_appcast_file = os.path.join(os.getcwd(),'release','appcast.xml')


################################################################################
## Tasks
################################################################################

@task
def info():
    '''
    Output all the build properties
    '''

    print 'Build info:'
    for (k,v) in [(k,v) for (k,v) in globals().items() if k.startswith('proj_')]:
        print "\t%s: %s" % (k[len('proj_'):],v)

@task
def build():
    '''
    Makes a build by executing xcodebuild
    '''

    with lcd(proj_src_dir):
        local('xcodebuild -target %s -configuration Release' % proj_name)

@task
def archive():
    '''
    Archives build
    '''

    # dependencies
    execute(build)

    local('ditto -ck --keepParent %s %s' % (proj_app_dir, proj_archive_path))

@task
def prepare_release():
    '''
    Prepare the release: sign the build, generate appcast, generate release notes, commit and push.
    '''

    # prerequisites
    puts('Verify that the update URL matches')
    tree = ElementTree.parse(proj_info_plist)
    root = tree.getroot().find('dict')
    elem = list(root.findall('*'))
    plist_appcast_url = _find(lambda (k,v): k.text == 'SUFeedURL', zip(*[iter(elem)]*2))[1].text.strip()
    if plist_appcast_url != proj_appcast_url:
        abort('Appcasts are different! Expected: `%s`, got: `%s`' % (proj_appcast_url, plist_appcast_url))

    # dependencies
    execute(archive)

    puts('Sign the build')
    sign_file = tempfile.mktemp()
    local('openssl dgst -sha1 -binary < %s | openssl dgst -dss1 -sign %s > %s'
        % (proj_archive_path, proj_private_key, sign_file))
    local('openssl dgst -sha1 -binary < %s | openssl dgst -dss1 -verify %s -signature %s'
        % (proj_archive_path, proj_public_key, sign_file))

    signature = None
    with open(sign_file) as f:
        signature = base64.b64encode(f.read())

    os.remove(sign_file)

    # appcast properties
    appcast = dict( \
        proj_name=proj_name, \
        proj_appcast_url=proj_appcast_url, \
        proj_version=proj_version, \
        proj_release_notes_url=proj_release_notes_url, \
        date=datetime.datetime.now().strftime('%a, %d %b %G %T %z'), \
        download_url=proj_download_url, \
        download_size=os.path.getsize(proj_archive_path), \
        download_signature=signature, \
    )

    puts('Appcast properties:')
    for (k,v) in appcast.items():
        print "\t%s: %s" % (k,v)
   
    appcast_str = pystache.render(appcast_template, appcast)
    release_notes_str = _gen_release_notes()

    puts('Following will update appcast and release-notes, COMMIT and PUSH TO ORIGIN!')
    if not confirm('Proceed with release (make sure you know what are you doing!)?'):
        return
        
    with open(proj_appcast_file,"w") as f:
        f.write(appcast_str)

    with open(proj_release_notes_file,"w") as f:
        f.write(release_notes_str)

    local('git add %s' % proj_appcast_file)    
    local('git add %s' % proj_release_notes_file)
    local('git commit -m "Added appcast and release notes for the %s release"' % proj_archive_name)
    local('git push origin %s' % proj_branch)

@task
def upload_release():
    '''
    Uploads the release to github
    '''

    # dependencies
    execute(archive)

    if not confirm('Proceed with upload?'):
        return

    github = _github()
    shiftit = github.repository('fikovnik','ShiftIt')

    download = _find(lambda d: d.name == proj_archive_name, shiftit.iter_downloads())
    if download:
        if not confirm('Download %s (id: %s, size: %s bytes) already exists. Override?' % (download.name, download.id, download.size)):
            return
        else:
            puts('Deleting download: %s (%s)' % (download.name, download.id))
            download.delete()

    download = shiftit.create_download(proj_archive_name, proj_archive_path)

    if not download:
        raise Exception('Unable to upload')

    puts('Uploaded: %s (id: %s, size: %s bytes): %s' % (download.name, download.id, download.size, download.html_url))
    proj_download_url=download.html_url

@task
def release():
    '''
    Makes the complete release (same as prepare_release, upload_release)
    '''

    # dependencies
    execute(prepare_release)
    execute(upload_release)


@task
def print_release_notes():
    '''
    Prints release notes
    '''

    puts(_gen_release_notes())
