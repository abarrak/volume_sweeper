require_relative "support/smtp_helper"

STDOUT = StringIO.new

RSpec.describe VolumeSweeper::Utils::Notification do
  before(:all) do
    assign_test_std_channels
    Support::SmtpHelper.start_testing_server
  end

  after(:all) do
    unassign_test_std_channels
    Support::SmtpHelper.close_testing_server
  end

  let(:test_opts) do
    { smtp_host: Support::SmtpHelper::LOCALHOST, smtp_port: Support::SmtpHelper::SMTP_PORT,
      notification_subject: "Notification: block volume operation", smtp_tls: "false",
      smtp_sender: "default@example.com", smtp_receiver: "default@example.com",
      ms_teams_webhook: "https://httpbin.org/post" }
  end

  let(:sample_message) {
    <<~EOD
      <ul style="color: #400707">
      <li>volume: <a href="https://example.com/bv/vol-1232irijwof43">vol-1232irijwof43</a> is eligibile for deletion.</li>
      <li>volume: <a href="https://example.com/bv/vol-9njdo54lfbkmk">vol-9njdo54lfbkmk</a> is eligibile for deletion.</li>
      <li>volume: <a href="https://example.com/bv/vol-kjeroi43vv78s">vol-kjeroi43vv78s</a> is eligibile for deletion.</li>
      </ul>
    EOD
  }

  subject do
    VolumeSweeper::Utils::Notification.new **test_opts
  end

  it "sets smtp configurations per passed options" do
    expect(subject.instance_variable_get "@notification_subject").to eq test_opts[:notification_subject]
    expect(subject.instance_variable_get "@smtp_host").to eq test_opts[:smtp_host]
    expect(subject.instance_variable_get "@smtp_port").to eq test_opts[:smtp_port]
    expect(subject.instance_variable_get "@smtp_sender").to eq test_opts[:smtp_sender]
    expect(subject.instance_variable_get "@smtp_receiver").to eq test_opts[:smtp_receiver]
    expect(subject.instance_variable_get "@smtp_tls").to eq test_opts[:smtp_tls]
  end

  it "sends mail notification given a text content" do
    expect(subject.send_mail sample_message).to be(true)
    expect(STDOUT.string).to match(%r{email is sent successfully})
  end

  it "sends ms_teams notifications given a text content" do
    expect(subject.send_ms_teams_notice sample_message).to match(%r{\"title\": \"#{test_opts[:notification_subject]}})
  end
end
