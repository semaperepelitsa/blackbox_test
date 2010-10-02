$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require "test/blackbox"

arg = ARGV[0]

if arg.nil? || %w(-h --help -help help).include?(arg)
  abort <<EOD
USAGE: ruby tester.rb C:\\path\\to\\program\\[main.exe]
EOD
end

suite = Test::Blackbox.new(arg)

puts "\n\n"
i = 0
suite.tests.each do |test|
  puts "#{i+=1}. #{test[:message]}" if test[:status] != Test::Blackbox::PASSED
end
