#!/usr/local/bin/ruby25

require 'time'
require 'fileutils'

OPTS = {
  dev: '/dev/video0',
  res: '1280x720', tres: '320x240',
  path: '.', keep: 1,
  depth: 2 * 3600,
  sleep: 7 }

as = ARGV.dup
while a = as.shift
  case a
  when '-d', '--device' then OPTS[:dev] = as.shift
  when '-r', '--res' then OPTS[:res] = as.shift
  when '-t', '--tres' then OPTS[:tres] = as.shift
  when '-p', '--path' then OPTS[:path] = as.shift
  when '-k', '--keep-days' then OPTS[:keep] = as.shift.to_i
  when '-s', '--sleep' then OPTS[:sleep] = as.shift.to_i
  when '-i', '--index-depth' then OPTS[:depth] = as.shift.to_i
  end
end


def fjoin(fn); File.join(OPTS[:path], fn); end
def dir(fn); Dir[fjoin(fn)]; end

def basename(path)
  bn = File.basename(path, File.extname(path))
  m = bn.match(/\A(.+)_thumbnail\z/)
  bn = m ? m[1] : bn
end

def to_thumb_fn(path); basename(path) + '_thumbnail.jpg'; end
def to_html_fn(path); basename(path) + '.html'; end
def to_photo_fn(path); basename(path) + '.jpg'; end

def to_thumb_pa(path); fjoin(to_thumb_fn(path)); end
def to_html_pa(path); fjoin(to_html_fn(path)); end
def to_photo_pa(path); fjoin(to_photo_fn(path)); end

def shoot

  fmt = '%Y-%m-%d %H:%M:%S (%Z)'.inspect

  t = Time.now.strftime('%Y%m%d_%H%M%S')
  pfn = fjoin("photo_#{t}.jpg")
  tfn = fjoin("photo_#{t}_thumbnail.jpg")

  #mute = ''
  mute = ' > /dev/null 2>&1'

  system(
    "fswebcam -d #{OPTS[:dev]} --timestamp #{fmt} " +
      "-r #{OPTS[:res]} #{pfn} " +
      "--scale #{OPTS[:tres]} #{tfn} " +
      mute)
end

def clean

  i = OPTS[:keep]
  max = 2 * 31

  loop do

    break if i > max

    t = (Time.now - i * 24 * 3600).strftime('%Y%m%d')
    paths = dir("photo_#{t}_*.{html,jpg}")

    FileUtils.rm(paths, force: true)

    i = i + 1
  end
end

def index

  index = fjoin('index.html')
  index1 = fjoin('index1.html')

  File.open(index1, 'wb') do |f|
    f.write(%{
<!DOCTYPE html>
<html>
<head>
<title>ura cam</title>
<!--
<link href="index.css" rel="stylesheet" type="text/css" />
<script src="index.js"></script>
-->
</head>
<body>
    }.strip)
    dir('photo_*_thumbnail.jpg')
      .sort.reverse
      .take_while { |pa|
        t = Time.parse(pa.match(/photo_(\d+_\d+)_thumbn/)[1])
        (Time.now - t) < OPTS[:depth] }
      .each { |pa|
        f.write(%{
<a href="#{to_html_fn(pa)}"><img class="photo" src="#{to_thumb_fn(pa)}" /></a>
        }.rstrip) }
    f.write(%{
</body>
</html>
    }.strip)
  end
  system("mv #{index1} #{index} > /dev/null 2>&1")
end

def map

  thumbs =
    dir('photo_*_thumbnail.jpg').sort.reverse
  thumbs[0, 28]
    .each_with_index do |t, i|
      File.open(to_html_pa(t), 'wb') do |f|
        pt = i > 0 ? thumbs[i - 1] : nil
        nt = thumbs[i + 1]
        prv =
          pt ?
          "<a href=\"#{to_html_fn(pt)}\"><img src=\"#{to_thumb_fn(pt)}\" /></a>" :
          ''
        nxt =
          nt ?
          "<a href=\"#{to_html_fn(nt)}\"><img src=\"#{to_thumb_fn(nt)}\" /></a>" :
          ''
        f.write(%{
<!DOCTYPE html>
<html>
<head>
<title>ura #{File.basename(basename(t))}</title>
<link href="photo.css" rel="stylesheet" type="text/css" />
<!--
<script src="photo.js"></script>
-->
</head>
<body>
  <table>
    <tr>
      <td class="prev">#{prv}</td>
      <td class="curr"><a href="#{to_photo_fn(t)}"><img src="#{to_photo_fn(t)}" /></a></td>
      <td class="next">#{nxt}</td>
    </tr>
    <tr>
      <td colspan="3">
        <a href="/cam">index</a>
      </td>
    </tr>
  </table>
</body>
</html>
        }.strip)
      end
  end
end


loop do

  shoot
  clean
  index
  map

  sleep OPTS[:sleep]
end

