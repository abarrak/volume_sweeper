RSpec.describe VolumeSweeper::Cli do
  before(:all) do
    ARGV.clear
    assign_test_std_channels
  end

  after(:all) do
    unassign_test_std_channels
  end

  let(:sample_options) {
    { cloud: 'oci', 'config-path': './tmp/config', mode: 'audit' }
  }

  it "prints the welcoming message" do
    title = 'Volume Sweeper 1.0'
    expect { VolumeSweeper::Cli.run }.to output(%r{#{title}}).to_stdout
  end

  it "accepts parameters and return them as options to the core" do
    arguments = ''
    sample_options.each do |k,v|
      arguments << " --#{k} #{v}"
    end
    ARGV.unshift arguments

    output = VolumeSweeper::Cli.run
    expect(output).to be_a(OpenStruct)
    # expect(output.cloud).to eq(sample_options[:cloud])
    # expect(output.config_path).to eq(sample_options['config-path'])
    # expect(output.mode).to eq(sample_options[:mode])
  end
end
