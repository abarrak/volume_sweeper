RSpec.describe VolumeSweeper::Comparer do
  before do
    allow(VolumeSweeper::Utils::Log.instance).to receive(:msg) .and_return(nil)
  end


  let(:sample_bvs) {
    ["ocid1.volume.oc1.me-jeddah-1.abvgkljrhrfqgtbwl2eodat4codfsqqbjsmsklxshm3opneevpnrv2nlv6ca",
     "ocid1.volume.oc1.me-jeddah-1.abvgkljrckckunqd56x32sumtmijkgk3234kxxcdjtlyrkysu6u76e53vu2a",
     "ocid1.volume.oc1.me-jeddah-1.abvgkljrixub2zwxypa56b7hyjgqv7zcai3ex6dge6cp5ysi6au74ejqjupq"]
  }

  let(:sample_pvs) {
    [{
      name: "csi-39f7c004-08f9-40f1-8560-9a5cfef552f3",
      status: "Bound",
      volumeHandle: "ocid1.volume.oc1.me-jeddah-1.abvgkljrhrfqgtbwl2eodat4codfsqqbjsmsklxshm3opneevpnrv2nlv6ca",
      pvc: "data-loki-compactor",
      namespace: "loki-distributed"
    },
    {
      name: "csi-5572f5f7-0120-45de-a857-46fbae0965d2",
      status: "Bound",
      volumeHandle: "ocid1.volume.oc1.me-jeddah-1.abvgkljrckckunqd56x32sumtmijkgk3234kxxcdjtlyrkysu6u76e53vu2a",
      pvc: "data-loki-querier-0",
      namespace: "loki-distributed"
    }]
  }

  example_group "logic verifications" do
    example "block volumes in used are identified as active" do
      result = VolumeSweeper::Comparer.process sample_bvs, sample_pvs
      expect(result[:active_ids].count).to eq(2)
    end

    example "block volumes in wihout pv reference are identifed as inactive" do
      result = VolumeSweeper::Comparer.process sample_bvs, sample_pvs
      expect(result[:unused_ids].count).to eq(1)
    end
  end
end
