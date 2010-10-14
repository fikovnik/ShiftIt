#!/bin/sh
########################################################################
# release.sh
#
# - makes a release of a xcode project compatible with Sparkle
# - makes the release in the diectory from which it were executed
#
########################################################################

# configuration

PROJECT_NAME="ShiftIt"
PRIV_KEY="$HOME/Dropbox/Personal/Keys/ShiftIt/dsa_priv.pem"
URL="http://nkuyu.net/apps/shiftit"
APPCAST_URL="$URL/appcast.xml"
DOWNLOAD_URL="$URL/downloads"
OPENSSL="/usr/bin/openssl"

# below is the logic
src_dir="$(dirname $0)/../$PROJECT_NAME"
app_dir="$src_dir/build/Release/$PROJECT_NAME.app"

# build
pushd . > /dev/null
cd "$src_dir"
xcodebuild -target $PROJECT_NAME -configuration Release
if [ $? != 0 ]; then
    echo "XCode build failed"
    popd
    exit 2
fi
popd > /dev/null

# version
# note: defaults have to be (from whatever reason) called with full path
version=$(defaults read $(pwd)/"$app_dir/Contents/Info" CFBundleVersion)
if [ $? != 0 ]; then
    echo "Unable to get version info"
    exit 2
fi

archive_name="$PROJECT_NAME-$version.zip"
archive_path="$archive_name"
rel_notes_file="release-notes-$version.html"

# create an archive
if [ -f $archive_path ]; then 
    echo "Removing previously built archive"
    rm -fr $archive_path 
fi

echo 

echo "Version: $version"
echo "Name: $archive_name"
echo "Path: $(pwd)/$archive_path"

ditto -ck --keepParent "$app_dir" "$archive_path"
if [ $? != 0 ]; then
    echo "Unable to make an archive"
    exit 2
fi

# size
size=$(stat -c %s "$archive_path")
echo "Size: $size"

# date
pub_date=$(LC_TIME=en_US date +"%a, %d %b %G %T %z")
echo "Date: $pub_date"

# sign
# this comes from Sparkle
sign_file="$archive_name.sign"
"$OPENSSL" dgst -sha1 -binary < "$archive_path" | "$OPENSSL" dgst -dss1 -sign "$PRIV_KEY" > "$sign_file"
if [ $? != 0 ]; then
    echo "Unable to sign an archive"
    exit 2
fi
"$OPENSSL" dgst -sha1 -binary < "$archive_path" | "$OPENSSL" dgst -dss1 -verify "$src_dir/dsa_pub.pem" -signature "$sign_file"
if [ $? != 0 ]; then
    echo "Unable to verify signature an archive"
    exit 2
fi

signature=$(cat "$sign_file" | "$OPENSSL" enc -base64)
echo "Sig: $signature"
rm "$sign_file"

echo 
echo "Appcast:"
echo

# item
cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle"  xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>$PROJECT_NAME Changelog</title>
    <link>$APPCAST_URL</link>
    <description>Most recent changes with links to updates.</description>
    <language>en</language>
    <item>
      <title>Version $version</title>
      <sparkle:releaseNotesLink>
        http://nkuyu.net/apps/shiftit/release-notes-$version.html
      </sparkle:releaseNotesLink>
      <pubDate>$pub_date</pubDate>
      <enclosure url="$DOWNLOAD_URL/$archive_name" sparkle:version="$version" length="$size" type="application/octet-stream" sparkle:dsaSignature="$signature" />
    </item>
  </channel>
</rss>
EOF

echo
echo "Release notes: $rel_notes_file"
echo

# release  notes
cat <<EOF > $rel_notes_file
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<html>
<body>
<h1>Version $version</h1>

<h2>Changes</h2>
<ul>
  <li></li>
</ul>

If you find any bug please report them in <a href="http://github.com/fikovnik/ShiftIt/issues">github</a>

</body>
</html>
EOF

cat $rel_notes_file
echo
