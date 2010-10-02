require 'pathname'

module Test
  class Blackbox
    NOT_TESTED = '-'
    PASSED = '.'
    FAILED = 'F'
    ERROR = 'E'
    
    attr_reader :tests
    
    def load_tests!
      @tests = []
      file = (@dir + 'tests.txt').read
      sep = file.slice!(/.+\n/)
      half_sep = sep[0..(sep.length / 2 - 1)] + "\n"
      i = 0
      file.split(sep).each do |t|
        input, expectation = *t.split(half_sep).map{ |e| e.strip }
        @tests << {:name => (i+=1).to_s, :input => input, :expectation => expectation, :status => NOT_TESTED}
      end
    end
    
    def initialize target, options = {}
      target = Pathname.new(target) unless target.is_a? Pathname
      target += 'main.exe' if target.directory?
      target = target.sub_ext '.exe'
      raise ArgumentError, "Specified file \"#{target}\" does not exist" unless target.exist?
      @path = target
      @dir = @path.dirname
      @input_path = @dir + 'input.txt'
      @output_path = @dir + 'output.txt'
      @tests = []
      options[:autorun] = true if options[:autorun].nil?
      run if options[:autorun]
    end
    
    def run options = {}
      options[:load_tests] = true if options[:load_tests].nil?
      load_tests! if options[:load_tests]
      Dir.chdir(@dir)
      @tests.each do |test|
        @output_path.delete if @output_path.exist?
        @input_path.open('w') {|f| f.write(test[:input]) }
        
        start = Time.now
        ret = `#{@path}`
        test[:time] = Time.now - start
        
        begin
          test[:actual] = @output_path.read
        rescue Errno::ENOENT
          set_output_error_for test
        else
          if test[:expectation] == test[:actual]
            set_success_for test
          else
            set_fail_for test
          end
        end
        add_debug_information_for test, ret
      end
    end
    
    def set_output_error_for test
      print test[:status] = ERROR
      test[:message] = "Program didn't create \"output.txt\" for test #{test[:name]}\n"
    end
    
    def set_success_for test
      print test[:status] = PASSED
      test[:message] = "Test #{test[:name]} is passed\n"
    end
    
    def set_fail_for test
      print test[:status] = FAILED
      test[:message] = <<EOT
Test #{test[:name]} is failed
Input:
#{test[:input]}
Expectation:
#{test[:expectation]}
Actual:
#{test[:actual]}
EOT
    end
    
    def add_debug_information_for test, info=nil
      test[:message] = '' if test[:message].nil?
      test[:message] << "Debug:\n#{info}\n" unless info.empty?
    end
  end
end
