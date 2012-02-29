require 'rake/testtask'

namespace :test do

  Rake::TestTask.new(:unit) do |t|
    t.libs = ['lib']
    t.test_files = FileList['test/unit/*_test.rb']
    t.ruby_opts += ["-w"]
  end

  Rake::TestTask.new(:end_to_end) do |t|
    t.libs = ['lib']
    t.test_files = FileList['test/end_to_end/*_test.rb']
    t.ruby_opts += ["-w"]
  end

  task :run => [:unit, :end_to_end]

end

desc 'Alias to test:run'
task :test => 'test:run'

task :default => :test
