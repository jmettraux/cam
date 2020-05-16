#!/usr/local/bin/ruby25

require 'time'

OPTS = {
  dev: '/dev/video0',
  res: '1280x720', tres: '320x240',
  path: '.', old: 2 * 24 * 3600,
  sleep: 5 }

as = ARGV.dup
while a = as.shift
  case a
  when '-d', '--device' then OPTS[:dev] = as.shift
  when '-r', '--res' then OPTS[:res] = as.shift
  when '-t', '--tres' then OPTS[:tres] = as.shift
  when '-p', '--path' then OPTS[:path] = as.shift
  when '-o', '--old' then OPTS[:old] = as.shift.to_i
  when '-s', '--sleep' then OPTS[:sleep] = as.shift.to_i
  end
end


def shoot

  t = Time.now.strftime('%Y%m%d_%H%M%S')
  fn = File.join(OPTS[:path], "photo_#{t}.jpg")
  tfn = File.join(OPTS[:path], "photo_#{t}_thumbnail.jpg")
  system("fswebcam -d #{OPTS[:dev]} -r #{OPTS[:tres]} #{tfn} > /dev/null 2>&1")
  system("fswebcam -d #{OPTS[:dev]} -r #{OPTS[:res]} #{fn} > /dev/null 2>&1")
end

def clean

  t = Time.now

  Dir[File.join(OPTS[:path], 'photo_*.jpg')]
    .each { |pa|
      pt = pa.match(/\/photo_(\d+_\d+)(_thumbnail)?.jpg$/)
      pt = Time.parse(pt[1])
      FileUtils.rm(pa, force: true) if (t - pt) > OPTS[:old] }
end

def index

  File.open(File.join(OPTS[:path], 'index.html'), 'wb') do |f|
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
    Dir[File.join(OPTS[:path], 'photo_*_thumbnail.jpg')]
      .sort.reverse[0, 100].each do |pa|
        fn = File.basename(pa)
        f.write(%{
<a href="#{fn.gsub(/_thumbnail\./, '.')}"><img class="photo" src="#{fn}" /></a>
        }.rstrip)
      end
    f.write(%{
</body>
</html>
    }.strip)
  end
end


loop do

  shoot
  clean
  index

  sleep OPTS[:sleep]
end

