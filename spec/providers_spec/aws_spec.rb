RSpec.describe VolumeSweeper::Providers::Aws do
  before(:all) do
    ::Aws.config.update stub_responses: true
  end

  let(:aws_options) {
    { region: "us-west-1", mode: :audit, account_id: "1000" }
  }
  subject { VolumeSweeper::Providers::Aws.new **aws_options }

  context "intialization" do
    it "sets the provider's parameters" do
      expect(subject.instance_variable_get "@region").to eq "us-west-1"
      expect(subject.instance_variable_get "@run_mode").to eq :audit
      expect(subject.instance_variable_get "@account_id").to eq "1000"
      expect(subject.instance_variable_get "@config_path").to eq nil
      expect(subject.instance_variable_get "@creds_path").to eq nil
    end

    it "validates missing parameters" do
      expect {
        VolumeSweeper::Providers::Aws.new **aws_options.except(:account_id)
      }.to raise_error(SystemExit)
    end
  end

  context "api sdk" do
    it "configures regions" do
      expect(::Aws.config[:region]).to eq aws_options[:region]
    end

    it "call fetching volumes methold" do
      expect_any_instance_of(::Aws::EC2::Client).to receive(:describe_volumes)
      expect(subject.scan_block_volumes).to eq([0, []])
    end
  end
end
