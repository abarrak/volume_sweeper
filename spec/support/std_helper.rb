module Support
  module StdHelper

    def assign_test_std_channels
      @original_stdout = $stdout
      @original_stderr = $stderr
      $stderr = StringIO.new
      $stdout = StringIO.new
    end

    def unassign_test_std_channels
      $stdout = @original_stdout
      $stderr = @original_stderr
      @original_stdout = nil
      @original_stderr = nil
    end
  end
end
