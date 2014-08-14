# Only used for development!
# Always run using bundle! (`bundle exec guard`)


guard :shell do
  watch(/.*\.coffee$/) do
    p `make clean` # clean everything.
    p `make` # recompile everything.
    `pkill -f ~/atom-shell/atom` # Kill all Springseed processes automatically, quite crude, just matches all processes using a `~/atom-shell` ¯\_(ツ)_/¯
    p `~/atom-shell/atom ~/springseed` # restart springseed, again, crude, but does the job.
  end
end
