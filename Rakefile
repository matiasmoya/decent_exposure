require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--format progress']
  t.verbose = false
end

task :default => :spec
