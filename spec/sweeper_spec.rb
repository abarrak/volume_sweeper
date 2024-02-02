RSpec.describe VolumeSweeper do
  it "has a version number" do
    expect(VolumeSweeper::VERSION).not_to be nil
    expect(VolumeSweeper::VERSION).to be_kind_of String
  end

end
