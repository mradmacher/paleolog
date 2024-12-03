# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
  t.warning = false
end

task default: :test

namespace :test do
  desc 'Runs web tests'
  task :web do
    Dir.glob('./test/web/**/*_test.rb').shuffle.each do |file|
      sh "bundle exec ruby -Itest #{file}"
    rescue StandardError
      puts 'Tests failed'
    end
  end

  desc 'Runs feature tests'
  task :features do
    Dir.glob('./test/features/**/*_test.rb').shuffle.each do |file|
      sh "bundle exec ruby -Itest #{file}"
    rescue StandardError
      puts 'Tests failed'
    end
  end

  desc 'Runs repository tests'
  task :repository do
    Dir.glob('./test/repository/*_test.rb').shuffle.each do |file|
      sh "bundle exec ruby -Itest #{file}"
    rescue StandardError
      puts 'Tests failed'
    end
  end
end
